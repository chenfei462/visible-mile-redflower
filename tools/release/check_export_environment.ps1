param(
    [switch]$Json
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$PresetName = "Windows Demo"
$ExportExeRelative = "build/windows/visible_one_kilometer_demo.exe"

function Read-Utf8 {
    param([string]$Path)
    $Encoding = [System.Text.UTF8Encoding]::new($false)
    return [System.IO.File]::ReadAllText($Path, $Encoding)
}

function Get-GodotTemplateVersion {
    param([string]$GodotVersion)
    if ($GodotVersion -match '^(\d+\.\d+\.\d+\.stable)') {
        return $Matches[1]
    }
    return ""
}

$PresetPath = Join-Path $RepoRoot "export_presets.cfg"
$BuildDir = Join-Path $RepoRoot "build/windows"
$InstallHint = "Install Godot export templates in the editor: Editor > Manage Export Templates > Download and Install, or Install from File. Then retry the release build."

$Result = [ordered]@{
    success = $false
    repo_root = [string]$RepoRoot
    preset_name = $PresetName
    export_path = $ExportExeRelative
    godot_command_found = $false
    godot_version = ""
    template_version = ""
    template_dir = ""
    required_templates = @()
    missing_templates = @()
    preset_found = $false
    build_dir_writable = $false
    install_hint = $InstallHint
    errors = @()
}

$GodotCommand = Get-Command godot_console -ErrorAction SilentlyContinue
if ($null -eq $GodotCommand) {
    $Result.errors += "godot_console was not found in PATH. Install Godot 4.6.2 or add it to PATH."
}
else {
    $Result.godot_command_found = $true
    $VersionOutput = (& godot_console --version 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($VersionOutput)) {
        $Result.errors += "Unable to read Godot version from godot_console."
    }
    else {
        $Result.godot_version = [string]$VersionOutput
        $Result.template_version = Get-GodotTemplateVersion $Result.godot_version
        if ([string]::IsNullOrWhiteSpace($Result.template_version)) {
            $Result.errors += "Unable to infer Godot export template version from '$($Result.godot_version)'."
        }
        else {
            $Result.template_dir = Join-Path $env:APPDATA ("Godot/export_templates/{0}" -f $Result.template_version)
            $Result.required_templates = @(
                (Join-Path $Result.template_dir "windows_debug_x86_64.exe"),
                (Join-Path $Result.template_dir "windows_release_x86_64.exe")
            )
            $Result.missing_templates = @($Result.required_templates | Where-Object { -not (Test-Path -LiteralPath $_) })
            if ($Result.missing_templates.Count -gt 0) {
                $Result.errors += "Missing Godot Windows export templates for $($Result.template_version): $($Result.missing_templates -join ', ')"
            }
        }
    }
}

if (-not (Test-Path -LiteralPath $PresetPath)) {
    $Result.errors += "Missing export_presets.cfg"
}
else {
    $PresetText = Read-Utf8 $PresetPath
    $Result.preset_found = $PresetText -match ('name="' + [regex]::Escape($PresetName) + '"')
    if (-not $Result.preset_found) {
        $Result.errors += "Missing export preset named '$PresetName'."
    }
    if ($PresetText -notmatch ('export_path="' + [regex]::Escape($ExportExeRelative) + '"')) {
        $Result.errors += "Export preset '$PresetName' should export to $ExportExeRelative."
    }
}

try {
    New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
    $ProbePath = Join-Path $BuildDir ".release_write_probe"
    Set-Content -LiteralPath $ProbePath -Value "ok" -Encoding ASCII
    Remove-Item -LiteralPath $ProbePath -Force
    $Result.build_dir_writable = $true
}
catch {
    $Result.errors += "Build directory is not writable: $BuildDir ($($_.Exception.Message))"
}

$Result.success = $Result.errors.Count -eq 0

if ($Json) {
    $Result | ConvertTo-Json -Depth 8
}
else {
    Write-Host "Release export environment"
    Write-Host "  Godot found: $($Result.godot_command_found)"
    Write-Host "  Godot version: $($Result.godot_version)"
    Write-Host "  Template version: $($Result.template_version)"
    Write-Host "  Template dir: $($Result.template_dir)"
    Write-Host "  Preset found: $($Result.preset_found)"
    Write-Host "  Build dir writable: $($Result.build_dir_writable)"
    if ($Result.missing_templates.Count -gt 0) {
        Write-Host "  Missing templates:"
        foreach ($MissingTemplate in $Result.missing_templates) {
            Write-Host "    - $MissingTemplate"
        }
    }
    if (-not $Result.success) {
        Write-Host ""
        Write-Host $InstallHint
        Write-Host ""
        foreach ($ErrorLine in $Result.errors) {
            Write-Host "ERROR: $ErrorLine"
        }
    }
    else {
        Write-Host "Release export environment is ready."
    }
}

if ($Result.success) {
    exit 0
}
exit 1
