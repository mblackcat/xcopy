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
scripts/bundle.sh             # release build → .app bundle
release.sh                    # one-command build + Gitee Release upload
.release.env                  # Gitee credentials (git-ignored)
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

## Release & Upload

Use `release.sh` to build, package, and optionally upload to Gitee Releases.

```bash
./release.sh                        # build + zip (current version from Info.plist)
./release.sh -v 1.2                 # build + zip with specified version
./release.sh --upload               # build + zip + upload to Gitee
./release.sh -v 1.2 --upload        # specify version + upload
```

### Gitee Upload Configuration

Create `.release.env` in the project root (already in `.gitignore`):

```
GITEE_TOKEN=your_personal_access_token
GITEE_OWNER=lizhi-studio
GITEE_REPO=xcopy
```

The script will:
1. Update `Info.plist` version if `-v` is specified
2. Run `scripts/bundle.sh` for release build
3. Package `.app` into a zip (`ClipVault-v1.2-macOS.zip`)
4. Create a Git tag, push to Gitee, create a Release, and upload the zip as an attachment

### Gitee Repository

- **Repo**: https://gitee.com/lizhi-studio/xcopy
- **Releases**: https://gitee.com/lizhi-studio/xcopy/releases
