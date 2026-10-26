# Steam Workshop page

Notes for the mod's Workshop page (release: roadmap Phase 8).

## Suggested pairings (user, 2026-10-15)
Mods to recommend next to ours on the Workshop page. Both make station building less tedious, and both need SirNukes Mod Support APIs, which we may depend on too (D-5).

| Mod | Workshop | Author | Installed here as | What it does (from its own description, version checked) |
|-----|----------|--------|-------------------|-------------------------------------------------------------|
| Build Storage: Station Drone Self-Supply | [3754773002](https://steamcommunity.com/sharedfiles/filedetails/?id=3754773002) | Simucad | `extensions/baulager_drone_supply` (id `ws_3754773002`) | The station's cargo drones supply its build storage from wares already stored on the station; optional "Drone-Only" toggle (right-click the station). Removable mid-game. (v102, 2026-06-30) |
| XBuilder | [3797254195](https://steamcommunity.com/sharedfiles/filedetails/?id=3797254195) | Lord Starwolf | `extensions/xbuilder` (id `ws_3797254195`) | Assign more construction vessels to a station under construction; they work the same plan in the same order and use the same materials, so it finishes faster. (v104, 2026-09-23, for X4 8.00 and 9.x) |

**Why they fit:** our mod keeps a rebuild from losing ships, wares and workers; Drone Self-Supply gets the refunded and stored wares into the build faster; XBuilder shortens the rebuild itself.

**Compatibility (to test in Phase 7):** both touch station builds. XBuilder adds builders to a running build and Drone Self-Supply moves wares into build storage, while our mod hooks plan changes, recycling and build storage. Not tested yet. The user put both on the page on 2026-10-26 before that test, so the page recommends them without claiming they work together with this mod.

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

## Workshop item

The dev `extension/content.xml` is unchanged. The upload was from a separate folder named `station_rebuilder`, never from the dev junction.

Published 2026-10-16. **verified** from `WorkshopTool` (exit 0, item id 3821053684) and from the Steam Web API `GetPublishedFileDetails` (result 1, visibility 0, title and the 944-character description below). An `ISteamUGC` details query on the same item returned the primary preview plus two additional image previews.

Update 1.01 (2026-10-16, D-21): ships, cargo and workforce start on. Version 1.00 already used that default for a new save, but SirNukes kept the off values saved while the dev build was in use and applied them on every load. The update writes those three menu values on once. Grace period and leave rate stay as the player left them. Change note: `Ships, cargo and workforce now start on.` **verified** from `WorkshopTool update` (exit 0, version 1.00 to 1.01, item 3821053684). The release `content.xml` is `version="101"`, `lastupdate="1792187373"`.

Update 1.02 (2026-10-26): the code review fixes and save cleanup ([workflow-review-fixes.md](../tasks/workflow-review-fixes.md)). First release built from `extension/` (D-22): `md/`, `ui/` and `ui.xml` copied into the release folder, its own `content.xml` bumped to `version="102"`, `date="2026-10-26"`. The 1.01 folder was kept as `H:\dev\esr-release\station_rebuilder.bak-1.01-20261026`. Command: `WorkshopTool update -path <release folder> -buildcat -changenote <3 lines>`, confirmed with `y` on stdin. Change note (three lines): `Ships parked during a rebuild now go back to their orders after 3 minutes.` / `Ships that dock at a module being removed later in the rebuild are moved too; leftovers wait while another rebuild is queued.` / `New Enable debug log option (off); less work at Confirm; old save data cleaned up.`. **verified** from `WorkshopTool` (exit 0, version 1.01 to 1.02, `lastupdate="1793024668"`) and `GetPublishedFileDetails` (result 1, visibility 0, updated 2026-10-26 14:24 UTC). Page text unchanged. Not tested in game before the upload (user's call).

The same day the description got a dated **Changelog** section (user: a "small changelog" means that section on the item page, one dated line per version, newest first). Uploaded with `WorkshopTool update -minor -namedesc up` (version stays 1.02, change note `Added a changelog to the description.`). **verified** from `GetPublishedFileDetails`: the live description is the `content.xml` text, 1247 characters, ending with the changelog. `lastupdate="1793025195"`. For each later update: add a line at the top of the changelog in the release `content.xml` and pass `-namedesc up`.

Also on 2026-10-26 the **Suggested mods** section went on the page (user reviewed the wording: praise the two mods, but not too much). The mod names are Steam `[url=...]` links. The same text shows in the in-game extension menu, where the tags appear as raw text (user's choice). Uploaded with `WorkshopTool update -buildcat -minor -namedesc up -changenote "Added suggested mods to the description."`, confirmed with `y` on stdin (exit 0, version stays 1.02, `lastupdate="1793044040"`). **verified** from `GetPublishedFileDetails` (result 1, visibility 0, 1874 characters) and from the item page HTML, which renders both names as `bb_link` anchors to items 3754773002 and 3797254195. The release `content.xml` from before this change is `H:\dev\esr-release\content.xml.bak-20261026-pairings`.

Page: <https://steamcommunity.com/sharedfiles/filedetails/?id=3821053684>

The upload used a copy at `H:\dev\esr-release\station_rebuilder`, not the dev junction. `WorkshopTool` rewrote that copy's `content.xml` to `id="ws_3821053684"` and `sync="false"`. The dev `extension/content.xml` was not changed. In the copy, ships, cargo and workforce default on, and the log-only refund option is not in the menu (D-17).

Since 2026-10-26 (D-22) `extension/` holds the same scripts as the release, so the copy is built from it. Before the next upload, replace `md/`, `ui/` and `ui.xml` in the release folder with the ones from `extension/` and keep the release folder's own `content.xml` (bump `version` and `date`). Do not copy the dev `content.xml`: its id is `station_rebuilder`, not `ws_3821053684`.

Images, from the repo root. The preview is the thumbnail. The other two are additional previews (Steam file names `02-cargo.jpg` and `03-settings.png`).

| File | Role |
|------|------|
| `cargo on build storage.jpg` | Preview. Station planner, Asteroid Belt High Tech Factory II. |
| `station cargo.jpg` | Additional. Logical overview, cargo and 41,250 workforce. |
| `mod settings.png` | Additional. Extension Options, the three protections on. |

The dev junction is still `station_rebuilder` in the profile. The Workshop copy uses the same folder name. Do not subscribe in this profile while that junction is linked.

### Page

Title: **Easy Station Rebuild**

The page text below is for players. [README.md](../README.md) is for people installing from the repository and covers how the scripts work. English only. The Workshop page does not localise. The same text is the `description` attribute further down. On the first upload the tool publishes that attribute as the Workshop description, and the game shows the Workshop text in the extension menu (Egosoft wiki, last modified 2023-09-22).

**How the top pages read.** Verified 2026-10-16 from the Steam Web API (`GetPublishedFileDetails`) for the top 10 all-time, Top Rated, ready-to-use items: Sector Explorer, Faster Crew Leveling, Fly-by Looting, SirNukes Mod Support APIs, Inventory Collector, Better Kill Credit, ATF Freyr Battlecarrier, Capital Ship Loot Magnet, Fly-by Lockbox, Variety and Rebalance Overhaul. The part a player reads first is short. Fly-by Lockbox is one short paragraph. SirNukes Mod Support APIs and Capital Ship Loot Magnet are about 90 words. Fly-by Looting and Better Kill Credit are about 110–120 words. Inventory Collector and Sector Explorer run nearer 200 words, and then a changelog that grew on the page over the years. Headings show up when the page has a question list or a feature list (Faster Crew Leveling, the Freyr, Variety and Rebalance Overhaul). The gameplay mods open with what the mod does, often "This mod", then a few short paragraphs, the limit a player will hit, another mod by name when one is needed, and a single line such as "Version 7.x compatible." The text below follows that shape. 175 words, plain paragraphs, no headings. A changelog stays off the first upload. Later updates leave the Workshop text in place unless `-namedesc up` is passed.

This mod keeps the ships, cargo and workers on your stations when you confirm a new construction plan.

Docked ships move off the modules that are coming down and wait nearby. A ship that can't get out is teleported away. The ship you are flying stays put.

Cargo that no longer fits goes into that station's build storage, and is put back when there is room.

Workers stay for 2 hours while new housing is built. After that, workers who still have nowhere to live leave at 20% of those still waiting each hour. New housing takes them back as soon as there is room.

Safe to add or remove mid-game. Only your own stations. Build time and cost stay the same. The game can still take down a module that your new plan keeps, and build it again.

With SirNukes Mod Support APIs you can turn ships, cargo or workers off, and change the wait and the leave rate, under Extension Options. Without it, the settings above are used.

Suggested mods
If you rebuild stations often, these two are worth a look:
- [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3754773002]Build Storage: Station Drone Self-Supply[/url] (by Simucad). The station's own drones carry wares it already has into build storage, so a rebuild doesn't have to wait for traders.
- [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3797254195]XBuilder[/url] (by Lord Starwolf). It lets you put more construction ships on a station that is already being built, so big rebuilds finish sooner.
Both need SirNukes Mod Support APIs.

For X4 9.00 or newer.

Changelog
2026-10-26 (1.02): Added suggested mods.
2026-10-26 (1.02): Parked ships go back to their orders after 3 minutes. Ships that dock at a module being removed later are moved too. New Enable debug log option (off), and old save data is cleaned up.
2026-10-16 (1.01): Ships, cargo and workers start on.
2026-10-16 (1.00): First release.

The page does not mention module refunds. The game already returns those materials (D-17).

Dependency to show on the page: SirNukes Mod Support APIs, optional, Workshop id 2042901274 (`ws_2042901274` in `content.xml`). Minimum game version 9.00 (`<dependency version="900"/>`). The dependency is named in the text above. The `<dependency>` entry is what the extension menu lists.

First version: **1.00**, which is `version="100"` (D-20). The attribute is the displayed version times 100. First change note: `First release.` Update **1.01** is `version="101"` (D-21). Change note: `Ships, cargo and workforce now start on.`

### Release content.xml

The `&#10;` sequences are line breaks. The Egosoft wiki says `\n` does not work in this attribute (wiki text, last modified 2023-09-22). Set `date` to the day of the upload. The tool replaces `id` when the upload succeeds. `author="Dant"` (D-19) is the name in the extension menu and on the Workshop page. The MIT lines in `LICENSE` and `README.md` keep the legal name.

```xml
<?xml version="1.0" encoding="utf-8"?>
<content id="station_rebuilder" name="Easy Station Rebuild" description="This mod keeps the ships, cargo and workers on your stations when you confirm a new construction plan.&#10;&#10;Docked ships move off the modules that are coming down and wait nearby. A ship that can't get out is teleported away. The ship you are flying stays put.&#10;&#10;Cargo that no longer fits goes into that station's build storage, and is put back when there is room.&#10;&#10;Workers stay for 2 hours while new housing is built. After that, workers who still have nowhere to live leave at 20% of those still waiting each hour. New housing takes them back as soon as there is room.&#10;&#10;Safe to add or remove mid-game. Only your own stations. Build time and cost stay the same. The game can still take down a module that your new plan keeps, and build it again.&#10;&#10;With SirNukes Mod Support APIs you can turn ships, cargo or workers off, and change the wait and the leave rate, under Extension Options. Without it, the settings above are used.&#10;&#10;Suggested mods&#10;If you rebuild stations often, these two are worth a look:&#10;- [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3754773002]Build Storage: Station Drone Self-Supply[/url] (by Simucad). The station's own drones carry wares it already has into build storage, so a rebuild doesn't have to wait for traders.&#10;- [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3797254195]XBuilder[/url] (by Lord Starwolf). It lets you put more construction ships on a station that is already being built, so big rebuilds finish sooner.&#10;Both need SirNukes Mod Support APIs.&#10;&#10;For X4 9.00 or newer.&#10;&#10;Changelog&#10;2026-10-26 (1.02): Added suggested mods.&#10;2026-10-26 (1.02): Parked ships go back to their orders after 3 minutes. Ships that dock at a module being removed later are moved too. New Enable debug log option (off), and old save data is cleaned up.&#10;2026-10-16 (1.01): Ships, cargo and workers start on.&#10;2026-10-16 (1.00): First release." author="Dant" version="102" date="YYYY-MM-DD" save="false" enabled="1">
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

The preview used for this upload is `cargo on build storage.jpg` (1920×1080). The other two repo-root images are additional previews.

### Still to do

- Try a rebuild with each suggested mod installed (Phase 7, user). If one turns out not to work with this mod, change or remove its line on the page.

