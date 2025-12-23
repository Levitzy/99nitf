local AutoPlant = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoPlant.autoPlantEnabled = false
AutoPlant.plantDelay = 0.5
AutoPlant.scanInterval = 2.0 -- Scan every 2 seconds
AutoPlant.plantConnection = nil
AutoPlant.lastPlantTime = 0
AutoPlant.lastScanTime = 0
AutoPlant.isPlanting = false
AutoPlant.cachedSaplings = {}

function AutoPlant.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function AutoPlant.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function AutoPlant.updateSaplingCache()
    local currentTime = tick()
    if currentTime - AutoPlant.lastScanTime < AutoPlant.scanInterval then
        return AutoPlant.cachedSaplings
    end

    local workspace = game:GetService("Workspace")
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if not itemsFolder then 
        AutoPlant.cachedSaplings = {}
        return {} 
    end
    
    local allSaplings = {}
    local playerPos = AutoPlant.getPlayerPosition()
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item and item.Parent and item.Name == "Sapling" then
            local saplingPos = nil
            
            if item:FindFirstChild("Handle") then
                saplingPos = item.Handle.Position
            elseif item:FindFirstChildOfClass("Part") then
                saplingPos = item:FindFirstChildOfClass("Part").Position
            elseif item:FindFirstChildOfClass("MeshPart") then
                saplingPos = item:FindFirstChildOfClass("MeshPart").Position
            elseif item.PrimaryPart then
                saplingPos = item.PrimaryPart.Position
            end
            
            if saplingPos then
                local distance = 0
                if playerPos then
                    local success, result = pcall(function()
                        return AutoPlant.getDistance(playerPos, saplingPos)
                    end)
                    if success then
                        distance = result
                    end
                end
                
                table.insert(allSaplings, {
                    sapling = item,
                    position = saplingPos,
                    distance = distance
                })
            end
        end
    end
    
    table.sort(allSaplings, function(a, b)
        return a.distance < b.distance
    end)
    
    AutoPlant.cachedSaplings = allSaplings
    AutoPlant.lastScanTime = currentTime
    return allSaplings
end

function AutoPlant.findAllSaplings()
    return AutoPlant.updateSaplingCache()
end

function AutoPlant.plantSapling(sapling, plantPosition)
    if not sapling or not sapling.Parent then
        return false
    end
    
    local success = pcall(function()
        local args = {
            sapling,
            plantPosition
        }
        
        ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestPlantItem"):InvokeServer(unpack(args))
    end)
    
    return success
end

function AutoPlant.plantAllSaplings(saplingsData)
    local currentTime = tick()
    if currentTime - AutoPlant.lastPlantTime < AutoPlant.plantDelay then
        return false
    end
    
    -- Limit concurrency (optional, but good practice)
    local plantedCount = 0
    local maxPlants = 5 
    
    for _, saplingData in pairs(saplingsData) do
        if plantedCount >= maxPlants then break end
        
        if saplingData.sapling and saplingData.sapling.Parent then
            task.spawn(function()
                local plantPosition = saplingData.position
                local success = AutoPlant.plantSapling(saplingData.sapling, plantPosition)
            end)
            plantedCount = plantedCount + 1
            task.wait(0.05)
        end
    end
    
    AutoPlant.lastPlantTime = currentTime
    return true
end

function AutoPlant.autoPlantLoop()
    if not AutoPlant.autoPlantEnabled then return end
    
    if AutoPlant.isPlanting then return end
    
    local currentTime = tick()
    if currentTime - AutoPlant.lastPlantTime < AutoPlant.plantDelay then
        return
    end
    
    AutoPlant.isPlanting = true
    
    local allSaplings = AutoPlant.updateSaplingCache()
    
    if #allSaplings > 0 then
        AutoPlant.plantAllSaplings(allSaplings)
    end
    
    AutoPlant.isPlanting = false
end

function AutoPlant.setEnabled(enabled)
    AutoPlant.autoPlantEnabled = enabled
    
    if enabled then
        if AutoPlant.plantConnection then AutoPlant.plantConnection:Disconnect() end
        AutoPlant.plantConnection = RunService.Heartbeat:Connect(AutoPlant.autoPlantLoop)
    else
        if AutoPlant.plantConnection then
            AutoPlant.plantConnection:Disconnect()
            AutoPlant.plantConnection = nil
        end
    end
end

function AutoPlant.setPlantDelay(delay)
    AutoPlant.plantDelay = delay
end

function AutoPlant.getStatus()
    if AutoPlant.autoPlantEnabled then
        local allSaplings = AutoPlant.cachedSaplings
        
         if #allSaplings == 0 and (tick() - AutoPlant.lastScanTime > AutoPlant.scanInterval) then
            allSaplings = AutoPlant.updateSaplingCache()
        end
        
        if #allSaplings > 0 then
            local closestDistance = allSaplings[1] and allSaplings[1].distance or 0
            
            return string.format("Status: Planting %d saplings (Batch 5)...", 
                   #allSaplings), #allSaplings, closestDistance
        else
            return "Status: No saplings found", 0, 0
        end
    else
        return "Status: Auto plant disabled", 0, 0
    end
end

return AutoPlant