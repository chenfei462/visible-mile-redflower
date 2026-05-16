@echo off
setlocal
set "GODOT_EXE_RESOLVED="
set "LOCAL_GODOT_FALLBACK=C:\Users\hacjr\Documents\Codex\2026-05-15\files-mentioned-by-the-user-c\godot-4.6.2\Godot_v4.6.2-stable_win64_console.exe"

if defined GODOT_CONSOLE_EXE (
  if exist "%GODOT_CONSOLE_EXE%" set "GODOT_EXE_RESOLVED=%GODOT_CONSOLE_EXE%"
)

if not defined GODOT_EXE_RESOLVED (
  for /f "delims=" %%G in ('where godot_console.exe 2^>nul') do (
    if not defined GODOT_EXE_RESOLVED set "GODOT_EXE_RESOLVED=%%G"
  )
)

if not defined GODOT_EXE_RESOLVED (
  for /f "delims=" %%G in ('where godot.exe 2^>nul') do (
    if not defined GODOT_EXE_RESOLVED set "GODOT_EXE_RESOLVED=%%G"
  )
)

if not defined GODOT_EXE_RESOLVED (
  if exist "%LOCAL_GODOT_FALLBACK%" set "GODOT_EXE_RESOLVED=%LOCAL_GODOT_FALLBACK%"
)

if not defined GODOT_EXE_RESOLVED (
  echo Godot console executable not found:
  echo - Set GODOT_CONSOLE_EXE to a Godot console executable, or
  echo - Add godot_console.exe or godot.exe to PATH.
  exit /b 1
)
"%GODOT_EXE_RESOLVED%" --headless --path "%~dp0." --script res://tests/run_tests.gd --quit
endlocal
