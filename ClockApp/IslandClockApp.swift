import SwiftUI

@main
struct IslandClockApp: App {
    @State private var manager = ClockActivityManager()
    @State private var timerManager = TimerActivityManager()

    var body: some Scene {
        WindowGroup {
            ClockHomeView(manager: manager, timerManager: timerManager)
        }
    }
}
