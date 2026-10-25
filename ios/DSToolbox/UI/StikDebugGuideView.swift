import SwiftUI

struct StikDebugGuideView: View {
    @ObservedObject private var svc = StikDebugService.shared
    @State private var bundleID = ""

    var body: some View {
        Form {
            Section("状态") {
                LabeledContent("可启用 JIT", value: svc.canEnableJIT ? "是" : "否")
                LabeledContent("已连接", value: svc.isAttached ? "是" : "否")
            }
            Section("挂载") {
                TextField("Bundle ID", text: $bundleID)
                    .autocorrectionDisabled().textInputAutocapitalization(.never)
                Button("连接") { svc.attach(bundleID: bundleID) }
                    .disabled(bundleID.isEmpty)
                if svc.isAttached { Button("断开", role: .destructive) { svc.detach() } }
            }
            Section("说明") {
                Text("StikDebug 完整集成需要 libidevice_ffi（当前未链接）。此处提供占位功能。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("StikDebug")
    }
}
