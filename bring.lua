local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local BringItems = {}

local selectedItem = nil
local availableItems = {}
local lastBringTime = 0
local bringCooldown = 0.1
local forcedSelection = nil

local function getPlayerCharacter()
    return LocalPlayer.Character
end

local function getPlayerCFrame()
    local character = getPlayerCharacter()
    if character and character:FindFirstChild("HumanoidRootPart") then
        return character.HumanoidRootPart.CFrame
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

local function bringItemToCFrame(item, targetCFrame, offset)
    if not item or not item:FindFirstChild("Main") or not targetCFrame then
        return false
    end
    
    local success = pcall(function()
        local main = item.Main
        
        main.Anchored = true
        main.CanCollide = false
        
        if main:FindFirstChild("BodyVelocity") then
            main.BodyVelocity:Destroy()
        end
        if main:FindFirstChild("BodyAngularVelocity") then
            main.BodyAngularVelocity:Destroy()
        end
        if main:FindFirstChild("BodyPosition") then
            main.BodyPosition:Destroy()
        end
        
        local newCFrame = targetCFrame * CFrame.new(offset)
        item:SetPrimaryPartCFrame(newCFrame)
        
        main.Velocity = Vector3.new(0, 0, 0)
        main.AngularVelocity = Vector3.new(0, 0, 0)
        
        if main.AssemblyLinearVelocity then
            main.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        if main.AssemblyAngularVelocity then
            main.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
        
        wait(0.05)
        main.Anchored = false
        main.CanCollide = true
    end)
    
    return success
end

local function bringSelectedItems()
    local targetItem = forcedSelection or selectedItem
    
    if not targetItem or targetItem == "" then
        print("❌ No item selected! Current selection: " .. tostring(targetItem))
        return false
    end
    
    local currentTime = tick()
    if currentTime - lastBringTime < bringCooldown then
        return false
    end
    
    local playerCFrame = getPlayerCFrame()
    if not playerCFrame then
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
    
    print("🔍 Searching for items with exact name: '" .. targetItem .. "'")
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item.Name == targetItem and item:FindFirstChild("Main") then
            table.insert(itemsToProcess, item)
            print("✅ Found matching item: " .. item.Name)
        end
    end
    
    if #itemsToProcess == 0 then
        print("❌ No items found with name: '" .. targetItem .. "'")
        print("📋 Available items in workspace:")
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item:FindFirstChild("Main") then
                print("  - " .. item.Name)
            end
        end
        return false
    end
    
    print("🎯 Bringing " .. #itemsToProcess .. " " .. targetItem .. " items...")
    
    local radius = 3
    local height = 2
    
    for i, item in pairs(itemsToProcess) do
        local angle = (i - 1) * (math.pi * 2 / math.max(8, #itemsToProcess))
        local offsetX = math.cos(angle) * radius
        local offsetZ = math.sin(angle) * radius
        local offset = Vector3.new(offsetX, height, offsetZ)
        
        local success = bringItemToCFrame(item, playerCFrame, offset)
        
        if success then
            itemsBrought = itemsBrought + 1
            print("✅ Brought " .. item.Name .. " to player")
        else
            print("❌ Failed to bring " .. item.Name)
        end
        
        if i % 5 == 0 then
            wait(0.1)
        end
    end
    
    lastBringTime = currentTime
    
    if itemsBrought > 0 then
        print("✅ Successfully brought " .. itemsBrought .. " " .. targetItem .. "(s) to your location!")
        return true
    else
        print("❌ Failed to bring any " .. targetItem .. " items!")
        return false
    end
end

local function bringAllItems()
    local currentTime = tick()
    if currentTime - lastBringTime < bringCooldown then
        return false
    end
    
    local playerCFrame = getPlayerCFrame()
    if not playerCFrame then
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
    
    print("🎯 Bringing " .. #itemsToProcess .. " total items...")
    
    local radius = 5
    local height = 2
    
    for i, item in pairs(itemsToProcess) do
        local angle = (i - 1) * (math.pi * 2 / math.max(12, #itemsToProcess))
        local offsetX = math.cos(angle) * radius
        local offsetZ = math.sin(angle) * radius
        local offset = Vector3.new(offsetX, height, offsetZ)
        
        local success = bringItemToCFrame(item, playerCFrame, offset)
        
        if success then
            itemsBrought = itemsBrought + 1
        end
        
        if i % 8 == 0 then
            wait(0.1)
        end
    end
    
    lastBringTime = currentTime
    
    if itemsBrought > 0 then
        print("✅ Successfully brought " .. itemsBrought .. " items to your location!")
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
    return bringAllItems()
end

function BringItems.setSelectedItem(itemName)
    if itemName and type(itemName) == "string" and itemName ~= "" then
        selectedItem = itemName
        forcedSelection = itemName
        print("📦 FORCED SELECTION SET TO: " .. itemName)
        print("📦 BOTH VARIABLES SET TO: " .. itemName)
        return true
    else
        print("❌ Invalid item name provided: " .. tostring(itemName))
        return false
    end
end

function BringItems.forceSelectItem(itemName)
    if itemName and type(itemName) == "string" and itemName ~= "" then
        selectedItem = itemName
        forcedSelection = itemName
        print("🎯 FORCE SELECTED: " .. itemName)
        return true
    else
        print("❌ Force selection failed: " .. tostring(itemName))
        return false
    end
end

function BringItems.getSelectedItem()
    return forcedSelection or selectedItem
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
    local targetItem = itemName or forcedSelection or selectedItem
    if not targetItem then
        return 0
    end
    
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

function BringItems.clearSelection()
    selectedItem = nil
    forcedSelection = nil
    print("🧹 Both selections cleared")
end

function BringItems.getStatus()
    local currentSelection = forcedSelection or selectedItem
    local count = 0
    
    if currentSelection then
        count = BringItems.getItemCount(currentSelection)
    end
    
    return {
        selectedItem = currentSelection or "None",
        forcedSelection = forcedSelection,
        regularSelection = selectedItem,
        availableItemTypes = #availableItems,
        selectedItemCount = count,
        hasSelection = currentSelection ~= nil
    }
end

function BringItems.debugSelection()
    print("🐛 DETAILED DEBUG INFO:")
    print("  Regular Selected Item: " .. tostring(selectedItem))
    print("  Forced Selected Item: " .. tostring(forcedSelection))
    print("  Active Selection: " .. tostring(forcedSelection or selectedItem))
    print("  Available Items: " .. table.concat(availableItems, ", "))
    
    local currentSelection = forcedSelection or selectedItem
    if currentSelection then
        print("  Count of Active Selection: " .. BringItems.getItemCount(currentSelection))
        
        local itemsFolder = workspace:FindFirstChild("Items")
        if itemsFolder then
            print("  Items in workspace with this name:")
            for _, item in pairs(itemsFolder:GetChildren()) do
                if item:IsA("Model") and item.Name == currentSelection and item:FindFirstChild("Main") then
                    print("    - Found: " .. item.Name .. " at " .. tostring(item.Main.Position))
                end
            end
        end
    else
        print("  No active selection found!")
    end
end

function BringItems.listAllItems()
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        print("📋 ALL ITEMS IN WORKSPACE:")
        for i, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item:FindFirstChild("Main") then
                print("  " .. i .. ". " .. item.Name)
            end
        end
    end
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
