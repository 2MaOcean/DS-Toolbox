import SwiftUI

struct DownloadOptionsView: View {
    let host: String?
    @Environment(\.dismiss) private var dismiss
    @State private var options: DownloadOptions

    init(host: String?) {
        self.host = host
        _options = State(initialValue: host == nil ? DownloadOptionsStore.shared.global : DownloadOptionsStore.shared.options(for: host!))
    }

    var body: some View {
        Form {
            Section("并发与分片") {
                Stepper("并发分片：\(options.concurrency)", value: $options.concurrency, in: 1...32)
                Stepper("分片大小：\(options.segmentSizeMB) MB", value: $options.segmentSizeMB, in: 1...64)
            }
            Section("请求") {
                TextField("自定义 UA", text: Binding(get: { options.customUserAgent ?? "" }, set: { options.customUserAgent = $0.isEmpty ? nil : $0 }))
                TextField("自定义 Referer", text: Binding(get: { options.customReferer ?? "" }, set: { options.customReferer = $0.isEmpty ? nil : $0 }))
                Stepper("超时：\(Int(options.timeout)) 秒", value: $options.timeout, in: 5...120, step: 5)
                Stepper("重试次数：\(options.maxRetries)", value: $options.maxRetries, in: 0...10)
            }
            Section("限速") {
                Toggle("启用限速", isOn: Binding(get: { options.speedLimitMBps != nil }, set: { options.speedLimitMBps = $0 ? 5 : nil }))
                if let limit = options.speedLimitMBps {
                    Slider(value: Binding(get: { limit }, set: { options.speedLimitMBps = $0 }), in: 1...50, step: 1)
                    Text("\(Int(options.speedLimitMBps ?? 0)) MB/s").font(.caption)
                }
            }
            Section("开关") {
                Toggle("使用 Range 分片下载", isOn: $options.useRangeRequests)
                Toggle("跟随重定向", isOn: $options.followRedirects)
            }
        }
        .navigationTitle(host == nil ? "全局下载参数" : host!)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    if let h = host { DownloadOptionsStore.shared.setHostOptions(options, for: h) }
                    else { DownloadOptionsStore.shared.global = options; DownloadOptionsStore.shared.saveGlobal() }
                    dismiss()
                }
            }
        }
    }
}
