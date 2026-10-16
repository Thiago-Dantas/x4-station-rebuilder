# Workflow: evaluate vanilla station-equipment refund (manual test 2026-10-16)

Status: **done** (2026-10-16)

Question: does vanilla X4 refund turrets and shields mounted **on a station module** when a plan change removes that module (not equipment on docked ships)?

The user removed (1) a defence disc and (2) a container storage S, one at a time, through the station build menu, with the diagnostic logger installed and every protection off (pure vanilla).

## Steps
- [x] Copy `%USERPROFILE%\Documents\Egosoft\X4\104494216\debuglog.txt` to `research/logs/manual-2026-10-16-equipment-test.txt` (623 099 bytes, log LastWriteTime 2026-10-16 08:40)
- [x] Extract `[ESR]` lines and identify CONFIRM / PLAN / SNAP for each removal
- [x] Compare engine refund vs module recipe vs recipe + mounted equipment
- [x] Identify what was mounted (`PLAN removed-equipment`; recipes in `ego_dlc_terran/libraries/wares.xml`). Exact integer match, so no save read was needed.
- [x] Record verified result in docs/x4-modding.md, docs/decisions.md (D-17), workflow files, CLAUDE.md
- [x] Commit and push

## Result (verified)
Vanilla refunds **100 %** of the module recipe **plus** mounted turrets and shields. `GetModuleRecycledResources` already includes them; build storage received that amount. `esr_refund.xml` stays log-only (D-17).

| Removal | Recipe (CS / EC / SC) | Equipment | Engine refund (CS / EC / ML / SC) | Build storage |
|---------|----------------------|-----------|-----------------------------------|---------------|
| `defence_ter_disc_01_macro` on Getsu Fune Defence Platform I | 57 / 419 / 117 | 4× L shield mk3, 8× L beam, 16× M laser, 8× M shield mk3 | 609 / 57 587 / 7 316 / 1 089 | before CS 2; after = before + refund |
| `storage_ter_s_container_01_macro` on Getsu Fune Defense | 14 / 103 / 29 | 4× M shield mk3, 8× M beam | 194 / 17 515 / 2 336 / 337 | after = before + refund − 1 L shield mk3 (a disc was also changed on the same confirm) |
