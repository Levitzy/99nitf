local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local AutoCollectCoins = {}

local enabled = false
local connection
local lastCollectTime = 0
local collectDelay = 0.5
local collectRadius = 50

local function getPlayerPosition()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        return character.HumanoidRootPart.Position
    end
    return nil
end

local function findCoinsNearby()
    local playerPos = getPlayerPosition()
    if not playerPos then
        return {}
    end
    
    local coinsFound = {}
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item.Name == "Mossy Coin" and item:FindFirstChild("Main") then
                local distance = (item.Main.Position - playerPos).Magnitude
                if distance <= collectRadius then
                    table.insert(coinsFound, item)
                end
            end
        end
    end
    
    return coinsFound
end

local function collectCoins()
    if not enabled then
        return
    end
    
    local currentTime = tick()
    if currentTime - lastCollectTime < collectDelay then
        return
    end
    
    local coinsNearby = findCoinsNearby()
    
    if #coinsNearby > 0 then
        local success = pcall(function()
            local args = {Instance.new("Model", nil)}
            local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents")
            if remoteEvent then
                local collectCoins = remoteEvent:FindFirstChild("RequestCollectCoints")
                if collectCoins then
                    collectCoins:InvokeServer(unpack(args))
                    lastCollectTime = currentTime
                    print("💰 Collected " .. #coinsNearby .. " Mossy Coins!")
                    return true
                else
                    print("❌ RequestCollectCoints remote not found!")
                end
            else
                print("❌ RemoteEvents folder not found!")
            end
            return false
        end)
        
        if not success then
            print("❌ Failed to collect coins!")
        end
    end
end

local function autoCollectLoop()
    if not enabled then
        return
    end
    
    collectCoins()
end

function AutoCollectCoins.toggle()
    enabled = not enabled
    
    if enabled then
        print("💰 Auto Collect Coins: ON (Radius: " .. collectRadius .. ", Delay: " .. collectDelay .. "s)")
        if connection then
            connection:Disconnect()
        end
        connection = RunService.Heartbeat:Connect(function()
            wait(collectDelay)
            autoCollectLoop()
        end)
    else
        print("💰 Auto Collect Coins: OFF")
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
    
    return enabled
end

function AutoCollectCoins.stop()
    enabled = false
    if connection then
        connection:Disconnect()
        connection = nil
    end
    print("💰 Auto Collect Coins: STOPPED")
end

function AutoCollectCoins.isEnabled()
    return enabled
end

function AutoCollectCoins.setDelay(delay)
    collectDelay = math.max(0.1, math.min(5, delay))
    print("💰 Collection delay set to:", collectDelay .. "s")
end

function AutoCollectCoins.getDelay()
    return collectDelay
end

function AutoCollectCoins.setRadius(radius)
    collectRadius = math.max(10, math.min(200, radius))
    print("💰 Collection radius set to:", collectRadius .. " studs")
end

function AutoCollectCoins.getRadius()
    return collectRadius
end

function AutoCollectCoins.collectOnce()
    local coinsNearby = findCoinsNearby()
    
    if #coinsNearby > 0 then
        print("💰 Found " .. #coinsNearby .. " Mossy Coins nearby, collecting...")
        
        local success = pcall(function()
            local args = {Instance.new("Model", nil)}
            local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents")
            if remoteEvent then
                local collectCoins = remoteEvent:FindFirstChild("RequestCollectCoints")
                if collectCoins then
                    collectCoins:InvokeServer(unpack(args))
                    print("💰 Manual collection triggered!")
                    return true
                else
                    print("❌ RequestCollectCoints remote not found!")
                end
            else
                print("❌ RemoteEvents folder not found!")
            end
            return false
        end)
        
        return success
    else
        print("💰 No Mossy Coins found nearby (radius: " .. collectRadius .. ")")
        return false
    end
end

function AutoCollectCoins.getStatus()
    local coinsNearby = findCoinsNearby()
    
    return {
        enabled = enabled,
        delay = collectDelay,
        radius = collectRadius,
        hasConnection = connection ~= nil,
        coinsNearby = #coinsNearby
    }
end

function AutoCollectCoins.scanCoins()
    local totalCoins = 0
    local nearbyCoins = 0
    local playerPos = getPlayerPosition()
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item.Name == "Mossy Coin" and item:FindFirstChild("Main") then
                totalCoins = totalCoins + 1
                
                if playerPos then
                    local distance = (item.Main.Position - playerPos).Magnitude
                    if distance <= collectRadius then
                        nearbyCoins = nearbyCoins + 1
                    end
                end
            end
        end
    end
    
    print("💰 Coin Scan Results:")
    print("  Total Mossy Coins in world: " .. totalCoins)
    print("  Mossy Coins in range: " .. nearbyCoins)
    print("  Collection radius: " .. collectRadius .. " studs")
    
    return {
        total = totalCoins,
        nearby = nearbyCoins,
        radius = collectRadius
    }
end

return AutoCollectCoins
