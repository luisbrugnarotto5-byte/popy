import Foundation
import ServiceManagement

/// Manages "Launch at Login" functionality.
/// Uses SMAppService on macOS 13+, falls back to a no-op on older systems.
final class LoginItemManager {

    static let shared = LoginItemManager()
    private let userDefaultsKey = "launchAtLogin"

    private init() {}

    /// Whether launch-at-login is currently enabled.
    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return UserDefaults.standard.bool(forKey: userDefaultsKey)
        }
    }

    /// Toggle launch-at-login on or off.
    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Popy: Failed to \(enabled ? "register" : "unregister") login item: \(error)")
            }
        } else {
            // On macOS 12, just persist the preference. 
            // Full launch-agent support would require a helper bundle which is out of scope.
            UserDefaults.standard.set(enabled, forKey: userDefaultsKey)
            print("Popy: Launch at Login preference saved (requires macOS 13+ for automatic registration).")
        }
    }
}
