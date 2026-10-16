# Workflow: diagnostic logger (Phase 1 part B tooling, Phase 2 skeleton)

Status: **in progress** (started 2026-10-15)

User request (2026-10-15): "build the logging mod". It measures tests B1–B6 ([workflow-phase1-research.md](workflow-phase1-research.md)) and is the mod's first skeleton (Phase 2).

## Steps
- [x] Mod folder `extension/` (D-13): `content.xml` (id `station_rebuilder`, `save="false"`, version 1), `ui.xml` (Lua addon after `ego_detailmonitor`)
- [x] Lua `extension/ui/esr_diag.lua`: wraps the build menu's Confirm, logs the engine's removed modules with their recycled wares, the changed/new entries and build storage, then calls the original
- [x] MD `extension/md/esr_diag.xml`: on `event_player_build_added` (expansion) logs which plan entries map to existing modules (`planmodule.{entry.id}`), the removed modules (recycling wares, build cost, docked ships), a snapshot; then a snapshot every 60 s while building and every 5 min for an hour; build finished / step / cancelled; player ships and modules destroyed
- [x] Offline checks: `md/esr_diag.xml` valid against the game's `md.xsd`, `ui.xml` against `addon.xsd`, Lua parses (luaparser; control: the game's `menu_station_configuration.lua` parses too)
- [x] `tools/check.py`: all offline checks in one command; also `md.<Script>.<Cue>` references and property names vs `scriptproperties.xml`. Negative tests (scratch copies): 7 broken references and 8 `.knowname` typos all reported.
- [x] `tools/esr_log.py`: pull the `[ESR]` lines (and `--errors` in our files) out of `debuglog.txt`
- [x] Dev install: junction `<profile>\extensions\station_rebuilder` → `extension\` (`tools/link-dev.ps1`), created 2026-10-15; second run reports "Already linked"
- [x] Test instructions for the user: docs/testing.md. The log format was checked in the existing `debuglog.txt`: `debug_text filter="general"` lines appear, ids print as hex (Lua side now prints the same hex form).
- [ ] **In game (user):** the mod loads (`[ESR] Lua logger loaded`, `[ESR] MD logger started` in the log), no script errors
- [ ] **In game (user):** B1–B6 played; results read from the log into docs/x4-modding.md

## Notes
- Schema validation checks element structure only, not the expressions inside attributes. Expression errors show up in `debuglog.txt` as script errors.
- Lua lines are written with `DebugError`, so they appear as errors in the log; that is only how they get there.
