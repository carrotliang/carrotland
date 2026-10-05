import ActivityKit
import SwiftUI
import WidgetKit

struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                Text("计时器")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                FullActivityTimer(startedAt: context.attributes.startedAt, fontSize: 34)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .activityBackgroundTint(.black)
            .activitySystemActionForegroundColor(.white)
            .foregroundStyle(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 6) {
                        Text("计时器")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        FullActivityTimer(startedAt: context.attributes.startedAt, fontSize: 30)
                    }
                    .padding(.vertical, 8)
                }
            } compactLeading: {
                TimerIslandSymbol()
            } compactTrailing: {
                CompactTimerFace(startedAt: context.attributes.startedAt)
            } minimal: {
                MinimalTimerFace(startedAt: context.attributes.startedAt)
            }
            .keylineTint(.orange)
        }
    }
}

private struct FullActivityTimer: View {
    let startedAt: Date
    let fontSize: CGFloat
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        if isLuminanceReduced {
            Text("唤醒屏幕查看计时")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(minHeight: fontSize + 6, alignment: .leading)
        } else {
            LiveElapsedTimeText(startedAt: startedAt)
                .font(.system(size: fontSize, weight: .medium, design: .rounded))
        }
    }
}
