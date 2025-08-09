local Webhook = {}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

Webhook.webhookEnabled = false
Webhook.webhookConnection = nil
Webhook.lastDay = 0
Webhook.lastNotifiedDay = 0
Webhook.url = "https://discord.com/api/webhooks/1383438355278336151/626zQx9Ob68IqsjEqomxRmaET282U2X1S1TL4D_8Q8yKjz5dc3kVlQissMVD5OGGXzDL"

function Webhook.SendMessage(url, message)
    pcall(function()
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
    end)
end

function Webhook.SendMessageEMBED(url, embed)
    pcall(function()
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
    end)
end

function Webhook.getHungerStatus()
    local success, result = pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        local interface = playerGui:WaitForChild("Interface", 5)
        local statBars = interface:WaitForChild("StatBars", 5)
        local hungerBar = statBars:WaitForChild("HungerBar", 5)
        
        if hungerBar:FindFirstChild("Fill") then
            local fillSize = hungerBar.Fill.Size.X.Scale
            local percentage = math.floor(fillSize * 100)
            return percentage
        elseif hungerBar:FindFirstChild("Bar") and hungerBar.Bar:FindFirstChild("Fill") then
            local fillSize = hungerBar.Bar.Fill.Size.X.Scale
            local percentage = math.floor(fillSize * 100)
            return percentage
        end
        
        return 0
    end)
    
    if success then
        return result
    else
        return 0
    end
end

function Webhook.getHungerStatusText(percentage)
    if percentage >= 80 then
        return "🟢 Well Fed (" .. percentage .. "%)"
    elseif percentage >= 60 then
        return "🟡 Satisfied (" .. percentage .. "%)"
    elseif percentage >= 40 then
        return "🟠 Peckish (" .. percentage .. "%)"
    elseif percentage >= 20 then
        return "🔴 Hungry (" .. percentage .. "%)"
    else
        return "🟥 Starving (" .. percentage .. "%)"
    end
end
    local success, result = pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        local interface = playerGui:WaitForChild("Interface", 5)
        local dayCounter = interface:WaitForChild("DayCounter", 5)
        
        if dayCounter.Text then
            local dayText = dayCounter.Text
            local dayNumber = string.match(dayText, "%d+")
            return tonumber(dayNumber) or 0
        end
        
        return 0
    end)
    
    if success then
        return result
    else
        return 0
    end
end

function Webhook.checkDayChange()
    if not Webhook.webhookEnabled then return end
    
    local currentDay = Webhook.getCurrentDay()
    
    if currentDay > Webhook.lastDay and currentDay > 0 and Webhook.lastDay > 0 then
        local data = {
            ["content"] = "@everyone",
            ["embeds"] = {
                {
                    ["title"] = "🌅 New Day Started!",
                    ["description"] = "A new day has begun in the forest survival game.",
                    ["color"] = 3447003,
                    ["fields"] = {
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
                        }
                    },
                    ["footer"] = {
                        ["text"] = "Forest Automation Suite - Day Tracker"
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
    elseif currentDay > 0 and Webhook.lastDay == 0 then
        Webhook.lastDay = currentDay
        print("Initial day set to: Day " .. currentDay)
    end
end

function Webhook.setEnabled(enabled)
    Webhook.webhookEnabled = enabled
    
    if enabled then
        Webhook.lastDay = Webhook.getCurrentDay()
        Webhook.lastNotifiedDay = Webhook.lastDay
        
        Webhook.webhookConnection = RunService.Heartbeat:Connect(function()
            Webhook.checkDayChange()
        end)
        
        local startEmbed = {
            ["title"] = "🚀 Day Tracker Started",
            ["description"] = "Forest Automation Suite day tracking is now active!",
            ["color"] = 65280,
            ["fields"] = {
                {
                    ["name"] = "📅 Current Day",
                    ["value"] = "Day " .. Webhook.lastDay,
                    ["inline"] = true
                },
                {
                    ["name"] = "🔔 Status",
                    ["value"] = "Monitoring for day changes",
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "Forest Automation Suite - Day Tracker"
            }
        }
        
        Webhook.SendMessageEMBED(Webhook.url, startEmbed)
        print("Day tracker started - Current day: " .. Webhook.lastDay)
    else
        if Webhook.webhookConnection then
            Webhook.webhookConnection:Disconnect()
            Webhook.webhookConnection = nil
        end
        
        local stopEmbed = {
            ["title"] = "⏹️ Day Tracker Stopped",
            ["description"] = "Forest Automation Suite day tracking has been disabled.",
            ["color"] = 16711680,
            ["fields"] = {
                {
                    ["name"] = "📅 Last Tracked Day",
                    ["value"] = "Day " .. Webhook.lastDay,
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "Forest Automation Suite - Day Tracker"
            }
        }
        
        Webhook.SendMessageEMBED(Webhook.url, stopEmbed)
        print("Day tracker stopped")
    end
end

function Webhook.setWebhookUrl(newUrl)
    Webhook.url = newUrl
    print("Webhook URL updated")
end

function Webhook.getStatus()
    if Webhook.webhookEnabled then
        local currentDay = Webhook.getCurrentDay()
        return string.format("Day Tracker: Active - Day %d", currentDay)
    else
        return "Day Tracker: Disabled"
    end
end

function Webhook.sendTestMessage()
    local hungerPercentage = Webhook.getHungerStatus()
    local hungerStatus = Webhook.getHungerStatusText(hungerPercentage)
    
    local data = {
        ["content"] = "@everyone",
        ["embeds"] = {
            {
                ["title"] = "🧪 Test Message",
                ["description"] = "This is a test message from Forest Automation Suite!",
                ["color"] = 16776960,
                ["fields"] = {
                    {
                        ["name"] = "📅 Current Day",
                        ["value"] = "Day " .. Webhook.getCurrentDay(),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "🍖 Hunger Status",
                        ["value"] = hungerStatus,
                        ["inline"] = true
                    },
                    {
                        ["name"] = "⏰ Time",
                        ["value"] = os.date("%H:%M:%S"),
                        ["inline"] = true
                    }
                },
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
    print("Test message sent")
end

return Webhook