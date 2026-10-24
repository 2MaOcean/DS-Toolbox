import SwiftUI

struct IPAActionSheet: View {
    let ipa: ImportedIPA
    let onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var running = false

    var body: some View {
        NavigationStack {
            Form {
                Section("应用信息") {
                    LabeledContent("名称", value: ipa.displayName ?? "?")
                    LabeledContent("Bundle ID", value: ipa.bundleID ?? "?")
                    LabeledContent("版本", value: ipa.version ?? "?")
                    LabeledContent("大小", value: byteString(ipa.size))
                    if ipa.isEncrypted { Label("已加密（需解密）", systemImage: "lock").foregroundStyle(.red) }
                }
                Section("安装方式") {
                    ForEach(InstallMethod.allCases) { m in
                        Button(m.rawValue) { install(using: m) }
                    }
                }
                if !message.isEmpty { Section { Text(message).foregroundStyle(.secondary) } }
            }
            .navigationTitle("IPA 操作")
            .disabled(running)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
        }
    }

    private func install(using m: InstallMethod) {
        running = true
        Task {
            do {
                try await IPAInstallService.shared.install(ipa: ipa.fileURL, using: m)
                message = "已启动：\(m.rawValue)"
            } catch { message = error.localizedDescription }
            running = false
            onFinish()
        }
    }
}
