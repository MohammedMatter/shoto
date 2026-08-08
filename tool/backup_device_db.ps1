<#
.SYNOPSIS
  Pulls SHOTO's on-device database and preferences off an Android device
  before anything is installed over the app.

.DESCRIPTION
  Run this BEFORE `flutter install`, `flutter run`, or any adb install
  against a device that holds real data.

  This exists because of a real loss, not a hypothetical one. `flutter
  install` prints "Uninstalling old version..." and does exactly that — the
  uninstall takes /data/data/<pkg> with it, so the library, the folders and
  every preference are gone before the new APK is even copied across. The
  app's own backup feature does not help here: it writes to the cache
  directory and is only durable once the user has shared the file out.

  What is and is not at risk:

    * `shoto.db` — folders, what was kept and filed, favourites, intents.
      Private storage. Destroyed by an uninstall.
    * `shared_prefs` — onboarding state, theme, developer unlock, the funnel
      counters. Private storage. Destroyed by an uninstall.
    * The screenshots themselves — NOT at risk. SHOTO references gallery
      paths through photo_manager and only ever copies into the temporary
      directory, so the images live in the gallery and survive.

  Requires a debuggable (debug-signed) build, because it pulls through
  `run-as`. A release build on a non-rooted phone cannot be read this way —
  in that case there is no backup path, and installing over it is a decision
  to lose the data.

.EXAMPLE
  ./tool/backup_device_db.ps1
  ./tool/backup_device_db.ps1 -Serial b711239a
#>
[CmdletBinding()]
param(
    # Device serial from `adb devices`. Defaults to the only attached device.
    [string]$Serial,

    # Where to write the backup. Timestamped subfolder is created inside.
    [string]$OutRoot = "$PSScriptRoot/../.device-backups",

    [string]$Package = 'com.shoto.app'
)

$ErrorActionPreference = 'Stop'

function Adb {
    if ($Serial) { & adb -s $Serial @args } else { & adb @args }
}

# --- Pick a device -----------------------------------------------------------
$devices = @(adb devices | Select-Object -Skip 1 |
    Where-Object { $_ -match '\sdevice$' } |
    ForEach-Object { ($_ -split '\s+')[0] })

if ($devices.Count -eq 0) { throw 'No device attached. Plug the phone in and enable USB debugging.' }
if (-not $Serial) {
    if ($devices.Count -gt 1) {
        throw "More than one device attached ($($devices -join ', ')). Pass -Serial to choose."
    }
    $Serial = $devices[0]
}
Write-Host "Device: $Serial"

# --- Refuse early rather than produce an empty backup ------------------------
$flags = Adb shell "dumpsys package $Package | grep -m1 pkgFlags"
if (-not $flags) { throw "$Package is not installed on $Serial — nothing to back up." }
if ($flags -notmatch 'DEBUGGABLE') {
    throw "$Package on $Serial is NOT debuggable, so run-as cannot read its data. " +
          'There is no backup path for a release build on a non-rooted device. ' +
          'Installing over it will destroy the library.'
}

# --- Pull --------------------------------------------------------------------
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$dest = Join-Path $OutRoot "$Serial`_$stamp"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

# run-as cannot write outside the app sandbox and adb pull cannot read inside
# it, so the data is staged through a tar on stdout instead of a file anybody
# has to clean up afterwards.
Write-Host 'Pulling databases and shared_prefs...'
$staged = "/data/local/tmp/shoto-backup-$stamp.tar"
Adb shell "run-as $Package tar -cf - databases shared_prefs 2>/dev/null > $staged"
Adb pull $staged "$dest/data.tar" | Out-Null
Adb shell "rm -f $staged"

$tar = Get-Item "$dest/data.tar" -ErrorAction SilentlyContinue
if (-not $tar -or $tar.Length -lt 1024) {
    throw "Backup came back empty ($($tar.Length) bytes). Do NOT install over this device."
}

Write-Host ''
Write-Host "Backed up $([math]::Round($tar.Length/1KB)) KB to:" -ForegroundColor Green
Write-Host "  $dest/data.tar"
Write-Host ''
Write-Host 'Restore (same package, debuggable build) with:'
Write-Host "  adb -s $Serial push `"$dest/data.tar`" /data/local/tmp/restore.tar"
Write-Host "  adb -s $Serial shell `"run-as $Package tar -xf /data/local/tmp/restore.tar`""
Write-Host ''
Write-Host 'Safe to install now. Prefer `adb install -r` — `flutter install` uninstalls first.' -ForegroundColor Yellow
