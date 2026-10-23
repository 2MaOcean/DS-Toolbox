import SwiftUI
struct TorrentView: View {
    @StateObject private var torrent = TorrentDownloader()
    @State private var input = ""
    @State private var showFilePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Text("BT 为实验性功能，依赖 WebRTC 与公开 tracker，建议 < 100 MB。").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    TextField("magnet:?xt=... 或 .torrent 文件", text: $input, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(2...4).autocorrectionDisabled().textInputAutocapitalization(.never)
                    HStack {
                        Button("开始") { guard !input.isEmpty else { return }; torrent.start(magnet: input) }.buttonStyle(.borderedProminent)
                        Button("从文件选择") { showFilePicker = true }.buttonStyle(.bordered)
                        Button("停止") { torrent.stop() }.buttonStyle(.bordered).disabled(!torrent.isRunning)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(torrent.name.isEmpty ? "未开始" : torrent.name).font(.headline).lineLimit(1)
                            Spacer()
                            Text(torrent.speed).font(.caption)
                        }
                        ProgressView(value: torrent.progress)
                        Text(torrent.status).font(.caption).foregroundStyle(.secondary)
                        if let saved = torrent.savedURL { Text("保存至：\(saved.lastPathComponent)").font(.caption2) }
                    }
                    .padding(14).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }.padding()
            }
            .frame(maxWidth: 720).frame(maxWidth: .infinity).navigationTitle("BT 下载")
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.data]) { result in
                if case .success(let url) = result, url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url) {
                        torrent.start(magnet: "data:application/x-bittorrent;base64," + data.base64EncodedString())
                    }
                }
            }
        }
    }
}
