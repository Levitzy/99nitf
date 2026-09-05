--[[
    Karinderya by Kiri
    Ultra-Smooth Automation Suite & Premium Custom GUI for [🔥] Karinderya!
    
    Features:
      - Main Tab:
          [Karinderya Card]
          * Auto Assign
          * Table Actions (Serve Food & Clear Dirty Dishes)
          * Auto Wash (Native Hold Simulation < 3s)
          * Auto Give Softdrinks
          [Extra Card]
          * Auto Chase Thieves (+ Pan)
          * Auto Wake Worker (+ Pan)
          * Auto Clean Trash
      - Shop Tab (Matched to Design):
          * GROCERY Header with Category Filter Dropdown, Select All, and Auto Buy Toggle
          * Real-time 2-Column Grocery Stock Grid with color-coded percentages:
            - Blue/Cyan (>= 75%)
            - Orange/Amber (20% - 74%)
            - Red (< 20%)
          * Click-to-Buy any grocery item directly from the list
          * SHOP Bottom Bar with Item Category Dropdown, Refresh button, and Auto Buy Toggle
      - Webhook Tab:
          * Discord Webhook Integration with auto-save persistence (karinderya_webhook.json)
          * Auto Send Status Updates every 1 min, 5 min, 10 min, 15 min, or 30 min
          * Rich Discord Embed with Player info, Current Balance, Session Profit, Uptime, Hired Staff, and Counters
          * Instant "Send Test Webhook" connection verification button
          * Real-time AFK Telemetry Monitor with live countdown timer
          * Real-time Alerts on Runaway Thief smacked and Rare Worker candidate appeared
      - Config Tab:
          * Movement Mode: Toggle between Smooth Glide and Instant Teleport
          * Interactive Glide Speed Slider (30 to 250 studs/s) with real-time value display
          * Return to Plot after actions
          * Speed Booster (24 spd) & Anti-AFK Protection
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Clean up any prior running instances
local G = getgenv and getgenv() or _G
if G.KarinderyaHub and type(G.KarinderyaHub.Unload) == "function" then
    pcall(G.KarinderyaHub.Unload)
end

local Hub = {
    Running = true,
    Connections = {},
    Tasks = {},
    UI = nil,
    CurrentActivity = "Idle",
    SessionStartTime = os.clock(),
    SessionStartCash = 0,
    LastWebhookSent = 0,
    ThievesChasedCount = 0,
    WorkersWokenCount = 0,
    TrashCleanedCount = 0,
}
G.KarinderyaHub = Hub

local function trackConn(c)
    table.insert(Hub.Connections, c)
    return c
end

local function spawnLoop(delaySec, fn)
    local thread = task.spawn(function()
        while Hub.Running do
            pcall(fn)
            task.wait(delaySec)
        end
    end)
    table.insert(Hub.Tasks, thread)
    return thread
end

--------------------------------------------------------------------------------
-- CONFIGURATION STATE
--------------------------------------------------------------------------------
local Config = {
    -- Karinderya Automations
    AutoAssign = true,
    TableActions = true,
    AutoWash = true,
    AutoGiveSoftdrinks = true,

    -- Extra Automations
    AutoChaseThieves = false,
    AutoWakeWorker = false,
    AutoCleanTrash = false,

    -- Shop Automations
    GroceryAutoBuy = false,
    GroceryThreshold = 25, -- 10, 25, 50, 75 (%)
    GroceryFilter = "All",
    ShopAutoBuy = false,
    ShopFilter = "All",

    -- Worker Gacha Automations
    WorkerAutoRoll = false,
    WorkerMinRarity = "Legendary", -- "Rare", "Epic", "Legendary", "Mythical", "Secret"
    WorkerTargetRole = "Manual Pick", -- "Manual Pick", "Any", "Assigner", "Dishwasher"

    -- Merchant Automations
    MerchantAutoBuyWeapons = false,
    MerchantAutoBuyFurniture = false,

    -- Gift Automations
    AutoClaimGiftsOnStart = true,

    -- Smooth Movement & Mechanics
    UseGlide = true,      -- true = Smooth Glide, false = Instant Teleport
    GlideSpeed = 80,      -- Studs per second (controlled by slider)
    ReturnToHome = true,
    EquipPan = true,
    SpeedBoost = false,
    BoostSpeed = 24,
    AntiAFK = true,

    -- Discord Webhook AFK Tracker
    WebhookEnabled = false,
    WebhookURL = "",
    WebhookInterval = "5 min", -- "1 min", "5 min", "10 min", "15 min", "30 min"
    WebhookAlertThief = true,
    WebhookAlertWorker = true,
}

--------------------------------------------------------------------------------
-- SAFE REMOTES & MODULES
--------------------------------------------------------------------------------
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local CounterRemotes = Remotes and Remotes:FindFirstChild("CounterRemotes")
local ShopRemotes = Remotes and Remotes:FindFirstChild("ShopRemotes")
local NPCRemotes = Remotes and Remotes:FindFirstChild("NPCRemotes")
local KitchenRemotes = Remotes and Remotes:FindFirstChild("KitchenRemotes")
local WorkerRemotes = Remotes and Remotes:FindFirstChild("WorkerRemotes")
local BussingRemotes = Remotes and Remotes:FindFirstChild("BussingRemotes")
local MerchantRemotes = Remotes and Remotes:FindFirstChild("MerchantRemotes")
local Merchant2Remotes = Remotes and Remotes:FindFirstChild("Merchant2Remotes")
local RedeemCodeFolder = Remotes and Remotes:FindFirstChild("RedeemCode")
local GroupRewardFolder = Remotes and Remotes:FindFirstChild("GroupReward")

local GetCounterInfo = CounterRemotes and CounterRemotes:FindFirstChild("GetCounterInfo")
local AssignNPC = CounterRemotes and CounterRemotes:FindFirstChild("AssignNPC")
local HitRunawayEvent = Remotes and Remotes:FindFirstChild("HitRunawayEvent")
local CustomerRanAwayEvent = Remotes and Remotes:FindFirstChild("CustomerRanAwayEvent")
local WakeWorkerEvent = WorkerRemotes and WorkerRemotes:FindFirstChild("WakeWorkerEvent")
local RollWorkerRemote = WorkerRemotes and WorkerRemotes:FindFirstChild("RollWorker")
local HireWorkerRemote = WorkerRemotes and WorkerRemotes:FindFirstChild("HireWorker")
local GetWaitingWorkersRemote = WorkerRemotes and WorkerRemotes:FindFirstChild("GetWaitingWorkers")

local GetMerchantStock = MerchantRemotes and MerchantRemotes:FindFirstChild("GetMerchantStock")
local BuyMerchantItem = MerchantRemotes and MerchantRemotes:FindFirstChild("BuyMerchantItem")
local GetMerchant2Stock = Merchant2Remotes and Merchant2Remotes:FindFirstChild("GetMerchant2Stock")
local BuyMerchant2Item = Merchant2Remotes and Merchant2Remotes:FindFirstChild("BuyMerchant2Item")

local RedeemCodeRemote = RedeemCodeFolder and RedeemCodeFolder:FindFirstChild("RedeemCode")
local ClaimGroupRewardRemote = GroupRewardFolder and GroupRewardFolder:FindFirstChild("ClaimGroupReward")
local IsGroupClaimedRemote = GroupRewardFolder and GroupRewardFolder:FindFirstChild("IsClaimed")

local GiveSoftdrink = ShopRemotes and ShopRemotes:FindFirstChild("GiveSoftdrink")
local BuyIngredient = ShopRemotes and ShopRemotes:FindFirstChild("BuyIngredient")
local BuyFurniture = ShopRemotes and ShopRemotes:FindFirstChild("BuyFurniture")
local ShopRestocked = ShopRemotes and ShopRemotes:FindFirstChild("ShopRestocked")
local GetShopInfo = ShopRemotes and ShopRemotes:FindFirstChild("GetShopInfo")
local PropEquipEvent = Remotes and Remotes:FindFirstChild("PropEquipEvent")
local TeleportHomeEvent = Remotes and Remotes:FindFirstChild("TeleportHomeEvent")

local Modules = ReplicatedStorage:FindFirstChild("Modules")
local FoodConfig = Modules and Modules:FindFirstChild("FoodConfig") and require(Modules.FoodConfig) or {}
local IngredientsConfig = Modules and Modules:FindFirstChild("IngredientsConfig") and require(Modules.IngredientsConfig) or {}
local HandState = Modules and Modules:FindFirstChild("HandState") and require(Modules.HandState) or nil
local FurnitureConfig = Modules and Modules:FindFirstChild("FurnitureConfig") and require(Modules.FurnitureConfig) or nil
local PaintConfig = Modules and Modules:FindFirstChild("PaintConfig") and require(Modules.PaintConfig) or nil
local MaterialConfig = Modules and Modules:FindFirstChild("MaterialConfig") and require(Modules.MaterialConfig) or nil
local TileConfig = Modules and Modules:FindFirstChild("TileConfig") and require(Modules.TileConfig) or nil
local WorkerConfig = Modules and Modules:FindFirstChild("WorkerConfig") and require(Modules.WorkerConfig) or {}
local MerchantConfig = Modules and Modules:FindFirstChild("MerchantConfig") and require(Modules.MerchantConfig) or {}
local CodeConfig = Modules and Modules:FindFirstChild("CodeConfig") and require(Modules.CodeConfig) or {}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------
local function formatNumber(n)
    local str = tostring(math.floor(tonumber(n) or 0))
    local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if formatted:sub(1, 1) == "," then
        formatted = formatted:sub(2)
    end
    return formatted
end

local function getItemPriceAndName(systemType, category, key)
    if category == "Paints" and PaintConfig and PaintConfig[key] then
        local cfg = PaintConfig[key]
        local name = cfg.Name or key
        name = name:gsub("%s*Paint$", "")
        return cfg.Cost or 0, name
    elseif category == "Tiles" and TileConfig and TileConfig[key] then
        local cfg = TileConfig[key]
        return cfg.Cost or 0, cfg.Name or key
    elseif category == "Materials" and MaterialConfig and MaterialConfig[key] then
        local cfg = MaterialConfig[key]
        return cfg.Cost or 0, cfg.Name or key
    elseif FurnitureConfig and type(FurnitureConfig.GetItemConfig) == "function" then
        local ok, cfg = pcall(function() return FurnitureConfig.GetItemConfig(systemType, category, key) end)
        if ok and cfg then
            return cfg.Price or cfg.Cost or 0, cfg.Name or key
        end
    end
    return 0, key
end
local function getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function getPlayerPlot()
    for _, child in ipairs(Workspace:GetChildren()) do
        if string.find(child.Name, "^Karenderya") and child:GetAttribute("Owner") == LocalPlayer.UserId then
            return child
        end
    end
    return Workspace:FindFirstChild("Karenderya")
end

local function equipPanTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    local currentTool = char:FindFirstChildWhichIsA("Tool")
    if currentTool and string.find(string.lower(currentTool.Name), "pan") then
        return currentTool
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, t in ipairs(backpack:GetChildren()) do
            if t:IsA("Tool") and string.find(string.lower(t.Name), "pan") then
                local hum = getHumanoid()
                if hum then
                    hum:EquipTool(t)
                    task.wait(0.08)
                    return t
                end
            end
        end
    end
    return nil
end

local function isHoldingFood()
    if HandState and type(HandState.IsHoldingFood) == "function" then
        return HandState.IsHoldingFood()
    end
    local char = LocalPlayer.Character
    if not char then return false end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") and child:GetAttribute("IsFood") then
            return true
        end
    end
    return false
end

local function isHoldingDirty()
    if HandState and type(HandState.IsHoldingDirty) == "function" then
        return HandState.IsHoldingDirty()
    end
    local char = LocalPlayer.Character
    if not char then return false end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") and child:GetAttribute("IsDirty") then
            return true
        end
    end
    return false
end

local function isHoldingSoftdrink()
    if HandState and type(HandState.IsHoldingSoftdrink) == "function" then
        return HandState.IsHoldingSoftdrink()
    end
    local char = LocalPlayer.Character
    if not char then return false end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") and child:GetAttribute("IsSoftdrink") then
            return true
        end
    end
    return false
end

local function firePrompt(prompt, duration)
    if not prompt or not prompt.Parent then return end
    if fireproximityprompt then
        fireproximityprompt(prompt, duration or 0)
    end
end

local function setActivity(text, color)
    Hub.CurrentActivity = text
    if Hub.StatusLabel then
        Hub.StatusLabel.Text = "Status: " .. text
        if color and Hub.StatusDot then
            Hub.StatusDot.TextColor3 = color
        end
    end
end

--------------------------------------------------------------------------------
-- RUNAWAY THIEF TRACKING (MY KARINDERYA ONLY)
--------------------------------------------------------------------------------
local myRunawayThieves = {}  -- [npcName] = expireTime (from CustomerRanAwayEvent)
local myCustomerNpcIds = {}  -- [npcName] = expireTime (customers belonging to my plot)

if CustomerRanAwayEvent then
    trackConn(CustomerRanAwayEvent.OnClientEvent:Connect(function(arg1, arg2)
        local id2 = arg2 and tostring(arg2)
        local id1 = arg1 and tostring(arg1)
        if id2 and id2 ~= "" and id2 ~= "nil" then
            myRunawayThieves[id2] = os.clock() + 60
            myCustomerNpcIds[id2] = os.clock() + 180
        end
        if id1 and id1 ~= "" and id1 ~= "nil" and not tonumber(id1) then
            myRunawayThieves[id1] = os.clock() + 60
            myCustomerNpcIds[id1] = os.clock() + 180
        end
    end))
end

-- Grocery Stock Calculation
local function getStockInfo(ingKey, ingData)
    local current = 0
    local ingFolder = LocalPlayer:FindFirstChild("Ingredients")
    if ingFolder then
        local item = ingFolder:FindFirstChild(ingKey)
        if item then current = item.Value end
    end
    local char = LocalPlayer.Character
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Accessory") and child:GetAttribute("IsSoftdrink") and (child:GetAttribute("Flavor") or child.Name) == ingKey then
                current = current + 1
            end
        end
    end
    local maxStock = ingData.MaxStock or 100
    local pct = math.clamp(math.floor((current / maxStock) * 100), 0, 100)
    return current, maxStock, pct
end

local function getPctColor(pct)
    if pct >= 75 then
        return Color3.fromRGB(56, 189, 248) -- Light blue / cyan
    elseif pct >= 20 then
        return Color3.fromRGB(251, 146, 60) -- Amber / orange
    else
        return Color3.fromRGB(239, 68, 68) -- Red
    end
end

local updateWorkersUI = nil
local updateMerchantUI = nil

--------------------------------------------------------------------------------
-- GIFTS, CODES & GROUP REWARD
--------------------------------------------------------------------------------
local function redeemAllCodes()
    if not RedeemCodeRemote then
        setActivity("RedeemCode remote not found", Color3.fromRGB(239, 68, 68))
        return
    end
    setActivity("Redeeming Gift Codes...", Color3.fromRGB(245, 158, 11))
    local codes = {
        "50KCCU",
        "DECOPART1",
        "BAKARENEPAIRYAN",
        "BAKARAINYDAYYAN",
        "BATINATAYOHA",
        "MATERIALSDAW",
        "FISHONTOOO",
        "BALDOG",
        "LERISNATO",
        "3MVISITS",
        "2MVISITS",
        "1MVISITS",
        "BRICKS",
        "RELEASE",
        "OLDCODE",
    }
    task.spawn(function()
        for _, code in ipairs(codes) do
            pcall(function() RedeemCodeRemote:FireServer(code) end)
            task.wait(0.12)
        end
        setActivity("Gift Codes Processed!", Color3.fromRGB(52, 199, 89))
    end)
end

local function claimGroupReward()
    if not ClaimGroupRewardRemote then
        setActivity("GroupReward remote not found", Color3.fromRGB(239, 68, 68))
        return
    end
    task.spawn(function()
        if IsGroupClaimedRemote then
            local ok, claimed = pcall(function() return IsGroupClaimedRemote:InvokeServer() end)
            if ok and claimed == true then
                setActivity("Group Reward already claimed!", Color3.fromRGB(245, 158, 11))
                return
            end
        end
        pcall(function() ClaimGroupRewardRemote:FireServer() end)
        setActivity("Group Reward Claimed!", Color3.fromRGB(52, 199, 89))
    end)
end

--------------------------------------------------------------------------------
-- TRAVELLING MERCHANT AUTOMATION
--------------------------------------------------------------------------------
local lastMerchantCheck = 0
local function doMerchantAutoBuy()
    local now = os.clock()
    if now - lastMerchantCheck < 10 then return end
    lastMerchantCheck = now

    if not GetMerchantStock or not BuyMerchantItem then return end
    task.spawn(function()
        local ok, stock = pcall(function() return GetMerchantStock:InvokeServer() end)
        if not ok or type(stock) ~= "table" then return end

        for _, item in ipairs(stock) do
            if item.Stock and item.Stock > 0 and not item.Owned then
                local isWeapon = (item.Category == "Weapons")
                local isFurniture = (item.Category == "Tables" or item.Category == "Chairs")
                if (isWeapon and Config.MerchantAutoBuyWeapons) or (isFurniture and Config.MerchantAutoBuyFurniture) then
                    local bOk, bRes = pcall(function() return BuyMerchantItem:InvokeServer(item.Key) end)
                    if bOk then
                        setActivity("Bought " .. (item.Name or item.Key) .. " from Merchant!", Color3.fromRGB(52, 199, 89))
                        if updateMerchantUI then updateMerchantUI() end
                    end
                    task.wait(0.15)
                end
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- GACHA WORKER ROLLER & HIRER
--------------------------------------------------------------------------------
local RARITY_RANKS = {
    Common = 1,
    Rare = 2,
    Steamer = 3,
    Epic = 4,
    Legendary = 5,
    Mythical = 6,
    Secret = 7,
    Limited = 8,
}

local RARITY_COLORS = {
    Common = Color3.fromRGB(160, 175, 200),
    Rare = Color3.fromRGB(56, 189, 248),
    Steamer = Color3.fromRGB(96, 165, 250),
    Epic = Color3.fromRGB(168, 85, 247),
    Legendary = Color3.fromRGB(250, 204, 21),
    Mythical = Color3.fromRGB(244, 114, 182),
    Secret = Color3.fromRGB(239, 68, 68),
    Limited = Color3.fromRGB(52, 211, 153),
}

local function getHiredRoles()
    local plot = getPlayerPlot()
    local hired = {}
    if plot then
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("Model") and d:GetAttribute("IsWorker") == true and d:GetAttribute("Hired") == true then
                local wp = d:GetAttribute("WorkerPlot")
                if wp == plot.Name or d:IsDescendantOf(plot) then
                    local role = d:GetAttribute("Role")
                    if role then
                        hired[role] = {
                            Model = d,
                            Name = d:GetAttribute("WorkerName") or d.Name,
                            Wage = d:GetAttribute("Wage") or 100,
                            Rarity = d:GetAttribute("Rarity") or "Common",
                            Speed = d:GetAttribute("Speed") or 40,
                            DaysLeft = d:GetAttribute("DaysLeft") or 1,
                        }
                    end
                end
            end
        end
    end
    return hired
end

--------------------------------------------------------------------------------
-- MOVEMENT CONTROLLER (Smooth Glide vs Instant Teleport)
--------------------------------------------------------------------------------
local isGliding = false
local function moveTo(targetCFrame, speedOverride)
    local hrp = getHRP()
    local char = LocalPlayer.Character
    if not hrp or not char then return end

    local startCF = hrp.CFrame
    local distance = (targetCFrame.Position - startCF.Position).Magnitude

    if distance < 1.2 then
        hrp.CFrame = targetCFrame
        return
    end

    -- Instant Teleport Mode
    if not Config.UseGlide then
        hrp.CFrame = targetCFrame
        return
    end

    -- Smooth Glide Mode
    isGliding = true
    local speed = speedOverride or Config.GlideSpeed or 80
    local duration = math.clamp(distance / speed, 0.12, 1.2)

    local partsToRestore = {}
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then
            p.CanCollide = false
            table.insert(partsToRestore, p)
        end
    end

    local startTime = os.clock()
    while Hub.Running do
        local elapsed = os.clock() - startTime
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local smoothAlpha = alpha * alpha * (3 - 2 * alpha)

        hrp.CFrame = startCF:Lerp(targetCFrame, smoothAlpha)
        if alpha >= 1 then break end
        RunService.Heartbeat:Wait()
    end

    hrp.CFrame = targetCFrame
    for _, p in ipairs(partsToRestore) do
        if p.Parent then
            p.CanCollide = true
        end
    end
    isGliding = false
end

--------------------------------------------------------------------------------
-- DISCORD WEBHOOK & AFK TELEMETRY ENGINE
--------------------------------------------------------------------------------
local INTERVAL_MAP = {
    ["1 min"] = 60,
    ["5 min"] = 300,
    ["10 min"] = 600,
    ["15 min"] = 900,
    ["30 min"] = 1800,
}

local function getHttpRequest()
    return (syn and syn.request) or (http and http.request) or http_request or request
end

local WEBHOOK_SAVE_FILE = "karinderya_webhook.json"

local function loadWebhookConfig()
    if readfile and isfile and isfile(WEBHOOK_SAVE_FILE) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(WEBHOOK_SAVE_FILE))
        end)
        if ok and type(data) == "table" then
            if data.WebhookURL then Config.WebhookURL = data.WebhookURL end
            if data.WebhookEnabled ~= nil then Config.WebhookEnabled = data.WebhookEnabled end
            if data.WebhookInterval then Config.WebhookInterval = data.WebhookInterval end
            if data.WebhookAlertThief ~= nil then Config.WebhookAlertThief = data.WebhookAlertThief end
            if data.WebhookAlertWorker ~= nil then Config.WebhookAlertWorker = data.WebhookAlertWorker end
            if data.GroceryAutoBuy ~= nil then Config.GroceryAutoBuy = data.GroceryAutoBuy end
            if data.GroceryThreshold ~= nil then Config.GroceryThreshold = tonumber(data.GroceryThreshold) or 25 end
        end
    end
end

local function saveWebhookConfig()
    if writefile then
        pcall(function()
            local payload = {
                WebhookURL = Config.WebhookURL or "",
                WebhookEnabled = Config.WebhookEnabled == true,
                WebhookInterval = Config.WebhookInterval or "5 min",
                WebhookAlertThief = Config.WebhookAlertThief ~= false,
                WebhookAlertWorker = Config.WebhookAlertWorker ~= false,
                GroceryAutoBuy = Config.GroceryAutoBuy == true,
                GroceryThreshold = Config.GroceryThreshold or 25,
            }
            writefile(WEBHOOK_SAVE_FILE, HttpService:JSONEncode(payload))
        end)
    end
end
pcall(loadWebhookConfig)

local function sendDiscordWebhookAlert(title, desc, colorHex)
    if not Config.WebhookEnabled or not Config.WebhookURL or Config.WebhookURL == "" then return end
    local reqFn = getHttpRequest()
    if not reqFn then return end

    pcall(function()
        local payload = {
            username = "Karinderya Alerts",
            avatar_url = "https://cdn-icons-png.flaticon.com/512/3081/3081986.png",
            embeds = {
                {
                    title = title,
                    description = desc,
                    color = colorHex or 0xE11D48,
                    footer = { text = "Karinderya by Kiri • AFK Alerts" },
                    timestamp = DateTime.now():ToIsoDate()
                }
            }
        }
        reqFn({
            Url = Config.WebhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

local function sendDiscordWebhookReport(isTest)
    if not Config.WebhookURL or Config.WebhookURL == "" then
        return false, "No Webhook URL configured"
    end
    local reqFn = getHttpRequest()
    if not reqFn then
        return false, "No HTTP request function found (executor unsupported)"
    end

    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local curCash = (leaderstats and leaderstats:FindFirstChild("Cash") and leaderstats.Cash.Value) or 0
    if Hub.SessionStartCash == 0 and curCash > 0 then
        Hub.SessionStartCash = curCash
    end

    local earned = curCash - (Hub.SessionStartCash or curCash)
    local elapsed = math.max(1, math.floor(os.clock() - (Hub.SessionStartTime or os.clock())))
    local elapsedHours = elapsed / 3600
    local ratePerHour = math.floor(math.max(0, earned) / elapsedHours)

    local uptimeStr = string.format("%02dh %02dm %02ds", math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), elapsed % 60)

    local hired = getHiredRoles and getHiredRoles() or { Assigner = false, Dishwasher = false, WorkerCount = 0 }
    local staffStr = string.format("Assigner: %s | Dishwasher: %s",
        hired.Assigner and "✅ Hired" or "❌ None",
        hired.Dishwasher and "✅ Hired" or "❌ None"
    )

    local embedTitle = isTest and "🔔 Karinderya by Kiri — Webhook Test Connection" or "🍜 Karinderya by Kiri — Live AFK Report"
    local embedColor = isTest and 0x0A84FF or (earned >= 0 and 0x34C759 or 0xFF9F0A)

    local payload = {
        username = "Karinderya Tracker",
        avatar_url = "https://cdn-icons-png.flaticon.com/512/3081/3081986.png",
        embeds = {
            {
                title = embedTitle,
                description = isTest and "✅ **Discord Webhook Connected Successfully!**\nAuto-updates will be sent according to your selected interval." or "⚡ **Live AFK Farm Statistics & Status Update**",
                color = embedColor,
                fields = {
                    {
                        name = "👤 Player",
                        value = string.format("%s (`@%s`)", LocalPlayer.DisplayName, LocalPlayer.Name),
                        inline = true
                    },
                    {
                        name = "💰 Current Balance",
                        value = string.format("₱%s", formatNumber(curCash)),
                        inline = true
                    },
                    {
                        name = "📈 Session Profit",
                        value = string.format("%s₱%s (~₱%s/hr)", earned >= 0 and "+" or "", formatNumber(earned), formatNumber(ratePerHour)),
                        inline = true
                    },
                    {
                        name = "⏱️ AFK Session Time",
                        value = uptimeStr,
                        inline = true
                    },
                    {
                        name = "👥 Hired Staff",
                        value = staffStr,
                        inline = true
                    },
                    {
                        name = "⚙️ Hub Activity",
                        value = tostring(Hub.CurrentActivity or "Idle"),
                        inline = true
                    },
                    {
                        name = "🛡️ AFK Action Counter",
                        value = string.format("🥷 Thieves Smacked: **%d** | 💤 Workers Woken: **%d** | 🧹 Trash Cleaned: **%d**",
                            Hub.ThievesChasedCount or 0,
                            Hub.WorkersWokenCount or 0,
                            Hub.TrashCleanedCount or 0
                        ),
                        inline = false
                    }
                },
                footer = {
                    text = "Karinderya by Kiri • Ultra-Smooth Automation Suite"
                },
                timestamp = DateTime.now():ToIsoDate()
            }
        }
    }

    local ok, res = pcall(function()
        return reqFn({
            Url = Config.WebhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if ok then
        Hub.LastWebhookSent = os.clock()
        return true, "Webhook dispatched successfully"
    else
        return false, tostring(res)
    end
end

--------------------------------------------------------------------------------
-- AUTOMATION ENGINES
--------------------------------------------------------------------------------

-- 1. Auto Assign (Silent Background Remote)
local isAssigning = false
local function doAutoAssign()
    if not Config.AutoAssign or isAssigning or not GetCounterInfo or not AssignNPC then return end
    isAssigning = true

    local ok, customer, tables = pcall(function()
        return GetCounterInfo:InvokeServer()
    end)

    if ok and customer and tables and #tables > 0 then
        local order = customer.Order
        local hasIngredients = true

        if order and FoodConfig[order] then
            local req = FoodConfig[order].RequiredIngredients or {}
            local ingFolder = LocalPlayer:FindFirstChild("Ingredients")
            if ingFolder then
                for _, ingName in ipairs(req) do
                    local item = ingFolder:FindFirstChild(ingName)
                    if not item or item.Value <= 0 then
                        hasIngredients = false
                        break
                    end
                end
            end
        end

        if hasIngredients then
            local targetTable = tables[1]
            local npcId = customer.NpcId or customer.TemplateName or ""
            if customer.NpcId then
                myCustomerNpcIds[tostring(customer.NpcId)] = os.clock() + 300
            end
            AssignNPC:FireServer({
                Slot = targetTable.Slot,
                Seat = targetTable.Seat,
                NPCName = npcId,
                NpcId = npcId
            })
            task.wait(0.15)
        end
    end

    isAssigning = false
end

-- 2. Auto Wash (Supercharged Native Hold Simulation)
local isWashing = false
local function doAutoWash()
    if not Config.AutoWash or isWashing then return end
    local plot = getPlayerPlot()
    local hrp = getHRP()
    if not plot or not hrp then return end

    local sink = plot:FindFirstChild("Sink", true)
    local promptPart = sink and sink:FindFirstChild("PromptPart", true)
    local washPrompt = promptPart and promptPart:FindFirstChild("Wash")

    if not washPrompt or not promptPart then return end
    if washPrompt:GetAttribute("HasDishes") ~= true and not washPrompt.Enabled then return end

    isWashing = true
    local origCF = hrp.CFrame
    setActivity("Washing Dishes...", Color3.fromRGB(59, 130, 246))

    local standCF = promptPart.CFrame * CFrame.new(0, 0, 2.5) * CFrame.Angles(0, math.pi, 0)
    moveTo(standCF)
    task.wait(0.1)

    if washPrompt.InputHoldBegin then
        washPrompt:InputHoldBegin()
    else
        firePrompt(washPrompt, 0)
    end

    local startTime = os.clock()
    while Hub.Running and (os.clock() - startTime < 4.0) do
        if washPrompt:GetAttribute("HasDishes") == false then
            break
        end
        task.wait(0.08)
    end

    if washPrompt.InputHoldEnd then
        washPrompt:InputHoldEnd()
    end

    setActivity("Dishes Cleaned!", Color3.fromRGB(38, 140, 78))
    task.wait(0.2)

    if Config.ReturnToHome and origCF then
        moveTo(origCF)
    end

    setActivity("Idle", Color3.fromRGB(160, 160, 160))
    isWashing = false
end

-- 3. Table Actions
local isDoingTableAction = false
local function doTableActions()
    if not Config.TableActions or isDoingTableAction or isWashing then return end
    local plot = getPlayerPlot()
    local hrp = getHRP()
    if not plot or not hrp then return end

    isDoingTableAction = true

    -- Pick up food
    if not isHoldingFood() and not isHoldingDirty() and not isHoldingSoftdrink() then
        local serveFolder = plot:FindFirstChild("Serve")
        if serveFolder then
            for _, slot in ipairs(serveFolder:GetChildren()) do
                for _, food in ipairs(slot:GetChildren()) do
                    if food:IsA("Model") then
                        local prompt = food:FindFirstChildWhichIsA("ProximityPrompt", true)
                        local plate = food:FindFirstChild("Plate") or food.PrimaryPart or food:FindFirstChildWhichIsA("BasePart")
                        if prompt and prompt.Enabled and plate then
                            setActivity("Picking up food...", Color3.fromRGB(245, 158, 11))
                            moveTo(plate.CFrame + Vector3.new(0, 1.5, 0))
                            task.wait(0.1)
                            firePrompt(prompt, 0)
                            task.wait(0.2)
                            break
                        end
                    end
                end
                if isHoldingFood() then break end
            end
        end
    end

    -- Deliver food to seated customer
    if isHoldingFood() then
        local servePrompt = nil
        for _, p in ipairs(plot:GetDescendants()) do
            if p:IsA("ProximityPrompt") and p:GetAttribute("TableAction") == "Serve" and p.Enabled then
                servePrompt = p
                break
            end
        end

        if servePrompt and servePrompt.Parent and servePrompt.Parent:IsA("BasePart") then
            setActivity("Serving Customer...", Color3.fromRGB(38, 140, 78))
            moveTo(servePrompt.Parent.CFrame + Vector3.new(0, 1.5, 0))
            task.wait(0.1)
            firePrompt(servePrompt, 0)
            task.wait(0.2)
        end
    end

    -- Clear dirty dishes
    if not isHoldingFood() and not isHoldingDirty() and not isHoldingSoftdrink() then
        local dirtyPrompt = nil
        for _, p in ipairs(plot:GetDescendants()) do
            if p:IsA("ProximityPrompt") and p:GetAttribute("TableAction") == "GetDirty" and p.Enabled then
                dirtyPrompt = p
                break
            end
        end

        if dirtyPrompt and dirtyPrompt.Parent and dirtyPrompt.Parent:IsA("BasePart") then
            setActivity("Clearing Table...", Color3.fromRGB(234, 179, 8))
            moveTo(dirtyPrompt.Parent.CFrame + Vector3.new(0, 1.5, 0))
            task.wait(0.1)
            firePrompt(dirtyPrompt, 0)
            task.wait(0.2)
        end
    end

    -- Drop dirty dishes to sink
    if isHoldingDirty() then
        local sink = plot:FindFirstChild("Sink", true)
        local promptPart = sink and sink:FindFirstChild("PromptPart", true)
        if promptPart then
            setActivity("Taking Dishes to Sink...", Color3.fromRGB(59, 130, 246))
            local standCF = promptPart.CFrame * CFrame.new(0, 0, 2.5) * CFrame.Angles(0, math.pi, 0)
            moveTo(standCF)
            task.wait(0.2)

            if Config.AutoWash then
                doAutoWash()
            end
        end
    end

    setActivity("Idle", Color3.fromRGB(160, 160, 160))
    isDoingTableAction = false
end

-- 4. Auto Give Softdrinks
local isGivingDrinks = false
local function doAutoGiveSoftdrinks()
    if not Config.AutoGiveSoftdrinks or isGivingDrinks or not GiveSoftdrink then return end
    isGivingDrinks = true

    for _, drink in ipairs({ "Kola", "Suprise", "Loyal" }) do
        pcall(function()
            GiveSoftdrink:InvokeServer(drink)
        end)
    end

    isGivingDrinks = false
end

-- Helper: Update Customer Registry from Restaurant & Controller Registry
local lastRegistryUpdate = 0
local function updateCustomerRegistry()
    local now = os.clock()
    if now - lastRegistryUpdate < 0.8 then return end
    lastRegistryUpdate = now

    local myPlot = getPlayerPlot()
    if not myPlot then return end

    -- 1. Scan NPCs located inside our restaurant (Line, DiningPlot1, NpcSpawn)
    local clientNPCs = Workspace:FindFirstChild("ClientNPCs")
    if clientNPCs then
        local checkFolders = {
            myPlot:FindFirstChild("DiningPlot1"),
            myPlot:FindFirstChild("Line"),
            myPlot:FindFirstChild("NpcSpawn")
        }
        local referenceParts = {}
        for _, f in ipairs(checkFolders) do
            if f then
                for _, p in ipairs(f:GetDescendants()) do
                    if p:IsA("BasePart") then
                        table.insert(referenceParts, p.Position)
                    end
                end
            end
        end

        for _, npc in ipairs(clientNPCs:GetChildren()) do
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
            if hrp then
                local pos = hrp.Position
                for _, refPos in ipairs(referenceParts) do
                    if (pos - refPos).Magnitude < 14 then
                        myCustomerNpcIds[npc.Name] = now + 180
                        break
                    end
                end
            end
        end
    end

    -- 2. Inspect NPCClientController internal spawn registry via getupvalues (if available)
    if getupvalues then
        pcall(function()
            local controller = LocalPlayer:FindFirstChild("PlayerScripts") 
                and LocalPlayer.PlayerScripts:FindFirstChild("Controllers") 
                and LocalPlayer.PlayerScripts.Controllers:FindFirstChild("NPCClientController")
            if not controller then return end
            local mod = require(controller)
            if not mod or not mod.Init then return end
            local uvs = getupvalues(mod.Init)
            local reg = uvs and uvs[5]
            if type(reg) ~= "table" then return end

            local spawnPart = myPlot:FindFirstChild("NpcSpawn") and myPlot.NpcSpawn:FindFirstChildWhichIsA("BasePart", true)
            local mySpawnPos = spawnPart and spawnPart.Position or Vector3.new(-215.1, 2.7, -84.2)

            for npcId, data in pairs(reg) do
                local sp = data and data.SpawnCFrame and data.SpawnCFrame.Position
                if sp then
                    local dist = (Vector3.new(sp.X, 0, sp.Z) - Vector3.new(mySpawnPos.X, 0, mySpawnPos.Z)).Magnitude
                    if dist < 15 then
                        myCustomerNpcIds[tostring(npcId)] = now + 180
                    end
                end
            end
        end)
    end

    -- Clean expired entries
    for k, expireTime in pairs(myRunawayThieves) do
        if expireTime < now then myRunawayThieves[k] = nil end
    end
    for k, expireTime in pairs(myCustomerNpcIds) do
        if expireTime < now then myCustomerNpcIds[k] = nil end
    end
end

-- Helper: Check if a runaway NPC belongs exclusively to OUR Karinderya
local function isMyKarinderyaThief(npc)
    if not npc or not npc.Parent then return false end
    if npc:GetAttribute("IsRunaway") ~= true then return false end

    local name = npc.Name
    local now = os.clock()

    -- 1. Direct confirmation from server CustomerRanAwayEvent (alert sent only to restaurant owner)
    if myRunawayThieves[name] and myRunawayThieves[name] > now then
        return true
    end

    -- 2. Known customer that spawned, was in line, or dined at our Karinderya
    if myCustomerNpcIds[name] and myCustomerNpcIds[name] > now then
        return true
    end

    -- 3. Spatial Verification & Strict Foreign Karinderya Exclusion
    local thiefPart = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
    if not thiefPart then return false end
    local thiefPos = thiefPart.Position

    local myPlot = getPlayerPlot()
    if not myPlot then return false end

    local myFloor = myPlot:FindFirstChild("Floor") or myPlot:FindFirstChild("DiningPlot1") or myPlot
    local myCenterPart = myFloor:FindFirstChildWhichIsA("BasePart", true)
    local myCenter = myCenterPart and myCenterPart.Position or Vector3.new(-191.7, 2.3, -128.0)
    local distToMyPlot = (Vector3.new(thiefPos.X, 0, thiefPos.Z) - Vector3.new(myCenter.X, 0, myCenter.Z)).Magnitude

    -- Check against all other Karinderya plots in Workspace
    for _, child in ipairs(Workspace:GetChildren()) do
        if string.find(child.Name, "^Karenderya") and child ~= myPlot then
            local otherFloor = child:FindFirstChild("Floor") or child:FindFirstChild("DiningPlot1") or child
            local otherPart = otherFloor:FindFirstChildWhichIsA("BasePart", true)
            if otherPart then
                local otherCenter = otherPart.Position
                local distToOther = (Vector3.new(thiefPos.X, 0, thiefPos.Z) - Vector3.new(otherCenter.X, 0, otherCenter.Z)).Magnitude
                -- If thief is closer to another player's restaurant, it belongs to them! Reject immediately.
                if distToOther <= distToMyPlot then
                    return false
                end
                -- If thief is within 85 studs of another restaurant's core building, reject immediately!
                if distToOther < 85 then
                    return false
                end
            end
        end
    end

    -- Must be within our restaurant area (90 studs) or near our plot's Steal waypoints
    if distToMyPlot <= 90 then
        return true
    end

    local stealFolder = myPlot:FindFirstChild("Steal")
    if stealFolder then
        for _, wp in ipairs(stealFolder:GetChildren()) do
            if wp:IsA("BasePart") and (Vector3.new(thiefPos.X, 0, thiefPos.Z) - Vector3.new(wp.Position.X, 0, wp.Position.Z)).Magnitude < 40 then
                return true
            end
        end
    end

    return false
end

-- 5. Auto Chase Thieves (+ Pan) [Restricted Exclusively to MY Karinderya]
local isChasingThieves = false
local function doAutoChaseThieves()
    if not Config.AutoChaseThieves or isChasingThieves or not HitRunawayEvent then return end
    local hrp = getHRP()
    if not hrp then return end

    local clientNPCs = Workspace:FindFirstChild("ClientNPCs")
    if not clientNPCs then return end

    updateCustomerRegistry()

    for _, npc in ipairs(clientNPCs:GetChildren()) do
        if isMyKarinderyaThief(npc) then
            isChasingThieves = true
            setActivity("Chasing Thief! (+Pan)", Color3.fromRGB(225, 29, 72))
            local panTool = Config.EquipPan and equipPanTool() or nil
            local thiefPart = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")

            if thiefPart then
                local origCF = hrp.CFrame
                moveTo(thiefPart.CFrame * CFrame.new(0, 0, 2), 95)
                task.wait(0.1)
                HitRunawayEvent:FireServer(npc.Name)
                Hub.ThievesChasedCount = (Hub.ThievesChasedCount or 0) + 1
                if Config.WebhookEnabled and Config.WebhookAlertThief then
                    task.spawn(function()
                        sendDiscordWebhookAlert("🚨 Runaway Thief Smacked!", "Chased and smacked runaway thief **" .. tostring(npc.Name) .. "** with a frying pan! 🍳", 0xE11D48)
                    end)
                end
                if panTool then
                    pcall(function() panTool:Activate() end)
                end
                task.wait(0.25)
                myRunawayThieves[npc.Name] = nil
                if Config.ReturnToHome and origCF then
                    moveTo(origCF)
                end
            else
                HitRunawayEvent:FireServer(npc.Name)
                Hub.ThievesChasedCount = (Hub.ThievesChasedCount or 0) + 1
                myRunawayThieves[npc.Name] = nil
            end
            setActivity("Idle", Color3.fromRGB(160, 160, 160))
            isChasingThieves = false
            break
        end
    end
end

-- 6. Auto Wake Worker (+ Pan) [Restricted Exclusively to MY Karinderya]
local isWakingWorker = false
local function doAutoWakeWorker()
    if not Config.AutoWakeWorker or isWakingWorker or not WakeWorkerEvent then return end
    local hrp = getHRP()
    local plot = getPlayerPlot()
    if not hrp or not plot then return end

    local sleepingWorker = nil
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") and d:GetAttribute("IsWorker") == true and d:GetAttribute("IsSleeping") == true then
            local workerPlot = d:GetAttribute("WorkerPlot")
            if (workerPlot and workerPlot == plot.Name) or d:IsDescendantOf(plot) then
                sleepingWorker = d
                break
            end
        end
    end

    if sleepingWorker then
        isWakingWorker = true
        setActivity("Waking Worker! (+Pan)", Color3.fromRGB(245, 158, 11))
        local panTool = Config.EquipPan and equipPanTool() or nil
        local workerPart = sleepingWorker:FindFirstChild("HumanoidRootPart") or sleepingWorker.PrimaryPart or sleepingWorker:FindFirstChildWhichIsA("BasePart")

        if workerPart then
            local origCF = hrp.CFrame
            moveTo(workerPart.CFrame * CFrame.new(0, 0, 2), 90)
            task.wait(0.1)
            WakeWorkerEvent:FireServer(sleepingWorker.Name)
            Hub.WorkersWokenCount = (Hub.WorkersWokenCount or 0) + 1
            if panTool then
                pcall(function() panTool:Activate() end)
            end
            task.wait(0.25)
            if Config.ReturnToHome and origCF then
                moveTo(origCF)
            end
        else
            WakeWorkerEvent:FireServer(sleepingWorker.Name)
            Hub.WorkersWokenCount = (Hub.WorkersWokenCount or 0) + 1
        end
        setActivity("Idle", Color3.fromRGB(160, 160, 160))
        isWakingWorker = false
    end
end

-- 7. Auto Clean Trash
local isCleaningTrash = false
local function doAutoCleanTrash()
    if not Config.AutoCleanTrash or isCleaningTrash or isWashing or isDoingTableAction then return end
    local hrp = getHRP()
    if not hrp then return end

    local trashPrompt = nil
    local plot = getPlayerPlot()

    if plot then
        for _, d in ipairs(plot:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d:GetAttribute("IsTrash") and d.Enabled and d.Parent and d.Parent:IsA("BasePart") then
                trashPrompt = d
                break
            end
        end
    end

    if not trashPrompt then
        local spawner = Workspace:FindFirstChild("GlobalTrashSpawner") or Workspace:FindFirstChild("TrashOutside")
        if spawner then
            for _, d in ipairs(spawner:GetDescendants()) do
                if d:IsA("ProximityPrompt") and d:GetAttribute("IsTrash") and d.Enabled and d.Parent and d.Parent:IsA("BasePart") then
                    trashPrompt = d
                    break
                end
            end
        end
    end

    if trashPrompt and trashPrompt.Parent and trashPrompt.Parent:IsA("BasePart") then
        isCleaningTrash = true
        setActivity("Sweeping Trash...", Color3.fromRGB(14, 165, 233))
        local origCF = hrp.CFrame
        moveTo(trashPrompt.Parent.CFrame + Vector3.new(0, 2, 0))
        task.wait(0.12)
        firePrompt(trashPrompt, 0)
        Hub.TrashCleanedCount = (Hub.TrashCleanedCount or 0) + 1
        task.wait(0.25)
        if Config.ReturnToHome and origCF then
            moveTo(origCF)
        end
        setActivity("Idle", Color3.fromRGB(160, 160, 160))
        isCleaningTrash = false
    end
end

-- 8. Grocery Auto Buy (Threshold: 10%, 25%, 50%, 75%)
local isBuyingGrocery = false
local function doGroceryAutoBuy()
    if not Config.GroceryAutoBuy or isBuyingGrocery or not BuyIngredient then return end
    isBuyingGrocery = true

    local ingFolder = LocalPlayer:FindFirstChild("Ingredients")
    if ingFolder then
        local threshold = tonumber(Config.GroceryThreshold) or 25
        for ingKey, info in pairs(IngredientsConfig) do
            local current, maxStock, pct = getStockInfo(ingKey, info)
            if pct <= threshold or current < threshold then
                local needed = maxStock - current
                if needed > 0 then
                    pcall(function()
                        BuyIngredient:InvokeServer(ingKey, math.min(needed, info.YieldAmount or 12), "Cash")
                    end)
                    task.wait(0.08)
                end
            end
        end
    end

    isBuyingGrocery = false
end

-- 9. Shop Auto Buy (Buys Restocked Furniture / Appliances)
local isBuyingShop = false
local function doShopAutoBuy()
    if not Config.ShopAutoBuy or isBuyingShop or not BuyFurniture or not GetShopInfo then return end
    isBuyingShop = true

    local ok, res = pcall(function() return GetShopInfo:InvokeServer() end)
    if ok and type(res) == "table" then
        for catName, items in pairs(res) do
            if Config.ShopFilter == "All" or catName == Config.ShopFilter then
                if type(items) == "table" then
                    for _, itm in ipairs(items) do
                        if itm.Stock and itm.Stock > 0 and itm.Key and itm.Category and itm.SystemType then
                            pcall(function()
                                BuyFurniture:InvokeServer(itm.SystemType, itm.Category, itm.Key)
                            end)
                            task.wait(0.08)
                        end
                    end
                end
            end
        end
    end

    isBuyingShop = false
end

--------------------------------------------------------------------------------
-- WORKER & REWARD CONSTANTS & HELPERS
--------------------------------------------------------------------------------
local RARITY_RANKS = {
    Common = 1,
    Rare = 2,
    Steamer = 3,
    Epic = 4,
    Legendary = 5,
    Mythical = 6,
    Secret = 7,
    Limited = 8,
}

local RARITY_COLORS = {
    Common = Color3.fromRGB(160, 160, 160),
    Rare = Color3.fromRGB(59, 130, 246),
    Steamer = Color3.fromRGB(168, 85, 247),
    Epic = Color3.fromRGB(192, 38, 211),
    Legendary = Color3.fromRGB(245, 158, 11),
    Mythical = Color3.fromRGB(239, 68, 68),
    Secret = Color3.fromRGB(236, 72, 153),
    Limited = Color3.fromRGB(16, 185, 129),
}

local function getHiredRoles()
    local hired = { Assigner = false, Dishwasher = false, WorkerCount = 0 }
    local plot = getPlayerPlot()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") and d:GetAttribute("IsWorker") == true then
            local wp = d:GetAttribute("WorkerPlot")
            local isHired = d:GetAttribute("Hired")
            local role = d:GetAttribute("Role")
            local isMine = (plot and (wp == plot.Name or d:IsDescendantOf(plot)))
            if isMine and isHired then
                hired.WorkerCount = hired.WorkerCount + 1
                if role == "Assigner" then
                    hired.Assigner = true
                elseif role == "Dishwasher" then
                    hired.Dishwasher = true
                end
            end
        end
    end
    return hired
end

-- 10. Auto Redeem Codes & Group Reward
local isRedeemingCodes = false
local function redeemAllCodes()
    if isRedeemingCodes or not RedeemCodeRemote then return end
    isRedeemingCodes = true
    setActivity("Redeeming Gift Codes...", Color3.fromRGB(59, 130, 246))

    local codes = {}
    if type(CodeConfig) == "table" then
        for codeKey, _ in pairs(CodeConfig) do
            table.insert(codes, tostring(codeKey))
        end
    end
    if #codes == 0 then
        codes = { "50KCCU", "DECOPART1" }
    end

    local count = 0
    for _, code in ipairs(codes) do
        local ok = pcall(function()
            RedeemCodeRemote:FireServer(tostring(code))
        end)
        if ok then count = count + 1 end
        task.wait(0.25)
    end
    setActivity("Redeemed " .. count .. " codes!", Color3.fromRGB(52, 199, 89))
    isRedeemingCodes = false
end

local isClaimingGroup = false
local function claimGroupReward()
    if isClaimingGroup or not ClaimGroupRewardRemote then return end
    isClaimingGroup = true
    setActivity("Checking Group Reward...", Color3.fromRGB(245, 158, 11))

    local isClaimed = false
    if IsGroupClaimedRemote then
        local ok, res = pcall(function() return IsGroupClaimedRemote:InvokeServer() end)
        if ok and res == true then
            isClaimed = true
        end
    end

    if not isClaimed then
        pcall(function()
            ClaimGroupRewardRemote:FireServer()
        end)
        setActivity("Claimed Group Reward! ⭐", Color3.fromRGB(52, 199, 89))
    else
        setActivity("Group Reward Already Claimed", Color3.fromRGB(160, 160, 160))
    end
    isClaimingGroup = false
end

-- 11. Travelling Merchant Auto Buy
local isBuyingMerchant = false
local lastMerchantCheck = 0
local function doMerchantAutoBuy()
    if isBuyingMerchant or not BuyMerchantItem or not GetMerchantStock then return end
    if not (Config.MerchantAutoBuyWeapons or Config.MerchantAutoBuyFurniture) then return end
    if os.clock() - lastMerchantCheck < 4 then return end
    lastMerchantCheck = os.clock()

    isBuyingMerchant = true
    task.spawn(function()
        local ok, stock = pcall(function() return GetMerchantStock:InvokeServer() end)
        if ok and type(stock) == "table" then
            for _, item in pairs(stock) do
                if type(item) == "table" and item.Key and item.Category then
                    local isWeapon = (item.Category == "Weapons")
                    local isFurniture = (item.Category == "Chairs" or item.Category == "Tables")

                    local shouldBuy = false
                    if isWeapon and Config.MerchantAutoBuyWeapons then
                        shouldBuy = true
                    elseif isFurniture and Config.MerchantAutoBuyFurniture then
                        shouldBuy = true
                    end

                    if shouldBuy then
                        pcall(function()
                            BuyMerchantItem:InvokeServer(item.Key)
                        end)
                        setActivity("Bought Merchant: " .. tostring(item.Key), Color3.fromRGB(52, 199, 89))
                        task.wait(0.2)
                    end
                end
            end
        end
        isBuyingMerchant = false
    end)
end

-- 12. Gacha Worker Auto Roll & Auto Hire
local isRollingWorker = false
local lastWorkerRollTime = 0
local function doWorkerAutoRoll()
    if isRollingWorker or not RollWorkerRemote or not HireWorkerRemote or not GetWaitingWorkersRemote then return end
    if not Config.WorkerAutoRoll then return end
    if os.clock() - lastWorkerRollTime < 1.2 then return end
    lastWorkerRollTime = os.clock()

    local cash = LocalPlayer.leaderstats and LocalPlayer.leaderstats:FindFirstChild("Cash")
    if cash and cash.Value < 100 then
        setActivity("Low Cash for Worker Roll (₱" .. cash.Value .. ")", Color3.fromRGB(239, 68, 68))
        return
    end

    isRollingWorker = true
    task.spawn(function()
        -- 1. Check current waiting pool first
        local okWait, waitRes = pcall(function() return GetWaitingWorkersRemote:InvokeServer() end)
        local candidates = (okWait and type(waitRes) == "table" and (waitRes.w2 or waitRes)) or {}

        local targetRank = RARITY_RANKS[Config.WorkerMinRarity] or 5
        local bestCandidate = nil
        local bestRank = 0

        for _, cand in pairs(candidates) do
            if type(cand) == "table" and cand.Name and cand.Rarity then
                local rank = RARITY_RANKS[cand.Rarity] or 1
                if rank >= targetRank and rank > bestRank then
                    bestCandidate = cand
                    bestRank = rank
                end
            end
        end

        -- If a matching high-rarity candidate is waiting:
        if bestCandidate then
            local role = Config.WorkerTargetRole
            if role == "Manual Pick" or not role then
                Config.WorkerAutoRoll = false -- Stop rolling so player can pick
                setActivity("Found " .. tostring(bestCandidate.Template or bestCandidate.Name) .. " (" .. tostring(bestCandidate.Rarity) .. ")! Pick role to hire below.", Color3.fromRGB(52, 199, 89))
                isRollingWorker = false
                return
            else
                if role == "Any" then
                    local hiredRoles = getHiredRoles()
                    role = not hiredRoles.Assigner and "Assigner" or "Dishwasher"
                end
                local hOk, hRes = pcall(function()
                    return HireWorkerRemote:InvokeServer(bestCandidate.Name, role)
                end)
                if hOk and hRes then
                    setActivity("Hired " .. tostring(bestCandidate.Template or bestCandidate.Name) .. " (" .. tostring(bestCandidate.Rarity) .. ") as " .. role .. "!", Color3.fromRGB(52, 199, 89))
                    Config.WorkerAutoRoll = false
                    isRollingWorker = false
                    return
                end
            end
        end

        -- 2. If no matching candidate, roll new candidates
        setActivity("Rolling Worker Gacha (₱100)...", Color3.fromRGB(168, 85, 247))
        pcall(function()
            RollWorkerRemote:InvokeServer("Roll")
        end)
        task.wait(0.6)
        isRollingWorker = false
    end)
end

--------------------------------------------------------------------------------
-- EVENT-DRIVEN SIGNALS & PRIORITY LOOP
--------------------------------------------------------------------------------
task.spawn(function()
    local plot = getPlayerPlot()
    local wash = plot and plot:FindFirstChild("Wash", true)
    if wash then
        trackConn(wash:GetAttributeChangedSignal("HasDishes"):Connect(function()
            if wash:GetAttribute("HasDishes") == true and Config.AutoWash and not isWashing then
                task.defer(doAutoWash)
            end
        end))
    end
end)

if NPCRemotes then
    local arrived = NPCRemotes:FindFirstChild("NPCArrivedAtSpot1")
    if arrived then
        trackConn(arrived.OnClientEvent:Connect(function()
            if Config.AutoAssign then task.defer(doAutoAssign) end
        end))
    end

    local seated = NPCRemotes:FindFirstChild("NPCSeated")
    if seated then
        trackConn(seated.OnClientEvent:Connect(function()
            if Config.AutoAssign then task.delay(0.15, doAutoAssign) end
        end))
    end

    local softdrinks = NPCRemotes:FindFirstChild("SoftdrinkOrdersUpdated")
    if softdrinks then
        trackConn(softdrinks.OnClientEvent:Connect(function()
            if Config.AutoGiveSoftdrinks then task.defer(doAutoGiveSoftdrinks) end
        end))
    end
end

if Remotes then
    local runaway = Remotes:FindFirstChild("CustomerRanAwayEvent")
    if runaway then
        trackConn(runaway.OnClientEvent:Connect(function()
            if Config.AutoChaseThieves then task.defer(doAutoChaseThieves) end
        end))
    end
end

if ShopRestocked then
    trackConn(ShopRestocked.OnClientEvent:Connect(function()
        if Config.ShopAutoBuy then task.defer(doShopAutoBuy) end
    end))
end

-- Priority Orchestrator Loop
spawnLoop(0.25, function()
    if Config.AutoChaseThieves then doAutoChaseThieves() end
    if Config.AutoWakeWorker then doAutoWakeWorker() end

    if Config.AutoAssign then doAutoAssign() end
    if Config.AutoGiveSoftdrinks then doAutoGiveSoftdrinks() end
    if Config.TableActions then doTableActions() end
    if Config.AutoWash then doAutoWash() end

    if Config.AutoCleanTrash then doAutoCleanTrash() end
    if Config.GroceryAutoBuy then doGroceryAutoBuy() end
    if Config.ShopAutoBuy then doShopAutoBuy() end

    -- Merchant & Worker Automations
    if Config.MerchantAutoBuyWeapons or Config.MerchantAutoBuyFurniture then
        doMerchantAutoBuy()
    end
    if Config.WorkerAutoRoll then
        doWorkerAutoRoll()
    end

    if Config.SpeedBoost then
        local hum = getHumanoid()
        if hum and hum.WalkSpeed < Config.BoostSpeed then
            hum.WalkSpeed = Config.BoostSpeed
        end
    end
end)

-- Auto Claim Free Gifts & Codes on Start
if Config.AutoClaimGiftsOnStart then
    task.spawn(function()
        task.wait(2)
        claimGroupReward()
        task.wait(0.5)
        redeemAllCodes()
    end)
end

-- Anti-AFK
trackConn(LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end
end))

-- Periodic Discord Webhook Dispatcher
spawnLoop(1, function()
    if not Config.WebhookEnabled or not Config.WebhookURL or Config.WebhookURL == "" then return end
    local intervalSec = INTERVAL_MAP[Config.WebhookInterval] or 300
    local elapsedSince = os.clock() - (Hub.LastWebhookSent or 0)
    if elapsedSince >= intervalSec then
        sendDiscordWebhookReport(false)
    end
end)

--------------------------------------------------------------------------------
-- USER INTERFACE CONSTRUCTION
--------------------------------------------------------------------------------
local function getGuiParent()
    if gethui then
        return gethui()
    elseif syn and syn.protect_gui and CoreGui then
        return CoreGui
    elseif CoreGui:FindFirstChild("RobloxGui") then
        return CoreGui.RobloxGui
    else
        return LocalPlayer:WaitForChild("PlayerGui")
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KarinderyaHub_UI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local targetParent = getGuiParent()
screenGui.Parent = targetParent
Hub.UI = screenGui

-- Color Palette & Apple Liquid Glass Design System
local C_BG = Color3.fromRGB(16, 20, 28)
local C_HEADER = Color3.fromRGB(22, 28, 42)
local C_CARD_BG = Color3.fromRGB(24, 30, 46)
local C_ROW_BG = Color3.fromRGB(32, 40, 60)
local C_STROKE = Color3.fromRGB(80, 95, 125)
local C_SIDEBAR_ACTIVE = Color3.fromRGB(10, 132, 255)
local C_SIDEBAR_INACTIVE = Color3.fromRGB(28, 35, 52)
local C_BTN_ON = Color3.fromRGB(52, 199, 89)
local C_BTN_OFF = Color3.fromRGB(48, 54, 70)

-- Helper: Apple Specular Liquid Glass Chamfered Border
local function applyGlassStroke(instance, thickness, topTrans, botTrans)
    local stroke = Instance.new("UIStroke")
    stroke.Name = "GlassStroke"
    stroke.Thickness = thickness or 1.2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Parent = instance

    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(210, 225, 250)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(75, 90, 125))
    })
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, topTrans or 0.28),
        NumberSequenceKeypoint.new(0.55, (topTrans or 0.28) + 0.35),
        NumberSequenceKeypoint.new(1, botTrans or 0.85)
    })
    grad.Parent = stroke
    return stroke
end

-- Main Container Window (Apple Liquid Glass Modal)
local mainWindow = Instance.new("Frame")
mainWindow.Name = "MainWindow"
mainWindow.Size = UDim2.new(0, 600, 0, 410)
mainWindow.Position = UDim2.new(0.5, -300, 0.5, -205)
mainWindow.BackgroundColor3 = C_BG
mainWindow.BackgroundTransparency = 0.16
mainWindow.BorderSizePixel = 0
mainWindow.ClipsDescendants = false
mainWindow.Parent = screenGui

local windowCorner = Instance.new("UICorner")
windowCorner.CornerRadius = UDim.new(0, 16)
windowCorner.Parent = mainWindow

applyGlassStroke(mainWindow, 1.4, 0.22, 0.82)

local windowGrad = Instance.new("UIGradient")
windowGrad.Rotation = 45
windowGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 38, 56)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(18, 22, 34)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 15, 24))
})
windowGrad.Parent = mainWindow

-- Ambient Floating Drop Shadow (iPhone Modal Elevation)
local windowShadow = Instance.new("ImageLabel")
windowShadow.Name = "WindowShadow"
windowShadow.AnchorPoint = Vector2.new(0.5, 0.5)
windowShadow.Position = UDim2.new(0.5, 0, 0.5, 6)
windowShadow.Size = UDim2.new(1, 48, 1, 48)
windowShadow.BackgroundTransparency = 1
windowShadow.Image = "rbxassetid://6015897843"
windowShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
windowShadow.ImageTransparency = 0.4
windowShadow.ScaleType = Enum.ScaleType.Slice
windowShadow.SliceCenter = Rect.new(49, 49, 450, 450)
windowShadow.ZIndex = -1
windowShadow.Parent = mainWindow

-- Title Bar Header (Translucent Frosted Glass)
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = C_HEADER
header.BackgroundTransparency = 0.35
header.BorderSizePixel = 0
header.Parent = mainWindow

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header

local headerMask = Instance.new("Frame")
headerMask.Name = "HeaderMask"
headerMask.Size = UDim2.new(1, 0, 0, 14)
headerMask.Position = UDim2.new(0, 0, 1, -14)
headerMask.BackgroundColor3 = C_HEADER
headerMask.BackgroundTransparency = 0.35
headerMask.BorderSizePixel = 0
headerMask.Parent = header

-- Specular Bottom Shine Divider for Header
local headerShine = Instance.new("Frame")
headerShine.Name = "HeaderShine"
headerShine.Size = UDim2.new(1, 0, 0, 1)
headerShine.Position = UDim2.new(0, 0, 1, 0)
headerShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
headerShine.BorderSizePixel = 0
headerShine.Parent = header

local shineGrad = Instance.new("UIGradient")
shineGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 180, 225)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 180, 225))
})
shineGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.96),
    NumberSequenceKeypoint.new(0.5, 0.72),
    NumberSequenceKeypoint.new(1, 0.96)
})
shineGrad.Parent = headerShine

-- Avatar Icon (Left)
local avatarIcon = Instance.new("ImageLabel")
avatarIcon.Name = "AvatarIcon"
avatarIcon.Size = UDim2.new(0, 28, 0, 28)
avatarIcon.Position = UDim2.new(0, 12, 0.5, -14)
avatarIcon.BackgroundColor3 = Color3.fromRGB(40, 48, 65)
avatarIcon.Image = "rbxassetid://109876251688116"
avatarIcon.Parent = header

local avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(1, 0)
avatarCorner.Parent = avatarIcon

local avatarStroke = Instance.new("UIStroke")
avatarStroke.Color = Color3.fromRGB(255, 255, 255)
avatarStroke.Transparency = 0.65
avatarStroke.Thickness = 1
avatarStroke.Parent = avatarIcon

-- Title Label (Apple SF Pro Style Typography)
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Text = "Karinderya by Kiri"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0, 48, 0, 0)
titleLabel.Size = UDim2.new(0, 160, 1, 0)
titleLabel.Parent = header

-- Live Balance Pill (Liquid Glass Stat Badge - Cash Only)
local statPill = Instance.new("Frame")
statPill.Name = "StatPill"
statPill.Size = UDim2.new(0, 130, 0, 24)
statPill.Position = UDim2.new(1, -245, 0.5, -12)
statPill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
statPill.BackgroundTransparency = 0.94
statPill.BorderSizePixel = 0
statPill.Parent = header

local statCorner = Instance.new("UICorner")
statCorner.CornerRadius = UDim.new(1, 0)
statCorner.Parent = statPill

local statStroke = Instance.new("UIStroke")
statStroke.Thickness = 1
statStroke.Color = Color3.fromRGB(255, 214, 10)
statStroke.Transparency = 0.72
statStroke.Parent = statPill

local cashBadge = Instance.new("TextLabel")
cashBadge.Name = "CashBadge"
cashBadge.Text = "₱0"
cashBadge.Font = Enum.Font.GothamBold
cashBadge.TextSize = 12
cashBadge.TextColor3 = Color3.fromRGB(255, 214, 10) -- Warm Apple Gold
cashBadge.TextXAlignment = Enum.TextXAlignment.Center
cashBadge.BackgroundTransparency = 1
cashBadge.Size = UDim2.new(1, 0, 1, 0)
cashBadge.Position = UDim2.new(0, 0, 0, 0)
cashBadge.Parent = statPill

local function updateHeaderStats()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local cVal = leaderstats and leaderstats:FindFirstChild("Cash") and leaderstats.Cash.Value or 0
    cashBadge.Text = "₱" .. formatNumber(cVal)
end
updateHeaderStats()

task.spawn(function()
    local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
    if leaderstats then
        local cObj = leaderstats:WaitForChild("Cash", 5)
        if cObj then trackConn(cObj.Changed:Connect(updateHeaderStats)) end
    end
end)

-- Header Controls (Right - Apple Traffic Lights)
local headerControls = Instance.new("Frame")
headerControls.Name = "HeaderControls"
headerControls.BackgroundTransparency = 1
headerControls.Size = UDim2.new(0, 95, 1, 0)
headerControls.Position = UDim2.new(1, -104, 0, 0)
headerControls.Parent = header

local headerLayout = Instance.new("UIListLayout")
headerLayout.FillDirection = Enum.FillDirection.Horizontal
headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
headerLayout.Padding = UDim.new(0, 7)
headerLayout.Parent = headerControls

local function makeHeaderButton(name, text, bgColor, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = bgColor
    btn.BackgroundTransparency = 0.12
    btn.Size = UDim2.new(0, 22, 0, 22)
    btn.AutoButtonColor = true
    btn.Parent = headerControls

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn

    local bStroke = Instance.new("UIStroke")
    bStroke.Thickness = 1
    bStroke.Color = Color3.fromRGB(255, 255, 255)
    bStroke.Transparency = 0.55
    bStroke.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

makeHeaderButton("BtnInfo", "!", Color3.fromRGB(10, 132, 255), function()
    print("[Karinderya by Kiri] Ultra-Smooth Liquid Glass Suite Active!")
end)

local isMinimized = false
makeHeaderButton("BtnMin", "-", Color3.fromRGB(255, 159, 10), function()
    isMinimized = not isMinimized
    local contentHolder = mainWindow:FindFirstChild("ContentHolder")
    local sidebar = mainWindow:FindFirstChild("Sidebar")
    local statusBar = mainWindow:FindFirstChild("StatusBar")
    local resizeHandle = mainWindow:FindFirstChild("ResizeGrip")
    if isMinimized then
        if contentHolder then contentHolder.Visible = false end
        if sidebar then sidebar.Visible = false end
        if statusBar then statusBar.Visible = false end
        if resizeHandle then resizeHandle.Visible = false end
        TweenService:Create(mainWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(mainWindow.Size.X.Scale, mainWindow.Size.X.Offset, 0, 44)
        }):Play()
    else
        TweenService:Create(mainWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(mainWindow.Size.X.Scale, mainWindow.Size.X.Offset, 0, 410)
        }):Play()
        task.delay(0.2, function()
            if contentHolder then contentHolder.Visible = true end
            if sidebar then sidebar.Visible = true end
            if statusBar then statusBar.Visible = true end
            if resizeHandle then resizeHandle.Visible = true end
        end)
    end
end)

makeHeaderButton("BtnClose", "X", Color3.fromRGB(255, 69, 58), function()
    Hub.Unload()
end)

-- Window Dragging Functionality
local dragging, dragInput, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainWindow.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Sidebar Navigation (Left)
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 130, 1, -74)
sidebar.Position = UDim2.new(0, 10, 0, 48)
sidebar.BackgroundTransparency = 1
sidebar.Parent = mainWindow

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.FillDirection = Enum.FillDirection.Vertical
sidebarLayout.Padding = UDim.new(0, 10)
sidebarLayout.Parent = sidebar

-- Tab Pages Container
local contentHolder = Instance.new("Frame")
contentHolder.Name = "ContentHolder"
contentHolder.Size = UDim2.new(1, -156, 1, -74)
contentHolder.Position = UDim2.new(0, 146, 0, 48)
contentHolder.BackgroundTransparency = 1
contentHolder.Parent = mainWindow

-- Bottom Status Bar (Liquid Glass Pill)
local statusBar = Instance.new("Frame")
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(1, -24, 0, 22)
statusBar.Position = UDim2.new(0, 12, 1, -26)
statusBar.BackgroundTransparency = 1
statusBar.Parent = mainWindow

local statusDot = Instance.new("TextLabel")
statusDot.Name = "StatusDot"
statusDot.Text = "●"
statusDot.Font = Enum.Font.GothamBold
statusDot.TextSize = 13
statusDot.TextColor3 = Color3.fromRGB(52, 199, 89) -- Apple System Green
statusDot.Size = UDim2.new(0, 14, 1, 0)
statusDot.BackgroundTransparency = 1
statusDot.Parent = statusBar
Hub.StatusDot = statusDot

-- Subtle breathing animation for status dot
task.spawn(function()
    while Hub.Running do
        TweenService:Create(statusDot, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextTransparency = 0.5 }):Play()
        task.wait(1.2)
        if not Hub.Running then break end
        TweenService:Create(statusDot, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextTransparency = 0 }):Play()
        task.wait(1.2)
    end
end)

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Text = "Status: Idle"
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 11
statusLabel.TextColor3 = Color3.fromRGB(165, 180, 205)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Size = UDim2.new(1, -22, 1, 0)
statusLabel.Position = UDim2.new(0, 20, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Parent = statusBar
Hub.StatusLabel = statusLabel

local tabButtons = {}
local tabPages = {}

local function switchTab(tabName)
    for name, page in pairs(tabPages) do
        page.Visible = (name == tabName)
    end
    for name, btn in pairs(tabButtons) do
        local isActive = (name == tabName)
        local stroke = btn:FindFirstChild("TabStroke")
        TweenService:Create(btn, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = isActive and Color3.fromRGB(14, 115, 235) or Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = isActive and 0.18 or 0.94,
            TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 185, 210)
        }):Play()
        if stroke then
            TweenService:Create(stroke, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Color = isActive and Color3.fromRGB(120, 200, 255) or Color3.fromRGB(255, 255, 255),
                Transparency = isActive and 0.35 or 0.88
            }):Play()
        end
    end
end

local function createTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Name = "Tab_" .. name
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 0.94
    btn.TextColor3 = Color3.fromRGB(170, 185, 210)
    btn.AutoButtonColor = true
    btn.Parent = sidebar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Name = "TabStroke"
    stroke.Thickness = 1.1
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.88
    stroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        switchTab(name)
    end)

    tabButtons[name] = btn

    local page = Instance.new("Frame")
    page.Name = "Page_" .. name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = contentHolder

    tabPages[name] = page
    return page
end

--------------------------------------------------------------------------------
-- TAB PAGES INITIALIZATION
--------------------------------------------------------------------------------
local mainPage = createTabButton("Main")
local shopPage = createTabButton("Shop")
local workersPage = createTabButton("Workers")
local merchantPage = createTabButton("Merchant")
local webhookPage = createTabButton("Webhook")
local configPage = createTabButton("Config")

--------------------------------------------------------------------------------
-- SHARED CARD & ROW BUILDER HELPERS
--------------------------------------------------------------------------------
local function createCard(title, parent)
    local card = Instance.new("Frame")
    card.Name = "Card_" .. title
    card.Size = UDim2.new(0.5, -5, 1, 0)
    card.BackgroundColor3 = C_CARD_BG
    card.BackgroundTransparency = 0.35
    card.BorderSizePixel = 0
    card.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card

    applyGlassStroke(card, 1.2, 0.4, 0.85)

    local cardGrad = Instance.new("UIGradient")
    cardGrad.Rotation = 90
    cardGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 40, 58)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 22, 34))
    })
    cardGrad.Parent = card

    local headerLabel = Instance.new("TextLabel")
    headerLabel.Name = "Title"
    headerLabel.Text = title:upper()
    headerLabel.Font = Enum.Font.GothamBold
    headerLabel.TextSize = 12
    headerLabel.TextColor3 = Color3.fromRGB(165, 180, 205)
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.BackgroundTransparency = 1
    headerLabel.Size = UDim2.new(1, -20, 0, 32)
    headerLabel.Position = UDim2.new(0, 12, 0, 2)
    headerLabel.Parent = card

    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(1, -24, 0, 1)
    divider.Position = UDim2.new(0, 12, 0, 34)
    divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    divider.BackgroundTransparency = 0.88
    divider.BorderSizePixel = 0
    divider.Parent = card

    local rowsContainer = Instance.new("ScrollingFrame")
    rowsContainer.Name = "RowsContainer"
    rowsContainer.Size = UDim2.new(1, -12, 1, -44)
    rowsContainer.Position = UDim2.new(0, 6, 0, 40)
    rowsContainer.BackgroundTransparency = 1
    rowsContainer.ScrollBarThickness = 2
    rowsContainer.ScrollBarImageColor3 = Color3.fromRGB(120, 180, 255)
    rowsContainer.ScrollBarImageTransparency = 0.5
    rowsContainer.BorderSizePixel = 0
    rowsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    rowsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    rowsContainer.Parent = card

    local rowsLayout = Instance.new("UIListLayout")
    rowsLayout.FillDirection = Enum.FillDirection.Vertical
    rowsLayout.Padding = UDim.new(0, 8)
    rowsLayout.Parent = rowsContainer

    return rowsContainer
end

local function createToggleRow(label, initialValue, onToggle, parent)
    local row = Instance.new("Frame")
    row.Name = "Row_" .. label
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    row.BackgroundTransparency = 0.94
    row.BorderSizePixel = 0
    row.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Thickness = 1
    rowStroke.Color = Color3.fromRGB(255, 255, 255)
    rowStroke.Transparency = 0.9
    rowStroke.Parent = row

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Label"
    textLabel.Text = label
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 12
    textLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextTruncate = Enum.TextTruncate.AtEnd
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -66, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.Parent = row

    -- iOS Style Switch Track (46x24 Pill)
    local switchTrack = Instance.new("TextButton")
    switchTrack.Name = "ToggleBtn"
    switchTrack.Text = ""
    switchTrack.Size = UDim2.new(0, 46, 0, 24)
    switchTrack.Position = UDim2.new(1, -54, 0.5, -12)
    switchTrack.BackgroundColor3 = initialValue and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(48, 54, 70)
    switchTrack.BackgroundTransparency = initialValue and 0.12 or 0.4
    switchTrack.BorderSizePixel = 0
    switchTrack.AutoButtonColor = false
    switchTrack.Parent = row

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = switchTrack

    local trackStroke = Instance.new("UIStroke")
    trackStroke.Thickness = 1
    trackStroke.Color = initialValue and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(255, 255, 255)
    trackStroke.Transparency = initialValue and 0.45 or 0.85
    trackStroke.Parent = switchTrack

    -- White Circular Thumb Knob (20x20)
    local thumb = Instance.new("Frame")
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(0, 20, 0, 20)
    thumb.Position = initialValue and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.Parent = switchTrack

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0)
    thumbCorner.Parent = thumb

    local thumbShadow = Instance.new("UIStroke")
    thumbShadow.Thickness = 1
    thumbShadow.Color = Color3.fromRGB(0, 0, 0)
    thumbShadow.Transparency = 0.85
    thumbShadow.Parent = thumb

    local isEnabled = initialValue
    local function updateSwitch(animate)
        local targetColor = isEnabled and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(48, 54, 70)
        local targetTrans = isEnabled and 0.12 or 0.4
        local targetStrokeCol = isEnabled and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(255, 255, 255)
        local targetStrokeTrans = isEnabled and 0.45 or 0.85
        local targetThumbPos = isEnabled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)

        if animate then
            local twInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(switchTrack, twInfo, { BackgroundColor3 = targetColor, BackgroundTransparency = targetTrans }):Play()
            TweenService:Create(trackStroke, twInfo, { Color = targetStrokeCol, Transparency = targetStrokeTrans }):Play()
            TweenService:Create(thumb, twInfo, { Position = targetThumbPos }):Play()
        else
            switchTrack.BackgroundColor3 = targetColor
            switchTrack.BackgroundTransparency = targetTrans
            trackStroke.Color = targetStrokeCol
            trackStroke.Transparency = targetStrokeTrans
            thumb.Position = targetThumbPos
        end
    end

    switchTrack.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        updateSwitch(true)
        onToggle(isEnabled)
    end)

    return row
end

local function createButtonRow(label, btnText, btnColor, onClick, parent)
    local row = Instance.new("Frame")
    row.Name = "BtnRow_" .. label
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    row.BackgroundTransparency = 0.94
    row.BorderSizePixel = 0
    row.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Thickness = 1
    rowStroke.Color = Color3.fromRGB(255, 255, 255)
    rowStroke.Transparency = 0.9
    rowStroke.Parent = row

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Label"
    textLabel.Text = label
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 12
    textLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextTruncate = Enum.TextTruncate.AtEnd
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -115, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.Parent = row

    local actBtn = Instance.new("TextButton")
    actBtn.Name = "ActionBtn"
    actBtn.Text = btnText or "Action"
    actBtn.Font = Enum.Font.GothamBold
    actBtn.TextSize = 11
    actBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    actBtn.Size = UDim2.new(0, 95, 0, 26)
    actBtn.Position = UDim2.new(1, -103, 0.5, -13)
    actBtn.BackgroundColor3 = btnColor or Color3.fromRGB(14, 115, 235)
    actBtn.BackgroundTransparency = 0.15
    actBtn.BorderSizePixel = 0
    actBtn.AutoButtonColor = true
    actBtn.Parent = row

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = actBtn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Thickness = 1
    btnStroke.Color = Color3.fromRGB(255, 255, 255)
    btnStroke.Transparency = 0.6
    btnStroke.Parent = actBtn

    actBtn.MouseButton1Click:Connect(function()
        TweenService:Create(actBtn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 91, 0, 24), Position = UDim2.new(1, -101, 0.5, -12) }):Play()
        task.wait(0.08)
        TweenService:Create(actBtn, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 95, 0, 26), Position = UDim2.new(1, -103, 0.5, -13) }):Play()
        if onClick then
            onClick(actBtn)
        end
    end)

    return row, actBtn
end

local function createValueCycleRow(label, initialValue, options, onCycle, parent)
    local row = Instance.new("Frame")
    row.Name = "CycleRow_" .. label
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    row.BackgroundTransparency = 0.94
    row.BorderSizePixel = 0
    row.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Thickness = 1
    rowStroke.Color = Color3.fromRGB(255, 255, 255)
    rowStroke.Transparency = 0.9
    rowStroke.Parent = row

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Label"
    textLabel.Text = label
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 12
    textLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextTruncate = Enum.TextTruncate.AtEnd
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -115, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.Parent = row

    local currentVal = initialValue
    local cycleBtn = Instance.new("TextButton")
    cycleBtn.Name = "CycleBtn"
    cycleBtn.Text = tostring(currentVal)
    cycleBtn.Font = Enum.Font.GothamBold
    cycleBtn.TextSize = 11
    cycleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    cycleBtn.Size = UDim2.new(0, 95, 0, 26)
    cycleBtn.Position = UDim2.new(1, -103, 0.5, -13)
    cycleBtn.BackgroundColor3 = Color3.fromRGB(48, 56, 75)
    cycleBtn.BackgroundTransparency = 0.2
    cycleBtn.BorderSizePixel = 0
    cycleBtn.AutoButtonColor = true
    cycleBtn.Parent = row

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = cycleBtn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Thickness = 1
    btnStroke.Color = Color3.fromRGB(255, 255, 255)
    btnStroke.Transparency = 0.7
    btnStroke.Parent = cycleBtn

    cycleBtn.MouseButton1Click:Connect(function()
        local idx = 1
        for i, opt in ipairs(options) do
            if opt == currentVal then
                idx = i
                break
            end
        end
        local nextIdx = (idx % #options) + 1
        currentVal = options[nextIdx]
        cycleBtn.Text = tostring(currentVal)
        if onCycle then
            onCycle(currentVal)
        end
    end)

    return row, cycleBtn
end

--------------------------------------------------------------------------------
-- MAIN TAB
--------------------------------------------------------------------------------
do
    local mainColumnsLayout = Instance.new("UIListLayout")
    mainColumnsLayout.FillDirection = Enum.FillDirection.Horizontal
    mainColumnsLayout.Padding = UDim.new(0, 10)
    mainColumnsLayout.Parent = mainPage

local syncShopGroceryAutoBuyUI = nil
local syncShopGroceryThresholdUI = nil
local syncMainGroceryAutoBuyUI = nil
local syncMainGroceryThresholdUI = nil

    -- 1. Left Card: "Karinderya"
    local karinderyaRows = createCard("Karinderya", mainPage)
    createToggleRow("Auto Assign", Config.AutoAssign, function(v) Config.AutoAssign = v end, karinderyaRows)
    createToggleRow("Table Actions", Config.TableActions, function(v) Config.TableActions = v end, karinderyaRows)
    createToggleRow("Auto Wash", Config.AutoWash, function(v) Config.AutoWash = v end, karinderyaRows)
    createToggleRow("Auto Give Softdrinks", Config.AutoGiveSoftdrinks, function(v) Config.AutoGiveSoftdrinks = v end, karinderyaRows)

    local mainAutoBuyRow = createToggleRow("Auto Buy Grocery", Config.GroceryAutoBuy, function(v)
        Config.GroceryAutoBuy = v
        saveWebhookConfig()
        setActivity(v and ("Auto Buy Grocery ON (< " .. (Config.GroceryThreshold or 25) .. "%)") or "Auto Buy Grocery OFF", Color3.fromRGB(52, 199, 89))
        if syncShopGroceryAutoBuyUI then syncShopGroceryAutoBuyUI() end
    end, karinderyaRows)

    local mainThreshRow, mainThreshBtn = createValueCycleRow("Grocery Min Stock", "< " .. tostring(Config.GroceryThreshold or 25) .. "%", { "< 10%", "< 25%", "< 50%", "< 75%" }, function(v)
        local num = tonumber(v:match("%d+")) or 25
        Config.GroceryThreshold = num
        saveWebhookConfig()
        setActivity("Grocery Auto Buy when stock < " .. num .. "%", Color3.fromRGB(255, 214, 10))
        if syncShopGroceryThresholdUI then syncShopGroceryThresholdUI(num) end
    end, karinderyaRows)

    syncMainGroceryThresholdUI = function(num)
        if mainThreshBtn then
            mainThreshBtn.Text = "< " .. tostring(num) .. "%"
        end
    end

    -- 2. Right Card: "Extra"
    local extraRows = createCard("Extra", mainPage)
    createToggleRow("Auto Chase Thieves (+ Pan)", Config.AutoChaseThieves, function(v) Config.AutoChaseThieves = v end, extraRows)
    createToggleRow("Auto Wake Worker (+ Pan)", Config.AutoWakeWorker, function(v) Config.AutoWakeWorker = v end, extraRows)
    createToggleRow("Auto Clean Trash", Config.AutoCleanTrash, function(v) Config.AutoCleanTrash = v end, extraRows)
    createToggleRow("Auto Claim on Start", Config.AutoClaimGiftsOnStart, function(v)
        Config.AutoClaimGiftsOnStart = v
    end, extraRows)

    createButtonRow("Redeem All Codes", "Redeem 🎁", Color3.fromRGB(14, 115, 235), function(btn)
        btn.Text = "Redeeming..."
        task.spawn(function()
            redeemAllCodes()
            task.wait(1.5)
            btn.Text = "Redeem 🎁"
        end)
    end, extraRows)

    createButtonRow("Claim Group Reward", "Claim ⭐", Color3.fromRGB(245, 158, 11), function(btn)
        btn.Text = "Claiming..."
        task.spawn(function()
            claimGroupReward()
            task.wait(1.5)
            btn.Text = "Claim ⭐"
        end)
    end, extraRows)
end

--------------------------------------------------------------------------------
-- SHOP TAB (Exact Replica of User Provided Screenshot)
--------------------------------------------------------------------------------
do
    local shopMainCard = Instance.new("Frame")
shopMainCard.Name = "ShopMainCard"
shopMainCard.Size = UDim2.new(1, 0, 1, 0)
shopMainCard.BackgroundColor3 = C_CARD_BG
shopMainCard.BackgroundTransparency = 0.35
shopMainCard.BorderSizePixel = 0
shopMainCard.Parent = shopPage

local shopCardCorner = Instance.new("UICorner")
shopCardCorner.CornerRadius = UDim.new(0, 12)
shopCardCorner.Parent = shopMainCard

applyGlassStroke(shopMainCard, 1.2, 0.4, 0.85)

local shopCardGrad = Instance.new("UIGradient")
shopCardGrad.Rotation = 90
shopCardGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 40, 58)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 22, 34))
})
shopCardGrad.Parent = shopMainCard

local renderGroceryGridShared = nil

local function buildGrocerySection()
    -- 1. TOP HEADER: GROCERY
    local groceryHeader = Instance.new("Frame")
    groceryHeader.Name = "GroceryHeader"
    groceryHeader.Size = UDim2.new(1, -20, 0, 36)
    groceryHeader.Position = UDim2.new(0, 10, 0, 8)
    groceryHeader.BackgroundTransparency = 1
    groceryHeader.Parent = shopMainCard

local groceryLabel = Instance.new("TextLabel")
groceryLabel.Name = "GroceryLabel"
groceryLabel.Text = "GROCERY"
groceryLabel.Font = Enum.Font.GothamBold
groceryLabel.TextSize = 12
groceryLabel.TextColor3 = Color3.fromRGB(165, 180, 205)
groceryLabel.TextXAlignment = Enum.TextXAlignment.Left
groceryLabel.Size = UDim2.new(0, 58, 1, 0)
groceryLabel.Position = UDim2.new(0, 0, 0, 0)
groceryLabel.BackgroundTransparency = 1
groceryLabel.Parent = groceryHeader

-- Dropdown Button for Grocery (Liquid Glass Pill)
local groceryDropdownBtn = Instance.new("TextButton")
groceryDropdownBtn.Name = "GroceryDropdownBtn"
groceryDropdownBtn.Text = "Category  ▼"
groceryDropdownBtn.Font = Enum.Font.GothamBold
groceryDropdownBtn.TextSize = 11
groceryDropdownBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
groceryDropdownBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
groceryDropdownBtn.BackgroundTransparency = 0.93
groceryDropdownBtn.Size = UDim2.new(0, 130, 0, 28)
groceryDropdownBtn.Position = UDim2.new(0, 62, 0.5, -14)
groceryDropdownBtn.AutoButtonColor = true
groceryDropdownBtn.Parent = groceryHeader

local gDropCorner = Instance.new("UICorner")
gDropCorner.CornerRadius = UDim.new(0, 8)
gDropCorner.Parent = groceryDropdownBtn

local gDropStroke = Instance.new("UIStroke")
gDropStroke.Color = Color3.fromRGB(255, 255, 255)
gDropStroke.Transparency = 0.88
gDropStroke.Thickness = 1
gDropStroke.Parent = groceryDropdownBtn

-- Select All Button (Liquid Glass Pill)
local selectAllBtn = Instance.new("TextButton")
selectAllBtn.Name = "SelectAllBtn"
selectAllBtn.Text = "Select All"
selectAllBtn.Font = Enum.Font.GothamBold
selectAllBtn.TextSize = 11
selectAllBtn.TextColor3 = Color3.fromRGB(230, 235, 250)
selectAllBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
selectAllBtn.BackgroundTransparency = 0.91
selectAllBtn.Size = UDim2.new(0, 66, 0, 28)
selectAllBtn.Position = UDim2.new(0, 196, 0.5, -14)
selectAllBtn.AutoButtonColor = true
selectAllBtn.Parent = groceryHeader

local selCorner = Instance.new("UICorner")
selCorner.CornerRadius = UDim.new(0, 8)
selCorner.Parent = selectAllBtn

local selStroke = Instance.new("UIStroke")
selStroke.Color = Color3.fromRGB(255, 255, 255)
selStroke.Transparency = 0.88
selStroke.Thickness = 1
selStroke.Parent = selectAllBtn

-- Grocery Threshold Cycler Button (Liquid Glass Pill: < 10%, < 25%, < 50%, < 75%)
local groceryThresholdBtn = Instance.new("TextButton")
groceryThresholdBtn.Name = "GroceryThresholdBtn"
groceryThresholdBtn.Text = "< " .. tostring(Config.GroceryThreshold or 25) .. "%"
groceryThresholdBtn.Font = Enum.Font.GothamBold
groceryThresholdBtn.TextSize = 11
groceryThresholdBtn.TextColor3 = Color3.fromRGB(255, 214, 10) -- Warm Apple Gold
groceryThresholdBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
groceryThresholdBtn.BackgroundTransparency = 0.92
groceryThresholdBtn.Size = UDim2.new(0, 68, 0, 28)
groceryThresholdBtn.Position = UDim2.new(0, 266, 0.5, -14)
groceryThresholdBtn.AutoButtonColor = true
groceryThresholdBtn.Parent = groceryHeader

local gThreshCorner = Instance.new("UICorner")
gThreshCorner.CornerRadius = UDim.new(0, 8)
gThreshCorner.Parent = groceryThresholdBtn

local gThreshStroke = Instance.new("UIStroke")
gThreshStroke.Color = Color3.fromRGB(255, 214, 10)
gThreshStroke.Transparency = 0.72
gThreshStroke.Thickness = 1
gThreshStroke.Parent = groceryThresholdBtn

local THRESHOLD_LIST = { 10, 25, 50, 75 }
groceryThresholdBtn.MouseButton1Click:Connect(function()
    local cur = Config.GroceryThreshold or 25
    local nextVal = 25
    for i, val in ipairs(THRESHOLD_LIST) do
        if val == cur then
            nextVal = THRESHOLD_LIST[(i % #THRESHOLD_LIST) + 1]
            break
        end
    end
    Config.GroceryThreshold = nextVal
    groceryThresholdBtn.Text = "< " .. tostring(nextVal) .. "%"
    saveWebhookConfig()
    setActivity("Grocery Auto Buy when stock < " .. tostring(nextVal) .. "%", Color3.fromRGB(255, 214, 10))
    if syncMainGroceryThresholdUI then syncMainGroceryThresholdUI(nextVal) end
end)

syncShopGroceryThresholdUI = function(num)
    if groceryThresholdBtn then
        groceryThresholdBtn.Text = "< " .. tostring(num) .. "%"
    end
end

-- Grocery Auto Buy Toggle Button (Liquid Glass Pill)
local groceryAutoBuyBtn = Instance.new("TextButton")
groceryAutoBuyBtn.Name = "GroceryAutoBuyBtn"
groceryAutoBuyBtn.Text = Config.GroceryAutoBuy and "Auto: ON" or "Auto: OFF"
groceryAutoBuyBtn.Font = Enum.Font.GothamBold
groceryAutoBuyBtn.TextSize = 11
groceryAutoBuyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
groceryAutoBuyBtn.BackgroundColor3 = Config.GroceryAutoBuy and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 255, 255)
groceryAutoBuyBtn.BackgroundTransparency = Config.GroceryAutoBuy and 0.14 or 0.92
groceryAutoBuyBtn.Size = UDim2.new(0, 84, 0, 28)
groceryAutoBuyBtn.Position = UDim2.new(1, -84, 0.5, -14)
groceryAutoBuyBtn.AutoButtonColor = true
groceryAutoBuyBtn.Parent = groceryHeader

local gAutoCorner = Instance.new("UICorner")
gAutoCorner.CornerRadius = UDim.new(0, 8)
gAutoCorner.Parent = groceryAutoBuyBtn

local gAutoStroke = Instance.new("UIStroke")
gAutoStroke.Color = Config.GroceryAutoBuy and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(255, 255, 255)
gAutoStroke.Transparency = Config.GroceryAutoBuy and 0.45 or 0.88
gAutoStroke.Thickness = 1
gAutoStroke.Parent = groceryAutoBuyBtn

local function updateGroceryAutoBuyVisual()
    local isOn = Config.GroceryAutoBuy == true
    groceryAutoBuyBtn.Text = isOn and "Auto: ON" or "Auto: OFF"
    TweenService:Create(groceryAutoBuyBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = isOn and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = isOn and 0.14 or 0.92
    }):Play()
    TweenService:Create(gAutoStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Color = isOn and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(255, 255, 255),
        Transparency = isOn and 0.45 or 0.88
    }):Play()
end

groceryAutoBuyBtn.MouseButton1Click:Connect(function()
    Config.GroceryAutoBuy = not Config.GroceryAutoBuy
    updateGroceryAutoBuyVisual()
    saveWebhookConfig()
    setActivity(Config.GroceryAutoBuy and ("Auto Buy Grocery ON (< " .. (Config.GroceryThreshold or 25) .. "%)") or "Auto Buy Grocery OFF", Color3.fromRGB(52, 199, 89))
    if syncMainGroceryAutoBuyUI then syncMainGroceryAutoBuyUI(Config.GroceryAutoBuy) end
end)

syncShopGroceryAutoBuyUI = updateGroceryAutoBuyVisual

-- 2. MIDDLE SCROLLING GRID FOR GROCERY ITEMS
local groceryGridScroll = Instance.new("ScrollingFrame")
groceryGridScroll.Name = "GroceryGridScroll"
groceryGridScroll.Size = UDim2.new(1, -20, 1, -94)
groceryGridScroll.Position = UDim2.new(0, 10, 0, 48)
groceryGridScroll.BackgroundTransparency = 1
groceryGridScroll.BorderSizePixel = 0
groceryGridScroll.ScrollBarThickness = 4
groceryGridScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 110, 140)
groceryGridScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
groceryGridScroll.Parent = shopMainCard

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.5, -6, 0, 36)
gridLayout.CellPadding = UDim2.new(0, 8, 0, 6)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = groceryGridScroll

local groceryItemRows = {}
local groceryCategories = {
    { Id = "All", Label = "Category: All  ▼", MenuText = "All Categories" },
    { Id = "Fridge", Label = "Fridge  ▼", MenuText = "Fridge" },
    { Id = "Softdrinks", Label = "Drinks  ▼", MenuText = "Drinks" },
    { Id = "Rice", Label = "Rice  ▼", MenuText = "Rice" },
}

-- Floating Popup Menu for Grocery Category Selection (Liquid Glass Sheet)
local groceryDropdownPopup = Instance.new("Frame")
groceryDropdownPopup.Name = "GroceryDropdownPopup"
groceryDropdownPopup.Size = UDim2.new(0, 145, 0, #groceryCategories * 28 + 8)
groceryDropdownPopup.Position = UDim2.new(0, 62, 0, 42)
groceryDropdownPopup.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
groceryDropdownPopup.BackgroundTransparency = 0.12
groceryDropdownPopup.BorderSizePixel = 0
groceryDropdownPopup.ZIndex = 30
groceryDropdownPopup.Visible = false
groceryDropdownPopup.Parent = shopMainCard

local gPopupCorner = Instance.new("UICorner")
gPopupCorner.CornerRadius = UDim.new(0, 10)
gPopupCorner.Parent = groceryDropdownPopup

applyGlassStroke(groceryDropdownPopup, 1.2, 0.35, 0.8)

local gPopupLayout = Instance.new("UIListLayout")
gPopupLayout.FillDirection = Enum.FillDirection.Vertical
gPopupLayout.Padding = UDim.new(0, 2)
gPopupLayout.Parent = groceryDropdownPopup

local gPopupPadding = Instance.new("UIPadding")
gPopupPadding.PaddingTop = UDim.new(0, 4)
gPopupPadding.PaddingBottom = UDim.new(0, 4)
gPopupPadding.PaddingLeft = UDim.new(0, 4)
gPopupPadding.PaddingRight = UDim.new(0, 4)
gPopupPadding.Parent = groceryDropdownPopup

local function renderGroceryGrid()
    for _, obj in pairs(groceryItemRows) do
        obj.Frame:Destroy()
    end
    table.clear(groceryItemRows)

    local sortedList = {}
    for key, data in pairs(IngredientsConfig) do
        if Config.GroceryFilter == "All" or data.Category == Config.GroceryFilter then
            table.insert(sortedList, { Key = key, Data = data })
        end
    end

    table.sort(sortedList, function(a, b)
        local nameA = (a.Data.Name or a.Key):lower()
        local nameB = (b.Data.Name or b.Key):lower()
        return nameA < nameB
    end)

    for i, item in ipairs(sortedList) do
        local key = item.Key
        local data = item.Data
        local current, maxStock, pct = getStockInfo(key, data)
        local cost = data.Cost or data.Price or 0

        local rowBtn = Instance.new("TextButton")
        rowBtn.Name = "Item_" .. key
        rowBtn.Text = ""
        rowBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        rowBtn.BackgroundTransparency = 0.94
        rowBtn.BorderSizePixel = 0
        rowBtn.AutoButtonColor = false
        rowBtn.LayoutOrder = i
        rowBtn.Parent = groceryGridScroll

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = rowBtn

        local rStroke = Instance.new("UIStroke")
        rStroke.Thickness = 1
        rStroke.Color = Color3.fromRGB(255, 255, 255)
        rStroke.Transparency = 0.9
        rStroke.Parent = rowBtn

        rowBtn.MouseEnter:Connect(function()
            TweenService:Create(rowBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.88 }):Play()
        end)
        rowBtn.MouseLeave:Connect(function()
            TweenService:Create(rowBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.94 }):Play()
        end)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.Text = data.Name or key
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 11
        nameLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Size = UDim2.new(1, -106, 1, 0)
        nameLabel.Position = UDim2.new(0, 8, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Parent = rowBtn

        local priceLabel = Instance.new("TextLabel")
        priceLabel.Name = "Price"
        priceLabel.Text = cost > 0 and ("₱" .. formatNumber(cost)) or "Free"
        priceLabel.Font = Enum.Font.GothamBold
        priceLabel.TextSize = 11
        priceLabel.TextColor3 = Color3.fromRGB(255, 214, 10) -- Apple System Gold
        priceLabel.TextXAlignment = Enum.TextXAlignment.Right
        priceLabel.Size = UDim2.new(0, 50, 1, 0)
        priceLabel.Position = UDim2.new(1, -96, 0, 0)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Parent = rowBtn

        local pctLabel = Instance.new("TextLabel")
        pctLabel.Name = "Pct"
        pctLabel.Text = tostring(pct) .. "%"
        pctLabel.Font = Enum.Font.GothamBold
        pctLabel.TextSize = 11
        pctLabel.TextColor3 = getPctColor(pct)
        pctLabel.TextXAlignment = Enum.TextXAlignment.Right
        pctLabel.Size = UDim2.new(0, 38, 1, 0)
        pctLabel.Position = UDim2.new(1, -44, 0, 0)
        pctLabel.BackgroundTransparency = 1
        pctLabel.Parent = rowBtn

        rowBtn.MouseButton1Click:Connect(function()
            if BuyIngredient then
                task.spawn(function()
                    pcall(function()
                        BuyIngredient:InvokeServer(key, 1, "Cash")
                    end)
                    local cur, mx, p = getStockInfo(key, data)
                    pctLabel.Text = tostring(p) .. "%"
                    pctLabel.TextColor3 = getPctColor(p)
                    setActivity("Bought 1x " .. (data.Name or key) .. (cost > 0 and (" (₱" .. formatNumber(cost) .. ")") or ""), Color3.fromRGB(52, 199, 89))
                end)
            end
        end)

        groceryItemRows[key] = { Frame = rowBtn, PctLabel = pctLabel, PriceLabel = priceLabel, Key = key, Data = data }
    end

    local rowsCount = math.ceil(#sortedList / 2)
    groceryGridScroll.CanvasSize = UDim2.new(0, 0, 0, rowsCount * 42 + 10)
end

for _, cat in ipairs(groceryCategories) do
    local itemBtn = Instance.new("TextButton")
    itemBtn.Name = "Cat_" .. cat.Id
    itemBtn.Text = cat.MenuText
    itemBtn.Font = Enum.Font.GothamBold
    itemBtn.TextSize = 11
    itemBtn.TextColor3 = Color3.fromRGB(230, 235, 250)
    itemBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    itemBtn.BackgroundTransparency = 0.94
    itemBtn.Size = UDim2.new(1, 0, 0, 26)
    itemBtn.AutoButtonColor = true
    itemBtn.ZIndex = 31
    itemBtn.Parent = groceryDropdownPopup

    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 6)
    itemCorner.Parent = itemBtn

    itemBtn.MouseButton1Click:Connect(function()
        Config.GroceryFilter = cat.Id
        groceryDropdownBtn.Text = cat.Label
        groceryDropdownPopup.Visible = false
        renderGroceryGrid()
    end)
end

-- Grocery Dropdown Toggle
groceryDropdownBtn.MouseButton1Click:Connect(function()
    groceryDropdownPopup.Visible = not groceryDropdownPopup.Visible
end)

-- Select All: buys needed quota for all grocery items
selectAllBtn.MouseButton1Click:Connect(function()
    if BuyIngredient then
        setActivity("Restocking All Ingredients...", Color3.fromRGB(59, 130, 246))
        task.spawn(function()
            for key, data in pairs(IngredientsConfig) do
                local current, maxStock, pct = getStockInfo(key, data)
                if pct < 100 then
                    local needed = maxStock - current
                    pcall(function()
                        BuyIngredient:InvokeServer(key, math.min(needed, 10), "Cash")
                    end)
                    task.wait(0.06)
                end
            end
            renderGroceryGrid()
            setActivity("All Grocery Items Restocked!", Color3.fromRGB(38, 140, 78))
        end)
    end
end)

-- Real-time stock watcher loop
spawnLoop(1.5, function()
    for key, item in pairs(groceryItemRows) do
        local cur, mx, p = getStockInfo(key, item.Data)
        item.PctLabel.Text = tostring(p) .. "%"
        item.PctLabel.TextColor3 = getPctColor(p)
    end
end)

    renderGroceryGrid()
    renderGroceryGridShared = renderGroceryGrid
end

local function buildShopFurnitureSection()
    -- 3. BOTTOM FOOTER: SHOP
    local shopFooter = Instance.new("Frame")
shopFooter.Name = "ShopFooter"
shopFooter.Size = UDim2.new(1, -20, 0, 36)
shopFooter.Position = UDim2.new(0, 10, 1, -42)
shopFooter.BackgroundTransparency = 1
shopFooter.Parent = shopMainCard

local shopLabel = Instance.new("TextLabel")
shopLabel.Name = "ShopLabel"
shopLabel.Text = "SHOP"
shopLabel.Font = Enum.Font.GothamBold
shopLabel.TextSize = 12
shopLabel.TextColor3 = Color3.fromRGB(165, 180, 205)
shopLabel.TextXAlignment = Enum.TextXAlignment.Left
shopLabel.Size = UDim2.new(0, 42, 1, 0)
shopLabel.BackgroundTransparency = 1
shopLabel.Parent = shopFooter

-- Dropdown Button for Shop (Opens In-Stock Items Popup - Liquid Glass Pill)
local shopDropdownBtn = Instance.new("TextButton")
shopDropdownBtn.Name = "ShopDropdownBtn"
shopDropdownBtn.Text = "Select Shop Item (Stock)  ▼"
shopDropdownBtn.Font = Enum.Font.GothamBold
shopDropdownBtn.TextSize = 11
shopDropdownBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
shopDropdownBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
shopDropdownBtn.BackgroundTransparency = 0.93
shopDropdownBtn.Size = UDim2.new(0, 160, 0, 28)
shopDropdownBtn.Position = UDim2.new(0, 46, 0.5, -14)
shopDropdownBtn.AutoButtonColor = true
shopDropdownBtn.Parent = shopFooter

local sDropCorner = Instance.new("UICorner")
sDropCorner.CornerRadius = UDim.new(0, 8)
sDropCorner.Parent = shopDropdownBtn

local sDropStroke = Instance.new("UIStroke")
sDropStroke.Color = Color3.fromRGB(255, 255, 255)
sDropStroke.Transparency = 0.88
sDropStroke.Thickness = 1
sDropStroke.Parent = shopDropdownBtn

-- Refresh Button (Apple System Blue Glass Pill)
local refreshBtn = Instance.new("TextButton")
refreshBtn.Name = "RefreshBtn"
refreshBtn.Text = "Refresh"
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.TextSize = 11
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
refreshBtn.BackgroundTransparency = 0.15
refreshBtn.Size = UDim2.new(0, 58, 0, 28)
refreshBtn.Position = UDim2.new(0, 210, 0.5, -14)
refreshBtn.AutoButtonColor = true
refreshBtn.Parent = shopFooter

local refCorner = Instance.new("UICorner")
refCorner.CornerRadius = UDim.new(0, 8)
refCorner.Parent = refreshBtn

local refStroke = Instance.new("UIStroke")
refStroke.Color = Color3.fromRGB(255, 255, 255)
refStroke.Transparency = 0.6
refStroke.Thickness = 1
refStroke.Parent = refreshBtn

-- Buy Stock Button (Apple System Green Glass Pill)
local buyStockBtn = Instance.new("TextButton")
buyStockBtn.Name = "BuyStockBtn"
buyStockBtn.Text = "Buy Stock"
buyStockBtn.Font = Enum.Font.GothamBold
buyStockBtn.TextSize = 11
buyStockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
buyStockBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
buyStockBtn.BackgroundTransparency = 0.15
buyStockBtn.Size = UDim2.new(0, 74, 0, 28)
buyStockBtn.Position = UDim2.new(0, 272, 0.5, -14)
buyStockBtn.AutoButtonColor = true
buyStockBtn.Parent = shopFooter

local buyStockCorner = Instance.new("UICorner")
buyStockCorner.CornerRadius = UDim.new(0, 8)
buyStockCorner.Parent = buyStockBtn

local buyStockStroke = Instance.new("UIStroke")
buyStockStroke.Color = Color3.fromRGB(255, 255, 255)
buyStockStroke.Transparency = 0.55
buyStockStroke.Thickness = 1
buyStockStroke.Parent = buyStockBtn

-- Shop Auto Buy Toggle Button (Liquid Glass Pill)
local shopAutoBuyBtn = Instance.new("TextButton")
shopAutoBuyBtn.Name = "ShopAutoBuyBtn"
shopAutoBuyBtn.Text = Config.ShopAutoBuy and "Auto Buy: ON" or "Auto Buy: OFF"
shopAutoBuyBtn.Font = Enum.Font.GothamBold
shopAutoBuyBtn.TextSize = 11
shopAutoBuyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shopAutoBuyBtn.BackgroundColor3 = Config.ShopAutoBuy and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 255, 255)
shopAutoBuyBtn.BackgroundTransparency = Config.ShopAutoBuy and 0.15 or 0.92
shopAutoBuyBtn.Size = UDim2.new(0, 74, 0, 28)
shopAutoBuyBtn.Position = UDim2.new(1, -74, 0.5, -14)
shopAutoBuyBtn.AutoButtonColor = true
shopAutoBuyBtn.Parent = shopFooter

local sAutoCorner = Instance.new("UICorner")
sAutoCorner.CornerRadius = UDim.new(0, 8)
sAutoCorner.Parent = shopAutoBuyBtn

local sAutoStroke = Instance.new("UIStroke")
sAutoStroke.Color = Config.ShopAutoBuy and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(255, 255, 255)
sAutoStroke.Transparency = Config.ShopAutoBuy and 0.45 or 0.88
sAutoStroke.Thickness = 1
sAutoStroke.Parent = shopAutoBuyBtn

shopAutoBuyBtn.MouseButton1Click:Connect(function()
    Config.ShopAutoBuy = not Config.ShopAutoBuy
    shopAutoBuyBtn.Text = Config.ShopAutoBuy and "Auto Buy: ON" or "Auto Buy: OFF"
    TweenService:Create(shopAutoBuyBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = Config.ShopAutoBuy and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = Config.ShopAutoBuy and 0.15 or 0.92
    }):Play()
    TweenService:Create(sAutoStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Color = Config.ShopAutoBuy and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(255, 255, 255),
        Transparency = Config.ShopAutoBuy and 0.45 or 0.88
    }):Play()
end)

-- In-Stock Items Popup Frame (Apple Liquid Glass Modal Sheet)
local shopDropdownPopup = Instance.new("Frame")
shopDropdownPopup.Name = "ShopDropdownPopup"
shopDropdownPopup.Size = UDim2.new(0, 360, 0, 260)
shopDropdownPopup.Position = UDim2.new(0, 46, 1, -304)
shopDropdownPopup.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
shopDropdownPopup.BackgroundTransparency = 0.12
shopDropdownPopup.BorderSizePixel = 0
shopDropdownPopup.ZIndex = 40
shopDropdownPopup.Visible = false
shopDropdownPopup.Parent = shopMainCard

local sPopupCorner = Instance.new("UICorner")
sPopupCorner.CornerRadius = UDim.new(0, 14)
sPopupCorner.Parent = shopDropdownPopup

applyGlassStroke(shopDropdownPopup, 1.4, 0.22, 0.82)

-- Header in Popup
local popHeader = Instance.new("Frame")
popHeader.Name = "PopHeader"
popHeader.Size = UDim2.new(1, 0, 0, 36)
popHeader.BackgroundColor3 = Color3.fromRGB(24, 30, 44)
popHeader.BackgroundTransparency = 0.35
popHeader.BorderSizePixel = 0
popHeader.ZIndex = 41
popHeader.Parent = shopDropdownPopup

local popHeaderCorner = Instance.new("UICorner")
popHeaderCorner.CornerRadius = UDim.new(0, 14)
popHeaderCorner.Parent = popHeader

local popHeaderLabel = Instance.new("TextLabel")
popHeaderLabel.Text = "Items In Stock"
popHeaderLabel.Font = Enum.Font.GothamBold
popHeaderLabel.TextSize = 12
popHeaderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
popHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
popHeaderLabel.Size = UDim2.new(1, -125, 1, 0)
popHeaderLabel.Position = UDim2.new(0, 12, 0, 0)
popHeaderLabel.BackgroundTransparency = 1
popHeaderLabel.ZIndex = 42
popHeaderLabel.Parent = popHeader

local popBuyAllBtn = Instance.new("TextButton")
popBuyAllBtn.Name = "PopBuyAllBtn"
popBuyAllBtn.Text = "Buy All Stock"
popBuyAllBtn.Font = Enum.Font.GothamBold
popBuyAllBtn.TextSize = 11
popBuyAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
popBuyAllBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
popBuyAllBtn.BackgroundTransparency = 0.15
popBuyAllBtn.Size = UDim2.new(0, 105, 0, 24)
popBuyAllBtn.Position = UDim2.new(1, -112, 0.5, -12)
popBuyAllBtn.AutoButtonColor = true
popBuyAllBtn.ZIndex = 42
popBuyAllBtn.Parent = popHeader

local pbaCorner = Instance.new("UICorner")
pbaCorner.CornerRadius = UDim.new(0, 8)
pbaCorner.Parent = popBuyAllBtn

local pbaStroke = Instance.new("UIStroke")
pbaStroke.Thickness = 1
pbaStroke.Color = Color3.fromRGB(255, 255, 255)
pbaStroke.Transparency = 0.55
pbaStroke.Parent = popBuyAllBtn

-- Scrolling List for In-Stock Items
local shopStockScroll = Instance.new("ScrollingFrame")
shopStockScroll.Name = "ShopStockScroll"
shopStockScroll.Size = UDim2.new(1, -16, 1, -46)
shopStockScroll.Position = UDim2.new(0, 8, 0, 40)
shopStockScroll.BackgroundTransparency = 1
shopStockScroll.BorderSizePixel = 0
shopStockScroll.ScrollBarThickness = 4
shopStockScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 110, 140)
shopStockScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
shopStockScroll.ZIndex = 41
shopStockScroll.Parent = shopDropdownPopup

local shopStockLayout = Instance.new("UIListLayout")
shopStockLayout.FillDirection = Enum.FillDirection.Vertical
shopStockLayout.Padding = UDim.new(0, 4)
shopStockLayout.Parent = shopStockScroll

local function renderShopStockPopup()
    for _, child in ipairs(shopStockScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local loadLbl = Instance.new("TextLabel")
    loadLbl.Text = "Fetching available stock..."
    loadLbl.Font = Enum.Font.GothamMedium
    loadLbl.TextSize = 11
    loadLbl.TextColor3 = Color3.fromRGB(56, 189, 248)
    loadLbl.BackgroundTransparency = 1
    loadLbl.Size = UDim2.new(1, 0, 0, 30)
    loadLbl.ZIndex = 42
    loadLbl.Parent = shopStockScroll

    task.spawn(function()
        local ok, res = pcall(function() return GetShopInfo:InvokeServer() end)
        if not ok or type(res) ~= "table" then
            loadLbl.Text = "Failed to load shop stock."
            loadLbl.TextColor3 = Color3.fromRGB(239, 68, 68)
            return
        end

        loadLbl:Destroy()

        local stocked = {}
        local totalPrice = 0
        for catName, items in pairs(res) do
            if Config.ShopFilter == "All" or catName == Config.ShopFilter then
                if type(items) == "table" then
                    for _, itm in ipairs(items) do
                        if itm.Stock and itm.Stock > 0 then
                            local price, friendlyName = getItemPriceAndName(itm.SystemType, itm.Category or catName, itm.Key)
                            totalPrice = totalPrice + (price * itm.Stock)
                            table.insert(stocked, {
                                Key = itm.Key,
                                Category = itm.Category or catName,
                                Stock = itm.Stock,
                                SystemType = itm.SystemType,
                                Price = price,
                                FriendlyName = friendlyName,
                            })
                        end
                    end
                end
            end
        end

        table.sort(stocked, function(a, b)
            return a.FriendlyName:lower() < b.FriendlyName:lower()
        end)

        popHeaderLabel.Text = "In Stock (" .. #stocked .. " items)"
        popBuyAllBtn.Text = "Buy All Stock"

        if #stocked == 0 then
            local emptyLbl = Instance.new("TextLabel")
            emptyLbl.Text = "No items currently in stock (" .. Config.ShopFilter .. ")"
            emptyLbl.Font = Enum.Font.GothamMedium
            emptyLbl.TextSize = 11
            emptyLbl.TextColor3 = Color3.fromRGB(160, 175, 200)
            emptyLbl.BackgroundTransparency = 1
            emptyLbl.Size = UDim2.new(1, 0, 0, 40)
            emptyLbl.ZIndex = 42
            emptyLbl.Parent = shopStockScroll
            shopStockScroll.CanvasSize = UDim2.new(0, 0, 0, 40)
            return
        end

        for _, itm in ipairs(stocked) do
            local row = Instance.new("Frame")
            row.Name = "StockItem_" .. itm.Key
            row.Size = UDim2.new(1, -6, 0, 32)
            row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            row.BackgroundTransparency = 0.94
            row.BorderSizePixel = 0
            row.ZIndex = 42
            row.Parent = shopStockScroll

            local rCorner = Instance.new("UICorner")
            rCorner.CornerRadius = UDim.new(0, 8)
            rCorner.Parent = row

            local rStroke = Instance.new("UIStroke")
            rStroke.Thickness = 1
            rStroke.Color = Color3.fromRGB(255, 255, 255)
            rStroke.Transparency = 0.9
            rStroke.Parent = row

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Text = itm.FriendlyName .. " (" .. itm.Category .. ")"
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 11
            nameLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.Size = UDim2.new(1, -195, 1, 0)
            nameLbl.Position = UDim2.new(0, 8, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.ZIndex = 43
            nameLbl.Parent = row

            local priceLbl = Instance.new("TextLabel")
            priceLbl.Name = "Price"
            priceLbl.Text = (itm.Price and itm.Price > 0) and ("₱" .. formatNumber(itm.Price)) or "Free"
            priceLbl.Font = Enum.Font.GothamBold
            priceLbl.TextSize = 11
            priceLbl.TextColor3 = Color3.fromRGB(255, 214, 10) -- Apple Gold
            priceLbl.TextXAlignment = Enum.TextXAlignment.Right
            priceLbl.Size = UDim2.new(0, 80, 1, 0)
            priceLbl.Position = UDim2.new(1, -188, 0, 0)
            priceLbl.BackgroundTransparency = 1
            priceLbl.ZIndex = 43
            priceLbl.Parent = row

            local stckLbl = Instance.new("TextLabel")
            stckLbl.Name = "Stock"
            stckLbl.Text = "x" .. itm.Stock
            stckLbl.Font = Enum.Font.GothamBold
            stckLbl.TextSize = 11
            stckLbl.TextColor3 = Color3.fromRGB(100, 210, 255) -- Apple System Cyan
            stckLbl.TextXAlignment = Enum.TextXAlignment.Center
            stckLbl.Size = UDim2.new(0, 28, 1, 0)
            stckLbl.Position = UDim2.new(1, -95, 0, 0)
            stckLbl.BackgroundTransparency = 1
            stckLbl.ZIndex = 43
            stckLbl.Parent = row

            local bBtn = Instance.new("TextButton")
            bBtn.Name = "BuyBtn"
            bBtn.Text = "Buy"
            bBtn.Font = Enum.Font.GothamBold
            bBtn.TextSize = 11
            bBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            bBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
            bBtn.BackgroundTransparency = 0.15
            bBtn.Size = UDim2.new(0, 50, 0, 22)
            bBtn.Position = UDim2.new(1, -56, 0.5, -11)
            bBtn.AutoButtonColor = true
            bBtn.ZIndex = 43
            bBtn.Parent = row

            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 8)
            bCorner.Parent = bBtn

            local bStroke = Instance.new("UIStroke")
            bStroke.Thickness = 1
            bStroke.Color = Color3.fromRGB(255, 255, 255)
            bStroke.Transparency = 0.55
            bStroke.Parent = bBtn

            bBtn.MouseButton1Click:Connect(function()
                if BuyFurniture then
                    task.spawn(function()
                        local bOk, bRes = pcall(function()
                            return BuyFurniture:InvokeServer(itm.SystemType, itm.Category, itm.Key)
                        end)
                        if bOk and bRes then
                            setActivity("Bought 1x " .. itm.FriendlyName .. " (" .. (itm.Price > 0 and ("₱" .. formatNumber(itm.Price)) or "Free") .. ")", Color3.fromRGB(52, 199, 89))
                            itm.Stock = itm.Stock - 1
                            if itm.Stock <= 0 then
                                row:Destroy()
                            else
                                stckLbl.Text = "x" .. itm.Stock
                            end
                        else
                            setActivity("Buy failed: " .. itm.FriendlyName, Color3.fromRGB(255, 69, 58))
                        end
                    end)
                end
            end)
        end

        shopStockScroll.CanvasSize = UDim2.new(0, 0, 0, #stocked * 36 + 8)
    end)
end

-- Function to buy all available stock
local isBuyingAllStock = false
local function buyAllAvailableStock()
    if isBuyingAllStock or not BuyFurniture or not GetShopInfo then return end
    isBuyingAllStock = true

    setActivity("Scanning Shop Stock...", Color3.fromRGB(59, 130, 246))
    task.spawn(function()
        local ok, res = pcall(function() return GetShopInfo:InvokeServer() end)
        if not ok or type(res) ~= "table" then
            setActivity("Failed to read shop info", Color3.fromRGB(239, 68, 68))
            isBuyingAllStock = false
            return
        end

        local boughtCount = 0
        for catName, items in pairs(res) do
            if Config.ShopFilter == "All" or catName == Config.ShopFilter then
                if type(items) == "table" then
                    for _, itm in ipairs(items) do
                        if itm.Stock and itm.Stock > 0 and itm.Key and itm.Category and itm.SystemType then
                            for s = 1, itm.Stock do
                                local bOk, bRes = pcall(function()
                                    return BuyFurniture:InvokeServer(itm.SystemType, itm.Category, itm.Key)
                                end)
                                if bOk and bRes then
                                    boughtCount = boughtCount + 1
                                    setActivity("Bought " .. itm.Key .. " (" .. boughtCount .. ")", Color3.fromRGB(34, 197, 94))
                                end
                                task.wait(0.06)
                            end
                        end
                    end
                end
            end
        end

        if boughtCount > 0 then
            setActivity("Bought " .. boughtCount .. " items in stock!", Color3.fromRGB(34, 197, 94))
        else
            setActivity("No stock available (" .. Config.ShopFilter .. ")", Color3.fromRGB(234, 179, 8))
        end

        if shopDropdownPopup.Visible then
            renderShopStockPopup()
        end
        isBuyingAllStock = false
    end)
end

-- Connect Buttons
buyStockBtn.MouseButton1Click:Connect(buyAllAvailableStock)
popBuyAllBtn.MouseButton1Click:Connect(buyAllAvailableStock)

shopDropdownBtn.MouseButton1Click:Connect(function()
    shopDropdownPopup.Visible = not shopDropdownPopup.Visible
    if shopDropdownPopup.Visible then
        task.spawn(renderShopStockPopup)
    end
end)

refreshBtn.MouseButton1Click:Connect(function()
    task.spawn(function()
        if GetShopInfo then
            pcall(function() GetShopInfo:InvokeServer() end)
        end
        if renderGroceryGridShared then
            renderGroceryGridShared()
        end
        if shopDropdownPopup.Visible then
            renderShopStockPopup()
        end
        setActivity("Shop & Grocery Refreshed!", Color3.fromRGB(59, 130, 246))
    end)
end)
end

    buildGrocerySection()
    buildShopFurnitureSection()
end

--------------------------------------------------------------------------------
-- WORKERS TAB (Gacha Roller & Staff Management)
--------------------------------------------------------------------------------
do
    local workersColumnsLayout = Instance.new("UIListLayout")
    workersColumnsLayout.FillDirection = Enum.FillDirection.Horizontal
    workersColumnsLayout.Padding = UDim.new(0, 10)
    workersColumnsLayout.Parent = workersPage

-- 1. Left Card: Staff & Gacha Control
local workerCtrlRows = createCard("Gacha & Staff Controls", workersPage)

-- Live Staff Status Badge Row
local staffStatusRow = Instance.new("Frame")
staffStatusRow.Name = "StaffStatusRow"
staffStatusRow.Size = UDim2.new(1, 0, 0, 50)
staffStatusRow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
staffStatusRow.BackgroundTransparency = 0.94
staffStatusRow.BorderSizePixel = 0
staffStatusRow.Parent = workerCtrlRows

local ssCorner = Instance.new("UICorner")
ssCorner.CornerRadius = UDim.new(0, 8)
ssCorner.Parent = staffStatusRow

local ssStroke = Instance.new("UIStroke")
ssStroke.Thickness = 1
ssStroke.Color = Color3.fromRGB(255, 255, 255)
ssStroke.Transparency = 0.9
ssStroke.Parent = staffStatusRow

local staffStatusLabel = Instance.new("TextLabel")
staffStatusLabel.Name = "StaffStatusLabel"
staffStatusLabel.Text = "Staff: Assigner (Checking...) | Dishwasher (Checking...)"
staffStatusLabel.Font = Enum.Font.GothamMedium
staffStatusLabel.TextSize = 11
staffStatusLabel.TextColor3 = Color3.fromRGB(200, 215, 235)
staffStatusLabel.Size = UDim2.new(1, -16, 1, 0)
staffStatusLabel.Position = UDim2.new(0, 8, 0, 0)
staffStatusLabel.TextWrapped = true
staffStatusLabel.BackgroundTransparency = 1
staffStatusLabel.Parent = staffStatusRow

local function updateStaffStatusDisplay()
    local hired = getHiredRoles()
    local aText = hired.Assigner and "<font color='#34C759'>Hired</font>" or "<font color='#FF453A'>None</font>"
    local dText = hired.Dishwasher and "<font color='#34C759'>Hired</font>" or "<font color='#FF453A'>None</font>"
    staffStatusLabel.RichText = true
    staffStatusLabel.Text = "Staff: Assigner: " .. aText .. " | Dishwasher: " .. dText .. " (" .. hired.WorkerCount .. " active)"
end
task.spawn(function()
    while Hub.Running do
        pcall(updateStaffStatusDisplay)
        task.wait(2)
    end
end)

createToggleRow("Auto Roll Gacha (₱100)", Config.WorkerAutoRoll, function(v)
    Config.WorkerAutoRoll = v
    setActivity(v and ("Auto Rolling for " .. Config.WorkerMinRarity .. "+") or "Auto Roll Stopped", Color3.fromRGB(168, 85, 247))
end, workerCtrlRows)

createValueCycleRow("Min Target Rarity", Config.WorkerMinRarity, { "Rare", "Epic", "Legendary", "Mythical", "Secret" }, function(v)
    Config.WorkerMinRarity = v
    setActivity("Worker Min Rarity: " .. v, Color3.fromRGB(168, 85, 247))
end, workerCtrlRows)

createValueCycleRow("Auto Assign Role", Config.WorkerTargetRole, { "Manual Pick", "Assigner", "Dishwasher", "Any" }, function(v)
    Config.WorkerTargetRole = v
    setActivity("Worker Role Assignment: " .. v, Color3.fromRGB(59, 130, 246))
end, workerCtrlRows)


local renderWorkerCandidates

createButtonRow("Roll Candidate Pool", "Roll (₱100)", Color3.fromRGB(168, 85, 247), function(btn)
    if RollWorkerRemote then
        btn.Text = "Rolling..."
        task.spawn(function()
            pcall(function() RollWorkerRemote:InvokeServer("Roll") end)
            task.wait(0.5)
            btn.Text = "Roll (₱100)"
            if renderWorkerCandidates then
                renderWorkerCandidates()
            end
        end)
    end
end, workerCtrlRows)

createButtonRow("Refresh Pool View", "Refresh", Color3.fromRGB(59, 130, 246), function(btn)
    if renderWorkerCandidates then
        renderWorkerCandidates()
    end
end, workerCtrlRows)

-- 2. Right Card: Waiting Candidates Pool
local workerPoolRows = createCard("Waiting Candidates Pool", workersPage)

renderWorkerCandidates = function()
    for _, ch in ipairs(workerPoolRows:GetChildren()) do
        if ch.Name:find("^Cand_") then
            ch:Destroy()
        end
    end

    if not GetWaitingWorkersRemote then return end
    local ok, waitRes = pcall(function() return GetWaitingWorkersRemote:InvokeServer() end)
    local candidates = (ok and type(waitRes) == "table" and (waitRes.w2 or waitRes)) or {}

    local count = 0
    for _, cand in pairs(candidates) do
        if type(cand) == "table" and cand.Name then
            count = count + 1
            local rarity = cand.Rarity or "Common"
            local rColor = RARITY_COLORS[rarity] or Color3.fromRGB(160, 160, 160)

            local cFrame = Instance.new("Frame")
            cFrame.Name = "Cand_" .. cand.Name
            cFrame.Size = UDim2.new(1, 0, 0, 78)
            cFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            cFrame.BackgroundTransparency = 0.94
            cFrame.BorderSizePixel = 0
            cFrame.Parent = workerPoolRows

            local cCorner = Instance.new("UICorner")
            cCorner.CornerRadius = UDim.new(0, 8)
            cCorner.Parent = cFrame

            local cStroke = Instance.new("UIStroke")
            cStroke.Thickness = 1.2
            cStroke.Color = rColor
            cStroke.Transparency = 0.55
            cStroke.Parent = cFrame

            -- Candidate Name
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Text = tostring(cand.Template or cand.Name)
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 13
            nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Size = UDim2.new(0.55, 0, 0, 20)
            nameLbl.Position = UDim2.new(0, 10, 0, 6)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Parent = cFrame

            -- Rarity Badge
            local rarLbl = Instance.new("TextLabel")
            rarLbl.Text = rarity:upper()
            rarLbl.Font = Enum.Font.GothamBold
            rarLbl.TextSize = 10
            rarLbl.TextColor3 = rColor
            rarLbl.TextXAlignment = Enum.TextXAlignment.Right
            rarLbl.Size = UDim2.new(0.4, -10, 0, 20)
            rarLbl.Position = UDim2.new(0.6, 0, 0, 6)
            rarLbl.BackgroundTransparency = 1
            rarLbl.Parent = cFrame

            -- Stats string
            local statLbl = Instance.new("TextLabel")
            local spd = cand.Speed or 16
            local wage = cand.Wage or 0
            local sleep = cand.SleepChance or 0
            statLbl.Text = string.format("Speed: %s | Wage: ₱%s/d | Sleep: %s%%", tostring(spd), formatNumber(wage), tostring(sleep))
            statLbl.Font = Enum.Font.GothamMedium
            statLbl.TextSize = 10
            statLbl.TextColor3 = Color3.fromRGB(165, 180, 205)
            statLbl.TextXAlignment = Enum.TextXAlignment.Left
            statLbl.Size = UDim2.new(1, -20, 0, 16)
            statLbl.Position = UDim2.new(0, 10, 0, 26)
            statLbl.BackgroundTransparency = 1
            statLbl.Parent = cFrame

            -- Hire Assigner button
            local hireABtn = Instance.new("TextButton")
            hireABtn.Text = "Hire Assigner"
            hireABtn.Font = Enum.Font.GothamBold
            hireABtn.TextSize = 10
            hireABtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            hireABtn.BackgroundColor3 = Color3.fromRGB(14, 115, 235)
            hireABtn.Size = UDim2.new(0.47, -5, 0, 24)
            hireABtn.Position = UDim2.new(0, 10, 0, 46)
            hireABtn.AutoButtonColor = true
            hireABtn.Parent = cFrame

            local habCorner = Instance.new("UICorner")
            habCorner.CornerRadius = UDim.new(0, 6)
            habCorner.Parent = hireABtn

            local habStroke = Instance.new("UIStroke")
            habStroke.Thickness = 1
            habStroke.Color = Color3.fromRGB(255, 255, 255)
            habStroke.Transparency = 0.65
            habStroke.Parent = hireABtn

            hireABtn.MouseButton1Click:Connect(function()
                if HireWorkerRemote then
                    hireABtn.Text = "Hiring..."
                    task.spawn(function()
                        local hOk, hRes = pcall(function() return HireWorkerRemote:InvokeServer(cand.Name, "Assigner") end)
                        if hOk and hRes then
                            setActivity("Hired " .. tostring(cand.Template or cand.Name) .. " as Assigner!", Color3.fromRGB(52, 199, 89))
                            renderWorkerCandidates()
                        else
                            setActivity("Hire failed!", Color3.fromRGB(255, 69, 58))
                            hireABtn.Text = "Hire Assigner"
                        end
                    end)
                end
            end)

            -- Hire Dishwasher button
            local hireDBtn = Instance.new("TextButton")
            hireDBtn.Text = "Hire Dishwasher"
            hireDBtn.Font = Enum.Font.GothamBold
            hireDBtn.TextSize = 10
            hireDBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            hireDBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
            hireDBtn.Size = UDim2.new(0.47, -5, 0, 24)
            hireDBtn.Position = UDim2.new(0.53, 0, 0, 46)
            hireDBtn.AutoButtonColor = true
            hireDBtn.Parent = cFrame

            local hdbCorner = Instance.new("UICorner")
            hdbCorner.CornerRadius = UDim.new(0, 6)
            hdbCorner.Parent = hireDBtn

            local hdbStroke = Instance.new("UIStroke")
            hdbStroke.Thickness = 1
            hdbStroke.Color = Color3.fromRGB(255, 255, 255)
            hdbStroke.Transparency = 0.65
            hdbStroke.Parent = hireDBtn

            hireDBtn.MouseButton1Click:Connect(function()
                if HireWorkerRemote then
                    hireDBtn.Text = "Hiring..."
                    task.spawn(function()
                        local hOk, hRes = pcall(function() return HireWorkerRemote:InvokeServer(cand.Name, "Dishwasher") end)
                        if hOk and hRes then
                            setActivity("Hired " .. tostring(cand.Template or cand.Name) .. " as Dishwasher!", Color3.fromRGB(52, 199, 89))
                            renderWorkerCandidates()
                        else
                            setActivity("Hire failed!", Color3.fromRGB(255, 69, 58))
                            hireDBtn.Text = "Hire Dishwasher"
                        end
                    end)
                end
            end)
        end
    end

    if count == 0 then
        local emptyLbl = Instance.new("TextLabel")
        emptyLbl.Name = "Cand_Empty"
        emptyLbl.Text = "No candidates in waiting pool.\nClick 'Roll (₱100)' to recruit!"
        emptyLbl.Font = Enum.Font.GothamMedium
        emptyLbl.TextSize = 12
        emptyLbl.TextColor3 = Color3.fromRGB(150, 165, 190)
        emptyLbl.Size = UDim2.new(1, 0, 0, 60)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Parent = workerPoolRows
    end
end
task.spawn(renderWorkerCandidates)
end

--------------------------------------------------------------------------------
-- MERCHANT TAB (Travelling Merchant Auto-Buyer & Restock Sniper)
--------------------------------------------------------------------------------
do
    local merchantColumnsLayout = Instance.new("UIListLayout")
    merchantColumnsLayout.FillDirection = Enum.FillDirection.Horizontal
    merchantColumnsLayout.Padding = UDim.new(0, 10)
    merchantColumnsLayout.Parent = merchantPage

-- 1. Left Card: Merchant Radar & Auto-Buy Settings
local merchantCtrlRows = createCard("Merchant Radar & Settings", merchantPage)

createToggleRow("Auto Buy Rare Weapons", Config.MerchantAutoBuyWeapons, function(v)
    Config.MerchantAutoBuyWeapons = v
    setActivity(v and "Auto Buying Merchant Weapons (Dipper, Hanger, Slipper)" or "Merchant Weapons Auto Buy OFF", Color3.fromRGB(245, 158, 11))
end, merchantCtrlRows)

createToggleRow("Auto Buy Rare Furniture", Config.MerchantAutoBuyFurniture, function(v)
    Config.MerchantAutoBuyFurniture = v
    setActivity(v and "Auto Buying Antique/Bamboo/Folding Furniture" or "Merchant Furniture Auto Buy OFF", Color3.fromRGB(245, 158, 11))
end, merchantCtrlRows)

local renderMerchantStock

createButtonRow("Merchant 2 Mystery", "Buy (₱100)", Color3.fromRGB(245, 158, 11), function(btn)
    if BuyMerchant2Item then
        btn.Text = "Buying..."
        task.spawn(function()
            local ok, res = pcall(function() return BuyMerchant2Item:InvokeServer() end)
            if ok and res then
                setActivity("Bought Merchant 2 Mystery Item!", Color3.fromRGB(52, 199, 89))
            else
                setActivity("Merchant 2 Buy Failed", Color3.fromRGB(255, 69, 58))
            end
            task.wait(0.6)
            btn.Text = "Buy (₱100)"
        end)
    end
end, merchantCtrlRows)

createButtonRow("Refresh Merchant Stock", "Refresh 🔄", Color3.fromRGB(59, 130, 246), function(btn)
    if renderMerchantStock then
        renderMerchantStock()
    end
end, merchantCtrlRows)

-- 2. Right Card: Travelling Merchant Stock Catalog (9 Items)
local merchantStockRows = createCard("Travelling Merchant Stock", merchantPage)

renderMerchantStock = function()
    for _, ch in ipairs(merchantStockRows:GetChildren()) do
        if ch.Name:find("^MStock_") then
            ch:Destroy()
        end
    end

    if not GetMerchantStock then return end
    local ok, stock = pcall(function() return GetMerchantStock:InvokeServer() end)
    local items = (ok and type(stock) == "table") and stock or {}

    local count = 0
    for _, item in pairs(items) do
        if type(item) == "table" and item.Key then
            count = count + 1
            local price = item.Price or 0
            local cat = item.Category or "Item"
            local isWeapon = (cat == "Weapons")

            local row = Instance.new("Frame")
            row.Name = "MStock_" .. item.Key
            row.Size = UDim2.new(1, 0, 0, 48)
            row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            row.BackgroundTransparency = 0.94
            row.BorderSizePixel = 0
            row.Parent = merchantStockRows

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = row

            local rStroke = Instance.new("UIStroke")
            rStroke.Thickness = 1
            rStroke.Color = isWeapon and Color3.fromRGB(245, 158, 11) or Color3.fromRGB(255, 255, 255)
            rStroke.Transparency = isWeapon and 0.45 or 0.88
            rStroke.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Text = item.Key
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 12
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Size = UDim2.new(0.55, 0, 0, 18)
            nameLabel.Position = UDim2.new(0, 10, 0, 6)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Parent = row

            local catLabel = Instance.new("TextLabel")
            catLabel.Text = string.format("%s • ₱%s", cat, formatNumber(price))
            catLabel.Font = Enum.Font.GothamMedium
            catLabel.TextSize = 10
            catLabel.TextColor3 = isWeapon and Color3.fromRGB(255, 214, 10) or Color3.fromRGB(165, 180, 205)
            catLabel.TextXAlignment = Enum.TextXAlignment.Left
            catLabel.Size = UDim2.new(0.55, 0, 0, 16)
            catLabel.Position = UDim2.new(0, 10, 0, 26)
            catLabel.BackgroundTransparency = 1
            catLabel.Parent = row

            local buyBtn = Instance.new("TextButton")
            buyBtn.Name = "BuyBtn"
            buyBtn.Text = "Buy"
            buyBtn.Font = Enum.Font.GothamBold
            buyBtn.TextSize = 11
            buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            buyBtn.Size = UDim2.new(0, 68, 0, 26)
            buyBtn.Position = UDim2.new(1, -76, 0.5, -13)
            buyBtn.BackgroundColor3 = isWeapon and Color3.fromRGB(245, 158, 11) or Color3.fromRGB(14, 115, 235)
            buyBtn.BorderSizePixel = 0
            buyBtn.AutoButtonColor = true
            buyBtn.Parent = row

            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 6)
            bCorner.Parent = buyBtn

            local bStroke = Instance.new("UIStroke")
            bStroke.Thickness = 1
            bStroke.Color = Color3.fromRGB(255, 255, 255)
            bStroke.Transparency = 0.6
            bStroke.Parent = buyBtn

            buyBtn.MouseButton1Click:Connect(function()
                if BuyMerchantItem then
                    buyBtn.Text = "..."
                    task.spawn(function()
                        local bOk, bRes = pcall(function() return BuyMerchantItem:InvokeServer(item.Key) end)
                        if bOk and bRes then
                            setActivity("Purchased " .. item.Key .. " (₱" .. formatNumber(price) .. ")", Color3.fromRGB(52, 199, 89))
                            buyBtn.Text = "Owned"
                            buyBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
                        else
                            setActivity("Purchase failed: " .. item.Key, Color3.fromRGB(255, 69, 58))
                            buyBtn.Text = "Buy"
                        end
                    end)
                end
            end)
        end
    end

    if count == 0 then
        local emptyLbl = Instance.new("TextLabel")
        emptyLbl.Name = "MStock_Empty"
        emptyLbl.Text = "Travelling Merchant has no active stock right now."
        emptyLbl.Font = Enum.Font.GothamMedium
        emptyLbl.TextSize = 12
        emptyLbl.TextColor3 = Color3.fromRGB(150, 165, 190)
        emptyLbl.Size = UDim2.new(1, 0, 0, 60)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Parent = merchantStockRows
    end
end
task.spawn(renderMerchantStock)
end

--------------------------------------------------------------------------------
-- WEBHOOK TAB (Discord AFK Grinding Monitor)
--------------------------------------------------------------------------------
local function buildWebhookSection()
    local webhookColumnsLayout = Instance.new("UIListLayout")
    webhookColumnsLayout.FillDirection = Enum.FillDirection.Horizontal
    webhookColumnsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    webhookColumnsLayout.Padding = UDim.new(0, 10)
    webhookColumnsLayout.Parent = webhookPage

    ----------------------------------------------------------------------------
    -- 1. Left Card: Webhook Setup
    ----------------------------------------------------------------------------
    local whSettingsRows = createCard("Webhook Setup", webhookPage)
    local whSettingsCard = whSettingsRows.Parent
    whSettingsCard.Name = "Card_01_WebhookSetup"
    whSettingsCard.LayoutOrder = 1
    local whSettingsLayout = whSettingsRows:FindFirstChildWhichIsA("UIListLayout")
    if whSettingsLayout then
        whSettingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        whSettingsLayout.Padding = UDim.new(0, 8)
    end

    -- Row 1: Discord Webhook URL Card
    local urlRow = Instance.new("Frame")
    urlRow.Name = "Row_01_WebhookURL"
    urlRow.Size = UDim2.new(1, 0, 0, 68)
    urlRow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    urlRow.BackgroundTransparency = 0.94
    urlRow.BorderSizePixel = 0
    urlRow.LayoutOrder = 1
    urlRow.Parent = whSettingsRows

    local urlCorner = Instance.new("UICorner")
    urlCorner.CornerRadius = UDim.new(0, 8)
    urlCorner.Parent = urlRow

    local urlStroke = Instance.new("UIStroke")
    urlStroke.Thickness = 1
    urlStroke.Color = Color3.fromRGB(255, 255, 255)
    urlStroke.Transparency = 0.9
    urlStroke.Parent = urlRow

    local urlTitle = Instance.new("TextLabel")
    urlTitle.Text = "🔗 Webhook URL"
    urlTitle.Font = Enum.Font.GothamBold
    urlTitle.TextSize = 11
    urlTitle.TextColor3 = Color3.fromRGB(235, 242, 255)
    urlTitle.TextXAlignment = Enum.TextXAlignment.Left
    urlTitle.Size = UDim2.new(1, -95, 0, 20)
    urlTitle.Position = UDim2.new(0, 10, 0, 6)
    urlTitle.BackgroundTransparency = 1
    urlTitle.Parent = urlRow

    local urlStatusPill = Instance.new("Frame")
    urlStatusPill.Name = "StatusPill"
    urlStatusPill.Size = UDim2.new(0, 80, 0, 18)
    urlStatusPill.Position = UDim2.new(1, -88, 0, 7)
    urlStatusPill.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
    urlStatusPill.BorderSizePixel = 0
    urlStatusPill.Parent = urlRow

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(1, 0)
    pillCorner.Parent = urlStatusPill

    local pillStroke = Instance.new("UIStroke")
    pillStroke.Thickness = 1
    pillStroke.Color = Color3.fromRGB(80, 90, 110)
    pillStroke.Transparency = 0.5
    pillStroke.Parent = urlStatusPill

    local urlStatusBadge = Instance.new("TextLabel")
    urlStatusBadge.Name = "StatusText"
    urlStatusBadge.Font = Enum.Font.GothamBold
    urlStatusBadge.TextSize = 9
    urlStatusBadge.TextColor3 = Color3.fromRGB(150, 165, 185)
    urlStatusBadge.TextXAlignment = Enum.TextXAlignment.Center
    urlStatusBadge.Size = UDim2.new(1, 0, 1, 0)
    urlStatusBadge.BackgroundTransparency = 1
    urlStatusBadge.Parent = urlStatusPill

    local function updateUrlStatusBadge(clean)
        clean = clean or (Config.WebhookURL or "")
        if #clean > 10 and clean:find("discord") then
            urlStatusPill.BackgroundColor3 = Color3.fromRGB(18, 42, 26)
            pillStroke.Color = Color3.fromRGB(52, 199, 89)
            urlStatusBadge.TextColor3 = Color3.fromRGB(52, 199, 89)
            urlStatusBadge.Text = "● Connected"
        elseif #clean > 0 then
            urlStatusPill.BackgroundColor3 = Color3.fromRGB(42, 34, 16)
            pillStroke.Color = Color3.fromRGB(255, 214, 10)
            urlStatusBadge.TextColor3 = Color3.fromRGB(255, 214, 10)
            urlStatusBadge.Text = "● Custom"
        else
            urlStatusPill.BackgroundColor3 = Color3.fromRGB(26, 28, 38)
            pillStroke.Color = Color3.fromRGB(70, 80, 100)
            urlStatusBadge.TextColor3 = Color3.fromRGB(140, 155, 175)
            urlStatusBadge.Text = "● Not Set"
        end
    end
    updateUrlStatusBadge(Config.WebhookURL)

    local urlBox = Instance.new("TextBox")
    urlBox.Name = "UrlInput"
    urlBox.Text = Config.WebhookURL or ""
    urlBox.PlaceholderText = "Paste Discord webhook URL..."
    urlBox.Font = Enum.Font.GothamMedium
    urlBox.TextSize = 10
    urlBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    urlBox.PlaceholderColor3 = Color3.fromRGB(130, 140, 160)
    urlBox.TextXAlignment = Enum.TextXAlignment.Left
    urlBox.ClearTextOnFocus = false
    urlBox.Size = UDim2.new(1, -20, 0, 28)
    urlBox.Position = UDim2.new(0, 10, 0, 32)
    urlBox.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
    urlBox.BorderSizePixel = 0
    urlBox.Parent = urlRow

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = urlBox

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 1
    boxStroke.Color = Color3.fromRGB(255, 255, 255)
    boxStroke.Transparency = 0.85
    boxStroke.Parent = urlBox

    urlBox.FocusLost:Connect(function()
        local clean = urlBox.Text:gsub("%s+", "")
        Config.WebhookURL = clean
        saveWebhookConfig()
        updateUrlStatusBadge(clean)
    end)

    -- Row 2: Auto Send Status Updates Toggle
    local autoSendRow = createToggleRow("Auto Send Updates", Config.WebhookEnabled, function(v)
        Config.WebhookEnabled = v
        saveWebhookConfig()
        setActivity(v and ("Webhook Updates: " .. Config.WebhookInterval) or "Webhook Updates Paused", Color3.fromRGB(14, 115, 235))
    end, whSettingsRows)
    autoSendRow.Name = "Row_02_AutoSend"
    autoSendRow.LayoutOrder = 2
    local autoSendLabel = autoSendRow:FindFirstChild("Label")
    if autoSendLabel then autoSendLabel.TextSize = 11 end

    -- Row 3: Send Interval Cycler
    local intervalRow = createValueCycleRow("Send Interval", Config.WebhookInterval, { "1 min", "5 min", "10 min", "15 min", "30 min" }, function(v)
        Config.WebhookInterval = v
        saveWebhookConfig()
        setActivity("Webhook Interval: " .. v, Color3.fromRGB(14, 115, 235))
    end, whSettingsRows)
    intervalRow.Name = "Row_03_Interval"
    intervalRow.LayoutOrder = 3
    local intCycleBtn = intervalRow:FindFirstChild("CycleBtn")
    local intLabel = intervalRow:FindFirstChild("Label")
    if intCycleBtn and intLabel then
        intCycleBtn.Size = UDim2.new(0, 72, 0, 26)
        intCycleBtn.Position = UDim2.new(1, -80, 0.5, -13)
        intLabel.Size = UDim2.new(1, -88, 1, 0)
        intLabel.TextSize = 11
    end

    -- Row 4: Alert on Thief Chased Toggle
    local thiefAlertRow = createToggleRow("Alert: Thief Chased", Config.WebhookAlertThief, function(v)
        Config.WebhookAlertThief = v
        saveWebhookConfig()
    end, whSettingsRows)
    thiefAlertRow.Name = "Row_04_ThiefAlert"
    thiefAlertRow.LayoutOrder = 4
    local thiefLabel = thiefAlertRow:FindFirstChild("Label")
    if thiefLabel then thiefLabel.TextSize = 11 end

    -- Row 5: Alert on Rare Worker Toggle
    local workerAlertRow = createToggleRow("Alert: Rare Worker", Config.WebhookAlertWorker, function(v)
        Config.WebhookAlertWorker = v
        saveWebhookConfig()
    end, whSettingsRows)
    workerAlertRow.Name = "Row_05_WorkerAlert"
    workerAlertRow.LayoutOrder = 5
    local workerLabel = workerAlertRow:FindFirstChild("Label")
    if workerLabel then workerLabel.TextSize = 11 end

    -- Row 6: Full-Width Send Test Button
    local testRow = Instance.new("Frame")
    testRow.Name = "Row_06_TestBtn"
    testRow.Size = UDim2.new(1, 0, 0, 36)
    testRow.BackgroundTransparency = 1
    testRow.BorderSizePixel = 0
    testRow.LayoutOrder = 6
    testRow.Parent = whSettingsRows

    local testBtn = Instance.new("TextButton")
    testBtn.Name = "TestBtn"
    testBtn.Text = "📡  Send Test Webhook"
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 11
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.BackgroundColor3 = Color3.fromRGB(14, 115, 235)
    testBtn.BackgroundTransparency = 0.15
    testBtn.Size = UDim2.new(1, 0, 1, 0)
    testBtn.BorderSizePixel = 0
    testBtn.AutoButtonColor = true
    testBtn.Parent = testRow

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 8)
    tbCorner.Parent = testBtn

    local tbStroke = Instance.new("UIStroke")
    tbStroke.Thickness = 1
    tbStroke.Color = Color3.fromRGB(255, 255, 255)
    tbStroke.Transparency = 0.65
    tbStroke.Parent = testBtn

    local isSendingTest = false
    testBtn.MouseButton1Click:Connect(function()
        if isSendingTest then return end
        if not Config.WebhookURL or Config.WebhookURL == "" then
            testBtn.Text = "⚠️  Enter Webhook URL First!"
            testBtn.BackgroundColor3 = Color3.fromRGB(255, 159, 10)
            task.wait(1.8)
            testBtn.Text = "📡  Send Test Webhook"
            testBtn.BackgroundColor3 = Color3.fromRGB(14, 115, 235)
            return
        end

        isSendingTest = true
        testBtn.Text = "⏳  Sending Test..."
        testBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
        task.spawn(function()
            local ok, err = sendDiscordWebhookReport(true)
            if ok then
                testBtn.Text = "✓  Sent to Discord!"
                testBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
            else
                testBtn.Text = "❌  Failed to Send"
                testBtn.BackgroundColor3 = Color3.fromRGB(255, 69, 58)
                print("[Webhook Error]:", err)
            end
            task.wait(2.2)
            testBtn.Text = "📡  Send Test Webhook"
            testBtn.BackgroundColor3 = Color3.fromRGB(14, 115, 235)
            isSendingTest = false
        end)
    end)

    ----------------------------------------------------------------------------
    -- 2. Right Card: Live AFK Monitor (Apple Glass Dashboard Widgets)
    ----------------------------------------------------------------------------
    local whMonitorRows = createCard("Live AFK Monitor", webhookPage)
    local whMonitorCard = whMonitorRows.Parent
    whMonitorCard.Name = "Card_02_LiveAFKMonitor"
    whMonitorCard.LayoutOrder = 2
    local whMonitorLayout = whMonitorRows:FindFirstChildWhichIsA("UIListLayout")
    if whMonitorLayout then
        whMonitorLayout.SortOrder = Enum.SortOrder.LayoutOrder
        whMonitorLayout.Padding = UDim.new(0, 8)
    end

    -- Tile 1: Hero Profit Widget
    local profitTile = Instance.new("Frame")
    profitTile.Name = "Tile_01_Profit"
    profitTile.Size = UDim2.new(1, 0, 0, 66)
    profitTile.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    profitTile.BackgroundTransparency = 0.94
    profitTile.BorderSizePixel = 0
    profitTile.LayoutOrder = 1
    profitTile.Parent = whMonitorRows

    local ptCorner = Instance.new("UICorner")
    ptCorner.CornerRadius = UDim.new(0, 10)
    ptCorner.Parent = profitTile

    local ptStroke = Instance.new("UIStroke")
    ptStroke.Thickness = 1
    ptStroke.Color = Color3.fromRGB(255, 255, 255)
    ptStroke.Transparency = 0.9
    ptStroke.Parent = profitTile

    local ptGrad = Instance.new("UIGradient")
    ptGrad.Rotation = 90
    ptGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(36, 46, 66)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 26, 38))
    })
    ptGrad.Parent = profitTile

    local ptHeader = Instance.new("Frame")
    ptHeader.Size = UDim2.new(1, -20, 0, 18)
    ptHeader.Position = UDim2.new(0, 10, 0, 6)
    ptHeader.BackgroundTransparency = 1
    ptHeader.Parent = profitTile

    local ptTitle = Instance.new("TextLabel")
    ptTitle.Text = "💰 SESSION PROFIT"
    ptTitle.Font = Enum.Font.GothamBold
    ptTitle.TextSize = 10
    ptTitle.TextColor3 = Color3.fromRGB(150, 170, 200)
    ptTitle.TextXAlignment = Enum.TextXAlignment.Left
    ptTitle.Size = UDim2.new(0.65, 0, 1, 0)
    ptTitle.BackgroundTransparency = 1
    ptTitle.Parent = ptHeader

    local ptLiveBadge = Instance.new("TextLabel")
    ptLiveBadge.Text = "● LIVE"
    ptLiveBadge.Font = Enum.Font.GothamBold
    ptLiveBadge.TextSize = 9
    ptLiveBadge.TextColor3 = Color3.fromRGB(52, 199, 89)
    ptLiveBadge.TextXAlignment = Enum.TextXAlignment.Right
    ptLiveBadge.Size = UDim2.new(0.35, 0, 1, 0)
    ptLiveBadge.BackgroundTransparency = 1
    ptLiveBadge.Parent = ptHeader

    local profitVal = Instance.new("TextLabel")
    profitVal.Name = "ProfitVal"
    profitVal.Text = "+₱0"
    profitVal.Font = Enum.Font.GothamBold
    profitVal.TextSize = 16
    profitVal.TextColor3 = Color3.fromRGB(52, 225, 100)
    profitVal.TextXAlignment = Enum.TextXAlignment.Left
    profitVal.Size = UDim2.new(0.55, -4, 0, 28)
    profitVal.Position = UDim2.new(0, 10, 0, 28)
    profitVal.BackgroundTransparency = 1
    profitVal.Parent = profitTile

    local rateBadge = Instance.new("TextLabel")
    rateBadge.Name = "RateBadge"
    rateBadge.Text = "~₱0/hr"
    rateBadge.Font = Enum.Font.GothamBold
    rateBadge.TextSize = 10
    rateBadge.TextColor3 = Color3.fromRGB(200, 230, 255)
    rateBadge.TextXAlignment = Enum.TextXAlignment.Center
    rateBadge.Size = UDim2.new(0.45, -6, 0, 22)
    rateBadge.Position = UDim2.new(0.55, 0, 0, 31)
    rateBadge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    rateBadge.BackgroundTransparency = 0.92
    rateBadge.BorderSizePixel = 0
    rateBadge.Parent = profitTile

    local rbCorner = Instance.new("UICorner")
    rbCorner.CornerRadius = UDim.new(1, 0)
    rbCorner.Parent = rateBadge

    local rbStroke = Instance.new("UIStroke")
    rbStroke.Thickness = 1
    rbStroke.Color = Color3.fromRGB(255, 255, 255)
    rbStroke.Transparency = 0.88
    rbStroke.Parent = rateBadge

    -- Tile 2: Dual Status Mini-Cards (AFK Time + Next Send)
    local dualRow = Instance.new("Frame")
    dualRow.Name = "Tile_02_DualRow"
    dualRow.Size = UDim2.new(1, 0, 0, 50)
    dualRow.BackgroundTransparency = 1
    dualRow.BorderSizePixel = 0
    dualRow.LayoutOrder = 2
    dualRow.Parent = whMonitorRows

    local timeBox = Instance.new("Frame")
    timeBox.Name = "TimeBox"
    timeBox.Size = UDim2.new(0.5, -4, 1, 0)
    timeBox.Position = UDim2.new(0, 0, 0, 0)
    timeBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    timeBox.BackgroundTransparency = 0.94
    timeBox.BorderSizePixel = 0
    timeBox.Parent = dualRow

    local tbCorner2 = Instance.new("UICorner")
    tbCorner2.CornerRadius = UDim.new(0, 8)
    tbCorner2.Parent = timeBox

    local tbStroke2 = Instance.new("UIStroke")
    tbStroke2.Thickness = 1
    tbStroke2.Color = Color3.fromRGB(255, 255, 255)
    tbStroke2.Transparency = 0.9
    tbStroke2.Parent = timeBox

    local tbTitle = Instance.new("TextLabel")
    tbTitle.Text = "⏱️ AFK TIME"
    tbTitle.Font = Enum.Font.GothamBold
    tbTitle.TextSize = 9
    tbTitle.TextColor3 = Color3.fromRGB(140, 155, 180)
    tbTitle.TextXAlignment = Enum.TextXAlignment.Left
    tbTitle.Size = UDim2.new(1, -12, 0, 16)
    tbTitle.Position = UDim2.new(0, 8, 0, 5)
    tbTitle.BackgroundTransparency = 1
    tbTitle.Parent = timeBox

    local uptimeVal = Instance.new("TextLabel")
    uptimeVal.Name = "UptimeVal"
    uptimeVal.Text = "00h 00m 00s"
    uptimeVal.Font = Enum.Font.GothamBold
    uptimeVal.TextSize = 11
    uptimeVal.TextColor3 = Color3.fromRGB(245, 250, 255)
    uptimeVal.TextXAlignment = Enum.TextXAlignment.Left
    uptimeVal.Size = UDim2.new(1, -12, 0, 22)
    uptimeVal.Position = UDim2.new(0, 8, 0, 22)
    uptimeVal.BackgroundTransparency = 1
    uptimeVal.Parent = timeBox

    local sendBox = Instance.new("Frame")
    sendBox.Name = "SendBox"
    sendBox.Size = UDim2.new(0.5, -4, 1, 0)
    sendBox.Position = UDim2.new(0.5, 4, 0, 0)
    sendBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sendBox.BackgroundTransparency = 0.94
    sendBox.BorderSizePixel = 0
    sendBox.Parent = dualRow

    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 8)
    sbCorner.Parent = sendBox

    local sbStroke = Instance.new("UIStroke")
    sbStroke.Thickness = 1
    sbStroke.Color = Color3.fromRGB(255, 255, 255)
    sbStroke.Transparency = 0.9
    sbStroke.Parent = sendBox

    local sbTitle = Instance.new("TextLabel")
    sbTitle.Text = "📡 NEXT SEND"
    sbTitle.Font = Enum.Font.GothamBold
    sbTitle.TextSize = 9
    sbTitle.TextColor3 = Color3.fromRGB(140, 155, 180)
    sbTitle.TextXAlignment = Enum.TextXAlignment.Left
    sbTitle.Size = UDim2.new(1, -12, 0, 16)
    sbTitle.Position = UDim2.new(0, 8, 0, 5)
    sbTitle.BackgroundTransparency = 1
    sbTitle.Parent = sendBox

    local nextSendVal = Instance.new("TextLabel")
    nextSendVal.Name = "NextSendVal"
    nextSendVal.Text = "Paused"
    nextSendVal.Font = Enum.Font.GothamBold
    nextSendVal.TextSize = 11
    nextSendVal.TextColor3 = Color3.fromRGB(140, 150, 170)
    nextSendVal.TextXAlignment = Enum.TextXAlignment.Left
    nextSendVal.Size = UDim2.new(1, -12, 0, 22)
    nextSendVal.Position = UDim2.new(0, 8, 0, 22)
    nextSendVal.BackgroundTransparency = 1
    nextSendVal.Parent = sendBox

    -- Tile 3: Staff Status Card
    local staffTile = Instance.new("Frame")
    staffTile.Name = "Tile_03_Staff"
    staffTile.Size = UDim2.new(1, 0, 0, 44)
    staffTile.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    staffTile.BackgroundTransparency = 0.94
    staffTile.BorderSizePixel = 0
    staffTile.LayoutOrder = 3
    staffTile.Parent = whMonitorRows

    local stCorner = Instance.new("UICorner")
    stCorner.CornerRadius = UDim.new(0, 8)
    stCorner.Parent = staffTile

    local stStroke = Instance.new("UIStroke")
    stStroke.Thickness = 1
    stStroke.Color = Color3.fromRGB(255, 255, 255)
    stStroke.Transparency = 0.9
    stStroke.Parent = staffTile

    local stTitle = Instance.new("TextLabel")
    stTitle.Text = "👥 RESTAURANT STAFF"
    stTitle.Font = Enum.Font.GothamBold
    stTitle.TextSize = 9
    stTitle.TextColor3 = Color3.fromRGB(140, 155, 180)
    stTitle.TextXAlignment = Enum.TextXAlignment.Left
    stTitle.Size = UDim2.new(1, -16, 0, 14)
    stTitle.Position = UDim2.new(0, 8, 0, 4)
    stTitle.BackgroundTransparency = 1
    stTitle.Parent = staffTile

    local staffRow = Instance.new("Frame")
    staffRow.Size = UDim2.new(1, -16, 0, 20)
    staffRow.Position = UDim2.new(0, 8, 0, 20)
    staffRow.BackgroundTransparency = 1
    staffRow.Parent = staffTile

    local assignerLabel = Instance.new("TextLabel")
    assignerLabel.Name = "AssignerLabel"
    assignerLabel.RichText = true
    assignerLabel.Text = "Assigner: <font color='#FF453A'>None</font>"
    assignerLabel.Font = Enum.Font.GothamBold
    assignerLabel.TextSize = 10
    assignerLabel.TextColor3 = Color3.fromRGB(220, 230, 245)
    assignerLabel.TextXAlignment = Enum.TextXAlignment.Left
    assignerLabel.Size = UDim2.new(0.5, 0, 1, 0)
    assignerLabel.Position = UDim2.new(0, 0, 0, 0)
    assignerLabel.BackgroundTransparency = 1
    assignerLabel.Parent = staffRow

    local dishwasherLabel = Instance.new("TextLabel")
    dishwasherLabel.Name = "DishwasherLabel"
    dishwasherLabel.RichText = true
    dishwasherLabel.Text = "Dishes: <font color='#FF453A'>None</font>"
    dishwasherLabel.Font = Enum.Font.GothamBold
    dishwasherLabel.TextSize = 10
    dishwasherLabel.TextColor3 = Color3.fromRGB(220, 230, 245)
    dishwasherLabel.TextXAlignment = Enum.TextXAlignment.Left
    dishwasherLabel.Size = UDim2.new(0.5, 0, 1, 0)
    dishwasherLabel.Position = UDim2.new(0.5, 0, 0, 0)
    dishwasherLabel.BackgroundTransparency = 1
    dishwasherLabel.Parent = staffRow

    -- Tile 4: Telemetry Stats Grid (3 Columns)
    local telemTile = Instance.new("Frame")
    telemTile.Name = "Tile_04_Telemetry"
    telemTile.Size = UDim2.new(1, 0, 0, 54)
    telemTile.BackgroundTransparency = 1
    telemTile.BorderSizePixel = 0
    telemTile.LayoutOrder = 4
    telemTile.Parent = whMonitorRows

    local function makeTelemBox(name, titleText, initialVal, posScale)
        local box = Instance.new("Frame")
        box.Name = name
        box.Size = UDim2.new(0.333, -4, 1, 0)
        local xOffset = (posScale == 0 and 0) or (posScale > 0.6 and 4 or 2)
        box.Position = UDim2.new(posScale, xOffset, 0, 0)
        box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        box.BackgroundTransparency = 0.94
        box.BorderSizePixel = 0
        box.Parent = telemTile

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 8)
        bCorner.Parent = box

        local bStroke = Instance.new("UIStroke")
        bStroke.Thickness = 1
        bStroke.Color = Color3.fromRGB(255, 255, 255)
        bStroke.Transparency = 0.9
        bStroke.Parent = box

        local lbl = Instance.new("TextLabel")
        lbl.Text = titleText
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 9
        lbl.TextColor3 = Color3.fromRGB(140, 155, 180)
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.Size = UDim2.new(1, 0, 0, 16)
        lbl.Position = UDim2.new(0, 0, 0, 5)
        lbl.BackgroundTransparency = 1
        lbl.Parent = box

        local valLbl = Instance.new("TextLabel")
        valLbl.Name = "Val"
        valLbl.Text = initialVal
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 14
        valLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        valLbl.TextXAlignment = Enum.TextXAlignment.Center
        valLbl.Size = UDim2.new(1, 0, 0, 24)
        valLbl.Position = UDim2.new(0, 0, 0, 22)
        valLbl.BackgroundTransparency = 1
        valLbl.Parent = box

        return valLbl
    end

    local thievesVal = makeTelemBox("Box_Thieves", "💥 Thieves", "0", 0)
    local workersWokenVal = makeTelemBox("Box_Woken", "💤 Woken", "0", 0.333)
    local trashVal = makeTelemBox("Box_Trash", "🧹 Cleaned", "0", 0.666)

    ----------------------------------------------------------------------------
    -- 3. Background Telemetry Updater
    ----------------------------------------------------------------------------
    task.spawn(function()
        while Hub.Running do
            local elapsed = math.floor(os.clock() - (Hub.SessionStartTime or os.clock()))
            uptimeVal.Text = string.format("%02dh %02dm %02ds", math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), elapsed % 60)

            if Config.WebhookEnabled and Config.WebhookURL and #Config.WebhookURL > 10 then
                local intSec = INTERVAL_MAP[Config.WebhookInterval] or 300
                local sinceLast = os.clock() - (Hub.LastWebhookSent or 0)
                local remaining = math.max(0, math.floor(intSec - sinceLast))
                nextSendVal.Text = string.format("in %02d:%02d", math.floor(remaining / 60), remaining % 60)
                nextSendVal.TextColor3 = Color3.fromRGB(52, 199, 89)
            else
                nextSendVal.Text = "Paused"
                nextSendVal.TextColor3 = Color3.fromRGB(140, 150, 170)
            end

            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            local curCash = (leaderstats and leaderstats:FindFirstChild("Cash") and leaderstats.Cash.Value) or 0
            if Hub.SessionStartCash == 0 and curCash > 0 then
                Hub.SessionStartCash = curCash
            end
            local earned = curCash - (Hub.SessionStartCash or curCash)
            local ratePerHour = math.floor(math.max(0, earned) / math.max(0.001, elapsed / 3600))
            profitVal.Text = string.format("%s₱%s", earned >= 0 and "+" or "", formatNumber(earned))
            profitVal.TextColor3 = earned >= 0 and Color3.fromRGB(52, 225, 100) or Color3.fromRGB(255, 90, 80)
            rateBadge.Text = string.format("~₱%s/hr", formatNumber(ratePerHour))

            thievesVal.Text = tostring(Hub.ThievesChasedCount or 0)
            workersWokenVal.Text = tostring(Hub.WorkersWokenCount or 0)
            trashVal.Text = tostring(Hub.TrashCleanedCount or 0)

            local hired = getHiredRoles and getHiredRoles() or {}
            local hasAssigner = (hired.Assigner ~= nil and hired.Assigner ~= false)
            local hasDishwasher = (hired.Dishwasher ~= nil and hired.Dishwasher ~= false)
            assignerLabel.Text = string.format("Assigner: %s", hasAssigner and "<font color='#34C759'>● Active</font>" or "<font color='#FF453A'>○ None</font>")
            dishwasherLabel.Text = string.format("Dishes: %s", hasDishwasher and "<font color='#34C759'>● Active</font>" or "<font color='#FF453A'>○ None</font>")

            task.wait(1)
        end
    end)
end
do
    buildWebhookSection()
end

--------------------------------------------------------------------------------
-- CONFIG TAB (Movement Mode Toggle + Interactive Glide Speed Slider)
--------------------------------------------------------------------------------
do
    local configColumnsLayout = Instance.new("UIListLayout")
    configColumnsLayout.FillDirection = Enum.FillDirection.Horizontal
    configColumnsLayout.Padding = UDim.new(0, 10)
    configColumnsLayout.Parent = configPage

local configMovementRows = createCard("Movement & Glide", configPage)

-- 1. Movement Mode Toggle (Smooth Glide vs Instant Teleport)
createToggleRow("Movement: Smooth Glide (OFF=TP)", Config.UseGlide, function(v)
    Config.UseGlide = v
    setActivity(v and ("Movement: Smooth Glide (" .. Config.GlideSpeed .. " spd)") or "Movement: Instant Teleport", Color3.fromRGB(59, 130, 246))
end, configMovementRows)

-- 2. Interactive Glide Speed Slider
local function createSlider(title, minVal, maxVal, defaultVal, onValueChanged, parent)
    local container = Instance.new("Frame")
    container.Name = "Slider_" .. title
    container.Size = UDim2.new(1, 0, 0, 54)
    container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    container.BackgroundTransparency = 0.94
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local cStroke = Instance.new("UIStroke")
    cStroke.Thickness = 1
    cStroke.Color = Color3.fromRGB(255, 255, 255)
    cStroke.Transparency = 0.9
    cStroke.Parent = container

    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, -20, 0, 20)
    headerFrame.Position = UDim2.new(0, 10, 0, 6)
    headerFrame.BackgroundTransparency = 1
    headerFrame.Parent = container

    local label = Instance.new("TextLabel")
    label.Text = title
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = Color3.fromRGB(240, 245, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Parent = headerFrame

    local valLabel = Instance.new("TextLabel")
    valLabel.Text = tostring(defaultVal) .. " studs/s"
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 12
    valLabel.TextColor3 = Color3.fromRGB(100, 210, 255) -- Apple System Cyan
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Size = UDim2.new(0.4, 0, 1, 0)
    valLabel.Position = UDim2.new(0.6, 0, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Parent = headerFrame

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, -20, 0, 8)
    track.Position = UDim2.new(0, 10, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    track.BackgroundTransparency = 0.85
    track.BorderSizePixel = 0
    track.Parent = container

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local initPct = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(initPct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(10, 132, 255) -- Apple System Blue
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 132, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 210, 255))
    })
    fillGrad.Parent = fill

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(initPct, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local knobShadow = Instance.new("UIStroke")
    knobShadow.Thickness = 1
    knobShadow.Color = Color3.fromRGB(0, 0, 0)
    knobShadow.Transparency = 0.8
    knobShadow.Parent = knob

    local hitBtn = Instance.new("TextButton")
    hitBtn.Name = "HitBtn"
    hitBtn.Text = ""
    hitBtn.BackgroundTransparency = 1
    hitBtn.Size = UDim2.new(1, -20, 0, 26)
    hitBtn.Position = UDim2.new(0, 10, 0, 24)
    hitBtn.Parent = container

    local isDragging = false
    local function setFromInput(input)
        local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local value = math.floor(minVal + (maxVal - minVal) * relX)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        knob.Position = UDim2.new(relX, 0, 0.5, 0)
        valLabel.Text = tostring(value) .. " studs/s"
        onValueChanged(value)
    end

    hitBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            setFromInput(input)
        end
    end)

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            setFromInput(input)
        end
    end)

    trackConn(UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromInput(input)
        end
    end))

    trackConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end))

    return container
end

createSlider("Glide Speed", 30, 250, Config.GlideSpeed, function(val)
    Config.GlideSpeed = val
end, configMovementRows)

createToggleRow("Return to Plot after action", Config.ReturnToHome, function(v) Config.ReturnToHome = v end, configMovementRows)
createToggleRow("Speed Booster (24 spd)", Config.SpeedBoost, function(v)
    Config.SpeedBoost = v
    local hum = getHumanoid()
    if hum and not v then hum.WalkSpeed = 16 end
end, configMovementRows)

-- Right Column: Controls & Protection
local configControlsRows = createCard("Controls & Safety", configPage)
createToggleRow("Auto Equip Pan", Config.EquipPan, function(v) Config.EquipPan = v end, configControlsRows)
createToggleRow("Anti-AFK Protection", Config.AntiAFK, function(v) Config.AntiAFK = v end, configControlsRows)

local function createActionButton(label, callback, parent)
    local btn = Instance.new("TextButton")
    btn.Name = "ActionBtn_" .. label
    btn.Text = label
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = C_ROW_BG
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.AutoButtonColor = true
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    return btn
end

createActionButton("Teleport to Plot", function()
    if TeleportHomeEvent then
        TeleportHomeEvent:FireServer()
    else
        local plot = getPlayerPlot()
        local hrp = getHRP()
        if plot and hrp then
            local pivot = plot:GetPivot()
            hrp.CFrame = pivot * CFrame.new(0, 3, 0)
        end
    end
end, configControlsRows)

createActionButton("Unload / Close Script", function()
    Hub.Unload()
end, configControlsRows)
end

-- Resize Grip Handle Icon at bottom-right
local resizeGrip = Instance.new("ImageLabel")
resizeGrip.Name = "ResizeGrip"
resizeGrip.Size = UDim2.new(0, 14, 0, 14)
resizeGrip.Position = UDim2.new(1, -16, 1, -16)
resizeGrip.BackgroundTransparency = 1
resizeGrip.Image = "rbxassetid://97837777176169"
resizeGrip.ImageColor3 = Color3.fromRGB(120, 120, 120)
resizeGrip.Parent = mainWindow

-- Toggle GUI Visibility Keybind (RightControl / Insert)
trackConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and (input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert) then
        mainWindow.Visible = not mainWindow.Visible
    end
end))

-- Set Initial Active Tab
switchTab("Main")

--------------------------------------------------------------------------------
-- UNLOAD CLEANUP
--------------------------------------------------------------------------------
function Hub.Unload()
    Hub.Running = false

    for _, conn in ipairs(Hub.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Hub.Connections)

    for _, th in ipairs(Hub.Tasks) do
        pcall(function() task.cancel(th) end)
    end
    table.clear(Hub.Tasks)

    if Hub.UI then
        pcall(function() Hub.UI:Destroy() end)
        Hub.UI = nil
    end

    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = 16
    end

    G.KarinderyaHub = nil
    print("[Karinderya!] Unloaded successfully.")
end

print("[Karinderya!] Ultra-Smooth Suite with Redesigned Shop & Glide Slider Deployed!")
