local Fly = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

Fly.flyEnabled = false
Fly.flySpeed = 50
Fly.flyConnection = nil
Fly.inputConnections = {}
Fly.bodyVelocity = nil
Fly.bodyAngularVelocity = nil

local movement = {
    forward = false,
    backward = false,
    left = false,
    right = false,
    up = false,
    down = false
}

local mobileControls = {
    moveVector = Vector3.new(0, 0, 0),
    isTouching = false,
    touchStartPos = nil
}

function Fly.cleanupConnections()
    for _, connection in pairs(Fly.inputConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    Fly.inputConnections = {}
end

function Fly.destroyFlyObjects()
    if Fly.bodyVelocity then
        Fly.bodyVelocity:Destroy()
        Fly.bodyVelocity = nil
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
            if rootPart:FindFirstChild("AssemblyAngularVelocity") then
                rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end

function Fly.createFlyObjects()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local rootPart = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")
    
    Fly.destroyFlyObjects()
    
    Fly.bodyVelocity = Instance.new("BodyVelocity")
    Fly.bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    Fly.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    Fly.bodyVelocity.Parent = rootPart
    
    Fly.bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    Fly.bodyAngularVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    Fly.bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    Fly.bodyAngularVelocity.Parent = rootPart
    
    if humanoid then
        humanoid.PlatformStand = true
    end
    
    return true
end

function Fly.updateMovement()
    if not Fly.flyEnabled or not Fly.bodyVelocity then
        return
    end
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local camera = workspace.CurrentCamera
    local moveVector = Vector3.new(0, 0, 0)
    
    if UserInputService.TouchEnabled and mobileControls.isTouching then
        moveVector = mobileControls.moveVector
    else
        local cameraCFrame = camera.CFrame
        local lookVector = cameraCFrame.LookVector
        local rightVector = cameraCFrame.RightVector
        local upVector = Vector3.new(0, 1, 0)
        
        if movement.forward then
            moveVector = moveVector + lookVector
        end
        if movement.backward then
            moveVector = moveVector - lookVector
        end
        if movement.left then
            moveVector = moveVector - rightVector
        end
        if movement.right then
            moveVector = moveVector + rightVector
        end
        if movement.up then
            moveVector = moveVector + upVector
        end
        if movement.down then
            moveVector = moveVector - upVector
        end
    end
    
    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit
    end
    
    Fly.bodyVelocity.Velocity = moveVector * Fly.flySpeed
    
    if Fly.bodyAngularVelocity then
        Fly.bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    end
end

function Fly.onKeyDown(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        movement.forward = true
    elseif input.KeyCode == Enum.KeyCode.S then
        movement.backward = true
    elseif input.KeyCode == Enum.KeyCode.A then
        movement.left = true
    elseif input.KeyCode == Enum.KeyCode.D then
        movement.right = true
    elseif input.KeyCode == Enum.KeyCode.Space then
        movement.up = true
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.LeftControl then
        movement.down = true
    end
end

function Fly.onKeyUp(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        movement.forward = false
    elseif input.KeyCode == Enum.KeyCode.S then
        movement.backward = false
    elseif input.KeyCode == Enum.KeyCode.A then
        movement.left = false
    elseif input.KeyCode == Enum.KeyCode.D then
        movement.right = false
    elseif input.KeyCode == Enum.KeyCode.Space then
        movement.up = false
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.LeftControl then
        movement.down = false
    end
end

function Fly.onTouchStart(touch, gameProcessed)
    if not Fly.flyEnabled or gameProcessed then return end
    
    mobileControls.isTouching = true
    mobileControls.touchStartPos = touch.Position
end

function Fly.onTouchMove(touch, gameProcessed)
    if not Fly.flyEnabled or gameProcessed or not mobileControls.isTouching then return end
    
    local camera = workspace.CurrentCamera
    local screenSize = camera.ViewportSize
    local touchPos = touch.Position
    
    local centerX = screenSize.X / 2
    local centerY = screenSize.Y / 2
    
    local deltaX = (touchPos.X - centerX) / (screenSize.X / 2)
    local deltaY = (touchPos.Y - centerY) / (screenSize.Y / 2)
    
    local deadZone = 0.15
    local moveX = math.abs(deltaX) > deadZone and deltaX or 0
    local moveY = math.abs(deltaY) > deadZone and deltaY or 0
    
    local cameraCFrame = camera.CFrame
    local lookVector = cameraCFrame.LookVector
    local rightVector = cameraCFrame.RightVector
    
    local moveVector = Vector3.new(0, 0, 0)
    
    if moveY < 0 then
        moveVector = moveVector + lookVector * math.abs(moveY)
    elseif moveY > 0 then
        moveVector = moveVector - lookVector * moveY
    end
    
    if moveX < 0 then
        moveVector = moveVector - rightVector * math.abs(moveX)
    elseif moveX > 0 then
        moveVector = moveVector + rightVector * moveX
    end
    
    mobileControls.moveVector = moveVector
end

function Fly.onTouchEnd(touch, gameProcessed)
    if not Fly.flyEnabled then return end
    
    mobileControls.isTouching = false
    mobileControls.moveVector = Vector3.new(0, 0, 0)
    mobileControls.touchStartPos = nil
end

function Fly.setupMobileControls()
    if not UserInputService.TouchEnabled then return end
    
    table.insert(Fly.inputConnections, UserInputService.TouchStarted:Connect(Fly.onTouchStart))
    table.insert(Fly.inputConnections, UserInputService.TouchMoved:Connect(Fly.onTouchMove))
    table.insert(Fly.inputConnections, UserInputService.TouchEnded:Connect(Fly.onTouchEnd))
end

function Fly.setupDesktopControls()
    table.insert(Fly.inputConnections, UserInputService.InputBegan:Connect(Fly.onKeyDown))
    table.insert(Fly.inputConnections, UserInputService.InputEnded:Connect(Fly.onKeyUp))
end

function Fly.setEnabled(enabled)
    Fly.flyEnabled = enabled
    
    if enabled then
        if Fly.createFlyObjects() then
            Fly.flyConnection = RunService.Heartbeat:Connect(Fly.updateMovement)
            
            Fly.cleanupConnections()
            Fly.setupDesktopControls()
            Fly.setupMobileControls()
        else
            Fly.flyEnabled = false
            return false
        end
    else
        if Fly.flyConnection then
            Fly.flyConnection:Disconnect()
            Fly.flyConnection = nil
        end
        
        Fly.cleanupConnections()
        Fly.destroyFlyObjects()
        
        for key in pairs(movement) do
            movement[key] = false
        end
        
        mobileControls.isTouching = false
        mobileControls.moveVector = Vector3.new(0, 0, 0)
    end
    
    return true
end

function Fly.setSpeed(speed)
    Fly.flySpeed = math.max(1, math.min(speed, 500))
end

function Fly.getStatus()
    if Fly.flyEnabled then
        return "Fly: Active"
    else
        return "Fly: Disabled"
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    if Fly.flyEnabled then
        wait(1)
        Fly.setEnabled(true)
    end
end)

return Fly