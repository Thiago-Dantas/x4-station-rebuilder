# Workflow: Phase 7, safety, options, compatibility (G4)

Status: **in progress** (started 2026-10-16)

Goal (G4): safe to add to and remove from an existing save. No broken saves, no stuck builds after uninstall. Roadmap: [roadmap.md](roadmap.md). S1 stays deferred. Do not repeat runs 15–29.

## Steps
- [x] Save compatibility: install mid-game, uninstall mid-game, during a rebuild
  - [x] Read what `save="false"` does to this mod's Mission Director state (test save and the 2026-10-15 backup, no game launch). It omits the mod from `<patches>` and still writes the `ESR_*` script elements. Details: [docs/x4-modding.md](../docs/x4-modding.md) "Save attribute".
  - [x] Install mid-game: runs 1–29 loaded the copy of `save_002` that had no `ESR_*` scripts. Run 30 later overwrote `save_010`.
  - [x] Uninstall mid-game: run 31 loaded the `save_010` that run 30 wrote with the mod linked. The mod was unlinked. The save reached the game (Savage Spur II, age 362283.189) and the log does not name `ESR_Main` or `station_rebuilder`. Other save slots kept their timestamps. The harness quit in the load frame. `event_game_saved` did not signal, so run 30 was killed at the timeout after the file was already closed. Log `research/logs/run-20261016-154845.txt`. Do not load `save_003` or the 427-module station. Do not repeat runs 30–31.
  - [x] During a rebuild: no separate load. Nothing in `extension/md` starts, aborts, or takes a construction sequence (verified, files). The grace pool is `ESR_Workforce.State.$Stations` (verified in `esr_workforce.xml` and in the save_003 backup). Removing the mod drops that pool; those workers are already off the station. Cargo already in build storage stays. SirNukes calls the option callback only when this mod registers and the cue exists. A live build was not watched after the load. Details: [docs/x4-modding.md](../docs/x4-modding.md) "Save attribute".
- [x] Options menu (written 2026-10-15, untested in game). Do not retest unless this phase's save work needs it.
- [ ] Without DLCs; with common station mods. The user will test these. Do not run them in the harness.
- [ ] With the suggested pairings: Build Storage: Station Drone Self-Supply and XBuilder ([docs/workshop.md](../docs/workshop.md)). The user will test these. Do not run them in the harness.
- [ ] Multiple stations rebuilding at once; NPC stations untouched
- [x] Performance: no polling every frame (verified, files, 2026-10-16). No interval was changed. Details: [docs/x4-modding.md](../docs/x4-modding.md) "Condition checks".

## Notes
- `extension/content.xml` has `save="false"` (since the skeleton). SirNukes is an optional dependency (D-14).
- Run 13: root State cues that already ran do not run again on load, so MD variables survive a reload while the mod is installed. Run 15: the save still held leave rate 10 after the harness wrote 20 into the live game. Both are with the mod present.
- NPC stations are already excluded (`isplayerowned` on the build event and on Confirm).
- Condition checks (verified, files, 2026-10-16): `libraries/md.xsd` says `checkinterval` is the delay between condition checks, and not to use it on a cue that has an event. `X4.exe` 9.00 reports an instantiating cue that has neither an event condition nor a check interval. Its scheduler keeps a positive interval and uses 1 second when the stored interval is not greater than 0. That is not a per-frame poll. In `extension/md` the only repeating condition cues are `ESR_Main.SweepTimer` (`30s`, and the sweep runs only while a rebuild is tracked), `ESR_Ships.Watch` (`2s`, and it acts only while a ship is in `$Tried`), and `ESR_Diag.Tick` (`60s`, and it acts only while a station is tracked). The other cues are events or one-shot state cues. `extension/ui/esr_confirm.lua` and `esr_diag.lua` only wrap Confirm.
