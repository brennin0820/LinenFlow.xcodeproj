import Foundation

public struct LeavingChecklistItem: Codable, Identifiable, Hashable {
    public var id: UUID = UUID()
    public var title: String
    public var isEnabled: Bool = true
    public var sortOrder: Int
    public var createdAt: Date = .now
    public var updatedAt: Date = .now
}
