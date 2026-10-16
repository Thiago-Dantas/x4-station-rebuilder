# Easy Station Rebuild

A mod for **X4: Foundations**. Confirming a new construction plan on a station you own keeps the ships at its docks, the wares in its storage, and the workforce that would otherwise leave with the habitats.

The game still takes the removed modules apart and builds the new plan. What changes is the loss that used to come with that.

## Install

Subscribe on the Steam Workshop, then start the game. The extension is named Easy Station Rebuild.

To install a downloaded copy, put the folder `station_rebuilder` here:

`Documents\Egosoft\X4\<your Steam id>\extensions\`

Requires X4: Foundations 9.00 or newer. No DLC is required.

[SirNukes Mod Support APIs](https://steamcommunity.com/sharedfiles/filedetails/?id=2042901274) is optional. With it, the settings appear in Extension Options. Without it, the mod still runs on the defaults below.

On a Workshop install the three protections start on. The development copy in this repository starts with them off.

## What happens when you confirm a plan

Only stations you own are affected.

**Ships.** A ship docked at a pier or dock the new plan removes is sent to a spot near the station. Your ships park there until you give them an order. Other ships are told to undock. A ship with no pilot, or one that is still inside the station about ten seconds later, is moved out. The ship you are flying stays put. Drones are left to the game.

**Wares.** Wares that no longer fit, because a storage module is being removed, are moved to that station's build storage. When the build ends, wares the new station can hold are moved back into the station. The rest stays in build storage. Removed modules, and the turrets and shields mounted on them, are refunded in full by the game, into the same build storage.

**Workforce.** Workers who no longer have a habitat are kept for 2 hours of game time. As new habitats are built, they come back, up to the new capacity. After the 2 hours, workers still waiting leave at 20% of that remaining group per hour. Time warp (SETA) speeds game time up, so the wait is shorter on the clock while it is on.

## Settings

In Extension Options, category **Easy Station Rebuild**:

| Setting | Release default |
|---|---|
| Protect docked ships | On |
| Keep cargo of removed storage | On |
| Keep workforce during rebuilds | On |
| Workforce grace period | 2 h (0–24, steps of 1 h) |
| Workforce leave rate after the grace period | 20 %/h (1–100) |

## Limits

A module the new plan still contains can still be taken apart and built again. Reordering the build, or loading the same plan with a module moved, can do that. This version does not stop it.

Build time and build cost stay as the game set them.

To remove the mod, disable it under Extensions, or unsubscribe. It does not edit the game's own files. Let a rebuild finish before you remove it. Removing it in the middle of a rebuild has not been tested.

## Licence

MIT. Copyright (c) 2026 Thiago Almeida Dantas. See [LICENSE](LICENSE).

Source: <https://github.com/Thiago-Dantas/x4-station-rebuilder>
