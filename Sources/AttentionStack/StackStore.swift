import AppKit
import AttentionCore
import Combine
import SwiftUI

@MainActor
final class StackStore: ObservableObject {
    @Published private(set) var state = AttentionState()
    @Published var toast: String?
    @Published var lastCompletedID: UUID?
    @Published var storageError: String?
    @Published var celebration = 0
    @Published var insertionPosition: InsertionPosition = .front {
        didSet { UserDefaults.standard.set(insertionPosition.rawValue, forKey: "insertionPosition") }
    }
    private var toastTask: Task<Void, Never>?
    private var unreadableOriginal = false
    let fileURL: URL

    init() {
        insertionPosition = InsertionPosition(rawValue: UserDefaults.standard.string(forKey: "insertionPosition") ?? "") ?? .front
        let isDemo = ProcessInfo.processInfo.arguments.contains("--demo")
        let isQA = ProcessInfo.processInfo.arguments.contains("--qa") || Bundle.main.bundleIdentifier?.hasSuffix(".qa") == true
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(isQA ? "Attention Stack QA" : isDemo ? "Attention Stack Demo" : "Attention Stack", isDirectory: true)
        fileURL = root.appendingPathComponent("stack.json")
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            if !isDemo && !isQA && !FileManager.default.fileExists(atPath: fileURL.path) {
                let legacy = root.deletingLastPathComponent()
                    .appendingPathComponent("Attention Stack Demo/stack.json")
                if FileManager.default.fileExists(atPath: legacy.path) {
                    // Preserve any tasks entered while the first preview was running.
                    try FileManager.default.copyItem(at: legacy, to: fileURL)
                }
            }
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                state = try JSONDecoder.stack.decode(AttentionState.self, from: data)
            }
        } catch {
            unreadableOriginal = true
            storageError = "无法读取记录，原文件已保留：\(error.localizedDescription)"
        }
        if (isDemo || isQA) && !unreadableOriginal && state.current == nil && state.pending.isEmpty && state.archive.isEmpty {
            let now = Date()
            state.add("整理今天的灵感", at: now.addingTimeInterval(-3600))
            state.complete(at: now.addingTimeInterval(-2800))
            state.add("把 Attention Stack 的想法做出来", at: now.addingTimeInterval(-1500))
            state.add("读完那篇一直想看的文章", at: now.addingTimeInterval(-1000))
            state.add("给周末留一点空白", at: now.addingTimeInterval(-800))
            state.add("画出下一版的交互草图", at: now.addingTimeInterval(-300))
            save()
        }
    }

    func add(_ title: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        mutate { $0.add(title, position: insertionPosition) }
    }

    func complete() {
        guard let current = state.current else { return }
        mutate { $0.complete() }
        lastCompletedID = current.id
        celebration += 1
        showToast(state.current.map { "已完成。接下来：\($0.title)" } ?? "全部完成，给自己一点空白。")
    }

    func promote(_ id: UUID) { mutate { $0.promote(id) } }
    func move(_ id: UUID, before target: UUID?) { mutate { $0.move(id, before: target) } }
    func restore(_ id: UUID) {
        let hadCurrent = state.current != nil
        mutate { $0.restore(id, position: insertionPosition) }
        showToast(hadCurrent ? "已放回待办\(insertionPosition == .front ? "前面" : "后面")" : "已重新开始专注")
    }
    func rename(_ id: UUID, to title: String) { mutate { $0.rename(id, to: title) } }
    func undo() {
        guard let id = lastCompletedID else { return }
        mutate { $0.undoCompletion(id) }
        lastCompletedID = nil
        toast = nil
    }

    func exportArchive() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Attention-Stack-归档.json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try JSONEncoder.stack.encode(state.archive)
            try data.write(to: url, options: .atomic)
            showToast("归档已导出")
        } catch { storageError = "导出失败：\(error.localizedDescription)" }
    }

    private func mutate(_ operation: (inout AttentionState) -> Void) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { operation(&state) }
        save()
    }

    private func save() {
        // Do not overwrite unreadable user data with a fresh empty stack.
        guard !unreadableOriginal else { return }
        do {
            try JSONEncoder.stack.encode(state).write(to: fileURL, options: .atomic)
            storageError = nil
        } catch { storageError = "保存失败：\(error.localizedDescription)" }
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        withAnimation { toast = message }
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(7))
            guard !Task.isCancelled else { return }
            withAnimation { self?.toast = nil; self?.lastCompletedID = nil }
        }
    }
}

extension JSONEncoder {
    static var stack: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var stack: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
