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

local TreeAura, KillAura, BringItems

local function loadModules()
    print("Loading modules...")
    
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
    
    KillAura = {
        toggle = function() return false end,
        stop = function() end,
        setDistance = function() end,
        getDistance = function() return 80 end,
        isEnabled = function() return false end
    }
    
    BringItems = {
        bringSelected = function() return false end,
        bringAll = function() return false end,
        setSelectedItem = function() end,
        getSelectedItem = function() return nil end,
        refreshItems = function() return {} end,
        getAvailableItems = function() return {} end,
        getItemCount = function() return 0 end,
        clearSelection = function() end,
        debugSelection = function() end,
        isEnabled = function() return false end,
        toggle = function() return false end,
        stop = function() end
    }
    
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
        print("❌ Failed to load Tree Aura module - using fallback")
    end
    
    if success2 and killModule then
        KillAura = killModule
        print("✅ Kill Aura module loaded!")
    else
        print("❌ Failed to load Kill Aura module - using fallback")
    end
    
    if success3 and bringModule then
        BringItems = bringModule
        print("✅ Bring Items module loaded!")
    else
        print("❌ Failed to load Bring Items module - using fallback")
    end
    
    print("Modules loading complete!")
    return true
end

local function createRayfieldGUI()
    print("Creating Rayfield UI...")
    
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    
    local Window = Rayfield:CreateWindow({
        Name = "🎯 Aura Farm Pro v13.0",
        LoadingTitle = "Aura Farm Pro",
        LoadingSubtitle = "Dropdown Only + Drop at Player",
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
    local BringTab = Window:CreateTab("📦 Bring Items", 4483345998)
    local SettingsTab = Window:CreateTab("⚙️ Settings", 4483345998)
    
    TreeTab:CreateSection("Tree Farm Controls")
    
    local TreeToggle = TreeTab:CreateToggle({
        Name = "Auto Farm Trees",
        CurrentValue = false,
        Flag = "AutoFarmTreeToggle",
        Callback = function(Value)
            pcall(function()
                if TreeAura then
                    if Value then
                        TreeAura.toggle()
                        Rayfield:Notify({
                            Title = "Tree Farm",
                            Content = "🟢 Auto Tree Farming Enabled!",
                            Duration = 3,
                            Image = 4483345998
                        })
                    else
                        TreeAura.stop()
                        Rayfield:Notify({
                            Title = "Tree Farm",
                            Content = "🔴 Auto Tree Farming Disabled!",
                            Duration = 3,
                            Image = 4483345998
                        })
                    end
                end
            end)
        end,
    })
    
    local TreeDistanceSlider = TreeTab:CreateSlider({
        Name = "Farm Distance",
        Range = {10, 200},
        Increment = 1,
        Suffix = "studs",
        CurrentValue = 86,
        Flag = "TreeDistance",
        Callback = function(Value)
            pcall(function()
                if TreeAura and TreeAura.setDistance then
                    TreeAura.setDistance(Value)
                end
            end)
        end,
    })
    
    local TreeDelaySlider = TreeTab:CreateSlider({
        Name = "Chopping Delay",
        Range = {0.1, 2},
        Increment = 0.1,
        Suffix = "seconds",
        CurrentValue = 0.1,
        Flag = "TreeDelay",
        Callback = function(Value)
            pcall(function()
                if TreeAura and TreeAura.setDelay then
                    TreeAura.setDelay(Value)
                end
            end)
        end,
    })
    
    local MaxTreesSlider = TreeTab:CreateSlider({
        Name = "Trees Per Cycle",
        Range = {1, 10},
        Increment = 1,
        Suffix = "trees",
        CurrentValue = 3,
        Flag = "MaxTrees",
        Callback = function(Value)
            pcall(function()
                if TreeAura and TreeAura.setMaxTreesPerCycle then
                    TreeAura.setMaxTreesPerCycle(Value)
                end
            end)
        end,
    })
    
    local AutoCollectToggle = TreeTab:CreateToggle({
        Name = "Auto Collect Logs",
        CurrentValue = true,
        Flag = "AutoCollectLogs",
        Callback = function(Value)
            pcall(function()
                if TreeAura and TreeAura.setAutoCollectLogs then
                    TreeAura.setAutoCollectLogs(Value)
                end
            end)
        end,
    })
    
    TreeTab:CreateParagraph({
        Title = "Enhanced Tree Farming",
        Content = "Automatically farms trees from both Foliage and Landmarks folders. Supports all tree types with auto log collection."
    })
    
    KillTab:CreateSection("Kill Aura Controls")
    
    local KillToggle = KillTab:CreateToggle({
        Name = "Enable Kill Aura",
        CurrentValue = false,
        Flag = "KillAuraToggle",
        Callback = function(Value)
            pcall(function()
                if KillAura then
                    if Value then
                        KillAura.toggle()
                        Rayfield:Notify({
                            Title = "Kill Aura",
                            Content = "🟢 Kill Aura Enabled!",
                            Duration = 3,
                            Image = 4483345998
                        })
                    else
                        KillAura.stop()
                        Rayfield:Notify({
                            Title = "Kill Aura",
                            Content = "🔴 Kill Aura Disabled!",
                            Duration = 3,
                            Image = 4483345998
                        })
                    end
                end
            end)
        end,
    })
    
    local KillSlider = KillTab:CreateSlider({
        Name = "Attack Distance",
        Range = {10, 200},
        Increment = 1,
        Suffix = "studs",
        CurrentValue = 80,
        Flag = "KillDistance",
        Callback = function(Value)
            pcall(function()
                if KillAura and KillAura.setDistance then
                    KillAura.setDistance(Value)
                end
            end)
        end,
    })
    
    KillTab:CreateParagraph({
        Title = "Combat System",
        Content = "Automatically attacks the closest target within range. Uses best available tool for maximum damage."
    })
    
    BringTab:CreateSection("Item Selection")
    
    local selectedItemDropdown
    local selectionStatusLabel
    local currentSelection = nil
    
    local function updateSelectionDisplay()
        pcall(function()
            if BringItems then
                local selected = BringItems.getSelectedItem()
                local count = 0
                
                if selected then
                    count = BringItems.getItemCount(selected)
                    currentSelection = selected
                end
                
                local statusText = selected and ("✅ Selected: " .. selected .. " | Available: " .. count .. " items") or "❌ No item selected"
                
                if selectionStatusLabel then
                    selectionStatusLabel:Set({
                        Title = "Selection Status",
                        Content = statusText
                    })
                end
                
                print("📊 " .. statusText)
            end
        end)
    end
    
    local function refreshAndUpdate()
        pcall(function()
            if BringItems and BringItems.refreshItems then
                local items = BringItems.refreshItems()
                
                if items and #items > 0 then
                    print("🔄 Available items: " .. table.concat(items, ", "))
                    
                    if selectedItemDropdown then
                        selectedItemDropdown:Refresh(items)
                    end
                    
                    updateSelectionDisplay()
                    return items
                end
            end
        end)
    end
    
    selectionStatusLabel = BringTab:CreateParagraph({
        Title = "Selection Status",
        Content = "❌ No item selected"
    })
    
    selectedItemDropdown = BringTab:CreateDropdown({
        Name = "Select Item Type",
        Options = {"None"},
        CurrentOption = "None",
        Flag = "MainItemDropdown",
        Callback = function(Option)
            pcall(function()
                print("🎯 DROPDOWN CALLBACK TRIGGERED: " .. tostring(Option))
                
                if Option and type(Option) == "string" and Option ~= "" and Option ~= "None" then
                    print("🎯 VALID OPTION SELECTED: " .. Option)
                    
                    if BringItems and BringItems.setSelectedItem then
                        local success = BringItems.setSelectedItem(Option)
                        if success then
                            currentSelection = Option
                            print("✅ SELECTION SUCCESS: " .. Option)
                            
                            wait(0.3)
                            updateSelectionDisplay()
                            
                            Rayfield:Notify({
                                Title = "Item Selected",
                                Content = "✅ Selected: " .. Option,
                                Duration = 2,
                                Image = 4483345998
                            })
                        else
                            print("❌ SELECTION FAILED for: " .. Option)
                        end
                    end
                else
                    print("❌ Invalid dropdown option: " .. tostring(Option))
                    if BringItems and BringItems.clearSelection then
                        BringItems.clearSelection()
                        currentSelection = nil
                        updateSelectionDisplay()
                    end
                end
            end)
        end,
    })
    
    local RefreshButton = BringTab:CreateButton({
        Name = "🔄 Scan Available Items",
        Callback = function()
            local items = refreshAndUpdate()
            if items and #items > 0 then
                Rayfield:Notify({
                    Title = "Items Scanned",
                    Content = "🔄 Found " .. #items .. " item types!",
                    Duration = 2,
                    Image = 4483345998
                })
            else
                Rayfield:Notify({
                    Title = "No Items",
                    Content = "❌ No items found in world!",
                    Duration = 2,
                    Image = 4483345998
                })
            end
        end,
    })
    
    local ClearSelectionButton = BringTab:CreateButton({
        Name = "🧹 Clear Selection",
        Callback = function()
            pcall(function()
                if BringItems and BringItems.clearSelection then
                    BringItems.clearSelection()
                    currentSelection = nil
                    updateSelectionDisplay()
                    
                    Rayfield:Notify({
                        Title = "Selection Cleared",
                        Content = "🧹 No item selected",
                        Duration = 2,
                        Image = 4483345998
                    })
                end
            end)
        end,
    })
    
    BringTab:CreateSection("Bring Actions")
    
    local BringSelectedButton = BringTab:CreateButton({
        Name = "📦 Bring Selected Items",
        Callback = function()
            pcall(function()
                if BringItems then
                    local selected = BringItems.getSelectedItem()
                    
                    if not selected then
                        Rayfield:Notify({
                            Title = "No Selection",
                            Content = "❌ Please select an item first!",
                            Duration = 3,
                            Image = 4483345998
                        })
                        return
                    end
                    
                    print("🚀 BRINGING ITEMS: " .. selected)
                    local success = BringItems.bringSelected()
                    
                    if success then
                        Rayfield:Notify({
                            Title = "Items Brought & Dropped",
                            Content = "✅ Brought " .. selected .. " and dropped at your position!",
                            Duration = 3,
                            Image = 4483345998
                        })
                    else
                        Rayfield:Notify({
                            Title = "No Items Found",
                            Content = "❌ No " .. selected .. " items found!",
                            Duration = 3,
                            Image = 4483345998
                        })
                    end
                    
                    wait(1)
                    updateSelectionDisplay()
                end
            end)
        end,
    })
    
    local BringAllButton = BringTab:CreateButton({
        Name = "🌟 Bring ALL Items",
        Callback = function()
            pcall(function()
                if BringItems and BringItems.bringAll then
                    print("🚀 BRINGING ALL ITEMS")
                    local success = BringItems.bringAll()
                    
                    if success then
                        Rayfield:Notify({
                            Title = "All Items Brought & Dropped",
                            Content = "✅ Brought ALL items and dropped at your position!",
                            Duration = 3,
                            Image = 4483345998
                        })
                    else
                        Rayfield:Notify({
                            Title = "No Items Found",
                            Content = "❌ No items found in world!",
                            Duration = 3,
                            Image = 4483345998
                        })
                    end
                    
                    wait(1)
                    updateSelectionDisplay()
                end
            end)
        end,
    })
    
    local DebugButton = BringTab:CreateButton({
        Name = "🐛 Debug Selection",
        Callback = function()
            pcall(function()
                if BringItems and BringItems.debugSelection then
                    BringItems.debugSelection()
                    updateSelectionDisplay()
                    
                    Rayfield:Notify({
                        Title = "Debug Info",
                        Content = "🐛 Check console for debug output",
                        Duration = 2,
                        Image = 4483345998
                    })
                end
            end)
        end,
    })
    
    BringTab:CreateParagraph({
        Title = "Dropdown Only + Drop System",
        Content = "Simplified to use only dropdown selection. Items are brought to your CFrame, then dropped at your Humanoid position for easy collection!"
    })
    
    BringTab:CreateParagraph({
        Title = "How It Works",
        Content = "1. Scan available items to refresh dropdown\n2. Select item type from dropdown\n3. Items teleport above you then drop to your position\n4. Items arrange in circles around your character\n5. Multiple item support with proper spacing"
    })
    
    SettingsTab:CreateSection("General Controls")
    
    local ResetButton = SettingsTab:CreateButton({
        Name = "🔄 Reset All Settings",
        Callback = function()
            pcall(function()
                TreeDistanceSlider:Set(86)
                TreeDelaySlider:Set(0.1)
                MaxTreesSlider:Set(3)
                AutoCollectToggle:Set(true)
                KillSlider:Set(80)
                
                if TreeAura then
                    if TreeAura.setDistance then TreeAura.setDistance(86) end
                    if TreeAura.setDelay then TreeAura.setDelay(0.1) end
                    if TreeAura.setMaxTreesPerCycle then TreeAura.setMaxTreesPerCycle(3) end
                    if TreeAura.setAutoCollectLogs then TreeAura.setAutoCollectLogs(true) end
                end
                if KillAura and KillAura.setDistance then
                    KillAura.setDistance(80)
                end
                
                if BringItems and BringItems.clearSelection then
                    BringItems.clearSelection()
                    currentSelection = nil
                    updateSelectionDisplay()
                end
                
                Rayfield:Notify({
                    Title = "Settings Reset",
                    Content = "🔄 All settings reset to defaults!",
                    Duration = 3,
                    Image = 4483345998
                })
            end)
        end,
    })
    
    local StopAllButton = SettingsTab:CreateButton({
        Name = "🛑 Stop All Systems",
        Callback = function()
            pcall(function()
                if TreeAura and TreeAura.stop then
                    TreeAura.stop()
                    TreeToggle:Set(false)
                end
                if KillAura and KillAura.stop then
                    KillAura.stop()
                    KillToggle:Set(false)
                end
                if BringItems and BringItems.stop then
                    BringItems.stop()
                end
                
                Rayfield:Notify({
                    Title = "Emergency Stop",
                    Content = "🛑 All systems stopped!",
                    Duration = 3,
                    Image = 4483345998
                })
            end)
        end,
    })
    
    local DestroyButton = SettingsTab:CreateButton({
        Name = "🗑️ Destroy GUI",
        Callback = function()
            pcall(function()
                if TreeAura and TreeAura.stop then TreeAura.stop() end
                if KillAura and KillAura.stop then KillAura.stop() end
                if BringItems and BringItems.stop then BringItems.stop() end
                Rayfield:Destroy()
                print("🗑️ GUI destroyed successfully!")
            end)
        end,
    })
    
    SettingsTab:CreateSection("Script Information")
    
    SettingsTab:CreateParagraph({
        Title = "Aura Farm Pro v13.0 - Dropdown Only + Drop",
        Content = "Simplified to use only dropdown selection with enhanced drop system. Items bring to your CFrame then drop at your Humanoid position!"
    })
    
    SettingsTab:CreateParagraph({
        Title = "New Drop System Features",
        Content = "• Dropdown only selection (no manual input)\n• Items teleport to your CFrame first\n• Then drop at your Humanoid position\n• Circular arrangement around player\n• Multiple item support with spacing\n• Enhanced positioning and physics\n• Better item collision handling"
    })
    
    wait(1)
    refreshAndUpdate()
    updateSelectionDisplay()
    
    Rayfield:Notify({
        Title = "Aura Farm Pro v13.0",
        Content = "✨ Dropdown only + drop system ready!",
        Duration = 5,
        Image = 4483345998
    })
    
    print("✨ Dropdown selection and drop system loaded!")
    
    return {
        Rayfield = Rayfield,
        Window = Window,
        TreeToggle = TreeToggle,
        KillToggle = KillToggle
    }
end

local function main()
    print("🚀 Starting Aura Farm Pro v13.0 - Dropdown Only + Drop System...")
    
    loadModules()
    
    local success, result = pcall(function()
        local gui = createRayfieldGUI()
        
        print("✨ Aura Farm Pro v13.0 loaded successfully!")
        print("🌳 Tree Farm: " .. (TreeAura and "✅ LOADED" or "❌ FALLBACK"))
        print("⚔️ Kill Aura: " .. (KillAura and "✅ LOADED" or "❌ FALLBACK"))
        print("📦 Bring Items: " .. (BringItems and "✅ LOADED" or "❌ FALLBACK"))
        print("📋 Selection Method: ✅ DROPDOWN ONLY")
        print("📍 Drop System: ✅ CFrame → HUMANOID POSITION")
        print("🎯 Multiple Item Support: ✅ CIRCULAR ARRANGEMENT")
        
        return gui
    end)
    
    if not success then
        warn("Failed to create GUI: " .. tostring(result))
    end
end

main()
