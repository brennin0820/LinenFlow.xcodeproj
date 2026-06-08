import SwiftUI
import SwiftData

struct ShiftTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(ShiftOrchestrator.self) private var orchestrator
    @Environment(ShiftPlannerSettings.self) private var settings

    @State private var dashboardViewModel = ShiftDashboardViewModel()
    @State private var showPatterns = false
    @State private var showDurations = false
    @State private var showPlannerSettings = false
    @State private var clockTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            DashboardView(
                viewModel: dashboardViewModel,
                onManagePatterns: { showPatterns = true },
                onOpenSettings: { showDurations = true }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(HimmerFlowColors.background)
            .navigationTitle("Shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showPatterns = true
                        } label: {
                            Label("Shift Patterns", systemImage: "calendar")
                        }
                        Button {
                            showDurations = true
                        } label: {
                            Label("Durations", systemImage: "timer")
                        }
                        Button {
                            showPlannerSettings = true
                        } label: {
                            Label("Location & Monitoring", systemImage: "location")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Shift options")
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            dashboardViewModel.orchestrator = orchestrator
            startClock()
        }
        .onDisappear {
            clockTask?.cancel()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await orchestrator.reconcile(trigger: .appForeground) }
            }
        }
        .sheet(isPresented: $showPatterns) {
            NavigationStack {
                ShiftPatternListView(orchestrator: orchestrator)
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showDurations) {
            NavigationStack {
                HimmerFlowDurationSettingsView(settings: settings) {
                    await orchestrator.reconcile(trigger: .settingsChanged)
                }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showPlannerSettings) {
            NavigationStack {
                HimmerFlowPlannerSettingsView(settings: settings, orchestrator: orchestrator)
            }
            .preferredColorScheme(.dark)
        }
    }

    private func startClock() {
        clockTask?.cancel()
        clockTask = Task {
            while !Task.isCancelled {
                await MainActor.run {
                    dashboardViewModel.now = .now
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
