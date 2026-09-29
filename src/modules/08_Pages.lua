--==============================================================
--  PAGES  (Eggs · Code Sniper · Diagnostics · Settings)
--
--  The Eggs tab is built to answer three questions instantly:
--     1. how many eggs did we find, and HOW did we find them?
--     2. which ones pass my filters right now?
--     3. what is the farm doing at this second?
--==============================================================

local W = {}          -- every widget of this page lives here (saves locals)
W.Util = SaB.Util
W.CONFIG = SaB.CONFIG
W.Rarity = SaB.Rarity

W.Farm = SaB.Farm

W.UI = SaB.UI

W.s = W.UI.s

W.Pages = {}
SaB.Pages = W.Pages

--==============================================================
--  PAGE 1 : EGGS
--==============================================================
W.eggPage = W.UI.addTab("Eggs")

-- (moved into the widget table)
-- ---------------- STATUS ----------------
W.statusSection = W.UI.section(W.eggPage, "Status", SaB.Theme.ACC)  -- keep for the children
W.statusLabel = W.UI.label(W.statusSection, "detected 0   •   matching 0   •   delivered 0",
    SaB.Theme.TEXT, { bold = true })
W.statusLine = W.UI.label(W.statusSection, "farm: idle", SaB.Theme.DIM)
W.detectLine = W.UI.label(W.statusSection, "scan: -", SaB.Theme.DIM, { size = 10 })

-- ---------------- DETECTION ----------------
W.detSection = W.UI.section(W.eggPage, "Detection", Color3.fromRGB(90, 200, 255))
W.UI.toggle(W.detSection, "EGG ESP (labels)", W.CONFIG.EggESPEnabled, function(v)
    W.CONFIG.EggESPEnabled = v
    if not v then SaB.ESP.clear() end
end)
W.UI.toggle(W.detSection, "Glow box around eggs", W.CONFIG.EggHighlight, function(v)
    W.CONFIG.EggHighlight = v
end)
W.UI.toggle(W.detSection, "See eggs through walls", W.CONFIG.EggAlwaysOnTop, function(v)
    W.CONFIG.EggAlwaysOnTop = v
    SaB.ESP.rebuild()
end)
W.UI.toggle(W.detSection, "Watch for new eggs (live scan)", W.CONFIG.EggLiveScan, function(v)
    W.CONFIG.EggLiveScan = v
end)
do
    local row = W.UI.row(W.detSection, 30)
    W.UI.button(row, "DEEP SCAN NOW", function()
        W.UI.toastShow("scanning the whole map...", SaB.Theme.ACC, 2)
        local added = SaB.Scanner.deepScan(false)
        W.UI.toastShow(("scan done - %d eggs tracked"):format(W.Util.tableCount(SaB.Scanner.eggs)), SaB.Theme.OK, 2)
        W.eggLog(("deep scan: +%d new (see console)"):format(added), SaB.Theme.ACC)
    end, { width = 0.5, color = SaB.Theme.ACC })
    W.UI.button(row, "REBUILD LABELS", function()
        SaB.ESP.rebuild()
        W.UI.toastShow("labels rebuilt", SaB.Theme.OK, 2)
    end, { width = 0.5 })
end
W.UI.cycle(W.detSection, "Detection sensitivity  (loose = finds more)",
    { "normal", "loose (finds more)", "strict (fewer mistakes)" }, 1, function(i)
        W.CONFIG.EggMinConfidence = ({ 60, 35, 75 })[i]
        SaB.Scanner.clear()
        SaB.Scanner.deepScan(false)
        W.UI.toastShow(("sensitivity: %s"):format(({ "normal", "loose", "strict" })[i]), SaB.Theme.OK, 2)
    end)
W.sourceLine = W.UI.label(W.detSection, "detectors: -", SaB.Theme.DIM, { size = 10 })
W.extraInput = W.UI.input(W.detSection, "extra keywords (comma separated)", W.CONFIG.EggExtraKeywords, function(text)
    W.CONFIG.EggExtraKeywords = text
    W.UI.toastShow("keywords saved - press DEEP SCAN", SaB.Theme.OK, 2)
end)

-- ---------------- FILTERS ----------------
W.filterSection = W.UI.section(W.eggPage, "Filters", Color3.fromRGB(255, 190, 60))

W.rarityValues = { "ANY" }
for _, r in ipairs(W.Rarity.ORDER) do
    if r ~= "Unknown" then table.insert(W.rarityValues, r) end
end
W.rarityBtn = W.UI.cycle(W.filterSection, "Min rarity", W.rarityValues,
    W.CONFIG.EggMinRarityIndex + 1, function(i)
        W.CONFIG.EggMinRarityIndex = i - 1
        if i > 1 then
            W.rarityBtn.BackgroundColor3 = W.Rarity.color(W.rarityValues[i])
        else
            W.rarityBtn.BackgroundColor3 = SaB.Theme.BTN
        end
    end)

W.islandValues = { "Any" }
for _, isl in ipairs(SaB.EggDB.ISLANDS) do table.insert(W.islandValues, isl.key) end
W.UI.cycle(W.filterSection, "Island", W.islandValues, 1, function(i)
    W.CONFIG.EggIslandFilter = W.islandValues[i]
end)

W.searchInput = W.UI.input(W.filterSection, "search: dragon, secret, heavenly ...",
    table.concat(W.CONFIG.EggWhitelist, ", "), function(text)
        W.CONFIG.EggWhitelist = W.Util.split(text)
        W.UI.toastShow(("saved %d search word(s)"):format(#W.CONFIG.EggWhitelist), SaB.Theme.OK, 2)
    end)
W.UI.toggle(W.filterSection, "Use the search box", W.CONFIG.EggWhitelistOn, function(v)
    W.CONFIG.EggWhitelistOn = v
end)

W.distInput = W.UI.input(W.filterSection, "max distance in studs (0 = any)",
    tostring(W.CONFIG.EggMaxDistance), function(text)
        W.CONFIG.EggMaxDistance = tonumber(text) or 0
        W.UI.toastShow("max distance = " .. tostring(W.CONFIG.EggMaxDistance), SaB.Theme.OK, 2)
    end)

W.UI.toggle(W.filterSection, "Hide eggs with unknown rarity", W.CONFIG.EggHideUnknown, function(v)
    W.CONFIG.EggHideUnknown = v
end)
W.UI.toggle(W.filterSection, "Only eggs from the known list", W.CONFIG.EggOnlyKnown, function(v)
    W.CONFIG.EggOnlyKnown = v
end)
W.UI.toggle(W.filterSection, "Skip eggs that failed recently", W.CONFIG.EggSkipFailed, function(v)
    W.CONFIG.EggSkipFailed = v
end)

W.filterLine = W.UI.label(W.filterSection, "filters: 0 of 0 eggs pass", SaB.Theme.WARN, { size = 11 })
W.UI.button(W.filterSection, "RESET ALL FILTERS", function()
    W.CONFIG.EggMinRarityIndex = 0
    W.CONFIG.EggIslandFilter = "Any"
    W.CONFIG.EggWhitelistOn = false
    W.CONFIG.EggWhitelist = {}
    W.CONFIG.EggMaxDistance = 0
    W.CONFIG.EggHideUnknown = false
    W.CONFIG.EggOnlyKnown = false
    W.rarityBtn.BackgroundColor3 = SaB.Theme.BTN
    W.searchInput.Text = ""
    W.distInput.Text = "0"
    W.UI.toastShow("filters reset", SaB.Theme.OK, 2)
end, { color = SaB.Theme.BTN2 })

-- ---------------- ALERTS ----------------
W.alertSection = W.UI.section(W.eggPage, "Rare egg alerts", Color3.fromRGB(255, 215, 0))
W.UI.toggle(W.alertSection, "Shout when a rare egg appears", W.CONFIG.EggAlertEnabled,
    function(v) W.CONFIG.EggAlertEnabled = v end)

W.alertValues = {}
for _, name in ipairs(W.Rarity.ORDER) do
    if name ~= "Unknown" then table.insert(W.alertValues, name) end
end
W.alertBtn = W.UI.cycle(W.alertSection, "Alert me from", W.alertValues,
    W.CONFIG.EggAlertMinRarityIndex, function(i)
        W.CONFIG.EggAlertMinRarityIndex = i
        W.alertBtn.BackgroundColor3 = W.Rarity.color(W.alertValues[i])
    end)
W.alertBtn.BackgroundColor3 = W.Rarity.color(W.alertValues[W.CONFIG.EggAlertMinRarityIndex] or "Secret")
W.alertLine = W.UI.label(W.alertSection, "no rare eggs yet", SaB.Theme.DIM, { size = 10 })

-- ---------------- TARGETS ----------------
W.targetSection = W.UI.section(W.eggPage, "Eggs found (tap to teleport)", Color3.fromRGB(120, 220, 140))
W.targetHint = W.UI.label(W.targetSection,
    "waiting for the first scan...", SaB.Theme.DIM, { size = 11 })

W.MAX_ROWS = 16
W.rows = {}
W.headers = {}

-- small coloured header: "SECRET  x3"  (the list is grouped by category)
local function makeHeader(index)
    local h = Instance.new("TextLabel")
    h.Name = "Head" .. index
    h.BackgroundTransparency = 1
    h.Font = Enum.Font.GothamBold
    h.TextSize = s(10)
    h.TextColor3 = SaB.Theme.DIM
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.Size = UDim2.new(1, 0, 0, s(14))
    h.Visible = false
    h.Parent = W.targetSection
    return h
end

local function makeRow(index)
    local row = Instance.new("TextButton")
    row.Name = "Row" .. index
    row.BackgroundColor3 = SaB.Theme.BG3
    row.BackgroundTransparency = 0.25
    row.BorderSizePixel = 0
    row.Size = UDim2.new(1, 0, 0, s(30))
    row.AutoButtonColor = true
    row.Text = ""
    row.Visible = false
    row.Parent = W.targetSection
    W.UI.corner(row, s(7))

    local chip = W.UI.chip(row, "???", SaB.Theme.DIM, 42)
    chip.Position = UDim2.new(0, s(5), 0.5, -s(8))

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = s(11)
    nameLabel.TextColor3 = SaB.Theme.TEXT
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
    subLabel.TextColor3 = SaB.Theme.DIM
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
    distLabel.TextColor3 = SaB.Theme.DIM
    distLabel.TextXAlignment = Enum.TextXAlignment.Right
    distLabel.Position = UDim2.new(1, -s(92), 0, s(9))
    distLabel.Size = UDim2.new(0, s(52), 0, s(12))
    distLabel.Text = ""
    distLabel.Parent = row

    local farmBtn = Instance.new("TextButton")
    farmBtn.BackgroundColor3 = SaB.Theme.ACC
    farmBtn.Font = Enum.Font.GothamBold
    farmBtn.TextSize = s(10)
    farmBtn.TextColor3 = SaB.Theme.TEXT
    farmBtn.Text = "FARM"
    farmBtn.Size = UDim2.new(0, s(34), 0, s(20))
    farmBtn.Position = UDim2.new(1, -s(38), 0.5, -s(10))
    farmBtn.Parent = row
    W.UI.corner(farmBtn, s(6))

    local rec = nil
    W.UI.onClick(row, function()
        if rec and rec.obj and rec.obj.Parent then
            W.UI.toastShow("teleporting to " .. rec.name, W.Rarity.color(rec.rarity), 2)
            task.spawn(function()
                W.Farm.Teleport.to(rec.pos)
            end)
        end
    end)
    W.UI.onClick(farmBtn, function()
        if rec and rec.obj and rec.obj.Parent then
            W.Farm.runOnce(rec)
        end
    end)

    local data = {
        row = row, chip = chip, name = nameLabel, sub = subLabel,
        dist = distLabel, farm = farmBtn,
        set = function(_, r)
            rec = r
            if not r then row.Visible = false return end
            row.Visible = true
            local color = W.Rarity.color(r.rarity)
            chip.BackgroundColor3 = color
            chip.Text = " " .. (W.Rarity.SHORT[r.rarity] or "???") .. " "
            nameLabel.Text = r.name or "?"
            nameLabel.TextColor3 = color
            local bits = {}
            if r.island then table.insert(bits, r.island) end
            if r.incomeText then table.insert(bits, r.incomeText) end
            if r.timerLeft and r.timerLeft > 0 then
                table.insert(bits, W.Util.formatClock(r.timerLeft))
            end
            table.insert(bits, "(" .. (SaB.Scanner.SOURCE_LABEL[r.source] or r.source) .. ")")
            subLabel.Text = table.concat(bits, "  •  ")
            distLabel.Text = W.Util.formatDistance(r.dist)
        end,
    }
    return data
end

-- ---------------- AUTO FARM ----------------
W.farmSection = W.UI.section(W.eggPage, "Auto farm", Color3.fromRGB(255, 120, 160))
W.farmToggle, W.farmGet, W.farmSet = W.UI.toggle(W.farmSection, "AUTO FARM EGGS", W.CONFIG.EggAutoFarm, function(v)
    W.CONFIG.EggAutoFarm = v
    if not v then
        W.Farm.Teleport.cancel()
    else
        W.UI.toastShow("auto farm started", SaB.Theme.OK, 2)
        if not W.Farm.Base.get() then
            W.UI.toastShow("base not found - press SET BASE HERE", SaB.Theme.BAD, 4)
        end
    end
end)
W.UI.cycle(W.farmSection, "Pick order",
    { "best rarity first", "nearest first", "best income first" }, 1, function(i)
        W.CONFIG.EggFarmPriority = ({ "rarity", "nearest", "income" })[i]
    end)
W.UI.toggle(W.farmSection, "Safe step teleport (anti void)", W.CONFIG.EggSafeTeleport, function(v)
    W.CONFIG.EggSafeTeleport = v
end)
W.UI.toggle(W.farmSection, "Freeze in place while grabbing", W.CONFIG.EggAnchorWhileWaiting,
    function(v)
        W.CONFIG.EggAnchorWhileWaiting = v
        if not v then W.Farm.setAnchor(false) end
    end)
W.UI.toggle(W.farmSection, "Experimental: fire 'collect' remotes", W.CONFIG.EggExperimentalRemotes,
    function(v) W.CONFIG.EggExperimentalRemotes = v end)

do
    local row = W.UI.row(W.farmSection, 30)
    W.UI.button(row, "FARM BEST", function() W.Farm.runOnce(nil) end, { width = 0.34, color = SaB.Theme.ON })
    W.UI.button(row, "FARM NEAREST", function()
        local list = SaB.Scanner.matching()
        table.sort(list, function(a, b) return a.dist < b.dist end)
        W.Farm.runOnce(list[1])
    end, { width = 0.34 })
    W.UI.button(row, "STOP", function()
        W.CONFIG.EggAutoFarm = false
        W.farmSet(false)
        W.Farm.Teleport.cancel()
        W.UI.toastShow("stopped", SaB.Theme.WARN, 2)
    end, { width = 0.32, color = SaB.Theme.OFF })
end

do
    local row = W.UI.row(W.farmSection, 30)
    W.UI.button(row, "SET BASE HERE", function()
        local hrp = W.Util.getHRP()
        if hrp then
            W.Farm.Base.set(hrp.Position, "set by you")
            W.UI.toastShow("base saved", SaB.Theme.OK, 2)
            W.eggLog("base set to your current position", SaB.Theme.OK)
        end
    end, { width = 0.5, color = SaB.Theme.ACC })
    W.UI.button(row, "TELEPORT TO BASE", function()
        local base = W.Farm.Base.get()
        if base then
            W.Farm.Teleport.to(base.pos)
            W.UI.toastShow("teleported to base (" .. base.source .. ")", SaB.Theme.OK, 2)
        else
            W.UI.toastShow("base not found", SaB.Theme.BAD, 3)
        end
    end, { width = 0.5 })
end

W.baseLine = W.UI.label(W.farmSection, "base: -", SaB.Theme.DIM, { size = 10 })
W.farmStatsLine = W.UI.label(W.farmSection, "delivered 0   failed 0", SaB.Theme.DIM, { size = 10 })

do
    local row = W.UI.row(W.farmSection, 30)
    local pInput = W.UI.input(row, "pick delay", tostring(W.CONFIG.EggPickupDelay))
    pInput.Size = UDim2.new(0.5, -s(4), 0, s(30))
    pInput.FocusLost:Connect(function()
        local n = tonumber(pInput.Text)
        if n then W.CONFIG.EggPickupDelay = W.Util.clamp(n, 0.1, 6) end
    end)
    local rInput = W.UI.input(row, "return delay", tostring(W.CONFIG.EggReturnDelay))
    rInput.Size = UDim2.new(0.5, -s(4), 0, s(30))
    rInput.FocusLost:Connect(function()
        local n = tonumber(rInput.Text)
        if n then W.CONFIG.EggReturnDelay = W.Util.clamp(n, 0.5, 15) end
    end)
end

-- ---------------- ISLANDS ----------------
W.islandSection = W.UI.section(W.eggPage, "Islands (tap to fly there)",
    Color3.fromRGB(120, 220, 255))
W.islandLine = W.UI.label(W.islandSection, "no islands found yet", SaB.Theme.DIM, { size = 10 })
W.islandBtns = {}

local function makeIslandBtn(index)
    local b = W.UI.button(W.islandSection, "-", function()
        local isl = W.islandBtns[index].island
        if isl and isl.obj and isl.obj.Parent then
            W.Farm.Teleport.to(isl.pos)
            W.UI.toastShow("flying to " .. isl.key, SaB.Extras.islandColor(isl.key), 2)
        end
    end, { color = SaB.Theme.BTN })
    b.Visible = false
    W.islandBtns[index] = { button = b }
    return W.islandBtns[index]
end

-- ---------------- COLLECTED ----------------
W.collSection = W.UI.section(W.eggPage, "Collected eggs", Color3.fromRGB(150, 230, 160))
W.collLogBox = W.UI.log(W.collSection, 110)
W.collLog, W.collLogClear = W.collLogBox.add, W.collLogBox.clear
W.Farm.onDelivery = function(rec)
    pcall(function()
        W.collLog(("%s   %s   [%s]"):format(os.date("%H:%M:%S"), rec.name, rec.rarity),
            W.Rarity.color(rec.rarity))
    end)
end
W.UI.button(W.collSection, "Clear the collected list", function() W.collLogClear() end,
    { color = SaB.Theme.BTN2 })

-- ---------------- AFK / XP ----------------
W.afkSection = W.UI.section(W.eggPage, "AFK / XP (trampoline)",
    Color3.fromRGB(200, 160, 255))
W.UI.toggle(W.afkSection, "AFK auto jump (trampoline XP)", W.CONFIG.AfkJump, function(v)
    W.CONFIG.AfkJump = v
    if v then
        W.UI.toastShow("auto jump ON", SaB.Theme.OK, 2)
    end
end)
W.afkInput = W.UI.input(W.afkSection, "seconds between jumps",
    tostring(W.CONFIG.AfkJumpInterval), function(text)
        local n = tonumber(text)
        if n then W.CONFIG.AfkJumpInterval = W.Util.clamp(n, 0.15, 5) end
    end)
do
    local row = W.UI.row(W.afkSection, 30)
    W.UI.button(row, "FIND TRAMPOLINE", function()
        local pos, name = SaB.Extras.findTrampoline()
        if pos then
            W.UI.toastShow("found: " .. tostring(name), SaB.Theme.OK, 3)
            W.collLog("", SaB.Theme.DIM)
        else
            W.UI.toastShow("nothing named trampoline/treadmill", SaB.Theme.WARN, 3)
        end
    end, { width = 0.5, color = SaB.Theme.ACC })
    W.UI.button(row, "GO TRAIN (AFK)", function() SaB.Extras.goTrain() end,
        { width = 0.5, color = SaB.Theme.ON })
end
W.afkLine = W.UI.label(W.afkSection, "afk: off", SaB.Theme.DIM, { size = 10 })

-- ---------------- ACTIVITY LOG ----------------
W.actSection = W.UI.section(W.eggPage, "Activity", SaB.Theme.DIM)
W.eggLog = W.UI.log(W.actSection, 150)
W.eggLogAdd, W.eggLogClear = W.eggLog.add, W.eggLog.clear
W.eggLog = W.eggLogAdd

--==============================================================
--  REFRESH (runs once a second while the Eggs tab is open)
--==============================================================
W.lastCounts = { total = -1, matching = -1 }

function W.Pages.refreshEggs()
    local list = SaB.Scanner.list or {}
    local total, matching, unknown = SaB.Scanner.counts()

    W.statusLabel.Text = ("detected %d   •   matching %d   •   delivered %d"):format(
        total, matching, W.Farm.stats.delivered)
    W.filterLine.Text = ("filters: %d of %d eggs pass%s"):format(
        matching, total, (unknown > 0 and ("   (%d unknown rarity)"):format(unknown) or ""))
    W.filterLine.TextColor3 = (matching > 0) and SaB.Theme.OK or SaB.Theme.WARN

    local st = SaB.Scanner.stats
    W.detectLine.Text = ("scan: %d objects in %.2fs  •  %d watched folders  •  live: %s"):format(
        st.scanned or 0, st.lastDuration or 0, W.Util.tableCount(SaB.Scanner.roots),
        W.CONFIG.EggLiveScan and "ON" or "OFF")

    -- how did we find them?
    local bySource = {}
    for _, rec in ipairs(list) do
        bySource[rec.source] = (bySource[rec.source] or 0) + 1
    end
    local bits = {}
    for _, k in ipairs(W.Util.keys(bySource)) do
        table.insert(bits, ("%s x%d"):format(SaB.Scanner.SOURCE_LABEL[k] or k, bySource[k]))
    end
    W.sourceLine.Text = #bits > 0 and ("found by: " .. table.concat(bits, "  |  "))
        or "found by: nothing yet"

    -- target W.rows, grouped by category (one coloured header per rarity)
    local targets = SaB.Scanner.matching(W.MAX_ROWS)
    local groups, groupOrder = {}, {}
    for _, rec in ipairs(targets) do
        if not groups[rec.rarity] then
            groups[rec.rarity] = {}
            table.insert(groupOrder, rec.rarity)
        end
        table.insert(groups[rec.rarity], rec)
    end
    table.sort(groupOrder, function(a, b) return W.Rarity.tier(a) > W.Rarity.tier(b) end)

    local slot, hIndex = 0, 0
    for _, rarityName in ipairs(groupOrder) do
        hIndex = hIndex + 1
        W.headers[hIndex] = W.headers[hIndex] or makeHeader(hIndex)
        local head = W.headers[hIndex]
        head.Visible = true
        head.LayoutOrder = slot + 1
        head.TextColor3 = W.Rarity.color(rarityName)
        head.Text = ("▸ %s   (%d)"):format(rarityName:upper(), #groups[rarityName])
        slot = slot + 1
        for _, rec in ipairs(groups[rarityName]) do
            slot = slot + 1
            if slot - hIndex > W.MAX_ROWS then break end
            W.rows[slot - hIndex] = W.rows[slot - hIndex] or makeRow(slot - hIndex)
            local rowData = W.rows[slot - hIndex]
            rowData.row.LayoutOrder = slot
            rowData:set(rec)
        end
    end
    for i = slot - hIndex + 1, W.MAX_ROWS do
        if W.rows[i] then W.rows[i]:set(nil) end
    end
    for i = hIndex + 1, #W.headers do
        if W.headers[i] then W.headers[i].Visible = false end
    end

    if #targets == 0 then
        W.targetHint.Visible = true
        if total == 0 then
            W.targetHint.Text = "NO EGGS DETECTED YET.\n" ..
                "1) make sure you are inside the LTM (go through the portal)\n" ..
                "2) press DEEP SCAN NOW (it scans the whole map)\n" ..
                "3) still nothing? open the DIAGNOSTICS tab and send me the report"
            W.targetHint.TextColor3 = SaB.Theme.BAD
        else
            W.targetHint.Text = ("%d eggs detected but none pass your filters - " ..
                "press RESET ALL FILTERS or relax them."):format(total)
            W.targetHint.TextColor3 = SaB.Theme.WARN
        end
    else
        W.targetHint.Visible = false
    end

    -- alerts
    local alertCount = #SaB.Extras.alerts
    if alertCount > 0 then
        local last = SaB.Extras.alerts[alertCount]
        W.alertLine.Text = ("%d rare egg(s) seen  •  last: %s [%s]"):format(
            alertCount, last.name, last.rarity)
        W.alertLine.TextColor3 = W.Rarity.color(last.rarity)
    else
        W.alertLine.Text = ("no %s eggs seen yet"):format(tostring(SaB.Extras.alertRarity()))
        W.alertLine.TextColor3 = SaB.Theme.DIM
    end

    -- islands
    local islands = SaB.Extras.findIslands()
    if #islands == 0 then
        W.islandLine.Visible = true
        W.islandLine.Text = "no islands found (are you inside the LTM?)"
    else
        W.islandLine.Visible = false
    end
    for i = 1, 8 do
        local isl = islands[i]
        if isl then
            W.islandBtns[i] = W.islandBtns[i] or makeIslandBtn(i)
            W.islandBtns[i].island = isl
            local b = W.islandBtns[i].button
            b.Visible = true
            b.Text = ("%s   (%d eggs)"):format(isl.key, SaB.Extras.eggCountOn(isl.key))
            b.BackgroundColor3 = SaB.Extras.islandColor(isl.key)
            b.TextColor3 = Color3.fromRGB(12, 12, 16)
        elseif W.islandBtns[i] then
            W.islandBtns[i].button.Visible = false
        end
    end

    -- afk
    W.afkLine.Text = W.CONFIG.AfkJump
        and ("afk: jumping every %ss%s"):format(tostring(W.CONFIG.AfkJumpInterval),
            (W.CONFIG.AfkTrampolineName ~= "" and ("  on " .. W.CONFIG.AfkTrampolineName) or ""))
        or "afk: off"
    W.afkLine.TextColor3 = W.CONFIG.AfkJump and SaB.Theme.OK or SaB.Theme.DIM

    -- farm info
    local base = W.Farm.Base.get()
    W.baseLine.Text = base and ("base: %s   (%.0f, %.0f, %.0f)"):format(
        base.source, base.pos.X, base.pos.Y, base.pos.Z) or "base: NOT FOUND - press SET BASE HERE"
    W.baseLine.TextColor3 = base and SaB.Theme.DIM or SaB.Theme.BAD
    W.farmStatsLine.Text = ("delivered %d   •   failed %d   •   last: %s   •   grab method: %s"):format(
        W.Farm.stats.delivered, W.Farm.stats.failed, W.Farm.stats.lastEgg, W.Farm.Pickup.lastMethod)

    if total ~= W.lastCounts.total then
        W.lastCounts.total = total
        if total > 0 then
            W.eggLog(("%d eggs tracked (%d match your filters)"):format(total, matching), SaB.Theme.ACC)
        end
    end
end

W.Farm.onStatus = function(text, color)
    pcall(function()
        W.statusLine.Text = "farm: " .. tostring(text)
        W.statusLine.TextColor3 = color or SaB.Theme.DIM
    end)
end

Log.onAdd(function(text, color, tag)
    if tag == "EGG" or tag == "FARM" then
        pcall(W.eggLog, text, color)
    end
end)

--==============================================================
--  PAGE 2 : CODE SNIPER
--==============================================================
W.sniperPage = W.UI.addTab("Sniper")
W.UI.label(W.sniperPage, "CODE SNIPER - listens to SpyderSammy and types the code for you",
    SaB.Theme.ACC, { bold = true })

W.sniperStatus = W.UI.label(W.sniperPage, "status: listening...", SaB.Theme.DIM)
SaB.Sniper.statusFn = function(t, c)
    pcall(function()
        W.sniperStatus.Text = ("status: %s\n|  type: %s  |  captured: %d"):format(
            t, SaB.Sniper.describeHint(SaB.Sniper.hint), SaB.Sniper.captured)
        W.sniperStatus.TextColor3 = c or SaB.Theme.DIM
    end)
end

W.snipMain = W.UI.section(W.sniperPage, "Main", SaB.Theme.ACC)
W.UI.toggle(W.snipMain, "Sniper enabled", W.CONFIG.SniperEnabled, function(v) W.CONFIG.SniperEnabled = v end)
W.UI.toggle(W.snipMain, "TEST: listen to everyone", W.CONFIG.SniperListenEveryone, function(v)
    W.CONFIG.SniperListenEveryone = v
    if v then W.UI.toastShow("type in chat: code is TACO BOOST 123", SaB.Theme.WARN, 4) end
end)
W.UI.toggle(W.snipMain, "Auto press Submit", W.CONFIG.SniperAutoSubmit, function(v)
    W.CONFIG.SniperAutoSubmit = v
end)

W.typeValues = {}
for _, t in ipairs(SaB.Sniper.CODE_TYPES) do table.insert(W.typeValues, t.name) end
W.UI.cycle(W.snipMain, "Code type", W.typeValues, W.CONFIG.SniperTypeIndex, function(i)
    W.CONFIG.SniperTypeIndex = i
    SaB.Sniper.hint = SaB.Sniper.hintFromIndex(i)
    SaB.Sniper.hintFromChat = false
end)

W.startBtn = W.UI.button(W.snipMain, "▶  START capturing", function()
    SaB.Sniper.hintFromChat = false
    SaB.Sniper.startSession()
    W.UI.toastShow("capturing started - say the code!", SaB.Theme.OK, 2)
end, { h = 38, color = SaB.Theme.ON })
W.fmtJoined = true
-- (moved into the widget table)
W.fmtBtn = W.UI.button(W.snipMain, "Format:  JOINED (TACOBOOST)", function()
    fmtJoined = not W.fmtJoined
    W.CONFIG.SniperJoinCode = W.fmtJoined
    W.fmtBtn.Text = W.fmtJoined and "Format:  JOINED (TACOBOOST)" or 'Format:  SPACED ("TACO BOOST")'
end, { color = SaB.Theme.BTN })
W.UI.button(W.snipMain, "■  STOP capturing", function() SaB.Sniper.finalizeCode() end)

W.snipFilters = W.UI.section(W.sniperPage, "Options", SaB.Theme.DIM)
W.timeoutInput = W.UI.input(W.snipFilters, "silence timeout (seconds)",
    tostring(W.CONFIG.SniperSilenceTimeout), function(text)
        local n = tonumber(text)
        if n then W.CONFIG.SniperSilenceTimeout = W.Util.clamp(n, 1, 60) end
    end)
W.UI.input(W.snipFilters, "code box path (optional, auto-detect when empty)",
    W.CONFIG.CodeBoxPathOverride, function(text) W.CONFIG.CodeBoxPathOverride = text end)

W.testSection = W.UI.section(W.sniperPage, "Test zone (no event needed)",
    Color3.fromRGB(255, 190, 60))
W.testInput = W.UI.input(W.testSection, "type a word (e.g. TACO)", "")
W.UI.button(W.testSection, "1) Feed this word", function()
    local w = W.testInput.Text
    if w == "" then return end
    W.testInput.Text = ""
    SaB.Sniper.handleMessage(w, SaB.LocalPlayer.UserId, SaB.LocalPlayer.Name, true)
end)
W.UI.button(W.testSection, "2) Start session (marker)", function()
    SaB.Sniper.handleMessage("code is", SaB.LocalPlayer.UserId, SaB.LocalPlayer.Name, true)
end)
W.UI.button(W.testSection, "3) DEMO: two words", function()
    task.spawn(function()
        for _, w in ipairs({ "the code is two words", "TACO", "BOOST" }) do
            SaB.Sniper.handleMessage(w, SaB.LocalPlayer.UserId, SaB.LocalPlayer.Name, true)
            task.wait(0.8)
        end
        W.UI.toastShow("demo finished - check the log", SaB.Theme.OK, 2)
    end)
end)
W.UI.button(W.testSection, "3b) DEMO: words + numbers", function()
    task.spawn(function()
        for _, w in ipairs({ "the code is letters and numbers", "TACO", "BOOST", "123" }) do
            SaB.Sniper.handleMessage(w, SaB.LocalPlayer.UserId, SaB.LocalPlayer.Name, true)
            task.wait(0.8)
        end
        W.UI.toastShow("demo finished - check the log", SaB.Theme.OK, 2)
    end)
end)
W.UI.button(W.testSection, "4) Force finish now", function() SaB.Sniper.finalizeCode() end)

W.sniperLogBox = W.UI.log(W.sniperPage, 170)
W.sniperLog = W.sniperLogBox.add
SaB.Sniper.logFn = function(text, color) pcall(W.sniperLog, text, color) end
W.sniperLog("sniper ready - target: SpyderSammy (id " .. W.CONFIG.SniperTargetUserId .. ")", SaB.Theme.ACC)
W.sniperLog("waiting for a marker ('code is') or a type announcement ...", SaB.Theme.DIM)
W.sniperLog("tip: pick the CODE TYPE above, or let the sniper read it from Sammy", SaB.Theme.DIM)

--==============================================================
--  PAGE 3 : DIAGNOSTICS
--==============================================================
W.Diag = {}
SaB.Diag = W.Diag
W.Diag.lastReport = ""

W.diagPage = W.UI.addTab("W.Diag")
W.UI.label(W.diagPage, "DIAGNOSTICS - press REPORT then send me the text (copy or file)",
    SaB.Theme.ACC, { bold = true })

local function line(out, text)
    table.insert(out, tostring(text))
end

function W.Diag.buildReport()
    local out = {}
    local lp = SaB.LocalPlayer
    line(out, "=== SaB Suite report ===")
    line(out, ("version   : %s"):format(SaB.VERSION))
    line(out, ("date      : %s"):format(os.date("%Y-%m-%d %H:%M:%S")))
    line(out, ("placeId   : %s   jobId: %s"):format(tostring(game.PlaceId), tostring(game.JobId)))
    line(out, ("player    : %s (%s)"):format(lp.Name, tostring(lp.UserId)))
    line(out, ("egg DB    : %d known eggs, source: %s"):format(#SaB.EggDB.EGGS, SaB.EggDB.SOURCE))
    line(out, "")

    -- 1) top level of the workspace
    line(out, "--- WORKSPACE (top level) ---")
    for _, c in ipairs(SaB.Services.Workspace:GetChildren()) do
        local n = 0
        pcall(function() n = #c:GetChildren() end)
        line(out, ("  %s  [%s]  children=%d"):format(c.Name, c.ClassName, n))
    end
    line(out, "")

    -- 2) second level (folders where eggs usually live)
    line(out, "--- WORKSPACE (2nd level, first 200) ---")
    local printed = 0
    for _, c in ipairs(SaB.Services.Workspace:GetChildren()) do
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
    for _, d in ipairs(SaB.Services.Workspace:GetDescendants()) do
        if eggish >= 120 then break end
        local n = W.Util.lower(d.Name)
        if (d:IsA("Model") or d:IsA("BasePart") or d:IsA("Folder"))
            and (SaB.EggDB.isEggWord(n) or SaB.EggDB.lookup(d.Name)) then
            line(out, ("  %s  [%s]  parent=%s"):format(
                W.Util.path(d), d.ClassName, d.Parent and d.Parent.Name or "?"))
            eggish = eggish + 1
        end
    end
    if eggish == 0 then line(out, "  (none)") end
    line(out, "")

    -- 4) what our scanner actually found
    line(out, "--- SCANNER FINDINGS ---")
    local list = SaB.Scanner.list or {}
    line(out, ("  %d eggs tracked"):format(#list))
    for _, rec in ipairs(list) do
        line(out, ("  %s | %s | island=%s | via=%s | score=%d | path=%s"):format(
            rec.name, rec.rarity, tostring(rec.island), rec.source, rec.score, rec.path))
    end
    line(out, ("  roots watched: %d"):format(W.Util.tableCount(SaB.Scanner.roots)))
    line(out, ("  last scan: %d objects in %.2fs"):format(
        SaB.Scanner.stats.scanned or 0, SaB.Scanner.stats.lastDuration or 0))
    line(out, "")

    -- 5) prompts we have seen
    line(out, "--- PROXIMITY PROMPTS SEEN ---")
    if #SaB.Scanner.promptLog == 0 then
        line(out, "  (none yet - walk up to an egg / an NPC)")
    else
        for _, l in ipairs(SaB.Scanner.promptLog) do line(out, "  " .. l) end
    end
    line(out, "")

    -- 6) remotes that look useful
    line(out, "--- REMOTES (collect / pick / egg / hatch) ---")
    local remotes = 0
    for _, d in ipairs(SaB.Services.ReplicatedStorage:GetDescendants()) do
        if remotes >= 80 then break end
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
            local n = W.Util.lower(d.Name)
            if n:find("collect") or n:find("pick") or n:find("egg") or n:find("hatch")
                or n:find("grab") or n:find("take") or n:find("steal") then
                line(out, "  " .. W.Util.path(d))
                remotes = remotes + 1
            end
        end
    end
    if remotes == 0 then line(out, "  (none)") end
    line(out, "")

    -- 7) base candidates
    line(out, "--- BASE CANDIDATES ---")
    local bp, src = W.Farm.Base.find()
    line(out, ("  found: %s   source: %s"):format(
        bp and ("%.0f, %.0f, %.0f"):format(bp.X, bp.Y, bp.Z) or "NO", tostring(src)))
    line(out, "")

    -- 8) character / carrying
    line(out, "--- PLAYER ---")
    local hrp = W.Util.getHRP()
    line(out, ("  position: %s"):format(hrp and ("%.0f, %.0f, %.0f"):format(
        hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "no character"))
    line(out, ("  carrying: %s"):format(tostring(W.Farm.Carry.what())))
    local attrs = W.Util.getAttributes(lp)
    local attrBits = {}
    for k, v in pairs(attrs) do
        table.insert(attrBits, ("%s=%s"):format(k, tostring(v)))
    end
    line(out, ("  attributes: %s"):format(#attrBits > 0 and table.concat(attrBits, ", ") or "(none)"))
    line(out, "")
    line(out, "=== end of report ===")

    local text = table.concat(out, "\n")
    W.Diag.lastReport = text
    return text
end

W.diagLog = W.UI.log(W.diagPage, 220).add

local function dumpToLog(title, items)
    W.diagLog(("=== %s (%d) ==="):format(title, #items), SaB.Theme.ACC)
    for i = 1, math.min(#items, 80) do W.diagLog("  " .. tostring(items[i]), SaB.Theme.TEXT) end
end

W.diagSection = W.UI.section(W.diagPage, "Reports", SaB.Theme.ACC)
W.UI.button(W.diagSection, "▶  BUILD FULL REPORT", function()
    local text = W.Diag.buildReport()
    W.diagLog("=== FULL REPORT ===", SaB.Theme.ACC)
    for l in (text .. "\n"):gmatch("([^\n]*)\n") do
        W.diagLog(l, SaB.Theme.TEXT)
    end
    print(text)
    W.UI.toastShow("report built - copy / save it below", SaB.Theme.OK, 3)
end, { h = 36, color = SaB.Theme.ACC })

do
    local row = W.UI.row(W.diagSection, 30)
    W.UI.button(row, "COPY report", function()
        if W.Diag.lastReport == "" then W.Diag.buildReport() end
        if W.Util.clipboard(W.Diag.lastReport) then
            W.UI.toastShow("copied to clipboard", SaB.Theme.OK, 2)
        else
            W.UI.toastShow("no clipboard on this executor - use SAVE", SaB.Theme.BAD, 3)
        end
    end, { width = 0.5, color = SaB.Theme.ON })
    W.UI.button(row, "SAVE to file", function()
        if W.Diag.lastReport == "" then W.Diag.buildReport() end
        if W.Util.writeFile("egg_report.txt", W.Diag.lastReport) then
            W.UI.toastShow("saved to SaBSuite/egg_report.txt", SaB.Theme.OK, 3)
        else
            W.UI.toastShow("writefile not supported here", SaB.Theme.BAD, 3)
        end
    end, { width = 0.5 })
end

W.dumpSection = W.UI.section(W.diagPage, "Quick dumps", SaB.Theme.DIM)
W.UI.button(W.dumpSection, "Dump: names containing 'egg'", function()
    local items = {}
    for _, d in ipairs(SaB.Services.Workspace:GetDescendants()) do
        if W.Util.has(d.Name, "egg") then
            table.insert(items, ("%s [%s] parent=%s"):format(
                W.Util.path(d), d.ClassName, d.Parent and d.Parent.Name or "?"))
        end
    end
    dumpToLog("EGG NAMES", items)
end)
W.UI.button(W.dumpSection, "Dump: island / LTM folders", function()
    local items = {}
    for _, d in ipairs(SaB.Services.Workspace:GetDescendants()) do
        if d:IsA("Folder") or d:IsA("Model") then
            if SaB.EggDB.isContainerWord(d.Name) then
                local n = 0
                pcall(function() n = #d:GetChildren() end)
                table.insert(items, ("%s [%s] children=%d"):format(W.Util.path(d), d.ClassName, n))
            end
        end
    end
    dumpToLog("CONTAINERS", items)
end)
W.UI.button(W.dumpSection, "Dump: proximity prompts in the map", function()
    local items = {}
    for _, d in ipairs(SaB.Services.Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            table.insert(items, ("%s | action='%s' | hold=%.1f | parent=%s"):format(
                W.Util.path(d), tostring(d.ActionText), tonumber(d.HoldDuration) or 0,
                W.Util.path(d.Parent)))
        end
    end
    dumpToLog("PROMPTS", items)
end)
W.UI.button(W.dumpSection, "Dump: remotes", function()
    local items = {}
    for _, d in ipairs(SaB.Services.ReplicatedStorage:GetDescendants()) do
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
            table.insert(items, W.Util.path(d))
        end
    end
    dumpToLog("REMOTES", items)
end)
W.UI.button(W.dumpSection, "Dump: my attributes + carrying", function()
    local items = {}
    for k, v in pairs(W.Util.getAttributes(SaB.LocalPlayer)) do
        table.insert(items, ("player.%s = %s"):format(k, tostring(v)))
    end
    local char = W.Util.getChar()
    if char then
        for _, d in ipairs(char:GetDescendants()) do
            if W.Util.has(d.Name, "egg") or W.Util.has(d.Name, "carry") or W.Util.has(d.Name, "hold") then
                table.insert(items, "character has: " .. W.Util.path(d))
            end
        end
    end
    table.insert(items, "carrying = " .. tostring(W.Farm.Carry.what()))
    dumpToLog("PLAYER", items)
end)
W.UI.button(W.dumpSection, "Dump: what the scanner is tracking", function()
    local items = {}
    for _, rec in ipairs(SaB.Scanner.list or {}) do
        table.insert(items, ("%s | %s | island=%s | via=%s | score=%d | %s"):format(
            rec.name, rec.rarity, tostring(rec.island), rec.source, rec.score, rec.path))
    end
    dumpToLog("TRACKED EGGS", items)
end)

--==============================================================
--  PAGE 4 : SETTINGS
--==============================================================
W.setPage = W.UI.addTab("Settings")
W.UI.label(W.setPage, "SETTINGS", SaB.Theme.ACC, { bold = true })

W.uiSection = W.UI.section(W.setPage, "Interface", SaB.Theme.ACC)
W.UI.cycle(W.uiSection, "Label size", { "normal", "big", "huge" }, 1, function(i)
    W.CONFIG.EggLabelScale = ({ 1.0, 1.25, 1.5 })[i]
    SaB.ESP.rebuild()
end)
W.UI.input(W.uiSection, "ESP max distance (studs)", tostring(W.CONFIG.EggEspMaxDistance), function(text)
    local n = tonumber(text)
    if n then
        W.CONFIG.EggEspMaxDistance = W.Util.clamp(n, 200, 20000)
        SaB.ESP.rebuild()
    end
end)
W.UI.button(W.uiSection, "Reset window position", function() W.UI.resetPosition() end)
W.UI.button(W.uiSection, "Re-center + reopen", function()
    W.UI.show()
    W.UI.setMinimized(false)
    W.UI.resetPosition()
end)
W.UI.button(W.uiSection, "Clear all ESP labels", function()
    SaB.ESP.clear()
    W.UI.toastShow("labels cleared", SaB.Theme.OK, 2)
end)

W.saveSection = W.UI.section(W.setPage, "Saved settings", SaB.Theme.ACC)
W.saveLine = W.UI.label(W.saveSection, "settings are kept in SaBSuite/settings.txt",
    SaB.Theme.DIM, { size = 10 })
W.UI.toggle(W.saveSection, "Load my settings at startup", W.CONFIG.AutoLoadSettings,
    function(v) W.CONFIG.AutoLoadSettings = v end)
do
    local row = W.UI.row(W.saveSection, 30)
    W.UI.button(row, "SAVE", function()
        local ok, msg = SaB.Extras.save()
        W.saveLine.Text = (ok and "settings saved" or ("could not save: " .. tostring(msg)))
        W.saveLine.TextColor3 = ok and SaB.Theme.OK or SaB.Theme.BAD
        W.UI.toastShow(ok and "settings saved" or "save failed", ok and SaB.Theme.OK or SaB.Theme.BAD, 3)
    end, { width = 0.34, color = SaB.Theme.ON })
    W.UI.button(row, "LOAD", function()
        local ok, msg = SaB.Extras.load()
        W.saveLine.Text = tostring(msg)
        W.saveLine.TextColor3 = ok and SaB.Theme.OK or SaB.Theme.WARN
        W.UI.toastShow(tostring(msg), ok and SaB.Theme.OK or SaB.Theme.WARN, 3)
    end, { width = 0.33 })
    W.UI.button(row, "DELETE", function()
        local ok, msg = SaB.Extras.delete()
        W.saveLine.Text = tostring(msg)
        W.UI.toastShow(tostring(msg), ok and SaB.Theme.OK or SaB.Theme.WARN, 3)
    end, { width = 0.33, color = SaB.Theme.OFF })
end

W.infoSection = W.UI.section(W.setPage, "Info", SaB.Theme.DIM)
W.UI.label(W.infoSection,
    ("version %s   •   %d known eggs (Update 68 LTM)\n"):format(SaB.VERSION, #SaB.EggDB.EGGS)
    .. "Egg data: Steal a Brainrot Wiki - 'Jump for Eggs LTM'.\n"
    .. "W.Rarity colours: one colour per category (Secret = gold, "
    .. "Brainrot God = pink, Mythic = red, ...).\n"
    .. "Islands: Grass < Desert < Arctic < Cave < Aquatic < Lava < Heavenly.",
    SaB.Theme.DIM, { size = 10 })

W.UI.button(W.infoSection, "UNLOAD script (stop everything)", function()
    SaB.Running = false
    W.CONFIG.EggAutoFarm = false
    W.CONFIG.EggESPEnabled = false
    W.CONFIG.SniperEnabled = false
    pcall(function() SaB.ESP.clear() end)
    pcall(function() W.UI.gui:Destroy() end)
    W.Util.notify("SaB Suite", "unloaded", 3)
end, { color = SaB.Theme.OFF })

--==============================================================
--  STARTUP
--==============================================================
W.UI.layoutTabs()
W.UI.selectTab("Eggs")

task.spawn(function()
    while SaB.Running do
        task.wait(1)
        pcall(function()
            if W.UI.currentTab == "Eggs" and W.UI.gui.Enabled then
                W.Pages.refreshEggs()
            end
        end)
    end
end)

-- first paint
task.spawn(function()
    task.wait(1.2)
    pcall(W.Pages.refreshEggs)
end)

return W.Pages
