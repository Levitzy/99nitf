local TreeChopper = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

TreeChopper.autoChopEnabled = false
TreeChopper.maxDistance = 50
TreeChopper.chopDelay = 1
TreeChopper.chopConnection = nil
TreeChopper.lastChopTime = 0

function TreeChopper.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function TreeChopper.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function TreeChopper.findTreesInRange()
    local playerPos = TreeChopper.getPlayerPosition()
    if not playerPos then return {} end
    
    local workspace = game:GetService("Workspace")
    local mapFolder = workspace:WaitForChild("Map")
    local foliageFolder = mapFolder:WaitForChild("Foliage")
    local landmarksFolder = mapFolder:WaitForChild("Landmarks")
    
    local treesInRange = {}
    
    local function scanFolder(folder)
        for _, tree in pairs(folder:GetChildren()) do
            if tree.Name == "Small Tree" and tree:FindFirstChild("Trunk") then
                local treePos = tree.Trunk.Position
                local distance = TreeChopper.getDistance(playerPos, treePos)
                
                if distance <= TreeChopper.maxDistance then
                    table.insert(treesInRange, {tree = tree, distance = distance})
                end
            end
        end
    end
    
    scanFolder(foliageFolder)
    scanFolder(landmarksFolder)
    
    table.sort(treesInRange, function(a, b)
        return a.distance < b.distance
    end)
    
    return treesInRange
end

function TreeChopper.hasOldAxe()
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if inventory then
        return inventory:FindFirstChild("Old Axe") ~= nil
    end
    return false
end

function TreeChopper.chopTree(tree)
    if not TreeChopper.hasOldAxe() then
        return false
    end
    
    local inventory = LocalPlayer:WaitForChild("Inventory")
    local oldAxe = inventory:WaitForChild("Old Axe")
    
    local playerPos = TreeChopper.getPlayerPosition()
    if not playerPos then return false end
    
    local treePos = tree.Trunk.Position
    local lookDirection = (treePos - playerPos).Unit
    local cframe = CFrame.lookAt(playerPos, treePos)
    
    for i = 1, 5 do
        local args = {
            tree,
            oldAxe,
            "28_9083712192",
            cframe
        }
        
        local success, result = pcall(function()
            return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(unpack(args))
        end)
        
        if not success then
            wait(0.05)
        else
            wait(0.02)
        end
    end
    
    return true
end

function TreeChopper.chopMultipleTrees(treesData)
    if not TreeChopper.hasOldAxe() then
        return false
    end
    
    local currentTime = tick()
    if currentTime - TreeChopper.lastChopTime < TreeChopper.chopDelay then
        return false
    end
    
    local choppedCount = 0
    
    for _, treeData in pairs(treesData) do
        if treeData.tree and treeData.tree.Parent then
            TreeChopper.chopTree(treeData.tree)
            choppedCount = choppedCount + 1
            wait(0.1)
        end
    end
    
    TreeChopper.lastChopTime = currentTime
    return choppedCount > 0
end

function TreeChopper.autoChopLoop()
    if not TreeChopper.autoChopEnabled then return end
    
    local treesInRange = TreeChopper.findTreesInRange()
    
    if #treesInRange > 0 then
        local success = TreeChopper.chopMultipleTrees(treesInRange)
    end
end

function TreeChopper.setEnabled(enabled)
    TreeChopper.autoChopEnabled = enabled
    
    if enabled then
        TreeChopper.chopConnection = RunService.Heartbeat:Connect(TreeChopper.autoChopLoop)
    else
        if TreeChopper.chopConnection then
            TreeChopper.chopConnection:Disconnect()
            TreeChopper.chopConnection = nil
        end
    end
end

function TreeChopper.setMaxDistance(distance)
    TreeChopper.maxDistance = distance
end

function TreeChopper.setChopDelay(delay)
    TreeChopper.chopDelay = delay
end

function TreeChopper.getStatus()
    if TreeChopper.autoChopEnabled then
        local treesInRange = TreeChopper.findTreesInRange()
        local hasAxe = TreeChopper.hasOldAxe()
        
        if not hasAxe then
            return "Status: No Old Axe found!", 0, 0
        elseif #treesInRange > 0 then
            local closestDistance = treesInRange[1].distance
            return string.format("Status: Chopping %d trees (closest: %.1f studs) - Delay: %.1fs", #treesInRange, closestDistance, TreeChopper.chopDelay), #treesInRange, closestDistance
        else
            return "Status: No trees in range", 0, 0
        end
    else
        return "Status: Auto chop disabled", 0, 0
    end
end

return TreeChopper