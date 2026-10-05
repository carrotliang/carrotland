import Foundation
import XCTest
@testable import IslandClock

final class ClockFormatTests: XCTestCase {
    private let utc = TimeZone(secondsFromGMT: 0)!

    func testMidnightAndZeroPadding() {
        assertTime("2026-10-02T00:00:00.000Z", left: "00:00", right: "00.000", full: "00:00:00.000")
        assertTime("2026-10-02T01:02:03.004Z", left: "01:02", right: "03.004", full: "01:02:03.004")
    }

    func testEndOfDayAndTwentyFourHourClock() {
        assertTime("2026-10-02T23:59:59.999Z", left: "23:59", right: "59.999", full: "23:59:59.999")
        assertTime("2026-10-02T14:30:25.123Z", left: "14:30", right: "25.123", full: "14:30:25.123")
    }

    func testMinuteHourAndDayRollover() {
        for (before, after, expected) in [
            ("2026-10-02T14:30:59.999Z", "2026-10-02T14:31:00.000Z", "14:31:00.000"),
            ("2026-10-02T14:59:59.999Z", "2026-10-02T15:00:00.000Z", "15:00:00.000"),
            ("2026-10-02T23:59:59.999Z", "2026-10-03T00:00:00.000Z", "00:00:00.000")
        ] {
            let style = ClockFormat.style(for: .full, timeZone: utc)
            XCTAssertNotEqual(style.format(date(before)), style.format(date(after)))
            XCTAssertEqual(style.format(date(after)), expected)
        }
    }

    func testTimeZoneChangesAndDaylightSaving() {
        let instant = date("2026-10-02T16:30:25.123Z")
        XCTAssertEqual(ClockFormat.style(for: .full, timeZone: TimeZone(identifier: "Asia/Shanghai")!).format(instant), "00:30:25.123")
        let newYork = TimeZone(identifier: "America/New_York")!
        let style = ClockFormat.style(for: .full, timeZone: newYork)
        XCTAssertEqual(style.format(date("2026-03-08T06:59:59.999Z")), "01:59:59.999")
        XCTAssertEqual(style.format(date("2026-03-08T07:00:00.000Z")), "03:00:00.000")
    }

    func testFractionalDigitsRepresentCurrentSecond() {
        XCTAssertEqual(compactSeconds(date("2026-10-02T14:30:25.001Z")), "25.001")
        XCTAssertEqual(compactSeconds(date("2026-10-02T14:30:25.999Z")), "25.999")
    }

    func testMinimalSecondsAndMilliseconds() {
        for (iso, seconds, milliseconds) in [
            ("2026-10-02T00:00:00.000Z", "00", "000"),
            ("2026-10-02T14:30:09.007Z", "09", "007"),
            ("2026-10-02T14:30:25.123Z", "25", "123"),
            ("2026-10-02T23:59:59.999Z", "59", "999"),
            ("2026-10-03T00:00:00.001Z", "00", "001")
        ] {
            let instant = date(iso)
            XCTAssertEqual(ClockFormat.style(for: .second, timeZone: utc).format(instant), seconds)
            XCTAssertEqual(ClockFormat.style(for: .millisecond, timeZone: utc).format(instant), milliseconds)
        }
    }

    private func assertTime(_ iso: String, left: String, right: String, full: String, file: StaticString = #filePath, line: UInt = #line) {
        let value = date(iso)
        XCTAssertEqual(ClockFormat.style(for: .hourMinute, timeZone: utc).format(value), left, file: file, line: line)
        XCTAssertEqual(compactSeconds(value), right, file: file, line: line)
        XCTAssertEqual(ClockFormat.style(for: .full, timeZone: utc).format(value), full, file: file, line: line)
    }

    private func compactSeconds(_ date: Date) -> String {
        // Match CompactSecondFace's separate second and millisecond fields.
        ClockFormat.style(for: .second, timeZone: utc).format(date)
            + "." + ClockFormat.style(for: .millisecond, timeZone: utc).format(date)
    }

    private func date(_ iso: String) -> Date {
        try! Date(iso, strategy: .iso8601.year().month().day().time(includingFractionalSeconds: true).timeZone(separator: .omitted))
    }
}
