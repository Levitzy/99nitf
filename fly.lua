local Fly = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

Fly.flyEnabled = false
Fly.flySpeed = 50
Fly.flyConnection = nil
Fly.bodyVelocity = nil
Fly.bodyPosition = nil
Fly.bodyAngularVelocity = nil

local keys = {
    W = false,
    A = false,
    S = false,
    D = false,
    Space = false,
    LeftShift = false
}

function Fly.createFlyObjects()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local rootPart = character.HumanoidRootPart
    
    if Fly.bodyVelocity then
        Fly.bodyVelocity:Destroy()
    end
    if Fly.bodyPosition then
        Fly.bodyPosition:Destroy()
    end
    if Fly.bodyAngularVelocity then
        Fly.bodyAngularVelocity:Destroy()
    end
    
    Fly.bodyVelocity = Instance.new("BodyVelocity")
    Fly.bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    Fly.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    Fly.bodyVelocity.Parent = rootPart
    
    Fly.bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    Fly.bodyAngularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
    Fly.bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    Fly.bodyAngularVelocity.Parent = rootPart
    
    return true
end

function Fly.destroyFlyObjects()
    if Fly.bodyVelocity then
        Fly.bodyVelocity:Destroy()
        Fly.bodyVelocity = nil
    end
    if Fly.bodyPosition then
        Fly.bodyPosition:Destroy()
        Fly.bodyPosition = nil
    end
    if Fly.bodyAngularVelocity then
        Fly.bodyAngularVelocity:Destroy()
        Fly.bodyAngularVelocity = nil
    end
end

function Fly.updateMovement()
    if not Fly.flyEnabled or not Fly.bodyVelocity then
        return
    end
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local rootPart = character.HumanoidRootPart
    local camera = workspace.CurrentCamera
    local moveVector = Vector3.new(0, 0, 0)
    
    if keys.W then
        moveVector = moveVector + camera.CFrame.LookVector
    end
    if keys.S then
        moveVector = moveVector - camera.CFrame.LookVector
    end
    if keys.A then
        moveVector = moveVector - camera.CFrame.RightVector
    end
    if keys.D then
        moveVector = moveVector + camera.CFrame.RightVector
    end
    if keys.Space then
        moveVector = moveVector + Vector3.new(0, 1, 0)
    end
    if keys.LeftShift then
        moveVector = moveVector - Vector3.new(0, 1, 0)
    end
    
    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit
    end
    
    Fly.bodyVelocity.Velocity = moveVector * Fly.flySpeed
end

function Fly.onKeyDown(key)
    if keys[key.KeyCode.Name] ~= nil then
        keys[key.KeyCode.Name] = true
    end
end

function Fly.onKeyUp(key)
    if keys[key.KeyCode.Name] ~= nil then
        keys[key.KeyCode.Name] = false
    end
end

function Fly.setEnabled(enabled)
    Fly.flyEnabled = enabled
    
    if enabled then
        if Fly.createFlyObjects() then
            Fly.flyConnection = RunService.Heartbeat:Connect(Fly.updateMovement)
            
            UserInputService.InputBegan:Connect(Fly.onKeyDown)
            UserInputService.InputEnded:Connect(Fly.onKeyUp)
            
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.PlatformStand = true
            end
        else
            Fly.flyEnabled = false
            return false
        end
    else
        if Fly.flyConnection then
            Fly.flyConnection:Disconnect()
            Fly.flyConnection = nil
        end
        
        Fly.destroyFlyObjects()
        
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.PlatformStand = false
        end
        
        for key, _ in pairs(keys) do
            keys[key] = false
        end
    end
    
    return true
end

function Fly.setSpeed(speed)
    Fly.flySpeed = math.max(1, math.min(speed, 500))
end

function Fly.getStatus()
    if Fly.flyEnabled then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local position = character.HumanoidRootPart.Position
            return string.format("Status: Flying at speed %.0f - Pos: (%.0f, %.0f, %.0f)", 
                   Fly.flySpeed, position.X, position.Y, position.Z)
        else
            return "Status: Flying - No character found"
        end
    else
        return "Status: Fly disabled"
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    if Fly.flyEnabled then
        wait(1)
        Fly.setEnabled(true)
    end
end)

return Fly