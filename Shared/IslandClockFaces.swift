import SwiftUI

/// Shared by the Live Activity and the in-app presentation previews.
struct CompactHourMinuteFace: View {
    var body: some View {
        LiveClockText(part: .hourMinute)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .frame(width: 49, alignment: .leading)
    }
}

struct CompactSecondFace: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            LiveClockText(part: .second)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .multilineTextAlignment(.trailing)
                .frame(width: 20)
            Text(".")
                .font(.system(size: 12, weight: .medium, design: .rounded))
            LiveClockText(part: .millisecond)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .frame(width: 25)
        }
        .frame(width: 58, alignment: .trailing)
    }
}

struct MinimalClockFace: View {
    var body: some View {
        VStack(spacing: 0) {
            LiveClockText(part: .second)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
            LiveClockText(part: .millisecond)
                .font(.system(size: 8, weight: .medium, design: .rounded))
        }
        .frame(width: 24)
        .multilineTextAlignment(.center)
    }
}
