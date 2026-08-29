import Foundation

/// Transient (non-persisted) restore outcome returned after restoring a workspace.
struct RestoreResult {
    let workspaceName: String
    let windowsRestored: Int
    let windowsFailed: Int
    let appsLaunched: Int
    let appsAlreadyRunning: Int
    let warnings: [String]
    let timestamp: Date

    var isSuccess: Bool { windowsFailed == 0 }

    var summary: String {
        var parts: [String] = []
        if windowsRestored > 0 { parts.append("\(windowsRestored) window\(windowsRestored == 1 ? "" : "s") arranged") }
        if appsLaunched > 0    { parts.append("\(appsLaunched) app\(appsLaunched == 1 ? "" : "s") launched") }
        if appsAlreadyRunning > 0 { parts.append("\(appsAlreadyRunning) already open") }
        return parts.isEmpty ? "Workspace restored" : parts.joined(separator: " · ")
    }
}
