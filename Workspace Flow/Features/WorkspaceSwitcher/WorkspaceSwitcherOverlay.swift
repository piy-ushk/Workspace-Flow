import SwiftUI
import AppKit

// MARK: - Panel Controller
/// NSPanel-based floating overlay for keyboard-first workspace switching.
final class WorkspaceSwitcherPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 500),
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
struct WorkspaceSwitcherOverlay: View {
    let workspaces: [Workspace]
    var onSelect: (Workspace) -> Void
    var onDismiss: () -> Void

    @State private var searchText   = ""
    @State private var selectedIndex = 0
    @State private var appeared     = false

    var filtered: [Workspace] {
        searchText.isEmpty ? workspaces
            : workspaces.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            // Background blur
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(spacing: 0) {
                // Header
                VStack(spacing: WFSpacing.sm) {
                    HStack(spacing: WFSpacing.sm) {
                        Image(systemName: "rectangle.3.group.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                        TextField("Search workspaces…", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18))
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(WFSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .padding(.horizontal, WFSpacing.xl)
                    .padding(.top, WFSpacing.xl)
                }

                Divider()
                    .padding(.top, WFSpacing.md)

                // Workspace grid
                if filtered.isEmpty {
                    Spacer()
                    Text("No workspaces found")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: WFSpacing.md)],
                            spacing: WFSpacing.md
                        ) {
                            ForEach(Array(filtered.enumerated()), id: \.1.id) { idx, workspace in
                                SwitcherCard(
                                    workspace: workspace,
                                    isSelected: idx == selectedIndex
                                )
                                .onTapGesture { select(workspace) }
                                .onHover { if $0 { selectedIndex = idx } }
                            }
                        }
                        .padding(WFSpacing.xl)
                    }
                }

                Divider()

                // Footer hint
                HStack(spacing: WFSpacing.xl) {
                    KeyHint(keys: ["↵"], action: "Restore")
                    KeyHint(keys: ["↑", "↓", "←", "→"], action: "Navigate")
                    KeyHint(keys: ["⎋"], action: "Dismiss")
                }
                .padding(WFSpacing.md)
                .padding(.horizontal, WFSpacing.xl)
            }
        }
        .frame(width: 760, height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 40, y: 20)
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                appeared = true
            }
        }
        .onKeyPress(.escape) { onDismiss(); return .handled }
        .onKeyPress(.return) {
            if filtered.indices.contains(selectedIndex) {
                select(filtered[selectedIndex])
            }
            return .handled
        }
        .onKeyPress(.leftArrow)  { move(-1); return .handled }
        .onKeyPress(.rightArrow) { move(+1); return .handled }
        .onKeyPress(.upArrow)    { move(-3); return .handled }
        .onKeyPress(.downArrow)  { move(+3); return .handled }
    }

    private func move(_ delta: Int) {
        let count = filtered.count
        guard count > 0 else { return }
        selectedIndex = max(0, min(count - 1, selectedIndex + delta))
    }

    private func select(_ workspace: Workspace) {
        onDismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onSelect(workspace)
        }
    }
}

// MARK: - Switcher Card
private struct SwitcherCard: View {
    let workspace: Workspace
    let isSelected: Bool

    var accent: Color { Color(hex: workspace.colorHex) }

    var body: some View {
        VStack(spacing: WFSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: workspace.iconName)
                    .font(.system(size: 26))
                    .foregroundStyle(accent)
            }

            VStack(spacing: 2) {
                Text(workspace.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text("\(workspace.apps.count) apps")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let sc = workspace.keyboardShortcut {
                ShortcutBadge(shortcut: sc)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(WFSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous)
                .fill(isSelected ? accent.opacity(0.2) : Color(NSColor.controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous)
                        .stroke(isSelected ? accent : Color.clear, lineWidth: 2)
                )
        )
        .animation(.spring(response: 0.2), value: isSelected)
    }
}

// MARK: - Key hint
private struct KeyHint: View {
    let keys: [String]
    let action: String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(keys, id: \.self) { k in
                Text(k)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(NSColor.quaternaryLabelColor))
                    )
            }
            Text(action)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Visual Effect Blur (NSViewRepresentable)
struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material    = material
        view.blendingMode = blendingMode
        view.state       = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material    = material
        nsView.blendingMode = blendingMode
    }
}
