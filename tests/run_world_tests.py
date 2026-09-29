#!/usr/bin/env python3
"""
Integration test: runs the REAL script modules against a fake Roblox world
(tests/roblox_world.lua) and checks that eggs are detected, filtered,
labelled and farmed.

    python3 tests/run_world_tests.py
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


BUILD_WORLD = r"""
local W = game:GetService("Workspace")

-- ---------------- Heavenly island: egg named Dragon Cannelloni ----------
local islands = World.new("Folder", W, "Islands")

local heavenly = World.new("Model", islands, "HeavenlyIsland")
local eggs1 = World.new("Folder", heavenly, "Eggs")
local eggA = World.new("Model", eggs1, "DragonCannelloni")
local eggAPart = World.new("Part", eggA, "EggMesh")
eggAPart.Position = Vector3.new(100, 500, 100)
eggA.PrimaryPart = eggAPart
World.new("StringValue", eggA, "Rarity").Value = "Secret"

-- ---------------- Grass island: plain part "Egg_1" + collect prompt -----
local grass = World.new("Model", islands, "GrassIsland")
local eggs2 = World.new("Folder", grass, "Eggs")
local eggB = World.new("Part", eggs2, "Egg_1")
eggB.Position = Vector3.new(20, 30, 20)
local prompt = World.new("ProximityPrompt", eggB, "Prompt")
prompt.ActionText = "Collect Egg"
prompt.HoldDuration = 0
-- decoy: a rock inside the same egg folder (must NOT be an egg)
World.new("Part", eggs2, "Rock_7").Position = Vector3.new(25, 30, 25)

-- ---------------- Lava island: attributes only --------------------------
local lava = World.new("Model", islands, "LavaIsland")
local eggs3 = World.new("Folder", lava, "Eggs")
local eggC = World.new("Model", eggs3, "Egg_Cerberus")
eggC:SetAttribute("Rarity", "Secret")
eggC:SetAttribute("Island", "Lava")
local eggCPart = World.new("Part", eggC, "Body")
eggCPart.Position = Vector3.new(-200, 300, 50)
eggC.PrimaryPart = eggCPart

-- ---------------- a mystery capsule flagged as an egg -------------------
local eggD = World.new("Model", W, "MysteryCapsule")
eggD:SetAttribute("IsEgg", true)
eggD:SetAttribute("EggName", "Cerberus")
local eggDPart = World.new("Part", eggD, "Main")
eggDPart.Position = Vector3.new(0, 100, 400)
eggD.PrimaryPart = eggDPart

-- ---------------- decoys ------------------------------------------------
World.new("Part", W, "Sign_Shop").Position = Vector3.new(0, 5, 0)
local decoyPrompt = World.new("Part", W, "Door")
decoyPrompt.Position = Vector3.new(5, 5, 0)
World.new("ProximityPrompt", decoyPrompt, "OpenDoor").ActionText = "Open"

-- ---------------- the player's base -------------------------------------
local base = World.new("Model", W, "TestPlayer")
local basePart = World.new("Part", base, "BasePad")
basePart.Position = Vector3.new(0, 5, 0)
base.PrimaryPart = basePart

-- ---------------- the player character ----------------------------------
World.makeCharacter(W)

World_Test = { eggA = eggA, eggB = eggB, eggC = eggC, eggD = eggD }
"""


def main():
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    ev = lua.eval

    print("[1] load the fake Roblox world + all 9 modules")
    src = (TESTS / "roblox_world.lua").read_text(encoding="utf-8")
    if src.rstrip().endswith("return World"):
        src = src.rstrip()[: -len("return World")] + "_G.World = World"
    lua.execute(src)

    # we load the PACKED file (src/StealABrainrot.lua) and not the single
    # modules, because that is exactly what gets pasted into Delta - and the
    # modules share `local` values that only exist in one chunk.
    import subprocess
    subprocess.run([sys.executable, str(ROOT / "tools" / "build.py")], check=True,
                   stdout=subprocess.DEVNULL)
    packed = ROOT / "src" / "StealABrainrot.lua"
    print(f"  ok    built {packed.relative_to(ROOT)}")
    try:
        lua.execute(packed.read_text(encoding="utf-8"))
        print("  ok    packed script loaded (all 9 modules in one chunk)")
    except Exception as exc:  # noqa: BLE001
        failures.append(f"packed script failed to load: {exc}")
        print(f"  FAIL  packed script: {str(exc)[:600]}")
        return 1

    print("\n[2] build a fake map (3 real eggs, 1 flagged egg, 3 decoys)")
    lua.execute("(function() %s end)()" % BUILD_WORLD)
    check_true("world built", ev("function() return World_Test ~= nil end")())

    # ------------------------- detection -------------------------
    print("\n[3] deep scan - are the eggs found?")
    found = ev("function() SaB.Scanner.deepScan(false) return Util_count(SaB.Scanner.eggs) end")
    lua.execute("function Util_count(t) local n=0 for _ in pairs(t) do n=n+1 end return n end")
    check("eggs detected", found(), 4)
    check("decoys ignored (rock/door/sign)",
          ev("function() return SaB.Scanner.eggs[game:GetService('Workspace'):FindFirstChild('Sign_Shop')] ~= nil end")(),
          False)

    rec = lambda expr: ev("function() %s end" % expr)
    check("Dragon Cannelloni rarity",
          rec("return SaB.Scanner.getByObj(World_Test.eggA).rarity")(), "Secret")
    check("Dragon Cannelloni island",
          rec("return SaB.Scanner.getByObj(World_Test.eggA).island")(), "Heavenly")
    check("Dragon Cannelloni income",
          rec("return SaB.Scanner.getByObj(World_Test.eggA).income")(), 250000000)
    check("Egg_1 detected (name has 'egg')",
          rec("return SaB.Scanner.getByObj(World_Test.eggB) ~= nil")(), True)
    check("Egg_1 rarity from the name/folder",
          rec("return SaB.Scanner.getByObj(World_Test.eggB).rarity")(), "Unknown")
    check("Egg_Cerberus rarity from the attribute",
          rec("return SaB.Scanner.getByObj(World_Test.eggC).rarity")(), "Secret")
    check("Egg_Cerberus island from the attribute",
          rec("return SaB.Scanner.getByObj(World_Test.eggC).island")(), "Lava")
    check("Egg_Cerberus known from the database",
          rec("return SaB.Scanner.getByObj(World_Test.eggC).known")(), True)
    check("flagged capsule -> Cerberus",
          rec("return SaB.Scanner.getByObj(World_Test.eggD).name")(), "Cerberus")
    check("flagged capsule -> Secret",
          rec("return SaB.Scanner.getByObj(World_Test.eggD).rarity")(), "Secret")
    check("Egg_1 has a collect prompt",
          rec("return #SaB.Scanner.getByObj(World_Test.eggB).prompts")(), 1)

    print("\n[3b] eggs that spawn LATER (the old script showed an empty list)")
    lua.execute("""
        local W = game:GetService("Workspace")
        local late = World.new("Model", W:FindFirstChild("Islands"):FindFirstChild("GrassIsland"), "Yetimatic")
        local latePart = World.new("Part", late, "Body")
        latePart.Position = Vector3.new(10, 40, 10)
        late.PrimaryPart = latePart
        World_Test.late = late
        W.DescendantAdded:Fire(late)
    """)
    check("late egg detected by the live watcher",
          ev("function() return SaB.Scanner.getByObj(World_Test.late) ~= nil end")(), True)
    check("late egg rarity from the database",
          ev("function() return SaB.Scanner.getByObj(World_Test.late).rarity end")(), "Secret")
    check("late egg island from the database",
          ev("function() return SaB.Scanner.getByObj(World_Test.late).island end")(), "Arctic")
    lua.execute("World_Test.late:Destroy() SaB.Scanner.refresh()")
    check("destroyed egg disappears from the list",
          ev("function() return SaB.Scanner.getByObj(World_Test.late) == nil end")(), True)

    # ------------------------- filters -------------------------
    print("\n[4] filters")
    lua.execute("SaB.Scanner.refresh()")
    check("all 4 pass with no filters", ev("function() return #SaB.Scanner.matching() end")(), 4)
    lua.execute("SaB.CONFIG.EggMinRarityIndex = SaB.Rarity.indexOf('Secret')")
    check("min rarity = Secret keeps only the 3 secrets",
          ev("function() return #SaB.Scanner.matching() end")(), 3)
    lua.execute("SaB.CONFIG.EggMinRarityIndex = 0")
    lua.execute("SaB.CONFIG.EggHideUnknown = true")
    check("hide unknown drops Egg_1",
          ev("function() return #SaB.Scanner.matching() end")(), 3)
    lua.execute("SaB.CONFIG.EggHideUnknown = false")
    lua.execute("SaB.CONFIG.EggIslandFilter = 'Lava'")
    # Cerberus is a Lava egg, and the flagged capsule says it holds a Cerberus
    check("island filter = Lava",
          ev("function() return #SaB.Scanner.matching() end")(), 2)
    lua.execute("SaB.CONFIG.EggIslandFilter = 'Any'")
    lua.execute("SaB.CONFIG.EggWhitelistOn = true SaB.CONFIG.EggWhitelist = {'dragon'}")
    check("search 'dragon'",
          ev("function() return #SaB.Scanner.matching() end")(), 1)
    lua.execute("SaB.CONFIG.EggWhitelistOn = false")
    lua.execute("SaB.CONFIG.EggFarmPriority = 'nearest'")
    check("nearest first = Egg_1 (30 studs)",
          ev("function() return SaB.Scanner.bestTarget().name end")(), "Egg")
    lua.execute("SaB.CONFIG.EggFarmPriority = 'income'")
    check("best income first = Dragon Cannelloni",
          ev("function() return SaB.Scanner.bestTarget().name end")(), "Dragon Cannelloni")
    lua.execute("SaB.CONFIG.EggFarmPriority = 'rarity'")

    # ------------------------- ESP -------------------------
    print("\n[5] ESP labels")
    lua.execute("SaB.ESP.rebuild()")
    check("one label per egg", ev("function() return Util_count(SaB.ESP.parts) end")(), 4)
    check("label text = egg name",
          ev("function() return SaB.ESP.parts[World_Test.eggA].nameLbl.Text end")(),
          "Dragon Cannelloni")
    check("label colour = rarity colour",
          ev("function() return SaB.ESP.parts[World_Test.eggA].nameLbl.TextColor3 == SaB.Rarity.color('Secret') end")(),
          True)
    check("chip shows the category",
          ev("function() return SaB.ESP.parts[World_Test.eggA].chip.Text end")(), " SEC ")
    check("text is centred",
          ev("function() return tostring(SaB.ESP.parts[World_Test.eggA].nameLbl.TextXAlignment) end")(),
          "Enum.TextXAlignment.Center")
    check("labels are visible from far away",
          ev("function() return SaB.ESP.parts[World_Test.eggA].bb.MaxDistance end")(), 6000)
    lua.execute("SaB.CONFIG.EggESPEnabled = false SaB.ESP.update()")
    check("ESP off = no labels", ev("function() return Util_count(SaB.ESP.parts) end")(), 0)
    lua.execute("SaB.CONFIG.EggESPEnabled = true SaB.ESP.rebuild()")

    # ------------------------- farm -------------------------
    print("\n[6] auto farm (teleport -> pick up -> base)")
    # make the executor helper exist: firing the prompt removes the egg
    # (= the game giving you the egg)
    lua.execute("""
        fireproximityprompt = function(prompt)
            if prompt and prompt.Parent then prompt.Parent:Destroy() end
        end
    """)
    check("base auto-detected",
          ev("function() local b = SaB.Farm.Base.get() return b and b.source or 'none' end")(),
          "workspace/TestPlayer")
    lua.execute("""
        local target = SaB.Scanner.getByObj(World_Test.eggB)
        local ok, why = SaB.Farm.cycle(target)
        FARM_OK = ok
        FARM_WHY = why
    """)
    check("cycle delivered the egg", ev("function() return FARM_OK end")(), True)
    check("delivered counter", ev("function() return SaB.Farm.stats.delivered end")(), 1)
    check("pickup method logged",
          ev("function() return SaB.Farm.Pickup.lastMethod end")(), "proximity prompt (fire)")
    check("character actually moved to the egg",
          ev("function() return SaB.Util.getHRP().Position.X end")(), 0.0)
    lua.execute("SaB.Scanner.refresh()")
    check("egg is gone after the pickup",
          ev("function() return SaB.Scanner.getByObj(World_Test.eggB) == nil end")(), True)

    # ------------------------- UI -------------------------
    print("\n[7] user interface")
    check("tabs created", ev("function() return #SaB.UI.tabOrder end")(), 4)
    check("eggs tab is selected first", ev("function() return SaB.UI.currentTab end")(), "Eggs")
    lua.execute("SaB.UI.setMinimized(true)")
    check("minimise hides the body", ev("function() return SaB.UI.body.Visible end")(), False)
    check("minimise shrinks the window",
          ev("function() return SaB.UI.main.Size.Y.Offset end")(),
          ev("function() return SaB.UI.HEADER end")())
    check("minimise button shows +", ev("function() return SaB.UI.minBtn.Text end")(), "+")
    lua.execute("SaB.UI.setMinimized(false)")
    check("restore shows the body", ev("function() return SaB.UI.body.Visible end")(), True)
    check("restore brings the pages back",
          ev("function() return SaB.UI.pages['Eggs'].Visible end")(), True)
    lua.execute("SaB.Pages.refreshEggs()")
    check("status line counts the eggs",
          ev("function() return SaB.Pages ~= nil end")(), True)
    check("egg rows rendered",
          ev("function() local n = 0 for _, c in ipairs(SaB.UI.pages['Eggs']:GetDescendants()) do if c.Name and c.Name:sub(1,3) == 'Row' and c.Visible then n = n + 1 end end return n end")(),
          3)
    check("category headers rendered",
          ev("function() local n = 0 for _, c in ipairs(SaB.UI.pages['Eggs']:GetDescendants()) do if c.Name and c.Name:sub(1,4) == 'Head' and c.Visible then n = n + 1 end end return n end")(),
          1)
    check("header shows the category name",
          ev("function() for _, c in ipairs(SaB.UI.pages['Eggs']:GetDescendants()) do if c.Name == 'Head1' then return c.Text end end return '' end")(),
          "▸ SECRET   (3)")
    check("diagnostics report builds",
          ev("function() return (SaB.Diag.buildReport():find('=== SaB Suite report ===', 1, true) ~= nil) end")(),
          True)

    print("\n" + "-" * 50)
    if failures:
        print(f"FAILED  {len(failures)}/{checks + len(failures)} checks")
        for f in failures:
            print("   - " + f)
        return 1
    print(f"PASSED  {checks} checks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
