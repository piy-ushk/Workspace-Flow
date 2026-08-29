import Foundation
import SwiftData
import OSLog

final class ActivityLogService {
    private let logger = Logger.activity

    func log(_ event: ActivityEvent, in context: ModelContext) {
        context.insert(event)
        save(context)
    }

    func logRestore(result: RestoreResult, workspace: Workspace, in context: ModelContext) {
        let event = ActivityEvent(
            eventType: result.isSuccess ? .restored : .failed,
            summary: "\(workspace.name) restored — \(result.summary)",
            workspaceID: workspace.id,
            workspaceName: workspace.name
        )
        event.successCount = result.windowsRestored
        event.failureCount = result.windowsFailed
        if !result.warnings.isEmpty {
            event.details = result.warnings.joined(separator: "\n")
        }
        log(event, in: context)
    }

    func logSave(workspace: Workspace, in context: ModelContext) {
        let event = ActivityEvent(
            eventType: .saved,
            summary: "\"\(workspace.name)\" workspace saved",
            workspaceID: workspace.id,
            workspaceName: workspace.name
        )
        event.successCount = workspace.windows.count
        log(event, in: context)
    }

    func logClean(workspace: Workspace, mode: CleanMode, in context: ModelContext) {
        let event = ActivityEvent(
            eventType: .cleaned,
            summary: "\"\(workspace.name)\" cleaned — \(mode.label)",
            workspaceID: workspace.id,
            workspaceName: workspace.name
        )
        log(event, in: context)
    }

    func clearAll(in context: ModelContext) {
        do {
            try context.delete(model: ActivityEvent.self)
            save(context)
        } catch {
            logger.error("Failed to clear activity log: \(error)")
        }
    }

    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            logger.error("Failed to save activity event: \(error)")
        }
    }
}
