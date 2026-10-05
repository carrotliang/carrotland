import Foundation

enum ClockFormat {
    enum Part {
        case hourMinute
        case second
        case millisecond
        case full
    }

    /// Keep system-defined format styles: Live Activities render in a separate
    /// process, where app-defined DiscreteFormatStyle types may not decode.
    static func style(
        for part: Part,
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> Date.FormatStyle {
        let base = Date.FormatStyle(
            locale: Locale(identifier: "en_GB-u-hc-h23"),
            calendar: Calendar(identifier: .gregorian),
            timeZone: timeZone
        )
        switch part {
        case .hourMinute:
            return base.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
        case .second:
            return base.second(.twoDigits)
        case .millisecond:
            return base.secondFraction(.fractional(3))
        case .full:
            return base.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
                .second(.twoDigits).secondFraction(.fractional(3))
        }
    }
}
