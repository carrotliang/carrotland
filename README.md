# 灵动萝卜

供个人使用的原生 iPhone 灵动岛样式合集，支持 iOS 26 及以上。目前提供“自然时间”和“计时器”，整个 App 同一时刻只运行一个灵动岛活动。点击另一种类型的“运行”时，先关闭当前活动，再启动所选类型。

| 类型 | 常规形态 | 最小形态 | 展开与锁屏 |
| --- | --- | --- | --- |
| 自然时间 | 左侧 `HH:mm`，右侧 `ss.SSS` | 上方两位秒、下方三位毫秒 | 当前系统时间 `HH:mm:ss.SSS` |
| 计时器 | 左侧秒表图标，右侧累计 `HH:mm:ss` | 累计 `HH:mm` | 累计 `HH:mm:ss` |

计时器点击“运行”后从 `00:00:00` 开始递增。小时、分钟和秒均补齐两位，整秒与整分钟经过后才进位。未运行时预览显示 `00:00:00` / `00:00`；返回桌面、重新打开 App 后继续本次计时，停止后再次运行从零开始。切换到自然时间会结束本次计时；再次运行计时器时从零开始。

每张卡片的标题、操作和预览都位于同一个圆角边框内：顶部为类型标题，下方左侧展示两种胶囊预览，右侧为运行 / 停止按钮，按钮与预览同行，不显示“常规形态”“最小形态”的可见标签。未运行时外框使用系统分隔线颜色，实际活动运行时变为绿色；不显示日常状态行和说明文字。操作失败、权限关闭或无法自动返回主屏幕时，提示按需显示在卡片内。标题的辅助功能值仍提供运行状态，便于 VoiceOver 用户识别。

首页采用紧凑间距：页面左右 12 pt、上下 8 pt，卡片之间 12 pt；卡片内左右 12 pt、上下 10 pt，标题与预览操作行之间 8 pt，预览与按钮之间 8 pt。标题与按钮文字统一使用 subheadline 字号，标题半粗、按钮中等字重；按钮采用浅灰底、10 pt 圆角和小号图标，默认可见高度约 30 pt，点击区域至少 44 pt 高。辅助功能大字号下按钮显示播放 / 停止图标，保持在预览右侧，并与首个胶囊对齐，并通过 VoiceOver 提供完整操作和类型名称；预览名称也保留为辅助功能分组标签。

同一卡片的两种形态预览通常并排显示；可用宽度不足或使用辅助功能大字号时改为上下排列。胶囊自身保留灰色轮廓，最小形态只展示数字胶囊。首页预览与扩展共用显示组件，预览的黑色外形为示意，常规预览中间留白为 72 pt；实际灵动岛的外形、位置与优先级由系统决定。

自然时间固定 24 小时制、等宽数字、三位秒小数，来自手机系统。常规形态的时分为 14 pt、秒为 14 pt、毫秒为 12 pt；右侧秒与毫秒沿同一文字基线排列。最小形态两行居中显示：上方两位秒数为 12 pt，下方三位毫秒为 8 pt，均补零；例如上 `25`、下 `123` 表示 `25.123` 秒。计时器常规形态数字为 14 pt，最小形态为 9 pt。

点击“运行”成功后 App 自动返回主屏幕；点击“停止”立即结束对应实时活动，完成后同样自动返回主屏幕。运行失败时留在 App 内显示原因。

## 打开与安装

1. 使用 Xcode 26 或更新版本打开 `IslandClock.xcodeproj`，选择 **IslandClock** scheme。
2. 在 Xcode → Settings → Accounts 中登录自己的 Apple ID。
3. 分别选择 **IslandClock** 和 **ClockWidgetExtension** target，在 Signing & Capabilities 中选择相同的个人 Team，保留 Automatically manage signing。
4. 默认 Bundle ID 为 `com.kunyaoliang.carrotland` 和 `com.kunyaoliang.carrotland.ClockWidget`。若使用其他账号遇到标识占用，将两者改成自己的唯一标识，并保留扩展以主 App 标识加点开头的关系。
5. 连接、信任自己的 iPhone，开启手机的开发者模式，选择该 iPhone 作为运行设备，点击 Xcode 的 Run。
6. 在手机允许本 App 使用实时活动，点击“运行”，成功后会自动返回主屏幕。停止 Xcode 调试后，仍可从手机桌面独立启动 App。

个人签名的有效期取决于账号和描述文件；签名到期时需通过 Xcode 重新安装。项目不保存开发团队、证书或私钥，签名团队由本机选择。

### 一键编译并安装到手机

在 macOS 上安装完整 Xcode，登录开发者账号，连接并信任 iPhone、开启开发者模式后运行（需要 Python 3，无第三方 Python 依赖）：

```sh
./Scripts/install-to-iphone.py
```

脚本默认执行 Release 真机构建、主 App 及嵌入扩展的严格签名检查、覆盖安装、手机端 Bundle ID 与版本回读，最后在手机未锁屏时启动 App。覆盖安装不会先卸载应用。构建或签名检查失败时不会继续安装；安装已成功但手机锁屏时，会明确提示解锁后手动打开。

签名团队按 `--team`、环境变量 `DEVELOPMENT_TEAM`、本地配置、Xcode 工程设置的顺序选择。首次使用可传入团队 ID：

```sh
./Scripts/install-to-iphone.py --team YOURTEAMID
```

也可以在 `Scripts/install.local.json` 保存本机配置，之后直接运行脚本。该文件已被 Git 忽略，不应加入版本库：

```json
{
  "team": "YOURTEAMID"
}
```

默认选择唯一已配对的物理 iPhone，排除模拟器；多台手机或重名设备必须明确选择。设备按 `--device`、环境变量 `IPHONE_DEVICE`、本地配置的 `device` 字段选择，均接受名称、CoreDevice 标识符或 UDID。常用选项：

```sh
./Scripts/install-to-iphone.py --list-devices
./Scripts/install-to-iphone.py --device '你的 iPhone 名称'
./Scripts/install-to-iphone.py --build-only
./Scripts/install-to-iphone.py --no-launch
./Scripts/install-to-iphone.py --configuration Debug
```

构建会通过 `-allowProvisioningUpdates` 允许 Xcode 管理签名描述文件，需使用已登录的开发者账号。安装包位于 `.build/iphone/DerivedData/Build/Products/Release-iphoneos/IslandClock.app`，每次运行的日志和设备 JSON 结果位于 `.build/iphone/logs/run-*`。这些输出均在 Git 忽略范围内；脚本失败时会保留日志并返回非零退出码。脚本可从任意工作目录通过绝对路径运行。

安装脚本的设备选择、回读及失败保护检查可单独执行，无需连接手机：

```sh
python3 Scripts/test_install_to_iphone.py
```

## 工程结构

- `ClockApp`：首页、权限与错误提示、实时活动生命周期管理。
- `ClockApp/IslandTypeCard.swift`：可复用的卡片外框，接收各类型的卡片内容及运行状态；后续类型可沿首页纵向追加。
- `ClockApp/ClockIslandCard.swift`、`TimerIslandCard.swift`：两种类型的预览与控制入口。
- `ClockApp/IslandActivityCoordinator.swift`：统一串行处理运行、停止和恢复，只保留一个活动，并同步所有卡片状态；后续增加类型时在这里接入会话枚举与结束操作。
- `ClockApp/IslandPresentationPreviews.swift`、`IslandActivityControls.swift`：共用预览排布、标题与预览操作行、异常提示和成功后的返回主屏幕行为。
- `ClockWidget`：灵动岛的常规 / 最小 / 展开布局及锁屏卡片。
- `Shared`：ActivityAttributes、系统日期与时长格式、自动更新的时间文本，以及首页预览与灵动岛共用的显示组件。
- `ClockTests`：实际格式输出、时间边界和真实 ActivityKit 会话集成测试。
- `docs/design/dynamic-carrot-icon-v1.png`：当前“灵动萝卜”图标原稿，以萝卜、黑色灵动岛胶囊和叠层卡片表达样式合集。
- `Scripts/generate-app-icon.swift`：使用 CoreGraphics 将原稿转换为 1024 × 1024、不含透明通道的 App 图标，无外部依赖。

使用 SwiftUI、ActivityKit、WidgetKit 和 Foundation。没有服务器、账号系统、网络校时、推送或后台保活。自然时间通过 `TimeDataSource.currentDate` 和系统内置 `Date.FormatStyle` 自动更新；三位小数使用 `.secondFraction(.fractional(3))`。计时器将开始时刻保存在独立的 `TimerAttributes` 中，通过 `TimeDataSource.durationOffset(to:)` 和系统内置 `Duration.TimeFormatStyle` 显示累计时长。

App 以 ActivityKit 的真实活动列表为准恢复会话，跨类型最多保留一个活动。旧版本遗留多个活动时，只保留开始时间最新的一个，恢复计时器不会重置起点。运行、停止和恢复操作共用串行入口，避免并发创建；操作期间两张卡片的按钮暂时禁用，完成后同步绿色边框与按钮状态。若旧活动结束后新活动创建失败，页面显示失败原因，此时没有运行中的活动。重新进入前台或收到系统显著时间变更通知时，刷新时区和活动内容；不会逐秒或逐毫秒提交活动更新。实际跨时区的后台表现仍须真机检查。

自动返回主屏幕由首页按钮在操作成功后调用 `UIApplication` 的非公开 `suspend` 方法实现，仅用于这个个人安装版本，不适合 App Store 上架。调用前检查方法是否存在；系统不提供该方法时保留页面并提示手动返回。不会退出进程或销毁场景，恢复会话也不会自动把用户送回后台。此调用没有公开兼容性保证，升级 iOS 后需重新验证。

## 显示限制

- **显示三位毫秒不代表每毫秒刷新一次，也不代表具有毫秒级授时精度。** 时间精度取决于手机系统时钟，显示刷新由系统决定。
- 正常亮屏显示完整毫秒。常亮低亮度状态下，锁屏卡片改为“唤醒屏幕查看时间”或“唤醒屏幕查看计时”，唤醒后恢复完整时间，避免系统粗化日期格式后展示不准确的分钟。其他系统限频仍可能省略细粒度字段。
- 单次实时活动最多 8 小时；到期或被系统 / 用户移除后，打开 App 再次运行。
- 系统决定灵动岛的显示优先级；其他 App 同时有实时活动时，本 App 的活动可能进入最小形态。
- 没有灵动岛的设备仍可显示锁屏实时活动。App 不锁定屏幕、不改变手机的自动锁定设置。

参考：[计时时长数据源](https://developer.apple.com/documentation/swiftui/timedatasource/durationoffset(to:))、[时长格式](https://developer.apple.com/documentation/foundation/duration/timeformatstyle)、[TimeDataSource](https://developer.apple.com/documentation/swiftui/timedatasource)、[秒的小数格式](https://developer.apple.com/documentation/foundation/date/formatstyle/symbol/secondfraction)、[实时活动生命周期](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)。

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
