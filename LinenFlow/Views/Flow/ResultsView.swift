import SwiftUI
import SwiftData

struct ResultsView: View {
    @Environment(FlowViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Binding var path: NavigationPath

    @State private var savedConfirmation: String?
    @State private var savedAt: Date?
    @State private var expandedResultItemName: String?

    var body: some View {
        AppBackground(accentColor: viewModel.selectedTower.flatMap { Color(hex: $0.identityColorHex ?? "") }) {
            ScrollView {
                VStack(spacing: 16) {
                    FlowProgressHeader(current: .results)

                    if let tower = viewModel.selectedTower {
                        headerCard(tower)
                    }

                    if !viewModel.validationWarnings.isEmpty {
                        WarningCard(warnings: viewModel.validationWarnings)
                    }

                    if let confirmation = savedConfirmation {
                        savedBanner(confirmation)
                    }

                    if viewModel.calculationSummaries.isEmpty {
                        EmptyStateView(
                            systemImage: "function",
                            title: "No results yet",
                            message: "Add receiving entries and recalculate."
                        )
                    } else {
                        resultsDashboard
                        shortageWarningCards
                        smartDeliveryRecommendationCard

                        VStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Spacer(minLength: 0)
                                Image(systemName: "pin")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.45))
                                Text("Pin up to 3 items to show on widget")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.45))
                                let pinnedCount = viewModel.pinnedWidgetItemNames.count
                                if pinnedCount > 0 {
                                    Text("· \(pinnedCount)/3")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.cyan.opacity(0.85))
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 4)

                            ForEach(viewModel.calculationSummaries) { summary in
                                let isPinned = viewModel.isWidgetPinned(summary.itemName)
                                let pinnedCount = viewModel.pinnedWidgetItemNames.count
                                ResultCard(
                                    summary: summary,
                                    usesParSystem: viewModel.usesParSystem,
                                    isPinned: isPinned,
                                    canPin: pinnedCount < 3 || isPinned,
                                    isExpanded: expandedResultItemName == summary.itemName,
                                    onToggle: {
                                        expandedResultItemName = expandedResultItemName == summary.itemName ? nil : summary.itemName
                                    },
                                    onPinToggle: { viewModel.toggleWidgetPin(for: summary.itemName) }
                                ) {
                                    path.append(FlowStep.rebalance(itemName: summary.itemName))
                                } onViewFloorPlan: {
                                    path.append(FlowStep.floorPlan)
                                }
                            }
                        }

                        widgetPreviewPanel
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 140)
            }
        }
        .safeAreaInset(edge: .bottom) {
            StickyBottomActionBar {
                PrimaryActionButton(
                    title: "View Floor Plan",
                    systemImage: "list.number",
                    isEnabled: !viewModel.calculationSummaries.isEmpty
                ) {
                    path.append(FlowStep.floorPlan)
                }
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        editReceived()
                    } label: {
                        Label("Edit Received", systemImage: "pencil")
                    }
                    Button {
                        saveLog()
                    } label: {
                        Label("Save Daily Log", systemImage: "tray.and.arrow.down.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More result actions")
            }
        }
    }

    @ViewBuilder
    private var widgetPreviewPanel: some View {
        let pinned = viewModel.pinnedWidgetItemNames
        let summaries = viewModel.calculationSummaries

        if !pinned.isEmpty {
            PremiumCard(accentColor: .cyan.opacity(0.5)) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 7) {
                        Image(systemName: "apps.iphone")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.cyan)
                        Text("Widget Preview")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(pinned.count)/3")
                            .font(.caption2.weight(.heavy).monospacedDigit())
                            .foregroundStyle(.cyan)
                    }

                    if let tower = viewModel.selectedTower {
                        HStack(spacing: 6) {
                            Text(tower.name)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.62))
                            Text("·")
                                .foregroundStyle(.white.opacity(0.32))
                            Text("\(tower.floorCount) floors")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.48))
                        }
                    }

                    ForEach(pinned, id: \.self) { itemName in
                        if let summary = summaries.first(where: { $0.itemName == itemName }) {
                            widgetPreviewItemRow(summary)
                        }
                    }

                    Text("Matches your home screen widget.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.36))
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(widgetPreviewAccessibilityLabel)
        }
    }

    private func widgetPreviewItemRow(_ summary: CalculationSummary) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(summary.itemName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("\(summary.receivedPieces) pcs · \(summary.loosePieces) loose")
                    .font(.caption2.weight(.medium).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Text("\(summary.deliverableBundles)")
                .font(.subheadline.weight(.heavy).monospacedDigit())
                .foregroundStyle(.white)
            Text("bdl")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.48))

            let statusLabel = widgetStatusLabel(for: summary)
            Text(statusLabel)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(widgetStatusColor(statusLabel))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(widgetStatusColor(statusLabel).opacity(0.14), in: Capsule())
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func widgetStatusLabel(for summary: CalculationSummary) -> String {
        switch summary.status {
        case .shortage: return "Short"
        case .overage: return "Over"
        case .exact: return "Exact"
        }
    }

    private func widgetStatusColor(_ label: String) -> Color {
        switch label {
        case "Short": return .red
        case "Over": return .orange
        case "Exact": return .green
        default: return .white
        }
    }

    private var widgetPreviewAccessibilityLabel: String {
        let pinned = viewModel.pinnedWidgetItemNames
        let summaries = viewModel.calculationSummaries
        let items = pinned.compactMap { name in
            summaries.first(where: { $0.itemName == name })
        }
        let descriptions = items.map { "\($0.itemName), \($0.deliverableBundles) bundles, \(widgetStatusLabel(for: $0))" }
        return "Widget preview showing \(pinned.count) pinned items. \(descriptions.joined(separator: ". "))."
    }

    private var resultsDashboard: some View {
        let stats = resultStats
        return PremiumCard(accentColor: stats.statusColor) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: stats.statusIcon)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(stats.statusColor.opacity(0.72), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: stats.statusColor.opacity(0.22), radius: 10, y: 5)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(stats.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Text(stats.nextAction)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Text("\(stats.readyCount)/\(stats.itemCount)")
                        .font(.headline.weight(.bold).monospacedDigit())
                        .foregroundStyle(stats.statusColor)
                        .contentTransition(.numericText())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(stats.statusColor.opacity(0.14), in: Capsule())
                }

                HStack(spacing: 8) {
                    dashboardFact("Bundles", "\(stats.fullBundles)", "ready", tint: .blue)
                    dashboardFact("Loose", "\(stats.loosePieces)", "pcs", tint: stats.loosePieces > 0 ? .orange : .white)
                    dashboardFact("Short", "\(stats.shortageCount)", "items", tint: stats.shortageCount > 0 ? .red : .white)
                }

                HStack(spacing: 8) {
                    dashboardFact("Enough", "\(stats.enoughCount)", "items", tint: .green)
                    dashboardFact("Overage", "\(stats.overageCount)", "items", tint: stats.overageCount > 0 ? .mint : .white)
                    dashboardFact(viewModel.usesParSystem ? "Required" : "Total", "\(stats.requiredPieces)", "pcs", tint: .white)
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    @ViewBuilder
    private var shortageWarningCards: some View {
        let shortages = viewModel.calculationSummaries
            .filter { $0.status == .shortage }
            .sorted { lhs, rhs in
                if lhs.shortageBundles == rhs.shortageBundles {
                    return lhs.itemName < rhs.itemName
                }
                return lhs.shortageBundles > rhs.shortageBundles
            }

        if !shortages.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                        .frame(width: 24, height: 24)
                        .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Shortage warnings")
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(.white)
                        Text("\(shortages.count) item\(shortages.count == 1 ? "" : "s") need review before delivery.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.56))
                    }
                    Spacer()
                }

                ForEach(shortages) { summary in
                    ShortageWarningCard(summary: summary) {
                        path.append(FlowStep.rebalance(itemName: summary.itemName))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var smartDeliveryRecommendationCard: some View {
        let recommendation = deliveryRecommendation

        Button {
            openDeliveryRecommendation(recommendation)
        } label: {
            PremiumCard(accentColor: recommendation.tint.opacity(0.82)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: recommendation.systemImage)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(recommendation.tint)
                            .frame(width: 42, height: 42)
                            .background(recommendation.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(recommendation.tint.opacity(0.2), lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Smart delivery recommendation")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(.white.opacity(0.54))
                                .textCase(.uppercase)
                            Text(recommendation.title)
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(recommendation.message)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.62))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 8)
                    }

                    HStack(spacing: 8) {
                        recommendationMetric(recommendation.primaryLabel, recommendation.primaryValue, tint: recommendation.tint)
                        recommendationMetric("Short", "\(resultStats.shortageCount)", tint: resultStats.shortageCount > 0 ? .red : .white)
                        recommendationMetric("Loose", "\(resultStats.loosePieces)", tint: resultStats.loosePieces > 0 ? .orange : .white)
                    }

                    HStack(spacing: 7) {
                        Image(systemName: recommendation.actionSystemImage)
                        Text(recommendation.actionTitle)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white.opacity(0.78))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Double tap to open the recommended next step.")
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    private func headerCard(_ tower: Tower) -> some View {
        PremiumCard(accentColor: Color(hex: tower.identityColorHex ?? "")) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(tower.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        if viewModel.isDemoDay {
                            Text("Demo Day")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.2), in: Capsule())
                                .foregroundStyle(.purple)
                        }
                    }
                    Text("\(tower.floorCount) floors · \(viewModel.calculationSummaries.count) items calculated")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
            }
        }
    }

    private func savedBanner(_ message: String) -> some View {
        PremiumCard(accentColor: .green) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text(message)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    if let savedAt {
                        Text(savedAt.formatted(date: .omitted, time: .standard))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
    }

    private func saveLog() {
        switch DailyLogSaveService.save(viewModel: viewModel, context: modelContext) {
        case .success:
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            savedConfirmation = "Daily log saved."
            savedAt = .now
        case .failure(let err):
            savedConfirmation = err.errorDescription ?? "Save failed."
        }
    }

    private func editReceived() {
        // Pop back to Receiving (path.last is .results, before is .review).
        if path.count >= 2 {
            path.removeLast(2)
        } else if path.count >= 1 {
            path.removeLast()
        }
    }

    private func openDeliveryRecommendation(_ recommendation: SmartDeliveryRecommendation) {
        if let itemName = recommendation.rebalanceItemName {
            path.append(FlowStep.rebalance(itemName: itemName))
        } else {
            path.append(FlowStep.floorPlan)
        }
    }

    private var resultStats: ResultDashboardStats {
        let summaries = viewModel.calculationSummaries
        let shortageCount = summaries.filter { $0.status == .shortage }.count
        let overageCount = summaries.filter { $0.status == .overage }.count
        let exactCount = summaries.filter { $0.status == .exact }.count
        let fullBundles = summaries.reduce(0) { $0 + $1.fullBundles }
        let loosePieces = summaries.reduce(0) { $0 + $1.loosePieces }
        let requiredPieces = summaries.reduce(0) { $0 + $1.requiredPieces }
        let readyCount = exactCount + overageCount

        let title: String
        let nextAction: String
        let statusIcon: String
        let statusColor: Color
        if shortageCount > 0 {
            title = "Needs Review"
            nextAction = "Review shortage items before starting delivery."
            statusIcon = "exclamationmark.triangle.fill"
            statusColor = .orange
        } else if loosePieces > 0, viewModel.deliveryUnitIsBundles {
            title = "Bundle Plan Ready"
            nextAction = "Loose pieces are listed separately and are not part of default delivery."
            statusIcon = "checkmark.seal.fill"
            statusColor = .blue
        } else {
            title = "Ready for Floor Plan"
            nextAction = "Open the floor plan when the received count looks correct."
            statusIcon = "checkmark.circle.fill"
            statusColor = .green
        }

        return ResultDashboardStats(
            itemCount: summaries.count,
            readyCount: readyCount,
            shortageCount: shortageCount,
            overageCount: overageCount,
            enoughCount: readyCount,
            fullBundles: fullBundles,
            loosePieces: loosePieces,
            requiredPieces: requiredPieces,
            title: title,
            nextAction: nextAction,
            statusIcon: statusIcon,
            statusColor: statusColor
        )
    }

    private var deliveryRecommendation: SmartDeliveryRecommendation {
        let summaries = viewModel.calculationSummaries
        let shortages = summaries
            .filter { $0.status == .shortage }
            .sorted { lhs, rhs in
                if lhs.shortageBundles == rhs.shortageBundles {
                    return lhs.itemName < rhs.itemName
                }
                return lhs.shortageBundles > rhs.shortageBundles
            }

        if let shortage = shortages.first {
            return SmartDeliveryRecommendation(
                title: "Review \(shortage.itemName) before loading",
                message: "This item is short \(shortage.shortageBundles) bundle\(shortage.shortageBundles == 1 ? "" : "s"). Fix the recovery plan before starting the floor route.",
                systemImage: "exclamationmark.triangle.fill",
                tint: .red,
                primaryLabel: "Review",
                primaryValue: shortage.itemName,
                actionTitle: "Open Recovery Assist",
                actionSystemImage: "arrow.triangle.2.circlepath",
                rebalanceItemName: shortage.itemName
            )
        }

        if viewModel.deliveryUnitIsBundles,
           let looseSummary = summaries.filter({ $0.loosePieces > 0 }).sorted(by: { $0.loosePieces > $1.loosePieces }).first {
            return SmartDeliveryRecommendation(
                title: "Keep loose pieces separate",
                message: "\(looseSummary.itemName) has \(looseSummary.loosePieces) loose pcs. The floor plan stays bundle-first, so keep these out of the default delivery load.",
                systemImage: "circle.grid.2x2.fill",
                tint: .orange,
                primaryLabel: "Loose",
                primaryValue: "\(looseSummary.loosePieces) pcs",
                actionTitle: "View Floor Plan",
                actionSystemImage: "list.number",
                rebalanceItemName: nil
            )
        }

        if !viewModel.deliveryUnitIsBundles {
            return SmartDeliveryRecommendation(
                title: "Review the piece floor plan",
                message: "Timeshare delivery uses received pieces divided across delivery floors. No par cap or shortage rule is applied.",
                systemImage: "number.circle.fill",
                tint: .teal,
                primaryLabel: "Pieces",
                primaryValue: "\(summaries.reduce(0) { $0 + $1.receivedPieces })",
                actionTitle: "View Floor Plan",
                actionSystemImage: "list.number",
                rebalanceItemName: nil
            )
        }

        let deliverable = summaries
            .filter { $0.deliverableBundles > 0 }
            .sorted { lhs, rhs in
                if lhs.deliverableBundles == rhs.deliverableBundles {
                    return lhs.itemName < rhs.itemName
                }
                return lhs.deliverableBundles < rhs.deliverableBundles
            }

        if let singleBundle = deliverable.first(where: { $0.deliverableBundles == 1 }) {
            return SmartDeliveryRecommendation(
                title: "Start with \(singleBundle.itemName)",
                message: "It only has 1 deliverable bundle, making it a good first pass before heavier items.",
                systemImage: "1.circle.fill",
                tint: .cyan,
                primaryLabel: "First",
                primaryValue: "1 bdl",
                actionTitle: "View Floor Plan",
                actionSystemImage: "list.number",
                rebalanceItemName: nil
            )
        }

        if let lightest = deliverable.first {
            return SmartDeliveryRecommendation(
                title: "Start with the lightest bundle group",
                message: "\(lightest.itemName) has \(lightest.deliverableBundles) deliverable bundles, the smallest current bundle load.",
                systemImage: "arrow.up.forward.circle.fill",
                tint: .blue,
                primaryLabel: "Lightest",
                primaryValue: "\(lightest.deliverableBundles) bdl",
                actionTitle: "View Floor Plan",
                actionSystemImage: "list.number",
                rebalanceItemName: nil
            )
        }

        return SmartDeliveryRecommendation(
            title: "Open the floor plan",
            message: "The received entries are calculated. Review the floor plan before delivery.",
            systemImage: "list.bullet.rectangle.fill",
            tint: .green,
            primaryLabel: "Items",
            primaryValue: "\(summaries.count)",
            actionTitle: "View Floor Plan",
            actionSystemImage: "list.number",
            rebalanceItemName: nil
        )
    }

    private func dashboardFact(_ label: String, _ value: String, _ detail: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(.white.opacity(0.56))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.42))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .padding(.horizontal, 6)
        .background(
            LinearGradient(
                colors: [
                    tint.opacity(tint == .white ? 0.045 : 0.13),
                    Color.white.opacity(0.035)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(tint.opacity(tint == .white ? 0.07 : 0.18), lineWidth: 1)
        )
    }

    private func recommendationMetric(_ label: String, _ value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.heavy).monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
        .background(tint.opacity(tint == .white ? 0.045 : 0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(tint.opacity(tint == .white ? 0.07 : 0.18), lineWidth: 1)
        )
    }
}

// MARK: - Result card

private struct ResultDashboardStats {
    let itemCount: Int
    let readyCount: Int
    let shortageCount: Int
    let overageCount: Int
    let enoughCount: Int
    let fullBundles: Int
    let loosePieces: Int
    let requiredPieces: Int
    let title: String
    let nextAction: String
    let statusIcon: String
    let statusColor: Color
}

private struct SmartDeliveryRecommendation {
    let title: String
    let message: String
    let systemImage: String
    let tint: Color
    let primaryLabel: String
    let primaryValue: String
    let actionTitle: String
    let actionSystemImage: String
    let rebalanceItemName: String?
}

private struct ShortageWarningCard: View {
    let summary: CalculationSummary
    let onReview: () -> Void

    var body: some View {
        Button(action: onReview) {
            PremiumCard(accentColor: .red.opacity(0.78)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        LinenItemIcon(itemName: summary.itemName, size: 38, boxed: true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(summary.itemName)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Text(explanation)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.62))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 8)

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(summary.shortageBundles)")
                                .font(.title3.weight(.heavy).monospacedDigit())
                                .foregroundStyle(.red)
                                .contentTransition(.numericText())
                            Text("bdl short")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.48))
                        }
                    }

                    HStack(spacing: 8) {
                        warningMetric("Ready", summary.deliverableBundles, "bdl", tint: .green)
                        warningMetric("Needed", requiredBundleDisplay, "bdl", tint: .blue)
                        warningMetric("Short", summary.shortageBundles, "bdl", tint: .red)
                    }

                    HStack {
                        Label("Open Recovery Assist", systemImage: "arrow.triangle.2.circlepath")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.78))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Double tap to open Recovery Assist.")
    }

    private var requiredBundleDisplay: Int {
        summary.requiredBundles ?? max(summary.maxAllowedBundles, summary.deliverableBundles + summary.shortageBundles)
    }

    private var explanation: String {
        let pieces = abs(summary.differencePieces)
        if summary.shortageBundles > 0 {
            return "Delivery can cover \(summary.deliverableBundles) full bundles, but the plan is short \(summary.shortageBundles) bundle\(summary.shortageBundles == 1 ? "" : "s") (\(pieces) pcs)."
        }
        return "Received pieces are below the required par total by \(pieces) pcs."
    }

    private func warningMetric(_ label: String, _ value: Int, _ detail: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.headline.weight(.heavy).monospacedDigit())
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.55))
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.42))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct ResultCard: View {
    let summary: CalculationSummary
    let usesParSystem: Bool
    let isPinned: Bool
    let canPin: Bool
    let isExpanded: Bool
    let onToggle: () -> Void
    let onPinToggle: () -> Void
    let onRebalance: () -> Void
    let onViewFloorPlan: () -> Void

    var body: some View {
        PremiumCard(accentColor: accent.opacity(0.7)) {
            VStack(alignment: .leading, spacing: 12) {
                Button(action: onToggle) {
                    VStack(alignment: .leading, spacing: 10) {
                        header
                        compactSummary
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint(isExpanded ? "Double tap to collapse result details." : "Double tap for result details.")

                if isExpanded {
                    Divider().overlay(Color.white.opacity(0.08))
                    expandedDetails
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.snappy(duration: 0.2), value: isExpanded)
    }

    private var header: some View {
        HStack(spacing: 10) {
            LinenItemIcon(itemName: summary.itemName, size: 40, boxed: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(summary.itemName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text("\(summary.fullBundles) full bundles · \(summary.loosePieces) loose pcs")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.62))
            }
            Spacer()
            if isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.cyan)
            }
            if usesParSystem {
                StatusBadge(status: summary.status)
            } else {
                Text("NO PAR")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.teal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.teal.opacity(0.14), in: Capsule())
                    .overlay(Capsule().stroke(Color.teal.opacity(0.20), lineWidth: 1))
            }
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.42))
        }
    }

    private var compactSummary: some View {
        HStack(spacing: 8) {
            compactFact("Deliverable", "\(summary.deliverableBundles)", "bundles", tint: .green)
            compactFact("Loose", "\(summary.loosePieces)", "pcs", tint: summary.loosePieces > 0 ? .orange : .white)
            if usesParSystem {
                compactFact(compactDifferenceLabel, compactDifferenceValue, "bundles", tint: accent)
            } else {
                compactFact("Received", "\(summary.receivedPieces)", "pcs", tint: .teal)
            }
        }
    }

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                MetricTile(
                    label: "Received", value: "\(summary.receivedPieces)", secondary: "pcs",
                    explanation: "\(summary.fullBundles) × \(summary.bundleSize) pcs = \(summary.fullBundles * summary.bundleSize)\(summary.loosePieces > 0 ? " + \(summary.loosePieces) loose" : "")"
                )
                MetricTile(
                    label: "Bundles", value: "\(summary.fullBundles)",
                    secondary: summary.loosePieces > 0 ? "+\(summary.loosePieces) loose" : nil,
                    explanation: "\(summary.receivedPieces) pcs ÷ \(summary.bundleSize) pcs/bundle"
                )
            }
            if usesParSystem {
                HStack(spacing: 10) {
                    MetricTile(
                        label: "Required", value: "\(summary.requiredPieces)", secondary: "pcs par",
                        explanation: "Total par for all active floors"
                    )
                    MetricTile(
                        label: "Difference", value: differenceString, secondary: differenceSecondary, tint: accent,
                        explanation: "\(summary.receivedPieces) received − \(summary.requiredPieces) required = \(summary.differencePieces) pcs"
                    )
                }
                HStack(spacing: 10) {
                    MetricTile(
                        label: "Max Allowed", value: "\(summary.maxAllowedBundles)", secondary: "bundles",
                        explanation: "⌈\(summary.requiredPieces) pcs ÷ \(summary.bundleSize) pcs/bundle⌉"
                    )
                    MetricTile(
                        label: "Can Deliver", value: "\(summary.deliverableBundles)", secondary: "bundles", tint: .green,
                        explanation: "min(\(summary.fullBundles) on hand, \(summary.maxAllowedBundles) max allowed)"
                    )
                }
                HStack(spacing: 10) {
                    MetricTile(
                        label: "Shortage", value: "\(summary.shortageBundles)", secondary: "bundles",
                        tint: summary.shortageBundles > 0 ? .red : .white,
                        explanation: summary.shortageBundles > 0
                            ? "\(summary.maxAllowedBundles) needed − \(summary.deliverableBundles) available"
                            : "No shortage — supply meets or exceeds demand"
                    )
                    MetricTile(
                        label: "Leftover", value: "\(summary.leftoverBundles)", secondary: "bundles",
                        tint: summary.leftoverBundles > 0 ? .orange : .white,
                        explanation: summary.leftoverBundles > 0
                            ? "\(summary.fullBundles) on hand − \(summary.deliverableBundles) delivered"
                            : "No leftover — all bundles are being delivered"
                    )
                }
            } else {
                HStack(spacing: 10) {
                    MetricTile(label: "Rule", value: "No Par", secondary: "timeshare", tint: .teal,
                        explanation: "Timeshare items deliver all received pieces evenly"
                    )
                    MetricTile(label: "Distributed", value: "\(summary.receivedPieces)", secondary: "pcs received", tint: .green,
                        explanation: "All \(summary.receivedPieces) pcs distributed across floors"
                    )
                }
            }
            HStack(spacing: 10) {
                MetricTile(
                    label: "Per Floor", value: String(format: "%.2f", summary.exactPerFloorPieces), secondary: "exact",
                    explanation: "Total deliverable pieces ÷ active floor count"
                )
                MetricTile(
                    label: "Practical",
                    value: "\(summary.basePerFloorPieces)",
                    secondary: summary.remainderPieces > 0 ? "first \(summary.remainderPieces) get +1" : "even",
                    explanation: summary.remainderPieces > 0
                        ? "\(summary.basePerFloorPieces) pcs base + 1 extra to first \(summary.remainderPieces) floors"
                        : "\(summary.basePerFloorPieces) pcs to every floor — divides evenly"
                )
            }

            Text("Bundle size: \(summary.bundleSize) pcs/bundle")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
            Text(summaryLine)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                widgetPinRow
                Divider().overlay(Color.white.opacity(0.08))
                compactActionRow("View floor plan", systemImage: "list.number", action: onViewFloorPlan)
                if usesParSystem {
                    Divider().overlay(Color.white.opacity(0.08))
                    compactActionRow("Rebalance this item", systemImage: "arrow.triangle.2.circlepath", action: onRebalance)
                }
            }
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var widgetPinRow: some View {
        Button(action: onPinToggle) {
            HStack(spacing: 9) {
                Image(systemName: isPinned ? "pin.fill" : "pin")
                    .frame(width: 18)
                    .foregroundStyle(isPinned ? .cyan : .white.opacity(0.82))
                Text(isPinned ? "On Widget" : (canPin ? "Show on Widget" : "Widget full"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isPinned ? .cyan : .white.opacity(canPin ? 0.82 : 0.36))
                Spacer()
                if isPinned {
                    Text("Pinned")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.cyan.opacity(0.14), in: Capsule())
                } else if !canPin {
                    Text("3/3")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.36))
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canPin && !isPinned)
        .accessibilityLabel(isPinned ? "\(summary.itemName) is shown on widget." : (canPin ? "Show \(summary.itemName) on widget." : "Widget item limit reached."))
        .accessibilityHint(isPinned ? "Double tap to remove from widget." : (canPin ? "Double tap to pin to widget." : "Unpin one item to add another."))
    }

    private func compactFact(_ label: String, _ value: String, _ detail: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.heavy).monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint.opacity(tint == .white ? 0.58 : 0.9))
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.42))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(tint == .white ? 0.04 : 0.11), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func compactActionRow(
        _ title: String,
        systemImage: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .frame(width: 18)
                Text(title)
                    .font(.caption.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))
            }
            .foregroundStyle(.white.opacity(isEnabled ? 0.82 : 0.36))
            .padding(.horizontal, 11)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var differenceString: String {
        summary.differencePieces > 0 ? "+\(summary.differencePieces)" : "\(summary.differencePieces)"
    }

    private var differenceSecondary: String {
        switch summary.status {
        case .shortage: return "short \(abs(summary.differencePieces)) pcs"
        case .overage:  return "enough +\(summary.differencePieces) pcs"
        case .exact:    return "exact match"
        }
    }

    private var summaryLine: String {
        let base = summary.basePerFloorPieces
        let rem = summary.remainderPieces
        if rem > 0 {
            return "\(base) per floor. First \(rem) floors get \(base + 1)."
        }
        return "\(base) per floor — distributes evenly."
    }

    private var compactDifferenceLabel: String {
        switch summary.status {
        case .shortage: return "Short"
        case .overage: return "Leftover"
        case .exact: return "Exact"
        }
    }

    private var compactDifferenceValue: String {
        switch summary.status {
        case .shortage: return "\(summary.shortageBundles)"
        case .overage: return "\(summary.leftoverBundles)"
        case .exact: return "0"
        }
    }

    private var accessibilityLabel: String {
        "\(summary.itemName), \(summary.fullBundles) full bundles, \(summary.loosePieces) loose pieces, \(summary.deliverableBundles) deliverable bundles."
    }

    private var accent: Color {
        LinenIconLibrary.color(forItem: summary.itemName)
    }
}
