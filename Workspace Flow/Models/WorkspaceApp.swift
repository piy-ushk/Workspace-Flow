import Foundation
import SwiftData

@Model
final class WorkspaceApp {
    var id: UUID
    var bundleIdentifier: String
    var displayName: String
    var launchIfMissing: Bool
    var isRequired: Bool
    var visibilityRaw: String
    var appIconBookmark: Data?

    var preferredVisibility: WindowVisibility {
        get { WindowVisibility(rawValue: visibilityRaw) ?? .visible }
        set { visibilityRaw = newValue.rawValue }
    }

    init(bundleIdentifier: String, displayName: String) {
        self.id = UUID()
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.launchIfMissing = true
        self.isRequired = false
        self.visibilityRaw = WindowVisibility.visible.rawValue
    }
}

enum WindowVisibility: String, CaseIterable {
    case frontmost  = "frontmost"
    case visible    = "visible"
    case minimized  = "minimized"
    case hidden     = "hidden"
}
