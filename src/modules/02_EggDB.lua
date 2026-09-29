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

return EggDB
