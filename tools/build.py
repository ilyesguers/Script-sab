#!/usr/bin/env python3
"""
Build the single-file Delta script (src/StealABrainrot.lua) by concatenating
every module in src/modules in alphabetical order.

Why: Delta (and most mobile executors) take ONE pasted script, but we want to
keep the source organised in small files that are easy to review / edit.

Usage:  python3 tools/build.py
"""
from pathlib import Path
import datetime
import sys

ROOT = Path(__file__).resolve().parent.parent
MODULES = ROOT / "src" / "modules"
OUT = ROOT / "src" / "StealABrainrot.lua"

BANNER = """--[[ =====================================================================
     STEAL A BRAINROT SUITE  v{version}   ({date})
     ---------------------------------------------------------------------
     GENERATED FILE - do not edit by hand.
     Edit the modules in src/modules/ then run:  python3 tools/build.py

     Modules packed in this build:
{modules}

     FEATURES
       1. EGG SYSTEM   : deep detection (7 strategies, live tracking) ,
                         rarity-coloured ESP , filters , auto farm
                         (approach -> pick up -> return to base -> hatch)
       2. CODE SNIPER  : listens to SpyderSammy , builds the code word by
                         word , writes it into the code box , full TEST mode
       3. DIAGNOSTICS  : one-click reports (copy / save to file) so we can
                         hard-code the real object paths later

     UI: draggable / minimizable / closable - works with mouse + touch
     ===================================================================== ]]
"""

FOOTER = """
--[[ ===================== end of build ===================== ]]
print(("[SaB Suite] v%s loaded - Eggs tab is the main tab."):format(SaB.VERSION))
"""


def strip_trailing_return(body: str) -> str:
    """Remove a final `return X` line (modules keep it so dofile() works)."""
    import re
    lines = body.rstrip().split("\n")
    while lines and lines[-1].strip() == "":
        lines.pop()
    if lines and re.fullmatch(r"return\s+[A-Za-z_][\w.]*\s*", lines[-1].strip()):
        lines.pop()
    return "\n".join(lines) + "\n"


def read_version() -> str:
    core = MODULES / "01_Core.lua"
    for line in core.read_text(encoding="utf-8").splitlines():
        if "VERSION" in line and "=" in line:
            return line.split("=", 1)[1].strip().strip('",')
    return "0.0.0"


def main() -> int:
    files = sorted(MODULES.glob("*.lua"))
    if not files:
        print("no modules found in", MODULES, file=sys.stderr)
        return 1

    parts = [BANNER.format(
        version=read_version(),
        date=datetime.date.today().isoformat(),
        modules="\n".join("       - " + f.name for f in files),
    )]

    for f in files:
        parts.append("\n--==============================================================\n"
                     "--  MODULE: %s\n"
                     "--==============================================================\n" % f.name)
        body = f.read_text(encoding="utf-8").rstrip() + "\n"
        # modules may end with "return X" so they can be dofile()'d in tests,
        # but a top-level return inside the packed chunk would stop the script.
        body = strip_trailing_return(body)
        parts.append(body)

    parts.append(FOOTER % read_version())
    OUT.write_text("".join(parts), encoding="utf-8")
    print("built %s  (%d modules, %d lines)" % (
        OUT.relative_to(ROOT), len(files), OUT.read_text(encoding="utf-8").count("\n") + 1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
