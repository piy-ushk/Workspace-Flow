import Cocoa
import OSLog

// MARK: - Running App Info
struct RunningAppInfo: Identifiable {
    let id = UUID()
    let bundleIdentifier: String
    let displayName: String
    let pid: pid_t
    let icon: NSImage?
    let app: NSRunningApplication
}

// MARK: - App Error
enum AppError: LocalizedError {
    case appNotFound(String)
    case windowNotAccessible(String)
    case permissionDenied
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .appNotFound(let id):           return "Application not found: \(id)"
        case .windowNotAccessible(let name): return "Window not accessible: \(name)"
        case .permissionDenied:              return "Accessibility permission is required."
        case .launchFailed(let name):        return "Could not launch \(name)."
        }
    }
}

// MARK: - Service
final class RunningAppsService {
    private let logger = Logger.apps

    private static var selfBundleID: String {
        Bundle.main.bundleIdentifier ?? "personal.Workspace-Flow"
    }

    /// Enumerate regular (non-background) apps, excluding Workspace Flow itself.
    func fetchRunningApps() -> [RunningAppInfo] {
        NSWorkspace.shared.runningApplications
            .filter {
                $0.activationPolicy == .regular &&
                $0.bundleIdentifier != Self.selfBundleID &&
                $0.bundleIdentifier != nil
            }
            .compactMap { app in
                guard let bundleID = app.bundleIdentifier else { return nil }
                return RunningAppInfo(
                    bundleIdentifier: bundleID,
                    displayName: app.localizedName ?? "Unknown",
                    pid: app.processIdentifier,
                    icon: app.icon,
                    app: app
                )
            }
    }

    func isRunning(bundleIdentifier: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleIdentifier
        }
    }

    /// Launch an app by bundle identifier asynchronously.
    func launchApp(bundleIdentifier: String) async throws {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            throw AppError.appNotFound(bundleIdentifier)
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        do {
            try await NSWorkspace.shared.openApplication(at: url, configuration: config)
            logger.info("Launched: \(bundleIdentifier)")
        } catch {
            logger.error("Launch failed for \(bundleIdentifier): \(error)")
            throw AppError.launchFailed(bundleIdentifier)
        }
    }

    /// Wait until the app appears in the running apps list (with timeout).
    func waitForApp(bundleIdentifier: String, timeout: TimeInterval = 8) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if isRunning(bundleIdentifier: bundleIdentifier) { return true }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        return false
    }
}
