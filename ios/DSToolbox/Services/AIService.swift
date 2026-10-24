import Foundation
import Combine

struct AIToolDefinition: Codable { let type: String; let function: FunctionDef }
struct FunctionDef: Codable { let name: String; let description: String; let parameters: ParameterDef }
struct ParameterDef: Codable { let type: String; let properties: [String: PropertyDef]; let required: [String] }
struct PropertyDef: Codable { let type: String; let description: String }

struct ChatMessage: Codable {
    let role: String
    var content: String?
    var tool_calls: [ToolCall]?
    var tool_call_id: String?
}

struct ToolCall: Codable {
    let id: String
    let type: String
    let function: FunctionCall
}

struct FunctionCall: Codable {
    let name: String
    let arguments: String
}

@MainActor
final class AIService: ObservableObject {
    static let shared = AIService()
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var pendingToolCall: ToolCall?
    @Published var pendingCallKind: CallKind = .low

    enum CallKind { case low, high, readOutside }

    private var authorizedHighUntil: Date?
    private var readOutsideAuthorized = false
    private var apiKey: String { UserDefaults.standard.string(forKey: "ds.ai.apiKey") ?? "" }
    private var model: String { UserDefaults.standard.string(forKey: "ds.ai.model") ?? "gpt-4o" }
    private var baseURL: String { UserDefaults.standard.string(forKey: "ds.ai.baseURL") ?? "https://api.openai.com/v1" }

    func sendMessage(_ text: String) async {
        messages.append(ChatMessage(role: "user", content: text, tool_calls: nil, tool_call_id: nil))
        isLoading = true
        await runAgentLoop()
        isLoading = false
    }

    private func classify(_ call: ToolCall) -> CallKind {
        if ["write_file", "download_url"].contains(call.function.name) {
            if let until = authorizedHighUntil, Date() < until { return .low }
            return .high
        }
        if ["list_files", "read_file"].contains(call.function.name),
           let d = call.function.arguments.data(using: .utf8),
           let args = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           let path = args["path"] as? String,
           !path.hasPrefix(NSHomeDirectory()) {
            return readOutsideAuthorized ? .low : .readOutside
        }
        return .low
    }

    func approvePendingTool() {
        guard let call = pendingToolCall else { return }
        switch pendingCallKind {
        case .high:
            authorizedHighUntil = Date().addingTimeInterval(300)
        case .readOutside:
            readOutsideAuthorized = true
        case .low: break
        }
        pendingToolCall = nil
        Task { await runAgentLoop() }
    }

    func rejectPendingTool() {
        pendingToolCall = nil
        isLoading = false
    }

    private func runAgentLoop() async {
        var step = 0
        while step < 5 {
            step += 1
            do {
                let (content, toolCalls) = try await requestChatCompletion()
                if let tc = toolCalls, !tc.isEmpty {
                    messages.append(ChatMessage(role: "assistant", content: content, tool_calls: tc, tool_call_id: nil))
                    for call in tc {
                        let kind = classify(call)
                        if kind != .low {
                            pendingCallKind = kind
                            pendingToolCall = call
                            return
                        }
                        await execute(call)
                    }
                    continue
                }
                if let text = content, !text.isEmpty {
                    messages.append(ChatMessage(role: "assistant", content: text, tool_calls: nil, tool_call_id: nil))
                }
                return
            } catch {
                messages.append(ChatMessage(role: "assistant", content: "API 错误：\(error.localizedDescription)", tool_calls: nil, tool_call_id: nil))
                return
            }
        }
        messages.append(ChatMessage(role: "assistant", content: "已达到最大工具调用步数(5)，已中止。", tool_calls: nil, tool_call_id: nil))
    }

    private func execute(_ call: ToolCall) async {
        guard let d = call.function.arguments.data(using: .utf8),
              let args = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else {
            messages.append(ChatMessage(role: "tool", content: "参数解析失败", tool_calls: nil, tool_call_id: call.id))
            return
        }
        let result = (try? await AIToolExecutor.execute(name: call.function.name, arguments: args)) ?? "执行失败"
        messages.append(ChatMessage(role: "tool", content: result, tool_calls: nil, tool_call_id: call.id))
    }

    private func requestChatCompletion() async throws -> (String?, [ToolCall]?) {
        guard !apiKey.isEmpty, let url = URL(string: baseURL + "/chat/completions") else {
            throw NSError(domain: "AI", code: 400, userInfo: [NSLocalizedDescriptionKey: "未配置 API Key"])
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var msgs: [[String: Any]] = [["role": "system", "content": AIToolExecutor.systemPrompt]]
        for m in messages {
            var obj: [String: Any] = ["role": m.role]
            if let c = m.content { obj["content"] = c }
            if let tc = m.tool_calls {
                obj["tool_calls"] = tc.map { ["id": $0.id, "type": $0.type, "function": ["name": $0.function.name, "arguments": $0.function.arguments]] }
            }
            if let id = m.tool_call_id { obj["tool_call_id"] = id }
            msgs.append(obj)
        }

        let tools: [[String: Any]] = AIToolExecutor.availableTools.map { def in
            [
                "type": def.type,
                "function": [
                    "name": def.function.name,
                    "description": def.function.description,
                    "parameters": [
                        "type": "object",
                        "properties": def.function.parameters.properties.mapValues { ["type": $0.type, "description": $0.description] },
                        "required": def.function.parameters.required
                    ]
                ]
            ]
        }

        let body: [String: Any] = ["model": model, "messages": msgs, "tools": tools]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let h = resp as? HTTPURLResponse, !(200..<300).contains(h.statusCode) {
            throw NSError(domain: "AI", code: h.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(h.statusCode)"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let msg = first["message"] as? [String: Any] else {
            throw NSError(domain: "AI", code: 500, userInfo: [NSLocalizedDescriptionKey: "响应格式异常"])
        }

        let content = msg["content"] as? String
        var calls: [ToolCall]?
        if let raw = msg["tool_calls"] as? [[String: Any]] {
            calls = raw.compactMap { item in
                guard let id = item["id"] as? String,
                      let type = item["type"] as? String,
                      let fn = item["function"] as? [String: Any],
                      let name = fn["name"] as? String,
                      let args = fn["arguments"] as? String else { return nil }
                return ToolCall(id: id, type: type, function: FunctionCall(name: name, arguments: args))
            }
        }
        return (content, calls)
    }
}
