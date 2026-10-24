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

    private func runAgentLoop() async {
        while true {
            do {
                let (content, toolCalls) = try await requestChatCompletion()
                if let tc = toolCalls, !tc.isEmpty {
                    messages.append(ChatMessage(role: "assistant", content: content, tool_calls: tc, tool_call_id: nil))
                    for call in tc {
                        if AIToolExecutor.riskLevel(for: call.function.name) == .high {
                            if let time = authorizedTools[call.function.name], Date().timeIntervalSince(time) < 300 {
                                // 5分钟内有效
                            } else {
                                pendingToolCall = call
                                return // 暂停，等待用户操作
                            }
                        }
                        if let argsData = call.function.arguments.data(using: .utf8), let args = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any] {
                            let result = try await AIToolExecutor.execute(name: call.function.name, arguments: args)
                            messages.append(ChatMessage(role: "tool", content: result, tool_calls: nil, tool_call_id: call.id))
                        }
                    }
                } else {
                    messages.append(ChatMessage(role: "assistant", content: content, tool_calls: nil, tool_call_id: nil))
                    break
                }
            } catch {
                messages.append(ChatMessage(role: "assistant", content: "错误: \(error.localizedDescription)", tool_calls: nil, tool_call_id: nil))
                break
            }
        }
    }
    
    func approvePendingTool() {
        guard let call = pendingToolCall else { return }
        authorizedTools[call.function.name] = Date()
        pendingToolCall = nil
        Task { 
            if let argsData = call.function.arguments.data(using: .utf8), let args = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any] {
                let result = (try? await AIToolExecutor.execute(name: call.function.name, arguments: args)) ?? "执行失败"
                messages.append(ChatMessage(role: "tool", content: result, tool_calls: nil, tool_call_id: call.id))
            }
            await runAgentLoop() 
        }
    }
    
    func rejectPendingTool() {
        if let call = pendingToolCall {
            messages.append(ChatMessage(role: "tool", content: "用户拒绝了操作", tool_calls: nil, tool_call_id: call.id))
            messages.append(ChatMessage(role: "assistant", content: "操作已被用户拒绝。", tool_calls: nil, tool_call_id: nil))
        }
        pendingToolCall = nil
        isLoading = false
    }

    private func requestChatCompletion() async throws -> (String?, [ToolCall]?) {
        guard !apiKey.isEmpty, let url = URL(string: "\(baseURL)/chat/completions") else { throw NSError(domain: "AI", code: 400, userInfo: [NSLocalizedDescriptionKey: "请先在设置中填写 API Key"]) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var apiMessages: [[String: Any]] = [["role": "system", "content": AIToolExecutor.systemPrompt]]
        apiMessages += messages.map { m -> [String: Any] in
            var dict: [String: Any] = ["role": m.role]
            if let c = m.content { dict["content"] = c }
            if let tc = m.tool_calls { dict["tool_calls"] = tc.map { ["id": $0.id, "type": $0.type, "function": ["name": $0.function.name, "arguments": $0.function.arguments]] } }
            if let tci = m.tool_call_id { dict["tool_call_id"] = tci }
            return dict
        }
        
        let body: [String: Any] = ["model": model, "messages": apiMessages, "tools": AIToolExecutor.availableTools.map { t -> [String: Any] in
            ["type": t.type, "function": ["name": t.function.name, "description": t.function.description, "parameters": ["type": "object", "properties": t.function.parameters.properties.mapValues { ["type": $0.type, "description": $0.description] }, "required": t.function.parameters.required]]]
        }]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: req)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let choices = json["choices"] as? [[String: Any]], let first = choices.first, let message = first["message"] as? [String: Any] {
            let content = message["content"] as? String
            var tCalls: [ToolCall]? = nil
            if let tcs = message["tool_calls"] as? [[String: Any]] {
                tCalls = tcs.compactMap { tc in
                    guard let id = tc["id"] as? String, let type = tc["type"] as? String, let fn = tc["function"] as? [String: Any], let name = fn["name"] as? String, let args = fn["arguments"] as? String else { return nil }
                    return ToolCall(id: id, type: type, function: FunctionCall(name: name, arguments: args))
                }
            }
            return (content, tCalls)
        }
        throw NSError(domain: "AI", code: 500, userInfo: [NSLocalizedDescriptionKey: "API 响应异常"])
    }
}
