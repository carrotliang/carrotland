import ActivityKit
import Foundation
import Observation

@MainActor
protocol IslandActivityStateObserver: AnyObject {
    func synchronizeActivityState()
}

/// Serializes all activity mutations, including across different managers.
@MainActor
@Observable
final class IslandActivityCoordinator {
    static let shared = IslandActivityCoordinator()

    enum Kind {
        case clock, timer
    }

    private(set) var isBusy = false
    @ObservationIgnored private var waiters: [CheckedContinuation<Void, Never>] = []
    @ObservationIgnored private var observers: [WeakObserver] = []

    private struct WeakObserver {
        weak var value: (any IslandActivityStateObserver)?
    }

    private struct Session {
        let kind: Kind
        let id: String
        let startedAt: Date
        let isActive: Bool
    }

    func register(_ observer: any IslandActivityStateObserver) {
        observers.removeAll { $0.value == nil }
        observers.append(WeakObserver(value: observer))
    }

    /// Restore both cards in one transaction; perform publishes their final state.
    func restore() async {
        await perform {
            await retainLatest()
            await Self.refreshClock()
        }
    }

    func perform<T>(_ operation: () async -> T) async -> T {
        if isBusy {
            await withCheckedContinuation { waiters.append($0) }
        } else {
            isBusy = true
        }
        defer {
            // Publish both cards before returning, without waiting for ActivityKit streams.
            observers.removeAll { $0.value == nil }
            for observer in observers { observer.value?.synchronizeActivityState() }
            if waiters.isEmpty {
                isBusy = false
            } else {
                waiters.removeFirst().resume()
            }
        }
        return await operation()
    }

    /// With a kind, retain that type's newest session and end every other session.
    /// Without one, restore only the newest active session from any type.
    func retainLatest(of kind: Kind? = nil) async {
        let all = sessions
        let survivor = all.filter { $0.isActive && (kind == nil || $0.kind == kind) }
            .max {
                $0.startedAt == $1.startedAt ? $0.id < $1.id : $0.startedAt < $1.startedAt
            }
        for session in all where session.id != survivor?.id {
            await Self.endActivity(id: session.id, kind: session.kind)
        }
    }

    func endAll(of kind: Kind) async {
        for session in sessions where session.kind == kind {
            await Self.endActivity(id: session.id, kind: kind)
        }
    }

    // Add future activity types here and in endActivity, so restoration also
    // covers sessions created before any card's manager has been initialized.
    private var sessions: [Session] {
        Activity<ClockAttributes>.activities.map {
            Session(kind: .clock, id: $0.id, startedAt: $0.attributes.startedAt,
                    isActive: $0.activityState.isRunning)
        } + Activity<TimerAttributes>.activities.map {
            Session(kind: .timer, id: $0.id, startedAt: $0.attributes.startedAt,
                    isActive: $0.activityState.isRunning)
        }
    }

    // Resolve the Activity here instead of passing a non-Sendable reference
    // from main-actor state across ActivityKit's nonisolated async boundary.
    private nonisolated static func refreshClock() async {
        guard let activity = Activity<ClockAttributes>.activities.first(where: { $0.activityState.isRunning }) else { return }
        await activity.update(ActivityContent(state: .init(refreshedAt: .now), staleDate: nil))
    }

    // Resolve IDs inside the nonisolated function; Activity isn't Sendable.
    private nonisolated static func endActivity(id: String, kind: Kind) async {
        switch kind {
        case .clock:
            if let activity = Activity<ClockAttributes>.activities.first(where: { $0.id == id }) {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        case .timer:
            if let activity = Activity<TimerAttributes>.activities.first(where: { $0.id == id }) {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}

extension ActivityState {
    var isRunning: Bool {
        self == .active || self == .stale
    }
}
