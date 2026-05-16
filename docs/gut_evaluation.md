# GUT 测试框架评估

更新时间：2026-05-16

## 背景

当前项目已经有一条轻量、可本地运行的 Godot 测试链路：

- `run_tests.bat` 启动 `res://tests/run_tests.gd`
- `tests/run_tests.gd` 校验 autoload 是否齐全，并运行 `tests/test_core.gd`
- 额外 smoke 脚本覆盖完整 10 天流程、动画、平衡、通关后、音频设置和发布脚本

这条链路的优点是没有插件依赖、启动快、适合当前 Demo 的本地可玩性守门。缺点是测试组织、失败定位、报告格式和 CI 集成能力都比较朴素，随着核心玩法继续扩张，`test_core.gd` 会继续变长。

## GUT 概览

GUT（Godot Unit Test）是 bitwes 维护的 Godot 测试插件，适合把 GDScript 测试拆成更清晰的单元和集成测试套件。参考来源：

- GitHub：<https://github.com/bitwes/Gut>
- 命令行文档：<https://gut.readthedocs.io/en/v9.6.0/Command-Line.html>
- 导出测试结果文档：<https://gut.readthedocs.io/en/latest/Export-Test-Results.html>

从当前项目需求看，GUT 的价值主要在三点：

- 更标准的测试结构：按脚本、测试用例、前置/后置逻辑组织，而不是把所有断言手写到一个 runner 中。
- 更适合 CI：GUT 的命令行运行方式和测试结果导出能力更利于后续接入 GitHub Actions、GitLab CI 或本地构建流水线。
- 更适合长期维护：当 UI、音频、AI fallback、存档和日循环都需要持续回归时，GUT 能减少自维护 runner 的成本。

## JUnit 报告适配性

GUT 的测试结果导出能力适合后续 CI 使用，尤其是需要在 CI 页面中直接展示失败用例时。JUnit XML 对本项目有现实价值：

- 可以让 CI 汇总失败测试，而不是只靠 Godot 控制台文本。
- 可以区分核心规则测试、smoke 测试和后续 UI/音频专项测试。
- 可以保留历史测试趋势，辅助判断迭代是否造成核心玩法回归。

当前分支暂不直接接入 JUnit 输出，因为仓库里还没有插件目录、CI 配置和稳定的 Godot 安装发现策略。先写评估文档和增强现有测试覆盖，风险更低。

## 当前结论

本分支建议暂不接入 GUT 插件。

原因：

- 用户要求保留现有测试入口，且不能替换整个测试框架。
- 当前任务重点是补核心玩法覆盖，不是改测试基础设施。
- 直接引入插件会带来仓库体积、Godot 插件启用状态、CI Godot 版本和报告路径配置等额外变量。
- 现有 runner 已经能稳定覆盖 autoload 和核心逻辑，本次可以先在这条链路上补齐回归场景。

推荐策略是“先兼容、后迁移”：保留 `run_tests.bat` 和 smoke 脚本，把新增覆盖放进现有流程；等 CI 落地时，再把稳定的核心规则测试逐步迁到 GUT。

## 后续接入步骤

1. 固定 Godot 版本和 CI 下载/缓存方式，继续使用 Godot 4.6.2。
2. 通过 AssetLib 或 Git 子模块/供应商目录引入 GUT，并记录插件版本。
3. 新增 `tests/gut/`，先迁移纯规则测试，例如 `RecipeRules`、`BoardRules`、`RatingRules`、`PlayabilityDirector`。
4. 保留 `tests/run_tests.gd`，在一段时间内让旧 runner 与 GUT 并行运行。
5. 为 GUT 命令行增加 JUnit XML 输出目录，例如 `reports/gut/`。
6. CI 中依次运行：
   - `run_tests.bat` 或等价 headless 命令
   - GUT 单元/集成测试
   - `full_game_smoke.gd`
   - `animation_smoke.gd`
   - `demo_balance_smoke.gd`
   - `post_game_smoke.gd`
7. 当 GUT 覆盖达到旧 runner 等价范围后，再考虑缩减 `test_core.gd` 中的重复测试，但不删除 smoke 入口。

## 适合优先迁移到 GUT 的测试

- 配方匹配与合成失败原因。
- 棋盘放置、区域限制、多格建筑和邻接奖励。
- 问题事件解决、惩罚、升级队列。
- 居民愿望链、满意度、健康和记忆记录。
- Day 10 评级、年度报告和通关后模式。
- AI fallback 的本地降级路径。
- 存档字段回填和读档恢复。

## 暂不建议迁移的测试

- `full_game_smoke.gd`：它更像端到端流程守门，继续独立运行更清晰。
- `animation_smoke.gd`：属于表现层稳定性 smoke，先保持原入口。
- `live_ai_smoke.gd`：可能触发真实 AI 通路，不应进入默认 CI。
- 发布脚本 smoke：它是 PowerShell/打包链路测试，不适合塞进 GUT。

## 风险与注意事项

- GUT 插件接入后必须明确许可证、版本和更新方式，避免未来插件升级影响比赛交付。
- JUnit 报告路径要使用相对路径，不能依赖某台机器的绝对目录。
- GUT 测试不能绕过真实逻辑来伪造成功；迁移时应继续调用现有 autoload 和 core 规则。
- 旧 runner 和 GUT 并行期间，可能出现重复覆盖，但这是迁移期可接受的成本。
