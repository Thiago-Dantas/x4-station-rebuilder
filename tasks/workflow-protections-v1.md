# Workflow: protections, first version (Phases 3–5, settings from Phase 7)

Status: **in progress** (started 2026-10-15, while the user is away: "keep going")

Goal: first working versions of the protections, written from the Phase 1 file research, **before** the in-game measurements B1–B6. Each part is a hypothesis until tested in game; B1–B6 may change them. All are off by default in dev builds (D-14) so B1–B6 measure vanilla.

## Design (shared)
- `ESR_Main` (`extension/md/esr_main.xml`): settings with defaults, SirNukes options registration (optional dependency, D-5), and the rebuild tracker. On `event_player_build_added` (expansion, player station) the station is tracked with its build; a sweep every 30 s computes the **doomed modules** = station modules that no entry of the build's construction sequence maps to (`planmodule.{entry.id}`), and calls each enabled protection. Tracking ends when the build is gone and no protection holds anything for the station.
- One script per protection, each a `run_actions` library called by the sweep, with its own state.

## Steps
- [x] D-14 (protections off by default in dev builds) in docs/decisions.md
- [x] `esr_main.xml`: settings, options registration, tracker, doomed modules, sweep
- [x] Ships (G1, D-7) `esr_ships.xml`: ships docked at doomed modules get a `MoveWait` order to a safe spot near the station (`get_safe_pos`, station size to 2× away); player ships keep waiting there; still docked after 60 s, no pilot, or not the player's: warped there. The player's own ship is never touched (logged).
- [x] Cargo (G2 part 1, D-6) `esr_cargo.xml`: per transport tag, capacity after removal = station capacity − doomed storage modules' macro capacity; used volume above it moves from station cargo to build storage, proportionally over the wares of that tag
- [x] Refund (G2 part 2, D-6) `esr_refund.xml`: doomed modules are watched (build cost = `macro.ware.resources`, vanilla refund = `recyclingwares.max`); when one no longer exists, `cost − refund` per ware goes to build storage. Modules dropped from the plan again or still standing after the build are not refunded.
- [x] Workforce (G3, D-8, D-12) `esr_workforce.xml`: per race, drops caused by capacity (`prev − max(now, capacity)`) go into a held pool; held workers return with `add_workforce` as capacity frees up; after the grace period (setting, default 2 h) the pool shrinks by the leave-rate setting
- [x] Offline checks pass (`tools/check.py`): 6 MD scripts valid, 90 references, 271 property names. The checks found one real error (`request_undocking` needs `queuedresult`/`grantedresult`) and one false alarm (`isclass.storage`: class names aren't property names; the checker now takes them from vanilla scripts). Self-review added: units and mass traffic skipped; refund guarded when a module has no build cost.
- [x] Docs: docs/x4-modding.md (design + open points), docs/testing.md (how to test each protection), CLAUDE.md, roadmap
- [x] Engine list of removed modules (added after the first review): `ui/esr_confirm.lua` sends the build menu's removed modules at Confirm (UI event `esr_confirm`), `ESR_Main.OnConfirm` stores them and the sweep prefers them over the plan-entry mapping; `MAIN COMPARE` logs both. Removes the dependency on the B1 hypothesis for plan changes made in the build menu. Checks pass.
- [x] Build method for refunds: `esr_confirm.lua` also sends the build storage's build method; `esr_refund.xml` maps it to a race and uses `raceresources`. Checker: keyword values (`race.terran`, `class.storage`, …) now learned from vanilla scripts. Checks pass.
- [x] **Verified in game (automated runs 6–8, the user's CVL-296 replacement through the build menu):** cargo (14.46 M wares kept), ships (0 of 2 lost after the warp fix), workforce (41 250 held). Equipment refund: vanilla already pays 100 % (manual test 2026-10-16, D-17).
- [x] **Grace-period decay verified (run 15, 2026-10-16, log `research/logs/run-20261016-090809.txt`):** harness set grace 0.1 h and leave rate 20 %/h (the save still held 10). 250 Argon workers stayed held until the grace period ended, then fell to 237.314 over the next 0.254 h; 20 %/h predicts 237.303.
- [x] **ReturnLeftovers on a real build (run 18, 2026-10-16, log `research/logs/run-20261016-100731.txt`):** one Argon S habitat, not force-completed. The builder took the recipe from build storage (94 claytronics, 188 energy cells, 343 hull parts). Medical supplies were untouched. When the build ended, the script moved back what the station could hold and left the rest in build storage (1639 hull parts, 998 medical supplies). Nothing was created (D-15).
- [x] **Dock-area ships (run 28, 2026-10-16, log `research/logs/run-20261016-141428.txt`):** scenario `b6dock`, ship protection on, cargo and workforce off. Courier XVV-180 started in the S internal bay and Mercury LLR-189 on an external M pad. Both were ordered to park at Confirm and warped 10.8 s later. The dock was gone about 60 s after Confirm. Both ships still existed and were outside the station. No `contextkilled`. Build storage held the dock recipe (54 / 108 / 198). `esr_refund.xml` logged 0 pieces.

## What the user's replacement showed (2026-10-15)
- Cargo protection: the most important one (≈13 M wares lost). It must act at Confirm: 57 s later all storage was gone.
- Refund protection: module recipes and mounted turrets/shields come back 100 % in vanilla (manual test 2026-10-16, D-17). `esr_refund.xml` stays log-only.
- Ship protection and workforce protection: needed as designed.
- All of it has to happen in the first seconds: all modules switch to deconstruction at once.

## Open points (to settle with B1–B6 or the user)
- ~~Leave rate~~: settled, D-12 revised: setting, default 20 %/h of the held pool (vanilla drops everything at once). Saves that already ran the mod keep their stored value (10) until changed in the options.
- ~~Refunds use the default build method's recipe~~: fixed; the build method comes with the Confirm event (`GetContainerBuildMethod`, else the player's global method) and refunds use `ware.raceresources.{race}`. Plan changes made without the build menu still use the default recipe.
- ~~Equipment (turrets, shields) on removed modules~~: vanilla refunds 100 % (D-17).
- ~~Wares in build storage that the build doesn't need~~: settled, D-15. Run 18 confirmed the split: what fits goes back to the station, the rest stays in build storage.
- `recyclingwares.max` may already be a table; then `.table` gives null and the refund would add the full cost on top of vanilla (B2 log shows the type).
- Ships arriving at a doomed dock later are caught by the 30 s sweep, not prevented from docking.
