import Foundation

enum XPFBridge {
    /// 如果集成了 opa334/XPF 的 C 库，在这里调用 xpf_construct_offset_dictionary
    static func resolve(data: Data) -> KernelOffsets? {
        return nil
    }
}
