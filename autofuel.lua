local AutoFuel = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 0.5
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0
AutoFuel.startTime = 0
AutoFuel.initDelay = 10

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
    
    local function findMainFire()
        local map = workspace:FindFirstChild("Map")
        if not map then return nil end
        
        local campground = map:FindFirstChild("Campground")
        if not campground then return nil end
        
        local mainFire = campground:FindFirstChild("MainFire")
        return mainFire
    end
    
    local mainFire = findMainFire()
    if mainFire then
        return mainFire
    end
    
    wait(1)
    return findMainFire()
end

function AutoFuel.findAllFuelItems()
    local workspace = game:GetService("Workspace")
    local fuelItems = {}
    
    local function isValidFuelItem(item)
        if item.Name == "Log" then
            return item:FindFirstChild("Handle") or 
                   item:FindFirstChild("Meshes/log_Cylinder") or
                   item:FindFirstChildOfClass("Part") or
                   item:FindFirstChildOfClass("MeshPart")
        elseif item.Name == "Coal" then
            return item:FindFirstChild("Coal") or
                   item:FindFirstChild("Handle") or
                   item:FindFirstChildOfClass("Part")
        elseif item.Name == "Fuel Canister" then
            return item:FindFirstChild("Handle") or
                   item:FindFirstChildOfClass("Part") or
                   item:FindFirstChildOfClass("MeshPart")
        end
        return false
    end
    
    local function scanContainer(container)
        for _, item in pairs(container:GetChildren()) do
            if isValidFuelItem(item) then
                table.insert(fuelItems, item)
            end
            
            if item:IsA("Folder") or item:IsA("Model") then
                scanContainer(item)
            end
        end
    end
    
    scanContainer(workspace)
    
    return fuelItems
end

function AutoFuel.getFuelHandle(fuelItem)
    local handle = nil
    
    if fuelItem.Name == "Log" then
        handle = fuelItem:FindFirstChild("Handle") or 
                fuelItem:FindFirstChild("Meshes/log_Cylinder") or
                fuelItem:FindFirstChild("Meshes") and fuelItem.Meshes:FindFirstChild("log_Cylinder")
    elseif fuelItem.Name == "Coal" then
        handle = fuelItem:FindFirstChild("Coal") or
                fuelItem:FindFirstChild("Handle")
    elseif fuelItem.Name == "Fuel Canister" then
        handle = fuelItem:FindFirstChild("Handle")
    end
    
    if not handle then
        handle = fuelItem:FindFirstChildOfClass("Part") or 
                fuelItem:FindFirstChildOfClass("MeshPart") or
                fuelItem:FindFirstChildOfClass("UnionOperation")
    end
    
    return handle
end

function AutoFuel.teleportItemToMainFire(fuelItem)
    if not fuelItem or not fuelItem.Parent then
        return false
    end
    
    local success = pcall(function()
        local fuelHandle = AutoFuel.getFuelHandle(fuelItem)
        
        if fuelHandle and fuelHandle:IsA("BasePart") then
            local targetPosition = Vector3.new(0, 4, -3)
            local dropHeight = math.random(20, 30)
            
            local spawnPosition = targetPosition + Vector3.new(
                math.random(-3, 3),
                dropHeight,
                math.random(-3, 3)
            )
            
            fuelHandle.Anchored = false
            fuelHandle.CanCollide = true
            
            if fuelHandle:FindFirstChild("BodyVelocity") then
                fuelHandle.BodyVelocity:Destroy()
            end
            if fuelHandle:FindFirstChild("BodyAngularVelocity") then
                fuelHandle.BodyAngularVelocity:Destroy()
            end
            if fuelHandle:FindFirstChild("BodyPosition") then
                fuelHandle.BodyPosition:Destroy()
            end
            
            fuelHandle.CFrame = CFrame.new(spawnPosition)
            
            wait(0.1)
            
            fuelHandle.Velocity = Vector3.new(
                math.random(-2, 2),
                math.random(-25, -20),
                math.random(-2, 2)
            )
            
            fuelHandle.AngularVelocity = Vector3.new(
                math.random(-15, 15),
                math.random(-15, 15),
                math.random(-15, 15)
            )
            
            if fuelHandle.AssemblyLinearVelocity then
                fuelHandle.AssemblyLinearVelocity = Vector3.new(
                    math.random(-2, 2),
                    math.random(-25, -20),
                    math.random(-2, 2)
                )
            end
            
            if fuelHandle.AssemblyAngularVelocity then
                fuelHandle.AssemblyAngularVelocity = Vector3.new(
                    math.random(-15, 15),
                    math.random(-15, 15),
                    math.random(-15, 15)
                )
            end
        end
    end)
    
    return success
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
    
    local fuelItems = AutoFuel.findAllFuelItems()
    
    if #fuelItems > 0 then
        local itemsToProcess = math.min(#fuelItems, 4)
        local processed = 0
        
        for i = 1, itemsToProcess do
            local fuelItem = fuelItems[i]
            if fuelItem and fuelItem.Parent then
                local success = AutoFuel.teleportItemToMainFire(fuelItem)
                if success then
                    processed = processed + 1
                end
                wait(0.15)
            end
        end
        
        if processed > 0 then
            AutoFuel.lastFuelTime = currentTime
        end
    end
end

function AutoFuel.setEnabled(enabled)
    AutoFuel.autoFuelEnabled = enabled
    
    if enabled then
        AutoFuel.startTime = tick()
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
        local currentTime = tick()
        local timeLeft = AutoFuel.initDelay - (currentTime - AutoFuel.startTime)
        
        if timeLeft > 0 then
            return string.format("Status: Starting in %.1f seconds...", timeLeft), 0
        end
        
        local fuelItems = AutoFuel.findAllFuelItems()
        local mainFire = AutoFuel.getMainFire()
        
        if not mainFire then
            return "Status: MainFire not found!", 0
        elseif #fuelItems > 0 then
            local playerPos = AutoFuel.getPlayerPosition()
            local targetPos = Vector3.new(0, 4, -3)
            local distance = playerPos and AutoFuel.getDistance(playerPos, targetPos) or 0
            
            local logCount = 0
            local coalCount = 0
            local canisterCount = 0
            
            for _, item in pairs(fuelItems) do
                if item.Name == "Log" then
                    logCount = logCount + 1
                elseif item.Name == "Coal" then
                    coalCount = coalCount + 1
                elseif item.Name == "Fuel Canister" then
                    canisterCount = canisterCount + 1
                end
            end
            
            return string.format("Status: ACTIVE - Teleporting to (0,4,-3) | L:%d C:%d FC:%d", 
                   logCount, coalCount, canisterCount), distance
        else
            return "Status: No fuel items found - Scanning...", 0
        end
    else
        return "Status: Auto fuel disabled", 0
    end
end

return AutoFuel