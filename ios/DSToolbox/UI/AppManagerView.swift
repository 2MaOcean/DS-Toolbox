import SwiftUI

struct AppManagerView: View {
    @State private var apps: [InstalledApp] = []
    @State private var query = ""

    private var filtered: [InstalledApp] {
        query.isEmpty ? apps : apps.filter { $0.displayName.localizedCaseInsensitiveContains(query) || $0.bundleID.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        List(filtered) { app in
            VStack(alignment: .leading, spacing: 4) {
                Text(app.displayName).font(.headline)
                Text(app.bundleID).font(.caption).foregroundStyle(.secondary)
                Text(app.bundlePath).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .searchable(text: $query)
        .navigationTitle("应用管理")
        .overlay {
            if apps.isEmpty {
                ContentUnavailableView("未检测到应用", systemImage: "app", description: Text("需要越狱或 TrollStore 环境"))
            }
        }
        .onAppear { apps = AppScanner.shared.scanAllApps() }
    }
}
