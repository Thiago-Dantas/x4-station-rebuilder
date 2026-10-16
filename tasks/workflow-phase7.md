# Workflow: Phase 7, safety, options, compatibility (G4)

Status: **in progress** (started 2026-10-16)

Goal (G4): safe to add to and remove from an existing save. No broken saves, no stuck builds after uninstall. Roadmap: [roadmap.md](roadmap.md). S1 stays deferred. Do not repeat runs 15–29.

## Steps
- [ ] Save compatibility: install mid-game, uninstall mid-game, during a rebuild
  - [x] Read what `save="false"` does to this mod's Mission Director state (test save and the 2026-10-15 backup, no game launch). It omits the mod from `<patches>` and still writes the `ESR_*` script elements. Details: [docs/x4-modding.md](../docs/x4-modding.md) "Save attribute".
  - [x] Install mid-game: `save_010` has no `ESR_*` scripts (mtime still 2026-10-15 20:09). Runs 1–29 loaded it with the mod and the scripts started.
  - [ ] Uninstall mid-game: a save made with the mod loads with it removed, and the build is not stuck. Not run. `save_010` has never been written by the game, so it does not contain the script elements. Do not load `save_003` or the 427-module station. Next: teach the harness to write `save_010`, then load that file with the mod unlinked.
  - [ ] During a rebuild: save and load while workforce is held. The pool is stored in `ESR_Workforce.State.$Stations` when the game writes the save (verified in the save_003 backup). A quit and reload of `save_010` with the pool still held is not measured. Same harness save as the uninstall step.
- [x] Options menu (written 2026-10-15, untested in game). Do not retest unless this phase's save work needs it.
- [ ] Without DLCs; with common station mods
- [ ] With the suggested pairings: Build Storage: Station Drone Self-Supply and XBuilder ([docs/workshop.md](../docs/workshop.md))
- [ ] Multiple stations rebuilding at once; NPC stations untouched
- [ ] Performance: no polling every frame

## Notes
- `extension/content.xml` has `save="false"` (since the skeleton). SirNukes is an optional dependency (D-14).
- Run 13: root State cues that already ran do not run again on load, so MD variables survive a reload while the mod is installed. Run 15: the save still held leave rate 10 after the harness wrote 20 into the live game. Both are with the mod present.
- NPC stations are already excluded (`isplayerowned` on the build event and on Confirm). The sweep is `checkinterval="30s"`. Ship watch is `2s`. Diag tick is `60s`. None of those is every frame. Not checked off until the step is reviewed.
