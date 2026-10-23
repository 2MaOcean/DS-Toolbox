import SwiftUI
import WebKit

struct BrowserView: View {
    @ObservedObject var session = BrowserSession.shared
    @State private var addressInput = ""
    @State private var showTabs = false
    @State private var showBookmarks = false
    @State private var showHistory = false
    @State private var showFindBar = false
    @State private var findText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let tab = session.activeTab {
                    WebViewContainer(webView: tab.webView)
                    if tab.isLoading { ProgressView(value: tab.progress).progressViewStyle(.linear) }
                }
                toolbar
            }
            .navigationTitle(session.activeTab?.title ?? "浏览器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button { showTabs = true } label: { Image(systemName: "square.on.square") }
                        Menu {
                            Button("书签") { showBookmarks = true }
                            Button("历史") { showHistory = true }
                            Button("桌面模式") {
                                session.activeTab?.isDesktopMode.toggle()
                                applyDesktopMode()
                            }
                        } label: { Image(systemName: "ellipsis.circle") }
                    }
                }
            }
            .sheet(isPresented: $showTabs) { TabsSheet(session: session) }
            .sheet(isPresented: $showBookmarks) { BookmarksSheet() }
            .sheet(isPresented: $showHistory) { HistorySheet() }
            .sheet(item: $session.pendingDownload) { item in PendingDownloadSheet(item: item) }
            .onAppear { addressInput = session.activeTab?.urlString ?? "" }
            .onChange(of: session.activeTabID) { _, _ in addressInput = session.activeTab?.urlString ?? "" }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button { session.activeTab?.webView.goBack() } label: { Image(systemName: "chevron.left") }
                .disabled(!(session.activeTab?.canGoBack ?? false))
            Button { session.activeTab?.webView.goForward() } label: { Image(systemName: "chevron.right") }
                .disabled(!(session.activeTab?.canGoForward ?? false))
            TextField("搜索或输入网址", text: $addressInput)
                .textFieldStyle(.roundedBorder).keyboardType(.URL).autocorrectionDisabled().textInputAutocapitalization(.never)
                .onSubmit { session.load(addressInput) }
            Button {
                if session.activeTab?.isLoading == true { session.activeTab?.webView.stopLoading() }
                else { session.activeTab?.webView.reload() }
            } label: { Image(systemName: session.activeTab?.isLoading == true ? "xmark" : "arrow.clockwise") }
        }.padding(.horizontal).padding(.bottom, 6)
    }

    private func applyDesktopMode() {
        guard let tab = session.activeTab else { return }
        let mobile = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15"
        let desktop = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"
        tab.webView.customUserAgent = tab.isDesktopMode ? desktop : mobile
        tab.webView.reload()
    }
}

struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
