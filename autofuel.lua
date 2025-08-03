local AutoFuel = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 1
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0
AutoFuel.totalItemsMoved = 0
AutoFuel.sessionStats = {
    logs = 0,
    coal = 0,
    canisters = 0,
    startTime = 0
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
    local workspace = game:GetService("Workspace")
    local map = workspace:WaitForChild("Map")
    local campground = map:WaitForChild("Campground")
    local mainFire = campground:WaitForChild("MainFire")
    
    return mainFire, mainFire
end

function AutoFuel.findLogItems()
    local workspace = game:GetService("Workspace")
    local fuelItems = {}
    
    local function addItem(item, itemType)
        table.insert(fuelItems, {
            item = item,
            type = itemType,
            priority = itemType == "Coal" and 3 or (itemType == "FuelCanister" and 2 or 1)
        })
    end
    
    for _, item in pairs(workspace:GetChildren()) do
        if item.Name == "Log" and item:FindFirstChild("Meshes/log_Cylinder") then
            addItem(item, "Log")
        elseif item.Name == "Coal" and item:FindFirstChild("Coal") then
            addItem(item, "Coal")
        elseif item.Name == "FuelCanister" and (item:FindFirstChild("Handle") or item:FindFirstChildOfClass("Part")) then
            addItem(item, "FuelCanister")
        end
    end
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item.Name == "Log" and (item:FindFirstChild("Handle") or item:FindFirstChild("Meshes/log_Cylinder")) then
                addItem(item, "Log")
            elseif item.Name == "Coal" and item:FindFirstChild("Coal") then
                addItem(item, "Coal")
            elseif item.Name == "FuelCanister" and (item:FindFirstChild("Handle") or item:FindFirstChildOfClass("Part")) then
                addItem(item, "FuelCanister")
            end
        end
    end
    
    table.sort(fuelItems, function(a, b) return a.priority > b.priority end)
    return fuelItems
end

function AutoFuel.getItemHandle(fuelItem)
    if fuelItem.Name == "Log" then
        return fuelItem:FindFirstChild("Handle") or fuelItem:FindFirstChild("Meshes/log_Cylinder")
    elseif fuelItem.Name == "Coal" then
        return fuelItem:FindFirstChild("Coal")
    elseif fuelItem.Name == "FuelCanister" then
        return fuelItem:FindFirstChild("Handle") or fuelItem:FindFirstChildOfClass("Part")
    end
    return fuelItem:FindFirstChildOfClass("Part") or fuelItem:FindFirstChildOfClass("MeshPart")
end

function AutoFuel.teleportItemToFire(fuelItem)
    local mainFire, _ = AutoFuel.getMainFire()
    if not mainFire or not fuelItem or not fuelItem.Parent then
        return false
    end
    
    local handle = AutoFuel.getItemHandle(fuelItem)
    if not handle then return false end
    
    local success = pcall(function()
        local firePosition = mainFire.Position
        -- FIX: Reduced the random horizontal offset to (-1, 1) for better accuracy.
        local offsetX = math.random(-1, 1)
        local offsetY = math.random(15, 25)
        -- FIX: Reduced the random horizontal offset to (-1, 1) for better accuracy.
        local offsetZ = math.random(-1, 1)
        
        local targetPosition = firePosition + Vector3.new(offsetX, offsetY, offsetZ)
        
        handle.CFrame = CFrame.new(targetPosition)
        handle.Anchored = false
        handle.CanCollide = true
        
        if handle.Parent then
            handle.Velocity = Vector3.new(0, -20, 0)
        end
    end)
    
    return success
end

function AutoFuel.moveItemWithForce(fuelItem)
    local mainFire, _ = AutoFuel.getMainFire()
    if not mainFire or not fuelItem or not fuelItem.Parent then
        return false
    end
    
    local handle = AutoFuel.getItemHandle(fuelItem)
    if not handle then return false end
    
    local success = pcall(function()
        local firePos = mainFire.Position
        -- FIX: Reduced the random horizontal offset to (-1, 1) to create a much tighter drop zone.
        local dropPos = firePos + Vector3.new(
            math.random(-1, 1),
            math.random(20, 30),
            math.random(-1, 1)
        )
        
        for _, bodyMover in pairs(handle:GetChildren()) do
            if bodyMover:IsA("BodyVelocity") or bodyMover:IsA("BodyAngularVelocity") or bodyMover:IsA("BodyPosition") then
                bodyMover:Destroy()
            end
        end
        
        local bodyPos = Instance.new("BodyPosition")
        bodyPos.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyPos.Position = dropPos
        bodyPos.P = 3000
        bodyPos.D = 500
        bodyPos.Parent = handle
        
        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVel.Velocity = Vector3.new(0, -15, 0)
        bodyVel.Parent = handle
        
        wait(0.5)
        
        if bodyPos then bodyPos:Destroy() end
        if bodyVel then bodyVel:Destroy() end
    end)
    
    return success
end

function AutoFuel.advancedDrop(fuelItem)
    local mainFire, _ = AutoFuel.getMainFire()
    if not mainFire or not fuelItem or not fuelItem.Parent then
        return false
    end
    
    local handle = AutoFuel.getItemHandle(fuelItem)
    if not handle then return false end
    
    local success = pcall(function()
        local fireBox = mainFire:GetBoundingBox()
        local firePos = fireBox.Position
        
        local dropHeight = firePos.Y + math.random(25, 40)
        -- FIX: Greatly reduced the horizontal offset to (-1, 1) to precisely target the center of the fire.
        local dropX = firePos.X + math.random(-1, 1)
        local dropZ = firePos.Z + math.random(-1, 1)
        
        handle.CFrame = CFrame.new(dropX, dropHeight, dropZ)
        
        handle.Velocity = Vector3.new(
            math.random(-5, 5),
            math.random(-25, -15),
            math.random(-5, 5)
        )
        
        handle.AngularVelocity = Vector3.new(
            math.random(-10, 10),
            math.random(-10, 10),
            math.random(-10, 10)
        )
        
        if handle:GetAttribute("AssemblyLinearVelocity") ~= nil then
            handle:SetAttribute("AssemblyLinearVelocity", handle.Velocity)
        end
        if handle:GetAttribute("AssemblyAngularVelocity") ~= nil then
            handle:SetAttribute("AssemblyAngularVelocity", handle.AngularVelocity)
        end
    end)
    
    return success
end

function AutoFuel.moveItemToMainFire(fuelItemData)
    local fuelItem = fuelItemData.item
    if not fuelItem or not fuelItem.Parent then return false end
    
    local methods = {
        AutoFuel.teleportItemToFire,
        AutoFuel.moveItemWithForce,
        AutoFuel.advancedDrop
    }
    
    for _, method in ipairs(methods) do
        local success = method(fuelItem)
        if success then
            AutoFuel.totalItemsMoved = AutoFuel.totalItemsMoved + 1
            if fuelItem.Name == "Log" then
                AutoFuel.sessionStats.logs = AutoFuel.sessionStats.logs + 1
            elseif fuelItem.Name == "Coal" then
                AutoFuel.sessionStats.coal = AutoFuel.sessionStats.coal + 1
            elseif fuelItem.Name == "FuelCanister" then
                AutoFuel.sessionStats.canisters = AutoFuel.sessionStats.canisters + 1
            end
            return true
        end
        wait(0.1)
    end
    
    return false
end

function AutoFuel.autoFuelLoop()
    if not AutoFuel.autoFuelEnabled then return end
    
    local currentTime = tick()
    if currentTime - AutoFuel.lastFuelTime < AutoFuel.fuelDelay then
        return
    end
    
    local fuelItems = AutoFuel.findLogItems()
    
    if #fuelItems > 0 then
        for i = 1, math.min(#fuelItems, 2) do
            local fuelItemData = fuelItems[i]
            if fuelItemData.item and fuelItemData.item.Parent then
                AutoFuel.moveItemToMainFire(fuelItemData)
                wait(0.3)
            end
        end
        AutoFuel.lastFuelTime = currentTime
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

function AutoFuel.getStatus()
    if AutoFuel.autoFuelEnabled then
        local fuelItems = AutoFuel.findLogItems()
        local mainFire, _ = AutoFuel.getMainFire()
        
        if not mainFire then
            return "Status: MainFire not found!", 0
        elseif #fuelItems > 0 then
            local playerPos = AutoFuel.getPlayerPosition()
            local distance = 0
            if playerPos and mainFire then
                distance = AutoFuel.getDistance(playerPos, mainFire.Position)
            end
            
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
            
            local sessionTime = AutoFuel.getSessionTime()
            local itemsPerMinute = sessionTime > 0 and (AutoFuel.totalItemsMoved / sessionTime * 60) or 0
            
            return string.format("Status: Multi-Method Drop - L:%d C:%d F:%d | Moved:%d Rate:%.1f/min", 
                   logCount, coalCount, canisterCount, 
                   AutoFuel.totalItemsMoved, itemsPerMinute), distance
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
