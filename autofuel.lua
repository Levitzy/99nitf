local AutoFuel = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
    
    local firePart = mainFire:FindFirstChild("Meshes/log_Cylinder001") or 
                    mainFire:FindFirstChild("Meshes/log_Cylinder") or
                    mainFire:FindFirstChild("Fire") or
                    mainFire:FindFirstChildOfClass("Part")
    
    return mainFire, firePart
end

function AutoFuel.findLogItems()
    local workspace = game:GetService("Workspace")
    local fuelItems = {}
    
    for _, item in pairs(workspace:GetChildren()) do
        if item.Name == "Log" and item:FindFirstChild("Meshes/log_Cylinder") then
            table.insert(fuelItems, item)
        elseif item.Name == "Coal" and item:FindFirstChild("Coal") then
            table.insert(fuelItems, item)
        elseif item.Name == "FuelCanister" and (item:FindFirstChild("Handle") or item:FindFirstChildOfClass("Part")) then
            table.insert(fuelItems, item)
        end
    end
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item.Name == "Log" and (item:FindFirstChild("Handle") or item:FindFirstChild("Meshes/log_Cylinder")) then
                table.insert(fuelItems, item)
            elseif item.Name == "Coal" and item:FindFirstChild("Coal") then
                table.insert(fuelItems, item)
            elseif item.Name == "FuelCanister" and (item:FindFirstChild("Handle") or item:FindFirstChildOfClass("Part")) then
                table.insert(fuelItems, item)
            end
        end
    end
    
    return fuelItems
end

function AutoFuel.fuelFireWithItem(fuelItem)
    local mainFire, firePart = AutoFuel.getMainFire()
    if not mainFire or not firePart or not fuelItem or not fuelItem.Parent then
        return false
    end
    
    local success = pcall(function()
        local fuelHandle = nil
        
        if fuelItem.Name == "Log" then
            fuelHandle = fuelItem:FindFirstChild("Handle") or fuelItem:FindFirstChild("Meshes/log_Cylinder")
        elseif fuelItem.Name == "Coal" then
            fuelHandle = fuelItem:FindFirstChild("Coal")
        elseif fuelItem.Name == "FuelCanister" then
            fuelHandle = fuelItem:FindFirstChild("Handle") or fuelItem:FindFirstChildOfClass("Part")
        end
        
        if not fuelHandle then
            fuelHandle = fuelItem:FindFirstChildOfClass("Part") or fuelItem:FindFirstChildOfClass("MeshPart")
        end
        
        if fuelHandle then
            local firePosition = firePart.Position
            local playerPos = AutoFuel.getPlayerPosition()
            
            if playerPos then
                local lookDirection = (firePosition - playerPos).Unit
                local cframe = CFrame.lookAt(playerPos, firePosition)
                
                local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
                if remoteEvents then
                    local fuelRemote = remoteEvents:FindFirstChild("AddFuelToFire") or
                                     remoteEvents:FindFirstChild("FuelFire") or
                                     remoteEvents:FindFirstChild("InteractWithFire")
                    
                    if fuelRemote then
                        local args = {
                            mainFire,
                            fuelItem,
                            fuelHandle,
                            cframe
                        }
                        
                        if fuelRemote.ClassName == "RemoteFunction" then
                            fuelRemote:InvokeServer(unpack(args))
                        else
                            fuelRemote:FireServer(unpack(args))
                        end
                    else
                        local interactRemote = remoteEvents:FindFirstChild("InteractWithObject") or
                                             remoteEvents:FindFirstChild("UseItem") or
                                             remoteEvents:FindFirstChild("ToolDamageObject")
                        
                        if interactRemote then
                            local args = {
                                mainFire,
                                fuelItem,
                                "fuel_action",
                                cframe
                            }
                            
                            if interactRemote.ClassName == "RemoteFunction" then
                                interactRemote:InvokeServer(unpack(args))
                            else
                                interactRemote:FireServer(unpack(args))
                            end
                        end
                    end
                end
            end
            
            fuelHandle.CFrame = CFrame.new(firePosition.X + math.random(-1, 1), firePosition.Y + 2, firePosition.Z + math.random(-1, 1))
            fuelHandle.Velocity = Vector3.new(0, 0, 0)
            fuelHandle.AngularVelocity = Vector3.new(0, 0, 0)
            
            if fuelHandle:FindFirstChild("AssemblyLinearVelocity") then
                fuelHandle.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
            if fuelHandle:FindFirstChild("AssemblyAngularVelocity") then
                fuelHandle.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
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
    
    local fuelItems = AutoFuel.findLogItems()
    
    if #fuelItems > 0 then
        local fuelItem = fuelItems[1]
        if fuelItem and fuelItem.Parent then
            AutoFuel.fuelFireWithItem(fuelItem)
            AutoFuel.lastFuelTime = currentTime
            wait(0.5)
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
    AutoFuel.fuelDelay = delay
end

function AutoFuel.getStatus()
    if AutoFuel.autoFuelEnabled then
        local fuelItems = AutoFuel.findLogItems()
        local mainFire, firePart = AutoFuel.getMainFire()
        
        if not mainFire or not firePart then
            return "Status: MainFire not found!", 0
        elseif #fuelItems > 0 then
            local playerPos = AutoFuel.getPlayerPosition()
            local firePos = firePart.Position
            local distance = playerPos and AutoFuel.getDistance(playerPos, firePos) or 0
            
            local logCount = 0
            local coalCount = 0
            local canisterCount = 0
            
            for _, item in pairs(fuelItems) do
                if item.Name == "Log" then
                    logCount = logCount + 1
                elseif item.Name == "Coal" then
                    coalCount = coalCount + 1
                elseif item.Name == "FuelCanister" then
                    canisterCount = canisterCount + 1
                end
            end
            
            return string.format("Status: Auto-fueling MainFire - Log:%d Coal:%d Canisters:%d - Delay:%.1fs", 
                   logCount, coalCount, canisterCount, AutoFuel.fuelDelay), distance
        else
            return "Status: No fuel items found", 0
        end
    else
        return "Status: Auto fuel disabled", 0
    end
end

return AutoFuel