import SwiftUI
struct TorrentPreviewView: View {
    let url: URL; @State private var parsed: ParsedTorrent?; @State private var error: String?
    var body: some View {
        Form {
            if let e = error { Section { Text(e).foregroundStyle(.red) } }
            else if let p = parsed {
                Section("信息") { LabeledContent("名称", value: p.name); LabeledContent("大小", value: byteString(p.totalSize)); LabeledContent("Hash", value: p.infoHash) }
                Section("磁力") { Text(p.magnetLink).font(.caption).textSelection(.enabled); ShareLink(item: p.magnetLink) { Label("分享", systemImage: "square.and.arrow.up") } }
            }
        }.navigationTitle("种子预览").onAppear { if let d = try? Data(contentsOf: url) { parsed = try? SimpleTorrentParser.parse(d); if parsed == nil { error = "解析失败" } } }
    }
}
