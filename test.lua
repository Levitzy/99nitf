-- CONFIG: put the raw URL that returns this script's source (raw gist / pastebin raw / raw GitHub)
local LOADER_RAW_URL = "https://raw.githubusercontent.com/yourusername/yourrepo/main/autofarm.lua" -- <<--- REPLACE THIS

-- Attempt to queue loader on teleport (supports common executors)
local function queue_on_teleport_loader(rawUrl)
    local code = ("loadstring(game:HttpGet('%s'))()"):format(rawUrl)
    if syn and syn.queue_on_teleport then
        pcall(function() syn.queue_on_teleport(code) end)
        return true
    elseif queue_on_teleport then
        pcall(function() queue_on_teleport(code) end)
        return true
    elseif _G.queue_on_teleport then
        pcall(function() _G.queue_on_teleport(code) end)
        return true
    end
    -- fallback: copy to clipboard so user can paste after join
    pcall(function()
        if setclipboard then
            setclipboard(code)
        elseif toclipboard then
            toclipboard(code)
        end
    end)
    return false
end

local queued = false
if LOADER_RAW_URL and LOADER_RAW_URL:match("^https?://") then
    queued = queue_on_teleport_loader(LOADER_RAW_URL)
    if not queued then
        warn("queue_on_teleport not available. A loadstring launcher has been copied to your clipboard. After rejoin paste it into your executor to resume autofarm.")
    end
else
    warn("LOADER_RAW_URL not set. Please host the script somewhere raw and set LOADER_RAW_URL to that link for full auto-queue functionality.")
end

-- ==== Autofarm + Auto-Rejoin Script ====
-- Load Fluent UI (already in your earlier scripts)
local ok, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)
if not ok then
    warn("Failed to load Fluent UI.")
    Fluent = nil
end

-- Build UI if Fluent available
local Window, Tab
if Fluent then
    Window = Fluent:CreateWindow({
        Title = "Autofarm GUI",
        SubTitle = "Refill + Place Blocks (Auto Rejoin)",
        TabWidth = 160,
        Size = UDim2.fromOffset(420, 320),
        Acrylic = false,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.RightControl
    })
    Tab = Window:AddTab({ Title = "Autofarm", Icon = "rbxassetid://7734068321" })
end

-- Autofarm state (auto-enabled)
local autofarmEnabled = true

-- Add toggle if UI present
if Tab then
    Tab:AddToggle("AutoFarmToggle", {
        Title = "Enable Autofarm",
        Default = true,
        Callback = function(value)
            autofarmEnabled = value
        end
    })
end

-- Services and events
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local refillEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RefillBlocks")
local placeEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlaceBlock")

-- Autofarm: every frame (fast)
local heartbeatConn
heartbeatConn = RunService.Heartbeat:Connect(function()
    if autofarmEnabled then
        -- Fire as fast as possible
        pcall(function()
            refillEvent:FireServer()
            placeEvent:FireServer()
        end)
    end
end)

-- Helper: find progress text label robustly
local function findProgressTextLabel()
    local success, core = pcall(function() return LocalPlayer.PlayerGui:WaitForChild("Core",5) end)
    if not success or not core then return nil end

    local hud = core:FindFirstChild("Hud") or core:FindFirstChildWhichIsA("Folder")
    if not hud then
        -- scan children for likely candidate
        for _,c in ipairs(core:GetDescendants()) do
            if c:IsA("TextLabel") and c.Text:match("Progress[:%s]") then
                return c
            end
        end
        return nil
    end

    -- try expected path
    local top = hud:FindFirstChild("Top") or hud:FindFirstChildWhichIsA("Frame")
    if top then
        local pb = top:FindFirstChild("ProgressBar") or top:FindFirstChildWhichIsA("Frame")
        if pb then
            -- look for a text label with % in it
            for _,child in ipairs(pb:GetDescendants()) do
                if child:IsA("TextLabel") and child.Text:match("%%") then
                    return child
                end
            end
        end
    end

    -- last resort: search all PlayerGui for a TextLabel with 100% pattern
    for _,c in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if c:IsA("TextLabel") and c.Text:match("%d+/%d+ %(%d+%%%)") then
            return c
        end
    end

    return nil
end

-- Auto-rejoin when progress hits 100%
task.spawn(function()
    local progressLabel = nil
    while not progressLabel do
        progressLabel = findProgressTextLabel()
        if progressLabel then break end
        task.wait(1)
    end

    while task.wait(0.8) do
        if autofarmEnabled and progressLabel and progressLabel.Parent and progressLabel.Text then
            local text = progressLabel.Text
            if string.find(text, "100%%") or string.find(text, "%(100%%%)") or text:match("%d+/%d+ %[100%%%]") then
                -- Queue loader again (try again in case queueing expired)
                if LOADER_RAW_URL and LOADER_RAW_URL:match("^https?://") then
                    queue_on_teleport_loader(LOADER_RAW_URL)
                end

                -- Teleport to another server (matchmaking)
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)

                -- If teleport fails (rare), wait and try again
                task.wait(5)
            end
        end
    end
end)

-- Clean exit handling (optional)
local function cleanup()
    if heartbeatConn then
        heartbeatConn:Disconnect()
    end
end
game:BindToClose(cleanup)
