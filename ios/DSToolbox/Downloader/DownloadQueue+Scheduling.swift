import Foundation

extension DownloadQueue {
    func pause(id: UUID) {
        running[id]?.cancel(); running[id] = nil
        if let i = tasks.firstIndex(where: { $0.id == id }), tasks[i].state == .running || tasks[i].state == .queued { tasks[i].state = .paused }
        clearSpeed(id: id); save(); pump()
    }
    func resume(id: UUID) {
        if let i = tasks.firstIndex(where: { $0.id == id }), tasks[i].state == .paused || tasks[i].state == .failed { tasks[i].state = .queued; tasks[i].retries = 0 }
        save(); pump()
    }
    func remove(id: UUID) {
        running[id]?.cancel(); running[id] = nil
        if let i = tasks.firstIndex(where: { $0.id == id }) {
            try? FileManager.default.removeItem(at: tasks[i].taskDirectory)
            if tasks[i].state == .finished { try? FileManager.default.removeItem(at: tasks[i].destination) }
            tasks.remove(at: i)
        }
        clearSpeed(id: id); DownloadTaskOptionsStore.shared.remove(for: id); save(); pump()
    }
    func pauseAll() { for (_, t) in running { t.cancel() }; running.removeAll(); for i in tasks.indices where tasks[i].state == .running { tasks[i].state = .paused }; save() }
}

extension DownloadQueue {
    func pump() {
        guard running.isEmpty else { return }
        guard let task = tasks.first(where: { $0.state == .queued && running[$0.id] == nil }) else { finalizeBatches(); return }
        start(task)
    }

    func start(_ task: DownloadTask) {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) { tasks[i].state = .running }
        save()
        let kind = detectKind(task.url)
        let fingerprint = DownloadFingerprint.fingerprint(for: kind)
        let tuner: QuarkTuner? = kind == .quark ? QuarkTuner(initial: 4, maxCap: 16) : nil
        let downloader = AdaptiveDownloader(fingerprint: fingerprint, tuner: tuner)
        let options = DownloadTaskOptionsStore.shared.options(for: task.id)

        let handle = Task { [weak self] in
            guard let self else { return }
            do {
                try await downloader.download(url: task.url, to: task.destination, cookieHeader: task.cookieHeader, taskDirectory: task.taskDirectory, options: options) { done, total in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        if let i = self.tasks.firstIndex(where: { $0.id == task.id }) { self.tasks[i].completedBytes = done; self.tasks[i].totalBytes = total }
                        self.updateSpeed(id: task.id, completed: done)
                    }
                }
                await MainActor.run {
                    if let i = self.tasks.firstIndex(where: { $0.id == task.id }) { self.tasks[i].state = .finished }
                    self.running.removeValue(forKey: task.id); self.clearSpeed(id: task.id); self.completedCount += 1; self.save()
                    DownloadHistory.shared.append(HistoryRecord(id: UUID(), fileName: task.fileName, size: task.totalBytes, completedAt: Date(), kind: kind.rawValue, urlString: task.url.absoluteString))
                    NotificationManager.shared.notifyDownloadFinished(fileName: task.fileName)
                    Task { [weak self] in
                        guard let self else { return }
                        if self.completedCount % self.cooldownAfterTasks == 0 { await RequestBuilder.cooldown(seconds: self.cooldownSeconds) }
                        self.pump()
                    }
                }
            } catch is CancellationError {
                await MainActor.run {
                    if let i = self.tasks.firstIndex(where: { $0.id == task.id }), self.tasks[i].state == .running { self.tasks[i].state = .paused }
                    self.running.removeValue(forKey: task.id); self.clearSpeed(id: task.id); self.save(); self.pump()
                }
            } catch let e as DownloaderError {
                if case .needsRelogin = e {
                    await MainActor.run { if let i = self.tasks.firstIndex(where: { $0.id == task.id }) { self.tasks[i].state = .failed }; self.running.removeValue(forKey: task.id); self.clearSpeed(id: task.id); self.needsRelogin = kind; self.save() }
                    return
                }
                await MainActor.run {
                    if let i = self.tasks.firstIndex(where: { $0.id == task.id }) {
                        self.tasks[i].retries += 1
                        let willFail = self.tasks[i].retries >= 3
                        self.tasks[i].state = willFail ? .failed : .queued
                        if willFail { NotificationManager.shared.notifyDownloadFailed(fileName: task.fileName, reason: e.localizedDescription) }
                    }
                    self.running.removeValue(forKey: task.id); self.clearSpeed(id: task.id); self.save(); self.pump()
                }
            } catch {
                await MainActor.run {
                    if let i = self.tasks.firstIndex(where: { $0.id == task.id }) {
                        self.tasks[i].retries += 1
                        let willFail = self.tasks[i].retries >= 3
                        self.tasks[i].state = willFail ? .failed : .queued
                        if willFail { NotificationManager.shared.notifyDownloadFailed(fileName: task.fileName, reason: error.localizedDescription) }
                    }
                    self.running.removeValue(forKey: task.id); self.clearSpeed(id: task.id); self.save(); self.pump()
                }
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
            guard !related.isEmpty, related.allSatisfy({ $0.state == .finished }) else { continue }
            if let zipped = try? BatchPackager.pack(fileURLs: related.map(\.destination), archiveName: batch.archiveName) { lastPacked = zipped }
        }
        batches.removeAll { b in let related = tasks.filter { b.tasks.contains($0.id) }; return related.allSatisfy { $0.state == .finished || $0.state == .failed } }
    }
}
