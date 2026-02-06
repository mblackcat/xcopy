import CoreGraphics
import Carbon

enum PasteService {
    static func simulatePaste() {
        // Small delay to ensure pasteboard is updated before simulating paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            performPaste()
        }
    }

    private static func performPaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down: Cmd+V
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true) else { return }
        keyDown.flags = .maskCommand

        // Key up: Cmd+V
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else { return }
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
