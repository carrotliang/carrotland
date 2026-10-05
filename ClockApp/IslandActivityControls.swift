import SwiftUI
import UIKit

@MainActor
protocol IslandActivityControlling: AnyObject {
    var isRunning: Bool { get }
    var isBusy: Bool { get }
    var activitiesEnabled: Bool { get }
    var errorMessage: String? { get }
    func start() async -> Bool
    func stop() async -> Bool
}

struct IslandActivityControls<Manager: IslandActivityControlling, Preview: View>: View {
    let title: String
    let manager: Manager
    let accessibilityIdentifier: String
    @ViewBuilder let preview: () -> Preview
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isSubmittingAction = false
    @State private var backgroundNotice: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityValue(manager.isRunning ? "运行中" : "未运行")

            HStack(alignment: .top, spacing: 8) {
                preview()
                actionButton
                    // Align with the first 37-point capsule even when the action
                    // grows with Dynamic Type or the second preview wraps below.
                    .alignmentGuide(.top) { dimensions in
                        (dimensions.height - 37) / 2
                    }
            }

            if let backgroundNotice {
                Text(backgroundNotice)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if !manager.activitiesEnabled || manager.errorMessage != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Label("暂时无法显示", systemImage: "exclamationmark.circle")
                        .font(.headline)
                    Text(manager.errorMessage ?? "请在系统设置中允许“灵动萝卜”使用实时活动，再返回重试。")
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
                .padding(16)
                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var actionButton: some View {
        Button {
            Task { await performAction() }
        } label: {
            HStack(spacing: 6) {
                if manager.isBusy || isSubmittingAction {
                    ProgressView().tint(.primary)
                } else {
                    Image(systemName: manager.isRunning ? "stop.fill" : "play.fill")
                        .font(.caption.weight(.semibold))
                }
                // Keep the previews and action on the same row at accessibility sizes.
                // The full action and type name remain available to VoiceOver.
                if !dynamicTypeSize.isAccessibilitySize {
                    Text(manager.isRunning ? "停止" : "运行")
                }
            }
            .font(.subheadline.weight(.medium))
        }
        .buttonStyle(IslandActionButtonStyle())
        .disabled(manager.isBusy || isSubmittingAction)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel("\(manager.isRunning ? "停止" : "运行")\(title)")
        .accessibilityIdentifier(accessibilityIdentifier)
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
}

private struct IslandActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(minWidth: 44, minHeight: 30)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
            // Keep a 44-point touch target around the visually lighter control.
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .opacity(isEnabled ? (configuration.isPressed ? 0.6 : 1) : 0.45)
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
