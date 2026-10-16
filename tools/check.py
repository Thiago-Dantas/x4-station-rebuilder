"""Offline checks for the mod in extension/ and the test harness in extension_test/ (no game needed).

    python -I tools/check.py

- content.xml: well-formed, id station_rebuilder
- ui.xml against the game's ui/core/addon.xsd
- md/*.xml against the game's libraries/md.xsd, aiscripts/*.xml against libraries/aiscripts.xsd
- md.<Script>.<Cue> references and run_actions refs point at scripts and cues that exist
  (ours, or the game's own md/ files)
- every .property in our expressions is a name from the game's scriptproperties.xml (typo check)
- every .lua file parses (luaparser; LuaJIT syntax is Lua 5.1, which it accepts)

Schemas and game scripts come from research/extracted/base/ (git-ignored; extract them with
the designer's tools/x4cat.py, see docs/dev-setup.md). luaparser is looked up in
H:\\dev\\pylibs\\luaparser or the ESR_LUAPARSER environment variable.
Exit code 0 when everything passes.
"""
import glob
import os
import re
import sys

from lxml import etree

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# extension folder -> expected content.xml id (the mod, and the test harness that is never published)
EXTENSIONS = {"extension": "station_rebuilder", "extension_test": "station_rebuilder_test"}
BASE = os.path.join(ROOT, "research", "extracted", "base")
LUAPARSER = os.environ.get("ESR_LUAPARSER", r"H:\dev\pylibs\luaparser")

failures = []


def fail(msg):
    failures.append(msg)
    print("FAIL", msg)


def ok(msg):
    print("ok  ", msg)


def rel(path):
    try:
        return os.path.relpath(path, ROOT)
    except ValueError:  # another drive
        return path


def validate(files, xsd):
    if not files:
        return
    if not os.path.exists(xsd):
        fail(f"schema missing: {rel(xsd)} (extract it, see docs/dev-setup.md)")
        return
    schema = etree.XMLSchema(etree.parse(xsd))
    for path in files:
        try:
            doc = etree.parse(path)
        except etree.XMLSyntaxError as e:
            fail(f"{rel(path)}: not well-formed: {e}")
            continue
        if schema.validate(doc):
            ok(f"{rel(path)} valid against {os.path.basename(xsd)}")
        else:
            for e in schema.error_log:
                fail(f"{rel(path)}:{e.line}: {e.message}")


def check_content(ext, expected):
    path = os.path.join(ext, "content.xml")
    try:
        root = etree.parse(path).getroot()
    except (OSError, etree.XMLSyntaxError) as e:
        fail(f"content.xml: {e}")
        return
    if root.get("id") != expected:
        fail(f"{rel(path)}: id is {root.get('id')!r}, expected {expected!r}")
    else:
        ok(f"{rel(path)} id {expected}")


def md_cues(paths):
    """Script name -> set of cue and library names."""
    result = {}
    for path in paths:
        try:
            root = etree.parse(path).getroot()
        except etree.XMLSyntaxError:
            continue
        if root.tag != "mdscript":
            continue
        names = {el.get("name") for el in root.iter("cue", "library") if el.get("name")}
        result[root.get("name")] = names
    return result


def check_references(ours):
    known = md_cues(glob.glob(os.path.join(BASE, "md", "*.xml")))
    # optional dependency (D-5, D-14): SirNukes Mod Support APIs, extracted next to the game files
    known.update(md_cues(glob.glob(os.path.join(ROOT, "research", "extracted", "sn_mod_support_apis", "md", "*.xml"))))
    known.update(md_cues(ours))
    # md.Script.Cue (followed by . or a quote/space/bracket); case matters in MD
    pattern = re.compile(r"\bmd\.([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)")
    count = 0
    for path in ours:
        root = etree.parse(path).getroot()
        own = root.get("name")
        for el in root.iter():
            for attr, value in el.attrib.items():
                for script, cue in pattern.findall(value):
                    count += 1
                    if script not in known:
                        fail(f"{rel(path)}:{el.sourceline}: unknown script md.{script}")
                    elif cue not in known[script]:
                        fail(f"{rel(path)}:{el.sourceline}: md.{script} has no cue or library {cue}")
            if el.tag == "run_actions":
                ref = el.get("ref", "")
                if not ref.startswith("md.") and ref not in known.get(own, set()):
                    fail(f"{rel(path)}:{el.sourceline}: run_actions ref {ref} not found in {own}")
        # the schema allows <return> anywhere, but the game rejects a cue that uses it (run 4): libraries only
        for el in root.iter("return"):
            owner = next((a for a in el.iterancestors() if a.tag in ("cue", "library")), None)
            if owner is not None and owner.tag == "cue":
                fail(f"{rel(path)}:{el.sourceline}: <return> in cue {owner.get('name')}; only libraries may return")
        names = [el.get("name") for el in root.iter("cue", "library") if el.get("name")]
        dupes = {n for n in names if names.count(n) > 1}
        if dupes:
            fail(f"{rel(path)}: duplicate cue names {sorted(dupes)}")
    ok(f"{count} md.<Script>.<Cue> references checked")


def check_properties(ours, aiscripts):
    """Every .property in our expressions must be a property or keyword name somewhere in
    scriptproperties.xml. Only catches unknown words (typos), not a property used on the wrong type."""
    path = os.path.join(BASE, "libraries", "scriptproperties.xml")
    if not os.path.exists(path):
        fail(f"missing {rel(path)} (extract it, see docs/dev-setup.md)")
        return
    words = {"all", "construction", "operational", "wreck"}  # modules.<state>, named only in the docs
    keywords = set()
    for el in etree.parse(path).getroot().iter():
        name = el.get("name") if isinstance(el.tag, str) else None
        if name:
            words.update(s for s in re.split(r"[.\s]", re.sub(r"\{[^}]*\}|<[^>]*>", "", name)) if s)
            if el.tag == "keyword":
                keywords.add(name)
    # keyword values are engine-defined (class.storage, race.terran, ...); take the ones vanilla scripts use,
    # plus the isclass.<class> shortcut
    after = re.compile(r"\b(" + "|".join(sorted(map(re.escape, keywords | {"isclass"}))) + r")\.([a-z_][a-z0-9_]*)")
    for file in glob.glob(os.path.join(BASE, "md", "*.xml")) + glob.glob(os.path.join(BASE, "aiscripts", "*.xml")):
        with open(file, encoding="utf-8-sig", errors="replace") as f:
            words.update(value for _, value in after.findall(f.read()))
    count = 0
    for file in ours + aiscripts:
        for el in etree.parse(file).getroot().iter():
            if not isinstance(el.tag, str):
                continue
            for attr, value in el.attrib.items():
                if attr in ("comment", "xsi:noNamespaceSchemaLocation") or attr.startswith("{"):
                    continue
                expr = re.sub(r"'[^']*'", "''", value)  # drop string literals
                for word in re.findall(r"\.([a-z][A-Za-z0-9_]*)", expr):
                    count += 1
                    if word not in words:
                        fail(f"{rel(file)}:{el.sourceline}: unknown property .{word}")
    ok(f"{count} property names checked")


def check_lua(exts):
    files = [f for ext in exts for f in glob.glob(os.path.join(ext, "**", "*.lua"), recursive=True)]
    if not files:
        return
    if os.path.isdir(LUAPARSER) and LUAPARSER not in sys.path:
        sys.path.insert(0, LUAPARSER)
    try:
        from luaparser import ast
    except ImportError:
        fail(f"luaparser not found ({LUAPARSER}); install: python -m pip install --target H:\\dev\\pylibs\\luaparser luaparser")
        return
    for path in files:
        with open(path, encoding="utf-8-sig") as f:
            source = f.read()
        try:
            ast.parse(source)
            ok(f"{rel(path)} parses")
        except Exception as e:  # luaparser raises its own exception types
            fail(f"{rel(path)}: {str(e)[:300]}")


def main():
    exts = [os.path.join(ROOT, name) for name in EXTENSIONS]
    for ext, expected in zip(exts, EXTENSIONS.values()):
        check_content(ext, expected)
    validate([os.path.join(e, "ui.xml") for e in exts if os.path.exists(os.path.join(e, "ui.xml"))],
             os.path.join(BASE, "ui", "core", "addon.xsd"))
    md = sorted(f for e in exts for f in glob.glob(os.path.join(e, "md", "*.xml")))
    ai = sorted(f for e in exts for f in glob.glob(os.path.join(e, "aiscripts", "*.xml")))
    validate(md, os.path.join(BASE, "libraries", "md.xsd"))
    validate(ai, os.path.join(BASE, "libraries", "aiscripts.xsd"))
    check_references(md)
    check_properties(md, ai)
    check_lua(exts)
    print()
    print(f"{len(failures)} failure(s)" if failures else "all checks passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
