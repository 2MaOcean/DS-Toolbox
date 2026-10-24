import SwiftUI

struct InjectionInspectorView: View {
    @State private var images: [String] = []
    @State private var query = ""

    private var filtered: [String] {
        query.isEmpty ? images : images.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        List(filtered, id: \.self) { img in
            Text(img).font(.system(.caption, design: .monospaced)).lineLimit(1)
        }
        .searchable(text: $query)
        .navigationTitle("插件检查")
        .overlay {
            if images.isEmpty {
                ContentUnavailableView("暂无框架", systemImage: "shippingbox")
            }
        }
        .onAppear { images = InjectionInspector.currentImages() }
    }
}
