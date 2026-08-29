import SwiftUI
import AppKit
import SwiftData
import ApplicationServices

@Observable
final class DockNavigatorViewModel {
    var activeWorkspace: Workspace?
    var searchText: String = ""
    var selectedIndex: Int = 0
    var appStates: [AppStatus] = []
    
    struct AppStatus: Identifiable, Equatable {
        let id = UUID()
        let workspaceApp: WorkspaceApp
        var isRunning: Bool
        var windowTitle: String?
        var runningApp: NSRunningApplication?
    }
    
    var filteredApps: [AppStatus] {
        if searchText.isEmpty {
            return appStates
        }
        return appStates.filter {
            $0.workspaceApp.displayName.localizedCaseInsensitiveContains(searchText) ||
            ($0.windowTitle?.localizedCaseInsensitiveContains(searchText) == true)
        }
    }
    
    func refresh(with workspace: Workspace?) {
        self.activeWorkspace = workspace
        self.searchText = ""
        self.selectedIndex = 0
        self.appStates = []
        
        guard let workspace = workspace else { return }
        
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in workspace.apps {
            let runningApp = runningApps.first(where: { $0.bundleIdentifier == app.bundleIdentifier })
            var windowTitle: String? = nil
            
            if let rApp = runningApp {
                // If we have AX permissions, try to get the frontmost window title
                let axApp = AXUIElementCreateApplication(rApp.processIdentifier)
                var focusedWindow: CFTypeRef?
                if AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success {
                    let window = focusedWindow as! AXUIElement
                    var titleRef: CFTypeRef?
                    if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
                       let title = titleRef as? String, !title.isEmpty {
                        windowTitle = title
                    }
                }
            }
            
            appStates.append(AppStatus(
                workspaceApp: app,
                isRunning: runningApp != nil,
                windowTitle: windowTitle,
                runningApp: runningApp
            ))
        }
    }
    
    func activate(status: AppStatus) -> Bool {
        if let running = status.runningApp {
            // App is running, bring it forward
            running.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            return true
        } else {
            // App is not running, launch it
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: status.workspaceApp.bundleIdentifier) {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
                return true
            }
        }
        return false
    }
    
    func openAllApps() {
        for status in appStates where !status.isRunning {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: status.workspaceApp.bundleIdentifier) {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = false
                NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
            }
        }
        // Refresh states after launching
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refresh(with: self?.activeWorkspace)
        }
    }
}
