import SwiftUI

struct ProcessListView: View {
    @ObservedObject private var pm = ProcessManager.shared
    @State private var query = ""

    private var filtered: [ProcessInfoEntry] {
        query.isEmpty ? pm.processes : pm.processes.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        List(filtered) { p in
            HStack {
                VStack(alignment: .leading) {
                    Text(p.name)
                    Text("PID \(p.pid)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("结束", role: .destructive) { _ = pm.kill(pid: p.pid) }
            }
        }
        .searchable(text: $query)
        .navigationTitle("进程管理")
        .onAppear { pm.refresh() }
        .refreshable { pm.refresh() }
    }
}
