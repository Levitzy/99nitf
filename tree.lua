local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local TreeAura = {}

local enabled = false
local treeDistance = 86
local choppingDelay = 0.1
local connection
local farmLandmarks = true
local farmFoliage = true
local prioritizeClosest = true

local function getPlayerCharacter()
    return LocalPlayer.Character
end

local function getPlayerPosition()
    local character = getPlayerCharacter()
    if character and character:FindFirstChild("HumanoidRootPart") then
        return character.HumanoidRootPart.Position
    end
    return nil
end

local function getPlayerInventoryTool()
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if inventory then
        return inventory:FindFirstChild("Old Axe") or 
               inventory:FindFirstChild("Axe") or
               inventory:FindFirstChild("Iron Axe") or
               inventory:FindFirstChild("Steel Axe") or
               inventory:FindFirstChild("Stone Axe")
    end
    return nil
end

local function isValidTree(tree)
    if not tree or not tree:IsA("Model") then
        return false
    end
    
    local name = tree.Name:lower()
    if name:find("tree") or name:find("oak") or name:find("pine") or name:find("birch") then
        return tree:FindFirstChild("Trunk") or tree:FindFirstChild("PrimaryPart") or tree:FindFirstChild("Wood")
    end
    
    return false
end

local function getTreeTrunk(tree)
    return tree:FindFirstChild("Trunk") or 
           tree:FindFirstChild("PrimaryPart") or 
           tree:FindFirstChild("Wood") or
           tree:FindFirstChild("Base")
end

local function findTreesInFoliage()
    local playerPos = getPlayerPosition()
    if not playerPos then
        return {}
    end
    
    local treesInRange = {}
    
    local foliageFolder = workspace:FindFirstChild("Map")
    if foliageFolder then
        foliageFolder = foliageFolder:FindFirstChild("Foliage")
        if foliageFolder then
            for _, tree in pairs(foliageFolder:GetChildren()) do
                if isValidTree(tree) then
                    local trunk = getTreeTrunk(tree)
                    if trunk then
                        local distance = (trunk.Position - playerPos).Magnitude
                        if distance <= treeDistance then
                            table.insert(treesInRange, {
                                tree = tree,
                                trunk = trunk,
                                distance = distance,
                                source = "Foliage"
                            })
                        end
                    end
                end
            end
        end
    end
    
    return treesInRange
end

local function findTreesInLandmarks()
    local playerPos = getPlayerPosition()
    if not playerPos then
        return {}
    end
    
    local treesInRange = {}
    
    local landmarksFolder = workspace:FindFirstChild("Map")
    if landmarksFolder then
        landmarksFolder = landmarksFolder:FindFirstChild("Landmarks")
        if landmarksFolder then
            for _, landmark in pairs(landmarksFolder:GetChildren()) do
                if landmark:IsA("Model") or landmark:IsA("Folder") then
                    for _, tree in pairs(landmark:GetChildren()) do
                        if isValidTree(tree) then
                            local trunk = getTreeTrunk(tree)
                            if trunk then
                                local distance = (trunk.Position - playerPos).Magnitude
                                if distance <= treeDistance then
                                    table.insert(treesInRange, {
                                        tree = tree,
                                        trunk = trunk,
                                        distance = distance,
                                        source = "Landmarks"
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return treesInRange
end

local function findAllTreesInRange()
    local allTrees = {}
    
    if farmFoliage then
        local foliageTrees = findTreesInFoliage()
        for _, treeData in pairs(foliageTrees) do
            table.insert(allTrees, treeData)
        end
    end
    
    if farmLandmarks then
        local landmarkTrees = findTreesInLandmarks()
        for _, treeData in pairs(landmarkTrees) do
            table.insert(allTrees, treeData)
        end
    end
    
    if prioritizeClosest then
        table.sort(allTrees, function(a, b)
            return a.distance < b.distance
        end)
    end
    
    return allTrees
end

local function attackTree(treeData)
    local tool = getPlayerInventoryTool()
    if not tool then
        return false
    end
    
    local tree = treeData.tree
    if not tree or not tree.Parent then
        return false
    end
    
    local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if remoteEvent then
        remoteEvent = remoteEvent:FindFirstChild("ToolDamageObject")
        if remoteEvent then
            local playerCharacter = getPlayerCharacter()
            if playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart") then
                local args = {
                    tree,
                    tool,
                    "1_8592674679",
                    playerCharacter.HumanoidRootPart.CFrame
                }
                
                local success, result = pcall(function()
                    remoteEvent:InvokeServer(unpack(args))
                end)
                
                if success then
                    print("Chopped tree from " .. treeData.source .. " (Distance: " .. math.floor(treeData.distance) .. ")")
                end
                
                return success
            end
        end
    end
    
    return false
end

local function treeAuraLoop()
    if not enabled then
        return
    end
    
    local treesInRange = findAllTreesInRange()
    
    for _, treeData in pairs(treesInRange) do
        if enabled then
            attackTree(treeData)
            wait(choppingDelay)
        else
            break
        end
    end
end

function TreeAura.toggle()
    enabled = not enabled
    
    if enabled then
        local foliageStatus = farmFoliage and "ON" or "OFF"
        local landmarkStatus = farmLandmarks and "ON" or "OFF"
        print("Tree Aura: ON")
        print("  Distance: " .. treeDistance)
        print("  Delay: " .. choppingDelay .. "s")
        print("  Foliage farming: " .. foliageStatus)
        print("  Landmarks farming: " .. landmarkStatus)
        print("  Prioritize closest: " .. (prioritizeClosest and "ON" or "OFF"))
        
        connection = RunService.Heartbeat:Connect(function()
            treeAuraLoop()
        end)
    else
        print("Tree Aura: OFF")
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
    
    return enabled
end

function TreeAura.stop()
    enabled = false
    if connection then
        connection:Disconnect()
        connection = nil
    end
    print("Tree Aura: STOPPED")
end

function TreeAura.isEnabled()
    return enabled
end

function TreeAura.setDistance(distance)
    treeDistance = math.max(10, math.min(500, distance))
    print("Tree Aura distance set to:", treeDistance)
end

function TreeAura.getDistance()
    return treeDistance
end

function TreeAura.setDelay(delay)
    choppingDelay = math.max(0.05, math.min(10, delay))
    print("Tree Aura chopping delay set to:", choppingDelay .. "s")
end

function TreeAura.getDelay()
    return choppingDelay
end

function TreeAura.setFarmLandmarks(enabled)
    farmLandmarks = enabled
    print("Landmarks farming:", enabled and "ENABLED" or "DISABLED")
end

function TreeAura.getFarmLandmarks()
    return farmLandmarks
end

function TreeAura.setFarmFoliage(enabled)
    farmFoliage = enabled
    print("Foliage farming:", enabled and "ENABLED" or "DISABLED")
end

function TreeAura.getFarmFoliage()
    return farmFoliage
end

function TreeAura.setPrioritizeClosest(enabled)
    prioritizeClosest = enabled
    print("Prioritize closest trees:", enabled and "ENABLED" or "DISABLED")
end

function TreeAura.getPrioritizeClosest()
    return prioritizeClosest
end

function TreeAura.getTreeCount()
    local allTrees = findAllTreesInRange()
    local foliageCount = 0
    local landmarkCount = 0
    
    for _, treeData in pairs(allTrees) do
        if treeData.source == "Foliage" then
            foliageCount = foliageCount + 1
        elseif treeData.source == "Landmarks" then
            landmarkCount = landmarkCount + 1
        end
    end
    
    return {
        total = #allTrees,
        foliage = foliageCount,
        landmarks = landmarkCount
    }
end

function TreeAura.getStatus()
    local treeCounts = TreeAura.getTreeCount()
    return {
        enabled = enabled,
        distance = treeDistance,
        delay = choppingDelay,
        hasConnection = connection ~= nil,
        treesFound = treeCounts.total,
        foliageTrees = treeCounts.foliage,
        landmarkTrees = treeCounts.landmarks,
        farmingFoliage = farmFoliage,
        farmingLandmarks = farmLandmarks,
        prioritizeClosest = prioritizeClosest
    }
end

function TreeAura.getAllSettings()
    return {
        distance = treeDistance,
        delay = choppingDelay,
        farmLandmarks = farmLandmarks,
        farmFoliage = farmFoliage,
        prioritizeClosest = prioritizeClosest
    }
end

function TreeAura.loadSettings(settings)
    if settings.distance then TreeAura.setDistance(settings.distance) end
    if settings.delay then TreeAura.setDelay(settings.delay) end
    if settings.farmLandmarks ~= nil then TreeAura.setFarmLandmarks(settings.farmLandmarks) end
    if settings.farmFoliage ~= nil then TreeAura.setFarmFoliage(settings.farmFoliage) end
    if settings.prioritizeClosest ~= nil then TreeAura.setPrioritizeClosest(settings.prioritizeClosest) end
    print("Settings loaded successfully!")
end

return TreeAura
