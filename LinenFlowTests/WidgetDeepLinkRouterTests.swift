import XCTest
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

final class WidgetDeepLinkRouterTests: XCTestCase {

    // MARK: - Supported schemes

    func test_supportedSchemes_includesLinenflowAndHimmerflow() {
        XCTAssertTrue(WidgetDeepLink.supportedSchemes.contains("linenflow"))
        XCTAssertTrue(WidgetDeepLink.supportedSchemes.contains("himmerflow"))
    }

    func test_startRoute_himmerflowScheme() {
        let url = URL(string: "himmerflow://widget/start")!
        XCTAssertEqual(WidgetDeepLink.route(from: url), .start)
    }

    func test_startRoute_linenflowLegacyScheme() {
        let url = URL(string: "linenflow://widget/start")!
        XCTAssertEqual(WidgetDeepLink.route(from: url), .start)
    }

    func test_startRoute_caseInsensitiveSchemeAndPath() {
        let url = URL(string: "HimmerFlow://widget/START")!
        XCTAssertEqual(WidgetDeepLink.route(from: url), .start)
    }

    // MARK: - Delivery route

    func test_deliveryRoute_parsesTowerQuery() {
        let url = URL(string: "himmerflow://widget/delivery?tower=Lagoon")!
        XCTAssertEqual(WidgetDeepLink.route(from: url), .delivery(towerName: "Lagoon"))
    }

    func test_deliveryRoute_linenflowSchemeWithTower() {
        let url = URL(string: "linenflow://widget/delivery?tower=GW")!
        XCTAssertEqual(WidgetDeepLink.route(from: url), .delivery(towerName: "GW"))
    }

    func test_deliveryRoute_withoutTowerQuery() {
        let url = URL(string: "himmerflow://widget/delivery")!
        XCTAssertEqual(WidgetDeepLink.route(from: url), .delivery(towerName: nil))
    }

    func test_deliveryRoute_caseInsensitivePath() {
        let url = URL(string: "himmerflow://widget/DELIVERY?tower=Tapa")!
        XCTAssertEqual(WidgetDeepLink.route(from: url), .delivery(towerName: "Tapa"))
    }

    // MARK: - Rejected URLs

    func test_unsupportedScheme_returnsNil() {
        let url = URL(string: "https://widget/start")!
        XCTAssertNil(WidgetDeepLink.route(from: url))
    }

    func test_wrongHost_returnsNil() {
        let url = URL(string: "himmerflow://app/start")!
        XCTAssertNil(WidgetDeepLink.route(from: url))
    }

    func test_unknownPath_returnsNil() {
        let url = URL(string: "himmerflow://widget/settings")!
        XCTAssertNil(WidgetDeepLink.route(from: url))
    }

    func test_missingHost_returnsNil() {
        let url = URL(string: "himmerflow:///start")!
        XCTAssertNil(WidgetDeepLink.route(from: url))
    }
}
