# 《看得见的一公里》项目交接文档

更新时间：2026-05-28

本文档面向下一阶段接手本项目的游戏开发者，目标不是宣传，而是帮助接手者快速理解：这个项目现在已经做到什么程度、核心系统如何串联、代码从哪里进入、哪些部分已可运行、哪些部分仍是 Mock 或过渡实现，以及下一阶段应优先从哪里继续推进。

## 1. 项目概览

《看得见的一公里》当前是一个基于 Godot 4.6.2 的 PC 单机桌面堆叠社区经营 Demo。项目名在 [project.godot](/C:/Users/hacjr/Desktop/小红花社区/project.godot) 中配置为“看得见的一公里 Demo”，当前版本号是 `0.3.0`，主入口场景是 `res://scenes/Main.tscn`。

从玩法定位上看，它不是传统意义上的“前端 + 后端”分离项目，而是一个以桌面堆叠为主循环、以社区地图落地为二段兑现的本地 Godot 客户端 Demo。玩家通过顶部卡包栏获得卡牌，在实时日间里拖拽堆叠卡牌、把设施放到社区地图、把居民需求拖到对应服务建筑上；夜间只负责推进到下一天，Day 10 之后直接进入 Day 11。代码层已经具备主循环、卡牌内容、桌面 timed craft、地图放置、居民需求、存档、AI 回退、安全面板、无障碍设置、SteamBridge 模拟层以及发布脚本，不再是概念原型。

从仓库形态上看，这个项目已经适合继续做“可玩性稳定化 + 内容扩充 + 正式化集成”，而不是从零搭骨架。接手者应默认这是一个“已有运行链路、已有自动化测试、但仍处于活跃迭代”的 Godot Demo。

## 2. 当前可玩范围与完成度快照

下面是以当前仓库状态为准的完成度快照：

| 维度 | 当前状态 | 说明 |
| --- | --- | --- |
| 本地运行 | 已可运行 | 已验证可通过 [start_game.bat](/C:/Users/hacjr/Desktop/小红花社区/start_game.bat) 在本机启动 |
| 主循环 | 已成型 | 日出、白天、黄昏、夜间四段流程完整存在 |
| 主场景 | 已成型 | [Main.tscn](/C:/Users/hacjr/Desktop/小红花社区/scenes/Main.tscn) + [MainView.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/ui/MainView.gd) 串起全部主流程 |
| 卡牌内容 | 已有可观规模 | 当前 `cards.json` 中有 80 张 live 卡牌 |
| 配方内容 | 已有可观规模 | 当前 `recipes.json` 中有 30 条原始记录，其中 27 条 live `recipe_id` 记录 |
| 居民内容 | 已接入运行态 | 当前 `residents.json` 中有 9 个 `resident_id` |
| 卡包内容 | 已成型 | 当前 `card_packs.json` 中有 6 个 live pack family，并保留 3 个 legacy alias 条目 |
| 存档系统 | 已可用 | 支持自动存档、手动存档、读档、旧字段恢复 |
| AI / 问题链路 | 已接入但可回退 | 支持兼容 DeepSeek 的远程接口，同时内置本地回退链路；当前 live 数据不再单列 `events.json` |
| Steam 集成 | 仍为 Mock | 当前通过 [SteamBridge.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/SteamBridge.gd) 提供本地模拟 |
| 测试 | 已具备核心覆盖 | 有核心测试、完整流程 smoke、动画 smoke、交互 smoke、发布脚本 smoke |

需要特别注意的是，当前仓库已经完成过一次从旧口径到桌面堆叠版的瘦身迁移。后续接手时，不要再把旧的“固定选卡 + Day 10 终局”描述当成运行真相；应以 [README.md](/C:/Users/hacjr/Desktop/小红花社区/README.md)、[project.godot](/C:/Users/hacjr/Desktop/小红花社区/project.godot)、[run_tests.bat](/C:/Users/hacjr/Desktop/小红花社区/run_tests.bat) 和 `data/` 目录现状为准。

## 3. 核心玩法循环与目标体验

这个项目当前的核心体验是“卡包开包 + 桌面堆叠 + 地图落地 + 居民需求响应”。

玩家每日主要进行以下动作：

1. 从顶部卡包栏购买或打开卡包，让卡牌直接落到桌面。
2. 把桌面上的卡牌互相堆叠，触发 timed craft 合成或生产。
3. 把设施类卡牌拖到社区地图上，兑现长期产出与服务能力。
4. 把居民需求卡拖到匹配的服务建筑上，完成一次服务响应。
5. 在黄昏承担未处理需求带来的惩罚，并结算当天资源与状态变化。
6. 在夜间查看简短日报，然后进入下一天；Day 10 后继续进入 Day 11。

当前设计与常见堆叠卡牌项目相比，至少有 4 个差异点：

- 当前唯一卡源是顶部卡包栏，而不是旧的固定明牌选卡流程。
- 桌面就是主要工作台，堆叠和 timed craft 发生在同一可见空间里。
- 设施必须真正落到社区地图上，才会兑现长期产出和服务能力。
- 当前 demo 走连续天数循环，Day 10 不是强制终局。

从代码和文档共同指向的体验目标来看，项目想强调的是：社区建设不只是一串资源公式，而是一套“桌面经营 + 地图兑现 + 服务响应”的轻量社区经营循环。

## 4. 系统拆解

### 4.1 资源与进度

运行态核心资源放在 [GameState.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/GameState.gd) 的 `community_state` 中，主要包含：

- `flowers`：偏稀缺、偏目标导向的社区资源。
- `funds`：用于日常建设与运转的资金资源。
- `manpower`：日间操作与问题处理的人力预算。
- `trust`：长期进度资源，用于内容解锁。
- 兼容字段如 `autonomy` / `autonomy_points` / `rating` 仍可能出现在运行态或旧存档迁移中，但不再代表当前 live 设计承诺。

[ResourceManager.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/ResourceManager.gd) 负责通用资源加减、放置消耗、事件惩罚记录和日志。资源处理相对轻量，核心优势在于“统一入口”，后续如果要补经济平衡、战报记录或 UI 反馈，这里是较好的扩展点。

### 4.2 卡牌、配方、棋盘与建造

卡牌、配方和棋盘逻辑主要分布在 `scripts/core/`：

- [PrototypeRules.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/core/PrototypeRules.gd)：承接选卡、拖卡、合成、放置等原型操作规则。
- [RecipeRules.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/core/RecipeRules.gd)：配方与结果映射逻辑。
- [BoardRules.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/core/BoardRules.gd)：棋盘格、区域、库存、设施产出、联动缓存等规则。

从当前状态看，棋盘已经不是装饰层，而是会影响产出和问题处理效率的核心系统。`GameState.community_state` 中维护：

- `board_cells`
- `built_facilities`
- `inventory`
- `recipe_codex`
- `discovered_combos`
- `board_combo_cache`

这意味着下一阶段如果要继续扩内容，新增卡牌时不能只写 `cards.json`，还要考虑区域偏好、联动组、产出、问题对抗标签以及是否进入库存或棋盘放置链路。

### 4.3 居民系统

居民系统相关逻辑主要在 [ResidentSystem.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/core/ResidentSystem.gd) 和运行态 `resident_states` 中。当前居民不是静态文本对象，而是会参与多个系统：

- 每日人力产出。
- 与需求卡、服务建筑和搬入逻辑的绑定。
- 个人留言与记忆记录。
- 开局引导与问题反馈中的角色呈现。

旧字段如 `wish_progress`、满意度/健康相关值和其他历史统计仍会在迁移或部分逻辑中保留，但不应再把它们当成当前对玩家承诺的主循环目标。后续如果要增强角色表现，优先不要推翻现有 `resident_states`、`memory_log`、`personal_messages` 结构，而应在这些结构之上扩展展示和反馈。

### 4.4 事件系统

事件与问题链路由 [EventManager.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/EventManager.gd) 管理。当前 live 路径以日出注入问题、居民需求和 AI 回退为主，不再依赖独立的 `data/events.json`。运行态中的问题状态至少包含：

- 事件标识与标题
- 问题卡 `problem_card_id`
- 所需人力 `required_manpower`
- 已分配人力 `assigned_manpower`
- 奖励 `reward`
- 惩罚 `penalty`
- 目标居民 `target_resident_ids`
- 升级链、持续天数、准备条件、部分成功奖励等扩展字段

处理方式目前有两条：

- 直接分配人力解决问题
- 使用支援卡匹配 `counter_tags` 缓解或解决问题

如果问题在黄昏前未被解决，会进入惩罚与升级结算流程，相关逻辑由 [DayCycle.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/DayCycle.gd) 在 `_resolve_active_problem_penalties()` 中调用。

### 4.5 AI 事件导演与安全回退

[AIDirector.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/AIDirector.gd) 是当前 AI 链路的边界模块。默认设置包括：

- `mode = hybrid`
- `base_url = https://api.deepseek.com`
- `model = deepseek-v4-flash`
- `timeout_seconds = 15`

关键事实有 3 个：

1. 它支持远程兼容式 Chat Completions 请求。
2. 如果没有 API Key、配置不合法或请求失败，会回退到本地候选事件。
3. 它会记录请求历史、回退次数、阻塞次数、最后失败原因，用于安全审计。

主流程里，日出事件生成当前走的是异步链路：`MainView` 在新的一天开始时调用 `await EventManager.resolve_sunrise_events_async()`，`EventManager` 再按事件类型选择固定候选或 `await AIDirector.request_event_candidate(...)`。这意味着：

- 游戏主循环已经考虑了外部请求延迟。
- 即使 AI 不可用，Demo 仍应保持可玩。
- 安全面板不是附属功能，而是保证可控演示的重要工具。

### 4.6 存档、读档与教程

[SaveManager.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/SaveManager.gd) 支持：

- 自动存档 `slot 0`
- 通用存档槽 `slot 0-3`
- UI 状态随存档一起保存
- 旧存档字段修补与运行态字段恢复

在 UI 层，[MainView.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/ui/MainView.gd) 已接入手动存档、手动读档和黄昏自动存档。也就是说，接手者如果只关注“游戏内容”，不要忽视 UI 存档交互已经在主场景里串好。

教程系统由 [TutorialManager.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/TutorialManager.gd) 管理，当前包括：

- Day -1 教学场景入口
- 内联提示
- 首次开包、首次合成、首次放置、首次处理问题等进度标记

这为下一阶段继续补新手体验提供了清晰边界，不建议另起一套独立教程状态系统。

### 4.7 设置、无障碍与音频

[SettingsManager.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/SettingsManager.gd) 当前维护：

- `high_contrast`
- `large_text`
- `reduce_motion`
- `no_time_pressure`
- `music_volume`
- `sfx_volume`

默认 `no_time_pressure = true`，说明设计上并不追求操作压迫感，而更偏向“治理与安排”的节奏。

[AudioManager.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/AudioManager.gd) 负责背景音乐与音效入口，UI 中已有设置入口。无障碍不是后补备注，而是已经进入全局设置层，后续改 UI 时需要保留这一前提。

### 4.8 旧终局字段兼容层

当前仓库仍保留一部分旧进度字段和兼容清洗逻辑，例如 `autonomy`、`autonomy_points`、`rating`、`wish_progress` 和相关摘要结构。这些字段今天的职责主要是：

- 兼容旧存档读档与字段归一化。
- 让历史 UI 状态或测试夹具仍能安全通过迁移流程。
- 为后续彻底清理遗留口径保留过渡带。

需要特别注意的是，当前 live 数据侧已经不再加载独立的 `wishes.json`、`events.json`、`autonomy_levels.json`，而 [DayCycle.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/DayCycle.gd) 的夜间结算也不再在 Day 10 生成 `annual_report`、`celebration_summary` 或终局摘要。后续如果碰这些字段，应把它们视为兼容层，而不是当前玩法承诺。

### 4.9 SteamBridge 模拟层

[SteamBridge.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/SteamBridge.gd) 当前只提供本地模拟能力，包括：

- 成就解锁信号
- 语言读取
- 云存档路径接口

这意味着现阶段所有“Steam 已接入”的描述都应理解为“接口形状和调用位置已经留好，但实际 SDK 还没接”。这一点必须在对外协作和后续任务拆分中说清楚。

## 5. 工程结构与关键文件

### 顶层目录职责

| 路径 | 作用 |
| --- | --- |
| [project.godot](/C:/Users/hacjr/Desktop/小红花社区/project.godot) | 项目配置、主场景入口、autoload 注册、窗口配置 |
| [scenes/](/C:/Users/hacjr/Desktop/小红花社区/scenes) | 主场景、Day -1 教程场景、卡牌视图场景 |
| [scripts/autoload/](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload) | 全局状态与服务层 |
| [scripts/core/](/C:/Users/hacjr/Desktop/小红花社区/scripts/core) | 桌面规则、地图结算、居民逻辑与兼容迁移相关规则 |
| [scripts/ui/](/C:/Users/hacjr/Desktop/小红花社区/scripts/ui) | 主界面、卡牌 UI、教学 UI、安全面板 |
| [data/](/C:/Users/hacjr/Desktop/小红花社区/data) | 游戏内容 JSON、教程配置、平衡目标、资源清单 |
| [tests/](/C:/Users/hacjr/Desktop/小红花社区/tests) | 核心测试、完整流程 smoke、动画 smoke、发布脚本 smoke |
| [tools/release/](/C:/Users/hacjr/Desktop/小红花社区/tools/release) | 发布、校验、打包和 SteamPipe 模板 |

### autoload 层

[project.godot](/C:/Users/hacjr/Desktop/小红花社区/project.godot) 当前注册了以下 autoload：

- `DataRepository`
- `GameState`
- `SettingsManager`
- `AudioManager`
- `ResourceManager`
- `DayCycle`
- `TutorialManager`
- `AIDirector`
- `EventManager`
- `SaveManager`
- `SteamBridge`

这个列表基本等于“主运行时的服务边界”。如果接手者想找系统入口，autoload 层是第一层索引，不建议跳过。

### 当前最关键的几个文件

| 文件 | 角色 |
| --- | --- |
| [scripts/ui/MainView.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/ui/MainView.gd) | 当前最核心的主控 UI 文件，把状态、拖拽、教程、结算、存档和模式切换都串起来了 |
| [scripts/autoload/GameState.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/GameState.gd) | 社区运行态总容器 |
| [scripts/autoload/DayCycle.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/DayCycle.gd) | 四阶段流程中的结算控制器 |
| [scripts/autoload/EventManager.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/EventManager.gd) | 事件与问题生成、分配和解决 |
| [scripts/autoload/AIDirector.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/AIDirector.gd) | 远程 AI 请求与本地回退边界 |
| [scripts/autoload/DataRepository.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/DataRepository.gd) | JSON 内容加载与校验 |
| [scripts/autoload/SaveManager.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/SaveManager.gd) | 存档、读档、版本兼容恢复 |
| [scripts/core/BoardRules.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/core/BoardRules.gd) | 棋盘、设施和库存规则 |
| [scripts/core/ResidentSystem.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/core/ResidentSystem.gd) | 居民运行态与结算逻辑 |
| [scripts/ui/SafetyPanel.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/ui/SafetyPanel.gd) | AI 配置、安全回退与调试入口 |

如果只看一个文件理解全局，请先看 `MainView.gd`。如果只看一个“无 UI 噪音”的系统入口，请看 `DayCycle.gd`。

## 6. 运行时流程

主流程可以按下面顺序理解：

1. 启动项目，进入 [Main.tscn](/C:/Users/hacjr/Desktop/小红花社区/scenes/Main.tscn)。
2. [MainView.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/ui/MainView.gd) 的 `_ready()` 执行，重置状态、重载教程数据、构建 UI、接入 AI 与设置事件、播放 BGM。
3. 如果 Day -1 教程尚未完成，优先进入 [DayMinusOne.tscn](/C:/Users/hacjr/Desktop/小红花社区/scenes/DayMinusOne.tscn)；否则直接进入新一天流程。
4. 新的一天开始时，`DayCycle.resolve_sunrise()` 负责结算居民产出、设施产出、问题处理人力预算和棋盘联动缓存。
5. 随后 `await EventManager.resolve_sunrise_events_async()` 注入当天问题与需求，其中 AI 或 hybrid 路径会通过 `AIDirector` 尝试远程生成候选内容，失败则本地回退。
6. 玩家在白天阶段进行开包、桌面堆叠、地图放置、需求处理和设置/存档操作。
7. 白天阶段结束后，`DayCycle.resolve_dusk()` 处理未解决问题惩罚、居民变化与黄昏自动存档。
8. 夜间阶段由 `DayCycle.resolve_night()` 推进到下一天并处理搬入补充；Day 10 之后继续进入 Day 11，不再走终局摘要分支。
9. 这条链路当前的重点不是一次性通关，而是让桌面循环在连续天数中保持清晰、稳定和可回归。

这条链路说明当前项目已经从“功能片段集合”升级成了“完整状态机”。后续接手时，最容易出问题的不是单个资源公式，而是改动某一系统后破坏了日出、黄昏、夜间之间的联动关系。

## 7. 数据驱动内容组织

[DataRepository.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/DataRepository.gd) 会在启动时统一加载 `data/` 目录下的 JSON，并建立索引缓存和基本字段校验。当前重要数据文件包括：

| 文件 | 作用 |
| --- | --- |
| [data/cards.json](/C:/Users/hacjr/Desktop/小红花社区/data/cards.json) | 卡牌定义 |
| [data/recipes.json](/C:/Users/hacjr/Desktop/小红花社区/data/recipes.json) | 配方规则 |
| [data/residents.json](/C:/Users/hacjr/Desktop/小红花社区/data/residents.json) | 居民基础数据 |
| [data/card_packs.json](/C:/Users/hacjr/Desktop/小红花社区/data/card_packs.json) | 顶部卡包栏定义 |
| [data/day_sequence.json](/C:/Users/hacjr/Desktop/小红花社区/data/day_sequence.json) | 天数、每日卡包节奏与关键日流程配置 |
| [data/tutorial.json](/C:/Users/hacjr/Desktop/小红花社区/data/tutorial.json) | 教程与提示文本 |
| [data/opening_playability_plan.json](/C:/Users/hacjr/Desktop/小红花社区/data/opening_playability_plan.json) | 开局可玩性计划 |
| [data/art_manifest.json](/C:/Users/hacjr/Desktop/小红花社区/data/art_manifest.json) | 资源清单与占位映射 |
| [data/strings.json](/C:/Users/hacjr/Desktop/小红花社区/data/strings.json) | 文本表 |

当前可直接确认的规模包括：

- `cards.json` 有 80 张 live 卡牌。
- `recipes.json` 有 30 条原始记录，其中 27 条 live `recipe_id`。
- `residents.json` 有 9 个 `resident_id`。
- `card_packs.json` 有 6 个 live pack family，并保留 3 个 legacy alias 条目。

如果在代码里仍看到 `wishes`、`events`、`autonomy_levels` 等符号，先把它们理解成兼容残留或空载入结构，不要默认它们背后仍有一份 live JSON 数据源。
- `day_sequence.json` 当前配置 `max_days = 10`、`daily_pack_cards_per_day = 5`、`player_card_choices_per_day = 3`、`tutorial_scene_enabled = true`。

需要再次强调：README 中的规模描述与 `data/` 目录当前记录可能短期不完全一致，这在活跃开发阶段是正常的。真正接手内容迭代时，建议先建立“README、设计文档、JSON 内容”的统一校对流程，否则策划口径和实际实现会越来越偏。

## 8. 运行、测试与构建发布

### 本地运行

当前本地运行入口有 3 个：

- [start_game.bat](/C:/Users/hacjr/Desktop/小红花社区/start_game.bat)：启动 Demo。
- [open_editor.bat](/C:/Users/hacjr/Desktop/小红花社区/open_editor.bat)：用 Godot 打开工程。
- [run_tests.bat](/C:/Users/hacjr/Desktop/小红花社区/run_tests.bat)：运行核心自动化测试。

其中，启动脚本近期已经适配为“使用这台机器上的固定 Godot 路径”而不是依赖 PATH，这让当前机器上可以直接双击运行，但也带来了跨机器不可移植的问题，见第 9 节。

### 自动化测试

当前测试入口建议按下面顺序理解：

| 文件 | 作用 |
| --- | --- |
| [tests/run_tests.gd](/C:/Users/hacjr/Desktop/小红花社区/tests/run_tests.gd) | 核心测试入口，先检查 autoload 是否齐全，再执行 [tests/test_core.gd](/C:/Users/hacjr/Desktop/小红花社区/tests/test_core.gd) |
| [tests/full_game_smoke.gd](/C:/Users/hacjr/Desktop/小红花社区/tests/full_game_smoke.gd) | 在本地回退 AI 配置下跑完整 10 天流程 |
| [tests/animation_smoke.gd](/C:/Users/hacjr/Desktop/小红花社区/tests/animation_smoke.gd) | 动画相关 smoke |
| [tests/first_10_minutes_smoke.gd](/C:/Users/hacjr/Desktop/小红花社区/tests/first_10_minutes_smoke.gd) | 开局前 10 分钟路径 smoke |
| [tests/drag_to_board_smoke.gd](/C:/Users/hacjr/Desktop/小红花社区/tests/drag_to_board_smoke.gd) | 桌面拖拽到地图的核心交互 smoke |
| [tests/live_ai_smoke.gd](/C:/Users/hacjr/Desktop/小红花社区/tests/live_ai_smoke.gd) | 真实 AI 兼容链路验证 |
| [tests/release_scripts_smoke.ps1](/C:/Users/hacjr/Desktop/小红花社区/tests/release_scripts_smoke.ps1) | 发布脚本和比赛包链路验证 |

本次交接前已经重新验证：

- [run_tests.bat](/C:/Users/hacjr/Desktop/小红花社区/run_tests.bat) 能以退出码 0 跑通核心测试与 smoke 链。
- [start_game.bat](/C:/Users/hacjr/Desktop/小红花社区/start_game.bat) 能在本机拉起新的 Godot 进程。

### 构建与比赛发布

发布相关脚本主要在 [tools/release/](/C:/Users/hacjr/Desktop/小红花社区/tools/release)：

- `build_demo.ps1`
- `validate_export.ps1`
- `package_competition_zip.ps1`
- SteamPipe 模板文件

README 中已经定义了发布产物路径：

- `build/windows/visible_one_kilometer_demo.exe`
- `dist/visible-one-kilometer-demo-vX.Y.Z.zip`

因此，下一阶段如果要继续做比赛包或 Steam Demo 发布，优先应扩的是现有 `tools/release` 链路，而不是另做一套外部打包脚本。

## 9. 当前限制、Mock 边界与技术债

接手时最需要知道的现实限制如下：

1. Steam 仍是 Mock。当前 [SteamBridge.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/SteamBridge.gd) 只是提供本地接口形状，不代表真实 Steamworks 已接入。
2. AI 虽然支持远程调用，但默认仍要依赖本地回退来保证 Demo 可玩。不能把远程 AI 当成稳定、总在线、无需降级的生产依赖。
3. 正式美术仍不完整。README 也明确说明当前偏轻量资产和占位资源，`art_manifest.json` 更像资源映射层，而非完整成品资源库。
4. README、设计文档和当前 `data/` 目录的规模描述并不总是完全同步，说明内容层仍在积极迭代。
5. 启动脚本现已改为依赖本机固定 Godot 路径，只适合当前机器直接运行，不适合作为通用交付方式。
6. [MainView.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/ui/MainView.gd) 目前承担了过多集成职责，是非常高的改动汇聚点。后续只要继续加 UI 功能，这个文件会更容易膨胀。
7. `GameState` 和多个 autoload 已经形成强耦合的运行态网络，任何“改状态字段名”或“重组字典结构”的动作都必须配套验证存档恢复、夜间结算、教程状态和测试入口。

这些都不意味着项目设计有问题，只意味着下一阶段要以“稳定已有骨架”为优先，而不是一上来大规模重写。

## 10. 下一阶段开发建议

如果由新的开发者接手，我建议按下面顺序推进：

### 第一优先级：统一内容口径

- 先把 `README.md`、`gameDesign.md` 和 `data/` 目录当前规模核对一遍。
- 确认哪些数字是对外宣传口径，哪些数字是内部实时内容口径。
- 建立一个轻量的内容变更同步流程，避免后续继续出现文档与数据偏离。

### 第二优先级：稳定核心循环与平衡

- 重点验证“卡包开包 -> 桌面堆叠 -> 地图放置 -> 需求处理 -> 黄昏惩罚 -> 次日推进”这条链在连续天数里是否始终保持可玩。
- 优先审视 [tests/full_game_smoke.gd](/C:/Users/hacjr/Desktop/小红花社区/tests/full_game_smoke.gd) 所覆盖的路径是否足够代表真实玩家路径。
- 对卡包成本、问题压力、设施收益、开局引导节奏做一次集中平衡梳理。

### 第三优先级：降低主界面集成风险

- 在不破坏现有行为的前提下，逐步把 [MainView.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/ui/MainView.gd) 中过于集中的逻辑拆出更清晰的 UI 子模块。
- 保持 `MainView` 继续承担“调度入口”，但减少它亲自维护的细节数量。

### 第四优先级：补强表现与资源正式化

- 逐步替换占位资源和轻量美术。
- 在保留无障碍选项的前提下，统一 UI 反馈、动效节奏、资源可读性和棋盘视觉层级。

### 第五优先级：推进真实平台与交付链路

- 在现有 [tools/release/](/C:/Users/hacjr/Desktop/小红花社区/tools/release) 基础上完善导出、验证、打包流程。
- 把本机固定路径启动脚本替换成更通用的分发方案。
- 若目标包含 Steam 发布，再在 `SteamBridge` 既有接口边界上接真实平台能力。

## 11. 新开发者建议阅读顺序

接手者建议按下面顺序进入项目，而不是随机翻文件：

1. 先读 [README.md](/C:/Users/hacjr/Desktop/小红花社区/README.md)，建立项目范围感。
2. 再读 [project.godot](/C:/Users/hacjr/Desktop/小红花社区/project.godot)，确认主场景和 autoload 列表。
3. 接着读 [scripts/ui/MainView.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/ui/MainView.gd)，理解当前主流程是如何被组装起来的。
4. 再读 [scripts/autoload/GameState.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/GameState.gd)，理解运行态长什么样。
5. 读 [scripts/autoload/DayCycle.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/DayCycle.gd)，理解日循环结算。
6. 读 [scripts/autoload/EventManager.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/EventManager.gd)，理解问题事件的生成与解决。
7. 读 [scripts/autoload/AIDirector.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/AIDirector.gd)，理解 AI 与回退边界。
8. 读 [scripts/autoload/DataRepository.gd](/C:/Users/hacjr/Desktop/小红花社区/scripts/autoload/DataRepository.gd)，理解数据加载与校验。
9. 读 [tests/run_tests.gd](/C:/Users/hacjr/Desktop/小红花社区/tests/run_tests.gd) 和 [tests/full_game_smoke.gd](/C:/Users/hacjr/Desktop/小红花社区/tests/full_game_smoke.gd)，理解“项目作者认为什么必须一直可用”。
10. 最后再去看 `data/`、`tools/release/` 和其余 `core/` 文件，按你要接手的方向深入。

如果只做一次最小上手动作，我建议是：

1. 先运行 [run_tests.bat](/C:/Users/hacjr/Desktop/小红花社区/run_tests.bat)。
2. 再启动 [start_game.bat](/C:/Users/hacjr/Desktop/小红花社区/start_game.bat)。
3. 然后边跑边对照 `MainView.gd` 和 `DayCycle.gd` 看状态如何流动。

这样能最快把“文档理解”和“实际运行感”对齐。
