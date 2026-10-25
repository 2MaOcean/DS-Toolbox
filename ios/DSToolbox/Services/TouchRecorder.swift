import Foundation
import UIKit
import Combine

struct TouchEvent: Codable, Identifiable {
    var id = UUID()
    let timestamp: Double
    let x: Double
    let y: Double
}

@MainActor
final class TouchRecorder: ObservableObject {
    static let shared = TouchRecorder()
    @Published private(set) var isRecording = false
    @Published private(set) var events: [TouchEvent] = []
    private var startAt: Date?
    private init() {}

    func start() { isRecording = true; events.removeAll(); startAt = Date() }
    func stop() { isRecording = false }
    func clear() { events.removeAll() }

    func record(x: Double, y: Double) {
        guard isRecording, let start = startAt else { return }
        events.append(TouchEvent(timestamp: Date().timeIntervalSince(start), x: x, y: y))
    }

    func exportJSON() -> Data? {
        try? JSONEncoder().encode(events)
    }
}
