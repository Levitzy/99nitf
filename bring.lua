local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local BringAura = {}

local enabled = false
local selectedItem = "Log"
local bringDelay = 0.2
local bringDistance = 100
local connection
local lastBringTime = 0
local availableItems = {}

local function getPlayerCharacter()
    return LocalPlayer.Character
end

local function getPlayerPosition()
    local character = getPlayerCharacter()
    if character and character:FindFirstChild("HumanoidRootPart") then
        return character.HumanoidRootPart.Position
    end
    return nil
end

local function scanAvailableItems()
    local items = {}
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if itemsFolder then
        local itemNames = {}
        
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item.Name ~= "Camera" then
                local itemName = item.Name
                if not itemNames[itemName] then
                    itemNames[itemName] = true
                    table.insert(items, itemName)
                end
            end
        end
        
        table.sort(items)
    end
    
    availableItems = items
    return items
end

local function findItemsInRange()
    local playerPos = getPlayerPosition()
    if not playerPos then
        return {}
    end
    
    local itemsInRange = {}
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item.Name == selectedItem and item:FindFirstChild("Main") then
                local distance = (item.Main.Position - playerPos).Magnitude
                if distance <= bringDistance then
                    table.insert(itemsInRange, {
                        item = item,
                        distance = distance
                    })
                end
            end
        end
        
        if #itemsInRange > 1 then
            table.sort(itemsInRange, function(a, b)
                return a.distance < b.distance
            end)
        end
    end
    
    return itemsInRange
end

local function bringItem(itemData)
    local currentTime = tick()
    
    if currentTime - lastBringTime < bringDelay then
        return false
    end
    
    local item = itemData.item
    if not item or not item.Parent or not item:FindFirstChild("Main") then
        return false
    end
    
    local playerCharacter = getPlayerCharacter()
    if not playerCharacter or not playerCharacter:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local success = pcall(function()
        item.Main.CFrame = playerCharacter.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
        item.Main.Velocity = Vector3.new(0, 0, 0)
        item.Main.AngularVelocity = Vector3.new(0, 0, 0)
    end)
    
    if success then
        lastBringTime = currentTime
        return true
    end
    
    return false
end

local function bringAuraLoop()
    if not enabled then
        return
    end
    
    local itemsInRange = findItemsInRange()
    
    for _, itemData in pairs(itemsInRange) do
        if enabled then
            bringItem(itemData)
            break
        end
    end
end

function BringAura.toggle()
    enabled = not enabled
    
    if enabled then
        print("Bring Aura: ON")
        print("Selected Item: " .. selectedItem)
        print("Distance: " .. bringDistance .. " | Delay: " .. bringDelay .. "s")
        
        connection = RunService.Heartbeat:Connect(function()
            wait(bringDelay)
            bringAuraLoop()
        end)
    else
        print("Bring Aura: OFF")
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
    
    return enabled
end

function BringAura.stop()
    enabled = false
    if connection then
        connection:Disconnect()
        connection = nil
    end
    print("Bring Aura: STOPPED")
end

function BringAura.isEnabled()
    return enabled
end

function BringAura.setSelectedItem(itemName)
    selectedItem = itemName
    print("Bring Aura item set to: " .. itemName)
end

function BringAura.getSelectedItem()
    return selectedItem
end

function BringAura.setDelay(delay)
    bringDelay = math.max(0.1, math.min(5, delay))
    print("Bring Aura delay set to: " .. bringDelay .. "s")
end

function BringAura.getDelay()
    return bringDelay
end

function BringAura.setDistance(distance)
    bringDistance = math.max(10, math.min(500, distance))
    print("Bring Aura distance set to: " .. bringDistance)
end

function BringAura.getDistance()
    return bringDistance
end

function BringAura.getAvailableItems()
    return availableItems
end

function BringAura.refreshItems()
    local items = scanAvailableItems()
    print("Items refreshed! Found " .. #items .. " different items:")
    for i, item in pairs(items) do
        print("  " .. i .. ". " .. item)
    end
    return items
end

function BringAura.getItemCount()
    local count = 0
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item.Name == selectedItem then
                count = count + 1
            end
        end
    end
    
    return count
end

function BringAura.getStatus()
    local itemCount = BringAura.getItemCount()
    local itemsInRange = findItemsInRange()
    
    return {
        enabled = enabled,
        selectedItem = selectedItem,
        delay = bringDelay,
        distance = bringDistance,
        hasConnection = connection ~= nil,
        totalItems = itemCount,
        itemsInRange = #itemsInRange,
        availableItemTypes = #availableItems
    }
end

BringAura.refreshItems()

return BringAura
