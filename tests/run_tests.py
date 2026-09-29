#!/usr/bin/env python3
"""
Unit tests for the parts of the script that do not need a real Roblox client.

    python3 tests/run_tests.py

Requires the `lupa` package (Lua 5.4 inside Python):
    pip install lupa
"""
import sys
from pathlib import Path

try:
    import lupa
except ImportError:
    print("SKIP: lupa not installed (pip install lupa)")
    raise SystemExit(0)

ROOT = Path(__file__).resolve().parent.parent
MODULES = ROOT / "src" / "modules"
TESTS = Path(__file__).resolve().parent

failures = []
checks = 0


def check(label, got, want):
    global checks
    checks += 1
    if got != want:
        failures.append(f"{label}: got {got!r}, want {want!r}")
        print(f"  FAIL  {label}: got {got!r}, want {want!r}")
    else:
        print(f"  ok    {label} = {got!r}")


def check_true(label, got):
    check(label, bool(got), True)


def main():
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)

    # 1) every module must at least COMPILE (catches syntax errors)
    print("[1] syntax check")
    for f in sorted(MODULES.glob("*.lua")):
        try:
            lua.compile(f.read_text(encoding="utf-8"), name=f.name)
            print(f"  ok    {f.name} compiles")
        except Exception as exc:  # noqa: BLE001
            failures.append(f"{f.name} does not compile: {exc}")
            print(f"  FAIL  {f.name}: {exc}")

    # 2) load the Roblox stub + Core + EggDB
    print("\n[2] load Core + EggDB under the test stub")
    lua.execute((TESTS / "roblox_stub.lua").read_text(encoding="utf-8"))
    lua.execute((MODULES / "01_Core.lua").read_text(encoding="utf-8"))
    lua.execute((MODULES / "02_EggDB.lua").read_text(encoding="utf-8"))
    print("  ok    loaded")

    ev = lua.eval

    # ---------- database ----------
    print("\n[3] egg database")
    check("egg count", ev("function() return #SaB.EggDB.EGGS end")(), 35)
    check("islands", ev("function() return #SaB.EggDB.ISLANDS end")(), 8)

    check("lookup exact",
          ev("function() local e = SaB.EggDB.lookup('Dragon Cannelloni'); return e and e.r end")(),
          "Secret")
    check("lookup island",
          ev("function() local e = SaB.EggDB.lookup('Dragon Cannelloni'); return e and e.i end")(),
          "Heavenly")
    check("lookup income",
          ev("function() local e = SaB.EggDB.lookup('Dragon Cannelloni'); return e and e.inc end")(),
          250000000)
    check("lookup fuzzy (object name)",
          ev("function() local e = SaB.EggDB.lookup('Egg_DragonCannelloni_3'); return e and e.n end")(),
          "Dragon Cannelloni")
    check("lookup fuzzy (spaces stripped)",
          ev("function() local e = SaB.EggDB.lookup('to to to sahur'); return e and e.r end")(),
          "Secret")
    check("lookup miss",
          ev("function() return SaB.EggDB.lookup('Random Thing') end")(),
          None)
    check("lookup every egg by its own name",
          ev("function() local n=0 for _,e in ipairs(SaB.EggDB.EGGS) do if SaB.EggDB.lookup(e.n)==e then n=n+1 end end return n end")(),
          35)

    # ---------- classify ----------
    print("\n[4] classify")
    check("classify known",
          ev("function() local c = SaB.EggDB.classify('Lavamanta'); return c.rarity .. '/' .. c.island end")(),
          "Secret/Lava")
    check("classify unknown object",
          ev("function() local c = SaB.EggDB.classify('Egg_27'); return c.known end")(),
          False)
    check("rarity from text",
          ev("function() return SaB.EggDB.classify('Secret Egg').rarity end")(),
          "Secret")
    check("brainrot god from text",
          ev("function() return SaB.EggDB.classify('Brainrot God Egg').rarity end")(),
          "Brainrot God")
    check("island from text",
          ev("function() return SaB.EggDB.islandFromText('Workspace.Islands.HeavenlyIsland') end")(),
          "Heavenly")
    check("island from lava path",
          ev("function() return SaB.EggDB.islandFromText('LavaZone/Eggs/Egg2') end")(),
          "Lava")
    check("no island",
          ev("function() return SaB.EggDB.islandFromText('Workspace/Part') end")(),
          None)
    check("display name from object name",
          ev("function() return SaB.EggDB.displayName('egg_03') end")(),
          "Egg")
    check("display name from db",
          ev("function() return SaB.EggDB.displayName('Cerberus_1') end")(),
          "Cerberus")

    # ---------- keywords ----------
    print("\n[5] detection keywords")
    check_true("egg word", ev("function() return SaB.EggDB.isEggWord('LuckyEgg_2') end")())
    check_true("container word", ev("function() return SaB.EggDB.isContainerWord('Eggs') end")())
    check_true("prompt word", ev("function() return SaB.EggDB.isPromptWord('Collect Egg') end")())
    check("not a prompt word",
          ev("function() return SaB.EggDB.isPromptWord('Shop') end")(),
          False)

    # ---------- rarity ----------
    print("\n[6] rarity")
    check("rarity tiers count", ev("function() return #SaB.Rarity.ORDER end")(), 10)
    check("tier secret > mythic",
          ev("function() return SaB.Rarity.tier('Secret') > SaB.Rarity.tier('Mythic') end")(),
          True)
    check("unknown tier 0", ev("function() return SaB.Rarity.tier('Unknown') end")(), 0)
    check("normalize god",
          ev("function() return SaB.Rarity.normalize('Brainrot God') end")(),
          "Brainrot God")
    check("normalize bg", ev("function() return SaB.Rarity.normalize('bg') end")(), "Brainrot God")
    check("every rarity has a colour",
          ev("function() local n=0 for _,r in ipairs(SaB.Rarity.ORDER) do if SaB.Rarity.color(r) then n=n+1 end end return n end")(),
          10)

    # ---------- utils ----------
    print("\n[7] utilities")
    check("key()", ev("function() return SaB.Util.key('To to to Sahur!') end")(), "tototosahur")
    check("formatNumber M", ev("function() return SaB.Util.formatNumber(250000000) end")(), "250.0M")
    check("formatNumber K", ev("function() return SaB.Util.formatNumber(7500) end")(), "7.5K")
    check("formatDistance", ev("function() return SaB.Util.formatDistance(1234) end")(), "1.2km")
    check("formatClock", ev("function() return SaB.Util.formatClock(65) end")(), "1:05")
    check("split", ev("function() return #SaB.Util.split('dragon, cerberus ,, yeti') end")(), 3)
    check("clamp", ev("function() return SaB.Util.clamp(99, 0, 10) end")(), 10)
    check("prettyName", ev("function() return SaB.Util.prettyName('grass_egg_01') end")(), "Grass Egg 01")

    # ---------- settings (de)serializer ----------
    print("\n[8] saved settings (encode / decode)")
    check("encode + decode a number",
          ev("function() local t = SaB.Util.decodeSettings(SaB.Util.encodeSettings({a=5})) return t.a end")(),
          5)
    check("encode + decode a boolean",
          ev("function() local t = SaB.Util.decodeSettings(SaB.Util.encodeSettings({b=true, c=false})) return tostring(t.b) .. tostring(t.c) end")(),
          "truefalse")
    check("encode + decode a string",
          ev("function() local t = SaB.Util.decodeSettings(SaB.Util.encodeSettings({s='dragon egg'})) return t.s end")(),
          "dragon egg")
    check("encode + decode a list",
          ev("function() local t = SaB.Util.decodeSettings(SaB.Util.encodeSettings({l={'a','b','c'}})) return table.concat(t.l, ',') end")(),
          "a,b,c")
    check("the whole config survives a round trip",
          ev("function() local t = SaB.Util.decodeSettings(SaB.Util.encodeSettings(SaB.CONFIG)) return t.EggMinConfidence end")(),
          60)

    # ---------- summary ----------
    print("\n" + "-" * 50)
    if failures:
        print(f"FAILED  {len(failures)}/{checks + len(failures)} checks")
        for f in failures:
            print("   - " + f)
        return 1
    print(f"PASSED  {checks} checks")
    return 0


if __name__ == "__main__":
    sys.exit(main())
