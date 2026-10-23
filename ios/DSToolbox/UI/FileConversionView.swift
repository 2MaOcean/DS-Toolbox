import SwiftUI
struct FileConversionView: View {
    let source: URL; let destDir: URL
    @State private var conversion: FileConversion = .plistToXML
    @State private var error: String?; @State private var success: URL?
    var body: some View {
        Form {
            Section("源文件") { LabeledContent("名称", value: source.lastPathComponent) }
            Section("转换类型") { Picker("格式", selection: $conversion) { ForEach(FileConversion.allCases) { Text($0.label).tag($0) } }.pickerStyle(.menu) }
            if let error { Section { Text(error).foregroundStyle(.red) } }
            if let success { Section("结果") { LabeledContent("已生成", value: success.lastPathComponent); NavigationLink("查看结果") { FileViewer(url: success) } } }
            Section { Button("执行转换") { do { success = try FileConverter.convert(source: source, conversion: conversion, to: destDir); error = nil } catch { self.error = error.localizedDescription } }.buttonStyle(.borderedProminent) }
        }.navigationTitle("文件转换").navigationBarTitleDisplayMode(.inline)
    }
}
