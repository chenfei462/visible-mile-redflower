$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ProjectPath = Join-Path $RepoRoot "project.godot"
$AddonRoot = Join-Path $RepoRoot "addons\godot_doctor"
$PluginCfg = Join-Path $AddonRoot "plugin.cfg"
$Settings = Join-Path $AddonRoot "settings\godot_doctor_settings.tres"

function Assert-True {
    param(
        [bool] $Condition,
        [string] $Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Assert-True (Test-Path -LiteralPath $PluginCfg) "Godot Doctor plugin.cfg should exist."
Assert-True (Test-Path -LiteralPath $Settings) "Godot Doctor settings resource should exist."

$ProjectText = Get-Content -LiteralPath $ProjectPath -Raw -Encoding UTF8
$PluginText = Get-Content -LiteralPath $PluginCfg -Raw -Encoding UTF8
$SettingsText = Get-Content -LiteralPath $Settings -Raw -Encoding UTF8

Assert-True ($ProjectText.Contains('res://addons/godot_doctor/plugin.cfg')) "project.godot should enable Godot Doctor."
Assert-True ($PluginText.Contains('version="2.1.3"')) "Godot Doctor should be pinned to version 2.1.3."
Assert-True (-not (Test-Path -LiteralPath (Join-Path $AddonRoot "core\c_sharp"))) "C# wrapper files should be omitted for this GDScript project."
Assert-True (-not (Test-Path -LiteralPath (Join-Path $AddonRoot "examples\csharp"))) "C# examples should be omitted for this GDScript project."
Assert-True ($SettingsText.Contains("check_for_updates_on_startup = false")) "Godot Doctor update checks should be disabled by default."
Assert-True ($SettingsText.Contains("show_welcome_dialog = false")) "Godot Doctor welcome dialog should be disabled by default."
Assert-True ($SettingsText.Contains("show_toasts = false")) "Godot Doctor toast notifications should be disabled by default."

Write-Host "GODOT DOCTOR INTEGRATION SMOKE PASSED"
