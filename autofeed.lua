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
AutoFeed.lastHungerCheck = 0
AutoFeed.previousHunger = 0
AutoFeed.lastFeedAttempt = 0
AutoFeed.failedAttempts = 0
AutoFeed.maxFailedAttempts = 3
AutoFeed.debugCooldown = 0
AutoFeed.lastDebugTime = 0

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
    local currentTime = tick()
    if currentTime - AutoFeed.lastDebugTime < 30 then
        return
    end
    AutoFeed.lastDebugTime = currentTime
    
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
    local consumptionMethods = {
        function()
            local modelWrapper = Instance.new("Model", nil)
            item.Parent = modelWrapper
            local result = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(modelWrapper)
            return result
        end,
        
        function()
            local result = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(item)
            return result
        end,
        
        function()
            local emptyModel = Instance.new("Model", nil)
            local result = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(emptyModel, item)
            return result
        end,
        
        function()
            ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):FireServer(item)
            return true
        end,
        
        function()
            local player = game:GetService("Players").LocalPlayer
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local rootPart = player.Character.HumanoidRootPart
                if item:FindFirstChildOfClass("Part") then
                    local itemPart = item:FindFirstChildOfClass("Part")
                    itemPart.CFrame = rootPart.CFrame
                    itemPart.Velocity = Vector3.new(0, 0, 0)
                end
                wait(0.1)
                local result = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(item)
                return result
            end
            return false
        end
    }
    
    for i, method in pairs(consumptionMethods) do
        local success = pcall(method)
        if success then
            wait(0.2)
            local newHunger = AutoFeed.getHungerPercentage()
            if newHunger > preHunger then
                print("AutoFeed - Successfully consumed " .. item.Name .. " using method " .. i .. " (Hunger: " .. preHunger .. "% -> " .. newHunger .. "%)")
                return true
            end
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
    
    if currentTime - AutoFeed.lastHungerCheck >= 2.0 then
        if AutoFeed.previousHunger > 0 and currentHunger ~= AutoFeed.previousHunger then
            local change = currentHunger - AutoFeed.previousHunger
            if math.abs(change) >= 5 then
                print("AutoFeed - Hunger changed: " .. AutoFeed.previousHunger .. "% -> " .. currentHunger .. "% (" .. (change > 0 and "+" or "") .. change .. "%)")
            end
        end
        AutoFeed.previousHunger = currentHunger
        AutoFeed.lastHungerCheck = currentTime
    end
    
    if currentTime - AutoFeed.lastFeedTime < AutoFeed.feedDelay then
        return
    end
    
    if not AutoFeed.shouldFeed() then
        AutoFeed.failedAttempts = 0
        return
    end
    
    if AutoFeed.failedAttempts >= AutoFeed.maxFailedAttempts then
        if currentTime - AutoFeed.lastFeedAttempt < 30 then
            return
        end
        AutoFeed.failedAttempts = 0
    end
    
    local cookedFood = AutoFeed.findCookedFood()
    
    if #cookedFood > 0 then
        local foodToEat = cookedFood[1]
        if foodToEat and foodToEat.Parent then
            AutoFeed.lastFeedAttempt = currentTime
            
            print("AutoFeed - Attempting to consume " .. foodToEat.Name .. " (Hunger: " .. currentHunger .. "%, Threshold: " .. AutoFeed.feedThreshold .. "%)")
            
            local success = AutoFeed.consumeItem(foodToEat)
            
            if success then
                AutoFeed.lastFeedTime = currentTime
                AutoFeed.failedAttempts = 0
                print("AutoFeed - ✅ Consumption successful!")
            else
                AutoFeed.failedAttempts = AutoFeed.failedAttempts + 1
                print("AutoFeed - ❌ Consumption failed (Attempt " .. AutoFeed.failedAttempts .. "/" .. AutoFeed.maxFailedAttempts .. ")")
                
                if AutoFeed.failedAttempts >= AutoFeed.maxFailedAttempts then
                    print("AutoFeed - Max failed attempts reached. Pausing for 30 seconds...")
                    AutoFeed.listAllRemoteEvents()
                end
            end
        end
    else
        if currentTime - AutoFeed.debugCooldown > 10 then
            print("AutoFeed - No cooked food available (Hunger: " .. currentHunger .. "%)")
            AutoFeed.debugCooldown = currentTime
        end
    end
end

function AutoFeed.setEnabled(enabled)
    AutoFeed.autoFeedEnabled = enabled
    AutoFeed.failedAttempts = 0
    AutoFeed.lastFeedAttempt = 0
    
    if enabled then
        AutoFeed.feedConnection = RunService.Heartbeat:Connect(AutoFeed.autoFeedLoop)
        print("AutoFeed - System enabled (Threshold: " .. AutoFeed.feedThreshold .. "%)")
    else
        if AutoFeed.feedConnection then
            AutoFeed.feedConnection:Disconnect()
            AutoFeed.feedConnection = nil
        end
        print("AutoFeed - System disabled")
    end
end

function AutoFeed.setFeedThreshold(threshold)
    AutoFeed.feedThreshold = math.max(25, math.min(threshold, 80))
    print("AutoFeed - Feed threshold set to " .. AutoFeed.feedThreshold .. "%")
end

function AutoFeed.setFeedDelay(delay)
    AutoFeed.feedDelay = delay
    print("AutoFeed - Feed delay set to " .. AutoFeed.feedDelay .. " seconds")
end

function AutoFeed.getStatus()
    local currentHunger = AutoFeed.getHungerPercentage()
    local cookedFood = AutoFeed.findCookedFood()
    
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
        
        local failStatus = ""
        if AutoFeed.failedAttempts > 0 then
            failStatus = " [Fails: " .. AutoFeed.failedAttempts .. "/" .. AutoFeed.maxFailedAttempts .. "]"
        end
        
        if #cookedFood > 0 then
            return string.format("Status: %s (%d%%) - M:%d S:%d - Threshold: %d%%%s", 
                   hungerStatus, currentHunger, morselCount, steakCount, AutoFeed.feedThreshold, failStatus), currentHunger
        else
            return string.format("Status: %s (%d%%) - No Cooked Food found!%s", 
                   hungerStatus, currentHunger, failStatus), currentHunger
        end
    else
        return string.format("Status: Auto feed disabled - Hunger: %d%% - M:%d S:%d available", 
               currentHunger, morselCount, steakCount), currentHunger
    end
end

return AutoFeed