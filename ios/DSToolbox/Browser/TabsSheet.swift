import SwiftUI

struct TabsSheet: View {
    @ObservedObject var session = BrowserSession.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(session.tabs) { tab in
                    Button {
                        session.activeTabID = tab.id
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tab.title).lineLimit(1)
                                Text(tab.urlString).font(.caption)
                                    .foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            if session.activeTabID == tab.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .swipeActions {
                        Button("关闭", role: .destructive) { session.closeTab(tab.id) }
                    }
                }
            }
            .navigationTitle("标签页")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        session.newTab(); dismiss()
                    } label: { Image(systemName: "plus") }
                }
            }
        }
    }
}
