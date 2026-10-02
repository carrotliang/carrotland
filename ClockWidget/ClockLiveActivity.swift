import ActivityKit
import SwiftUI
import WidgetKit

@main
struct ClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClockLiveActivity()
    }
}

struct ClockLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClockAttributes.self) { _ in
            VStack(alignment: .leading, spacing: 8) {
                Text("当前时间")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                FullActivityClock(fontSize: 34)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .activityBackgroundTint(.black)
            .activitySystemActionForegroundColor(.white)
            .foregroundStyle(.white)
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 6) {
                        Text("当前时间")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        FullActivityClock(fontSize: 30)
                    }
                    .padding(.vertical, 8)
                }
            } compactLeading: {
                CompactHourMinuteFace()
            } compactTrailing: {
                CompactSecondFace()
            } minimal: {
                MinimalClockFace()
            }
            .keylineTint(.cyan)
        }
    }
}

private struct FullActivityClock: View {
    let fontSize: CGFloat
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        if isLuminanceReduced {
            // The system may round Date.FormatStyle aggressively in Always-On.
            // Avoid presenting that approximation as the actual current time.
            Text("唤醒屏幕查看时间")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(minHeight: fontSize + 6, alignment: .leading)
        } else {
            LiveClockText()
                .font(.system(size: fontSize, weight: .medium, design: .rounded))
        }
    }
}
