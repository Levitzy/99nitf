local AutoFuel = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 1.0
AutoFuel.fuelConnection = nil
AutoFuel.lastFuelTime = 0
AutoFuel.dropPosition = Vector3.new(0, 4, -3)

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
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    
    local campground = map:FindFirstChild("Campground")
    if not campground then return nil end
    
    local mainFire = campground:FindFirstChild("MainFire")
    return mainFire
end

function AutoFuel.findLogItems()
    local workspace = game:GetService("Workspace")
    local fuelItems = {}
    
    local function addFuelItem(item)
        if item.Name == "Log" then
            local handle = item:FindFirstChild("Handle") or item:FindFirstChild("Meshes/log_Cylinder")
            if handle then
                table.insert(fuelItems, {item = item, handle = handle, type = "Log"})
            end
        elseif item.Name == "Coal" then
            local handle = item:FindFirstChild("Coal")
            if handle then
                table.insert(fuelItems, {item = item, handle = handle, type = "Coal"})
            end
        elseif item.Name == "FuelCanister" then
            local handle = item:FindFirstChild("Handle") or item:FindFirstChildOfClass("Part")
            if handle then
                table.insert(fuelItems, {item = item, handle = handle, type = "FuelCanister"})
            end
        end
    end
    
    for _, item in pairs(workspace:GetChildren()) do
        addFuelItem(item)
    end
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            addFuelItem(item)
        end
    end
    
    local playerPos = AutoFuel.getPlayerPosition()
    if playerPos then
        table.sort(fuelItems, function(a, b)
            local distA = AutoFuel.getDistance(playerPos, a.handle.Position)
            local distB = AutoFuel.getDistance(playerPos, b.handle.Position)
            return distA < distB
        end)
    end
    
    return fuelItems
end

function AutoFuel.moveItemToPosition(fuelData)
    if not fuelData or not fuelData.item or not fuelData.handle or not fuelData.item.Parent then
        return false
    end
    
    local success = pcall(function()
        local handle = fuelData.handle
        
        if handle:FindFirstChild("BodyVelocity") then
            handle.BodyVelocity:Destroy()
        end
        if handle:FindFirstChild("BodyAngularVelocity") then
            handle.BodyAngularVelocity:Destroy()
        end
        if handle:FindFirstChild("BodyPosition") then
            handle.BodyPosition:Destroy()
        end
        
        handle.CFrame = CFrame.new(AutoFuel.dropPosition)
        handle.Velocity = Vector3.new(0, 0, 0)
        handle.CanCollide = false
        
        if handle:FindFirstChild("AssemblyAngularVelocity") then
            handle.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
        if handle:FindFirstChild("AngularVelocity") then
            handle.AngularVelocity = Vector3.new(0, 0, 0)
        end
        if handle:FindFirstChild("AssemblyLinearVelocity") then
            handle.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
        bodyVelocity.Velocity = Vector3.new(0, -15, 0)
        bodyVelocity.Parent = handle
        
        spawn(function()
            wait(0.5)
            if handle and handle.Parent then
                handle.CanCollide = true
                if bodyVelocity and bodyVelocity.Parent then
                    bodyVelocity:Destroy()
                end
            end
        end)
        
        spawn(function()
            wait(2)
            if handle and handle.Parent and handle:FindFirstChild("BodyVelocity") then
                handle.BodyVelocity:Destroy()
            end
        end)
    end)
    
    return success
end

function AutoFuel.autoFuelLoop()
    if not AutoFuel.autoFuelEnabled then return end
    
    local currentTime = tick()
    if currentTime - AutoFuel.lastFuelTime < AutoFuel.fuelDelay then
        return
    end
    
    local fuelItems = AutoFuel.findLogItems()
    
    if #fuelItems > 0 then
        local batchSize = math.min(6, #fuelItems)
        local movedItems = 0
        
        for i = 1, batchSize do
            local fuelData = fuelItems[i]
            if fuelData and fuelData.item and fuelData.item.Parent then
                spawn(function()
                    AutoFuel.moveItemToPosition(fuelData)
                end)
                movedItems = movedItems + 1
            end
        end
        
        if movedItems > 0 then
            AutoFuel.lastFuelTime = currentTime
        end
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
    AutoFuel.fuelDelay = math.max(0.1, delay)
end

function AutoFuel.setDropPosition(position)
    AutoFuel.dropPosition = position
end

function AutoFuel.getStatus()
    if AutoFuel.autoFuelEnabled then
        local fuelItems = AutoFuel.findLogItems()
        
        if #fuelItems > 0 then
            local logCount = 0
            local coalCount = 0
            local canisterCount = 0
            
            for _, fuelData in pairs(fuelItems) do
                if fuelData.type == "Log" then
                    logCount = logCount + 1
                elseif fuelData.type == "Coal" then
                    coalCount = coalCount + 1
                elseif fuelData.type == "FuelCanister" then
                    canisterCount = canisterCount + 1
                end
            end
            
            return string.format("Status: Moving fuel to (%.0f,%.0f,%.0f) - L:%d C:%d F:%d - Delay:%.1fs", 
                   AutoFuel.dropPosition.X, AutoFuel.dropPosition.Y, AutoFuel.dropPosition.Z,
                   logCount, coalCount, canisterCount, AutoFuel.fuelDelay), 0
        else
            return "Status: No fuel items found", 0
        end
    else
        return "Status: Auto fuel disabled", 0
    end
end

return AutoFuel