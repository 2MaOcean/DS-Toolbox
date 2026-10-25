import SwiftUI

struct KrwFileBrowserView: View {
    @ObservedObject private var fm = KrwFileManager.shared
    @State private var current: String = NSHomeDirectory()
    @State private var files: [URL] = []
    @State private var editing: URL?
    @State private var editorText = ""

    var body: some View {
        List(files, id: \.self) { f in
            Button {
                let isDir = FileSorter.isDirectory(f)
                if isDir {
                    current = f.path; reload()
                } else if let d = fm.read(f.path), let s = String(data: d, encoding: .utf8) {
                    editorText = s; editing = f
                }
            } label: {
                HStack {
                    Image(systemName: FileSorter.isDirectory(f) ? "folder" : FileTypeDetector.iconName(for: f))
                    Text(f.lastPathComponent)
                }
            }
        }
        .navigationTitle((current as NSString).lastPathComponent)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    let p = (current as NSString).deletingLastPathComponent
                    if p != current { current = p; reload() }
                } label: { Image(systemName: "chevron.up") }
            }
        }
        .sheet(item: $editing) { url in
            NavigationStack {
                TextEditor(text: $editorText).padding()
                    .navigationTitle(url.lastPathComponent)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("保存") {
                                _ = fm.write(url.path, data: Data(editorText.utf8))
                                editing = nil
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("取消") { editing = nil }
                        }
                    }
            }
        }
        .onAppear(perform: reload)
    }

    private func reload() { files = fm.list(current) }
}
