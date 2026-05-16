# Dialogue Tool Evaluation

更新时间：2026-05-16

## 结论

本分支不接入外部对话插件。当前最合适的路线是继续使用 `residents.json`、`wishes.json`、`resident_states`、`wish_progress`、`memory_log` 和 `personal_messages` 做轻量居民反馈；等居民剧情需要真正的分支对白 UI 时，优先评估 `nathanhoad/godot_dialogue_manager`，再考虑 Dialogic。

## 当前项目需求

《看得见的一公里》当前不是视觉小说结构，而是 10 天社区治理卡牌 Demo。居民对白需要满足：

- 能读取 `resident_states` 中的满意度、健康、位置、愿望进度和记忆。
- 能根据 `wish_progress`、`memory_log`、`active_problems` 显示不同留言。
- 不能破坏本地离线可玩、存档兼容和 `run_tests.bat`。
- 不能让主循环依赖远程 AI 或大型演出插件。

## Dialogic 评估

项目地址：[dialogic-godot/dialogic](https://github.com/dialogic-godot/dialogic)

文档：[Dialogic 2 Documentation](https://docs.dialogic.pro/)

优点：

- 适合完整剧情演出、视觉小说、角色立绘、时间线事件和演出控制。
- 有角色系统、立绘/Portrait 管理、Timeline 编辑器，适合未来做 Day -1、结局庆典、重点居民剧情演出。
- MIT 许可证，许可风险低。

风险：

- Dialogic 2 文档标注仍处于 Alpha，工作流和 API 可能变化。
- 它的优势在“演出系统”，而当前居民需求更偏数据驱动反馈，直接接入会增加项目复杂度。
- 需要新增插件资源、时间线文件和 UI 适配，超出本分支“增强居民愿望链和记忆系统”的最小目标。

适配方式：

- 未来若接入，可只用于特殊剧情节点，例如 Day -1 开场、Day 10 年报后日谈、单个居民关键愿望完成演出。
- 条件入口仍应由本项目控制：先由 `ResidentSystem` 根据 `resident_states` 选出剧情 key，再启动 Dialogic timeline。

## Dialogue Manager 评估

项目地址：[nathanhoad/godot_dialogue_manager](https://github.com/nathanhoad/godot_dialogue_manager)

文档：[Dialogue Manager for Godot](https://dialogue.nathanhoad.net/)

条件与变更文档：[Conditions and Mutations](https://www.mintlify.com/nathanhoad/godot_dialogue_manager/writing/conditions-and-mutations)

优点：

- 偏轻量分支对白，适合“居民留言 + 条件分支 + 少量选择”的需求。
- 支持条件、变量、mutation 和额外 game states，方便把 `resident_states`、`wish_progress`、`memory_log` 作为对白条件来源。
- GitHub 版本说明显示 MIT 许可证，并已有 Godot 4.6 对应版本，和当前 Godot 4.6.2 更贴近。

风险：

- 仍然需要引入插件、维护 dialogue 资源和本地化流程。
- 如果直接让对白 mutation 改 `GameState`，会绕过当前 `ResidentSystem`、`ResourceManager`、`SaveManager` 的安全边界。

建议适配方式：

- 不让对白脚本直接写 `GameState`。
- 增加一个只读适配器，例如 `ResidentDialogueContext.gd`，提供：
  - `has_completed_wish(resident_id, wish_id)`
  - `latest_memory_contains(resident_id, keyword)`
  - `resident_satisfaction_at_least(resident_id, value)`
  - `has_active_problem_for(resident_id)`
- 对话完成后的奖励仍回到 `ResidentSystem.record_memory()` 或已有愿望奖励路径处理。

## 本分支选择

本分支采用“内建轻量方案”：

- 居民数据增加 `concerns`、`starting_messages`、`memory_seeds`。
- `ResidentSystem.build_initial_states()` 把这些字段带入运行态。
- 愿望完成继续使用既有 `record_memory()`、`personal_messages`、`trust` 奖励和自治点路径。
- 年度报告从 `memory_log` 和 `wish_progress` 里生成居民结果摘要。

这样能满足当前玩法反馈目标，同时保留未来接 Dialogue Manager 或 Dialogic 的入口。
