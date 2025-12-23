local TreeChopper = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/tree.lua'))()
local AutoFuel = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofuel.lua'))()
local Fly = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/fly.lua'))()
local AutoKill = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/kill.lua'))()
local AutoCook = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autocook.lua'))()
local AutoPlant = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autoplant.lua'))()
local AutoFeed = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/autofeed.lua'))()
local Webhook = loadstring(game:HttpGet('https://raw.githubusercontent.com/Levitzy/99nitf/refs/heads/main/webhook.lua'))()

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Forest Automation Suite v2.2",
    Folder = "ForestAutomation",
    Icon = "trees",
    IconSize = 20,
    NewElements = true,
    HideSearchBar = false,
    
    OpenButton = {
        Title = "Open Forest UI",
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new(
            Color3.fromRGB(76, 175, 80),
            Color3.fromRGB(30, 80, 40)
        )
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    }
})

local Tabs = {
    Flight = Window:Tab({ Title = "Flight", Icon = "plane", IconShape = "Square" }),
    Forest = Window:Tab({ Title = "Forest", Icon = "tree-pine", IconShape = "Square" }),
    Combat = Window:Tab({ Title = "Combat", Icon = "sword", IconShape = "Square" }),
    Discord = Window:Tab({ Title = "Discord", Icon = "message-circle", IconShape = "Square" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "settings", IconShape = "Square" })
}

local RunService = game:GetService("RunService")

-- Flight Tab
Tabs.Flight:Toggle({
    Title = "Enable Flight",
    Desc = "Toggle flight mode with WASD controls",
    Callback = function(Value)
        local success = Fly.setEnabled(Value)
        
        if Value and success then
            WindUI:Notify({
                Title = "Flight System",
                Content = "Flight enabled! Use WASD + Space/Shift to fly",
                Duration = 4
            })
        elseif Value and not success then
            WindUI:Notify({
                Title = "Flight Error",
                Content = "Could not enable flight - character not found!",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "Flight System", 
                Content = "Flight disabled - landing complete",
                Duration = 2
            })
        end
    end
})

Tabs.Flight:Slider({
    Title = "Flight Speed",
    Desc = "Adjust your flying speed",
    Step = 1,
    Value = {
        Min = 1,
        Max = 200,
        Default = 50,
    },
    Callback = function(Value)
        Fly.setSpeed(Value)
    end
})

Tabs.Forest:Dropdown({
    Title = "Tree Selection",
    Desc = "Select which trees to chop",
    Multi = true,
    Values = {
        "Small Tree",
        "Snowy Small Tree",
        "TreeBig1"
    },
    Value = {"Small Tree", "Snowy Small Tree", "TreeBig1"},
    Callback = function(Value)
        -- Handle Multi-Select (Table) or Single-Select (String/Table)
        local names = {}
        if type(Value) == "table" then
            for k, v in pairs(Value) do
                -- If it's a list of strings { "A", "B" }
                if type(k) == "number" and type(v) == "string" then
                    table.insert(names, v)
                -- If it's a dictionary { ["A"] = true }
                elseif type(k) == "string" and v == true then
                    table.insert(names, k)
                end
            end
        elseif type(Value) == "string" then
            table.insert(names, Value)
        end
        
        -- Fallback if empty (prevent breaking)
        if #names == 0 then
            names = {"Small Tree", "Snowy Small Tree", "TreeBig1"} 
        end
        
        TreeChopper.setTargetNames(names)
        
        WindUI:Notify({
            Title = "Tree Selector",
            Content = "Target trees updated!",
            Duration = 2
        })
    end
})

Tabs.Forest:Toggle({
    Title = "Auto Tree Chopper",
    Desc = "Automatically chop all small trees on the map",
    Callback = function(Value)
        TreeChopper.setEnabled(Value)
        
        if Value then
            WindUI:Notify({
                Title = "Tree Chopper",
                Content = "Started chopping all small trees!",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "Tree Chopper",
                Content = "Tree chopping stopped",
                Duration = 2
            })
        end
    end
})

Tabs.Forest:Toggle({
    Title = "Auto Plant Saplings", 
    Desc = "Plant saplings at their current locations",
    Callback = function(Value)
        AutoPlant.setEnabled(Value)
        
        if Value then
            WindUI:Notify({
                Title = "Auto Plant",
                Content = "Planting saplings for forest regeneration!",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "Auto Plant",
                Content = "Sapling planting stopped",
                Duration = 2
            })
        end
    end
})

Tabs.Forest:Toggle({
    Title = "Auto Fuel System",
    Desc = "Teleport fuel items to MainFire at (0,4,-3)",
    Callback = function(Value)
        AutoFuel.setEnabled(Value)
        
        if Value then
            WindUI:Notify({
                Title = "Auto Fuel",
                Content = "Fuel management system active!",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "Auto Fuel",
                Content = "Fuel automation stopped",
                Duration = 2
            })
        end
    end
})

-- Combat Tab
Tabs.Combat:Toggle({
    Title = "Auto Combat System",
    Desc = "Attack all hostile creatures (Bunny, Wolf, Cultist, etc.)",
    Callback = function(Value)
        AutoKill.setEnabled(Value)
        
        if Value then
            WindUI:Notify({
                Title = "Combat System",
                Content = "Engaging all hostile targets!",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "Combat System",
                Content = "Combat automation stopped",
                Duration = 2
            })
        end
    end
})

Tabs.Combat:Toggle({
    Title = "Auto Cooking System",
    Desc = "Cook all raw meat (Morsel & Steak) automatically",
    Callback = function(Value)
        AutoCook.setEnabled(Value)
        
        if Value then
            WindUI:Notify({
                Title = "Cooking System",
                Content = "Auto-cooking all raw meat!",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "Cooking System", 
                Content = "Cooking automation stopped",
                Duration = 2
            })
        end
    end
})

Tabs.Combat:Toggle({
    Title = "Auto Feed System",
    Desc = "Automatically eat Cooked Morsels when hungry",
    Callback = function(Value)
        AutoFeed.setEnabled(Value)
        
        if Value then
            WindUI:Notify({
                Title = "Auto Feed",
                Content = "Auto-feeding system activated!",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "Auto Feed", 
                Content = "Auto-feeding stopped",
                Duration = 2
            })
        end
    end
})

Tabs.Combat:Dropdown({
    Title = "Feed Threshold",
    Desc = "Start feeding when hunger drops to this level",
    Values = {
        {Title = "25%"},
        {Title = "50%"},
        {Title = "75%"},
        {Title = "80%"}
    },
    Value = "80%",
    Callback = function(Option)
        -- Option matches the table entry, e.g., {Title = "80%"}
        local val = Option.Title
        local threshold = tonumber(string.match(val, "%d+"))
        AutoFeed.setFeedThreshold(threshold)
        
        WindUI:Notify({
            Title = "Feed Threshold",
            Content = "Feed threshold set to " .. threshold .. "%",
            Duration = 2
        })
    end
})

-- Discord Tab
Tabs.Discord:Toggle({
    Title = "Day Tracker",
    Desc = "Get Discord notifications when a new day starts",
    Callback = function(Value)
        Webhook.setEnabled(Value)
        
        if Value then
            WindUI:Notify({
                Title = "Day Tracker",
                Content = "Discord notifications enabled for day changes!",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "Day Tracker",
                Content = "Discord notifications disabled",
                Duration = 2
            })
        end
    end
})

Tabs.Discord:Button({
    Title = "Send Test Message",
    Desc = "Send a test message to Discord to verify webhook works",
    Callback = function()
        Webhook.sendTestMessage()
        WindUI:Notify({
            Title = "Test Message",
            Content = "Test message sent to Discord!",
            Duration = 2
        })
    end
})

-- Settings Tab
local TreeStatus = Tabs.Settings:Paragraph({
    Title = "Tree Status",
    Desc = "Ready"
})

local FuelStatus = Tabs.Settings:Paragraph({
    Title = "Fuel Status", 
    Desc = "Ready"
})

local CombatStatus = Tabs.Settings:Paragraph({
    Title = "Combat Status",
    Desc = "Ready"
})

local CookStatus = Tabs.Settings:Paragraph({
    Title = "Cook Status",
    Desc = "Ready"
})

local FeedStatus = Tabs.Settings:Paragraph({
    Title = "Feed Status",
    Desc = "Ready"
})

local PlantStatus = Tabs.Settings:Paragraph({
    Title = "Plant Status",
    Desc = "Ready"
})

local DiscordStatus = Tabs.Settings:Paragraph({
    Title = "Discord Status",
    Desc = "Ready"
})

local SystemStatus = Tabs.Settings:Paragraph({
    Title = "System Overview",
    Desc = "All systems offline"
})

local lastUIUpdate = 0
local UIUpdateInterval = 0.5

RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    
    if currentTime - lastUIUpdate < UIUpdateInterval then
        return
    end
    lastUIUpdate = currentTime
    
    local treeStatusText, treeCount, closestDistance = TreeChopper.getStatus()
    -- Assuming SetDesc works or direct property assignment. 
    -- If SetDesc doesn't exist, this might error, but it's the best guess based on patterns.
    if TreeStatus.SetDesc then TreeStatus:SetDesc(treeStatusText) end
    
    local fuelStatusText, distance = AutoFuel.getStatus()
    if FuelStatus.SetDesc then FuelStatus:SetDesc(fuelStatusText) end
    
    local killStatusText, targetCount, closestTargetDistance = AutoKill.getStatus()
    if CombatStatus.SetDesc then CombatStatus:SetDesc("Targets: " .. killStatusText) end
    
    local cookStatusText, meatCount = AutoCook.getStatus()
    if CookStatus.SetDesc then CookStatus:SetDesc(cookStatusText) end
    
    local feedStatusText, hungerPercent = AutoFeed.getStatus()
    if FeedStatus.SetDesc then FeedStatus:SetDesc(feedStatusText) end
    
    local plantStatusText, saplingCount = AutoPlant.getStatus()
    if PlantStatus.SetDesc then PlantStatus:SetDesc(plantStatusText) end
    
    local discordStatusText = Webhook.getStatus()
    if DiscordStatus.SetDesc then DiscordStatus:SetDesc(discordStatusText) end
    
    local chopEnabled = TreeChopper.autoChopEnabled
    local fuelEnabled = AutoFuel.autoFuelEnabled
    local killEnabled = AutoKill.autoKillEnabled
    local cookEnabled = AutoCook.autoCookEnabled
    local feedEnabled = AutoFeed.autoFeedEnabled
    local plantEnabled = AutoPlant.autoPlantEnabled
    
    local activeCount = 0
    local activeSystems = {}
    
    if chopEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Tree")
    end
    if fuelEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Fuel")
    end
    if killEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Combat")
    end
    if cookEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Cook")
    end
    if feedEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Feed")
    end
    if plantEnabled then 
        activeCount = activeCount + 1 
        table.insert(activeSystems, "Plant")
    end
    
    local statusText = ""
    if activeCount == 6 then
        statusText = "🚀 All 6 systems running perfectly!"
    elseif activeCount >= 4 then
        statusText = "🔥 Multi-System Active: " .. activeCount .. "/6 systems (" .. table.concat(activeSystems, ", ") .. ")"
    elseif activeCount >= 2 then
        statusText = "⚡ Multi-Mode: " .. table.concat(activeSystems, " + ") .. " active"
    elseif activeCount == 1 then
        statusText = "📍 Single System: " .. activeSystems[1] .. " running"
    else
        statusText = "💤 All automation systems offline - Ready to start!"
    end
    
    if SystemStatus.SetDesc then SystemStatus:SetDesc(statusText) end
end)

WindUI:Notify({
    Title = "Forest Automation Suite v2.2",
    Content = "Ultimate forest management system loaded! WindUI Edition.",
    Duration = 6
})
