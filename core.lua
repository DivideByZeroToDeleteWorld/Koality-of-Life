-- ============================================================================
-- Koality-of-Life: Core Essentials
-- ============================================================================
-- This file contains ONLY the absolute bare minimum needed for everything else:
--   - KOL addon object creation
--   - Database initialization
--   - Color functions (used everywhere)
--   - Basic print functions
--
-- Everything else (slash commands, events, etc.) is in main.lua
-- ============================================================================

local addonName = "Koality-of-Life"

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

        -- Command Blocks: Reusable code snippets that return values
        commandBlocks = {},

        -- Macro Updater: Auto-update macros out of combat
        macroUpdater = {
            macros = {},  -- { ["MacroName"] = { enabled = bool, commandBlock = "name", lastUpdated = time } }
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

function KOL:PrintTag(msg)
    local rainbowTag = "|cFFFF0000K|cFFFF4400o|cFFFF8800a|cFFFFCC00l|cFFFFFF00i|cFFCCFF00t|cFF88FF00y|cFF44FF00-|cFF00FF00o|cFF00FF88f|cFF00FFFF-|cFF55AAFFL|cFF7799FFi|cFF8888FFf|cFFAA66FFe|r"
    DEFAULT_CHAT_FRAME:AddMessage("[" .. rainbowTag .. "] " .. tostring(msg))
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
end

-- Note: OnEnable, OnDisable, and other lifecycle functions are in main.lua
