import SwiftUI
import SwiftData

@main
struct DeskFlowApp: App {
    @State private var appState: AppState
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate



    // SwiftData container for all persistent models
    static let modelContainer: ModelContainer = {
        let schema = Schema([
            Workspace.self,
            WorkspaceApp.self,
            WorkspaceWindow.self,
            DisplaySnapshot.self,
            ActivityEvent.self
        ])
        let config = ModelConfiguration("DeskFlow", schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    init() {
        let state = AppState()
        _appState = State(initialValue: state)
        DockNavigatorManager.shared.setup(appState: state, modelContainer: Self.modelContainer)
    }

    var body: some Scene {
        // MARK: Main Window
        WindowGroup("DeskFlow", id: "main") {
            Group {
                if appState.showOnboarding {
                    OnboardingView()
                        .frame(minWidth: 560, minHeight: 480)
                } else {
                    WorkspaceDashboardView()
                        .frame(minWidth: 800, minHeight: 560)
                }
            }
            .environment(appState)
            .modelContainer(Self.modelContainer)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 960, height: 640)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Save Current Workspace…") {
                    appState.presentEditor(for: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }

        // MARK: Settings Window
        Settings {
            SettingsView()
                .environment(appState)
                .modelContainer(Self.modelContainer)
                .frame(minWidth: 480, minHeight: 400)
        }

        // MARK: Menu Bar Extra
        MenuBarExtra {
            MenuBarContentView()
                .environment(appState)
                .modelContainer(Self.modelContainer)
        } label: {
            Image(systemName: appState.restoreService.isRestoring
                  ? "arrow.clockwise.circle.fill"
                  : "rectangle.3.group.fill")
            .symbolEffect(.bounce, value: appState.restoreService.isRestoring)
        }
        .menuBarExtraStyle(.menu)
    }
}

// MARK: - Menu Bar Content
struct MenuBarContentView: View {
    @Environment(AppState.self) var appState
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Workspace.lastUsedAt, order: .reverse) var workspaces: [Workspace]
    @Query(sort: \ActivityEvent.timestamp, order: .reverse) var recentEvents: [ActivityEvent]

    var body: some View {
        // Status line
        if let ws = mostRecentWorkspace {
            Label("Last: \(ws.name)", systemImage: ws.iconName)
                .foregroundStyle(.secondary)
                .font(.caption)
        }

        Divider()

        // Workspace list
        if workspaces.isEmpty {
            Text("No workspaces saved yet")
                .foregroundStyle(.secondary)
        } else {
            ForEach(workspaces) { workspace in
                workspaceMenuItem(workspace)
            }
        }

        Divider()

        Button("Save Current Workspace…") {
            appState.presentEditor(for: nil)
            openMainWindow()
        }

        Divider()

        Button("Open DeskFlow") { openMainWindow() }
        Button("Settings…") { openSettings() }

        Divider()

        Button("Quit DeskFlow") { NSApp.terminate(nil) }
    }

    @ViewBuilder
    private func workspaceMenuItem(_ workspace: Workspace) -> some View {
        Menu {
            Button("Restore Now") { restore(workspace) }
            Button("Edit…") {
                appState.presentEditor(for: workspace)
                openMainWindow()
            }
        } label: {
            HStack {
                Image(systemName: workspace.iconName)
                    .foregroundStyle(Color(hex: workspace.colorHex))
                Text(workspace.name)
                if let sc = workspace.keyboardShortcut {
                    Spacer()
                    Text(sc).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var mostRecentWorkspace: Workspace? {
        workspaces.first { $0.lastUsedAt != nil }
    }

    private func restore(_ workspace: Workspace) {
        Task {
            let result = await appState.restoreService.restore(workspace: workspace)
            workspace.lastUsedAt = Date()
            try? modelContext.save()
            appState.activityLog.logRestore(result: result, workspace: workspace, in: modelContext)
            appState.setActiveWorkspace(workspace)
        }
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Open the window group
            for window in NSApp.windows {
                window.makeKeyAndOrderFront(nil)
                break
            }
        }
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
