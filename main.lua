local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Auto Tree Chopper & Fuel Bot",
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
local UtilityTab = Window:CreateTab("Utilities", 4370317008)

local RunService = game:GetService("RunService")

local AutoChopToggle = MainTab:CreateToggle({
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

local ChopDelayDropdown = MainTab:CreateDropdown({
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

local InfoSection = MainTab:CreateSection("Tree Chopper Information")
local StatusLabel = MainTab:CreateLabel("Status: Ready")

local TreeInfoLabel = MainTab:CreateLabel("Trees will be chopped from both Foliage and Landmarks folders")

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
               Content = "Both Tree Chopper and Auto Fuel are now active!",
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
local ComboInfoLabel = UtilityTab:CreateLabel("Tree Chopper will find ALL small trees on the map")

RunService.Heartbeat:Connect(function()
    local status, treeCount, closestDistance = TreeChopper.getStatus()
    StatusLabel:Set(status)
    
    local fuelStatus, distance = AutoFuel.getStatus()
    FuelStatusLabel:Set(fuelStatus)
    
    local chopEnabled = TreeChopper.autoChopEnabled
    local fuelEnabled = AutoFuel.autoFuelEnabled
    
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
   Title = "Auto Tree Chopper & Fuel Bot Loaded",
   Content = "Script loaded! Tree Chopper will find ALL small trees. Auto Fuel brings logs to MainFire.",
   Duration = 6,
   Image = 4483362458
})