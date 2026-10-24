import SwiftUI

struct AgreementView: View {
    @AppStorage("ds.hasAcceptedAgreement") private var hasAcceptedAgreement = false
    @AppStorage("ds.allowExploit") private var allowExploit = false
    @AppStorage("ds.allowAI") private var allowAI = false
    
    @State private var coreChecked = false
    @State private var exploitChecked = false
    @State private var aiChecked = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "exclamationmark.shield.fill").foregroundStyle(.red).font(.title)
                Text("用户协议与免责声明").font(.title2.bold())
            }.padding(.top, 20)
            
            // 核心协议（最前面）
            Toggle(isOn: $coreChecked) {
                Text("我已阅读并同意全部核心免责声明").font(.headline)
            }
            .padding()
            .background(coreChecked ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("1. 风险自担：本软件提供文件管理与高级环境调度功能，可能导致系统崩溃、无限重启、数据丢失。一切损失由您自行承担。")
                    Text("2. 账号风险：网盘直链解析可能违反服务商协议，导致账号限速或封禁，开发者不承担任何责任。")
                    Text("3. 合规要求：严禁利用本软件下载、传播任何违法违规内容。")
                    Text("4. 责任豁免：用户使用本工具造成的一切直接或间接损害，均由用户自行承担，开发者不承担任何连带责任。")
                    
                    Divider().padding(.vertical, 10)
                    
                    // 两条独立互动勾选（默认关闭）
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $exploitChecked) {
                            Text("我同意使用越狱、TrollStore、漏洞利用及相关高级功能造成的一切损失，由我本人承担。").font(.footnote)
                        }
                        Toggle(isOn: $aiChecked) {
                            Text("我同意使用 AI 功能造成的一切损失，由我本人承担。").font(.footnote)
                        }
                    }.padding().background(Color.orange.opacity(0.1)).cornerRadius(8)
                }.padding()
            }
            
            Button {
                allowExploit = exploitChecked
                allowAI = aiChecked
                hasAcceptedAgreement = true
            } label: {
                Text("进入应用").frame(maxWidth: .infinity).padding().background(coreChecked ? Color.blue : Color.gray).foregroundStyle(.white).cornerRadius(10)
            }
            .padding()
            .disabled(!coreChecked)
        }
        .interactiveDismissDisabled()
    }
}
