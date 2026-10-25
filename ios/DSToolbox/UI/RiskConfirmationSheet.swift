import SwiftUI

struct RiskConfirmationSheet: View {
    enum RiskKind {
        case installIPA, runExploit, writeSystem
    }
    let kind: RiskKind
    let environment: EnvironmentReport
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("环境") {
                    LabeledContent("iOS", value: environment.iosVersion)
                    LabeledContent("芯片", value: environment.chip.rawValue)
                    LabeledContent("沙盒", value: environment.sandboxLevel.rawValue)
                    LabeledContent("越狱", value: environment.isJailbroken ? "是" : "否")
                    LabeledContent("TrollStore", value: environment.isTrollStore ? "是" : "否")
                }
                Section("风险") {
                    Text("此操作可能导致系统不稳定或数据丢失，请确认已备份。")
                        .font(.callout).foregroundStyle(.red)
                }
                if let r = environment.blockedReason {
                    Section("限制") { Text(r).foregroundStyle(.orange) }
                }
                Section {
                    Button("我已知晓，继续") { onConfirm() }.foregroundStyle(.red).bold()
                    Button("取消", role: .cancel) { onCancel() }
                }
            }
            .navigationTitle("风险确认")
        }
    }
}
