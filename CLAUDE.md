# ClipVault

macOS menu bar clipboard manager app. Monitors the system clipboard, stores history (text, images, rich text, files), and lets the user paste any previous item via a global hotkey or menu bar icon.

## Tech Stack

- **Language**: Swift 5.9, macOS 13+
- **UI**: SwiftUI views hosted in AppKit containers (NSPanel, NSStatusItem)
- **Build**: Swift Package Manager (`swift build`) + `scripts/bundle.sh` to produce `.app`
- **No Dock icon**: `LSUIElement = true`

## Project Structure

```
Sources/ClipVault/
  main.swift                  # NSApplication bootstrap
  App/                        # AppDelegate, Constants
  Models/                     # ClipboardItem data model
  Services/                   # ClipboardMonitor, ClipboardStore, HotKeyManager, PasteService, SettingsManager
  UI/                         # StatusBar, HistoryPanel, SwiftUI views, Settings window
Resources/Info.plist
scripts/bundle.sh
```

## Key Design Decisions

- **Global hotkey**: Carbon `RegisterEventHotKey` (no Accessibility permission needed for registration)
- **Clipboard monitoring**: `NSPasteboard.general.changeCount` polling at 0.5s interval
- **Paste simulation**: `CGEvent` Cmd+V (requires Accessibility permission)
- **Storage**: JSON index + binary blob files in `~/Library/Application Support/ClipVault/`
- **Self-referential write detection**: boolean flag on ClipboardStore to skip internal clipboard changes

## Build & Run

```bash
swift build              # debug build
swift run                # run directly
./scripts/bundle.sh      # release build → build/ClipVault.app
open build/ClipVault.app # launch the app
```
