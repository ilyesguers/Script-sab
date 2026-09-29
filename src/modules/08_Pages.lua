--==============================================================
--  PAGES  (Eggs · Code Sniper · Diagnostics · Settings)
--
--  The Eggs tab is built to answer three questions instantly:
--     1. how many eggs did we find, and HOW did we find them?
--     2. which ones pass my filters right now?
--     3. what is the farm doing at this second?
--==============================================================

local Util    = SaB.Util
local CONFIG  = SaB.CONFIG
local Rarity  = SaB.Rarity
local EggDB   = SaB.EggDB
local Scanner = SaB.Scanner
local Farm    = SaB.Farm
local Sniper  = SaB.Sniper
local UI      = SaB.UI
local T       = SaB.Theme
local s       = UI.s

local Workspace = SaB.Services.Workspace

local Pages = {}
SaB.Pages = Pages

--==============================================================
--  PAGE 1 : EGGS
--==============================================================
local eggPage = UI.addTab("Eggs")

local eggLogFrame, eggLog, eggLogClear

-- ---------------- STATUS ----------------
local statusSection = UI.section(eggPage, "Status", T.ACC)
local statusLabel = UI.label(statusSection, "detected 0   •   matching 0   •   delivered 0",
    T.TEXT, { bold = true })
local statusLine = UI.label(statusSection, "farm: idle", T.DIM)
local detectLine = UI.label(statusSection, "scan: -", T.DIM, { size = 10 })

-- ---------------- DETECTION ----------------
local detSection = UI.section(eggPage, "Detection", Color3.fromRGB(90, 200, 255))
UI.toggle(detSection, "EGG ESP (labels)", CONFIG.EggESPEnabled, function(v)
    CONFIG.EggESPEnabled = v
    if not v then SaB.ESP.clear() end
end)
UI.toggle(detSection, "Glow box around eggs", CONFIG.EggHighlight, function(v)
    CONFIG.EggHighlight = v
end)
UI.toggle(detSection, "See eggs through walls", CONFIG.EggAlwaysOnTop, function(v)
    CONFIG.EggAlwaysOnTop = v
    SaB.ESP.rebuild()
end)
UI.toggle(detSection, "Watch for new eggs (live scan)", CONFIG.EggLiveScan, function(v)
    CONFIG.EggLiveScan = v
end)
do
    local row = UI.row(detSection, 30)
    UI.button(row, "DEEP SCAN NOW", function()
        UI.toastShow("scanning the whole map...", T.ACC, 2)
        local added = Scanner.deepScan(false)
        UI.toastShow(("scan done - %d eggs tracked"):format(Util.tableCount(Scanner.eggs)), T.OK, 2)
        eggLog(("deep scan: +%d new (see console)"):format(added), T.ACC)
    end, { width = 0.5, color = T.ACC })
    UI.button(row, "REBUILD LABELS", function()
        SaB.ESP.rebuild()
        UI.toastShow("labels rebuilt", T.OK, 2)
    end, { width = 0.5 })
end
UI.cycle(detSection, "Detection sensitivity  (loose = finds more)",
    { "normal", "loose (finds more)", "strict (fewer mistakes)" }, 1, function(i)
        CONFIG.EggMinConfidence = ({ 60, 35, 75 })[i]
        Scanner.clear()
        Scanner.deepScan(false)
        UI.toastShow(("sensitivity: %s"):format(({ "normal", "loose", "strict" })[i]), T.OK, 2)
    end)
local sourceLine = UI.label(detSection, "detectors: -", T.DIM, { size = 10 })
local extraInput = UI.input(detSection, "extra keywords (comma separated)", CONFIG.EggExtraKeywords, function(text)
    CONFIG.EggExtraKeywords = text
    UI.toastShow("keywords saved - press DEEP SCAN", T.OK, 2)
end)

-- ---------------- FILTERS ----------------
local filterSection = UI.section(eggPage, "Filters", Color3.fromRGB(255, 190, 60))

local rarityValues = { "ANY" }
for _, r in ipairs(Rarity.ORDER) do
    if r ~= "Unknown" then table.insert(rarityValues, r) end
end
local rarityBtn = UI.cycle(filterSection, "Min rarity", rarityValues,
    CONFIG.EggMinRarityIndex + 1, function(i)
        CONFIG.EggMinRarityIndex = i - 1
        if i > 1 then
            rarityBtn.BackgroundColor3 = Rarity.color(rarityValues[i])
        else
            rarityBtn.BackgroundColor3 = T.BTN
        end
    end)

local islandValues = { "Any" }
for _, isl in ipairs(EggDB.ISLANDS) do table.insert(islandValues, isl.key) end
UI.cycle(filterSection, "Island", islandValues, 1, function(i)
    CONFIG.EggIslandFilter = islandValues[i]
end)

local searchInput = UI.input(filterSection, "search: dragon, secret, heavenly ...",
    table.concat(CONFIG.EggWhitelist, ", "), function(text)
        CONFIG.EggWhitelist = Util.split(text)
        UI.toastShow(("saved %d search word(s)"):format(#CONFIG.EggWhitelist), T.OK, 2)
    end)
UI.toggle(filterSection, "Use the search box", CONFIG.EggWhitelistOn, function(v)
    CONFIG.EggWhitelistOn = v
end)

local distInput = UI.input(filterSection, "max distance in studs (0 = any)",
    tostring(CONFIG.EggMaxDistance), function(text)
        CONFIG.EggMaxDistance = tonumber(text) or 0
        UI.toastShow("max distance = " .. tostring(CONFIG.EggMaxDistance), T.OK, 2)
    end)

UI.toggle(filterSection, "Hide eggs with unknown rarity", CONFIG.EggHideUnknown, function(v)
    CONFIG.EggHideUnknown = v
end)
UI.toggle(filterSection, "Only eggs from the known list", CONFIG.EggOnlyKnown, function(v)
    CONFIG.EggOnlyKnown = v
end)
UI.toggle(filterSection, "Skip eggs that failed recently", CONFIG.EggSkipFailed, function(v)
    CONFIG.EggSkipFailed = v
end)

local filterLine = UI.label(filterSection, "filters: 0 of 0 eggs pass", T.WARN, { size = 11 })
UI.button(filterSection, "RESET ALL FILTERS", function()
    CONFIG.EggMinRarityIndex = 0
    CONFIG.EggIslandFilter = "Any"
    CONFIG.EggWhitelistOn = false
    CONFIG.EggWhitelist = {}
    CONFIG.EggMaxDistance = 0
    CONFIG.EggHideUnknown = false
    CONFIG.EggOnlyKnown = false
    rarityBtn.BackgroundColor3 = T.BTN
    searchInput.Text = ""
    distInput.Text = "0"
    UI.toastShow("filters reset", T.OK, 2)
end, { color = T.BTN2 })

-- ---------------- TARGETS ----------------
local targetSection = UI.section(eggPage, "Eggs found (tap to teleport)", Color3.fromRGB(120, 220, 140))
local targetHint = UI.label(targetSection,
    "waiting for the first scan...", T.DIM, { size = 11 })

local MAX_ROWS = 16
local rows = {}
local headers = {}

-- small coloured header: "SECRET  x3"  (the list is grouped by category)
local function makeHeader(index)
    local h = Instance.new("TextLabel")
    h.Name = "Head" .. index
    h.BackgroundTransparency = 1
    h.Font = Enum.Font.GothamBold
    h.TextSize = s(10)
    h.TextColor3 = T.DIM
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.Size = UDim2.new(1, 0, 0, s(14))
    h.Visible = false
    h.Parent = targetSection
    return h
end

local function makeRow(index)
    local row = Instance.new("TextButton")
    row.Name = "Row" .. index
    row.BackgroundColor3 = T.BG3
    row.BackgroundTransparency = 0.25
    row.BorderSizePixel = 0
    row.Size = UDim2.new(1, 0, 0, s(30))
    row.AutoButtonColor = true
    row.Text = ""
    row.Visible = false
    row.Parent = targetSection
    UI.corner(row, s(7))

    local chip = UI.chip(row, "???", T.DIM, 42)
    chip.Position = UDim2.new(0, s(5), 0.5, -s(8))

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = s(11)
    nameLabel.TextColor3 = T.TEXT
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
    subLabel.TextColor3 = T.DIM
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
    distLabel.TextColor3 = T.DIM
    distLabel.TextXAlignment = Enum.TextXAlignment.Right
    distLabel.Position = UDim2.new(1, -s(92), 0, s(9))
    distLabel.Size = UDim2.new(0, s(52), 0, s(12))
    distLabel.Text = ""
    distLabel.Parent = row

    local farmBtn = Instance.new("TextButton")
    farmBtn.BackgroundColor3 = T.ACC
    farmBtn.Font = Enum.Font.GothamBold
    farmBtn.TextSize = s(10)
    farmBtn.TextColor3 = T.TEXT
    farmBtn.Text = "FARM"
    farmBtn.Size = UDim2.new(0, s(34), 0, s(20))
    farmBtn.Position = UDim2.new(1, -s(38), 0.5, -s(10))
    farmBtn.Parent = row
    UI.corner(farmBtn, s(6))

    local rec = nil
    UI.onClick(row, function()
        if rec and rec.obj and rec.obj.Parent then
            UI.toastShow("teleporting to " .. rec.name, Rarity.color(rec.rarity), 2)
            task.spawn(function()
                Farm.Teleport.to(rec.pos)
            end)
        end
    end)
    UI.onClick(farmBtn, function()
        if rec and rec.obj and rec.obj.Parent then
            Farm.runOnce(rec)
        end
    end)

    local data = {
        row = row, chip = chip, name = nameLabel, sub = subLabel,
        dist = distLabel, farm = farmBtn,
        set = function(_, r)
            rec = r
            if not r then row.Visible = false return end
            row.Visible = true
            local color = Rarity.color(r.rarity)
            chip.BackgroundColor3 = color
            chip.Text = " " .. (Rarity.SHORT[r.rarity] or "???") .. " "
            nameLabel.Text = r.name or "?"
            nameLabel.TextColor3 = color
            local bits = {}
            if r.island then table.insert(bits, r.island) end
            if r.incomeText then table.insert(bits, r.incomeText) end
            if r.timerLeft and r.timerLeft > 0 then
                table.insert(bits, Util.formatClock(r.timerLeft))
            end
            table.insert(bits, "(" .. (Scanner.SOURCE_LABEL[r.source] or r.source) .. ")")
            subLabel.Text = table.concat(bits, "  •  ")
            distLabel.Text = Util.formatDistance(r.dist)
        end,
    }
    return data
end

-- ---------------- AUTO FARM ----------------
local farmSection = UI.section(eggPage, "Auto farm", Color3.fromRGB(255, 120, 160))
local farmToggle, farmGet, farmSet = UI.toggle(farmSection, "AUTO FARM EGGS", CONFIG.EggAutoFarm, function(v)
    CONFIG.EggAutoFarm = v
    if not v then
        Farm.Teleport.cancel()
    else
        UI.toastShow("auto farm started", T.OK, 2)
        if not Farm.Base.get() then
            UI.toastShow("base not found - press SET BASE HERE", T.BAD, 4)
        end
    end
end)
UI.cycle(farmSection, "Pick order",
    { "best rarity first", "nearest first", "best income first" }, 1, function(i)
        CONFIG.EggFarmPriority = ({ "rarity", "nearest", "income" })[i]
    end)
UI.toggle(farmSection, "Safe step teleport (anti void)", CONFIG.EggSafeTeleport, function(v)
    CONFIG.EggSafeTeleport = v
end)
UI.toggle(farmSection, "Freeze in place while grabbing", CONFIG.EggAnchorWhileWaiting,
    function(v)
        CONFIG.EggAnchorWhileWaiting = v
        if not v then Farm.setAnchor(false) end
    end)
UI.toggle(farmSection, "Experimental: fire 'collect' remotes", CONFIG.EggExperimentalRemotes,
    function(v) CONFIG.EggExperimentalRemotes = v end)

do
    local row = UI.row(farmSection, 30)
    UI.button(row, "FARM BEST", function() Farm.runOnce(nil) end, { width = 0.34, color = T.ON })
    UI.button(row, "FARM NEAREST", function()
        local list = Scanner.matching()
        table.sort(list, function(a, b) return a.dist < b.dist end)
        Farm.runOnce(list[1])
    end, { width = 0.34 })
    UI.button(row, "STOP", function()
        CONFIG.EggAutoFarm = false
        farmSet(false)
        Farm.Teleport.cancel()
        UI.toastShow("stopped", T.WARN, 2)
    end, { width = 0.32, color = T.OFF })
end

do
    local row = UI.row(farmSection, 30)
    UI.button(row, "SET BASE HERE", function()
        local hrp = Util.getHRP()
        if hrp then
            Farm.Base.set(hrp.Position, "set by you")
            UI.toastShow("base saved", T.OK, 2)
            eggLog("base set to your current position", T.OK)
        end
    end, { width = 0.5, color = T.ACC })
    UI.button(row, "TELEPORT TO BASE", function()
        local base = Farm.Base.get()
        if base then
            Farm.Teleport.to(base.pos)
            UI.toastShow("teleported to base (" .. base.source .. ")", T.OK, 2)
        else
            UI.toastShow("base not found", T.BAD, 3)
        end
    end, { width = 0.5 })
end

local baseLine = UI.label(farmSection, "base: -", T.DIM, { size = 10 })
local farmStatsLine = UI.label(farmSection, "delivered 0   failed 0", T.DIM, { size = 10 })

do
    local row = UI.row(farmSection, 30)
    local pInput = UI.input(row, "pick delay", tostring(CONFIG.EggPickupDelay))
    pInput.Size = UDim2.new(0.5, -s(4), 0, s(30))
    pInput.FocusLost:Connect(function()
        local n = tonumber(pInput.Text)
        if n then CONFIG.EggPickupDelay = Util.clamp(n, 0.1, 6) end
    end)
    local rInput = UI.input(row, "return delay", tostring(CONFIG.EggReturnDelay))
    rInput.Size = UDim2.new(0.5, -s(4), 0, s(30))
    rInput.FocusLost:Connect(function()
        local n = tonumber(rInput.Text)
        if n then CONFIG.EggReturnDelay = Util.clamp(n, 0.5, 15) end
    end)
end

-- ---------------- ACTIVITY LOG ----------------
local actSection = UI.section(eggPage, "Activity", T.DIM)
eggLogFrame, eggLog, eggLogClear = UI.log(actSection, 150)

--==============================================================
--  REFRESH (runs once a second while the Eggs tab is open)
--==============================================================
local lastCounts = { total = -1, matching = -1 }

function Pages.refreshEggs()
    local list = Scanner.list or {}
    local total, matching, unknown = Scanner.counts()

    statusLabel.Text = ("detected %d   •   matching %d   •   delivered %d"):format(
        total, matching, Farm.stats.delivered)
    filterLine.Text = ("filters: %d of %d eggs pass%s"):format(
        matching, total, (unknown > 0 and ("   (%d unknown rarity)"):format(unknown) or ""))
    filterLine.TextColor3 = (matching > 0) and T.OK or T.WARN

    local st = Scanner.stats
    detectLine.Text = ("scan: %d objects in %.2fs  •  %d watched folders  •  live: %s"):format(
        st.scanned or 0, st.lastDuration or 0, Util.tableCount(Scanner.roots),
        CONFIG.EggLiveScan and "ON" or "OFF")

    -- how did we find them?
    local bySource = {}
    for _, rec in ipairs(list) do
        bySource[rec.source] = (bySource[rec.source] or 0) + 1
    end
    local bits = {}
    for _, k in ipairs(Util.keys(bySource)) do
        table.insert(bits, ("%s x%d"):format(Scanner.SOURCE_LABEL[k] or k, bySource[k]))
    end
    sourceLine.Text = #bits > 0 and ("found by: " .. table.concat(bits, "  |  "))
        or "found by: nothing yet"

    -- target rows, grouped by category (one coloured header per rarity)
    local targets = Scanner.matching(MAX_ROWS)
    local groups, groupOrder = {}, {}
    for _, rec in ipairs(targets) do
        if not groups[rec.rarity] then
            groups[rec.rarity] = {}
            table.insert(groupOrder, rec.rarity)
        end
        table.insert(groups[rec.rarity], rec)
    end
    table.sort(groupOrder, function(a, b) return Rarity.tier(a) > Rarity.tier(b) end)

    local slot, hIndex = 0, 0
    for _, rarityName in ipairs(groupOrder) do
        hIndex = hIndex + 1
        headers[hIndex] = headers[hIndex] or makeHeader(hIndex)
        local head = headers[hIndex]
        head.Visible = true
        head.LayoutOrder = slot + 1
        head.TextColor3 = Rarity.color(rarityName)
        head.Text = ("▸ %s   (%d)"):format(rarityName:upper(), #groups[rarityName])
        slot = slot + 1
        for _, rec in ipairs(groups[rarityName]) do
            slot = slot + 1
            if slot - hIndex > MAX_ROWS then break end
            rows[slot - hIndex] = rows[slot - hIndex] or makeRow(slot - hIndex)
            local rowData = rows[slot - hIndex]
            rowData.row.LayoutOrder = slot
            rowData:set(rec)
        end
    end
    for i = slot - hIndex + 1, MAX_ROWS do
        if rows[i] then rows[i]:set(nil) end
    end
    for i = hIndex + 1, #headers do
        if headers[i] then headers[i].Visible = false end
    end

    if #targets == 0 then
        targetHint.Visible = true
        if total == 0 then
            targetHint.Text = "NO EGGS DETECTED YET.\n" ..
                "1) make sure you are inside the LTM (go through the portal)\n" ..
                "2) press DEEP SCAN NOW (it scans the whole map)\n" ..
                "3) still nothing? open the DIAGNOSTICS tab and send me the report"
            targetHint.TextColor3 = T.BAD
        else
            targetHint.Text = ("%d eggs detected but none pass your filters - " ..
                "press RESET ALL FILTERS or relax them."):format(total)
            targetHint.TextColor3 = T.WARN
        end
    else
        targetHint.Visible = false
    end

    -- farm info
    local base = Farm.Base.get()
    baseLine.Text = base and ("base: %s   (%.0f, %.0f, %.0f)"):format(
        base.source, base.pos.X, base.pos.Y, base.pos.Z) or "base: NOT FOUND - press SET BASE HERE"
    baseLine.TextColor3 = base and T.DIM or T.BAD
    farmStatsLine.Text = ("delivered %d   •   failed %d   •   last: %s   •   grab method: %s"):format(
        Farm.stats.delivered, Farm.stats.failed, Farm.stats.lastEgg, Farm.Pickup.lastMethod)

    if total ~= lastCounts.total then
        lastCounts.total = total
        if total > 0 then
            eggLog(("%d eggs tracked (%d match your filters)"):format(total, matching), T.ACC)
        end
    end
end

Farm.onStatus = function(text, color)
    pcall(function()
        statusLine.Text = "farm: " .. tostring(text)
        statusLine.TextColor3 = color or T.DIM
    end)
end

Log.onAdd(function(text, color, tag)
    if tag == "EGG" or tag == "FARM" then
        pcall(eggLog, text, color)
    end
end)

--==============================================================
--  PAGE 2 : CODE SNIPER
--==============================================================
local sniperPage = UI.addTab("Sniper")
UI.label(sniperPage, "CODE SNIPER - listens to SpyderSammy and types the code for you",
    T.ACC, { bold = true })

local sniperStatus = UI.label(sniperPage, "status: listening...", T.DIM)
Sniper.statusFn = function(t, c)
    pcall(function()
        sniperStatus.Text = ("status: %s\n|  type: %s  |  captured: %d"):format(
            t, Sniper.describeHint(Sniper.hint), Sniper.captured)
        sniperStatus.TextColor3 = c or T.DIM
    end)
end

local snipMain = UI.section(sniperPage, "Main", T.ACC)
UI.toggle(snipMain, "Sniper enabled", CONFIG.SniperEnabled, function(v) CONFIG.SniperEnabled = v end)
UI.toggle(snipMain, "TEST: listen to everyone", CONFIG.SniperListenEveryone, function(v)
    CONFIG.SniperListenEveryone = v
    if v then UI.toastShow("type in chat: code is TACO BOOST 123", T.WARN, 4) end
end)
UI.toggle(snipMain, "Auto press Submit", CONFIG.SniperAutoSubmit, function(v)
    CONFIG.SniperAutoSubmit = v
end)

local typeValues = {}
for _, t in ipairs(Sniper.CODE_TYPES) do table.insert(typeValues, t.name) end
UI.cycle(snipMain, "Code type", typeValues, CONFIG.SniperTypeIndex, function(i)
    CONFIG.SniperTypeIndex = i
    Sniper.hint = Sniper.hintFromIndex(i)
    Sniper.hintFromChat = false
end)

local startBtn = UI.button(snipMain, "▶  START capturing", function()
    Sniper.hintFromChat = false
    Sniper.startSession()
    UI.toastShow("capturing started - say the code!", T.OK, 2)
end, { h = 38, color = T.ON })
local fmtJoined = true
local fmtBtn
fmtBtn = UI.button(snipMain, "Format:  JOINED (TACOBOOST)", function()
    fmtJoined = not fmtJoined
    CONFIG.SniperJoinCode = fmtJoined
    fmtBtn.Text = fmtJoined and "Format:  JOINED (TACOBOOST)" or 'Format:  SPACED ("TACO BOOST")'
end, { color = T.BTN })
UI.button(snipMain, "■  STOP capturing", function() Sniper.finalizeCode() end)

local snipFilters = UI.section(sniperPage, "Options", T.DIM)
local timeoutInput = UI.input(snipFilters, "silence timeout (seconds)",
    tostring(CONFIG.SniperSilenceTimeout), function(text)
        local n = tonumber(text)
        if n then CONFIG.SniperSilenceTimeout = Util.clamp(n, 1, 60) end
    end)
UI.input(snipFilters, "code box path (optional, auto-detect when empty)",
    CONFIG.CodeBoxPathOverride, function(text) CONFIG.CodeBoxPathOverride = text end)

local testSection = UI.section(sniperPage, "Test zone (no event needed)",
    Color3.fromRGB(255, 190, 60))
local testInput = UI.input(testSection, "type a word (e.g. TACO)", "")
UI.button(testSection, "1) Feed this word", function()
    local w = testInput.Text
    if w == "" then return end
    testInput.Text = ""
    Sniper.handleMessage(w, SaB.LocalPlayer.UserId, SaB.LocalPlayer.Name, true)
end)
UI.button(testSection, "2) Start session (marker)", function()
    Sniper.handleMessage("code is", SaB.LocalPlayer.UserId, SaB.LocalPlayer.Name, true)
end)
UI.button(testSection, "3) DEMO: two words", function()
    task.spawn(function()
        for _, w in ipairs({ "the code is two words", "TACO", "BOOST" }) do
            Sniper.handleMessage(w, SaB.LocalPlayer.UserId, SaB.LocalPlayer.Name, true)
            task.wait(0.8)
        end
        UI.toastShow("demo finished - check the log", T.OK, 2)
    end)
end)
UI.button(testSection, "3b) DEMO: words + numbers", function()
    task.spawn(function()
        for _, w in ipairs({ "the code is letters and numbers", "TACO", "BOOST", "123" }) do
            Sniper.handleMessage(w, SaB.LocalPlayer.UserId, SaB.LocalPlayer.Name, true)
            task.wait(0.8)
        end
        UI.toastShow("demo finished - check the log", T.OK, 2)
    end)
end)
UI.button(testSection, "4) Force finish now", function() Sniper.finalizeCode() end)

local sniperLogFrame, sniperLog, sniperLogClear = UI.log(sniperPage, 170)
Sniper.logFn = function(text, color) pcall(sniperLog, text, color) end
sniperLog("sniper ready - target: SpyderSammy (id " .. CONFIG.SniperTargetUserId .. ")", T.ACC)
sniperLog("waiting for a marker ('code is') or a type announcement ...", T.DIM)
sniperLog("tip: pick the CODE TYPE above, or let the sniper read it from Sammy", T.DIM)

--==============================================================
--  PAGE 3 : DIAGNOSTICS
--==============================================================
local Diag = {}
SaB.Diag = Diag
Diag.lastReport = ""

local diagPage = UI.addTab("Diag")
UI.label(diagPage, "DIAGNOSTICS - press REPORT then send me the text (copy or file)",
    T.ACC, { bold = true })

local function line(out, text)
    table.insert(out, tostring(text))
end

function Diag.buildReport()
    local out = {}
    local lp = SaB.LocalPlayer
    line(out, "=== SaB Suite report ===")
    line(out, ("version   : %s"):format(SaB.VERSION))
    line(out, ("date      : %s"):format(os.date("%Y-%m-%d %H:%M:%S")))
    line(out, ("placeId   : %s   jobId: %s"):format(tostring(game.PlaceId), tostring(game.JobId)))
    line(out, ("player    : %s (%s)"):format(lp.Name, tostring(lp.UserId)))
    line(out, ("egg DB    : %d known eggs, source: %s"):format(#EggDB.EGGS, EggDB.SOURCE))
    line(out, "")

    -- 1) top level of the workspace
    line(out, "--- WORKSPACE (top level) ---")
    for _, c in ipairs(Workspace:GetChildren()) do
        local n = 0
        pcall(function() n = #c:GetChildren() end)
        line(out, ("  %s  [%s]  children=%d"):format(c.Name, c.ClassName, n))
    end
    line(out, "")

    -- 2) second level (folders where eggs usually live)
    line(out, "--- WORKSPACE (2nd level, first 200) ---")
    local printed = 0
    for _, c in ipairs(Workspace:GetChildren()) do
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
    for _, d in ipairs(Workspace:GetDescendants()) do
        if eggish >= 120 then break end
        local n = Util.lower(d.Name)
        if (d:IsA("Model") or d:IsA("BasePart") or d:IsA("Folder"))
            and (EggDB.isEggWord(n) or EggDB.lookup(d.Name)) then
            line(out, ("  %s  [%s]  parent=%s"):format(
                Util.path(d), d.ClassName, d.Parent and d.Parent.Name or "?"))
            eggish = eggish + 1
        end
    end
    if eggish == 0 then line(out, "  (none)") end
    line(out, "")

    -- 4) what our scanner actually found
    line(out, "--- SCANNER FINDINGS ---")
    local list = Scanner.list or {}
    line(out, ("  %d eggs tracked"):format(#list))
    for _, rec in ipairs(list) do
        line(out, ("  %s | %s | island=%s | via=%s | score=%d | path=%s"):format(
            rec.name, rec.rarity, tostring(rec.island), rec.source, rec.score, rec.path))
    end
    line(out, ("  roots watched: %d"):format(Util.tableCount(Scanner.roots)))
    line(out, ("  last scan: %d objects in %.2fs"):format(
        Scanner.stats.scanned or 0, Scanner.stats.lastDuration or 0))
    line(out, "")

    -- 5) prompts we have seen
    line(out, "--- PROXIMITY PROMPTS SEEN ---")
    if #Scanner.promptLog == 0 then
        line(out, "  (none yet - walk up to an egg / an NPC)")
    else
        for _, l in ipairs(Scanner.promptLog) do line(out, "  " .. l) end
    end
    line(out, "")

    -- 6) remotes that look useful
    line(out, "--- REMOTES (collect / pick / egg / hatch) ---")
    local remotes = 0
    for _, d in ipairs(SaB.Services.ReplicatedStorage:GetDescendants()) do
        if remotes >= 80 then break end
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
            local n = Util.lower(d.Name)
            if n:find("collect") or n:find("pick") or n:find("egg") or n:find("hatch")
                or n:find("grab") or n:find("take") or n:find("steal") then
                line(out, "  " .. Util.path(d))
                remotes = remotes + 1
            end
        end
    end
    if remotes == 0 then line(out, "  (none)") end
    line(out, "")

    -- 7) base candidates
    line(out, "--- BASE CANDIDATES ---")
    local bp, src = Farm.Base.find()
    line(out, ("  found: %s   source: %s"):format(
        bp and ("%.0f, %.0f, %.0f"):format(bp.X, bp.Y, bp.Z) or "NO", tostring(src)))
    line(out, "")

    -- 8) character / carrying
    line(out, "--- PLAYER ---")
    local hrp = Util.getHRP()
    line(out, ("  position: %s"):format(hrp and ("%.0f, %.0f, %.0f"):format(
        hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "no character"))
    line(out, ("  carrying: %s"):format(tostring(Farm.Carry.what())))
    local attrs = Util.getAttributes(lp)
    local attrBits = {}
    for k, v in pairs(attrs) do
        table.insert(attrBits, ("%s=%s"):format(k, tostring(v)))
    end
    line(out, ("  attributes: %s"):format(#attrBits > 0 and table.concat(attrBits, ", ") or "(none)"))
    line(out, "")
    line(out, "=== end of report ===")

    local text = table.concat(out, "\n")
    Diag.lastReport = text
    return text
end

local diagLogFrame, diagLog = UI.log(diagPage, 220)

local function dumpToLog(title, items)
    diagLog(("=== %s (%d) ==="):format(title, #items), T.ACC)
    for i = 1, math.min(#items, 80) do diagLog("  " .. tostring(items[i]), T.TEXT) end
end

local diagSection = UI.section(diagPage, "Reports", T.ACC)
UI.button(diagSection, "▶  BUILD FULL REPORT", function()
    local text = Diag.buildReport()
    diagLog("=== FULL REPORT ===", T.ACC)
    for l in (text .. "\n"):gmatch("([^\n]*)\n") do
        diagLog(l, T.TEXT)
    end
    print(text)
    UI.toastShow("report built - copy / save it below", T.OK, 3)
end, { h = 36, color = T.ACC })

do
    local row = UI.row(diagSection, 30)
    UI.button(row, "COPY report", function()
        if Diag.lastReport == "" then Diag.buildReport() end
        if Util.clipboard(Diag.lastReport) then
            UI.toastShow("copied to clipboard", T.OK, 2)
        else
            UI.toastShow("no clipboard on this executor - use SAVE", T.BAD, 3)
        end
    end, { width = 0.5, color = T.ON })
    UI.button(row, "SAVE to file", function()
        if Diag.lastReport == "" then Diag.buildReport() end
        if Util.writeFile("egg_report.txt", Diag.lastReport) then
            UI.toastShow("saved to SaBSuite/egg_report.txt", T.OK, 3)
        else
            UI.toastShow("writefile not supported here", T.BAD, 3)
        end
    end, { width = 0.5 })
end

local dumpSection = UI.section(diagPage, "Quick dumps", T.DIM)
UI.button(dumpSection, "Dump: names containing 'egg'", function()
    local items = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if Util.has(d.Name, "egg") then
            table.insert(items, ("%s [%s] parent=%s"):format(
                Util.path(d), d.ClassName, d.Parent and d.Parent.Name or "?"))
        end
    end
    dumpToLog("EGG NAMES", items)
end)
UI.button(dumpSection, "Dump: island / LTM folders", function()
    local items = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Folder") or d:IsA("Model") then
            if EggDB.isContainerWord(d.Name) then
                local n = 0
                pcall(function() n = #d:GetChildren() end)
                table.insert(items, ("%s [%s] children=%d"):format(Util.path(d), d.ClassName, n))
            end
        end
    end
    dumpToLog("CONTAINERS", items)
end)
UI.button(dumpSection, "Dump: proximity prompts in the map", function()
    local items = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            table.insert(items, ("%s | action='%s' | hold=%.1f | parent=%s"):format(
                Util.path(d), tostring(d.ActionText), tonumber(d.HoldDuration) or 0,
                Util.path(d.Parent)))
        end
    end
    dumpToLog("PROMPTS", items)
end)
UI.button(dumpSection, "Dump: remotes", function()
    local items = {}
    for _, d in ipairs(SaB.Services.ReplicatedStorage:GetDescendants()) do
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
            table.insert(items, Util.path(d))
        end
    end
    dumpToLog("REMOTES", items)
end)
UI.button(dumpSection, "Dump: my attributes + carrying", function()
    local items = {}
    for k, v in pairs(Util.getAttributes(SaB.LocalPlayer)) do
        table.insert(items, ("player.%s = %s"):format(k, tostring(v)))
    end
    local char = Util.getChar()
    if char then
        for _, d in ipairs(char:GetDescendants()) do
            if Util.has(d.Name, "egg") or Util.has(d.Name, "carry") or Util.has(d.Name, "hold") then
                table.insert(items, "character has: " .. Util.path(d))
            end
        end
    end
    table.insert(items, "carrying = " .. tostring(Farm.Carry.what()))
    dumpToLog("PLAYER", items)
end)
UI.button(dumpSection, "Dump: what the scanner is tracking", function()
    local items = {}
    for _, rec in ipairs(Scanner.list or {}) do
        table.insert(items, ("%s | %s | island=%s | via=%s | score=%d | %s"):format(
            rec.name, rec.rarity, tostring(rec.island), rec.source, rec.score, rec.path))
    end
    dumpToLog("TRACKED EGGS", items)
end)

--==============================================================
--  PAGE 4 : SETTINGS
--==============================================================
local setPage = UI.addTab("Settings")
UI.label(setPage, "SETTINGS", T.ACC, { bold = true })

local uiSection = UI.section(setPage, "Interface", T.ACC)
UI.cycle(uiSection, "Label size", { "normal", "big", "huge" }, 1, function(i)
    CONFIG.EggLabelScale = ({ 1.0, 1.25, 1.5 })[i]
    SaB.ESP.rebuild()
end)
UI.input(uiSection, "ESP max distance (studs)", tostring(CONFIG.EggEspMaxDistance), function(text)
    local n = tonumber(text)
    if n then
        CONFIG.EggEspMaxDistance = Util.clamp(n, 200, 20000)
        SaB.ESP.rebuild()
    end
end)
UI.button(uiSection, "Reset window position", function() UI.resetPosition() end)
UI.button(uiSection, "Re-center + reopen", function()
    UI.show()
    UI.setMinimized(false)
    UI.resetPosition()
end)
UI.button(uiSection, "Clear all ESP labels", function()
    SaB.ESP.clear()
    UI.toastShow("labels cleared", T.OK, 2)
end)

local infoSection = UI.section(setPage, "Info", T.DIM)
UI.label(infoSection,
    ("version %s   •   %d known eggs (Update 68 LTM)\n"):format(SaB.VERSION, #EggDB.EGGS)
    .. "Egg data: Steal a Brainrot Wiki - 'Jump for Eggs LTM'.\n"
    .. "Rarity colours: one colour per category (Secret = gold, "
    .. "Brainrot God = pink, Mythic = red, ...).\n"
    .. "Islands: Grass < Desert < Arctic < Cave < Aquatic < Lava < Heavenly.",
    T.DIM, { size = 10 })

UI.button(infoSection, "UNLOAD script (stop everything)", function()
    SaB.Running = false
    CONFIG.EggAutoFarm = false
    CONFIG.EggESPEnabled = false
    CONFIG.SniperEnabled = false
    pcall(function() SaB.ESP.clear() end)
    pcall(function() UI.gui:Destroy() end)
    Util.notify("SaB Suite", "unloaded", 3)
end, { color = T.OFF })

--==============================================================
--  STARTUP
--==============================================================
UI.layoutTabs()
UI.selectTab("Eggs")

task.spawn(function()
    while SaB.Running do
        task.wait(1)
        pcall(function()
            if UI.currentTab == "Eggs" and UI.gui.Enabled then
                Pages.refreshEggs()
            end
        end)
    end
end)

-- first paint
task.spawn(function()
    task.wait(1.2)
    pcall(Pages.refreshEggs)
end)

return Pages
