import Foundation

public struct AttentionItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public let enqueuedAt: Date
    public var focusedAt: Date?
    public var completedAt: Date?
    public var focusedSeconds: TimeInterval

    public init(title: String, at date: Date = Date()) {
        id = UUID()
        self.title = title
        enqueuedAt = date
        focusedSeconds = 0
    }

    public func attentionDuration(at date: Date = Date()) -> TimeInterval {
        focusedSeconds + (focusedAt.map { max(0, date.timeIntervalSince($0)) } ?? 0)
    }

    mutating func pause(at date: Date) {
        focusedSeconds = attentionDuration(at: date)
        focusedAt = nil
    }
}

/// New thoughts enter the top of the stack without interrupting the active task.
public struct AttentionState: Codable, Equatable, Sendable {
    public var current: AttentionItem?
    public var pending: [AttentionItem]
    public var archive: [AttentionItem]

    public init() {
        current = nil
        pending = []
        archive = []
    }

    @discardableResult
    public mutating func add(_ title: String, at date: Date = Date()) -> UUID? {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }
        var item = AttentionItem(title: title, at: date)
        if current == nil {
            item.focusedAt = date
            current = item
        } else {
            pending.insert(item, at: 0)
        }
        return item.id
    }

    @discardableResult
    public mutating func complete(at date: Date = Date()) -> AttentionItem? {
        guard var item = current else { return nil }
        item.pause(at: date)
        item.completedAt = date
        archive.insert(item, at: 0)
        current = nil
        advance(at: date)
        return item
    }

    public mutating func promote(_ id: UUID, at date: Date = Date()) {
        guard let index = pending.firstIndex(where: { $0.id == id }) else { return }
        var next = pending.remove(at: index)
        if var previous = current {
            previous.pause(at: date)
            pending.insert(previous, at: 0)
        }
        next.focusedAt = date
        current = next
    }

    public mutating func move(_ id: UUID, before targetID: UUID?) {
        guard id != targetID,
              let source = pending.firstIndex(where: { $0.id == id }) else { return }
        let item = pending.remove(at: source)
        if let targetID, let target = pending.firstIndex(where: { $0.id == targetID }) {
            pending.insert(item, at: target)
        } else {
            pending.append(item)
        }
    }

    public mutating func restore(_ id: UUID, at date: Date = Date()) {
        guard let original = archive.first(where: { $0.id == id }) else { return }
        // Repeating a task is a new attempt; its previous completion stays archived.
        add(original.title, at: date)
    }

    public mutating func undoCompletion(_ id: UUID, at date: Date = Date()) {
        guard let index = archive.firstIndex(where: { $0.id == id }) else { return }
        var item = archive.remove(at: index)
        if var previous = current {
            previous.pause(at: date)
            pending.insert(previous, at: 0)
        }
        item.completedAt = nil
        item.focusedAt = date
        current = item
    }

    public mutating func rename(_ id: UUID, to title: String) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        if current?.id == id { current?.title = title }
        if let index = pending.firstIndex(where: { $0.id == id }) { pending[index].title = title }
    }

    private mutating func advance(at date: Date) {
        guard !pending.isEmpty else { return }
        var next = pending.removeFirst()
        next.focusedAt = date
        current = next
    }
}
