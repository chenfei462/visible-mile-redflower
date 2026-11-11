# 玩法可读性整改路线图

**状态：** Proposed
**日期：** 2026-05-26
**来源：** 用户反馈"游玩逻辑乱七八糟，不知道该咋玩"后的诊断 + 决策
**前置阅读：** [gameDesign.md](../gameDesign.md)、[docs/tabletop-stacklands-demo-followup-plan.md](tabletop-stacklands-demo-followup-plan.md)、[docs/superpowers/specs/2026-05-24-onboarding-guidance-redesign-design.md](superpowers/specs/2026-05-24-onboarding-guidance-redesign-design.md)

---

## 这份文档是什么

2026-05-26 的对话里，用户抱怨当前游戏"乱七八糟、不知道该咋玩"。诊断后定位到 5 个具体混乱点（见下"诊断结论"），并对方向做了决策：**维持 2026-05-21 commit `2cb0b1f` 的桌面堆叠瘦身决定**，不再把自治/评级/愿望链拉回来。

本文档把这次对话产出的待办固化下来，让以后回到这条主线时能从断点接着做。

---

## 已完成（本次会话）

- [x] **重写 gameDesign.md** 让它与代码现状对齐：删除棋盘 3×3 残影、信任阈值 25/50/75 误标、公告栏主入口幻觉等。文档第 9、10 节明确写出"自治 / 评级 / 双模式 / 愿望链已退出 demo 范围"。
- [x] **删手动「结束当天」按钮（Fork 1=b）**：`_on_advance_day()` 早被改成伪装设置面板入口（死代码），整体清除。底栏"结束今日"面板改名"今日动作"，抽屉的 end_day 面板拆掉。120 秒自动翻页是唯一推进方式。
  - 改动文件：`scripts/ui/MainView.gd`、`tests/test_core.gd`
  - 验证：`run_tests.bat` 全过

---

## 诊断结论：5 个混乱点（按破坏力排序）

| # | 现象 | 根因 | 状态 |
|---|---|---|---|
| 1 | 不知道核心目标 | Day -1 欢迎 + 任务区 + coachmark 三套引导同时说话 | **未解决**（看 Task A） |
| 2 | 不知道卡从哪来 | 公告栏废弃但命名/接口残留 | **未解决**（看 Task B） |
| 3 | 合成和解决需求长一样 | 两条路径都是 timed craft 进度环，UI 无区分 | **未解决**（看 Task C） |
| 4 | 时间压力来源不明 | 120 秒自动 + 手动结束当天并存 | ✅ 已解决（Task #1） |
| 5 | 需求卡两个容器 | `problems_container` + `resident_need_entities` 双轨 | **未解决**（看 Task D） |

---

## 待办（按建议顺序）

### Task A — 落地 onboarding redesign spec

**目标**：消除三层引导同时说话的混乱。完成后玩家任何时刻只看到一个主声音。

**依据**：[docs/superpowers/specs/2026-05-24-onboarding-guidance-redesign-design.md](superpowers/specs/2026-05-24-onboarding-guidance-redesign-design.md) 已经写好详细 spec，未落地。

**关键改动**：
1. `Day -1` 欢迎页瘦身为一张短欢迎卡（仅一句循环说明 + 四步预告 + "开始引导/跳过引导"）
2. 主界面中央教程覆盖层取消常驻
3. 左侧"教程目标"改造为"当前一步"卡（动作 + 为什么 + 去哪里 + 短进度）
4. 顶部 `tutorial_hint_label` 默认隐藏，仅极端兜底场景出现
5. 抽屉"Guide"重命名为"回看引导"，退为兜底入口
6. `TutorialManager` 拆分 `welcome_seen` 与 `completed_day_minus_one` 语义
7. coachmark / 当前一步卡 / 欢迎卡 三者职责分清楚

**预计文件**：`scripts/ui/MainView.gd`（高风险）、`scripts/ui/DayMinusOneView.gd`、`scripts/autoload/TutorialManager.gd`、`data/tutorial.json`

**风险**：MainView.gd 教程逻辑和 UI 刷新高度耦合。spec 第 11 节明确警告，要逐步移除中央覆盖层。

**验收**：
- 新开档先看到短欢迎卡，不是完整教学正文
- 主界面只有一个主引导区域
- 完成"选卡"后引导立即切到"合成"
- 顶部不再重复显示教程提示
- 抽屉里仍能回看
- `run_tests.bat` 通过

---

### Task B — 清理公告栏命名遗留

**目标**：卡源已经从公告栏迁移到卡包栏（commit `3685f11`），但代码里"bulletin" 命名/接口仍大面积存在，造成新人/未来的自己看代码时被误导。

**目前已知残留**：
- `bulletin_container` 节点名仍叫"公告栏"，实际功能是 CardPackShop 容器 (`MainView.gd:65`)
- `get_bulletin_card_action_state()` 函数名指向已废弃逻辑 (`MainView.gd:1825, 3847`)
- `_claim_bulletin_card_from_ui(index)`、`PROTOTYPE_RULES.clear_bulletin()` 等接口仍被调用，需逐个判断"还活着 vs 死代码"
- `bulletin_cards` / `bulletin_card_prices` / `current_bulletin_offset` 等字段
- `tests/test_core.gd:1508` 测试还在用 `next_day_cards` + `generate_daily_bulletin`
- `run_tests.bat:44` 行注释提到 bulletin UI 已移除但测试还没重写

**做法**：
1. 先 grep `bulletin` 在 `scripts/` 下的全部出现，分三档：
   - **活的**（仍被运行时路径调用）→ 重命名为 `card_pack_*` 或 `daily_pack_*`
   - **死的**（无人调用）→ 删除
   - **测试用的**（generate_daily_bulletin 等）→ 重写或删除
2. 函数名 + 变量名 + 节点名一起改，避免半改不改
3. 旧存档兼容：如果 `bulletin_*` 字段写进了存档，加迁移兜底

**预计文件**：`scripts/ui/MainView.gd`、`scripts/core/PrototypeRules.gd`、`scripts/autoload/SaveManager.gd`、`tests/test_core.gd`

**验收**：
- `grep -ri bulletin scripts/` 只剩历史注释或 SaveManager 兼容迁移块
- 测试全过

---

### Task C — 让"合成"和"解决需求"在 UI 上能区分

**目标**：现在两条路径都是 timed craft 进度环（2.5 秒起），玩家完全分不清"我在合成新卡"还是"我在服务居民"。

**做法（建议）**：
- 服务居民时：进度环颜色 / 中心图标 / 完成音效用一套**和合成不同**的视觉
- 居民头像 + 服务建筑高亮一闪表明这是服务行为
- 进度环里加一行小字"为 王奶奶 提供 出行服务"

**预计文件**：`scripts/ui/CardView.gd`（CraftProgressOverlay）、`scripts/ui/MainView.gd`（启动服务流程时传入区分参数）

**验收**：
- 视频/截图能清楚看出两种行为视觉不同
- 不要重写整套 timed craft 框架，只在表现层加分支

---

### Task D — 收口需求卡的双容器

**目标**：需求卡现在同时存在 `problems_container`（左侧 UI）和 `resident_need_entities`（桌面），两边都能拖、行为有微妙差异。

**做法**：
- 调查清楚两个容器是否真有不同语义（如左侧是"未拖出"、桌面是"已拖出"），还是只是历史包袱
- 如果是包袱：合成一个数据源，UI 只展示，不同时持有
- 如果有语义差异：在文档和 UI label 里讲清楚

**预计文件**：`scripts/ui/MainView.gd`（需求卡构建逻辑）、`scripts/core/ResidentSystem.gd`（spawn_daily_need_entities）

**验收**：
- 用户拖一张需求卡到设施上，无论从哪个容器拖出来行为一致
- 黄昏结算时不会出现"两个容器都有，结算只看其中一个"的漏算

---

### Task E — gameDesign.md 维护契约落地

gameDesign.md 第 15 节写了"代码与本文档不一致时以代码为准并改回文档"。但目前没有自动检查机制，靠人记。

**建议**（可选）：
- 加一个 `tests/design_doc_sync_smoke.gd`：扫几个关键不变量（信任阈值、卡牌总量、棋盘大小、120 秒/日），跟 gameDesign.md 字面对应
- 不变量漂移时测试失败，提示同步文档

---

## 不会做的（明确退出范围）

为了避免下次又被同样的想法绊倒，把以下事项明确钉死，**不再当作"待办"**：

- ❌ 复活 AutonomySystem.gd / 自治等级升级
- ❌ 复活 AnnualReportSystem.gd / 年度报告
- ❌ 复活 EndgameSystem.gd / D~S 评级 / 第 10 天结算
- ❌ 复活 PostGameSystem.gd / 新游戏+
- ❌ 复活 BalanceProfile.gd / demo_balance_targets.json
- ❌ 复活 wishes.json / 愿望链跨天进度系统
- ❌ 复活独立 events.json / 12 事件脚本（事件目前在 `opening_playability_plan.json` 里，足够 demo 用）

如果未来要把上面任何一项拉回来，**必须先**：
1. 反转 `2cb0b1f` 那次架构决定（写新 goal-prompt 说明为什么需要拉回来）
2. 同步更新 `tests/test_core.gd:404-447` 的 legacy 守卫
3. 跟 `docs/tabletop-stacklands-demo-followup-plan.md` 对齐方向

---

## 优先级建议

如果你只能挑一件做，挑 **Task A**：玩家"不知道咋玩"的核心症结是引导噪音，A 是直接对症的药。

如果时间宽裕做完 A 还想继续，按 **A → B → D → C → E** 顺序。C 是观感问题，没 B/D 严重；E 是长期投资。

每完成一个 Task，建议跑 `run_tests.bat` 并截一张主界面 1280×720 图存到 `docs/acceptance/` 留底。
