import SwiftUI
struct IPAManagerView: View {
    @State private var ipas: [ImportedIPA] = []; @State private var showPicker = false; @State private var actionIPA: ImportedIPA?
    var body: some View {
        List {
            Button("导入 IPA") { showPicker = true }
            ForEach(ipas) { ipa in
                VStack(alignment: .leading) { Text(ipa.appName ?? ipa.fileName).font(.headline); Text(byteString(ipa.fileSize)).font(.caption).foregroundStyle(.secondary) }
                    .onTapGesture { actionIPA = ipa }
            }
        }.navigationTitle("IPA 管理").fileImporter(isPresented: $showPicker, allowedContentTypes: [.data]) { r in
            if case .success(let u) = r, u.pathExtension.lowercased() == "ipa" {
                let d = FileManager.default.temporaryDirectory.appendingPathComponent(u.lastPathComponent); try? FileManager.default.copyItem(at: u, to: d)
                var ipa = ImportedIPA(fileURL: d, fileName: u.lastPathComponent, fileSize: Int64((try? d.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0))
                if let m = IPAMetadataReader.read(from: d) { ipa.bundleID = m.bundleID; ipa.appName = m.name; ipa.version = m.version; ipa.isEncrypted = m.isEncrypted }
                ipas.append(ipa)
            }
        }.sheet(item: $actionIPA) { ipa in IPAActionSheet(ipa: ipa) { print($0) } }
    }
}
