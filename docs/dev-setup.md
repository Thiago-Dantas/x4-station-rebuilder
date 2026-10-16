# Dev setup

Windows 10, game 9.00 on Steam. Installs go on H: (or D:), not C:.

## Tools
| Tool | Where | Used for |
|------|-------|----------|
| Python 3.11 | system install (`python`) | `tools/*.py`; always run with `-I` |
| lxml 5.4 | system Python (was already installed) | schema validation in `tools/check.py` |
| luaparser 4.2 | `H:\dev\pylibs\luaparser` (installed 2026-10-15 with `python -m pip install --target H:\dev\pylibs\luaparser luaparser`) | Lua syntax check in `tools/check.py`; override the path with `ESR_LUAPARSER` |
| PowerShell 7 (`pwsh`) | system | `tools/link-dev.ps1` |
| capstone 5.0.9, pefile 2024.8.26 | `H:\dev\pylibs\disasm` (installed 2026-10-15) | disassembling single `X4.exe` functions and finding references to globals (scratch scripts; see docs/x4-modding.md, "How the engine computes module refunds") |
| Ghidra 12.1.4 + JDK 21 | `C:\tools\ghidra_12.1.4_PUBLIC`, `C:\tools\jdk-21.0.12.1+1` (already installed, used by REA) | `analyzeHeadless` needs `JAVA_HOME` set to the JDK 21. Import `X4.exe` once with `-noanalysis`, then decompile chosen addresses with a small post-script; full auto-analysis of the 55 MB binary exceeds REA's startup deadline |
| `x4cat.py` | `..\x4-station-designer\tools\x4cat.py` | extracting game files |

## Game files for the checks (git-ignored)
`tools/check.py` needs the game's schemas and scripts in `research/extracted/base/`:
```
$G = "F:\SteamLibrary\steamapps\common\X4 Foundations"
python -I ..\x4-station-designer\tools\x4cat.py extract "$G\08.cat" research\extracted\base "md/*" "aiscripts/*" "ui/addons/ego_*/*.lua" "ui/addons/*/ui.xml" "libraries/*.xsd" libraries/scriptproperties.xml libraries/parameters.xml libraries/wares.xml
```
`ui/core/addon.xsd` and `coreaddon.xsd` are in another catalog; loop over `01.cat` … `09.cat` with the pattern `ui/core/*.xsd`. On 9.00 everything above came from `08.cat` except those two.

## Commands
| Command | What |
|---------|------|
| `python -I tools/check.py` | All offline checks (≈2.5 min, mostly compiling `md.xsd`): `content.xml`, `ui.xml` vs `addon.xsd`, MD vs `md.xsd`, AI scripts vs `aiscripts.xsd`, `md.<Script>.<Cue>` references, property names vs `scriptproperties.xml`, Lua syntax. Exit code 0 = pass. |
| `pwsh tools/link-dev.ps1` | Dev install (junction into the profile's `extensions\`); `-Remove` undoes it |
| `python -I tools/esr_log.py [log] [--errors]` | Our lines from `debuglog.txt` |

## What the offline checks can't catch
Expressions in MD attributes are only checked for unknown property names. A property used on the wrong type, a wrong event parameter, or a runtime null only shows up in game, as an `[=ERROR=]` line naming our file and line. Every in-game session should end with `tools/esr_log.py --errors`.
