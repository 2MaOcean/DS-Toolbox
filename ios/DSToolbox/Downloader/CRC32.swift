import Foundation
enum CRC32 {
    static let table: [UInt32] = {
        var t = [UInt32](repeating: 0, count: 256)
        for i in 0..<256 { var c = UInt32(i); for _ in 0..<8 { c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1) }; t[i] = c }
        return t
    }()
    static func update(_ crc: UInt32, chunk: Data) -> UInt32 {
        var c = crc; for byte in chunk { c = table[Int((c ^ UInt32(byte)) & 0xFF)] ^ (c >> 8) }; return c
    }
}
