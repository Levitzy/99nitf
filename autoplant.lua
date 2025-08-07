local AutoPlant = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoPlant.autoPlantEnabled = false
AutoPlant.plantDelay = 0.5
AutoPlant.plantConnection = nil
AutoPlant.lastPlantTime = 0

function AutoPlant.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function AutoPlant.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function AutoPlant.findAllSaplings()
    local workspace = game:GetService("Workspace")
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if not itemsFolder then return {} end
    
    local allSaplings = {}
    local playerPos = AutoPlant.getPlayerPosition()
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item and item.Parent and item.Name == "Sapling" then
            local saplingPos = nil
            
            local handle = item:FindFirstChild("Handle") or item:FindFirstChildOfClass("Part") or item:FindFirstChildOfClass("MeshPart")
            if handle and handle.Parent then
                saplingPos = handle.Position
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
    
    return allSaplings
end

function AutoPlant.plantSapling(sapling, plantPosition)
    if not sapling or not sapling.Parent then
        return false
    end
    
    local success = pcall(function()
        local args = {
            Instance.new("Model", nil),
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
    
    local plantedCount = 0
    
    for _, saplingData in pairs(saplingsData) do
        if saplingData.sapling and saplingData.sapling.Parent then
            spawn(function()
                local plantPosition = saplingData.position
                local success = AutoPlant.plantSapling(saplingData.sapling, plantPosition)
                if success then
                    plantedCount = plantedCount + 1
                end
            end)
            wait(0.1)
        end
    end
    
    AutoPlant.lastPlantTime = currentTime
    return true
end

function AutoPlant.autoPlantLoop()
    if not AutoPlant.autoPlantEnabled then return end
    
    local allSaplings = AutoPlant.findAllSaplings()
    
    if #allSaplings == 0 then
        return
    end
    
    if #allSaplings > 0 then
        AutoPlant.plantAllSaplings(allSaplings)
    end
end

function AutoPlant.setEnabled(enabled)
    AutoPlant.autoPlantEnabled = enabled
    
    if enabled then
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
        local allSaplings = AutoPlant.findAllSaplings()
        
        if #allSaplings > 0 then
            local closestDistance = allSaplings[1] and allSaplings[1].distance or 0
            
            return string.format("Status: Planting %d saplings at their locations!", 
                   #allSaplings), #allSaplings, closestDistance
        else
            return "Status: No saplings found", 0, 0
        end
    else
        return "Status: Auto plant disabled", 0, 0
    end
end

return AutoPlant