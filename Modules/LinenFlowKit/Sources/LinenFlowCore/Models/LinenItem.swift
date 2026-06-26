import Foundation
import SwiftData

public enum LinenItemDisplayGroup: String, Codable, CaseIterable, Sendable {
    case bath
    case bedding
    case specialty

    public var displayName: String {
        switch self {
        case .bath: return "Bath Linen"
        case .bedding: return "Bedding"
        case .specialty: return "Specialty"
        }
    }

    public var subtitle: String {
        switch self {
        case .bath: return "Towels, mats, washcloths"
        case .bedding: return "Sheets, covers, pillow cases"
        case .specialty: return "Tower-specific supply"
        }
    }

    public var systemImage: String {
        switch self {
        case .bath: return "drop.fill"
        case .bedding: return "bed.double.fill"
        case .specialty: return "staroflife.fill"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .bath: return 0
        case .bedding: return 1
        case .specialty: return 2
        }
    }
}

@Model
public final class LinenItem {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var parCount: Int
    public var countMethodRaw: String
    public var bundleSize: Int
    public var piecesPerBin: Int?
    private var allowedTowerNamesData: Data?
    public var isActive: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public var availabilityScopeRaw: String = ItemAvailabilityScope.allTowers.rawValue

    public var availabilityScope: ItemAvailabilityScope {
        get { ItemAvailabilityScope(rawValue: availabilityScopeRaw) ?? .allTowers }
        set { availabilityScopeRaw = newValue.rawValue }
    }

    public var countMethod: CountMethod {
        get { CountMethod(rawValue: countMethodRaw) ?? .manualPieces }
        set { countMethodRaw = newValue.rawValue }
    }

    public var displayGroup: LinenItemDisplayGroup {
        let normalized = name.lowercased()
        if normalized.contains("towel") || normalized.contains("mat") || normalized.contains("washcloth") {
            return .bath
        }
        if normalized.contains("sheet") || normalized.contains("cover") || normalized.contains("pillow") {
            return .bedding
        }
        return .specialty
    }

    public var allowedTowerNames: [String] {
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

    public init(
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
