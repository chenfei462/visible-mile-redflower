# 堆叠工作倒计时设计

## 目标

把当前"双卡放入合成槽 → 瞬时合成"和"居民驻扎到建筑 → 自动产出"两套机制统一为 Stacklands 式的**堆叠 + 倒计时工作**：

- 把一张卡叠到另一张卡上 → 系统识别该堆栈匹配的"工作"配方 → 在堆顶卡牌上显示进度条 → 倒计时结束产出。
- 居民、材料、设施、问题卡全部通过同一套"堆叠工作"机制驱动，玩家不需要记忆"哪些卡是合成、哪些是驻扎、哪些是消解"。

参考视频帧（`C:\Users\hacjr\Downloads\1388127494.mp4`）：村民卡叠到浆果灌木卡上，左下角出现"采摘浆果灌木... 还剩 9.2 秒"。倒计时归零后，村民回到桌面，浆果灌木被消耗，产出"浆果"卡。

## 问题总结

当前合成 / 驻扎现状：

- `craft_slots: Array[String]` 是写死的两个槽位，玩家拖到槽里才能合成。
- `RecipeRules.find_matching_recipe()` 走纯数据匹配，没有"工作时间"概念。
- 居民驻扎走另一条路径：建筑落地 + 居民分配 → 黄昏自动结算产出。
- 玩家需要区分"合成区""桌面""建筑驻扎位"三种交互，认知负担重。
- 与参考视频"任何堆栈都自动识别工作"的形态完全不同。

参考视频里的核心信号：

- **没有合成槽**，桌面就是工作台。
- **堆栈识别**：村民 + 浆果灌木 = "采摘"工作。
- **进度条**显示在堆顶卡片上方，附带文字描述。
- **倒计时归零产出**：原料卡按规则消耗（资源节点消耗，工人卡释放回桌面）。
- **被打断**：玩家把工人卡从堆栈中拖走 → 进度立刻清零。

## 设计结论

以"堆栈 = 隐式工作单元"为核心，重写合成 / 驻扎链路：

1. `craft_slots` 整体删除。
2. 新增 `tabletop_stacks: Array[Dictionary]` 数据结构，每个 stack 记录卡片 id 列表 + 当前匹配的工作 + 进度。
3. 合成、驻扎、问题消解、采集统一为 `work_definition`，配方写在新文件 `data/works.json`。
4. UI 在堆顶卡片上渲染**圆环进度条** + 工作名称。
5. 玩家从堆栈中拖走任意一张卡 → 工作中止，进度归零。

## 方案对比

### 方案 A：堆栈识别 + 倒计时工作（推荐）

完全照搬 Stacklands 行为。改动量大但语义统一。

### 方案 B：保留合成槽，只在桌面叠加倒计时驻扎

合成不变，居民驻扎加倒计时。改动小但维持"两套并存"的认知负担，与视频差距大。

### 方案 C：堆栈识别但即时产出（无倒计时）

最小动作量但失去"工作感"。视频里倒计时本身就是核心张力来源，砍掉等于不抄。

**选方案 A。**

## 数据层设计

### 新增 `data/works.json`

```json
{
  "works": [
    {
      "work_id": "build_ramp",
      "name": "建设坡道",
      "required_cards": ["ramp_blueprint", "lumber_pack"],
      "optional_workers": ["resident_*"],
      "duration_sec": 6.0,
      "consumes": ["lumber_pack"],
      "preserves": ["ramp_blueprint"],
      "produces": [{"card_id": "community_ramp", "count": 1}],
      "rewards": {"flowers": 2, "trust": 1},
      "description": "把木料用许可建成坡道。"
    },
    {
      "work_id": "harvest_berry_bush",
      "name": "采摘浆果灌木",
      "required_cards": ["berry_bush"],
      "required_workers": ["resident_*"],
      "duration_sec": 9.0,
      "consumes": ["berry_bush"],
      "produces": [{"card_id": "berry", "count": 2}],
      "description": "村民去采浆果。"
    },
    {
      "work_id": "serve_resident_need",
      "name": "服务居民需求",
      "required_cards": ["service_facility_*", "resident_need_*"],
      "duration_sec": 4.0,
      "consumes": ["resident_need_*"],
      "preserves": ["service_facility_*"],
      "produces": [],
      "rewards": {"flowers": 1, "satisfaction_delta": 5},
      "description": "建筑处理居民需求。"
    }
  ]
}
```

字段说明：

- `required_cards`: 堆栈中**必须包含的 card_id 或匹配模式**（支持 `*` 通配）。
- `required_workers / optional_workers`: 单独标注"工人位"，因为产出后工人会被释放，原料会被消耗，需要区分。
- `duration_sec`: 倒计时长，0 表示瞬时（保留即时合成的兼容路径）。
- `consumes`: 工作结束后销毁的 card_id。
- `preserves`: 工作结束后保留的 card_id（典型如蓝图、建筑）。
- `produces`: 工作结束后新生成的卡。
- `rewards`: 资源 / 信任 / 满意度等状态修改。

### `data/recipes.json`

旧文件保留作为"瞬时合成"的兼容路径（`duration_sec = 0`），逐步把内容迁移到 `works.json`。短期内 `RecipeRules.find_matching_recipe()` 两套都查。

### `data/cards.json`

每张卡补充：

```json
{
  "card_id": "ramp_blueprint",
  "stack_role": "blueprint",
  "is_worker": false,
  "is_consumable": false
}
```

`stack_role` 用于 UI 渲染堆叠时的层级排序（worker > blueprint > material > resource）。
`is_worker` 标注居民、志愿者等可移动的"工人位"。
`is_consumable` 提示 UI 这张卡可能被工作消耗，用于显示警告。

## 代码层设计

### 新增 `scripts/core/StackingWorkRules.gd`

核心入口：

```gdscript
static func detect_works_for_stack(
    stack_card_ids: Array[String],
    works: Array[Dictionary]
) -> Array[Dictionary]  # all matching works, sorted by priority

static func tick_stack_work(
    stack: Dictionary,
    delta_sec: float,
    works: Array[Dictionary]
) -> Dictionary  # {completed, progress_ratio, produced_cards, rewards}

static func apply_work_completion(
    stack: Dictionary,
    work: Dictionary,
    state: Dictionary
) -> Dictionary  # mutates state, returns produced card_ids and removed card_ids

static func cancel_work(stack: Dictionary) -> void  # progress = 0
```

行为：

1. `detect_works_for_stack` 扫描所有 works，找到 `required_cards` 全部匹配的工作。多个候选时按优先级（设施 > 服务 > 采集 > 合成）选第一个。
2. 堆栈数据结构持久化为：
   ```gdscript
   {
       "stack_id": String,
       "card_ids": Array[String],
       "card_instance_ids": Array[String],  # 用于精确识别每张卡实例
       "current_work_id": String,
       "progress_sec": float,
       "position": Vector2
   }
   ```
3. 每帧 `_process` 调用 `tick_stack_work` 累加 `progress_sec`，到达 `duration_sec` 即触发完成。

### 修改 `scripts/core/RecipeRules.gd`

`find_matching_recipe()` 弃用，外部调用全部改走 `StackingWorkRules.detect_works_for_stack`。短期保留旧函数返回 empty，避免一次性改全部调用点。

### 修改 `scripts/core/ResidentSystem.gd`

`refill_residents_for_housing_capacity` 等迁入逻辑保留。

驻扎 / 产出相关：

- 删除"建筑落地 + 居民分配 → 自动产出"路径。
- 居民产出全部走"居民卡堆到建筑卡上启动工作"的统一路径。
- 满意度结算保留在黄昏阶段，但满意度增减直接来自完成的 `work` 的 `rewards` 累加。

### 修改 `scripts/ui/MainView.gd`

UI 层：

- 删除 `craft_slot_panels` 和合成区 UI。
- 桌面 `tabletop_controller` 新增"堆栈检测"：拖卡放下后检测和已有卡的距离，若 < `STACK_SNAP_PX`（建议 32px），加入对方堆栈。
- 堆顶卡片渲染圆环进度条 + 工作名 + 剩余秒数。
- 拖走任意一张堆栈中的卡 → 调用 `StackingWorkRules.cancel_work`。

状态层：

- `craft_slots / craft_slot_sources / craft_slot_prices` 全部删除。
- 新增 `tabletop_stacks: Array[Dictionary]`，持久化到存档。
- `hand_cards` 因柜台 spec 已退化为兼容字段，本 spec 进一步弃用。

### 修改 `scripts/core/PlayabilityDirector.gd`

`get_recipe_hints()` 升级为 `get_work_hints()`：

- 输入：桌面上所有卡 id。
- 输出：每张卡当前"如果叠到 X 上能启动 Y 工作"的提示。
- 复用 `2026-05-25-crafting-readability-design.md` 已经规划的卡面提示字段，把 `partner_card_id / result_card_id / result_name` 改为 `partner_card_id / work_id / work_name / duration_sec`。

合成可读性 spec 仍然有效，本 spec 只是把"合成"二字替换为"工作"。

## UI 表现

### 堆叠交互

- 拖卡放下时，若距离已有卡 < 32px 视为"叠到上面"。
- 叠加时自动整理：堆栈卡片按 `stack_role` 从下到上排列（resource < material < blueprint < worker），堆顶露出 28px 标题条。
- 叠加后系统自动检测工作；有匹配则立即开始倒计时。
- 玩家可以再叠卡进现有堆栈（如往"坡道建设中"的堆栈再加一个志愿者，会触发工作切换或加速，具体由 work_definition 决定）。

### 进度反馈

- 堆顶卡片上方：圆环进度条（顺时针填充）+ 工作名称浮在卡面上方。
- 剩余 < 1 秒时圆环闪烁 + 轻微脉冲。
- 完成瞬间：产出卡从堆栈中心弹出 + 短暂粒子（沿用现有 `FloatingNotifier`）。
- 工人卡完成后回到桌面（在堆栈位置附近）。

### 失败 / 中止

- 拖走任意原料 / 工人 → 进度条立即归零 + 工作名灰化 + 短促"嗯"音效。
- 不显示弹窗，不打断流程。

### 多个堆栈并行

- 桌面可同时存在任意数量的堆栈，每个独立 tick。
- 玩家可在堆栈之间切换工作流，体感接近 Stacklands 的"管理多个工作"。

## 与日周期的关系

用户已确认保留"下一天"按钮（玩家主动触发黄昏）。本 spec 配合规则：

- 黄昏触发时，**所有正在进行的工作不被打断**——进度保留到次日。
- 未处理的居民需求仍按当前规则在黄昏扣分。
- 这意味着玩家可以"工作做到一半就过夜"，符合 Stacklands 的"软时间"质感，又保留日周期的节奏感。

## 兼容性

### 存档

- 旧存档无 `tabletop_stacks` → 初始化为空数组。
- 旧 `craft_slots` 字段读到后：若内含卡片，自动 spawn 到桌面散落区，进度清零。
- 旧"已驻扎居民"字段读到后：居民卡 spawn 到对应建筑卡附近，但不自动启动工作（避免读档瞬间触发未预期产出）。

### 旧测试

- 凡是测试"`craft_slot[0] = X`"路径的，全部改为"在桌面 spawn 两张卡，调用 tabletop_controller.stack_at"。
- 期望"立即产出"的测试，按 `duration_sec` 用模拟时间 tick。

## 测试策略

先写失败测试：

1. `detect_works_for_stack` 在 stack `[ramp_blueprint, lumber_pack]` 时返回 `build_ramp`。
2. `tick_stack_work` 累加 `delta_sec` 到达 `duration_sec` 时标记 `completed = true`。
3. `apply_work_completion` 正确消耗 `consumes`、保留 `preserves`、生成 `produces`。
4. 工人卡完成后被释放（仍在桌面上），不被消耗。
5. 工作中拖走任意一张卡，进度归零，工作 ID 清空。
6. 多个候选 work 时按优先级返回第一个。
7. 旧存档加载后 `craft_slots` 内容自动落到桌面，无报错。
8. 黄昏切换不影响进度。

## 范围外

- 复杂的工作链路（A 产出物自动喂入相邻 B 堆栈）——这是 Stacklands 后期玩法，本 spec 不涉及。
- 工作加速 / 工人技能加成——后续平衡 spec。
- 工作失败概率 / 工作中事件干扰——后续事件 spec。
- 卡片碰撞物理 / 桌面整理按钮——UI 打磨阶段独立做。

## 风险

1. **进度持久化**：玩家在工作中保存退出，再进来工作要继续。`tabletop_stacks` 需要完整序列化进度。如果 Godot 主循环 `_process(delta)` 用作 tick，要把"游戏时间"和"实际时间"分开，否则暂停会出错。
2. **堆叠误触**：32px 阈值可能太小或太大，需要原型测试。建议加 `data/settings.json` 可调字段。
3. **配方迁移成本**：现有 40 条配方 + 后续愿望/事件触发的合成都要迁到 `works.json`。建议分批，先迁开局教学链（坡道/长椅/志愿者站/无障碍卡 4~6 条），其余继续走旧 `recipes.json` 路径。
4. **`MainView.gd` 9278 行**：tabletop 渲染逻辑当前混在 MainView 里。本 spec 强烈建议先把 `tabletop_controller` 抽到独立 controller 文件（已有同名变量但实现散在），再加堆叠工作。
5. **居民系统重写**：当前 `ResidentSystem.gd` 632 行有大量"驻扎到建筑→产出"逻辑。本 spec 要求废弃这一路径，迁移成本不可低估。

## 实施顺序

1. 抽 `scripts/ui/controllers/TabletopStackController.gd`，把 MainView 里现有的桌面拖拽 / 堆叠雏形挪过去。
2. 创建 `data/works.json`，先写 4~6 条核心工作（坡道、长椅、志愿者站、无障碍卡、采摘示例、服务需求示例）。
3. 实装 `StackingWorkRules.gd` 三个核心函数。
4. 写失败测试 + 单元测试。
5. 实装堆叠检测和进度 tick。
6. 在堆顶卡片上渲染圆环进度条（沿用现有 `CardView.gd` 增加 progress overlay）。
7. 迁移 `RecipeRules.find_matching_recipe()` 调用点。
8. 迁移 `ResidentSystem` 驻扎路径。
9. smoke 测试改造。
10. 删除 `craft_slots` 相关代码 + UI。
11. 把剩余配方批次迁到 `works.json`。

## 与其他 spec 的关系

- **`2026-05-25-daily-pack-stall-design.md`**：本 spec 与卡包柜台并行，**不互相阻塞**。柜台决定"卡从哪里来"，本 spec 决定"卡来了之后怎么用"。
- **`2026-05-25-crafting-readability-design.md`**：本 spec 把"合成"语义改为"工作"，可读性 spec 的卡面提示字段需要相应改名，但设计意图完全一致。
- **`2026-05-25-opening-flow-unification-design.md`**：开局 6 步骨架不变，但第 3 步"摆放"和第 4 步"解决需求"在新机制下都变成"启动工作"——开局流程文案需要小幅改写。
- **`2026-05-24-onboarding-guidance-redesign-design.md`**：教程"合成"和"驻扎"两步并为"叠卡片"一步，教学链路缩短。
