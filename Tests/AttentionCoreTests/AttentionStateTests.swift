import Foundation
import Testing
@testable import AttentionCore

struct AttentionStateTests {
    let start = Date(timeIntervalSince1970: 1_790_000_000)

    @Test func newThoughtsDoNotInterruptAndUseStackOrder() {
        var stack = AttentionState()
        let first = stack.add("  写提案  ", at: start)
        stack.add("查资料", at: start.addingTimeInterval(10))
        stack.add("画草图", at: start.addingTimeInterval(20))
        #expect(stack.current?.id == first)
        #expect(stack.current?.title == "写提案")
        #expect(stack.pending.map(\.title) == ["画草图", "查资料"])
        #expect(stack.add(" \n ") == nil)
        #expect(stack.pending.count == 2)
    }

    @Test func completionRecordsBothTimestampsAndAdvances() {
        var stack = AttentionState()
        stack.add("第一件", at: start)
        stack.add("第二件", at: start.addingTimeInterval(5))
        let done = start.addingTimeInterval(120)
        let result = stack.complete(at: done)
        #expect(result?.enqueuedAt == start)
        #expect(result?.completedAt == done)
        #expect(result?.focusedSeconds == 120)
        #expect(result?.focusedAt == nil)
        #expect(stack.archive.count == 1)
        #expect(stack.current?.title == "第二件")
        #expect(stack.current?.focusedAt == done)
        #expect(stack.pending.isEmpty)
        stack.complete(at: done.addingTimeInterval(60))
        #expect(stack.current == nil)
        #expect(stack.archive.count == 2)
        #expect(stack.complete() == nil)
    }

    @Test func switchingFocusPreservesWaitingTaskAndAccumulatesActualFocusTime() {
        var stack = AttentionState()
        let original = stack.add("原任务", at: start)!
        let next = stack.add("切换任务", at: start.addingTimeInterval(10))!
        stack.promote(next, at: start.addingTimeInterval(50))
        #expect(stack.current?.id == next)
        #expect(stack.pending.first?.id == original)
        #expect(stack.pending.first?.enqueuedAt == start)
        #expect(stack.pending.first?.focusedSeconds == 50)
        #expect(stack.pending.first?.focusedAt == nil)
        stack.promote(original, at: start.addingTimeInterval(80))
        stack.complete(at: start.addingTimeInterval(100))
        #expect(stack.archive.first?.focusedSeconds == 70)
        #expect(stack.current?.focusedSeconds == 30)
        #expect(stack.current?.attentionDuration(at: start.addingTimeInterval(110)) == 40)
    }

    @Test func dragReorderingMaintainsIdentityAndSupportsMovingToEnd() {
        var stack = AttentionState()
        stack.add("当前", at: start)
        let a = stack.add("A", at: start)!
        let b = stack.add("B", at: start)!
        let c = stack.add("C", at: start)!
        stack.move(a, before: c)
        #expect(stack.pending.map(\.title) == ["A", "C", "B"])
        stack.move(c, before: nil)
        #expect(stack.pending.map(\.title) == ["A", "B", "C"])
        stack.move(b, before: b)
        stack.promote(UUID())
        #expect(Set(stack.pending.map(\.id)).count == 3)
        #expect(stack.current?.title == "当前")
    }

    @Test func undoRestoresCompletedTaskAndKeepsNextTaskQueued() {
        var stack = AttentionState()
        let first = stack.add("先做", at: start)!
        let second = stack.add("后做", at: start)!
        stack.complete(at: start.addingTimeInterval(10))
        stack.undoCompletion(first, at: start.addingTimeInterval(20))
        #expect(stack.archive.isEmpty)
        #expect(stack.current?.id == first)
        #expect(stack.current?.completedAt == nil)
        #expect(stack.current?.enqueuedAt == start)
        #expect(stack.pending.first?.id == second)
        #expect(stack.pending.first?.focusedSeconds == 10)
    }

    @Test func repeatingArchivedTaskCreatesNewAttemptWithoutLosingHistory() {
        var stack = AttentionState()
        let first = stack.add("每日阅读", at: start)!
        stack.complete(at: start.addingTimeInterval(60))
        let later = start.addingTimeInterval(86400)
        stack.restore(first, at: later)
        #expect(stack.archive.count == 1)
        #expect(stack.archive.first?.id == first)
        #expect(stack.current?.id != first)
        #expect(stack.current?.enqueuedAt == later)
        #expect(stack.current?.focusedSeconds == 0)
    }

    @Test func diskRoundTripPreservesQueueHistoryAndTimers() throws {
        var stack = AttentionState()
        stack.add("已完成", at: start)
        stack.complete(at: start.addingTimeInterval(20))
        stack.add("当前", at: start.addingTimeInterval(30))
        stack.add("等待", at: start.addingTimeInterval(40))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("stack.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(stack).write(to: url, options: .atomic)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let loaded = try decoder.decode(AttentionState.self, from: Data(contentsOf: url))
        #expect(loaded == stack)
    }
}
