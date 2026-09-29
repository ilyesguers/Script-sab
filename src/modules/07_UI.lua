--==============================================================
--  UI FRAMEWORK
--
--  One window: drag it (mouse + touch) , minimise it , close it.
--  Widgets used by every page: sections, labels, buttons, toggles,
--  cycle buttons, text inputs, logs and coloured chips.
--
--  The minimise bug from v1 is fixed: the whole body (tabs + pages)
--  lives inside ONE frame that we simply show / hide.
--==============================================================

local UI = {}
SaB.UI = UI

local Util = SaB.Util
local T    = SaB.Theme

local UserInputService = SaB.Services.UserInputService

-- ---------- sizing ----------
local vw, vh = Camera.ViewportSize.X, Camera.ViewportSize.Y
UI.vw, UI.vh = vw, vh
UI.S    = Util.clamp(math.min(vw, vh) / 720, 0.80, 1.35)
local S = UI.S

UI.W = Util.clamp(vw * 0.94, 316, 560)
UI.H = Util.clamp(vh * 0.84, 420, 700)
UI.HEADER = math.floor(44 * S)
UI.TABS   = math.floor(36 * S)

UI.pages = {}
UI.tabButtons = {}
UI.tabOrder = {}
UI.minimized = false

local function s(n) return n * S end
UI.s = s

-- ---------- root ----------
local function uiParent()
    local ok, res = pcall(function()
        if typeof(gethui) == "function" then return gethui() end
    end)
    if ok and res then return res end
    return SaB.PlayerGui
end

local gui = Instance.new("ScreenGui")
gui.Name = "SaBSuite"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 9999
gui.Parent = uiParent()
UI.gui = gui

--==============================================================
--  WINDOW
--==============================================================
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(UI.W, UI.H)
main.Position = UDim2.new(0.5, -UI.W / 2, 0.5, -UI.H / 2)
main.BackgroundColor3 = T.BG
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = false
main.Parent = gui
UI.main = main

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 14)
    c.Parent = main
    local st = Instance.new("UIStroke")
    st.Color = T.ACC
    st.Thickness = 1.5
    st.Transparency = 0.55
    st.Parent = main
end

-- ---------- header ----------
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, UI.HEADER)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = T.BG2
header.BorderSizePixel = 0
header.Active = true
header.Parent = main
UI.header = header

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 14)
    c.Parent = header
end

-- the bottom corners of the header should only be round when minimised
local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 14)
headerFix.Position = UDim2.new(0, 0, 1, -14)
headerFix.BackgroundColor3 = T.BG2
headerFix.BorderSizePixel = 0
headerFix.Parent = header
UI.headerFix = headerFix

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = s(15)
title.TextColor3 = T.TEXT
title.Text = "  Steal a Brainrot Suite"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Size = UDim2.new(1, -s(110), 1, 0)
title.Parent = header
UI.title = title

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = s(9)
subtitle.TextColor3 = T.DIM
subtitle.Text = "  v" .. SaB.VERSION .. "  |  drag the bar"
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Size = UDim2.new(1, -s(110), 0, s(11))
subtitle.Position = UDim2.new(0, 0, 1, -s(13))
subtitle.Parent = header

local function headerButton(text, x)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = T.BTN2
    b.Font = Enum.Font.GothamBold
    b.TextSize = s(15)
    b.TextColor3 = T.TEXT
    b.Text = text
    b.Size = UDim2.fromOffset(s(34), s(30))
    b.Position = UDim2.new(1, x, 0.5, -s(15))
    b.AutoButtonColor = true
    b.Parent = header
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b
    local st = Instance.new("UIStroke")
    st.Color = T.ACC
    st.Transparency = 0.7
    st.Parent = b
    return b
end

UI.minBtn  = headerButton("–", -s(76))
UI.closeBtn = headerButton("✕", -s(38))

--==============================================================
--  BODY  (everything below the header - this is what we hide)
--==============================================================
local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, 0, 1, -UI.HEADER)
body.Position = UDim2.new(0, 0, 0, UI.HEADER)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ClipsDescendants = true
body.Parent = main
UI.body = body

local tabRow = Instance.new("Frame")
tabRow.Name = "Tabs"
tabRow.Size = UDim2.new(1, 0, 0, UI.TABS)
tabRow.BackgroundTransparency = 1
tabRow.Parent = body
UI.tabRow = tabRow

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -s(12), 1, -(UI.TABS + s(8)))
content.Position = UDim2.new(0, s(6), 0, UI.TABS + s(4))
content.BackgroundTransparency = 1
content.Parent = body
UI.content = content

--==============================================================
--  MINIMISE / CLOSE / DRAG
--==============================================================
function UI.setMinimized(state)
    UI.minimized = state and true or false
    body.Visible = not UI.minimized
    headerFix.Visible = UI.minimized
    main.Size = UI.minimized and UDim2.fromOffset(UI.W, UI.HEADER) or UDim2.fromOffset(UI.W, UI.H)
    UI.minBtn.Text = UI.minimized and "+" or "–"
    UI.minBtn.BackgroundColor3 = UI.minimized and T.ACC or T.BTN2
end

-- click handler that works with mouse AND touch (and never fires twice)
function UI.onClick(btn, cb)
    local last = 0
    local function fire()
        local t = tick()
        if t - last < 0.18 then return end   -- debounce: touch fires 2 events
        last = t
        pcall(cb)
    end
    if btn:IsA("GuiButton") then
        btn.MouseButton1Click:Connect(fire)
        btn.TouchTap:Connect(fire)
    else
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                fire()
            end
        end)
    end
end

UI.onClick(UI.minBtn, function() UI.setMinimized(not UI.minimized) end)

-- floating bubble to bring the window back
local reopen = Instance.new("TextButton")
reopen.Name = "Reopen"
reopen.Size = UDim2.fromOffset(s(50), s(50))
reopen.Position = UDim2.new(0, s(12), 0.45, 0)
reopen.BackgroundColor3 = T.ACC
reopen.Font = Enum.Font.GothamBold
reopen.TextSize = s(20)
reopen.TextColor3 = T.TEXT
reopen.Text = "☰"
reopen.Visible = false
reopen.AutoButtonColor = true
reopen.Parent = gui
UI.reopen = reopen
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = reopen
end

UI.onClick(UI.closeBtn, function()
    gui.Enabled = false
    reopen.Visible = true
end)
UI.onClick(reopen, function()
    gui.Enabled = true
    reopen.Visible = false
end)

function UI.show()
    gui.Enabled = true
    reopen.Visible = false
end

-- ---------- drag ----------
local function makeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
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

makeDraggable(header, main)
makeDraggable(reopen, reopen)

function UI.resetPosition()
    main.Position = UDim2.new(0.5, -UI.W / 2, 0.5, -UI.H / 2)
end

--==============================================================
--  TABS
--==============================================================
function UI.addTab(name)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = T.BTN
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = s(12)
    btn.TextColor3 = T.TEXT
    btn.Text = name
    btn.AutoButtonColor = true
    btn.Size = UDim2.new(0.24, -s(6), 1, 0)
    btn.Parent = tabRow
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = T.ACC
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, s(6))
    layout.Parent = page
    local pad = Instance.new("UIPadding")
    pad.PaddingBottom = UDim.new(0, s(6))
    pad.Parent = page

    UI.pages[name] = page
    UI.tabButtons[name] = btn
    table.insert(UI.tabOrder, name)

    UI.onClick(btn, function() UI.selectTab(name) end)
    return page
end

function UI.selectTab(name)
    for n, page in pairs(UI.pages) do
        page.Visible = (n == name)
    end
    for n, btn in pairs(UI.tabButtons) do
        btn.BackgroundColor3 = (n == name) and T.ACC or T.BTN
    end
    UI.currentTab = name
end

function UI.layoutTabs()
    local n = math.max(1, #UI.tabOrder)
    for i, name in ipairs(UI.tabOrder) do
        local btn = UI.tabButtons[name]
        if btn then
            btn.Size = UDim2.new(1 / n, -s(5), 1, 0)
        end
    end
end

--==============================================================
--  WIDGETS
--==============================================================
local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or s(8))
    c.Parent = inst
    return c
end
UI.corner = corner

-- titled box so every page is organised the same way
function UI.section(parent, labelText, accent)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = T.BG2
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Parent = parent
    corner(frame, s(10))

    local stroke = Instance.new("UIStroke")
    stroke.Color = accent or T.ACC
    stroke.Transparency = 0.75
    stroke.Thickness = 1
    stroke.Parent = frame

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, s(7))
    pad.PaddingBottom = UDim.new(0, s(8))
    pad.PaddingLeft = UDim.new(0, s(8))
    pad.PaddingRight = UDim.new(0, s(8))
    pad.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, s(5))
    layout.Parent = frame

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = s(11)
    title.TextColor3 = accent or T.ACC
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Size = UDim2.new(1, 0, 0, s(14))
    title.Text = tostring(labelText or ""):upper()
    title.Parent = frame

    return frame, layout
end

function UI.label(parent, text, color, opts)
    opts = opts or {}
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = opts.bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize = s(opts.size or 12)
    l.TextColor3 = color or T.TEXT
    l.TextWrapped = true
    l.TextXAlignment = opts.align or Enum.TextXAlignment.Left
    l.Size = UDim2.new(1, 0, 0, 0)
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.Text = tostring(text or "")
    l.Parent = parent
    return l
end

function UI.spacer(parent, h)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(1, 0, 0, s(h or 6))
    f.Parent = parent
    return f
end

-- a row that lays its children out horizontally
function UI.row(parent, height, padding)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(1, 0, 0, s(height or 32))
    f.Parent = parent
    local l = Instance.new("UIListLayout")
    l.FillDirection = Enum.FillDirection.Horizontal
    l.Padding = UDim.new(0, s(padding or 5))
    l.VerticalAlignment = Enum.VerticalAlignment.Center
    l.Parent = f
    return f
end

function UI.button(parent, text, cb, opts)
    opts = opts or {}
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = opts.color or T.BTN
    b.Font = Enum.Font.GothamMedium
    b.TextSize = s(opts.size or 12)
    b.TextColor3 = opts.textColor or T.TEXT
    b.Text = tostring(text or "")
    b.TextWrapped = true
    b.AutoButtonColor = true
    b.Size = opts.width and UDim2.new(opts.width, -s(4), 0, s(opts.h or 32)) or UDim2.new(1, 0, 0, s(opts.h or 32))
    b.Parent = parent
    corner(b, s(8))
    if cb then UI.onClick(b, cb) end
    return b
end

function UI.toggle(parent, labelText, default, cb)
    local on = default and true or false
    local b = Instance.new("TextButton")
    b.Font = Enum.Font.GothamMedium
    b.TextSize = s(12)
    b.TextColor3 = T.TEXT
    b.AutoButtonColor = true
    b.Size = UDim2.new(1, 0, 0, s(32))
    b.Parent = parent
    corner(b, s(8))

    local function render()
        b.Text = ("%s     %s"):format(tostring(labelText), on and "ON" or "OFF")
        b.BackgroundColor3 = on and T.ON or T.OFF
    end
    UI.onClick(b, function()
        on = not on
        render()
        pcall(cb, on)
    end)
    render()
    -- NOTE: functions are returned separately - you cannot store them on an
    -- Instance (Roblox throws "X is not a valid member of TextButton")
    local function get() return on end
    local function set(v)
        on = v and true or false
        render()
    end
    return b, get, set
end

-- button that cycles through a list of options
function UI.cycle(parent, labelText, values, index, cb)
    local i = index or 1
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = T.BTN
    b.Font = Enum.Font.GothamMedium
    b.TextSize = s(12)
    b.TextColor3 = T.TEXT
    b.AutoButtonColor = true
    b.Size = UDim2.new(1, 0, 0, s(32))
    b.Parent = parent
    corner(b, s(8))

    local function render()
        b.Text = ("%s:   %s"):format(tostring(labelText), tostring(values[i]))
    end
    UI.onClick(b, function()
        i = i + 1
        if i > #values then i = 1 end
        render()
        pcall(cb, i, values[i])
    end)
    render()
    local function getIndex() return i end
    local function setIndex(n)
        i = Util.clamp(n or 1, 1, #values)
        render()
        pcall(cb, i, values[i])
    end
    return b, getIndex, setIndex
end

function UI.input(parent, placeholder, default, cb)
    local t = Instance.new("TextBox")
    t.PlaceholderText = tostring(placeholder or "")
    t.Text = tostring(default or "")
    t.Font = Enum.Font.Gotham
    t.TextSize = s(12)
    t.TextColor3 = T.TEXT
    t.PlaceholderColor3 = T.DIM
    t.BackgroundColor3 = T.BG3
    t.BorderSizePixel = 0
    t.ClearTextOnFocus = false
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Size = UDim2.new(1, 0, 0, s(30))
    t.Parent = parent
    corner(t, s(8))
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, s(8))
    pad.Parent = t
    if cb then
        t.FocusLost:Connect(function(enter)
            pcall(cb, t.Text, enter)
        end)
    end
    return t
end

-- small coloured pill (used for the rarity chip in the list)
function UI.chip(parent, text, color, width)
    local l = Instance.new("TextLabel")
    l.BackgroundColor3 = color or T.ACC
    l.BackgroundTransparency = 0.12
    l.Font = Enum.Font.GothamBold
    l.TextSize = s(9)
    l.TextColor3 = Color3.fromRGB(12, 12, 16)
    l.TextXAlignment = Enum.TextXAlignment.Center
    l.Size = width and UDim2.new(0, s(width), 0, s(15)) or UDim2.new(0, s(46), 0, s(15))
    l.Text = " " .. tostring(text or "") .. " "
    l.Parent = parent
    corner(l, s(5))
    return l
end

-- scrolling log
function UI.log(parent, height)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 0, s(height or 140))
    sf.BackgroundColor3 = T.BG3
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 4
    sf.ScrollBarImageColor3 = T.ACC
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Parent = parent
    corner(sf, s(8))

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = sf

    local count = 0
    local function add(text, color)
        local lb = Instance.new("TextLabel")
        lb.BackgroundTransparency = 1
        lb.Font = Enum.Font.Code
        lb.TextSize = s(10)
        lb.TextWrapped = true
        lb.TextColor3 = color or T.TEXT
        lb.TextXAlignment = Enum.TextXAlignment.Left
        lb.Size = UDim2.new(1, -s(10), 0, 0)
        lb.AutomaticSize = Enum.AutomaticSize.Y
        lb.Text = tostring(text)
        lb.Parent = sf
        count = count + 1
        if count > 160 then
            for _, c in ipairs(sf:GetChildren()) do
                if c:IsA("TextLabel") then
                    c:Destroy()
                    count = count - 1
                    break
                end
            end
        end
        task.defer(function()
            pcall(function()
                sf.CanvasPosition = Vector2.new(0, math.max(0, sf.AbsoluteCanvasSize.Y))
            end)
        end)
        return lb
    end

    local function clear()
        for _, c in ipairs(sf:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        count = 0
    end

    return { frame = sf, add = add, clear = clear }
end

--==============================================================
--  TOAST (bottom of the screen status bar)
--==============================================================
local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.Size = UDim2.new(0, math.min(vw - 20, 420), 0, s(26))
toast.Position = UDim2.new(0.5, -math.min(vw - 20, 420) / 2, 1, -s(90))
toast.BackgroundColor3 = T.BG2
toast.BackgroundTransparency = 0.15
toast.Font = Enum.Font.GothamBold
toast.TextSize = s(12)
toast.TextColor3 = T.ACC
toast.Text = ""
toast.Visible = false
toast.Parent = gui
corner(toast, s(8))
UI.toast = toast

local toastUntil = 0
function UI.toastShow(text, color, seconds)
    toast.Text = tostring(text)
    toast.TextColor3 = color or T.ACC
    toast.Visible = true
    toastUntil = tick() + (seconds or 3)
end

task.spawn(function()
    while SaB.Running do
        task.wait(0.4)
        if toast.Visible and tick() > toastUntil then
            toast.Visible = false
        end
    end
end)

return UI
