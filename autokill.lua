local AutoKill = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoKill.autoKillEnabled = false
AutoKill.killDelay = 0.1
AutoKill.killConnection = nil
AutoKill.lastKillTime = 0

function AutoKill.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function AutoKill.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function AutoKill.findAllBunnies()
    local workspace = game:GetService("Workspace")
    local charactersFolder = workspace:WaitForChild("Characters")
    
    local allBunnies = {}
    local playerPos = AutoKill.getPlayerPosition()
    
    for _, bunny in pairs(charactersFolder:GetChildren()) do
        if bunny.Name == "Bunny" and bunny:FindFirstChild("HumanoidRootPart") then
            local distance = 0
            if playerPos then
                distance = AutoKill.getDistance(playerPos, bunny.HumanoidRootPart.Position)
            end
            table.insert(allBunnies, {
                bunny = bunny, 
                distance = distance
            })
        end
    end
    
    table.sort(allBunnies, function(a, b)
        return a.distance < b.distance
    end)
    
    return allBunnies
end

function AutoKill.hasOldAxe()
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if inventory then
        return inventory:FindFirstChild("Old Axe") ~= nil
    end
    return false
end

function AutoKill.attackBunny(bunny)
    if not AutoKill.hasOldAxe() then
        return false
    end
    
    local inventory = LocalPlayer:WaitForChild("Inventory")
    local oldAxe = inventory:WaitForChild("Old Axe")
    
    local playerPos = AutoKill.getPlayerPosition()
    if not playerPos then return false end
    
    local bunnyPos = bunny.HumanoidRootPart.Position
    local lookDirection = (bunnyPos - playerPos).Unit
    local cframe = CFrame.lookAt(playerPos, bunnyPos)
    
    for i = 1, 8 do
        local args = {
            bunny,
            oldAxe,
            "6_9111530262",
            cframe
        }
        
        local success, result = pcall(function()
            return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(unpack(args))
        end)
        
        if not success then
            wait(0.01)
        else
            wait(0.005)
        end
    end
    
    return true
end

function AutoKill.attackAllBunnies(bunniesData)
    if not AutoKill.hasOldAxe() then
        return false
    end
    
    local currentTime = tick()
    if currentTime - AutoKill.lastKillTime < AutoKill.killDelay then
        return false
    end
    
    local attackedCount = 0
    
    for _, bunnyData in pairs(bunniesData) do
        if bunnyData.bunny and bunnyData.bunny.Parent then
            spawn(function()
                local success = AutoKill.attackBunny(bunnyData.bunny)
                if success then
                    attackedCount = attackedCount + 1
                end
            end)
        end
    end
    
    AutoKill.lastKillTime = currentTime
    return true
end

function AutoKill.autoKillLoop()
    if not AutoKill.autoKillEnabled then return end
    
    local allBunnies = AutoKill.findAllBunnies()
    
    if #allBunnies > 0 then
        AutoKill.attackAllBunnies(allBunnies)
    end
end

function AutoKill.setEnabled(enabled)
    AutoKill.autoKillEnabled = enabled
    
    if enabled then
        AutoKill.killConnection = RunService.Heartbeat:Connect(AutoKill.autoKillLoop)
    else
        if AutoKill.killConnection then
            AutoKill.killConnection:Disconnect()
            AutoKill.killConnection = nil
        end
    end
end

function AutoKill.setKillDelay(delay)
    AutoKill.killDelay = delay
end

function AutoKill.getStatus()
    if AutoKill.autoKillEnabled then
        local allBunnies = AutoKill.findAllBunnies()
        local hasAxe = AutoKill.hasOldAxe()
        
        if not hasAxe then
            return "Status: No Old Axe found!", 0, 0
        elseif #allBunnies > 0 then
            local closestDistance = allBunnies[1] and allBunnies[1].distance or 0
            
            return string.format("Status: Attacking %d bunnies - Fast Mode!", 
                   #allBunnies), #allBunnies, closestDistance
        else
            return "Status: No bunnies found", 0, 0
        end
    else
        return "Status: Auto kill disabled", 0, 0
    end
end

return AutoKill