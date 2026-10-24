import Foundation

extension DownloadQueue {
    func pause(id: UUID) {
        running[id]?.cancel(); running[id] = nil; updateTaskState(id: id, state: .paused)
        clearSpeed(id: id); save(); pump()
    }
    func resume(id: UUID) {
        updateTaskState(id: id, state: .queued); updateRetries(id: id, retries: 0); save(); pump()
    }
    func remove(id: UUID) {
        running[id]?.cancel(); running[id] = nil
        if let i = tasks.firstIndex(where: { $0.id == id }) {
            try? FileManager.default.removeItem(at: tasks[i].taskDirectory)
            if tasks[i].state == .finished { try? FileManager.default.removeItem(at: tasks[i].destination) }
            removeTask(at: i)
        }
        clearSpeed(id: id); DownloadTaskOptionsStore.shared.remove(for: id); save(); pump()
    }
    func pauseAll() {
        for (_, t) in running { t.cancel() }; running.removeAll()
        for i in tasks.indices where tasks[i].state == .running { updateTaskState(id: tasks[i].id, state: .paused) }
        save()
    }
}

extension DownloadQueue {
    func pump() {
        guard running.isEmpty else { return }
        guard let task = tasks.first(where: { $0.state == .queued && running[$0.id] == nil }) else { finalizeBatches(); return }
        start(task)
    }

    func start(_ task: DownloadTask) {
        updateTaskState(id: task.id, state: .running); save()
        let kind = detectKind(task.url)
        let downloader = AdaptiveDownloader(fingerprint: DownloadFingerprint.fingerprint(for: kind), tuner: kind == .quark ? QuarkTuner(initial: 4, maxCap: 16) : nil)
        let options = DownloadTaskOptionsStore.shared.options(for: task.id)

        let handle = Task { [weak self] in
            guard let self else { return }
            do {
                try await downloader.download(url: task.url, to: task.destination, cookieHeader: task.cookieHeader, taskDirectory: task.taskDirectory, options: options) { done, total in
                    Task { @MainActor [weak self] in
                        self?.updateProgress(id: task.id, done: done, total: total)
                        self?.updateSpeed(id: task.id, completed: done)
                    }
                }
                await MainActor.run {
                    self.updateTaskState(id: task.id, state: .finished)
                    self.running.removeValue(forKey: task.id); self.clearSpeed(id: task.id); self.completedCount += 1; self.save()
                    NotificationManager.shared.notifyDownloadFinished(fileName: task.fileName)
                    Task { if self.completedCount % self.cooldownAfterTasks == 0 { await RequestBuilder.cooldown(seconds: self.cooldownSeconds) }; self.pump() }
                }
            } catch is CancellationError {
                await MainActor.run { self.updateTaskState(id: task.id, state: .paused); self.running.removeValue(forKey: task.id); self.clearSpeed(id: task.id); self.save(); self.pump() }
            } catch let e as DownloaderError {
                if case .needsRelogin = e {
                    await MainActor.run { self.updateTaskState(id: task.id, state: .failed); self.running.removeValue(forKey: task.id); self.clearSpeed(id: task.id); self.needsRelogin = kind; self.save() }
                    return
                }
                await MainActor.run { self.updateRetries(id: task.id, retries: self.tasks.first(where: { $0.id == task.id })?.retries ?? 0 + 1)
                    if (self.tasks.first(where: { $0.id == task.id })?.retries ?? 0) < 3 {
                        self.updateTaskState(id: task.id, state: .queued)
                    } else {
                        self.updateTaskState(id: task.id, state: .failed)
                        NotificationManager.shared.notifyDownloadFailed(fileName: task.fileName, reason: "多次重试失败")
                    }
                    self.running.removeValue(forKey: task.id); self.clearSpeed(id: task.id); self.save(); self.pump() }
            } catch {
                await MainActor.run { self.updateRetries(id: task.id, retries: self.tasks.first(where: { $0.id == task.id })?.retries ?? 0 + 1)
                    if (self.tasks.first(where: { $0.id == task.id })?.retries ?? 0) < 3 {
                        self.updateTaskState(id: task.id, state: .queued)
                    } else {
                        self.updateTaskState(id: task.id, state: .failed)
                        NotificationManager.shared.notifyDownloadFailed(fileName: task.fileName, reason: "多次重试失败")
                    }
                    self.running.removeValue(forKey: task.id); self.clearSpeed(id: task.id); self.save(); self.pump() }
            }
        }
        running[task.id] = handle
    }

    func detectKind(_ url: URL) -> DriveKind {
        let host = url.host?.lowercased() ?? ""
        if host.contains("baidu") { return .baidu }; if host.contains("quark") { return .quark }
        if host.contains("guangya") { return .guangya }; if host.contains("139") { return .cmcc }; if host.contains("189") { return .telecom }
        return .baidu
    }

    private func finalizeBatches() {
        for batch in batches {
            let related = tasks.filter { batch.tasks.contains($0.id) }
            if !related.isEmpty && related.allSatisfy({ $0.state == .finished }) {
                if let zipped = try? BatchPackager.pack(fileURLs: related.map(\.destination), archiveName: batch.archiveName) { setPackedURL(zipped) }
            }
        }
        clearBatches()
    }
}
