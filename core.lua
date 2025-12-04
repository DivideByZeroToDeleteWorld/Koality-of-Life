-- Koality-of-Life: Quality of Life improvements for Synastria
-- Author: Fostot

local addonName = "Koality-of-Life"

-- Get version from TOC file
local version = GetAddOnMetadata(addonName, "Version") or "Unknown"

-- Create main addon using AceAddon-3.0
KoalityOfLife = LibStub("AceAddon-3.0"):NewAddon("KoalityOfLife", "AceConsole-3.0", "AceEvent-3.0")
local KOL = KoalityOfLife

-- Store version for other modules to access
KOL.version = version
KOL.addonName = addonName

-- Store registered slash commands
KOL.slashCommands = {}

-- Default database structure
local defaults = {
    profile = {
        enabled = true,
        debug = false,
    }
}

-- ============================================================================
-- Slash Command Registration System
-- ============================================================================

-- Register a slash command that any module can use
-- Usage: KOL:RegisterSlashCommand("mycommand", functionToCall, "Description of command")
function KOL:RegisterSlashCommand(command, func, description)
    if not command or not func then
        self:PrintTag(RED("Error:") .. " Invalid slash command registration")
        return false
    end
    
    -- Normalize command to lowercase
    command = string.lower(command)
    
    -- Check for duplicates
    if self.slashCommands[command] then
        self:PrintTag(RED("Warning:") .. " Slash command '" .. command .. "' is already registered. Overwriting.")
    end
    
    -- Register the command
    self.slashCommands[command] = {
        func = func,
        description = description or "No description available"
    }
    
    self:DebugPrint("Registered slash command: " .. YELLOW(command))
    return true
end

-- Unregister a slash command
function KOL:UnregisterSlashCommand(command)
    command = string.lower(command)
    if self.slashCommands[command] then
        self.slashCommands[command] = nil
        self:DebugPrint("Unregistered slash command: " .. YELLOW(command))
        return true
    end
    return false
end

-- ============================================================================
-- Addon Initialization
-- ============================================================================

function KOL:OnInitialize()
    -- Initialize database with AceDB-3.0
    self.db = LibStub("AceDB-3.0"):New("KoalityOfLifeDB", defaults, true)

    -- Initialize UI and config system
    if self.InitializeUI then
        self:InitializeUI()
    end

    -- Register slash commands
    self:RegisterChatCommand("kol", "SlashCommand")
    self:RegisterChatCommand("koality", "SlashCommand")

    -- Register standalone difficulty commands
    self:RegisterChatCommand("r25h", function() self:SetRaidDifficulty(4, "25 Man Heroic") end)
    self:RegisterChatCommand("r25", function() self:SetRaidDifficulty(2, "25 Man Normal") end)
    self:RegisterChatCommand("r10h", function() self:SetRaidDifficulty(3, "10 Man Heroic") end)
    self:RegisterChatCommand("r10", function() self:SetRaidDifficulty(1, "10 Man Normal") end)
    self:RegisterChatCommand("d5h", function() self:SetDungeonDifficulty(2, "5 Player Heroic") end)
    self:RegisterChatCommand("d5", function() self:SetDungeonDifficulty(1, "5 Player Normal") end)
end

function KOL:OnEnable()
    self:PrintTag("v" .. version .. " loaded! Type " .. YELLOW("/kol") .. " or " .. YELLOW("/kol config") .. " for options.")
end

function KOL:OnDisable()
    -- Cleanup if needed
end

-- ============================================================================
-- Slash Command Handler
-- ============================================================================

function KOL:SlashCommand(input)
    input = string.trim(input or "")
    local args = {}
    
    for word in string.gmatch(input, "%S+") do
        table.insert(args, word)
    end
    
    local cmd = args[1] and string.lower(args[1]) or ""
    
    -- Remove the command from args, leaving only parameters
    table.remove(args, 1)
    
    -- Check if it's a registered command
    if cmd ~= "" and self.slashCommands[cmd] then
        local commandData = self.slashCommands[cmd]
        -- Call the registered function with the remaining arguments
        commandData.func(unpack(args))
        return
    end
    
    -- Built-in commands (these don't need registration)
    if not cmd or cmd == "" or cmd == "help" then
        self:PrintHelp()
    elseif cmd == "config" or cmd == "options" then
        self:OpenConfig()
    elseif cmd == "debug" then
        self:ToggleDebug()
    else
        self:PrintTag(RED("Unknown command: ") .. cmd)
        self:PrintTag("Type " .. YELLOW("/kol help") .. " for a list of commands")
    end
end

function KOL:PrintHelp()
    self:PrintTag("Available commands:")
    
    -- Built-in commands
    self:Print(YELLOW("/kol config") .. " - Open configuration panel")
    self:Print(YELLOW("/kol debug") .. " - Toggle debug mode")
    self:Print(YELLOW("/kol help") .. " - Show this help message")
    
    -- Registered commands (sorted alphabetically)
    local sortedCommands = {}
    for cmd, data in pairs(self.slashCommands) do
        table.insert(sortedCommands, {cmd = cmd, desc = data.description})
    end
    
    table.sort(sortedCommands, function(a, b) return a.cmd < b.cmd end)
    
    if #sortedCommands > 0 then
        self:Print(" ")
        self:Print("|cFF88AAFFModule Commands:|r")
        for _, cmdData in ipairs(sortedCommands) do
            self:Print(YELLOW("/kol " .. cmdData.cmd) .. " - " .. cmdData.desc)
        end
    end
end

function KOL:ToggleDebug()
    self.db.profile.debug = not self.db.profile.debug
    local status = self.db.profile.debug and GREEN("enabled") or RED("disabled")
    self:PrintTag("Debug mode " .. status)
end

function KOL:OpenConfig()
    -- Open the config dialog (handled by ui.lua)
    LibStub("AceConfigDialog-3.0"):Open("KoalityOfLife")
end

-- ============================================================================
-- Helper Functions
-- ============================================================================

function KOL:SafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        self:PrintTag(RED("Error:") .. " " .. tostring(err))
    end
    return success
end

-- Debug print function
function KOL:DebugPrint(...)
    if self.db.profile.debug then
        local msg = ""
        for i = 1, select("#", ...) do
            local arg = select(i, ...)
            msg = msg .. tostring(arg)
        end
        self:PrintTag("|cFFFF6600[DEBUG]|r " .. msg)  -- Orange warning color
    end
end

-- ============================================================================
-- Difficulty Setting Functions
-- ============================================================================

function KOL:SetRaidDifficulty(difficulty, diffName)
    -- Check if we're in a group/raid and if we have permission
    if IsInGroup() or IsInRaid() then
        if not IsRaidLeader() and not IsRaidOfficer() then
            self:PrintTag(RED("Error:") .. " You must be raid leader or assistant to change raid difficulty")
            return
        end
    end

    -- Set the difficulty
    SetRaidDifficulty(difficulty)
    self:PrintTag("Raid difficulty set to: " .. YELLOW(diffName))
    self:DebugPrint("SetRaidDifficulty(" .. difficulty .. ") called")
end

function KOL:SetDungeonDifficulty(difficulty, diffName)
    -- Check if we're in a group and if we have permission
    if IsInGroup() then
        if not IsPartyLeader() then
            self:PrintTag(RED("Error:") .. " You must be party leader to change dungeon difficulty")
            return
        end
    end

    -- Set the difficulty
    SetDungeonDifficulty(difficulty)
    self:PrintTag("Dungeon difficulty set to: " .. YELLOW(diffName))
    self:DebugPrint("SetDungeonDifficulty(" .. difficulty .. ") called")
end
