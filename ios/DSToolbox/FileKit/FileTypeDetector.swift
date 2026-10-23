import Foundation
import UniformTypeIdentifiers

enum FileCategory { case text, plist, json, xml, image, audio, video, archive, torrent, binary, other }

enum FileTypeDetector {
    static func category(for url: URL) -> FileCategory {
        let ext = url.pathExtension.lowercased()
        if ext == "plist" { return .plist }; if ext == "json" { return .json }
        if ext == "xml" { return .xml }; if ext == "torrent" { return .torrent }
        if ["txt","md","csv","log","yaml","yml","html","css","js","swift","py","go","sh","c","cpp","h","ts"].contains(ext) { return .text }
        if let t = UTType(filenameExtension: ext) {
            if t.conforms(to: .image) { return .image }; if t.conforms(to: .audio) { return .audio }
            if t.conforms(to: .movie) || t.conforms(to: .video) { return .video }
            if t.conforms(to: .archive) { return .archive }
            if t.conforms(to: .text) || t.conforms(to: .sourceCode) { return .text }
        }
        return .other
    }
    static func iconName(for url: URL) -> String {
        switch category(for: url) {
        case .text: return "doc.text"; case .plist: return "list.bullet.rectangle"
        case .json: return "curlybraces"; case .xml: return "chevron.left.forwardslash.chevron.right"
        case .image: return "photo"; case .audio: return "music.note"; case .video: return "play.rectangle"
        case .archive: return "archivebox"; case .torrent: return "point.3.connected.trianglepath.dotted"
        default: return "doc"
        }
    }
    static func canEdit(_ url: URL) -> Bool {
        let c = category(for: url); return c == .text || c == .plist || c == .json || c == .xml
    }
}
