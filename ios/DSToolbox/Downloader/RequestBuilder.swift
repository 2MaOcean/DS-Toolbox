import Foundation
struct RequestBuilder {
    let fingerprint: DownloadFingerprint
    let cookieHeader: String
    var options: DownloadOptions = .default
    func make(_ url: URL, range: ClosedRange<Int64>? = nil) -> URLRequest {
        var req = URLRequest(url: url)
        req.timeoutInterval = options.timeout
        req.setValue(options.customUserAgent ?? fingerprint.userAgent, forHTTPHeaderField: "User-Agent")
        if !cookieHeader.isEmpty { req.setValue(cookieHeader, forHTTPHeaderField: "Cookie") }
        let referer = options.customReferer ?? fingerprint.referer
        if !referer.isEmpty { req.setValue(referer, forHTTPHeaderField: "Referer") }
        req.setValue(fingerprint.acceptLanguage, forHTTPHeaderField: "Accept-Language")
        req.setValue(fingerprint.acceptEncoding, forHTTPHeaderField: "Accept-Encoding")
        req.setValue("keep-alive", forHTTPHeaderField: "Connection")
        for (k, v) in options.customHeaders where !k.isEmpty { req.setValue(v, forHTTPHeaderField: k) }
        if options.useRangeRequests, let r = range { req.setValue("bytes=\(r.lowerBound)-\(r.upperBound)", forHTTPHeaderField: "Range") }
        return req
    }
    static func jitter() async { try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 0.3...1.2) * 1_000_000_000)) }
    static func cooldown(seconds: TimeInterval) async { guard seconds > 0 else { return }; try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000)) }
}
