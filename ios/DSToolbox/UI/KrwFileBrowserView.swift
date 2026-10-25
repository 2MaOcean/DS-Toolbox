import SwiftUI

struct KrwEditableURL: Identifiable {
    var id: String { url.path }
    let url: URL
}

struct KrwFileBrowserView: View {
    @ObservedObject private var fm = KrwFileManager.shared
    @State private var current: String = NSHomeDirectory()
    @State private var files: [URL] = []
    @State private var editing: KrwEditableURL?
    @State private var editorText = ""

    var body: some View {
        List(files, id: \.self) { f in
            Button {
                if FileSorter.isDirectory(f) { current = f.path; reload() }
                else if let d = fm.read(f.path), let s = String(data: d, encoding: .utf8) {
                    editorText = s; editing = KrwEditableURL(url: f)
                }
            } label: {
                HStack {
                    Image(systemName: FileSorter.isDirectory(f) ? "folder" : FileTypeDetector.iconName(for: f))
                    Text(f.lastPathComponent)
                }
            }
        }
        .navigationTitle((current as NSString).lastPathComponent)
        .sheet(item: $editing) { e in
            NavigationStack {
                TextEditor(text: $editorText).padding()
                    .navigationTitle(e.url.lastPathComponent)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("保存") { _ = fm.write(e.url.path, data: Data(editorText.utf8)); editing = nil }
                        }
                    }
            }
        }
        .onAppear(perform: reload)
    }

    private func reload() { files = fm.list(current) }
}
