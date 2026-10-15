# 当前状态与资源所有权盘点

日期：2026-10-15。依据工作区最新源码；这是迁移前的现状图，不把目标结构当成已实现事实。源架构文档仍为 `PROPOSED`。

## 权威状态与写入路径

| 状态 / 资源 | 当前权威所有者 | 写入与读取 | 线程 / 生命周期 | 迁移归属与备注 |
| --- | --- | --- | --- | --- |
| 展开/收起及动画进度 | `main.zig` 的 `PaintContext.motion`（`Motion.Motion`） | Win32 输入/状态协调设置目标；绘制循环推进 tick，`Renderer` 读取当前盒体 | UI 线程；伴随窗口生命周期 | 最终由 Shell 持有；绘制层不能选择目标或卡片 |
| 当前卡片归属 | `PresentationPolicy.State.card_owner`，实例保存在 `PaintContext.presentation` | `paintWindow` 每帧按纯值 facts 运行 `PresentationPolicy.next`；输入/布局从同一状态读 | UI 线程 | S1-002 已将唯一策略和类型权威放入 Shell；Renderer 不再声明 `CardOwner` 或选择卡片 |
| 系统子页选择 | `PresentationPolicy.State.panel_level`，与卡片归属合在一个状态值 | 同一个 `PresentationPolicy.next` 按 tray/sound/start 优先级更新；main 用结果编排内容与输入 | UI 线程 | S1-002 已从 `CardLayout` 移除 `PanelLevel` 和策略；几何仍留 Core |
| 子页打开/局部操作 | `PaintContext` 中的 `system_panel_pinned`、`sound_page_open`、`tray_page_open`、`start_page_open` 等 bool 与局部选择字段 | 主窗口输入分支写入，Renderer/TextRenderer 读取 | UI 线程 | 目前 App 集中保存，不等于所有值属于同一 Feature；在 Feature 逐项迁移时分步转移 |
| Music 系统会话 | `MusicSession.MusicSession` worker 与其受锁保护的 `MusicInfo` snapshot | GSMTC/WinRT worker 获取会话和媒体信息；App 通过 `snapshot` 复制；transport 请求经 worker event | worker 创建并拥有 WinRT MTA apartment；stop 等待线程退出后销毁同步对象 | Music Core/Snapshot + Windows Media adapter；App 中 `music_snapshot` 等是复制/派生视图，不应另行写入服务事实 |
| Lyrics | `Lyrics.LyricsProvider` | App 请求/读取当前歌词和 revision；由歌词模块维护解析结果 | 当前对象生命周期由 App；异步/网络线程边界需 S4-001 再核 | Music Feature 的歌词能力；不得阻塞绘制/输入 |
| Sound 设备/会话、主音量与用户意图 | `SoundController.Controller.state`：输出 snapshot、master/session 值、revision、topology generation、乐观值和 pending/error | App 只派发 typed Action；复制 Windows service values/results 后调用 Controller 更新或确认 | Controller 在 UI thread；platform worker 数据经锁保护后按值读取 | S3-001 已合并业务状态权威；AudioService/AudioVolume 内部缓存只服务于 adapter，不由 UI 写入 |
| Core Audio 接口和设备/session 枚举 | `AudioService.AudioService` 的 Windows worker 与 adapter snapshot/result 槽 | worker 枚举、读写 Core Audio、维护 app icon bytes；UI 只能通过 `SoundAudio.Snapshot/OperationResult` 读副本 | worker MTA 创建/使用/Release COM；停止时发 stop event 并 join 后释放同步资源 | COM 指针不越过 `platform/contracts/SoundAudio`；HRESULT 保留在 OperationResult |
| 主端点音量/静音与峰值采样缓存 | `AudioVolume.AudioVolume` 的 Windows adapter worker | worker 每 500 ms 采样确认音量/静音，按请求更新端点并提供 peak；App 复制值给 SoundController | MTA worker；COM interfaces 在 worker 内释放；UI 只读复制值 | `SystemStatus` 不再单独查询/保存 volume/mute；业务确认/乐观状态由 SoundController 持有 |
| Notification 历史/当前通知 | `Notification.Store`（App 提供生命周期）；输入适配由 `NotificationPipe`、`WeChatWatch` 提供 | Pipe/Watcher 生成通知值；Store 去重/保留；Shell 读取 active display 项 | 接入线程和停止顺序需 S4-004 复核 | Notification Core 拥有去重/历史；Pipe 只按公开输入契约投递值 |
| Weather 数据 | `Weather` reader/service 与其 revision | App/Renderer 读取 snapshot；绘制入口当前会查询 `weather_reader` | 当前刷新/超时/请求路径在 S4-007 审核 | Weather Feature 拥有查询状态；UI 读取只读快照 |
| Start apps / system tray / task windows | `AppRuntime.Runtime` 拥有 `StartApps`/`TrayIcons`；`WindowList` 由 App 线程管理 | Runtime 初始化/逆序释放 Launcher 与 Tray 资源；Shell 读取目录快照并编排 Action | HWND/进程身份来自 Windows；资源/身份校验分别在 S4-002/003/005 完成 | Feature 拥有交互语义；Windows adapter 拥有系统句柄和调用 |
| 渲染设备及 COM 图形对象 | `Renderer.DeviceResources` | Renderer 创建、更新、提交并释放 D3D11/DXGI/DComp/D2D 对象 | 单线程 D2D context；应只在 UI 绘制线程调用 | Graphics Backend 拥有设备代际与重建；S2-001 审核错误分支及缓存失效 |
| 文本格式与已上传图像缓存 | `TextRenderer.TextRenderer` | TextRenderer 创建 DirectWrite factory/formats，缓存 D2D bitmap；调用者传入画布/context 和只读页面数据 | 与渲染 context 同线程；销毁在 UI teardown | UI Foundation 应持有通用文本/图像原语；Feature 专用文本模型逐步归入 Feature UI |
| decoded WIC 图像缓冲 | `WicImage.DecodedImage` + 调用者的输出缓冲 | Windows Imaging Component 解码/编码；调用者提供像素缓冲并管理结果 | WIC 调用内部可能初始化 COM；逐调用的 Apartment/释放审计见 S2-001 | Platform image adapter 返回普通像素数据，不把 COM 对象交给 Feature |
| Window/AppBar/Monitor 句柄 | `app/WindowHost.WindowHost` 组合 `platform/windows/IslandWindow`、`AppBar`、`Monitor` | WindowHost 创建窗口、计算初始 bounds/DPI、管理 AppBar 并按序销毁 | UI/window thread；具体关闭顺序仍待 S5-001 实机回归 | App 负责组装；Windows adapters 负责 API 和句柄 |

## S1-003 — 应用图标能力归属

- `AppIconService`（`src/platform/windows/AppIconService.zig`）是 Shell/GDI 文件图标提取、32×32 DIB 绘制、PNG 编码和临时 HICON/HDC/HBITMAP 释放的唯一实现者。调用者只提供 executable path 和 caller-owned byte buffer；原生图形句柄不会逃出适配器。
- `AppIcon.FetchPngFn` 是平台无关的窄端口。App Composition Root 将 Windows service 函数注入 MusicSession、SoundOutput、NotificationIcon 和 Renderer；Feature/UI 不再把 MusicSession 当作图标 service。
- MusicSession、NotificationIcon、Renderer 只使用传入的函数和调用方 buffer；SoundOutput worker 在自身对象中维护 icon bytes cache。Cache identity 现在是 PID + case-insensitive executable path，检测同一 PID 对应不同路径后替换该 PID 条目。
- 自动测试覆盖输入路径边界、当前测试进程的 PNG 图标、相同路径不同大小写命中缓存，以及 PID+路径变化后刷新。真实应用切换和 GDI handle 趋势仍需 `WIN-ICON-001` 人工验收。

## S2-001 — 绘制与设备资源所有权

- `Renderer.DeviceResources` 持有 D3D11/DXGI/DComp/D2D COM 对象和 window icon bitmap；`generation` 标记每次 initialize 建立的新设备代际。shutdown 只释放图形资源，不写入 `PaintContext` 的业务/页面状态。
- 一帧 D2D target/draw 顺序由纯 `DrawLifecycle` 状态检查：绑定 target → BeginDraw → EndDraw（包含提前 return 的 defer）→ detach target → release target/backbuffer。PushClip/PopClip 位于无提前返回的同步区间；HDC、DC、DIB 和临时 COM interfaces 由 defer 或失败分支成对释放。
- `TextRenderer` 的 DirectWrite factory/formats 与 D2D device-dependent bitmap caches 分开管理。设备代际变化先调用 `invalidateDeviceResources` 释放所有 D2D bitmap/cache 与 context key，保留 fonts/formats、App 页面 snapshots 和输入状态；随后 Renderer shutdown/initialize。
- 运行时仅对已识别的 D2D recreate-target、DXGI device-removed/hung/reset/driver-internal HRESULT 自动重建；初始化失败时后续绘制最多每秒重试一次。自动恢复的系统级实际效果仍属于 `WIN-GFX-001`、`WIN-LIFECYCLE-001`，保持 `MANUAL_PENDING`。
- `WicImage` 独立持有进程级 WIC factory/解码缓冲，并按调用 defer 释放 stream、decoder、frame、converter、scaler、bitmap；解码像素指针指向对应 decode slot，调用者不持有 COM 对象。设备重建不清空这些 platform image buffers。

## S2-002 — Sound mixer layout snapshot 与坐标约定

- `LayoutSnapshot.Snapshot` 是所覆盖 Sound mixer slider 控件的布局、裁剪和命中几何载体；`PaintContext` 暂存 candidate 与 last-presented 两个值。Candidate 在帧绘制成功后才发布，失败时留用上次成功帧；关闭 SoundPage 后的成功帧发布空快照。
- App 从 `CardLayout.soundPageFor` 建立滑块轨道元素；同一元素 Bounds 被 TextRenderer 绘制和 hit-test 使用。快照保存页面 viewport 与 reveal clip；Renderer 使用其 surface clip，TextRenderer 对页面滚动内容使用其 content clip。动画 Transform 对 Bounds/clip 正向映射到画布，对命中点使用逆向映射。
- `IslandWindow.Point`/窗口原点是物理屏幕像素坐标；窗口可能位于负坐标显示器。`ScreenTransform` 按绘制帧记录的窗口原点与 pixels-per-DIP 转为 client-local DIPs。CardLayout、快照 Bounds、D2D clip/primitive 使用 client-local DIPs。DPI 比例为 monitor pixels-per-DIP，96 DPI 时为 1。
- 自动几何测试验证负坐标、125% DPI、空隙、裁剪、z-order、可见/启用、动画 Transform 和失败帧不发布。SoundPage 其他控件仍暂由旧几何 API 管理；后续 S3-002 迁入 Sound UI 后扩展 snapshot，而不让本步变成批量页面重写。

## S2-003 — 输入路由与语义 Action

- 通用 `InputRouter` / `LayoutSnapshot` 属于 UI Foundation，只表达元素 ID、元素 index、坐标、frame generation 和通用 slider adjustment，不导入 Sound、AudioVolume 或 Win32。`LayoutSnapshot` 从早期 Core 试点位置移到 UI Foundation；Core 不再持有 UI ElementId/HitRegion 类型。
- `InputRouter.Router` 是 slider press/drag/release/cancel 捕获状态的唯一持有者。App 将通用 `.slider` Action 映射到现有 Sound 调节函数；S3-001 再把分发交给 Sound Controller/AudioService。
- Pointer-down adjustment 是单击的唯一调节 Action；release 只清理捕获。Transient `pending_press_action_handled` 处理窗口消息分离时的重复 click 队列，不代替持久业务状态。

## PaintContext 的跨域汇总

`PaintContext` 当前同时保存窗口/显示器、任务栏、Shell、Music、Sound、Tray、Launcher、Notification、Weather/状态和多种动画/UI 文本。它是现有 UI 线程上的唯一组合根引用容器，但其内部很多字段是**复制 snapshot 或派生展示缓存**，不能当成平台数据的第二个事实源。逐步转移时由新 Feature 持有业务状态，App 仅持有依赖与非拥有引用；不批量搬迁、不同时驱动旧新两条事件路径。

`Renderer.PillAppearance` 与 `FrameState` 是主循环构造后传给 Renderer 的展示值/非拥有指针集合；它们应视为短生命周期只读输入，Renderer 不拥有其中通知、歌词、文本和图像 bytes。`FrameState` 在仓库没有构造/读取调用方，旧 `card_owner` 字段随策略迁移移除；运行时绘制仍由 App 传入已经组装的页面展示字段。

## 对外契约语义（先确定责任，后续步骤再实现）

- **Shell Presentation**：输入为纯值 facts（可见/请求中的卡片、通知是否活动、Music 是否存在、窗口/动画状态）和必要的上次 Shell state；输出为唯一 `CardOwner`、`PanelLevel`/Surface 描述。确定性、无 Win32/COM/绘图副作用。关闭/反向动画继续交由现有 `Motion`。
- **Feature Action**：值类型的用户意图，例如 `SetMasterVolume`、`SetSessionVolume`、`SelectOutput`。Action 表示请求而不直接调用 Win32；由所属 Controller 检查身份/代际并调用端口。
- **Feature Snapshot**：只读复制的纯数据，含必要 revision/generation；不暴露 COM 指针、可变全局对象或另一个 Feature 的私有实现。
- **Platform Port**：仅表达所属能力的输入/结果；平台实现拥有线程、COM apartment、句柄和原始 HRESULT/Win32 错误。回到 Feature 的是复制数据和可诊断错误，不能越权写 UI 状态。
- **UI layout/input**：UI 只消费 Snapshot/样式并输出几何、hit identity 和 typed Action；绘制和命中共用同一布局事实。布局快照在 S2-002 实施，不在此提前假定数据结构。

## 需继续核验的风险

- `PaintContext` 同时留有服务 snapshot 和 UI 展示缓存；迁移时需区分权威与派生值。
- 卡片与子页选择现由 `PresentationPolicy` 唯一计算；App 仍作为组合根持有该状态值并提供页面展示值。将 App 内页面局部状态逐项转到 Feature 的工作留给 S3/S4。
- Core Audio 和 GSMTC worker 生命周期代码已有显式 stop/wait，但 UI shutdown 的整体等待/释放顺序需 S5-001 复核。
- S1-003 已让图标获取归 AppIconService、SoundOutput cache 按 PID+路径识别并可自动测 PID 重用；真实 Feature 页面图标、进程退出/重启和系统 GDI handle 趋势仍由 `WIN-ICON-001` 人工验收，其他 HWND/window icon cache 在 S4-005 再审。
- GUI、真实设备、多屏、设备丢失与真实安装器运行均为 `MANUAL_PENDING`，详见统一清单。

## S2-004 — UI Tokens、Canvas 与 Slider 样式所有权

- `ThemeTokens` 只定义纯 Color、共用 Accent/Ink tokens 和透明度运算；它不读写文件、不记录日志、不持有全局选择状态。`Theme` 仍暂时管理主题列表/选择和持久化。
- Sound mixer Slider 的值映射和专用 track/fill/thumb 样式由 `features/sound/ui/MixerSlider` 负责；只输出通用 `Slider.ViewModel`，不访问音频服务、Renderer 或 Windows API。
- `ui/Slider` 只消费 Bounds 与只读 ViewModel，经 `ui/Canvas` 发出圆角矩形/椭圆绘制；Canvas 后端持有本次绘制调用的 D2D context 借用，不拥有或缓存 COM 资源。
- App 在组装旧 `SoundPageText` 时将 Sound 数据和主题 tokens 映射到 ViewModel；UI renderer 只画 ViewModel，并以已呈现 LayoutSnapshot 的 Bounds 绘制/命中。`SoundPageText` 仍作为 S3-002 前的兼容桥，不视为最终 Feature UI 所有权。
- Theme 的日志不再由 UI Theme 模块直接引用 Windows Log，而由 App 显式传入同步日志函数；回调只用于当前同步主题操作，不保存、不注册、不形成可变全局 Context/EventBus。
- 绘制测试记录了轨道、填充与 thumb 的调用和位置；实际 D2D brush/帧时间/资源趋势仍需 `WIN-UI-001`、`WIN-PERF-001` 实测。

## S3-001 — Sound Controller 与 Windows AudioService

- `features/sound/Controller.zig` 是 Sound 业务状态唯一权威：持有 output snapshot/revision、topology generation、master confirmed value、乐观主/会话值、pending token 和最后原始 HRESULT。UI/App 不另存一份可写 volume/mute/output snapshot。
- `platform/contracts/SoundAudio.zig` 只含固定容量设备/会话值快照、revision、Operation/OperationResult；COM interface、HRESULT 调用和系统设备枚举不跨过契约进入 Feature/UI。
- `platform/windows/AudioService.zig` 所有设备/会话 COM 接口只由该 worker 创建/使用/Release；AudioVolume master endpoint/meter 同样只由它的 worker 操作。两个 worker 请求以值和 token 入队，UI 每轮复制 snapshot/result，Controller 校验 token 与 topology generation 后更新业务状态。
- 两个 worker 均请求 MTA；只有 `CoInitializeEx` 返回成功时才执行 Core Audio 并配对 `CoUninitialize`。stop event 后等待 worker 退出，再释放 event/thread handle 与 critical section；真实启动/退出与设备丢失由 `WIN-LIFECYCLE-001` 和 `WIN-SOUND-*` 实测。
- App 是组合根，只连接 Controller port 到现有 AudioVolume/AudioService；SystemStatus 不再直接读写主音量/静音副本。Sound Page 的旧 TextRenderer/ViewModel/布局桥暂时保留到 S3-002。
- 当前 Controller 采用一个 pending action；新 accepted action supersede 旧乐观值，旧 token 结果不会覆盖新请求。同步拒绝的新请求不取消此前已接受的操作。操作失败公开原始 HRESULT；超过 5 秒未回传以 timeout 结束。`MANUAL_PENDING` 不能证明设备切换、权限策略和真实线程启停行为。

## S3-002 — SoundPage UI 与呈现快照

- `features/sound/ui/Page.zig` 拥有声音页 read-only ViewModel、布局几何、滚动范围、hit-to-Action 规则和绘制顺序；它读取 Controller state 与 SoundAudio value snapshot，不调用 Windows API。
- `SoundPage.LocalState` 定义页面 scroll/hover/pressed 状态，当前值由 App `PaintContext.sound_page_state` 单独保存；`LayoutSnapshot` 的 candidate/presented pair 也暂由 App UI 线程保存，只有绘制成功才发布 presented snapshot。SoundPage 从同一个 ViewModel/geometry 产出 `.button/.row/.slider/.scrollbar` 元素，命中和绘制读同一 Bounds。
- `InputRouter.Router` 是滑块 press/drag/release 捕获状态的唯一 owner，并记录 frame generation 与 data generation。音频 session/device topology generation 更新会清除捕获；Feature Action 对过期 generation 再校验一次。
- `TextRenderer` 只提供通用文本、矩形、clip、slider、图像 primitive；Sound 专用 `SoundPageText`/draw function/icon bitmap cache 已移除。`PagePainter.Painter` 是 UI 通用同步回调契约，`Renderer.PillAppearance` 只持有通用 painter/box/reveal/layout，不知道具体 Feature。
- App 只组合 Sound Controller、AudioService、Feature UI 和 Shell 子页展示；不再维护 SoundPage 文案副本、独立 hit 几何或 page draw 分支。所有音频写操作经 Sound Controller typed Action。
- 原页面尺寸、字体 format、颜色、主题 alpha、slider track/thumb 和滚动节奏沿用既有值。实际截图、设备变更和动画输入仍待 `WIN-UI-001`、`WIN-LAYOUT-001`、`WIN-INPUT-001`、`WIN-SOUND-001/002` 人工测试。

## S4-001 — Music 最新所有权

- `features/music/Controller.State` 是当前歌词有效性和 track generation 的唯一业务权威。Track 切换或会话消失会清除旧歌词并推进 generation；旧网络/worker 结果必须带原 generation，经 Controller 拒绝后才允许进入 UI snapshot。
- `platform/windows/LyricsService` 拥有歌词请求/传输和 worker 生命周期，只输出值类型 `LyricsProtocol.Lyrics` 加 track generation；`platform/contracts/LyricsProtocol` 是共享纯协议解析代码，不持有 Feature 状态或 Windows 实现。
- `platform/windows/MediaService` 拥有 GSMTC worker 的 COM apartment、系统媒体会话和 WIC 封面解码；`MusicMedia` 只传复制值及固定容量图像数据，不传 COM 对象。
- `features/music/ui/Page` 拥有 Music 卡片/条 view mapping、局部布局、展示绘制映射及 hit Action。Renderer 和 TextRenderer 只持有通用绘制契约/回调；App 组装 service、Controller 与 Feature UI，并仅在成功绘制后更新 presented Music layout。
- 既有 ownership 表中的 `MusicSession`、`LyricsProvider` 行作为迁移前历史记录保留；本节为 S4-001 后的现行权威覆盖。`WIN-MUSIC-001`、`WIN-ICON-001`、`WIN-LIFECYCLE-001`、`WIN-UI-001`、`WIN-INPUT-001`、`WIN-DPI-001`、`WIN-GFX-001` 仍需 Windows 实机验收。

## S4-002 — Launcher 最新所有权

- `platform/windows/LauncherService` 拥有 AppsFolder 枚举、应用图标和 ShellExecute；平台返回 `LauncherCatalog.App/LaunchResult` 固定值。`features/launcher/Controller.State` 独占当前页、列表滚动/选择、电源确认及 launch generation/pending/result；Feature 不调用 Windows API。
- `features/launcher/ui/Page` 独占 Launcher 页面 geometry、裁剪、网格/list hover 与 hit-to-Action。App 组装 Service/Controller/UI，并只使用最近成功呈现的 LayoutSnapshot 派发输入；grid gutters 不产生 hit，重复同一 frame generation 的启动 action 被拒绝。
- `SystemToggles` 只依赖 `platform/windows/ShellCommand`，不再依赖 `features/StartMenu`。旧 `StartApps`、`StartMenu` 文件路径是迁移前记录；`WIN-LAUNCHER-001`、`WIN-UI-001`、`WIN-INPUT-001`、`WIN-DPI-001`、`WIN-LIFECYCLE-001`、`WIN-ICON-001`、`WIN-SYSTEM-001` 的真实 Windows 验收仍为 `MANUAL_PENDING`。

## S4-003 — Tray 当前权威

- `TrayIcons` 独占 Windows shell 图标快照读取、registration 比较与 catalog revision；`TrayCatalog.Icon` 不暴露 COM 指针，身份值包括 tooltip/name、完整 executable path、UID/GUID、promoted 状态和 registration 时间。
- `TrayController.State` 是菜单/选择/hover/退出确认的唯一 owner；菜单打开时复制带 catalog fingerprint/revision 的身份及可用 `WindowInstance`。App 执行 Action 前复核 HWND、PID、进程创建时间和完整 image path。
- `TrayPage.LayoutSnapshot` 是托盘绘制与 hit 的同一几何来源。Renderer/TextRenderer 只接收通用 Feature Painter/primitive，不持有 Tray 私有 UI 或菜单分支。
- `TrayPress` 拥有 shell flyout/COM UI Automation/鼠标注入实现；legacy UID 若指向多个不同矩形则拒绝，进程查找使用完整路径而不是 exe basename。

## S4-004 — Notification / ToastStore / WeChat / Pipe

| 状态 / 资源 | 当前权威所有者 | 写入与读取 | 线程 / 生命周期 | 迁移归属与备注 |
| --- | --- | --- | --- | --- |
| 通知历史、已读、source/key 去重、sticky 来源消费 | `features/notification/Controller.zig` 的 Store | App 按值提交 `NotificationInput.Event`；Shell 读取展示候选；UI 读取 Feature View | Store 生命周期由 App 组合持有；adapter poll 在主循环中轮询 | Feature Store 是唯一业务状态权威；短通知过期规则和 sticky fallback 保留 |
| Pipe/Toast/WeChat 输入 | `platform/windows` adapters；边界只发 `NotificationInput.Message/Event` | Pipe 保持现有 JSON 字段；Toast/WeChat 转成值事件；App 调用 Store `apply/ingest` | Pipe start/stop 由 App；WeChat window poll 在 UI 主循环；原生资源不跨 adapter | Adapter 不导入 Feature Store；source identity 只在内部契约使用 |
| 通知卡片布局与显示数据 | `features/notification/ui/Page.zig` 的 View/`layoutFor` | App 生成 Feature View；Renderer 经 `PagePainter` 同步回调读取；Page 单独计算几何 | 与 Renderer 同步绘制；bitmap cache 由 TextRenderer 的设备代际管理 | Shell 独占通知优先级；原卡片布局、文案位置、字号和 NoticeStrip 外观保留 |
| Toast/WeChat 来源身份 | `NotificationInput.SourceIdentity` + Feature Store source/key | adapter 生成固定身份 key；Feature 对未读 key 去重并只撤销匹配来源项 | 事件身份随来源有效期；不传 COM/HWND | 来源活跃状态由 adapter 报事件；history/read 状态归 Feature |

- 本步自动测试覆盖 JSON wire、Store 去重/撤销、NotificationPage 几何和 WeChat call transition。真实 Windows Toast/Pipe/WeChat/GUI 仍 `MANUAL_PENDING`。

## S4-005 — Taskbar 最新所有权（2026-10-15）

- `WindowList` 是 Windows 窗口目录与稳定实例身份的唯一所有者；`TaskbarCatalog` 是纯值边界；`TaskbarController.State` 独占当前快照、hover 窗口身份和按 WindowId 保存的动画量，并只从有效 revision 产生激活/最小化请求。
- `features/taskbar/ui/Layout` 唯一计算 Taskbar 行几何；`TaskbarPage` 在 App 提供的窗口值上生成 `TaskbarPresentation.View`。成功绘制后 App 才发布 presented view；Renderer、原生 hit test、点击 Action、hover 与 InputRegion 都读取这份视图。失败帧不替换旧 presented view。
- Renderer 的窗口 icon cache 只缓存仍显示的稳定窗口实例；窗口退出或 HWND 被不同 PID/创建时间实例复用后，旧缓存被移除。缩略图入口由 App 从 `WindowList.handleForIdentity` 获取一次性复核后的 HWND；`ThumbnailAdapter` 只拥有 DWM/GDI/native HWND 资源，Feature `ThumbnailLayout` 只拥有纯摆放计算，契约只传像素值。
- 共享 Core `BarControlLayout` 只管 Start/System/Tray/status controls；Taskbar 专有行布局已不在 Core、Renderer 或 TextRenderer 中重复计算。`WIN-TASKBAR-001`、`WIN-INPUT-001`、`WIN-DPI-001`、`WIN-UI-001`、`WIN-ICON-001` 的原生实测均 `MANUAL_PENDING`，不阻塞 S4-006。

## S4-006 — System Panel 当前所有权（2026-10-15）

- `platform/contracts/SystemStatus.Snapshot` 是跨边界的纯值契约；`platform/windows/SystemStatus` 负责 Win32 查询并保留查询失败时的既有值。`SystemController.State` 是 System Feature 内 status、布局数、亮度能力/确认百分比和分页位置的唯一权威。
- `features/system/ui/Page` 负责状态映射、标签、分页/Action 列表和 System Panel View；`features/system/ui/Layout` 独占专用 tile/slider/page hit 几何。`ui/SystemPanelPresentation.View` 只有绘制值与布局，不含业务 Action。TextRenderer 消费该值型 View，不导入 System Feature。
- App 只把 Page Action 编排为 Shell 导航或调用 `platform/windows/SystemService`；Service 封装 `SystemStatusReader`、`SystemToggles` 和 DDC/CI brightness adapter。开关请求不乐观修改状态，异步结果后重新采样；亮度仅在 adapter 写入并读回成功时更新。能力不可用只移除亮度 slider。
- `core/CardLayout` 中 System Panel 专用布局/命中和对应 test 已迁至 System Feature UI；Start/Tray/Music 等共享几何仍留在 Core。视觉常量、tile 顺序、标签、滑块尺寸与设置 URI 保持。
- `WIN-SYSTEM-001`、`WIN-INPUT-001`、`WIN-DPI-001` 仍 `MANUAL_PENDING`；Status/Toggle/DDC/CI 和原生 GUI 未在自动环境运行。此状态不阻塞 S4-007。

## S4-007 — Weather 当前所有权

- `platform/windows/WeatherService.zig` 独占 WinHTTP/Windows Location 查询、解析、后台轮询、15 分钟刷新/1 分钟重试和线程安全 last-good transport cache；它只发布 `WeatherData.SourceSnapshot` 固定值，不生成 UI 文案或持有绘制对象。
- `features/weather/Controller.zig` 独占 App 使用的 Weather `State`，按 source revision 接收快照、拒绝旧 revision、保留 last-good 值，并报告 `unavailable/fresh/cached/stale`。陈旧阈值为 30 分钟；状态元数据不改变现有显示外观。
- `features/weather/ui/Page.zig` 独占 WMO 文案映射、天气图标映射、温度格式化和 `StatusLineWeather.View` 构建。`ui/StatusLineWeather.zig` 是 render-only 展示契约；Renderer/TextRenderer 只绘制该值型贡献，不导入 Weather Feature/Service。
- App 在调度/快照同步路径读取 Service 快照并调用 Controller；绘制只读取已确认的 Controller 状态，不发网络请求。城市配置在请求期间变化时丢弃该响应；串行 worker 与 revision 防止迟到结果覆盖当前状态。`WIN-WEATHER-001` 实机仍 `MANUAL_PENDING`。

## S5-001 — App Runtime 与窗口宿主

- `app/Runtime.zig` 是 App 组合层 Windows worker 与长期服务的生命周期所有者：通知 Pipe、Music/GSMTC、Lyrics、PlayerWindow、SystemStatus、AudioVolume、AudioService 和 Weather；它也持有 TrayIcons 与 LauncherService 的目录/图标资源。Runtime 的 ports 指向其稳定字段，stop 顺序按启动的反序执行。
- `app/WindowHost.zig` 持有主 HWND、监视器几何/DPI 与 AppBar 注册；它负责初始化/更新 bounds、AppBar claim/release、窗口销毁和 message loop。窗口 callback/context 的接口仍由主 UI 线程组装。
- 各 Feature Controller 继续拥有业务状态；`PaintContext` 只保留 App/Shell 的 UI 汇总、最近呈现布局与非拥有的 Feature/Platform 引用，不替代 worker snapshot 或 Feature Controller。主循环的 Win32 输入桥接仍在 `main.zig`，后续只按清晰边界迁移，不复制旧新两套事件路径。
- `WIN-LIFECYCLE-001`、`WIN-UI-001`、`WIN-INPUT-001`、`WIN-DPI-001` 和 `WIN-PERF-001` 的 Windows 原生验证仍为 `MANUAL_PENDING`。
