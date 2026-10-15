# IslandBar 架构重构 — 最终实施报告

日期：2026-10-15  
执行计划：`IslandBar-Codex-Goal-Complete-Refactor-V2.md`  
架构依据：`docs/IslandBar-Architecture-V1.md`（状态保持 `PROPOSED`）

## 结果

**状态：`IMPLEMENTATION_COMPLETE_MANUAL_PENDING`。** Tracker 中 S0-001 至 S5-003 共 20/20 步骤均已实施，自动验证在当前 Windows/Zig 环境完成。Windows 原生 UI、设备和安装器人工验收尚未执行，因此不代表 GUI 已验证或可发布。

Codex Goal 名称为 **IslandBar Architecture Refactor**；完整 20 步队列与三类验证状态见 [GOAL-TRACKER.md](GOAL-TRACKER.md)。每一步的改动、原因、命令/退出码和回退方式追加在仓库根 [AGENTS.md](../../AGENTS.md)。

## 架构成果

- Shell 展示优先级由 `src/shell/PresentationPolicy.zig` 单点决定；布局绘制与命中共享成功呈现的 LayoutSnapshot，输入事件带 ElementId、frame generation 和 feature data generation。
- Feature 路径已覆盖 Sound、Music/Lyrics、Launcher、Tray、Notification、Taskbar/Thumbnail、System 和 Weather；各自的 Controller/UI、平台值契约和 Windows adapter 按职责归位。通用 Renderer/TextRenderer 不导入 Feature 实现。
- D2D 绘制与设备丢失恢复有明确生命周期；Feature 页面布局/Action 逐步离开旧 Renderer、TextRenderer 和 Core 专属分支。旧 `TaskStripLayout` 已由通用 `BarControlLayout` 与 Feature Taskbar UI 取代。
- `src/app/Runtime.zig` 拥有 Windows 后台服务和托盘/Launcher 资源并逆序停止；`src/app/WindowHost.zig` 拥有主 HWND、DPI/bounds、AppBar 和消息循环宿主；Win32 `IslandWindow` 已归入 `src/platform/windows/`。
- 可选 `ISLANDBAR_TRACE_UI=1` 日志可串起 Sound slider 的元素/布局、Action、Sound Controller token、平台 HRESULT/迟到结果、快照 revision 与 Renderer generation。默认关闭，无堆分配。
- 静态历史边从最初 21 条逐阶段收敛，目前只保留 `Renderer → WicImage` 和 `TextRenderer → WicImage` 两条。它们仍负责 WIC PNG 解码/编码/模糊处理及 D2D bitmap cache 输入；WIC COM 接口没有传出 adapter。两条理由已登记，不为清空白名单创建过度抽象。
- 现存 `PaintContext` 与主窗口 callback 仍承担 App UI 线程上的 Feature 连接和 Win32 输入适配。Runtime/WindowHost 已把 worker 与窗口生命周期移出入口；继续拆分回调应保持唯一状态权威和单条输入路径。

## 最终自动验证

执行环境：Windows 10 X64；Zig 0.17.0；进程级 `ZIG_LIB_DIR=C:\Software\Loadout\store\zig\0.17.0\lib`。最终代码缓存为 `.zig-cache-s5-003`。

| 命令 | 结果 |
| --- | --- |
| `zig build --cache-dir .zig-cache-s5-003 --summary all` | 退出码 0；16/16 steps，IslandBar、安装器及全部 smoke/probe targets 成功 |
| `zig build test --cache-dir .zig-cache-s5-003 --summary all` | 退出码 0；91/91 build steps、88/88 tests 通过 |
| `zig fmt --check build.zig src` | 退出码 0 |
| `python tools/architecture/check_boundaries.py --report`（bundled Python runtime） | 退出码 0；2 条登记 WIC 边、0 新增、0 未解析 |
| `git diff --check` | 退出码 0；仅报告仓库 CRLF 转换提示 |

无 `ENV_UNAVAILABLE`，无 `BUILD_PENDING`。S5-001/S5-002 首次测试运行各出现一次 Zig 标准库文件读取 `Unexpected`；同缓存重跑均通过。它不是源码错误，也未被记作环境缺失。实际构建中发现的窗口指针类型和显式模块绑定错误都已修复并重跑通过。

## 维护性边界检查

| 维护任务 | 首要改动范围 | 预期影响 |
| --- | --- | --- |
| Music 页面样式/排版 | `src/features/music/ui/Page.zig`；缺少通用绘制原语时才扩展 `src/ui/TextRenderer.zig` | Music Controller、GSMTC service、其他 Feature 不应变化 |
| Sound 页面布局 | `src/features/sound/ui/Page.zig`、`MixerSlider.zig`；必要时使用通用 `src/ui/Slider.zig` | Sound Controller/Core Audio service 保持不变；页面布局测试应覆盖 hit 与绘制共用 snapshot |
| Shell 卡片优先级 | `src/shell/PresentationPolicy.zig` 及其纯逻辑测试 | 不修改 Feature 页面绘制和 Windows adapter |
| 媒体平台实现 | `src/platform/windows/MediaService.zig`、`LyricsService.zig`；仅公共值形状变化时调整 `platform/contracts/` | 不修改 Music UI 或其他 Feature 私有代码 |
| 音频平台实现 | `src/platform/windows/AudioService.zig`、`AudioVolume.zig`；仅公共 snapshot/result 变化时更新 `SoundAudio` | 不修改 Sound 页面布局；Controller 继续验证 token/generation |

以上是按 `build.zig` 显式模块依赖与目录 owner 执行的静态维护性验收记录，不伪称曾为本次架构任务制造临时产品视觉改动。所有模块和回归用例仍可通过最终完整构建/测试命令验证。

## Windows 人工验收

所有 20 个项目集中在 [WINDOWS-MANUAL-TESTS.md](WINDOWS-MANUAL-TESTS.md)，状态均为 `MANUAL_PENDING`。重点包括：

- `WIN-UI-001`、`WIN-INPUT-001`、`WIN-DPI-001`：原 UI 截图、动画中点击、负坐标和 100/125/150% DPI、多显示器。
- `WIN-GFX-001`、`WIN-LIFECYCLE-001`、`WIN-PERF-001`：D2D/DComp/Device Lost、窗口关闭/重启、迟到事件及长时间资源/帧趋势。
- `WIN-SOUND-001/002`、`WIN-MUSIC-001`、`WIN-TRAY-001`、`WIN-NOTIFY-001`、`WIN-TASKBAR-001`、`WIN-LAUNCHER-001`：真实系统设备、播放器、托盘、通知、窗口和输入交互。
- `WIN-SYSTEM-001`、`WIN-WEATHER-001`：权限、无线/亮度/状态刷新、网络失败与恢复。
- `WIN-SETUP-001`：在可恢复 VM 中实测安装/卸载；本轮只验证安装器构建。

本轮没有启动 IslandBar GUI、执行电源操作、修改系统无线/亮度/音频状态或运行真实安装器。

## 回退

每一实施步骤都在 `AGENTS.md` 有单独回退说明。单步回退只撤销对应文件、build wiring 和该步文档增量；禁止 reset 整个工作区。架构文档状态不变。
