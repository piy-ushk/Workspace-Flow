import SwiftUI

struct RestoreHUDView: View {
    let result: RestoreResult
    @State private var appeared = false

    var body: some View {
        HStack(spacing: WFSpacing.md) {
            Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundStyle(result.isSuccess ? Color(hex: "#34C759") : Color(hex: "#FF9500"))

            VStack(alignment: .leading, spacing: 2) {
                Text("\"\(result.workspaceName)\" restored")
                    .font(.system(size: 13, weight: .semibold))
                Text(result.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !result.warnings.isEmpty {
                Spacer()
                Button {
                    // Could show detail popover
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(result.warnings.joined(separator: "\n"))
            }
        }
        .padding(.horizontal, WFSpacing.xl)
        .padding(.vertical, WFSpacing.md)
        .background(
            Capsule()
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(appeared ? 1 : 0.85)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        RestoreHUDView(result: RestoreResult(
            workspaceName: "Coding",
            windowsRestored: 4,
            windowsFailed: 0,
            appsLaunched: 2,
            appsAlreadyRunning: 2,
            warnings: [],
            timestamp: Date()
        ))
        .padding()
    }
}
