import SwiftUI

struct LaraFileManagerSheet: View {
    @ObservedObject private var lara = LaraFileManager.shared
    @Environment(\.dismiss) private var dismiss
    let onSelect: (URL) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("KRW 状态") {
                    Text(lara.krwAvailable ? "已就绪" : "未就绪")
                        .foregroundStyle(lara.krwAvailable ? .green : .secondary)
                    Text(lara.status).font(.caption)
                }
                Section("可访问根目录") {
                    ForEach(lara.accessRoots) { root in
                        Button {
                            onSelect(root.url)
                            dismiss()
                        } label: {
                            HStack {
                                Text(root.label)
                                Spacer()
                                Text(root.path).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Lara 文件")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
        }
    }
}
