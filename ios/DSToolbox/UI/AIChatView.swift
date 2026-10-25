import SwiftUI

struct AIChatView: View {
    @StateObject private var ai = AIService.shared
    @State private var input = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(ai.messages.indices, id: \.self) { i in
                    if ai.messages[i].role != "tool" {
                        Text(ai.messages[i].content ?? "调用工具中...")
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            HStack {
                TextField("输入指令", text: $input).textFieldStyle(.roundedBorder)
                Button("发送") {
                    let t = input; input = ""
                    Task { await ai.sendMessage(t) }
                }.disabled(ai.isLoading)
            }.padding()
        }
        .navigationTitle("AI 助手")
        .alert("高风险授权", isPresented: Binding(
            get: { ai.pendingToolCall != nil },
            set: { if !$0 { ai.rejectPendingTool() } }
        )) {
            Button("同意") { ai.approvePendingTool() }
            Button("拒绝", role: .cancel) { ai.rejectPendingTool() }
        } message: {
            Text("AI 请求调用工具：\(ai.pendingToolCall?.function.name ?? "")")
        }
    }
}
