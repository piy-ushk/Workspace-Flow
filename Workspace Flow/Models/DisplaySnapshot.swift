import Foundation
import SwiftData

@Model
final class DisplaySnapshot {
    var identifier: String
    var name: String
    var frameX: Double
    var frameY: Double
    var width: Double
    var height: Double
    var isPrimary: Bool

    init(
        identifier: String,
        name: String,
        frameX: Double,
        frameY: Double,
        width: Double,
        height: Double,
        isPrimary: Bool
    ) {
        self.identifier = identifier
        self.name       = name
        self.frameX     = frameX
        self.frameY     = frameY
        self.width      = width
        self.height     = height
        self.isPrimary  = isPrimary
    }

    var frame: CGRect {
        CGRect(x: frameX, y: frameY, width: width, height: height)
    }
}
