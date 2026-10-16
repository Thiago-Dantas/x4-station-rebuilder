"""Pull the mod's lines out of the game log.

    python -I tools/esr_log.py [debuglog.txt] [--errors]

Prints every line containing "[ESR]" from the game's debuglog.txt (default: the profile's
log under %USERPROFILE%\\Documents\\Egosoft\\X4\\<profile id>\\debuglog.txt, the newest one).
With --errors it also prints script errors that mention our files (esr_*, ESR_*, station_rebuilder),
so a broken expression in our scripts shows up next to our own output.
"""
import glob
import os
import sys


def default_log():
    pattern = os.path.join(os.environ.get("USERPROFILE", ""), "Documents", "Egosoft", "X4", "*", "debuglog.txt")
    logs = glob.glob(pattern)
    return max(logs, key=os.path.getmtime) if logs else None


def main(argv):
    errors = "--errors" in argv
    args = [a for a in argv if not a.startswith("--")]
    path = args[0] if args else default_log()
    if not path or not os.path.exists(path):
        print("no debuglog.txt found; start the game with -debug all -logfile debuglog.txt", file=sys.stderr)
        return 1
    ours = ("esr_", "ESR_", "station_rebuilder")
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            if "[ESR]" in line or (errors and any(tag in line for tag in ours)):
                sys.stdout.write(line)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
