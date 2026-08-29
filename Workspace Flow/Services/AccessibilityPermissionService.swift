import Cocoa
import ApplicationServices
import OSLog

/// Manages Accessibility permission status and guidance.
@Observable
final class AccessibilityPermissionService {
    private let logger = Logger.permission

    var isGranted: Bool = false

    init() {
        checkPermission()
    }

    func checkPermission() {
        isGranted = AXIsProcessTrusted()
        logger.info("Accessibility permission: \(self.isGranted ? "granted" : "denied")")
    }

    /// Prompts the system dialog and opens System Settings.
    func requestPermission() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
        // Always open System Settings for reliability
        openSystemSettings()
    }

    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Poll — call from a Timer to detect when the user grants permission.
    @discardableResult
    func poll() -> Bool {
        checkPermission()
        return isGranted
    }
}
