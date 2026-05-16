# Project Handoff Guide Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `docs/` 下产出一份给下一阶段开发者使用的完整中文项目交接文档，准确说明当前 Demo 的玩法、工程结构、运行方式、测试链路、风险边界和后续开发建议。

**Architecture:** 只新增一个 Markdown 交接文档，不改动游戏逻辑、数据内容或测试脚本。文档内容以 `project.godot`、`README.md`、`gameDesign.md` 和现有脚本目录为信息来源，先搭章节骨架，再补玩法与系统，再补工程与接手建议，最后做一次仓库一致性核对。

**Tech Stack:** Markdown，PowerShell，Godot 项目结构说明，现有仓库文档与 GDScript 源码。

---

### Task 1: 创建交接文档骨架

**Files:**
- Create: `C:\Users\hacjr\Desktop\小红花社区\docs\project-handoff-guide.md`
- Read: `C:\Users\hacjr\Desktop\小红花社区\docs\superpowers\specs\2026-05-16-developer-handoff-doc-design.md`

- [ ] **Step 1: 复读设计 spec，确认章节边界**

Run:

```powershell
Get-Content -Path 'C:\Users\hacjr\Desktop\小红花社区\docs\superpowers\specs\2026-05-16-developer-handoff-doc-design.md' -Encoding UTF8
```

Expected: 看到交付路径、目标读者、11 个必需章节，以及“AI 可回退 / Steam mock / 数据仍在活跃编辑”等必须反映的仓库现实。

- [ ] **Step 2: 写入 Markdown 标题和章节骨架**

目标文档必须至少包含以下标题：

```markdown
# 《看得见的一公里》项目交接文档

## 1. 项目概览
## 2. 当前可玩范围与完成度快照
## 3. 核心玩法循环与目标体验
## 4. 系统拆解
## 5. 工程结构与关键文件
## 6. 运行时流程
## 7. 数据驱动内容组织
## 8. 运行、测试与构建发布
## 9. 当前限制、Mock 边界与技术债
## 10. 下一阶段开发建议
## 11. 新开发者建议阅读顺序
```

- [ ] **Step 3: 在文档开头补一个“文档用途”说明段**

说明要点：

```markdown
本文档面向下一阶段接手本项目的游戏开发者，目标不是宣传，而是帮助接手者快速理解：这个项目现在已经做到什么程度、核心系统如何串联、代码从哪里进入、哪些部分已可运行、哪些部分仍是 Mock 或过渡实现，以及下一阶段应优先从哪里继续推进。
```

### Task 2: 写入项目、玩法和系统内容

**Files:**
- Modify: `C:\Users\hacjr\Desktop\小红花社区\docs\project-handoff-guide.md`
- Read: `C:\Users\hacjr\Desktop\小红花社区\README.md`
- Read: `C:\Users\hacjr\Desktop\小红花社区\gameDesign.md`
- Read: `C:\Users\hacjr\Desktop\小红花社区\project.godot`

- [ ] **Step 1: 写“项目概览”和“完成度快照”**

内容必须覆盖这些事实：

```markdown
- 项目名称是《看得见的一公里 Demo》
- 引擎是 Godot 4.6.2
- 当前主程序是单机 Godot Demo，而不是前后端分离应用
- 主场景入口是 `res://scenes/Main.tscn`
- Demo 以 10 个社区日为主循环
- README 宣称的核心内容包括卡牌、配方、固定/AI/混合事件、存档、AI 安全面板、SteamBridge mock、无障碍选项和比赛导出脚本
```

- [ ] **Step 2: 写“核心玩法循环与目标体验”**

这一节应明确写出：

```markdown
- 玩家每天从公告栏明牌中选卡
- 卡牌可进入手牌、合成槽和棋盘格
- 设施放入棋盘后会产生资源与联动
- 问题事件在日出后进入待处理状态
- 黄昏结算会处理未解决问题、居民状态和自治推进
- 夜间在最后一天进入评级、年报与后续模式解锁
- 项目与常见堆叠卡牌玩法的差异，在于“公告栏明牌选择 + 棋盘空间布局 + 居民个体状态 + 自治成长”
```

- [ ] **Step 3: 写“系统拆解”**

这一节至少要有这些小节和信息点：

```markdown
### 4.1 资源与进度
- flowers / funds / manpower / trust / autonomy 的作用

### 4.2 居民系统
- resident_states 的运行态
- 满意度、健康、愿望链、人力产出

### 4.3 事件系统
- fixed / ai / hybrid 三类事件
- 问题卡、公告、所需人力、奖励、惩罚、升级链

### 4.4 AI 事件导演与安全回退
- 默认使用 DeepSeek 兼容接口配置
- 无 API Key 或远程失败时可回退到本地候选事件
- Safety Panel 与请求日志是调试和安全边界的一部分

### 4.5 存档与进度恢复
- 自动存档、手动存档、版本兼容恢复

### 4.6 SteamBridge 模拟层
- 成就、语言、云存档路径仍是本地 mock

### 4.7 无障碍与设置
- 大字号、高对比、减少动态效果、无时间压力、音量控制
```

### Task 3: 写入工程结构、流程和测试发布内容

**Files:**
- Modify: `C:\Users\hacjr\Desktop\小红花社区\docs\project-handoff-guide.md`
- Read: `C:\Users\hacjr\Desktop\小红花社区\scripts\autoload\*.gd`
- Read: `C:\Users\hacjr\Desktop\小红花社区\scripts\core\*.gd`
- Read: `C:\Users\hacjr\Desktop\小红花社区\scripts\ui\*.gd`
- Read: `C:\Users\hacjr\Desktop\小红花社区\tests\run_tests.gd`
- Read: `C:\Users\hacjr\Desktop\小红花社区\tests\full_game_smoke.gd`

- [ ] **Step 1: 写“工程结构与关键文件”**

这一节必须把目录职责写清楚：

```markdown
- `project.godot`：主入口、autoload、窗口配置
- `scenes/`：主场景、卡牌视图、Day -1 教学场景
- `scripts/autoload/`：全局状态与服务层
- `scripts/core/`：规则层与结算层
- `scripts/ui/`：主界面、卡牌视图、安全面板
- `data/`：卡牌、配方、居民、愿望、事件等 JSON 数据
- `tests/`：核心测试、冒烟测试、发布脚本验证
```

同时要点名这些核心模块职责：

```markdown
- `DataRepository.gd`：加载并校验 JSON 内容
- `GameState.gd`：维护社区运行态
- `DayCycle.gd`：控制日出/黄昏/夜间结算
- `EventManager.gd`：生成与解决问题事件
- `AIDirector.gd`：远程 AI 请求与本地回退
- `SaveManager.gd`：存档/读档与旧存档修复
- `MainView.gd`：把 UI、拖拽、教程、设置、存档入口和日流程串起来
```

- [ ] **Step 2: 写“运行时流程”**

建议用编号描述从启动到结束的顺序：

```markdown
1. 进入 `Main.tscn`
2. `MainView._ready()` 重置状态、加载教程与设置、构建 UI
3. 种入居民运行态并开启新的一天
4. `DayCycle.resolve_sunrise()` 结算居民和建筑产出
5. `EventManager.resolve_sunrise_events()` 注入当天问题
6. 玩家在白天执行选卡、合成、建设、问题处理
7. `DayCycle.resolve_dusk()` 处理未解决问题与居民变化
8. `DayCycle.resolve_night()` 在最后一天计算评级、年报和后续模式
```

- [ ] **Step 3: 写“数据驱动内容组织”与“测试发布”**

这一节必须包含这些明确内容：

```markdown
- `cards.json` 目前包含约 80 张卡
- `recipes.json` 目前包含 43 条配方记录
- `residents.json` 当前有 7 个 `resident_id`
- `events.json` 当前有 42 个 `event_id`
- README 中对规模的描述与当前数据文件可能暂时不完全同步，因为仓库仍在活跃编辑
```

以及这些测试/发布结论：

```markdown
- `run_tests.gd` 是核心测试入口，要求 autoload 节点齐全
- `full_game_smoke.gd` 会用本地回退配置跑完整 10 天流程
- 还有动画、平衡、发布脚本等 smoke 检查
- 项目目前可通过本机 Godot 启动，启动脚本已改为固定本机 Godot 路径
```

### Task 4: 写入风险边界、下一阶段建议并核对文档

**Files:**
- Modify: `C:\Users\hacjr\Desktop\小红花社区\docs\project-handoff-guide.md`
- Verify: `C:\Users\hacjr\Desktop\小红花社区\docs\project-handoff-guide.md`

- [ ] **Step 1: 写“当前限制、Mock 边界与技术债”**

至少要明确写出这些点：

```markdown
- Steam 仍是本地模拟层，不是正式 Steamworks 接入
- AI 虽然支持远程接口，但默认仍要依赖本地回退保持可玩
- 正式美术和资源仍以轻量占位为主
- 数据文件处于持续编辑状态，README 与当前 JSON 规模可能短期不一致
- 启动脚本现在适配的是这台机器上的固定 Godot 路径，不具备跨机器可移植性
```

- [ ] **Step 2: 写“下一阶段开发建议”和“阅读顺序”**

建议按优先级写成可执行路线：

```markdown
1. 先稳定数据内容与 README/设计文档的一致性
2. 再补核心玩法的内容验证与平衡校准
3. 再推进 UI/资源正式化与体验打磨
4. 之后再做真实平台集成，例如 Steamworks 与正式导出流程
```

阅读顺序建议必须包含：

```markdown
1. `README.md`
2. `project.godot`
3. `scripts/ui/MainView.gd`
4. `scripts/autoload/GameState.gd`
5. `scripts/autoload/DayCycle.gd`
6. `scripts/autoload/EventManager.gd`
7. `scripts/autoload/AIDirector.gd`
8. `tests/run_tests.gd`
9. `tests/full_game_smoke.gd`
```

- [ ] **Step 3: 核对文档结构与仓库一致性**

Run:

```powershell
Get-Content -Path 'C:\Users\hacjr\Desktop\小红花社区\docs\project-handoff-guide.md' -Encoding UTF8
rg -n '^## ' 'C:\Users\hacjr\Desktop\小红花社区\docs\project-handoff-guide.md'
rg -n 'Main.tscn|DataRepository.gd|GameState.gd|DayCycle.gd|EventManager.gd|AIDirector.gd|SaveManager.gd|SteamBridge.gd|run_tests.gd|full_game_smoke.gd' 'C:\Users\hacjr\Desktop\小红花社区\docs\project-handoff-guide.md'
```

Expected:

```text
- 文档存在于 docs/project-handoff-guide.md
- 至少出现 11 个二级标题
- 关键模块名和路径都能在文档中被找到
- 文档没有把 Steam 或 AI 说成已经完成正式生产集成
```
