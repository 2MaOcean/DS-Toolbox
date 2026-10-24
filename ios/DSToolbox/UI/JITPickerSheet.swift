import SwiftUI

struct JITPickerSheet: View {
    @ObservedObject private var mgr = JITManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("选择 JIT 后端") {
                    ForEach(JITBackend.allCases) { backend in
                        Button {
                            let r = mgr.confirm(backend: backend)
                            mgr.lastResult = r
                            dismiss()
                        } label: {
                            HStack {
                                Text(backend.rawValue)
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption)
                            }
                        }
                    }
                }
                if let r = mgr.lastResult {
                    Section("上次结果") {
                        Text(r.message).foregroundStyle(r.success ? .green : .red)
                    }
                }
            }
            .navigationTitle("启用 JIT")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
        }
    }
}
