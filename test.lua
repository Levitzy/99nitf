local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local GUI = {}
GUI.__index = GUI

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

function GUI.new(title)
    local self = setmetatable({}, GUI)
    
    self.isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    self.screenSize = workspace.CurrentCamera.ViewportSize
    
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "ModernGUI"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.screenGui.Parent = PlayerGui
    
    local guiSize = self.isMobile and {700, 500} or {900, 600}
    if self.screenSize.X < 800 then
        guiSize = {self.screenSize.X * 0.95, self.screenSize.Y * 0.85}
    end
    
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "MainFrame"
    self.mainFrame.Size = UDim2.new(0, guiSize[1], 0, guiSize[2])
    self.mainFrame.Position = UDim2.new(0.5, -guiSize[1]/2, 0.5, -guiSize[2]/2)
    self.mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Parent = self.screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, self.isMobile and 8 or 12)
    corner.Parent = self.mainFrame
    
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.ZIndex = -1
    shadow.Parent = self.mainFrame
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, self.isMobile and 12 or 16)
    shadowCorner.Parent = shadow
    
    self:createTitleBar(title or "Modern GUI")
    self:createSidebar()
    self:createContentArea()
    self:createSearchBar()
    
    self.sidebarItems = {}
    self.selectedItem = nil
    self.dialogs = {}
    
    if not self.isMobile then
        self:makeDraggable()
    end
    
    return self
end

function GUI:createTitleBar(title)
    local titleHeight = self.isMobile and 40 or 50
    
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Size = UDim2.new(1, 0, 0, titleHeight)
    self.titleBar.Position = UDim2.new(0, 0, 0, 0)
    self.titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    self.titleBar.BorderSizePixel = 0
    self.titleBar.Parent = self.mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, self.isMobile and 8 or 12)
    titleCorner.Parent = self.titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -100, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = self.isMobile and 16 or 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = self.titleBar
    
    self.closeButton = Instance.new("TextButton")
    self.closeButton.Name = "CloseButton"
    self.closeButton.Size = UDim2.new(0, self.isMobile and 35 or 40, 0, self.isMobile and 25 or 30)
    self.closeButton.Position = UDim2.new(1, self.isMobile and -45 or -50, 0, self.isMobile and 7 or 10)
    self.closeButton.BackgroundColor3 = Color3.fromRGB(255, 95, 87)
    self.closeButton.BorderSizePixel = 0
    self.closeButton.Text = "×"
    self.closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.closeButton.TextSize = self.isMobile and 16 or 18
    self.closeButton.Font = Enum.Font.GothamBold
    self.closeButton.Parent = self.titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = self.closeButton
    
    self.closeButton.MouseButton1Click:Connect(function()
        self:destroy()
    end)
end

function GUI:createSidebar()
    local sidebarWidth = self.isMobile and 180 or 250
    local titleHeight = self.isMobile and 40 or 50
    
    self.sidebar = Instance.new("Frame")
    self.sidebar.Name = "Sidebar"
    self.sidebar.Size = UDim2.new(0, sidebarWidth, 1, -titleHeight)
    self.sidebar.Position = UDim2.new(0, 0, 0, titleHeight)
    self.sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    self.sidebar.BorderSizePixel = 0
    self.sidebar.Parent = self.mainFrame
    
    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, 0)
    sidebarCorner.Parent = self.sidebar
    
    self.sidebarScrolling = Instance.new("ScrollingFrame")
    self.sidebarScrolling.Name = "SidebarScrolling"
    self.sidebarScrolling.Size = UDim2.new(1, 0, 1, self.isMobile and -45 or -60)
    self.sidebarScrolling.Position = UDim2.new(0, 0, 0, self.isMobile and 45 or 60)
    self.sidebarScrolling.BackgroundTransparency = 1
    self.sidebarScrolling.BorderSizePixel = 0
    self.sidebarScrolling.ScrollBarThickness = self.isMobile and 2 or 4
    self.sidebarScrolling.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    self.sidebarScrolling.Parent = self.sidebar
    
    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 3)
    sidebarLayout.Parent = self.sidebarScrolling
end

function GUI:createSearchBar()
    local searchHeight = self.isMobile and 30 or 40
    
    self.searchFrame = Instance.new("Frame")
    self.searchFrame.Name = "SearchFrame"
    self.searchFrame.Size = UDim2.new(1, -16, 0, searchHeight)
    self.searchFrame.Position = UDim2.new(0, 8, 0, 8)
    self.searchFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    self.searchFrame.BorderSizePixel = 0
    self.searchFrame.Parent = self.sidebar
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 6)
    searchCorner.Parent = self.searchFrame
    
    self.searchBox = Instance.new("TextBox")
    self.searchBox.Name = "SearchBox"
    self.searchBox.Size = UDim2.new(1, -30, 1, 0)
    self.searchBox.Position = UDim2.new(0, 8, 0, 0)
    self.searchBox.BackgroundTransparency = 1
    self.searchBox.Text = ""
    self.searchBox.PlaceholderText = "Search..."
    self.searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
    self.searchBox.TextSize = self.isMobile and 12 or 14
    self.searchBox.Font = Enum.Font.Gotham
    self.searchBox.TextXAlignment = Enum.TextXAlignment.Left
    self.searchBox.Parent = self.searchFrame
    
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Name = "SearchIcon"
    searchIcon.Size = UDim2.new(0, 16, 0, 16)
    searchIcon.Position = UDim2.new(1, -22, 0.5, -8)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextColor3 = Color3.fromRGB(150, 150, 160)
    searchIcon.TextSize = self.isMobile and 10 or 12
    searchIcon.Parent = self.searchFrame
    
    self.searchBox.Changed:Connect(function()
        self:filterSidebarItems(self.searchBox.Text)
    end)
end

function GUI:createContentArea()
    local sidebarWidth = self.isMobile and 180 or 250
    local titleHeight = self.isMobile and 40 or 50
    
    self.contentArea = Instance.new("Frame")
    self.contentArea.Name = "ContentArea"
    self.contentArea.Size = UDim2.new(1, -sidebarWidth, 1, -titleHeight)
    self.contentArea.Position = UDim2.new(0, sidebarWidth, 0, titleHeight)
    self.contentArea.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    self.contentArea.BorderSizePixel = 0
    self.contentArea.Parent = self.mainFrame
    
    self.contentScrolling = Instance.new("ScrollingFrame")
    self.contentScrolling.Name = "ContentScrolling"
    self.contentScrolling.Size = UDim2.new(1, 0, 1, 0)
    self.contentScrolling.Position = UDim2.new(0, 0, 0, 0)
    self.contentScrolling.BackgroundTransparency = 1
    self.contentScrolling.BorderSizePixel = 0
    self.contentScrolling.ScrollBarThickness = self.isMobile and 3 or 6
    self.contentScrolling.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    self.contentScrolling.Parent = self.contentArea
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, self.isMobile and 6 or 10)
    contentLayout.Parent = self.contentScrolling
    
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, self.isMobile and 12 or 20)
    contentPadding.PaddingBottom = UDim.new(0, self.isMobile and 12 or 20)
    contentPadding.PaddingLeft = UDim.new(0, self.isMobile and 12 or 20)
    contentPadding.PaddingRight = UDim.new(0, self.isMobile and 12 or 20)
    contentPadding.Parent = self.contentScrolling
end

function GUI:addSidebarItem(name, callback)
    local itemHeight = self.isMobile and 35 or 45
    
    local item = Instance.new("Frame")
    item.Name = name
    item.Size = UDim2.new(1, -16, 0, itemHeight)
    item.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    item.BorderSizePixel = 0
    item.Parent = self.sidebarScrolling
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 6)
    itemCorner.Parent = item
    
    local itemButton = Instance.new("TextButton")
    itemButton.Name = "ItemButton"
    itemButton.Size = UDim2.new(1, 0, 1, 0)
    itemButton.Position = UDim2.new(0, 0, 0, 0)
    itemButton.BackgroundTransparency = 1
    itemButton.Text = name
    itemButton.TextColor3 = Color3.fromRGB(200, 200, 210)
    itemButton.TextSize = self.isMobile and 12 or 14
    itemButton.Font = Enum.Font.Gotham
    itemButton.TextXAlignment = Enum.TextXAlignment.Left
    itemButton.Parent = item
    
    local itemPadding = Instance.new("UIPadding")
    itemPadding.PaddingLeft = UDim.new(0, self.isMobile and 10 or 15)
    itemPadding.Parent = itemButton
    
    local highlight = Instance.new("Frame")
    highlight.Name = "Highlight"
    highlight.Size = UDim2.new(0, 3, 0.6, 0)
    highlight.Position = UDim2.new(0, 0, 0.2, 0)
    highlight.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    highlight.BorderSizePixel = 0
    highlight.Visible = false
    highlight.Parent = item
    
    local highlightCorner = Instance.new("UICorner")
    highlightCorner.CornerRadius = UDim.new(0, 1.5)
    highlightCorner.Parent = highlight
    
    itemButton.MouseButton1Click:Connect(function()
        self:selectSidebarItem(item, name, callback)
    end)
    
    itemButton.MouseEnter:Connect(function()
        if self.selectedItem ~= item then
            local tween = TweenService:Create(item, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)})
            tween:Play()
        end
    end)
    
    itemButton.MouseLeave:Connect(function()
        if self.selectedItem ~= item then
            local tween = TweenService:Create(item, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)})
            tween:Play()
        end
    end)
    
    self.sidebarItems[name] = item
    
    return item
end

function GUI:selectSidebarItem(item, name, callback)
    if self.selectedItem then
        local prevHighlight = self.selectedItem:FindFirstChild("Highlight")
        if prevHighlight then
            prevHighlight.Visible = false
        end
        local tween = TweenService:Create(self.selectedItem, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)})
        tween:Play()
    end
    
    self.selectedItem = item
    local highlight = item:FindFirstChild("Highlight")
    if highlight then
        highlight.Visible = true
    end
    
    local tween = TweenService:Create(item, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 70)})
    tween:Play()
    
    self:clearContent()
    
    if callback then
        callback()
    end
end

function GUI:clearContent()
    for _, child in ipairs(self.contentScrolling:GetChildren()) do
        if child:IsA("GuiObject") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
            child:Destroy()
        end
    end
end

function GUI:addToggle(name, defaultValue, callback)
    local toggleHeight = self.isMobile and 50 or 60
    
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = name .. "Toggle"
    toggleFrame.Size = UDim2.new(1, 0, 0, toggleHeight)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = self.contentScrolling
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleFrame
    
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Name = "ToggleLabel"
    toggleLabel.Size = UDim2.new(1, -80, 1, 0)
    toggleLabel.Position = UDim2.new(0, self.isMobile and 12 or 20, 0, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = name
    toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleLabel.TextSize = self.isMobile and 13 or 16
    toggleLabel.Font = Enum.Font.Gotham
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.Parent = toggleFrame
    
    local switchSize = self.isMobile and {44, 24} or {52, 28}
    local knobSize = self.isMobile and 18 or 22
    
    local toggleTrack = Instance.new("Frame")
    toggleTrack.Name = "ToggleTrack"
    toggleTrack.Size = UDim2.new(0, switchSize[1], 0, switchSize[2])
    toggleTrack.Position = UDim2.new(1, -switchSize[1] - (self.isMobile and 12 or 20), 0.5, -switchSize[2]/2)
    toggleTrack.BackgroundColor3 = defaultValue and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(97, 97, 97)
    toggleTrack.BorderSizePixel = 0
    toggleTrack.Parent = toggleFrame
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, switchSize[2]/2)
    trackCorner.Parent = toggleTrack
    
    local toggleKnob = Instance.new("Frame")
    toggleKnob.Name = "ToggleKnob"
    toggleKnob.Size = UDim2.new(0, knobSize, 0, knobSize)
    toggleKnob.Position = defaultValue and UDim2.new(1, -knobSize - 3, 0.5, -knobSize/2) or UDim2.new(0, 3, 0.5, -knobSize/2)
    toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleKnob.BorderSizePixel = 0
    toggleKnob.ZIndex = 2
    toggleKnob.Parent = toggleTrack
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, knobSize/2)
    knobCorner.Parent = toggleKnob
    
    local knobShadow = Instance.new("Frame")
    knobShadow.Name = "KnobShadow"
    knobShadow.Size = UDim2.new(1, 4, 1, 4)
    knobShadow.Position = UDim2.new(0, -2, 0, -2)
    knobShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    knobShadow.BackgroundTransparency = 0.3
    knobShadow.ZIndex = 1
    knobShadow.Parent = toggleKnob
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, knobSize/2 + 2)
    shadowCorner.Parent = knobShadow
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(1, 20, 1, 20)
    toggleButton.Position = UDim2.new(0, -10, 0, -10)
    toggleButton.BackgroundTransparency = 1
    toggleButton.Text = ""
    toggleButton.ZIndex = 3
    toggleButton.Parent = toggleTrack
    
    local isToggled = defaultValue
    
    local function animateToggle()
        local trackColor = isToggled and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(97, 97, 97)
        local knobPosition = isToggled and UDim2.new(1, -knobSize - 3, 0.5, -knobSize/2) or UDim2.new(0, 3, 0.5, -knobSize/2)
        
        local ripple = Instance.new("Frame")
        ripple.Name = "Ripple"
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
        ripple.BackgroundColor3 = isToggled and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(97, 97, 97)
        ripple.BackgroundTransparency = 0.7
        ripple.BorderSizePixel = 0
        ripple.ZIndex = 1
        ripple.Parent = toggleKnob
        
        local rippleCorner = Instance.new("UICorner")
        rippleCorner.CornerRadius = UDim.new(1, 0)
        rippleCorner.Parent = ripple
        
        local rippleExpand = TweenService:Create(ripple, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 40, 0, 40),
            Position = UDim2.new(0.5, -20, 0.5, -20),
            BackgroundTransparency = 1
        })
        
        local trackTween = TweenService:Create(toggleTrack, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = trackColor})
        local knobTween = TweenService:Create(toggleKnob, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = knobPosition})
        
        rippleExpand:Play()
        trackTween:Play()
        knobTween:Play()
        
        rippleExpand.Completed:Connect(function()
            ripple:Destroy()
        end)
    end
    
    toggleButton.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        animateToggle()
        
        if callback then
            callback(isToggled)
        end
    end)
    
    return toggleFrame
end

function GUI:addDropdown(name, options, defaultOption, callback)
    local dropdownHeight = self.isMobile and 50 or 60
    
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Name = name .. "Dropdown"
    dropdownFrame.Size = UDim2.new(1, 0, 0, dropdownHeight)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    dropdownFrame.BorderSizePixel = 0
    dropdownFrame.Parent = self.contentScrolling
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 8)
    dropdownCorner.Parent = dropdownFrame
    
    local dropdownLabel = Instance.new("TextLabel")
    dropdownLabel.Name = "DropdownLabel"
    dropdownLabel.Size = UDim2.new(0.4, 0, 1, 0)
    dropdownLabel.Position = UDim2.new(0, self.isMobile and 12 or 20, 0, 0)
    dropdownLabel.BackgroundTransparency = 1
    dropdownLabel.Text = name
    dropdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownLabel.TextSize = self.isMobile and 13 or 16
    dropdownLabel.Font = Enum.Font.Gotham
    dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
    dropdownLabel.Parent = dropdownFrame
    
    local buttonWidth = self.isMobile and 140 or 180
    local buttonHeight = self.isMobile and 28 or 35
    
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Name = "DropdownButton"
    dropdownButton.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
    dropdownButton.Position = UDim2.new(1, -buttonWidth - (self.isMobile and 12 or 20), 0.5, -buttonHeight/2)
    dropdownButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    dropdownButton.BorderSizePixel = 0
    dropdownButton.Text = defaultOption or options[1] or "Select"
    dropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownButton.TextSize = self.isMobile and 12 or 14
    dropdownButton.Font = Enum.Font.Gotham
    dropdownButton.Parent = dropdownFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = dropdownButton
    
    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.new(0, 16, 0, 16)
    arrow.Position = UDim2.new(1, -20, 0.5, -8)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Color3.fromRGB(200, 200, 200)
    arrow.TextSize = self.isMobile and 10 or 12
    arrow.Font = Enum.Font.Gotham
    arrow.Parent = dropdownButton
    
    local optionHeight = self.isMobile and 28 or 35
    
    local dropdownList = Instance.new("Frame")
    dropdownList.Name = "DropdownList"
    dropdownList.Size = UDim2.new(0, buttonWidth, 0, #options * optionHeight)
    dropdownList.Position = UDim2.new(1, -buttonWidth - (self.isMobile and 12 or 20), 1, 5)
    dropdownList.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    dropdownList.BorderSizePixel = 0
    dropdownList.Visible = false
    dropdownList.ZIndex = 10
    dropdownList.Parent = dropdownFrame
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = dropdownList
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = dropdownList
    
    for i, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Name = "Option" .. i
        optionButton.Size = UDim2.new(1, 0, 0, optionHeight)
        optionButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        optionButton.BorderSizePixel = 0
        optionButton.Text = option
        optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        optionButton.TextSize = self.isMobile and 12 or 14
        optionButton.Font = Enum.Font.Gotham
        optionButton.Parent = dropdownList
        
        if i == 1 then
            local topCorner = Instance.new("UICorner")
            topCorner.CornerRadius = UDim.new(0, 6)
            topCorner.Parent = optionButton
        elseif i == #options then
            local bottomCorner = Instance.new("UICorner")
            bottomCorner.CornerRadius = UDim.new(0, 6)
            bottomCorner.Parent = optionButton
        end
        
        optionButton.MouseEnter:Connect(function()
            local tween = TweenService:Create(optionButton, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60, 60, 70)})
            tween:Play()
        end)
        
        optionButton.MouseLeave:Connect(function()
            local tween = TweenService:Create(optionButton, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)})
            tween:Play()
        end)
        
        optionButton.MouseButton1Click:Connect(function()
            dropdownButton.Text = option
            dropdownList.Visible = false
            
            local arrowTween = TweenService:Create(arrow, TweenInfo.new(0.2), {Rotation = 0})
            arrowTween:Play()
            
            if callback then
                callback(option, i)
            end
        end)
    end
    
    dropdownButton.MouseButton1Click:Connect(function()
        dropdownList.Visible = not dropdownList.Visible
        
        local rotation = dropdownList.Visible and 180 or 0
        local arrowTween = TweenService:Create(arrow, TweenInfo.new(0.2), {Rotation = rotation})
        arrowTween:Play()
    end)
    
    return dropdownFrame
end

function GUI:createDialog(title, content, buttons)
    local dialogSize = self.isMobile and {320, 200} or {400, 250}
    
    local dialog = Instance.new("Frame")
    dialog.Name = "Dialog"
    dialog.Size = UDim2.new(0, dialogSize[1], 0, dialogSize[2])
    dialog.Position = UDim2.new(0.5, -dialogSize[1]/2, 0.5, -dialogSize[2]/2)
    dialog.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 20
    dialog.Parent = self.screenGui
    
    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = UDim.new(0, self.isMobile and 8 or 12)
    dialogCorner.Parent = dialog
    
    local dialogShadow = Instance.new("Frame")
    dialogShadow.Name = "DialogShadow"
    dialogShadow.Size = UDim2.new(1, 20, 1, 20)
    dialogShadow.Position = UDim2.new(0, -10, 0, -10)
    dialogShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dialogShadow.BackgroundTransparency = 0.5
    dialogShadow.ZIndex = 19
    dialogShadow.Parent = dialog
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, self.isMobile and 12 or 16)
    shadowCorner.Parent = dialogShadow
    
    local dialogTitle = Instance.new("TextLabel")
    dialogTitle.Name = "DialogTitle"
    dialogTitle.Size = UDim2.new(1, -32, 0, self.isMobile and 35 or 50)
    dialogTitle.Position = UDim2.new(0, 16, 0, 8)
    dialogTitle.BackgroundTransparency = 1
    dialogTitle.Text = title
    dialogTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    dialogTitle.TextSize = self.isMobile and 15 or 18
    dialogTitle.Font = Enum.Font.GothamBold
    dialogTitle.TextXAlignment = Enum.TextXAlignment.Left
    dialogTitle.Parent = dialog
    
    local contentHeight = self.isMobile and 100 or 120
    
    local dialogContent = Instance.new("TextLabel")
    dialogContent.Name = "DialogContent"
    dialogContent.Size = UDim2.new(1, -32, 0, contentHeight)
    dialogContent.Position = UDim2.new(0, 16, 0, self.isMobile and 40 or 60)
    dialogContent.BackgroundTransparency = 1
    dialogContent.Text = content
    dialogContent.TextColor3 = Color3.fromRGB(200, 200, 200)
    dialogContent.TextSize = self.isMobile and 12 or 14
    dialogContent.Font = Enum.Font.Gotham
    dialogContent.TextXAlignment = Enum.TextXAlignment.Left
    dialogContent.TextYAlignment = Enum.TextYAlignment.Top
    dialogContent.TextWrapped = true
    dialogContent.Parent = dialog
    
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "ButtonFrame"
    buttonFrame.Size = UDim2.new(1, -32, 0, self.isMobile and 35 or 50)
    buttonFrame.Position = UDim2.new(0, 16, 1, self.isMobile and -45 or -60)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = dialog
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    buttonLayout.Padding = UDim.new(0, 8)
    buttonLayout.Parent = buttonFrame
    
    buttons = buttons or {{"OK", function() dialog:Destroy() end}}
    
    for i, buttonData in ipairs(buttons) do
        local buttonName, buttonCallback = buttonData[1], buttonData[2]
        
        local dialogButton = Instance.new("TextButton")
        dialogButton.Name = "DialogButton" .. i
        dialogButton.Size = UDim2.new(0, self.isMobile and 60 or 80, 1, 0)
        dialogButton.BackgroundColor3 = i == 1 and Color3.fromRGB(33, 150, 243) or Color3.fromRGB(60, 60, 70)
        dialogButton.BorderSizePixel = 0
        dialogButton.Text = buttonName
        dialogButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        dialogButton.TextSize = self.isMobile and 12 or 14
        dialogButton.Font = Enum.Font.Gotham
        dialogButton.Parent = buttonFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = dialogButton
        
        dialogButton.MouseButton1Click:Connect(function()
            if buttonCallback then
                buttonCallback()
            end
            dialog:Destroy()
        end)
        
        dialogButton.MouseEnter:Connect(function()
            local hoverColor = i == 1 and Color3.fromRGB(63, 180, 255) or Color3.fromRGB(80, 80, 90)
            local tween = TweenService:Create(dialogButton, TweenInfo.new(0.1), {BackgroundColor3 = hoverColor})
            tween:Play()
        end)
        
        dialogButton.MouseLeave:Connect(function()
            local normalColor = i == 1 and Color3.fromRGB(33, 150, 243) or Color3.fromRGB(60, 60, 70)
            local tween = TweenService:Create(dialogButton, TweenInfo.new(0.1), {BackgroundColor3 = normalColor})
            tween:Play()
        end)
    end
    
    dialog.Position = UDim2.new(0.5, -dialogSize[1]/2, 0.5, -dialogSize[2] - 100)
    local tween = TweenService:Create(dialog, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, -dialogSize[1]/2, 0.5, -dialogSize[2]/2)})
    tween:Play()
    
    table.insert(self.dialogs, dialog)
    
    return dialog
end

function GUI:filterSidebarItems(searchText)
    searchText = searchText:lower()
    
    for name, item in pairs(self.sidebarItems) do
        if searchText == "" or name:lower():find(searchText) then
            item.Visible = true
        else
            item.Visible = false
        end
    end
end

function GUI:makeDraggable()
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    self.titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.mainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

function GUI:destroy()
    if self.screenGui then
        self.screenGui:Destroy()
    end
end

function GUI:show()
    self.screenGui.Enabled = true
end

function GUI:hide()
    self.screenGui.Enabled = false
end

return GUI
