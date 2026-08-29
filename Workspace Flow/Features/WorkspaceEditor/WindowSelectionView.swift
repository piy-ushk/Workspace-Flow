import SwiftUI

struct WindowSelectionView: View {
    let captureResult: CaptureResult
    @Binding var selectedApps: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: WFSpacing.md) {
            HStack {
                WFSectionHeader(title: "Detected Apps & Windows")
                Spacer()
                Button("Select All") { selectedApps = Set(captureResult.apps.map(\.bundleIdentifier)) }
                    .font(.caption)
                Button("Deselect All") { selectedApps.removeAll() }
                    .font(.caption)
            }

            if captureResult.apps.isEmpty {
                Text("No eligible applications detected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                VStack(spacing: WFSpacing.xs) {
                    ForEach(captureResult.apps) { app in
                        AppSelectionRow(
                            app: app,
                            windows: captureResult.windows.filter { $0.bundleIdentifier == app.bundleIdentifier },
                            isSelected: selectedApps.contains(app.bundleIdentifier),
                            onToggle: {
                                if selectedApps.contains(app.bundleIdentifier) {
                                    selectedApps.remove(app.bundleIdentifier)
                                } else {
                                    selectedApps.insert(app.bundleIdentifier)
                                }
                            }
                        )
                    }
                }
                .padding(WFSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            }
        }
    }
}

private struct AppSelectionRow: View {
    let app: RunningAppInfo
    let windows: [DiscoveredWindow]
    let isSelected: Bool
    let onToggle: () -> Void
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: WFSpacing.sm) {
                    // Checkbox
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .font(.system(size: 16))
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)


                    // App icon
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 24, height: 24)
                    }

                    Text(app.displayName)
                        .font(.system(size: 13, weight: .medium))

                    Spacer()

                    // Window count
                    if !windows.isEmpty {
                        Text("\(windows.count) window\(windows.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Expand arrow
                    if !windows.isEmpty {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .onTapGesture { withAnimation { expanded.toggle() } }
                    }
                }
                .padding(.vertical, WFSpacing.sm)
                .padding(.horizontal, WFSpacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(windows) { win in
                        HStack(spacing: WFSpacing.sm) {
                            Image(systemName: win.isRestorable ? "rectangle.dashed" : "rectangle.slash")
                                .font(.caption2)
                                .foregroundStyle(win.isRestorable ? Color.secondary : Color.red)

                            Text(win.title ?? "Untitled Window")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer()
                            if !win.isRestorable {
                                Text("Not restorable")
                                    .font(.caption2)
                                    .foregroundStyle(.red.opacity(0.8))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(.red.opacity(0.1)))
                            } else {
                                Text("\(Int(win.frame.width))×\(Int(win.frame.height))")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.leading, 44)
                        .padding(.vertical, 2)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
