import Foundation

final class NetworkDiagnostics {
    static let shared = NetworkDiagnostics()
    private init() {}
    
    func dnsQuery(domain: String, type: String = "A") async throws -> [String] {
        guard let url = URL(string: "https://cloudflare-dns.com/dns-query?name=\(domain)&type=\(type)") else { return [] }
        var req = URLRequest(url: url)
        req.setValue("application/dns-json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 10
        let (data, _) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let answers = json?["Answer"] as? [[String: Any]] ?? []
        return answers.compactMap { $0["data"] as? String }
    }
    
    func currentIP() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }
        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            guard interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) else { continue }
            let name = String(cString: interface.ifa_name)
            if name == "en0" {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                address = String(cString: hostname)
            }
        }
        return address
    }
}
