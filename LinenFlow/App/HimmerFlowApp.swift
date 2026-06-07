import SwiftUI
import SwiftData
import OSLog

@main
struct HimmerFlowApp: App {
    let container: ModelContainer
    let flowViewModel: FlowViewModel
    let floorTrackingSession: FloorTrackingSessionViewModel
    let shiftSettings = ShiftSettings()
    let appThemeSettings = AppThemeSettings()

    init() {
        AppLogger.boot.info("HimmerFlow boot started")
        do {
            container = try ModelContainer(
                for: Tower.self, LinenItem.self, DailyLog.self,
                migrationPlan: HimmerFlowMigrationPlan.self
            )
            AppLogger.seed.info("Seeding if needed…")
            let isCustomProperty = UserDefaults.standard.bool(forKey: "isCustomProperty")
            SeedService.seedIfNeeded(context: container.mainContext, isCustomProperty: isCustomProperty)
            flowViewModel = FlowViewModel(modelContext: container.mainContext)
            floorTrackingSession = FloorTrackingSessionViewModel()
            flowViewModel.configureWidgetShiftSettings(shiftSettings)
            flowViewModel.syncWidgetState(
                shiftSettings: shiftSettings,
                preserveExistingActiveSession: true
            )
            Task { @MainActor in
                _ = NotificationManager.shared
            }
            AppLogger.boot.info("HimmerFlow boot complete")
        } catch {
            AppLogger.boot.critical("SwiftData container init failed: \(error, privacy: .public)")
            fatalError("HimmerFlow — SwiftData container failed to initialize.\nError: \(error)\n\nCheck schema migrations and model registration.")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(.dark)
                .environment(flowViewModel)
                .environment(shiftSettings)
                .environment(floorTrackingSession)
                .environment(appThemeSettings)
        }
        .modelContainer(container)
    }
}
