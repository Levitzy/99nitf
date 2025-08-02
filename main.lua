local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

wait(2)

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then
    warn("PlayerGui not found!")
    return
end

local TreeAura, KillAura

local function loadModules()
    print("Loading modules...")
    
    local success1, treeModule = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Jubiar01/99nitf/refs/heads/main/tree.lua"))()
    end)
    
    local success2, killModule = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Jubiar01/99nitf/refs/heads/main/kill.lua"))()
    end)
    
    if success1 and treeModule then
        TreeAura = treeModule
        print("✅ Tree Aura module loaded!")
    else
        print("❌ Failed to load Tree Aura module")
        TreeAura = {
            toggle = function() return false end,
            stop = function() end,
            setDistance = function() end,
            getDistance = function() return 86 end,
            setDelay = function() end,
            getDelay = function() return 0.1 end,
            isEnabled = function() return false end
        }
    end
    
    if success2 and killModule then
        KillAura = killModule
        print("✅ Kill Aura module loaded!")
    else
        print("❌ Failed to load Kill Aura module")
        KillAura = {
            toggle = function() return false end,
            stop = function() end,
            setDistance = function() end,
            getDistance = function() return 80 end,
            isEnabled = function() return false end
        }
    end
    
    print("Modules loading complete!")
    return TreeAura and KillAura
end

local function createRayfieldGUI()
    print("Creating Rayfield UI...")
    
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    
    local Window = Rayfield:CreateWindow({
        Name = "🎯 Aura Farm Pro v5.2",
        LoadingTitle = "Aura Farm Pro",
        LoadingSubtitle = "by Rayfield Interface Suite",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "AuraFarmPro",
            FileName = "config"
        },
        Discord = {
            Enabled = false,
            Invite = "noinvitelink",
            RememberJoins = true
        },
        KeySystem = false
    })
    
    local KillTab = Window:CreateTab("⚔️ Kill Aura", 4483345998)
    local TreeTab = Window:CreateTab("🌳 Tree Aura", 4483345998)
    local SettingsTab = Window:CreateTab("⚙️ Settings", 4483345998)
    
    local KillSection = KillTab:CreateSection("Kill Aura Controls")
    
    local killEnabled = false
    
    local KillToggle = KillTab:CreateToggle({
        Name = "Enable Kill Aura",
        CurrentValue = false,
        Flag = "KillAuraToggle",
        Callback = function(Value)
            killEnabled = Value
            if KillAura then
                if Value then
                    if not KillAura.isEnabled() then
                        KillAura.toggle()
                    end
                    Rayfield:Notify({
                        Title = "Kill Aura",
                        Content = "🟢 Kill Aura Enabled!",
                        Duration = 3,
                        Image = 4483345998
                    })
                else
                    if KillAura.isEnabled() then
                        KillAura.toggle()
                    end
                    Rayfield:Notify({
                        Title = "Kill Aura",
                        Content = "🔴 Kill Aura Disabled!",
                        Duration = 3,
                        Image = 4483345998
                    })
                end
            end
        end,
    })
    
    local KillSlider = KillTab:CreateSlider({
        Name = "Attack Distance",
        Range = {10, 200},
        Increment = 1,
        Suffix = "studs",
        CurrentValue = KillAura and KillAura.getDistance() or 80,
        Flag = "KillDistance",
        Callback = function(Value)
            if KillAura and KillAura.setDistance then
                KillAura.setDistance(Value)
                print("Kill Aura distance set to: " .. Value)
            end
        end,
    })
    
    local KillLabel = KillTab:CreateLabel("Status: Ready to use")
    
    KillTab:CreateSection("Information")
    
    KillTab:CreateParagraph({
        Title = "How Kill Aura Works",
        Content = "Kill Aura automatically attacks nearby players/NPCs within the specified range. Adjust the distance slider to control the attack range. Higher distances may affect performance."
    })
    
    local TreeSection = TreeTab:CreateSection("Tree Aura Controls")
    
    local treeEnabled = false
    
    local TreeToggle = TreeTab:CreateToggle({
        Name = "Enable Tree Aura",
        CurrentValue = false,
        Flag = "TreeAuraToggle",
        Callback = function(Value)
            treeEnabled = Value
            if TreeAura then
                if Value then
                    if not TreeAura.isEnabled() then
                        TreeAura.toggle()
                    end
                    Rayfield:Notify({
                        Title = "Tree Aura",
                        Content = "🟢 Tree Aura Enabled!",
                        Duration = 3,
                        Image = 4483345998
                    })
                else
                    if TreeAura.isEnabled() then
                        TreeAura.toggle()
                    end
                    Rayfield:Notify({
                        Title = "Tree Aura",
                        Content = "🔴 Tree Aura Disabled!",
                        Duration = 3,
                        Image = 4483345998
                    })
                end
            end
        end,
    })
    
    local TreeDistanceSlider = TreeTab:CreateSlider({
        Name = "Tree Distance",
        Range = {10, 200},
        Increment = 1,
        Suffix = "studs",
        CurrentValue = TreeAura and TreeAura.getDistance() or 86,
        Flag = "TreeDistance",
        Callback = function(Value)
            if TreeAura and TreeAura.setDistance then
                TreeAura.setDistance(Value)
                print("Tree Aura distance set to: " .. Value)
            end
        end,
    })
    
    local TreeDelaySlider = TreeTab:CreateSlider({
        Name = "Chopping Delay",
        Range = {0.1, 10},
        Increment = 0.1,
        Suffix = "seconds",
        CurrentValue = TreeAura and TreeAura.getDelay() or 0.1,
        Flag = "TreeDelay",
        Callback = function(Value)
            if TreeAura and TreeAura.setDelay then
                TreeAura.setDelay(Value)
                print("Tree Aura delay set to: " .. Value .. "s")
            end
        end,
    })
    
    local TreeLabel = TreeTab:CreateLabel("Status: Ready to farm")
    
    TreeTab:CreateSection("Tree Farming Guide")
    
    TreeTab:CreateParagraph({
        Title = "Tree Farming Tips",
        Content = "Tree Aura automatically chops trees within range. Lower delay = faster chopping but may cause lag. Higher delay = more stable performance and less detection risk."
    })
    
    TreeTab:CreateParagraph({
        Title = "Optimal Settings",
        Content = "Distance: 50-100 studs for best coverage. Delay: 0.1-0.5 seconds for optimal balance between speed and stability."
    })
    
    local GeneralSection = SettingsTab:CreateSection("General Controls")
    
    local ResetButton = SettingsTab:CreateButton({
        Name = "🔄 Reset All Settings",
        Callback = function()
            if TreeAura then
                TreeAura.setDistance(86)
                TreeAura.setDelay(0.1)
                TreeDistanceSlider:Set(86)
                TreeDelaySlider:Set(0.1)
            end
            if KillAura then
                KillAura.setDistance(80)
                KillSlider:Set(80)
            end
            Rayfield:Notify({
                Title = "Settings Reset",
                Content = "🔄 All settings reset to defaults!",
                Duration = 3,
                Image = 4483345998
            })
        end,
    })
    
    local StopAllButton = SettingsTab:CreateButton({
        Name = "🛑 Stop All Auras",
        Callback = function()
            if TreeAura and TreeAura.stop then
                TreeAura.stop()
                TreeToggle:Set(false)
                treeEnabled = false
            end
            if KillAura and KillAura.stop then
                KillAura.stop()
                KillToggle:Set(false)
                killEnabled = false
            end
            Rayfield:Notify({
                Title = "Emergency Stop",
                Content = "🛑 All auras stopped successfully!",
                Duration = 3,
                Image = 4483345998
            })
        end,
    })
    
    local DestroyButton = SettingsTab:CreateButton({
        Name = "🗑️ Destroy GUI",
        Callback = function()
            if TreeAura and TreeAura.stop then TreeAura.stop() end
            if KillAura and KillAura.stop then KillAura.stop() end
            Rayfield:Destroy()
            print("🗑️ Rayfield GUI destroyed!")
        end,
    })
    
    SettingsTab:CreateSection("Script Information")
    
    SettingsTab:CreateParagraph({
        Title = "Aura Farm Pro v5.2",
        Content = "Professional farming automation script with advanced aura systems. Built with Rayfield UI for the best user experience."
    })
    
    SettingsTab:CreateParagraph({
        Title = "Features",
        Content = "• Automatic Tree Farming with customizable delay\n• Kill Aura with adjustable range\n• Mobile & PC Compatible\n• Config Auto-Save\n• Professional UI Design"
    })
    
    SettingsTab:CreateSection("Credits & Support")
    
    SettingsTab:CreateLabel("Made with ❤️ for enhanced farming")
    SettingsTab:CreateLabel("UI Library: Rayfield Interface Suite")
    SettingsTab:CreateLabel("Created by: Aura Farm Pro Team")
    
    local statusUpdateLoop
    statusUpdateLoop = RunService.Heartbeat:Connect(function()
        wait(2)
        
        if KillAura and killEnabled then
            if KillAura.isEnabled() then
                KillLabel:Set("Status: 🟢 Active - Scanning for targets")
            else
                KillLabel:Set("Status: 🔴 Inactive")
            end
        else
            KillLabel:Set("Status: Ready to use")
        end
        
        if TreeAura and treeEnabled then
            if TreeAura.isEnabled() then
                local status = TreeAura.getStatus and TreeAura.getStatus()
                if status and status.treesFound then
                    TreeLabel:Set("Status: 🟢 Active - Trees found: " .. status.treesFound)
                else
                    TreeLabel:Set("Status: 🟢 Active - Scanning for trees")
                end
            else
                TreeLabel:Set("Status: 🔴 Inactive")
            end
        else
            TreeLabel:Set("Status: Ready to farm")
        end
    end)
    
    Rayfield:Notify({
        Title = "Aura Farm Pro",
        Content = "✨ Successfully loaded with Rayfield UI!",
        Duration = 5,
        Image = 4483345998
    })
    
    print("✨ Rayfield UI created successfully!")
    
    return {
        Rayfield = Rayfield,
        Window = Window,
        KillToggle = KillToggle,
        TreeToggle = TreeToggle,
        statusUpdateLoop = statusUpdateLoop
    }
end

local function main()
    print("🚀 Starting Premium Aura Controller v5.2 with Rayfield...")
    
    if not loadModules() then
        warn("Modules failed to load, using fallback functions")
    end
    
    local success, result = pcall(function()
        local gui = createRayfieldGUI()
        
        print("✨ Premium Aura Controller v5.2 with Rayfield loaded successfully!")
        print("🌳 Tree Aura: Distance & delay controls with real-time status")
        print("⚔️ Kill Aura: Adjustable attack distance with target scanning")
        print("📱 Rayfield Professional Interface with auto-save configs")
        
        return gui
    end)
    
    if not success then
        warn("Failed to create Rayfield GUI: " .. tostring(result))
        print("Error details: " .. tostring(result))
    end
end

main()
