import Testing
import Foundation
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

@Suite("OperationalShiftStateEngine")
struct OperationalShiftStateEngineTests {

    // MARK: - Start

    @Test("Start snapshot: opening pass with zero completions")
    func startSnapshot() {
        let snap = OperationalShiftStateEngine.snapshot(
            towerName: "Rainbow",
            floorCount: 10,
            completedFloors: 0,
            remainingFloors: 10,
            currentItemName: "Sheets",
            currentItemNames: nil,
            nextCarryGroupTitle: nil,
            targetTime: nil,
            statusText: "Ready",
            isActiveSession: true,
            isPausedSession: false
        )
        #expect(snap.semanticState == .openingPass)
        #expect(snap.isActiveSession == true)
        #expect(snap.isPaused == false)
        #expect(snap.isComplete == false)
        #expect(snap.progressFraction == 0.0)
        #expect(snap.completedFloors == 0)
        #expect(snap.remainingFloors == 10)
    }

    // MARK: - Pause

    @Test("Pause snapshot: state is paused with partial progress retained")
    func pauseSnapshot() {
        let snap = OperationalShiftStateEngine.snapshot(
            towerName: "Rainbow",
            floorCount: 10,
            completedFloors: 4,
            remainingFloors: 6,
            currentItemName: nil,
            currentItemNames: nil,
            nextCarryGroupTitle: nil,
            targetTime: nil,
            statusText: "Paused",
            isActiveSession: false,
            isPausedSession: true
        )
        #expect(snap.semanticState == .paused)
        #expect(snap.isPaused == true)
        #expect(snap.isComplete == false)
        #expect(snap.progressFraction == 0.4)
        #expect(snap.completedFloors == 4)
        #expect(snap.remainingFloors == 6)
    }

    // MARK: - Resume

    @Test("Resume snapshot: active run after pause clears paused state")
    func resumeSnapshot() {
        let snap = OperationalShiftStateEngine.snapshot(
            towerName: "Rainbow",
            floorCount: 10,
            completedFloors: 4,
            remainingFloors: 6,
            currentItemName: nil,
            currentItemNames: nil,
            nextCarryGroupTitle: nil,
            targetTime: nil,
            statusText: "Active",
            isActiveSession: true,
            isPausedSession: false
        )
        #expect(snap.semanticState == .activeRun)
        #expect(snap.isPaused == false)
        #expect(snap.isComplete == false)
        #expect(snap.isActiveSession == true)
        #expect(snap.progressFraction == 0.4)
    }

    // MARK: - Finish

    @Test("Finish snapshot: complete state with full progress fraction")
    func finishSnapshot() {
        let snap = OperationalShiftStateEngine.snapshot(
            towerName: "Rainbow",
            floorCount: 10,
            completedFloors: 10,
            remainingFloors: 0,
            currentItemName: nil,
            currentItemNames: nil,
            nextCarryGroupTitle: nil,
            targetTime: nil,
            statusText: "Done",
            isActiveSession: false
        )
        #expect(snap.semanticState == .complete)
        #expect(snap.isComplete == true)
        #expect(snap.isPaused == false)
        #expect(snap.progressFraction == 1.0)
        #expect(snap.completedFloors == 10)
        #expect(snap.remainingFloors == 0)
    }

    // MARK: - Urgency

    @Test("Urgency is inactive when no tower is loaded")
    func urgencyInactiveWithNoTower() {
        let urgency = OperationalShiftStateEngine.countdownUrgency(
            targetTime: nil, isComplete: false, hasTower: false
        )
        #expect(urgency == .inactive)
    }

    @Test("Urgency is complete regardless of target time when shift is done")
    func urgencyCompleteOverridesTime() {
        let futureTime = Date.now.addingTimeInterval(3600)
        let urgency = OperationalShiftStateEngine.countdownUrgency(
            targetTime: futureTime, isComplete: true, hasTower: true
        )
        #expect(urgency == .complete)
    }

    @Test("Urgency is critical when past target time")
    func urgencyCriticalWhenOvertime() {
        let pastTime = Date.now.addingTimeInterval(-60)
        let urgency = OperationalShiftStateEngine.countdownUrgency(
            targetTime: pastTime, isComplete: false, hasTower: true
        )
        #expect(urgency == .critical)
    }

    @Test("Urgency is calm when no target time is set")
    func urgencyCalmWithNoTargetTime() {
        let urgency = OperationalShiftStateEngine.countdownUrgency(
            targetTime: nil, isComplete: false, hasTower: true
        )
        #expect(urgency == .calm)
    }

    // MARK: - Tower name compaction

    @Test("Single-word tower name uses first 3 characters uppercased")
    func compactSingleWord() {
        #expect(OperationalShiftStateEngine.compactTowerName("Rainbow") == "RAI")
    }

    @Test("Two-word tower name returns initials of first two words")
    func compactTwoWords() {
        #expect(OperationalShiftStateEngine.compactTowerName("Grand Waikikian") == "GW")
    }

    @Test("Empty tower name returns HF fallback")
    func compactEmptyName() {
        #expect(OperationalShiftStateEngine.compactTowerName("") == "HF")
    }
}
