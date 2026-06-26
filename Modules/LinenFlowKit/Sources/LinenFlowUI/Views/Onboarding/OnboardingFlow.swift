import SwiftUI
import SwiftData
import LinenFlowCore
import LinenFlowEngine

public struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable public var settings: ShiftPlannerSettings
    @Bindable public var orchestrator: ShiftOrchestrator

    @State private var step = 0
    @State private var clockInDate = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: .now) ?? .now
    @State private var commuteMinutes = 30
    @State private var wantsLocation = false
    @State private var showLocationPermission = false

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressIndicator
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                TabView(selection: $step) {
                    clockInStep.tag(0)
                    commuteStep.tag(1)
                    locationStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.snappy, value: step)

                footerButtons
                    .padding(24)
            }
            .background(HimmerFlowColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLocationPermission) {
                LocationPermissionView()
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled()
    }

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? HimmerFlowColors.accent : HimmerFlowColors.border)
                    .frame(height: 4)
            }
        }
        .accessibilityLabel("Step \(step + 1) of 3")
    }

    private var clockInStep: some View {
        onboardingPage(
            title: "When do you clock in?",
            subtitle: "This is the hard anchor — everything else counts backward from this time.",
            systemImage: "clock.fill"
        ) {
            DatePicker("Clock in time", selection: $clockInDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
        }
    }

    private var commuteStep: some View {
        onboardingPage(
            title: "How long is your commute?",
            subtitle: "A manual estimate is fine. No traffic data — just your best guess.",
            systemImage: "car.fill"
        ) {
            DurationPickerView(
                title: "Commute",
                minutes: $commuteMinutes,
                range: 5...120,
                step: 5
            )
        }
    }

    private var locationStep: some View {
        onboardingPage(
            title: "Want location features?",
            subtitle: "Optional. Detect leaving home and arriving at work automatically.",
            systemImage: "location.fill"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable smart location detection", isOn: $wantsLocation)
                    .font(.body.weight(.semibold))
                    .tint(HimmerFlowColors.accent)

                Text("You can skip this and still get time-based reminders.")
                    .font(.footnote)
                    .foregroundStyle(HimmerFlowColors.mutedText)
            }
            .padding(16)
            .background(HimmerFlowColors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func onboardingPage<Content: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: systemImage)
                    .font(.system(size: 44))
                    .foregroundStyle(HimmerFlowColors.accent)

                Text(title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(HimmerFlowColors.heroText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(HimmerFlowColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                content()
            }
            .padding(24)
        }
    }

    private var footerButtons: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("Back") {
                    withAnimation { step -= 1 }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(HimmerFlowColors.mutedText)
            }

            Spacer()

            Button(step == 2 ? "Get Started" : "Continue") {
                if step < 2 {
                    withAnimation { step += 1 }
                } else {
                    completeOnboarding()
                }
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(HimmerFlowColors.ctaFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func completeOnboarding() {
        settings.commuteDurationMinutes = commuteMinutes
        settings.monitoringTier = wantsLocation ? .smart : .manual
        settings.hasCompletedOnboarding = true

        let components = Calendar.current.dateComponents([.hour, .minute], from: clockInDate)
        let weekday = Weekday(calendarWeekday: Calendar.current.component(.weekday, from: .now)) ?? .monday

        let pattern = ShiftPattern(
            name: "My Shift",
            daysOfWeek: [weekday],
            clockInTime: components,
            shiftDurationMinutes: 480,
            isActive: true
        )
        modelContext.insert(pattern)
        try? modelContext.save()

        if wantsLocation {
            showLocationPermission = true
        }

        Task {
            await orchestrator.reconcile(trigger: .settingsChanged)
            dismiss()
        }
    }
}
