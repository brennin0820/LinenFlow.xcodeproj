import Foundation
import Observation

enum WidgetDeepLink {
    static let supportedSchemes: Set<String> = ["linenflow", "himmerflow"]

    enum Route: Equatable {
        case start
        case delivery(towerName: String?)
    }

    static func route(from url: URL) -> Route? {
        guard let scheme = url.scheme?.lowercased(), supportedSchemes.contains(scheme) else {
            return nil
        }
        guard url.host?.lowercased() == "widget" else {
            return nil
        }

        switch url.path.lowercased() {
        case "/start":
            return .start
        case "/delivery":
            let towerName = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "tower" })?
                .value
            return .delivery(towerName: towerName)
        default:
            return nil
        }
    }
}

@Observable
@MainActor
final class WidgetDeepLinkCoordinator {
    enum Tab: Hashable {
        case home
        case shift
        case insights
        case logs
        case settings
    }

    var selectedTab: Tab = .home
    var openDeliveryCommandCenter = false

    func handle(_ url: URL, flowViewModel: FlowViewModel) {
        guard let route = WidgetDeepLink.route(from: url) else { return }

        switch route {
        case .start:
            selectedTab = .home
            openDeliveryCommandCenter = false
        case .delivery(let towerName):
            if let towerName,
               let tower = flowViewModel.availableTowers.first(where: { $0.name == towerName }) {
                flowViewModel.selectTower(tower)
            }
            selectedTab = .home
            openDeliveryCommandCenter = true
        }
    }

    func consumeDeliveryCommandCenterRequest() {
        openDeliveryCommandCenter = false
    }
}
