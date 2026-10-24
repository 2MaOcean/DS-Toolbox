import Foundation
import Combine
import UIKit
import Darwin

struct SystemSnapshot {
    var cpuUsage: Double
    var memoryUsed: Int64
    var memoryTotal: Int64
    var batteryLevel: Float
}

final class SystemMonitorService: ObservableObject {
    static let shared = SystemMonitorService()
    @Published private(set) var snapshot: SystemSnapshot?
    private var timer: Timer?

    func start(interval: TimeInterval = 2) {
        stop()
        UIDevice.current.isBatteryMonitoringEnabled = true
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in self?.refresh() }
        refresh()
    }

    func stop() { timer?.invalidate(); timer = nil }

    private func refresh() {
        let mem = readMemory()
        snapshot = SystemSnapshot(cpuUsage: 0, memoryUsed: mem.used, memoryTotal: mem.total, batteryLevel: UIDevice.current.batteryLevel)
    }
    private func readMemory() -> (used: Int64, total: Int64) {
        let total = ProcessInfo.processInfo.physicalMemory
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) { $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count) } }
        guard result == KERN_SUCCESS else { return (0, total) }
        let pageSize = Int64(vm_kernel_page_size)
        return (Int64(stats.active_count) * pageSize + Int64(stats.wire_count) * pageSize, total)
    }
}
