import AppKit

class HistoryPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Constants.panelWidth, height: Constants.panelHeight),
            styleMask: [.titled, .closable, .nonactivatingPanel, .hudWindow, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        title = "ClipVault"
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .utilityWindow
    }
}
