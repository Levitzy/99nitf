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
    
    local guiSize = self.isMobile and {400, 280} or {450, 300}
    if self.screenSize.X < 550 then
        guiSize = {self.screenSize.X * 0.9, self.screenSize.Y * 0.7}
    end
    
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "MainFrame"
    self.mainFrame.Size = UDim2.new(0, guiSize[1], 0, guiSize[2])
    self.mainFrame.Position = UDim2.new(0.5, -guiSize[1]/2, 0.5, -guiSize[2]/2)
    self.mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    self.mainFrame.BackgroundTransparency = 0.1
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Parent = self.screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, self.isMobile and 4 or 6)
    corner.Parent = self.mainFrame
    
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 12, 1, 12)
    shadow.Position = UDim2.new(0, -6, 0, -6)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.ZIndex = -1
    shadow.Parent = self.mainFrame
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, self.isMobile and 8 or 10)
    shadowCorner.Parent = shadow
    
    self:createTitleBar(title or "Modern GUI")
    self:createSidebar()
    self:createContentArea()
    self:createSearchBar()
    
    self.sidebarItems = {}
    self.selectedItem = nil
    self.dialogs = {}
    self.dropdownSelections = {}
    
    self:makeDraggable()
    
    return self
end

function GUI:createTitleBar(title)
    local titleHeight = self.isMobile and 25 or 30
    
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Size = UDim2.new(1, 0, 0, titleHeight)
    self.titleBar.Position = UDim2.new(0, 0, 0, 0)
    self.titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    self.titleBar.BackgroundTransparency = 0.05
    self.titleBar.BorderSizePixel = 0
    self.titleBar.Parent = self.mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, self.isMobile and 4 or 6)
    titleCorner.Parent = self.titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 8, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = self.isMobile and 12 or 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = self.titleBar
    
    self.closeButton = Instance.new("TextButton")
    self.closeButton.Name = "CloseButton"
    self.closeButton.Size = UDim2.new(0, self.isMobile and 20 or 24, 0, self.isMobile and 16 or 20)
    self.closeButton.Position = UDim2.new(1, self.isMobile and -24 or -28, 0, self.isMobile and 4 or 5)
    self.closeButton.BackgroundColor3 = Color3.fromRGB(255, 95, 87)
    self.closeButton.BorderSizePixel = 0
    self.closeButton.Text = "×"
    self.closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.closeButton.TextSize = self.isMobile and 10 or 12
    self.closeButton.Font = Enum.Font.GothamBold
    self.closeButton.Parent = self.titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 3)
    closeCorner.Parent = self.closeButton
    
    self.closeButton.MouseButton1Click:Connect(function()
        self:destroy()
    end)
end

function GUI:createSidebar()
    local sidebarWidth = self.isMobile and 90 or 115
    local titleHeight = self.isMobile and 25 or 30
    
    self.sidebar = Instance.new("Frame")
    self.sidebar.Name = "Sidebar"
    self.sidebar.Size = UDim2.new(0, sidebarWidth, 1, -titleHeight)
    self.sidebar.Position = UDim2.new(0, 0, 0, titleHeight)
    self.sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    self.sidebar.BackgroundTransparency = 0.1
    self.sidebar.BorderSizePixel = 0
    self.sidebar.Parent = self.mainFrame
    
    self.sidebarScrolling = Instance.new("ScrollingFrame")
    self.sidebarScrolling.Name = "SidebarScrolling"
    self.sidebarScrolling.Size = UDim2.new(1, 0, 1, self.isMobile and -28 or -32)
    self.sidebarScrolling.Position = UDim2.new(0, 0, 0, self.isMobile and 28 or 32)
    self.sidebarScrolling.BackgroundTransparency = 1
    self.sidebarScrolling.BorderSizePixel = 0
    self.sidebarScrolling.ScrollBarThickness = 2
    self.sidebarScrolling.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    self.sidebarScrolling.Parent = self.sidebar
    
    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 1)
    sidebarLayout.Parent = self.sidebarScrolling
end

function GUI:createSearchBar()
    local searchHeight = self.isMobile and 20 or 24
    
    self.searchFrame = Instance.new("Frame")
    self.searchFrame.Name = "SearchFrame"
    self.searchFrame.Size = UDim2.new(1, -8, 0, searchHeight)
    self.searchFrame.Position = UDim2.new(0, 4, 0, 4)
    self.searchFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    self.searchFrame.BorderSizePixel = 0
    self.searchFrame.Parent = self.sidebar
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 3)
    searchCorner.Parent = self.searchFrame
    
    self.searchBox = Instance.new("TextBox")
    self.searchBox.Name = "SearchBox"
    self.searchBox.Size = UDim2.new(1, -20, 1, 0)
    self.searchBox.Position = UDim2.new(0, 4, 0, 0)
    self.searchBox.BackgroundTransparency = 1
    self.searchBox.Text = ""
    self.searchBox.PlaceholderText = "Search..."
    self.searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
    self.searchBox.TextSize = self.isMobile and 10 or 13
    self.searchBox.Font = Enum.Font.Gotham
    self.searchBox.TextXAlignment = Enum.TextXAlignment.Left
    self.searchBox.Parent = self.searchFrame
    
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Name = "SearchIcon"
    searchIcon.Size = UDim2.new(0, 10, 0, 10)
    searchIcon.Position = UDim2.new(1, -14, 0.5, -5)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextColor3 = Color3.fromRGB(150, 150, 160)
    searchIcon.TextSize = self.isMobile and 6 or 8
    searchIcon.Parent = self.searchFrame
    
    self.searchBox.Changed:Connect(function()
        self:filterSidebarItems(self.searchBox.Text)
    end)
end

function GUI:createContentArea()
    local sidebarWidth = self.isMobile and 90 or 115
    local titleHeight = self.isMobile and 25 or 30
    
    self.contentArea = Instance.new("Frame")
    self.contentArea.Name = "ContentArea"
    self.contentArea.Size = UDim2.new(1, -sidebarWidth, 1, -titleHeight)
    self.contentArea.Position = UDim2.new(0, sidebarWidth, 0, titleHeight)
    self.contentArea.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    self.contentArea.BackgroundTransparency = 0.15
    self.contentArea.BorderSizePixel = 0
    self.contentArea.Parent = self.mainFrame
    
    self.contentScrolling = Instance.new("ScrollingFrame")
    self.contentScrolling.Name = "ContentScrolling"
    self.contentScrolling.Size = UDim2.new(1, 0, 1, 0)
    self.contentScrolling.Position = UDim2.new(0, 0, 0, 0)
    self.contentScrolling.BackgroundTransparency = 1
    self.contentScrolling.BorderSizePixel = 0
    self.contentScrolling.ScrollBarThickness = self.isMobile and 2 or 3
    self.contentScrolling.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    self.contentScrolling.Parent = self.contentArea
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, self.isMobile and 3 or 4)
    contentLayout.Parent = self.contentScrolling
    
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, self.isMobile and 6 or 8)
    contentPadding.PaddingBottom = UDim.new(0, self.isMobile and 6 or 8)
    contentPadding.PaddingLeft = UDim.new(0, self.isMobile and 6 or 8)
    contentPadding.PaddingRight = UDim.new(0, self.isMobile and 6 or 8)
    contentPadding.Parent = self.contentScrolling
end

function GUI:addSidebarItem(name, callback)
    local itemHeight = self.isMobile and 22 or 26
    
    local item = Instance.new("Frame")
    item.Name = name
    item.Size = UDim2.new(1, -8, 0, itemHeight)
    item.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    item.BorderSizePixel = 0
    item.Parent = self.sidebarScrolling
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 3)
    itemCorner.Parent = item
    
    local itemButton = Instance.new("TextButton")
    itemButton.Name = "ItemButton"
    itemButton.Size = UDim2.new(1, 0, 1, 0)
    itemButton.Position = UDim2.new(0, 0, 0, 0)
    itemButton.BackgroundTransparency = 1
    itemButton.Text = name
    itemButton.TextColor3 = Color3.fromRGB(200, 200, 210)
    itemButton.TextSize = self.isMobile and 9 or 12
    itemButton.Font = Enum.Font.Gotham
    itemButton.TextXAlignment = Enum.TextXAlignment.Left
    itemButton.Parent = item
    
    local itemPadding = Instance.new("UIPadding")
    itemPadding.PaddingLeft = UDim.new(0, self.isMobile and 4 or 6)
    itemPadding.Parent = itemButton
    
    local highlight = Instance.new("Frame")
    highlight.Name = "Highlight"
    highlight.Size = UDim2.new(0, 2, 0.6, 0)
    highlight.Position = UDim2.new(0, 0, 0.2, 0)
    highlight.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    highlight.BorderSizePixel = 0
    highlight.Visible = false
    highlight.Parent = item
    
    local highlightCorner = Instance.new("UICorner")
    highlightCorner.CornerRadius = UDim.new(0, 1)
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
    local toggleHeight = self.isMobile and 28 or 32
    
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = name .. "Toggle"
    toggleFrame.Size = UDim2.new(1, 0, 0, toggleHeight)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = self.contentScrolling
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggleFrame
    
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Name = "ToggleLabel"
    toggleLabel.Size = UDim2.new(1, -50, 1, 0)
    toggleLabel.Position = UDim2.new(0, self.isMobile and 6 or 8, 0, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = name
    toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleLabel.TextSize = self.isMobile and 10 or 13
    toggleLabel.Font = Enum.Font.Gotham
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.Parent = toggleFrame
    
    local switchSize = self.isMobile and {28, 16} or {34, 18}
    local knobSize = self.isMobile and 12 or 14
    
    local toggleTrack = Instance.new("Frame")
    toggleTrack.Name = "ToggleTrack"
    toggleTrack.Size = UDim2.new(0, switchSize[1], 0, switchSize[2])
    toggleTrack.Position = UDim2.new(1, -switchSize[1] - (self.isMobile and 6 or 8), 0.5, -switchSize[2]/2)
    toggleTrack.BackgroundColor3 = defaultValue and Color3.fromRGB(33, 150, 243) or Color3.fromRGB(97, 97, 97)
    toggleTrack.BorderSizePixel = 0
    toggleTrack.Parent = toggleFrame
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, switchSize[2]/2)
    trackCorner.Parent = toggleTrack
    
    local toggleKnob = Instance.new("Frame")
    toggleKnob.Name = "ToggleKnob"
    toggleKnob.Size = UDim2.new(0, knobSize, 0, knobSize)
    toggleKnob.Position = defaultValue and UDim2.new(1, -knobSize - 2, 0.5, -knobSize/2) or UDim2.new(0, 2, 0.5, -knobSize/2)
    toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleKnob.BorderSizePixel = 0
    toggleKnob.ZIndex = 2
    toggleKnob.Parent = toggleTrack
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, knobSize/2)
    knobCorner.Parent = toggleKnob
    
    local knobShadow = Instance.new("Frame")
    knobShadow.Name = "KnobShadow"
    knobShadow.Size = UDim2.new(1, 2, 1, 2)
    knobShadow.Position = UDim2.new(0, -1, 0, -1)
    knobShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    knobShadow.BackgroundTransparency = 0.4
    knobShadow.ZIndex = 1
    knobShadow.Parent = toggleKnob
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, knobSize/2 + 1)
    shadowCorner.Parent = knobShadow
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(1, 16, 1, 16)
    toggleButton.Position = UDim2.new(0, -8, 0, -8)
    toggleButton.BackgroundTransparency = 1
    toggleButton.Text = ""
    toggleButton.ZIndex = 3
    toggleButton.Parent = toggleTrack
    
    local isToggled = defaultValue
    
    local function animateToggle()
        local trackColor = isToggled and Color3.fromRGB(33, 150, 243) or Color3.fromRGB(97, 97, 97)
        local knobPosition = isToggled and UDim2.new(1, -knobSize - 2, 0.5, -knobSize/2) or UDim2.new(0, 2, 0.5, -knobSize/2)
        
        local ripple = Instance.new("Frame")
        ripple.Name = "Ripple"
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
        ripple.BackgroundColor3 = isToggled and Color3.fromRGB(33, 150, 243) or Color3.fromRGB(97, 97, 97)
        ripple.BackgroundTransparency = 0.7
        ripple.BorderSizePixel = 0
        ripple.ZIndex = 1
        ripple.Parent = toggleKnob
        
        local rippleCorner = Instance.new("UICorner")
        rippleCorner.CornerRadius = UDim.new(1, 0)
        rippleCorner.Parent = ripple
        
        local rippleExpand = TweenService:Create(ripple, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0.5, -10, 0.5, -10),
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
    local dropdownHeight = self.isMobile and 28 or 32
    
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Name = name .. "Dropdown"
    dropdownFrame.Size = UDim2.new(1, 0, 0, dropdownHeight)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    dropdownFrame.BorderSizePixel = 0
    dropdownFrame.Parent = self.contentScrolling
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 4)
    dropdownCorner.Parent = dropdownFrame
    
    local dropdownLabel = Instance.new("TextLabel")
    dropdownLabel.Name = "DropdownLabel"
    dropdownLabel.Size = UDim2.new(0.5, 0, 1, 0)
    dropdownLabel.Position = UDim2.new(0, self.isMobile and 6 or 8, 0, 0)
    dropdownLabel.BackgroundTransparency = 1
    dropdownLabel.Text = name
    dropdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownLabel.TextSize = self.isMobile and 10 or 13
    dropdownLabel.Font = Enum.Font.Gotham
    dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
    dropdownLabel.Parent = dropdownFrame
    
    local buttonWidth = self.isMobile and 80 or 100
    local buttonHeight = self.isMobile and 18 or 20
    
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Name = "DropdownButton"
    dropdownButton.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
    dropdownButton.Position = UDim2.new(1, -buttonWidth - (self.isMobile and 6 or 8), 0.5, -buttonHeight/2)
    dropdownButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    dropdownButton.BorderSizePixel = 0
    dropdownButton.Text = defaultOption or options[1] or "Select"
    dropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownButton.TextSize = self.isMobile and 9 or 12
    dropdownButton.Font = Enum.Font.Gotham
    dropdownButton.Parent = dropdownFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 3)
    buttonCorner.Parent = dropdownButton
    
    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.new(0, 10, 0, 10)
    arrow.Position = UDim2.new(1, -12, 0.5, -5)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Color3.fromRGB(200, 200, 200)
    arrow.TextSize = self.isMobile and 6 or 8
    arrow.Font = Enum.Font.Gotham
    arrow.Parent = dropdownButton
    
    self.dropdownSelections[name] = defaultOption or options[1] or ""
    
    dropdownButton.MouseButton1Click:Connect(function()
        self:createDropdownDialog(name, options, defaultOption, callback, dropdownButton)
    end)
    
    return dropdownFrame
end

function GUI:createDropdownDialog(title, options, defaultOption, callback, button)
    local dialogSize = self.isMobile and {240, 200} or {280, 240}
    
    local overlay = Instance.new("Frame")
    overlay.Name = "DropdownOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 25
    overlay.Parent = self.screenGui
    
    local dialog = Instance.new("Frame")
    dialog.Name = "DropdownDialog"
    dialog.Size = UDim2.new(0, dialogSize[1], 0, dialogSize[2])
    dialog.Position = UDim2.new(0.5, -dialogSize[1]/2, 0.5, -dialogSize[2]/2)
    dialog.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 30
    dialog.Parent = overlay
    
    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = UDim.new(0, 6)
    dialogCorner.Parent = dialog
    
    local dialogTitle = Instance.new("TextLabel")
    dialogTitle.Name = "DialogTitle"
    dialogTitle.Size = UDim2.new(1, -30, 0, 25)
    dialogTitle.Position = UDim2.new(0, 8, 0, 6)
    dialogTitle.BackgroundTransparency = 1
    dialogTitle.Text = "Select " .. title
    dialogTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    dialogTitle.TextSize = self.isMobile and 12 or 16
    dialogTitle.Font = Enum.Font.GothamBold
    dialogTitle.TextXAlignment = Enum.TextXAlignment.Left
    dialogTitle.Parent = dialog
    
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 16, 0, 16)
    closeButton.Position = UDim2.new(1, -22, 0, 6)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 95, 87)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = self.isMobile and 8 or 10
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = dialog
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    local searchFrame = Instance.new("Frame")
    searchFrame.Name = "SearchFrame"
    searchFrame.Size = UDim2.new(1, -16, 0, self.isMobile and 20 or 24)
    searchFrame.Position = UDim2.new(0, 8, 0, 32)
    searchFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = dialog
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 3)
    searchCorner.Parent = searchFrame
    
    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -20, 1, 0)
    searchBox.Position = UDim2.new(0, 6, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search options..."
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
    searchBox.TextSize = self.isMobile and 8 or 10
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.Parent = searchFrame
    
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Name = "SearchIcon"
    searchIcon.Size = UDim2.new(0, 10, 0, 10)
    searchIcon.Position = UDim2.new(1, -14, 0.5, -5)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextColor3 = Color3.fromRGB(150, 150, 160)
    searchIcon.TextSize = self.isMobile and 6 or 8
    searchIcon.Parent = searchFrame
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "OptionsScroll"
    scrollFrame.Size = UDim2.new(1, -16, 1, -66)
    scrollFrame.Position = UDim2.new(0, 8, 0, 58)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 2
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    scrollFrame.Parent = dialog
    
    local optionLayout = Instance.new("UIListLayout")
    optionLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optionLayout.Padding = UDim.new(0, 1)
    optionLayout.Parent = scrollFrame
    
    local optionFrames = {}
    local currentSelection = self.dropdownSelections[title]
    
    for i, option in ipairs(options) do
        local optionFrame = Instance.new("Frame")
        optionFrame.Name = "Option" .. i
        optionFrame.Size = UDim2.new(1, 0, 0, self.isMobile and 22 or 26)
        optionFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        optionFrame.BorderSizePixel = 0
        optionFrame.Parent = scrollFrame
        
        local optionCorner = Instance.new("UICorner")
        optionCorner.CornerRadius = UDim.new(0, 3)
        optionCorner.Parent = optionFrame
        
        local highlightBorder = Instance.new("UIStroke")
        highlightBorder.Name = "HighlightBorder"
        highlightBorder.Color = Color3.fromRGB(76, 175, 80)
        highlightBorder.Thickness = 2.5
        highlightBorder.Enabled = (option == currentSelection)
        highlightBorder.Transparency = 0
        highlightBorder.Parent = optionFrame
        
        local highlightGlow = Instance.new("Frame")
        highlightGlow.Name = "HighlightGlow"
        highlightGlow.Size = UDim2.new(1, 0, 1, 0)
        highlightGlow.Position = UDim2.new(0, 0, 0, 0)
        highlightGlow.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        highlightGlow.BackgroundTransparency = (option == currentSelection) and 0.85 or 1
        highlightGlow.BorderSizePixel = 0
        highlightGlow.ZIndex = 0
        highlightGlow.Parent = optionFrame
        
        local glowCorner = Instance.new("UICorner")
        glowCorner.CornerRadius = UDim.new(0, 3)
        glowCorner.Parent = highlightGlow
        
        local checkIcon = Instance.new("TextLabel")
        checkIcon.Name = "CheckIcon"
        checkIcon.Size = UDim2.new(0, 16, 0, 16)
        checkIcon.Position = UDim2.new(1, -20, 0.5, -8)
        checkIcon.BackgroundTransparency = 1
        checkIcon.Text = "✓"
        checkIcon.TextColor3 = Color3.fromRGB(76, 175, 80)
        checkIcon.TextSize = self.isMobile and 10 or 12
        checkIcon.Font = Enum.Font.GothamBold
        checkIcon.Visible = (option == currentSelection)
        checkIcon.ZIndex = 2
        checkIcon.Parent = optionFrame
        
        local optionButton = Instance.new("TextButton")
        optionButton.Name = "OptionButton"
        optionButton.Size = UDim2.new(1, 0, 1, 0)
        optionButton.BackgroundTransparency = 1
        optionButton.Text = option
        optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        optionButton.TextSize = self.isMobile and 8 or 10
        optionButton.Font = Enum.Font.Gotham
        optionButton.TextXAlignment = Enum.TextXAlignment.Left
        optionButton.Parent = optionFrame
        
        local optionPadding = Instance.new("UIPadding")
        optionPadding.PaddingLeft = UDim.new(0, 6)
        optionPadding.Parent = optionButton
        
        optionFrames[option] = {frame = optionFrame, border = highlightBorder, glow = highlightGlow, check = checkIcon}
        
        optionButton.MouseEnter:Connect(function()
            if not highlightBorder.Enabled then
                local hoverTween = TweenService:Create(optionFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(55, 55, 65)})
                local glowTween = TweenService:Create(highlightGlow, TweenInfo.new(0.15), {BackgroundTransparency = 0.92})
                hoverTween:Play()
                glowTween:Play()
            end
        end)
        
        optionButton.MouseLeave:Connect(function()
            if not highlightBorder.Enabled then
                local hoverTween = TweenService:Create(optionFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)})
                local glowTween = TweenService:Create(highlightGlow, TweenInfo.new(0.15), {BackgroundTransparency = 1})
                hoverTween:Play()
                glowTween:Play()
            end
        end)
        
        optionButton.MouseButton1Click:Connect(function()
            for _, data in pairs(optionFrames) do
                data.border.Enabled = false
                data.check.Visible = false
                local glowTween = TweenService:Create(data.glow, TweenInfo.new(0.2), {BackgroundTransparency = 1})
                glowTween:Play()
            end
            
            highlightBorder.Enabled = true
            checkIcon.Visible = true
            local selectGlowTween = TweenService:Create(highlightGlow, TweenInfo.new(0.2), {BackgroundTransparency = 0.85})
            selectGlowTween:Play()
            
            local ripple = Instance.new("Frame")
            ripple.Name = "SelectRipple"
            ripple.Size = UDim2.new(0, 0, 0, 0)
            ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
            ripple.AnchorPoint = Vector2.new(0.5, 0.5)
            ripple.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
            ripple.BackgroundTransparency = 0.3
            ripple.BorderSizePixel = 0
            ripple.ZIndex = 1
            ripple.Parent = optionFrame
            
            local rippleCorner = Instance.new("UICorner")
            rippleCorner.CornerRadius = UDim.new(1, 0)
            rippleCorner.Parent = ripple
            
            local rippleExpand = TweenService:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 100, 0, 100),
                BackgroundTransparency = 1
            })
            
            rippleExpand:Play()
            rippleExpand.Completed:Connect(function()
                ripple:Destroy()
            end)
            
            self.dropdownSelections[title] = option
            
            button.Text = option
            
            wait(0.1)
            overlay:Destroy()
            
            if callback then
                callback(option, i)
            end
        end)
    end
    
    local function filterOptions(searchText)
        searchText = searchText:lower()
        for option, data in pairs(optionFrames) do
            if searchText == "" or option:lower():find(searchText) then
                data.frame.Visible = true
            else
                data.frame.Visible = false
            end
        end
    end
    
    searchBox.Changed:Connect(function()
        filterOptions(searchBox.Text)
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        overlay:Destroy()
    end)
    
    overlay.MouseButton1Click:Connect(function()
        overlay:Destroy()
    end)
    
    dialog.MouseButton1Click:Connect(function(input)
        input.Handled = true
    end)
    
    dialog.Position = UDim2.new(0.5, -dialogSize[1]/2, 0.5, -dialogSize[2] - 40)
    local tween = TweenService:Create(dialog, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, -dialogSize[1]/2, 0.5, -dialogSize[2]/2)})
    tween:Play()
    
    return dialog
end

function GUI:addButton(name, callback)
    local buttonHeight = self.isMobile and 24 or 28
    
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = name .. "ButtonFrame"
    buttonFrame.Size = UDim2.new(1, 0, 0, buttonHeight + 6)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = self.contentScrolling
    
    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Size = UDim2.new(1, -12, 0, buttonHeight)
    button.Position = UDim2.new(0, 6, 0, 3)
    button.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = self.isMobile and 10 or 13
    button.Font = Enum.Font.GothamBold
    button.Parent = buttonFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = button
    
    local buttonShadow = Instance.new("Frame")
    buttonShadow.Name = "ButtonShadow"
    buttonShadow.Size = UDim2.new(1, 3, 1, 3)
    buttonShadow.Position = UDim2.new(0, -1.5, 0, -1.5)
    buttonShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    buttonShadow.BackgroundTransparency = 0.6
    buttonShadow.ZIndex = -1
    buttonShadow.Parent = button
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 5.5)
    shadowCorner.Parent = buttonShadow
    
    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(63, 180, 255)})
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(33, 150, 243)})
        tween:Play()
    end)
    
    button.MouseButton1Click:Connect(function()
        for _, dialog in ipairs(self.dialogs) do
            if dialog and dialog.Parent then
                dialog:Destroy()
            end
        end
        self.dialogs = {}
        
        local ripple = Instance.new("Frame")
        ripple.Name = "Ripple"
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.7
        ripple.BorderSizePixel = 0
        ripple.ZIndex = 2
        ripple.Parent = button
        
        local rippleCorner = Instance.new("UICorner")
        rippleCorner.CornerRadius = UDim.new(1, 0)
        rippleCorner.Parent = ripple
        
        local rippleExpand = TweenService:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 80, 0, 80),
            Position = UDim2.new(0.5, -40, 0.5, -40),
            BackgroundTransparency = 1
        })
        
        rippleExpand:Play()
        rippleExpand.Completed:Connect(function()
            ripple:Destroy()
        end)
        
        if callback then
            callback()
        end
    end)
    
    return buttonFrame
end

function GUI:addSlider(name, minValue, maxValue, defaultValue, callback)
    local sliderHeight = self.isMobile and 32 or 36
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = name .. "Slider"
    sliderFrame.Size = UDim2.new(1, 0, 0, sliderHeight)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = self.contentScrolling
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 4)
    sliderCorner.Parent = sliderFrame
    
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Name = "SliderLabel"
    sliderLabel.Size = UDim2.new(1, -40, 0, 14)
    sliderLabel.Position = UDim2.new(0, self.isMobile and 6 or 8, 0, 2)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = name
    sliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sliderLabel.TextSize = self.isMobile and 10 or 13
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.Parent = sliderFrame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.new(0, 35, 0, 14)
    valueLabel.Position = UDim2.new(1, -41, 0, 2)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = Color3.fromRGB(33, 150, 243)
    valueLabel.TextSize = self.isMobile and 10 or 13
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = sliderFrame
    
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Name = "SliderTrack"
    sliderTrack.Size = UDim2.new(1, -16, 0, 3)
    sliderTrack.Position = UDim2.new(0, 8, 1, -12)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Parent = sliderFrame
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 1.5)
    trackCorner.Parent = sliderTrack
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "SliderFill"
    sliderFill.Size = UDim2.new((defaultValue - minValue) / (maxValue - minValue), 0, 1, 0)
    sliderFill.Position = UDim2.new(0, 0, 0, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderTrack
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 1.5)
    fillCorner.Parent = sliderFill
    
    local sliderKnob = Instance.new("Frame")
    sliderKnob.Name = "SliderKnob"
    sliderKnob.Size = UDim2.new(0, self.isMobile and 12 or 14, 0, self.isMobile and 12 or 14)
    sliderKnob.Position = UDim2.new((defaultValue - minValue) / (maxValue - minValue), self.isMobile and -6 or -7, 0.5, self.isMobile and -6 or -7)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    sliderKnob.BorderSizePixel = 0
    sliderKnob.ZIndex = 2
    sliderKnob.Parent = sliderTrack
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = sliderKnob
    
    local knobShadow = Instance.new("Frame")
    knobShadow.Name = "KnobShadow"
    knobShadow.Size = UDim2.new(1, 3, 1, 3)
    knobShadow.Position = UDim2.new(0, -1.5, 0, -1.5)
    knobShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    knobShadow.BackgroundTransparency = 0.3
    knobShadow.ZIndex = 1
    knobShadow.Parent = sliderKnob
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(1, 0)
    shadowCorner.Parent = knobShadow
    
    local currentValue = defaultValue
    local dragging = false
    
    local function updateSlider(input)
        local relativePos = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
        currentValue = math.floor(minValue + (maxValue - minValue) * relativePos)
        
        valueLabel.Text = tostring(currentValue)
        
        local fillTween = TweenService:Create(sliderFill, TweenInfo.new(0.1), {Size = UDim2.new(relativePos, 0, 1, 0)})
        local knobTween = TweenService:Create(sliderKnob, TweenInfo.new(0.1), {Position = UDim2.new(relativePos, self.isMobile and -6 or -7, 0.5, self.isMobile and -6 or -7)})
        
        fillTween:Play()
        knobTween:Play()
        
        if callback then
            callback(currentValue)
        end
    end
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    return sliderFrame
end

function GUI:addTextInput(name, placeholder, callback)
    local inputHeight = self.isMobile and 45 or 55
    
    local inputFrame = Instance.new("Frame")
    inputFrame.Name = name .. "Input"
    inputFrame.Size = UDim2.new(1, 0, 0, inputHeight)
    inputFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    inputFrame.BackgroundTransparency = 0.1
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = self.contentScrolling
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputFrame
    
    local inputContainer = Instance.new("Frame")
    inputContainer.Name = "InputContainer"
    inputContainer.Size = UDim2.new(1, -16, 0, self.isMobile and 30 or 36)
    inputContainer.Position = UDim2.new(0, 8, 1, self.isMobile and -36 or -42)
    inputContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    inputContainer.BackgroundTransparency = 0.2
    inputContainer.BorderSizePixel = 0
    inputContainer.Parent = inputFrame
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 4)
    containerCorner.Parent = inputContainer
    
    local containerStroke = Instance.new("UIStroke")
    containerStroke.Name = "ContainerStroke"
    containerStroke.Color = Color3.fromRGB(80, 80, 90)
    containerStroke.Thickness = 1.5
    containerStroke.Transparency = 0.3
    containerStroke.Parent = inputContainer
    
    local underline = Instance.new("Frame")
    underline.Name = "Underline"
    underline.Size = UDim2.new(0, 0, 0, 3)
    underline.Position = UDim2.new(0.5, 0, 1, -3)
    underline.AnchorPoint = Vector2.new(0.5, 0)
    underline.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    underline.BorderSizePixel = 0
    underline.Parent = inputContainer
    
    local underlineCorner = Instance.new("UICorner")
    underlineCorner.CornerRadius = UDim.new(0, 1.5)
    underlineCorner.Parent = underline
    
    local textBox = Instance.new("TextBox")
    textBox.Name = "TextBox"
    textBox.Size = UDim2.new(1, -16, 1, 0)
    textBox.Position = UDim2.new(0, 8, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.Text = ""
    textBox.PlaceholderText = ""
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
    textBox.TextSize = self.isMobile and 12 or 15
    textBox.Font = Enum.Font.Gotham
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false
    textBox.Parent = inputContainer
    
    local floatingLabel = Instance.new("TextLabel")
    floatingLabel.Name = "FloatingLabel"
    floatingLabel.Size = UDim2.new(0, 200, 0, 20)
    floatingLabel.Position = UDim2.new(0, 8, 0, self.isMobile and 10 or 12)
    floatingLabel.BackgroundTransparency = 1
    floatingLabel.Text = placeholder or name
    floatingLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
    floatingLabel.TextSize = self.isMobile and 12 or 15
    floatingLabel.Font = Enum.Font.Gotham
    floatingLabel.TextXAlignment = Enum.TextXAlignment.Left
    floatingLabel.ZIndex = 3
    floatingLabel.Parent = inputContainer
    
    local labelBackground = Instance.new("Frame")
    labelBackground.Name = "LabelBackground"
    labelBackground.Size = UDim2.new(0, 0, 0, 4)
    labelBackground.Position = UDim2.new(0, 8, 0, -2)
    labelBackground.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    labelBackground.BackgroundTransparency = 0.1
    labelBackground.BorderSizePixel = 0
    labelBackground.Visible = false
    labelBackground.ZIndex = 2
    labelBackground.Parent = inputContainer
    
    local labelName = Instance.new("TextLabel")
    labelName.Name = "LabelName"
    labelName.Size = UDim2.new(1, -16, 0, 14)
    labelName.Position = UDim2.new(0, 8, 0, 2)
    labelName.BackgroundTransparency = 1
    labelName.Text = name
    labelName.TextColor3 = Color3.fromRGB(255, 255, 255)
    labelName.TextSize = self.isMobile and 11 or 14
    labelName.Font = Enum.Font.GothamMedium
    labelName.TextXAlignment = Enum.TextXAlignment.Left
    labelName.Parent = inputFrame
    
    local rippleFrame = Instance.new("Frame")
    rippleFrame.Name = "RippleFrame"
    rippleFrame.Size = UDim2.new(1, 0, 1, 0)
    rippleFrame.Position = UDim2.new(0, 0, 0, 0)
    rippleFrame.BackgroundTransparency = 1
    rippleFrame.ClipsDescendants = true
    rippleFrame.Parent = inputContainer
    
    local rippleCorner2 = Instance.new("UICorner")
    rippleCorner2.CornerRadius = UDim.new(0, 4)
    rippleCorner2.Parent = rippleFrame
    
    local function createRipple(position)
        local ripple = Instance.new("Frame")
        ripple.Name = "Ripple"
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.Position = UDim2.new(0, position.X - rippleFrame.AbsolutePosition.X, 0, position.Y - rippleFrame.AbsolutePosition.Y)
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
        ripple.BackgroundTransparency = 0.8
        ripple.BorderSizePixel = 0
        ripple.ZIndex = 1
        ripple.Parent = rippleFrame
        
        local rippleCorner = Instance.new("UICorner")
        rippleCorner.CornerRadius = UDim.new(1, 0)
        rippleCorner.Parent = ripple
        
        local rippleExpand = TweenService:Create(ripple, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 100, 0, 100),
            BackgroundTransparency = 1
        })
        
        rippleExpand:Play()
        rippleExpand.Completed:Connect(function()
            ripple:Destroy()
        end)
    end
    
    local function animateLabel(focused, clickPosition)
        local isActive = focused or textBox.Text ~= ""
        
        if focused and clickPosition then
            createRipple(clickPosition)
        end
        
        if isActive then
            local labelSize = floatingLabel.TextBounds.X + 12
            
            local labelTween = TweenService:Create(floatingLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 8, 0, -10),
                TextSize = self.isMobile and 9 or 12,
                TextColor3 = focused and Color3.fromRGB(33, 150, 243) or Color3.fromRGB(190, 190, 200)
            })
            
            local backgroundTween = TweenService:Create(labelBackground, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, labelSize, 0, 4)
            })
            
            labelBackground.Visible = true
            labelTween:Play()
            backgroundTween:Play()
        else
            local labelTween = TweenService:Create(floatingLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 8, 0, self.isMobile and 10 or 12),
                TextSize = self.isMobile and 12 or 15,
                TextColor3 = Color3.fromRGB(160, 160, 170)
            })
            
            local backgroundTween = TweenService:Create(labelBackground, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 0, 0, 4)
            })
            
            labelTween:Play()
            backgroundTween:Play()
            
            backgroundTween.Completed:Connect(function()
                if not (focused or textBox.Text ~= "") then
                    labelBackground.Visible = false
                end
            end)
        end
        
        local strokeTween = TweenService:Create(containerStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Color = focused and Color3.fromRGB(33, 150, 243) or Color3.fromRGB(80, 80, 90),
            Thickness = focused and 2.5 or 1.5,
            Transparency = focused and 0 or 0.3
        })
        
        local underlineTween = TweenService:Create(underline, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = focused and UDim2.new(1, 0, 0, 3) or UDim2.new(0, 0, 0, 3)
        })
        
        local containerTween = TweenService:Create(inputContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = focused and Color3.fromRGB(50, 50, 60) or Color3.fromRGB(45, 45, 55),
            BackgroundTransparency = focused and 0.1 or 0.2
        })
        
        strokeTween:Play()
        underlineTween:Play()
        containerTween:Play()
    end
    
    textBox.Focused:Connect(function()
        local mouse = game.Players.LocalPlayer:GetMouse()
        animateLabel(true, Vector2.new(mouse.X, mouse.Y))
    end)
    
    textBox.FocusLost:Connect(function()
        animateLabel(false)
        if callback then
            callback(textBox.Text)
        end
    end)
    
    textBox.Changed:Connect(function()
        if textBox.Text ~= "" and floatingLabel.Position.Y.Offset > 0 then
            animateLabel(false)
        end
    end)
    
    inputContainer.MouseEnter:Connect(function()
        if not textBox:IsFocused() then
            local hoverTween = TweenService:Create(inputContainer, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = Color3.fromRGB(48, 48, 58),
                BackgroundTransparency = 0.15
            })
            
            local strokeHoverTween = TweenService:Create(containerStroke, TweenInfo.new(0.15), {
                Transparency = 0.1
            })
            
            hoverTween:Play()
            strokeHoverTween:Play()
        end
    end)
    
    inputContainer.MouseLeave:Connect(function()
        if not textBox:IsFocused() then
            local hoverTween = TweenService:Create(inputContainer, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = Color3.fromRGB(45, 45, 55),
                BackgroundTransparency = 0.2
            })
            
            local strokeHoverTween = TweenService:Create(containerStroke, TweenInfo.new(0.15), {
                Transparency = 0.3
            })
            
            hoverTween:Play()
            strokeHoverTween:Play()
        end
    end)
    
    return inputFrame
end

function GUI:createDialog(title, content, buttons)
    local dialogSize = self.isMobile and {220, 150} or {260, 170}
    
    local overlay = Instance.new("Frame")
    overlay.Name = "DialogOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 25
    overlay.Parent = self.screenGui
    
    local dialog = Instance.new("Frame")
    dialog.Name = "Dialog"
    dialog.Size = UDim2.new(0, dialogSize[1], 0, dialogSize[2])
    dialog.Position = UDim2.new(0.5, -dialogSize[1]/2, 0.5, -dialogSize[2]/2)
    dialog.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 30
    dialog.Parent = overlay
    
    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = UDim.new(0, 4)
    dialogCorner.Parent = dialog
    
    local dialogTitle = Instance.new("TextLabel")
    dialogTitle.Name = "DialogTitle"
    dialogTitle.Size = UDim2.new(1, -16, 0, 20)
    dialogTitle.Position = UDim2.new(0, 8, 0, 6)
    dialogTitle.BackgroundTransparency = 1
    dialogTitle.Text = title
    dialogTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    dialogTitle.TextSize = self.isMobile and 10 or 12
    dialogTitle.Font = Enum.Font.GothamBold
    dialogTitle.TextXAlignment = Enum.TextXAlignment.Left
    dialogTitle.Parent = dialog
    
    local contentHeight = self.isMobile and 80 or 90
    
    local dialogContent = Instance.new("TextLabel")
    dialogContent.Name = "DialogContent"
    dialogContent.Size = UDim2.new(1, -16, 0, contentHeight)
    dialogContent.Position = UDim2.new(0, 8, 0, 28)
    dialogContent.BackgroundTransparency = 1
    dialogContent.Text = content
    dialogContent.TextColor3 = Color3.fromRGB(200, 200, 200)
    dialogContent.TextSize = self.isMobile and 10 or 13
    dialogContent.Font = Enum.Font.Gotham
    dialogContent.TextXAlignment = Enum.TextXAlignment.Left
    dialogContent.TextYAlignment = Enum.TextYAlignment.Top
    dialogContent.TextWrapped = true
    dialogContent.Parent = dialog
    
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "ButtonFrame"
    buttonFrame.Size = UDim2.new(1, -16, 0, self.isMobile and 20 or 24)
    buttonFrame.Position = UDim2.new(0, 8, 1, self.isMobile and -28 or -32)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = dialog
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    buttonLayout.Padding = UDim.new(0, 4)
    buttonLayout.Parent = buttonFrame
    
    buttons = buttons or {{"OK", function() overlay:Destroy() end}}
    
    for i, buttonData in ipairs(buttons) do
        local buttonName, buttonCallback = buttonData[1], buttonData[2]
        
        local dialogButton = Instance.new("TextButton")
        dialogButton.Name = "DialogButton" .. i
        dialogButton.Size = UDim2.new(0, self.isMobile and 40 or 50, 1, 0)
        dialogButton.BackgroundColor3 = i == 1 and Color3.fromRGB(33, 150, 243) or Color3.fromRGB(60, 60, 70)
        dialogButton.BorderSizePixel = 0
        dialogButton.Text = buttonName
        dialogButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        dialogButton.TextSize = self.isMobile and 9 or 12
        dialogButton.Font = Enum.Font.Gotham
        dialogButton.Parent = buttonFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 3)
        buttonCorner.Parent = dialogButton
        
        dialogButton.MouseButton1Click:Connect(function()
            if buttonCallback then
                buttonCallback()
            end
            overlay:Destroy()
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
    
    dialog.Position = UDim2.new(0.5, -dialogSize[1]/2, 0.5, -dialogSize[2] - 40)
    local tween = TweenService:Create(dialog, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, -dialogSize[1]/2, 0.5, -dialogSize[2]/2)})
    tween:Play()
    
    table.insert(self.dialogs, overlay)
    
    return overlay
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.mainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            self.mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
