$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ReleaseDir = Join-Path $RepoRoot "tools/release"
$Failures = New-Object System.Collections.Generic.List[string]

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) {
        $Failures.Add($Message)
    }
}

function Assert-File {
    param([string]$Path)
    Assert-True (Test-Path -LiteralPath $Path) "Missing file: $Path"
}

function Read-Utf8 {
    param([string]$Path)
    $Encoding = [System.Text.UTF8Encoding]::new($false)
    return [System.IO.File]::ReadAllText($Path, $Encoding)
}

$RequiredFiles = @(
    "version.json",
    "check_export_environment.ps1",
    "build_demo.ps1",
    "validate_export.ps1",
    "package_competition_zip.ps1",
    "steam_app_build.vdf.template",
    "steam_depot_windows.vdf.template",
    "README.md"
)

foreach ($FileName in $RequiredFiles) {
    Assert-File (Join-Path $ReleaseDir $FileName)
}

if ($Failures.Count -eq 0) {
    $VersionPath = Join-Path $ReleaseDir "version.json"
    $VersionInfo = (Read-Utf8 $VersionPath) | ConvertFrom-Json
    Assert-True ($VersionInfo.version -match '^\d+\.\d+\.\d+$') "version.json should expose semantic numeric version"
    Assert-True ([string]$VersionInfo.build_channel -eq "demo") "version.json build_channel should default to demo"
    Assert-True (-not [string]::IsNullOrWhiteSpace($VersionInfo.display_name)) "version.json should include display_name"
    Assert-True (-not ([string]$VersionInfo.display_name).Contains("?")) "version.json display_name should not contain replacement question marks"
    Assert-True (-not [string]::IsNullOrWhiteSpace($VersionInfo.notes)) "version.json should include notes"

    $ProjectBeforePreflight = Read-Utf8 (Join-Path $RepoRoot "project.godot")
    $PresetBeforePreflight = Read-Utf8 (Join-Path $RepoRoot "export_presets.cfg")
    & (Join-Path $ReleaseDir "build_demo.ps1") -PreflightOnly | Out-Host
    $ProjectAfterPreflight = Read-Utf8 (Join-Path $RepoRoot "project.godot")
    $PresetAfterPreflight = Read-Utf8 (Join-Path $RepoRoot "export_presets.cfg")
    Assert-True ($ProjectBeforePreflight -eq $ProjectAfterPreflight) "build_demo.ps1 -PreflightOnly should not modify project.godot"
    Assert-True ($PresetBeforePreflight -eq $PresetAfterPreflight) "build_demo.ps1 -PreflightOnly should not modify export_presets.cfg"

    & (Join-Path $ReleaseDir "build_demo.ps1") -Version $VersionInfo.version -SkipTests -NoExport | Out-Host
    if ($LASTEXITCODE -ne 0) {
        $Failures.Add("build_demo.ps1 -NoExport should exit 0")
    }

    $ProjectText = Read-Utf8 (Join-Path $RepoRoot "project.godot")
    $PresetText = Read-Utf8 (Join-Path $RepoRoot "export_presets.cfg")
    $ProjectBytes = [System.IO.File]::ReadAllBytes((Join-Path $RepoRoot "project.godot"))
    $PresetBytes = [System.IO.File]::ReadAllBytes((Join-Path $RepoRoot "export_presets.cfg"))
    Assert-True ($ProjectText -match ('config/version="' + [regex]::Escape($VersionInfo.version) + '"')) "project.godot should receive synced config/version"
    Assert-True ($ProjectText -match '(?m)^config/name="[^"]+"\r?$') "project.godot should contain a closed config/name string"
    Assert-True ($PresetText -match ('application/file_version="' + [regex]::Escape($VersionInfo.version) + '"')) "export preset should receive synced file_version"
    Assert-True ($PresetText -match ('application/product_version="' + [regex]::Escape($VersionInfo.version) + '"')) "export preset should receive synced product_version"
    Assert-True (-not ($ProjectBytes.Length -ge 3 -and $ProjectBytes[0] -eq 0xEF -and $ProjectBytes[1] -eq 0xBB -and $ProjectBytes[2] -eq 0xBF)) "project.godot should be written as UTF-8 without BOM"
    Assert-True (-not ($PresetBytes.Length -ge 3 -and $PresetBytes[0] -eq 0xEF -and $PresetBytes[1] -eq 0xBB -and $PresetBytes[2] -eq 0xBF)) "export_presets.cfg should be written as UTF-8 without BOM"
    Assert-True (([regex]::Matches($ProjectText, '(?m)^config/version=')).Count -eq 1) "project.godot should contain exactly one config/version"
    Assert-True (([regex]::Matches($PresetText, '(?m)^application/file_version=')).Count -eq 1) "export preset should contain exactly one file_version"
    Assert-True (([regex]::Matches($PresetText, '(?m)^application/product_version=')).Count -eq 1) "export preset should contain exactly one product_version"
    Assert-True (([regex]::Matches($PresetText, '(?m)^application/product_name=')).Count -eq 1) "export preset should contain exactly one product_name"
    Assert-True (([regex]::Matches($PresetText, '(?m)^application/file_description=')).Count -eq 1) "export preset should contain exactly one file_description"

    $WindowsBuildDir = Join-Path $RepoRoot "build/windows"
    New-Item -ItemType Directory -Force -Path $WindowsBuildDir | Out-Null
    $ExePath = Join-Path $WindowsBuildDir "visible_one_kilometer_demo.exe"
    Set-Content -LiteralPath $ExePath -Value "placeholder exe for release script smoke" -Encoding UTF8
    $ExeItem = Get-Item -LiteralPath $ExePath
    $ValidationPath = Join-Path $WindowsBuildDir "export_validation.json"
    $ValidationInfo = [ordered]@{
        version = [string]$VersionInfo.version
        godot_version = "release-script-smoke"
        template_version = "4.6.2.stable"
        template_dir = "release-script-smoke"
        exe_path = $ExePath
        exe_size_bytes = $ExeItem.Length
        launch_passed = $true
        launch_exit_code = 0
        launch_timed_out = $false
        launch_skipped = $false
        launch_command = "release-script-smoke"
        embedded_pck = $true
        validated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        errors = @()
    }
    $Encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($ValidationPath, ($ValidationInfo | ConvertTo-Json -Depth 8), $Encoding)

    & (Join-Path $ReleaseDir "package_competition_zip.ps1") -Version $VersionInfo.version -SkipValidation | Out-Host
    if ($LASTEXITCODE -ne 0) {
        $Failures.Add("package_competition_zip.ps1 should exit 0 with a present exe")
    }

    $ZipPath = Join-Path $RepoRoot ("dist/visible-one-kilometer-demo-v{0}.zip" -f $VersionInfo.version)
    Assert-File $ZipPath
    if (Test-Path -LiteralPath $ZipPath) {
        $Archive = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
        try {
            $EntryNames = @($Archive.Entries | ForEach-Object { $_.FullName })
            Assert-True ($EntryNames -contains "visible_one_kilometer_demo.exe") "competition ZIP should include the Windows exe"
            Assert-True ($EntryNames -contains "README.md") "competition ZIP should include README.md"
            Assert-True ($EntryNames -contains "version.json") "competition ZIP should include version.json"
            Assert-True ($EntryNames -contains "build_info.json") "competition ZIP should include build_info.json"
            Assert-True ($EntryNames -contains "export_validation.json") "competition ZIP should include export_validation.json"
            Assert-True ($EntryNames -contains "release_checklist.md") "competition ZIP should include release_checklist.md"
        }
        finally {
            $Archive.Dispose()
        }
    }
    if (Test-Path -LiteralPath $ExePath) {
        Remove-Item -LiteralPath $ExePath -Force
    }
    if (Test-Path -LiteralPath $ValidationPath) {
        Remove-Item -LiteralPath $ValidationPath -Force
    }
    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }

    $SteamTemplateText = Get-Content -LiteralPath (Join-Path $ReleaseDir "steam_app_build.vdf.template") -Raw
    Assert-True ($SteamTemplateText -match '<STEAM_APP_ID>') "Steam app template should keep AppID as a placeholder"
    Assert-True ($SteamTemplateText -notmatch '(?i)password|passwd|login\s+"[^<]') "Steam templates must not contain credentials"
}

if ($Failures.Count -gt 0) {
    foreach ($Failure in $Failures) {
        Write-Error $Failure
    }
    exit 1
}

Write-Host "RELEASE SCRIPTS SMOKE PASSED"
exit 0
