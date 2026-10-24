import SwiftUI

struct FileBrowserView: View {
    @EnvironmentObject var env: ToolboxEnvironment
    @ObservedObject private var dest = DownloadDestinationService.shared
    @State private var showPicker = false
    private var rootDirectory: URL { dest.currentDirectory }

    var body: some View {
        Group {
            if env.dualPaneEnabled {
                HStack(spacing: 0) {
                    FileBrowserPane(rootDirectory: rootDirectory, paneLabel: "左").frame(maxWidth: .infinity)
                    Divider()
                    FileBrowserPane(rootDirectory: rootDirectory, paneLabel: "右").frame(maxWidth: .infinity)
                }
            } else {
                FileBrowserPane(rootDirectory: rootDirectory, paneLabel: "文件")
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showPicker = true } label: { Image(systemName: "folder.badge.gearshape") }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation { env.dualPaneEnabled.toggle() }
                } label: {
                    Image(systemName: env.dualPaneEnabled ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            DirectoryPickerView { url in
                showPicker = false
                try? dest.setDirectory(url)
            }
        }
    }
}
