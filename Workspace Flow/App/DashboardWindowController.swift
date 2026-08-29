import AppKit
import SwiftUI
import SwiftData

@MainActor
final class DashboardWindowController: NSWindowController {
    static let shared = DashboardWindowController()
    
    private var appState: AppState?
    private var modelContext: ModelContext?
    
    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DeskFlow"
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.isReleasedWhenClosed = false
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(appState: AppState, modelContainer: ModelContainer) {
        self.appState = appState
        self.modelContext = ModelContext(modelContainer)
    }
    
    func showWindow() {
        guard let appState = appState, let modelContext = modelContext else { return }
        
        let rootView = Group {
            if appState.showOnboarding {
                OnboardingView()
                    .frame(minWidth: 560, minHeight: 480)
            } else {
                WorkspaceDashboardView()
                    .frame(minWidth: 800, minHeight: 560)
            }
        }
        .environment(appState)
        .modelContext(modelContext)
        
        window?.contentView = NSHostingView(rootView: rootView)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
