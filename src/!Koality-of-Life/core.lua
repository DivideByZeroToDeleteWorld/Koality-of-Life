-- ============================================================================
-- !Koality-of-Life: Core Essentials
-- ============================================================================
-- This file contains ONLY the absolute bare minimum needed for everything else:
--   - KOL addon object creation
--   - Database initialization
--   - Color functions (used everywhere)
--   - Mission-critical print functions (PrintTag, DebugPrint)
--
-- IMPORTANT: All functions here are available immediately to ALL modules
-- because core.lua loads FIRST in the .toc file.
--
-- Everything else (slash commands, events, etc.) is in main.lua
-- ============================================================================

local addonName = "!Koality-of-Life"

-- Get version from TOC file
local version = GetAddOnMetadata(addonName, "Version") or "Unknown"

-- Create main addon using AceAddon-3.0
KoalityOfLife = LibStub("AceAddon-3.0"):NewAddon("KoalityOfLife", "AceConsole-3.0", "AceEvent-3.0")
local KOL = KoalityOfLife

-- Store version for other modules to access
KOL.version = version
KOL.addonName = addonName

-- Default database structure
local defaults = {
    profile = {
        enabled = true,
        debug = false,
        debugLevel = 1,  -- 1 = minimal, 5 = maximum verbosity
        debugFont = "JetBrains Mono",  -- Default monospace font for debug console
        debugFontOutline = "THICKOUTLINE",
        debugMaxLines = 1000,  -- Maximum lines to keep in debug console (default: 1000, max: 10000)
        watchDeathsLevel = 0,  -- 0 = disabled, 1 = bosses only, 2 = elites+bosses, 3 = all mobs
        showPrints = false,  -- Controls PrintTag visibility (separate from debug)
        showSplash = true,  -- Show splash screen on login

        -- Command Blocks: Reusable code snippets that return values
        commandBlocks = {},

        -- Macro Updater: Auto-update macros out of combat
        macroUpdater = {
            macros = {},  -- { ["MacroName"] = { enabled = bool, commandBlock = "name", lastUpdated = time } }
        },
        -- Binds System: Configurable keybinding management
        binds = {
            enabled = true,
            showInCombat = false,
            groups = {
                configs = {name = "Configs", color = "STANDARD_GRAY", isSystem = true},
                general = {name = "General", color = "PASTEL_YELLOW", isSystem = true},
                -- User groups added dynamically
            },
            keybindings = {},
            profiles = {
                ["default"] = {
                    name = "Default Profile",
                    groups = {}, -- Group states per profile
                    keybindings = {}, -- Bind overrides per profile
                }
            },
            settings = {
                rememberInputs = true,
                instantProfileSwitch = false, -- Requires reload
                showNotifications = true,
            }
        },

        -- Tracker: Progress tracking for dungeons/raids
        tracker = {
            -- Font settings (defaults to Source Code Pro Bold for proper glyph support)
            baseFont = "Source Code Pro Bold",
            baseFontSize = 12,
            fontScale = 1.0,
            -- Filter settings
            dungeonFilterExpansion = "",
            dungeonFilterDifficulty = "all",
            selectedDungeonInstance = "",
            raidFilterExpansion = "",
            raidFilterDifficulty = "all",
            selectedRaidInstance = "",
        },

        -- Themes: UI theme management
        themes = {
            active = "Nuclear Zero",
            themes = {},  -- Registered themes stored here
        },
    }
}

-- ============================================================================
-- Print Functions
-- ============================================================================

function KOL:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(tostring(msg))
end

function KOL:ColorPrint(msg)
    -- Just pass through - colors are pre-formatted in the string
    DEFAULT_CHAT_FRAME:AddMessage(tostring(msg))
end

function KOL:PrintTag(msg, force)
    -- Only print if showPrints is enabled (suppresses chat spam when turned off)
    -- force = true bypasses this check for critical messages
    if not force and self.db and self.db.profile and not self.db.profile.showPrints then
        return
    end

    local rainbowTag = "|cFFFF0000K|cFFFF4400o|cFFFF8800a|cFFFFCC00l|cFFFFFF00i|cFFCCFF00t|cFF88FF00y|cFF44FF00-|cFF00FF00o|cFF00FF88f|cFF00FFFF-|cFF55AAFFL|cFF7799FFi|cFF8888FFf|cFFAA66FFe|r"
    DEFAULT_CHAT_FRAME:AddMessage("[" .. rainbowTag .. "] " .. tostring(msg))
end

-- Debug print function with levels
-- Level 0: CRITICAL - Always prints to BOTH chat AND debug console, bypassing all filters (for critical diagnostic info)
-- Level 1: Basic debug (default)
-- Level 2: Unused (reserved)
-- Level 3: Moderate detail (skip repetitive/aggressive logs)
-- Level 4: Unused (reserved)
-- Level 5: Maximum verbosity (everything)
function KOL:DebugPrint(msg, level)
    level = level or 1  -- Default to level 1 if not specified

    -- Level 0: CRITICAL - Always print to chat, bypass all debug settings
    if level == 0 then
        self:PrintTag("|cFFFF0000[DEBUG][CRITICAL]|r " .. tostring(msg))
        return
    end

    if self.db and self.db.profile and self.db.profile.debug then
        local currentLevel = self.db.profile.debugLevel or 1

        -- Only print if message level is within current debug level
        if level <= currentLevel then
            local levelColor = ""
            if level == 1 then
                levelColor = "|cFFFF6600"  -- Orange
            elseif level == 3 then
                levelColor = "|cFFFFAA00"  -- Yellow-orange
            elseif level == 5 then
                levelColor = "|cFFFFFF00"  -- Yellow
            else
                levelColor = "|cFFFF6600"  -- Default orange
            end

            self:PrintTag("|cFFFF6600[DEBUG]|r" .. levelColor .. "[" .. level .. "]|r " .. tostring(msg))
        end
    end
end

-- ============================================================================
-- Global Color Functions
-- ============================================================================
-- Color functions are now defined in modules/colors.lua
-- This provides user-customizable colors and a unified color system

-- ColorOutput function - handles unlimited arguments and outputs colored text
function ColorOutput(...)
    local output = ""

    -- Concatenate all arguments
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        if arg ~= nil then
            output = output .. tostring(arg)
        end
    end

    -- Output through KOL:Print to ensure proper color rendering
    if KoalityOfLife and KoalityOfLife.Print then
        KoalityOfLife:Print(output)
    else
        -- Fallback if addon isn't loaded yet
        DEFAULT_CHAT_FRAME:AddMessage(output)
    end
end

-- Create a shorter alias for convenience
CO = ColorOutput

-- ============================================================================
-- Database Initialization
-- ============================================================================

function KOL:OnInitialize()
    -- Initialize database with AceDB-3.0
    self.db = LibStub("AceDB-3.0"):New("KoalityOfLifeDB", defaults, true)

    self:DebugPrint("Core: Database initialized", 2)

    -- Initialize themes module after database is ready
    if self.Themes and self.Themes.Initialize then
        self:DebugPrint("Core: Calling Themes:Initialize()", 2)
        self.Themes:Initialize()
    else
        self:DebugPrint("Core: Themes module not available", 1)
    end

    -- Initialize objective tracking system
    if self.InitializeObjectives then
        self:InitializeObjectives()
        self:DebugPrint("Core: Objective tracking initialized", 2)
    end
end

-- Note: OnEnable, OnDisable, and other lifecycle functions are in main.lua
