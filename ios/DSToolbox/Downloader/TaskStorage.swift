import Foundation
enum TaskStorage {
    static func tasksFile() throws -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("DSToolbox")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("tasks.json")
    }
    static func load() -> [DownloadTask] {
        guard let f = try? tasksFile(), let d = try? Data(contentsOf: f) else { return [] }
        return (try? JSONDecoder().decode([DownloadTask].self, from: d)) ?? []
    }
    static func save(_ tasks: [DownloadTask]) {
        guard let f = try? tasksFile(), let d = try? JSONEncoder().encode(tasks) else { return }
        try? d.write(to: f, options: .atomic)
    }
}
