import Foundation
struct DownloadOptions: Codable, Equatable {
    var concurrency: Int = 4
    var segmentSizeMB: Int = 8
    var customUserAgent: String? = nil
    var customReferer: String? = nil
    var customHeaders: [String: String] = [:]
    var timeout: TimeInterval = 30
    var maxRetries: Int = 3
    var speedLimitMBps: Double? = nil
    var useRangeRequests: Bool = true
    var followRedirects: Bool = true
    var segmentSizeBytes: Int64 { Int64(segmentSizeMB) * 1_048_576 }
    var speedLimitBytes: Double? { speedLimitMBps.map { $0 * 1_048_576 } }
    static let `default` = DownloadOptions()
}
