import SwiftUI
struct JITControlView: View {
    @State private var apps: [InstalledApp] = []
    @State private var selectedApp: InstalledApp?
    var body: some View {
        List {
            Section { if !JITService.shared.isStikDebugInstalled { Text("请先安装 StikDebug").foregroundStyle(.red); Button("前往下载") { JITService.shared.openStikDebugStore() } } }
            Section("选择目标应用") {
                ForEach(apps) { app in
                    Button { selectedApp = app } label: { HStack { Text(app.displayName); Spacer(); if selectedApp?.bundleID == app.bundleID { Image(systemName: "checkmark").foregroundStyle(.blue) } } }
                }
            }
            Section { Button("为选中的应用启用 JIT") { if let app = selectedApp { _ = JITService.shared.enableJIT(bundleID: app.bundleID) } }.disabled(selectedApp == nil) }
        }.navigationTitle("JIT 控制").onAppear { apps = AppScanner.shared.scanAllApps() }
    }
}
