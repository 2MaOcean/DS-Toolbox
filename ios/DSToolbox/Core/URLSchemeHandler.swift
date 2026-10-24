import Foundation

@MainActor
final class URLSchemeHandler {
    static let shared = URLSchemeHandler()
    private init() {}

    func handle(_ url: URL, env: ToolboxEnvironment) {
        guard url.scheme == "dstoolbox" else { return }
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = comps?.queryItems ?? []

        switch url.host {
        case "download":
            handleDownload(items, env: env)
        case "open":
            if let s = items.first(where: { $0.name == "url" })?.value,
               let u = URL(string: s) {
                BrowserSession.shared.newTab(url: u)
            }
        case "resolve":
            handleResolve(items, env: env)
        default:
            break
        }
    }

    private func handleDownload(_ items: [URLQueryItem], env: ToolboxEnvironment) {
        guard let target = items.first(where: { $0.name == "url" })?.value,
              let targetURL = URL(string: target),
              let adapter = env.registry.adapter(for: targetURL),
              let cred = CredentialStore.shared.load(kind: adapter.kind) else { return }
        let name = items.first(where: { $0.name == "name" })?.value
        let fileName = (name?.isEmpty == false ? name! : targetURL.lastPathComponent)
        _ = try? env.queue.enqueue(
            url: targetURL,
            fileName: fileName.isEmpty ? "download.bin" : fileName,
            credential: cred,
            kind: adapter.kind
        )
    }

    private func handleResolve(_ items: [URLQueryItem], env: ToolboxEnvironment) {
        guard let target = items.first(where: { $0.name == "url" })?.value,
              let targetURL = URL(string: target),
              let adapter = env.registry.adapter(for: targetURL),
              let cred = CredentialStore.shared.load(kind: adapter.kind) else { return }
        Task {
            if let link = try? await adapter.resolve(targetURL, credential: cred) {
                _ = try? env.queue.enqueue(link: link, kind: adapter.kind)
            }
        }
    }
}
