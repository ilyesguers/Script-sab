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

return Sniper
