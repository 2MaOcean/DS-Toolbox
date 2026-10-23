import Foundation
enum TuningDecision: Equatable { case none, rampUp, backoff, abort }

actor QuarkTuner {
    private var concurrency: Int
    private var segmentSize: Int64
    private let maxConcurrency: Int
    private let minConcurrency: Int
    private var healthyStreak = 0
    private var slowStreak = 0

    init(initial: Int = 4, maxCap: Int = 16, segmentSize: Int64 = 4_194_304) {
        self.concurrency = initial; self.minConcurrency = max(1, initial / 2); self.maxConcurrency = maxCap; self.segmentSize = segmentSize
    }
    func currentConcurrency() -> Int { concurrency }
    func currentSegmentSize() -> Int64 { segmentSize }

    func record(bytes: Int64, duration: TimeInterval, statusCode: Int) -> TuningDecision {
        guard duration > 0 else { return .none }
        let speed = Double(bytes) / duration
        if statusCode == 403 { return .abort }
        if statusCode == 429 || statusCode == 503 { slowStreak += 1; if slowStreak >= 2 { return .backoff }; return .none }
        if speed > 1_500_000 {
            healthyStreak += 1; slowStreak = 0
            if healthyStreak >= 5 && concurrency < maxConcurrency { concurrency = min(maxConcurrency, concurrency + 2); healthyStreak = 0; return .rampUp }
        } else if speed < 300_000 {
            slowStreak += 1; healthyStreak = 0
            if slowStreak >= 3 { concurrency = max(minConcurrency, concurrency / 2); slowStreak = 0; return .backoff }
        }
        return .none
    }
}
