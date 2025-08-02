local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local BringItems = {}

local selectedItem = "Log"
local availableItems = {}
local lastBringTime = 0
local bringCooldown = 0.3
local autoStore = false
local autoStoreConnection

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

local function autoStoreItems()
    if not autoStore then
        return
    end
    
    local bag = getPlayerBag()
    if not bag then
        return
    end
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if not itemsFolder then
        return
    end
    
    local playerPos = getPlayerPosition()
    if not playerPos then
        return
    end
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item:FindFirstChild("Main") then
            local distance = (item.Main.Position - playerPos).Magnitude
            if distance <= 10 then
                local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents")
                if remoteEvent then
                    remoteEvent = remoteEvent:FindFirstChild("RequestBagStoreItem")
                    if remoteEvent then
                        pcall(function()
                            local args = {bag, item}
                            remoteEvent:InvokeServer(unpack(args))
                        end)
                        wait(0.1)
                    end
                end
            end
        end
    end
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
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item.Name == selectedItem and item:FindFirstChild("Main") then
            local success = pcall(function()
                local offsetX = math.random(-4, 4)
                local offsetZ = math.random(-4, 4)
                local newPosition = playerPosition + Vector3.new(offsetX, 1, offsetZ)
                
                item:SetPrimaryPartCFrame(CFrame.new(newPosition))
                
                if item.Main:FindFirstChild("BodyVelocity") then
                    item.Main.BodyVelocity:Destroy()
                end
                if item.Main:FindFirstChild("BodyAngularVelocity") then
                    item.Main.BodyAngularVelocity:Destroy()
                end
                if item.Main:FindFirstChild("BodyPosition") then
                    item.Main.BodyPosition:Destroy()
                end
                
                item.Main.Velocity = Vector3.new(0, 0, 0)
                item.Main.AngularVelocity = Vector3.new(0, 0, 0)
                item.Main.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                item.Main.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
            
            if success then
                itemsBrought = itemsBrought + 1
            end
            
            wait(0.02)
        end
    end
    
    lastBringTime = currentTime
    
    if itemsBrought > 0 then
        print("✅ Brought " .. itemsBrought .. " " .. selectedItem .. "(s)")
        return true
    else
        print("❌ No " .. selectedItem .. " items found!")
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
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item:FindFirstChild("Main") and item.Name ~= "Camera" then
            local success = pcall(function()
                local offsetX = math.random(-6, 6)
                local offsetZ = math.random(-6, 6)
                local newPosition = playerPosition + Vector3.new(offsetX, 1, offsetZ)
                
                item:SetPrimaryPartCFrame(CFrame.new(newPosition))
                
                if item.Main:FindFirstChild("BodyVelocity") then
                    item.Main.BodyVelocity:Destroy()
                end
                if item.Main:FindFirstChild("BodyAngularVelocity") then
                    item.Main.BodyAngularVelocity:Destroy()
                end
                if item.Main:FindFirstChild("BodyPosition") then
                    item.Main.BodyPosition:Destroy()
                end
                
                item.Main.Velocity = Vector3.new(0, 0, 0)
                item.Main.AngularVelocity = Vector3.new(0, 0, 0)
                item.Main.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                item.Main.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
            
            if success then
                itemsBrought = itemsBrought + 1
            end
            
            wait(0.01)
        end
    end
    
    lastBringTime = currentTime
    
    if itemsBrought > 0 then
        print("✅ Brought " .. itemsBrought .. " items")
        return true
    else
        print("❌ No items found!")
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
    print("📦 Selected: " .. itemName)
end

function BringItems.getSelectedItem()
    return selectedItem
end

function BringItems.getAvailableItems()
    return availableItems
end

function BringItems.refreshItems()
    local items = scanAvailableItems()
    print("🔄 Found " .. #items .. " item types")
    return items
end

function BringItems.setAutoStore(enabled)
    autoStore = enabled
    
    if enabled then
        print("🎒 Auto-store: ON")
        autoStoreConnection = RunService.Heartbeat:Connect(function()
            wait(0.5)
            autoStoreItems()
        end)
    else
        print("🎒 Auto-store: OFF")
        if autoStoreConnection then
            autoStoreConnection:Disconnect()
            autoStoreConnection = nil
        end
    end
end

function BringItems.getAutoStore()
    return autoStore
end

function BringItems.storeAllNearbyItems()
    local bag = getPlayerBag()
    if not bag then
        print("❌ No bag found in inventory!")
        return false
    end
    
    local itemsFolder = workspace:FindFirstChild("Items")
    if not itemsFolder then
        return false
    end
    
    local playerPos = getPlayerPosition()
    if not playerPos then
        return false
    end
    
    local itemsStored = 0
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item:FindFirstChild("Main") then
            local distance = (item.Main.Position - playerPos).Magnitude
            if distance <= 15 then
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
                        wait(0.1)
                    end
                end
            end
        end
    end
    
    if itemsStored > 0 then
        print("🎒 Stored " .. itemsStored .. " items in bag")
        return true
    else
        print("❌ No items to store nearby")
        return false
    end
end

function BringItems.getStatus()
    return {
        selectedItem = selectedItem,
        availableItemTypes = #availableItems,
        autoStore = autoStore,
        hasBag = getPlayerBag() ~= nil
    }
end

function BringItems.isEnabled()
    return false
end

function BringItems.toggle()
    return false
end

function BringItems.stop()
    if autoStoreConnection then
        autoStoreConnection:Disconnect()
        autoStoreConnection = nil
    end
    autoStore = false
    print("Bring Items: Stopped")
end

BringItems.refreshItems()

return BringItems
