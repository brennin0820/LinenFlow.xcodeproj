import Foundation
import Network

// Detects possible Wi-Fi departure while the app is active in the foreground.
// This service does NOT guarantee reliable background detection.
// Time-based local notifications remain the primary and reliable leave reminder.
@Observable
final class WiFiLeaveDetectionService {
    var isMonitoring: Bool = false
    var onPossibleLeaveDetected: (() -> Void)?

    private var monitor: NWPathMonitor?
    private var previouslyOnWifi = false
    private let monitorQueue = DispatchQueue(label: "himmerflow.wifi.monitor", qos: .utility)

    func startMonitoring() {
        guard !isMonitoring else { return }
        let m = NWPathMonitor()
        m.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let onWifi = path.usesInterfaceType(.wifi)
            let wasOnWifi = self.previouslyOnWifi
            self.previouslyOnWifi = onWifi
            if wasOnWifi && !onWifi {
                DispatchQueue.main.async {
                    self.onPossibleLeaveDetected?()
                }
            }
        }
        m.start(queue: monitorQueue)
        monitor = m
        isMonitoring = true
    }

    func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
        isMonitoring = false
    }

    deinit {
        monitor?.cancel()
    }
}
