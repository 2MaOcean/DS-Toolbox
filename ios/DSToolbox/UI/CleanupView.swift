import SwiftUI
struct CleanupView: View {
    @State private var items: [CleanableItem] = []; @State private var selected: Set<String> = []; @State private var cleaning = false
    var body: some View {
        Form {
            Section("可清理项目") {
                ForEach(items) { i in
                    Button { if selected.contains(i.id) { selected.remove(i.id) } else { selected.insert(i.id) } } label: {
                        HStack { Image(systemName: selected.contains(i.id) ? "checkmark.circle.fill" : "circle").foregroundStyle(selected.contains(i.id) ? .blue : .gray); VStack(alignment: .leading) { Text(i.title); Text(i.detail).font(.caption2).foregroundStyle(.secondary) }; Spacer(); Text(byteString(i.sizeBytes)).font(.caption) }
                    }
                }
            }
            Section { Button(cleaning ? "清理中…" : "清理选中项") {
                cleaning = true
                Task { _ = await GarbageCleaner.shared.clean(items: items.filter { selected.contains($0.id) }); items = await GarbageCleaner.shared.scan(); cleaning = false }
            }.disabled(selected.isEmpty || cleaning) }
        }.navigationTitle("垃圾清理").task { items = await GarbageCleaner.shared.scan(); selected = Set(items.filter { $0.isDefaultSelected }.map { $0.id }) }
    }
}
