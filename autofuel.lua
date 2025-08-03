local AutoFuel = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 1
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0

function AutoFuel.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function AutoFuel.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function AutoFuel.hasLogItem()
    local workspace = game:GetService("Workspace")
    local itemsFolder = workspace:WaitForChild("Items")
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item.Name == "Log" then
            return true, item
        end
    end
    return false, nil
end

function AutoFuel.getLogItem()
    local workspace = game:GetService("Workspace")
    local itemsFolder = workspace:WaitForChild("Items")
    local items = itemsFolder:GetChildren()
    
    if #items >= 100 then
        return items[100]
    else
        for _, item in pairs(items) do
            if item.Name == "Log" then
                return item
            end
        end
    end
    return nil
end

function AutoFuel.getMainFire()
    local workspace = game:GetService("Workspace")
    local mapFolder = workspace:WaitForChild("Map")
    local campgroundFolder = mapFolder:WaitForChild("Campground")
    local mainFire = campgroundFolder:WaitForChild("MainFire")
    
    return mainFire
end

function AutoFuel.isInRange(maxDistance)
    local playerPos = AutoFuel.getPlayerPosition()
    if not playerPos then return false end
    
    local mainFire = AutoFuel.getMainFire()
    if not mainFire then return false end
    
    local firePos = mainFire.Position
    local distance = AutoFuel.getDistance(playerPos, firePos)
    
    return distance <= maxDistance, distance
end

function AutoFuel.fuelFire()
    local hasLog, logItem = AutoFuel.hasLogItem()
    if not hasLog then
        return false, "No Log item found"
    end
    
    local currentTime = tick()
    if currentTime - AutoFuel.lastFuelTime < AutoFuel.fuelDelay then
        return false, "Delay not reached"
    end
    
    local mainFire = AutoFuel.getMainFire()
    if not mainFire then
        return false, "MainFire not found"
    end
    
    local logToUse = AutoFuel.getLogItem()
    if not logToUse then
        return false, "No Log item available"
    end
    
    local args = {
        mainFire,
        logToUse
    }
    
    local success, result = pcall(function()
        return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestBurnItem"):FireServer(unpack(args))
    end)
    
    if success then
        AutoFuel.lastFuelTime = currentTime
        return true, "Fuel added successfully"
    else
        return false, "Failed to fuel fire"
    end
end

function AutoFuel.autoFuelLoop()
    if not AutoFuel.autoFuelEnabled then return end
    
    local inRange, distance = AutoFuel.isInRange(50)
    
    if inRange then
        AutoFuel.fuelFire()
    end
end

function AutoFuel.setEnabled(enabled)
    AutoFuel.autoFuelEnabled = enabled
    
    if enabled then
        AutoFuel.fuelConnection = RunService.Heartbeat:Connect(AutoFuel.autoFuelLoop)
    else
        if AutoFuel.fuelConnection then
            AutoFuel.fuelConnection:Disconnect()
            AutoFuel.fuelConnection = nil
        end
    end
end

function AutoFuel.setFuelDelay(delay)
    AutoFuel.fuelDelay = delay
end

function AutoFuel.getStatus()
    if AutoFuel.autoFuelEnabled then
        local hasLog, logItem = AutoFuel.hasLogItem()
        local inRange, distance = AutoFuel.isInRange(50)
        
        if not hasLog then
            return "Status: No Log item found in workspace!", 0
        elseif not inRange then
            return string.format("Status: Too far from MainFire (%.1f studs)", distance or 0), distance or 0
        else
            return string.format("Status: Auto fueling MainFire (%.1f studs) - Delay: %.1fs", distance, AutoFuel.fuelDelay), distance
        end
    else
        return "Status: Auto fuel disabled", 0
    end
end

return AutoFuel