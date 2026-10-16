# Testing in game

How to run the in-game tests. Offline checks come first: `python -I tools/check.py` must pass.

## Automated runs (Claude runs these)
`pwsh tools/run-game.ps1 [-TimeoutMinutes 20]` links the test harness (`extension_test\`) and the mod, starts X4 through Steam, and the harness loads `save_010` (a copy of the user's `save_002`), runs the scenario in `extension_test/md/esr_test.xml`, logs `[ESR-TEST]` lines, ends with `[ESR-TEST] DONE` and quits the game. The runner then unlinks the harness, copies the log to `research/logs/run-<time>.txt` and prints our lines. One run takes about 2½ minutes plus the scenario. Autosave is switched off in `config.xml` for the run and restored afterwards, so the test game never overwrites the user's autosaves. `save_010` needs Corporate Dynamics (`ws_3772881250`). The runner copies `content.xml` to `content.xml.esr-run-backup`, sets only that extension to `enabled="true"` (UTF-8, no BOM), marks the file read-only for the run, and restores the backup after the game exits, including a failed run. `FOpenForWriting(content.xml): Error 13` is that read-only file. Needs: Steam running, the game's Steam launch options `-skipintro -logfile debuglog.txt` (otherwise Steam asks before each launch), Protected UI mode off (it is), nobody playing at the time. Workflow: [workflow-test-harness.md](../tasks/workflow-test-harness.md).

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
| B1 Matching | (a) Save the station's plan as a new plan and load it back onto the station; Confirm. (b) The same plan with a changed build order (from `x4-station-designer`), Confirm. (c) Move one built module in the editor, Confirm. | Note which of a/b/c you did and roughly when. The engine's `CONFIRM removed` line answers it; the diag `PLAN removed` list is wrong when the new entry ids are not mapped yet. (a) run 19: kept all 7; the plan file has no component ids. (b) run 21: menu removed 0, positions unchanged, every module stayed operational for 3 minutes, and a price-0 build stayed queued and never went in progress. (c) run 22: a plan load with the defence disc 1000 m higher removed only that disc, and one module entered construction within 3 s. |
| B2 Replace a few | Replace 2–3 modules (one of them a storage module with cargo, if possible). Confirm and let it build. | Run 26 (scenario `b2`, protections off): one Confirm removed the S container, the energy-cell module at x=−884, and the defence disc. The dock, the other energy-cell module, the pier and the habitat stayed. Nothing was added. 200 medical supplies were on the station at Confirm and gone 3 s later, not in build storage. The storage and energy-cell recipes (312 / 623 / 1140) were in build storage about 69 s later, while the disc was still under construction. The disc's recipe arrived when build `0x8426` finished, about 183 s after Confirm. The total was the three recipes (449 / 897 / 1641). `iswaitingforstorage` stayed 0. |
| B3 Full replacement | Load a different plan onto the station, Confirm, let it build. | Run 27 (scenario `b3`, protections off): loading `tutorial_quantumtube` removed all 7 modules and added 5 new ones (pier, M dock, L habitat, L container, quantum tubes). 200 medical supplies were gone within 3 s of Confirm and never reached build storage. The seven recipes (1170 / 2338 / 4276) arrived when the last old module finished, about 184 s later. By 12 min the builder had spent the pier, dock and L habitat recipes from that stock, and `iswaitingforstorage` stayed 0. The L container and the quantum-tube module were not up yet. |
| B4 Storage with cargo | Remove a storage module that holds wares. | As B2. Run 23 (scenario `b4`, protections off): the build menu removed only the S container. 200 medical supplies were still on the station at Confirm and gone 3 s later, not in build storage. The module recipe (52 / 103 / 189) arrived in build storage when the module finished deconstruction, about 72 s later. The station had no other container storage. Run 29 (same scenario, cargo protection on, ships and workforce off): the 200 moved to build storage in the confirm frame and were still there after the container was gone, together with the recipe. |
| B5 Habitats | Remove the habitats (or replace them). | Run 3 (script path, protections off): removing the only habitat took the workforce from 250/250 to 0 at once. There is no gradual vanilla leave rate. Workforce protection on that habitat-loss case is run 15 (scenario `grace`): held workers stay until the grace period ends, then leave at the rate setting (0.1 h and 20 %/h). Runs 6–9 held 41 250 and returned them when the new habitats were built. |
| B6 Docks with ships | Remove a dock area or pier with ships docked. | Run 3 (script path) and run 24 (scenario `b6menu`, build menu, protections off): removing the pier undocks the L freighter in the confirm frame. It is outside the station within 3 s and still exists after the pier is gone, about 72 s later. The M freighter on the dock area stays docked. The pier recipe (313 / 625 / 1143) arrives in build storage when the pier finishes deconstruction. Run 25 (scenario `b6dock`, protections off): removing the dock area left an S freighter in its internal bay and an M freighter on an external pad inside the station, and destroyed both (`contextkilled`) when the dock finished deconstruction, about 65 s after Confirm. Run 28 (same scenario, ship protection on, cargo and workforce off): both ships were ordered to park at Confirm, warped about 11 s later, and both still existed after the dock was gone. The 427-module replacement destroyed ships that were still inside the station (runs 6 and 7). |

Tests can share one plan change (e.g. B2 + B4 + B6 in one go); write down which ones you combined.

## Protections (after B1–B6)
All protections are off by default (D-14). Turn one on in *Extension Options → Easier Station Rebuild* (needs SirNukes Mod Support APIs), repeat the matching test, and look for its log lines. The `MAIN tracking …` line shows which ones were on.

| Protection | Repeat | Log lines | Pass when |
|------------|--------|-----------|-----------|
| Protect docked ships | B6 | `SHIPS … ordered to park` / `asked to undock` / `warped out` | No ship destroyed (`EVENT destroyed` lines); player ships wait near the station. Run 28 (`b6dock`, ships on): both ships still existed after the dock was gone. |
| Keep cargo of removed storage | B4 | `CARGO … moving` / `moved` | Station cargo + build storage after the build ≥ station cargo before (minus what the build used). Run 29 (`b4`, cargo on): the 200 medical supplies were in build storage after the container was gone. |
| Full refund for removed modules | B2, B3 | `CONFIRM removed … recycled=` | Build storage gains the engine refund (module recipe + mounted equipment). Vanilla already pays 100 %; `esr_refund.xml` is log-only (D-17) |
| Keep workforce during rebuilds | B5 | `WORKFORCE … holding` / `returned` | Workers come back when the new habitats finish; before the grace period ends none are lost. Runs 6–9: 41 250 held and returned when the new habitats were built. Run 15 (scenario `grace`, workforce on): the pool stays until the grace period ends, then shrinks at the leave-rate setting (0.1 h and 20 %/h). |

A real (not force-completed) habitat build is **verified** (run 18): the builder consumed the module recipe from build storage, and `ReturnLeftovers` moved back only what the station could hold.

Also check after each test: no `[=ERROR=]` lines for `extensions\station_rebuilder` (`tools/esr_log.py --errors`).
