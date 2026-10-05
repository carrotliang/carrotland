import Foundation

enum ElapsedTimeFormat {
    enum Part {
        case hourMinuteSecond
        case hourMinute
    }

    /// System-defined styles can be decoded by the separate Live Activity renderer.
    /// Round down so seconds and minutes only advance after a full unit has elapsed.
    static func style(for part: Part) -> Duration.TimeFormatStyle {
        let pattern: Duration.TimeFormatStyle.Pattern
        switch part {
        case .hourMinuteSecond:
            pattern = .hourMinuteSecond(padHourToLength: 2, roundFractionalSeconds: .down)
        case .hourMinute:
            pattern = .hourMinute(padHourToLength: 2, roundSeconds: .down)
        }
        return Duration.TimeFormatStyle(pattern: pattern, locale: Locale(identifier: "en_US_POSIX"))
    }
}
