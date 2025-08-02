local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local KillAura = {}

local enabled = false
local attackDistance = 80
local connection
local lastScanTime = 0
local cachedTargets = {}
local cacheTimeout = 1

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
        return inventory:FindFirstChild("Chainsaw") or
               inventory:FindFirstChild("Strong Axe") or
               inventory:FindFirstChild("Gooad Axe") or
               inventory:FindFirstChild("Old Axe") or
               inventory:FindFirstChild("Axe")
    end
    return nil
end

local function findCharactersInRange()
    local currentTime = tick()
    
    if currentTime - lastScanTime < cacheTimeout and #cachedTargets > 0 then
        return cachedTargets
    end
    
    local charactersFolder = workspace:FindFirstChild("Characters")
    if not charactersFolder then
        cachedTargets = {}
        lastScanTime = currentTime
        return {}
    end
    
    local playerPos = getPlayerPosition()
    if not playerPos then
        cachedTargets = {}
        lastScanTime = currentTime
        return {}
    end
    
    local charactersInRange = {}
    
    for _, character in pairs(charactersFolder:GetChildren()) do
        if character:IsA("Model") and character:FindFirstChild("HumanoidRootPart") and character ~= getPlayerCharacter() then
            local distance = (character.HumanoidRootPart.Position - playerPos).Magnitude
            if distance <= attackDistance then
                charactersInRange[#charactersInRange + 1] = {
                    character = character,
                    distance = distance
                }
            end
        end
    end
    
    if #charactersInRange > 1 then
        table.sort(charactersInRange, function(a, b)
            return a.distance < b.distance
        end)
    end
    
    cachedTargets = charactersInRange
    lastScanTime = currentTime
    
    return charactersInRange
end

local function attackCharacter(targetData)
    local tool = getPlayerInventoryTool()
    if not tool then
        return false
    end
    
    local character = targetData.character
    if not character or not character.Parent then
        return false
    end
    
    local remoteEvent = ReplicatedStorage.RemoteEvents and ReplicatedStorage.RemoteEvents:FindFirstChild("ToolDamageObject")
    if remoteEvent then
        local playerCharacter = getPlayerCharacter()
        if playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart") then
            local success = pcall(function()
                remoteEvent:InvokeServer(character, tool, "2_8592674679", playerCharacter.HumanoidRootPart.CFrame)
            end)
            
            return success
        end
    end
    
    return false
end

local function killAuraLoop()
    if not enabled then
        return
    end
    
    local charactersInRange = findCharactersInRange()
    
    if #charactersInRange > 0 then
        local closestTarget = charactersInRange[1]
        attackCharacter(closestTarget)
    end
end

function KillAura.toggle()
    enabled = not enabled
    
    if enabled then
        print("Kill Aura: ON (Distance: " .. attackDistance .. ")")
        if connection then
            connection:Disconnect()
        end
        connection = RunService.Heartbeat:Connect(function()
            wait(0.1)
            killAuraLoop()
        end)
    else
        print("Kill Aura: OFF")
        if connection then
            connection:Disconnect()
            connection = nil
        end
        cachedTargets = {}
    end
    
    return enabled
end

function KillAura.stop()
    enabled = false
    if connection then
        connection:Disconnect()
        connection = nil
    end
    cachedTargets = {}
    print("Kill Aura: STOPPED")
end

function KillAura.isEnabled()
    return enabled
end

function KillAura.setDistance(distance)
    attackDistance = math.max(10, math.min(500, distance))
    cachedTargets = {}
    print("Kill Aura distance set to:", attackDistance)
end

function KillAura.getDistance()
    return attackDistance
end

function KillAura.getStatus()
    return {
        enabled = enabled,
        distance = attackDistance,
        hasConnection = connection ~= nil,
        targetsFound = #cachedTargets
    }
end

return KillAura
