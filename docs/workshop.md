# Steam Workshop page

Notes for the mod's Workshop page (release: roadmap Phase 8).

## Suggested pairings (user, 2026-10-15)
Mods to recommend next to ours on the Workshop page. Both make station building less tedious, and both need SirNukes Mod Support APIs, which we may depend on too (D-5).

| Mod | Workshop | Author | Installed here as | What it does (from its own description, version checked) |
|-----|----------|--------|-------------------|-------------------------------------------------------------|
| Build Storage: Station Drone Self-Supply | [3754773002](https://steamcommunity.com/sharedfiles/filedetails/?id=3754773002) | Simucad | `extensions/baulager_drone_supply` (id `ws_3754773002`) | The station's cargo drones supply its build storage from wares already stored on the station; optional "Drone-Only" toggle (right-click the station). Removable mid-game. (v102, 2026-06-30) |
| XBuilder | [3797254195](https://steamcommunity.com/sharedfiles/filedetails/?id=3797254195) | Lord Starwolf | `extensions/xbuilder` (id `ws_3797254195`) | Assign more construction vessels to a station under construction; they work the same plan in the same order and use the same materials, so it finishes faster. (v104, 2026-09-23, for X4 8.00 and 9.x) |

**Why they fit:** our mod keeps a rebuild from losing ships, wares and workers; Drone Self-Supply gets the refunded and stored wares into the build faster; XBuilder shortens the rebuild itself.

**Compatibility (to test in Phase 7):** both touch station builds. XBuilder adds builders to a running build and Drone Self-Supply moves wares into build storage, while our mod hooks plan changes, recycling and build storage. Test a rebuild with each of them installed before naming them on the page.

## Upload tool

**verified** (2026-10-16): Steam app 282160 installed, then `WorkshopTool help` exited 0 and printed the text below. Nothing was uploaded.

X Workshop Tool 1.15 and the X Catalog Tool live in `H:\SteamLibrary\steamapps\common\X Tools` (`WorkshopTool.exe`, `XRCatTool.exe`, `XRCatToolGUI.exe`). Steam first wrote the app into `C:\Program Files (x86)\Steam\steamapps\common\X Tools`. It was moved to the H: library, which is where installs go. On the next Steam start the content log loaded 8 apps from `H:\SteamLibrary` and left no `appmanifest_282160.acf` on C:. Build id 19742470, depot 282161, about 4.4 MB.

First X4 upload, from that help text. Do not run this until the release step:

```
WorkshopTool publishx4 -path <extension folder> -preview <jpg or png> -buildcat
```

The tool asks before it uploads. `-batchmode` skips the question and uploads immediately.

From the same help text:
- `-path` is required. The Workshop folder name is that folder's name unless `-foldername` is set.
- Files uploaded from the folder are `.cat`, `.dat`, `.cur`, `.mkv`, `.txt`, and `.pdf`. `-buildcat` builds `ext_01.cat` when the folder has no catalog, then deletes the catalogs unless `-keepcatfiles` is set.
- Upload modifies the content definition. That is `content.xml` in the folder, or the file given with `-contentdef`.

The dev junction is `<profile>\extensions\station_rebuilder` (`tools/link-dev.ps1`). Publishing from that folder would rewrite the working `content.xml`. Use a separate release copy. `station_rebuilder` is 17 characters and uses only lowercase letters and an underscore. The Egosoft wiki allows `a-z`, digits, `.`, `_`, `-`, and space, and a length of at most 32 (wiki text, last modified 2023-09-22; not re-tested by an upload).

Steam has to be running and logged in. The same wiki page says a limited Steam account cannot publish.

`WorkshopTool help` also opens the tool's tutorial page in the browser.
