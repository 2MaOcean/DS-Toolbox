import SwiftUI
struct ProfileGeneratorView: View {
    @State private var selected: Set<ProfileOption> = []
    @State private var footnote = ""
    @State private var fileURL: URL?
    var body: some View {
        Form {
            Section("选项") { ForEach(ProfileOption.allCases) { o in Button { if selected.contains(o) { selected.remove(o) } else { selected.insert(o) } } label: { HStack { Text(o.rawValue).foregroundStyle(.primary); Spacer(); if selected.contains(o) { Image(systemName: "checkmark").foregroundStyle(.blue) } } } } }
            if selected.contains(.lockScreenFootnote) { Section("脚注") { TextField("文字", text: $footnote) } }
            Section { Button("生成描述文件") {
                if let d = ProfileGenerator.shared.generate(options: Array(selected), footnote: footnote) {
                    let u = FileManager.default.temporaryDirectory.appendingPathComponent("DS.mobileconfig"); try? d.write(to: u); fileURL = u
                }
            }.disabled(selected.isEmpty) }
            if let u = fileURL { Section { ShareLink(item: u) { Label("分享", systemImage: "square.and.arrow.up") } } }
        }.navigationTitle("描述文件")
    }
}
