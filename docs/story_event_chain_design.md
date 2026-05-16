# Story Event Chain Design

更新时间：2026-05-16

## 目标

本分支新增一条 5 段式社区剧情链：旧小区公共空间重建。它不是纯文本剧情，而是通过已有事件系统进入治理循环：玩家需要分配人力处理问题，处理结果影响 `trust`、自治点、居民满意度和 Day 10 年度报告。

## 设计原则

- 不新增大型剧情系统。
- 不依赖远程 AI。
- 使用现有 `fixed` 事件、`chain_id`、`chain_step`、`reward`、`penalty`。
- 失败也进入 `resolved_problem_history`，年度报告可以看到推进和过期情况。
- 剧情链不是通关硬门槛；它提供额外信任、自治和居民反馈。

## 事件链

统一链 ID：`chain_public_space_rebuild`

1. `event_public_space_idle_complaint`
   - Day 4 触发。
   - 主题：居民抱怨公共空间被杂物和旧椅子闲置。
   - 居民：张阿姨、李师傅。
   - 奖励：`trust +1`。
   - 惩罚：`trust -1`、满意度压力。

2. `event_public_space_first_cleanup`
   - Day 5 触发。
   - 主题：玩家用人力协调第一次清场，也可借既有设施和导流体系减轻压力。
   - 居民：李师傅、阿强。
   - 奖励：`funds +1`、`trust +1`。
   - 惩罚：`funds -1`、满意度压力。

3. `event_public_space_need_split`
   - Day 6 触发。
   - 主题：不同居民提出不同需求，休息、故事墙、送餐路线发生分歧。
   - 居民：王奶奶、孙同学、高美华。
   - 奖励：`trust +2`。
   - 惩罚：`trust -1`、满意度压力。

4. `event_public_space_shared_schedule`
   - Day 8 触发。
   - 主题：公共空间成形后，需要共享时段表治理使用冲突。
   - 居民：小林、高美华、孙同学。
   - 奖励：`trust +2`。
   - 惩罚：`trust -1`、满意度压力。

5. `event_public_space_year_end_review`
   - Day 10 触发。
   - 主题：把公共空间重建过程写进年度报告。
   - 居民：张阿姨、李师傅、孙同学。
   - 奖励：`flowers +1`、`trust +2`。
   - 惩罚：`trust -1`、满意度压力。

## 年度报告接入

`AnnualReportSystem.build_report()` 会从 `resolved_problem_history` 扫描所有带 `chain_id` 的问题状态，并生成 `story_chain_summary`。

对 `chain_public_space_rebuild`，报告会按结果生成不同文案：

- 全部或大部分解决：公共空间从闲置角落变成共享空间。
- 部分过期：公共空间推进了，但仍有反馈未收好。
- 过期多于解决：公共空间重建留下分歧，需要下一年继续回应。

这不是唯一结局，只是年度报告中的剧情总结。

## 对话工具评估

Dialogic：[dialogic-godot/dialogic](https://github.com/dialogic-godot/dialogic)

- 适合角色立绘、剧情演出、时间线和 Day 10 后日谈。
- 当前剧情链只需要事件文本、奖惩和年度报告，不需要接入。

Dialogue Manager：[nathanhoad/godot_dialogue_manager](https://github.com/nathanhoad/godot_dialogue_manager)

- 更适合轻量分支对白。
- 未来可把 `chain_id`、`chain_step`、`wish_progress`、`memory_log` 暴露给对白条件。
- 当前先保留内建事件链，避免引入插件和新资源格式。

## 后续扩展

- 若要让每段剧情出现居民对话，可以先在 `docs/dialogue_tool_evaluation.md` 的轻量方案上加只读上下文适配器。
- 若要做演出，则把 Day 10 的公共空间总结接入 Dialogic timeline，而不是替换事件系统。
