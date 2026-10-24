import SwiftUI
import WebKit

struct AIChatView: View {
    @StateObject private var ai = AIService.shared
    @StateObject private var webAI = WebAIController.shared
    @State private var input = ""
    @State private var mode = 0 // 0: API, 1: 网页版
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("模式", selection: $mode) {
                Text("API 模式").tag(0)
                Text("网页免费模式").tag(1)
            }.pickerStyle(.segmented).padding()
            
            if mode == 0 {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(ai.messages.indices, id: \.self) { i in
                                let msg = ai.messages[i]
                                if msg.role != "tool" {
                                    HStack {
                                        if msg.role == "user" { Spacer() }
                                        Text(msg.content ?? "⚙️ 正在调用本地工具...")
                                            .padding(10)
                                            .background(msg.role == "user" ? Color.blue : Color.gray.opacity(0.2))
                                            .foregroundStyle(msg.role == "user" ? .white : .primary)
                                            .cornerRadius(10)
                                        if msg.role == "assistant" { Spacer() }
                                    }.id(i)
                                }
                            }
                        }.padding()
                    }
                    .onChange(of: ai.messages.count) { _, _ in
                        if ai.messages.count > 0 { proxy.scrollTo(ai.messages.count - 1) }
                    }
                }
                HStack {
                    TextField("告诉 AI 帮你操作文件或下载", text: $input).textFieldStyle(.roundedBorder)
                    Button("发送") {
                        let t = input; input = ""
                        Task { await ai.sendMessage(t) }
                    }.disabled(ai.isLoading || input.isEmpty)
                }.padding()
            } else {
                AIWebViewContainer(webView: webAI.webView)
                HStack {
                    TextField("输入要发给网页版 AI 的内容", text: $input).textFieldStyle(.roundedBorder)
                    Button("定时自动发送") {
                        webAI.autoSend(prompt: input)
                    }.buttonStyle(.borderedProminent)
                    Button("停止") { webAI.stopAutoSend() }.buttonStyle(.bordered)
                }.padding()
            }
        }
        .alert("高风险操作授权", isPresented: Binding(get: { ai.pendingToolCall != nil }, set: { if !$0 { ai.rejectPendingTool() } })) {
            Button("同意 (5分钟内有效)") { ai.approvePendingTool() }
            Button("拒绝", role: .cancel) { ai.rejectPendingTool() }
        } message: {
            Text("AI 请求执行高风险操作：\(ai.pendingToolCall?.function.name ?? "")。是否授权？")
        }
        .navigationTitle("AI 助手")
        .toolbar { Button("设置") { showSettings = true } }
        .sheet(isPresented: $showSettings) { AISettingsView() }
    }
}

struct AIWebViewContainer: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct AISettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("ds.ai.apiKey") var apiKey = ""
    @AppStorage("ds.ai.baseURL") var baseURL = "https://api.openai.com/v1"
    @AppStorage("ds.ai.model") var model = "gpt-4o"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("API 配置") {
                    TextField("Base URL", text: $baseURL)
                    TextField("API Key", text: $apiKey)
                    TextField("模型名 (如 gpt-4o)", text: $model)
                }
                Section("说明") {
                    Text("API 模式支持调用本地文件工具。如果不填 API Key，可直接在 AI 页面切换到“网页免费模式”。")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("AI 设置")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
        }
    }
}
