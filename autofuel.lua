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
    local map = Workspace:FindFirstChild("Map")
    if map then
        local campground = map:FindFirstChild("Campground")
        if campground then
            local mainFire = campground:FindFirstChild("MainFire")
            return mainFire
        end
    end
    return nil
end

function AutoFuel.findAllLogs()
    local itemsFolder = Workspace:FindFirstChild("Items")
    if not itemsFolder then return {} end
    
    local playerPos = AutoFuel.getPlayerPosition()
    if not playerPos then return {} end
    
    local allLogs = {}
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item.Name == "Log" and item:IsA("Model") then
            local logPart = item:FindFirstChild("Meshes/log_Cylinder")
            if logPart then
                local logPos = logPart.Position
                local distance = AutoFuel.getDistance(playerPos, logPos)
                
                table.insert(allLogs, {log = item, distance = distance})
            end
        end
    end
    
    table.sort(allLogs, function(a, b)
        return a.distance < b.distance
    end)
    
    return allLogs
end

function AutoFuel.burnLogToMainFire(log)
    local mainFire = AutoFuel.getMainFire()
    if not mainFire then
        return false, "MainFire not found"
    end
    
    local args = {
        mainFire,
        log
    }
    
    local success, result = pcall(function()
        return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestBurnItem"):FireServer(unpack(args))
    end)
    
    return success, result
end

function AutoFuel.burnMultipleLogs(logsData)
    local currentTime = tick()
    if currentTime - AutoFuel.lastFuelTime < AutoFuel.fuelDelay then
        return false
    end
    
    local burnedCount = 0
    local maxBurnPerCycle = 10
    
    for i, logData in pairs(logsData) do
        if i > maxBurnPerCycle then break end
        
        if logData.log and logData.log.Parent then
            local success, error = AutoFuel.burnLogToMainFire(logData.log)
            if success then
                burnedCount = burnedCount + 1
            end
            wait(0.05)
        end
    end
    
    AutoFuel.lastFuelTime = currentTime
    return burnedCount > 0
end

function AutoFuel.autoFuelLoop()
    if not AutoFuel.autoFuelEnabled then return end
    
    local allLogs = AutoFuel.findAllLogs()
    
    if #allLogs > 0 then
        local success = AutoFuel.burnMultipleLogs(allLogs)
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
        local allLogs = AutoFuel.findAllLogs()
        local mainFire = AutoFuel.getMainFire()
        
        if not mainFire then
            return "Status: MainFire not found in Map/Campground!", 0
        elseif #allLogs > 0 then
            local closestDistance = allLogs[1].distance
            return string.format("Status: Fueling with %d logs (closest: %.1f studs) - Delay: %.1fs", #allLogs, closestDistance, AutoFuel.fuelDelay), closestDistance
        else
            return "Status: No logs found in workspace", 0
        end
    else
        return "Status: Auto fuel disabled", 0
    end
end

return AutoFuel