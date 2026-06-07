import Foundation
import Observation

@MainActor
protocol MovementProvider: AnyObject {
    var source: MovementSensingSource { get }
    var latestSignal: MovementSignal? { get }
    var confidence: MovementConfidence { get }
    var isAvailable: Bool { get }
    var unavailableReason: String? { get }

    func start()
    func stop()
    func reset()
}

@Observable
@MainActor
final class MovementSensingCoordinator {
    private let watchProvider: MovementProvider
    private let phoneProvider: MovementProvider
    private let manualProvider: MovementProvider

    private(set) var activeSource: MovementSensingSource = .manualOnly
    private(set) var latestSignal: MovementSignal?
    private(set) var confidence: MovementConfidence = .low
    private(set) var fallbackReason: String?
    private(set) var isTracking = false

    init() {
        self.watchProvider = WatchMovementProvider()
        self.phoneProvider = PhoneMovementProvider()
        self.manualProvider = MockMovementProvider()
        selectProvider()
    }

    init(
        watchProvider: MovementProvider,
        phoneProvider: MovementProvider,
        manualProvider: MovementProvider
    ) {
        self.watchProvider = watchProvider
        self.phoneProvider = phoneProvider
        self.manualProvider = manualProvider
        selectProvider()
    }

    func startTracking() {
        isTracking = true
        let provider = selectProvider()
        provider.start()
        sync(from: provider)
    }

    func stopTracking() {
        isTracking = false
        watchProvider.stop()
        phoneProvider.stop()
        manualProvider.stop()
        selectProvider()
    }

    func reset() {
        isTracking = false
        watchProvider.reset()
        phoneProvider.reset()
        manualProvider.reset()
        latestSignal = nil
        selectProvider()
    }

    @discardableResult
    private func selectProvider() -> MovementProvider {
        let selected: MovementProvider
        if watchProvider.isAvailable {
            selected = watchProvider
            fallbackReason = nil
        } else if phoneProvider.isAvailable {
            selected = phoneProvider
            fallbackReason = watchProvider.unavailableReason
        } else {
            selected = manualProvider
            fallbackReason = phoneProvider.unavailableReason ?? watchProvider.unavailableReason ?? "Live movement sensors unavailable. Using manual tracking."
        }

        sync(from: selected)
        return selected
    }

    private func sync(from provider: MovementProvider) {
        activeSource = provider.source
        latestSignal = provider.latestSignal
        confidence = provider.confidence
    }
}

/*
 Future intelligent floor detection design:
 Landed Floor = vertical movement stopped and altitude stabilized.
 Worked Floor = landed floor plus steps or dwell time.
 Delivered Floor = user-confirmed delivery checklist state.

 Apple Watch helps confirm body movement and steps.
 iPhone barometer helps estimate vertical movement.
 Manual confirmation remains required for reliability.
 */
