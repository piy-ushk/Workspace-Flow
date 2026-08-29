import Cocoa
import OSLog

/// Orchestrates the full workspace restore flow:
/// launch missing apps → discover windows → match → move/resize → clean mode.
@Observable
final class WorkspaceRestoreService {
    private let logger         = Logger.restore
    private let windowDiscovery = WindowDiscoveryService()
    private let windowControl   = WindowControlService()
    private let runningApps     = RunningAppsService()
    private let displayMapping  = DisplayMappingService()

    var isRestoring: Bool = false
    var lastResult: RestoreResult?

    // MARK: - Public

    func restore(workspace: Workspace) async -> RestoreResult {
        isRestoring = true
        defer { isRestoring = false }

        logger.info("Restoring workspace: \"\(workspace.name)\"")

        var windowsRestored     = 0
        var windowsFailed       = 0
        var appsLaunched        = 0
        var appsAlreadyRunning  = 0
        var warnings: [String]  = []

        // 1. Launch missing apps
        for savedApp in workspace.apps where savedApp.launchIfMissing {
            if runningApps.isRunning(bundleIdentifier: savedApp.bundleIdentifier) {
                appsAlreadyRunning += 1
                logger.debug("\(savedApp.displayName) already running")
            } else {
                do {
                    try await runningApps.launchApp(bundleIdentifier: savedApp.bundleIdentifier)
                    let appeared = await runningApps.waitForApp(bundleIdentifier: savedApp.bundleIdentifier, timeout: 8)
                    if appeared {
                        appsLaunched += 1
                        // Extra settle time for windows to appear
                        try? await Task.sleep(nanoseconds: 800_000_000)
                    } else {
                        warnings.append("\(savedApp.displayName) launched but windows not yet ready")
                    }
                } catch {
                    warnings.append("Could not launch \(savedApp.displayName): \(error.localizedDescription)")
                    logger.warning("Launch failed for \(savedApp.bundleIdentifier): \(error)")
                }
            }
        }

        // 2. Discover current windows
        let currentApps    = runningApps.fetchRunningApps()
        let currentWindows = windowDiscovery.discoverWindows(for: currentApps)
        let currentScreens = displayMapping.currentDisplays()

        // 3. Restore window frames
        for savedWindow in workspace.windows {
            guard savedWindow.isRestorable else { continue }

            let candidates = currentWindows.filter { $0.bundleIdentifier == savedWindow.bundleIdentifier }
            let target = matchWindow(savedWindow: savedWindow, candidates: candidates)

            guard let window = target else {
                warnings.append("Window not found for \(savedWindow.bundleIdentifier)")
                windowsFailed += 1
                continue
            }

            guard window.isRestorable else {
                warnings.append("\(window.appName) windows are not resizable via Accessibility")
                windowsFailed += 1
                continue
            }

            let savedDisplay = workspace.displays.first { $0.identifier == savedWindow.displayIdentifier }
            let targetFrame  = displayMapping.mapFrame(savedWindow.frame,
                                                       fromDisplay: savedDisplay,
                                                       toCurrentDisplays: currentScreens)

            if window.isMinimized {
                windowControl.unminimize(window.axWindow)
                try? await Task.sleep(nanoseconds: 200_000_000)
            }

            if windowControl.setFrame(targetFrame, for: window.axWindow) {
                windowsRestored += 1
                windowControl.raise(window.axWindow)
            } else {
                windowsFailed += 1
                warnings.append("Could not reposition \(window.appName) window")
            }
        }

        // 4. Apply clean mode
        if workspace.cleanMode != .none {
            applyCleanMode(workspace: workspace, currentApps: currentApps)
        }

        // 5. Bring workspace apps forward
        let workspaceBundleIDs = Set(workspace.apps.map(\.bundleIdentifier))
        for app in currentApps where workspaceBundleIDs.contains(app.bundleIdentifier) {
            app.app.activate()
        }

        let result = RestoreResult(
            workspaceName: workspace.name,
            windowsRestored: windowsRestored,
            windowsFailed: windowsFailed,
            appsLaunched: appsLaunched,
            appsAlreadyRunning: appsAlreadyRunning,
            warnings: warnings,
            timestamp: Date()
        )
        lastResult = result
        logger.info("Restore complete — restored:\(windowsRestored) failed:\(windowsFailed) launched:\(appsLaunched)")
        return result
    }

    // MARK: - Clean Current Workspace

    func cleanWorkspace(_ workspace: Workspace) {
        let currentApps = runningApps.fetchRunningApps()
        applyCleanMode(workspace: workspace, currentApps: currentApps)
        logger.info("Cleaned workspace: \(workspace.name)")
    }

    // MARK: - Private

    private func matchWindow(savedWindow: WorkspaceWindow, candidates: [DiscoveredWindow]) -> DiscoveredWindow? {
        // 1. Title match (when title is stored)
        if let savedTitle = savedWindow.windowTitle, !savedTitle.isEmpty {
            if let match = candidates.first(where: { $0.title == savedTitle }) {
                return match
            }
        }
        // 2. Index match
        if candidates.indices.contains(savedWindow.windowIndex) {
            return candidates[savedWindow.windowIndex]
        }
        // 3. Fallback to first
        return candidates.first
    }

    private func applyCleanMode(workspace: Workspace, currentApps: [RunningAppInfo]) {
        let keepIDs = Set(workspace.apps.map(\.bundleIdentifier))
        let others  = currentApps.filter { !keepIDs.contains($0.bundleIdentifier) }

        for app in others {
            switch workspace.cleanMode {
            case .hideOtherApps:
                app.app.hide()
            case .minimizeOtherWindows:
                windowControl.minimizeAllWindows(pid: app.pid)
            case .none:
                break
            }
        }
    }
}
