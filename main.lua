local function safeCall(module, methodName, ...)
    if module and module[methodName] then
        local success, result = pcall(module[methodName], ...)
        if not success then
            print("Error calling " .. methodName .. ": " .. tostring(result))
            return false, result
        end
        return true, result
    else
        local moduleName = module and "unknown module" or "nil module"
        print("Module or method not found: " .. moduleName .. "." .. methodName)
        return false, "Module not loaded"
    end
end

local function safeLoadModule(url, name)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if success and result then
        print("✅ Successfully loaded: " .. name)
        return result
    else
        print("❌ Failed to load: " .. name .. " - Error: " .. tostring(result))
        return nil
    end
end

local TreeChopper = safeLoadModule('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua', 'TreeChopper')
local AutoFuel = safeLoadModule('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua', 'AutoFuel')
local Fly = safeLoadModule('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/fly.lua', 'Fly')
local AutoKill = safeLoadModule('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autokill.lua', 'AutoKill')
local AutoCook = safeLoadModule('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autocook.lua', 'AutoCook')
local AutoPlant = safeLoadModule('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autoplant.lua', 'AutoPlant')
local AutoFeed = safeLoadModule('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofeed.lua', 'AutoFeed')
local Webhook = safeLoadModule('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/webhook.lua', 'Webhook')

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
    local success, result = safeCall(Fly, "setEnabled", Value)
    
    if Value and success then
        Fluent:Notify({
            Title = "Flight System",
            Content = "Flight enabled! Use WASD + Space/Shift to fly",
            Duration = 4
        })
    elseif Value and not success then
        Fluent:Notify({
            Title = "Flight Error",
            Content = "Could not enable flight - " .. tostring(result),
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
    safeCall(Fly, "setSpeed", Value)
end)

local TreeToggle = Tabs.Forest:AddToggle("TreeToggle", {
    Title = "Auto Tree Chopper",
    Description = "Automatically chop all small trees on the map",
    Default = false
})

TreeToggle:OnChanged(function(Value)
    local success = safeCall(TreeChopper, "setEnabled", Value)
    
    if Value and success then
        Fluent:Notify({
            Title = "Tree Chopper",
            Content = "Started chopping all small trees!",
            Duration = 3
        })
    elseif Value and not success then
        Fluent:Notify({
            Title = "Tree Chopper Error",
            Content = "Could not start tree chopper - module not loaded!",
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
    local success = safeCall(AutoPlant, "setEnabled", Value)
    
    if Value and success then
        Fluent:Notify({
            Title = "Auto Plant",
            Content = "Planting saplings for forest regeneration!",
            Duration = 3
        })
    elseif Value and not success then
        Fluent:Notify({
            Title = "Auto Plant Error",
            Content = "Could not start auto plant - module not loaded!",
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
    local success = safeCall(AutoFuel, "setEnabled", Value)
    
    if Value and success then
        Fluent:Notify({
            Title = "Auto Fuel",
            Content = "Fuel management system active!",
            Duration = 3
        })
    elseif Value and not success then
        Fluent:Notify({
            Title = "Auto Fuel Error",
            Content = "Could not start auto fuel - module not loaded!",
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
    local success = safeCall(AutoKill, "setEnabled", Value)
    
    if Value and success then
        Fluent:Notify({
            Title = "Combat System",
            Content = "Engaging all hostile targets!",
            Duration = 3
        })
    elseif Value and not success then
        Fluent:Notify({
            Title = "Combat System Error",
            Content = "Could not start combat system - module not loaded!",
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
    local success = safeCall(AutoCook, "setEnabled", Value)
    
    if Value and success then
        Fluent:Notify({
            Title = "Cooking System",
            Content = "Auto-cooking all raw meat!",
            Duration = 3
        })
    elseif Value and not success then
        Fluent:Notify({
            Title = "Cooking System Error",
            Content = "Could not start cooking system - module not loaded!",
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
    local success = safeCall(AutoFeed, "setEnabled", Value)
    
    if Value and success then
        Fluent:Notify({
            Title = "Auto Feed",
            Content = "Auto-feeding system activated!",
            Duration = 3
        })
    elseif Value and not success then
        Fluent:Notify({
            Title = "Auto Feed Error",
            Content = "Could not start auto feed - module not loaded!",
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
    safeCall(AutoFeed, "setFeedThreshold", threshold)
    
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
    local success = safeCall(Webhook, "setEnabled", Value)
    
    if Value and success then
        Fluent:Notify({
            Title = "Day Tracker",
            Content = "Discord notifications enabled for day changes!",
            Duration = 3
        })
    elseif Value and not success then
        Fluent:Notify({
            Title = "Day Tracker Error",
            Content = "Could not start day tracker - module not loaded!",
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
        local success = safeCall(Webhook, "sendTestMessage")
        if success then
            Fluent:Notify({
                Title = "Test Message",
                Content = "Test message sent to Discord!",
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Test Message Error",
                Content = "Could not send test message - webhook not loaded!",
                Duration = 3
            })
        end
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

RunService.Heartbeat:Connect(function()
    local treeStatusText, treeCount, closestDistance = "Module not loaded", 0, 0
    if TreeChopper and TreeChopper.getStatus then
        treeStatusText, treeCount, closestDistance = TreeChopper.getStatus()
    end
    TreeStatus:SetDesc(treeStatusText)
    
    local fuelStatusText, distance = "Module not loaded", 0
    if AutoFuel and AutoFuel.getStatus then
        fuelStatusText, distance = AutoFuel.getStatus()
    end
    FuelStatus:SetDesc(fuelStatusText)
    
    local killStatusText, targetCount, closestTargetDistance = "Module not loaded", 0, 0
    if AutoKill and AutoKill.getStatus then
        killStatusText, targetCount, closestTargetDistance = AutoKill.getStatus()
    end
    CombatStatus:SetDesc("Targets: " .. killStatusText)
    
    local cookStatusText, meatCount = "Module not loaded", 0
    if AutoCook and AutoCook.getStatus then
        cookStatusText, meatCount = AutoCook.getStatus()
    end
    CookStatus:SetDesc(cookStatusText)
    
    local feedStatusText, hungerPercent = "Module not loaded", 0
    if AutoFeed and AutoFeed.getStatus then
        feedStatusText, hungerPercent = AutoFeed.getStatus()
    end
    FeedStatus:SetDesc(feedStatusText)
    
    local plantStatusText, saplingCount = "Module not loaded", 0
    if AutoPlant and AutoPlant.getStatus then
        plantStatusText, saplingCount = AutoPlant.getStatus()
    end
    PlantStatus:SetDesc(plantStatusText)
    
    local discordStatusText = "Module not loaded"
    if Webhook and Webhook.getStatus then
        discordStatusText = Webhook.getStatus()
    end
    DiscordStatus:SetDesc(discordStatusText)
    
    local chopEnabled = TreeChopper and TreeChopper.autoChopEnabled or false
    local fuelEnabled = AutoFuel and AutoFuel.autoFuelEnabled or false
    local killEnabled = AutoKill and AutoKill.autoKillEnabled or false
    local cookEnabled = AutoCook and AutoCook.autoCookEnabled or false
    local feedEnabled = AutoFeed and AutoFeed.autoFeedEnabled or false
    local plantEnabled = AutoPlant and AutoPlant.autoPlantEnabled or false
    
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