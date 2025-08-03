local AutoFuel = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 1
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0
AutoFuel.maxDistance = 75

function AutoFuel.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function AutoFuel.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function AutoFuel.getMainFirePosition()
    local mainFire = Workspace:FindFirstChild("Map")
    if mainFire then
        mainFire = mainFire:FindFirstChild("Campground")
        if mainFire then
            mainFire = mainFire:FindFirstChild("MainFire")
            if mainFire and mainFire:FindFirstChild("PrimaryPart") then
                return mainFire.PrimaryPart.Position
            elseif mainFire then
                local firstChild = mainFire:GetChildren()[1]
                if firstChild and firstChild:IsA("BasePart") then
                    return firstChild.Position
                end
            end
        end
    end
    return nil
end

function AutoFuel.findLogsInRange()
    local playerPos = AutoFuel.getPlayerPosition()
    if not playerPos then return {} end
    
    local itemsFolder = Workspace:FindFirstChild("Items")
    if not itemsFolder then return {} end
    
    local logsInRange = {}
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item.Name == "Log" and item:IsA("Model") and item:FindFirstChild("Meshes/log_Cylinder") then
            local logPos = item["Meshes/log_Cylinder"].Position
            local distance = AutoFuel.getDistance(playerPos, logPos)
            
            if distance <= AutoFuel.maxDistance then
                table.insert(logsInRange, {log = item, distance = distance})
            end
        end
    end
    
    table.sort(logsInRange, function(a, b)
        return a.distance < b.distance
    end)
    
    return logsInRange
end

function AutoFuel.burnLogToMainFire(log)
    local mainFire = Workspace:WaitForChild("Map"):WaitForChild("Campground"):WaitForChild("MainFire")
    
    local args = {
        mainFire,
        log
    }
    
    local success, result = pcall(function()
        return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestBurnItem"):FireServer(unpack(args))
    end)
    
    return success
end

function AutoFuel.burnMultipleLogs(logsData)
    local currentTime = tick()
    if currentTime - AutoFuel.lastFuelTime < AutoFuel.fuelDelay then
        return false
    end
    
    local burnedCount = 0
    
    for _, logData in pairs(logsData) do
        if logData.log and logData.log.Parent then
            local success = AutoFuel.burnLogToMainFire(logData.log)
            if success then
                burnedCount = burnedCount + 1
            end
            wait(0.1)
        end
    end
    
    AutoFuel.lastFuelTime = currentTime
    return burnedCount > 0
end

function AutoFuel.autoFuelLoop()
    if not AutoFuel.autoFuelEnabled then return end
    
    local logsInRange = AutoFuel.findLogsInRange()
    
    if #logsInRange > 0 then
        local success = AutoFuel.burnMultipleLogs(logsInRange)
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

function AutoFuel.setMaxDistance(distance)
    AutoFuel.maxDistance = distance
end

function AutoFuel.getStatus()
    if AutoFuel.autoFuelEnabled then
        local logsInRange = AutoFuel.findLogsInRange()
        local mainFirePos = AutoFuel.getMainFirePosition()
        
        if not mainFirePos then
            return "Status: MainFire not found!", 0
        elseif #logsInRange > 0 then
            local closestDistance = logsInRange[1].distance
            return string.format("Status: Fueling with %d logs (closest: %.1f studs) - Delay: %.1fs", #logsInRange, closestDistance, AutoFuel.fuelDelay), closestDistance
        else
            return "Status: No logs in range", 0
        end
    else
        return "Status: Auto fuel disabled", 0
    end
end

return AutoFuel