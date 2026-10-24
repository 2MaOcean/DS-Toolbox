import SwiftUI
import WebKit

struct BrowserView: View {
    @ObservedObject var session = BrowserSession.shared
    @State private var input = ""
    @State private var showBookmarks = false
    @State private var showHistory = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let tab = session.activeTab { WebViewContainer(webView: tab.webView) }
                HStack {
                    TextField("搜索或输入网址", text: $input)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .onSubmit(go)
                    Button("转到", action: go).buttonStyle(.borderedProminent)
                }.padding(.horizontal)
                HStack(spacing: 24) {
                    Button { session.activeTab?.webView.goBack() } label: { Image(systemName: "chevron.left") }
                        .disabled(!(session.activeTab?.webView.canGoBack ?? false))
                    Button { session.activeTab?.webView.goForward() } label: { Image(systemName: "chevron.right") }
                        .disabled(!(session.activeTab?.webView.canGoForward ?? false))
                    Button { showBookmarks = true } label: { Image(systemName: "bookmark") }
                    Button { showHistory = true } label: { Image(systemName: "clock") }
                    Button { toggleBookmark() } label: { Image(systemName: bookmarkIcon) }
                    Spacer()
                    Button { session.newTab() } label: { Image(systemName: "plus.square") }
                }.padding()
            }
            .navigationTitle(session.activeTab?.title ?? "浏览器")
            .sheet(isPresented: $showBookmarks) { BookmarksSheet { load($0) } }
            .sheet(isPresented: $showHistory) { HistorySheet { load($0) } }
            .sheet(item: $session.pendingDownload) { item in
                PendingDownloadSheet(item: item)
            }
        }
    }

    private var bookmarkIcon: String {
        guard let url = session.activeTab?.webView.url?.absoluteString else { return "bookmark" }
        return BookmarkStore.shared.contains(url: url) ? "bookmark.fill" : "bookmark"
    }

    private func go() {
        let s = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return }
        let urlString = s.hasPrefix("http") ? s : "https://\(s)"
        load(urlString)
    }
    private func load(_ s: String) {
        guard let u = URL(string: s) else { return }
        session.activeTab?.webView.load(URLRequest(url: u))
        input = s
    }
    private func toggleBookmark() {
        guard let url = session.activeTab?.webView.url?.absoluteString else { return }
        let title = session.activeTab?.title ?? url
        session.toggleBookmark(title: title, url: url)
    }
}

struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
