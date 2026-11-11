# 《看得见的一公里》桌面堆叠 Demo

这是一个基于 Godot 4.6.2 的 PC 单机桌面堆叠社区经营 Demo。玩家通过顶部卡包栏获得卡牌，在 120 秒实时日间里把卡牌拖到桌面堆叠合成、把设施落到社区地图、把居民需求拖到对应服务建筑上处理；Day 10 不结算终局报告，游戏继续进入 Day 11。

## 当前内容

- 顶部卡包栏是当前唯一卡源，开包后卡牌直接落到桌面。
- 桌面 timed craft 堆叠合成、设施落地图、居民需求拖到服务建筑处理构成主循环。
- Day -1 引导、120 秒实时日间、日出/黄昏/夜间自动结算已经接通；Day 10 后继续进入 Day 11。
- 当前内容以 `data/` 实际文件为准，不再在 README 中承诺容易漂移的卡牌/配方/事件数量。
- 自动存档、手动存档、旧存档字段补齐。
- AI 事件导演、安全面板、本地回退池和请求日志。
- SteamBridge 模拟层：成就、语言、云存档路径接口先走本地 mock。
- 音效管理、音量设置、减少动态效果、高对比度、大字号、无时间压力等无障碍开关。
- 核心自动化覆盖 `run_tests.bat`、`full_game_smoke`、`first_10_minutes_smoke`、`drag_to_board_smoke`、`tabletop_reduce_motion_smoke` 等主路径。

Steam 当前仍是模拟层，不包含真实 Steamworks SDK 或 SteamPipe 上传凭据。正式美术仍以轻量资产和占位资源为主。

## 运行

双击：

- `start_game.bat`：启动 Demo。
- `open_editor.bat`：用 Godot 打开工程。
- `run_tests.bat`：运行核心自动化测试。

命令行：

```powershell
godot --path "."
godot_console --headless --path "." --script res://tests/run_tests.gd --quit
```

## 测试

常用回归命令：

```powershell
godot_console --headless --path "." --script res://tests/run_tests.gd --quit
godot_console --headless --path "." --script res://tests/full_game_smoke.gd --quit
godot_console --headless --path "." --script res://tests/animation_smoke.gd --quit
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\release_scripts_smoke.ps1
```

`live_ai_smoke.gd` 会检查真实 AI 兼容通路；本机没配 API Key 时会验证本地 fallback 并正常通过，适合单独跑来诊断 AI 边界。

## 导出与比赛 ZIP

发布版本号以 `tools/release/version.json` 为唯一来源。默认 Windows Demo preset 会导出到：

```text
build/windows/visible_one_kilometer_demo.exe
```

完整构建：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\release\build_demo.ps1
```

快速同步版本但不导出：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\release\build_demo.ps1 -SkipTests -NoExport
```

比赛包输出：

```text
dist/visible-one-kilometer-demo-vX.Y.Z.zip
```

ZIP 内包含 Windows exe、`README.md`、`version.json` 和 `build_info.json`。

## SteamPipe

`tools/release/` 内提供 SteamPipe VDF 模板，仅作为正式上传前的安全起点。真实 AppID、DepotID、账号、密码、分支凭据不要提交到仓库。

本阶段不做真实 Steam 上传；Steam Demo 上架前需要在私有位置填充模板，并用 SteamCMD 手动验证。


## 美术资源接入

美术资源的数据驱动接入流程见：

- `docs/art-pipeline-guide.md`

校验命令：

```powershell
godot --headless --path . --script res://tools/art/validate_art_pipeline.gd --quit
```
