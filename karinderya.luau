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
    MysteryBoxesOpenedCount = 0,
    LastMysteryBoxDrop = "None",
    CurrentCounterLevel = "Default",
    ChillerStatus = "Working",
    GoldenSpatulaStatus = "Inactive",
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
    ShopAutoBuyTargetsOnly = true,
    ShopTargetItems = {},
    ShopShowAllStock = true,
    ShopFilter = "All",
    ShopAutoRefresh = true,
    ShopAutoRefreshInterval = 10,
    WebhookAlertShop = true,

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

    -- Upgrades & Mystery Box Automations
    MysteryBoxAutoOrder = false,
    MysteryBoxOrderCount = 5,      -- 1, 2, 3, 4, 5
    MysteryBoxMinHearts = 1,       -- Keep at least X hearts
    MysteryBoxAutoOpen = true,
    WebhookAlertMysteryBox = true,

    -- Counter & Appliances Automations
    AutoUpgradeCounter = false,
    AutoEquipCounter = true,
    AutoRepairChiller = true,
    AutoBuyGoldenSpatula = false,

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

local Upg = {
    BuyMysteryBox = Remotes and Remotes:FindFirstChild("MysteryBoxRemotes") and Remotes.MysteryBoxRemotes:FindFirstChild("BuyMysteryBox"),
    GetMysteryBoxState = Remotes and Remotes:FindFirstChild("MysteryBoxRemotes") and Remotes.MysteryBoxRemotes:FindFirstChild("GetMysteryBoxState"),
    MysteryBoxOpened = Remotes and Remotes:FindFirstChild("Notification") and Remotes.Notification:FindFirstChild("MysteryBoxOpened"),
    BuyCounterUpgrade = CounterRemotes and CounterRemotes:FindFirstChild("BuyCounterUpgrade"),
    EquipCounterUpgrade = CounterRemotes and CounterRemotes:FindFirstChild("EquipCounterUpgrade"),
    GetMenuData = Remotes and Remotes:FindFirstChild("MenuRemotes") and Remotes.MenuRemotes:FindFirstChild("GetMenuData"),
    GetExpansionInfo = Remotes and Remotes:FindFirstChild("ExpansionRemotes") and Remotes.ExpansionRemotes:FindFirstChild("GetExpansionInfo"),
    StartExpansion = Remotes and Remotes:FindFirstChild("ExpansionRemotes") and Remotes.ExpansionRemotes:FindFirstChild("StartExpansion"),
    GetGoldenSpatulaInfo = Remotes and Remotes:FindFirstChild("GetGoldenSpatulaInfo"),
    PurchaseGoldenSpatula = Remotes and Remotes:FindFirstChild("PurchaseGoldenSpatula"),
    MysteryBoxConfig = Modules and Modules:FindFirstChild("MysteryBoxConfig") and require(Modules.MysteryBoxConfig) or {},
    CounterConfig = Modules and Modules:FindFirstChild("CounterConfig") and require(Modules.CounterConfig) or {},
    ExpansionConfig = Modules and Modules:FindFirstChild("ExpansionConfig") and require(Modules.ExpansionConfig) or {},
    GoldenSpatulaConfig = Modules and Modules:FindFirstChild("GoldenSpatulaConfig") and require(Modules.GoldenSpatulaConfig) or {},
}
Hub.Upg = Upg

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

local function getItemDetails(systemType, category, key)
    local price = 0
    local name = key
    local icon = nil
    local desc = nil

    local cat = string.lower(tostring(category or ""))
    if (cat == "paints" or cat == "paint") and PaintConfig and PaintConfig[key] then
        local cfg = PaintConfig[key]
        name = (cfg.Name or key):gsub("%s*Paint$", "")
        price = cfg.Cost or cfg.Price or 0
        icon = cfg.Image or cfg.Icon
        desc = cfg.Description
    elseif (cat == "tiles" or cat == "tile") and TileConfig and TileConfig[key] then
        local cfg = TileConfig[key]
        name = cfg.Name or key
        price = cfg.Cost or cfg.Price or 0
        icon = cfg.Image or cfg.Icon
        desc = cfg.Description
    elseif (cat == "materials" or cat == "material") and MaterialConfig and MaterialConfig[key] then
        local cfg = MaterialConfig[key]
        name = cfg.Name or key
        price = cfg.Cost or cfg.Price or 0
        icon = cfg.Image or cfg.Icon
        desc = cfg.Description
    elseif FurnitureConfig and type(FurnitureConfig.GetItemConfig) == "function" then
        local ok, cfg = pcall(function() return FurnitureConfig.GetItemConfig(systemType, category, key) end)
        if ok and cfg then
            price = cfg.Price or cfg.Cost or 0
            name = cfg.Name or key
            icon = cfg.Icon or cfg.Image
            desc = cfg.Description
        end
    end
    return price, name, icon, desc
end

local function getItemPriceAndName(systemType, category, key)
    local price, name = getItemDetails(systemType, category, key)
    return price, name
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
        Hub.StatusLabel.Text = "● " .. text
        if color then
            Hub.StatusLabel.TextColor3 = color
        end
    end
    if Hub.HeaderStatusLabel then
        Hub.HeaderStatusLabel.Text = text
        if color and Hub.HeaderStatusDot then
            Hub.HeaderStatusDot.TextColor3 = color
        end
        if color and Hub.HeaderStatusStroke then
            Hub.HeaderStatusStroke.Color = color
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
local updateShopStockShared = nil
local syncShopAutoBuyButtons = nil

local function matchesShopCategory(catName, filter)
    if not filter or filter == "All" then return true end
    if not catName then return false end
    local c = string.lower(tostring(catName))
    local f = string.lower(tostring(filter))
    if c == f then return true end
    if (c == "materials" and f == "material") or (c == "material" and f == "materials") then return true end
    if (c == "stoves" and f == "stove") or (c == "stove" and f == "stoves") then return true end
    if (c == "paints" and f == "paint") or (c == "paint" and f == "paints") then return true end
    if (c == "tables" and f == "table") or (c == "table" and f == "tables") then return true end
    if (c == "chairs" and f == "chair") or (c == "chair" and f == "chairs") then return true end
    if (c == "tiles" and f == "tile") or (c == "tile" and f == "tiles") then return true end
    return false
end

local function getNextRestockRemaining()
    local ok, serverTime = pcall(function() return Workspace:GetServerTimeNow() end)
    if not ok or not serverTime then serverTime = os.time() end
    local elapsed = serverTime % 300
    local remaining = 300 - elapsed
    if remaining <= 0 or remaining >= 300 then
        return 0
    end
    return math.floor(remaining)
end

local function formatTimer(secs)
    secs = math.max(0, math.floor(secs or 0))
    local m = math.floor(secs / 60)
    local s = secs % 60
    return string.format("%02d:%02d", m, s)
end

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
            if data.MysteryBoxAutoOrder ~= nil then Config.MysteryBoxAutoOrder = data.MysteryBoxAutoOrder end
            if data.MysteryBoxOrderCount ~= nil then Config.MysteryBoxOrderCount = tonumber(data.MysteryBoxOrderCount) or 5 end
            if data.MysteryBoxMinHearts ~= nil then Config.MysteryBoxMinHearts = tonumber(data.MysteryBoxMinHearts) or 1 end
            if data.MysteryBoxAutoOpen ~= nil then Config.MysteryBoxAutoOpen = data.MysteryBoxAutoOpen end
            if data.WebhookAlertMysteryBox ~= nil then Config.WebhookAlertMysteryBox = data.WebhookAlertMysteryBox end
            if data.AutoUpgradeCounter ~= nil then Config.AutoUpgradeCounter = data.AutoUpgradeCounter end
            if data.AutoEquipCounter ~= nil then Config.AutoEquipCounter = data.AutoEquipCounter end
            if data.AutoRepairChiller ~= nil then Config.AutoRepairChiller = data.AutoRepairChiller end
            if data.AutoBuyGoldenSpatula ~= nil then Config.AutoBuyGoldenSpatula = data.AutoBuyGoldenSpatula end
            if data.ShopAutoBuy ~= nil then Config.ShopAutoBuy = data.ShopAutoBuy end
            if data.ShopAutoBuyTargetsOnly ~= nil then Config.ShopAutoBuyTargetsOnly = data.ShopAutoBuyTargetsOnly end
            if data.ShopTargetItems and type(data.ShopTargetItems) == "table" then Config.ShopTargetItems = data.ShopTargetItems end
            if data.ShopShowAllStock ~= nil then Config.ShopShowAllStock = data.ShopShowAllStock end
            if data.WebhookAlertShop ~= nil then Config.WebhookAlertShop = data.WebhookAlertShop end
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
                MysteryBoxAutoOrder = Config.MysteryBoxAutoOrder == true,
                MysteryBoxOrderCount = Config.MysteryBoxOrderCount or 5,
                MysteryBoxMinHearts = Config.MysteryBoxMinHearts or 1,
                MysteryBoxAutoOpen = Config.MysteryBoxAutoOpen ~= false,
                WebhookAlertMysteryBox = Config.WebhookAlertMysteryBox ~= false,
                AutoUpgradeCounter = Config.AutoUpgradeCounter == true,
                AutoEquipCounter = Config.AutoEquipCounter ~= false,
                AutoRepairChiller = Config.AutoRepairChiller ~= false,
                AutoBuyGoldenSpatula = Config.AutoBuyGoldenSpatula == true,
                ShopAutoBuy = Config.ShopAutoBuy == true,
                ShopAutoBuyTargetsOnly = Config.ShopAutoBuyTargetsOnly ~= false,
                ShopTargetItems = Config.ShopTargetItems or {},
                ShopShowAllStock = Config.ShopShowAllStock ~= false,
                WebhookAlertShop = Config.WebhookAlertShop ~= false,
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
                    },
                    {
                        name = "📦 Upgrades & Appliances",
                        value = string.format("🎁 Boxes Opened: **%d** (Latest: `%s`) | 🔨 Counter: **%s** | ❄️ Chiller: **%s**",
                            Hub.MysteryBoxesOpenedCount or 0,
                            Hub.LastMysteryBoxDrop or "None",
                            Hub.CurrentCounterLevel or "Default",
                            Hub.ChillerStatus or "Working"
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

-- 9. Shop Auto Buy (Buys Restocked Furniture / Appliances / Targeted Items)
local function hasShopTargets()
    if not Config.ShopTargetItems then return false end
    for _, v in pairs(Config.ShopTargetItems) do
        if v == true then return true end
    end
    return false
end

local isBuyingShop = false
local lastShopAutoBuyTick = 0

local function doShopAutoBuy(force)
    local hasTargets = hasShopTargets()
    local isTargetMode = (Config.ShopAutoBuyTargetsOnly == true)

    -- Auto-buy proceeds if Master Auto Buy is ON, OR if user has 1+ active targeted items!
    if not Config.ShopAutoBuy and not (isTargetMode and hasTargets) then
        return
    end

    if isBuyingShop or not BuyFurniture or not GetShopInfo then return end

    local now = tick()
    if not force and (now - lastShopAutoBuyTick < 2.0) then
        return
    end
    lastShopAutoBuyTick = now
    isBuyingShop = true

    local ok, res = pcall(function() return GetShopInfo:InvokeServer() end)
    if ok and type(res) == "table" then
        local anyBought = false
        for catName, items in pairs(res) do
            if type(items) == "table" then
                for _, itm in ipairs(items) do
                    local itmKey = itm.Key
                    local itmCat = itm.Category or catName
                    local itmSys = itm.SystemType or (itmCat == "Stoves" and "Kitchen" or "Dining")
                    local itmStock = tonumber(itm.Stock) or 0

                    local shouldBuy = false
                    if isTargetMode then
                        shouldBuy = (Config.ShopTargetItems and Config.ShopTargetItems[itmKey] == true)
                    else
                        shouldBuy = matchesShopCategory(catName, Config.ShopFilter)
                    end

                    if shouldBuy and itmStock > 0 and itmKey and itmCat and itmSys then
                        local boughtCount = 0
                        for _ = 1, itmStock do
                            local bOk, bRes = pcall(function()
                                return BuyFurniture:InvokeServer(itmSys, itmCat, itmKey)
                            end)
                            if bOk and bRes then
                                boughtCount = boughtCount + 1
                                anyBought = true
                            else
                                break
                            end
                            task.wait(0.08)
                        end
                        if boughtCount > 0 then
                            local _, fName = getItemDetails(itmSys, itmCat, itmKey)
                            local itemName = fName or itmKey
                            setActivity(string.format("🎯 Sniped %dx %s!", boughtCount, itemName), Color3.fromRGB(52, 199, 89))
                            if Config.WebhookAlertShop ~= false then
                                sendDiscordWebhookAlert("🛍️ Shop Auto-Bought Item!", string.format("Purchased **%dx %s** (`%s`) from Karinderya Shop.", boughtCount, itemName, tostring(itmKey)), 0x10B981)
                            end
                        end
                    end
                end
            end
        end
        if anyBought and updateShopStockShared then
            task.defer(function() updateShopStockShared(true) end)
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
        task.defer(function() doShopAutoBuy(true) end)
        if updateShopStockShared then task.defer(updateShopStockShared) end
    end))
end

--------------------------------------------------------------------------------
-- UPGRADES, MYSTERY BOX & APPLIANCE AUTOMATIONS
--------------------------------------------------------------------------------
do
    local BuyMysteryBox = Upg.BuyMysteryBox
    local GetMysteryBoxState = Upg.GetMysteryBoxState
    local MysteryBoxOpened = Upg.MysteryBoxOpened
    local BuyCounterUpgrade = Upg.BuyCounterUpgrade
    local EquipCounterUpgrade = Upg.EquipCounterUpgrade
    local GetMenuData = Upg.GetMenuData
    local GetExpansionInfo = Upg.GetExpansionInfo
    local StartExpansion = Upg.StartExpansion
    local GetGoldenSpatulaInfo = Upg.GetGoldenSpatulaInfo
    local PurchaseGoldenSpatula = Upg.PurchaseGoldenSpatula
    local CounterConfig = Upg.CounterConfig

    -- Mystery Box Drop Listener
    if MysteryBoxOpened then
        trackConn(MysteryBoxOpened.OnClientEvent:Connect(function(itemName)
            Hub.MysteryBoxesOpenedCount = (Hub.MysteryBoxesOpenedCount or 0) + 1
            Hub.LastMysteryBoxDrop = tostring(itemName)

            local itemStr = tostring(itemName)
            local rarity = "Common"
            local colorHex = 0x94A3B8
            if itemStr:find("Secret") then
                rarity = "Secret"
                colorHex = 0xEF4444
            elseif itemStr:find("Mythical") then
                rarity = "Mythical"
                colorHex = 0xEC4899
            elseif itemStr:find("Legendary") then
                rarity = "Legendary"
                colorHex = 0xF59E0B
            elseif itemStr:find("Epic") then
                rarity = "Epic"
                colorHex = 0xA855F7
            elseif itemStr:find("Rare") then
                rarity = "Rare"
                colorHex = 0x38BDF8
            end

            setActivity("Unboxed: " .. itemStr .. " [" .. rarity .. "]! 🎁", Color3.fromRGB(255, 215, 0))

            if Config.WebhookAlertMysteryBox then
                sendDiscordWebhookAlert(
                    "🎁 Mystery Box Unboxed!",
                    string.format("**Player:** %s\n**Item Awarded:** %s\n**Rarity:** %s\n**Total Opened:** %d",
                        LocalPlayer.DisplayName, itemStr, rarity, Hub.MysteryBoxesOpenedCount or 1
                    ),
                    colorHex
                )
            end
        end))
    end

    -- 1. Auto Open Delivered Mystery Boxes
    local function doAutoOpenMysteryBoxes()
        if not Config.MysteryBoxAutoOpen then return end
        local myPlot = getPlayerPlot()
        if not myPlot then return end
        local mystery = myPlot:FindFirstChild("Mystery")
        if not mystery then return end
        local place = mystery:FindFirstChild("MysteryPlace")
        if not place then return end

        local prompt = place:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt and prompt.Enabled and fireproximityprompt then
            pcall(function()
                fireproximityprompt(prompt)
            end)
        end
    end

    -- 2. Auto Order Mystery Boxes
    local isOrderingBox = false
    local lastOrderCheck = 0
    local function doAutoOrderMysteryBoxes()
        if not Config.MysteryBoxAutoOrder or isOrderingBox then return end
        if not BuyMysteryBox or not GetMysteryBoxState then return end
        local now = os.clock()
        if now - lastOrderCheck < 3 then return end
        lastOrderCheck = now

        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        local heartStat = leaderstats and leaderstats:FindFirstChild("Heart")
        local curHearts = (heartStat and heartStat.Value) or 0
        local reserve = tonumber(Config.MysteryBoxMinHearts) or 1
        local orderBatch = tonumber(Config.MysteryBoxOrderCount) or 5

        local maxAffordable = curHearts - reserve
        if maxAffordable < 1 then return end

        local toOrder = math.clamp(math.min(orderBatch, maxAffordable), 1, 5)

        isOrderingBox = true
        task.spawn(function()
            pcall(function()
                local state = GetMysteryBoxState:InvokeServer()
                if not state or (state.RemainingTime and state.RemainingTime <= 0) then
                    local ok, res = pcall(function()
                        return BuyMysteryBox:InvokeServer("Common", toOrder)
                    end)
                    if ok then
                        setActivity("Ordered " .. toOrder .. "x Mystery Boxes! 🎁", Color3.fromRGB(0, 180, 255))
                    end
                end
            end)
            task.wait(2)
            isOrderingBox = false
        end)
    end

    -- 3. Auto Counter Evolution & Equip
    local COUNTER_ORDER = {
        "Default", "RedWood", "ElegantWood", "Parsons", "SlatBack",
        "Royal", "Standard", "ObbyBaloyet", "BlackToo", "Futitoo"
    }
    local COUNTER_TIER_INDEX = {}
    for i, v in ipairs(COUNTER_ORDER) do COUNTER_TIER_INDEX[v] = i end

    local lastCounterCheck = 0
    local function doCounterEvolution()
        if not Config.AutoUpgradeCounter and not Config.AutoEquipCounter then return end
        if not GetMenuData then return end
        local now = os.clock()
        if now - lastCounterCheck < 4 then return end
        lastCounterCheck = now

        task.spawn(function()
            local ok, menuData = pcall(function()
                return GetMenuData:InvokeServer()
            end)
            if not ok or type(menuData) ~= "table" then return end

            local currentLevel = menuData.CounterLevel or "Default"
            Hub.CurrentCounterLevel = currentLevel
            local upgrades = menuData.CounterUpgrades or {}

            local upgrading = false
            local highestUnlocked = "Default"
            local highestIndex = 1

            for name, info in pairs(upgrades) do
                if info.IsUpgrading or (info.EndTime and info.EndTime > os.time()) then
                    upgrading = true
                end
                if info.Unlocked then
                    local idx = COUNTER_TIER_INDEX[name] or 1
                    if idx > highestIndex then
                        highestIndex = idx
                        highestUnlocked = name
                    end
                end
            end

            -- Auto Equip highest unlocked counter
            if Config.AutoEquipCounter and EquipCounterUpgrade and highestUnlocked ~= currentLevel then
                pcall(function()
                    EquipCounterUpgrade:InvokeServer(highestUnlocked)
                    Hub.CurrentCounterLevel = highestUnlocked
                    setActivity("Equipped Counter: " .. highestUnlocked .. " ✨", Color3.fromRGB(52, 199, 89))
                end)
            end

            -- Auto Upgrade to next tier if not currently upgrading
            if Config.AutoUpgradeCounter and not upgrading and BuyCounterUpgrade then
                local nextIdx = highestIndex + 1
                if nextIdx <= #COUNTER_ORDER then
                    local nextTier = COUNTER_ORDER[nextIdx]
                    local cfg = CounterConfig and CounterConfig[nextTier]
                    local cost = (cfg and cfg.Cost) or 0
                    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
                    local curCash = (leaderstats and leaderstats:FindFirstChild("Cash") and leaderstats.Cash.Value) or 0

                    if curCash >= cost and cost > 0 then
                        local buyOk = pcall(function()
                            return BuyCounterUpgrade:InvokeServer(nextTier)
                        end)
                        if buyOk then
                            setActivity("Upgrading Counter to " .. nextTier .. " (₱" .. formatNumber(cost) .. ")! 🔨", Color3.fromRGB(255, 200, 0))
                            if Config.WebhookEnabled then
                                sendDiscordWebhookAlert(
                                    "🔨 Counter Upgrade Started!",
                                    "**Upgrading to:** " .. nextTier .. "\n**Cost:** ₱" .. formatNumber(cost),
                                    0xF59E0B
                                )
                            end
                        end
                    end
                end
            end
        end)
    end

    -- 4. Auto Repair Chiller
    local lastChillerCheck = 0
    local function doAutoRepairChiller()
        if not Config.AutoRepairChiller then return end
        if not StartExpansion then return end
        local now = os.clock()
        if now - lastChillerCheck < 5 then return end
        lastChillerCheck = now

        local myPlot = getPlayerPlot()
        if not myPlot then return end
        local soft = myPlot:FindFirstChild("Softdrinks")
        local chiller = soft and soft:FindFirstChild("Chiller")
        if not chiller then return end

        task.spawn(function()
            local ok, info = pcall(function()
                if GetExpansionInfo then
                    return GetExpansionInfo:InvokeServer(chiller)
                end
                return nil
            end)

            if ok and type(info) == "table" then
                if info.IsRepaired == false and (info.RemainingSeconds or 0) <= 0 then
                    Hub.ChillerStatus = "Broken"
                    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
                    local curCash = (leaderstats and leaderstats:FindFirstChild("Cash") and leaderstats.Cash.Value) or 0
                    local cost = info.Cost or 200000
                    if curCash >= cost then
                        pcall(function()
                            StartExpansion:InvokeServer(chiller)
                            Hub.ChillerStatus = "Repairing"
                            setActivity("Repaired Chiller (₱" .. formatNumber(cost) .. ")! ❄️", Color3.fromRGB(0, 200, 255))
                            if Config.WebhookEnabled then
                                sendDiscordWebhookAlert("❄️ Chiller Repair Dispatched!", "Dispatched krazy builder to repair softdrinks chiller!", 0x38BDF8)
                            end
                        end)
                    end
                elseif info.RemainingSeconds and info.RemainingSeconds > 0 then
                    Hub.ChillerStatus = "Repairing (" .. math.ceil(info.RemainingSeconds / 60) .. "m)"
                else
                    Hub.ChillerStatus = "Working"
                end
            end
        end)
    end

    -- 5. Golden Spatula Sniper
    local lastSpatulaCheck = 0
    local function doGoldenSpatulaSniper()
        if not Config.AutoBuyGoldenSpatula then return end
        if not GetGoldenSpatulaInfo or not PurchaseGoldenSpatula then return end
        local now = os.clock()
        if now - lastSpatulaCheck < 10 then return end
        lastSpatulaCheck = now

        task.spawn(function()
            local ok, info = pcall(function()
                return GetGoldenSpatulaInfo:InvokeServer()
            end)
            if ok and type(info) == "table" then
                if info.EventActive and not info.Owned then
                    Hub.GoldenSpatulaStatus = "ACTIVE!"
                    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
                    local curCash = (leaderstats and leaderstats:FindFirstChild("Cash") and leaderstats.Cash.Value) or 0
                    local cost = info.Cost or 350000
                    if curCash >= cost then
                        pcall(function()
                            local buyOk = PurchaseGoldenSpatula:InvokeServer()
                            if buyOk then
                                setActivity("Sniped Golden Spatula! 🌟", Color3.fromRGB(255, 215, 0))
                                sendDiscordWebhookAlert("🌟 Golden Spatula Acquired!", "Purchased exclusive event Golden Spatula for ₱" .. formatNumber(cost) .. "!", 0xF59E0B)
                            end
                        end)
                    end
                else
                    Hub.GoldenSpatulaStatus = info.Owned and "Owned" or "Inactive"
                end
            end
        end)
    end

    -- Dedicated Upgrades & Appliances Background Loop
    spawnLoop(1.2, function()
        if Config.MysteryBoxAutoOpen then doAutoOpenMysteryBoxes() end
        if Config.MysteryBoxAutoOrder then doAutoOrderMysteryBoxes() end
        if Config.AutoUpgradeCounter or Config.AutoEquipCounter then doCounterEvolution() end
        if Config.AutoRepairChiller then doAutoRepairChiller() end
        if Config.AutoBuyGoldenSpatula then doGoldenSpatulaSniper() end
    end)
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
    doShopAutoBuy(false)

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
local oldGui = targetParent:FindFirstChild("KarinderyaHub_UI")
if oldGui then
    pcall(function() oldGui:Destroy() end)
end
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

-- Main Container Window (Apple Liquid Glass Modal & Responsive Container)
local mainWindow
local contentHolder
local sidebar
local statusBar
local switchTab
local createTabButton
local createGlassChip
do
    mainWindow = Instance.new("Frame")
    mainWindow.Name = "MainWindow"
    mainWindow.Size = UDim2.new(0, 620, 0, 420)
    mainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
    mainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainWindow.BackgroundColor3 = C_BG
    mainWindow.BackgroundTransparency = 0.12
    mainWindow.BorderSizePixel = 0
    mainWindow.ClipsDescendants = false
    mainWindow.Parent = screenGui


-- Responsive Multi-Device Scaling Engine (Desktop, Tablet, Mobile)
local uiScale = Instance.new("UIScale")
uiScale.Name = "HubScale"
uiScale.Parent = mainWindow

local function updateResponsiveScale()
    local cam = Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local width = vp.X
    local height = vp.Y
    
    local scaleFactor = 1.0
    if width < 700 or height < 480 then
        -- Mobile screens (smartphones in portrait / compact landscape)
        scaleFactor = math.clamp(math.min(width / 660, height / 460), 0.55, 0.82)
    elseif width < 1050 or height < 650 then
        -- Tablets & small laptops
        scaleFactor = math.clamp(math.min(width / 880, height / 580), 0.80, 0.96)
    else
        -- Desktop & high-resolution displays
        scaleFactor = math.clamp(math.min(width / 1366, height / 768), 0.95, 1.15)
    end
    uiScale.Scale = scaleFactor
end

updateResponsiveScale()
if Workspace.CurrentCamera then
    trackConn(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale))
end

do
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
end

-- Title Bar Header (Translucent Frosted Glass)
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = C_HEADER
header.BackgroundTransparency = 0.35
header.BorderSizePixel = 0
header.Parent = mainWindow

do
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

-- Title Label (Apple SF Pro Typography)
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Text = "Karinderya by Kiri"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0, 48, 0, 0)
titleLabel.Size = UDim2.new(1, -380, 1, 0)
titleLabel.Parent = header

-- 1. Live Balance Transparent Chip (Warm Gold Liquid Glass Pill)
local statPill = Instance.new("Frame")
statPill.Name = "StatPill"
statPill.Size = UDim2.new(0, 114, 0, 24)
statPill.Position = UDim2.new(1, -325, 0.5, -12)
statPill.BackgroundColor3 = Color3.fromRGB(255, 214, 10)
statPill.BackgroundTransparency = 0.92
statPill.BorderSizePixel = 0
statPill.Parent = header

local statCorner = Instance.new("UICorner")
statCorner.CornerRadius = UDim.new(1, 0)
statCorner.Parent = statPill

local statStroke = Instance.new("UIStroke")
statStroke.Thickness = 1
statStroke.Color = Color3.fromRGB(255, 214, 10)
statStroke.Transparency = 0.60
statStroke.Parent = statPill

local cashBadge = Instance.new("TextLabel")
cashBadge.Name = "CashBadge"
cashBadge.Text = "₱0"
cashBadge.Font = Enum.Font.GothamBold
cashBadge.TextSize = 11
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

-- 2. Live Status Transparent Chip (Emerald Liquid Glass Pill)
local statusChip = Instance.new("Frame")
statusChip.Name = "HeaderStatusChip"
statusChip.Size = UDim2.new(0, 96, 0, 24)
statusChip.Position = UDim2.new(1, -204, 0.5, -12)
statusChip.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
statusChip.BackgroundTransparency = 0.92
statusChip.BorderSizePixel = 0
statusChip.Parent = header

local statusChipCorner = Instance.new("UICorner")
statusChipCorner.CornerRadius = UDim.new(1, 0)
statusChipCorner.Parent = statusChip

local statusChipStroke = Instance.new("UIStroke")
statusChipStroke.Thickness = 1
statusChipStroke.Color = Color3.fromRGB(52, 199, 89)
statusChipStroke.Transparency = 0.60
statusChipStroke.Parent = statusChip
Hub.HeaderStatusStroke = statusChipStroke

local headerStatusDot = Instance.new("TextLabel")
headerStatusDot.Name = "Dot"
headerStatusDot.Text = "●"
headerStatusDot.Font = Enum.Font.GothamBold
headerStatusDot.TextSize = 11
headerStatusDot.TextColor3 = Color3.fromRGB(52, 199, 89)
headerStatusDot.Size = UDim2.new(0, 14, 1, 0)
headerStatusDot.Position = UDim2.new(0, 6, 0, 0)
headerStatusDot.BackgroundTransparency = 1
headerStatusDot.Parent = statusChip
Hub.HeaderStatusDot = headerStatusDot

local headerStatusLabel = Instance.new("TextLabel")
headerStatusLabel.Name = "StatusLabel"
headerStatusLabel.Text = "Active"
headerStatusLabel.Font = Enum.Font.GothamBold
headerStatusLabel.TextSize = 10
headerStatusLabel.TextColor3 = Color3.fromRGB(240, 250, 245)
headerStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
headerStatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
headerStatusLabel.Size = UDim2.new(1, -24, 1, 0)
headerStatusLabel.Position = UDim2.new(0, 20, 0, 0)
headerStatusLabel.BackgroundTransparency = 1
headerStatusLabel.Parent = statusChip
Hub.HeaderStatusLabel = headerStatusLabel

-- Header Controls (Right - Apple Traffic Lights)
local headerControls = Instance.new("Frame")
headerControls.Name = "HeaderControls"
headerControls.BackgroundTransparency = 1
headerControls.Size = UDim2.new(0, 95, 1, 0)
headerControls.Position = UDim2.new(1, -100, 0, 0)
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
            Size = UDim2.new(0, 620, 0, 44)
        }):Play()
    else
        TweenService:Create(mainWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 620, 0, 420)
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
end

-- Window Dragging Functionality (Scale-Aware for All Devices)
do
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
            local currentScale = (uiScale and uiScale.Scale) or 1
            local delta = (input.Position - dragStart) / currentScale
            mainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Sidebar Navigation (Left) - Scrollable Liquid Glass Navigation
sidebar = Instance.new("ScrollingFrame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 130, 1, -88)
sidebar.Position = UDim2.new(0, 10, 0, 48)
sidebar.BackgroundTransparency = 1
sidebar.ScrollBarThickness = 0
sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
sidebar.BorderSizePixel = 0
sidebar.Parent = mainWindow

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.FillDirection = Enum.FillDirection.Vertical
sidebarLayout.Padding = UDim.new(0, 8)
sidebarLayout.Parent = sidebar

-- Tab Pages Container
contentHolder = Instance.new("Frame")
contentHolder.Name = "ContentHolder"
contentHolder.Size = UDim2.new(1, -156, 1, -88)
contentHolder.Position = UDim2.new(0, 146, 0, 48)
contentHolder.BackgroundTransparency = 1
contentHolder.Parent = mainWindow

-- Bottom Status Bar (Liquid Glass Telemetry Dock with Transparent Chips)
statusBar = Instance.new("Frame")
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(1, -20, 0, 28)
statusBar.Position = UDim2.new(0, 10, 1, -34)
statusBar.BackgroundColor3 = Color3.fromRGB(18, 24, 36)
statusBar.BackgroundTransparency = 0.45
statusBar.BorderSizePixel = 0
statusBar.Parent = mainWindow

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(1, 0)
statusCorner.Parent = statusBar

applyGlassStroke(statusBar, 1.1, 0.35, 0.85)

local dockScroll = Instance.new("ScrollingFrame")
dockScroll.Name = "DockScroll"
dockScroll.Size = UDim2.new(1, -12, 1, 0)
dockScroll.Position = UDim2.new(0, 6, 0, 0)
dockScroll.BackgroundTransparency = 1
dockScroll.BorderSizePixel = 0
dockScroll.ScrollBarThickness = 0
dockScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
dockScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
dockScroll.Parent = statusBar

local dockList = Instance.new("UIListLayout")
dockList.FillDirection = Enum.FillDirection.Horizontal
dockList.VerticalAlignment = Enum.VerticalAlignment.Center
dockList.Padding = UDim.new(0, 6)
dockList.Parent = dockScroll

-- Reusable Transparent Glass Chip Factory
createGlassChip = function(text, textColor, strokeColor, bgTrans, parent)
    local chip = Instance.new("Frame")
    chip.Name = "Chip_" .. text
    chip.Size = UDim2.new(0, 0, 0, 20)
    chip.AutomaticSize = Enum.AutomaticSize.X
    chip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    chip.BackgroundTransparency = bgTrans or 0.92
    chip.BorderSizePixel = 0
    if parent then chip.Parent = parent end

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = chip

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = strokeColor or Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.68
    stroke.Parent = chip

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = chip

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = textColor or Color3.fromRGB(240, 245, 255)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Parent = chip

    return chip, lbl, stroke
end

-- Telemetry Transparent Chips inside Bottom Dock
local dockStatusChip, dockStatusLbl, dockStatusStroke = createGlassChip("● Idle", Color3.fromRGB(52, 199, 89), Color3.fromRGB(52, 199, 89), 0.90, dockScroll)
Hub.StatusLabel = dockStatusLbl
Hub.StatusDot = nil

local dockThievesChip, dockThievesVal = createGlassChip("💥 Thieves: 0", Color3.fromRGB(244, 114, 182), Color3.fromRGB(244, 114, 182), 0.92, dockScroll)
Hub.DockThievesVal = dockThievesVal

local dockWokenChip, dockWokenVal = createGlassChip("💤 Woken: 0", Color3.fromRGB(168, 85, 247), Color3.fromRGB(168, 85, 247), 0.92, dockScroll)
Hub.DockWorkersVal = dockWokenVal

local dockTrashChip, dockTrashVal = createGlassChip("🧹 Trash: 0", Color3.fromRGB(56, 189, 248), Color3.fromRGB(56, 189, 248), 0.92, dockScroll)
Hub.DockTrashVal = dockTrashVal

local dockProfitChip, dockProfitVal = createGlassChip("📈 Profit: +₱0", Color3.fromRGB(52, 225, 100), Color3.fromRGB(52, 225, 100), 0.92, dockScroll)
Hub.DockProfitVal = dockProfitVal

local tabButtons = {}
local tabPages = {}

switchTab = function(tabName)
    for name, page in pairs(tabPages) do
        page.Visible = (name == tabName)
    end
    for name, btn in pairs(tabButtons) do
        local isActive = (name == tabName)
        btn:SetAttribute("Active", isActive)
        local stroke = btn:FindFirstChild("TabStroke")
        local glow = btn:FindFirstChild("TabGlow")
        if glow then glow.Enabled = isActive end
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

createTabButton = function(name)
    local btn = Instance.new("TextButton")
    btn.Name = "Tab_" .. name
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 0.94
    btn.TextColor3 = Color3.fromRGB(170, 185, 210)
    btn.AutoButtonColor = false
    btn.Parent = sidebar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Name = "TabStroke"
    stroke.Thickness = 1.1
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.88
    stroke.Parent = btn

    local glow = Instance.new("UIGradient")
    glow.Name = "TabGlow"
    glow.Rotation = 90
    glow.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 115, 235)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 255))
    })
    glow.Enabled = false
    glow.Parent = btn

    btn.MouseEnter:Connect(function()
        if not (btn:GetAttribute("Active")) then
            TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundTransparency = 0.88 }):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if not (btn:GetAttribute("Active")) then
            TweenService:Create(btn, TweenInfo.new(0.18), { BackgroundTransparency = 0.94 }):Play()
        end
    end)

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
end

--------------------------------------------------------------------------------
-- TAB PAGES INITIALIZATION
--------------------------------------------------------------------------------
local mainPage = createTabButton("Main")
local upgradesPage = createTabButton("Upgrades")
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
-- UPGRADES & APPLIANCES TAB
--------------------------------------------------------------------------------
do
    local upgColumnsLayout = Instance.new("UIListLayout")
    upgColumnsLayout.FillDirection = Enum.FillDirection.Horizontal
    upgColumnsLayout.Padding = UDim.new(0, 10)
    upgColumnsLayout.Parent = upgradesPage

    -- 1. Left Card: "Mystery Box & Drops"
    local mysteryRows = createCard("Mystery Box & Drops", upgradesPage)

    local mysteryStatusRow = Instance.new("Frame")
    mysteryStatusRow.Name = "MysteryStatusRow"
    mysteryStatusRow.Size = UDim2.new(1, 0, 0, 52)
    mysteryStatusRow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    mysteryStatusRow.BackgroundTransparency = 0.94
    mysteryStatusRow.BorderSizePixel = 0
    mysteryStatusRow.Parent = mysteryRows

    local msCorner = Instance.new("UICorner")
    msCorner.CornerRadius = UDim.new(0, 8)
    msCorner.Parent = mysteryStatusRow

    local msStroke = Instance.new("UIStroke")
    msStroke.Thickness = 1
    msStroke.Color = Color3.fromRGB(255, 255, 255)
    msStroke.Transparency = 0.9
    msStroke.Parent = mysteryStatusRow

    local mysteryStatusLabel = Instance.new("TextLabel")
    mysteryStatusLabel.Name = "MysteryStatusLabel"
    mysteryStatusLabel.RichText = true
    mysteryStatusLabel.Font = Enum.Font.GothamMedium
    mysteryStatusLabel.TextSize = 11
    mysteryStatusLabel.TextColor3 = Color3.fromRGB(200, 215, 235)
    mysteryStatusLabel.Size = UDim2.new(1, -16, 1, 0)
    mysteryStatusLabel.Position = UDim2.new(0, 8, 0, 0)
    mysteryStatusLabel.TextWrapped = true
    mysteryStatusLabel.BackgroundTransparency = 1
    mysteryStatusLabel.Text = "📦 <b>Boxes on Plot:</b> ... | <b>Total Opened:</b> 0\n🎁 <b>Latest Drop:</b> None"
    mysteryStatusLabel.Parent = mysteryStatusRow

    createToggleRow("Auto Open Delivered Boxes", Config.MysteryBoxAutoOpen, function(v)
        Config.MysteryBoxAutoOpen = v
        saveWebhookConfig()
        setActivity(v and "Auto Open Mystery Boxes ON 📦" or "Auto Open OFF", Color3.fromRGB(52, 199, 89))
    end, mysteryRows)

    createToggleRow("Auto Order Mystery Boxes", Config.MysteryBoxAutoOrder, function(v)
        Config.MysteryBoxAutoOrder = v
        saveWebhookConfig()
        setActivity(v and "Auto Order Mystery Boxes ON 🎁" or "Auto Order OFF", Color3.fromRGB(0, 180, 255))
    end, mysteryRows)

    createValueCycleRow("Order Batch Size", tostring(Config.MysteryBoxOrderCount or 5) .. " Boxes", { "1 Box", "2 Boxes", "3 Boxes", "5 Boxes" }, function(v)
        local num = tonumber(v:match("%d+")) or 5
        Config.MysteryBoxOrderCount = num
        saveWebhookConfig()
    end, mysteryRows)

    createValueCycleRow("Min Hearts Reserve", "Keep ≥ " .. tostring(Config.MysteryBoxMinHearts or 1) .. " ❤️", { "Keep ≥ 0 ❤️", "Keep ≥ 1 ❤️", "Keep ≥ 3 ❤️", "Keep ≥ 5 ❤️" }, function(v)
        local num = tonumber(v:match("%d+")) or 1
        Config.MysteryBoxMinHearts = num
        saveWebhookConfig()
    end, mysteryRows)

    createToggleRow("Webhook Alerts on Drops", Config.WebhookAlertMysteryBox, function(v)
        Config.WebhookAlertMysteryBox = v
        saveWebhookConfig()
    end, mysteryRows)

    createButtonRow("Open All Boxes Now", "Open Now 📦", Color3.fromRGB(52, 199, 89), function(btn)
        btn.Text = "Opening..."
        task.spawn(function()
            local plot = getPlayerPlot()
            if plot and plot:FindFirstChild("Mystery") and plot.Mystery:FindFirstChild("MysteryPlace") then
                local p = plot.Mystery.MysteryPlace:FindFirstChildWhichIsA("ProximityPrompt")
                if p and fireproximityprompt then
                    for i = 1, 5 do
                        pcall(function() fireproximityprompt(p) end)
                        task.wait(0.12)
                    end
                end
            end
            task.wait(0.5)
            btn.Text = "Open Now 📦"
        end, mysteryRows)
    end, mysteryRows)

    createButtonRow("Order 5x Boxes Now", "Order (5 ❤️)", Color3.fromRGB(14, 115, 235), function(btn)
        btn.Text = "Ordering..."
        task.spawn(function()
            if BuyMysteryBox then
                pcall(function() BuyMysteryBox:InvokeServer("Common", 5) end)
            end
            task.wait(0.8)
            btn.Text = "Order (5 ❤️)"
        end)
    end, mysteryRows)

    -- 2. Right Card: "Counter & Appliances"
    local applianceRows = createCard("Counter & Appliances", upgradesPage)

    local applianceStatusRow = Instance.new("Frame")
    applianceStatusRow.Name = "ApplianceStatusRow"
    applianceStatusRow.Size = UDim2.new(1, 0, 0, 52)
    applianceStatusRow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    applianceStatusRow.BackgroundTransparency = 0.94
    applianceStatusRow.BorderSizePixel = 0
    applianceStatusRow.Parent = applianceRows

    local asCorner = Instance.new("UICorner")
    asCorner.CornerRadius = UDim.new(0, 8)
    asCorner.Parent = applianceStatusRow

    local asStroke = Instance.new("UIStroke")
    asStroke.Thickness = 1
    asStroke.Color = Color3.fromRGB(255, 255, 255)
    asStroke.Transparency = 0.9
    asStroke.Parent = applianceStatusRow

    local applianceStatusLabel = Instance.new("TextLabel")
    applianceStatusLabel.Name = "ApplianceStatusLabel"
    applianceStatusLabel.RichText = true
    applianceStatusLabel.Font = Enum.Font.GothamMedium
    applianceStatusLabel.TextSize = 11
    applianceStatusLabel.TextColor3 = Color3.fromRGB(200, 215, 235)
    applianceStatusLabel.Size = UDim2.new(1, -16, 1, 0)
    applianceStatusLabel.Position = UDim2.new(0, 8, 0, 0)
    applianceStatusLabel.TextWrapped = true
    applianceStatusLabel.BackgroundTransparency = 1
    applianceStatusLabel.Text = "🔨 <b>Counter Tier:</b> ...\n❄️ <b>Chiller:</b> ... | 🌟 <b>Spatula:</b> ..."
    applianceStatusLabel.Parent = applianceStatusRow

    createToggleRow("Auto Upgrade Counter", Config.AutoUpgradeCounter, function(v)
        Config.AutoUpgradeCounter = v
        saveWebhookConfig()
        setActivity(v and "Auto Upgrade Counter ON 🔨" or "Auto Upgrade Counter OFF", Color3.fromRGB(255, 200, 0))
    end, applianceRows)

    createToggleRow("Auto Equip Best Counter", Config.AutoEquipCounter, function(v)
        Config.AutoEquipCounter = v
        saveWebhookConfig()
    end, applianceRows)

    createToggleRow("Auto Repair Chiller (₱200k)", Config.AutoRepairChiller, function(v)
        Config.AutoRepairChiller = v
        saveWebhookConfig()
        setActivity(v and "Auto Repair Chiller ON ❄️" or "Auto Repair Chiller OFF", Color3.fromRGB(0, 200, 255))
    end, applianceRows)

    createToggleRow("Golden Spatula Sniper (₱350k)", Config.AutoBuyGoldenSpatula, function(v)
        Config.AutoBuyGoldenSpatula = v
        saveWebhookConfig()
    end, applianceRows)

    createButtonRow("Repair Chiller Now", "Repair ❄️", Color3.fromRGB(0, 180, 255), function(btn)
        btn.Text = "Repairing..."
        task.spawn(function()
            local plot = getPlayerPlot()
            local chiller = plot and plot:FindFirstChild("Softdrinks") and plot.Softdrinks:FindFirstChild("Chiller")
            if chiller and StartExpansion then
                pcall(function() StartExpansion:InvokeServer(chiller) end)
            end
            task.wait(1)
            btn.Text = "Repair ❄️"
        end)
    end, applianceRows)

    createButtonRow("Check Spatula Event", "Check 🌟", Color3.fromRGB(245, 158, 11), function(btn)
        btn.Text = "Checking..."
        task.spawn(function()
            if GetGoldenSpatulaInfo then
                local ok, info = pcall(function() return GetGoldenSpatulaInfo:InvokeServer() end)
                if ok and type(info) == "table" then
                    Hub.GoldenSpatulaStatus = info.EventActive and "ACTIVE!" or (info.Owned and "Owned" or "Inactive")
                    setActivity(info.EventActive and "Golden Spatula Event ACTIVE! 🌟" or "Spatula Event Inactive", Color3.fromRGB(255, 215, 0))
                end
            end
            task.wait(1)
            btn.Text = "Check 🌟"
        end)
    end, applianceRows)

    -- Telemetry update loop for Upgrades Tab
    task.spawn(function()
        while Hub.Running do
            pcall(function()
                local plot = getPlayerPlot()
                local boxCount = 0
                if plot and plot:FindFirstChild("Mystery") then
                    for _, c in ipairs(plot.Mystery:GetChildren()) do
                        if c.Name:find("Box") then boxCount = boxCount + 1 end
                    end
                end
                local dropText = Hub.LastMysteryBoxDrop or "None"
                local dropColor = "#38BDF8"
                if dropText:find("Secret") then dropColor = "#EF4444"
                elseif dropText:find("Mythical") then dropColor = "#EC4899"
                elseif dropText:find("Legendary") then dropColor = "#F59E0B"
                elseif dropText:find("Epic") then dropColor = "#A855F7" end

                mysteryStatusLabel.Text = string.format(
                    "📦 <b>Boxes on Plot:</b> <font color='#34C759'>%d</font> | <b>Total Opened:</b> %d\n🎁 <b>Latest Drop:</b> <font color='%s'>%s</font>",
                    boxCount, Hub.MysteryBoxesOpenedCount or 0, dropColor, dropText
                )

                local cTier = Hub.CurrentCounterLevel or "Default"
                local chStatus = Hub.ChillerStatus or "Working"
                local chColor = (chStatus == "Working") and "#34C759" or (chStatus:find("Repair") and "#F59E0B" or "#FF453A")
                local spColor = (Hub.GoldenSpatulaStatus == "ACTIVE!") and "#F59E0B" or "#94A3B8"

                applianceStatusLabel.Text = string.format(
                    "🔨 <b>Counter Tier:</b> <font color='#00B4FF'>%s</font>\n❄️ <b>Chiller:</b> <font color='%s'>%s</font> | 🌟 <b>Spatula:</b> <font color='%s'>%s</font>",
                    cTier, chColor, chStatus, spColor, Hub.GoldenSpatulaStatus or "Inactive"
                )
            end)
            task.wait(1.5)
        end
    end)
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
        nameLabel.Size = UDim2.new(1, -118, 1, 0)
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
        priceLabel.Size = UDim2.new(0, 52, 1, 0)
        priceLabel.Position = UDim2.new(1, -112, 0, 0)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Parent = rowBtn

        -- Transparent Liquid Glass Stock Chip
        local pctChip = Instance.new("Frame")
        pctChip.Name = "PctChip"
        pctChip.Size = UDim2.new(0, 48, 0, 22)
        pctChip.Position = UDim2.new(1, -54, 0.5, -11)
        pctChip.BackgroundColor3 = getPctColor(pct)
        pctChip.BackgroundTransparency = 0.88
        pctChip.BorderSizePixel = 0
        pctChip.Parent = rowBtn

        local pctCorner = Instance.new("UICorner")
        pctCorner.CornerRadius = UDim.new(1, 0)
        pctCorner.Parent = pctChip

        local pctStroke = Instance.new("UIStroke")
        pctStroke.Thickness = 1
        pctStroke.Color = getPctColor(pct)
        pctStroke.Transparency = 0.55
        pctStroke.Parent = pctChip

        local pctLabel = Instance.new("TextLabel")
        pctLabel.Name = "Pct"
        pctLabel.Text = tostring(pct) .. "%"
        pctLabel.Font = Enum.Font.GothamBold
        pctLabel.TextSize = 10
        pctLabel.TextColor3 = getPctColor(pct)
        pctLabel.TextXAlignment = Enum.TextXAlignment.Center
        pctLabel.Size = UDim2.new(1, 0, 1, 0)
        pctLabel.BackgroundTransparency = 1
        pctLabel.Parent = pctChip

        rowBtn.MouseButton1Click:Connect(function()
            if BuyIngredient then
                task.spawn(function()
                    pcall(function()
                        BuyIngredient:InvokeServer(key, 1, "Cash")
                    end)
                    local cur, mx, p = getStockInfo(key, data)
                    local pCol = getPctColor(p)
                    pctLabel.Text = tostring(p) .. "%"
                    pctLabel.TextColor3 = pCol
                    pctChip.BackgroundColor3 = pCol
                    pctStroke.Color = pCol
                    setActivity("Bought 1x " .. (data.Name or key) .. (cost > 0 and (" (₱" .. formatNumber(cost) .. ")") or ""), Color3.fromRGB(52, 199, 89))
                end)
            end
        end)

        groceryItemRows[key] = { Frame = rowBtn, PctLabel = pctLabel, PctChip = pctChip, PctStroke = pctStroke, PriceLabel = priceLabel, Key = key, Data = data }
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
    -- Category metadata helper
    local function getCategoryMeta(catName)
        local c = string.lower(tostring(catName or ""))
        if c == "stoves" or c == "stove" then
            return "🔥", "Stoves", Color3.fromRGB(249, 115, 22), Color3.fromRGB(251, 146, 60), "Stove"
        elseif c == "paints" or c == "paint" then
            return "🎨", "Paints", Color3.fromRGB(168, 85, 247), Color3.fromRGB(192, 132, 252), "Paint"
        elseif c == "materials" or c == "material" then
            return "🧱", "Materials", Color3.fromRGB(34, 197, 94), Color3.fromRGB(74, 222, 128), "Material"
        elseif c == "tables" or c == "table" then
            return "🪵", "Tables", Color3.fromRGB(245, 158, 11), Color3.fromRGB(251, 191, 36), "Table"
        elseif c == "chairs" or c == "chair" then
            return "🪑", "Chairs", Color3.fromRGB(59, 130, 246), Color3.fromRGB(96, 165, 250), "Chair"
        elseif c == "tiles" or c == "tile" then
            return "🧊", "Tiles", Color3.fromRGB(6, 182, 212), Color3.fromRGB(103, 232, 249), "Tile"
        end
        return "📦", catName or "Other", Color3.fromRGB(148, 163, 184), Color3.fromRGB(203, 213, 225), catName or "Item"
    end

    local DEFAULT_CATEGORIES = {
        { Id = "All", Label = "All", Icon = "🌐" },
        { Id = "Stoves", Label = "Stoves", Icon = "🔥" },
        { Id = "Paints", Label = "Paints", Icon = "🎨" },
        { Id = "Materials", Label = "Materials", Icon = "🧱" },
        { Id = "Tables", Label = "Tables", Icon = "🪵" },
        { Id = "Chairs", Label = "Chairs", Icon = "🪑" },
        { Id = "Tiles", Label = "Tiles", Icon = "🧊" },
    }

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
    shopLabel.Size = UDim2.new(0, 38, 1, 0)
    shopLabel.BackgroundTransparency = 1
    shopLabel.Parent = shopFooter

    -- Dropdown Button for Shop (Opens In-Stock Items Dialog)
    local shopDropdownBtn = Instance.new("TextButton")
    shopDropdownBtn.Name = "ShopDropdownBtn"
    shopDropdownBtn.Text = "📦 Stock  ▼"
    shopDropdownBtn.Font = Enum.Font.GothamBold
    shopDropdownBtn.TextSize = 11
    shopDropdownBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
    shopDropdownBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    shopDropdownBtn.BackgroundTransparency = 0.93
    shopDropdownBtn.Size = UDim2.new(0, 85, 0, 28)
    shopDropdownBtn.Position = UDim2.new(0, 42, 0.5, -14)
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

    -- Timer Pill in ShopFooter (Live Countdown)
    local shopTimerPill = Instance.new("TextLabel")
    shopTimerPill.Name = "ShopTimerPill"
    shopTimerPill.Text = "⏱️ --:--"
    shopTimerPill.Font = Enum.Font.GothamBold
    shopTimerPill.TextSize = 11
    shopTimerPill.TextColor3 = Color3.fromRGB(56, 189, 248)
    shopTimerPill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    shopTimerPill.BackgroundTransparency = 0.93
    shopTimerPill.Size = UDim2.new(0, 92, 0, 28)
    shopTimerPill.Position = UDim2.new(0, 132, 0.5, -14)
    shopTimerPill.Parent = shopFooter

    local sTimerCorner = Instance.new("UICorner")
    sTimerCorner.CornerRadius = UDim.new(0, 8)
    sTimerCorner.Parent = shopTimerPill

    local sTimerStroke = Instance.new("UIStroke")
    sTimerStroke.Color = Color3.fromRGB(56, 189, 248)
    sTimerStroke.Transparency = 0.8
    sTimerStroke.Thickness = 1
    sTimerStroke.Parent = shopTimerPill

    -- Refresh Button
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Name = "RefreshBtn"
    refreshBtn.Text = "Refresh"
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 11
    refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
    refreshBtn.BackgroundTransparency = 0.15
    refreshBtn.Size = UDim2.new(0, 56, 0, 28)
    refreshBtn.Position = UDim2.new(0, 228, 0.5, -14)
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

    -- Buy Stock Button
    local buyStockBtn = Instance.new("TextButton")
    buyStockBtn.Name = "BuyStockBtn"
    buyStockBtn.Text = "Buy All"
    buyStockBtn.Font = Enum.Font.GothamBold
    buyStockBtn.TextSize = 11
    buyStockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyStockBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
    buyStockBtn.BackgroundTransparency = 0.15
    buyStockBtn.Size = UDim2.new(0, 60, 0, 28)
    buyStockBtn.Position = UDim2.new(0, 288, 0.5, -14)
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

    -- Shop Auto Buy Mode Toggle Button (Targets Only vs All Stock)
    local shopAutoModeBtn = Instance.new("TextButton")
    shopAutoModeBtn.Name = "ShopAutoModeBtn"
    shopAutoModeBtn.Text = Config.ShopAutoBuyTargetsOnly and "🎯 Targets" or "📦 All Stock"
    shopAutoModeBtn.Font = Enum.Font.GothamBold
    shopAutoModeBtn.TextSize = 10
    shopAutoModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    shopAutoModeBtn.BackgroundColor3 = Config.ShopAutoBuyTargetsOnly and Color3.fromRGB(245, 158, 11) or Color3.fromRGB(10, 132, 255)
    shopAutoModeBtn.BackgroundTransparency = 0.2
    shopAutoModeBtn.Size = UDim2.new(0, 84, 0, 28)
    shopAutoModeBtn.Position = UDim2.new(1, -164, 0.5, -14)
    shopAutoModeBtn.AutoButtonColor = true
    shopAutoModeBtn.Parent = shopFooter

    local sModeCorner = Instance.new("UICorner")
    sModeCorner.CornerRadius = UDim.new(0, 8)
    sModeCorner.Parent = shopAutoModeBtn

    local sModeStroke = Instance.new("UIStroke")
    sModeStroke.Color = Config.ShopAutoBuyTargetsOnly and Color3.fromRGB(251, 191, 36) or Color3.fromRGB(120, 200, 255)
    sModeStroke.Transparency = 0.5
    sModeStroke.Thickness = 1
    sModeStroke.Parent = shopAutoModeBtn

    shopAutoModeBtn.MouseButton1Click:Connect(function()
        Config.ShopAutoBuyTargetsOnly = not Config.ShopAutoBuyTargetsOnly
        saveWebhookConfig()
        shopAutoModeBtn.Text = Config.ShopAutoBuyTargetsOnly and "🎯 Targets" or "📦 All Stock"
        TweenService:Create(shopAutoModeBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Config.ShopAutoBuyTargetsOnly and Color3.fromRGB(245, 158, 11) or Color3.fromRGB(10, 132, 255),
        }):Play()
        TweenService:Create(sModeStroke, TweenInfo.new(0.2), {
            Color = Config.ShopAutoBuyTargetsOnly and Color3.fromRGB(251, 191, 36) or Color3.fromRGB(120, 200, 255),
        }):Play()
        setActivity("Auto-Buy Mode: " .. (Config.ShopAutoBuyTargetsOnly and "Targets Only" or "All Category Stock"), Color3.fromRGB(245, 158, 11))
    end)

    -- Shop Auto Buy Toggle Button
    local shopAutoBuyBtn = Instance.new("TextButton")
    shopAutoBuyBtn.Name = "ShopAutoBuyBtn"
    shopAutoBuyBtn.Text = Config.ShopAutoBuy and "Auto: ON" or "Auto: OFF"
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
        saveWebhookConfig()
        if syncShopAutoBuyButtons then
            syncShopAutoBuyButtons()
        else
            shopAutoBuyBtn.Text = Config.ShopAutoBuy and "Auto: ON" or "Auto: OFF"
            TweenService:Create(shopAutoBuyBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Config.ShopAutoBuy and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = Config.ShopAutoBuy and 0.15 or 0.92
            }):Play()
            TweenService:Create(sAutoStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Color = Config.ShopAutoBuy and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(255, 255, 255),
                Transparency = Config.ShopAutoBuy and 0.45 or 0.88
            }):Play()
        end
        if Config.ShopAutoBuy then
            task.defer(function() doShopAutoBuy(true) end)
        end
    end)

    -- In-Stock Items Dialog Frame (Apple Liquid Glass Modal Sheet)
    local shopDropdownPopup = Instance.new("Frame")
    shopDropdownPopup.Name = "ShopDropdownPopup"
    shopDropdownPopup.Size = UDim2.new(1, -12, 1, -12)
    shopDropdownPopup.Position = UDim2.new(0, 6, 0, 6)
    shopDropdownPopup.BackgroundColor3 = Color3.fromRGB(15, 19, 28)
    shopDropdownPopup.BackgroundTransparency = 0.05
    shopDropdownPopup.BorderSizePixel = 0
    shopDropdownPopup.ZIndex = 50
    shopDropdownPopup.Visible = false
    shopDropdownPopup.Parent = shopMainCard

    local sPopupCorner = Instance.new("UICorner")
    sPopupCorner.CornerRadius = UDim.new(0, 12)
    sPopupCorner.Parent = shopDropdownPopup

    applyGlassStroke(shopDropdownPopup, 1.4, 0.22, 0.82)

    local popGrad = Instance.new("UIGradient")
    popGrad.Rotation = 90
    popGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 35, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 18, 27))
    })
    popGrad.Parent = shopDropdownPopup

    -- 1. Modal Header
    local popHeader = Instance.new("Frame")
    popHeader.Name = "PopHeader"
    popHeader.Size = UDim2.new(1, 0, 0, 36)
    popHeader.BackgroundColor3 = Color3.fromRGB(22, 28, 42)
    popHeader.BackgroundTransparency = 0.35
    popHeader.BorderSizePixel = 0
    popHeader.ZIndex = 51
    popHeader.Parent = shopDropdownPopup

    local popHeaderCorner = Instance.new("UICorner")
    popHeaderCorner.CornerRadius = UDim.new(0, 12)
    popHeaderCorner.Parent = popHeader

    local popHeaderLabel = Instance.new("TextLabel")
    popHeaderLabel.Name = "PopHeaderLabel"
    popHeaderLabel.Text = "🛍️ Shop Stock"
    popHeaderLabel.Font = Enum.Font.GothamBold
    popHeaderLabel.TextSize = 12
    popHeaderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    popHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
    popHeaderLabel.TextTruncate = Enum.TextTruncate.AtEnd
    popHeaderLabel.Size = UDim2.new(0, 115, 1, 0)
    popHeaderLabel.Position = UDim2.new(0, 10, 0, 0)
    popHeaderLabel.BackgroundTransparency = 1
    popHeaderLabel.ZIndex = 52
    popHeaderLabel.Parent = popHeader

    -- Right Action Buttons in Header
    local popCloseBtn = Instance.new("TextButton")
    popCloseBtn.Name = "PopCloseBtn"
    popCloseBtn.Text = "✕"
    popCloseBtn.Font = Enum.Font.GothamBold
    popCloseBtn.TextSize = 11
    popCloseBtn.TextColor3 = Color3.fromRGB(200, 210, 230)
    popCloseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    popCloseBtn.BackgroundTransparency = 0.92
    popCloseBtn.Size = UDim2.new(0, 22, 0, 22)
    popCloseBtn.Position = UDim2.new(1, -28, 0.5, -11)
    popCloseBtn.AutoButtonColor = true
    popCloseBtn.ZIndex = 52
    popCloseBtn.Parent = popHeader

    local pCloseCorner = Instance.new("UICorner")
    pCloseCorner.CornerRadius = UDim.new(0, 6)
    pCloseCorner.Parent = popCloseBtn

    local pCloseStroke = Instance.new("UIStroke")
    pCloseStroke.Thickness = 1
    pCloseStroke.Color = Color3.fromRGB(255, 255, 255)
    pCloseStroke.Transparency = 0.85
    pCloseStroke.Parent = popCloseBtn

    popCloseBtn.MouseButton1Click:Connect(function()
        shopDropdownPopup.Visible = false
    end)

    local popBuyAllBtn = Instance.new("TextButton")
    popBuyAllBtn.Name = "PopBuyAllBtn"
    popBuyAllBtn.Text = "Buy All Stock"
    popBuyAllBtn.Font = Enum.Font.GothamBold
    popBuyAllBtn.TextSize = 10
    popBuyAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    popBuyAllBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
    popBuyAllBtn.BackgroundTransparency = 0.15
    popBuyAllBtn.Size = UDim2.new(0, 94, 0, 24)
    popBuyAllBtn.Position = UDim2.new(1, -126, 0.5, -12)
    popBuyAllBtn.AutoButtonColor = true
    popBuyAllBtn.ZIndex = 52
    popBuyAllBtn.Parent = popHeader

    local pbaCorner = Instance.new("UICorner")
    pbaCorner.CornerRadius = UDim.new(0, 8)
    pbaCorner.Parent = popBuyAllBtn

    local pbaStroke = Instance.new("UIStroke")
    pbaStroke.Thickness = 1
    pbaStroke.Color = Color3.fromRGB(255, 255, 255)
    pbaStroke.Transparency = 0.55
    pbaStroke.Parent = popBuyAllBtn

    local popRefreshBtn = Instance.new("TextButton")
    popRefreshBtn.Name = "PopRefreshBtn"
    popRefreshBtn.Text = "🔄"
    popRefreshBtn.Font = Enum.Font.GothamBold
    popRefreshBtn.TextSize = 12
    popRefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    popRefreshBtn.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
    popRefreshBtn.BackgroundTransparency = 0.2
    popRefreshBtn.Size = UDim2.new(0, 24, 0, 24)
    popRefreshBtn.Position = UDim2.new(1, -154, 0.5, -12)
    popRefreshBtn.AutoButtonColor = true
    popRefreshBtn.ZIndex = 52
    popRefreshBtn.Parent = popHeader

    local prfCorner = Instance.new("UICorner")
    prfCorner.CornerRadius = UDim.new(0, 6)
    prfCorner.Parent = popRefreshBtn

    local prfStroke = Instance.new("UIStroke")
    prfStroke.Thickness = 1
    prfStroke.Color = Color3.fromRGB(255, 255, 255)
    prfStroke.Transparency = 0.65
    prfStroke.Parent = popRefreshBtn

    -- Master Auto Buy Toggle in Dialog Header
    local popAutoBuyBtn = Instance.new("TextButton")
    popAutoBuyBtn.Name = "PopAutoBuyBtn"
    popAutoBuyBtn.Text = Config.ShopAutoBuy and "Auto Buy: ON" or "Auto Buy: OFF"
    popAutoBuyBtn.Font = Enum.Font.GothamBold
    popAutoBuyBtn.TextSize = 10
    popAutoBuyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    popAutoBuyBtn.BackgroundColor3 = Config.ShopAutoBuy and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 255, 255)
    popAutoBuyBtn.BackgroundTransparency = Config.ShopAutoBuy and 0.15 or 0.92
    popAutoBuyBtn.Size = UDim2.new(0, 86, 0, 24)
    popAutoBuyBtn.Position = UDim2.new(1, -244, 0.5, -12)
    popAutoBuyBtn.AutoButtonColor = true
    popAutoBuyBtn.ZIndex = 52
    popAutoBuyBtn.Parent = popHeader

    local pabCorner = Instance.new("UICorner")
    pabCorner.CornerRadius = UDim.new(0, 6)
    pabCorner.Parent = popAutoBuyBtn

    local pabStroke = Instance.new("UIStroke")
    pabStroke.Thickness = 1
    pabStroke.Color = Config.ShopAutoBuy and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(255, 255, 255)
    pabStroke.Transparency = Config.ShopAutoBuy and 0.45 or 0.88
    pabStroke.Parent = popAutoBuyBtn

    popAutoBuyBtn.MouseButton1Click:Connect(function()
        Config.ShopAutoBuy = not Config.ShopAutoBuy
        saveWebhookConfig()
        if syncShopAutoBuyButtons then syncShopAutoBuyButtons() end
        setActivity("Shop Auto Buy: " .. (Config.ShopAutoBuy and "ON" or "OFF"), Config.ShopAutoBuy and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(245, 158, 11))
        if Config.ShopAutoBuy then
            task.defer(function() doShopAutoBuy(true) end)
        end
    end)

    syncShopAutoBuyButtons = function()
        local isOn = (Config.ShopAutoBuy == true)
        if shopAutoBuyBtn then
            shopAutoBuyBtn.Text = isOn and "Auto: ON" or "Auto: OFF"
            TweenService:Create(shopAutoBuyBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = isOn and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = isOn and 0.15 or 0.92
            }):Play()
            if sAutoStroke then
                TweenService:Create(sAutoStroke, TweenInfo.new(0.2), {
                    Color = isOn and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(255, 255, 255),
                    Transparency = isOn and 0.45 or 0.88
                }):Play()
            end
        end
        if popAutoBuyBtn then
            popAutoBuyBtn.Text = isOn and "Auto Buy: ON" or "Auto Buy: OFF"
            TweenService:Create(popAutoBuyBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = isOn and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = isOn and 0.15 or 0.92
            }):Play()
            if pabStroke then
                TweenService:Create(pabStroke, TweenInfo.new(0.2), {
                    Color = isOn and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(255, 255, 255),
                    Transparency = isOn and 0.45 or 0.88
                }):Play()
            end
        end
    end

    -- Catalog Mode Toggle Button in Dialog Header (Show: All Catalog vs In-Stock Only)
    local popCatalogBtn = Instance.new("TextButton")
    popCatalogBtn.Name = "PopCatalogBtn"
    popCatalogBtn.Text = Config.ShopShowAllStock and "Show: All" or "Show: Stock"
    popCatalogBtn.Font = Enum.Font.GothamBold
    popCatalogBtn.TextSize = 10
    popCatalogBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    popCatalogBtn.BackgroundColor3 = Config.ShopShowAllStock and Color3.fromRGB(168, 85, 247) or Color3.fromRGB(255, 255, 255)
    popCatalogBtn.BackgroundTransparency = Config.ShopShowAllStock and 0.2 or 0.92
    popCatalogBtn.Size = UDim2.new(0, 84, 0, 24)
    popCatalogBtn.Position = UDim2.new(1, -332, 0.5, -12)
    popCatalogBtn.AutoButtonColor = true
    popCatalogBtn.ZIndex = 52
    popCatalogBtn.Parent = popHeader

    local pcCorner = Instance.new("UICorner")
    pcCorner.CornerRadius = UDim.new(0, 6)
    pcCorner.Parent = popCatalogBtn

    local pcStroke = Instance.new("UIStroke")
    pcStroke.Thickness = 1
    pcStroke.Color = Config.ShopShowAllStock and Color3.fromRGB(216, 180, 254) or Color3.fromRGB(255, 255, 255)
    pcStroke.Transparency = Config.ShopShowAllStock and 0.45 or 0.88
    pcStroke.Parent = popCatalogBtn

    -- Live Countdown Timer Pill in Dialog Header
    local popTimerPill = Instance.new("TextLabel")
    popTimerPill.Name = "PopTimerPill"
    popTimerPill.Text = "⏱️ --:--"
    popTimerPill.Font = Enum.Font.GothamBold
    popTimerPill.TextSize = 10
    popTimerPill.TextColor3 = Color3.fromRGB(56, 189, 248)
    popTimerPill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    popTimerPill.BackgroundTransparency = 0.93
    popTimerPill.Size = UDim2.new(0, 84, 0, 24)
    popTimerPill.Position = UDim2.new(1, -420, 0.5, -12)
    popTimerPill.ZIndex = 52
    popTimerPill.Parent = popHeader

    local ptCorner = Instance.new("UICorner")
    ptCorner.CornerRadius = UDim.new(0, 6)
    ptCorner.Parent = popTimerPill

    local ptStroke = Instance.new("UIStroke")
    ptStroke.Thickness = 1
    ptStroke.Color = Color3.fromRGB(56, 189, 248)
    ptStroke.Transparency = 0.8
    ptStroke.Parent = popTimerPill

    -- 2. Horizontal Category Chips Container
    local popChipsScroll = Instance.new("ScrollingFrame")
    popChipsScroll.Name = "PopChipsScroll"
    popChipsScroll.Size = UDim2.new(1, -16, 0, 28)
    popChipsScroll.Position = UDim2.new(0, 8, 0, 40)
    popChipsScroll.BackgroundTransparency = 1
    popChipsScroll.BorderSizePixel = 0
    popChipsScroll.ScrollBarThickness = 0
    popChipsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    popChipsScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    popChipsScroll.ScrollingDirection = Enum.ScrollingDirection.X
    popChipsScroll.ZIndex = 51
    popChipsScroll.Parent = shopDropdownPopup

    local popChipsLayout = Instance.new("UIListLayout")
    popChipsLayout.FillDirection = Enum.FillDirection.Horizontal
    popChipsLayout.Padding = UDim.new(0, 6)
    popChipsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    popChipsLayout.Parent = popChipsScroll

    local popChipsPadding = Instance.new("UIPadding")
    popChipsPadding.PaddingLeft = UDim.new(0, 2)
    popChipsPadding.PaddingRight = UDim.new(0, 2)
    popChipsPadding.PaddingTop = UDim.new(0, 1)
    popChipsPadding.PaddingBottom = UDim.new(0, 1)
    popChipsPadding.Parent = popChipsScroll

    -- 3. Filter Stats Bar
    local popStatLabel = Instance.new("TextLabel")
    popStatLabel.Name = "PopStatLabel"
    popStatLabel.Text = "Scanning inventory..."
    popStatLabel.Font = Enum.Font.GothamMedium
    popStatLabel.TextSize = 10
    popStatLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
    popStatLabel.TextXAlignment = Enum.TextXAlignment.Left
    popStatLabel.Size = UDim2.new(1, -20, 0, 16)
    popStatLabel.Position = UDim2.new(0, 10, 0, 72)
    popStatLabel.BackgroundTransparency = 1
    popStatLabel.ZIndex = 51
    popStatLabel.Parent = shopDropdownPopup

    -- 4. Scrolling List for In-Stock Items
    local shopStockScroll = Instance.new("ScrollingFrame")
    shopStockScroll.Name = "ShopStockScroll"
    shopStockScroll.Size = UDim2.new(1, -16, 1, -94)
    shopStockScroll.Position = UDim2.new(0, 8, 0, 90)
    shopStockScroll.BackgroundTransparency = 1
    shopStockScroll.BorderSizePixel = 0
    shopStockScroll.ScrollBarThickness = 4
    shopStockScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 110, 140)
    shopStockScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    shopStockScroll.ZIndex = 51
    shopStockScroll.Parent = shopDropdownPopup

    local shopStockLayout = Instance.new("UIListLayout")
    shopStockLayout.FillDirection = Enum.FillDirection.Vertical
    shopStockLayout.Padding = UDim.new(0, 4)
    shopStockLayout.SortOrder = Enum.SortOrder.LayoutOrder
    shopStockLayout.Parent = shopStockScroll

    -- State & Data Cache
    local lastRawShopData = nil
    local chipButtons = {}
    local renderShopStockPopup = nil

    local function refreshChipButtons(categoryCounts)
        for _, chipData in ipairs(chipButtons) do
            local catId = chipData.Id
            local count = categoryCounts[catId] or 0
            local isSelected = matchesShopCategory(catId, Config.ShopFilter) or (catId == "All" and Config.ShopFilter == "All")

            chipData.Button.Text = string.format("%s %s (%d)", chipData.Icon, chipData.Label, count)

            if isSelected then
                chipData.Button.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
                chipData.Button.BackgroundTransparency = 0.15
                chipData.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                chipData.Stroke.Color = Color3.fromRGB(120, 200, 255)
                chipData.Stroke.Transparency = 0.4
            else
                chipData.Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                chipData.Button.BackgroundTransparency = 0.94
                chipData.Button.TextColor3 = (count > 0) and Color3.fromRGB(180, 195, 220) or Color3.fromRGB(115, 130, 150)
                chipData.Stroke.Color = Color3.fromRGB(255, 255, 255)
                chipData.Stroke.Transparency = 0.9
            end
        end
    end

    renderShopStockPopup = function(dontRefetch)
        for _, child in ipairs(shopStockScroll:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        local function processData(res)
            if type(res) ~= "table" then
                popStatLabel.Text = "Failed to load shop stock."
                popStatLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
                return
            end

            lastRawShopData = res

            -- 1. Calculate counts for categories & build item lists
            local counts = { All = 0 }
            local dynamicCats = {}
            local allStocked = {}

            for catName, items in pairs(res) do
                if type(items) == "table" then
                    for _, itm in ipairs(items) do
                        local isTarget = Config.ShopTargetItems and (Config.ShopTargetItems[itm.Key] == true)
                        if (itm.Stock and itm.Stock > 0) or Config.ShopShowAllStock or isTarget then
                            local price, friendlyName, icon, desc = getItemDetails(itm.SystemType, itm.Category or catName, itm.Key)
                            local cat = itm.Category or catName

                            if itm.Stock and itm.Stock > 0 then
                                counts["All"] = (counts["All"] or 0) + itm.Stock
                                counts[cat] = (counts[cat] or 0) + itm.Stock
                            end

                            -- Track dynamic categories
                            local matchedKnown = false
                            for _, def in ipairs(DEFAULT_CATEGORIES) do
                                if matchesShopCategory(cat, def.Id) then
                                    matchedKnown = true
                                    break
                                end
                            end
                            if not matchedKnown then
                                dynamicCats[cat] = true
                            end

                            table.insert(allStocked, {
                                Key = itm.Key,
                                Category = cat,
                                Stock = itm.Stock or 0,
                                SystemType = itm.SystemType,
                                Price = price,
                                FriendlyName = friendlyName,
                                Icon = icon,
                                Description = desc,
                            })
                        end
                    end
                end
            end

            -- Update counts for all standard category aliases
            for _, def in ipairs(DEFAULT_CATEGORIES) do
                if def.Id ~= "All" and not counts[def.Id] then
                    local total = 0
                    for catKey, cVal in pairs(counts) do
                        if catKey ~= "All" and matchesShopCategory(catKey, def.Id) then
                            total = total + cVal
                        end
                    end
                    counts[def.Id] = total
                end
            end

            -- 2. Build Category Chips if not yet populated or if dynamic cats present
            if #chipButtons == 0 then
                for _, child in ipairs(popChipsScroll:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                table.clear(chipButtons)

                local fullCategories = {}
                for _, def in ipairs(DEFAULT_CATEGORIES) do
                    table.insert(fullCategories, def)
                end
                for dynCat in pairs(dynamicCats) do
                    table.insert(fullCategories, {
                        Id = dynCat,
                        Label = dynCat,
                        Icon = "📦"
                    })
                end

                for orderIdx, catDef in ipairs(fullCategories) do
                    local chip = Instance.new("TextButton")
                    chip.Name = "Chip_" .. catDef.Id
                    chip.Text = catDef.Icon .. " " .. catDef.Label
                    chip.Font = Enum.Font.GothamBold
                    chip.TextSize = 10
                    chip.TextColor3 = Color3.fromRGB(180, 195, 220)
                    chip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    chip.BackgroundTransparency = 0.94
                    chip.Size = UDim2.new(0, 0, 1, 0)
                    chip.AutomaticSize = Enum.AutomaticSize.X
                    chip.LayoutOrder = orderIdx
                    chip.AutoButtonColor = false
                    chip.ZIndex = 52
                    chip.Parent = popChipsScroll

                    local cCorner = Instance.new("UICorner")
                    cCorner.CornerRadius = UDim.new(0, 14)
                    cCorner.Parent = chip

                    local cStroke = Instance.new("UIStroke")
                    cStroke.Thickness = 1
                    cStroke.Color = Color3.fromRGB(255, 255, 255)
                    cStroke.Transparency = 0.9
                    cStroke.Parent = chip

                    local cPad = Instance.new("UIPadding")
                    cPad.PaddingLeft = UDim.new(0, 10)
                    cPad.PaddingRight = UDim.new(0, 10)
                    cPad.Parent = chip

                    local chipRecord = {
                        Id = catDef.Id,
                        Label = catDef.Label,
                        Icon = catDef.Icon,
                        Button = chip,
                        Stroke = cStroke,
                    }
                    table.insert(chipButtons, chipRecord)

                    chip.MouseButton1Click:Connect(function()
                        Config.ShopFilter = catDef.Id
                        refreshChipButtons(counts)
                        renderShopStockPopup(true)
                    end)
                end
            end

            refreshChipButtons(counts)

            -- 3. Filter items for current category
            local filtered = {}
            local totalFilterPrice = 0
            for _, itm in ipairs(allStocked) do
                if matchesShopCategory(itm.Category, Config.ShopFilter) then
                    totalFilterPrice = totalFilterPrice + (itm.Price * itm.Stock)
                    table.insert(filtered, itm)
                end
            end

            table.sort(filtered, function(a, b)
                local aTarget = (Config.ShopTargetItems and Config.ShopTargetItems[a.Key]) and 1 or 0
                local bTarget = (Config.ShopTargetItems and Config.ShopTargetItems[b.Key]) and 1 or 0
                if aTarget ~= bTarget then
                    return aTarget > bTarget
                end
                local aInStock = (a.Stock > 0) and 1 or 0
                local bInStock = (b.Stock > 0) and 1 or 0
                if aInStock ~= bInStock then
                    return aInStock > bInStock
                end
                return a.FriendlyName:lower() < b.FriendlyName:lower()
            end)

            -- Update Header & Stats
            local curCount = (Config.ShopFilter == "All") and (counts["All"] or 0) or (counts[Config.ShopFilter] or #filtered)
            popHeaderLabel.Text = "🛍️ Shop Stock (" .. curCount .. ")"
            popBuyAllBtn.Text = (Config.ShopFilter == "All") and "Buy All Stock" or ("Buy " .. Config.ShopFilter)

            local targetCount = 0
            for _ in pairs(Config.ShopTargetItems or {}) do targetCount = targetCount + 1 end
            local targetStr = targetCount > 0 and ("  •  🎯 " .. targetCount .. " target" .. (targetCount == 1 and "" or "s")) or ""

            popStatLabel.Text = string.format("Showing %d item%s (%s)%s  •  Value: %s",
                #filtered,
                #filtered == 1 and "" or "s",
                Config.ShopFilter,
                targetStr,
                totalFilterPrice > 0 and ("₱" .. formatNumber(totalFilterPrice)) or "Free"
            )

            -- 4. Empty State
            if #filtered == 0 then
                local emptyCard = Instance.new("Frame")
                emptyCard.Name = "EmptyCard"
                emptyCard.Size = UDim2.new(1, -10, 0, 120)
                emptyCard.Position = UDim2.new(0, 5, 0, 15)
                emptyCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                emptyCard.BackgroundTransparency = 0.96
                emptyCard.BorderSizePixel = 0
                emptyCard.ZIndex = 52
                emptyCard.Parent = shopStockScroll

                local ecCorner = Instance.new("UICorner")
                ecCorner.CornerRadius = UDim.new(0, 10)
                ecCorner.Parent = emptyCard

                local ecStroke = Instance.new("UIStroke")
                ecStroke.Thickness = 1
                ecStroke.Color = Color3.fromRGB(255, 255, 255)
                ecStroke.Transparency = 0.92
                ecStroke.Parent = emptyCard

                local eIcon = Instance.new("TextLabel")
                eIcon.Text = "📦"
                eIcon.Font = Enum.Font.GothamBold
                eIcon.TextSize = 24
                eIcon.Size = UDim2.new(1, 0, 0, 30)
                eIcon.Position = UDim2.new(0, 0, 0, 14)
                eIcon.BackgroundTransparency = 1
                eIcon.ZIndex = 53
                eIcon.Parent = emptyCard

                local eTitle = Instance.new("TextLabel")
                eTitle.Text = "No " .. Config.ShopFilter .. " In Stock"
                eTitle.Font = Enum.Font.GothamBold
                eTitle.TextSize = 12
                eTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
                eTitle.Size = UDim2.new(1, 0, 0, 20)
                eTitle.Position = UDim2.new(0, 0, 0, 48)
                eTitle.BackgroundTransparency = 1
                eTitle.ZIndex = 53
                eTitle.Parent = emptyCard

                local eSub = Instance.new("TextLabel")
                eSub.Text = "Check back soon! Karinderya restocks inventory periodically."
                eSub.Font = Enum.Font.GothamMedium
                eSub.TextSize = 10
                eSub.TextColor3 = Color3.fromRGB(140, 155, 180)
                eSub.Size = UDim2.new(1, -20, 0, 18)
                eSub.Position = UDim2.new(0, 10, 0, 70)
                eSub.BackgroundTransparency = 1
                eSub.ZIndex = 53
                eSub.Parent = emptyCard

                local eRefBtn = Instance.new("TextButton")
                eRefBtn.Text = "Refresh Stock"
                eRefBtn.Font = Enum.Font.GothamBold
                eRefBtn.TextSize = 10
                eRefBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                eRefBtn.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
                eRefBtn.BackgroundTransparency = 0.25
                eRefBtn.Size = UDim2.new(0, 96, 0, 22)
                eRefBtn.Position = UDim2.new(0.5, -48, 0, 92)
                eRefBtn.AutoButtonColor = true
                eRefBtn.ZIndex = 53
                eRefBtn.Parent = emptyCard

                local erbCorner = Instance.new("UICorner")
                erbCorner.CornerRadius = UDim.new(0, 6)
                erbCorner.Parent = eRefBtn

                eRefBtn.MouseButton1Click:Connect(function()
                    renderShopStockPopup(false)
                end)

                shopStockScroll.CanvasSize = UDim2.new(0, 0, 0, 135)
                return
            end

            -- 5. Render Stock Item Rows
            for _, itm in ipairs(filtered) do
                local eIcon, eName, eBgColor, eStrokeColor, eTagLabel = getCategoryMeta(itm.Category)
                local isTarget = Config.ShopTargetItems and (Config.ShopTargetItems[itm.Key] == true)

                local row = Instance.new("Frame")
                row.Name = "StockItem_" .. itm.Key
                row.Size = UDim2.new(1, -6, 0, 40)
                row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                row.BackgroundTransparency = isTarget and 0.90 or 0.95
                row.BorderSizePixel = 0
                row.ZIndex = 52
                row.Parent = shopStockScroll

                local rCorner = Instance.new("UICorner")
                rCorner.CornerRadius = UDim.new(0, 8)
                rCorner.Parent = row

                local rStroke = Instance.new("UIStroke")
                rStroke.Thickness = 1
                rStroke.Color = isTarget and Color3.fromRGB(245, 158, 11) or Color3.fromRGB(255, 255, 255)
                rStroke.Transparency = isTarget and 0.45 or 0.9
                rStroke.Parent = row

                row.MouseEnter:Connect(function()
                    TweenService:Create(row, TweenInfo.new(0.15), { BackgroundTransparency = 0.86 }):Play()
                end)
                row.MouseLeave:Connect(function()
                    local curTarget = Config.ShopTargetItems and (Config.ShopTargetItems[itm.Key] == true)
                    TweenService:Create(row, TweenInfo.new(0.15), { BackgroundTransparency = curTarget and 0.90 or 0.95 }):Play()
                end)

                -- Thumbnail / Icon Box
                local iconHolder = Instance.new("Frame")
                iconHolder.Name = "IconHolder"
                iconHolder.Size = UDim2.new(0, 28, 0, 28)
                iconHolder.Position = UDim2.new(0, 6, 0.5, -14)
                iconHolder.BackgroundColor3 = eBgColor
                iconHolder.BackgroundTransparency = 0.8
                iconHolder.BorderSizePixel = 0
                iconHolder.ZIndex = 53
                iconHolder.Parent = row

                local ihCorner = Instance.new("UICorner")
                ihCorner.CornerRadius = UDim.new(0, 6)
                ihCorner.Parent = iconHolder

                local ihStroke = Instance.new("UIStroke")
                ihStroke.Thickness = 1
                ihStroke.Color = eStrokeColor
                ihStroke.Transparency = 0.5
                ihStroke.Parent = iconHolder

                if itm.Icon and tostring(itm.Icon) ~= "" then
                    local img = Instance.new("ImageLabel")
                    img.Image = itm.Icon
                    img.Size = UDim2.new(1, -4, 1, -4)
                    img.Position = UDim2.new(0, 2, 0, 2)
                    img.BackgroundTransparency = 1
                    img.ScaleType = Enum.ScaleType.Fit
                    img.ZIndex = 54
                    img.Parent = iconHolder
                else
                    local emojiLbl = Instance.new("TextLabel")
                    emojiLbl.Text = eIcon
                    emojiLbl.Font = Enum.Font.GothamBold
                    emojiLbl.TextSize = 14
                    emojiLbl.Size = UDim2.new(1, 0, 1, 0)
                    emojiLbl.BackgroundTransparency = 1
                    emojiLbl.ZIndex = 54
                    emojiLbl.Parent = iconHolder
                end

                -- Category Tag Mini-Pill
                local tagPill = Instance.new("Frame")
                tagPill.Name = "TagPill"
                tagPill.Size = UDim2.new(0, 58, 0, 16)
                tagPill.Position = UDim2.new(0, 40, 0, 4)
                tagPill.BackgroundColor3 = eBgColor
                tagPill.BackgroundTransparency = 0.82
                tagPill.BorderSizePixel = 0
                tagPill.ZIndex = 53
                tagPill.Parent = row

                local tpCorner = Instance.new("UICorner")
                tpCorner.CornerRadius = UDim.new(0, 4)
                tpCorner.Parent = tagPill

                local tagLbl = Instance.new("TextLabel")
                tagLbl.Text = eIcon .. " " .. eTagLabel
                tagLbl.Font = Enum.Font.GothamBold
                tagLbl.TextSize = 9
                tagLbl.TextColor3 = eStrokeColor
                tagLbl.Size = UDim2.new(1, 0, 1, 0)
                tagLbl.BackgroundTransparency = 1
                tagLbl.ZIndex = 54
                tagLbl.Parent = tagPill

                -- Item Friendly Name
                local nameLbl = Instance.new("TextLabel")
                nameLbl.Name = "ItemName"
                nameLbl.Text = itm.FriendlyName
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 11
                nameLbl.TextColor3 = Color3.fromRGB(245, 248, 255)
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                nameLbl.Size = UDim2.new(1, -336, 0, 16)
                nameLbl.Position = UDim2.new(0, 104, 0, 4)
                nameLbl.BackgroundTransparency = 1
                nameLbl.ZIndex = 53
                nameLbl.Parent = row

                -- Subtitle / System Type
                local subLbl = Instance.new("TextLabel")
                subLbl.Name = "SubInfo"
                local descText = (itm.Description and itm.Description ~= "") and itm.Description or (itm.SystemType and (itm.SystemType .. " Item") or itm.Category)
                subLbl.Text = descText
                subLbl.Font = Enum.Font.GothamMedium
                subLbl.TextSize = 9
                subLbl.TextColor3 = Color3.fromRGB(140, 155, 180)
                subLbl.TextXAlignment = Enum.TextXAlignment.Left
                subLbl.TextTruncate = Enum.TextTruncate.AtEnd
                subLbl.Size = UDim2.new(1, -336, 0, 14)
                subLbl.Position = UDim2.new(0, 40, 0, 22)
                subLbl.BackgroundTransparency = 1
                subLbl.ZIndex = 53
                subLbl.Parent = row

                -- Price Tag
                local priceLbl = Instance.new("TextLabel")
                priceLbl.Name = "Price"
                priceLbl.Text = (itm.Price and itm.Price > 0) and ("₱" .. formatNumber(itm.Price)) or "Free"
                priceLbl.Font = Enum.Font.GothamBold
                priceLbl.TextSize = 11
                priceLbl.TextColor3 = (itm.Price and itm.Price > 0) and Color3.fromRGB(255, 214, 10) or Color3.fromRGB(52, 199, 89)
                priceLbl.TextXAlignment = Enum.TextXAlignment.Right
                priceLbl.Size = UDim2.new(0, 58, 1, 0)
                priceLbl.Position = UDim2.new(1, -226, 0, 0)
                priceLbl.BackgroundTransparency = 1
                priceLbl.ZIndex = 53
                priceLbl.Parent = row

                -- 🎯 Target Sniper Toggle Button
                local targetBtn = Instance.new("TextButton")
                targetBtn.Name = "TargetBtn"
                targetBtn.Text = isTarget and "🎯 Auto" or "🎯 Off"
                targetBtn.Font = Enum.Font.GothamBold
                targetBtn.TextSize = 10
                targetBtn.TextColor3 = isTarget and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 175, 200)
                targetBtn.BackgroundColor3 = isTarget and Color3.fromRGB(245, 158, 11) or Color3.fromRGB(255, 255, 255)
                targetBtn.BackgroundTransparency = isTarget and 0.15 or 0.92
                targetBtn.Size = UDim2.new(0, 56, 0, 22)
                targetBtn.Position = UDim2.new(1, -164, 0.5, -11)
                targetBtn.AutoButtonColor = true
                targetBtn.ZIndex = 53
                targetBtn.Parent = row

                local tgtCorner = Instance.new("UICorner")
                tgtCorner.CornerRadius = UDim.new(0, 6)
                tgtCorner.Parent = targetBtn

                local tgtStroke = Instance.new("UIStroke")
                tgtStroke.Thickness = 1
                tgtStroke.Color = isTarget and Color3.fromRGB(251, 191, 36) or Color3.fromRGB(255, 255, 255)
                tgtStroke.Transparency = isTarget and 0.45 or 0.88
                tgtStroke.Parent = targetBtn

                targetBtn.MouseButton1Click:Connect(function()
                    if not Config.ShopTargetItems then Config.ShopTargetItems = {} end
                    if Config.ShopTargetItems[itm.Key] then
                        Config.ShopTargetItems[itm.Key] = nil
                    else
                        Config.ShopTargetItems[itm.Key] = true
                        Config.ShopAutoBuy = true
                        if syncShopAutoBuyButtons then syncShopAutoBuyButtons() end
                    end
                    saveWebhookConfig()
                    local nowTarget = (Config.ShopTargetItems[itm.Key] == true)
                    targetBtn.Text = nowTarget and "🎯 Auto" or "🎯 Off"
                    targetBtn.TextColor3 = nowTarget and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 175, 200)
                    TweenService:Create(targetBtn, TweenInfo.new(0.2), {
                        BackgroundColor3 = nowTarget and Color3.fromRGB(245, 158, 11) or Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = nowTarget and 0.15 or 0.92,
                    }):Play()
                    TweenService:Create(tgtStroke, TweenInfo.new(0.2), {
                        Color = nowTarget and Color3.fromRGB(251, 191, 36) or Color3.fromRGB(255, 255, 255),
                        Transparency = nowTarget and 0.45 or 0.88,
                    }):Play()
                    TweenService:Create(rStroke, TweenInfo.new(0.2), {
                        Color = nowTarget and Color3.fromRGB(245, 158, 11) or Color3.fromRGB(255, 255, 255),
                        Transparency = nowTarget and 0.45 or 0.9,
                    }):Play()
                    setActivity((nowTarget and "🎯 Target Added: " or "🎯 Target Removed: ") .. itm.FriendlyName, nowTarget and Color3.fromRGB(245, 158, 11) or Color3.fromRGB(160, 175, 200))

                    if nowTarget then
                        task.defer(function()
                            doShopAutoBuy(true)
                        end)
                    end
                end)

                -- Stock Badge Pill
                local stckHolder = Instance.new("Frame")
                stckHolder.Name = "StockHolder"
                stckHolder.Size = UDim2.new(0, 30, 0, 20)
                stckHolder.Position = UDim2.new(1, -104, 0.5, -10)
                stckHolder.BackgroundColor3 = (itm.Stock > 0) and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(50, 55, 70)
                stckHolder.BackgroundTransparency = (itm.Stock > 0) and 0.85 or 0.7
                stckHolder.BorderSizePixel = 0
                stckHolder.ZIndex = 53
                stckHolder.Parent = row

                local shCorner = Instance.new("UICorner")
                shCorner.CornerRadius = UDim.new(0, 6)
                shCorner.Parent = stckHolder

                local stckLbl = Instance.new("TextLabel")
                stckLbl.Name = "Stock"
                stckLbl.Text = "x" .. itm.Stock
                stckLbl.Font = Enum.Font.GothamBold
                stckLbl.TextSize = 10
                stckLbl.TextColor3 = (itm.Stock > 0) and Color3.fromRGB(100, 210, 255) or Color3.fromRGB(140, 150, 170)
                stckLbl.Size = UDim2.new(1, 0, 1, 0)
                stckLbl.BackgroundTransparency = 1
                stckLbl.ZIndex = 54
                stckLbl.Parent = stckHolder

                -- Buy 1 / Manual Action Button
                local bBtn = Instance.new("TextButton")
                bBtn.Name = "BuyBtn"
                bBtn.Font = Enum.Font.GothamBold
                bBtn.ZIndex = 53
                bBtn.Parent = row

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 6)
                bCorner.Parent = bBtn

                local bStroke = Instance.new("UIStroke")
                bStroke.Thickness = 1
                bStroke.Color = Color3.fromRGB(255, 255, 255)
                bStroke.Transparency = 0.55
                bStroke.Parent = bBtn

                local maxBtn = nil

                if itm.Stock > 1 then
                    bBtn.Text = "Buy"
                    bBtn.TextSize = 10
                    bBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    bBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
                    bBtn.BackgroundTransparency = 0.15
                    bBtn.Size = UDim2.new(0, 34, 0, 22)
                    bBtn.Position = UDim2.new(1, -70, 0.5, -11)
                    bBtn.AutoButtonColor = true

                    maxBtn = Instance.new("TextButton")
                    maxBtn.Name = "MaxBtn"
                    maxBtn.Text = "Max"
                    maxBtn.Font = Enum.Font.GothamBold
                    maxBtn.TextSize = 10
                    maxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    maxBtn.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
                    maxBtn.BackgroundTransparency = 0.2
                    maxBtn.Size = UDim2.new(0, 30, 0, 22)
                    maxBtn.Position = UDim2.new(1, -34, 0.5, -11)
                    maxBtn.AutoButtonColor = true
                    maxBtn.ZIndex = 53
                    maxBtn.Parent = row

                    local mCorner = Instance.new("UICorner")
                    mCorner.CornerRadius = UDim.new(0, 6)
                    mCorner.Parent = maxBtn

                    local mStroke = Instance.new("UIStroke")
                    mStroke.Thickness = 1
                    mStroke.Color = Color3.fromRGB(255, 255, 255)
                    mStroke.Transparency = 0.6
                    mStroke.Parent = maxBtn

                    maxBtn.MouseButton1Click:Connect(function()
                        if not BuyFurniture or itm.Stock <= 0 then return end
                        maxBtn.Text = "..."
                        task.spawn(function()
                            local buyQty = itm.Stock
                            local bought = 0
                            for s = 1, buyQty do
                                local bOk, bRes = pcall(function()
                                    return BuyFurniture:InvokeServer(itm.SystemType, itm.Category, itm.Key)
                                end)
                                if bOk and bRes then
                                    bought = bought + 1
                                    itm.Stock = itm.Stock - 1
                                    counts[itm.Category] = math.max(0, (counts[itm.Category] or 0) - 1)
                                    counts["All"] = math.max(0, (counts["All"] or 0) - 1)
                                end
                                task.wait(0.06)
                            end
                            if bought > 0 then
                                setActivity(string.format("Bought %dx %s!", bought, itm.FriendlyName), Color3.fromRGB(52, 199, 89))
                            end
                            refreshChipButtons(counts)
                            renderShopStockPopup(false)
                        end)
                    end)
                elseif itm.Stock == 1 then
                    bBtn.Text = "Buy"
                    bBtn.TextSize = 10
                    bBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    bBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
                    bBtn.BackgroundTransparency = 0.15
                    bBtn.Size = UDim2.new(0, 66, 0, 22)
                    bBtn.Position = UDim2.new(1, -70, 0.5, -11)
                    bBtn.AutoButtonColor = true
                else
                    -- Out of stock (Catalog mode item)
                    bBtn.Text = "Out of Stock"
                    bBtn.TextSize = 9
                    bBtn.TextColor3 = Color3.fromRGB(150, 160, 180)
                    bBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
                    bBtn.BackgroundTransparency = 0.6
                    bBtn.Size = UDim2.new(0, 66, 0, 22)
                    bBtn.Position = UDim2.new(1, -70, 0.5, -11)
                    bBtn.AutoButtonColor = false
                    bStroke.Transparency = 0.85
                end

                bBtn.MouseButton1Click:Connect(function()
                    if itm.Stock <= 0 then
                        setActivity("Item is out of stock. Marked with 🎯 Auto to snipe upon restock!", Color3.fromRGB(245, 158, 11))
                        return
                    end
                    if not BuyFurniture then return end
                    bBtn.Text = "..."
                    task.spawn(function()
                        local bOk, bRes = pcall(function()
                            return BuyFurniture:InvokeServer(itm.SystemType, itm.Category, itm.Key)
                        end)
                        if bOk and bRes then
                            itm.Stock = itm.Stock - 1
                            counts[itm.Category] = math.max(0, (counts[itm.Category] or 0) - 1)
                            counts["All"] = math.max(0, (counts["All"] or 0) - 1)
                            refreshChipButtons(counts)
                            setActivity("Bought 1x " .. itm.FriendlyName .. " (" .. (itm.Price > 0 and ("₱" .. formatNumber(itm.Price)) or "Free") .. ")", Color3.fromRGB(52, 199, 89))
                            if itm.Stock <= 0 then
                                if Config.ShopShowAllStock or (Config.ShopTargetItems and Config.ShopTargetItems[itm.Key]) then
                                    bBtn.Text = "Out of Stock"
                                    bBtn.TextSize = 9
                                    bBtn.TextColor3 = Color3.fromRGB(150, 160, 180)
                                    bBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
                                    bBtn.BackgroundTransparency = 0.6
                                    bBtn.Size = UDim2.new(0, 66, 0, 22)
                                    bBtn.AutoButtonColor = false
                                    stckLbl.Text = "x0"
                                    stckHolder.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
                                    stckLbl.TextColor3 = Color3.fromRGB(140, 150, 170)
                                else
                                    row:Destroy()
                                end
                            else
                                bBtn.Text = "Buy"
                                stckLbl.Text = "x" .. itm.Stock
                                if itm.Stock <= 1 and maxBtn then
                                    maxBtn:Destroy()
                                    bBtn.Size = UDim2.new(0, 66, 0, 22)
                                end
                            end
                        else
                            bBtn.Text = "Buy"
                            setActivity("Buy failed: " .. itm.FriendlyName, Color3.fromRGB(255, 69, 58))
                        end
                    end)
                end)
            end

            shopStockScroll.CanvasSize = UDim2.new(0, 0, 0, #filtered * 44 + 8)
        end

        if dontRefetch and lastRawShopData then
            processData(lastRawShopData)
        else
            local loadLbl = Instance.new("TextLabel")
            loadLbl.Text = "Fetching available stock..."
            loadLbl.Font = Enum.Font.GothamMedium
            loadLbl.TextSize = 11
            loadLbl.TextColor3 = Color3.fromRGB(56, 189, 248)
            loadLbl.BackgroundTransparency = 1
            loadLbl.Size = UDim2.new(1, 0, 0, 30)
            loadLbl.ZIndex = 52
            loadLbl.Parent = shopStockScroll

            task.spawn(function()
                local ok, res = pcall(function() return GetShopInfo:InvokeServer() end)
                loadLbl:Destroy()
                if ok and type(res) == "table" then
                    processData(res)
                else
                    popStatLabel.Text = "Failed to load shop stock."
                    popStatLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
                end
            end)
        end
    end

    popCatalogBtn.MouseButton1Click:Connect(function()
        Config.ShopShowAllStock = not Config.ShopShowAllStock
        saveWebhookConfig()
        popCatalogBtn.Text = Config.ShopShowAllStock and "Show: All" or "Show: Stock"
        TweenService:Create(popCatalogBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Config.ShopShowAllStock and Color3.fromRGB(168, 85, 247) or Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = Config.ShopShowAllStock and 0.2 or 0.92,
        }):Play()
        TweenService:Create(pcStroke, TweenInfo.new(0.2), {
            Color = Config.ShopShowAllStock and Color3.fromRGB(216, 180, 254) or Color3.fromRGB(255, 255, 255),
            Transparency = Config.ShopShowAllStock and 0.45 or 0.88,
        }):Play()
        renderShopStockPopup(true)
    end)

    -- Bulk Purchase Routine
    local isBuyingAllStock = false
    local function buyAllAvailableStock()
        if isBuyingAllStock or not BuyFurniture or not GetShopInfo then return end
        isBuyingAllStock = true

        popBuyAllBtn.Text = "Buying..."
        setActivity("Scanning Shop Stock (" .. Config.ShopFilter .. ")...", Color3.fromRGB(59, 130, 246))

        task.spawn(function()
            local ok, res = pcall(function() return GetShopInfo:InvokeServer() end)
            if not ok or type(res) ~= "table" then
                setActivity("Failed to read shop info", Color3.fromRGB(239, 68, 68))
                isBuyingAllStock = false
                popBuyAllBtn.Text = "Buy All Stock"
                return
            end

            local boughtCount = 0
            for catName, items in pairs(res) do
                if matchesShopCategory(catName, Config.ShopFilter) then
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

            popBuyAllBtn.Text = (Config.ShopFilter == "All") and "Buy All Stock" or ("Buy " .. Config.ShopFilter)
            if shopDropdownPopup.Visible then
                renderShopStockPopup(false)
            end
            isBuyingAllStock = false
        end)
    end

    -- Connect Buttons
    buyStockBtn.MouseButton1Click:Connect(buyAllAvailableStock)
    popBuyAllBtn.MouseButton1Click:Connect(buyAllAvailableStock)

    popRefreshBtn.MouseButton1Click:Connect(function()
        renderShopStockPopup(false)
    end)

    shopDropdownBtn.MouseButton1Click:Connect(function()
        shopDropdownPopup.Visible = not shopDropdownPopup.Visible
        if shopDropdownPopup.Visible then
            renderShopStockPopup(false)
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
                renderShopStockPopup(false)
            end
            setActivity("Shop & Grocery Refreshed!", Color3.fromRGB(59, 130, 246))
        end)
    end)

    updateShopStockShared = function(forceRefetch)
        if shopDropdownPopup and shopDropdownPopup.Visible then
            renderShopStockPopup(not forceRefetch)
        end
        if renderGroceryGridShared then
            renderGroceryGridShared()
        end
    end

    -- 6. Real-Time Restock Countdown Timer & Auto-Refresh Engine
    local lastCycleIdx = -1
    local lastAutoRefreshTime = 0

    spawnLoop(1, function()
        local remaining = getNextRestockRemaining()
        local timeStr = formatTimer(remaining)
        local isUrgent = (remaining <= 15 and remaining > 0)
        local isRestocking = (remaining == 0)

        local timerColor = isRestocking and Color3.fromRGB(52, 199, 89) or (isUrgent and Color3.fromRGB(251, 146, 60) or Color3.fromRGB(56, 189, 248))
        local timerText = isRestocking and "✨ Restocked!" or ("⏱️ " .. timeStr)

        if shopTimerPill then
            shopTimerPill.Text = timerText
            shopTimerPill.TextColor3 = timerColor
            if sTimerStroke then
                sTimerStroke.Color = timerColor
            end
        end
        if popTimerPill then
            popTimerPill.Text = timerText
            popTimerPill.TextColor3 = timerColor
            if ptStroke then
                ptStroke.Color = timerColor
            end
        end

        -- Sync original game stock timer in PlayerGui if present
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local origStockTime = pg and pg:FindFirstChild("GUI") and pg.GUI.Frames and pg.GUI.Frames.Stock and pg.GUI.Frames.Stock.Title and pg.GUI.Frames.Stock.Title:FindFirstChild("StockTime")
            if origStockTime then
                origStockTime.Text = timeStr
            end
        end)

        -- Detect 5-minute restock cycle rollover
        local ok, serverTime = pcall(function() return Workspace:GetServerTimeNow() end)
        local curCycle = math.floor(((ok and serverTime) or os.time()) / 300)
        if lastCycleIdx ~= -1 and curCycle ~= lastCycleIdx then
            lastCycleIdx = curCycle
            setActivity("Shop Restocked! Updating inventory...", Color3.fromRGB(52, 199, 89))
            if shopDropdownPopup and shopDropdownPopup.Visible then
                renderShopStockPopup(false)
            end
            if renderGroceryGridShared then
                renderGroceryGridShared()
            end
            if Config.ShopAutoBuy then
                task.defer(doShopAutoBuy)
            end
        elseif lastCycleIdx == -1 then
            lastCycleIdx = curCycle
        end

        -- Periodic auto-refresh when dialog is open and ShopAutoRefresh is enabled
        local now = os.clock()
        if Config.ShopAutoRefresh and (now - lastAutoRefreshTime >= (Config.ShopAutoRefreshInterval or 10)) then
            if shopDropdownPopup and shopDropdownPopup.Visible then
                lastAutoRefreshTime = now
                renderShopStockPopup(false)
            end
        end
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

            if Hub.DockThievesVal then Hub.DockThievesVal.Text = "💥 Thieves: " .. tostring(Hub.ThievesChasedCount or 0) end
            if Hub.DockWorkersVal then Hub.DockWorkersVal.Text = "💤 Woken: " .. tostring(Hub.WorkersWokenCount or 0) end
            if Hub.DockTrashVal then Hub.DockTrashVal.Text = "🧹 Trash: " .. tostring(Hub.TrashCleanedCount or 0) end
            if Hub.DockProfitVal then
                Hub.DockProfitVal.Text = string.format("📈 Profit: %s₱%s", earned >= 0 and "+" or "", formatNumber(earned))
                Hub.DockProfitVal.TextColor3 = earned >= 0 and Color3.fromRGB(52, 225, 100) or Color3.fromRGB(255, 90, 80)
            end

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
