local AutoFlower = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoFlower.autoFlowerEnabled = false
AutoFlower.flowerDelay = 0.5
AutoFlower.flowerConnection = nil
AutoFlower.lastFlowerTime = 0

function AutoFlower.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function AutoFlower.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function AutoFlower.findAllFlowers()
    local workspace = game:GetService("Workspace")
    local mapFolder = workspace:FindFirstChild("Map")
    if not mapFolder then return {} end
    
    local landmarksFolder = mapFolder:FindFirstChild("Landmarks")
    if not landmarksFolder then return {} end
    
    local allFlowers = {}
    local playerPos = AutoFlower.getPlayerPosition()
    
    for _, item in pairs(landmarksFolder:GetChildren()) do
        if item and item.Parent and item.Name == "Flower" then
            local flowerPos = nil
            
            if item:FindFirstChild("Handle") then
                flowerPos = item.Handle.Position
            elseif item:FindFirstChildOfClass("Part") then
                flowerPos = item:FindFirstChildOfClass("Part").Position
            elseif item:FindFirstChildOfClass("MeshPart") then
                flowerPos = item:FindFirstChildOfClass("MeshPart").Position
            elseif item.PrimaryPart then
                flowerPos = item.PrimaryPart.Position
            end
            
            if flowerPos then
                local distance = 0
                if playerPos then
                    local success, result = pcall(function()
                        return AutoFlower.getDistance(playerPos, flowerPos)
                    end)
                    if success then
                        distance = result
                    end
                end
                
                table.insert(allFlowers, {
                    flower = item,
                    position = flowerPos,
                    distance = distance
                })
            end
        end
    end
    
    table.sort(allFlowers, function(a, b)
        return a.distance < b.distance
    end)
    
    return allFlowers
end

function AutoFlower.pickFlower(flower)
    if not flower or not flower.Parent then
        return false
    end
    
    local success = pcall(function()
        local args = {
            flower
        }
        
        ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestPickFlower"):InvokeServer(unpack(args))
    end)
    
    return success
end

function AutoFlower.pickAllFlowers(flowersData)
    local currentTime = tick()
    if currentTime - AutoFlower.lastFlowerTime < AutoFlower.flowerDelay then
        return false
    end
    
    local pickedCount = 0
    
    for _, flowerData in pairs(flowersData) do
        if flowerData.flower and flowerData.flower.Parent then
            spawn(function()
                local success = AutoFlower.pickFlower(flowerData.flower)
                if success then
                    pickedCount = pickedCount + 1
                end
            end)
            wait(0.1)
        end
    end
    
    AutoFlower.lastFlowerTime = currentTime
    return true
end

function AutoFlower.autoFlowerLoop()
    if not AutoFlower.autoFlowerEnabled then return end
    
    local allFlowers = AutoFlower.findAllFlowers()
    
    if #allFlowers > 0 then
        AutoFlower.pickAllFlowers(allFlowers)
    end
end

function AutoFlower.setEnabled(enabled)
    AutoFlower.autoFlowerEnabled = enabled
    
    if enabled then
        AutoFlower.flowerConnection = RunService.Heartbeat:Connect(AutoFlower.autoFlowerLoop)
    else
        if AutoFlower.flowerConnection then
            AutoFlower.flowerConnection:Disconnect()
            AutoFlower.flowerConnection = nil
        end
    end
end

function AutoFlower.setFlowerDelay(delay)
    AutoFlower.flowerDelay = delay
end

function AutoFlower.getStatus()
    if AutoFlower.autoFlowerEnabled then
        local allFlowers = AutoFlower.findAllFlowers()
        
        if #allFlowers > 0 then
            local closestDistance = allFlowers[1] and allFlowers[1].distance or 0
            
            return string.format("Status: Picking %d flowers from landmarks!", 
                   #allFlowers), #allFlowers, closestDistance
        else
            return "Status: No flowers found", 0, 0
        end
    else
        return "Status: Auto flower disabled", 0, 0
    end
end

return AutoFlower