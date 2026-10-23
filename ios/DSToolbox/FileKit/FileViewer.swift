import SwiftUI
import AVKit
import QuickLook

struct FileViewer: View {
    let url: URL
    @State private var text: String = ""
    @State private var original: String = ""
    @State private var category: FileCategory = .other
    @State private var error: String?

    var body: some View {
        Group {
            switch category {
            case .text, .plist, .json, .xml: editor
            case .audio, .video: VideoPlayer(player: AVPlayer(url: url)).padding()
            case .image:
                if let img = UIImage(contentsOfFile: url.path) { ScrollView([.horizontal, .vertical]) { Image(uiImage: img).resizable().scaledToFit() } }
                else { Text("无法加载图片") }
            case .torrent: TorrentPreviewView(url: url)
            default: QuickLookView(url: url)
            }
        }
        .navigationTitle(url.lastPathComponent)
        .onAppear(perform: load)
        .alert("提示", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("好", role: .cancel) {} } message: { Text(error ?? "") }
    }

    private var editor: some View {
        VStack(spacing: 0) {
            if text != original {
                HStack { Spacer(); Button("保存") { save() }.buttonStyle(.borderedProminent).padding(8) }.background(.thinMaterial)
            }
            TextEditor(text: $text).font(.system(.body, design: .monospaced)).padding(8).autocorrectionDisabled().textInputAutocapitalization(.never)
        }
    }

    private func load() {
        category = FileTypeDetector.category(for: url)
        guard category == .text || category == .plist || category == .json || category == .xml else { return }
        if let s = try? String(contentsOf: url, encoding: .utf8) { text = s; original = s; return }
        if category == .plist {
            if let d = try? Data(contentsOf: url), let obj = try? PropertyListSerialization.propertyList(from: d, format: nil), let xd = try? PropertyListSerialization.data(fromPropertyList: obj, format: .xml, options: 0), let s = String(data: xd, encoding: .utf8) {
                text = s; original = s; return
            }
        }
        error = "无法读取文件内容"
    }

    private func save() {
        if category == .plist {
            guard let d = text.data(using: .utf8), let obj = try? PropertyListSerialization.propertyList(from: d, format: nil) else { error = "plist 格式不正确"; return }
            guard let xd = try? PropertyListSerialization.data(fromPropertyList: obj, format: .xml, options: 0) else { error = "无法写入"; return }
            try? xd.write(to: url); original = text; return
        }
        if category == .json { guard let d = text.data(using: .utf8), (try? JSONSerialization.jsonObject(with: d)) != nil else { error = "JSON 格式不正确"; return } }
        do { try text.write(to: url, atomically: true, encoding: .utf8); original = text } catch { self.error = error.localizedDescription }
    }
}

struct QuickLookView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> QLPreviewController { let c = QLPreviewController(); c.dataSource = context.coordinator; return c }
    func updateUIViewController(_ vc: QLPreviewController, context: Context) {}
    func makeCoordinator() -> Coord { Coord(url: url) }
    final class Coord: NSObject, QLPreviewControllerDataSource {
        let url: URL; init(url: URL) { self.url = url }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ c: QLPreviewController, previewItemAt i: Int) -> QLPreviewItem { url as NSURL }
    }
}
