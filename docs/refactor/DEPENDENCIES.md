# 当前模块依赖与过渡契约

日期：2026-10-15。下方最初的依赖图是 S3-002 时点快照；当前关系以 `island/build.zig` 显式 `addImport`/`bindModules` 和文末 S5-002 复核为准，不是运行时调用图。

## 历史关键编译依赖（S3-002 时点快照）

`build.zig` 为每个来源建立命名模块并显式绑定。当前非空依赖如下（箭头表示 source → dependency）：

```text
AppIcon → （无模块依赖；纯图标能力契约）
AppBar → Monitor, Log
CardLayout → Geometry, TaskStripLayout
Canvas → Geometry, ThemeTokens
CommandLine → Motion
Diagnostics → Geometry, Motion, StatePolicy, CardLayout, IslandWindow, Lyrics, MiniJson, Monitor, MusicSession, Notification, Renderer, TextRenderer, Theme, WicImage, Log
GlassMaterial → Theme
IslandWindow → AppBar
InputRegion → Geometry, Motion, TaskStripLayout
InputRouter → LayoutSnapshot
LayoutSnapshot → Geometry
Lyrics → MiniJson
MixerSlider → Slider, ThemeTokens
Motion → Geometry
MusicSession → AppIcon, Log, WicImage
NativeTaskbar → Log
Notification → MiniJson
NotificationIcon → AppIcon, WicImage, Log, Notification
NotificationPipe → Log, MiniJson, Notification
PagePainter → Geometry, LayoutSnapshot, TextRenderer（UI 通用回调契约）
Renderer → AppIcon, CardLayout, DrawLifecycle, Geometry, LayoutSnapshot, Motion, Notification, PagePainter, TaskStripLayout, TextRenderer, Theme, Weather, WicImage
PresentationPolicy → （无模块依赖；纯数据策略）
DrawLifecycle → （无模块依赖；纯绘制阶段/错误分类）
AudioService → AppIcon, Log, SoundAudio
AudioVolume → SoundAudio
SoundController → SoundAudio
SoundAudio → （无平台依赖；纯值契约）
SoundPage → Geometry, LayoutSnapshot, SoundAudio, SoundController, MixerSlider, Slider, ThemeTokens, TextRenderer
AppIconService → WicImage
StartApps → WicImage
StatePolicy → Motion
SysStatusProbe → Log
SystemStatus → Log, SystemToggles
SystemToggles → StartMenu
TaskStripLayout → Geometry, Motion
Slider → Canvas, Geometry, ThemeTokens
TextRenderer → Canvas, CardLayout, Geometry, GlassMaterial, Slider, StartApps, TaskStripLayout, Theme, Weather, WicImage
Theme → ThemeTokens
ToastStore → Notification
Weather → Log
WeChatWatch → Notification, Log
WindowList → Monitor
main (composition root) → app-required named modules plus Setup
jsonprobe → MiniJson, Notification
```

无 `bindModules` 的来源模块（例如 Geometry、AudioVolume、DisplayBrightness、Log、MiniJson、Monitor、PlayerWindow、TrayIcons、TrayPress、ThumbnailPreview 等）不声明命名模块依赖。smoke/probe 目标独立保留。

## 历史静态依赖债务（迁移记录）

S1-001 基线为 21 条既存 prohibited edges。S1-003 将图标查询迁出后移除了三个边；S2-004 将 `Theme → Log` 改为 App 注入窄同步日志函数；S3-001 将 Core Audio/枚举及日志从 Feature 目录移至 Windows `AudioService`，allowlist 随之删除 `SoundOutput → Log`。当前 `legacy-dependencies.json` 记录 16 条仍存在旧边，检查为 0 新增、0 未解析；allowlist 仅记录现存兼容债务，不是架构认可。

| 当前边 | 问题 | 迁移任务 / 目标删除条件 |
| --- | --- | --- |
| `Renderer → Notification, Weather` | 通用 Renderer 编排/引用 Feature | S4-004/007：Feature UI 通过公开 View/paint 契约供 Shell 调用后移除；`Renderer → MusicSession` 已在 S1-003 删除；`DrawLifecycle` 只含纯绘制状态 |
| `TextRenderer → StartApps, Weather` | 文本/渲染层含 Launcher/Weather 展示数据 | S4-002、S4-007：对应 UI 独立，公共 renderer 无 Feature imports；SoundPage 专属绘制数据已在 S3-002 移出 |
| `Renderer/TextRenderer → WicImage` | UI 直接耦合 Windows 图像实现 | S1-003、S2-004、S5-002：纯图像数据/窄 image contract 接入并通过资源验证 |
| `IslandWindow → AppBar` | 通用 Window wrapper 直接连 Windows AppBar | S4-006/S5-001：确认 window-host 契约与生命周期，保持行为后移除 |
| `SoundOutput → MusicSession` | Sound 曾复用 Music 私有 icon API | 已于 S1-003 删除；改由 App 注入 `AppIcon.FetchPngFn`，PID+路径缓存有自动测试 |
| `NotificationIcon → MusicSession` | Notification 曾依赖 Music icon API | 已于 S1-003 删除；改由 App 注入 `AppIcon.FetchPngFn` |
| `NotificationIcon → WicImage, Log` | Feature 同时承担图像解码/平台日志 | S1-003/S4-004：平台服务处理系统资源，Feature 只保留纯 icon data |
| `MusicSession → AppIcon, Log, WicImage` | Music WinRT adapter 仍有平台日志/图像解码调用，并只依赖图标能力契约 | S4-001：MediaService 与 image service 按实际 ownership 隔离 |
| `StartApps → WicImage` | Launcher Feature 直接调用平台 image codec | S4-002：Launcher UI 接收应用 icon snapshot |
| `WeChatWatch → Log`、`Weather → Log` | Feature 依赖 Windows logger | S4-004/S4-007：窄日志口或 App 事件记录替换后删除 Windows 依赖 |
| `NotificationPipe → Notification` | Windows Pipe adapter 直接依赖 Notification 内部模型/存储 | S4-004：通知输入值契约独立；adapter 不导入 Feature |
| `SystemToggles → StartMenu` | Windows system adapter 依赖 Launcher Feature 打开页面 | S4-002/S4-006：由 App/Shell 编排 system capability 和 page action |
| `Diagnostics → Feature/UI/Platform 多模块` | App 诊断代码成为广泛依赖汇聚点 | S5-003：只通过明确诊断快照采集；必要依赖逐步缩小 |

以上分类以 import 扫描结果与代码符号为准。没有把每条旧边都当作运行时 bug；步骤完成时只删除已由替代路径接管的边，并更新 allowlist，不扩大例外。

## S1-002 实施结果

- 新增纯数据 `src/shell/PresentationPolicy.zig`，并将 `CardOwner`、`PanelLevel`、卡片/子页优先级和控件点亮派生集中于该模块。
- `PaintContext` 现在持有唯一的 `PresentationPolicy.State` 值；`paintWindow` 对通知/面板/Music 事实进行一次纯策略更新，后续命中和展示读取该状态。
- 移除 `Renderer.nextCardOwner`、Renderer 的 `CardOwner` 类型和未被使用的 `FrameState.card_owner` 字段；移除 `CardLayout` 的重复 `CardOwner`、`PanelLevel` 和控制点亮策略。没有改 UI 几何/绘制样式。
- `build.zig` 显式加入 Shell 模块和测试入口。策略单测覆盖原优先级、关闭保持、关闭完成、快速反向子页选择和按钮状态。
- 自动验证：`zig build test --summary all` 5/5 steps、4/4 tests passed；`zig build --summary all` 16/16 steps succeeded；依赖守卫 21 legacy edges、0 新增、0 移除、0 unresolved。运行命令和人工待测记录在 `AGENTS.md` 与统一清单。

## 公开契约与依赖方向

```text
App / Composition Root
  └─ Shell 展示与输入编排
      ├─ UI Foundation（只读展示数据/布局/受控绘制）
      └─ Feature Public Contract（typed Action + immutable Snapshot）
          └─ Feature Core → Platform Port ← Windows Adapter

Core：纯几何/公共数据；不得依赖 Feature、UI、App 或 Windows 实现。
```

- Shell 唯一决定 Surface/CardOwner/PanelLevel；Renderer 接收决定后的展示数据。
- Feature Core 仅依赖 Core 和所属 Platform Contract；禁止导入其他 Feature 私有实现或 Windows 实现。
- Windows adapter 产生纯值 snapshot/result 和原始错误码；不得调用 Feature 私有页面/Store。
- UI Foundation 接受纯数据和 platform-neutral drawing/image data；不得导入 Music、Sound、Weather、Notification、Launcher 等。
- `build.zig` 仍显式列模块；新边界必须在接入端显式添加，不能启用通配导入。

## 临时桥接与审查门槛

| 桥接 | 当前保留原因 | 删除条件 |
| --- | --- | --- |
| `PaintContext` 聚合服务指针、snapshot 和 UI state | 保持既有运行入口，按 Feature 分步迁移 | 每个 Feature 的 controller/state/action/snapshot 已接入，旧字段不再写入；对应 S4/S5 |
| `Renderer.PillAppearance` 与 `TextRenderer.*Text` Feature 结构 | 维持当前渲染和视觉 | 对应 Feature UI 能提供同一绘制/输入数据后逐项移走，不提前删除 |
| 16 条 `legacy-dependencies.json` | 渐进迁移中的静态守卫基线 | 逐边完成源码替代、自动检查通过并审查之后删除 |
| 旧 `main.zig` 点击/页面分支 | 未迁移功能的唯一现有入口 | 新路径每次只切一个 Feature，自动回归满足后删除该 Feature 对应分支 |

## 本次新增测试入口

`zig build test` 运行 StatePolicy、PresentationPolicy、AppIconService 路径/PNG、AudioService 图标缓存、SoundController/SoundAudio 快照与动作、DrawLifecycle 阶段/错误分类、LayoutSnapshot 几何/坐标、InputRouter 手势/Action，以及 ThemeTokens/Slider/MixerSlider 的纯值和绘制操作测试。IconService 的测试调用 Windows Shell/GDI icon API，但不创建 UI 窗口；GUI/设备/真实 PID 重用检查仍在 `docs/refactor/WINDOWS-MANUAL-TESTS.md` 标记为 `MANUAL_PENDING`。

## S1-003 实施结果

- 新增 `AppIcon.FetchPngFn` platform contract 和 `AppIconService` Windows implementation；Shell/GDI handle acquisition and cleanup plus PNG encoding now live in the Windows adapter. Callers provide the output buffer; no HICON/HDC/HBITMAP escapes.
- App injects the callback into MusicSession, SoundOutput, NotificationIcon, and Renderer. Those modules no longer import one another for app icon extraction, and Renderer no longer imports MusicSession.
- SoundOutput cache keys now include case-insensitive executable path alongside PID. A reused PID with a different path refreshes the same entry; failure does not cache a blank icon permanently. Test covers path case-insensitivity and PID reuse.
- Boundary baseline removed `SoundOutput → MusicSession`, `NotificationIcon → MusicSession`, and `Renderer → MusicSession`; current count is 18 old edges, 0 new/removed/unresolved.
- `zig build test --summary all`: exit 0, 9/9 steps succeeded, icon path/PNG and SoundOutput cache tests passed. `zig fmt --check` passed for modified Zig sources. `zig build --summary all`: exit 0, 16/16 steps succeeded (app, installer, smoke and probes).
- `WIN-ICON-001` remains `MANUAL_PENDING` for real multi-app icon rendering, exit/relaunch, possible PID reuse, and GDI resource trend checks.

## S2-001 实施结果

- 源码审计确认一个真实错误：`Renderer.renderPill` 在 `BeginDraw` 后有多处可提前返回，旧路径未调用 `EndDraw`，可能令 D2D context 留在绘制状态。现在 `DrawLifecycle` 跟踪 target/draw 配对，正常路径和所有错误返回都会在 detach target 前结束 `EndDraw`。
- 修复 `GetBuffer`、D2D target/brush、window icon bitmap 和 Composition opacity animation 的部分失败输出释放；`PushClip/PopClip`、Win32 `GetDC/ReleaseDC`、GDI bitmap selection、WIC stream/decoder/frame/converter、Readback staging/map 与 COM `AddRef/Release` 已按控制流核对。
- `DeviceResources.generation` 每次初始化递增；TextRenderer 新增只清理 D2D bitmap/cache 的 `invalidateDeviceResources`，保留 DirectWrite formats 和业务快照。显示器变更及检测到 D2D/DXGI device-loss HRESULT 时先清缓存，再 shutdown/recreate backend；运行中的 `PaintContext`、Music/Sound/Notification 等 snapshot 未重置，恢复失败最多每秒重试一次。
- D2D/DComp、DXGI、D3D11 设备重建以及清理顺序未声称实机通过；`WIN-GFX-001`、`WIN-LIFECYCLE-001` 为 `MANUAL_PENDING`。
- `zig build test --summary all`：退出码 0，11/11 steps succeeded，3/3 新增 DrawLifecycle tests passed；既有测试目标通过（显示为缓存）。`zig fmt --check` 修改文件退出码 0。`zig build --summary all`：退出码 0，16/16 steps succeeded。静态依赖报告仍为 18 legacy、0 new/removed/unresolved。

## S2-002 实施结果

- 新增平台无关 `LayoutSnapshot`：包含 `ElementId`、Bounds/HitRegion、动画 Transform、内容/页面 Clip、ZOrder、Visible/Enabled、generation 和固定容量元素数组。发布函数只在渲染成功时替换最新快照，失败帧保留此前成功呈现的快照。
- 受控场景为 SoundPage 混音滑块组。App 在每次候选帧中从既有 `CardLayout.soundPageFor` 生成一次滑块轨道坐标；`TextRenderer` 从候选快照读取轨道 Bounds 并使用同一内容 clip；`Renderer` 使用同一快照的 reveal clip。鼠标命中/拖动/游标命中优先查询最近成功呈现的快照；旧布局的滑块命中不会在快照未命中时作为回退命中。其它 SoundPage 控件仍保留原有布局路径。
- 坐标约定：`IslandWindow.Point` 和窗口左/上原点为物理屏幕像素，可为负；`ScreenTransform` 用每 DIP 像素比例换算为 client-local DIPs。CardLayout 和 D2D 画布几何以 client-local DIPs 表示；布局/动画 Transform 的正变换同时供绘制，逆变换供命中。快照同时记录屏幕变换、content viewport 与动画 reveal clip。
- 改动文件：`AGENTS.md`、`docs/refactor/GOAL-TRACKER.md`、`docs/refactor/DEPENDENCIES.md`、`docs/refactor/OWNERSHIP.md`、`docs/refactor/WINDOWS-MANUAL-TESTS.md`、`island/build.zig`、`island/src/ui/LayoutSnapshot.zig`、`island/src/app/main.zig`、`island/src/ui/Renderer.zig`、`island/src/ui/TextRenderer.zig`。S2-003 将 LayoutSnapshot 从 Core 移入 UI Foundation，并把 ElementId 收窄成通用 `.slider`。
- 不变项：仅接入混音滑块轨道和裁剪/命中；其它页面控件、颜色、字体、尺寸、动效参数、音量行为、安装器与 probe 均未改。
- 自动验证：`zig fmt` 修改源码退出码 0；`zig build test --summary all` 退出码 0，6/6 测试通过；覆盖裁剪/动画 reveal、空隙、disabled/invisible、ZOrder、动画 Transform 与 DPI/负坐标。`zig build --summary all` 退出码 0，16/16 steps，IslandBar/安装器/既有默认 probe 成功。`setup-build`、`native-smoke-build`、`thumbprobe-build`、`sysstatusprobe-build`、`geoprobe-build`、`gsmtcprobe-build` 各退出码 0、2/2 steps。依赖守卫退出码 0：18 legacy、0 新增、0 移除、0 未解析。`git diff --check` 退出码 0（仅有 LF→CRLF 提示）。
- 首轮构建发现并修复两处真实集成错误：滚动条分支保留 `device_count/mix_count`；Renderer 用自身 `D2DRectF` 组装 clip，未跨模块调用 TextRenderer 私有 helper。复跑全部相关验证通过。
- Windows 手工待测：`WIN-LAYOUT-001`、`WIN-INPUT-001`、`WIN-DPI-001`、`WIN-UI-001`，均 `MANUAL_PENDING`。尚无真实桌面/显示器/动画点击证据，不将自动几何测试说成 GUI 通过。
- 风险：快照当前只覆盖 SoundPage mixer slider 元素，其他 SoundPage 的设备/返回/滚动等 geometry 仍由旧 CardLayout 路径提供；S3-002 将继续迁移该页面。需要实测动画 reveal、拖动、设备/滚动更新与多 DPI 组合。

## S2-003 实施结果

- 新增 UI Foundation `InputRouter`，只依赖通用 `LayoutSnapshot`；Action 类型表达通用元素调整/释放，携带 ElementId、元素 index、slider fraction、press/drag phase 与 frame generation。Router 接收 screen-pixel press/move/release/cancel，并只读取最近成功呈现的 snapshot。
- App 作为组装/分发处把 `.slider` 调整 Action 映射到现有 `setMixerLevel`，没有将 SoundOutput/AudioVolume 依赖引入 UI。Router 捕获元素 index 与初始 generation；后续 drag 查询 latest-presented generation。取消、离开页面或释放会清除捕获状态。
- 修复真实重复动作：旧流程在 `WM_LBUTTONDOWN` 已调一次音量，`takeClick()` 释放分支又基于同一个 press point 调一次。现在按下/拖动由 Router Action 分发；释放只输出 release，不重复更新。若输入桥接没有记录到 press Action，兼容 click 路径经 Router 补发一次；transient 标记可在捕获被取消时压制重复点击。
- 移除 `mixer_drag_row` 和未使用的 `mixer_drag_pid` 第二份拖动状态；捕获唯一由 InputRouter.Router 持有。页面其他控件暂留原路径，后续由 S3-002 迁入 Sound UI。
- 改动文件：`AGENTS.md`、`docs/refactor/GOAL-TRACKER.md`、`docs/refactor/DEPENDENCIES.md`、`docs/refactor/OWNERSHIP.md`、`docs/refactor/WINDOWS-MANUAL-TESTS.md`、`island/build.zig`、`island/src/ui/InputRouter.zig`、`island/src/ui/LayoutSnapshot.zig`、`island/src/app/main.zig`。
- 自动验证：`zig fmt --check build.zig src/ui/InputRouter.zig src/ui/LayoutSnapshot.zig src/app/main.zig` 退出码 0；`zig build test --summary all` 退出码 0，15/15 steps succeeded，LayoutSnapshot 6 tests + InputRouter 5 tests = 11/11 passed；`zig build --summary all` 退出码 0，16/16 steps succeeded，应用/安装器/默认 smoke-probe artifacts 成功。依赖守卫为 18 legacy、0 new/removed/unresolved；`git diff --check` 退出码 0（仅 LF→CRLF 提示）。
- 自动手势覆盖：一次 press + release 只有一个 adjust、drag 读取新呈现 generation、ZOrder 优先级、clip/gap/zero-size/out-of-bounds 不捕获、快速 cancel/re-press 不复用旧 capture；LayoutSnapshot 覆盖 disabled/invisible 与坐标/动画变换。
- Windows 手工待测：`WIN-INPUT-001`、`WIN-LAYOUT-001`、`WIN-DPI-001`、`WIN-UI-001` 均 `MANUAL_PENDING`。实际 Win32 动画反向、输入区域更新时间、真实主/应用音量改变和多显示器行为未执行。
- 当时遗留风险（已由 S3-001 接管）：`setMixerLevel` 原先从 main/App 直接调用 AudioVolume/SoundOutput；现在统一派发至 Sound Controller。完整非 slider SoundPage UI 仍留待 S3-002。

## S2-004 — 通用 UI 绘制原语与 Sound 滑块样式边界

- 新增纯值 `ThemeTokens`（Color、Accent/Ink tokens、alpha 运算）；主题选择和文件配置仍由 `Theme` 管理，Sound 滑块尺寸/色阶样式由 `features/sound/ui/MixerSlider.zig` 管理。
- 新增受控 `Canvas`（rounded rectangle / ellipse 两种当前实际需要的绘制操作）与通用 `Slider` primitive。Slider 接收只读 `ViewModel` 和 Bounds；无 VDOM、全量绘制命令、全局上下文或堆分配。
- App 把现有主音量/应用会话数据映射为 `Slider.ViewModel`；`TextRenderer` 只适配现有 D2D 画笔回调并调用通用 Slider。Slider 位置仍取成功帧 `LayoutSnapshot`，布局及命中权威没有改变；Sound 专用 track/fill/thumb 视觉参数从公共 TextRenderer 移出。
- `TextRenderer.SoundPageText` 及剩余 SoundPage 绘制/布局仍是临时兼容桥；完整页面 UI/本地状态和 Action 在 S3-002 迁移，其他 feature 页面按 S4 各自步骤迁移。现阶段 Feature ViewModel 仅为混音滑块只读绘制值。
- `Theme → Log` 已收窄为 `Theme.cycleTheme(log_fn)`/`applyRememberedTheme(log_fn)` 的显式日志函数参数，由 App 传入 Windows Log 实现；Theme 不再静态导入平台日志。用户主题解析日志改用栈上缓冲，避免每个无效文件新增长期 allocator 分配。
- 视觉等价：轨道高度/圆角、滑块位置、thumb 半径、Track/Fill/Thumb alpha 与旧代码相同；同一帧同一批元素，没有新布局计算、额外分配或额外 draw 操作。真实帧时间/资源趋势仍需实机测量。
- 自动验证：Zig `0.17.0` 的最终 `zig build test --summary all` 23/23 steps 成功；Theme parser/smoke test 本次 1/1 通过，先前未缓存运行已通过 Slider 2、MixerSlider 1、ThemeTokens 1，合计 5 个新增测试通过。`zig build --summary all` 16/16 steps 成功。`zig fmt --check` 退出码 0；依赖报告 17 legacy、0 新增、0 未解析，并确认移除 `Theme → Log`。`git diff --check` 退出码 0，仅显示 LF→CRLF 提示。
- Windows 实机状态：`WIN-UI-001`、`WIN-PERF-001` 仍 `MANUAL_PENDING`，待检查 Sound 页面截图/主题循环/视觉一致性、帧时间与长期资源趋势。

## S3-001 — Sound State/Action/Controller 与 AudioService

- `features/SoundOutput.zig` 已迁移为 `platform/windows/AudioService.zig`；AppIcon、Log、SoundAudio 是它唯一显式模块依赖。`AudioVolume` 和 `SoundController` 只依赖纯值 `SoundAudio` contract；`SystemStatus` 不再依赖或采样 AudioVolume。SoundController 不导入 Win32/Core Audio。
- `SoundAudio` 仅传设备/会话快照、operation/token、revision 和原始 HRESULT，无 COM pointer。App 连接 master AudioVolume、会话/设备 AudioService 与 Controller；Controller 是 Sound 唯一业务状态 owner，SystemStatus 里的 volume/mute 副本已移除。
- 两个 Windows worker 都用 MTA；COM interface 生命周期留在各自 worker。结果以固定值/锁保护槽回 UI，Controller 通过 token 和 topology generation 丢弃迟到操作；失败/超时保留系统错误码。`RPC_E_CHANGED_MODE` 不再误当成已成功调用 CoInitializeEx。
- S3-001 后：52 个命名来源模块，16 active legacy dependencies、0 新增、0 未解析。自动测试涵盖 Controller 无设备、拓扑更改、重复/快速拖动、失败/HRESULT/超时、权限拒绝、迟到结果、supersede；Windows 真实音频/COM/GUI 仍见 `WINDOWS-MANUAL-TESTS.md`，均 `MANUAL_PENDING`。

## S3-002 — SoundPage UI 与同一布局/命中快照

- `features/sound/ui/Page.zig` 现在拥有声音页 ViewModel、原布局几何、滚动限制、绘制和 hit-to-Action 映射；ViewModel 明确区分 confirmed、displayed optimistic value 和 pending 状态。页面只读 `SoundController.State`、`SoundAudio.Snapshot` 和 `ThemeTokens`，不调用 Windows API。
- `TextRenderer.SoundPageText`、Sound 专用绘制函数/图标 cache 名称以及 `CardLayout.SoundPageLayout/soundPageHitFor` 已移除。通用 `TextRenderer` 暴露页面文本、矩形、clip、slider 和 PNG icon 绘制原语；图标缓存同时检查 revision 与图像内容 fingerprint，页面无 icon 时释放对应设备 bitmap slot。
- UI `PagePainter` 仅定义通用同步 callback；`Renderer` 持有 callback、box、reveal 和 LayoutSnapshot，不导入 Sound。App 将 SoundController 和 Sound UI 连入 Shell，发布成功帧的完整 `.button/.row/.slider/.scrollbar` snapshot，并按类型 dispatch Sound Controller Action。
- `LayoutSnapshot.data_generation` 绑定音频设备/会话拓扑。InputRouter 在拖动中遇到 data generation 变化时取消旧 capture；设备选择/滑块 Action 也拒绝过期 topology，避免旧行继续调节替换后的应用会话。
- 默认 visual metrics 逐项沿用旧布局（40/34/28/40/34/36/14 DIP）、4/2/6 DIP slider geometry，以及原主题 alpha 合成。页面 renderer 不自行重算命中位置；绘制与输入共用最近成功呈现的 snapshot。
- 当前 54 个命名来源模块；自动边界扫描为 16 legacy、0 新增、0 未解析。全量纯 Zig 自动测试 45/45 通过；默认 `zig build --summary all` 16/16，`setup-build` 4/4、五个独立 smoke/probe build 目标各 2/2。Windows 真实音量、设备/会话切换、动画、DPI/多屏与视觉截图仍为 `MANUAL_PENDING`，见统一清单。

## S4-001 — Music / Lyrics / GSMTC / Music UI

- `features/music/Controller.zig` 独占当前音乐/歌词业务状态和 track generation；旧的 `features/MusicSession.zig` 已迁到 `platform/windows/MediaService.zig`，由平台 worker 负责 GSMTC、COM apartment、封面 bytes 和资源释放。
- `platform/contracts/MusicMedia.zig` 是不含 COM 指针的平台值契约。歌词格式/纯解析 helper 位于 `platform/contracts/LyricsProtocol.zig`，Feature 的 `features/music/Lyrics.zig` 保留 Feature façade；Windows `LyricsService` 只通过 generation-tagged 值结果返回，不导入 Feature 私有文件。
- `features/music/ui/Page.zig` 拥有音乐卡片/条的布局、绘制数据映射与命中快照。TextRenderer 只接收通用 `MediaCardContent/MediaCardLayout`；通用 Renderer 只经 Feature painter callbacks 绘制。`CardLayout` 中 Music/Lyrics 专用几何已移除，展示和命中只发布成功帧的 MusicPage snapshot。
- 当前扫描为 14 条已记录历史边、0 新增、0 移除、0 未解析导入；MediaService 与 LyricsService 不再跨层调用 Music Feature。自动测试和构建结果见 S4-001 的 `AGENTS.md` 记录；GSMTC、设备、动画/多 DPI 和视觉验收仍为 `MANUAL_PENDING`。

## S4-002 — Launcher / AppsFolder / Shell commands

- `features/StartApps.zig` 已迁移为 `platform/windows/LauncherService.zig`，仅供 App 组合；`features/StartMenu.zig` 已迁移为 `platform/windows/ShellCommand.zig`。新 `LauncherCatalog` contract 只含固定容量应用值和 launch result，不暴露 Windows 指针给 Feature。
- `features/launcher/Controller` 持有页选择、滚动/选择/电源确认、launch generation 与同呈现帧去重；`features/launcher/ui/Page` 持有 grid/list 几何、裁剪、hover 与 hit-to-Action。`SystemToggles` 现在依赖平台 ShellCommand，不再向上依赖 StartMenu Feature。
- 移除 `TextRenderer → StartApps` 与 `SystemToggles → StartMenu` 已替代边；当前守卫为 11 条历史边、0 新增、0 移除、0 未解析。完整依赖扫描和验证命令见 S4-002 的 `AGENTS.md` 记录；真实 AppsFolder/图标/启动行为仍待 `WIN-LAUNCHER-001`。

## S4-003 — Tray / 托盘窗口与菜单

- 新增 `TrayCatalog` 值契约；`TrayIcons` 只枚举/复制 Windows shell 图标数据并维护 catalog revision，`TrayController` 独占菜单选择、hover 和高影响 Action 规则，`TrayPage` 持有托盘页布局/命中/绘制输入。
- `Renderer`、`TextRenderer` 和 `CardLayout` 不再拥有 Tray 专用绘制/菜单/网格逻辑；App 将已呈现的 Tray 布局快照和语义 Action 接到平台执行。
- `TrayPress` 保持 Windows 专属操作边界；完整 exe 路径筛选进程，无法唯一解析的 legacy UID 拒绝操作。行动目标带 HWND、PID、进程创建时间并在执行前复核。
- 本步未新增代码边界违规：11 条历史违规、0 新增、0 未解析 import；`Renderer → CardLayout` 已替代边从历史 allowlist 移除。

## S4-004 — Notification / ToastStore / WeChat / Pipe（当前边界）

- 当前模块关系：`NotificationInput` 是 platform-neutral 消息与来源事件契约；Notification Feature Store 只依赖该契约；`NotificationPipe`、`ToastStore`、`NotificationIcon` 和 `WeChatWatch`（实现文件 `platform/windows/WeChatAdapter.zig`）是 Windows adapter，只传值，不导入 Feature Store。`NotificationPage` 通过通用 `PagePainter` 调用 UI primitives；Shell/`PresentationPolicy` 继续拥有通知卡片抢占策略。
- `main` composition root 组合平台来源、Feature Store、Feature UI 与 Shell。Pipe wire 保留原 `app/title/body/icon/urgency/sticky` 字段；source/key 是内部身份值，不泄漏进已有协议。
- S4-004 移除 `NotificationPipe → Notification`、`Renderer → Notification` 和已替代的 NotificationIcon 对 MusicSession/WicImage/Log、WeChatWatch → Log 旧依赖记录。当前静态守卫为 6 条登记历史违规、0 新增、0 移除、0 unresolved。
- 自动核验：全量 suite 67/67 tests、默认 build 16/16 steps、边界检查 6 legacy / 0 new / 0 unresolved；Windows Toast、WeChat、Pipe server 和图标实机链路为 `WIN-NOTIFY-001 MANUAL_PENDING`。

## S4-005 — Taskbar / WindowList / Thumbnail 当前依赖边界（2026-10-15）

- `features/taskbar/ui/Layout.zig` 独占任务窗口行的 fit、按钮宽度、hover/title 和 hit 几何；`Page.zig` 生成带 catalog revision/frame generation 的 presented view。`ui/TaskbarPresentation.zig` 只定义通用绘制消费的值型 View，Renderer 依赖该 UI 契约而不依赖 Feature。
- `platform/contracts/TaskbarCatalog.zig` 只定义 WindowId、目录快照、请求和语义 Action；`platform/windows/WindowList.zig` 枚举窗口并维护稳定实例 ID/revision，执行前校验 HWND、PID 与进程创建时间。App 负责把 Controller、Page、WindowList、Renderer 组合起来。
- `features/taskbar/ui/ThumbnailLayout.zig` 只算 DPI/屏幕像素摆放；`platform/contracts/Thumbnail.zig` 仅共享矩形/尺寸/摆放值；`platform/windows/ThumbnailAdapter.zig` 拥有 DWM 注册、预览窗口、图标/标题提取和资源释放。Feature UI 不导入 Windows API，Windows adapter 不导入 Feature。
- 通用 `core/BarControlLayout.zig` 保留 Start/System/Tray/status cluster 几何并替代旧 `TaskStripLayout.zig`；Taskbar 行几何已从 Core 移出。InputRegion 接收最近成功呈现的 task row bounds；绘制、按钮 hit、hover target 和缩略图锚点使用同一个 presented geometry。Renderer 的 WindowIcon cache 以 WindowId+PID+process-created-at+HWND 匹配并在实例离开呈现视图后清理。
- S4-005 后依赖守卫报告仍为 6 条已登记历史边、0 新增、0 删除、0 未解析模块；S4-006 可按 V2 继续实施。`docs/IslandBar-Architecture-V1.md` 保持 `PROPOSED`。

## S4-006 — System 边界

- 允许方向：`features/system/Controller` → `platform/contracts/SystemStatus`；`features/system/ui/Page` → Controller/Status value、`SystemLayout`、UI primitives；`SystemLayout` → Geometry 与 render-only `SystemPanelPresentation`；Windows `SystemService` → Windows SystemStatus/SystemToggles/DisplayBrightness adapters；App 组合 Feature 与 Windows Service。
- `TextRenderer` 仅依赖 `SystemPanelPresentation` render DTO，不接收 System Feature Action，也不导入 Status/Toggles/DisplayBrightness。`SystemPage` 不调用 Win32/COM/DDC/CI；平台适配器不持有 UI 页面或导航决定。
- System Panel 专用布局及命中已从 `core/CardLayout` 移到 `features/system/ui/Layout`；通用 CardLayout 不再保存 System 专有算法。系统设置 URI 作为 Feature Action 目标由 App 交给 ShellCommand 打开。
- 检查结果：6 条已登记历史依赖、0 新增、0 移除、0 未解析 import；`docs/IslandBar-Architecture-V1.md` 状态仍为 `PROPOSED`。Windows 设置操作/设备行为见 `WIN-SYSTEM-001 MANUAL_PENDING`。

## S4-007 — Weather 边界

- 允许方向：`WeatherController` → `WeatherData`；`WeatherPage` → Controller、纯值契约和 `StatusLineWeather`；`WeatherService` → `WeatherData`/Log；App 组合 Service、Controller 与 Page。
- `Renderer`/`TextRenderer` 不导入 Weather Feature/平台实现，只消费 `StatusLineWeather.View`。Weather Page 提供文案、温度和标记种类；共享 renderer 负责排版与图形 primitive。
- 旧 `features/Weather.zig` 已由以上边界替代并移除；原三条 Weather 历史边从 allowlist 移除。其余历史项留待 S5-002 逐项审查，不因扫描结果自动删除。
- 边界检查与 Windows 网络/位置服务手测状态见 S4-007 的 `AGENTS.md` 记录和 `WIN-WEATHER-001 MANUAL_PENDING`。

## S5-001 — App 生命周期边界

- `app/Runtime.zig` 集中依赖 Windows 服务及 Feature Controller 的窄类型，用于创建、连接、启动和逆序停止 worker；其新增显式模块依赖仅为 `LauncherService` 与 `TrayIcons`，没有新增 Feature 间私有依赖。
- `app/WindowHost.zig` 依赖 `IslandWindow`、`AppBar`、`Monitor`、`Geometry` 和日志；窗口消息回调由 App 提供，Platform/UI 对象没有反向导入 App。
- `main.zig` 仍组合 Feature/Page 与 Shell 展示状态，回调参数由 App 线程设置；通用 Renderer/TextRenderer 继续不导入 Feature。静态检查当前 3 条残留历史边，逐项理由在 S5-002 审查。

## S5-002 — 当前边界复核

- `IslandWindow` 实现已从 `src/ui/` 移至 `src/platform/windows/`；命名模块别名不变。它与 `AppBar`、`Monitor` 同属 Windows Platform，`AppWindowHost` 负责组合窗口及其生命周期。
- 通用 `Renderer`/`TextRenderer` 不 import Music、Sound、Weather、Notification、Launcher、Tray、Taskbar 或 System Feature 实现。页面展示值由 Feature UI/公开 render-only DTO 提供；旧 `TaskStripLayout` 已不存在，通用 `BarControlLayout` 与 Feature Taskbar Layout 分别持有自己的几何。
- 现存 allowlist 仅保留 `Renderer → WicImage` 与 `TextRenderer → WicImage` 两条。前者负责 PNG decode/encode/blur 的 renderer asset path，后者负责将已有 icon/artwork PNG bytes 解码到 D2D bitmap cache；解码临时 COM 对象不跨出 `WicImage`，Feature 不直接依赖 WIC。未来抽离必须以注入 codec contract 和自动资源/像素测试替代，不能只删白名单。
- `build.zig` 继续以显式命名模块与 `bindModules` 锁定边界；不合并成隐式相对导入。原 IslandBar/Setup、manifest/RC、native-smoke 和五个 probe build steps 均在 `zig build --summary all` 16/16 成功路径中保留。
- 最终 S5-002 扫描：2 条已登记历史 WIC 边、0 新增、0 未解析；Windows D2D/WIC 资源行为见 `WIN-UI-001`、`WIN-DPI-001`、`WIN-LIFECYCLE-001`，均 `MANUAL_PENDING`。
