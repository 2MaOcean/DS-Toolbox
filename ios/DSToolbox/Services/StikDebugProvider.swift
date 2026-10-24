import Foundation

final class StikDebugProvider {
    static let shared = StikDebugProvider()
    private init() {}

    private var pairingFilePath: String {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("pairing.plist").path
    }
    var isPairingFileAvailable: Bool {
        FileManager.default.fileExists(atPath: pairingFilePath)
    }

    private func consumeError(_ err: UnsafeMutablePointer<IdeviceFfiError>?) -> String? {
        guard let err else { return nil }
        let msg = err.pointee.message.map { String(cString: $0) } ?? "unknown"
        idevice_error_free(err)
        return msg
    }

    /// JIT 启用（bundleID）
    func enableJIT(bundleID: String) -> JITResult {
        guard isPairingFileAvailable else {
            return JITResult(success: false, message: "请先导入 pairing.plist")
        }
        var provider: OpaquePointer?
        var handshake: OpaquePointer?
        defer { if provider != nil { tunnel_free(provider) } }

        var e: UnsafeMutablePointer<IdeviceFfiError>?
        e = tunnel_create_rppairing(pairingFilePath, "127.0.0.1", 49152, &provider, &handshake)
        if let msg = consumeError(e) {
            return JITResult(success: false, message: "隧道失败：\(msg)")
        }

        e = debug_app(provider, handshake, bundleID, nil, nil)
        if let msg = consumeError(e) {
            return JITResult(success: false, message: "JIT 失败：\(msg)")
        }
        return JITResult(success: true, message: "JIT 已启用：\(bundleID)")
    }

    /// 进程列表（需先建立隧道，此处复用 JIT 的 provider）
    func fetchProcessList() -> [String] {
        var provider: OpaquePointer?
        var handshake: OpaquePointer?
        defer { if provider != nil { tunnel_free(provider) } }

        var e: UnsafeMutablePointer<IdeviceFfiError>?
        e = tunnel_create_rppairing(pairingFilePath, "127.0.0.1", 49152, &provider, &handshake)
        if let msg = consumeError(e) {
            print("隧道失败：\(msg)")
            return []
        }

        var list: UnsafeMutablePointer<ProcessInfo>?
        var count: Int32 = 0
        e = fetch_process_list(provider, handshake, &list, &count)
        if let msg = consumeError(e) {
            print("进程列表失败：\(msg)")
            return []
        }

        var result: [String] = []
        for i in 0..<Int(count) {
            if let name = list?[i].name {
                result.append(String(cString: name))
            }
        }
        free_process_list(list, count)
        return result
    }

    /// 应用列表（bundleID -> name）
    func fetchAppList() -> [String: String] {
        var provider: OpaquePointer?
        var handshake: OpaquePointer?
        defer { if provider != nil { tunnel_free(provider) } }

        var e: UnsafeMutablePointer<IdeviceFfiError>?
        e = tunnel_create_rppairing(pairingFilePath, "127.0.0.1", 49152, &provider, &handshake)
        if let msg = consumeError(e) {
            print("隧道失败：\(msg)")
            return [:]
        }

        var plist: UnsafeMutablePointer<plist_t>?
        e = fetch_app_list(provider, handshake, &plist)
        if let msg = consumeError(e) {
            print("应用列表失败：\(msg)")
            return [:]
        }

        var result: [String: String] = [:]
        if let plist {
            let count = plist_array_get_size(plist)
            for i in 0..<count {
                guard let item = plist_array_get_item(plist, i) else { continue }
                let bid = plist_dict_get_string_val(item, "CFBundleIdentifier")
                let name = plist_dict_get_string_val(item, "CFBundleDisplayName")
                if let bid, let name { result[String(cString: bid)] = String(cString: name) }
            }
            plist_free(plist)
        }
        return result
    }

    /// Syslog 日志流（简化：阻塞读一行，实际应放后台线程）
    func startSyslogRelay(handler: @escaping (String) -> Void) -> Bool {
        var provider: OpaquePointer?
        var handshake: OpaquePointer?
        defer { if provider != nil { tunnel_free(provider) } }

        var e: UnsafeMutablePointer<IdeviceFfiError>?
        e = tunnel_create_rppairing(pairingFilePath, "127.0.0.1", 49152, &provider, &handshake)
        if let msg = consumeError(e) {
            print("隧道失败：\(msg)")
            return false
        }

        e = start_syslog_relay(provider, handshake, { line in
            if let line { handler(String(cString: line)) }
        })
        if let msg = consumeError(e) {
            print("Syslog 失败：\(msg)")
            return false
        }
        return true
    }

    /// 虚拟定位（需已挂载 DDI）
    func simulateLocation(latitude: Double, longitude: Double) -> Bool {
        var provider: OpaquePointer?
        var handshake: OpaquePointer?
        defer { if provider != nil { tunnel_free(provider) } }

        var e: UnsafeMutablePointer<IdeviceFfiError>?
        e = tunnel_create_rppairing(pairingFilePath, "127.0.0.1", 49152, &provider, &handshake)
        if let msg = consumeError(e) {
            print("隧道失败：\(msg)")
            return false
        }

        e = simulate_location(provider, handshake, latitude, longitude)
        if let msg = consumeError(e) {
            print("定位失败：\(msg)")
            return false
        }
        return true
    }

    func stopSyslogRelay() {
        stop_syslog_relay()
    }
}
