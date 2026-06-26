import Foundation
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

final class MockLiveActivityService: LiveActivityServiceProtocol, @unchecked Sendable {
    var canStartFromBackground: Bool { false }
    private(set) var activeActivityID: String?
    private(set) var updates: [ShiftActivityContent] = []
    private(set) var ended = false

    func start(initialContent: ShiftActivityContent) throws -> String {
        let id = UUID().uuidString
        activeActivityID = id
        updates.append(initialContent)
        return id
    }

    func update(activityID: String, content: ShiftActivityContent) async {
        updates.append(content)
    }

    func end(activityID: String, finalContent: ShiftActivityContent) async {
        ended = true
        activeActivityID = nil
    }
}
