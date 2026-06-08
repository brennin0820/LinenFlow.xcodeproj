import UIKit

/// Cold-launch location events are delivered to `LocationService`'s `CLLocationManagerDelegate`
/// after scene connection, per iOS 26 guidance (Chain C, §5).
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        true
    }
}
