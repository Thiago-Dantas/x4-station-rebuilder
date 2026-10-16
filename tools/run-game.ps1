# Automated in-game test run (workflow-test-harness.md).
#   pwsh tools/run-game.ps1 [-Scenario b6] [-Save save_010] [-TimeoutMinutes 20]
# Scenarios are in extension_test/md/esr_test.xml (b6: script-made pier removal on save_010;
# replace: the user's CVL-296 replacement through the build menu on save_009, a copy of their quicksave;
# replace_build: the same, then the build is force-completed after the removal to see workers return;
# grace: remove a new station's habitat and sample the held workforce through the grace period;
# build: add a habitat to a new tutorial_station and let the builder finish it;
# b1: save the new station's own plan and load it back through the build menu;
# b1b: load that same layout with the two energy-cell modules swapped in sequence order;
# b1c: load that layout with the defence disc moved 1000 m up;
# b4: remove the S container storage from the build menu and watch the medical supplies;
# b6menu: remove the pier from the build menu with an L ship docked there and an M ship on the dock area;
# b6dock: remove the dock area from the build menu with an S ship in an internal bay;
# b2: remove the S container, one energy-cell module and the defence disc in one Confirm;
# b3: load plan player_1792192001, a copy of library plan tutorial_quantumtube).
# Links the test harness (extension_test\) and the mod into the profile, starts X4 through Steam
# (launch options in Steam: -skipintro -logfile debuglog.txt), waits for
# "[ESR-TEST] DONE" in debuglog.txt, lets the game quit (kills it after a grace period),
# unlinks the harness, copies the log to research\logs\ and prints our lines and script errors.
# Autosave is switched off in the profile's config.xml for the run (the test game must never overwrite the
# user's autosave_01..03) and the original config.xml is put back afterwards.
# save_010 needs Corporate Dynamics (ws_3772881250). The profile keeps it disabled. A writable
# enabled="true" is rewritten to false within seconds of launch, so the runner copies content.xml
# to content.xml.esr-run-backup, enables only that extension, and sets the file read-only.
# FOpenForWriting Error 13 is that read-only file. The backup is restored after the game exits,
# including when the run fails. A leftover backup is restored at the next run.
# Exit code 0 when the DONE line was seen.
param([string]$Scenario = 'b6', [string]$Save = 'save_010', [int]$TimeoutMinutes = 20)
$ErrorActionPreference = 'Stop'

$repo = Split-Path $PSScriptRoot -Parent
$profiles = Get-ChildItem "$env:USERPROFILE\Documents\Egosoft\X4" -Directory | Where-Object { $_.Name -match '^\d+$' }
if ($profiles.Count -ne 1) { throw "Expected one X4 profile folder, found $($profiles.Count)" }
$profileDir = $profiles[0].FullName
$log = Join-Path $profileDir 'debuglog.txt'
$harness = Join-Path $profileDir 'extensions\station_rebuilder_test'

if (Get-Process -Name X4 -ErrorAction SilentlyContinue) { throw 'X4 is already running; not starting a test run' }

$config = Join-Path $profileDir 'config.xml'
$configBackup = "$config.esr-run-backup"
if (Test-Path $configBackup) {
    # an earlier run was interrupted before it could restore the user's settings
    Copy-Item $configBackup $config -Force
    Remove-Item $configBackup
    'Restored config.xml left over from an interrupted run'
}

$content = Join-Path $profileDir 'content.xml'
$contentBackup = "$content.esr-run-backup"
if (Test-Path $contentBackup) {
    $contentItem = Get-Item $content
    if ($contentItem.IsReadOnly) { $contentItem.IsReadOnly = $false }
    Copy-Item $contentBackup $content -Force
    Remove-Item $contentBackup
    'Restored content.xml left over from an interrupted run'
}

function Read-Log {
    if (-not (Test-Path $log)) { return '' }
    # the game keeps the file open; share it
    $stream = [System.IO.File]::Open($log, 'Open', 'Read', 'ReadWrite')
    try { return (New-Object System.IO.StreamReader($stream)).ReadToEnd() } finally { $stream.Dispose() }
}

# tell the harness which save to load and which scenario to run
Set-Content -Path (Join-Path $repo 'extension_test\ui\esr_test_config.lua') -Value @(
    '-- Written by tools/run-game.ps1 before each run (-Save, -Scenario). This is the default.',
    "ESR_TEST = { save = `"$Save`", scenario = `"$Scenario`" }"
)
"Scenario $Scenario on $Save"

& (Join-Path $PSScriptRoot 'link-dev.ps1') | Out-Host
if (-not (Get-Item $harness -ErrorAction SilentlyContinue)) {
    New-Item -ItemType Junction -Path $harness -Target (Join-Path $repo 'extension_test') | Out-Null
}
"Harness linked: $harness"

$started = Get-Date
$done = $false
try {
    Copy-Item $config $configBackup
    (Get-Content $config -Raw) -replace '<autosave>true</autosave>', '<autosave>false</autosave>' | Set-Content $config -NoNewline
    'Autosave off for the run (config.xml backed up)'
    Copy-Item $content $contentBackup
    $utf8 = New-Object System.Text.UTF8Encoding $false
    $contentText = [System.IO.File]::ReadAllText($content)
    $cdOff = '<extension id="ws_3772881250" enabled="false"/>'
    $cdOn = '<extension id="ws_3772881250" enabled="true"/>'
    if ($contentText.Contains($cdOff)) {
        [System.IO.File]::WriteAllText($content, $contentText.Replace($cdOff, $cdOn), $utf8)
    } elseif (-not $contentText.Contains($cdOn)) {
        throw 'ws_3772881250 is not in the profile content.xml'
    }
    (Get-Item $content).IsReadOnly = $true
    'content.xml: Corporate Dynamics enabled and the file is read-only'
    # through Steam with no arguments of our own: arguments from outside make Steam ask the user first.
    # The game's Steam launch options must contain -skipintro -logfile debuglog.txt (docs/testing.md).
    Start-Process 'steam://rungameid/392160'
    "Started X4 at $started; waiting up to $TimeoutMinutes min for [ESR-TEST] DONE"
    $deadline = $started.AddMinutes($TimeoutMinutes)
    $seenProcess = $false
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 5
        $running = [bool](Get-Process -Name X4 -ErrorAction SilentlyContinue)
        if ($running) { $seenProcess = $true }
        if ((Test-Path $log) -and (Get-Item $log).LastWriteTime -gt $started -and (Read-Log).Contains('[ESR-TEST] DONE')) { $done = $true; break }
        if ($seenProcess -and -not $running) { 'X4 exited before DONE'; break }
    }
    if (-not $done -and (Get-Date) -ge $deadline) { 'Timed out' }
    # the harness quits the game after DONE; give it time, then make sure
    $quitBy = (Get-Date).AddSeconds(120)
    while ((Get-Process -Name X4 -ErrorAction SilentlyContinue) -and (Get-Date) -lt $quitBy) { Start-Sleep -Seconds 3 }
    if (Get-Process -Name X4 -ErrorAction SilentlyContinue) {
        'X4 still running; stopping it'
        Stop-Process -Name X4 -Force
        Wait-Process -Name X4 -Timeout 60 -ErrorAction SilentlyContinue
    }
}
finally {
    # the game writes config.xml when it exits, so restore only after it is gone
    if (-not (Get-Process -Name X4 -ErrorAction SilentlyContinue)) {
        if (Test-Path $configBackup) {
            Copy-Item $configBackup $config -Force
            Remove-Item $configBackup
            'config.xml restored (autosave as before)'
        }
        $contentItem = Get-Item $content -ErrorAction SilentlyContinue
        if ($contentItem -and $contentItem.IsReadOnly) { $contentItem.IsReadOnly = $false }
        if (Test-Path $contentBackup) {
            Copy-Item $contentBackup $content -Force
            Remove-Item $contentBackup
            'content.xml restored (Corporate Dynamics as before)'
        }
    } else {
        "X4 still running; config.xml and content.xml NOT restored yet (backups restored at the next run)"
    }
    $item = Get-Item $harness -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -eq 'Junction') { $item.Delete(); 'Harness unlinked' }
}

$logs = Join-Path $repo 'research\logs'
New-Item -ItemType Directory -Force $logs | Out-Null
$copy = Join-Path $logs ('run-' + $started.ToString('yyyyMMdd-HHmmss') + '.txt')
if (Test-Path $log) { Copy-Item $log $copy; "Log copied to $copy" }
"----- our lines and errors in our files -----"
Get-Content $copy -ErrorAction SilentlyContinue | Where-Object { $_ -match '\[ESR|station_rebuilder|esr_' }
if ($done) { exit 0 } else { exit 1 }
