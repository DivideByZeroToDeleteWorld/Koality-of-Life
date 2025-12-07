-- Koality-of-Life: UI and Configuration System
-- Professional configuration interface using AceConfig-3.0

local addonName = "Koality-of-Life"
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
                            -- Update memory usage (with safety check for API availability)
                            local mem = 0
                            local memMB = 0
                            if UpdateAddOnMemoryUsage and GetAddOnMemoryUsage then
                                UpdateAddOnMemoryUsage()
                                mem = GetAddOnMemoryUsage("Koality-of-Life") or 0
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
                            end

                            return string.format(
                                "|cFFFFDD00Memory Usage:|r %s%s|r\n" ..
                                "|cFFFFDD00Batch Channels:|r |cFF88DDFF%d running|r / |cFFAAAA00%d total|r\n" ..
                                "|cFFFFDD00Debug Messages:|r |cFFAAAA00%d|r / |cFF888888%d max|r",
                                memColor, memText,
                                runningChannels, totalChannels,
                                debugCount, debugMax
                            )
                        end,
                        fontSize = "medium",
                        order = 13,
                    },
                    refreshStats = {
                        type = "execute",
                        name = "Refresh Stats",
                        desc = "Manually refresh performance statistics (auto-refreshes every 2 seconds)",
                        func = function()
                            -- Force refresh by notifying AceConfigRegistry
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("Koality-of-Life")
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
            colors = {
                type = "group",
                name = "|cFFFF88CCColors|r",
                order = 5,
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
                        name = "|cFFAAAAAAAAvailable via color functions: RED(), GREEN(), YELLOW(), etc.|r\n",
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
                    customHeader = {
                        type = "header",
                        name = "Custom Colors",
                        order = 7,
                    },
                    customDesc = {
                        type = "description",
                        name = "|cFFAAAAAACreate your own named colors for use in custom watch frames and other features.|r\n",
                        order = 8,
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
                        order = 9,
                    },
                    customColors = {
                        type = "group",
                        name = " ",
                        inline = true,
                        order = 10,
                        args = {},  -- Will be populated dynamically
                    },
                    resetHeader = {
                        type = "header",
                        name = "Reset Colors",
                        order = 11,
                    },
                    resetAll = {
                        type = "execute",
                        name = "Reset All Colors to Defaults",
                        desc = "Reset all color customizations back to default values",
                        func = function()
                            if KOL.Colors then
                                KOL.Colors:ResetAll()
                                -- Refresh config
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("Koality-of-Life")
                            end
                        end,
                        width = "full",
                        order = 12,
                        confirm = function()
                            return "Are you sure you want to reset all colors to defaults? This cannot be undone."
                        end,
                    },
                }
            },
            tracker = {
                type = "group",
                name = "|cFF66FFCCProgress Tracker|r",
                order = 6,
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
                            hideUI = {
                                type = "toggle",
                                name = "Hide UI Elements",
                                desc = "Hide all UI elements (background, borders, scrollbar, minimize button, titlebar background)",
                                get = function()
                                    return KOL.db.profile.tracker and KOL.db.profile.tracker.hideUI or false
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.hideUI = value
                                    KOL:PrintTag("Hide UI: " .. (value and GREEN("Enabled") or RED("Disabled")))
                                end,
                                width = "full",
                                order = 5,
                            },
                            showUIOnMouseover = {
                                type = "toggle",
                                name = "Show UI On Mouseover",
                                desc = "Show all hidden UI elements when mouse hovers over the watch frame (only works when 'Hide UI Elements' is enabled)",
                                disabled = function()
                                    return not (KOL.db.profile.tracker and KOL.db.profile.tracker.hideUI)
                                end,
                                get = function()
                                    return KOL.db.profile.tracker and KOL.db.profile.tracker.showUIOnMouseover or false
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.showUIOnMouseover = value
                                    KOL:PrintTag("Show UI on mouseover: " .. (value and GREEN("Enabled") or RED("Disabled")))
                                end,
                                width = "full",
                                order = 6,
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
                                name = "Frame Dimensions",
                                order = 12,
                            },
                            frameWidth = {
                                type = "range",
                                name = "Default Frame Width",
                                desc = "Default width for watch frames (in pixels)",
                                min = 150,
                                max = 500,
                                step = 10,
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.frameWidth) or 250
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.frameWidth = value
                                end,
                                order = 13,
                            },
                            frameHeight = {
                                type = "range",
                                name = "Default Frame Height",
                                desc = "Default height for watch frames when maximized (in pixels)",
                                min = 100,
                                max = 800,
                                step = 10,
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.frameHeight) or 300
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.frameHeight = value
                                end,
                                order = 14,
                            },
                            scrollBarWidth = {
                                type = "range",
                                name = "Scrollbar Width",
                                desc = "Width of the scrollbar (in pixels)",
                                min = 8,
                                max = 32,
                                step = 2,
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
                                order = 15,
                            },
                            spacer1 = {
                                type = "description",
                                name = " ",
                                order = 16,
                            },
                            fontHeader = {
                                type = "header",
                                name = "Font Settings",
                                order = 17,
                            },
                            baseFont = {
                                type = "select",
                                name = "Watch Frame Font",
                                desc = "Font used for watch frame text (averaged with General Font)",
                                dialogControl = "LSM30_Font",
                                values = LibStub("LibSharedMedia-3.0"):HashTable("font"),
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.baseFont) or "Friz Quadrata TT"
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.baseFont = value
                                    KOL:PrintTag("Tracker font set to: " .. PASTEL_YELLOW(value))
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 18,
                            },
                            baseFontSize = {
                                type = "range",
                                name = "Base Font Size",
                                desc = "Base font size for watch frames (averaged with General Font Size)",
                                min = 8,
                                max = 24,
                                step = 1,
                                get = function()
                                    return (KOL.db.profile.tracker and KOL.db.profile.tracker.baseFontSize) or 12
                                end,
                                set = function(_, value)
                                    if not KOL.db.profile.tracker then
                                        KOL.db.profile.tracker = {}
                                    end
                                    KOL.db.profile.tracker.baseFontSize = value
                                    -- Refresh all active frames
                                    if KOL.Tracker then
                                        for instanceId, _ in pairs(KOL.Tracker.activeFrames) do
                                            KOL.Tracker:UpdateWatchFrame(instanceId)
                                        end
                                    end
                                end,
                                order = 19,
                            },
                            fontScale = {
                                type = "range",
                                name = "Font Scale Multiplier",
                                desc = "Scale multiplier for all tracker fonts",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
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
                                order = 20,
                            },
                            spacer2 = {
                                type = "description",
                                name = " ",
                                order = 21,
                            },
                            resetHeader = {
                                type = "header",
                                name = "Reset Progress",
                                order = 22,
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
                                      "|cFFCCCCCC/kol tracker reset|r - Reset all boss kills|r",
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
                            filterExpansion = {
                                type = "select",
                                name = "Show Expansion",
                                desc = "Select which expansion's dungeons to display",
                                values = {
                                    [""] = "-- Select Expansion --",
                                    classic = "Classic",
                                    tbc = "The Burning Crusade",
                                    wotlk = "Wrath of the Lich King",
                                    all = "All Expansions (Slow!)",
                                },
                                get = function()
                                    return KOL.db.profile.tracker.dungeonFilterExpansion or ""
                                end,
                                set = function(_, value)
                                    KOL.db.profile.tracker.dungeonFilterExpansion = value
                                    KOL:PopulateTrackerConfigUI()
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("Koality-of-Life")
                                end,
                                order = 1,
                            },
                            filterDifficulty = {
                                type = "select",
                                name = "Show Difficulty",
                                desc = "Filter dungeons by difficulty",
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
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("Koality-of-Life")
                                end,
                                order = 2,
                            },
                            spacer = {
                                type = "description",
                                name = " ",
                                order = 3,
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
                            filterExpansion = {
                                type = "select",
                                name = "Show Expansion",
                                desc = "Select which expansion's raids to display",
                                values = {
                                    [""] = "-- Select Expansion --",
                                    classic = "Classic",
                                    tbc = "The Burning Crusade",
                                    wotlk = "Wrath of the Lich King",
                                    all = "All Expansions (Slow!)",
                                },
                                get = function()
                                    return KOL.db.profile.tracker.raidFilterExpansion or ""
                                end,
                                set = function(_, value)
                                    KOL.db.profile.tracker.raidFilterExpansion = value
                                    KOL:PopulateTrackerConfigUI()
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("Koality-of-Life")
                                end,
                                order = 1,
                            },
                            filterDifficulty = {
                                type = "select",
                                name = "Show Size/Difficulty",
                                desc = "Filter raids by size and difficulty",
                                values = function()
                                    local expansion = KOL.db.profile.tracker.raidFilterExpansion or "all"
                                    if expansion == "classic" then
                                        return {
                                            all = "All Sizes",
                                            ["20"] = "20-Player",
                                            ["40"] = "40-Player",
                                        }
                                    elseif expansion == "tbc" then
                                        return {
                                            all = "All Sizes",
                                            ["10"] = "10-Player",
                                            ["25"] = "25-Player",
                                        }
                                    elseif expansion == "wotlk" then
                                        return {
                                            all = "All Sizes/Difficulties",
                                            ["10n"] = "10-Player Normal",
                                            ["25n"] = "25-Player Normal",
                                            ["10h"] = "10-Player Heroic",
                                            ["25h"] = "25-Player Heroic",
                                        }
                                    else  -- all
                                        return {
                                            all = "All Sizes/Difficulties",
                                            ["10"] = "10-Player",
                                            ["20"] = "20-Player",
                                            ["25"] = "25-Player",
                                            ["40"] = "40-Player",
                                            ["10n"] = "10-Player Normal",
                                            ["25n"] = "25-Player Normal",
                                            ["10h"] = "10-Player Heroic",
                                            ["25h"] = "25-Player Heroic",
                                        }
                                    end
                                end,
                                get = function()
                                    return KOL.db.profile.tracker.raidFilterDifficulty or "all"
                                end,
                                set = function(_, value)
                                    KOL.db.profile.tracker.raidFilterDifficulty = value
                                    KOL:PopulateTrackerConfigUI()
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("Koality-of-Life")
                                end,
                                order = 2,
                            },
                            spacer = {
                                type = "description",
                                name = " ",
                                order = 3,
                            },
                            -- Raid instances will be populated below this
                        }
                    },
                    custom = {
                        type = "group",
                        name = "|cFFFFAA00Custom Panels|r",
                        order = 4,
                        args = {
                            -- Will be populated dynamically by PopulateTrackerConfigUI()
                        }
                    },
                }
            },
        }
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

    -- Initialize batch UI (if batch-ui.lua is loaded)
    if self.InitializeBatchUI then
        self:InitializeBatchUI()
    end

    -- Initialize Tweaks config UI (if tweaks.lua is loaded)
    if self.Tweaks and self.Tweaks.Initialize then
        self.Tweaks:Initialize()
    end

    -- Initialize Colors config UI (if colors.lua is loaded)
    if self.Colors then
        self.Colors:PopulateStandardColorsUI()
        self.Colors:PopulatePastelColorsUI()
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
    local raidFilterExpansion = KOL.db.profile.tracker.raidFilterExpansion or ""
    local raidFilterDifficulty = KOL.db.profile.tracker.raidFilterDifficulty or "all"

    -- Clear existing instance entries (keep filter UI)
    for k, _ in pairs(dungeonsArgs) do
        if k ~= "header" and k ~= "filterExpansion" and k ~= "filterDifficulty" and k ~= "spacer" then
            dungeonsArgs[k] = nil
        end
    end
    for k, _ in pairs(raidsArgs) do
        if k ~= "header" and k ~= "filterExpansion" and k ~= "filterDifficulty" and k ~= "spacer" then
            raidsArgs[k] = nil
        end
    end
    for k, _ in pairs(customArgs) do
        customArgs[k] = nil
    end

    local dungeonOrder = 10  -- Start after filter UI
    local raidOrder = 10
    local customOrder = 0

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

    -- Iterate through all registered instances
    for instanceId, data in pairs(KOL.Tracker.instances) do
        -- Only process if passes filters
        if PassesFilters(data) then
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
            end

            -- Create inline group for this instance
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

                -- Title Settings Group
                titleSettings = {
                    type = "group",
                    name = "Title Bar Settings",
                    inline = true,
                    order = 10,
                    args = {
                        titleText = {
                            type = "input",
                            name = "Custom Title Text",
                            desc = "Override the default title text (leave empty to use default: " .. data.name .. ")",
                            get = function() return GetInstanceSetting(instanceId, "titleText", "") end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "titleText", value)
                                KOL:PrintTag("Title text updated for: " .. data.name)
                            end,
                            width = "full",
                            order = 1,
                        },
                        titleFont = {
                            type = "select",
                            name = "Title Font",
                            desc = "Font for the title bar text",
                            dialogControl = "LSM30_Font",
                            values = LibStub("LibSharedMedia-3.0"):HashTable("font"),
                            get = function() return GetInstanceSetting(instanceId, "titleFont", KOL.db.profile.generalFont or "Friz Quadrata TT") end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "titleFont", value)
                            end,
                            order = 2,
                        },
                        titleFontSize = {
                            type = "range",
                            name = "Title Font Size",
                            desc = "Size of the title text",
                            min = 8,
                            max = 24,
                            step = 1,
                            get = function() return GetInstanceSetting(instanceId, "titleFontSize", 13) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "titleFontSize", value)
                            end,
                            order = 3,
                        },
                        titleFontScale = {
                            type = "range",
                            name = "Title Font Scale",
                            desc = "Scale multiplier for title font",
                            min = 0.5,
                            max = 2.0,
                            step = 0.05,
                            get = function() return GetInstanceSetting(instanceId, "titleFontScale", 1.0) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "titleFontScale", value)
                            end,
                            order = 4,
                        },
                        titleFontOutline = {
                            type = "select",
                            name = "Title Font Outline",
                            desc = "Outline style for title text",
                            values = {
                                ["NONE"] = "None",
                                ["OUTLINE"] = "Outline",
                                ["THICKOUTLINE"] = "Thick Outline",
                                ["MONOCHROME"] = "Monochrome",
                                ["OUTLINE, MONOCHROME"] = "Outline + Monochrome",
                                ["THICKOUTLINE, MONOCHROME"] = "Thick Outline + Monochrome",
                            },
                            get = function() return GetInstanceSetting(instanceId, "titleFontOutline", "THICKOUTLINE") end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "titleFontOutline", value)
                            end,
                            order = 5,
                        },
                        titleFontColor = {
                            type = "color",
                            name = "Title Font Color",
                            desc = "Color of the title text (supports hex input)",
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
                                local hex = KOL.Colors:ToHex({r, g, b})
                                KOL:PrintTag("Title color set to |cFF" .. hex .. "■■■|r")
                            end,
                            order = 6,
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
                    }
                },

                -- UI Visibility Group
                uiVisibility = {
                    type = "group",
                    name = "UI Visibility",
                    inline = true,
                    order = 30,
                    args = {
                        hideUI = {
                            type = "toggle",
                            name = "Hide UI Elements",
                            desc = "Hide all UI elements (background, borders, scrollbar, minimize button, titlebar background)",
                            get = function() return GetInstanceSetting(instanceId, "hideUI", false) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "hideUI", value)
                                KOL:PrintTag(data.name .. " Hide UI: " .. (value and GREEN("Enabled") or RED("Disabled")))
                            end,
                            width = "full",
                            order = 1,
                        },
                        showUIOnMouseover = {
                            type = "toggle",
                            name = "Show UI On Mouseover",
                            desc = "Show hidden UI elements when mouse hovers over the watch frame",
                            disabled = function() return not GetInstanceSetting(instanceId, "hideUI", false) end,
                            get = function() return GetInstanceSetting(instanceId, "showUIOnMouseover", false) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "showUIOnMouseover", value)
                                KOL:PrintTag(data.name .. " Show UI on mouseover: " .. (value and GREEN("Enabled") or RED("Disabled")))
                            end,
                            width = "full",
                            order = 2,
                        },
                    }
                },

                -- Frame Dimensions Group
                frameDimensions = {
                    type = "group",
                    name = "Frame Dimensions",
                    inline = true,
                    order = 40,
                    args = {
                        frameWidth = {
                            type = "range",
                            name = "Frame Width",
                            desc = "Width of the watch frame (0 = use global setting)",
                            min = 0,
                            max = 600,
                            step = 10,
                            get = function() return GetInstanceSetting(instanceId, "frameWidth", 0) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "frameWidth", value)
                            end,
                            order = 1,
                        },
                        frameHeight = {
                            type = "range",
                            name = "Frame Height",
                            desc = "Height of the watch frame (0 = use global setting)",
                            min = 0,
                            max = 800,
                            step = 10,
                            get = function() return GetInstanceSetting(instanceId, "frameHeight", 0) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "frameHeight", value)
                            end,
                            order = 2,
                        },
                        scrollBarWidth = {
                            type = "range",
                            name = "Scrollbar Width",
                            desc = "Width of the scrollbar in pixels (0 = use global setting, min 8, max 32)",
                            min = 0,
                            max = 32,
                            step = 2,
                            get = function() return GetInstanceSetting(instanceId, "scrollBarWidth", 0) end,
                            set = function(_, value)
                                SetInstanceSetting(instanceId, "scrollBarWidth", value)
                            end,
                            order = 3,
                        },
                    }
                },

                -- Actions Group
                actions = {
                    type = "group",
                    name = "Actions",
                    inline = true,
                    order = 50,
                    args = {
                        showFrame = {
                            type = "execute",
                            name = "Show Watch Frame",
                            desc = "Manually show the watch frame for this instance",
                            func = function()
                                if KOL.Tracker then
                                    KOL.Tracker:ShowWatchFrame(instanceId)
                                    KOL:PrintTag("Showing watch frame: " .. data.name)
                                end
                            end,
                            width = "half",
                            order = 1,
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
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("Koality-of-Life")
                                end
                            end,
                            width = "half",
                            order = 2,
                            confirm = function()
                                return "Are you sure you want to reset all progress for " .. data.name .. "?"
                            end,
                        },
                    }
                },
            }
        }

        -- Add Edit and Delete buttons for custom panels
        if data.type == "custom" then
            args[instanceId].args.spacer3 = {
                type = "description",
                name = " ",
                order = 8,
            }

            args[instanceId].args.editPanel = {
                type = "execute",
                name = "Edit Panel",
                desc = "Edit this custom panel (objectives, groups, zones, etc.)",
                func = function()
                    if KOL.ShowCustomPanelEditor then
                        KOL:ShowCustomPanelEditor(instanceId)
                    end
                end,
                width = "half",
                order = 9,
            }

            args[instanceId].args.deletePanel = {
                type = "execute",
                name = "Delete Panel",
                desc = "Permanently delete this custom panel",
                func = function()
                    if KOL.Tracker then
                        KOL.Tracker:DeleteCustomPanel(instanceId)
                    end
                end,
                width = "half",
                order = 10,
                confirm = function()
                    return "Are you sure you want to delete " .. data.name .. "? This cannot be undone."
                end,
            }
        end

            if data.type == "dungeon" then
                dungeonOrder = dungeonOrder + 1
            elseif data.type == "raid" then
                raidOrder = raidOrder + 1
            else
                customOrder = customOrder + 1
            end
        end  -- end if PassesFilters
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
                name = "|cFFAAAAAAAANo dungeons match the selected filters.|r",
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
                name = "|cFFAAAAAAAANo raids match the selected filters.|r",
                fontSize = "medium",
                order = 10,
            }
        end
    end

    -- Custom Panels tab population
    customArgs.header = {
        type = "description",
        name = "|cFFFFFFFFCustom Watch Panels|r\n|cFFAAAAAACreate custom tracking panels with your own objectives and boss groups.|r\n",
        fontSize = "medium",
        order = 0,
    }

    customArgs.createNew = {
        type = "execute",
        name = "Create New Custom Panel",
        desc = "Create a new custom watch panel",
        func = function()
            if KOL.ShowCustomPanelEditor then
                KOL:ShowCustomPanelEditor()
            end
        end,
        width = "full",
        order = 1,
    }

    customArgs.spacer = {
        type = "description",
        name = " ",
        order = 2,
    }

    if customOrder == 0 then
        customArgs.noinstances = {
            type = "description",
            name = "|cFFAAAAAAAANo custom panels created yet. Click 'Create New Custom Panel' to get started.|r",
            fontSize = "medium",
            order = 3,
        }
    end

    -- Calculate actual counts (subtract starting order)
    local actualDungeonCount = math.max(0, dungeonOrder - 10)
    local actualRaidCount = math.max(0, raidOrder - 10)

    KOL:DebugPrint("Tracker Config: Populated " .. actualDungeonCount .. " dungeons, " .. actualRaidCount .. " raids, and " .. customOrder .. " custom panels", 2)
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
