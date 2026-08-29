import SwiftUI
import SwiftData
import AppKit

@MainActor
final class DockNavigatorManager {
    static let shared = DockNavigatorManager()
    
    private var panel: DockNavigatorPanel?
    private var modelContext: ModelContext?
    private var appState: AppState?
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowNavigator),
            name: .showDockNavigator,
            object: nil
        )
    }
    
    func setup(appState: AppState, modelContainer: ModelContainer) {
        self.appState = appState
        self.modelContext = ModelContext(modelContainer)
        
        // Also register the shortcut
        appState.shortcutService.register(shortcut: "⌥Space") { [weak self] in
            self?.showNavigator()
        }
    }
    
    @objc private func handleShowNavigator() {
        let mouseLocation = NSEvent.mouseLocation
        showNavigator(at: mouseLocation)
    }
    
    func showNavigator(at point: NSPoint? = nil) {
        guard let appState = appState, let modelContext = modelContext else { return }
        
        if panel == nil {
            let p = DockNavigatorPanel()
            p.isReleasedWhenClosed = false
            self.panel = p
        }
        
        guard let panel = panel else { return }
        
        // Get active workspace
        var activeWorkspace: Workspace?
        if let idString = appState.activeWorkspaceId, let uuid = UUID(uuidString: idString) {
            let descriptor = FetchDescriptor<Workspace>()
            if let allWorkspaces = try? modelContext.fetch(descriptor) {
                activeWorkspace = allWorkspaces.first(where: { $0.id == uuid })
            }
        }
        
        let overlayView = DockNavigatorOverlay(
            initialWorkspace: activeWorkspace,
            onDismiss: { [weak self] in
                self?.hideNavigator()
            },
            onEditWorkspace: { [weak self] workspace in
                self?.hideNavigator()
                self?.appState?.presentEditor(for: workspace)
                self?.openMainWindow()
            },
            onOpenDeskFlow: { [weak self] in
                self?.hideNavigator()
                self?.openMainWindow()
            },
            onChangeWorkspace: {
                // WorkspacePickerView handles the update directly via AppState/onSelect, but we might want to do something here
            }
        )
        .environment(appState)
        .modelContext(modelContext)
        
        let hostingView = NSHostingView(rootView: overlayView)
        // Ensure the hosting view gets the workspace from DB before presenting
        
        panel.contentView = hostingView
        
        // Position panel at mouse location (which is roughly where the Dock icon is)
        if let pt = point ?? NSEvent.mouseLocation as NSPoint? {
            let panelSize = panel.frame.size
            let x = max(0, min(pt.x - (panelSize.width / 2), (NSScreen.main?.frame.width ?? 0) - panelSize.width))
            // Position above the dock (giving a little padding)
            let y = pt.y + 20 
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            panel.center()
        }
        
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Push the active workspace down to the overlay
        if let host = panel.contentView as? NSHostingView<ModifiedContent<ModifiedContent<DockNavigatorOverlay, _EnvironmentKeyWritingModifier<AppState>>, _EnvironmentKeyWritingModifier<ModelContext>>> {
             // We can't easily call refresh() on overlay since it's a struct and we don't hold the reference to it easily
             // Let's just have the overlay use `.onAppear { refresh(...) }` by fetching it itself, or we inject it
        }
    }
    
    func hideNavigator() {
        panel?.orderOut(nil)
    }
    
    private func openMainWindow() {
        DashboardWindowController.shared.showWindow()
    }
}
