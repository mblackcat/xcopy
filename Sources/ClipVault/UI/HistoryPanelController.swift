import AppKit
import SwiftUI

class HistoryPanelController {
    private let panel: HistoryPanel
    private let store: ClipboardStore
    private let settingsManager: SettingsManager
    private var clickOutsideMonitor: Any?
    private var previousApp: NSRunningApplication?

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
        previousApp = NSWorkspace.shared.frontmostApplication
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
        let appToRestore = previousApp
        hide()
        store.writeToPasteboard(item)

        // Activate the previously focused app using the correct API for the OS version
        if #available(macOS 14.0, *) {
            appToRestore?.activate()
        } else {
            appToRestore?.activate(options: .activateIgnoringOtherApps)
        }

        // Wait for app switch to fully complete, then simulate Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PasteService.simulatePaste()
        }
    }

    private func positionNearMouse() {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) })
              ?? NSScreen.main else { return }

        let panelSize = panel.frame.size
        let safe = screen.visibleFrame
        let margin: CGFloat = 4

        // macOS coordinates: origin at bottom-left, y increases upward.
        // Default: panel top-left corner at cursor (origin.y = mouse.y - panelHeight).
        var x = mouse.x
        var y = mouse.y - panelSize.height

        // Flip horizontally: if panel would overflow right edge, place it to the left of cursor
        if x + panelSize.width > safe.maxX - margin {
            x = mouse.x - panelSize.width
        }
        // If still overflows left edge, clamp to left
        if x < safe.minX + margin {
            x = safe.minX + margin
        }

        // Flip vertically: if panel would overflow below bottom edge, place it above cursor
        if y < safe.minY + margin {
            y = mouse.y
        }
        // If still overflows top edge, clamp to top
        if y + panelSize.height > safe.maxY - margin {
            y = safe.maxY - panelSize.height - margin
        }
        // Final safety clamp for bottom
        if y < safe.minY + margin {
            y = safe.minY + margin
        }

        panel.setFrameOrigin(NSPoint(x: x, y: y))
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
