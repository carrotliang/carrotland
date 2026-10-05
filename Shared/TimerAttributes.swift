import ActivityKit
import Foundation

struct TimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {}

    /// The immutable origin survives app relaunches via ActivityKit.
    let startedAt: Date
}
