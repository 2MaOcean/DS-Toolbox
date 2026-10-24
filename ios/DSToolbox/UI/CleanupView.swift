import SwiftUI

struct CleanupView: View {
    @State private var items: [CleanableItem] = []
    @State private var selected: Set<String> = []
    @State private var cleaning = false

    var body: some View {
        Form {
            Section("可清理项目") {
                if items.isEmpty {
                    Text("正在扫描或没有可清理项").foregroundStyle(.secondary)
                }
                ForEach(items) { item in
                    row(for: item)
                }
            }
            Section {
                Button(cleaning ? "清理中…" : "清理选中项") {
                    performClean()
                }.disabled(selected.isEmpty || cleaning)
            }
        }
        .navigationTitle("垃圾清理")
        .task {
            items = await GarbageCleaner.shared.scan()
            selected = Set(items.filter { $0.isDefaultSelected }.map { $0.id })
        }
    }

    @ViewBuilder
    private func row(for item: CleanableItem) -> some View {
        Button {
            toggle(item.id)
        } label: {
            HStack {
                Image(systemName: selected.contains(item.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected.contains(item.id) ? .blue : .gray)
                VStack(alignment: .leading) {
                    Text(item.title)
                    Text(item.detail).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Text(byteString(item.sizeBytes)).font(.caption)
            }
        }.buttonStyle(.plain)
    }

    private func toggle(_ id: String) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }

    private func performClean() {
        cleaning = true
        Task {
            let toClean = items.filter { selected.contains($0.id) }
            _ = await GarbageCleaner.shared.clean(items: toClean)
            items = await GarbageCleaner.shared.scan()
            selected.removeAll()
            cleaning = false
        }
    }
}
