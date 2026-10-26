import SwiftUI

struct FileBrowserPane: View {
    let rootDirectory: URL
    let paneLabel: String
    @State private var currentDirectory: URL
    @State private var files: [URL] = []
    @State private var selected: Set<URL> = []
    @State private var searchText = ""
    @State private var showDeleteAlert = false
    @State private var pendingDelete: [URL] = []
    @State private var createPrompt = false
    @State private var createKind: CreateKind = .folder
    @State private var newName = ""
    @State private var errorText: String?
    @State private var accessDenied = false
    @State private var showLaraSheet = false

    enum CreateKind: String, CaseIterable, Identifiable {
        case folder = "文件夹", plist = "plist", xml = "xml", json = "json"
        var id: String { rawValue }
    }

    init(rootDirectory: URL, paneLabel: String) {
        self.rootDirectory = rootDirectory
        self.paneLabel = paneLabel
        self._currentDirectory = State(initialValue: rootDirectory)
    }

    private var displayedFiles: [URL] {
        let filtered = searchText.isEmpty ? files : files.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) }
        let dirs = filtered.filter { FileSorter.isDirectory($0) }
        let regular = filtered.filter { !FileSorter.isDirectory($0) }
        return FileSorter.sort(dirs, by: .nameAsc) + FileSorter.sort(regular, by: .nameAsc)
    }

    var body: some View {
        NavigationStack {
            List(selection: $selected) {
                if displayedFiles.isEmpty { emptyState }
                ForEach(displayedFiles, id: \.self) { f in row(for: f) }
            }
            .searchable(text: $searchText, prompt: "搜索文件")
            .navigationTitle(currentDirectory.path == rootDirectory.path ? paneLabel : currentDirectory.lastPathComponent)
            .toolbar { toolbar }
            .overlay(alignment: .top) { errorBanner }
            .alert("高风险确认", isPresented: $showDeleteAlert) {
                Button("删除", role: .destructive) { performDelete(pendingDelete); pendingDelete = [] }
                Button("取消", role: .cancel) { pendingDelete = [] }
            } message: { Text("包含高风险文件或系统目录，确定继续吗？") }
            .alert("新建 \(createKind.rawValue)", isPresented: $createPrompt) {
                TextField("名称", text: $newName)
                Button("创建") { createNew() }
                Button("取消", role: .cancel) { newName = "" }
            }
            .onAppear(perform: reload)
            .onChange(of: currentDirectory) { _, _ in reload() }
        }
    }

    @ViewBuilder private var emptyState: some View {
        if accessDenied {
            ContentUnavailableView {
                Label("无法访问", systemImage: "lock.fill")
            } description: {
                Text("当前环境无权读取此目录。越狱 / TrollStore 环境可访问系统路径；普通安装只能浏览 App 沙盒。")
            }
        } else {
            ContentUnavailableView("空目录", systemImage: "folder")
        }
    }

    @ViewBuilder private var errorBanner: some View {
        if let e = errorText {
            Text(e)
                .font(.caption).foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color.red.opacity(0.9)).cornerRadius(8)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        withAnimation { errorText = nil }
                    }
                }
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if currentDirectory.path != rootDirectory.path {
                Button { goUp() } label: { Image(systemName: "chevron.up") }
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                let t: URL = SandboxService.shared.level == .root ? URL(fileURLWithPath: "/") : URL(fileURLWithPath: NSHomeDirectory())
                currentDirectory = t
            } label: { Image(systemName: "externaldrive") }
        }
        ToolbarItem(placement: .primaryAction) {
            Menu {
                ForEach(CreateKind.allCases) { k in
                    Button("新建 \(k.rawValue)") {
                        createKind = k; newName = ""; createPrompt = true
                    }
                }
            } label: { Image(systemName: "plus") }
        }
        ToolbarItem(placement: .bottomBar) {
            if !selected.isEmpty {
                Button(role: .destructive) { requestDelete(Array(selected)) } label: { Image(systemName: "trash") }
            } else {
                Button { reload() } label: { Image(systemName: "arrow.clockwise") }
            }
        }
    }

    @ViewBuilder private func row(for f: URL) -> some View {
        let isDir = FileSorter.isDirectory(f)
        let risk = FileRiskManager.shared.level(for: f)
        if isDir {
            Button { currentDirectory = f } label: { rowContent(f, isDir: true, risk: risk) }
                .tag(f).contextMenu { contextMenu(for: f) }
        } else {
            NavigationLink { FileViewer(url: f) } label: { rowContent(f, isDir: false, risk: risk) }
                .tag(f).contextMenu { contextMenu(for: f) }
        }
    }

    @ViewBuilder private func rowContent(_ f: URL, isDir: Bool, risk: FileRiskLevel) -> some View {
        HStack {
            Image(systemName: isDir ? "folder" : FileTypeDetector.iconName(for: f))
                .foregroundStyle(risk == .high ? Color.red : Color.accentColor)
            Text(f.lastPathComponent).lineLimit(1)
            Spacer()
            if risk == .high {
                Text("高风险").font(.caption2).foregroundStyle(.red)
                    .padding(.horizontal, 4).background(Color.red.opacity(0.1)).cornerRadius(4)
            }
        }
    }

    @ViewBuilder private func contextMenu(for f: URL) -> some View {
        NavigationLink("信息") { FileInfoView(url: f) }
        if !FileSorter.isDirectory(f) {
            NavigationLink("转换") { FileConversionView(source: f, destDir: currentDirectory) }
        }
        Button("删除", role: .destructive) { requestDelete([f]) }
    }

    private func requestDelete(_ targets: [URL]) {
        if targets.contains(where: { FileRiskManager.shared.level(for: $0) == .high }) {
            pendingDelete = targets
            showDeleteAlert = true
        } else {
            performDelete(targets)
        }
    }

    private func performDelete(_ targets: [URL]) {
        for f in targets { try? FileManager.default.removeItem(at: f) }
        reload()
    }

    private func createNew() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { errorText = "名称不能为空"; return }
        do {
            switch createKind {
            case .folder: _ = try FileOperations.createFolder(in: currentDirectory, named: trimmed)
            case .plist: _ = try FileOperations.createPlist(in: currentDirectory, named: trimmed, content: [:])
            case .xml: _ = try FileOperations.createXML(in: currentDirectory, named: trimmed, content: "<?xml version=\"1.0\"?><root/>")
            case .json: _ = try FileOperations.createJSON(in: currentDirectory, named: trimmed, content: "{}")
            }
            newName = ""
            reload()
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func goUp() {
        let parent = currentDirectory.deletingLastPathComponent()
        if parent.path.hasPrefix(rootDirectory.path) { currentDirectory = parent }
    }

    private func reload() {
        do {
            files = try FileManager.default.contentsOfDirectory(at: currentDirectory, includingPropertiesForKeys: nil)
            accessDenied = false
        } catch {
            files = []
            accessDenied = true
        }
        selected = selected.filter { files.contains($0) }
    }
}
