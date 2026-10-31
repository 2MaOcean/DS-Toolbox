import Foundation

final class OffsetDatabase {
    static let shared = OffsetDatabase()
    private(set) var table: [KernelOffsets] = []
    private init() { loadBuiltin() }

    func offsetsFor(iosVersion: String, chip: ChipFamily) -> KernelOffsets? {
        let __short = iosVersion.split(separator: ".").prefix(2).joined(separator: ".")
        print("[KernelOffsets] lookup \(__short)/\(chip.rawValue)")
        let shortVersion = iosVersion.split(separator: ".").prefix(2).joined(separator: ".")
        if let hit = table.first(where: { $0.iosVersion == shortVersion && $0.chip == chip.rawValue }) {
            return hit
        }
        // 关键修复：缺失时明确失败，避免上层无超时等待
        print("[KernelOffsets] 缺失偏移量: iOS \(shortVersion) / chip \(chip.rawValue)")
        return nil
    }

    private func loadBuiltin() {
        table = [
            KernelOffsets(iosVersion: "18.4", chip: "A17 Pro",
                          kernelBase: 0xfffffff007004000, t1szBoot: 0x19,
                          offsetIcmp6Filt: 0x138, offsetSoProto: 0x20, offsetPrInput: 0x20)
        ]
    }
}
