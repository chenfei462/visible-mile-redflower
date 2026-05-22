# Godot Doctor 检查目标清单

本文档根据当前项目文件与最新未提交改动整理，用于指导 Godot Doctor 或人工检查优先关注哪些资源链。当前改动重点包括：

- 启用 `addons/godot_doctor` 插件。
- 扩展 `scripts/ui/MainView.gd` 的桌面卡牌堆叠、自动合成、计时合成与 reduce motion 行为。
- 新增桌面合成相关核心测试与 smoke test。

## 必须检查

| 文件 | 检查重点 |
| --- | --- |
| `project.godot` | 确认 `res://addons/godot_doctor/plugin.cfg` 已启用；检查主场景、autoload、插件列表没有异常。 |
| `scenes/Main.tscn` | 确认主场景仍正确绑定 `MainView.gd`，桌面面板、动画层、拖放相关节点引用可用。 |
| `scripts/ui/MainView.gd` | 核心改动文件。重点查桌面卡牌实例 ID、堆叠命中、自动合成、计时合成、反馈记录、reduce motion 分支。 |
| `data/cards.json` | 检查 `ramp_blueprint`、`lumber_pack`、`community_ramp` 等卡牌定义，尤其是 `type`、`board_placeable` 与卡牌 ID 是否匹配代码引用。 |
| `data/recipes.json` | 检查 `build_ramp` 配方、`result_card_id`、材料输入、`time_cost_sec` 等字段是否支持桌面合成逻辑。 |
| `tests/test_core.gd` | 新增桌面合成单测。检查脚本语法、资源引用、测试夹具和新增断言是否稳定。 |
| `tests/tabletop_reduce_motion_smoke.gd` | 新增 reduce motion smoke。检查计时合成在减少动态效果时是否立即完成。 |

## 关联依赖建议检查

这些文件不是本次直接修改目标，但 `MainView.gd` 的新逻辑会调用它们。若 Godot Doctor 支持按依赖扩展扫描，建议一并纳入：

| 文件 | 关联原因 |
| --- | --- |
| `scripts/core/RecipeRules.gd` | 负责匹配配方、消耗材料、记录配方发现。 |
| `scripts/core/BoardRules.gd` | 提供 inventory 结构与棋盘规则，桌面合成会通过它确保库存状态。 |
| `scripts/autoload/GameState.gd` | 桌面合成会读写全局游戏状态、建造设施列表与配方发现状态。 |
| `scripts/autoload/DataRepository.gd` | 提供 `cards_by_id` 与 `recipes`，是卡牌和配方校验入口。 |
| `scripts/autoload/SettingsManager.gd` | `reduce_motion` 会影响计时合成是否立即完成。 |
| `scripts/autoload/AudioManager.gd` | 合成开始、成功、失败会触发音效。 |
| `scripts/autoload/TutorialManager.gd` | 成功合成后会标记 `craft` 行为。 |
| `scripts/autoload/SteamBridge.gd` | 成功合成会触发 demo 成就 mock。 |

## Godot Doctor 集成检查

这些文件用于确认插件被正确引入项目，而不是检查游戏业务逻辑：

| 文件 | 检查重点 |
| --- | --- |
| `addons/godot_doctor/plugin.cfg` | 确认插件存在、版本固定，并可被 `project.godot` 正确引用。 |
| `addons/godot_doctor/settings/godot_doctor_settings.tres` | 确认默认关闭更新检查、欢迎弹窗和 toast，避免干扰自动化。 |
| `tests/godot_doctor_integration_smoke.ps1` | 检查插件集成 smoke 是否覆盖插件启用、版本、设置和 C# 文件裁剪。 |

## 不用优先检查

| 路径 | 原因 |
| --- | --- |
| `addons/godot_doctor/examples/**` | 插件示例，不属于当前游戏运行链路。 |
| `addons/godot_doctor/core/**` | 除非修改 Godot Doctor 插件本体，否则不应把插件源码当作本次业务检查重点。 |
| `run_tests.bat` | 这是测试编排脚本，适合直接运行验证，不是 Godot Doctor 的主要资源检查目标。 |

## 建议检查顺序

1. 先检查 `project.godot` 与 Godot Doctor 集成文件，确认插件可加载。
2. 再检查 `scenes/Main.tscn` 和 `scripts/ui/MainView.gd`，确认主场景与核心逻辑可解析。
3. 然后检查 `data/cards.json` 与 `data/recipes.json`，确认桌面合成数据链完整。
4. 最后检查新增测试文件，确认测试资源引用与运行入口稳定。

