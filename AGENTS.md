# IslandBar — 开发与重构进度

此文件是**进度台账**，目标架构以 `docs/IslandBar-Architecture-V1.md` 为准（原文仍为 **PROPOSED**）。不要把计划视为已实现代码。

## 必须执行的约束

1. 采用渐进重构。一次只改一个明确边界；未经明确批准不得批量搬迁、删除或重写既有模块。
2. 永远保留现有 Zig + Win32 + D2D/DWrite/DComp 技术路线、安装器、smoke/probe 构建目标和当前 UI 外观/交互。
3. 状态、资源、布局几何由单一权威持有。UI 通用层不新增 Feature 依赖；Feature 不新增对其他 Feature 私有文件或 Windows 实现的依赖。
4. 不创建无必要的全局 EventBus、可写万能 Context、动态插件宿主或过度抽象。
5. 每一阶段交付：改动文件、原因、验证命令与输出、Windows 实测、遗留风险、回退步骤。如无法验证，明确写“未验证”，不可写“通过”。
6. 工作开始前阅读此文件和架构文档；完成后**追加更新**，不要抹除历史记录。除非获得批准，不得自行改变架构文档状态。

## 当前进度（2026-10-15）

| 阶段 | 状态 | 进展/阻塞 |
| --- | --- | --- |
| 0. 构建与回归基线 | 自动基线已完成；实机 **MANUAL_PENDING** | Zig 构建、静态依赖守卫通过；GUI 实测列入统一清单，不阻塞后续 |
| 1. 所有权与模块契约 | 自动实施已完成；实机 **MANUAL_PENDING** | 状态、策略、图标契约已实施并有自动回归 |
| 2. 高风险修复与 UI 底座 | 自动实施已完成；实机 **MANUAL_PENDING** | 绘制生命周期、布局快照、输入路由和 UI foundation 已实施 |
| 3. SoundPage 试点 | 自动实施已完成；实机 **MANUAL_PENDING** | Sound controller/service/page 边界与测试已实施 |
| 4. 其他 Feature 迁移 | 自动实施已完成；实机 **MANUAL_PENDING** | Music、Launcher、Tray、Notification、Taskbar、System、Weather 均已按边界迁移 |
| 5. 清理旧架构与规则固化 | 自动实施已完成；Windows 实测 **MANUAL_PENDING** | 20/20 重构步骤均已实施并记录自动验证；人工验收汇总在 `docs/refactor/WINDOWS-MANUAL-TESTS.md` |

## 目录约定（2026-10-15）

- 仓库根保留 `AGENTS.md`、`.git/`、`.gitignore`、`.vscode/` 和原有 `.zig-*` 目录。
- `island/` 是代码根，包含 `build.zig`、`src/`、`setup/`、`res/`、`tools/`、工具链脚本及 `zig-out/`。从该目录运行 `zig build` 和 `python tools/architecture/check_boundaries.py --report`。
- `docs/` 集中存放设计与进度文档、开始页、截图和补丁归档。架构文档中的源代码路径相对于 `island/`。
- S0-001 原记录中的无前缀 `src/`、`tools/` 等路径对应目录整理前布局；当前路径分别为 `island/src/`、`island/tools/`。

## 本次变更记录 — S0-001

- **目标：** 锁定依赖债务和回归基线；避免后续重构引入更多越界引用。
- **新增：** `tools/architecture/check_boundaries.py`、`tools/architecture/legacy-dependencies.json`、`docs/REFACTOR-BASELINE.md`、架构文档工作副本。
- **更新：** `AGENTS.md`（将原 `111` 占位内容更新为进度台账）。
- **生产代码改动：** 无；`src/`、`build.zig`、`setup/` 未修改。
- **已验证：** 在离线静态分析环境执行依赖脚本，当前 21 条旧违规、0 条新增、0 个未解析的 import；注入新增越界 import 的负向测试被正确拒绝。
- **未验证：** 本机没有 Zig；Windows `zig build`、安装器 build、启动运行、UI 和多 DPI 操作均待原生环境验收。
- **回退：** 删除以上新增脚本、JSON、基线文档；恢复先前的 `AGENTS.md` 即可。生产代码无需回退。

## 历史执行说明 — S0-001 当时的 Windows 复核

> 以下是 S0-001 时期的待办记录，已由后续 S1–S5 实施记录覆盖。当前 Goal 的 20 个代码步骤已完成；Windows 人工项目统一保持 `MANUAL_PENDING`，由 `docs/refactor/WINDOWS-MANUAL-TESTS.md` 后续集中验收，不阻止代码实施。

在 Windows 的 `island/` 代码目录执行 `zig version` 和各构建命令，再填写下面的实际结果。**不要跳过验证直接开始重写 main.zig 或 Renderer.zig。**

### Windows 验证日志（S0-001 复核补录，2026-10-15）

- 操作系统/架构：`Microsoft Windows 10.0.26220` / `X64`（`RuntimeInformation` 原始值）。
- Zig 版本：`0.17.0`；`zig version` 成功。Zig 安装在 `C:\Software\Loadout\store\zig\0.17.0`。默认沙箱首次执行七个构建目标各退出码 1，原始错误：`error: unable to find zig installation directory from executable path "C:\\Software\\Loadout\\store\\zig\\0.17.0\\zig.exe": FileNotFound`；进程内设置 `ZIG_LIB_DIR` 后，沙箱内 `zig env` 退出码 1，原始错误：`error: unable to open zig lib directory "C:\\Software\\Loadout\\store\\zig\\0.17.0\\lib": AccessDenied`。随后在获准访问工具链和 Windows SDK 的构建调用中，以进程级 `ZIG_LIB_DIR=C:\Software\Loadout\store\zig\0.17.0\lib` 重跑，构建目标均成功。
- `python tools/architecture/check_boundaries.py --report`：系统 `python` 命令解析到不可启动的 Microsoft Store alias；改用工作区 Python runtime 的完整路径执行同一脚本，退出码 0：21 条现存旧边、0 新增、0 删除、0 未解析。临时加入 `src/ui/Renderer.zig -> StartMenu` 后退出码 1 并报告新违规；测试后逐字节恢复原文件。
- 当前源码复核：41 个 Zig 文件、24,755 行、40 个命名源码模块；`main.zig` 3,991 行、`Renderer.zig` 1,503 行、`TextRenderer.zig` 2,493 行。工作区 `res.zip` SHA-256 与本基线来源一致；`src/`、`setup/`、`res/` 共 45 个文件与压缩包内容逐字节一致。
- `zig build`、`zig build setup-build`、`zig build native-smoke-build`、`zig build thumbprobe-build`、`zig build sysstatusprobe-build`、`zig build geoprobe-build`、`zig build gsmtcprobe-build`：在以上进程级 `ZIG_LIB_DIR` 设置下，各退出码均为 0。初次沙箱内的错误没有代表源码编译失败；最终结果来自可访问本机 Zig 库和 SDK 的重跑。
- 安装器/发布：`setup-build` 编译成功，没有运行安装器。整理后从 `island/` 重跑全部目标成功，生成路径为 `island/zig-out/bin/`。
- Windows UI 人工回归：Computer Use 原生桌面插件可用；尝试启动工作区 exe 后，工具未暴露可操作窗口，返回 `launched app did not expose a targetable window: C:\Users\viato\IslandBar\island_bar.exe`。窗口列表没有 IslandBar；没有进行点击交互。以下均为**未验证**：收起/悬停/展开、任务栏按钮、音乐、声音页面、托盘、通知、启动菜单、动画中点击、多 DPI/多显示器。未执行电源或窗口关闭操作。
- 当前待办：阶段 0 仅剩真实 Windows UI 人工回归未完成；完成前保持阶段 0，不进入阶段 1。
- 本轮未修改生产 Zig 源码、`build.zig`、安装器源文件、资源或 probe 入口。回退：删除本次追加的 S0-001 验证补录并恢复本次编辑前的 `AGENTS.md` 与 `docs/REFACTOR-BASELINE.md`；无需回退生产代码。

### 下阶段建议

先完成真实 Windows UI 回归以结束阶段 0。之后如获授权，阶段 1 从单一边界的 State/Action/Contract 只读盘点开始；可优先评估 `Renderer.nextCardOwner` 的职责归属，但本次未实施迁移。

### 后续变更记录模板

```text
编号 / 日期：
阶段 / 目标：
改动文件：
非改动范围：
编译与测试（命令 + 结果）：
Windows 实机回归（操作 + 结果）：
风险 / 未验证项：
回退方式：
下阶段建议：
```

## 本次变更记录 — DIR-001

- **目标：** 将代码与构建内容集中到 `island/`、文档集中到 `docs/`，同时保留根目录配置和 Zig 缓存。
- **移动：** `build.zig`、`src/`、`setup/`、`res/`、`tools/`、工具链脚本及 `zig-out/` 移入 `island/`；`START-HERE.txt`、阶段补丁包与截图归入 `docs/`。
- **根目录保留：** `AGENTS.md`、`.git/`、`.gitignore`、`.vscode/` 和原有 `.zig-*`。更新 `.gitignore` 与 VS Code 路径设置。
- **未移动/未恢复：** 整理开始时工作区不存在 `res.zip`，因此未移动或重建；此前 S0-001 对它的检查作为历史记录保留。
- **生产代码内容：** 仅移动，未重写或删除 Zig 源码、安装器、资源或 probe 目标。
- **验证：** 从 `island/` 执行 `python tools/architecture/check_boundaries.py --report`，退出码 0，21 条旧边、0 新增/移除/未解析；`zig build`、`setup-build`、五个 smoke/probe build 目标各退出码 0。产物位于 `island/zig-out/bin/`。UI 人工回归仍未验证，因 Computer Use 未返回 IslandBar 可操作窗口。
- **回退：** 将 `island/` 中的代码目录和文件移回根目录，将 `docs/START-HERE.txt`、`docs/patches/` 与 `docs/screenshots/` 中对应文件移回整理前位置，并恢复 `.gitignore`、`.vscode/settings.json` 与本节路径说明。

## V2 Goal 队列与执行约定（2026-10-15）

- Goal 名称：**IslandBar Architecture Refactor**。当前 Codex Goal 已激活，当前任务标题已同步命名；Goal API 不提供修改已激活 objective 的操作。完整 20 步队列及依赖记录在 `docs/refactor/GOAL-TRACKER.md`，按该队列连续实施。
- 授权范围：用户明确授权按 V2 对代码逐步实施，不需每步确认。采用单边界、逐步回退；保留 Zig/Win32/D2D/DWrite/DComp、安装器、smoke/probe、现有功能与 UI 外观。不得改变架构文档的 `PROPOSED` 状态。
- 状态规则：实施与验证状态分开。`IMPLEMENTED + AUTO_PASSED/AUTO_PARTIAL_ENV + MANUAL_PENDING` 可解锁下游。仅真实代码/接口问题可标 `BLOCKED_TECHNICAL`；缺失工具标 `ENV_UNAVAILABLE`，GUI/多显示器/设备实测标 `MANUAL_PENDING`。
- 统一 Windows 实机清单：`docs/refactor/WINDOWS-MANUAL-TESTS.md`。每一步引用测试 ID，不在此台账重复复制测试步骤。
- 代码实施基线：commit `a95646ede369445a819f9367e5b9a92aee7227ec`；开始时 `git status --short` 仅有用户提供的 `IslandBar-Codex-Goal-Complete-Refactor-V2.md` 未跟踪文件。保留该文件，不覆盖、不重置用户数据。
- 以下“GUI 完成前保持阶段 0”及“下一位执行者先完成 GUI”均为旧待办记录。用户的 V2 明确授权覆盖该门禁；其历史内容保留，但不再阻止后续实施。

## [S0-001] 最新源码、工具链与回归基线 — V2 复核

- 日期 / 分支 / 基线 commit：2026-10-15 / 分支名未另行确认 / `a95646ede369445a819f9367e5b9a92aee7227ec`。
- 实施状态：`IMPLEMENTED`。
- 自动验证状态：`AUTO_PASSED`；Zig `0.17.0`，依赖扫描及所有既有构建目标成功。沙箱首次工具链访问失败已按环境权限原因记录，获准访问 Zig 库与 Windows SDK 后同一目标重跑成功。
- Windows GUI 验证状态：`MANUAL_PENDING`；未获得 IslandBar 可操作原生窗口，未声称 GUI 通过。清单：`WIN-SHELL-001`、`WIN-WINDOW-001`、`WIN-INPUT-001`、`WIN-DPI-001`、`WIN-GFX-001`、`WIN-UI-001`、`WIN-SOUND-001/002`、`WIN-MUSIC-001`、`WIN-LAUNCHER-001`、`WIN-TRAY-001`、`WIN-NOTIFY-001`、`WIN-SYSTEM-001`、`WIN-WEATHER-001`、`WIN-LIFECYCLE-001`、`WIN-PERF-001`、`WIN-SETUP-001`。
- 允许改动范围 / 未改范围：复核阶段仅允许台账和测试文档；未修改生产 Zig、`build.zig`、setup、资源及 probes。
- 改动文件：`AGENTS.md`、`docs/refactor/GOAL-TRACKER.md`、`docs/refactor/WINDOWS-MANUAL-TESTS.md`。
- 基线 / 静态依赖：`python` 命令是不可启动的 Microsoft Store alias；改用 `C:\Users\viato\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe tools/architecture/check_boundaries.py --report`，退出码 0：21 条既存边、0 新增、0 移除、0 未解析。临时注入 `Renderer.zig -> StartMenu` 的负向验证退出码 1，报告该新增边；finally 恢复后文件逐字节一致。
- Zig / 构建命令与结果：`zig version` 输出 `0.17.0`。默认沙箱 `zig build` 首次错误为找不到 `C:\Software\Loadout\store\zig\0.17.0` 安装目录；设置进程级 `ZIG_LIB_DIR` 后仍因沙箱 `AccessDenied`。随后在获准访问本机 Zig 库和 Windows SDK 的构建调用中，`zig build`、`zig build setup-build`、`zig build native-smoke-build`、`zig build thumbprobe-build`、`zig build sysstatusprobe-build`、`zig build geoprobe-build`、`zig build gsmtcprobe-build` 各退出码 0。未运行安装器或有系统副作用的 probe。
- 单元测试：当前阶段没有新增测试；后续按步骤补纯 Zig 测试并执行。
- 环境不可执行项：系统 Python alias 无法启动，已由 bundled Python 替代；普通沙箱不能访问外部 Zig `lib` 和 Windows SDK，获准构建后完成全部构建目标。本地 Windows 原生 GUI 未被 Computer Use 暴露，记为人工待测，不归类为 `ENV_UNAVAILABLE`。
- Windows 人工编号：见上述清单，共同维护于 `docs/refactor/WINDOWS-MANUAL-TESTS.md`，当前均 `MANUAL_PENDING`。
- 风险：没有截图/桌面行为证据；构建通过不代表窗口、设备或安装流程通过。
- 回退点：本步骤没有生产代码改动；撤回本次步骤仅需还原 `AGENTS.md` 和删除本步骤新建的 `docs/refactor/GOAL-TRACKER.md`、`docs/refactor/WINDOWS-MANUAL-TESTS.md`。保留用户提供的 V2 文件。Git diff 可逐文件审阅。
- 下游任务解锁：是。S0 自动门槛通过；人工 GUI 未测不阻塞 S1。

### 后续执行状态

当时最早未完成步骤为 `S1-001`；该行保留为步骤完成时的进度说明。当前状态以追踪表及后续步骤记录为准。

## [S1-001] 编制所有权/依赖矩阵和最小公开契约

- 日期 / 分支 / 基线 commit：2026-10-15 / `main` / `a95646ede369445a819f9367e5b9a92aee7227ec`。
- 实施状态：`IMPLEMENTED`。
- 自动验证状态：`AUTO_PASSED`。
- Windows GUI 验证状态：`MANUAL_PENDING`（S1 的卡片优先级/快速操作实测见 `WIN-SHELL-001`；同帧绘制/布局与设备实测见 `WIN-UI-001`、`WIN-GFX-001`）。
- 允许改动范围 / 未修改行为：补齐当前所有权/依赖事实，给现有纯状态决策增加可执行单测入口；未改运行时逻辑、UI、视觉、Win32/COM/GPU 行为。
- 代码与契约：新增 `docs/refactor/OWNERSHIP.md`、`docs/refactor/DEPENDENCIES.md`；记录 `PaintContext` 当前聚合状态、服务 snapshot、渲染资源、线程和释放边界，并定义 Shell Presentation / typed Action / immutable Snapshot / Platform Port 的最小语义。当前 21 条 legacy imports 逐项记录归属任务与删除条件。
- 改动文件：`AGENTS.md`、`docs/refactor/GOAL-TRACKER.md`、`docs/refactor/OWNERSHIP.md`、`docs/refactor/DEPENDENCIES.md`、`docs/refactor/WINDOWS-MANUAL-TESTS.md`、`island/build.zig`、`island/src/core/StatePolicy.zig`。
- 已消除依赖 / 兼容桥：本步无生产依赖删除；明确 Shell 决策仍分别落在 `Renderer.nextCardOwner()` 与 `CardLayout.nextPanelLevel()`，计划由 S1-002 集中。`PaintContext`、`PillAppearance` 和旧页面分支保留作逐 Feature 迁移桥。
- Zig 版本与构建：Zig `0.17.0`。`zig build test --summary all` 退出码 0（Build Summary 3/3 steps succeeded；两个 StatePolicy tests 执行成功）；`zig build --summary all` 16/16 steps 成功；`zig build setup-build` 4/4；`zig build native-smoke-build`、`thumbprobe-build`、`sysstatusprobe-build`、`geoprobe-build`、`gsmtcprobe-build` 各 2/2，退出码均 0。
- 依赖边界检查：bundled Python 执行 `python tools/architecture/check_boundaries.py --report`：21 条旧边、0 新增、0 移除、0 未解析，退出码 0。`git diff --check` 退出码 0。此前的 S0 负向注入验证退出码 1 并确认 byte restore。
- 纯 Zig 测试：新增 StatePolicy 对 fullscreen/system panel/notification/music 优先级以及 expanded→resting 返回状态的用例；`zig build test --summary all` 实际运行通过。
- 环境不可执行项：系统 `python` 是不可启动的 Microsoft Store alias，改用 bundled Python；普通沙箱访问 Zig 安装目录和 Windows SDK 返回 `FileNotFound/AccessDenied`，获准的构建调用使用进程级 `ZIG_LIB_DIR` 后各目标成功。Windows 原生 GUI/多显示器/设备不在当前自动测试路径，统一 `MANUAL_PENDING`。
- Windows 人工编号：`WIN-SHELL-001`、`WIN-UI-001`、`WIN-GFX-001`（集中清单持续维护）。
- 资源/线程/输入/UI 风险：服务 snapshot 和 App 派生展示缓存要区分；SoundOutput 和 AudioVolume 分别拥有 per-app 与主音量 COM worker；renderer 设备在 UI 线程。当前仅静态所有权盘点，设备/线程 teardown 真实运行未验证。
- 回退点：仅还原本步骤的 `island/src/core/StatePolicy.zig` 与 `island/build.zig` 测试增量；删除本步骤新增的 `docs/refactor/OWNERSHIP.md`、`DEPENDENCIES.md`，并反向编辑 `AGENTS.md`/tracker 的 S1-001 条目。保留已完成的 S0 文档、用户 V2 计划和其他改动。
- 下游任务解锁：是；S1-002、S1-003、S2-001 依赖的 ownership/compile facts 已记录，人工实测不阻塞。

> 后续步骤开始：`S1-002`。现有卡片归属状态存于 `PaintContext`，策略分别在 Renderer 与 CardLayout；该步将只迁移 Shell 展示策略与类型权威，再接入 App 并保留渲染兼容边界。

## [S1-002] Shell 成为唯一卡片展示策略决策者

- 日期 / 分支 / 基线 commit：2026-10-15 / `main` / `a95646ede369445a819f9367e5b9a92aee7227ec`。
- 实施状态：`IMPLEMENTED`。
- 自动验证状态：`AUTO_PASSED`。
- Windows GUI 验证状态：`MANUAL_PENDING`；完整卡片抢占/恢复、反向动画和当前布局实测见 `WIN-SHELL-001`、`WIN-INPUT-001`、`WIN-UI-001`。
- 允许改动范围 / 未修改行为：只迁移卡片归属和子页优先级决策及类型；保留旧优先级、关闭保持、动画阶段命中和所有 UI 几何/颜色/字体/动画参数。未迁移页面绘制、窗口数量或 Feature 业务状态。
- 代码与架构变更：新增 `island/src/shell/PresentationPolicy.zig`，以纯值 `Facts` → `State` 计算唯一 `CardOwner`/`PanelLevel`；`PaintContext` 改持有一个 `PresentationPolicy.State`，绘制、点击和输入区域读同一状态。Renderer 不再有 `nextCardOwner`、`CardOwner` 或未使用的 `FrameState.card_owner`；Core/CardLayout 移除从属 `CardOwner`、`PanelLevel` 和控件点亮决策，仅保留几何。App 将控制点亮值作为既有 UI 展示参数传入。
- 改动文件：`AGENTS.md`、`docs/refactor/GOAL-TRACKER.md`、`docs/refactor/OWNERSHIP.md`、`docs/refactor/DEPENDENCIES.md`、`island/build.zig`、`island/src/app/main.zig`、`island/src/core/CardLayout.zig`、`island/src/ui/Renderer.zig`、`island/src/shell/PresentationPolicy.zig`。
- 已消除依赖 / 保留桥：Shell 展示策略不再定义在 Renderer 或 Core/CardLayout；`PresentationPolicy` 无 Feature/Windows import。依赖守卫扫描边仍为 21 条历史边，0 新增/移除；Renderer 现存 Feature imports 是 S4/S5 后续任务。App 暂时保存 Shell 状态和局部 Feature flags，后续按 Feature 迁移。
- Zig 版本与构建：Zig `0.17.0`。`zig build test --summary all` 退出码 0，5/5 steps succeeded、4/4 tests passed；`zig build --summary all` 退出码 0，16/16 steps succeeded，IslandBar 与安装器重新编译成功，已有 smoke/probe artifact 均保留并安装。
- 依赖边界 / 差异检查：bundled Python 的 `check_boundaries.py --report` 退出码 0：21 legacy forbidden edges、0 新增、0 移除、0 unresolved。`git diff --check` 退出码 0；未修改白名单。
- 自动状态测试：PresentationPolicy 覆盖 system panel > notification > music、tray > sound > start、关闭时保持/动画完成清空、关闭后快速反向切页和控件灯状态；先前 StatePolicy 测试也由同一 `zig build test` 运行。
- 环境不可执行项：Windows 原生 GUI、动画中真实点击、多显示器/DPI未实测，统一 `MANUAL_PENDING`；未尝试反复启动窗口。SDK/Zig 在普通沙箱不可读的情况已由获准构建解决，不存在本步 `ENV_UNAVAILABLE` 构建项。
- Windows 人工编号：`WIN-SHELL-001`、`WIN-INPUT-001`、`WIN-UI-001`。
- 资源/线程/输入/UI 风险：本步只改状态策略，保持 UI 线程调用和单帧调用时序；`FrameState.card_owner` 经仓库搜索无构造/读取调用方后移除。静态/自动测试不能证明 GUI 抢占时序与动画中命中表现，需执行上述人工项。
- 回退点：仅反向本步：恢复 `Renderer.zig` 的 `CardOwner`/旧策略和 `FrameState.card_owner`；恢复 `CardLayout.zig` 的 panel-level type/helpers；`main.zig` 从 `presentation.*` 还原原字段/调用；删除 `src/shell/PresentationPolicy.zig` 并撤销 `build.zig` 注册/测试入口。保留 S1-001 StatePolicy 测试和文档、S0 基线、用户 V2 文件。
- 下游任务解锁：是；S1-003、S2-001 可依赖稳定 Shell 纯策略，不需要等 GUI 手测。

> 当前最早未完成步骤：`S2-001`。状态与依赖队列见 `docs/refactor/GOAL-TRACKER.md`；Windows 手测仍集中在 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。

## [S1-003] 剥离跨 Feature 的应用图标能力

- 日期 / 分支 / 基线 commit：2026-10-15 / `main` / `a95646ede369445a819f9367e5b9a92aee7227ec`。
- 实施状态：`IMPLEMENTED`。
- 自动验证状态：`AUTO_PASSED`。Windows Shell/GDI API 的单元集成测试可在当前 Windows Zig/SDK 环境执行；用户界面及真实进程复用仍需人工验收。
- Windows 实机状态：`MANUAL_PENDING`，统一记录在 `docs/refactor/WINDOWS-MANUAL-TESTS.md` 的 `WIN-ICON-001`。不得把自动 PNG/API 测试当作 GUI、真实应用切换或 GDI 趋势验证。
- 目标与范围：将 Shell 文件图标提取从 MusicSession 私有实现移至 Windows `AppIconService`，通过窄 `FetchPngFn` 注入 Music、Sound、Notification 和 Renderer；不改现有 UI 视觉/交互，不删除功能、安装器或 probe。
- 改动文件：`AGENTS.md`、`docs/refactor/GOAL-TRACKER.md`、`docs/refactor/OWNERSHIP.md`、`docs/refactor/DEPENDENCIES.md`、`docs/refactor/WINDOWS-MANUAL-TESTS.md`、`island/build.zig`、`island/tools/architecture/legacy-dependencies.json`、`island/src/platform/contracts/AppIcon.zig`、`island/src/platform/windows/AppIconService.zig`、`island/src/features/MusicSession.zig`、`island/src/features/SoundOutput.zig`、`island/src/features/NotificationIcon.zig`、`island/src/ui/Renderer.zig`、`island/src/app/main.zig`。
- 具体实现：`AppIconService` 独自获取/销毁 HICON、创建并销毁 GDI DC/DIB、把 32×32 像素编码到调用方提供的 PNG buffer；不向调用者暴露原生句柄。App 将函数显式注入四个消费者。SoundOutput 缓存标识改为 PID + 不区分大小写的 executable path，同 PID 路径变化时刷新原槽；失败取图不永久缓存空结果。保留 MusicSession 的 app-id 路径解析及带注入参数的图标 helper。
- 依赖差异：删除 `SoundOutput → MusicSession`、`NotificationIcon → MusicSession`、`Renderer → MusicSession` 三条已替代边；`legacy-dependencies.json` 经审查从 21 降至 18。边界扫描现报 18 条既存边、0 新增、0 移除、0 未解析。
- 自动验证命令与结果：Zig `0.17.0`。`zig fmt --check build.zig src/app/main.zig src/features/MusicSession.zig src/features/SoundOutput.zig src/features/NotificationIcon.zig src/ui/Renderer.zig src/platform/contracts/AppIcon.zig src/platform/windows/AppIconService.zig` 退出码 0。`zig build test --summary all` 最终退出码 0、9/9 build steps succeeded；图标输入/PNG 与 PID+路径缓存单测成功（其余既有测试命中 Zig build cache）。`zig build --summary all` 退出码 0、16/16 steps succeeded，IslandBar、安装器及既有 smoke/probe 目标成功。bundled Python `tools/architecture/check_boundaries.py --record-baseline` 从源码差异移除三条已解决边；随后 `--report` 退出码 0：18 legacy、0 新增/移除/未解析。`git diff --check` 退出码 0；Git 仅提示 LF 将在未来转换为 CRLF，没有 whitespace error。
- 真实代码错误及修复：首轮测试发现 Zig 0.17 不接受该路径测试中的旧式数组重复表达式；改成 `[260]u16 = @splat('x')` 后测试通过。不是环境错误；没有跳过该错误。
- 环境项：无 `ENV_UNAVAILABLE`。本轮在进程级 `ZIG_LIB_DIR=C:\Software\Loadout\store\zig\0.17.0\lib` 并获准访问 Windows SDK 的环境完成测试与完整构建。
- 仍待验证：`WIN-ICON-001` 中的 Music/Sound/Notification/任务窗口真实图标、缺失权限路径、进程退出/重启、自然 PID 重用及 GDI handle 长期趋势；以上为 `MANUAL_PENDING`，不阻止后续步骤。
- 风险：AppIconService 采用原有 GDI 绘制/PNG 路径并收窄资源所有权；自动测试验证当前进程返回 PNG 签名和缓存 PID/path 逻辑，但不证明真实 Feature 页面刷新节奏或资源长期趋势。
- 回退方式：只反向 S1-003 的代码 hunks：恢复 MusicSession 原 Shell/GDI helper 与 SoundOutput 原 PID-only cache；将 NotificationIcon、Renderer 和 SoundOutput/MusicSession 回到直接旧接口；撤销 main callback 注入和 build 注册/绑定/测试；删除新增 `AppIcon.zig` 与 `AppIconService.zig`；向旧 allowlist 加回三条依赖。反向编辑 S1-003 的 tracker/doc 记录。保留 S0、S1-001、S1-002 变更和用户 V2 文件，不重置工作区。
- 下游任务解锁：是。`S2-001` 可继续；`S3-001` 也已有图标 port 前置条件。真实 Windows 手测继续留待集中验收，不作为代码队列门禁。

## [S2-001] 受控绘制生命周期与设备资源边界

- 日期 / 分支 / 基线 commit：2026-10-15 / `main` / `a95646ede369445a819f9367e5b9a92aee7227ec`。
- 实施状态：`IMPLEMENTED`。
- 自动验证状态：`AUTO_PASSED`。
- Windows 实机状态：`MANUAL_PENDING`；`WIN-GFX-001`、`WIN-LIFECYCLE-001` 在 `docs/refactor/WINDOWS-MANUAL-TESTS.md` 集中记录。未声称真实 GPU/device-loss 恢复、DPI/多显示器或资源增长实测通过。
- 审计发现的代码错误：`Renderer.renderPill` 在 D2D `BeginDraw` 后存在多处可提前 return 分支；旧代码会跳过 `EndDraw`，导致下一帧仍处于错误的 draw/target 状态。直接代码检查确认，已修复而非跳过。
- 修复与资源策略：新增无平台依赖的 `DrawLifecycle` 纯状态辅助模块；正常和提前返回都保证 `EndDraw` 后才 `SetTarget(null)`，再释放 D2D target/surface。失败的 `GetBuffer`、D2D target/brush、icon bitmap、Composition opacity animation 也会释放部分输出句柄。`DeviceResources.generation` 每次 initialize 递增；TextRenderer 单独清除 D2D bitmap/context cache，保留 DirectWrite formats 和主循环的业务 snapshots。显示变化和检测到明确 device-loss HRESULT 后按“失效缓存 → Renderer shutdown → initialize → 下帧重绘”顺序重建；运行态失败最多每秒重试一次。
- 改动文件：`AGENTS.md`、`docs/refactor/GOAL-TRACKER.md`、`docs/refactor/DEPENDENCIES.md`、`docs/refactor/OWNERSHIP.md`、`docs/refactor/WINDOWS-MANUAL-TESTS.md`、`island/build.zig`、`island/src/ui/DrawLifecycle.zig`、`island/src/ui/Renderer.zig`、`island/src/ui/TextRenderer.zig`、`island/src/app/main.zig`。
- 非改动范围：无 UI 几何、视觉样式、绘制内容、窗口行为或业务状态结构改动；不重构为复杂绘制命令系统，不改 WIC 解码像素 cache 生命周期。
- 自动验证：Zig `0.17.0`。`zig fmt --check build.zig src/app/main.zig src/ui/Renderer.zig src/ui/TextRenderer.zig src/ui/DrawLifecycle.zig` 退出码 0。`zig build test --summary all` 退出码 0、11/11 steps succeeded，DrawLifecycle 3/3 测试通过（测试集余下目标使用缓存）；覆盖正常完成、device-loss 错误后仍 detach target、已知与未知 HRESULT 分类。`zig build --summary all` 退出码 0、16/16 steps succeeded，app、installer、现有 smoke/probe 保持成功。bundled Python `check_boundaries.py --report` 退出码 0：18 legacy、0 新增/移除/未解析。`git diff --check` 退出码 0，Git 仅发出 LF→CRLF 提示，没有 whitespace error。
- Windows 未验证项：真实显示器/DPI 变化、D2D/DComp/DXGI/D3D11 device loss/recreate、UI 视觉及长期资源趋势均为 `MANUAL_PENDING`。当前能构建并运行 Windows 单元测试，不存在工具链/SDK `ENV_UNAVAILABLE`。
- 风险：设备损失自动恢复按 HRESULT 严格分类；其它绘制失败会被清理但不强制重建。实际驱动行为、COM 组件错误码传播、长时间重建/bitmap 资源趋势须按清单验证。
- 回退方式：仅反向 S2-001：恢复 Renderer 旧 EndDraw/defer 前的控制流及原资源错误分支；移除 `DeviceResources.generation`、`lastFailureIsDeviceLoss`、主循环恢复调用和 TextRenderer `invalidateDeviceResources` 增量；删除 `DrawLifecycle.zig` 并撤销 build 注册/测试。撤回对应文档小节和 tracker 状态。保留 S0、S1-001/002/003、用户 V2 文件及其他未相关变更。
- 下游任务解锁：是。S2-002 可以继续；Sound 的 S3-001 前置条件已满足。Windows 手测不阻塞后续工作。

> 当前最早未完成步骤：`S2-002`。依赖与20步队列见 `docs/refactor/GOAL-TRACKER.md`；Windows 验收仍统一维护于 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。

## [S2-002] 最小 LayoutSnapshot 与坐标契约

- 日期 / 分支 / 基线 commit：2026-10-15 / `main` / `a95646ede369445a819f9367e5b9a92aee7227ec`。
- 实施状态：`IMPLEMENTED`。
- 自动验证状态：`AUTO_PASSED`。所有可执行 Zig/静态目标已实跑；第一次完整编译暴露的两个集成编译错误已修复并复跑成功。
- Windows 实机状态：`MANUAL_PENDING`。声音滑块动画中点击/拖动、reveal/viewport 裁剪、显示器 DPI/负坐标和真实设备变化见 `WIN-LAYOUT-001`、`WIN-INPUT-001`、`WIN-DPI-001`、`WIN-UI-001`；没有声称真实 GUI/设备测试通过。
- 允许改动范围 / 未修改行为：新增最小布局快照类型，选择 SoundPage mixer slider group 单一受控接入；只替换其 track bounds、content/surface clip 和 hit mapping。其它 SoundPage 控件及页面仍走旧几何 API。颜色、字体、尺寸、动画参数、音量功能、窗口、安装器、smoke/probe 均保持。
- 代码与坐标契约：新增 `island/src/ui/LayoutSnapshot.zig`，包含通用 ElementId、Bounds/HitRegion、动画 Transform、Clip、ZOrder、Visible/Enabled、generation、ScreenTransform、hit 查询和成功帧发布逻辑。S2-003 将其从 Core 移入 UI Foundation 并将专用声音 ID 收窄为通用 `.slider`。`PaintContext` 在 UI 线程持有 candidate/last-presented 值；每次绘制只有成功后才发布，失败帧继续用上个成功帧。Sound 滑块轨道由一份 `CardLayout.soundPageFor` 结果构建快照，TextRenderer 从快照绘制同一 Bounds，Renderer/TextRenderer 使用快照 clip，游标/按下/点击/拖动 hit 查询成功帧快照。若旧重算路径命中 slider 但快照没有命中，则不触发旧 slider 命中。
- 坐标定义：IslandWindow screen point 和 window origin 是物理像素，可含负坐标；ScreenTransform 用每 DIP 像素比例转为 client-local DIPs。CardLayout/D2D 几何为 client-local DIPs；布局 Transform 对绘制 bounds/clip 正向映射、对输入点逆向映射。快照 clip 是 viewport 与当前 reveal surface 的交集。
- 改动文件：`AGENTS.md`、`docs/refactor/GOAL-TRACKER.md`、`docs/refactor/DEPENDENCIES.md`、`docs/refactor/OWNERSHIP.md`、`docs/refactor/WINDOWS-MANUAL-TESTS.md`、`island/build.zig`、`island/src/ui/LayoutSnapshot.zig`、`island/src/app/main.zig`、`island/src/ui/Renderer.zig`、`island/src/ui/TextRenderer.zig`。
- 可执行验证（Zig `0.17.0`）：`zig fmt` 退出码 0；`zig build test --summary all` 退出码 0，13/13 build steps succeeded、6/6 tests passed；`zig build --summary all` 退出码 0，16/16 steps succeeded（IslandBar、Setup、native-smoke、thumbprobe、sysstatusprobe、geoprobe、gsmtcprobe）。独立 `setup-build`、`native-smoke-build`、`thumbprobe-build`、`sysstatusprobe-build`、`geoprobe-build`、`gsmtcprobe-build` 各退出码 0、2/2 steps。
- 几何单测范围：snapshot content/reveal clip、空隙、disabled/invisible、overlap z-order、绘制/命中共用 animation Transform、125% DPI 与负显示器原点、失败帧不覆盖已呈现快照。真实点击与音量操作仍为人工项。
- 依赖/差异检查：bundled Python `tools/architecture/check_boundaries.py --report` 退出码 0：18 active legacy edges、0 新增、0 移除、0 未解析。最终位置的 `zig fmt --check build.zig src/ui/LayoutSnapshot.zig src/app/main.zig src/ui/Renderer.zig src/ui/TextRenderer.zig` 退出码 0。`git diff --check` 退出码 0，只有已有工作区的 LF→CRLF 提示。
- 首轮真实代码错误：完整 build 报告主音量滚动分支的 `device_count`/`mix_count` 变量未定义，以及 Renderer 引用不可见的 TextRenderer `toD2DRect`。已恢复局部行数变量并用 Renderer 自有 `D2DRectF` 转换快照 clip；没有归为环境问题或跳过。
- 环境不可执行项：无 `ENV_UNAVAILABLE`。普通沙箱访问 Zig lib 首次返回 `AccessDenied`，按项目已记录的工具链方式，在获准访问本机 Zig `lib`/Windows SDK 后完成测试和全部构建。Windows 桌面、多个 DPI/显示器、实际音频设备为 `MANUAL_PENDING`，不是环境构建缺口。
- 回退方式：仅反向 S2-002：移除 `LayoutSnapshot.zig`、Renderer/TextRenderer/main 的快照字段和试点调用、build module/import/test 增量；恢复 SoundPage slider 原绘制/命中路径；撤回本步 tracker/ownership/dependency/manual-test 文档 hunks。保留 S0/S1/S2-001、用户 V2 文件和其它并行工作，不 reset 工作区。
- 风险：快照目前只覆盖 mixer slider 元素；设备行、空间音效、返回、滚动条等非 slider hit geometry 仍按旧路径计算。真实 renderer clip、hover 与音频设备列表变化仍需手工回归；S3-002 将逐步把完整 Sound UI 纳入统一 layout/action。
- 下游任务解锁：是。S2-003、S2-004 和 S3-001 可继续；人工 GUI 不阻塞。

> 当前最早未完成步骤：`S2-003`。依赖与 20 步队列见 `docs/refactor/GOAL-TRACKER.md`；所有 Windows 实测统一记录于 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。

## [S2-003] InputRouter、语义 Action 与动画命中同步

- 日期 / 分支 / 基线 commit：2026-10-15 / `main` / `a95646ede369445a819f9367e5b9a92aee7227ec`。
- 实施状态：`IMPLEMENTED`。
- 自动验证状态：`AUTO_PASSED`；Zig `0.17.0` 下格式、纯 Zig 单测、完整 Windows app/setup/probe build 与边界检查均实际执行。
- Windows 实机状态：`MANUAL_PENDING`。真实动画期间反向/拖动、点击仅触发一次、多 DPI/多屏、原生输入区域时序与主/应用音量动作见 `WIN-INPUT-001`、`WIN-LAYOUT-001`、`WIN-DPI-001`、`WIN-UI-001`；未声称 GUI/音频设备通过。
- 允许改动范围 / 未修改行为：只把 S2-002 mixer slider 的 press/drag/release/cancel 接入 InputRouter；声音设备行、滚动条、其它 Feature/页面、现有音量展示和 UI 样式仍保留旧路径。未更改 SoundOutput/AudioVolume API。
- 代码与 Action：新增 `island/src/ui/InputRouter.zig`。它只依赖 UI `LayoutSnapshot`，Action 是通用 `.adjust`/`.release`，包含 ElementId、index、fraction、phase 和 frame generation。App 消费 `.slider` adjustment 并调用既有 `setMixerLevel`。Router 是唯一 drag capture owner；移除了 `PaintContext.mixer_drag_row` 与从未读取的 `mixer_drag_pid`。
- 图层修正：S2-002 的 `LayoutSnapshot` 从 `src/core` 移到 `src/ui`；ElementId 从 sound 专用名字改为通用 `.slider`，InputRouter 不引入 Feature 依赖。`build.zig` 保持显式模块注册与绑定。
- 修复已确认重复副作用：之前按下分支立即调音量，释放 `takeClick()` 分支又以原 press point 调一次。现在 press/drag 通过类型化 Action 更新；release 只清除 capture。`pending_press_action_handled` 仅是本次窗口事件的暂存信息，防止捕获取消后 click 分支重复派发；没有创建第二份长期业务状态。
- 改动文件：`AGENTS.md`、`docs/refactor/GOAL-TRACKER.md`、`docs/refactor/DEPENDENCIES.md`、`docs/refactor/OWNERSHIP.md`、`docs/refactor/WINDOWS-MANUAL-TESTS.md`、`island/build.zig`、`island/src/ui/InputRouter.zig`、`island/src/ui/LayoutSnapshot.zig`、`island/src/app/main.zig`。
- 自动验证：`zig fmt --check build.zig src/ui/InputRouter.zig src/ui/LayoutSnapshot.zig src/app/main.zig` 退出码 0。`zig build test --summary all` 退出码 0、15/15 steps succeeded；本次 InputRouter 5/5 实测通过，LayoutSnapshot 6/6 已执行且缓存成功，合计 11/11。`zig build --summary all` 退出码 0、16/16 steps succeeded，IslandBar、Setup 与全部默认 smoke/probe targets 成功。
- 自动交互覆盖：press + release 输出一个调节 Action；拖动 Action 使用最新成功呈现 frame generation；最高 ZOrder 优先；clip/gap/disabled/zero-size/out-of-bounds 拒绝捕获；快速取消与重新按下不沿用旧 capture。单测不模拟真实 Win32 消息队列与可见帧。
- 依赖/差异检查：bundled Python `tools/architecture/check_boundaries.py --report` 退出码 0：18 active legacy edges、0 新增、0 移除、0 未解析。`git diff --check` 退出码 0，仅 LF→CRLF 提示。`ENV_UNAVAILABLE`：无；实际工具链需已记录的进程级 `ZIG_LIB_DIR` 和获准的 SDK 访问。
- 风险：Mixer Action 仍在 App 调用现有 SoundOutput/AudioVolume 路径，S3-001 再迁移到 Controller；SoundPage 非滑块 hit/action 继续旧路径。原生消息是否严格只派发一次、多显示器 transform 和动画反向仍待人工验证。
- 回退方式：仅反向 S2-003：撤销 InputRouter 注册/import/测试，恢复 `mixer_drag_row` 旧 capture 与点击/拖动分支；如需保持 S2-002 独立阶段则保留 `src/ui/LayoutSnapshot.zig` 的最终 UI 路径与绘制/命中接线；撤回本步 docs/tracker 记录。不要把文件移回 Core，不改前序步骤或工作区其它改动。
- 下游任务解锁：是。S2-004 和 S3-001 可继续；人工 GUI/设备不作为门禁。

> 当前最早未完成步骤：`S2-004`。依赖与 20 步队列见 `docs/refactor/GOAL-TRACKER.md`；Windows 实测统一维护于 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。

## [S2-004] 最小 UI 公共层、样式与绘制边界

- 日期 / 阶段：2026-10-15 / 阶段 2。S2-002、S2-003 之后实施；按 V2 逐步执行，架构文档仍为 `PROPOSED`。
- 实施状态：`IMPLEMENTED`；自动验证：`AUTO_PASSED`；Windows 实机：`MANUAL_PENDING`。
- 目标边界：新增通用、固定容量/受控绘制接口；只抽取当前实际复用需要的圆角矩形、椭圆和滑块，不创建 VDOM、全量 DrawCommands、动态插件宿主、全局 Context 或事件总线。
- 改动文件：`island/src/ui/ThemeTokens.zig`、`island/src/ui/Canvas.zig`、`island/src/ui/Slider.zig`、`island/src/features/sound/ui/MixerSlider.zig`、`island/src/ui/Theme.zig`、`island/src/ui/GlassMaterial.zig`、`island/src/ui/Renderer.zig`、`island/src/ui/TextRenderer.zig`、`island/src/app/main.zig`、`island/build.zig`、`island/tools/architecture/legacy-dependencies.json`、`docs/refactor/GOAL-TRACKER.md`、`docs/refactor/DEPENDENCIES.md`、`docs/refactor/OWNERSHIP.md`、`docs/refactor/WINDOWS-MANUAL-TESTS.md`、`AGENTS.md`。
- 代码改动：新增纯值共享 `ThemeTokens.Color/Tokens` 与透明度 helpers；`Theme` 主题持久化仍在原模块，但 Feature 滑块尺寸/颜色分别由 Sound UI 决定。新增 `Canvas` 与通用 `Slider.ViewModel`/paint；App 将现有主/应用音量映射为 Sound UI view model，公共 TextRenderer 只执行通用 Canvas/Slider 操作。滑块 bounds 仍来自最近成功帧的同一 LayoutSnapshot；无新的布局计算、堆分配或 draw 操作，视觉参数沿用旧值。
- 日志依赖：`Theme → Log` 改为 `Theme.cycleTheme(log_fn)`/`applyRememberedTheme(log_fn)` 接收 App 注入的窄同步 logger，移除不必要平台依赖；主题文件错误日志改为固定栈缓冲，避免持续泄漏新分配。`legacy-dependencies.json` 删除已替代的这一条，当前 17 条旧边。
- 编译/测试（Zig `0.17.0`）：最终 `zig build test --summary all` 退出码 0，23/23 steps succeeded；新增 Theme parser/smoke test 本次 1/1 通过；此前 uncached 运行中 Slider 2 tests、MixerSlider 1、ThemeTokens 1 均通过，合计 5 个新增纯逻辑/绘制测试全通过。首次运行曾发现 C ABI callback 按值接收普通 Zig struct 编译错误、以及两个写错的测试期望；回调改为只传指针、断言调整后重跑成功，未跳过错误。
- 完整构建：`zig build --summary all` 退出码 0，16/16 steps succeeded，包括 IslandBar、Setup、native-smoke 与 thumbprobe/sysstatusprobe/geoprobe/gsmtcprobe。
- 静态/格式检查：`zig fmt --check` 退出码 0；`python tools/architecture/check_boundaries.py --report` 最终退出码 0：17 条 active legacy、0 新增、0 移除、0 未解析；`git diff --check` 退出码 0（Git 仅提示工作树 LF→CRLF）。普通沙箱 Zig library access 延续项目已记录方式，使用 `ZIG_LIB_DIR` 并在获准访问本机 Zig/SDK 后编译；本步无 `ENV_UNAVAILABLE`。
- Windows 人工待测：`WIN-UI-001`（滑块样式、主题循环、截图对比）与 `WIN-PERF-001`（实际帧时间、句柄/内存/GPU 长期趋势）`MANUAL_PENDING`；还需要真实 D2D 渲染观察。详情统一维护在 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。自动绘制测试不替代 GUI/性能结论。
- 保留/遗留风险：只将 Sound mixer slider 的视觉映射迁到 Sound UI；`TextRenderer.SoundPageText` 和其余 SoundPage 绘制仍为兼容桥，按 S3-002 继续迁移；其它页面按 S4 处理。Theme 文件配置/全局选择状态尚未分离出 Theme façade，但纯共享 Color/Tokens 不再与 Feature 专属滑块样式混写。
- 回退方式：仅反向 S2-004：移除 `ThemeTokens.zig`、`Canvas.zig`、`Slider.zig`、`features/sound/ui/MixerSlider.zig` 及对应 build/test wiring；在 App 恢复为旧 `volume/muted` 数据，在 TextRenderer 恢复原 Sound slider 绘制；Theme 恢复旧 Color/Accent/Ink 布局和 Log import/call signature，并恢复 `legacy-dependencies.json` 的 `Theme → Log`；撤回本步 tracker/dependency/ownership/manual-test 文档段落。保留 S2-001 至 S2-003 文件/行为、此前日志与用户 V2 文件，不 reset 工作区。
- 下游：继续按 V2 顺序处理 S3-001；S3-002 的依赖已满足。Windows GUI 和性能待测不阻塞后续步骤。

## [S3-001] Sound State/Action/Controller 与 AudioService 分层

- 日期 / 分支 / 基线 commit：2026-10-15 / `main` / `a95646ede369445a819f9367e5b9a92aee7227ec`。
- 实施状态：`IMPLEMENTED`；自动验证：`AUTO_PASSED`；Windows 实机：`MANUAL_PENDING`。步骤状态和依赖队列见 `docs/refactor/GOAL-TRACKER.md`。
- 目标边界：为 Sound 建立唯一业务状态 owner，并把 Core Audio、设备/会话枚举和副作用隔离到 Windows platform adapter；不改变现有页面视觉、功能、安装器或 smoke/probe 构建目标。
- 改动文件：`AGENTS.md`、`docs/refactor/GOAL-TRACKER.md`、`docs/refactor/DEPENDENCIES.md`、`docs/refactor/OWNERSHIP.md`、`docs/refactor/WINDOWS-MANUAL-TESTS.md`、`island/build.zig`、`island/tools/architecture/check_boundaries.py`、`island/tools/architecture/legacy-dependencies.json`、`island/src/features/SoundOutput.zig`（迁移为 `island/src/platform/windows/AudioService.zig`）、`island/src/features/sound/Controller.zig`、`island/src/platform/contracts/SoundAudio.zig`、`island/src/platform/windows/AudioVolume.zig`、`island/src/platform/windows/SystemStatus.zig`、`island/src/app/main.zig`。
- 具体实施：AudioService 包含原 SoundOutput 的 COM/Core Audio 设备/会话枚举、音量写入、图标缓存和后台刷新。新增无 COM 指针的 SoundAudio 值契约。Controller 独占 Sound snapshot、revision、topology generation、confirmed/optimistic volume/mute/session state、pending token 和原始 HRESULT error；App 统一映射系统面板静音/音量、Sound session slider、默认设备选择动作。SystemStatus 不再再次采样/缓存主音量/静音。Session/device Action 依据 PID/device id 与 topology generation 校验；迟到 token 丢弃；同步拒绝的替换请求不取消先前 accepted 请求，新 accepted 请求 supersede 并清理旧 optimistic state。超时为 5 秒。
- 线程/资源契约：AudioService 与 AudioVolume 各自拥有一个 worker；worker 请求 MTA，只在 CoInitializeEx 成功时使用 Core Audio 且同线程 CoUninitialize。COM interfaces 不越线程返回；同步调用通过锁内固定值队列和 `SoundAudio.OperationResult` 回到 UI，后者保留系统 HRESULT。stop event 后 join worker 再释放 handles/critical section。检测到 RPC_E_CHANGED_MODE 不再当作初始化成功，避免对未由该线程配对初始化的 COM 状态调用 CoUninitialize。
- 自动验证命令/输出：Zig `0.17.0`，本机 SDK/lib 以进程级 `ZIG_LIB_DIR=C:\Software\Loadout\store\zig\0.17.0\lib` 执行。`zig fmt` 修改文件退出码 0；`zig fmt --check build.zig src` 退出码 0。`zig build test --summary all` 最后退出码 0、27/27 steps succeeded；SoundController 9/9 纯逻辑测试已实跑通过，SoundAudio snapshot 测试通过。`zig build --summary all` 退出码 0、16/16 steps succeeded，含 IslandBar、IslandBarSetup 和 5 个 smoke/probe 目标。bundled Python `tools/architecture/check_boundaries.py --report` 退出码 0：16 active legacy edges、0 新增、0 未解析；已从旧 17 条中删除 `SoundOutput → Log`。`git diff --check` 退出码 0，仅有 LF→CRLF 提示。
- 编译错误处理：首轮完整 build 报告 `main.zig` switch arm 中赋值表达式无效；改成显式 block 并重跑完整构建通过。代码审计发现 `RPC_E_CHANGED_MODE` 被旧 worker 逻辑当作成功并不配对 CoUninitialize；两个 worker 现只接受成功 HRESULT。测试与构建未跳过已确认错误。
- Windows 人工待测：`WIN-SOUND-001`、`WIN-SOUND-002`、`WIN-ICON-001`、`WIN-LIFECYCLE-001` 全部 `MANUAL_PENDING`；包括 GUI 视觉/操作、真实主/应用音量、输出设备切换/热插拔/会话退出、COM worker 真实启停。统一清单：`docs/refactor/WINDOWS-MANUAL-TESTS.md`。没有因 GUI 窗口无法操作而阻塞后续步骤；无 `ENV_UNAVAILABLE`。
- 风险：当前 Controller 全局只有一个 pending action；新 accepted 操作会 supersede 旧 pending 并清理其乐观状态，旧结果忽略，真实结果需由后续 snapshot 反映。回传队列以固定 operation result slot 保存当前类别最新结果。需实机验证用户快速拖动时操作可见反馈与设备异常恢复。
- 回退方式：只反向 S3-001：将 `AudioService.zig` 的 COM 枚举/写入实现恢复到旧 `features/SoundOutput.zig`，恢复构建模块名/import 和 SoundOutput→Log allowlist/owner mapping；删除 `SoundController.zig`、`SoundAudio.zig` 及对应构建绑定/单测；main 恢复 SoundOutput/AudioVolume 直接读写与旧缓存字段；SystemStatus 恢复 AudioVolume 音量采样。撤回 S3 文档/tracker 增量，保留 S0/S1/S2/Sound UI slider 基础和其它工作区更改，不 reset 工作区。
- 下游任务解锁：是。S3-002 可继续；WIN-SOUND/WIN-LIFECYCLE 人工项目仍为 `MANUAL_PENDING`，不作为代码门禁。

## [S3-002] SoundPage UI 独立完成并移除旧业务路径

- 日期 / 阶段：2026-10-15 / 阶段 3；V2 架构文档状态仍为 `PROPOSED`。
- 实施状态：`IMPLEMENTED`；自动验证：`AUTO_PASSED`；Windows 实机验收：`MANUAL_PENDING`，关联 `WIN-SOUND-001/002`、`WIN-LAYOUT-001`、`WIN-INPUT-001`、`WIN-UI-001`、`WIN-DPI-001`、`WIN-LIFECYCLE-001`。
- 改动文件：`island/src/features/sound/ui/Page.zig`、`island/src/features/sound/ui/MixerSlider.zig`、`island/src/ui/PagePainter.zig`、`island/src/ui/Renderer.zig`、`island/src/ui/TextRenderer.zig`、`island/src/core/CardLayout.zig`、`island/src/ui/LayoutSnapshot.zig`、`island/src/ui/InputRouter.zig`、`island/src/app/main.zig`、`island/build.zig`、`docs/refactor/GOAL-TRACKER.md`、`docs/refactor/DEPENDENCIES.md`、`docs/refactor/OWNERSHIP.md`、`docs/refactor/WINDOWS-MANUAL-TESTS.md`、`AGENTS.md`。
- 具体改动：新增 Sound UI 只读 ViewModel、页面局部状态、布局/滚动、绘制与 typed Action 映射；让按钮、会话行、滑块及滚动条由同一成功呈现的 `LayoutSnapshot` 提供 Bounds 与 hit target。设备/会话拓扑 generation 更新时，Router 取消过期拖动，Controller Action 再校验代际。Renderer 通过通用 PagePainter callback 接收 Feature 页面，不再内嵌 Sound 绘制或状态；TextRenderer 改为通用绘制原语和通用图标缓存。移除旧 SoundPage TextRenderer 类型、CardLayout 专属几何/hit 路径和 main 的旧绘制/命中副本。
- 保持项：逐项保留旧页面尺寸、字体、颜色、主题透明度合成、滑块轨道/圆角/thumb 几何、裁剪与滚动节奏。没有修改 UI 视觉设计、安装器、smoke/probe 接口或音频功能。
- 自动验证：`zig fmt --check build.zig src` 退出码 0；在全新缓存运行 `zig build test --cache-dir %TEMP%\islandbar-s3-002-docverify-tests --summary all` 退出码 0，31/31 build steps、45/45 测试通过；`zig build --summary all` 退出码 0，16/16 steps；`setup-build` 4/4、`native-smoke-build`/`thumbprobe-build`/`sysstatusprobe-build`/`geoprobe-build`/`gsmtcprobe-build` 各 2/2；`python tools/architecture/check_boundaries.py --report` 退出码 0，16 legacy、0 新增、0 移除、0 未解析；`git diff --check` 退出码 0。构建通过获准访问已安装 Zig 0.17.0 库和 Windows SDK 的调用执行，使用进程级 `ZIG_LIB_DIR`。
- 自动测试覆盖：SoundPage 4 项布局/Action/ViewModel 测试，LayoutSnapshot 7 项 clip/动画/坐标/元素测试，InputRouter 6 项单次 Action/捕获/代际取消测试；全量测试合计 45 项。source-only 扫描未发现旧 `SoundPageText`、`drawSoundPage`、`soundPageFor`、`soundPageHitFor` 业务路径引用。
- Windows 实测：尚未打开可操作的 IslandBar 原生窗口；音量/设备/会话行为、GUI 命中、动画、DPI/多屏和截图均 `MANUAL_PENDING`，集中记录在 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。自动几何测试不作为人工验收证据。
- 风险 / 未验证：真实 D2D/DComp 绘制和音频设备变化、快速设备替换中的手势表现尚无原生桌面证据；GUI 未测不阻塞 S4 重构。没有 `ENV_UNAVAILABLE` 的编译或测试项目。
- 回退方式：只反向 S3-002 代码 hunks：恢复 TextRenderer 的 SoundPage 专用绘制接口、CardLayout 旧 SoundPage layout/hit、main/Renderer 的 SoundPage 旧构建和派发路径；撤销 SoundPage/PagePainter 的 build wiring；恢复 LayoutSnapshot/InputRouter 对 Sound 页面元素及 topology generation 的 S3-002 变化（若被后续步骤依赖，先保留通用 API 并仅回接 S3-001）。撤回本步 `docs/refactor` 段落与 tracker 行状态；保留 S0 至 S3-001 记录、后续独立变更和用户 V2 文件，不 reset 工作区。
- 下游解锁：是；S4-001 至 S4-007 按 V2 各自范围连续实施，所有 Windows 实机项仍待集中验收。

> 当前最早未完成步骤：`S4-001`。执行队列见 `docs/refactor/GOAL-TRACKER.md`；所有 Windows 原生 GUI、设备、DPI、多显示器、动画点击与长期资源项目统一见 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。

## [S4-001] Music / Lyrics / GSMTC / Music UI

- 日期 / 阶段：2026-10-15 / 阶段 4；依据 V2 计划实施，`docs/IslandBar-Architecture-V1.md` 继续保持 `PROPOSED`。
- 实施状态：`IMPLEMENTED`；自动验证：`AUTO_PASSED`；Windows 实机：`MANUAL_PENDING`。Tracker 的 S4-002 已自动转为 `IN_PROGRESS`，GUI/设备验收不是前置门禁。
- 改动文件：`island/build.zig`；`island/src/app/main.zig`、`Diagnostics.zig`；`island/src/core/CardLayout.zig`、`StatePolicy.zig`；`island/src/features/music/Controller.zig`、`Lyrics.zig`、`ui/Page.zig`；`island/src/platform/contracts/MusicMedia.zig`、`LyricsProtocol.zig`；`island/src/platform/windows/MediaService.zig`、`LyricsService.zig`；`island/src/ui/Renderer.zig`、`TextRenderer.zig`；`island/tools/architecture/check_boundaries.py`、`legacy-dependencies.json`；`docs/refactor/GOAL-TRACKER.md`、`DEPENDENCIES.md`、`OWNERSHIP.md`、`WINDOWS-MANUAL-TESTS.md`、`AGENTS.md`。旧 `island/src/features/MusicSession.zig` 和 `island/src/features/Lyrics.zig` 路径已移除并由新边界替代。
- 代码边界：MediaService 持有 GSMTC/COM worker、会话与封面解码；`MusicMedia` 是无 COM 指针的值契约。Music Controller 持有当前音乐/歌词有效性和 track generation；Windows LyricsService 只返回附带 generation 的值，纯解析代码放入 `LyricsProtocol` contract，Feature `Lyrics` façade 保留。Music Page 拥有 Music 卡片与条的布局/文本映射/命中快照；Renderer/TextRenderer 接收通用 card DTO 与 page-painter 回调。Music 的卡片控制与歌词几何已从 Core CardLayout 移除，绘制和点击只读最近成功呈现布局。
- 保持项：沿用迁移前 Music 卡片/条的尺寸、间距、字号、颜色、动画与交互；播放/暂停、切歌、封面、歌词滚动、会话切换/消失路径保留。未改安装器、资源、smoke/probe 目标或架构文档状态。
- 自动验证（Zig `0.17.0`，进程级 `ZIG_LIB_DIR=C:\Software\Loadout\store\zig\0.17.0\lib`，新缓存）：`zig fmt --check build.zig src` 退出码 0；`zig build test --summary all` 退出码 0，41/41 build steps、52/52 tests；`zig build --summary all` 退出码 0，16/16 steps，包含 IslandBar、Setup、native-smoke、thumbprobe、sysstatusprobe、geoprobe、gsmtcprobe；bundled Python `tools/architecture/check_boundaries.py --report` 退出码 0：14 active legacy edges、0 新增、0 移除、0 未解析；`git diff --check` 退出码 0（仅 Git 的 LF→CRLF 提示）。
- 已发现并修复的真实代码问题：单测编译发现忽略 `parseLrc` 返回值；完整 build 发现未使用 capture；早期依赖守卫仍把已迁移的 MusicSession 写作必须模块。均已修复并在最终全量测试/构建及静态扫描中复核，没有关闭测试或放宽边界。早期 Zig 标准库读取偶发 `Unexpected` 后重试成功，不构成 `ENV_UNAVAILABLE`。
- Windows 人工待测：`WIN-MUSIC-001`、`WIN-ICON-001`、`WIN-LIFECYCLE-001`、`WIN-UI-001`、`WIN-INPUT-001`、`WIN-DPI-001`、`WIN-GFX-001` 均 `MANUAL_PENDING`；涉及真实 GSMTC 播放器/音频设备、会话切换、封面、GUI 视觉、动画点击、COM 生命周期、多 DPI/多显示器与 D2D 资源恢复。统一操作和预期见 `docs/refactor/WINDOWS-MANUAL-TESTS.md`；未打开或声称验证 Windows 原生 GUI。
- 风险：MediaService/GSMTC COM 的真实设备行为、歌词来源弱网/缓存、封面切换和长时间资源趋势没有 GUI/设备证据；自动 generation 测试只证明纯值状态规则，不代表真实 Windows worker/GSMTC 测试。
- 回退方式：只反向 S4-001：恢复旧 `features/MusicSession.zig` 与 `features/Lyrics.zig` 来源及 build/import wiring；撤回 `MusicMedia`/`LyricsProtocol`、Music Controller/Page、MediaService/LyricsService 接线及相应 tests；恢复 TextRenderer 旧 Music card DTO、Renderer/MusicPage 旧画法和 CardLayout 音乐几何/hit；恢复 App 旧的歌词/播放与独立布局处理。撤销 S4-001 的 boundary map 变化和本步文档增量。保留 S0-S3 及其他步骤的更改，不 reset 或覆盖工作区。
- 下游解锁：是。S4-002 Launcher 继续实施；所有 Windows 实机项继续 `MANUAL_PENDING`。

> 当前最早未完成步骤：`S4-003`。执行队列见 `docs/refactor/GOAL-TRACKER.md`；所有 Windows 原生 GUI、设备、DPI、多显示器、动画点击与长期资源项目统一见 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。

## [S4-002] Launcher / StartApps / StartMenu

- 日期 / 阶段：2026-10-15 / 阶段 4；依据 V2 的 S4-002 范围实施，`docs/IslandBar-Architecture-V1.md` 继续保持 `PROPOSED`。
- 实施状态：`IMPLEMENTED`；自动验证：`AUTO_PASSED`；Windows 实机：`MANUAL_PENDING`。Tracker 已推进 S4-003 为 `IN_PROGRESS`；人工 GUI/系统操作不作为门禁。
- 改动文件：`island/build.zig`；旧 `island/src/features/StartApps.zig` 迁移为 `island/src/platform/windows/LauncherService.zig`，旧 `island/src/features/StartMenu.zig` 迁移为 `island/src/platform/windows/ShellCommand.zig`；新增 `island/src/platform/contracts/LauncherCatalog.zig`、`island/src/features/launcher/Controller.zig`、`island/src/features/launcher/ui/Page.zig`；更新 `island/src/platform/windows/SystemToggles.zig`、`island/src/app/main.zig`、`island/src/core/CardLayout.zig`、`island/src/ui/Renderer.zig`、`island/src/ui/TextRenderer.zig`、`island/tools/architecture/check_boundaries.py`、`island/tools/architecture/legacy-dependencies.json`；更新 `docs/refactor/GOAL-TRACKER.md`、`DEPENDENCIES.md`、`OWNERSHIP.md`、`WINDOWS-MANUAL-TESTS.md` 和本文件。
- 具体实施：Windows service 单独负责 AppsFolder 枚举、图标和 ShellExecute；contract 仅传固定容量 app 值和带 ShellExecute code 的 launch result。Controller 持有 Launcher 页状态、滚动/选择、电源确认和 launch lifecycle generation，并拒绝同一呈现帧重复启动。Launcher Page 负责网格/list 几何、hover、clip、scroll 与 hit-to-Action；命中使用最近成功呈现的页面 snapshot，网格间隙无 hit。App 保留原有功能与页面视觉参数，失败启动留在页面并记录错误码，成功后按原行为收起。SystemToggles 改用平台 ShellCommand，去除对 Feature 的逆向依赖；Core CardLayout、Renderer、TextRenderer 移除 Launcher 专属路径，TextRenderer 使用通用 primitive。
- 编译/测试（Zig `0.17.0`，进程级 `ZIG_LIB_DIR=C:\Software\Loadout\store\zig\0.17.0\lib`）：最终 `zig build --summary all` 退出码 0，16/16 steps succeeded（IslandBar、Setup、native-smoke、thumbprobe、sysstatusprobe、geoprobe、gsmtcprobe）；新缓存 `zig build test --summary all` 退出码 0，45/45 build steps、56/56 tests passed；`zig fmt --check build.zig src` 退出码 0；bundled Python `tools/architecture/check_boundaries.py --report` 退出码 0：11 active legacy edges、0 新增、0 移除、0 未解析；`git diff --check` 退出码 0，仅 LF→CRLF 提示。无 `ENV_UNAVAILABLE`。
- 已发现并修复的真实错误：全量 build 捕获 Page/Controller 的同形匿名 payload 不是同一 Zig 类型，App 映射改为逐字段复制后 `zig build` 通过。此前测试编译还捕获固定数组初始化、union tag 断言和列表连续行测试假设错误；均修正并通过完整测试。主构建曾捕获 TextRenderer tray-menu 使用已移除字体字段，改接通用 page-body format 并重建成功。
- Windows 人工待测：`WIN-LAUNCHER-001`、`WIN-UI-001`、`WIN-INPUT-001`、`WIN-DPI-001`、`WIN-LIFECYCLE-001`、`WIN-ICON-001`、`WIN-SYSTEM-001` 全部 `MANUAL_PENDING`；涵盖真实 AppsFolder/图标/启动、网格与列表 hit/滚动/clip、启动失败、连点、DPI/多显示器、原生视觉、系统电源行为和生命周期。统一验收操作见 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。没有打开或声称操作 Windows GUI。
- 风险/未验证：无 Windows 原生 GUI/AppsFolder 图标或真实 ShellExecute 实测。纯逻辑测试覆盖网格间隙与 clip hit、launch error result 和同 frame 去重，但不能替代 Shell/系统状态/显示器验证。未出现需要标记 `ENV_UNAVAILABLE` 的可执行自动验证项。
- 回退方式：仅反向 S4-002：恢复 `features/StartApps.zig`、`features/StartMenu.zig` 与旧 `build.zig` module wiring；恢复 SystemToggles 对原 StartMenu 调用；在 CardLayout/Renderer/TextRenderer 恢复原 Launcher 几何、StartPage Painter/文字绘制；在 main 恢复旧 app/page state、命中与启动派发；删除本步新增的 LauncherCatalog、Controller、Page 和新平台文件；恢复 checker owner map/legacy edges；撤销本步 tracker、ownership、dependency、manual checklist 和本记录增量。保留 S0-S4-001 及其他后续改动，不重置整个工作区。
- 下游解锁：是。S4-003 Tray 继续实施；所有本步实机事项保持 `MANUAL_PENDING`，不阻塞后续步骤。

> 当前最早未完成步骤：`S4-003`。执行队列见 `docs/refactor/GOAL-TRACKER.md`；所有 Windows 实机项目统一维护在 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。

## [S4-003] Tray / 托盘窗口与菜单

- 日期 / 阶段：2026-10-15 / 阶段 4；依据 V2 S4-003 实施，架构文档保持 `PROPOSED`。
- 状态：`IMPLEMENTED`；自动验证 `AUTO_PASSED`；Windows 实机 `MANUAL_PENDING`。Tracker 已推进 S4-004 为 `IN_PROGRESS`；人工 GUI 操作不阻塞下游。
- 改动文件：`island/build.zig`；新增 `src/platform/contracts/TrayCatalog.zig`、`src/features/tray/Controller.zig`、`src/features/tray/ui/Page.zig`；更新 `src/platform/windows/TrayIcons.zig`、`TrayPress.zig`、`src/app/main.zig`、`src/core/CardLayout.zig`、`src/ui/Renderer.zig`、`TextRenderer.zig`、`tools/architecture/check_boundaries.py`、`legacy-dependencies.json`；更新 `docs/refactor/GOAL-TRACKER.md`、`DEPENDENCIES.md`、`OWNERSHIP.md`、`WINDOWS-MANUAL-TESTS.md` 和本记录。
- 具体改动：托盘枚举通过值契约提供 registration snapshot/revision；Feature Controller 独占菜单、选择、hover 和原有退出二次确认；TrayPage 负责布局/绘制/命中快照。Renderer、TextRenderer、CardLayout 的 Tray 专用菜单/网格/UI 分支已移出。App 只对最近成功呈现的页面几何执行 Action。图标 registration 变化会使旧菜单失效；菜单目标保存 HWND、PID、进程创建时间与路径，执行前重新校验窗口、PID、创建时间和完整 image path。TrayPress 按完整 exe 路径筛进程；legacy UID 若解析为多个不同 shell 矩形则拒绝，不猜测目标。
- 保持项：沿用旧 Tray 页/菜单尺寸、顺序、字体颜色、命中范围、刷新与开/关行为；保留 shell flyout UI Automation 实现和高影响退出二次确认。未改安装器、资源、smoke/probe 目标或架构文档状态。
- 自动验证（Zig 0.17.0，进程级 `ZIG_LIB_DIR=C:\Software\Loadout\store\zig\0.17.0\lib`）：`zig fmt build.zig src/features/tray/Controller.zig` 退出码 0；`zig fmt --check build.zig src` 退出码 0；全新缓存 `zig build test --summary all` 退出码 0，53/53 build steps、62/62 tests；`zig build --summary all` 退出码 0，16/16 steps（IslandBar、Setup 与 smoke/probe）；Python boundary checker 退出码 0，11 历史违规、0 新增、0 未解析；`git diff --check` 退出码 0（仅 Git 的 LF→CRLF 提示）。
- 已发现并修复的真实错误：首次将 TrayPress 单测接入后，测试构建发现 `iconRect` 内 legacy UID 分支局部变量 `matches` 重名；改为 `rect_matches` 后重新执行完整测试与构建成功。没有关闭测试或绕开编译错误。
- Windows 待测：`WIN-TRAY-001`、`WIN-UI-001`、`WIN-INPUT-001`、`WIN-DPI-001`、`WIN-ICON-001`、`WIN-LIFECYCLE-001` 继续 `MANUAL_PENDING`。真实 shell 枚举、同程序多实例、菜单点击、目标关闭/重启、视觉与动画未在原生 GUI 执行；细项统一见 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。未因无法操作原生窗口停止后续步骤，也无 `ENV_UNAVAILABLE`。
- 风险：Windows shell 的 legacy UID/窗口归属可能受第三方托盘程序影响；无法唯一判定的对象采取拒绝动作，可能降低可操作性。路径/创建时间/HWND 校验缩窄 PID reuse 风险，但真实退出/重启仍需人工验证。
- 回退：只回退 S4-003：在 `main.zig` 恢复旧 tray view/menu 映射、CardLayout 命中和 Renderer/TextRenderer 专用绘制分支；恢复 TrayIcons/TrayPress 到本步前行为与 Request 容量；移除 TrayCatalog/Controller/Page 模块及 build/test 接线；恢复 checker owner/legacy edge；撤销本步文档增量。保留 S0–S4-002 和其他已有更改，不重置整个工作区。
- 下游解锁：是。S4-004 Notification 按 V2 范围连续实施；Tray/GUI 实机项目保持 `MANUAL_PENDING`。

> 当前最早未完成步骤：`S4-004`。执行队列见 `docs/refactor/GOAL-TRACKER.md`；所有 Windows 实机项目集中在 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。

## [S4-004] Notification / ToastStore / WeChatWatch / Pipe

- 日期 / 阶段：2026-10-15 / 阶段 4；依照 V2 独立迁移通知边界，`docs/IslandBar-Architecture-V1.md` 状态仍为 `PROPOSED`。
- 实施状态：`IMPLEMENTED`；自动验证：`AUTO_PASSED`；Windows 实机：`MANUAL_PENDING`。Tracker 解锁 S4-005；原生 GUI、通知来源和音频设备运行不作为下游门禁。
- 改动文件：`island/build.zig`、`island/src/app/main.zig`、旧 `src/features/Notification.zig`（替代为 `src/features/notification/Controller.zig`）、新增 `src/features/notification/ui/Page.zig`、新增 `src/platform/contracts/NotificationInput.zig`、`src/platform/windows/NotificationPipe.zig`、`ToastStore.zig`、`WeChatAdapter.zig`（原 `features/WeChatWatch.zig`）、`NotificationIcon.zig`、`island/src/ui/Renderer.zig`、`TextRenderer.zig`、`island/tools/architecture/check_boundaries.py`、`legacy-dependencies.json`、`island/tools/jsonprobe/main.zig`、`docs/refactor/GOAL-TRACKER.md`、`DEPENDENCIES.md`、`OWNERSHIP.md`、`WINDOWS-MANUAL-TESTS.md` 和本记录。旧 Feature 文件路径由新职责路径替代。
- 所有权与行为：Notification Feature Store 唯一持有通知历史、未读、按来源身份去重/撤销和有效期；`NotificationInput` 是固定容量值契约，保留既有 Pipe JSON 字段/值；Pipe、Windows Toast、WeChat adapters 输出契约值/事件，不导入 Feature Store。Shell 的 `PresentationPolicy` 继续决定通知抢占优先级与恢复。Feature `NotificationPage` 接管 NoticeStrip/Card 专用 View 与卡片排版/绘制回调；通用 Renderer/TextRenderer 使用通用 painter、卡片文本/图像 primitives。原卡片 clock/divider、文案偏移、字体尺寸和 NoticeStrip 行为保持。
- 已移除旧依赖：`NotificationPipe → Notification`、`Renderer → Notification`、NotificationIcon 的 MusicSession/WicImage/Log 和 WeChatWatch → Log 边已从 allowlist 收敛；检查现有 6 条其他历史债务，`0 new / 0 removed / 0 unresolved`。
- 首轮主构建发现真实错误：`main.zig` 的 WeChat 轮询可选值捕获未使用；改为只检查 Notification Store 是否存在后重建通过。该错误已修复，不作为环境限制。
- 自动验证：`zig build test --summary all` 退出码 0，63/63 build steps、67/67 tests；`zig build --summary all` 16/16；`zig build setup-build --summary all` 4/4；`native-smoke-build`、`thumbprobe-build`、`sysstatusprobe-build`、`geoprobe-build`、`gsmtcprobe-build` 各 2/2。修改 Zig 文件 `zig fmt --check` 退出码 0；`python tools/architecture/check_boundaries.py --report` 退出码 0，6 历史、0 新增、0 未解析；`git diff --check` 退出码 0（仅 LF→CRLF 提示）。Zig 0.17.0 需要获准访问本机 Zig lib/Windows SDK 并设置进程级 `ZIG_LIB_DIR`；此处并非 `ENV_UNAVAILABLE`。
- Windows 人工待测：`WIN-NOTIFY-001`，包括 Pipe wire 兼容、快速/重复通知、来源身份去重/撤销、Toast/WeChat 来源变化、卡片抢占/恢复、历史标记已读与图标缺失回退；统一清单具备步骤/预期/风险，状态仍为 `MANUAL_PENDING`。
- 风险 / 未验证：未运行 IslandBar Windows 窗口、系统通知、WeChat 窗口/音频设备、真实图标查询及 DPI/动画实测。纯 Zig 测试不代表上述路径通过。未发现可执行的自动验证因缺工具链无法运行。
- 回退：只反向 S4-004：恢复 `Notification.zig`、`ToastStore.zig`、`WeChatWatch.zig`、`NotificationIcon.zig` 原路径及 `build.zig` wiring；撤回 `NotificationInput`/Feature Page 接入、Pipe/Main/Renderer 适配和本步 allowlist 变化；恢复 S4-004 前的通知消费逻辑。撤销本步 tracker/ownership/dependency/manual 清单和记录增量；保留 S1–S4-003，不重置整个工作区。
- 下游解锁：是；编译、测试和依赖检查通过，GUI/来源实机待测不阻塞 S4-005。

> 当前最早未完成步骤：`S4-005`。所有 Windows 实机项目统一维护在 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。

## [S4-005] Taskbar / WindowList / NativeTaskbar / Thumbnail

- 日期 / 阶段：2026-10-15 / 阶段 4；V2 实施继续推进，架构文档状态保持 `PROPOSED`。
- 实施状态：`IMPLEMENTED`；自动验证：`AUTO_PASSED`；Windows 实机：`MANUAL_PENDING`。Tracker 解锁 S4-006；原生窗口/动画/多显示器测试不作为下游门禁。
- 改动文件：`island/build.zig`；`island/src/app/main.zig`；`island/src/platform/contracts/TaskbarCatalog.zig`、`Thumbnail.zig`；`island/src/platform/windows/WindowList.zig`、新增 `ThumbnailAdapter.zig`；`island/src/features/taskbar/Controller.zig`、`ui/Layout.zig`、`ui/Page.zig`、`ui/ThumbnailLayout.zig`；新增 `island/src/ui/TaskbarPresentation.zig`；更新 `island/src/ui/Renderer.zig`、`TextRenderer.zig`、`core/InputRegion.zig`、`core/CardLayout.zig`；`core/TaskStripLayout.zig` 改为共享控件布局 `core/BarControlLayout.zig`；`docs/refactor/GOAL-TRACKER.md`、`DEPENDENCIES.md`、`OWNERSHIP.md`、`WINDOWS-MANUAL-TESTS.md` 和本记录。原 `ui/ThumbnailPreview.zig` 移至 Windows 平台适配器，几何计算移到 Taskbar UI。
- 具体改动：WindowList 按窗口 HWND、PID 和进程创建时间匹配稳定实例 ID/revision；Controller 按 ID 拥有快照、hover 与动画量，并拒绝过时代际 Action；执行激活/最小化及 DWM 预览前复核目录代际与实例身份。Taskbar Page 生成值型呈现视图，Renderer 绘制、点击、hover、缩略图锚点与 InputRegion 均消费同一成功呈现几何；icon cache 以稳定窗口实例匹配并在实例移除/替换后清理。Taskbar 行 layout 已迁入 Feature；共享 Core 保留 Start/System/Tray/status 控件几何。缩略图像素合同为平台无关值，Windows Adapter 管理 DWM/GDI/HWND，纯布局留在 Feature。
- 保持项：按钮顺序、尺寸、间距、hover 展宽/标题、任务按钮激活/前台最小化和预览样式沿用既有实现；未更改 UI 视觉、窗口枚举过滤、安装器/资源/probe 源码或架构文档。安装器和 probe 仅编译，未运行安装器或执行系统级 probe。
- 自动验证：`zig fmt --check build.zig src` 退出码 0；新临时缓存 `zig build test --summary all` 退出码 0，77/77 steps、76/76 tests；`zig build --summary all` 16/16 steps；单独 `zig build setup-build --summary all` 4/4，`native-smoke-build`、`thumbprobe-build`、`sysstatusprobe-build`、`geoprobe-build`、`gsmtcprobe-build` 各 2/2；`python tools/architecture/check_boundaries.py --report` 退出码 0，6 条历史边、0 新增、0 删除、0 未解析；`git diff --check` 退出码 0（Git 提示工作区 LF 将按 core.autocrlf 转换为 CRLF）。第一次新缓存运行中有 2 个测试目标暂时报告 Zig stdlib 文件读取 `Unexpected`，同缓存重试和另一新缓存全量重跑均成功；无代码失败被跳过，未标 `ENV_UNAVAILABLE`。
- 自动测试覆盖：Taskbar Page 同一按钮 bounds 绘制/点击/hover 与 gap 保持；Controller 覆盖稳定身份、过时 revision、窗口消失和重排后动画继承；WindowList 覆盖 HWND/PID/创建时间区分；Taskbar 几何覆盖宽度 fit/hit；ThumbnailLayout 覆盖宽高比和显示器边缘；BarControl/Layout/InputRegion/Renderer 完整编译。自动测试不证明真实 Windows DWM/输入行为。
- Windows 实测：`WIN-TASKBAR-001`（列表/激活/最小化/重排/预览/HWND 自然重用）、`WIN-INPUT-001`、`WIN-DPI-001`、`WIN-UI-001`、`WIN-ICON-001` 均 `MANUAL_PENDING`，统一步骤、预期和风险见 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。没有尝试启动 GUI 或安装程序。
- 风险 / 未验证：本地未取得真实 DWM 预览、Windows 窗口创建/销毁竞态、实际 HWND 重用、动画点击、DPI/负坐标/多屏证据；若 OS 不允许读取进程创建时间，服务会拒绝不确定的激活/预览请求，仍需实机观察其反馈。所有这些均不阻塞下游。不存在未运行的可用编译/静态/纯 Zig 单测目标。
- 回退方式：只反向 S4-005。恢复 `TaskStripLayout.zig` 原共享/任务行布局，再恢复各模块的旧 import 和 build wiring；删除本步新增 `TaskbarPresentation`、Taskbar UI/Controller 与 Thumbnail contract/layout/adapter，并恢复原 `ThumbnailPreview.zig` 路径/API；撤回 TaskbarCatalog identity、WindowList 校验、Renderer cache key 与 Main 的 presented view 接线。撤回 S4-005 的 tracker、所有权、依赖、人工测试和本记录增量；保留 S0 至 S4-004 与其他用户改动，不 reset 工作区。
- 下游解锁：是。Tracker 下一步 `S4-006`；Windows GUI 与设备验收集中留待后续人工完成。

> 当前最早未完成步骤：`S4-006`。所有 Windows 原生 GUI、设备、多 DPI、多显示器、动画点击、系统托盘和音频相关实测统一维护于 `docs/refactor/WINDOWS-MANUAL-TESTS.md`，`MANUAL_PENDING` 不阻塞重构。

## [S4-006] System Panel / Status / Toggles / Brightness

- 日期 / 阶段：2026-10-15 / 阶段 4；依 V2 单边界迁移，`docs/IslandBar-Architecture-V1.md` 状态保持 `PROPOSED`。
- 实施状态：`IMPLEMENTED`；自动验证：`AUTO_PASSED`；Windows 实机：`MANUAL_PENDING`。Tracker 已解锁 S4-007；系统 GUI/权限/真实显示器/无线设备测试不阻塞下游。
- 改动文件：`island/build.zig`、`island/src/app/main.zig`、`island/src/core/CardLayout.zig`、新增 `island/src/features/system/Controller.zig`、`features/system/ui/Layout.zig`、`features/system/ui/Page.zig`、新增 `island/src/platform/contracts/SystemStatus.zig`、新增 `island/src/platform/windows/SystemService.zig`、`island/src/platform/windows/SystemStatus.zig`、新增 `island/src/ui/SystemPanelPresentation.zig`、`island/src/ui/TextRenderer.zig`、`docs/refactor/GOAL-TRACKER.md`、`DEPENDENCIES.md`、`OWNERSHIP.md`、`WINDOWS-MANUAL-TESTS.md` 和本记录。
- 架构改动：Windows status snapshot 改由纯值 contract 定义，System Feature Controller 唯一拥有状态、键盘布局数、亮度能力/已确认值和分页位置；System Page 创建只含显示值的 render DTO 与独立语义 Action；System 专属 tile/slider/page layout 和 HitTest 已从 Core 迁到 System UI。TextRenderer 只读 `SystemPanelPresentation.View`，不含 Feature Action、不读取 Windows 状态。App 通过 `SystemService` 封装调用状态读取、异步 radio/night-light/captions 操作和亮度 adapter。
- 行为/资源：按钮顺序、tile 文案、颜色 token、卡片和 slider 几何、分页顺序及设置 URI 保持。radio/night-light 不先乐观修改状态，结果到达后重新采样；亮度只有 DDC/CI 写入并读回成功才更新权威状态。没有电源动作；能力不可用只隐藏亮度 slider，其他面板仍构建。DDC/CI 仍按既有周期在 UI 线程同步采样，需通过 `WIN-PERF-001` 与 `WIN-SYSTEM-001` 实机观察其耗时。
- 自动验证：Zig `0.17.0`。`zig fmt --check build.zig src` 退出码 0；`zig build test --cache-dir .zig-cache-s4-006 --summary all` 最终退出码 0、85/85 build steps；`zig build --cache-dir .zig-cache-s4-006 --summary all` 16/16；`setup-build` 4/4；`native-smoke-build`、`thumbprobe-build`、`sysstatusprobe-build`、`geoprobe-build`、`gsmtcprobe-build` 分别 2/2、退出码 0。依赖守卫退出码 0：6 条登记历史边、0 新增/移除/未解析。`git diff --check` 退出码 0，只有 Git `core.autocrlf` 的 LF→CRLF 提示。
- 自动测试覆盖：`SystemController` 2 tests（拒绝未确认的亮度变化、无能力降级）；`SystemLayout` 1 test（同一 tile/slider bounds 进行绘制与命中、gap 不命中）；`SystemPage` 3 tests（tile 顺序/分页 Action、亮度 slider 局部降级、输入法与电池能力格式）；status Contract 1 test。首次全新测试缓存有一次 Zig stdlib `std/hash_map.zig: Unexpected`（AudioService 测试编译读库失败），同缓存重试后 85/85 成功；源码失败未被跳过或标成环境缺失。
- Windows 人工待测：`WIN-SYSTEM-001`、`WIN-INPUT-001`、`WIN-DPI-001`、`WIN-PERF-001` 均 `MANUAL_PENDING`，操作、预期与恢复要求统一在 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。未启动 IslandBar GUI，未调整系统设置、无线电、夜间模式、字幕或电源。
- 风险 / 未验证：未实测 Windows WLAN/Bluetooth/Live Captions/Night Light 权限与异步结果、DDC/CI 对不同显示器的读回、原生分页动画/命中、DPI/多屏；这些均为手工待测，不代表自动验证失败。历史静态债务仍 6 条且无新增。
- 回退方式：仅撤回 S4-006：恢复 `CardLayout` 中的 SystemPanel 几何/命中及旧 smoke test；恢复 `main.zig` 直接的 SystemPanel tile/状态分页/平台操作接线和旧 `TextRenderer.SystemPanelText`/`PanelAction` DTO；撤回 build module/test wiring，移除本步新建的 System Feature、status contract、SystemService 和 Presentation 文件；恢复 SystemStatus 中搬出的 UI helpers；撤回本步 tracker、ownership、dependency、manual 清单增量和本记录。保留 S0–S4-005 及其他用户改动，不 reset 工作区。
- 下游解锁：是。自动测试、完整 Windows 应用/安装器/probe 构建、格式和边界检查通过；`MANUAL_PENDING` 的系统实测不阻塞 S4-007。

> 当前最早未完成步骤：`S4-007`。Weather 按 V2 接续实施；所有原生 GUI、真实设备和多显示器项目集中维护在 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。

## [S4-007] Weather / 数据源与天气卡片

- 日期 / 阶段：2026-10-15 / 阶段 4；按 V2 分离平台数据来源、Feature 状态和展示贡献；`docs/IslandBar-Architecture-V1.md` 仍为 `PROPOSED`。
- 实施状态：`IMPLEMENTED`；自动验证：`AUTO_PASSED`；Windows 实机：`MANUAL_PENDING`。Tracker 解锁 S5-001；没有以 GUI/网络设备测试作为阻塞。
- 改动文件：`island/build.zig`、`island/src/app/main.zig`、删除旧 `island/src/features/Weather.zig`、新增 `island/src/platform/contracts/WeatherData.zig`、`island/src/platform/windows/WeatherService.zig`、`island/src/features/weather/Controller.zig`、`island/src/features/weather/ui/Page.zig`、`island/src/ui/StatusLineWeather.zig`、`island/src/ui/Renderer.zig`、`island/src/ui/TextRenderer.zig`、`island/tools/architecture/legacy-dependencies.json`、`docs/refactor/GOAL-TRACKER.md`、`DEPENDENCIES.md`、`OWNERSHIP.md`、`WINDOWS-MANUAL-TESTS.md` 和本记录。
- 架构改动：WinHTTP/Windows Location、解析、串行后台轮询与 last-good transport cache 归 `WeatherService`；跨层快照 `WeatherData.SourceSnapshot` 为纯值。Weather Controller 按 revision 接收快照、保留 last-good、拒绝旧 revision，并提供 unavailable/fresh/cached/stale 健康状态；缓存超过 30 分钟被标记 stale。天气设置在网络请求期间变化时，服务丢弃旧设置的响应。天气文案、WMO 图标映射、摄氏度格式化由 Weather Page 产生 `StatusLineWeather.View`；Renderer/TextRenderer 已无 Weather Feature/Service import，绘制/命中路径不发起同步请求。旧 Weather 模块及三条对应历史 allowlist 边已移除。
- 行为保持：首次立即请求；15 分钟轮询、失败 1 分钟重试；网络/字段失败保留旧成功值；无数据仅天气段为空，不影响时钟/其他 Feature。原中文标签、未知 code 只显示温度、温度四舍五入、字体/标记、状态栏位置与行宽算法保持。陈旧状态只作为内部健康元数据，不改现有外观。
- 自动验证（Zig 0.17.0，进程级 `ZIG_LIB_DIR=C:\Software\Loadout\store\zig\0.17.0\lib`）：`zig build test --cache-dir .zig-cache-s4-007 --summary all` 退出码 0，91/91 build steps，5/5 Weather tests passed；`zig build --cache-dir .zig-cache-s4-007 --summary all` 16/16（IslandBar、安装器、全部 smoke/probe）；`zig fmt --check build.zig src` 退出码 0；`python tools/architecture/check_boundaries.py --report` 退出码 0，3 条历史边、0 新增、0 未解析；`git diff --check` 退出码 0，只有 Git `core.autocrlf` LF→CRLF 提示。首次全量测试遇到一次与天气无关的 Zig stdlib `ErrorBundle.zig: Unexpected` 文件读取，使用同一缓存重试成功；没有隐藏或跳过源码错误。此前真实的 `@memcpy` 数组源类型错误已按编译器反馈修复后重跑构建。
- 自动测试覆盖：Service 测试拒绝缺字段/非有限温度；Controller 测试 revision 单调、失败保留 last-good、陈旧时间和高 revision/旧 success time 不覆盖较新读数；Page 测试中文标签、温度格式与未知 code 降级。Renderer smoke build 保持不同状态图标呈现入口。
- Windows 人工待测：`WIN-WEATHER-001`、`WIN-UI-001`、`WIN-LIFECYCLE-001`、`WIN-PERF-001` 仍 `MANUAL_PENDING`；步骤、预期结果及恢复条件统一在 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。实际 WinHTTP、Windows Location 权限、网络离线/恢复、屏幕视觉与刷新节奏未执行；未启动 IslandBar GUI。
- 风险 / 未验证：30 分钟 stale 阈值是 Feature 状态元数据；UI 为保留当前设计会继续显示 last-good 值。外部配置在一次请求的最终提交前通过重读设置校验；系统位置源没有城市配置代际，后台单 worker 保证请求串行。真实服务行为/超时由 `WIN-WEATHER-001` 人工观察。未发现其他自动验证不可用项，`ENV_UNAVAILABLE`：无。
- 回退方式：只回退 S4-007：恢复步骤前的 `features/Weather.zig` 与 `build.zig` 中原 Weather 模块/测试关系；移除本步新增 WeatherData/WeatherService/WeatherController/WeatherPage/StatusLineWeather；在 `main.zig`、Renderer、TextRenderer 恢复 WeatherReader 和旧状态栏参数；恢复 allowlist 中原三条 Weather 边；撤回本步 tracker、ownership、dependency、manual 清单和日志增量。保留 S0–S4-006 及其他更改，不 reset 工作区。
- 下游解锁：是。Tracker 下一步 S5-001；Windows 手测保持 `MANUAL_PENDING`。

## [S5-001] App Runtime 与 WindowHost 生命周期

- 日期 / 阶段：2026-10-15 / 阶段 5；按 V2 收缩入口初始化和运行时资源所有权；`docs/IslandBar-Architecture-V1.md` 继续保持 `PROPOSED`。
- 实施状态：`IMPLEMENTED`；自动验证：`AUTO_PASSED`；Windows 实机：`MANUAL_PENDING`。Tracker 已解锁 S5-002；窗口交互/设备验收不阻塞后续。
- 改动文件：新增 `island/src/app/Runtime.zig`、`island/src/app/WindowHost.zig`；更新 `island/src/app/main.zig`、`island/build.zig`；更新 `docs/refactor/GOAL-TRACKER.md`、`OWNERSHIP.md`、`DEPENDENCIES.md`、`WINDOWS-MANUAL-TESTS.md` 和本记录。
- 具体实施：`AppRuntime.Runtime` 统一启动/停止通知 Pipe、GSMTC、歌词、播放器窗口、系统状态、主音量、音频输出和天气 worker，并拥有托盘图标目录与 Launcher 服务资源。退出时按启动逆序释放 Launcher/Tray，再停止天气、Sound/Audio、状态读取、播放器、歌词、音乐和通知 worker；Sound controller port 指向稳定的 Runtime 字段。`AppWindowHost.WindowHost` 持有监视器尺寸/DPI、原生窗口和 AppBar 注册，封装窗口初始化、AppBar 回收、窗口销毁及消息循环。入口只组装 Feature/绘制上下文并把现有回调接到 Host；Feature 状态仍由各自 Controller 所有，未改 UI 外观或交互。
- 编译/测试：Zig `0.17.0`，进程级 `ZIG_LIB_DIR=C:\Software\Loadout\store\zig\0.17.0\lib`。`zig build --cache-dir .zig-cache-s5-001 --summary all` 退出码 0，16/16 steps（IslandBar、安装器和所有 smoke/probe）；`zig build test --cache-dir .zig-cache-s5-001 --summary all` 退出码 0，91/91 build steps，86/86 个用例通过；`zig fmt --check build.zig src` 退出码 0；bundled Python `tools/architecture/check_boundaries.py --report` 退出码 0，3 条登记历史边、0 新增/未解析；`git diff --check` 退出码 0，仅 Git LF→CRLF 提示。无 `ENV_UNAVAILABLE`。
- 已发现并修复的真实构建错误：第一次拆 Host 时两处窗口指针层级不匹配；修复后完整构建通过。Runtime 纳入 Tray/Launcher 后，显式 build import 清单缺两个模块；已补齐并重跑完整构建。测试期间首次出现 Zig 标准库 `WindowsSdk.zig: Unexpected` 文件读取错误，同缓存重试后全量 suite 通过；它没有被记作源码通过或 SDK 缺失。
- Windows 人工待测：`WIN-LIFECYCLE-001`、`WIN-UI-001`、`WIN-INPUT-001`、`WIN-DPI-001`、`WIN-PERF-001` 保持 `MANUAL_PENDING`。真实窗口启动/关闭、D2D 资源代际、动画点击、多 DPI/多显示器和长期资源趋势统一见 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。未打开 GUI，也没有声称实测通过。
- 风险 / 未验证：`PaintContext` 和 Win32 消息/Feature Action 桥接仍是 App UI 线程组合对象；本步只把长期运行服务与窗口/AppBar 所有权提取到职责模块，未把 Feature callback 机械拆散或复制状态。真实 COM/GPU/窗口 teardown 顺序仍需 `WIN-LIFECYCLE-001` 验收。
- 回退方式：仅反向 S5-001：恢复 `main.zig` 中原 Runtime worker、Tray/Launcher 初始化/销毁和窗口/AppBar/message-loop 实现；移除 `AppRuntime`、`AppWindowHost` 模块及 build wiring；恢复 `OWNERSHIP.md`/`DEPENDENCIES.md` 中对应 App 资源归属、manual checklist 的旧替代说明、tracker 状态和本记录增量。保留 S0–S4 的实现及其他用户改动，不重置工作区。
- 下游解锁：是。自动构建、测试、格式与依赖检查已通过；所有 Windows 实测保持 `MANUAL_PENDING`。

## [S5-002] Renderer、旧布局与显式构建依赖审查

- 日期 / 阶段：2026-10-15 / 阶段 5；按 V2 审核旧 UI/Platform 边界和剩余静态债务；架构文档保持 `PROPOSED`。
- 实施状态：`IMPLEMENTED`；自动验证：`AUTO_PASSED`；Windows 实机：`MANUAL_PENDING`。Tracker 已解锁 S5-003；截图、DPI、安装器实测不阻塞。
- 改动文件：将 `island/src/ui/IslandWindow.zig` 移为 `island/src/platform/windows/IslandWindow.zig`；更新 `island/build.zig`、`island/tools/architecture/legacy-dependencies.json`、`docs/refactor/GOAL-TRACKER.md`、`DEPENDENCIES.md`、`OWNERSHIP.md`、`WINDOWS-MANUAL-TESTS.md` 和本记录。
- 具体实施：IslandWindow 实现直接使用 Win32 HWND/message、AppBar 和 Monitor API，现归 Windows Platform；保留命名模块名/导入别名和所有既有调用，构建入口改为新源码位置。复查发现 Renderer/TextRenderer 已无 Feature 实现导入；CardLayout 为通用卡片几何，旧 TaskStripLayout 已在 S4-005 被 BarControlLayout/Taskbar UI 替代；安装器、资源、smoke/probe build steps 继续保留。静态 legacy debt 从 3 条收敛至 2 条。
- 保留债务与理由：`Renderer → WicImage` 需要现有 WIC PNG 解码、编码和模糊背景辅助；`TextRenderer → WicImage` 需要将调用方 PNG bytes 解码为同线程 D2D bitmap cache。两条都只服务 Windows 图像像素适配，Feature 不经由 Renderer 调用；当前 `WicImage.DecodedImage` 只暴露像素值/调用方缓冲，没有 COM interface 泄漏。若后续加注入式 codec contract，应单独审计资源/线程成本，不能为清空 allowlist 引入万能接口。
- 编译/测试：Zig `0.17.0` + 进程级 `ZIG_LIB_DIR`。`zig build --cache-dir .zig-cache-s5-002 --summary all` 退出码 0，16/16 steps（应用、安装器、native-smoke、thumbprobe、sysstatusprobe、geoprobe、gsmtcprobe）；`zig build test --cache-dir .zig-cache-s5-002 --summary all` 退出码 0，91/91 build steps、86/86 个用例通过；`zig fmt --check build.zig src` 退出码 0；依赖扫描退出码 0，2 条已登记历史 WIC 边、0 新增、0 未解析；`git diff --check` 退出码 0（仅 LF→CRLF 提示）。无 `ENV_UNAVAILABLE`。首次测试运行的 Zig stdlib `Target/alpha.zig: Unexpected` 文件读取错误在同缓存重试后消失；全部测试均执行。
- Windows 人工待测：`WIN-UI-001`、`WIN-DPI-001`、`WIN-LIFECYCLE-001`、`WIN-SETUP-001` 保持 `MANUAL_PENDING`；原生 D2D 视觉、DPI/多屏、窗口 teardown 和真实安装流程统一见 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。未启动 GUI 或运行安装器。
- 风险 / 未验证：2 条 WIC 静态依赖仍是 UI Foundation 到 Windows codec 的有界例外；真实 D2D bitmap cache 与 Windows Imaging Component 生命周期尚未原生验证。历史 `DEPENDENCIES.md` 快照被明确标记为历史，并补充当前边界状态。
- 回退方式：仅反向 S5-002：将 `IslandWindow.zig` 移回 `src/ui/`；恢复 `build.zig` 的原 source path 和 `legacy-dependencies.json` 中 IslandWindow→AppBar 例外；撤回本步 tracker、依赖/所有权/manual 文档和本记录增量。保留 S5-001 与此前全部步骤，不重置工作区。
- 下游解锁：是。完整构建、测试、格式和边界检查通过；有理由的 WIC 边已登记，不以 GUI 手测阻塞 S5-003。

> 当前最早未完成步骤：`S5-003`。完成诊断/维护性回归、最终完整验证与最终报告；Windows 实测仍统一见 `docs/refactor/WINDOWS-MANUAL-TESTS.md`。

## [S5-003] 诊断、自动回归与最终验收

- 日期 / 阶段：2026-10-15 / 阶段 5；依据 V2 完成自动诊断和维护性依赖复核；架构文档状态仍为 `PROPOSED`。
- 实施状态：`IMPLEMENTED`；自动验证：`AUTO_PASSED`；Windows 实机：`MANUAL_PENDING`。全 Goal 达到 `IMPLEMENTATION_COMPLETE_MANUAL_PENDING`，20/20 代码步骤完成。
- 改动文件：更新 `island/src/app/Diagnostics.zig`、`island/src/app/main.zig`；新增 `docs/refactor/FINAL-REPORT.md`；更新 `docs/refactor/GOAL-TRACKER.md`、`WINDOWS-MANUAL-TESTS.md`、本文件。
- 具体实施：添加默认关闭的 `ISLANDBAR_TRACE_UI=1` 跟踪日志，不创建堆分配或常开采样。InputRouter 的 Sound slider Action 日志使用 Controller token 作为 OperationId，记录 ElementId/index、presented Layout generation、client-local DIP bounds/hit region/surface/content clip、屏幕原点、DPI/比例、帧耗时、Action/dispatch、Controller revision 和 Renderer resource generation；AudioVolume/AudioService 结果用同 token 记录 operation、applied/stale disposition、HRESULT 与更新后的 Controller revision。新增格式化诊断单测。复核维护边界：Music 样式由 `features/music/ui/Page.zig` 为主，Sound 几何由 `features/sound/ui/Page.zig`/`MixerSlider.zig`，卡片优先级由 `shell/PresentationPolicy.zig`，媒体/音频适配分别由 `platform/windows/MediaService.zig`、`AudioService.zig`/`AudioVolume.zig`；这是基于显式模块依赖的维护性检查，没有伪造临时产品改动。
- 编译/测试：Zig `0.17.0` + `ZIG_LIB_DIR=C:\Software\Loadout\store\zig\0.17.0\lib`。`zig build --cache-dir .zig-cache-s5-003 --summary all` 退出码 0，16/16 steps；`zig build test --cache-dir .zig-cache-s5-003 --summary all` 退出码 0，91/91 build steps、88/88 tests；`zig fmt --check build.zig src` 退出码 0；`tools/architecture/check_boundaries.py --report` 最终 2 条有理由的历史 WIC 边、0 新增、0 未解析，退出码 0；`git diff --check` 退出码 0（仅 CRLF 提示）。无 `ENV_UNAVAILABLE`、无 `BUILD_PENDING`。S5-001/S5-002 两次首次测试都遇到 Zig stdlib 文件读取 `Unexpected`，各自在同缓存重试通过；S5-003 最终全套一次通过。
- Windows 人工待测：`docs/refactor/WINDOWS-MANUAL-TESTS.md` 共 20 项，全部 `MANUAL_PENDING`；包含 GUI 视觉/输入、动画、多 DPI/多屏、托盘、音频/媒体设备、系统服务、天气网络、长期稳定性和安装器真实运行。没有打开 IslandBar 窗口或运行安装器，也没有声称人工验收通过。
- 风险 / 未验证：跟踪只在显式启用时记录当前通用 InputRouter/Sound slider 与音频操作路径；其他 Feature action 沿用各自已有 generation/revision/error 规则，未新建全局事件总线。WIC 两条例外、App 的主窗口输入/Feature 适配代码仍需未来按独立边界治理；D2D/WIC、窗口和真实设备表现要在 Windows 清单验收。无性能基准变化声明。
- 回退方式：仅反向 S5-003：移除 `ISLANDBAR_TRACE_UI` 开关、PaintContext 的 trace/frame 字段、`traceInputAction`/`traceSoundResult` 调用和 Diagnostics 的 trace formatter/test；删除最终报告并恢复本步 tracker/manual/AGENTS 增量。保留 S5-001/S5-002 和 S0–S4 代码，不重置工作区。
- 最终状态：`IMPLEMENTATION_COMPLETE_MANUAL_PENDING`。没有 `ENV_UNAVAILABLE` 自动构建项；20 项 Windows 实测集中待验。`docs/refactor/FINAL-REPORT.md` 汇总代码、验证和维护边界；后续只需集中完成人工清单，人工结果不得回填为自动验证。

> 当前代码实施队列无未完成步骤。Windows 验收集中在 `docs/refactor/WINDOWS-MANUAL-TESTS.md`，20 项均为 `MANUAL_PENDING`。
