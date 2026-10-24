import Foundation
import CryptoKit

enum FileHasher {
    static func sha256(url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        let chunkSize = 262_144
        while true {
            let chunk = try handle.read(upToCount: chunkSize) ?? Data()
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
    
    static func sha256Async(url: URL) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            try sha256(url: url)
        }.value
    }
}
