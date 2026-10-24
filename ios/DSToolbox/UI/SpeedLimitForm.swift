import SwiftUI

struct SpeedLimitForm: View {
    @ObservedObject private var queue = DownloadQueue.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("限速") {
                Toggle("启用限速", isOn: $queue.speedLimitEnabled)
                if queue.speedLimitEnabled {
                    Stepper("上限：\(Int(queue.speedLimitValue / 1_048_576)) MB/s",
                            value: Binding(
                                get: { Int(queue.speedLimitValue / 1_048_576) },
                                set: { queue.speedLimitValue = Double($0) * 1_048_576 }
                            ), in: 1...100)
                }
            }
            Section("当前") {
                Text(queue.speedLimitEnabled ? "\(Int(queue.speedLimitValue / 1_048_576)) MB/s" : "不限速")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("限速")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
    }
}
