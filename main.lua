local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()
local Fly = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/fly.lua'))()
local AutoKill = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autokill.lua'))()
local AutoCook = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autocook.lua'))()
local AutoPlant = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autoplant.lua'))()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Multi-Tool Bot Suite",
    LoadingTitle = "Clean Fly-Focused Interface",
    LoadingSubtitle = "by TreeChopper",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "MultiToolConfig",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

local FlyTab = Window:CreateTab("Fly", 4483362458)
local TreeTab = Window:CreateTab("Tree Chopper", 4483362458)
local FuelTab = Window:CreateTab("Auto Fuel", 4335489011)
local KillTab = Window:CreateTab("Auto Kill", 4370317008)
local CookTab = Window:CreateTab("Auto Cook", 4335489011)
local PlantTab = Window:CreateTab("Auto Plant", 4483362458)
local UtilityTab = Window:CreateTab("Utilities", 4370317008)

local RunService = game:GetService("RunService")

local FlyToggle = FlyTab:CreateToggle({
    Name = "Enable Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        local success = Fly.setEnabled(Value)
        
        if Value and success then
            Rayfield:Notify({
                Title = "Fly Enabled",
                Content = "PC: WASD + Space/Shift | Mobile: Touch & drag to fly!",
                Duration = 4,
                Image = 4483362458
            })
        elseif Value and not success then
            Rayfield:Notify({
                Title = "Fly Failed",
                Content = "Could not enable fly - character not found!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Fly Disabled",
                Content = "Flight mode deactivated.",
                Duration = 2,
                Image = 4483362458
            })
        end
    end,
})

local FlySpeedSlider = FlyTab:CreateSlider({
    Name = "Fly Speed",
    Range = {1, 200},
    Increment = 5,
    Suffix = " Speed",
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(Value)
        Fly.setSpeed(Value)
    end,
})

local TreeToggle = TreeTab:CreateToggle({
    Name = "Auto Chop All Small Trees",
    CurrentValue = false,
    Flag = "AutoChopToggle",
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Chop Enabled",
                Content = "Started chopping ALL small trees in map!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Chop Disabled",
                Content = "Stopped chopping trees.",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})



local TreeStatusLabel = TreeTab:CreateLabel("Status: Ready")

local FuelToggle = FuelTab:CreateToggle({
    Name = "Auto Fuel to Position (0,4,-3)",
    CurrentValue = false,
    Flag = "AutoFuelToggle",
    Callback = function(Value)
        AutoFuel.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Fuel Enabled",
                Content = "Teleporting fuel to exact position (0,4,-3) - Enhanced dropping!",
                Duration = 3,
                Image = 4335489011
            })
        else
            Rayfield:Notify({
                Title = "Auto Fuel Disabled",
                Content = "Stopped moving fuel items.",
                Duration = 3,
                Image = 4335489011
            })
        end
    end,
})

local FuelStatusLabel = FuelTab:CreateLabel("Status: Ready")

local KillToggle = KillTab:CreateToggle({
    Name = "Auto Kill All Bunnies",
    CurrentValue = false,
    Flag = "AutoKillToggle",
    Callback = function(Value)
        AutoKill.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Kill Enabled",
                Content = "Started attacking all bunnies in workspace!",
                Duration = 3,
                Image = 4370317008
            })
        else
            Rayfield:Notify({
                Title = "Auto Kill Disabled",
                Content = "Stopped attacking bunnies.",
                Duration = 3,
                Image = 4370317008
            })
        end
    end,
})



local KillStatusLabel = KillTab:CreateLabel("Status: Ready")

local CookToggle = CookTab:CreateToggle({
    Name = "Auto Cook Raw Meat",
    CurrentValue = false,
    Flag = "AutoCookToggle",
    Callback = function(Value)
        AutoCook.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Cook Enabled",
                Content = "Started cooking all raw meat at MainFire!",
                Duration = 3,
                Image = 4335489011
            })
        else
            Rayfield:Notify({
                Title = "Auto Cook Disabled",
                Content = "Stopped cooking meat.",
                Duration = 3,
                Image = 4335489011
            })
        end
    end,
})

local CookStatusLabel = CookTab:CreateLabel("Status: Ready")

local PlantToggle = PlantTab:CreateToggle({
    Name = "Auto Plant Saplings",
    CurrentValue = false,
    Flag = "AutoPlantToggle",
    Callback = function(Value)
        AutoPlant.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Plant Enabled",
                Content = "Started planting all saplings at their locations!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Auto Plant Disabled",
                Content = "Stopped planting saplings.",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

local PlantStatusLabel = PlantTab:CreateLabel("Status: Ready")

local ComboToggle = UtilityTab:CreateToggle({
    Name = "Tree + Fuel Combo",
    CurrentValue = false,
    Flag = "ComboBotToggle",
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        AutoFuel.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "Combo Bot Enabled",
                Content = "Tree Chopper and Auto Fuel active! Fuel stacks at (0,4,-3)",
                Duration = 4,
                Image = 4370317008
            })
        else
            Rayfield:Notify({
                Title = "Combo Bot Disabled",
                Content = "Both bots have been stopped.",
                Duration = 3,
                Image = 4370317008
            })
        end
    end,
})

local UltimateComboToggle = UtilityTab:CreateToggle({
    Name = "Ultimate Combo (All Bots)",
    CurrentValue = false,
    Flag = "UltimateBotToggle",
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        AutoFuel.setEnabled(Value)
        AutoKill.setEnabled(Value)
        AutoCook.setEnabled(Value)
        AutoPlant.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "Ultimate Combo Enabled",
                Content = "All bots active! Complete forest automation!",
                Duration = 4,
                Image = 4370317008
            })
        else
            Rayfield:Notify({
                Title = "Ultimate Combo Disabled",
                Content = "All bots have been stopped.",
                Duration = 3,
                Image = 4370317008
            })
        end
    end,
})

local ComboStatusLabel = UtilityTab:CreateLabel("Combo Status: All bots disabled")

RunService.Heartbeat:Connect(function()
    local treeStatus, treeCount, closestDistance = TreeChopper.getStatus()
    TreeStatusLabel:Set(treeStatus)
    
    local fuelStatus, distance = AutoFuel.getStatus()
    FuelStatusLabel:Set(fuelStatus)
    
    local killStatus, bunnyCount, closestBunnyDistance = AutoKill.getStatus()
    KillStatusLabel:Set("Targets: " .. killStatus)
    
    local cookStatus, meatCount = AutoCook.getStatus()
    CookStatusLabel:Set(cookStatus)
    
    local plantStatus, saplingCount = AutoPlant.getStatus()
    PlantStatusLabel:Set(plantStatus)
    
    local chopEnabled = TreeChopper.autoChopEnabled
    local fuelEnabled = AutoFuel.autoFuelEnabled
    local killEnabled = AutoKill.autoKillEnabled
    local cookEnabled = AutoCook.autoCookEnabled
    local plantEnabled = AutoPlant.autoPlantEnabled
    
    local activeCount = 0
    if chopEnabled then activeCount = activeCount + 1 end
    if fuelEnabled then activeCount = activeCount + 1 end
    if killEnabled then activeCount = activeCount + 1 end
    if cookEnabled then activeCount = activeCount + 1 end
    if plantEnabled then activeCount = activeCount + 1 end
    
    if activeCount == 5 then
        ComboStatusLabel:Set("Combo Status: ALL 5 BOTS ACTIVE - Ultimate Forest Mode!")
    elseif activeCount >= 3 then
        ComboStatusLabel:Set(string.format("Combo Status: %d/5 bots active - Multi-bot mode", activeCount))
    elseif activeCount == 2 then
        ComboStatusLabel:Set("Combo Status: Dual-bot mode active")
    elseif activeCount == 1 then
        ComboStatusLabel:Set("Combo Status: Single bot active")
    else
        ComboStatusLabel:Set("Combo Status: All bots disabled")
    end
end)

Rayfield:Notify({
    Title = "Multi-Tool Bot Suite Load",
    Content = "Complete forest automation loaded! 5 bots ready for ultimate mode.",
    Duration = 6,
    Image = 4483362458
})