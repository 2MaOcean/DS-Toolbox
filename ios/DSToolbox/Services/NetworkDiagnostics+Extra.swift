import Foundation

extension NetworkDiagnostics {
    struct LatencyResult {
        let host: String
        let avgMs: Double
        let minMs: Double
        let maxMs: Double
        let samples: [Double]
    }

    func httpLatency(host: String, times: Int = 5) async -> LatencyResult {
        var samples: [Double] = []
        let urlString = host.hasPrefix("http") ? host : "https://\(host)"
        guard let url = URL(string: urlString) else {
            return LatencyResult(host: host, avgMs: 0, minMs: 0, maxMs: 0, samples: [])
        }
        for _ in 0..<times {
            let start = Date()
            var req = URLRequest(url: url)
            req.httpMethod = "HEAD"
            req.timeoutInterval = 5
            _ = try? await URLSession.shared.data(for: req)
            samples.append(Date().timeIntervalSince(start) * 1000)
        }
        let avg = samples.reduce(0, +) / Double(samples.count)
        return LatencyResult(
            host: host,
            avgMs: avg,
            minMs: samples.min() ?? 0,
            maxMs: samples.max() ?? 0,
            samples: samples
        )
    }
}
