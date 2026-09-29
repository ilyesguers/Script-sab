--==============================================================
--  EXTRAS  (v2.2)
--     1. rare egg alerts   - "a SECRET egg just spawned!"
--     2. islands           - find them and teleport to them
--     3. AFK auto jump     - train XP on the trampoline hands free
--     4. saved settings    - keep your setup between sessions
--==============================================================

local Extras = {}
SaB.Extras = Extras

local CONFIG  = SaB.CONFIG
local Util    = SaB.Util

local Scanner = SaB.Scanner

--==============================================================
--  1) RARE EGG ALERTS
--==============================================================
Extras.alerts = {}
local lastNotify = 0

-- the egg database index -> rarity name (1 = Common ... 9 = Limited)
function Extras.alertValues()
    local out = {}
    for _, name in ipairs(SaB.Rarity.ORDER) do
        if name ~= "Unknown" then table.insert(out, name) end
    end
    return out
end

function Extras.alertRarity()
    return SaB.Rarity.fromIndex(CONFIG.EggAlertMinRarityIndex)
end

function Extras.shouldAlert(rec)
    if not CONFIG.EggAlertEnabled then return false end
    local min = Extras.alertRarity()
    if not min then return false end
    return (rec.tier or SaB.Rarity.tier(rec.rarity)) >= SaB.Rarity.tier(min)
end

function Extras.onAlert(rec)
    if not rec or rec.alerted then return end
    if not Extras.shouldAlert(rec) then return end
    rec.alerted = true

    local where = rec.island and ("  on " .. rec.island) or ""
    local text = ("%s  [%s]%s"):format(rec.name, rec.rarity, where)
    table.insert(Extras.alerts, {
        time = os.date("%H:%M:%S"), name = rec.name, rarity = rec.rarity,
    })
    if #Extras.alerts > 40 then table.remove(Extras.alerts, 1) end

    Log.eggs(("★ RARE EGG  %s  (%s away)"):format(text, Util.formatDistance(rec.dist)),
        SaB.Rarity.color(rec.rarity))
    if SaB.UI and SaB.UI.toastShow then
        SaB.UI.toastShow("★  " .. text, SaB.Rarity.color(rec.rarity), 5)
    end
    -- do not flood the Roblox notification queue
    local now = tick()
    if now - lastNotify > 4 then
        lastNotify = now
        Util.notify("★ " .. rec.rarity .. " egg!", rec.name .. where, 6)
    end
end

Scanner.onAlert = function(rec) pcall(Extras.onAlert, rec) end

--==============================================================
--  2) ISLANDS
--==============================================================
Extras.islands = {}
Extras.islandsAt = 0

local function considerIsland(obj, out, seen)
    if not obj then return end
    if not (obj:IsA("Folder") or obj:IsA("Model")) then return end
    local key = SaB.EggDB.islandFromText(obj.Name)
    if not key or seen[key] then return end
    local pos = Util.getPos(obj)
    if not pos then return end
    seen[key] = true
    table.insert(out, { obj = obj, key = key, name = obj.Name, pos = pos })
end

function Extras.findIslands(force)
    if not force and (tick() - Extras.islandsAt) < 10 and #Extras.islands > 0 then
        return Extras.islands
    end
    local out, seen = {}, {}
    for _, child in ipairs(SaB.Services.Workspace:GetChildren()) do
        considerIsland(child, out, seen)
        for _, g in ipairs(child:GetChildren()) do
            considerIsland(g, out, seen)
        end
    end
    table.sort(out, function(a, b)
        return SaB.EggDB.islandHeight(a.key) < SaB.EggDB.islandHeight(b.key)
    end)
    Extras.islands = out
    Extras.islandsAt = tick()
    return out
end

function Extras.islandColor(key)
    local isl = SaB.EggDB.ISLAND_BY_KEY[key]
    if isl and isl.color then
        return Color3.fromRGB(isl.color[1], isl.color[2], isl.color[3])
    end
    return SaB.Theme.ACC
end

function Extras.eggCountOn(key)
    local n = 0
    for _, rec in ipairs(Scanner.list or {}) do
        if rec.island == key then n = n + 1 end
    end
    return n
end

--==============================================================
--  3) AFK AUTO JUMP (trampoline XP)
--==============================================================
local AFK_WORDS = { "trampoline", "treadmill", "trampolin", "jump", "train", "gym", "xp" }

function Extras.findTrampoline()
    local count = 0
    for _, d in ipairs(SaB.Services.Workspace:GetDescendants()) do
        count = count + 1
        if count > 30000 then break end
        if d:IsA("Model") or d:IsA("BasePart") then
            local n = Util.lower(d.Name)
            for _, w in ipairs(AFK_WORDS) do
                if n:find(w, 1, true) then
                    local p = Util.getPos(d)
                    if p then
                        CONFIG.AfkTrampolineName = d.Name
                        return p, d.Name
                    end
                end
            end
        end
    end
    return nil
end

function Extras.afkJumpOnce()
    local hum = Util.getHumanoid()
    if not hum then return false end
    pcall(function() hum.Jump = true end)
    return true
end

-- go stand on the trampoline and start jumping
function Extras.goTrain()
    local pos, name = nil, CONFIG.AfkTrampolineName
    if name ~= "" then
        for _, d in ipairs(SaB.Services.Workspace:GetDescendants()) do
            if d.Name == name then
                pos = Util.getPos(d)
                break
            end
        end
    end
    if not pos then
        pos, name = Extras.findTrampoline()
    end
    if not pos then
        SaB.UI.toastShow("no trampoline found - jumping here", SaB.Theme.WARN, 3)
        Log.warn("AFK: no trampoline / treadmill found by name")
    else
        SaB.Farm.Teleport.to(pos)
        Log.ok("AFK: standing on " .. tostring(name), SaB.Theme.OK)
        SaB.UI.toastShow("training on " .. tostring(name), SaB.Theme.OK, 3)
    end
    CONFIG.AfkJump = true
end

task.spawn(function()
    while SaB.Running do
        task.wait(math.max(0.15, CONFIG.AfkJumpInterval))
        if CONFIG.AfkJump then
            pcall(function()
                if Util.isAlive() then Extras.afkJumpOnce() end
            end)
        end
    end
end)

--==============================================================
--  4) SAVED SETTINGS
--==============================================================
Extras.SETTINGS_FILE = "SaBSuite/settings.txt"

function Extras.save()
    local text = Util.encodeSettings(CONFIG)
    if not Util.writeFile("settings.txt", text) then
        return false, "writefile is not available on this executor"
    end
    return true, "saved"
end

function Extras.load()
    local data = Util.readSaved(Extras.SETTINGS_FILE)
    if not data then
        local plain = Util.readSaved("settings.txt")
        if not plain then return false, "no saved settings yet" end
        data = plain
    end
    local values = Util.decodeSettings(data)
    local n = 0
    for k, v in pairs(values) do
        if CONFIG[k] ~= nil and type(CONFIG[k]) == type(v) then
            CONFIG[k] = v
            n = n + 1
        end
    end
    return true, ("%d settings loaded"):format(n)
end

function Extras.delete()
    if typeof(delfile) == "function" then
        pcall(function() delfile(Extras.SETTINGS_FILE) end)
        return true, "deleted"
    end
    return false, "delfile is not available"
end

return Extras
