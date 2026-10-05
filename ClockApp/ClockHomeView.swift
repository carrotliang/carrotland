import SwiftUI
import UIKit

struct ClockHomeView: View {
    let manager: ClockActivityManager
    let timerManager: TimerActivityManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var currentTimeZone = TimeZone.autoupdatingCurrent

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ClockIslandCard(manager: manager)
                    TimerIslandCard(manager: timerManager)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
        }
        .environment(\.timeZone, currentTimeZone)
        .task { await IslandActivityCoordinator.shared.restore() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            refresh()
        }
    }

    private func refresh() {
        currentTimeZone = .current
        Task { await IslandActivityCoordinator.shared.restore() }
    }
}
