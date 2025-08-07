local AutoFuel = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 3
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0
AutoFuel.startTime = 0
AutoFuel.initDelay = 10
AutoFuel.scanDelay = 8
AutoFuel.lastScanTime = 0
AutoFuel.cachedFuelItems = {}
AutoFuel.mainFirePosition = nil

function AutoFuel.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function AutoFuel.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function AutoFuel.findMainFirePosition()
    local workspace = game:GetService("Workspace")
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    
    local campground = map:FindFirstChild("Campground")
    if not campground then return nil end
    
    local mainFire = campground:FindFirstChild("MainFire")
    if not mainFire then return nil end
    
    if mainFire:FindFirstChild("Fire") then
        return mainFire.Fire.Position
    elseif mainFire:FindFirstChildOfClass("Part") then
        return mainFire:FindFirstChildOfClass("Part").Position
    end
    
    return mainFire.Position or Vector3.new(0, 4, -3)
end

function AutoFuel.scanForFuelItems()
    local workspace = game:GetService("Workspace")
    local fuelItems = {}
    local maxItems = 10
    
    for _, item in pairs(workspace:GetChildren()) do
        if #fuelItems >= maxItems then break end
        if item.Name == "Log" or item.Name == "Coal" or item.Name == "Fuel Canister" then
            table.insert(fuelItems, item)
        end
    end
    
    if #fuelItems < maxItems then
        local itemsFolder = workspace:FindFirstChild("Items")
        if itemsFolder then
            for _, item in pairs(itemsFolder:GetChildren()) do
                if #fuelItems >= maxItems then break end
                if item.Name == "Log" or item.Name == "Coal" or item.Name == "Fuel Canister" then
                    table.insert(fuelItems, item)
                end
            end
        end
    end
    
    return fuelItems
end

function AutoFuel.getFuelHandle(fuelItem)
    if fuelItem.Name == "Log" then
        return fuelItem:FindFirstChild("Handle") or fuelItem:FindFirstChild("Meshes/log_Cylinder")
    elseif fuelItem.Name == "Coal" then
        return fuelItem:FindFirstChild("Coal")
    elseif fuelItem.Name == "Fuel Canister" then
        return fuelItem:FindFirstChild("Handle")
    end
    return nil
end

function AutoFuel.teleportItemToFire(fuelItem)
    if not fuelItem or not fuelItem.Parent then
        return false
    end
    
    local fuelHandle = AutoFuel.getFuelHandle(fuelItem)
    if not fuelHandle then return false end
    
    local firePos = AutoFuel.mainFirePosition
    if not firePos then
        firePos = AutoFuel.findMainFirePosition()
        if not firePos then
            firePos = Vector3.new(0, 4, -3)
        end
        AutoFuel.mainFirePosition = firePos
    end
    
    local dropPosition = firePos + Vector3.new(
        math.random(-1, 1),
        15,
        math.random(-1, 1)
    )
    
    fuelHandle.CFrame = CFrame.new(dropPosition)
    fuelHandle.Velocity = Vector3.new(0, -25, 0)
    
    return true
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
    
    if currentTime - AutoFuel.lastScanTime > AutoFuel.scanDelay or #AutoFuel.cachedFuelItems == 0 then
        AutoFuel.cachedFuelItems = AutoFuel.scanForFuelItems()
        AutoFuel.lastScanTime = currentTime
    end
    
    for i = #AutoFuel.cachedFuelItems, 1, -1 do
        local item = AutoFuel.cachedFuelItems[i]
        if not item or not item.Parent then
            table.remove(AutoFuel.cachedFuelItems, i)
        end
    end
    
    if #AutoFuel.cachedFuelItems > 0 then
        local item = AutoFuel.cachedFuelItems[1]
        if AutoFuel.teleportItemToFire(item) then
            table.remove(AutoFuel.cachedFuelItems, 1)
        end
        AutoFuel.lastFuelTime = currentTime
    end
end

function AutoFuel.setEnabled(enabled)
    AutoFuel.autoFuelEnabled = enabled
    
    if enabled then
        AutoFuel.startTime = tick()
        AutoFuel.lastScanTime = 0
        AutoFuel.cachedFuelItems = {}
        AutoFuel.mainFirePosition = AutoFuel.findMainFirePosition()
        AutoFuel.fuelConnection = RunService.Heartbeat:Connect(AutoFuel.autoFuelLoop)
    else
        if AutoFuel.fuelConnection then
            AutoFuel.fuelConnection:Disconnect()
            AutoFuel.fuelConnection = nil
        end
        AutoFuel.cachedFuelItems = {}
        AutoFuel.mainFirePosition = nil
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
            return string.format("Status: Starting in %.0f seconds...", timeLeft), 0
        end
        
        local itemCount = #AutoFuel.cachedFuelItems
        
        if itemCount > 0 then
            local logCount = 0
            local coalCount = 0
            local canisterCount = 0
            
            for _, item in pairs(AutoFuel.cachedFuelItems) do
                if item and item.Parent then
                    if item.Name == "Log" then
                        logCount = logCount + 1
                    elseif item.Name == "Coal" then
                        coalCount = coalCount + 1
                    elseif item.Name == "Fuel Canister" then
                        canisterCount = canisterCount + 1
                    end
                end
            end
            
            return string.format("Status: FEEDING FIRE - L:%d C:%d FC:%d", 
                   logCount, coalCount, canisterCount), itemCount
        else
            return "Status: Scanning for fuel...", 0
        end
    else
        return "Status: Auto fuel disabled", 0
    end
end

return AutoFuel