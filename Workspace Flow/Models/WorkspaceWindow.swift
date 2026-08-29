import Foundation
import SwiftData

@Model
final class WorkspaceWindow {
    var id: UUID
    var bundleIdentifier: String
    var windowTitle: String?
    var windowIndex: Int
    var displayIdentifier: String
    var frameX: Double
    var frameY: Double
    var frameWidth: Double
    var frameHeight: Double
    var isMinimized: Bool
    var isRestorable: Bool

    init(
        bundleIdentifier: String,
        windowTitle: String? = nil,
        windowIndex: Int,
        displayIdentifier: String,
        frameX: Double,
        frameY: Double,
        frameWidth: Double,
        frameHeight: Double,
        isMinimized: Bool = false,
        isRestorable: Bool = true
    ) {
        self.id = UUID()
        self.bundleIdentifier  = bundleIdentifier
        self.windowTitle       = windowTitle
        self.windowIndex       = windowIndex
        self.displayIdentifier = displayIdentifier
        self.frameX      = frameX
        self.frameY      = frameY
        self.frameWidth  = frameWidth
        self.frameHeight = frameHeight
        self.isMinimized  = isMinimized
        self.isRestorable = isRestorable
    }

    var frame: CGRect {
        CGRect(x: frameX, y: frameY, width: frameWidth, height: frameHeight)
    }
}
