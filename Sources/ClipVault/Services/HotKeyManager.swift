import Carbon
import AppKit

// Global C function for Carbon event handler
private func hotKeyEventHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData = userData else { return OSStatus(eventNotHandledErr) }
    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async {
        manager.handleHotKey()
    }
    return noErr
}

class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private let callback: () -> Void
    private let settingsManager: SettingsManager
    private var eventHandlerRef: EventHandlerRef?

    init(settingsManager: SettingsManager, callback: @escaping () -> Void) {
        self.settingsManager = settingsManager
        self.callback = callback
        register()
    }

    func register() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        let hotKeyID = EventHotKeyID(signature: OSType(0x4356_4C54), // "CVLT"
                                      id: 1)

        let keyCode = settingsManager.hotkeyKeyCode
        let modifiers = settingsManager.hotkeyModifiers

        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    func reregister() {
        unregister()
        register()
    }

    func handleHotKey() {
        callback()
    }
}
