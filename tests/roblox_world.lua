--[[ =====================================================================
     A fake Roblox world (used only by tests/run_world_tests.py).

     It is complete enough to LOAD and RUN the real scanner / farm
     modules, so we can prove that eggs are detected, filtered and
     picked up without opening the game.
     ===================================================================== ]]

local World = {}

-- ---------------------------------------------------------------- basics
math.clamp = math.clamp or function(n, lo, hi)
    n = tonumber(n) or 0
    if n < lo then return lo end
    if n > hi then return hi end
    return n
end
math.round = math.round or function(n) return math.floor(n + 0.5) end
tick = tick or function() return os.clock() end

-- ---------------------------------------------------------------- vectors
local V3 = {}
V3.__index = function(t, k)
    if k == "Magnitude" then
        return math.sqrt(t.x * t.x + t.y * t.y + t.z * t.z)
    elseif k == "Unit" then
        local m = math.sqrt(t.x * t.x + t.y * t.y + t.z * t.z)
        if m == 0 then return Vector3.new(0, 0, 0) end
        return Vector3.new(t.x / m, t.y / m, t.z / m)
    end
    return rawget(V3, k)
end
V3.__add = function(a, b) return Vector3.new(a.x + b.x, a.y + b.y, a.z + b.z) end
V3.__sub = function(a, b) return Vector3.new(a.x - b.x, a.y - b.y, a.z - b.z) end
V3.__mul = function(a, b)
    if type(b) == "number" then return Vector3.new(a.x * b, a.y * b, a.z * b) end
    return Vector3.new(a.x * b.x, a.y * b.y, a.z * b.z)
end
V3.__tostring = function(v) return ("Vector3(%s, %s, %s)"):format(v.x, v.y, v.z) end

Vector3 = {
    zero = setmetatable({ x = 0, y = 0, z = 0, X = 0, Y = 0, Z = 0 }, V3),
    new = function(x, y, z)
        x, y, z = x or 0, y or 0, z or 0
        return setmetatable({ x = x, y = y, z = z, X = x, Y = y, Z = z }, V3)
    end,
}
setmetatable(Vector3.zero, V3)

CFrame = {
    new = function(x, y, z)
        local p
        if type(x) == "table" and x.x then p = x else p = Vector3.new(x, y, z) end
        return setmetatable({ Position = p, __cframe = true }, {})
    end,
}

Color3 = {
    fromRGB = function(r, g, b) return { r = r, g = g, b = b, __color = true } end,
}

Vector2 = { new = function(x, y) return { X = x or 0, Y = y or 0 } end }

UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
UDim2 = {
    new = function(xs, xo, ys, yo) return { X = UDim.new(xs, xo), Y = UDim.new(ys, yo) } end,
    fromOffset = function(x, y) return { X = UDim.new(0, x), Y = UDim.new(0, y) } end,
}

Enum = setmetatable({}, {
    __index = function(_, k)
        return setmetatable({}, {
            __index = function(_, v) return ("Enum.%s.%s"):format(k, v) end,
        })
    end,
})

typeof = function(v)
    if type(v) == "table" then
        if v.__color then return "Color3" end
        if v.__vector then return "Vector3" end
        if v.__cframe then return "CFrame" end
        if v.ClassName then return "Instance" end
        if v.x then return "Vector3" end
    end
    return type(v)
end

-- ---------------------------------------------------------------- signals
local Signal = {}
Signal.__index = Signal
function Signal.new(name)
    return setmetatable({ Name = name, _handlers = {} }, Signal)
end
function Signal:Connect(fn)
    table.insert(self._handlers, fn)
    return { Disconnect = function() end, Connected = true }
end
function Signal:Fire(...)
    for _, h in ipairs(self._handlers) do h(...) end
end

local EVENT_SUFFIX = {
    "Added", "Removing", "Changed", "Shown", "Hidden", "Received", "Began",
    "Ended", "Lost", "Click", "Tap", "Activated", "Died", "Heartbeat",
    "Stepped", "Triggered", "Input", "Message", "ted",
}
local function looksLikeEvent(k)
    if type(k) ~= "string" then return false end
    if not k:match("^%u") then return false end
    for _, suf in ipairs(EVENT_SUFFIX) do
        if k:sub(-#suf) == suf then return true end
    end
    return false
end

-- ---------------------------------------------------------------- instances
local SUPER = {
    Part = "BasePart", MeshPart = "BasePart", UnionOperation = "BasePart",
    WedgePart = "BasePart", CornerWedgePart = "BasePart", TrussPart = "BasePart",
    SpawnLocation = "BasePart", VehicleSeat = "BasePart", Seat = "BasePart",
    TextButton = "GuiButton", ImageButton = "GuiButton",
    TextLabel = "GuiObject", Frame = "GuiObject", ImageLabel = "GuiObject",
    StringValue = "ValueBase", IntValue = "ValueBase", NumberValue = "ValueBase",
    BoolValue = "ValueBase", ObjectValue = "ValueBase", CFrameValue = "ValueBase",
    ScreenGui = "LayerCollector", BillboardGui = "LayerCollector",
}

local storeOf = setmetatable({}, { __mode = "k" })
local proxyOf = setmetatable({}, { __mode = "k" })

local DEFAULTS = {
    TextBounds = { X = 100, Y = 14, x = 100, y = 14 },
    AbsoluteSize = { X = 100, Y = 20 },
    AbsolutePosition = { X = 0, Y = 0 },
    AbsoluteCanvasSize = { X = 300, Y = 400 },
    Size = Vector3.new(4, 6, 4),
}

local methods = {}
local ObjMT = {}

local function store(t)
    return storeOf[t]
end

function methods.IsA(self, name)
    local c = store(self).ClassName
    if c == name then return true end
    while SUPER[c] do
        c = SUPER[c]
        if c == name then return true end
    end
    return name == "Instance"
end

function methods.GetChildren(self)
    local out = {}
    for _, c in ipairs(store(self).children) do table.insert(out, c) end
    return out
end

function methods.GetDescendants(self)
    local out = {}
    local function walk(node)
        for _, c in ipairs(store(node).children) do
            table.insert(out, c)
            walk(c)
        end
    end
    walk(self)
    return out
end

function methods.FindFirstChild(self, name, recursive)
    for _, c in ipairs(store(self).children) do
        if c.Name == name then return c end
    end
    if recursive then
        for _, d in ipairs(self:GetDescendants()) do
            if d.Name == name then return d end
        end
    end
    return nil
end

function methods.FindFirstChildOfClass(self, class)
    for _, c in ipairs(store(self).children) do
        if c:IsA(class) then return c end
    end
    return nil
end

function methods.FindFirstChildWhichIsA(self, class, recursive)
    local list = recursive and self:GetDescendants() or self:GetChildren()
    for _, c in ipairs(list) do
        if c:IsA(class) then return c end
    end
    return nil
end

function methods.FindFirstAncestorWhichIsA(self, class)
    local p = store(self).parent
    while p do
        if p:IsA(class) then return p end
        p = store(p).parent
    end
    return nil
end

function methods.WaitForChild(self, name)
    local found = self:FindFirstChild(name)
    if found then return found end
    local obj = World.new(name, self)
    obj.ClassName = "Folder"
    return obj
end

function methods.GetFullName(self)
    local parts, cur = {}, self
    while cur do
        table.insert(parts, 1, cur.Name)
        cur = store(cur).parent
    end
    return table.concat(parts, ".")
end

function methods.GetAttribute(self, name)
    return store(self).attrs[name]
end

function methods.SetAttribute(self, name, value)
    store(self).attrs[name] = value
end

function methods.GetAttributes(self)
    local out = {}
    for k, v in pairs(store(self).attrs) do out[k] = v end
    return out
end

function methods.Destroy(self)
    local s = store(self)
    if s.parent then
        local kids = store(s.parent).children
        for i, c in ipairs(kids) do
            if c == self then table.remove(kids, i) break end
        end
        s.parent = nil
    end
    s.destroyed = true
end

function methods.GetPivot(self)
    local p = store(self).Position
    return CFrame.new(p or Vector3.zero)
end

function methods.GetBoundingBox(self)
    return CFrame.new(store(self).Position or Vector3.zero), Vector3.new(4, 6, 4)
end

function methods.SetPrimaryPartCFrame(self, cf) store(self).Position = cf.Position end

ObjMT.__index = function(t, k)
    local s = store(t)
    if k == "Parent" then return s.parent end
    if s[k] ~= nil then return s[k] end
    if methods[k] then return methods[k] end
    if DEFAULTS[k] then return DEFAULTS[k] end
    if k == "Position" then return nil end
    if looksLikeEvent(k) then
        local sig = Signal.new(k)
        s[k] = sig
        return sig
    end
    return nil
end

ObjMT.__newindex = function(t, k, v)
    local s = store(t)
    if k == "Parent" then
        local old = s.parent
        if old then
            local kids = store(old).children
            for i, c in ipairs(kids) do
                if c == t then table.remove(kids, i) break end
            end
        end
        s.parent = v
        if v then table.insert(store(v).children, t) end
    elseif k == "CFrame" and type(v) == "table" and v.Position then
        s.CFrame = v
        s.Position = v.Position       -- so the tests can follow teleports
    else
        s[k] = v
    end
end

ObjMT.__tostring = function(t) return t:GetFullName() end

function World.new(className, parent, name)
    local proxy = {}
    storeOf[proxy] = {
        ClassName = className, Name = name or className,
        children = {}, attrs = {}, parent = nil,
    }
    setmetatable(proxy, ObjMT)
    proxyOf[proxy] = true
    if parent then proxy.Parent = parent end
    return proxy
end

Instance = { new = function(class, parent) return World.new(class, parent) end }

-- ---------------------------------------------------------------- services
local services = {}
local gameObj = World.new("DataModel", nil, "game")
gameObj.PlaceId = 109983668079237
gameObj.JobId = "test-job-id"
function gameObj:GetService(name)
    if not services[name] then
        services[name] = World.new(name, nil, name)
    end
    return services[name]
end
function gameObj:FindService(name) return self:GetService(name) end
game = gameObj

local WorkspaceSvc = gameObj:GetService("Workspace")
workspace = WorkspaceSvc
local Camera = World.new("Camera", WorkspaceSvc, "Camera")
Camera.ViewportSize = { X = 1280, Y = 720 }
WorkspaceSvc.CurrentCamera = Camera

local Players = gameObj:GetService("Players")
local LocalPlayer = World.new("Player", Players, "TestPlayer")
LocalPlayer.UserId = 1
Players.LocalPlayer = LocalPlayer
function Players:GetPlayers() return { LocalPlayer } end
function Players:GetNameForUserIdAsync() return "TestPlayer" end

gameObj:GetService("UserInputService")
gameObj:GetService("TextChatService")
gameObj:GetService("ReplicatedStorage")
gameObj:GetService("StarterGui").SetCore = function() end
gameObj:GetService("ProximityPromptService")
gameObj:GetService("VirtualInputManager").SendMouseButtonEvent = function() end

function WorkspaceSvc:GetServerTimeNow() return 0 end

-- ---------------------------------------------------------------- task
task = {
    wait = function() end,
    spawn = function() end,        -- never start the background loops in tests
    delay = function() end,
    defer = function() end,
    cancel = function() end,
}

World.game = game
World.Workspace = WorkspaceSvc
World.Players = Players
World.LocalPlayer = LocalPlayer
World.Camera = Camera
World.Signal = Signal

-- ---------------------------------------------------------------- helpers
function World.makeCharacter(parent)
    local char = World.new("Model", parent, LocalPlayer.Name)
    local hrp = World.new("Part", char, "HumanoidRootPart")
    hrp.Position = Vector3.new(0, 5, 0)
    local hum = World.new("Humanoid", char, "Humanoid")
    hum.Health = 100
    char.PrimaryPart = hrp
    LocalPlayer.Character = char
    return char
end

function World.reset()
    storeOf[LocalPlayer].attrs = {}
end

return World
