local AutoKill = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject")

AutoKill.autoKillEnabled = false
AutoKill.killDelay = 0.1
AutoKill.maxTargets = 5
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

function AutoKill.findAllTargets()
    local charactersFolder = game:GetService("Workspace"):WaitForChild("Characters")
    local allTargets = {}
    local playerPos = AutoKill.getPlayerPosition()
    for _, target in pairs(charactersFolder:GetChildren()) do
        local name = target.Name
        if (name == "Bunny" or name == "Wolf" or name == "Alpha Wolf" or name == "Cultist" or name == "Crossbow Cultist") and target:FindFirstChild("HumanoidRootPart") then
            local distance = 0
            if playerPos then
                distance = AutoKill.getDistance(playerPos, target.HumanoidRootPart.Position)
            end
            table.insert(allTargets, {target = target, distance = distance, type = name})
        end
    end
    table.sort(allTargets, function(a, b)
        return a.distance < b.distance
    end)
    return allTargets
end

function AutoKill.hasOldAxe()
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if inventory then
        return inventory:FindFirstChild("Old Axe") ~= nil
    end
    return false
end

function AutoKill.attackTarget(target)
    if not AutoKill.hasOldAxe() then
        return false
    end
    local inventory = LocalPlayer:WaitForChild("Inventory")
    local oldAxe = inventory:WaitForChild("Old Axe")
    local playerPos = AutoKill.getPlayerPosition()
    if not playerPos then return false end
    local targetPos = target.HumanoidRootPart.Position
    local cframe = CFrame.lookAt(playerPos, targetPos)
    for i = 1, 8 do
        local args = {target, oldAxe, "6_9111530262", cframe}
        local success = pcall(function()
            return Remote:InvokeServer(unpack(args))
        end)
        if not success then
            task.wait(0.01)
        else
            task.wait(0.005)
        end
    end
    return true
end

function AutoKill.attackAllTargets(targetsData)
    if not AutoKill.hasOldAxe() then
        return false
    end
    local currentTime = tick()
    if currentTime - AutoKill.lastKillTime < AutoKill.killDelay then
        return false
    end
    for i = 1, math.min(#targetsData, AutoKill.maxTargets) do
        local targetData = targetsData[i]
        if targetData.target and targetData.target.Parent then
            AutoKill.attackTarget(targetData.target)
        end
    end
    AutoKill.lastKillTime = currentTime
    return true
end

function AutoKill.autoKillLoop()
    if not AutoKill.autoKillEnabled then return end
    local allTargets = AutoKill.findAllTargets()
    if #allTargets > 0 then
        AutoKill.attackAllTargets(allTargets)
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

function AutoKill.setMaxTargets(count)
    AutoKill.maxTargets = count
end

function AutoKill.getStatus()
    if AutoKill.autoKillEnabled then
        local allTargets = AutoKill.findAllTargets()
        local hasAxe = AutoKill.hasOldAxe()
        if not hasAxe then
            return "Status: No Old Axe found!", 0, 0
        elseif #allTargets > 0 then
            local closestDistance = allTargets[1] and allTargets[1].distance or 0
            local bunnyCount = 0
            local wolfCount = 0
            local alphaWolfCount = 0
            local cultistCount = 0
            local crossbowCultistCount = 0
            for _, targetData in pairs(allTargets) do
                if targetData.type == "Bunny" then
                    bunnyCount = bunnyCount + 1
                elseif targetData.type == "Wolf" then
                    wolfCount = wolfCount + 1
                elseif targetData.type == "Alpha Wolf" then
                    alphaWolfCount = alphaWolfCount + 1
                elseif targetData.type == "Cultist" then
                    cultistCount = cultistCount + 1
                elseif targetData.type == "Crossbow Cultist" then
                    crossbowCultistCount = crossbowCultistCount + 1
                end
            end
            return string.format("B:%d W:%d AW:%d C:%d CC:%d", bunnyCount, wolfCount, alphaWolfCount, cultistCount, crossbowCultistCount), #allTargets, closestDistance
        else
            return "Status: No targets found", 0, 0
        end
    else
        return "Status: Auto kill disabled", 0, 0
    end
end

return AutoKill
