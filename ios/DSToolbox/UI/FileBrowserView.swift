import SwiftUI

struct FileBrowserView: View {
    @EnvironmentObject var env: ToolboxEnvironment
    @State private var leftSelected: Set<URL> = []
    @State private var rightSelected: Set<URL> = []

    private var rootDirectory: URL { DownloadDestinationService.shared.currentDirectory }

    var body: some View {
        Group {
            if env.dualPaneEnabled { dualPane } else { singlePane }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation { env.dualPaneEnabled.toggle() }
                } label: {
                    Image(systemName: env.dualPaneEnabled ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                }
            }
        }
    }

    private var singlePane: some View {
        FileBrowserPane(rootDirectory: rootDirectory, paneLabel: "文件", selected: $leftSelected)
    }

    private var dualPane: some View {
        HStack(spacing: 0) {
            FileBrowserPane(rootDirectory: rootDirectory, paneLabel: "左窗格", selected: $leftSelected).frame(maxWidth: .infinity)
            Divider()
            FileBrowserPane(rootDirectory: rootDirectory, paneLabel: "右窗格", selected: $rightSelected).frame(maxWidth: .infinity)
        }
    }
}
