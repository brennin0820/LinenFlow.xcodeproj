import Foundation

@MainActor
protocol FloorTrackingManager: AnyObject {
    var currentState: FloorTrackingState { get }

    func startTracking(towerName: String, startingFloor: Int)
    func stopTracking()
    func moveUpOneFloor()
    func moveDownOneFloor()
    func setCurrentFloor(_ floor: Int)
    func resetTracking()
}
