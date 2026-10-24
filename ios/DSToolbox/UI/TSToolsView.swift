import SwiftUI

struct TSToolsView: View {
    @State private var toast: String?
    @AppStorage("ds.allowExploit") private var allowExploit = false
    @AppStorage("ds.allowAI") private var allowAI = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                    // 基础功能（始终可见）
                    entry("系统监控", "gauge", "CPU / 内存 / 电池") { SystemMonitorView() }
                    entry("网络工具", "network", "DNS 与 IP 查询") { NetworkToolsView() }
                    entry("描述文件生成", "doc.badge.gearshape", "MDM 配置生成") { ProfileGeneratorView() }
                    
                    // 高级功能（必须勾选漏洞协议才显示）
                    if allowExploit {
                        entry("应用管理", "square.grid.3x3", "浏览应用") { AppManagerView() }
                        entry("IPA 管理器", "doc.zipper", "导入与安装 IPA") { IPAManagerView() }
                        entry("证书管理", "key", "p12 + mobileprovision") { CertificateManagementView() }
                        entry("JIT 控制", "bolt.horizontal.circle", "启用侧载 JIT") { JITControlView() }
                        entry("漏洞利用", "exclamationmark.shield", "自动化内核漏洞") { Expl                        
                        Button { if !TrollStoreService.shared.openTrollStore() { toast = "未安装 TrollStore" } } label: {
                            card(title: "打开 TrollStore", icon: "shippingbox", description: "跳转到巨魔商店")
                        }
                    }
                }.padding()
            }
            .navigationTitle("TS 工具")
            .alert("提示", isPresented: Binding(get: { toast != nil }, set: { if !$0 { toast = nil } })) { Button("好", role: .cancel) {} } message: { Text(toast ?? "") }
        }
    }

    private func entry<Content: View>(_ title: String, _ icon: String, _ desc: String, @ViewBuilder content: () -> Content) -> some View {
        NavigationLink { content() } label: { card(title: title, icon: icon, description: desc) }.buttonStyle(.plain)
    }
    private func card(title: String, icon: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(.tint)
            Text(title).font(.headline).foregroundStyle(.primary)
            Text(description).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.leading)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
