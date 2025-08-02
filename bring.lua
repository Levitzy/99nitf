local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local BringItems = {}

local selectedItem = "Log"
local availableItems = {}
local lastBringTime = 0
local bringCooldown = 0.1
local bringHeight = 3

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

local function getPlayerBag()
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if inventory then
        return inventory:FindFirstChild("Old Sack") or 
               inventory:FindFirstChild("Sack") or
               inventory:FindFirstChild("Bag") or
               inventory:FindFirstChild("Storage")
    end
    return nil
end

local function scanAvailableItems()
    local items = {}
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if itemsFolder then
        local itemNames = {}
        
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item.Name ~= "Camera" and item:FindFirstChild("Main") then
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

local function smoothBringItem(item, targetPosition)
    if not item or not item:FindFirstChild("Main") or not item.Main then
        return false
    end
    
    local success = pcall(function()
        if item.Main:FindFirstChild("BodyVelocity") then
            item.Main.BodyVelocity:Destroy()
        end
        if item.Main:FindFirstChild("BodyAngularVelocity") then
            item.Main.BodyAngularVelocity:Destroy()
        end
        if item.Main:FindFirstChild("BodyPosition") then
            item.Main.BodyPosition:Destroy()
        end
        
        item.Main.Anchored = false
        item.Main.CanCollide = false
        
        item.Main.Velocity = Vector3.new(0, 0, 0)
        item.Main.AngularVelocity = Vector3.new(0, 0, 0)
        
        if item.Main.AssemblyLinearVelocity then
            item.Main.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        if item.Main.AssemblyAngularVelocity then
            item.Main.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
        
        item:SetPrimaryPartCFrame(CFrame.new(targetPosition))
        
        wait(0.05)
        
        item.Main.CanCollide = true
    end)
    
    return success
end

local function bringSelectedItems()
    local currentTime = tick()
    
    if currentTime - lastBringTime < bringCooldown then
        return false
    end
    
    local playerCharacter = getPlayerCharacter()
    if not playerCharacter or not playerCharacter:FindFirstChild("HumanoidRootPart") then
        print("❌ Player character not found!")
        return false
    end
    
    local playerPosition = playerCharacter.HumanoidRootPart.Position
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if not itemsFolder then
        print("❌ Items folder not found!")
        return false
    end
    
    local itemsBrought = 0
    local itemsToProcess = {}
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item.Name == selectedItem and item:FindFirstChild("Main") then
            table.insert(itemsToProcess, item)
        end
    end
    
    if #itemsToProcess == 0 then
        print("❌ No " .. selectedItem .. " items found!")
        return false
    end
    
    print("🔍 Found " .. #itemsToProcess .. " " .. selectedItem .. " items to bring...")
    
    for i, item in pairs(itemsToProcess) do
        local offsetX = math.random(-5, 5)
        local offsetZ = math.random(-5, 5)
        local newPosition = playerPosition + Vector3.new(offsetX, bringHeight, offsetZ)
        
        local success = smoothBringItem(item, newPosition)
        
        if success then
            itemsBrought = itemsBrought + 1
        end
        
        if i % 3 == 0 then
            wait(0.05)
        end
    end
    
    lastBringTime = currentTime
    
    if itemsBrought > 0 then
        print("✅ Successfully brought " .. itemsBrought .. " " .. selectedItem .. "(s) to you!")
        return true
    else
        print("❌ Failed to bring any " .. selectedItem .. " items!")
        return false
    end
end

local function bringAllDifferentItems()
    local currentTime = tick()
    
    if currentTime - lastBringTime < bringCooldown then
        return false
    end
    
    local playerCharacter = getPlayerCharacter()
    if not playerCharacter or not playerCharacter:FindFirstChild("HumanoidRootPart") then
        print("❌ Player character not found!")
        return false
    end
    
    local playerPosition = playerCharacter.HumanoidRootPart.Position
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if not itemsFolder then
        print("❌ Items folder not found!")
        return false
    end
    
    local itemsBrought = 0
    local itemsToProcess = {}
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item:FindFirstChild("Main") and item.Name ~= "Camera" then
            table.insert(itemsToProcess, item)
        end
    end
    
    if #itemsToProcess == 0 then
        print("❌ No items found!")
        return false
    end
    
    print("🔍 Found " .. #itemsToProcess .. " items to bring...")
    
    for i, item in pairs(itemsToProcess) do
        local offsetX = math.random(-8, 8)
        local offsetZ = math.random(-8, 8)
        local newPosition = playerPosition + Vector3.new(offsetX, bringHeight, offsetZ)
        
        local success = smoothBringItem(item, newPosition)
        
        if success then
            itemsBrought = itemsBrought + 1
        end
        
        if i % 5 == 0 then
            wait(0.05)
        end
    end
    
    lastBringTime = currentTime
    
    if itemsBrought > 0 then
        print("✅ Successfully brought " .. itemsBrought .. " items to you!")
        return true
    else
        print("❌ Failed to bring any items!")
        return false
    end
end

local function storeNearbyItems()
    local bag = getPlayerBag()
    if not bag then
        print("❌ No bag found in inventory!")
        return false
    end
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if not itemsFolder then
        print("❌ Items folder not found!")
        return false
    end
    
    local playerPos = getPlayerPosition()
    if not playerPos then
        print("❌ Player position not found!")
        return false
    end
    
    local itemsStored = 0
    local itemsToStore = {}
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item:FindFirstChild("Main") then
            local distance = (item.Main.Position - playerPos).Magnitude
            if distance <= 12 then
                table.insert(itemsToStore, item)
            end
        end
    end
    
    if #itemsToStore == 0 then
        print("❌ No items nearby to store!")
        return false
    end
    
    print("🎒 Found " .. #itemsToStore .. " items nearby to store...")
    
    for _, item in pairs(itemsToStore) do
        local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if remoteEvent then
            remoteEvent = remoteEvent:FindFirstChild("RequestBagStoreItem")
            if remoteEvent then
                local success = pcall(function()
                    local args = {bag, item}
                    remoteEvent:InvokeServer(unpack(args))
                end)
                
                if success then
                    itemsStored = itemsStored + 1
                end
                wait(0.15)
            end
        end
    end
    
    if itemsStored > 0 then
        print("🎒 Successfully stored " .. itemsStored .. " items in bag!")
        return true
    else
        print("❌ Failed to store items in bag!")
        return false
    end
end

function BringItems.bringSelected()
    return bringSelectedItems()
end

function BringItems.bringAll()
    return bringAllDifferentItems()
end

function BringItems.setSelectedItem(itemName)
    selectedItem = itemName
    print("📦 Selected item: " .. itemName)
end

function BringItems.getSelectedItem()
    return selectedItem
end

function BringItems.getAvailableItems()
    return availableItems
end

function BringItems.refreshItems()
    local items = scanAvailableItems()
    print("🔄 Refreshed items list - Found " .. #items .. " different item types")
    for i, itemName in pairs(items) do
        print("  " .. i .. ". " .. itemName)
    end
    return items
end

function BringItems.storeNearbyItems()
    return storeNearbyItems()
end

function BringItems.setBringHeight(height)
    bringHeight = math.max(1, math.min(10, height))
    print("📏 Bring height set to: " .. bringHeight)
end

function BringItems.getBringHeight()
    return bringHeight
end

function BringItems.getStatus()
    local itemCount = 0
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item.Name == selectedItem and item:FindFirstChild("Main") then
                itemCount = itemCount + 1
            end
        end
    end
    
    return {
        selectedItem = selectedItem,
        availableItemTypes = #availableItems,
        selectedItemCount = itemCount,
        hasBag = getPlayerBag() ~= nil,
        bringHeight = bringHeight
    }
end

function BringItems.getItemCount(itemName)
    local count = 0
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item.Name == (itemName or selectedItem) and item:FindFirstChild("Main") then
                count = count + 1
            end
        end
    end
    return count
end

function BringItems.isEnabled()
    return false
end

function BringItems.toggle()
    return false
end

function BringItems.stop()
    print("Bring Items: Module stopped")
end

BringItems.refreshItems()

return BringItems
