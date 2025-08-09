local AutoFeed = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoFeed.autoFeedEnabled = false
AutoFeed.feedThreshold = 80
AutoFeed.feedDelay = 5.0
AutoFeed.feedConnection = nil
AutoFeed.lastFeedTime = 0
AutoFeed.lastCheckTime = 0
AutoFeed.checkInterval = 2.0
AutoFeed.cachedHunger = 0
AutoFeed.hungerCacheTime = 0

function AutoFeed.getCachedHungerPercentage()
    local currentTime = tick()
    
    -- Only update hunger cache every 1 second to reduce lag
    if currentTime - AutoFeed.hungerCacheTime > 1.0 then
        AutoFeed.cachedHunger = AutoFeed.getHungerPercentage()
        AutoFeed.hungerCacheTime = currentTime
    end
    
    return AutoFeed.cachedHunger
end

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
    
    local success = pcall(function()
        ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(item)
    end)
    
    if success then
        print("AutoFeed: Ate " .. item.Name)
    end
    
    return success
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
    
    -- Only check every 2 seconds to reduce lag
    if currentTime - AutoFeed.lastCheckTime < AutoFeed.checkInterval then
        return
    end
    AutoFeed.lastCheckTime = currentTime
    
    -- Only feed if enough time has passed since last feeding
    if currentTime - AutoFeed.lastFeedTime < AutoFeed.feedDelay then
        return
    end
    
    local currentHunger = AutoFeed.getCachedHungerPercentage()
    if currentHunger >= 100 or currentHunger > AutoFeed.feedThreshold then
        return
    end
    
    local cookedFood = AutoFeed.findCookedFood()
    
    if #cookedFood > 0 then
        local foodToEat = cookedFood[1]
        if foodToEat and foodToEat.Parent then
            local success = AutoFeed.consumeItem(foodToEat)
            if success then
                AutoFeed.lastFeedTime = currentTime
                -- Reset hunger cache to get updated value
                AutoFeed.hungerCacheTime = 0
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
    local currentHunger = AutoFeed.getCachedHungerPercentage()
    
    if AutoFeed.autoFeedEnabled then
        local hungerStatus = ""
        if currentHunger >= 100 then
            hungerStatus = "🟢 Full"
        elseif currentHunger >= AutoFeed.feedThreshold then
            hungerStatus = "🟡 Satisfied"
        else
            hungerStatus = "🔴 Hungry"
        end
        
        return string.format("Status: %s (%d%%) - Threshold: %d%%", 
               hungerStatus, currentHunger, AutoFeed.feedThreshold), currentHunger
    else
        return string.format("Status: Auto feed disabled - Hunger: %d%%", 
               currentHunger), currentHunger
    end
end

return AutoFeed