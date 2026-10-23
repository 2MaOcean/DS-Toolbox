import SwiftUI
struct TorrentResultView: View {
    let result: TorrentCreationResult; @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("种子") { LabeledContent("名称", value: result.name); LabeledContent("大小", value: byteString(result.totalSize)) }
                Section("磁力") { Text(result.magnetLink).font(.caption).textSelection(.enabled); ShareLink(item: result.magnetLink) { Label("分享", systemImage: "square.and.arrow.up") } }
                Section { ShareLink(item: result.torrentURL) { Label("分享种子文件", systemImage: "doc") } }
            }.navigationTitle("已生成").toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
        }
    }
}
