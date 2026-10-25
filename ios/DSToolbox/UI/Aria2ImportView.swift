import SwiftUI
struct Aria2ImportView: View {
    @EnvironmentObject var env: ToolboxEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var archiveName = "batch"

    var body: some View {
        NavigationStack {
            Form {
                Section("aria2 配置 / 命令行") {
                    TextEditor(text: $text).frame(minHeight: 220).font(.system(.caption, design: .monospaced)).autocorrectionDisabled().textInputAutocapitalization(.never)
                }
                Section("打包") { TextField("压缩包名称", text: $archiveName) }
            }
            .navigationTitle("导入 aria2")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导入") {
                        guard let cred = env.credential else { return }
                        let tasks = Aria2Importer.parse(conf: text)
                        for t in tasks {
                            for u in t.urls {
                                _ = try? env.queue.enqueue(url: u, fileName: t.out ?? u.lastPathComponent, credential: cred)
                            }
                        }
                        dismiss()
                    }.disabled(text.isEmpty || env.credential == nil)
                }
            }
        }
    }
}
