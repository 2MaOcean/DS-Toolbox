import Foundation

final class OffsetDatabase {
    static let shared = OffsetDatabase()
    private(set) var table: [KernelOffsets] = []
    private init() { loadBuiltin() }

    func offsetsFor(iosVersion: String, chip: ChipFamily) -> KernelOffsets? {
        let shortVersion = iosVersion.split(separator: ".").prefix(2).joined(separator: ".")
        return table.first { $0.iosVersion == shortVersion && $0.chip == chip.rawValue }
    }

    private func loadBuiltin() {
        table = [
            KernelOffsets(iosVersion: "18.4", chip: "A17 Pro",
                          kernelBase: 0xfffffff007004000, t1szBoot: 0x19,
                          offsetIcmp6Filt: 0x138, offsetSoProto: 0x20, offsetPrInput: 0x20)
        ]
    }
}
