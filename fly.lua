local Fly = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

Fly.flyEnabled = false
Fly.flySpeed = 50
Fly.flyConnection = nil
Fly.inputConnection1 = nil
Fly.inputConnection2 = nil
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
    local humanoid = character:FindFirstChild("Humanoid")
    
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
    Fly.bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    Fly.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    Fly.bodyVelocity.Parent = rootPart
    
    Fly.bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    Fly.bodyAngularVelocity.MaxTorque = Vector3.new(0, 0, 0)
    Fly.bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    Fly.bodyAngularVelocity.Parent = rootPart
    
    if humanoid then
        humanoid.PlatformStand = true
    end
    
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
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid then
            humanoid.PlatformStand = false
        end
        
        if rootPart then
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.AngularVelocity = Vector3.new(0, 0, 0)
        end
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
    local humanoid = character:FindFirstChild("Humanoid")
    local camera = workspace.CurrentCamera
    local moveVector = Vector3.new(0, 0, 0)
    
    local cameraCFrame = camera.CFrame
    local lookVector = cameraCFrame.LookVector
    local rightVector = cameraCFrame.RightVector
    
    if keys.W then
        moveVector = moveVector + Vector3.new(lookVector.X, 0, lookVector.Z).Unit
    end
    if keys.S then
        moveVector = moveVector - Vector3.new(lookVector.X, 0, lookVector.Z).Unit
    end
    if keys.A then
        moveVector = moveVector - Vector3.new(rightVector.X, 0, rightVector.Z).Unit
    end
    if keys.D then
        moveVector = moveVector + Vector3.new(rightVector.X, 0, rightVector.Z).Unit
    end
    if keys.Space then
        moveVector = moveVector + Vector3.new(0, 1, 0)
    end
    if keys.LeftShift then
        moveVector = moveVector + Vector3.new(0, -1, 0)
    end
    
    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit
    end
    
    Fly.bodyVelocity.Velocity = moveVector * Fly.flySpeed
    
    if humanoid then
        humanoid.PlatformStand = true
        if moveVector.Magnitude > 0 then
            local newCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + Vector3.new(moveVector.X, 0, moveVector.Z))
            rootPart.CFrame = rootPart.CFrame:Lerp(newCFrame, 0.1)
        end
    end
end

function Fly.onKeyDown(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        keys.W = true
    elseif input.KeyCode == Enum.KeyCode.A then
        keys.A = true
    elseif input.KeyCode == Enum.KeyCode.S then
        keys.S = true
    elseif input.KeyCode == Enum.KeyCode.D then
        keys.D = true
    elseif input.KeyCode == Enum.KeyCode.Space then
        keys.Space = true
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        keys.LeftShift = true
    end
end

function Fly.onKeyUp(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        keys.W = false
    elseif input.KeyCode == Enum.KeyCode.A then
        keys.A = false
    elseif input.KeyCode == Enum.KeyCode.S then
        keys.S = false
    elseif input.KeyCode == Enum.KeyCode.D then
        keys.D = false
    elseif input.KeyCode == Enum.KeyCode.Space then
        keys.Space = false
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        keys.LeftShift = false
    end
end

function Fly.onTouchMoved(touch, gameProcessed)
    if not Fly.flyEnabled or gameProcessed then return end
    
    local camera = workspace.CurrentCamera
    local touchPosition = touch.Position
    local screenSize = camera.ViewportSize
    
    local centerX = screenSize.X / 2
    local centerY = screenSize.Y / 2
    
    local deltaX = (touchPosition.X - centerX) / centerX
    local deltaY = (touchPosition.Y - centerY) / centerY
    
    local deadZone = 0.3
    
    keys.W = deltaY < -deadZone
    keys.S = deltaY > deadZone
    keys.A = deltaX < -deadZone
    keys.D = deltaX > deadZone
end

function Fly.onTouchEnded(touch, gameProcessed)
    if not Fly.flyEnabled then return end
    
    keys.W = false
    keys.S = false
    keys.A = false
    keys.D = false
end

function Fly.setEnabled(enabled)
    Fly.flyEnabled = enabled
    
    if enabled then
        if Fly.createFlyObjects() then
            Fly.flyConnection = RunService.Heartbeat:Connect(Fly.updateMovement)
            
            if Fly.inputConnection1 then Fly.inputConnection1:Disconnect() end
            if Fly.inputConnection2 then Fly.inputConnection2:Disconnect() end
            
            Fly.inputConnection1 = UserInputService.InputBegan:Connect(Fly.onKeyDown)
            Fly.inputConnection2 = UserInputService.InputEnded:Connect(Fly.onKeyUp)
            
            if UserInputService.TouchEnabled then
                UserInputService.TouchMoved:Connect(Fly.onTouchMoved)
                UserInputService.TouchEnded:Connect(Fly.onTouchEnded)
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
        
        if Fly.inputConnection1 then
            Fly.inputConnection1:Disconnect()
            Fly.inputConnection1 = nil
        end
        
        if Fly.inputConnection2 then
            Fly.inputConnection2:Disconnect()
            Fly.inputConnection2 = nil
        end
        
        Fly.destroyFlyObjects()
        
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