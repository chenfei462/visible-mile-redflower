# Godot Launcher Scripts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the project's Windows launcher scripts work on this machine without requiring `godot` or `godot_console` in PATH.

**Architecture:** Keep the existing batch-script entry points, but replace their implicit PATH dependency with explicit absolute paths to the verified local Godot GUI and console executables. Add a small existence check in each script so double-click failures turn into actionable error messages.

**Tech Stack:** Windows batch scripts, Godot 4.6.2 executables, Git for diff inspection.

---

### Task 1: Update launcher batch scripts

**Files:**
- Modify: `C:\Users\hacjr\Desktop\小红花社区\start_game.bat`
- Modify: `C:\Users\hacjr\Desktop\小红花社区\open_editor.bat`
- Modify: `C:\Users\hacjr\Desktop\小红花社区\run_tests.bat`

- [ ] **Step 1: Inspect the current scripts before editing**

Run:

```powershell
Get-Content -Path 'C:\Users\hacjr\Desktop\小红花社区\start_game.bat'
Get-Content -Path 'C:\Users\hacjr\Desktop\小红花社区\open_editor.bat'
Get-Content -Path 'C:\Users\hacjr\Desktop\小红花社区\run_tests.bat'
```

Expected: each file currently shells out to `godot` or `godot_console` by command name.

- [ ] **Step 2: Replace `start_game.bat` with a fixed GUI Godot path and a missing-file guard**

Target content:

```bat
@echo off
setlocal
set "GODOT_EXE=C:\Users\hacjr\Documents\Codex\2026-05-15\files-mentioned-by-the-user-c\godot-4.6.2\Godot_v4.6.2-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Godot executable not found:
  echo %GODOT_EXE%
  echo Restore the local Godot installation or update this script.
  pause
  exit /b 1
)
"%GODOT_EXE%" --path "%~dp0"
endlocal
```

- [ ] **Step 3: Replace `open_editor.bat` with a fixed GUI Godot path and a missing-file guard**

Target content:

```bat
@echo off
setlocal
set "GODOT_EXE=C:\Users\hacjr\Documents\Codex\2026-05-15\files-mentioned-by-the-user-c\godot-4.6.2\Godot_v4.6.2-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Godot executable not found:
  echo %GODOT_EXE%
  echo Restore the local Godot installation or update this script.
  pause
  exit /b 1
)
"%GODOT_EXE%" -e --path "%~dp0"
endlocal
```

- [ ] **Step 4: Replace `run_tests.bat` with a fixed console Godot path and a missing-file guard**

Target content:

```bat
@echo off
setlocal
set "GODOT_CONSOLE_EXE=C:\Users\hacjr\Documents\Codex\2026-05-15\files-mentioned-by-the-user-c\godot-4.6.2\Godot_v4.6.2-stable_win64_console.exe"
if not exist "%GODOT_CONSOLE_EXE%" (
  echo Godot console executable not found:
  echo %GODOT_CONSOLE_EXE%
  echo Restore the local Godot installation or update this script.
  pause
  exit /b 1
)
"%GODOT_CONSOLE_EXE%" --headless --path "%~dp0" --script res://tests/run_tests.gd --quit
endlocal
```

- [ ] **Step 5: Inspect the diff**

Run:

```powershell
git -C 'C:\Users\hacjr\Desktop\小红花社区' diff -- start_game.bat open_editor.bat run_tests.bat
```

Expected: only the three batch files change, and each change is limited to the fixed executable path plus the existence check.

### Task 2: Verify the updated scripts

**Files:**
- Test: `C:\Users\hacjr\Desktop\小红花社区\run_tests.bat`
- Test: `C:\Users\hacjr\Desktop\小红花社区\start_game.bat`

- [ ] **Step 1: Run the updated test script**

Run:

```powershell
& 'C:\Users\hacjr\Desktop\小红花社区\run_tests.bat'
```

Expected: exit code `0` and output containing `ALL TESTS PASSED`.

- [ ] **Step 2: Run the updated game launcher script**

Run:

```powershell
$p = Start-Process -FilePath 'C:\Users\hacjr\Desktop\小红花社区\start_game.bat' -PassThru
Start-Sleep -Seconds 2
Get-Process -Id $p.Id -ErrorAction SilentlyContinue
```

Expected: the batch wrapper exits quickly after spawning Godot, or a Godot child process remains running and the game window opens successfully.

- [ ] **Step 3: Confirm a Godot GUI process is active**

Run:

```powershell
Get-Process | Where-Object { $_.ProcessName -like 'Godot*' } | Select-Object Id, ProcessName
```

Expected: at least one Godot GUI process is listed after launching the game.
