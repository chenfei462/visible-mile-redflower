# Godot Automation Tools

Portable automation helpers for Godot projects. Copy `tools/automation` into a
Godot project, keep the editor bridge and `godot-ai-playtest` addons enabled in
that project, then run the recipe against the project you want to test.

## Install

```powershell
cd C:\Users\hacjr\Desktop\小红花社区\tools\automation
python -m pip install -r requirements.txt
```

## Run Unit Tests

```powershell
cd C:\Users\hacjr\Desktop\小红花社区
python -m pytest tools/automation/tests -q
```

## Run The Editor/Runtime Smoke Recipe

### Current Project

1. Start this project's editor:

```powershell
& 'C:\Users\hacjr\Desktop\小红花社区\open_editor.bat'
```

2. After the editor bridge is ready, run the recipe:

```powershell
cd C:\Users\hacjr\Desktop\小红花社区
python -m tools.automation.automation.recipes.open_edit_run_smoke --scene res://scenes/Main.tscn
```

### Another Godot Project

Copy this `tools/automation` folder into the other Godot project, or run it from
this repository while pointing `--project` at the other project:

```powershell
cd C:\Users\hacjr\Desktop\小红花社区
python -m tools.automation.automation.recipes.open_edit_run_smoke `
  --project "D:\Games\MyGodotGame" `
  --scene res://scenes/Main.tscn
```

The target project must contain:

- `project.godot`,
- an enabled editor bridge compatible with `addons/mcp_bridge`,
- an enabled runtime playtest server compatible with `addons/godot_ai_playtest`.

If the target project has `mcp_ports.cfg`, the recipe reads `[mcp] editor_port`
from that file. The runtime playtest server defaults to `localhost:9876`; override
it when needed:

```powershell
python -m tools.automation.automation.recipes.open_edit_run_smoke `
  --project "D:\Games\MyGodotGame" `
  --scene res://worlds/TestWorld.tscn `
  --editor-port 17600 `
  --runtime-port 19876
```

## Smoke Recipe Behavior

The smoke recipe intentionally creates a temporary `AutomationProbe` node inside
the target scene, sets a low-risk property on that temporary node, saves the
scene, runs the project, captures runtime evidence through `godot-ai-playtest`,
stops the project, deletes the temporary node, saves again, and restores the
original scene file bytes if needed.

Successful execution proves the following phase-1 integration points:

- the editor bridge accepts semantic commands on the configured editor port,
- `Main.tscn` can be opened and edited through automation,
- the editor can launch the project,
- the runtime playtest server accepts commands on the configured runtime port,
- runtime screenshots can be captured,
- the project can be stopped cleanly,
- the temporary probe node is not left behind in the scene.

## Last Verified

Portable CLI behavior verified on 2026-05-20 with:

```powershell
python -m pytest tools/automation/tests -q
python -m tools.automation.automation.recipes.open_edit_run_smoke --help
```

Results:

- Python automation tests: `41 passed`.
- CLI help lists `--project`, `--scene`, `--editor-port`, and `--runtime-port`.
