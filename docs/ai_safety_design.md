# AI Safety Design

更新时间：2026-05-16

## 目标

AI 导演只能提供事件候选，不能成为游戏主循环的硬依赖。没有 API Key、网络失败、超时、内容被拦截或返回格式错误时，游戏必须使用本地 fallback 事件继续运行。

## 降级流程

1. `EventManager` 在日出阶段读取当天事件。
2. `fixed` 事件直接本地物化。
3. `ai` 或 `hybrid` 事件调用 `AIDirector` 请求候选。
4. `AIDirector` 先检查模式、API Key 和 URL。
5. 任何失败都会进入同一个 fallback builder：
   - 优先读取事件的 `fallback_event_id`。
   - 找不到 fallback 时使用原事件定义。
   - 返回本地 candidate，并标记 `fallback_used = true`。
6. `EventManager` 只消费 candidate，把它转成公告和问题状态。

这条链路保证 AI 失败不会阻塞 DayCycle，也不会直接写入 `GameState`。

## 失败原因分类

`AIDirector.classify_failure_reason()` 把底层错误归一为以下类别：

- `no_api_key`：没有 API Key。
- `timeout`：HTTP 请求超时。
- `invalid_response`：HTTP 状态异常、空响应、非 JSON、缺字段、schema 不通过。
- `blocked_content`：远程返回内容过滤。
- `network_error`：连接、DNS、TLS、请求层错误。
- `fallback_used`：开发者强制本地或同步路径无法远程请求。

## 记录的数据

`AIDirector.get_safety_summary()` 现在提供：

- `fallback_count`
- `blocked_count`
- `success_count`
- `last_failure_reason`
- `last_request_status`
- `last_fallback_event_id`
- `request_history`

每条 fallback 日志包含：

- 原事件 ID
- fallback 事件 ID
- provider
- result
- normalized reason
- raw reason

`EventManager` 也会把 `fallback_used`、`ai_failure_reason`、`fallback_event_id` 写入公告和问题状态，方便 UI、存档和 smoke 验证。

## SafetyPanel 展示

`SafetyPanel` 显示：

- 请求数、成功数、fallback 次数、拦截次数。
- 最近请求状态。
- 最近失败原因。
- 最近 fallback 事件 ID。
- 请求历史中每次 fallback 的事件 ID、fallback 事件 ID 和原因。

## 为什么不会阻塞主循环

- 本地模式和缺 API Key 直接同步返回 fallback。
- 异步远程请求只发生在 `resolve_sunrise_events_async()` 中；失败后立即转本地 candidate。
- `EventManager` 不等待二次外部调用，也不重试远程请求。
- fallback candidate 使用已经通过 `DataRepository` 校验的本地事件数据。

## LimboAI 评估

参考项目：[limbonaut/limboai](https://github.com/limbonaut/limboai)

LimboAI 提供 Godot 4 的行为树与层级状态机，适合未来把 AI 导演建模为“教学期、发展期、压力期、结局期”等可视化状态。但当前安全需求主要是失败分类、fallback 和审计展示，不需要引入 C++/GDExtension 插件。现阶段只借鉴状态机思想，用字符串状态和测试覆盖实现。

## GUT 评估

参考项目：[bitwes/Gut](https://github.com/bitwes/Gut)

GUT 是 Godot 的单元测试框架，Godot Asset Library 和 GUT 文档均提供 Godot 4 版本。它适合后续把 AI fallback 测试拆成更细的测试类、fixture 和断言工具，尤其是网络模拟、异步请求、UI 面板测试。但当前项目已有 `tests/run_tests.gd`、`tests/test_core.gd` 和 smoke 脚本，短期先补现有测试，避免引入新插件和 CI 复杂度。

后续建议：

- 如果 AI 安全测试继续增多，再单独评估 GUT。
- 如果引入 GUT，应从 `AIDirector` 的纯函数分类测试开始迁移。
- 不要为了测试改成绕过 fallback 的假路径，测试必须继续覆盖真实 fallback builder。
