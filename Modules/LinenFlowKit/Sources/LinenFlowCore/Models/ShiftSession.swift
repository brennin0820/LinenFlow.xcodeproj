import Foundation

public struct ShiftSession: Identifiable, Hashable, Sendable {
    public var id: UUID
    public var towerName: String?
    public var floorCount: Int
    public var shiftStartTime: Date
    public var targetDownTime: Date
    public var expectedShiftEndTime: Date
    public var actualFinishTime: Date?
    public var deliveryStartedAt: Date?
    public var deliveryPausedAt: Date?
    public var completedFloors: Set<Int>
    public var remainingFloors: [Int]
    public var totalFloors: Int
    public var estimatedFinishTime: Date?
    public var estimatedMinutesRemaining: Int
    public var isBehindPace: Bool
    public var activeItemFocus: String?
    public var activeTrip: ElevatorTrip?
    public var remainingBundles: Int
    public var averageFloorCompletionMinutes: Double
    public var paceStatus: PaceStatus
    public var recommendedNextAction: String

    public init(
        id: UUID = UUID(),
        towerName: String? = nil,
        floorCount: Int = 0,
        selectedTower: String? = nil,
        shiftStartTime: Date,
        targetDownTime: Date,
        expectedShiftEndTime: Date,
        actualFinishTime: Date? = nil,
        deliveryStartedAt: Date? = nil,
        deliveryPausedAt: Date? = nil,
        completedFloors: Set<Int> = [],
        remainingFloors: [Int] = [],
        totalFloors: Int = 0,
        estimatedFinishTime: Date? = nil,
        estimatedMinutesRemaining: Int = 0,
        isBehindPace: Bool = false,
        activeItemFocus: String? = nil,
        activeTrip: ElevatorTrip? = nil,
        remainingBundles: Int = 0,
        averageFloorCompletionMinutes: Double = 0,
        paceStatus: PaceStatus = .notStarted,
        recommendedNextAction: String = "Start delivery when ready."
    ) {
        self.id = id
        self.towerName = towerName ?? selectedTower
        self.floorCount = floorCount
        self.shiftStartTime = shiftStartTime
        self.targetDownTime = targetDownTime
        self.expectedShiftEndTime = expectedShiftEndTime
        self.actualFinishTime = actualFinishTime
        self.deliveryStartedAt = deliveryStartedAt
        self.deliveryPausedAt = deliveryPausedAt
        self.completedFloors = completedFloors
        self.remainingFloors = remainingFloors
        self.totalFloors = totalFloors
        self.estimatedFinishTime = estimatedFinishTime
        self.estimatedMinutesRemaining = estimatedMinutesRemaining
        self.isBehindPace = isBehindPace
        self.activeItemFocus = activeItemFocus
        self.activeTrip = activeTrip
        self.remainingBundles = remainingBundles
        self.averageFloorCompletionMinutes = averageFloorCompletionMinutes
        self.paceStatus = paceStatus
        self.recommendedNextAction = recommendedNextAction
    }

    public var estimatedCompletionTime: Date? {
        get { estimatedFinishTime }
        set { estimatedFinishTime = newValue }
    }

    public var selectedTower: String? {
        get { towerName }
        set { towerName = newValue }
    }
}

public enum PaceStatus: String, CaseIterable, Hashable, Sendable {
    case ahead
    case onPace
    case behind
    case notStarted

    public var displayName: String {
        switch self {
        case .ahead: return "Ahead"
        case .onPace: return "On Pace"
        case .behind: return "Behind"
        case .notStarted: return "Not Started"
        }
    }

    public var alertText: String {
        switch self {
        case .ahead: return "You are ahead of pace."
        case .onPace: return "You are on pace."
        case .behind: return "You are behind target."
        case .notStarted: return "Start delivery to track live pace."
        }
    }
}

public typealias DeliveryPaceStatus = PaceStatus
