import Foundation
import Combine

struct SpeedSample { var lastBytes: Int64; var lastTime: Date; var bytesPerSecond: Double }

@MainActor
final class DownloadQueue: ObservableObject {
    static let shared = DownloadQueue()
    @Published var tasks: [DownloadTask] = []
    @Published private(set) var lastPacked: URL?
    @Published var needsRelogin: DriveKind? = nil
    @Published private(set) var speeds: [UUID: SpeedSample] = [:]

    @Published var speedLimitEnabled: Bool = UserDefaults.standard.bool(forKey: "ds.speedLimitEnabled") { didSet { UserDefaults.standard.set(speedLimitEnabled, forKey: "ds.speedLimitEnabled") } }
    @Published var speedLimitValue: Double = { let v = UserDefaults.standard.double(forKey: "ds.speedLimitValue"); return v > 0 ? v : 5_242_880 }() { didSet { UserDefaults.standard.set(speedLimitValue, forKey: "ds.speedLimitValue") } }

    var effectiveSpeedLimit: Double? { speedLimitEnabled ? speedLimitValue : nil }
    var running: [UUID: Task<Void, Never>] = [:]
    var completedCount = 0
    let cooldownAfterTasks = 5
    let cooldownSeconds: TimeInterval = 60

    private init() {
        self.tasks = TaskStorage.load().map { t -> DownloadTask in
            var c = t; if c.state == .running { c.state = .paused }; return c
        }
    }

    func updateSpeed(id: UUID, completed: Int64) {
        let now = Date()
        if let prev = speeds[id] {
            let dt = now.timeIntervalSince(prev.lastTime)
            if dt >= 0.8 {
                let db = completed - prev.lastBytes
                let inst = dt > 0 ? Double(db) / dt : 0
                let smoothed = prev.bytesPerSecond == 0 ? inst : prev.bytesPerSecond * 0.6 + inst * 0.4
                speeds[id] = SpeedSample(lastBytes: completed, lastTime: now, bytesPerSecond: max(0, smoothed))
            }
        } else {
            speeds[id] = SpeedSample(lastBytes: completed, lastTime: now, bytesPerSecond: 0)
        }
    }
    func clearSpeed(id: UUID) { speeds.removeValue(forKey: id) }
    var activeTaskIDs: Set<UUID> { Set(running.keys) }
    func save() { TaskStorage.save(tasks) }

    func updateTaskState(id: UUID, state: TaskState) { if let i = tasks.firstIndex(where: { $0.id == id }) { tasks[i].state = state } }
    func updateRetries(id: UUID, retries: Int) { if let i = tasks.firstIndex(where: { $0.id == id }) { tasks[i].retries = retries } }
    func updateProgress(id: UUID, done: Int64, total: Int64) {
        if let i = tasks.firstIndex(where: { $0.id == id }) { tasks[i].completedBytes = done; tasks[i].totalBytes = total }
    }

    func pump() {
        let active = tasks.filter { $0.state == .running }.count
        guard active < 2 else { return }
        guard let task = tasks.first(where: { $0.state == .queued }) else { return }
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) { tasks[idx].state = .running }
        runTask(task.id)
    }

    private func runTask(_ id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        let fp = DownloadFingerprint.fingerprint(for: task.kind)
        let downloader = AdaptiveDownloader(fingerprint: fp)
        let work = Task { [weak self] in
            do {
                try await downloader.download(url: task.url, to: task.destination, cookieHeader: task.cookieHeader, taskDirectory: task.taskDirectory) { done, total in
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
            let name = tasks[i].fileName; let size = tasks[i].totalBytes
            let urlString = tasks[i].url.absoluteString; let kind = tasks[i].kind.rawValue
            DownloadHistory.shared.append(HistoryRecord(id: UUID(), fileName: name, size: size, completedAt: Date(), kind: kind, urlString: urlString))
            NotificationManager.shared.notifyDownloadFinished(fileName: name)
        }
        running[id] = nil; clearSpeed(id: id); save(); pump()
    }

    private func fail(id: UUID, error: Error) {
        if let i = tasks.firstIndex(where: { $0.id == id }) {
            tasks[i].state = .failed
            NotificationManager.shared.notifyDownloadFailed(fileName: tasks[i].fileName, reason: error.localizedDescription)
        }
        running[id] = nil; clearSpeed(id: id); save(); pump()
    }
}
