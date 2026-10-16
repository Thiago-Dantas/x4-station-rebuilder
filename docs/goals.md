# Goals

## Problem (user reports, 2026-10-15; reproduced, see the status below)
When the player edits a station's construction plan in game and confirms it:
1. **Modules get deleted.** Reordering the build order or replacing modules deconstructs them, even ones that end up the same.
2. **Materials disappear.** Sometimes they flow back to the build storage, but in tests with whole-station replacements most of them were gone.
3. **Workforce is lost** when habitats go away.
4. **Docked ships are destroyed** when the dock area or pier they sit at is deleted.

**Status of the reports (2026-10-15, verified; details in [x4-modding.md](x4-modding.md)):** in the user's full replacement through the build menu, every module was replaced (report 1, also for identical modules), **all station cargo was lost** (≈13 M wares; report 2), module recipes came back 100 % but gradually and went into the new build, **2 of 4 docked ships were destroyed** (report 4), all workforce was lost at once (report 3). A small script-made change (automated run 3) lost nothing but the workforce. Not a mod bug. Station equipment (turrets, shields on the module) is also refunded 100 % by vanilla (manual test 2026-10-16, D-17).

## Vision
Reorganizing or replacing a station costs time, not assets. The player can rebuild a station the way they want without losing ships, wares or people.

## Goals
| ID | Goal | Notes |
|----|------|-------|
| G1 | No ship is destroyed because its dock is removed | Ships are parked near the station, teleported if needed (D-7) |
| G2 | No materials are lost | Wares stored on the station are kept (also cargo in removed storage modules), and removed modules are refunded at 100% of their build cost, all into build storage (D-6) |
| G3 | No workforce is lost to a rebuild for a grace period | Workers above the new capacity wait 2 hours for habitats to come back, then start to leave (D-8) |
| G4 | Safe to add to and remove from an existing save | No broken saves, no stuck builds after uninstall |
| G5 | Published on the Steam Workshop as "Easier Station Rebuild" | English text first; repo public before release; MIT (D-10) |

## Stretch goal (agreed, D-9)
| ID | Goal | Notes |
|----|------|-------|
| S1 | Don't deconstruct modules that stay the same | Report 1 suggests the game rebuilds unchanged modules after a reorder. If the game's plan matching can be influenced from a script, the best loss prevention is not removing them at all. Feasibility is a research question (roadmap Phase 1). |

## Non-goals (for now)
- A station designer inside the game (that's what `x4-station-designer` and the vanilla build menu are for)
- Changing build speed or build costs
- NPC stations (only player-owned stations, unless research shows it's free)

## Constraints
- Game version 9.00 with all DLCs on the dev machine; the mod must also work without DLCs.
- Plain Mission Director (MD) and AI scripts first; widespread support mods such as SirNukes Mod Support APIs are fine when needed (D-5).
- Don't break saves: data the mod keeps lives in MD variables or blackboards that are harmless when the mod is gone.
