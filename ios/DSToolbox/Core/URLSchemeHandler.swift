import Foundation

@MainActor
final class URLSchemeHandler {
    static let shared = URLSchemeHandler()
    private init() {}

    func handle(_ url: URL, env: ToolboxEnvironment) {
        guard url.scheme == "dstoolbox", url.host == "download" else { return }
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let target = comps?.queryItems?.first(where: { $0.name == "url" })?.value,
              let targetURL = URL(string: target),
              let adapter = env.registry.adapter(for: targetURL) else { return }
        guard let cred = CredentialStore.shared.load(kind: adapter.kind) else { return }
        let name = comps?.queryItems?.first(where: { $0.name == "name" })?.value
        let fileName = (name?.isEmpty == false ? name! : targetURL.lastPathComponent)
        _ = try? env.queue.enqueue(url: targetURL, fileName: fileName.isEmpty ? "download.bin" : fileName, credential: cred, kind: adapter.kind)
    }
}
