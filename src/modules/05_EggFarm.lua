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
--==============================================================
local Teleport = {}
Farm.Teleport = Teleport
Teleport.cancelFlag = false
Teleport.lastSafe = nil

function Teleport.cancel()
    Teleport.cancelFlag = true
    Farm.setAnchor(false)      -- never leave the player frozen in the air
end

-- freeze / unfreeze the character while we wait for the game to react
function Farm.setAnchor(state)
    if state and not CONFIG.EggAnchorWhileWaiting then return end
    local hrp = Util.getHRP()
    if not hrp then return end
    pcall(function() hrp.Anchored = state and true or false end)
end

local function setCFrame(pos)
    local hrp = Util.getHRP()
    if not hrp then return false end
    pcall(function()
        hrp.CFrame = CFrame.new(pos)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    if hrp.Position.Y > -150 then
        Teleport.lastSafe = hrp.Position
    end
    return true
end

-- move in small jumps: climb first, then cross, then land
function Teleport.stepTo(target)
    local hrp = Util.getHRP()
    if not hrp or not target then return false end

    local step = math.max(20, CONFIG.EggStepSize)
    local delay = CONFIG.EggStepDelay
    local from = hrp.Position

    -- 1) vertical (is islands are very high / very low)
    local dy = target.Y + 3 - from.Y
    if math.abs(dy) > 45 then
        local dir = dy > 0 and 1 or -1
        local climbed = 0
        while climbed < math.abs(dy) do
            if Teleport.cancelFlag then return false end
            if not Util.isAlive() then return false end
            local hrp2 = Util.getHRP()
            if not hrp2 then return false end
            local move = math.min(step, math.abs(dy) - climbed)
            setCFrame(hrp2.Position + Vector3.new(0, dir * move, 0))
            climbed = climbed + move
            task.wait(delay)
        end
    end

    -- 2) horizontal
    while true do
        if Teleport.cancelFlag then return false end
        if not Util.isAlive() then return false end
        local hrp2 = Util.getHRP()
        if not hrp2 then return false end
        local flat = Vector3.new(target.X - hrp2.Position.X, 0, target.Z - hrp2.Position.Z)
        local len = flat.Magnitude
        if len <= step then
            setCFrame(Vector3.new(target.X, hrp2.Position.Y, target.Z))
            break
        end
        setCFrame(hrp2.Position + (flat.Unit * step))
        task.wait(delay)
    end

    -- 3) settle on the egg
    setCFrame(Vector3.new(target.X, target.Y + 3, target.Z))
    task.wait(0.12)
    return true
end

function Teleport.to(target)
    if Teleport.cancelFlag then Teleport.cancelFlag = false end
    Farm.setAnchor(false)
    local hrp = Util.getHRP()
    if not hrp or not target then return false end

    local dist = (hrp.Position - target).Magnitude
    if not CONFIG.EggSafeTeleport or dist <= 80 then
        setCFrame(target + Vector3.new(0, 3, 0))
        task.wait(0.15)
        return true
    end
    return Teleport.stepTo(target)
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
        setCFrame(back + Vector3.new(0, 8, 0))
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
    Teleport.to(rec.pos)
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
        Teleport.to(rec.pos)
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
    Teleport.to(rec.pos)

    local hrp = Util.getHRP()
    if hrp then
        local d = (hrp.Position - rec.pos).Magnitude
        if d > 60 then
            Teleport.to(rec.pos)
            task.wait(0.3)
        end
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

return Farm
