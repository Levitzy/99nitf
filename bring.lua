local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local BringItems = {}

local enabled = false
local selectedItem = "Log"
local bringDelay = 0.3
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

local function bringAllItems()
    local currentTime = tick()
    
    if currentTime - lastBringTime < bringDelay then
        return false
    end
    
    local playerCharacter = getPlayerCharacter()
    if not playerCharacter or not playerCharacter:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if not itemsFolder then
        return false
    end
    
    local itemsBrought = 0
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item.Name == selectedItem and item:FindFirstChild("Main") then
            local success = pcall(function()
                item.Main.CFrame = playerCharacter.HumanoidRootPart.CFrame + Vector3.new(math.random(-3, 3), 2, math.random(-3, 3))
                item.Main.Velocity = Vector3.new(0, 0, 0)
                item.Main.AngularVelocity = Vector3.new(0, 0, 0)
            end)
            
            if success then
                itemsBrought = itemsBrought + 1
            end
        end
    end
    
    if itemsBrought > 0 then
        lastBringTime = currentTime
        print("Brought " .. itemsBrought .. " " .. selectedItem .. "(s)")
        return true
    end
    
    return false
end

local function bringLoop()
    if not enabled then
        return
    end
    
    bringAllItems()
end

function BringItems.toggle()
    enabled = not enabled
    
    if enabled then
        print("Bring Items: ON")
        print("Selected Item: " .. selectedItem)
        print("Delay: " .. bringDelay .. "s")
        
        connection = RunService.Heartbeat:Connect(function()
            wait(bringDelay)
            bringLoop()
        end)
    else
        print("Bring Items: OFF")
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
    
    return enabled
end

function BringItems.stop()
    enabled = false
    if connection then
        connection:Disconnect()
        connection = nil
    end
    print("Bring Items: STOPPED")
end

function BringItems.isEnabled()
    return enabled
end

function BringItems.setSelectedItem(itemName)
    selectedItem = itemName
    print("Bring Items set to: " .. itemName)
end

function BringItems.getSelectedItem()
    return selectedItem
end

function BringItems.setDelay(delay)
    bringDelay = math.max(0.1, math.min(5, delay))
    print("Bring Items delay set to: " .. bringDelay .. "s")
end

function BringItems.getDelay()
    return bringDelay
end

function BringItems.getAvailableItems()
    return availableItems
end

function BringItems.refreshItems()
    local items = scanAvailableItems()
    print("Items refreshed! Found " .. #items .. " different items:")
    for i, item in pairs(items) do
        print("  " .. i .. ". " .. item)
    end
    return items
end

function BringItems.getItemCount()
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

function BringItems.getStatus()
    local itemCount = BringItems.getItemCount()
    
    return {
        enabled = enabled,
        selectedItem = selectedItem,
        delay = bringDelay,
        hasConnection = connection ~= nil,
        totalItems = itemCount,
        availableItemTypes = #availableItems
    }
end

BringItems.refreshItems()

return BringItems
