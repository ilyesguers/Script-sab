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

return Farm
