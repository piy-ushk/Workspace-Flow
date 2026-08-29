import Cocoa
import OSLog

// MARK: - Shortcut Combo
private struct ShortcutCombo {
    let modifiers: NSEvent.ModifierFlags
    let keyCode: UInt16
}

/// Registers and manages global keyboard shortcuts via NSEvent global monitors.
final class ShortcutService {
    private let logger   = Logger.shortcuts
    private var monitors : [String: Any] = [:]

    // MARK: Public

    @discardableResult
    func register(shortcut: String, handler: @escaping () -> Void) -> Bool {
        guard let combo = parse(shortcut) else {
            logger.warning("Could not parse shortcut: \(shortcut)")
            return false
        }
        unregister(shortcut: shortcut) // remove previous if any

        let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == combo.modifiers,
               event.keyCode == combo.keyCode {
                handler()
            }
        }
        if let m = monitor {
            monitors[shortcut] = m
            logger.info("Registered shortcut: \(shortcut)")
            return true
        }
        return false
    }

    func unregister(shortcut: String) {
        if let m = monitors.removeValue(forKey: shortcut) {
            NSEvent.removeMonitor(m)
        }
    }

    func unregisterAll() {
        monitors.values.forEach { NSEvent.removeMonitor($0) }
        monitors.removeAll()
    }

    // MARK: Display string
    static func displayString(for shortcut: String?) -> String? {
        guard let s = shortcut, !s.isEmpty else { return nil }
        return s
    }

    // MARK: Private
    private func parse(_ shortcut: String) -> ShortcutCombo? {
        var mods: NSEvent.ModifierFlags = []
        var key = shortcut
        if key.contains("⌘") { mods.insert(.command); key.removeAll { $0 == "⌘" } }
        if key.contains("⌥") { mods.insert(.option);  key.removeAll { $0 == "⌥" } }
        if key.contains("⌃") { mods.insert(.control); key.removeAll { $0 == "⌃" } }
        if key.contains("⇧") { mods.insert(.shift);   key.removeAll { $0 == "⇧" } }
        guard let code = keyCode(for: key.lowercased()) else { return nil }
        return ShortcutCombo(modifiers: mods, keyCode: code)
    }

    private func keyCode(for s: String) -> UInt16? {
        let map: [String: UInt16] = [
            "1": 18, "2": 19, "3": 20, "4": 21, "5": 23,
            "6": 22, "7": 26, "8": 28, "9": 25, "0": 29,
            "a": 0,  "b": 11, "c": 8,  "d": 2,  "e": 14,
            "f": 3,  "g": 5,  "h": 4,  "i": 34, "j": 38,
            "k": 40, "l": 37, "m": 46, "n": 45, "o": 31,
            "p": 35, "q": 12, "r": 15, "s": 1,  "t": 17,
            "u": 32, "v": 9,  "w": 13, "x": 7,  "y": 16, "z": 6
        ]
        return map[s]
    }
}
