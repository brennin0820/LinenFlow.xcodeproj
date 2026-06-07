import Foundation

struct ShiftSession: Identifiable, Hashable, Sendable {
    var id: UUID
    var towerName: String?
    var floorCount: Int
    var shiftStartTime: Date
    var targetDownTime: Date
    var expectedShiftEndTime: Date
    var actualFinishTime: Date?
    var deliveryStartedAt: Date?
    var deliveryPausedAt: Date?
    var completedFloors: Set<Int>
    var remainingFloors: [Int]
    var totalFloors: Int
    var estimatedFinishTime: Date?
    var estimatedMinutesRemaining: Int
    var isBehindPace: Bool
    var activeItemFocus: String?
    var activeTrip: ElevatorTrip?
    var remainingBundles: Int
    var averageFloorCompletionMinutes: Double
    var paceStatus: PaceStatus
    var recommendedNextAction: String

    init(
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

    var estimatedCompletionTime: Date? {
        get { estimatedFinishTime }
        set { estimatedFinishTime = newValue }
    }

    var selectedTower: String? {
        get { towerName }
        set { towerName = newValue }
    }
}

enum PaceStatus: String, CaseIterable, Hashable, Sendable {
    case ahead
    case onPace
    case behind
    case notStarted

    var displayName: String {
        switch self {
        case .ahead: return "Ahead"
        case .onPace: return "On Pace"
        case .behind: return "Behind"
        case .notStarted: return "Not Started"
        }
    }

    var alertText: String {
        switch self {
        case .ahead: return "You are ahead of pace."
        case .onPace: return "You are on pace."
        case .behind: return "You are behind target."
        case .notStarted: return "Start delivery to track live pace."
        }
    }
}

typealias DeliveryPaceStatus = PaceStatus
