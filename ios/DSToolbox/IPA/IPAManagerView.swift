import SwiftUI

struct IPAManagerView: View {
    @State private var ipas: [ImportedIPA] = []
    @State private var showPicker = false
    @State private var selected: ImportedIPA?

    var body: some View {
        NavigationStack {
            List(ipas) { ipa in
                Button {
                    selected = ipa
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ipa.displayName ?? ipa.fileName).font(.headline)
                        if let bid = ipa.bundleID { Text(bid).font(.caption).foregroundStyle(.secondary) }
                        Text("v\(ipa.version ?? "?") · \(byteString(ipa.size))").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("IPA 管理")
            .toolbar {
                ToolbarItem(placement: .primaryAction) { Button("导入") { showPicker = true } }
            }
            .sheet(isPresented: $showPicker) { ipaPicker }
            .sheet(item: $selected) { ipa in IPAActionSheet(ipa: ipa) { refresh() } }
        }
    }

    private var ipaPicker: some View {
        IPAPicker { url in
            if let meta = IPAMetadataReader.read(from: url) {
                let ipa = ImportedIPA(id: UUID(), fileURL: url, fileName: url.lastPathComponent,
                                      size: (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init) ?? 0,
                                      bundleID: meta.bundleID, displayName: meta.name, version: meta.version, isEncrypted: meta.isEncrypted)
                ipas.append(ipa)
            }
            showPicker = false
        }
    }
    private func refresh() { selected = nil }
}

struct IPAPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let p = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        p.allowsMultipleSelection = false
        p.delegate = context.coordinator
        return p
    }
    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}
    func makeCoordinator() -> Coord { Coord(onPick: onPick) }
    final class Coord: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }
        func documentPicker(_ c: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { if let u = urls.first { onPick(u) } }
    }
}
