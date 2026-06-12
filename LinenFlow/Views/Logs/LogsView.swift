import SwiftUI
import SwiftData
import OSLog

struct LogsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date, order: .reverse) private var logs: [DailyLog]
    @State private var filter: LogFilter = .all

    var body: some View {
        AppBackground {
            ScrollView {
                VStack(spacing: 14) {
                    filterBar

                    if filteredLogs.isEmpty {
                        EmptyStateView(
                            systemImage: "doc.text.magnifyingglass",
                            title: logs.isEmpty ? "No logs yet" : "No logs match this filter",
                            message: logs.isEmpty
                                ? "Saved logs from Results or Floor Plan will appear here."
                                : "Try a different tower filter."
                        )
                    } else {
                        VStack(spacing: 0) {
                            ForEach(filteredLogs) { log in
                                NavigationLink(value: LogRoute.detail(id: log.id)) {
                                    LogRow(log: log)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(log)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                if log.id != filteredLogs.last?.id {
                                    Divider()
                                        .overlay(Color.white.opacity(0.07))
                                        .padding(.leading, 14)
                                }
                            }
                        }
                        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Daily Logs")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: LogRoute.self) { route in
            switch route {
            case .detail(let id):
                if let log = logs.first(where: { $0.id == id }) {
                    LogDetailView(log: log)
                } else {
                    EmptyStateView(
                        systemImage: "exclamationmark.triangle",
                        title: "Log not found",
                        message: "It may have been deleted."
                    )
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LogFilter.allCases) { f in
                    Button {
                        filter = f
                    } label: {
                        Text(f.label)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                filter == f ? Color.blue.opacity(0.25) : Color.white.opacity(0.06),
                                in: Capsule()
                            )
                            .foregroundStyle(filter == f ? .white : .white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var filteredLogs: [DailyLog] {
        LogFilterBuilder.filter(logs, by: filter)
    }

    private func delete(_ log: DailyLog) {
        modelContext.delete(log)
        do {
            try modelContext.save()
        } catch {
            AppLogger.logs.error("Log delete save failed: \(error, privacy: .public)")
        }
    }
}

enum LogRoute: Hashable {
    case detail(id: UUID)
}

// MARK: - Card

private struct LogRow: View {
    let log: DailyLog

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accent ?? .blue)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(log.towerName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(log.entriesSnapshot.count) items")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.56))
                    Spacer()
                    Text(log.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.48))
                        .lineLimit(1)
                }

                let counts = statusCounts
                HStack(spacing: 10) {
                    statusPill("Short", count: counts.short, color: .red)
                    statusPill("Enough", count: counts.over, color: .green)
                    statusPill("Exact", count: counts.exact, color: .blue)
                    Spacer()
                    Text("\(log.floorCount) floors")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }

                if !log.notes.isEmpty {
                    Text(log.notes)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.28))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(log.towerName), \(log.entriesSnapshot.count) items, \(log.floorCount) floors, \(log.date.formatted(date: .abbreviated, time: .shortened))")
        .accessibilityHint("Double tap to view log details.")
    }

    private func statusPill(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text("\(count) \(label)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private var statusCounts: (short: Int, over: Int, exact: Int) {
        let s = log.summarySnapshot
        return (
            s.filter { $0.status == .shortage }.count,
            s.filter { $0.status == .overage }.count,
            s.filter { $0.status == .exact }.count
        )
    }

    private var accent: Color? {
        // Use the brand colour from seed data if available
        DefaultData.towers.first(where: { $0.name == log.towerName })
            .flatMap { Color(hex: $0.identityColorHex ?? "") }
    }
}
