import Foundation
import SwiftData

@Model
public final class DailyLog {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var towerName: String
    public var floorCount: Int
    private var entriesData: Data
    private var summariesData: Data
    private var distributionData: Data
    public var notes: String
    public var createdAt: Date

    public var entriesSnapshot: [ReceivingEntry] {
        (try? JSONDecoder().decode([ReceivingEntry].self, from: entriesData)) ?? []
    }

    public var summarySnapshot: [CalculationSummary] {
        (try? JSONDecoder().decode([CalculationSummary].self, from: summariesData)) ?? []
    }

    public var distributionSnapshot: [FloorDistributionRow] {
        (try? JSONDecoder().decode([FloorDistributionRow].self, from: distributionData)) ?? []
    }

    public init(
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
    public func update(
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
