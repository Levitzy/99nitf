local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()
local Fly = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/fly.lua'))()

local Flux = loadstring(game:HttpGet('https://raw.githubusercontent.com/weakhoes/Roblox-UI-Libs/refs/heads/main/Flux%20Lib/Flux%20Lib%20Source.lua'))()

local Window = Flux:Window({
    Title = "Multi-Tool Bot Suite",
    SubTitle = "Fly, Tree Chopper & Auto Fuel",
    TabWidth = 160,
    Size = UDim2.fromOffset(530, 350),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local FlyTab = Window:Tab({
    Title = "Fly",
    Icon = "rbxassetid://10734950309"
})

local TreeTab = Window:Tab({
    Title = "Tree Chopper", 
    Icon = "rbxassetid://10734884548"
})

local FuelTab = Window:Tab({
    Title = "Auto Fuel",
    Icon = "rbxassetid://10747374131"
})

local UtilityTab = Window:Tab({
    Title = "Utilities",
    Icon = "rbxassetid://10734950020"
})

local RunService = game:GetService("RunService")

local FlyToggle = FlyTab:Toggle({
    Title = "Enable Fly",
    Description = "Activate flight mode with WASD controls",
    Default = false,
    Callback = function(Value)
        local success = Fly.setEnabled(Value)
        
        if Value and success then
            Flux:Notification({
                Title = "Fly Enabled",
                Content = "PC: WASD + Space/Shift | Mobile: Touch & drag to fly!",
                Duration = 4
            })
        elseif Value and not success then
            Flux:Notification({
                Title = "Fly Failed", 
                Content = "Could not enable fly - character not found!",
                Duration = 3
            })
        else
            Flux:Notification({
                Title = "Fly Disabled",
                Content = "Flight mode deactivated.",
                Duration = 2
            })
        end
    end
})

local FlySpeedSlider = FlyTab:Slider({
    Title = "Fly Speed",
    Description = "Adjust your flight speed",
    Default = 50,
    Min = 1,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
        Fly.setSpeed(Value)
    end
})

local TreeToggle = TreeTab:Toggle({
    Title = "Auto Chop Trees",
    Description = "Automatically chop all small trees on the map", 
    Default = false,
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        
        if Value then
            Flux:Notification({
                Title = "Tree Chopper Enabled",
                Content = "Started chopping all small trees in map!",
                Duration = 3
            })
        else
            Flux:Notification({
                Title = "Tree Chopper Disabled",
                Content = "Stopped chopping trees.",
                Duration = 3  
            })
        end
    end
})

local TreeDelayDropdown = TreeTab:Dropdown({
    Title = "Chop Delay",
    Description = "Time between tree chopping cycles",
    Values = {"0.1s", "0.5s", "1s", "2s", "3s", "5s"},
    Default = "1s",
    Multi = false,
    Callback = function(Value)
        local delayMap = {
            ["0.1s"] = 0.1,
            ["0.5s"] = 0.5,
            ["1s"] = 1,
            ["2s"] = 2,
            ["3s"] = 3,
            ["5s"] = 5
        }
        local delay = delayMap[Value] or 1
        TreeChopper.setChopDelay(delay)
    end
})

local TreeStatusParagraph = TreeTab:Paragraph({
    Title = "Tree Chopper Status",
    Content = "Status: Ready - Processes 5 trees per cycle"
})

local FuelToggle = FuelTab:Toggle({
    Title = "Auto Fuel Collection",
    Description = "Teleport fuel items to position (0,4,-3)",
    Default = false,
    Callback = function(Value)
        AutoFuel.setEnabled(Value)
        
        if Value then
            Flux:Notification({
                Title = "Auto Fuel Enabled",
                Content = "Teleporting fuel to position (0,4,-3) with enhanced dropping!",
                Duration = 3
            })
        else
            Flux:Notification({
                Title = "Auto Fuel Disabled", 
                Content = "Stopped collecting fuel items.",
                Duration = 3
            })
        end
    end
})

local FuelStatusParagraph = FuelTab:Paragraph({
    Title = "Auto Fuel Status",
    Content = "Status: Ready - 1.0s delay, stacks at (0,4,-3)"
})

local ComboToggle = UtilityTab:Toggle({
    Title = "Tree + Fuel Combo",
    Description = "Enable both Tree Chopper and Auto Fuel together",
    Default = false,
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        AutoFuel.setEnabled(Value)
        
        if Value then
            Flux:Notification({
                Title = "Combo Bot Enabled",
                Content = "Tree Chopper and Auto Fuel are now active!",
                Duration = 4
            })
        else
            Flux:Notification({
                Title = "Combo Bot Disabled",
                Content = "Both bots have been stopped.",
                Duration = 3
            })
        end
    end
})

local ComboStatusParagraph = UtilityTab:Paragraph({
    Title = "Combo Status",
    Content = "Both bots disabled"
})

RunService.Heartbeat:Connect(function()
    local treeStatus, treeCount, closestDistance = TreeChopper.getStatus()
    TreeStatusParagraph:SetContent(treeStatus)
    
    local fuelStatus, distance = AutoFuel.getStatus()
    FuelStatusParagraph:SetContent(fuelStatus)
    
    local chopEnabled = TreeChopper.autoChopEnabled
    local fuelEnabled = AutoFuel.autoFuelEnabled
    
    if chopEnabled and fuelEnabled then
        ComboStatusParagraph:SetContent("Both bots active - Chopping & Fueling")
    elseif chopEnabled then
        ComboStatusParagraph:SetContent("Only Tree Chopper active")
    elseif fuelEnabled then
        ComboStatusParagraph:SetContent("Only Auto Fuel active")
    else
        ComboStatusParagraph:SetContent("Both bots disabled")  
    end
end)

Flux:Notification({
    Title = "Multi-Tool Bot Suite Loaded",
    Content = "Flux UI loaded! Clean fly-focused main tab ready to use.",
    Duration = 6
})