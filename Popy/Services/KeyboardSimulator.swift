import AppKit
import Carbon.HIToolbox

/// Simulates keyboard events to paste into the frontmost application.
/// Requires Accessibility permissions (System Preferences → Privacy → Accessibility).
enum KeyboardSimulator {

    /// Simulate Cmd+V (paste) into whatever app is currently focused.
    /// The caller should have already placed the desired text on NSPasteboard.
    static func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Virtual key code for "V" is 0x09 (kVK_ANSI_V)
        let keyCode: CGKeyCode = CGKeyCode(kVK_ANSI_V)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            print("Popy: Failed to create CGEvent for paste simulation.")
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    /// Check if we have Accessibility permissions (needed for CGEvent posting).
    static var hasAccessibilityPermission: Bool {
        return AXIsProcessTrusted()
    }

    /// Prompt the user to grant Accessibility permissions.
    /// Opens System Preferences to the right pane.
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
