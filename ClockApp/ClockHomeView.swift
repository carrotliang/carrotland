import SwiftUI
import UIKit

struct ClockHomeView: View {
    let manager: ClockActivityManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var currentTimeZone = TimeZone.autoupdatingCurrent
    @State private var isSubmittingAction = false
    @State private var backgroundNotice: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    IslandPresentationPreviews()

                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(manager.isRunning ? Color.green : Color.secondary)
                                .frame(width: 8, height: 8)
                            Text(manager.isRunning ? "运行中" : "未运行")
                                .font(.headline)
                                .accessibilityIdentifier("activityStatus")
                        }
                        Text(manager.statusMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            Task { await performAction() }
                        } label: {
                            HStack(spacing: 8) {
                                if manager.isBusy || isSubmittingAction {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: manager.isRunning ? "stop.fill" : "play.fill")
                                }
                                Text(manager.isRunning ? "停止" : "运行")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 36)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(manager.isRunning ? .red : .accentColor)
                        .disabled(manager.isBusy || isSubmittingAction)
                        .accessibilityIdentifier("toggleActivity")

                        if let backgroundNotice {
                            Text(backgroundNotice)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))

                    if !manager.activitiesEnabled || manager.errorMessage != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("暂时无法显示", systemImage: "exclamationmark.circle")
                                .font(.headline)
                            Text(manager.errorMessage ?? "请在系统设置中允许“萝卜时刻”使用实时活动，再返回重试。")
                                .font(.subheadline)
                            if !manager.activitiesEnabled {
                                Button("打开设置") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        openURL(url)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
        }
        .environment(\.timeZone, currentTimeZone)
        .task { await manager.restore() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            refresh()
        }
    }

    @MainActor
    private func performAction() async {
        guard !isSubmittingAction, !manager.isBusy else { return }
        isSubmittingAction = true
        backgroundNotice = nil
        defer { isSubmittingAction = false }

        let succeeded: Bool
        if manager.isRunning {
            succeeded = await manager.stop()
        } else {
            succeeded = await manager.start()
        }
        guard succeeded else { return }

        // Only a successful user-initiated button action backgrounds the app.
        // Restoration and ActivityKit tests must never trigger this behavior.
        if !PersonalInstallBackgrounding.request() {
            backgroundNotice = "操作已完成，当前系统不支持自动返回主屏幕，请手动上滑返回。"
        }
    }

    private func refresh() {
        currentTimeZone = .current
        Task { await manager.restore() }
    }
}

private struct IslandPresentationPreviews: View {
    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            IslandPreview("常规形态") {
                HStack(spacing: 0) {
                    CompactHourMinuteFace()
                    Color.clear
                        .frame(width: 95, height: 1)
                        .accessibilityHidden(true)
                    CompactSecondFace()
                }
                .padding(.horizontal, 14)
                .frame(height: 37)
                .foregroundStyle(.white)
                .background(.black, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(Color(.systemGray), lineWidth: 1)
                }
                .accessibilityIdentifier("compactIslandPreview")
            }

            IslandPreview("最小形态") {
                MinimalClockFace()
                    .frame(width: 40, height: 37)
                    .foregroundStyle(.white)
                    .background(.black, in: Capsule())
                    .overlay {
                        Capsule().strokeBorder(Color(.systemGray), lineWidth: 1)
                    }
                    .accessibilityIdentifier("minimalIslandPreview")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

private struct IslandPreview<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            content
                .fixedSize()
                .frame(height: 44)
        }
    }
}

@MainActor
private enum PersonalInstallBackgrounding {
    static func request() -> Bool {
        let application = UIApplication.shared
        guard application.applicationState == .active else { return true }

        // NON-PUBLIC API, intentionally limited to this personal-install app.
        // UIKit has no public equivalent for returning a single-scene iPhone
        // app to the Home Screen. Remove this before any App Store release.
        let selector = NSSelectorFromString("suspend")
        guard application.responds(to: selector) else { return false }
        _ = application.perform(selector)
        return true
    }
}
