# Testing in game

How to run the in-game tests. Offline checks come first: `python -I tools/check.py` must pass.

## Automated runs (Claude runs these)
`pwsh tools/run-game.ps1 [-TimeoutMinutes 20]` links the test harness (`extension_test\`) and the mod, starts X4 through Steam, and the harness loads `save_010` (a copy of the user's `save_002`), runs the scenario in `extension_test/md/esr_test.xml`, logs `[ESR-TEST]` lines, ends with `[ESR-TEST] DONE` and quits the game. The runner then unlinks the harness, copies the log to `research/logs/run-<time>.txt` and prints our lines. One run takes about 2½ minutes plus the scenario. Autosave is switched off in `config.xml` for the run and restored afterwards, so the test game never overwrites the user's autosaves. Needs: Steam running, the game's Steam launch options `-skipintro -logfile debuglog.txt` (otherwise Steam asks before each launch), Protected UI mode off (it is), nobody playing at the time. Workflow: [workflow-test-harness.md](../tasks/workflow-test-harness.md).

## One-time setup
1. **Dev install:** `pwsh tools/link-dev.ps1` links `extension\` into `<profile>\extensions\station_rebuilder` (done 2026-10-15). Remove with `-Remove`.
2. **Log:** the game must run with `-logfile debuglog.txt` (Steam → X4 → Properties → Launch options). **Verified 2026-10-15:** the dev machine already writes `<profile>\debuglog.txt`, and other mods' `debug_text … filter="general"` lines appear in it as `[General] <time> *** Context:md.<Script>.<Cue><inst:…>: <text>`. Script errors appear as `[=ERROR=] <time> extensions\<folder>\md\<file>.xml(<line>): <message>`.
3. **Enable the extension** if the game asks (new extensions may need enabling in *Extensions* in the main menu).

## After each session
`python -I tools/esr_log.py --errors > <somewhere>\esr.log` pulls our lines (and script errors in our files) out of the newest `debuglog.txt`. Claude can also read `debuglog.txt` directly. The log is rewritten at every game start, so pull the lines before restarting.

## Does the mod load? (first check)
Start the game, load a save. In the log:
- `[ESR] Lua logger loaded` (Lua side; shown as an `[=ERROR=]` line because Lua writes through `DebugError`)
- `[ESR] MD logger started` (first time) or `[ESR] MD logger active after load`
- no `[=ERROR=]` line mentioning `station_rebuilder` or `esr_diag`

## Phase 1 tests B1–B6 (vanilla behaviour, measured by the logger)
**Back up the save first** (copy it to `<name>.bak-YYYYMMDD-HHMM` in `<profile>\save\`). Use a test save, not the main one.

Station set-up: a player station with a builder assigned and money in its build account, some wares in storage, habitats with workers, and a dock area or pier with a few player ships docked (ships without important crew).

What the logger writes for each plan change:
- `CONFIRM …` lines (Lua, at the Confirm button): the engine's own list of removed modules with what each gives back, the changed/new entries, the build storage.
- `PLAN …` lines (MD, right after): each plan entry → existing module or new; removed modules with recycling wares, build cost and docked ships; a summary.
- `SNAP …` lines: modules, builds, build processor (waiting for resources / storage, recycled so far), build storage, station cargo, workforce, docked ships. Every 60 s while building, then every 5 min for an hour.
- `EVENT …` lines: build steps, build finished/cancelled, player ships and modules destroyed (with killer and kill method).

| Test | Do | Then |
|------|----|------|
| B1 Matching | (a) Save the station's plan as a new plan and load it back onto the station; Confirm. (b) The same plan with a changed build order (from `x4-station-designer`), Confirm. (c) Move one built module in the editor, Confirm. | Note which of a/b/c you did and roughly when. The engine's `CONFIRM removed` line answers it; the diag `PLAN removed` list is wrong when the new entry ids are not mapped yet. (a) run 19: kept all 7. (b) run 21: menu removed 0, no module left operational in 3 min, a price-0 build stayed queued. (c) run 22: a plan load with the defence disc 1000 m higher removed only that disc, and one module entered construction within 3 s. |
| B2 Replace a few | Replace 2–3 modules (one of them a storage module with cargo, if possible). Confirm and let it build. | Let it run until the build finishes, plus 5 min. |
| B3 Full replacement | Load a different plan onto the station, Confirm, let it build. | As B2. Watch for "waiting for storage". |
| B4 Storage with cargo | Remove a storage module that holds wares. | As B2. Run 23 (scenario `b4`, protections off): the build menu removed only the S container. 200 medical supplies were still on the station at Confirm and gone 3 s later, not in build storage. The module recipe (52 / 103 / 189) arrived in build storage when the module finished deconstruction, about 72 s later. The station had no other container storage. |
| B5 Habitats | Remove the habitats (or replace them). | Run 3 (script path): removing the only habitat took the workforce from 250/250 to 0 at once. There is no gradual vanilla leave rate. The mod's grace period is run 15. |
| B6 Docks with ships | Remove a dock area or pier with ships docked. | Note when the ships die (if they do). |

Tests can share one plan change (e.g. B2 + B4 + B6 in one go); write down which ones you combined.

## Protections (after B1–B6)
All protections are off by default (D-14). Turn one on in *Extension Options → Easier Station Rebuild* (needs SirNukes Mod Support APIs), repeat the matching test, and look for its log lines. The `MAIN tracking …` line shows which ones were on.

| Protection | Repeat | Log lines | Pass when |
|------------|--------|-----------|-----------|
| Protect docked ships | B6 | `SHIPS … ordered to park` / `asked to undock` / `warped out` | No ship destroyed (`EVENT destroyed` lines); player ships wait near the station |
| Keep cargo of removed storage | B4 | `CARGO … moving` / `moved` | Station cargo + build storage after the build ≥ station cargo before (minus what the build used) |
| Full refund for removed modules | B2, B3 | `CONFIRM removed … recycled=` | Build storage gains the engine refund (module recipe + mounted equipment). Vanilla already pays 100 %; `esr_refund.xml` is log-only (D-17) |
| Keep workforce during rebuilds | B5 | `WORKFORCE … holding` / `returned` | Workers come back when the new habitats finish; before the grace period ends none are lost. Scenario `grace` (run 15): held count stays flat until `$GraceHours`, then falls at `$LeaveRate` %/h |

Also check after each test: no `[=ERROR=]` lines for `extensions\station_rebuilder` (`tools/esr_log.py --errors`).
