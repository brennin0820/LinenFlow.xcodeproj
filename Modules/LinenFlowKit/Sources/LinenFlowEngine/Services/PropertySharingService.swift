import Foundation
import SwiftData
import CoreImage.CIFilterBuiltins
import UIKit
import LinenFlowCore

public enum PropertySharingError: LocalizedError {
    case invalidBase64
    case decompressionFailed
    case decodingFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidBase64:
            return "The configuration code is invalid or missing characters."
        case .decompressionFailed:
            return "Failed to decompress the configuration code."
        case .decodingFailed:
            return "Failed to read the configuration. It may be corrupt or from an incompatible version."
        }
    }
}

@MainActor
public final class PropertySharingService {
    
    public static func exportConfiguration(towers: [Tower], items: [LinenItem]) throws -> String {
        let exportTowers = towers.map { tower in
            TowerExport(
                name: tower.name,
                floorCount: tower.floorCount,
                isActive: tower.isActive,
                identityColorHex: tower.identityColorHex,
                deliveryModeRaw: tower.deliveryModeRaw,
                allowsDoubleItems: tower.allowsDoubleItems,
                startFloor: tower.startFloor,
                topFloor: tower.topFloor,
                skip13thFloor: tower.skip13thFloor,
                estimatedFloorHeightMeters: tower.estimatedFloorHeightMeters,
                floorDetectionToleranceMeters: tower.floorDetectionToleranceMeters,
                floorMovementConfidenceThresholdMeters: tower.floorMovementConfidenceThresholdMeters,
                latitude: tower.latitude,
                longitude: tower.longitude,
                towerDataConfidence: tower.towerDataConfidence,
                towerDataNotes: tower.towerDataNotes
            )
        }
        
        let exportItems = items.map { item in
            LinenItemExport(
                name: item.name,
                parCount: item.parCount,
                countMethodRaw: item.countMethodRaw,
                bundleSize: item.bundleSize,
                piecesPerBin: item.piecesPerBin,
                isActive: item.isActive,
                availabilityScopeRaw: item.availabilityScopeRaw,
                allowedTowerNames: item.allowedTowerNames
            )
        }
        
        let exportObj = PropertyExport(towers: exportTowers, linenItems: exportItems)
        let data = try JSONEncoder().encode(exportObj)
        let compressed = try (data as NSData).compressed(using: .lzfse)
        return compressed.base64EncodedString()
    }
    
    public static func importConfiguration(from base64: String, context: ModelContext) throws {
        // Strip out any accidental whitespaces when users copy/paste
        let cleanBase64 = base64.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let compressedData = Data(base64Encoded: cleanBase64) else {
            throw PropertySharingError.invalidBase64
        }
        
        let data: Data
        do {
            data = try (compressedData as NSData).decompressed(using: .lzfse) as Data
        } catch {
            throw PropertySharingError.decompressionFailed
        }
        
        let exportObj: PropertyExport
        do {
            exportObj = try JSONDecoder().decode(PropertyExport.self, from: data)
        } catch {
            throw PropertySharingError.decodingFailed
        }
        
        // Securely wipe existing state
        try? context.delete(model: DailyLog.self)
        try? context.delete(model: LinenItem.self)
        try? context.delete(model: Tower.self)
        try? context.save() // ensure wiped before inserting
        
        for tExport in exportObj.towers {
            let tower = Tower(
                name: tExport.name,
                floorCount: tExport.floorCount,
                isActive: tExport.isActive,
                identityColorHex: tExport.identityColorHex,
                deliveryMode: TowerDeliveryMode(rawValue: tExport.deliveryModeRaw) ?? .bundles,
                allowsDoubleItems: tExport.allowsDoubleItems,
                startFloor: tExport.startFloor,
                topFloor: tExport.topFloor,
                skip13thFloor: tExport.skip13thFloor,
                estimatedFloorHeightMeters: tExport.estimatedFloorHeightMeters,
                floorDetectionToleranceMeters: tExport.floorDetectionToleranceMeters,
                floorMovementConfidenceThresholdMeters: tExport.floorMovementConfidenceThresholdMeters,
                latitude: tExport.latitude,
                longitude: tExport.longitude,
                towerDataConfidence: tExport.towerDataConfidence,
                towerDataNotes: tExport.towerDataNotes
            )
            context.insert(tower)
        }
        
        for iExport in exportObj.linenItems {
            let item = LinenItem(
                name: iExport.name,
                parCount: iExport.parCount,
                countMethod: CountMethod(rawValue: iExport.countMethodRaw) ?? .manualPieces,
                bundleSize: iExport.bundleSize,
                piecesPerBin: iExport.piecesPerBin,
                allowedTowerNames: iExport.allowedTowerNames,
                availabilityScope: ItemAvailabilityScope(rawValue: iExport.availabilityScopeRaw) ?? .allTowers,
                isActive: iExport.isActive
            )
            context.insert(item)
        }
        
        try context.save()
        UserDefaults.standard.set(true, forKey: "isCustomProperty")
    }

    public static func generateQRCode(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            let context = CIContext()
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}
