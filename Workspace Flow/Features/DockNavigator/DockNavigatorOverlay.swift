import SwiftUI
import AppKit

// MARK: - Panel Controller
final class DockNavigatorPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 600),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - SwiftUI Overlay
struct DockNavigatorOverlay: View {
    @Environment(AppState.self) var appState
    @State private var viewModel = DockNavigatorViewModel()
    @State private var appeared = false
    @State private var showingPicker = false
    
    var initialWorkspace: Workspace?
    
    var onDismiss: () -> Void
    var onEditWorkspace: (Workspace) -> Void
    var onOpenDeskFlow: () -> Void
    var onChangeWorkspace: () -> Void
    
    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
            
            VStack(spacing: 0) {
                // Header (Workspace Info)
                headerView
                
                Divider()
                
                // App List
                if viewModel.activeWorkspace == nil {
                    VStack {
                        Spacer()
                        Text("No Active Workspace")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Button("Choose Workspace") {
                            onChangeWorkspace()
                        }
                        .padding(.top, WFSpacing.sm)
                        Spacer()
                    }
                } else if showingPicker {
                    workspacePickerView
                } else if viewModel.appStates.isEmpty {
                    VStack {
                        Spacer()
                        Text("No Apps in Workspace")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    appList
                }
                
                Divider()
                
                // Footer
                footerView
            }
        }
        .frame(width: 450, height: 500)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.95)
        .onAppear {
            viewModel.refresh(with: initialWorkspace)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
        .onKeyPress(.escape) { handleKeyDown(53); return .handled }
        .onKeyPress(.downArrow) { handleKeyDown(125); return .handled }
        .onKeyPress(.upArrow) { handleKeyDown(126); return .handled }
        .onKeyPress(.return) { handleKeyDown(36); return .handled }
    }
    
    private var headerView: some View {
        HStack {
            if let workspace = viewModel.activeWorkspace {
                Image(systemName: workspace.iconName)
                    .foregroundStyle(Color(hex: workspace.colorHex))
                Text(workspace.name)
                    .font(.headline)
            } else {
                Text("Dock Navigator")
                    .font(.headline)
            }
            
            Spacer()
            
            Button(showingPicker ? "Cancel" : "Change") {
                withAnimation {
                    showingPicker.toggle()
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
        }
        .padding(WFSpacing.md)
        .background(Color.black.opacity(0.1))
    }
    
    private var workspacePickerView: some View {
        WorkspacePickerView(
            activeWorkspaceId: viewModel.activeWorkspace?.id,
            onSelect: { workspace in
                onChangeWorkspace()
                viewModel.refresh(with: workspace)
                withAnimation { showingPicker = false }
            }
        )
    }
    
    private var appList: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search apps...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(WFSpacing.md)
            
            Divider()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.filteredApps.enumerated()), id: \.1.id) { index, status in
                            AppRow(
                                status: status,
                                isSelected: index == viewModel.selectedIndex
                            )
                            .id(index)
                            .onTapGesture {
                                viewModel.selectedIndex = index
                                if viewModel.activate(status: status) {
                                    onDismiss()
                                }
                            }
                        }
                    }
                }
                .onChange(of: viewModel.selectedIndex) { _, newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }
    
    private var footerView: some View {
        HStack {
            Button("Open all apps") {
                viewModel.openAllApps()
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button("Edit workspace") {
                if let workspace = viewModel.activeWorkspace {
                    onEditWorkspace(workspace)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button("Open DeskFlow") {
                onOpenDeskFlow()
            }
            .buttonStyle(.plain)
        }
        .padding(WFSpacing.md)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    
    @discardableResult
    private func handleKeyDown(_ keyCode: UInt16) -> Bool {
        let apps = viewModel.filteredApps
        guard !apps.isEmpty else {
            if keyCode == 53 { // Escape
                onDismiss()
                return true
            }
            return false
        }
        
        switch keyCode {
        case 125: // Down arrow
            if viewModel.selectedIndex < apps.count - 1 {
                viewModel.selectedIndex += 1
                return true
            }
        case 126: // Up arrow
            if viewModel.selectedIndex > 0 {
                viewModel.selectedIndex -= 1
                return true
            }
        case 36: // Return
            let selectedApp = apps[viewModel.selectedIndex]
            if viewModel.activate(status: selectedApp) {
                onDismiss()
            }
            return true
        case 53: // Escape
            onDismiss()
            return true
        default:
            break
        }
        return false
    }
    
    func refresh(with workspace: Workspace?) {
        viewModel.refresh(with: workspace)
    }
}

private struct AppRow: View {
    let status: DockNavigatorViewModel.AppStatus
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: WFSpacing.md) {
            let nsImage = NSWorkspace.shared.icon(forFile: NSWorkspace.shared.urlForApplication(withBundleIdentifier: status.workspaceApp.bundleIdentifier)?.path ?? "")
            Image(nsImage: nsImage)
                .resizable()
                .frame(width: 32, height: 32)
                .opacity(status.isRunning ? 1.0 : 0.6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(status.workspaceApp.displayName)
                    .font(.body)
                    .opacity(status.isRunning ? 1.0 : 0.6)
                
                if let title = status.windowTitle {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if status.isRunning {
                Text("Running")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Launch")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(WFSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
        .padding(.horizontal, WFSpacing.sm)
    }
}
