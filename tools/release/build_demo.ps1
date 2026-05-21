param(
    [string]$Version = "",
    [switch]$SkipTests,
    [switch]$NoExport,
    [switch]$PreflightOnly
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$VersionPath = Join-Path $ScriptDir "version.json"
$PresetName = "Windows Demo"
$ExportExeRelative = "build/windows/visible_one_kilometer_demo.exe"
$ExportExePath = Join-Path $RepoRoot $ExportExeRelative

function Read-VersionInfo {
    if (-not (Test-Path -LiteralPath $VersionPath)) {
        throw "Missing version source: $VersionPath"
    }
    return (Read-Utf8 $VersionPath) | ConvertFrom-Json
}

function Save-VersionInfo {
    param($Info)
    Write-Utf8NoBom $VersionPath ($Info | ConvertTo-Json -Depth 8)
}

function Assert-Version {
    param([string]$Value)
    if ($Value -notmatch '^\d+\.\d+\.\d+$') {
        throw "Version must be numeric semver like 0.3.0; got '$Value'"
    }
}

function Write-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Text
    )
    $Encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Text, $Encoding)
}

function Read-Utf8 {
    param([string]$Path)
    $Encoding = [System.Text.UTF8Encoding]::new($false)
    return [System.IO.File]::ReadAllText($Path, $Encoding)
}

function Remove-MatchingLines {
    param(
        [string]$Text,
        [string]$Pattern
    )
    $Lines = $Text -split "\r?\n"
    $Kept = @($Lines | Where-Object { $_ -notmatch $Pattern })
    return ($Kept -join "`r`n").TrimEnd() + "`r`n"
}

function Insert-AfterLine {
    param(
        [string]$Text,
        [string]$AfterPattern,
        [string[]]$LinesToInsert
    )
    $Lines = [System.Collections.Generic.List[string]]::new()
    foreach ($Line in ($Text -split "\r?\n")) {
        $Lines.Add($Line)
        if ($Line -match $AfterPattern) {
            foreach ($InsertLine in $LinesToInsert) {
                $Lines.Add($InsertLine)
            }
        }
    }
    return ($Lines -join "`r`n").TrimEnd() + "`r`n"
}

function Sync-VersionFiles {
    param($Info)

    $ProjectPath = Join-Path $RepoRoot "project.godot"
    $PresetPath = Join-Path $RepoRoot "export_presets.cfg"
    if (-not (Test-Path -LiteralPath $ProjectPath)) { throw "Missing project.godot" }
    if (-not (Test-Path -LiteralPath $PresetPath)) { throw "Missing export_presets.cfg" }

    $VersionValue = [string]$Info.version
    $DisplayName = [string]$Info.display_name
    $Description = "Demo $VersionValue ($($Info.build_channel))"

    $ProjectText = Read-Utf8 $ProjectPath
    $ProjectText = Remove-MatchingLines $ProjectText '^config/name='
    $ProjectText = Remove-MatchingLines $ProjectText '^config/version='
    $ProjectText = Insert-AfterLine $ProjectText '^\[application\]' @(
        ('config/name="{0}"' -f $DisplayName)
    )
    $ProjectText = Insert-AfterLine $ProjectText '^config/icon=' @(('config/version="{0}"' -f $VersionValue))
    Write-Utf8NoBom $ProjectPath $ProjectText

    $PresetText = Read-Utf8 $PresetPath
    $PresetText = Remove-MatchingLines $PresetText '^application/file_version='
    $PresetText = Remove-MatchingLines $PresetText '^application/product_version='
    $PresetText = Remove-MatchingLines $PresetText '^application/product_name='
    $PresetText = Remove-MatchingLines $PresetText '^application/file_description='
    $PresetText = Insert-AfterLine $PresetText '^application/icon_interpolation=' @(
        ('application/file_version="{0}"' -f $VersionValue),
        ('application/product_version="{0}"' -f $VersionValue),
        ('application/product_name="{0}"' -f $DisplayName),
        ('application/file_description="{0}"' -f $Description)
    )
    Write-Utf8NoBom $PresetPath $PresetText
}

function Invoke-Checked {
    param(
        [string]$Label,
        [string[]]$CommandLine
    )
    Write-Host "==> $Label"
    & $CommandLine[0] @($CommandLine | Select-Object -Skip 1)
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE"
    }
}

function Run-RegressionTests {
    Invoke-Checked "Core tests" @("godot_console", "--headless", "--path", $RepoRoot, "--script", "res://tests/run_tests.gd", "--quit")
    Invoke-Checked "Full game smoke" @("godot_console", "--headless", "--path", $RepoRoot, "--script", "res://tests/full_game_smoke.gd", "--quit")
    Invoke-Checked "Animation smoke" @("godot_console", "--headless", "--path", $RepoRoot, "--script", "res://tests/animation_smoke.gd", "--quit")
    Invoke-Checked "Main scene headless boot" @("godot_console", "--headless", "--path", $RepoRoot, "--scene", "res://scenes/Main.tscn", "--quit-after", "5")
}

function Invoke-ReleasePreflight {
    $PreflightScript = Join-Path $ScriptDir "check_export_environment.ps1"
    $JsonOutput = & $PreflightScript -Json
    $PreflightExit = $LASTEXITCODE
    $Result = ($JsonOutput -join "`n") | ConvertFrom-Json
    if ($PreflightExit -ne 0 -or -not [bool]$Result.success) {
        Write-Host "Release preflight failed."
        Write-Host "Godot version: $($Result.godot_version)"
        Write-Host "Expected template directory: $($Result.template_dir)"
        if ($Result.missing_templates.Count -gt 0) {
            Write-Host "Missing templates:"
            foreach ($MissingTemplate in $Result.missing_templates) {
                Write-Host "  - $MissingTemplate"
            }
        }
        Write-Host $Result.install_hint
        throw "Release preflight failed; install Godot Windows export templates and retry."
    }
    return $Result
}

$VersionInfo = Read-VersionInfo

if ($PreflightOnly) {
    & (Join-Path $ScriptDir "check_export_environment.ps1")
    exit $LASTEXITCODE
}

if (-not [string]::IsNullOrWhiteSpace($Version)) {
    Assert-Version $Version
    $VersionInfo.version = $Version
    Save-VersionInfo $VersionInfo
}
Assert-Version ([string]$VersionInfo.version)
Sync-VersionFiles $VersionInfo

if (-not $SkipTests) {
    Run-RegressionTests
}

if ($NoExport) {
    Write-Host "NoExport requested; version files synced and export skipped."
    exit 0
}

$GodotCommand = Get-Command godot_console -ErrorAction SilentlyContinue
if ($null -eq $GodotCommand) {
    throw "godot_console was not found in PATH. Install Godot 4.6.2 or add it to PATH."
}
$Preflight = Invoke-ReleasePreflight

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ExportExePath) | Out-Null
if (Test-Path -LiteralPath $ExportExePath) {
    Remove-Item -LiteralPath $ExportExePath -Force
}

Invoke-Checked "Godot release export" @("godot_console", "--headless", "--path", $RepoRoot, "--export-release", $PresetName, $ExportExePath)
& (Join-Path $ScriptDir "validate_export.ps1") -ExePath $ExportExePath -GodotVersion ([string]$Preflight.godot_version) -TemplateVersion ([string]$Preflight.template_version) -TemplateDir ([string]$Preflight.template_dir)
if ($LASTEXITCODE -ne 0) {
    throw "Export validation failed with exit code $LASTEXITCODE"
}

& (Join-Path $ScriptDir "package_competition_zip.ps1") -Version ([string]$VersionInfo.version)
if ($LASTEXITCODE -ne 0) {
    throw "Competition ZIP packaging failed with exit code $LASTEXITCODE"
}

Write-Host "Demo build complete."
