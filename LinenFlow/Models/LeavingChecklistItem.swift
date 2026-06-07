import Foundation

struct LeavingChecklistItem: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var isEnabled: Bool = true
    var sortOrder: Int
    var createdAt: Date = .now
    var updatedAt: Date = .now
}
