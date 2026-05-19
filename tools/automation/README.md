# Godot Automation Tools

## Install

```powershell
cd C:\Users\hacjr\Desktop\小红花社区\tools\automation
python -m pip install -r requirements.txt
```

## Run unit tests

```powershell
cd C:\Users\hacjr\Desktop\小红花社区
python -m pytest tools/automation/tests -q
```

## Run the editor/runtime smoke recipe

1. Start the editor with:

```powershell
& 'C:\Users\hacjr\Desktop\小红花社区\open_editor.bat'
```

2. Run the recipe:

```powershell
cd C:\Users\hacjr\Desktop\小红花社区
python -m tools.automation.automation.recipes.open_edit_run_smoke --scene res://scenes/Main.tscn
```
