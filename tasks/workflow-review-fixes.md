# Workflow: fixes from the code review of 2026-10-26

Status: **in progress** (started 2026-10-26). Roadmap: [roadmap.md](roadmap.md).

The user went through the `/code-review high` findings: 1, 4, 6, 7, 8, 9, 10 are bugs to fix, 5 gets a debug-log setting, 2 is a non-issue (every removed module goes into deconstruction on its own ~3 min timer, not in build order), 3 is fine as it is.

## Steps
- [x] 1: park order (`MoveWait`) had timeout `0s` = wait forever; give it a finite wait and don't recall subordinates (`esr_ships.xml`)
- [x] 4: leftovers go back only when no expansion build of the station is queued or running (`esr_main.xml` SweepStation)
- [x] 5: setting "Enable debug log" (off): gates `ESR_Diag`, the COMPARE line and `ui/esr_diag.lua` (`raise_lua_event` `esr_debug`)
- [x] 6: no plan-mapping work while the engine list exists; COMPARE only with debug on and with table lookups
- [x] 7: ships that dock at a doomed module after the Confirm sweep: `event_object_docked_at` on a group of tracked stations (`esr_ships.xml` Docking)
- [x] 8: a Confirm list is used only by the build added with it (`$ConfirmTimes`; stale lists dropped at the next build)
- [x] 9: `OnEquipment` keeps no loadouts while the refund test setting is off (and clears old ones)
- [x] 10: `extension/` matches the published 1.01 (protections on, `ReleaseDefaults`, `esr_defaults_rev`, no refund option); D-14 superseded
- [x] Harness: turn the debug log on in `extension_test` so test logs keep the PLAN/SNAP lines
- [x] `python -I tools/check.py` passes
- [ ] In-game check with `tools/run-game.ps1` (ask the user first: they may be playing)
- [x] Docs: CLAUDE.md, decisions, x4-modding (performance), workshop (release copy step)
- [x] Commit and push

## Notes
- Offline checks: `python -I tools/check.py` passed 2026-10-26 (schemas, 310 cue references, 1554 property names, Lua syntax).
- Still hypotheses until a run: `event_object_docked_at` on a group whose members change; `ship.dock.module` is the module that holds the dock; `raise_lua_event` with a param reaches `RegisterEvent` in `esr_diag.lua`; SirNukes calls the `esr_debug` callback on every load; `MoveWait` with `3min` returns the ship to its previous or default order.
- The release folder `H:\dev\esr-release\station_rebuilder` was not touched; it still matches the published 1.01.
- Scenarios worth running: `b6dock` (ships; a ship docking after Confirm is not in it yet), `b4` (cargo, leftovers), `grace` (workforce), one with the debug log off to see that no PLAN/SNAP lines appear.
