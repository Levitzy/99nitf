local TreeChopper = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

TreeChopper.autoChopEnabled = false
TreeChopper.chopDelay = 0.5
TreeChopper.chopConnection = nil
TreeChopper.lastChopTime = 0
TreeChopper.batchSize = 10
TreeChopper.processedTrees = {}

function TreeChopper.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function TreeChopper.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function TreeChopper.findAllTrees()
    local workspace = game:GetService("Workspace")
    local mapFolder = workspace:FindFirstChild("Map")
    if not mapFolder then return {} end
    
    local foliageFolder = mapFolder:FindFirstChild("Foliage")
    local landmarksFolder = mapFolder:FindFirstChild("Landmarks")
    
    local allTrees = {}
    local playerPos = TreeChopper.getPlayerPosition()
    
    local function scanFolder(folder, folderName)
        if not folder then return end
        
        for _, tree in pairs(folder:GetChildren()) do
            if tree.Name == "Small Tree" and tree:FindFirstChild("Trunk") and tree.Parent then
                local treeId = tostring(tree)
                
                if not TreeChopper.processedTrees[treeId] then
                    local treePos = tree.Trunk.Position
                    local distance = playerPos and TreeChopper.getDistance(playerPos, treePos) or 0
                    
                    table.insert(allTrees, {
                        tree = tree,
                        distance = distance,
                        folder = folderName,
                        id = treeId
                    })
                end
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
    local character = LocalPlayer.Character
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool and tool.Name == "Old Axe" then
            return tool
        end
    end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local axe = backpack:FindFirstChild("Old Axe")
        if axe then
            return axe
        end
    end
    
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if inventory then
        return inventory:FindFirstChild("Old Axe")
    end
    
    return nil
end

function TreeChopper.equipAxe()
    local axe = TreeChopper.hasOldAxe()
    if not axe then return false end
    
    if axe.Parent == LocalPlayer.Backpack then
        axe.Parent = LocalPlayer.Character
        wait(0.1)
    end
    
    return true
end

function TreeChopper.chopTree(treeData)
    local axe = TreeChopper.hasOldAxe()
    if not axe then
        return false
    end
    
    local tree = treeData.tree
    if not tree or not tree.Parent or not tree:FindFirstChild("Trunk") then
        TreeChopper.processedTrees[treeData.id] = true
        return false
    end
    
    local playerPos = TreeChopper.getPlayerPosition()
    if not playerPos then return false end
    
    TreeChopper.equipAxe()
    
    local treePos = tree.Trunk.Position
    local lookDirection = (treePos - playerPos).Unit
    local cframe = CFrame.lookAt(playerPos, treePos)
    
    local success = false
    for attempt = 1, 8 do
        local args = {
            tree,
            axe,
            "28_9083712192",
            cframe
        }
        
        local chopSuccess, result = pcall(function()
            return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(unpack(args))
        end)
        
        if chopSuccess then
            success = true
            wait(0.05)
        else
            wait(0.02)
        end
        
        if not tree.Parent then
            TreeChopper.processedTrees[treeData.id] = true
            break
        end
    end
    
    return success
end

function TreeChopper.chopTreeBatch(treesData)
    if not TreeChopper.hasOldAxe() then
        return 0
    end
    
    local currentTime = tick()
    if currentTime - TreeChopper.lastChopTime < TreeChopper.chopDelay then
        return 0
    end
    
    local choppedCount = 0
    local batchLimit = math.min(#treesData, TreeChopper.batchSize)
    
    for i = 1, batchLimit do
        local treeData = treesData[i]
        if treeData and treeData.tree and treeData.tree.Parent then
            if TreeChopper.chopTree(treeData) then
                choppedCount = choppedCount + 1
            end
            wait(0.08)
        end
    end
    
    TreeChopper.lastChopTime = currentTime
    return choppedCount
end

function TreeChopper.cleanupProcessedTrees()
    for treeId, _ in pairs(TreeChopper.processedTrees) do
        local stillExists = false
        
        local workspace = game:GetService("Workspace")
        local mapFolder = workspace:FindFirstChild("Map")
        if mapFolder then
            local foliageFolder = mapFolder:FindFirstChild("Foliage")
            local landmarksFolder = mapFolder:FindFirstChild("Landmarks")
            
            local function checkFolder(folder)
                if not folder then return end
                for _, tree in pairs(folder:GetChildren()) do
                    if tostring(tree) == treeId and tree.Parent then
                        stillExists = true
                        return
                    end
                end
            end
            
            checkFolder(foliageFolder)
            if not stillExists then
                checkFolder(landmarksFolder)
            end
        end
        
        if not stillExists then
            TreeChopper.processedTrees[treeId] = nil
        end
    end
end

function TreeChopper.autoChopLoop()
    if not TreeChopper.autoChopEnabled then return end
    
    if math.random(1, 100) <= 5 then
        TreeChopper.cleanupProcessedTrees()
    end
    
    local allTrees = TreeChopper.findAllTrees()
    
    if #allTrees > 0 then
        TreeChopper.chopTreeBatch(allTrees)
    end
end

function TreeChopper.setEnabled(enabled)
    TreeChopper.autoChopEnabled = enabled
    
    if enabled then
        TreeChopper.processedTrees = {}
        TreeChopper.chopConnection = RunService.Heartbeat:Connect(TreeChopper.autoChopLoop)
    else
        if TreeChopper.chopConnection then
            TreeChopper.chopConnection:Disconnect()
            TreeChopper.chopConnection = nil
        end
    end
end

function TreeChopper.setMaxDistance(distance)
end

function TreeChopper.setChopDelay(delay)
    TreeChopper.chopDelay = math.max(delay, 0.1)
end

function TreeChopper.setBatchSize(size)
    TreeChopper.batchSize = math.max(size, 1)
end

function TreeChopper.getStatus()
    if TreeChopper.autoChopEnabled then
        local allTrees = TreeChopper.findAllTrees()
        local hasAxe = TreeChopper.hasOldAxe()
        local processedCount = 0
        for _ in pairs(TreeChopper.processedTrees) do
            processedCount = processedCount + 1
        end
        
        if not hasAxe then
            return "Status: No Old Axe found!", 0, 0
        elseif #allTrees > 0 then
            local foliageCount = 0
            local landmarkCount = 0
            
            for _, treeData in pairs(allTrees) do
                if treeData.folder == "Foliage" then
                    foliageCount = foliageCount + 1
                else
                    landmarkCount = landmarkCount + 1
                end
            end
            
            return string.format("Status: Found %d trees (F:%d L:%d) - Processed:%d - Delay:%.1fs", 
                   #allTrees, foliageCount, landmarkCount, processedCount, TreeChopper.chopDelay), #allTrees, 0
        else
            return string.format("Status: No trees available - Processed:%d trees", processedCount), 0, 0
        end
    else
        return "Status: Auto chop disabled", 0, 0
    end
end

return TreeChopper