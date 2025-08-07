local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()
local Fly = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/fly.lua'))()
local AutoKill = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autokill.lua'))()
local AutoCook = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autocook.lua'))()
local AutoPlant = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autoplant.lua'))()

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

local Window = Library.CreateLib("Forest Automation Suite", "BloodTheme")

local FlyTab = Window:NewTab("🚁 Flight")
local AutomationTab = Window:NewTab("🤖 Automation")  
local UtilityTab = Window:NewTab("⚙️ Utilities")

local FlySection = FlyTab:NewSection("Flight Controls")
local TreeSection = AutomationTab:NewSection("Tree & Plant Management")
local CombatSection = AutomationTab:NewSection("Combat & Survival")
local ComboSection = UtilityTab:NewSection("Combo Controls")
local StatusSection = UtilityTab:NewSection("Status Monitor")

local RunService = game:GetService("RunService")

FlySection:NewToggle("Enable Flight", "Toggle flight mode", function(state)
    local success = Fly.setEnabled(state)
    
    if state and success then
        Library:Notify("Flight Enabled", "PC: WASD + Space/Shift | Mobile: Touch controls")
    elseif state and not success then
        Library:Notify("Flight Failed", "Character not found!")
    else
        Library:Notify("Flight Disabled", "Landing complete")
    end
end)

FlySection:NewSlider("Flight Speed", "Adjust your flying speed", 200, 50, function(s)
    Fly.setSpeed(s)
end)

TreeSection:NewToggle("Auto Tree Chopper", "Automatically chop all small trees", function(state)
    TreeChopper.setEnabled(state)
    
    if state then
        Library:Notify("Tree Chopper Active", "Chopping all small trees on the map!")
    else
        Library:Notify("Tree Chopper Stopped", "Tree chopping disabled")
    end
end)

TreeSection:NewToggle("Auto Plant Saplings", "Automatically plant saplings at their locations", function(state)
    AutoPlant.setEnabled(state)
    
    if state then
        Library:Notify("Auto Plant Active", "Planting saplings for forest regeneration!")
    else
        Library:Notify("Auto Plant Stopped", "Sapling planting disabled")
    end
end)

TreeSection:NewToggle("Auto Fuel System", "Teleport fuel items to MainFire position", function(state)
    AutoFuel.setEnabled(state)
    
    if state then
        Library:Notify("Auto Fuel Active", "Fuel management system online!")
    else
        Library:Notify("Auto Fuel Stopped", "Fuel automation disabled")
    end
end)

CombatSection:NewToggle("Auto Combat System", "Attack all hostile creatures", function(state)
    AutoKill.setEnabled(state)
    
    if state then
        Library:Notify("Combat System Active", "Engaging all hostile targets!")
    else
        Library:Notify("Combat System Stopped", "Combat automation disabled")
    end
end)

CombatSection:NewToggle("Auto Cooking System", "Cook all raw meat automatically", function(state)
    AutoCook.setEnabled(state)
    
    if state then
        Library:Notify("Cooking System Active", "Auto-cooking all raw meat!")
    else
        Library:Notify("Cooking System Stopped", "Cooking automation disabled")
    end
end)

ComboSection:NewToggle("🌲 Forest Combo", "Tree Chopper + Auto Fuel + Auto Plant", function(state)
    TreeChopper.setEnabled(state)
    AutoFuel.setEnabled(state)
    AutoPlant.setEnabled(state)
    
    if state then
        Library:Notify("Forest Combo Active", "Complete forest management enabled!")
    else
        Library:Notify("Forest Combo Stopped", "Forest automation disabled")
    end
end)

ComboSection:NewToggle("⚔️ Survival Combo", "Combat + Cooking Systems", function(state)
    AutoKill.setEnabled(state)
    AutoCook.setEnabled(state)
    
    if state then
        Library:Notify("Survival Combo Active", "Combat and cooking systems online!")
    else
        Library:Notify("Survival Combo Stopped", "Survival automation disabled")
    end
end)

ComboSection:NewToggle("🚀 ULTIMATE MODE", "Enable ALL automation systems", function(state)
    TreeChopper.setEnabled(state)
    AutoFuel.setEnabled(state)
    AutoKill.setEnabled(state)
    AutoCook.setEnabled(state)
    AutoPlant.setEnabled(state)
    
    if state then
        Library:Notify("ULTIMATE MODE ACTIVE", "All 5 automation systems engaged! AFK mode ready!")
    else
        Library:Notify("Ultimate Mode Stopped", "All automation systems disabled")
    end
end)

local TreeStatusLabel = StatusSection:NewLabel("Tree Status: Ready")
local FuelStatusLabel = StatusSection:NewLabel("Fuel Status: Ready") 
local KillStatusLabel = StatusSection:NewLabel("Combat Status: Ready")
local CookStatusLabel = StatusSection:NewLabel("Cook Status: Ready")
local PlantStatusLabel = StatusSection:NewLabel("Plant Status: Ready")
local ComboStatusLabel = StatusSection:NewLabel("System Status: All bots offline")

RunService.Heartbeat:Connect(function()
    local treeStatus, treeCount, closestDistance = TreeChopper.getStatus()
    TreeStatusLabel:UpdateLabel("Trees: " .. treeStatus)
    
    local fuelStatus, distance = AutoFuel.getStatus()
    FuelStatusLabel:UpdateLabel("Fuel: " .. fuelStatus)
    
    local killStatus, targetCount, closestTargetDistance = AutoKill.getStatus()
    KillStatusLabel:UpdateLabel("Combat: " .. killStatus)
    
    local cookStatus, meatCount = AutoCook.getStatus()
    CookStatusLabel:UpdateLabel("Cook: " .. cookStatus)
    
    local plantStatus, saplingCount = AutoPlant.getStatus()
    PlantStatusLabel:UpdateLabel("Plant: " .. plantStatus)
    
    local chopEnabled = TreeChopper.autoChopEnabled
    local fuelEnabled = AutoFuel.autoFuelEnabled
    local killEnabled = AutoKill.autoKillEnabled
    local cookEnabled = AutoCook.autoCookEnabled
    local plantEnabled = AutoPlant.autoPlantEnabled
    
    local activeCount = 0
    local activeSystems = {}
    
    if chopEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Tree")
    end
    if fuelEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Fuel")
    end
    if killEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Combat")
    end
    if cookEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Cook")
    end
    if plantEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Plant")
    end
    
    if activeCount == 5 then
        ComboStatusLabel:UpdateLabel("🚀 ULTIMATE MODE: All 5 systems active!")
    elseif activeCount >= 3 then
        ComboStatusLabel:UpdateLabel("🔥 Multi-System: " .. activeCount .. "/5 active (" .. table.concat(activeSystems, ", ") .. ")")
    elseif activeCount == 2 then
        ComboStatusLabel:UpdateLabel("⚡ Dual-System: " .. table.concat(activeSystems, " + "))
    elseif activeCount == 1 then
        ComboStatusLabel:UpdateLabel("📍 Single System: " .. activeSystems[1] .. " active")
    else
        ComboStatusLabel:UpdateLabel("💤 All systems offline")
    end
end)

Library:Notify("Forest Automation Suite", "Complete automation system loaded! 5 bots ready for ultimate forest management.")