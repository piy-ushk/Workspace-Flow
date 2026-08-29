import Cocoa
import OSLog

// MARK: - Capture result
struct CaptureResult {
    let apps: [RunningAppInfo]
    let windows: [DiscoveredWindow]
    let displays: [DisplaySnapshotData]
    let suggestedName: String
}

struct DisplaySnapshotData {
    let identifier: String
    let name: String
    let frame: CGRect
    let isPrimary: Bool
}

// MARK: - Service
final class WorkspaceCaptureService {
    private let logger   = Logger.capture
    private let windowDiscovery = WindowDiscoveryService()
    private let runningApps     = RunningAppsService()

    func captureCurrentLayout() -> CaptureResult {
        let apps     = runningApps.fetchRunningApps()
        let windows  = windowDiscovery.discoverWindows(for: apps)
        let displays = captureDisplays()
        let suggested = suggestName(for: apps)
        logger.info("Captured \(apps.count) apps, \(windows.count) windows, \(displays.count) displays")
        return CaptureResult(apps: apps, windows: windows, displays: displays, suggestedName: suggested)
    }

    // MARK: Display snapshot
    func captureDisplays() -> [DisplaySnapshotData] {
        NSScreen.screens.map { screen in
            DisplaySnapshotData(
                identifier: displayIdentifier(for: screen),
                name: screen.localizedName,
                frame: screen.frame,
                isPrimary: screen == NSScreen.main
            )
        }
    }

    func displayIdentifier(for screen: NSScreen) -> String {
        if let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
            return "\(num)"
        }
        return screen.localizedName
    }

    // MARK: Name suggestion
    func suggestName(for apps: [RunningAppInfo]) -> String {
        let ids = Set(apps.map(\.bundleIdentifier))
        let hasCode   = ids.contains("com.microsoft.VSCode") || ids.contains("com.apple.dt.Xcode") || ids.contains("com.jetbrains.intellij")
        let hasTerm   = ids.contains("com.apple.Terminal") || ids.contains("com.googlecode.iterm2")
        let hasZoom   = ids.contains("us.zoom.xos") || ids.contains("com.microsoft.teams2") || ids.contains("com.apple.FaceTime")
        let hasCal    = ids.contains("com.apple.iCal")
        let hasSafari = ids.contains("com.apple.Safari") || ids.contains("org.mozilla.firefox") || ids.contains("com.google.Chrome")
        let hasNotes  = ids.contains("com.apple.Notes") || ids.contains("com.apple.iWork.Pages")
        let hasDesign = ids.contains("com.figma.Desktop") || ids.contains("com.adobe.Photoshop") || ids.contains("com.adobe.illustrator")

        if hasCode && hasTerm  { return "Coding" }
        if hasCode             { return "Coding" }
        if hasZoom && hasCal   { return "Meeting" }
        if hasZoom             { return "Meeting" }
        if hasSafari && hasNotes { return "Research" }
        if hasNotes            { return "Writing" }
        if hasDesign           { return "Design" }
        if hasSafari           { return "Research" }
        return "My Workspace"
    }
}
