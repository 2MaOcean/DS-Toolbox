import Foundation

enum AIToolExecutor {
    static let systemPrompt = "你是一个运行在 iOS 上的智能助手。可调用 list_files, read_file, write_file, download_url。路径请尽量使用沙盒内路径。"
    static let availableTools: [AIToolDefinition] = [
        AIToolDefinition(type: "function", function: FunctionDef(name: "list_files", description: "列出目录内容", parameters: ParameterDef(type: "object", properties: ["path": PropertyDef(type: "string", description: "绝对路径")], required: ["path"]))),
        AIToolDefinition(type: "function", function: FunctionDef(name: "read_file", description: "读取文件", parameters: ParameterDef(type: "object", properties: ["path": PropertyDef(type: "string", description: "路径")], required: ["path"]))),
        AIToolDefinition(type: "function", function: FunctionDef(name: "write_file", description: "写入文件(高风险)", parameters: ParameterDef(type: "object", properties: ["path": PropertyDef(type: "string", description: "路径"), "content": PropertyDef(type: "string", description: "内容")], required: ["path", "content"]))),
        AIToolDefinition(type: "function", function: FunctionDef(name: "download_url", description: "下载链接(高风险)", parameters: ParameterDef(type: "object", properties: ["url": PropertyDef(type: "string", description: "下载链接"), "fileName": PropertyDef(type: "string", description: "保存文件名")], required: ["url"])))
    ]

    @MainActor
    static func execute(name: String, arguments: [String: Any]) async throws -> String {
        switch name {
        case "list_files":
            let path = arguments["path"] as? String ?? "/"
            let list = try FileManager.default.contentsOfDirectory(atPath: path)
            return list.joined(separator: "\n")
        case "read_file":
            let path = arguments["path"] as? String ?? ""
            return try String(contentsOfFile: path, encoding: .utf8)
        case "write_file":
            guard let p = arguments["path"] as? String, let c = arguments["content"] as? String else { return "缺少参数" }
            try c.write(toFile: p, atomically: true, encoding: .utf8)
            return "写入成功：\(p)"
        case "download_url":
            guard let s = arguments["url"] as? String, let u = URL(string: s) else { return "无效 URL" }
            let name = (arguments["fileName"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? u.lastPathComponent
            let fileName = name.isEmpty ? "download.bin" : name
            let id = try DownloadQueue.shared.enqueue(url: u, fileName: fileName, credential: nil)
            return "已入队：\(id.uuidString)"
        default:
            return "未知工具：\(name)"
        }
    }
}
