local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local BringItems = {}

local selectedItem = "Log"
local availableItems = {}
local lastBringTime = 0
local bringCooldown = 0.05

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

local function teleportItem(item, targetPosition)
    if not item or not item:FindFirstChild("Main") then
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
        
        main.CFrame = CFrame.new(targetPosition)
        main.Velocity = Vector3.new(0, 0, 0)
        main.AngularVelocity = Vector3.new(0, 0, 0)
        
        if main.AssemblyLinearVelocity then
            main.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        if main.AssemblyAngularVelocity then
            main.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
        
        wait(0.1)
        main.Anchored = false
        main.CanCollide = true
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
    local radius = 4
    local angleStep = (2 * math.pi) / 8
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item.Name == selectedItem and item:FindFirstChild("Main") then
            local angle = angleStep * itemsBrought
            local offsetX = math.cos(angle) * radius
            local offsetZ = math.sin(angle) * radius
            local newPosition = playerPosition + Vector3.new(offsetX, 2, offsetZ)
            
            local success = teleportItem(item, newPosition)
            
            if success then
                itemsBrought = itemsBrought + 1
            end
            
            if itemsBrought >= 8 then
                radius = radius + 3
                itemsBrought = 0
            end
            
            wait(0.05)
        end
    end
    
    lastBringTime = currentTime
    
    if itemsBrought > 0 or itemsBrought == 0 then
        local totalItems = 0
        for _, item in pairs(itemsFolder:GetChildren()) do
            if item:IsA("Model") and item.Name == selectedItem and item:FindFirstChild("Main") then
                totalItems = totalItems + 1
            end
        end
        
        if totalItems > 0 then
            print("✅ Brought " .. totalItems .. " " .. selectedItem .. "(s) to you!")
            return true
        else
            print("❌ No " .. selectedItem .. " items found!")
            return false
        end
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
    
    local playerPosition = playerCharacter.HumanoidRootPart.Position
    local itemsFolder = workspace:FindFirstChild("Items")
    
    if not itemsFolder then
        print("❌ Items folder not found!")
        return false
    end
    
    local itemsBrought = 0
    local radius = 5
    local angleStep = (2 * math.pi) / 10
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item:FindFirstChild("Main") and item.Name ~= "Camera" then
            local angle = angleStep * itemsBrought
            local offsetX = math.cos(angle) * radius
            local offsetZ = math.sin(angle) * radius
            local newPosition = playerPosition + Vector3.new(offsetX, 2, offsetZ)
            
            local success = teleportItem(item, newPosition)
            
            if success then
                itemsBrought = itemsBrought + 1
            end
            
            if itemsBrought >= 10 then
                radius = radius + 4
                itemsBrought = 0
            end
            
            wait(0.03)
        end
    end
    
    lastBringTime = currentTime
    
    local totalItems = 0
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item:IsA("Model") and item:FindFirstChild("Main") and item.Name ~= "Camera" then
            totalItems = totalItems + 1
        end
    end
    
    if totalItems > 0 then
        print("✅ Brought " .. totalItems .. " items to you!")
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
    return bringAllItems()
end

function BringItems.setSelectedItem(itemName)
    if itemName and type(itemName) == "string" then
        selectedItem = itemName
        print("📦 Selected item: " .. itemName)
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

function BringItems.getStatus()
    return {
        selectedItem = selectedItem,
        availableItemTypes = #availableItems,
        selectedItemCount = BringItems.getItemCount(),
        totalItems = BringItems.getItemCount("all")
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
