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
"%GODOT_EXE%" --path "%~dp0."
endlocal
