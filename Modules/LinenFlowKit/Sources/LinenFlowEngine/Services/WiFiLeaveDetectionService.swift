import Foundation
import Network
import LinenFlowCore

// Detects possible Wi-Fi departure while the app is active in the foreground.
// This service does NOT guarantee reliable background detection.
// Time-based local notifications remain the primary and reliable leave reminder.
@Observable
public final class WiFiLeaveDetectionService {
    public var isMonitoring: Bool = false
    public var onPossibleLeaveDetected: (() -> Void)?

    private var monitor: NWPathMonitor?
    private var previouslyOnWifi = false
    private let monitorQueue = DispatchQueue(label: "himmerflow.wifi.monitor", qos: .utility)

    public func startMonitoring() {
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

    public func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
        isMonitoring = false
    }

    deinit {
        monitor?.cancel()
    }
}
