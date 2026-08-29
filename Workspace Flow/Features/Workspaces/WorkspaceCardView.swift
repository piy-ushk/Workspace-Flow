import SwiftUI

struct WorkspaceCardView: View {
    let workspace: Workspace
    var onRestore:   () -> Void
    var onEdit:      () -> Void
    var onDelete:    () -> Void
    var onDuplicate: () -> Void

    @State private var isHovered = false
    @State private var isRestoring = false

    private var accentColor: Color { Color(hex: workspace.colorHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar with color accent
            Rectangle()
                .fill(accentColor.gradient)
                .frame(height: 4)

            VStack(alignment: .leading, spacing: WFSpacing.md) {
                // Icon + Name row
                HStack(spacing: WFSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 42, height: 42)
                        Image(systemName: workspace.iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(accentColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(workspace.name)
                                .font(.system(size: 16, weight: .semibold))
                                .lineLimit(1)
                            if workspace.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.yellow)
                            }
                        }
                        Text("\(workspace.apps.count) app\(workspace.apps.count == 1 ? "" : "s") · \(workspace.windows.count) window\(workspace.windows.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Shortcut badge
                    if let sc = workspace.keyboardShortcut {
                        ShortcutBadge(shortcut: sc)
                    }

                    // Context menu button
                    Menu {
                        Button("Edit", systemImage: "pencil", action: onEdit)
                        Button("Duplicate", systemImage: "doc.on.doc", action: onDuplicate)
                        Divider()
                        Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle().fill(Color(NSColor.quaternaryLabelColor))
                                    .opacity(isHovered ? 1 : 0)
                            )
                    }
                    .menuStyle(.button)
                    .buttonStyle(.plain)
                }

                // App icons row
                if !workspace.apps.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(workspace.apps.prefix(6)) { app in
                            AppIconImage(bundleIdentifier: app.bundleIdentifier, size: 22)
                                .help(app.displayName)
                        }
                        if workspace.apps.count > 6 {
                            Text("+\(workspace.apps.count - 6)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color(NSColor.quaternaryLabelColor)))
                        }
                        Spacer()
                    }
                }

                Divider().opacity(0.5)

                // Bottom row: last used + restore
                HStack {
                    if let used = workspace.lastUsedAt {
                        Label(used.formatted(.relative(presentation: .named)), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Never used")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    // Restore button
                    Button {
                        Task {
                            isRestoring = true
                            onRestore()
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            isRestoring = false
                        }
                    } label: {
                        Label(isRestoring ? "Restoring…" : "Restore", systemImage: isRestoring ? "arrow.clockwise" : "play.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(isRestoring ? Color.secondary : accentColor)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isRestoring)

                }
            }
            .padding(WFSpacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: accentColor.opacity(isHovered ? 0.2 : 0),
                        radius: isHovered ? 12 : 0, y: 4)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous)
                .stroke(accentColor.opacity(isHovered ? 0.4 : 0.1), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Restore", systemImage: "play.fill", action: onRestore)
            Button("Edit", systemImage: "pencil", action: onEdit)
            Button("Duplicate", systemImage: "doc.on.doc", action: onDuplicate)
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
    }
}
