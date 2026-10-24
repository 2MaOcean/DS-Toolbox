import SwiftUI

struct FileBrowserPane: View {
    let rootDirectory: URL
    let paneLabel: String
    @Binding var selected: Set<URL>
    @State private var currentDirectory: URL
    @State private var files: [URL] = []
    @State private var searchText = ""
    @State private var sortOption: FileSortOption = .nameAsc
    @State private var renameTarget: URL?
    @State private var renameText = ""
    @State private var copyTargets: [URL] = []
    @State private var showCopyPicker = false
    @State private var conversionTarget: URL?
    @State private var infoTarget: URL?
    @State private var exportingURLs: [URL]?
    @State private var toast: String?
    @State private var showCreateFolder = false
    @State private var newFolderName = ""
    @State private var showTorrentSheet = false
    @State private var torrentResult: TorrentCreationResult?
    @State private var showDeleteHighRiskAlert = false
    @State private var pendingDeleteTargets: [URL] = []

    init(rootDirectory: URL, paneLabel: String, selected: Binding<Set<URL>>) {
        self.rootDirectory = rootDirectory
        self.paneLabel = paneLabel
        self._selected = selected
        self._currentDirectory = State(initialValue: rootDirectory)
    }

    private var displayedFiles: [URL] {
        let filtered = searchText.isEmpty ? files : files.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) }
        let dirs = filtered.filter { FileSorter.isDirectory($0) }
        let regular = filtered.filter { !FileSorter.isDirectory($0) }
        return FileSorter.sort(dirs, by: sortOption) + FileSorter.sort(regular, by: sortOption)
    }

    var body: some View {
        NavigationStack {
            List(selection: $selected) {
                if displayedFiles.isEmpty {
                    ContentUnavailableView(searchText.isEmpty ? "空目录" : "没有匹配文件", systemImage: "folder", description: Text(searchText.isEmpty ? "拖入文件或从其他窗格复制" : "换个关键词试试"))
                }
                ForEach(displayedFiles, id: \.self) { f in row(for: f) }
            }
            .searchable(text: $searchText, prompt: "搜索文件")
            .navigationTitle(currentDirectory.path == rootDirectory.path ? paneLabel : currentDirectory.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if currentDirectory.path != rootDirectory.path { Button { goUp() } label: { Image(systemName: "chevron.up") } }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("排序", selection: $sortOption) { ForEach(FileSortOption.allCases) { opt in Text(opt.label).tag(opt) } }
                        Divider()
                        Button("新建文件夹") { showCreateFolder = true }
                        Button("刷新") { reload() }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
                ToolbarItem(placement: .primaryAction) { EditButton() }
                ToolbarItemGroup(placement: .bottomBar) {
                    if !selected.isEmpty {
                        Button { exportingURLs = Array(selected) } label: { Label("导出", systemImage: "square.and.arrow.up") }
                        Spacer()
                        Button { copyTargets = Array(selected); showCopyPicker = true } label: { Label("复制到…", systemImage: "doc.on.doc") }
                        Spacer()
                        Button(role: .destructive) { requestDelete(Array(selected)) } label: { Label("删除", systemImage: "trash") }
                    } else {
                        Button("刷新", systemImage: "arrow.clockwise") { reload() }
                        Spacer()
                        Text("\(files.count) 项").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear(perform: reload)
            .onChange(of: currentDirectory) { _, _ in reload() }
            .dropDestination(for: URL.self) { urls, _ in handleDrop(urls); return true }
            .sheet(item: Binding(get: { exportingURLs.map { ExportWrapper(urls: $0) } }, set: { exportingURLs = $0?.urls })) { w in DocumentExporter(urls: w.urls) }
            .sheet(isPresented: $showCopyPicker) { DirectoryPickerView { directory in performCopy(to: directory) } }
            .sheet(isPresented: $showTorrentSheet) { TorrentCreationSheet(sources: Array(selected), outputDirectory: currentDirectory) { r in torrentResult = r } }
            .sheet(item: $torrentResult) { result in TorrentResultView(result: result) }
            .navigationDestination(item: $conversionTarget) { url in FileConversionView(source: url, destDir: currentDirectory) }
            .navigationDestination(item: $infoTarget) { url in FileInfoView(url: url) }
            .navigationDestination(for: URL.self) { url in FileViewer(url: url) }
            .alert("高风险操作确认", isPresented: $showDeleteHighRiskAlert) {
                Button("强制删除", role: .destructive) { performDelete(pendingDeleteTargets); pendingDeleteTargets = [] }
                Button("取消", role: .cancel) { pendingDeleteTargets = [] }
            } message: { Text("您选中的包含高风险文件夹或系统文件。强制删除可能导致系统或应用崩溃，确定继续吗？") }
            .alert("重命名", isPresented: Binding(get: { renameTarget != nil }, set: { if !$0 { renameTarget = nil } })) {
                TextField("新文件名", text: $renameText); Button("确定") { performRename() }; Button("取消", role: .cancel) { renameTarget = nil }
            }
            .alert("新建文件夹", isPresented: $showCreateFolder) {
                TextField("文件夹名称", text: $newFolderName); Button("创建") { performCreateFolder() }; Button("取消", role: .cancel) { newFolderName = "" }
            }
            .alert("提示", isPresented: Binding(get: { toast != nil }, set: { if !$0 { toast = nil } })) { Button("好", role: .cancel) {} } message: { Text(toast ?? "") }
        }
    }

    @ViewBuilder
    private func row(for f: URL) -> some View {
        let isDir = FileSorter.isDirectory(f)
        let risk = FileRiskManager.shared.level(for: f)
        HStack {
            if risk == .high {
                Image(systemName: isDir ? "folder.fill.badge.gearshape" : "exclamationmark.shield.fill").foregroundStyle(.red)
            } else {
                Image(systemName: isDir ? "folder" : FileTypeDetector.iconName(for: f)).foregroundStyle(isDir ? .blue : .tint)
            }
            VStack(alignment: .leading) {
                HStack {
                    Text(f.lastPathComponent).lineLimit(1)
                    if risk == .high {
                        Text("高风险").font(.caption2).foregroundStyle(.red).padding(.horizontal, 4).padding(.vertical, 1).background(Color.red.opacity(0.1)).cornerRadius(4)
                    }
                }
                if !isDir {
                    HStack(spacing: 8) {
                        Text(byteString(FileSorter.size(f) ?? 0)).font(.caption2).foregroundStyle(.secondary)
                        if let d = FileSorter.date(f) { Text(d.formatted(date: .numeric, time: .shortened)).font(.caption2).foregroundStyle(.secondary) }
                    }
                }
            }
            Spacer()
            if isDir { Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary) }
        }
        .contentShape(Rectangle())
        .onTapGesture { if isDir { currentDirectory = f; selected.removeAll() } else { selected = [f] } }
        .tag(f)
        .draggable(f) { HStack { Image(systemName: isDir ? "folder" : FileTypeDetector.iconName(for: f)); Text(f.lastPathComponent).lineLimit(1) }.padding(8).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10)) }
        .swipeActions {
            Button("导出") { exportingURLs = [f] }
            Button(role: .destructive) { requestDelete([f]) } label: { Label("删除", systemImage: "trash") }
        }
        .contextMenu {
            if isDir { Button { currentDirectory = f } label: { Label("打开", systemImage: "folder") } }
            else {
                Button { infoTarget = f } label: { Label("信息", systemImage: "info.circle") }
                Button { conversionTarget = f } label: { Label("转换", systemImage: "arrow.triangle.2.circlepath") }
                ShareLink(item: f) { Label("分享", systemImage: "square.and.arrow.up") }
            }
            Button { renameTarget = f; renameText = f.lastPathComponent } label: { Label("重命名", systemImage: "pencil") }
            Button { copyTargets = [f]; showCopyPicker = true } label: { Label("复制到…", systemImage: "doc.on.doc") }
            Button { selected = [f]; showTorrentSheet = true } label: { Label("生成种子", systemImage: "point.3.connected.trianglepath.dotted") }
            Button(role: .destructive) { requestDelete([f]) } label: { Label("删除", systemImage: "trash") }
        }
    }

    private func requestDelete(_ targets: [URL]) {
        if targets.contains(where: { FileRiskManager.shared.level(for: $0) == .high }) {
            pendingDeleteTargets = targets
            showDeleteHighRiskAlert = true
        } else { performDelete(targets) }
    }

    private func performDelete(_ targets: [URL]) {
        for f in targets { try? FileManager.default.removeItem(at: f) }
        reload()
    }

    private func handleDrop(_ urls: [URL]) -> Bool {
        do { let c = try FileOperations.copy(urls, to: currentDirectory); toast = "已复制 \(c.count) 项"; reload() } catch { toast = error.localizedDescription }
        return true
    }
    private func performCopy(to directory: URL) {
        guard !copyTargets.isEmpty else { return }
        do { _ = try FileOperations.copy(copyTargets, to: directory); toast = "已复制 \(copyTargets.count) 项"; copyTargets = [] } catch { toast = error.localizedDescription }
    }
    private func performRename() {
        guard let target = renameTarget else { return }
        do { _ = try FileOperations.rename(target, to: renameText); renameTarget = nil; reload() } catch { toast = error.localizedDescription }
    }
    private func performCreateFolder() {
        do { _ = try FileOperations.createFolder(in: currentDirectory, named: newFolderName); newFolderName = ""; reload() } catch { toast = error.localizedDescription }
    }
    private func goUp() {
        let parent = currentDirectory.deletingLastPathComponent()
        if parent.path.hasPrefix(rootDirectory.path) || parent.path == rootDirectory.path { currentDirectory = parent }
    }
    private func reload() {
        files = ((try? FileManager.default.contentsOfDirectory(at: currentDirectory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey])) ?? [])
        selected = selected.filter { files.contains($0) }
    }
}
