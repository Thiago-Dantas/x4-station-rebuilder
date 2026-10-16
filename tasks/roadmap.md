# Roadmap

Master list of milestones. Each active workstream gets its own `tasks/workflow-<topic>.md` with step-by-step state, linked from here. Goals (G1–G5, S1) are in [docs/goals.md](../docs/goals.md), decisions (D-n) and open questions (OD-n) in [docs/decisions.md](../docs/decisions.md).

Phase order after Phase 2 is a proposal: ships first because a destroyed ship can't be undone, then materials, then workforce. S1 comes last of the features because it depends most on what Phase 1 finds.

## Phase 0: Project setup
Log: [workflow-project-setup.md](workflow-project-setup.md)
- [x] CLAUDE.md, docs/, tasks/ skeleton
- [x] Repo-local `user.email`
- [x] User review of the roadmap; OD-1 … OD-7 decided (D-4 … D-10), `LICENSE` (MIT)
- [x] First commit and push (when the user asks)

## Phase 1: Research: what the game does when a plan changes
Log: [workflow-phase1-research.md](workflow-phase1-research.md)

Questions to answer before writing the mod (part A, game files, done 2026-10-15; part B, in game, waiting):
- [x] Reproduce the four losses in a test save and measure them (B2–B6). Station modules and their mounted equipment are refunded in full by vanilla (manual test 2026-10-16, D-17). That refund is not a gap for the mod.
- [ ] How the game matches the old station to the new plan, and can a script influence it (S1, D-9). The engine matches; no script binds an entry to a module. B1(a) is verified (run 19): an identical plan keeps every module and the plan file has no component ids. B1(b) is measured (run 21): a build-order swap, positions unchanged, left the menu at removed 0 and every module operational for 3 minutes; a price-0 build stayed queued and never went in progress. B1(c) is measured (run 22): loading a plan with the defence disc 1000 m higher removed only that disc, and one module entered construction within 3 seconds. Whether S1 is doable is still open. Deferred by the user 2026-10-16.
- [x] The vanilla refund rule for removed modules: 100 % of the module recipe plus mounted turrets/shields (`GetModuleRecycledResources`; delivered to build storage). Manual test 2026-10-16, D-17.
- [x] Build storage: MD adds wares with `add_cargo` (vanilla does it). The no-limit statement (D-11) vs `iswaitingforstorage`: a three-module recycle (run 26) and a full replacement (run 27, 12 min, refunds plus three new modules) both left the flag at 0. Neither run filled build storage.
- [x] Cargo in a removed storage module is not moved to build storage (run 23, scenario `b4`). 200 medical supplies were on the station at Confirm and gone 3 s later, while the module was still under construction. Build storage later received only the module recipe (52 claytronics, 103 energy cells, 189 hull parts). The station had no other container storage.
- [x] The first moment a script can act: before confirm, from a Lua wrap of the build menu's confirm (the engine's removed-module list is available); after confirm, `event_build_added` on the build storage, while the builder recycles modules over time
- [x] Docked ships: `dockingbay.docked`, `undock`, `request_undocking`, `warp` with `safepos` exist. A single pier removal undocks the ship in the confirm frame and it survives (run 3 script path, run 24 build menu). Removing the dock area kills ships that are still inside when the module finishes deconstruction, including an S ship in an internal bay and an M ship on an external pad (run 25, `contextkilled`). The same death happened in the 427-module replacement (runs 6 and 7).
- [x] Workforce: per-race amount/capacity and `add_workforce`/`remove_workforce` exist; `add_workforce` can't exceed capacity, so the grace period needs a mod-side store. The vanilla leave rate is instant (run 3, script path: the only habitat removed, 250/250 became 0 at once). The mod's own grace and leave rate are run 15.
- [x] Prior-art mods: none touch plan changes
- [x] OD-8, OD-9 decided by the user (D-11, D-12)
- [ ] Decide whether S1 is doable. Deferred by the user 2026-10-16.

## Phase 2: Mod skeleton and dev loop
Log: [workflow-diag-logger.md](workflow-diag-logger.md) (the skeleton is the diagnostic logger)
- [x] Repo subfolder `extension/` (D-13)
- [x] Extension (`content.xml` id `station_rebuilder`, "Easier Station Rebuild"), MD and Lua logger, linked into `<profile>\extensions\` through a junction (`tools/link-dev.ps1`)
- [x] Offline checks (`tools/check.py`): schemas, references, property names, Lua syntax
- [x] Logging to `debuglog.txt` (format checked in the existing log), `tools/esr_log.py`
- [x] Detect a plan change on a player station and log the modules that will be removed (Lua: engine list at Confirm; MD: plan entries vs existing modules)
- [ ] **In game (user):** the mod loads without script errors; whether a save reload picks up script edits or a restart is needed
- [ ] Test save(s) with a station set up for each loss (user), backed up

## Phase 3: Docked ships (G1, D-7)
First version written 2026-10-15; **verified in game** (automated run 8, full replacement: 0 of 2 ships lost; run 28, scenario `b6dock`, ship protection only: the internal-bay S freighter and the external-pad M freighter both still existed after the dock was gone): [workflow-protections-v1.md](workflow-protections-v1.md) (`esr_ships.xml`).
- [ ] Find ships docked at modules about to be removed
- [ ] Undock them and park them near the station; teleport the ones that can't get out in time
- [ ] Handle ships that can't undock (no pilot, busy, being built or repaired at that dock)
- [ ] In-game test: replace a pier and a dock area with ships docked; nothing destroyed

## Phase 4: Materials (G2, D-6)
Cargo **verified in game** (runs 6–8: 14.46 M wares kept; run 29, scenario `b4`, cargo protection only: 200 medical supplies moved to build storage in the confirm frame and were still there after the only container was gone). A real (not force-completed) habitat build is **verified** (run 18): the builder consumed the module recipe from build storage, and `ReturnLeftovers` moved back only what the station could hold. Module recipes **and** station equipment are refunded 100 % by vanilla (D-17); `esr_refund.xml` is log-only. `esr_cargo.xml` ([workflow-protections-v1.md](workflow-protections-v1.md)).
- [ ] Keep stored wares: cargo in storage modules that get removed goes to build storage
- [x] Refund removed modules at 100% of their build cost: vanilla already does this (recipe + mounted equipment)
- [x] Equipment on removed modules (turrets, shields): vanilla refunds 100 % (manual test 2026-10-16, D-17)
- [x] ~~Build storage full~~: not needed, build storage has no limit (D-11)
- [ ] In-game test: full replacement; wares before and after add up

## Phase 5: Workforce (G3, D-8)
Holding, returning and the grace-period decay are **verified in game** (runs 6–9: 41 250 held, all returned when the new habitats were built; run 15: the pool stays until the grace period ends, then shrinks at the leave-rate setting). `esr_workforce.xml` ([workflow-protections-v1.md](workflow-protections-v1.md)).
- [x] Record workforce per race before habitats go
- [x] Hold workers above the new capacity in a mod-side store; add them back as capacity returns
- [x] Grace period (setting, default 2 h), then workers leave at the rate setting (D-8, D-12). Verified run 15 with 0.1 h and 20 %/h
- [x] In-game test: replace all habitats; workforce comes back after the rebuild (runs 6–9) and, if the habitats are not rebuilt, leaves only after the grace period (run 15)

## Phase 6: Keep unchanged modules (S1, D-9)
- [ ] Depends on Phase 1 findings; steps to be written then

## Phase 7: Safety, options, compatibility (G4)
- [ ] Save compatibility: install mid-game, uninstall mid-game, during a rebuild
- [x] Options menu (SirNukes Mod Support APIs, optional dependency, D-14): toggles per protection, grace period, leave rate (written 2026-10-15, untested in game)
- [ ] Without DLCs; with common station mods
- [ ] With the suggested pairings: Build Storage: Station Drone Self-Supply and XBuilder ([docs/workshop.md](../docs/workshop.md))
- [ ] Multiple stations rebuilding at once; NPC stations untouched
- [ ] Performance: no polling every frame

## Phase 8: Release (G5)
- [x] Licence: MIT (D-10)
- [ ] README for players
- [ ] Make the repo public
- [ ] Steam Workshop upload (Egosoft's X Tools / WorkshopTool), description, screenshots; list dependencies on the Workshop page
- [ ] Suggested pairings on the Workshop page ([docs/workshop.md](../docs/workshop.md))
- [ ] Version scheme and release notes

## Later (ideas, not agreed)
- [ ] Warning in the build menu listing what a plan change will remove (Lua, allowed by D-5)
- [ ] Work with plans from `x4-station-designer`
