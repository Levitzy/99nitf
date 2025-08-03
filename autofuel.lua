local AutoFuel = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 1
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0
AutoFuel.prioritizeClosest = true
AutoFuel.smartDropping = true
AutoFuel.batchSize = 3
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

local DROP_ZONES = {
    CFrame.new(0, 25, 0),
    CFrame.new(-3, 30, 2),
    CFrame.new(3, 28, -2),
    CFrame.new(-2, 32, -3),
    CFrame.new(2, 26, 3)
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
        local map = workspace:WaitForChild("Map", 5)
        if not map then return nil end
        
        local campground = map:WaitForChild("Campground", 5)
        if not campground then return nil end
        
        local mainFire = campground:WaitForChild("MainFire", 5)
        return mainFire
    end)
    
    return success and result or nil
end

function AutoFuel.isValidFuelItem(item)
    if not item or not item.Parent then return false end
    
    local itemName = item.Name
    if itemName == "Log" then
        return item:FindFirstChild("Meshes/log_Cylinder") or item:FindFirstChild("Handle")
    elseif itemName == "Coal" then
        return item:FindFirstChild("Coal")
    elseif itemName == "FuelCanister" then
        return item:FindFirstChild("Handle") or item:FindFirstChildOfClass("Part")
    end
    
    return false
end

function AutoFuel.findLogItems()
    local workspace = game:GetService("Workspace")
    local fuelItems = {}
    local playerPos = AutoFuel.getPlayerPosition()
    
    local function scanContainer(container, containerName)
        if not container then return end
        
        for _, item in pairs(container:GetChildren()) do
            if AutoFuel.isValidFuelItem(item) then
                local distance = math.huge
                
                if playerPos then
                    local itemPos = item:FindFirstChild("Handle") or 
                                  item:FindFirstChild("Meshes/log_Cylinder") or 
                                  item:FindFirstChild("Coal") or 
                                  item:FindFirstChildOfClass("Part")
                    
                    if itemPos and itemPos.Position then
                        distance = AutoFuel.getDistance(playerPos, itemPos.Position)
                        
                        table.insert(fuelItems, {
                            item = item,
                            distance = distance,
                            priority = FUEL_PRIORITIES[item.Name] or 1,
                            container = containerName
                        })
                    end
                end
            end
        end
    end
    
    scanContainer(workspace, "Workspace")
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        scanContainer(itemsFolder, "Items")
    end
    
    local droppedFolder = workspace:FindFirstChild("Dropped")
    if droppedFolder then
        scanContainer(droppedFolder, "Dropped")
    end
    
    if AutoFuel.prioritizeClosest then
        table.sort(fuelItems, function(a, b)
            if a.priority == b.priority then
                return a.distance < b.distance
            end
            return a.priority > b.priority
        end)
    else
        table.sort(fuelItems, function(a, b)
            return a.priority > b.priority
        end)
    end
    
    return fuelItems
end

function AutoFuel.getOptimalDropPosition(mainFire, index)
    local mainFireCFrame = mainFire:GetBoundingBox()
    local dropOffset = DROP_ZONES[((index - 1) % #DROP_ZONES) + 1]
    
    if AutoFuel.smartDropping then
        local randomOffset = CFrame.new(
            math.random(-2, 2),
            math.random(0, 5),
            math.random(-2, 2)
        )
        return mainFireCFrame * dropOffset * randomOffset
    else
        return mainFireCFrame * dropOffset
    end
end

function AutoFuel.moveItemToMainFire(fuelItemData, index)
    local fuelItem = fuelItemData.item
    local mainFire = AutoFuel.getMainFire()
    
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
        
        if fuelHandle and fuelHandle:IsA("BasePart") then
            local dropPosition = AutoFuel.getOptimalDropPosition(mainFire, index or 1)
            
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
            
            local dropSpeed = math.random(-12, -5)
            local horizontalForce = math.random(-4, 4)
            
            fuelHandle.Velocity = Vector3.new(
                horizontalForce,
                dropSpeed,
                horizontalForce
            )
            
            fuelHandle.AngularVelocity = Vector3.new(
                math.random(-10, 10),
                math.random(-10, 10),
                math.random(-10, 10)
            )
            
            if fuelHandle:FindFirstChild("AssemblyLinearVelocity") then
                fuelHandle.AssemblyLinearVelocity = fuelHandle.Velocity
            end
            if fuelHandle:FindFirstChild("AssemblyAngularVelocity") then
                fuelHandle.AssemblyAngularVelocity = fuelHandle.AngularVelocity
            end
            
            AutoFuel.totalItemsMoved = AutoFuel.totalItemsMoved + 1
            AutoFuel.sessionStats[string.lower(fuelItem.Name .. "s")] = 
                (AutoFuel.sessionStats[string.lower(fuelItem.Name .. "s")] or 0) + 1
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
                local success = AutoFuel.moveItemToMainFire(fuelItemData, i)
                if success then
                    successCount = successCount + 1
                end
                wait(0.1)
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
    AutoFuel.fuelDelay = math.max(0.1, delay)
end

function AutoFuel.setPrioritizeClosest(prioritize)
    AutoFuel.prioritizeClosest = prioritize
end

function AutoFuel.setSmartDropping(smart)
    AutoFuel.smartDropping = smart
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
        local mainFire = AutoFuel.getMainFire()
        
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
            local avgDistance = 0
            
            for _, itemData in pairs(fuelItems) do
                if itemData.item.Name == "Log" then
                    logCount = logCount + 1
                elseif itemData.item.Name == "Coal" then
                    coalCount = coalCount + 1
                elseif itemData.item.Name == "FuelCanister" then
                    canisterCount = canisterCount + 1
                end
                avgDistance = avgDistance + itemData.distance
            end
            
            avgDistance = #fuelItems > 0 and avgDistance / #fuelItems or 0
            
            local stats = AutoFuel.getDetailedStats()
            
            return string.format("Status: Fueling (L:%d C:%d F:%d) Moved:%d Rate:%.1f/min", 
                   logCount, coalCount, canisterCount, 
                   AutoFuel.totalItemsMoved, stats.itemsPerMinute), distance
        else
            return string.format("Status: No fuel items found - Moved:%d total", 
                   AutoFuel.totalItemsMoved), 0
        end
    else
        return string.format("Status: Auto fuel disabled - Session moved:%d items", 
               AutoFuel.totalItemsMoved), 0
    end
end

return AutoFuel