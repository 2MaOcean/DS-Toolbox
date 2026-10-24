import Foundation

enum ToolRiskLevel: String { case low, high }

struct AIToolDefinition: Codable {
    let type: String
    let function: FunctionDef
}
struct FunctionDef: Codable {
    let name: String
    let description: String
    let parameters: ParameterDef
}
struct ParameterDef: Codable {
    let type: String
    let properties: [String: PropertyDef]
    let required: [String]
}
struct PropertyDef: Codable {
    let type: String
    let description: String
}

enum AIToolExecutor {
    static let systemPrompt = """
    你是一个运行在 iOS 上的智能文件与下载助手。你可以调用以下工具：
    1. list_files(path): 列出目录内容。
    2. read_file(path): 读取文本文件。
    3. write_file(path, content): 写入文件（高风险）。
    4. download_url(url, filename): 加入下载队列（高风险）。
    请根据用户需求自动调用工具。高风险操作需要用户授权。
    """
    
    static let availableTools: [AIToolDefinition] = [
        AIToolDefinition(type: "function", function: FunctionDef(name: "list_files", description: "列出目录内容", parameters: ParameterDef(type: "object", properties: ["path": PropertyDef(type: "string", description: "绝对路径")], required: ["path"]))),
        AIToolDefinition(type: "function", function: FunctionDef(name: "read_file", description: "读取文本文件", parameters: ParameterDef(type: "object", properties: ["path": PropertyDef(type: "string", description: "文件绝对路径")], required: ["path"]))),
        AIToolDefinition(type: "function", function: FunctionDef(name: "write_file", description: "写入文件(高风险)", parameters: ParameterDef(type: "object", properties: ["path": PropertyDef(type: "string", description: "文件路径"), "content": PropertyDef(type: "string", description: "内容")], required: ["path", "content"]))),
        AIToolDefinition(type: "function", function: FunctionDef(name: "download_url", description: "加入下载队列(高风险)", parameters: ParameterDef(type: "object", properties: ["url": PropertyDef(type: "string", description: "链接"), "filename": PropertyDef(type: "string", description: "文件名")], required: ["url", "filename"])))
    ]
    
    static func riskLevel(for toolName: String) -> ToolRiskLevel {
        return ["write_file", "download_url"].contains(toolName) ? .high : .low
    }

    @MainActor
    static func execute(name: String, arguments: [String: Any]) async throws -> String {
        let sandboxRoot = DownloadDestinationService.shared.currentDirectory.path
        let allowFullDisk = UserDefaults.standard.bool(forKey: "ds.allowExploit")
        
        func checkPath(_ path: String) throws -> URL {
            let url = URL(fileURLWithPath: path).standardizedFileURL
            if !allowFullDisk && !url.path.hasPrefix(sandboxRoot) { throw NSError(domain: "AI", code: 403, userInfo: [NSLocalizedDescriptionKey: "安全限制：只能操作 Downloads 目录"]) }
            return url
        }
        
        switch name {
        case "list_files":
            let url = try checkPath(arguments["path"] as? String ?? sandboxRoot)
            return try FileManager.default.contentsOfDirectory(atPath: url.path).joined(separator: "\n")
        case "read_file":
            guard let path = arguments["path"] as? String else { return "缺少参数" }
            return try String(contentsOf: checkPath(path), encoding: .utf8)
        case "write_file":
            guard let path = arguments["path"] as? String, let content = arguments["content"] as? String else { return "缺少参数" }
            try content.write(to: checkPath(path), atomically: true, encoding: .utf8)
            return "写入成功"
        case "download_url":
            guard let urlStr = arguments["url"] as? String, let url = URL(string: urlStr), let name = arguments["filename"] as? String else { return "参数无效" }
            guard let cred = CredentialStore.shared.load(kind: .baidu) else { return "请先登录网盘" }
            try DownloadQueue.shared.enqueue(url: url, fileName: name, credential: cred)
            return "已加入下载队列"
        default: return "未知工具"
        }
    }
}
