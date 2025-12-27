-- ============================================================================
-- !Koality-of-Life: Binds Module - MOCKUP UI
-- ============================================================================
-- ElvUI-style mockup with left selection panel using childGroups = "tree"
-- ============================================================================

local KOL = KoalityOfLife

-- Initialize Binds namespace if it doesn't exist
KOL.Binds = KOL.Binds or {}
KOL.Binds.customGroups = KOL.Binds.customGroups or {}  -- Track custom-created groups

-- ============================================================================
-- Config UI Registration
-- ============================================================================

function KOL.Binds:InitializeMockupUI()
    -- Make sure UI system is initialized first
    if not KOL.configOptions then
        KOL:DebugPrint("Binds Mockup: Waiting for main UI to initialize...", 3)
        return
    end

    -- Create the Binds mockup group with tree layout (ElvUI style)
    KOL.configGroups.bindsMockup = {
        type = "group",
        name = "|cFFFF88AABinds Mockup|r",
        childGroups = "tree",  -- THIS creates the left selection panel!
        order = 101,
        args = {
            header = {
                order = 1,
                type = "description",
                name = "|cFF66FFBBElvUI-Style Binds Management Interface|r\n|cFFAAAA00Click groups on the left to view their configuration.|r\n\n",
                fontSize = "medium",
            },

            addGroupName = {
                order = 2,
                type = "input",
                name = "Group Name",
                desc = "Enter the name for the new bind group",
                width = 0.75,
                get = function() return KOL.Binds.newGroupName or "" end,
                set = function(info, value)
                    KOL.Binds.newGroupName = value
                end,
            },
            addGroupSep = {
                order = 3,
                type = "description",
                name = ">",
                width = 0.05,
            },
            addGroupDesc = {
                order = 4,
                type = "input",
                name = "Description",
                desc = "Enter a short description for this group",
                width = 0.75,
                get = function() return KOL.Binds.newGroupDesc or "" end,
                set = function(info, value)
                    KOL.Binds.newGroupDesc = value
                end,
            },
            addGroupSep2 = {
                order = 5,
                type = "description",
                name = ">",
                width = 0.05,
            },
            addGroupButton = {
                order = 6,
                type = "execute",
                name = "Add Bind Group",
                desc = "Create a new bind group",
                width = 0.65,
                func = function()
                    local groupName = KOL.Binds.newGroupName or ""
                    local groupDesc = KOL.Binds.newGroupDesc or ""

                    if groupName == "" then
                        print("|cFFFF6666Error:|r Please enter a group name")
                        return
                    end

                    -- Create a safe key from the group name
                    local groupKey = groupName:gsub("%s+", ""):lower() .. "Group"

                    -- Mark this as a custom group
                    KOL.Binds.customGroups[groupKey] = true

                    -- Create the new group
                    KOL.configGroups.bindsMockup.args[groupKey] = {
                        order = 60,
                        type = "group",
                        name = "|cFFFFAA00" .. groupName .. "|r",
                        args = {
                            header = {
                                order = 1,
                                type = "header",
                                name = groupName,
                            },
                            description = {
                                order = 2,
                                type = "description",
                                name = groupDesc .. "\n\n|cFF88FF88Enabled:|r 0  |  |cFFFF6666Disabled:|r 0\n",
                            },
                            deleteGroupButton = {
                                order = 2.5,
                                type = "execute",
                                name = "|cFFFF6666Delete This Group|r",
                                desc = "Hold CTRL+SHIFT and click to delete this group",
                                width = "full",
                                confirm = true,
                                confirmText = "Delete this bind group? This cannot be undone.",
                                func = function()
                                    if not (IsControlKeyDown() and IsShiftKeyDown()) then
                                        print("|cFFFF6666Error:|r You must hold CTRL+SHIFT to delete a group")
                                        return
                                    end

                                    -- Remove the group
                                    KOL.configGroups.bindsMockup.args[groupKey] = nil
                                    KOL.Binds.customGroups[groupKey] = nil

                                    print("|cFF88FF88Success:|r Deleted bind group: " .. groupName)
                                end,
                            },
                            spacer1 = {
                                order = 2.6,
                                type = "description",
                                name = "\n",
                            },
                            addBindName = {
                                order = 3,
                                type = "input",
                                name = "Bind Name",
                                desc = "Enter the name for the new bind",
                                width = 0.8,
                                get = function() return KOL.Binds["newBindName_" .. groupKey] or "" end,
                                set = function(info, value)
                                    KOL.Binds["newBindName_" .. groupKey] = value
                                end,
                            },
                            addBindSep1 = {
                                order = 4,
                                type = "description",
                                name = ">",
                                width = 0.05,
                            },
                            addBindGroup = {
                                order = 5,
                                type = "select",
                                name = "Bind Group",
                                desc = "Choose which group to add this bind to",
                                width = 0.8,
                                values = function()
                                    return {
                                        general = "General",
                                        combat = "Combat",
                                        social = "Social",
                                        utility = "Utility",
                                        [groupKey] = groupName,
                                    }
                                end,
                                get = function() return KOL.Binds["newBindGroup_" .. groupKey] or groupKey end,
                                set = function(info, value)
                                    KOL.Binds["newBindGroup_" .. groupKey] = value
                                end,
                            },
                            addBindSep2 = {
                                order = 6,
                                type = "description",
                                name = ">",
                                width = 0.05,
                            },
                            addBindButton = {
                                order = 7,
                                type = "execute",
                                name = "Add Bind",
                                desc = "Add a new bind to this group",
                                width = 0.5,
                                func = function()
                                    local bindName = KOL.Binds["newBindName_" .. groupKey] or ""
                                    if bindName == "" then
                                        print("|cFFFF6666Error:|r Please enter a bind name")
                                        return
                                    end

                                    local targetGroup = KOL.Binds["newBindGroup_" .. groupKey] or groupKey
                                    local targetGroupName = targetGroup:gsub("^%l", string.upper)
                                    print("|cFF88FF88Success:|r Added new bind to " .. targetGroupName .. ": " .. bindName)
                                    KOL.Binds["newBindName_" .. groupKey] = ""
                                    KOL.Binds["newBindGroup_" .. groupKey] = groupKey
                                end,
                            },
                        }
                    }

                    print("|cFF88FF88Success:|r Added new bind group: " .. groupName)
                    -- Clear the input fields
                    KOL.Binds.newGroupName = ""
                    KOL.Binds.newGroupDesc = ""
                end,
            },

            -- ================================================================
            -- GENERAL GROUP (with Configs merged at top)
            -- ================================================================
            generalGroup = {
                order = 20,
                type = "group",
                name = "|cFFFFFF99General|r",
                args = {
                    -- Configuration Options Section
                    configHeader = {
                        order = 1,
                        type = "header",
                        name = "Configuration Options",
                    },
                    enableBinds = {
                        order = 2,
                        type = "toggle",
                        name = "Enable Binds System",
                        desc = "Master toggle for the entire Binds system",
                        width = "normal",
                        get = function() return true end,
                        set = function() end,
                    },
                    showInCombat = {
                        order = 3,
                        type = "toggle",
                        name = "Show Binds In Combat",
                        desc = "Allow bind execution during combat",
                        width = "normal",
                        get = function() return false end,
                        set = function() end,
                    },

                    spacer1 = {
                        order = 9,
                        type = "description",
                        name = "\n",
                    },

                    -- General Binds Section
                    header = {
                        order = 10,
                        type = "header",
                        name = "General",
                    },
                    description = {
                        order = 11,
                        type = "description",
                        name = "Default keybinds that don't belong to specific groups.\n\n|cFF88FF88Enabled:|r 2  |  |cFFFF6666Disabled:|r 0\n",
                    },
                    addBindName = {
                        order = 12,
                        type = "input",
                        name = "Bind Name",
                        desc = "Enter the name for the new bind",
                        width = 0.8,
                        get = function() return KOL.Binds.newBindName_general or "" end,
                        set = function(info, value)
                            KOL.Binds.newBindName_general = value
                        end,
                    },
                    addBindSep1 = {
                        order = 13,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    addBindGroup = {
                        order = 14,
                        type = "select",
                        name = "Bind Group",
                        desc = "Choose which group to add this bind to",
                        width = 0.8,
                        values = function()
                            return {
                                general = "General",
                                combat = "Combat",
                                social = "Social",
                                utility = "Utility",
                            }
                        end,
                        get = function() return KOL.Binds.newBindGroup_general or "general" end,
                        set = function(info, value)
                            KOL.Binds.newBindGroup_general = value
                        end,
                    },
                    addBindSep2 = {
                        order = 15,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    addBindButton = {
                        order = 16,
                        type = "execute",
                        name = "Add Bind",
                        desc = "Add a new bind to this group",
                        width = 0.5,
                        func = function()
                            local bindName = KOL.Binds.newBindName_general or ""
                            if bindName == "" then
                                print("|cFFFF6666Error:|r Please enter a bind name")
                                return
                            end

                            local targetGroup = KOL.Binds.newBindGroup_general or "general"
                            local groupName = targetGroup:gsub("^%l", string.upper)
                            print("|cFF88FF88Success:|r Added new bind to " .. groupName .. ": " .. bindName)
                            KOL.Binds.newBindName_general = ""
                            KOL.Binds.newBindGroup_general = "general"
                        end,
                    },

                    -- Bind 1: Dismount
                    bind1Header = {
                        order = 20,
                        type = "header",
                        name = "Dismount",
                    },
                    bind1Enable = {
                        order = 21,
                        type = "toggle",
                        name = "Enable",
                        desc = "Enable this bind",
                        width = "full",
                        get = function() return true end,
                        set = function() end,
                    },
                    bind1Key = {
                        order = 22,
                        type = "keybinding",
                        name = "Keybinding",
                        desc = "Click to set keybinding",
                        width = 0.7,
                        get = function() return "F1" end,
                        set = function(info, value) end,
                    },
                    bind1Sep1 = {
                        order = 23,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    bind1Type = {
                        order = 24,
                        type = "select",
                        name = "Type",
                        width = 0.7,
                        values = {internal = "Internal Action", synastria = "Synastria Action", command = "Command Block"},
                        get = function() return "synastria" end,
                        set = function() end,
                    },
                    bind1Sep2 = {
                        order = 25,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    bind1Target = {
                        order = 26,
                        type = "select",
                        name = "Target",
                        desc = "The command/spell/macro to execute",
                        width = 0.7,
                        values = {
                            dismount = "dismount",
                            mount = "mount",
                            fly = "fly",
                            randomMount = "random mount",
                        },
                        get = function() return "dismount" end,
                        set = function() end,
                    },

                    -- Bind 2: Show Gear Stats
                    bind2Header = {
                        order = 30,
                        type = "header",
                        name = "Show Gear Stats",
                    },
                    bind2Enable = {
                        order = 31,
                        type = "toggle",
                        name = "Enable",
                        width = "full",
                        get = function() return true end,
                        set = function() end,
                    },
                    bind2Key = {
                        order = 32,
                        type = "keybinding",
                        name = "Keybinding",
                        desc = "Click to set keybinding",
                        width = 0.7,
                        get = function() return "F2" end,
                        set = function(info, value) end,
                    },
                    bind2Sep1 = {
                        order = 33,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    bind2Type = {
                        order = 34,
                        type = "select",
                        name = "Type",
                        width = 0.7,
                        values = {internal = "Internal Action", synastria = "Synastria Action", command = "Command Block"},
                        get = function() return "synastria" end,
                        set = function() end,
                    },
                    bind2Sep2 = {
                        order = 35,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    bind2Target = {
                        order = 36,
                        type = "select",
                        name = "Target",
                        width = 0.7,
                        values = {
                            gearStats = "gear stats",
                            itemLevel = "item level",
                            durability = "durability",
                        },
                        get = function() return "gearStats" end,
                        set = function() end,
                    },
                }
            },

            -- ================================================================
            -- COMBAT GROUP
            -- ================================================================
            combatGroup = {
                order = 30,
                type = "group",
                name = "|cFFFF6666Combat|r",
                args = {
                    header = {
                        order = 1,
                        type = "header",
                        name = "Combat",
                    },
                    description = {
                        order = 2,
                        type = "description",
                        name = "Combat-related keybinds for dungeons and raids.\n\n|cFF88FF88Enabled:|r 1  |  |cFFFF6666Disabled:|r 1\n",
                    },
                    addBindName = {
                        order = 3,
                        type = "input",
                        name = "Bind Name",
                        desc = "Enter the name for the new bind",
                        width = 0.8,
                        get = function() return KOL.Binds.newBindName_combat or "" end,
                        set = function(info, value)
                            KOL.Binds.newBindName_combat = value
                        end,
                    },
                    addBindSep1 = {
                        order = 4,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    addBindGroup = {
                        order = 5,
                        type = "select",
                        name = "Bind Group",
                        desc = "Choose which group to add this bind to",
                        width = 0.8,
                        values = function()
                            return {
                                general = "General",
                                combat = "Combat",
                                social = "Social",
                                utility = "Utility",
                            }
                        end,
                        get = function() return KOL.Binds.newBindGroup_combat or "combat" end,
                        set = function(info, value)
                            KOL.Binds.newBindGroup_combat = value
                        end,
                    },
                    addBindSep2 = {
                        order = 6,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    addBindButton = {
                        order = 7,
                        type = "execute",
                        name = "Add Bind",
                        desc = "Add a new bind to this group",
                        width = 0.5,
                        func = function()
                            local bindName = KOL.Binds.newBindName_combat or ""
                            if bindName == "" then
                                print("|cFFFF6666Error:|r Please enter a bind name")
                                return
                            end

                            local targetGroup = KOL.Binds.newBindGroup_combat or "combat"
                            local groupName = targetGroup:gsub("^%l", string.upper)
                            print("|cFF88FF88Success:|r Added new bind to " .. groupName .. ": " .. bindName)
                            KOL.Binds.newBindName_combat = ""
                            KOL.Binds.newBindGroup_combat = "combat"
                        end,
                    },

                    -- Bind 1: Open Leaderboard
                    bind1Header = {
                        order = 10,
                        type = "header",
                        name = "Open Leaderboard",
                    },
                    bind1Enable = {
                        order = 11,
                        type = "toggle",
                        name = "Enable",
                        width = "full",
                        get = function() return true end,
                        set = function() end,
                    },
                    bind1Key = {
                        order = 12,
                        type = "keybinding",
                        name = "Keybinding",
                        desc = "Click to set keybinding",
                        width = 0.7,
                        get = function() return "F3" end,
                        set = function(info, value) end,
                    },
                    bind1Sep1 = {
                        order = 13,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    bind1Type = {
                        order = 14,
                        type = "select",
                        name = "Type",
                        width = 0.7,
                        values = {internal = "Internal Action", synastria = "Synastria Action", command = "Command Block"},
                        get = function() return "synastria" end,
                        set = function() end,
                    },
                    bind1Sep2 = {
                        order = 15,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    bind1Target = {
                        order = 16,
                        type = "select",
                        name = "Target",
                        width = 0.7,
                        values = {
                            leaderboard = "leaderboard",
                            dps = "dps meter",
                            threat = "threat meter",
                        },
                        get = function() return "leaderboard" end,
                        set = function() end,
                    },

                    -- Bind 2: Unstuck Me (Disabled)
                    bind2Header = {
                        order = 20,
                        type = "header",
                        name = "Unstuck Me",
                    },
                    bind2Enable = {
                        order = 21,
                        type = "toggle",
                        name = "Enable",
                        width = "full",
                        get = function() return false end,
                        set = function() end,
                    },
                    bind2Key = {
                        order = 22,
                        type = "keybinding",
                        name = "Keybinding",
                        desc = "Click to set keybinding",
                        width = 0.7,
                        get = function() return "F4" end,
                        set = function(info, value) end,
                    },
                    bind2Sep1 = {
                        order = 23,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    bind2Type = {
                        order = 24,
                        type = "select",
                        name = "Type",
                        width = 0.7,
                        values = {internal = "Internal Action", synastria = "Synastria Action", command = "Command Block"},
                        get = function() return "synastria" end,
                        set = function() end,
                    },
                    bind2Sep2 = {
                        order = 25,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    bind2Target = {
                        order = 26,
                        type = "select",
                        name = "Target",
                        width = 0.7,
                        values = {
                            unstuckme = "unstuckme",
                            unstuck = "unstuck",
                            teleport = "teleport home",
                        },
                        get = function() return "unstuckme" end,
                        set = function() end,
                    },
                }
            },

            -- ================================================================
            -- SOCIAL GROUP
            -- ================================================================
            socialGroup = {
                order = 40,
                type = "group",
                name = "|cFF66CCFFSocial|r",
                args = {
                    header = {
                        order = 1,
                        type = "header",
                        name = "Social",
                    },
                    description = {
                        order = 2,
                        type = "description",
                        name = "Social and communication keybinds.\n\n|cFF88FF88Enabled:|r 1  |  |cFFFF6666Disabled:|r 0\n",
                    },
                    addBindName = {
                        order = 3,
                        type = "input",
                        name = "Bind Name",
                        desc = "Enter the name for the new bind",
                        width = 0.8,
                        get = function() return KOL.Binds.newBindName_social or "" end,
                        set = function(info, value)
                            KOL.Binds.newBindName_social = value
                        end,
                    },
                    addBindSep1 = {
                        order = 4,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    addBindGroup = {
                        order = 5,
                        type = "select",
                        name = "Bind Group",
                        desc = "Choose which group to add this bind to",
                        width = 0.8,
                        values = function()
                            return {
                                general = "General",
                                combat = "Combat",
                                social = "Social",
                                utility = "Utility",
                            }
                        end,
                        get = function() return KOL.Binds.newBindGroup_social or "social" end,
                        set = function(info, value)
                            KOL.Binds.newBindGroup_social = value
                        end,
                    },
                    addBindSep2 = {
                        order = 6,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    addBindButton = {
                        order = 7,
                        type = "execute",
                        name = "Add Bind",
                        desc = "Add a new bind to this group",
                        width = 0.5,
                        func = function()
                            local bindName = KOL.Binds.newBindName_social or ""
                            if bindName == "" then
                                print("|cFFFF6666Error:|r Please enter a bind name")
                                return
                            end

                            local targetGroup = KOL.Binds.newBindGroup_social or "social"
                            local groupName = targetGroup:gsub("^%l", string.upper)
                            print("|cFF88FF88Success:|r Added new bind to " .. groupName .. ": " .. bindName)
                            KOL.Binds.newBindName_social = ""
                            KOL.Binds.newBindGroup_social = "social"
                        end,
                    },

                    -- Bind 1: Find NPC
                    bind1Header = {
                        order = 10,
                        type = "header",
                        name = "Find NPC",
                    },
                    bind1Enable = {
                        order = 11,
                        type = "toggle",
                        name = "Enable",
                        width = "full",
                        get = function() return true end,
                        set = function() end,
                    },
                    bind1Key = {
                        order = 12,
                        type = "keybinding",
                        name = "Keybinding",
                        desc = "Click to set keybinding",
                        width = 0.7,
                        get = function() return "F5" end,
                        set = function(info, value) end,
                    },
                    bind1Sep1 = {
                        order = 13,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    bind1Type = {
                        order = 14,
                        type = "select",
                        name = "Type",
                        width = 0.7,
                        values = {internal = "Internal Action", synastria = "Synastria Action", command = "Command Block"},
                        get = function() return "synastria" end,
                        set = function() end,
                    },
                    bind1Sep2 = {
                        order = 15,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    bind1Target = {
                        order = 16,
                        type = "select",
                        name = "Target",
                        width = 0.7,
                        values = {
                            findnpc = "findnpc",
                            findobj = "find object",
                            findquest = "find quest",
                        },
                        get = function() return "findnpc" end,
                        set = function() end,
                    },
                }
            },

            -- ================================================================
            -- UTILITY GROUP
            -- ================================================================
            utilityGroup = {
                order = 50,
                type = "group",
                name = "|cFF66FF66Utility|r",
                args = {
                    header = {
                        order = 1,
                        type = "header",
                        name = "Utility",
                    },
                    description = {
                        order = 2,
                        type = "description",
                        name = "Utility and quality of life keybinds.\n\n|cFF88FF88Enabled:|r 2  |  |cFFFF6666Disabled:|r 0\n",
                    },
                    addBindName = {
                        order = 3,
                        type = "input",
                        name = "Bind Name",
                        desc = "Enter the name for the new bind",
                        width = 0.8,
                        get = function() return KOL.Binds.newBindName_utility or "" end,
                        set = function(info, value)
                            KOL.Binds.newBindName_utility = value
                        end,
                    },
                    addBindSep1 = {
                        order = 4,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    addBindGroup = {
                        order = 5,
                        type = "select",
                        name = "Bind Group",
                        desc = "Choose which group to add this bind to",
                        width = 0.8,
                        values = function()
                            return {
                                general = "General",
                                combat = "Combat",
                                social = "Social",
                                utility = "Utility",
                            }
                        end,
                        get = function() return KOL.Binds.newBindGroup_utility or "utility" end,
                        set = function(info, value)
                            KOL.Binds.newBindGroup_utility = value
                        end,
                    },
                    addBindSep2 = {
                        order = 6,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    addBindButton = {
                        order = 7,
                        type = "execute",
                        name = "Add Bind",
                        desc = "Add a new bind to this group",
                        width = 0.5,
                        func = function()
                            local bindName = KOL.Binds.newBindName_utility or ""
                            if bindName == "" then
                                print("|cFFFF6666Error:|r Please enter a bind name")
                                return
                            end

                            local targetGroup = KOL.Binds.newBindGroup_utility or "utility"
                            local groupName = targetGroup:gsub("^%l", string.upper)
                            print("|cFF88FF88Success:|r Added new bind to " .. groupName .. ": " .. bindName)
                            KOL.Binds.newBindName_utility = ""
                            KOL.Binds.newBindGroup_utility = "utility"
                        end,
                    },

                    -- Placeholder binds
                    bind1Header = {
                        order = 10,
                        type = "header",
                        name = "Utility Bind 1",
                    },
                    bind1Enable = {
                        order = 11,
                        type = "toggle",
                        name = "Enable",
                        width = "full",
                        get = function() return true end,
                        set = function() end,
                    },
                    bind1Key = {
                        order = 12,
                        type = "keybinding",
                        name = "Keybinding",
                        desc = "Click to set keybinding",
                        width = 0.7,
                        get = function() return "F6" end,
                        set = function(info, value) end,
                    },
                    bind1Sep1 = {
                        order = 13,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    bind1Type = {
                        order = 14,
                        type = "select",
                        name = "Type",
                        width = 0.7,
                        values = {internal = "Internal Action", synastria = "Synastria Action", command = "Command Block"},
                        get = function() return "command" end,
                        set = function() end,
                    },
                    bind1Sep2 = {
                        order = 15,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    bind1Target = {
                        order = 16,
                        type = "select",
                        name = "Target",
                        width = 0.7,
                        values = {
                            util1 = "utility macro 1",
                            util2 = "utility macro 2",
                        },
                        get = function() return "util1" end,
                        set = function() end,
                    },

                    bind2Header = {
                        order = 20,
                        type = "header",
                        name = "Utility Bind 2",
                    },
                    bind2Enable = {
                        order = 21,
                        type = "toggle",
                        name = "Enable",
                        width = "full",
                        get = function() return true end,
                        set = function() end,
                    },
                    bind2Key = {
                        order = 22,
                        type = "keybinding",
                        name = "Keybinding",
                        desc = "Click to set keybinding",
                        width = 0.7,
                        get = function() return "F7" end,
                        set = function(info, value) end,
                    },
                    bind2Sep1 = {
                        order = 23,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    bind2Type = {
                        order = 24,
                        type = "select",
                        name = "Type",
                        width = 0.7,
                        values = {internal = "Internal Action", synastria = "Synastria Action", command = "Command Block"},
                        get = function() return "internal" end,
                        set = function() end,
                    },
                    bind2Sep2 = {
                        order = 25,
                        type = "description",
                        name = ">",
                        width = 0.05,
                    },
                    bind2Target = {
                        order = 26,
                        type = "select",
                        name = "Target",
                        width = 0.7,
                        values = {
                            hearthstone = "Hearthstone",
                            teleport = "Teleport",
                        },
                        get = function() return "hearthstone" end,
                        set = function() end,
                    },
                }
            },
        }
    }

    -- Only add tab if devMode is enabled (hidden in production)
    if KOL.db and KOL.db.profile and KOL.db.profile.devMode then
        KOL.configOptions.args.bindsMockup = KOL.configGroups.bindsMockup
        KOL:DebugPrint("Binds Mockup: Registered ElvUI-style tree layout (devMode)", 3)
    else
        KOL:DebugPrint("Binds Mockup: Skipped (devMode disabled)", 3)
    end
end

-- Register initialization callback
KOL.InitializeBindsMockupUI = function()
    KOL.Binds:InitializeMockupUI()
end
