import Foundation
import SwiftData

enum LinenItemDisplayGroup: String, Codable, CaseIterable, Sendable {
    case bath
    case bedding
    case specialty

    var displayName: String {
        switch self {
        case .bath: return "Bath Linen"
        case .bedding: return "Bedding"
        case .specialty: return "Specialty"
        }
    }

    var subtitle: String {
        switch self {
        case .bath: return "Towels, mats, washcloths"
        case .bedding: return "Sheets, covers, pillow cases"
        case .specialty: return "Tower-specific supply"
        }
    }

    var systemImage: String {
        switch self {
        case .bath: return "drop.fill"
        case .bedding: return "bed.double.fill"
        case .specialty: return "staroflife.fill"
        }
    }

    var sortOrder: Int {
        switch self {
        case .bath: return 0
        case .bedding: return 1
        case .specialty: return 2
        }
    }
}

@Model
final class LinenItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var parCount: Int
    var countMethodRaw: String
    var bundleSize: Int
    var piecesPerBin: Int?
    private var allowedTowerNamesData: Data?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    var availabilityScopeRaw: String = ItemAvailabilityScope.allTowers.rawValue

    var availabilityScope: ItemAvailabilityScope {
        get { ItemAvailabilityScope(rawValue: availabilityScopeRaw) ?? .allTowers }
        set { availabilityScopeRaw = newValue.rawValue }
    }

    var countMethod: CountMethod {
        get { CountMethod(rawValue: countMethodRaw) ?? .manualPieces }
        set { countMethodRaw = newValue.rawValue }
    }

    var displayGroup: LinenItemDisplayGroup {
        let normalized = name.lowercased()
        if normalized.contains("towel") || normalized.contains("mat") || normalized.contains("washcloth") {
            return .bath
        }
        if normalized.contains("sheet") || normalized.contains("cover") || normalized.contains("pillow") {
            return .bedding
        }
        return .specialty
    }

    var allowedTowerNames: [String] {
        get {
            guard let data = allowedTowerNamesData,
                  let names = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return names
        }
        set {
            allowedTowerNamesData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        parCount: Int,
        countMethod: CountMethod,
        bundleSize: Int,
        piecesPerBin: Int? = nil,
        allowedTowerNames: [String] = [],
        availabilityScope: ItemAvailabilityScope = .allTowers,
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.parCount = parCount
        self.countMethodRaw = countMethod.rawValue
        self.bundleSize = bundleSize
        self.piecesPerBin = piecesPerBin
        self.allowedTowerNamesData = (try? JSONEncoder().encode(allowedTowerNames))
        self.availabilityScopeRaw = availabilityScope.rawValue
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
