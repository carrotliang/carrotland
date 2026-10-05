import SwiftUI

struct ClockIslandCard: View {
    let manager: ClockActivityManager

    var body: some View {
        IslandTypeCard(isRunning: manager.isRunning) {
            IslandActivityControls(title: "自然时间", manager: manager, accessibilityIdentifier: "toggleActivity") {
                IslandPresentationPreviews(
                    compactIdentifier: "compactIslandPreview",
                    minimalIdentifier: "minimalIslandPreview"
                ) {
                    HStack(spacing: 0) {
                        CompactHourMinuteFace()
                        Color.clear
                            .frame(width: 72, height: 1)
                            .accessibilityHidden(true)
                        CompactSecondFace()
                    }
                } minimal: {
                    MinimalClockFace()
                }
            }
        }
    }
}
