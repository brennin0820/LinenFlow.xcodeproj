import Foundation
import UserNotifications
@testable import HimmerFlow
import LinenFlowCore
import LinenFlowEngine
import LinenFlowUI

final class MockNotificationService: NotificationServiceProtocol, @unchecked Sendable {
    private(set) var scheduled: [UNNotificationRequest] = []
    private(set) var cancelledIDs: [String] = []
    private(set) var didCancelAll = false

    func scheduledNotificationCount() async -> Int { scheduled.count }

    func pendingIdentifiers() async -> [String] { scheduled.map(\.identifier) }

    func schedule(_ request: UNNotificationRequest) async throws {
        scheduled.removeAll { $0.identifier == request.identifier }
        scheduled.append(request)
    }

    func cancel(identifiers: [String]) async {
        cancelledIDs.append(contentsOf: identifiers)
        scheduled.removeAll { identifiers.contains($0.identifier) }
    }

    func cancelAll() async {
        didCancelAll = true
        scheduled.removeAll()
    }

    func registerCategories() async {}
}
