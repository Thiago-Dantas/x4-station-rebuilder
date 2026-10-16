# Roadmap

Master list of milestones. Each active workstream gets its own `tasks/workflow-<topic>.md` with step-by-step state, linked from here. Goals (G1–G5, S1) are in [docs/goals.md](../docs/goals.md), decisions (D-n) and open questions (OD-n) in [docs/decisions.md](../docs/decisions.md).

Phase order after Phase 2 is a proposal: ships first because a destroyed ship can't be undone, then materials, then workforce. S1 comes last of the features because it depends most on what Phase 1 finds.

## Phase 0: Project setup
Log: [workflow-project-setup.md](workflow-project-setup.md)
- [x] CLAUDE.md, docs/, tasks/ skeleton
- [x] Repo-local `user.email`
- [x] User review of the roadmap; OD-1 … OD-7 decided (D-4 … D-10), `LICENSE` (MIT)
- [ ] First commit and push (when the user asks)

## Phase 1: Research: what the game does when a plan changes
Log: [workflow-phase1-research.md](workflow-phase1-research.md)

Questions to answer before writing the mod (part A, game files, done 2026-10-15; part B, in game, waiting):
- [ ] Reproduce the four losses in a test save and measure them (B2–B6)
- [ ] How the game matches the old station to the new plan, and can a script influence it (S1, D-9). Files: the engine matches, Lua only reads the result; B1 decides.
- [ ] The vanilla refund rule for removed modules. Files: `GetModuleRecycledResources` / `recyclingwares.max`, back to build storage by the builder; amounts vs build cost in B2/B3.
- [x] Build storage: MD adds wares with `add_cargo` (vanilla does it). The no-limit statement (D-11) vs `iswaitingforstorage` → B3.
- [ ] Cargo in storage modules that get removed: vanilla moves cargo only when the whole station goes → B4
- [x] The first moment a script can act: before confirm, from a Lua wrap of the build menu's confirm (the engine's removed-module list is available); after confirm, `event_build_added` on the build storage, while the builder recycles modules over time
- [x] Docked ships: `dockingbay.docked`, `undock`, `request_undocking`, `warp` with `safepos` exist. How they die → B6.
- [ ] Workforce: per-race amount/capacity and `add_workforce`/`remove_workforce` exist; `add_workforce` can't exceed capacity, so the grace period needs a mod-side store. The vanilla leave rate (D-12) → B5.
- [x] Prior-art mods: none touch plan changes
- [x] OD-8, OD-9 decided by the user (D-11, D-12)
- [ ] Decide whether S1 is doable

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
First version written 2026-10-15; **verified in game** (automated run 8, full replacement: 0 of 2 ships lost): [workflow-protections-v1.md](workflow-protections-v1.md) (`esr_ships.xml`).
- [ ] Find ships docked at modules about to be removed
- [ ] Undock them and park them near the station; teleport the ones that can't get out in time
- [ ] Handle ships that can't undock (no pilot, busy, being built or repaired at that dock)
- [ ] In-game test: replace a pier and a dock area with ships docked; nothing destroyed

## Phase 4: Materials (G2, D-6)
Cargo **verified in game** (runs 6–8: 14.46 M wares kept). Module recipes are refunded by vanilla; equipment is not (engine, docs/x4-modding.md), so the refund protection is being redesigned to refund equipment. `esr_cargo.xml`, `esr_refund.xml` ([workflow-protections-v1.md](workflow-protections-v1.md)).
- [ ] Keep stored wares: cargo in storage modules that get removed goes to build storage
- [ ] Refund removed modules at 100% of their build cost (wares per build method, from `wares.xml`) into build storage, without paying twice for what the game already returns
- [ ] Equipment on removed modules (turrets, shields)
- [x] ~~Build storage full~~: not needed, build storage has no limit (D-11)
- [ ] In-game test: full replacement; wares before and after add up

## Phase 5: Workforce (G3, D-8)
Holding and returning **verified in game** (runs 6–9: 41 250 held, all returned when the new habitats were built). The grace-period decay is not tested yet. `esr_workforce.xml` ([workflow-protections-v1.md](workflow-protections-v1.md)).
- [ ] Record workforce per race before habitats go
- [ ] Hold workers above the new capacity in a mod-side store; add them back as capacity returns
- [ ] Grace period (setting, default 2 h), then workers leave at the game's own rate or the rate setting (D-8, D-12)
- [ ] In-game test: replace all habitats; workforce comes back after the rebuild

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
