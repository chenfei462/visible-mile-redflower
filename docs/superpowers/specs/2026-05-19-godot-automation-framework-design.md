# Godot Automation Framework Design

## Goal

Build a reusable local automation framework for this project that can:

- control the Godot editor reliably for structured project edits,
- run and validate the game after editor-driven changes,
- use GUI automation only when semantic editor control is unavailable,
- standardize runtime playtesting on `godot-ai-playtest` instead of growing ad hoc game-control scripts.

The framework is intended to automate common development and regression flows for the existing Godot 4.6.2 project, not to replace the game's internal logic or to become a generic desktop automation suite.

## Scope

In scope:

- an external automation layer under `tools/automation/`,
- integration with the existing editor TCP bridge in `addons/mcp_bridge/plugin.gd`,
- runtime playtesting integration with `godot-ai-playtest`,
- minimal GUI fallback for the Godot editor window,
- reusable automation recipes for edit, save, run, and runtime verification workflows,
- conservative handling of known editor dialogs and error states.

Out of scope:

- rewriting the core game loop, scene architecture, or existing gameplay systems,
- replacing the existing editor bridge with a brand-new protocol in phase 1,
- broad automation of arbitrary third-party desktop applications,
- exhaustive support for every Godot plugin panel or every possible editor layout,
- OCR-first control as the primary automation path,
- fully automated handling of all system-native file dialogs.

## Current Context

The repository already contains two relevant automation primitives:

1. An editor plugin bridge in `addons/mcp_bridge/plugin.gd` that can already open scenes, inspect and modify nodes, save, run, stop, inspect output, and perform limited scene operations.
2. A game runtime bridge in `mcp_bridge_game.gd` that can capture screenshots, inspect the runtime tree, and inject basic pointer input.

The editor bridge is already the most stable path for editor automation because it operates on Godot semantics instead of screen coordinates. The runtime bridge is useful, but narrower than a purpose-built runtime test layer. The user-approved direction is therefore:

- keep editor automation centered on the existing semantic editor bridge,
- add a minimal GUI fallback layer for editor-only gaps,
- standardize runtime testing on `godot-ai-playtest`.

## Design Principles

The framework should follow these rules:

1. Semantic control first. If the editor bridge can complete an operation, it should be used before any GUI automation is attempted.
2. GUI automation is a fallback, not a peer. Mouse, keyboard, screenshot, OCR, and window switching should only cover gaps that the editor bridge cannot handle.
3. Verification before advance. Every action must be followed by a result check before the next action is allowed to proceed.
4. Conservative failure handling. Unknown editor states and unknown dialogs should stop the workflow with evidence instead of guessing.
5. Edge isolation. The framework should live at the project edge and avoid unnecessary edits to the game's core systems.
6. Runtime testing is separate from editor control. The editor layer should launch the game; the runtime layer should validate the running game.

## Architecture

The framework should be split into the following modules.

### 1. `EditorSession`

Responsibilities:

- start or attach to the Godot editor process,
- probe the configured editor port from `mcp_ports.cfg`,
- establish and maintain the TCP connection to the editor bridge,
- track whether the editor is reachable and whether a scene is open,
- expose editor health checks and reconnect behavior.

This module answers one question: "Is the editor currently controllable?"

### 2. `EditorSemanticDriver`

Responsibilities:

- wrap the existing editor bridge commands behind a Python API,
- open scenes,
- inspect the scene tree,
- read and modify node properties,
- create and delete nodes,
- connect signals, attach scripts, set resources,
- save scenes,
- run and stop the project,
- fetch editor state and output.

This module should hide raw TCP payloads from higher-level code.

### 3. `RuntimeSession`

Responsibilities:

- connect to `godot-ai-playtest` after the game launches,
- probe runtime readiness,
- manage timeout, reconnect, and orderly teardown,
- expose runtime availability separately from editor availability.

This module answers one question: "Is the running game currently controllable?"

### 4. `RuntimeDriver`

Responsibilities:

- wrap `godot-ai-playtest` commands behind a local API,
- read runtime state snapshots,
- capture screenshots,
- start and fetch error capture,
- run minimal save/load checks,
- run performance assertions,
- call project-specific playtest hooks when needed.

Phase 1 should only require a minimal subset:

- `ping`
- `get_state`
- `screenshot`
- `start_error_capture`
- `get_captured_errors`
- `assert_performance`

Additional runtime commands can be added after the basic framework is stable.

### 5. `GuiDriver`

Responsibilities:

- find and activate the Godot editor window,
- capture editor window screenshots,
- send mouse and keyboard input,
- locate a small set of known UI anchors if semantic control is unavailable,
- classify and handle a small set of known editor dialogs.

This layer must remain deliberately small in phase 1.

### 6. `ActionRouter`

Responsibilities:

- receive high-level intents such as `open_scene`, `set_property`, `save_and_run`, or `dismiss_dialog`,
- route each intent to semantic control first,
- fall back to GUI control only when semantic control is unsupported or has failed,
- record the chosen path and why it was chosen.

The router is the boundary that keeps higher-level workflows independent of transport details.

### 7. `Verifier`

Responsibilities:

- validate action results before the next step proceeds,
- compare intended state versus observed state,
- assign a confidence level to the current automation state,
- stop workflows when state confidence drops below an acceptable threshold.

Verification should prefer:

1. explicit semantic responses,
2. semantic re-read of state,
3. runtime assertions,
4. screenshot or OCR checks only when needed.

### 8. `Recipes`

Responsibilities:

- define reusable workflows composed from the drivers above,
- express common development tasks without exposing raw TCP or GUI details,
- provide a stable entry point for future CLI commands or agent-driven automation.

Phase 1 should include one canonical recipe:

`open scene -> modify low-risk property -> save -> run -> wait for runtime -> screenshot -> stop`

## Control Flow

### Editor Edit Flow

1. Connect to the editor through `EditorSession`.
2. Query editor state.
3. Open the requested scene via `EditorSemanticDriver`.
4. Read the scene tree or target node state.
5. Apply modifications.
6. Re-read the modified state through the bridge.
7. Save the scene.

If any semantic step is unsupported or fails, the router may attempt GUI fallback only if the failure is a known editor-surface problem rather than a true data or logic error.

### Editor Run Flow

1. Run the main scene or a requested scene via the editor bridge.
2. Wait for runtime readiness through `RuntimeSession`.
3. Start runtime error capture.
4. Capture runtime state and screenshot.
5. Run runtime assertions.
6. Stop the running scene.

### GUI Fallback Flow

GUI fallback is allowed for:

- editor window activation,
- known menu navigation,
- known confirmation dialogs,
- known blocking error dialogs where semantic control is unavailable.

GUI fallback is not allowed to continue blindly after an unknown state. If fallback cannot prove the current editor state, the workflow must stop.

## State Model

The framework should track explicit state instead of only success or failure. The minimum shared state model should include:

- `editor_connected`
- `editor_window_active`
- `scene_open`
- `scene_path`
- `scene_dirty`
- `editor_playing`
- `runtime_connected`
- `modal_dialog_present`
- `last_error`
- `state_confidence`

`state_confidence` should be one of:

- `high`: semantic response and semantic re-read agree,
- `medium`: semantic response is incomplete but GUI evidence is consistent,
- `low`: state depends on ambiguous GUI or OCR inference,
- `unknown`: no trustworthy state could be established.

Workflows that may mutate project state should only continue when confidence is `high` or `medium`. Unknown state should halt the workflow.

## Dialog Strategy

Dialogs should be classified into three categories.

### 1. Safe confirmation dialogs

Examples:

- save modified scene,
- close-with-unsaved-changes,
- reload changed resources.

These can be handled by explicit workflow policy such as:

- save and continue,
- discard and continue,
- cancel and stop.

### 2. Blocking error dialogs

Examples:

- script compilation failure,
- missing resource,
- failed scene load.

These must:

- capture evidence,
- extract the visible message when practical,
- stop the workflow,
- report a structured failure.

### 3. Unknown dialogs

These must never be dismissed automatically in phase 1. The framework should capture a screenshot, record any extracted text, and stop.

## Runtime Testing Layer

`godot-ai-playtest` should become the standard runtime testing layer for new automation work.

Reasons:

- it is specifically built for external runtime control over TCP,
- it already models runtime concepts such as state snapshots, screenshots, performance assertions, error capture, and hook-based system extensions,
- it is better suited for repeatable playtesting and CI than the current narrow runtime bridge.

Phase 1 design decisions:

- editor automation remains in the existing `addons/mcp_bridge` bridge,
- runtime testing uses `godot-ai-playtest`,
- the existing `mcp_bridge_game.gd` is not removed immediately,
- new runtime automation should target `godot-ai-playtest` first,
- project-specific runtime hooks may be added as needed through the playtest hook model.

This avoids mixing editor control concerns into the runtime test server.

## Repository Layout

The expected phase 1 file layout is:

```text
tools/
  automation/
    README.md
    requirements.txt
    automation/
      __init__.py
      editor_session.py
      editor_semantic_driver.py
      runtime_session.py
      runtime_driver.py
      gui_driver.py
      action_router.py
      verifier.py
      models.py
      recipes/
        __init__.py
        open_edit_run_smoke.py
```

Optional future additions:

- `tests/playtest/` for runtime smoke scenarios or fixtures,
- lightweight project-specific playtest hook scripts if runtime state needs cleaner access than generic inspection provides.

The framework should remain external-first. It should not require major edits to the game's core autoloads or UI scripts just to function.

## Phase 1 Deliverables

Phase 1 is complete when all of the following exist:

1. A Python automation package under `tools/automation/`.
2. Stable connection and health checks for the editor bridge.
3. A typed wrapper for the editor bridge commands already present in `addons/mcp_bridge/plugin.gd`.
4. Stable connection and health checks for `godot-ai-playtest`.
5. A minimal runtime wrapper exposing the phase 1 runtime commands.
6. A minimal GUI fallback layer for:
   - editor window activation,
   - screenshot capture,
   - known dialog handling.
7. A single end-to-end smoke recipe that:
   - opens a scene,
   - changes a low-risk property,
   - saves,
   - runs the project,
   - connects to the runtime layer,
   - captures evidence,
   - stops the running scene.

## Verification

Phase 1 verification should prove the framework works end to end without claiming unsupported breadth.

Required verification:

1. Connect to the editor bridge successfully.
2. Open `res://scenes/Main.tscn` successfully.
3. Read scene tree data successfully.
4. Modify one low-risk property and re-read it successfully.
5. Save the scene successfully.
6. Run the project successfully.
7. Connect to the runtime playtest server successfully.
8. Capture one runtime state snapshot and one screenshot successfully.
9. Stop the running scene successfully.
10. Report failure cleanly when a known blocking dialog appears.

Project verification should continue to include the existing `run_tests.bat` suite so the automation framework does not regress the game's existing behavior.

## Risks and Mitigations

### 1. Existing worktree is dirty

Risk:

- project files are already modified, so automation changes must avoid colliding with unrelated work.

Mitigation:

- keep new code isolated under `tools/automation/`,
- avoid touching high-risk gameplay files unless a runtime hook is clearly necessary,
- add project hooks only as thin edge adapters.

### 2. Editor layout drift

Risk:

- GUI fallback becomes brittle if the editor dock layout changes significantly.

Mitigation:

- keep GUI fallback limited,
- prefer semantic control wherever possible,
- design fallback around window activation and dialogs rather than arbitrary panel editing.

### 3. Dual runtime bridges

Risk:

- `mcp_bridge_game.gd` and `godot-ai-playtest` can create overlapping responsibilities.

Mitigation:

- standardize new runtime automation on `godot-ai-playtest`,
- keep the existing bridge only as a temporary compatibility layer or for project-specific commands not yet migrated.

### 4. Unknown dialogs and script errors

Risk:

- the framework can corrupt state if it dismisses dialogs blindly.

Mitigation:

- default to evidence capture and stop on unknown dialogs,
- treat script compilation and resource-load dialogs as blocking errors.

### 5. Over-scoping phase 1

Risk:

- attempting full desktop automation in the first pass will delay a stable result.

Mitigation:

- keep phase 1 focused on semantic editing, runtime verification, and minimal GUI fallback,
- defer broad OCR and layout-generalized automation until the core workflow is stable.

## Final Decision

The approved implementation direction is:

- keep editor automation centered on the existing semantic editor bridge,
- add a minimal Windows GUI fallback layer only for editor-surface gaps,
- adopt `godot-ai-playtest` as the standardized runtime testing layer,
- expose all automation through a reusable external framework under `tools/automation/`,
- validate every step before continuing,
- ship phase 1 around one stable end-to-end smoke workflow before broadening coverage.
