# Links the working copy into the game as a profile extension (dev install, D-2 / D-4).
#   pwsh tools/link-dev.ps1            create the junction
#   pwsh tools/link-dev.ps1 -Remove    remove it (only the link; the repo folder stays)
# The game loads extensions from <profile>\extensions\ as well as <game>\extensions\.
# A directory junction needs no admin rights. Restart the game after changing scripts.
param([switch]$Remove)

$profiles = Get-ChildItem "$env:USERPROFILE\Documents\Egosoft\X4" -Directory | Where-Object { $_.Name -match '^\d+$' }
if ($profiles.Count -ne 1) { throw "Expected one X4 profile folder, found $($profiles.Count): $($profiles.Name -join ', ')" }
$link = Join-Path $profiles[0].FullName 'extensions\station_rebuilder'
$target = Join-Path (Split-Path $PSScriptRoot -Parent) 'extension'

if ($Remove) {
    $item = Get-Item $link -ErrorAction SilentlyContinue
    if (-not $item) { "Nothing to remove: $link"; return }
    if ($item.LinkType -ne 'Junction') { throw "$link is not a junction; not touching it" }
    $item.Delete()  # removes the link only
    "Removed $link"
    return
}

$existing = Get-Item $link -ErrorAction SilentlyContinue
if ($existing) {
    if ($existing.LinkType -eq 'Junction' -and $existing.Target -contains $target) { "Already linked: $link -> $target"; return }
    throw "$link already exists and is not our junction; remove it by hand"
}
New-Item -ItemType Directory -Force (Split-Path $link -Parent) | Out-Null
New-Item -ItemType Junction -Path $link -Target $target | Out-Null
"Linked $link -> $target"
