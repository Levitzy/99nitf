local AutoFuel = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoFuel.autoFuelEnabled = false
AutoFuel.fuelDelay = 0.5
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
    
    return mainFire
end

function AutoFuel.findAllFuelItems()
    local workspace = game:GetService("Workspace")
    local fuelItems = {}
    
    local function scanArea(container)
        for _, item in pairs(container:GetChildren()) do
            if item.Name == "Log" and item:FindFirstChild("Meshes/log_Cylinder") then
                table.insert(fuelItems, item)
            elseif item.Name == "Coal" and item:FindFirstChild("Coal") then
                table.insert(fuelItems, item)
            elseif item.Name == "Fuel Canister" and (item:FindFirstChild("Handle") or item:FindFirstChildOfClass("Part")) then
                table.insert(fuelItems, item)
            end
        end
    end
    
    scanArea(workspace)
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        scanArea(itemsFolder)
    end
    
    local mapFolder = workspace:FindFirstChild("Map")
    if mapFolder then
        for _, subfolder in pairs(mapFolder:GetChildren()) do
            if subfolder:IsA("Folder") then
                scanArea(subfolder)
            end
        end
    end
    
    return fuelItems
end

--[[
    Moves a fuel item as if the player carried it and places it directly
    on top of the MainFire.  This avoids relying on any teleport patches
    while ensuring the item ends up precisely at the campfire.
]]
function AutoFuel.bringItemToMainFire(fuelItem)
    local mainFire = AutoFuel.getMainFire()
    if not mainFire or not fuelItem or not fuelItem.Parent then
        return false
    end

    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false
    end

    local fuelHandle
    if fuelItem.Name == "Log" then
        fuelHandle = fuelItem:FindFirstChild("Handle") or fuelItem:FindFirstChild("Meshes/log_Cylinder")
    elseif fuelItem.Name == "Coal" then
        fuelHandle = fuelItem:FindFirstChild("Coal")
    elseif fuelItem.Name == "Fuel Canister" then
        fuelHandle = fuelItem:FindFirstChild("Handle") or fuelItem:FindFirstChildOfClass("Part")
    end

    if not fuelHandle then
        fuelHandle = fuelItem:FindFirstChildOfClass("Part") or fuelItem:FindFirstChildOfClass("MeshPart")
    end
    if not fuelHandle then return false end

    -- move item near the player to simulate carrying it
    fuelHandle.CFrame = hrp.CFrame * CFrame.new(0, 0, -2)

    if fuelHandle:FindFirstChild("BodyVelocity") then
        fuelHandle.BodyVelocity:Destroy()
    end
    if fuelHandle:FindFirstChild("BodyAngularVelocity") then
        fuelHandle.BodyAngularVelocity:Destroy()
    end

    -- brief delay so the item appears carried
    task.wait(0.05)

    -- place directly above the campfire so it falls onto it
    local target = mainFire.Position + Vector3.new(0, 1, 0)
    fuelHandle.CFrame = CFrame.new(target)

    -- remove any lingering velocity so it drops straight down
    fuelHandle.Velocity = Vector3.zero
    fuelHandle.AngularVelocity = Vector3.zero
    if fuelHandle:FindFirstChild("AssemblyLinearVelocity") then
        fuelHandle.AssemblyLinearVelocity = Vector3.zero
    end
    if fuelHandle:FindFirstChild("AssemblyAngularVelocity") then
        fuelHandle.AssemblyAngularVelocity = Vector3.zero
    end

    return true
end

function AutoFuel.teleportItemToMainFire(fuelItem)
    local mainFire = AutoFuel.getMainFire()
    if not mainFire or not fuelItem or not fuelItem.Parent then
        return false
    end
    
    local success = pcall(function()
        local fuelHandle = nil
        
        if fuelItem.Name == "Log" then
            fuelHandle = fuelItem:FindFirstChild("Handle") or fuelItem:FindFirstChild("Meshes/log_Cylinder")
        elseif fuelItem.Name == "Coal" then
            fuelHandle = fuelItem:FindFirstChild("Coal")
        elseif fuelItem.Name == "Fuel Canister" then
            fuelHandle = fuelItem:FindFirstChild("Handle") or fuelItem:FindFirstChildOfClass("Part")
        end
        
        if not fuelHandle then
            fuelHandle = fuelItem:FindFirstChildOfClass("Part") or fuelItem:FindFirstChildOfClass("MeshPart")
        end
        
        if fuelHandle then
            local targetPosition = mainFire.Position + Vector3.new(0, 1, 0)

            fuelHandle.CFrame = CFrame.new(targetPosition)

            if fuelHandle:FindFirstChild("BodyVelocity") then
                fuelHandle.BodyVelocity:Destroy()
            end
            if fuelHandle:FindFirstChild("BodyAngularVelocity") then
                fuelHandle.BodyAngularVelocity:Destroy()
            end

            fuelHandle.Velocity = Vector3.zero
            fuelHandle.AngularVelocity = Vector3.zero

            if fuelHandle:FindFirstChild("AssemblyLinearVelocity") then
                fuelHandle.AssemblyLinearVelocity = Vector3.zero
            end
            if fuelHandle:FindFirstChild("AssemblyAngularVelocity") then
                fuelHandle.AssemblyAngularVelocity = Vector3.zero
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
    
    local fuelItems = AutoFuel.findAllFuelItems()
    
    if #fuelItems > 0 then
        for i = 1, math.min(#fuelItems, 3) do
            local fuelItem = fuelItems[i]
            if fuelItem and fuelItem.Parent then
                if not AutoFuel.bringItemToMainFire(fuelItem) then
                    AutoFuel.teleportItemToMainFire(fuelItem)
                end
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
        local fuelItems = AutoFuel.findAllFuelItems()
        local mainFire = AutoFuel.getMainFire()
        
        if not mainFire then
            return "Status: MainFire not found!", 0
        elseif #fuelItems > 0 then
            local playerPos = AutoFuel.getPlayerPosition()
            local mainFirePos = mainFire.Position
            local distance = playerPos and AutoFuel.getDistance(playerPos, mainFirePos) or 0

            local logCount = 0
            local coalCount = 0
            local canisterCount = 0

            for _, item in pairs(fuelItems) do
                if item.Name == "Log" then
                    logCount = logCount + 1
                elseif item.Name == "Coal" then
                    coalCount = coalCount + 1
                elseif item.Name == "Fuel Canister" then
                    canisterCount = canisterCount + 1
                end
            end

            return string.format("Status: Delivering to MainFire - Logs:%d Coal:%d Canisters:%d - Direct Drop!",
                   logCount, coalCount, canisterCount), distance
        else
            return "Status: No fuel items found", 0
        end
    else
        return "Status: Auto fuel disabled", 0
    end
end

return AutoFuel
