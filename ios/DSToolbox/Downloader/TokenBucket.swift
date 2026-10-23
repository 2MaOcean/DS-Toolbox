import Foundation
actor TokenBucket {
    private var tokens: Double
    private let rate: Double
    private var last: Date
    init(ratePerSecond: Double) { self.rate = ratePerSecond; self.tokens = ratePerSecond; self.last = Date() }
    func consume(_ n: Double) async {
        while true { refill(); if tokens >= n { tokens -= n; return }; try? await Task.sleep(nanoseconds: 100_000_000) }
    }
    private func refill() { let now = Date(); tokens = min(rate, tokens + now.timeIntervalSince(last) * rate); last = now }
}
