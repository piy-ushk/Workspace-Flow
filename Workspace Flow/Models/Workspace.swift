import Foundation
import SwiftData

@Model
final class Workspace {
    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?
    var keyboardShortcut: String?
    var cleanModeRaw: String
    var isFavorite: Bool
    var sortOrder: Int

    @Relationship(deleteRule: .cascade) var apps: [WorkspaceApp]
    @Relationship(deleteRule: .cascade) var windows: [WorkspaceWindow]
    @Relationship(deleteRule: .cascade) var displays: [DisplaySnapshot]

    var cleanMode: CleanMode {
        get { CleanMode(rawValue: cleanModeRaw) ?? .none }
        set { cleanModeRaw = newValue.rawValue }
    }

    init(
        name: String,
        iconName: String = "rectangle.3.group",
        colorHex: String = "#007AFF",
        sortOrder: Int = 0
    ) {
        self.id        = UUID()
        self.name      = name
        self.iconName  = iconName
        self.colorHex  = colorHex
        self.createdAt = Date()
        self.updatedAt = Date()
        self.cleanModeRaw = CleanMode.none.rawValue
        self.isFavorite   = false
        self.sortOrder    = sortOrder
        self.apps     = []
        self.windows  = []
        self.displays = []
    }
}

// MARK: - Enums
enum CleanMode: String, Codable, CaseIterable {
    case none              = "none"
    case hideOtherApps     = "hideOtherApps"
    case minimizeOtherWindows = "minimizeOtherWindows"

    var label: String {
        switch self {
        case .none:                "No action"
        case .hideOtherApps:      "Hide other apps"
        case .minimizeOtherWindows: "Minimize other windows"
        }
    }
}
