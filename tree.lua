local TreeChopper = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

TreeChopper.autoChopEnabled = false
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

function TreeChopper.findAllSmallTrees()
    local workspace = game:GetService("Workspace")
    local mapFolder = workspace:WaitForChild("Map")
    local foliageFolder = mapFolder:WaitForChild("Foliage")
    local landmarksFolder = mapFolder:WaitForChild("Landmarks")
    
    local allTrees = {}
    local playerPos = TreeChopper.getPlayerPosition()
    
    local function scanFolder(folder, folderName)
        for _, tree in pairs(folder:GetChildren()) do
            if tree.Name == "Small Tree" and tree:FindFirstChild("Trunk") then
                local distance = 0
                if playerPos then
                    distance = TreeChopper.getDistance(playerPos, tree.Trunk.Position)
                end
                table.insert(allTrees, {
                    tree = tree, 
                    distance = distance,
                    folder = folderName
                })
            end
        end
    end
    
    scanFolder(foliageFolder, "Foliage")
    scanFolder(landmarksFolder, "Landmarks")
    
    table.sort(allTrees, function(a, b)
        return a.distance < b.distance
    end)
    
    return allTrees
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

function TreeChopper.chopBatchTrees(treesData)
    if not TreeChopper.hasOldAxe() then
        return false
    end
    
    local currentTime = tick()
    if currentTime - TreeChopper.lastChopTime < TreeChopper.chopDelay then
        return false
    end
    
    local choppedCount = 0
    local maxBatch = math.min(3, #treesData)
    
    for i = 1, maxBatch do
        local treeData = treesData[i]
        if treeData.tree and treeData.tree.Parent then
            local success = TreeChopper.chopTree(treeData.tree)
            if success then
                choppedCount = choppedCount + 1
            end
            wait(0.1)
        end
    end
    
    TreeChopper.lastChopTime = currentTime
    return choppedCount > 0
end

function TreeChopper.autoChopLoop()
    if not TreeChopper.autoChopEnabled then return end
    
    local allTrees = TreeChopper.findAllSmallTrees()
    
    if #allTrees > 0 then
        TreeChopper.chopBatchTrees(allTrees)
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

function TreeChopper.setChopDelay(delay)
    TreeChopper.chopDelay = delay
end

function TreeChopper.getStatus()
    if TreeChopper.autoChopEnabled then
        local allTrees = TreeChopper.findAllSmallTrees()
        local hasAxe = TreeChopper.hasOldAxe()
        
        if not hasAxe then
            return "Status: No Old Axe found!", 0, 0
        elseif #allTrees > 0 then
            local foliageCount = 0
            local landmarkCount = 0
            local closestDistance = allTrees[1] and allTrees[1].distance or 0
            
            for _, treeData in pairs(allTrees) do
                if treeData.folder == "Foliage" then
                    foliageCount = foliageCount + 1
                elseif treeData.folder == "Landmarks" then
                    landmarkCount = landmarkCount + 1
                end
            end
            
            return string.format("Status: Processing %d trees (F:%d L:%d) - Batch: 3/cycle - Delay: %.1fs", 
                   #allTrees, foliageCount, landmarkCount, TreeChopper.chopDelay), #allTrees, closestDistance
        else
            return "Status: No small trees found", 0, 0
        end
    else
        return "Status: Auto chop disabled", 0, 0
    end
end

return TreeChopper