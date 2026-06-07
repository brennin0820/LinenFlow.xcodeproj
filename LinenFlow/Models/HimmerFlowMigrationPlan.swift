import SwiftData
import Foundation

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

enum HimmerFlowMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            HimmerFlowSchemaV1.self
        ]
    }

    static var stages: [MigrationStage] {
        []
    }
}
