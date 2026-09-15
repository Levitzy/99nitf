--[[
    ═════════════════════════════════════════════════════════════════════════
    ⚡ SHADCN/UI WALKSPEED, COMBAT & AUTO PLAY CONTROLLER (ROBLOX / LUAU) ⚡
    • Strict 1:1 shadcn/ui Design System:
        - Modern 3-Tab navigation: [ 🏃 Speed ], [ ⚔️ Combat ], [ 🤖 Auto Play ]
        - Zinc dark theme (#09090b background, #27272a borders, #fafafa primary)
        - Stepper buttons [-] and [+] with glowing focus ring input
        - Segmented preset tabs: [0] [8] [12] [16] [20] with active highlight
        - Official Lucide icons (Gauge, Swords, Target, Flame, Minus, Plus, Repeat, Bot, Play, Close)
    • Features:
        1. WALKSPEED ENGINE:
           - Range: 0 to 20 (Default: 20)
           - Anti-Reset Engine (Heartbeat & PreSimulation frame lock)
           - Property Change listener (Bypasses scripts resetting speed)
           - Auto-respawn & death rebind (CharacterAdded)
        2. COMBAT & KILL AURA ENGINE:
           - Auto Swing: Rapid weapon RemoteEvent & weaponUsed dispatch
           - Kill Aura: Scans nearby enemies in range and automatically strikes
           - Auto Abilities: Auto-casts Q & E spells when off cooldown
           - Bypasses busyCasting combat lockups & checks peaceful status
        3. AUTO PLAY ENGINE (DIRECT ENEMY WALKING & AFK FARM):
           - Auto Play: Character walks directly on enemies at speed 20
           - Direct Navigation: Faces mob, triggers MoveTo and ground step move
           - Auto Start: Drops initial barrier and starts dungeon automatically
           - Auto Replay: Seamless instant dungeon restart on victory
           - Noclip: Auto bypasses walls, gates, and dungeon barriers on Stepped
           - Walk Distance slider: Configurable approach distance (0 to 6 studs)
        4. PERSISTENCE:
           - Auto-Execute Persistence (Teleport & Server Hop via queue_on_teleport)
           - Executor autoexec folder support
    ═════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")

-- Ensure game and LocalPlayer are loaded (handles early autoexec and teleports)
if not game:IsLoaded() then
    pcall(function()
        game.Loaded:Wait()
    end)
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    pcall(function()
        LocalPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    end)
    if not LocalPlayer then
        LocalPlayer = Players.LocalPlayer
    end
end
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

-- Clean up any prior running instances
local GlobalEnv = (getgenv and getgenv()) or _G
if GlobalEnv.ShadcnWalkSpeed and type(GlobalEnv.ShadcnWalkSpeed.Destroy) == "function" then
    pcall(GlobalEnv.ShadcnWalkSpeed.Destroy)
end

--------------------------------------------------------------------------------
-- DESIGN SYSTEM TOKENS (shadcn/ui Dark Mode)
--------------------------------------------------------------------------------
local MIN_SPEED = 0
local MAX_SPEED = 20
local DEFAULT_SPEED = 20
local currentSpeed = DEFAULT_SPEED
local connections = {}
local isRunning = true

local ICONS = {
    Gauge     = "rbxassetid://10723395708", -- lucide-gauge
    Swords    = "rbxassetid://10734975692", -- lucide-swords
    Target    = "rbxassetid://10734977012", -- lucide-target
    Flame     = "rbxassetid://10723376114", -- lucide-flame
    RotateCcw = "rbxassetid://10734940376", -- lucide-rotate-ccw
    Close     = "rbxassetid://10747384394", -- lucide-x
    Minus     = "rbxassetid://10734896206", -- lucide-minus
    Plus      = "rbxassetid://10734924532", -- lucide-plus
    Repeat    = "rbxassetid://10734933966", -- lucide-repeat
    Bot       = "rbxassetid://10709782230", -- lucide-bot
    Play      = "rbxassetid://10734923549", -- lucide-play
}

local SHADCN = {
    Background       = Color3.fromRGB(9, 9, 11),       -- #09090b
    Card             = Color3.fromRGB(12, 12, 16),     -- #0c0c10
    CardHeader       = Color3.fromRGB(16, 16, 21),     -- elevated header
    Border           = Color3.fromRGB(39, 39, 42),     -- #27272a (zinc-800)
    BorderHover      = Color3.fromRGB(63, 63, 70),     -- #3f3f46 (zinc-700)
    RingFocus        = Color3.fromRGB(244, 244, 245),  -- focus ring
    Foreground       = Color3.fromRGB(250, 250, 250),  -- #fafafa
    MutedForeground  = Color3.fromRGB(161, 161, 170),  -- #a1a1aa
    Muted            = Color3.fromRGB(24, 24, 27),     -- #18181b (secondary)
    MutedHover       = Color3.fromRGB(39, 39, 42),     -- #27272a
    Primary          = Color3.fromRGB(250, 250, 250),  -- white slider fill & active tab
    PrimaryText      = Color3.fromRGB(9, 9, 11),       -- dark text on primary fill
    Track            = Color3.fromRGB(39, 39, 42),     -- slider track
    SuccessDot       = Color3.fromRGB(34, 197, 94),    -- emerald live status
    DestructiveHover = Color3.fromRGB(45, 18, 22),
    DestructiveText  = Color3.fromRGB(248, 113, 113)
}

--------------------------------------------------------------------------------
-- SAFE GUI PARENTING
--------------------------------------------------------------------------------
local function GetSafeGuiParent()
    if gethui then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    if CoreGui then
        local ok, res = pcall(function() return CoreGui end)
        if ok and res then return res end
    end
    local playerGui = LocalPlayer and (LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 2))
    return playerGui or CoreGui
end

--------------------------------------------------------------------------------
-- WALKSPEED CORE & ANTI-RESET ENGINE
--------------------------------------------------------------------------------
local function GetHumanoid()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function ApplySpeed()
    if not isRunning then return end
    local hum = GetHumanoid()
    if hum and hum.WalkSpeed ~= currentSpeed then
        hum.WalkSpeed = currentSpeed
    end
end

-- Re-apply on property change to bypass game scripts that enforce WalkSpeed = 16
local humConn = nil
local function HookHumanoid(hum)
    if humConn then
        humConn:Disconnect()
        humConn = nil
    end
    if not hum then return end
    humConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if isRunning and hum.WalkSpeed ~= currentSpeed then
            hum.WalkSpeed = currentSpeed
        end
    end)
    table.insert(connections, humConn)
end

-- Auto-rebind upon character respawn/death
if LocalPlayer then
    local charConn = LocalPlayer.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 4)
        if hum then
            HookHumanoid(hum)
            hum.WalkSpeed = currentSpeed
        end
    end)
    table.insert(connections, charConn)

    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            HookHumanoid(hum)
            hum.WalkSpeed = currentSpeed
        end
    end
end

-- Continuous frame loops for persistent enforcement
table.insert(connections, RunService.Heartbeat:Connect(ApplySpeed))
table.insert(connections, RunService.PreSimulation:Connect(ApplySpeed))

--------------------------------------------------------------------------------
-- COMBAT ENGINE (AUTO SWING & KILL AURA)
--------------------------------------------------------------------------------
local CombatState = {
    AutoSwing     = false,
    KillAura      = false,
    AutoAbilities = true,
    AuraRange     = 35,
    SwingDelay    = 0.07,
}

-- Dynamic Remotes resolution
local function GetRemotes()
    local r = ReplicatedStorage:FindFirstChild("remotes")
    if not r then
        r = ReplicatedStorage:WaitForChild("remotes", 2)
    end
    return r
end

local function GetEquippedWeapon(char)
    char = char or LocalPlayer.Character
    if not char then return nil end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") and child:FindFirstChild("Weapon") then
            return child
        end
    end
    -- Fallback: check Tools or accessories with RemoteEvent
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") or (child:IsA("Accessory") and (child:FindFirstChildOfClass("RemoteEvent") or child:FindFirstChild("swing"))) then
            return child
        end
    end
    return nil
end

local function UpdateHitboxExpansion()
    local char = LocalPlayer.Character
    if not char then return end

    local weapon = GetEquippedWeapon(char)
    if not weapon then return end

    local hitBox = weapon:FindFirstChild("hitBox")
    if hitBox and hitBox:IsA("BasePart") then
        if hitBox.Size.X < 20 then
            hitBox.Size = Vector3.new(22, 22, 22)
            hitBox.CanCollide = false
            hitBox.Massless = true
        end
    end
end

local function PerformAttack(target)
    local char = LocalPlayer.Character
    if not char then return end

    -- Check peaceful town status
    local peaceful = LocalPlayer:FindFirstChild("peaceful")
    if peaceful and peaceful.Value == true then return end

    -- Reset busy casting lock
    local busyCasting = char:FindFirstChild("busyCasting")
    if busyCasting and busyCasting.Value == true then
        busyCasting.Value = false
    end

    -- Expand weapon hitbox to ensure full hit registration
    UpdateHitboxExpansion()

    -- 1. Trigger weapon RemoteEvent (e.g. "swing")
    local weapon = GetEquippedWeapon(char)
    if weapon then
        local remote = weapon:FindFirstChildOfClass("RemoteEvent") or weapon:FindFirstChild("swing")
        if remote then
            pcall(function() remote:FireServer() end)
        end
    else
        -- Scan character for any attack/swing remote
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("RemoteEvent") and (desc.Name:lower():find("swing") or desc.Name:lower():find("attack")) then
                pcall(function() desc:FireServer() end)
                break
            end
        end
    end

    -- 2. Trigger core weaponUsed remote
    local remotesFolder = GetRemotes()
    if remotesFolder then
        local wUsed = remotesFolder:FindFirstChild("weaponUsed")
        if wUsed then
            pcall(function() wUsed:FireServer() end)
        end
    end
end

local function GetAbilityTool(slot)
    local slotKey = string.lower(tostring(slot))
    local lp = LocalPlayer
    if not lp then return nil end

    -- Check Backpack
    local bp = lp:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            local as = tool:FindFirstChild("abilitySlot")
            if as and string.lower(tostring(as.Value)) == slotKey then
                return tool
            end
        end
    end

    -- Check Character
    local char = lp.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") or tool:IsA("Accessory") then
                local as = tool:FindFirstChild("abilitySlot")
                if as and string.lower(tostring(as.Value)) == slotKey then
                    return tool
                end
            end
        end
    end
    return nil
end

local function IsAbilityReady(tool)
    if not tool then return false end
    local cd = tool:FindFirstChild("cooldown")
    if cd and tonumber(cd.Value) and tonumber(cd.Value) > 0 then
        return false
    end
    return true
end

local function CastAbilitySlot(slot)
    local tool = GetAbilityTool(slot)
    if not tool or not IsAbilityReady(tool) then return false end

    local char = LocalPlayer.Character
    if char then
        local busy = char:FindFirstChild("busyCasting")
        if busy and busy.Value == true then
            busy.Value = false
        end
    end

    -- 1. Tool RemoteEvent
    local remote = tool:FindFirstChildOfClass("RemoteEvent")
    if remote then
        pcall(function() remote:FireServer() end)
    end

    -- 2. Tool localEvent
    local localEvent = tool:FindFirstChild("localEvent")
    if localEvent then
        pcall(function() localEvent:Fire() end)
    end

    -- 3. abilityUsed RemoteEvent
    local remotesFolder = GetRemotes()
    if remotesFolder then
        local abUsed = remotesFolder:FindFirstChild("abilityUsed")
        if abUsed then
            pcall(function() abUsed:FireServer(string.lower(slot), tool) end)
        end
    end

    return true
end

local function GetAliveEnemies(maxRange)
    local char = LocalPlayer.Character
    if not char then return {} end
    local myRoot = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not myRoot then return {} end

    local list = {}
    local myPos = myRoot.Position
    local checkedModels = {}

    -- Scan room-by-room, dungeon descendants, enemies folder, or workspace
    local rootContainer = workspace:FindFirstChild("dungeon") or workspace:FindFirstChild("enemies") or workspace

    for _, desc in ipairs(rootContainer:GetDescendants()) do
        if desc:IsA("Humanoid") and desc.Health > 0 then
            local enemyModel = desc.Parent
            if enemyModel and enemyModel:IsA("Model") and enemyModel ~= char and not checkedModels[enemyModel] then
                checkedModels[enemyModel] = true
                -- Exclude players
                if not Players:GetPlayerFromCharacter(enemyModel) then
                    local eRoot = enemyModel:FindFirstChild("HumanoidRootPart") 
                               or enemyModel:FindFirstChild("Head") 
                               or enemyModel:FindFirstChild("Torso") 
                               or enemyModel:FindFirstChild("UpperTorso")
                    if eRoot then
                        local dist = (myPos - eRoot.Position).Magnitude
                        if dist <= maxRange then
                            table.insert(list, {
                                Model = enemyModel,
                                Humanoid = desc,
                                RootPart = eRoot,
                                Distance = dist
                            })
                        end
                    end
                end
            end
        end
    end

    table.sort(list, function(a, b) return a.Distance < b.Distance end)
    return list
end

-- Auto Swing Loop
task.spawn(function()
    while isRunning do
        if CombatState.AutoSwing then
            pcall(function()
                PerformAttack(nil)
            end)
        end
        task.wait(CombatState.SwingDelay)
    end
end)

-- Kill Aura Loop
task.spawn(function()
    while isRunning do
        if CombatState.KillAura then
            local enemies = GetAliveEnemies(CombatState.AuraRange)
            if #enemies > 0 then
                local target = enemies[1]
                pcall(function()
                    PerformAttack(target.Model or target)
                end)
                if CombatState.AutoAbilities then
                    pcall(function() CastAbilitySlot("q") end)
                    pcall(function() CastAbilitySlot("e") end)
                end
            end
        end
        task.wait(CombatState.SwingDelay)
    end
end)

table.insert(connections, RunService.Heartbeat:Connect(function()
    if isRunning then
        pcall(UpdateHitboxExpansion)
    end
end))

-- Standalone Auto Abilities Loop (Runs when Auto Abilities is ON)
task.spawn(function()
    while isRunning do
        if CombatState.AutoAbilities and not CombatState.KillAura then
            local enemies = GetAliveEnemies(CombatState.AuraRange)
            if #enemies > 0 then
                pcall(function() CastAbilitySlot("q") end)
                pcall(function() CastAbilitySlot("e") end)
            end
        end
        task.wait(0.12)
    end
end)

--------------------------------------------------------------------------------
-- AUTO PLAY & AFK DUNGEON FARM ENGINE
--------------------------------------------------------------------------------
local AutoPlayState = {
    Enabled             = true,
    AutoStart           = true,
    AutoReplay          = true,
    ClearNearestFirst   = true,
    ApproachDistance    = 1.5,
    AutoRejoin          = true,
    AutoCreateDungeon   = true,
    AutoSkipIntro       = true,
    TargetDungeon       = "Desert Temple",
    TargetDifficulty    = "Nightmare",
    TargetHardcore      = true,
    TargetLevelReq      = 0,
    LastStartTick       = 0,
    LastReplayTick      = 0,
    LastStageSwitchTick = 0,
    LastAttackTick      = 0,
    LastSpellQTick      = 0,
    LastSpellETick      = 0,
    LastLobbyActionTick = 0,
    CurrentTarget       = nil,
    LastStuckPos        = Vector3.zero,
    StuckTime           = 0,
}

if LocalPlayer then
    table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
        AutoPlayState.CurrentTarget = nil
        AutoPlayState.LastStuckPos = Vector3.zero
        AutoPlayState.StuckTime = 0
    end))
end

local function GetOrderedDungeonRooms()
    local dungeon = workspace:FindFirstChild("dungeon")
    if not dungeon then return {} end

    local rooms = {}
    for _, room in ipairs(dungeon:GetChildren()) do
        if room:IsA("Model") or room:IsA("Folder") then
            local orderVal = room:FindFirstChild("order")
            local ordNum = orderVal and tonumber(orderVal.Value)
            if not ordNum then
                local numInName = tonumber(string.match(room.Name, "%d+"))
                if numInName then
                    ordNum = numInName
                end
            end
            if ordNum then
                table.insert(rooms, { Room = room, Order = ordNum })
            elseif room.Name ~= "initialRoom" and (room:FindFirstChild("enemyFolder") or room:FindFirstChild("enemies") or room:FindFirstChild("mobs")) then
                table.insert(rooms, { Room = room, Order = 9000 })
            end
        end
    end

    table.sort(rooms, function(a, b) return a.Order < b.Order end)

    local bossRoom = dungeon:FindFirstChild("bossRoom")
    if bossRoom then
        local found = false
        for _, r in ipairs(rooms) do
            if r.Room == bossRoom then found = true break end
        end
        if not found then
            table.insert(rooms, { Room = bossRoom, Order = 9999 })
        end
    end

    return rooms
end

local function GetAliveEnemiesInDungeonRoom(room)
    local alive = {}
    if not room then return alive end

    local checked = {}
    for _, desc in ipairs(room:GetDescendants()) do
        if desc:IsA("Humanoid") and desc.Health > 0 then
            local model = desc.Parent
            if model and model:IsA("Model") and model ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(model) and not checked[model] then
                checked[model] = true
                local hrp = model:FindFirstChild("HumanoidRootPart") 
                         or model:FindFirstChild("Head") 
                         or model:FindFirstChild("Torso") 
                         or model:FindFirstChild("UpperTorso")
                if hrp then
                    table.insert(alive, model)
                end
            end
        end
    end

    return alive
end

local function GetActiveDungeonTarget()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not hrp then return nil, nil end
    local myPos = hrp.Position

    -- 1. Focus & Clear Current Target (finish off current enemy before switching, unless an enemy is in melee face range)
    local current = AutoPlayState.CurrentTarget
    if current and current.Parent then
        local cHum = current:FindFirstChildOfClass("Humanoid")
        local cHrp = current:FindFirstChild("HumanoidRootPart") or current:FindFirstChild("Head") or current:FindFirstChild("Torso") or current:FindFirstChild("UpperTorso")
        if cHum and cHum.Health > 0 and cHrp then
            local cDist = (cHrp.Position - myPos).Magnitude
            local immediateThreats = GetAliveEnemies(8)
            if #immediateThreats == 0 or immediateThreats[1].Model == current or cDist <= 10 then
                return current, current.Parent
            end
        else
            AutoPlayState.CurrentTarget = nil
        end
    else
        AutoPlayState.CurrentTarget = nil
    end

    -- 2. Immediate Area Priority: strictly clear the nearest living enemy within 50 studs first
    if AutoPlayState.ClearNearestFirst then
        local nearbyEnemies = GetAliveEnemies(50)
        if #nearbyEnemies > 0 then
            return nearbyEnemies[1].Model, nearbyEnemies[1].Model.Parent
        end
    end

    -- 3. Room Progression Order: find first active room and target the closest enemy in that room
    local rooms = GetOrderedDungeonRooms()
    for _, item in ipairs(rooms) do
        local enemies = GetAliveEnemiesInDungeonRoom(item.Room)
        if #enemies > 0 then
            local closest, minDist = nil, math.huge
            for _, e in ipairs(enemies) do
                local eRoot = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("Head") or e:FindFirstChild("Torso") or e:FindFirstChild("UpperTorso")
                if eRoot then
                    local d = (eRoot.Position - myPos).Magnitude
                    if d < minDist then
                        minDist = d
                        closest = e
                    end
                end
            end
            if closest then
                return closest, item.Room
            end
        end
    end

    -- 4. Global fallback: closest alive enemy anywhere in dungeon
    local globalEnemies = GetAliveEnemies(1000)
    if #globalEnemies > 0 then
        return globalEnemies[1].Model, nil
    end

    return nil, nil
end

local function CheckAutoStartDungeon()
    if not AutoPlayState.AutoStart then return end

    local startVal = workspace:FindFirstChild("start") or workspace:FindFirstChild("dungeonStarted")
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local startBtn = pgui and pgui:FindFirstChild("startButton")
    local needStart = (startVal and startVal.Value == false) or (startBtn ~= nil)

    if needStart then
        local now = os.clock()
        if (now - AutoPlayState.LastStartTick) >= 1.2 then
            AutoPlayState.LastStartTick = now
            local remotes = GetRemotes()
            if remotes and remotes:FindFirstChild("changeStartValue") then
                pcall(function() remotes.changeStartValue:FireServer() end)
            end
            if startBtn then
                pcall(function() startBtn:Destroy() end)
            end
        end
    end
end

local function IsBossRaid()
    local dungeonName = workspace:FindFirstChild("dungeonName")
    if dungeonName and dungeonName:IsA("StringValue") then
        local ok, res = pcall(function()
            local modules = ReplicatedStorage:FindFirstChild("modules")
            local bri = modules and modules:FindFirstChild("BossRaidInfo")
            if bri then
                local BossRaidInfo = require(bri)
                if BossRaidInfo and BossRaidInfo.isBossRaidName then
                    return BossRaidInfo.isBossRaidName(dungeonName.Value)
                end
            end
            return false
        end)
        if ok and res ~= nil then return res end
        return string.find(string.lower(dungeonName.Value), "raid") ~= nil
    end
    return false
end

local function CollectDungeonData()
    local data = {}
    local dungeonName = workspace:FindFirstChild("dungeonName")
    if dungeonName and dungeonName:IsA("StringValue") then
        data.dungeonName = dungeonName.Value
    end

    local dungeonProgress = workspace:FindFirstChild("dungeonProgress")
    if dungeonProgress and dungeonProgress:IsA("StringValue") then
        data.dungeonProgress = dungeonProgress.Value
    end

    local dungeonStarted = workspace:FindFirstChild("dungeonStarted")
    if dungeonStarted and dungeonStarted:IsA("BoolValue") then
        data.dungeonStarted = dungeonStarted.Value
    end

    local hardcore = workspace:FindFirstChild("hardcore")
    if hardcore and hardcore:IsA("BoolValue") then
        data.hardcore = hardcore.Value
        data.isHardcore = hardcore.Value
    end

    local dungeon = workspace:FindFirstChild("dungeon")
    if dungeon then
        for _, child in ipairs(dungeon:GetChildren()) do
            if child:IsA("ValueBase") then
                data[child.Name] = child.Value
            end
        end

        local bossRoom = dungeon:FindFirstChild("bossRoom")
        if bossRoom then
            for _, child in ipairs(bossRoom:GetChildren()) do
                if child:IsA("ValueBase") then
                    data[child.Name] = child.Value
                end
            end
        end
    end

    return data
end

local function IsDungeonFinished()
    local dungeon = workspace:FindFirstChild("dungeon")
    if not dungeon then return false end

    -- Guard: dungeon must have started and not be in initial countdown
    local dungeonStarted = workspace:FindFirstChild("dungeonStarted")
    if dungeonStarted and dungeonStarted:IsA("BoolValue") and dungeonStarted.Value == false then
        return false
    end

    -- Check Boss Raid completion
    if IsBossRaid() then
        local dungeonProgress = workspace:FindFirstChild("dungeonProgress")
        if dungeonProgress and dungeonProgress:IsA("StringValue") and dungeonProgress.Value == "bossKilled" then
            return true
        end
        return false
    end

    -- Check standard dungeon boss room completion
    local bossRoom = dungeon:FindFirstChild("bossRoom")
    if bossRoom then
        local finishedVal = bossRoom:FindFirstChild("dungeonFinished")
        if finishedVal and finishedVal:IsA("BoolValue") and finishedVal.Value == true then
            return true
        end
    end

    return false
end

local function CheckAutoReplayDungeon()
    if not AutoPlayState.AutoReplay then return end

    if IsDungeonFinished() then
        local now = os.clock()
        if (now - AutoPlayState.LastReplayTick) >= 3.0 then
            AutoPlayState.LastReplayTick = now

            local data = CollectDungeonData()
            if not data.dungeonName then
                local dName = workspace:FindFirstChild("dungeonName")
                if dName and dName:IsA("StringValue") then
                    data.dungeonName = dName.Value
                end
            end

            -- If it's a boss raid and has BossRaidReplayMenu, open menu
            if IsBossRaid() then
                local pgui = LocalPlayer:FindFirstChild("PlayerGui")
                local bossMenu = pgui and pgui:FindFirstChild("BossRaidReplayMenu")
                local menuScript = bossMenu and bossMenu:FindFirstChild("MenuScript")
                local openMenu = menuScript and menuScript:FindFirstChild("OpenMenu")
                if openMenu then
                    pcall(function() openMenu:Fire(data) end)
                    return
                end
            end

            -- Direct replay remote dispatch with collected dungeon data
            local remotes = GetRemotes()
            if remotes and remotes:FindFirstChild("replayDungeon") then
                pcall(function()
                    remotes.replayDungeon:FireServer(data)
                end)
            end
        end
    end
end

-- Main AutoPlay Frame Tick (Direct Walking on Enemies with Speed 20)
local function StepAutoPlay(dt)
    if not isRunning or not AutoPlayState.Enabled then
        AutoPlayState.CurrentTarget = nil
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hrp or not hum or hum.Health <= 0 then 
        AutoPlayState.CurrentTarget = nil
        return 
    end

    -- Strictly enforce walkspeed 20 (or configured speed)
    if hum.WalkSpeed ~= currentSpeed then
        hum.WalkSpeed = currentSpeed
    end

    -- 1. Auto Start & Auto Replay
    CheckAutoStartDungeon()
    CheckAutoReplayDungeon()

    -- 2. Find Current Target (strictly nearest enemy first)
    local target, currentRoom = GetActiveDungeonTarget()
    AutoPlayState.CurrentTarget = target

    if target and target.Parent then
        local targetHum = target:FindFirstChildOfClass("Humanoid")
        local targetHrp = target:FindFirstChild("HumanoidRootPart") 
                       or target:FindFirstChild("Head") 
                       or target:FindFirstChild("Torso") 
                       or target:FindFirstChild("UpperTorso")

        -- If target died during combat, immediately clear so next nearest is acquired instantly
        if not targetHum or targetHum.Health <= 0 then
            AutoPlayState.CurrentTarget = nil
            return
        end

        if targetHrp then
            local targetPos = targetHrp.Position
            local playerPos = hrp.Position
            local flatPlayerPos = Vector3.new(playerPos.X, 0, playerPos.Z)
            local flatTargetPos = Vector3.new(targetPos.X, 0, targetPos.Z)
            local flatDiff = flatTargetPos - flatPlayerPos
            local flatDist = flatDiff.Magnitude

            -- Rotate character smoothly towards enemy on the horizontal plane
            if flatDist > 0.3 then
                local lookPos = Vector3.new(targetPos.X, playerPos.Y, targetPos.Z)
                hrp.CFrame = CFrame.lookAt(playerPos, lookPos)
            end

            -- Ground walking towards the target
            local minStopDist = math.max(AutoPlayState.ApproachDistance or 1.5, 1.0) + 1.2
            if flatDist > minStopDist then
                hum:MoveTo(targetPos)

                -- Anti-Stuck jump system: hops over stairs, rocks, or rubble if blocked
                local deltaMoved = (flatPlayerPos - Vector3.new(AutoPlayState.LastStuckPos.X, 0, AutoPlayState.LastStuckPos.Z)).Magnitude
                if deltaMoved < 0.5 then
                    AutoPlayState.StuckTime = AutoPlayState.StuckTime + (dt or 0.016)
                    if AutoPlayState.StuckTime > 0.45 then
                        hum.Jump = true
                        AutoPlayState.StuckTime = 0
                    end
                else
                    AutoPlayState.StuckTime = 0
                    AutoPlayState.LastStuckPos = playerPos
                end
            else
                -- In close melee range: hold position firmly to avoid pushing/jitter
                hum:MoveTo(playerPos)
                AutoPlayState.StuckTime = 0
                AutoPlayState.LastStuckPos = playerPos
            end

            -- Keep physics stable without freezing natural walking
            hrp.AssemblyAngularVelocity = Vector3.zero

            -- Rapid weapon & skill execution directly on the mob
            local now = os.clock()
            if (now - AutoPlayState.LastAttackTick) >= CombatState.SwingDelay then
                AutoPlayState.LastAttackTick = now
                pcall(function()
                    PerformAttack(target)
                end)
            end

            -- Cast spells when within combat range (flatDist <= 24) or when health is low (< 50% for auto-heal/defense)
            local isLowHealth = (hum.Health / math.max(hum.MaxHealth, 1)) < 0.5
            if flatDist <= 24 or isLowHealth then
                if (now - AutoPlayState.LastSpellQTick) >= 0.28 then
                    AutoPlayState.LastSpellQTick = now
                    pcall(function() CastAbilitySlot("q") end)
                end

                if (now - AutoPlayState.LastSpellETick) >= 0.28 then
                    AutoPlayState.LastSpellETick = now
                    pcall(function() CastAbilitySlot("e") end)
                end
            end
        end
    else
        -- 3. No active enemy in current area -> Walk directly to next stage / barrier / checkpoint
        AutoPlayState.CurrentTarget = nil
        local rooms = GetOrderedDungeonRooms()
        for _, rInfo in ipairs(rooms) do
            local r = rInfo.Room
            local checkPoint = r:FindFirstChild("checkPoint")
            local startPart = r:FindFirstChild("startPart")
            local barrier = r:FindFirstChild("barrier")
            if barrier and barrier.CanCollide then
                local dest = startPart and startPart.Position or (checkPoint and checkPoint.Position)
                if dest then
                    local flatPlayerPos = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
                    local flatDest = Vector3.new(dest.X, 0, dest.Z)
                    local d = (flatDest - flatPlayerPos).Magnitude
                    if d > 1.5 then
                        hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(dest.X, hrp.Position.Y, dest.Z))
                        hum:MoveTo(dest)

                        -- Anti-stuck jump towards barrier / door
                        local deltaMoved = (flatPlayerPos - Vector3.new(AutoPlayState.LastStuckPos.X, 0, AutoPlayState.LastStuckPos.Z)).Magnitude
                        if deltaMoved < 0.5 then
                            AutoPlayState.StuckTime = AutoPlayState.StuckTime + (dt or 0.016)
                            if AutoPlayState.StuckTime > 0.45 then
                                hum.Jump = true
                                AutoPlayState.StuckTime = 0
                            end
                        else
                            AutoPlayState.StuckTime = 0
                            AutoPlayState.LastStuckPos = hrp.Position
                        end
                    end
                    break
                end
            elseif checkPoint and (Vector3.new(checkPoint.Position.X, 0, checkPoint.Position.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude > 4 then
                local dest = checkPoint.Position
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(dest.X, hrp.Position.Y, dest.Z))
                hum:MoveTo(dest)
                break
            end
        end
    end
end

-- Connect StepAutoPlay on Heartbeat
table.insert(connections, RunService.Heartbeat:Connect(StepAutoPlay))

-- Noclip loop for passing seamlessly through gates, walls, and barriers
table.insert(connections, RunService.Stepped:Connect(function()
    if isRunning and AutoPlayState.Enabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end))

--------------------------------------------------------------------------------
-- LOBBY & DUNGEON DETECTION HELPERS
--------------------------------------------------------------------------------
-- Target Place ID: strictly Dungeon Quest Reborn (77649408247578)
local DUNGEON_QUEST_REBORN_PLACE_ID = 77649408247578

local function IsInDungeon()
    -- 1. If PlaceId is not the main lobby, we are definitely in a dungeon sub-place
    if game.PlaceId ~= DUNGEON_QUEST_REBORN_PLACE_ID then
        return true
    end
    -- 2. If workspace.dungeon exists, we are in a dungeon
    local dungeon = workspace:FindFirstChild("dungeon") or workspace:FindFirstChild("Dungeon")
    if dungeon and #dungeon:GetChildren() > 0 then
        return true
    end
    -- 3. In the dungeon, workspace.games does NOT exist (workspace.games only exists in the lobby)
    if not workspace:FindFirstChild("games") and not workspace:FindFirstChild("Lobby") then
        return true
    end
    -- 4. Dungeon-specific values in workspace
    if (workspace:FindFirstChild("dungeonName") or workspace:FindFirstChild("dungeonStarted")) and not workspace:FindFirstChild("games") then
        return true
    end
    return false
end

local function IsInLobby()
    -- We are strictly in the lobby ONLY if workspace.games exists AND we are not in a dungeon
    if workspace:FindFirstChild("games") and not workspace:FindFirstChild("dungeon") then
        return true
    end
    return not IsInDungeon()
end

-- Persist known Lobby Place ID (ensuring Dungeon Quest Reborn)
if IsInLobby() then
    GlobalEnv.DQLobbyPlaceId = game.PlaceId
    pcall(function()
        if writefile then
            writefile("dq_lobby_place.txt", tostring(game.PlaceId))
        end
    end)
else
    local loadedId = nil
    pcall(function()
        if readfile and isfile and isfile("dq_lobby_place.txt") then
            loadedId = tonumber(readfile("dq_lobby_place.txt"))
        end
    end)
    -- Exclude original Dungeon Quest (2414851778), strictly enforce Reborn
    if loadedId and loadedId ~= 2414851778 and loadedId > 0 then
        GlobalEnv.DQLobbyPlaceId = loadedId
    else
        GlobalEnv.DQLobbyPlaceId = DUNGEON_QUEST_REBORN_PLACE_ID
    end
end

local function GetPlayerLobbyStatus()
    local lp = LocalPlayer
    if not lp then return false, false, nil end

    -- 1. Check PlayerGui queueGui state
    local pgui = lp:FindFirstChildOfClass("PlayerGui")
    local queueGui = pgui and pgui:FindFirstChild("queueGui")
    if queueGui then
        local lobbyInfo = queueGui:FindFirstChild("lobbyInfo")
        if lobbyInfo and lobbyInfo.Visible then
            local startBg = lobbyInfo:FindFirstChild("startBackground")
            local isHost = (startBg ~= nil and startBg.Visible == true)
            return true, isHost, nil
        end
    end

    -- 2. Check workspace.games.inLobby
    local games = workspace:FindFirstChild("games")
    if games then
        local inLobby = games:FindFirstChild("inLobby")
        if inLobby then
            for _, lobby in ipairs(inLobby:GetChildren()) do
                if lobby.Name == lp.Name then
                    return true, true, lobby
                end
                if lobby:FindFirstChild(lp.Name) then
                    return true, (lobby.Name == lp.Name), lobby
                end
                local roster = lobby:GetAttribute("Roster")
                if type(roster) == "string" and roster:find(lp.Name) then
                    local isHost = (lobby.Name == lp.Name) or (roster:find('"o":true') ~= nil and roster:find(lp.Name) ~= nil)
                    return true, isHost, lobby
                end
                for _, child in ipairs(lobby:GetChildren()) do
                    if child.Name == lp.Name then
                        return true, (lobby.Name == lp.Name), lobby
                    end
                end
            end
        end

        local inGame = games:FindFirstChild("inGame")
        if inGame then
            for _, lobby in ipairs(inGame:GetChildren()) do
                if lobby.Name == lp.Name or lobby:FindFirstChild(lp.Name) then
                    return true, (lobby.Name == lp.Name), lobby
                end
                local roster = lobby:GetAttribute("Roster")
                if type(roster) == "string" and roster:find(lp.Name) then
                    return true, (lobby.Name == lp.Name), lobby
                end
            end
        end
    end

    return false, false, nil
end

local function inALobby(player)
    local inParty = GetPlayerLobbyStatus()
    return inParty
end

local function findLobby(player)
    local inParty, isHost, lobbyObj = GetPlayerLobbyStatus()
    return lobbyObj
end

--------------------------------------------------------------------------------
-- INTRO BYPASS ENGINE (Auto-Click Play & Spawn Character)
--------------------------------------------------------------------------------
local function HandleIntroScreen()
    if not AutoPlayState.AutoSkipIntro then return end

    local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
    if not pgui then return end

    -- Locate cameraIntro or intro screen
    local camIntro = pgui:FindFirstChild("cameraIntro")
    if not camIntro then
        for _, child in ipairs(pgui:GetChildren()) do
            if child:IsA("ScreenGui") and (child.Name:lower():find("intro") or child:FindFirstChild("title") or child:FindFirstChild("screenCover")) then
                camIntro = child
                break
            end
        end
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local needsSpawn = (camIntro ~= nil) or (hrp == nil)

    if needsSpawn then
        -- 1. Click TextButton inside intro screen if present
        if camIntro then
            pcall(function()
                local textBtn = camIntro:FindFirstChildWhichIsA("TextButton", true)
                if textBtn and textBtn:IsA("GuiButton") then
                    if firesignal then
                        pcall(function() firesignal(textBtn.Activated) end)
                        pcall(function() firesignal(textBtn.MouseButton1Click) end)
                        pcall(function() firesignal(textBtn.MouseButton1Down) end)
                    end
                end
            end)
        end

        -- 2. Dispatch loadPlayerCharacter remote
        local remotes = GetRemotes()
        if remotes and remotes:FindFirstChild("loadPlayerCharacter") then
            pcall(function()
                remotes.loadPlayerCharacter:FireServer(nil, true)
            end)
        end

        -- 3. Unhide essential interface HUDs
        local hudList = { "mainInterface", "leaderboard", "friendsList", "abilities", "playerStatus", "queueGui" }
        for _, hName in ipairs(hudList) do
            local hGui = pgui:FindFirstChild(hName)
            if hGui and hGui:IsA("ScreenGui") then
                hGui.Enabled = true
            end
        end

        -- 4. Clean up any BlurEffect in Lighting
        pcall(function()
            for _, obj in ipairs(game:GetService("Lighting"):GetChildren()) do
                if obj:IsA("BlurEffect") then
                    obj:Destroy()
                end
            end
        end)

        -- 5. Restore camera to custom & follow humanoid
        pcall(function()
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            local c = LocalPlayer.Character
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if hum then
                workspace.CurrentCamera.CameraSubject = hum
            end
        end)

        -- 6. Destroy intro screen
        if camIntro then
            pcall(function() camIntro:Destroy() end)
        end
    end
end

-- Run immediate intro bypass check
task.spawn(function()
    task.wait(0.5)
    pcall(HandleIntroScreen)
end)

--------------------------------------------------------------------------------
-- DUNGEON CREATION & AUTO START ENGINE (Desert Temple - Nightmare Hardcore)
--------------------------------------------------------------------------------
local isCreatingLobby = false

local function CreateDesertTempleLobby()
    if isCreatingLobby then return false end
    isCreatingLobby = true

    local remotes = GetRemotes()
    local createRemote = remotes and (remotes:FindFirstChild("createLobby") or remotes:WaitForChild("createLobby", 2))
    if not createRemote then
        warn("⚠️ [Dungeon Quest] remotes.createLobby not found!")
        isCreatingLobby = false
        return false
    end

    print("🏛️ [Dungeon Quest] Invoking createLobby: Desert Temple (Nightmare, Hardcore)...")
    local ok, res = pcall(function()
        if createRemote:IsA("RemoteFunction") then
            return createRemote:InvokeServer(
                "Desert Temple",                  -- Map Name
                "Nightmare",                      -- Difficulty
                0,                                -- Level Requirement
                true,                             -- Hardcore Mode
                false,                            -- Private = false
                false                             -- WaveDefense = false
            )
        else
            createRemote:FireServer(
                "Desert Temple",
                "Nightmare",
                0,
                true,
                false,
                false
            )
            return true
        end
    end)
    print("🏛️ [Dungeon Quest] createLobby result:", ok, tostring(res))
    isCreatingLobby = false
    return ok
end

local isStartingDungeon = false
local lastStartAttemptTick = 0

local function StartCreatedDungeon()
    local now = os.clock()
    if isStartingDungeon and (now - lastStartAttemptTick) < 25 then
        return
    end
    isStartingDungeon = true
    lastStartAttemptTick = now

    local remotes = GetRemotes()
    local startRemote = remotes and (remotes:FindFirstChild("startDungeon") or remotes:WaitForChild("startDungeon", 2))

    print("🚀 [Dungeon Quest] Starting Dungeon from Lobby...")
    if startRemote then
        pcall(function()
            if startRemote:IsA("RemoteFunction") then
                startRemote:InvokeServer()
            else
                startRemote:FireServer()
            end
        end)
    end

    -- Auto-hide startBackground in queueGui to reflect starting state cleanly
    pcall(function()
        local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local queueGui = pgui and pgui:FindFirstChild("queueGui")
        local lobbyInfo = queueGui and queueGui:FindFirstChild("lobbyInfo")
        local startBg = lobbyInfo and lobbyInfo:FindFirstChild("startBackground")
        if startBg then
            startBg.Visible = false
        end
    end)
end

local function CreateAndLaunchDungeon()
    if not IsInLobby() then return end
    local now = os.clock()
    if isStartingDungeon and (now - lastStartAttemptTick) < 25 then return end

    local inParty, isHost = GetPlayerLobbyStatus()
    if inParty then
        print("🚀 [Dungeon Quest] Already in party! Launching dungeon...")
        StartCreatedDungeon()
        return
    end

    print("🏛️ [Dungeon Quest] Creating Desert Temple (Nightmare, Hardcore)...")
    local ok = CreateDesertTempleLobby()
    if ok then
        -- Wait briefly for lobby registration, then launch once!
        task.delay(1.5, function()
            if isRunning and IsInLobby() and not isStartingDungeon then
                print("🚀 [Dungeon Quest] Launching created dungeon...")
                StartCreatedDungeon()
            end
        end)
    end
end

-- Lobby Supervisor Loop (Handles Intro -> Create Lobby -> Start Dungeon)
task.spawn(function()
    print("📋 [Dungeon Quest] Lobby Supervisor Thread Started.")
    while isRunning do
        if AutoPlayState.AutoCreateDungeon and IsInLobby() and not isStartingDungeon then
            -- 1. Ensure intro is bypassed & character is spawned
            pcall(HandleIntroScreen)

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local inParty, isHost = GetPlayerLobbyStatus()
                local now = os.clock()

                if inParty then
                    -- Already in lobby/party! Start the dungeon!
                    if (now - AutoPlayState.LastLobbyActionTick) >= 3.0 then
                        AutoPlayState.LastLobbyActionTick = now
                        print("🚀 [Dungeon Quest] Party detected. Starting dungeon...")
                        StartCreatedDungeon()
                    end
                else
                    -- Not in a lobby: create Desert Temple and launch
                    if (now - AutoPlayState.LastLobbyActionTick) >= 3.5 then
                        AutoPlayState.LastLobbyActionTick = now
                        print("⏳ [Dungeon Quest] In lobby without party. Creating & launching Desert Temple...")
                        CreateAndLaunchDungeon()
                    end
                end
            end
        end
        task.wait(1.0)
    end
end)

--------------------------------------------------------------------------------
-- AUTO-EXECUTE & TELEPORT PERSISTENCE ENGINE
--------------------------------------------------------------------------------
local autoExecuteEnabled = true

local function SetupAutoExecute()
    if not autoExecuteEnabled then return end

    -- 1. Queue on Teleport (Executes on server hop / place teleport)
    local queueFn = queue_on_teleport or (syn and syn.queue_on_teleport) or queueonteleport or (fluxus and fluxus.queue_on_teleport)
    if queueFn then
        local autoCode = [[
            task.wait(1.5)
            local files = {
                "dq.lua",
                "scripts/dq.lua",
                "kaizenn/dq.lua",
                "walkspeed.lua",
                "scripts/walkspeed.lua",
                "autoexec/dq.lua",
                "walkspeed_slider.luau"
            }
            local ran = false
            if readfile and isfile then
                for _, f in ipairs(files) do
                    if isfile(f) then
                        local src = readfile(f)
                        if src and #src > 100 then
                            local fn = loadstring(src)
                            if fn then
                                task.spawn(fn)
                                ran = true
                                break
                            end
                        end
                    end
                end
            end
        ]]
        pcall(function()
            queueFn(autoCode)
        end)

        if LocalPlayer and not LocalPlayer:GetAttribute("WalkSpeedTeleportHooked") then
            LocalPlayer:SetAttribute("WalkSpeedTeleportHooked", true)
            local tpConn = LocalPlayer.OnTeleport:Connect(function()
                if autoExecuteEnabled then
                    pcall(function()
                        queueFn(autoCode)
                    end)
                end
            end)
            table.insert(connections, tpConn)
        end
    end

    -- 2. Auto-save to executor autoexec folder if supported
    pcall(function()
        if writefile and readfile and isfile then
            local selfContent = nil
            for _, f in ipairs({ "dq.lua", "scripts/dq.lua", "kaizenn/dq.lua", "walkspeed.lua" }) do
                if isfile(f) then
                    selfContent = readfile(f)
                    if selfContent and #selfContent > 100 then break end
                end
            end

            if selfContent and #selfContent > 100 then
                if not isfile("autoexec/dq.lua") then
                    pcall(function() writefile("autoexec/dq.lua", selfContent) end)
                end
                if not isfile("dq.lua") then
                    pcall(function() writefile("dq.lua", selfContent) end)
                end
            end
        end
    end)
end
SetupAutoExecute()

--------------------------------------------------------------------------------
-- AUTO REJOIN ENGINE (On Kick, Disconnect, or Teleport Failure)
--------------------------------------------------------------------------------
local isAutoRejoining = false

local function TriggerAutoRejoin(reason)
    if isAutoRejoining then return end
    if not AutoPlayState.AutoRejoin then return end
    isAutoRejoining = true

    warn("🚨 [Auto Rejoin] Connection failure or kick detected (" .. tostring(reason) .. ")! Rejoining...")

    -- Ensure auto-execute script is queued for next teleport
    pcall(SetupAutoExecute)

    -- Destination: strictly Dungeon Quest Reborn (77649408247578)
    local targetPlace = DUNGEON_QUEST_REBORN_PLACE_ID
    if GlobalEnv.DQLobbyPlaceId and GlobalEnv.DQLobbyPlaceId ~= 2414851778 then
        targetPlace = GlobalEnv.DQLobbyPlaceId
    end

    print("🚀 [Auto Rejoin] Teleporting to Dungeon Quest Reborn (Place ID: " .. tostring(targetPlace) .. ")...")

    -- Click Retry / Reconnect button if present on screen
    pcall(function()
        local rPromptGui = CoreGui:FindFirstChild("RobloxPromptGui")
        local overlay = rPromptGui and rPromptGui:FindFirstChild("promptOverlay")
        local errorPrompt = overlay and overlay:FindFirstChild("ErrorPrompt")
        if errorPrompt then
            for _, btn in ipairs(errorPrompt:GetDescendants()) do
                if btn:IsA("GuiButton") and (btn.Name:lower():find("retry") or (btn:IsA("TextButton") and btn.Text:lower():find("retry"))) then
                    if firesignal then
                        pcall(function() firesignal(btn.MouseButton1Click) end)
                        pcall(function() firesignal(btn.Activated) end)
                    end
                end
            end
        end
    end)

    task.wait(1.0)
    task.spawn(function()
        while true do
            pcall(function()
                TeleportService:Teleport(targetPlace, LocalPlayer)
            end)
            task.wait(3.5)
        end
    end)
end

local function CheckForRealDisconnect(context)
    local hasError = false
    local errorReason = ""

    -- 1. Inspect CoreGui promptOverlay for visible ErrorPrompt or Connection Failed dialog
    pcall(function()
        local rPromptGui = CoreGui:FindFirstChild("RobloxPromptGui")
        if rPromptGui and rPromptGui.Enabled then
            local overlay = rPromptGui:FindFirstChild("promptOverlay")
            if overlay and overlay.Visible then
                local errorPrompt = overlay:FindFirstChild("ErrorPrompt")
                if errorPrompt and errorPrompt:IsA("GuiObject") and errorPrompt.Visible and errorPrompt.AbsoluteSize.Y > 30 then
                    local texts = {}
                    for _, desc in ipairs(errorPrompt:GetDescendants()) do
                        if desc:IsA("TextLabel") and #desc.Text > 0 then
                            table.insert(texts, desc.Text:lower())
                        end
                    end
                    local combined = table.concat(texts, " ")

                    if combined:find("connection failed")
                        or combined:find("failed to connect")
                        or combined:find("no response from server")
                        or combined:find("279")
                        or combined:find("error code: 279")
                        or combined:find("error code: 267")
                        or combined:find("error code: 268")
                        or combined:find("error code: 277")
                        or combined:find("error code: 273")
                        or combined:find("error code: 524")
                        or combined:find("disconnected")
                        or combined:find("you have been kicked")
                        or combined:find("unexpected client behavior")
                        or combined:find("lost connection")
                        or combined:find("shut down")
                    then
                        hasError = true
                        errorReason = "ErrorPrompt: " .. combined:sub(1, 120)
                    end
                end
            end
        end
    end)

    -- 2. Inspect GuiService ErrorCode
    if not hasError then
        pcall(function()
            local errCode = GuiService:GetErrorCode()
            local codeVal = typeof(errCode) == "EnumItem" and errCode.Value or tonumber(errCode)
            if codeVal and codeVal > 0 then
                hasError = true
                errorReason = "GuiService ErrorCode " .. tostring(codeVal)
            end
        end)
    end

    -- 3. Explicit context string check (from ErrorMessageChanged or TeleportInitFailed)
    if not hasError and context and typeof(context) == "string" and #context > 0 then
        local c = context:lower()
        if c:find("kick")
            or c:find("unexpected client behavior")
            or c:find("connection failed")
            or c:find("failed to connect")
            or c:find("no response from server")
            or c:find("lost connection")
            or c:find("error code")
            or c:find("279")
            or c:find("267")
            or c:find("268")
            or c:find("277")
        then
            hasError = true
            errorReason = "Context: " .. context
        end
    end

    if hasError then
        TriggerAutoRejoin(errorReason)
    end
end

-- Hook 1: GuiService.ErrorMessageChanged
table.insert(connections, GuiService.ErrorMessageChanged:Connect(function(msg)
    CheckForRealDisconnect(msg)
end))

-- Hook 2: ErrorPrompt inside CoreGui.RobloxPromptGui.promptOverlay
pcall(function()
    local rPromptGui = CoreGui:WaitForChild("RobloxPromptGui", 5)
    local overlay = rPromptGui and rPromptGui:WaitForChild("promptOverlay", 5)
    if overlay then
        table.insert(connections, overlay.ChildAdded:Connect(function(child)
            task.delay(0.3, function()
                CheckForRealDisconnect("ChildAdded: " .. child.Name)
            end)
        end))

        local errorPrompt = overlay:FindFirstChild("ErrorPrompt")
        if errorPrompt then
            table.insert(connections, errorPrompt:GetPropertyChangedSignal("Visible"):Connect(function()
                if errorPrompt.Visible then
                    task.delay(0.2, function()
                        CheckForRealDisconnect("ErrorPrompt Became Visible")
                    end)
                end
            end))
        end
    end
end)

-- Hook 3: TeleportService.TeleportInitFailed
table.insert(connections, TeleportService.TeleportInitFailed:Connect(function(player, result, err)
    TriggerAutoRejoin("TeleportInitFailed: " .. tostring(err) .. " (" .. tostring(result) .. ")")
end))

-- Continuous Auto-Rejoin Polling Thread (Guarantees detection within 1s of prompt appearing)
task.spawn(function()
    while isRunning do
        task.wait(1.0)
        pcall(function()
            CheckForRealDisconnect()
        end)
    end
end)

-- Anti-AFK Idle Disconnect Prevention (20 min idle timer reset)
if LocalPlayer then
    table.insert(connections, LocalPlayer.Idled:Connect(function()
        pcall(function()
            local vu = game:GetService("VirtualUser")
            if vu then
                vu:CaptureController()
                vu:ClickButton2(Vector2.new(0, 0))
            end
        end)
    end))
end

--------------------------------------------------------------------------------
-- GUI CONSTRUCTION (shadcn/ui Card Component)
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShadcnWalkSpeed_" .. math.random(100, 999)
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    ScreenGui.Parent = GetSafeGuiParent()
end)

-- Main Card Window (284px x 316px)
local Card = Instance.new("Frame")
Card.Name = "ShadcnCard"
Card.Size = UDim2.new(0, 292, 0, 324)
Card.Position = UDim2.new(0.06, 0, 0.20, 0)
Card.BackgroundColor3 = SHADCN.Card
Card.BorderSizePixel = 0
Card.ClipsDescendants = true
Card.ZIndex = 100
Card.Parent = ScreenGui

local CardCorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0, 8)
CardCorner.Parent = Card

local CardStroke = Instance.new("UIStroke")
CardStroke.Thickness = 1
CardStroke.Color = SHADCN.Border
CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
CardStroke.Parent = Card

-- Card Header (Draggable Handle)
local CardHeader = Instance.new("Frame")
CardHeader.Name = "CardHeader"
CardHeader.Size = UDim2.new(1, 0, 0, 44)
CardHeader.BackgroundColor3 = SHADCN.CardHeader
CardHeader.BorderSizePixel = 0
CardHeader.ZIndex = 101
CardHeader.Parent = Card

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 8)
HeaderCorner.Parent = CardHeader

local HeaderTrim = Instance.new("Frame")
HeaderTrim.Size = UDim2.new(1, 0, 0, 8)
HeaderTrim.Position = UDim2.new(0, 0, 1, -8)
HeaderTrim.BackgroundColor3 = SHADCN.CardHeader
HeaderTrim.BorderSizePixel = 0
HeaderTrim.ZIndex = 101
HeaderTrim.Parent = CardHeader

local HeaderDivider = Instance.new("Frame")
HeaderDivider.Size = UDim2.new(1, 0, 0, 1)
HeaderDivider.Position = UDim2.new(0, 0, 1, 0)
HeaderDivider.BackgroundColor3 = SHADCN.Border
HeaderDivider.BorderSizePixel = 0
HeaderDivider.ZIndex = 102
HeaderDivider.Parent = CardHeader

-- Header Left: Lucide Gauge Icon
local TitleIcon = Instance.new("ImageLabel")
TitleIcon.Size = UDim2.new(0, 15, 0, 15)
TitleIcon.Position = UDim2.new(0, 14, 0.5, -7)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Image = ICONS.Gauge
TitleIcon.ImageColor3 = SHADCN.Foreground
TitleIcon.ZIndex = 103
TitleIcon.Parent = CardHeader

-- Header Title
local CardTitle = Instance.new("TextLabel")
CardTitle.Size = UDim2.new(0, 115, 0, 18)
CardTitle.Position = UDim2.new(0, 35, 0.5, -9)
CardTitle.BackgroundTransparency = 1
CardTitle.Font = Enum.Font.GothamBold
CardTitle.TextSize = 13
CardTitle.TextColor3 = SHADCN.Foreground
CardTitle.TextXAlignment = Enum.TextXAlignment.Left
CardTitle.Text = "Walk & Auto Play"
CardTitle.ZIndex = 103
CardTitle.Parent = CardHeader

-- Live Status Badge: [● Active]
local StatusBadge = Instance.new("Frame")
StatusBadge.Name = "StatusBadge"
StatusBadge.Size = UDim2.new(0, 58, 0, 18)
StatusBadge.Position = UDim2.new(0, 155, 0.5, -9)
StatusBadge.BackgroundColor3 = SHADCN.Muted
StatusBadge.BorderSizePixel = 0
StatusBadge.ZIndex = 103
StatusBadge.Parent = CardHeader

local BadgeCorner = Instance.new("UICorner")
BadgeCorner.CornerRadius = UDim.new(0, 4)
BadgeCorner.Parent = StatusBadge

local BadgeStroke = Instance.new("UIStroke")
BadgeStroke.Thickness = 1
BadgeStroke.Color = SHADCN.Border
BadgeStroke.Parent = StatusBadge

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 6, 0, 6)
StatusDot.Position = UDim2.new(0, 7, 0.5, -3)
StatusDot.BackgroundColor3 = SHADCN.SuccessDot
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 104
StatusDot.Parent = StatusBadge

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = StatusDot

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -17, 1, 0)
StatusLabel.Position = UDim2.new(0, 17, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 10
StatusLabel.TextColor3 = SHADCN.Foreground
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Text = "Active"
StatusLabel.ZIndex = 104
StatusLabel.Parent = StatusBadge

-- Ghost Close Button with Lucide Close Icon
local CloseBtn = Instance.new("ImageButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -32, 0.5, -12)
CloseBtn.BackgroundColor3 = SHADCN.CardHeader
CloseBtn.BackgroundTransparency = 1
CloseBtn.Image = ICONS.Close
CloseBtn.ImageColor3 = SHADCN.MutedForeground
CloseBtn.ZIndex = 103
CloseBtn.Parent = CardHeader

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseEnter:Connect(function()
    CloseBtn.BackgroundTransparency = 0
    CloseBtn.BackgroundColor3 = SHADCN.DestructiveHover
    CloseBtn.ImageColor3 = SHADCN.DestructiveText
end)

CloseBtn.MouseLeave:Connect(function()
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.ImageColor3 = SHADCN.MutedForeground
end)

--------------------------------------------------------------------------------
-- SHADCN TABS COMPONENT: [ Speed ] [ Combat ] [ Auto Play ]
--------------------------------------------------------------------------------
local TabsList = Instance.new("Frame")
TabsList.Name = "TabsList"
TabsList.Size = UDim2.new(1, -28, 0, 28)
TabsList.Position = UDim2.new(0, 14, 0, 50)
TabsList.BackgroundColor3 = SHADCN.Muted
TabsList.BorderSizePixel = 0
TabsList.ZIndex = 101
TabsList.Parent = Card

local TabsCorner = Instance.new("UICorner")
TabsCorner.CornerRadius = UDim.new(0, 6)
TabsCorner.Parent = TabsList

local TabsStroke = Instance.new("UIStroke")
TabsStroke.Thickness = 1
TabsStroke.Color = SHADCN.Border
TabsStroke.Parent = TabsList

local MoveTabBtn = Instance.new("TextButton")
MoveTabBtn.Name = "MoveTabBtn"
MoveTabBtn.Size = UDim2.new(0.333, -2, 1, -4)
MoveTabBtn.Position = UDim2.new(0, 2, 0, 2)
MoveTabBtn.BackgroundColor3 = SHADCN.Primary
MoveTabBtn.Font = Enum.Font.GothamBold
MoveTabBtn.TextSize = 10
MoveTabBtn.TextColor3 = SHADCN.PrimaryText
MoveTabBtn.Text = "🏃 Speed"
MoveTabBtn.AutoButtonColor = false
MoveTabBtn.ZIndex = 102
MoveTabBtn.Parent = TabsList

local MoveTabCorner = Instance.new("UICorner")
MoveTabCorner.CornerRadius = UDim.new(0, 4)
MoveTabCorner.Parent = MoveTabBtn

local CombatTabBtn = Instance.new("TextButton")
CombatTabBtn.Name = "CombatTabBtn"
CombatTabBtn.Size = UDim2.new(0.333, -2, 1, -4)
CombatTabBtn.Position = UDim2.new(0.333, 1, 0, 2)
CombatTabBtn.BackgroundTransparency = 1
CombatTabBtn.BackgroundColor3 = SHADCN.Primary
CombatTabBtn.Font = Enum.Font.GothamBold
CombatTabBtn.TextSize = 10
CombatTabBtn.TextColor3 = SHADCN.MutedForeground
CombatTabBtn.Text = "⚔️ Combat"
CombatTabBtn.AutoButtonColor = false
CombatTabBtn.ZIndex = 102
CombatTabBtn.Parent = TabsList

local CombatTabCorner = Instance.new("UICorner")
CombatTabCorner.CornerRadius = UDim.new(0, 4)
CombatTabCorner.Parent = CombatTabBtn

local AutoPlayTabBtn = Instance.new("TextButton")
AutoPlayTabBtn.Name = "AutoPlayTabBtn"
AutoPlayTabBtn.Size = UDim2.new(0.334, -2, 1, -4)
AutoPlayTabBtn.Position = UDim2.new(0.666, 0, 0, 2)
AutoPlayTabBtn.BackgroundTransparency = 1
AutoPlayTabBtn.BackgroundColor3 = SHADCN.Primary
AutoPlayTabBtn.Font = Enum.Font.GothamBold
AutoPlayTabBtn.TextSize = 10
AutoPlayTabBtn.TextColor3 = SHADCN.MutedForeground
AutoPlayTabBtn.Text = "🤖 Auto Play"
AutoPlayTabBtn.AutoButtonColor = false
AutoPlayTabBtn.ZIndex = 102
AutoPlayTabBtn.Parent = TabsList

local AutoPlayTabCorner = Instance.new("UICorner")
AutoPlayTabCorner.CornerRadius = UDim.new(0, 4)
AutoPlayTabCorner.Parent = AutoPlayTabBtn

-- Tab Content Containers
local MoveContent = Instance.new("Frame")
MoveContent.Name = "MoveContent"
MoveContent.Size = UDim2.new(1, -28, 1, -88)
MoveContent.Position = UDim2.new(0, 14, 0, 84)
MoveContent.BackgroundTransparency = 1
MoveContent.Visible = true
MoveContent.ZIndex = 101
MoveContent.Parent = Card

local CombatContent = Instance.new("Frame")
CombatContent.Name = "CombatContent"
CombatContent.Size = UDim2.new(1, -28, 1, -88)
CombatContent.Position = UDim2.new(0, 14, 0, 84)
CombatContent.BackgroundTransparency = 1
CombatContent.Visible = false
CombatContent.ZIndex = 101
CombatContent.Parent = Card

local AutoPlayContent = Instance.new("ScrollingFrame")
AutoPlayContent.Name = "AutoPlayContent"
AutoPlayContent.Size = UDim2.new(1, -28, 1, -88)
AutoPlayContent.Position = UDim2.new(0, 14, 0, 84)
AutoPlayContent.BackgroundTransparency = 1
AutoPlayContent.BorderSizePixel = 0
AutoPlayContent.ScrollBarThickness = 2
AutoPlayContent.ScrollBarImageColor3 = SHADCN.BorderHover
AutoPlayContent.BottomImage = ""
AutoPlayContent.TopImage = ""
AutoPlayContent.ClipsDescendants = true
AutoPlayContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
AutoPlayContent.CanvasSize = UDim2.new(0, 0, 0, 0)
AutoPlayContent.Visible = false
AutoPlayContent.ZIndex = 101
AutoPlayContent.Parent = Card

local AutoPlayLayout = Instance.new("UIListLayout")
AutoPlayLayout.SortOrder = Enum.SortOrder.LayoutOrder
AutoPlayLayout.Padding = UDim.new(0, 5)
AutoPlayLayout.Parent = AutoPlayContent

local AutoPlayPadding = Instance.new("UIPadding")
AutoPlayPadding.PaddingRight = UDim.new(0, 4)
AutoPlayPadding.PaddingBottom = UDim.new(0, 8)
AutoPlayPadding.Parent = AutoPlayContent

local function SwitchTab(tabIndex) -- 1: Move, 2: Combat, 3: AutoPlay
    MoveContent.Visible = (tabIndex == 1)
    CombatContent.Visible = (tabIndex == 2)
    AutoPlayContent.Visible = (tabIndex == 3)

    MoveTabBtn.BackgroundTransparency = (tabIndex == 1) and 0 or 1
    MoveTabBtn.TextColor3 = (tabIndex == 1) and SHADCN.PrimaryText or SHADCN.MutedForeground

    CombatTabBtn.BackgroundTransparency = (tabIndex == 2) and 0 or 1
    CombatTabBtn.TextColor3 = (tabIndex == 2) and SHADCN.PrimaryText or SHADCN.MutedForeground

    AutoPlayTabBtn.BackgroundTransparency = (tabIndex == 3) and 0 or 1
    AutoPlayTabBtn.TextColor3 = (tabIndex == 3) and SHADCN.PrimaryText or SHADCN.MutedForeground
end

MoveTabBtn.MouseButton1Click:Connect(function() SwitchTab(1) end)
CombatTabBtn.MouseButton1Click:Connect(function() SwitchTab(2) end)
AutoPlayTabBtn.MouseButton1Click:Connect(function() SwitchTab(3) end)

--------------------------------------------------------------------------------
-- TAB 1: MOVEMENT CONTENT (WalkSpeed, Steppers, Presets, Reset, AutoExec)
--------------------------------------------------------------------------------

-- Form Row (Labels + Stepper Buttons + Input)
local FormRow = Instance.new("Frame")
FormRow.Name = "FormRow"
FormRow.Size = UDim2.new(1, 0, 0, 26)
FormRow.Position = UDim2.new(0, 0, 0, 0)
FormRow.BackgroundTransparency = 1
FormRow.ZIndex = 102
FormRow.Parent = MoveContent

local LabelsContainer = Instance.new("Frame")
LabelsContainer.Size = UDim2.new(1, -100, 1, 0)
LabelsContainer.BackgroundTransparency = 1
LabelsContainer.ZIndex = 102
LabelsContainer.Parent = FormRow

local MainLabel = Instance.new("TextLabel")
MainLabel.Size = UDim2.new(1, 0, 0, 14)
MainLabel.BackgroundTransparency = 1
MainLabel.Font = Enum.Font.GothamBold
MainLabel.TextSize = 11
MainLabel.TextColor3 = SHADCN.Foreground
MainLabel.TextXAlignment = Enum.TextXAlignment.Left
MainLabel.Text = "WalkSpeed"
MainLabel.ZIndex = 103
MainLabel.Parent = LabelsContainer

local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(1, 0, 0, 12)
SubLabel.Position = UDim2.new(0, 0, 0, 14)
SubLabel.BackgroundTransparency = 1
SubLabel.Font = Enum.Font.GothamMedium
SubLabel.TextSize = 9
SubLabel.TextColor3 = SHADCN.MutedForeground
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.Text = "Range: 0 - 20 studs/s"
SubLabel.ZIndex = 103
SubLabel.Parent = LabelsContainer

-- Stepper Group Container [ - ] [ Value ] [ + ]
local StepperGroup = Instance.new("Frame")
StepperGroup.Name = "StepperGroup"
StepperGroup.Size = UDim2.new(0, 96, 0, 24)
StepperGroup.Position = UDim2.new(1, -96, 0.5, -12)
StepperGroup.BackgroundTransparency = 1
StepperGroup.ZIndex = 102
StepperGroup.Parent = FormRow

local MinusBtn = Instance.new("ImageButton")
MinusBtn.Name = "MinusBtn"
MinusBtn.Size = UDim2.new(0, 24, 0, 24)
MinusBtn.Position = UDim2.new(0, 0, 0, 0)
MinusBtn.BackgroundColor3 = SHADCN.Muted
MinusBtn.Image = ICONS.Minus
MinusBtn.ImageColor3 = SHADCN.MutedForeground
MinusBtn.ZIndex = 103
MinusBtn.Parent = StepperGroup

local MinusCorner = Instance.new("UICorner")
MinusCorner.CornerRadius = UDim.new(0, 4)
MinusCorner.Parent = MinusBtn

local MinusStroke = Instance.new("UIStroke")
MinusStroke.Thickness = 1
MinusStroke.Color = SHADCN.Border
MinusStroke.Parent = MinusBtn

local ValueInput = Instance.new("TextBox")
ValueInput.Name = "ValueInput"
ValueInput.Size = UDim2.new(0, 40, 0, 24)
ValueInput.Position = UDim2.new(0, 28, 0, 0)
ValueInput.BackgroundColor3 = SHADCN.Muted
ValueInput.Font = Enum.Font.GothamBold
ValueInput.TextSize = 11
ValueInput.TextColor3 = SHADCN.Foreground
ValueInput.Text = tostring(currentSpeed)
ValueInput.ClearTextOnFocus = false
ValueInput.ZIndex = 103
ValueInput.Parent = StepperGroup

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 4)
InputCorner.Parent = ValueInput

local InputStroke = Instance.new("UIStroke")
InputStroke.Thickness = 1
InputStroke.Color = SHADCN.Border
InputStroke.Parent = ValueInput

ValueInput.Focused:Connect(function()
    TweenService:Create(InputStroke, TweenInfo.new(0.12), { Color = SHADCN.RingFocus }):Play()
end)

ValueInput.FocusLost:Connect(function()
    TweenService:Create(InputStroke, TweenInfo.new(0.12), { Color = SHADCN.Border }):Play()
end)

local PlusBtn = Instance.new("ImageButton")
PlusBtn.Name = "PlusBtn"
PlusBtn.Size = UDim2.new(0, 24, 0, 24)
PlusBtn.Position = UDim2.new(0, 72, 0, 0)
PlusBtn.BackgroundColor3 = SHADCN.Muted
PlusBtn.Image = ICONS.Plus
PlusBtn.ImageColor3 = SHADCN.MutedForeground
PlusBtn.ZIndex = 103
PlusBtn.Parent = StepperGroup

local PlusCorner = Instance.new("UICorner")
PlusCorner.CornerRadius = UDim.new(0, 4)
PlusCorner.Parent = PlusBtn

local PlusStroke = Instance.new("UIStroke")
PlusStroke.Thickness = 1
PlusStroke.Color = SHADCN.Border
PlusStroke.Parent = PlusBtn

local function AddButtonHover(btn)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = SHADCN.MutedHover }):Play()
        btn.ImageColor3 = SHADCN.Foreground
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = SHADCN.Muted }):Play()
        btn.ImageColor3 = SHADCN.MutedForeground
    end)
end
AddButtonHover(MinusBtn)
AddButtonHover(PlusBtn)

-- Slider Track & Fill
local SliderSection = Instance.new("Frame")
SliderSection.Name = "SliderSection"
SliderSection.Size = UDim2.new(1, 0, 0, 36)
SliderSection.Position = UDim2.new(0, 0, 0, 34)
SliderSection.BackgroundTransparency = 1
SliderSection.ZIndex = 102
SliderSection.Parent = MoveContent

local SliderTrack = Instance.new("Frame")
SliderTrack.Name = "SliderTrack"
SliderTrack.Size = UDim2.new(1, 0, 0, 6)
SliderTrack.Position = UDim2.new(0, 0, 0, 10)
SliderTrack.BackgroundColor3 = SHADCN.Track
SliderTrack.BorderSizePixel = 0
SliderTrack.ZIndex = 103
SliderTrack.Parent = SliderSection

local TrackCorner = Instance.new("UICorner")
TrackCorner.CornerRadius = UDim.new(1, 0)
TrackCorner.Parent = SliderTrack

local initialPct = (currentSpeed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)

local SliderRange = Instance.new("Frame")
SliderRange.Name = "SliderRange"
SliderRange.Size = UDim2.new(initialPct, 0, 1, 0)
SliderRange.BackgroundColor3 = SHADCN.Primary
SliderRange.BorderSizePixel = 0
SliderRange.ZIndex = 104
SliderRange.Parent = SliderTrack

local RangeCorner = Instance.new("UICorner")
RangeCorner.CornerRadius = UDim.new(1, 0)
RangeCorner.Parent = SliderRange

local SliderThumb = Instance.new("Frame")
SliderThumb.Name = "SliderThumb"
SliderThumb.Size = UDim2.new(0, 16, 0, 16)
SliderThumb.Position = UDim2.new(initialPct, -8, 0.5, -8)
SliderThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderThumb.BorderSizePixel = 0
SliderThumb.ZIndex = 105
SliderThumb.Parent = SliderTrack

local ThumbCorner = Instance.new("UICorner")
ThumbCorner.CornerRadius = UDim.new(1, 0)
ThumbCorner.Parent = SliderThumb

local ThumbStroke = Instance.new("UIStroke")
ThumbStroke.Thickness = 1.5
ThumbStroke.Color = SHADCN.Border
ThumbStroke.Parent = SliderThumb

local TickRow = Instance.new("Frame")
TickRow.Size = UDim2.new(1, 0, 0, 12)
TickRow.Position = UDim2.new(0, 0, 0, 22)
TickRow.BackgroundTransparency = 1
TickRow.ZIndex = 103
TickRow.Parent = SliderSection

local TickMin = Instance.new("TextLabel")
TickMin.Size = UDim2.new(0, 20, 1, 0)
TickMin.BackgroundTransparency = 1
TickMin.Font = Enum.Font.GothamMedium
TickMin.TextSize = 9
TickMin.TextColor3 = SHADCN.MutedForeground
TickMin.TextXAlignment = Enum.TextXAlignment.Left
TickMin.Text = "0"
TickMin.ZIndex = 104
TickMin.Parent = TickRow

local TickMid = Instance.new("TextLabel")
TickMid.Size = UDim2.new(0, 40, 1, 0)
TickMid.Position = UDim2.new(0.5, -20, 0, 0)
TickMid.BackgroundTransparency = 1
TickMid.Font = Enum.Font.GothamMedium
TickMid.TextSize = 9
TickMid.TextColor3 = SHADCN.MutedForeground
TickMid.Text = "10"
TickMid.ZIndex = 104
TickMid.Parent = TickRow

local TickMax = Instance.new("TextLabel")
TickMax.Size = UDim2.new(0, 50, 1, 0)
TickMax.Position = UDim2.new(1, -50, 0, 0)
TickMax.BackgroundTransparency = 1
TickMax.Font = Enum.Font.GothamBold
TickMax.TextSize = 9
TickMax.TextColor3 = SHADCN.MutedForeground
TickMax.TextXAlignment = Enum.TextXAlignment.Right
TickMax.Text = "20 (Def)"
TickMax.ZIndex = 104
TickMax.Parent = TickRow

-- Preset Chips [ 0 ] [ 8 ] [ 12 ] [ 16 ] [ 20 ]
local PresetContainer = Instance.new("Frame")
PresetContainer.Name = "PresetContainer"
PresetContainer.Size = UDim2.new(1, 0, 0, 26)
PresetContainer.Position = UDim2.new(0, 0, 0, 76)
PresetContainer.BackgroundColor3 = SHADCN.Muted
PresetContainer.BorderSizePixel = 0
PresetContainer.ZIndex = 102
PresetContainer.Parent = MoveContent

local PresetCorner = Instance.new("UICorner")
PresetCorner.CornerRadius = UDim.new(0, 6)
PresetCorner.Parent = PresetContainer

local PresetStroke = Instance.new("UIStroke")
PresetStroke.Thickness = 1
PresetStroke.Color = SHADCN.Border
PresetStroke.Parent = PresetContainer

local PresetLayout = Instance.new("UIListLayout")
PresetLayout.FillDirection = Enum.FillDirection.Horizontal
PresetLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
PresetLayout.VerticalAlignment = Enum.VerticalAlignment.Center
PresetLayout.Padding = UDim.new(0, 4)
PresetLayout.Parent = PresetContainer

local PRESETS = { 0, 8, 12, 16, 20 }
local presetButtons = {}

-- Reset Button
local ResetButton = Instance.new("TextButton")
ResetButton.Name = "ResetButton"
ResetButton.Size = UDim2.new(1, 0, 0, 26)
ResetButton.Position = UDim2.new(0, 0, 0, 110)
ResetButton.BackgroundColor3 = SHADCN.Muted
ResetButton.BorderSizePixel = 0
ResetButton.Font = Enum.Font.GothamMedium
ResetButton.TextSize = 10
ResetButton.TextColor3 = SHADCN.Foreground
ResetButton.Text = "        Reset to Default (20)"
ResetButton.TextXAlignment = Enum.TextXAlignment.Center
ResetButton.AutoButtonColor = false
ResetButton.ZIndex = 102
ResetButton.Parent = MoveContent

local ResetCorner = Instance.new("UICorner")
ResetCorner.CornerRadius = UDim.new(0, 6)
ResetCorner.Parent = ResetButton

local ResetStroke = Instance.new("UIStroke")
ResetStroke.Thickness = 1
ResetStroke.Color = SHADCN.Border
ResetStroke.Parent = ResetButton

local ResetIcon = Instance.new("ImageLabel")
ResetIcon.Size = UDim2.new(0, 11, 0, 11)
ResetIcon.Position = UDim2.new(0, 36, 0.5, -5)
ResetIcon.BackgroundTransparency = 1
ResetIcon.Image = ICONS.RotateCcw
ResetIcon.ImageColor3 = SHADCN.MutedForeground
ResetIcon.ZIndex = 103
ResetIcon.Parent = ResetButton

ResetButton.MouseEnter:Connect(function()
    TweenService:Create(ResetButton, TweenInfo.new(0.12), { BackgroundColor3 = SHADCN.MutedHover }):Play()
    TweenService:Create(ResetStroke, TweenInfo.new(0.12), { Color = SHADCN.BorderHover }):Play()
    ResetIcon.ImageColor3 = SHADCN.Foreground
end)

ResetButton.MouseLeave:Connect(function()
    TweenService:Create(ResetButton, TweenInfo.new(0.12), { BackgroundColor3 = SHADCN.Muted }):Play()
    TweenService:Create(ResetStroke, TweenInfo.new(0.12), { Color = SHADCN.Border }):Play()
    ResetIcon.ImageColor3 = SHADCN.MutedForeground
end)

-- Auto-Execute Toggle Row
local AutoExecRow = Instance.new("Frame")
AutoExecRow.Name = "AutoExecRow"
AutoExecRow.Size = UDim2.new(1, 0, 0, 26)
AutoExecRow.Position = UDim2.new(0, 0, 0, 144)
AutoExecRow.BackgroundColor3 = SHADCN.Muted
AutoExecRow.BorderSizePixel = 0
AutoExecRow.ZIndex = 102
AutoExecRow.Parent = MoveContent

local AutoExecCorner = Instance.new("UICorner")
AutoExecCorner.CornerRadius = UDim.new(0, 6)
AutoExecCorner.Parent = AutoExecRow

local AutoExecStroke = Instance.new("UIStroke")
AutoExecStroke.Thickness = 1
AutoExecStroke.Color = SHADCN.Border
AutoExecStroke.Parent = AutoExecRow

local AutoExecIcon = Instance.new("ImageLabel")
AutoExecIcon.Size = UDim2.new(0, 11, 0, 11)
AutoExecIcon.Position = UDim2.new(0, 10, 0.5, -5)
AutoExecIcon.BackgroundTransparency = 1
AutoExecIcon.Image = ICONS.Repeat
AutoExecIcon.ImageColor3 = SHADCN.Foreground
AutoExecIcon.ZIndex = 103
AutoExecIcon.Parent = AutoExecRow

local AutoExecLabel = Instance.new("TextLabel")
AutoExecLabel.Size = UDim2.new(1, -95, 1, 0)
AutoExecLabel.Position = UDim2.new(0, 26, 0, 0)
AutoExecLabel.BackgroundTransparency = 1
AutoExecLabel.Font = Enum.Font.GothamMedium
AutoExecLabel.TextSize = 10
AutoExecLabel.TextColor3 = SHADCN.Foreground
AutoExecLabel.TextXAlignment = Enum.TextXAlignment.Left
AutoExecLabel.Text = "Auto Execute"
AutoExecLabel.ZIndex = 103
AutoExecLabel.Parent = AutoExecRow

local AutoExecBadge = Instance.new("TextButton")
AutoExecBadge.Name = "AutoExecBadge"
AutoExecBadge.Size = UDim2.new(0, 58, 0, 18)
AutoExecBadge.Position = UDim2.new(1, -64, 0.5, -9)
AutoExecBadge.BackgroundColor3 = SHADCN.Card
AutoExecBadge.Font = Enum.Font.GothamBold
AutoExecBadge.TextSize = 9
AutoExecBadge.TextColor3 = SHADCN.SuccessDot
AutoExecBadge.Text = "● Active"
AutoExecBadge.AutoButtonColor = false
AutoExecBadge.ZIndex = 103
AutoExecBadge.Parent = AutoExecRow

local AutoExecBadgeCorner = Instance.new("UICorner")
AutoExecBadgeCorner.CornerRadius = UDim.new(0, 4)
AutoExecBadgeCorner.Parent = AutoExecBadge

local AutoExecBadgeStroke = Instance.new("UIStroke")
AutoExecBadgeStroke.Thickness = 1
AutoExecBadgeStroke.Color = SHADCN.Border
AutoExecBadgeStroke.Parent = AutoExecBadge

local function UpdateAutoExecVisuals()
    if autoExecuteEnabled then
        AutoExecBadge.TextColor3 = SHADCN.SuccessDot
        AutoExecBadge.Text = "● Active"
        AutoExecIcon.ImageColor3 = SHADCN.Foreground
    else
        AutoExecBadge.TextColor3 = SHADCN.MutedForeground
        AutoExecBadge.Text = "○ Disabled"
        AutoExecIcon.ImageColor3 = SHADCN.MutedForeground
    end
end

AutoExecBadge.MouseButton1Click:Connect(function()
    autoExecuteEnabled = not autoExecuteEnabled
    UpdateAutoExecVisuals()
    if autoExecuteEnabled then
        SetupAutoExecute()
    end
end)

--------------------------------------------------------------------------------
-- TAB 2: COMBAT CONTENT (Auto Swing, Kill Aura, Auto Spells, Aura Range)
--------------------------------------------------------------------------------
local function CreateCombatToggleRow(parent, yPos, iconAsset, titleText, descText, defaultState, callback, layoutOrder)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.Position = UDim2.new(0, 0, 0, yPos or 0)
    row.LayoutOrder = layoutOrder or 0
    row.BackgroundColor3 = SHADCN.Muted
    row.BorderSizePixel = 0
    row.ZIndex = 102
    row.Parent = parent

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 6)
    rCorner.Parent = row

    local rStroke = Instance.new("UIStroke")
    rStroke.Thickness = 1
    rStroke.Color = defaultState and SHADCN.BorderHover or SHADCN.Border
    rStroke.Parent = row

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 14, 0, 14)
    icon.Position = UDim2.new(0, 10, 0.5, -7)
    icon.BackgroundTransparency = 1
    icon.Image = iconAsset
    icon.ImageColor3 = defaultState and SHADCN.Foreground or SHADCN.MutedForeground
    icon.ZIndex = 103
    icon.Parent = row

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -95, 0, 14)
    titleLbl.Position = UDim2.new(0, 30, 0, 5)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 10
    titleLbl.TextColor3 = SHADCN.Foreground
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = titleText
    titleLbl.ZIndex = 103
    titleLbl.Parent = row

    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1, -95, 0, 12)
    descLbl.Position = UDim2.new(0, 30, 0, 18)
    descLbl.BackgroundTransparency = 1
    descLbl.Font = Enum.Font.GothamMedium
    descLbl.TextSize = 8
    descLbl.TextColor3 = SHADCN.MutedForeground
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.Text = descText
    descLbl.ZIndex = 103
    descLbl.Parent = row

    local badgeBtn = Instance.new("TextButton")
    badgeBtn.Size = UDim2.new(0, 56, 0, 20)
    badgeBtn.Position = UDim2.new(1, -64, 0.5, -10)
    badgeBtn.BackgroundColor3 = SHADCN.Card
    badgeBtn.Font = Enum.Font.GothamBold
    badgeBtn.TextSize = 9
    badgeBtn.TextColor3 = defaultState and SHADCN.SuccessDot or SHADCN.MutedForeground
    badgeBtn.Text = defaultState and "● ON" or "○ OFF"
    badgeBtn.AutoButtonColor = false
    badgeBtn.ZIndex = 103
    badgeBtn.Parent = row

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 4)
    bCorner.Parent = badgeBtn

    local bStroke = Instance.new("UIStroke")
    bStroke.Thickness = 1
    bStroke.Color = SHADCN.Border
    bStroke.Parent = badgeBtn

    local isEnabled = defaultState

    local function UpdateVisuals()
        badgeBtn.TextColor3 = isEnabled and SHADCN.SuccessDot or SHADCN.MutedForeground
        badgeBtn.Text = isEnabled and "● ON" or "○ OFF"
        icon.ImageColor3 = isEnabled and SHADCN.Foreground or SHADCN.MutedForeground
        TweenService:Create(rStroke, TweenInfo.new(0.12), { Color = isEnabled and SHADCN.BorderHover or SHADCN.Border }):Play()
    end

    local function ToggleState()
        isEnabled = not isEnabled
        UpdateVisuals()
        pcall(function()
            callback(isEnabled)
        end)
    end

    local rowBtn = Instance.new("TextButton")
    rowBtn.Name = "RowBtn"
    rowBtn.Size = UDim2.new(1, 0, 1, 0)
    rowBtn.BackgroundTransparency = 1
    rowBtn.Text = ""
    rowBtn.ZIndex = 108
    rowBtn.Parent = row

    rowBtn.MouseButton1Click:Connect(ToggleState)
    badgeBtn.MouseButton1Click:Connect(ToggleState)

    return {
        Set = function(val)
            isEnabled = val
            UpdateVisuals()
        end
    }
end

-- 1. Auto Swing Toggle
CreateCombatToggleRow(
    CombatContent,
    0,
    ICONS.Swords,
    "Auto Swing",
    "Continuous weapon & remote spam",
    CombatState.AutoSwing,
    function(val)
        CombatState.AutoSwing = val
    end
)

-- 2. Kill Aura Toggle
CreateCombatToggleRow(
    CombatContent,
    42,
    ICONS.Target,
    "Kill Aura",
    "Strikes all nearby mobs in reach",
    CombatState.KillAura,
    function(val)
        CombatState.KillAura = val
    end
)

-- 3. Auto Abilities (Q & E) Toggle
CreateCombatToggleRow(
    CombatContent,
    84,
    ICONS.Flame,
    "Auto Abilities (Q & E)",
    "Auto-casts spells when off cooldown",
    CombatState.AutoAbilities,
    function(val)
        CombatState.AutoAbilities = val
    end
)

-- 4. Kill Aura Radius Setting Row
local RangeRow = Instance.new("Frame")
RangeRow.Name = "RangeRow"
RangeRow.Size = UDim2.new(1, 0, 0, 40)
RangeRow.Position = UDim2.new(0, 0, 0, 126)
RangeRow.BackgroundColor3 = SHADCN.Muted
RangeRow.BorderSizePixel = 0
RangeRow.ZIndex = 102
RangeRow.Parent = CombatContent

local RangeCorner = Instance.new("UICorner")
RangeCorner.CornerRadius = UDim.new(0, 6)
RangeCorner.Parent = RangeRow

local RangeStroke = Instance.new("UIStroke")
RangeStroke.Thickness = 1
RangeStroke.Color = SHADCN.Border
RangeStroke.Parent = RangeRow

local RangeTitle = Instance.new("TextLabel")
RangeTitle.Size = UDim2.new(0, 120, 0, 14)
RangeTitle.Position = UDim2.new(0, 10, 0, 6)
RangeTitle.BackgroundTransparency = 1
RangeTitle.Font = Enum.Font.GothamBold
RangeTitle.TextSize = 10
RangeTitle.TextColor3 = SHADCN.Foreground
RangeTitle.TextXAlignment = Enum.TextXAlignment.Left
RangeTitle.Text = "Aura Reach"
RangeTitle.ZIndex = 103
RangeTitle.Parent = RangeRow

local RangeVal = Instance.new("TextLabel")
RangeVal.Size = UDim2.new(0, 60, 0, 14)
RangeVal.Position = UDim2.new(1, -70, 0, 6)
RangeVal.BackgroundTransparency = 1
RangeVal.Font = Enum.Font.GothamBold
RangeVal.TextSize = 10
RangeVal.TextColor3 = SHADCN.Foreground
RangeVal.TextXAlignment = Enum.TextXAlignment.Right
RangeVal.Text = CombatState.AuraRange .. " studs"
RangeVal.ZIndex = 103
RangeVal.Parent = RangeRow

local RangeTrack = Instance.new("Frame")
RangeTrack.Size = UDim2.new(1, -20, 0, 5)
RangeTrack.Position = UDim2.new(0, 10, 0, 24)
RangeTrack.BackgroundColor3 = SHADCN.Track
RangeTrack.BorderSizePixel = 0
RangeTrack.ZIndex = 103
RangeTrack.Parent = RangeRow

local RTrackCorner = Instance.new("UICorner")
RTrackCorner.CornerRadius = UDim.new(1, 0)
RTrackCorner.Parent = RangeTrack

local rangePct = (CombatState.AuraRange - 15) / (60 - 15)

local RangeFill = Instance.new("Frame")
RangeFill.Size = UDim2.new(rangePct, 0, 1, 0)
RangeFill.BackgroundColor3 = SHADCN.Primary
RangeFill.BorderSizePixel = 0
RangeFill.ZIndex = 104
RangeFill.Parent = RangeTrack

local RFillCorner = Instance.new("UICorner")
RFillCorner.CornerRadius = UDim.new(1, 0)
RFillCorner.Parent = RangeFill

local RangeThumb = Instance.new("Frame")
RangeThumb.Size = UDim2.new(0, 12, 0, 12)
RangeThumb.Position = UDim2.new(rangePct, -6, 0.5, -6)
RangeThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RangeThumb.BorderSizePixel = 0
RangeThumb.ZIndex = 105
RangeThumb.Parent = RangeTrack

local RThumbCorner = Instance.new("UICorner")
RThumbCorner.CornerRadius = UDim.new(1, 0)
RThumbCorner.Parent = RangeThumb

local isDraggingRange = false
local function UpdateRangeFromInput(input)
    local barX = RangeTrack.AbsolutePosition.X
    local barWidth = RangeTrack.AbsoluteSize.X
    if barWidth <= 0 then return end
    local pct = math.clamp((input.Position.X - barX) / barWidth, 0, 1)
    local calc = math.round(15 + (60 - 15) * pct)
    CombatState.AuraRange = calc
    RangeVal.Text = calc .. " studs"
    RangeFill.Size = UDim2.new(pct, 0, 1, 0)
    RangeThumb.Position = UDim2.new(pct, -6, 0.5, -6)
end

RangeTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingRange = true
        UpdateRangeFromInput(input)
    end
end)

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if isDraggingRange and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateRangeFromInput(input)
    end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingRange = false
    end
end))

--------------------------------------------------------------------------------
-- TAB 3: AUTO PLAY CONTENT (Auto Rejoin, Dungeon Create, Intro, Auto Farm)
--------------------------------------------------------------------------------
-- 1. Auto Rejoin on Kick / Disconnect
CreateCombatToggleRow(
    AutoPlayContent,
    0,
    ICONS.RotateCcw,
    "Auto Rejoin (Kick)",
    "Auto reconnect if kicked or disconnected",
    AutoPlayState.AutoRejoin,
    function(val)
        AutoPlayState.AutoRejoin = val
    end,
    1
)

-- 2. Auto Create Dungeon (Desert Temple - Nightmare Hardcore)
CreateCombatToggleRow(
    AutoPlayContent,
    0,
    ICONS.Flame,
    "Auto Create Dungeon",
    "Desert Temple (Nightmare, Hardcore)",
    AutoPlayState.AutoCreateDungeon,
    function(val)
        AutoPlayState.AutoCreateDungeon = val
        if val then
            AutoPlayState.LastLobbyActionTick = 0
        end
    end,
    2
)

-- 3. Force Create & Start Button Row
local ForceCreateBtn = Instance.new("TextButton")
ForceCreateBtn.Name = "ForceCreateBtn"
ForceCreateBtn.Size = UDim2.new(1, 0, 0, 30)
ForceCreateBtn.Position = UDim2.new(0, 0, 0, 0)
ForceCreateBtn.LayoutOrder = 3
ForceCreateBtn.BackgroundColor3 = SHADCN.Muted
ForceCreateBtn.BorderSizePixel = 0
ForceCreateBtn.Font = Enum.Font.GothamBold
ForceCreateBtn.TextSize = 10
ForceCreateBtn.TextColor3 = SHADCN.Foreground
ForceCreateBtn.Text = "⚡ Create & Start Lobby Now"
ForceCreateBtn.AutoButtonColor = false
ForceCreateBtn.ZIndex = 102
ForceCreateBtn.Parent = AutoPlayContent

local ForceCreateCorner = Instance.new("UICorner")
ForceCreateCorner.CornerRadius = UDim.new(0, 6)
ForceCreateCorner.Parent = ForceCreateBtn

local ForceCreateStroke = Instance.new("UIStroke")
ForceCreateStroke.Thickness = 1
ForceCreateStroke.Color = SHADCN.Border
ForceCreateStroke.Parent = ForceCreateBtn

ForceCreateBtn.MouseEnter:Connect(function()
    TweenService:Create(ForceCreateBtn, TweenInfo.new(0.12), { BackgroundColor3 = SHADCN.MutedHover }):Play()
    TweenService:Create(ForceCreateStroke, TweenInfo.new(0.12), { Color = SHADCN.BorderHover }):Play()
end)

ForceCreateBtn.MouseLeave:Connect(function()
    TweenService:Create(ForceCreateBtn, TweenInfo.new(0.12), { BackgroundColor3 = SHADCN.Muted }):Play()
    TweenService:Create(ForceCreateStroke, TweenInfo.new(0.12), { Color = SHADCN.Border }):Play()
end)

ForceCreateBtn.MouseButton1Click:Connect(function()
    TweenService:Create(ForceCreateBtn, TweenInfo.new(0.08), { BackgroundColor3 = Color3.fromRGB(45, 45, 52) }):Play()
    task.delay(0.1, function()
        TweenService:Create(ForceCreateBtn, TweenInfo.new(0.12), { BackgroundColor3 = SHADCN.Muted }):Play()
    end)
    pcall(CreateAndLaunchDungeon)
end)

-- 4. Auto Skip Intro Screen
CreateCombatToggleRow(
    AutoPlayContent,
    0,
    ICONS.Play,
    "Auto Skip Intro",
    "Click play intro & spawn character",
    AutoPlayState.AutoSkipIntro,
    function(val)
        AutoPlayState.AutoSkipIntro = val
        if val then
            pcall(HandleIntroScreen)
        end
    end,
    4
)

-- 5. Auto Play Master Toggle
CreateCombatToggleRow(
    AutoPlayContent,
    0,
    ICONS.Bot,
    "Auto Play (Walk)",
    "Walk directly on enemies at speed 20",
    AutoPlayState.Enabled,
    function(val)
        AutoPlayState.Enabled = val
        if not val then
            AutoPlayState.CurrentTarget = nil
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                hum:MoveTo(hrp.Position)
            end
        end
    end,
    5
)

-- 6. Auto Start Barrier Toggle
CreateCombatToggleRow(
    AutoPlayContent,
    0,
    ICONS.Play,
    "Auto Start Barrier",
    "Open start barrier automatically",
    AutoPlayState.AutoStart,
    function(val)
        AutoPlayState.AutoStart = val
    end,
    6
)

-- 7. Auto Replay Toggle
CreateCombatToggleRow(
    AutoPlayContent,
    0,
    ICONS.Repeat,
    "Auto Replay Dungeon",
    "Replay upon dungeon victory",
    AutoPlayState.AutoReplay,
    function(val)
        AutoPlayState.AutoReplay = val
    end,
    7
)

-- 8. Clear Nearest First Toggle
CreateCombatToggleRow(
    AutoPlayContent,
    0,
    ICONS.Target,
    "Clear Nearest First",
    "Target & defeat closest mob first",
    AutoPlayState.ClearNearestFirst,
    function(val)
        AutoPlayState.ClearNearestFirst = val
        AutoPlayState.CurrentTarget = nil
    end,
    8
)

-- 9. Walk Distance Slider Row (0 to 6 studs, default 1.5 studs)
local DistRow = Instance.new("Frame")
DistRow.Name = "DistRow"
DistRow.Size = UDim2.new(1, 0, 0, 40)
DistRow.Position = UDim2.new(0, 0, 0, 0)
DistRow.LayoutOrder = 9
DistRow.BackgroundColor3 = SHADCN.Muted
DistRow.BorderSizePixel = 0
DistRow.ZIndex = 102
DistRow.Parent = AutoPlayContent

local DistCorner = Instance.new("UICorner")
DistCorner.CornerRadius = UDim.new(0, 6)
DistCorner.Parent = DistRow

local DistStroke = Instance.new("UIStroke")
DistStroke.Thickness = 1
DistStroke.Color = SHADCN.Border
DistStroke.Parent = DistRow

local DistTitle = Instance.new("TextLabel")
DistTitle.Size = UDim2.new(0, 120, 0, 14)
DistTitle.Position = UDim2.new(0, 10, 0, 6)
DistTitle.BackgroundTransparency = 1
DistTitle.Font = Enum.Font.GothamBold
DistTitle.TextSize = 10
DistTitle.TextColor3 = SHADCN.Foreground
DistTitle.TextXAlignment = Enum.TextXAlignment.Left
DistTitle.Text = "Walk Distance"
DistTitle.ZIndex = 103
DistTitle.Parent = DistRow

local DistVal = Instance.new("TextLabel")
DistVal.Size = UDim2.new(0, 60, 0, 14)
DistVal.Position = UDim2.new(1, -70, 0, 6)
DistVal.BackgroundTransparency = 1
DistVal.Font = Enum.Font.GothamBold
DistVal.TextSize = 10
DistVal.TextColor3 = SHADCN.Foreground
DistVal.TextXAlignment = Enum.TextXAlignment.Right
DistVal.Text = string.format("%.1f studs", AutoPlayState.ApproachDistance)
DistVal.ZIndex = 103
DistVal.Parent = DistRow

local DistTrack = Instance.new("Frame")
DistTrack.Size = UDim2.new(1, -20, 0, 5)
DistTrack.Position = UDim2.new(0, 10, 0, 24)
DistTrack.BackgroundColor3 = SHADCN.Track
DistTrack.BorderSizePixel = 0
DistTrack.ZIndex = 103
DistTrack.Parent = DistRow

local DTrackCorner = Instance.new("UICorner")
DTrackCorner.CornerRadius = UDim.new(1, 0)
DTrackCorner.Parent = DistTrack

local distPct = (AutoPlayState.ApproachDistance - 0) / (6 - 0)

local DistFill = Instance.new("Frame")
DistFill.Size = UDim2.new(distPct, 0, 1, 0)
DistFill.BackgroundColor3 = SHADCN.Primary
DistFill.BorderSizePixel = 0
DistFill.ZIndex = 104
DistFill.Parent = DistTrack

local DFillCorner = Instance.new("UICorner")
DFillCorner.CornerRadius = UDim.new(1, 0)
DFillCorner.Parent = DistFill

local DistThumb = Instance.new("Frame")
DistThumb.Size = UDim2.new(0, 12, 0, 12)
DistThumb.Position = UDim2.new(distPct, -6, 0.5, -6)
DistThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DistThumb.BorderSizePixel = 0
DistThumb.ZIndex = 105
DistThumb.Parent = DistTrack

local DThumbCorner = Instance.new("UICorner")
DThumbCorner.CornerRadius = UDim.new(1, 0)
DThumbCorner.Parent = DistThumb

local isDraggingDist = false
local function UpdateDistFromInput(input)
    local barX = DistTrack.AbsolutePosition.X
    local barWidth = DistTrack.AbsoluteSize.X
    if barWidth <= 0 then return end
    local pct = math.clamp((input.Position.X - barX) / barWidth, 0, 1)
    local calc = math.round((0 + (6 - 0) * pct) * 10) / 10
    AutoPlayState.ApproachDistance = calc
    DistVal.Text = string.format("%.1f studs", calc)
    DistFill.Size = UDim2.new(pct, 0, 1, 0)
    DistThumb.Position = UDim2.new(pct, -6, 0.5, -6)
end

DistTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingDist = true
        UpdateDistFromInput(input)
    end
end)

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if isDraggingDist and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateDistFromInput(input)
    end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingDist = false
    end
end))

--------------------------------------------------------------------------------
-- REACTIVE STATE & SLIDER LOGIC
--------------------------------------------------------------------------------
local function UpdatePresetVisuals()
    for val, btn in pairs(presetButtons) do
        local isActive = (val == currentSpeed)
        local targetBg = isActive and SHADCN.Primary or Color3.fromRGB(0, 0, 0)
        local targetText = isActive and SHADCN.PrimaryText or SHADCN.MutedForeground
        local targetTransparency = isActive and 0 or 1

        btn.BackgroundTransparency = targetTransparency
        btn.BackgroundColor3 = targetBg
        btn.TextColor3 = targetText
    end
end

local function SetSpeed(val)
    val = math.clamp(math.round(val), MIN_SPEED, MAX_SPEED)
    currentSpeed = val
    ValueInput.Text = tostring(currentSpeed)

    local pct = (currentSpeed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
    SliderRange.Size = UDim2.new(pct, 0, 1, 0)
    SliderThumb.Position = UDim2.new(pct, -8, 0.5, -8)

    UpdatePresetVisuals()
    ApplySpeed()
end

-- Create Preset Chip Buttons
for _, pVal in ipairs(PRESETS) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 44, 0, 20)
    btn.BackgroundTransparency = 1
    btn.BackgroundColor3 = SHADCN.Primary
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = SHADCN.MutedForeground
    btn.Text = tostring(pVal)
    btn.ZIndex = 103
    btn.Parent = PresetContainer

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 4)
    bCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        SetSpeed(pVal)
    end)

    presetButtons[pVal] = btn
end
UpdatePresetVisuals()

-- Micro-Stepper Action handlers
MinusBtn.MouseButton1Click:Connect(function()
    SetSpeed(currentSpeed - 1)
end)

PlusBtn.MouseButton1Click:Connect(function()
    SetSpeed(currentSpeed + 1)
end)

-- Slider Drag Interaction (Mouse + Touch)
local isDraggingSlider = false

local function UpdateFromInput(input)
    local barX = SliderTrack.AbsolutePosition.X
    local barWidth = SliderTrack.AbsoluteSize.X
    if barWidth <= 0 then return end
    local pct = math.clamp((input.Position.X - barX) / barWidth, 0, 1)
    local calculated = MIN_SPEED + ((MAX_SPEED - MIN_SPEED) * pct)
    SetSpeed(calculated)
end

SliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSlider = true
        TweenService:Create(ThumbStroke, TweenInfo.new(0.1), { Color = SHADCN.RingFocus, Thickness = 2 }):Play()
        UpdateFromInput(input)
    end
end)

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateFromInput(input)
    end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingSlider = false
        TweenService:Create(ThumbStroke, TweenInfo.new(0.1), { Color = SHADCN.Border, Thickness = 1.5 }):Play()
    end
end))

-- Direct TextBox Input
ValueInput.FocusLost:Connect(function()
    local num = tonumber(ValueInput.Text)
    if num then
        SetSpeed(num)
    else
        ValueInput.Text = tostring(currentSpeed)
    end
end)

ResetButton.MouseButton1Click:Connect(function()
    SetSpeed(DEFAULT_SPEED)
end)

--------------------------------------------------------------------------------
-- DRAGGABLE WINDOW LOGIC (Mouse & Touch)
--------------------------------------------------------------------------------
local isDraggingFrame = false
local dragStart = nil
local startPos = nil
local dragInput = nil

CardHeader.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingFrame = true
        dragStart = input.Position
        startPos = Card.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDraggingFrame = false
            end
        end)
    end
end)

CardHeader.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and isDraggingFrame then
        local delta = input.Position - dragStart
        Card.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end))

--------------------------------------------------------------------------------
-- CLEAN CLOSE & UNLOAD
--------------------------------------------------------------------------------
local Hub = {}
GlobalEnv.ShadcnWalkSpeed = Hub

function Hub.Destroy()
    isRunning = false
    CombatState.AutoSwing = false
    CombatState.KillAura = false
    AutoPlayState.Enabled = false
    AutoPlayState.AutoCreateDungeon = false
    AutoPlayState.AutoRejoin = false
    AutoPlayState.AutoSkipIntro = false

    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(connections)

    local hum = GetHumanoid()
    if hum then
        pcall(function()
            hum.WalkSpeed = DEFAULT_SPEED
        end)
    end

    pcall(function()
        ScreenGui:Destroy()
    end)
    GlobalEnv.ShadcnWalkSpeed = nil
end

CloseBtn.MouseButton1Click:Connect(function()
    Hub.Destroy()
end)

-- Initial apply
ApplySpeed()
SwitchTab(3)
print("⚡ [shadcn/ui] WalkSpeed, Combat & Auto Play Controller initialized successfully (Auto Play Active).")
