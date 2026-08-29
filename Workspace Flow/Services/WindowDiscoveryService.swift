import Cocoa
import ApplicationServices
import OSLog

// MARK: - Discovered Window
struct DiscoveredWindow: Identifiable {
    let id = UUID()
    let bundleIdentifier: String
    let appName: String
    let pid: pid_t
    let windowIndex: Int
    let title: String?
    let frame: CGRect
    let isMinimized: Bool
    let isRestorable: Bool
    let axWindow: AXUIElement
}

// MARK: - Service
final class WindowDiscoveryService {
    private let logger = Logger.windows

    /// Discover all accessible windows for the given running apps.
    func discoverWindows(for apps: [RunningAppInfo]) -> [DiscoveredWindow] {
        apps.flatMap { appInfo in
            windowsForApp(pid: appInfo.pid,
                          bundleID: appInfo.bundleIdentifier,
                          appName: appInfo.displayName)
        }
    }

    // MARK: Private
    private func windowsForApp(pid: pid_t, bundleID: String, appName: String) -> [DiscoveredWindow] {
        let axApp = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windowsArray = windowsRef as? [AXUIElement] else {
            logger.debug("No AX windows for \(bundleID) (\(pid))")
            return []
        }

        return windowsArray.enumerated().compactMap { index, axWindow in
            makeWindow(axWindow: axWindow,
                       bundleID: bundleID,
                       appName: appName,
                       pid: pid,
                       index: index)
        }
    }

    private func makeWindow(
        axWindow: AXUIElement,
        bundleID: String,
        appName: String,
        pid: pid_t,
        index: Int
    ) -> DiscoveredWindow? {
        // Skip sheets / drawers
        var subroleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axWindow, kAXSubroleAttribute as CFString, &subroleRef)
        let subrole = subroleRef as? String ?? ""
        if subrole == kAXDialogSubrole || subrole == "AXSheet" || subrole == "AXDrawer" {
            return nil
        }

        // Title
        var titleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef)
        let title = titleRef as? String

        // Minimized state
        var minRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axWindow, kAXMinimizedAttribute as CFString, &minRef)
        let isMinimized = (minRef as? Bool) ?? false

        // Frame (position + size)
        var posRef: CFTypeRef?
        var szRef: CFTypeRef?
        let posOK = AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &posRef)
        let szOK  = AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &szRef)

        var frame = CGRect.zero
        var isRestorable = false

        if posOK == .success, szOK == .success,
           let pv = posRef, let sv = szRef {
            var pt = CGPoint.zero
            var sz = CGSize.zero
            // swiftlint:disable force_cast
            AXValueGetValue(pv as! AXValue, .cgPoint, &pt)
            AXValueGetValue(sv as! AXValue, .cgSize, &sz)
            // swiftlint:enable force_cast
            frame = CGRect(origin: pt, size: sz)

            var settable: DarwinBoolean = false
            AXUIElementIsAttributeSettable(axWindow, kAXPositionAttribute as CFString, &settable)
            isRestorable = settable.boolValue && frame != .zero
        }

        return DiscoveredWindow(
            bundleIdentifier: bundleID,
            appName: appName,
            pid: pid,
            windowIndex: index,
            title: title,
            frame: frame,
            isMinimized: isMinimized,
            isRestorable: isRestorable,
            axWindow: axWindow
        )
    }
}
