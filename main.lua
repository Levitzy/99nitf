local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Auto Tree Chopper & Fuel",
   LoadingTitle = "Tree Chopping & Auto Fuel Bot",
   LoadingSubtitle = "by TreeChopper",
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
   Name = "Auto Fuel MainFire",
   CurrentValue = false,
   Flag = "AutoFuelToggle",
   Callback = function(Value)
       AutoFuel.setEnabled(Value)
       
       if Value then
           Rayfield:Notify({
               Title = "Auto Fuel Enabled",
               Content = "Started fueling MainFire automatically!",
               Duration = 3,
               Image = 4335489011
           })
       else
           Rayfield:Notify({
               Title = "Auto Fuel Disabled",
               Content = "Stopped fueling MainFire.",
               Duration = 3,
               Image = 4335489011
           })
       end
   end,
})

local FuelDelayDropdown = FuelTab:CreateDropdown({
   Name = "Fuel Delay",
   Options = {"0.5s", "1s", "3s", "5s", "7s", "10s"},
   CurrentOption = "1s",
   Flag = "FuelDelay",
   Callback = function(Option)
       local delayMap = {
           ["0.5s"] = 0.5,
           ["1s"] = 1,
           ["3s"] = 3,
           ["5s"] = 5,
           ["7s"] = 7,
           ["10s"] = 10
       }
       local delay = delayMap[Option] or 1
       AutoFuel.setFuelDelay(delay)
   end,
})

local FuelDistanceSlider = FuelTab:CreateSlider({
   Name = "Max Fuel Distance",
   Range = {20, 200},
   Increment = 10,
   CurrentValue = 100,
   Flag = "MaxFuelDistance",
   Callback = function(Value)
       AutoFuel.setMaxDistance(Value)
   end,
})

local FuelInfoSection = FuelTab:CreateSection("Information")

local FuelStatusLabel = FuelTab:CreateLabel("Status: Ready")

RunService.Heartbeat:Connect(function()
    local status, treeCount, closestDistance = TreeChopper.getStatus()
    StatusLabel:Set(status)
    
    local fuelStatus, distance = AutoFuel.getStatus()
    FuelStatusLabel:Set(fuelStatus)
end)

Rayfield:Notify({
   Title = "Auto Tree Chopper & Fuel Loaded",
   Content = "Script loaded successfully! Make sure you have an Old Axe and logs are available.",
   Duration = 5,
   Image = 4483362458
})