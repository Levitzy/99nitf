local AutoFuel = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 1
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0
AutoFuel.batchSize = 2
AutoFuel.totalItemsMoved = 0
AutoFuel.sessionStats = {
    logs = 0,
    coal = 0,
    canisters = 0,
    startTime = 0
}

local FUEL_PRIORITIES = {
    ["Coal"] = 3,
    ["FuelCanister"] = 2,
    ["Log"] = 1
}

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
    local success, result = pcall(function()
        local workspace = game:GetService("Workspace")
        local map = workspace:WaitForChild("Map")
        local campground = map:WaitForChild("Campground")
        local mainFire = campground:WaitForChild("MainFire")
        return mainFire
    end)
    
    return success and result or nil, success and result or nil
end

function AutoFuel.findLogItems()
    local workspace = game:GetService("Workspace")
    local fuelItems = {}
    
    for _, item in pairs(workspace:GetChildren()) do
        if item.Name == "Log" and item:FindFirstChild("Meshes/log_Cylinder") then
            table.insert(fuelItems, {item = item, type = "Log", priority = FUEL_PRIORITIES["Log"]})
        elseif item.Name == "Coal" and item:FindFirstChild("Coal") then
            table.insert(fuelItems, {item = item, type = "Coal", priority = FUEL_PRIORITIES["Coal"]})
        elseif item.Name == "FuelCanister" and (item:FindFirstChild("Handle") or item:FindFirstChildOfClass("Part")) then
            table.insert(fuelItems, {item = item, type = "FuelCanister", priority = FUEL_PRIORITIES["FuelCanister"]})
        end
    end
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item.Name == "Log" and (item:FindFirstChild("Handle") or item:FindFirstChild("Meshes/log_Cylinder")) then
                table.insert(fuelItems, {item = item, type = "Log", priority = FUEL_PRIORITIES["Log"]})
            elseif item.Name == "Coal" and item:FindFirstChild("Coal") then
                table.insert(fuelItems, {item = item, type = "Coal", priority = FUEL_PRIORITIES["Coal"]})
            elseif item.Name == "FuelCanister" and (item:FindFirstChild("Handle") or item:FindFirstChildOfClass("Part")) then
                table.insert(fuelItems, {item = item, type = "FuelCanister", priority = FUEL_PRIORITIES["FuelCanister"]})
            end
        end
    end
    
    local droppedFolder = workspace:FindFirstChild("Dropped")
    if droppedFolder then
        for _, item in pairs(droppedFolder:GetChildren()) do
            if item.Name == "Log" and (item:FindFirstChild("Handle") or item:FindFirstChild("Meshes/log_Cylinder")) then
                table.insert(fuelItems, {item = item, type = "Log", priority = FUEL_PRIORITIES["Log"]})
            elseif item.Name == "Coal" and item:FindFirstChild("Coal") then
                table.insert(fuelItems, {item = item, type = "Coal", priority = FUEL_PRIORITIES["Coal"]})
            elseif item.Name == "FuelCanister" and (item:FindFirstChild("Handle") or item:FindFirstChildOfClass("Part")) then
                table.insert(fuelItems, {item = item, type = "FuelCanister", priority = FUEL_PRIORITIES["FuelCanister"]})
            end
        end
    end
    
    table.sort(fuelItems, function(a, b)
        return a.priority > b.priority
    end)
    
    return fuelItems
end

function AutoFuel.moveItemToMainFire(fuelItemData)
    local fuelItem = fuelItemData.item
    local mainFire, _ = AutoFuel.getMainFire()
    if not mainFire or not fuelItem or not fuelItem.Parent then
        return false
    end
    
    local success = pcall(function()
        local fuelHandle = nil
        
        if fuelItem.Name == "Log" then
            fuelHandle = fuelItem:FindFirstChild("Handle") or fuelItem:FindFirstChild("Meshes/log_Cylinder")
        elseif fuelItem.Name == "Coal" then
            fuelHandle = fuelItem:FindFirstChild("Coal")
        elseif fuelItem.Name == "FuelCanister" then
            fuelHandle = fuelItem:FindFirstChild("Handle") or fuelItem:FindFirstChildOfClass("Part")
        end
        
        if not fuelHandle then
            fuelHandle = fuelItem:FindFirstChildOfClass("Part") or fuelItem:FindFirstChildOfClass("MeshPart")
        end
        
        if fuelHandle then
            local mainFireCFrame = mainFire:GetBoundingBox()
            local dropPosition = mainFireCFrame * CFrame.new(
                math.random(-6, 6),
                math.random(22, 35),
                math.random(-6, 6)
            )
            
            if fuelHandle:FindFirstChild("BodyVelocity") then
                fuelHandle.BodyVelocity:Destroy()
            end
            if fuelHandle:FindFirstChild("BodyAngularVelocity") then
                fuelHandle.BodyAngularVelocity:Destroy()
            end
            if fuelHandle:FindFirstChild("BodyPosition") then
                fuelHandle.BodyPosition:Destroy()
            end
            
            fuelHandle.CFrame = dropPosition
            
            local dropSpeed = math.random(-10, -4)
            fuelHandle.Velocity = Vector3.new(
                math.random(-4, 4),
                dropSpeed,
                math.random(-4, 4)
            )
            fuelHandle.AngularVelocity = Vector3.new(
                math.random(-8, 8),
                math.random(-8, 8),
                math.random(-8, 8)
            )
            
            if fuelHandle:FindFirstChild("AssemblyLinearVelocity") then
                fuelHandle.AssemblyLinearVelocity = Vector3.new(
                    math.random(-4, 4),
                    dropSpeed,
                    math.random(-4, 4)
                )
            end
            if fuelHandle:FindFirstChild("AssemblyAngularVelocity") then
                fuelHandle.AssemblyAngularVelocity = Vector3.new(
                    math.random(-8, 8),
                    math.random(-8, 8),
                    math.random(-8, 8)
                )
            end
            
            AutoFuel.totalItemsMoved = AutoFuel.totalItemsMoved + 1
            if fuelItem.Name == "Log" then
                AutoFuel.sessionStats.logs = AutoFuel.sessionStats.logs + 1
            elseif fuelItem.Name == "Coal" then
                AutoFuel.sessionStats.coal = AutoFuel.sessionStats.coal + 1
            elseif fuelItem.Name == "FuelCanister" then
                AutoFuel.sessionStats.canisters = AutoFuel.sessionStats.canisters + 1
            end
        end
    end)
    
    return success
end

function AutoFuel.autoFuelLoop()
    if not AutoFuel.autoFuelEnabled then return end
    
    local currentTime = tick()
    if currentTime - AutoFuel.lastFuelTime < AutoFuel.fuelDelay then
        return
    end
    
    local fuelItems = AutoFuel.findLogItems()
    
    if #fuelItems > 0 then
        local itemsToProcess = math.min(#fuelItems, AutoFuel.batchSize)
        local successCount = 0
        
        for i = 1, itemsToProcess do
            local fuelItemData = fuelItems[i]
            if fuelItemData.item and fuelItemData.item.Parent then
                local success = AutoFuel.moveItemToMainFire(fuelItemData)
                if success then
                    successCount = successCount + 1
                end
                wait(0.2)
            end
        end
        
        if successCount > 0 then
            AutoFuel.lastFuelTime = currentTime
        end
    end
end

function AutoFuel.setEnabled(enabled)
    AutoFuel.autoFuelEnabled = enabled
    
    if enabled then
        if AutoFuel.sessionStats.startTime == 0 then
            AutoFuel.sessionStats.startTime = tick()
        end
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

function AutoFuel.setBatchSize(size)
    AutoFuel.batchSize = math.max(1, math.min(5, size))
end

function AutoFuel.getSessionTime()
    if AutoFuel.sessionStats.startTime > 0 then
        return tick() - AutoFuel.sessionStats.startTime
    end
    return 0
end

function AutoFuel.resetStats()
    AutoFuel.sessionStats = {
        logs = 0,
        coal = 0,
        canisters = 0,
        startTime = AutoFuel.autoFuelEnabled and tick() or 0
    }
    AutoFuel.totalItemsMoved = 0
end

function AutoFuel.getDetailedStats()
    local sessionTime = AutoFuel.getSessionTime()
    local itemsPerMinute = sessionTime > 0 and (AutoFuel.totalItemsMoved / sessionTime * 60) or 0
    
    return {
        totalItems = AutoFuel.totalItemsMoved,
        logs = AutoFuel.sessionStats.logs,
        coal = AutoFuel.sessionStats.coal,
        canisters = AutoFuel.sessionStats.canisters,
        sessionTime = sessionTime,
        itemsPerMinute = itemsPerMinute
    }
end

function AutoFuel.getStatus()
    if AutoFuel.autoFuelEnabled then
        local fuelItems = AutoFuel.findLogItems()
        local mainFire, _ = AutoFuel.getMainFire()
        
        if not mainFire then
            return "Status: MainFire not found!", 0
        elseif #fuelItems > 0 then
            local playerPos = AutoFuel.getPlayerPosition()
            local mainFireCFrame = mainFire:GetBoundingBox()
            local mainFirePos = mainFireCFrame.Position
            local distance = playerPos and AutoFuel.getDistance(playerPos, mainFirePos) or 0
            
            local logCount = 0
            local coalCount = 0
            local canisterCount = 0
            
            for _, itemData in pairs(fuelItems) do
                if itemData.item.Name == "Log" then
                    logCount = logCount + 1
                elseif itemData.item.Name == "Coal" then
                    coalCount = coalCount + 1
                elseif itemData.item.Name == "FuelCanister" then
                    canisterCount = canisterCount + 1
                end
            end
            
            local stats = AutoFuel.getDetailedStats()
            
            return string.format("Status: Fueling - L:%d C:%d F:%d | Moved:%d Rate:%.1f/min Delay:%.1fs", 
                   logCount, coalCount, canisterCount, 
                   AutoFuel.totalItemsMoved, stats.itemsPerMinute, AutoFuel.fuelDelay), distance
        else
            return string.format("Status: No fuel items found | Moved:%d total", 
                   AutoFuel.totalItemsMoved), 0
        end
    else
        return string.format("Status: Auto fuel disabled | Session moved:%d items", 
               AutoFuel.totalItemsMoved), 0
    end
end

return AutoFuel