import SwiftUI

struct FlowProgressHeader: View {
    enum Step: Int, CaseIterable, Identifiable {
        case receive, review, results, floorPlan
        var id: Int { rawValue }
        var label: String {
            switch self {
            case .receive:   return "Receive"
            case .review:    return "Review"
            case .results:   return "Results"
            case .floorPlan: return "Floor Plan"
            }
        }
    }

    let current: Step

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Step.allCases) { step in
                let isCurrent = step == current
                let isComplete = step.rawValue < current.rawValue
                VStack(spacing: 4) {
                    Circle()
                        .fill(isCurrent ? Color.blue : (isComplete ? Color.green : Color.white.opacity(0.18)))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(isCurrent ? 0.36 : 0.10), lineWidth: 1)
                        )
                    Text(step.label)
                        .font(.caption2.weight(isCurrent ? .bold : .regular))
                        .foregroundStyle(isCurrent ? .white : .white.opacity(0.5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                if step != Step.allCases.last {
                    Capsule()
                        .fill(isComplete ? Color.green.opacity(0.55) : Color.white.opacity(0.1))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .offset(y: -6)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
