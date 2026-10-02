import ActivityKit
import Foundation
import Observation

@MainActor
@Observable
final class ClockActivityManager {
    private(set) var isRunning = false
    private(set) var isBusy = false
    private(set) var activitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
    private(set) var startedAt: Date?
    private(set) var statusMessage = "点击运行，在灵动岛查看当前时间"
    private(set) var errorMessage: String?

    @ObservationIgnored private var activity: Activity<ClockAttributes>?
    @ObservationIgnored private var stateTask: Task<Void, Never>?
    @ObservationIgnored private var authorizationTask: Task<Void, Never>?

    init() {
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

    /// ActivityKit is the source of truth, including after the app is terminated.
    /// Reconcile under the same gate as start/stop so reentrancy can't duplicate a session.
    func restore() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        activitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        let all = Activity<ClockAttributes>.activities
            .sorted { $0.attributes.startedAt > $1.attributes.startedAt }
        let survivor = all.first { Self.isActive($0.activityState) }

        for candidate in all where candidate.id != survivor?.id {
            await Self.endActivity(id: candidate.id)
        }
        // It may have been dismissed while awaiting cleanup.
        if let survivor, Self.isActive(survivor.activityState) {
            attach(survivor)
            await Self.refreshActivity(id: survivor.id)
        } else {
            clearActivity(message: isRunning ? "显示已结束，可再次运行" : statusMessage)
        }
    }

    @discardableResult
    func start() async -> Bool {
        guard !isBusy else { return false }
        // Recover an existing session before considering a new request.
        await restore()
        guard !isBusy else { return false }
        if isRunning { return true }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        activitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        guard activitiesEnabled else {
            errorMessage = "实时活动未开启。请在系统设置中允许“灵动时钟”使用实时活动，然后重试。"
            return false
        }

        do {
            let now = Date.now
            let requested = try Activity.request(
                attributes: ClockAttributes(sessionID: UUID(), startedAt: now),
                content: ActivityContent(state: .init(refreshedAt: now), staleDate: nil),
                pushType: nil
            )
            attach(requested)
            return isRunning
        } catch {
            errorMessage = "无法启动实时活动：\(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func stop() async -> Bool {
        guard !isBusy else { return false }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        // End all sessions belonging to this activity type, including old cards.
        for candidate in Activity<ClockAttributes>.activities {
            await Self.endActivity(id: candidate.id)
        }
        clearActivity(message: "已停止显示")
        return true
    }

    private func attach(_ newActivity: Activity<ClockAttributes>) {
        isRunning = Self.isActive(newActivity.activityState)
        startedAt = newActivity.attributes.startedAt
        statusMessage = "正在灵动岛显示当前时间"
        errorMessage = nil
        guard activity?.id != newActivity.id else { return }
        stateTask?.cancel()
        activity = newActivity
        stateTask = Task { [weak self] in
            for await state in newActivity.activityStateUpdates {
                guard !Task.isCancelled, self?.activity?.id == newActivity.id else { return }
                if !Self.isActive(state) {
                    self?.clearActivity(message: "显示已结束，可再次运行")
                    return
                }
            }
        }
    }

    private func clearActivity(message: String) {
        stateTask?.cancel()
        stateTask = nil
        activity = nil
        isRunning = false
        startedAt = nil
        statusMessage = message
    }

    private static func isActive(_ state: ActivityState) -> Bool {
        switch state {
        case .active, .stale: true
        default: false
        }
    }

    // ActivityKit's async methods are nonisolated and its Activity reference is
    // not Sendable in this SDK. Pass IDs across that boundary, not references
    // owned by the main-actor observation state.
    private nonisolated static func endActivity(id: String) async {
        guard let candidate = Activity<ClockAttributes>.activities.first(where: { $0.id == id }) else { return }
        await candidate.end(nil, dismissalPolicy: .immediate)
    }

    private nonisolated static func refreshActivity(id: String) async {
        guard let candidate = Activity<ClockAttributes>.activities.first(where: { $0.id == id }) else { return }
        await candidate.update(ActivityContent(state: .init(refreshedAt: .now), staleDate: nil))
    }
}
