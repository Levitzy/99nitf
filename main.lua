local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()
local Fly = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/fly.lua'))()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Multi-Tool Bot Suite",
    LoadingTitle = "Enhanced Speed Interface",
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
    Name = "Auto Chop ALL Small Trees (0.1s)",
    CurrentValue = false,
    Flag = "AutoChopToggle",
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "Fast Auto Chop Enabled",
                Content = "Chopping ALL small trees simultaneously at 0.1s speed!",
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

local TreeStatusLabel = TreeTab:CreateLabel("Status: Ready - Fast Mode 0.1s")

local FuelToggle = FuelTab:CreateToggle({
    Name = "Auto Fuel to Position (0,4,-3)",
    CurrentValue = false,
    Flag = "AutoFuelToggle",
    Callback = function(Value)
        AutoFuel.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "Auto Fuel Enabled",
                Content = "Fast teleporting fuel to (0,4,-3) with improved drop speed!",
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

local FuelStatusLabel = FuelTab:CreateLabel("Status: Ready - Enhanced Speed")

local ComboToggle = UtilityTab:CreateToggle({
    Name = "Tree + Fuel Combo (FAST)",
    CurrentValue = false,
    Flag = "ComboBotToggle",
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        AutoFuel.setEnabled(Value)
        
        if Value then
            Rayfield:Notify({
                Title = "FAST Combo Bot Enabled",
                Content = "Ultra-fast tree chopping (0.1s) + fuel teleporting to (0,4,-3)!",
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

local ComboStatusLabel = UtilityTab:CreateLabel("Combo Status: Both bots disabled")

RunService.Heartbeat:Connect(function()
    local treeStatus, treeCount, closestDistance = TreeChopper.getStatus()
    TreeStatusLabel:Set(treeStatus)
    
    local fuelStatus, distance = AutoFuel.getStatus()
    FuelStatusLabel:Set(fuelStatus)
    
    local chopEnabled = TreeChopper.autoChopEnabled
    local fuelEnabled = AutoFuel.autoFuelEnabled
    
    if chopEnabled and fuelEnabled then
        ComboStatusLabel:Set("Combo Status: FAST MODE - Both bots active")
    elseif chopEnabled then
        ComboStatusLabel:Set("Combo Status: Only Tree Chopper active (FAST)")
    elseif fuelEnabled then
        ComboStatusLabel:Set("Combo Status: Only Auto Fuel active (FAST)")
    else
        ComboStatusLabel:Set("Combo Status: Both bots disabled")
    end
end)

Rayfield:Notify({
    Title = "Enhanced Multi-Tool Suite",
    Content = "FAST MODE loaded! Tree chopper at 0.1s, improved fuel teleporting!",
    Duration = 6,
    Image = 4483362458
})