import SwiftUI

struct ContentView: View {
    @EnvironmentObject var env: ToolboxEnvironment
    var body: some View {
        TabView {
            Tab("网盘", systemImage: "cloud") { Text("网盘解析（占位）") }
            Tab("浏览器", systemImage: "safari") { BrowserView() }
            Tab("下载", systemImage: "arrow.down.circle") { DownloadListView() }
            Tab("文件", systemImage: "folder") { FileBrowserView() }
            Tab("TS 工具", systemImage: "wrench.and.screwdriver") { TSToolsView() }
            Tab("设置", systemImage: "gear") { SettingsView() }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}
