import ActivityKit
import Foundation
import Observation

@MainActor
@Observable
final class TimerActivityManager: IslandActivityControlling, IslandActivityStateObserver {
    private(set) var isRunning = false
    var isBusy: Bool { IslandActivityCoordinator.shared.isBusy }
    private(set) var activitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
    private(set) var startedAt: Date?
    private(set) var errorMessage: String?

    @ObservationIgnored private var activityID: String?
    @ObservationIgnored private var stateTask: Task<Void, Never>?
    @ObservationIgnored private var authorizationTask: Task<Void, Never>?

    init() {
        IslandActivityCoordinator.shared.register(self)
        authorizationTask = Task { [weak self] in
            for await enabled in ActivityAuthorizationInfo().activityEnablementUpdates {
                guard !Task.isCancelled else { return }
                self?.activitiesEnabled = enabled
            }
        }
    }

    deinit {
        stateTask?.cancel()
        authorizationTask?.cancel()
    }

    func synchronizeActivityState() {
        activitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        let survivor = Activity<TimerAttributes>.activities
            .filter { $0.activityState.isRunning }
            .max { $0.attributes.startedAt < $1.attributes.startedAt }
        if let survivor {
            attach(survivor)
        } else {
            clearActivity()
        }
    }

    @discardableResult
    func start() async -> Bool {
        let coordinator = IslandActivityCoordinator.shared
        return await coordinator.perform {
            errorMessage = nil
            activitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
            guard activitiesEnabled else {
                errorMessage = "实时活动未开启。请在系统设置中允许“灵动萝卜”使用实时活动，然后重试。"
                return false
            }
            // Finish the previous type before requesting a new activity.
            await coordinator.retainLatest(of: .timer)
            synchronizeActivityState()
            if isRunning { return true }
            do {
                let now = Date.now
                let requested = try Activity.request(
                    attributes: TimerAttributes(startedAt: now),
                    content: ActivityContent(state: .init(), staleDate: nil),
                    pushType: nil
                )
                attach(requested)
                return isRunning
            } catch {
                errorMessage = "无法启动计时器：\(error.localizedDescription)"
                return false
            }
        }
    }

    @discardableResult
    func stop() async -> Bool {
        let coordinator = IslandActivityCoordinator.shared
        return await coordinator.perform {
            errorMessage = nil
            await coordinator.endAll(of: .timer)
            await coordinator.retainLatest()
            return true
        }
    }

    private func attach(_ activity: Activity<TimerAttributes>) {
        isRunning = activity.activityState.isRunning
        startedAt = activity.attributes.startedAt
        errorMessage = nil
        guard activityID != activity.id else { return }
        stateTask?.cancel()
        activityID = activity.id
        stateTask = Task { [weak self] in
            for await state in activity.activityStateUpdates {
                guard !Task.isCancelled, self?.activityID == activity.id else { return }
                if !state.isRunning {
                    self?.clearActivity()
                    return
                }
            }
        }
    }

    private func clearActivity() {
        stateTask?.cancel()
        stateTask = nil
        activityID = nil
        startedAt = nil
        isRunning = false
    }
}
