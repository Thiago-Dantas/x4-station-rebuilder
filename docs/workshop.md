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

## Publishing draft

Draft only (2026-10-16). Not uploaded. The dev `extension/content.xml` is unchanged. Publish from a separate folder named `station_rebuilder`, never from the dev junction.

### Page

Title: **Easier Station Rebuild**

Description the tool uploads (the `description` attribute below). English, as the Workshop page does not localise:

Changing a station's construction plan keeps the ships at its docks, the wares in its storage, and the workforce for a grace period.

When you confirm a plan change on a station you own, ships docked at a module that is removed are parked near the station, and moved out if they cannot leave in time. Wares that no longer fit are moved to the station's build storage, and what the finished station can hold is moved back when the build ends. Removed modules, turrets and shields are refunded in full by the game. Workers who lose their habitat wait 2 hours, then leave at 20% of those still waiting per hour. New habitats take them back as room appears.

Settings are in Extension Options when SirNukes Mod Support APIs is installed. Without it, the defaults above are used. That mod is optional.

Only your own stations are affected. A module the new plan still contains can still be taken apart and built again. Build time and build cost are unchanged.

Dependency to show on the page: SirNukes Mod Support APIs, optional, Workshop id 2042901274 (`ws_2042901274` in `content.xml`). Minimum game version 9.00 (`<dependency version="900"/>`).

Proposed first version: **1.00**, which is `version="100"` (the tool's rule: the attribute is the displayed version times 100). Proposed first change note: `First release.` This version number is a proposal in this draft, not a logged decision.

### Release content.xml

The `&#10;` sequences are line breaks. The Egosoft wiki says `\n` does not work in this attribute (wiki text, last modified 2023-09-22). Set `date` to the day of the upload. The tool replaces `id` when the upload succeeds.

```xml
<?xml version="1.0" encoding="utf-8"?>
<content id="station_rebuilder" name="Easier Station Rebuild" description="Changing a station's construction plan keeps the ships at its docks, the wares in its storage, and the workforce for a grace period.&#10;&#10;When you confirm a plan change on a station you own, ships docked at a module that is removed are parked near the station, and moved out if they cannot leave in time. Wares that no longer fit are moved to the station's build storage, and what the finished station can hold is moved back when the build ends. Removed modules, turrets and shields are refunded in full by the game. Workers who lose their habitat wait 2 hours, then leave at 20% of those still waiting per hour. New habitats take them back as room appears.&#10;&#10;Settings are in Extension Options when SirNukes Mod Support APIs is installed. Without it, the defaults above are used. That mod is optional.&#10;&#10;Only your own stations are affected. A module the new plan still contains can still be taken apart and built again. Build time and build cost are unchanged." author="Thiago Almeida Dantas" version="100" date="YYYY-MM-DD" save="false" enabled="1">
  <dependency version="900"/>
  <dependency id="ws_2042901274" optional="true" name="SirNukes Mod Support APIs"/>
</content>
```

### Command

Steam running and logged in. The tool asks before uploading. Do not pass `-batchmode`.

```
WorkshopTool publishx4 -path <release folder> -preview <jpg or png> -buildcat
```

`-buildcat` packs the loose XML and Lua into `ext_01.cat` and deletes that catalog afterwards. After the upload, open the item page, accept the Steam Workshop legal agreement if it asks, and set the visibility. A new item stays hidden until then.

The preview is still to be made. One real in-game screenshot, JPG or PNG, widescreen, 640×360 or larger.

### Still to do before that command

- Copy `extension/` to a release folder named `station_rebuilder` and use the content.xml above. The tool rewrites the content.xml it is pointed at.
- Turn the three protections on by default in that copy (D-14). In the dev scripts they are still off (`$Ships`, `$Cargo`, `$Workforce` start at 0 in `esr_main.xml`).
- Take the log-only option "Refund equipment of removed modules (test)" out of the player menu in that copy (D-17). The game already refunds that equipment.
- Make the repo public first (D-3). The player README links to it.
- A preview screenshot.
- Leave the suggested-pairings paragraph off the page until a rebuild has been tried with each mod (Phase 7). Draft paragraph, for after that test: "Two other mods make the rebuild itself easier. Build Storage: Station Drone Self-Supply moves wares you already have into the build storage. XBuilder adds construction ships to a station that is already being built. Both need SirNukes Mod Support APIs."

