--==============================================================
--  MAIN  (boot + welcome + smart hints)
--==============================================================

local Util    = SaB.Util
local CONFIG  = SaB.CONFIG
local Scanner = SaB.Scanner
local Farm    = SaB.Farm
local UI      = SaB.UI
local T       = SaB.Theme

Log.info(("SaB Suite v%s loaded - %d known eggs in the database")
    :format(SaB.VERSION, #SaB.EggDB.EGGS), T.ACC)
Log.eggs("first scan started (whole map) ...", T.DIM)

Util.notify("SaB Suite", ("v%s loaded - Eggs tab is open"):format(SaB.VERSION), 5)

-- when the character respawns the old positions are useless
SaB.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    pcall(function()
        Farm.Base.cached = nil
        Farm.Teleport.lastSafe = nil
    end)
end)

-- after 20 seconds: tell the user what is going on if nothing was found
task.spawn(function()
    task.wait(20)
    if not SaB.Running then return end
    local total = Util.tableCount(Scanner.eggs)
    if total == 0 then
        Log.warn("no eggs found in the first 20s - things to check:", T.WARN)
        Log.warn("  1) are you inside the LTM? (go through the portal)", T.WARN)
        Log.warn("  2) press 'DEEP SCAN NOW' in the Eggs tab", T.WARN)
        Log.warn("  3) open the DIAGNOSTICS tab -> BUILD FULL REPORT and send it", T.WARN)
        Util.notify("SaB Suite", "No eggs found yet - see the console / Diag tab", 6)
    else
        Log.ok(("%d eggs tracked - ESP is drawing labels"):format(total), T.OK)
    end
end)

-- keep the ESP in sync with the config (cheap, once every 2s)
task.spawn(function()
    while SaB.Running do
        task.wait(2)
        pcall(function()
            if not CONFIG.EggESPEnabled and Util.tableCount(SaB.ESP.parts) > 0 then
                SaB.ESP.clear()
            end
        end)
    end
end)

return SaB
