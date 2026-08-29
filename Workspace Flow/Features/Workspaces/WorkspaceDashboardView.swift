import SwiftUI
import SwiftData

struct WorkspaceDashboardView: View {
    @Environment(AppState.self) var appState
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Workspace.sortOrder) var workspaces: [Workspace]
    @Query(sort: \ActivityEvent.timestamp, order: .reverse) var events: [ActivityEvent]

    @State private var showDeleteAlert    = false
    @State private var workspaceToDelete: Workspace? = nil
    @State private var isCapturing        = false
    @State private var searchText         = ""

    var filtered: [Workspace] {
        searchText.isEmpty ? workspaces
            : workspaces.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        @Bindable var state = appState

        NavigationSplitView {
            // MARK: Sidebar
            List(selection: $state.selectedSidebar) {
                Section {
                    ForEach(SidebarItem.allCases, id: \.self) { item in
                        Label(item.rawValue, systemImage: item.icon)
                            .tag(item)
                            .badge(item == .activity ? events.count > 0 ? events.count : 0 : 0)
                    }
                }

                if !workspaces.isEmpty {
                    Section("Workspaces") {
                        ForEach(workspaces) { ws in
                            HStack(spacing: 8) {
                                ColorPill(hex: ws.colorHex, size: 8)
                                Image(systemName: ws.iconName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: ws.colorHex))
                                Text(ws.name)
                                    .font(.system(size: 13))
                                Spacer()
                                if let sc = ws.keyboardShortcut {
                                    Text(sc)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .tag(SidebarItem.workspaces)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 200)
            .toolbar(removing: .sidebarToggle)

        } detail: {
            // MARK: Detail area
            switch appState.selectedSidebar {
            case .workspaces: workspacesContent
            case .activity:   ActivityView()
            case .settings:   SettingsView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $state.showWorkspaceEditor) {
            WorkspaceEditorView(workspace: appState.editingWorkspace)
                .frame(minWidth: 600, minHeight: 500)
        }
        .alert("Delete Workspace?", isPresented: $showDeleteAlert, presenting: workspaceToDelete) { ws in
            Button("Delete", role: .destructive) { delete(ws) }
            Button("Cancel", role: .cancel) { }
        } message: { ws in
            Text("\"\(ws.name)\" will be permanently removed.")
        }
        .overlay(alignment: .bottom) {
            if appState.showRestoreHUD, let result = appState.lastRestoreResult {
                RestoreHUDView(result: result)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, WFSpacing.xl)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.showRestoreHUD)
    }

    // MARK: Workspaces content
    private var workspacesContent: some View {
        Group {
            if workspaces.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: WFSpacing.xl) {
                        // Search + toolbar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search workspaces…", text: $searchText)
                                .textFieldStyle(.plain)
                            if !searchText.isEmpty {
                                Button { searchText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(WFSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )

                        // Cards grid
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 280, maximum: 360), spacing: WFSpacing.lg)],
                            spacing: WFSpacing.lg
                        ) {
                            ForEach(filtered) { workspace in
                                WorkspaceCardView(
                                    workspace: workspace,
                                    onRestore: { restore(workspace) },
                                    onEdit:    { appState.presentEditor(for: workspace) },
                                    onDelete:  { workspaceToDelete = workspace; showDeleteAlert = true },
                                    onDuplicate: { duplicate(workspace) }
                                )
                            }
                        }
                    }
                    .padding(WFSpacing.xl)
                }
            }
        }
        .navigationTitle("Workspaces")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isCapturing = true
                    appState.presentEditor(for: nil)
                    isCapturing = false
                } label: {
                    Label("Save Workspace", systemImage: "plus")
                }
                .disabled(isCapturing)
            }

            ToolbarItem {
                Button {
                    appState.permissionService.checkPermission()
                } label: {
                    Label(
                        appState.permissionService.isGranted ? "Accessibility: Granted" : "Accessibility: Denied",
                        systemImage: appState.permissionService.isGranted ? "checkmark.shield.fill" : "exclamationmark.shield.fill"
                    )
                }
                .foregroundStyle(appState.permissionService.isGranted ? Color(hex: "#34C759") : Color(hex: "#FF9500"))
                .help(appState.permissionService.isGranted
                      ? "Accessibility permission granted"
                      : "Click to open Accessibility settings")
            }
        }
    }

    private var emptyState: some View {
        WFEmptyState(
            icon: "rectangle.3.group",
            title: "Your Mac, organized around how you work.",
            subtitle: "Save your current app layout as a named workspace — then restore it anytime in one click.",
            action: { appState.presentEditor(for: nil) },
            actionLabel: "Save Current Workspace"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Actions
    private func restore(_ workspace: Workspace) {
        Task {
            let result = await appState.restoreService.restore(workspace: workspace)
            workspace.lastUsedAt = Date()
            try? modelContext.save()
            appState.activityLog.logRestore(result: result, workspace: workspace, in: modelContext)
            appState.showHUD(result: result)
        }
    }

    private func delete(_ workspace: Workspace) {
        appState.shortcutService.unregister(shortcut: workspace.keyboardShortcut ?? "")
        modelContext.delete(workspace)
        try? modelContext.save()
    }

    private func duplicate(_ workspace: Workspace) {
        let copy = Workspace(name: "\(workspace.name) Copy",
                             iconName: workspace.iconName,
                             colorHex: workspace.colorHex,
                             sortOrder: workspace.sortOrder + 1)
        copy.cleanMode = workspace.cleanMode
        for app in workspace.apps {
            let a = WorkspaceApp(bundleIdentifier: app.bundleIdentifier, displayName: app.displayName)
            a.launchIfMissing = app.launchIfMissing
            copy.apps.append(a)
        }
        modelContext.insert(copy)
        try? modelContext.save()
    }
}

#Preview {
    WorkspaceDashboardView()
        .environment(AppState())
        .modelContainer(for: [Workspace.self, ActivityEvent.self], inMemory: true)
}
