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
        print("AutoFeed Debug - Invalid item or item has no parent")
        return false
    end
    
    print("AutoFeed Debug - Item details: Name=" .. item.Name .. ", ClassName=" .. item.ClassName)
    if item.Parent then
        print("AutoFeed Debug - Item parent: " .. item.Parent.Name)
    end
    
    local success = false
    local preHunger = AutoFeed.getHungerPercentage()
    
    -- METHOD 1: Original RequestConsumeItem with Model wrapper
    print("AutoFeed Debug - METHOD 1: RequestConsumeItem with Model wrapper")
    local method1Success = pcall(function()
        local modelWrapper = Instance.new("Model", nil)
        local args = {modelWrapper}
        -- Put the item inside the model
        item.Parent = modelWrapper
        local result = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(unpack(args))
        print("AutoFeed Debug - Method 1 result:", result)
    end)
    
    wait(0.3)
    local hunger1 = AutoFeed.getHungerPercentage()
    if hunger1 > preHunger then
        print("AutoFeed Debug - METHOD 1 SUCCESS! Hunger: " .. preHunger .. "% -> " .. hunger1 .. "%")
        return true
    end
    print("AutoFeed Debug - Method 1 failed, hunger still: " .. hunger1 .. "%")
    
    -- METHOD 2: Try direct item reference without wrapper
    print("AutoFeed Debug - METHOD 2: Direct item reference")
    local method2Success = pcall(function()
        local result = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(item)
        print("AutoFeed Debug - Method 2 result:", result)
    end)
    
    wait(0.3)
    local hunger2 = AutoFeed.getHungerPercentage()
    if hunger2 > preHunger then
        print("AutoFeed Debug - METHOD 2 SUCCESS! Hunger: " .. preHunger .. "% -> " .. hunger2 .. "%")
        return true
    end
    print("AutoFeed Debug - Method 2 failed, hunger still: " .. hunger2 .. "%")
    
    -- METHOD 3: Try with empty model as first argument and item as second
    print("AutoFeed Debug - METHOD 3: Empty model + item as separate args")
    local method3Success = pcall(function()
        local emptyModel = Instance.new("Model", nil)
        local result = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(emptyModel, item)
        print("AutoFeed Debug - Method 3 result:", result)
    end)
    
    wait(0.3)
    local hunger3 = AutoFeed.getHungerPercentage()
    if hunger3 > preHunger then
        print("AutoFeed Debug - METHOD 3 SUCCESS! Hunger: " .. preHunger .. "% -> " .. hunger3 .. "%")
        return true
    end
    print("AutoFeed Debug - Method 3 failed, hunger still: " .. hunger3 .. "%")
    
    -- METHOD 4: Try FireServer instead of InvokeServer
    print("AutoFeed Debug - METHOD 4: FireServer with item")
    local method4Success = pcall(function()
        ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):FireServer(item)
        print("AutoFeed Debug - Method 4 FireServer called")
    end)
    
    wait(0.3)
    local hunger4 = AutoFeed.getHungerPercentage()
    if hunger4 > preHunger then
        print("AutoFeed Debug - METHOD 4 SUCCESS! Hunger: " .. preHunger .. "% -> " .. hunger4 .. "%")
        return true
    end
    print("AutoFeed Debug - Method 4 failed, hunger still: " .. hunger4 .. "%")
    
    -- METHOD 5: Try manipulating item position to player (simulate picking up and eating)
    print("AutoFeed Debug - METHOD 5: Teleport item to player + consume")
    local method5Success = pcall(function()
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            -- Teleport item to player
            local rootPart = player.Character.HumanoidRootPart
            if item:FindFirstChildOfClass("Part") then
                local itemPart = item:FindFirstChildOfClass("Part")
                itemPart.CFrame = rootPart.CFrame
                itemPart.Velocity = Vector3.new(0, 0, 0)
            end
            
            -- Wait a moment for collision/pickup
            wait(0.2)
            
            -- Now try consuming
            local result = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(item)
            print("AutoFeed Debug - Method 5 result:", result)
        end
    end)
    
    wait(0.3)
    local hunger5 = AutoFeed.getHungerPercentage()
    if hunger5 > preHunger then
        print("AutoFeed Debug - METHOD 5 SUCCESS! Hunger: " .. preHunger .. "% -> " .. hunger5 .. "%")
        return true
    end
    print("AutoFeed Debug - Method 5 failed, hunger still: " .. hunger5 .. "%")
    
    -- BONUS METHOD 6: Try with player's mouse/character interaction simulation
    print("AutoFeed Debug - METHOD 6: Simulate player interaction")
    local method6Success = pcall(function()
        local player = game:GetService("Players").LocalPlayer
        local mouse = player:GetMouse()
        
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            -- Try to simulate clicking on the item
            if item:FindFirstChildOfClass("Part") then
                local itemPart = item:FindFirstChildOfClass("Part")
                
                -- Try different remote event calls that might simulate player interaction
                local interactionMethods = {
                    function() 
                        return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(item, player.Character)
                    end,
                    function()
                        return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(item, mouse)
                    end,
                    function()
                        return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(item, mouse.Hit)
                    end,
                    function()
                        return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(item, mouse.Target)
                    end
                }
                
                for i, method in pairs(interactionMethods) do
                    local subSuccess = pcall(method)
                    if subSuccess then
                        print("AutoFeed Debug - Method 6." .. i .. " call succeeded")
                        wait(0.2)
                        local testHunger = AutoFeed.getHungerPercentage()
                        if testHunger > preHunger then
                            print("AutoFeed Debug - METHOD 6." .. i .. " SUCCESS! Hunger: " .. preHunger .. "% -> " .. testHunger .. "%")
                            return true
                        end
                    end
                end
            end
        end
    end)
    
    wait(0.3)
    local hunger6 = AutoFeed.getHungerPercentage()
    if hunger6 > preHunger then
        print("AutoFeed Debug - METHOD 6 SUCCESS! Hunger: " .. preHunger .. "% -> " .. hunger6 .. "%")
        return true
    end
    print("AutoFeed Debug - Method 6 failed, hunger still: " .. hunger6 .. "%")
    
    print("AutoFeed Debug - ALL 6 METHODS FAILED! Hunger unchanged at: " .. hunger6 .. "%")
    return false
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
            print("AutoFeed Debug - ========== STARTING CONSUMPTION ATTEMPT ==========")
            print("AutoFeed Debug - Attempting to eat: " .. foodToEat.Name)
            print("AutoFeed Debug - Current hunger before attempt: " .. currentHunger .. "%")
            
            local success = AutoFeed.consumeItem(foodToEat)
            
            -- Check final hunger after all methods
            local finalHunger = AutoFeed.getHungerPercentage()
            print("AutoFeed Debug - Final hunger after all methods: " .. finalHunger .. "%")
            
            if finalHunger > currentHunger then
                print("AutoFeed Debug - ✅ SUCCESS! Hunger increased by " .. (finalHunger - currentHunger) .. "%")
                AutoFeed.lastFeedTime = currentTime
            else
                print("AutoFeed Debug - ❌ COMPLETE FAILURE - Need to investigate other remote events")
                -- List all available remote events for investigation
                AutoFeed.listAllRemoteEvents()
            end
            
            print("AutoFeed Debug - ========== CONSUMPTION ATTEMPT COMPLETE ==========")
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