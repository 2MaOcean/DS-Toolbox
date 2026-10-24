import Foundation
import Combine

struct ChatMessage: Codable {
    let role: String
    var content: String?
    var tool_calls: [ToolCall]?
    var tool_call_id: String?
}
struct ToolCall: Codable { let id: String; let type: String; let function: FunctionCall }
struct FunctionCall: Codable { let name: String; let arguments: String }

@MainActor
final class AIService: ObservableObject {
    static let shared = AIService()
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var pendingToolCall: ToolCall? = nil
    
    private var authorizedTools: [String: Date] = [:]
    private var apiKey: String { UserDefaults.standard.string(forKey: "ds.ai.apiKey") ?? "" }
    private var baseURL: String { UserDefaults.standard.string(forKey: "ds.ai.baseURL") ?? "https://api.openai.com/v1" }
    private var model: String { UserDefaults.standard.string(forKey: "ds.ai.model") ?? "gpt-4o" }
    
    func sendMessage(_ text: String) async {
        messages.append(ChatMessage(role: "user", content: text, tool_calls: nil, tool_call_id: nil))
        isLoading = true
        await runAgentLoop()
        isLoading = false
    }
