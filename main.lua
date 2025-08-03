local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Auto Tree Chopper",
   LoadingTitle = "Tree Chopping Bot",
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

local MainTab = Window:CreateTab("Main", 4483362458)

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

RunService.Heartbeat:Connect(function()
    local status, treeCount, closestDistance = TreeChopper.getStatus()
    StatusLabel:Set(status)
end)

Rayfield:Notify({
   Title = "Auto Tree Chopper Loaded",
   Content = "Script loaded successfully! Make sure you have an Old Axe.",
   Duration = 5,
   Image = 4483362458
})