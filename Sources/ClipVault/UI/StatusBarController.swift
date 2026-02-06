import AppKit

class StatusBarController {
    private var statusItem: NSStatusItem!
    private let onShowHistory: () -> Void
    private let onShowSettings: () -> Void
    private let onQuit: () -> Void

    init(onShowHistory: @escaping () -> Void,
         onShowSettings: @escaping () -> Void,
         onQuit: @escaping () -> Void) {
        self.onShowHistory = onShowHistory
        self.onShowSettings = onShowSettings
        self.onQuit = onQuit
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = createTemplateIcon()
            button.image?.isTemplate = true
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        setupMenu()
    }

    private func createTemplateIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.black.setStroke()

            // Clipboard outline
            let clipboardRect = NSRect(x: 3, y: 1, width: 12, height: 15)
            let clipboardPath = NSBezierPath(roundedRect: clipboardRect, xRadius: 1.5, yRadius: 1.5)
            clipboardPath.lineWidth = 1.2
            clipboardPath.stroke()

            // Clip at top
            let clipRect = NSRect(x: 6, y: 13, width: 6, height: 4)
            let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: 1.5, yRadius: 1.5)
            clipPath.lineWidth = 1.2
            clipPath.stroke()

            // Lines representing text
            let line1 = NSBezierPath()
            line1.move(to: NSPoint(x: 6, y: 11))
            line1.line(to: NSPoint(x: 12, y: 11))
            line1.lineWidth = 1.0
            line1.stroke()

            let line2 = NSBezierPath()
            line2.move(to: NSPoint(x: 6, y: 8))
            line2.line(to: NSPoint(x: 12, y: 8))
            line2.lineWidth = 1.0
            line2.stroke()

            let line3 = NSBezierPath()
            line3.move(to: NSPoint(x: 6, y: 5))
            line3.line(to: NSPoint(x: 10, y: 5))
            line3.lineWidth = 1.0
            line3.stroke()

            return true
        }
        image.isTemplate = true
        return image
    }

    private func setupMenu() {
        let menu = NSMenu()

        let historyItem = NSMenuItem(title: "Show History", action: #selector(showHistory), keyEquivalent: "")
        historyItem.target = self
        menu.addItem(historyItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit ClipVault", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func statusBarButtonClicked(_ sender: Any?) {
        // Menu handles the click
    }

    @objc private func showHistory() {
        onShowHistory()
    }

    @objc private func showSettings() {
        onShowSettings()
    }

    @objc private func quit() {
        onQuit()
    }
}
