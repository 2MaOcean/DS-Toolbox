import Foundation

struct SegmentResult {
    let index: Int
    let bytes: Int64
    let duration: TimeInterval
    let statusCode: Int
}

final class AdaptiveDownloader: @unchecked Sendable {
    let session: URLSession
    let fingerprint: DownloadFingerprint
    let tuner: QuarkTuner?

    init(fingerprint: DownloadFingerprint, tuner: QuarkTuner? = nil, session: URLSession = .shared) {
        self.fingerprint = fingerprint; self.tuner = tuner; self.session = session
    }

    func download(url: URL, to destination: URL, cookieHeader: String, taskDirectory: URL, options: DownloadOptions = .default, progress: @escaping (Int64, Int64) -> Void) async throws {
        let fm = FileManager.default
        try fm.createDirectory(at: taskDirectory, withIntermediateDirectories: true)
        let segDir = taskDirectory.appendingPathComponent("segments", isDirectory: true)
        try fm.createDirectory(at: segDir, withIntermediateDirectories: true)
        let manifestURL = taskDirectory.appendingPathComponent("manifest.json")
        let builder = RequestBuilder(fingerprint: fingerprint, cookieHeader: cookieHeader, options: options)

        let info = try await probe(url: url, builder: builder)
        guard info.size > 0 else { throw DownloaderError.emptyFile }

        let initialSeg = await tuner?.currentSegmentSize() ?? options.segmentSizeBytes
        let manifest = loadOrCreateManifest(url: url, size: info.size, segSize: initialSeg, manifestURL: manifestURL)
        let store = ManifestStore(url: manifestURL, manifest: manifest)
        let bucket = options.speedLimitBytes.map { TokenBucket(ratePerSecond: $0) }

        var completed: Int64 = 0
        for idx in manifest.completedSet { let s = manifest.segments[idx]; completed += s.end - s.start + 1 }
        progress(completed, info.size)

        let pending = manifest.segments.filter { !manifest.completedSet.contains($0.index) }
        var cursor = 0

        while cursor < pending.count {
            try Task.checkCancellation()
            let conc = await tuner?.currentConcurrency() ?? options.concurrency
            let end = min(cursor + conc, pending.count)
            let batch = Array(pending[cursor..<end])

            let results = try await withThrowingTaskGroup(of: SegmentResult.self) { group -> [SegmentResult] in
                for seg in batch {
                    let dest = segDir.appendingPathComponent("\(seg.index).part")
                    group.addTask { try await self.fetchWithRetry(seg: seg, builder: builder, dest: dest, url: url, bucket: bucket, maxRetries: options.maxRetries) }
                }
                var out: [SegmentResult] = []; for try await r in group { out.append(r) }; return out
            }

            for r in results {
                completed += r.bytes; await store.markCompleted(index: r.index)
                if let decision = await tuner?.record(bytes: r.bytes, duration: r.duration, statusCode: r.statusCode) {
                    if decision == .abort { throw DownloaderError.forbidden }
                    if decision == .backoff { await RequestBuilder.cooldown(seconds: 30) }
                }
            }
            progress(completed, info.size); cursor = end
            if cursor < pending.count { await RequestBuilder.jitter() }
        }

        try Task.checkCancellation()
        let final = await store.snapshot()
        try Self.merge(segments: final.segments, segDir: segDir, destination: destination)
        try? fm.removeItem(at: taskDirectory); progress(info.size, info.size)
    }

    private func loadOrCreateManifest(url: URL, size: Int64, segSize: Int64, manifestURL: URL) -> DownloadManifest {
        if let d = try? Data(contentsOf: manifestURL), let m = try? JSONDecoder().decode(DownloadManifest.self, from: d), m.urlString == url.absoluteString, m.totalSize == size { return m }
        let segs = Self.makeSegments(size: size, segmentSize: segSize)
        let m = DownloadManifest(urlString: url.absoluteString, totalSize: size, segmentSize: segSize, segments: segs, completedIndexes: [], updatedAt: Date())
        try? JSONEncoder().encode(m).write(to: manifestURL, options: .atomic); return m
    }
}
