local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()
local Fly = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/fly.lua'))()

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Interface/main/Source.lua"))()

local Window = Library:CreateWindow({
    Title = "Multi-Tool Bot Suite",
    SubTitle = "Fly, Tree Chopper & Auto Fuel",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Fly", Icon = "plane" }),
    Tree = Window:AddTab({ Title = "Tree Chopper", Icon = "tree-pine" }),
    Fuel = Window:AddTab({ Title = "Auto Fuel", Icon = "flame" }),
    Utility = Window:AddTab({ Title = "Utilities", Icon = "settings" })
}

local RunService = game:GetService("RunService")

local FlyToggle = Tabs.Main:AddToggle("FlyToggle", {
    Title = "Enable Fly",
    Description = "Activate flight mode with WASD controls",
    Default = false,
    Callback = function(Value)
        local success = Fly.setEnabled(Value)
        
        if Value and success then
            Library:Notify({
                Title = "Fly Enabled",
                Content = "PC: WASD + Space/Shift | Mobile: Touch & drag to fly!",
                Duration = 4
            })
        elseif Value and not success then
            Library:Notify({
                Title = "Fly Failed",
                Content = "Could not enable fly - character not found!",
                Duration = 3
            })
        else
            Library:Notify({
                Title = "Fly Disabled",
                Content = "Flight mode deactivated.",
                Duration = 2
            })
        end
    end
})

local FlySpeedSlider = Tabs.Main:AddSlider("FlySpeed", {
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

local TreeToggle = Tabs.Tree:AddToggle("TreeToggle", {
    Title = "Auto Chop Trees",
    Description = "Automatically chop all small trees on the map",
    Default = false,
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        
        if Value then
            Library:Notify({
                Title = "Tree Chopper Enabled",
                Content = "Started chopping all small trees in map!",
                Duration = 3
            })
        else
            Library:Notify({
                Title = "Tree Chopper Disabled",
                Content = "Stopped chopping trees.",
                Duration = 3
            })
        end
    end
})

local TreeDelayDropdown = Tabs.Tree:AddDropdown("TreeDelay", {
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

local FuelToggle = Tabs.Fuel:AddToggle("FuelToggle", {
    Title = "Auto Fuel Collection",
    Description = "Teleport fuel items to position (0,4,-3)",
    Default = false,
    Callback = function(Value)
        AutoFuel.setEnabled(Value)
        
        if Value then
            Library:Notify({
                Title = "Auto Fuel Enabled",
                Content = "Teleporting fuel to position (0,4,-3) with enhanced dropping!",
                Duration = 3
            })
        else
            Library:Notify({
                Title = "Auto Fuel Disabled",
                Content = "Stopped collecting fuel items.",
                Duration = 3
            })
        end
    end
})

local ComboToggle = Tabs.Utility:AddToggle("ComboToggle", {
    Title = "Tree + Fuel Combo",
    Description = "Enable both Tree Chopper and Auto Fuel together",
    Default = false,
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        AutoFuel.setEnabled(Value)
        
        if Value then
            Library:Notify({
                Title = "Combo Bot Enabled",
                Content = "Tree Chopper and Auto Fuel are now active!",
                Duration = 4
            })
        else
            Library:Notify({
                Title = "Combo Bot Disabled",
                Content = "Both bots have been stopped.",
                Duration = 3
            })
        end
    end
})

local TreeStatusParagraph = Tabs.Tree:AddParagraph({
    Title = "Tree Chopper Status",
    Content = "Status: Ready - Processes 5 trees per cycle"
})

local FuelStatusParagraph = Tabs.Fuel:AddParagraph({
    Title = "Auto Fuel Status", 
    Content = "Status: Ready - 1.0s delay, stacks at (0,4,-3)"
})

local ComboStatusParagraph = Tabs.Utility:AddParagraph({
    Title = "Combo Status",
    Content = "Both bots disabled"
})

RunService.Heartbeat:Connect(function()
    local treeStatus, treeCount, closestDistance = TreeChopper.getStatus()
    TreeStatusParagraph:SetDesc(treeStatus)
    
    local fuelStatus, distance = AutoFuel.getStatus()
    FuelStatusParagraph:SetDesc(fuelStatus)
    
    local chopEnabled = TreeChopper.autoChopEnabled  
    local fuelEnabled = AutoFuel.autoFuelEnabled
    
    if chopEnabled and fuelEnabled then
        ComboStatusParagraph:SetDesc("Both bots active - Chopping & Fueling")
    elseif chopEnabled then
        ComboStatusParagraph:SetDesc("Only Tree Chopper active")
    elseif fuelEnabled then
        ComboStatusParagraph:SetDesc("Only Auto Fuel active") 
    else
        ComboStatusParagraph:SetDesc("Both bots disabled")
    end
end)

Library:Notify({
    Title = "Multi-Tool Bot Suite Loaded",
    Content = "Fluent UI loaded! Fly, Tree Chopper, and Auto Fuel ready to use.",
    Duration = 6
})

Window:SelectTab(1)