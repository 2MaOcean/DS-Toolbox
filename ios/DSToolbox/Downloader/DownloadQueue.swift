import Foundation
import Combine

struct BatchJob: Identifiable { let id = UUID(); var tasks: [UUID]; var archiveName: String; var autoPack: Bool }
struct SpeedSample { var lastBytes: Int64; var lastTime: Date; var bytesPerSecond: Double }

@MainActor
final class DownloadQueue: ObservableObject {
    static let shared = DownloadQueue()
    @Published private(set) var tasks: [DownloadTask] = []
    @Published private(set) var batches: [BatchJob] = []
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

    private init() { self.tasks = TaskStorage.load().map { t -> DownloadTask in var c = t; if c.state == .running { c.state = .paused }; return c } }

    func enqueue(url: URL, fileName: String, credential: DriveCredential?, siteCredential: SiteCredential? = nil, kind: DriveKind = .baidu, options: DownloadOptions? = nil) throws -> UUID {
        let dest = try DownloadPaths.uniqueDestination(in: DownloadDestinationService.shared.currentDirectory, fileName: fileName)
        let resolvedOptions = options ?? DownloadOptionsStore.shared.options(for: url.host ?? "")
        let cookie = siteCredential?.cookieHeader ?? credential?.cookieHeader ?? ""
        let ua = siteCredential?.userAgent ?? credential?.userAgent ?? ""

        let task = DownloadTask(id: UUID(), url: url, fileName: fileName, destination: dest, totalBytes: 0, completedBytes: 0, state: .queued, createdAt: Date(), retries: 0, cookieHeader: cookie, userAgent: ua)
        tasks.append(task); DownloadTaskOptionsStore.shared.set(resolvedOptions, for: task.id)
        save(); pump(); return task.id
    }

    func enqueueBatch(ariaTasks: [Aria2Task], credential: DriveCredential, archiveName: String, autoPack: Bool) {
        var ids: [UUID] = []
        for a in ariaTasks { for url in a.urls { let name = a.out ?? url.lastPathComponent; if let id = try? enqueue(url: url, fileName: name.isEmpty ? "download.bin" : name, credential: credential) { ids.append(id) } } }
        if autoPack && ids.count > 1 { batches.append(BatchJob(tasks: ids, archiveName: archiveName, autoPack: true)) }
        save()
    }

    func updateSpeed(id: UUID, completed: Int64) {
        let now = Date()
        if let prev = speeds[id] {
            let dt = now.timeIntervalSince(prev.lastTime)
            if dt >= 0.8 { let db = completed - prev.lastBytes; let inst = dt > 0 ? Double(db) / dt : 0; let smoothed = prev.bytesPerSecond == 0 ? inst : prev.bytesPerSecond * 0.6 + inst * 0.4; speeds[id] = SpeedSample(lastBytes: completed, lastTime: now, bytesPerSecond: max(0, smoothed)) }
            else { speeds[id] = SpeedSample(lastBytes: completed, lastTime: prev.lastTime, bytesPerSecond: prev.bytesPerSecond) }
        } else { speeds[id] = SpeedSample(lastBytes: completed, lastTime: now, bytesPerSecond: 0) }
    }
    func clearSpeed(id: UUID) { speeds.removeValue(forKey: id) }
    var activeTaskIDs: Set<UUID> { Set(running.keys) }
    func save() { TaskStorage.save(tasks) }
    
    func updateTaskState(id: UUID, state: TaskState) {
        if let i = tasks.firstIndex(where: { $0.id == id }) { tasks[i].state = state }
    }
    func updateProgress(id: UUID, done: Int64, total: Int64) {
        if let i = tasks.firstIndex(where: { $0.id == id }) { tasks[i].completedBytes = done; tasks[i].totalBytes = total }
    }
    func setPackedURL(_ url: URL) { lastPacked = url }
    func clearBatches() { batches.removeAll() }
    func removeTask(at i: Int) { tasks.remove(at: i) }
    func updateRetries(id: UUID, retries: Int) { if let i = tasks.firstIndex(where: { $0.id == id }) { tasks[i].retries = retries } }
    func setBatchArchiveName(index: Int, name: String) { batches[index].archiveName = name }
}
