import Foundation

struct CloudDriveAPIHelper {
    let cookieHeader: String
    let userAgent: String
    let referer: String

    func get(_ url: URL, extra: [String: String] = [:]) async throws -> Data {
        var r = URLRequest(url: url)
        r.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        r.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        r.setValue(referer, forHTTPHeaderField: "Referer")
        r.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        for (k, v) in extra { r.setValue(v, forHTTPHeaderField: k) }
        let (d, resp) = try await URLSession.shared.data(for: r)
        try Self.check(resp)
        return d
    }

    func post(_ url: URL, body: [String: String], extra: [String: String] = [:]) async throws -> Data {
        var r = URLRequest(url: url)
        r.httpMethod = "POST"
        r.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        r.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        r.setValue(referer, forHTTPHeaderField: "Referer")
        r.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        for (k, v) in extra { r.setValue(v, forHTTPHeaderField: k) }
        r.httpBody = body.map { "\($0.key)=\(Self.escape($0.value))" }.joined(separator: "&").data(using: .utf8)
        let (d, resp) = try await URLSession.shared.data(for: r)
        try Self.check(resp)
        return d
    }

    func json(_ data: Data) throws -> [String: Any] {
        guard let j = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ResolveError.unsupported
        }
        return j
    }

    static func check(_ resp: URLResponse) throws {
        guard let h = resp as? HTTPURLResponse else { throw ResolveError.unsupported }
        if h.statusCode == 401 || h.statusCode == 403 { throw ResolveError.credentialExpired }
        if h.statusCode == 429 { throw ResolveError.riskControl }
        guard (200..<300).contains(h.statusCode) else { throw ResolveError.unsupported }
    }

    static func escape(_ s: String) -> String {
        var out = ""
        for c in s.utf8 {
            let ch = Character(UnicodeScalar(c))
            if ch.isLetter || ch.isNumber || "-._~".contains(ch) { out.append(ch) }
            else { out += String(format: "%%%02X", c) }
        }
        return out
    }
}
