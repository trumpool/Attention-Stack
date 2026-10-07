import AppKit
import SwiftUI

/// Use a persistent native scrollbar without changing the SwiftUI drag coordinate space.
struct VisibleVerticalScroller: NSViewRepresentable {
    func makeNSView(context: Context) -> Probe { Probe() }
    func updateNSView(_ view: Probe, context: Context) { view.configureScroller() }

    final class Probe: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            configureScroller()
        }

        func configureScroller() {
            DispatchQueue.main.async { [weak self] in
                guard let scroll = self?.enclosingScrollView else { return }
                scroll.hasVerticalScroller = true
                scroll.autohidesScrollers = false
                scroll.scrollerStyle = .legacy
                scroll.scrollerKnobStyle = .light
                scroll.drawsBackground = false
            }
        }
    }
}

struct PanelHeightDragRegion: NSViewRepresentable {
    @ObservedObject var coordinator: PanelCoordinator

    func makeNSView(context: Context) -> ResizeView { ResizeView(coordinator: coordinator) }
    func updateNSView(_ view: ResizeView, context: Context) {
        view.coordinator = coordinator
        view.setAccessibilityValue(coordinator.height)
    }

    final class ResizeView: NSView {
        var coordinator: PanelCoordinator

        init(coordinator: PanelCoordinator) {
            self.coordinator = coordinator
            super.init(frame: .zero)
            setAccessibilityElement(true)
            setAccessibilityRole(.slider)
            setAccessibilityLabel("调整待办区域高度")
            setAccessibilityHelp("向下拖动增高，向上拖动缩短；也可使用增加或减少操作")
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }
        override func resetCursorRects() { addCursorRect(bounds, cursor: .resizeUpDown) }
        override func accessibilityPerformIncrement() -> Bool {
            coordinator.adjustHeight(by: 40)
            return true
        }
        override func accessibilityPerformDecrement() -> Bool {
            coordinator.adjustHeight(by: -40)
            return true
        }

        override func mouseDown(with event: NSEvent) {
            guard let window else { return }
            let start = window.convertPoint(toScreen: event.locationInWindow)
            coordinator.beginHeightResize()
            defer { coordinator.endHeightResize() }
            while let next = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) {
                if next.type == .leftMouseUp { return }
                let point = window.convertPoint(toScreen: next.locationInWindow)
                coordinator.dragHeight(by: start.y - point.y)
            }
        }
    }
}
