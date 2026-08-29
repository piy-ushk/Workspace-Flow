import Foundation
import SwiftData

@Model
final class ActivityEvent {
    var id: UUID
    var workspaceID: UUID?
    var workspaceName: String?
    var eventTypeRaw: String
    var timestamp: Date
    var summary: String
    var details: String?
    var successCount: Int
    var failureCount: Int

    var eventType: ActivityEventType {
        get { ActivityEventType(rawValue: eventTypeRaw) ?? .restored }
        set { eventTypeRaw = newValue.rawValue }
    }

    init(
        eventType: ActivityEventType,
        summary: String,
        workspaceID: UUID? = nil,
        workspaceName: String? = nil
    ) {
        self.id = UUID()
        self.eventTypeRaw   = eventType.rawValue
        self.timestamp      = Date()
        self.summary        = summary
        self.workspaceID    = workspaceID
        self.workspaceName  = workspaceName
        self.successCount   = 0
        self.failureCount   = 0
    }
}

enum ActivityEventType: String, CaseIterable {
    case restored = "restored"
    case saved    = "saved"
    case updated  = "updated"
    case cleaned  = "cleaned"
    case failed   = "failed"

    var icon: String {
        switch self {
        case .restored: "arrow.clockwise.circle.fill"
        case .saved:    "square.and.arrow.down.fill"
        case .updated:  "pencil.circle.fill"
        case .cleaned:  "sparkles"
        case .failed:   "exclamationmark.triangle.fill"
        }
    }

    var color: String {
        switch self {
        case .restored: "#34C759"
        case .saved:    "#007AFF"
        case .updated:  "#FF9500"
        case .cleaned:  "#5AC8FA"
        case .failed:   "#FF3B30"
        }
    }
}
