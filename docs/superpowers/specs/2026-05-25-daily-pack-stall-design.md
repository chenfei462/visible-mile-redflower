# 每日卡包柜台设计

## 目标

把当前"公告栏 = 每天 5 张明牌（2 许可 + 3 材料）"改造成 Stacklands 式的**每日卡包柜台**：顶部一排不同价位的卡包按钮，每个卡包对应一个主题，打开后卡片散落到桌面。每日刷新柜台内容，但卡包数量、价位、主题都是当天独立配方。

参考视频帧（`C:\Users\hacjr\Downloads\1388127494.mp4`）：顶部黑色按钮条 `1G / 3G / 4G / 10G / 10G / 15G / 20G / 26G`，每个按钮一个卡包。本设计沿用这一形态，但保留小红花社区的"每日刷新"作为差异化。

## 问题总结

当前 `公告栏` 现状：

- 每天固定 5 张明牌平铺展示（2 许可 + 3 材料）。
- `PrototypeRules.generate_daily_bulletin()` 用 `(offset + i) % size` 轮询，无随机、无主题、无价位差异。
- 玩家"拿"卡是一次性的，没有"开包"的期待感。
- 价格只在第 5 天后的付费模式才出现，且仅是"剩余卡的售卖兜底"。
- 与参考视频的"柜台 + 多档卡包 + 随时购买"形态完全不同。

参考视频里的核心信号：

- 卡包按钮**常驻顶部**而不是落到玩家手里。
- 同一时刻有**多种主题**：基础包、村民包、稀有包，价位反映稀有度。
- 玩家**用游戏内资源购买**（视频里是金币），不是"每日限领"。
- 卡包打开后卡片**散落到桌面**，玩家自己整理。

## 设计结论

把公告栏改成"每日卡包柜台 + 桌面散落"。柜台**每日刷新**保留小红花社区原有的节奏感和教学控制力，但每张"明牌"升级为一个"卡包按钮"。

核心要素：

- 柜台 = 顶部 5~8 个卡包槽位。
- 每个槽位 = 1 个**卡包配方**（包名 + 主题 + 价格 + 内含卡数 + 主题权重）。
- 玩家用**小红花 / 资金 / 人力**购买（不同包用不同资源结算）。
- 购买后卡片**散落到桌面**，不再有"手牌区"概念。
- 柜台每日黄昏后刷新，未购买的卡包消失。

## 方案对比

### 方案 A：完全照搬 Stacklands 常驻菜单

包不刷新，永远在售。优点是 Stacklands 原汁原味，缺点是失去"每日节奏"和教学控制点，且和现有 `opening_playability_plan.json` 编排冲突。

### 方案 B：每日卡包柜台（推荐）

柜台每天刷一次，5~8 个不同主题/价位的卡包。保留日周期节奏，同时拿到 Stacklands 的"挑包"手感。

### 方案 C：单一"今日社区包"

每天只刷 1 个大包，玩家点击抽出全部内容。改动最小但失去"挑包"策略点，与视频差距大。

**选方案 B。**

## 数据层设计

### 新增 `data/card_packs.json`

每个卡包是一个配方：

```json
{
  "pack_id": "starter_materials",
  "name": "邻里物资包",
  "theme": "neighborhood",
  "cost": { "resource": "funds", "amount": 3 },
  "card_count": 3,
  "composition": {
    "material": { "min": 2, "max": 3 },
    "building_permit": { "min": 0, "max": 1 }
  },
  "card_pool": ["lumber_pack", "paint_bucket", "fabric_roll", "notice_design"],
  "guaranteed_cards": [],
  "unlock_condition": null,
  "art": "pack_neighborhood.png",
  "description": "基础材料和偶尔的许可。"
}
```

字段说明：

- `cost.resource`: `flowers / funds / manpower` 之一。
- `card_count`: 这个包打开后产出几张卡。
- `composition`: 配额约束（必须满足 min/max）。
- `card_pool`: 候选 card_id 池，与 `composition` 一起决定具体出什么。
- `guaranteed_cards`: 强制必出的卡，配合开局教学。
- `unlock_condition`: 信任值阈值 / 完成事件 / 日数等解锁条件。

候选包初版（覆盖现有玩法 + 留扩展位）：

| pack_id | 名称 | 主题 | 价格 | 卡数 | 解锁 |
|---|---|---|---|---|---|
| `starter_materials` | 邻里物资包 | neighborhood | 3 资金 | 3 | 始终 |
| `accessibility_kit` | 无障碍工具包 | accessibility | 4 小红花 | 3 | 始终 |
| `housing_permit_pack` | 住宅许可包 | housing | 2~ 资金（阶梯） | 1 | 始终 |
| `volunteer_permit_pack` | 志愿者站许可包 | volunteer | 2~ 小红花（阶梯） | 1 | 始终 |
| `emergency_supplies` | 应急物资包 | emergency | 5 小红花 | 3 | 完成第 1 次应急事件 |
| `commerce_lot` | 商业地块包 | commerce | 8 资金 | 2 | day >= 3 |
| `greenery_box` | 绿化苗木包 | greenery | 6 小红花 | 3 | 信任 >= 30 |
| `rare_blueprint` | 稀有图纸包 | mixed | 12 小红花 | 1 | 信任 >= 60 |

数量保留弹性：柜台只显示当日刷出的 5~8 个，剩下未解锁的不出现。

### `data/day_sequence.json`

新增：

```json
{
  "pack_stall_size_per_day": 6,
  "pack_stall_min_themes": 3
}
```

`pack_stall_size_per_day` 控制柜台一次显示几个包；`pack_stall_min_themes` 控制主题最低多样性，避免一天全是同主题。

旧字段 `bulletin_cards_per_day` / `player_card_choices_per_day` 保留作为兼容回退。

### `data/opening_playability_plan.json`

`bulletin_card_ids` 语义改为 `guaranteed_pack_ids`（保底必出包）：

```json
{
  "day": 1,
  "guaranteed_pack_ids": ["starter_materials", "accessibility_kit", "volunteer_permit_pack"],
  "themed_pool_weights": { "neighborhood": 2, "accessibility": 1 }
}
```

旧字段同名保留，迁移期 PrototypeRules 同时识别两种字段名。

### `data/cards.json`

不动卡牌本身。`themes` 字段后续若做"愿望链回填驻扎"时再加。本次 spec 只需要卡包配置。

## 代码层设计

### `scripts/core/CardPackSystem.gd`

文件已存在（86 行级别），当前只承担"开包动画"角色。本次扩展为柜台核心模块：

```gdscript
static func roll_daily_stall(
    available_packs: Array[Dictionary],
    guaranteed_pack_ids: Array[String],
    theme_weights: Dictionary,
    stall_size: int,
    min_themes: int,
    state: Dictionary,
    rng_seed: int
) -> Array[String]  # returns pack_ids on the stall today

static func can_purchase_pack(
    pack_def: Dictionary,
    state: Dictionary
) -> Dictionary  # {allowed, cost_resource, cost_amount, reason}

static func purchase_pack(
    pack_def: Dictionary,
    state: Dictionary,
    rng_seed: int
) -> Array[String]  # returns spawned card_ids, deducts cost in state
```

行为：

1. `roll_daily_stall` 先放入所有 `guaranteed_pack_ids`，再按主题加权抽满 `stall_size`，并强制至少 `min_themes` 种主题。
2. `can_purchase_pack` 检查资源 / 解锁条件 / 阶梯价格（住宅 / 志愿者站走 `permit_purchase_counts`）。
3. `purchase_pack` 按 `composition` + `card_pool` 用确定性 RNG 抽出 `card_count` 张，扣资源，返回 card_id 数组。

### `scripts/core/PrototypeRules.gd`

废弃 `generate_daily_bulletin / claim_bulletin_card / bulletin_purchase_cost_for_card / return_hand_card_to_bulletin` 中的"明牌挑选"分支。保留方法签名但内部改成 thin wrapper 调用 `CardPackSystem`，避免大量调用方一次性改完。

`bulletin_paid_mode_enabled` 删除（柜台本身就是付费）。

### `scripts/ui/MainView.gd`

变更最小化，但分两层：

UI 容器层：

- `bulletin_container` 改名职责为 `pack_stall_container`，仍是 `HFlowContainer`。
- 每个槽位渲染为一个 `PackButtonView`（新组件，扔到 `scripts/ui/modules/`），显示包名/价格/主题图标。
- 点击触发 `CardPackSystem.purchase_pack`，购买成功后卡片以扩散动画落到桌面。

状态层：

- `bulletin_cards: Array[String]` 改名 `stall_pack_ids: Array[String]`。
- `bulletin_card_prices` 删除（价格走 `card_packs.json`）。
- `hand_cards` 数组取消"公告栏免费拿 N 张"语义，全部走"买包→散落到桌面"路径。
- 仍保留 `hand_cards` 数组用于过渡兼容（卡片散落实质是直接 spawn 到 `tabletop_cards`）。

兼容：

- `bulletin_free_pick_limit / claim_bulletin_card_from_ui / return_hand_card_to_bulletin / set_bulletin_cards_state` 全部保留，但实现内部走新柜台逻辑或返回 no-op，避免旧测试 / 旧存档读档失败。

### `scripts/autoload/SaveManager.gd`

新增字段：

- `stall_pack_ids: Array[String]`
- `stall_rng_seed: int`
- 旧 `bulletin_cards / bulletin_card_prices` 仍写入但只用于兼容旧版本读取。

### `scripts/autoload/TutorialManager.gd`

`first_pick_done` 语义改为"购买过第一个卡包"。新增 `first_pack_open_done` 字段记录开包教学完成，避免旧 `selected_cards_today` 计数与新柜台产生歧义。

## UI 表现

### 顶部柜台条

视觉参考视频帧 5/7：

- 顶部一排 5~8 个**黑色矩形按钮**，宽度均匀。
- 每个按钮上半部显示包名（白字），下半部显示价格 + 资源图标。
- 按钮间距与桌面同等清爽，禁止再叠任何"卡牌槽位"概念。
- 鼠标悬停时按钮下方弹出 tooltip：包内主题、产出预览（不显示具体卡，只显示分类）。
- 资源不足时按钮变灰，价格变红。

### 开包动画

- 玩家点击按钮 → 按钮短暂下凹 → 卡片以扇形从按钮位置弹出 → 散落到桌面中央偏下区域。
- 卡片落地时有随机角度偏移（±5°）和位置抖动，避免完全对齐——保留 Stacklands 的"随手扔在桌上"质感。
- 落地后立即可拖、可堆叠。

### 不再保留的元素

- 手牌区抽屉（验收清单 §1 已要求自由桌面，本 spec 完成最后一步）。
- "今日已选 N/M" 计数器（柜台是付费，不限次数）。
- 公告栏退卡功能（`return_hand_card_to_bulletin`）。

## 经济与平衡

### 起始资源

为了保证玩家第一天能开 1~2 个包：

- 资金初始 3，可买 1 个 `starter_materials`。
- 小红花初始 2，可买 1 个 `volunteer_permit_pack`（首档价 2）。

具体数值放到 `data/initial_state.json` 或现有 `GameState` 初始化里调，spec 不锁死。

### 包价格分布

参考视频 1G / 3G / 4G / 10G / 10G / 15G / 20G / 26G 的分档思路：

- 入门包（小红花/资金 2~4）：每天必出 2 个，保证推进。
- 中档包（5~10）：每天出 2~3 个，匹配当天主题。
- 高档包（12+）：每天出 0~2 个，门槛是信任 / 日数 / 事件。

### 房屋 / 志愿者站阶梯价

保留现行 `bulletin_purchase_cost_for_card` 里 `2 + purchased_count * 2` 的阶梯逻辑，搬到 `housing_permit_pack / volunteer_permit_pack` 的 `cost.amount` 计算里。

## 兼容性

### 存档

旧存档加载后：

- `bulletin_cards / bulletin_card_prices / selected_cards_today` 字段仍读取，但被 `stall_pack_ids` 覆盖前先用一次以填充第一天柜台（避免读档进入空柜台）。
- 后续日子按新柜台逻辑刷新。

### 测试

需要改动的现有测试（点名）：

- `tests/bulletin_paid_purchase_os_click_smoke.gd`：从"买未挑明牌"改为"点击柜台付费按钮"。
- `tests/first_10_minutes_smoke.gd`：开局从"公告栏选 3 张"改为"买 starter_materials + accessibility_kit"。
- `tests/full_game_smoke.gd`：所有"模拟点击公告栏第 N 个"改为"模拟点击柜台 pack_id = X"。
- `tests/test_core.gd`：新增针对 `CardPackSystem.roll_daily_stall / purchase_pack` 的回归。

## 测试策略

先写失败测试：

1. `roll_daily_stall` 在固定 seed 下产出包列表稳定。
2. `guaranteed_pack_ids` 一定出现在结果里。
3. `min_themes` 满足时返回包至少覆盖 N 种主题。
4. 资源不足时 `can_purchase_pack` 返回 `allowed=false` 并给出 `reason`。
5. 同一日反复购买同一个 `housing_permit_pack`，价格按 `2 + purchased * 2` 递增。
6. `purchase_pack` 用固定 seed 时，产出 card_id 列表稳定。
7. 旧存档加载时不报错，第一天柜台用兼容回退填充。

## 范围外

- 卡包美术素材（占位用纯色按钮 + 包名文字即可，等美术阶段统一上）。
- 卡牌边框分色（属于"卡面可读性"独立 spec，与卡包柜台解耦）。
- 卡牌详情面板（左下角 tooltip 常驻形态，独立改）。
- 堆叠 + 倒计时合成（见 `2026-05-25-stacking-work-timer-design.md`）。
- 季节系统 / 周报系统等长期玩法。

## 风险

1. **`MainView.gd` 9278 行**：柜台 UI 改造和现有 `tabletop_controller`、教学 coachmark、任务面板都耦合。建议先在 `scripts/ui/modules/` 下抽 `PackButtonView` 和 `PackStallBar`，主文件只调度。
2. **存档迁移**：旧 `bulletin_cards` 字段同时被读和写，迁移期要 print 一行警告，便于排查。
3. **教学链断点**：新手最早接触的"拿卡"动作语义变成"买包"，`TutorialManager` 和 `data/tutorial.json` 文案需要同步重写，否则前 5 分钟体验会断裂。
4. **资源经济不匹配**：当前初始资金/小红花是按"免费拿 3 张"设计的，柜台付费后可能在第 1 天就资源紧张。需要在调通流程后回查 `初始_state` 数值。

## 实施顺序

1. 创建 `data/card_packs.json`，写好 8 个候选包。
2. 在 `CardPackSystem.gd` 实装 `roll_daily_stall / can_purchase_pack / purchase_pack`。
3. 写失败测试，跑红。
4. 实装柜台逻辑，跑绿。
5. `MainView.gd` 改 `bulletin_container` 渲染为 `PackButtonView`，新逻辑接入。
6. 迁移 `tutorial.json` 文案 + `TutorialManager` 字段。
7. 改 smoke 测试。
8. 调初始资源与第一天柜台默认配方。
9. 删除/no-op 化旧公告栏代码路径。
