import SwiftUI

struct StikDebugGuideView: View {
    @ObservedObject private var bridge = StikDebugBridge.shared
    @State private var bundleID = ""
    @State private var pidText = ""

    var body: some View {
        Form {
            Section("状态") {
                LabeledContent("StikDebug", value: StikDebugProvider.shared.isInstalled ? "已安装" : "未安装")
            }
            Section("JIT / 启动") {
                TextField("Bundle ID", text: $bundleID)
                    .autocorrectionDisabled().textInputAutocapitalization(.never)
                Button("启用 JIT") {
                    _ = bridge.launchAppWithJIT(bundleID: bundleID)
                }.disabled(bundleID.isEmpty)
                Button("启动应用") {
                    _ = bridge.launchApp(bundleID: bundleID)
                }.disabled(bundleID.isEmpty)
            }
            Section("进程管理") {
                TextField("PID", text: $pidText).keyboardType(.numberPad)
                Button("结束进程", role: .destructive) {
                    if let p = Int(pidText) { _ = bridge.killProcess(pid: p) }
                }.disabled(pidText.isEmpty)
            }
        }
        .navigationTitle("StikDebug")
    }
}
