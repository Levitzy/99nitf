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

local function createCleanGUI()
    print("Creating Clean Premium UI...")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PremiumAuraGUI"
    screenGui.ResetOnSpawn = false
    
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    
    local frameWidth = isMobile and 300 or 340
    local frameHeight = isMobile and 400 or 450
    
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, frameWidth, 0, frameHeight)
    mainFrame.Position = UDim2.new(0, isMobile and 30 or 60, 0, isMobile and 80 or 40)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = mainFrame
    
    local borderFrame = Instance.new("Frame")
    borderFrame.Size = UDim2.new(1, 4, 1, 4)
    borderFrame.Position = UDim2.new(0, -2, 0, -2)
    borderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    borderFrame.ZIndex = mainFrame.ZIndex - 1
    borderFrame.Parent = mainFrame
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 18)
    borderCorner.Parent = borderFrame
    
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 12, 1, 12)
    shadow.Position = UDim2.new(0, -6, 0, -6)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.6
    shadow.ZIndex = mainFrame.ZIndex - 2
    shadow.Parent = mainFrame
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 22)
    shadowCorner.Parent = shadow
    
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, isMobile and 60 or 55)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 16)
    titleCorner.Parent = titleBar
    
    local titleCover = Instance.new("Frame")
    titleCover.Size = UDim2.new(1, 0, 0, 28)
    titleCover.Position = UDim2.new(0, 0, 1, -28)
    titleCover.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    titleCover.BorderSizePixel = 0
    titleCover.Parent = titleBar
    
    local titleIcon = Instance.new("TextLabel")
    titleIcon.Size = UDim2.new(0, 30, 0, 30)
    titleIcon.Position = UDim2.new(0, 15, 0, isMobile and 15 or 12)
    titleIcon.BackgroundTransparency = 1
    titleIcon.Text = "🎯"
    titleIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleIcon.TextSize = isMobile and 20 or 18
    titleIcon.Font = Enum.Font.GothamBold
    titleIcon.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -120, 1, 0)
    titleText.Position = UDim2.new(0, 50, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Aura Farm Pro"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = isMobile and 18 or 16
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(0, 40, 0, 15)
    versionLabel.Position = UDim2.new(0, 50, 0, isMobile and 30 or 28)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "v5.0"
    versionLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    versionLabel.TextSize = isMobile and 12 or 10
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.TextXAlignment = Enum.TextXAlignment.Left
    versionLabel.Parent = titleBar
    
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Size = UDim2.new(0, isMobile and 40 or 35, 0, isMobile and 40 or 30)
    minimizeButton.Position = UDim2.new(1, isMobile and -50 or -45, 0, isMobile and 10 or 12)
    minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
    minimizeButton.Text = "−"
    minimizeButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    minimizeButton.TextSize = isMobile and 20 or 18
    minimizeButton.Font = Enum.Font.GothamBold
    minimizeButton.BorderSizePixel = 0
    minimizeButton.Parent = titleBar
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 8)
    minimizeCorner.Parent = minimizeButton
    
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -30, 1, isMobile and -90 or -85)
    contentFrame.Position = UDim2.new(0, 15, 0, isMobile and 75 or 70)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 6
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 85)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, isMobile and 350 or 360)
    contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    contentFrame.Parent = mainFrame
    
    local killSection = Instance.new("Frame")
    killSection.Size = UDim2.new(1, 0, 0, isMobile and 130 or 140)
    killSection.Position = UDim2.new(0, 0, 0, 0)
    killSection.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    killSection.BorderSizePixel = 0
    killSection.Parent = contentFrame
    
    local killCorner = Instance.new("UICorner")
    killCorner.CornerRadius = UDim.new(0, 12)
    killCorner.Parent = killSection
    
    local killAccent = Instance.new("Frame")
    killAccent.Size = UDim2.new(0, 4, 1, 0)
    killAccent.Position = UDim2.new(0, 0, 0, 0)
    killAccent.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    killAccent.BorderSizePixel = 0
    killAccent.Parent = killSection
    
    local killAccentCorner = Instance.new("UICorner")
    killAccentCorner.CornerRadius = UDim.new(0, 2)
    killAccentCorner.Parent = killAccent
    
    local killTitle = Instance.new("TextLabel")
    killTitle.Size = UDim2.new(1, -20, 0, 30)
    killTitle.Position = UDim2.new(0, 15, 0, 10)
    killTitle.BackgroundTransparency = 1
    killTitle.Text = "⚔️ KILL AURA"
    killTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    killTitle.TextSize = isMobile and 16 or 14
    killTitle.Font = Enum.Font.GothamBold
    killTitle.TextXAlignment = Enum.TextXAlignment.Left
    killTitle.Parent = killSection
    
    local killDistanceLabel = Instance.new("TextLabel")
    killDistanceLabel.Size = UDim2.new(1, -20, 0, 20)
    killDistanceLabel.Position = UDim2.new(0, 15, 0, 40)
    killDistanceLabel.BackgroundTransparency = 1
    killDistanceLabel.Text = "Distance: " .. (KillAura and KillAura.getDistance() or 80)
    killDistanceLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    killDistanceLabel.TextSize = isMobile and 14 or 12
    killDistanceLabel.Font = Enum.Font.Gotham
    killDistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    killDistanceLabel.Parent = killSection
    
    local killSliderFrame = Instance.new("TextButton")
    killSliderFrame.Size = UDim2.new(1, -30, 0, isMobile and 25 or 20)
    killSliderFrame.Position = UDim2.new(0, 15, 0, isMobile and 65 or 65)
    killSliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    killSliderFrame.BorderSizePixel = 0
    killSliderFrame.Text = ""
    killSliderFrame.AutoButtonColor = false
    killSliderFrame.Parent = killSection
    
    local killSliderCorner = Instance.new("UICorner")
    killSliderCorner.CornerRadius = UDim.new(0, isMobile and 12 or 10)
    killSliderCorner.Parent = killSliderFrame
    
    local killSliderButton = Instance.new("TextButton")
    killSliderButton.Size = UDim2.new(0, isMobile and 25 or 20, 0, isMobile and 25 or 20)
    killSliderButton.Position = UDim2.new(((KillAura and KillAura.getDistance() or 80) - 10) / 190, isMobile and -12 or -10, 0, 0)
    killSliderButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    killSliderButton.Text = ""
    killSliderButton.BorderSizePixel = 0
    killSliderButton.AutoButtonColor = false
    killSliderButton.Parent = killSliderFrame
    
    local killSliderButtonCorner = Instance.new("UICorner")
    killSliderButtonCorner.CornerRadius = UDim.new(0, isMobile and 12 or 10)
    killSliderButtonCorner.Parent = killSliderButton
    
    local killToggleButton = Instance.new("TextButton")
    killToggleButton.Size = UDim2.new(1, -30, 0, isMobile and 40 or 35)
    killToggleButton.Position = UDim2.new(0, 15, 0, isMobile and 95 or 90)
    killToggleButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    killToggleButton.Text = "🔴 KILL OFF"
    killToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    killToggleButton.TextSize = isMobile and 16 or 14
    killToggleButton.Font = Enum.Font.GothamBold
    killToggleButton.BorderSizePixel = 0
    killToggleButton.Parent = killSection
    
    local killToggleCorner = Instance.new("UICorner")
    killToggleCorner.CornerRadius = UDim.new(0, 10)
    killToggleCorner.Parent = killToggleButton
    
    local treeSection = Instance.new("Frame")
    treeSection.Size = UDim2.new(1, 0, 0, isMobile and 130 or 140)
    treeSection.Position = UDim2.new(0, 0, 0, isMobile and 145 or 155)
    treeSection.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    treeSection.BorderSizePixel = 0
    treeSection.Parent = contentFrame
    
    local treeCorner = Instance.new("UICorner")
    treeCorner.CornerRadius = UDim.new(0, 12)
    treeCorner.Parent = treeSection
    
    local treeAccent = Instance.new("Frame")
    treeAccent.Size = UDim2.new(0, 4, 1, 0)
    treeAccent.Position = UDim2.new(0, 0, 0, 0)
    treeAccent.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
    treeAccent.BorderSizePixel = 0
    treeAccent.Parent = treeSection
    
    local treeAccentCorner = Instance.new("UICorner")
    treeAccentCorner.CornerRadius = UDim.new(0, 2)
    treeAccentCorner.Parent = treeAccent
    
    local treeTitle = Instance.new("TextLabel")
    treeTitle.Size = UDim2.new(1, -20, 0, 30)
    treeTitle.Position = UDim2.new(0, 15, 0, 10)
    treeTitle.BackgroundTransparency = 1
    treeTitle.Text = "🌳 TREE AURA"
    treeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    treeTitle.TextSize = isMobile and 16 or 14
    treeTitle.Font = Enum.Font.GothamBold
    treeTitle.TextXAlignment = Enum.TextXAlignment.Left
    treeTitle.Parent = treeSection
    
    local treeDistanceLabel = Instance.new("TextLabel")
    treeDistanceLabel.Size = UDim2.new(1, -20, 0, 20)
    treeDistanceLabel.Position = UDim2.new(0, 15, 0, 40)
    treeDistanceLabel.BackgroundTransparency = 1
    treeDistanceLabel.Text = "Distance: " .. (TreeAura and TreeAura.getDistance() or 80)
    treeDistanceLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    treeDistanceLabel.TextSize = isMobile and 14 or 12
    treeDistanceLabel.Font = Enum.Font.Gotham
    treeDistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    treeDistanceLabel.Parent = treeSection
    
    local treeSliderFrame = Instance.new("TextButton")
    treeSliderFrame.Size = UDim2.new(1, -30, 0, isMobile and 25 or 20)
    treeSliderFrame.Position = UDim2.new(0, 15, 0, isMobile and 65 or 65)
    treeSliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    treeSliderFrame.BorderSizePixel = 0
    treeSliderFrame.Text = ""
    treeSliderFrame.AutoButtonColor = false
    treeSliderFrame.Parent = treeSection
    
    local treeSliderCorner = Instance.new("UICorner")
    treeSliderCorner.CornerRadius = UDim.new(0, isMobile and 12 or 10)
    treeSliderCorner.Parent = treeSliderFrame
    
    local treeSliderButton = Instance.new("TextButton")
    treeSliderButton.Size = UDim2.new(0, isMobile and 25 or 20, 0, isMobile and 25 or 20)
    treeSliderButton.Position = UDim2.new(((TreeAura and TreeAura.getDistance() or 80) - 10) / 190, isMobile and -12 or -10, 0, 0)
    treeSliderButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
    treeSliderButton.Text = ""
    treeSliderButton.BorderSizePixel = 0
    treeSliderButton.AutoButtonColor = false
    treeSliderButton.Parent = treeSliderFrame
    
    local treeSliderButtonCorner = Instance.new("UICorner")
    treeSliderButtonCorner.CornerRadius = UDim.new(0, isMobile and 12 or 10)
    treeSliderButtonCorner.Parent = treeSliderButton
    
    local treeToggleButton = Instance.new("TextButton")
    treeToggleButton.Size = UDim2.new(1, -30, 0, isMobile and 40 or 35)
    treeToggleButton.Position = UDim2.new(0, 15, 0, isMobile and 95 or 90)
    treeToggleButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    treeToggleButton.Text = "🔴 TREE OFF"
    treeToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    treeToggleButton.TextSize = isMobile and 16 or 14
    treeToggleButton.Font = Enum.Font.GothamBold
    treeToggleButton.BorderSizePixel = 0
    treeToggleButton.Parent = treeSection
    
    local treeToggleCorner = Instance.new("UICorner")
    treeToggleCorner.CornerRadius = UDim.new(0, 10)
    treeToggleCorner.Parent = treeToggleButton
    
    local destroyButton = Instance.new("TextButton")
    destroyButton.Size = UDim2.new(1, 0, 0, isMobile and 35 or 30)
    destroyButton.Position = UDim2.new(0, 0, 0, isMobile and 290 or 300)
    destroyButton.BackgroundColor3 = Color3.fromRGB(108, 117, 125)
    destroyButton.Text = "🗑️ Destroy GUI"
    destroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    destroyButton.TextSize = isMobile and 14 or 12
    destroyButton.Font = Enum.Font.GothamSemibold
    destroyButton.BorderSizePixel = 0
    destroyButton.Parent = contentFrame
    
    local destroyCorner = Instance.new("UICorner")
    destroyCorner.CornerRadius = UDim.new(0, 8)
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
    
    local targetHeight = isMinimized and (gui.isMobile and 60 or 55) or (gui.isMobile and 400 or 450)
    local targetText = isMinimized and "+" or "−"
    
    if isMinimized then
        gui.contentFrame.Visible = false
        wait(0.1)
        local tween = TweenService:Create(
            gui.mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, gui.mainFrame.Size.X.Offset, 0, targetHeight)}
        )
        tween:Play()
    else
        local tween = TweenService:Create(
            gui.mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, gui.mainFrame.Size.X.Offset, 0, targetHeight)}
        )
        tween:Play()
        tween.Completed:Connect(function()
            wait(0.1)
            gui.contentFrame.Visible = true
        end)
    end
    
    gui.minimizeButton.Text = targetText
    print(isMinimized and "🔽 GUI Minimized" or "🔼 GUI Restored")
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
        sliderButton.Position = UDim2.new(relativeX, gui.isMobile and -12 or -10, 0, 0)
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
    local originalColor = button.BackgroundColor3
    
    local tween1 = TweenService:Create(
        button,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        {
            Size = UDim2.new(originalSize.X.Scale * 0.95, 0, originalSize.Y.Scale * 0.95, 0),
            BackgroundColor3 = Color3.new(originalColor.R * 0.8, originalColor.G * 0.8, originalColor.B * 0.8)
        }
    )
    tween1:Play()
    
    tween1.Completed:Connect(function()
        local tween2 = TweenService:Create(
            button,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {
                Size = originalSize,
                BackgroundColor3 = originalColor
            }
        )
        tween2:Play()
    end)
end

local function main()
    print("🚀 Starting Premium Aura Controller v5.0...")
    
    local existingGUI = PlayerGui:FindFirstChild("PremiumAuraGUI")
    if existingGUI then
        existingGUI:Destroy()
        wait(0.5)
    end
    
    if not loadModules() then
        warn("Modules failed to load, using fallback functions")
    end
    
    local success, result = pcall(function()
        gui = createCleanGUI()
        
        print("📱 Device: " .. (gui.isMobile and "Mobile" or "PC"))
        
        setupSlider(gui.killSliderButton, gui.killSliderFrame, gui.killDistanceLabel, KillAura)
        setupSlider(gui.treeSliderButton, gui.treeSliderFrame, gui.treeDistanceLabel, TreeAura)
        
        gui.minimizeButton.MouseButton1Click:Connect(function()
            print("🔄 Minimize button clicked!")
            toggleMinimize()
        end)
        
        if gui.isMobile then
            gui.minimizeButton.TouchTap:Connect(function()
                print("🔄 Minimize button touched!")
                toggleMinimize()
            end)
        end
        
        gui.killToggleButton.MouseButton1Click:Connect(function()
            print("⚔️ Kill button clicked!")
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
            print("🌳 Tree button clicked!")
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
            print("🗑️ Destroying GUI...")
            if KillAura and KillAura.stop then KillAura.stop() end
            if TreeAura and TreeAura.stop then TreeAura.stop() end
            gui.screenGui:Destroy()
        end)
        
        print("✨ Premium Aura Controller v5.0 loaded successfully!")
        print("💡 Click the − button to minimize/restore the GUI")
    end)
    
    if not success then
        warn("Failed to create premium GUI: " .. tostring(result))
    end
end

main()
