# 验证记录

日期：2026-10-02（Asia/Shanghai）。

## 环境

- Xcode 26.6（17F113），iOS SDK 26.5。
- 专用模拟器：iPhone 16 Pro，iOS 26.5（23F77），由本任务创建，用后关闭并清理；截图保留在项目中。
- 已配对真机：iPhone 16 Pro，iOS 27.0（24A437），开发者模式已开启。
- 真机安装使用本机已有 Apple Development 签名，Release 构建；无调试器附加。

## 已通过

| 项目 | 结果与证据 |
| --- | --- |
| Debug 模拟器构建 | 主 App 与 WidgetKit 扩展编译通过 |
| Release 真机签名构建 | 编译、扩展嵌入及签名通过；未在仓库保存签名凭据 |
| 时间格式测试 | 5 个 XCTest 全部通过：补零、24 小时制、三位秒小数、跨分钟 / 小时 / 午夜、上海时区与纽约夏令时边界 |
| ActivityKit 集成测试 | 1 个 XCTest 通过：实际系统服务下并发运行仅创建一个活动；重复运行复用；新管理器恢复相同会话；停止清理活动；旧管理器重新同步为空闲 |
| 首页 | 正常显示完整时间，运行 / 停止按钮与状态一致；无障碍树能读到实际时间值 |
| 后台常规灵动岛 | 左侧 `HH:mm`，右侧 `ss.SSS` 可读且不截断；脱离调试器返回桌面后，观察到 `11:37 / 57.696` 变为 `11:38 / 53.506`，跨分钟仍在更新 |
| 停止 | 点击停止后首页显示“已停止显示”，返回桌面确认灵动岛恢复空闲 |
| 锁屏亮屏状态 | 完整时间可读，观察到 `11:50:35.269`；后续截图为 `11:51:01.678` |
| 锁屏低亮度状态 | 显示“唤醒屏幕查看时间”；唤醒后恢复完整时间 |
| 真机部署（自动返回主屏幕修改前） | Release App 已安装到已配对 iPhone，包含低亮度提示的版本安装并启动成功；本次自动返回主屏幕更新尚未安装，见下文 |

首轮自动化测试共 **6 个，0 失败、0 跳过**；最小形态两行显示追加后增至 **7 个，全部通过**，见下文。时间格式测试直接检查 Foundation 的输出；ActivityKit 集成测试使用实际前台测试宿主，不使用模拟的活动列表。这些测试不证明系统的视觉刷新频率或真机常亮行为。

构建中只出现 Xcode 工具链提示：没有 AppIntents 依赖所以跳过元数据提取、已签名扩展未执行二次 strip。最终源代码没有 Swift 并发警告或编译错误。

## 自动返回主屏幕：追加验证

2026-10-02 17:00 左右，在新的专用 iPhone 16 Pro / iOS 26.5 模拟器中完成以下检查。交互时脱离调试器，没有点击模拟器 Home 按钮或手动执行返回手势。

| 操作 | 实际结果 |
| --- | --- |
| 点击“运行” | 自动返回主屏幕；灵动岛显示 `17:01 / 26.221`，仍在更新时间 |
| 点击桌面图标重新进入 App | 停留在首页，显示“运行中”和“停止”按钮；恢复状态未触发自动返回 |
| 点击“停止” | 自动返回主屏幕；灵动岛时钟已移除 |
| 自动化回归 | 6 个测试通过、0 失败、0 跳过；集成测试同时检查运行、复用和停止的成功返回值 |
| Release 签名构建 | 包含本次修改的主 App 和扩展构建、签名通过 |
| 当时的真机更新 | 17:00 左右配对 iPhone 为 `unavailable`，当时未安装；17:11 已随移除底部说明版本完成安装，见下文。真机自动返回行为尚未验收 |

按钮只在操作成功后请求切到后台，权限关闭或启动报错时保留页面；此失败分支经代码检查，尚未补充关闭权限后的 UI 实测。自动返回使用非公开的 `UIApplication.suspend`，只适用于个人安装用途；iOS 后续版本的兼容性没有保证。接口不存在时显示手动返回提示。

本次测试结果包为 `/tmp/IslandClock-BackgroundTests.xcresult`；签名构建产物为 `/tmp/IslandClock-DeviceBuild/Build/Products/Release-iphoneos/IslandClock.app`。临时目录可能被系统清理。

## 移除首页底部说明：安装验证

2026-10-02 17:11，删除首页底部的三段使用说明，重新完成 Release 签名构建，并通过 `devicectl` 安装到已配对的 iPhone 16 Pro。安装和启动命令均成功，Bundle ID 为 `com.kunyaoliang.carrotland`。该版本同时包含运行 / 停止成功后自动返回主屏幕的功能。

本次为说明区域删除，完成源码检查和真机签名构建，未重复运行此前已通过的 6 项自动化测试。安装、启动结果不替代真机页面截图或自动返回主屏幕交互的视觉验收；本次未新增手机截图。构建日志位于 `/tmp/islandclock-clean-home-release.log`。

## 测试发现与处理

### 最小形态两行显示

2026-10-02 17:38 左右，在专用 iPhone 16 Pro / iOS 26.5 模拟器中，同时运行灵动时钟和独立 Bundle ID 的辅助 App 的实时活动，实际触发系统最小形态。辅助 App 仅用于模拟器验证，没有安装到个人手机。

- 最终布局为上方两位秒数、下方三位毫秒，两行居中，分别使用系统 `TimeDataSource.currentDate` 和内置格式。保留系统默认最小形态边距；示例上 `09`、下 `344` 表示 `09.344` 秒。
- 分离小区域：观察到 `09 / 344`，后续截图为 `30 / 904`，完整显示并持续变化。
- 附着在主灵动岛一侧：观察到 `08 / 058`，两行完整显示，无省略号或边缘裁切。
- 结束辅助活动后，恢复常规形态 `17:38 / 45.171`。
- 曾尝试单行 `ss.SSS`，出现省略号；缩小自定义边距又导致字符边缘裁切。按用户提出的两行布局修改并恢复系统默认边距后，通过上述检查。
- 新增独立秒数 / 毫秒格式测试，覆盖 `00 / 000`、`09 / 007`、`25 / 123`、`59 / 999`、跨日 `00 / 001`。本次共 7 个 XCTest 通过，0 失败、0 跳过。首次运行卡在测试启动阶段并被中断，停止测试宿主与辅助 App 进程后重试通过。
- 最终模拟器构建与 Release 真机签名构建通过，17:39 完成手机安装。真机双活动视觉效果仍待观察，不能用模拟器结果替代。

本次测试结果包：`/tmp/IslandClock-MinimalStackRetry.xcresult`；最终构建日志：`/tmp/islandclock-minimal-stack-build.log`、`/tmp/islandclock-minimal-stack-release.log`。两行的系统刷新不承诺每毫秒一次，也未验收秒边界上两行逐帧同步。

2026-10-02 17:47 追加字号调整：秒数从 11 pt 改为 12 pt，毫秒从 9 pt 改为 8 pt，继续两行居中。专用模拟器双活动场景观察到上 `47`、下 `288`，完整显示且字号层级清楚。模拟器与真机签名构建通过，新版已安装到个人 iPhone 并启动成功。本次仅调整字号，未重复执行格式与生命周期测试；日志为 `/tmp/islandclock-minimal-font-build.log`、`/tmp/islandclock-minimal-font-release.log`。

### 低亮度显示

在模拟器的低亮度锁屏状态中，系统自动简化含毫秒的日期格式时，曾在系统锁屏显示 `11:46` 的同时，将活动粗化为 `11:50`。因此锁屏与展开视图显式读取 `isLuminanceReduced`：低亮度时显示唤醒提示，亮屏时恢复 `HH:mm:ss.SSS`。该状态切换已在模拟器观察通过。

此处理是为了避免将系统粗化结果误呈现为当前准确时间。真机上的常亮模式仍需单独检查。

## 首页灵动岛预览与常规形态字号

2026-10-02 18:02 更新：常规形态时分改为 14 pt，秒保留 14 pt，毫秒改为 12 pt；秒、小数点和毫秒使用同一文字基线。最小形态保持上方秒 12 pt、下方毫秒 8 pt。

首页原完整时间与时区区域替换为“灵动岛区域”，分别展示“常规形态”“最小形态”的黑色外形示意和实时数字。首页与 WidgetKit 扩展共用 `Shared/IslandClockFaces.swift` 中的显示组件，未运行活动时也能预览。预览外形为示意，不代表系统固定的灵动岛尺寸或刷新节奏。

- 专用 iPhone 16 Pro / iOS 26.5 模拟器中，首页两种预览及运行按钮完整可见，无裁切；旧的完整时间、时区和底部说明未出现在首页。
- 实际点击运行后自动返回主屏幕，常规灵动岛观察到 `18:01 / 41.113`，毫秒字号较小且与秒沿同一基线排列。后续截图留存在下方。
- 7 项 XCTest 全部通过，0 失败、0 跳过；结果包 `/tmp/IslandClock-PreviewTests.xcresult`。
- 模拟器构建与 Release 真机签名构建通过，新版已安装到配对 iPhone。真机视觉验收仍未新增。

日志：`/tmp/islandclock-preview-tests.log`、`/tmp/islandclock-preview-release.log`。

## 首页预览边框与并排布局

2026-10-02 18:18 更新：首页“灵动岛区域”的常规形态、最小形态改为同一行的两个等宽卡片，各自使用 1 pt 系统分隔线颜色边框和 16 pt 圆角，卡片间距为 12 pt。预览内容按可用宽度以相同比例缩放，实际实时活动的字号与布局不变。

- 专用 iPhone 16 Pro / iOS 26.5 模拟器中，两种形态同一行对齐，边框及数字完整可见；两次界面读取确认时间继续变化。
- Debug 模拟器构建、Release 真机签名构建均通过。本次为首页布局调整，未重复运行此前已通过的 7 项格式与生命周期测试。
- 新版已成功安装到配对 iPhone 16 Pro；启动命令被系统以 `Locked` 拒绝，需解锁后手动打开。此次没有新增真机视觉验收证据。
- 验证完成后已关闭并删除本次专用模拟器，并核实设备列表中不存在该实例。

日志：`/tmp/islandclock-preview-row-build.log`、`/tmp/islandclock-preview-row-release.log`。

## 首页预览边框改为灵动岛轮廓

2026-10-02 18:30 更新：移除上一版的外侧圆角卡片，改为在常规形态和最小形态的黑色胶囊上绘制 1 pt 系统灰色轮廓边框。最小形态移除左侧空白灵动岛，仅保留两行数字胶囊。两种形态继续同一行显示，间距为 24 pt；去掉整体缩放，恢复共享组件的原始字号。实际实时活动未修改。

- iPhone 16 Pro / iOS 26.5 专用模拟器中，边框贴合两个黑色胶囊，外侧卡片和最小形态左侧占位均已消失，两种形态在同一行完整显示；连续界面读取确认数字持续更新。
- Debug 模拟器与 Release 真机签名构建均通过。本次仅调整首页预览，未重复运行格式与生命周期测试。
- 新版已成功安装并启动于已配对的 iPhone 16 Pro；真机视觉效果仍需用户实际查看，安装和启动结果不替代视觉验收。
- 本次专用模拟器已关闭、删除，并核验设备列表中不存在该实例。

日志：`/tmp/islandclock-outline-build.log`、`/tmp/islandclock-outline-release.log`。

## 移除首页标题

2026-10-02 18:34 更新：删除首页“灵动时钟”和“灵动岛区域”两个标题，并隐藏导航栏，避免保留空白标题栏。常规形态、最小形态标签及现有预览、状态、按钮保留。

- Debug 模拟器与 Release 真机签名构建通过；iPhone 16 Pro / iOS 26.5 专用模拟器截图和无障碍树确认两个标题不再出现，预览及按钮完整显示。
- 新版已成功安装到已配对的 iPhone 16 Pro。手机锁屏导致启动命令返回 `Locked`，解锁后可手动打开；未新增真机视觉验收证据。
- 本次仅删除首页标题，未重复运行格式与生命周期测试。专用模拟器已关闭、删除并核验清理结果。

日志：`/tmp/islandclock-no-titles-build.log`、`/tmp/islandclock-no-titles-release.log`。

## 截图

- [常规灵动岛](verification/simulator-compact.png)
- [后台另一时刻](verification/simulator-compact-later.png)
- [锁屏低亮度提示](verification/simulator-lock-dim.png)
- [锁屏亮屏完整时间](verification/simulator-lock-awake.png)
- [点击运行后自动返回主屏幕](verification/simulator-auto-run.png)
- [点击停止后自动返回主屏幕](verification/simulator-auto-stop.png)
- [两行最小形态：分离区域](verification/simulator-minimal-detached.png)
- [两行最小形态：附着区域](verification/simulator-minimal-attached.png)
- [两行字号调整：秒 12 pt、毫秒 8 pt](verification/simulator-minimal-font.png)
- [首页灵动岛区域实时预览](verification/simulator-home-island-previews.png)
- [首页两种形态：圆角边框、同一行显示](verification/simulator-home-bordered-row.png)
- [首页：灵动岛轮廓边框、仅数字最小形态](verification/simulator-home-island-outlines.png)
- [最新首页：去除页面标题和区域标题](verification/simulator-home-no-titles.png)
- [常规形态：时分与秒 14 pt、毫秒 12 pt](verification/simulator-compact-mixed-font.png)

截图均来自本任务专用模拟器，无图片合成。截图样本能够证明所拍时刻的布局和不同时间点的变化，不能据此推算每毫秒刷新或稳定帧率。

## 尚未验收

- 真机正常亮屏下左右布局及三位毫秒持续变化：已向用户发出观察请求，尚未收到反馈；安装与启动成功不替代视觉验收。
- 真机锁屏 / 解锁、常亮显示、低电量模式，以及系统时间 / 时区改变后的后台行为。
- 长按展开、不同屏幕尺寸与辅助功能字号；其他 App 同时运行时的两行最小形态已在上述模拟器验证，真机仍待验收。
- 关闭实时活动权限后的实际系统设置往返流程，以及系统强制结束后的真机恢复。
- 完整运行 8 小时后的到期移除，以及真实跨午夜时两侧在同一刷新周期内的视觉一致性。

真机正常亮屏下若三位小数无法正确显示或时间停住，应记录为毫秒功能未通过验收。当前结论为：**代码、模拟器核心功能、自动返回主屏幕、两行最小形态及首页实时预览验证通过；包含首页预览与最新字号的新版已安装到个人手机，真机完整显示与自动返回交互验收待补充。**

## 复现

在 Xcode 选择专用 iPhone 模拟器，运行 IslandClock scheme 的测试。命令行步骤见项目 README。集成测试会清理该模拟器上本 App 的实时活动，应避免在正在使用时钟的个人手机执行测试。

Xcode 完整测试结果位于本机临时目录 `/tmp/IslandClock-IntegrationTests.xcresult`，可能随系统清理消失。此文档保留测试范围和结果，重新执行测试可生成新的结果包。

## 萝卜时刻：图标与名称更新

2026-10-03 07:04（Asia/Shanghai）更新：采用用户确认的萝卜时钟机器人图标，主 App 和 WidgetKit 扩展的显示名均改为“萝卜时刻”，权限提示同步使用新名称。Bundle ID 保持 `com.kunyaoliang.carrotland`，通过覆盖安装更新原应用，没有卸载。

- 图标原稿保存在 `docs/design/carrot-clock-icon-v1.png`；生成脚本输出 1024 × 1024、sRGB、不含透明通道的 AppIcon。已目视检查原稿转换结果和安装包内的 120 × 120 图标。
- Xcode 26.6 的 Release 真机签名构建通过，`codesign --verify --deep --strict` 通过；主 App 和内嵌扩展的最终 Info.plist 均已核实显示名为“萝卜时刻”。
- `devicectl` 安装成功；安装前回读名称为“灵动时钟”，安装后相同 Bundle ID 的名称为“萝卜时刻”。目标为已配对的 iPhone 16 Pro。
- 启动请求因手机锁屏被系统以 `Locked` 拒绝，解锁后可手动打开。本次没有真机桌面截图，不能将安装与元数据核验视为真机视觉验收。
- 本次仅涉及图标和名称文案，未修改时钟功能，未重复运行格式或 ActivityKit 生命周期测试。

构建日志：`/tmp/carrotland-icon-name-release.log`；安装和回读记录：`/tmp/carrotland-icon-name-install.json`、`/tmp/carrotland-after-install.json`；启动结果：`/tmp/carrotland-icon-name-launch.json`。签名构建产物位于 `/tmp/Carrotland-IconName-20261003/Build/Products/Release-iphoneos/IslandClock.app`，临时文件可能被系统清理。

2026-10-03 07:08（Asia/Shanghai）再次同步：核对当前名称、图标和原 Bundle ID 后，重新完成 Release 构建与严格签名检查，并覆盖安装到同一台 iPhone 16 Pro。手机端回读名称为“萝卜时刻”；07:08:23 启动命令成功，本次启动验证已通过，补充了上一轮因锁屏未能完成的启动检查。尚未新增真机桌面截图或功能交互验收。

本次日志与结果：`/tmp/carrotland-icon-name-resync-release.log`、`/tmp/carrotland-icon-name-resync-install.json`、`/tmp/carrotland-icon-name-resync-apps.json`、`/tmp/carrotland-icon-name-resync-launch.json`。

## 灵动岛类型卡片：首页布局调整

2026-10-04（Asia/Shanghai）更新：标题“时钟灵动岛”放在统一圆角外框上方，常规形态、最小形态和运行 / 停止按钮放在框内。移除日常状态行与说明文字，运行状态通过外框颜色表达：活动运行时为绿色，未运行时为系统分隔线颜色。异常提示仍按需显示。提取 `IslandTypeCard` 通用容器与 `ClockIslandCard` 时钟组件，便于以后沿首页纵向追加其他类型。

本次环境为 Xcode 27.0（27A266a）、iPhone 16 Pro / iOS 27.0（24A434）专用模拟器。

| 验证项 | 本次结果 |
| --- | --- |
| Debug 模拟器构建 | 主 App、新增卡片组件及扩展构建通过；仅有未使用 AppIntents 的元数据提取提示 |
| 现有自动化测试 | 7 项 XCTest 通过、0 失败：6 项时间格式测试与 1 项真实 ActivityKit 生命周期集成测试 |
| 未运行首页 | 标题在框外，两种预览并排位于框内，底部蓝色运行按钮完整，原状态圆点、状态文字和日常说明已消失 |
| 真实活动运行态 | 现有管理器启动真实活动后，外框为绿色、按钮为红色“停止”；胶囊原有轮廓保持不变 |
| 活动停止后 | 现有管理器停止活动后，外框恢复默认颜色、按钮恢复蓝色“运行” |
| 深色模式 | 运行中的绿色边框、两种预览及停止按钮完整可见 |
| 最大辅助功能字号 | 两种预览改为上下排列，标题和按钮放大，数字保持既定字号，无横向裁切 |
| 项目配置与补丁 | `plutil -lint` 与 `git diff --check` 通过 |

未运行和大字号截图来自当前交付源码构建。因本机设备面板无法通过界面工具读取，本次运行 / 停止的视觉验证使用 `/tmp` 下的源码副本，仅在首页恢复任务后增加环境变量控制的 `manager.start()` / `manager.stop()` 调用；卡片、共享数字组件和活动管理器均与交付源码一致，未伪造运行状态。该验证入口没有加入仓库。运行、停止及深色模式截图来自此副本。

本次没有重新验收实际点击按钮后的自动返回主屏幕、权限关闭后的设置往返、VoiceOver 朗读或所有窄屏设备，也没有构建或安装真机版本。上述截图与测试不替代这些验收。

截图：

- [未运行：首页类型卡片](verification/simulator-type-card-idle.png)
- [真实活动运行：绿色外框](verification/simulator-type-card-running.png)
- [活动停止：默认外框](verification/simulator-type-card-stopped.png)
- [深色模式：运行中](verification/simulator-type-card-dark.png)
- [最大辅助功能字号：上下排列](verification/simulator-type-card-accessibility.png)

构建日志：`/tmp/carrotland-island-cards-build.log`。测试日志与结果包：`/tmp/carrotland-island-cards-tests.log`、`/tmp/Carrotland-IslandCards-20261004.xcresult`。临时视觉验证副本：`/tmp/Carrotland-CardVisual-20261004-awb_81bh`，构建日志：`/tmp/carrotland-card-visual-build.log`。临时文件可能被系统清理。

验证结束后，已停止测试活动，关闭并删除专用模拟器，回读设备列表确认该实例已移除；本任务启动的 Device Hub 进程正常结束信号未生效，随后强制结束并核验进程已退出。

### 类型卡片版本：真机覆盖安装

2026-10-04（Asia/Shanghai）追加：用户要求安装到手机。初次检查设备不可用，用户连接并解锁后，设备恢复为已配对且可用，安装前及启动前回读均为 `passcodeRequired: false`。

- 使用当前仓库源码完成 Release 真机签名构建，构建成功；主 App 与嵌入扩展通过 `codesign --verify --deep --strict`。受限环境最初无法完成证书信任检查，使用本机钥匙串访问权限重试后验证通过。
- 核对主 App 和扩展的显示名均为“萝卜时刻”，Bundle ID 分别为 `com.kunyaoliang.carrotland` 和 `com.kunyaoliang.carrotland.ClockWidget`，安装包不包含临时视觉验证入口。
- 已覆盖安装到已配对的 iPhone 16 Pro，没有卸载原应用。安装后回读名称为“萝卜时刻”、版本 1.0、Bundle Version 1，原 Bundle ID 保持一致。
- 启动命令成功，返回 `Launched application with com.kunyaoliang.carrotland bundle identifier.`。本次确认构建、签名、安装、应用身份回读与启动，未新增真机页面截图或点击运行 / 停止的交互验收。

安装包：`/tmp/Carrotland-CardsDevice-20261004/Build/Products/Release-iphoneos/IslandClock.app`。构建日志：`/tmp/carrotland-cards-device-build.log`；安装记录：`/tmp/carrotland-cards-device-install.json`；应用回读：`/tmp/carrotland-cards-app-after.json`；启动结果：`/tmp/carrotland-cards-device-launch.json`。

## 更名为“萝卜灵动”

2026-10-04（Asia/Shanghai）更新：根据灵动岛样式合集的产品定位，将应用名称改为“萝卜灵动”，保留现有萝卜图标的品牌联系。主 App、WidgetKit 扩展的 Debug / Release 显示名以及权限提示统一使用新名称，README 同步说明合集定位及当前提供的时钟类型。

- 使用当前源码完成 Release 真机签名构建，`codesign --verify --deep --strict` 通过；安装包中主 App 与扩展的显示名均确认为“萝卜灵动”。
- 采用原 Bundle ID 覆盖安装到已配对的 iPhone 16 Pro，没有卸载应用。手机端回读名称从“萝卜时刻”变为“萝卜灵动”，版本 1.0、Bundle Version 1。
- 用户解锁后，启动前回读 `passcodeRequired: false`；新版应用启动成功。
- 本次只调整显示名与相关文案，没有重复执行时间格式或活动生命周期测试；安装与名称回读不能替代真机桌面截图或完整功能验收。

构建日志：`/tmp/carrotland-rename-release.log`；安装记录：`/tmp/carrotland-rename-install.json`；更名前后回读：`/tmp/carrotland-rename-before.json`、`/tmp/carrotland-rename-after.json`；启动结果：`/tmp/carrotland-rename-launch.json`。安装包：`/tmp/Carrotland-Rename-20261004/Build/Products/Release-iphoneos/IslandClock.app`。

## “灵动萝卜”：名称调整与灵动岛主题图标

2026-10-04（Asia/Shanghai）更新：按用户要求将名称调整为“灵动萝卜”，同步主 App、WidgetKit 扩展的 Debug / Release 显示名、权限提示与 README。图标改为萝卜主体、黑色灵动岛胶囊和叠层卡片组合，去除原有钟盘，以贴合多种灵动岛样式合集的使用场景。

- 使用内置 image_gen 工具生成新图标，以旧萝卜图标作为品牌参考。新原稿及完整提示词保存为 `docs/design/dynamic-carrot-icon-v1.png`、`docs/design/dynamic-carrot-icon-v1.prompt.txt`；原时钟图标原稿保留为历史设计。
- 更新 `Scripts/generate-app-icon.swift` 的默认输入，生成 1024 × 1024、sRGB、无透明通道的 AppIcon。已目视检查生成图以及安装包中的 120 × 120 图标。
- Release 真机构建和 `codesign --verify --deep --strict` 通过；安装包内主 App 与扩展显示名均为“灵动萝卜”。
- 保持原 Bundle ID 覆盖安装到已配对的 iPhone 16 Pro，手机端回读名称由“萝卜灵动”变为“灵动萝卜”。启动前确认未锁屏，新版应用启动成功。
- 本次为名称、图标与相关文案调整，未重复运行功能测试，也未新增真机桌面截图；安装、名称回读和启动结果不替代真机图标视觉验收。

构建日志：`/tmp/carrotland-dynamic-icon-release.log`；安装记录：`/tmp/carrotland-dynamic-icon-install.json`；应用回读：`/tmp/carrotland-dynamic-icon-after.json`；启动结果：`/tmp/carrotland-dynamic-icon-launch.json`。安装包：`/tmp/Carrotland-DynamicIcon-20261004/Build/Products/Release-iphoneos/IslandClock.app`。


## 自然时间与计时器

2026-10-04（Asia/Shanghai）更新：原“时钟灵动岛”更名为“自然时间”，首页、展开视图和锁屏标题同步调整；新增“计时器”卡片及独立的 ActivityKit 类型。运行时从零递增，常规形态显示 `HH:mm:ss`，最小形态显示 `HH:mm`。每次停止后再运行使用新起点，返回 App 从真实活动恢复原有起点。各自的运行 / 停止操作互不影响，仍使用绿色运行边框与框内底部按钮。

共用的预览排布和操作区域提取为 `IslandPresentationPreviews`、`IslandActivityControls`，类型差异分别由自然时间和计时器组件提供。计时数字使用系统 `TimeDataSource.durationOffset(to:)` 与 `Duration.TimeFormatStyle` 自动渲染，不向系统逐秒提交更新。

本次环境：Xcode 27.0（27A266a），专用 iPhone 16 Pro / iOS 27.0（24A434）模拟器。

| 验证项 | 结果 |
| --- | --- |
| 正式源码 Debug 构建及 XCTest | 11 项通过、0 失败：原 7 项测试，加 3 项累计时长格式测试和 1 项真实计时活动集成测试 |
| 计时格式 | 零值与补零、秒 / 分 / 小时进位前不提前舍入、24 小时累计值不回绕均通过 |
| ActivityKit 独立生命周期 | 并发 / 重复运行保持单会话和原起点；新管理器恢复起点；两种活动共存；停止一种不影响另一种；停止再运行生成新起点，均通过 |
| 首页 | 两张卡片标题、未运行零值、运行绿色边框、重新打开后持续计时、停止计时器后自然时间仍为运行态，均已截图确认 |
| 常规系统灵动岛 | 原生 UI 测试点击运行并确认 App 返回后台；授权后系统显示从 `00:00:07` 递增至截图的 `00:00:12`，秒表符号与完整时分秒均可见 |
| 最小系统灵动岛 | 与独立测试 App 的活动同时运行，系统最小形态显示完整 `01:02`，未裁切；最终原生 UI 渲染测试通过 |
| 锁屏卡片 | 通知中心的锁屏样式卡片显示“计时器”和累计时分秒，截图值 `00:00:09` |
| 真机交付 | 正式源码 Release 构建和严格签名检查通过；原 Bundle ID 覆盖安装成功；手机回读“灵动萝卜”1.0（1）；解锁状态下启动成功 |

为检查超过一小时的格式，临时验证副本通过真实 `TimerAttributes` 注入“当前时间减 3723 秒”的起点；这属于测试数据，不代表持续运行一小时的耐久测试。临时入口、UI 测试目标、独立测试 App 均只位于 `/tmp`，未加入仓库或手机安装包。首页空闲截图来自正式源码构建，运行与系统渲染截图来自使用相同组件、格式和管理器的验证副本。

验证过程中，新建模拟器尚未确认首次实时活动授权，初期桌面未显示内容；在系统通知卡片选择“允许”后恢复显示。中间一轮 UI 测试有 3 个断言失败：2 项在系统内容尚未就绪时读取空标签，1 项假设同一 App 的两个活动会立即触发最小形态。后续改为等待内容就绪，并用独立测试 App 触发最小形态，最终渲染测试通过。中间测试中的双运行、停止计时器后自然时间继续运行及自动返回后台断言均已通过。

本次确认模拟器的数字渲染与核心交互，以及真机的安装、身份回读和启动；未新增真机灵动岛截图，也未执行 8 小时到期、常亮 / 低电量、手动修改系统时间和全部屏幕尺寸的验收。

截图：

- [首页：自然时间与计时器](verification/simulator-timer-idle.png)
- [重新打开：计时器继续运行](verification/simulator-timer-restored.png)
- [两种活动同时运行](verification/simulator-timer-both-running.png)
- [停止计时器：自然时间继续运行](verification/simulator-timer-stopped-clock-running.png)
- [系统常规形态：时分秒](verification/simulator-timer-compact-system.png)
- [系统最小形态：时分](verification/simulator-timer-minimal-system.png)
- [锁屏样式卡片](verification/simulator-timer-lock-screen.png)

测试结果：`/tmp/carrotland-timer-tests-20261004.xcresult`；最终系统渲染 UI 测试：`/tmp/carrotland-timer-ui-render-20261004.xcresult`。临时验证源码：`/tmp/Carrotland-TimerVisual-20261004-rs9bfzot`。正式真机构建日志：`/tmp/carrotland-timer-device-build.log`；安装、回读与启动记录：`/tmp/carrotland-timer-device-install.json`、`/tmp/carrotland-timer-device-after.json`、`/tmp/carrotland-timer-device-launch.json`。安装包：`/tmp/Carrotland-TimerDevice-20261004/Build/Products/Release-iphoneos/IslandClock.app`。临时文件可能被系统清理。

验证结束后已关闭、删除本任务专用模拟器，并回读设备列表确认移除；未启动额外的设备面板进程，临时测试活动随该模拟器一并清理。


## 首页紧凑布局

2026-10-04（Asia/Shanghai）更新：按用户确认的压缩方案缩小页面与卡片留白，保留标题在框外、两种形态预览在框内、底部运行 / 停止按钮，以及运行时绿色边框。

- 页面左右 / 上下内边距改为 12 / 8 pt，卡片间距 12 pt；标题与边框间距 6 pt。
- 卡片左右 / 上下内边距改为 12 / 10 pt，圆角 14 pt；预览与按钮间距 10 pt。
- 去除预览区域额外上下留白，形态名称与胶囊间距 4 pt，预览占用高度与胶囊统一为 37 pt；两种形态之间 12 pt。
- 首页常规预览的摄像头示意留白由 95 pt 缩为 72 pt。共享数字组件和 WidgetKit 的实际显示尺寸未改动。
- 运行 / 停止按钮使用常规系统样式，内容最小高度由 36 pt 降为 30 pt；实际默认总高度为 44 pt。内容只设置最小高度，辅助功能大字号可自然增高。

本次使用 Xcode 27.0（27A266a）、专用 iPhone 16 Pro / iOS 27.0 模拟器验证。正式源码 Debug 模拟器构建和 Release 真机签名构建均成功；主 App 和内嵌扩展通过严格签名检查，显示名、Bundle ID 核对通过。

默认字号下，使用同为 1206 × 2622、3 倍像素密度的前后截图测量蓝色按钮：旧版按钮高度为 50 pt，两张卡片按钮顶边距离为 242.67 pt；新版分别为 44 pt、167.67 pt。扣除各自卡片间距 24 / 12 pt，可得单卡含标题约 218.67 → 155.67 pt；两卡主体总高约 461.33 → 323.33 pt，减少约 30%。

已目视核验默认字号、深色模式和最大辅助功能字号。默认字号下两种形态仍并排，数字与按钮完整；最大辅助功能字号下预览上下排列，标题、数字和按钮均完整显示，按钮随文字增高。此次为首页尺寸调整，未新增测试或重复执行上一轮格式 / ActivityKit 生命周期测试，也未重复验收实际系统灵动岛和运行交互。

新版已采用原 Bundle ID 覆盖安装到已配对 iPhone 16 Pro，回读显示“灵动萝卜”1.0（1）。安装后手机处于锁屏状态，已请求解锁，启动验证等待解锁完成。

截图：[默认字号](verification/simulator-compact-idle.png)、[最大辅助功能字号](verification/simulator-compact-accessibility.png)、[深色模式](verification/simulator-compact-dark.png)。

构建日志：`/tmp/carrotland-compact-simulator-build.log`、`/tmp/carrotland-compact-device-build.log`；测量脚本：`/tmp/carrotland-compact-measure.swift`；安装和回读：`/tmp/carrotland-compact-device-install.json`、`/tmp/carrotland-compact-device-after.json`。签名安装包位于 `/tmp/Carrotland-TimerDevice-20261004/Build/Products/Release-iphoneos/IslandClock.app`，已更新为本轮紧凑布局版本。临时文件可能被系统清理。

已关闭、删除本轮专用模拟器，并通过设备列表回读确认清理完成。

## 标题与操作移入边框顶部

2026-10-04（Asia/Shanghai）更新：按用户要求，将“自然时间”“计时器”的标题移入卡片边框内部，与右侧运行 / 停止按钮处于同一行；常规形态和最小形态预览放在下方。两种类型共用这一结构，运行状态仍由实际活动控制绿色边框。

- 标题操作行与预览间距为 10 pt，沿用卡片左右 12 pt、上下 10 pt 的紧凑内边距。
- 默认字号显示图标和“运行” / “停止”文字；辅助功能字号下使用操作图标，并提供包含操作和类型名称的完整 VoiceOver 标签，保持标题与按钮同行。
- 正式源码 Debug 模拟器构建和 Release 真机签名构建成功，主 App 与扩展的严格签名检查通过。
- 在本轮专用 iPhone 16 Pro / iOS 27.0 模拟器中，已目视核验默认字号、最大辅助功能字号和深色模式：标题与按钮同行，边框包裹完整内容，预览无裁切。
- 本次只调整首页布局，未新增测试或重复执行计时格式、ActivityKit 生命周期及系统灵动岛渲染测试。
- 本轮手机连接显示为不可用，尚未将这个版本安装到手机；上一节的安装记录对应此前的紧凑布局版本。

截图：[默认字号](verification/simulator-header-idle.png)、[最大辅助功能字号](verification/simulator-header-accessibility.png)、[深色模式](verification/simulator-header-dark.png)。

构建日志：`/tmp/carrotland-header-simulator-build.log`、`/tmp/carrotland-header-device-build.log`；设备状态：`/tmp/carrotland-header-device-list.json`。签名安装包：`/tmp/Carrotland-TimerDevice-20261004/Build/Products/Release-iphoneos/IslandClock.app`，当前为标题和按钮同行的版本。临时文件可能被系统清理。

已关闭、删除本轮专用布局验证模拟器，并回读设备列表确认移除；保留其他既有模拟器。

## 全 App 同时只运行一个灵动岛

2026-10-04（Asia/Shanghai）更新：按用户要求，将自然时间与计时器改为互斥运行。点击另一种类型的“运行”，先结束原活动，再启动所选活动；切回计时器时从零开始。卡片的运行 / 停止按钮与绿色边框随真实会话同步。

新增 `IslandActivityCoordinator`，让所有类型的运行、停止、恢复操作共用一个串行入口，并在操作完成前同步已有管理器。操作期间按钮暂时禁用；调用层同时到达的运行请求按进入顺序执行。以后增加类型时，在协调器中接入该类型的会话枚举和结束操作，继续遵守全 App 单活动规则。

打开 App 时扫描所有已支持类型的真实 ActivityKit 会话；若旧版本遗留多个活动，只保留开始时间最新的有效会话，关闭其余活动。恢复计时器保留原起点；停止一个非当前类型不会结束正在运行的其他类型。权限检查在结束旧活动之前完成；若旧活动结束后新活动创建失败，保留错误提示，此时没有运行中的活动。

本次使用 Xcode 27.0、专用 iPhone 16 Pro / iOS 27.0 模拟器：

- 完整 XCTest 共 14 项通过、0 失败，包括自然时间格式 6 项、累计时长格式 3 项、原自然时间生命周期 1 项和切换 / 恢复集成测试 4 项。
- 真实 ActivityKit 集成测试验证了计时器 → 自然时间 → 计时器的双向切换，旧活动立即结束、各管理器状态同步、切回计时器使用新起点、重复运行复用当前会话。
- 8 个跨类型并发运行请求全部完成，检查每次返回时有效活动数不超过 1；最终再次运行计时器后仅保留计时器。
- 直接创建两个真实活动模拟旧版本遗留状态，分别验证自然时间较新、计时器较新的恢复结果，保留原活动 ID 与计时起点。
- Release 真机签名构建通过，主 App 及内嵌扩展通过 `codesign --verify --deep --strict`；名称与 Bundle ID 核对通过。
- 手机仍显示连接不可用，本轮版本尚未安装。本轮验证涵盖源码、构建和模拟器 ActivityKit 会话；未新增真机灵动岛截图或重复验收首页视觉布局。

完整测试日志及结果：`/tmp/carrotland-single-activity-tests.log`、`/tmp/carrotland-single-activity-tests-20261004.xcresult`。真机构建日志：`/tmp/carrotland-single-activity-device-build.log`；设备状态：`/tmp/carrotland-single-device-list.json`。签名安装包：`/tmp/Carrotland-SingleActivityDevice-20261004/Build/Products/Release-iphoneos/IslandClock.app`。临时文件可能被系统清理。

初次编译的并发测试触发 Swift 任务组隔离检查警告；改为主 actor 任务后，最终 4 项切换 / 恢复用例再次全部通过，未出现 Swift 并发警告。最终复测日志及结果：`/tmp/carrotland-single-activity-final.log`、`/tmp/carrotland-single-activity-final-20261004.xcresult`。

已关闭、删除本轮专用模拟器，并回读确认清理完成；其他既有模拟器保持原状态。

## 单活动版本真机安装

2026-10-04（Asia/Shanghai）更新：手机恢复连接后，按用户要求，将最新 Release 签名包覆盖安装到已配对的 iPhone 16 Pro。这个安装包同时包含标题 / 按钮在边框内同行的布局，以及全 App 只运行一个灵动岛、后运行关闭前一个的切换逻辑。

安装前严格签名校验通过，安装命令与 JSON 结果均确认成功。手机端回读为“灵动萝卜”1.0（1），Bundle ID 为 `com.kunyaoliang.carrotland`，保持原应用身份，没有卸载应用。安装前手机处于锁屏状态，已请求解锁，启动验证待完成。

安装包：`/tmp/Carrotland-SingleActivityDevice-20261004/Build/Products/Release-iphoneos/IslandClock.app`；安装结果：`/tmp/carrotland-single-device-install.json`；手机端应用回读：`/tmp/carrotland-single-device-after.json`；安装前锁屏状态：`/tmp/carrotland-single-install-lock.json`。

## 移除形态标签并统一标题与按钮

2026-10-04（Asia/Shanghai）更新：按用户要求，移除首页“常规形态”“最小形态”的可见标签及其占位，两种胶囊预览直接展示。名称保留为辅助功能分组标签，数字内容继续供 VoiceOver 访问。

标题与操作文字统一使用 subheadline 字号，标题半粗、按钮中等字重；按钮改用系统自适应灰色底、10 pt 圆角和小号图标，文字与标题使用相同前景色。默认按钮可见高度约 30 pt，外围点击区域至少 44 pt；禁用与按下状态使用透明度反馈。标题操作行与预览间距由 10 pt 调为 8 pt。

- 正式源码 Debug 模拟器构建、Release 真机签名构建均通过，主 App 及扩展严格签名检查通过。
- 在本轮专用 iPhone 16 Pro / iOS 27.0 模拟器上，已目视核验普通字号、最大辅助功能字号、深色模式：标签不再显示，标题按钮保持同行，胶囊数字完整；辅助功能大字号时预览仍自动上下排列。
- 本次只调整首页外观与辅助功能分组，未新增测试或重复执行上轮单活动切换 / 计时格式测试；绿色运行边框和活动生命周期逻辑未改动。
- 新版已覆盖安装到已配对 iPhone 16 Pro，安装 JSON 成功，手机回读“灵动萝卜”1.0（1）、原 Bundle ID。安装后仍锁屏，本轮未执行真机启动或页面视觉验收。
- 已关闭、删除本轮专用模拟器并回读确认清理；其他既有模拟器保持原状态。

截图：[普通字号](verification/simulator-refined-idle.png)、[最大辅助功能字号](verification/simulator-refined-accessibility.png)、[深色模式](verification/simulator-refined-dark.png)。

构建日志：`/tmp/carrotland-refined-simulator-build.log`、`/tmp/carrotland-refined-device-build.log`；安装、回读和锁屏状态：`/tmp/carrotland-refined-device-install.json`、`/tmp/carrotland-refined-device-after.json`、`/tmp/carrotland-refined-device-lock-after.json`。签名安装包：`/tmp/Carrotland-RefinedDevice-20261004/Build/Products/Release-iphoneos/IslandClock.app`。临时文件可能被系统清理。

## 操作按钮与灵动岛预览同行

2026-10-05（Asia/Shanghai）更新：自然时间和计时器卡片保留上方类型标题，下方将两种胶囊预览与运行 / 停止按钮放在同一横向布局中，按钮位于预览右侧，间距 8 pt。按钮按实际高度与第一个 37 pt 胶囊垂直居中；预览在宽度不足或辅助功能大字号下上下排列时，按钮仍对齐首个胶囊。提示区域位于预览操作行下方。

- 使用 Xcode 27.0（27A266a）完成最终源码 Debug 模拟器构建，结果为 `BUILD SUCCEEDED`；`git diff --check` 通过。
- 专用 iPhone 16 Pro / iOS 27.0 模拟器中，普通字号下两种预览与按钮同行且完整显示；最大辅助功能字号下预览上下排列，图标按钮与首个胶囊垂直居中，内容未越出卡片。
- 本次只调整卡片内容组合与布局，没有新增测试或重复执行活动生命周期测试；未进行真机安装和视觉验收。

截图：[普通字号](verification/simulator-preview-row-idle.png)、[最大辅助功能字号](verification/simulator-preview-row-accessibility.png)。构建日志：`/tmp/carrotland-preview-row-build.log`；模拟器安装包：`/tmp/Carrotland-PreviewRow-20261005/Build/Products/Debug-iphonesimulator/IslandClock.app`。临时文件可能被系统清理。

深色模式冷启动复核通过，标题、数字、胶囊、按钮和边框完整可见：[深色模式截图](verification/simulator-preview-row-dark.png)。中间一次从最大字号恢复普通字号并切换深色模式后，截图出现部分数字未绘制；该次截图保留在 `/tmp/carrotland-preview-row-dark-transition.png`，冷启动截图未再出现，尚未确定切换时绘制异常的原因，不据此宣称所有外观切换场景均已验收。

两次专用模拟器均已关闭、删除并回读设备列表确认移除；本轮开始前已存在的模拟器保持原状态。

## 无用定义与重复恢复逻辑清理

2026-10-06（Asia/Shanghai）在现有未提交工作上完成调用链核对与清理：

- 删除自然时间管理器中不再被界面消费的 `statusMessage`、仅测试读取的 `startedAt` 缓存及相关赋值；保留活动属性中的 `startedAt`，用于选择最新会话。
- 删除两种活动没有实际消费者的 `sessionID`，继续使用 ActivityKit 的活动 ID 区分会话；删除仅测试使用的 `secondMillisecond` 格式分支，改为验证界面实际使用的秒与毫秒分段格式。
- 由 `IslandActivityCoordinator.restore()` 一次完成跨类型去重、自然时间内容刷新及管理器状态同步，删除两个管理器的恢复入口、首页转发方法和停止时重复清理；合并运行状态判定。保留串行入口、活动状态监听和计时起点。

验证结果：Xcode 27.0 在专用 iPhone 16 Pro / iOS 27.0 模拟器完成 App、Widget 扩展及测试构建，14 项 XCTest 全部通过、无跳过；覆盖时间格式、并发启动、跨类型切换、单活动恢复、计时器重置及自然时间内容刷新。两项旧会话恢复测试先解码含旧 `sessionID` 的 JSON，再创建实际 ActivityKit 会话验证恢复；这不等于已完成旧版 App 到新版 App 的真机升级验收。`git diff --check` 通过。

测试日志：`/tmp/carrotland-cleanup-20261006-tests.log`；结果包：`/tmp/Carrotland-Cleanup-20261006.xcresult`。本次未安装到真机，未新增视觉验收。临时文件可能被系统清理。
