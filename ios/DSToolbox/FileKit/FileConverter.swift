import Foundation

enum FileConversion: String, CaseIterable, Identifiable {
    case plistToXML, xmlToBinary, plistToJSON, jsonToPlist
    case jsonPretty, jsonCompact, base64Encode, base64Decode, urlEncode, urlDecode
    var id: String { rawValue }
    var label: String {
        switch self {
        case .plistToXML: return "Plist → XML"; case .xmlToBinary: return "XML Plist → 二进制"
        case .plistToJSON: return "Plist → JSON"; case .jsonToPlist: return "JSON → Plist"
        case .jsonPretty: return "JSON 格式化"; case .jsonCompact: return "JSON 压缩"
        case .base64Encode: return "Base64 编码"; case .base64Decode: return "Base64 解码"
        case .urlEncode: return "URL 编码"; case .urlDecode: return "URL 解码"
        }
    }
    var outputExtension: String {
        switch self {
        case .plistToXML, .xmlToBinary, .jsonToPlist: return "plist"
        case .plistToJSON, .jsonPretty, .jsonCompact: return "json"
        default: return "txt"
        }
    }
}

enum ConverterError: LocalizedError {
    case unsupported, parseFailed(String), writeFailed(String)
    var errorDescription: String? {
        switch self {
        case .unsupported: return "不支持的转换类型"
        case .parseFailed(let s): return "解析失败：\(s)"
        case .writeFailed(let s): return "写入失败：\(s)"
        }
    }
}

enum FileConverter {
    static func convert(source: URL, conversion: FileConversion, to destinationDirectory: URL) throws -> URL {
        let outputName = source.deletingPathExtension().lastPathComponent + ".\(conversion.outputExtension)"
        var dest = destinationDirectory.appendingPathComponent(outputName)
        if FileManager.default.fileExists(atPath: dest.path) {
            let base = (outputName as NSString).deletingPathExtension; let ext = (outputName as NSString).pathExtension; var i = 1
            while FileManager.default.fileExists(atPath: dest.path) { dest = destinationDirectory.appendingPathComponent("\(base) (\(i)).\(ext)"); i += 1 }
        }
        let inputData: Data
        do { inputData = try Data(contentsOf: source) } catch { throw ConverterError.parseFailed(error.localizedDescription) }

        switch conversion {
        case .plistToXML: try convertPlist(data: inputData, format: .xml, to: dest)
        case .xmlToBinary: try convertPlist(data: inputData, format: .binary, to: dest)
        case .plistToJSON: try convertPlistToJSON(data: inputData, to: dest)
        case .jsonToPlist: try convertJSONToPlist(data: inputData, to: dest)
        case .jsonPretty: try formatJSON(data: inputData, pretty: true, to: dest)
        case .jsonCompact: try formatJSON(data: inputData, pretty: false, to: dest)
        case .base64Encode: try inputData.base64EncodedData().write(to: dest)
        case .base64Decode:
            guard let text = String(data: inputData, encoding: .utf8), let decoded = Data(base64Encoded: text.trimmingCharacters(in: .whitespacesAndNewlines)) else { throw ConverterError.parseFailed("不是合法的 base64") }
            try decoded.write(to: dest)
        case .urlEncode:
            guard let text = String(data: inputData, encoding: .utf8), let enc = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { throw ConverterError.parseFailed("URL 编码失败") }
            try enc.write(to: dest, atomically: true, encoding: .utf8)
        case .urlDecode:
            guard let text = String(data: inputData, encoding: .utf8), let dec = text.removingPercentEncoding else { throw ConverterError.parseFailed("URL 解码失败") }
            try dec.write(to: dest, atomically: true, encoding: .utf8)
        }
        return dest
    }

    private static func convertPlist(data: Data, format: PropertyListSerialization.PropertyListFormat, to dest: URL) throws {
        guard let obj = try? PropertyListSerialization.propertyList(from: data, format: nil) else { throw ConverterError.parseFailed("不是合法的 plist") }
        guard let out = try? PropertyListSerialization.data(fromPropertyList: obj, format: format, options: 0) else { throw ConverterError.writeFailed("无法序列化 plist") }
        try out.write(to: dest)
    }
    private static func convertPlistToJSON(data: Data, to dest: URL) throws {
        guard let obj = try? PropertyListSerialization.propertyList(from: data, format: nil), JSONSerialization.isValidJSONObject(obj) else { throw ConverterError.parseFailed("结构无法转 JSON") }
        try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]).write(to: dest)
    }
    private static func convertJSONToPlist(data: Data, to dest: URL) throws {
        guard let obj = try? JSONSerialization.jsonObject(with: data) else { throw ConverterError.parseFailed("不是合法的 JSON") }
        guard let out = try? PropertyListSerialization.data(fromPropertyList: obj, format: .xml, options: 0) else { throw ConverterError.writeFailed("JSON 无法转 plist") }
        try out.write(to: dest)
    }
    private static func formatJSON(data: Data, pretty: Bool, to dest: URL) throws {
        guard let obj = try? JSONSerialization.jsonObject(with: data) else { throw ConverterError.parseFailed("不是合法的 JSON") }
        var options: JSONSerialization.WritingOptions = [.sortedKeys]; if pretty { options.insert(.prettyPrinted) }
        try JSONSerialization.data(withJSONObject: obj, options: options).write(to: dest)
    }
}
