-- !Koality-of-Life: UI and Configuration System
-- Professional configuration interface using AceConfig-3.0

local addonName = "!Koality-of-Life"
local KOL = KoalityOfLife
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

-- Store module config groups
KOL.configGroups = {}

-- Rainbow color sequence for titles
local rainbowColors = {
    "FF0000", "FF4400", "FF8800", "FFCC00", "FFFF00", "CCFF00",
    "88FF00", "44FF00", "00FF00", "00FF88", "00FFFF", "55AAFF",
    "7799FF", "8888FF", "AA66FF"
}

-- ============================================================================
-- Rainbow Text Helper
-- ============================================================================

local function RainbowText(text)
    local result = ""
    local colorIndex = 1
    
    for i = 1, #text do
        local char = text:sub(i, i)
        result = result .. "|cFF" .. rainbowColors[colorIndex] .. char
        colorIndex = colorIndex + 1
        if colorIndex > #rainbowColors then
            colorIndex = 1
        end
    end
    
    return result .. "|r"
end

-- ============================================================================
-- Raid Size/Difficulty Helper Functions
-- ============================================================================

-- Get raid size from expansion, difficulty, and name
local function GetRaidSize(expansion, difficulty, name)
    if expansion == "classic" then
        -- Classic: 20-man (ZG, AQ20) vs 40-man (MC, BWL, AQ40)
        if name and (name:find("Zul'Gurub") or name:find("Ruins")) then
            return 20
        else
            return 40
        end
    elseif expansion == "tbc" then
        -- TBC: difficulty 1 = 10-man, difficulty 2 = 25-man
        return difficulty == 1 and 10 or 25
    elseif expansion == "wotlk" then
        -- WotLK: difficulty 1/3 = 10-man, difficulty 2/4 = 25-man
        return (difficulty == 1 or difficulty == 3) and 10 or 25
    end
    return 10  -- default
end

-- Check if raid is heroic mode
local function IsHeroicRaid(expansion, difficulty)
    -- Only WotLK has heroic raids (difficulty 3 = 10H, difficulty 4 = 25H)
    if expansion == "wotlk" then
        return difficulty == 3 or difficulty == 4
    end
    return false
end

-- Get unified difficulty code (e.g., "10n", "25h")
local function GetUnifiedDifficultyCode(expansion, difficulty, name)
    local size = GetRaidSize(expansion, difficulty, name)
    local isHeroic = IsHeroicRaid(expansion, difficulty)
    return size .. (isHeroic and "h" or "n")
end

-- Get display name for unified difficulty code
local function GetDifficultyDisplayName(code, colored)
    local displays = {
        ["10n"] = colored and "|cFF66FF66" .. string.char(149) .. " 10N|r" or "10N",
        ["10h"] = colored and "|cFFFF6666" .. string.char(149) .. " 10H|r" or "10H",
        ["20n"] = colored and "|cFF66FF66" .. string.char(149) .. " 20N|r" or "20N",
        ["25n"] = colored and "|cFF66FF66" .. string.char(149) .. " 25N|r" or "25N",
        ["25h"] = colored and "|cFFFF6666" .. string.char(149) .. " 25H|r" or "25H",
        ["40n"] = colored and "|cFF66FF66" .. string.char(149) .. " 40N|r" or "40N",
    }
    return displays[code] or code
end

-- ============================================================================
-- Initialize UI System
-- ============================================================================

function KOL:InitializeUI()
    -- Create main options table
    local options = {
        name = RainbowText("Koality of Life"),
        type = "group",
        args = {
            header = {
                type = "description",
                name = RainbowText("Koality of Life") .. " |cFFFFFFFFv" .. self.version .. "|r\n|cFFAAAAAAQuality of life improvements for Synastria|r\n",
                fontSize = "medium",
                order = 0,
            },
            general = {
                type = "group",
                name = "|cFFFFDD00General|r",
                order = 1,
                childGroups = "tab",
                args = {
                    main = {
                        type = "group",
                        name = "|cFFFFDD00Main|r",
                        order = 1,
                        args = {
                            enabled = {
                        type = "toggle",
                        name = "Enable Addon",
                        desc = "Enable or disable Koality of Life",
                        get = function() return self.db.profile.enabled end,
                        set = function(_, value) self.db.profile.enabled = value end,
                        width = "full",
                        order = 1,
                    },
                    showSplash = {
                        type = "toggle",
                        name = "Show Splash Screen",
                        desc = "Show the Koality of Life splash image on login",
                        get = function() return self.db.profile.showSplash end,
                        set = function(_, value) self.db.profile.showSplash = value end,
                        width = "full",
                        order = 1.5,
                    },
                    spacer1 = {
                        type = "description",
                        name = " ",
                        order = 2,
                    },
                    fontHeader = {
                        type = "header",
                        name = "General UI Fonts",
                        order = 3,
                    },
                    generalFont = {
                        type = "select",
                        name = "Font",
                        desc = "Font used for custom UI elements (like Batch Queue Viewer and Debug Console)",
                        dialogControl = "LSM30_Font",
                        values = LibStub("LibSharedMedia-3.0"):HashTable("font"),
                        order = 4,
                        get = function() return self.db.profile.generalFont or "Friz Quadrata TT" end,
                        set = function(_, value)
                            self.db.profile.generalFont = value
                            self:PrintTag("General font set to: " .. PASTEL_YELLOW(value))
                        end,
                    },
                    generalFontOutline = {
                        type = "select",
                        name = "Font Outline",
                        desc = "Outline style for general UI fonts",
                        values = {
                            ["NONE"] = "None",
                            ["OUTLINE"] = "Outline",
                            ["THICKOUTLINE"] = "Thick Outline",
                            ["MONOCHROME"] = "Monochrome",
                            ["OUTLINE, MONOCHROME"] = "Outline + Monochrome",
                            ["THICKOUTLINE, MONOCHROME"] = "Thick Outline + Monochrome",
                        },
                        order = 5,
                        get = function() return self.db.profile.generalFontOutline or "THICKOUTLINE" end,
                        set = function(_, value)
                            self.db.profile.generalFontOutline = value
                            self:PrintTag("General font outline set to: " .. PASTEL_YELLOW(value))
                        end,
                    },
                    spacer2 = {
                        type = "description",
                        name = " ",
                        order = 10,
                    },
                    statsHeader = {
                        type = "header",
                        name = "Performance Stats",
                        order = 11,
                    },
                    statsDesc = {
                        type = "description",
                        name = "|cFFAAAAAALive performance metrics for Koality of Life|r",
                        fontSize = "small",
                        order = 12,
                    },
                    stats = {
                        type = "description",
                        name = function()
                            -- Use cached stats to avoid memory churn on every UI refresh
                            -- Stats are updated by the Refresh button or periodically
                            if not KOL.cachedStats then
                                KOL.cachedStats = {
                                    text = "|cFFFFDD00Memory Usage:|r |cFF888888Loading...|r",
                                    lastUpdate = 0,
                                    lastFreed = nil,  -- Set by Refresh Stats button
                                }
                            end

                            -- Only update stats every 2 seconds to reduce memory allocations
                            local now = GetTime()
                            if now - KOL.cachedStats.lastUpdate < 2 then
                                return KOL.cachedStats.text
                            end
                            KOL.cachedStats.lastUpdate = now

                            -- Update memory usage (with safety check for API availability)
                            local mem = 0
                            local memMB = 0
                            if UpdateAddOnMemoryUsage and GetAddOnMemoryUsage then
                                UpdateAddOnMemoryUsage()
                                mem = GetAddOnMemoryUsage("!Koality-of-Life") or 0
                                memMB = mem / 1024
                            end

                            -- Count batch channels
                            local totalChannels = 0
                            local runningChannels = 0
                            if KOL.Batch and KOL.Batch.channels then
                                for name, channel in pairs(KOL.Batch.channels) do
                                    totalChannels = totalChannels + 1
                                    if channel.isRunning then
                                        runningChannels = runningChannels + 1
                                    end
                                end
                            end

                            -- Count debug messages
                            local debugCount = 0
                            local debugMax = KOL.db.profile.debugMaxLines or 1000
                            if KOL.DebugGetMessageCount then
                                debugCount = KOL.DebugGetMessageCount()
                            end

                            local memColor = "|cFF88FF88"  -- Green
                            local memText = "N/A"
                            if UpdateAddOnMemoryUsage and GetAddOnMemoryUsage then
                                memText = string.format("%.2f MB", memMB)
                                if memMB > 10 then
                                    memColor = "|cFFFFFF88"  -- Yellow
                                end
                                if memMB > 20 then
                                    memColor = "|cFFFF8888"  -- Red
                                end

                                -- Show how much was freed on last GC (from last Refresh Stats click)
                                if KOL.cachedStats.lastFreed and KOL.cachedStats.lastFreed > 0.01 then
                                    memText = string.format("%.2f MB |cFF888888(|r|cFF88FF88freed %.2f|r on last |cFFFFAA00GC|r|cFF888888)|r", memMB, KOL.cachedStats.lastFreed)
                                end
                            end

                            KOL.cachedStats.text = string.format(
                                "|cFFFFDD00Memory Usage:|r %s%s|r\n" ..
                                "|cFFFFDD00Batch Channels:|r |cFF88DDFF%d running|r / |cFFAAAA00%d total|r\n" ..
                                "|cFFFFDD00Debug Messages:|r |cFFAAAA00%d|r / |cFF888888%d max|r",
                                memColor, memText,
                                runningChannels, totalChannels,
                                debugCount, debugMax
                            )
                            return KOL.cachedStats.text
                        end,
                        fontSize = "medium",
                        order = 13,
                    },
                    refreshNote = {
                        type = "description",
                        name = "Running |cFF88DDFFRefresh Stats|r will |cFFFFAA00Collect Garbage|r before |cFF88DDFFRefreshing Stats|r.",
                        fontSize = "small",
                        order = 13.5,
                    },
                    refreshStats = {
                        type = "execute",
                        name = "Refresh Stats",
                        desc = "Force garbage collection and refresh stats for accurate memory reading",
                        func = function()
                            -- Get memory BEFORE garbage collection
                            local memBefore = 0
                            if UpdateAddOnMemoryUsage and GetAddOnMemoryUsage then
                                UpdateAddOnMemoryUsage()
                                memBefore = GetAddOnMemoryUsage("!Koality-of-Life") or 0
                            end

                            -- Force garbage collection
                            collectgarbage("collect")

                            -- Get memory AFTER garbage collection
                            local memAfter = 0
                            if UpdateAddOnMemoryUsage and GetAddOnMemoryUsage then
                                UpdateAddOnMemoryUsage()
                                memAfter = GetAddOnMemoryUsage("!Koality-of-Life") or 0
                            end

                            -- Calculate how much was freed by GC
                            local freed = (memBefore - memAfter) / 1024  -- Convert to MB

                            -- Store freed amount for display
                            if not KOL.cachedStats then
                                KOL.cachedStats = { lastUpdate = 0 }
                            end
                            KOL.cachedStats.lastFreed = freed > 0 and freed or nil
                            KOL.cachedStats.lastUpdate = 0  -- Force immediate refresh

                            -- Force refresh by notifying AceConfigRegistry
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
                        end,
                        width = "normal",
                        order = 14,
                    },
                        }
                    },
                    debug = {
                type = "group",
                name = "|cFFFF6666Debug|r",
                order = 2,
                args = {
                    header = {
                        type = "description",
                        name = "|cFFFFFFFFDebug System|r\n|cFFAAAAAATools for debugging and troubleshooting the addon.|r\n",
                        fontSize = "medium",
                        order = 0,
                    },
                    enabled = {
                        type = "toggle",
                        name = "Enable Debug Mode",
                        desc = "Enable debug output",
                        get = function() return self.db.profile.debug end,
                        set = function(_, value)
                            self.db.profile.debug = value
                            local status = value and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
                            local level = self.db.profile.debugLevel or 1
                            self:PrintTag("Debug mode " .. status .. " (Level " .. level .. ")")
                        end,
                        width = "full",
                        order = 1,
                    },
                    debugLevel = {
                        type = "select",
                        name = "Debug Level",
                        desc = "Set the verbosity level of debug output\n\nLevel 1: Critical/important info only\nLevel 2: Reserved\nLevel 3: Moderate detail (includes aggressive timers)\nLevel 4: Reserved\nLevel 5: Maximum verbosity (everything)",
                        values = {
                            [1] = "Level 1 - Minimal (Critical only)",
                            [2] = "Level 2 - Reserved",
                            [3] = "Level 3 - Moderate (includes timers)",
                            [4] = "Level 4 - Reserved",
                            [5] = "Level 5 - Maximum (everything)",
                        },
                        get = function() return self.db.profile.debugLevel or 1 end,
                        set = function(_, value)
                            self.db.profile.debugLevel = value
                            if self.db.profile.debug then
                                self:PrintTag("Debug level set to: |cFFFFFF00" .. value .. "|r")
                            else
                                self:PrintTag("Debug level set to: |cFFFFFF00" .. value .. "|r |cFF888888(Debug mode is OFF)|r")
                            end
                        end,
                        width = "full",
                        order = 2,
                    },
                    debugOutputToChat = {
                        type = "toggle",
                        name = "Output Debug to Chat",
                        desc = "When enabled, debug messages appear in chat frame. When disabled, they only go to the Debug Console",
                        get = function() return self.db.profile.debugOutputToChat ~= false end,
                        set = function(_, value)
                            self.db.profile.debugOutputToChat = value
                            local status = value and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
                            self:PrintTag("Debug output to chat " .. status .. " (Debug Console always receives messages)")
                        end,
                        width = "full",
                        order = 3,
                    },
                    spacer1 = {
                        type = "description",
                        name = " ",
                        order = 4,
                    },
                    showDebugButton = {
                        type = "toggle",
                        name = "Show Debug Button",
                        desc = "Show a floating 'D' button near the chat frame that opens the Debug Console when clicked",
                        get = function() return self.db.profile.showDebugButton ~= false end,
                        set = function(_, value)
                            self.db.profile.showDebugButton = value
                            if KOL.UpdateDebugButton then
                                KOL:UpdateDebugButton()
                            end
                            local status = value and "|cFF00FF00shown|r" or "|cFFFF0000hidden|r"
                            self:PrintTag("Debug button " .. status)
                        end,
                        width = "full",
                        order = 5,
                    },
                    spacer2 = {
                        type = "description",
                        name = " ",
                        order = 6,
                    },
                    fontHeader = {
                        type = "header",
                        name = "Debug Console Font",
                        order = 7,
                    },
                    debugFont = {
                        type = "select",
                        name = "Font",
                        desc = "Font used for the Debug Console (monospace recommended for proper alignment)",
                        dialogControl = "LSM30_Font",
                        values = LibStub("LibSharedMedia-3.0"):HashTable("font"),
                        order = 8,
                        get = function() return self.db.profile.debugFont or "JetBrains Mono" end,
                        set = function(_, value)
                            self.db.profile.debugFont = value
                            self:PrintTag("Debug console font set to: " .. PASTEL_YELLOW(value) .. " |cFF888888(close/reopen console to see changes)|r")
                        end,
                    },
                    debugFontOutline = {
                        type = "select",
                        name = "Font Outline",
                        desc = "Outline style for debug console font",
                        values = {
                            ["NONE"] = "None",
                            ["OUTLINE"] = "Outline",
                            ["THICKOUTLINE"] = "Thick Outline",
                            ["MONOCHROME"] = "Monochrome",
                            ["OUTLINE, MONOCHROME"] = "Outline + Monochrome",
                            ["THICKOUTLINE, MONOCHROME"] = "Thick Outline + Monochrome",
                        },
                        order = 9,
                        get = function() return self.db.profile.debugFontOutline or "THICKOUTLINE" end,
                        set = function(_, value)
                            self.db.profile.debugFontOutline = value
                            self:PrintTag("Debug console font outline set to: " .. PASTEL_YELLOW(value) .. " |cFF888888(close/reopen console to see changes)|r")
                        end,
                    },
                    debugMaxLines = {
                        type = "range",
                        name = "Maximum Lines",
                        desc = "Maximum number of lines to keep in the debug console\n\nLower values use less memory and improve performance.\nHigher values keep more history.\n\nRecommended: 1000 (default)\nMaximum: 10000",
                        min = 100,
                        max = 10000,
                        step = 100,
                        order = 9.5,
                        get = function() return self.db.profile.debugMaxLines or 1000 end,
                        set = function(_, value)
                            self.db.profile.debugMaxLines = value
                            self:PrintTag("Debug console max lines set to: " .. PASTEL_YELLOW(value))
                        end,
                    },
                    spacer3 = {
                        type = "description",
                        name = " ",
                        order = 10,
                    },
                    viewConsole = {
                        type = "execute",
                        name = "View Debug Console",
                        desc = "Open the Debug Console window",
                        func = function()
                            KOL:ShowDebugConsole()
                        end,
                        width = "normal",
                        order = 11,
                    },
                },
                    },
                    colors = {
                        type = "group",
                        name = "|cFFFF88CCColors|r",
                        order = 3,
                        args = {
                            header = {
                                type = "description",
                                name = "|cFFFFFFFFColor Library|r\n|cFFAAAAAAView and customize colors used throughout the addon.|r\n",
                                fontSize = "medium",
                                order = 0,
                            },
                            standardHeader = {
                                type = "header",
                                name = "Standard Colors",
                                order = 1,
                            },
                            standardDesc = {
                                type = "description",
                                name = "|cFFAAAAAAAvailable via color functions: RED(), GREEN(), YELLOW(), etc.|r\n",
                                order = 2,
                            },
                            standardColors = {
                                type = "group",
                                name = " ",
                                inline = true,
                                order = 3,
                                args = {},  -- Will be populated dynamically
                            },
                            pastelHeader = {
                                type = "header",
                                name = "Pastel Colors",
                                order = 4,
                            },
                            pastelDesc = {
                                type = "description",
                                name = "|cFFAAAAAAUsed for UI elements, blocks, and tracker frames.|r\n",
                                order = 5,
                            },
                            pastelColors = {
                                type = "group",
                                name = " ",
                                inline = true,
                                order = 6,
                                args = {},  -- Will be populated dynamically
                            },
                            nuclearHeader = {
                                type = "header",
                                name = "Nuclear Colors",
                                order = 7,
                            },
                            nuclearDesc = {
                                type = "description",
                                name = "|cFFAAAAAAVibrant colors for high-contrast UI elements.|r\n",
                                order = 8,
                            },
                            nuclearColors = {
                                type = "group",
                                name = " ",
                                inline = true,
                                order = 9,
                                args = {},  -- Will be populated dynamically
                            },
                            customHeader = {
                                type = "header",
                                name = "Custom Colors",
                                order = 10,
                            },
                            customDesc = {
                                type = "description",
                                name = "|cFFAAAAAACreate your own named colors for use in custom watch frames and other features.|r\n",
                                order = 11,
                            },
                            addCustomColor = {
                                type = "execute",
                                name = "Add Custom Color",
                                desc = "Add a new custom color",
                                func = function()
                                    if KOL.Colors and KOL.Colors.ShowCustomColorDialog then
                                        KOL.Colors:ShowCustomColorDialog()
                                    end
                                end,
                                width = "full",
                                order = 12,
                            },
                            customColors = {
                                type = "group",
                                name = " ",
                                inline = true,
                                order = 13,
                                args = {},  -- Will be populated dynamically
                            },
                            resetHeader = {
                                type = "header",
                                name = "Reset Colors",
                                order = 14,
                            },
                            resetAll = {
                                type = "execute",
                                name = "Reset All Colors to Defaults",
                                desc = "Reset all color customizations back to default values",
                                func = function()
                                    if KOL.Colors then
                                        KOL.Colors:ResetAll()
                                        -- Refresh config
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
                                    end
                                end,
                                width = "full",
                                order = 15,
                                confirm = function()
                                    return "Are you sure you want to reset all colors to defaults? This cannot be undone."
                                end,
                            },
                        }
                    },
                }
            },
            tweaks = {
                type = "group",
                name = "|cFF88DDFFTweaks|r",
                order = 3,
                childGroups = "tab",
                args = {
                    header = {
                        type = "description",
                        name = "|cFFFFFFFFTweaks & Quality of Life Features|r\n|cFFAAAAAAVarious tweaks to improve your gameplay experience.|r\n",
                        fontSize = "medium",
                        order = 0,
                    },
                    vendors = {
                        type = "group",
                        name = "|cFFFFDD00Vendors|r",
                        order = 1,
                        args = {
                            -- This will be populated by CreateBlock function
                        }
                    },
                }
            },
            commandblocks = {
                type = "group",
                name = "|cFFFFAA66Command Blocks|r",
                order = 4,
                args = {
                    header = {
                        type = "description",
                        name = "|cFFFFFFFFCommand Blocks|r\n|cFFAAAAAAReusable Lua code blocks that can be executed by other modules.|r\n",
                        fontSize = "medium",
                        order = 0,
                    },
                    openEditor = {
                        type = "execute",
                        name = "Open Command Block Editor",
                        desc = "Open the Command Block Editor to create, edit, and manage command blocks",
                        func = function()
                            if KOL.CommandBlocks then
                                KOL.CommandBlocks:ShowEditor()
                            end
                        end,
                        width = "full",
                        order = 1,
                    },
                    spacer1 = {
                        type = "description",
                        name = " ",
                        order = 2,
                    },
                    infoHeader = {
                        type = "header",
                        name = "About Command Blocks",
                        order = 3,
                    },
                    info = {
                        type = "description",
                        name = "|cFFAAAAFFCommand Blocks are reusable pieces of Lua code that can be used by multiple systems:\n\n" ..
                              "|cFFFFFFFF• Macro Updater|r - Generate dynamic macro content\n" ..
                              "|cFFFFFFFF• Content Tracker|r - Run custom code when entering dungeons/raids\n" ..
                              "|cFFFFFFFF• Batch System|r - Execute automated tasks\n" ..
                              "|cFFFFFFFF• Custom Systems|r - Any module can execute command blocks\n\n" ..
                              "|cFFFF8888Note:|r Command blocks must return a string value to be used by other systems.|r",
                        fontSize = "medium",
                        order = 4,
                    },
                }
            },
            tracker = {
                type = "group",
                name = "|cFF66FFCCProgress Tracker|r",
                order = 2,
                childGroups = "tab",
                args = {
                    header = {
                        type = "description",
                        name = "|cFFFFFFFFProgress Tracker|r\n|cFFAAAAAATrack dungeon and raid boss kills with auto-showing watch frames.|r\n",
                        fontSize = "medium",
                        order = 0,
                    },
                    general = {
                        type = "group",
                        name = "|cFFFFDD00General|r",
                        order = 1,
                        args = {
                            generalHeader = {
                                type = "header",
                                name = "Watch Frame Settings",
                                order = 1,
                            },
                            autoShow = {
                                type = "toggle",
                                name = "Auto-Show Watch Frames",
                                desc = "Automatically show watch frames when entering tracked zones",
                                get = function()
                                    return KOL.db.profile.tracker and KOL.db.profile.tracker.autoShow ~= false
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.autoShow = value
                                    KOL:PrintTag("Auto-show watch frames: " .. (value and GREEN("Enabled") or RED("Disabled")))
                                end,
                                width = "full",
                                order = 2,
                            },
                            spacerUI1 = {
                                type = "description",
                                name = " ",
                                order = 3,
                            },
                            uiHeader = {
                                type = "header",
                                name = "UI Visibility",
                                order = 4,
                            },
                            showBgOnHover = {
                                type = "toggle",
                                name = "Show Background on Mouseover Only",
                                desc = "Hide the frame background by default, show it only when hovering (creates a floating text look)",
                                get = function()
                                    return KOL.db.profile.tracker and KOL.db.profile.tracker.showBgOnHover or false
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.showBgOnHover = value
                                    -- Also set the old values for compatibility
                                    KOL.db.profile.tracker.hideUI = value
                                    KOL.db.profile.tracker.showUIOnMouseover = value
                                    KOL:PrintTag("Show BG on hover: " .. (value and GREEN("Enabled") or RED("Disabled")))
                                end,
                                width = "full",
                                order = 5,
                            },
                            spacerButtons = {
                                type = "description",
                                name = " ",
                                order = 7,
                            },
                            buttonsHeader = {
                                type = "header",
                                name = "Button Options",
                                order = 8,
                            },
                            showMinimizeButton = {
                                type = "toggle",
                                name = "Show Minimize Button",
                                desc = "Show the minimize/maximize button on watch frames (can still double-click title to minimize)",
                                get = function()
                                    return KOL.db.profile.tracker and KOL.db.profile.tracker.showMinimizeButton ~= false
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.showMinimizeButton = value
                                    KOL:PrintTag("Show minimize button: " .. (value and GREEN("Enabled") or RED("Disabled")))
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, frame in pairs(KOL.Tracker.activeFrames) do
                                            if frame.minimizeBtn then
                                                if value then
                                                    frame.minimizeBtn:Show()
                                                else
                                                    frame.minimizeBtn:Hide()
                                                end
                                            end
                                        end
                                    end
                                end,
                                width = "full",
                                order = 9,
                            },
                            showScrollButtons = {
                                type = "toggle",
                                name = "Show Scroll Arrow Buttons",
                                desc = "Show up/down arrow buttons on scrollbars",
                                get = function()
                                    return KOL.db.profile.tracker and KOL.db.profile.tracker.showScrollButtons ~= false
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.showScrollButtons = value
                                    KOL:PrintTag("Show scroll arrows: " .. (value and GREEN("Enabled") or RED("Disabled")))
                                end,
                                width = "full",
                                order = 10,
                            },
                            spacer0 = {
                                type = "description",
                                name = " ",
                                order = 11,
                            },
                            frameHeader = {
                                type = "header",
                                name = "Frame Control",
                                order = 12,
                            },
                            showScrollBar = {
                                type = "select",
                                name = "Scrollbar Visibility",
                                desc = "Control scrollbar visibility for all watch frames",
                                values = {
                                    [false] = "Hidden",
                                    [true] = "Visible",
                                },
                                get = function()
                                    if KOL.db.profile.tracker and KOL.db.profile.tracker.showScrollBar ~= nil then
                                        return KOL.db.profile.tracker.showScrollBar
                                    end
                                    return false  -- Default to invisible
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.showScrollBar = value

                                    -- Refresh all active frames to apply new visibility
                                    if KOL.Tracker and KOL.Tracker.RefreshAllWatchFrames then
                                        KOL.Tracker:RefreshAllWatchFrames()
                                    end
                                end,
                                order = 15,
                            },
                            scrollBarWidth = {
                                type = "range",
                                name = "Scrollbar Width",
                                desc = "Width of the scrollbar (in pixels, minimum 6 to prevent font size issues)",
                                min = 6,
                                max = 32,
                                step = 1,
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.scrollBarWidth) or 16
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.scrollBarWidth = value

                                    -- Recreate all active frames to apply new scrollbar width
                                    if KOL.Tracker and KOL.Tracker.activeFrames then
                                        for instanceId, frame in pairs(KOL.Tracker.activeFrames) do
                                            -- Only recreate if this instance doesn't have a per-instance override
                                            local hasOverride = KOL.db.profile.tracker.instances and
                                                               KOL.db.profile.tracker.instances[instanceId] and
                                                               KOL.db.profile.tracker.instances[instanceId].scrollBarWidth and
                                                               KOL.db.profile.tracker.instances[instanceId].scrollBarWidth > 0
                                            if not hasOverride then
                                                frame:Hide()
                                                KOL.Tracker.activeFrames[instanceId] = nil
                                                KOL.Tracker:ShowWatchFrame(instanceId)
                                            end
                                        end
                                    end
                                end,
                                order = 16,
                            },
                            spacer1 = {
                                type = "description",
                                name = " ",
                                order = 17,
                            },
                            colorHeader = {
                                type = "header",
                                name = "Colors",
                                order = 18,
                            },
                            titleFontColor = {
                                type = "color",
                                name = "Title Font Color",
                                desc = "Color for the instance title text",
                                hasAlpha = false,
                                get = function()
                                    -- Returns RGB (instance color used for title)
                                    return 0.7, 0.9, 1  -- Default SKY blue
                                end,
                                set = function(_, r, g, b)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.titleFontColor = {r, g, b}
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 19,
                            },
                            groupIncompleteColor = {
                                type = "color",
                                name = "Group Header Incomplete Color",
                                desc = "Color for group headers when not all bosses are killed (uses instance color by default)",
                                hasAlpha = false,
                                get = function()
                                    local color = KOL.db.profile.tracker and KOL.db.profile.tracker.groupIncompleteColor
                                    if color then
                                        return color[1], color[2], color[3]
                                    end
                                    return 0.7, 0.9, 1  -- Default uses instance color
                                end,
                                set = function(_, r, g, b)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.groupIncompleteColor = {r, g, b}
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 20,
                            },
                            groupCompleteColor = {
                                type = "color",
                                name = "Group Header Complete Color",
                                desc = "Color for group headers when all bosses are killed",
                                hasAlpha = false,
                                get = function()
                                    local color = KOL.db.profile.tracker and KOL.db.profile.tracker.groupCompleteColor
                                    if color then
                                        return color[1], color[2], color[3]
                                    end
                                    return 0.75, 1, 0.75  -- Default Pastel Easter Green
                                end,
                                set = function(_, r, g, b)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.groupCompleteColor = {r, g, b}
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 21,
                            },
                            objectiveIncompleteColor = {
                                type = "color",
                                name = "Objective Incomplete Color",
                                desc = "Color for bosses/objectives that are not yet killed/completed",
                                hasAlpha = false,
                                get = function()
                                    local color = KOL.db.profile.tracker and KOL.db.profile.tracker.objectiveIncompleteColor
                                    if color then
                                        return color[1], color[2], color[3]
                                    end
                                    return 1, 0.6, 0.6  -- Default Pastel Red
                                end,
                                set = function(_, r, g, b)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.objectiveIncompleteColor = {r, g, b}
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 22,
                            },
                            objectiveCompleteColor = {
                                type = "color",
                                name = "Objective Complete Color",
                                desc = "Color for bosses/objectives that are killed/completed",
                                hasAlpha = false,
                                get = function()
                                    local color = KOL.db.profile.tracker and KOL.db.profile.tracker.objectiveCompleteColor
                                    if color then
                                        return color[1], color[2], color[3]
                                    end
                                    return 0.7, 1, 0.7  -- Default Pastel Green
                                end,
                                set = function(_, r, g, b)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.objectiveCompleteColor = {r, g, b}
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 23,
                            },
                            spacerColors = {
                                type = "description",
                                name = " ",
                                order = 24,
                            },
                            fontHeader = {
                                type = "header",
                                name = "Fonts",
                                order = 25,
                            },
                            globalFont = {
                                type = "select",
                                name = "Global Font",
                                desc = "Default font for all watch frame text",
                                dialogControl = "LSM30_Font",
                                values = LibStub("LibSharedMedia-3.0"):HashTable("font"),
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.baseFont) or "Source Code Pro Bold"
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.baseFont = value
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 26,
                                width = "double",
                            },
                            fontScale = {
                                type = "range",
                                name = "Font Scale (All Content)",
                                desc = "Scale multiplier for all tracker fonts",
                                min = 0.5,
                                max = 2.0,
                                step = 0.05,
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.fontScale) or 1.0
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.fontScale = value
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 27,
                                width = "full",
                            },
                            spacerFonts1 = {
                                type = "description",
                                name = "\n|cFFFFFFFFSpecific Font Settings:|r",
                                order = 28,
                            },
                            titleFont = {
                                type = "select",
                                name = "Title Bar Font",
                                desc = "Font for instance title bar (leave empty to use Global Font)",
                                dialogControl = "LSM30_Font",
                                values = function()
                                    local fonts = LibStub("LibSharedMedia-3.0"):HashTable("font")
                                    fonts[""] = "Use Global Font"
                                    return fonts
                                end,
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.titleFont) or ""
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.titleFont = (value ~= "" and value or nil)
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 29,
                                width = "double",
                            },
                            titleFontSize = {
                                type = "range",
                                name = "Title Bar Size",
                                desc = "Font size for title bar (0 = auto, min: 8, max: 32)",
                                min = 0,
                                max = 32,
                                step = 1,
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.titleFontSize) or 0
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.titleFontSize = (value > 0 and value or nil)
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 29,
                                width = "normal",
                            },
                            titleFontOutline = {
                                type = "select",
                                name = "Title Bar Outline",
                                desc = "Font outline for title bar",
                                values = {
                                    ["NONE"] = "None",
                                    ["OUTLINE"] = "Outline",
                                    ["THICKOUTLINE"] = "Thick Outline",
                                    ["MONOCHROME"] = "Monochrome",
                                    ["OUTLINE, MONOCHROME"] = "Outline + Monochrome",
                                },
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.titleFontOutline) or "OUTLINE"
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.titleFontOutline = value
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 29.5,
                                width = "normal",
                            },
                            groupFont = {
                                type = "select",
                                name = "Group Header Font",
                                desc = "Font for group headers (leave empty to use Global Font)",
                                dialogControl = "LSM30_Font",
                                values = function()
                                    local fonts = LibStub("LibSharedMedia-3.0"):HashTable("font")
                                    fonts[""] = "Use Global Font"
                                    return fonts
                                end,
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.groupFont) or ""
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.groupFont = (value ~= "" and value or nil)
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 30,
                                width = "double",
                            },
                            groupFontSize = {
                                type = "range",
                                name = "Group Header Size",
                                desc = "Font size for group headers (0 = auto, min: 8, max: 32)",
                                min = 0,
                                max = 32,
                                step = 1,
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.groupFontSize) or 0
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.groupFontSize = (value > 0 and value or nil)
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 31,
                                width = "normal",
                            },
                            groupFontOutline = {
                                type = "select",
                                name = "Group Header Outline",
                                desc = "Font outline for group headers",
                                values = {
                                    ["NONE"] = "None",
                                    ["OUTLINE"] = "Outline",
                                    ["THICKOUTLINE"] = "Thick Outline",
                                    ["MONOCHROME"] = "Monochrome",
                                    ["OUTLINE, MONOCHROME"] = "Outline + Monochrome",
                                },
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.groupFontOutline) or "OUTLINE"
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.groupFontOutline = value
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 31.5,
                                width = "normal",
                            },
                            objectiveFont = {
                                type = "select",
                                name = "Objective Font",
                                desc = "Font for boss names and objectives (leave empty to use Global Font)",
                                dialogControl = "LSM30_Font",
                                values = function()
                                    local fonts = LibStub("LibSharedMedia-3.0"):HashTable("font")
                                    fonts[""] = "Use Global Font"
                                    return fonts
                                end,
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.objectiveFont) or ""
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.objectiveFont = (value ~= "" and value or nil)
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 32,
                                width = "double",
                            },
                            objectiveFontSize = {
                                type = "range",
                                name = "Objective Size",
                                desc = "Font size for boss names and objectives (0 = auto, min: 8, max: 32)",
                                min = 0,
                                max = 32,
                                step = 1,
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.objectiveFontSize) or 0
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.objectiveFontSize = (value > 0 and value or nil)
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 33,
                                width = "normal",
                            },
                            objectiveFontOutline = {
                                type = "select",
                                name = "Objective Outline",
                                desc = "Font outline for boss names and objectives",
                                values = {
                                    ["NONE"] = "None",
                                    ["OUTLINE"] = "Outline",
                                    ["THICKOUTLINE"] = "Thick Outline",
                                    ["MONOCHROME"] = "Monochrome",
                                    ["OUTLINE, MONOCHROME"] = "Outline + Monochrome",
                                },
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.objectiveFontOutline) or "OUTLINE"
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.objectiveFontOutline = value
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 33.5,
                                width = "normal",
                            },
                            spacer2 = {
                                type = "description",
                                name = " ",
                                order = 34,
                            },
                            resetHeader = {
                                type = "header",
                                name = "Reset Progress",
                                order = 28,
                            },
                            resetAll = {
                                type = "execute",
                                name = "Reset All Boss Kills",
                                desc = "Reset all boss kill tracking for all instances",
                                func = function()
                                    if KOL.Tracker then
                                        KOL.Tracker:ResetAll()
                                    end
                                end,
                                width = "full",
                                order = 23,
                                confirm = function()
                                    return "Are you sure you want to reset ALL boss kill tracking? This cannot be undone."
                                end,
                            },
                            spacer3 = {
                                type = "description",
                                name = " ",
                                order = 24,
                            },
                            infoHeader = {
                                type = "header",
                                name = "About Progress Tracker",
                                order = 25,
                            },
                            info = {
                                type = "description",
                                name = "|cFFAAAAFFThe Progress Tracker automatically tracks your dungeon and raid boss kills.\n\n" ..
                                      "|cFFFFFFFF• Auto-Show|r - Watch frames appear when entering tracked zones\n" ..
                                      "|cFFFFFF• Draggable|r - Drag from title text to move frames\n" ..
                                      "|cFFFFFFFF• Minimize|r - Double-click title text to collapse frames\n" ..
                                      "|cFFFFFFFF• Boss Detection|r - Automatically detects boss kills via combat log\n" ..
                                      "|cFFFFFFFF• Zone Detection|r - Matches main zone and subzone names\n\n" ..
                                      "|cFFFF8888Commands:|r\n" ..
                                      "|cFFCCCCCC/kol tracker list|r - List all registered instances\n" ..
                                      "|cFFCCCCCC/kol tracker zone|r - Show current zone info\n" ..
                                      "|cFFCCCCCC/kol tracker test|r - Show test watch frame\n" ..
                                      "|cFFCCCCCC/kol tracker reset|r - Reset all boss kills\n" ..
                                      "|cFFCCCCCC/kol tracker refresh|r - Refresh watch frames (after fontScale change)|r",
                                fontSize = "medium",
                                order = 26,
                            },
                        }
                    },
                    dungeons = {
                        type = "group",
                        name = "|cFF88DDFFDungeons|r",
                        order = 2,
                            args = {
                                header = {
                                    type = "description",
                                    name = "|cFFFFFFFFDungeon Tracker|r\n|cFFAAAAAAFilter and configure dungeon instances.|r\n",
                                    fontSize = "medium",
                                    order = 0,
                                },
                                filterGroup = {
                                    type = "group",
                                    name = "Filters",
                                    order = 1,
                                    args = {
                                        filterExpansion = {
                                            type = "select",
                                            name = "Expansion",
                                            desc = "Select which expansion's dungeons to display",
                                            width = 120,
                                            values = {
                                                [""] = "-- Select Expansion --",
                                                classic = "Classic",
                                                tbc = "The Burning Crusade",
                                                wotlk = "Wrath of the Lich King",
                                                all = "All Expansions",
                                            },
                                            get = function()
                                                return KOL.db.profile.tracker.dungeonFilterExpansion or ""
                                            end,
                                            set = function(_, value)
                                                KOL.db.profile.tracker.dungeonFilterExpansion = value
                                                KOL:PopulateTrackerConfigUI()
                                                LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
                                            end,
                                            order = 1,
                                        },
                                        filterDifficulty = {
                                            type = "select",
                                            name = "Difficulty",
                                            desc = "Filter dungeons by difficulty",
                                            width = 100,
                                            values = function()
                                                local expansion = KOL.db.profile.tracker.dungeonFilterExpansion or "all"
                                                if expansion == "all" then
                                                    return {
                                                        all = "All Difficulties",
                                                        normal = "Normal",
                                                        heroic = "Heroic",
                                                    }
                                                elseif expansion == "classic" then
                                                    return {
                                                        all = "All Difficulties",
                                                        normal = "Normal",
                                                    }
                                                else  -- TBC or WotLK
                                                    return {
                                                        all = "All Difficulties",
                                                        normal = "Normal",
                                                        heroic = "Heroic",
                                                    }
                                                end
                                            end,
                                            get = function()
                                                return KOL.db.profile.tracker.dungeonFilterDifficulty or "all"
                                            end,
                                            set = function(_, value)
                                                KOL.db.profile.tracker.dungeonFilterDifficulty = value
                                                KOL:PopulateTrackerConfigUI()
                                                LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
                                            end,
                                            order = 2,
                                        },
                                    },
                                },
                                selectInstance = {
                                    type = "select",
                                    name = "Select Instance",
                                    desc = "Choose which instance to configure",
                                    values = function()
                                        -- Build list of instances that match current filters
                                        local instances = {[""] = "-- Select Instance --"}
                                        if not KOL.Tracker or not KOL.Tracker.instances then
                                            return instances
                                        end
                                        
                                        local expansion = KOL.db.profile.tracker.dungeonFilterExpansion or ""
                                        local difficulty = KOL.db.profile.tracker.dungeonFilterDifficulty or "all"
                                        
                                        for id, data in pairs(KOL.Tracker.instances) do
                                            if data.type == "dungeon" then
                                                local include = true
                                                
                                                -- Filter by expansion
                                                if expansion ~= "" and expansion ~= "all" then
                                                    if data.expansion ~= expansion then
                                                        include = false
                                                    end
                                                end
                                                
                                                -- Filter by difficulty
                                                if difficulty ~= "" and difficulty ~= "all" then
                                                    if data.difficulty ~= difficulty then
                                                        include = false
                                                    end
                                                end
                                                
                                                if include then
                                                    instances[id] = data.name
                                                end
                                            end
                                        end
                                        return instances
                                    end,
                                    get = function()
                                        return KOL.db.profile.tracker.dungeonFilterInstance or ""
                                    end,
                                    set = function(_, value)
                                        KOL.db.profile.tracker.dungeonFilterInstance = value
                                        KOL:PopulateTrackerConfigUI()
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
                                    end,
                                    order = 2,
                                },
                                -- Dungeon instances will be populated below this
                        }
                    },
                    raids = {
                        type = "group",
                        name = "|cFFFF6666Raids|r",
                        order = 3,
                            args = {
                                header = {
                                    type = "description",
                                    name = "|cFFFFFFFFRaid Tracker|r\n|cFFAAAAAAFilter and configure raid instances.|r\n",
                                    fontSize = "medium",
                                    order = 0,
                                },
                                filterGroup = {
                                    type = "group",
                                    name = "Filters",
                                    order = 1,
                                    args = {
                                        filterExpansion = {
                                            type = "select",
                                            name = "Expansion",
                                            desc = "Select which expansion's raids to display",
                                            width = 120,
                                            values = {
                                                [""] = "-- Select Expansion --",
                                                classic = "Classic",
                                                tbc = "The Burning Crusade",
                                                wotlk = "Wrath of the Lich King",
                                                all = "All Expansions",
                                            },
                                            get = function()
                                                return KOL.db.profile.tracker.raidFilterExpansion or ""
                                            end,
                                            set = function(_, value)
                                                KOL.db.profile.tracker.raidFilterExpansion = value
                                                KOL:PopulateTrackerConfigUI()
                                                LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
                                            end,
                                            order = 1,
                                        },
                                        filterDifficulty = {
                                            type = "select",
                                            name = "Size/Difficulty",
                                            desc = "Filter raids by size and difficulty (N=Normal, H=Heroic)",
                                            width = 100,
                                            values = function()
                                                local expansion = KOL.db.profile.tracker.raidFilterExpansion or "all"
                                                -- Unified N/H naming with color coding
                                                -- Green bullet = Normal, Red bullet = Heroic
                                                local green = "|cFF66FF66"
                                                local red = "|cFFFF6666"
                                                local bullet = string.char(149) .. " "

                                                if expansion == "classic" then
                                                    return {
                                                        all = "All",
                                                        ["20n"] = green .. bullet .. "20N|r",
                                                        ["40n"] = green .. bullet .. "40N|r",
                                                    }
                                                elseif expansion == "tbc" then
                                                    return {
                                                        all = "All",
                                                        ["10n"] = green .. bullet .. "10N|r",
                                                        ["25n"] = green .. bullet .. "25N|r",
                                                    }
                                                elseif expansion == "wotlk" then
                                                    return {
                                                        all = "All",
                                                        ["10n"] = green .. bullet .. "10N|r",
                                                        ["25n"] = green .. bullet .. "25N|r",
                                                        ["10h"] = red .. bullet .. "10H|r",
                                                        ["25h"] = red .. bullet .. "25H|r",
                                                    }
                                                else  -- all expansions
                                                    return {
                                                        all = "All",
                                                        ["10n"] = green .. bullet .. "10N|r",
                                                        ["20n"] = green .. bullet .. "20N|r",
                                                        ["25n"] = green .. bullet .. "25N|r",
                                                        ["40n"] = green .. bullet .. "40N|r",
                                                        ["10h"] = red .. bullet .. "10H|r",
                                                        ["25h"] = red .. bullet .. "25H|r",
                                                    }
                                                end
                                            end,
                                            get = function()
                                                return KOL.db.profile.tracker.raidFilterDifficulty or "all"
                                            end,
                                            set = function(_, value)
                                                KOL.db.profile.tracker.raidFilterDifficulty = value
                                                KOL:PopulateTrackerConfigUI()
                                                LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
                                            end,
                                            order = 2,
                                        },
                                    },
                                },
                                selectInstance = {
                                    type = "select",
                                    name = "Select Instance",
                                    desc = "Choose which raid instance to configure",
                                    values = function()
                                        -- Build list of instances that match current filters
                                        local instances = {[""] = "-- Select Instance --"}
                                        if not KOL.Tracker or not KOL.Tracker.instances then
                                            return instances
                                        end

                                        local filterExpansion = KOL.db.profile.tracker.raidFilterExpansion or ""
                                        local filterDifficulty = KOL.db.profile.tracker.raidFilterDifficulty or "all"

                                        -- Collect raids for sorting
                                        local raidList = {}

                                        for id, data in pairs(KOL.Tracker.instances) do
                                            if data.type == "raid" then
                                                local include = true

                                                -- Filter by expansion
                                                if filterExpansion ~= "" and filterExpansion ~= "all" then
                                                    if data.expansion ~= filterExpansion then
                                                        include = false
                                                    end
                                                end

                                                -- Filter by unified difficulty code (e.g., "10n", "25h", "40n")
                                                if include and filterDifficulty ~= "" and filterDifficulty ~= "all" then
                                                    -- Get this raid's unified code
                                                    local raidCode = GetUnifiedDifficultyCode(data.expansion, data.difficulty, data.name)
                                                    if raidCode ~= filterDifficulty then
                                                        include = false
                                                    end
                                                end

                                                if include then
                                                    -- Get size and heroic status for sorting
                                                    local size = GetRaidSize(data.expansion, data.difficulty, data.name)
                                                    local isHeroic = IsHeroicRaid(data.expansion, data.difficulty)
                                                    local expansionOrder = ({classic = 1, tbc = 2, wotlk = 3})[data.expansion] or 4

                                                    table.insert(raidList, {
                                                        id = id,
                                                        name = data.name,
                                                        expansion = data.expansion,
                                                        expansionOrder = expansionOrder,
                                                        size = size,
                                                        isHeroic = isHeroic,
                                                    })
                                                end
                                            end
                                        end

                                        -- Sort by: expansion, then size, then heroic, then name
                                        table.sort(raidList, function(a, b)
                                            if a.expansionOrder ~= b.expansionOrder then
                                                return a.expansionOrder < b.expansionOrder
                                            end
                                            if a.size ~= b.size then
                                                return a.size < b.size
                                            end
                                            if a.isHeroic ~= b.isHeroic then
                                                return not a.isHeroic  -- Normal before Heroic
                                            end
                                            return a.name < b.name
                                        end)

                                        -- Build ordered instances table
                                        for _, raid in ipairs(raidList) do
                                            instances[raid.id] = raid.name
                                        end

                                        return instances
                                    end,
                                    get = function()
                                        return KOL.db.profile.tracker.selectedRaidInstance or ""
                                    end,
                                    set = function(_, value)
                                        KOL.db.profile.tracker.selectedRaidInstance = value
                                        KOL:PopulateTrackerConfigUI()
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
                                    end,
                                    order = 2,
                                },
                                -- Raid instances will be populated below this
                        }
                    },
                    custom = {
                        type = "group",
                        name = "|cFFFFAA00Custom Trackers|r",
                        order = 4,
                        args = {
                            -- Will be populated dynamically by PopulateTrackerConfigUI()
                        }
                    },
                }
            },
            -- Binds UI loaded separately via binds-ui.lua
        },
        -- Themes temporarily disabled due to config validation error
        -- themes = {
        --     type = "group",
        --     name = "|cFFAA66FFThemes|r",
        --     order = 10,
        --     args = {
        --         themeInfo = {
        --             type = "description",
        --             name = "|cFFAAAAAATheme system loaded - use /kol theme commands to test|r\n\n" ..
        --                   "|cFFFF8800/kol theme info|r - Show current theme info\n" ..
        --                   "|cFFFF8800/kol theme list|r - List available themes\n" ..
        --                   "|cFFFF8800/kol theme test|r - Show color samples\n" ..
        --                   "|cFFFF8800/kol theme export|r - Export current theme",
        --             fontSize = "medium",
        --             order = 1,
        --         },
        --     }
        -- }
    }

    -- IMPORTANT: Store options table so modules can add to it
    self.configOptions = options

    -- Register options
    AceConfig:RegisterOptionsTable("KoalityOfLife", options)

    -- Add to Blizzard Interface Options
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("KoalityOfLife", RainbowText("Koality of Life"))

    -- Register profile options
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    options.args.profiles.order = 100

    -- Initialize breadcrumb navigation (if breadcrumb.lua is loaded)
    if self.InitializeBreadcrumb then
        self:InitializeBreadcrumb()
    end

    -- Initialize batch UI (if batch-ui.lua is loaded)
    if self.InitializeBatchUI then
        self:InitializeBatchUI()
    end

    -- Initialize Binds mockup UI (if binds-mockup.lua is loaded) - DISABLED
    -- if self.InitializeBindsMockupUI then
    --     self:InitializeBindsMockupUI()
    -- end

    -- Initialize Binds UI (if binds-ui.lua is loaded)
    if self.InitializeBindsUI then
        self:InitializeBindsUI()
    end

    -- Initialize Tweaks config UI (if tweaks.lua is loaded)
    if self.Tweaks and self.Tweaks.Initialize then
        self.Tweaks:Initialize()
    end

    -- Initialize Fishing config UI (if fishing.lua is loaded)
    if self.fishing and self.fishing.InitializeConfig then
        self.fishing:InitializeConfig()
    end

    -- Initialize Changes config UI (if changes.lua is loaded)
    if self.changes and self.changes.InitializeConfig then
        self.changes:InitializeConfig()
    end

    -- Initialize Colors config UI (if colors.lua is loaded)
    if self.Colors then
        self.Colors:PopulateStandardColorsUI()
        self.Colors:PopulatePastelColorsUI()
        self.Colors:PopulateNuclearColorsUI()
        self.Colors:PopulateCustomColorsUI()
    end

    -- Initialize Tracker config UI (will be re-populated when tracker-data loads)
    if self.PopulateTrackerConfigUI then
        self:PopulateTrackerConfigUI()
    end
end

-- ============================================================================
-- Progress Tracker Config Population
-- ============================================================================

function KOL:PopulateTrackerConfigUI()
    if not self.configOptions or not self.configOptions.args.tracker then
        return
    end

    if not KOL.Tracker or not KOL.Tracker.instances then
        return
    end

    local dungeonsArgs = self.configOptions.args.tracker.args.dungeons.args
    local raidsArgs = self.configOptions.args.tracker.args.raids.args
    local customArgs = self.configOptions.args.tracker.args.custom.args

    -- Get filter settings (default to empty = no content shown)
    local dungeonFilterExpansion = KOL.db.profile.tracker.dungeonFilterExpansion or ""
    local dungeonFilterDifficulty = KOL.db.profile.tracker.dungeonFilterDifficulty or "all"
    local selectedDungeonInstance = KOL.db.profile.tracker.selectedDungeonInstance or ""
    local raidFilterExpansion = KOL.db.profile.tracker.raidFilterExpansion or ""
    local raidFilterDifficulty = KOL.db.profile.tracker.raidFilterDifficulty or "all"
    local selectedRaidInstance = KOL.db.profile.tracker.selectedRaidInstance or ""
    local selectedCustomInstance = KOL.db.profile.tracker.selectedCustomInstance or ""

    -- Validate that selected custom instance still exists
    if selectedCustomInstance ~= "" then
        local foundInInstances = KOL.Tracker.instances[selectedCustomInstance]
        local foundInDB = KOL.db.profile.tracker.customPanels and KOL.db.profile.tracker.customPanels[selectedCustomInstance]

        if not foundInInstances and not foundInDB then
            KOL:DebugPrint("Tracker Config: Selected custom instance '" .. selectedCustomInstance .. "' not found anywhere, clearing selection", 2)
            KOL.db.profile.tracker.selectedCustomInstance = ""
            selectedCustomInstance = ""
        elseif not foundInInstances and foundInDB then
            -- Instance exists in DB but not loaded - reload it
            KOL:DebugPrint("Tracker Config: Selected custom instance '" .. selectedCustomInstance .. "' found in DB, reloading", 2)
            KOL.Tracker:RegisterInstance(selectedCustomInstance, foundInDB)
        else
            KOL:DebugPrint("Tracker Config: Found selected custom instance: " .. selectedCustomInstance, 3)
        end
    end

    -- Clear existing instance entries (keep filter UI)
    for k, _ in pairs(dungeonsArgs) do
        if k ~= "header" and k ~= "filterExpansion" and k ~= "filterDifficulty" and k ~= "selectInstance" and k ~= "spacer" then
            dungeonsArgs[k] = nil
        end
    end
    for k, _ in pairs(raidsArgs) do
        if k ~= "header" and k ~= "filterExpansion" and k ~= "filterDifficulty" and k ~= "selectInstance" and k ~= "spacer" then
            raidsArgs[k] = nil
        end
    end
    for k, _ in pairs(customArgs) do
        customArgs[k] = nil
    end

    local dungeonOrder = 10  -- Start after filter UI
    local raidOrder = 10
    local customOrder = 20  -- Start after control UI (header, create, select, management)

    -- Helper functions for instance settings (defined once, not per-instance)
    local function GetInstanceSetting(instanceId, key, defaultValue)
        if not KOL.db.profile.tracker.instances then
            KOL.db.profile.tracker.instances = {}
        end
        if not KOL.db.profile.tracker.instances[instanceId] then
            return defaultValue
        end
        local value = KOL.db.profile.tracker.instances[instanceId][key]
        return value ~= nil and value or defaultValue
    end

    local function SetInstanceSetting(instanceId, key, value)
        if not KOL.db.profile.tracker.instances then
            KOL.db.profile.tracker.instances = {}
        end
        if not KOL.db.profile.tracker.instances[instanceId] then
            KOL.db.profile.tracker.instances[instanceId] = {}
        end
        KOL.db.profile.tracker.instances[instanceId][key] = value

        -- Update active frame if it exists
        if KOL.Tracker and KOL.Tracker.activeFrames and KOL.Tracker.activeFrames[instanceId] then
            -- Recreate the frame with new settings
            KOL.Tracker.activeFrames[instanceId]:Hide()
            KOL.Tracker.activeFrames[instanceId] = nil
            KOL.Tracker:ShowWatchFrame(instanceId)
        end
    end

    -- Helper function to check if instance passes filters
    local function PassesFilters(data)
        if data.type == "dungeon" then
            -- If no expansion selected, show nothing
            if dungeonFilterExpansion == "" then
                return false
            end
            -- Check expansion filter
            if dungeonFilterExpansion ~= "all" and data.expansion ~= dungeonFilterExpansion then
                return false
            end
            -- Check difficulty filter
            if dungeonFilterDifficulty ~= "all" then
                if dungeonFilterDifficulty == "normal" and data.difficulty ~= nil and data.difficulty > 1 then
                    return false
                elseif dungeonFilterDifficulty == "heroic" and (data.difficulty == nil or data.difficulty ~= 2) then
                    return false
                end
            end
        elseif data.type == "raid" then
            -- If no expansion selected, show nothing
            if raidFilterExpansion == "" then
                return false
            end
            -- Check expansion filter
            if raidFilterExpansion ~= "all" and data.expansion ~= raidFilterExpansion then
                return false
            end
            -- Check difficulty/size filter
            if raidFilterDifficulty ~= "all" then
                -- Map difficulty codes to filter values
                -- Classic: 20-player (no difficulty field), 40-player (no difficulty field)
                -- TBC: 10-player, 25-player (no difficulty field in our data)
                -- WotLK: difficulty 1=10N, 2=25N, 3=10H, 4=25H

                if data.expansion == "classic" then
                    -- Check raid size based on name
                    if raidFilterDifficulty == "20" then
                        if not (string.find(data.name, "Zul'Gurub") or string.find(data.name, "AQ20") or string.find(data.name, "Ruins")) then
                            return false
                        end
                    elseif raidFilterDifficulty == "40" then
                        if string.find(data.name, "Zul'Gurub") or string.find(data.name, "AQ20") or string.find(data.name, "Ruins") then
                            return false
                        end
                    end
                elseif data.expansion == "tbc" then
                    -- Check raid size based on difficulty field or name
                    if raidFilterDifficulty == "10" then
                        if not (string.find(data.name, "10") or string.find(data.name, "Karazhan") or string.find(data.name, "Zul'Aman")) then
                            return false
                        end
                    elseif raidFilterDifficulty == "25" then
                        if string.find(data.name, "10") or string.find(data.name, "Karazhan") or string.find(data.name, "Zul'Aman") then
                            return false
                        end
                    end
                elseif data.expansion == "wotlk" then
                    -- WotLK has difficulty field: 1=10N, 2=25N, 3=10H, 4=25H
                    if raidFilterDifficulty == "10n" and data.difficulty ~= 1 then
                        return false
                    elseif raidFilterDifficulty == "25n" and data.difficulty ~= 2 then
                        return false
                    elseif raidFilterDifficulty == "10h" and data.difficulty ~= 3 then
                        return false
                    elseif raidFilterDifficulty == "25h" and data.difficulty ~= 4 then
                        return false
                    elseif raidFilterDifficulty == "10" and (data.difficulty ~= 1 and data.difficulty ~= 3) then
                        return false
                    elseif raidFilterDifficulty == "25" and (data.difficulty ~= 2 and data.difficulty ~= 4) then
                        return false
                    end
                end
            end
        end
        return true
    end

    -- Debug: Count instances by type and list custom trackers
    local debugCounts = {dungeon = 0, raid = 0, custom = 0}
    local customPanelIds = {}
    for id, d in pairs(KOL.Tracker.instances) do
        local t = d.type or "custom"
        debugCounts[t] = (debugCounts[t] or 0) + 1
        if t ~= "dungeon" and t ~= "raid" then
            table.insert(customPanelIds, id)
        end
    end
    KOL:DebugPrint("Tracker Config: Instances - " .. debugCounts.dungeon .. " dungeons, " .. debugCounts.raid .. " raids, " .. (debugCounts.custom or 0) .. " custom", 2)
    if #customPanelIds > 0 then
        KOL:DebugPrint("Tracker Config: Custom tracker IDs: " .. table.concat(customPanelIds, ", "), 2)
    end
    if selectedCustomInstance ~= "" then
        KOL:DebugPrint("Tracker Config: Looking for selectedCustomInstance: '" .. selectedCustomInstance .. "'", 2)
    end

    -- Iterate through all registered instances
    for instanceId, data in pairs(KOL.Tracker.instances) do
        -- Check if we should only show a specific instance
        local shouldShow = false
        if data.type == "dungeon" then
            -- Only show if a specific dungeon is selected AND it matches
            if selectedDungeonInstance ~= "" and instanceId == selectedDungeonInstance then
                shouldShow = true
            end
        elseif data.type == "raid" then
            -- Only show if a specific raid is selected AND it matches
            if selectedRaidInstance ~= "" and instanceId == selectedRaidInstance then
                shouldShow = true
            end
        else
            -- Custom trackers - only show if selected
            local isMatch = (instanceId == selectedCustomInstance)
            KOL:DebugPrint("Tracker Config: Custom '" .. instanceId .. "' == '" .. selectedCustomInstance .. "' ? " .. tostring(isMatch), 2)
            if selectedCustomInstance ~= "" and isMatch then
                shouldShow = true
                KOL:DebugPrint("Tracker Config: MATCH! Will show config for: " .. instanceId, 2)
            end
        end

        -- Only process if should be shown
        if shouldShow then
            local args, order
            if data.type == "dungeon" then
                args = dungeonsArgs
                order = dungeonOrder
            elseif data.type == "raid" then
                args = raidsArgs
                order = raidOrder
            else
                args = customArgs
                order = customOrder
                KOL:DebugPrint("Tracker Config: Adding custom config to customArgs with order " .. order, 2)
            end

            -- Check if this is a custom tracker (not dungeon/raid)
            local isCustomTracker = (data.type ~= "dungeon" and data.type ~= "raid")

            if isCustomTracker then
                -- NEW Custom Tracker structure with Display, Layout, Appearance groups
                args[instanceId] = {
                    type = "group",
                    name = data.name,
                    inline = true,
                    order = order,
                    args = {
                        -- Display group - action buttons + display options
                        displayGroup = {
                            type = "group",
                            name = "Display",
                            inline = true,
                            order = 10,
                            args = {
                                -- Action buttons row
                                showFrame = {
                                    type = "execute",
                                    name = "Show",
                                    desc = "Show the watch frame for this tracker",
                                    func = function()
                                        if KOL.Tracker then
                                            KOL.Tracker:ShowWatchFrame(instanceId)
                                        end
                                    end,
                                    width = 0.4,
                                    order = 1,
                                },
                                hideFrame = {
                                    type = "execute",
                                    name = "Hide",
                                    desc = "Hide the watch frame for this tracker",
                                    func = function()
                                        if KOL.Tracker then
                                            KOL.Tracker:HideWatchFrame(instanceId)
                                        end
                                    end,
                                    width = 0.4,
                                    order = 2,
                                },
                                resetProgress = {
                                    type = "execute",
                                    name = "Reset Progress",
                                    desc = "Reset all progress for this tracker back to 0.\n\n|cFFFFFF00Note:|r Loot items will re-count from your inventory.",
                                    func = function()
                                        if KOL.Tracker then
                                            KOL.Tracker:ResetInstance(instanceId)
                                            KOL:PrintTag("Reset progress for: " .. data.name)
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                                        end
                                    end,
                                    width = 0.55,
                                    order = 3,
                                    confirm = function()
                                        return "Reset all progress for " .. data.name .. "?\n\nNote: Loot items will re-count from inventory."
                                    end,
                                },
                                resetAllSettings = {
                                    type = "execute",
                                    name = "Reset All Settings",
                                    desc = "Reset ALL settings for this tracker back to defaults.\n\n|cFF00FF00This does NOT delete:|r Your entries/objectives.",
                                    func = function()
                                        -- Reset per-instance settings
                                        if KOL.db.profile.tracker.instances and KOL.db.profile.tracker.instances[instanceId] then
                                            KOL.db.profile.tracker.instances[instanceId] = nil
                                        end
                                        -- Refresh the watch frame if shown
                                        if KOL.Tracker.activeFrames[instanceId] then
                                            KOL.Tracker:HideWatchFrame(instanceId)
                                            KOL.Tracker:ShowWatchFrame(instanceId)
                                        end
                                        KOL:PrintTag("Reset all settings for: " .. data.name)
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                                    end,
                                    width = 0.65,
                                    order = 4,
                                    confirm = function()
                                        return "Reset ALL settings for " .. data.name .. "?\n\nYour entries will NOT be deleted."
                                    end,
                                },
                                -- Separator after buttons
                                buttonSpacer = {
                                    type = "description",
                                    name = " ",
                                    width = "full",
                                    order = 5,
                                },
                                -- Display options
                                enabled = {
                                    type = "toggle",
                                    name = "Enable Auto-Show",
                                    desc = "Automatically show watch frame when entering tracked zones",
                                    get = function()
                                        -- Read from panel data (same as Tracker Manager)
                                        local panelData = KOL.Tracker.instances[instanceId]
                                        if panelData then
                                            return panelData.autoShow or false
                                        end
                                        return false
                                    end,
                                    set = function(_, value)
                                        -- Write to both panel data AND saved DB
                                        local panelData = KOL.Tracker.instances[instanceId]
                                        if panelData then
                                            panelData.autoShow = value
                                        end
                                        if KOL.db.profile.tracker.customPanels and KOL.db.profile.tracker.customPanels[instanceId] then
                                            KOL.db.profile.tracker.customPanels[instanceId].autoShow = value
                                        end
                                        -- If turning off and frame is visible, hide it
                                        if not value and KOL.Tracker.activeFrames[instanceId] then
                                            KOL.Tracker:HideWatchFrame(instanceId)
                                        end
                                        KOL:PrintTag(data.name .. " auto-show: " .. (value and GREEN("Enabled") or RED("Disabled")))
                                    end,
                                    width = 1.0,
                                    order = 6,
                                },
                                autoCollapse = {
                                    type = "toggle",
                                    name = "Auto-Collapse Completed Groups",
                                    desc = "Automatically collapse groups when all entries are complete",
                                    get = function()
                                        local val = GetInstanceSetting(instanceId, "autoCollapse", nil)
                                        if val == nil then return true end  -- Default ON
                                        return val
                                    end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "autoCollapse", value)
                                        KOL:PrintTag(data.name .. " auto-collapse: " .. (value and GREEN("Enabled") or RED("Disabled")))
                                    end,
                                    width = 1.2,
                                    order = 7,
                                },
                                customZoneText = {
                                    type = "input",
                                    name = "Custom Zone Text",
                                    desc = "Override the default title text (leave empty to use default: " .. data.name .. ")",
                                    get = function() return GetInstanceSetting(instanceId, "titleText", "") end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "titleText", value)
                                        KOL:PrintTag("Title text updated for: " .. data.name)
                                    end,
                                    width = "full",
                                    order = 8,
                                },
                            },
                        },

                        -- Layout group - frame dimensions and visibility
                        layoutGroup = {
                            type = "group",
                            name = "Layout",
                            inline = true,
                            order = 15,
                            args = {
                                frameWidth = {
                                    type = "range",
                                    name = "Frame Width",
                                    desc = "Override frame width (0 = use default)",
                                    min = 0,
                                    max = 600,
                                    step = 1,
                                    get = function() return GetInstanceSetting(instanceId, "frameWidth", 0) end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "frameWidth", value)
                                    end,
                                    order = 1,
                                },
                                frameHeight = {
                                    type = "range",
                                    name = "Frame Height",
                                    desc = "Override frame height (0 = use default)",
                                    min = 0,
                                    max = 800,
                                    step = 1,
                                    get = function() return GetInstanceSetting(instanceId, "frameHeight", 0) end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "frameHeight", value)
                                    end,
                                    order = 2,
                                },
                                showScrollBar = {
                                    type = "select",
                                    name = "Scrollbar Visibility",
                                    desc = "Control scrollbar visibility (Default = use global setting)",
                                    values = {
                                        ["default"] = "Default (Use Global)",
                                        ["hidden"] = "Hidden",
                                        ["visible"] = "Visible",
                                    },
                                    get = function()
                                        local value = GetInstanceSetting(instanceId, "showScrollBar", nil)
                                        if value == nil then
                                            return "default"
                                        elseif value == true then
                                            return "visible"
                                        else
                                            return "hidden"
                                        end
                                    end,
                                    set = function(_, value)
                                        if value == "default" then
                                            if KOL.db.profile.tracker.instances and KOL.db.profile.tracker.instances[instanceId] then
                                                KOL.db.profile.tracker.instances[instanceId].showScrollBar = nil
                                            end
                                        elseif value == "visible" then
                                            SetInstanceSetting(instanceId, "showScrollBar", true)
                                        else
                                            SetInstanceSetting(instanceId, "showScrollBar", false)
                                        end
                                    end,
                                    order = 3,
                                },
                                scrollBarWidth = {
                                    type = "range",
                                    name = "Scrollbar Width",
                                    desc = "Width of the scrollbar in pixels (0 = use global setting)",
                                    min = 0,
                                    max = 32,
                                    step = 1,
                                    get = function() return GetInstanceSetting(instanceId, "scrollBarWidth", 0) end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "scrollBarWidth", value)
                                    end,
                                    order = 4,
                                },
                                showBgOnHover = {
                                    type = "toggle",
                                    name = "Show BG on Mouseover Only",
                                    desc = "Hide the frame background by default, show it only when hovering (floating text look)",
                                    get = function() return GetInstanceSetting(instanceId, "showBgOnHover", false) end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "showBgOnHover", value)
                                        -- Also set the old values for compatibility
                                        SetInstanceSetting(instanceId, "hideUI", value)
                                        SetInstanceSetting(instanceId, "showUIOnMouseover", value)
                                    end,
                                    width = "full",
                                    order = 5,
                                },
                            },
                        },

                        -- Appearance group - colors + fonts combined
                        appearanceGroup = {
                            type = "group",
                            name = "Appearance",
                            inline = true,
                            order = 20,
                            args = {
                                -- Objective Colors section
                                objectiveColorsLabel = {
                                    type = "description",
                                    name = "|cFF88DDFF--- Objective Colors ---|r",
                                    fontSize = "medium",
                                    order = 1,
                                },
                                titleFontColor = {
                                    type = "color",
                                    name = "Title Font Color",
                                    desc = "Color of the title text",
                                    hasAlpha = false,
                                    get = function()
                                        local color = GetInstanceSetting(instanceId, "titleFontColor", nil)
                                        if color then
                                            return color[1], color[2], color[3]
                                        end
                                        local colorName = data.color or "PINK"
                                        local rgb = KOL.Colors:GetPastel(colorName)
                                        return rgb[1], rgb[2], rgb[3]
                                    end,
                                    set = function(_, r, g, b)
                                        SetInstanceSetting(instanceId, "titleFontColor", {r, g, b})
                                    end,
                                    order = 2,
                                },
                                groupIncompleteColor = {
                                    type = "color",
                                    name = "Group Incomplete",
                                    desc = "Color for group headers when not all entries are complete",
                                    hasAlpha = false,
                                    get = function()
                                        local color = GetInstanceSetting(instanceId, "groupIncompleteColor", nil)
                                        if color then
                                            return color[1], color[2], color[3]
                                        end
                                        local colorName = data.color or "PINK"
                                        local rgb = KOL.Colors:GetPastel(colorName)
                                        return rgb[1], rgb[2], rgb[3]
                                    end,
                                    set = function(_, r, g, b)
                                        SetInstanceSetting(instanceId, "groupIncompleteColor", {r, g, b})
                                    end,
                                    order = 3,
                                },
                                groupCompleteColor = {
                                    type = "color",
                                    name = "Group Complete",
                                    desc = "Color for group headers when all entries are complete",
                                    hasAlpha = false,
                                    get = function()
                                        local color = GetInstanceSetting(instanceId, "groupCompleteColor", nil)
                                        if color then
                                            return color[1], color[2], color[3]
                                        end
                                        return 0.75, 1, 0.75
                                    end,
                                    set = function(_, r, g, b)
                                        SetInstanceSetting(instanceId, "groupCompleteColor", {r, g, b})
                                    end,
                                    order = 4,
                                },
                                objectiveIncompleteColor = {
                                    type = "color",
                                    name = "Objective Incomplete",
                                    desc = "Color for objectives that are not yet completed",
                                    hasAlpha = false,
                                    get = function()
                                        local color = GetInstanceSetting(instanceId, "objectiveIncompleteColor", nil)
                                        if color then
                                            return color[1], color[2], color[3]
                                        end
                                        return 1, 0.6, 0.6
                                    end,
                                    set = function(_, r, g, b)
                                        SetInstanceSetting(instanceId, "objectiveIncompleteColor", {r, g, b})
                                    end,
                                    order = 5,
                                },
                                objectiveCompleteColor = {
                                    type = "color",
                                    name = "Objective Complete",
                                    desc = "Color for objectives that are completed",
                                    hasAlpha = false,
                                    get = function()
                                        local color = GetInstanceSetting(instanceId, "objectiveCompleteColor", nil)
                                        if color then
                                            return color[1], color[2], color[3]
                                        end
                                        return 0.7, 1, 0.7
                                    end,
                                    set = function(_, r, g, b)
                                        SetInstanceSetting(instanceId, "objectiveCompleteColor", {r, g, b})
                                    end,
                                    order = 6,
                                },

                                -- UI Colors section
                                uiColorsLabel = {
                                    type = "description",
                                    name = "\n|cFF88DDFF--- UI Colors ---|r",
                                    fontSize = "medium",
                                    order = 10,
                                },
                                backgroundColor = {
                                    type = "color",
                                    name = "Background",
                                    desc = "Main frame background color",
                                    hasAlpha = true,
                                    get = function()
                                        local color = GetInstanceSetting(instanceId, "backgroundColor", nil)
                                        if color then
                                            return color[1], color[2], color[3], color[4] or 0.95
                                        end
                                        return 0.05, 0.05, 0.05, 0.95
                                    end,
                                    set = function(_, r, g, b, a)
                                        SetInstanceSetting(instanceId, "backgroundColor", {r, g, b, a})
                                    end,
                                    order = 11,
                                },
                                borderColor = {
                                    type = "color",
                                    name = "Border",
                                    desc = "Frame border color",
                                    hasAlpha = true,
                                    get = function()
                                        local color = GetInstanceSetting(instanceId, "borderColor", nil)
                                        if color then
                                            return color[1], color[2], color[3], color[4] or 1
                                        end
                                        return 0.2, 0.2, 0.2, 1
                                    end,
                                    set = function(_, r, g, b, a)
                                        SetInstanceSetting(instanceId, "borderColor", {r, g, b, a})
                                    end,
                                    order = 12,
                                },
                                titleBarColor = {
                                    type = "color",
                                    name = "Title Bar",
                                    desc = "Title bar background color",
                                    hasAlpha = true,
                                    get = function()
                                        local color = GetInstanceSetting(instanceId, "titleBarColor", nil)
                                        if color then
                                            return color[1], color[2], color[3], color[4] or 1
                                        end
                                        return 0.1, 0.1, 0.1, 1
                                    end,
                                    set = function(_, r, g, b, a)
                                        SetInstanceSetting(instanceId, "titleBarColor", {r, g, b, a})
                                    end,
                                    order = 13,
                                },
                                scrollBarColor = {
                                    type = "color",
                                    name = "Scroll Bar BG",
                                    desc = "Scroll bar background color",
                                    hasAlpha = true,
                                    get = function()
                                        local color = GetInstanceSetting(instanceId, "scrollBarColor", nil)
                                        if color then
                                            return color[1], color[2], color[3], color[4] or 0.9
                                        end
                                        return 0.1, 0.1, 0.1, 0.9
                                    end,
                                    set = function(_, r, g, b, a)
                                        SetInstanceSetting(instanceId, "scrollBarColor", {r, g, b, a})
                                    end,
                                    order = 14,
                                },
                                scrollThumbColor = {
                                    type = "color",
                                    name = "Scroll Thumb",
                                    desc = "Scroll bar thumb/slider color",
                                    hasAlpha = true,
                                    get = function()
                                        local color = GetInstanceSetting(instanceId, "scrollThumbColor", nil)
                                        if color then
                                            return color[1], color[2], color[3], color[4] or 1
                                        end
                                        return 0.3, 0.3, 0.3, 1
                                    end,
                                    set = function(_, r, g, b, a)
                                        SetInstanceSetting(instanceId, "scrollThumbColor", {r, g, b, a})
                                    end,
                                    order = 15,
                                },
                                scrollBarBorderColor = {
                                    type = "color",
                                    name = "Scroll Border",
                                    desc = "Scroll bar border color",
                                    hasAlpha = true,
                                    get = function()
                                        local color = GetInstanceSetting(instanceId, "scrollBarBorderColor", nil)
                                        if color then
                                            return color[1], color[2], color[3], color[4] or 1
                                        end
                                        return 0.2, 0.2, 0.2, 1
                                    end,
                                    set = function(_, r, g, b, a)
                                        SetInstanceSetting(instanceId, "scrollBarBorderColor", {r, g, b, a})
                                    end,
                                    order = 16,
                                },

                                -- Fonts section
                                fontsLabel = {
                                    type = "description",
                                    name = "\n|cFF88DDFF--- Fonts ---|r",
                                    fontSize = "medium",
                                    order = 20,
                                },
                                globalFont = {
                                    type = "select",
                                    name = "Global Font",
                                    desc = "Default font for all text",
                                    dialogControl = "LSM30_Font",
                                    values = LibStub("LibSharedMedia-3.0"):HashTable("font"),
                                    get = function() return GetInstanceSetting(instanceId, "globalFont", KOL.db.profile.generalFont or "Friz Quadrata TT") end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "globalFont", value)
                                    end,
                                    order = 21,
                                    width = "double",
                                },
                                fontScale = {
                                    type = "range",
                                    name = "Font Scale",
                                    desc = "Scale multiplier for ALL fonts",
                                    min = 0.5,
                                    max = 2.0,
                                    step = 0.05,
                                    get = function() return GetInstanceSetting(instanceId, "fontScale", 1.0) end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "fontScale", value)
                                    end,
                                    order = 22,
                                },
                                globalFontOutline = {
                                    type = "select",
                                    name = "Global Outline",
                                    desc = "Default outline style for all text",
                                    values = {
                                        ["NONE"] = "None",
                                        ["OUTLINE"] = "Outline",
                                        ["THICKOUTLINE"] = "Thick Outline",
                                    },
                                    get = function() return GetInstanceSetting(instanceId, "globalFontOutline", "OUTLINE") end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "globalFontOutline", value)
                                    end,
                                    order = 23,
                                },
                                titleFont = {
                                    type = "select",
                                    name = "Title Font",
                                    desc = "Font for title bar (empty = use Global)",
                                    dialogControl = "LSM30_Font",
                                    values = function()
                                        local fonts = LibStub("LibSharedMedia-3.0"):HashTable("font")
                                        fonts[""] = "Use Global Font"
                                        return fonts
                                    end,
                                    get = function() return GetInstanceSetting(instanceId, "titleFont", "") end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "titleFont", value ~= "" and value or nil)
                                    end,
                                    order = 24,
                                },
                                titleFontSize = {
                                    type = "range",
                                    name = "Title Size",
                                    desc = "Font size for title (0 = auto)",
                                    min = 0,
                                    max = 32,
                                    step = 1,
                                    get = function() return GetInstanceSetting(instanceId, "titleFontSize", 0) end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "titleFontSize", value > 0 and value or nil)
                                    end,
                                    order = 25,
                                },
                                groupFont = {
                                    type = "select",
                                    name = "Group Font",
                                    desc = "Font for group headers (empty = use Global)",
                                    dialogControl = "LSM30_Font",
                                    values = function()
                                        local fonts = LibStub("LibSharedMedia-3.0"):HashTable("font")
                                        fonts[""] = "Use Global Font"
                                        return fonts
                                    end,
                                    get = function() return GetInstanceSetting(instanceId, "groupFont", "") end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "groupFont", value ~= "" and value or nil)
                                    end,
                                    order = 26,
                                },
                                groupFontSize = {
                                    type = "range",
                                    name = "Group Size",
                                    desc = "Font size for group headers (0 = auto)",
                                    min = 0,
                                    max = 32,
                                    step = 1,
                                    get = function() return GetInstanceSetting(instanceId, "groupFontSize", 0) end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "groupFontSize", value > 0 and value or nil)
                                    end,
                                    order = 27,
                                },
                                objectiveFont = {
                                    type = "select",
                                    name = "Objective Font",
                                    desc = "Font for objectives (empty = use Global)",
                                    dialogControl = "LSM30_Font",
                                    values = function()
                                        local fonts = LibStub("LibSharedMedia-3.0"):HashTable("font")
                                        fonts[""] = "Use Global Font"
                                        return fonts
                                    end,
                                    get = function() return GetInstanceSetting(instanceId, "objectiveFont", "") end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "objectiveFont", value ~= "" and value or nil)
                                    end,
                                    order = 28,
                                },
                                objectiveFontSize = {
                                    type = "range",
                                    name = "Objective Size",
                                    desc = "Font size for objectives (0 = auto)",
                                    min = 0,
                                    max = 32,
                                    step = 1,
                                    get = function() return GetInstanceSetting(instanceId, "objectiveFontSize", 0) end,
                                    set = function(_, value)
                                        SetInstanceSetting(instanceId, "objectiveFontSize", value > 0 and value or nil)
                                    end,
                                    order = 29,
                                },
                            },
                        },
                    },
                }
            else
                -- EXISTING Dungeons/Raids structure (unchanged)
                args[instanceId] = {
                type = "group",
                name = data.name,
                inline = true,
                order = order,
                args = {
                    status = {
                        type = "description",
                        name = function()
                            -- Count killed bosses
                            local killed = 0
                            local total = 0

                            if data.bosses and #data.bosses > 0 then
                                total = #data.bosses
                                for i = 1, total do
                                    if KOL.Tracker:IsBossKilled(instanceId, i) then
                                        killed = killed + 1
                                    end
                                end
                            elseif data.groups and #data.groups > 0 then
                                for groupIndex, group in ipairs(data.groups) do
                                    if group.bosses then
                                        for bossIndex, boss in ipairs(group.bosses) do
                                            total = total + 1
                                            local bossId = "g" .. groupIndex .. "-b" .. bossIndex
                                            if KOL.Tracker:IsBossKilled(instanceId, bossId) then
                                                killed = killed + 1
                                            end
                                        end
                                    end
                                end
                            end

                            local statusColor = killed == total and GREEN or (killed > 0 and YELLOW or RED)
                            local expansionText = data.expansion and " (" .. string.upper(data.expansion) .. ")" or ""
                            return statusColor(killed .. "/" .. total .. " defeated") .. expansionText .. "\n"
                        end,
                        fontSize = "small",
                        order = 1,
                    },
                    enabled = {
                        type = "toggle",
                        name = "Enable Auto-Show",
                        desc = "Automatically show watch frame when entering this instance",
                        get = function() return GetInstanceSetting(instanceId, "enabled", true) end,
                        set = function(_, value)
                            SetInstanceSetting(instanceId, "enabled", value)
                            KOL:PrintTag(data.name .. " auto-show: " .. (value and GREEN("Enabled") or RED("Disabled")))
                        end,
                        width = "full",
                        order = 2,
                    },

                    -- Custom Zone Text
                    customZoneText = {
                        type = "input",
                        name = "Custom Zone Text",
                        desc = "Override the default title text (leave empty to use default: " .. data.name .. ")",
                        get = function() return GetInstanceSetting(instanceId, "titleText", "") end,
                        set = function(_, value)
                            SetInstanceSetting(instanceId, "titleText", value)
                            KOL:PrintTag("Title text updated for: " .. data.name)
                        end,
                        width = "full",
                        order = 5,
                    },

                -- Colors Group
                colorsGroup = {
                    type = "group",
                    name = "Colors",
                    inline = true,
                    order = 10,
                    args = {
                        titleFontColor = {
                            type = "color",
                            name = "Title Font Color",
                            desc = "Color of the title text",
                            hasAlpha = false,
                            get = function()
                                local color = GetInstanceSetting(instanceId, "titleFontColor", nil)
                                if color then
                                    return color[1], color[2], color[3]
                                end
                                -- Default to instance color
                                local colorName = data.color or "PINK"
                                local rgb = KOL.Colors:GetPastel(colorName)
                                return rgb[1], rgb[2], rgb[3]
                            end,
                            set = function(_, r, g, b)
                                SetInstanceSetting(instanceId, "titleFontColor", {r, g, b})
                            end,
                            order = 1,
                        },
                        groupIncompleteColor = {
                            type = "color",
                            name = "Group Header Incomplete Color",
                            desc = "Color for group headers when not all bosses are killed",
                            hasAlpha = false,
                            get = function()
                                local color = GetInstanceSetting(instanceId, "groupIncompleteColor", nil)
                                if color then
                                    return color[1], color[2], color[3]
                                end
                                -- Default to instance color
                                local colorName = data.color or "PINK"
                                local rgb = KOL.Colors:GetPastel(colorName)
                                return rgb[1], rgb[2], rgb[3]
                            end,
                            set = function(_, r, g, b)
                                SetInstanceSetting(instanceId, "groupIncompleteColor", {r, g, b})
                            end,
                            order = 2,
                        },
                        groupCompleteColor = {
                            type = "color",
                            name = "Group Header Complete Color",
                            desc = "Color for group headers when all bosses are killed",
                            hasAlpha = false,
                            get = function()
                                local color = GetInstanceSetting(instanceId, "groupCompleteColor", nil)
                                if color then
                                    return color[1], color[2], color[3]
                                end
                                return 0.75, 1, 0.75  -- Default Pastel Easter Green
                            end,
                            set = function(_, r, g, b)
                                SetInstanceSetting(instanceId, "groupCompleteColor", {r, g, b})
                            end,
                            order = 3,
                        },
                        objectiveIncompleteColor = {
                            type = "color",
                            name = "Objective Incomplete Color",
                            desc = "Color for bosses/objectives that are not yet completed",
                            hasAlpha = false,
                            get = function()
                                local color = GetInstanceSetting(instanceId, "objectiveIncompleteColor", nil)
                                if color then
                                    return color[1], color[2], color[3]
                                end
                                return 1, 0.6, 0.6  -- Default Pastel Red
                            end,
                            set = function(_, r, g, b)
                                SetInstanceSetting(instanceId, "objectiveIncompleteColor", {r, g, b})
                            end,
                            order = 4,
                        },
                        objectiveCompleteColor = {
                            type = "color",
                            name = "Objective Complete Color",
                            desc = "Color for bosses/objectives that are completed",
                            hasAlpha = false,
                            get = function()
                                local color = GetInstanceSetting(instanceId, "objectiveCompleteColor", nil)
                                if color then
                                    return color[1], color[2], color[3]
                                end
                                return 0.7, 1, 0.7  -- Default Pastel Green
                            end,
                            set = function(_, r, g, b)
                                SetInstanceSetting(instanceId, "objectiveCompleteColor", {r, g, b})
                            end,
                            order = 5,
                        },
                    }
                },

                -- Fonts Group
                fontsGroup = {
                    type = "group",
                    name = "Fonts",
                    inline = true,
                    order = 15,
                    args = {
                        globalFont = {
                            type = "select",
                            name = "Global Font",
                            desc = "Default font for all text (used when specific fonts are not set)",
                            dialogControl = "LSM30_Font",
                            values = LibStub("LibSharedMedia-3.0"):HashTable("font"),
                            get = function() return GetInstanceSetting(instanceId, "globalFont", KOL.db.profile.generalFont or "Friz Quadrata TT") end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "globalFont", value)
                            end,
                            order = 1,
                            width = "double",
                        },
                        fontScale = {
                            type = "range",
                            name = "Font Scale (All Content)",
                            desc = "Scale multiplier for ALL fonts",
                            min = 0.5,
                            max = 2.0,
                            step = 0.05,
                            get = function() return GetInstanceSetting(instanceId, "fontScale", 1.0) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "fontScale", value)
                            end,
                            order = 1.5,
                            width = "normal",
                        },
                        globalFontOutline = {
                            type = "select",
                            name = "Global Outline",
                            desc = "Default outline style for all text (used when specific outlines are not set)",
                            values = {
                                ["NONE"] = "None",
                                ["OUTLINE"] = "Outline",
                                ["THICKOUTLINE"] = "Thick Outline",
                            },
                            get = function() return GetInstanceSetting(instanceId, "globalFontOutline", "OUTLINE") end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "globalFontOutline", value)
                            end,
                            order = 1.7,
                            width = "normal",
                        },
                        spacer1 = {
                            type = "description",
                            name = "\n|cFFFFFFFFSpecific Font Settings:|r",
                            order = 2.5,
                        },
                        titleFont = {
                            type = "select",
                            name = "Title Bar Font",
                            desc = "Font for title bar (leave empty to use Global Font)",
                            dialogControl = "LSM30_Font",
                            values = function()
                                local fonts = LibStub("LibSharedMedia-3.0"):HashTable("font")
                                fonts[""] = "Use Global Font"
                                return fonts
                            end,
                            get = function() return GetInstanceSetting(instanceId, "titleFont", "") end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "titleFont", value ~= "" and value or nil)
                            end,
                            order = 3,
                            width = "double",
                        },
                        titleFontSize = {
                            type = "range",
                            name = "Title Bar Size",
                            desc = "Font size for title bar (0 = auto, min: 8, max: 32)",
                            min = 0,
                            max = 32,
                            step = 1,
                            get = function() return GetInstanceSetting(instanceId, "titleFontSize", 0) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "titleFontSize", value > 0 and value or nil)
                            end,
                            order = 4,
                            width = "normal",
                        },
                        titleFontOutline = {
                            type = "select",
                            name = "Title Bar Outline",
                            desc = "Outline style for title bar (leave empty to use Global Outline)",
                            values = {
                                [""] = "Use Global Outline",
                                ["NONE"] = "None",
                                ["OUTLINE"] = "Outline",
                                ["THICKOUTLINE"] = "Thick Outline",
                                ["MONOCHROME"] = "Monochrome",
                                ["OUTLINE, MONOCHROME"] = "Outline + Monochrome",
                            },
                            get = function() return GetInstanceSetting(instanceId, "titleFontOutline", "") end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "titleFontOutline", value ~= "" and value or nil)
                            end,
                            order = 5,
                            width = "normal",
                        },
                        groupFont = {
                            type = "select",
                            name = "Group Header Font",
                            desc = "Font for group headers (leave empty to use Global Font)",
                            dialogControl = "LSM30_Font",
                            values = function()
                                local fonts = LibStub("LibSharedMedia-3.0"):HashTable("font")
                                fonts[""] = "Use Global Font"
                                return fonts
                            end,
                            get = function() return GetInstanceSetting(instanceId, "groupFont", "") end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "groupFont", value ~= "" and value or nil)
                            end,
                            order = 6,
                            width = "double",
                        },
                        groupFontSize = {
                            type = "range",
                            name = "Group Header Size",
                            desc = "Font size for group headers (0 = auto, min: 8, max: 32)",
                            min = 0,
                            max = 32,
                            step = 1,
                            get = function() return GetInstanceSetting(instanceId, "groupFontSize", 0) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "groupFontSize", value > 0 and value or nil)
                            end,
                            order = 7,
                            width = "normal",
                        },
                        groupFontOutline = {
                            type = "select",
                            name = "Group Header Outline",
                            desc = "Outline style for group headers (leave empty to use Global Outline)",
                            values = {
                                [""] = "Use Global Outline",
                                ["NONE"] = "None",
                                ["OUTLINE"] = "Outline",
                                ["THICKOUTLINE"] = "Thick Outline",
                                ["MONOCHROME"] = "Monochrome",
                                ["OUTLINE, MONOCHROME"] = "Outline + Monochrome",
                            },
                            get = function() return GetInstanceSetting(instanceId, "groupFontOutline", "") end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "groupFontOutline", value ~= "" and value or nil)
                            end,
                            order = 8,
                            width = "normal",
                        },
                        objectiveFont = {
                            type = "select",
                            name = "Objective Font",
                            desc = "Font for boss names/objectives (leave empty to use Global Font)",
                            dialogControl = "LSM30_Font",
                            values = function()
                                local fonts = LibStub("LibSharedMedia-3.0"):HashTable("font")
                                fonts[""] = "Use Global Font"
                                return fonts
                            end,
                            get = function() return GetInstanceSetting(instanceId, "objectiveFont", "") end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "objectiveFont", value ~= "" and value or nil)
                            end,
                            order = 9,
                            width = "double",
                        },
                        objectiveFontSize = {
                            type = "range",
                            name = "Objective Size",
                            desc = "Font size for boss names/objectives (0 = auto, min: 8, max: 32)",
                            min = 0,
                            max = 32,
                            step = 1,
                            get = function() return GetInstanceSetting(instanceId, "objectiveFontSize", 0) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "objectiveFontSize", value > 0 and value or nil)
                            end,
                            order = 10,
                            width = "normal",
                        },
                        objectiveFontOutline = {
                            type = "select",
                            name = "Objective Outline",
                            desc = "Outline style for boss names/objectives (leave empty to use Global Outline)",
                            values = {
                                [""] = "Use Global Outline",
                                ["NONE"] = "None",
                                ["OUTLINE"] = "Outline",
                                ["THICKOUTLINE"] = "Thick Outline",
                                ["MONOCHROME"] = "Monochrome",
                                ["OUTLINE, MONOCHROME"] = "Outline + Monochrome",
                            },
                            get = function() return GetInstanceSetting(instanceId, "objectiveFontOutline", "") end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "objectiveFontOutline", value ~= "" and value or nil)
                            end,
                            order = 11,
                            width = "normal",
                        },
                    }
                },

                -- UI Colors Group
                uiColors = {
                    type = "group",
                    name = "UI Element Colors",
                    inline = true,
                    order = 20,
                    args = {
                        backgroundColor = {
                            type = "color",
                            name = "Background Color",
                            desc = "Main frame background color",
                            hasAlpha = true,
                            get = function()
                                local color = GetInstanceSetting(instanceId, "backgroundColor", nil)
                                if color then
                                    return color[1], color[2], color[3], color[4] or 0.95
                                end
                                return 0.05, 0.05, 0.05, 0.95
                            end,
                            set = function(_, r, g, b, a)
                                SetInstanceSetting(instanceId, "backgroundColor", {r, g, b, a})
                            end,
                            order = 1,
                        },
                        borderColor = {
                            type = "color",
                            name = "Border Color",
                            desc = "Frame border color",
                            hasAlpha = true,
                            get = function()
                                local color = GetInstanceSetting(instanceId, "borderColor", nil)
                                if color then
                                    return color[1], color[2], color[3], color[4] or 1
                                end
                                return 0.2, 0.2, 0.2, 1
                            end,
                            set = function(_, r, g, b, a)
                                SetInstanceSetting(instanceId, "borderColor", {r, g, b, a})
                            end,
                            order = 2,
                        },
                        titleBarColor = {
                            type = "color",
                            name = "Title Bar Background",
                            desc = "Title bar background color",
                            hasAlpha = true,
                            get = function()
                                local color = GetInstanceSetting(instanceId, "titleBarColor", nil)
                                if color then
                                    return color[1], color[2], color[3], color[4] or 1
                                end
                                return 0.1, 0.1, 0.1, 1
                            end,
                            set = function(_, r, g, b, a)
                                SetInstanceSetting(instanceId, "titleBarColor", {r, g, b, a})
                            end,
                            order = 3,
                        },
                        scrollBarColor = {
                            type = "color",
                            name = "Scroll Bar Background",
                            desc = "Scroll bar background color",
                            hasAlpha = true,
                            get = function()
                                local color = GetInstanceSetting(instanceId, "scrollBarColor", nil)
                                if color then
                                    return color[1], color[2], color[3], color[4] or 0.9
                                end
                                return 0.1, 0.1, 0.1, 0.9
                            end,
                            set = function(_, r, g, b, a)
                                SetInstanceSetting(instanceId, "scrollBarColor", {r, g, b, a})
                            end,
                            order = 4,
                        },
                        scrollThumbColor = {
                            type = "color",
                            name = "Scroll Thumb Color",
                            desc = "Scroll bar thumb/slider color",
                            hasAlpha = true,
                            get = function()
                                local color = GetInstanceSetting(instanceId, "scrollThumbColor", nil)
                                if color then
                                    return color[1], color[2], color[3], color[4] or 1
                                end
                                return 0.3, 0.3, 0.3, 1
                            end,
                            set = function(_, r, g, b, a)
                                SetInstanceSetting(instanceId, "scrollThumbColor", {r, g, b, a})
                            end,
                            order = 5,
                        },
                        scrollBarBorderColor = {
                            type = "color",
                            name = "Scroll Bar Border",
                            desc = "Scroll bar border color",
                            hasAlpha = true,
                            get = function()
                                local color = GetInstanceSetting(instanceId, "scrollBarBorderColor", nil)
                                if color then
                                    return color[1], color[2], color[3], color[4] or 1
                                end
                                return 0.2, 0.2, 0.2, 1  -- Default dark gray
                            end,
                            set = function(_, r, g, b, a)
                                SetInstanceSetting(instanceId, "scrollBarBorderColor", {r, g, b, a})
                            end,
                            order = 6,
                        },
                    }
                },

                -- UI Visibility Group
                uiVisibility = {
                    type = "group",
                    name = "UI Visibility",
                    inline = true,
                    order = 30,
                    args = {
                        showBgOnHover = {
                            type = "toggle",
                            name = "Show Background on Mouseover Only",
                            desc = "Hide the frame background by default, show it only when hovering (floating text look)",
                            get = function() return GetInstanceSetting(instanceId, "showBgOnHover", false) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "showBgOnHover", value)
                                -- Also set the old values for compatibility
                                SetInstanceSetting(instanceId, "hideUI", value)
                                SetInstanceSetting(instanceId, "showUIOnMouseover", value)
                                KOL:PrintTag(data.name .. " Show BG on hover: " .. (value and GREEN("Enabled") or RED("Disabled")))
                            end,
                            width = "full",
                            order = 1,
                        },
                    }
                },

                -- Frame Control Group
                frameDimensions = {
                    type = "group",
                    name = "Frame Control",
                    inline = true,
                    order = 40,
                    args = {
                        frameWidth = {
                            type = "range",
                            name = "Frame Width",
                            desc = "Override frame width (0 = use default from instance data)",
                            min = 0,
                            max = 600,
                            step = 1,
                            get = function() return GetInstanceSetting(instanceId, "frameWidth", 0) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "frameWidth", value)
                                -- Refresh the watch frame to apply new size
                                if KOL.Tracker and KOL.Tracker.UpdateWatchFrame then
                                    KOL.Tracker:UpdateWatchFrame(instanceId)
                                end
                            end,
                            order = 1,
                        },
                        frameHeight = {
                            type = "range",
                            name = "Frame Height",
                            desc = "Override frame height (0 = use default from instance data)",
                            min = 0,
                            max = 800,
                            step = 1,
                            get = function() return GetInstanceSetting(instanceId, "frameHeight", 0) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "frameHeight", value)
                                -- Refresh the watch frame to apply new size
                                if KOL.Tracker and KOL.Tracker.UpdateWatchFrame then
                                    KOL.Tracker:UpdateWatchFrame(instanceId)
                                end
                            end,
                            order = 2,
                        },
                        scrollBarWidth = {
                            type = "range",
                            name = "Scrollbar Width",
                            desc = "Width of the scrollbar in pixels (0 = use global setting)",
                            min = 0,
                            max = 32,
                            step = 1,
                            get = function() return GetInstanceSetting(instanceId, "scrollBarWidth", 0) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "scrollBarWidth", value)
                                -- Refresh the watch frame to apply new size
                                if KOL.Tracker and KOL.Tracker.UpdateWatchFrame then
                                    KOL.Tracker:UpdateWatchFrame(instanceId)
                                end
                            end,
                            order = 3,
                        },
                        showScrollBar = {
                            type = "select",
                            name = "Scrollbar Visibility",
                            desc = "Control scrollbar visibility for this instance (Default = use global setting)",
                            values = {
                                ["default"] = "Default (Use Global)",
                                ["hidden"] = "Hidden",
                                ["visible"] = "Visible",
                            },
                            get = function()
                                local value = GetInstanceSetting(instanceId, "showScrollBar", nil)
                                if value == nil then
                                    return "default"
                                elseif value == true then
                                    return "visible"
                                else
                                    return "hidden"
                                end
                            end,
                            set = function(_, value)
                                if value == "default" then
                                    -- Clear the setting to use global
                                    if KOL.db.profile.tracker.instances and KOL.db.profile.tracker.instances[instanceId] then
                                        KOL.db.profile.tracker.instances[instanceId].showScrollBar = nil
                                    end
                                elseif value == "visible" then
                                    SetInstanceSetting(instanceId, "showScrollBar", true)
                                else -- "hidden"
                                    SetInstanceSetting(instanceId, "showScrollBar", false)
                                end

                                -- Refresh this frame to apply new visibility
                                if KOL.Tracker and KOL.Tracker.UpdateWatchFrame then
                                    KOL.Tracker:UpdateWatchFrame(instanceId)
                                end
                            end,
                            order = 4,
                        },
                    }
                },

                -- Actions Group (4 buttons on one row)
                actions = {
                    type = "group",
                    name = "Actions",
                    inline = true,
                    order = 50,
                    args = {
                        showFrame = {
                            type = "execute",
                            name = "Show",
                            desc = "Manually show the watch frame for this instance",
                            func = function()
                                if KOL.Tracker then
                                    KOL.Tracker:ShowWatchFrame(instanceId)
                                    KOL:PrintTag("Showing watch frame: " .. data.name)
                                end
                            end,
                            width = 0.4,
                            order = 1,
                        },
                        hideFrame = {
                            type = "execute",
                            name = "Hide",
                            desc = "Hide the watch frame for this instance",
                            func = function()
                                if KOL.Tracker then
                                    KOL.Tracker:HideWatchFrame(instanceId)
                                    KOL:PrintTag("Hidden watch frame: " .. data.name)
                                end
                            end,
                            width = 0.4,
                            order = 2,
                        },
                        resetProgress = {
                            type = "execute",
                            name = "Reset Progress",
                            desc = "Reset all boss kills for this instance",
                            func = function()
                                if KOL.Tracker then
                                    KOL.Tracker:ResetInstance(instanceId)
                                    KOL:PrintTag("Reset progress for: " .. data.name)
                                    -- Refresh config
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
                                end
                            end,
                            width = 0.55,
                            order = 3,
                            confirm = function()
                                return "Are you sure you want to reset all progress for " .. data.name .. "?"
                            end,
                        },
                        resetAllSettings = {
                            type = "execute",
                            name = "Reset All Settings",
                            desc = "Reset all customizations for this instance back to defaults (colors, fonts, dimensions, etc.)",
                            func = function()
                                -- Clear all instance-specific settings
                                if KOL.db.profile.tracker.instances and KOL.db.profile.tracker.instances[instanceId] then
                                    KOL.db.profile.tracker.instances[instanceId] = {}
                                    KOL:PrintTag("Reset all settings for: " .. data.name)

                                    -- Refresh the watch frame if it's active
                                    if KOL.Tracker and KOL.Tracker.UpdateWatchFrame then
                                        KOL.Tracker:UpdateWatchFrame(instanceId)
                                    end

                                    -- Refresh config UI
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
                                end
                            end,
                            width = 0.7,
                            order = 4,
                            confirm = function()
                                return "Are you sure you want to reset all customizations (colors, fonts, dimensions, etc.) for " .. data.name .. " back to defaults?"
                            end,
                        },
                    }
                },
            }
        }
            end  -- end if isCustomTracker else

        if data.type == "dungeon" then
            dungeonOrder = dungeonOrder + 1
        elseif data.type == "raid" then
            raidOrder = raidOrder + 1
        else
            customOrder = customOrder + 1
        end
        end  -- end if shouldShow
    end

    -- Add message if no instances shown
    if dungeonOrder == 10 then
        if dungeonFilterExpansion == "" then
            dungeonsArgs.noinstances = {
                type = "description",
                name = "|cFFFFDD00Please select an expansion above to view dungeons.|r",
                fontSize = "medium",
                order = 10,
            }
        else
            dungeonsArgs.noinstances = {
                type = "description",
                name = "|cFFAAAAAANo dungeons match the selected filters.|r",
                fontSize = "medium",
                order = 10,
            }
        end
    end

    if raidOrder == 10 then
        if raidFilterExpansion == "" then
            raidsArgs.noinstances = {
                type = "description",
                name = "|cFFFFDD00Please select an expansion above to view raids.|r",
                fontSize = "medium",
                order = 10,
            }
        else
            raidsArgs.noinstances = {
                type = "description",
                name = "|cFFAAAAAANo raids match the selected filters.|r",
                fontSize = "medium",
                order = 10,
            }
        end
    end

    -- Custom Trackers tab population - reorganized layout
    customArgs.header = {
        type = "description",
        name = "|cFFFFFFFFCustom Trackers|r\n|cFFAAAAAACreate and manage custom progress trackers.|r\n",
        fontSize = "medium",
        order = 0,
    }

    -- Management group - Select Tracker + Create/Edit/Delete
    customArgs.management = {
        type = "group",
        name = "Management",
        inline = true,
        order = 5,
        args = {
            selectInstance = {
                type = "select",
                name = "Select Tracker",
                desc = "Choose which custom tracker to configure",
                values = function()
                    local panels = {[""] = "-- Select Tracker --"}
                    if not KOL.Tracker or not KOL.Tracker.instances then
                        return panels
                    end
                    for instanceId, data in pairs(KOL.Tracker.instances) do
                        if data.type ~= "dungeon" and data.type ~= "raid" then
                            panels[instanceId] = data.name
                        end
                    end
                    return panels
                end,
                get = function()
                    return KOL.db.profile.tracker.selectedCustomInstance or ""
                end,
                set = function(_, value)
                    KOL.db.profile.tracker.selectedCustomInstance = value
                    KOL:PopulateTrackerConfigUI()
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                end,
                width = 1.0,
                order = 1,
            },
            createNew = {
                type = "execute",
                name = "Create",
                desc = "Create a new custom progress tracker",
                func = function()
                    if KOL.ShowTrackerManager then
                        KOL:ShowTrackerManager()
                    end
                end,
                width = 0.4,
                order = 2,
            },
            editPanel = {
                type = "execute",
                name = "Edit",
                desc = "Edit this custom tracker's entries and settings",
                func = function()
                    if selectedCustomInstance ~= "" and KOL.ShowTrackerManager then
                        KOL:ShowTrackerManager(selectedCustomInstance)
                    else
                        KOL:PrintTag("|cFFFF6600Select a tracker first!|r")
                    end
                end,
                width = 0.4,
                order = 3,
                disabled = function() return selectedCustomInstance == "" end,
            },
            deletePanel = {
                type = "execute",
                name = "Delete",
                desc = "Permanently delete this custom tracker",
                func = function()
                    if selectedCustomInstance == "" then return end
                    local panelName = KOL.Tracker.instances[selectedCustomInstance] and KOL.Tracker.instances[selectedCustomInstance].name or "Tracker"
                    StaticPopupDialogs["KOL_DELETE_CUSTOM_PANEL"] = {
                        text = "Are you sure you want to delete '" .. panelName .. "'?",
                        button1 = "Delete",
                        button2 = "Cancel",
                        OnAccept = function()
                            if KOL.Tracker.DeleteCustomPanel then
                                KOL.Tracker:DeleteCustomPanel(selectedCustomInstance)
                            end
                            KOL.db.profile.tracker.selectedCustomInstance = ""
                            KOL:PopulateTrackerConfigUI()
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                            KOL:PrintTag(RED("Deleted:") .. " " .. panelName)
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                    }
                    StaticPopup_Show("KOL_DELETE_CUSTOM_PANEL")
                end,
                width = 0.4,
                order = 4,
                disabled = function() return selectedCustomInstance == "" end,
            },
        },
    }

    -- Count custom trackers (check both Tracker.instances AND saved DB)
    local customPanelCount = 0
    for instanceId, data in pairs(KOL.Tracker.instances) do
        if data.type ~= "dungeon" and data.type ~= "raid" then
            customPanelCount = customPanelCount + 1
        end
    end
    -- Also check saved custom trackers in DB (in case Tracker.instances isn't populated yet)
    if customPanelCount == 0 and KOL.db.profile.tracker.customPanels then
        for _ in pairs(KOL.db.profile.tracker.customPanels) do
            customPanelCount = customPanelCount + 1
        end
    end

    if customPanelCount == 0 then
        customArgs.noTrackers = {
            type = "description",
            name = "|cFFAAAAAANo custom trackers created yet. Click 'Create' to get started.|r",
            fontSize = "medium",
            order = 6,
        }
    elseif selectedCustomInstance == "" then
        customArgs.selectPrompt = {
            type = "description",
            name = "|cFF88CCFFSelect a tracker from the dropdown above to view its configuration.|r",
            fontSize = "medium",
            order = 6,
        }
    end

    -- Update customOrder for proper tracking (start at 20 + count for proper ordering)
    customOrder = 20 + customPanelCount

    -- Calculate actual counts (subtract starting order)
    local actualDungeonCount = math.max(0, dungeonOrder - 10)
    local actualRaidCount = math.max(0, raidOrder - 10)

    KOL:DebugPrint("Tracker Config: Populated " .. actualDungeonCount .. " dungeons, " .. actualRaidCount .. " raids, and " .. customOrder .. " custom trackers", 2)
    KOL:DebugPrint("Tracker Config: Filters - Dungeons: " .. dungeonFilterExpansion .. "/" .. dungeonFilterDifficulty .. ", Raids: " .. raidFilterExpansion .. "/" .. raidFilterDifficulty, 3)
end

-- ============================================================================
-- Module Registration Functions
-- ============================================================================

-- Add a config group for a module
function KOL:UIAddConfigGroup(name, displayName, order)
    if not self.configGroups then
        self.configGroups = {}
    end

    if not self.configOptions then
        self:PrintTag(RED("Error:") .. " UI not initialized yet! Cannot add config group: " .. name)
        return nil
    end

    -- Create colored display name
    local coloredName = "|cFF" .. (order and rainbowColors[math.min(order, #rainbowColors)] or "88AAFF") .. displayName .. "|r"

    local group = {
        type = "group",
        name = coloredName,
        order = order or 50,
        args = {}
    }

    self.configGroups[name] = group

    -- Add directly to the stored options table (this is the key fix!)
    self.configOptions.args[name] = group

    self:DebugPrint("UI: Added config group '" .. name .. "' (order: " .. (order or 50) .. ")")

    return group
end

-- Add a header/title to a config group
function KOL:UIAddConfigTitle(groupName, key, text, order)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "header",
        name = text,
        order = order or 0,
    }
end

-- Add a description to a config group
function KOL:UIAddConfigDescription(groupName, key, text, order)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "description",
        name = text,
        fontSize = "medium",
        order = order or 0,
    }
end

-- Add a toggle (checkbox) option
function KOL:UIAddConfigToggle(groupName, key, params)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "toggle",
        name = params.name,
        desc = params.desc,
        get = params.get,
        set = params.set,
        width = params.width or "normal",
        order = params.order or 10,
    }
end

-- Add a slider option
function KOL:UIAddConfigSlider(groupName, key, params)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "range",
        name = params.name,
        desc = params.desc,
        min = params.min or 0,
        max = params.max or 100,
        step = params.step or 1,
        get = params.get,
        set = params.set,
        width = params.width or "normal",
        order = params.order or 10,
    }
end

-- Add a dropdown/select option
function KOL:UIAddConfigSelect(groupName, key, params)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "select",
        name = params.name,
        desc = params.desc,
        values = params.values,
        get = params.get,
        set = params.set,
        width = params.width or "normal",
        order = params.order or 10,
        style = params.style or "dropdown",
    }
end

-- Add a font selector using LibSharedMedia
function KOL:UIAddConfigFontSelect(groupName, key, params)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "select",
        name = params.name,
        desc = params.desc,
        dialogControl = "LSM30_Font",
        values = LSM:HashTable("font"),
        get = params.get,
        set = params.set,
        width = params.width or "double",
        order = params.order or 10,
    }
end

-- Add a text input field
function KOL:UIAddConfigInput(groupName, key, params)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "input",
        name = params.name,
        desc = params.desc,
        get = params.get,
        set = params.set,
        width = params.width or "normal",
        order = params.order or 10,
        multiline = params.multiline or false,
    }
end

-- Add a color picker
function KOL:UIAddConfigColor(groupName, key, params)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "color",
        name = params.name,
        desc = params.desc,
        hasAlpha = params.hasAlpha or false,
        get = params.get,
        set = params.set,
        width = params.width or "normal",
        order = params.order or 10,
    }
end

-- Add an execute button
function KOL:UIAddConfigExecute(groupName, key, params)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "execute",
        name = params.name,
        desc = params.desc,
        func = params.func,
        width = params.width or "normal",
        order = params.order or 10,
    }
end

-- Add a spacer
function KOL:UIAddConfigSpacer(groupName, key, order)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "description",
        name = " ",
        order = order or 50,
    }
end
