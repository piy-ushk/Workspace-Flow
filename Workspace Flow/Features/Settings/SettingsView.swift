import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) var appState
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInDock")    private var showInDock    = false
    @AppStorage("switcherShortcut") private var switcherShortcut = "⌥Space"
    @State private var showPrivacyPolicy = false

    var body: some View {
        Form {
            // Permission status
            Section("Accessibility Permission") {
                HStack {
                    Label(
                        appState.permissionService.isGranted
                            ? "Access granted"
                            : "Access required",
                        systemImage: appState.permissionService.isGranted
                            ? "checkmark.shield.fill"
                            : "exclamationmark.shield.fill"
                    )
                    .foregroundStyle(appState.permissionService.isGranted
                                     ? Color(hex: "#34C759") : Color(hex: "#FF9500"))

                    Spacer()

                    if !appState.permissionService.isGranted {
                        Button("Open Settings") {
                            appState.permissionService.openSystemSettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 2)

                Text("Workspace Flow uses Accessibility access only to identify, move, resize, minimize, and bring forward app windows. It never reads window contents.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Workspace Switcher") {
                HStack {
                    Text("Open Switcher Overlay")
                    Spacer()
                    TextField("e.g. ⌥Space", text: $switcherShortcut)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
            }

            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Bundle ID")
                    Spacer()
                    Text(Bundle.main.bundleIdentifier ?? "—")
                        .foregroundStyle(.secondary)
                        .font(.system(.caption, design: .monospaced))
                }

                Button("Privacy Policy") { showPrivacyPolicy.toggle() }
                    .buttonStyle(.link)
            }

            Section("Data") {
                Text("All workspace data is stored locally on your Mac. No account, no cloud, no analytics.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
                .frame(minWidth: 460, minHeight: 400)
        }
    }
}

// MARK: - Privacy Policy
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Privacy Policy")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(WFSpacing.xl)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: WFSpacing.lg) {
                    PolicySection(title: "What Workspace Flow accesses",
                                  content: "Workspace Flow uses macOS Accessibility API only to identify, move, resize, minimize, and bring forward application windows when you restore a workspace.")

                    PolicySection(title: "What Workspace Flow never does",
                                  content: """
• Never reads the contents of your windows, documents, or browser tabs.
• Never records your screen or takes screenshots.
• Never captures keystrokes or typed text.
• Never reads passwords, browser history, or sensitive data.
• Never connects to the internet or any external server.
• Never collects analytics or usage data.
• Never creates an account or requires sign-in.
""")

                    PolicySection(title: "Data storage",
                                  content: "All workspace data (names, window positions, app lists) is stored locally in a SwiftData database on your Mac. Nothing leaves your device.")

                    PolicySection(title: "Permissions",
                                  content: "The only permission requested is Accessibility. You can revoke it at any time in System Settings → Privacy & Security → Accessibility. Revoking will disable window management features but the app will still run in browse mode.")

                }
                .padding(WFSpacing.xl)
            }
        }
    }
}

private struct PolicySection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: WFSpacing.sm) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
