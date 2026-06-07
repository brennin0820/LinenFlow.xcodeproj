import SwiftUI

struct ScheduleTranscriptCard: View {
    @Bindable var viewModel: SmartShiftAlarmPlannerViewModel
    @State private var isExpanded = false

    var body: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Button {
                    withAnimation(.snappy(duration: 0.24)) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "note.text")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Schedule Notes / Transcript")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Reference only — edit days manually below")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.50))
                        }
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider().background(Color.white.opacity(0.08)).padding(.vertical, 12)

                    Text("Paste schedule text here as a reference. Edit days below manually.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 8)

                    TextEditor(text: $viewModel.scheduleTranscriptNotes)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color.white.opacity(0.045))
                        .frame(minHeight: 120, maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .onChange(of: viewModel.scheduleTranscriptNotes) { _, _ in
                            viewModel.save()
                        }
                }
            }
        }
    }
}
