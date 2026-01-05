local KOL = KoalityOfLife

KOL.Binds = KOL.Binds or {}

local function GetGroupBindCounts(groupId)
    local enabled, disabled = 0, 0
    for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
        if bind.group == groupId then
            if bind.enabled then
                enabled = enabled + 1
            else
                disabled = disabled + 1
            end
        end
    end
    return enabled, disabled
end

local function GetAllGroupValues()
    local values = {}
    for groupId, group in pairs(KOL.db.profile.binds.groups) do
        values[groupId] = group.name
    end
    return values
end

local function GenerateBindUI(bindId, bind, orderStart)
    local args = {}

    args[bindId .. "_header"] = {
        order = orderStart,
        type = "header",
        name = bind.name,
    }

    args[bindId .. "_enable"] = {
        order = orderStart + 1,
        type = "toggle",
        name = "Enable",
        desc = "Enable or disable this keybinding",
        width = "full",
        get = function() return bind.enabled end,
        set = function(_, value)
            bind.enabled = value
            if value then
                if bind.key and bind.key ~= "" then
                    KOL.Binds:ApplyKeybinding(bindId, bind.key)
                end
            else
                KOL.Binds:RemoveKeybinding(bindId)
            end
        end,
    }

    args[bindId .. "_key"] = {
        order = orderStart + 2,
        type = "keybinding",
        name = "Keybinding",
        desc = "Click to set keybinding",
        width = 0.7,
        get = function() return bind.key or "" end,
        set = function(_, value)
            KOL.Binds:ApplyKeybinding(bindId, value)
        end,
    }

    args[bindId .. "_sep1"] = {
        order = orderStart + 3,
        type = "description",
        name = ">",
        width = 0.05,
    }

    args[bindId .. "_type"] = {
        order = orderStart + 4,
        type = "select",
        name = "Type",
        desc = "Action type",
        width = 0.7,
        values = {
            internal = "Internal Action",
            synastria = "Synastria Command",
            commandblock = "Command Block"
        },
        get = function() return bind.type end,
        set = function(_, value)
            bind.type = value
        end,
    }

    args[bindId .. "_sep2"] = {
        order = orderStart + 5,
        type = "description",
        name = ">",
        width = 0.05,
    }

    args[bindId .. "_target"] = {
        order = orderStart + 6,
        type = "input",
        name = "Target",
        desc = "Command/action to execute",
        width = 0.7,
        get = function() return bind.target or "" end,
        set = function(_, value)
            bind.target = value
        end,
    }

    args[bindId .. "_sep3"] = {
        order = orderStart + 7,
        type = "description",
        name = ">",
        width = 0.05,
    }

    args[bindId .. "_delete"] = {
        order = orderStart + 8,
        type = "execute",
        name = "|cFFFF6666Delete|r",
        desc = "Delete this keybinding",
        width = 0.5,
        confirm = true,
        confirmText = "Delete this keybinding?",
        func = function()
            KOL.Binds:DeleteKeybinding(bindId)
            LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
        end,
    }

    return args
end

local function GenerateGroupBindsUI(groupId, startOrder)
    local args = {}
    local order = startOrder

    for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
        if bind.group == groupId then
            local bindArgs = GenerateBindUI(bindId, bind, order)
            for k, v in pairs(bindArgs) do
                args[k] = v
            end
            order = order + 10
        end
    end

    return args
end

local function GenerateStandardGroup(groupId, groupName, groupColor, groupDesc)
    return {
        type = "group",
        name = groupColor .. groupName .. "|r",
        args = {
            header = {
                order = 1,
                type = "header",
                name = groupName,
            },
            description = {
                order = 2,
                type = "description",
                name = function()
                    local enabled, disabled = GetGroupBindCounts(groupId)
                    return (groupDesc or "") .. "\n\n|cFF88FF88Enabled:|r " .. enabled .. "  |  |cFFFF6666Disabled:|r " .. disabled .. "\n"
                end,
            },
            addBindName = {
                order = 3,
                type = "input",
                name = "Bind Name",
                desc = "Enter the name for the new bind",
                width = 0.8,
                get = function() return KOL.Binds["newBindName_" .. groupId] or "" end,
                set = function(_, value)
                    KOL.Binds["newBindName_" .. groupId] = value
                end,
            },
            addBindSep1 = {
                order = 4,
                type = "description",
                name = ">",
                width = 0.05,
            },
            addBindType = {
                order = 5,
                type = "select",
                name = "Type",
                desc = "Action type for new bind",
                width = 0.8,
                values = {
                    internal = "Internal Action",
                    synastria = "Synastria Command",
                    commandblock = "Command Block"
                },
                get = function() return KOL.Binds["newBindType_" .. groupId] or "synastria" end,
                set = function(_, value)
                    KOL.Binds["newBindType_" .. groupId] = value
                end,
            },
            addBindSep2 = {
                order = 6,
                type = "description",
                name = ">",
                width = 0.05,
            },
            addBindTarget = {
                order = 7,
                type = "input",
                name = "Target",
                desc = "Command/action target",
                width = 0.8,
                get = function() return KOL.Binds["newBindTarget_" .. groupId] or "" end,
                set = function(_, value)
                    KOL.Binds["newBindTarget_" .. groupId] = value
                end,
            },
            addBindSep3 = {
                order = 8,
                type = "description",
                name = ">",
                width = 0.05,
            },
            addBindButton = {
                order = 9,
                type = "execute",
                name = "Add Bind",
                desc = "Create new keybinding",
                width = 0.5,
                func = function()
                    local bindName = KOL.Binds["newBindName_" .. groupId] or ""
                    local bindType = KOL.Binds["newBindType_" .. groupId] or "synastria"
                    local bindTarget = KOL.Binds["newBindTarget_" .. groupId] or ""

                    if bindName == "" then
                        KOL:PrintTag(RED("Error:") .. " Please enter a bind name")
                        return
                    end

                    if bindTarget == "" then
                        KOL:PrintTag(RED("Error:") .. " Please enter a target")
                        return
                    end

                    local bindId = bindName:lower():gsub("%s+", "_"):gsub("[^%w_]", "")

                    if KOL.Binds:CreateKeybinding(bindId, {
                        name = bindName,
                        type = bindType,
                        target = bindTarget,
                        group = groupId,
                        enabled = true,
                    }) then
                        KOL:PrintTag(GREEN("Created keybinding: ") .. COLOR("PASTEL_YELLOW", bindName))
                        KOL.Binds["newBindName_" .. groupId] = ""
                        KOL.Binds["newBindTarget_" .. groupId] = ""
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                    end
                end,
            },
            spacer1 = {
                order = 10,
                type = "description",
                name = "\n",
            },
        }
    }
end

function KOL.Binds:InitializeUI()
    if not KOL.configOptions then
        KOL:DebugPrint("Binds UI: Waiting for main UI to initialize...")
        return
    end

    if not (KOL.db and KOL.db.profile and KOL.db.profile.devMode) then
        KOL:DebugPrint("Binds UI: Skipped (devMode disabled)")
        return
    end

    KOL.configOptions.args.binds = {
        type = "group",
        name = "|cFF66FFBBBinds|r",
        order = 7,
        childGroups = "tree",
        args = {
            header = {
                order = 1,
                type = "description",
                name = "|cFF66FFBBKeybinding Management System|r\n|cFFAAAA00Click groups on the left to manage keybindings.|r\n\n",
                fontSize = "medium",
            },

            addGroupName = {
                order = 2,
                type = "input",
                name = "Group Name",
                desc = "Enter name for new bind group",
                width = 0.75,
                get = function() return KOL.Binds.newGroupName or "" end,
                set = function(_, value)
                    KOL.Binds.newGroupName = value
                end,
            },
            addGroupSep = {
                order = 3,
                type = "description",
                name = ">",
                width = 0.05,
            },
            addGroupColor = {
                order = 4,
                type = "select",
                name = "Color",
                desc = "Color for the new group",
                width = 0.75,
                values = {
                    ["PASTEL_YELLOW"] = "Pastel Yellow",
                    ["PASTEL_PINK"] = "Pastel Pink",
                    ["NUCLEAR_GREEN"] = "Nuclear Green",
                    ["NUCLEAR_BLUE"] = "Nuclear Blue",
                    ["NUCLEAR_RED"] = "Nuclear Red",
                    ["NUCLEAR_ORANGE"] = "Nuclear Orange",
                },
                get = function() return KOL.Binds.newGroupColor or "PASTEL_YELLOW" end,
                set = function(_, value)
                    KOL.Binds.newGroupColor = value
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
                name = "Add Group",
                desc = "Create new bind group",
                width = 0.65,
                func = function()
                    local groupName = KOL.Binds.newGroupName or ""
                    local groupColor = KOL.Binds.newGroupColor or "PASTEL_YELLOW"

                    if groupName == "" then
                        KOL:PrintTag(RED("Error:") .. " Please enter a group name")
                        return
                    end

                    local groupId = groupName:lower():gsub("%s+", "_"):gsub("[^%w_]", "")

                    if KOL.db.profile.binds.groups[groupId] then
                        KOL:PrintTag(RED("Error:") .. " Group already exists")
                        return
                    end

                    KOL.db.profile.binds.groups[groupId] = {
                        name = groupName,
                        color = groupColor,
                        isSystem = false
                    }

                    KOL:PrintTag(GREEN("Created group: ") .. COLOR("PASTEL_YELLOW", groupName))

                    KOL.Binds.newGroupName = ""
                    KOL.Binds.newGroupColor = "PASTEL_YELLOW"

                    LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                end,
            },

            generalGroup = {
                order = 20,
                type = "group",
                name = "|cFFFFFF99General|r",
                args = {
                    configHeader = {
                        order = 1,
                        type = "header",
                        name = "Configuration Options",
                    },
                    enableBinds = {
                        order = 2,
                        type = "toggle",
                        name = "Enable Binds System",
                        desc = "Master toggle for keybinding system",
                        width = "normal",
                        get = function() return KOL.db.profile.binds.enabled end,
                        set = function(_, value)
                            KOL.db.profile.binds.enabled = value
                            KOL:PrintTag("Binds system: " .. (value and GREEN("Enabled") or RED("Disabled")))
                        end,
                    },
                    showInCombat = {
                        order = 3,
                        type = "toggle",
                        name = "Allow In Combat",
                        desc = "Allow keybindings during combat",
                        width = "normal",
                        get = function() return KOL.db.profile.binds.showInCombat end,
                        set = function(_, value)
                            KOL.db.profile.binds.showInCombat = value
                        end,
                    },
                    rememberInputs = {
                        order = 4,
                        type = "toggle",
                        name = "Remember Inputs",
                        desc = "Remember last input per bind per character",
                        width = "normal",
                        get = function() return KOL.db.profile.binds.settings.rememberInputs end,
                        set = function(_, value)
                            KOL.db.profile.binds.settings.rememberInputs = value
                        end,
                    },
                    showNotifications = {
                        order = 5,
                        type = "toggle",
                        name = "Show Notifications",
                        desc = "Show notifications when binds trigger",
                        width = "normal",
                        get = function() return KOL.db.profile.binds.settings.showNotifications end,
                        set = function(_, value)
                            KOL.db.profile.binds.settings.showNotifications = value
                        end,
                    },

                    spacer1 = {
                        order = 9,
                        type = "description",
                        name = "\n",
                    },

                    header = {
                        order = 10,
                        type = "header",
                        name = "General Keybindings",
                    },
                    description = {
                        order = 11,
                        type = "description",
                        name = function()
                            local enabled, disabled = GetGroupBindCounts("general")
                            return "Default keybindings.\n\n|cFF88FF88Enabled:|r " .. enabled .. "  |  |cFFFF6666Disabled:|r " .. disabled .. "\n"
                        end,
                    },
                    addBindName = {
                        order = 12,
                        type = "input",
                        name = "Bind Name",
                        width = 0.8,
                        get = function() return KOL.Binds.newBindName_general or "" end,
                        set = function(_, value) KOL.Binds.newBindName_general = value end,
                    },
                    addBindSep1 = { order = 13, type = "description", name = ">", width = 0.05 },
                    addBindType = {
                        order = 14,
                        type = "select",
                        name = "Type",
                        width = 0.8,
                        values = { internal = "Internal", synastria = "Synastria", commandblock = "Command Block" },
                        get = function() return KOL.Binds.newBindType_general or "synastria" end,
                        set = function(_, value) KOL.Binds.newBindType_general = value end,
                    },
                    addBindSep2 = { order = 15, type = "description", name = ">", width = 0.05 },
                    addBindTarget = {
                        order = 16,
                        type = "input",
                        name = "Target",
                        width = 0.8,
                        get = function() return KOL.Binds.newBindTarget_general or "" end,
                        set = function(_, value) KOL.Binds.newBindTarget_general = value end,
                    },
                    addBindSep3 = { order = 17, type = "description", name = ">", width = 0.05 },
                    addBindButton = {
                        order = 18,
                        type = "execute",
                        name = "Add Bind",
                        width = 0.5,
                        func = function()
                            local name = KOL.Binds.newBindName_general or ""
                            local bindType = KOL.Binds.newBindType_general or "synastria"
                            local target = KOL.Binds.newBindTarget_general or ""

                            if name == "" or target == "" then
                                KOL:PrintTag(RED("Error:") .. " Name and target required")
                                return
                            end

                            local bindId = name:lower():gsub("%s+", "_"):gsub("[^%w_]", "")
                            if KOL.Binds:CreateKeybinding(bindId, {
                                name = name,
                                type = bindType,
                                target = target,
                                group = "general",
                                enabled = true,
                            }) then
                                KOL:PrintTag(GREEN("Created: ") .. COLOR("PASTEL_YELLOW", name))
                                KOL.Binds.newBindName_general = ""
                                KOL.Binds.newBindTarget_general = ""
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                            end
                        end,
                    },
                    spacer2 = {
                        order = 19,
                        type = "description",
                        name = "\n",
                    },
                }
            },
        }
    }

    local groupOrders = {
        configs = 19,
        general = 20,
        combat = 30,
        social = 40,
        utility = 50,
    }

    local groupColors = {
        configs = "|cFFAAAAAA",
        general = "|cFFFFFF99",
        combat = "|cFFFF6666",
        social = "|cFF66CCFF",
        utility = "|cFF66FF66",
    }

    local groupDescs = {
        configs = "Configuration bindings.",
        combat = "Combat-related keybindings for dungeons and raids.",
        social = "Social and communication keybindings.",
        utility = "Utility and quality of life keybindings.",
    }

    for groupId, groupData in pairs(KOL.db.profile.binds.groups) do
        if groupId ~= "general" then
            local order = groupOrders[groupId] or 60
            local color = groupColors[groupId] or "|cFFFFAA00"
            local desc = groupDescs[groupId] or ""

            KOL.configOptions.args.binds.args[groupId .. "Group"] = GenerateStandardGroup(
                groupId,
                groupData.name,
                color,
                desc
            )

            local bindArgs = GenerateGroupBindsUI(groupId, 20)
            for k, v in pairs(bindArgs) do
                KOL.configOptions.args.binds.args[groupId .. "Group"].args[k] = v
            end

            if not groupData.isSystem then
                KOL.configOptions.args.binds.args[groupId .. "Group"].args.deleteGroup = {
                    order = 2.5,
                    type = "execute",
                    name = "|cFFFF6666Delete This Group|r",
                    desc = "Hold CTRL+SHIFT to delete",
                    width = "full",
                    confirm = true,
                    confirmText = "Delete this group? Cannot be undone.",
                    func = function()
                        if not (IsControlKeyDown() and IsShiftKeyDown()) then
                            KOL:PrintTag(RED("Error:") .. " Hold CTRL+SHIFT to delete")
                            return
                        end

                        for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
                            if bind.group == groupId then
                                KOL.Binds:DeleteKeybinding(bindId)
                            end
                        end

                        KOL.db.profile.binds.groups[groupId] = nil
                        KOL:PrintTag(GREEN("Deleted group: ") .. groupData.name)
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                    end,
                }
            end
        end
    end

    local generalBindArgs = GenerateGroupBindsUI("general", 20)
    for k, v in pairs(generalBindArgs) do
        KOL.configOptions.args.binds.args.generalGroup.args[k] = v
    end

    KOL.configOptions.args.binds.args.profilesGroup = {
        order = 70,
        type = "group",
        name = "|cFFFF88FFProfile Manager|r",
        args = {
            header = {
                order = 1,
                type = "header",
                name = "Profile Management",
            },
            description = {
                order = 2,
                type = "description",
                name = "Manage keybinding profiles.\n\n",
            },
            currentProfile = {
                order = 3,
                type = "description",
                name = function()
                    return "|cFFAAAAFFCurrent Profile:|r " .. COLOR("PASTEL_YELLOW", KOL.Binds.activeProfile or "default") .. "\n\n"
                end,
                fontSize = "medium",
            },
            listProfiles = {
                order = 4,
                type = "description",
                name = function()
                    local text = "|cFFDDDDDDAvailable Profiles:|r\n"
                    for profileId, profile in pairs(KOL.db.profile.binds.profiles) do
                        local isCurrent = (profileId == (KOL.Binds.activeProfile or "default"))
                        local status = isCurrent and COLOR("GREEN", " [ACTIVE]") or ""
                        local bindCount = 0
                        if profile.keybindings then
                            for _ in pairs(profile.keybindings) do bindCount = bindCount + 1 end
                        end
                        text = text .. "  * " .. COLOR("PASTEL_YELLOW", profile.name) .. status .. " (" .. bindCount .. " binds)\n"
                    end
                    return text
                end,
                fontSize = "small",
            },
            spacer1 = {
                order = 10,
                type = "description",
                name = "\n",
            },
            createProfileName = {
                order = 11,
                type = "input",
                name = "New Profile Name",
                desc = "Name for new profile",
                width = 0.8,
                get = function() return KOL.Binds.newProfileName or "" end,
                set = function(_, value) KOL.Binds.newProfileName = value end,
            },
            createProfileSep = {
                order = 12,
                type = "description",
                name = ">",
                width = 0.05,
            },
            createProfileButton = {
                order = 13,
                type = "execute",
                name = "Create Profile",
                desc = "Create new profile",
                width = 0.5,
                func = function()
                    local name = KOL.Binds.newProfileName or ""
                    if name == "" then
                        KOL:PrintTag(RED("Error:") .. " Enter profile name")
                        return
                    end
                    KOL.Binds:CreateProfile(name)
                    KOL.Binds.newProfileName = ""
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                end,
            },
            spacer2 = {
                order = 20,
                type = "description",
                name = "\n",
            },
            switchProfile = {
                order = 21,
                type = "select",
                name = "Switch Profile",
                desc = "Change active profile",
                width = 0.8,
                values = function()
                    local vals = {}
                    for profileId, profile in pairs(KOL.db.profile.binds.profiles) do
                        vals[profileId] = profile.name
                    end
                    return vals
                end,
                get = function() return KOL.Binds.activeProfile or "default" end,
                set = function(_, value)
                    KOL.Binds:SwitchProfile(value)
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                end,
            },
            exportProfile = {
                order = 30,
                type = "execute",
                name = "Export Current Profile",
                desc = "Export profile to string",
                width = "normal",
                func = function()
                    KOL.Binds:ExportProfile(KOL.Binds.activeProfile or "default")
                end,
            },
            importProfile = {
                order = 31,
                type = "execute",
                name = "Import Profile",
                desc = "Import profile from string",
                width = "normal",
                func = function()
                    KOL.Binds:ImportProfile()
                end,
            },
        }
    }

    KOL:DebugPrint("Binds UI: Registered tree layout with " .. tostring(KOL.configOptions.args.binds and "success" or "failure"))
end

KOL.InitializeBindsUI = function()
    KOL.Binds:InitializeUI()
end
