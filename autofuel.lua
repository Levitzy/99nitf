local AutoFuel = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 1
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0
AutoFuel.collectLogs = true
AutoFuel.autoWalkToLogs = true
AutoFuel.walkSpeed = 50
AutoFuel.collectDistance = 15
AutoFuel.currentTarget = nil
AutoFuel.isMoving = false
AutoFuel.logInventory = {}

function AutoFuel.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function AutoFuel.getPlayerCharacter()
    return LocalPlayer.Character
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

function AutoFuel.getMainFirePosition()
    local mainFire = AutoFuel.getMainFire()
    if mainFire then
        local center = mainFire:FindFirstChild("Center")
        if center then
            return center.Position
        elseif mainFire.PrimaryPart then
            return mainFire.PrimaryPart.Position
        else
            local firstPart = mainFire:FindFirstChildOfClass("BasePart")
            if firstPart then
                return firstPart.Position
            end
        end
    end
    return nil
end

function AutoFuel.movePlayerTo(targetPosition)
    local character = AutoFuel.getPlayerCharacter()
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character.HumanoidRootPart
    
    if humanoid and rootPart then
        AutoFuel.isMoving = true
        humanoid.WalkSpeed = AutoFuel.walkSpeed
        humanoid:MoveTo(targetPosition)
        
        local connection
        connection = humanoid.MoveToFinished:Connect(function()
            AutoFuel.isMoving = false
            connection:Disconnect()
        end)
        
        return true
    end
    return false
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
                
                table.insert(allLogs, {log = item, distance = distance, position = logPos})
            end
        end
    end
    
    table.sort(allLogs, function(a, b)
        return a.distance < b.distance
    end)
    
    return allLogs
end

function AutoFuel.getPlayerInventoryLogs()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = AutoFuel.getPlayerCharacter()
    local logs = {}
    
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item.Name == "Log" then
                table.insert(logs, item)
            end
        end
    end
    
    if character then
        for _, item in pairs(character:GetChildren()) do
            if item.Name == "Log" and item:IsA("Tool") then
                table.insert(logs, item)
            end
        end
    end
    
    return logs
end

function AutoFuel.pickupLog(log)
    local character = AutoFuel.getPlayerCharacter()
    if not character or not character:FindFirstChild("Humanoid") then
        return false
    end
    
    local humanoid = character.Humanoid
    
    local success, result = pcall(function()
        humanoid:EquipTool(log)
        return true
    end)
    
    if not success then
        success, result = pcall(function()
            log.Parent = LocalPlayer.Backpack
            return true
        end)
    end
    
    return success
end

function AutoFuel.dropAllLogs()
    local inventoryLogs = AutoFuel.getPlayerInventoryLogs()
    local droppedCount = 0
    
    for _, log in pairs(inventoryLogs) do
        local success, result = pcall(function()
            log.Parent = Workspace
            droppedCount = droppedCount + 1
        end)
        wait(0.1)
    end
    
    return droppedCount
end

function AutoFuel.collectNearbyLog()
    local playerPos = AutoFuel.getPlayerPosition()
    if not playerPos then return false end
    
    local allLogs = AutoFuel.findAllLogs()
    
    for _, logData in pairs(allLogs) do
        if logData.distance <= AutoFuel.collectDistance then
            local success = AutoFuel.pickupLog(logData.log)
            if success then
                return true
            end
        end
    end
    
    return false
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

function AutoFuel.burnInventoryLogs()
    local inventoryLogs = AutoFuel.getPlayerInventoryLogs()
    local burnedCount = 0
    
    for _, log in pairs(inventoryLogs) do
        local success = AutoFuel.burnLogToMainFire(log)
        if success then
            burnedCount = burnedCount + 1
        end
        wait(0.1)
    end
    
    return burnedCount
end

function AutoFuel.autoFuelLoop()
    if not AutoFuel.autoFuelEnabled then return end
    
    local currentTime = tick()
    if currentTime - AutoFuel.lastFuelTime < AutoFuel.fuelDelay then
        return
    end
    
    local playerPos = AutoFuel.getPlayerPosition()
    if not playerPos then return end
    
    local mainFirePos = AutoFuel.getMainFirePosition()
    if not mainFirePos then return end
    
    local inventoryLogs = AutoFuel.getPlayerInventoryLogs()
    local allLogs = AutoFuel.findAllLogs()
    
    if #inventoryLogs > 0 then
        local distanceToMainFire = AutoFuel.getDistance(playerPos, mainFirePos)
        
        if distanceToMainFire > 20 then
            if not AutoFuel.isMoving then
                AutoFuel.movePlayerTo(mainFirePos)
            end
        else
            AutoFuel.burnInventoryLogs()
            AutoFuel.lastFuelTime = currentTime
        end
    elseif AutoFuel.collectLogs and #allLogs > 0 then
        local nearbyCollected = AutoFuel.collectNearbyLog()
        
        if not nearbyCollected and AutoFuel.autoWalkToLogs then
            local closestLog = allLogs[1]
            if closestLog and not AutoFuel.isMoving then
                AutoFuel.currentTarget = closestLog
                AutoFuel.movePlayerTo(closestLog.position)
            end
        end
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
        AutoFuel.isMoving = false
        AutoFuel.currentTarget = nil
    end
end

function AutoFuel.setFuelDelay(delay)
    AutoFuel.fuelDelay = delay
end

function AutoFuel.setCollectLogs(enabled)
    AutoFuel.collectLogs = enabled
end

function AutoFuel.setAutoWalk(enabled)
    AutoFuel.autoWalkToLogs = enabled
end

function AutoFuel.setWalkSpeed(speed)
    AutoFuel.walkSpeed = speed
end

function AutoFuel.setCollectDistance(distance)
    AutoFuel.collectDistance = distance
end

function AutoFuel.getStatus()
    if AutoFuel.autoFuelEnabled then
        local allLogs = AutoFuel.findAllLogs()
        local inventoryLogs = AutoFuel.getPlayerInventoryLogs()
        local mainFire = AutoFuel.getMainFire()
        
        if not mainFire then
            return "Status: MainFire not found in Map/Campground!", 0
        end
        
        local playerPos = AutoFuel.getPlayerPosition()
        local mainFirePos = AutoFuel.getMainFirePosition()
        local distanceToFire = 0
        
        if playerPos and mainFirePos then
            distanceToFire = AutoFuel.getDistance(playerPos, mainFirePos)
        end
        
        if AutoFuel.isMoving and AutoFuel.currentTarget then
            return string.format("Status: Moving to log (%.1f studs away) | Inventory: %d logs", AutoFuel.currentTarget.distance, #inventoryLogs), distanceToFire
        elseif #inventoryLogs > 0 then
            if distanceToFire > 20 then
                return string.format("Status: Moving to MainFire (%.1f studs) | Inventory: %d logs", distanceToFire, #inventoryLogs), distanceToFire
            else
                return string.format("Status: Burning %d logs | World logs: %d", #inventoryLogs, #allLogs), distanceToFire
            end
        elseif #allLogs > 0 then
            local closestDistance = allLogs[1].distance
            return string.format("Status: Collecting logs (%d available, closest: %.1f studs)", #allLogs, closestDistance), distanceToFire
        else
            return "Status: No logs found in workspace", distanceToFire
        end
    else
        return "Status: Auto fuel disabled", 0
    end
end

return AutoFuel