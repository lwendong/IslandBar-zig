# IslandBar — Codex 自动执行重构 Goal V2（无 GUI 环境自动推进版）

> **用途：** 将本文件作为 Codex 的长期 Goal / Task Plan，按照下列编号顺序，对当前 IslandBar 工程执行渐进式架构重构。  
> **计划版本：** 2.0 · 2026-10-15（基于 V1 优化验证门禁，不改变 6 阶段 / 20 步范围）  
> **范围：** **6 个阶段，20 个执行步骤**（S0-001 至 S5-003）。  
> **唯一代码事实源：** Codex 当前工作目录中的最新代码。`res.zip` 只是 2026-10-15 的历史分析快照，**不能覆盖比它新的源码**。  
> **架构依据：** `IslandBar-Architecture-V1.md`（优先读取仓库内 `docs/IslandBar-Architecture-V1.md`）；`AGENTS.md` 用于记录实施进度。  
> **总体授权：** 用户授权 Codex **依照本 Goal 逐步实际修改代码**，达到“可执行自动化验证”门槛后自行继续下一步，无须每一步重新申请。**Windows 原生窗口交互 / 多显示器 / 真实设备 / 用户桌面环境测试不可执行时，不构成阻止后续开发的门禁**；需统一标为 `MANUAL_PENDING`，生成手工测试清单，最后集中交用户验收。  
> **严格区分：** `代码实施完成 ≠ Windows GUI 验证通过 ≠ 已可发布`。本授权不允许跳过**能执行的**自动检查、掩盖真实构建失败、大规模推倒重写、改变既有视觉、执行危险系统操作或擅自决定重大架构 ADR。

---

## 0. 直接给 Codex 的执行指令（优先级最高）

你是 IslandBar 的架构重构实施者，不是只写建议的代码审查员。**请现在创建名为 `IslandBar Architecture Refactor` 的 Goal/Task Plan，把以下 20 个步骤按编号加入任务队列，并从尚未完成的最早步骤开始实际改项目代码。** 本 V2 的自动推进与验证状态规则，优先于各步骤中“实机回归”“验收”“关键门禁”等旧措辞；**不可把 `MANUAL_PENDING` 解释成 `BLOCKED`**。

1. 先读取本文件、当前 `AGENTS.md`、架构文档、`build.zig` 与实际源码；检查 Git 工作区。有用户未提交改动时保留并适配，不覆盖、不重置、不丢弃。记录 Git 基线（无 Git 则记录差异快照）。
2. **复用已经实施的阶段 0**：若 `tools/architecture/check_boundaries.py`、`legacy-dependencies.json`、`docs/REFACTOR-BASELINE.md` 已存在，检查再复用；缺失则执行 S0-001。最新源码永远优先于 `res.zip`，`AGENTS.md` 的已有记录不能被旧版覆盖。
3. 每一步：**核对现状 → 确定范围 → 新增/运行可执行的自动测试 → 修改代码 → 构建/静态验证（能运行的）→ 记录缺失的 Windows 实机项 → 保存独立回退点 → 自动继续**。一个步骤一个清晰的变更集，不混合无关功能。
4. **实施状态与验证状态分开记录**。一个步骤可以是 `IMPLEMENTED` 且 `Windows GUI = MANUAL_PENDING`，**仍视为后续任务的前置开发依赖已满足**；除非有真实失败、存在严重代码风险或关键接口尚未实现。
5. **不要求 Codex 具有 Windows 桌面**：原生 HWND、D2D/DComp 可见窗口、多 DPI、多屏、拖动、通知抢占、设备拔插、真实音频会话、托盘交互等 GUI/硬件测试，环境不可用就加入 `docs/refactor/WINDOWS-MANUAL-TESTS.md`；**不要反复尝试启动窗口、索取截图、要求用户即时操作，或因为不能运行 GUI 就停下剩余 20 步**。
6. 能执行的验证必须执行：`git diff --check`、依赖扫描、相关纯 Zig 单测、实际可用的 Zig/Windows 交叉编译和构建目标。**有工具但产生可复现的真实编译/单测失败时必须修复**，不能写成环境缺失。若 Zig、Windows SDK、目标架构或某工具在当前执行环境中确实不存在，把该项记录为 `ENV_UNAVAILABLE`（及尝试命令、错误、替代检查），**照常推进后续步骤**；不要为了绿灯删除测试或错误代码。
7. 代码审查不可放松：任何已知的重复状态权威、UI 绘制/命中坐标双轨、COM/GPU 资源所有权破坏、双触发系统命令、越界线程写入、明显行为回归，应先修复。如果本步解决不了，把**受影响的任务链**记为 `BLOCKED_TECHNICAL`，保存当前改动和证据，继续执行其他**不依赖该缺陷**的任务；不能以“人工测试稍后做”为由无视已确认缺陷。
8. 如果某一步涉及高风险 Windows 行为但缺少实机环境：仍可完成结构迁移、单元测试、静态/可行的交叉编译，并保留兼容/回退路径或特性开关（仅在确有必要时）；**不要求当场人工验证才能进入 S3/S4/S5**。不得声称切换后的行为已在用户 Windows 系统上验证，也不得自动执行高风险操作。
9. 当前 Zig 版本与 Build API 以仓库为准。继续 Zig/Win32/Direct2D/DirectWrite/DirectComposition；不引入 Electron/WebView、大框架、动态插件、万能 EventBus 或全局可写 Context。
10. 每完成一个步骤，在 `AGENTS.md` 登记改动文件、消除的耦合、可执行命令及退出码、`ENV_UNAVAILABLE` 详情、Windows 手工待测编号、风险、回退点、后续依赖。自动转到下一可实施步骤，不要停留在“建议下一步”的咨询模式。
11. 禁止擅自将架构文档 `PROPOSED` 改为 `FROZEN`。候选实现可以依据实际源码选择更简单方案，但记入 ADR，不自创需要 GUI 环境才能获得的证据。
12. **目标完成语义**：全部 20 个步骤代码实施完，即可报告 `IMPLEMENTATION_COMPLETE_MANUAL_PENDING`（如果还有构建环境缺失，则注明 `BUILD_PENDING`），并**结束本轮 Codex 自动实施**；人工 Windows 验收以后独立进行。只有人工测试结果真实通过后，才可以写 `FULLY_VERIFIED` 或“可发布”。

**优先级冲突处理：** 在全文中出现“Windows 回归必须通过才能继续”“无法实机验证则 BLOCKED”“关键门禁必须实机确认”时，以本节和第 2 节为准：**仅缺少 Windows GUI/设备环境 → `MANUAL_PENDING`，不阻塞其他步骤，也不阻塞 20 步全部代码实施**；真实编译失败或已确认逻辑缺陷 → 修复，不能伪装成待测。

### 成功定义

用户未来要调整**音乐卡片字号或间距**，主要只需编辑 Music UI；调整**声音页面滑块布局**，主要只需编辑 Sound UI；**点击位置**不再维护第二套坐标公式；Windows 服务失败可在所属适配层定位；新增 Feature 只需新增本 Feature、必要端口和少量集中注册，不再在 `main.zig` 的各个 UI 分支到处插代码。完成重构前不得因目录结构“变好看”就宣布成功。

---

## 1. 项目事实与重构边界

### 1.1 来源明确、但必须对最新代码再次复核的现状

在 2026-10-15 提供的 `res.zip` 快照中，已观察到：

- `src/app/main.zig` 约 3,991 行，包含 `PaintContext`、页面文案组装、窗口事件/绘制、功能数据和平台操作。
- `src/ui/Renderer.zig` 约 1,503 行、`src/ui/TextRenderer.zig` 约 2,493 行，都直接引用具体 Feature；渲染底座和页面展示未分开。
- `Renderer.nextCardOwner()` 管理卡片归属，而 `main.zig` 使用该策略；`CardLayout.nextPanelLevel()` 同时参与页面状态决策；`StatePolicy.zig` 已有部分状态转换规则。
- `src/core/CardLayout.zig` 包含 `soundPageHitFor()` 等页面专用命中/几何；`src/core/TaskStripLayout.zig` 管理任务栏几何。
- `src/features/SoundOutput.zig` 和 `src/features/NotificationIcon.zig` 调用 `MusicSession.fetchAppIconForTest()`；这是明显不合理的跨 Feature 图标依赖。
- `src/platform/windows/SystemToggles.zig` 引用 `StartMenu`；`NotificationPipe.zig` 引用 `Notification`。此类依赖要核对 API 与职责后有计划地消除。
- 当前 `build.zig` 通过约 40 个**文件级命名模块**显式列出编译依赖；该显式约束有价值，不能直接删掉改成随意相对导入。
- 已准备过阶段 0 补丁，其中静态检查基线为 **21 条历史跨层依赖边**。此数字属于旧快照，不是 21 个已确认运行时 Bug；最新源码中不得硬编码它作为必须达到的数值。

以上是**调查入口，不是可以不看代码就机械移动文件的指令**。以 Codex 工作区的真实实现和编译结果为准。

### 1.2 必须长期成立的依赖方向

```text
              App / Composition Root
                       |
                       v
                Shell（展示编排）
                  |          \
                  v           v
           UI Foundation   Feature 公共展示接口
                  ^           |
                  |           v
               Feature UI   Feature Core → Platform Contracts
                  |                         ^
                  └──────→ Core            |
                                   Windows Platform Adapters

* 注：图只表达责任方向，不强制每个目录都是独立 Zig module；
  Feature Core 不依赖 UI/Windows 实现；通用 UI 不依赖具体 Feature。
```

- **App**：启动、连接依赖、生命周期和事件协调；不放页面细节、每个控件点击分支。
- **Shell**：卡片归属、导航、窗口展示模式/优先级、Surface 编排；不自行访问音频系统或绘制 GPU 细节。
- **Feature Core**：各自状态、Action、控制器、异步结果；禁止引用其他 Feature 的私有文件、通用 UI 或 Windows 具体实现。
- **Feature UI**：展示快照、局部样式、布局/绘制/输入映射；不调用阻塞的枚举、网络、COM/Win32 系统查询。
- **UI Foundation**：通用布局、输入、动画、主题、文本/图形原语、渲染契约；不导入 Music、Weather、Notification 等。
- **Platform Contracts**：窄接口与纯数据，不能向上导入 Windows 适配器。
- **Windows Platform**：Win32、GSMTC、Core Audio、Tray、Shell、D2D/DirectWrite/DComp 等实现，显式释放资源。
- **Core**：无业务、无 UI、无 Windows 副作用的公共基础类型。

### 1.3 本 Goal 明确禁止的“捷径”

- 不借机修改原 UI 颜色、字体、尺寸、布局、动效、交互含义或屏幕位置；除非为修复**已确认缺陷**且有前后行为对照。
- 不在多个地方保存独立且可写的同一业务状态；不让新旧两套命中/绘制公式永久并存。
- 不用导入通配、全局 `anyopaque` 万能上下文或动态服务定位器“解决”耦合。
- 不以“每个 Feature 必有 5 个文件”为机械目标；不必要的分层可以合并，必须保留职责独立。
- 不删除安装器 `setup/`、manifest、RC、`tools/smoke` 及既有 probes；不移除 build step、不更改现有发布产物名称。
- 不对用户机器自动执行终止程序、关机/重启、真实安装覆盖、系统任务栏重置或危险系统设置切换。
- 不通过扩大例外白名单、删除失败测试、吞掉错误码、禁用日志等方式制造“绿灯”。

---

## 2. 两层验证与自动推进门禁（优先级高于各步骤旧“验收”措辞）

### 2.1 进入步骤时

1. 从 `AGENTS.md` 读取**最早未实施**的步骤，核查依赖是已实现的代码/接口，而不是前序步骤的人工 GUI 测试是否完成；`MANUAL_PENDING` 不阻止下游。
2. 明确本步允许修改范围、保留行为、单一状态所有者、线程/资源所有权、现有测试与回退点。源码和构建 API 以当前工作区为准。
3. 为纯逻辑、状态机、布局几何、Action、异步 generation、错误和生命周期建立能执行的自动测试；对于 GUI/设备行为写人工检查项，不将虚拟测试说成真机测试。

### 2.2 A 类：能自动验证的门槛（必须尽最大可能执行）

| 检查 | 当前环境具备依赖 | 当前环境确实缺依赖 |
| --- | --- | --- |
| `git diff --check`、依赖图/边界扫描、语法/静态检查 | 实跑；真实新增问题修复后继续 | 记命令、原因、替代检查；可继续 |
| 纯 Zig 单元测试/几何与状态逻辑测试 | 实跑；新增失败必须修复 | 标 `ENV_UNAVAILABLE`，记录缺的 Zig/依赖；可继续 |
| `zig build`、可用的 Windows 交叉编译目标及 setup/probe | 能执行就实跑；失败先判断真实代码错误还是既存/环境限制 | 标 `ENV_UNAVAILABLE`，附命令和错误；可继续 |
| 源码 diff 审核，单一所有权、没有双命中/双绘制权威、无明显资源泄漏路径 | 每步必须做；发现可证实缺陷先修 | 不能标为通过；记具体风险与静态审查证据 |

- **真实失败 ≠ 环境不可执行。** Zig 命令实际运行且报错时要定位，例如缺 Windows SDK/系统库是 `ENV_UNAVAILABLE`，而 Zig 类型不匹配、未定义引用、用例断言失败是**代码问题**。绝不可把后者包装成 `ENV_UNAVAILABLE`。
- 如果代码问题暂时不能修复，只阻塞依赖该问题的步骤，并查找其他可继续的独立工作；不得直接跳过失败测试、扩大白名单、关闭错误处理。
- 某项可执行自动检查通过，仅说明**对应自动验证通过**，不能推出 Windows GUI 行为正确。
- 若整个执行环境连 Zig 都没有，仍应完成可静态审查的结构改造和单元测试源码编写、差异自审、依赖扫描以及完整手工验证清单；最终总状态另加 `BUILD_PENDING`，**不得声明编译成功或可发布**。

### 2.3 B 类：Windows GUI / 实机专项（后置，不阻塞自动实施）

以下事项若 Codex 无真实 Windows 桌面/设备访问，就标为 `MANUAL_PENDING`，不置任务 `BLOCKED`：

| 范围 | 后续由用户在 Windows 上实际测试的项目 |
| --- | --- |
| 整体 Shell | 收起、悬停、展开、自动收起、动画反向、通知抢占/恢复、全屏、焦点 |
| Music | 播放/暂停、切歌、封面、歌词、GSMTC 无会话/失败 |
| Sound | 主/应用音量、静音、输出设备、拖动、设备拔插、音频会话变更 |
| Taskbar | 窗口增删/激活、动画中命中、预览、HWND 重用、图标刷新 |
| Launcher | 打开/关闭、网格间隙、滚动、裁剪区域点击、启动失败 |
| Tray | 图标变化、菜单悬停/点击、菜单/窗口关闭；退出需手工确认 |
| Notification | 来源/去重/展示时长/抢占恢复、历史与图标失效 |
| System/Weather | 状态刷新、权限不足、系统能力缺失、天气超时与缓存 |
| Graphics/UI | D2D/DComp/透明、Clip/HitTest、100/125/150% DPI、负坐标、多屏、Device Lost |
| 稳定性/发布 | 帧时间、卡顿、长时间句柄/内存/GPU 趋势、Windows 安装器真实运行 |

**生成和维护** `docs/refactor/WINDOWS-MANUAL-TESTS.md`：每项使用唯一 ID，例如 `WIN-SHELL-001`，包含关联步骤、准备条件、明确操作、预期结果、风险、已做的自动替代验证、实际状态 `MANUAL_PENDING/PASS/FAIL/NOT_APPLICABLE`、实测者/日期/证据路径（未知则留空）。避免每阶段重复复制全部条目；以 ID 关联共享测试矩阵。

**执行原则：**

1. 不能运行 GUI → `MANUAL_PENDING` → **继续下个步骤**，包括 Sound 试点结束、全部 Feature 迁移、最终清理。不得要求用户先手工点击才能继续开发。
2. 可用纯数据、mock、几何回放、状态机/错误注入测试覆盖的，Codex 应自行做；这些只能作为自动替代验证，不能替代原生 GUI 通过的声明。
3. 未验证的高风险切换，应尽可能保持可回退路径、降低不可逆副作用，并记录风险及具体手工验证方法；结构层面可以继续实施，不得未经验证自动发布或安装。
4. 只有**真实发生的失败**才是故障；人工项目尚未执行不是失败。若人工测试后来明确 `FAIL`，需开修复任务并标识影响的步骤，而非默默标通过。

### 2.4 双状态模型：开发完成与人工验收不混淆

每个 Sx-yyy 使用两组**独立字段**，不能只用一个笼统的 `DONE/BLOCKED`：

- **实施状态：** `TODO`、`IN_PROGRESS`、`IMPLEMENTED`（完成代码与当前可执行的自动检查）、`BLOCKED_TECHNICAL`（已知代码/契约问题阻碍其实施）、`SKIPPED_NOT_APPLICABLE`（真实不适用且解释）。
- **验证状态：** `AUTO_PASSED`（可用自动门槛均实跑通过）、`AUTO_PARTIAL_ENV`（因工具/SDK/系统限制，部分未跑）、`MANUAL_PENDING`（人工 Windows 验证尚未执行，可与前两项并存）、`MANUAL_PASSED`、`MANUAL_FAILED`。记录为若干字段而不是互斥单值。

**依赖解锁规则**：某个前置步骤 `IMPLEMENTED`，且其接口可被后续引用、没有已知的关键逻辑缺陷时，**即可解锁下游**，即使该步骤是 `AUTO_PARTIAL_ENV + MANUAL_PENDING`。若步骤 `BLOCKED_TECHNICAL`，仅它的依赖链受阻；不相关任务继续。不得让 `MANUAL_PENDING` 变相成为 `BLOCKED_TECHNICAL`。

### 2.5 Codex 何时可以结束此次 Goal

- **20/20 实施完成，GUI 未测**：输出 `IMPLEMENTATION_COMPLETE_MANUAL_PENDING`；同时生成用户可直接照做的 Windows 手工验收单，明确“仍不可宣称已全面验收/可以发布”。这是允许的正常结束条件，**不是任务失败**。
- **20/20 实施完成，但因环境缺编译条件**：输出 `IMPLEMENTATION_COMPLETE_MANUAL_PENDING + BUILD_PENDING`；即使静态检查通过也不可声称构建通过。
- **遇到真实代码阻塞且有其他独立步骤**：先推进剩余独立任务，最后 `PARTIAL_TECHNICAL_BLOCK` 并列出具体阻塞链及修复建议。
- **20/20 实施且 Windows 实机由实际操作者验收完成**：只有具有真实 PASS 证据且构建证据完整时才可输出 `FULLY_VERIFIED`。Codex 不得自己编造 GUI 截图、运行日志、硬件结果。

**人工待测不是“必须停止”的条件；虚假测试结果、已知严重缺陷和危险系统操作才不可越过。**

## 3. 全部 20 个执行步骤与顺序

### 阶段 0：基线固化（1 步）

#### [ ] S0-001 — 最新源码、工具链与回归基线

**目标：** 确认重构开始之前的工程状态，可定位、可编译、可回退。

**具体任务：**

1. 检查仓库中是否已有阶段 0 的 `tools/architecture/check_boundaries.py`、`legacy-dependencies.json`、`docs/REFACTOR-BASELINE.md`；有则复验，无则按架构文档创建等效版本。保留原有数据，不直接用 `res.zip` 覆盖当前工作区。
2. 运行 `zig version`、`zig build`、`zig build setup-build`，确认构建产物为本轮生成。
3. 构建现有 `native-smoke-build`、`thumbprobe-build`、`sysstatusprobe-build`、`geoprobe-build`、`gsmtcprobe-build`；存在其他目标也记录，不删除。使用正确的 Zig 与 Windows SDK。
4. 运行依赖检查并进行一次**可撤销的违规导入负向测试**；验证历史债务被允许、新债务被拦截，随后还原测试改动。
5. 记录模块 import 图、Git 基线、关键页面视觉截图、系统交互清单及环境限制；现存 bug 记录复现步骤，不能把潜在风险写成已经复现。
6. 初始化或更新 `AGENTS.md` 步骤进度日志，保留已有日志。

**允许改动：** `AGENTS.md`、`docs/REFACTOR-BASELINE.md`、`tools/architecture/*` 和其他必要的测试文档。**禁止修改业务 Zig 源码及 `build.zig`。**

**验收：** 依赖基线与最新源码一致；真实执行的构建结果如实记录；Windows GUI 基线不可取得则记入人工清单 `MANUAL_PENDING`，构建环境缺失记 `AUTO_PARTIAL_ENV`，**两者均不妨碍 S1 开始**。只有确证的工具/代码基线被破坏、无法确定工作代码范围等实际问题才记 `BLOCKED_TECHNICAL`。

---

### 阶段 1：建立所有权与契约（3 步）

#### [ ] S1-001 — 编制所有权/依赖矩阵和最小公开契约

**目标：** 搞清楚谁持有可写状态、谁可以调用谁，先立规矩再移动代码。

**具体任务：**

1. 从 `PaintContext`、`Renderer.PillAppearance`、`CardLayout`、`StatePolicy`、`SoundOutput`、`MusicSession` 等追踪业务状态、展示状态、动画状态、输入状态和 COM/GPU 资源。
2. 写 `docs/refactor/OWNERSHIP.md`，列出每组状态的唯一所有者、写入点、读取者、生命周期及跨线程规则；标注每一个临时的旧实现桥接。
3. 写 `docs/refactor/DEPENDENCIES.md`，记录当前编译模块关系、跨层不当引用、期望的公开接口、过渡依赖和删除条件。
4. 明确 **Shell 展示 Action**、Feature Action/只读 Snapshot、最小 Platform Port 的语义；先确定类型和责任，不强制大规模引入新目录或抽象类。
5. 针对最先迁移的页面优先补上纯 Zig 状态决策测试，包括不同界面请求的优先级、快速反向等。

**验收：** 关键状态能够明确回答“谁写、谁读、谁释放”；新模块不再被允许随意跨层引入依赖；生产行为不变。

#### [ ] S1-002 — Shell 成为唯一卡片展示策略决策者

**目标：** 从绘制层抽离卡片归属、页面选择和展示优先级。

**具体任务：**

1. 对照 `Renderer.nextCardOwner()`、`CardLayout.nextPanelLevel()`、`core/StatePolicy.zig` 和 `main.zig` 的实际调用链，确认它们的状态转换与显示规则。
2. 在 `src/shell/PresentationPolicy.zig`（或等效最小模块）构造**纯数据输入 + 确定性输出**的状态决策函数，保留旧逻辑的优先级与过渡期语义。
3. 将 `CardOwner`、`PanelLevel` 等展示选择类型的权威所有者放在 Shell 公共契约中；**避免再出现 Renderer 和 CardLayout 两份同名 enum/转换表**。必要时先使用兼容别名，再安全移除。
4. 将主入口中的决策调用接入 Shell；`Renderer` 只接收已决定的展示描述并负责绘制，不再决定哪张卡片应该展示。
5. 用纯 Zig 用例覆盖：Music/Notification/System 竞争、展开/关闭、旧卡片消失、通知开始/结束、快速连击和动画反向。先跑“旧行为对照测试”，再切新实现。

**验收：** 展示策略只存在 Shell 一份；修改通知和卡片抢占逻辑不需要修改 Renderer；布局/颜色/动画表现与旧版一致。不要顺带做窗口数量重构。

#### [ ] S1-003 — 剥离跨 Feature 的应用图标能力

**目标：** 让 Sound、Notification 等不再调用 Music 的私有图标函数。

**具体任务：**

1. 追踪 `MusicSession.fetchAppIconForTest()` 的图标获取、WIC 解码、缓存、错误和线程/COM 规则。
2. 将通用获取能力抽到 Windows 平台图标服务/资源适配器（例如 `platform/windows/shell/AppIconService.zig`，名称以现有代码为准），对上层提供窄接口和明确输出生命周期。
3. 将 Sound、Notification 和真正需要的其他调用者改接该能力；Music 不再成为公共图标库。
4. 测试路径为空、窗口关闭、进程退出、图标缺失、HWND/PID 重用、缓存失效和释放（能自动测的先测；Windows 情况作实测记录）。
5. 审核更新 `build.zig` 的**显式**依赖清单，移除已消失的错误跨 Feature 依赖。

**验收：** `SoundOutput`、`NotificationIcon` 不再 import MusicSession 仅为图标获取；功能图标显示行为保持不变。

---

### 阶段 2：UI 渲染、布局与输入底座（4 步）

#### [ ] S2-001 — 受控绘制生命周期与设备资源边界

**目标：** 确保渲染操作发生错误时仍能正确清理和恢复，而不丢业务状态。

**具体任务：**

1. 审计 `src/ui/Renderer.zig`、`TextRenderer.zig`、`WicImage.zig` 的 D2D/DWrite/DComp/D3D11/DXGI、WIC/COM 所有权。
2. 检查 BeginDraw/EndDraw、PushClip/PopClip、Acquire/Release、Resize/Commit/Present 及提前 return 的配对；将确认的失衡点封装在 GraphicsBackend 责任内。
3. 明确设备代际、缓存失效、Device Lost 后的重建顺序；**业务 Snapshot 与设备资源分别管理**。
4. 在可控制的纯 Zig 辅助逻辑中加生命周期/错误路径测试；条件允许时增加低风险的 Windows 设备重建设备验证，不做会破坏系统的故障注入。
5. 不预设必须创建复杂绘制命令系统；可保留高性能受控绘制接口。

**验收：** 在源码审计与可执行测试范围证明关键绘制操作的清理与资源分离；Device Lost 等 Windows 实机部分标 `MANUAL_PENDING` 并生成测试用例，**不阻止 S2-002 或后续步骤**。不得把未验证的设备恢复写成实机已通过。

#### [ ] S2-002 — 最小 LayoutSnapshot 与坐标契约

**目标：** 建立“同一帧布局只算一次”的数据结构与验证方法。

**具体任务：**

1. 建立 `ElementId`、Bounds、Transform、Clip、ZOrder、HitRegion、Visible/Enabled 及 LayoutSnapshot generation（字段按实际必需程度简化）。
2. 明确坐标系：DIP、窗口像素、屏幕坐标、DPI 变换、负坐标和多显示器。
3. 先挑选**一个受控场景**接入（优先 SoundPage 控件或 Taskbar 的一组按钮），避免一次性翻新所有布局。
4. 将该场景绘制、hover、输入命中、裁剪统一到同一快照；只有与**最近成功呈现帧**对应的快照才能对外用于命中，不能用下一帧预测坐标代替。
5. 补齐裁剪、边界、间隙、ZOrder、动画变换和 DPI/负坐标的纯几何测试。

**验收：** 试点控件绘制位置与命中区域来自同一份快照，动画过程中不因两套公式产生错位；旧路径切换后不再有第二个可写几何权威。

#### [ ] S2-003 — InputRouter、语义 Action 与动画命中同步

**目标：** 输入事件不再在大段窗口消息/绘制代码中直接操纵业务。

**具体任务：**

1. 建立最小 `InputRouter`/命中 API，输入是原始事件及上次已呈现的 LayoutSnapshot，输出为带 ElementId 的**类型化 Action**。
2. Shell Action 调 Shell 状态机；Feature Action 调所属 Controller；Win32 真实系统副作用由对应平台适配器执行。
3. 先将 S2-002 已接入的控件迁移成完整链路，逐步替换其旧命中；避免同时驱动双重点击行为。
4. 检查动画取消、快速反向、窗口几何/输入区域更新的时序；不允许独立插值坐标与命中公式漂移。
5. 用纯 Zig 测试覆盖 hit priority、按下/拖动/释放、快速切换、重叠、裁剪、disabled、零尺寸及越界点。

**验收：** 可用 ElementId、Frame Generation 和 Action 定位一次点击；试点场景动作只触发一次；窗口行为未改变。

#### [ ] S2-004 — 最小 UI 公共层、样式与绘制边界

**目标：** 为 Feature UI 提供稳定、可复用但不过度复杂的接口。

**具体任务：**

1. 根据真实复用需要整理 Text、Image、Button、Slider、ScrollView、IconButton 等已有绘制/输入原语；不要求全部一次实现。
2. 将 Theme 中的可复用 Tokens 与 Music/Sound 等专用 Style 区分；配置持久化不混在纯样式定义里。
3. 为 Feature UI 提供只读 ViewModel + 局部状态 + layout/paint/hit/action 映射约定；允许直接使用受控画布 API，而非强制 VDOM 或全量 DrawCommands。
4. 将已迁移试点的页面专用绘制从公共 TextRenderer/Renderer 移出；其他尚未迁移页面保留临时兼容路径并登记清理计划。
5. 观察帧时间与资源数量，避免因抽象增加明显卡顿、重复分配或重复绘制。

**验收：** 通用 UI 基础设施没有新增具体 Feature 依赖；局部样式变更不影响服务与主循环；旧外观完全保留。

---

### 阶段 3：完整试点 Sound Feature（2 步）

#### [ ] S3-001 — Sound State/Action/Controller 与 AudioService 分层

**目标：** 用 Sound 验证架构不是空设计。

**具体任务：**

1. 梳理 `src/features/SoundOutput.zig`、`src/platform/windows/AudioVolume.zig` 及 `main.zig` 中声音数据获取、后台执行、调节音量和设备切换调用链。
2. 创建 `features/sound` 的最小公开入口与内部状态/Action/Controller（目录和文件数按复杂度确定）；唯一维护业务状态、revision、请求中的乐观状态（若需要）。
3. 把 Core Audio/系统设备枚举与副作用隔离到 Windows AudioService；Feature 只通过窄端口请求，错误保留可诊断的系统码但不向 UI 泄漏 COM 指针。
4. 明确 COM Apartment、工作线程、UI 线程回传、generation/token、停止或设备变更时的过期结果丢弃、分配/释放规则。
5. 添加纯 Zig 控制器测试：无设备、设备变化、重复动作、失败/超时、陈旧结果、权限失败和反复拖动。

**验收：** Sound Core 不导入 Win32/Core Audio 实现；没有第二份可写声音状态；现有功能表现保留。

#### [ ] S3-002 — SoundPage UI 独立完成并移除旧业务路径

**目标：** 证明调整音量页 UI 可以只动 Sound UI。

**具体任务：**

1. 从 `main.zig` 的 `buildSoundPageText()`、点击/拖动分支和 `TextRenderer` 的专用绘制逻辑中识别 UI 职责；移到 `features/sound/ui` 的 ViewModel/组件/局部布局。
2. Sound UI 只消费 Sound Snapshot，输出布局、绘制和 Action；拖动时用户显示值与实际系统确认值明确区分。
3. 复用 S2 的 LayoutSnapshot/InputRouter，处理设备列表、应用音量滑块、滚动、Hover/Pressed、DPI/裁剪。
4. 由 App 集中组装 Sound Controller + AudioService，Shell 通过公开展示契约挂载 SoundPage。
5. 新旧路径完成切换后删除**该功能**的重复状态/重复事件分支，不删其他功能代码。
6. 在 Windows 回归：打开/关闭声音页、默认设备、音量拖动、静音、设备拔插、进程退出/音频会话变化、失败回退。

**验收：** 修改滑块颜色/尺寸/排列主要只修改 `features/sound/ui`；`main.zig` 和 Windows AudioService 无需随之变动；结构与自动测试达到当前环境可验证范围。**这是后续 Feature 迁移的代码架构门槛，不是 Windows 实机点击门槛**；Sound GUI 无法运行则登记 `MANUAL_PENDING` 并直接继续 S4。

---

### 阶段 4：逐项迁移剩余 Feature（7 步）

> **每项都是独立、可回退的代码实施与自动检查，不可合并成“一次移动整个 features 目录”。** 每迁完一项，先确保新路径的唯一权威与可执行测试，再清理该功能被替代的旧代码；未迁移功能允许走登记过的兼容桥。各 Feature 的 Windows GUI 验收可以全部累计到最终手工测试单，**任何未执行的实机测试均不得阻止其他 Feature 开始**。

#### [ ] S4-001 — Music / Lyrics / GSMTC / Music UI

1. 从 `MusicSession.zig` 和 `Lyrics.zig` 提取 Music State、Actions、Controller、歌词能力和只读 ViewModel；GSMTC 及封面系统解码由 Windows MediaService/资源服务负责。
2. 将迷你音乐条、完整 MusicCard 的布局/绘制逐步归入 Music UI；Shell 只决定何时显示，不决定音乐业务状态。
3. 保留播放/暂停/切歌、歌词滚动、封面更新、系统媒体会话切换、会话丢失时恢复的行为。
4. 显式测试异步封面/歌词结果的代际有效性、COM 生命周期、UI 同帧命中和渲染资源恢复。

**验收：** 音乐卡片字号/间距仅修改 Music UI；GSMTC 逻辑修改不要求改公共 Renderer。消除相关跨层债务。

#### [ ] S4-002 — Launcher / StartApps / StartMenu

1. 分离应用枚举、图标、启动 Windows AppService 与 Launcher 自有的索引、选择、搜索/打开 Action。
2. 将 StartPage 网格、列表、hover、scroll、clip、命中归 Launcher UI；必要的逻辑布局与其组件放在同一职责域。
3. 确保网格**空隙不触发点击**、裁剪外不误命中、错误启动有返回结果，多 DPI/快速重复点击不重复启动。
4. 处理 `SystemToggles.zig` 对 `StartMenu` 的不合理依赖：确认职责后用平台契约或 App/Shell 编排代替，而非倒置层次。

**验收：** Launcher UI/状态与系统枚举/启动隔离；系统能力实现不 import Launcher 私有模块。

#### [ ] S4-003 — Tray / 托盘窗口与菜单

1. 分离 `TrayIcons.zig`、`TrayPress.zig` 的系统枚举、图标身份和具体操作与 Tray Feature 状态/展示模型。
2. TrayPage/菜单 hover、选择、滚动、裁剪、点击从主入口/通用 Renderer 中迁移到 Tray UI。
3. 对托盘项使用可验证的目标身份、当前生命周期、进程/窗口实例；关闭/退出等高影响操作保持原有确认/权限规则。
4. 通过代际或失效规则处理托盘项更新、窗口关闭及缓存失效。

**验收：** 修改托盘页面 UI 不需要编辑系统托盘枚举代码；误点击不会触发错误目标。

#### [ ] S4-004 — Notification / ToastStore / WeChatWatch / Pipe

1. 将消息模型、历史、去重与消费规则归 Notification Feature；消息来源（Pipe/微信等）放入通知输入适配层或独立集成子模块。
2. 消除 Windows `NotificationPipe` 对 Feature 内部实现的直接依赖，使用明确的通知输入契约；不破坏已有来源协议。
3. 将 NoticeStrip/NotificationCard 专用 ViewModel/UI 从通用渲染路径分离；通知**显示优先级仍由 Shell 决定**。
4. 验证抢占与恢复、历史去重、快速连续通知、来源失效、图标获取和过期结果。

**验收：** Notification 失败不应使整个 Shell UI 无响应；更改通知样式不必改 Windows 输入适配器。

#### [ ] S4-005 — Taskbar / WindowList / NativeTaskbar / Thumbnail

1. 将任务窗口枚举、激活/关闭、稳定身份、缩略图 DWM 接口归 Windows WindowService / ThumbnailAdapter；Taskbar Feature 管理交互语义和所需 Snapshot。
2. 将 `TaskStripLayout.zig` 的专用逻辑归 Taskbar UI；`ThumbnailPreview.zig` 划分平台抓取与 UI 展示职责。
3. 将**同一帧实际呈现几何**用于绘制、窗口输入区域、Hover 和 HitTest；处理任务按钮出现/消失、重排、动画反向和 DPI。
4. 处理 HWND 重用、窗口消失、图标缓存失效、进程 ID 非唯一、误激活/误关闭风险；禁止仅凭 exe 名称执行高影响操作。
5. 添加高价值的纯几何测试和 Windows 动画中实际点击回归。

**验收：** 动画中的任务按钮命中准确；图标和窗口身份在关闭/重建后不误指向新窗口。

#### [ ] S4-006 — System Panel / Status / Toggles / Brightness

1. 分离 `SystemStatus`、`SystemToggles`、`DisplayBrightness` 等系统 Win32 操作与 System Feature 状态/Action。
2. SystemPanel 专用 UI 和布局归 System UI，优先使用平台服务返回的稳定纯数据而非 UI 内直接查询系统。
3. 对亮度、电源、蓝牙、Wi-Fi 等操作保留权限和错误语义，系统结果确认后再更新权威状态；危险操作不得自动触发。
4. 验证系统能力不可用时有局部降级，不拖垮整个应用。

**验收：** System UI 不直接操作系统 API；平台适配器不决定展示的页面。

#### [ ] S4-007 — Weather / 数据源与天气卡片

1. 从 `Weather.zig` 区分查询/解析/缓存/失败/重试与 Weather Feature 状态、ViewModel 和 UI。
2. 将天气相关 TextRenderer/Renderer 专用输出移到 Weather UI 或公开展示贡献；天气请求不在绘制/输入热路径同步发生。
3. 对无网络、超时、旧结果晚于新结果、缓存陈旧、字段缺失做好防护，并明确定义不影响 Shell 的降级行为。
4. 验证原文案、温度格式、视觉位置、刷新节奏（除非已确认旧问题）不改变。

**验收：** 更换数据来源不需要修改 Renderer；天气失败不影响其他 Feature 绘制。

---

### 阶段 5：收缩旧架构、清理依赖、固化维护能力（3 步）

#### [ ] S5-001 — 收缩 `main.zig`，固化 App/Shell 组装边界

**具体任务：**

1. 在全部 Feature 已有独立路径的前提下，将 `main.zig` 中剩余初始化、运行协调、窗口消息路由、异步调度移到职责明确的 `App.zig` / `Runtime.zig` / Shell/WindowHost 等模块；**不要求按文件名机械拆分**。
2. Shell 持有展示导航与 Surface 组合，Feature 持有业务状态，Platform 持有 Windows 资源；App 只负责创建依赖、启动和有序销毁。
3. 逐一确认关闭路径中的线程终止顺序、COM 释放、资源和缓存销毁、窗口清理，以及后台迟到消息处理。
4. 删除已不再需要的旧 `PaintContext` 跨模块可写状态、专用 UI 决策分支和重复调度；保留必要的轻量适配代码。

**验收：** 增加一个独立功能无需修改主循环各处的 switch；入口职责清楚；启动/退出/运行行为完全回归。

#### [ ] S5-002 — 收缩 Renderer/旧布局/构建依赖，消除历史跨层债务

**具体任务：**

1. 在已有功能全部迁移且对照通过后，删除被替代的旧布局/旧渲染/旧服务/兼容桥；禁止先删后补。
2. 使通用 `Renderer`/`TextRenderer` 或新 RenderPipeline **不再 import Music、Sound、Weather、Notification、Launcher 等 Feature 实现**；业务 UI 通过公开展示接口调用受控绘制。
3. 审核 `core/CardLayout`、`TaskStripLayout`、`Motion`、`InputRegion` 等：通用几何留 Core/UI，页面或任务栏专用布局回到对应 UI，Shell 策略留 Shell。
4. 按稳定边界重整 `build.zig` 的显式 import 白名单；不要机械“一源码文件一个顶层模块”，也不要为了简化而打开隐式跨层导入。
5. 审查 `tools/architecture/legacy-dependencies.json` 中每一条旧债务：已消除的移除、未消除的记录原因；**绝不因扫描脚本全绿就自动删掉所有例外**。
6. 保留已有安装器、探针、Windows 资源构建入口及发布方式，必要时更新现有脚本以匹配新目录。

**验收：** 关键架构红线受静态检查约束，历史债务显著减少且残留有责任人/理由；所有原构建目标仍存在。能够运行的构建目标必须通过；因 SDK/平台限制无法运行的写 `AUTO_PARTIAL_ENV`，不阻止 S5-003，但列入最终 Windows 编译检查。

#### [ ] S5-003 — Diagnostics、回归体系与 Goal 最终验收

**具体任务：**

1. 整理跨层诊断链：`Input/Event → ElementId/Layout Generation → Action → Controller → Platform Result/Error → Snapshot → Render`；仅增加轻量 OperationId 和必要上下文，不造分布式追踪系统。
2. 开发模式提供可选 UI Inspector/日志：ElementId、Bounds/HitRegion/Clip、DPI/坐标系、帧时间、资源代际；默认运行不承担明显额外负担。
3. 覆盖 Shell 状态、LayoutSnapshot、InputRouter、Feature Controller、陈旧请求、资源失效等纯 Zig 测试；检查测试可以持续运行。
4. 在当前环境执行**能够运行的**完整构建、安装器构建、已有 probe 构建和自动测试。对于第 2.3 节 GUI/多屏/设备场景，若无 Windows 桌面就**不执行也不阻塞**；确保每项在 `WINDOWS-MANUAL-TESTS.md` 中具备操作步骤与预期结果，统一 `MANUAL_PENDING`。
5. 实际完成维护性验收：只改 Music UI 样式、只改 Sound UI 布局、只改 Shell 卡片优先级、只改 Media/Audio 平台实现，记录分别触及了哪些文件，以及是否影响不相关模块。
6. 更新 `docs/refactor/FINAL-REPORT.md`、`AGENTS.md`：已完成步骤、关键架构决策、已解决耦合、残留风险、性能变化、编译和实测证据、后续维护规范。
7. 若全部 20 个步骤代码实施完成但 Windows GUI 尚未测试，**正常结束当前自动实施流程**，报告 `IMPLEMENTATION_COMPLETE_MANUAL_PENDING`；缺编译条件再追加 `BUILD_PENDING`。真实检测到的性能退化、关键双重状态或逻辑/编译失败必须修复或记作 `PARTIAL_TECHNICAL_BLOCK`，不能用 `MANUAL_PENDING` 掩盖。

**自动实施完成标准：** 20 个步骤的代码路径与必要测试/文档均已落实；能执行的检查如实记录，不能执行的 Windows GUI/系统场景均有手工用例。这代表**重构代码实施完成**，不代表“Windows GUI 已实测”或“可发布”。

---

## 4. 任务看板（Codex 每完成一步必须更新）

> 初始 `TODO` 代表**尚未经过本 Goal 的最新代码与测试确认**，不是断言第一步补丁尚未应用。Codex 须先基于当前工程验证，再更新状态。

| 阶段 | 编号 | 步骤简述 | 初始状态 | 关键前置 |
| --- | --- | --- | --- | --- |
| 0 | S0-001 | 基线、构建与回归 | TODO / 待复验 | 无 |
| 1 | S1-001 | 状态所有权和契约 | TODO | S0-001 |
| 1 | S1-002 | Shell 展示策略 | TODO | S1-001 |
| 1 | S1-003 | 图标公共服务 | TODO | S1-001 |
| 2 | S2-001 | 绘制与设备生命周期 | TODO | S0-001、S1-001 |
| 2 | S2-002 | 同帧 LayoutSnapshot | TODO | S1-001、S2-001 |
| 2 | S2-003 | InputRouter / Action | TODO | S2-002、S1-002 |
| 2 | S2-004 | UI Foundation / Theme | TODO | S2-002、S2-003 |
| 3 | S3-001 | Sound Core / AudioService | TODO | S1-001、S1-003、S2-001 |
| 3 | S3-002 | SoundPage UI 独立 | TODO | S3-001、S2-004 |
| 4 | S4-001 | Music | TODO | S3-002 |
| 4 | S4-002 | Launcher | TODO | S3-002 |
| 4 | S4-003 | Tray | TODO | S3-002 |
| 4 | S4-004 | Notification | TODO | S1-002、S3-002 |
| 4 | S4-005 | Taskbar | TODO | S2-003、S3-002 |
| 4 | S4-006 | System | TODO | S3-002 |
| 4 | S4-007 | Weather | TODO | S3-002 |
| 5 | S5-001 | App/Shell/入口收缩 | TODO | S4 全部 |
| 5 | S5-002 | 旧模块与 build 清理 | TODO | S5-001 |
| 5 | S5-003 | 诊断与最终回归 | TODO | S5-002 |

**状态定义：** 看板“初始状态”仅用于第一次创建任务；正式状态按照 §2.4 拆成**实施状态 + 验证状态**。`IMPLEMENTED + MANUAL_PENDING` 就是可继续的开发完成状态；仅已确认技术问题使用 `BLOCKED_TECHNICAL`；`SKIPPED_NOT_APPLICABLE` 必须有真实源码证据。

**强制规则：** 不得为让看板全绿就批量标 `IMPLEMENTED` 或伪造 GUI 验证；每项必须有源码变更/适用性确认、可执行检查结果、人工待测项引用和回退点。应自动完成全部能独立实施的任务，不以待人工操作的 GUI 验证阻断后续步骤。

---

## 5. `AGENTS.md` 进度记录格式（强制）

继续使用现有 `AGENTS.md`，只追加/更新当前步骤记录；旧日志不得删除或覆写。若原文件仍是占位内容 `111`，可初始化成进度台账，注明原始内容。

```markdown
## [Sx-yyy] 步骤标题

- 日期、分支、基线 commit：
- 实施状态：TODO / IN_PROGRESS / IMPLEMENTED / BLOCKED_TECHNICAL / SKIPPED_NOT_APPLICABLE
- 自动验证状态：AUTO_PASSED / AUTO_PARTIAL_ENV / NOT_RUN（附原因）
- Windows GUI 验证状态：MANUAL_PENDING / MANUAL_PASSED / MANUAL_FAILED / NOT_APPLICABLE
- 允许改动范围、未修改行为：
- 代码与架构变更、唯一状态所有者：
- 改动文件：
- 已消除依赖、保留兼容桥和删除条件：
- Zig 版本、实际构建命令、退出码与日志位置：
- 纯 Zig/模拟测试及真实结果：
- 依赖边界检查（新增违规数）：
- 环境不可执行项：具体命令 + 原始错误 + 环境缺口 + 替代验证；不可填“通过”
- Windows 人工待测编号：WIN-...（详见 docs/refactor/WINDOWS-MANUAL-TESTS.md）
- 资源/线程/输入/UI 风险：
- 回退 commit / patch：
- 下游任务是否解锁：是/否；理由：
```

必须同步维护 `docs/refactor/WINDOWS-MANUAL-TESTS.md`，状态表和人工待测项目必须保持一致，**不要因为一个人工项目尚未执行而把步骤写成 `BLOCKED`**。

禁止：填写“所有测试通过”却没有运行；把压缩包旧 exe 视为新构建；把 Windows SDK 缺失当成代码失败，或把 Zig 类型错误当成环境缺失；以纯逻辑测试冒充 Win32 GUI 实测。

## 6. 验证命令、差异检查与回退规则

### 6.1 优先使用的现有构建入口

```powershell
zig version
zig build
zig build setup-build
zig build native-smoke-build
zig build thumbprobe-build
zig build sysstatusprobe-build
zig build geoprobe-build
zig build gsmtcprobe-build
python tools/architecture/check_boundaries.py --report
```

- 若某个命令不存在、工具链版本不同或工作区已变化，检查当前 `build.zig`，记录真实情况；不要为了匹配本文删除已存在目标。
- 纯 Zig 测试应按**实际创建的测试目标**运行，例如新增 `zig build test`（需先在 `build.zig` 注册并确保兼容当前 Zig 版本），不能仅写在报告里。
- 某一命令跨平台不可用，要记录环境限制及原始错误、标记 `AUTO_PARTIAL_ENV`，再继续下一步；不得暗改平台实现以制造通过。

### 6.2 每一步前后执行的差异自检

1. `git status` / `git diff --stat` / `git diff --check`（若有 Git）。
2. `rg '@import\(' src` 等依赖扫描；记录新增跨层依赖数和已消除的旧债务。
3. 对每一新公开 API 明确谁负责初始化、回调、销毁；在代码中验证调用方确实遵守所有权。
4. 关注是否在 Renderer 或通用 TextEngine 中又出现新 Feature import；关注 Feature UI 中是否出现高成本系统调用。
5. 对绘制和输入同一控件定位：是否分别算了两次尺寸/位置；是否使用最近**已成功呈现**的帧快照。
6. 对异步/COM/线程：后台是否越权写 UI；取消和销毁之后迟到结果是否被丢弃；有无跨 Apartment 误用或二次释放。

### 6.3 回退与阻塞

- 只回退**本步骤造成的变更**，不 `git reset --hard` 覆盖用户工作或前面已验收步骤。
- 构建或回归失败先定位根因；如果失败本来就存在，记录对照；不能把新失败冒充历史故障。
- 修复可能改变 UI 交互或平台副作用时，先执行可以运行的业务/布局/资源自动验证；**GUI 真机无法运行则记 `MANUAL_PENDING`、保留回退点并继续开发**。如果已经发现确切代码缺陷而非缺环境，标 `BLOCKED_TECHNICAL` 并优先修复。
- 不要自动运行可能修改 Windows 系统设置、用户应用进程或机器电源状态的探针/功能操作；此类实机检查需要明确的手动安全环境。
- 如果工具链可用且出现新增的真实编译失败，应修复或仅阻塞依赖该失败的开发链；若工具链**不可用**导致无法编译，只记录 `BUILD_PENDING/AUTO_PARTIAL_ENV`、补充静态自检与回退点，其他步骤继续，不得谎称“可编译、可运行”。

---

## 7. 最终应交付的内容

1. **实际源码改动及已执行自动验证结果**，不是只新建大量空目录或写文档；缺实机环境时不得将代码实施称为“全部功能已验证”。
2. 与实际实现一致的 `docs/IslandBar-Architecture-V1.md` 对照记录与必要 ADR（**不要自行修改源架构文档的状态**）。
3. `AGENTS.md`（20 步实施状态、独立的自动/人工验证状态、证据、回退）、`docs/refactor/FINAL-REPORT.md` 与 **`docs/refactor/WINDOWS-MANUAL-TESTS.md`**（用户集中执行的原生 GUI/系统验收单）。
4. 模块边界检查、纯 Zig 关键算法测试、全部原 Windows 构建/安装器/probe 目标（若当前环境无法运行，记录待在 Windows 验证的准确命令，**不因此中断自动实施**）。
5. 维护说明：改 Music UI、Sound UI、Shell 展示策略、Windows Media/Audio 服务分别在哪些文件修改；新增 Feature 如何接入。
6. 尚未解决的**已确认代码问题**与**因环境未运行的测试项**分两张清单：分别说明风险、复现/手测步骤、关联任务、回退方式，不可互相混淆。

## 8. Codex 最终回报格式

```markdown
# IslandBar Architecture Refactor — 自动实施报告

- Goal 状态：IMPLEMENTATION_COMPLETE_MANUAL_PENDING / IMPLEMENTATION_COMPLETE_MANUAL_PENDING + BUILD_PENDING / FULLY_VERIFIED / PARTIAL_TECHNICAL_BLOCK
- 代码实施进度：x / 20，逐项编号；未实施项原因
- 当前代码基线：branch / commit / Zig 版本或 Zig 缺失
- 核心职责调整及消除的跨层依赖：
- 静态检查与可执行单测：实际命令、退出码、失败/成功证据
- 构建：已真实运行的目标与结果；无法运行的目标和环境原因
- Windows GUI 手工待验收：xx 项，见 docs/refactor/WINDOWS-MANUAL-TESTS.md
- 已确认的功能/编译缺陷（不同于未验证项）：
- 兼容桥、回退点、尚存风险：
- 后续用户在 Windows 上需要执行的具体清单与建议顺序：
- 注意：代码实施完成不等于 GUI 实机已通过，也不意味着已可发布
```

**现在立即执行：** 读取实际工程 → 与 `AGENTS.md` 对齐 → 创建 Goal 与全部 20 个步骤 → 从最早未实施的步骤开始实际修改。**Windows GUI/硬件/多屏实测无法运行，不阻止进入后续步骤**；持续实施到 20/20，创建人工测试清单后报告 `IMPLEMENTATION_COMPLETE_MANUAL_PENDING`。真实代码错误先修复，不能执行的构建如实写 `BUILD_PENDING`。不要仅做总体分析就结束。
