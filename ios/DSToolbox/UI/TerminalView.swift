import SwiftUI

struct TerminalLine: Identifiable {
    let id = UUID()
    let text: String
    let kind: Kind
    enum Kind { case input, output, error, info }
}

struct TerminalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var engine = CommandEngine.shared
    @State private var lines: [TerminalLine] = []
    @State private var input = ""
    @State private var history: [String] = []
    @State private var histIndex = -1
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                backendBar
                outputArea
                Divider()
                inputBar
            }
            .background(Color.black)
            .navigationTitle("终端")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button("清屏") { lines.removeAll() } }
            }
            .onAppear {
                focused = true
                if lines.isEmpty {
                    append("DS-Toolbox Terminal v1.1", .info)
                    append("后端: \(ShellBackend.current.label)", .info)
                    append("目录: \(engine.cwdString)", .info)
                    append("输入 help 查看命令；长按输出可复制", .info)
                }
            }
        }
    }

    private var backendBar: some View {
        HStack {
            Circle()
                .fill(ShellBackend.current == .sandbox ? Color.orange : Color.green)
                .frame(width: 8, height: 8)
            Text(ShellBackend.current.label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.gray)
            Spacer()
            Text(engine.cwdString)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.green).lineLimit(1)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color(white: 0.08))
    }

    private var outputArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(lines) { line in
                        Text(line.text)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(color(for: line.kind))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .id(line.id)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
            }
            .onChange(of: lines.count) { _, _ in
                withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 6) {
            Button { histMove(-1) } label: { Image(systemName: "chevron.up") }
                .disabled(history.isEmpty)
            Button { histMove(1) } label: { Image(systemName: "chevron.down") }
                .disabled(history.isEmpty)
            Text("$")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.green)
            TextField("", text: $input)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focused)
                .onSubmit(run)
            Button("执行", action: run).font(.caption)
        }
        .padding(8)
        .background(Color(white: 0.1))
    }

    private func run() {
        let cmd = input.trimmingCharacters(in: .whitespacesAndNewlines)
        append("$ \(cmd)", .input)
        input = ""
        guard !cmd.isEmpty else { return }
        history.append(cmd)
        histIndex = history.count
        let result = engine.execute(cmd)
        if result.shouldClear { lines.removeAll(); return }
        if result.shouldExit { dismiss(); return }
        if !result.output.isEmpty { append(result.output, result.isError ? .error : .output) }
    }

    private func append(_ text: String, _ kind: TerminalLine.Kind) {
        lines.append(TerminalLine(text: text, kind: kind))
    }

    private func histMove(_ delta: Int) {
        guard !history.isEmpty else { return }
        histIndex = max(0, min(history.count - 1, histIndex + delta))
        input = history[histIndex]
    }

    private func color(for kind: TerminalLine.Kind) -> Color {
        switch kind {
        case .input:  return .green
        case .output: return .white
        case .error:  return .red
        case .info:   return .gray
        }
    }
}
