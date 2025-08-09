local AutoFeed = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoFeed.autoFeedEnabled = false
AutoFeed.feedThreshold = 80
AutoFeed.feedDelay = 2.0
AutoFeed.feedConnection = nil
AutoFeed.lastFeedTime = 0
AutoFeed.lastHungerCheck = 0
AutoFeed.previousHunger = 0

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

function AutoFeed.consumeItem(item)
    if not item or not item.Parent then
        print("AutoFeed Debug - Invalid item or item has no parent")
        return false
    end
    
    print("AutoFeed Debug - Item details: Name=" .. item.Name .. ", ClassName=" .. item.ClassName)
    
    -- Try multiple methods to consume the item
    local success = false
    
    -- Method 1: Try common variations of consume events
    local remoteEvents = {
        "RequestConsumeItem",
        "ConsumeItem", 
        "EatItem",
        "RequestEatItem",
        "UseItem",
        "RequestUseItem"
    }
    
    for i, eventName in pairs(remoteEvents) do
        local eventExists = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild(eventName)
        if eventExists then
            print("AutoFeed Debug - Found event: " .. eventName)
            
            -- Try InvokeServer first
            local invokeSuccess = pcall(function()
                print("AutoFeed Debug - Trying InvokeServer on " .. eventName)
                local result = eventExists:InvokeServer(item)
                print("AutoFeed Debug - InvokeServer result:", result)
                success = true
            end)
            
            if not invokeSuccess then
                -- Try FireServer
                local fireSuccess = pcall(function()
                    print("AutoFeed Debug - Trying FireServer on " .. eventName)
                    eventExists:FireServer(item)
                    success = true
                end)
                
                if fireSuccess then
                    print("AutoFeed Debug - FireServer succeeded on " .. eventName)
                else
                    print("AutoFeed Debug - Both methods failed on " .. eventName)
                end
            else
                print("AutoFeed Debug - InvokeServer succeeded on " .. eventName)
                break
            end
            
            if success then break end
        else
            print("AutoFeed Debug - Event not found: " .. eventName)
        end
    end
    
    if not success then
        print("AutoFeed Debug - All consumption methods failed")
    end
    
    return success
end

function AutoFeed.shouldFeed()
    local currentHunger = AutoFeed.getHungerPercentage()
    
    -- Debug: print current hunger and threshold
    print("AutoFeed Debug - Current Hunger: " .. currentHunger .. "%, Threshold: " .. AutoFeed.feedThreshold .. "%")
    
    -- Don't feed if already full
    if currentHunger >= 100 then
        print("AutoFeed Debug - Already full, not feeding")
        return false
    end
    
    -- Feed if hunger is at or below threshold
    if currentHunger <= AutoFeed.feedThreshold then
        print("AutoFeed Debug - Should feed! Hunger " .. currentHunger .. "% <= " .. AutoFeed.feedThreshold .. "%")
        return true
    end
    
    print("AutoFeed Debug - No need to feed yet")
    return false
end

function AutoFeed.autoFeedLoop()
    if not AutoFeed.autoFeedEnabled then return end
    
    local currentTime = tick()
    local currentHunger = AutoFeed.getHungerPercentage()
    
    -- Track hunger changes
    if currentTime - AutoFeed.lastHungerCheck >= 1.0 then
        if AutoFeed.previousHunger > 0 and currentHunger ~= AutoFeed.previousHunger then
            print("AutoFeed Debug - Hunger changed from " .. AutoFeed.previousHunger .. "% to " .. currentHunger .. "%")
        end
        AutoFeed.previousHunger = currentHunger
        AutoFeed.lastHungerCheck = currentTime
    end
    
    if currentTime - AutoFeed.lastFeedTime < AutoFeed.feedDelay then
        return
    end
    
    if not AutoFeed.shouldFeed() then
        return
    end
    
    local cookedFood = AutoFeed.findCookedFood()
    print("AutoFeed Debug - Found " .. #cookedFood .. " cooked food items")
    
    if #cookedFood > 0 then
        local foodToEat = cookedFood[1]
        if foodToEat and foodToEat.Parent then
            print("AutoFeed Debug - Attempting to eat: " .. foodToEat.Name)
            local preHunger = AutoFeed.getHungerPercentage()
            
            local success = AutoFeed.consumeItem(foodToEat)
            
            -- Wait a moment and check if hunger increased
            wait(0.5)
            local postHunger = AutoFeed.getHungerPercentage()
            
            if success then
                print("AutoFeed Debug - Consumption call succeeded")
                if postHunger > preHunger then
                    print("AutoFeed Debug - Hunger increased from " .. preHunger .. "% to " .. postHunger .. "%")
                    AutoFeed.lastFeedTime = currentTime
                else
                    print("AutoFeed Debug - WARNING: Hunger did not increase! Still at " .. postHunger .. "%")
                end
            else
                print("AutoFeed Debug - Failed to consume " .. foodToEat.Name)
            end
        end
    else
        print("AutoFeed Debug - No cooked food available!")
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