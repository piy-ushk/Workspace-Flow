import SwiftUI
import AppKit

extension Color {
    /// Initialize from a CSS hex string like "#007AFF" or "007AFF"
    init(hex: String) {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("#") { clean.removeFirst() }

        var rgb: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8)  & 0xFF) / 255
        let b = Double(rgb         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// Return a hex string like "#007AFF"
    var hexString: String {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor(self)
        let r = Int((nsColor.redComponent   * 255).rounded())
        let g = Int((nsColor.greenComponent * 255).rounded())
        let b = Int((nsColor.blueComponent  * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Workspace palette
extension Color {
    static let workspaceBlue   = Color(hex: "#007AFF")
    static let workspaceOrange = Color(hex: "#FF9500")
    static let workspacePurple = Color(hex: "#AF52DE")
    static let workspaceGreen  = Color(hex: "#34C759")
    static let workspaceRed    = Color(hex: "#FF3B30")
    static let workspaceTeal   = Color(hex: "#5AC8FA")
    static let workspaceIndigo = Color(hex: "#5856D6")
    static let workspaceYellow = Color(hex: "#FFCC00")
    static let workspacePink   = Color(hex: "#FF2D55")
    static let workspaceMint   = Color(hex: "#00C7BE")

    static let workspacePalette: [Color] = [
        .workspaceBlue, .workspaceOrange, .workspacePurple, .workspaceGreen,
        .workspaceRed,  .workspaceTeal,   .workspaceIndigo,  .workspaceYellow,
        .workspacePink, .workspaceMint
    ]
}
