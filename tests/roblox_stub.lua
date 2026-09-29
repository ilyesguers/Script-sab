-- Minimal Roblox environment so the pure parts of the script can be
-- loaded (and unit tested) by a plain Lua interpreter.
-- This file is ONLY used by tests/run_tests.py - never shipped to Delta.

local function isCallable(v)
    return type(v) == "function"
end

local function newInstance(name, className)
    local inst
    inst = {
        Name = name or "Instance",
        ClassName = className or name or "Instance",
        Parent = nil,
        IsA = function(_, c) return c == (className or name) end,
        FindFirstChild = function() return nil end,
        FindFirstChildOfClass = function() return nil end,
        FindFirstChildWhichIsA = function() return nil end,
        FindFirstAncestorWhichIsA = function() return nil end,
        WaitForChild = function(_, n) return newInstance(n, n) end,
        GetChildren = function() return {} end,
        GetDescendants = function() return {} end,
        GetAttributes = function() return {} end,
        GetAttribute = function() return nil end,
        GetFullName = function() return name or "Instance" end,
        GetService = function(_, n) return newInstance(n, n) end,
    }
    return inst
end

local function newService(name)
    local svc = newInstance(name, name)
    if name == "Players" then
        svc.LocalPlayer = newInstance("TestPlayer", "Player")
        svc.LocalPlayer.UserId = 1
        svc.GetPlayers = function() return { svc.LocalPlayer } end
        svc.GetNameForUserIdAsync = function() return "TestPlayer" end
    end
    return svc
end

game = newInstance("game", "DataModel")
game.GetService = function(_, n) return newService(n) end
game.FindService = game.GetService

workspace = newService("Workspace")

Color3 = {}
Color3.fromRGB = function(r, g, b) return { r = r, g = g, b = b, __color = true } end
Color3.new = function(r, g, b) return { r = r, g = g, b = b, __color = true } end

Vector3 = { zero = { X = 0, Y = 0, Z = 0 } }
Vector3.new = function(x, y, z) return { X = x or 0, Y = y or 0, Z = z or 0, __vector = true } end

CFrame = {}
CFrame.new = function(...) return { __cframe = true } end

Instance = { new = function(c) return newInstance(c, c) end }

task = {
    wait = function() end,
    spawn = function(fn) if isCallable(fn) then fn() end end,
    delay = function() end,
    defer = function(fn) if isCallable(fn) then fn() end end,
}

typeof = function(v)
    if type(v) == "table" and v.__color then return "Color3" end
    if type(v) == "table" and v.__vector then return "Vector3" end
    if type(v) == "table" and v.__cframe then return "CFrame" end
    return type(v)
end

Enum = setmetatable({}, {
    __index = function(_, k) return setmetatable({}, { __index = function(_, v) return k .. "." .. v end }) end,
})

return true
