import SwiftUI
import Carbon

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var isRecordingShortcut = false

    var body: some View {
        Form {
            Section {
                Text("ClipVault keeps a history of everything you copy. Press the global shortcut to quickly access and paste previous items.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }

            Section("General") {
                HStack {
                    Text("Max History Items")
                    Spacer()
                    Stepper(
                        value: $settingsManager.maxRecords,
                        in: Constants.minMaxRecords...Constants.maxMaxRecords,
                        step: 10
                    ) {
                        Text("\(settingsManager.maxRecords)")
                            .monospacedDigit()
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }

            Section("Shortcut") {
                HStack {
                    Text("Global Hotkey")
                    Spacer()
                    Button(action: {
                        isRecordingShortcut.toggle()
                    }) {
                        Text(isRecordingShortcut ? "Press keys…" : settingsManager.hotkeyDisplayString)
                            .frame(minWidth: 80)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isRecordingShortcut ? Color.accentColor : Color.secondary.opacity(0.3))
                    )
                    .onKeyboardShortcut(isRecording: $isRecordingShortcut, settingsManager: settingsManager)
                }

                Button("Reset to Default (^V)") {
                    settingsManager.hotkeyKeyCode = Constants.defaultHotkeyKeyCode
                    settingsManager.hotkeyModifiers = Constants.defaultHotkeyModifiers
                }
                .font(.system(size: 11))
            }

            Section("About") {
                HStack {
                    Text("ClipVault")
                    Spacer()
                    Text("Version 1.2")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Developer")
                    Spacer()
                    Text("Joey <275980464@qq.com>")
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 340)
    }
}

// Shortcut recording modifier
struct ShortcutRecorderModifier: ViewModifier {
    @Binding var isRecording: Bool
    let settingsManager: SettingsManager

    func body(content: Content) -> some View {
        content
            .background(
                ShortcutRecorderRepresentable(isRecording: $isRecording, settingsManager: settingsManager)
                    .frame(width: 0, height: 0)
            )
    }
}

struct ShortcutRecorderRepresentable: NSViewRepresentable {
    @Binding var isRecording: Bool
    let settingsManager: SettingsManager

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.onKeyRecorded = { keyCode, modifiers in
            settingsManager.hotkeyKeyCode = UInt32(keyCode)
            settingsManager.hotkeyModifiers = modifiers
            isRecording = false
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.isRecordingActive = isRecording
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        } else {
            // If we are still first responder, resign it
            if nsView.window?.firstResponder === nsView {
                nsView.window?.makeFirstResponder(nil)
            }
        }
    }
}

class ShortcutRecorderNSView: NSView {
    var isRecordingActive = false
    var onKeyRecorded: ((UInt16, UInt32) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isRecordingActive else {
            super.keyDown(with: event)
            return
        }

        let carbonModifiers = carbonModifiersFromCocoa(event.modifierFlags)
        guard carbonModifiers != 0 else { return } // Require at least one modifier

        onKeyRecorded?(event.keyCode, carbonModifiers)
    }

    private func carbonModifiersFromCocoa(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        return carbon
    }
}

extension View {
    func onKeyboardShortcut(isRecording: Binding<Bool>, settingsManager: SettingsManager) -> some View {
        modifier(ShortcutRecorderModifier(isRecording: isRecording, settingsManager: settingsManager))
    }
}
