import Foundation
import Combine
import UIKit
import Darwin

struct SystemSnapshot {
    var cpuUsage: Double
    var memoryUsed: Int64
    var memoryTotal: Int64
    var batteryLevel: Float
    var batteryState: UIDevice.BatteryState
    var uptime: TimeInterval
}

final class SystemMonitorService: ObservableObject {
    static let shared = SystemMonitorService()
    @Published private(set) var snapshot: SystemSnapshot?
    private var timer: Timer?
    private var lastCPU: (user: UInt32, system: UInt32, idle: UInt32, nice: UInt32)?

    func start(interval: TimeInterval = 2) {
        stop()
        UIDevice.current.isBatteryMonitoringEnabled = true
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        refresh()
    }
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        let mem = readMemory()
        let cpu = readCPU()
        snapshot = SystemSnapshot(
            cpuUsage: cpu,
            memoryUsed: mem.used,
            memoryTotal: mem.total,
            batteryLevel: UIDevice.current.batteryLevel,
            batteryState: UIDevice.current.batteryState,
            uptime: ProcessInfo.processInfo.systemUptime
        )
    }

    private func readMemory() -> (used: Int64, total: Int64) {
        let total = Int64(ProcessInfo.processInfo.physicalMemory)
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let r = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard r == KERN_SUCCESS else { return (0, total) }
        let ps = Int64(vm_kernel_page_size)
        return (Int64(stats.active_count) * ps + Int64(stats.wire_count) * ps, total)
    }

    private func readCPU() -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        let r = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard r == KERN_SUCCESS else { return 0 }
        let user = info.cpu_ticks.0
        let system = info.cpu_ticks.1
        let idle = info.cpu_ticks.2
        let nice = info.cpu_ticks.3

        var usage = 0.0
        if let last = lastCPU {
            let du = Double(user - last.user)
            let ds = Double(system - last.system)
            let di = Double(idle - last.idle)
            let dn = Double(nice - last.nice)
            let total = du + ds + di + dn
            if total > 0 { usage = (du + ds + dn) / total }
        }
        lastCPU = (user, system, idle, nice)
        return usage
    }
}
