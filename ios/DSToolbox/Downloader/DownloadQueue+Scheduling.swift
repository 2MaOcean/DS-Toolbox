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
            if tasks[i].state == .finished { try? FileManager.default.removeItem(at: tasks[i].destination) }
            tasks.remove(at: i)
        }
        clearSpeed(id: id); save(); pump()
    }
    func updateTaskState(id: UUID, state: TaskState) { if let i = tasks.firstIndex(where: { $0.id == id }) { tasks[i].state = state } }
    func updateRetries(id: UUID, retries: Int) { if let i = tasks.firstIndex(where: { $0.id == id }) { tasks[i].retries = retries } }
    func updateProgress(id: UUID, done: Int64, total: Int64) { if let i = tasks.firstIndex(where: { $0.id == id }) { tasks[i].completedBytes = done; tasks[i].totalBytes = total } }
    func enqueue(url: URL, fileName: String, credential: DriveCredential?, kind: DriveKind = .baidu, options: DownloadOptions? = nil) throws -> UUID {
        let dest = try DownloadPaths.uniqueDestination(in: DownloadDestinationService.shared.currentDirectory, fileName: fileName)
        let task = DownloadTask(id: UUID(), url: url, fileName: fileName, destination: dest, totalBytes: 0, completedBytes: 0, state: .queued, createdAt: Date(), retries: 0, cookieHeader: credential?.cookieHeader ?? "", userAgent: credential?.userAgent ?? "", kind: kind)
        tasks.append(task); save(); pump(); return task.id
    }
}
