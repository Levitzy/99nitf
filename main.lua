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

local TreeAura, KillAura, BringAura

local function loadModules()
    print("Loading modules...")
    
    local success1, treeModule = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Jubiar01/99nitf/refs/heads/main/tree.lua"))()
    end)
    
    local success2, killModule = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Jubiar01/99nitf/refs/heads/main/kill.lua"))()
    end)
    
    local success3, bringModule = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Jubiar01/99nitf/refs/heads/main/bring.lua"))()
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
            isEnabled = function() return false end,
            setMaxTreesPerCycle = function() end,
            getMaxTreesPerCycle = function() return 3 end,
            setAutoCollectLogs = function() end,
            getAutoCollectLogs = function() return true end
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
    
    if success3 and bringModule then
        BringAura = bringModule
        print("✅ Bring Aura module loaded!")
    else
        print("❌ Failed to load Bring Aura module")
        BringAura = {
            toggle = function() return false end,
            stop = function() end,
            setSelectedItem = function() end,
            getSelectedItem = function() return "Log" end,
            setDistance = function() end,
            getDistance = function() return 100 end,
            setDelay = function() end,
            getDelay = function() return 0.2 end,
            isEnabled = function() return false end,
            refreshItems = function() return {"Log", "Stone", "Stick"} end,
            getAvailableItems = function() return {"Log", "Stone", "Stick"} end
        }
    end
    
    print("Modules loading complete!")
    return TreeAura and KillAura and BringAura
end

local function createRayfieldGUI()
    print("Creating Rayfield UI...")
    
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    
    local Window = Rayfield:CreateWindow({
        Name = "🎯 Aura Farm Pro v7.0",
        LoadingTitle = "Aura Farm Pro",
        LoadingSubtitle = "Complete Automation Suite",
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
    
    local TreeTab = Window:CreateTab("🌳 Tree Farm", 4483345998)
    local KillTab = Window:CreateTab("⚔️ Kill Aura", 4483345998)
    local BringTab = Window:CreateTab("📦 Item Bring", 4483345998)
    local SettingsTab = Window:CreateTab("⚙️ Settings", 4483345998)
    
    TreeTab:CreateSection("Tree Farm Controls")
    
    local treeEnabled = false
    
    local TreeToggle = TreeTab:CreateToggle({
        Name = "Auto Farm Trees",
        CurrentValue = false,
        Flag = "AutoFarmTreeToggle",
        Callback = function(Value)
            treeEnabled = Value
            if TreeAura then
                if Value then
                    if not TreeAura.isEnabled() then
                        TreeAura.toggle()
                    end
                    Rayfield:Notify({
                        Title = "Tree Farm",
                        Content = "🟢 Auto Tree Farming Enabled!",
                        Duration = 3,
                        Image = 4483345998
                    })
                else
                    if TreeAura.isEnabled() then
                        TreeAura.toggle()
                    end
                    Rayfield:Notify({
                        Title = "Tree Farm",
                        Content = "🔴 Auto Tree Farming Disabled!",
                        Duration = 3,
                        Image = 4483345998
                    })
                end
            end
        end,
    })
    
    local TreeDistanceSlider = TreeTab:CreateSlider({
        Name = "Farm Distance",
        Range = {10, 200},
        Increment = 1,
        Suffix = "studs",
        CurrentValue = TreeAura and TreeAura.getDistance() or 86,
        Flag = "TreeDistance",
        Callback = function(Value)
            if TreeAura and TreeAura.setDistance then
                TreeAura.setDistance(Value)
            end
        end,
    })
    
    local TreeDelaySlider = TreeTab:CreateSlider({
        Name = "Chopping Delay",
        Range = {0.1, 2},
        Increment = 0.1,
        Suffix = "seconds",
        CurrentValue = TreeAura and TreeAura.getDelay() or 0.1,
        Flag = "TreeDelay",
        Callback = function(Value)
            if TreeAura and TreeAura.setDelay then
                TreeAura.setDelay(Value)
            end
        end,
    })
    
    local MaxTreesSlider = TreeTab:CreateSlider({
        Name = "Trees Per Cycle",
        Range = {1, 10},
        Increment = 1,
        Suffix = "trees",
        CurrentValue = TreeAura and TreeAura.getMaxTreesPerCycle() or 3,
        Flag = "MaxTrees",
        Callback = function(Value)
            if TreeAura and TreeAura.setMaxTreesPerCycle then
                TreeAura.setMaxTreesPerCycle(Value)
            end
        end,
    })
    
    TreeTab:CreateSection("Additional Options")
    
    local AutoCollectToggle = TreeTab:CreateToggle({
        Name = "Auto Collect Logs",
        CurrentValue = TreeAura and TreeAura.getAutoCollectLogs() or true,
        Flag = "AutoCollectLogs",
        Callback = function(Value)
            if TreeAura and TreeAura.setAutoCollectLogs then
                TreeAura.setAutoCollectLogs(Value)
            end
        end,
    })
    
    TreeTab:CreateParagraph({
        Title = "Enhanced Tree Farming",
        Content = "Automatically farms trees from both Foliage and Landmarks folders. Supports Small Trees, multiple trees per cycle, and auto log collection within 15 studs."
    })
    
    KillTab:CreateSection("Kill Aura Controls")
    
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
            end
        end,
    })
    
    KillTab:CreateParagraph({
        Title = "Combat System",
        Content = "Automatically attacks the closest target within range. Uses Chainsaw > Strong Axe > Gooad Axe > Old Axe > Axe priority for maximum damage."
    })
    
    BringTab:CreateSection("Item Bring Controls")
    
    local bringEnabled = false
    local selectedItemDropdown
    
    local function refreshItemDropdown()
        if BringAura then
            local items = BringAura.refreshItems()
            if selectedItemDropdown then
                selectedItemDropdown:Refresh(items, BringAura.getSelectedItem())
            end
        end
    end
    
    selectedItemDropdown = BringTab:CreateDropdown({
        Name = "Select Item to Bring",
        Options = BringAura and BringAura.getAvailableItems() or {"Log"},
        CurrentOption = BringAura and BringAura.getSelectedItem() or "Log",
        Flag = "SelectedItem",
        Callback = function(Value)
            if BringAura and BringAura.setSelectedItem then
                BringAura.setSelectedItem(Value)
            end
        end,
    })
    
    local RefreshButton = BringTab:CreateButton({
        Name = "🔄 Refresh Item List",
        Callback = function()
            refreshItemDropdown()
            Rayfield:Notify({
                Title = "Items Refreshed",
                Content = "📦 Item list updated!",
                Duration = 2,
                Image = 4483345998
            })
        end,
    })
    
    local BringToggle = BringTab:CreateToggle({
        Name = "Auto Bring Items",
        CurrentValue = false,
        Flag = "BringAuraToggle",
        Callback = function(Value)
            bringEnabled = Value
            if BringAura then
                if Value then
                    if not BringAura.isEnabled() then
                        BringAura.toggle()
                    end
                    Rayfield:Notify({
                        Title = "Item Bring",
                        Content = "🟢 Auto Bring Enabled for " .. BringAura.getSelectedItem(),
                        Duration = 3,
                        Image = 4483345998
                    })
                else
                    if BringAura.isEnabled() then
                        BringAura.toggle()
                    end
                    Rayfield:Notify({
                        Title = "Item Bring",
                        Content = "🔴 Auto Bring Disabled!",
                        Duration = 3,
                        Image = 4483345998
                    })
                end
            end
        end,
    })
    
    local BringDistanceSlider = BringTab:CreateSlider({
        Name = "Bring Distance",
        Range = {10, 500},
        Increment = 5,
        Suffix = "studs",
        CurrentValue = BringAura and BringAura.getDistance() or 100,
        Flag = "BringDistance",
        Callback = function(Value)
            if BringAura and BringAura.setDistance then
                BringAura.setDistance(Value)
            end
        end,
    })
    
    local BringDelaySlider = BringTab:CreateSlider({
        Name = "Bring Delay",
        Range = {0.1, 5},
        Increment = 0.1,
        Suffix = "seconds",
        CurrentValue = BringAura and BringAura.getDelay() or 0.2,
        Flag = "BringDelay",
        Callback = function(Value)
            if BringAura and BringAura.setDelay then
                BringAura.setDelay(Value)
            end
        end,
    })
    
    BringTab:CreateParagraph({
        Title = "Item Collection System",
        Content = "Automatically brings selected items to your location. Choose any item from the workspace and set custom distance/delay. Use refresh button to update available items."
    })
    
    SettingsTab:CreateSection("General Controls")
    
    local ResetButton = SettingsTab:CreateButton({
        Name = "🔄 Reset All Settings",
        Callback = function()
            if TreeAura then
                TreeAura.setDistance(86)
                TreeAura.setDelay(0.1)
                TreeAura.setMaxTreesPerCycle(3)
                TreeAura.setAutoCollectLogs(true)
                TreeDistanceSlider:Set(86)
                TreeDelaySlider:Set(0.1)
                MaxTreesSlider:Set(3)
                AutoCollectToggle:Set(true)
            end
            if KillAura then
                KillAura.setDistance(80)
                KillSlider:Set(80)
            end
            if BringAura then
                BringAura.setDistance(100)
                BringAura.setDelay(0.2)
                BringDistanceSlider:Set(100)
                BringDelaySlider:Set(0.2)
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
            if BringAura and BringAura.stop then
                BringAura.stop()
                BringToggle:Set(false)
                bringEnabled = false
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
            if BringAura and BringAura.stop then BringAura.stop() end
            Rayfield:Destroy()
            print("🗑️ Rayfield GUI destroyed!")
        end,
    })
    
    SettingsTab:CreateSection("Script Information")
    
    SettingsTab:CreateParagraph({
        Title = "Aura Farm Pro v7.0",
        Content = "Complete automation suite with enhanced tree farming, item collection system, and combat features. Now includes automatic log collection and multi-tree farming capabilities."
    })
    
    SettingsTab:CreateParagraph({
        Title = "New Features v7.0",
        Content = "• Unified Tree Farming (Foliage + Landmarks)\n• Item Bring System with Dropdown\n• Auto Log Collection\n• Multi-Tree Per Cycle\n• Chainsaw Support\n• Enhanced Performance\n• Cleaner Interface"
    })
    
    SettingsTab:CreateSection("Credits")
    
    SettingsTab:CreateLabel("Complete Automation Suite")
    SettingsTab:CreateLabel("UI Library: Rayfield Interface Suite")
    SettingsTab:CreateLabel("Created by: Aura Farm Pro Team")
    
    refreshItemDropdown()
    
    Rayfield:Notify({
        Title = "Aura Farm Pro v7.0",
        Content = "✨ Complete Automation Suite Loaded!",
        Duration = 5,
        Image = 4483345998
    })
    
    print("✨ Rayfield UI created successfully!")
    
    return {
        Rayfield = Rayfield,
        Window = Window,
        TreeToggle = TreeToggle,
        KillToggle = KillToggle,
        BringToggle = BringToggle
    }
end

local function main()
    print("🚀 Starting Aura Farm Pro v7.0 Complete Automation Suite...")
    
    if not loadModules() then
        warn("Some modules failed to load, using fallback functions")
    end
    
    local success, result = pcall(function()
        local gui = createRayfieldGUI()
        
        print("✨ Aura Farm Pro v7.0 Complete Automation Suite loaded!")
        print("🌳 Tree Farm: Unified farming with auto log collection")
        print("⚔️ Kill Aura: Enhanced targeting with tool priority")
        print("📦 Item Bring: Complete item collection system")
        print("🎮 Full automation suite ready!")
        
        return gui
    end)
    
    if not success then
        warn("Failed to create Rayfield GUI: " .. tostring(result))
        print("Error details: " .. tostring(result))
    end
end

main()
