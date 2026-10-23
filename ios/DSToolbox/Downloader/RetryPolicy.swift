import Foundation
struct RetryPolicy {
    var maxRetries: Int = 3
    var baseDelay: TimeInterval = 1.0
    var maxDelay: TimeInterval = 30.0
    var rateLimitStrikesBeforeRelogin: Int = 3
    init(maxRetries: Int = 3, baseDelay: TimeInterval = 1.0, maxDelay: TimeInterval = 30.0, rateLimitStrikesBeforeRelogin: Int = 3) {
        self.maxRetries = maxRetries; self.baseDelay = baseDelay; self.maxDelay = maxDelay; self.rateLimitStrikesBeforeRelogin = rateLimitStrikesBeforeRelogin
    }
    func delay(for attempt: Int, retryAfter: TimeInterval?) -> TimeInterval {
        if let ra = retryAfter { return min(ra, maxDelay) }
        return min(baseDelay * pow(2, Double(attempt)), maxDelay) + Double.random(in: 0...0.5)
    }
    static func retryAfter(from response: HTTPURLResponse) -> TimeInterval? {
        guard let s = response.value(forHTTPHeaderField: "Retry-After") else { return nil }
        return TimeInterval(s)
    }
}

enum DownloaderError: LocalizedError {
    case invalidResponse, noRangeSupport, badStatus(Int), emptyFile, segmentSizeMismatch, cannotCreateFile, forbidden
    case rateLimited(TimeInterval?)
    case needsRelogin
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "无效响应"; case .noRangeSupport: return "不支持 Range"; case .badStatus(let c): return "HTTP \(c)"
        case .emptyFile: return "空文件"; case .segmentSizeMismatch: return "分片大小不匹配"; case .cannotCreateFile: return "无法创建文件"
        case .forbidden: return "访问被拒绝"; case .rateLimited: return "触发限流"; case .needsRelogin: return "凭证已失效，请重新登录"
        }
    }
}
