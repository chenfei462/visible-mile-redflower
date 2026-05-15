@echo off
setlocal
godot_console --headless --path "%~dp0" --script res://tests/run_tests.gd --quit
endlocal
