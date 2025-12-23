local TreeChopper = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

TreeChopper.autoChopEnabled = false
TreeChopper.chopDelay = 0.5 -- Increased delay to reduce lag
TreeChopper.scanInterval = 2.0 -- Only scan for trees every 2 seconds
TreeChopper.chopConnection = nil
TreeChopper.lastChopTime = 0
TreeChopper.lastScanTime = 0
TreeChopper.isChopping = false
TreeChopper.cachedTrees = {}
TreeChopper.maxChopsPerBatch = 3 -- Limit concurrent chops

function TreeChopper.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function TreeChopper.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

TreeChopper.targetNames = {
    ["Small Tree"] = true,
    ["Snowy Small Tree"] = true,
    ["TreeBig1"] = true
}

function TreeChopper.setTargetNames(names)
    TreeChopper.targetNames = {}
    for _, name in pairs(names) do
        TreeChopper.targetNames[name] = true
    end
end

function TreeChopper.updateTreeCache()
    local currentTime = tick()
    -- Return cached result if within interval
    if currentTime - TreeChopper.lastScanTime < TreeChopper.scanInterval then
        return TreeChopper.cachedTrees
    end

    local workspace = game:GetService("Workspace")
    local mapFolder = workspace:FindFirstChild("Map")
    if not mapFolder then 
        TreeChopper.cachedTrees = {}
        return {} 
    end
    
    local foliageFolder = mapFolder:FindFirstChild("Foliage")
    local landmarksFolder = mapFolder:FindFirstChild("Landmarks")
    
    local allTrees = {}
    local playerPos = TreeChopper.getPlayerPosition()
    
    local function scanFolder(folder, folderName)
        if not folder then return end
        
        for _, tree in pairs(folder:GetChildren()) do
            if tree and tree.Parent and TreeChopper.targetNames[tree.Name] then
                local trunk = tree:FindFirstChild("Trunk")
                if trunk and trunk.Parent then
                    local distance = 0
                    if playerPos then
                        local success, result = pcall(function()
                            return TreeChopper.getDistance(playerPos, trunk.Position)
                        end)
                        if success then
                            distance = result
                        end
                    end
                    table.insert(allTrees, {
                        tree = tree, 
                        distance = distance,
                        folder = folderName
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
    
    TreeChopper.cachedTrees = allTrees
    TreeChopper.lastScanTime = currentTime
    return allTrees
end

function TreeChopper.findTrees()
    return TreeChopper.updateTreeCache()
end

function TreeChopper.hasOldAxe()
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if inventory then
        return inventory:FindFirstChild("Old Axe") ~= nil
    end
    return false
end

function TreeChopper.chopTree(tree)
    if not tree or not tree.Parent then return false end
    
    local trunk = tree:FindFirstChild("Trunk")
    if not trunk or not trunk.Parent then return false end
    
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    local oldAxe = inventory and inventory:FindFirstChild("Old Axe")
    if not oldAxe then return false end
    
    local playerPos = TreeChopper.getPlayerPosition()
    if not playerPos then return false end
    
    local success, cframe = pcall(function()
        return CFrame.lookAt(playerPos, trunk.Position)
    end)
    
    if not success then return false end
    
    -- Reduced hit count slightly to avoid rate limits
    for i = 1, 5 do
        if not tree.Parent or not trunk.Parent then break end
        
        local args = {
            tree,
            oldAxe,
            "28_9083712192",
            cframe
        }
        
        local chopSuccess = pcall(function()
            return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(unpack(args))
        end)
        
        if not chopSuccess then
            task.wait(0.05)
        else
            task.wait(0.01)
        end
    end
    
    return true
end

function TreeChopper.chopTargetTrees(treesData)
    if not TreeChopper.hasOldAxe() then return false end
    
    local currentTime = tick()
    if currentTime - TreeChopper.lastChopTime < TreeChopper.chopDelay then return false end
    
    local choppedCount = 0
    
    for _, treeData in pairs(treesData) do
        -- Limit concurrent chops to prevent lag
        if choppedCount >= TreeChopper.maxChopsPerBatch then break end
        
        if treeData.tree and treeData.tree.Parent then
            task.spawn(function()
                TreeChopper.chopTree(treeData.tree)
            end)
            choppedCount = choppedCount + 1
        end
    end
    
    TreeChopper.lastChopTime = currentTime
    return true
end

function TreeChopper.autoChopLoop()
    if not TreeChopper.autoChopEnabled then return end
    
    if TreeChopper.isChopping then return end
    
    local currentTime = tick()
    if currentTime - TreeChopper.lastChopTime < TreeChopper.chopDelay then
        return
    end
    
    TreeChopper.isChopping = true
    
    -- Use cached trees efficiently
    local allTrees = TreeChopper.updateTreeCache()
    
    if #allTrees > 0 then
        TreeChopper.chopTargetTrees(allTrees)
    end
    
    TreeChopper.isChopping = false
end

function TreeChopper.setEnabled(enabled)
    TreeChopper.autoChopEnabled = enabled
    
    if enabled then
        if TreeChopper.chopConnection then TreeChopper.chopConnection:Disconnect() end
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
        -- Use cache for status display to avoid lag
        local allTrees = TreeChopper.cachedTrees
        
        -- Refresh if stale (backup check)
        if #allTrees == 0 and (tick() - TreeChopper.lastScanTime > TreeChopper.scanInterval) then
            allTrees = TreeChopper.updateTreeCache()
        end
        
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
            
            return string.format("Status: Batch Chopping %d trees (Batch:%d)", 
                   #allTrees, TreeChopper.maxChopsPerBatch), #allTrees, closestDistance
        else
            return "Status: No trees found.", 0, 0
        end
    else
        return "Status: Auto chop disabled", 0, 0
    end
end

return TreeChopper