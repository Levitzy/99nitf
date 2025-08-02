local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local BringItems = {}

local selectedItem = nil
local availableItems = {}
local lastBringTime = 0
local bringCooldown = 0.05

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

local function getHumanoidPosition()
    local character = getPlayerCharacter()
    if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
        return character.HumanoidRootPart.Position
    end
    return nil
end

local function scanAvailableItems()
    local items = {}
    local itemCounts = {}
    
    print("🔍 Starting item scan...")
    print("🔍 Checking workspace for Items folder...")
    
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if not itemsFolder then
        print("❌ No Items folder found in workspace!")
        print("🔍 Workspace children:")
        for _, child in pairs(workspace:GetChildren()) do
            print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
        end
        availableItems = {}
        return {}
    end
    
    print("✅ Items folder found! Scanning items...")
    print("🔍 Items folder has " .. #itemsFolder:GetChildren() .. " children")
    
    local itemNames = {}
    local totalItems = 0
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") then
            totalItems = totalItems + 1
            print("🔍 Found model: " .. item.Name .. " (Has Main: " .. tostring(item:FindFirstChild("Main") ~= nil) .. ")")
            
            if item.Name ~= "Camera" and item:FindFirstChild("Main") then
                local itemName = item.Name
                if not itemNames[itemName] then
                    itemNames[itemName] = true
                    table.insert(items, itemName)
                    itemCounts[itemName] = 1
                    print("✅ Added new item type: " .. itemName)
                else
                    itemCounts[itemName] = itemCounts[itemName] + 1
                end
            end
        end
    end
    
    table.sort(items)
    
    print("📊 Scan complete!")
    print("📊 Total models in Items folder: " .. totalItems)
    print("📊 Valid item types found: " .. #items)
    print("📊 Item counts:")
    for itemName, count in pairs(itemCounts) do
        print("  - " .. itemName .. ": " .. count)
    end
    
    availableItems = items
    return items
end

local function dropItemAtPlayer(item)
    if not item or not item:FindFirstChild("Main") then
        return false
    end
    
    local playerPos = getHumanoidPosition()
    if not playerPos then
        return false
    end
    
    local success = pcall(function()
        local main = item.Main
        
        main.Anchored = false
        main.CanCollide = true
        
        if main:FindFirstChild("BodyVelocity") then
            main.BodyVelocity:Destroy()
        end
        if main:FindFirstChild("BodyAngularVelocity") then
            main.BodyAngularVelocity:Destroy()
        end
        if main:FindFirstChild("BodyPosition") then
            main.BodyPosition:Destroy()
        end
        
        local randomX = math.random(-2, 2)
        local randomZ = math.random(-2, 2)
        local dropPosition = playerPos + Vector3.new(randomX, 1, randomZ)
        
        item:SetPrimaryPartCFrame(CFrame.new(dropPosition))
        
        main.Velocity = Vector3.new(0, 0, 0)
        main.AngularVelocity = Vector3.new(0, 0, 0)
        
        if main.AssemblyLinearVelocity then
            main.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        if main.AssemblyAngularVelocity then
            main.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end)
    
    return success
end

local function bringSelectedItems()
    if not selectedItem or selectedItem == "" or selectedItem == "None" then
        print("❌ No item selected! Current selection: " .. tostring(selectedItem))
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
    
    print("🔍 Searching for items with exact name: '" .. selectedItem .. "'")
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item.Name == selectedItem and item:FindFirstChild("Main") then
            table.insert(itemsToProcess, item)
            print("✅ Found matching item: " .. item.Name)
        end
    end
    
    if #itemsToProcess == 0 then
        print("❌ No items found with name: '" .. selectedItem .. "'")
        print("📋 Available items in workspace:")
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item:FindFirstChild("Main") then
                print("  - " .. item.Name)
            end
        end
        return false
    end
    
    print("🎯 Bringing " .. #itemsToProcess .. " " .. selectedItem .. " items...")
    
    for i, item in pairs(itemsToProcess) do
        local radius = 3 + math.floor(i / 8) * 2
        local angle = (i - 1) * (math.pi * 2 / 8)
        local offsetX = math.cos(angle) * radius
        local offsetZ = math.sin(angle) * radius
        local height = 3
        
        local offset = Vector3.new(offsetX, height, offsetZ)
        local bringCFrame = playerCFrame * CFrame.new(offset)
        
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
            
            item:SetPrimaryPartCFrame(bringCFrame)
            
            main.Velocity = Vector3.new(0, 0, 0)
            main.AngularVelocity = Vector3.new(0, 0, 0)
            
            if main.AssemblyLinearVelocity then
                main.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
            if main.AssemblyAngularVelocity then
                main.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
            
            wait(0.2)
            
            dropItemAtPlayer(item)
        end)
        
        if success then
            itemsBrought = itemsBrought + 1
            print("✅ Brought and dropped " .. item.Name)
        else
            print("❌ Failed to bring " .. item.Name)
        end
        
        if i % 5 == 0 then
            wait(0.1)
        end
    end
    
    lastBringTime = currentTime
    
    if itemsBrought > 0 then
        print("✅ Successfully brought " .. itemsBrought .. " " .. selectedItem .. "(s) and dropped them at your position!")
        return true
    else
        print("❌ Failed to bring any " .. selectedItem .. " items!")
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
    
    for i, item in pairs(itemsToProcess) do
        local radius = 4 + math.floor(i / 12) * 2
        local angle = (i - 1) * (math.pi * 2 / 12)
        local offsetX = math.cos(angle) * radius
        local offsetZ = math.sin(angle) * radius
        local height = 3
        
        local offset = Vector3.new(offsetX, height, offsetZ)
        local bringCFrame = playerCFrame * CFrame.new(offset)
        
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
            
            item:SetPrimaryPartCFrame(bringCFrame)
            
            main.Velocity = Vector3.new(0, 0, 0)
            main.AngularVelocity = Vector3.new(0, 0, 0)
            
            if main.AssemblyLinearVelocity then
                main.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
            if main.AssemblyAngularVelocity then
                main.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
            
            wait(0.15)
            
            dropItemAtPlayer(item)
        end)
        
        if success then
            itemsBrought = itemsBrought + 1
        end
        
        if i % 8 == 0 then
            wait(0.1)
        end
    end
    
    lastBringTime = currentTime
    
    if itemsBrought > 0 then
        print("✅ Successfully brought " .. itemsBrought .. " items and dropped them at your position!")
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
    if itemName and type(itemName) == "string" and itemName ~= "" and itemName ~= "None" then
        selectedItem = itemName
        print("📦 SELECTION UPDATED TO: " .. itemName)
        return true
    else
        selectedItem = nil
        print("🧹 Selection cleared or invalid: " .. tostring(itemName))
        return false
    end
end

function BringItems.getSelectedItem()
    return selectedItem
end

function BringItems.getAvailableItems()
    return availableItems
end

function BringItems.refreshItems()
    print("🔄 REFRESHING ITEMS LIST...")
    local items = scanAvailableItems()
    print("🔄 Refresh complete - found " .. #items .. " item types")
    return items
end

function BringItems.getItemCount(itemName)
    local targetItem = itemName or selectedItem
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
    
    print("📊 Count for '" .. targetItem .. "': " .. count)
    return count
end

function BringItems.clearSelection()
    selectedItem = nil
    print("🧹 Selection cleared")
end

function BringItems.getStatus()
    local count = 0
    if selectedItem then
        count = BringItems.getItemCount(selectedItem)
    end
    
    print("📊 Status check - Selected: " .. tostring(selectedItem) .. ", Count: " .. count)
    
    return {
        selectedItem = selectedItem or "None",
        availableItemTypes = #availableItems,
        selectedItemCount = count,
        hasSelection = selectedItem ~= nil
    }
end

function BringItems.debugSelection()
    print("🐛 DETAILED DEBUG INFO:")
    print("  Selected Item: " .. tostring(selectedItem))
    print("  Available Items: " .. table.concat(availableItems, ", "))
    print("  Available Items Count: " .. #availableItems)
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if itemsFolder then
        print("  Items folder children count: " .. #itemsFolder:GetChildren())
        print("  Items folder contents:")
        for i, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") then
                print("    " .. i .. ". " .. item.Name .. " (Has Main: " .. tostring(item:FindFirstChild("Main") ~= nil) .. ")")
            end
        end
    else
        print("  ❌ Items folder not found!")
    end
    
    if selectedItem then
        print("  Count of Selected Item: " .. BringItems.getItemCount(selectedItem))
    end
end

function BringItems.forceRefresh()
    print("🔄 FORCE REFRESH TRIGGERED!")
    availableItems = {}
    selectedItem = nil
    local items = scanAvailableItems()
    print("🔄 Force refresh complete - found " .. #items .. " items")
    return items
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

-- Initial scan on load
print("🚀 BringItems module loading - performing initial scan...")
BringItems.refreshItems()

return BringItems
