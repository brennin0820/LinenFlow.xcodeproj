import SwiftUI
import SwiftData
import OSLog
import CoreLocation

/// Bridges AppDelegate cold-launch handling with the live orchestrator instance.
@MainActor
enum HimmerFlowAppIntegration {
    private(set) static var orchestrator: ShiftOrchestrator?
    private(set) static var locationService: LocationService?

    static func register(orchestrator: ShiftOrchestrator, locationService: LocationService) {
        self.orchestrator = orchestrator
        self.locationService = locationService
    }

    static func handleColdLocationLaunch() async {
        guard let orchestrator else {
            AppLogger.boot.error("Location cold launch before orchestrator registration")
            return
        }

        await NotificationService().registerCategories()
        await orchestrator.reconcile(trigger: .appForeground)
        HimmerFlowLog.orchestrator.info("Background reconciliation finished after location cold launch")
    }
}

@main
struct HimmerFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    let container: ModelContainer
    let flowViewModel: FlowViewModel
    let floorTrackingSession: FloorTrackingSessionViewModel
    let shiftSettings = ShiftSettings()
    let appThemeSettings = AppThemeSettings()
    let shiftPlannerSettings: ShiftPlannerSettings
    let shiftOrchestrator: ShiftOrchestrator
    let himmerFlowLocationService = LocationService()
    let liveActivityService = LiveActivityService()

    init() {
        AppLogger.boot.info("HimmerFlow boot started")
        do {
            container = try ModelContainer(
                for: Tower.self,
                LinenItem.self,
                DailyLog.self,
                ShiftPattern.self,
                SavedLocation.self,
                ShiftPlannerSettings.self,
                migrationPlan: HimmerFlowMigrationPlan.self
            )

            let context = container.mainContext
            HimmerFlowLegacyShiftMigration.migrateIfNeeded(context: context)

            AppLogger.seed.info("Seeding if needed…")
            let isCustomProperty = UserDefaults.standard.bool(forKey: "isCustomProperty")
            SeedService.seedIfNeeded(context: context, isCustomProperty: isCustomProperty)

            shiftPlannerSettings = HimmerFlowLegacyShiftMigration.loadOrCreateSettings(context: context)
            shiftOrchestrator = ShiftOrchestrator(
                modelContext: context,
                settings: shiftPlannerSettings,
                activityService: liveActivityService,
                locationService: himmerFlowLocationService
            )

            flowViewModel = FlowViewModel(modelContext: context)
            floorTrackingSession = FloorTrackingSessionViewModel()
            flowViewModel.configureWidgetShiftSettings(shiftSettings)
            flowViewModel.syncWidgetState(
                shiftSettings: shiftSettings,
                preserveExistingActiveSession: true
            )

            let orchestrator = shiftOrchestrator
            himmerFlowLocationService.onRegionEvent = { region, entering in
                Task { @MainActor in
                    await orchestrator.reconcile(
                        trigger: .geofenceEvent(regionIdentifier: region.identifier, entering: entering)
                    )
                }
            }
            himmerFlowLocationService.onSignificantLocationChange = { _ in
                Task { @MainActor in
                    await orchestrator.reconcile(trigger: .significantLocationChange)
                }
            }

            HimmerFlowAppIntegration.register(
                orchestrator: shiftOrchestrator,
                locationService: himmerFlowLocationService
            )

            Task { @MainActor in
                _ = NotificationManager.shared
                await NotificationService().registerCategories()
                await orchestrator.reconcile(trigger: .appForeground)
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
                .environment(shiftOrchestrator)
                .environment(shiftPlannerSettings)
                .fullScreenCover(isPresented: onboardingPresented) {
                    OnboardingFlow(settings: shiftPlannerSettings, orchestrator: shiftOrchestrator)
                }
        }
        .modelContainer(container)
    }

    private var onboardingPresented: Binding<Bool> {
        Binding(
            get: { !shiftPlannerSettings.hasCompletedOnboarding },
            set: { _ in }
        )
    }
}
