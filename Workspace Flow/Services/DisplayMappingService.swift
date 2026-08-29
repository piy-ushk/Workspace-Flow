import Cocoa
import OSLog

/// Maps saved display geometry to current screen layout, with proportional fallback.
final class DisplayMappingService {
    private let logger = Logger.display

    // MARK: - Public API

    func currentDisplays() -> [NSScreen] { NSScreen.screens }

    func displayIdentifier(for screen: NSScreen) -> String {
        if let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
            return "\(num)"
        }
        return screen.localizedName
    }

    /// Map a saved frame to the current display layout.
    /// - If the original display is still available, just clamp the frame to it.
    /// - If the original display is gone, proportionally map to the primary display.
    func mapFrame(
        _ savedFrame: CGRect,
        fromDisplay savedDisplay: DisplaySnapshot?,
        toCurrentDisplays screens: [NSScreen]
    ) -> CGRect {
        let primaryScreen = NSScreen.main ?? screens.first ?? NSScreen()

        guard let saved = savedDisplay else {
            return clampToScreen(savedFrame, screen: primaryScreen)
        }

        // Look for matching screen by stored identifier
        if let match = screens.first(where: { displayIdentifier(for: $0) == saved.identifier }) {
            return clampToScreen(savedFrame, screen: match)
        }

        // Display gone — remap proportionally to primary
        logger.info("Display \(saved.identifier) not found, remapping to primary")
        return mapProportionally(savedFrame, fromDisplayFrame: saved.frame, toScreen: primaryScreen)
    }

    // MARK: - Helpers

    func mapProportionally(_ frame: CGRect, fromDisplayFrame displayFrame: CGRect, toScreen screen: NSScreen) -> CGRect {
        guard displayFrame.width > 0, displayFrame.height > 0 else {
            return clampToScreen(frame, screen: screen)
        }

        let rx = (frame.minX - displayFrame.minX) / displayFrame.width
        let ry = (frame.minY - displayFrame.minY) / displayFrame.height
        let rw = frame.width  / displayFrame.width
        let rh = frame.height / displayFrame.height

        let sf = screen.frame
        return clampToScreen(
            CGRect(x: sf.minX + rx * sf.width,
                   y: sf.minY + ry * sf.height,
                   width: rw * sf.width,
                   height: rh * sf.height),
            screen: screen
        )
    }

    func clampToScreen(_ frame: CGRect, screen: NSScreen) -> CGRect {
        let sf   = screen.frame
        let minW : CGFloat = 200
        let minH : CGFloat = 100
        let w = max(minW, min(frame.width,  sf.width))
        let h = max(minH, min(frame.height, sf.height))
        let x = max(sf.minX, min(frame.minX, sf.maxX - w))
        let y = max(sf.minY, min(frame.minY, sf.maxY - h))
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
