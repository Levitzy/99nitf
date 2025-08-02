local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

wait(2)

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then
    warn("PlayerGui not found!")
    return
end

local TreeAura, KillAura
local isMinimized = false
local mainFrame
local gui = {}

local function loadModules()
    print("Loading modules...")
    
    local success1, treeModule = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Jubiar01/99nitf/refs/heads/main/tree.lua"))()
    end)
    
    local success2, killModule = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Jubiar01/99nitf/refs/heads/main/kill.lua"))()
    end)
    
    if success1 and treeModule then
        TreeAura = treeModule
        print("✅ Tree Aura module loaded!")
    else
        print("❌ Failed to load Tree Aura module")
        TreeAura = {
            toggle = function() return false end,
            stop = function() end,
            setDistance = function() end,
            getDistance = function() return 80 end,
            isEnabled = function() return false end
        }
    end
    
    if success2 and killModule then
        KillAura = killModule
        print("✅ Kill Aura module loaded!")
    else
        print("❌ Failed to load Kill Aura module")
        KillAura = {
            toggle = function() return false end,
            stop = function() end,
            setDistance = function() end,
            getDistance = function() return 80 end,
            isEnabled = function() return false end
        }
    end
    
    print("Modules loading complete!")
    return TreeAura and KillAura
end

local function createResponsiveGUI()
    print("Creating Responsive UI...")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ResponsiveAuraGUI"
    screenGui.ResetOnSpawn = false
    
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    
    local frameWidth = isMobile and 280 or 320
    local frameHeight = isMobile and 320 or 370
    local buttonHeight = isMobile and 35 or 30
    local textSize = isMobile and 12 or 11
    
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, frameWidth, 0, frameHeight)
    mainFrame.Position = UDim2.new(0, isMobile and 20 or 50, 0, isMobile and 100 or 50)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, -3, 0, -3)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.ZIndex = mainFrame.ZIndex - 1
    shadow.Parent = mainFrame
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 15)
    shadowCorner.Parent = shadow
    
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, isMobile and 45 or 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local titleCover = Instance.new("Frame")
    titleCover.Size = UDim2.new(1, 0, 0, 20)
    titleCover.Position = UDim2.new(0, 0, 1, -20)
    titleCover.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    titleCover.BorderSizePixel = 0
    titleCover.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -80, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎯 Aura Farm v4.0"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = isMobile and 16 or 14
    titleText.Font = Enum.Font.GothamSemibold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextScaled = isMobile
    titleText.Parent = titleBar
    
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Size = UDim2.new(0, isMobile and 35 or 30, 0, isMobile and 35 or 25)
    minimizeButton.Position = UDim2.new(1, isMobile and -45 or -40, 0, isMobile and 5 or 7.5)
    minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
    minimizeButton.Text = "−"
    minimizeButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    minimizeButton.TextSize = isMobile and 18 or 16
    minimizeButton.Font = Enum.Font.GothamBold
    minimizeButton.BorderSizePixel = 0
    minimizeButton.Parent = titleBar
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 6)
    minimizeCorner.Parent = minimizeButton
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -20, 1, isMobile and -65 or -60)
    contentFrame.Position = UDim2.new(0, 10, 0, isMobile and 55 or 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    local killSection = Instance.new("Frame")
    killSection.Size = UDim2.new(1, 0, 0, isMobile and 100 or 110)
    killSection.Position = UDim2.new(0, 0, 0, 0)
    killSection.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    killSection.BorderSizePixel = 0
    killSection.Parent = contentFrame
    
    local killCorner = Instance.new("UICorner")
    killCorner.CornerRadius = UDim.new(0, 8)
    killCorner.Parent = killSection
    
    local killTitle = Instance.new("TextLabel")
    killTitle.Size = UDim2.new(1, 0, 0, isMobile and 22 or 20)
    killTitle.Position = UDim2.new(0, 0, 0, 5)
    killTitle.BackgroundTransparency = 1
    killTitle.Text = "⚔️ KILL AURA"
    killTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
    killTitle.TextSize = isMobile and 14 or 12
    killTitle.Font = Enum.Font.GothamBold
    killTitle.TextScaled = isMobile
    killTitle.Parent = killSection
    
    local killDistanceLabel = Instance.new("TextLabel")
    killDistanceLabel.Size = UDim2.new(1, 0, 0, 15)
    killDistanceLabel.Position = UDim2.new(0, 0, 0, isMobile and 25 or 22)
    killDistanceLabel.BackgroundTransparency = 1
    killDistanceLabel.Text = "Distance: " .. (KillAura and KillAura.getDistance() or 80)
    killDistanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    killDistanceLabel.TextSize = isMobile and 11 or 10
    killDistanceLabel.Font = Enum.Font.Gotham
    killDistanceLabel.TextScaled = isMobile
    killDistanceLabel.Parent = killSection
    
    local killSliderFrame = Instance.new("TextButton")
    killSliderFrame.Size = UDim2.new(1, -20, 0, isMobile and 18 or 15)
    killSliderFrame.Position = UDim2.new(0, 10, 0, isMobile and 42 or 40)
    killSliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    killSliderFrame.BorderSizePixel = 0
    killSliderFrame.Text = ""
    killSliderFrame.AutoButtonColor = false
    killSliderFrame.Parent = killSection
    
    local killSliderCorner = Instance.new("UICorner")
    killSliderCorner.CornerRadius = UDim.new(0, isMobile and 9 or 7)
    killSliderCorner.Parent = killSliderFrame
    
    local killSliderButton = Instance.new("TextButton")
    killSliderButton.Size = UDim2.new(0, isMobile and 18 or 15, 0, isMobile and 18 or 15)
    killSliderButton.Position = UDim2.new(((KillAura and KillAura.getDistance() or 80) - 10) / 190, isMobile and -9 or -7.5, 0, 0)
    killSliderButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    killSliderButton.Text = ""
    killSliderButton.BorderSizePixel = 0
    killSliderButton.AutoButtonColor = false
    killSliderButton.Parent = killSliderFrame
    
    local killSliderButtonCorner = Instance.new("UICorner")
    killSliderButtonCorner.CornerRadius = UDim.new(0, isMobile and 9 or 7)
    killSliderButtonCorner.Parent = killSliderButton
    
    local killToggleButton = Instance.new("TextButton")
    killToggleButton.Size = UDim2.new(1, -20, 0, buttonHeight)
    killToggleButton.Position = UDim2.new(0, 10, 0, isMobile and 65 or 62)
    killToggleButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    killToggleButton.Text = "🔴 KILL OFF"
    killToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    killToggleButton.TextSize = textSize
    killToggleButton.Font = Enum.Font.GothamSemibold
    killToggleButton.BorderSizePixel = 0
    killToggleButton.TextScaled = isMobile
    killToggleButton.Parent = killSection
    
    local killToggleCorner = Instance.new("UICorner")
    killToggleCorner.CornerRadius = UDim.new(0, 6)
    killToggleCorner.Parent = killToggleButton
    
    local treeSection = Instance.new("Frame")
    treeSection.Size = UDim2.new(1, 0, 0, isMobile and 100 or 110)
    treeSection.Position = UDim2.new(0, 0, 0, isMobile and 115 or 125)
    treeSection.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    treeSection.BorderSizePixel = 0
    treeSection.Parent = contentFrame
    
    local treeCorner = Instance.new("UICorner")
    treeCorner.CornerRadius = UDim.new(0, 8)
    treeCorner.Parent = treeSection
    
    local treeTitle = Instance.new("TextLabel")
    treeTitle.Size = UDim2.new(1, 0, 0, isMobile and 22 or 20)
    treeTitle.Position = UDim2.new(0, 0, 0, 5)
    treeTitle.BackgroundTransparency = 1
    treeTitle.Text = "🌳 TREE AURA"
    treeTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
    treeTitle.TextSize = isMobile and 14 or 12
    treeTitle.Font = Enum.Font.GothamBold
    treeTitle.TextScaled = isMobile
    treeTitle.Parent = treeSection
    
    local treeDistanceLabel = Instance.new("TextLabel")
    treeDistanceLabel.Size = UDim2.new(1, 0, 0, 15)
    treeDistanceLabel.Position = UDim2.new(0, 0, 0, isMobile and 25 or 22)
    treeDistanceLabel.BackgroundTransparency = 1
    treeDistanceLabel.Text = "Distance: " .. (TreeAura and TreeAura.getDistance() or 80)
    treeDistanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    treeDistanceLabel.TextSize = isMobile and 11 or 10
    treeDistanceLabel.Font = Enum.Font.Gotham
    treeDistanceLabel.TextScaled = isMobile
    treeDistanceLabel.Parent = treeSection
    
    local treeSliderFrame = Instance.new("TextButton")
    treeSliderFrame.Size = UDim2.new(1, -20, 0, isMobile and 18 or 15)
    treeSliderFrame.Position = UDim2.new(0, 10, 0, isMobile and 42 or 40)
    treeSliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    treeSliderFrame.BorderSizePixel = 0
    treeSliderFrame.Text = ""
    treeSliderFrame.AutoButtonColor = false
    treeSliderFrame.Parent = treeSection
    
    local treeSliderCorner = Instance.new("UICorner")
    treeSliderCorner.CornerRadius = UDim.new(0, isMobile and 9 or 7)
    treeSliderCorner.Parent = treeSliderFrame
    
    local treeSliderButton = Instance.new("TextButton")
    treeSliderButton.Size = UDim2.new(0, isMobile and 18 or 15, 0, isMobile and 18 or 15)
    treeSliderButton.Position = UDim2.new(((TreeAura and TreeAura.getDistance() or 80) - 10) / 190, isMobile and -9 or -7.5, 0, 0)
    treeSliderButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    treeSliderButton.Text = ""
    treeSliderButton.BorderSizePixel = 0
    treeSliderButton.AutoButtonColor = false
    treeSliderButton.Parent = treeSliderFrame
    
    local treeSliderButtonCorner = Instance.new("UICorner")
    treeSliderButtonCorner.CornerRadius = UDim.new(0, isMobile and 9 or 7)
    treeSliderButtonCorner.Parent = treeSliderButton
    
    local treeToggleButton = Instance.new("TextButton")
    treeToggleButton.Size = UDim2.new(1, -20, 0, buttonHeight)
    treeToggleButton.Position = UDim2.new(0, 10, 0, isMobile and 65 or 62)
    treeToggleButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    treeToggleButton.Text = "🔴 TREE OFF"
    treeToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    treeToggleButton.TextSize = textSize
    treeToggleButton.Font = Enum.Font.GothamSemibold
    treeToggleButton.BorderSizePixel = 0
    treeToggleButton.TextScaled = isMobile
    treeToggleButton.Parent = treeSection
    
    local treeToggleCorner = Instance.new("UICorner")
    treeToggleCorner.CornerRadius = UDim.new(0, 6)
    treeToggleCorner.Parent = treeToggleButton
    
    local destroyButton = Instance.new("TextButton")
    destroyButton.Size = UDim2.new(1, -20, 0, isMobile and 30 or 25)
    destroyButton.Position = UDim2.new(0, 10, 1, isMobile and -35 or -30)
    destroyButton.BackgroundColor3 = Color3.fromRGB(108, 117, 125)
    destroyButton.Text = "🗑️ Destroy GUI"
    destroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    destroyButton.TextSize = isMobile and 12 or 10
    destroyButton.Font = Enum.Font.Gotham
    destroyButton.BorderSizePixel = 0
    destroyButton.TextScaled = isMobile
    destroyButton.Parent = contentFrame
    
    local destroyCorner = Instance.new("UICorner")
    destroyCorner.CornerRadius = UDim.new(0, 5)
    destroyCorner.Parent = destroyButton
    
    mainFrame.Parent = screenGui
    screenGui.Parent = PlayerGui
    
    return {
        screenGui = screenGui,
        mainFrame = mainFrame,
        contentFrame = contentFrame,
        minimizeButton = minimizeButton,
        killToggleButton = killToggleButton,
        treeToggleButton = treeToggleButton,
        destroyButton = destroyButton,
        killSliderButton = killSliderButton,
        killSliderFrame = killSliderFrame,
        killDistanceLabel = killDistanceLabel,
        treeSliderButton = treeSliderButton,
        treeSliderFrame = treeSliderFrame,
        treeDistanceLabel = treeDistanceLabel,
        isMobile = isMobile
    }
end

local function toggleMinimize()
    isMinimized = not isMinimized
    
    local targetHeight = isMinimized and (gui.isMobile and 45 or 40) or (gui.isMobile and 320 or 370)
    local targetText = isMinimized and "+" or "−"
    
    local tween = TweenService:Create(
        gui.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, gui.mainFrame.Size.X.Offset, 0, targetHeight)}
    )
    
    tween:Play()
    gui.minimizeButton.Text = targetText
    gui.contentFrame.Visible = not isMinimized
    
    print(isMinimized and "GUI Minimized" or "GUI Restored")
end

local function setupSlider(sliderButton, sliderFrame, distanceLabel, auraModule)
    local isDragging = false
    
    local function updateSlider(inputX)
        local sliderFrameAbsPos = sliderFrame.AbsolutePosition.X
        local sliderFrameAbsSize = sliderFrame.AbsoluteSize.X
        
        local relativeX = math.clamp((inputX - sliderFrameAbsPos) / sliderFrameAbsSize, 0, 1)
        local newDistance = math.floor(10 + (relativeX * 190))
        
        if auraModule and auraModule.setDistance then
            auraModule.setDistance(newDistance)
        end
        distanceLabel.Text = "Distance: " .. newDistance
        sliderButton.Position = UDim2.new(relativeX, gui.isMobile and -9 or -7.5, 0, 0)
    end
    
    sliderFrame.MouseButton1Down:Connect(function(x, y)
        updateSlider(x)
    end)
    
    sliderButton.MouseButton1Down:Connect(function()
        isDragging = true
    end)
    
    if gui.isMobile then
        sliderFrame.TouchTap:Connect(function(touch, gameProcessed)
            if not gameProcessed then
                updateSlider(touch.Position.X)
            end
        end)
        
        sliderButton.TouchTap:Connect(function()
            isDragging = true
        end)
    end
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position.X)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
end

local function animateButton(button)
    local originalSize = button.Size
    local tween = TweenService:Create(
        button,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        {Size = UDim2.new(originalSize.X.Scale * 0.95, 0, originalSize.Y.Scale * 0.95, 0)}
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        local tweenBack = TweenService:Create(
            button,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {Size = originalSize}
        )
        tweenBack:Play()
    end)
end

local function main()
    print("🚀 Starting Responsive Aura Controller v4.0...")
    
    local existingGUI = PlayerGui:FindFirstChild("ResponsiveAuraGUI")
    if existingGUI then
        existingGUI:Destroy()
        wait(0.5)
    end
    
    if not loadModules() then
        warn("Modules failed to load, using fallback functions")
    end
    
    local success, result = pcall(function()
        gui = createResponsiveGUI()
        
        print("📱 Device: " .. (gui.isMobile and "Mobile" or "PC"))
        
        setupSlider(gui.killSliderButton, gui.killSliderFrame, gui.killDistanceLabel, KillAura)
        setupSlider(gui.treeSliderButton, gui.treeSliderFrame, gui.treeDistanceLabel, TreeAura)
        
        gui.minimizeButton.MouseButton1Click:Connect(function()
            toggleMinimize()
        end)
        
        if gui.isMobile then
            gui.minimizeButton.TouchTap:Connect(function()
                toggleMinimize()
            end)
        end
        
        gui.killToggleButton.MouseButton1Click:Connect(function()
            print("Kill button clicked!")
            animateButton(gui.killToggleButton)
            
            local isEnabled = false
            if KillAura and KillAura.toggle then
                isEnabled = KillAura.toggle()
            end
            
            if isEnabled then
                gui.killToggleButton.Text = "🟢 KILL ON"
                gui.killToggleButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
            else
                gui.killToggleButton.Text = "🔴 KILL OFF"
                gui.killToggleButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
            end
        end)
        
        gui.treeToggleButton.MouseButton1Click:Connect(function()
            print("Tree button clicked!")
            animateButton(gui.treeToggleButton)
            
            local isEnabled = false
            if TreeAura and TreeAura.toggle then
                isEnabled = TreeAura.toggle()
            end
            
            if isEnabled then
                gui.treeToggleButton.Text = "🟢 TREE ON"
                gui.treeToggleButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
            else
                gui.treeToggleButton.Text = "🔴 TREE OFF"
                gui.treeToggleButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
            end
        end)
        
        gui.destroyButton.MouseButton1Click:Connect(function()
            print("Destroying GUI...")
            if KillAura and KillAura.stop then KillAura.stop() end
            if TreeAura and TreeAura.stop then TreeAura.stop() end
            gui.screenGui:Destroy()
        end)
        
        print("✅ Responsive Aura Controller v4.0 loaded successfully!")
        print("💡 Click the − button to minimize/restore the GUI")
    end)
    
    if not success then
        warn("Failed to create main GUI: " .. tostring(result))
    end
end

main()
