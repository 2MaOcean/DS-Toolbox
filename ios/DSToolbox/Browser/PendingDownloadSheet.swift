import SwiftUI
struct PendingDownloadSheet: View {
    let item: BrowserSession.PendingDownload
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var env: ToolboxEnvironment
    @State private var fileName: String
    @State private var useSiteCredential = true
    init(item: BrowserSession.PendingDownload) { self.item = item; _fileName = State(initialValue: item.suggestedFileName) }
    var body: some View {
        NavigationStack {
            Form {
                Section("下载信息") {
                    LabeledContent("来源", value: item.host)
                    TextField("文件名", text: $fileName)
                    Text(item.url.absoluteString).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                }
                if SiteCredentialStore.shared.credential(for: item.host) != nil {
                    Section { Toggle("使用该站点已保存的登录凭证", isOn: $useSiteCredential) }
                }
                Section {
                    Button("加入下载队列") {
                        let siteCred = useSiteCredential ? SiteCredentialStore.shared.credential(for: item.host) : nil
                        let resolvedOptions = DownloadOptionsStore.shared.options(for: item.host)
                        _ = try? env.queue.enqueue(url: item.url, fileName: fileName, credential: nil, siteCredential: siteCred, options: resolvedOptions)
                        dismiss()
                    }
                }
            }.navigationTitle("下载").toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
        }
    }
}
