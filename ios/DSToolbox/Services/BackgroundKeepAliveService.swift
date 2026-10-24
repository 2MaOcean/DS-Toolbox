import Foundation
import UIKit
import Combine
import AVFoundation
import CoreLocation

enum KeepAliveMode: String, CaseIterable, Identifiable {
    case none, audio, location
    var id: String { rawValue }
    var label: String { self == .none ? "关闭" : (self == .audio ? "静音音频" : "后台定位") }
}

struct KeepAliveLogEntry: Identifiable {
    let id = UUID(); let time: Date; let event: String
}

@MainActor
final class BackgroundKeepAliveService: NSObject, ObservableObject {
    static let shared = BackgroundKeepAliveService()
    @Published private(set) var activeMode: KeepAliveMode = .none
    @Published private(set) var isRunning = false
    @Published private(set) var logs: [KeepAliveLogEntry] = []
    @Published var autoResumeOnLaunch: Bool = UserDefaults.standard.bool(forKey: "ds.keepalive.autoResume") { didSet { UserDefaults.standard.set(autoResumeOnLaunch, forKey: "ds.keepalive.autoResume") } }
    @Published var autoStopMinutes: Int = UserDefaults.standard.integer(forKey: "ds.keepalive.autoStop") { didSet { UserDefaults.standard.set(autoStopMinutes, forKey: "ds.keepalive.autoStop") } }

    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var locationManager: CLLocationManager?
    private var autoStopTimer: Timer?

    private override init() {
        super.init()
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    func startAudioKeepAlive() throws {
        stop(); let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers]); try session.setActive(true)
        let engine = AVAudioEngine(); let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let node = AVAudioSourceNode { _, _, _, abl -> OSStatus in
            let ptr = UnsafeMutableAudioBufferListPointer(abl); for b in ptr { memset(b.mData, 0, Int(b.mDataByteSize)) }; return noErr
        }
        engine.attach(node); engine.connect(node, to: engine.mainMixerNode, format: format); try engine.start()
        self.audioEngine = engine; self.sourceNode = node; markStarted(.audio)
    }

    func startLocationKeepAlive() {
        stop(); let manager = CLLocationManager(); manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers; manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = true; manager.requestAlwaysAuthorization(); manager.startUpdatingLocation()
        self.locationManager = manager; markStarted(.location)
    }

    func stop() {
        audioEngine?.stop(); sourceNode.map { audioEngine?.detach($0) }; audioEngine = nil; sourceNode = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        locationManager?.stopUpdatingLocation(); locationManager = nil
        autoStopTimer?.invalidate(); autoStopTimer = nil
        activeMode = .none; isRunning = false; appendLog("已停止")
    }

    private func markStarted(_ mode: KeepAliveMode) {
        activeMode = mode; isRunning = true; appendLog("已启动：\(mode.label)")
        if autoStopMinutes > 0 { autoStopTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(autoStopMinutes * 60), repeats: false) { [weak self] _ in Task { @MainActor in self?.stop() } } }
    }
    private func appendLog(_ msg: String) { logs.insert(KeepAliveLogEntry(time: Date(), event: msg), at: 0); if logs.count > 50 { logs = Array(logs.prefix(50)) } }
    func resumeIfNeeded() { guard autoResumeOnLaunch else { return }; if UserDefaults.standard.string(forKey: "ds.keepalive.lastMode") == "audio" { try? startAudioKeepAlive() } else if UserDefaults.standard.string(forKey: "ds.keepalive.lastMode") == "location" { startLocationKeepAlive() } }
    func persistCurrentMode() { UserDefaults.standard.set(activeMode.rawValue, forKey: "ds.keepalive.lastMode") }
}
extension BackgroundKeepAliveService: CLLocationManagerDelegate { nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {} }
