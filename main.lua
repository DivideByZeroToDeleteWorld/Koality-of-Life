-- ============================================================================
-- Koality-of-Life: Main Systems
-- ============================================================================
-- This file contains all the main addon systems that depend on core.lua:
--   - Slash command registration system
--   - Event registration system
--   - Slash command handlers
--   - Debug functions
--   - Difficulty setting functions
--   - Event frame
-- ============================================================================

local KOL = KoalityOfLife

-- Store registered slash commands
KOL.slashCommands = {}

-- Store registered event callbacks
KOL.eventCallbacks = {}

-- ============================================================================
-- Slash Command Registration System
-- ============================================================================

-- Register a slash command that any module can use
-- Usage: KOL:RegisterSlashCommand("mycommand", functionToCall, "Description of command", "category")
-- Categories: nil/"module" (default), "test" (for test commands)
function KOL:RegisterSlashCommand(command, func, description, category)
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
        description = description or "No description available",
        category = category or "module"  -- Default to "module" category
    }

    self:DebugPrint("System: Registered slash command: " .. YELLOW(command) .. " (category: " .. (category or "module") .. ")")
    return true
end

-- Unregister a slash command
function KOL:UnregisterSlashCommand(command)
    command = string.lower(command)
    if self.slashCommands[command] then
        self.slashCommands[command] = nil
        self:DebugPrint("System: Unregistered slash command: " .. YELLOW(command))
        return true
    end
    return false
end

-- ============================================================================
-- Event Registration System
-- ============================================================================

-- Register a callback for a WoW event that any module can use
-- Usage: KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", myFunction, "MyModule")
function KOL:RegisterEventCallback(event, callback, moduleName)
    if not event or not callback then
        self:PrintTag(RED("Error:") .. " Invalid event callback registration")
        return false
    end

    -- Initialize event callback list if needed
    if not self.eventCallbacks[event] then
        self.eventCallbacks[event] = {}
    end

    -- Add callback to the event's list
    table.insert(self.eventCallbacks[event], {
        callback = callback,
        moduleName = moduleName or "Unknown"
    })

    self:DebugPrint("Registered event callback: " .. YELLOW(event) .. " for " .. (moduleName or "Unknown"))

    -- Register the event with our main frame if not already registered
    if self.eventFrame then
        self.eventFrame:RegisterEvent(event)
    end

    return true
end

-- Unregister all callbacks for a specific module
function KOL:UnregisterModuleEvents(moduleName)
    if not moduleName then return false end

    local removedCount = 0
    for event, callbacks in pairs(self.eventCallbacks) do
        for i = #callbacks, 1, -1 do
            if callbacks[i].moduleName == moduleName then
                table.remove(callbacks, i)
                removedCount = removedCount + 1
            end
        end
    end

    if removedCount > 0 then
        self:DebugPrint("Unregistered " .. removedCount .. " event callbacks for: " .. moduleName)
    end

    return true
end

-- Fire all registered callbacks for an event
function KOL:FireEventCallbacks(event, ...)
    if not self.eventCallbacks[event] then
        return
    end

    for _, callbackData in ipairs(self.eventCallbacks[event]) do
        local success, err = pcall(callbackData.callback, ...)
        if not success then
            self:PrintTag(RED("Error") .. " in " .. callbackData.moduleName .. " event handler (" .. event .. "): " .. tostring(err))
        end
    end
end

-- ============================================================================
-- Addon Lifecycle
-- ============================================================================

function KOL:OnEnable()
    -- Initialize UI and config system
    if self.InitializeUI then
        self:InitializeUI()
    end

    -- Register slash commands
    self:RegisterChatCommand("kol", "SlashCommand")
    self:RegisterChatCommand("koality", "SlashCommand")
    self:RegisterChatCommand("kt", "TestSlashCommand")  -- Alias for test commands
    self:RegisterChatCommand("kdc", function() self:ToggleDebugConsole() end)  -- Koality Debug Console
    self:RegisterChatCommand("kc", function()
        -- Open config panel
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)  -- Call twice for WoW 3.3.5a bug
    end)  -- Koality Config
    self:RegisterChatCommand("kcpt", function()
        -- Open config and navigate to Progress Tracker
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)  -- Call twice for WoW 3.3.5a bug
        -- Select the tracker tab
        LibStub("AceConfigDialog-3.0"):SelectGroup("Koality-of-Life", "tracker")
    end)  -- Koality Config Progress Tracker
    self:RegisterChatCommand("kmu", function()
        if KoalityOfLife.MacroUpdater then
            KoalityOfLife.MacroUpdater:ShowUI()
        end
    end)  -- Koality Macro Updater

    -- Register standalone difficulty commands
    self:RegisterChatCommand("r25h", function() self:SetRaidDifficulty(4, "25 Man Heroic") end)
    self:RegisterChatCommand("r25", function() self:SetRaidDifficulty(2, "25 Man Normal") end)
    self:RegisterChatCommand("r10h", function() self:SetRaidDifficulty(3, "10 Man Heroic") end)
    self:RegisterChatCommand("r10", function() self:SetRaidDifficulty(1, "10 Man Normal") end)
    self:RegisterChatCommand("d5h", function() self:SetDungeonDifficulty(2, "5 Player Heroic") end)
    self:RegisterChatCommand("d5", function() self:SetDungeonDifficulty(1, "5 Player Normal") end)

    self:DebugPrint("Koality-of-Life v" .. KOL.version .. " loaded", 1)
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
        self:ToggleDebug(args[1], args[2])
    else
        self:PrintTag(RED("Unknown command: ") .. cmd)
        self:PrintTag("Type " .. YELLOW("/kol help") .. " for a list of commands")
    end
end

-- Test slash command handler (/kt)
function KOL:TestSlashCommand(input)
    input = string.trim(input or "")
    local args = {}

    for word in string.gmatch(input, "%S+") do
        table.insert(args, word)
    end

    local cmd = args[1] and string.lower(args[1]) or ""

    -- Remove the command from args, leaving only parameters
    table.remove(args, 1)

    -- Check if it's a registered TEST command
    if cmd ~= "" and self.slashCommands[cmd] and self.slashCommands[cmd].category == "test" then
        local commandData = self.slashCommands[cmd]
        -- Call the registered function with the remaining arguments
        commandData.func(unpack(args))
        return
    end

    -- Show available test commands
    if not cmd or cmd == "" or cmd == "help" then
        self:PrintTag(PASTEL_PINK("Test Commands:"))

        local testCommands = {}
        for cmdName, data in pairs(self.slashCommands) do
            if data.category == "test" then
                table.insert(testCommands, {cmd = cmdName, desc = data.description})
            end
        end

        table.sort(testCommands, function(a, b) return a.cmd < b.cmd end)

        for _, cmdData in ipairs(testCommands) do
            self:Print(YELLOW("/kt " .. cmdData.cmd) .. " - " .. cmdData.desc)
        end

        if #testCommands == 0 then
            self:Print(GRAY("No test commands registered yet"))
        end
    else
        self:PrintTag(RED("Unknown test command: ") .. cmd)
        self:PrintTag("Type " .. YELLOW("/kt") .. " or " .. YELLOW("/kt help") .. " for a list of test commands")
    end
end

function KOL:PrintHelp()
    self:PrintTag("Available commands:")

    -- Built-in commands
    self:Print(YELLOW("/kol config") .. " - Open configuration panel")
    self:Print(YELLOW("/kol debug") .. " - Toggle debug mode")
    self:Print(YELLOW("/kol help") .. " - Show this help message")

    -- Separate commands by category
    local moduleCommands = {}
    local testCommands = {}

    for cmd, data in pairs(self.slashCommands) do
        if data.category == "test" then
            table.insert(testCommands, {cmd = cmd, desc = data.description})
        else
            table.insert(moduleCommands, {cmd = cmd, desc = data.description})
        end
    end

    -- Sort both lists alphabetically
    table.sort(moduleCommands, function(a, b) return a.cmd < b.cmd end)
    table.sort(testCommands, function(a, b) return a.cmd < b.cmd end)

    -- Show module commands
    if #moduleCommands > 0 then
        self:Print(" ")
        self:Print("|cFF88AAFFModule Commands:|r")
        for _, cmdData in ipairs(moduleCommands) do
            self:Print(YELLOW("/kol " .. cmdData.cmd) .. " - " .. cmdData.desc)
        end
    end

    -- Show test commands with pastel pink separator
    if #testCommands > 0 then
        self:Print(" ")
        self:Print(PASTEL_PINK("Tests:") .. " " .. GRAY("(also available via /kt)"))
        for _, cmdData in ipairs(testCommands) do
            self:Print(YELLOW("/kol " .. cmdData.cmd) .. " - " .. cmdData.desc)
        end
    end

    -- Show standalone shortcuts
    self:Print(" ")
    self:Print("|cFF00CCCCStandalone Shortcuts:|r")
    self:Print(YELLOW("/kmu") .. " - Open Macro Updater")
    self:Print(YELLOW("/kdc") .. " - Toggle Debug Console")
    self:Print(YELLOW("/kt") .. " - Show test commands")
    self:Print(YELLOW("/r25h") .. ", " .. YELLOW("/r25") .. ", " .. YELLOW("/r10h") .. ", " .. YELLOW("/r10") .. " - Set raid difficulty")
    self:Print(YELLOW("/d5h") .. ", " .. YELLOW("/d5") .. " - Set dungeon difficulty")
end

function KOL:ToggleDebug(arg1, arg2)
    -- /kol debug - toggle on/off
    -- /kol debug on - turn on
    -- /kol debug off - turn off
    -- /kol debug level 3 or /kol debug l 3 - set level

    if not arg1 then
        -- Simple toggle
        self.db.profile.debug = not self.db.profile.debug
        local status = self.db.profile.debug and GREEN("enabled") or RED("disabled")
        local level = self.db.profile.debugLevel or 1
        self:PrintTag("Debug mode " .. status .. " (Level " .. YELLOW(level) .. ")")
        return
    end

    arg1 = string.lower(arg1)

    if arg1 == "on" then
        self.db.profile.debug = true
        local level = self.db.profile.debugLevel or 1
        self:PrintTag("Debug mode " .. GREEN("enabled") .. " (Level " .. YELLOW(level) .. ")")
    elseif arg1 == "off" then
        self.db.profile.debug = false
        self:PrintTag("Debug mode " .. RED("disabled"))
    elseif arg1 == "level" or arg1 == "l" then
        if not arg2 then
            local level = self.db.profile.debugLevel or 1
            self:PrintTag("Current debug level: " .. YELLOW(level))
            self:Print("Usage: " .. YELLOW("/kol debug level [1-5]") .. " or " .. YELLOW("/kol debug l [1-5]"))
            return
        end

        local newLevel = tonumber(arg2)
        if newLevel and newLevel >= 1 and newLevel <= 5 then
            self.db.profile.debugLevel = newLevel
            self:PrintTag("Debug level set to: " .. YELLOW(newLevel))
            if not self.db.profile.debug then
                self:Print(GRAY("  (Debug mode is currently OFF - turn it on with /kol debug on)"))
            end

            -- Refresh debug console if it's open
            if self.RefreshDebugConsole then
                self:RefreshDebugConsole()
            end
        else
            self:PrintTag(RED("Error:") .. " Debug level must be between 1 and 5")
        end
    else
        self:PrintTag(RED("Error:") .. " Unknown debug command: " .. arg1)
        self:Print("Usage:")
        self:Print("  " .. YELLOW("/kol debug") .. " - Toggle debug mode on/off")
        self:Print("  " .. YELLOW("/kol debug on/off") .. " - Turn debug on or off")
        self:Print("  " .. YELLOW("/kol debug level [1-5]") .. " or " .. YELLOW("/kol debug l [1-5]") .. " - Set debug level")
    end
end

function KOL:OpenConfig()
    -- Open the config dialog (handled by ui.lua)
    LibStub("AceConfigDialog-3.0"):Open("KoalityOfLife")

    -- Start auto-refresh timer for performance stats (updates every 2 seconds)
    if not KOL.statsRefreshTimer then
        KOL.statsRefreshTimer = C_Timer.NewTicker(2, function()
            -- Check if config dialog is still open
            local ACD = LibStub("AceConfigDialog-3.0")
            if ACD.OpenFrames["KoalityOfLife"] then
                -- Notify config registry to refresh (updates dynamic stats)
                LibStub("AceConfigRegistry-3.0"):NotifyChange("Koality-of-Life")
            else
                -- Config closed, cancel timer
                if KOL.statsRefreshTimer then
                    KOL.statsRefreshTimer:Cancel()
                    KOL.statsRefreshTimer = nil
                end
            end
        end)
    end
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

-- ============================================================================
-- Event Frame
-- ============================================================================

-- Create main event handling frame
KOL.eventFrame = CreateFrame("Frame")
KOL.eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- Fire all registered callbacks for this event
    KOL:FireEventCallbacks(event, ...)
end)
