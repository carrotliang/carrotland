# 萝卜时刻

供个人使用的原生 iPhone 时钟，支持 iOS 26 及以上。打开 App 点击“运行”，成功后 App 自动返回主屏幕，灵动岛左侧显示 `HH:mm`，右侧显示 `ss.SSS`。

```text
  14:30       [ 摄像头区域 ]       25.123
   时:分                           秒.毫秒
```

首页不显示应用名称和“灵动岛区域”标题，直接在同一行实时展示常规形态和最小形态，不需要先启动活动。边框直接沿黑色灵动岛外形绘制，没有外侧卡片；最小形态只展示两行数字胶囊，不展示左侧的空白灵动岛。两种预览使用原始字号，不再整体缩小。实际灵动岛常规形态的时分为 14 pt、秒为 14 pt、毫秒为 12 pt；右侧秒与毫秒沿同一文字基线排列。与其他活动并排时，最小形态分两行居中显示：上方两位秒数为 12 pt，下方三位毫秒为 8 pt，均补零；例如上 `25`、下 `123` 表示 `25.123` 秒。首页预览与扩展共用数字显示组件，预览的黑色外形为示意，实际灵动岛的外形与位置由系统决定。

展开视图和锁屏卡片显示完整的 `HH:mm:ss.SSS`。所有时间固定 24 小时制、等宽数字、三位秒小数，来自手机系统。点击“停止”立即结束实时活动，完成后同样自动返回主屏幕。运行失败时留在 App 内显示原因。

## 打开与安装

1. 使用 Xcode 26 或更新版本打开 `IslandClock.xcodeproj`，选择 **IslandClock** scheme。
2. 在 Xcode → Settings → Accounts 中登录自己的 Apple ID。
3. 分别选择 **IslandClock** 和 **ClockWidgetExtension** target，在 Signing & Capabilities 中选择相同的个人 Team，保留 Automatically manage signing。
4. 默认 Bundle ID 为 `com.kunyaoliang.carrotland` 和 `com.kunyaoliang.carrotland.ClockWidget`。若使用其他账号遇到标识占用，将两者改成自己的唯一标识，并保留扩展以主 App 标识加点开头的关系。
5. 连接、信任自己的 iPhone，开启手机的开发者模式，选择该 iPhone 作为运行设备，点击 Xcode 的 Run。
6. 在手机允许本 App 使用实时活动，点击“运行”，成功后会自动返回主屏幕。停止 Xcode 调试后，仍可从手机桌面独立启动 App。

个人签名的有效期取决于账号和描述文件；签名到期时需通过 Xcode 重新安装。项目不保存开发团队、证书或私钥，签名团队由本机选择。

## 工程结构

- `ClockApp`：首页、权限与错误提示、实时活动生命周期管理。
- `ClockWidget`：灵动岛的常规 / 最小 / 展开布局及锁屏卡片。
- `Shared`：ActivityAttributes、系统日期格式、自动更新的时间文本，以及首页预览与灵动岛共用的显示组件。
- `ClockTests`：实际格式输出、时间边界和真实 ActivityKit 会话集成测试。
- `docs/design/carrot-clock-icon-v1.png`：已确认的萝卜时钟机器人图标原稿。
- `Scripts/generate-app-icon.swift`：使用 CoreGraphics 将原稿转换为 1024 × 1024、不含透明通道的 App 图标，无外部依赖。

使用 SwiftUI、ActivityKit、WidgetKit 和 Foundation。没有服务器、账号系统、网络校时、推送或后台保活。两侧分别通过 `TimeDataSource.currentDate` 和系统内置 `Date.FormatStyle` 自动更新；三位小数使用 `.secondFraction(.fractional(3))`。

App 以 ActivityKit 的真实活动列表为准恢复会话，同一时刻最多保留一个时钟活动。重新进入前台或收到系统显著时间变更通知时，刷新时区和活动内容；不会逐秒或逐毫秒提交活动更新。实际跨时区的后台表现仍须真机检查。

自动返回主屏幕由首页按钮在操作成功后调用 `UIApplication` 的非公开 `suspend` 方法实现，仅用于这个个人安装版本，不适合 App Store 上架。调用前检查方法是否存在；系统不提供该方法时保留页面并提示手动返回。不会退出进程或销毁场景，恢复会话也不会自动把用户送回后台。此调用没有公开兼容性保证，升级 iOS 后需重新验证。

## 显示限制

- **显示三位毫秒不代表每毫秒刷新一次，也不代表具有毫秒级授时精度。** 时间精度取决于手机系统时钟，显示刷新由系统决定。
- 正常亮屏显示完整毫秒。常亮低亮度状态下，锁屏卡片改为“唤醒屏幕查看时间”，唤醒后恢复完整时间，避免系统粗化日期格式后展示不准确的分钟。其他系统限频仍可能省略细粒度字段。
- 单次实时活动最多 8 小时；到期或被系统 / 用户移除后，打开 App 再次运行。
- 系统决定灵动岛的显示优先级，其他实时活动可能使时钟进入最小形态。
- 没有灵动岛的设备仍可显示锁屏实时活动。App 不锁定屏幕、不改变手机的自动锁定设置。

参考：[TimeDataSource](https://developer.apple.com/documentation/swiftui/timedatasource)、[秒的小数格式](https://developer.apple.com/documentation/foundation/date/formatstyle/symbol/secondfraction)、[实时活动生命周期](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)。

## 编译与测试

先用 `xcrun simctl list devices available` 选择一个已安装运行时的 iPhone 模拟器，然后执行。ActivityKit 集成测试会启动并清理本 App 的会话，请在专用模拟器运行：

```sh
xcodebuild -project IslandClock.xcodeproj -scheme IslandClock \
  -configuration Debug -destination 'platform=iOS Simulator,id=你的模拟器ID' \
  -derivedDataPath /tmp/IslandClock-DerivedData CODE_SIGNING_ALLOWED=NO test
```

真机版本在 Xcode 中选择团队后构建。更新图标原稿后，在仓库根目录运行以下命令重新生成 App 图标：

```sh
swift Scripts/generate-app-icon.swift
```

实际验证状态、环境与待验收项目见 [验证记录](docs/verification.md)。编译和格式测试通过不等于真机毫秒显示已验收。
