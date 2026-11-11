# 《看得见的一公里》优化方案

> 以用户视角审查项目，面向"让大众愿意接受并使用"的目标整理问题与优化策略。
> 生成时间：2026-06-24

---

## 一、问题概览

| 优先级 | 类别 | 问题 | 状态 |
|--------|------|------|------|
| P0 | 数据一致性 | `day_sequence.json` 中 `phase_progression.unlocked_packs` 使用已废弃的旧包 ID | ✅ 已修复 |
| P0 | 数据一致性 | `day_sequence.json` `finale` (Day 10) 列出了 `governance_pack`，但该包实际 `unlock_day=11` | ✅ 已修复 |
| P1 | 文档正确性 | `README.md` 命令示例硬编码了 `D:\Desktop\小红花社区`，跨机器无法直接运行 | ✅ 已修复 |
| P1 | 新手体验 | `tutorial.json` 第一步 `start_tabletop` 指引不够明确，新手可能不知道该做什么 | ✅ 已优化 |
| P1 | 新手体验 | `tutorial.json` `day_minus_one.body` 主欢迎文案节奏感偏弱，不够有感召力 | ✅ 已优化 |
| P2 | 新手体验 | `inline_hints.first_craft` 文案引导方向不清晰（"看到能配成设施的两张卡"对新人过于抽象） | ✅ 已优化 |
| P2 | 内容质量 | `gameDesign.md` 标注的"未实装"功能（居民愿望 UI）没有任何对玩家的替代提示 | 📝 文档已说明 |
| P3 | 代码质量 | `MainView.gd` 单文件承载全部 UI 逻辑（拖拽、教程、结算、存档），后续扩展困难 | 📝 列入路线图 |
| P3 | 代码质量 | `GameState.gd` 中 `autonomy`/`rating` 等字段仅为兼容遗留存档，增加维护负担 | 📝 列入路线图 |
| P3 | 配置冗余 | `card_packs.json` 和 `CardPackSystem.gd` 中保留 3 个 legacy alias（`basic_pack` 等），有混淆风险 | 📝 列入路线图 |

---

## 二、已执行的修复

### Fix 1：`data/day_sequence.json` — 清理 phase_progression 中的废弃包 ID

**问题**：`phase_progression` 里的 `unlocked_packs` 列表混用了已废弃的旧包名（`basic_pack`、`volunteer_pack`、`accessibility_pack`）和当前有效包名；`finale`（第 10 天）还包含 `unlock_day=11` 的 `governance_pack`，逻辑上不可能在第 10 天解锁。

**修复内容**：
- 所有 phase 的 `unlocked_packs` 统一替换为当前 6 个 live pack ID
- `finale` 移除 `governance_pack`（第 11 天才解锁）
- 映射关系：`basic_pack` → 删除（`starter_pack` 已覆盖）；`volunteer_pack` → `resident_pack`；`accessibility_pack` → `service_pack`

### Fix 2：`README.md` — 修复硬编码路径

**问题**：命令示例写死了 `D:\Desktop\小红花社区`，在任何其他机器上都需要手动改路径才能运行，对新贡献者不友好。

**修复内容**：将路径替换为"在项目目录下执行 `.`"的形式，适合所有机器。

### Fix 3：`data/tutorial.json` — 提升新手引导文案质量

**问题**：
1. `day_minus_one.body` 开场文案平铺直叙，缺乏带入感；
2. `start_tabletop` 步骤描述含糊（"或先整理桌面起手卡"容易让新手困惑）；
3. `inline_hints.first_craft` 说"看到能配成设施的两张卡"——新手根本不知道哪两张能配；
4. `inline_hints.first_problem` 说"拖到对应服务建筑上"——新手可能不知道服务建筑是什么。

**修复内容**：重写以上 4 处文案，使用更具体、更有行动导向的描述。

---

## 三、路线图建议（未自动执行，需更大范围变更）

### 近期（Demo 上线前）

1. **补充美术资源**：`art_manifest.json` 中大量 `path` 为空，卡牌显示 `icon.svg` 占位符。即使是简单的色块+图标也比占位符好得多，强烈建议用 AI 生成的简单图标先行填充。
2. **居民愿望 UI**：`residents.json` 中已有愿望链数据字段，但界面没有展示，玩家感受不到长期目标。最简单的方案是在居民抽屉里加一行"心愿：…"文字。
3. **终局/里程碑提示**：当前 demo 是开放式无终点，但没有任何提示告诉玩家"你现在做得很好"或"这是 demo 的全部内容"。建议在 Day 10 结束时加一条日报：「这个社区已经能自我运转了。感谢你的陪伴。」

### 中期（Steam Demo 前）

4. **MainView.gd 拆分**：建议按功能划分出 `TabletopInteractionHandler.gd`、`DayCycleUIBridge.gd`、`TutorialOverlayController.gd`，减少单文件行数至可维护的 <600 行。
5. **legacy alias 清理**：当 `basic_pack`/`volunteer_pack`/`accessibility_pack` 相关的旧存档迁移窗口关闭后，从 `card_packs.json` 和 `CardPackSystem.gd` 中删除这三个条目。
6. **GameState 字段瘦身**：`autonomy`、`autonomy_points`、`rating`、`completed_run_summary` 等仅为兼容旧存档的字段，可在一个版本号迁移后由 SaveManager 统一清理。

---

## 四、用户体验核心洞察

以下是以首次玩家视角体验后的核心感受：

1. **第一分钟最难**：进游戏后桌面堆了一堆卡，玩家不知道先动哪张。教程气泡虽然存在，但没有「先动这张」的强引导。→ 应让第一步操作有明确的视觉高亮+唯一目标。

2. **进度不透明**：玩家无法直观看出自己距离"下一个里程碑"还有多远（信任还差几点解锁新棋盘行？）。→ 建议在 HUD 上加信任进度条，或在锁定的棋盘行上直接显示"再攒 X 信任就解锁"。

3. **居民是无名配角**：9 位有名字、有故事的居民，但在主界面几乎感知不到他们的存在（只有需求卡出现时才看到名字）。→ 哪怕是在日报里加一句"今天王奶奶需要…"，也能大幅提升代入感。

4. **合成逻辑对新玩家不直观**：timed craft 进度环体验很好，但"哪两张卡可以合成"缺乏预览。→ 建议悬停卡牌时，如果当前桌面上有匹配的合成材料，高亮显示那张卡。
