# Workflow: Phase 1 research: what the game does when a plan changes

Status: **in progress** (started 2026-10-15). Part A done; part B needs the user in game.

Goal: answer the Phase 1 questions in [roadmap.md](roadmap.md) with evidence (game files, logs, in-game tests), and find out whether S1 (keep unchanged modules, D-9) is doable. Findings go to [docs/x4-modding.md](../docs/x4-modding.md).

## A. Game files (no game needed)
- [x] Extract the files into `research/extracted/base/` (525 files from `08.cat`: `md/`, `aiscripts/`, `ui/addons/ego_*/*.lua`, `libraries/*.xsd`, `scriptproperties.xml`, `parameters.xml`, `wares.xml`; 0 MD5 mismatches)
- [x] Build menu Lua: the engine lists removed modules (`GetRemovedConstructionPlanModules2`) and their vanilla refund (`GetModuleRecycledResources`) before confirm; confirm is one call (`SetConstructionSequenceFromConstructionMap`)
- [x] MD/AI scripts: `build.buildstorage.xml` processes builds on `event_build_added`; it moves station cargo to build storage (`add_cargo`) only when the whole station is dismantled; removed modules are recycled by the builder over time
- [x] S1: the engine does the matching; no API binds plan entries to existing modules; hypothesis that a loaded plan matches nothing (B1 decides)
- [x] Schema and script properties: build, build processor (`recycled`, `iswaitingforstorage`), `recyclingwares`, workforce per race, `dockingbay.docked`, `undock`, `request_undocking`, `warp` with `safepos`
- [x] Lua: native `ui.xml` addons can wrap build-menu functions (no other mod needed); Lua ↔ MD via `AddUITriggeredEvent` / `raise_lua_event`
- [x] SirNukes Mod Support APIs: Simple Menu API puts options (buttons, sliders) in Extension Options, registered from MD; fits D-12's settings
- [x] Prior-art mods: `recycleshipsandstations`, `baulager_more_docks`, `workforce_plus_player` don't touch plan changes
- [x] Findings written into docs/x4-modding.md

### Open after part A
- [x] The vanilla rate at which workers leave when capacity drops isn't in the files (D-12 depends on it) → B5. Measured in run 3: instant.
- Whether build storage really has no limit for recycled wares (`iswaitingforstorage`, D-11) → B3
- How long between confirm and a module disappearing, and how a docked ship dies → B6
- [x] Why materials vanish: station modules and mounted turrets/shields come back at 100 % (manual test 2026-10-16, D-17). Stored cargo is a separate loss (B4).

## B. In-game measurements (needs the user)
**Proposal (waiting for the user):** build a small diagnostic extension first (Phase 2's skeleton plus a logger). On every plan change of a player station it writes to `debuglog.txt`: the removed modules with `recyclingwares.max`, build storage and station cargo, workforce per race and capacity, docked ships per removed dock; then the same at each `event_build_finished_components` and at the end, plus every `event_object_destroyed` of a ship. The user only plays the steps below and sends the log. Without it, the user has to write the numbers down from the menus.

Setup: a test save (backed up), a player station with a builder assigned, some wares in storage, habitats with workers, a dock area or pier with a few of the player's ships docked.

- [ ] **B1 Matching (S1).** (a) Open the station's build menu, save its plan as a new plan, then load that same plan onto the station. Does the plan view list "Removed Modules"? (b) Same with the plan's build order changed (from `x4-station-designer` or by removing and re-adding a module in game). (c) In the editor, move one built module. What shows as removed?
- [x] **B2 Replace a few modules.** Run 26 (scenario `b2`, log `research/logs/run-20261016-125659.txt`): one Confirm removed the S container, one energy-cell module and the defence disc. Cargo (200 medical supplies) was gone within 3 s and did not reach build storage. Each recipe arrived in build storage when that module finished deconstruction. The total was 449 claytronics, 897 energy cells and 1641 hull parts. `iswaitingforstorage` stayed 0. No module was added.
- [ ] **B3 Full replacement.** Same as B2 for the whole station. Also: does the build ever stall on "waiting for storage"?
- [x] **B4 Storage modules with cargo removed.** Run 23 (scenario `b4`, build menu, log `research/logs/run-20261016-114357.txt`): the cargo is gone within 3 s of Confirm and does not arrive in build storage. The module recipe is refunded when the module finishes deconstruction. The station had no other container storage.
- [x] **B5 Habitats removed.** Run 3 (script path, log `research/logs/run-20261015-202817.txt`): removing the only habitat took the workforce from 250/250 to 0 at once. The vanilla leave rate is instant. The mod's grace period and leave rate are run 15.
- [x] **B6 pier with a docked ship removed.** Run 3 (script path) and run 24 (build menu, log `research/logs/run-20261016-115545.txt`): the L ship is undocked in the confirm frame, is outside the station within 3 s, and still exists after the pier disappears about 72 s later. Run 25 (scenario `b6dock`, log `research/logs/run-20261016-123728.txt`): removing the dock area left an S ship in an internal bay and an M ship on an external pad inside the station, and destroyed both (`contextkilled`) when the dock finished deconstruction. The 427-module replacement killed ships that were still inside the station (runs 6 and 7).

## C. Decisions
- [x] OD-1 … OD-7 decided by the user before research started (D-4 … D-10)
- [x] OD-8, OD-9 decided by the user (D-11, D-12)
- [ ] S1: doable or not; if yes, write the Phase 6 steps
- [ ] D-12 if vanilla drops workers at once (no "game rate" to follow)

## Sub-agents
None.
