import SwiftUI

struct AISettingsView: View {
    @AppStorage("ds.ai.apiKey") private var apiKey = ""
    @AppStorage("ds.ai.model") private var model = "gpt-4o"
    @AppStorage("ds.ai.baseURL") private var baseURL = "https://api.openai.com/v1"
    @State private var testing = false
    @State private var result = ""

    private let models = ["gpt-4o", "gpt-4o-mini", "gpt-4.1", "claude-3-5-sonnet", "deepseek-chat"]

    var body: some View {
        Form {
            Section("API") {
                SecureField("API Key", text: $apiKey)
                TextField("Base URL", text: $baseURL)
                    .keyboardType(.URL).autocorrectionDisabled().textInputAutocapitalization(.never)
                Picker("模型", selection: $model) {
                    ForEach(models, id: \.self) { Text($0).tag($0) }
                }
            }
            Section {
                Button(testing ? "测试中..." : "测试连接") { test() }
                    .disabled(testing || apiKey.isEmpty)
                if !result.isEmpty {
                    Text(result).font(.caption).foregroundStyle(result.hasPrefix("✅") ? .green : .red)
                }
            }
            Section("说明") {
                Text("AI 会自动在需要时请求授权，写文件/下载 5 分钟内免重复确认。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("AI 设置")
    }

    private func test() {
        testing = true; result = ""
        Task {
            do {
                guard let url = URL(string: baseURL + "/models") else { throw NSError(domain: "AI", code: 0) }
                var req = URLRequest(url: url)
                req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                let (_, resp) = try await URLSession.shared.data(for: req)
                if let h = resp as? HTTPURLResponse, (200..<300).contains(h.statusCode) { result = "✅ 连接成功" }
                else { result = "❌ 认证失败" }
            } catch { result = "❌ \(error.localizedDescription)" }
            testing = false
        }
    }
}
