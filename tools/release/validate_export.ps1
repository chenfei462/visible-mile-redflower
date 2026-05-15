param(
    [string]$ExePath = "",
    [switch]$SkipLaunch,
    [string]$GodotVersion = "",
    [string]$TemplateVersion = "",
    [string]$TemplateDir = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")

if ([string]::IsNullOrWhiteSpace($ExePath)) {
    $ExePath = Join-Path $RepoRoot "build/windows/visible_one_kilometer_demo.exe"
}
$ValidationPath = Join-Path (Split-Path -Parent $ExePath) "export_validation.json"

function Read-Utf8 {
    param([string]$Path)
    $Encoding = [System.Text.UTF8Encoding]::new($false)
    return [System.IO.File]::ReadAllText($Path, $Encoding)
}

function Write-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Text
    )
    $Encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Text, $Encoding)
}

function Write-ValidationRecord {
    param($Record)
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ValidationPath) | Out-Null
    Write-Utf8NoBom $ValidationPath ($Record | ConvertTo-Json -Depth 8)
}

$VersionPath = Join-Path $ScriptDir "version.json"
$VersionInfo = $null
if (Test-Path -LiteralPath $VersionPath) {
    $VersionInfo = (Read-Utf8 $VersionPath) | ConvertFrom-Json
}

if ([string]::IsNullOrWhiteSpace($GodotVersion)) {
    $VersionOutput = (& godot_console --version 2>$null)
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($VersionOutput)) {
        $GodotVersion = [string]$VersionOutput
    }
}
if ([string]::IsNullOrWhiteSpace($TemplateVersion) -and $GodotVersion -match '^(\d+\.\d+\.\d+\.stable)') {
    $TemplateVersion = $Matches[1]
}
if ([string]::IsNullOrWhiteSpace($TemplateDir) -and -not [string]::IsNullOrWhiteSpace($TemplateVersion)) {
    $TemplateDir = Join-Path $env:APPDATA ("Godot/export_templates/{0}" -f $TemplateVersion)
}

$ValidationVersion = ""
if ($null -ne $VersionInfo) {
    $ValidationVersion = [string]$VersionInfo.version
}

$Record = [ordered]@{
    version = $ValidationVersion
    godot_version = $GodotVersion
    template_version = $TemplateVersion
    template_dir = $TemplateDir
    exe_path = $ExePath
    exe_size_bytes = 0
    launch_passed = $false
    launch_exit_code = $null
    launch_timed_out = $false
    launch_skipped = [bool]$SkipLaunch
    launch_command = ""
    embedded_pck = $false
    validated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    errors = @()
}

if (-not (Test-Path -LiteralPath $ExePath)) {
    $Record.errors += "Exported executable not found: $ExePath"
    Write-ValidationRecord $Record
    throw "Exported executable not found: $ExePath"
}

$ExeItem = Get-Item -LiteralPath $ExePath
$Record.exe_size_bytes = $ExeItem.Length
if ($ExeItem.Length -le 0) {
    $Record.errors += "Exported executable is empty: $ExePath"
    Write-ValidationRecord $Record
    throw "Exported executable is empty: $ExePath"
}

$ReadmePath = Join-Path $RepoRoot "README.md"
if (-not (Test-Path -LiteralPath $ReadmePath)) {
    $Record.errors += "README.md is required for release packages"
    Write-ValidationRecord $Record
    throw "README.md is required for release packages"
}

if (-not (Test-Path -LiteralPath $VersionPath)) {
    $Record.errors += "tools/release/version.json is required for release validation"
    Write-ValidationRecord $Record
    throw "tools/release/version.json is required for release validation"
}

$PresetPath = Join-Path $RepoRoot "export_presets.cfg"
if (-not (Test-Path -LiteralPath $PresetPath)) {
    $Record.errors += "export_presets.cfg is required for release validation"
    Write-ValidationRecord $Record
    throw "export_presets.cfg is required for release validation"
}
$PresetText = Read-Utf8 $PresetPath
$Record.embedded_pck = $PresetText -match 'binary_format/embed_pck=true'
if (-not $Record.embedded_pck) {
    $PckPath = [System.IO.Path]::ChangeExtension($ExePath, ".pck")
    if (-not (Test-Path -LiteralPath $PckPath)) {
        $Record.errors += "Export preset does not embed pck and sidecar pck is missing: $PckPath"
        Write-ValidationRecord $Record
        throw "Export preset does not embed pck and sidecar pck is missing: $PckPath"
    }
}

if ($SkipLaunch) {
    Write-ValidationRecord $Record
    Write-Host "Export file checks passed; launch validation skipped."
    exit 0
}

$LaunchArgs = @("--headless", "--quit-after", "5")
$Record.launch_command = ('"{0}" {1}' -f $ExePath, ($LaunchArgs -join " "))
$Process = Start-Process -FilePath $ExePath -ArgumentList $LaunchArgs -WindowStyle Hidden -PassThru
if (-not $Process.WaitForExit(15000)) {
    $Process.Kill()
    $Record.launch_timed_out = $true
    $Record.errors += "Exported executable did not exit within 15 seconds"
    Write-ValidationRecord $Record
    throw "Exported executable did not exit within 15 seconds"
}

$Record.launch_exit_code = $Process.ExitCode
if ($Process.ExitCode -ne 0) {
    $Record.errors += "Exported executable exited with code $($Process.ExitCode)"
    Write-ValidationRecord $Record
    throw "Exported executable exited with code $($Process.ExitCode)"
}

$Record.launch_passed = $true
$Record.validated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
Write-ValidationRecord $Record

Write-Host "EXPORT VALIDATION PASSED"
exit 0
