import Foundation
import OSLog
import SwiftData

// MARK: - Schema versions

enum HimmerFlowSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            Tower.self,
            LinenItem.self,
            DailyLog.self
        ]
    }
}

enum HimmerFlowSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            Tower.self,
            LinenItem.self,
            DailyLog.self,
            ShiftPattern.self,
            SavedLocation.self,
            ShiftPlannerSettings.self
        ]
    }
}

enum HimmerFlowMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            HimmerFlowSchemaV1.self,
            HimmerFlowSchemaV2.self
        ]
    }

    static var stages: [MigrationStage] {
        [
            MigrationStage.lightweight(fromVersion: HimmerFlowSchemaV1.self, toVersion: HimmerFlowSchemaV2.self)
        ]
    }
}

// MARK: - Legacy SmartShiftAlarmPlannerViewModel migration

/// Migrates on-device `UserDefaults` state from the legacy shift tab (`SmartShiftAlarmPlannerViewModel`)
/// into SwiftData models used by `ShiftOrchestrator`.
///
/// **Deprecation:** Waze deep links and MapKit routing from the legacy planner are not migrated.
/// HimmerFlow uses manual commute duration estimates only (LOCKED no-network rule, spec §16).
enum HimmerFlowLegacyShiftMigration {
    private static let migrationCompletedKey = "himmerflow.migratedFromSmartShiftPlanner"

    private static let legacyScheduleKey = "shiftPlanner.schedule"
    private static let legacyCommutePlanKey = "shiftPlanner.commutePlan"

    static func migrateIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: migrationCompletedKey) else { return }

        let existingPatterns = (try? context.fetch(FetchDescriptor<ShiftPattern>())) ?? []
        guard existingPatterns.isEmpty else {
            UserDefaults.standard.set(true, forKey: migrationCompletedKey)
            return
        }

        let schedule = decodeLegacySchedule()
        let commute = decodeLegacyCommutePlan()
        guard !schedule.isEmpty || commute != nil else { return }

        let settings = loadOrCreateSettings(context: context)

        if let commute {
            settings.commuteDurationMinutes = commute.manualEstimatedDriveMinutes
            settings.walkToCarMinutes = commute.walkToCarMinutes
            settings.getReadyDurationMinutes = commute.prepMinutes
            settings.arrivalBufferMinutes = commute.safetyBufferMinutes

            if !commute.homeAddress.isEmpty {
                let home = SavedLocation(
                    label: commute.homeLabel,
                    latitude: commute.wazeLatitude,
                    longitude: commute.wazeLongitude,
                    radiusMeters: 200,
                    locationType: .home
                )
                context.insert(home)
                settings.homeLocation = home
            }

            if !commute.workAddress.isEmpty {
                let work = SavedLocation(
                    label: commute.workLabel,
                    latitude: commute.wazeLatitude,
                    longitude: commute.wazeLongitude,
                    radiusMeters: 200,
                    locationType: .work
                )
                context.insert(work)

                let workdays = schedule.filter(\.isWorkday)
                if !workdays.isEmpty {
                    let grouped = Dictionary(grouping: workdays) { day in
                        "\(day.shiftStartHour):\(day.shiftStartMinute)-\(day.shiftEndHour):\(day.shiftEndMinute)"
                    }
                    for (index, days) in grouped.values.enumerated() {
                        guard let sample = days.first else { continue }
                        let duration = shiftDurationMinutes(for: sample)
                        let pattern = ShiftPattern(
                            name: grouped.count == 1 ? "Migrated Shift" : "Migrated Shift \(index + 1)",
                            daysOfWeek: Set(days.compactMap { Weekday(rawValue: $0.weekday) }),
                            clockInTime: DateComponents(hour: sample.shiftStartHour, minute: sample.shiftStartMinute),
                            shiftDurationMinutes: duration,
                            workLocation: work,
                            isActive: true
                        )
                        context.insert(pattern)
                    }
                }
            }
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: migrationCompletedKey)
        AppLogger.boot.info("Migrated legacy SmartShiftAlarmPlannerViewModel defaults into SwiftData")
    }

    static func loadOrCreateSettings(context: ModelContext) -> ShiftPlannerSettings {
        if let existing = try? context.fetch(FetchDescriptor<ShiftPlannerSettings>()).first {
            return existing
        }

        let settings = ShiftPlannerSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }

    private static func decodeLegacySchedule() -> [WorkScheduleDay] {
        guard let data = UserDefaults.standard.data(forKey: legacyScheduleKey) else { return [] }
        return (try? JSONDecoder().decode([WorkScheduleDay].self, from: data)) ?? []
    }

    private static func decodeLegacyCommutePlan() -> CommutePlan? {
        guard let data = UserDefaults.standard.data(forKey: legacyCommutePlanKey) else { return nil }
        return try? JSONDecoder().decode(CommutePlan.self, from: data)
    }

    private static func shiftDurationMinutes(for day: WorkScheduleDay) -> Int {
        var start = day.shiftStartHour * 60 + day.shiftStartMinute
        var end = day.shiftEndHour * 60 + day.shiftEndMinute
        if day.isOvernightShift || end <= start {
            end += 24 * 60
        }
        return max(end - start, 60)
    }
}
