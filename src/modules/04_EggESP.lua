--==============================================================
--  EGG ESP  (the labels you see above every egg)
--
--  Every label is built the same way so the list is easy to read:
--
--        +-----------------------------+
--        |      Dragon Cannelloni      |   <- name, colour = rarity
--        |   [ SECRET ]  Heavenly      |   <- category chip + island
--        |      820m     1:45          |   <- distance + despawn timer
--        +-----------------------------+
--
--  Everything is centred over the egg, the box auto-fits the text,
--  and the colour always matches the rarity (no more grey "unknown").
--==============================================================

local ESP = {}
SaB.ESP = ESP

local CONFIG = SaB.CONFIG
local Util   = SaB.Util
local Rarity = SaB.Rarity
local Scanner = SaB.Scanner

ESP.parts   = {}      -- [obj] = { bb, frame, nameLbl, chip, chipLbl, infoLbl, highlight }
ESP.MAX     = 120     -- safety: never build more than this many labels
ESP.TEXT_SCALE = 1

do
    local s = Util.clamp(math.min(Camera.ViewportSize.X, Camera.ViewportSize.Y) / 720, 0.85, 1.4)
    ESP.TEXT_SCALE = s
end

local function scale(n)
    return n * ESP.TEXT_SCALE * Util.clamp(CONFIG.EggLabelScale, 0.6, 1.8)
end

local function adorneeFor(rec)
    local obj = rec.obj
    if obj:IsA("BasePart") then return obj end
    if obj.PrimaryPart then return obj.PrimaryPart end
    local ok, part = pcall(function() return obj:FindFirstChildWhichIsA("BasePart", true) end)
    if ok and part then return part end
    return nil
end

local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = inst
    return c
end

--==============================================================
--  BUILD ONE LABEL
--==============================================================
function ESP.build(rec)
    if ESP.parts[rec.obj] then return ESP.parts[rec.obj] end
    local adornee = adorneeFor(rec)
    if not adornee then return nil end

    local color = Rarity.color(rec.rarity)
    local s = ESP.TEXT_SCALE

    local bb = Instance.new("BillboardGui")
    bb.Name = "SaB_EggLabel"
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 180 * s, 0, 64 * s)
    bb.StudsOffset = Vector3.new(0, (rec.height or 2) / 2 + 2.4, 0)
    bb.AlwaysOnTop = CONFIG.EggAlwaysOnTop
    bb.MaxDistance = CONFIG.EggEspMaxDistance      -- islands are far away!
    bb.LightInfluence = 0                          -- keep the text readable
    bb.ResetOnSpawn = false
    bb.ClipsDescendants = false
    bb.Enabled = true

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
    frame.BackgroundTransparency = 0.32
    frame.BorderSizePixel = 0
    frame.Parent = bb
    corner(frame, 8 * s)

    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 2
    stroke.Transparency = 0.15
    stroke.Parent = frame

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4 * s)
    pad.PaddingBottom = UDim.new(0, 3 * s)
    pad.PaddingLeft = UDim.new(0, 6 * s)
    pad.PaddingRight = UDim.new(0, 6 * s)
    pad.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 1)
    layout.Parent = frame

    -- row 1 : name (centred, rarity colour)
    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1, 0, 0, 17 * s)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = scale(14)
    nameLbl.TextColor3 = color
    nameLbl.TextStrokeTransparency = 0.35
    nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Text = rec.name or "?"
    nameLbl.LayoutOrder = 1
    nameLbl.Parent = frame

    -- row 2 : chip + island + income
    local row2 = Instance.new("Frame")
    row2.BackgroundTransparency = 1
    row2.Size = UDim2.new(1, 0, 0, 15 * s)
    row2.LayoutOrder = 2
    row2.Parent = frame

    local row2Layout = Instance.new("UIListLayout")
    row2Layout.FillDirection = Enum.FillDirection.Horizontal
    row2Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    row2Layout.VerticalAlignment = Enum.VerticalAlignment.Center
    row2Layout.Padding = UDim.new(0, 4 * s)
    row2Layout.Parent = row2

    -- category chip (coloured pill, never grey unless really unknown)
    local chip = Instance.new("TextLabel")
    chip.BackgroundColor3 = color
    chip.BackgroundTransparency = 0.12
    chip.Font = Enum.Font.GothamBold
    chip.TextSize = scale(10)
    chip.TextColor3 = Color3.fromRGB(10, 10, 14)
    chip.TextXAlignment = Enum.TextXAlignment.Center
    chip.Size = UDim2.new(0, 56 * s, 0, 13 * s)
    chip.Text = " " .. (Rarity.SHORT[rec.rarity] or "???") .. " "
    chip.AutomaticSize = Enum.AutomaticSize.X
    chip.Parent = row2
    corner(chip, 6 * s)

    local infoLbl = Instance.new("TextLabel")
    infoLbl.BackgroundTransparency = 1
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = scale(10)
    infoLbl.TextColor3 = Color3.fromRGB(226, 231, 240)
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.TextStrokeTransparency = 0.5
    infoLbl.AutomaticSize = Enum.AutomaticSize.X
    infoLbl.Size = UDim2.new(0, 0, 0, 13 * s)
    infoLbl.Text = (rec.island and (rec.island .. "  ") or "")
        .. (rec.incomeText and (rec.incomeText .. "  ") or "")
    infoLbl.Parent = row2

    -- row 3 : distance + timer
    local info2 = Instance.new("TextLabel")
    info2.BackgroundTransparency = 1
    info2.Size = UDim2.new(1, 0, 0, 13 * s)
    info2.Font = Enum.Font.Gotham
    info2.TextSize = scale(10)
    info2.TextColor3 = Color3.fromRGB(190, 198, 214)
    info2.TextStrokeTransparency = 0.5
    info2.TextXAlignment = Enum.TextXAlignment.Center
    info2.Text = ""
    info2.LayoutOrder = 3
    info2.Parent = frame

    bb.Parent = adornee

    local part = {
        bb = bb, frame = frame, stroke = stroke,
        nameLbl = nameLbl, chip = chip, infoLbl = infoLbl, info2 = info2,
        row2 = row2,
    }

    if CONFIG.EggHighlight then
        ESP.addHighlight(rec, part)
    end

    ESP.parts[rec.obj] = part
    ESP.resize(part, rec)
    return part
end

function ESP.addHighlight(rec, part)
    if part.highlight then return end
    local ok = pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "SaB_EggHighlight"
        h.Adornee = rec.obj
        h.FillColor = Rarity.color(rec.rarity)
        h.FillTransparency = 0.72
        h.OutlineColor = Rarity.color(rec.rarity)
        h.OutlineTransparency = 0
        h.DepthMode = CONFIG.EggAlwaysOnTop
            and Enum.HighlightDepthMode.AlwaysOnTop
            or Enum.HighlightDepthMode.Occluded
        h.Parent = part.bb
        part.highlight = h
    end)
    return ok
end

function ESP.removeHighlight(part)
    if part and part.highlight then
        pcall(function() part.highlight:Destroy() end)
        part.highlight = nil
    end
end

-- fit the box to the text (looks much tidier than a fixed wide box)
function ESP.resize(part, rec)
    local s = ESP.TEXT_SCALE
    local nameW = part.nameLbl.TextBounds.X
    if nameW <= 0 then nameW = 120 * s end
    local w = math.max(nameW + 26 * s, (part.infoLbl.TextBounds.X or 0) + 70 * s, 96 * s)
    local h = (CONFIG.EggEspName and 17 * s or 0)
        + (CONFIG.EggEspRarity and 15 * s or 0)
        + ((CONFIG.EggEspDistance or CONFIG.EggEspIsland) and 13 * s or 0)
        + 8 * s
    part.bb.Size = UDim2.new(0, math.min(w, 420 * s), 0, math.max(h, 26 * s))
end

--==============================================================
--  ATTACH / DETACH
--==============================================================
function ESP.attach(rec)
    if not rec or not rec.obj or rec.obj.Parent == nil then return end
    if ESP.parts[rec.obj] then return end
    if Util.tableCount(ESP.parts) >= ESP.MAX then return end
    pcall(function() ESP.build(rec) end)
end

function ESP.detach(rec)
    if not rec then return end
    local part = ESP.parts[rec.obj]
    if not part then return end
    pcall(function()
        if part.bb then part.bb:Destroy() end
    end)
    ESP.parts[rec.obj] = nil
end

function ESP.detachByObj(obj)
    local part = ESP.parts[obj]
    if not part then return end
    pcall(function() if part.bb then part.bb:Destroy() end end)
    ESP.parts[obj] = nil
end

function ESP.clear()
    for obj, part in pairs(ESP.parts) do
        pcall(function() if part.bb then part.bb:Destroy() end end)
        ESP.parts[obj] = nil
    end
end

function ESP.rebuild()
    ESP.clear()
    for _, rec in pairs(Scanner.eggs) do
        ESP.attach(rec)
    end
end

--==============================================================
--  LIVE UPDATE
--==============================================================
function ESP.update()
    local enabled = CONFIG.EggESPEnabled
    for obj, rec in pairs(Scanner.eggs) do
        if obj.Parent == nil then
            Scanner.eggs[obj] = nil
            ESP.detach(rec)
        elseif enabled then
            ESP.attach(rec)
        elseif ESP.parts[obj] then
            ESP.detach(rec)
        end
    end

    if not enabled then return end

    for obj, part in pairs(ESP.parts) do
        local rec = Scanner.eggs[obj]
        if not rec then
            ESP.detachByObj(obj)
        else
            pcall(function()
                part.nameLbl.Visible = CONFIG.EggEspName
                part.row2.Visible    = CONFIG.EggEspRarity or CONFIG.EggEspIsland
                part.infoLbl.Visible = CONFIG.EggEspIsland

                -- keep the colour in sync (rarity can be learned later)
                local color = Rarity.color(rec.rarity)
                part.nameLbl.TextColor3 = color
                part.stroke.Color = color
                part.chip.BackgroundColor3 = color
                part.chip.Text = " " .. (Rarity.SHORT[rec.rarity] or "???") .. " "

                if CONFIG.EggEspIsland then
                    part.infoLbl.Text = (rec.island and (rec.island .. "  ") or "")
                        .. (rec.incomeText and (rec.incomeText .. "  ") or "")
                else
                    part.infoLbl.Text = rec.incomeText or ""
                end

                local bits = {}
                if CONFIG.EggEspDistance then
                    table.insert(bits, Util.formatDistance(rec.dist))
                end
                if rec.timerLeft and rec.timerLeft > 0 then
                    table.insert(bits, Util.formatClock(rec.timerLeft))
                end
                part.info2.Text = table.concat(bits, "   ")
                part.info2.Visible = #bits > 0

                -- far away eggs fade a little so the screen stays readable
                local far = rec.dist > 1200
                part.frame.BackgroundTransparency = far and 0.5 or 0.32

                if CONFIG.EggHighlight then
                    if not part.highlight then ESP.addHighlight(rec, part) end
                    if part.highlight then
                        part.highlight.FillColor = color
                        part.highlight.OutlineColor = color
                        part.highlight.DepthMode = CONFIG.EggAlwaysOnTop
                            and Enum.HighlightDepthMode.AlwaysOnTop
                            or Enum.HighlightDepthMode.Occluded
                    end
                else
                    ESP.removeHighlight(part)
                end
            end)
        end
    end
end

return ESP
