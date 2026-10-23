import SwiftUI
struct SystemMonitorView: View {
    @StateObject private var monitor = SystemMonitorService.shared
    var body: some View {
        ScrollView {
            if let s = monitor.snapshot {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    card("CPU", String(format: "%.1f%%", s.cpuUsage), "cpu")
                    card("内存", byteString(s.memoryUsed) + " / " + byteString(s.memoryTotal), "memorychip")
                    card("电池", s.batteryLevel >= 0 ? "\(Int(s.batteryLevel * 100))%" : "—", "battery.100")
                }.padding()
            } else { ProgressView("正在读取…").padding() }
        }.navigationTitle("系统监控").onAppear { monitor.start() }.onDisappear { monitor.stop() }
    }
    private func card(_ title: String, _ val: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) { Image(systemName: icon).foregroundStyle(.tint); Text(title).font(.caption).foregroundStyle(.secondary); Text(val).font(.headline) }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
