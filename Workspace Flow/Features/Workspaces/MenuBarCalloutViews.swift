import SwiftUI

// MARK: - Menu Bar Callout Banner
/// Dismissible tip shown in the dashboard until the user acknowledges it.
struct MenuBarCalloutBanner: View {
    var onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        HStack(spacing: WFSpacing.md) {
            // Animated icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "#007AFF").opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(hex: "#007AFF"))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("DeskFlow lives in your menu bar")
                        .font(.system(size: 13, weight: .semibold))
                    // Live pulse
                    Circle()
                        .fill(Color(hex: "#34C759"))
                        .frame(width: 7, height: 7)
                        .scaleEffect(appeared ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: appeared)
                }
                Text("Click the \(Image(systemName: "rectangle.3.group.fill")) icon at the top-right of your screen to switch or restore workspaces — anytime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button {
                withAnimation(.spring(response: 0.3)) { onDismiss() }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .help("Dismiss")
        }
        .padding(WFSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: WFRadius.lg, style: .continuous)
                        .stroke(Color(hex: "#007AFF").opacity(0.25), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -8)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - Menu Bar Info Popover
/// Shown when user clicks the menubar.rectangle toolbar button.
struct MenuBarInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: WFSpacing.lg) {
            // Header
            HStack(spacing: WFSpacing.sm) {
                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "#007AFF"))
                Text("Menu Bar")
                    .font(.headline)
            }

            Divider()

            // Steps
            VStack(alignment: .leading, spacing: WFSpacing.md) {
                InfoRow(
                    number: "1",
                    icon: "rectangle.3.group.fill",
                    color: Color(hex: "#007AFF"),
                    title: "Find the icon",
                    subtitle: "Look for ⊞ in the top-right of your screen, next to the clock."
                )
                InfoRow(
                    number: "2",
                    icon: "cursorarrow.click",
                    color: Color(hex: "#AF52DE"),
                    title: "Click to switch",
                    subtitle: "Instantly restore any saved workspace from the dropdown."
                )
                InfoRow(
                    number: "3",
                    icon: "keyboard",
                    color: Color(hex: "#34C759"),
                    title: "Or use a shortcut",
                    subtitle: "Assign ⌥1, ⌥2… to individual workspaces in the editor."
                )
            }

            Divider()

            // Status
            HStack(spacing: WFSpacing.sm) {
                Circle()
                    .fill(Color(hex: "#34C759"))
                    .frame(width: 8, height: 8)
                Text("Menu bar icon is active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(WFSpacing.xl)
        .frame(width: 300)
    }
}

// MARK: - Info Row helper
private struct InfoRow: View {
    let number: String
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: WFSpacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview("Banner") {
    MenuBarCalloutBanner { }
        .padding()
        .frame(width: 560)
}

#Preview("Popover") {
    MenuBarInfoPopover()
}
