local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local KillAura = {}

local enabled = false
local attackDistance = 80
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

local function findCharactersInRange()
    local charactersFolder = workspace:FindFirstChild("Characters")
    if not charactersFolder then
        return {}
    end
    
    local playerPos = getPlayerPosition()
    if not playerPos then
        return {}
    end
    
    local charactersInRange = {}
    
    for _, character in pairs(charactersFolder:GetChildren()) do
        if character:IsA("Model") and character:FindFirstChild("HumanoidRootPart") and character ~= getPlayerCharacter() then
            local distance = (character.HumanoidRootPart.Position - playerPos).Magnitude
            if distance <= attackDistance then
                table.insert(charactersInRange, character)
            end
        end
    end
    
    return charactersInRange
end

local function attackCharacter(character)
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
                    character,
                    tool,
                    "2_8592674679",
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

local function killAuraLoop()
    if not enabled then
        return
    end
    
    local charactersInRange = findCharactersInRange()
    
    for _, character in pairs(charactersInRange) do
        if enabled then
            attackCharacter(character)
            wait(0.1)
        else
            break
        end
    end
end

function KillAura.toggle()
    enabled = not enabled
    
    if enabled then
        print("Kill Aura: ON")
        connection = RunService.Heartbeat:Connect(function()
            killAuraLoop()
        end)
    else
        print("Kill Aura: OFF")
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
    
    return enabled
end

function KillAura.stop()
    enabled = false
    if connection then
        connection:Disconnect()
        connection = nil
    end
    print("Kill Aura: STOPPED")
end

function KillAura.isEnabled()
    return enabled
end

function KillAura.setDistance(distance)
    attackDistance = distance
    print("Kill Aura distance set to:", distance)
end

function KillAura.getDistance()
    return attackDistance
end

function KillAura.getStatus()
    return {
        enabled = enabled,
        distance = attackDistance,
        hasConnection = connection ~= nil
    }
end

return KillAura
