param(
    [string]$Version = "",
    [switch]$SkipValidation
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$VersionPath = Join-Path $ScriptDir "version.json"
$ExePath = Join-Path $RepoRoot "build/windows/visible_one_kilometer_demo.exe"
$ValidationPath = Join-Path $RepoRoot "build/windows/export_validation.json"
$DistDir = Join-Path $RepoRoot "dist"
$StagingDir = Join-Path $DistDir "competition_zip_staging"

if (-not (Test-Path -LiteralPath $VersionPath)) {
    throw "Missing version source: $VersionPath"
}

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

$VersionInfo = (Read-Utf8 $VersionPath) | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = [string]$VersionInfo.version
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version must be numeric semver like 0.3.0; got '$Version'"
}

if (-not $SkipValidation) {
    & (Join-Path $ScriptDir "validate_export.ps1") -ExePath $ExePath
    if ($LASTEXITCODE -ne 0) {
        throw "Export validation failed with exit code $LASTEXITCODE"
    }
}

if (-not (Test-Path -LiteralPath $ExePath)) {
    throw "Cannot package missing executable: $ExePath"
}
if (-not (Test-Path -LiteralPath $ValidationPath)) {
    throw "Cannot package without export validation record: $ValidationPath"
}

$ValidationInfo = (Read-Utf8 $ValidationPath) | ConvertFrom-Json
if ([string]$ValidationInfo.version -ne $Version) {
    throw "Export validation version $($ValidationInfo.version) does not match package version $Version"
}
if (-not [bool]$ValidationInfo.launch_passed) {
    throw "Export validation did not pass launch verification; run validate_export.ps1 before packaging."
}

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
if (Test-Path -LiteralPath $StagingDir) {
    Remove-Item -LiteralPath $StagingDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $StagingDir | Out-Null

Copy-Item -LiteralPath $ExePath -Destination (Join-Path $StagingDir "visible_one_kilometer_demo.exe") -Force
Copy-Item -LiteralPath (Join-Path $RepoRoot "README.md") -Destination (Join-Path $StagingDir "README.md") -Force
Copy-Item -LiteralPath $VersionPath -Destination (Join-Path $StagingDir "version.json") -Force
Copy-Item -LiteralPath $ValidationPath -Destination (Join-Path $StagingDir "export_validation.json") -Force

$GitCommit = "not-a-git-repo"
$GitCommand = Get-Command git -ErrorAction SilentlyContinue
if ($null -ne $GitCommand -and (Test-Path -LiteralPath (Join-Path $RepoRoot ".git"))) {
    $CommitOutput = & git -C $RepoRoot rev-parse --short HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($CommitOutput)) {
        $GitCommit = [string]$CommitOutput
    }
}

$BuildInfo = [ordered]@{
    version = $Version
    build_channel = [string]$VersionInfo.build_channel
    display_name = [string]$VersionInfo.display_name
    built_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    git_commit = $GitCommit
    package_type = "competition_windows_zip"
}
Write-Utf8NoBom (Join-Path $StagingDir "build_info.json") ($BuildInfo | ConvertTo-Json -Depth 8)

$Checklist = @"
# Competition ZIP Release Checklist

- Version: $Version
- Export executable: visible_one_kilometer_demo.exe
- Export validation: launch_passed=$($ValidationInfo.launch_passed), exe_size_bytes=$($ValidationInfo.exe_size_bytes)
- Manual check: extract this ZIP in a clean folder and double-click visible_one_kilometer_demo.exe.
- SteamPipe: templates are provided separately; no real Steam upload is performed by this package script.
"@
Write-Utf8NoBom (Join-Path $StagingDir "release_checklist.md") $Checklist

$ZipPath = Join-Path $DistDir ("visible-one-kilometer-demo-v{0}.zip" -f $Version)
if (Test-Path -LiteralPath $ZipPath) {
    Remove-Item -LiteralPath $ZipPath -Force
}

Compress-Archive -Path (Join-Path $StagingDir "*") -DestinationPath $ZipPath -Force
Remove-Item -LiteralPath $StagingDir -Recurse -Force

Write-Host "Competition ZIP created: $ZipPath"
exit 0
