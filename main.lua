local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()
local Fly = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/fly.lua'))()

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()

local Window = Library:CreateWindow({
    Title = 'Multi-Tool Bot Suite',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local MainTab = Window:AddTab('Fly')
local TreeTab = Window:AddTab('Tree Chopper') 
local FuelTab = Window:AddTab('Auto Fuel')
local UtilityTab = Window:AddTab('Utilities')

local RunService = game:GetService("RunService")

local FlyGroup = MainTab:AddLeftGroupbox('Flight Controls')

local FlyToggle = FlyGroup:AddToggle('FlyToggle', {
    Text = 'Enable Fly',
    Default = false,
    Tooltip = 'Activate flight mode with WASD controls',
    Callback = function(Value)
        local success = Fly.setEnabled(Value)
        
        if Value and success then
            Library:Notify('Fly Enabled - PC: WASD + Space/Shift | Mobile: Touch & drag', 4)
        elseif Value and not success then
            Library:Notify('Fly Failed - Character not found!', 3) 
        else
            Library:Notify('Fly Disabled', 2)
        end
    end
})

local FlySpeedSlider = FlyGroup:AddSlider('FlySpeed', {
    Text = 'Fly Speed',
    Default = 50,
    Min = 1,
    Max = 200,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        Fly.setSpeed(Value)
    end
})

local TreeGroup = TreeTab:AddLeftGroupbox('Tree Chopper')

local TreeToggle = TreeGroup:AddToggle('TreeToggle', {
    Text = 'Auto Chop Trees',
    Default = false,
    Tooltip = 'Automatically chop all small trees on the map',
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        
        if Value then
            Library:Notify('Tree Chopper Enabled - Chopping all small trees!', 3)
        else
            Library:Notify('Tree Chopper Disabled', 3)
        end
    end
})

local TreeDelayDropdown = TreeGroup:AddDropdown('TreeDelay', {
    Values = {'0.1s', '0.5s', '1s', '2s', '3s', '5s'},
    Default = '1s',
    Multi = false,
    Text = 'Chop Delay',
    Tooltip = 'Time between tree chopping cycles',
    Callback = function(Value)
        local delayMap = {
            ['0.1s'] = 0.1,
            ['0.5s'] = 0.5,
            ['1s'] = 1,
            ['2s'] = 2,
            ['3s'] = 3,
            ['5s'] = 5
        }
        local delay = delayMap[Value] or 1
        TreeChopper.setChopDelay(delay)
    end
})

local TreeStatusGroup = TreeTab:AddRightGroupbox('Status')
local TreeStatusLabel = TreeStatusGroup:AddLabel('Status: Ready - Processes 5 trees per cycle')

local FuelGroup = FuelTab:AddLeftGroupbox('Auto Fuel')

local FuelToggle = FuelGroup:AddToggle('FuelToggle', {
    Text = 'Auto Fuel Collection',
    Default = false,
    Tooltip = 'Teleport fuel items to position (0,4,-3)',
    Callback = function(Value)
        AutoFuel.setEnabled(Value)
        
        if Value then
            Library:Notify('Auto Fuel Enabled - Teleporting to (0,4,-3)!', 3)
        else
            Library:Notify('Auto Fuel Disabled', 3)
        end
    end
})

local FuelStatusGroup = FuelTab:AddRightGroupbox('Status')
local FuelStatusLabel = FuelStatusGroup:AddLabel('Status: Ready - 1.0s delay, stacks at (0,4,-3)')

local ComboGroup = UtilityTab:AddLeftGroupbox('Combo Controls')

local ComboToggle = ComboGroup:AddToggle('ComboToggle', {
    Text = 'Tree + Fuel Combo',
    Default = false,
    Tooltip = 'Enable both Tree Chopper and Auto Fuel together',
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        AutoFuel.setEnabled(Value)
        
        if Value then
            Library:Notify('Combo Bot Enabled - Both systems active!', 4)
        else
            Library:Notify('Combo Bot Disabled', 3)
        end
    end
})

local ComboStatusGroup = UtilityTab:AddRightGroupbox('Status')
local ComboStatusLabel = ComboStatusGroup:AddLabel('Both bots disabled')

RunService.Heartbeat:Connect(function()
    local treeStatus, treeCount, closestDistance = TreeChopper.getStatus()
    TreeStatusLabel:SetText(treeStatus)
    
    local fuelStatus, distance = AutoFuel.getStatus()
    FuelStatusLabel:SetText(fuelStatus)
    
    local chopEnabled = TreeChopper.autoChopEnabled
    local fuelEnabled = AutoFuel.autoFuelEnabled
    
    if chopEnabled and fuelEnabled then
        ComboStatusLabel:SetText('Both bots active - Chopping & Fueling')
    elseif chopEnabled then
        ComboStatusLabel:SetText('Only Tree Chopper active')
    elseif fuelEnabled then
        ComboStatusLabel:SetText('Only Auto Fuel active')
    else
        ComboStatusLabel:SetText('Both bots disabled')
    end
end)

Library:Notify('Multi-Tool Bot Suite Loaded - Clean UI with fly-focused main tab!', 6)

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder('MultiToolThemes')
ThemeManager:ApplyToTab(UtilityTab)