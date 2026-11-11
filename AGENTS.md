# Xiaohonghua Community Codex Protocol

This is a Godot 4 project. Codex should treat this repository as an existing playable game, not a blank project.

## Project Facts

- Engine: Godot 4
- Main scene: `res://scenes/Main.tscn`
- Genre: single-player community-building card/tabletop prototype
- Current status: existing runnable demo with cards, recipes, board play, residents, events, save logic, AI fallback, safety panel, and smoke tests

## Required Context

Before changing code, read the smallest useful set from:

1. `docs/project-handoff-guide.md`
2. `README.md`
3. `project.godot`
4. Relevant design docs, data files, scripts, and tests for the requested feature

## Automatic Role Routing

The user should not need to say which role or agent to call. When the user asks for a game feature, optimization, bug fix, UI pass, review, or production task, Codex should infer the relevant roles automatically.

Use true subagent delegation when the Codex runtime allows it and the subtasks are independent. If tool-level policy blocks subagent spawning for the current wording, apply the same role routing locally and say clearly that no subagent was spawned. Never pretend that work was delegated when it was only role-guided locally.

Default role combinations:

- Gameplay feature: `producer`, `game-designer`, `godot-specialist`, `gameplay-programmer`, `qa-tester`
- UI or player clarity: `producer`, `ux-designer`, `ui-programmer`, `godot-specialist`, `qa-tester`
- Performance optimization: `performance-analyst`, `godot-specialist`, `lead-programmer`, `qa-tester`
- Architecture or refactor: `technical-director`, `lead-programmer`, `godot-specialist`, `qa-lead`
- Data, recipes, economy, balance: `systems-designer`, `economy-designer`, `game-designer`, `qa-tester`
- Narrative, residents, events, copy: `narrative-director`, `writer`, `game-designer`, `qa-tester`
- Release or export: `producer`, `release-manager`, `devops-engineer`, `qa-lead`
- Review: `qa-lead`, `qa-tester`, plus specialists matching the changed files

For broad requests such as "optimize this game" or "improve Xiaohonghua Community", start with four independent read-only streams:

- `performance-analyst`: frame time, repeated UI rebuilds, loading, memory, test coverage
- `ux-designer`: first 10 minutes, player entry, feedback clarity, drag/drop discoverability
- `game-designer`: core loop, goals, rewards, progression, retention
- `godot-specialist`: scene tree, autoload boundaries, signals, state sync, script size

## Work Rules

- Make small, reversible changes.
- Keep save compatibility unless the user explicitly asks otherwise.
- Prefer data-driven changes for cards, recipes, tutorials, events, and balance.
- Do not rewrite the project from scratch.
- Do not perform a large `MainView.gd` refactor unless the task explicitly approves a staged refactor plan.
- Do not remove existing systems such as day flow, events, board rules, residents, save management, AI fallback, or safety features without explicit approval.
- Do not make gameplay depend on live network AI. Local fallback must keep working.
- Treat Steam or platform integrations as mock-only unless the user explicitly approves real SDK work.

## High-Risk Files

Be especially careful with:

- `scripts/ui/MainView.gd`
- `scripts/autoload/GameState.gd`
- `scripts/autoload/DayCycle.gd`
- `scripts/autoload/EventManager.gd`
- `scripts/autoload/SaveManager.gd`
- `scripts/autoload/DataRepository.gd`
- `scripts/autoload/TutorialManager.gd`
- `scripts/core/PlayabilityDirector.gd`
- `scripts/core/PrototypeRules.gd`

## Validation

Run the smallest relevant verification first. For normal changes, prefer:

- `run_tests.bat`
- relevant smoke tests under `tests/`
- Godot scene run only when needed for visual or interaction behavior

If verification cannot run, report exactly what blocked it and which manual checks remain.

## Final Response Requirements

Every completed task should report:

- Files changed
- What changed
- Tests or checks run
- Remaining risks
- Suggested manual verification when useful
