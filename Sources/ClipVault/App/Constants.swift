import Foundation

enum Constants {
    static let appName = "ClipVault"
    static let bundleIdentifier = "com.clipvault.app"

    static let storageDirectoryName = "ClipVault"
    static let indexFileName = "index.json"
    static let blobsDirectoryName = "blobs"

    static let defaultMaxRecords = 100
    static let minMaxRecords = 10
    static let maxMaxRecords = 500

    static let clipboardPollInterval: TimeInterval = 0.5

    static let panelWidth: CGFloat = 340
    static let panelHeight: CGFloat = 480

    static let thumbnailSize: CGFloat = 64

    // UserDefaults keys
    static let maxRecordsKey = "maxRecords"
    static let hotkeyKeyCodeKey = "hotkeyKeyCode"
    static let hotkeyModifiersKey = "hotkeyModifiers"

    // Default hotkey: Control+Command+V (kVK_ANSI_V = 9)
    static let defaultHotkeyKeyCode: UInt32 = 9
    static let defaultHotkeyModifiers: UInt32 = 0x1100 // controlKey | cmdKey
}
