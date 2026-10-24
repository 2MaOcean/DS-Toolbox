import SwiftUI
import WebKit

struct WebAIView: View {
    @ObservedObject private var ctrl = WebAIController.shared
    @State private var prompt = ""
    @State private var urlInput = "https://chat.deepseek.com"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("URL", text: $urlInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled().textInputAutocapitalization(.never)
                Button("加载") {
                    if let u = URL(string: urlInput) { ctrl.webView.load(URLRequest(url: u)) }
                }.buttonStyle(.bordered)
            }.padding(.horizontal)
            WebAIWebView(webView: ctrl.webView)
            HStack {
                TextField("自动发送内容", text: $prompt)
                    .textFieldStyle(.roundedBorder)
                Button("自动发送") { ctrl.autoSend(prompt: prompt) }
                    .disabled(prompt.isEmpty)
                Button("停止") { ctrl.stopAutoSend() }
                    .foregroundStyle(.red)
            }.padding()
        }
        .navigationTitle("网页 AI")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { ctrl.stopAutoSend() }
    }
}

private struct WebAIWebView: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
