import SwiftUI
struct TabsSheet: View {
    @ObservedObject var session: BrowserSession
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                ForEach(session.tabs) { tab in
                    Button { session.activeTabID = tab.id; dismiss() } label: {
                        HStack {
                            VStack(alignment: .leading) { Text(tab.title).font(.headline); Text(tab.urlString).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                            Spacer()
                            if tab.id == session.activeTabID { Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue) }
                        }
                    }.swipeActions { Button(role: .destructive) { session.closeTab(tab.id) } label: { Label("关闭", systemImage: "xmark") } }
                }
            }.navigationTitle("标签").toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("新建") { session.newTab(); dismiss() } }
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
            }
        }
    }
}
