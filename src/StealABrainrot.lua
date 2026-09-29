--[[ =====================================================================
     STEAL A BRAINROT SUITE  v2.3.0   (2026-09-29)
     ---------------------------------------------------------------------
     GENERATED FILE - do not edit by hand.
     Edit the modules in src/modules/ then run:  python3 tools/build.py

     Modules packed in this build:
       - 01_Core.lua
       - 02_EggDB.lua
       - 03_EggScanner.lua
       - 04_EggESP.lua
       - 05_EggFarm.lua
       - 06_Sniper.lua
       - 07_UI.lua
       - 08_Pages.lua
       - 09_Extras.lua
       - 10_Main.lua

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

--==============================================================
--  MODULE: 01_Core.lua
--==============================================================
--==============================================================
--  CORE : services , config , theme , utilities , log
--==============================================================

local SaB = {
    VERSION = "2.3.0",
    NAME    = "SaB Suite",
    Running = true,
}

local Players                = game:GetService("Players")
local RunService            = game:GetService("RunService")
local UserInputService      = game:GetService("UserInputService")
local TextChatService       = game:GetService("TextChatService")
local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local Workspace             = game:GetService("Workspace")
local StarterGui            = game:GetService("StarterGui")
local ProximityPromptService= game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = Workspace.CurrentCamera or Workspace:FindFirstChildWhichIsA("Camera")

SaB.Services = {
    Players = Players, RunService = RunService, UserInputService = UserInputService,
    TextChatService = TextChatService, ReplicatedStorage = ReplicatedStorage,
    Workspace = Workspace, StarterGui = StarterGui,
    ProximityPromptService = ProximityPromptService,
}
SaB.LocalPlayer = LocalPlayer
SaB.PlayerGui   = PlayerGui

--==============================================================
--  CONFIG  (all defaults live here - the UI edits this table)
--==============================================================
SaB.CONFIG = {
    -- ---------- EGG DETECTION ----------
    EggESPEnabled      = true,    -- master switch for the labels
    EggEspName         = true,    -- show the egg name
    EggEspRarity       = true,    -- show the rarity chip
    EggEspDistance     = true,    -- show "123m"
    EggEspIsland       = true,    -- show the island name
    EggHighlight       = true,    -- glowing box around the egg
    EggAlwaysOnTop     = false,   -- see eggs through walls
    EggEspMaxDistance  = 6000,    -- studs (islands are HIGH - keep this big)
    EggLabelScale      = 1.0,     -- 0.7 .. 1.6
    EggLiveScan        = true,    -- watch for new eggs as they spawn
    EggScanInterval    = 1.0,     -- seconds between quick scans
    EggDeepScanInterval= 25,      -- seconds between full Workspace walks
    EggScanLimit       = 60000,   -- safety cap of objects per deep scan
    EggMinConfidence   = 60,      -- 0..100 - how sure we must be it is an egg
                                  -- (35 = loose  •  60 = normal  •  75 = strict)
    EggExtraKeywords   = "",      -- user keywords, comma separated

    -- ---------- FILTERS ----------
    EggMinRarityIndex  = 0,       -- 0 = any  (index into Rarity.ORDER)
    EggIslandFilter    = "Any",
    EggWhitelistOn     = false,
    EggWhitelist       = {},      -- {"dragon", "secret", ...}
    EggMaxDistance     = 0,       -- studs, 0 = unlimited
    EggHideUnknown     = false,   -- hide eggs with unknown rarity
    EggOnlyKnown       = false,   -- only eggs from the known database
    EggSkipFailed      = true,    -- skip eggs we failed to pick up recently

    -- ---------- AUTO FARM ----------
    EggAutoFarm        = false,
    EggFarmPriority    = "rarity",   -- rarity | nearest | income
    EggSafeTeleport    = true,       -- fly there instead of 1 jump (anti snap-back)
    EggStepSize        = 14,         -- studs per fallback step (smooth mode uses speed)
    EggStepDelay       = 0,          -- 0 = wait one frame between steps
    EggTpMode          = "smooth",   -- smooth | fast | instant
    EggTpSpeed         = 80,         -- studs / second (smooth fly)
    EggTpNoclip        = true,       -- no collision while flying (islands will not fling you)
    EggTpAntiRubber    = true,       -- if the server snaps you back, put yourself back on the path
    EggTpHoldArrive    = 0.45,       -- seconds to hold still on arrival so the server accepts the position
    EggTpArcHeight     = 28,         -- extra height (climb, cross, land) so we do not clip islands
    EggTpArriveDist    = 10,         -- studs - we only say "arrived" when we ARE this close
    EggPickupDelay     = 0.60,       -- pause on the egg before checking
    EggReturnDelay     = 2.00,       -- pause at the base (hatch time)
    EggPickupTimeout   = 7.0,        -- give up on one egg after this
    EggFailCooldown    = 30,         -- seconds before retrying a failed egg
    EggMaxRetries      = 2,
    EggExperimentalRemotes = false,  -- try firing "collect" remotes (risky)
    EggAnchorWhileWaiting = true,   -- freeze in the air so we do not fall

    -- ---------- ALERTS ----------
    EggAlertEnabled       = true,
    EggAlertMinRarityIndex = 7,       -- index in Rarity.ORDER (7 = Secret)

    -- ---------- AFK / XP ----------
    AfkJump              = false,     -- jump on the trampoline automatically
    AfkJumpInterval      = 0.60,      -- seconds between jumps
    AfkTrampolineName    = "",        -- filled by "find trampoline"

    -- ---------- SAVED SETTINGS ----------
    AutoLoadSettings     = false,     -- load my settings when the script starts

    -- ---------- SNIPER ----------
    SniperEnabled        = true,
    SniperTargetUserId   = 2678001507,   -- SpyderSammy
    SniperMatchNameToo   = true,
    SniperListenEveryone = false,
    SniperSilenceTimeout = 8,
    SniperMinLength      = 3,
    SniperAutoSubmit     = false,
    CodeBoxPathOverride  = "",
    SniperTypeIndex      = 1,
    SniperJoinCode       = true,
}

--==============================================================
--  THEME
--==============================================================
SaB.Theme = {
    BG      = Color3.fromRGB(20, 22, 30),
    BG2     = Color3.fromRGB(30, 33, 44),
    BG3     = Color3.fromRGB(38, 42, 56),
    BTN     = Color3.fromRGB(48, 53, 70),
    BTN2    = Color3.fromRGB(60, 66, 88),
    ON      = Color3.fromRGB(46, 165, 96),
    OFF     = Color3.fromRGB(120, 60, 68),
    ACC     = Color3.fromRGB(120, 90, 235),
    TEXT    = Color3.fromRGB(236, 239, 246),
    DIM     = Color3.fromRGB(146, 152, 168),
    WARN    = Color3.fromRGB(255, 190, 60),
    OK      = Color3.fromRGB(90, 220, 140),
    BAD     = Color3.fromRGB(255, 95, 95),
}

--==============================================================
--  RARITY
--==============================================================
local Rarity = {}
SaB.Rarity = Rarity

Rarity.ORDER = {
    "Common", "Rare", "Epic", "Legendary", "Mythic",
    "Brainrot God", "Secret", "OG", "Limited", "Unknown",
}

-- one clear colour per category (never grey unless it really is unknown)
Rarity.COLORS = {
    Common       = Color3.fromRGB(185, 196, 208),
    Rare         = Color3.fromRGB(74, 150, 255),
    Epic         = Color3.fromRGB(180, 92, 255),
    Legendary    = Color3.fromRGB(255, 180, 40),
    Mythic       = Color3.fromRGB(255, 77, 77),
    ["Brainrot God"] = Color3.fromRGB(255, 107, 229),
    Secret       = Color3.fromRGB(255, 208, 0),
    OG           = Color3.fromRGB(70, 224, 160),
    Limited      = Color3.fromRGB(51, 214, 255),
    Unknown      = Color3.fromRGB(150, 158, 172),
}

Rarity.SHORT = {
    Common = "COM", Rare = "RAR", Epic = "EPI", Legendary = "LEG", Mythic = "MYT",
    ["Brainrot God"] = "GOD", Secret = "SEC", OG = "OG", Limited = "LIM", Unknown = "???",
}

Rarity.ALIASES = {
    common = "Common", uncommon = "Common", basic = "Common",
    rare = "Rare",
    epic = "Epic",
    legendary = "Legendary", legend = "Legendary", leg = "Legendary",
    mythic = "Mythic", mythical = "Mythic", myt = "Mythic",
    brainrotgod = "Brainrot God", god = "Brainrot God", bg = "Brainrot God",
    braingod = "Brainrot God", brainrot = "Brainrot God",
    secret = "Secret", sec = "Secret",
    og = "OG", original = "OG",
    limited = "Limited", event = "Limited", exclusive = "Limited",
    unknown = "Unknown", none = "Unknown", ["?"] = "Unknown",
}

Rarity.TIER = {}
do
    for i, name in ipairs(Rarity.ORDER) do
        Rarity.TIER[name] = (name == "Unknown") and 0 or (11 - i)
    end
    -- Common=10 ... Limited=2 , Unknown=0  (higher = juicier)
    Rarity.TIER["Common"] = 1
    Rarity.TIER["Rare"] = 2
    Rarity.TIER["Epic"] = 3
    Rarity.TIER["Legendary"] = 4
    Rarity.TIER["Mythic"] = 5
    Rarity.TIER["Brainrot God"] = 6
    Rarity.TIER["Secret"] = 7
    Rarity.TIER["OG"] = 8
    Rarity.TIER["Limited"] = 9
end

function Rarity.normalize(value)
    if type(value) ~= "string" then return nil end
    local key = value:lower():gsub("[^%a]", "")
    if key == "" then return nil end
    return Rarity.ALIASES[key]
end

function Rarity.color(name)
    return Rarity.COLORS[name] or Rarity.COLORS.Unknown
end

function Rarity.tier(name)
    return Rarity.TIER[name] or 0
end

function Rarity.fromIndex(i)
    if i <= 0 then return nil end
    return Rarity.ORDER[i]
end

function Rarity.indexOf(name)
    for i, n in ipairs(Rarity.ORDER) do
        if n == name then return i end
    end
    return 0
end

--==============================================================
--  LOG  (console + UI listeners)
--==============================================================
local Log = { history = {}, listeners = {}, max = 300 }
SaB.Log = Log

function Log.onAdd(fn)
    table.insert(Log.listeners, fn)
end

function Log.add(tag, text, color)
    text = tostring(text)
    local line = os.date("%H:%M:%S") .. "  " .. text
    table.insert(Log.history, { tag = tag, text = line, color = color })
    if #Log.history > Log.max then table.remove(Log.history, 1) end
    for _, fn in ipairs(Log.listeners) do
        pcall(fn, text, color, tag)
    end
    if tag ~= "quiet" then
        print(("[SaB][%s] %s"):format(tostring(tag), text))
    end
end

function Log.eggs(text, color)   Log.add("EGG", text, color) end
function Log.farm(text, color)   Log.add("FARM", text, color) end
function Log.sniper(text, color) Log.add("SNIPE", text, color) end
function Log.info(text, color)   Log.add("INFO", text, color) end
function Log.warn(text, color)   Log.add("WARN", text, color or SaB.Theme.WARN) end
function Log.ok(text, color)     Log.add("OK", text, color or SaB.Theme.OK) end

--==============================================================
--  UTILITIES
--==============================================================
local Util = {}
SaB.Util = Util

function Util.safe(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, res = pcall(fn, ...)
    if ok then return true, res end
    return false, res
end

function Util.notify(title, body, seconds)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = tostring(title or SaB.NAME),
            Text = tostring(body or ""),
            Duration = seconds or 4,
        })
    end)
end

function Util.clamp(n, lo, hi)
    n = tonumber(n) or lo
    if n < lo then return lo end
    if n > hi then return hi end
    return n
end

function Util.round(n)
    return math.floor((tonumber(n) or 0) + 0.5)
end

function Util.trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function Util.split(s, sep)
    local out = {}
    for part in tostring(s or ""):gmatch(sep or "[^,]+") do
        local t = Util.trim(part)
        if t ~= "" then table.insert(out, t) end
    end
    return out
end

-- lower-case, letters+digits only  ("To to to Sahur" -> "tototosahur")
function Util.key(s)
    return (tostring(s or ""):lower():gsub("[^%w]", ""))
end

function Util.lower(s)
    return tostring(s or ""):lower()
end

function Util.has(haystack, needle)
    if type(haystack) ~= "string" or type(needle) ~= "string" then return false end
    if needle == "" then return false end
    return haystack:lower():find(needle:lower(), 1, true) ~= nil
end

-- pretty title case for raw object names ("grass_egg_01" -> "Grass Egg 01")
function Util.prettyName(raw)
    local s = tostring(raw or "")
    s = s:gsub("[_%.%-]", " ")
    s = s:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    s = s:gsub("%s+", " ")
    return Util.trim(s)
end

function Util.formatNumber(n)
    n = tonumber(n) or 0
    if n >= 1e9 then return ("%.2fB"):format(n / 1e9) end
    if n >= 1e6 then return ("%.1fM"):format(n / 1e6) end
    if n >= 1e3 then return ("%.1fK"):format(n / 1e3) end
    return tostring(Util.round(n))
end

function Util.formatDistance(d)
    d = tonumber(d) or 0
    if d >= 1000 then return ("%.1fkm"):format(d / 1000) end
    return ("%dm"):format(Util.round(d))
end

function Util.formatClock(sec)
    sec = math.max(0, tonumber(sec) or 0)
    local m = math.floor(sec / 60)
    local s = math.floor(sec % 60)
    return ("%d:%02d"):format(m, s)
end

-- ---------- instances ----------
function Util.getChar()
    return LocalPlayer.Character
end

function Util.getHRP()
    local c = Util.getChar()
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

function Util.getHumanoid()
    local c = Util.getChar()
    if not c then return nil end
    return c:FindFirstChildOfClass("Humanoid")
end

function Util.isAlive()
    local h = Util.getHumanoid()
    return (h ~= nil and h.Health > 0)
end

function Util.waitForCharacter(timeout)
    local c = LocalPlayer.Character
    local waited = 0
    while (not c or not c:FindFirstChild("HumanoidRootPart")) and waited < (timeout or 15) do
        LocalPlayer.CharacterAdded:Wait()
        c = LocalPlayer.Character
        waited = waited + 0.5
        task.wait(0.25)
    end
    return LocalPlayer.Character
end

function Util.getPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart.Position end
        local ok, p = pcall(function() return obj:GetPivot() end)
        if ok and p and typeof(p) == "CFrame" then return p.Position end
        local part = obj:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
    elseif obj:IsA("Attachment") then
        return obj.WorldPosition
    end
    return nil
end

-- centre + top of a model (for putting the label above the egg)
function Util.getBounds(obj)
    if not obj then return nil, 2 end
    if obj:IsA("BasePart") then
        local size = obj.Size
        return obj.Position, (size and size.Y) or 2
    end
    local ok, cf, size = pcall(function() return obj:GetBoundingBox() end)
    if ok and cf and size then
        return cf.Position, size.Y
    end
    local p = Util.getPos(obj)
    return p, 2
end

function Util.distanceTo(pos)
    local hrp = Util.getHRP()
    if not hrp or not pos then return math.huge end
    return (hrp.Position - pos).Magnitude
end

function Util.path(obj)
    if not obj then return "nil" end
    local ok, p = pcall(function() return obj:GetFullName() end)
    if ok then return p end
    return tostring(obj)
end

function Util.isPartOfCharacter(obj)
    if not obj then return false end
    local ok, model = pcall(function()
        return obj:FindFirstAncestorWhichIsA("Model")
    end)
    if not ok or not model then return false end
    if model:FindFirstChildOfClass("Humanoid") then
        return model ~= LocalPlayer.Character or false and true
    end
    return false
end

-- read the first attribute that exists from a list of candidate names
function Util.getAttribute(obj, names)
    if not obj then return nil end
    for _, n in ipairs(names) do
        local ok, v = pcall(function() return obj:GetAttribute(n) end)
        if ok and v ~= nil and v ~= "" then return v, n end
    end
    return nil
end

function Util.getAttributes(obj)
    local ok, attrs = pcall(function() return obj:GetAttributes() end)
    if ok and type(attrs) == "table" then return attrs end
    return {}
end

-- find a child ValueBase (StringValue / NumberValue / IntValue ...) by name
function Util.findValue(obj, names, limit)
    if not obj then return nil end
    limit = limit or 40
    local count = 0
    local lowered = {}
    for _, n in ipairs(names) do lowered[Util.key(n)] = true end
    for _, d in ipairs(obj:GetDescendants()) do
        count = count + 1
        if count > limit then break end
        if d:IsA("ValueBase") then
            local key = Util.key(d.Name)
            if lowered[key] then
                local ok, v = pcall(function() return d.Value end)
                if ok and v ~= nil and v ~= "" then return v, d.Name, d end
            end
        end
    end
    return nil
end

function Util.findFirst(obj, className, deep)
    if not obj then return nil end
    if deep then
        return obj:FindFirstChildWhichIsA(className, true)
    end
    return obj:FindFirstChildOfClass(className)
end

-- collect every ProximityPrompt under an object (they are usually the way
-- the game lets you pick an egg up)
function Util.findPrompts(obj, limit)
    local out = {}
    if not obj then return out end
    limit = limit or 6
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            table.insert(out, d)
            if #out >= limit then break end
        end
    end
    return out
end

function Util.findClickDetectors(obj, limit)
    local out = {}
    if not obj then return out end
    limit = limit or 3
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("ClickDetector") then
            table.insert(out, d)
            if #out >= limit then break end
        end
    end
    return out
end

-- an image we can show on the ESP (only rbxasset ids work inside Roblox)
function Util.findIcon(obj)
    if not obj then return nil end
    local count = 0
    for _, d in ipairs(obj:GetDescendants()) do
        count = count + 1
        if count > 60 then break end
        if (d:IsA("Decal") or d:IsA("Texture")) and d.Texture ~= "" then
            if Util.has(d.Texture, "rbxassetid") then return d.Texture end
        elseif d:IsA("ImageLabel") and d.Image ~= "" then
            if Util.has(d.Image, "rbxassetid") then return d.Image end
        end
    end
    return nil
end

-- look for a countdown (eggs disappear if you are too slow)
function Util.findTimer(obj)
    if not obj then return nil end
    local candidates = {
        "TimeLeft", "TimeRemaining", "DespawnTime", "Despawn", "Lifetime",
        "LifeTime", "Expire", "ExpireTime", "Timer", "Duration", "Cooldown",
    }
    local v, name = Util.getAttribute(obj, candidates)
    if tonumber(v) then return tonumber(v), name end

    local ok, now = pcall(function() return workspace:GetServerTimeNow() end)
    for attr, raw in pairs(Util.getAttributes(obj)) do
        if Util.has(attr, "expire") or Util.has(attr, "despawn") or Util.has(attr, "deadline") then
            if tonumber(raw) and ok then
                local left = tonumber(raw) - now
                if left > 0 and left < 3600 then return left, attr end
            end
        end
    end

    -- sometimes the countdown is drawn on a billboard ("0:45")
    local count = 0
    for _, d in ipairs(obj:GetDescendants()) do
        count = count + 1
        if count > 40 then break end
        if d:IsA("TextLabel") and d.Visible then
            local mm, ss = d.Text:match("(%d+):(%d%d)")
            if mm then
                return tonumber(mm) * 60 + tonumber(ss), "label"
            end
        end
    end
    return nil
end

function Util.tableCount(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

function Util.keys(t)
    local out = {}
    for k in pairs(t or {}) do table.insert(out, k) end
    table.sort(out, function(a, b) return tostring(a) < tostring(b) end)
    return out
end

-- executor helpers (Delta / Synapse style) - always optional
function Util.clipboard(text)
    if typeof(setclipboard) == "function" then
        pcall(setclipboard, tostring(text))
        return true
    end
    if typeof(toclipboard) == "function" then
        pcall(toclipboard, tostring(text))
        return true
    end
    return false
end

function Util.writeFile(name, text)
    if typeof(writefile) ~= "function" then return false end
    local ok = pcall(function()
        if typeof(makefolder) == "function" and not isfolder("SaBSuite") then
            makefolder("SaBSuite")
        end
        writefile("SaBSuite/" .. name, tostring(text))
    end)
    if not ok then
        ok = pcall(function() writefile(name, tostring(text)) end)
    end
    return ok
end

-- tiny settings (de)serializer - no JSON library needed inside Roblox
local SETTINGS_SEP = "\031"

function Util.encodeSettings(cfg)
    local lines = {}
    for k, v in pairs(cfg or {}) do
        local t = type(v)
        if t == "number" or t == "boolean" then
            table.insert(lines, ("%s=%s=%s"):format(k, t, tostring(v)))
        elseif t == "string" then
            if not v:find("\n") then
                table.insert(lines, ("%s=string=%s"):format(k, v))
            end
        elseif t == "table" then
            local items = {}
            local plain = true
            for _, item in ipairs(v) do
                if type(item) ~= "string" and type(item) ~= "number" then plain = false break end
                table.insert(items, tostring(item))
            end
            if plain then
                table.insert(lines, ("%s=table=%s"):format(k, table.concat(items, SETTINGS_SEP)))
            end
        end
    end
    table.sort(lines)
    return table.concat(lines, "\n")
end

function Util.decodeSettings(text)
    local out = {}
    for line in tostring(text or ""):gmatch("[^\n]+") do
        local k, t, v = line:match("^(%w+)=(%w+)=(.*)$")
        if k and t and v then
            if t == "number" then
                out[k] = tonumber(v)
            elseif t == "boolean" then
                out[k] = (v == "true")
            elseif t == "string" then
                out[k] = v
            elseif t == "table" then
                local items = {}
                for item in v:gmatch("[^" .. SETTINGS_SEP .. "]+") do
                    table.insert(items, item)
                end
                out[k] = items
            end
        end
    end
    return out
end

function Util.readSaved(name)
    if typeof(readfile) ~= "function" then return nil end
    local ok, data = pcall(function()
        if typeof(isfile) == "function" and not isfile(name) then return nil end
        return readfile(name)
    end)
    if ok and type(data) == "string" then return data end
    return nil
end

function Util.isEmpty(t)
    for _ in pairs(t or {}) do return false end
    return true
end

-- expose the whole suite so you can poke at it from the executor console
-- (or from the unit tests, which load this file with a Roblox stub)
_G.SaB = SaB
_G.SAB = SaB

--==============================================================
--  MODULE: 02_EggDB.lua
--==============================================================
--==============================================================
--  EGG DATABASE  (pure data + pure functions - unit tested)
--
--  Everything here comes from the game wiki, so the script can
--  recognise an egg even when the object itself has NO attributes:
--  we match the object name / value text against the real list.
--
--  tests:  python3 tests/run_tests.py
--==============================================================

local SaB = SaB or {}
local EggDB = {}
SaB.EggDB = EggDB

EggDB.SOURCE = "Steal a Brainrot Wiki - 'Jump for Eggs LTM' (Update 68, 26/09/2026)"

-- keep this module runnable on its own (unit tests load it without Core)
local function norm(s)
    if SaB.Util and SaB.Util.key then return SaB.Util.key(s) end
    return (tostring(s or ""):lower():gsub("[^%w]", ""))
end
local function lower(s)
    return tostring(s or ""):lower()
end

--==============================================================
--  ISLANDS  (higher = rarer eggs)
--==============================================================
EggDB.ISLANDS = {
    { key = "Grass",    label = "Grass",    height = 1, color = { 120, 210, 90 },
      aliases = { "grass", "starter", "spawn" } },
    { key = "Desert",   label = "Desert",   height = 2, color = { 240, 200, 110 },
      aliases = { "desert", "sand", "dune" } },
    { key = "Arctic",   label = "Arctic",   height = 3, color = { 150, 220, 255 },
      aliases = { "arctic", "snow", "ice", "frozen", "winter" } },
    { key = "Cave",     label = "Cave",     height = 4, color = { 200, 150, 105 },
      aliases = { "cave", "cavern", "mine", "mines", "mining" } },
    { key = "Aquatic",  label = "Aquatic",  height = 5, color = { 80, 160, 255 },
      aliases = { "aquatic", "water", "ocean", "sea", "lake", "beach" } },
    { key = "Lava",     label = "Lava",     height = 6, color = { 255, 110, 60 },
      aliases = { "lava", "volcano", "magma", "fire" } },
    { key = "Heavenly", label = "Heavenly", height = 7, color = { 255, 245, 205 },
      aliases = { "heavenly", "heaven", "sky", "cloud", "divine", "galaxy", "angel" } },
    { key = "Event",    label = "Event",    height = 8, color = { 255, 140, 220 },
      aliases = { "candy", "rainbow", "easter", "event", "limited" } },
}

EggDB.ISLAND_BY_KEY = {}
for _, isl in ipairs(EggDB.ISLANDS) do
    EggDB.ISLAND_BY_KEY[isl.key] = isl
end

function EggDB.islandLabel(key)
    local isl = EggDB.ISLAND_BY_KEY[key]
    return isl and isl.label or "?"
end

function EggDB.islandHeight(key)
    local isl = EggDB.ISLAND_BY_KEY[key]
    return isl and isl.height or 0
end

-- find an island name inside ANY text (object name, folder, path ...)
function EggDB.islandFromText(text)
    local t = lower(text)
    if t == "" then return nil end
    local best, bestLen = nil, 0
    for _, isl in ipairs(EggDB.ISLANDS) do
        for _, alias in ipairs(isl.aliases) do
            if t:find(alias, 1, true) and #alias > bestLen then
                best, bestLen = isl.key, #alias
            end
        end
    end
    return best
end

--==============================================================
--  THE 35 EGGS  (7 islands x 5 eggs)  - Update 68
--==============================================================
--  n = brainrot you get , r = rarity , i = island , s = slot (1..5)
--  inc = income per second (number) , incText = as shown on the wiki
EggDB.EGGS = {
    -- Grass / Starter
    { n = "Cavallo Virtuoso",          r = "Mythic",        i = "Grass",    s = 1, inc = 7500,      incText = "$7.5K/s" },
    { n = "Tartaruga Cisterna",        r = "Brainrot God",  i = "Grass",    s = 2, inc = 250000,    incText = "$250K/s" },
    { n = "Eggdin Egg Egg Dun",        r = "Brainrot God",  i = "Grass",    s = 3, inc = 310000,    incText = "$310K/s" },
    { n = "Graipuss Medussi",          r = "Secret",        i = "Grass",    s = 4, inc = 1000000,   incText = "$1M/s" },
    { n = "Zebrino Pianino",           r = "Secret",        i = "Grass",    s = 5, inc = 7200000,   incText = "$7.2M/s" },
    -- Desert
    { n = "Extinct Ballerina",         r = "Brainrot God",  i = "Desert",   s = 1, inc = 125000,    incText = "$125K/s" },
    { n = "Craburger",                 r = "Secret",        i = "Desert",   s = 2, inc = 1300000,   incText = "$1.3M/s" },
    { n = "Rexino Ramino",             r = "Secret",        i = "Desert",   s = 3, inc = 2600000,   incText = "$2.6M/s" },
    { n = "Qamar Camelamp",            r = "Secret",        i = "Desert",   s = 4, inc = 3300000,   incText = "$3.3M/s" },
    { n = "La Grande Combinasion",     r = "Secret",        i = "Desert",   s = 5, inc = 10000000,  incText = "$10M/s" },
    -- Arctic
    { n = "Frio Ninja",                r = "Brainrot God",  i = "Arctic",   s = 1, inc = 265000,    incText = "$265K/s" },
    { n = "Ski Ski Skunki",            r = "Secret",        i = "Arctic",   s = 2, inc = 1600000,   incText = "$1.6M/s" },
    { n = "Rockarino Rockara",         r = "Secret",        i = "Arctic",   s = 3, inc = 3000000,   incText = "$3M/s" },
    { n = "Chill Puppy",               r = "Secret",        i = "Arctic",   s = 4, inc = 4000000,   incText = "$4M/s" },
    { n = "Yetimatic",                 r = "Secret",        i = "Arctic",   s = 5, inc = 87500000,  incText = "$87.5M/s" },
    -- Cave
    { n = "Sammyni Spyderini",         r = "Secret",        i = "Cave",     s = 1, inc = 330000,    incText = "$330K/s" },
    { n = "Pin Pin Pengu",             r = "Secret",        i = "Cave",     s = 2, inc = 2300000,   incText = "$2.3M/s" },
    { n = "Chicleteira Bicicleteira",  r = "Secret",        i = "Cave",     s = 3, inc = 3500000,   incText = "$3.5M/s" },
    { n = "Sir Mangus",                r = "Secret",        i = "Cave",     s = 4, inc = 7500000,   incText = "$7.5M/s" },
    { n = "Draculino",                 r = "Secret",        i = "Cave",     s = 5, inc = 120000000, incText = "$120M/s" },
    -- Aquatic
    { n = "Fishboard",                 r = "Secret",        i = "Aquatic",  s = 1, inc = 825000,    incText = "$825K/s" },
    { n = "Marino Submarino",          r = "Secret",        i = "Aquatic",  s = 2, inc = 3600000,   incText = "$3.6M/s" },
    { n = "Arcadopus",                 r = "Secret",        i = "Aquatic",  s = 3, inc = 5000000,   incText = "$5M/s" },
    { n = "Swag Soda",                 r = "Secret",        i = "Aquatic",  s = 4, inc = 13000000,  incText = "$13M/s" },
    { n = "Capitano Moby",             r = "Secret",        i = "Aquatic",  s = 5, inc = 160000000, incText = "$160M/s" },
    -- Lava
    { n = "Ranito Pepito",             r = "Secret",        i = "Lava",     s = 1, inc = 950000,    incText = "$950K/s" },
    { n = "To to to Sahur",            r = "Secret",        i = "Lava",     s = 2, inc = 2250000,   incText = "$2.25M/s" },
    { n = "Burrito Bat",               r = "Secret",        i = "Lava",     s = 3, inc = 7000000,   incText = "$7M/s" },
    { n = "Lavamanta",                 r = "Secret",        i = "Lava",     s = 4, inc = 28500000,  incText = "$28.5M/s" },
    { n = "Cerberus",                  r = "Secret",        i = "Lava",     s = 5, inc = 175000000, incText = "$175M/s" },
    -- Heavenly (best island)
    { n = "Capibaro Celestino",        r = "Secret",        i = "Heavenly", s = 1, inc = 1700000,   incText = "$1.7M/s" },
    { n = "Cupid Cupid Sahur",         r = "Secret",        i = "Heavenly", s = 2, inc = 3100000,   incText = "$3.1M/s" },
    { n = "DJ Panda",                  r = "Secret",        i = "Heavenly", s = 3, inc = 17500000,  incText = "$17.5M/s" },
    { n = "Lionello Casarello",        r = "Secret",        i = "Heavenly", s = 4, inc = 58500000,  incText = "$58.5M/s" },
    { n = "Dragon Cannelloni",         r = "Secret",        i = "Heavenly", s = 5, inc = 250000000, incText = "$250M/s" },
}

-- index by normalised name:  "dragoncannelloni" -> entry
EggDB.BY_KEY = {}
for _, e in ipairs(EggDB.EGGS) do
    e.key = norm(e.n)
    EggDB.BY_KEY[e.key] = e
end

-- every DB name is also a detection keyword
EggDB.NAMES = {}
for _, e in ipairs(EggDB.EGGS) do
    table.insert(EggDB.NAMES, e.n)
end

--==============================================================
--  DETECTION KEYWORDS
--==============================================================
-- words that mean "this object is an egg"
EggDB.EGG_WORDS = {
    "egg", "eggs", "eggrot", "easteregg", "luckyegg",
    "nest", "capsule", "pod", "hatchegg",
}

-- folders that usually hold the eggs
EggDB.CONTAINER_WORDS = {
    "egg", "eggs", "island", "islands", "ltm", "event", "events",
    "jumpforeggs", "jumpforegg", "easter", "nest", "collect", "collectible",
    "collectables", "pickup", "pickups", "loot", "spawns",
}

-- a LOCATION (island / biome / event area) is never an egg itself
EggDB.LOCATION_WORDS = {
    "island", "islands", "biome", "zone", "area", "world", "region", "map",
    "ltm", "event", "easter", "realm", "dimension", "level",
}

-- ProximityPrompt action texts that mean "pick it up"
EggDB.PROMPT_WORDS = {
    "collect", "grab", "pick", "pickup", "take", "steal", "hatch",
    "claim", "gather", "catch", "get", "hold", "carry",
}

-- attributes / values the game might use to describe an egg
EggDB.NAME_ATTRS = {
    "EggName", "Egg", "Brainrot", "BrainrotName", "PetName", "Name2",
    "Reward", "Contents", "Contains", "Prize", "Unit", "Character",
}
EggDB.RARITY_ATTRS = {
    "Rarity", "EggRarity", "Tier", "Rank", "Quality", "RarityName",
}
EggDB.ISLAND_ATTRS = {
    "Island", "Biome", "Zone", "Area", "World", "Region", "Map",
}
EggDB.FLAG_ATTRS = {
    "IsEgg", "Egg", "IsCollectible", "Collectible", "IsLoot", "IsPickup",
}

--==============================================================
--  LOOKUP / CLASSIFY
--==============================================================

-- exact or fuzzy match against the 35 known eggs
function EggDB.lookup(text)
    if type(text) ~= "string" or text == "" then return nil end
    local k = norm(text)
    if k == "" then return nil end
    local direct = EggDB.BY_KEY[k]
    if direct then return direct, "exact" end

    -- fuzzy: the object name contains the brainrot name (or the other way)
    -- e.g.  "Egg_DragonCannelloni_3" , "Dragon Cannelloni Egg"
    local best, bestLen = nil, 0
    for _, e in ipairs(EggDB.EGGS) do
        if #e.key >= 6 then
            if k:find(e.key, 1, true) then
                if #e.key > bestLen then best, bestLen = e, #e.key end
            elseif e.key:find(k, 1, true) and #k >= 6 then
                if #k > bestLen then best, bestLen = e, #k end
            end
        end
    end
    if best then return best, "fuzzy" end
    return nil
end

-- read a rarity out of any free text ("Secret Egg", "rarity: Brainrot God")
function EggDB.rarityFromText(text)
    if type(text) ~= "string" then return nil end
    local t = lower(text)
    if t == "" then return nil end
    if t:find("brainrotgod", 1, true) or t:find("brainrot god", 1, true) or t:find("braingod", 1, true) then
        return "Brainrot God"
    end
    local found, bestTier = nil, -1
    if SaB.Rarity then
        for _, name in ipairs(SaB.Rarity.ORDER) do
            if name ~= "Unknown" and t:find(lower(name), 1, true) then
                if SaB.Rarity.tier(name) > bestTier then
                    found, bestTier = name, SaB.Rarity.tier(name)
                end
            end
        end
    else
        local simple = { "limited", "og", "secret", "mythic", "legendary", "epic", "rare", "common" }
        for i, w in ipairs(simple) do
            if t:find(w, 1, true) then return w end
        end
    end
    return found
end

function EggDB.isEggWord(text)
    local t = lower(text)
    for _, w in ipairs(EggDB.EGG_WORDS) do
        if t:find(w, 1, true) then return true, w end
    end
    return false
end

function EggDB.isContainerWord(text)
    local t = lower(text)
    for _, w in ipairs(EggDB.CONTAINER_WORDS) do
        if t:find(w, 1, true) then return true, w end
    end
    return false
end

function EggDB.isLocationWord(text)
    local t = lower(text)
    for _, w in ipairs(EggDB.LOCATION_WORDS) do
        if t:find(w, 1, true) then return true, w end
    end
    return false
end

function EggDB.isPromptWord(text)
    local t = lower(text)
    for _, w in ipairs(EggDB.PROMPT_WORDS) do
        if t:find(w, 1, true) then return true, w end
    end
    return false
end

--[[
    classify(text) -> {
        name     = "Dragon Cannelloni",   -- best display name we have
        rarity   = "Secret",              -- "Unknown" when we cannot tell
        island   = "Heavenly",            -- nil when unknown
        income   = 250000000,             -- nil when unknown
        incomeText = "$250M/s",
        known    = true,                  -- matched the database
        slot     = 5,
    }
]]
function EggDB.classify(text)
    local out = { name = tostring(text or "?"), rarity = "Unknown", known = false }
    if type(text) ~= "string" or text == "" then return out end

    local entry = EggDB.lookup(text)
    if entry then
        out.name       = entry.n
        out.rarity     = entry.r
        out.island     = entry.i
        out.income     = entry.inc
        out.incomeText = entry.incText
        out.slot       = entry.s
        out.known      = true
        return out
    end

    -- not in the DB: at least try to read the rarity / island from the text
    out.rarity = EggDB.rarityFromText(text) or "Unknown"
    out.island = EggDB.islandFromText(text)
    return out
end

-- turn a raw Roblox object name into something readable
function EggDB.displayName(raw)
    local entry = EggDB.lookup(raw)
    if entry then return entry.n end
    local pretty = (SaB.Util and SaB.Util.prettyName) and SaB.Util.prettyName(raw) or tostring(raw)
    pretty = pretty:gsub("%s*%d+$", "")      -- drop trailing "3" from "Egg 3"
    if pretty == "" then pretty = tostring(raw) end
    return pretty
end

-- how many eggs per island (used by the UI / stats)
function EggDB.countByIsland()
    local out = {}
    for _, e in ipairs(EggDB.EGGS) do
        out[e.i] = (out[e.i] or 0) + 1
    end
    return out
end


--==============================================================
--  MODULE: 03_EggScanner.lua
--==============================================================
--==============================================================
--  EGG SCANNER
--
--  Old version only looked for objects whose NAME contains "egg",
--  which is why the list was empty on most servers.
--
--  New version scores every object with 7 different strategies and
--  keeps watching the workspace, so eggs that spawn later (or eggs
--  that are named after the brainrot inside) are picked up too:
--
--     1. db       - the name matches one of the 35 known eggs
--     2. attr     - an attribute / value says it is an egg
--     3. name     - "egg" (or another egg word) in the name / path
--     4. folder   - it sits inside an egg / island / event folder
--     5. prompt   - it has a "Collect / Grab / Pick up" prompt
--     6. value    - a child value holds the brainrot name
--     7. user     - one of your own keywords
--
--==============================================================

local Scanner = {}
SaB.Scanner = Scanner

local CONFIG  = SaB.CONFIG
local Util    = SaB.Util

Scanner.eggs   = {}    -- [obj] = record
Scanner.roots  = {}    -- folders worth re-scanning often
Scanner.failed = {}    -- [obj] = tick() until we retry a bad egg
Scanner.stats = {
    scanned = 0, objects = 0, lastScan = 0, lastDeep = 0,
    lastDuration = 0, bySource = {}, byRarity = {}, newSince = 0,
}
Scanner.SOURCE_LABEL = {
    db = "known egg name", attr = "attribute/value", name = "name has 'egg'",
    folder = "egg/island folder", prompt = "collect prompt",
    value = "child value", user = "your keyword",
}

local PRUNE = { Terrain = true, Camera = true }

--==============================================================
--  helpers
--==============================================================

local function now() return tick() end

local function isContainer(obj)
    return obj and (obj:IsA("Folder") or obj:IsA("Model")) or false
end

local function ancestorNames(obj, levels)
    local parts, cur, n = {}, obj and obj.Parent, 0
    while cur and n < (levels or 4) do
        table.insert(parts, cur.Name)
        cur = cur.Parent
        n = n + 1
    end
    return table.concat(parts, "/")
end

local function objPath(obj)
    local prefix = ancestorNames(obj, 4)
    if prefix == "" then return obj.Name end
    return prefix .. "/" .. obj.Name
end

local function bump(t, k, by)
    t[k] = (t[k] or 0) + (by or 1)
end

--==============================================================
--  CLASSIFY ONE OBJECT
--==============================================================

--[[
    returns a record, or nil when the object is not egg-like enough.

    record = {
        obj, raw, name, rarity, island, income, incomeText, tier, known,
        pos, dist, source, score, icon, timer, path, prompts, clicks,
        firstSeen, lastSeen, carried
    }
]]
Scanner.budget = 0     -- how many objects the current scan may still analyse
Scanner.BUDGET = 700

function Scanner.classifyObject(obj)
    if Scanner.budget <= 0 then return nil end
    Scanner.budget = Scanner.budget - 1
    if not obj then return nil end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return nil end
    if Util.isPartOfCharacter(obj) then return nil end

    -- already counted?  (an egg model and the parts inside it are ONE egg)
    local anc, _ = obj.Parent, 0
    for _ = 1, 4 do
        if not anc then break end
        if Scanner.eggs[anc] then return nil end
        anc = anc.Parent
    end

    local raw      = obj.Name or ""
    local parents  = ancestorNames(obj, 4)
    local path     = (parents ~= "" and (parents .. "/") or "") .. raw
    if Util.has(path, "Players") then return nil end

    local attrs = Util.getAttributes(obj)

    -- ---------------------------------------------------------------
    -- 1) collect the text this object tells us about itself
    -- ---------------------------------------------------------------
    local entry   = SaB.EggDB.lookup(raw)
    local nameHasEggWord = SaB.EggDB.isEggWord(raw)          -- "Egg_1"
    local pathHasEggWord = SaB.EggDB.isEggWord(parents)      -- inside "Eggs"
    local hasContainer   = SaB.EggDB.isContainerWord(parents)
    local isLocation     = SaB.EggDB.isLocationWord(raw)     -- "GrassIsland"

    -- an island / event area is a PLACE, not an egg - unless the game itself
    -- marks it as one (a database name or an IsEgg flag)
    if isLocation and not entry and flagValue ~= true then return nil end

    -- user keywords
    local userHit = false
    for _, kw in ipairs(CONFIG.EggWhitelist) do
        if Util.has(path, kw) then userHit = true break end
    end
    for _, kw in ipairs(Util.split(CONFIG.EggExtraKeywords)) do
        if Util.has(path, kw) then userHit = true break end
    end

    -- attributes that describe the egg
    local flagValue      = Util.getAttribute(obj, SaB.EggDB.FLAG_ATTRS)
    local nameFromAttr   = Util.getAttribute(obj, SaB.EggDB.NAME_ATTRS)
    local rarityFromAttr = Util.getAttribute(obj, SaB.EggDB.RARITY_ATTRS)
    local islandFromAttr = Util.getAttribute(obj, SaB.EggDB.ISLAND_ATTRS)

    local entryFromAttr = nil
    if type(nameFromAttr) == "string" then
        entryFromAttr = SaB.EggDB.lookup(nameFromAttr)
    end

    -- ---------------------------------------------------------------
    -- 2) score it  (cheap checks first - this runs on every object)
    -- ---------------------------------------------------------------
    local score, source = 0, nil
    local function offer(points, why)
        if points > score then score, source = points, why end
    end

    -- "it sits in an egg/island folder" alone is NOT enough (an island is
    -- full of rocks and trees) - it only counts together with a 2nd signal
    if entry then                                    offer(100, "db")     end
    if entryFromAttr then                            offer(95, "value")   end
    if flagValue == true or flagValue == "true" then offer(85, "attr")    end
    if nameHasEggWord then                           offer(70, "name")    end
    if userHit then                                  offer(65, "user")    end
    if pathHasEggWord then                           offer(45, "name")    end

    -- rarity / island attributes make the guess much stronger
    local rarityGuessed = nil
    if rarityFromAttr ~= nil then
        rarityGuessed = SaB.Rarity.normalize(tostring(rarityFromAttr))
            or SaB.EggDB.rarityFromText(tostring(rarityFromAttr))
        if rarityGuessed then
            offer(hasContainer and 72 or 40, "attr")
        end
    end
    if islandFromAttr ~= nil and (hasEggWord or hasContainer) then
        offer(75, "attr")
    end

    -- prompts / click detectors : a "Collect / Grab" prompt is a strong hint.
    -- Models get a deep search, plain parts only a cheap direct-child check
    -- (keeps the scan fast on huge maps).
    local prompts, clicks = {}, {}
    if nameHasEggWord or pathHasEggWord or hasContainer or userHit or score > 0 then
        if obj:IsA("Model") then
            prompts = Util.findPrompts(obj, 4)
        else
            local direct = obj:FindFirstChildOfClass("ProximityPrompt")
            if direct then prompts = { direct } end
        end
        for _, p in ipairs(prompts) do
            local action = tostring(p.ActionText or "") .. " " .. tostring(p.Name or "")
            if SaB.EggDB.isPromptWord(action) then
                offer(58, "prompt")
                break
            end
        end
        clicks = Util.findClickDetectors(obj, 2)
        if #clicks > 0 then offer(50, "prompt") end
    end

    -- sitting inside an egg / island folder lifts an object that already has
    -- one real signal (but never an island itself)
    if hasContainer and not isLocation then
        if score >= 45 then offer(math.min(score + 12, 92), source or "folder") end
    end

    -- child values holding a brainrot name (egg_12 -> StringValue "Cerberus")
    if score < 95 and (hasEggWord or hasContainer or userHit) then
        local v = Util.findValue(obj, SaB.EggDB.NAME_ATTRS, 30)
        if type(v) == "string" then
            local e2 = SaB.EggDB.lookup(v)
            if e2 then
                entryFromAttr = e2
                offer(92, "value")
            end
        end
    end

    if score < CONFIG.EggMinConfidence then return nil end

    -- ---------------------------------------------------------------
    -- 3) build the record
    -- ---------------------------------------------------------------
    local info = SaB.EggDB.classify(entry and entry.n or (entryFromAttr and entryFromAttr.n) or raw)

    local name
    if entry then
        name = entry.n
    elseif entryFromAttr then
        name = entryFromAttr.n
    elseif type(nameFromAttr) == "string" and #nameFromAttr > 1 then
        name = SaB.EggDB.displayName(nameFromAttr)
    else
        name = SaB.EggDB.displayName(raw)
    end

    local rarity = "Unknown"
    if rarityGuessed then
        rarity = rarityGuessed
    elseif info.known then
        rarity = info.rarity
    else
        rarity = SaB.EggDB.rarityFromText(raw .. " " .. parents) or "Unknown"
    end
    rarity = SaB.Rarity.normalize(rarity) or rarity
    if not SaB.Rarity.COLORS[rarity] then rarity = "Unknown" end

    local island = nil
    if islandFromAttr ~= nil then
        island = SaB.EggDB.islandFromText(tostring(islandFromAttr))
    end
    if not island and info.known then island = info.island end
    if not island then island = SaB.EggDB.islandFromText(parents .. " " .. raw) end

    local pos, height = Util.getBounds(obj)
    if not pos then return nil end

    local timer, timerSource = Util.findTimer(obj)

    local rec = {
        obj         = obj,
        isLocation  = isLocation,
        raw         = raw,
        name        = name,
        rarity      = rarity,
        tier        = SaB.Rarity.tier(rarity),
        island      = island,
        income      = info.income,
        incomeText  = info.incomeText,
        known       = info.known,
        slot        = info.slot,
        pos         = pos,
        height      = height or 2,
        dist        = Util.distanceTo(pos),
        source      = source or "?",
        score       = score,
        icon        = Util.findIcon(obj),
        timer       = timer,
        timerSource = timerSource,
        timerAt     = timer and now() or nil,
        path        = objPath(obj),
        prompts     = prompts,
        clicks      = clicks,
        firstSeen   = now(),
        lastSeen    = now(),
        carried     = false,
    }
    return rec
end

--==============================================================
--  TRACKING
--==============================================================

function Scanner.add(obj, fromEvent)
    if not obj then return nil end
    local existing = Scanner.eggs[obj]
    if existing then
        existing.lastSeen = now()
        return existing
    end
    local rec = Scanner.classifyObject(obj)
    if not rec then return nil end
    Scanner.eggs[obj] = rec
    bump(Scanner.stats.bySource, rec.source)
    bump(Scanner.stats.byRarity, rec.rarity)
    Scanner.stats.newSince = Scanner.stats.newSince + 1
    -- rare egg? let the UI shout about it (alerts are wired in 09_Extras)
    pcall(Scanner.onAlert, rec)
    if fromEvent then
        Log.eggs(("NEW egg  %s  [%s]  %s  (%s, %s)"):format(
            rec.name, rec.rarity, rec.island and (rec.island .. " island") or "island ?",
            Util.formatDistance(rec.dist), Scanner.SOURCE_LABEL[rec.source] or rec.source),
            SaB.Rarity.color(rec.rarity))
    end
    return rec
end

function Scanner.remove(obj)
    local rec = Scanner.eggs[obj]
    if not rec then return end
    Scanner.eggs[obj] = nil
    Scanner.failed[obj] = nil
    if SaB.ESP then SaB.ESP.detach(rec) end
end

function Scanner.markFailed(rec, seconds)
    if not rec then return end
    rec.fails = (rec.fails or 0) + 1
    Scanner.failed[rec.obj] = now() + (seconds or CONFIG.EggFailCooldown)
end

function Scanner.isFailed(rec)
    if not rec then return false end
    local t = Scanner.failed[rec.obj]
    return t ~= nil and t > now()
end

--==============================================================
--  SCANNING
--==============================================================

-- walk a root, calling visit(obj) for every Model / BasePart
function Scanner.walk(root, visit, limit)
    limit = limit or CONFIG.EggScanLimit
    local stack = { root }
    local count = 0
    while #stack > 0 do
        local node = table.remove(stack)
        if node and not PRUNE[node.Name] then
            count = count + 1
            if count > limit then break end
            if node ~= root then
                if node:IsA("Model") or node:IsA("BasePart") then
                    visit(node)
                end
            end
            local ok, children = pcall(function() return node:GetChildren() end)
            if ok and children then
                for i = 1, #children do
                    local c = children[i]
                    if not PRUNE[c.Name] then
                        stack[#stack + 1] = c
                    end
                end
            end
        end
    end
    return count
end

-- remember the folders that look like they hold eggs - we re-scan those
-- often (cheap) instead of walking the whole map every second
function Scanner.registerRoot(obj)
    if not obj or Scanner.roots[obj] then return end
    if not (obj:IsA("Folder") or obj:IsA("Model")) then return end
    if SaB.EggDB.isContainerWord(obj.Name) or SaB.EggDB.isEggWord(obj.Name) then
        Scanner.roots[obj] = true
    end
end

-- quick scan: only the promising folders (runs every ~1s)
function Scanner.quickScan()
    Scanner.budget = Scanner.BUDGET
    for root in pairs(Scanner.roots) do
        if root and root.Parent then
            Scanner.walk(root, function(obj) Scanner.add(obj) end, 4000)
        else
            Scanner.roots[root] = nil
        end
    end
    return Util.tableCount(Scanner.eggs)
end

-- deep scan: the whole workspace (runs on a timer / on demand)
function Scanner.deepScan(quiet)
    local t0 = now()
    local objects = 0
    Scanner.budget = Scanner.BUDGET
    local before = Util.tableCount(Scanner.eggs)

    objects = Scanner.walk(SaB.Services.Workspace, function(obj)
        Scanner.registerRoot(obj)
        Scanner.add(obj)
    end, CONFIG.EggScanLimit)

    -- also check the top level containers directly (eggs are often plain
    -- parts with a name like "Egg1" sitting inside an island model)
    for _, child in ipairs(Workspace:GetChildren()) do
        Scanner.registerRoot(child)
    end

    Scanner.stats.scanned    = objects
    Scanner.stats.lastDeep   = now()
    Scanner.stats.lastScan   = now()
    Scanner.stats.lastDuration = now() - t0
    if not quiet then
        Log.eggs(("deep scan: %d objects in %.2fs - %d eggs tracked"):format(
            objects, Scanner.stats.lastDuration, Util.tableCount(Scanner.eggs)), SaB.Theme.ACC)
    end
    return Util.tableCount(Scanner.eggs) - before
end

-- refresh what we already know: positions, distances, dead objects, timers
function Scanner.refresh()
    local list = {}
    local hrp = Util.getHRP()
    for obj, rec in pairs(Scanner.eggs) do
        local alive = (obj.Parent ~= nil)
        if not alive then
            Scanner.eggs[obj] = nil
            if SaB.ESP then SaB.ESP.detach(rec) end
        else
            local p = Util.getPos(obj)
            if p then
                rec.pos = p
                rec.dist = hrp and (hrp.Position - p).Magnitude or rec.dist
            end
            rec.lastSeen = now()
            -- is the egg now attached to a player (being carried)?
            rec.carried = Util.isPartOfCharacter(obj)
            if rec.timer and rec.timerAt then
                local left = rec.timer - (now() - rec.timerAt)
                if left <= 0 then left = 0 end
                rec.timerLeft = left
            end
            table.insert(list, rec)
        end
    end
    Scanner.list = list
    return list
end

--==============================================================
--  FILTERS + TARGETS
--==============================================================

function Scanner.passesFilter(rec)
    if not rec or not rec.obj or rec.obj.Parent == nil then return false end
    if rec.carried then return false end

    if CONFIG.EggHideUnknown and rec.rarity == "Unknown" then return false end
    if CONFIG.EggOnlyKnown and not rec.known then return false end

    if CONFIG.EggMinRarityIndex > 0 then
        local minName = SaB.Rarity.fromIndex(CONFIG.EggMinRarityIndex)
        if minName and rec.tier < SaB.Rarity.tier(minName) then return false end
    end

    if CONFIG.EggIslandFilter ~= "Any" and rec.island ~= CONFIG.EggIslandFilter then
        return false
    end

    if CONFIG.EggMaxDistance > 0 and rec.dist > CONFIG.EggMaxDistance then
        return false
    end

    if CONFIG.EggWhitelistOn and #CONFIG.EggWhitelist > 0 then
        local hay = Util.lower((rec.name or "") .. " " .. (rec.rarity or "") .. " "
            .. (rec.island or "") .. " " .. (rec.raw or ""))
        local ok = false
        for _, w in ipairs(CONFIG.EggWhitelist) do
            if Util.has(hay, w) then ok = true break end
        end
        if not ok then return false end
    end

    if CONFIG.EggSkipFailed and Scanner.isFailed(rec) then return false end

    return true
end

local SORTERS = {
    rarity = function(a, b)
        if a.tier ~= b.tier then return a.tier > b.tier end
        return a.dist < b.dist
    end,
    income = function(a, b)
        local ia, ib = a.income or 0, b.income or 0
        if ia ~= ib then return ia > ib end
        return a.dist < b.dist
    end,
    nearest = function(a, b)
        return a.dist < b.dist
    end,
}

function Scanner.matching(limit)
    local out = {}
    for _, rec in ipairs(Scanner.list) do
        if Scanner.passesFilter(rec) then
            table.insert(out, rec)
        end
    end
    table.sort(out, SORTERS[CONFIG.EggFarmPriority] or SORTERS.rarity)
    if limit and #out > limit then
        local trimmed = {}
        for i = 1, limit do trimmed[i] = out[i] end
        out = trimmed
    end
    return out
end

function Scanner.bestTarget()
    local list = Scanner.matching()
    return list[1]
end

function Scanner.counts()
    local total, matching, unknown = 0, 0, 0
    for _, rec in ipairs(Scanner.list) do
        total = total + 1
        if rec.rarity == "Unknown" then unknown = unknown + 1 end
        if Scanner.passesFilter(rec) then matching = matching + 1 end
    end
    return total, matching, unknown
end

function Scanner.clear()
    for obj, rec in pairs(Scanner.eggs) do
        if SaB.ESP then SaB.ESP.detach(rec) end
        Scanner.eggs[obj] = nil
    end
    Scanner.failed = {}
    Scanner.list = {}
    Scanner.stats.bySource = {}
    Scanner.stats.byRarity = {}
end

function Scanner.getByObj(obj)
    return Scanner.eggs[obj]
end

--==============================================================
--  LIVE WATCHERS  (this is what finds the eggs that spawn LATER)
--==============================================================

Workspace.DescendantAdded:Connect(function(obj)
    if not CONFIG.EggLiveScan then return end
    if Scanner.budget <= 0 then Scanner.budget = 200 end
    pcall(function()
        Scanner.registerRoot(obj)
        if obj:IsA("Model") or obj:IsA("BasePart") then
            Scanner.add(obj, true)
        end
    end)
end)

Workspace.DescendantRemoving:Connect(function(obj)
    if Scanner.eggs[obj] then
        local rec = Scanner.eggs[obj]
        Scanner.eggs[obj] = nil
        if SaB.ESP then SaB.ESP.detach(rec) end
    end
end)

-- remember every prompt the game shows us: with this we can tell what the
-- real "pick up" action is called in this place
Scanner.promptLog = {}
Scanner.onAlert   = function() end   -- set by 09_Extras / the UI
SaB.Services.ProximityPromptService.PromptShown:Connect(function(prompt)
    pcall(function()
        local parent = prompt.Parent
        local line = ("%s | action='%s' | key='%s' | hold=%.1f | path=%s"):format(
            prompt.ClassName, tostring(prompt.ActionText), tostring(prompt.KeyboardKeyCode),
            tonumber(prompt.HoldDuration) or 0, Util.path(parent))
        if #Scanner.promptLog > 60 then table.remove(Scanner.promptLog, 1) end
        local dupe = false
        for _, l in ipairs(Scanner.promptLog) do
            if l == line then dupe = true break end
        end
        if not dupe then table.insert(Scanner.promptLog, line) end
        Scanner.add(parent, false)
    end)
end)

--==============================================================
--  BACKGROUND LOOP
--==============================================================
task.spawn(function()
    Scanner.deepScan(false)
    while SaB.Running do
        task.wait(0.25)
        pcall(function()
            Scanner.refresh()
            if CONFIG.EggLiveScan then
                if now() - Scanner.stats.lastScan >= CONFIG.EggScanInterval then
                    Scanner.stats.lastScan = now()
                    Scanner.quickScan()
                end
                if now() - Scanner.stats.lastDeep >= CONFIG.EggDeepScanInterval then
                    Scanner.deepScan(true)
                end
            end
            if SaB.ESP then SaB.ESP.update() end
        end)
    end
end)


--==============================================================
--  MODULE: 04_EggESP.lua
--==============================================================
--==============================================================
--  EGG ESP  (the labels you see above every egg)
--
--  Every label is built the same way so the list is easy to read:
--
--        +-----------------------------+
--        |      Dragon Cannelloni      |   <- name, colour = rarity
--        |   [ SECRET ]  Heavenly      |   <- category chip + island
--        |      820m     1:45          |   <- distance + despawn timer
--        +-----------------------------+
--
--  Everything is centred over the egg, the box auto-fits the text,
--  and the colour always matches the rarity (no more grey "unknown").
--==============================================================

local ESP = {}
SaB.ESP = ESP

local CONFIG = SaB.CONFIG
local Util   = SaB.Util

ESP.parts   = {}      -- [obj] = { bb, frame, nameLbl, chip, chipLbl, infoLbl, highlight }
ESP.MAX     = 120     -- safety: never build more than this many labels
ESP.TEXT_SCALE = 1

do
    local s = Util.clamp(math.min(Camera.ViewportSize.X, Camera.ViewportSize.Y) / 720, 0.85, 1.4)
    ESP.TEXT_SCALE = s
end

local function scale(n)
    return n * ESP.TEXT_SCALE * Util.clamp(CONFIG.EggLabelScale, 0.6, 1.8)
end

local function adorneeFor(rec)
    local obj = rec.obj
    if obj:IsA("BasePart") then return obj end
    if obj.PrimaryPart then return obj.PrimaryPart end
    local ok, part = pcall(function() return obj:FindFirstChildWhichIsA("BasePart", true) end)
    if ok and part then return part end
    return nil
end

local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = inst
    return c
end

--==============================================================
--  BUILD ONE LABEL
--==============================================================
function ESP.build(rec)
    if ESP.parts[rec.obj] then return ESP.parts[rec.obj] end
    local adornee = adorneeFor(rec)
    if not adornee then return nil end

    local color = SaB.Rarity.color(rec.rarity)
    local s = ESP.TEXT_SCALE

    local bb = Instance.new("BillboardGui")
    bb.Name = "SaB_EggLabel"
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 180 * s, 0, 64 * s)
    bb.StudsOffset = Vector3.new(0, (rec.height or 2) / 2 + 2.4, 0)
    bb.AlwaysOnTop = CONFIG.EggAlwaysOnTop
    bb.MaxDistance = CONFIG.EggEspMaxDistance      -- islands are far away!
    bb.LightInfluence = 0                          -- keep the text readable
    bb.ResetOnSpawn = false
    bb.ClipsDescendants = false
    bb.Enabled = true

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
    frame.BackgroundTransparency = 0.32
    frame.BorderSizePixel = 0
    frame.Parent = bb
    corner(frame, 8 * s)

    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 2
    stroke.Transparency = 0.15
    stroke.Parent = frame

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4 * s)
    pad.PaddingBottom = UDim.new(0, 3 * s)
    pad.PaddingLeft = UDim.new(0, 6 * s)
    pad.PaddingRight = UDim.new(0, 6 * s)
    pad.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 1)
    layout.Parent = frame

    -- row 1 : name (centred, rarity colour)
    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1, 0, 0, 17 * s)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = scale(14)
    nameLbl.TextColor3 = color
    nameLbl.TextStrokeTransparency = 0.35
    nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Text = rec.name or "?"
    nameLbl.LayoutOrder = 1
    nameLbl.Parent = frame

    -- row 2 : chip + island + income
    local row2 = Instance.new("Frame")
    row2.BackgroundTransparency = 1
    row2.Size = UDim2.new(1, 0, 0, 15 * s)
    row2.LayoutOrder = 2
    row2.Parent = frame

    local row2Layout = Instance.new("UIListLayout")
    row2Layout.FillDirection = Enum.FillDirection.Horizontal
    row2Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    row2Layout.VerticalAlignment = Enum.VerticalAlignment.Center
    row2Layout.Padding = UDim.new(0, 4 * s)
    row2Layout.Parent = row2

    -- category chip (coloured pill, never grey unless really unknown)
    local chip = Instance.new("TextLabel")
    chip.BackgroundColor3 = color
    chip.BackgroundTransparency = 0.12
    chip.Font = Enum.Font.GothamBold
    chip.TextSize = scale(10)
    chip.TextColor3 = Color3.fromRGB(10, 10, 14)
    chip.TextXAlignment = Enum.TextXAlignment.Center
    chip.Size = UDim2.new(0, 56 * s, 0, 13 * s)
    chip.Text = " " .. (SaB.Rarity.SHORT[rec.rarity] or "???") .. " "
    chip.AutomaticSize = Enum.AutomaticSize.X
    chip.Parent = row2
    corner(chip, 6 * s)

    local infoLbl = Instance.new("TextLabel")
    infoLbl.BackgroundTransparency = 1
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = scale(10)
    infoLbl.TextColor3 = Color3.fromRGB(226, 231, 240)
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.TextStrokeTransparency = 0.5
    infoLbl.AutomaticSize = Enum.AutomaticSize.X
    infoLbl.Size = UDim2.new(0, 0, 0, 13 * s)
    infoLbl.Text = (rec.island and (rec.island .. "  ") or "")
        .. (rec.incomeText and (rec.incomeText .. "  ") or "")
    infoLbl.Parent = row2

    -- row 3 : distance + timer
    local info2 = Instance.new("TextLabel")
    info2.BackgroundTransparency = 1
    info2.Size = UDim2.new(1, 0, 0, 13 * s)
    info2.Font = Enum.Font.Gotham
    info2.TextSize = scale(10)
    info2.TextColor3 = Color3.fromRGB(190, 198, 214)
    info2.TextStrokeTransparency = 0.5
    info2.TextXAlignment = Enum.TextXAlignment.Center
    info2.Text = ""
    info2.LayoutOrder = 3
    info2.Parent = frame

    bb.Parent = adornee

    local part = {
        bb = bb, frame = frame, stroke = stroke,
        nameLbl = nameLbl, chip = chip, infoLbl = infoLbl, info2 = info2,
        row2 = row2,
    }

    if CONFIG.EggHighlight then
        ESP.addHighlight(rec, part)
    end

    ESP.parts[rec.obj] = part
    ESP.resize(part, rec)
    return part
end

function ESP.addHighlight(rec, part)
    if part.highlight then return end
    local ok = pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "SaB_EggHighlight"
        h.Adornee = rec.obj
        h.FillColor = SaB.Rarity.color(rec.rarity)
        h.FillTransparency = 0.72
        h.OutlineColor = SaB.Rarity.color(rec.rarity)
        h.OutlineTransparency = 0
        h.DepthMode = CONFIG.EggAlwaysOnTop
            and Enum.HighlightDepthMode.AlwaysOnTop
            or Enum.HighlightDepthMode.Occluded
        h.Parent = part.bb
        part.highlight = h
    end)
    return ok
end

function ESP.removeHighlight(part)
    if part and part.highlight then
        pcall(function() part.highlight:Destroy() end)
        part.highlight = nil
    end
end

-- fit the box to the text (looks much tidier than a fixed wide box)
function ESP.resize(part, rec)
    local s = ESP.TEXT_SCALE
    local nameW = part.nameLbl.TextBounds.X
    if nameW <= 0 then nameW = 120 * s end
    local w = math.max(nameW + 26 * s, (part.infoLbl.TextBounds.X or 0) + 70 * s, 96 * s)
    local h = (CONFIG.EggEspName and 17 * s or 0)
        + (CONFIG.EggEspRarity and 15 * s or 0)
        + ((CONFIG.EggEspDistance or CONFIG.EggEspIsland) and 13 * s or 0)
        + 8 * s
    part.bb.Size = UDim2.new(0, math.min(w, 420 * s), 0, math.max(h, 26 * s))
end

--==============================================================
--  ATTACH / DETACH
--==============================================================
function ESP.attach(rec)
    if not rec or not rec.obj or rec.obj.Parent == nil then return end
    if ESP.parts[rec.obj] then return end
    if Util.tableCount(ESP.parts) >= ESP.MAX then return end
    pcall(function() ESP.build(rec) end)
end

function ESP.detach(rec)
    if not rec then return end
    local part = ESP.parts[rec.obj]
    if not part then return end
    pcall(function()
        if part.bb then part.bb:Destroy() end
    end)
    ESP.parts[rec.obj] = nil
end

function ESP.detachByObj(obj)
    local part = ESP.parts[obj]
    if not part then return end
    pcall(function() if part.bb then part.bb:Destroy() end end)
    ESP.parts[obj] = nil
end

function ESP.clear()
    for obj, part in pairs(ESP.parts) do
        pcall(function() if part.bb then part.bb:Destroy() end end)
        ESP.parts[obj] = nil
    end
end

function ESP.rebuild()
    ESP.clear()
    for _, rec in pairs(SaB.Scanner.eggs) do
        ESP.attach(rec)
    end
end

--==============================================================
--  LIVE UPDATE
--==============================================================
function ESP.update()
    local enabled = CONFIG.EggESPEnabled
    for obj, rec in pairs(SaB.Scanner.eggs) do
        if obj.Parent == nil then
            SaB.Scanner.eggs[obj] = nil
            ESP.detach(rec)
        elseif enabled then
            ESP.attach(rec)
        elseif ESP.parts[obj] then
            ESP.detach(rec)
        end
    end

    if not enabled then return end

    for obj, part in pairs(ESP.parts) do
        local rec = SaB.Scanner.eggs[obj]
        if not rec then
            ESP.detachByObj(obj)
        else
            pcall(function()
                part.nameLbl.Visible = CONFIG.EggEspName
                part.row2.Visible    = CONFIG.EggEspRarity or CONFIG.EggEspIsland
                part.infoLbl.Visible = CONFIG.EggEspIsland

                -- keep the colour in sync (rarity can be learned later)
                local color = SaB.Rarity.color(rec.rarity)
                part.nameLbl.TextColor3 = color
                part.stroke.Color = color
                part.chip.BackgroundColor3 = color
                part.chip.Text = " " .. (SaB.Rarity.SHORT[rec.rarity] or "???") .. " "

                if CONFIG.EggEspIsland then
                    part.infoLbl.Text = (rec.island and (rec.island .. "  ") or "")
                        .. (rec.incomeText and (rec.incomeText .. "  ") or "")
                else
                    part.infoLbl.Text = rec.incomeText or ""
                end

                local bits = {}
                if CONFIG.EggEspDistance then
                    table.insert(bits, Util.formatDistance(rec.dist))
                end
                if rec.timerLeft and rec.timerLeft > 0 then
                    table.insert(bits, Util.formatClock(rec.timerLeft))
                end
                part.info2.Text = table.concat(bits, "   ")
                part.info2.Visible = #bits > 0

                -- far away eggs fade a little so the screen stays readable
                local far = rec.dist > 1200
                part.frame.BackgroundTransparency = far and 0.5 or 0.32

                if CONFIG.EggHighlight then
                    if not part.highlight then ESP.addHighlight(rec, part) end
                    if part.highlight then
                        part.highlight.FillColor = color
                        part.highlight.OutlineColor = color
                        part.highlight.DepthMode = CONFIG.EggAlwaysOnTop
                            and Enum.HighlightDepthMode.AlwaysOnTop
                            or Enum.HighlightDepthMode.Occluded
                    end
                else
                    ESP.removeHighlight(part)
                end
            end)
        end
    end
end


--==============================================================
--  MODULE: 05_EggFarm.lua
--==============================================================
--==============================================================
--  MOVEMENT  +  PICK UP  +  AUTO FARM
--
--  The old farm did nothing because of two bugs:
--    1. it called a function that was declared LATER (nil call -> crash)
--    2. it only tried the prompt, then gave up silently
--
--  This version walks there step by step (no falling into the void),
--  tries 5 different ways to grab the egg, tells you which one worked,
--  brings it back to your base and waits for the hatch.
--==============================================================

local Farm = {}
SaB.Farm = Farm

local CONFIG  = SaB.CONFIG
local Util    = SaB.Util

Farm.stats = {
    delivered = 0, failed = 0, cycles = 0, lastEgg = "-", lastWhy = "-",
    history = {},          -- { time , name , rarity }
}
Farm.onDelivery = function() end
Farm.busy  = false
Farm.state = "idle"
Farm.onStatus = function() end

local lastStatus = ""
local function status(text, color)
    Farm.state = text
    if text ~= lastStatus then          -- no spam while waiting for eggs
        lastStatus = text
        Log.farm(text, color)
    end
    pcall(Farm.onStatus, text, color)
end

--==============================================================
--  TELEPORT
--
--  Why you were snapping back to spawn (the bug you reported):
--    1. 60-stud CFrame jumps (~600 studs/s). The server anti-cheat
--       rejects that and rubberbands you to the last VALID position
--       (your start). Client already showed you flying, then - pop.
--    2. Instant jump whenever the egg was < 80 studs away. Same thing.
--    3. Gravity between steps + no noclip → you fall / get flung /
--       die → respawn at the start, and the pickup never happens
--       because the SERVER still thinks you are at spawn.
--    4. "I arrived" was a lie: it never checked the real position.
--
--  This version (v2.3):
--    • speed-capped fly (default 80 studs/s) so the server accepts it
--    • noclip + PlatformStand so islands / gravity cannot fling you
--    • anti-rubberband: the PATH is the source of truth. If the server
--      snaps you, we put you back on the path (we do NOT follow the snap)
--    • hold still on arrival until the server actually has you there
--    • only returns true when you ARE within EggTpArriveDist of the target
--==============================================================
local Teleport = {}
Farm.Teleport = Teleport
Teleport.cancelFlag = false
Teleport.lastSafe = nil
Teleport.origin = nil
Teleport.flying = false
Teleport.progress = 0
Teleport.lastWhy = "idle"
Teleport.gen = 0
Teleport.stats = { flights = 0, arrived = 0, snapped = 0, failed = 0 }
Teleport.onProgress = function(pct, left)
    pcall(Farm.onStatus,
        ("FLYING  %d%%  %s left"):format(pct, Util.formatDistance(left)),
        SaB.Theme.ACC)
end

function Teleport.isSim()
    return _G.World ~= nil
end

function Teleport.cancel()
    Teleport.cancelFlag = true
    Teleport.gen = (Teleport.gen or 0) + 1
    Farm.setAnchor(false)      -- never leave the player frozen in the air
    Teleport.cleanupFlight()
end

-- freeze / unfreeze the character while we wait for the game to react
function Farm.setAnchor(state)
    if state and not CONFIG.EggAnchorWhileWaiting then return end
    local hrp = Util.getHRP()
    if not hrp then return end
    pcall(function() hrp.Anchored = state and true or false end)
end

local collideSaved = {}
local humSaved = nil
local holdConn = nil

local function zeroVel(hrp)
    if not hrp then return end
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
    end)
end

local function pulseNoclip()
    if not CONFIG.EggTpNoclip then return end
    local char = Util.getChar()
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            if collideSaved[p] == nil then
                local ok, v = pcall(function() return p.CanCollide end)
                collideSaved[p] = (ok and v) or false
            end
            pcall(function() p.CanCollide = false end)
        end
    end
end

local function restoreNoclip()
    for p, v in pairs(collideSaved) do
        pcall(function()
            if p and p.Parent then p.CanCollide = v end
        end)
    end
    collideSaved = {}
end

local function prepareHumanoid()
    local hum = Util.getHumanoid()
    if not hum then return end
    if not humSaved then
        humSaved = {
            PlatformStand = hum.PlatformStand,
            AutoRotate = hum.AutoRotate,
            Sit = hum.Sit,
        }
    end
    pcall(function()
        hum.Sit = false
        hum.PlatformStand = true
        hum.AutoRotate = false
        if hum.ChangeState then
            hum:ChangeState(Enum.HumanoidStateType.Physics)
        end
    end)
end

local function restoreHumanoid()
    local hum = Util.getHumanoid()
    local saved = humSaved
    humSaved = nil
    if not hum or not saved then return end
    pcall(function()
        hum.PlatformStand = saved.PlatformStand and true or false
        hum.AutoRotate = (saved.AutoRotate ~= false)
        if hum.ChangeState then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
end

function Teleport.cleanupFlight()
    Teleport.flying = false
    if holdConn then
        pcall(function() holdConn:Disconnect() end)
        holdConn = nil
    end
    restoreNoclip()
    restoreHumanoid()
    local hrp = Util.getHRP()
    zeroVel(hrp)
end

-- put the whole character on `pos` (PivotTo when we can, else HRP)
local function applyPos(pos, lookAt)
    local hrp = Util.getHRP()
    if not hrp or not pos then return false end
    local cf
    if lookAt then
        local flat = Vector3.new(lookAt.X - pos.X, 0, lookAt.Z - pos.Z)
        if flat.Magnitude > 1 then
            cf = CFrame.new(pos, pos + flat)
        end
    end
    cf = cf or CFrame.new(pos)
    local applied = false
    pcall(function()
        local char = Util.getChar()
        if char and char.PivotTo then
            char:PivotTo(cf)
            applied = true
        end
    end)
    if not applied then
        pcall(function()
            hrp.CFrame = cf
        end)
    end
    zeroVel(hrp)
    return true
end

-- kept so older call sites / tests that poke at the mover still work
local function setCFrame(pos)
    return applyPos(pos)
end

function Teleport.arrived(pos, limit)
    local hrp = Util.getHRP()
    if not hrp or not pos then return false end
    local dest = Vector3.new(pos.X, pos.Y + 3, pos.Z)
    return (hrp.Position - dest).Magnitude <= (limit or CONFIG.EggTpArriveDist or 10)
end

local function destOf(target)
    return Vector3.new(target.X, target.Y + 3, target.Z)
end

local function liveTarget(target, follow)
    if follow then
        local ok, parent = pcall(function() return follow.Parent end)
        if ok and parent then
            local p = Util.getPos(follow)
            if p then return p end
        end
    end
    return target
end

local function modeName()
    if not CONFIG.EggSafeTeleport then return "instant" end
    local m = CONFIG.EggTpMode or "smooth"
    if m == "fast" or m == "instant" or m == "smooth" then return m end
    return "smooth"
end

function Teleport.modeSpeed()
    local mode = modeName()
    if mode == "instant" then return nil end
    local base = tonumber(CONFIG.EggTpSpeed) or 80
    if mode == "fast" then return math.max(120, base) end
    return math.max(22, base)
end

-- climb first, cross high, then land - never walk through an island
local function waypoints(from, dest)
    local arc = tonumber(CONFIG.EggTpArcHeight) or 0
    local points = {}
    local flat = Vector3.new(dest.X - from.X, 0, dest.Z - from.Z)
    local dy = dest.Y - from.Y
    if arc > 0 and (flat.Magnitude > 18 or math.abs(dy) > 18) then
        local cruiseY = math.max(from.Y, dest.Y) + arc
        table.insert(points, Vector3.new(from.X, cruiseY, from.Z))
        table.insert(points, Vector3.new(dest.X, cruiseY, dest.Z))
    elseif math.abs(dy) > 40 then
        table.insert(points, Vector3.new(from.X, dest.Y, from.Z))
    end
    table.insert(points, dest)
    return points
end

local function startHoldLoop(getIntended)
    if Teleport.isSim() then return end
    if holdConn then
        pcall(function() holdConn:Disconnect() end)
        holdConn = nil
    end
    pcall(function()
        holdConn = SaB.Services.RunService.Heartbeat:Connect(function()
            if not Teleport.flying then return end
            pulseNoclip()
            local hrp = Util.getHRP()
            if not hrp then return end
            zeroVel(hrp)
            if not CONFIG.EggTpAntiRubber then return end
            local intended = getIntended()
            if intended and (hrp.Position - intended).Magnitude > 8 then
                Teleport.stats.snapped = Teleport.stats.snapped + 1
                applyPos(intended)
            end
        end)
    end)
end

local function holdAt(pos, seconds)
    seconds = tonumber(seconds) or 0
    if seconds <= 0 or Teleport.isSim() then
        applyPos(pos)
        return
    end
    local t0 = tick()
    while (tick() - t0) < seconds do
        if Teleport.cancelFlag then return end
        applyPos(pos)
        pulseNoclip()
        zeroVel(Util.getHRP())
        task.wait()
    end
end

-- fly along the path. `intended` is the source of truth (NOT hrp.Position)
-- so a server snap cannot drag us back to spawn.
function Teleport.stepTo(target, follow)
    local hrp = Util.getHRP()
    if not hrp or not target then return false end
    local myGen = Teleport.gen

    local speed = Teleport.modeSpeed() or 80
    local arrive = tonumber(CONFIG.EggTpArriveDist) or 10
    local intended = hrp.Position
    local rubberWarned = false
    local lastUi = -10

    local function currentDest()
        return destOf(liveTarget(target, follow))
    end

    startHoldLoop(function() return intended end)

    local function tickToward(dest, dt)
        local hrp2 = Util.getHRP()
        if not hrp2 then return false, "dead" end
        if CONFIG.EggTpAntiRubber then
            local drift = (hrp2.Position - intended).Magnitude
            if drift > 10 then
                Teleport.stats.snapped = Teleport.stats.snapped + 1
                if not rubberWarned then
                    rubberWarned = true
                    Log.warn("server tried to snap you back - staying on the path")
                end
                applyPos(intended)
                speed = math.max(22, speed * 0.88)
            end
        end
        local delta = dest - intended
        local dist = delta.Magnitude
        local step = math.max(0.5, speed * dt)
        if dist <= math.max(step, arrive) then
            intended = dest
            applyPos(intended)
            return true
        end
        intended = intended + (delta.Unit * step)
        applyPos(intended, dest)
        pulseNoclip()
        return false
    end

    local dest = currentDest()
    local path = waypoints(intended, dest)
    local total = math.max(1, (hrp.Position - dest).Magnitude)
    local deadline = tick() + math.max(8, total / math.max(18, speed) + 8)
    local hops = 0

    for i, wp in ipairs(path) do
        while true do
            hops = hops + 1
            if hops > 25000 then
                Teleport.lastWhy = "timeout"
                return false
            end
            if Teleport.cancelFlag or Teleport.gen ~= myGen then return false end
            if not Util.isAlive() then return false end
            dest = currentDest()
            -- last waypoint tracks a moving egg
            if i == #path then wp = dest end
            local now = tick()
            if now > deadline then
                Teleport.lastWhy = "timeout"
                return false
            end
            local hrp2 = Util.getHRP()
            if not hrp2 then return false end
            if hrp2.Position.Y < -120 then
                applyPos(intended)
                if hrp2.Position.Y < -120 then
                    Teleport.rescue()
                    Teleport.lastWhy = "void"
                    return false
                end
            end

            local dt
            if Teleport.isSim() then
                dt = 1 / 20
            else
                local t0 = tick()
                task.wait(CONFIG.EggStepDelay or 0)
                dt = tick() - t0
                if dt <= 0 or dt > 0.25 then dt = 1 / 60 end
            end

            local reached = tickToward(wp, dt)
            local left = (dest - intended).Magnitude
            local pct = Util.clamp(Util.round((1 - left / total) * 100), 0, 99)
            Teleport.progress = pct
            if pct - lastUi >= 15 then
                lastUi = pct
                pcall(Teleport.onProgress, pct, left)
            end
            if reached then break end
        end
    end

    dest = currentDest()
    intended = dest
    applyPos(dest)
    holdAt(dest, CONFIG.EggTpHoldArrive)

    hrp = Util.getHRP()
    if hrp and (hrp.Position - dest).Magnitude <= math.max(arrive, 18) then
        return true
    end
    -- one last shove
    applyPos(dest)
    hrp = Util.getHRP()
    return hrp ~= nil and (hrp.Position - dest).Magnitude <= 25
end

function Teleport.to(target, follow)
    Teleport.gen = (Teleport.gen or 0) + 1
    local myGen = Teleport.gen
    Teleport.cancelFlag = false
    Farm.setAnchor(false)

    local hrp = Util.getHRP()
    if not hrp or not target then
        Teleport.lastWhy = "no character"
        return false
    end

    Teleport.stats.flights = Teleport.stats.flights + 1
    Teleport.origin = hrp.Position
    if hrp.Position.Y > -50 then
        Teleport.lastSafe = hrp.Position
    end
    Teleport.flying = true
    Teleport.progress = 0
    Teleport.lastWhy = "flying"
    prepareHumanoid()
    pulseNoclip()

    local dist = (hrp.Position - target).Magnitude
    local ok = false
    local mode = modeName()

    local flown, err = pcall(function()
        if mode == "instant" then
            local dest = destOf(liveTarget(target, follow))
            applyPos(dest)
            holdAt(dest, math.min(0.20, CONFIG.EggTpHoldArrive or 0))
            return Teleport.arrived(liveTarget(target, follow), 25)
        end
        -- even short hops go through the flyer: an 80-stud instant
        -- jump is exactly what the anti-cheat rubberbands
        if dist <= (CONFIG.EggTpArriveDist or 10) + 2 then
            local dest = destOf(target)
            applyPos(dest)
            holdAt(dest, CONFIG.EggTpHoldArrive)
            return true
        end
        return Teleport.stepTo(target, follow)
    end)

    if myGen == Teleport.gen then
        Teleport.cleanupFlight()
    end

    if myGen ~= Teleport.gen then
        Teleport.lastWhy = "superseded"
        return false
    end
    if Teleport.cancelFlag then
        Teleport.lastWhy = "cancelled"
        Teleport.stats.failed = Teleport.stats.failed + 1
        return false
    end
    if not flown then
        Teleport.lastWhy = "error"
        Teleport.stats.failed = Teleport.stats.failed + 1
        Log.warn("teleport error: " .. tostring(err))
        return false
    end
    ok = err and true or false
    if ok then
        Teleport.lastWhy = "arrived"
        Teleport.progress = 100
        Teleport.stats.arrived = Teleport.stats.arrived + 1
        local here = Util.getHRP()
        if here and here.Position.Y > -50 then
            Teleport.lastSafe = here.Position
        end
    else
        Teleport.lastWhy = Teleport.lastWhy ~= "flying" and Teleport.lastWhy or "did not arrive"
        Teleport.stats.failed = Teleport.stats.failed + 1
    end
    return ok
end

-- anti void: if we somehow fall out of the map, hop back
function Teleport.rescue()
    local hrp = Util.getHRP()
    if not hrp then return false end
    if hrp.Position.Y > -120 then return false end
    local back = Teleport.lastSafe
    if not back then
        local base = Farm.Base and Farm.Base.get()
        back = base and base.pos
    end
    if back then
        applyPos(back + Vector3.new(0, 8, 0))
        Log.warn("fell out of the map - hopped back")
        return true
    end
    return false
end

--==============================================================
--  BASE  (where we bring the egg back to)
--==============================================================
local Base = {}
Farm.Base = Base
Base.cached = nil
Base.cachedAt = 0
Base.source = "?"
Base.manual = nil

function Base.set(pos, label)
    if not pos then return end
    Base.manual = pos
    Base.source = label or "set by you"
    Base.cached = nil
end

function Base.find()
    local name = SaB.LocalPlayer.Name
    local uid = SaB.LocalPlayer.UserId

    -- 1) a container named after you
    local direct = SaB.Services.Workspace:FindFirstChild(name)
    local p = Util.getPos(direct)
    if p then return p, "workspace/" .. name end

    -- 2) Bases / Plots folders
    for _, folderName in ipairs({ "Bases", "Base", "Plots", "Plot", "PlotsFolder", "PlayerBases" }) do
        local folder = SaB.Services.Workspace:FindFirstChild(folderName)
        if folder then
            local mine = folder:FindFirstChild(name) or folder:FindFirstChild(tostring(uid))
            p = Util.getPos(mine)
            if p then return p, folderName .. "/" .. tostring(mine.Name) end
        end
    end

    -- 3) anything claiming to be owned by us
    local found, label
    for _, obj in ipairs(SaB.Services.Workspace:GetChildren()) do
        local attrs = Util.getAttributes(obj)
        local owner = attrs.Owner or attrs.OwnerName or attrs.PlayerName or attrs.Player
        local ownerId = attrs.OwnerId or attrs.OwnerUserId or attrs.UserId
        if (type(owner) == "string" and Util.lower(owner) == Util.lower(name))
            or (ownerId ~= nil and tonumber(ownerId) == uid) then
            local pp = Util.getPos(obj)
            if pp then found, label = pp, obj.Name .. " (owner attribute)" break end
        end
        -- folders holding a plot with our name (one level deep is enough)
        if obj:IsA("Folder") or obj:IsA("Model") then
            for _, child in ipairs(obj:GetChildren()) do
                local ca = Util.getAttributes(child)
                local cowner = ca.Owner or ca.OwnerName or ca.PlayerName
                local cid = ca.OwnerId or ca.OwnerUserId
                if (type(cowner) == "string" and Util.lower(cowner) == Util.lower(name))
                    or (cid ~= nil and tonumber(cid) == uid) then
                    local pp = Util.getPos(child)
                    if pp then found, label = pp, obj.Name .. "/" .. child.Name break end
                end
            end
        end
        if found then break end
    end
    if found then return found, label end

    -- 4) attributes / respawn point
    local cf = SaB.LocalPlayer:GetAttribute("BaseCFrame") or SaB.LocalPlayer:GetAttribute("Base")
    if typeof(cf) == "CFrame" then return cf.Position, "player attribute" end
    if typeof(cf) == "Vector3" then return cf, "player attribute (Vector3)" end

    if SaB.LocalPlayer.RespawnLocation then
        p = Util.getPos(SaB.LocalPlayer.RespawnLocation)
        if p then return p, "RespawnLocation" end
    end
    local spawn = SaB.Services.Workspace:FindFirstChild("SpawnLocation") or SaB.Services.Workspace:FindFirstChild("Spawn")
    p = Util.getPos(spawn)
    if p then return p, "spawn point" end

    -- 5) where we were standing when the script loaded
    if Base.startPos then return Base.startPos, "start position" end
    return nil, "?"
end

function Base.get()
    if Base.manual then
        return { pos = Base.manual, source = "set by you" }
    end
    if Base.cached and (tick() - Base.cachedAt) < 10 then
        return Base.cached
    end
    local pos, source = Base.find()
    if pos then
        Base.cached = { pos = pos, source = source }
        Base.cachedAt = tick()
        Base.source = source
    end
    return Base.cached
end

task.spawn(function()
    task.wait(1.5)
    local hrp = Util.getHRP()
    if hrp then Base.startPos = hrp.Position end
end)

--==============================================================
--  CARRYING DETECTION
--==============================================================
local Carry = {}
Farm.Carry = Carry

Carry.WORDS = { "egg", "carry", "carrying", "hold", "holding", "grab" }

function Carry.what()
    local char = Util.getChar()
    if not char then return nil end
    for _, d in ipairs(char:GetDescendants()) do
        local n = Util.lower(d.Name)
        for _, w in ipairs(Carry.WORDS) do
            if n:find(w, 1, true) then
                return d.Name
            end
        end
        if SaB.EggDB.lookup(d.Name) then return d.Name end
    end
    -- some games keep it on the player instead of the character
    for k, v in pairs(Util.getAttributes(SaB.LocalPlayer)) do
        local nk = Util.lower(k)
        if (nk:find("carry") or nk:find("hold") or nk:find("egg")) and v and v ~= false and v ~= "" then
            return k
        end
    end
    return nil
end

function Carry.state()
    return Carry.what() ~= nil
end

--==============================================================
--  PICK UP
--==============================================================
local Pickup = {}
Farm.Pickup = Pickup

Pickup.methods = {
    "proximity prompt (fire)", "proximity prompt (hold)",
    "click detector", "touch (stand on it)", "remote (experimental)",
}
Pickup.lastMethod = "-"

local function refreshPrompts(rec)
    local list = rec.prompts or {}
    if #list == 0 then
        list = Util.findPrompts(rec.obj, 4)
        rec.prompts = list
    end
    local alive = {}
    for _, p in ipairs(list) do
        if p and p.Parent then table.insert(alive, p) end
    end
    rec.prompts = alive
    return alive
end

local function tryFirePrompt(prompt)
    if typeof(fireproximityprompt) == "function" then
        pcall(function() fireproximityprompt(prompt, 0) end)
        task.wait(math.max(0.15, (tonumber(prompt.HoldDuration) or 0) + 0.15))
        return true
    end
    return false
end

local function tryHoldPrompt(prompt)
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(0.2, (tonumber(prompt.HoldDuration) or 0) + 0.25))
        prompt:InputHoldEnd()
    end)
    return ok
end

local function tryClick(rec)
    local clicks = rec.clicks or Util.findClickDetectors(rec.obj, 2)
    if #clicks == 0 then return false end
    if typeof(fireclickdetector) == "function" then
        for _, cd in ipairs(clicks) do
            pcall(function() fireclickdetector(cd) end)
            task.wait(0.25)
        end
        return true
    end
    return false
end

local function tryTouch(rec)
    Teleport.to(rec.pos, rec.obj)
    task.wait(CONFIG.EggPickupDelay)
    return false   -- the game has to react, we only check afterwards
end

local function tryRemotes(rec)
    if not CONFIG.EggExperimentalRemotes then return false end
    local names = { "collect", "pickup", "pick", "grab", "egg", "hatch", "take" }
    local fired = 0
    for _, d in ipairs(SaB.Services.ReplicatedStorage:GetDescendants()) do
        if d:IsA("RemoteEvent") then
            local n = Util.lower(d.Name)
            for _, key in ipairs(names) do
                if n:find(key, 1, true) then
                    pcall(function() d:FireServer(rec.obj) end)
                    fired = fired + 1
                    break
                end
            end
            if fired > 6 then break end
        end
    end
    if fired > 0 then
        Log.warn(("experimental: fired %d 'collect' remotes"):format(fired))
        task.wait(0.5)
        return true
    end
    return false
end

--[[ returns true when the egg is ours (or at least disappeared) ]]
function Pickup.check(rec)
    if Carry.state() then return true, "carrying: " .. tostring(Carry.what()) end
    if rec.obj.Parent == nil then return true, "egg is gone from the map" end
    return false
end

function Pickup.attempt(rec)
    local deadline = tick() + CONFIG.EggPickupTimeout
    local why = "unknown"

    -- get close first
    local hrp = Util.getHRP()
    if hrp and (hrp.Position - rec.pos).Magnitude > 25 then
        Teleport.to(rec.pos, rec.obj)
    end

    local attempts = 0
    while tick() < deadline and attempts < 8 do
        attempts = attempts + 1
        if Teleport.cancelFlag then break end

        -- 1) proximity prompt (fastest way)
        for _, prompt in ipairs(refreshPrompts(rec)) do
            if tryFirePrompt(prompt) then
                Pickup.lastMethod = "proximity prompt (fire)"
                local ok, reason = Pickup.check(rec)
                if ok then return true, reason end
            end
            if tick() > deadline then break end
            if tryHoldPrompt(prompt) then
                Pickup.lastMethod = "proximity prompt (hold)"
                local ok, reason = Pickup.check(rec)
                if ok then return true, reason end
            end
        end

        -- 2) click detector
        if tryClick(rec) then
            Pickup.lastMethod = "click detector"
            local ok, reason = Pickup.check(rec)
            if ok then return true, reason end
        end

        -- 3) just stand on it / touch it
        tryTouch(rec)
        Pickup.lastMethod = "touch (stand on it)"
        local ok, reason = Pickup.check(rec)
        if ok then return true, reason end

        -- 4) (optional) fire remotes that look like "collect"
        if CONFIG.EggExperimentalRemotes then
            if tryRemotes(rec) then
                Pickup.lastMethod = "remote (experimental)"
                local ok2, reason2 = Pickup.check(rec)
                if ok2 then return true, reason2 end
            end
        end

        Teleport.rescue()
        task.wait(0.25)
    end

    return false, why
end

--==============================================================
--  ONE FULL CYCLE :  go -> pick -> return -> hatch
--==============================================================
function Farm.cycle(rec)
    if not rec or not rec.obj or rec.obj.Parent == nil then
        return false, "egg disappeared"
    end

    Farm.stats.cycles = Farm.stats.cycles + 1
    Farm.stats.lastEgg = rec.name

    -- ---------- 1) travel ----------
    status(("TRAVEL  ->  %s  [%s]  %s"):format(rec.name, rec.rarity,
        Util.formatDistance(rec.dist)), SaB.Rarity.color(rec.rarity))
    local reached = Teleport.to(rec.pos, rec.obj)

    local hrp = Util.getHRP()
    if hrp then
        local d = (hrp.Position - rec.pos).Magnitude
        if (not reached) or d > 25 then
            reached = Teleport.to(rec.pos, rec.obj)
            task.wait(0.2)
        end
    end

    if not reached and not Teleport.arrived(rec.pos, 25) then
        Farm.stats.failed = Farm.stats.failed + 1
        Farm.stats.lastWhy = "travel failed (snapped back)"
        status(("TRAVEL FAILED  %s  - snapped back / did not arrive"):format(rec.name),
            SaB.Theme.BAD)
        return false, "travel failed"
    end

    -- ---------- 2) pick up ----------
    Farm.setAnchor(true)     -- do not slide off the island while grabbing it
    status(("PICK UP  %s   (trying %s)"):format(rec.name, "prompt / click / touch"),
        SaB.Theme.WARN)
    local ok, why = Pickup.attempt(rec)

    if not ok then
        Farm.setAnchor(false)
        Farm.stats.failed = Farm.stats.failed + 1
        Farm.stats.lastWhy = "could not grab it"
        SaB.Scanner.markFailed(rec)
        status(("FAILED  %s  - nothing worked (egg may need a jump / a key)"):format(rec.name),
            SaB.Theme.BAD)
        return false, "pickup failed"
    end

    status(("GOT IT  %s   via %s"):format(rec.name, Pickup.lastMethod), SaB.Theme.OK)

    -- ---------- 3) back to base ----------
    local base = Base.get()
    if not base then
        Farm.setAnchor(false)
        status(("holding %s but I cannot find your base - press 'Set base here'"):format(rec.name),
            SaB.Theme.BAD)
        return false, "no base"
    end

    status(("RETURN  %s  -> base (%s)"):format(rec.name, base.source), SaB.Theme.ACC)
    Farm.setAnchor(false)
    Teleport.to(base.pos)
    Farm.setAnchor(true)     -- wait for the hatch without falling

    -- ---------- 4) wait for the hatch ----------
    local waited = 0
    while waited < math.max(CONFIG.EggReturnDelay, 6) do
        task.wait(0.25)
        waited = waited + 0.25
        if not Carry.state() then break end
        if Teleport.cancelFlag then break end
    end

    Farm.setAnchor(false)
    Farm.stats.delivered = Farm.stats.delivered + 1
    table.insert(Farm.stats.history, {
        time = os.date("%H:%M:%S"), name = rec.name, rarity = rec.rarity,
    })
    if #Farm.stats.history > 60 then table.remove(Farm.stats.history, 1) end
    pcall(Farm.onDelivery, rec)
    status(("DELIVERED  %s   (total %d)"):format(rec.name, Farm.stats.delivered), SaB.Theme.OK)
    Util.notify("Egg farm", ("Delivered: %s [%s]"):format(rec.name, rec.rarity), 3)
    return true, "delivered"
end

-- manual: farm one specific egg (or the best one)
function Farm.runOnce(rec)
    if Farm.busy then
        status("already busy - wait for the current run", SaB.Theme.WARN)
        return
    end
    task.spawn(function()
        Farm.busy = true
        pcall(function()
            if not Util.isAlive() then Util.waitForCharacter(10) end
            local target = rec
            if not target or target.obj.Parent == nil then
                target = SaB.Scanner.bestTarget()
            end
            if not target then
                local total = Util.tableCount(SaB.Scanner.eggs)
                status(("no egg matches your filters (detected %d)"):format(total), SaB.Theme.WARN)
                return
            end
            local ok, why = Farm.cycle(target)
            if not ok then Farm.stats.lastWhy = tostring(why) end
        end)
        task.wait(0.5)
        Farm.busy = false
        if not CONFIG.EggAutoFarm then
            status("idle", SaB.Theme.DIM)
        end
    end)
end

--==============================================================
--  BACKGROUND LOOP
--==============================================================
task.spawn(function()
    while SaB.Running do
        task.wait(0.4)
        if CONFIG.EggAutoFarm and not Farm.busy then
            Farm.busy = true
            pcall(function()
                if Util.isAlive() then
                    Teleport.rescue()
                    local target = SaB.Scanner.bestTarget()
                    if target then
                        Farm.cycle(target)
                    else
                        local total = Util.tableCount(SaB.Scanner.eggs)
                        if total == 0 then
                            status("no eggs detected - press DEEP SCAN (or enter the LTM portal)",
                                SaB.Theme.WARN)
                        else
                            status(("no egg passes your filters (%d detected) - relax the filters"):format(total),
                                SaB.Theme.WARN)
                        end
                        task.wait(1.2)
                    end
                else
                    status("waiting for respawn...", SaB.Theme.WARN)
                    Util.waitForCharacter(20)
                end
            end)
            Farm.busy = false
        end
    end
end)

-- stop any movement the moment the user turns the farm off
task.spawn(function()
    local wasOn = CONFIG.EggAutoFarm
    while SaB.Running do
        task.wait(0.4)
        if wasOn and not CONFIG.EggAutoFarm then
            Teleport.cancel()
            status("stopped", SaB.Theme.DIM)
        end
        wasOn = CONFIG.EggAutoFarm
    end
end)


--==============================================================
--  MODULE: 06_Sniper.lua
--==============================================================
--==============================================================
--  CODE SNIPER
--
--  Listens to SpyderSammy (UserId 2678001507), builds the code
--  word by word while he says it, and writes it into the code box
--  the second it is complete.  Full TEST zone, no event needed.
--
--  Same logic as v1 (it was already spec'd and tested) with the
--  new logging / config plumbing.
--==============================================================

local Sniper = {}
SaB.Sniper = Sniper

local CONFIG = SaB.CONFIG
local Util   = SaB.Util

local NUMBER_WORDS = {
    zero = "0", one = "1", two = "2", three = "3", four = "4",
    five = "5", six = "6", seven = "7", eight = "8", nine = "9",
}

-- Sammy announces the type BEFORE the code
local CODE_TYPES = {
    { name = "Any (auto)",           words = nil, digits = nil },
    { name = "Letters only",         words = nil, digits = false },
    { name = "Two words",            words = 2,   digits = nil },
    { name = "Two words + number",   words = 2,   digits = true },
    { name = "Three words",          words = 3,   digits = nil },
    { name = "Three words + number", words = 3,   digits = true },
    { name = "With numbers (any)",   words = nil, digits = true },
}
Sniper.CODE_TYPES = CODE_TYPES

Sniper.collecting  = false
Sniper.tokens      = {}
Sniper.lastTokenAt = 0
Sniper.lastCode    = ""
Sniper.attempted   = {}
Sniper.pending     = nil
Sniper.repeatNext  = 1
Sniper.hint        = nil
Sniper.hintFromChat = false
Sniper.armed       = false
Sniper.armedAt     = 0
Sniper.captured    = 0
Sniper.logFn       = function() end
Sniper.statusFn    = function() end

local function slog(text, color)
    pcall(Sniper.logFn, text, color)
    Log.sniper(text, color)
end

local function sstatus(text, color)
    pcall(Sniper.statusFn, text, color)
end

local function tokenValues()
    local t = {}
    for _, x in ipairs(Sniper.tokens) do t[#t + 1] = x.v end
    return t
end
local function concatCode() return table.concat(tokenValues(), "") end
local function spacedCode() return table.concat(tokenValues(), " ") end
local function finalCode()  return CONFIG.SniperJoinCode and concatCode() or spacedCode() end

function Sniper.hintFromIndex(i)
    local t = CODE_TYPES[i or CONFIG.SniperTypeIndex or 1]
    if not t then return nil end
    if t.words == nil and t.digits == nil then return nil end
    return { words = t.words, digits = t.digits }
end

function Sniper.describeHint(h)
    if not h then return "any (auto)" end
    local parts = {}
    if h.words then table.insert(parts, h.words .. " words") else table.insert(parts, "any length") end
    if h.digits == true then table.insert(parts, "with numbers")
    elseif h.digits == false then table.insert(parts, "no numbers") end
    return table.concat(parts, " + ")
end

local function describeHint(h) return Sniper.describeHint(h) end

-- "the code is two words" / "letters and numbers" / "two words + number"
local function parseTypeHint(text)
    local t = text:lower()
    local hasWord   = t:find("word") ~= nil
    local hasLetter = t:find("letter") ~= nil
    local hasNum    = (t:find("number") ~= nil) or (t:find("digit") ~= nil)
    if not (hasWord or hasLetter or hasNum) then return nil end

    local hint = {}
    local w = t:match("(%a+)%s+words?")
    if w then
        local n = tonumber(NUMBER_WORDS[w]) or tonumber(w)
        if n then hint.words = n end
    end
    if hasNum then
        hint.digits = true
    elseif hasLetter and t:find("only") then
        hint.digits = false
    end
    return hint
end

-- with a known type we can finish instantly (no waiting for silence)
local function shouldComplete()
    local h = Sniper.hint
    if not h or not h.words then return false end
    if #Sniper.tokens < h.words then return false end
    if h.digits then
        for _, tk in ipairs(Sniper.tokens) do
            if tk.kind == "DIGITS" or tk.kind == "NUMBER_WORD" then return true end
        end
        return false
    end
    return true
end

local tryAutoSubmit = function() end

local function validCode(c)
    return type(c) == "string" and #c >= CONFIG.SniperMinLength and #c <= 40 and c:match("^%w+$") ~= nil
end

-- ---------------- code box discovery ----------------
local function getCodeBox()
    if CONFIG.CodeBoxPathOverride ~= "" then
        local node = SaB.PlayerGui
        for part in CONFIG.CodeBoxPathOverride:gmatch("[^%.]+") do
            node = node and node:FindFirstChild(part)
        end
        if node and node:IsA("TextBox") then return node end
    end
    local found
    for _, d in ipairs(SaB.PlayerGui:GetDescendants()) do
        if d:IsA("TextBox") then
            local ph = (d.PlaceholderText or ""):lower()
            if ph:find("code") or Util.lower(d.Name):find("code") then
                found = d
                break
            end
        end
    end
    return found
end

local function tryWriteCode(code)
    local box = getCodeBox()
    if box then
        pcall(function()
            box.Text = code
            box.CursorPosition = #code + 1
        end)
        slog(("WRITTEN to the code box -> %s"):format(code), SaB.Theme.OK)
        Util.notify("Code Sniper", "Code written: " .. code)
        return true
    end
    Sniper.pending = code
    slog("code box is not open yet - saved, it will auto-fill when it appears", SaB.Theme.DIM)
    return false
end

local function finalizeCode()
    if not Sniper.collecting then return end
    Sniper.collecting = false
    local code = finalCode()
    if validCode(code) then
        if not Sniper.attempted[code] then
            Sniper.attempted[code] = true
            Sniper.lastCode = code
            Sniper.captured = Sniper.captured + 1
            sstatus("CODE READY: " .. code, SaB.Theme.OK)
            slog(("FINAL code #%d: %s   (spaced: %s)"):format(Sniper.captured, code, spacedCode()),
                SaB.Theme.OK)
            if tryWriteCode(code) then
                task.wait(0.1)
                tryAutoSubmit()
            end
        else
            slog("duplicate code ignored: " .. code, SaB.Theme.DIM)
        end
    else
        slog("collected words did not form a valid code: '" .. code .. "'", SaB.Theme.BAD)
    end
    Sniper.hintFromChat = false
    sstatus("Listening...", SaB.Theme.DIM)
end
Sniper.finalizeCode = finalizeCode

local function startSession()
    Sniper.collecting  = true
    Sniper.tokens      = {}
    Sniper.repeatNext  = 1
    Sniper.lastTokenAt = tick()
    if not Sniper.hintFromChat then
        Sniper.hint = Sniper.hintFromIndex(CONFIG.SniperTypeIndex)
    end
    sstatus("Collecting... [" .. describeHint(Sniper.hint) .. "]", SaB.Theme.WARN)
    slog("session started - type: " .. describeHint(Sniper.hint), SaB.Theme.WARN)
end
Sniper.startSession = startSession

-- feed one raw word (from chat or from the test panel)
local function feedToken(raw)
    if type(raw) ~= "string" or raw == "" then return end
    local low = raw:lower()

    if low == "double" or low == "dbl" then
        Sniper.repeatNext = 2
        slog('received "double"  ->  the next letter will be doubled', SaB.Theme.ACC)
        return
    elseif low == "triple" then
        Sniper.repeatNext = 3
        slog('received "triple"  ->  the next letter will be tripled', SaB.Theme.ACC)
        return
    end

    local letter = low:match("^double%s+(%a)$")
    if letter then
        table.insert(Sniper.tokens, { v = letter:upper() .. letter:upper(), kind = "DOUBLE" })
        slog(('received "%s"  ->  DOUBLE  ->  "%s"'):format(raw, letter:upper() .. letter:upper()),
            SaB.Theme.ACC)
    else
        local t = raw:upper():gsub("[^%w]", "")
        if t == "" then
            slog(('received "%s"  ->  IGNORED (not code-like)'):format(raw), SaB.Theme.DIM)
            return
        elseif #t == 1 and t:match("%a") then
            local v = t
            if Sniper.repeatNext and Sniper.repeatNext > 1 then
                v = t:rep(Sniper.repeatNext)
                Sniper.repeatNext = 1
            end
            table.insert(Sniper.tokens, { v = v, kind = "LETTER" })
            slog(('received "%s"  ->  LETTER  ->  "%s"'):format(raw, v), SaB.Theme.TEXT)
        elseif t:match("^%d+$") then
            table.insert(Sniper.tokens, { v = t, kind = "DIGITS" })
            slog(('received "%s"  ->  DIGITS'):format(raw), SaB.Theme.TEXT)
        else
            local num = NUMBER_WORDS[low]
            if num then
                table.insert(Sniper.tokens, { v = num, kind = "NUMBER_WORD" })
                slog(('received "%s"  ->  NUMBER_WORD  ->  "%s"'):format(raw, num), SaB.Theme.TEXT)
            elseif t:match("^%w+$") then
                table.insert(Sniper.tokens, { v = t, kind = "WORD" })
                slog(('received "%s"  ->  WORD'):format(raw), SaB.Theme.TEXT)
            else
                slog(('received "%s"  ->  IGNORED'):format(raw), SaB.Theme.DIM)
                return
            end
        end
    end

    Sniper.lastTokenAt = tick()
    local partial = finalCode()
    sstatus("Building: " .. partial, SaB.Theme.WARN)

    if validCode(partial) then
        local box = getCodeBox()
        if box then pcall(function() box.Text = partial end) end
    end

    if shouldComplete() then
        finalizeCode()
    end
end

local NOT_MARKER_NEXT = {
    ["for"] = true, ["not"] = true, ["yet"] = true, ["coming"] = true,
    ["later"] = true, ["time"] = true, ["guys"] = true, ["everyone"] = true,
    ["isn't"] = true, ["wasn't"] = true, ["soon"] = true, ["today"] = true,
}

local function isCodeMarker(text)
    local lower = text:lower()
    local idx = lower:find("code")
    if not idx then return false end
    local rest = lower:sub(idx + 4):gsub("^%s*", "")
    local nextWord = rest:match("^([%a']+)")
    if nextWord == nil then return true end
    if nextWord == "is" then return true end
    if NOT_MARKER_NEXT[nextWord] then return false end
    return true
end

-- force = true bypasses the sender filter (used by the TEST zone)
function Sniper.handleMessage(text, uid, name, force)
    if type(text) ~= "string" or text == "" then return end
    if not (CONFIG.SniperEnabled or force) then return end

    if not (force or CONFIG.SniperListenEveryone) then
        local isTarget = (uid == CONFIG.SniperTargetUserId)
        if not isTarget and CONFIG.SniperMatchNameToo and type(name) == "string" then
            local ln = name:lower()
            if ln:find("spydersammy") or ln == "sammy" then isTarget = true end
        end
        if not isTarget then return end
    end

    -- 1) type announced first: "the code is two words"
    local hint = parseTypeHint(text)
    if hint then
        Sniper.hint         = hint
        Sniper.hintFromChat = true
        Sniper.armed        = true
        Sniper.armedAt      = tick()
        slog("TYPE announced -> " .. describeHint(hint), SaB.Theme.ACC)
        sstatus("Type set: " .. describeHint(hint), SaB.Theme.ACC)
        local afterColon = text:match(":%s*(.+)$")
        if afterColon then
            startSession()
            for w in afterColon:gmatch("%S+") do feedToken(w) end
        end
        return
    end

    -- 2) the code itself
    if isCodeMarker(text) then
        startSession()
        local lower = text:lower()
        local idx = lower:find("code")
        local rest = text:sub(idx + 4):lower()
        rest = rest:gsub("^%s*", "")
        rest = rest:gsub("^is[%s:]*", "")
        rest = rest:gsub("^[%s:]*", "")
        for w in rest:gmatch("%S+") do feedToken(w) end
        return
    end

    -- 3) armed by a type announcement -> the words are arriving
    if not Sniper.collecting and Sniper.armed then
        local words = {}
        for w in text:gmatch("%S+") do table.insert(words, w) end
        if #words >= 1 and #words <= 3 then
            local allCodeLike = true
            for _, w in ipairs(words) do
                if not w:match("^%w+$") or #w > 20 then allCodeLike = false break end
            end
            if allCodeLike then
                Sniper.armed = false
                startSession()
                for _, w in ipairs(words) do feedToken(w) end
                return
            end
        end
    end

    -- 4) plain word while collecting
    if Sniper.collecting then
        for w in text:gmatch("%S+") do feedToken(w) end
    end
end

-- silence watcher
task.spawn(function()
    while SaB.Running do
        task.wait(0.25)
        if Sniper.armed and not Sniper.collecting and (tick() - Sniper.armedAt) > 120 then
            Sniper.armed = false
            Sniper.hintFromChat = false
            slog("type announcement expired - back to listening", SaB.Theme.DIM)
        end
        if Sniper.collecting and (tick() - Sniper.lastTokenAt) > CONFIG.SniperSilenceTimeout then
            finalizeCode()
        end
    end
end)

-- ---------------- chat hooks ----------------
if SaB.Services.TextChatService then
    SaB.Services.TextChatService.MessageReceived:Connect(function(msg)
        pcall(function()
            local ts = msg.TextSource
            Sniper.handleMessage(msg.Text or "", ts and ts.UserId, ts and ts.Name)
        end)
    end)
    pcall(function()
        SaB.Services.TextChatService.SendingMessage:Connect(function(msg)
            local ts = msg.TextSource
            Sniper.handleMessage(msg.Text or "", ts and ts.UserId, ts and ts.Name)
        end)
    end)
end

local function hookLegacy(p)
    pcall(function()
        p.Chatted:Connect(function(text)
            Sniper.handleMessage(text, p.UserId, p.Name)
        end)
    end)
end
for _, p in ipairs(SaB.Services.Players:GetPlayers()) do hookLegacy(p) end
SaB.Services.Players.PlayerAdded:Connect(hookLegacy)

-- auto-fill when the code box finally opens
SaB.PlayerGui.DescendantAdded:Connect(function(d)
    if Sniper.pending and d:IsA("TextBox") then
        local ph = (d.PlaceholderText or ""):lower()
        if ph:find("code") or Util.lower(d.Name):find("code") then
            task.wait(0.15)
            pcall(function() d.Text = Sniper.pending end)
            slog("auto-filled the code box with: " .. Sniper.pending, SaB.Theme.OK)
            Sniper.pending = nil
        end
    end
end)

-- best effort auto submit
tryAutoSubmit = function()
    if not CONFIG.SniperAutoSubmit then return end
    local box = getCodeBox()
    if not box then return end
    local btn = nil
    for _, d in ipairs(box.Parent:GetDescendants()) do
        if d:IsA("GuiButton") and Util.lower(d.Name):find("submit") then btn = d break end
    end
    if not btn then
        for _, d in ipairs(SaB.PlayerGui:GetDescendants()) do
            if d:IsA("GuiButton") and Util.lower(d.Name):find("submit") then btn = d break end
        end
    end
    if not btn then return end
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local p, s = btn.AbsolutePosition, btn.AbsoluteSize
        local x, y = p.X + s.X / 2, p.Y + s.Y / 2
        vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.05)
        vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
        slog("auto-submit pressed", SaB.Theme.OK)
    end)
end


--==============================================================
--  MODULE: 07_UI.lua
--==============================================================
--==============================================================
--  UI FRAMEWORK
--
--  One window: drag it (mouse + touch) , minimise it , close it.
--  Widgets used by every page: sections, labels, buttons, toggles,
--  cycle buttons, text inputs, logs and coloured chips.
--
--  The minimise bug from v1 is fixed: the whole body (tabs + pages)
--  lives inside ONE frame that we simply show / hide.
--==============================================================

local UI = {}
SaB.UI = UI

local Util = SaB.Util
local T    = SaB.Theme

local UserInputService = SaB.Services.UserInputService

-- ---------- sizing ----------
local vw, vh = Camera.ViewportSize.X, Camera.ViewportSize.Y
UI.vw, UI.vh = vw, vh
UI.S    = Util.clamp(math.min(vw, vh) / 720, 0.80, 1.35)
local S = UI.S

UI.W = Util.clamp(vw * 0.94, 316, 560)
UI.H = Util.clamp(vh * 0.84, 420, 700)
UI.HEADER = math.floor(44 * S)
UI.TABS   = math.floor(36 * S)

UI.pages = {}
UI.tabButtons = {}
UI.tabOrder = {}
UI.minimized = false

local function s(n) return n * S end
UI.s = s

-- ---------- root ----------
local function uiParent()
    local ok, res = pcall(function()
        if typeof(gethui) == "function" then return gethui() end
    end)
    if ok and res then return res end
    return SaB.PlayerGui
end

local gui = Instance.new("ScreenGui")
gui.Name = "SaBSuite"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 9999
gui.Parent = uiParent()
UI.gui = gui

--==============================================================
--  WINDOW
--==============================================================
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(UI.W, UI.H)
main.Position = UDim2.new(0.5, -UI.W / 2, 0.5, -UI.H / 2)
main.BackgroundColor3 = T.BG
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = false
main.Parent = gui
UI.main = main

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 14)
    c.Parent = main
    local st = Instance.new("UIStroke")
    st.Color = T.ACC
    st.Thickness = 1.5
    st.Transparency = 0.55
    st.Parent = main
end

-- ---------- header ----------
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, UI.HEADER)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = T.BG2
header.BorderSizePixel = 0
header.Active = true
header.Parent = main
UI.header = header

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 14)
    c.Parent = header
end

-- the bottom corners of the header should only be round when minimised
local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 14)
headerFix.Position = UDim2.new(0, 0, 1, -14)
headerFix.BackgroundColor3 = T.BG2
headerFix.BorderSizePixel = 0
headerFix.Parent = header
UI.headerFix = headerFix

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = s(15)
title.TextColor3 = T.TEXT
title.Text = "  Steal a Brainrot Suite"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Size = UDim2.new(1, -s(110), 1, 0)
title.Parent = header
UI.title = title

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = s(9)
subtitle.TextColor3 = T.DIM
subtitle.Text = "  v" .. SaB.VERSION .. "  |  drag the bar"
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Size = UDim2.new(1, -s(110), 0, s(11))
subtitle.Position = UDim2.new(0, 0, 1, -s(13))
subtitle.Parent = header

local function headerButton(text, x)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = T.BTN2
    b.Font = Enum.Font.GothamBold
    b.TextSize = s(15)
    b.TextColor3 = T.TEXT
    b.Text = text
    b.Size = UDim2.fromOffset(s(34), s(30))
    b.Position = UDim2.new(1, x, 0.5, -s(15))
    b.AutoButtonColor = true
    b.Parent = header
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b
    local st = Instance.new("UIStroke")
    st.Color = T.ACC
    st.Transparency = 0.7
    st.Parent = b
    return b
end

UI.minBtn  = headerButton("–", -s(76))
UI.closeBtn = headerButton("✕", -s(38))

--==============================================================
--  BODY  (everything below the header - this is what we hide)
--==============================================================
local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, 0, 1, -UI.HEADER)
body.Position = UDim2.new(0, 0, 0, UI.HEADER)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ClipsDescendants = true
body.Parent = main
UI.body = body

local tabRow = Instance.new("Frame")
tabRow.Name = "Tabs"
tabRow.Size = UDim2.new(1, 0, 0, UI.TABS)
tabRow.BackgroundTransparency = 1
tabRow.Parent = body
UI.tabRow = tabRow

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -s(12), 1, -(UI.TABS + s(8)))
content.Position = UDim2.new(0, s(6), 0, UI.TABS + s(4))
content.BackgroundTransparency = 1
content.Parent = body
UI.content = content

--==============================================================
--  MINIMISE / CLOSE / DRAG
--==============================================================
function UI.setMinimized(state)
    UI.minimized = state and true or false
    body.Visible = not UI.minimized
    headerFix.Visible = UI.minimized
    main.Size = UI.minimized and UDim2.fromOffset(UI.W, UI.HEADER) or UDim2.fromOffset(UI.W, UI.H)
    UI.minBtn.Text = UI.minimized and "+" or "–"
    UI.minBtn.BackgroundColor3 = UI.minimized and T.ACC or T.BTN2
end

-- click handler that works with mouse AND touch (and never fires twice)
function UI.onClick(btn, cb)
    local last = 0
    local function fire()
        local t = tick()
        if t - last < 0.18 then return end   -- debounce: touch fires 2 events
        last = t
        pcall(cb)
    end
    if btn:IsA("GuiButton") then
        btn.MouseButton1Click:Connect(fire)
        btn.TouchTap:Connect(fire)
    else
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                fire()
            end
        end)
    end
end

UI.onClick(UI.minBtn, function() UI.setMinimized(not UI.minimized) end)

-- floating bubble to bring the window back
local reopen = Instance.new("TextButton")
reopen.Name = "Reopen"
reopen.Size = UDim2.fromOffset(s(50), s(50))
reopen.Position = UDim2.new(0, s(12), 0.45, 0)
reopen.BackgroundColor3 = T.ACC
reopen.Font = Enum.Font.GothamBold
reopen.TextSize = s(20)
reopen.TextColor3 = T.TEXT
reopen.Text = "☰"
reopen.Visible = false
reopen.AutoButtonColor = true
reopen.Parent = gui
UI.reopen = reopen
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = reopen
end

UI.onClick(UI.closeBtn, function()
    gui.Enabled = false
    reopen.Visible = true
end)
UI.onClick(reopen, function()
    gui.Enabled = true
    reopen.Visible = false
end)

function UI.show()
    gui.Enabled = true
    reopen.Visible = false
end

-- ---------- drag ----------
local function makeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                        startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

makeDraggable(header, main)
makeDraggable(reopen, reopen)

function UI.resetPosition()
    main.Position = UDim2.new(0.5, -UI.W / 2, 0.5, -UI.H / 2)
end

--==============================================================
--  TABS
--==============================================================
function UI.addTab(name)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = T.BTN
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = s(12)
    btn.TextColor3 = T.TEXT
    btn.Text = name
    btn.AutoButtonColor = true
    btn.Size = UDim2.new(0.24, -s(6), 1, 0)
    btn.Parent = tabRow
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = T.ACC
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, s(6))
    layout.Parent = page
    local pad = Instance.new("UIPadding")
    pad.PaddingBottom = UDim.new(0, s(6))
    pad.Parent = page

    UI.pages[name] = page
    UI.tabButtons[name] = btn
    table.insert(UI.tabOrder, name)

    UI.onClick(btn, function() UI.selectTab(name) end)
    return page
end

function UI.selectTab(name)
    for n, page in pairs(UI.pages) do
        page.Visible = (n == name)
    end
    for n, btn in pairs(UI.tabButtons) do
        btn.BackgroundColor3 = (n == name) and T.ACC or T.BTN
    end
    UI.currentTab = name
end

function UI.layoutTabs()
    local n = math.max(1, #UI.tabOrder)
    for i, name in ipairs(UI.tabOrder) do
        local btn = UI.tabButtons[name]
        if btn then
            btn.Size = UDim2.new(1 / n, -s(5), 1, 0)
        end
    end
end

--==============================================================
--  WIDGETS
--==============================================================
local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or s(8))
    c.Parent = inst
    return c
end
UI.corner = corner

-- titled box so every page is organised the same way
function UI.section(parent, labelText, accent)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = T.BG2
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Parent = parent
    corner(frame, s(10))

    local stroke = Instance.new("UIStroke")
    stroke.Color = accent or T.ACC
    stroke.Transparency = 0.75
    stroke.Thickness = 1
    stroke.Parent = frame

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, s(7))
    pad.PaddingBottom = UDim.new(0, s(8))
    pad.PaddingLeft = UDim.new(0, s(8))
    pad.PaddingRight = UDim.new(0, s(8))
    pad.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, s(5))
    layout.Parent = frame

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = s(11)
    title.TextColor3 = accent or T.ACC
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Size = UDim2.new(1, 0, 0, s(14))
    title.Text = tostring(labelText or ""):upper()
    title.Parent = frame

    return frame, layout
end

function UI.label(parent, text, color, opts)
    opts = opts or {}
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = opts.bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize = s(opts.size or 12)
    l.TextColor3 = color or T.TEXT
    l.TextWrapped = true
    l.TextXAlignment = opts.align or Enum.TextXAlignment.Left
    l.Size = UDim2.new(1, 0, 0, 0)
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.Text = tostring(text or "")
    l.Parent = parent
    return l
end

function UI.spacer(parent, h)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(1, 0, 0, s(h or 6))
    f.Parent = parent
    return f
end

-- a row that lays its children out horizontally
function UI.row(parent, height, padding)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(1, 0, 0, s(height or 32))
    f.Parent = parent
    local l = Instance.new("UIListLayout")
    l.FillDirection = Enum.FillDirection.Horizontal
    l.Padding = UDim.new(0, s(padding or 5))
    l.VerticalAlignment = Enum.VerticalAlignment.Center
    l.Parent = f
    return f
end

function UI.button(parent, text, cb, opts)
    opts = opts or {}
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = opts.color or T.BTN
    b.Font = Enum.Font.GothamMedium
    b.TextSize = s(opts.size or 12)
    b.TextColor3 = opts.textColor or T.TEXT
    b.Text = tostring(text or "")
    b.TextWrapped = true
    b.AutoButtonColor = true
    b.Size = opts.width and UDim2.new(opts.width, -s(4), 0, s(opts.h or 32)) or UDim2.new(1, 0, 0, s(opts.h or 32))
    b.Parent = parent
    corner(b, s(8))
    if cb then UI.onClick(b, cb) end
    return b
end

function UI.toggle(parent, labelText, default, cb)
    local on = default and true or false
    local b = Instance.new("TextButton")
    b.Font = Enum.Font.GothamMedium
    b.TextSize = s(12)
    b.TextColor3 = T.TEXT
    b.AutoButtonColor = true
    b.Size = UDim2.new(1, 0, 0, s(32))
    b.Parent = parent
    corner(b, s(8))

    local function render()
        b.Text = ("%s     %s"):format(tostring(labelText), on and "ON" or "OFF")
        b.BackgroundColor3 = on and T.ON or T.OFF
    end
    UI.onClick(b, function()
        on = not on
        render()
        pcall(cb, on)
    end)
    render()
    -- NOTE: functions are returned separately - you cannot store them on an
    -- Instance (Roblox throws "X is not a valid member of TextButton")
    local function get() return on end
    local function set(v)
        on = v and true or false
        render()
    end
    return b, get, set
end

-- button that cycles through a list of options
function UI.cycle(parent, labelText, values, index, cb)
    local i = index or 1
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = T.BTN
    b.Font = Enum.Font.GothamMedium
    b.TextSize = s(12)
    b.TextColor3 = T.TEXT
    b.AutoButtonColor = true
    b.Size = UDim2.new(1, 0, 0, s(32))
    b.Parent = parent
    corner(b, s(8))

    local function render()
        b.Text = ("%s:   %s"):format(tostring(labelText), tostring(values[i]))
    end
    UI.onClick(b, function()
        i = i + 1
        if i > #values then i = 1 end
        render()
        pcall(cb, i, values[i])
    end)
    render()
    local function getIndex() return i end
    local function setIndex(n)
        i = Util.clamp(n or 1, 1, #values)
        render()
        pcall(cb, i, values[i])
    end
    return b, getIndex, setIndex
end

function UI.input(parent, placeholder, default, cb)
    local t = Instance.new("TextBox")
    t.PlaceholderText = tostring(placeholder or "")
    t.Text = tostring(default or "")
    t.Font = Enum.Font.Gotham
    t.TextSize = s(12)
    t.TextColor3 = T.TEXT
    t.PlaceholderColor3 = T.DIM
    t.BackgroundColor3 = T.BG3
    t.BorderSizePixel = 0
    t.ClearTextOnFocus = false
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Size = UDim2.new(1, 0, 0, s(30))
    t.Parent = parent
    corner(t, s(8))
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, s(8))
    pad.Parent = t
    if cb then
        t.FocusLost:Connect(function(enter)
            pcall(cb, t.Text, enter)
        end)
    end
    return t
end

-- small coloured pill (used for the rarity chip in the list)
function UI.chip(parent, text, color, width)
    local l = Instance.new("TextLabel")
    l.BackgroundColor3 = color or T.ACC
    l.BackgroundTransparency = 0.12
    l.Font = Enum.Font.GothamBold
    l.TextSize = s(9)
    l.TextColor3 = Color3.fromRGB(12, 12, 16)
    l.TextXAlignment = Enum.TextXAlignment.Center
    l.Size = width and UDim2.new(0, s(width), 0, s(15)) or UDim2.new(0, s(46), 0, s(15))
    l.Text = " " .. tostring(text or "") .. " "
    l.Parent = parent
    corner(l, s(5))
    return l
end

-- scrolling log
function UI.log(parent, height)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 0, s(height or 140))
    sf.BackgroundColor3 = T.BG3
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 4
    sf.ScrollBarImageColor3 = T.ACC
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Parent = parent
    corner(sf, s(8))

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = sf

    local count = 0
    local function add(text, color)
        local lb = Instance.new("TextLabel")
        lb.BackgroundTransparency = 1
        lb.Font = Enum.Font.Code
        lb.TextSize = s(10)
        lb.TextWrapped = true
        lb.TextColor3 = color or T.TEXT
        lb.TextXAlignment = Enum.TextXAlignment.Left
        lb.Size = UDim2.new(1, -s(10), 0, 0)
        lb.AutomaticSize = Enum.AutomaticSize.Y
        lb.Text = tostring(text)
        lb.Parent = sf
        count = count + 1
        if count > 160 then
            for _, c in ipairs(sf:GetChildren()) do
                if c:IsA("TextLabel") then
                    c:Destroy()
                    count = count - 1
                    break
                end
            end
        end
        task.defer(function()
            pcall(function()
                sf.CanvasPosition = Vector2.new(0, math.max(0, sf.AbsoluteCanvasSize.Y))
            end)
        end)
        return lb
    end

    local function clear()
        for _, c in ipairs(sf:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        count = 0
    end

    return { frame = sf, add = add, clear = clear }
end

--==============================================================
--  TOAST (bottom of the screen status bar)
--==============================================================
local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.Size = UDim2.new(0, math.min(vw - 20, 420), 0, s(26))
toast.Position = UDim2.new(0.5, -math.min(vw - 20, 420) / 2, 1, -s(90))
toast.BackgroundColor3 = T.BG2
toast.BackgroundTransparency = 0.15
toast.Font = Enum.Font.GothamBold
toast.TextSize = s(12)
toast.TextColor3 = T.ACC
toast.Text = ""
toast.Visible = false
toast.Parent = gui
corner(toast, s(8))
UI.toast = toast

local toastUntil = 0
function UI.toastShow(text, color, seconds)
    toast.Text = tostring(text)
    toast.TextColor3 = color or T.ACC
    toast.Visible = true
    toastUntil = tick() + (seconds or 3)
end

task.spawn(function()
    while SaB.Running do
        task.wait(0.4)
        if toast.Visible and tick() > toastUntil then
            toast.Visible = false
        end
    end
end)


--==============================================================
--  MODULE: 08_Pages.lua
--==============================================================
--==============================================================
--  PAGES  (Eggs · Code Sniper · Diagnostics · Settings)
--
--  The Eggs tab is built to answer three questions instantly:
--     1. how many eggs did we find, and HOW did we find them?
--     2. which ones pass my filters right now?
--     3. what is the farm doing at this second?
--==============================================================

local W = {}          -- every widget of this page lives here (saves locals)
W.Util = SaB.Util
W.CONFIG = SaB.CONFIG
W.Rarity = SaB.Rarity

W.Farm = SaB.Farm

W.UI = SaB.UI

W.s = W.UI.s

W.Pages = {}
SaB.Pages = W.Pages

--==============================================================
--  PAGE 1 : EGGS
--==============================================================
W.eggPage = W.UI.addTab("Eggs")

-- (moved into the widget table)
-- ---------------- STATUS ----------------
W.statusSection = W.UI.section(W.eggPage, "Status", SaB.Theme.ACC)  -- keep for the children
W.statusLabel = W.UI.label(W.statusSection, "detected 0   •   matching 0   •   delivered 0",
    SaB.Theme.TEXT, { bold = true })
W.statusLine = W.UI.label(W.statusSection, "farm: idle", SaB.Theme.DIM)
W.detectLine = W.UI.label(W.statusSection, "scan: -", SaB.Theme.DIM, { size = 10 })

-- ---------------- DETECTION ----------------
W.detSection = W.UI.section(W.eggPage, "Detection", Color3.fromRGB(90, 200, 255))
W.UI.toggle(W.detSection, "EGG ESP (labels)", W.CONFIG.EggESPEnabled, function(v)
    W.CONFIG.EggESPEnabled = v
    if not v then SaB.ESP.clear() end
end)
W.UI.toggle(W.detSection, "Glow box around eggs", W.CONFIG.EggHighlight, function(v)
    W.CONFIG.EggHighlight = v
end)
W.UI.toggle(W.detSection, "See eggs through walls", W.CONFIG.EggAlwaysOnTop, function(v)
    W.CONFIG.EggAlwaysOnTop = v
    SaB.ESP.rebuild()
end)
W.UI.toggle(W.detSection, "Watch for new eggs (live scan)", W.CONFIG.EggLiveScan, function(v)
    W.CONFIG.EggLiveScan = v
end)
do
    local row = W.UI.row(W.detSection, 30)
    W.UI.button(row, "DEEP SCAN NOW", function()
        W.UI.toastShow("scanning the whole map...", SaB.Theme.ACC, 2)
        local added = SaB.Scanner.deepScan(false)
        W.UI.toastShow(("scan done - %d eggs tracked"):format(W.Util.tableCount(SaB.Scanner.eggs)), SaB.Theme.OK, 2)
        W.eggLog(("deep scan: +%d new (see console)"):format(added), SaB.Theme.ACC)
    end, { width = 0.5, color = SaB.Theme.ACC })
    W.UI.button(row, "REBUILD LABELS", function()
        SaB.ESP.rebuild()
        W.UI.toastShow("labels rebuilt", SaB.Theme.OK, 2)
    end, { width = 0.5 })
end
W.UI.cycle(W.detSection, "Detection sensitivity  (loose = finds more)",
    { "normal", "loose (finds more)", "strict (fewer mistakes)" }, 1, function(i)
        W.CONFIG.EggMinConfidence = ({ 60, 35, 75 })[i]
        SaB.Scanner.clear()
        SaB.Scanner.deepScan(false)
        W.UI.toastShow(("sensitivity: %s"):format(({ "normal", "loose", "strict" })[i]), SaB.Theme.OK, 2)
    end)
W.sourceLine = W.UI.label(W.detSection, "detectors: -", SaB.Theme.DIM, { size = 10 })
W.extraInput = W.UI.input(W.detSection, "extra keywords (comma separated)", W.CONFIG.EggExtraKeywords, function(text)
    W.CONFIG.EggExtraKeywords = text
    W.UI.toastShow("keywords saved - press DEEP SCAN", SaB.Theme.OK, 2)
end)

-- ---------------- FILTERS ----------------
W.filterSection = W.UI.section(W.eggPage, "Filters", Color3.fromRGB(255, 190, 60))

W.rarityValues = { "ANY" }
for _, r in ipairs(W.Rarity.ORDER) do
    if r ~= "Unknown" then table.insert(W.rarityValues, r) end
end
W.rarityBtn = W.UI.cycle(W.filterSection, "Min rarity", W.rarityValues,
    W.CONFIG.EggMinRarityIndex + 1, function(i)
        W.CONFIG.EggMinRarityIndex = i - 1
        if i > 1 then
            W.rarityBtn.BackgroundColor3 = W.Rarity.color(W.rarityValues[i])
        else
            W.rarityBtn.BackgroundColor3 = SaB.Theme.BTN
        end
    end)

W.islandValues = { "Any" }
for _, isl in ipairs(SaB.EggDB.ISLANDS) do table.insert(W.islandValues, isl.key) end
W.UI.cycle(W.filterSection, "Island", W.islandValues, 1, function(i)
    W.CONFIG.EggIslandFilter = W.islandValues[i]
end)

W.searchInput = W.UI.input(W.filterSection, "search: dragon, secret, heavenly ...",
    table.concat(W.CONFIG.EggWhitelist, ", "), function(text)
        W.CONFIG.EggWhitelist = W.Util.split(text)
        W.UI.toastShow(("saved %d search word(s)"):format(#W.CONFIG.EggWhitelist), SaB.Theme.OK, 2)
    end)
W.UI.toggle(W.filterSection, "Use the search box", W.CONFIG.EggWhitelistOn, function(v)
    W.CONFIG.EggWhitelistOn = v
end)

W.distInput = W.UI.input(W.filterSection, "max distance in studs (0 = any)",
    tostring(W.CONFIG.EggMaxDistance), function(text)
        W.CONFIG.EggMaxDistance = tonumber(text) or 0
        W.UI.toastShow("max distance = " .. tostring(W.CONFIG.EggMaxDistance), SaB.Theme.OK, 2)
    end)

W.UI.toggle(W.filterSection, "Hide eggs with unknown rarity", W.CONFIG.EggHideUnknown, function(v)
    W.CONFIG.EggHideUnknown = v
end)
W.UI.toggle(W.filterSection, "Only eggs from the known list", W.CONFIG.EggOnlyKnown, function(v)
    W.CONFIG.EggOnlyKnown = v
end)
W.UI.toggle(W.filterSection, "Skip eggs that failed recently", W.CONFIG.EggSkipFailed, function(v)
    W.CONFIG.EggSkipFailed = v
end)

W.filterLine = W.UI.label(W.filterSection, "filters: 0 of 0 eggs pass", SaB.Theme.WARN, { size = 11 })
W.UI.button(W.filterSection, "RESET ALL FILTERS", function()
    W.CONFIG.EggMinRarityIndex = 0
    W.CONFIG.EggIslandFilter = "Any"
    W.CONFIG.EggWhitelistOn = false
    W.CONFIG.EggWhitelist = {}
    W.CONFIG.EggMaxDistance = 0
    W.CONFIG.EggHideUnknown = false
    W.CONFIG.EggOnlyKnown = false
    W.rarityBtn.BackgroundColor3 = SaB.Theme.BTN
    W.searchInput.Text = ""
    W.distInput.Text = "0"
    W.UI.toastShow("filters reset", SaB.Theme.OK, 2)
end, { color = SaB.Theme.BTN2 })

-- ---------------- ALERTS ----------------
W.alertSection = W.UI.section(W.eggPage, "Rare egg alerts", Color3.fromRGB(255, 215, 0))
W.UI.toggle(W.alertSection, "Shout when a rare egg appears", W.CONFIG.EggAlertEnabled,
    function(v) W.CONFIG.EggAlertEnabled = v end)

W.alertValues = {}
for _, name in ipairs(W.Rarity.ORDER) do
    if name ~= "Unknown" then table.insert(W.alertValues, name) end
end
W.alertBtn = W.UI.cycle(W.alertSection, "Alert me from", W.alertValues,
    W.CONFIG.EggAlertMinRarityIndex, function(i)
        W.CONFIG.EggAlertMinRarityIndex = i
        W.alertBtn.BackgroundColor3 = W.Rarity.color(W.alertValues[i])
    end)
W.alertBtn.BackgroundColor3 = W.Rarity.color(W.alertValues[W.CONFIG.EggAlertMinRarityIndex] or "Secret")
W.alertLine = W.UI.label(W.alertSection, "no rare eggs yet", SaB.Theme.DIM, { size = 10 })

-- ---------------- TARGETS ----------------
W.targetSection = W.UI.section(W.eggPage, "Eggs found (tap to teleport)", Color3.fromRGB(120, 220, 140))
W.targetHint = W.UI.label(W.targetSection,
    "waiting for the first scan...", SaB.Theme.DIM, { size = 11 })

W.MAX_ROWS = 16
W.rows = {}
W.headers = {}

-- small coloured header: "SECRET  x3"  (the list is grouped by category)
local function makeHeader(index)
    local h = Instance.new("TextLabel")
    h.Name = "Head" .. index
    h.BackgroundTransparency = 1
    h.Font = Enum.Font.GothamBold
    h.TextSize = s(10)
    h.TextColor3 = SaB.Theme.DIM
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.Size = UDim2.new(1, 0, 0, s(14))
    h.Visible = false
    h.Parent = W.targetSection
    return h
end

local function makeRow(index)
    local row = Instance.new("TextButton")
    row.Name = "Row" .. index
    row.BackgroundColor3 = SaB.Theme.BG3
    row.BackgroundTransparency = 0.25
    row.BorderSizePixel = 0
    row.Size = UDim2.new(1, 0, 0, s(30))
    row.AutoButtonColor = true
    row.Text = ""
    row.Visible = false
    row.Parent = W.targetSection
    W.UI.corner(row, s(7))

    local chip = W.UI.chip(row, "???", SaB.Theme.DIM, 42)
    chip.Position = UDim2.new(0, s(5), 0.5, -s(8))

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = s(11)
    nameLabel.TextColor3 = SaB.Theme.TEXT
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Position = UDim2.new(0, s(52), 0, s(2))
    nameLabel.Size = UDim2.new(1, -s(140), 0, s(14))
    nameLabel.Text = ""
    nameLabel.Parent = row

    local subLabel = Instance.new("TextLabel")
    subLabel.BackgroundTransparency = 1
    subLabel.Font = Enum.Font.Gotham
    subLabel.TextSize = s(9)
    subLabel.TextColor3 = SaB.Theme.DIM
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.TextTruncate = Enum.TextTruncate.AtEnd
    subLabel.Position = UDim2.new(0, s(52), 0, s(16))
    subLabel.Size = UDim2.new(1, -s(140), 0, s(11))
    subLabel.Text = ""
    subLabel.Parent = row

    local distLabel = Instance.new("TextLabel")
    distLabel.BackgroundTransparency = 1
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = s(10)
    distLabel.TextColor3 = SaB.Theme.DIM
    distLabel.TextXAlignment = Enum.TextXAlignment.Right
    distLabel.Position = UDim2.new(1, -s(92), 0, s(9))
    distLabel.Size = UDim2.new(0, s(52), 0, s(12))
    distLabel.Text = ""
    distLabel.Parent = row

    local farmBtn = Instance.new("TextButton")
    farmBtn.BackgroundColor3 = SaB.Theme.ACC
    farmBtn.Font = Enum.Font.GothamBold
    farmBtn.TextSize = s(10)
    farmBtn.TextColor3 = SaB.Theme.TEXT
    farmBtn.Text = "FARM"
    farmBtn.Size = UDim2.new(0, s(34), 0, s(20))
    farmBtn.Position = UDim2.new(1, -s(38), 0.5, -s(10))
    farmBtn.Parent = row
    W.UI.corner(farmBtn, s(6))

    local rec = nil
    W.UI.onClick(row, function()
        if rec and rec.obj and rec.obj.Parent then
            W.UI.toastShow("teleporting to " .. rec.name, W.Rarity.color(rec.rarity), 2)
            task.spawn(function()
                W.Farm.Teleport.to(rec.pos, rec.obj)
            end)
        end
    end)
    W.UI.onClick(farmBtn, function()
        if rec and rec.obj and rec.obj.Parent then
            W.Farm.runOnce(rec)
        end
    end)

    local data = {
        row = row, chip = chip, name = nameLabel, sub = subLabel,
        dist = distLabel, farm = farmBtn,
        set = function(_, r)
            rec = r
            if not r then row.Visible = false return end
            row.Visible = true
            local color = W.Rarity.color(r.rarity)
            chip.BackgroundColor3 = color
            chip.Text = " " .. (W.Rarity.SHORT[r.rarity] or "???") .. " "
            nameLabel.Text = r.name or "?"
            nameLabel.TextColor3 = color
            local bits = {}
            if r.island then table.insert(bits, r.island) end
            if r.incomeText then table.insert(bits, r.incomeText) end
            if r.timerLeft and r.timerLeft > 0 then
                table.insert(bits, W.Util.formatClock(r.timerLeft))
            end
            table.insert(bits, "(" .. (SaB.Scanner.SOURCE_LABEL[r.source] or r.source) .. ")")
            subLabel.Text = table.concat(bits, "  •  ")
            distLabel.Text = W.Util.formatDistance(r.dist)
        end,
    }
    return data
end

-- ---------------- AUTO FARM ----------------
W.farmSection = W.UI.section(W.eggPage, "Auto farm", Color3.fromRGB(255, 120, 160))
W.farmToggle, W.farmGet, W.farmSet = W.UI.toggle(W.farmSection, "AUTO FARM EGGS", W.CONFIG.EggAutoFarm, function(v)
    W.CONFIG.EggAutoFarm = v
    if not v then
        W.Farm.Teleport.cancel()
    else
        W.UI.toastShow("auto farm started", SaB.Theme.OK, 2)
        if not W.Farm.Base.get() then
            W.UI.toastShow("base not found - press SET BASE HERE", SaB.Theme.BAD, 4)
        end
    end
end)
W.UI.cycle(W.farmSection, "Pick order",
    { "best rarity first", "nearest first", "best income first" }, 1, function(i)
        W.CONFIG.EggFarmPriority = ({ "rarity", "nearest", "income" })[i]
    end)
W.UI.toggle(W.farmSection, "Safe fly teleport (anti snap-back)", W.CONFIG.EggSafeTeleport, function(v)
    W.CONFIG.EggSafeTeleport = v
end)
W.UI.toggle(W.farmSection, "Freeze in place while grabbing", W.CONFIG.EggAnchorWhileWaiting,
    function(v)
        W.CONFIG.EggAnchorWhileWaiting = v
        if not v then W.Farm.setAnchor(false) end
    end)
W.UI.toggle(W.farmSection, "Experimental: fire 'collect' remotes", W.CONFIG.EggExperimentalRemotes,
    function(v) W.CONFIG.EggExperimentalRemotes = v end)

do
    local row = W.UI.row(W.farmSection, 30)
    W.UI.button(row, "FARM BEST", function() W.Farm.runOnce(nil) end, { width = 0.34, color = SaB.Theme.ON })
    W.UI.button(row, "FARM NEAREST", function()
        local list = SaB.Scanner.matching()
        table.sort(list, function(a, b) return a.dist < b.dist end)
        W.Farm.runOnce(list[1])
    end, { width = 0.34 })
    W.UI.button(row, "STOP", function()
        W.CONFIG.EggAutoFarm = false
        W.farmSet(false)
        W.Farm.Teleport.cancel()
        W.UI.toastShow("stopped", SaB.Theme.WARN, 2)
    end, { width = 0.32, color = SaB.Theme.OFF })
end

do
    local row = W.UI.row(W.farmSection, 30)
    W.UI.button(row, "SET BASE HERE", function()
        local hrp = W.Util.getHRP()
        if hrp then
            W.Farm.Base.set(hrp.Position, "set by you")
            W.UI.toastShow("base saved", SaB.Theme.OK, 2)
            W.eggLog("base set to your current position", SaB.Theme.OK)
        end
    end, { width = 0.5, color = SaB.Theme.ACC })
    W.UI.button(row, "TELEPORT TO BASE", function()
        local base = W.Farm.Base.get()
        if base then
            W.Farm.Teleport.to(base.pos)
            W.UI.toastShow("teleported to base (" .. base.source .. ")", SaB.Theme.OK, 2)
        else
            W.UI.toastShow("base not found", SaB.Theme.BAD, 3)
        end
    end, { width = 0.5 })
end

W.baseLine = W.UI.label(W.farmSection, "base: -", SaB.Theme.DIM, { size = 10 })
W.farmStatsLine = W.UI.label(W.farmSection, "delivered 0   failed 0", SaB.Theme.DIM, { size = 10 })

do
    local row = W.UI.row(W.farmSection, 30)
    local pInput = W.UI.input(row, "pick delay", tostring(W.CONFIG.EggPickupDelay))
    pInput.Size = UDim2.new(0.5, -s(4), 0, s(30))
    pInput.FocusLost:Connect(function()
        local n = tonumber(pInput.Text)
        if n then W.CONFIG.EggPickupDelay = W.Util.clamp(n, 0.1, 6) end
    end)
    local rInput = W.UI.input(row, "return delay", tostring(W.CONFIG.EggReturnDelay))
    rInput.Size = UDim2.new(0.5, -s(4), 0, s(30))
    rInput.FocusLost:Connect(function()
        local n = tonumber(rInput.Text)
        if n then W.CONFIG.EggReturnDelay = W.Util.clamp(n, 0.5, 15) end
    end)
end

-- ---------------- TELEPORT ----------------
W.tpSection = W.UI.section(W.eggPage, "Teleport (anti snap-back)",
    Color3.fromRGB(180, 140, 255))
W.tpLine = W.UI.label(W.tpSection,
    "tp: idle  •  if you pop back to spawn the server rejected a jump - use SMOOTH",
    SaB.Theme.DIM, { size = 10 })
W.UI.cycle(W.tpSection, "Mode",
    { "smooth (anti-cheat)", "fast", "instant (old, snaps back)" }, 1, function(i)
        W.CONFIG.EggTpMode = ({ "smooth", "fast", "instant" })[i]
        W.UI.toastShow("teleport: " .. W.CONFIG.EggTpMode, SaB.Theme.ACC, 2)
    end)
W.UI.cycle(W.tpSection, "Fly speed",
    { "slow 50", "normal 80", "quick 120", "turbo 180" }, 2, function(i)
        W.CONFIG.EggTpSpeed = ({ 50, 80, 120, 180 })[i]
        W.UI.toastShow("fly speed: " .. tostring(W.CONFIG.EggTpSpeed) .. " studs/s", SaB.Theme.ACC, 2)
    end)
W.UI.toggle(W.tpSection, "Noclip while flying", W.CONFIG.EggTpNoclip, function(v)
    W.CONFIG.EggTpNoclip = v
end)
W.UI.toggle(W.tpSection, "Fight snap-back (anti rubberband)", W.CONFIG.EggTpAntiRubber, function(v)
    W.CONFIG.EggTpAntiRubber = v
end)
W.UI.toggle(W.tpSection, "Hold still on arrival (server must see you)",
    (tonumber(W.CONFIG.EggTpHoldArrive) or 0) > 0, function(v)
        W.CONFIG.EggTpHoldArrive = v and 0.45 or 0
    end)
W.UI.toggle(W.tpSection, "Sky arc (climb, then cross, then land)",
    (tonumber(W.CONFIG.EggTpArcHeight) or 0) > 0, function(v)
        W.CONFIG.EggTpArcHeight = v and 28 or 0
    end)

-- ---------------- ISLANDS ----------------
W.islandSection = W.UI.section(W.eggPage, "Islands (tap to fly there)",
    Color3.fromRGB(120, 220, 255))
W.islandLine = W.UI.label(W.islandSection, "no islands found yet", SaB.Theme.DIM, { size = 10 })
W.islandBtns = {}

local function makeIslandBtn(index)
    local b = W.UI.button(W.islandSection, "-", function()
        local isl = W.islandBtns[index].island
        if isl and isl.obj and isl.obj.Parent then
            W.Farm.Teleport.to(isl.pos)
            W.UI.toastShow("flying to " .. isl.key, SaB.Extras.islandColor(isl.key), 2)
        end
    end, { color = SaB.Theme.BTN })
    b.Visible = false
    W.islandBtns[index] = { button = b }
    return W.islandBtns[index]
end

-- ---------------- COLLECTED ----------------
W.collSection = W.UI.section(W.eggPage, "Collected eggs", Color3.fromRGB(150, 230, 160))
W.collLogBox = W.UI.log(W.collSection, 110)
W.collLog, W.collLogClear = W.collLogBox.add, W.collLogBox.clear
W.Farm.onDelivery = function(rec)
    pcall(function()
        W.collLog(("%s   %s   [%s]"):format(os.date("%H:%M:%S"), rec.name, rec.rarity),
            W.Rarity.color(rec.rarity))
    end)
end
W.UI.button(W.collSection, "Clear the collected list", function() W.collLogClear() end,
    { color = SaB.Theme.BTN2 })

-- ---------------- AFK / XP ----------------
W.afkSection = W.UI.section(W.eggPage, "AFK / XP (trampoline)",
    Color3.fromRGB(200, 160, 255))
W.UI.toggle(W.afkSection, "AFK auto jump (trampoline XP)", W.CONFIG.AfkJump, function(v)
    W.CONFIG.AfkJump = v
    if v then
        W.UI.toastShow("auto jump ON", SaB.Theme.OK, 2)
    end
end)
W.afkInput = W.UI.input(W.afkSection, "seconds between jumps",
    tostring(W.CONFIG.AfkJumpInterval), function(text)
        local n = tonumber(text)
        if n then W.CONFIG.AfkJumpInterval = W.Util.clamp(n, 0.15, 5) end
    end)
do
    local row = W.UI.row(W.afkSection, 30)
    W.UI.button(row, "FIND TRAMPOLINE", function()
        local pos, name = SaB.Extras.findTrampoline()
        if pos then
            W.UI.toastShow("found: " .. tostring(name), SaB.Theme.OK, 3)
            W.collLog("", SaB.Theme.DIM)
        else
            W.UI.toastShow("nothing named trampoline/treadmill", SaB.Theme.WARN, 3)
        end
    end, { width = 0.5, color = SaB.Theme.ACC })
    W.UI.button(row, "GO TRAIN (AFK)", function() SaB.Extras.goTrain() end,
        { width = 0.5, color = SaB.Theme.ON })
end
W.afkLine = W.UI.label(W.afkSection, "afk: off", SaB.Theme.DIM, { size = 10 })

-- ---------------- ACTIVITY LOG ----------------
W.actSection = W.UI.section(W.eggPage, "Activity", SaB.Theme.DIM)
W.eggLog = W.UI.log(W.actSection, 150)
W.eggLogAdd, W.eggLogClear = W.eggLog.add, W.eggLog.clear
W.eggLog = W.eggLogAdd

--==============================================================
--  REFRESH (runs once a second while the Eggs tab is open)
--==============================================================
W.lastCounts = { total = -1, matching = -1 }

function W.Pages.refreshEggs()
    local list = SaB.Scanner.list or {}
    local total, matching, unknown = SaB.Scanner.counts()

    W.statusLabel.Text = ("detected %d   •   matching %d   •   delivered %d"):format(
        total, matching, W.Farm.stats.delivered)
    W.filterLine.Text = ("filters: %d of %d eggs pass%s"):format(
        matching, total, (unknown > 0 and ("   (%d unknown rarity)"):format(unknown) or ""))
    W.filterLine.TextColor3 = (matching > 0) and SaB.Theme.OK or SaB.Theme.WARN

    local st = SaB.Scanner.stats
    W.detectLine.Text = ("scan: %d objects in %.2fs  •  %d watched folders  •  live: %s"):format(
        st.scanned or 0, st.lastDuration or 0, W.Util.tableCount(SaB.Scanner.roots),
        W.CONFIG.EggLiveScan and "ON" or "OFF")

    -- how did we find them?
    local bySource = {}
    for _, rec in ipairs(list) do
        bySource[rec.source] = (bySource[rec.source] or 0) + 1
    end
    local bits = {}
    for _, k in ipairs(W.Util.keys(bySource)) do
        table.insert(bits, ("%s x%d"):format(SaB.Scanner.SOURCE_LABEL[k] or k, bySource[k]))
    end
    W.sourceLine.Text = #bits > 0 and ("found by: " .. table.concat(bits, "  |  "))
        or "found by: nothing yet"

    -- target W.rows, grouped by category (one coloured header per rarity)
    local targets = SaB.Scanner.matching(W.MAX_ROWS)
    local groups, groupOrder = {}, {}
    for _, rec in ipairs(targets) do
        if not groups[rec.rarity] then
            groups[rec.rarity] = {}
            table.insert(groupOrder, rec.rarity)
        end
        table.insert(groups[rec.rarity], rec)
    end
    table.sort(groupOrder, function(a, b) return W.Rarity.tier(a) > W.Rarity.tier(b) end)

    local slot, hIndex = 0, 0
    for _, rarityName in ipairs(groupOrder) do
        hIndex = hIndex + 1
        W.headers[hIndex] = W.headers[hIndex] or makeHeader(hIndex)
        local head = W.headers[hIndex]
        head.Visible = true
        head.LayoutOrder = slot + 1
        head.TextColor3 = W.Rarity.color(rarityName)
        head.Text = ("▸ %s   (%d)"):format(rarityName:upper(), #groups[rarityName])
        slot = slot + 1
        for _, rec in ipairs(groups[rarityName]) do
            slot = slot + 1
            if slot - hIndex > W.MAX_ROWS then break end
            W.rows[slot - hIndex] = W.rows[slot - hIndex] or makeRow(slot - hIndex)
            local rowData = W.rows[slot - hIndex]
            rowData.row.LayoutOrder = slot
            rowData:set(rec)
        end
    end
    for i = slot - hIndex + 1, W.MAX_ROWS do
        if W.rows[i] then W.rows[i]:set(nil) end
    end
    for i = hIndex + 1, #W.headers do
        if W.headers[i] then W.headers[i].Visible = false end
    end

    if #targets == 0 then
        W.targetHint.Visible = true
        if total == 0 then
            W.targetHint.Text = "NO EGGS DETECTED YET.\n" ..
                "1) make sure you are inside the LTM (go through the portal)\n" ..
                "2) press DEEP SCAN NOW (it scans the whole map)\n" ..
                "3) still nothing? open the DIAGNOSTICS tab and send me the report"
            W.targetHint.TextColor3 = SaB.Theme.BAD
        else
            W.targetHint.Text = ("%d eggs detected but none pass your filters - " ..
                "press RESET ALL FILTERS or relax them."):format(total)
            W.targetHint.TextColor3 = SaB.Theme.WARN
        end
    else
        W.targetHint.Visible = false
    end

    -- alerts
    local alertCount = #SaB.Extras.alerts
    if alertCount > 0 then
        local last = SaB.Extras.alerts[alertCount]
        W.alertLine.Text = ("%d rare egg(s) seen  •  last: %s [%s]"):format(
            alertCount, last.name, last.rarity)
        W.alertLine.TextColor3 = W.Rarity.color(last.rarity)
    else
        W.alertLine.Text = ("no %s eggs seen yet"):format(tostring(SaB.Extras.alertRarity()))
        W.alertLine.TextColor3 = SaB.Theme.DIM
    end

    -- islands
    local islands = SaB.Extras.findIslands()
    if #islands == 0 then
        W.islandLine.Visible = true
        W.islandLine.Text = "no islands found (are you inside the LTM?)"
    else
        W.islandLine.Visible = false
    end
    for i = 1, 8 do
        local isl = islands[i]
        if isl then
            W.islandBtns[i] = W.islandBtns[i] or makeIslandBtn(i)
            W.islandBtns[i].island = isl
            local b = W.islandBtns[i].button
            b.Visible = true
            b.Text = ("%s   (%d eggs)"):format(isl.key, SaB.Extras.eggCountOn(isl.key))
            b.BackgroundColor3 = SaB.Extras.islandColor(isl.key)
            b.TextColor3 = Color3.fromRGB(12, 12, 16)
        elseif W.islandBtns[i] then
            W.islandBtns[i].button.Visible = false
        end
    end

    -- afk
    W.afkLine.Text = W.CONFIG.AfkJump
        and ("afk: jumping every %ss%s"):format(tostring(W.CONFIG.AfkJumpInterval),
            (W.CONFIG.AfkTrampolineName ~= "" and ("  on " .. W.CONFIG.AfkTrampolineName) or ""))
        or "afk: off"
    W.afkLine.TextColor3 = W.CONFIG.AfkJump and SaB.Theme.OK or SaB.Theme.DIM

    -- farm info
    local base = W.Farm.Base.get()
    W.baseLine.Text = base and ("base: %s   (%.0f, %.0f, %.0f)"):format(
        base.source, base.pos.X, base.pos.Y, base.pos.Z) or "base: NOT FOUND - press SET BASE HERE"
    W.baseLine.TextColor3 = base and SaB.Theme.DIM or SaB.Theme.BAD
    W.farmStatsLine.Text = ("delivered %d   •   failed %d   •   last: %s   •   grab method: %s"):format(
        W.Farm.stats.delivered, W.Farm.stats.failed, W.Farm.stats.lastEgg, W.Farm.Pickup.lastMethod)

    if W.tpLine then
        local tp = W.Farm.Teleport
        local st = tp.stats or {}
        if tp.flying then
            W.tpLine.Text = ("tp: FLYING  %d%%  •  mode %s  •  %d studs/s"):format(
                tp.progress or 0, tostring(W.CONFIG.EggTpMode), tonumber(W.CONFIG.EggTpSpeed) or 0)
            W.tpLine.TextColor3 = SaB.Theme.ACC
        else
            W.tpLine.Text = ("tp: %s  •  flights %d  arrived %d  snaps fought %d"):format(
                tostring(tp.lastWhy or "idle"), st.flights or 0, st.arrived or 0, st.snapped or 0)
            W.tpLine.TextColor3 = (tp.lastWhy == "arrived") and SaB.Theme.OK
                or ((tp.lastWhy == "idle") and SaB.Theme.DIM or SaB.Theme.WARN)
        end
    end

    if total ~= W.lastCounts.total then
        W.lastCounts.total = total
        if total > 0 then
            W.eggLog(("%d eggs tracked (%d match your filters)"):format(total, matching), SaB.Theme.ACC)
        end
    end
end

W.Farm.onStatus = function(text, color)
    pcall(function()
        W.statusLine.Text = "farm: " .. tostring(text)
        W.statusLine.TextColor3 = color or SaB.Theme.DIM
    end)
end

Log.onAdd(function(text, color, tag)
    if tag == "EGG" or tag == "FARM" then
        pcall(W.eggLog, text, color)
    end
end)

--==============================================================
--  PAGE 2 : CODE SNIPER
--==============================================================
W.sniperPage = W.UI.addTab("Sniper")
W.UI.label(W.sniperPage, "CODE SNIPER - listens to SpyderSammy and types the code for you",
    SaB.Theme.ACC, { bold = true })

W.sniperStatus = W.UI.label(W.sniperPage, "status: listening...", SaB.Theme.DIM)
SaB.Sniper.statusFn = function(t, c)
    pcall(function()
        W.sniperStatus.Text = ("status: %s\n|  type: %s  |  captured: %d"):format(
            t, SaB.Sniper.describeHint(SaB.Sniper.hint), SaB.Sniper.captured)
        W.sniperStatus.TextColor3 = c or SaB.Theme.DIM
    end)
end

W.snipMain = W.UI.section(W.sniperPage, "Main", SaB.Theme.ACC)
W.UI.toggle(W.snipMain, "Sniper enabled", W.CONFIG.SniperEnabled, function(v) W.CONFIG.SniperEnabled = v end)
W.UI.toggle(W.snipMain, "TEST: listen to everyone", W.CONFIG.SniperListenEveryone, function(v)
    W.CONFIG.SniperListenEveryone = v
    if v then W.UI.toastShow("type in chat: code is TACO BOOST 123", SaB.Theme.WARN, 4) end
end)
W.UI.toggle(W.snipMain, "Auto press Submit", W.CONFIG.SniperAutoSubmit, function(v)
    W.CONFIG.SniperAutoSubmit = v
end)

W.typeValues = {}
for _, t in ipairs(SaB.Sniper.CODE_TYPES) do table.insert(W.typeValues, t.name) end
W.UI.cycle(W.snipMain, "Code type", W.typeValues, W.CONFIG.SniperTypeIndex, function(i)
    W.CONFIG.SniperTypeIndex = i
    SaB.Sniper.hint = SaB.Sniper.hintFromIndex(i)
    SaB.Sniper.hintFromChat = false
end)

W.startBtn = W.UI.button(W.snipMain, "▶  START capturing", function()
    SaB.Sniper.hintFromChat = false
    SaB.Sniper.startSession()
    W.UI.toastShow("capturing started - say the code!", SaB.Theme.OK, 2)
end, { h = 38, color = SaB.Theme.ON })
W.fmtJoined = true
-- (moved into the widget table)
W.fmtBtn = W.UI.button(W.snipMain, "Format:  JOINED (TACOBOOST)", function()
    fmtJoined = not W.fmtJoined
    W.CONFIG.SniperJoinCode = W.fmtJoined
    W.fmtBtn.Text = W.fmtJoined and "Format:  JOINED (TACOBOOST)" or 'Format:  SPACED ("TACO BOOST")'
end, { color = SaB.Theme.BTN })
W.UI.button(W.snipMain, "■  STOP capturing", function() SaB.Sniper.finalizeCode() end)

W.snipFilters = W.UI.section(W.sniperPage, "Options", SaB.Theme.DIM)
W.timeoutInput = W.UI.input(W.snipFilters, "silence timeout (seconds)",
    tostring(W.CONFIG.SniperSilenceTimeout), function(text)
        local n = tonumber(text)
        if n then W.CONFIG.SniperSilenceTimeout = W.Util.clamp(n, 1, 60) end
    end)
W.UI.input(W.snipFilters, "code box path (optional, auto-detect when empty)",
    W.CONFIG.CodeBoxPathOverride, function(text) W.CONFIG.CodeBoxPathOverride = text end)

W.testSection = W.UI.section(W.sniperPage, "Test zone (no event needed)",
    Color3.fromRGB(255, 190, 60))
W.testInput = W.UI.input(W.testSection, "type a word (e.g. TACO)", "")
W.UI.button(W.testSection, "1) Feed this word", function()
    local w = W.testInput.Text
    if w == "" then return end
    W.testInput.Text = ""
    SaB.Sniper.handleMessage(w, SaB.LocalPlayer.UserId, SaB.LocalPlayer.Name, true)
end)
W.UI.button(W.testSection, "2) Start session (marker)", function()
    SaB.Sniper.handleMessage("code is", SaB.LocalPlayer.UserId, SaB.LocalPlayer.Name, true)
end)
W.UI.button(W.testSection, "3) DEMO: two words", function()
    task.spawn(function()
        for _, w in ipairs({ "the code is two words", "TACO", "BOOST" }) do
            SaB.Sniper.handleMessage(w, SaB.LocalPlayer.UserId, SaB.LocalPlayer.Name, true)
            task.wait(0.8)
        end
        W.UI.toastShow("demo finished - check the log", SaB.Theme.OK, 2)
    end)
end)
W.UI.button(W.testSection, "3b) DEMO: words + numbers", function()
    task.spawn(function()
        for _, w in ipairs({ "the code is letters and numbers", "TACO", "BOOST", "123" }) do
            SaB.Sniper.handleMessage(w, SaB.LocalPlayer.UserId, SaB.LocalPlayer.Name, true)
            task.wait(0.8)
        end
        W.UI.toastShow("demo finished - check the log", SaB.Theme.OK, 2)
    end)
end)
W.UI.button(W.testSection, "4) Force finish now", function() SaB.Sniper.finalizeCode() end)

W.sniperLogBox = W.UI.log(W.sniperPage, 170)
W.sniperLog = W.sniperLogBox.add
SaB.Sniper.logFn = function(text, color) pcall(W.sniperLog, text, color) end
W.sniperLog("sniper ready - target: SpyderSammy (id " .. W.CONFIG.SniperTargetUserId .. ")", SaB.Theme.ACC)
W.sniperLog("waiting for a marker ('code is') or a type announcement ...", SaB.Theme.DIM)
W.sniperLog("tip: pick the CODE TYPE above, or let the sniper read it from Sammy", SaB.Theme.DIM)

--==============================================================
--  PAGE 3 : DIAGNOSTICS
--==============================================================
W.Diag = {}
SaB.Diag = W.Diag
W.Diag.lastReport = ""

W.diagPage = W.UI.addTab("W.Diag")
W.UI.label(W.diagPage, "DIAGNOSTICS - press REPORT then send me the text (copy or file)",
    SaB.Theme.ACC, { bold = true })

local function line(out, text)
    table.insert(out, tostring(text))
end

function W.Diag.buildReport()
    local out = {}
    local lp = SaB.LocalPlayer
    line(out, "=== SaB Suite report ===")
    line(out, ("version   : %s"):format(SaB.VERSION))
    line(out, ("date      : %s"):format(os.date("%Y-%m-%d %H:%M:%S")))
    line(out, ("placeId   : %s   jobId: %s"):format(tostring(game.PlaceId), tostring(game.JobId)))
    line(out, ("player    : %s (%s)"):format(lp.Name, tostring(lp.UserId)))
    line(out, ("egg DB    : %d known eggs, source: %s"):format(#SaB.EggDB.EGGS, SaB.EggDB.SOURCE))
    line(out, "")

    -- 1) top level of the workspace
    line(out, "--- WORKSPACE (top level) ---")
    for _, c in ipairs(SaB.Services.Workspace:GetChildren()) do
        local n = 0
        pcall(function() n = #c:GetChildren() end)
        line(out, ("  %s  [%s]  children=%d"):format(c.Name, c.ClassName, n))
    end
    line(out, "")

    -- 2) second level (folders where eggs usually live)
    line(out, "--- WORKSPACE (2nd level, first 200) ---")
    local printed = 0
    for _, c in ipairs(SaB.Services.Workspace:GetChildren()) do
        if printed >= 200 then break end
        local ok, kids = pcall(function() return c:GetChildren() end)
        if ok then
            for _, k in ipairs(kids) do
                if printed >= 200 then break end
                line(out, ("  %s/%s  [%s]"):format(c.Name, k.Name, k.ClassName))
                printed = printed + 1
            end
        end
    end
    line(out, "")

    -- 3) anything with an egg-ish name
    line(out, "--- OBJECTS WITH AN EGG-ISH NAME ---")
    local eggish = 0
    for _, d in ipairs(SaB.Services.Workspace:GetDescendants()) do
        if eggish >= 120 then break end
        local n = W.Util.lower(d.Name)
        if (d:IsA("Model") or d:IsA("BasePart") or d:IsA("Folder"))
            and (SaB.EggDB.isEggWord(n) or SaB.EggDB.lookup(d.Name)) then
            line(out, ("  %s  [%s]  parent=%s"):format(
                W.Util.path(d), d.ClassName, d.Parent and d.Parent.Name or "?"))
            eggish = eggish + 1
        end
    end
    if eggish == 0 then line(out, "  (none)") end
    line(out, "")

    -- 4) what our scanner actually found
    line(out, "--- SCANNER FINDINGS ---")
    local list = SaB.Scanner.list or {}
    line(out, ("  %d eggs tracked"):format(#list))
    for _, rec in ipairs(list) do
        line(out, ("  %s | %s | island=%s | via=%s | score=%d | path=%s"):format(
            rec.name, rec.rarity, tostring(rec.island), rec.source, rec.score, rec.path))
    end
    line(out, ("  roots watched: %d"):format(W.Util.tableCount(SaB.Scanner.roots)))
    line(out, ("  last scan: %d objects in %.2fs"):format(
        SaB.Scanner.stats.scanned or 0, SaB.Scanner.stats.lastDuration or 0))
    line(out, "")

    -- 5) prompts we have seen
    line(out, "--- PROXIMITY PROMPTS SEEN ---")
    if #SaB.Scanner.promptLog == 0 then
        line(out, "  (none yet - walk up to an egg / an NPC)")
    else
        for _, l in ipairs(SaB.Scanner.promptLog) do line(out, "  " .. l) end
    end
    line(out, "")

    -- 6) remotes that look useful
    line(out, "--- REMOTES (collect / pick / egg / hatch) ---")
    local remotes = 0
    for _, d in ipairs(SaB.Services.ReplicatedStorage:GetDescendants()) do
        if remotes >= 80 then break end
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
            local n = W.Util.lower(d.Name)
            if n:find("collect") or n:find("pick") or n:find("egg") or n:find("hatch")
                or n:find("grab") or n:find("take") or n:find("steal") then
                line(out, "  " .. W.Util.path(d))
                remotes = remotes + 1
            end
        end
    end
    if remotes == 0 then line(out, "  (none)") end
    line(out, "")

    -- 7) base candidates
    line(out, "--- BASE CANDIDATES ---")
    local bp, src = W.Farm.Base.find()
    line(out, ("  found: %s   source: %s"):format(
        bp and ("%.0f, %.0f, %.0f"):format(bp.X, bp.Y, bp.Z) or "NO", tostring(src)))
    line(out, "")

    -- 8) character / carrying
    line(out, "--- PLAYER ---")
    local hrp = W.Util.getHRP()
    line(out, ("  position: %s"):format(hrp and ("%.0f, %.0f, %.0f"):format(
        hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "no character"))
    line(out, ("  carrying: %s"):format(tostring(W.Farm.Carry.what())))
    local attrs = W.Util.getAttributes(lp)
    local attrBits = {}
    for k, v in pairs(attrs) do
        table.insert(attrBits, ("%s=%s"):format(k, tostring(v)))
    end
    line(out, ("  attributes: %s"):format(#attrBits > 0 and table.concat(attrBits, ", ") or "(none)"))
    line(out, "")
    line(out, "=== end of report ===")

    local text = table.concat(out, "\n")
    W.Diag.lastReport = text
    return text
end

W.diagLog = W.UI.log(W.diagPage, 220).add

local function dumpToLog(title, items)
    W.diagLog(("=== %s (%d) ==="):format(title, #items), SaB.Theme.ACC)
    for i = 1, math.min(#items, 80) do W.diagLog("  " .. tostring(items[i]), SaB.Theme.TEXT) end
end

W.diagSection = W.UI.section(W.diagPage, "Reports", SaB.Theme.ACC)
W.UI.button(W.diagSection, "▶  BUILD FULL REPORT", function()
    local text = W.Diag.buildReport()
    W.diagLog("=== FULL REPORT ===", SaB.Theme.ACC)
    for l in (text .. "\n"):gmatch("([^\n]*)\n") do
        W.diagLog(l, SaB.Theme.TEXT)
    end
    print(text)
    W.UI.toastShow("report built - copy / save it below", SaB.Theme.OK, 3)
end, { h = 36, color = SaB.Theme.ACC })

do
    local row = W.UI.row(W.diagSection, 30)
    W.UI.button(row, "COPY report", function()
        if W.Diag.lastReport == "" then W.Diag.buildReport() end
        if W.Util.clipboard(W.Diag.lastReport) then
            W.UI.toastShow("copied to clipboard", SaB.Theme.OK, 2)
        else
            W.UI.toastShow("no clipboard on this executor - use SAVE", SaB.Theme.BAD, 3)
        end
    end, { width = 0.5, color = SaB.Theme.ON })
    W.UI.button(row, "SAVE to file", function()
        if W.Diag.lastReport == "" then W.Diag.buildReport() end
        if W.Util.writeFile("egg_report.txt", W.Diag.lastReport) then
            W.UI.toastShow("saved to SaBSuite/egg_report.txt", SaB.Theme.OK, 3)
        else
            W.UI.toastShow("writefile not supported here", SaB.Theme.BAD, 3)
        end
    end, { width = 0.5 })
end

W.dumpSection = W.UI.section(W.diagPage, "Quick dumps", SaB.Theme.DIM)
W.UI.button(W.dumpSection, "Dump: names containing 'egg'", function()
    local items = {}
    for _, d in ipairs(SaB.Services.Workspace:GetDescendants()) do
        if W.Util.has(d.Name, "egg") then
            table.insert(items, ("%s [%s] parent=%s"):format(
                W.Util.path(d), d.ClassName, d.Parent and d.Parent.Name or "?"))
        end
    end
    dumpToLog("EGG NAMES", items)
end)
W.UI.button(W.dumpSection, "Dump: island / LTM folders", function()
    local items = {}
    for _, d in ipairs(SaB.Services.Workspace:GetDescendants()) do
        if d:IsA("Folder") or d:IsA("Model") then
            if SaB.EggDB.isContainerWord(d.Name) then
                local n = 0
                pcall(function() n = #d:GetChildren() end)
                table.insert(items, ("%s [%s] children=%d"):format(W.Util.path(d), d.ClassName, n))
            end
        end
    end
    dumpToLog("CONTAINERS", items)
end)
W.UI.button(W.dumpSection, "Dump: proximity prompts in the map", function()
    local items = {}
    for _, d in ipairs(SaB.Services.Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            table.insert(items, ("%s | action='%s' | hold=%.1f | parent=%s"):format(
                W.Util.path(d), tostring(d.ActionText), tonumber(d.HoldDuration) or 0,
                W.Util.path(d.Parent)))
        end
    end
    dumpToLog("PROMPTS", items)
end)
W.UI.button(W.dumpSection, "Dump: remotes", function()
    local items = {}
    for _, d in ipairs(SaB.Services.ReplicatedStorage:GetDescendants()) do
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
            table.insert(items, W.Util.path(d))
        end
    end
    dumpToLog("REMOTES", items)
end)
W.UI.button(W.dumpSection, "Dump: my attributes + carrying", function()
    local items = {}
    for k, v in pairs(W.Util.getAttributes(SaB.LocalPlayer)) do
        table.insert(items, ("player.%s = %s"):format(k, tostring(v)))
    end
    local char = W.Util.getChar()
    if char then
        for _, d in ipairs(char:GetDescendants()) do
            if W.Util.has(d.Name, "egg") or W.Util.has(d.Name, "carry") or W.Util.has(d.Name, "hold") then
                table.insert(items, "character has: " .. W.Util.path(d))
            end
        end
    end
    table.insert(items, "carrying = " .. tostring(W.Farm.Carry.what()))
    dumpToLog("PLAYER", items)
end)
W.UI.button(W.dumpSection, "Dump: what the scanner is tracking", function()
    local items = {}
    for _, rec in ipairs(SaB.Scanner.list or {}) do
        table.insert(items, ("%s | %s | island=%s | via=%s | score=%d | %s"):format(
            rec.name, rec.rarity, tostring(rec.island), rec.source, rec.score, rec.path))
    end
    dumpToLog("TRACKED EGGS", items)
end)

--==============================================================
--  PAGE 4 : SETTINGS
--==============================================================
W.setPage = W.UI.addTab("Settings")
W.UI.label(W.setPage, "SETTINGS", SaB.Theme.ACC, { bold = true })

W.uiSection = W.UI.section(W.setPage, "Interface", SaB.Theme.ACC)
W.UI.cycle(W.uiSection, "Label size", { "normal", "big", "huge" }, 1, function(i)
    W.CONFIG.EggLabelScale = ({ 1.0, 1.25, 1.5 })[i]
    SaB.ESP.rebuild()
end)
W.UI.input(W.uiSection, "ESP max distance (studs)", tostring(W.CONFIG.EggEspMaxDistance), function(text)
    local n = tonumber(text)
    if n then
        W.CONFIG.EggEspMaxDistance = W.Util.clamp(n, 200, 20000)
        SaB.ESP.rebuild()
    end
end)
W.UI.button(W.uiSection, "Reset window position", function() W.UI.resetPosition() end)
W.UI.button(W.uiSection, "Re-center + reopen", function()
    W.UI.show()
    W.UI.setMinimized(false)
    W.UI.resetPosition()
end)
W.UI.button(W.uiSection, "Clear all ESP labels", function()
    SaB.ESP.clear()
    W.UI.toastShow("labels cleared", SaB.Theme.OK, 2)
end)

W.saveSection = W.UI.section(W.setPage, "Saved settings", SaB.Theme.ACC)
W.saveLine = W.UI.label(W.saveSection, "settings are kept in SaBSuite/settings.txt",
    SaB.Theme.DIM, { size = 10 })
W.UI.toggle(W.saveSection, "Load my settings at startup", W.CONFIG.AutoLoadSettings,
    function(v) W.CONFIG.AutoLoadSettings = v end)
do
    local row = W.UI.row(W.saveSection, 30)
    W.UI.button(row, "SAVE", function()
        local ok, msg = SaB.Extras.save()
        W.saveLine.Text = (ok and "settings saved" or ("could not save: " .. tostring(msg)))
        W.saveLine.TextColor3 = ok and SaB.Theme.OK or SaB.Theme.BAD
        W.UI.toastShow(ok and "settings saved" or "save failed", ok and SaB.Theme.OK or SaB.Theme.BAD, 3)
    end, { width = 0.34, color = SaB.Theme.ON })
    W.UI.button(row, "LOAD", function()
        local ok, msg = SaB.Extras.load()
        W.saveLine.Text = tostring(msg)
        W.saveLine.TextColor3 = ok and SaB.Theme.OK or SaB.Theme.WARN
        W.UI.toastShow(tostring(msg), ok and SaB.Theme.OK or SaB.Theme.WARN, 3)
    end, { width = 0.33 })
    W.UI.button(row, "DELETE", function()
        local ok, msg = SaB.Extras.delete()
        W.saveLine.Text = tostring(msg)
        W.UI.toastShow(tostring(msg), ok and SaB.Theme.OK or SaB.Theme.WARN, 3)
    end, { width = 0.33, color = SaB.Theme.OFF })
end

W.infoSection = W.UI.section(W.setPage, "Info", SaB.Theme.DIM)
W.UI.label(W.infoSection,
    ("version %s   •   %d known eggs (Update 68 LTM)\n"):format(SaB.VERSION, #SaB.EggDB.EGGS)
    .. "Egg data: Steal a Brainrot Wiki - 'Jump for Eggs LTM'.\n"
    .. "W.Rarity colours: one colour per category (Secret = gold, "
    .. "Brainrot God = pink, Mythic = red, ...).\n"
    .. "Islands: Grass < Desert < Arctic < Cave < Aquatic < Lava < Heavenly.",
    SaB.Theme.DIM, { size = 10 })

W.UI.button(W.infoSection, "UNLOAD script (stop everything)", function()
    SaB.Running = false
    W.CONFIG.EggAutoFarm = false
    W.CONFIG.EggESPEnabled = false
    W.CONFIG.SniperEnabled = false
    pcall(function() SaB.ESP.clear() end)
    pcall(function() W.UI.gui:Destroy() end)
    W.Util.notify("SaB Suite", "unloaded", 3)
end, { color = SaB.Theme.OFF })

--==============================================================
--  STARTUP
--==============================================================
W.UI.layoutTabs()
W.UI.selectTab("Eggs")

task.spawn(function()
    while SaB.Running do
        task.wait(1)
        pcall(function()
            if W.UI.currentTab == "Eggs" and W.UI.gui.Enabled then
                W.Pages.refreshEggs()
            end
        end)
    end
end)

-- first paint
task.spawn(function()
    task.wait(1.2)
    pcall(W.Pages.refreshEggs)
end)


--==============================================================
--  MODULE: 09_Extras.lua
--==============================================================
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


--==============================================================
--  MODULE: 10_Main.lua
--==============================================================
--==============================================================
--  MAIN  (boot + welcome + smart hints)
--==============================================================

local Util    = SaB.Util
local CONFIG  = SaB.CONFIG

if CONFIG.AutoLoadSettings then
    local ok, msg = SaB.Extras.load()
    Log.info("settings: " .. tostring(msg), ok and SaB.Theme.OK or SaB.Theme.DIM)
end

Log.info(("SaB Suite v%s loaded - %d known eggs in the database")
    :format(SaB.VERSION, #SaB.EggDB.EGGS), SaB.Theme.ACC)
Log.eggs("first scan started (whole map) ...", SaB.Theme.DIM)

Util.notify("SaB Suite", ("v%s loaded - Eggs tab is open"):format(SaB.VERSION), 5)

-- when the character respawns the old positions are useless
SaB.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    pcall(function()
        SaB.Farm.Base.cached = nil
        SaB.Farm.Teleport.lastSafe = nil
    end)
end)

-- after 20 seconds: tell the user what is going on if nothing was found
task.spawn(function()
    task.wait(20)
    if not SaB.Running then return end
    local total = Util.tableCount(SaB.Scanner.eggs)
    if total == 0 then
        Log.warn("no eggs found in the first 20s - things to check:", SaB.Theme.WARN)
        Log.warn("  1) are you inside the LTM? (go through the portal)", SaB.Theme.WARN)
        Log.warn("  2) press 'DEEP SCAN NOW' in the Eggs tab", SaB.Theme.WARN)
        Log.warn("  3) open the DIAGNOSTICS tab -> BUILD FULL REPORT and send it", SaB.Theme.WARN)
        Util.notify("SaB Suite", "No eggs found yet - see the console / Diag tab", 6)
    else
        Log.ok(("%d eggs tracked - ESP is drawing labels"):format(total), SaB.Theme.OK)
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


--[[ ===================== end of build ===================== ]]
print(("[SaB Suite] v2.3.0 loaded - Eggs tab is the main tab."):format(SaB.VERSION))
