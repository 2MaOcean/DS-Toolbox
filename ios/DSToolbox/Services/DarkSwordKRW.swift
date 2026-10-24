import Foundation

final class DarkSwordKRW {
    static let shared = DarkSwordKRW()
    private(set) var isReady = false
    private(set) var kernelBase: UInt64 = 0
    private init() {}

    func initialize() -> Bool {
        guard !isReady else { return true }
        let ok = ds_krw_init()
        if ok {
            isReady = true
            kernelBase = ds_kernel_base()
        }
        return ok
    }

    func read(address: UInt64, size: Int) -> Data? {
        guard isReady else { return nil }
        var data = Data(count: size)
        let ok = data.withUnsafeMutableBytes { buf -> Bool in
            guard let p = buf.baseAddress else { return false }
            return ds_kread(address, p, size)
        }
        return ok ? data : nil
    }

    func write8(address: UInt64, value: UInt64) -> Bool {
        guard isReady else { return false }
        var v = value
        return ds_kwrite(address, &v, 8)
    }

    func deinitialize() {
        ds_krw_deinit()
        isReady = false
        kernelBase = 0
    }
}
