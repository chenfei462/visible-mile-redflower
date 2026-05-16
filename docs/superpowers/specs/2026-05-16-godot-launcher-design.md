# Godot Launcher Script Design

## Goal

Make the project's Windows launcher scripts work on this machine by replacing the implicit `godot` and `godot_console` PATH dependency with the verified local Godot 4.6.2 executables.

## Scope

Files in scope:

- `start_game.bat`
- `open_editor.bat`
- `run_tests.bat`

Out of scope:

- Game logic, scene files, data files, or tests unrelated to launcher behavior
- Cross-machine portability
- Exporting a standalone `.exe`

## Current Problem

The three batch files assume `godot` and `godot_console` are available in PATH. On this machine they are not, so double-click launch fails even though a working local Godot installation exists.

## Approved Approach

Use fixed absolute executable paths for this machine:

- `C:\Users\hacjr\Documents\Codex\2026-05-15\files-mentioned-by-the-user-c\godot-4.6.2\Godot_v4.6.2-stable_win64.exe`
- `C:\Users\hacjr\Documents\Codex\2026-05-15\files-mentioned-by-the-user-c\godot-4.6.2\Godot_v4.6.2-stable_win64_console.exe`

Each batch file should:

1. Define the required executable path in a variable.
2. Check whether that file exists before launching.
3. Print a clear error and pause if the executable is missing.
4. Invoke Godot with the same project arguments already used today.

## Behavior

- `start_game.bat` launches the demo with the GUI executable.
- `open_editor.bat` launches the project in the Godot editor using `-e`.
- `run_tests.bat` runs the existing headless core test command with the console executable.

## Error Handling

If a required executable is missing, the script should:

- print the missing path,
- explain that the local Godot installation needs to be restored or the script updated,
- pause so the window does not close immediately,
- exit with a non-zero status.

## Verification

Verification should use the updated scripts themselves:

- run `run_tests.bat` and confirm the core suite passes,
- run `start_game.bat` and confirm a Godot process starts,
- optionally run `open_editor.bat` only if needed, since it opens the editor UI interactively.
