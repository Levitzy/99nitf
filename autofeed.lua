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

function AutoFeed.findInventoryFood()
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if not inventory then return {} end
    
    local inventoryFood = {}
    
    for _, item in pairs(inventory:GetChildren()) do
        if item and item.Parent and (item.Name == "Cooked Morsel" or item.Name == "Cooked Steak") then
            table.insert(inventoryFood, item)
        end
    end
    
    print("AutoFeed Debug - Found " .. #inventoryFood .. " food items in inventory")
    return inventoryFood
end

function AutoFeed.collectFoodToInventory()
    local workspace = game:GetService("Workspace")
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if not itemsFolder then return false end
    
    -- Find closest cooked food
    local playerPos = nil
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        playerPos = LocalPlayer.Character.HumanoidRootPart.Position
    end
    
    local closestFood = nil
    local closestDistance = math.huge
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item and item.Parent and (item.Name == "Cooked Morsel" or item.Name == "Cooked Steak") then
            if playerPos then
                local itemPos = item.PrimaryPart and item.PrimaryPart.Position or item:FindFirstChildOfClass("Part").Position
                local distance = (playerPos - itemPos).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestFood = item
                end
            else
                closestFood = item
                break
            end
        end
    end
    
    if closestFood then
        print("AutoFeed Debug - Attempting to collect: " .. closestFood.Name .. " at distance: " .. closestDistance)
        
        -- Try to collect/pickup the item
        local collectSuccess = pcall(function()
            local collectEvents = {
                "RequestPickupItem",
                "PickupItem",
                "CollectItem", 
                "RequestCollectItem",
                "GrabItem",
                "RequestGrabItem"
            }
            
            for _, eventName in pairs(collectEvents) do
                local event = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild(eventName)
                if event then
                    print("AutoFeed Debug - Trying to collect with: " .. eventName)
                    
                    -- Try different methods
                    pcall(function() event:InvokeServer(closestFood) end)
                    pcall(function() event:FireServer(closestFood) end)
                    pcall(function() event:InvokeServer(closestFood, LocalPlayer.Character) end)
                    
                    wait(0.1)
                end
            end
        end)
        
        return collectSuccess
    end
    
    return false
end

function AutoFeed.consumeInventoryItem(item)
    if not item or not item.Parent then
        print("AutoFeed Debug - Invalid inventory item")
        return false
    end
    
    print("AutoFeed Debug - Consuming inventory item: " .. item.Name)
    
    -- Method 1: Try consuming from inventory
    local success = pcall(function()
        local result = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(item)
        print("AutoFeed Debug - Inventory consume result:", result)
    end)
    
    if success then
        return true
    end
    
    -- Method 2: Try equipping then consuming
    local equipSuccess = pcall(function()
        -- Try to equip the item first
        local equipEvents = {"RequestEquipItem", "EquipItem", "RequestUseItem", "UseItem"}
        
        for _, eventName in pairs(equipEvents) do
            local event = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild(eventName)
            if event then
                print("AutoFeed Debug - Trying to equip with: " .. eventName)
                pcall(function() event:InvokeServer(item) end)
                pcall(function() event:FireServer(item) end)
                wait(0.1)
            end
        end
        
        -- Then try to consume
        wait(0.2)
        ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(item)
    end)
    
    return equipSuccess
end

function AutoFeed.consumeItem(item)
    if not item or not item.Parent then
        print("AutoFeed Debug - Invalid item or item has no parent")
        return false
    end
    
    print("AutoFeed Debug - Item details: Name=" .. item.Name .. ", ClassName=" .. item.ClassName)
    
    -- Simple direct approach for world items
    local success = pcall(function()
        print("AutoFeed Debug - Direct consumption attempt")
        ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(item)
    end)
    
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
    
    print("AutoFeed Debug - NEW METHOD: Trying inventory-based feeding")
    
    -- Method 1: Try consuming from inventory first
    local inventoryFood = AutoFeed.findInventoryFood()
    
    if #inventoryFood > 0 then
        print("AutoFeed Debug - Found food in inventory, attempting to consume")
        local foodToEat = inventoryFood[1]
        local preHunger = currentHunger
        
        local success = AutoFeed.consumeInventoryItem(foodToEat)
        
        wait(0.5)
        local postHunger = AutoFeed.getHungerPercentage()
        
        if postHunger > preHunger then
            print("AutoFeed Debug - SUCCESS! Hunger increased from " .. preHunger .. "% to " .. postHunger .. "%")
            AutoFeed.lastFeedTime = currentTime
            return
        else
            print("AutoFeed Debug - Inventory method failed, trying collection method")
        end
    end
    
    -- Method 2: Try collecting food from world then consuming
    print("AutoFeed Debug - Attempting to collect food from world")
    local collected = AutoFeed.collectFoodToInventory()
    
    if collected then
        wait(1.0) -- Wait for collection to complete
        
        local newInventoryFood = AutoFeed.findInventoryFood()
        if #newInventoryFood > 0 then
            print("AutoFeed Debug - Successfully collected food, now consuming")
            local foodToEat = newInventoryFood[1]
            local preHunger = AutoFeed.getHungerPercentage()
            
            local success = AutoFeed.consumeInventoryItem(foodToEat)
            
            wait(0.5)
            local postHunger = AutoFeed.getHungerPercentage()
            
            if postHunger > preHunger then
                print("AutoFeed Debug - SUCCESS! Collection method worked. Hunger: " .. preHunger .. "% -> " .. postHunger .. "%")
                AutoFeed.lastFeedTime = currentTime
                return
            else
                print("AutoFeed Debug - Collection method also failed")
            end
        end
    end
    
    -- Method 3: Try direct world consumption (fallback)
    print("AutoFeed Debug - Trying direct world consumption as fallback")
    local worldFood = AutoFeed.findCookedFood()
    
    if #worldFood > 0 then
        local foodToEat = worldFood[1]
        local preHunger = AutoFeed.getHungerPercentage()
        
        local success = AutoFeed.consumeItem(foodToEat)
        
        wait(0.5)
        local postHunger = AutoFeed.getHungerPercentage()
        
        if postHunger > preHunger then
            print("AutoFeed Debug - SUCCESS! Direct world method worked. Hunger: " .. preHunger .. "% -> " .. postHunger .. "%")
            AutoFeed.lastFeedTime = currentTime
        else
            print("AutoFeed Debug - All methods failed - hunger still at " .. postHunger .. "%")
        end
    else
        print("AutoFeed Debug - No food found anywhere!")
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

function AutoFeed.getStatus()
    local currentHunger = AutoFeed.getHungerPercentage()
    local cookedFood = AutoFeed.findCookedFood()
    local inventoryFood = AutoFeed.findInventoryFood()
    
    -- Count different types of food
    local morselCount = 0
    local steakCount = 0
    local invMorselCount = 0
    local invSteakCount = 0
    
    for _, food in pairs(cookedFood) do
        if food.Name == "Cooked Morsel" then
            morselCount = morselCount + 1
        elseif food.Name == "Cooked Steak" then
            steakCount = steakCount + 1
        end
    end
    
    for _, food in pairs(inventoryFood) do
        if food.Name == "Cooked Morsel" then
            invMorselCount = invMorselCount + 1
        elseif food.Name == "Cooked Steak" then
            invSteakCount = invSteakCount + 1
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
        
        local totalFood = #cookedFood + #inventoryFood
        if totalFood > 0 then
            return string.format("Status: %s (%d%%) - World M:%d S:%d | Inv M:%d S:%d - T:%d%%", 
                   hungerStatus, currentHunger, morselCount, steakCount, invMorselCount, invSteakCount, AutoFeed.feedThreshold), currentHunger
        else
            return string.format("Status: %s (%d%%) - No Food Available!", 
                   hungerStatus, currentHunger), currentHunger
        end
    else
        local totalFood = #cookedFood + #inventoryFood
        return string.format("Status: Auto feed disabled - Hunger: %d%% - Total Food: %d", 
               currentHunger, totalFood), currentHunger
    end
end

return AutoFeedr