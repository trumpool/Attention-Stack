import AppKit
import SwiftUI

@main
struct AttentionStackApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    init() {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--make-icon"), arguments.count > index + 1 {
            do { try IconGenerator.write(to: URL(fileURLWithPath: arguments[index + 1])) }
            catch { fputs("Icon generation failed: \(error)\n", stderr); exit(1) }
            exit(0)
        }
    }
    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = StackStore()
    let coordinator = PanelCoordinator()
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenu()
        coordinator.start(store: store)
    }

    private func setupMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "square.3.layers.3d", accessibilityDescription: "Attention Stack")
        item.button?.toolTip = "Attention Stack"
        let menu = NSMenu()
        menu.addItem(withTitle: "Attention Stack", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(menuItem("展开专注栈", action: #selector(showStack), key: ""))
        menu.addItem(menuItem("添加一个想法…", action: #selector(addIdea), key: "n"))
        menu.addItem(menuItem("查看归档", action: #selector(showArchive), key: ""))
        menu.addItem(menuItem("回到屏幕顶部", action: #selector(moveHome), key: ""))
        menu.addItem(menuItem("暂时隐藏悬浮窗", action: #selector(hideStack), key: ""))
        menu.addItem(.separator())
        menu.addItem(menuItem("退出 Attention Stack", action: #selector(quit), key: "q"))
        item.menu = menu
        statusItem = item
    }

    private func menuItem(_ title: String, action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func showStack() { coordinator.expand() }
    @objc private func addIdea() { coordinator.expand(focusInput: true) }
    @objc private func showArchive() { coordinator.expand(); coordinator.showingArchive = true }
    @objc private func moveHome() { coordinator.home() }
    @objc private func hideStack() { coordinator.hide() }
    @objc private func quit() { NSApp.terminate(nil) }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
