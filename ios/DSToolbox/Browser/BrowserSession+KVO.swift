import Foundation
import WebKit
import Combine

extension BrowserSession {
    func observe(_ tab: BrowserTab) {
        tab.observations = [
            tab.webView.observe(\.title, options: [.new]) { [weak tab] wv, _ in
                Task { @MainActor in tab?.title = wv.title ?? "新标签页" }
            },
            tab.webView.observe(\.url, options: [.new]) { [weak tab] wv, _ in
                Task { @MainActor in
                    tab?.urlString = wv.url?.absoluteString ?? ""
                    if let t = wv.title, let u = wv.url?.absoluteString {
                        self.recordVisit(title: t, url: u)
                    }
                }
            },
            tab.webView.observe(\.isLoading, options: [.new]) { [weak tab] wv, _ in
                Task { @MainActor in tab?.isLoading = wv.isLoading }
            }
        ]
    }
}
