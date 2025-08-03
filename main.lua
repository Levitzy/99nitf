local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Enhanced Tree Chopper & Fuel Bot",
   LoadingTitle = "Advanced Tree Chopping & Auto Fuel Bot",
   LoadingSubtitle = "by TreeChopper - Enhanced Version",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "TreeChopperConfig",
      FileName = "Config"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false
})

local MainTab = Window:CreateTab("Tree Chopper", 4483362458)
local FuelTab = Window:CreateTab("Auto Fuel", 4335489011)
local UtilityTab = Window:CreateTab("Utilities", 4370317008)
local SettingsTab = Window:CreateTab("Settings", 4370341237)

local RunService = game:GetService("RunService")

local AutoChopToggle = MainTab:CreateToggle({
   Name = "Auto Chop All Trees",
   CurrentValue = false,
   Flag = "AutoChopToggle",
   Callback = function(Value)
       TreeChopper.setEnabled(Value)
       
       if Value then
           Rayfield:Notify({
               Title = "Enhanced Auto Chop Enabled",
               Content = "Started chopping ALL trees in Foliage & Landmarks!",
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

local ChopDelayDropdown = MainTab:CreateDropdown({
   Name = "Chop Delay",
   Options = {"0.1s", "0.3s", "0.5s", "1s", "2s", "3s", "5s"},
   CurrentOption = "0.5s",
   Flag = "ChopDelay",
   Callback = function(Option)
       local delayMap = {
           ["0.1s"] = 0.1,
           ["0.3s"] = 0.3,
           ["0.5s"] = 0.5,
           ["1s"] = 1,
           ["2s"] = 2,
           ["3s"] = 3,
           ["5s"] = 5
       }
       local delay = delayMap[Option] or 0.5
       TreeChopper.setChopDelay(delay)
   end,
})

local BatchSizeDropdown = MainTab:CreateDropdown({
   Name = "Trees Per Batch",
   Options = {"5 trees", "10 trees", "15 trees", "20 trees", "25 trees"},
   CurrentOption = "10 trees",
   Flag = "BatchSize",
   Callback = function(Option)
       local sizeMap = {
           ["5 trees"] = 5,
           ["10 trees"] = 10,
           ["15 trees"] = 15,
           ["20 trees"] = 20,
           ["25 trees"] = 25
       }
       local size = sizeMap[Option] or 10
       TreeChopper.setBatchSize(size)
       
       Rayfield:Notify({
           Title = "Batch Size Updated",
           Content = "Now processing " .. size .. " trees per batch",
           Duration = 2,
           Image = 4483362458
       })
   end,
})

local InfoSection = MainTab:CreateSection("Tree Chopper Information")
local StatusLabel = MainTab:CreateLabel("Status: Ready - No distance limits!")

local AutoFuelToggle = FuelTab:CreateToggle({
   Name = "Auto Fuel MainFire",
   CurrentValue = false,
   Flag = "AutoFuelToggle",
   Callback = function(Value)
       AutoFuel.setFuelDelay(1.0)
       AutoFuel.setEnabled(Value)
       
       if Value then
           Rayfield:Notify({
               Title = "Auto Fuel Enabled",
               Content = "Started bringing fuel to MainFire automatically!",
               Duration = 3,
               Image = 4335489011
           })
       else
           Rayfield:Notify({
               Title = "Auto Fuel Disabled",
               Content = "Stopped bringing fuel to MainFire.",
               Duration = 3,
               Image = 4335489011
           })
       end
   end,
})



local FuelInfoSection = FuelTab:CreateSection("Auto Fuel Information")
local FuelStatusLabel = FuelTab:CreateLabel("Status: Ready")

local ComboBotToggle = UtilityTab:CreateToggle({
   Name = "Enable Both Bots",
   CurrentValue = false,
   Flag = "ComboBotToggle",
   Callback = function(Value)
       TreeChopper.setEnabled(Value)
       AutoFuel.setEnabled(Value)
       
       if Value then
           Rayfield:Notify({
               Title = "Combo Bot Enabled",
               Content = "Both Enhanced Tree Chopper and Auto Fuel are now active!",
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

local ResetProcessedButton = UtilityTab:CreateButton({
   Name = "Reset Processed Trees",
   Callback = function()
       TreeChopper.setEnabled(false)
       wait(0.5)
       TreeChopper.setEnabled(true)
       
       Rayfield:Notify({
           Title = "Trees Reset",
           Content = "Cleared processed tree memory - will rechop all trees!",
           Duration = 3,
           Image = 4370317008
       })
   end,
})

local ComboInfoSection = UtilityTab:CreateSection("Combo Bot Information")
local ComboStatusLabel = UtilityTab:CreateLabel("Combo Status: Both bots disabled")

local PerformanceSection = SettingsTab:CreateSection("Performance Settings")

local PerformanceModeToggle = SettingsTab:CreateToggle({
   Name = "Performance Mode",
   CurrentValue = false,
   Flag = "PerformanceMode",
   Callback = function(Value)
       if Value then
           TreeChopper.setChopDelay(0.3)
           TreeChopper.setBatchSize(15)
           Rayfield:Notify({
               Title = "Performance Mode ON",
               Content = "Optimized for speed: 0.3s delay, 15 trees/batch",
               Duration = 3,
               Image = 4370341237
           })
       else
           TreeChopper.setChopDelay(0.5)
           TreeChopper.setBatchSize(10)
           Rayfield:Notify({
               Title = "Performance Mode OFF",
               Content = "Back to normal: 0.5s delay, 10 trees/batch",
               Duration = 3,
               Image = 4370341237
           })
       end
   end,
})

local BalancedModeToggle = SettingsTab:CreateToggle({
   Name = "Balanced Mode",
   CurrentValue = false,
   Flag = "BalancedMode",
   Callback = function(Value)
       if Value then
           TreeChopper.setChopDelay(1.0)
           TreeChopper.setBatchSize(8)
           Rayfield:Notify({
               Title = "Balanced Mode ON",
               Content = "Optimized for stability: 1s delay, 8 trees/batch",
               Duration = 3,
               Image = 4370341237
           })
       else
           TreeChopper.setChopDelay(0.5)
           TreeChopper.setBatchSize(10)
           Rayfield:Notify({
               Title = "Balanced Mode OFF",
               Content = "Back to normal: 0.5s delay, 10 trees/batch",
               Duration = 3,
               Image = 4370341237
           })
       end
   end,
})

local InfoSectionSettings = SettingsTab:CreateSection("Script Information")
local VersionLabel = SettingsTab:CreateLabel("Version: Enhanced v2.0 - No Distance Limits")
local FeatureLabel = SettingsTab:CreateLabel("Features: Smart Tracking, Batch Processing, Auto-Equip")

RunService.Heartbeat:Connect(function()
    local status, treeCount, closestDistance = TreeChopper.getStatus()
    StatusLabel:Set(status)
    
    local fuelStatus, distance = AutoFuel.getStatus()
    FuelStatusLabel:Set(fuelStatus)
    
    local chopEnabled = TreeChopper.autoChopEnabled
    local fuelEnabled = AutoFuel.autoFuelEnabled
    
    if chopEnabled and fuelEnabled then
        ComboStatusLabel:Set("Combo Status: Both bots active - Enhanced Chopping & Fueling")
    elseif chopEnabled then
        ComboStatusLabel:Set("Combo Status: Only Enhanced Tree Chopper active")
    elseif fuelEnabled then
        ComboStatusLabel:Set("Combo Status: Only Auto Fuel active")
    else
        ComboStatusLabel:Set("Combo Status: Both bots disabled")
    end
end)

Rayfield:Notify({
   Title = "Enhanced Tree Chopper & Fuel Bot Loaded",
   Content = "Enhanced script loaded! No distance limits - chops ALL trees in Foliage & Landmarks. Smart tracking prevents re-chopping.",
   Duration = 8,
   Image = 4483362458
})