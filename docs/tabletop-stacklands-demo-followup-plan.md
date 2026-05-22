# 向参考图/视频玩法靠拢的后续计划

**状态：** Proposed  
**日期：** 2026-05-21  
**目标：** 将《小红花社区》进一步改造成 Stacklands-like 桌面卡堆经营 Demo。

## Summary

目标是把当前《小红花社区》进一步改造成 Stacklands-like 桌面卡堆经营 Demo：玩家主要在自由桌面上拖拽、堆叠、等待、产出、合成、买卡包，同时保留社区主题、居民需求和事件治理。

第一阶段按“完整 Demo”方向规划，目标支撑 45-60 分钟体验，但实施上分里程碑推进，避免一次性重写。每个里程碑或任务结束后必须运行 Godot Doctor 相关检测，再运行项目测试入口。

## Key Changes

### 1. 桌面卡堆成为主循环

- 玩家通过卡堆完成生产、合成和事件处理。
- 示例组合：
  - 居民卡 + 资源点卡 = 采集产出。
  - 许可卡 + 材料卡 = 社区设施。
  - 居民卡 + 设施卡 = 满足居民需求。
  - 问题卡 + 居民/支援/设施卡 = 处理社区事件。
- 当前棋盘系统先降级为“设施落地记录/社区进度”，不作为第一操作界面。
- 时间推进改为轻量节奏：卡堆计时、任务完成、玩家点击推进共同驱动。

### 2. 顶部卡包商店替代公告栏主入口

- 顶部提供卡包购买：
  - 起步包。
  - 材料包。
  - 居民/志愿者包。
  - 设施许可包。
  - 社区服务包。
  - 后期高级治理包。
- 公告栏保留为辅助入口，可作为每日推荐、任务奖励或特殊事件来源。
- 卡包开出的卡直接落到桌面，由玩家整理和堆叠推进。

### 3. 社区系统桌面化

- 居民系统保留，但表现为居民卡。
- 居民可参与采集、建设、服务和问题处理。
- 社区事件保留，但表现为问题卡。
- 未处理问题随时间造成满意度、健康或资源损失。
- 设施卡既是桌面对象，也记录到社区进度，用于后续解锁和结算。

### 4. UI/视觉方向

- 结构靠近参考图：
  - 大绿色手绘桌面。
  - 小尺寸粗黑边卡牌。
  - 顶部卡包/资源/时间条。
  - 左侧任务/主意/百科面板。
  - 底部保留缩放、暂停、设置等轻工具。
- 先做到“玩法结构和操作感接近”，正式美术后续逐步替换。
- 不一次性重写 `MainView.gd`，先在现有桌面卡牌、堆叠、自动合成、计时合成基础上扩展。

## Milestones

### Milestone 1: 桌面卡堆主循环

交付目标：玩家可以只靠桌面卡堆完成基础循环。

- 支持稳定堆叠、拆堆、移动、置顶。
- 支持卡堆计时任务。
- 支持进行中状态、进度条、完成产物生成。
- 支持失败反馈：组合无效、居民忙碌、资源不足。
- `reduce_motion=true` 时计时任务立即或低动效完成。

结束检测：

1. 运行 Godot Doctor 检测目标文件：
   - `project.godot`
   - `scenes/Main.tscn`
   - `scripts/ui/MainView.gd`
   - `scripts/core/RecipeRules.gd`
2. 运行插件集成 smoke：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\godot_doctor_integration_smoke.ps1
```

3. 运行项目测试入口：

```powershell
.\run_tests.bat
```

### Milestone 2: 卡包商店与任务面板

交付目标：玩家能通过买包扩张桌面，并由左侧任务推进。

- 顶部卡包商店替代公告栏主入口。
- 卡包消耗货币/鲜花，开出受阶段控制的卡。
- 左侧任务显示主线目标、可用主意、社区需求。
- 开局任务覆盖：买包、获得居民、采集材料、建造坡道、满足居民需求。

结束检测：

1. 运行 Godot Doctor 检测目标文件：
   - `data/cards.json`
   - 新增或扩展的卡包数据文件。
   - `scripts/ui/MainView.gd`
   - 卡包规则文件。
2. 运行插件集成 smoke：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\godot_doctor_integration_smoke.ps1
```

3. 运行项目测试入口：

```powershell
.\run_tests.bat
```

### Milestone 3: 居民需求与事件压力

交付目标：保留社区治理特色。

- 居民需求转成可见状态或需求卡。
- 问题事件转成桌面问题卡。
- 玩家通过堆叠处理问题。
- 未处理问题造成惩罚。
- 成功处理问题给奖励、解锁卡包或推进任务。

结束检测：

1. 运行 Godot Doctor 检测目标文件：
   - 居民规则文件。
   - 问题规则文件。
   - `scripts/autoload/GameState.gd`
   - `scripts/autoload/DataRepository.gd`
   - 相关数据 JSON。
2. 运行插件集成 smoke：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\godot_doctor_integration_smoke.ps1
```

3. 运行项目测试入口：

```powershell
.\run_tests.bat
```

### Milestone 4: 完整 Demo 节奏

交付目标：形成 45-60 分钟 Demo。

- 内容分 3 段：
  - 开局：基础资源、居民、设施。
  - 中盘：多个居民需求、社区服务、事件压力。
  - 后期：自治成果、高级设施、高级卡包。
- 每段有明确卡包池、任务线、解锁条件。
- 保留存档、设置、音效、无障碍、Steam mock 和本地 fallback。
- 完成一条可通关路线，并用 smoke test 覆盖。

结束检测：

1. 运行 Godot Doctor 全量项目检测，或至少覆盖所有本轮改动文件。
2. 运行插件集成 smoke：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\godot_doctor_integration_smoke.ps1
```

3. 运行项目测试入口：

```powershell
.\run_tests.bat
```

4. 运行完整 Demo smoke，确认主循环可完成。

## Data / Interface Changes

### 扩展 `data/cards.json` 卡牌分类

- `resident`
- `resource_node`
- `material`
- `building_permit`
- `facility`
- `problem`
- `support`
- `pack`

### 扩展 `data/recipes.json`

- 支持 2-4 张卡输入。
- 支持 `time_cost_sec`。
- 支持结果卡、资源奖励、居民状态变化。

### 新增或扩展卡包数据

- 卡包 ID。
- 价格。
- 解锁阶段。
- 掉落池。

### 保留现有可测试接口

- 放置桌面卡。
- 查询桌面卡。
- 执行卡堆合成。
- 强制完成计时任务。
- 查询最近反馈。

## Test And Doctor Gates

每一步完成后都按同一顺序验证：

1. 运行 Godot Doctor 检测当前步骤涉及的资源链。
2. 运行插件集成 smoke：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\godot_doctor_integration_smoke.ps1
```

3. 运行项目测试入口：

```powershell
.\run_tests.bat
```

4. 若本步骤新增专门 smoke，则一并加入 `run_tests.bat` 或单独运行。
5. 任一检测失败时，先修复失败，再进入下一步。

## Test Plan

### 核心规则测试

- 有效卡堆开始计时并生成结果。
- 无效卡堆不消耗卡。
- 重复卡实例不会误合成。
- 居民忙碌时不能重复参与任务。

### 数据测试

- 卡包引用卡牌存在。
- 配方输入和结果存在。
- 任务引用卡牌/配方/事件存在。

### UI smoke

- 开局买包、开包、拖卡、合成坡道。
- `reduce_motion=true` 时计时卡堆立即完成。
- 左侧任务正确推进。
- 顶部资源正确变化。

### 回归测试

- `run_tests.bat` 继续作为总入口。
- Godot Doctor 集成 smoke 保持为每步必跑门禁。
- 现有桌面合成、拖放、扩地、公告栏购买 smoke 保持通过，或改为兼容辅助入口。

## 完成后的下一步拆分优化方向

全部里程碑完成后，再进入“拆分和优化期”，重点不是继续堆功能，而是把系统拆清楚、稳定住。

### 1. 从 `MainView.gd` 拆出桌面玩法控制器

- 拆出 `TabletopController`：
  - 负责桌面卡实例、位置、z-order、堆叠、命中检测。
- 拆出 `StackActionController`：
  - 负责卡堆配方匹配、计时、完成、失败反馈。
- `MainView.gd` 保留为 UI 调度层，不继续承载所有玩法细节。

### 2. 建立独立卡包/掉落系统

- 拆出 `PackRules.gd`：
  - 负责卡包价格、解锁、掉落池、购买校验。
- 数据层独立管理卡包配置，避免卡包逻辑散落在 UI 中。
- 后续方便做平衡、稀有度、保底和阶段掉落。

### 3. 居民/问题卡规则模块化

- 拆出 `ResidentCardRules.gd`：
  - 负责居民忙碌、状态变化、需求满足。
- 拆出 `ProblemCardRules.gd`：
  - 负责问题卡计时、处理条件、惩罚和奖励。
- 让居民、问题、设施之间通过明确规则交互，减少硬编码。

### 4. UI 层拆分

- 左侧任务/百科面板独立成模块。
- 顶部资源/卡包商店独立成模块。
- 桌面工具栏独立成模块。
- 目标是让每个 UI 模块可以单独刷新和测试，避免每次操作都重建大块 UI。

### 5. 性能与体验优化

- 优化大量卡牌时的刷新：
  - 卡牌移动只刷新对应实例。
  - 卡堆状态变化只刷新相关卡堆。
  - 任务面板只在目标变化时刷新。
- 增加桌面整理能力：
  - 自动整理同类卡。
  - 快速收起/展开堆。
  - 搜索或高亮可用组合。
- 改善长期游玩体验：
  - 卡牌过多时的缩放、拖拽、边界、可读性。
  - 任务提示避免玩家迷失。
  - 失败原因必须直接可读。

## Assumptions

- 改造重心：玩法优先。
- 系统保留：融合保留居民、事件和社区主题。
- 第一阶段目标：完整 Demo，但分里程碑实现。
- 不使用浏览器视觉伴侣。
- 不一次性重写项目；先扩展现有桌面卡牌能力，再在完成后进入拆分优化期。
- 每个里程碑或任务结束后都必须运行 Godot Doctor 检测、Godot Doctor 集成 smoke 和项目测试入口。
