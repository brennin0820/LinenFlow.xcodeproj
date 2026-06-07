import Foundation
import SwiftData

@Model
final class DailyLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var towerName: String
    var floorCount: Int
    private var entriesData: Data
    private var summariesData: Data
    private var distributionData: Data
    var notes: String
    var createdAt: Date

    var entriesSnapshot: [ReceivingEntry] {
        (try? JSONDecoder().decode([ReceivingEntry].self, from: entriesData)) ?? []
    }

    var summarySnapshot: [CalculationSummary] {
        (try? JSONDecoder().decode([CalculationSummary].self, from: summariesData)) ?? []
    }

    var distributionSnapshot: [FloorDistributionRow] {
        (try? JSONDecoder().decode([FloorDistributionRow].self, from: distributionData)) ?? []
    }

    init(
        id: UUID = UUID(),
        date: Date,
        towerName: String,
        floorCount: Int,
        entriesSnapshot: [ReceivingEntry],
        summarySnapshot: [CalculationSummary],
        distributionSnapshot: [FloorDistributionRow],
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.towerName = towerName
        self.floorCount = floorCount
        self.entriesData = (try? JSONEncoder().encode(entriesSnapshot)) ?? Data()
        self.summariesData = (try? JSONEncoder().encode(summarySnapshot)) ?? Data()
        self.distributionData = (try? JSONEncoder().encode(distributionSnapshot)) ?? Data()
        self.notes = notes
        self.createdAt = createdAt
    }

    /// Overwrites all snapshot data so the same log record can be reused for
    /// multiple saves on the same calendar day.
    func update(
        floorCount: Int,
        entriesSnapshot: [ReceivingEntry],
        summarySnapshot: [CalculationSummary],
        distributionSnapshot: [FloorDistributionRow],
        notes: String
    ) {
        self.floorCount = floorCount
        self.entriesData = (try? JSONEncoder().encode(entriesSnapshot)) ?? Data()
        self.summariesData = (try? JSONEncoder().encode(summarySnapshot)) ?? Data()
        self.distributionData = (try? JSONEncoder().encode(distributionSnapshot)) ?? Data()
        self.notes = notes
        self.date = .now
    }
}
