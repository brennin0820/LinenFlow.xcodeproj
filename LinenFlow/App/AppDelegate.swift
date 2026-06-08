import CoreLocation
import OSLog
import UIKit

/// Handles Chain C cold relaunch when iOS wakes the app for a location event (§5).
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        guard launchOptions?[.location] != nil else { return true }

        AppLogger.boot.info("Cold launch from location event — starting background reconciliation")
        Task { @MainActor in
            await HimmerFlowAppIntegration.handleColdLocationLaunch()
        }
        return true
    }
}
