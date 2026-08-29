import SwiftUI
import SwiftData

struct WorkspaceEditorView: View {
    @Environment(AppState.self) var appState
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    let workspace: Workspace?

    // Form state
    @State private var name         = ""
    @State private var iconName     = "rectangle.3.group"
    @State private var colorHex     = "#007AFF"
    @State private var shortcut     = ""
    @State private var cleanMode    = CleanMode.none
    @State private var isFavorite   = false
    @State private var selectedApps : Set<String> = []
    @State private var captureResult: CaptureResult? = nil
    @State private var isCapturing  = true
    @State private var showIconPicker = false
    @State private var phase: EditorPhase = .form

    enum EditorPhase { case form, windowSelect, saving }

    var isEditMode: Bool { workspace != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isEditMode ? "Edit Workspace" : "Save Workspace")
                        .font(.title2)
                        .fontWeight(.bold)
                    if let r = captureResult {
                        Text("\(r.apps.count) apps · \(r.windows.count) windows detected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(WFSpacing.xl)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(spacing: WFSpacing.xl) {
                    // Workspace identity section
                    identitySection

                    Divider()

                    // Window/App selection
                    if let result = captureResult {
                        WindowSelectionView(
                            captureResult: result,
                            selectedApps: $selectedApps
                        )
                    } else if isCapturing {
                        HStack {
                            ProgressView()
                            Text("Detecting windows…")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }

                    Divider()

                    // Clean mode
                    VStack(alignment: .leading, spacing: WFSpacing.md) {
                        WFSectionHeader(title: "After Restoring")
                        Picker("Clean mode", selection: $cleanMode) {
                            ForEach(CleanMode.allCases, id: \.self) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }
                .padding(WFSpacing.xl)
            }

            Divider()

            // Actions
            HStack {
                Toggle("Favorite", isOn: $isFavorite)
                    .toggleStyle(.checkbox)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(isEditMode ? "Update" : "Save Workspace") { save() }
                    .buttonStyle(WFPrimaryButtonStyle(color: Color(hex: colorHex)))
                    .keyboardShortcut(.defaultAction)
            }
            .padding(WFSpacing.xl)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .onAppear { loadData() }
    }

    // MARK: Identity section
    private var identitySection: some View {
        VStack(alignment: .leading, spacing: WFSpacing.lg) {
            WFSectionHeader(title: "Identity")

            HStack(spacing: WFSpacing.lg) {
                // Icon picker button
                Button { showIconPicker.toggle() } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(hex: colorHex).opacity(0.15))
                            .frame(width: 64, height: 64)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(hex: colorHex).opacity(0.4), lineWidth: 1.5)
                            )
                        Image(systemName: iconName)
                            .font(.system(size: 28))
                            .foregroundStyle(Color(hex: colorHex))
                    }
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showIconPicker) {
                    IconPickerView(selected: $iconName, accentColor: Color(hex: colorHex))
                }

                VStack(alignment: .leading, spacing: WFSpacing.sm) {
                    TextField("Workspace name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 15, weight: .medium))

                    TextField("Shortcut (e.g. ⌥1)", text: $shortcut)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                }
            }

            // Color palette
            VStack(alignment: .leading, spacing: WFSpacing.sm) {
                Text("Color")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: WFSpacing.sm) {
                    ForEach(Color.workspacePalette, id: \.self) { color in
                        let hex = color.hexString
                        Button {
                            withAnimation(.spring(response: 0.2)) { colorHex = hex }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(color)
                                    .frame(width: 28, height: 28)
                                if colorHex == hex {
                                    Circle()
                                        .stroke(.white, lineWidth: 2)
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Load
    private func loadData() {
        if let ws = workspace {
            name       = ws.name
            iconName   = ws.iconName
            colorHex   = ws.colorHex
            shortcut   = ws.keyboardShortcut ?? ""
            cleanMode  = ws.cleanMode
            isFavorite = ws.isFavorite
            selectedApps = Set(ws.apps.map(\.bundleIdentifier))
        }

        Task {
            let result = appState.captureService.captureCurrentLayout()
            captureResult = result
            if workspace == nil {
                name         = result.suggestedName
                selectedApps = Set(result.apps.map(\.bundleIdentifier))
            }
            isCapturing = false
        }
    }

    // MARK: Save
    private func save() {
        guard !name.isEmpty else { return }

        let ws = workspace ?? Workspace(name: name)
        ws.name      = name
        ws.iconName  = iconName
        ws.colorHex  = colorHex
        ws.keyboardShortcut = shortcut.isEmpty ? nil : shortcut
        ws.cleanMode = cleanMode
        ws.isFavorite = isFavorite
        ws.updatedAt = Date()

        // Apps
        ws.apps.forEach { modelContext.delete($0) }
        ws.apps = []

        if let result = captureResult {
            for app in result.apps where selectedApps.contains(app.bundleIdentifier) {
                let a = WorkspaceApp(bundleIdentifier: app.bundleIdentifier, displayName: app.displayName)
                ws.apps.append(a)
            }

            // Windows
            ws.windows.forEach { modelContext.delete($0) }
            ws.windows = []
            for win in result.windows where selectedApps.contains(win.bundleIdentifier) {
                let display = result.displays.first { $0.frame.contains(win.frame.origin) }
                let w = WorkspaceWindow(
                    bundleIdentifier: win.bundleIdentifier,
                    windowTitle: win.title,
                    windowIndex: win.windowIndex,
                    displayIdentifier: display?.identifier ?? "",
                    frameX: win.frame.minX,
                    frameY: win.frame.minY,
                    frameWidth: win.frame.width,
                    frameHeight: win.frame.height,
                    isMinimized: win.isMinimized,
                    isRestorable: win.isRestorable
                )
                ws.windows.append(w)
            }

            // Displays
            ws.displays.forEach { modelContext.delete($0) }
            ws.displays = []
            for d in result.displays {
                let snap = DisplaySnapshot(
                    identifier: d.identifier,
                    name: d.name,
                    frameX: d.frame.minX,
                    frameY: d.frame.minY,
                    width: d.frame.width,
                    height: d.frame.height,
                    isPrimary: d.isPrimary
                )
                ws.displays.append(snap)
            }
        }

        if workspace == nil {
            modelContext.insert(ws)
            appState.activityLog.logSave(workspace: ws, in: modelContext)
        }

        try? modelContext.save()

        // Register shortcut
        if let sc = ws.keyboardShortcut, !sc.isEmpty {
            appState.shortcutService.register(shortcut: sc) {
                Task {
                    let result = await appState.restoreService.restore(workspace: ws)
                    appState.showHUD(result: result)
                }
            }
        }

        dismiss()
    }
}

// MARK: - Icon Picker
struct IconPickerView: View {
    @Binding var selected: String
    let accentColor: Color
    @Environment(\.dismiss) var dismiss

    let icons: [String] = [
        "rectangle.3.group.fill", "laptopcomputer", "desktopcomputer", "macmini.fill",
        "keyboard.fill", "terminal.fill", "chevron.left.forwardslash.chevron.right",
        "safari.fill", "network", "doc.text.fill", "doc.richtext.fill",
        "folder.fill", "archivebox.fill", "tray.fill",
        "pencil", "paintbrush.fill", "paintpalette.fill", "photo.fill",
        "music.note", "headphones", "mic.fill", "video.fill",
        "calendar", "clock.fill", "bell.fill", "checkmark.seal.fill",
        "person.fill", "person.2.fill", "building.2.fill", "briefcase.fill",
        "chart.bar.fill", "chart.pie.fill", "gauge.high",
        "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "leaf.fill", "moon.fill", "sun.max.fill", "sparkles",
        "gamecontroller.fill", "puzzlepiece.fill", "dice.fill"
    ]

    let columns = Array(repeating: GridItem(.fixed(42), spacing: 4), count: 8)

    var body: some View {
        VStack(alignment: .leading, spacing: WFSpacing.md) {
            Text("Choose Icon")
                .font(.headline)
                .padding(.horizontal, WFSpacing.lg)
                .padding(.top, WFSpacing.lg)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selected = icon
                            dismiss()
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundStyle(selected == icon ? accentColor : .secondary)
                                .frame(width: 38, height: 38)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selected == icon ? accentColor.opacity(0.15) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(WFSpacing.md)
            }
        }
        .frame(width: 360, height: 300)
    }
}
