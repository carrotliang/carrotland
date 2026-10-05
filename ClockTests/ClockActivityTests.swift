import ActivityKit
import XCTest
@testable import IslandClock

final class ClockActivityTests: XCTestCase {
    /// Uses the actual ActivityKit service in the foreground test-host app.
    /// Run on a disposable simulator: this ends this app's clock sessions.
    @MainActor
    func testConcurrentStartRestorationAndStop() async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw XCTSkip("实时活动权限关闭，无法执行 ActivityKit 集成测试")
        }
        let manager = ClockActivityManager()
        await manager.stop()

        async let first = manager.start()
        async let second = manager.start()
        let (firstSucceeded, secondSucceeded) = await (first, second)
        XCTAssertTrue(firstSucceeded || secondSucceeded)
        XCTAssertNil(manager.errorMessage)
        XCTAssertTrue(manager.isRunning)
        let initialIDs = activeIDs
        XCTAssertEqual(initialIDs.count, 1)

        let repeatedStartSucceeded = await manager.start()
        XCTAssertTrue(repeatedStartSucceeded)
        XCTAssertEqual(activeIDs, initialIDs, "重复运行必须复用原有活动")

        let restoredManager = ClockActivityManager()
        let beforeRestore = Date.now
        await IslandActivityCoordinator.shared.restore()
        XCTAssertTrue(restoredManager.isRunning)
        XCTAssertEqual(activeIDs, initialIDs, "恢复状态不应创建新活动")
        let restoredActivity = try XCTUnwrap(Activity<ClockAttributes>.activities.first { initialIDs.contains($0.id) })
        XCTAssertGreaterThanOrEqual(restoredActivity.content.state.refreshedAt, beforeRestore,
                                    "恢复自然时间时仍应刷新内容，以便系统重建日期格式")

        let stopSucceeded = await restoredManager.stop()
        XCTAssertTrue(stopSucceeded)
        XCTAssertFalse(restoredManager.isRunning)
        XCTAssertTrue(activeIDs.isEmpty)
        await IslandActivityCoordinator.shared.restore()
        XCTAssertFalse(manager.isRunning)
    }

    private var activeIDs: Set<String> {
        Set(Activity<ClockAttributes>.activities.filter {
            $0.activityState == .active || $0.activityState == .stale
        }.map(\.id))
    }
}
