local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Auto Tree Chopper & Fuel Pro",
   LoadingTitle = "Advanced Tree Chopping & Fuel Bot",
   LoadingSubtitle = "by TreeChopper - Enhanced Edition",
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
local FuelTab = Window:CreateTab("Auto Fuel Pro", 4335489011)
local SettingsTab = Window:CreateTab("Settings", 4370341699)

local RunService = game:GetService("RunService")

local AutoChopToggle = MainTab:CreateToggle({
   Name = "Auto Chop Trees",
   CurrentValue = false,
   Flag = "AutoChopToggle",
   Callback = function(Value)
       TreeChopper.setEnabled(Value)
       
       if Value then
           Rayfield:Notify({
               Title = "Auto Chop Enabled",
               Content = "Started chopping trees automatically!",
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

local DistanceSlider = MainTab:CreateSlider({
   Name = "Max Chop Distance",
   Range = {10, 100},
   Increment = 5,
   CurrentValue = 50,
   Flag = "MaxDistance",
   Callback = function(Value)
       TreeChopper.setMaxDistance(Value)
   end,
})

local ChopDelayDropdown = MainTab:CreateDropdown({
   Name = "Chop Delay",
   Options = {"0.1s", "0.5s", "1s", "3s", "5s", "10s"},
   CurrentOption = "1s",
   Flag = "ChopDelay",
   Callback = function(Option)
       local delayMap = {
           ["0.1s"] = 0.1,
           ["0.5s"] = 0.5,
           ["1s"] = 1,
           ["3s"] = 3,
           ["5s"] = 5,
           ["10s"] = 10
       }
       local delay = delayMap[Option] or 1
       TreeChopper.setChopDelay(delay)
   end,
})

local InfoSection = MainTab:CreateSection("Information")
local StatusLabel = MainTab:CreateLabel("Status: Ready")

local AutoFuelToggle = FuelTab:CreateToggle({
   Name = "Auto Fuel MainFire (Enhanced)",
   CurrentValue = false,
   Flag = "AutoFuelToggle",
   Callback = function(Value)
       AutoFuel.setEnabled(Value)
       
       if Value then
           Rayfield:Notify({
               Title = "Enhanced Auto Fuel Enabled",
               Content = "Bot will collect logs and fuel MainFire automatically!",
               Duration = 4,
               Image = 4335489011
           })
       else
           Rayfield:Notify({
               Title = "Auto Fuel Disabled",
               Content = "Stopped auto fuel operations.",
               Duration = 3,
               Image = 4335489011
           })
       end
   end,
})

local CollectLogsToggle = FuelTab:CreateToggle({
   Name = "Auto Collect Logs",
   CurrentValue = true,
   Flag = "CollectLogsToggle",
   Callback = function(Value)
       AutoFuel.setCollectLogs(Value)
       
       if Value then
           Rayfield:Notify({
               Title = "Auto Collect Enabled",
               Content = "Bot will automatically collect logs from the world!",
               Duration = 3,
               Image = 4335489011
           })
       else
           Rayfield:Notify({
               Title = "Auto Collect Disabled",
               Content = "Bot will only burn logs already in inventory.",
               Duration = 3,
               Image = 4335489011
           })
       end
   end,
})

local AutoWalkToggle = FuelTab:CreateToggle({
   Name = "Auto Walk to Logs",
   CurrentValue = true,
   Flag = "AutoWalkToggle",
   Callback = function(Value)
       AutoFuel.setAutoWalk(Value)
   end,
})

local FuelDelayDropdown = FuelTab:CreateDropdown({
   Name = "Fuel Operation Delay",
   Options = {"0.5s", "1s", "2s", "3s", "5s", "7s", "10s"},
   CurrentOption = "2s",
   Flag = "FuelDelay",
   Callback = function(Option)
       local delayMap = {
           ["0.5s"] = 0.5,
           ["1s"] = 1,
           ["2s"] = 2,
           ["3s"] = 3,
           ["5s"] = 5,
           ["7s"] = 7,
           ["10s"] = 10
       }
       local delay = delayMap[Option] or 2
       AutoFuel.setFuelDelay(delay)
   end,
})

local FuelInfoSection = FuelTab:CreateSection("Status Information")
local FuelStatusLabel = FuelTab:CreateLabel("Status: Ready")

local WalkSpeedSlider = SettingsTab:CreateSlider({
   Name = "Walk Speed",
   Range = {16, 100},
   Increment = 2,
   CurrentValue = 50,
   Flag = "WalkSpeed",
   Callback = function(Value)
       AutoFuel.setWalkSpeed(Value)
   end,
})

local CollectDistanceSlider = SettingsTab:CreateSlider({
   Name = "Auto Collect Distance",
   Range = {5, 30},
   Increment = 1,
   CurrentValue = 15,
   Flag = "CollectDistance",
   Callback = function(Value)
       AutoFuel.setCollectDistance(Value)
   end,
})

local UtilitySection = SettingsTab:CreateSection("Utility Functions")

local DropLogsButton = SettingsTab:CreateButton({
   Name = "Drop All Logs from Inventory",
   Callback = function()
       local droppedCount = AutoFuel.dropAllLogs()
       Rayfield:Notify({
           Title = "Logs Dropped",
           Content = string.format("Dropped %d logs from inventory!", droppedCount),
           Duration = 3,
           Image = 4335489011
       })
   end,
})

RunService.Heartbeat:Connect(function()
    local status, treeCount, closestDistance = TreeChopper.getStatus()
    StatusLabel:Set(status)
    
    local fuelStatus, distance = AutoFuel.getStatus()
    FuelStatusLabel:Set(fuelStatus)
end)

Rayfield:Notify({
   Title = "Enhanced Auto Tree Chopper & Fuel Loaded",
   Content = "Advanced automation loaded! Bot will collect logs and fuel automatically.",
   Duration = 6,
   Image = 4483362458
})