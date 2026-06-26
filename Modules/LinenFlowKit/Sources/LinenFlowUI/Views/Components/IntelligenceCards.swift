import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct SmartFillCard: View {
    public let summary: String
    public let itemCount: Int
    public let confidence: PredictionConfidence?
    public let onApply: () -> Void

    public var body: some View {
        PremiumCard(accentColor: .indigo) {
            PremiumCardActionRow {
                HStack(spacing: 10) {
                    Image(systemName: "brain.head.profile.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.indigo.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Smart Fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                            .fixedSize(horizontal: false, vertical: true)
                        if let confidence {
                            Text(confidence.displayLabel)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.indigo.opacity(0.95))
                        }
                    }
                }
            } trailing: {
                Button(action: onApply) {
                    Label("Apply Smart Fill", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Color.indigo.opacity(0.82), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Apply smart fill for \(itemCount) items")
            }
        }
    }
}

public struct IntelligenceInsightCard: View {
    public let anomalies: [SupplyAnomaly]

    public var body: some View {
        PremiumCard(accentColor: .purple) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.purple)
                    Text("Unusual vs. history")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(anomalies.count)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(.purple.opacity(0.9))
                }

                ForEach(anomalies.prefix(3)) { anomaly in
                    Text(anomaly.message)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if anomalies.count > 3 {
                    Text("+\(anomalies.count - 3) more flagged items")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.48))
                }
            }
        }
    }
}

public struct SupplyRecommendationCard: View {
    public let recommendation: SupplyRecommendation

    private var tint: Color {
        switch recommendation.severity {
        case .action: return .orange
        case .caution: return .yellow
        case .info: return .cyan
        }
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: recommendation.severity.systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(recommendation.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(recommendation.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
                if recommendation.towerName != nil || recommendation.itemName != nil {
                    HStack(spacing: 6) {
                        if let tower = recommendation.towerName {
                            Text(tower)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(tint.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(tint.opacity(0.12), in: Capsule())
                        }
                        if let item = recommendation.itemName {
                            Text(item)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.72))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.08), in: Capsule())
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
