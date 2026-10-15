# IslandBar 渐进重构：阶段 0 静态基线

> 快照日期：2026-10-15  
> 来源：用户提供的 `res.zip`（SHA-256: `79906ef073b56f564affb9c069564679df4cbe98868d1a5b8da3fdc7e08d9c3e`）  
> 设计依据：`docs/IslandBar-Architecture-V1.md`（目标架构，状态仍为 PROPOSED）  
> 验证级别：**当前工作区静态依赖检查和指定 Windows Zig 构建目标均通过；UI 交互尚未验证。**

> 目录说明：本文件中的 `build.zig`、`src/`、`setup/`、`tools/`、`res/` 路径均相对于仓库的 `island/` 代码根目录。

## 当前工程范围

- 现有工程包含 41 个 `src/**/*.zig` 源码文件，约 24,755 行；`build.zig` 注册了 40 个命名源码模块。
- `src/app/main.zig` 约 3,991 行，混合入口、`PaintContext`、窗口绘制回调、Sound UI 文案构造、点击处理、系统操作。
- `src/ui/Renderer.zig` 约 1,503 行；`src/ui/TextRenderer.zig` 约 2,493 行，均存在具体 Feature 依赖。
- `src/features/SoundOutput.zig` 与 `src/features/NotificationIcon.zig` 使用 `MusicSession.fetchAppIconForTest`，形成跨 Feature 实现耦合。
- `src/platform/windows/SystemToggles.zig` 直接导入 `StartMenu`；`src/platform/windows/NotificationPipe.zig` 直接导入 `Notification`。
- `src/ui/Renderer.zig` 中 `nextCardOwner` 判断卡片显示优先级，主入口调用它；按目标架构，此策略最终应归 Shell。
- `src/core/CardLayout.zig`、`src/core/TaskStripLayout.zig` 等仍承担具体页面布局职责。此类**职责错误**不能仅用 import 扫描脚本发现，需要后续人工/实机检查。

## 依赖边界基线

`tools/architecture/check_boundaries.py` 使用 `build.zig` 中现有命名模块映射，扫描 Zig 文件的 `@import("...")`。

当前基线为 **21 条旧跨层依赖**，详见 `tools/architecture/legacy-dependencies.json`。这个数字只是脚本规则下的**静态依赖边**，不是已证实的 21 个运行时 bug，也不是完整的架构问题数量。

默认执行时：旧依赖继续允许，新增违例返回非零错误码；旧依赖删除后会提示已消除。**不要通过修改白名单掩盖新依赖。** 基线更新必须在变更审查后显式执行 `--record-baseline`。

脚本检测不到 Zig `extern` 调用、运行时全局变量、通过参数传递的资源所有权和 UI 命中公式重复等问题；它也不判断代码实际是否有缺陷。

## Windows 实机验证清单

以下命令已在当前 Windows 工作区执行，结果见文末复核记录；UI 清单仍待实际操作：

1. `zig version`；核对 `START-HERE.txt` 所称 Zig 0.17 是否与本机一致（文件所述版本尚未通过本轮命令验证）。
2. `zig build`；记录返回码、输出产物路径、错误原文。
3. `zig build setup-build`；确认安装器构建仍可用，**不要自动运行安装或修改系统任务栏设置**。
4. `zig build native-smoke-build`、`zig build thumbprobe-build`、`zig build sysstatusprobe-build`、`zig build geoprobe-build`、`zig build gsmtcprobe-build`；仅先编译，不强制运行可能修改系统状态的 probe。
5. `python tools/architecture/check_boundaries.py --report`；如果 Python 不可用，记录环境缺口，不影响主程序编译。
6. 手动记录收起/悬停/展开、音乐、声音、通知、托盘、启动菜单、任务按钮、动画中点击、DPI/多屏的**实际**行为；屏幕截图要明确版本和复现步骤。
7. 分别记录 `zig-out/bin/IslandBar.exe` 与 `zig-out/bin/IslandBarSetup.exe` 的产物是否由本轮构建生成；压缩包中的既有二进制文件不能充当本轮编译验证。

## 已知环境与材料缺口

- 初始离线分析环境没有 `zig` 可执行文件，也无法进行 Win32 GUI 实机回归；当时尚未证明源代码可编译。当前 Windows 编译结果见文末复核记录。
- `START-HERE.txt` 指向 `README.md` 与 `TESTING.md`，但两者不在本轮 `res.zip` 中；请在实际工作目录核对，不要擅自虚构内容。
- `res.zip` 内带有以前的 `zig-out` 产物和日志。日志仅能反映先前运行，不等于本轮状态。
- 初始独立提供的 `AGENTS.md` 内容仅为 `111`，没有有效可追溯进度。本阶段将其替换为结构化记录，后续 Codex 每次改动都应追加更新。

## 阶段 0 范围和下一步

本阶段**不改动生产 Zig 源码、运行行为、UI、安装器与 build.zig**。只增加依赖审计和重构记录。完成 Windows 构建/人工基线后进入阶段 1：确定 State/Action/Service Contract 的权威归属，再考虑首次纯策略提取；不直接开始整仓移动。

后续高价值试点：SoundPage 的完整 Feature/UI/Windows Audio 边界（架构文档阶段 3 建议）。首次功能迁移前需先打通 Shell 展示边界和同帧 LayoutSnapshot 设计。

## Windows 阶段 0 复核记录（2026-10-15）

本节补录当前 Windows 工作区的真实检查结果；阶段 0 **未完成**，不据此进入阶段 1。

### 静态基线复核

- 工作区 `res.zip` SHA-256：`79906ef073b56f564affb9c069564679df4cbe98868d1a5b8da3fdc7e08d9c3e`，与本文快照来源一致。
- `src/` 当前为 41 个 Zig 文件、24,755 行；`build.zig` 当前解析出 40 个命名源码模块。`main.zig` 3,991 行，`Renderer.zig` 1,503 行，`TextRenderer.zig` 2,493 行，与本快照中的规模一致。
- `src/`、`setup/`、`res/` 共 45 个文件与 `res.zip` 中对应文件逐字节一致；当前源码没有相对该快照的新差异。
- `check_boundaries.py --report`：21 active legacy forbidden edges，0 new、0 removed、0 unresolved；退出码 0。21 条边均与 `legacy-dependencies.json` 一致。它们是静态依赖边，不表示运行时缺陷。
- 负向验证：临时在 `src/ui/Renderer.zig` 增加对 `StartMenu` 的导入，守卫退出码 1，并报告 `src/ui/Renderer.zig -> src/features/StartMenu.zig` 为新违规。随后在 `finally` 中恢复源文件原始字节；恢复校验通过。
- 运行入口：系统 `python` 命令是无法启动的 Microsoft Store alias；实际通过本机工作区 Python runtime 的完整路径运行同一脚本，结果如上。

### Windows 构建与安装器

- OS/架构原始值：`Microsoft Windows 10.0.26220` / `X64`。
- `zig version`：退出码 0，输出 `0.17.0`。首次沙箱内执行七个构建目标各退出码 1，原始错误：`error: unable to find zig installation directory from executable path "C:\\Software\\Loadout\\store\\zig\\0.17.0\\zig.exe": FileNotFound`；进程内指定 `ZIG_LIB_DIR` 后的沙箱内 `zig env` 退出码 1，原始错误：`error: unable to open zig lib directory "C:\\Software\\Loadout\\store\\zig\\0.17.0\\lib": AccessDenied`。之后通过可访问本机 Zig 库与 Windows SDK 的构建调用，在当前进程中指定 `ZIG_LIB_DIR=C:\Software\Loadout\store\zig\0.17.0\lib` 后重跑。
- 以下命令最终各自退出码均为 0：
  - `zig build`
  - `zig build setup-build`
  - `zig build native-smoke-build`
  - `zig build thumbprobe-build`
  - `zig build sysstatusprobe-build`
  - `zig build geoprobe-build`
  - `zig build gsmtcprobe-build`
- 本轮未运行安装器；`setup-build` 仅请求编译。`zig-out/bin/IslandBarSetup.exe` 与 `.pdb` 时间更新为 2026-10-15 14:12:13。`IslandBar.exe` / `.pdb` 时间为 13:11:12，probe 二进制时间更早；构建命令成功，但这些文件没有本轮时间戳，故不声称它们是本轮新生成。所需安装器和 probe 输出路径均存在。
- 初始错误由沙箱阻止 Zig 读取工作区外安装目录导致；在允许读取实际安装目录与 Windows SDK 的构建调用中已解决。没有修改系统级环境变量，只对构建进程设置 `ZIG_LIB_DIR`。

### Windows 人工回归

本轮尝试通过 Computer Use 启动工作区 exe，但工具未暴露 IslandBar 可操作窗口（返回 `launched app did not expose a targetable window: C:\Users\viato\IslandBar\island_bar.exe`）；未进行点击交互。以下行为全部记为**未验证**：

| 检查项 | 结果 |
| --- | --- |
| 收起、悬停、展开 | 未验证 |
| 任务栏按钮 | 未验证 |
| 音乐播放/控制 | 未验证 |
| 声音页面 | 未验证 |
| 系统托盘 | 未验证 |
| 通知 | 未验证 |
| 启动菜单 | 未验证 |
| 动画中点击 | 未验证 |
| 多 DPI / 多显示器 | 未验证 |
| 电源或窗口关闭类操作 | 未执行 |

### 本轮范围、风险与回退

- 本轮没有编辑 `src/`、`build.zig`、`setup/`、`res/`、probe 入口或发布目标；仅临时注入并恢复了负向守卫测试 import。
- 阶段 0 待办：执行实际 UI 回归。成功的构建命令证明构建目标可完成；旧时间戳的增量产物不宣称为本轮重新生成。
- 回退：删除本节并恢复本轮前的 `AGENTS.md`；无需回退生产代码、安装器或资源。
- 阶段状态仍为进行中，原因是 UI 人工回归未验证。完成阶段 0 后，阶段 1 的最小建议是先只读盘点一个 State/Action/Contract 边界，再另行批准任何生产代码改动；`Renderer.nextCardOwner` 可作为候选评估对象，尚非本轮改动。

## 目录整理记录（2026-10-15）

- 代码、构建文件、安装器、资源、工具链脚本、smoke/probe 入口及既有 `zig-out/` 产物已归入 `island/`；构建命令从 `island/` 执行。
- 说明文档、开始页、阶段补丁包和既有截图归入 `docs/`；仓库根保留 `AGENTS.md`、Git/VS Code 配置及原有 `.zig-*` 目录。
- 本次整理开始时，工作区未找到 `res.zip`；前文关于其哈希和内容核对是此前检查时的记录，本次未移动或重建该包。

### 整理后验证

- 根目录只保留 `AGENTS.md`、`.git/`、`.gitignore`、`.vscode/`、原有 `.zig-cache/`、`.zig-out-root/`，以及 `docs/`、`island/` 两个内容目录。
- `.gitignore`、`.vscode/settings.json` 已更新到新目录；VS Code 设置 JSON 可解析。截图转移到 `docs/screenshots/`，原有二进制、日志和 probe 入口均保留在 `island/zig-out/`、`island/tools/`。
- 在 `island/` 执行 `python tools/architecture/check_boundaries.py --report`：退出码 0，21 条旧边、0 新增、0 移除、0 未解析。
- 在 `island/` 并使用进程级 `ZIG_LIB_DIR` 执行 `zig build`、`zig build setup-build`、`zig build native-smoke-build`、`zig build thumbprobe-build`、`zig build sysstatusprobe-build`、`zig build geoprobe-build`、`zig build gsmtcprobe-build`：各退出码 0。主程序、安装器和 probe 输出位于 `island/zig-out/bin/`；当前构建更新了对应产物。
- UI 启动尝试没有获得目标窗口；因此实际收起/悬停/展开、任务栏按钮、音乐/声音、托盘、通知、启动菜单、动画中点击和 DPI 回归仍全部未验证。
