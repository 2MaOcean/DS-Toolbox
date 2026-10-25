import Foundation
import Combine

@MainActor
final class ProcessManager: ObservableObject {
    static let shared = ProcessManager()
    @Published private(set) var processes: [ProcessInfoEntry] = []
    private init() {}

    var isAvailable: Bool { CapabilityGate.shared.canManageProcesses }

    func refresh() {
        guard isAvailable else { processes = []; return }
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size = 0
        guard sysctl(&mib, 4, nil, &size, nil, 0) == 0 else { return }
        let count = size / MemoryLayout<kinfo_proc>.stride
        var procs = [kinfo_proc](repeating: kinfo_proc(), count: count)
        guard sysctl(&mib, 4, &procs, &size, nil, 0) == 0 else { return }
        processes = procs.compactMap { p in
            let name = withUnsafeBytes(of: p.kp_proc.p_comm) {
                String(cString: $0.bindMemory(to: CChar.self).baseAddress!)
            }
            guard !name.isEmpty else { return nil }
            return ProcessInfoEntry(pid: p.kp_proc.p_pid, name: name)
        }.sorted { $0.name < $1.name }
    }

    func kill(pid: pid_t) -> Bool {
        kill(pid, SIGKILL) == 0
    }
}

struct ProcessInfoEntry: Identifiable, Hashable {
    var id: pid_t { pid }
    let pid: pid_t
    let name: String
}
