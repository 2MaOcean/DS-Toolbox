import Foundation
import WebKit

extension TorrentDownloader: WKScriptMessageHandler {
    nonisolated func userContentController(_ uc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any], let type = dict["type"] as? String else { return }
        Task { @MainActor in
            switch type {
            case "progress":
                self.progress = dict["progress"] as? Double ?? 0
                if let s = dict["speed"] as? Double { self.speed = ByteCountFormatter.string(fromByteCount: Int64(s), countStyle: .file) + "/s" }
                if let n = dict["name"] as? String, !n.isEmpty { self.name = n }
                self.status = "下载中"
            case "start":
                self.name = dict["name"] as? String ?? "torrent.bin"
                do {
                    let dest = try DownloadPaths.uniqueDestination(in: DownloadDestinationService.shared.currentDirectory, fileName: self.name)
                    FileManager.default.createFile(atPath: dest.path, contents: nil)
                    self.outputURL = dest; self.outputHandle = try FileHandle(forWritingTo: dest)
                } catch { self.status = "创建文件失败：\(error.localizedDescription)"; self.isRunning = false }
            case "chunk":
                if let b64 = dict["data"] as? String, let d = Data(base64Encoded: b64) { try? self.outputHandle?.write(contentsOf: d) }
            case "complete":
                try? self.outputHandle?.close(); self.outputHandle = nil; self.savedURL = self.outputURL
                self.status = "完成"; self.progress = 1; self.isRunning = false; self.stopWebOnly()
            case "error":
                self.status = "错误：\(dict["message"] as? String ?? "未知")"; self.isRunning = false
            default: break
            }
        }
    }
}
