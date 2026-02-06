import AppKit
import SwiftUI

class HistoryPanelController {
    private let panel: HistoryPanel
    private let store: ClipboardStore
    private let settingsManager: SettingsManager
    private var clickOutsideMonitor: Any?

    init(store: ClipboardStore, settingsManager: SettingsManager) {
        self.store = store
        self.settingsManager = settingsManager
        self.panel = HistoryPanel()

        let historyView = ClipboardHistoryView(store: store) { [weak self] item in
            self?.selectItem(item)
        }
        let hostingView = NSHostingView(rootView: historyView)
        panel.contentView = hostingView

        setupEscapeHandler()
    }

    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        positionNearMouse()
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        startClickOutsideMonitor()
    }

    func hide() {
        panel.orderOut(nil)
        stopClickOutsideMonitor()
    }

    private func selectItem(_ item: ClipboardItem) {
        hide()
        store.writeToPasteboard(item)
        PasteService.simulatePaste()
    }

    private func positionNearMouse() {
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
              ?? NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        var origin = NSPoint(
            x: mouseLocation.x - Constants.panelWidth / 2,
            y: mouseLocation.y - Constants.panelHeight / 2
        )

        // Clamp to screen bounds
        origin.x = max(screenFrame.minX, min(origin.x, screenFrame.maxX - Constants.panelWidth))
        origin.y = max(screenFrame.minY, min(origin.y, screenFrame.maxY - Constants.panelHeight))

        panel.setFrameOrigin(origin)
    }

    private func setupEscapeHandler() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 && self?.panel.isVisible == true {
                self?.hide()
                return nil
            }
            return event
        }
    }

    private func startClickOutsideMonitor() {
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hide()
        }
    }

    private func stopClickOutsideMonitor() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }
}
