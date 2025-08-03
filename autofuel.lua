local AutoFuel = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 1
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0
AutoFuel.maxDistance = 100

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
    local success, mainFire = pcall(function()
        return workspace:WaitForChild("Map"):WaitForChild("Campground"):WaitForChild("MainFire")
    end)
    
    if success and mainFire then
        return mainFire
    end
    return nil
end

function AutoFuel.findLogsInWorkspace()
    local playerPos = AutoFuel.getPlayerPosition()
    if not playerPos then return {} end
    
    local workspace = game:GetService("Workspace")
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if not itemsFolder then return {} end
    
    local logsInRange = {}
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item.Name == "Log" and item:IsA("Model") and item:FindFirstChild("Meshes/log_Cylinder") then
            local logPos = item:FindFirstChild("Meshes/log_Cylinder").Position
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

function AutoFuel.dropLogToFire(log)
    local mainFire = AutoFuel.getMainFire()
    if not mainFire or not log or not log.Parent then
        return false
    end
    
    local playerPos = AutoFuel.getPlayerPosition()
    if not playerPos then return false end
    
    local firePos = mainFire.Position
    local logMesh = log:FindFirstChild("Meshes/log_Cylinder")
    if not logMesh then return false end
    
    local lookDirection = (firePos - playerPos).Unit
    local cframe = CFrame.lookAt(playerPos, firePos)
    
    local success, result = pcall(function()
        logMesh.CFrame = CFrame.new(firePos + Vector3.new(0, 2, 0))
        wait(0.1)
        logMesh.CFrame = CFrame.new(firePos)
    end)
    
    return success
end

function AutoFuel.fuelFire()
    if not AutoFuel.autoFuelEnabled then return end
    
    local currentTime = tick()
    if currentTime - AutoFuel.lastFuelTime < AutoFuel.fuelDelay then
        return false
    end
    
    local logsInRange = AutoFuel.findLogsInWorkspace()
    
    if #logsInRange > 0 then
        local logData = logsInRange[1]
        local success = AutoFuel.dropLogToFire(logData.log)
        
        if success then
            AutoFuel.lastFuelTime = currentTime
            return true
        end
    end
    
    return false
end

function AutoFuel.autoFuelLoop()
    if not AutoFuel.autoFuelEnabled then return end
    
    AutoFuel.fuelFire()
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
        local logsInRange = AutoFuel.findLogsInWorkspace()
        local mainFire = AutoFuel.getMainFire()
        
        if not mainFire then
            return "Status: MainFire not found!", 0
        elseif #logsInRange > 0 then
            local closestDistance = logsInRange[1].distance
            return string.format("Status: Fueling fire with %d logs (closest: %.1f studs) - Delay: %.1fs", #logsInRange, closestDistance, AutoFuel.fuelDelay), closestDistance
        else
            return "Status: No logs in range", 0
        end
    else
        return "Status: Auto fuel disabled", 0
    end
end

return AutoFuel