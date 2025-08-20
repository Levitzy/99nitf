local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()
local Fly = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/fly.lua'))()
local AutoKill = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/kill.lua'))()
local AutoCook = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autocook.lua'))()
local AutoPlant = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autoplant.lua'))()
local AutoFeed = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofeed.lua'))()
local Webhook = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/webhook.lua'))()

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Forest Automation Suite v2.2",
    SubTitle = "Ultimate Forest Management System",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local function createMobileToggle()
    local ScreenGui = Instance.new("ScreenGui")
    local ToggleButton = Instance.new("TextButton")
    local UICorner = Instance.new("UICorner")
    local UIStroke = Instance.new("UIStroke")
    local UISizeConstraint = Instance.new("UISizeConstraint")
    
    ScreenGui.Name = "ForestToggle"
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    
    ToggleButton.Parent = ScreenGui
    ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Position = UDim2.new(0, 20, 0, 80)
    ToggleButton.Size = UDim2.new(0, 65, 0, 65)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.Text = "🌲"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 32
    ToggleButton.ZIndex = 10000
    ToggleButton.Active = true
    ToggleButton.BackgroundTransparency = 0.1
    
    UICorner.Parent = ToggleButton
    UICorner.CornerRadius = UDim.new(0, 16)
    
    UIStroke.Parent = ToggleButton
    UIStroke.Color = Color3.fromRGB(76, 175, 80)
    UIStroke.Thickness = 3
    UIStroke.Transparency = 0.2
    
    UISizeConstraint.Parent = ToggleButton
    UISizeConstraint.MaxSize = Vector2.new(80, 80)
    UISizeConstraint.MinSize = Vector2.new(50, 50)
    
    local isVisible = true
    local isDragging = false
    local dragStart = nil
    local startPos = nil
    local clickTime = 0
    local TweenService = game:GetService("TweenService")
    
    local function createPulseEffect()
        local pulse = TweenService:Create(
            ToggleButton,
            TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {BackgroundTransparency = 0.3}
        )
        pulse:Play()
        return pulse
    end
    
    local pulseAnimation = createPulseEffect()
    
    local function updateVisualState()
        if isVisible then
            UIStroke.Color = Color3.fromRGB(76, 175, 80)
            ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 30, 20)
            UIStroke.Transparency = 0.1
        else
            UIStroke.Color = Color3.fromRGB(158, 158, 158)
            ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
            UIStroke.Transparency = 0.4
        end
    end
    
    local function animateClick()
        local clickTween = TweenService:Create(
            ToggleButton,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 75, 0, 75), TextSize = 36}
        )
        clickTween:Play()
        
        clickTween.Completed:Connect(function()
            local backTween = TweenService:Create(
                ToggleButton,
                TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 65, 0, 65), TextSize = 32}
            )
            backTween:Play()
        end)
    end
    
    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = ToggleButton.Position
            clickTime = tick()
            
            animateClick()
        end
    end)
    
    ToggleButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if isDragging and dragStart then
                local delta = input.Position - dragStart
                local newPosX = math.clamp(startPos.X.Offset + delta.X, 10, ScreenGui.AbsoluteSize.X - 75)
                local newPosY = math.clamp(startPos.Y.Offset + delta.Y, 10, ScreenGui.AbsoluteSize.Y - 75)
                ToggleButton.Position = UDim2.new(0, newPosX, 0, newPosY)
            end
        end
    end)
    
    ToggleButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isDragging then
                isDragging = false
                local timeDiff = tick() - clickTime
                
                if timeDiff < 0.3 and dragStart then
                    local dragDistance = (input.Position - dragStart).Magnitude
                    if dragDistance < 10 then
                        isVisible = not isVisible
                        Window.Root.Visible = isVisible
                        updateVisualState()
                        
                        if isVisible then
                            Fluent:Notify({
                                Title = "Forest GUI",
                                Content = "Interface restored",
                                Duration = 2
                            })
                        end
                    end
                end
                
                dragStart = nil
                startPos = nil
            end
        end
    end)
    
    updateVisualState()
    
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.LeftControl then
            isVisible = not isVisible
            Window.Root.Visible = isVisible
            updateVisualState()
        end
    end)
    
    return ToggleButton
end

local MobileToggle = createMobileToggle()

local Tabs = {
    Flight = Window:AddTab({ Title = "✈️ Flight", Icon = "plane" }),
    Forest = Window:AddTab({ Title = "🌲 Forest", Icon = "trees" }),
    Combat = Window:AddTab({ Title = "⚔️ Combat", Icon = "sword" }),
    Discord = Window:AddTab({ Title = "📢 Discord", Icon = "message-circle" }),
    Settings = Window:AddTab({ Title = "⚙️ Settings", Icon = "settings" })
}

local Options = Fluent.Options
local RunService = game:GetService("RunService")

local FlightToggle = Tabs.Flight:AddToggle("FlightToggle", {
    Title = "Enable Flight",
    Description = "Toggle flight mode with WASD controls",
    Default = false
})

FlightToggle:OnChanged(function(Value)
    local success = Fly.setEnabled(Value)
    
    if Value and success then
        Fluent:Notify({
            Title = "Flight System",
            Content = "Flight enabled! Use WASD + Space/Shift to fly",
            Duration = 4
        })
    elseif Value and not success then
        Fluent:Notify({
            Title = "Flight Error",
            Content = "Could not enable flight - character not found!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Flight System", 
            Content = "Flight disabled - landing complete",
            Duration = 2
        })
    end
end)

local FlightSpeed = Tabs.Flight:AddSlider("FlightSpeed", {
    Title = "Flight Speed",
    Description = "Adjust your flying speed",
    Default = 50,
    Min = 1,
    Max = 200,
    Rounding = 1
})

FlightSpeed:OnChanged(function(Value)
    Fly.setSpeed(Value)
end)

local TreeToggle = Tabs.Forest:AddToggle("TreeToggle", {
    Title = "Auto Tree Chopper",
    Description = "Automatically chop all small trees on the map",
    Default = false
})

TreeToggle:OnChanged(function(Value)
    TreeChopper.setEnabled(Value)
    
    if Value then
        Fluent:Notify({
            Title = "Tree Chopper",
            Content = "Started chopping all small trees!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Tree Chopper",
            Content = "Tree chopping stopped",
            Duration = 2
        })
    end
end)

local PlantToggle = Tabs.Forest:AddToggle("PlantToggle", {
    Title = "Auto Plant Saplings", 
    Description = "Plant saplings at their current locations",
    Default = false
})

PlantToggle:OnChanged(function(Value)
    AutoPlant.setEnabled(Value)
    
    if Value then
        Fluent:Notify({
            Title = "Auto Plant",
            Content = "Planting saplings for forest regeneration!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Auto Plant",
            Content = "Sapling planting stopped",
            Duration = 2
        })
    end
end)

local FuelToggle = Tabs.Forest:AddToggle("FuelToggle", {
    Title = "Auto Fuel System",
    Description = "Teleport fuel items to MainFire at (0,4,-3)",
    Default = false
})

FuelToggle:OnChanged(function(Value)
    AutoFuel.setEnabled(Value)
    
    if Value then
        Fluent:Notify({
            Title = "Auto Fuel",
            Content = "Fuel management system active!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Auto Fuel",
            Content = "Fuel automation stopped",
            Duration = 2
        })
    end
end)

local KillToggle = Tabs.Combat:AddToggle("KillToggle", {
    Title = "Auto Combat System",
    Description = "Attack all hostile creatures (Bunny, Wolf, Cultist, etc.)",
    Default = false
})

KillToggle:OnChanged(function(Value)
    AutoKill.setEnabled(Value)
    
    if Value then
        Fluent:Notify({
            Title = "Combat System",
            Content = "Engaging all hostile targets!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Combat System",
            Content = "Combat automation stopped",
            Duration = 2
        })
    end
end)

local CookToggle = Tabs.Combat:AddToggle("CookToggle", {
    Title = "Auto Cooking System",
    Description = "Cook all raw meat (Morsel & Steak) automatically",
    Default = false
})

CookToggle:OnChanged(function(Value)
    AutoCook.setEnabled(Value)
    
    if Value then
        Fluent:Notify({
            Title = "Cooking System",
            Content = "Auto-cooking all raw meat!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Cooking System", 
            Content = "Cooking automation stopped",
            Duration = 2
        })
    end
end)

local FeedToggle = Tabs.Combat:AddToggle("FeedToggle", {
    Title = "Auto Feed System",
    Description = "Automatically eat Cooked Morsels when hungry",
    Default = false
})

FeedToggle:OnChanged(function(Value)
    AutoFeed.setEnabled(Value)
    
    if Value then
        Fluent:Notify({
            Title = "Auto Feed",
            Content = "Auto-feeding system activated!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Auto Feed", 
            Content = "Auto-feeding stopped",
            Duration = 2
        })
    end
end)

local FeedThreshold = Tabs.Combat:AddDropdown("FeedThreshold", {
    Title = "Feed Threshold",
    Description = "Start feeding when hunger drops to this level",
    Values = {"25%", "50%", "75%", "80%"},
    Default = "80%"
})

FeedThreshold:OnChanged(function(Value)
    local threshold = tonumber(string.match(Value, "%d+"))
    AutoFeed.setFeedThreshold(threshold)
    
    Fluent:Notify({
        Title = "Feed Threshold",
        Content = "Feed threshold set to " .. threshold .. "%",
        Duration = 2
    })
end)

local DayTrackerToggle = Tabs.Discord:AddToggle("DayTrackerToggle", {
    Title = "Day Tracker",
    Description = "Get Discord notifications when a new day starts",
    Default = false
})

DayTrackerToggle:OnChanged(function(Value)
    Webhook.setEnabled(Value)
    
    if Value then
        Fluent:Notify({
            Title = "Day Tracker",
            Content = "Discord notifications enabled for day changes!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Day Tracker",
            Content = "Discord notifications disabled",
            Duration = 2
        })
    end
end)

local TestMessageButton = Tabs.Discord:AddButton({
    Title = "Send Test Message",
    Description = "Send a test message to Discord to verify webhook works",
    Callback = function()
        Webhook.sendTestMessage()
        Fluent:Notify({
            Title = "Test Message",
            Content = "Test message sent to Discord!",
            Duration = 2
        })
    end
})

local TreeStatus = Tabs.Settings:AddParagraph({
    Title = "🌲 Tree Status",
    Content = "Ready"
})

local FuelStatus = Tabs.Settings:AddParagraph({
    Title = "⛽ Fuel Status", 
    Content = "Ready"
})

local CombatStatus = Tabs.Settings:AddParagraph({
    Title = "⚔️ Combat Status",
    Content = "Ready"
})

local CookStatus = Tabs.Settings:AddParagraph({
    Title = "🍖 Cook Status",
    Content = "Ready"
})

local FeedStatus = Tabs.Settings:AddParagraph({
    Title = "🍽️ Feed Status",
    Content = "Ready"
})

local PlantStatus = Tabs.Settings:AddParagraph({
    Title = "🌱 Plant Status",
    Content = "Ready"
})

local DiscordStatus = Tabs.Settings:AddParagraph({
    Title = "📢 Discord Status",
    Content = "Ready"
})

local SystemStatus = Tabs.Settings:AddParagraph({
    Title = "🚀 System Overview",
    Content = "All systems offline"
})

local lastUIUpdate = 0
local UIUpdateInterval = 0.5  -- Update UI every 0.5 seconds instead of every frame

RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    
    -- Only update UI every 0.5 seconds to reduce lag
    if currentTime - lastUIUpdate < UIUpdateInterval then
        return
    end
    lastUIUpdate = currentTime
    local treeStatusText, treeCount, closestDistance = TreeChopper.getStatus()
    TreeStatus:SetDesc(treeStatusText)
    
    local fuelStatusText, distance = AutoFuel.getStatus()
    FuelStatus:SetDesc(fuelStatusText)
    
    local killStatusText, targetCount, closestTargetDistance = AutoKill.getStatus()
    CombatStatus:SetDesc("Targets: " .. killStatusText)
    
    local cookStatusText, meatCount = AutoCook.getStatus()
    CookStatus:SetDesc(cookStatusText)
    
    local feedStatusText, hungerPercent = AutoFeed.getStatus()
    FeedStatus:SetDesc(feedStatusText)
    
    local plantStatusText, saplingCount = AutoPlant.getStatus()
    PlantStatus:SetDesc(plantStatusText)
    
    local discordStatusText = Webhook.getStatus()
    DiscordStatus:SetDesc(discordStatusText)
    
    local chopEnabled = TreeChopper.autoChopEnabled
    local fuelEnabled = AutoFuel.autoFuelEnabled
    local killEnabled = AutoKill.autoKillEnabled
    local cookEnabled = AutoCook.autoCookEnabled
    local feedEnabled = AutoFeed.autoFeedEnabled
    local plantEnabled = AutoPlant.autoPlantEnabled
    
    local activeCount = 0
    local activeSystems = {}
    
    if chopEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Tree")
    end
    if fuelEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Fuel")
    end
    if killEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Combat")
    end
    if cookEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Cook")
    end
    if feedEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Feed")
    end
    if plantEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Plant")
    end
    
    if activeCount == 6 then
        SystemStatus:SetDesc("🚀 All 6 systems running perfectly!")
    elseif activeCount >= 4 then
        SystemStatus:SetDesc("🔥 Multi-System Active: " .. activeCount .. "/6 systems (" .. table.concat(activeSystems, ", ") .. ")")
    elseif activeCount >= 2 then
        SystemStatus:SetDesc("⚡ Multi-Mode: " .. table.concat(activeSystems, " + ") .. " active")
    elseif activeCount == 1 then
        SystemStatus:SetDesc("📍 Single System: " .. activeSystems[1] .. " running")
    else
        SystemStatus:SetDesc("💤 All automation systems offline - Ready to start!")
    end
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings() 
SaveManager:SetIgnoreIndexes({}) 
InterfaceManager:SetFolder("ForestAutomationSuite")
SaveManager:SetFolder("ForestAutomationSuite/configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Forest Automation Suite v2.2",
    Content = "Ultimate forest management system loaded! 6 advanced automation bots + Discord notifications ready.",
    Duration = 6
})