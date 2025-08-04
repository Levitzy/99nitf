local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()
local Fly = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/fly.lua'))()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Multi-Tool Suite",
   LoadingTitle = "Advanced Multi-Tool Suite",
   LoadingSubtitle = "Premium Experience",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "MultiToolSuite",
      FileName = "UserConfig"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false
})

local MainTab = Window:CreateTab("Flight", 4483362458)
local TreeTab = Window:CreateTab("Tree System", 4483362458)
local FuelTab = Window:CreateTab("Fuel System", 4335489011)
local UtilityTab = Window:CreateTab("Automation", 4370317008)

local RunService = game:GetService("RunService")

local FlightSection = MainTab:CreateSection("Flight Controls")

local FlyToggle = MainTab:CreateToggle({
   Name = "Enable Flight Mode",
   CurrentValue = false,
   Flag = "FlightToggle",
   Callback = function(Value)
       local success = Fly.setEnabled(Value)
       
       if Value and success then
           Rayfield:Notify({
               Title = "Flight Activated",
               Content = "Flight mode enabled. Use WASD for movement, Space/Shift for altitude.",
               Duration = 4,
               Image = 4370317008
           })
       elseif Value and not success then
           Rayfield:Notify({
               Title = "Flight Error",
               Content = "Unable to initialize flight system. Please try again.",
               Duration = 3,
               Image = 4370317008
           })
       else
           Rayfield:Notify({
               Title = "Flight Deactivated",
               Content = "Flight mode disabled.",
               Duration = 2,
               Image = 4370317008
           })
       end
   end,
})

local FlightSpeedSlider = MainTab:CreateSlider({
   Name = "Flight Speed",
   Range = {5, 150},
   Increment = 5,
   Suffix = " units/s",
   CurrentValue = 50,
   Flag = "FlightSpeed",
   Callback = function(Value)
       Fly.setSpeed(Value)
   end,
})

local FlightStatusSection = MainTab:CreateSection("System Status")
local FlightStatusLabel = MainTab:CreateLabel("Flight Status: Standby")

local TreeControlSection = TreeTab:CreateSection("Tree Management")

local AutoChopToggle = TreeTab:CreateToggle({
   Name = "Automated Tree Processing",
   CurrentValue = false,
   Flag = "TreeProcessingToggle",
   Callback = function(Value)
       TreeChopper.setEnabled(Value)
       
       if Value then
           Rayfield:Notify({
               Title = "Tree Processing Active",
               Content = "Automated tree processing has been enabled.",
               Duration = 3,
               Image = 4483362458
           })
       else
           Rayfield:Notify({
               Title = "Tree Processing Disabled",
               Content = "Tree processing has been stopped.",
               Duration = 3,
               Image = 4483362458
           })
       end
   end,
})

local TreeSpeedDropdown = TreeTab:CreateDropdown({
   Name = "Processing Interval",
   Options = {"Rapid (0.1s)", "Fast (0.5s)", "Standard (1s)", "Careful (2s)", "Slow (3s)", "Very Slow (5s)"},
   CurrentOption = "Standard (1s)",
   Flag = "TreeProcessingSpeed",
   Callback = function(Option)
       local speedMap = {
           ["Rapid (0.1s)"] = 0.1,
           ["Fast (0.5s)"] = 0.5,
           ["Standard (1s)"] = 1,
           ["Careful (2s)"] = 2,
           ["Slow (3s)"] = 3,
           ["Very Slow (5s)"] = 5
       }
       local delay = speedMap[Option] or 1
       TreeChopper.setChopDelay(delay)
   end,
})

local TreeStatusSection = TreeTab:CreateSection("System Information")
local TreeStatusLabel = TreeTab:CreateLabel("Status: Ready")
local TreeInfoLabel = TreeTab:CreateLabel("Processes 5 trees per cycle for optimal performance")

local FuelManagementSection = FuelTab:CreateSection("Fuel Management")

local AutoFuelToggle = FuelTab:CreateToggle({
   Name = "Automated Fuel Collection",
   CurrentValue = false,
   Flag = "FuelCollectionToggle",
   Callback = function(Value)
       AutoFuel.setEnabled(Value)
       
       if Value then
           Rayfield:Notify({
               Title = "Fuel Collection Active",
               Content = "Automated fuel collection to position (0,4,-3) enabled.",
               Duration = 3,
               Image = 4335489011
           })
       else
           Rayfield:Notify({
               Title = "Fuel Collection Disabled",
               Content = "Fuel collection has been stopped.",
               Duration = 3,
               Image = 4335489011
           })
       end
   end,
})

local FuelStatusSection = FuelTab:CreateSection("System Information")
local FuelStatusLabel = FuelTab:CreateLabel("Status: Ready")
local FuelInfoLabel = FuelTab:CreateLabel("Collection interval: 1.0s - Target position: (0,4,-3)")

local AutomationSection = UtilityTab:CreateSection("Combined Automation")

local ComboBotToggle = UtilityTab:CreateToggle({
   Name = "Full Automation Suite",
   CurrentValue = false,
   Flag = "AutomationSuiteToggle",
   Callback = function(Value)
       TreeChopper.setEnabled(Value)
       AutoFuel.setEnabled(Value)
       
       if Value then
           Rayfield:Notify({
               Title = "Automation Suite Active",
               Content = "Tree processing and fuel collection systems activated.",
               Duration = 4,
               Image = 4370317008
           })
       else
           Rayfield:Notify({
               Title = "Automation Suite Disabled",
               Content = "All automation systems have been stopped.",
               Duration = 3,
               Image = 4370317008
           })
       end
   end,
})

local AutomationStatusSection = UtilityTab:CreateSection("System Status")
local ComboStatusLabel = UtilityTab:CreateLabel("Automation Status: Standby")
local ComboInfoLabel = UtilityTab:CreateLabel("Manages tree processing and fuel collection simultaneously")

RunService.Heartbeat:Connect(function()
    local treeStatus, treeCount, closestDistance = TreeChopper.getStatus()
    TreeStatusLabel:Set(treeStatus)
    
    local fuelStatus, distance = AutoFuel.getStatus()
    FuelStatusLabel:Set(fuelStatus)
    
    local chopEnabled = TreeChopper.autoChopEnabled
    local fuelEnabled = AutoFuel.autoFuelEnabled
    local flyEnabled = Fly.flyEnabled
    
    if flyEnabled then
        FlightStatusLabel:Set("Flight Status: Active")
    else
        FlightStatusLabel:Set("Flight Status: Standby")
    end
    
    if chopEnabled and fuelEnabled then
        ComboStatusLabel:Set("Automation Status: Full Suite Active")
    elseif chopEnabled then
        ComboStatusLabel:Set("Automation Status: Tree Processing Only")
    elseif fuelEnabled then
        ComboStatusLabel:Set("Automation Status: Fuel Collection Only")
    else
        ComboStatusLabel:Set("Automation Status: Standby")
    end
end)

Rayfield:Notify({
   Title = "Multi-Tool Suite Initialized",
   Content = "Advanced automation and flight systems ready for deployment.",
   Duration = 5,
   Image = 4483362458
})