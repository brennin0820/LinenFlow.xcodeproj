import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct WeeklySupplyDay: Identifiable {
    public let id = UUID()
    public let date: Date
    public let pieces: Int
    public let bundles: Int
    public let logCount: Int
}

public struct WeeklySupplyGraph: View {
    public let days: [WeeklySupplyDay]

    private var maxBundles: Int {
        max(days.map(\.bundles).max() ?? 0, 1)
    }

    private var totals: (pieces: Int, bundles: Int, logs: Int) {
        (
            days.reduce(0) { $0 + $1.pieces },
            days.reduce(0) { $0 + $1.bundles },
            days.reduce(0) { $0 + $1.logCount }
        )
    }

    public var body: some View {
        PremiumCard(accentColor: .blue) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(totals.bundles) bdl")
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundStyle(.white)
                        Text("\(totals.pieces) pcs · \(totals.logs) logs")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                    }
                    Spacer()
                    Image(systemName: "shippingbox.fill")
                        .foregroundStyle(.blue)
                }

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                        let color = barColor(for: index)
                        VStack(spacing: 6) {
                            Text("\(day.bundles)")
                                .font(.caption2.weight(.bold).monospacedDigit())
                                .foregroundStyle(day.bundles > 0 ? .white : .white.opacity(0.36))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            GeometryReader { proxy in
                                VStack {
                                    Spacer(minLength: 0)
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(day.bundles > 0 ? color.opacity(0.88) : Color.white.opacity(0.08))
                                        .frame(height: max(6, proxy.size.height * barRatio(for: day)))
                                }
                            }
                            .frame(height: 118)

                            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                HStack(spacing: 8) {
                    graphLegend("Bundles", color: .cyan)
                    graphLegend("No log", color: .white.opacity(0.18))
                    Spacer()
                }
            }
        }
    }

    private func barRatio(for day: WeeklySupplyDay) -> CGFloat {
        CGFloat(day.bundles) / CGFloat(maxBundles)
    }

    private func barColor(for index: Int) -> Color {
        let palette: [Color] = [.cyan, .mint, .green, .yellow, .orange, .pink, .purple]
        return palette[index % palette.count]
    }

    private func graphLegend(_ label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
        }
    }
}
