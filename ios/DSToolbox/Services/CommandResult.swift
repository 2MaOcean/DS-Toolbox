import Foundation

struct CommandResult {
    let output: String
    let isError: Bool
    let newCwd: URL?
    let shouldClear: Bool
    let shouldExit: Bool

    static let empty = CommandResult(output: "", isError: false, newCwd: nil, shouldClear: false, shouldExit: false)
    static func ok(_ s: String) -> CommandResult { .init(output: s, isError: false, newCwd: nil, shouldClear: false, shouldExit: false) }
    static func err(_ s: String) -> CommandResult { .init(output: s, isError: true, newCwd: nil, shouldClear: false, shouldExit: false) }
    static func cd(_ url: URL) -> CommandResult { .init(output: "", isError: false, newCwd: url, shouldClear: false, shouldExit: false) }
}
