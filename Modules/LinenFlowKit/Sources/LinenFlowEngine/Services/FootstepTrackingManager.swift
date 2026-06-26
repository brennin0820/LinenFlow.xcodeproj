import Foundation
import LinenFlowCore

@MainActor
public protocol FootstepTrackingManager: AnyObject {
    var currentStepState: FootstepTrackingState { get }

    func startStepTracking()
    func stopStepTracking()
    func resetSteps()
    func addManualSteps(_ count: Int)
    func subtractManualSteps(_ count: Int)
    func setCurrentFloor(_ floor: Int)
    func commitCurrentFloorSteps(floor: Int)
}
