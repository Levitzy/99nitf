--// Module: GlassGreen
--// Drop this ModuleScript into ReplicatedStorage as "GlassGreen"
--// Usage:
--[[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GlassGreen = require(ReplicatedStorage:WaitForChild("GlassGreen"))

local ui = GlassGreen

local win = ui.CreateWindow({ Title = "GlassGreen UI", Size = UDim2.fromOffset(820, 520), Draggable = true })
local sidebar = win:AddSidebar({ Width = 210 })

local homeItem = sidebar:AddItem("Home")
local settingsItem = sidebar:AddItem("Settings")

local home = win:AddPage("Home")
local settings = win:AddPage("Settings")

home:AddButton("Hello", function() ui:Notify("Hi!", "Welcome to GlassGreen.") end)
home:AddToggle("God Mode", false, function(v) print("God Mode:", v) end)
home:AddSlider("Distance", 0, 200, 70, 1, function(v) print("Distance:", v) end)

settings:AddDropdown("Quality", {"Low","Medium","High","Ultra"}, "High", function(choice) print("Quality:", choice) end)
settings:AddKeybind("Open/Close", Enum.KeyCode.RightShift, function() win:SetVisible(not win.Visible) end)

sidebar.ItemSelected:Connect(function(name)
	win:ShowPage(name)
end)

sidebar:Select("Home")
ui:Notify("Loaded", "GlassGreen ready.")
]]

local GlassGreen = {}

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

--// ScreenGui (one per-session)
local screenGui do
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GlassGreenGui"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = (Players.LocalPlayer and Players.LocalPlayer:WaitForChild("PlayerGui")) or CoreGui
end

--// Signal helper
local function Signal()
	local bind = Instance.new("BindableEvent")
	local sig = {}
	function sig:Connect(fn) return bind.Event:Connect(fn) end
	function sig:Fire(...) bind:Fire(...) end
	function sig:Destroy() bind:Destroy() end
	return sig
end

--// Theme
GlassGreen.Theme = {
	Background = Color3.fromRGB(10, 14, 12),   -- base backdrop (used in full-screen vignette / shadows)
	Glass = Color3.fromRGB(26, 36, 32),        -- glass base (dark green-ish)
	GlassTransparency = 0.35,                  -- translucency level
	Stroke = Color3.fromRGB(255, 255, 255),    -- subtle white stroke
	StrokeTransparency = 0.8,                  -- light stroke
	Accent = Color3.fromHex and Color3.fromHex("#2EE36E") or Color3.fromRGB(46, 227, 110),
	Text = Color3.fromRGB(235, 244, 240),
	MutedText = Color3.fromRGB(180, 200, 190),
	Shadow = Color3.fromRGB(0, 0, 0),
	ShadowTransparency = 0.75,
	Corner = 16,                                -- default corner radius
	Font = Enum.Font.Gotham
}

-- track themed instances for live updates
local themed = {} -- { {inst=Instance, prop="BackgroundColor3", key="Glass"}, ... }
local function track(inst, prop, themeKey)
	table.insert(themed, {inst=inst, prop=prop, key=themeKey})
end
local function applyTheme(inst, prop, themeKey)
	pcall(function() inst[prop] = GlassGreen.Theme[themeKey] end)
end
local function applyAllTheme()
	for _, t in ipairs(themed) do
		applyTheme(t.inst, t.prop, t.key)
	end
end

--// Utilities
local function tween(obj, info, props)
	local ti = typeof(info) == "Instance" and info or TweenInfo.new(info or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tw = TweenService:Create(obj, ti, props)
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

local function makeGlassFrame(name, z)
	local f = Instance.new("Frame")
	f.Name = name or "GlassFrame"
	f.BackgroundColor3 = GlassGreen.Theme.Glass
	f.BackgroundTransparency = GlassGreen.Theme.GlassTransparency
	f.BorderSizePixel = 0
	f.ZIndex = z or 1
	track(f, "BackgroundColor3", "Glass")

	makeCorner(f)
	makeStroke(f, 1.25)

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200,220,210))
	})
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(1, 1)
	})
	grad.Rotation = -15
	grad.Parent = f

	return f
end

local function label(text, size, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text or ""
	l.Font = GlassGreen.Theme.Font
	l.TextColor3 = GlassGreen.Theme.Text
	l.TextSize = size or 16
	l.RichText = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.ZIndex = 3
	if bold then l.FontFace.Weight = Enum.FontWeight.Bold end
	track(l, "TextColor3", "Text")
	return l
end

local function buttonBase(textStr)
	local b = makeGlassFrame("Button", 3)
	b.AutomaticSize = Enum.AutomaticSize.Y
	b.Size = UDim2.new(1, 0, 0, 40)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = b

	local t = label(textStr or "Button", 16, true)
	t.Size = UDim2.new(1, 0, 1, 0)
	t.Parent = b

	local uiStroke = b:FindFirstChildOfClass("UIStroke")

	local btn = Instance.new("TextButton")
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Size = UDim2.fromScale(1,1)
	btn.ZIndex = 4
	btn.AutoButtonColor = false
	btn.Parent = b

	-- hover/press
	btn.MouseEnter:Connect(function()
		tween(b, 0.15, {BackgroundTransparency = math.clamp(GlassGreen.Theme.GlassTransparency - 0.05, 0,1)})
		if uiStroke then tween(uiStroke, 0.15, {Transparency = math.max(GlassGreen.Theme.StrokeTransparency - 0.1, 0.4)}) end
	end)
	btn.MouseLeave:Connect(function()
		tween(b, 0.2, {BackgroundTransparency = GlassGreen.Theme.GlassTransparency})
		if uiStroke then tween(uiStroke, 0.2, {Transparency = GlassGreen.Theme.StrokeTransparency}) end
	end)
	btn.MouseButton1Down:Connect(function()
		tween(b, 0.08, {BackgroundTransparency = math.clamp(GlassGreen.Theme.GlassTransparency - 0.1, 0,1)})
	end)
	btn.MouseButton1Up:Connect(function()
		tween(b, 0.12, {BackgroundTransparency = GlassGreen.Theme.GlassTransparency})
	end)

	return b, btn, t
end

local function makeList(parent, padding)
	local uiList = Instance.new("UIListLayout")
	uiList.FillDirection = Enum.FillDirection.Vertical
	uiList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	uiList.SortOrder = Enum.SortOrder.LayoutOrder
	uiList.Padding = UDim.new(0, padding or 8)
	uiList.Parent = parent
	return uiList
end

local function makeVGroup(parent, padding, insets)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, -(insets or 0), 1, -(insets or 0))
	holder.Position = UDim2.fromOffset((insets or 0)/2, (insets or 0)/2)
	holder.ZIndex = 2
	holder.Parent = parent
	makeList(holder, padding or 8)
	return holder
end

--// Notification system
local notifications = {}
function GlassGreen:Notify(titleText, messageText, duration)
	duration = duration or 3
	local card = makeGlassFrame("Toast", 50)
	card.AnchorPoint = Vector2.new(1,0)
	card.Size = UDim2.fromOffset(320, 86)
	card.Position = UDim2.new(1, -16, 0, 16 + (#notifications * 94))
	card.Parent = screenGui

	local padx = Instance.new("UIPadding")
	padx.PaddingLeft = UDim.new(0, 12)
	padx.PaddingRight = UDim.new(0, 12)
	padx.PaddingTop = UDim.new(0, 10)
	padx.PaddingBottom = UDim.new(0, 10)
	padx.Parent = card

	local title = label(titleText or "Notification", 16, true)
	title.Size = UDim2.new(1, 0, 0, 22)
	title.Parent = card

	local msg = label(messageText or "", 14, false)
	msg.TextColor3 = GlassGreen.Theme.MutedText
	msg.Size = UDim2.new(1, 0, 1, -26)
	msg.Position = UDim2.fromOffset(0, 24)
	msg.TextWrapped = true
	msg.Parent = card
	track(msg, "TextColor3", "MutedText")

	local accent = Instance.new("Frame")
	accnt = accent
	accnt = nil
	accent.BackgroundColor3 = GlassGreen.Theme.Accent
	accent.BackgroundTransparency = 0.7
	accent.BorderSizePixel = 0
	accent.Size = UDim2.new(0, 4, 1, 0)
	accent.Position = UDim2.fromOffset(-4, 0)
	accent.Parent = card
	track(accent, "BackgroundColor3", "Accent")

	table.insert(notifications, card)
	-- slide in
	card.Position = card.Position + UDim2.fromOffset(20, 0)
	tween(card, 0.25, {Position = UDim2.new(1, -16, 0, 16 + ((#notifications-1) * 94))})

	task.delay(duration, function()
		if card.Parent then
			tween(card, 0.2, {BackgroundTransparency = 1})
			task.wait(0.05)
			card:Destroy()
			-- reflow
			for i, c in ipairs(notifications) do
				if c == card then
					table.remove(notifications, i)
					break
				end
			end
			for i, c in ipairs(notifications) do
				if c.Parent then
					tween(c, 0.2, {Position = UDim2.new(1, -16, 0, 16 + ((i-1) * 94))})
				end
			end
		end
	end)
end

--// Theme mutation
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

--// Window + Sidebar + Page
local WindowMT = {}
WindowMT.__index = WindowMT

local SidebarMT = {}
SidebarMT.__index = SidebarMT

local PageMT = {}
PageMT.__index = PageMT

-- Draggable helper for topbar
local function makeDraggable(handle, root)
	local dragging = false
	local dragStart, startPos
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
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				local delta = input.Position - dragStart
				root.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
			end
		end
	end)
end

-- CreateWindow
function GlassGreen.CreateWindow(options)
	options = options or {}
	local self = setmetatable({}, WindowMT)

	self.Visible = true
	self.Pages = {}
	self.ActivePage = nil

	local container = makeGlassFrame("Window", 10)
	container.Size = options.Size or UDim2.fromOffset(820, 520)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.Parent = screenGui

	-- subtle drop shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://5028857084"
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(24,24,276,276)
	shadow.ImageTransparency = GlassGreen.Theme.ShadowTransparency
	shadow.ImageColor3 = GlassGreen.Theme.Shadow
	shadow.Size = container.Size + UDim2.fromOffset(48, 48)
	shadow.Position = container.Position + UDim2.fromOffset(-24, -24)
	shadow.AnchorPoint = container.AnchorPoint
	shadow.ZIndex = 5
	shadow.Parent = screenGui
	track(shadow, "ImageColor3", "Shadow")

	-- keep shadow following
	container:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		shadow.Position = container.Position + UDim2.fromOffset(-24, -24)
	end)
	container:GetPropertyChangedSignal("Size"):Connect(function()
		shadow.Size = container.Size + UDim2.fromOffset(48, 48)
	end)
	container:GetPropertyChangedSignal("Position"):Connect(function()
		shadow.Position = container.Position + UDim2.fromOffset(-24, -24)
	end)

	-- topbar
	local topbar = makeGlassFrame("Topbar", 20)
	topbar.Parent = container
	topbar.Size = UDim2.new(1, 0, 0, 44)
	topbar.BackgroundTransparency = math.clamp(GlassGreen.Theme.GlassTransparency - 0.1, 0,1)

	local title = label(options.Title or "GlassGreen", 18, true)
	title.Parent = topbar
	title.Size = UDim2.new(1, -120, 1, 0)
	title.Position = UDim2.fromOffset(14, 0)

	local btnClose = buttonBase("")[2]
	btnClose.Parent = topbar
	btnClose.Size = UDim2.fromOffset(36, 32)
	btnClose.Position = UDim2.new(1, -40, 0.5, -16)
	btnClose.ZIndex = 30
	local closeIcon = label("✕", 16, true)
	closeIcon.Parent = btnClose.Parent
	closeIcon.Size = btnClose.Size
	closeIcon.Position = btnClose.Position
	closeIcon.ZIndex = 31
	closeIcon.TextXAlignment = Enum.TextXAlignment.Center

	btnClose.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end)

	local btnMin = buttonBase("")[2]
	btnMin.Parent = topbar
	btnMin.Size = UDim2.fromOffset(36, 32)
	btnMin.Position = UDim2.new(1, -80, 0.5, -16)
	btnMin.ZIndex = 30
	local minIcon = label("—", 16, true)
	minIcon.Parent = btnMin.Parent
	minIcon.Size = btnMin.Size
	minIcon.Position = btnMin.Position
	minIcon.ZIndex = 31
	minIcon.TextXAlignment = Enum.TextXAlignment.Center

	btnMin.MouseButton1Click:Connect(function()
		local h = container.Size
		local to = self.Visible and UDim2.fromOffset(h.X.Offset, 44) or UDim2.fromOffset(h.X.Offset, (options.Size or UDim2.fromOffset(820,520)).Y.Offset)
		tween(container, 0.2, {Size = to})
		self.Visible = not self.Visible
	end)

	if options.Draggable ~= false then
		makeDraggable(topbar, container)
	end

	-- layout areas
	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, 0, 1, -48)
	body.Position = UDim2.fromOffset(0, 48)
	body.Parent = container

	local content = Instance.new("Frame")
	content.Name = "ContentArea"
	content.BackgroundTransparency = 1
	content.Size = UDim2.new(1, -230, 1, -16)
	content.Position = UDim2.fromOffset(222, 8)
	content.Parent = body

	local pagesFolder = Instance.new("Folder")
	pagesFolder.Name = "Pages"
	pagesFolder.Parent = content

	self._container = container
	self._content = content
	self._pagesFolder = pagesFolder
	self._shadow = shadow
	self._topbar = topbar
	self._title = title

	function self:AddSidebar(opts)
		opts = opts or {}
		local sb = setmetatable({}, SidebarMT)
		sb.Items = {}
		sb.Selected = nil
		sb.ItemSelected = Signal()

		local side = makeGlassFrame("Sidebar", 15)
		side.Parent = body
		side.Size = UDim2.new(0, opts.Width or 210, 1, -16)
		side.Position = UDim2.fromOffset(8, 8)

		local listHolder = makeVGroup(side, 6, 8)
		listHolder.Name = "ListHolder"

		local function renderItem(name, icon)
			local item = makeGlassFrame("Item_"..name, 18)
			item.Parent = listHolder
			item.Size = UDim2.new(1, 0, 0, 40)
			item.BackgroundTransparency = GlassGreen.Theme.GlassTransparency + 0.15

			local leftBar = Instance.new("Frame")
			leftBar.BackgroundColor3 = GlassGreen.Theme.Accent
			leftBar.BackgroundTransparency = 0.25
			leftBar.BorderSizePixel = 0
			leftBar.Size = UDim2.new(0, 4, 1, 0)
			leftBar.Visible = false
			leftBar.Parent = item
			track(leftBar, "BackgroundColor3", "Accent")

			local lbl = label(name, 16, false)
			lbl.Parent = item
			lbl.Size = UDim2.new(1, -14, 1, 0)
			lbl.Position = UDim2.fromOffset(10, 0)

			local btn = Instance.new("TextButton")
			btn.BackgroundTransparency = 1
			btn.Text = ""
			btn.Size = UDim2.fromScale(1,1)
			btn.Parent = item

			local function setActive(active)
				if active then
					leftBar.Visible = true
					tween(item, 0.15, {
						BackgroundTransparency = math.clamp(GlassGreen.Theme.GlassTransparency - 0.05, 0,1),
					})
					lbl.FontFace.Weight = Enum.FontWeight.SemiBold
					lbl.TextColor3 = GlassGreen.Theme.Text
					track(lbl, "TextColor3", "Text")
				else
					leftBar.Visible = false
					tween(item, 0.15, { BackgroundTransparency = GlassGreen.Theme.GlassTransparency + 0.15 })
					lbl.FontFace.Weight = Enum.FontWeight.Regular
					lbl.TextColor3 = GlassGreen.Theme.MutedText
					track(lbl, "TextColor3", "MutedText")
				end
			end

			btn.MouseEnter:Connect(function()
				if sb.Selected ~= name then
					tween(item, 0.12, {BackgroundTransparency = GlassGreen.Theme.GlassTransparency + 0.05})
				end
			end)
			btn.MouseLeave:Connect(function()
				if sb.Selected ~= name then
					tween(item, 0.15, {BackgroundTransparency = GlassGreen.Theme.GlassTransparency + 0.15})
				end
			end)
			btn.MouseButton1Click:Connect(function()
				sb:Select(name)
			end)

			sb.Items[name] = {Frame = item, Label = lbl, SetActive = setActive}
			return item
		end

		function sb:AddItem(name, icon)
			renderItem(name, icon)
			return sb.Items[name]
		end

		function sb:Select(name)
			if not sb.Items[name] then return end
			if sb.Selected == name then return end
			-- deselect previous
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

	function self:AddPage(name)
		local page = setmetatable({}, PageMT)
		page.Name = name

		local root = Instance.new("Frame")
		root.Name = "Page_"..name
		root.BackgroundTransparency = 1
		root.Size = UDim2.fromScale(1,1)
		root.Visible = false
		root.Parent = self._pagesFolder

		local holder = makeVGroup(root, 10, 6)

		page._root = root
		page._holder = holder
		page._controls = {}

		-- Controls:
		function page:AddButton(textStr, callback)
			local frame, btn, txt = buttonBase(textStr)
			frame.Parent = holder
			btn.MouseButton1Click:Connect(function()
				if callback then task.spawn(callback) end
			end)
			table.insert(page._controls, frame)
			return frame
		end

		function page:AddToggle(labelText, default, callback)
			local row = makeGlassFrame("Toggle", 3)
			row.Size = UDim2.new(1, 0, 0, 44)
			row.Parent = holder

			local lbl = label(labelText or "Toggle", 16, true)
			lbl.Size = UDim2.new(1, -80, 1, 0)
			lbl.Position = UDim2.fromOffset(12, 0)
			lbl.Parent = row

			local knob = makeGlassFrame("Knob", 4)
			knob.Size = UDim2.fromOffset(56, 26)
			knob.Position = UDim2.new(1, -68, 0.5, -13)
			knob.Parent = row

			local fill = Instance.new("Frame")
			fill.BackgroundColor3 = GlassGreen.Theme.Accent
			fill.BackgroundTransparency = 0.7
			fill.BorderSizePixel = 0
			fill.Size = UDim2.fromScale(0,1)
			fill.Parent = knob
			track(fill, "BackgroundColor3", "Accent")

			local thumb = makeGlassFrame("Thumb", 6)
			thumb.Size = UDim2.fromOffset(22, 22)
			thumb.Position = UDim2.fromOffset(2,2)
			thumb.Parent = knob

			local btn = Instance.new("TextButton")
			btn.Text = ""
			btn.BackgroundTransparency = 1
			btn.Size = UDim2.fromScale(1,1)
			btn.Parent = row

			local state = not not default
			local function render()
				if state then
					tween(fill, 0.18, {Size = UDim2.fromScale(1,1)})
					tween(thumb, 0.18, {Position = UDim2.fromOffset(56-24,2)})
				else
					tween(fill, 0.18, {Size = UDim2.fromScale(0,1)})
					tween(thumb, 0.18, {Position = UDim2.fromOffset(2,2)})
				end
			end
			render()

			btn.MouseButton1Click:Connect(function()
				state = not state
				render()
				if callback then task.spawn(callback, state) end
			end)

			table.insert(page._controls, row)
			return {
				Set = function(_, v) state = not not v; render() end,
				Get = function() return state end,
			}
		end

		function page:AddSlider(labelText, min, max, default, step, callback)
			min, max = min or 0, max or 100
			step = step or 1
			local value = math.clamp(default or min, min, max)

			local row = makeGlassFrame("Slider", 3)
			row.Size = UDim2.new(1, 0, 0, 58)
			row.Parent = holder

			local lbl = label(labelText or "Slider", 16, true)
			lbl.Size = UDim2.new(1, -100, 0, 24)
			lbl.Position = UDim2.fromOffset(12, 4)
			lbl.Parent = row

			local valLab = label(tostring(value), 14, false)
			valLab.TextXAlignment = Enum.TextXAlignment.Right
			valLab.Size = UDim2.new(0, 80, 0, 24)
			valLab.Position = UDim2.new(1, -84, 4, 0)
			valLab.Parent = row

			local track = makeGlassFrame("Track", 4)
			track.Size = UDim2.new(1, -24, 0, 10)
			track.Position = UDim2.fromOffset(12, 36)
			track.Parent = row

			local fill = Instance.new("Frame")
			fill.BackgroundColor3 = GlassGreen.Theme.Accent
			fill.BackgroundTransparency = 0.5
			fill.BorderSizePixel = 0
			fill.Size = UDim2.fromScale((value - min)/(max-min), 1)
			fill.Parent = track
			track(fill, "BackgroundColor3", "Accent")

			local dragging = false

			local function setFromX(x)
				local absPos = track.AbsolutePosition.X
				local width = track.AbsoluteSize.X
				local alpha = math.clamp((x - absPos) / math.max(width,1), 0, 1)
				local v = min + alpha * (max - min)
				v = math.round(v / step) * step
				v = math.clamp(v, min, max)
				if v ~= value then
					value = v
					valLab.Text = tostring(value)
					fill.Size = UDim2.fromScale((value - min)/(max-min), 1)
					if callback then task.spawn(callback, value) end
				else
					valLab.Text = tostring(value)
					fill.Size = UDim2.fromScale((value - min)/(max-min), 1)
				end
			end

			track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					setFromX(input.Position.X)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					setFromX(input.Position.X)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)

			table.insert(page._controls, row)
			return {
				Set = function(_, v) value = math.clamp(v, min, max); setFromX(track.AbsolutePosition.X + (track.AbsoluteSize.X * (value-min)/(max-min))) end,
				Get = function() return value end,
			}
		end

		function page:AddDropdown(labelText, list, default, callback)
			list = list or {}
			local current = default or list[1] or ""

			local row = makeGlassFrame("Dropdown", 3)
			row.Size = UDim2.new(1, 0, 0, 48)
			row.Parent = holder

			local lbl = label(labelText or "Dropdown", 16, true)
			lbl.Size = UDim2.new(1, -180, 1, 0)
			lbl.Position = UDim2.fromOffset(12, 0)
			lbl.Parent = row

			local display = buttonBase(current)
			display[1].Parent = row
			display[1].Size = UDim2.new(0, 160, 0, 34)
			display[1].Position = UDim2.new(1, -172, 0.5, -17)

			local btn = display[2]
			local txt = display[3]
			local open = false

			local menu = makeGlassFrame("Menu", 40)
			menu.Visible = false
			menu.Size = UDim2.new(0, 160, 0, math.min(#list, 6)*34 + 8)
			menu.Parent = row
			menu.Position = UDim2.new(1, -172, 1, 4)

			local inner = makeVGroup(menu, 6, 6)

			local function rebuild()
				inner:ClearAllChildren()
				for _, item in ipairs(list) do
					local opt, optBtn, optLbl = buttonBase(item)
					opt.Size = UDim2.new(1, 0, 0, 28)
					opt.Parent = inner
					optBtn.MouseButton1Click:Connect(function()
						current = item
						txt.Text = current
						open = false
						menu.Visible = false
						if callback then task.spawn(callback, current) end
					end)
				end
			end
			rebuild()

			btn.MouseButton1Click:Connect(function()
				open = not open
				menu.Visible = open
			end)

			table.insert(page._controls, row)
			return {
				SetList = function(_, newList) list = newList or {}; rebuild() end,
				Set = function(_, v) current = v; txt.Text = current end,
				Get = function() return current end,
			}
		end

		function page:AddKeybind(labelText, defaultKeyCode, callback)
			local key = defaultKeyCode or Enum.KeyCode.RightShift

			local row = makeGlassFrame("Keybind", 3)
			row.Size = UDim2.new(1, 0, 0, 48)
			row.Parent = holder

			local lbl = label(labelText or "Keybind", 16, true)
			lbl.Size = UDim2.new(1, -180, 1, 0)
			lbl.Position = UDim2.fromOffset(12, 0)
			lbl.Parent = row

			local d, btn, txt = buttonBase(key.Name)
			d.Parent = row
			d.Size = UDim2.new(0, 160, 0, 34)
			d.Position = UDim2.new(1, -172, 0.5, -17)

			local listening = false

			btn.MouseButton1Click:Connect(function()
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

			table.insert(page._controls, row)
			return {
				Set = function(_, kc) key = kc; txt.Text = key.Name end,
				Get = function() return key end,
				Destroy = function() if conn then conn:Disconnect() end row:Destroy() end
			}
		end

		self.Pages[name] = page
		return page
	end

	function self:ShowPage(name)
		for n, pg in pairs(self.Pages) do
			if pg._root then
				if n == name then
					pg._root.Visible = true
					pg._root.BackgroundTransparency = 1
					tween(pg._root, 0.18, {BackgroundTransparency = 1}) -- keep transparent but still animate in case of effects
				else
					pg._root.Visible = false
				end
			end
		end
		self.ActivePage = name
	end

	function self:SetTitle(t)
		self._title.Text = t
	end

	function self:SetVisible(v)
		self.Visible = v
		if v then
			self._container.Visible = true
			self._shadow.Visible = true
			tween(self._container, 0.2, {BackgroundTransparency = GlassGreen.Theme.GlassTransparency})
		else
			tween(self._container, 0.15, {BackgroundTransparency = 1}).Completed:Connect(function()
				self._container.Visible = false
				self._shadow.Visible = false
			end)
		end
	end

	function self:Destroy()
		if self._shadow then self._shadow:Destroy() end
		if self._container then self._container:Destroy() end
	end

	return self
end

return GlassGreen
