import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct SmartTipSheet: View {
    public let tip: SmartTip
    public let onDismiss: () -> Void
    public let onDismissPermanently: () -> Void
    public let onTurnOff: () -> Void

    public var body: some View {
        AppBackground(accentColor: tint) {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: tip.systemImage ?? "lightbulb.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(tint)
                            .frame(width: 46, height: 46)
                            .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(categoryLabel)
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(tint)
                                .textCase(.uppercase)
                            Text(tip.title)
                                .font(.title3.weight(.heavy))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                    }

                    Text(tip.message)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.76))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(tint.opacity(0.22), lineWidth: 1)
                )

                VStack(spacing: 10) {
                    Button(action: onDismiss) {
                        Label("Got it", systemImage: "checkmark.circle.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(tint.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: onDismissPermanently) {
                        Text("Don't show this again")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.82))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: onTurnOff) {
                        Text("Turn off Smart Tips")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 18)
        }
    }

    private var tint: Color {
        switch tip.priority {
        case .low: return .blue
        case .normal: return .cyan
        case .important: return .mint
        case .warning: return .orange
        }
    }

    private var categoryLabel: String {
        switch tip.category {
        case .tower: return "Tower"
        case .receiving: return "Receiving"
        case .review: return "Review"
        case .bundles: return "Bundles"
        case .results: return "Results"
        case .floorPlan: return "Floor Plan"
        case .liveDelivery: return "Live Delivery"
        case .logs: return "Logs"
        case .settings: return "Settings"
        case .widget: return "Widget"
        case .validation: return "Check"
        }
    }
}

private struct SmartTipSheetPresenter: ViewModifier {
    @Environment(FlowViewModel.self) private var viewModel

    public func body(content: Content) -> some View {
        content.sheet(item: activeTipBinding) { tip in
            SmartTipSheet(
                tip: tip,
                onDismiss: {
                    viewModel.dismissSmartTip(markDismissed: false)
                },
                onDismissPermanently: {
                    viewModel.dismissSmartTip(markDismissed: true)
                },
                onTurnOff: {
                    viewModel.turnOffSmartTips()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var activeTipBinding: Binding<SmartTip?> {
        Binding(
            get: { viewModel.activeSmartTip },
            set: { newValue in
                if newValue == nil {
                    viewModel.dismissSmartTip(markDismissed: false)
                }
            }
        )
    }
}

public extension View {
    public func smartTipSheet() -> some View {
        modifier(SmartTipSheetPresenter())
    }
}
