你现在在项目 `C:\Users\hacjr\Desktop\小红花社区` 中工作。请在当前代码基础上完成一项局部重构，并严格按 TDD + 分步验收执行。不要只给分析或计划，直接实现；但每一阶段都必须先补/改测试，再运行脚本验证，再改代码。

## 目标
将“居民需求”落实为每天开局就全部出现的实体需求卡 / 需求实体，并完成对应的服务建筑结算规则：

- 每天开局，所有居民都要生成 1 个可见的需求实体，沿用现有 resident persona / need_tags 映射。
- 服务建筑容量统一为 2。
- 被服务建筑满足的需求：每个需求结算 `+1 小红花 +1 资金`。
- 如果社区里不存在对应需求标签的服务建筑，则允许使用小红花兜底：
  - 同一天第 1 次兜底消耗 1 朵小红花
  - 同一天第 2 次兜底消耗 2 朵小红花
  - 兜底只算“满足需求”，不给 `小红花 / 资金` 收益
- 如果存在对应服务建筑，但容量用尽，不允许再走“小红花兜底”；这些需求应记为未满足。
- 黄昏结算后清空当日需求；下一天开局重新生成。
- 不要把旧的 `problem / wish / trust` 逻辑重新接回这条链路。

## 当前代码中的关键落点（先读后改）
- `scripts/core/ResidentSystem.gd`
  - `spawn_daily_need_entities`
  - `settle_daily_need_entities`
- `scripts/autoload/DayCycle.gd`
  - `resolve_sunrise`
  - `resolve_dusk`
- `scripts/autoload/GameState.gd`
- `scripts/ui/MainView.gd`
  - `_pending_resident_need_entities`
  - 需求相关 UI copy / dusk summary / runtime hint
- `scripts/ui/CardView.gd`
  - 需求卡的可见文案
- `tests/test_core.gd`
  - `_test_resident_need_entities_and_moral_settlement`
  - 与 MainView 需求文案、日切换、自动结算相关的测试
- `tests/first_10_minutes_smoke.gd`
- `tests/full_game_smoke.gd`

## 工作方式约束
1. 严格 TDD：
   - 先写 / 改失败测试
   - 跑脚本确认它真的失败在正确原因上
   - 再写最小实现让它通过
2. 每一阶段结束都要跑对应测试脚本并记录：
   - 执行命令
   - 退出码
   - 关键 PASS / FAIL banner
3. 不要重写整套系统；优先收口现有 resident need 实现。
4. 不要顺手做无关重构。
5. 不要引入新的 legacy 兼容层。
6. 如果 `MCP Bridge Game` 9601 端口或 `PlaytestServer` 9876 端口已占用，只要脚本退出码为 `0` 且 PASS banner 正确，可视为已通过；把它记为环境噪声而不是功能失败。

## Phase 0：建立基线
先阅读上述文件，然后运行基线测试，确认当前起点。

命令：
- `.\run_tests.bat`

基线验收：
- 记录 `ALL TESTS PASSED` 或当前真实失败信息。
- 如果基线不绿，先判断是否与本任务直接相关；只处理与本任务相关的失败。

## Phase 1：先把核心规则测试写成 / 改成会失败
优先修改 `tests/test_core.gd`，不要先改生产代码。

至少覆盖这些断言：
1. `spawn_daily_need_entities` 为每个居民生成 1 个需求实体。
2. 需求实体写回 `state["resident_need_entities"]`。
3. 每个需求实体沿用 resident 的 `need_tags`。
4. `service_capacity` 固定为 `2`。
5. 一栋匹配服务建筑最多满足 `2` 个需求。
6. 被建筑满足的每个需求都结算 `flowers +1` 和 `funds +1`。
7. 没有对应建筑时，单日前两次可用小红花兜底，成本依次为 `1 / 2`，且不给资源收益。
8. 如果有对应建筑但容量耗尽，不能再走兜底，而是记为未满足。
9. 未满足需求会进入民心扣减逻辑；全部满足则民心 `+1`。
10. 黄昏结算后需求列表被清空；下一天 `sunrise` / 新一天开始时重新生成。
11. `resolve_dusk()` 的结算文案继续包含 `满足 / 小红花兜底 / 未满足 / 民心`。
12. 如有必要，补 MainView / CardView 的 UI 测试，确保“需求卡在白天开局就存在”而不是只在结算时出现。

本阶段验收脚本：
- `godot_console --headless --path . --script res://tests/run_tests.gd --quit`
  - 如果本机没有 `godot_console`，使用仓库现有入口：`.\run_tests.bat`

本阶段通过标准：
- 新增 / 修改的断言先失败一次，再在实现后通过。
- 最终出现 `ALL TESTS PASSED`。

## Phase 2：实现 ResidentSystem 与 DayCycle 规则
在测试保护下收口生产代码。重点检查并必要时修改：

- `scripts/core/ResidentSystem.gd`
  - `spawn_daily_need_entities`
  - `settle_daily_need_entities`
  - 保持 resident persona -> need_tags 映射
- `scripts/autoload/DayCycle.gd`
  - 确保 `sunrise` / 新一天开始时，所有居民需求都会生成
  - 确保 `dusk` 统一结算，并清空当天需求
- `scripts/autoload/GameState.gd`
  - 如状态初始化字段需要补齐，只做本任务必须的最小修改

实现时必须保证：
- “无建筑时才可兜底”，而不是“有建筑但容量满了也能兜底”。
- 兜底计数按“当天全社区”计算，不是按居民单独计算。
- 建筑满足与兜底满足都算“已满足”，但只有建筑满足会产生 `+1 小红花 +1 资金`。
- 当天需求结算后，`resident_need_entities` / `resident_need_queue` / `daily_need_queue` 一致清空。
- 下一天开局重新生成完整需求集。

本阶段验收脚本：
- `godot_console --headless --path . --script res://tests/run_tests.gd --quit`
  - 或 `.\run_tests.bat`

本阶段通过标准：
- 出现 `ALL TESTS PASSED`。
- 不出现把旧 `problem / wish / trust` 逻辑重新接回来的回归。

## Phase 3：同步表现层与可见交互
如果 Phase 1 / 2 的测试揭示表现层不一致，补齐这些位置：

- `scripts/ui/MainView.gd`
  - 白天开局的需求可见性
  - 需求提示文案
  - 黄昏结算摘要文案
  - runtime hint 中关于“容量 2”与“1 / 2 朵兜底”的描述
- `scripts/ui/CardView.gd`
  - 需求卡 / 需求实体的正面文案，确保玩家能看到：
    - 需求类型
    - 服务容量 2
    - 无建筑时可用 1 / 2 朵小红花兜底
- 如已有 tutorial / coachmark / summary 测试受影响，同步修正，但不要扩大范围

本阶段验收脚本：
- `godot_console --headless --path . --script res://tests/run_tests.gd --quit`
- `godot_console --headless --path . --script res://tests/first_10_minutes_smoke.gd --quit`

本阶段通过标准：
- 出现 `ALL TESTS PASSED`。
- 出现 `FIRST 10 MINUTES SMOKE PASSED`。

## Phase 4：更新 smoke，验证真实流程
更新并验证 smoke，使它们真正覆盖这条新规则：

- `tests/first_10_minutes_smoke.gd`
  - 断言 day start 已生成 resident need entities
  - 断言放置服务建筑后，dusk 结算能产生建筑满足收益
  - 断言不再依赖 legacy problems / wishes
- `tests/full_game_smoke.gd`
  - 断言连续多天里 resident needs 每天重新出现
  - 断言服务容量 2 生效
  - 断言“无建筑时 1 / 2 朵兜底”生效
  - 断言有匹配建筑但容量满时，不会错误地兜底
  - 断言民心结算与无限模式日循环不被破坏

本阶段验收脚本：
- `godot_console --headless --path . --script res://tests/first_10_minutes_smoke.gd --quit`
- `godot_console --headless --path . --script res://tests/full_game_smoke.gd --quit`

本阶段通过标准：
- 出现 `FIRST 10 MINUTES SMOKE PASSED`。
- 出现 `FULL GAME SMOKE PASSED`。

## Phase 5：最终全量回归
完成后必须跑完整回归，不要跳过：

- `.\run_tests.bat`
- `godot_console --headless --path . --script res://tests/first_10_minutes_smoke.gd --quit`
- `godot_console --headless --path . --script res://tests/full_game_smoke.gd --quit`

最终完成定义：
- 居民需求在每天开局全部出现。
- 服务建筑容量统一为 `2`。
- 建筑满足需求给 `+1 小红花 +1 资金`。
- 仅在“完全没有对应建筑”时允许 `1 / 2` 朵小红花兜底。
- 有建筑但容量满时，该需求应未满足，不得兜底。
- `dusk` 摘要 / UI 文案 / smoke / core tests 全部与新规则一致。
- 所有上述脚本退出码为 `0`，且出现对应 PASS banner。

## 最终回复格式
完成后不要只说“done”。请按下面格式汇报：
1. 改了哪些文件
2. 每个阶段跑了什么命令
3. 每个命令的退出码与 PASS banner
4. 是否存在环境噪声（例如 `9601 / 9876` 端口占用）
5. 还有没有未完成项或风险点

现在开始执行。
