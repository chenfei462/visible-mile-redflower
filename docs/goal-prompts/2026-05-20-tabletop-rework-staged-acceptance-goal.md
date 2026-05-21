## 总目标

把当前游戏从“网格设施/旧问题/信任/自治”改造成类似参考视频与图片的自由堆叠卡牌桌面玩法，并保证每个阶段都有可运行、可截图、可回归的验收结果。

## 参考素材学习要求

开始实现前，必须先学习并拆解下面 3 个参考素材，不要只按文字规则改系统：

- `C:\Users\hacjr\Downloads\1388127494.mp4`
- `C:\Users\hacjr\Downloads\_cgi-bin_mmwebwx-bin_webwxgetmsgimg__&MsgID=5841386302765502893&skey=@crypt_ab8b7fa5_f05b4658eece4ea1c5f45d0ab6480fbb&mmweb_appid=wx_webfilehelper.jpg`
- `C:\Users\hacjr\Downloads\_cgi-bin_mmwebwx-bin_webwxgetmsgimg__&MsgID=1908204182967240442&skey=@crypt_ab8b7fa5_f05b4658eece4ea1c5f45d0ab6480fbb&mmweb_appid=wx_webfilehelper.jpg`

必须从参考素材中提炼并落地这些视觉与交互特征：

- 画面基调：浅绿色草地桌面、手绘树木/草丛背景、粗黑手绘边框、纸张质感 UI。
- 核心布局：中间是一整块大桌面区域，卡牌自由散落、可堆叠，不再被格子约束。
- 顶部区域：一排黑色商店/公告栏卡槽，卡面有价格、未知卡、出售入口或资源图标。
- 左侧区域：纸质任务/意图列表，像便签/账本一样纵向列出目标。
- 右上区域：资源条、日期/月相/时间推进按钮，使用黑色描边纸牌风格。
- 底部区域：缩放、整理、设置等小工具按钮，悬浮在桌面下方。
- 卡牌风格：小尺寸竖卡，粗黑描边，顶部标题条，颜色区分类型；卡牌堆叠时露出上方标题条。
- 操作方式：拖拽卡牌、叠放卡牌、卡牌互相合成/作用，桌面像实体桌游而不是传统面板菜单。
- 动效方向：卡牌拿取、拖动、堆叠、合成、解决需求时应有轻量弹跳/飞行动画，不要做复杂特效。
- 可读性：即使仿照参考图，也必须保证中文标题、资源数量、需求状态清楚可读。

在 Phase 0 中，必须先输出一段“参考素材拆解记录”，说明：

1. 从视频中观察到的桌面交互节奏。
2. 从两张图片中提炼出的 UI 布局。
3. 哪些元素会在本项目中直接仿照。
4. 哪些元素只做风格参考、不照搬。
5. 本阶段截图验收如何判断“像参考素材”。

如果 Claude 无法直接读取视频或图片文件，必须明确说明，并改用本提示词中写明的参考特征作为验收依据；不能忽略“仿照参考素材”这一目标。

核心改造目标：

- 居民需求必须有可见、可交互、可解决的需求卡/需求实体，不能只在黄昏自动结算。
- 建筑自然产出全部取消。
- 绿化建筑只有居民驻扎时产出小红花。
- 商业建筑只有居民驻扎时产出资金。
- 服务建筑只负责居民需求，不再靠驻扎产出资源。
- 所有建筑统一为“建筑许可 + 1 份专属材料 = 直接完成建筑”。
- 删除旧升级链和旧配方兼容入口。
- 公告栏每天只刷新 2 张建筑许可 + 3 份材料。
- 公告栏只允许 `material` 和 `building_permit` 类型出现。
- 住宅与志愿者站继续通过公告栏许可体系获得。
- 住宅价格走资金专线，首档 2，之后每次 +2。
- 志愿者站价格走小红花专线，首档 2，之后每次 +2。
- 每 5 天按住宅上限补满迁入。
- 居民模板使用现有 `residents.json` 人设循环，并编号扩展。
- 桌面从网格放置改成自由堆叠桌面。
- 旧 `facility/support/problem/trust/autonomy` 相关玩法整体移除或从主循环断开。

## 重要路径

项目路径：

```powershell
C:\Users\hacjr\Desktop\小红花社区
```

阶段性验收工具路径：

```powershell
C:\Users\hacjr\Desktop\游戏测试
```

自动化工具说明：

```powershell
C:\Users\hacjr\Desktop\游戏测试\tools\automation\README.md
```

可用自动化命令示例：

```powershell
cd C:\Users\hacjr\Desktop\游戏测试
python -m pytest tools/automation/tests -q
python -m tools.automation.automation.recipes.open_edit_run_smoke --project "C:\Users\hacjr\Desktop\小红花社区" --scene res://scenes/Main.tscn
```

项目内基础测试命令：

```powershell
cd C:\Users\hacjr\Desktop\小红花社区
.\run_tests.bat
godot_console --headless --path . --script res://tests/run_tests.gd --quit
godot_console --headless --path . --script res://tests/first_10_minutes_smoke.gd --quit
godot_console --headless --path . --script res://tests/full_game_smoke.gd --quit
```

如果本机没有 `godot_console`，优先使用仓库现有入口：

```powershell
.\run_tests.bat
```

## 当前重点文件

开始前先阅读这些文件，不要盲改：

- `data/day_sequence.json`
- `data/cards.json`
- `data/recipes.json`
- `data/residents.json`
- `scripts/autoload/GameState.gd`
- `scripts/autoload/DayCycle.gd`
- `scripts/autoload/DataRepository.gd`
- `scripts/autoload/SaveManager.gd`
- `scripts/core/ResidentSystem.gd`
- `scripts/core/RecipeRules.gd`
- `scripts/core/BoardRules.gd`
- `scripts/core/PrototypeRules.gd`
- `scripts/core/PlayabilityDirector.gd`
- `scripts/ui/MainView.gd`
- `scripts/ui/CardView.gd`
- `scripts/ui/IsometricGridPainter.gd`
- `tests/test_core.gd`
- `tests/first_10_minutes_smoke.gd`
- `tests/full_game_smoke.gd`

## 工作纪律

必须按 TDD 与阶段验收执行：

1. 每个阶段先写或修改失败测试。
2. 运行对应测试，确认失败原因正好是本阶段目标。
3. 再写最小实现。
4. 再运行项目内测试。
5. 再运行 `游戏测试` 文件夹中的阶段性自动化验收。
6. 记录命令、退出码、PASS/FAIL banner、截图或状态文件路径。

不要：

- 不要直接大面积重写系统。
- 不要把旧 `problem / wish / trust / autonomy` 逻辑重新接回主循环。
- 不要为了让测试过而降低验收标准。
- 不要删除用户已有未提交改动，除非该改动明确属于本目标且必须替换。
- 不要提交 git commit，除非用户另外要求。

## Phase 0：基线验收

### 目标

记录当前项目与自动化工具的基线状态。

### 必做

1. 读取 `C:\Users\hacjr\Desktop\游戏测试\tools\automation\README.md`。
2. 运行自动化工具自身测试：

```powershell
cd C:\Users\hacjr\Desktop\游戏测试
python -m pytest tools/automation/tests -q
```

3. 运行项目基线测试：

```powershell
cd C:\Users\hacjr\Desktop\小红花社区
.\run_tests.bat
```

### 阶段通过标准

- 自动化工具测试出现类似 `passed` 的 pytest 结果。
- 项目基线测试记录 `ALL TESTS PASSED` 或列出真实失败项。
- 如果基线失败，只处理与本目标直接相关的失败。

## Phase 1：公告栏与直接建造规则

### 目标

公告栏只提供 `2 building_permit + 3 material`，建筑只通过“建筑许可 + 1 份专属材料”直接生成。

### 先写测试

在 `tests/test_core.gd` 中补充或修改断言，覆盖：

- 每日公告栏数量固定为 5。
- 每日公告栏包含 2 张 `building_permit`。
- 每日公告栏包含 3 张 `material`。
- 公告栏不会出现建筑成品、支援、问题、居民或旧类型卡。
- 每个建筑配方都只有 2 个输入：一个 `building_permit`，一个专属 `material`。
- 不存在旧升级链配方。
- 不存在 `support` 结果配方。

### 实现重点

重点检查并修改：

- `data/day_sequence.json`
- `data/cards.json`
- `data/recipes.json`
- `scripts/core/PlayabilityDirector.gd`
- `scripts/core/RecipeRules.gd`
- `scripts/core/PrototypeRules.gd`

### 项目内验收命令

```powershell
cd C:\Users\hacjr\Desktop\小红花社区
godot_console --headless --path . --script res://tests/run_tests.gd --quit
```

如不可用：

```powershell
.\run_tests.bat
```

### 游戏测试文件夹验收命令

```powershell
cd C:\Users\hacjr\Desktop\游戏测试
python -m tools.automation.automation.recipes.open_edit_run_smoke --project "C:\Users\hacjr\Desktop\小红花社区" --scene res://scenes/Main.tscn --screenshot-name phase1-bulletin-direct-build
```

### 阶段通过标准

- 项目内测试通过。
- 自动化 smoke recipe 退出码为 `0`。
- 运行后没有残留 `AutomationProbe`。
- 记录截图名称 `phase1-bulletin-direct-build` 或实际输出截图路径。

## Phase 2：居民需求可见与可交互

### 目标

居民需求在白天开始时全部生成并可见，玩家可以对需求进行交互解决，不再因为没有交互入口而卡死。

### 先写测试

在 `tests/test_core.gd`、`tests/first_10_minutes_smoke.gd` 中覆盖：

- 每天开始时每个居民生成 1 个需求实体。
- 需求写入 `resident_need_entities`。
- 需求包含 `resident_id`、`resident_name`、`need_tags`、`status`、`day_created`。
- 需求卡/需求实体在白天 UI 可见，而不是只在黄昏结算出现。
- 服务建筑容量统一为 2。
- 玩家解决需求后，状态从 `pending` 变为 `resolved` 或从队列中正确移除。
- 黄昏只结算未解决需求。

### 实现重点

重点检查并修改：

- `scripts/core/ResidentSystem.gd`
- `scripts/autoload/DayCycle.gd`
- `scripts/ui/MainView.gd`
- `scripts/ui/CardView.gd`

### 交互建议

采用最小可行方案：

- 需求以卡牌形式出现在桌面或侧栏。
- 服务建筑卡显示可服务标签与剩余容量。
- 玩家拖拽需求卡到匹配服务建筑上即可解决。
- 暂时不要引入复杂动画，先保证交互闭环。

### 项目内验收命令

```powershell
cd C:\Users\hacjr\Desktop\小红花社区
godot_console --headless --path . --script res://tests/run_tests.gd --quit
godot_console --headless --path . --script res://tests/first_10_minutes_smoke.gd --quit
```

### 游戏测试文件夹验收命令

```powershell
cd C:\Users\hacjr\Desktop\游戏测试
python -m tools.automation.automation.recipes.open_edit_run_smoke --project "C:\Users\hacjr\Desktop\小红花社区" --scene res://scenes/Main.tscn --screenshot-name phase2-visible-resident-needs
```

### 阶段通过标准

- `run_tests.gd` 通过。
- `FIRST 10 MINUTES SMOKE PASSED` 出现。
- 自动化 smoke recipe 退出码为 `0`。
- 截图能证明主场景可运行。

## Phase 3：建筑驻扎与产出重构

### 目标

取消建筑自然产出，改为居民驻扎驱动产出：

- 绿化建筑 + 居民驻扎 = 小红花。
- 商业建筑 + 居民驻扎 = 资金。
- 服务建筑 + 居民/需求交互 = 解决需求，不产资源。

### 先写测试

覆盖：

- 没有居民驻扎时，绿化建筑不产小红花。
- 没有居民驻扎时，商业建筑不产资金。
- 有居民驻扎时，绿化建筑产小红花。
- 有居民驻扎时，商业建筑产资金。
- 服务建筑不会通过驻扎产出小红花或资金。
- 服务建筑只影响需求解决能力/容量。

### 实现重点

重点检查并修改：

- `scripts/core/BoardRules.gd`
- `scripts/core/ResidentSystem.gd`
- `scripts/autoload/DayCycle.gd`
- `scripts/autoload/GameState.gd`

如果仍保留旧 `built_facilities` 字段用于兼容，可以保留字段名，但主语义应迁移为新建筑系统；不要继续依赖旧邻接/自然产出规则。

### 验收命令

```powershell
cd C:\Users\hacjr\Desktop\小红花社区
godot_console --headless --path . --script res://tests/run_tests.gd --quit
godot_console --headless --path . --script res://tests/full_game_smoke.gd --quit
```

```powershell
cd C:\Users\hacjr\Desktop\游戏测试
python -m tools.automation.automation.recipes.open_edit_run_smoke --project "C:\Users\hacjr\Desktop\小红花社区" --scene res://scenes/Main.tscn --screenshot-name phase3-staffed-building-production
```

### 阶段通过标准

- 核心测试通过。
- `FULL GAME SMOKE PASSED` 出现。
- 自动化 smoke recipe 退出码为 `0`。

## Phase 4：住宅、志愿者站与迁入

### 目标

住宅和志愿者站仍通过公告栏许可体系获得，但有独立价格线；每 5 天按住宅上限补满迁入。

### 先写测试

覆盖：

- 住宅许可价格使用资金。
- 住宅首档价格为 2。
- 住宅每次购买后下一档 +2。
- 志愿者站许可价格使用小红花。
- 志愿者站首档价格为 2。
- 志愿者站每次购买后下一档 +2。
- 每 5 天检查住宅上限。
- 当前居民数低于上限时补满迁入。
- 新迁入居民从现有模板循环复制。
- 复制居民带编号扩展，避免 `resident_id` 冲突。

### 实现重点

重点检查并修改：

- `scripts/autoload/GameState.gd`
- `scripts/core/ResidentSystem.gd`
- `scripts/core/PrototypeRules.gd`
- `data/residents.json`
- `data/cards.json`

### 验收命令

```powershell
cd C:\Users\hacjr\Desktop\小红花社区
godot_console --headless --path . --script res://tests/run_tests.gd --quit
godot_console --headless --path . --script res://tests/full_game_smoke.gd --quit
```

```powershell
cd C:\Users\hacjr\Desktop\游戏测试
python -m tools.automation.automation.recipes.open_edit_run_smoke --project "C:\Users\hacjr\Desktop\小红花社区" --scene res://scenes/Main.tscn --screenshot-name phase4-housing-volunteer-movein
```

### 阶段通过标准

- 价格递增测试通过。
- 迁入测试通过。
- 自动化 smoke recipe 退出码为 `0`。

## Phase 5：自由堆叠桌面替代网格

### 目标

将主桌面从网格放置改成类似参考图的自由堆叠桌面。

### 先写测试

覆盖：

- 主界面启用自由桌面布局。
- 卡牌具有自由位置字段。
- 拖拽结束后保存卡牌位置。
- 卡牌可以重叠/堆叠。
- 卡牌有 z-index 或层级规则，点击/拖动会置顶。
- 旧网格放置不再是主建筑放置路径。
- 旧 `IsometricGridPainter` 不再主导核心玩法交互。

### 实现重点

重点检查并修改：

- `scripts/ui/MainView.gd`
- `scripts/ui/CardView.gd`
- `scripts/ui/IsometricGridPainter.gd`
- `scenes/Main.tscn`
- `scenes/CardView.tscn`
- `scripts/autoload/SaveManager.gd`

### UI 方向

布局接近参考图：

- 顶部：公告栏/商店卡列。
- 中央：大面积绿色自由桌面。
- 左侧：任务/需求列表。
- 右上：资源、日期、时间推进。
- 底部：缩放、整理、设置按钮。

### 验收命令

```powershell
cd C:\Users\hacjr\Desktop\小红花社区
godot_console --headless --path . --script res://tests/run_tests.gd --quit
godot_console --headless --path . --script res://tests/animation_smoke.gd --quit
godot_console --headless --path . --script res://tests/drag_to_board_smoke.gd --quit
```

```powershell
cd C:\Users\hacjr\Desktop\游戏测试
python -m tools.automation.automation.recipes.open_edit_run_smoke --project "C:\Users\hacjr\Desktop\小红花社区" --scene res://scenes/Main.tscn --screenshot-name phase5-free-stacking-tabletop
```

### 阶段通过标准

- 桌面相关测试通过。
- 自动化 smoke recipe 退出码为 `0`。
- 截图能看到自由桌面而不是旧网格主玩法。

## Phase 6：旧系统断开与清理

### 目标

旧 `facility/support/problem/trust/autonomy` 相关玩法从主循环断开，避免回归。

### 先写测试

覆盖：

- 公告栏不会出现 `support`、`problem`、旧 `facility` 成品。
- 今日目标不再出现旧 `problem` 或 `wish` 目标。
- 日循环不依赖 `trust` 解锁。
- 日循环不依赖 `autonomy`。
- 存档加载不会因为旧字段缺失崩溃。
- 旧存档字段存在时会被忽略或安全迁移。

### 实现重点

重点检查并修改：

- `scripts/autoload/GameState.gd`
- `scripts/autoload/SaveManager.gd`
- `scripts/autoload/EventManager.gd`
- `scripts/autoload/AIDirector.gd`
- `scripts/core/PlayabilityDirector.gd`
- `scripts/core/PrototypeRules.gd`
- `tests/test_core.gd`
- `tests/full_game_smoke.gd`

不要为了“清理”而删除仍被 Godot 场景引用、会导致加载失败的脚本。先断开主循环，再安全删除或保留空兼容层。

### 验收命令

```powershell
cd C:\Users\hacjr\Desktop\小红花社区
.\run_tests.bat
godot_console --headless --path . --script res://tests/first_10_minutes_smoke.gd --quit
godot_console --headless --path . --script res://tests/full_game_smoke.gd --quit
```

```powershell
cd C:\Users\hacjr\Desktop\游戏测试
python -m tools.automation.automation.recipes.open_edit_run_smoke --project "C:\Users\hacjr\Desktop\小红花社区" --scene res://scenes/Main.tscn --screenshot-name phase6-legacy-systems-disconnected
```

### 阶段通过标准

- 全量测试通过。
- 旧玩法不会从公告栏、日循环、需求解决、建筑产出中重新出现。
- 自动化 smoke recipe 退出码为 `0`。

## Final：最终整体验收

完成所有阶段后，运行：

```powershell
cd C:\Users\hacjr\Desktop\小红花社区
.\run_tests.bat
godot_console --headless --path . --script res://tests/first_10_minutes_smoke.gd --quit
godot_console --headless --path . --script res://tests/full_game_smoke.gd --quit
```

再运行：

```powershell
cd C:\Users\hacjr\Desktop\游戏测试
python -m pytest tools/automation/tests -q
python -m tools.automation.automation.recipes.open_edit_run_smoke --project "C:\Users\hacjr\Desktop\小红花社区" --scene res://scenes/Main.tscn --screenshot-name final-tabletop-rework-acceptance
```

最终完成定义：

- 居民需求白天可见、可交互、可解决。
- 建筑自然产出已取消。
- 绿化/商业建筑只通过居民驻扎产出。
- 服务建筑只解决需求。
- 建筑配方统一为许可 + 专属材料。
- 公告栏每天只出现 2 张许可 + 3 份材料。
- 住宅/志愿者站价格线正确递增。
- 每 5 天迁入补满住宅上限。
- 主桌面为自由堆叠卡牌桌面。
- 旧玩法不会回到主循环。
- 项目内测试通过。
- `游戏测试` 自动化验收通过。

## 最终回复格式

完成后按下面格式回复，不要只说 done：

1. 修改了哪些文件。
2. 每个 Phase 的测试命令、退出码、PASS/FAIL banner。
3. `C:\Users\hacjr\Desktop\游戏测试` 自动化验收命令与结果。
4. 生成的截图/状态文件路径。
5. 是否存在环境噪声，例如端口 `9601 / 9876` 被占用。
6. 尚未完成项或风险点。

现在开始执行。
