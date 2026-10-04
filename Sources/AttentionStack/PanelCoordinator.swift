import AppKit
import Combine
import QuartzCore
import SwiftUI

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class PanelCoordinator: ObservableObject {
    @Published private(set) var isExpanded = false
    @Published var showingArchive = false
    @Published private(set) var width: CGFloat = 392
    @Published private(set) var height: CGFloat = 74
    @Published var inputRequest = 0
    private(set) var panel: FloatingPanel?
    private var screenObserver: NSObjectProtocol?
    private var subscriptions = Set<AnyCancellable>()
    private var storedCenter: CGFloat?
    private var storedTop: CGFloat?
    private var hasPosition = false

    func start(store: StackStore) {
        let panel = FloatingPanel(contentRect: .zero,
                                  styleMask: [.borderless, .nonactivatingPanel],
                                  backing: .buffered, defer: false)
        panel.title = "Attention Stack"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: StackView(store: store, coordinator: self))
        panel.setAccessibilityLabel("Attention Stack 悬浮专注面板")
        self.panel = panel

        if UserDefaults.standard.object(forKey: "panel.centerX") != nil {
            storedCenter = UserDefaults.standard.double(forKey: "panel.centerX")
            storedTop = UserDefaults.standard.double(forKey: "panel.topY")
            hasPosition = true
        }
        resize(animated: false)
        panel.orderFrontRegardless()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.resize(animated: false) }
        }
        store.$state.map { $0.pending.count }.removeDuplicates().sink { [weak self] _ in
            Task { @MainActor in self?.resize(animated: true) }
        }.store(in: &subscriptions)
        if ProcessInfo.processInfo.arguments.contains("--expanded") || Bundle.main.bundleIdentifier?.hasSuffix(".qa") == true { expand() }
    }

    func toggle() { isExpanded ? collapse() : expand() }

    func expand(focusInput: Bool = false) {
        showingArchive = false
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) { isExpanded = true }
        resize(animated: true)
        panel?.makeKeyAndOrderFront(nil)
        if focusInput { inputRequest += 1 }
    }

    func collapse() {
        panel?.makeFirstResponder(nil)
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) { isExpanded = false }
        resize(animated: true)
        panel?.resignKey()
    }

    func show() { panel?.orderFrontRegardless() }
    func hide() { panel?.orderOut(nil) }

    func home() {
        hasPosition = false
        storedCenter = nil
        storedTop = nil
        UserDefaults.standard.removeObject(forKey: "panel.centerX")
        UserDefaults.standard.removeObject(forKey: "panel.topY")
        resize(animated: true)
        show()
    }

    func didDrag() {
        guard let panel else { return }
        storedCenter = panel.frame.midX
        storedTop = panel.frame.maxY
        hasPosition = true
        resize(animated: false)
        UserDefaults.standard.set(panel.frame.midX, forKey: "panel.centerX")
        UserDefaults.standard.set(panel.frame.maxY, forKey: "panel.topY")
    }

    private func resize(animated: Bool) {
        guard let panel else { return }
        let center = storedCenter ?? NSScreen.main?.visibleFrame.midX ?? 600
        let top = storedTop ?? NSScreen.main?.visibleFrame.maxY ?? 800
        let screen = NSScreen.screens.first {
            $0.frame.contains(NSPoint(x: center, y: top - 20))
        } ?? panel.screen ?? NSScreen.main
        guard let screen else { return }
        let safe = screen.visibleFrame.insetBy(dx: 8, dy: 8)
        let smallPreview = Bundle.main.bundleIdentifier?.hasSuffix(".qa") == true &&
            UserDefaults.standard.bool(forKey: "qa.smallPreview")
        width = min(smallPreview && isExpanded ? 340 : isExpanded ? 440 : 392, safe.width)
        height = min(smallPreview && isExpanded ? 480 : isExpanded ? 638 : 74, safe.height)
        let x = min(max(center - width / 2, safe.minX), safe.maxX - width)
        let anchorTop = hasPosition ? top : safe.maxY
        let y = min(max(anchorTop - height, safe.minY), safe.maxY - height)
        let frame = NSRect(x: x, y: y, width: width, height: height)
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.23
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(frame, display: true)
            }
        } else { panel.setFrame(frame, display: true) }
    }
}

/// Native window dragging works on both the collapsed pill and expanded header.
struct WindowDragRegion: NSViewRepresentable {
    var onClick: () -> Void
    var onDragEnded: () -> Void

    func makeNSView(context: Context) -> DragView { DragView(onClick: onClick, onDragEnded: onDragEnded) }
    func updateNSView(_ view: DragView, context: Context) {
        view.onClick = onClick
        view.onDragEnded = onDragEnded
    }

    final class DragView: NSView {
        var onClick: () -> Void
        var onDragEnded: () -> Void
        init(onClick: @escaping () -> Void, onDragEnded: @escaping () -> Void) {
            self.onClick = onClick
            self.onDragEnded = onDragEnded
            super.init(frame: .zero)
            setAccessibilityElement(true)
            setAccessibilityRole(.button)
            setAccessibilityLabel("展开或收起 Attention Stack；拖动以移动面板")
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }
        override func accessibilityPerformPress() -> Bool { onClick(); return true }
        override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }
        override func mouseDown(with event: NSEvent) {
            guard let window else { return }
            let origin = event.locationInWindow
            while let next = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) {
                if next.type == .leftMouseUp { onClick(); return }
                let distance = hypot(next.locationInWindow.x - origin.x, next.locationInWindow.y - origin.y)
                if distance > 3 {
                    window.performDrag(with: next)
                    onDragEnded()
                    return
                }
            }
        }
    }
}
