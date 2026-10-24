import SwiftUI

struct AgreementView: View {
    @AppStorage("ds.hasAcceptedAgreement") private var hasAccepted = false
    @AppStorage("ds.allowExploit") private var allowExploit = false
    @AppStorage("ds.allowAI") private var allowAI = false
    @State private var coreChecked = false
    @State private var exploitChecked = false
    @State private var aiChecked = false
    @State private var scrolled = false

    var body: some View {
        VStack(spacing: 0) {
            Text("用户协议与免责声明")
                .font(.title2.bold()).padding()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Group {
                        Text("一、基础条款").font(.headline)
                        Text("1. 本软件仅用于个人合法用途，严禁下载、传播违法内容。")
                        Text("2. 使用本软件所产生的一切后果由用户自行承担。")
                        Text("3. 开发者不对任何数据丢失、系统损坏负责。")
                    }
                    Group {
                        Text("二、高级功能").font(.headline)
                        Text("4. 漏洞调度、越狱相关功能可能导致系统不稳定，仅在明确了解风险后使用。")
                        Text("5. AI 功能会通过外部 API，请求内容可能被第三方处理。")
                        Text("6. 文件写入、下载工具可修改系统文件，请确保已备份。")
                    }
                    Group {
                        Text("三、授权须知").font(.headline)
                        Toggle(isOn: $exploitChecked) {
                            Text("我同意使用越狱/漏洞功能，风险自担")
                        }
                        Toggle(isOn: $aiChecked) {
                            Text("我同意使用 AI 功能，接受第三方处理")
                        }
                        Text("未勾选的高级功能将在主界面隐藏，需卸载重装才能重置。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding()
                .onAppear { scrolled = true }
            }
            Toggle(isOn: $coreChecked) {
                Text("我已阅读并同意全部核心条款").font(.headline)
            }
            .padding()
            .background(coreChecked ? Color.green.opacity(0.1) : Color.red.opacity(0.1))

            Button {
                allowExploit = exploitChecked
                allowAI = aiChecked
                hasAccepted = true
            } label: {
                Text("进入应用")
                    .frame(maxWidth: .infinity).padding()
                    .background(coreChecked ? Color.accentColor : Color.gray)
                    .foregroundStyle(.white).cornerRadius(10)
            }
            .padding()
            .disabled(!coreChecked)
        }
    }
}
