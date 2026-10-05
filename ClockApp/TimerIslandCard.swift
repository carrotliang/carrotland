import SwiftUI

struct TimerIslandCard: View {
    let manager: TimerActivityManager

    var body: some View {
        IslandTypeCard(isRunning: manager.isRunning) {
            IslandActivityControls(title: "计时器", manager: manager, accessibilityIdentifier: "toggleTimerActivity") {
                IslandPresentationPreviews(
                    compactIdentifier: "compactTimerPreview",
                    minimalIdentifier: "minimalTimerPreview"
                ) {
                    HStack(spacing: 0) {
                        TimerIslandSymbol()
                        Color.clear
                            .frame(width: 72, height: 1)
                            .accessibilityHidden(true)
                        CompactTimerFace(startedAt: manager.startedAt)
                    }
                } minimal: {
                    MinimalTimerFace(startedAt: manager.startedAt)
                }
            }
        }
    }
}
