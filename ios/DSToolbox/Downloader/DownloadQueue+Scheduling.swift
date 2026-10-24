import Foundation

extension DownloadQueue {
    func pause(id: UUID) {
        running[id]?.cancel(); running[id] = nil
        updateTaskState(id: id, state: .paused); clearSpeed(id: id); save(); pump()
    }
    func resume(id: UUID) {
        updateTaskState(id: id, state: .queued); updateRetries(id: id, retries: 0); save(); pump()
    }
    func pauseAll() {
        for (_, t) in running { t.cancel() }
        running.removeAll()
        for i in tasks.indices where tasks[i].state == .running {
            updateTaskState(id: tasks[i].id, state: .paused)
        }
        save()
    }
    func remove(id: UUID) {
        running[id]?.cancel(); running[id] = nil
        if let i = tasks.firstIndex(where: { $0.id == id }) {
            try? FileManager.default.removeItem(at: tasks[i].taskDirectory)
            if tasks[i].state == .finished {
                try? FileManager.default.removeItem(at: tasks[i].destination)
            }
            tasks.remove(at: i)
        }
        clearSpeed(id: id); save(); pump()
    }
    func updateTaskState(id: UUID, state: TaskState) {
        if let i = tasks.firstIndex(where: { $0.id == id }) { tasks[i].state = state }
    }
    func updateRetries(id: UUID, retries: Int) {
        if let i = tasks.firstIndex(where: { $0.id == id }) { tasks[i].retries = retries }
    }
    func updateProgress(id: UUID, done: Int64, total: Int64) {
        if let i = tasks.firstIndex(where: { $0.id == id }) {
            tasks[i].completedBytes = done
            tasks[i].totalBytes = total
        }
    }
    func enqueue(url: URL, fileName: String, credential: DriveCredential?,
                 kind: DriveKind = .baidu, options: DownloadOptions? = nil) throws -> UUID {
        let dest = try DownloadPaths.uniqueDestination(
            in: DownloadDestinationService.shared.currentDirectory,
            fileName: fileName
        )
        let task = DownloadTask(
            id: UUID(), url: url, fileName: fileName, destination: dest,
            totalBytes: 0, completedBytes: 0, state: .queued, createdAt: Date(),
            retries: 0,
            cookieHeader: credential?.cookieHeader ?? "",
            userAgent: credential?.userAgent ?? "",
            kind: kind
        )
        tasks.append(task); save(); pump(); return task.id
    }
}
EOFcat > ~/DS-Toolbox/ios/DSToolbox/Downloader/DownloadQueue+Runner.swift <<'EOF'
import Foundation

extension DownloadQueue {
    func pump() {
        let active = tasks.filter { $0.state == .running }.count
        guard active < 2 else { return }
        guard let task = tasks.first(where: { $0.state == .queued }) else { return }
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].state = .running
        }
        runTask(task.id)
    }

    private func runTask(_ id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        let fp = DownloadFingerprint.fingerprint(for: task.kind)
        let downloader = AdaptiveDownloader(fingerprint: fp)

        let work = Task { [weak self] in
            do {
                try await downloader.download(
                    url: task.url,
                    to: task.destination,
                    cookieHeader: task.cookieHeader,
                    taskDirectory: task.taskDirectory
                ) { done, total in
                    Task { @MainActor in
                        self?.updateProgress(id: id, done: done, total: total)
                        self?.updateSpeed(id: id, completed: done)
                    }
                }
                await MainActor.run { self?.finish(id: id) }
            } catch {
                await MainActor.run { self?.fail(id: id, error: error) }
            }
        }
        running[id] = work
    }

    private func finish(id: UUID) {
        if let i = tasks.firstIndex(where: { $0.id == id }) {
            tasks[i].state = .finished
            let name = tasks[i].fileName
            let size = tasks[i].totalBytes
            let urlString = tasks[i].url.absoluteString
            let kind = tasks[i].kind.rawValue
            DownloadHistory.shared.append(HistoryRecord(
                id: UUID(), fileName: name, size: size,
                completedAt: Date(), kind: kind, urlString: urlString
            ))
            NotificationManager.shared.notifyDownloadFinished(fileName: name)
        }
        running[id] = nil
        clearSpeed(id: id); save(); pump()
    }

    private func fail(id: UUID, error: Error) {
        if let i = tasks.firstIndex(where: { $0.id == id }) {
            tasks[i].state = .failed
            NotificationManager.shared.notifyDownloadFailed(
                fileName: tasks[i].fileName,
                reason: error.localizedDescription
            )
        }
        running[id] = nil
        clearSpeed(id: id); save(); pump()
    }
}
