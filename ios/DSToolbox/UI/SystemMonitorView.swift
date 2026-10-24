import SwiftUI

struct SystemMonitorView: View {
    @ObservedObject private var svc = SystemMonitorService.shared

    var body: some View {
        Form {
            if let s = svc.snapshot {
                Section("CPU") {
                    ProgressView(value: s.cpuUsage, total: 1.0)
                    Text(String(format: "%.1f%%", s.cpuUsage * 100))
                }
                Section("内存") {
                    ProgressView(value: Double(s.memoryUsed), total: Double(s.memoryTotal))
                    Text("\(byteString(s.memoryUsed)) / \(byteString(s.memoryTotal))")
                }
                Section("电池") {
                    Text(s.batteryLevel < 0 ? "未知" : String(format: "%.0f%%", s.batteryLevel * 100))
                }
                Section("运行时间") {
                    Text(formatted(s.uptime))
                }
            } else {
                ProgressView("加载中...")
            }
        }
        .navigationTitle("系统监控")
        .onAppear { svc.start() }
        .onDisappear { svc.stop() }
    }
    private func formatted(_ t: TimeInterval) -> String {
        let d = Int(t) / 86400, h = (Int(t) % 86400) / 3600, m = (Int(t) % 3600) / 60
        return "\(d)天 \(h)时 \(m)分"
    }
}
