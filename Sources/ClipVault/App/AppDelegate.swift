import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var clipboardStore: ClipboardStore!
    private var clipboardMonitor: ClipboardMonitor!
    private var hotKeyManager: HotKeyManager!
    private var historyPanelController: HistoryPanelController!
    private var settingsWindowController: SettingsWindowController!
    private var settingsManager: SettingsManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        checkAccessibilityPermission()

        settingsManager = SettingsManager()
        clipboardStore = ClipboardStore(maxRecords: settingsManager.maxRecords)
        clipboardMonitor = ClipboardMonitor(store: clipboardStore)

        historyPanelController = HistoryPanelController(
            store: clipboardStore,
            settingsManager: settingsManager
        )

        settingsWindowController = SettingsWindowController(settingsManager: settingsManager)

        statusBarController = StatusBarController(
            onShowHistory: { [weak self] in self?.toggleHistoryPanel() },
            onShowSettings: { [weak self] in self?.showSettings() },
            onQuit: { NSApplication.shared.terminate(nil) }
        )

        hotKeyManager = HotKeyManager(settingsManager: settingsManager) { [weak self] in
            self?.toggleHistoryPanel()
        }

        settingsManager.onMaxRecordsChanged = { [weak self] newMax in
            self?.clipboardStore.updateMaxRecords(newMax)
        }

        settingsManager.onHotkeyChanged = { [weak self] in
            self?.hotKeyManager.reregister()
        }

        clipboardMonitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        hotKeyManager.unregister()
    }

    private func toggleHistoryPanel() {
        historyPanelController.toggle()
    }

    private func showSettings() {
        settingsWindowController.showWindow()
    }

    private func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "ClipVault needs Accessibility permission to simulate paste (Cmd+V). Please grant access in System Settings > Privacy & Security > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
