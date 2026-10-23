import SwiftUI
struct TorrentCreationSheet: View {
    let sources: [URL]; let outputDirectory: URL; let onComplete: (TorrentCreationResult) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var tracker = "udp://tracker.opentrackr.org:1337/announce"
    @State private var pieceLength = 262_144; @State private var isCreating = false; @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Tracker") { TextField("announce URL", text: $tracker).autocorrectionDisabled() }
                Section("分片") { Picker("大小", selection: $pieceLength) { Text("64 KB").tag(65_536); Text("256 KB").tag(262_144); Text("1 MB").tag(1_048_576) } }
                if let error { Section { Text(error).foregroundStyle(.red) } }
                Section { Button(isCreating ? "生成中…" : "生成种子") {
                    isCreating = true
                    DispatchQueue.global().async {
                        do { let r = try TorrentCreator.create(sourceURLs: sources, pieceLength: pieceLength, outputDirectory: outputDirectory); DispatchQueue.main.async { onComplete(r); dismiss() } }
                        catch { DispatchQueue.main.async { self.error = error.localizedDescription; isCreating = false } }
                    }
                }.disabled(isCreating) }
            }.navigationTitle("生成种子").toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
        }
    }
}
