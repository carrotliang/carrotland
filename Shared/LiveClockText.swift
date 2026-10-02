import SwiftUI

struct LiveClockText: View {
    var part: ClockFormat.Part = .full
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        Text(TimeDataSource<Date>.currentDate, format: ClockFormat.style(for: part, timeZone: timeZone))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }
}
