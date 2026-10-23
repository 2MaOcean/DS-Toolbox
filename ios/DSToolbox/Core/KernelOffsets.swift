import Foundation

struct KernelOffsets: Codable {
    let iosVersion: String
    let chip: String
    let t1szBoot: UInt64
    let kernelBase: UInt64
}

final class OffsetDatabase {
    static let shared = OffsetDatabase()
    private(set) var table: [KernelOffsets] = []
    private init() { loadBuiltin() }
    func offsetsFor(iosVersion: String, chip: ChipFamily) -> KernelOffsets? {
        let shortVersion = iosVersion.split(separator: ".").prefix(2).joined(separator: ".")
        return table.first { $0.iosVersion == shortVersion && $0.chip == chip.rawValue }
    }
    private func loadBuiltin() {
        table = [ KernelOffsets(iosVersion: "18.4", chip: "A17 Pro", t1szBoot: 0x19, kernelBase: 0xfffffff007004000) ]
    }
}
