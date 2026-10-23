import Foundation
struct DownloadFingerprint {
    let kind: DriveKind
    let userAgent: String
    let referer: String
    let acceptLanguage: String
    let acceptEncoding: String
    let initialConcurrency: Int
    let initialSegmentSize: Int64
    let maxConcurrency: Int
    let maxActiveTasks: Int
    let slowSpeedThreshold: Double
    let slowStrikesBeforeDowngrade: Int
    let cooldownAfterDowngrade: TimeInterval

    static func fingerprint(for kind: DriveKind, isVIP: Bool = false) -> DownloadFingerprint {
        switch kind {
        case .baidu:
            return DownloadFingerprint(kind: .baidu, userAgent: isVIP ? "pan.baidu.com" : "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/122.0.0.0 Safari/537.36", referer: "https://pan.baidu.com/", acceptLanguage: "zh-CN,zh;q=0.9", acceptEncoding: "gzip, deflate, br", initialConcurrency: isVIP ? 4 : 1, initialSegmentSize: isVIP ? 16_777_216 : 4_194_304, maxConcurrency: isVIP ? 8 : 2, maxActiveTasks: 1, slowSpeedThreshold: 262_144, slowStrikesBeforeDowngrade: 3, cooldownAfterDowngrade: 120)
        case .quark:
            return DownloadFingerprint(kind: .quark, userAgent: "quark-cloud-drive/2.5.20", referer: "https://pan.quark.cn/", acceptLanguage: "zh-CN,zh;q=0.9", acceptEncoding: "gzip, deflate, br", initialConcurrency: 4, initialSegmentSize: 4_194_304, maxConcurrency: 16, maxActiveTasks: 2, slowSpeedThreshold: 307_200, slowStrikesBeforeDowngrade: 3, cooldownAfterDowngrade: 90)
        case .guangya, .cmcc, .telecom:
            return DownloadFingerprint(kind: kind, userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/122.0.0.0 Safari/537.36", referer: kind == .guangya ? "https://www.guangyapan.com/" : (kind == .cmcc ? "https://yun.139.com/" : "https://cloud.189.cn/"), acceptLanguage: "zh-CN,zh;q=0.9", acceptEncoding: "gzip, deflate, br", initialConcurrency: 2, initialSegmentSize: 8_388_608, maxConcurrency: 4, maxActiveTasks: 2, slowSpeedThreshold: 524_288, slowStrikesBeforeDowngrade: 3, cooldownAfterDowngrade: 90)
        }
    }
}
