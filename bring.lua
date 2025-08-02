local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local BringItems = {}

local selectedItem = "Log"
local availableItems = {}
local lastBringTime = 0
local bringCooldown = 0.1

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

local function dragItemToPlayer(item)
    if not item or not item:FindFirstChild("Main") then
        return false
    end
    
    local success = pcall(function()
        local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if remoteEvent then
            local requestDrag = remoteEvent:FindFirstChild("RequestStartDraggingItem")
            if requestDrag then
                local args = {item}
                requestDrag:FireServer(unpack(args))
                return true
            end
        end
        return false
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
        local success = dragItemToPlayer(item)
        
        if success then
            itemsBrought = itemsBrought + 1
            print("✅ Dragging " .. item.Name .. " to player...")
        else
            print("❌ Failed to drag " .. item.Name)
        end
        
        wait(0.1)
    end
    
    lastBringTime = currentTime
    
    if itemsBrought > 0 then
        print("✅ Successfully started dragging " .. itemsBrought .. " " .. selectedItem .. "(s)!")
        return true
    else
        print("❌ Failed to drag any " .. selectedItem .. " items!")
        return false
    end
end

local function bringAllItems()
    local currentTime = tick()
    
    if currentTime - lastBringTime < bringCooldown then
        return false
    end
    
    local playerCharacter = getPlayerCharacter()
    if not playerCharacter or not playerCharacter:FindFirstChild("HumanoidRootPart") then
        print("❌ Player character not found!")
        return false
    end
    
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
        local success = dragItemToPlayer(item)
        
        if success then
            itemsBrought = itemsBrought + 1
            print("✅ Dragging " .. item.Name .. " to player...")
        else
            print("❌ Failed to drag " .. item.Name)
        end
        
        wait(0.1)
    end
    
    lastBringTime = currentTime
    
    if itemsBrought > 0 then
        print("✅ Successfully started dragging " .. itemsBrought .. " items!")
        return true
    else
        print("❌ Failed to drag any items!")
        return false
    end
end

function BringItems.bringSelected()
    return bringSelectedItems()
end

function BringItems.bringAll()
    return bringAllItems()
end

function BringItems.setSelectedItem(itemName)
    if itemName and type(itemName) == "string" and itemName ~= "" then
        selectedItem = itemName
        print("📦 Selected item changed to: " .. itemName)
    else
        print("❌ Invalid item name: " .. tostring(itemName))
    end
end

function BringItems.getSelectedItem()
    return selectedItem
end

function BringItems.getAvailableItems()
    return availableItems
end

function BringItems.refreshItems()
    local items = scanAvailableItems()
    print("🔄 Found " .. #items .. " different item types:")
    for i, itemName in pairs(items) do
        print("  " .. i .. ". " .. itemName)
    end
    return items
end

function BringItems.getItemCount(itemName)
    local targetItem = itemName or selectedItem
    local count = 0
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item.Name == targetItem and item:FindFirstChild("Main") then
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
                local itemName = item.Name
                if not counts[itemName] then
                    counts[itemName] = 0
                end
                counts[itemName] = counts[itemName] + 1
            end
        end
    end
    
    return counts
end

function BringItems.testDragSystem()
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        local testItem = itemsFolder:FindFirstChild(selectedItem)
        if testItem then
            print("🧪 Testing drag system with: " .. testItem.Name)
            return dragItemToPlayer(testItem)
        else
            print("❌ No " .. selectedItem .. " found for testing")
            return false
        end
    end
    return false
end

function BringItems.getStatus()
    local counts = BringItems.getAllItemCounts()
    return {
        selectedItem = selectedItem,
        availableItemTypes = #availableItems,
        selectedItemCount = BringItems.getItemCount(),
        allItemCounts = counts,
        totalItems = 0
    }
end

function BringItems.isEnabled()
    return false
end

function BringItems.toggle()
    return false
end

function BringItems.stop()
    print("Bring Items: Stopped")
end

BringItems.refreshItems()

return BringItems
