import SwiftUI

struct LocationPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var locationService = LocationService()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(HimmerFlowColors.accent)

                    Text("Automatic leave & arrival")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(HimmerFlowColors.heroText)

                    Text("HimmerFlow can detect when you leave home and arrive at work, so reminders stay accurate even when you're distracted.")
                        .font(.body)
                        .foregroundStyle(HimmerFlowColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    permissionBullet("Works in the background when Always is granted")
                    permissionBullet("Falls back to time-based reminders if location is limited")
                    permissionBullet("Never blocks your shift plan if you skip this")
                }

                Spacer()

                Button {
                    locationService.requestWhenInUseAuthorization()
                } label: {
                    Text("Enable Location")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .foregroundStyle(.white)
                        .background(HimmerFlowColors.ctaFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    locationService.requestAlwaysAuthorization()
                } label: {
                    Text("Enable Background Detection")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .foregroundStyle(HimmerFlowColors.accent)
                }
                .buttonStyle(.plain)

                Button("Not now") {
                    dismiss()
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(HimmerFlowColors.mutedText)
                .frame(maxWidth: .infinity)
            }
            .padding(24)
            .background(HimmerFlowColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func permissionBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(HimmerFlowColors.accent)
            Text(text)
                .font(.footnote)
                .foregroundStyle(HimmerFlowColors.secondaryText)
        }
    }
}
