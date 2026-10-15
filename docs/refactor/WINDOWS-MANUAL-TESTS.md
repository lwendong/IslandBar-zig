# IslandBar Windows 实机人工验收

状态只在真实 Windows 桌面/设备实测后改为 `PASS` 或 `FAIL`。自动构建、几何测试和静态检查只记在“自动替代验证”，不得代替实机结论。执行前使用本轮 `island/zig-out/bin/IslandBar.exe`；安装器检查仅在隔离测试环境进行。所有项目初始状态均为 `MANUAL_PENDING`。

## Shell、窗口与输入

### WIN-SHELL-001 — 卡片优先级与展示状态

- 关联步骤：S1-002、S4-004、S5-001
- 准备：构建本轮程序；准备可显示的 Music、Notification、System 卡片触发条件。
- 操作：依次打开各卡片；在动画中快速反向开合；让通知出现并消失；观察恢复到的卡片。
- 预期：优先级、关闭和恢复行为与重构前一致，无闪烁、卡片丢失或错误抢占。
- 风险：仅交互回归；不触发系统设置或电源动作。
- 自动替代验证：PresentationPolicy 的纯状态序列测试（实施后记录测试名与结果）。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-WINDOW-001 — 收起、悬停、展开、焦点与全屏

- 关联步骤：S2-001、S2-003、S5-001
- 准备：桌面有普通窗口和全屏应用。
- 操作：收起 IslandBar，悬停并展开；切换焦点；在全屏前后台重复操作；等待自动收起。
- 预期：窗口状态、焦点和自动收起行为保持一致，无失焦卡死。
- 风险：可能打断前台工作；先保存其他应用内容。
- 自动替代验证：窗口/状态转换纯逻辑测试（实施后记录）。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-INPUT-001 — 动画中点击与单次 Action

- 关联步骤：S2-002、S2-003、S3-002、S4-005、S4-006
- 准备：打开带按钮、滑块或任务按钮的页面。
- 操作：在展开/收起动画中点击目标边缘、重叠区、裁剪边缘和空隙；在可拖滑块处按下、移动、释放。
- 预期：命中最近已呈现帧的可见目标；空隙/裁剪外不命中；一次手势只触发一次 Action。
- 风险：任务栏按钮可能激活或关闭目标窗口；仅选可安全恢复的测试窗口。
- 自动替代验证：LayoutSnapshot 7/7、InputRouter 6/6、SoundPage 4/4 与 TaskbarPage 同一呈现按钮 bounds 的绘制/命中/hover-gap 测试通过，覆盖 surface/content 裁剪、按钮/行/滑块/滚动条命中、frame generation、press/drag/release、数据代际变化时取消捕获、空隙、disabled、零尺寸、越界和快速取消；真实动画点击仍待实测。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-DPI-001 — DPI、负坐标与多显示器

- 关联步骤：S2-002、S2-003、S4-002、S4-005、S4-006
- 准备：至少两台显示器，或使用 Windows 显示设置模拟不同缩放；保存显示设置。
- 操作：测试 100%、125%、150% 缩放；将副屏置于主屏左侧/上方；在显示器间切换或断开再连接；点击控件并观察裁剪和窗口位置。
- 预期：DIP/像素/屏幕坐标转换正确，负坐标正常，窗口、绘制和命中同步。
- 风险：显示设置变化会移动窗口；测试后恢复原布局。
- 自动替代验证：LayoutSnapshot `screen pixels map to client DIPs on negative-origin high-DPI displays` 通过；覆盖 125% 比例和负显示器原点，不替代 100/150% 与多屏实测。
- 状态：MANUAL_PENDING；实测者/日期/证据：

## 绘制与 UI

### WIN-LAYOUT-001 — Sound mixer slider 同帧布局、裁剪与命中

- 关联步骤：S2-002、S2-003、S3-002
- 准备：使用本轮调试构建，打开 Sound 页面；至少准备一个主音量/应用音量滑块并记录原值。
- 操作：在页面展开动画期间点击滑块中心；滚动到应用音量行后按下拖动；在轨道边界、行间隙、视口裁剪边缘及 reveal 动画裁剪边缘点击；测试设备更新后再次拖动。
- 预期：滑块绘制与命中跟随最后成功呈现帧；裁剪外/空隙不命中；失败绘制不会让输入使用未呈现的下一帧坐标；音量值和目标应用与原有行为一致。
- 风险：会改变音量；先记原值并在结束后恢复。不要拔除系统必需音频设备。
- 自动替代验证：LayoutSnapshot 7/7 + InputRouter 6/6 + SoundPage 4/4；全量 `zig build test --summary all` 45/45 通过。测试覆盖同一布局快照生成绘制 Bounds/命中元素、Sound device/default selection、volume mapping、topology generation 变更后拒绝旧 session、滚动条 hit、reveal/content clip 与失败帧保留；无 Windows GPU/音频硬件行为结论。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-GFX-001 — D2D/DWrite/DComp 重绘与设备恢复

- 关联步骤：S2-001、S2-004、S5-002
- 准备：使用本轮调试构建；准备常用页面状态并记录当前窗口与 GPU 工作状态；不人为重启显卡驱动。
- 操作：反复调整窗口尺寸、最小化/还原、改变 DPI 与显示器；检查 Music/Sound/Notification 页面状态是否保留。只有在隔离 VM 且项目存在安全受控场景时，才额外触发一次 D2D target/device loss 并记录错误码、重建次数和页面状态。
- 预期：无残留 clip、黑屏或资源持续增长；普通显示器变化后重建 renderer；device-loss 恢复若可安全触发，应重建图形缓存并保留业务 snapshots。
- 风险：驱动/设备故障可能影响整台机器；没有隔离 VM 或受控触发方式时跳过故障触发部分并维持 `MANUAL_PENDING`，不可伪造通过。
- 自动替代验证：`zig build test --summary all` 的 DrawLifecycle 状态/设备丢失 HRESULT 分类测试；依赖完整 build 检查错误路径和资源绑定，均不能替代真实 GPU 重建。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-UI-001 — 原有视觉与页面布局回归

- 关联步骤：S2-004、S3-002、S4-001 至 S4-007、S5-002
- 准备：相同分辨率、缩放、主题、窗口和数据条件下保存重构前后截图。
- 操作：逐页查看 Shell、Music、Sound、Launcher、Tray、Notification、Taskbar、System、Weather 的颜色、字体、尺寸、间距、位置、圆角和动画；在 Sound 页面观察主/应用混音滑块的 0%、中间、100% 与静音外观，并循环内置主题。
- 预期：未授权的视觉或交互变化为零；差异若由已确认缺陷修复引起，附前后说明。
- 风险：无系统副作用。
- 自动替代验证：Theme parse/smoke、ThemeTokens、Slider、MixerSlider 与各 Feature Page 的纯值/绘制相关测试包含在当前 86 个通过用例中；Renderer/TextRenderer 无 Feature imports，IslandWindow 已归入 Windows Platform；代码保留原轨道高度 4 DIP、圆角 2 DIP、thumb 半径 6 DIP、主题 alpha 合成与同帧 Bounds。不能替代截图对比、动画实测和真实 D2D/WIC 绘制。
- 状态：MANUAL_PENDING；实测者/日期/证据：

## Feature 与系统适配器

### WIN-ICON-001 — 应用图标提取、缓存与进程重用

- 关联步骤：S1-003、S3-001、S4-001、S4-004、S4-005
- 准备：使用本轮构建；准备至少两个能显示应用图标的应用，并记录其 executable path、PID 和任务管理器 GDI object 数。
- 操作：查看 Music、Sound 应用会话、Notification/WeChat 来电和任务窗口图标；关闭一个应用再启动另一个；如 Windows 自然重用了 PID，确认路径变化后图标更新；可重复切换并记录 GDI object 数。不要通过修改应用或伪造系统 PID 制造复用。
- 预期：图标与 executable 对应；同一 PID 路径改变时不沿用旧图标；无图标/不可访问进程只缺少图标，不影响页面；反复刷新后 GDI object 不持续增长。
- 风险：需启动/退出测试应用；仅使用可安全恢复的程序，结束时恢复原运行状态。
- 自动替代验证：`zig build test --summary all` 包含当前进程 Shell icon PNG 提取、输入边界、SoundOutput 的 PID+路径 cache hit/刷新，以及 Taskbar WindowId/HWND/PID/process-created-time 身份比较；Renderer 图标缓存按稳定窗口实例键匹配并在实例退出/替换后清理；不能替代真实页面和 GDI 趋势检查。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-TASKBAR-001 — 窗口列表、稳定命中与 DWM 缩略图

- 关联步骤：S4-005、S5-002
- 准备：使用本轮 `island/zig-out/bin/IslandBar.exe`；打开至少三个可安全恢复的普通窗口，并记录活动窗口。
- 操作：打开/关闭窗口以触发列表增删和重排；分别点击非前台窗口与前台窗口；悬停任务按钮等待预览出现，再移开指针；在卡片展开、动画反向、屏幕边缘和多显示器/DPI 环境重复；关闭一个窗口后立即将新窗口打开并观察预览/图标目标。
- 预期：激活/最小化始终作用于按钮所表示的那个窗口；新列表或动画中的绘制与命中保持同一几何；已消失/重用 HWND 的请求不作用于新窗口；过期预览隐藏；DWM 预览卡片约束在当前显示器范围内。
- 风险：任务按钮会切换前台或最小化窗口；仅使用可安全恢复的测试程序，测试后恢复前台状态。只通过正常开关应用观察句柄复用，不伪造 HWND/PID。
- 自动替代验证：TaskbarPage 用同一呈现 bounds 做绘制数据、hit 和 gap hover；Controller 覆盖稳定 ID、重排动画、消失清 hover 和过期 revision 拒绝；WindowList 覆盖 HWND+PID+进程创建时间实例比较，缩略图入口按当前目录 revision 复核实例；`ThumbnailLayout` 覆盖纵横比和显示器边界。均不能替代真实 DWM/窗口管理器行为。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-SOUND-001 — 主音量、静音和输出设备

- 关联步骤：S3-001、S3-002、S4-006
- 准备：准备可恢复的音量值和至少一个输出设备。
- 操作：打开 Sound 页面，改变主音量、切换静音、选择输出设备，然后恢复原值/设备。
- 预期：滑块显示与系统确认值一致；错误时有局部反馈，页面仍可操作。
- 风险：测试会改变播放音量；控制在安全音量并在结束时恢复。
- 自动替代验证：SoundController 纯 Zig tests 9/9、SoundPage 4/4 通过。ViewModel 明确区分 confirmed/displayed/pending 音量值，快照 Action 检查 topology generation；覆盖无设备拒绝、重复动作抑制、服务失败保留 HRESULT、5 秒超时、迟到 token 忽略和乐观状态回退；这些测试不代替真实设备或 UI 行为。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-SOUND-002 — 应用音量与设备变化

- 关联步骤：S3-001、S3-002
- 准备：一个正在播放声音的测试应用；可选备用音频设备。
- 操作：调整该应用音量；切换默认设备；在安全条件下拔插可热插拔设备；关闭测试应用后再观察页面。
- 预期：会话身份不串用；过期/消失设备不再接受操作；错误不会卡住 UI。
- 风险：音频短暂中断；不要拔除系统必需设备。
- 自动替代验证：SoundController 测试覆盖设备拓扑变化后拒绝旧 PID/generation、失败 HRESULT、迟到结果、快速连续 session drag 与 supersede 清理；SoundAudio 纯值 snapshot 通过；InputRouter 6/6 在数据代际变化时取消原行拖动；SoundPage 4/4 测试设备选择和音量映射。热插拔、真实进程关闭和 Core Audio 会话时序仍需实机验证。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-MUSIC-001 — GSMTC 播放、切歌、歌词和会话变化

- 关联步骤：S4-001
- 准备：使用支持系统媒体会话的播放器和测试媒体。
- 操作：播放/暂停、上一首/下一首，查看封面/歌词；切换或关闭播放器，再启动另一会话。
- 预期：控制目标对应当前会话；封面/歌词随会话更新，过期结果不覆盖新内容。
- 风险：会控制当前播放器；仅使用测试媒体。
- 自动替代验证：`zig build test --summary all` 退出码 0（41/41 build steps，52/52 tests）；覆盖 MusicController 迟到歌词 generation 丢弃、歌词解析、LyricsService worker 启停、MediaService 媒体状态/位置映射与封面重试策略、MusicPage 布局和成功帧命中。`zig build --summary all` 退出码 0（16/16 steps）。这不替代真实播放器/GSMTC/音频设备或 GUI 验收。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-LAUNCHER-001 — 启动菜单命中、滚动与启动失败

- 关联步骤：S4-002
- 准备：Launcher 中有可安全启动的应用。
- 操作：点击一个可安全启动的固定图标中心，再点击网格水平/垂直间隙；打开 Apps 列表并滚动，分别点击裁剪区内外的行；对可安全测试目标快速连点同一图标；启动一个安全应用；在不实际执行危险命令的前提下验证失效/拒绝目标的错误响应。
- 预期：只有可见有效图标响应；网格间隙和裁剪外不响应；同一呈现帧重复点击最多启动一次；启动失败保留 Launcher 页面并报告 ShellExecute 错误码，成功后按原规则关闭页面；DPI 或显示器变化后仍命中可见图标。
- 风险：应用会启动；选择无副作用测试应用。
- 自动替代验证：`LauncherPage` 2 项几何/Action 测试（网格 gap 不命中、裁剪外不命中），`LauncherController` 2 项测试（启动失败保留状态及错误码、同一呈现帧拒绝重复启动）；全量 `zig build test --summary all` 56/56 tests passed，`zig build --summary all` 16/16 steps succeeded。未做真实 Win32 点击或启动。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-TRAY-001 — 系统托盘列表与菜单

- 关联步骤：S4-003
- 准备：使用本轮 `island/zig-out/bin/IslandBar.exe`；准备普通托盘图标，优先包含同一 exe 的两个实例；记录安全可重启应用的 PID 与窗口。
- 操作：打开托盘页并观察刷新；悬停/点选图标、使用无副作用菜单项；在目标窗口关闭或进程重启后再次操作旧菜单；若能构造两个同 UID 且对应不同托盘位置的旧式注册，确认操作被拒；核对“关闭窗口”只关闭所选 HWND，“退出应用”仍需连续二次确认。
- 预期：菜单只作用于打开菜单时选中的 PID/HWND/进程创建时间和完整 exe 路径；目录代际更新后旧选择失效；无法唯一解析的旧 UID 不会误点别的图标；页面布局、hover、字号和菜单交互保持原样。
- 风险：关闭/退出可能结束应用；仅对安全可重启测试程序执行，避免系统托盘程序或未保存工作。
- 自动替代验证：`TrayCatalog` 1/1 覆盖目录代际/索引/注册值身份；`TrayController` 3/3 覆盖目录更新失效、退出二次确认和窗口实例保留；`TrayPage` 1/1 覆盖同一剪裁布局的 hit/action；`TrayPress` 1/1 覆盖多个托盘窗口位置歧义拒绝。完整纯 Zig suite 62/62；不能替代真实 shell/UI 操作。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-NOTIFY-001 — 通知来源、去重、抢占和恢复

- 关联步骤：S1-002、S4-004
- 准备：使用本轮 `island/zig-out/bin/IslandBar.exe`；准备安全的通知发送端，并在本机已有微信时使用测试账号/窗口；记录来源与到达顺序。
- 操作：确认现有 JSON `app/title/body/icon/urgency/sticky` 字段可接收；快速发送同来源身份重复消息、不同来源的同内容消息和连续新消息；打开历史并点通知标记已读；撤销 WeChat call source；让通知抢占 Music/System 页面后等待超时；测试有效、缺失和空图标路径。
- 预期：Pipe 字段兼容；未读的同 source/key 去重，不同来源互不吞并；撤销只结束匹配来源；短通知过期后恢复原 Shell 卡片；来源/图标失败不使 Shell 无响应；原字号、间距和动画保持。
- 风险：通知会打断当前内容；避免向真实用户发消息或结束真实通话。
- 自动替代验证：`zig build test --summary all` 63/63 build steps、67/67 tests；覆盖 JSON wire、Feature Store source-key 去重/撤销、通知卡片原几何、WeChat call 转换。`zig build --summary all` 16/16 steps；不替代真实 Windows Toast/Pipe/微信窗口/GPU 呈现。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-SYSTEM-001 — 系统状态、权限与亮度

- 关联步骤：S4-006
- 准备：使用本轮构建；记下显示亮度、Wi-Fi、蓝牙、夜间模式和实时字幕原状态。确保能本地恢复网络，远程桌面期间不要切换无线状态。
- 操作：打开 SystemPanel，检查分页、网络/蓝牙/电池/输入法状态和外观名称；在支持 DDC/CI 的外接屏上拖动亮度后观察读回值。再使用无亮度能力的内置/外接屏确认亮度控件局部隐藏。仅在可安全恢复的环境中切换 Wi-Fi、蓝牙、夜间模式和实时字幕并还原。测试设置入口；Win+P 仅打开投影选择面板后按 Escape 取消。可在系统拒绝/能力不可用的状态下观察错误恢复。
- 预期：原有按钮顺序、中文文案、每页数量、滑块样式和交互不变；能力缺失只隐藏亮度滑块，面板其他功能可用。系统拒绝请求时状态不乐观翻转，确认后的真实状态才更新；失败不使面板或 IslandBar 退出。
- 风险：亮度、无线、夜间模式和字幕会改变系统状态，开始前保存并在结束时恢复。不要测试关机、重启、注销或其他电源动作；不要在远程会话切断其网络。
- 自动替代验证：`SystemPage` 3 tests 覆盖 tile 顺序/分页、键盘标签与电池能力显隐、亮度能力局部降级；`SystemLayout` 1 test 覆盖 tile/slider hit 共用 bounds 与 tile gap；`SystemController` 2 tests 覆盖状态所有权、只在确认写入后更新亮度；完整纯 Zig 单测和 Windows build 结果记录于 S4-006 台账。它们不能替代系统开关、权限、DDC/CI、UI 动画和真实设备检查。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-WEATHER-001 — 天气刷新、缓存和弱网

- 关联步骤：S4-007
- 准备：使用本轮 Windows 构建；确认网络可用，记录天气值与刷新时间。弱网测试只在可恢复的测试网络执行，不改系统代理或防火墙。
- 操作：冷启动观察首次读取；运行至少 16 分钟观察 15 分钟轮询；在测试配置中于请求期间修改 `weather.txt` 城市；可恢复断网触发重试后恢复网络；使用测试响应分别缺少温度/天气码字段或返回非有限温度；断网超过 30 分钟后观察缓存和恢复。
- 预期：首查后按 15 分钟节奏刷新，失败按 1 分钟重试；失败与缺字段保留最后成功值，Controller 标记缓存或陈旧；旧 revision 和配置变化期间返回的旧城市结果不能覆盖新状态；无数据时仅天气段为空，时钟、其他 Feature 和窗口仍正常；标签、摄氏度四舍五入、位置、字体和图标保持原样。
- 收尾：恢复 `weather.txt` 原内容和网络状态，重新启动一次确认现配置可读取。
- 风险：请求外部天气服务；弱网测试仅在可恢复环境进行。
- 自动替代验证：`WeatherService` CSV 缺字段/非有限值测试；`WeatherController` 新旧 revision、失败保留 last-good、30 分钟 freshness 测试；`WeatherPage` 文案/温度/未知代码展示测试。不能替代 WinHTTP、系统位置权限、断网重试与屏幕实测。
- 状态：MANUAL_PENDING；实测者/日期/证据：

## 生命周期、发布与稳定性

### WIN-LIFECYCLE-001 — 启动、关闭与后台迟到结果

- 关联步骤：S2-001、S3-001、S5-001
- 准备：使用调试构建，打开多个 Feature 页面。
- 操作：正常关闭应用；在后台操作正在进行时关闭页面/进程；重复启动和退出数次。
- 预期：无崩溃、COM/图形资源异常、悬挂窗口或退出后回调访问已释放对象。
- 风险：保存其他应用工作；仅关闭 IslandBar 测试进程。
- 自动替代验证：`AppRuntime.Runtime.stop` 按显式逆序停止服务并释放 Tray/Launcher；`WindowHost.destroy` 清理窗口与 AppBar；Zig 0.17.0 `zig build --cache-dir .zig-cache-s5-001 --summary all` 16/16、`zig build test --cache-dir .zig-cache-s5-001 --summary all` 91/91 build steps（86/86 tests）、格式和依赖守卫通过。静态调用顺序和自动构建不能替代 COM/GPU 运行时回调、迟到消息、真实 HWND/AppBar teardown 或重复启动/关闭实测。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-PERF-001 — 长时间运行与帧/资源趋势

- 关联步骤：S2-001、S2-004、S5-003
- 准备：记录应用启动时内存、句柄、GPU 占用和帧响应基线。
- 操作：运行至少 30 分钟；期间切换页面、动画、音乐/通知；记录相同指标并检查日志。
- 预期：无持续单调增长、明显卡顿或 UI 线程系统调用阻塞；诊断默认关闭时开销可忽略。
- 风险：无预期系统副作用；长时间运行可能影响电池。
- 自动替代验证：Slider/ViewModel/Canvas 无堆分配且复用同帧布局；`zig build test --summary all`、`zig build --summary all` 成功。无法替代长时间帧响应、内存/句柄/GPU 资源趋势测量。
- 状态：MANUAL_PENDING；实测者/日期/证据：

### WIN-SETUP-001 — 安装器真实运行

- 关联步骤：S0-001、S5-002、S5-003
- 准备：仅使用可恢复虚拟机/测试账户；构建本轮 `IslandBarSetup.exe`；建立快照。
- 操作：在测试 VM 安装、启动、升级（如有）并卸载；记录文件和快捷方式变化。
- 预期：发布入口、资源、可执行文件名和安装/卸载行为保持兼容。
- 风险：会写入系统；禁止在日常机器未经备份安装或覆盖。
- 自动替代验证：`zig build setup-build` 仅验证编译，不能替代安装实测。
- 状态：MANUAL_PENDING；实测者/日期/证据：

## 记录状态

本清单共 20 个唯一项目；截至 `2026-10-15` 均为 `MANUAL_PENDING`，尚无原生 GUI/设备项目被 Codex 执行或标为通过。实际执行后逐项填写实测者、日期、证据路径和结果；失败需关联修复步骤，不得把人工失败改写为环境缺失。
