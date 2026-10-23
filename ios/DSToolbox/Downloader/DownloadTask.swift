import Foundation
enum TaskState: String, Codable { case queued, running, paused, finished, failed }

struct DownloadTask: Identifiable, Codable {
    let id: UUID
    var url: URL
    var fileName: String
    var destination: URL
    var totalBytes: Int64
    var completedBytes: Int64
    var state: TaskState
    var createdAt: Date
    var retries: Int
    var cookieHeader: String
    var userAgent: String
    var taskDirectory: URL { DownloadPaths.taskDirectory(for: id) }
}

struct Segment: Codable { let index: Int; let start: Int64; let end: Int64 }

struct DownloadManifest: Codable {
    var urlString: String
    var totalSize: Int64
    var segmentSize: Int64
    var segments: [Segment]
    var completedIndexes: [Int]
    var updatedAt: Date
    var completedSet: Set<Int> { Set(completedIndexes) }
}
