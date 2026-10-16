# Workflow: Phase 8, release (G5)

Status: **in progress** (started 2026-10-16)

Goal (G5): published on the Steam Workshop as "Easy Station Rebuild". Roadmap: [roadmap.md](roadmap.md). This file tracks the upload prerequisites. Do not publish, do not make the repo public, and do not change `extension/content.xml` until the release step.

## Steps
- [x] Tooling: Egosoft X Tools (Steam app 282160), which contains `WorkshopTool.exe` and the catalog tool
- [x] Confirm `WorkshopTool` prints its command list and does not upload
- [x] Record the install path in [docs/dev-setup.md](../docs/dev-setup.md) and the publish command in [docs/workshop.md](../docs/workshop.md)
- [x] README for players ([README.md](../README.md))
- [x] Workshop publishing draft: title, description, release `content.xml`, dependencies ([docs/workshop.md](../docs/workshop.md)). Not uploaded.
- [ ] Make the repo public
- [ ] Steam Workshop upload (description, screenshots, dependencies). Not started. The draft lists what is still missing: release copy, protections on by default, the log-only refund option removed from the player menu, a preview screenshot.
- [ ] Suggested pairings on the Workshop page. Wording is drafted and held until the Phase 7 test.
- [ ] Version scheme and release notes

## Notes
- Installed 2026-10-16. Path: `H:\SteamLibrary\steamapps\common\X Tools`. WorkshopTool 1.15, build 19742470. Steam had written it on C:; it was moved to the H: library and Steam loaded it from there on restart (content log: 8 apps on H:, no manifest left on C:).
- `WorkshopTool help` printed the command list and exited 0. It also opens the tutorial page. No upload.
- X4 publish, from that help text: `WorkshopTool publishx4 -path <extension folder> -preview <jpg or png> -buildcat`. It asks before uploading. `-batchmode` uploads with no question. Do not use it, and do not run `publishx4` or `update`, until the release step.
- Upload rewrites `content.xml`. Do not point `-path` at the dev junction `<profile>\extensions\station_rebuilder`.
- Official procedure: [Steam Workshop for X Rebirth and X4](https://wiki.egosoft.com/X%20Rebirth%20Wiki/Modding%20support/Steam%20Workshop%20for%20X%20Rebirth%20and%20X4/). The website catalog download is a separate login-gated package and does not include WorkshopTool.
