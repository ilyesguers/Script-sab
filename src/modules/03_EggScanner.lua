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
local EggDB   = SaB.EggDB
local Rarity  = SaB.Rarity

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
    local entry   = EggDB.lookup(raw)
    local nameHasEggWord = EggDB.isEggWord(raw)          -- "Egg_1"
    local pathHasEggWord = EggDB.isEggWord(parents)      -- inside "Eggs"
    local hasContainer   = EggDB.isContainerWord(parents)
    local isLocation     = EggDB.isLocationWord(raw)     -- "GrassIsland"

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
    local flagValue      = Util.getAttribute(obj, EggDB.FLAG_ATTRS)
    local nameFromAttr   = Util.getAttribute(obj, EggDB.NAME_ATTRS)
    local rarityFromAttr = Util.getAttribute(obj, EggDB.RARITY_ATTRS)
    local islandFromAttr = Util.getAttribute(obj, EggDB.ISLAND_ATTRS)

    local entryFromAttr = nil
    if type(nameFromAttr) == "string" then
        entryFromAttr = EggDB.lookup(nameFromAttr)
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
        rarityGuessed = Rarity.normalize(tostring(rarityFromAttr))
            or EggDB.rarityFromText(tostring(rarityFromAttr))
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
            if EggDB.isPromptWord(action) then
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
        local v = Util.findValue(obj, EggDB.NAME_ATTRS, 30)
        if type(v) == "string" then
            local e2 = EggDB.lookup(v)
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
    local info = EggDB.classify(entry and entry.n or (entryFromAttr and entryFromAttr.n) or raw)

    local name
    if entry then
        name = entry.n
    elseif entryFromAttr then
        name = entryFromAttr.n
    elseif type(nameFromAttr) == "string" and #nameFromAttr > 1 then
        name = EggDB.displayName(nameFromAttr)
    else
        name = EggDB.displayName(raw)
    end

    local rarity = "Unknown"
    if rarityGuessed then
        rarity = rarityGuessed
    elseif info.known then
        rarity = info.rarity
    else
        rarity = EggDB.rarityFromText(raw .. " " .. parents) or "Unknown"
    end
    rarity = Rarity.normalize(rarity) or rarity
    if not Rarity.COLORS[rarity] then rarity = "Unknown" end

    local island = nil
    if islandFromAttr ~= nil then
        island = EggDB.islandFromText(tostring(islandFromAttr))
    end
    if not island and info.known then island = info.island end
    if not island then island = EggDB.islandFromText(parents .. " " .. raw) end

    local pos, height = Util.getBounds(obj)
    if not pos then return nil end

    local timer, timerSource = Util.findTimer(obj)

    local rec = {
        obj         = obj,
        isLocation  = isLocation,
        raw         = raw,
        name        = name,
        rarity      = rarity,
        tier        = Rarity.tier(rarity),
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
    if fromEvent then
        Log.eggs(("NEW egg  %s  [%s]  %s  (%s, %s)"):format(
            rec.name, rec.rarity, rec.island and (rec.island .. " island") or "island ?",
            Util.formatDistance(rec.dist), Scanner.SOURCE_LABEL[rec.source] or rec.source),
            Rarity.color(rec.rarity))
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
    if EggDB.isContainerWord(obj.Name) or EggDB.isEggWord(obj.Name) then
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

    objects = Scanner.walk(Workspace, function(obj)
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
        local minName = Rarity.fromIndex(CONFIG.EggMinRarityIndex)
        if minName and rec.tier < Rarity.tier(minName) then return false end
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

return Scanner
