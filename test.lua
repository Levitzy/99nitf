--// Module: GlassGreen (v2 - opaque + better sidebar)
--// No dependencies. Works in a LocalScript or via executor loadstring.

--[[ USAGE (example)
local GlassGreen = require(game:GetService("ReplicatedStorage"):WaitForChild("GlassGreen"))

local win = GlassGreen.CreateWindow({
    Title = "My Game UI",
    Size = UDim2.fromOffset(880, 540),
    Draggable = true
})

local sb = win:AddSidebar({ Width = 220 }) -- scrolls automatically if too many items
sb:AddItem("Home")
sb:AddItem("Settings")
sb:AddItem("Shop")
sb:AddItem("Weapons")
sb:AddItem("Skins")
sb:AddItem("Credits")

local home = win:AddPage("Home")
home:AddButton("Notify", function() GlassGreen:Notify("Hello", "This is solid + readable now!") end)
home:AddToggle("God Mode", false, function(v) print("God Mode:", v) end)
home:AddSlider("Distance", 0, 200, 70, 1, function(v) print("Distance:", v) end)

local settings = win:AddPage("Settings")
settings:AddDropdown("Quality", {"Low","Medium","High","Ultra"}, "High", function(v) print("Quality:", v) end)
settings:AddKeybind("Open/Close", Enum.KeyCode.RightShift, function()
    win:SetVisible(not win.Visible)
end)

sb.ItemSelected:Connect(function(name) win:ShowPage(name) end)
sb:Select("Home")
]]

local GlassGreen = {}

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

--// Root ScreenGui
local screenGui do
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GlassGreenGUI"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local pg = (Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"))
    if pg then screenGui.Parent = pg else screenGui.Parent = CoreGui end
end

--// Theme (OPAQ / HIGH CONTRAST)
GlassGreen.Theme = {
    -- opaque card/backgrounds for readability
    Glass = Color3.fromRGB(24, 38, 30),      -- deep green
    GlassTransparency = 0.05,                -- almost solid
    WindowBg = Color3.fromRGB(18, 26, 22),   -- window background
    WindowTransparency = 0,                  -- solid

    Stroke = Color3.fromRGB(255,255,255),
    StrokeTransparency = 0.7,

    Accent = Color3.fromRGB(46, 227, 110),
    Text = Color3.fromRGB(240, 248, 244),
    MutedText = Color3.fromRGB(190, 207, 199),

    Corner = 14,
    Font = Enum.Font.Gotham
}

-- track themed instances for live Updates
local themed = {} -- {inst, prop, key}
local function track(inst, prop, themeKey)
    table.insert(themed, {inst=inst, prop=prop, key=themeKey})
end
local function applyAllTheme()
    for _, t in ipairs(themed) do
        local ok, _ = pcall(function() t.inst[t.prop] = GlassGreen.Theme[t.key] end)
        if not ok then -- ignore
        end
    end
end

local function tween(obj, ti, props)
    local info = typeof(ti) == "number" and TweenInfo.new(ti, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) or ti
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or GlassGreen.Theme.Corner)
    c.Parent = parent
    return c
end

local function makeStroke(parent, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1.2
    s.Transparency = (transparency ~= nil) and transparency or GlassGreen.Theme.StrokeTransparency
    s.Color = GlassGreen.Theme.Stroke
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    track(s, "Color", "Stroke")
    return s
end

local function label(text, size, bold, alignRight)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = bold and Enum.Font.GothamSemibold or GlassGreen.Theme.Font
    l.Text = text or ""
    l.TextSize = size or 16
    l.TextWrapped = false
    l.TextColor3 = GlassGreen.Theme.Text
    l.TextXAlignment = alignRight and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    track(l, "TextColor3", "Text")
    return l
end

local function makeGlassFrame(name, z, solid)
    local f = Instance.new("Frame")
    f.Name = name or "Card"
    f.BackgroundColor3 = solid and GlassGreen.Theme.WindowBg or GlassGreen.Theme.Glass
    f.BackgroundTransparency = solid and GlassGreen.Theme.WindowTransparency or GlassGreen.Theme.GlassTransparency
    f.BorderSizePixel = 0
    if z then f.ZIndex = z end
    makeCorner(f)
    makeStroke(f)
    return f
end

-- simple signal
local function Signal()
    local ev = Instance.new("BindableEvent")
    return {
        Connect = function(_, fn) return ev.Event:Connect(fn) end,
        Fire = function(_, ...) ev:Fire(...) end,
        Destroy = function() ev:Destroy() end
    }
end

-- notifications
local activeToasts = {}
function GlassGreen:Notify(titleText, bodyText, duration)
    duration = duration or 3
    local toast = makeGlassFrame("Toast", 50, false)
    toast.Size = UDim2.fromOffset(320, 90)
    toast.AnchorPoint = Vector2.new(1,0)
    toast.Position = UDim2.new(1, -14, 0, 14 + (#activeToasts * 98))
    toast.Parent = screenGui

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent = toast

    local title = label(titleText or "Notification", 16, true)
    title.Size = UDim2.new(1, 0, 0, 22)
    title.Parent = toast

    local body = label(bodyText or "", 14, false)
    body.TextColor3 = GlassGreen.Theme.MutedText
    track(body, "TextColor3", "MutedText")
    body.Size = UDim2.new(1, 0, 1, -26)
    body.Position = UDim2.fromOffset(0, 24)
    body.TextWrapped = true
    body.Parent = toast

    table.insert(activeToasts, toast)
    tween(toast, 0.2, {Position = UDim2.new(1, -14, 0, 14 + ((#activeToasts-1) * 98))})

    task.delay(duration, function()
        if toast and toast.Parent then
            tween(toast, 0.15, {BackgroundTransparency = 1})
            task.wait(0.1)
            toast:Destroy()
            for i, t in ipairs(activeToasts) do
                if t == toast then table.remove(activeToasts, i) break end
            end
            for i, t in ipairs(activeToasts) do
                if t.Parent then tween(t, 0.15, {Position = UDim2.new(1, -14, 0, 14 + ((i-1)*98))}) end
            end
        end
    end)
end

function GlassGreen:SetAccent(color3)
    GlassGreen.Theme.Accent = color3
    applyAllTheme()
end
function GlassGreen:SetTheme(partial)
    for k,v in pairs(partial or {}) do
        GlassGreen.Theme[k] = v
    end
    applyAllTheme()
end

-- Window / Sidebar / Page metatables
local WindowMT, SidebarMT, PageMT = {}, {}, {}
WindowMT.__index, SidebarMT.__index, PageMT.__index = WindowMT, SidebarMT, PageMT

local function makeDraggable(handle, root)
    local dragging, dragStart, startPos = false
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = root.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            root.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- PUBLIC: CreateWindow
function GlassGreen.CreateWindow(opts)
    opts = opts or {}
    local self = setmetatable({}, WindowMT)
    self.Visible = true
    self.Pages = {}
    self.ActivePage = nil

    -- main window (SOLID background for visibility)
    local window = makeGlassFrame("Window", 10, true)
    window.Size = opts.Size or UDim2.fromOffset(880, 540)
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.Position = UDim2.fromScale(0.5, 0.5)
    window.Parent = screenGui

    -- topbar (slightly darker)
    local top = makeGlassFrame("Topbar", 20, false)
    top.BackgroundColor3 = GlassGreen.Theme.Glass
    top.BackgroundTransparency = 0.08
    top.Size = UDim2.new(1, 0, 0, 46)
    top.Parent = window

    local title = label(opts.Title or "GlassGreen", 18, true)
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Position = UDim2.fromOffset(14, 0)
    title.Parent = top

    -- close/min
    local closeBtn = Instance.new("TextButton")
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamSemibold
    closeBtn.TextSize = 18
    closeBtn.TextColor3 = GlassGreen.Theme.Text
    closeBtn.Size = UDim2.fromOffset(34, 34)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -17)
    closeBtn.Parent = top
    track(closeBtn, "TextColor3", "Text")

    local minBtn = Instance.new("TextButton")
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "—"
    minBtn.Font = Enum.Font.GothamSemibold
    minBtn.TextSize = 18
    minBtn.TextColor3 = GlassGreen.Theme.Text
    minBtn.Size = UDim2.fromOffset(34, 34)
    minBtn.Position = UDim2.new(1, -80, 0.5, -17)
    minBtn.Parent = top
    track(minBtn, "TextColor3", "Text")

    closeBtn.MouseButton1Click:Connect(function() self:SetVisible(false) end)
    minBtn.MouseButton1Click:Connect(function()
        if self.Visible then
            tween(window, 0.18, {Size = UDim2.new(window.Size.X.Scale, window.Size.X.Offset, 0, 46)})
        else
            tween(window, 0.18, {Size = opts.Size or UDim2.fromOffset(880, 540)})
        end
        self.Visible = not self.Visible
    end)

    if opts.Draggable ~= false then
        makeDraggable(top, window)
    end

    -- layout area
    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, 0, 1, -46)
    body.Position = UDim2.fromOffset(0, 46)
    body.Parent = window

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, -234, 1, -16)
    content.Position = UDim2.fromOffset(226, 8)
    content.Parent = body

    local pagesFolder = Instance.new("Folder")
    pagesFolder.Name = "Pages"
    pagesFolder.Parent = content

    -- store
    self._window = window
    self._title = title
    self._content = content
    self._pagesFolder = pagesFolder
    self._topbar = top

    -- APIs
    function self:SetTitle(t) self._title.Text = t end

    function self:SetVisible(v)
        if v then
            self._window.Visible = true
            tween(self._window, 0.15, {BackgroundTransparency = GlassGreen.Theme.WindowTransparency})
        else
            tween(self._window, 0.12, {BackgroundTransparency = 1}).Completed:Connect(function()
                self._window.Visible = false
            end)
        end
    end

    function self:Destroy()
        if self._window then self._window:Destroy() end
    end

    -- Sidebar
    function self:AddSidebar(o)
        o = o or {}
        local sb = setmetatable({}, SidebarMT)
        sb.Items = {}
        sb.Selected = nil
        sb.ItemSelected = Signal()

        local side = makeGlassFrame("Sidebar", 15, false)
        side.BackgroundTransparency = 0.08
        side.Size = UDim2.new(0, o.Width or 220, 1, -16)
        side.Position = UDim2.fromOffset(8, 8)
        side.Parent = body

        -- scrolling list
        local list = Instance.new("ScrollingFrame")
        list.Name = "List"
        list.BackgroundTransparency = 1
        list.BorderSizePixel = 0
        list.Size = UDim2.new(1, -12, 1, -12)
        list.Position = UDim2.fromOffset(6, 6)
        list.CanvasSize = UDim2.new(0,0,0,0)
        list.ScrollBarThickness = 4
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        list.Parent = side

        local uiList = Instance.new("UIListLayout")
        uiList.Padding = UDim.new(0, 6)
        uiList.SortOrder = Enum.SortOrder.LayoutOrder
        uiList.Parent = list

        local function mkItem(name)
            local item = Instance.new("TextButton")
            item.Name = "Item_"..name
            item.BackgroundColor3 = GlassGreen.Theme.Glass
            item.BackgroundTransparency = 0.25
            item.Text = name
            item.Font = Enum.Font.Gotham
            item.TextSize = 16
            item.TextColor3 = GlassGreen.Theme.MutedText
            item.Size = UDim2.new(1, 0, 0, 40)
            item.AutoButtonColor = false
            item.Parent = list
            makeCorner(item)
            makeStroke(item)

            local leftBar = Instance.new("Frame")
            leftBar.BackgroundColor3 = GlassGreen.Theme.Accent
            leftBar.BackgroundTransparency = 0.2
            leftBar.BorderSizePixel = 0
            leftBar.Size = UDim2.new(0, 4, 1, 0)
            leftBar.Visible = false
            leftBar.Parent = item

            local function setActive(active)
                if active then
                    leftBar.Visible = true
                    tween(item, 0.12, {BackgroundTransparency = 0.08})
                    item.TextColor3 = GlassGreen.Theme.Text
                    item.Font = Enum.Font.GothamSemibold
                else
                    leftBar.Visible = false
                    tween(item, 0.12, {BackgroundTransparency = 0.25})
                    item.TextColor3 = GlassGreen.Theme.MutedText
                    item.Font = Enum.Font.Gotham
                end
            end

            item.MouseEnter:Connect(function()
                if sb.Selected ~= name then tween(item, 0.1, {BackgroundTransparency = 0.18}) end
            end)
            item.MouseLeave:Connect(function()
                if sb.Selected ~= name then tween(item, 0.12, {BackgroundTransparency = 0.25}) end
            end)
            item.MouseButton1Click:Connect(function() sb:Select(name) end)

            sb.Items[name] = {Button = item, SetActive = setActive}
        end

        function sb:AddItem(name)
            mkItem(name)
            return sb.Items[name]
        end

        function sb:Select(name)
            if not sb.Items[name] then return end
            if sb.Selected and sb.Items[sb.Selected] then
                sb.Items[sb.Selected].SetActive(false)
            end
            sb.Selected = name
            sb.Items[name].SetActive(true)
            sb.ItemSelected:Fire(name)
        end

        sb._root = side
        self._sidebar = sb
        return sb
    end

    -- Pages
    function self:AddPage(name)
        local page = setmetatable({}, PageMT)
        page.Name = name

        local root = Instance.new("Frame")
        root.Name = "Page_"..name
        root.BackgroundTransparency = 1
        root.Size = UDim2.fromScale(1,1)
        root.Visible = false
        root.Parent = self._pagesFolder

        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.new(1, -16, 1, -16)
        holder.Position = UDim2.fromOffset(8,8)
        holder.Parent = root

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 8)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = holder

        page._root = root
        page._holder = holder

        -- Controls
        local function ButtonBase(textStr)
            local f = Instance.new("TextButton")
            f.Name = "Btn_"..(textStr or "Button")
            f.AutoButtonColor = false
            f.BackgroundColor3 = GlassGreen.Theme.Glass
            f.BackgroundTransparency = 0.08
            f.Text = textStr or "Button"
            f.Font = Enum.Font.GothamSemibold
            f.TextSize = 16
            f.TextColor3 = GlassGreen.Theme.Text
            f.Size = UDim2.new(1, 0, 0, 40)
            makeCorner(f)
            makeStroke(f)
            f.MouseEnter:Connect(function() tween(f, 0.1, {BackgroundTransparency = 0.02}) end)
            f.MouseLeave:Connect(function() tween(f, 0.12, {BackgroundTransparency = 0.08}) end)
            return f
        end

        function page:AddButton(textStr, callback)
            local b = ButtonBase(textStr)
            b.Parent = holder
            b.MouseButton1Click:Connect(function()
                if callback then task.spawn(callback) end
            end)
            return b
        end

        function page:AddToggle(labelText, default, callback)
            local row = makeGlassFrame("Toggle", 3, false)
            row.BackgroundTransparency = 0.08
            row.Size = UDim2.new(1, 0, 0, 44)
            row.Parent = holder

            local lbl = label(labelText or "Toggle", 16, true)
            lbl.Size = UDim2.new(1, -90, 1, 0)
            lbl.Position = UDim2.fromOffset(12, 0)
            lbl.Parent = row

            local trackF = makeGlassFrame("Track", 3, false)
            trackF.BackgroundTransparency = 0.18
            trackF.Size = UDim2.fromOffset(56, 26)
            trackF.Position = UDim2.new(1, -70, 0.5, -13)
            trackF.Parent = row

            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = GlassGreen.Theme.Accent
            fill.BackgroundTransparency = 0.3
            fill.BorderSizePixel = 0
            fill.Size = UDim2.fromScale(0,1)
            fill.Parent = trackF

            local thumb = makeGlassFrame("Thumb", 4, false)
            thumb.Size = UDim2.fromOffset(22, 22)
            thumb.Position = UDim2.fromOffset(2,2)
            thumb.Parent = trackF

            local state = not not default
            local function render()
                if state then
                    tween(fill, 0.15, {Size = UDim2.fromScale(1,1)})
                    tween(thumb, 0.15, {Position = UDim2.fromOffset(56-24,2)})
                else
                    tween(fill, 0.15, {Size = UDim2.fromScale(0,1)})
                    tween(thumb, 0.15, {Position = UDim2.fromOffset(2,2)})
                end
            end
            render()

            row.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    state = not state
                    render()
                    if callback then task.spawn(callback, state) end
                end
            end)

            return {
                Set = function(_, v) state = not not v; render() end,
                Get = function() return state end
            }
        end

        function page:AddSlider(labelText, min, max, default, step, callback)
            min, max = min or 0, max or 100
            step = step or 1
            local value = math.clamp(default or min, min, max)

            local row = makeGlassFrame("Slider", 3, false)
            row.BackgroundTransparency = 0.08
            row.Size = UDim2.new(1, 0, 0, 58)
            row.Parent = holder

            local lbl = label(labelText or "Slider", 16, true)
            lbl.Size = UDim2.new(1, -110, 0, 24)
            lbl.Position = UDim2.fromOffset(12, 6)
            lbl.Parent = row

            local val = label(tostring(value), 14, false, true)
            val.Size = UDim2.new(0, 80, 0, 24)
            val.Position = UDim2.new(1, -86, 6, 0)
            val.Parent = row

            local trackF = makeGlassFrame("Track", 3, false)
            trackF.BackgroundTransparency = 0.18
            trackF.Size = UDim2.new(1, -24, 0, 10)
            trackF.Position = UDim2.fromOffset(12, 36)
            trackF.Parent = row

            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = GlassGreen.Theme.Accent
            fill.BackgroundTransparency = 0.25
            fill.BorderSizePixel = 0
            fill.Size = UDim2.fromScale((value - min)/(max-min), 1)
            fill.Parent = trackF

            local dragging = false
            local function setFromX(x)
                local abs = trackF.AbsolutePosition.X
                local width = math.max(1, trackF.AbsoluteSize.X)
                local a = math.clamp((x - abs)/width, 0, 1)
                local v = min + a*(max-min)
                v = math.round(v/step)*step
                v = math.clamp(v, min, max)
                value = v
                val.Text = tostring(value)
                fill.Size = UDim2.fromScale((value-min)/(max-min), 1)
                if callback then task.spawn(callback, value) end
            end

            trackF.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    setFromX(i.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    setFromX(i.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            return {
                Set = function(_, v)
                    value = math.clamp(v, min, max)
                    val.Text = tostring(value)
                    fill.Size = UDim2.fromScale((value-min)/(max-min), 1)
                end,
                Get = function() return value end
            }
        end

        function page:AddDropdown(labelText, list, default, callback)
            list = list or {}
            local current = default or list[1] or ""

            local row = makeGlassFrame("Dropdown", 3, false)
            row.BackgroundTransparency = 0.08
            row.Size = UDim2.new(1, 0, 0, 48)
            row.Parent = holder

            local lbl = label(labelText or "Dropdown", 16, true)
            lbl.Size = UDim2.new(1, -172, 1, 0)
            lbl.Position = UDim2.fromOffset(12, 0)
            lbl.Parent = row

            local btn = makeGlassFrame("Select", 4, false)
            btn.BackgroundTransparency = 0.12
            btn.Size = UDim2.new(0, 160, 0, 34)
            btn.Position = UDim2.new(1, -172, 0.5, -17)
            btn.Parent = row

            local txt = label(current, 15, true, false)
            txt.Size = UDim2.fromScale(1,1)
            txt.Position = UDim2.fromOffset(10,0)
            txt.Parent = btn

            local click = Instance.new("TextButton")
            click.BackgroundTransparency = 1
            click.Text = ""
            click.Size = UDim2.fromScale(1,1)
            click.Parent = btn

            local menu = makeGlassFrame("Menu", 40, false)
            menu.BackgroundTransparency = 0.08
            menu.Visible = false
            menu.Size = UDim2.new(0, 160, 0, math.min(#list, 6)*30 + 8)
            menu.Position = UDim2.new(1, -172, 1, 4)
            menu.Parent = row

            local scroll = Instance.new("ScrollingFrame")
            scroll.BackgroundTransparency = 1
            scroll.Size = UDim2.new(1, -8, 1, -8)
            scroll.Position = UDim2.fromOffset(4,4)
            scroll.CanvasSize = UDim2.new(0,0,0,0)
            scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            scroll.ScrollBarThickness = 4
            scroll.Parent = menu

            local ui = Instance.new("UIListLayout")
            ui.Padding = UDim.new(0, 4)
            ui.Parent = scroll

            local function rebuild()
                scroll:ClearAllChildren()
                ui.Parent = scroll
                for _, item in ipairs(list) do
                    local opt = Instance.new("TextButton")
                    opt.BackgroundColor3 = GlassGreen.Theme.Glass
                    opt.BackgroundTransparency = 0.15
                    opt.Text = item
                    opt.Font = Enum.Font.Gotham
                    opt.TextSize = 15
                    opt.TextColor3 = GlassGreen.Theme.Text
                    opt.Size = UDim2.new(1, 0, 0, 28)
                    opt.AutoButtonColor = false
                    opt.Parent = scroll
                    makeCorner(opt)
                    makeStroke(opt)

                    opt.MouseButton1Click:Connect(function()
                        current = item
                        txt.Text = current
                        menu.Visible = false
                        if callback then task.spawn(callback, current) end
                    end)
                end
            end
            rebuild()

            click.MouseButton1Click:Connect(function()
                menu.Visible = not menu.Visible
            end)

            return {
                SetList = function(_, newList) list = newList or {}; rebuild() end,
                Set = function(_, v) current = v; txt.Text = current end,
                Get = function() return current end
            }
        end

        function page:AddKeybind(labelText, defaultKeyCode, callback)
            local key = defaultKeyCode or Enum.KeyCode.RightShift

            local row = makeGlassFrame("Keybind", 3, false)
            row.BackgroundTransparency = 0.08
            row.Size = UDim2.new(1, 0, 0, 48)
            row.Parent = holder

            local lbl = label(labelText or "Keybind", 16, true)
            lbl.Size = UDim2.new(1, -172, 1, 0)
            lbl.Position = UDim2.fromOffset(12, 0)
            lbl.Parent = row

            local btn = makeGlassFrame("BindBtn", 4, false)
            btn.BackgroundTransparency = 0.12
            btn.Size = UDim2.new(0, 160, 0, 34)
            btn.Position = UDim2.new(1, -172, 0.5, -17)
            btn.Parent = row

            local txt = label(key.Name, 15, true, false)
            txt.Size = UDim2.fromScale(1,1)
            txt.Position = UDim2.fromOffset(10,0)
            txt.Parent = btn

            local listen = Instance.new("TextButton")
            listen.BackgroundTransparency = 1
            listen.Text = ""
            listen.Size = UDim2.fromScale(1,1)
            listen.Parent = btn

            local listening = false
            listen.MouseButton1Click:Connect(function()
                listening = true
                txt.Text = "Press a key..."
            end)
            local conn
            conn = UserInputService.InputBegan:Connect(function(input, gp)
                if not listening or gp then return end
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    key = input.KeyCode
                    txt.Text = key.Name
                    listening = false
                    if callback then task.spawn(callback, key) end
                end
            end)

            return {
                Set = function(_, kc) key = kc; txt.Text = key.Name end,
                Get = function() return key end,
                Destroy = function() if conn then conn:Disconnect() end; row:Destroy() end
            }
        end

        -- store
        self.Pages[name] = page
        return page
    end

    function self:ShowPage(name)
        for n, pg in pairs(self.Pages) do
            if pg._root then
                local show = (n == name)
                pg._root.Visible = show
                if show then
                    pg._root.BackgroundTransparency = 1
                    tween(pg._root, 0.15, {BackgroundTransparency = 1}) -- placeholder for potential effects
                end
            end
        end
        self.ActivePage = name
    end

    return self
end

return GlassGreen
