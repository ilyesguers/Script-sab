--[[ =====================================================================
     STEAL A BRAINROT SUITE  —  for Delta Executor
     ---------------------------------------------------------------------
     Features:
       1. EGG SYSTEM  : ESP (name + rarity + image) , egg filters ,
                        auto farm (teleport -> pick -> return -> hatch)
       2. CODE SNIPER : listens to SpyderSammy's chat , builds the code
                        word-by-word , writes it into the code box ,
                        with a full TEST mode so you can verify it live
       3. EXPLORER    : one-click dumps to discover the real object paths

     UI: mobile friendly (English) - draggable / minimizable / closable

     HOW TO USE:
       - Paste into Delta and Execute.
       - Open the EXPLORER tab and press the dump buttons to learn the
         real paths (send me the output so we tune the script).
       - Test the sniper with the "TEST" buttons (no admin event needed).
     ===================================================================== ]]

--=========================== SERVICES ===========================--
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TextChatService   = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = Workspace.CurrentCamera

--=========================== CONFIG =============================--
local CONFIG = {
    -- Sniper
    SniperEnabled        = true,
    SniperTargetUserId   = 2678001507,          -- SpyderSammy (verified)
    SniperMatchNameToo   = true,                -- also match "sammy" / "spydersammy"
    SniperListenEveryone = false,               -- TEST mode: accept any sender
    SniperSilenceTimeout = 8,                   -- seconds of silence = code finished
    SniperMinLength      = 3,
    SniperAutoSubmit     = false,               -- press Submit automatically (best effort)
    CodeBoxPathOverride  = "",                  -- e.g. "PlayerGui.ScreenGui.Codes.TextBox"
    SniperTypeIndex      = 1,                   -- 1 = Any (auto)
    SniperJoinCode       = true,                -- true = TACOBOOST , false = "TACO BOOST"

    -- Eggs
    EggESPEnabled        = true,
    EggHighlight         = false,
    EggAutoFarm          = false,
    EggWhitelistOn       = false,
    EggWhitelist         = {},                  -- filled from the UI input
    EggMinRarityIndex    = 0,                   -- 0 = any
    EggPickupDelay       = 1.2,                 -- seconds to wait on the egg
    EggReturnDelay       = 2.5,                 -- seconds to wait at the base
}

--=========================== THEME ==============================--
local COLOR_BG    = Color3.fromRGB(24, 26, 34)
local COLOR_BG2   = Color3.fromRGB(34, 37, 48)
local COLOR_BTN   = Color3.fromRGB(46, 50, 64)
local COLOR_ON    = Color3.fromRGB(46, 160, 90)
local COLOR_OFF   = Color3.fromRGB(150, 55, 60)
local COLOR_ACC   = Color3.fromRGB(120, 90, 235)
local COLOR_TEXT  = Color3.fromRGB(235, 238, 245)
local COLOR_DIM   = Color3.fromRGB(140, 145, 160)

--=========================== UTILS ==============================--
local S = math.clamp(math.min(Camera.ViewportSize.X, Camera.ViewportSize.Y) / 700, 0.82, 1.35)

local function notify(title, body)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title or "SaB Suite",
            Text  = body or "",
            Duration = 4,
        })
    end)
end

local function addCorner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = inst
    return c
end

local function getChar()   return LocalPlayer.Character end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getPos(obj)
    if not obj then return nil end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart.Position end
        local ok, p = pcall(function() return obj:GetPivot().Position end)
        if ok and p then return p end
    elseif obj:IsA("BasePart") then
        return obj.Position
    end
    return nil
end

local function teleportTo(pos)
    local hrp = getHRP()
    if not hrp or not pos then return false end
    pcall(function()
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
        hrp.AssemblyLinearVelocity = Vector3.zero
    end)
    return true
end

local function findDescendants(root, pred, limit)
    local out = {}
    if not root then return out end
    for _, d in ipairs(root:GetDescendants()) do
        if pred(d) then
            table.insert(out, d)
            if limit and #out >= limit then break end
        end
    end
    return out
end

--=========================== SNIPER =============================--
-- word-by-word accumulator. Feeds come from chat OR from the TEST panel.
local NUMBER_WORDS = {
    zero = "0", one = "1", two = "2", three = "3", four = "4",
    five = "5", six = "6", seven = "7", eight = "8", nine = "9",
}

local RUNNING = true   -- set to false by the unload button

-- ================= CODE TYPES (Sammy announces the type first) =================
local CODE_TYPES = {
    { name = "Any (auto)",           words = nil, digits = nil  },
    { name = "Letters only",         words = nil, digits = false },
    { name = "Two words",            words = 2,   digits = nil  },
    { name = "Two words + number",   words = 2,   digits = true },
    { name = "Three words",          words = 3,   digits = nil  },
    { name = "Three words + number", words = 3,   digits = true },
    { name = "With numbers (any)",   words = nil, digits = true },
}

local Sniper = {
    collecting  = false,
    tokens      = {},       -- { v = "TACO", kind = "WORD" }
    lastTokenAt = 0,
    lastCode    = "",
    attempted   = {},
    pending     = nil,      -- code waiting for the box to open
    repeatNext  = 1,        -- 2 = next letter doubled, 3 = tripled
    hint         = nil,     -- current type hint { words=n, digits=bool }
    hintFromChat = false,   -- true when Sammy announced the type himself
    armed        = false,   -- type announced -> waiting for the code words
    armedAt      = 0,
    captured     = 0,       -- how many codes captured this session
    logFn       = function() end,
    statusFn    = function() end,
}

local RARITY_COLORS = {
    Common        = Color3.fromRGB(190, 195, 205),
    Rare          = Color3.fromRGB(70, 140, 255),
    Epic          = Color3.fromRGB(165, 80, 235),
    Legendary     = Color3.fromRGB(255, 170, 40),
    Mythic        = Color3.fromRGB(255, 70, 70),
    ["Brainrot God"] = Color3.fromRGB(255, 90, 210),
    Secret        = Color3.fromRGB(255, 45, 45),
    OG            = Color3.fromRGB(90, 220, 130),
    Limited       = Color3.fromRGB(255, 215, 90),
    Unknown       = Color3.fromRGB(160, 160, 160),
}

local function sniperLog(text, color)
    pcall(function() Sniper.logFn(text, color) end)
    print("[SNIPER] " .. text)
end

local function sniperStatus(text, color)
    pcall(function() Sniper.statusFn(text, color) end)
end

local function tokenValues()
    local t = {}
    for _, x in ipairs(Sniper.tokens) do t[#t + 1] = x.v end
    return t
end
local function concatCode()  return table.concat(tokenValues(), "") end
local function spacedCode()  return table.concat(tokenValues(), " ") end
local function finalCode()   return CONFIG.SniperJoinCode and concatCode() or spacedCode() end

-- ================= type hint helpers =================
local function hintFromIndex(i)
    local t = CODE_TYPES[i or CONFIG.SniperTypeIndex or 1]
    if not t then return nil end
    if t.words == nil and t.digits == nil then return nil end
    return { words = t.words, digits = t.digits }
end

local function describeHint(h)
    if not h then return "any (auto)" end
    local parts = {}
    if h.words then table.insert(parts, h.words .. " words") else table.insert(parts, "any length") end
    if h.digits == true then table.insert(parts, "with numbers")
    elseif h.digits == false then table.insert(parts, "no numbers") end
    return table.concat(parts, " + ")
end

-- understand "the code is two words" / "letters and numbers" / "two words + number"
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

-- with a known type we can finish the code instantly (no waiting for silence)
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

-- forward declaration (assigned later)
local tryAutoSubmit = function() end

local function validCode(c)
    return type(c) == "string" and #c >= CONFIG.SniperMinLength and #c <= 40 and c:match("^%w+$") ~= nil
end

-- ---------------- code box discovery ----------------
local function getCodeBox()
    if CONFIG.CodeBoxPathOverride ~= "" then
        local node = PlayerGui
        for part in CONFIG.CodeBoxPathOverride:gmatch("[^%.]+") do
            node = node and node:FindFirstChild(part)
        end
        if node and node:IsA("TextBox") then return node end
    end
    local boxes = findDescendants(PlayerGui, function(d)
        if not d:IsA("TextBox") then return false end
        local ph = (d.PlaceholderText or ""):lower()
        return ph:find("code") ~= nil or d.Name:lower():find("code") ~= nil
    end, 5)
    return boxes[1]
end

local function tryWriteCode(code)
    local box = getCodeBox()
    if box then
        pcall(function()
            box.Text = code
            box.CursorPosition = #code + 1
        end)
        sniperLog(("WRITTEN to code box -> %s"):format(code), COLOR_ON)
        notify("Code Sniper", "Code written: " .. code)
        return true
    end
    Sniper.pending = code
    sniperLog("code box not open yet - saved, will auto-fill when it appears", COLOR_DIM)
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
            sniperStatus("CODE READY: " .. code, COLOR_ON)
            sniperLog(("FINAL code #%d: %s   (spaced form: %s)"):format(Sniper.captured, code, spacedCode()), COLOR_ON)
            if tryWriteCode(code) then
                task.wait(0.1)
                tryAutoSubmit()
            end
        else
            sniperLog("duplicate code ignored: " .. code, COLOR_DIM)
        end
    else
        sniperLog("collected tokens did not form a valid code: '" .. code .. "'", COLOR_OFF)
    end
    -- reset for the next code (Sammy may announce a new type later)
    Sniper.hintFromChat = false
    sniperStatus("Listening...", COLOR_DIM)
end

local function startSession()
    Sniper.collecting  = true
    Sniper.tokens      = {}
    Sniper.repeatNext  = 1
    Sniper.lastTokenAt = tick()
    if not Sniper.hintFromChat then
        Sniper.hint = hintFromIndex(CONFIG.SniperTypeIndex)
    end
    sniperStatus("Collecting... [" .. describeHint(Sniper.hint) .. "]", Color3.fromRGB(255, 190, 60))
    sniperLog("session started - type: " .. describeHint(Sniper.hint), Color3.fromRGB(255, 190, 60))
end

-- feed one raw word (from chat or from the test panel)
local function feedToken(raw)
    if type(raw) ~= "string" or raw == "" then return end
    local low = raw:lower()

    -- "double" / "triple" said on its own -> next letter is repeated
    if low == "double" or low == "dbl" then
        Sniper.repeatNext = 2
        sniperLog('received "double"  ->  next letter will be doubled', COLOR_ACC)
        return
    elseif low == "triple" then
        Sniper.repeatNext = 3
        sniperLog('received "triple"  ->  next letter will be tripled', COLOR_ACC)
        return
    end

    -- "double s" -> SS
    local letter = low:match("^double%s+(%a)$")
    if letter then
        table.insert(Sniper.tokens, { v = letter:upper() .. letter:upper(), kind = "DOUBLE" })
        sniperLog(('received "%s"  ->  DOUBLE  ->  "%s"'):format(raw, letter:upper()..letter:upper()), COLOR_ACC)
    else
        local t = raw:upper():gsub("[^%w]", "")
        if t == "" then
            sniperLog(('received "%s"  ->  IGNORED (not code-like)'):format(raw), COLOR_DIM)
            return
        elseif #t == 1 and t:match("%a") then
            local v = t
            if Sniper.repeatNext and Sniper.repeatNext > 1 then
                v = t:rep(Sniper.repeatNext)
                Sniper.repeatNext = 1
            end
            table.insert(Sniper.tokens, { v = v, kind = "LETTER" })
            sniperLog(('received "%s"  ->  LETTER  ->  "%s"'):format(raw, v), COLOR_TEXT)
        elseif t:match("^%d+$") then
            table.insert(Sniper.tokens, { v = t, kind = "DIGITS" })
            sniperLog(('received "%s"  ->  DIGITS'):format(raw), COLOR_TEXT)
        else
            local num = NUMBER_WORDS[low]
            if num then
                table.insert(Sniper.tokens, { v = num, kind = "NUMBER_WORD" })
                sniperLog(('received "%s"  ->  NUMBER_WORD  ->  "%s"'):format(raw, num), COLOR_TEXT)
            elseif t:match("^%w+$") then
                table.insert(Sniper.tokens, { v = t, kind = "WORD" })
                sniperLog(('received "%s"  ->  WORD'):format(raw), COLOR_TEXT)
            else
                sniperLog(('received "%s"  ->  IGNORED'):format(raw), COLOR_DIM)
                return
            end
        end
    end

    Sniper.lastTokenAt = tick()
    local partial = finalCode()
    sniperStatus("Building: " .. partial, Color3.fromRGB(255, 190, 60))

    -- progressive write: keep the box filled while the code grows
    if validCode(partial) then
        local box = getCodeBox()
        if box then pcall(function() box.Text = partial end) end
    end

    -- when the type is known we finish instantly (fastest possible)
    if shouldComplete() then
        finalizeCode()
    end
end

-- words that often follow "code" when it is NOT a code announcement
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
    if nextWord == nil then return true end            -- message is just "code"
    if nextWord == "is" then return true end           -- "code is ..."
    if NOT_MARKER_NEXT[nextWord] then return false end
    return true                                         -- "code TACO ..." style
end

-- full message handler (chat or test). force=true bypasses the sender filter
local function handleMessage(text, uid, name, force)
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

    -- 1) Sammy announcing the TYPE first: "the code is two words" / "letters and numbers"
    local hint = parseTypeHint(text)
    if hint then
        Sniper.hint         = hint
        Sniper.hintFromChat = true
        Sniper.armed        = true          -- the code words are coming next
        Sniper.armedAt      = tick()
        sniperLog("TYPE announced -> " .. describeHint(hint), COLOR_ACC)
        sniperStatus("Type set: " .. describeHint(hint), COLOR_ACC)
        -- "code is two words: TACO BOOST" -> also collect the part after the colon
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
        local idx  = lower:find("code")
        local rest = text:sub(idx + 4):lower()
        rest = rest:gsub("^%s*", "")
        rest = rest:gsub("^is[%s:]*", "")
        rest = rest:gsub("^[%s:]*", "")
        for w in rest:gmatch("%S+") do feedToken(w) end
        return
    end

    -- 3) armed by a type announcement -> the code words start arriving
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

-- silence watcher (also expires the "armed" state)
task.spawn(function()
    while RUNNING do
        task.wait(0.25)
        if Sniper.armed and not Sniper.collecting and (tick() - Sniper.armedAt) > 120 then
            Sniper.armed        = false
            Sniper.hintFromChat = false
            sniperLog("type announcement expired - back to listening", COLOR_DIM)
        end
        if Sniper.collecting and (tick() - Sniper.lastTokenAt) > CONFIG.SniperSilenceTimeout then
            finalizeCode()
        end
    end
end)

-- chat hooks
if TextChatService then
    TextChatService.MessageReceived:Connect(function(msg)
        pcall(function()
            local ts = msg.TextSource
            handleMessage(msg.Text or "", ts and ts.UserId, ts and ts.Name)
        end)
    end)
    pcall(function()
        TextChatService.SendingMessage:Connect(function(msg)
            local ts = msg.TextSource
            handleMessage(msg.Text or "", ts and ts.UserId, ts and ts.Name)
        end)
    end)
end
-- legacy fallback
local function hookLegacy(p)
    pcall(function()
        p.Chatted:Connect(function(text) handleMessage(text, p.UserId, p.Name) end)
    end)
end
for _, p in ipairs(Players:GetPlayers()) do hookLegacy(p) end
Players.PlayerAdded:Connect(hookLegacy)

-- auto-fill when the code box finally opens
PlayerGui.DescendantAdded:Connect(function(d)
    if Sniper.pending and d:IsA("TextBox") then
        local ph = (d.PlaceholderText or ""):lower()
        if ph:find("code") or d.Name:lower():find("code") then
            task.wait(0.15)
            pcall(function() d.Text = Sniper.pending end)
            sniperLog("auto-filled the code box with: " .. Sniper.pending, COLOR_ON)
            Sniper.pending = nil
        end
    end
end)

-- best-effort auto submit
function tryAutoSubmit()
    if not CONFIG.SniperAutoSubmit then return end
    local box = getCodeBox()
    if not box then return end
    local btn = nil
    for _, d in ipairs(box.Parent:GetDescendants()) do
        if d:IsA("GuiButton") and d.Name:lower():find("submit") then btn = d break end
    end
    if not btn then
        for _, d in ipairs(PlayerGui:GetDescendants()) do
            if d:IsA("GuiButton") and d.Name:lower():find("submit") then btn = d break end
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
        sniperLog("auto-submit pressed", COLOR_ON)
    end)
end

--=========================== EGGS ==============================--
local RARITY_ORDER = { "Common","Rare","Epic","Legendary","Mythic","Brainrot God","Secret","OG","Limited" }
local RARITY_TIER  = {}
for i, r in ipairs(RARITY_ORDER) do RARITY_TIER[r] = i end

local Eggs = {
    active  = {},   -- [obj] = {billboard=, highlight=}
    lastScan = 0,
    foundList = {},
}

local function isEggObj(d)
    if not (d:IsA("Model") or d:IsA("BasePart")) then return false end
    return d.Name:lower():find("egg") ~= nil
end

local function detectRarity(egg)
    for _, k in ipairs({ "Rarity", "rarity", "EggRarity" }) do
        local v = egg:GetAttribute(k)
        if typeof(v) == "string" and v ~= "" then return v end
    end
    for _, c in ipairs(egg:GetDescendants()) do
        if c:IsA("StringValue") and c.Name:lower():find("rarity") then
            if c.Value ~= "" then return c.Value end
        end
    end
    return "Unknown"
end

local function findEggIcon(egg)
    for _, d in ipairs(egg:GetDescendants()) do
        if (d:IsA("Decal") or d:IsA("Texture")) and d.Texture ~= "" then return d.Texture end
        if d:IsA("ImageLabel") and d.Image ~= "" then return d.Image end
    end
    return nil
end

local function scanEggs()
    local list = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if isEggObj(d) then
            local pos = getPos(d)
            if pos then
                table.insert(list, {
                    obj    = d,
                    name   = d.Name,
                    pos    = pos,
                    rarity = detectRarity(d),
                    icon   = findEggIcon(d),
                })
            end
        end
    end
    return list
end

local function passesFilter(e)
    if CONFIG.EggWhitelistOn and #CONFIG.EggWhitelist > 0 then
        local ok = false
        for _, w in ipairs(CONFIG.EggWhitelist) do
            if w ~= "" and e.name:lower():find(w:lower(), 1, true) then ok = true break end
        end
        if not ok then return false end
    end
    if CONFIG.EggMinRarityIndex > 0 then
        local tier = RARITY_TIER[e.rarity] or 0
        if tier < CONFIG.EggMinRarityIndex then return false end
    end
    return true
end

local function destroyESP(e)
    local rec = Eggs.active[e.obj]
    if rec then
        if rec.billboard then pcall(function() rec.billboard:Destroy() end) end
        if rec.highlight then pcall(function() rec.highlight:Destroy() end) end
        Eggs.active[e.obj] = nil
    end
end

local function createESP(e)
    if Eggs.active[e.obj] then return end
    local part = e.obj:IsA("BasePart") and e.obj or e.obj:FindFirstChildWhichIsA("BasePart")
    if not part then return end
    local col = RARITY_COLORS[e.rarity] or RARITY_COLORS.Unknown

    local bb = Instance.new("BillboardGui")
    bb.Name = "SaB_EggESP"
    bb.Size = UDim2.new(0, 150 * S, 0, 46 * S)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = false
    bb.MaxDistance = 900
    bb.Parent = part

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13 * S
    lbl.TextColor3 = col
    lbl.TextStrokeTransparency = 0.4
    lbl.Size = UDim2.new(1, 0, 0, 18 * S)
    lbl.Text = e.name
    lbl.Parent = bb

    local rar = Instance.new("TextLabel")
    rar.BackgroundTransparency = 1
    rar.Font = Enum.Font.Gotham
    rar.TextSize = 11 * S
    rar.TextColor3 = col
    rar.TextStrokeTransparency = 0.5
    rar.Position = UDim2.new(0, 0, 0, 17 * S)
    rar.Size = UDim2.new(1, 0, 0, 14 * S)
    rar.Text = e.rarity
    rar.Parent = bb

    local rec = { billboard = bb }
    if e.icon then
        local img = Instance.new("ImageLabel")
        img.BackgroundTransparency = 1
        img.Size = UDim2.new(0, 34 * S, 0, 34 * S)
        img.Position = UDim2.new(0.5, -17 * S, 0, 20 * S)
        img.Image = e.icon
        img.Parent = bb
        bb.Size = UDim2.new(0, 150 * S, 0, 62 * S)
        rec.icon = img
    end

    if CONFIG.EggHighlight then
        local h = Instance.new("Highlight")
        h.FillColor = col
        h.FillTransparency = 0.75
        h.OutlineColor = col
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Adornee = e.obj
        h.Parent = bb
        rec.highlight = h
    end
    Eggs.active[e.obj] = rec
end

local function refreshESP()
    local list = scanEggs()
    local seen = {}
    for _, e in ipairs(list) do
        seen[e.obj] = true
        if CONFIG.EggESPEnabled then createESP(e) end
    end
    for obj in pairs(Eggs.active) do
        if not seen[obj] or not CONFIG.EggESPEnabled then destroyESP({ obj = obj }) end
    end
    Eggs.foundList = list
    return list
end

-- base position
local function getBasePos()
    local plot = Workspace:FindFirstChild(LocalPlayer.Name)
    local p = getPos(plot)
    if p then return p end
    local bases = Workspace:FindFirstChild("Bases") or Workspace:FindFirstChild("Plots")
    if bases then
        p = getPos(bases:FindFirstChild(LocalPlayer.Name))
        if p then return p end
    end
    local cf = LocalPlayer:GetAttribute("BaseCFrame")
    if typeof(cf) == "CFrame" then return cf.Position end
    return nil
end

local function isCarrying()
    local c = getChar()
    if c then
        for _, d in ipairs(c:GetDescendants()) do
            local n = d.Name:lower()
            if n:find("egg") or n:find("carry") or n:find("hold") then return true end
        end
    end
    for k, v in pairs(LocalPlayer:GetAttributes()) do
        if tostring(k):lower():find("carry") and v then return true end
    end
    return false
end

-- try to pick an egg up: proximity prompt first, then teleport-touch
local function tryPickup(e)
    local prompt = nil
    pcall(function()
        for _, d in ipairs(e.obj:GetDescendants()) do
            if d:IsA("ProximityPrompt") then prompt = d break end
        end
    end)
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.4)
        if isCarrying() then return true end
    end
    teleportTo(e.pos)
    task.wait(CONFIG.EggPickupDelay)
    return isCarrying()
end

-- full farm cycle for one egg: pick -> return to base -> hatch
local function farmEggOnce(e)
    farmStatusFn("farming: " .. e.name .. " [" .. e.rarity .. "]")
    local got = tryPickup(e)
    if not got then
        teleportTo(e.pos + Vector3.new(0, 2, 0))
        task.wait(0.4)
        got = tryPickup(e)
    end
    if not got then
        farmStatusFn("could not pick up: " .. e.name)
        return false
    end
    local bp = getBasePos()
    if not bp then
        farmStatusFn("picked up, but base was not found")
        return false
    end
    teleportTo(bp)
    task.wait(CONFIG.EggReturnDelay)
    farmStatusFn("delivered: " .. e.name)
    return true
end

local farmStatusFn = function() end

local function pickFarmTarget(list)
    local best, bestTier, bestDist = nil, -1, math.huge
    local hrp = getHRP()
    for _, e in ipairs(list) do
        if passesFilter(e) then
            local tier = RARITY_TIER[e.rarity] or 0
            local dist = hrp and (hrp.Position - e.pos).Magnitude or 0
            if tier > bestTier or (tier == bestTier and dist < bestDist) then
                best, bestTier, bestDist = e, tier, dist
            end
        end
    end
    return best
end

-- background loop: ESP refresh + auto farm (throttled, only when needed)
task.spawn(function()
    while RUNNING do
        task.wait(0.5)
        pcall(function()
            if not (CONFIG.EggESPEnabled or CONFIG.EggAutoFarm) then return end
            if (tick() - Eggs.lastScan) < 1 then return end
            Eggs.lastScan = tick()

            local list = scanEggs()
            Eggs.foundList = list
            local seen = {}
            for _, e in ipairs(list) do
                seen[e.obj] = true
                if CONFIG.EggESPEnabled then createESP(e) end
            end
            for obj in pairs(Eggs.active) do
                if (not seen[obj]) or (not CONFIG.EggESPEnabled) then destroyESP({ obj = obj }) end
            end

            if CONFIG.EggAutoFarm then
                local t = pickFarmTarget(list)
                if t then
                    farmEggOnce(t)
                else
                    farmStatusFn("no matching egg found")
                end
            end
        end)
    end
end)

--=========================== UI ================================--
local function uiParent()
    local ok, res = pcall(function()
        if typeof(gethui) == "function" then return gethui() end
    end)
    if ok and res then return res end
    return PlayerGui
end

local gui = Instance.new("ScreenGui")
gui.Name = "SaBSuite"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = uiParent()

local W = math.clamp(Camera.ViewportSize.X * 0.92, 310, 560)
local H = math.clamp(Camera.ViewportSize.Y * 0.78, 400, 640)

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(W, H)
main.Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2)
main.BackgroundColor3 = COLOR_BG
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
addCorner(main, 14)

local stroke = Instance.new("UIStroke")
stroke.Color = COLOR_ACC
stroke.Thickness = 1.5
stroke.Transparency = 0.6
stroke.Parent = main

-- header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40 * S)
header.BackgroundColor3 = COLOR_BG2
header.BorderSizePixel = 0
header.Active = true
header.Parent = main
addCorner(header, 14)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 15 * S
title.TextColor3 = COLOR_TEXT
title.Text = "  Steal a Brainrot Suite"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Size = UDim2.new(1, -90 * S, 1, 0)
title.Parent = header

local function headerBtn(text, x, color)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = color or COLOR_BTN
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14 * S
    b.TextColor3 = COLOR_TEXT
    b.Text = text
    b.Size = UDim2.fromOffset(30 * S, 26 * S)
    b.Position = UDim2.new(1, x, 0.5, -13 * S)
    b.Parent = header
    addCorner(b, 8)
    return b
end

local minimized = false
local minBtn = headerBtn("–", -78 * S)
local closeBtn = headerBtn("✕", -40 * S)

minBtn.Activated:Connect(function()
    minimized = not minimized
    for _, c in ipairs(main:GetChildren()) do
        if c ~= header and c ~= stroke then c.Visible = not minimized end
    end
    main.Size = minimized and UDim2.fromOffset(W, 40 * S) or UDim2.fromOffset(W, H)
    minBtn.Text = minimized and "+" or "–"
end)

-- floating reopen button (created BEFORE closeBtn so the closure can see it)
local reopen = Instance.new("TextButton")
reopen.Size = UDim2.fromOffset(46 * S, 46 * S)
reopen.Position = UDim2.new(0, 12 * S, 0.5, -23 * S)
reopen.BackgroundColor3 = COLOR_ACC
reopen.Font = Enum.Font.GothamBold
reopen.TextSize = 18 * S
reopen.TextColor3 = COLOR_TEXT
reopen.Text = "☰"
reopen.Visible = false
reopen.Parent = gui
addCorner(reopen, 12)
reopen.Activated:Connect(function()
    gui.Enabled = true
    reopen.Visible = false
end)

closeBtn.Activated:Connect(function()
    gui.Enabled = false
    reopen.Visible = true
end)

-- drag (mouse + touch)
do
    local dragging, dragStart, startPos = false, nil, nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
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

-- tabs
local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, 0, 0, 34 * S)
tabRow.Position = UDim2.new(0, 0, 0, 40 * S)
tabRow.BackgroundTransparency = 1
tabRow.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6 * S)
tabLayout.Parent = tabRow

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -12 * S, 1, -(40 + 34 + 10) * S)
content.Position = UDim2.new(0, 6 * S, 0, (40 + 34 + 6) * S)
content.BackgroundTransparency = 1
content.Parent = main

local pages = {}
local function newPage(name)
    local sf = Instance.new("ScrollingFrame")
    sf.Name = name
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 4
    sf.ScrollBarImageColor3 = COLOR_ACC
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Visible = false
    sf.Parent = content
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 6 * S)
    l.Parent = sf
    pages[name] = sf
    return sf
end

local tabButtons = {}
local function addTab(name)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = COLOR_BTN
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13 * S
    b.TextColor3 = COLOR_TEXT
    b.Text = name
    b.Size = UDim2.new(1, -6 * S, 1, 0)
    b.Parent = tabRow
    addCorner(b, 8)
    b.Activated:Connect(function()
        for n, page in pairs(pages) do page.Visible = (n == name) end
        for n, btn in pairs(tabButtons) do
            btn.BackgroundColor3 = (n == name) and COLOR_ACC or COLOR_BTN
        end
    end)
    tabButtons[name] = b
    return newPage(name)
end

-- widget helpers (parented into a page)
local function mkLabel(parent, text, color)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.Gotham
    l.TextSize = 13 * S
    l.TextColor3 = color or COLOR_TEXT
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Size = UDim2.new(1, 0, 0, 0)
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.Text = text
    l.Parent = parent
    return l
end

local function mkButton(parent, text, cb, h)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = COLOR_BTN
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13 * S
    b.TextColor3 = COLOR_TEXT
    b.Text = text
    b.AutoButtonColor = true
    b.Size = UDim2.new(1, 0, 0, h or 34 * S)
    b.Parent = parent
    addCorner(b, 8)
    b.Activated:Connect(function() pcall(cb) end)
    return b
end

local function mkToggle(parent, label, default, cb)
    local b = Instance.new("TextButton")
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13 * S
    b.TextColor3 = COLOR_TEXT
    b.AutoButtonColor = true
    b.Size = UDim2.new(1, 0, 0, 34 * S)
    b.Parent = parent
    addCorner(b, 8)
    local on = default
    local function render()
        b.Text = label .. ":   " .. (on and "ON" or "OFF")
        b.BackgroundColor3 = on and COLOR_ON or COLOR_OFF
    end
    b.Activated:Connect(function()
        on = not on
        render()
        pcall(cb, on)
    end)
    render()
    return b
end

local function mkInput(parent, placeholder, default)
    local t = Instance.new("TextBox")
    t.PlaceholderText = placeholder
    t.Text = default or ""
    t.Font = Enum.Font.Gotham
    t.TextSize = 13 * S
    t.TextColor3 = COLOR_TEXT
    t.PlaceholderColor3 = COLOR_DIM
    t.BackgroundColor3 = COLOR_BG2
    t.ClearTextOnFocus = false
    t.Size = UDim2.new(1, 0, 0, 32 * S)
    t.Parent = parent
    addCorner(t, 8)
    return t
end

local function mkLog(parent, lines)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 0, lines or 150 * S)
    sf.BackgroundColor3 = COLOR_BG2
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 4
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Parent = parent
    addCorner(sf, 8)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 2)
    l.Parent = sf

    local function addLine(text, color)
        local lb = Instance.new("TextLabel")
        lb.BackgroundTransparency = 1
        lb.Font = Enum.Font.Code
        lb.TextSize = 11 * S
        lb.TextWrapped = true
        lb.TextColor3 = color or COLOR_TEXT
        lb.TextXAlignment = Enum.TextXAlignment.Left
        lb.Size = UDim2.new(1, -10, 0, 0)
        lb.AutomaticSize = Enum.AutomaticSize.Y
        lb.Text = tostring(text)
        lb.Parent = sf
        local labels = {}
        for _, c in ipairs(sf:GetChildren()) do
            if c:IsA("TextLabel") then table.insert(labels, c) end
        end
        if #labels > 140 then labels[1]:Destroy() end
        task.defer(function()
            pcall(function() sf.CanvasPosition = Vector2.new(0, sf.AbsoluteCanvasSize.Y) end)
        end)
    end

    local function clearLines()
        for _, c in ipairs(sf:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
    end

    return sf, addLine, clearLines
end

--=========================== PAGE: EGGS ========================--
local eggPage = addTab("Eggs")

mkLabel(eggPage, "EGG SYSTEM  —  ESP / filter / auto farm", COLOR_ACC)
mkToggle(eggPage, "Egg ESP", CONFIG.EggESPEnabled, function(v)
    CONFIG.EggESPEnabled = v
    if not v then for obj in pairs(Eggs.active) do destroyESP({ obj = obj }) end end
end)
mkToggle(eggPage, "Highlight boxes", CONFIG.EggHighlight, function(v)
    CONFIG.EggHighlight = v
end)
mkToggle(eggPage, "Whitelist only (use list below)", CONFIG.EggWhitelistOn, function(v)
    CONFIG.EggWhitelistOn = v
end)
local whitelistInput = mkInput(eggPage, "Desired eggs, comma separated (e.g. Dragon, Divine, Heavenly)", "")
mkButton(eggPage, "Save whitelist", function()
    CONFIG.EggWhitelist = {}
    for w in whitelistInput.Text:gmatch("[^,]+") do
        local s = w:gsub("^%s+", ""):gsub("%s+$", "")
        if s ~= "" then table.insert(CONFIG.EggWhitelist, s) end
    end
    notify("Eggs", "Whitelist saved (" .. #CONFIG.EggWhitelist .. ")")
end)

local rarityIdx = CONFIG.EggMinRarityIndex
local rarityBtn = mkButton(eggPage, "Min rarity:  ANY", function()
    rarityIdx = rarityIdx + 1
    if rarityIdx > #RARITY_ORDER then rarityIdx = 0 end
    CONFIG.EggMinRarityIndex = rarityIdx
    rarityBtn.Text = (rarityIdx == 0) and "Min rarity:  ANY" or ("Min rarity:  " .. RARITY_ORDER[rarityIdx])
end)

mkToggle(eggPage, "Auto farm eggs", CONFIG.EggAutoFarm, function(v)
    CONFIG.EggAutoFarm = v
    if not v then farmStatusFn("idle") end
end)
local farmStatus = mkLabel(eggPage, "farm: idle", COLOR_DIM)
farmStatusFn = function(t) pcall(function() farmStatus.Text = "farm: " .. t end) end

mkButton(eggPage, "Farm nearest matching egg (once)", function()
    local list = refreshESP()
    local t = pickFarmTarget(list)
    if not t then notify("Eggs", "No matching egg found") return end
    task.spawn(function()
        pcall(function()
            farmEggOnce(t)
            task.wait(0.3)
            farmStatusFn("idle")
        end)
    end)
end)

mkLabel(eggPage, "— EGG LIST —", COLOR_ACC)
local eggListFrame, eggListLine, eggListClear = mkLog(eggPage, 130 * S)
mkButton(eggPage, "Refresh egg list", function()
    eggListClear()
    local list = refreshESP()
    eggListLine("eggs found: " .. #list, COLOR_ACC)
    for _, e in ipairs(list) do
        eggListLine(("  %s  [%s]  icon=%s"):format(e.name, e.rarity, e.icon and "yes" or "no"),
                RARITY_COLORS[e.rarity] or COLOR_TEXT)
    end
end)

--=========================== PAGE: SNIPER ======================--
local sniperPage = addTab("Code Sniper")

mkLabel(sniperPage, "CODE SNIPER  —  listens to SpyderSammy, builds the code word by word", COLOR_ACC)

local targetName = "SpyderSammy"
task.spawn(function()
    pcall(function()
        local ok, name = pcall(function()
            return Players:GetNameForUserIdAsync(CONFIG.SniperTargetUserId)
        end)
        if ok and name then targetName = name end
    end)
end)

local sniperStatusLbl = mkLabel(sniperPage, "status: listening...", COLOR_DIM)
Sniper.statusFn = function(t, c)
    pcall(function()
        sniperStatusLbl.Text = ("status: %s\n|  type: %s  |  codes captured: %d"):format(
            t, describeHint(Sniper.hint), Sniper.captured)
        sniperStatusLbl.TextColor3 = c
    end)
end

mkToggle(sniperPage, "Sniper enabled", CONFIG.SniperEnabled, function(v) CONFIG.SniperEnabled = v end)
mkToggle(sniperPage, "TEST: listen to everyone", CONFIG.SniperListenEveryone, function(v)
    CONFIG.SniperListenEveryone = v
    if v then notify("Sniper TEST", "Now type in chat: code is TACO BOOST 123") end
end)
mkToggle(sniperPage, "Auto press Submit", CONFIG.SniperAutoSubmit, function(v)
    CONFIG.SniperAutoSubmit = v
    if v then notify("Sniper", "Auto-submit ON (best effort)") end
end)

-- ===== code type selector (Sammy announces the type before the code) =====
mkLabel(sniperPage, "CODE TYPE  (choose it, or the sniper reads it from Sammy)", COLOR_ACC)
local typeBtn = mkButton(sniperPage, "Type:  " .. CODE_TYPES[CONFIG.SniperTypeIndex].name, function()
    CONFIG.SniperTypeIndex = CONFIG.SniperTypeIndex + 1
    if CONFIG.SniperTypeIndex > #CODE_TYPES then CONFIG.SniperTypeIndex = 1 end
    typeBtn.Text = "Type:  " .. CODE_TYPES[CONFIG.SniperTypeIndex].name
    Sniper.hint = hintFromIndex(CONFIG.SniperTypeIndex)
    Sniper.hintFromChat = false
    sniperLog("type set manually -> " .. describeHint(Sniper.hint), COLOR_ACC)
end)

local fmtBtn = mkButton(sniperPage, "Format:  JOINED (TACOBOOST)", function()
    CONFIG.SniperJoinCode = not CONFIG.SniperJoinCode
    fmtBtn.Text = CONFIG.SniperJoinCode and "Format:  JOINED (TACOBOOST)" or 'Format:  SPACED ("TACO BOOST")'
end)

-- ===== MANUAL START (بدا) =====
local startBtn = mkButton(sniperPage, "▶  START capturing  (بدا)", function()
    Sniper.hintFromChat = false
    startSession()
    notify("Sniper", "capturing started - say the code!")
end, 42 * S)
startBtn.BackgroundColor3 = COLOR_ON
mkButton(sniperPage, "■  STOP capturing", function()
    finalizeCode()
end)

local timeoutInput = mkInput(sniperPage, "Silence timeout (seconds)", tostring(CONFIG.SniperSilenceTimeout))
mkButton(sniperPage, "Save timeout", function()
    local n = tonumber(timeoutInput.Text)
    if n and n >= 1 and n <= 60 then
        CONFIG.SniperSilenceTimeout = n
        notify("Sniper", "Timeout = " .. n .. "s")
    end
end)

local boxPathInput = mkInput(sniperPage, "Code box path override (optional)", CONFIG.CodeBoxPathOverride)
mkButton(sniperPage, "Save code box path", function()
    CONFIG.CodeBoxPathOverride = boxPathInput.Text
    notify("Sniper", "Path saved: " .. (boxPathInput.Text ~= "" and boxPathInput.Text or "auto-detect"))
end)

mkLabel(sniperPage, "— TEST ZONE (no admin event needed) —", Color3.fromRGB(255, 190, 60))
local testInput = mkInput(sniperPage, "type a word here (e.g. TACO)", "")
mkButton(sniperPage, "1) Feed this word", function()
    local w = testInput.Text
    if w == "" then return end
    testInput.Text = ""
    handleMessage(w, LocalPlayer.UserId, LocalPlayer.Name, true)   -- force = bypass sender filter
end)
mkButton(sniperPage, "2) Start session (marker)", function()
    handleMessage("code is", LocalPlayer.UserId, LocalPlayer.Name, true)
end)
mkButton(sniperPage, "3) DEMO: two words", function()
    task.spawn(function()
        local seq = { "the code is two words", "TACO", "BOOST" }
        for _, w in ipairs(seq) do
            handleMessage(w, LocalPlayer.UserId, LocalPlayer.Name, true)
            task.wait(0.8)
        end
        notify("Sniper TEST", "demo finished - check the log")
    end)
end)
mkButton(sniperPage, "3b) DEMO: words + numbers", function()
    task.spawn(function()
        local seq = { "the code is letters and numbers", "TACO", "BOOST", "123" }
        for _, w in ipairs(seq) do
            handleMessage(w, LocalPlayer.UserId, LocalPlayer.Name, true)
            task.wait(0.8)
        end
        notify("Sniper TEST", "demo finished - check the log")
    end)
end)
mkButton(sniperPage, "4) Force finish now", function() finalizeCode() end)

local sniperLogFrame, sniperLogLine = mkLog(sniperPage, 200 * S)
Sniper.logFn = sniperLogLine
sniperLogLine("sniper ready - target: " .. targetName .. " (id " .. CONFIG.SniperTargetUserId .. ")", COLOR_ACC)
sniperLogLine("waiting for a marker ('code is') or a type announcement ...", COLOR_DIM)
sniperLogLine("tip: pick the CODE TYPE above, or let the sniper read it from Sammy", COLOR_DIM)

--=========================== PAGE: EXPLORER ====================--
local expPage = addTab("Explorer")

mkLabel(expPage, "EXPLORER  —  dump the real object paths (send me the output)", COLOR_ACC)
local expLogFrame, expLog = mkLog(expPage, 260 * S)

local function dump(titleText, items)
    expLog("=== " .. titleText .. " (" .. #items .. ") ===", COLOR_ACC)
    for _, s in ipairs(items) do expLog("  " .. s, COLOR_TEXT) end
    print("=== " .. titleText .. " ===")
    for _, s in ipairs(items) do print("  " .. s) end
end

mkButton(expPage, "Dump TextBoxes (open Codes menu first)", function()
    local items = {}
    for _, d in ipairs(PlayerGui:GetDescendants()) do
        if d:IsA("TextBox") then
            table.insert(items, d:GetFullName() .. "   |   ph='" .. tostring(d.PlaceholderText) .. "'")
        end
    end
    dump("TEXTBOXES", items)
end)

mkButton(expPage, "Dump GuiButtons (submit / codes)", function()
    local items = {}
    for _, d in ipairs(PlayerGui:GetDescendants()) do
        if d:IsA("GuiButton") then
            local n = d.Name:lower()
            if n:find("submit") or n:find("code") or n:find("redeem") then
                table.insert(items, d:GetFullName() .. "   |   text='" .. tostring(d.Text) .. "'")
            end
        end
    end
    dump("BUTTONS", items)
end)

mkButton(expPage, "Dump Eggs in Workspace", function()
    local items = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if (d:IsA("Model") or d:IsA("BasePart")) and d.Name:lower():find("egg") then
            local kids = {}
            for _, c in ipairs(d:GetChildren()) do table.insert(kids, c.Name .. "(" .. c.ClassName .. ")") end
            table.insert(items, d:GetFullName() .. "  " .. d.ClassName .. "  children: " .. table.concat(kids, ", "))
        end
    end
    dump("EGGS", items)
end)

mkButton(expPage, "Dump Bases / Plots", function()
    local items = {}
    for _, n in ipairs({ "Bases", "Plots", LocalPlayer.Name }) do
        local o = Workspace:FindFirstChild(n)
        if o then
            table.insert(items, o:GetFullName() .. "  " .. o.ClassName)
            for _, c in ipairs(o:GetChildren()) do
                table.insert(items, "    " .. c.Name .. " (" .. c.ClassName .. ")")
            end
        end
    end
    dump("BASES", items)
end)

mkButton(expPage, "Dump Remotes", function()
    local items = {}
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
            table.insert(items, d:GetFullName())
        end
    end
    dump("REMOTES", items)
end)

mkButton(expPage, "Dump chat info", function()
    local items = {}
    table.insert(items, "TextChatService = " .. tostring(TextChatService ~= nil))
    if TextChatService then
        pcall(function() table.insert(items, "ChatVersion = " .. tostring(TextChatService.ChatVersion)) end)
        local chans = TextChatService:FindFirstChild("TextChannels")
        if chans then
            for _, c in ipairs(chans:GetChildren()) do
                table.insert(items, "channel: " .. c.Name)
            end
        end
    end
    table.insert(items, "LocalPlayer = " .. LocalPlayer.Name .. " (" .. tostring(LocalPlayer.UserId) .. ")")
    dump("CHAT", items)
end)

--=========================== PAGE: SETTINGS ====================--
local setPage = addTab("Settings")
mkLabel(setPage, "SETTINGS", COLOR_ACC)
mkButton(setPage, "Reset window position", function()
    main.Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2)
end)
mkButton(setPage, "Re-center + reopen", function()
    gui.Enabled = true
    reopen.Visible = false
    main.Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2)
end)
mkButton(setPage, "UNLOAD script (close UI + stop loops)", function()
    RUNNING = false
    CONFIG.EggAutoFarm = false
    CONFIG.EggESPEnabled = false
    CONFIG.SniperEnabled = false
    for obj in pairs(Eggs.active) do destroyESP({ obj = obj }) end
    gui:Destroy()
    notify("SaB Suite", "unloaded")
end)
mkLabel(setPage, "Tip: press the dump buttons in Explorer while inside the game,\nthen send me the output so we can hard-code the real paths.", COLOR_DIM)

-- initial state
pages["Eggs"].Visible = true
tabButtons["Eggs"].BackgroundColor3 = COLOR_ACC

notify("SaB Suite", "loaded - open the Explorer tab and dump the paths!")
print("[SaB Suite] loaded. Explorer tab -> press dump buttons.")
