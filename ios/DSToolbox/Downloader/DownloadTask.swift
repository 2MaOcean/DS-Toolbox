import Foundation

enum TaskState: String, Codable { case queued, running, paused, finished, failed }

struct DownloadTask: Identifiable, Codable, Hashable {
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
    var kind: DriveKind = .baidu
    var taskDirectory: URL { DownloadPaths.taskDirectory(for: id) }

    enum CodingKeys: String, CodingKey {
        case id, url, fileName, destination, totalBytes, completedBytes
        case state, createdAt, retries, cookieHeader, userAgent, kind
    }

    init(id: UUID, url: URL, fileName: String, destination: URL,
         totalBytes: Int64, completedBytes: Int64, state: TaskState,
         createdAt: Date, retries: Int, cookieHeader: String,
         userAgent: String, kind: DriveKind = .baidu) {
        self.id = id
        self.url = url
        self.fileName = fileName
        self.destination = destination
        self.totalBytes = totalBytes
        self.completedBytes = completedBytes
        self.state = state
        self.createdAt = createdAt
        self.retries = retries
        self.cookieHeader = cookieHeader
        self.userAgent = userAgent
        self.kind = kind
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        url = try c.decode(URL.self, forKey: .url)
        fileName = try c.decode(String.self, forKey: .fileName)
        destination = try c.decode(URL.self, forKey: .destination)
        totalBytes = try c.decode(Int64.self, forKey: .totalBytes)
        completedBytes = try c.decode(Int64.self, forKey: .completedBytes)
        state = try c.decode(TaskState.self, forKey: .state)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        retries = try c.decode(Int.self, forKey: .retries)
        cookieHeader = try c.decode(String.self, forKey: .cookieHeader)
        userAgent = try c.decode(String.self, forKey: .userAgent)
        kind = (try? c.decode(DriveKind.self, forKey: .kind)) ?? .baidu
    }
}

struct Segment: Codable {
    let index: Int
    let start: Int64
    let end: Int64
}

struct DownloadManifest: Codable {
    var urlString: String
    var totalSize: Int64
    var segmentSize: Int64
    var segments: [Segment]
    var completedIndexes: [Int]
    var updatedAt: Date
    var completedSet: Set<Int> { Set(completedIndexes) }
}
