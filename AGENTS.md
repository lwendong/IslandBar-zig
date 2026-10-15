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
| 0. 构建与回归基线 | **进行中** | 静态依赖守卫和全部指定 Zig 构建目标已验证通过；Windows UI 人工回归仍未验证 |
| 1. 所有权与模块契约 | 未开始 | 先梳理 State/Action/Contract，不批量移动文件 |
| 2. 高风险修复与 UI 底座 | 未开始 | 需验证 D2D 生命周期、布局/命中一致性 |
| 3. SoundPage 试点 | 未开始 | 后续单独授权和分批实施 |
| 4. 其他 Feature 迁移 | 未开始 | 按验证后的依赖顺序 |
| 5. 清理旧架构与规则固化 | 未开始 | 删除旧路径前需证明已替代 |

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

## 下一位 Codex 执行者的任务

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
