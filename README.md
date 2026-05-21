# 《看得见的一公里》Competition Demo

这是一个基于 Godot 4.6.2 的社区建设卡牌 Demo。玩家在 10 个社区日内从公告栏选择卡牌、合成设施、建设棋盘、处理问题事件，并在 Day 10 获得年度报告评级。

## 当前内容

- 80 张卡牌、40 条配方、12 个固定/AI/混合事件。
- 公告栏选卡、手牌合成、设施放置、问题处理、日出/黄昏/夜间结算。
- 居民满意度、健康值、愿望链、个人留言、自治等级和年度报告结局。
- 自动存档、手动存档、旧存档字段补齐。
- AI 事件导演、安全面板、本地回退池和请求日志。
- SteamBridge 模拟层：成就、语言、云存档路径接口先走本地 mock。
- 音效管理、音量设置、减少动态效果、高对比度、大字号、无时间压力等无障碍开关。
- Demo 平衡验证：保守/正常/优化三条路径覆盖 45-60 分钟估算，正常路径目标 50-55 分钟。

Steam 当前仍是模拟层，不包含真实 Steamworks SDK 或 SteamPipe 上传凭据。正式美术仍以轻量资产和占位资源为主。

## 运行

双击：

- `start_game.bat`：启动 Demo。
- `open_editor.bat`：用 Godot 打开工程。
- `run_tests.bat`：运行核心自动化测试。

命令行：

```powershell
godot --path "D:\Desktop\小红花社区"
godot_console --headless --path "D:\Desktop\小红花社区" --script res://tests/run_tests.gd --quit
```

## 测试

常用回归命令：

```powershell
godot_console --headless --path "D:\Desktop\小红花社区" --script res://tests/run_tests.gd --quit
godot_console --headless --path "D:\Desktop\小红花社区" --script res://tests/full_game_smoke.gd --quit
godot_console --headless --path "D:\Desktop\小红花社区" --script res://tests/animation_smoke.gd --quit
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\release_scripts_smoke.ps1
```

`live_ai_smoke.gd` 会尝试走真实 AI 兼容通路，适合在本机 AI 配置准备好时单独运行。

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
