import SwiftUI

struct AgreementView: View {
    @AppStorage("ds.hasAcceptedAgreement") private var hasAccepted = false
    @AppStorage("ds.allowExploit") private var allowExploit = false
    @AppStorage("ds.allowAI") private var allowAI = false
    @State private var coreChecked = false
    @State private var exploitChecked = false
    @State private var aiChecked = false
    @State private var reachedBottom = false
    @State private var showRejectConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            Text("用户协议与免责声明")
                .font(.title2.bold())
                .padding(.top, 16).padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    agreementText
                    bottomMarker
                    coreAgreement
                    advancedSection
                }
                .padding()
            }
            .coordinateSpace(name: "agreementScroll")
            .onPreferenceChange(BottomOffsetKey.self) { v in
                if !reachedBottom && v <= 8 { reachedBottom = true }
            }

            bottomButtons
        }
        .alert("确认拒绝协议？", isPresented: $showRejectConfirm) {
            Button("退出应用", role: .destructive) { exit(0) }
            Button("取消", role: .cancel) {}
        } message: {
            Text("拒绝协议后应用无法使用，需要重新启动后再次确认。")
        }
    }

    private var agreementText: some View {
        VStack(alignment: .leading, spacing: 14) {
            Group {
                Text("一、基础条款").font(.headline)
                Text("1. 本软件仅用于个人合法用途，严禁下载、传播任何违反当地法律法规的内容。用户对所下载、存储、分发的全部数据承担全部法律责任。")
                Text("2. 使用本软件可能涉及网络请求、文件读写、系统级操作。用户应自行评估风险并做好数据备份。开发者不对任何数据丢失、系统损坏、账号封禁承担任何责任。")
                Text("3. 本软件包含第三方开源组件，其许可证随附于项目目录。用户在使用前应自行确认所用组件许可条款与本用途兼容。")
            }
            Group {
                Text("二、高级功能说明").font(.headline)
                Text("4. 漏洞调度、内核读写、越狱相关功能会尝试修改系统内存。在错误设备、错误偏移量下使用可能导致不可逆的系统损坏、无法开机、保修失效。仅在明确了解后果、并已备份全部数据的情况下使用。")
                Text("5. 文件系统级读写功能可绕过应用沙盒。错误路径、错误权限可能导致系统文件损坏。执行前请确认文件路径与目标一致。")
                Text("6. 进程管理、应用解密、SpringBoard 修改会影响其他应用与系统界面。执行后可能需要 respring 或重启设备。")
            }
            Group {
                Text("三、AI 功能说明").font(.headline)
                Text("7. AI 功能通过外部 API 通信，请求内容可能被第三方服务记录、处理。不得在 AI 对话中提交个人隐私、账号密码、身份证号等敏感信息。")
                Text("8. AI 具有工具调用能力（读写文件、下载链接）。每次高风险操作前会请求授权，但仍建议人工复核每次调用的路径与内容。")
                Text("9. 网页 AI 自动化功能会在后台定时向网页发送内容，可能违反目标网站的服务条款。用户应自行确认合规性。")
            }
            Group {
                Text("四、数据与隐私").font(.headline)
                Text("10. 本软件不使用任何远程服务器存储用户数据。所有 Cookie、凭证、文件仅存储在设备本地 Keychain 与沙盒中。")
                Text("11. 卸载应用会删除沙盒内全部数据，但 Keychain 凭证可能需要手动清理。")
            }
            Group {
                Text("五、免责声明").font(.headline)
                Text("12. 本软件按“现状”提供，不附带任何明示或暗示的担保，包括但不限于适销性、特定用途适用性、不侵权担保。")
                Text("13. 开发者不对因使用或无法使用本软件而产生的任何直接、间接、偶然、特殊、惩罚性损害承担责任，即使已被告知此类损害的可能性。")
                Text("14. 用户因违反当地法律法规使用本软件而导致的任何后果，由用户自行承担。")
            }
        }
        .font(.callout)
    }

    private var bottomMarker: some View {
        Color.clear.frame(height: 1)
            .background(GeometryReader { g in
                Color.clear.preference(
                    key: BottomOffsetKey.self,
                    value: g.frame(in: .named("agreementScroll")).maxY
                )
            })
    }

    private var coreAgreement: some View {
        Toggle(isOn: $coreChecked) {
            Text("我已阅读并同意上述全部核心条款").font(.headline)
        }
        .padding()
        .background(coreChecked ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    @ViewBuilder private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("高级功能（可选）").font(.footnote).foregroundStyle(.secondary)
            Toggle(isOn: $exploitChecked) {
                Text("同意使用越狱 / 漏洞功能，风险自担")
            }
            Toggle(isOn: $aiChecked) {
                Text("同意使用 AI 功能，接受第三方处理")
            }
            Text("不勾选则隐藏对应功能入口，需卸载重装才能重置。")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.top, 16)
        .opacity(reachedBottom ? 1.0 : 0.0)
        .frame(height: reachedBottom ? nil : 0)
    }

    private var bottomButtons: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Button {
                    showRejectConfirm = true
                } label: {
                    Text("不同意")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundStyle(.primary).cornerRadius(10)
                }

                Button {
                    allowExploit = exploitChecked
                    allowAI = aiChecked
                    hasAccepted = true
                } label: {
                    Text("同意并进入")
                        .frame(maxWidth: .infinity).padding()
                        .background(coreChecked ? Color.accentColor : Color.gray)
                        .foregroundStyle(.white).cornerRadius(10)
                }
                .disabled(!coreChecked)
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
    }
}

struct BottomOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = .greatestFiniteMagnitude
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}
