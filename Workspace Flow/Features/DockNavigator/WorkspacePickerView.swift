import SwiftUI
import SwiftData

struct WorkspacePickerView: View {
    let activeWorkspaceId: PersistentIdentifier?
    let onSelect: (Workspace) -> Void
    
    @Query(sort: \Workspace.sortOrder) private var workspaces: [Workspace]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: WFSpacing.sm) {
                ForEach(workspaces) { workspace in
                    let isActive = workspace.id == activeWorkspaceId
                    
                    HStack(spacing: WFSpacing.md) {
                        Image(systemName: workspace.iconName)
                            .foregroundStyle(Color(hex: workspace.colorHex))
                        Text(workspace.name)
                            .font(.body)
                        Spacer()
                        if isActive {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(WFSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isActive ? Color.accentColor.opacity(0.15) : Color.clear)
                    )
                    .contentShape(Rectangle())
                    .onHover { isHovered in
                        if isHovered {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .onTapGesture {
                        onSelect(workspace)
                    }
                }
            }
            .padding(WFSpacing.md)
        }
    }
}
