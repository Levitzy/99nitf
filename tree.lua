local TreeChopper = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

TreeChopper.autoChopEnabled = false
TreeChopper.chopDelay = 0.1
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
    
    local mapFolder = workspace:FindFirstChild("Map")
    if not mapFolder then return {} end
    
    local foliageFolder = mapFolder:FindFirstChild("Foliage")
    local landmarksFolder = mapFolder:FindFirstChild("Landmarks")
    
    local allTrees = {}
    local playerPos = TreeChopper.getPlayerPosition()
    
    local function scanFolder(folder, folderName)
        if not folder then return end
        
        for _, tree in pairs(folder:GetChildren()) do
            if tree and tree.Parent and tree.Name == "Small Tree" then
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
    
    if not tree or not tree.Parent then
        return false
    end
    
    local trunk = tree:FindFirstChild("Trunk")
    if not trunk or not trunk.Parent then
        return false
    end
    
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if not inventory then return false end
    
    local oldAxe = inventory:FindFirstChild("Old Axe")
    if not oldAxe then return false end
    
    local playerPos = TreeChopper.getPlayerPosition()
    if not playerPos then return false end
    
    local success, cframe = pcall(function()
        local treePos = trunk.Position
        local lookDirection = (treePos - playerPos).Unit
        return CFrame.lookAt(playerPos, treePos)
    end)
    
    if not success then return false end
    
    for i = 1, 8 do
        if not tree or not tree.Parent or not trunk or not trunk.Parent then
            break
        end
        
        local args = {
            tree,
            oldAxe,
            "28_9083712192",
            cframe
        }
        
        local chopSuccess, result = pcall(function()
            return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(unpack(args))
        end)
        
        if not chopSuccess then
            wait(0.01)
        else
            wait(0.005)
        end
    end
    
    return true
end

function TreeChopper.chopAllTrees(treesData)
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
            spawn(function()
                local success = TreeChopper.chopTree(treeData.tree)
                if success then
                    choppedCount = choppedCount + 1
                end
            end)
        end
    end
    
    TreeChopper.lastChopTime = currentTime
    return true
end

function TreeChopper.autoChopLoop()
    if not TreeChopper.autoChopEnabled then return end
    
    local allTrees = TreeChopper.findAllSmallTrees()
    
    if #allTrees == 0 then
        TreeChopper.setEnabled(false)
        return
    end
    
    if #allTrees > 0 then
        TreeChopper.chopAllTrees(allTrees)
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
            
            return string.format("Status: Chopping ALL %d trees (F:%d L:%d) - Fast Mode 0.1s!", 
                   #allTrees, foliageCount, landmarkCount), #allTrees, closestDistance
        else
            return "Status: All trees chopped! Auto-stopped.", 0, 0
        end
    else
        return "Status: Auto chop disabled", 0, 0
    end
end

return TreeChopper