import Foundation

struct OffsetResolver {
    static let shared = OffsetResolver()

    func resolve(kcache: URL) throws -> [String: UInt64] {
        let data = try Data(contentsOf: kcache,
                            options: .mappedIfSafe)
        guard data.count > 0x20 else {
            throw ResolveError.invalidMachO
        }
        let magic = data.withUnsafeBytes {
            $0.load(as: UInt32.self)
        }
        guard magic == 0xfeedfacf
           || magic == 0xfeedface else {
            throw ResolveError.invalidMachO
        }
        return ["kernelBase": 0]
    }
}

extension OffsetResolver {
    enum ResolveError: LocalizedError {
        case invalidMachO
        var errorDescription: String? {
            "kernelcache 不是合法的 Mach-O 文件"
        }
    }
}
