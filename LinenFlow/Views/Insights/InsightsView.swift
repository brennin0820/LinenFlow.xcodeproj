import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \DailyLog.createdAt, order: .forward) private var logs: [DailyLog]

    @State private var selectedTower: String = "All Towers"

    private let shiftIntelligence = ShiftIntelligenceService()
    
    var uniqueTowers: [String] {
        let towers = Set(logs.map { $0.towerName })
        return ["All Towers"] + Array(towers).sorted()
    }

    var filteredLogs: [DailyLog] {
        if selectedTower == "All Towers" {
            return logs
        } else {
            return logs.filter { $0.towerName == selectedTower }
        }
    }

    private var towerFilter: String? {
        selectedTower == "All Towers" ? nil : selectedTower
    }

    var recommendations: [SupplyRecommendation] {
        shiftIntelligence.recommendations(logs: logs, towerFilter: towerFilter)
    }

    struct DeliveryData: Identifiable {
        let id = UUID()
        let date: Date
        let item: String
        let bundles: Int
    }
    
    struct ShortageData: Identifiable {
        let id = UUID()
        let date: Date
        let item: String
        let shortageAmount: Int
        let unitLabel: String
    }

    var deliveryChartData: [DeliveryData] {
        var data: [DeliveryData] = []
        for log in filteredLogs {
            let summaries = log.summarySnapshot
            for summary in summaries {
                if summary.deliverableBundles > 0 {
                    data.append(DeliveryData(date: log.date, item: summary.itemName, bundles: summary.deliverableBundles))
                }
            }
        }
        return data
    }
    
    var shortageChartData: [ShortageData] {
        var data: [ShortageData] = []
        for log in filteredLogs {
            let summaries = log.summarySnapshot
            for summary in summaries where summary.status == .shortage {
                let usesBundlePar = summary.requiredBundles != nil
                if usesBundlePar, summary.shortageBundles > 0 {
                    data.append(ShortageData(
                        date: log.date,
                        item: summary.itemName,
                        shortageAmount: summary.shortageBundles,
                        unitLabel: "bundles"
                    ))
                } else if summary.differencePieces < 0 {
                    data.append(ShortageData(
                        date: log.date,
                        item: summary.itemName,
                        shortageAmount: abs(summary.differencePieces),
                        unitLabel: "pieces"
                    ))
                }
            }
        }
        return data
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                ScrollView {
                    VStack(spacing: 24) {
                        if logs.isEmpty {
                            ContentUnavailableView(
                                "No Data",
                                systemImage: "chart.bar.xaxis",
                                description: Text("Complete some daily logs to see insights here.")
                            )
                        } else {
                            towerPicker

                            smartRecommendationsSection

                            deliveryChartSection
                            
                            shortageChartSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Insights")
        }
    }
    
    private var towerPicker: some View {
        Picker("Tower", selection: $selectedTower) {
            ForEach(uniqueTowers, id: \.self) { tower in
                Text(tower).tag(tower)
            }
        }
        .pickerStyle(.segmented)
    }

    private var smartRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Recommendations")
                .font(.headline)

            if recommendations.isEmpty {
                PremiumCard {
                    Text("No patterns detected yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                }
            } else {
                ForEach(recommendations) { recommendation in
                    PremiumCard(accentColor: recommendationAccent(for: recommendation.severity)) {
                        SupplyRecommendationCard(recommendation: recommendation)
                    }
                }
            }
        }
    }

    private func recommendationAccent(for severity: RecommendationSeverity) -> Color {
        switch severity {
        case .action: return .orange
        case .caution: return .yellow
        case .info: return .cyan
        }
    }

    private var deliveryChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deliverable Bundles Over Time")
                .font(.headline)
            
            PremiumCard {
                if deliveryChartData.isEmpty {
                    Text("No delivery data available.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    Chart {
                        ForEach(deliveryChartData) { data in
                            BarMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Bundles", data.bundles)
                            )
                            .foregroundStyle(by: .value("Item", data.item))
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel(format: .dateTime.month().day())
                            AxisGridLine()
                        }
                    }
                    .frame(height: 300)
                }
            }
        }
    }
    
    private var shortageChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shortages Over Time")
                .font(.headline)
            
            PremiumCard {
                if shortageChartData.isEmpty {
                    Text("No shortages reported! Great job.")
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    Chart {
                        ForEach(shortageChartData) { data in
                            PointMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Shortage", data.shortageAmount)
                            )
                            .foregroundStyle(by: .value("Item", data.item))
                            .symbol(by: .value("Item", data.item))
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel(format: .dateTime.month().day())
                            AxisGridLine()
                        }
                    }
                    .frame(height: 300)
                }
            }
        }
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
