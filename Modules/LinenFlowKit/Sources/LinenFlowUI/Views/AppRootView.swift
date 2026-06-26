import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(FlowViewModel.self) private var flowViewModel
    @Environment(AppThemeSettings.self) private var themeSettings
    @State private var deepLinkCoordinator = WidgetDeepLinkCoordinator()

    public var body: some View {
        TabView(selection: $deepLinkCoordinator.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Linen", systemImage: "shippingbox.fill")
                }
                .tag(WidgetDeepLinkCoordinator.Tab.home)
                .accessibilityIdentifier("tab.linen")

            ShiftTabView()
                .tabItem {
                    Label("Shift", systemImage: "briefcase.fill")
                }
                .tag(WidgetDeepLinkCoordinator.Tab.shift)
                .accessibilityIdentifier("tab.shift")

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .tag(WidgetDeepLinkCoordinator.Tab.insights)
                .accessibilityIdentifier("tab.insights")

            LogsTabView()
                .tabItem {
                    Label("Logs", systemImage: "clock.arrow.circlepath")
                }
                .tag(WidgetDeepLinkCoordinator.Tab.logs)
                .accessibilityIdentifier("tab.logs")

            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(WidgetDeepLinkCoordinator.Tab.settings)
                .accessibilityIdentifier("tab.settings")
        }
        .tint(themeSettings.isPractical ? Color(red: 0.10, green: 0.48, blue: 0.98) : .cyan)
        .environment(deepLinkCoordinator)
        .smartTipSheet()
        .onOpenURL { url in
            deepLinkCoordinator.handle(url, flowViewModel: flowViewModel)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                flowViewModel.processPendingLiveActivityDrops()
            }
        }
        .onChange(of: themeSettings.mode) { _, newMode in
            AppThemeSettings.applyTabBarAppearance(for: newMode)
        }
    }
}
