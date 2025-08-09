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
    local success, result = pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return 0 end
        
        local interface = playerGui:FindFirstChild("Interface")
        if not interface then return 0 end
        
        local statBars = interface:FindFirstChild("StatBars")
        if not statBars then return 0 end
        
        local hungerBar = statBars:FindFirstChild("HungerBar")
        if not hungerBar then return 0 end
        
        -- Try multiple possible bar structures
        local bar = hungerBar:FindFirstChild("Bar") or hungerBar:FindFirstChild("Frame") or hungerBar:FindFirstChildOfClass("Frame")
        if not bar then return 0 end
        
        -- Check if bar has Size property
        if bar.Size and bar.Size.X and bar.Size.X.Scale then
            local currentSize = bar.Size.X.Scale
            local percentage = math.floor(currentSize * 100)
            return math.max(0, math.min(100, percentage))
        end
        
        return 0
    end)
    
    if success and result then
        return result
    else
        return 0
    end
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
    
    local data = {
        ["content"] = "@everyone",
        ["embeds"] = {
            {
                ["title"] = "🧪 Test Message",
                ["description"] = "This is a test message from Forest Automation Suite with hunger tracking!",
                ["color"] = 16776960,
                ["fields"] = {
                    {
                        ["name"] = "📅 Current Day",
                        ["value"] = "Day " .. Webhook.getCurrentDay(),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "🍖 Hunger Status",
                        ["value"] = hungerStatus .. " (" .. hungerPercentage .. "%)",
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
                ],
                ["footer"] = {
                    ["text"] = "Forest Automation Suite - Test Message"
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
    print("Test message sent with hunger: " .. hungerPercentage .. "%")
end

return Webhook