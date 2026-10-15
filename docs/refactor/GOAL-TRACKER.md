# IslandBar Architecture Refactor — Goal 追踪

依据：`IslandBar-Codex-Goal-Complete-Refactor-V2.md`、`docs/IslandBar-Architecture-V1.md` 与仓库根目录 `AGENTS.md`。架构文档继续保持 `PROPOSED`。

## Goal 状态

- 名称：IslandBar Architecture Refactor
- Codex Goal：当前会话 Goal 已激活；当前任务标题已设置为上述名称。Goal API 只允许创建或改状态，不能编辑已激活 Goal 的 objective；此文件是完整的 20 步执行队列和状态台账。
- 执行规则：用户已授权依照 V2 连续实施全部可实施步骤。`MANUAL_PENDING` 不阻塞后续代码步骤；真实代码失败必须先修复。不能访问的工具/SDK记为 `ENV_UNAVAILABLE`。
- 基线 commit：`a95646ede369445a819f9367e5b9a92aee7227ec`
- 当前分支：`main`。
- 本文状态采用 `实施状态 + 自动验证状态 + Windows 手工状态` 三列。`IMPLEMENTED + MANUAL_PENDING` 可解锁下游。
- Goal 结果：`IMPLEMENTATION_COMPLETE_MANUAL_PENDING`；20/20 步骤已完成可实施代码路径，Windows 原生验收保留在集中清单。

## 20 步执行队列

| 阶段 | 编号 | 步骤 | 实施状态 | 自动验证 | Windows 手工 | 依赖 |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | S0-001 | 最新源码、工具链与回归基线 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | — |
| 1 | S1-001 | 编制所有权/依赖矩阵和最小公开契约 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S0-001 |
| 1 | S1-002 | Shell 成为唯一卡片展示策略决策者 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S1-001 |
| 1 | S1-003 | 剥离跨 Feature 的应用图标能力 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S1-001 |
| 2 | S2-001 | 受控绘制生命周期与设备资源边界 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S0-001, S1-001 |
| 2 | S2-002 | 最小 LayoutSnapshot 与坐标契约 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S1-001, S2-001 |
| 2 | S2-003 | InputRouter、语义 Action 与动画命中同步 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S2-002, S1-002 |
| 2 | S2-004 | 最小 UI 公共层、样式与绘制边界 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S2-002, S2-003 |
| 3 | S3-001 | Sound State/Action/Controller 与 AudioService 分层 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S1-001, S1-003, S2-001 |
| 3 | S3-002 | SoundPage UI 独立完成并移除旧业务路径 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S3-001, S2-004 |
| 4 | S4-001 | Music / Lyrics / GSMTC / Music UI | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S3-002 |
| 4 | S4-002 | Launcher / StartApps / StartMenu | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S3-002 |
| 4 | S4-003 | Tray / 托盘窗口与菜单 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S3-002 |
| 4 | S4-004 | Notification / ToastStore / WeChatWatch / Pipe | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S1-002, S3-002 |
| 4 | S4-005 | Taskbar / WindowList / NativeTaskbar / Thumbnail | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S2-003, S3-002 |
| 4 | S4-006 | System Panel / Status / Toggles / Brightness | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S3-002 |
| 4 | S4-007 | Weather / 数据源与天气卡片 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S3-002 |
| 5 | S5-001 | 收缩 `main.zig`，固化 App/Shell 组装边界 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S4 全部 |
| 5 | S5-002 | 收缩 Renderer/旧布局/构建依赖，消除历史跨层债务 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S5-001 |
| 5 | S5-003 | Diagnostics、回归体系与 Goal 最终验收 | IMPLEMENTED | AUTO_PASSED | MANUAL_PENDING | S5-002 |

## 回退与变更记录

每一步在 `AGENTS.md` 追加独立记录，包含准确改动文件、自动命令/退出码、手工用例 ID 和逐步回退方法。任何代码回退只针对该步骤的变更，不重置工作区。V2 计划文件是用户提供的未跟踪文件，保留不改。
