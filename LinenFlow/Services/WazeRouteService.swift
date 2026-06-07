import Foundation
import UIKit

enum WazeRouteService {
    enum DestinationMode {
        case favWork
        case favHome
        case searchAddress(String)
        case coordinates(lat: Double, lon: Double)
    }

    static func buildURL(mode: DestinationMode) -> URL? {
        switch mode {
        case .favWork:
            return URL(string: "https://waze.com/ul?favorite=work&navigate=yes")
        case .favHome:
            return URL(string: "https://waze.com/ul?favorite=home&navigate=yes")
        case .searchAddress(let query):
            var components = URLComponents(string: "https://waze.com/ul")
            components?.queryItems = [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "navigate", value: "yes")
            ]
            return components?.url
        case .coordinates(let lat, let lon):
            var components = URLComponents(string: "https://www.waze.com/ul")
            components?.queryItems = [
                URLQueryItem(name: "ll", value: "\(lat),\(lon)"),
                URLQueryItem(name: "navigate", value: "yes"),
                URLQueryItem(name: "zoom", value: "17")
            ]
            return components?.url
        }
    }

    @MainActor
    static func openWaze(mode: DestinationMode) {
        guard let url = buildURL(mode: mode) else { return }
        UIApplication.shared.open(url)
    }
}
