import SwiftUI

struct AppManagerView: View {
    @State private var apps: [InstalledApp] = []
    @State private var search = ""
    
    var body: some View {
        List(apps.filter { search.isEmpty || $0.displayName.localizedCaseInsensitiveContains(search) }) { app in
            VStack(alignment: .leading) {
                Text(app.displayName).font(.headline)
                Text(app.bundleID).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .searchable(text: $search)
        .navigationTitle("应用管理")
        .onAppear { apps = AppScanner.shared.scanAllApps() }
    }
}
