# 《看得见的一公里》音频清单

更新时间：2026-05-16

本清单记录当前 Demo 已注册的音频 ID、触发点、推荐风格与 fallback 行为。当前阶段允许没有最终音频资源：`AudioManager.gd` 会尝试从 `res://assets/audio/` 加载对应文件，缺失时静默返回成功，不阻塞游戏流程，不报错。

## 实现约定

- SFX 通过 `AudioManager.play_sfx(id)` 触发，走 `SFX` bus，受 `SettingsManager.sfx_volume` 控制。
- BGM 通过 `AudioManager.play_bgm(id)` 触发，走 `Music` bus，受 `SettingsManager.music_volume` 控制。
- 缺失资源时使用静默 fallback：记录最近请求 ID 和 fallback 状态，但不创建弹窗、不暂停流程、不抛出错误。
- 推荐资源位置统一为 `res://assets/audio/<audio_id>.ogg` 或 `res://assets/audio/bgm_<phase>.ogg`，不要硬编码绝对路径。
- 临时 AI 声音资产必须保留生成记录、用途、授权说明；不要冒充真人或未授权 IP 声线。

## SFX

| 音频 ID | 当前建议路径 | 触发时机 | 推荐风格 | fallback 行为 | AI 生成声音提示词 |
| --- | --- | --- | --- | --- | --- |
| `card_pick` | `res://assets/audio/card_pick.ogg` | 玩家从公告栏选卡进入物品栏 | 轻快纸卡滑动声，短、清晰、不刺耳 | 缺失时静默；选卡仍完成 | `short warm paper card pickup sound, soft community board game UI, no voice, 0.3 seconds, gentle click tail` |
| `craft_success` | `res://assets/audio/craft_success.ogg` | 两张卡成功合成新设施或道具 | 木片与小铃结合，带一点完成感 | 缺失时静默；合成结果照常进入手牌 | `cozy crafting success chime with light wood taps and small bell, optimistic but subtle, no melody longer than 1 second` |
| `craft_fail` | `res://assets/audio/craft_fail.ogg` | 合成区两张卡无法匹配配方或配方未开放 | 柔和低提示音，不惩罚、不惊吓 | 缺失时静默；失败原因仍由文字展示 | `soft failed craft UI cue, gentle muted knock, non-punitive, warm interface sound, 0.4 seconds` |
| `facility_place` | `res://assets/audio/facility_place.ogg` | 设施放到棋盘、拆除后重新规划等建设反馈 | 轻微落地声、纸板放置、社区模型摆件感 | 缺失时静默；棋盘状态照常更新 | `small diorama building placement sound, felt board and paper model, warm tactile click, no heavy construction noise` |
| `problem_resolved` | `res://assets/audio/problem_resolved.ogg` | 人力或支援卡解决问题事件 | 温和释然的确认音，像社区广播提示完成 | 缺失时静默；奖励和状态结算照常执行 | `gentle problem resolved UI stinger, soft marimba and breathy bell, community relief feeling, 0.8 seconds` |
| `dusk_penalty` | `res://assets/audio/dusk_penalty.ogg` | 黄昏结算出现未解决问题、惩罚或升级 | 克制的低频提示，表达遗憾但不压迫 | 缺失时静默；黄昏惩罚仍按规则执行 | `subtle dusk penalty cue, low warm felt piano note with distant paper rustle, regretful but not scary, 1 second` |
| `day10_summary` | `res://assets/audio/day10_summary.ogg` | Day 10 年度报告、评级和结局展示 | 小型社区年会收束音，温暖、有仪式感 | 缺失时静默；年度报告继续展示 | `warm annual community report stinger, small ensemble, hopeful civic ceremony, short ending cue, no vocals, 2 seconds` |
| `event_notice` | `res://assets/audio/event_notice.ogg` | 日出后有事件公告或问题卡出现 | 清楚的公告提示音，像社区广播开头 | 缺失时静默；事件预览照常出现 | `community notice alert, soft public announcement chime, friendly but attention grabbing, no alarm feeling` |
| `drag` | `res://assets/audio/drag.ogg` | 开始拖拽卡牌或问题人力 token | 很轻的纸张摩擦或拾取声 | 缺失时静默；拖拽照常进行 | `very short paper drag pickup sound, tactile card UI, quiet and low fatigue` |
| `save` | `res://assets/audio/save.ogg` | 手动存档成功 | 低调确认音 | 缺失时静默；存档结果照常写入 | `soft save confirmation UI sound, tiny warm click and shimmer, no fanfare` |
| `flower_gain` | `res://assets/audio/flower_gain.ogg` | 后续可用于小红花获得反馈 | 明亮但短促的小花奖励音 | 当前未强制触发；缺失时静默 | `tiny flower reward sparkle, organic bell, warm and playful, 0.5 seconds` |

## BGM

| 音频 ID | 当前建议路径 | 触发时机 | 推荐风格 | fallback 行为 | AI 生成声音提示词 |
| --- | --- | --- | --- | --- | --- |
| `sunrise` | `res://assets/audio/bgm_sunrise.ogg` | 每天日出结算开始 | 清晨社区环境，轻木吉他、柔和电钢、少量环境声 | 缺失时静默；会继续切到白天状态 | `seamless loop, warm morning neighborhood ambience, soft electric piano and light acoustic guitar, hopeful, low pressure, 60 seconds` |
| `day` | `res://assets/audio/bgm_day.ogg` | 白天主要操作阶段 | 低压策略桌游感，节奏清楚但不催促 | 缺失时静默；操作不受影响 | `seamless loop, cozy community planning board game music, light percussion, marimba, acoustic bass, calm focus, 90 seconds` |
| `dusk` | `res://assets/audio/bgm_dusk.ogg` | 点击进入黄昏结算后 | 稍慢、温柔反思，适合看结算文字 | 缺失时静默；结算继续 | `seamless loop, reflective dusk neighborhood music, soft piano, muted strings, gentle civic warmth, 60 seconds` |
| `night` | `res://assets/audio/bgm_night.ogg` | 夜间进入次日前的过渡 | 安静、整理、收束，避免恐怖或压迫 | 缺失时静默；夜间流程继续 | `seamless loop, quiet night community office ambience, soft synth pad, distant city room tone, calm closure, 60 seconds` |
| `day10_summary` | `res://assets/audio/bgm_day10_summary.ogg` | Day 10 年度报告、评级、居民结局 | 年度总结感，小型温暖庆典，不要过度宏大 | 缺失时静默；报告继续展示 | `seamless or 2 minute loop, warm community annual report music, hopeful piano and small strings, civic celebration, no choir, no vocals` |
| `rain` | `res://assets/audio/bgm_rain.ogg` | 后续雨天/天气事件预留 | 轻雨环境与低压循环 | 缺失时静默 | `gentle rainy neighborhood loop, soft rain bed, calm keys, not gloomy, 60 seconds` |
| `ending` | `res://assets/audio/bgm_day10_summary.ogg` | 旧 ID 兼容，映射到 Day 10 总结 | 与 `day10_summary` 一致 | 缺失时静默 | 同 `day10_summary` |

## 后续落地建议

1. 先补 `card_pick`、`craft_success`、`craft_fail`、`facility_place` 四个高频 SFX，用短音频降低重复疲劳。
2. 再补 `sunrise`、`day`、`dusk`、`night` 四段 loop，响度统一到同一主观音量。
3. 每个 SFX 准备 2-4 个变体时，再扩展 `AudioManager` 的随机池；当前阶段保持单 ID 单路径，方便测试。
4. 所有 AI 生成音频进入仓库前，需要记录生成工具、提示词、日期、用途、许可状态和是否临时占位。
