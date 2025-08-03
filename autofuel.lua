local AutoFuel = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 1
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0

function AutoFuel.getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

function AutoFuel.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function AutoFuel.getMainFire()
    local workspace = game:GetService("Workspace")
    local map = workspace:WaitForChild("Map")
    local campground = map:WaitForChild("Campground")
    local mainFire = campground:WaitForChild("MainFire")
    
    local targetPart = mainFire:FindFirstChild("Meshes/log_Cylinder001") or 
                      mainFire:FindFirstChild("Meshes/log_Cylinder") or
                      mainFire:FindFirstChildOfClass("Part") or
                      mainFire:FindFirstChildOfClass("MeshPart")
    
    return mainFire, targetPart
end

function AutoFuel.findLogItems()
    local workspace = game:GetService("Workspace")
    local logItems = {}
    
    for _, item in pairs(workspace:GetChildren()) do
        if item.Name == "Log" and item:FindFirstChild("Meshes/log_Cylinder") then
            table.insert(logItems, item)
        end
    end
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item.Name == "Log" and (item:FindFirstChild("Handle") or item:FindFirstChild("Meshes/log_Cylinder")) then
                table.insert(logItems, item)
            end
        end
    end
    
    return logItems
end

function AutoFuel.moveItemToMainFire(logItem)
    local mainFire, mainFirePart = AutoFuel.getMainFire()
    if not mainFire or not mainFirePart or not logItem or not logItem.Parent then
        return false
    end
    
    local success = pcall(function()
        local logHandle = logItem:FindFirstChild("Handle") or 
                         logItem:FindFirstChild("Meshes/log_Cylinder") or
                         logItem:FindFirstChildOfClass("Part") or
                         logItem:FindFirstChildOfClass("MeshPart")
        
        if logHandle then
            local targetCFrame = mainFirePart.CFrame
            logHandle.CFrame = targetCFrame * CFrame.new(
                math.random(-4, 4),
                math.random(3, 6),
                math.random(-4, 4)
            )
            
            if logHandle:FindFirstChild("BodyVelocity") then
                logHandle.BodyVelocity:Destroy()
            end
            if logHandle:FindFirstChild("BodyAngularVelocity") then
                logHandle.BodyAngularVelocity:Destroy()
            end
            
            logHandle.Velocity = Vector3.new(0, 0, 0)
            logHandle.AngularVelocity = Vector3.new(0, 0, 0)
            
            if logHandle:FindFirstChild("AssemblyLinearVelocity") then
                logHandle.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
            if logHandle:FindFirstChild("AssemblyAngularVelocity") then
                logHandle.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)
    
    return success
end

function AutoFuel.autoFuelLoop()
    if not AutoFuel.autoFuelEnabled then return end
    
    local currentTime = tick()
    if currentTime - AutoFuel.lastFuelTime < AutoFuel.fuelDelay then
        return
    end
    
    local logItems = AutoFuel.findLogItems()
    
    if #logItems > 0 then
        for i = 1, math.min(#logItems, 3) do
            local logItem = logItems[i]
            if logItem and logItem.Parent then
                AutoFuel.moveItemToMainFire(logItem)
                wait(0.1)
            end
        end
        AutoFuel.lastFuelTime = currentTime
    end
end

function AutoFuel.setEnabled(enabled)
    AutoFuel.autoFuelEnabled = enabled
    
    if enabled then
        AutoFuel.fuelConnection = RunService.Heartbeat:Connect(AutoFuel.autoFuelLoop)
    else
        if AutoFuel.fuelConnection then
            AutoFuel.fuelConnection:Disconnect()
            AutoFuel.fuelConnection = nil
        end
    end
end

function AutoFuel.setFuelDelay(delay)
    AutoFuel.fuelDelay = delay
end

function AutoFuel.getStatus()
    if AutoFuel.autoFuelEnabled then
        local logItems = AutoFuel.findLogItems()
        local mainFire, mainFirePart = AutoFuel.getMainFire()
        
        if not mainFire or not mainFirePart then
            return "Status: MainFire not found!", 0
        elseif #logItems > 0 then
            local playerPos = AutoFuel.getPlayerPosition()
            local mainFirePos = mainFirePart.Position
            local distance = playerPos and AutoFuel.getDistance(playerPos, mainFirePos) or 0
            return string.format("Status: Fueling MainFire - %d logs available - Delay: %.1fs", #logItems, AutoFuel.fuelDelay), distance
        else
            return "Status: No log items found", 0
        end
    else
        return "Status: Auto fuel disabled", 0
    end
end

return AutoFuel