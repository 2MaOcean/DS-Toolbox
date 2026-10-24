import SwiftUI

struct ProfileGeneratorView: View {
    @State private var options: Set<ProfileOption> = []
    @State private var footnote = ""
    @State private var savedURL: URL?
    @State private var error: String?

    var body: some View {
        Form {
            Section("选项") {
                ForEach(ProfileOption.allCases) { option in
                    Toggle(option.rawValue, isOn: Binding(
                        get: { options.contains(option) },
                        set: { if $0 { options.insert(option) } else { options.remove(option) } }
                    ))
                }
            }
            if options.contains(.lockScreenFootnote) {
                Section("脚注") { TextField("锁屏脚注", text: $footnote) }
            }
            if let error { Section { Text(error).foregroundStyle(.red) } }
            if let url = savedURL {
                Section("已生成") {
                    Text(url.lastPathComponent).font(.caption)
                    Button("分享") { ProfileShareHelper.present(url: url) }
                }
            }
            Section {
                Button("生成描述文件") { generate() }.disabled(options.isEmpty)
            }
        }
        .navigationTitle("描述文件")
    }

    private func generate() {
        let data = ProfileGenerator.shared.generate(options: Array(options), footnote: footnote.isEmpty ? nil : footnote)
        guard let data else { error = "生成失败"; return }
        let dest = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("DSProfile.mobileconfig")
        do {
            try data.write(to: dest, options: .atomic)
            savedURL = dest; error = nil
        } catch { self.error = error.localizedDescription }
    }
}

enum ProfileShareHelper {
    static func present(url: URL) {
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }
}
