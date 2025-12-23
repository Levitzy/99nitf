local AutoFuel = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 0.8 -- Slightly increased for stability
AutoFuel.scanInterval = 2.0 -- Cache fuel items to reduce lag
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0
AutoFuel.lastScanTime = 0
AutoFuel.isFueling = false
AutoFuel.cachedFuel = {}

function AutoFuel.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function AutoFuel.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function AutoFuel.getMainFireTarget()
    local workspace = game:GetService("Workspace")
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    
    local campground = map:FindFirstChild("Campground")
    if not campground then return nil end
    
    local mainFire = campground:FindFirstChild("MainFire")
    if not mainFire then return nil end
    
    -- Specifically target the Center part as requested
    local center = mainFire:FindFirstChild("Center")
    return center or mainFire
end

function AutoFuel.updateFuelCache()
    local currentTime = tick()
    if currentTime - AutoFuel.lastScanTime < AutoFuel.scanInterval then
        return AutoFuel.cachedFuel
    end

    local workspace = game:GetService("Workspace")
    local fuelItems = {}
    
    local function scanArea(container)
        if not container then return end
        for _, item in pairs(container:GetChildren()) do
            if item.Name == "Log" and (item:FindFirstChild("Meshes/log_Cylinder") or item:FindFirstChild("Handle")) then
                table.insert(fuelItems, item)
            elseif item.Name == "Coal" and (item:FindFirstChild("Coal") or item:FindFirstChild("Handle")) then
                table.insert(fuelItems, item)
            elseif item.Name == "Fuel Canister" and (item:FindFirstChild("Handle") or item:FindFirstChildOfClass("Part")) then
                table.insert(fuelItems, item)
            end
        end
    end
    
    scanArea(workspace:FindFirstChild("Items"))
    scanArea(workspace) -- Some items might be in workspace directly
    
    local mapFolder = workspace:FindFirstChild("Map")
    if mapFolder then
        for _, subfolder in pairs(mapFolder:GetChildren()) do
            if subfolder:IsA("Folder") and subfolder.Name ~= "Campground" then -- Don't scan campground to avoid loop
                scanArea(subfolder)
            end
        end
    end
    
    AutoFuel.cachedFuel = fuelItems
    AutoFuel.lastScanTime = currentTime
    return fuelItems
end

function AutoFuel.findAllFuelItems()
    return AutoFuel.updateFuelCache()
end

function AutoFuel.deliverItem(fuelItem)
    local targetPart = AutoFuel.getMainFireTarget()
    if not targetPart or not fuelItem or not fuelItem.Parent then
        return false
    end

    local fuelHandle = nil
    if fuelItem.Name == "Log" then
        fuelHandle = fuelItem:FindFirstChild("Handle") or fuelItem:FindFirstChild("Meshes/log_Cylinder")
    elseif fuelItem.Name == "Coal" then
        fuelHandle = fuelItem:FindFirstChild("Coal") or fuelItem:FindFirstChild("Handle")
    elseif fuelItem.Name == "Fuel Canister" then
        fuelHandle = fuelItem:FindFirstChild("Handle") or fuelItem:FindFirstChildOfClass("Part")
    end

    if not fuelHandle then
        fuelHandle = fuelItem:FindFirstChildOfClass("Part") or fuelItem:FindFirstChildOfClass("MeshPart")
    end
    if not fuelHandle then return false end

    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    local success = pcall(function()
        -- 1. Bring to player briefly to bypass some distance checks if they exist
        if hrp then
            fuelHandle.CFrame = hrp.CFrame * CFrame.new(0, 0, -1)
            task.wait(0.02)
        end

        -- 2. Drop into the Center of MainFire
        local targetPos = targetPart.Position
        local dropPos = targetPos + Vector3.new(
            math.random(-1, 1),
            math.random(10, 15), -- Dropping from height
            math.random(-1, 1)
        )

        fuelHandle.CFrame = CFrame.new(dropPos)
        
        -- Apply downward force for consistency
        local velocity = Vector3.new(0, -20, 0)
        fuelHandle.Velocity = velocity
        if fuelHandle:FindFirstChild("AssemblyLinearVelocity") then
            fuelHandle.AssemblyLinearVelocity = velocity
        end
    end)

    return success
end

function AutoFuel.autoFuelLoop()
    if not AutoFuel.autoFuelEnabled then return end
    if AutoFuel.isFueling then return end

    local currentTime = tick()
    if currentTime - AutoFuel.lastFuelTime < AutoFuel.fuelDelay then
        return
    end
    
    AutoFuel.isFueling = true

    local fuelItems = AutoFuel.updateFuelCache()
    
    if #fuelItems > 0 then
        local batchSize = 3
        local processed = 0
        
        for i = 1, #fuelItems do
            if processed >= batchSize then break end
            
            local fuelItem = fuelItems[i]
            if fuelItem and fuelItem.Parent then
                if AutoFuel.deliverItem(fuelItem) then
                    processed = processed + 1
                    task.wait(0.1)
                end
            end
        end
        AutoFuel.lastFuelTime = tick()
    end
    
    AutoFuel.isFueling = false
end

function AutoFuel.setEnabled(enabled)
    AutoFuel.autoFuelEnabled = enabled
    
    if enabled then
        if AutoFuel.fuelConnection then AutoFuel.fuelConnection:Disconnect() end
        AutoFuel.fuelConnection = RunService.Heartbeat:Connect(AutoFuel.autoFuelLoop)
    else
        if AutoFuel.fuelConnection then
            AutoFuel.fuelConnection:Disconnect()
            AutoFuel.fuelConnection = nil
        end
    end
end

function AutoFuel.getStatus()
    if AutoFuel.autoFuelEnabled then
        local fuelItems = AutoFuel.cachedFuel
        local targetPart = AutoFuel.getMainFireTarget()
        
        if not targetPart then
            return "Status: MainFire Center not found!", 0
        elseif #fuelItems > 0 then
            local playerPos = AutoFuel.getPlayerPosition()
            local distance = playerPos and AutoFuel.getDistance(playerPos, targetPart.Position) or 0
            
            return string.format("Status: Refueling MainFire (%d items cached)", #fuelItems), distance
        else
            return "Status: No fuel items found", 0
        end
    else
        return "Status: Auto fuel disabled", 0
    end
end

return AutoFuel