local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local BringItems = {}

local selectedItem = "Log"
local availableItems = {}
local lastBringTime = 0
local bringCooldown = 0.5

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

local function bringSelectedItems()
    local currentTime = tick()
    
    if currentTime - lastBringTime < bringCooldown then
        print("Please wait " .. math.ceil(bringCooldown - (currentTime - lastBringTime)) .. " seconds before bringing items again")
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
    local totalItems = 0
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item.Name == selectedItem then
            totalItems = totalItems + 1
        end
    end
    
    if totalItems == 0 then
        print("❌ No " .. selectedItem .. " items found in workspace!")
        return false
    end
    
    print("🔍 Found " .. totalItems .. " " .. selectedItem .. "(s), bringing them to you...")
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item.Name == selectedItem and item:FindFirstChild("Main") then
            local success = pcall(function()
                local offsetX = math.random(-5, 5)
                local offsetZ = math.random(-5, 5)
                local newPosition = playerPosition + Vector3.new(offsetX, 3, offsetZ)
                
                item.Main.CFrame = CFrame.new(newPosition)
                item.Main.Velocity = Vector3.new(0, 0, 0)
                item.Main.AngularVelocity = Vector3.new(0, 0, 0)
                
                if item.Main:FindFirstChild("BodyVelocity") then
                    item.Main.BodyVelocity:Destroy()
                end
                if item.Main:FindFirstChild("BodyAngularVelocity") then
                    item.Main.BodyAngularVelocity:Destroy()
                end
            end)
            
            if success then
                itemsBrought = itemsBrought + 1
            end
            
            wait(0.05)
        end
    end
    
    lastBringTime = currentTime
    
    if itemsBrought > 0 then
        print("✅ Successfully brought " .. itemsBrought .. "/" .. totalItems .. " " .. selectedItem .. "(s) to your location!")
        return true
    else
        print("❌ Failed to bring any items!")
        return false
    end
end

local function bringAllDifferentItems()
    local currentTime = tick()
    
    if currentTime - lastBringTime < bringCooldown then
        print("Please wait " .. math.ceil(bringCooldown - (currentTime - lastBringTime)) .. " seconds before bringing items again")
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
    
    local itemTypes = {}
    local itemsBrought = 0
    local totalItems = 0
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item:FindFirstChild("Main") and item.Name ~= "Camera" then
            if not itemTypes[item.Name] then
                itemTypes[item.Name] = 0
            end
            itemTypes[item.Name] = itemTypes[item.Name] + 1
            totalItems = totalItems + 1
        end
    end
    
    if totalItems == 0 then
        print("❌ No items found in workspace!")
        return false
    end
    
    print("🔍 Found " .. totalItems .. " items of different types, bringing them all...")
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item:FindFirstChild("Main") and item.Name ~= "Camera" then
            local success = pcall(function()
                local offsetX = math.random(-8, 8)
                local offsetZ = math.random(-8, 8)
                local newPosition = playerPosition + Vector3.new(offsetX, 3, offsetZ)
                
                item.Main.CFrame = CFrame.new(newPosition)
                item.Main.Velocity = Vector3.new(0, 0, 0)
                item.Main.AngularVelocity = Vector3.new(0, 0, 0)
                
                if item.Main:FindFirstChild("BodyVelocity") then
                    item.Main.BodyVelocity:Destroy()
                end
                if item.Main:FindFirstChild("BodyAngularVelocity") then
                    item.Main.BodyAngularVelocity:Destroy()
                end
            end)
            
            if success then
                itemsBrought = itemsBrought + 1
            end
            
            wait(0.03)
        end
    end
    
    lastBringTime = currentTime
    
    if itemsBrought > 0 then
        print("✅ Successfully brought " .. itemsBrought .. "/" .. totalItems .. " items to your location!")
        return true
    else
        print("❌ Failed to bring any items!")
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
    print("📦 Selected item set to: " .. itemName)
end

function BringItems.getSelectedItem()
    return selectedItem
end

function BringItems.getAvailableItems()
    return availableItems
end

function BringItems.refreshItems()
    local items = scanAvailableItems()
    print("🔄 Items refreshed! Found " .. #items .. " different item types:")
    for i, item in pairs(items) do
        print("  " .. i .. ". " .. item)
    end
    return items
end

function BringItems.getItemCount(itemName)
    local itemName = itemName or selectedItem
    local count = 0
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item.Name == itemName and item:FindFirstChild("Main") then
                count = count + 1
            end
        end
    end
    
    return count
end

function BringItems.getAllItemCounts()
    local counts = {}
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item:FindFirstChild("Main") and item.Name ~= "Camera" then
                if not counts[item.Name] then
                    counts[item.Name] = 0
                end
                counts[item.Name] = counts[item.Name] + 1
            end
        end
    end
    
    return counts
end

function BringItems.getStatus()
    local selectedCount = BringItems.getItemCount()
    local allCounts = BringItems.getAllItemCounts()
    local totalItems = 0
    
    for _, count in pairs(allCounts) do
        totalItems = totalItems + count
    end
    
    return {
        selectedItem = selectedItem,
        selectedItemCount = selectedCount,
        totalItemsInWorld = totalItems,
        availableItemTypes = #availableItems,
        itemCounts = allCounts
    }
end

function BringItems.isEnabled()
    return false
end

function BringItems.toggle()
    return false
end

function BringItems.stop()
    print("Bring Items: No active processes to stop")
end

BringItems.refreshItems()

return BringItems
