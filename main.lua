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

local TreeAura = loadstring(game:HttpGet("https://your-url-here/tree.lua"))()
local KillAura = loadstring(game:HttpGet("https://your-url-here/kill.lua"))()

local mainFrame
local gui = {}

local function createFluentGUI()
    print("Creating Main Fluent UI...")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FluentKillAuraGUI"
    screenGui.ResetOnSpawn = false
    
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 350)
    mainFrame.Position = UDim2.new(0, 50, 0, 50)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local titleCover = Instance.new("Frame")
    titleCover.Size = UDim2.new(1, 0, 0, 20)
    titleCover.Position = UDim2.new(0, 0, 1, -20)
    titleCover.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    titleCover.BorderSizePixel = 0
    titleCover.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -50, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Kill & Tree Aura Farm v3.0"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 14
    titleText.Font = Enum.Font.GothamSemibold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 25, 0, 25)
    closeButton.Position = UDim2.new(1, -35, 0, 7.5)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 12
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    local killSection = Instance.new("Frame")
    killSection.Size = UDim2.new(1, -20, 0, 110)
    killSection.Position = UDim2.new(0, 10, 0, 50)
    killSection.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    killSection.BorderSizePixel = 0
    killSection.Parent = mainFrame
    
    local killCorner = Instance.new("UICorner")
    killCorner.CornerRadius = UDim.new(0, 8)
    killCorner.Parent = killSection
    
    local killTitle = Instance.new("TextLabel")
    killTitle.Size = UDim2.new(1, 0, 0, 25)
    killTitle.Position = UDim2.new(0, 0, 0, 5)
    killTitle.BackgroundTransparency = 1
    killTitle.Text = "KILL AURA"
    killTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
    killTitle.TextSize = 12
    killTitle.Font = Enum.Font.GothamBold
    killTitle.Parent = killSection
    
    local killDistanceLabel = Instance.new("TextLabel")
    killDistanceLabel.Size = UDim2.new(1, 0, 0, 15)
    killDistanceLabel.Position = UDim2.new(0, 0, 0, 25)
    killDistanceLabel.BackgroundTransparency = 1
    killDistanceLabel.Text = "Distance: " .. KillAura.getDistance()
    killDistanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    killDistanceLabel.TextSize = 10
    killDistanceLabel.Font = Enum.Font.Gotham
    killDistanceLabel.Parent = killSection
    
    local killSliderFrame = Instance.new("TextButton")
    killSliderFrame.Size = UDim2.new(1, -20, 0, 15)
    killSliderFrame.Position = UDim2.new(0, 10, 0, 45)
    killSliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    killSliderFrame.BorderSizePixel = 0
    killSliderFrame.Text = ""
    killSliderFrame.AutoButtonColor = false
    killSliderFrame.Parent = killSection
    
    local killSliderCorner = Instance.new("UICorner")
    killSliderCorner.CornerRadius = UDim.new(0, 7)
    killSliderCorner.Parent = killSliderFrame
    
    local killSliderButton = Instance.new("TextButton")
    killSliderButton.Size = UDim2.new(0, 15, 0, 15)
    killSliderButton.Position = UDim2.new((KillAura.getDistance() - 10) / 190, -7.5, 0, 0)
    killSliderButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    killSliderButton.Text = ""
    killSliderButton.BorderSizePixel = 0
    killSliderButton.AutoButtonColor = false
    killSliderButton.Parent = killSliderFrame
    
    local killSliderButtonCorner = Instance.new("UICorner")
    killSliderButtonCorner.CornerRadius = UDim.new(0, 7)
    killSliderButtonCorner.Parent = killSliderButton
    
    local killToggleButton = Instance.new("TextButton")
    killToggleButton.Size = UDim2.new(1, -20, 0, 30)
    killToggleButton.Position = UDim2.new(0, 10, 0, 70)
    killToggleButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    killToggleButton.Text = "KILL OFF"
    killToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    killToggleButton.TextSize = 11
    killToggleButton.Font = Enum.Font.GothamSemibold
    killToggleButton.BorderSizePixel = 0
    killToggleButton.Parent = killSection
    
    local killToggleCorner = Instance.new("UICorner")
    killToggleCorner.CornerRadius = UDim.new(0, 6)
    killToggleCorner.Parent = killToggleButton
    
    local treeSection = Instance.new("Frame")
    treeSection.Size = UDim2.new(1, -20, 0, 110)
    treeSection.Position = UDim2.new(0, 10, 0, 170)
    treeSection.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    treeSection.BorderSizePixel = 0
    treeSection.Parent = mainFrame
    
    local treeCorner = Instance.new("UICorner")
    treeCorner.CornerRadius = UDim.new(0, 8)
    treeCorner.Parent = treeSection
    
    local treeTitle = Instance.new("TextLabel")
    treeTitle.Size = UDim2.new(1, 0, 0, 25)
    treeTitle.Position = UDim2.new(0, 0, 0, 5)
    treeTitle.BackgroundTransparency = 1
    treeTitle.Text = "TREE AURA"
    treeTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
    treeTitle.TextSize = 12
    treeTitle.Font = Enum.Font.GothamBold
    treeTitle.Parent = treeSection
    
    local treeDistanceLabel = Instance.new("TextLabel")
    treeDistanceLabel.Size = UDim2.new(1, 0, 0, 15)
    treeDistanceLabel.Position = UDim2.new(0, 0, 0, 25)
    treeDistanceLabel.BackgroundTransparency = 1
    treeDistanceLabel.Text = "Distance: " .. TreeAura.getDistance()
    treeDistanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    treeDistanceLabel.TextSize = 10
    treeDistanceLabel.Font = Enum.Font.Gotham
    treeDistanceLabel.Parent = treeSection
    
    local treeSliderFrame = Instance.new("TextButton")
    treeSliderFrame.Size = UDim2.new(1, -20, 0, 15)
    treeSliderFrame.Position = UDim2.new(0, 10, 0, 45)
    treeSliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    treeSliderFrame.BorderSizePixel = 0
    treeSliderFrame.Text = ""
    treeSliderFrame.AutoButtonColor = false
    treeSliderFrame.Parent = treeSection
    
    local treeSliderCorner = Instance.new("UICorner")
    treeSliderCorner.CornerRadius = UDim.new(0, 7)
    treeSliderCorner.Parent = treeSliderFrame
    
    local treeSliderButton = Instance.new("TextButton")
    treeSliderButton.Size = UDim2.new(0, 15, 0, 15)
    treeSliderButton.Position = UDim2.new((TreeAura.getDistance() - 10) / 190, -7.5, 0, 0)
    treeSliderButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    treeSliderButton.Text = ""
    treeSliderButton.BorderSizePixel = 0
    treeSliderButton.AutoButtonColor = false
    treeSliderButton.Parent = treeSliderFrame
    
    local treeSliderButtonCorner = Instance.new("UICorner")
    treeSliderButtonCorner.CornerRadius = UDim.new(0, 7)
    treeSliderButtonCorner.Parent = treeSliderButton
    
    local treeToggleButton = Instance.new("TextButton")
    treeToggleButton.Size = UDim2.new(1, -20, 0, 30)
    treeToggleButton.Position = UDim2.new(0, 10, 0, 70)
    treeToggleButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    treeToggleButton.Text = "TREE OFF"
    treeToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    treeToggleButton.TextSize = 11
    treeToggleButton.Font = Enum.Font.GothamSemibold
    treeToggleButton.BorderSizePixel = 0
    treeToggleButton.Parent = treeSection
    
    local treeToggleCorner = Instance.new("UICorner")
    treeToggleCorner.CornerRadius = UDim.new(0, 6)
    treeToggleCorner.Parent = treeToggleButton
    
    local destroyButton = Instance.new("TextButton")
    destroyButton.Size = UDim2.new(1, -20, 0, 25)
    destroyButton.Position = UDim2.new(0, 10, 0, 290)
    destroyButton.BackgroundColor3 = Color3.fromRGB(108, 117, 125)
    destroyButton.Text = "Destroy GUI"
    destroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    destroyButton.TextSize = 10
    destroyButton.Font = Enum.Font.Gotham
    destroyButton.BorderSizePixel = 0
    destroyButton.Parent = mainFrame
    
    local destroyCorner = Instance.new("UICorner")
    destroyCorner.CornerRadius = UDim.new(0, 5)
    destroyCorner.Parent = destroyButton
    
    mainFrame.Parent = screenGui
    screenGui.Parent = PlayerGui
    
    return {
        screenGui = screenGui,
        killToggleButton = killToggleButton,
        treeToggleButton = treeToggleButton,
        closeButton = closeButton,
        destroyButton = destroyButton,
        killSliderButton = killSliderButton,
        killSliderFrame = killSliderFrame,
        killDistanceLabel = killDistanceLabel,
        treeSliderButton = treeSliderButton,
        treeSliderFrame = treeSliderFrame,
        treeDistanceLabel = treeDistanceLabel
    }
end

local function setupSlider(sliderButton, sliderFrame, distanceLabel, auraModule)
    local isDragging = false
    
    local function updateSlider(inputX)
        local sliderFrameAbsPos = sliderFrame.AbsolutePosition.X
        local sliderFrameAbsSize = sliderFrame.AbsoluteSize.X
        
        local relativeX = math.clamp((inputX - sliderFrameAbsPos) / sliderFrameAbsSize, 0, 1)
        local newDistance = math.floor(10 + (relativeX * 190))
        
        auraModule.setDistance(newDistance)
        distanceLabel.Text = "Distance: " .. newDistance
        sliderButton.Position = UDim2.new(relativeX, -7.5, 0, 0)
    end
    
    sliderFrame.MouseButton1Down:Connect(function(x, y)
        updateSlider(x)
    end)
    
    sliderButton.MouseButton1Down:Connect(function()
        isDragging = true
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input.Position.X)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
end

local function animateButton(button)
    local originalSize = button.Size
    local tween = TweenService:Create(
        button,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        {Size = UDim2.new(originalSize.X.Scale * 0.96, 0, originalSize.Y.Scale * 0.96, 0)}
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
    print("Starting Main Aura Controller v3.0...")
    
    local existingGUI = PlayerGui:FindFirstChild("FluentKillAuraGUI")
    if existingGUI then
        existingGUI:Destroy()
        wait(0.5)
    end
    
    local success, result = pcall(function()
        gui = createFluentGUI()
        
        setupSlider(gui.killSliderButton, gui.killSliderFrame, gui.killDistanceLabel, KillAura)
        setupSlider(gui.treeSliderButton, gui.treeSliderFrame, gui.treeDistanceLabel, TreeAura)
        
        gui.killToggleButton.MouseButton1Click:Connect(function()
            print("Kill button clicked!")
            animateButton(gui.killToggleButton)
            
            local isEnabled = KillAura.toggle()
            if isEnabled then
                gui.killToggleButton.Text = "KILL ON"
                gui.killToggleButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
            else
                gui.killToggleButton.Text = "KILL OFF"
                gui.killToggleButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
            end
        end)
        
        gui.treeToggleButton.MouseButton1Click:Connect(function()
            print("Tree button clicked!")
            animateButton(gui.treeToggleButton)
            
            local isEnabled = TreeAura.toggle()
            if isEnabled then
                gui.treeToggleButton.Text = "TREE ON"
                gui.treeToggleButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
            else
                gui.treeToggleButton.Text = "TREE OFF"
                gui.treeToggleButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
            end
        end)
        
        local function destroyGUI()
            print("Destroying GUI...")
            KillAura.stop()
            TreeAura.stop()
            gui.screenGui:Destroy()
        end
        
        gui.closeButton.MouseButton1Click:Connect(destroyGUI)
        gui.destroyButton.MouseButton1Click:Connect(destroyGUI)
        
        print("Main Controller loaded successfully!")
    end)
    
    if not success then
        warn("Failed to create main GUI: " .. tostring(result))
    end
end

main()
