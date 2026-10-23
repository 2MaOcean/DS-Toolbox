import Foundation
enum BatchPackager {
    static func pack(fileURLs: [URL], archiveName: String) throws -> URL {
        let dir = try DownloadPaths.downloadsDirectory()
        let name = archiveName.hasSuffix(".zip") ? archiveName : archiveName + ".zip"
        var dest = dir.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: dest.path) {
            let base = (name as NSString).deletingPathExtension; var i = 1
            while FileManager.default.fileExists(atPath: dest.path) { dest = dir.appendingPathComponent("\(base) (\(i)).zip"); i += 1 }
        }
        try SimpleZipWriter.write(files: fileURLs, to: dest); return dest
    }
}
