# Easy Station Rebuild

A mod for **X4: Foundations** 9.00 or newer. Confirming a new construction plan deconstructs modules, and with them the game can destroy docked ships, drop stored wares, and dismiss the workforce. This mod stops those three losses on stations you own. It does not choose which modules come down. That is still the game's plan match.

The Steam Workshop page is the short description for players. This file is for installing from the repository and for reading how the protections work.

## Install from this repository

The mod is the `extension/` folder. Its id is `station_rebuilder`. Copy that folder to:

`Documents\Egosoft\X4\<your Steam id>\extensions\station_rebuilder`

For development, `pwsh tools/link-dev.ps1` junctions it into the same place. `pwsh tools/link-dev.ps1 -Remove` removes the junction.

No DLC is required. `extension/content.xml` depends on game version `900`.

[SirNukes Mod Support APIs](https://steamcommunity.com/sharedfiles/filedetails/?id=2042901274) is an optional dependency (`ws_2042901274`). With it, the settings appear in Extension Options. Without it, the values in `extension/md/esr_main.xml` are used and there is no menu.

A Workshop release turns the three protections on. This repository is the dev build: ships, cargo, and workforce start off, so a test can watch the game on its own. Turn them on in Extension Options when you want the mod to act.

## What the scripts do

Only player-owned stations. `ui/esr_confirm.lua` runs when the build menu confirms and sends the engine's removed-module list to the Mission Director scripts in `extension/md/`. `esr_main.xml` tracks the station's build and, every 30 seconds, runs the protections that are on. Log lines start with `[ESR]` in `debuglog.txt` when the general debug filter is being written.

**Ships** (`esr_ships`). A ship docked at a module that is going is ordered to a free spot near the station and parks there until it gets another order. A ship from another faction is told to undock. A ship with no pilot is moved at once. A ship still inside the station about ten seconds later is moved out. The ship the player is flying is not touched. Drones and mass traffic are skipped.

**Cargo** (`esr_cargo`). For each ware transport type, the amount that will not fit once the removed storage modules are gone is moved to that station's build storage. The check repeats during the build, so wares delivered later are moved too. When the build ends, `ReturnLeftovers` moves back what the station can hold. The rest stays in build storage. This mod does not cap build storage.

**Workforce** (`esr_workforce`). Workers above the new habitat capacity go into a held pool. They come back with `add_workforce` as soon as the new habitats have room. The pool waits for the grace period, then shrinks by the leave rate. Both are game time, so SETA shortens the wait on the clock. Defaults are 2 hours and 20% of the pool per hour.

**Module refunds.** The game already puts the full recipe of a removed module, and of the turrets and shields on it, into build storage. `esr_refund.xml` only logs that amount. It adds nothing. The dev options menu still shows a test toggle named "Refund equipment of removed modules (test)". A release build should not offer that toggle.

## Settings

Extension Options, category **Easy Station Rebuild**:

| Setting | Option id | Release default | Dev default |
|---|---|---|---|
| Protect docked ships | `esr_ships` | On | Off |
| Keep cargo of removed storage | `esr_cargo` | On | Off |
| Keep workforce during rebuilds | `esr_workforce` | On | Off |
| Workforce grace period | `esr_grace_hours` | 2 h (0–24, step 1) | 2 h |
| Workforce leave rate after the grace period | `esr_leave_rate` | 20 %/h (1–100) | 20 %/h |

## Limits

The engine matches old modules to the new plan. Reordering the build, or loading a plan that moves a module, can still deconstruct a module the new plan contains. Keeping those modules in place is not in this version.

Build time and build cost are unchanged. NPC stations are ignored.

`content.xml` sets `save="false"`, so the mod is left out of the save's patch list. Its Mission Director state is still stored while it is installed. Disable it under Extensions, or unsubscribe, to remove it. Let a rebuild finish first. Removing it during a rebuild has not been tested.

## Licence

MIT. Copyright (c) 2026 Thiago Almeida Dantas. See [LICENSE](LICENSE).

Source: <https://github.com/Thiago-Dantas/x4-station-rebuilder>
