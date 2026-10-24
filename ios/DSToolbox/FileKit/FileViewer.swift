import SwiftUI

struct FileViewer: View {
    let url: URL
    @State private var text = ""
    @State private var original = ""
    @State private var category: FileCategory = .other
    @State private var error: String?

    var body: some View {
        Group {
            if category == .text || category == .plist || category == .json || category == .xml {
                VStack {
                    if text != original {
                        Button("保存") { save() }.buttonStyle(.borderedProminent).padding(.top)
                    }
                    TextEditor(text: $text)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
            } else if category == .image {
                if let img = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: img).resizable().scaledToFit()
                } else {
                    Text("无法加载图片").foregroundStyle(.secondary)
                }
            } else {
                Text("暂不支持预览").foregroundStyle(.secondary)
            }
            if let error {
                Text(error).foregroundStyle(.red).font(.caption)
            }
        }
        .navigationTitle(url.lastPathComponent)
        .onAppear(perform: load)
    }

    private func load() {
        category = FileTypeDetector.category(for: url)
        if let s = try? String(contentsOf: url, encoding: .utf8) {
            text = s; original = s
        }
    }

    private func save() {
        if FileRiskManager.shared.level(for: url) == .high {
            try? FileRiskManager.shared.backup(url: url)
        }
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            original = text
        } catch {
            self.error = error.localizedDescription
        }
    }
}
