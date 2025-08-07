local AutoFuel = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 2
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0
AutoFuel.startTime = 0
AutoFuel.initDelay = 10
AutoFuel.scanDelay = 5
AutoFuel.lastScanTime = 0
AutoFuel.cachedFuelItems = {}

function AutoFuel.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function AutoFuel.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function AutoFuel.getMainFire()
    local workspace = game:GetService("Workspace")
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    
    local campground = map:FindFirstChild("Campground")
    if not campground then return nil end
    
    return campground:FindFirstChild("MainFire")
end

function AutoFuel.scanForFuelItems()
    local workspace = game:GetService("Workspace")
    local fuelItems = {}
    
    for _, item in pairs(workspace:GetChildren()) do
        if item.Name == "Log" or item.Name == "Coal" or item.Name == "Fuel Canister" then
            table.insert(fuelItems, item)
        end
    end
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item.Name == "Log" or item.Name == "Coal" or item.Name == "Fuel Canister" then
                table.insert(fuelItems, item)
            end
        end
    end
    
    return fuelItems
end

function AutoFuel.getFuelHandle(fuelItem)
    if fuelItem.Name == "Log" then
        return fuelItem:FindFirstChild("Handle") or fuelItem:FindFirstChild("Meshes/log_Cylinder")
    elseif fuelItem.Name == "Coal" then
        return fuelItem:FindFirstChild("Coal") or fuelItem:FindFirstChild("Handle")
    elseif fuelItem.Name == "Fuel Canister" then
        return fuelItem:FindFirstChild("Handle")
    end
    
    return fuelItem:FindFirstChildOfClass("Part")
end

function AutoFuel.teleportItem(fuelItem)
    if not fuelItem or not fuelItem.Parent then
        return false
    end
    
    local fuelHandle = AutoFuel.getFuelHandle(fuelItem)
    if not fuelHandle then return false end
    
    local targetPosition = Vector3.new(0, 25, -3)
    
    fuelHandle.CFrame = CFrame.new(targetPosition)
    fuelHandle.Velocity = Vector3.new(0, -30, 0)
    
    return true
end

function AutoFuel.autoFuelLoop()
    if not AutoFuel.autoFuelEnabled then return end
    
    local currentTime = tick()
    
    if currentTime - AutoFuel.startTime < AutoFuel.initDelay then
        return
    end
    
    if currentTime - AutoFuel.lastFuelTime < AutoFuel.fuelDelay then
        return
    end
    
    if currentTime - AutoFuel.lastScanTime > AutoFuel.scanDelay then
        AutoFuel.cachedFuelItems = AutoFuel.scanForFuelItems()
        AutoFuel.lastScanTime = currentTime
    end
    
    local validItems = {}
    for _, item in pairs(AutoFuel.cachedFuelItems) do
        if item and item.Parent then
            table.insert(validItems, item)
        end
    end
    
    if #validItems > 0 then
        local item = validItems[1]
        AutoFuel.teleportItem(item)
        AutoFuel.lastFuelTime = currentTime
    end
end

function AutoFuel.setEnabled(enabled)
    AutoFuel.autoFuelEnabled = enabled
    
    if enabled then
        AutoFuel.startTime = tick()
        AutoFuel.lastScanTime = 0
        AutoFuel.cachedFuelItems = {}
        AutoFuel.fuelConnection = RunService.Heartbeat:Connect(AutoFuel.autoFuelLoop)
    else
        if AutoFuel.fuelConnection then
            AutoFuel.fuelConnection:Disconnect()
            AutoFuel.fuelConnection = nil
        end
        AutoFuel.cachedFuelItems = {}
    end
end

function AutoFuel.setFuelDelay(delay)
    AutoFuel.fuelDelay = delay
end

function AutoFuel.getStatus()
    if AutoFuel.autoFuelEnabled then
        local currentTime = tick()
        local timeLeft = AutoFuel.initDelay - (currentTime - AutoFuel.startTime)
        
        if timeLeft > 0 then
            return string.format("Status: Starting in %.0f seconds...", timeLeft), 0
        end
        
        local validItems = {}
        for _, item in pairs(AutoFuel.cachedFuelItems) do
            if item and item.Parent then
                table.insert(validItems, item)
            end
        end
        
        if #validItems > 0 then
            local logCount = 0
            local coalCount = 0
            local canisterCount = 0
            
            for _, item in pairs(validItems) do
                if item.Name == "Log" then
                    logCount = logCount + 1
                elseif item.Name == "Coal" then
                    coalCount = coalCount + 1
                elseif item.Name == "Fuel Canister" then
                    canisterCount = canisterCount + 1
                end
            end
            
            return string.format("Status: ACTIVE - L:%d C:%d FC:%d | Drop: (0,25,-3)", 
                   logCount, coalCount, canisterCount), 0
        else
            return "Status: No fuel items found", 0
        end
    else
        return "Status: Auto fuel disabled", 0
    end
end

return AutoFuel