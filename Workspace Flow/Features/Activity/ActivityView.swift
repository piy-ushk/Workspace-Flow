import SwiftUI
import SwiftData

struct ActivityView: View {
    @Environment(AppState.self) var appState
    @Environment(\.modelContext) var modelContext
    @Query(sort: \ActivityEvent.timestamp, order: .reverse) var events: [ActivityEvent]
    @State private var showClearAlert = false

    var body: some View {
        Group {
            if events.isEmpty {
                WFEmptyState(
                    icon: "clock.arrow.circlepath",
                    title: "No activity yet",
                    subtitle: "Restore a workspace to see results here."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedEvents.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(sectionHeader(date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ) {
                            ForEach(groupedEvents[date] ?? []) { event in
                                ActivityRowView(event: event)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Activity")
        .toolbar {
            if !events.isEmpty {
                ToolbarItem {
                    Button("Clear History") { showClearAlert = true }
                        .foregroundStyle(.red)
                }
            }
        }
        .alert("Clear Activity History?", isPresented: $showClearAlert) {
            Button("Clear All", role: .destructive) {
                appState.activityLog.clearAll(in: modelContext)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("All activity records will be permanently removed.")
        }
    }

    private var groupedEvents: [Date: [ActivityEvent]] {
        let calendar = Calendar.current
        return Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.timestamp)
        }
    }

    private func sectionHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide).month().day())
    }
}

struct ActivityRowView: View {
    let event: ActivityEvent

    var body: some View {
        HStack(spacing: WFSpacing.md) {
            // Event icon
            Image(systemName: event.eventType.icon)
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: event.eventType.color))
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(Color(hex: event.eventType.color).opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(event.summary)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)

                HStack(spacing: WFSpacing.sm) {
                    Text(event.timestamp.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if event.successCount > 0 || event.failureCount > 0 {
                        HStack(spacing: 3) {
                            if event.successCount > 0 {
                                Label("\(event.successCount)", systemImage: "checkmark")
                                    .font(.caption2)
                                    .foregroundStyle(Color(hex: "#34C759"))
                            }
                            if event.failureCount > 0 {
                                Label("\(event.failureCount)", systemImage: "xmark")
                                    .font(.caption2)
                                    .foregroundStyle(Color(hex: "#FF3B30"))
                            }
                        }
                    }
                }

                if let details = event.details {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ActivityView()
        .environment(AppState())
        .modelContainer(for: ActivityEvent.self, inMemory: true)
}
