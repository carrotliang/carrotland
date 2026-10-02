import ActivityKit
import Foundation

struct ClockAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        // A foreground refresh also asks the system to rebuild date formatting
        // after a time-zone or locale change. Time itself isn't pushed here.
        var refreshedAt: Date
    }

    let sessionID: UUID
    let startedAt: Date
}
