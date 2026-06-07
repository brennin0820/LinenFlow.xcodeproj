import Foundation
import OSLog
import SwiftData

@MainActor
enum SeedService {
    static func seedIfNeeded(context: ModelContext, isCustomProperty: Bool = false) {
        if !isCustomProperty {
            seedTowers(context: context)
        }
        seedLinenItems(context: context, isCustomProperty: isCustomProperty)
        do {
            try context.save()
        } catch {
            AppLogger.seed.error("Seed save failed: \(error, privacy: .public)")
        }
    }

    private static func seedTowers(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Tower>())) ?? []
        let existingByName = Dictionary(uniqueKeysWithValues: existing.map { ($0.name, $0) })

        for tower in DefaultData.towers {
            if let existingTower = existingByName[tower.name] {
                var didChange = false
                if existingTower.identityColorHex != tower.identityColorHex {
                    existingTower.identityColorHex = tower.identityColorHex
                    didChange = true
                }
                if existingTower.deliveryMode != tower.deliveryMode {
                    existingTower.deliveryMode = tower.deliveryMode
                    didChange = true
                }
                if existingTower.allowsDoubleItems != tower.allowsDoubleItems {
                    existingTower.allowsDoubleItems = tower.allowsDoubleItems
                    didChange = true
                }
                if ["GI", "GW", "Tapa", "Diamond", "Alii"].contains(existingTower.name),
                   existingTower.floorCount != tower.floorCount {
                    existingTower.floorCount = tower.floorCount
                    didChange = true
                }
                // Initialize the editable floor range only when the tower has
                // never been configured. Once a user edits start/top, those
                // values persist and seeding leaves them alone.
                if existingTower.startFloor < 1 || existingTower.topFloor < existingTower.startFloor {
                    if tower.startFloor >= 1, tower.topFloor >= tower.startFloor {
                        existingTower.startFloor = tower.startFloor
                        existingTower.topFloor = tower.topFloor
                        existingTower.skip13thFloor = tower.skip13thFloor
                        didChange = true
                    } else if existingTower.floorCount > 0 {
                        existingTower.startFloor = 1
                        existingTower.topFloor = existingTower.floorCount
                        existingTower.skip13thFloor = false
                        didChange = true
                    }
                }
                // Apply calibration data only when the tower still has the default "Unknown" confidence,
                // preserving any values the user may have manually adjusted.
                if existingTower.towerDataConfidence == "Unknown",
                   let cal = DefaultData.towerCalibrations[tower.name] {
                    existingTower.estimatedFloorHeightMeters = cal.estimatedFloorHeightMeters
                    existingTower.floorDetectionToleranceMeters = cal.floorDetectionToleranceMeters
                    existingTower.floorMovementConfidenceThresholdMeters = cal.floorMovementConfidenceThresholdMeters
                    existingTower.latitude = cal.latitude
                    existingTower.longitude = cal.longitude
                    existingTower.towerDataConfidence = cal.confidence
                    existingTower.towerDataNotes = cal.notes
                    didChange = true
                }
                if didChange {
                    existingTower.updatedAt = .now
                }
            } else {
                let cal = DefaultData.towerCalibrations[tower.name]
                context.insert(Tower(
                    name: tower.name,
                    floorCount: tower.floorCount,
                    identityColorHex: tower.identityColorHex,
                    deliveryMode: tower.deliveryMode,
                    allowsDoubleItems: tower.allowsDoubleItems,
                    startFloor: tower.startFloor,
                    topFloor: tower.topFloor,
                    skip13thFloor: tower.skip13thFloor,
                    estimatedFloorHeightMeters: cal?.estimatedFloorHeightMeters ?? 3.1,
                    floorDetectionToleranceMeters: cal?.floorDetectionToleranceMeters ?? 0.45,
                    floorMovementConfidenceThresholdMeters: cal?.floorMovementConfidenceThresholdMeters ?? 1.2,
                    latitude: cal?.latitude,
                    longitude: cal?.longitude,
                    towerDataConfidence: cal?.confidence ?? "Unknown",
                    towerDataNotes: cal?.notes
                ))
            }
        }
    }

    private static func seedLinenItems(context: ModelContext, isCustomProperty: Bool) {
        let existing = (try? context.fetch(FetchDescriptor<LinenItem>())) ?? []
        let existingNames = Set(existing.map { $0.name })

        for item in DefaultData.linenItems {
            let effectiveScope = isCustomProperty ? ItemAvailabilityScope.allTowers : item.availabilityScope
            let effectiveAllowedTowers = isCustomProperty ? [] : item.allowedTowerNames

            if let existingItem = existing.first(where: { $0.name == item.name }) {
                var didChange = false
                if existingItem.parCount <= 0 {
                    existingItem.parCount = item.parCount
                    didChange = true
                }
                if existingItem.bundleSize <= 0 {
                    existingItem.bundleSize = item.bundleSize
                    didChange = true
                }
                if existingItem.countMethodRaw.isEmpty {
                    existingItem.countMethod = item.countMethod
                    didChange = true
                }
                if item.countMethod == .fixedBin, existingItem.piecesPerBin == nil {
                    existingItem.piecesPerBin = item.piecesPerBin
                    didChange = true
                }
                if existingItem.availabilityScope != effectiveScope {
                    existingItem.availabilityScope = effectiveScope
                    didChange = true
                }
                if existingItem.allowedTowerNames != effectiveAllowedTowers {
                    existingItem.allowedTowerNames = effectiveAllowedTowers
                    didChange = true
                }
                // Migrate legacy items: if they have allowedTowerNames but scope is still allTowers
                if !isCustomProperty && !existingItem.allowedTowerNames.isEmpty && existingItem.availabilityScope == .allTowers {
                    existingItem.availabilityScope = .selectedTowers
                    didChange = true
                }
                if didChange {
                    existingItem.updatedAt = .now
                }
            } else if !existingNames.contains(item.name) {
                context.insert(LinenItem(
                    name: item.name,
                    parCount: item.parCount,
                    countMethod: item.countMethod,
                    bundleSize: item.bundleSize,
                    piecesPerBin: item.piecesPerBin,
                    allowedTowerNames: effectiveAllowedTowers,
                    availabilityScope: effectiveScope
                ))
            }
        }
    }
}
