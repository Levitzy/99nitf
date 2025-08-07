local AutoCook = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

AutoCook.autoCookEnabled = false
AutoCook.cookDelay = 0.1
AutoCook.cookConnection = nil
AutoCook.lastCookTime = 0

function AutoCook.getMainFire()
    local workspace = game:GetService("Workspace")
    local map = workspace:WaitForChild("Map")
    local campground = map:WaitForChild("Campground")
    local mainFire = campground:WaitForChild("MainFire")
    
    return mainFire
end

function AutoCook.findAllRawMeat()
    local workspace = game:GetService("Workspace")
    local itemsFolder = workspace:WaitForChild("Items")
    
    local rawMeatItems = {}
    
    for _, item in pairs(itemsFolder:GetChildren()) do
        if item.Name == "Morsel" or item.Name == "Steak" then
            table.insert(rawMeatItems, {
                item = item,
                type = item.Name
            })
        end
    end
    
    return rawMeatItems
end

function AutoCook.cookItem(item)
    local mainFire = AutoCook.getMainFire()
    if not mainFire or not item or not item.Parent then
        return false
    end
    
    local success = pcall(function()
        local args = {
            mainFire,
            item
        }
        
        ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestCookItem"):FireServer(unpack(args))
    end)
    
    return success
end

function AutoCook.cookAllItems(rawMeatData)
    local currentTime = tick()
    if currentTime - AutoCook.lastCookTime < AutoCook.cookDelay then
        return false
    end
    
    local cookedCount = 0
    
    for _, meatData in pairs(rawMeatData) do
        if meatData.item and meatData.item.Parent then
            spawn(function()
                local success = AutoCook.cookItem(meatData.item)
                if success then
                    cookedCount = cookedCount + 1
                end
            end)
            wait(0.01)
        end
    end
    
    AutoCook.lastCookTime = currentTime
    return true
end

function AutoCook.autoCookLoop()
    if not AutoCook.autoCookEnabled then return end
    
    local allRawMeat = AutoCook.findAllRawMeat()
    
    if #allRawMeat > 0 then
        AutoCook.cookAllItems(allRawMeat)
    end
end

function AutoCook.setEnabled(enabled)
    AutoCook.autoCookEnabled = enabled
    
    if enabled then
        AutoCook.cookConnection = RunService.Heartbeat:Connect(AutoCook.autoCookLoop)
    else
        if AutoCook.cookConnection then
            AutoCook.cookConnection:Disconnect()
            AutoCook.cookConnection = nil
        end
    end
end

function AutoCook.setCookDelay(delay)
    AutoCook.cookDelay = delay
end

function AutoCook.getStatus()
    if AutoCook.autoCookEnabled then
        local allRawMeat = AutoCook.findAllRawMeat()
        local mainFire = AutoCook.getMainFire()
        
        if not mainFire then
            return "Status: MainFire not found!", 0
        elseif #allRawMeat > 0 then
            local morselCount = 0
            local steakCount = 0
            
            for _, meatData in pairs(allRawMeat) do
                if meatData.type == "Morsel" then
                    morselCount = morselCount + 1
                elseif meatData.type == "Steak" then
                    steakCount = steakCount + 1
                end
            end
            
            return string.format("Status: Cooking M:%d S:%d - Fast Mode!", 
                   morselCount, steakCount), #allRawMeat
        else
            return "Status: No raw meat found", 0
        end
    else
        return "Status: Auto cook disabled", 0
    end
end

return AutoCook