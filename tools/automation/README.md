# Godot Automation Tools

## Install

```powershell
cd C:\Users\hacjr\Desktop\灏忕孩鑺辩ぞ鍖篭tools\automation
python -m pip install -r requirements.txt
```

## Run unit tests

```powershell
cd C:\Users\hacjr\Desktop\灏忕孩鑺辩ぞ鍖?python -m pytest tools/automation/tests -q
```

## Run the editor/runtime smoke recipe

Run the recipe with:

1. Start the editor with:

```powershell
& 'C:\Users\hacjr\Desktop\灏忕孩鑺辩ぞ鍖篭open_editor.bat'
```

2. Run the recipe:

```powershell
cd C:\Users\hacjr\Desktop\灏忕孩鑺辩ぞ鍖?python -m tools.automation.automation.recipes.open_edit_run_smoke --scene res://scenes/Main.tscn
```

## Smoke recipe behavior

The smoke recipe intentionally creates a temporary `AutomationProbe` node inside the target scene, sets a low-risk property on that temporary node, saves the scene, runs the project, captures runtime evidence, stops the project, deletes the temporary node, and saves the scene again so the repository returns to its original structure.
