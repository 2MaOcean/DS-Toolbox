import Foundation
import CryptoKit
struct ParsedTorrent { let name: String; let totalSize: Int64; let pieceCount: Int; let infoHash: String; let magnetLink: String }
enum SimpleTorrentParser {
    static func parse(_ data: Data) throws -> ParsedTorrent {
        guard let infoRange = findInfoRange(in: data) else { throw NSError(domain: "Torrent", code: 1) }
        let infoData = data.subdata(in: infoRange)
        let infoHashHex = Insecure.SHA1.hash(data: infoData).map { String(format: "%02x", $0) }.joined()
        let name = extractString(key: "name", in: infoData) ?? "unknown"
        let pieceLength = extractInt(key: "piece length", in: infoData) ?? 0
        let piecesLen = extractBytesLength(key: "pieces", in: infoData) ?? 0
        var totalSize: Int64 = 0
        if let s = extractInt(key: "length", in: infoData) { totalSize = Int64(s) } else { totalSize = sumFileLengths(in: infoData) }
        let encName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        return ParsedTorrent(name: name, totalSize: totalSize, pieceCount: pieceLength > 0 ? piecesLen / 20 : 0, infoHash: infoHashHex, magnetLink: "magnet:?xt=urn:btih:\(infoHashHex)&dn=\(encName)")
    }

    private static func findInfoRange(in data: Data) -> Range<Int>? {
        guard let r = data.range(of: Data("4:info".utf8)) else { return nil }
        var i = r.upperBound; guard i < data.count, data[i] == UInt8(ascii: "d") else { return nil }
        var depth = 1; i += 1
        while i < data.count && depth > 0 {
            let b = data[i]
            if b == UInt8(ascii: "d") || b == UInt8(ascii: "l") { depth += 1; i += 1 }
            else if b == UInt8(ascii: "e") { depth -= 1; i += 1 }
            else if b == UInt8(ascii: "i") { i += 1; while i < data.count && data[i] != UInt8(ascii: "e") { i += 1 }; i += 1 }
            else if b >= UInt8(ascii: "0") && b <= UInt8(ascii: "9") {
                var l = ""; while i < data.count && data[i] != UInt8(ascii: ":") { l.append(Character(UnicodeScalar(data[i]))); i += 1 }
                i += 1; if let len = Int(l) { i += len }
            } else { i += 1 }
        }
        return r.lowerBound..<i
    }
    private static func extractString(key: String, in data: Data) -> String? {
        guard let r = data.range(of: Data("\(key.count):\(key)".utf8)) else { return nil }
        var i = r.upperBound; var l = ""
        while i < data.count && data[i] != UInt8(ascii: ":") { l.append(Character(UnicodeScalar(data[i]))); i += 1 }
        i += 1; guard let len = Int(l), i + len <= data.count else { return nil }
        return String(data: data.subdata(in: i..<(i + len)), encoding: .utf8)
    }
    private static func extractInt(key: String, in data: Data) -> Int? {
        guard let r = data.range(of: Data("\(key.count):\(key)".utf8)) else { return nil }
        var i = r.upperBound; guard i < data.count, data[i] == UInt8(ascii: "i") else { return nil }
        i += 1; var n = ""; while i < data.count && data[i] != UInt8(ascii: "e") { n.append(Character(UnicodeScalar(data[i]))); i += 1 }; return Int(n)
    }
    private static func extractBytesLength(key: String, in data: Data) -> Int? {
        guard let r = data.range(of: Data("\(key.count):\(key)".utf8)) else { return nil }
        var i = r.upperBound; var l = ""
        while i < data.count && data[i] != UInt8(ascii: ":") { l.append(Character(UnicodeScalar(data[i]))); i += 1 }; return Int(l)
    }
    private static func sumFileLengths(in data: Data) -> Int64 {
        let kd = Data("6:length".utf8); var t: Int64 = 0; var sr = data.startIndex..<data.endIndex
        while let r = data.range(of: kd, in: sr) {
            var i = r.upperBound; guard i < data.count, data[i] == UInt8(ascii: "i") else { break }; i += 1
            var n = ""; while i < data.count && data[i] != UInt8(ascii: "e") { n.append(Character(UnicodeScalar(data[i]))); i += 1 }
            if let v = Int64(n) { t += v }; sr = i..<data.endIndex
        }
        return t
    }
}
