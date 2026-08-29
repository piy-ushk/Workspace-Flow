import Cocoa
import ApplicationServices
import OSLog

/// Moves, resizes, hides, minimizes windows via the Accessibility API.
final class WindowControlService {
    private let logger = Logger.windows

    @discardableResult
    func setFrame(_ frame: CGRect, for axWindow: AXUIElement) -> Bool {
        var position = frame.origin
        var size     = frame.size

        guard let posVal = AXValueCreate(.cgPoint, &position),
              let szVal  = AXValueCreate(.cgSize, &size) else {
            logger.warning("AXValueCreate failed")
            return false
        }

        let p = AXUIElementSetAttributeValue(axWindow, kAXPositionAttribute as CFString, posVal)
        let s = AXUIElementSetAttributeValue(axWindow, kAXSizeAttribute as CFString, szVal)

        if p != .success || s != .success {
            logger.warning("setFrame failed — pos:\(p.rawValue) size:\(s.rawValue)")
        }
        return p == .success && s == .success
    }

    func minimize(_ axWindow: AXUIElement) {
        AXUIElementSetAttributeValue(axWindow, kAXMinimizedAttribute as CFString, true as CFTypeRef)
    }

    func unminimize(_ axWindow: AXUIElement) {
        AXUIElementSetAttributeValue(axWindow, kAXMinimizedAttribute as CFString, false as CFTypeRef)
    }

    func raise(_ axWindow: AXUIElement) {
        AXUIElementSetAttributeValue(axWindow, kAXMainAttribute as CFString, true as CFTypeRef)
        AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
    }

    func hideApp(pid: pid_t) {
        let axApp = AXUIElementCreateApplication(pid)
        AXUIElementSetAttributeValue(axApp, kAXHiddenAttribute as CFString, true as CFTypeRef)
    }

    func showApp(pid: pid_t) {
        let axApp = AXUIElementCreateApplication(pid)
        AXUIElementSetAttributeValue(axApp, kAXHiddenAttribute as CFString, false as CFTypeRef)
    }

    func minimizeAllWindows(pid: pid_t) {
        let axApp = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else { return }
        for win in windows {
            minimize(win)
        }
    }
}
