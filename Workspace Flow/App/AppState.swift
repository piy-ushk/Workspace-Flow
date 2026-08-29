import SwiftUI
import OSLog

// MARK: - Navigation destination
enum SidebarItem: String, CaseIterable, Hashable {
    case workspaces   = "Workspaces"
    case activity     = "Activity"
    case settings     = "Settings"

    var icon: String {
        switch self {
        case .workspaces: "rectangle.3.group.fill"
        case .activity:   "clock.arrow.circlepath"
        case .settings:   "gearshape.fill"
        }
    }
}

// MARK: - App State
@Observable
final class AppState {
    // Navigation
    var selectedSidebar: SidebarItem = .workspaces
    var showOnboarding: Bool         = false
    var showWorkspaceEditor: Bool    = false
    var editingWorkspace: Workspace? = nil
    var showSwitcherOverlay: Bool    = false

    // HUD
    var showRestoreHUD: Bool     = false
    var lastRestoreResult: RestoreResult? = nil

    // Services (shared across the app)
    let permissionService = AccessibilityPermissionService()
    let restoreService    = WorkspaceRestoreService()
    let shortcutService   = ShortcutService()
    let activityLog       = ActivityLogService()
    let captureService    = WorkspaceCaptureService()

    init() {
        showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingComplete")
        permissionService.checkPermission()
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        showOnboarding = false
    }

    func presentEditor(for workspace: Workspace? = nil) {
        editingWorkspace  = workspace
        showWorkspaceEditor = true
    }

    func showHUD(result: RestoreResult) {
        lastRestoreResult = result
        showRestoreHUD = true
        // Auto-dismiss after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showRestoreHUD = false
        }
    }
}
