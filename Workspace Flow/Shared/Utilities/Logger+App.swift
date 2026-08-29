import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "personal.Workspace-Flow"

    static let permission = Logger(subsystem: subsystem, category: "Permission")
    static let apps       = Logger(subsystem: subsystem, category: "RunningApps")
    static let windows    = Logger(subsystem: subsystem, category: "Windows")
    static let capture    = Logger(subsystem: subsystem, category: "Capture")
    static let restore    = Logger(subsystem: subsystem, category: "Restore")
    static let display    = Logger(subsystem: subsystem, category: "Display")
    static let shortcuts  = Logger(subsystem: subsystem, category: "Shortcuts")
    static let activity   = Logger(subsystem: subsystem, category: "Activity")
    static let ui         = Logger(subsystem: subsystem, category: "UI")
}
