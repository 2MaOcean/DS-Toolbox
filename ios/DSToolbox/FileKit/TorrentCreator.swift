import Foundation
import CryptoKit
enum TorrentCreatorError: LocalizedError {
    case emptySelection, readFailed(String)
    var errorDescription: String? { return "创建种子失败" }
}
struct TorrentCreationResult: Identifiable {
    var id: String { torrentURL.absoluteString }
    let torrentURL: URL; let magnetLink: String; let name: String; let totalSize: Int64; let pieceCount: Int
}
enum TorrentCreator {
    static func create(sourceURLs: [URL], trackers: [String] = ["udp://tracker.opentrackr.org:1337/announce"], pieceLength: Int = 262_144, outputDirectory: URL) throws -> TorrentCreationResult {
        guard !sourceURLs.isEmpty else { throw TorrentCreatorError.emptySelection }
        let fm = FileManager.default; let first = sourceURLs[0]; let name = first.lastPathComponent
        let isSingle = sourceURLs.count == 1 && !FileSorter.isDirectory(first)
        var files: [(String, URL, Int64)] = []; var total: Int64 = 0
        if isSingle {
            let size = Int64((try? first.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0); files.append((name, first, size)); total = size
        } else {
            for src in sourceURLs {
                if FileSorter.isDirectory(src) {
                    guard let en = fm.enumerator(at: src, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) else { continue }
                    for case let f as URL in en {
                        let v = try? f.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey]); guard v?.isDirectory == false else { continue }
                        let rel = f.path.replacingOccurrences(of: src.deletingLastPathComponent().path + "/", with: "")
                        let size = Int64(v?.fileSize ?? 0); files.append((rel, f, size)); total += size
                    }
                } else {
                    let size = Int64((try? src.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0); files.append((src.lastPathComponent, src, size)); total += size
                }
            }
        }

        var pieces = Data(); var buf = Data(); var pCount = 0
        func flush() { if !buf.isEmpty { pieces.append(contentsOf: Insecure.SHA1.hash(data: buf)); pCount += 1; buf.removeAll(keepingCapacity: true) } }
        for f in files {
            guard let h = try? FileHandle(forReadingFrom: f.1) else { continue }; defer { try? h.close() }
            while true { let chunk = (try? h.read(upToCount: pieceLength - buf.count)) ?? Data(); if chunk.isEmpty { break }; buf.append(chunk); if buf.count >= pieceLength { flush() } }
        }
        flush()
        var info: [String: BencodeValue] = ["name": .string(name), "piece length": .int(pieceLength), "pieces": .data(pieces)]
        if isSingle { info["length"] = .int(Int(files[0].2)) }
        else {
            var list: [BencodeValue] = []
            for f in files { list.append(.dict(["length": .int(Int(f.2)), "path": .list(f.0.split(separator: "/").map { .string(String($0)) })])) }
            info["files"] = .list(list)
        }
        let infoData = BencodeEncoder().encode(.dict(info))
        let infoHashHex = Insecure.SHA1.hash(data: infoData).map { String(format: "%02x", $0) }.joined()
        var root: [String: BencodeValue] = ["info": .dict(info)]
        if trackers.count == 1 { root["announce"] = .string(trackers[0]) }
        else if !trackers.isEmpty { root["announce-list"] = .list(trackers.map { .list([.string($0)]) }) }
        let torrentData = BencodeEncoder().encode(.dict(root))
        let safeName = name.isEmpty ? "torrent" : name
        var tURL = outputDirectory.appendingPathComponent("\(safeName).torrent"); var i = 1
        while fm.fileExists(atPath: tURL.path) { tURL = outputDirectory.appendingPathComponent("\(safeName) (\(i)).torrent"); i += 1 }
        try torrentData.write(to: tURL)
        let encName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        var magnet = "magnet:?xt=urn:btih:\(infoHashHex)&dn=\(encName)"
        for t in trackers { magnet += "&tr=\(t.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? t)" }
        return TorrentCreationResult(torrentURL: tURL, magnetLink: magnet, name: name, totalSize: total, pieceCount: pCount)
    }
}
