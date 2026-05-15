# Release Tools

This directory contains the local release pipeline for the Windows competition Demo.

## First-Time Export Template Setup

The Windows export needs Godot export templates that match the local editor version.

Check the release environment first:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\release\build_demo.ps1 -PreflightOnly
```

If the preflight reports missing `windows_debug_x86_64.exe` or `windows_release_x86_64.exe`, install templates in Godot:

```text
Editor > Manage Export Templates > Download and Install
```

You can also use `Install from File` if you already have the official template package. For the current local Godot build, the expected folder is:

```text
%APPDATA%\Godot\export_templates\4.6.2.stable\
```

Missing export templates are an environment setup issue, not a project code failure.

## Build the Demo

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\release\build_demo.ps1
```

The build script:

- reads `tools/release/version.json`
- syncs the version into `project.godot` and `export_presets.cfg`
- runs the Godot regression smoke checks
- checks Godot Windows export templates
- exports the `Windows Demo` preset
- validates the exported executable and writes `build/windows/export_validation.json`
- creates `dist/visible-one-kilometer-demo-vX.Y.Z.zip`

Useful local options:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\release\build_demo.ps1 -Version 0.3.1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\release\build_demo.ps1 -SkipTests
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\release\build_demo.ps1 -SkipTests -NoExport
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\release\build_demo.ps1 -PreflightOnly
```

`-NoExport` is for fast release-script checks. It syncs version metadata and exits before invoking Godot export. `-PreflightOnly` only checks the export environment and does not sync files or export.

## Validate and Package Separately

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\release\validate_export.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\release\package_competition_zip.ps1
```

`package_competition_zip.ps1` expects:

- `build/windows/visible_one_kilometer_demo.exe`
- `build/windows/export_validation.json` with matching version and `launch_passed=true`

The competition ZIP includes:

- `visible_one_kilometer_demo.exe`
- `README.md`
- `version.json`
- `build_info.json`
- `export_validation.json`
- `release_checklist.md`

Final manual acceptance: extract the ZIP into a clean folder and double-click `visible_one_kilometer_demo.exe`.

## SteamPipe Template

The VDF files here are templates only. Do not commit real Steam credentials, AppID, DepotID, or branch secrets.

Before a real Steam upload, copy the templates outside the repo or into a private ignored location, replace:

- `<STEAM_APP_ID>`
- `<STEAM_WINDOWS_DEPOT_ID>`
- `<STEAM_BUILD_OUTPUT_DIR>`
- `<ABSOLUTE_CONTENT_ROOT>`
- `<BRANCH_NAME_OR_EMPTY>`

Then run SteamCMD manually from that private location.
