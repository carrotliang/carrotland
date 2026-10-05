import Foundation
import XCTest
@testable import IslandClock

final class ElapsedTimeFormatTests: XCTestCase {
    func testZeroAndHourPadding() {
        assertElapsed(.zero, full: "00:00:00", minimal: "00:00")
        assertElapsed(.seconds(3_723), full: "01:02:03", minimal: "01:02")
    }

    func testSecondsAndMinutesNeverRoundUpEarly() {
        assertElapsed(.milliseconds(999), full: "00:00:00", minimal: "00:00")
        assertElapsed(.seconds(1), full: "00:00:01", minimal: "00:00")
        assertElapsed(.milliseconds(59_999), full: "00:00:59", minimal: "00:00")
        assertElapsed(.seconds(60), full: "00:01:00", minimal: "00:01")
        assertElapsed(.milliseconds(3_599_999), full: "00:59:59", minimal: "00:59")
        assertElapsed(.seconds(3_600), full: "01:00:00", minimal: "01:00")
    }

    func testElapsedHoursDoNotWrapAtMidnight() {
        assertElapsed(.seconds(8 * 3_600), full: "08:00:00", minimal: "08:00")
        assertElapsed(.seconds(24 * 3_600 + 61), full: "24:01:01", minimal: "24:01")
    }

    private func assertElapsed(_ duration: Duration, full: String, minimal: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(ElapsedTimeFormat.style(for: .hourMinuteSecond).format(duration), full, file: file, line: line)
        XCTAssertEqual(ElapsedTimeFormat.style(for: .hourMinute).format(duration), minimal, file: file, line: line)
    }
}
