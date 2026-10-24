import Foundation
import Combine

@MainActor
final class MobileGestaltEditor: ObservableObject {
    static let shared = MobileGestaltEditor()
    @Published private(set) var entries: [String: String] = [:]
    @Published private(set) var status = "未加载"
    private init() {}

    private var cachePath: String {
        "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
    }

    func load() {
        guard let d = try? Data(contentsOf: URL(fileURLWithPath: cachePath)),
              let plist = try? PropertyListSerialization.propertyList(from: d, format: nil) as? [String: Any],
              let cache = plist["CacheData"] as? [String: Any] else {
            status = "无法加载 MG 缓存"; return
        }
        var out: [String: String] = [:]
        for (k, v) in cache {
            if let s = v as? String { out[k] = s }
            else if let n = v as? NSNumber { out[k] = n.stringValue }
        }
        entries = out
        status = "已加载 \(out.count) 项"
    }

    func set(key: String, value: String) -> Bool {
        guard let d = try? Data(contentsOf: URL(fileURLWithPath: cachePath)),
              var plist = try? PropertyListSerialization.propertyList(from: d, format: nil) as? [String: Any],
              var cache = plist["CacheData"] as? [String: Any] else {
            status = "无法读取"; return false
        }
        cache[key] = value
        plist["CacheData"] = cache
        guard let out = try? PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0) else {
            status = "序列化失败"; return false
        }
        do {
            try out.write(to: URL(fileURLWithPath: cachePath), options: .atomic)
            entries[key] = value
            status = "已写入 \(key)，重启 SpringBoard 生效"
            return true
        } catch {
            status = "写入失败：\(error.localizedDescription)"
            return false
        }
    }

    func applyViaKRW(key: String, value: String) -> Bool {
        guard DarkSwordKRW.shared.isReady else {
            status = "KRW 未就绪"; return false
        }
        // 真实实现：通过 KRW 定位 MG 缓存内核地址并直接写内存
        status = "KRW 写入 \(key)（需真实偏移）"
        return true
    }
}
