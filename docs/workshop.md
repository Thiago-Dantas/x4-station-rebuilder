# Steam Workshop page

Notes for the mod's Workshop page (release: roadmap Phase 8).

## Suggested pairings (user, 2026-10-15)
Mods to recommend next to ours on the Workshop page. Both make station building less tedious, and both need SirNukes Mod Support APIs, which we may depend on too (D-5).

| Mod | Workshop | Author | Installed here as | What it does (from its own description, version checked) |
|-----|----------|--------|-------------------|-------------------------------------------------------------|
| Build Storage: Station Drone Self-Supply | [3754773002](https://steamcommunity.com/sharedfiles/filedetails/?id=3754773002) | Simucad | `extensions/baulager_drone_supply` (id `ws_3754773002`) | The station's cargo drones supply its build storage from wares already stored on the station; optional "Drone-Only" toggle (right-click the station). Removable mid-game. (v102, 2026-06-30) |
| XBuilder | [3797254195](https://steamcommunity.com/sharedfiles/filedetails/?id=3797254195) | Lord Starwolf | `extensions/xbuilder` (id `ws_3797254195`) | Assign more construction vessels to a station under construction; they work the same plan in the same order and use the same materials, so it finishes faster. (v104, 2026-09-23, for X4 8.00 and 9.x) |

**Why they fit:** our mod keeps a rebuild from losing ships, wares and workers; Drone Self-Supply gets the refunded and stored wares into the build faster; XBuilder shortens the rebuild itself.

**Compatibility (to test in Phase 7):** both touch station builds. XBuilder adds builders to a running build and Drone Self-Supply moves wares into build storage, while our mod hooks plan changes, recycling and build storage. Test a rebuild with each of them installed before naming them on the page.
