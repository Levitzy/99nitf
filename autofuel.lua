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

function AutoFuel.findLogItems()
    local workspace = game:GetService("Workspace")
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if not itemsFolder then
        return {}
    end
    
    local logs = {}
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item.Name == "Log" and item:FindFirstChild("Main") and item.Main:IsA("BasePart") then
            table.insert(logs, item)
        end
    end
    
    return logs
end

function AutoFuel.getBestLogItem()
    local logs = AutoFuel.findLogItems()
    
    if #logs == 0 then
        return nil
    end
    
    local playerPos = AutoFuel.getPlayerPosition()
    if not playerPos then
        return logs[1]
    end
    
    local closestLog = nil
    local closestDistance = math.huge
    
    for _, log in pairs(logs) do
        if log:FindFirstChild("Main") and log.Main:IsA("BasePart") then
            local logPos = log.Main.Position
            local distance = AutoFuel.getDistance(playerPos, logPos)
            
            if distance < closestDistance then
                closestDistance = distance
                closestLog = log
            end
        end
    end
    
    return closestLog or logs[1]
end

function AutoFuel.hasLogItem()
    local logs = AutoFuel.findLogItems()
    return #logs > 0
end

function AutoFuel.getMainFire()
    local workspace = game:GetService("Workspace")
    local success, result = pcall(function()
        return workspace:WaitForChild("Map"):WaitForChild("Campground"):WaitForChild("MainFire")
    end)
    
    if success then
        return result
    else
        return nil
    end
end

function AutoFuel.getMainFirePosition()
    local mainFire = AutoFuel.getMainFire()
    if not mainFire then return nil end
    
    local primaryPart = mainFire.PrimaryPart
    if primaryPart then
        return primaryPart.Position
    end
    
    for _, child in pairs(mainFire:GetChildren()) do
        if child:IsA("BasePart") then
            return child.Position
        end
    end
    
    return nil
end

function AutoFuel.isInRange(maxDistance)
    local playerPos = AutoFuel.getPlayerPosition()
    if not playerPos then return false, 0 end
    
    local firePos = AutoFuel.getMainFirePosition()
    if not firePos then return false, 0 end
    
    local distance = AutoFuel.getDistance(playerPos, firePos)
    
    return distance <= maxDistance, distance
end

function AutoFuel.fuelFire()
    if not AutoFuel.hasLogItem() then
        return false, "No Log items found in workspace"
    end
    
    local currentTime = tick()
    if currentTime - AutoFuel.lastFuelTime < AutoFuel.fuelDelay then
        return false, "Delay not reached"
    end
    
    local mainFire = AutoFuel.getMainFire()
    if not mainFire then
        return false, "MainFire not found"
    end
    
    local logToUse = AutoFuel.getBestLogItem()
    if not logToUse then
        return false, "No suitable Log item available"
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
        return true, string.format("Fuel added successfully using %s", logToUse.Name)
    else
        return false, "Failed to fuel fire: " .. tostring(result)
    end
end

function AutoFuel.autoFuelLoop()
    if not AutoFuel.autoFuelEnabled then return end
    
    local inRange, distance = AutoFuel.isInRange(50)
    
    if inRange then
        local success, message = AutoFuel.fuelFire()
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
        local logs = AutoFuel.findLogItems()
        local logCount = #logs
        local inRange, distance = AutoFuel.isInRange(50)
        
        if logCount == 0 then
            return "Status: No Log items found in workspace.Items!", 0
        elseif not inRange then
            return string.format("Status: Too far from MainFire (%.1f studs) - %d logs available", distance or 0, logCount), distance or 0
        else
            return string.format("Status: Auto fueling MainFire (%.1f studs) - %d logs available - Delay: %.1fs", distance, logCount, AutoFuel.fuelDelay), distance
        end
    else
        local logs = AutoFuel.findLogItems()
        return string.format("Status: Auto fuel disabled - %d logs available", #logs), 0
    end
end

return AutoFuel