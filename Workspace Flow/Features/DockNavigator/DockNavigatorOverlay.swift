import SwiftUI
import AppKit

// MARK: - Panel Controller
final class DockNavigatorPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 600), // Height is dynamic, we'll set it
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
    
    // Grid configuration
    let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 20)
    ]
    
    var body: some View {
        ZStack {
            // macOS Dock Stack style background
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 5)
            
            VStack(spacing: 0) {
                // Header (Workspace Info)
                headerView
                
                Divider().background(Color.white.opacity(0.1))
                
                // Content
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
                    .frame(height: 200)
                } else if showingPicker {
                    workspacePickerView
                        .frame(height: 300)
                } else if viewModel.appStates.isEmpty {
                    VStack {
                        Spacer()
                        Text("No Apps in Workspace")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(height: 200)
                } else {
                    appGrid
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Footer
                footerView
            }
        }
        .frame(width: 420)
        // Spring animation from bottom
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.4, anchor: .bottom)
        .offset(y: appeared ? 0 : 50)
        .onAppear {
            viewModel.refresh(with: initialWorkspace)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
        .onKeyPress(.escape) { handleKeyDown(53); return .handled }
        .onKeyPress(.downArrow) { handleKeyDown(125); return .handled }
        .onKeyPress(.upArrow) { handleKeyDown(126); return .handled }
        .onKeyPress(.leftArrow) { handleKeyDown(123); return .handled }
        .onKeyPress(.rightArrow) { handleKeyDown(124); return .handled }
        .onKeyPress(.return) { handleKeyDown(36); return .handled }
    }
    
    private var headerView: some View {
        HStack {
            if let workspace = viewModel.activeWorkspace {
                Image(systemName: workspace.iconName)
                    .foregroundStyle(Color(hex: workspace.colorHex))
                    .font(.system(size: 18, weight: .semibold))
                Text(workspace.name)
                    .font(.system(size: 16, weight: .semibold))
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
    
    private var appGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(Array(viewModel.appStates.enumerated()), id: \.1.id) { index, status in
                    AppGridCell(
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
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
        }
        .frame(maxHeight: 400) // constrain height so it doesn't grow unbounded
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
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
    }
    
    @discardableResult
    private func handleKeyDown(_ keyCode: UInt16) -> Bool {
        let apps = viewModel.appStates
        guard !apps.isEmpty else {
            if keyCode == 53 { // Escape
                onDismiss()
                return true
            }
            return false
        }
        
        // Approximate columns based on width
        let cols = 3
        
        switch keyCode {
        case 125: // Down arrow
            if viewModel.selectedIndex + cols < apps.count {
                viewModel.selectedIndex += cols
                return true
            } else {
                viewModel.selectedIndex = apps.count - 1
                return true
            }
        case 126: // Up arrow
            if viewModel.selectedIndex - cols >= 0 {
                viewModel.selectedIndex -= cols
                return true
            } else {
                viewModel.selectedIndex = 0
                return true
            }
        case 123: // Left
            if viewModel.selectedIndex > 0 {
                viewModel.selectedIndex -= 1
                return true
            }
        case 124: // Right
            if viewModel.selectedIndex < apps.count - 1 {
                viewModel.selectedIndex += 1
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
}

private struct AppGridCell: View {
    let status: DockNavigatorViewModel.AppStatus
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Selection highlight
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 64, height: 64)
                }
                
                let nsImage = NSWorkspace.shared.icon(forFile: NSWorkspace.shared.urlForApplication(withBundleIdentifier: status.workspaceApp.bundleIdentifier)?.path ?? "")
                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .opacity(status.isRunning ? 1.0 : 0.6)
                    // Slight bounce on select
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.spring(response: 0.2), value: isSelected)
            }
            .frame(width: 64, height: 64)
            
            VStack(spacing: 2) {
                Text(status.workspaceApp.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.8))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                // Running indicator
                Circle()
                    .fill(status.isRunning ? Color.white.opacity(0.8) : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .contentShape(Rectangle())
    }
}
