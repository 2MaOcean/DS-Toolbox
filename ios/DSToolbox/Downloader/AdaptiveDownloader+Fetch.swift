import Foundation

struct RemoteFileInfo { let size: Int64; let supportsRanges: Bool }

actor ManifestStore {
    private var manifest: DownloadManifest
    private let url: URL
    init(url: URL, manifest: DownloadManifest) { self.url = url; self.manifest = manifest }
    func markCompleted(index: Int) {
        if !manifest.completedIndexes.contains(index) {
            manifest.completedIndexes.append(index); manifest.updatedAt = Date()
            if let d = try? JSONEncoder().encode(manifest) { try? d.write(to: url, options: .atomic) }
        }
    }
    func snapshot() -> DownloadManifest { manifest }
}

extension AdaptiveDownloader {
    func probe(url: URL, builder: RequestBuilder) async throws -> RemoteFileInfo {
        var req = builder.make(url); req.httpMethod = "HEAD"; req.timeoutInterval = 30
        if let (_, r) = try? await session.data(for: req), let http = r as? HTTPURLResponse, http.statusCode == 200, let len = http.value(forHTTPHeaderField: "Content-Length"), let size = Int64(len) {
            if (http.value(forHTTPHeaderField: "Accept-Ranges") ?? "").lowercased().contains("bytes") { return RemoteFileInfo(size: size, supportsRanges: true) }
        }
        var r = builder.make(url, range: 0...0); r.timeoutInterval = 30
        let (_, resp) = try await session.data(for: r)
        guard let http = resp as? HTTPURLResponse else { throw DownloaderError.invalidResponse }
        if http.statusCode == 403 { throw DownloaderError.forbidden }
        if http.statusCode == 429 || http.statusCode == 503 { throw DownloaderError.rateLimited(RetryPolicy.retryAfter(from: http)) }
        guard http.statusCode == 206 else { throw DownloaderError.noRangeSupport }
        guard let cr = http.value(forHTTPHeaderField: "Content-Range"), let total = cr.split(separator: "/").last, let size = Int64(total) else { throw DownloaderError.invalidResponse }
        return RemoteFileInfo(size: size, supportsRanges: true)
    }

    func fetchWithRetry(seg: Segment, builder: RequestBuilder, dest: URL, url: URL, bucket: TokenBucket?, maxRetries: Int) async throws -> SegmentResult {
        let policy = RetryPolicy(maxRetries: maxRetries); var attempt = 0; var strikes = 0
        while true {
            let start = Date()
            do {
                let (bytes, code) = try await fetchSegment(seg: seg, builder: builder, dest: dest, url: url, bucket: bucket)
                return SegmentResult(index: seg.index, bytes: bytes, duration: Date().timeIntervalSince(start), statusCode: code)
            } catch let e as DownloaderError {
                if case .forbidden = e { throw e }
                if case .rateLimited(let ra) = e {
                    strikes += 1; if strikes >= policy.rateLimitStrikesBeforeRelogin { throw DownloaderError.needsRelogin }
                    try? await Task.sleep(nanoseconds: UInt64(policy.delay(for: attempt, retryAfter: ra) * 1_000_000_000)); attempt += 1; continue
                }
                if case .badStatus(let c) = e, c != 500 { throw e }
                guard attempt < policy.maxRetries else { throw e }
                try? await Task.sleep(nanoseconds: UInt64(policy.delay(for: attempt, retryAfter: nil) * 1_000_000_000)); attempt += 1
            }
        }
    }

    func fetchSegment(seg: Segment, builder: RequestBuilder, dest: URL, url: URL, bucket: TokenBucket?) async throws -> (Int64, Int) {
        let req = builder.make(url, range: seg.start...seg.end)
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw DownloaderError.invalidResponse }
        if http.statusCode == 403 { throw DownloaderError.forbidden }
        if http.statusCode == 429 || http.statusCode == 503 { throw DownloaderError.rateLimited(RetryPolicy.retryAfter(from: http)) }
        guard http.statusCode == 206 else { throw DownloaderError.badStatus(http.statusCode) }
        guard Int64(data.count) == seg.end - seg.start + 1 else { throw DownloaderError.segmentSizeMismatch }
        if let bucket { await bucket.consume(Double(data.count)) }
        try data.write(to: dest, options: .atomic); return (Int64(data.count), http.statusCode)
    }

    static func makeSegments(size: Int64, segmentSize: Int64) -> [Segment] {
        var out: [Segment] = []; var start: Int64 = 0; var i = 0
        while start < size { let end = min(start + segmentSize - 1, size - 1); out.append(Segment(index: i, start: start, end: end)); start = end + 1; i += 1 }
        return out
    }

    static func merge(segments: [Segment], segDir: URL, destination: URL) throws {
        let fm = FileManager.default; if fm.fileExists(atPath: destination.path) { try fm.removeItem(at: destination) }
        guard fm.createFile(atPath: destination.path, contents: nil) else { throw DownloaderError.cannotCreateFile }
        let out = try FileHandle(forWritingTo: destination); defer { try? out.close() }
        for seg in segments.sorted(by: { $0.index < $1.index }) {
            let input = try FileHandle(forReadingFrom: segDir.appendingPathComponent("\(seg.index).part")); defer { try? input.close() }
            while true { let chunk = try input.read(upToCount: 1_048_576) ?? Data(); if chunk.isEmpty { break }; try out.write(contentsOf: chunk) }
        }
    }
}
