import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) var appState
    @State private var step: OnboardingStep = .welcome
    @State private var permissionPollingTimer: Timer?
    @State private var pulse = false

    enum OnboardingStep { case welcome, permission, ready }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color(hex: "#0A0A0F"), Color(hex: "#0D1117"), Color(hex: "#0A0F1A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle animated orbs
            GeometryReader { geo in
                Circle()
                    .fill(Color(hex: "#007AFF").opacity(0.12))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: geo.size.width * 0.6, y: -100)
                    .scaleEffect(pulse ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: pulse)

                Circle()
                    .fill(Color(hex: "#AF52DE").opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -50, y: geo.size.height * 0.6)
            }

            // Content
            VStack(spacing: 0) {
                Spacer()
                switch step {
                case .welcome:    WelcomeStep(onNext: { withAnimation(.spring(response: 0.5)) { step = .permission } })
                case .permission: PermissionStep(onNext: { withAnimation(.spring(response: 0.5)) { step = .ready } },
                                                  permissionService: appState.permissionService,
                                                  pollingTimer: $permissionPollingTimer)
                case .ready:      ReadyStep(onFinish: { appState.completeOnboarding() })
                }
                Spacer()

                // Step dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        let current = i == stepIndex
                        Circle()
                            .fill(current ? Color.white : Color.white.opacity(0.25))
                            .frame(width: current ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.3), value: stepIndex)
                    }
                }
                .padding(.bottom, 36)
            }
        }
        .frame(minWidth: 560, minHeight: 480)
        .onAppear { pulse = true }
        .onDisappear { permissionPollingTimer?.invalidate() }
    }

    private var stepIndex: Int {
        switch step {
        case .welcome: 0; case .permission: 1; case .ready: 2
        }
    }
}

// MARK: - Welcome Step
private struct WelcomeStep: View {
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: WFSpacing.xl) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: "#007AFF"), Color(hex: "#5856D6")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 88, height: 88)
                    .shadow(color: Color(hex: "#007AFF").opacity(0.5), radius: 20, y: 8)
                Image(systemName: "rectangle.3.group.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }

            VStack(spacing: WFSpacing.sm) {
                Text("DeskFlow")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Your workspace, exactly where you left it.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: WFSpacing.md) {
                FeatureRow(icon: "square.and.arrow.down.fill", color: Color(hex: "#007AFF"),
                           title: "Save your layout", subtitle: "Capture running apps and window positions in one click")
                FeatureRow(icon: "arrow.clockwise.circle.fill", color: Color(hex: "#34C759"),
                           title: "Restore instantly", subtitle: "Jump back to any saved workspace from the menu bar")
                FeatureRow(icon: "sparkles", color: Color(hex: "#AF52DE"),
                           title: "Stay focused", subtitle: "Clean your desktop with a single action")
            }
            .padding(WFSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: WFRadius.xl, style: .continuous)
                    .fill(.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: WFRadius.xl, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1))
            )

            Button("Get Started", action: onNext)
                .buttonStyle(WFPrimaryButtonStyle())
                .controlSize(.large)
        }
        .padding(WFSpacing.xxxl)
        .frame(maxWidth: 480)
    }
}

// MARK: - Permission Step
private struct PermissionStep: View {
    var onNext: () -> Void
    @Bindable var permissionService: AccessibilityPermissionService
    @Binding var pollingTimer: Timer?

    var body: some View {
        VStack(spacing: WFSpacing.xl) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#007AFF").opacity(0.15))
                    .frame(width: 100, height: 100)
                    .blur(radius: 2)
                Image(systemName: permissionService.isGranted ? "checkmark.shield.fill" : "hand.raised.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(permissionService.isGranted ? Color(hex: "#34C759") : Color(hex: "#007AFF"))
                    .symbolEffect(.bounce, value: permissionService.isGranted)
            }

            VStack(spacing: WFSpacing.sm) {
                Text("Workspace Control")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(permissionService.isGranted
                     ? "Permission granted — DeskFlow can manage your windows."
                     : "DeskFlow needs Accessibility access to move and resize windows when you restore a workspace.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            // Privacy note
            HStack(spacing: WFSpacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(Color(hex: "#34C759"))
                Text("DeskFlow **never** reads window contents, records your screen, or collects your data.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(WFSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: WFRadius.md, style: .continuous)
                    .fill(.white.opacity(0.05))
            )

            if permissionService.isGranted {
                Button("Continue", action: onNext)
                    .buttonStyle(WFPrimaryButtonStyle(color: Color(hex: "#34C759")))
                    .controlSize(.large)
            } else {
                VStack(spacing: WFSpacing.sm) {
                    Button("Allow Workspace Control") {
                        permissionService.requestPermission()
                        startPolling()
                    }
                    .buttonStyle(WFPrimaryButtonStyle())
                    .controlSize(.large)

                    Button("Skip for now") { onNext() }
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.5))
                        .buttonStyle(.plain)
                }
            }
        }
        .padding(WFSpacing.xxxl)
        .frame(maxWidth: 480)
        .onDisappear { pollingTimer?.invalidate() }
    }

    private func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            permissionService.checkPermission()
        }
    }
}

// MARK: - Ready Step
private struct ReadyStep: View {
    var onFinish: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: WFSpacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color(hex: "#34C759"))
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: appeared)

            VStack(spacing: WFSpacing.sm) {
                Text("You're all set!")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Save your first workspace now, or browse the dashboard.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.spring(response: 0.5).delay(0.2), value: appeared)

            Button("Open Dashboard", action: onFinish)
                .buttonStyle(WFPrimaryButtonStyle())
                .controlSize(.large)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5).delay(0.3), value: appeared)
        }
        .padding(WFSpacing.xxxl)
        .frame(maxWidth: 480)
        .onAppear { appeared = true }
    }
}

// MARK: - Feature row
private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: WFSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
