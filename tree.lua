local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local TreeAura = {}

local enabled = false
local treeDistance = 80
local connection

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
        return inventory:FindFirstChild("Old Axe") or inventory:FindFirstChild("Axe")
    end
    return nil
end

local function findTreesInRange()
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
                if tree:IsA("Model") and tree.Name:find("Tree") and tree:FindFirstChild("Trunk") then
                    local distance = (tree.Trunk.Position - playerPos).Magnitude
                    if distance <= treeDistance then
                        table.insert(treesInRange, tree)
                    end
                end
            end
        end
    end
    
    return treesInRange
end

local function attackTree(tree)
    local tool = getPlayerInventoryTool()
    if not tool then
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
    
    local treesInRange = findTreesInRange()
    
    for _, tree in pairs(treesInRange) do
        if enabled then
            attackTree(tree)
            wait(0.1)
        else
            break
        end
    end
end

function TreeAura.toggle()
    enabled = not enabled
    
    if enabled then
        print("Tree Aura: ON")
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
    treeDistance = distance
    print("Tree Aura distance set to:", distance)
end

function TreeAura.getDistance()
    return treeDistance
end

function TreeAura.getStatus()
    return {
        enabled = enabled,
        distance = treeDistance,
        hasConnection = connection ~= nil
    }
end

return TreeAura
