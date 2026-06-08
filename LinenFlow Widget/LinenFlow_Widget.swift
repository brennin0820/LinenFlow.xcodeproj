import SwiftUI
import WidgetKit
import AppIntents

enum HimmerFlowWidgetDesignSystem {
    enum Palette {
        static let nightBase = WidgetDesignTokens.ColorToken.nightBase
        static let nightElevated = WidgetDesignTokens.ColorToken.nightElevated
        static let nightDeep = WidgetDesignTokens.ColorToken.nightDeep
        static let inactive = WidgetDesignTokens.ColorToken.inactive
        static let ready = WidgetDesignTokens.ColorToken.ready
        static let paused = WidgetDesignTokens.ColorToken.paused
        static let finishing = WidgetDesignTokens.ColorToken.finishing
        static let urgent = WidgetDesignTokens.ColorToken.urgent
        static let overtime = WidgetDesignTokens.ColorToken.overtime
        static let complete = WidgetDesignTokens.ColorToken.complete
        static let demo = WidgetDesignTokens.ColorToken.demo
        static let defaultAccent = WidgetDesignTokens.ColorToken.defaultAccent
    }

    enum Radius {
        static let compact = WidgetDesignTokens.Radius.compact
    }

    static func accentColor(hex: String?) -> Color {
        Color(hex: hex) ?? Palette.defaultAccent
    }

    static func progressFraction(completedFloors: Int, floorCount: Int) -> Double {
        guard floorCount > 0 else { return 0 }
        return min(max(Double(completedFloors) / Double(floorCount), 0), 1)
    }

    static func countdownText(targetTime: Date?, fallback: String, compact: Bool = false) -> String {
        guard let targetTime else { return fallback }
        let raw = targetTime.timeIntervalSinceNow
        if raw < 0 {
            let over = Int(-raw / 60) + 1
            return compact ? "+\(over)m" : "Overtime +\(over)m"
        }
        let seconds = Int(raw)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 { return compact ? "\(hours)h \(minutes)m" : "\(hours)h \(minutes)m left" }
        if minutes > 0 { return compact ? "\(minutes)m" : "\(minutes)m left" }
        return "Due now"
    }

    static func shortTowerName(_ towerName: String) -> String {
        let trimmed = towerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "HF" }

        let words = trimmed.split(separator: " ")
        if words.count > 1 {
            return words.compactMap(\.first).prefix(2).map(String.init).joined().uppercased()
        }
        return String(trimmed.prefix(3)).uppercased()
    }
}

extension Color {
    init?(hex: String?) {
        guard let hex else { return nil }
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value) else { return nil }

        switch cleaned.count {
        case 6:
            self.init(
                red: Double((value & 0xFF0000) >> 16) / 255,
                green: Double((value & 0x00FF00) >> 8) / 255,
                blue: Double(value & 0x0000FF) / 255
            )
        default:
            return nil
        }
    }
}

struct HimmerFlowTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HimmerFlowWidgetEntry {
        HimmerFlowWidgetEntry(date: .now, state: .diamondActivePreview, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> HimmerFlowWidgetEntry {
        HimmerFlowWidgetEntry(date: .now, state: SharedWidgetStateManager.load(), configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<HimmerFlowWidgetEntry> {
        let state = SharedWidgetStateManager.load()
        let entry = HimmerFlowWidgetEntry(date: .now, state: state, configuration: configuration)
        let refreshMinutes = state.isActiveSession ? 2 : 15
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: refreshMinutes, to: .now) ?? .now.addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }
}

struct HimmerFlowWidgetEntry: TimelineEntry {
    let date: Date
    let state: SharedWidgetState
    let configuration: ConfigurationAppIntent
}

struct HimmerFlow_WidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: HimmerFlowWidgetEntry

    private var state: SharedWidgetState { entry.state }
    private var snapshot: OperationalShiftSnapshot {
        OperationalShiftStateEngine.snapshot(from: state)
    }
    private var hasTower: Bool { state.floorCount > 0 }
    private var isComplete: Bool {
        snapshot.isComplete
    }
    private var accentColor: Color { HimmerFlowWidgetDesignSystem.accentColor(hex: state.towerColorHex) }
    private var statusColor: Color {
        WidgetDesignTokens.statusColor(for: snapshot, towerColorHex: state.towerColorHex)
    }

    private var urgencyColor: Color {
        statusColor
    }

    private var badgeText: String {
        snapshot.semanticState.displayName
    }

    private var countdownText: String {
        roundedCountdownText(compact: false)
    }

    private var currentFloorPlanRows: [WidgetFloorPlanRow] {
        state.currentItemFloorPlanRows ?? []
    }

    private var currentTripItems: [String] {
        let tripItems = state.currentTripItemNames ?? []
        let fallbackItems = state.currentItemNames ?? [state.currentItemName].compactMap { $0 }
        return Array((tripItems.isEmpty ? fallbackItems : tripItems)
            .sorted { LinenIconLibrary.itemComesBefore($0, $1) }
            .prefix(2))
    }

    private var displayFloorNumber: Int? {
        state.currentFloorNumber
    }

    private var hasActiveDelivery: Bool {
        state.isActiveSession && displayFloorNumber != nil
    }

    private var hasRouteComplete: Bool {
        state.floorCount > 0 && state.remainingFloors == 0 && state.completedFloors >= state.floorCount
    }

    /// Delivery command board (floor tap-to-complete) vs shift-status pulse (tower, pins, progress).
    private var shouldShowDeliveryCommandBoard: Bool {
        hasRouteComplete || hasActiveDelivery
    }

    private var currentFloorAmounts: [WidgetFloorDeliveryAmount] {
        Array((state.currentFloorDeliveryAmounts ?? [])
            .sorted { LinenIconLibrary.itemComesBefore($0.itemName, $1.itemName) }
            .prefix(2))
    }

    private var progressText: String {
        "\(state.completedFloors) / \(max(state.floorCount, 0))"
    }

    private var bundleProgressText: String? {
        guard let remaining = state.currentTripRemainingBundles,
              let total = state.currentTripTotalBundles,
              total > 0 else { return nil }
        return "\(remaining) / \(total) bdl left"
    }

    private var deliveryProgressFraction: Double {
        HimmerFlowWidgetDesignSystem.progressFraction(completedFloors: state.completedFloors, floorCount: state.floorCount)
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                sizedWidget(size: .small)
            case .systemMedium:
                sizedWidget(size: .medium)
            case .systemLarge:
                sizedWidget(size: .large)
            case .systemExtraLarge:
                Group {
                    if shouldShowDeliveryCommandBoard {
                        deliveryWidget(compact: false)
                    } else {
                        extraLargeWidget
                    }
                }
            case .accessoryCircular:
                accessoryCircularContent
            case .accessoryInline:
                accessoryInlineContent
            case .accessoryRectangular:
                accessoryRectangularContent
            default:
                sizedWidget(size: .small)
            }
        }
        .widgetURL(widgetDeepLink)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(widgetAccessibilityLabel)
        .accessibilityHint(widgetAccessibilityHint)
        .animation(.easeInOut(duration: 0.16), value: displayFloorNumber)
        .animation(.easeInOut(duration: 0.16), value: state.completedFloors)
    }

    private enum WidgetContentSize {
        case small, medium, large
    }

    @ViewBuilder
    private var accessoryCircularContent: some View {
        if shouldShowDeliveryCommandBoard {
            deliveryCircularAccessory
        } else {
            circularAccessory
        }
    }

    @ViewBuilder
    private var accessoryInlineContent: some View {
        if shouldShowDeliveryCommandBoard {
            deliveryInlineAccessory
        } else {
            inlineAccessory
        }
    }

    @ViewBuilder
    private var accessoryRectangularContent: some View {
        if shouldShowDeliveryCommandBoard {
            deliveryRectangularAccessory
        } else {
            rectangularAccessory
        }
    }

    @ViewBuilder
    private func sizedWidget(size: WidgetContentSize) -> some View {
        if shouldShowDeliveryCommandBoard {
            deliveryWidget(compact: size == .small)
        } else {
            switch size {
            case .small:
                smallWidget
            case .medium:
                mediumWidget
            case .large:
                largeWidget
            }
        }
    }

    private func deliveryWidget(compact: Bool) -> some View {
        Group {
            if hasRouteComplete {
                routeCompleteWidget(compact: compact)
            } else if hasActiveDelivery, let floor = displayFloorNumber {
                VStack(alignment: .leading, spacing: compact ? 8 : 11) {
                    deliveryHeader(compact: compact)

                    floorActionCard(floor: floor, compact: compact)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    progressFooter(compact: compact)
                }
            } else {
                deliveryEmptyState(compact: compact)
            }
        }
        .linenCommandBackground(accentColor: accentColor, activeColor: accentColor)
    }

    private func deliveryHeader(compact: Bool) -> some View {
        HStack(alignment: .top, spacing: 9) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accentColor)
                .frame(width: 4)
                .shadow(color: accentColor.opacity(0.45), radius: 7, x: 0, y: 0)

            VStack(alignment: .leading, spacing: compact ? 5 : 7) {
                Text(state.towerName)
                    .font((compact ? Font.headline : Font.title3).weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                tripItemsStack(compact: compact)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func floorActionCard(floor: Int, compact: Bool) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            Button(intent: CompleteCurrentFloorIntent(floorNumber: floor)) {
                floorCardContent(floor: floor, compact: compact)
            }
            .buttonStyle(.plain)
        } else {
            floorCardContent(floor: floor, compact: compact)
        }
    }

    private func floorCardContent(floor: Int, compact: Bool) -> some View {
        VStack(spacing: compact ? 6 : 10) {
            VStack(spacing: compact ? 3 : 6) {
                Text("FLOOR")
                    .font((compact ? Font.caption2 : Font.caption).weight(.heavy))
                    .foregroundStyle(.white.opacity(0.66))
                    .tracking(1.8)
                Text("\(floor)")
                    .font(.system(size: compact ? 52 : 86, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.64)
                    .contentTransition(.numericText())
            }

            if !currentFloorAmounts.isEmpty {
                VStack(spacing: compact ? 3 : 5) {
                    ForEach(currentFloorAmounts, id: \.self) { amount in
                        itemAmountRow(amount, compact: compact)
                    }
                }
                .padding(.horizontal, compact ? 8 : 10)
                .padding(.vertical, compact ? 5 : 7)
                .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(compact ? 10 : 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 16 : 22, style: .continuous)
                    .fill(Color.white.opacity(0.075))
                RoundedRectangle(cornerRadius: compact ? 16 : 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.26), .white.opacity(0.035)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 16 : 22, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: accentColor.opacity(0.24), radius: 14, x: 0, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Complete floor \(floor)")
    }

    private func tripItemsStack(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 3 : 5) {
            if currentTripItems.isEmpty {
                Text("Current Trip")
                    .font((compact ? Font.caption2 : Font.caption).weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
            } else {
                HStack(spacing: 6) {
                    ForEach(currentTripItems, id: \.self) { item in
                        itemInitialBadge(itemName: item, compact: compact)
                    }
                }
            }
        }
    }

    private func itemAmountRow(_ amount: WidgetFloorDeliveryAmount, compact: Bool) -> some View {
        HStack(spacing: 7) {
            itemInitialBadge(itemName: amount.itemName, compact: compact)
            Text(amount.amountText)
                .font((compact ? Font.caption2 : Font.caption).weight(.heavy).monospacedDigit())
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Spacer(minLength: 0)
        }
    }

    private func itemInitialBadge(itemName: String, compact: Bool) -> some View {
        Text(LinenIconLibrary.initials(forItem: itemName))
            .font(.system(size: compact ? 12 : 14, weight: .black, design: .monospaced))
            .foregroundStyle(LinenIconLibrary.color(forItem: itemName))
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .frame(width: compact ? 24 : 28, height: compact ? 24 : 28)
            .accessibilityLabel(itemName)
    }

    private func progressFooter(compact: Bool) -> some View {
        VStack(spacing: compact ? 4 : 6) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.10))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.74), accentColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(proxy.size.width * deliveryProgressFraction, 3))
                }
            }
            .frame(height: compact ? 3 : 4)

            Text(progressText)
                .font((compact ? Font.caption2 : Font.caption).weight(.heavy).monospacedDigit())
                .foregroundStyle(.white.opacity(0.72))
                .frame(maxWidth: .infinity, alignment: .center)
                .contentTransition(.numericText())

            if let bundleProgressText {
                Text(bundleProgressText)
                    .font(.caption2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(accentColor.opacity(0.90))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .contentTransition(.numericText())
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(state.completedFloors) of \(state.floorCount) floors complete")
    }

    private func routeCompleteWidget(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 11) {
            deliveryHeader(compact: compact)

            VStack(spacing: compact ? 5 : 8) {
                Text("OK")
                    .font(.system(size: compact ? 34 : 46, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)
                Text("Route Complete")
                    .font((compact ? Font.headline : Font.title2).weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("Completed Successfully")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)

                if #available(iOSApplicationExtension 17.0, *), state.lastCompletedFloorNumber != nil {
                    Button(intent: UndoLastFloorIntent()) {
                        Text("Undo Last Floor")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.white.opacity(0.82))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(compact ? 10 : 16)
            .background(Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: compact ? 16 : 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 16 : 22, style: .continuous)
                    .stroke(accentColor.opacity(0.28), lineWidth: 1)
            )

            progressFooter(compact: compact)
        }
    }

    private func deliveryEmptyState(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? WidgetDesignTokens.Spacing.standard : WidgetDesignTokens.Spacing.content) {
            if hasTower {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(accentColor)
                        .frame(width: 4, height: compact ? 28 : 34)
                    Text(state.towerName)
                        .font((compact ? Font.headline : Font.title3).weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
            Text(hasTower ? "Ready to Deliver" : "No Active Delivery")
                .font((compact ? Font.headline : Font.title2).weight(.heavy))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
            Text(hasTower ? state.statusText : "Open HimmerFlow")
                .font(.caption.weight(.bold))
                .foregroundStyle(accentColor)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
            if !hasTower {
                Text("Choose a tower to begin")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(WidgetDesignTokens.Opacity.secondaryText))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            hasTower
                ? "\(state.towerName), ready to deliver. \(state.statusText)"
                : "No active delivery. Open HimmerFlow and choose a tower."
        )
    }

    private var deliveryInlineAccessory: some View {
        if hasRouteComplete {
            Text("Route Complete · \(progressText)")
        } else if hasActiveDelivery, let floor = displayFloorNumber {
            Text("\(currentTripItems.joined(separator: " · ")) · FLOOR \(floor)")
        } else {
            Text("No Active Delivery · Open HimmerFlow")
        }
    }

    private var deliveryCircularAccessory: some View {
        ZStack {
            AccessoryWidgetBackground()
            if hasRouteComplete {
                VStack(spacing: 0) {
                    Text("OK")
                        .font(.headline.weight(.black))
                    Text(progressText)
                        .font(.system(size: 8, weight: .heavy))
                }
            } else if hasActiveDelivery, let floor = displayFloorNumber {
                VStack(spacing: 0) {
                    Text("\(floor)")
                        .font(.title.weight(.black).monospacedDigit())
                    Text("FLOOR")
                        .font(.system(size: 8, weight: .heavy))
                }
            } else {
                Text("LF")
                    .font(.headline.weight(.heavy))
            }
        }
    }

    private var deliveryRectangularAccessory: some View {
        VStack(alignment: .leading, spacing: 4) {
            if hasRouteComplete {
                Text(state.towerName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text("Route Complete")
                    .font(.headline.weight(.heavy))
                    .lineLimit(1)
                Text(progressText)
                    .font(.caption2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else if hasActiveDelivery, let floor = displayFloorNumber {
                Text(currentTripItems.isEmpty ? state.towerName : currentTripItems.joined(separator: " · "))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if #available(iOSApplicationExtension 17.0, *) {
                    Button(intent: CompleteCurrentFloorIntent(floorNumber: floor)) {
                        Text("FLOOR \(floor)")
                            .font(.title2.weight(.black).monospacedDigit())
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("FLOOR \(floor)")
                        .font(.title2.weight(.black).monospacedDigit())
                        .lineLimit(1)
                }
                Text(progressText)
                    .font(.caption2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let amount = currentFloorAmounts.first {
                    Text(amount.amountText)
                        .font(.caption2.weight(.heavy).monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                Text("No Active Delivery")
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                Text("Open HimmerFlow")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .containerBackground(for: .widget) {
            AccessoryWidgetBackground()
        }
    }

    private var smallWidget: some View {
        Group {
            if hasTower {
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                        statusBadge
                    }

                    HStack(spacing: 7) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(accentColor)
                            .frame(width: 3, height: 22)
                        Text(state.towerName.uppercased())
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("\(state.towerName) tower")

                    Spacer(minLength: 0)

                    progressRing(size: WidgetDesignTokens.Layout.smallRingSize, lineWidth: WidgetDesignTokens.Layout.ringLineWidth, centerFont: .headline.weight(.heavy))
                        .shadow(color: state.isActiveSession ? urgencyColor.opacity(0.30) : .clear, radius: 10)

                    Spacer(minLength: 0)

                    Text(countdownText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(urgencyColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                        .contentTransition(.numericText())
                        .accessibilityLabel("Countdown")
                        .accessibilityValue(countdownAccessibilityValue)
                }
            } else {
                emptySmall
            }
        }
        .linenCommandBackground(accentColor: accentColor, activeColor: statusColor)
        .animation(.spring(response: 0.45, dampingFraction: 0.88), value: state.progressFraction)
        .animation(.spring(response: 0.35, dampingFraction: 0.90), value: badgeText)
    }

    private var mediumWidget: some View {
        Group {
            if hasTower {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 7) {
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(accentColor)
                                    .frame(width: 3, height: 24)
                                Text("\(snapshot.towerName) Tower")
                                    .font(.headline.weight(.heavy))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.76)
                            }
                            .accessibilityLabel("\(snapshot.towerName) tower")
                            Text(snapshot.semanticState.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(statusColor)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        countdownPill
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        ProgressView(value: snapshot.progressFraction)
                            .progressViewStyle(.linear)
                            .tint(urgencyColor)
                            .scaleEffect(x: 1, y: 2.0, anchor: .center)
                            .background(Color.white.opacity(0.13), in: Capsule())
                            .clipShape(Capsule())
                            .animation(.spring(response: 0.55, dampingFraction: 0.90), value: snapshot.progressFraction)

                        HStack {
                            Text("\(snapshot.completedFloors)/\(snapshot.floorCount)")
                                .font(.title3.weight(.heavy).monospacedDigit())
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                            Text("floors complete")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.58))
                            Spacer()
                            Text("\(snapshot.remainingFloors) left")
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundStyle(statusColor)
                                .contentTransition(.numericText())
                        }
                    }

                    if currentFloorPlanRows.isEmpty {
                        if hasPinnedOrQueuedItems {
                            pinnedOrQueuedPanel(compact: true)
                        } else {
                            commandDetailRow
                        }
                    } else {
                        currentItemFloorPlanPanel
                    }
                }
            } else {
                emptyMedium
            }
        }
        .linenCommandBackground(accentColor: accentColor, activeColor: statusColor)
        .animation(.spring(response: 0.45, dampingFraction: 0.88), value: state.progressFraction)
        .animation(.spring(response: 0.35, dampingFraction: 0.90), value: badgeText)
        .animation(.easeInOut(duration: 0.30), value: urgencyColor)
    }

    private var largeWidget: some View {
        Group {
            if hasTower {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(state.towerName) Tower")
                                .font(.title2.weight(.heavy))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Text(state.statusText)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.62))
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)
                        VStack(alignment: .trailing, spacing: 6) {
                            statusBadge
                            countdownPill
                        }
                    }

                    HStack(alignment: .center, spacing: 16) {
                        progressRing(size: 108, lineWidth: 10, centerFont: .title3.weight(.heavy))

                        VStack(alignment: .leading, spacing: 9) {
                            ProgressView(value: state.progressFraction)
                                .progressViewStyle(.linear)
                                .tint(urgencyColor)
                                .scaleEffect(x: 1, y: 2.2, anchor: .center)
                                .background(Color.white.opacity(0.13), in: Capsule())
                                .clipShape(Capsule())

                            HStack(alignment: .firstTextBaseline) {
                                Text(state.completedText)
                                    .font(.title.weight(.heavy).monospacedDigit())
                                    .foregroundStyle(.white)
                                    .contentTransition(.numericText())
                                Text("floors complete")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.58))
                                Spacer()
                                Text("\(state.remainingFloors) left")
                                    .font(.subheadline.weight(.heavy).monospacedDigit())
                                    .foregroundStyle(statusColor)
                            }

                            commandDetailRow
                        }
                    }

                    if currentFloorPlanRows.isEmpty {
                        if hasPinnedOrQueuedItems {
                            pinnedOrQueuedPanel(compact: false)
                        } else {
                            largeEmptyPlanPanel
                        }
                    } else {
                        largeFloorPlanPanel
                    }

                    Spacer(minLength: 0)
                }
            } else {
                emptyLarge
            }
        }
        .linenCommandBackground(accentColor: accentColor, activeColor: statusColor)
    }

    private var extraLargeWidget: some View {
        Group {
            if hasTower {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(state.towerName) Tower")
                                .font(.title.weight(.heavy))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Text(state.statusText)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.62))
                                .lineLimit(1)
                        }

                        Spacer(minLength: 10)
                        VStack(alignment: .trailing, spacing: 7) {
                            statusBadge
                            countdownPill
                        }
                    }

                    HStack(alignment: .center, spacing: 18) {
                        progressRing(size: 132, lineWidth: 11, centerFont: .title2.weight(.heavy))

                        VStack(alignment: .leading, spacing: 10) {
                            ProgressView(value: state.progressFraction)
                                .progressViewStyle(.linear)
                                .tint(urgencyColor)
                                .scaleEffect(x: 1, y: 2.4, anchor: .center)
                                .background(Color.white.opacity(0.13), in: Capsule())
                                .clipShape(Capsule())

                            HStack(alignment: .firstTextBaseline) {
                                Text(state.completedText)
                                    .font(.largeTitle.weight(.heavy).monospacedDigit())
                                    .foregroundStyle(.white)
                                    .contentTransition(.numericText())
                                Text("floors complete")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.58))
                                Spacer()
                                Text("\(state.remainingFloors) left")
                                    .font(.headline.weight(.heavy).monospacedDigit())
                                    .foregroundStyle(statusColor)
                            }

                            extraLargeCommandDetailRow
                        }
                    }

                    if currentFloorPlanRows.isEmpty {
                        if hasPinnedOrQueuedItems {
                            pinnedOrQueuedPanel(compact: false)
                        } else {
                            extraLargeEmptyPlanPanel
                        }
                    } else {
                        extraLargeFloorPlanPanel
                    }

                    Spacer(minLength: 0)
                }
            } else {
                emptyLarge
            }
        }
        .linenCommandBackground(accentColor: accentColor, activeColor: statusColor)
    }

    private var extraLargeCommandDetailRow: some View {
        HStack(alignment: .top, spacing: 8) {
            switch entry.configuration.displayMode {
            case .shiftStatus, .nextCarry:
                deliveryItemsBlock
                commandDetail(title: "Next Carry", value: state.nextCarryGroupTitle ?? "—", symbol: "arrow.forward.circle.fill", emphasis: false)
                commandDetail(title: "Target", value: countdownText, symbol: isComplete ? "checkmark.circle.fill" : "clock.fill", emphasis: true)
            case .floorProgress:
                commandDetail(title: "Progress", value: "\(Int(state.progressFraction * 100))% complete", symbol: "chart.line.uptrend.xyaxis", emphasis: true)
                commandDetail(title: "Remaining", value: "\(state.remainingFloors) floors", symbol: "stairs", emphasis: true)
                commandDetail(title: "Status", value: snapshot.semanticState.displayName, symbol: "building.2.fill", emphasis: false)
            }
        }
    }

    private var commandDetailRow: some View {
        HStack(alignment: .top, spacing: 8) {
            switch entry.configuration.displayMode {
            case .shiftStatus, .nextCarry:
                deliveryItemsBlock
                commandDetail(title: "Next Carry", value: state.nextCarryGroupTitle ?? "—", symbol: "arrow.forward.circle.fill", emphasis: false)
            case .floorProgress:
                commandDetail(title: "Progress", value: "\(Int(state.progressFraction * 100))% complete", symbol: "chart.line.uptrend.xyaxis", emphasis: true)
                commandDetail(title: "Remaining", value: "\(state.remainingFloors) floors", symbol: "stairs", emphasis: true)
            }
        }
    }

    private var deliveryItemsBlock: some View {
        let names = snapshot.currentItemNames
        return VStack(alignment: .leading, spacing: 3) {
            if names.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "shippingbox")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.38))
                    Text("No items queued")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.48))
                        .lineLimit(1)
                }
            } else {
                ForEach(Array(names.prefix(5).enumerated()), id: \.offset) { idx, name in
                    HStack(spacing: 5) {
                        Image(systemName: idx == 0 ? "shippingbox.fill" : "shippingbox")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(idx == 0 ? statusColor : Color.white.opacity(0.38))
                        Text(name)
                            .font(idx == 0 ? .caption.weight(.heavy) : .caption.weight(.semibold))
                            .foregroundStyle(idx == 0 ? .white : Color.white.opacity(0.62))
                            .lineLimit(1)
                            .minimumScaleFactor(0.80)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .topLeading)
        .padding(8)
        .background(
            Color.white.opacity(0.065),
            in: RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
        )
    }

    private var currentItemFloorPlanPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(statusColor)
                Text(snapshot.currentItemNames.first ?? "Current Item")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer(minLength: 6)
                Text(state.currentItemFloorPlanTitle ?? "Per floor")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            ForEach(Array(currentFloorPlanRows.prefix(3)), id: \.self) { row in
                HStack(spacing: 6) {
                    Circle()
                        .fill(row.isPriority ? statusColor : Color.white.opacity(0.32))
                        .frame(width: 5, height: 5)
                    Text(row.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                    Spacer(minLength: 4)
                    Text("\(row.floorCount) fl")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.52))
                        .lineLimit(1)
                    Text(row.valueText)
                        .font(.caption.weight(.heavy).monospacedDigit())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .frame(minWidth: 42, alignment: .trailing)
                }
            }
        }
        .padding(8)
        .background(
            Color.white.opacity(0.065),
            in: RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
                .stroke(statusColor.opacity(0.18), lineWidth: 1)
        )
    }

    private var largeFloorPlanPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "map.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(statusColor)
                Text(snapshot.currentItemNames.first ?? "Current item")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                Text(state.currentItemFloorPlanTitle ?? "Floor plan")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
            }

            VStack(spacing: 6) {
                ForEach(Array(currentFloorPlanRows.prefix(5)), id: \.self) { row in
                    HStack(spacing: 7) {
                        Circle()
                            .fill(row.isPriority ? statusColor : Color.white.opacity(0.32))
                            .frame(width: 6, height: 6)
                        Text(row.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.80))
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)
                        Spacer(minLength: 4)
                        Text("\(row.floorCount) fl")
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .foregroundStyle(.white.opacity(0.52))
                            .lineLimit(1)
                        Text(row.valueText)
                            .font(.subheadline.weight(.heavy).monospacedDigit())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .frame(minWidth: 48, alignment: .trailing)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(
                        Color.white.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
                    )
                }
            }
        }
        .padding(10)
        .background(
            Color.white.opacity(0.055),
            in: RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
                .stroke(statusColor.opacity(0.18), lineWidth: 1)
        )
    }

    private var extraLargeFloorPlanPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(statusColor)
                Text(snapshot.currentItemNames.first ?? "Current item")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                Text(state.currentItemFloorPlanTitle ?? "Floor plan")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
            }

            LazyVGrid(columns: extraLargeFloorPlanColumns, spacing: 10) {
                ForEach(Array(currentFloorPlanRows.prefix(12)), id: \.self) { row in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(row.isPriority ? statusColor : Color.white.opacity(0.32))
                            .frame(width: 6, height: 6)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.label)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.80))
                                .lineLimit(1)
                                .minimumScaleFactor(0.64)
                            Text("\(row.floorCount) floors")
                                .font(.caption2.weight(.bold).monospacedDigit())
                                .foregroundStyle(.white.opacity(0.46))
                                .lineLimit(1)
                        }
                        Spacer(minLength: 4)
                        Text(row.valueText)
                            .font(.subheadline.weight(.heavy).monospacedDigit())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .frame(minWidth: 48, alignment: .trailing)
                    }
                    .padding(9)
                    .background(
                        Color.white.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
                    )
                }
            }
        }
        .padding(12)
        .background(
            Color.white.opacity(0.055),
            in: RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
                .stroke(statusColor.opacity(0.18), lineWidth: 1)
        )
    }

    private var extraLargeFloorPlanColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    }

    private var hasPinnedOrQueuedItems: Bool {
        if let pinned = state.pinnedItemSummaries, !pinned.isEmpty { return true }
        return !snapshot.currentItemNames.isEmpty
    }

    @ViewBuilder
    private func pinnedOrQueuedPanel(compact: Bool) -> some View {
        if let pinnedSummaries = state.pinnedItemSummaries, !pinnedSummaries.isEmpty {
            pinnedItemsPanel(pinnedSummaries, compact: compact)
        } else {
            queuedItemsPanel(snapshot.currentItemNames, compact: compact)
        }
    }

    private func pinnedItemsPanel(_ items: [WidgetPinnedItemSummary], compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? WidgetDesignTokens.Spacing.compact : WidgetDesignTokens.Spacing.standard) {
            HStack(spacing: WidgetDesignTokens.Spacing.compact) {
                Image(systemName: "pin.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accentColor)
                Text("Pinned Items")
                    .font(compact ? .caption2.weight(.heavy) : .caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                Text("\(items.count)/3")
                    .font(.caption2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(accentColor)
            }

            ForEach(Array(items.prefix(3)), id: \.itemName) { item in
                HStack(spacing: compact ? 6 : 8) {
                    itemInitialBadge(itemName: item.itemName, compact: compact)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.itemName)
                            .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(WidgetDesignTokens.Opacity.primaryText))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Text("\(item.pieces) pcs · \(item.loosePieces) loose")
                            .font(.caption2.weight(.medium).monospacedDigit())
                            .foregroundStyle(.white.opacity(WidgetDesignTokens.Opacity.tertiaryText))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    Text("\(item.bundles)")
                        .font(compact ? .caption.weight(.heavy).monospacedDigit() : .subheadline.weight(.heavy).monospacedDigit())
                        .foregroundStyle(.white)
                    Text("bdl")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(WidgetDesignTokens.Opacity.tertiaryText))
                    Text(item.statusLabel)
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(statusLabelColor(item.statusLabel))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(statusLabelColor(item.statusLabel).opacity(0.14), in: Capsule())
                }
                .padding(.vertical, compact ? 4 : 6)
                .padding(.horizontal, compact ? 6 : 8)
                .background(Color.white.opacity(WidgetDesignTokens.Opacity.surface), in: RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous))
            }
        }
        .padding(compact ? 8 : 10)
        .background(
            Color.white.opacity(0.055),
            in: RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
                .stroke(accentColor.opacity(0.22), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(pinnedItemsAccessibilityLabel(items))
    }

    private func queuedItemsPanel(_ itemNames: [String], compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? WidgetDesignTokens.Spacing.compact : WidgetDesignTokens.Spacing.standard) {
            HStack(spacing: WidgetDesignTokens.Spacing.compact) {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accentColor)
                Text("Queued Items")
                    .font(compact ? .caption2.weight(.heavy) : .caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                Text("\(min(itemNames.count, 3))")
                    .font(.caption2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(accentColor)
            }

            ForEach(Array(itemNames.prefix(3)), id: \.self) { name in
                HStack(spacing: compact ? 6 : 8) {
                    itemInitialBadge(itemName: name, compact: compact)
                    Text(name)
                        .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(WidgetDesignTokens.Opacity.primaryText))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, compact ? 4 : 6)
                .padding(.horizontal, compact ? 6 : 8)
                .background(Color.white.opacity(WidgetDesignTokens.Opacity.surface), in: RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous))
            }
        }
        .padding(compact ? 8 : 10)
        .background(
            Color.white.opacity(0.055),
            in: RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Queued items: \(itemNames.prefix(3).joined(separator: ", "))")
    }

    private func pinnedItemsAccessibilityLabel(_ items: [WidgetPinnedItemSummary]) -> String {
        let summaries = items.prefix(3).map { item in
            "\(item.itemName), \(item.bundles) bundles, \(item.statusLabel)"
        }
        return "Pinned items: \(summaries.joined(separator: "; "))"
    }

    private func statusLabelColor(_ label: String) -> Color {
        if label.hasPrefix("Short") { return .red }
        if label.hasPrefix("Over") { return .orange }
        return .green
    }

    private var largeEmptyPlanPanel: some View {
        HStack(spacing: 10) {
            Image(systemName: "shippingbox.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(statusColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.currentItemSummary)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(state.nextCarryGroupTitle ?? "Select current item and next carry in HimmerFlow")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(10)
        .background(
            Color.white.opacity(0.055),
            in: RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
        )
    }

    private var extraLargeEmptyPlanPanel: some View {
        HStack(spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(statusColor)
            VStack(alignment: .leading, spacing: 3) {
                Text(snapshot.currentItemSummary)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(state.nextCarryGroupTitle ?? "Select current item and next carry in HimmerFlow")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(12)
        .background(
            Color.white.opacity(0.055),
            in: RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
        )
    }

    private var circularAccessory: some View {
        Group {
            if hasTower {
                Gauge(value: snapshot.progressFraction) {
                    Image(systemName: "building.2")
                } currentValueLabel: {
                    Text("\(snapshot.completedFloors)/\(snapshot.floorCount)")
                        .font(.caption2.weight(.heavy).monospacedDigit())
                        .contentTransition(.numericText())
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(urgencyColor)
                .accessibilityLabel("Tower delivery progress")
                .accessibilityValue(progressAccessibilityValue)
            } else {
                Image(systemName: "building.2")
                    .accessibilityLabel("No active delivery session")
            }
        }
    }

    private var inlineAccessory: some View {
        if hasTower {
            Text("\(snapshot.shortTowerName) · \(snapshot.completedFloors)/\(snapshot.floorCount) · \(shortCountdownText)")
        } else {
            Text("HimmerFlow · Open to start")
        }
    }

    private var rectangularAccessory: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(hasTower ? snapshot.towerName : "HimmerFlow")
                .font(.headline.weight(.semibold))
                .lineLimit(1)
            if hasTower {
                Text("\(snapshot.completedFloors)/\(snapshot.floorCount) floors · \(snapshot.remainingFloors) left")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .lineLimit(1)
                Text("\(compactCountdownText) · \(snapshot.semanticState.displayName)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("No active delivery session")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text("Open app to begin")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .containerBackground(for: .widget) {
            AccessoryWidgetBackground()
        }
    }

    private var statusBadge: some View {
        Text(badgeText)
            .font(.caption2.weight(.heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.38), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
            .contentTransition(.opacity)
            .accessibilityLabel("Delivery status")
            .accessibilityValue(snapshot.semanticState.displayName)
    }

    private var countdownPill: some View {
        HStack(spacing: 5) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "clock.fill")
                .font(.caption2.weight(.bold))
            Text(compactCountdownText)
                .font(.caption.weight(.heavy).monospacedDigit())
                .contentTransition(.numericText())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.34), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Countdown")
        .accessibilityValue(countdownAccessibilityValue)
    }

    private var compactCountdownText: String {
        roundedCountdownText(compact: true)
    }

    private var shortCountdownText: String {
        compactCountdownText
    }

    private var progressAccessibilityValue: String {
        guard hasTower else { return "No active delivery session" }
        return "\(snapshot.completedFloors) of \(snapshot.floorCount) floors complete, \(snapshot.remainingFloors) remaining"
    }

    private var countdownAccessibilityValue: String {
        if isComplete { return "Shift complete" }
        if compactCountdownText.hasPrefix("+") {
            return "Overtime \(String(compactCountdownText.dropFirst()))"
        }
        return countdownText
    }

    private var widgetDeepLink: URL? {
        var components = URLComponents()
        components.scheme = "himmerflow"
        components.host = "widget"
        if shouldShowDeliveryCommandBoard || hasTower {
            components.path = "/delivery"
            components.queryItems = [
                URLQueryItem(name: "source", value: "widget"),
                URLQueryItem(name: "tower", value: snapshot.towerName)
            ]
        } else {
            components.path = "/start"
            components.queryItems = [URLQueryItem(name: "source", value: "widget")]
        }
        return components.url
    }

    private var widgetAccessibilityLabel: String {
        if shouldShowDeliveryCommandBoard {
            if hasRouteComplete {
                return "\(state.towerName) route complete. \(progressText) floors delivered."
            }
            if let floor = displayFloorNumber {
                let items = currentTripItems.isEmpty ? "current trip" : currentTripItems.joined(separator: ", ")
                return "\(state.towerName) delivery. Floor \(floor). Items: \(items). \(progressText) floors complete."
            }
        }
        if hasTower {
            return "\(state.towerName) tower. \(snapshot.completedFloors) of \(snapshot.floorCount) floors complete. Status: \(badgeText). \(countdownAccessibilityValue)."
        }
        return "HimmerFlow. No tower selected."
    }

    private var widgetAccessibilityHint: String {
        if shouldShowDeliveryCommandBoard, hasActiveDelivery {
            return "Double tap to open delivery command center. Use complete floor action when available."
        }
        return "Double tap to open HimmerFlow."
    }

    private func roundedCountdownText(compact: Bool) -> String {
        if isComplete { return compact ? "Done" : "Shift complete" }
        guard let targetTime = snapshot.targetTime else {
            return compact ? snapshot.compactCountdownText : snapshot.countdownText
        }

        // Round partial minutes up so countdowns do not show "Due now" before the target time.
        let rawSeconds = targetTime.timeIntervalSince(entry.date)
        if rawSeconds < 0 {
            let overtimeMinutes = max(1, Int((-rawSeconds / 60).rounded(.up)))
            return compact ? "+\(overtimeMinutes)m" : "Overtime +\(overtimeMinutes)m"
        }

        if rawSeconds < 60 {
            return "<1m"
        }

        let remainingMinutes = Int((rawSeconds / 60).rounded(.up))

        let hours = remainingMinutes / 60
        let minutes = remainingMinutes % 60
        if hours > 0 {
            return compact ? "\(hours)h \(minutes)m" : "\(hours)h \(minutes)m left"
        }
        return compact ? "\(minutes)m" : "\(minutes)m left"
    }

    private var emptySmall: some View {
        VStack(alignment: .leading, spacing: WidgetDesignTokens.Spacing.standard) {
            HStack {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(WidgetDesignTokens.ColorToken.defaultAccent)
                Spacer()
                statusBadge
            }
            Spacer()
            Text("HimmerFlow")
                .font(.headline.weight(.heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text("Choose a tower in the app")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(WidgetDesignTokens.Opacity.secondaryText))
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("HimmerFlow. No tower selected. Open the app to choose a tower.")
    }

    private var emptyMedium: some View {
        VStack(alignment: .leading, spacing: WidgetDesignTokens.Spacing.standard) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(WidgetDesignTokens.ColorToken.defaultAccent)
                    .frame(width: 4, height: 32)
                Text("HimmerFlow")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(WidgetDesignTokens.ColorToken.defaultAccent)
            }
            Spacer(minLength: 0)
            Text("No tower selected")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(WidgetDesignTokens.Opacity.primaryText))
                .lineLimit(1)
            Text("Open HimmerFlow, pick your tower, and pin items for this widget.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(WidgetDesignTokens.Opacity.secondaryText))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("HimmerFlow. No tower selected. Open the app to pick a tower and pin items.")
    }

    private var emptyLarge: some View {
        VStack(alignment: .leading, spacing: WidgetDesignTokens.Spacing.content) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(WidgetDesignTokens.ColorToken.defaultAccent)
                    .frame(width: 4, height: 40)
                Text("HimmerFlow")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(WidgetDesignTokens.ColorToken.defaultAccent)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 6) {
                Text("No tower selected")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white.opacity(WidgetDesignTokens.Opacity.primaryText))
                    .lineLimit(1)
                Text("Open HimmerFlow, choose a tower, then start delivery to fill this command board with live floor progress and pinned item counts.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(WidgetDesignTokens.Opacity.secondaryText))
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("HimmerFlow command board. No tower selected. Open the app to choose a tower and start delivery.")
    }

    private func progressRing(size: CGFloat, lineWidth: CGFloat, centerFont: Font) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: state.progressFraction)
                .stroke(
                    AngularGradient(
                        colors: [urgencyColor.opacity(0.72), urgencyColor, urgencyColor.opacity(0.72)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text("\(snapshot.completedFloors)/\(snapshot.floorCount)")
                    .font(centerFont.monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text(snapshot.semanticState.compactDisplayName.lowercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.48))
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tower delivery progress")
        .accessibilityValue(progressAccessibilityValue)
    }

    private func commandDetail(title: String, value: String, symbol: String, emphasis: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(statusColor)
                Text(title)
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.white.opacity(0.52))
                    .textCase(.uppercase)
            }
            Text(value)
                .font((emphasis ? Font.caption.weight(.heavy) : Font.caption.weight(.semibold)))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .topLeading)
        .padding(8)
        .background(
            Color.white.opacity(0.065),
            in: RoundedRectangle(cornerRadius: HimmerFlowWidgetDesignSystem.Radius.compact, style: .continuous)
        )
    }
}

struct HimmerFlow_Widget: Widget {
    let kind = "HimmerFlow_Widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: HimmerFlowTimelineProvider()) { entry in
            HimmerFlow_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("HimmerFlow")
        .description("Shift Pulse and Delivery Command for tower linen delivery.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}

private extension View {
    func linenCommandBackground(accentColor: Color, activeColor: Color) -> some View {
        self
            .padding()
            .containerBackground(for: .widget) {
                ZStack {
                    WidgetDesignTokens.surfaceGradient(accent: accentColor, active: activeColor)
                    RoundedRectangle(cornerRadius: WidgetDesignTokens.Radius.surface, style: .continuous)
                        .strokeBorder(.white.opacity(WidgetDesignTokens.Opacity.stroke), lineWidth: 0.5)
                        .padding(1)
                }
            }
    }
}

private extension SharedWidgetState {
    static var diamondActivePreview: SharedWidgetState {
        SharedWidgetState(
            towerName: "Diamond",
            towerColorHex: "#7C878E",
            floorCount: 15,
            completedFloors: 9,
            remainingFloors: 6,
            targetTime: Calendar.current.date(byAdding: .minute, value: 134, to: .now),
            shiftStartTime: Calendar.current.date(byAdding: .hour, value: -3, to: .now),
            shiftEndTime: Calendar.current.date(byAdding: .hour, value: 4, to: .now),
            currentItemName: "Bath Towels",
            nextCarryGroupTitle: "WC + HT Carry Trip",
            statusText: "9/15 floors complete",
            lastUpdated: .now,
            isActiveSession: true,
            isDemoDay: false
        )
    }

    static var lagoonReadyPreview: SharedWidgetState {
        SharedWidgetState(
            towerName: "Lagoon",
            towerColorHex: "#2F8C9D",
            floorCount: 21,
            completedFloors: 0,
            remainingFloors: 21,
            targetTime: nil,
            shiftStartTime: nil,
            shiftEndTime: nil,
            currentItemName: nil,
            nextCarryGroupTitle: nil,
            statusText: "Ready for Lagoon",
            lastUpdated: .now,
            isActiveSession: false,
            isDemoDay: false
        )
    }

    static var demoDayPreview: SharedWidgetState {
        SharedWidgetState(
            towerName: "Lagoon",
            towerColorHex: "#2F8C9D",
            floorCount: 21,
            completedFloors: 4,
            remainingFloors: 17,
            targetTime: Calendar.current.date(byAdding: .minute, value: 85, to: .now),
            shiftStartTime: Calendar.current.date(byAdding: .hour, value: -1, to: .now),
            shiftEndTime: Calendar.current.date(byAdding: .hour, value: 5, to: .now),
            currentItemName: "Pillow Cases",
            nextCarryGroupTitle: "Trip 2: Towels",
            statusText: "Demo Day progress",
            lastUpdated: .now,
            isActiveSession: true,
            isDemoDay: true
        )
    }

    static var finalFloorsPreview: SharedWidgetState {
        SharedWidgetState(
            towerName: "Tapa",
            towerColorHex: "#9B6A3D",
            floorCount: 33,
            completedFloors: 30,
            remainingFloors: 3,
            targetTime: Calendar.current.date(byAdding: .minute, value: 42, to: .now),
            shiftStartTime: Calendar.current.date(byAdding: .hour, value: -5, to: .now),
            shiftEndTime: Calendar.current.date(byAdding: .hour, value: 1, to: .now),
            currentItemName: "King Sheets",
            nextCarryGroupTitle: "Final north stack",
            statusText: "30/33 floors complete",
            lastUpdated: .now,
            isActiveSession: true,
            isDemoDay: false
        )
    }

    static var openingPassPreview: SharedWidgetState {
        SharedWidgetState(
            towerName: "Diamond",
            towerColorHex: "#7C878E",
            floorCount: 15,
            completedFloors: 1,
            remainingFloors: 14,
            targetTime: Calendar.current.date(byAdding: .minute, value: 160, to: .now),
            shiftStartTime: Calendar.current.date(byAdding: .minute, value: -20, to: .now),
            shiftEndTime: Calendar.current.date(byAdding: .hour, value: 5, to: .now),
            currentItemName: "King Covers",
            nextCarryGroupTitle: "Opening pass",
            statusText: "Opening pass",
            lastUpdated: .now,
            isActiveSession: true,
            isDemoDay: false
        )
    }

    static var towelRunPreview: SharedWidgetState {
        var s = SharedWidgetState(
            towerName: "Alii",
            towerColorHex: "#B8665A",
            floorCount: 14,
            completedFloors: 4,
            remainingFloors: 10,
            targetTime: Calendar.current.date(byAdding: .minute, value: 74, to: .now),
            shiftStartTime: Calendar.current.date(byAdding: .hour, value: -2, to: .now),
            shiftEndTime: Calendar.current.date(byAdding: .hour, value: 3, to: .now),
            currentItemName: "Bath Towels",
            nextCarryGroupTitle: "Towel stack",
            statusText: "Towel run",
            lastUpdated: .now,
            isActiveSession: true,
            isDemoDay: false
        )
        s.currentItemNames = ["Bath Towels", "Hand Towels", "Washcloth"]
        return s
    }

    static var nearTargetPreview: SharedWidgetState {
        SharedWidgetState(
            towerName: "Alii",
            towerColorHex: "#B8665A",
            floorCount: 14,
            completedFloors: 11,
            remainingFloors: 3,
            targetTime: Calendar.current.date(byAdding: .minute, value: 24, to: .now),
            shiftStartTime: Calendar.current.date(byAdding: .hour, value: -4, to: .now),
            shiftEndTime: Calendar.current.date(byAdding: .hour, value: 1, to: .now),
            currentItemName: "Double Sheets",
            nextCarryGroupTitle: "Duvet recovery carry",
            statusText: "11/15 floors complete",
            lastUpdated: .now,
            isActiveSession: true,
            isDemoDay: false
        )
    }

    static var completedShiftPreview: SharedWidgetState {
        SharedWidgetState(
            towerName: "Diamond",
            towerColorHex: "#7C878E",
            floorCount: 15,
            completedFloors: 15,
            remainingFloors: 0,
            targetTime: Calendar.current.date(byAdding: .minute, value: 12, to: .now),
            shiftStartTime: Calendar.current.date(byAdding: .hour, value: -6, to: .now),
            shiftEndTime: Calendar.current.date(byAdding: .minute, value: 30, to: .now),
            currentItemName: nil,
            nextCarryGroupTitle: nil,
            statusText: "Shift complete",
            lastUpdated: .now,
            isActiveSession: false,
            isDemoDay: false
        )
    }

    static var pausedShiftPreview: SharedWidgetState {
        SharedWidgetState(
            towerName: "Rainbow",
            towerColorHex: "#6F7EDB",
            floorCount: 14,
            completedFloors: 7,
            remainingFloors: 7,
            targetTime: Calendar.current.date(byAdding: .minute, value: 96, to: .now),
            shiftStartTime: Calendar.current.date(byAdding: .hour, value: -2, to: .now),
            shiftEndTime: Calendar.current.date(byAdding: .hour, value: 3, to: .now),
            currentItemName: "Hand Towels",
            nextCarryGroupTitle: "Restart south side",
            statusText: "Paused at 7/14 floors",
            lastUpdated: .now,
            isActiveSession: false,
            isDemoDay: false
        )
    }

    static var noActiveSessionPreview: SharedWidgetState {
        SharedWidgetState(
            towerName: "No Active Tower",
            towerColorHex: nil,
            floorCount: 0,
            completedFloors: 0,
            remainingFloors: 0,
            targetTime: nil,
            shiftStartTime: nil,
            shiftEndTime: nil,
            currentItemName: nil,
            nextCarryGroupTitle: nil,
            statusText: "Open HimmerFlow to start",
            lastUpdated: .now,
            isActiveSession: false,
            isDemoDay: false
        )
    }

    static var overtimePreview: SharedWidgetState {
        var s = SharedWidgetState(
            towerName: "G.I.",
            towerColorHex: "#5A7A5A",
            floorCount: 18,
            completedFloors: 16,
            remainingFloors: 2,
            targetTime: Calendar.current.date(byAdding: .minute, value: -12, to: .now),
            shiftStartTime: Calendar.current.date(byAdding: .hour, value: -7, to: .now),
            shiftEndTime: Calendar.current.date(byAdding: .minute, value: 30, to: .now),
            currentItemName: "King Sheets",
            nextCarryGroupTitle: "Final north hallway",
            statusText: "16/18 floors — overtime",
            lastUpdated: .now,
            isActiveSession: true,
            isDemoDay: false
        )
        s.currentItemNames = ["King Sheets", "King Covers"]
        return s
    }

    static var multiItemPreview: SharedWidgetState {
        var s = SharedWidgetState(
            towerName: "Diamond",
            towerColorHex: "#7C878E",
            floorCount: 15,
            completedFloors: 5,
            remainingFloors: 10,
            targetTime: Calendar.current.date(byAdding: .minute, value: 95, to: .now),
            shiftStartTime: Calendar.current.date(byAdding: .hour, value: -1, to: .now),
            shiftEndTime: Calendar.current.date(byAdding: .hour, value: 5, to: .now),
            currentItemName: "Bath Towels",
            nextCarryGroupTitle: "Trip 2: Sheets + Covers",
            statusText: "5/15 floors complete",
            lastUpdated: .now,
            isActiveSession: true,
            isDemoDay: false
        )
        s.currentItemNames = ["Bath Towels", "Double Sheets", "Double Covers"]
        return s
    }
}

struct HimmerFlowWidgetPreviews: PreviewProvider {
    static var previews: some View {
        previewList
    }

    @ViewBuilder
    private static var previewList: some View {
        preview(.diamondActivePreview, family: .systemSmall, name: "Small - Diamond Active")
        preview(.diamondActivePreview, family: .systemSmall, name: "Small - Diamond Active - Increased Contrast")
            .environment(\.legibilityWeight, .bold)
        preview(.lagoonReadyPreview, family: .systemSmall, name: "Small - Lagoon Ready")
        preview(.demoDayPreview, family: .systemSmall, name: "Small - Demo Day")
        preview(.overtimePreview, family: .systemSmall, name: "Small - Overtime")
        preview(.noActiveSessionPreview, family: .systemSmall, name: "Small - No Active Session")
        preview(.openingPassPreview, family: .systemMedium, name: "Medium - Opening Pass")
        preview(.towelRunPreview, family: .systemMedium, name: "Medium - Towel Run")
        preview(.multiItemPreview, family: .systemMedium, name: "Medium - Multi Item")
        preview(.finalFloorsPreview, family: .systemMedium, name: "Medium - Final Floors")
        preview(.nearTargetPreview, family: .systemMedium, name: "Medium - Near Target")
        preview(.overtimePreview, family: .systemMedium, name: "Medium - Overtime")
        preview(.pausedShiftPreview, family: .systemMedium, name: "Medium - Paused")
        preview(.noActiveSessionPreview, family: .systemMedium, name: "Medium - No Active Session")
        preview(.finalFloorsPreview, family: .systemLarge, name: "Large - Tapa Command")
        preview(.diamondActivePreview, family: .systemLarge, name: "Large - Diamond Active")
        preview(.overtimePreview, family: .systemLarge, name: "Large - Overtime")
        preview(.noActiveSessionPreview, family: .systemLarge, name: "Large - No Active Session")
        preview(.finalFloorsPreview, family: .systemExtraLarge, name: "Extra Large - Tapa Command")
        preview(.diamondActivePreview, family: .systemExtraLarge, name: "Extra Large - Diamond Active")
        preview(.diamondActivePreview, family: .accessoryInline, name: "Inline - Diamond Active")
        preview(.nearTargetPreview, family: .accessoryInline, name: "Inline - Near Target")
        preview(.noActiveSessionPreview, family: .accessoryInline, name: "Inline - No Active Session")
        preview(.diamondActivePreview, family: .accessoryCircular, name: "Circular - Diamond Active")
        preview(.completedShiftPreview, family: .accessoryCircular, name: "Circular - Completed")
        preview(.noActiveSessionPreview, family: .accessoryCircular, name: "Circular - No Active Session")
        preview(.diamondActivePreview, family: .accessoryRectangular, name: "Rectangular - Diamond Active")
        preview(.completedShiftPreview, family: .accessoryRectangular, name: "Rectangular - Completed")
        preview(.noActiveSessionPreview, family: .accessoryRectangular, name: "Rectangular - No Active Session")
    }

    private static func preview(_ state: SharedWidgetState, family: WidgetFamily, name: String) -> some View {
        HimmerFlow_WidgetEntryView(
            entry: HimmerFlowWidgetEntry(date: .now, state: state, configuration: ConfigurationAppIntent())
        )
        .previewContext(WidgetPreviewContext(family: family))
        .previewDisplayName(name)
    }
}
