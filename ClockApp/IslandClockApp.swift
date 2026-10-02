import SwiftUI

@main
struct IslandClockApp: App {
    @State private var manager = ClockActivityManager()

    var body: some Scene {
        WindowGroup {
            ClockHomeView(manager: manager)
        }
    }
}
