import SwiftUI

struct DownloadOptionsView: View {
    let host: String?
    @ObservedObject private var store = DownloadOptionsStore.shared
    @State private var options: DownloadOptions

    init(host: String?) {
        self.host = host
        let initial = host.flatMap { h in DownloadOptionsStore.shared.options(for: h) } ?? DownloadOptionsStore.shared.global
        _options = State(initialValue: initial)
    }

    var body: some View {
        Form {
            Section("并发与分片") {
                Stepper("并发数：\(options.concurrency)", value: $options.concurrency, in: 1...32)
                Stepper("分片 MB：\(options.segmentSizeMB)", value: $options.segmentSizeMB, in: 1...64)
            }
            Section("重试与超时") {
                Stepper("最大重试：\(options.maxRetries)", value: $options.maxRetries, in: 0...10)
                Stepper("超时秒：\(Int(options.timeout))", value: Binding(
                    get: { Int(options.timeout) }, set: { options.timeout = TimeInterval($0) }
                ), in: 5...120)
            }
            Section("限速") {
                Toggle("启用限速", isOn: Binding(
                    get: { options.speedLimitMBps != nil },
                    set: { options.speedLimitMBps = $0 ? 5.0 : nil }
                ))
                if options.speedLimitMBps != nil {
                    Stepper("限速 MB/s：\(Int(options.speedLimitMBps ?? 5))", value: Binding(
                        get: { Int(options.speedLimitMBps ?? 5) }, set: { options.speedLimitMBps = Double($0) }
                    ), in: 1...100)
                }
            }
            Section("请求头") {
                TextField("UA（留空用指纹）", text: Binding(
                    get: { options.customUserAgent ?? "" },
                    set: { options.customUserAgent = $0.isEmpty ? nil : $0 }
                ))
                TextField("Referer（留空用指纹）", text: Binding(
                    get: { options.customReferer ?? "" },
                    set: { options.customReferer = $0.isEmpty ? nil : $0 }
                ))
            }
            Section {
                Button("保存") { save() }
            }
        }
        .navigationTitle(host.map { "参数：\($0)" } ?? "下载参数")
    }

    private func save() {
        if let h = host { store.setHostOptions(options, for: h) } else { store.global = options; store.saveGlobal() }
    }
}
