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
