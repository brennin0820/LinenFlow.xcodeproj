import SwiftUI

struct ReviewReceivedView: View {
    @Environment(FlowViewModel.self) private var viewModel
    @Binding var path: NavigationPath

    var body: some View {
        AppBackground(accentColor: viewModel.selectedTower.flatMap { Color(hex: $0.identityColorHex ?? "") }) {
            ScrollView {
                VStack(spacing: 16) {
                    FlowProgressHeader(current: .review)

                    if let tower = viewModel.selectedTower {
                        summaryCard(tower: tower)
                    }

                    if !viewModel.validationWarnings.isEmpty {
                        WarningCard(warnings: viewModel.validationWarnings)
                    }

                    SectionHeader(title: "Entries", subtitle: "Confirm before calculating results.")

                    if viewModel.receivingEntries.isEmpty {
                        EmptyStateView(
                            systemImage: "tray",
                            title: "Nothing received yet",
                            message: "Go back and enter at least one item to review."
                        )
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.receivingEntries) { entry in
                                EntryReviewCard(entry: entry)
                            }
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
        .safeAreaInset(edge: .bottom) {
            StickyBottomActionBar {
                HStack(spacing: 12) {
                    SecondaryActionButton(title: "Edit", systemImage: "pencil") {
                        path.removeLast()
                    }
                    PrimaryActionButton(
                        title: "Calculate Results",
                        systemImage: "function",
                        isEnabled: !viewModel.receivingEntries.isEmpty
                    ) {
                        viewModel.recalculate()
                        path.append(FlowStep.results)
                    }
                }
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func summaryCard(tower: Tower) -> some View {
        PremiumCard(accentColor: Color(hex: tower.identityColorHex ?? "")) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tower.name).font(.headline).foregroundStyle(.white)
                    Text("\(tower.floorCount) floors")
                        .font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                let totals = totals
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(totals.items) item types")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("\(totals.pieces) pcs · \(totals.bundles) bundles")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    private var totals: (items: Int, pieces: Int, bundles: Int) {
        let items = Set(viewModel.receivingEntries.map(\.itemName)).count
        let pieces = viewModel.receivingEntries.reduce(0) { $0 + $1.calculatedPieces }
        let bundles = viewModel.receivingEntries.reduce(0) { $0 + $1.calculatedFullBundles }
        return (items, pieces, bundles)
    }
}

private struct EntryReviewCard: View {
    let entry: ReceivingEntry

    var body: some View {
        PremiumCard(accentColor: LinenIconLibrary.color(forItem: entry.itemName)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    LinenItemIcon(itemName: entry.itemName, size: 40, boxed: true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.itemName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(entry.countMethod.displayName)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08), in: Capsule())
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                }

                HStack(spacing: 10) {
                    if entry.countMethod == .fixedBin {
                        miniMetric(label: "Bins", value: "\(entry.binCount ?? 0)")
                        miniMetric(label: "Per bin", value: "\(entry.piecesPerBin ?? 0)")
                    } else if let m = entry.manualPieces {
                        miniMetric(label: "Manual", value: "\(m)")
                    }
                    miniMetric(label: "Pieces", value: "\(entry.calculatedPieces)", emphasis: true)
                    miniMetric(label: "Bundles", value: "\(entry.calculatedFullBundles)")
                    miniMetric(label: "Loose", value: "\(entry.loosePieces)")
                }

                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    private func miniMetric(label: String, value: String, emphasis: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(emphasis ? .white : .white.opacity(0.85))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            emphasis ? Color.blue.opacity(0.18) : Color.white.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }
}
