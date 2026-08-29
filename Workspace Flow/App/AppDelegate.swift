import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Intercept Dock clicks to show Dock Navigator
        NotificationCenter.default.post(name: .showDockNavigator, object: nil)
        
        // Return false to prevent standard window reopening behavior since Dock Navigator is our primary interaction
        return false
    }
}

extension Notification.Name {
    static let showDockNavigator = Notification.Name("showDockNavigator")
}
