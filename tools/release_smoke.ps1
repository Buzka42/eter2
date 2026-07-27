# Builds the release APK, installs it, launches it, and fails if it crashes.
#
# Minification only runs in release, so a missing R8 keep rule cannot fail a
# test, a debug build, or an analyzer run — it fails on a real device, on
# launch, after the artifact has already been handed over. That happened with
# WorkManager's Room database. Run this before sending any APK.
#
# Usage: pwsh tools/release_smoke.ps1 [-SkipBuild]

param(
    [switch]$SkipBuild,
    [int]$SettleSeconds = 35
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root 'app'
$apk = Join-Path $app 'build\app\outputs\flutter-apk\app-release.apk'
$package = 'com.eterhealth.eter'
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'

if (-not (Test-Path $adb)) { throw "adb not found at $adb" }

$devices = & $adb devices | Select-String -Pattern "\tdevice$"
if (-not $devices) { throw 'No device or emulator is attached.' }

if (-not $SkipBuild) {
    Write-Host 'Building release APK...'
    Push-Location $app
    try { & flutter build apk --release | Select-Object -Last 2 }
    finally { Pop-Location }
}
if (-not (Test-Path $apk)) { throw "No APK at $apk" }

Write-Host 'Installing...'
# adb prints several lines; join them so the match tests the whole output
# rather than filtering it line by line.
$install = (& $adb install -r $apk 2>&1) -join "`n"
if ($install -notmatch 'Success') { throw "Install failed: $install" }

Write-Host 'Launching...'
& $adb shell am force-stop $package | Out-Null
& $adb logcat -c
& $adb shell am start -n "$package/.MainActivity" | Out-Null
Start-Sleep -Seconds $SettleSeconds

# Two independent checks. A crash leaves a stack trace; a process that dies
# quietly, or never draws, leaves no resumed activity.
$crash = & $adb logcat -d -s AndroidRuntime:E 2>&1 |
    Select-String -Pattern 'FATAL EXCEPTION' -Context 0, 12
$resumed = & $adb shell dumpsys activity activities 2>&1 |
    Select-String -Pattern "topResumedActivity.*$package"

if ($crash) {
    Write-Host "`nRelease build crashed on launch:`n" -ForegroundColor Red
    $crash | ForEach-Object { $_.ToString() }
    exit 1
}
if (-not $resumed) {
    Write-Host "`n$package is not the resumed activity after launch." -ForegroundColor Red
    Write-Host 'It may have died silently. Check: adb logcat -d'
    exit 1
}

Write-Host "`nRelease build launched and is running." -ForegroundColor Green
$size = (Get-Item $apk).Length / 1MB
$hash = (Get-FileHash $apk -Algorithm SHA256).Hash
Write-Host ("APK {0:N1} MB  SHA-256 {1}" -f $size, $hash)
