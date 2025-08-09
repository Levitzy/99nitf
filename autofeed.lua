local AutoFeed = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoFeed.autoFeedEnabled = false
AutoFeed.feedThreshold = 80
AutoFeed.feedDelay = 3.0
AutoFeed.feedConnection = nil
AutoFeed.lastFeedTime = 0

function AutoFeed.getHungerPercentage()
    local attempts = {
        function()
            local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
            local interface = playerGui.Interface
            local statBars = interface.StatBars
            local hungerBar = statBars.HungerBar
            local bar = hungerBar.Bar
            
            if bar and bar.Size and bar.Size.X then
                local scale = bar.Size.X.Scale
                return math.floor(scale * 100)
            end
            return nil
        end,
        
        function()
            local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            local interface = playerGui:WaitForChild("Interface")
            local statBars = interface:WaitForChild("StatBars")
            local hungerBar = statBars:WaitForChild("HungerBar")
            local bar = hungerBar:WaitForChild("Bar")
            
            if bar and bar.Size and bar.Size.X then
                local scale = bar.Size.X.Scale
                return math.floor(scale * 100)
            end
            return nil
        end,
        
        function()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if not playerGui then return nil end
            
            local interface = playerGui:FindFirstChild("Interface")
            if not interface then return nil end
            
            local statBars = interface:FindFirstChild("StatBars")
            if not statBars then return nil end
            
            local hungerBar = statBars:FindFirstChild("HungerBar")
            if not hungerBar then return nil end
            
            local bar = hungerBar:FindFirstChild("Bar")
            if not bar then return nil end
            
            if bar.Size and bar.Size.X then
                local scale = bar.Size.X.Scale
                return math.floor(scale * 100)
            end
            return nil
        end
    }
    
    for i, method in pairs(attempts) do
        local success, result = pcall(method)
        if success and result and result > 0 then
            return math.max(0, math.min(100, result))
        end
    end
    
    return 0
end

function AutoFeed.findCookedFood()
    local workspace = game:GetService("Workspace")
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if not itemsFolder then return {} end
    
    local cookedSteaks = {}
    local cookedMorsels = {}
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item and item.Parent then
            if item.Name == "Cooked Steak" then
                table.insert(cookedSteaks, item)
            elseif item.Name == "Cooked Morsel" then
                table.insert(cookedMorsels, item)
            end
        end
    end
    
    -- Prioritize steaks over morsels (steaks likely give more hunger)
    local allFood = {}
    for _, steak in pairs(cookedSteaks) do
        table.insert(allFood, steak)
    end
    for _, morsel in pairs(cookedMorsels) do
        table.insert(allFood, morsel)
    end
    
    return allFood
end

function AutoFeed.listAllRemoteEvents()
    print("AutoFeed Debug - ========== LISTING ALL REMOTE EVENTS ==========")
    local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
    
    for _, child in pairs(remoteEvents:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            print("AutoFeed Debug - Found " .. child.ClassName .. ": " .. child.Name)
        end
    end
    
    print("AutoFeed Debug - ========== END REMOTE EVENTS LIST ==========")
end

function AutoFeed.consumeItem(item)
    if not item or not item.Parent then
        return false
    end
    
    local preHunger = AutoFeed.getHungerPercentage()
    
    -- METHOD 2: Direct item reference (this one works!)
    local success = pcall(function()
        local result = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(item)
    end)
    
    if success then
        wait(0.2)
        local postHunger = AutoFeed.getHungerPercentage()
        if postHunger > preHunger then
            print("AutoFeed: Successfully ate " .. item.Name .. " - Hunger: " .. preHunger .. "% -> " .. postHunger .. "%")
            return true
        end
    end
    
    return false
end

function AutoFeed.shouldFeed()
    local currentHunger = AutoFeed.getHungerPercentage()
    
    if currentHunger >= 100 then
        return false
    end
    
    if currentHunger <= AutoFeed.feedThreshold then
        return true
    end
    
    return false
end

function AutoFeed.autoFeedLoop()
    if not AutoFeed.autoFeedEnabled then return end
    
    local currentTime = tick()
    local currentHunger = AutoFeed.getHungerPercentage()
    
    if currentTime - AutoFeed.lastFeedTime < AutoFeed.feedDelay then
        return
    end
    
    if not AutoFeed.shouldFeed() then
        return
    end
    
    local cookedFood = AutoFeed.findCookedFood()
    
    if #cookedFood > 0 then
        local foodToEat = cookedFood[1]
        if foodToEat and foodToEat.Parent then
            local success = AutoFeed.consumeItem(foodToEat)
            
            if success then
                AutoFeed.lastFeedTime = currentTime
            end
        end
    end
end

function AutoFeed.setEnabled(enabled)
    AutoFeed.autoFeedEnabled = enabled
    
    if enabled then
        AutoFeed.feedConnection = RunService.Heartbeat:Connect(AutoFeed.autoFeedLoop)
    else
        if AutoFeed.feedConnection then
            AutoFeed.feedConnection:Disconnect()
            AutoFeed.feedConnection = nil
        end
    end
end

function AutoFeed.setFeedThreshold(threshold)
    AutoFeed.feedThreshold = math.max(25, math.min(threshold, 80))
end

function AutoFeed.setFeedDelay(delay)
    AutoFeed.feedDelay = delay
end

function AutoFeed.getStatus()
    local currentHunger = AutoFeed.getHungerPercentage()
    local cookedFood = AutoFeed.findCookedFood()
    
    -- Count different types of food
    local morselCount = 0
    local steakCount = 0
    for _, food in pairs(cookedFood) do
        if food.Name == "Cooked Morsel" then
            morselCount = morselCount + 1
        elseif food.Name == "Cooked Steak" then
            steakCount = steakCount + 1
        end
    end
    
    if AutoFeed.autoFeedEnabled then
        local hungerStatus = ""
        if currentHunger >= 100 then
            hungerStatus = "🟢 Full"
        elseif currentHunger >= 90 then
            hungerStatus = "🟢 Almost Full"
        elseif currentHunger >= AutoFeed.feedThreshold then
            hungerStatus = "🟡 Satisfied"
        else
            hungerStatus = "🔴 Hungry"
        end
        
        if #cookedFood > 0 then
            return string.format("Status: %s (%d%%) - M:%d S:%d - Threshold: %d%%", 
                   hungerStatus, currentHunger, morselCount, steakCount, AutoFeed.feedThreshold), currentHunger
        else
            return string.format("Status: %s (%d%%) - No Cooked Food found!", 
                   hungerStatus, currentHunger), currentHunger
        end
    else
        return string.format("Status: Auto feed disabled - Hunger: %d%% - M:%d S:%d available", 
               currentHunger, morselCount, steakCount), currentHunger
    end
end

return AutoFeed