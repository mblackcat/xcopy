import Foundation
import AppKit

class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int
    private let store: ClipboardStore

    init(store: ClipboardStore) {
        self.store = store
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: Constants.clipboardPollInterval, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Skip internally-caused clipboard changes
        if store.isInternalWrite {
            store.isInternalWrite = false
            return
        }

        store.addItem(from: pasteboard)
    }
}
