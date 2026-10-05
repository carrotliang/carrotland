import SwiftUI

struct LiveElapsedTimeText: View {
    let startedAt: Date?
    var part: ElapsedTimeFormat.Part = .hourMinuteSecond

    var body: some View {
        Group {
            if let startedAt {
                Text(TimeDataSource<Duration>.durationOffset(to: startedAt), format: ElapsedTimeFormat.style(for: part))
            } else {
                Text(ElapsedTimeFormat.style(for: part).format(.zero))
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
}

struct TimerIslandSymbol: View {
    var body: some View {
        Image(systemName: "stopwatch")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.orange)
            .frame(width: 24)
            .accessibilityLabel("计时器")
    }
}

struct CompactTimerFace: View {
    let startedAt: Date?

    var body: some View {
        LiveElapsedTimeText(startedAt: startedAt)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .frame(width: 76, alignment: .trailing)
            .multilineTextAlignment(.trailing)
    }
}

struct MinimalTimerFace: View {
    let startedAt: Date?

    var body: some View {
        LiveElapsedTimeText(startedAt: startedAt, part: .hourMinute)
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .frame(width: 28)
            .multilineTextAlignment(.center)
    }
}
