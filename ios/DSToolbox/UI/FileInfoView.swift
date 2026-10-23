import SwiftUI
struct FileInfoView: View {
    let url: URL; @State private var sha256: String = "计算中…"
    var body: some View {
        Form {
            Section("基本信息") {
                LabeledContent("名称", value: url.lastPathComponent); LabeledContent("大小", value: byteString(FileSorter.size(url) ?? 0))
                if let d = FileSorter.date(url) { LabeledContent("修改时间", value: d.formatted(date: .abbreviated, time: .shortened)) }
            }
            Section("SHA256") { Text(sha256).font(.system(.caption, design: .monospaced)).textSelection(.enabled) }
            Section { ShareLink(item: url) { Label("分享文件", systemImage: "square.and.arrow.up") } }
        }
        .navigationTitle("文件信息").navigationBarTitleDisplayMode(.inline)
        .task { sha256 = (try? await FileHasher.sha256Async(url: url)) ?? "计算失败" }
    }
}
