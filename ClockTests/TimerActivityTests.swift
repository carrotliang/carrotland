import ActivityKit
import XCTest
@testable import IslandClock

final class TimerActivityTests: XCTestCase {
    /// Uses actual ActivityKit sessions. Run only on a disposable simulator.
    @MainActor
    func testSwitchingRestorationAndTimerReset() async throws {
        try requireActivities()
        let timer = TimerActivityManager()
        let clock = ClockActivityManager()
        await timer.stop()
        await clock.stop()
        do {
            let beforeStart = Date.now
            async let first = timer.start()
            async let second = timer.start()
            let starts = await (first, second)
            XCTAssertTrue(starts.0 && starts.1)
            XCTAssertNil(timer.errorMessage)
            XCTAssertTrue(timer.isRunning)
            let origin = try XCTUnwrap(timer.startedAt)
            XCTAssertGreaterThanOrEqual(origin, beforeStart)
            XCTAssertLessThanOrEqual(origin, .now)
            let firstIDs = timerIDs
            XCTAssertEqual(firstIDs.count, 1)

            let repeatedStart = await timer.start()
            XCTAssertTrue(repeatedStart)
            XCTAssertEqual(timerIDs, firstIDs)
            XCTAssertEqual(timer.startedAt, origin, "重复运行不应重置计时")

            let restored = TimerActivityManager()
            await IslandActivityCoordinator.shared.restore()
            XCTAssertTrue(restored.isRunning)
            XCTAssertEqual(restored.startedAt, origin, "重新打开 App 应恢复同一次计时")
            XCTAssertEqual(timerIDs, firstIDs)

            let clockStarted = await clock.start()
            XCTAssertTrue(clockStarted)
            let firstClockIDs = clockIDs
            XCTAssertEqual(firstClockIDs.count, 1)
            XCTAssertTrue(timerIDs.isEmpty, "运行自然时间必须关闭计时器")
            XCTAssertFalse(timer.isRunning, "切换返回时原卡片必须同步为未运行")
            XCTAssertFalse(restored.isRunning, "所有已存在的管理器都应同步")
            XCTAssertNil(timer.startedAt)
            XCTAssertNil(restored.startedAt)
            await restored.stop()
            XCTAssertEqual(clockIDs, firstClockIDs, "停止非当前类型不能关闭正在运行的类型")

            let beforeRestart = Date.now
            let restarted = await timer.start()
            XCTAssertTrue(restarted)
            let newOrigin = try XCTUnwrap(timer.startedAt)
            XCTAssertGreaterThanOrEqual(newOrigin, beforeRestart)
            XCTAssertGreaterThan(newOrigin, origin, "切回计时器必须从新起点开始")
            XCTAssertTrue(timerIDs.isDisjoint(with: firstIDs))
            XCTAssertEqual(timerIDs.count, 1)
            XCTAssertTrue(clockIDs.isEmpty, "运行计时器必须关闭自然时间")
            XCTAssertFalse(clock.isRunning)
            XCTAssertTrue(restored.isRunning)
            XCTAssertEqual(restored.startedAt, newOrigin)
            await IslandActivityCoordinator.shared.restore()
            XCTAssertFalse(clock.isRunning)
            XCTAssertTrue(timer.isRunning, "恢复状态不能重新启动已关闭的类型")
        } catch {
            await timer.stop()
            await clock.stop()
            throw error
        }
        await timer.stop()
        await clock.stop()
        XCTAssertTrue(timerIDs.isEmpty)
        XCTAssertTrue(clockIDs.isEmpty)
        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(clock.isRunning)
    }

    @MainActor
    func testConcurrentCrossTypeStartsLeaveOnlyOneActivity() async throws {
        try requireActivities()
        let timer = TimerActivityManager()
        let clock = ClockActivityManager()
        await timer.stop()
        await clock.stop()
        let tasks = (0..<8).map { index in
            Task { @MainActor in
                let succeeded = index.isMultiple(of: 2) ? await clock.start() : await timer.start()
                let timers = Activity<TimerAttributes>.activities.filter {
                    $0.activityState == .active || $0.activityState == .stale
                }.count
                let clocks = Activity<ClockAttributes>.activities.filter {
                    $0.activityState == .active || $0.activityState == .stale
                }.count
                XCTAssertLessThanOrEqual(timers + clocks, 1)
                return succeeded
            }
        }
        var results: [Bool] = []
        for task in tasks { results.append(await task.value) }
        XCTAssertTrue(results.allSatisfy { $0 }, "跨类型并发请求应依次完成，不能直接丢弃")
        XCTAssertEqual(timerIDs.count + clockIDs.count, 1)
        XCTAssertNotEqual(clock.isRunning, timer.isRunning)
        let finalStart = await timer.start()
        XCTAssertTrue(finalStart)
        XCTAssertEqual(timerIDs.count, 1, "最后一次运行决定最终类型")
        XCTAssertTrue(clockIDs.isEmpty)
        XCTAssertTrue(timer.isRunning)
        XCTAssertFalse(clock.isRunning)
        XCTAssertFalse(timer.isBusy)
        XCTAssertFalse(clock.isBusy)
        await timer.stop()
        await clock.stop()
    }

    @MainActor
    func testRestoreLegacyActivitiesKeepsNewestTimer() async throws {
        try await verifyLegacyRestoration(newestIsTimer: true)
    }

    @MainActor
    func testRestoreLegacyActivitiesKeepsNewestClock() async throws {
        try await verifyLegacyRestoration(newestIsTimer: false)
    }

    @MainActor
    private func verifyLegacyRestoration(newestIsTimer: Bool) async throws {
        try requireActivities()
        let timer = TimerActivityManager()
        let clock = ClockActivityManager()
        await timer.stop()
        await clock.stop()
        do {
            let now = Date.now
            let timerOrigin = now.addingTimeInterval(newestIsTimer ? -10 : -20)
            let clockOrigin = now.addingTimeInterval(newestIsTimer ? -20 : -10)
            // Older persisted attributes included an unused sessionID. Verify
            // those payloads still decode before exercising session restoration.
            let clockAttributes = try JSONDecoder().decode(ClockAttributes.self, from: JSONSerialization.data(withJSONObject: [
                "sessionID": UUID().uuidString, "startedAt": clockOrigin.timeIntervalSinceReferenceDate
            ]))
            let timerAttributes = try JSONDecoder().decode(TimerAttributes.self, from: JSONSerialization.data(withJSONObject: [
                "sessionID": UUID().uuidString, "startedAt": timerOrigin.timeIntervalSinceReferenceDate
            ]))
            // Seed sessions directly to represent an upgrade from the previous version.
            let _ = try Activity<ClockAttributes>.request(
                attributes: clockAttributes,
                content: ActivityContent(state: .init(refreshedAt: now), staleDate: nil),
                pushType: nil
            )
            let _ = try Activity<TimerAttributes>.request(
                attributes: timerAttributes,
                content: ActivityContent(state: .init(), staleDate: nil),
                pushType: nil
            )
            let existingTimerIDs = timerIDs
            let existingClockIDs = clockIDs
            XCTAssertEqual(existingTimerIDs.count + existingClockIDs.count, 2)
            await IslandActivityCoordinator.shared.restore()
            XCTAssertEqual(timerIDs.count + clockIDs.count, 1)
            XCTAssertEqual(timer.isRunning, newestIsTimer)
            XCTAssertEqual(clock.isRunning, !newestIsTimer)
            if newestIsTimer {
                XCTAssertEqual(timerIDs, existingTimerIDs)
                XCTAssertEqual(timer.startedAt, timerOrigin, "恢复时不能重置计时起点")
                XCTAssertTrue(clockIDs.isEmpty)
            } else {
                XCTAssertEqual(clockIDs, existingClockIDs)
                let restoredClock = try XCTUnwrap(Activity<ClockAttributes>.activities.first { existingClockIDs.contains($0.id) })
                XCTAssertEqual(restoredClock.attributes.startedAt, clockOrigin)
                XCTAssertTrue(timerIDs.isEmpty)
                XCTAssertNil(timer.startedAt)
            }
        } catch {
            await timer.stop()
            await clock.stop()
            throw error
        }
        await timer.stop()
        await clock.stop()
    }

    private func requireActivities() throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw XCTSkip("实时活动权限关闭，无法执行 ActivityKit 集成测试")
        }
    }

    private var timerIDs: Set<String> {
        Set(Activity<TimerAttributes>.activities.filter {
            $0.activityState == .active || $0.activityState == .stale
        }.map(\.id))
    }

    private var clockIDs: Set<String> {
        Set(Activity<ClockAttributes>.activities.filter {
            $0.activityState == .active || $0.activityState == .stale
        }.map(\.id))
    }
}
