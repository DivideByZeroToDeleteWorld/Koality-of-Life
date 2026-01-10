-- !Koality-of-Life: Core Essentials
-- Loads FIRST - provides KOL, DB, PrintTag, DebugPrint
-- Everything else (slash commands, events) is in main.lua

local addonName = "!Koality-of-Life"
local version = KOL_VERSION or "Unknown"

KoalityOfLife = LibStub("AceAddon-3.0"):NewAddon("KoalityOfLife", "AceConsole-3.0", "AceEvent-3.0")
local KOL = KoalityOfLife

KOL.version = version
KOL.addonName = addonName

-- ============================================================================
-- Error Handler - Captures ALL Lua errors for the Errors viewer
-- ============================================================================

local originalErrorHandler = geterrorhandler()
local errorPrintEnabled = true

seterrorhandler(function(err)
    if KOL.Errors and KOL.Errors.AddError then
        KOL.Errors:AddError(err)
    end

    if errorPrintEnabled and err then
        local errStr = tostring(err)
        if string.find(errStr, "Koality") or string.find(errStr, "KOL") or string.find(errStr, "!Koality") then
            print("|cFFFF0000[KOL ERROR]|r " .. errStr)
        end
    end
    return originalErrorHandler(err)
end)

function KOL:ToggleErrorPrinting(enabled)
    errorPrintEnabled = enabled
    print("|cFFFFCC00[KoL]|r Error printing to chat: " .. (enabled and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
end

-- ============================================================================
-- Default Database Structure
-- ============================================================================

local defaults = {
    profile = {
        enabled = true,
        debug = false,
        debugLevel = 1,
        debugFont = "JetBrains Mono",
        debugFontOutline = "THICKOUTLINE",
        debugMaxLines = 1000,
        watchDeathsLevel = 0,
        showPrints = false,
        showSplash = true,
        limitDamage = false,

        racialPrimary = nil,
        racialSecondary = nil,
        currentRacial = nil,

        commandBlocks = {},

        macroUpdater = {
            macros = {},
        },

        binds = {
            enabled = true,
            showInCombat = false,
            groups = {
                configs = {name = "Configs", color = "STANDARD_GRAY", isSystem = true},
                general = {name = "General", color = "PASTEL_YELLOW", isSystem = true},
            },
            keybindings = {},
            profiles = {
                ["default"] = {
                    name = "Default Profile",
                    groups = {},
                    keybindings = {},
                }
            },
            settings = {
                rememberInputs = true,
                instantProfileSwitch = false,
                showNotifications = true,
            }
        },

        tracker = {
            baseFont = "Source Code Pro Bold",
            baseFontSize = 12,
            fontScale = 1.0,
            dungeonFilterExpansion = "",
            dungeonFilterDifficulty = "all",
            selectedDungeonInstance = "",
            raidFilterExpansion = "",
            raidFilterDifficulty = "all",
            selectedRaidInstance = "",
            autoShow = true,
        },

        themes = {
            active = "Furwin",
            themes = {},
        },

        tweaks = {
            fishing = {
                enabled = true,
                autoUse = true,
                autoCancel = true,
            },
        },
    },
    global = {
        buildManager = {
            miscPerksDisabled = {},
            miscSubOptionsDisabled = {},
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
    DEFAULT_CHAT_FRAME:AddMessage(tostring(msg))
end

function KOL:PrintTag(msg, force)
    if not force and self.db and self.db.profile and not self.db.profile.showPrints then
        return
    end

    local rainbowTag = "|cFFFF0000K|cFFFF4400o|cFFFF8800a|cFFFFCC00l|cFFFFFF00i|cFFCCFF00t|cFF88FF00y|cFF44FF00-|cFF00FF00o|cFF00FF88f|cFF00FFFF-|cFF55AAFFL|cFF7799FFi|cFF8888FFf|cFFAA66FFe|r"
    DEFAULT_CHAT_FRAME:AddMessage("[" .. rainbowTag .. "] " .. tostring(msg))
end

-- Debug levels: 0=CRITICAL (always), 1=basic, 3=moderate, 5=verbose
function KOL:DebugPrint(msg, level)
    level = level or 1

    if level == 0 then
        self:PrintTag("|cFFFF0000[DEBUG][CRITICAL]|r " .. tostring(msg))
        return
    end

    if self.db and self.db.profile and self.db.profile.debug then
        local currentLevel = self.db.profile.debugLevel or 1

        if level <= currentLevel then
            local levelColor = ""
            if level == 1 then
                levelColor = "|cFFFF6600"
            elseif level == 3 then
                levelColor = "|cFFFFAA00"
            elseif level == 5 then
                levelColor = "|cFFFFFF00"
            else
                levelColor = "|cFFFF6600"
            end

            self:PrintTag("|cFFFF6600[DEBUG]|r" .. levelColor .. "[" .. level .. "]|r " .. tostring(msg))
        end
    end
end

-- ============================================================================
-- Global Color Functions
-- ============================================================================

function ColorOutput(...)
    local output = ""

    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        if arg ~= nil then
            output = output .. tostring(arg)
        end
    end

    if KoalityOfLife and KoalityOfLife.Print then
        KoalityOfLife:Print(output)
    else
        DEFAULT_CHAT_FRAME:AddMessage(output)
    end
end

CO = ColorOutput

-- ============================================================================
-- Database Initialization
-- ============================================================================

function KOL:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("KoalityOfLifeDB", defaults, true)

    self:DebugPrint("Core: Database initialized", 2)

    if self.Themes and self.Themes.Initialize then
        self:DebugPrint("Core: Calling Themes:Initialize()", 2)
        self.Themes:Initialize()
    else
        self:DebugPrint("Core: Themes module not available", 1)
    end

    if self.InitializeObjectives then
        self:InitializeObjectives()
        self:DebugPrint("Core: Objective tracking initialized", 2)
    end
end
