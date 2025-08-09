local Webhook = {}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

Webhook.webhookEnabled = false
Webhook.webhookConnection = nil
Webhook.lastDay = 0
Webhook.dayNotificationSent = false
Webhook.lastCheckTime = 0
Webhook.checkInterval = 2
Webhook.url = "https://discord.com/api/webhooks/1383438355278336151/626zQx9Ob68IqsjEqomxRmaET282U2X1S1TL4D_8Q8yKjz5dc3kVlQissMVD5OGGXzDL"

function Webhook.SendMessage(url, message)
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local data = {
        ["content"] = message
    }
    local body = HttpService:JSONEncode(data)
    local response = request({
        Url = url,
        Method = "POST",
        Headers = headers,
        Body = body
    })
    print("Message sent to Discord")
end

function Webhook.SendMessageEMBED(url, embed)
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local data = {
        ["embeds"] = {
            {
                ["title"] = embed.title,
                ["description"] = embed.description,
                ["color"] = embed.color,
                ["fields"] = embed.fields,
                ["footer"] = {
                    ["text"] = embed.footer.text
                }
            }
        }
    }
    local body = HttpService:JSONEncode(data)
    local response = request({
        Url = url,
        Method = "POST",
        Headers = headers,
        Body = body
    })
    print("Embed sent to Discord")
end

function Webhook.getCurrentDay()
    local success, result = pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return 0 end
        
        local interface = playerGui:FindFirstChild("Interface")
        if not interface then return 0 end
        
        local dayCounter = interface:FindFirstChild("DayCounter")
        if not dayCounter then return 0 end
        
        if dayCounter.Text then
            local dayText = dayCounter.Text
            local dayNumber = string.match(dayText, "%d+")
            return tonumber(dayNumber) or 0
        end
        
        return 0
    end)
    
    if success and result then
        return result
    else
        return 0
    end
end

function Webhook.getHungerPercentage()
    local attempts = {
        -- Method 1: Direct path based on screenshot
        function()
            local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
            local interface = playerGui.Interface
            local statBars = interface.StatBars
            local hungerBar = statBars.HungerBar
            local bar = hungerBar.Bar
            
            if bar and bar.Size and bar.Size.X then
                local scale = bar.Size.X.Scale
                return math.floor(scale * 100)
            end
            return nil
        end,
        
        -- Method 2: Wait for children approach
        function()
            local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            local interface = playerGui:WaitForChild("Interface")
            local statBars = interface:WaitForChild("StatBars")
            local hungerBar = statBars:WaitForChild("HungerBar")
            local bar = hungerBar:WaitForChild("Bar")
            
            if bar and bar.Size and bar.Size.X then
                local scale = bar.Size.X.Scale
                return math.floor(scale * 100)
            end
            return nil
        end,
        
        -- Method 3: FindFirstChild approach
        function()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if not playerGui then return nil end
            
            local interface = playerGui:FindFirstChild("Interface")
            if not interface then return nil end
            
            local statBars = interface:FindFirstChild("StatBars")
            if not statBars then return nil end
            
            local hungerBar = statBars:FindFirstChild("HungerBar")
            if not hungerBar then return nil end
            
            local bar = hungerBar:FindFirstChild("Bar")
            if not bar then return nil end
            
            if bar.Size and bar.Size.X then
                local scale = bar.Size.X.Scale
                return math.floor(scale * 100)
            end
            return nil
        end,
        
        -- Method 4: Try different bar names
        function()
            local path = game:GetService("Players").LocalPlayer.PlayerGui.Interface.StatBars.HungerBar
            
            for _, barName in pairs({"Bar", "Fill", "Progress", "Amount", "Level"}) do
                local bar = path:FindFirstChild(barName)
                if bar and bar.Size and bar.Size.X then
                    local scale = bar.Size.X.Scale
                    return math.floor(scale * 100)
                end
            end
            return nil
        end
    }
    
    -- Try each method until one works
    for i, method in pairs(attempts) do
        local success, result = pcall(method)
        if success and result and result > 0 then
            print("Hunger method " .. i .. " worked: " .. result .. "%")
            return math.max(0, math.min(100, result))
        end
    end
    
    -- If all methods fail, try to debug what's available
    pcall(function()
        local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
        local interface = playerGui.Interface
        local statBars = interface.StatBars
        local hungerBar = statBars.HungerBar
        
        print("HungerBar children:")
        for _, child in pairs(hungerBar:GetChildren()) do
            print(" - " .. child.Name .. " (" .. child.ClassName .. ")")
            if child.Name == "Bar" and child.Size then
                print("   Bar Size: " .. tostring(child.Size))
                print("   Bar Size.X.Scale: " .. tostring(child.Size.X.Scale))
            end
        end
    end)
    
    return 0
end

function Webhook.getHungerStatus(percentage)
    if percentage >= 80 then
        return "🟢 Well Fed"
    elseif percentage >= 60 then
        return "🟡 Satisfied" 
    elseif percentage >= 40 then
        return "🟠 Getting Hungry"
    elseif percentage >= 20 then
        return "🔴 Hungry"
    else
        return "💀 Starving"
    end
end

function Webhook.checkDayChange()
    if not Webhook.webhookEnabled then return end
    
    local currentTime = tick()
    if currentTime - Webhook.lastCheckTime < Webhook.checkInterval then
        return
    end
    Webhook.lastCheckTime = currentTime
    
    local currentDay = Webhook.getCurrentDay()
    if currentDay == 0 then return end -- Skip if can't get day
    
    if currentDay > Webhook.lastDay and Webhook.lastDay > 0 and not Webhook.dayNotificationSent then
        Webhook.dayNotificationSent = true
        
        local hungerPercentage = Webhook.getHungerPercentage()
        local hungerStatus = Webhook.getHungerStatus(hungerPercentage)
        
        -- Only include hunger info if we can get it
        local fields = {
            {
                ["name"] = "📅 Current Day",
                ["value"] = "Day " .. currentDay,
                ["inline"] = true
            },
            {
                ["name"] = "📈 Previous Day",
                ["value"] = "Day " .. Webhook.lastDay,
                ["inline"] = true
            },
            {
                ["name"] = "⏰ Time",
                ["value"] = os.date("%H:%M:%S"),
                ["inline"] = true
            },
            {
                ["name"] = "👤 Player",
                ["value"] = LocalPlayer.Name,
                ["inline"] = true
            },
            {
                ["name"] = "🎮 Game Status",
                ["value"] = "Surviving Day " .. currentDay,
                ["inline"] = true
            }
        }
        
        -- Only add hunger field if we successfully got the percentage
        if hungerPercentage > 0 then
            table.insert(fields, 3, {
                ["name"] = "🍖 Hunger Status",
                ["value"] = hungerStatus .. " (" .. hungerPercentage .. "%)",
                ["inline"] = true
            })
        end
        
        local data = {
            ["content"] = "@everyone",
            ["embeds"] = {
                {
                    ["title"] = "🌅 New Day Started!",
                    ["description"] = "A new day has begun in the forest survival game.",
                    ["color"] = 3447003,
                    ["fields"] = fields,
                    ["footer"] = {
                        ["text"] = "Forest Automation Suite - Day Tracker v2.0"
                    }
                }
            }
        }
        
        local headers = {
            ["Content-Type"] = "application/json"
        }
        local body = HttpService:JSONEncode(data)
        local response = request({
            Url = Webhook.url,
            Method = "POST",
            Headers = headers,
            Body = body
        })
        
        Webhook.lastDay = currentDay
        print("Day changed notification sent: Day " .. currentDay)
        
        spawn(function()
            wait(5)
            Webhook.dayNotificationSent = false
        end)
        
    elseif currentDay > 0 and Webhook.lastDay == 0 then
        Webhook.lastDay = currentDay
        Webhook.dayNotificationSent = false
        print("Initial day set to: Day " .. currentDay)
    elseif currentDay == Webhook.lastDay then
        Webhook.dayNotificationSent = false
    end
end

function Webhook.setEnabled(enabled)
    Webhook.webhookEnabled = enabled
    
    if enabled then
        Webhook.lastDay = Webhook.getCurrentDay()
        Webhook.dayNotificationSent = false
        
        Webhook.webhookConnection = RunService.Heartbeat:Connect(function()
            Webhook.checkDayChange()
        end)
        
        local hungerPercentage = Webhook.getHungerPercentage()
        local hungerStatus = Webhook.getHungerStatus(hungerPercentage)
        
        local startEmbed = {
            ["title"] = "🚀 Day Tracker Started",
            ["description"] = "Forest Automation Suite day tracking is now active with hunger monitoring!",
            ["color"] = 65280,
            ["fields"] = {
                {
                    ["name"] = "📅 Current Day",
                    ["value"] = "Day " .. Webhook.lastDay,
                    ["inline"] = true
                },
                {
                    ["name"] = "🍖 Current Hunger",
                    ["value"] = hungerStatus .. " (" .. hungerPercentage .. "%)",
                    ["inline"] = true
                },
                {
                    ["name"] = "🔔 Status",
                    ["value"] = "Monitoring for day changes",
                    ["inline"] = true
                },
                {
                    ["name"] = "👤 Player",
                    ["value"] = LocalPlayer.Name,
                    ["inline"] = true
                },
                {
                    ["name"] = "⏰ Started At",
                    ["value"] = os.date("%H:%M:%S"),
                    ["inline"] = true
                },
                {
                    ["name"] = "🎯 Features",
                    ["value"] = "Day tracking + Hunger monitoring",
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "Forest Automation Suite - Day Tracker v2.0"
            }
        }
        
        Webhook.SendMessageEMBED(Webhook.url, startEmbed)
        print("Day tracker started - Current day: " .. Webhook.lastDay .. " with " .. hungerPercentage .. "% hunger")
    else
        if Webhook.webhookConnection then
            Webhook.webhookConnection:Disconnect()
            Webhook.webhookConnection = nil
        end
        
        local hungerPercentage = Webhook.getHungerPercentage()
        local hungerStatus = Webhook.getHungerStatus(hungerPercentage)
        
        local stopEmbed = {
            ["title"] = "⏹️ Day Tracker Stopped",
            ["description"] = "Forest Automation Suite day tracking has been disabled.",
            ["color"] = 16711680,
            ["fields"] = {
                {
                    ["name"] = "📅 Last Tracked Day",
                    ["value"] = "Day " .. Webhook.lastDay,
                    ["inline"] = true
                },
                {
                    ["name"] = "🍖 Final Hunger",
                    ["value"] = hungerStatus .. " (" .. hungerPercentage .. "%)",
                    ["inline"] = true
                },
                {
                    ["name"] = "⏰ Stopped At",
                    ["value"] = os.date("%H:%M:%S"),
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "Forest Automation Suite - Day Tracker v2.0"
            }
        }
        
        Webhook.SendMessageEMBED(Webhook.url, stopEmbed)
        print("Day tracker stopped")
        
        Webhook.dayNotificationSent = false
    end
end

function Webhook.setWebhookUrl(newUrl)
    Webhook.url = newUrl
    print("Webhook URL updated")
end

function Webhook.getStatus()
    if Webhook.webhookEnabled then
        local currentDay = Webhook.getCurrentDay()
        local hungerPercentage = Webhook.getHungerPercentage()
        return string.format("Day Tracker: Active - Day %d | Hunger: %d%%", currentDay, hungerPercentage)
    else
        return "Day Tracker: Disabled"
    end
end

function Webhook.sendTestMessage()
    local hungerPercentage = Webhook.getHungerPercentage()
    local hungerStatus = Webhook.getHungerStatus(hungerPercentage)
    
    -- Force debug the hunger bar structure
    print("=== HUNGER BAR DEBUG ===")
    local debugInfo = ""
    pcall(function()
        local path = game:GetService("Players").LocalPlayer.PlayerGui.Interface.StatBars.HungerBar
        debugInfo = "HungerBar found! Children: "
        for _, child in pairs(path:GetChildren()) do
            debugInfo = debugInfo .. child.Name .. "(" .. child.ClassName .. ") "
            if child.Name == "Bar" then
                debugInfo = debugInfo .. "[Size:" .. tostring(child.Size) .. "] "
            end
        end
        print(debugInfo)
    end)
    
    local fields = {
        {
            ["name"] = "📅 Current Day",
            ["value"] = "Day " .. Webhook.getCurrentDay(),
            ["inline"] = true
        },
        {
            ["name"] = "⏰ Time",
            ["value"] = os.date("%H:%M:%S"),
            ["inline"] = true
        },
        {
            ["name"] = "👤 Player",
            ["value"] = LocalPlayer.Name,
            ["inline"] = true
        },
        {
            ["name"] = "🎮 Test Status",
            ["value"] = "All systems operational",
            ["inline"] = true
        },
        {
            ["name"] = "🔧 Version",
            ["value"] = "Day Tracker v2.0",
            ["inline"] = true
        }
    }
    
    -- Add hunger info if available
    if hungerPercentage > 0 then
        table.insert(fields, 2, {
            ["name"] = "🍖 Hunger Status",
            ["value"] = hungerStatus .. " (" .. hungerPercentage .. "%)",
            ["inline"] = true
        })
    else
        table.insert(fields, 2, {
            ["name"] = "🍖 Hunger Status",
            ["value"] = "❌ Could not read hunger bar",
            ["inline"] = true
        })
        
        -- Add debug info to Discord
        if debugInfo ~= "" then
            table.insert(fields, {
                ["name"] = "🔍 Debug Info",
                ["value"] = debugInfo,
                ["inline"] = false
            })
        end
    end
    
    local data = {
        ["content"] = "@everyone",
        ["embeds"] = {
            {
                ["title"] = "🧪 Test Message with Force Debug",
                ["description"] = "Testing hunger bar detection with aggressive debugging!",
                ["color"] = 16776960,
                ["fields"] = fields,
                ["footer"] = {
                    ["text"] = "Forest Automation Suite - Force Test Message"
                }
            }
        }
    }
    
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local body = HttpService:JSONEncode(data)
    local response = request({
        Url = Webhook.url,
        Method = "POST",
        Headers = headers,
        Body = body
    })
    print("Force test message sent - Hunger: " .. hungerPercentage .. "%")
    print("Debug complete!")
end

return Webhook