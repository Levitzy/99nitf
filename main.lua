local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()
local Fly = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/fly.lua'))()
local AutoKill = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autokill.lua'))()
local AutoCook = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autocook.lua'))()
local AutoPlant = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autoplant.lua'))()

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Forest Automation Suite v2.0",
    SubTitle = "Ultimate Forest Management System",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Flight = Window:AddTab({ Title = "✈️ Flight", Icon = "plane" }),
    Forest = Window:AddTab({ Title = "🌲 Forest", Icon = "trees" }),
    Combat = Window:AddTab({ Title = "⚔️ Combat", Icon = "sword" }),
    Combo = Window:AddTab({ Title = "🚀 Combo", Icon = "zap" }),
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

local ForestCombo = Tabs.Combo:AddToggle("ForestCombo", {
    Title = "🌲 Forest Management Combo",
    Description = "Tree Chopper + Auto Fuel + Auto Plant",
    Default = false
})

ForestCombo:OnChanged(function(Value)
    TreeChopper.setEnabled(Value)
    AutoFuel.setEnabled(Value)
    AutoPlant.setEnabled(Value)
    
    if Value then
        Fluent:Notify({
            Title = "Forest Combo",
            Content = "Complete forest management enabled!",
            Duration = 4
        })
    else
        Fluent:Notify({
            Title = "Forest Combo",
            Content = "Forest automation stopped",
            Duration = 2
        })
    end
end)

local SurvivalCombo = Tabs.Combo:AddToggle("SurvivalCombo", {
    Title = "⚔️ Survival Combo",
    Description = "Combat System + Cooking System",
    Default = false
})

SurvivalCombo:OnChanged(function(Value)
    AutoKill.setEnabled(Value)
    AutoCook.setEnabled(Value)
    
    if Value then
        Fluent:Notify({
            Title = "Survival Combo",
            Content = "Combat and cooking systems online!",
            Duration = 4
        })
    else
        Fluent:Notify({
            Title = "Survival Combo",
            Content = "Survival automation stopped",
            Duration = 2
        })
    end
end)

local UltimateCombo = Tabs.Combo:AddToggle("UltimateCombo", {
    Title = "🚀 ULTIMATE MODE",
    Description = "Enable ALL 5 automation systems for complete AFK mode",
    Default = false
})

UltimateCombo:OnChanged(function(Value)
    TreeChopper.setEnabled(Value)
    AutoFuel.setEnabled(Value)
    AutoKill.setEnabled(Value)
    AutoCook.setEnabled(Value)
    AutoPlant.setEnabled(Value)
    
    if Value then
        Fluent:Notify({
            Title = "🚀 ULTIMATE MODE",
            Content = "All 5 systems active! Complete AFK automation ready!",
            Duration = 5
        })
    else
        Fluent:Notify({
            Title = "Ultimate Mode",
            Content = "All automation systems stopped",
            Duration = 3
        })
    end
end)

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

local PlantStatus = Tabs.Settings:AddParagraph({
    Title = "🌱 Plant Status",
    Content = "Ready"
})

local SystemStatus = Tabs.Settings:AddParagraph({
    Title = "🚀 System Overview",
    Content = "All systems offline"
})

RunService.Heartbeat:Connect(function()
    local treeStatusText, treeCount, closestDistance = TreeChopper.getStatus()
    TreeStatus:SetDesc(treeStatusText)
    
    local fuelStatusText, distance = AutoFuel.getStatus()
    FuelStatus:SetDesc(fuelStatusText)
    
    local killStatusText, targetCount, closestTargetDistance = AutoKill.getStatus()
    CombatStatus:SetDesc("Targets: " .. killStatusText)
    
    local cookStatusText, meatCount = AutoCook.getStatus()
    CookStatus:SetDesc(cookStatusText)
    
    local plantStatusText, saplingCount = AutoPlant.getStatus()
    PlantStatus:SetDesc(plantStatusText)
    
    local chopEnabled = TreeChopper.autoChopEnabled
    local fuelEnabled = AutoFuel.autoFuelEnabled
    local killEnabled = AutoKill.autoKillEnabled
    local cookEnabled = AutoCook.autoCookEnabled
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
    if plantEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Plant")
    end
    
    if activeCount == 5 then
        SystemStatus:SetDesc("🚀 ULTIMATE MODE: All 5 systems running perfectly!")
    elseif activeCount >= 3 then
        SystemStatus:SetDesc("🔥 Multi-System Active: " .. activeCount .. "/5 systems (" .. table.concat(activeSystems, ", ") .. ")")
    elseif activeCount == 2 then
        SystemStatus:SetDesc("⚡ Dual-System Mode: " .. table.concat(activeSystems, " + ") .. " active")
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
    Title = "Forest Automation Suite v2.0",
    Content = "Ultimate forest management system loaded! 5 advanced automation bots ready.",
    Duration = 6
})