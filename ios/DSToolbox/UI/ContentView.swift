import SwiftUI

struct ContentView: View {
    @EnvironmentObject var env: ToolboxEnvironment
    @State private var showTerminal = false

    var body: some View {
        TabView {
            Tab("网盘", systemImage: "cloud") { DriveView() }
            Tab("浏览器", systemImage: "safari") { BrowserView() }
            Tab("下载", systemImage: "arrow.down.circle") { DownloadListView() }
            Tab("文件", systemImage: "folder") { FileBrowserView() }
            Tab("TS 工具", systemImage: "wrench.and.screwdriver") { TSToolsView() }
            Tab("设置", systemImage: "gear") { SettingsView() }
        }
        .tabViewStyle(.sidebarAdaptable)
        .overlay(alignment: .topTrailing) { terminalButton }
        .fullScreenCover(isPresented: $showTerminal) { TerminalView() }
    }

    private var terminalButton: some View {
        Button { showTerminal = true } label: {
            Image(systemName: "terminal.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.accentColor))
                .shadow(radius: 3, y: 1)
        }
        .padding(.top, 52)
        .padding(.trailing, 16)
    }
}
