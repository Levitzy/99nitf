local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()
local Fly = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/fly.lua'))()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Multi-Tool Bot Suite",
   LoadingTitle = "Tree Chopper, Auto Fuel & Fly Bot",
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

local MainTab = Window:CreateTab("Main", 4483362458)
local TreeTab = Window:CreateTab("Tree Chopper", 4483362458)
local FuelTab = Window:CreateTab("Auto Fuel", 4335489011)
local UtilityTab = Window:CreateTab("Utilities", 4370317008)

local RunService = game:GetService("RunService")

local MainSection = MainTab:CreateSection("Primary Controls")

local FlyToggle = MainTab:CreateToggle({
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
               Image = 4370317008
           })
       elseif Value and not success then
           Rayfield:Notify({
               Title = "Fly Failed",
               Content = "Could not enable fly - character not found!",
               Duration = 3,
               Image = 4370317008
           })
       else
           Rayfield:Notify({
               Title = "Fly Disabled",
               Content = "Flight mode deactivated.",
               Duration = 2,
               Image = 4370317008
           })
       end
   end,
})

local FlySpeedSlider = MainTab:CreateSlider({
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

local BotControlSection = MainTab:CreateSection("Bot Controls")

local AllBotsToggle = MainTab:CreateToggle({
   Name = "Enable Tree Chopper + Auto Fuel",
   CurrentValue = false,
   Flag = "AllBotsToggle",
   Callback = function(Value)
       TreeChopper.setEnabled(Value)
       AutoFuel.setEnabled(Value)
       
       if Value then
           Rayfield:Notify({
               Title = "All Bots Enabled",
               Content = "Tree Chopper and Auto Fuel active! Items stack at (0,4,-3)",
               Duration = 4,
               Image = 4483362458
           })
       else
           Rayfield:Notify({
               Title = "All Bots Disabled",
               Content = "Tree Chopper and Auto Fuel have been stopped.",
               Duration = 3,
               Image = 4483362458
           })
       end
   end,
})

local StatusSection = MainTab:CreateSection("Status Overview")
local MainStatusLabel = MainTab:CreateLabel("All systems ready")

local ControlsSection = MainTab:CreateSection("Controls Guide")
local FlyControlsLabel = MainTab:CreateLabel("PC: WASD move, Space up, Shift down | Mobile: Touch & drag")
local BotControlsLabel = MainTab:CreateLabel("Use individual tabs for detailed bot settings")

local AutoChopToggle = TreeTab:CreateToggle({
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

local ChopDelayDropdown = TreeTab:CreateDropdown({
   Name = "Chop Delay",
   Options = {"0.1s", "0.5s", "1s", "2s", "3s", "5s"},
   CurrentOption = "1s",
   Flag = "ChopDelay",
   Callback = function(Option)
       local delayMap = {
           ["0.1s"] = 0.1,
           ["0.5s"] = 0.5,
           ["1s"] = 1,
           ["2s"] = 2,
           ["3s"] = 3,
           ["5s"] = 5
       }
       local delay = delayMap[Option] or 1
       TreeChopper.setChopDelay(delay)
   end,
})

local TreeInfoSection = TreeTab:CreateSection("Tree Chopper Information")
local TreeStatusLabel = TreeTab:CreateLabel("Status: Ready")
local TreeInfoLabel = TreeTab:CreateLabel("Trees processed: 5 per cycle for optimal performance")

local AutoFuelToggle = FuelTab:CreateToggle({
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

local FuelInfoSection = FuelTab:CreateSection("Auto Fuel Information")
local FuelStatusLabel = FuelTab:CreateLabel("Status: Ready")
local FuelInfoLabel = FuelTab:CreateLabel("Fixed delay: 1.0s - Items stack at position (0,4,-3)")

local ComboBotToggle = UtilityTab:CreateToggle({
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

local ComboInfoSection = UtilityTab:CreateSection("Combo Bot Information")
local ComboStatusLabel = UtilityTab:CreateLabel("Combo Status: Both bots disabled")
local ComboInfoLabel = UtilityTab:CreateLabel("Tree Chopper processes 5 trees per cycle from all map locations")

RunService.Heartbeat:Connect(function()
    local treeStatus, treeCount, closestDistance = TreeChopper.getStatus()
    TreeStatusLabel:Set(treeStatus)
    
    local fuelStatus, distance = AutoFuel.getStatus()
    FuelStatusLabel:Set(fuelStatus)
    
    local chopEnabled = TreeChopper.autoChopEnabled
    local fuelEnabled = AutoFuel.autoFuelEnabled
    local flyEnabled = Fly.flyEnabled
    
    if flyEnabled then
        MainStatusLabel:Set("Main Status: Fly Active")
    else
        MainStatusLabel:Set("Main Status: Fly Disabled")
    end
    
    if chopEnabled and fuelEnabled then
        ComboStatusLabel:Set("Combo Status: Both bots active - Chopping & Fueling")
    elseif chopEnabled then
        ComboStatusLabel:Set("Combo Status: Only Tree Chopper active")
    elseif fuelEnabled then
        ComboStatusLabel:Set("Combo Status: Only Auto Fuel active")
    else
        ComboStatusLabel:Set("Combo Status: Both bots disabled")
    end
end)

Rayfield:Notify({
   Title = "Multi-Tool Bot Suite Loaded",
   Content = "All modules loaded! Fly, Tree Chopper, and Auto Fuel ready. Mobile compatible!",
   Duration = 6,
   Image = 4483362458
})