-- ============================================================================
-- !Koality-of-Life: Main Systems
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
        self:PrintTag(RED("Error:") .. " Invalid slash command registration", true)
        return false
    end

    -- Normalize command to lowercase
    command = string.lower(command)

    -- Check for duplicates
    if self.slashCommands[command] then
        self:DebugPrint("Slash command '" .. command .. "' is already registered. Overwriting.", 3)
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
        self:PrintTag(RED("Error:") .. " Invalid event callback registration", true)
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
            self:PrintTag(RED("Error") .. " in " .. callbackData.moduleName .. " event handler (" .. event .. "): " .. tostring(err), true)
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
    self:RegisterChatCommand("kcv", function() self:ToggleCharViewer() end)  -- Koality Character Viewer
    self:RegisterChatCommand("kld", function() self:ToggleLimitDamage() end)  -- Koality Limit Damage
    self:RegisterChatCommand("krs", function() self:ToggleRacial() end)  -- Koality Racial Swap
    self:RegisterChatCommand("kc", function(args)
        args = strtrim(args or ""):lower()
        if args == "showcase" then
            -- Show UI showcase demo frame
            if KOL.UIFactory and KOL.UIFactory.ShowUIShowcase then
                KOL.UIFactory:ShowUIShowcase()
            else
                self:PrintTag("UIFactory not loaded yet!")
            end
        elseif args == "ld" or args == "limitdamage" then
            -- Toggle Limit Damage
            self:ToggleLimitDamage()
        else
            -- Open config panel
            self:OpenConfig()
        end
    end)  -- Koality Config (with subcommands)
    self:RegisterChatCommand("kcpt", function()
        -- Open config and navigate to Progress Tracker
        self:OpenConfig()
        -- Select the tracker tab
        LibStub("AceConfigDialog-3.0"):SelectGroup("KoalityOfLife", "tracker")
    end)  -- Koality Config Progress Tracker
    self:RegisterChatCommand("kmu", function()
        if KoalityOfLife.MacroUpdater then
            KoalityOfLife.MacroUpdater:ShowUI()
        end
    end)  -- Koality Macro Updater

    -- Register standalone difficulty commands
    self:RegisterChatCommand("r25h", function() self:SetRaidDifficulty(4, "25 Man Heroic") end)
    self:RegisterChatCommand("r25n", function() self:SetRaidDifficulty(2, "25 Man Normal") end)
    self:RegisterChatCommand("r25", function() self:SetRaidDifficulty(2, "25 Man Normal") end)
    self:RegisterChatCommand("r20n", function() self:PrintTag("20-man raids (ZG, AQ20) use legacy difficulty - no setting needed.") end)
    self:RegisterChatCommand("r20", function() self:PrintTag("20-man raids (ZG, AQ20) use legacy difficulty - no setting needed.") end)
    self:RegisterChatCommand("r10h", function() self:SetRaidDifficulty(3, "10 Man Heroic") end)
    self:RegisterChatCommand("r10n", function() self:SetRaidDifficulty(1, "10 Man Normal") end)
    self:RegisterChatCommand("r10", function() self:SetRaidDifficulty(1, "10 Man Normal") end)
    self:RegisterChatCommand("d5h", function() self:SetDungeonDifficulty(2, "5 Player Heroic") end)
    self:RegisterChatCommand("d5n", function() self:SetDungeonDifficulty(1, "5 Player Normal") end)
    self:RegisterChatCommand("d5", function() self:SetDungeonDifficulty(1, "5 Player Normal") end)

    -- Reload UI shortcuts (force override any existing /rl command)
    SLASH_KOLRELOAD1 = "/rl"
    SLASH_KOLRELOAD2 = "/reloadui"
    SlashCmdList["KOLRELOAD"] = function() ReloadUI() end

    self:RegisterChatCommand("kwd", function(args)
        local level = tonumber(args)
        if level and level >= 0 and level <= 3 then
            self.db.profile.watchDeathsLevel = level
            local descriptions = {
                [0] = "Disabled",
                [1] = "Bosses only",
                [2] = "Elite mobs + Bosses",
                [3] = "All mobs (everything)"
            }
            self:PrintTag("Watch Deaths level set to " .. level .. " (" .. descriptions[level] .. ")")
        else
            local current = self.db.profile.watchDeathsLevel or 0
            local descriptions = {
                [0] = "Disabled",
                [1] = "Bosses only",
                [2] = "Elite mobs + Bosses",
                [3] = "All mobs (everything)"
            }
            self:PrintTag("Watch Deaths level: " .. current .. " (" .. descriptions[current] .. ")")
            self:PrintTag("Usage: /kwd [0-3]")
            self:PrintTag("  0 = Disabled (no output)")
            self:PrintTag("  1 = Bosses only")
            self:PrintTag("  2 = Elite mobs + Bosses")
            self:PrintTag("  3 = All mobs (everything)")
        end
    end)

    self:RegisterChatCommand("ksp", function(args)
        self:ShowPrints(args)
    end)

    -- Watch Frame Debug/Dump command
    self:RegisterChatCommand("kwfd", function()
        if not self.Tracker then
            self:PrintTag("Tracker module not loaded")
            return
        end

        local currentInstanceId = self.Tracker.currentInstanceId
        if not currentInstanceId then
            self:PrintTag("No active watch frame detected")
            return
        end

        local frame = self.Tracker.activeFrames[currentInstanceId]
        if not frame then
            self:PrintTag("Watch frame for " .. currentInstanceId .. " not found")
            return
        end

        local instanceData = self.Tracker.instances[currentInstanceId]
        if not instanceData then
            self:PrintTag("Instance data for " .. currentInstanceId .. " not found")
            return
        end

        self:PrintTag("========================================")
        self:PrintTag("Watch Frame Debug Info: " .. currentInstanceId)
        self:PrintTag("========================================")
        self:PrintTag("Instance Name: " .. (instanceData.name or "Unknown"))
        self:PrintTag(" ")

        -- Current dimensions
        local width = frame:GetWidth()
        local height = frame:GetHeight()
        self:PrintTag("CURRENT DIMENSIONS:")
        self:PrintTag("  Width: " .. math.floor(width))
        self:PrintTag("  Height: " .. math.floor(height))
        self:PrintTag(" ")

        -- Default dimensions from instance data
        self:PrintTag("DEFAULT DIMENSIONS (from instance data):")
        self:PrintTag("  frameWidth: " .. (instanceData.frameWidth or "not set"))
        self:PrintTag("  frameHeight: " .. (instanceData.frameHeight or "not set"))
        self:PrintTag(" ")

        -- Per-instance settings
        self:PrintTag("PER-INSTANCE SETTINGS:")
        local config = self.db.profile.tracker
        if config.instances and config.instances[currentInstanceId] then
            local instanceSettings = config.instances[currentInstanceId]
            local hasSettings = false
            for key, value in pairs(instanceSettings) do
                hasSettings = true
                self:PrintTag("  " .. key .. ": " .. tostring(value))
            end
            if not hasSettings then
                self:PrintTag("  (none)")
            end
        else
            self:PrintTag("  (none)")
        end
        self:PrintTag(" ")

        -- Global settings
        self:PrintTag("GLOBAL SETTINGS:")
        self:PrintTag("  baseFont: " .. (config.baseFont or "not set"))
        self:PrintTag("  baseFontSize: " .. (config.baseFontSize or "not set"))
        self:PrintTag("  fontScale: " .. (config.fontScale or "not set"))
        self:PrintTag("  frameWidth: " .. (config.frameWidth or "not set"))
        self:PrintTag("  frameHeight: " .. (config.frameHeight or "not set"))
        self:PrintTag(" ")

        -- Title calculation
        local titleText = frame.titleText and frame.titleText.text
        if titleText then
            local titleString = titleText:GetText() or ""
            local titleWidth = titleText:GetStringWidth()
            self:PrintTag("TITLE INFO:")
            self:PrintTag("  Text: " .. titleString)
            self:PrintTag("  Width: " .. math.floor(titleWidth))
            local font, size, outline = titleText:GetFont()
            self:PrintTag("  Font Size: " .. (size or "unknown"))
        end
        self:PrintTag(" ")

        -- Frame position
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
        self:PrintTag("POSITION:")
        self:PrintTag("  Point: " .. (point or "unknown"))
        self:PrintTag("  X Offset: " .. (xOfs and math.floor(xOfs) or "unknown"))
        self:PrintTag("  Y Offset: " .. (yOfs and math.floor(yOfs) or "unknown"))
        self:PrintTag("========================================")
    end)

    -- Boss Recorder Commands
    self:RegisterChatCommand("kbre", function()
        if KoalityOfLife.BossRecorder then
            KoalityOfLife.BossRecorder:ExportAllSessions()
        else
            self:PrintTag("|cFF00FF00Boss Recorder:|r Module not loaded")
        end
    end)
    
    self:RegisterChatCommand("kbrl", function()
        if KoalityOfLife.BossRecorder then
            KoalityOfLife.BossRecorder:ListSessions()
        else
            self:PrintTag("|cFF00FF00Boss Recorder:|r Module not loaded")
        end
    end)
    
    self:RegisterChatCommand("kbrs", function()
        if KoalityOfLife.BossRecorder then
            KoalityOfLife.BossRecorder:ShowStatus()
        else
            self:PrintTag("|cFF00FF00Boss Recorder:|r Module not loaded")
        end
    end)
    
    self:RegisterChatCommand("kbr", function(input)
        if KoalityOfLife.BossRecorder then
            KoalityOfLife.BossRecorder:HandleBossRecordCommand(input or "")
        else
            self:PrintTag("|cFF00FF00Boss Recorder:|r Module not loaded")
        end
    end)
    
    -- Full bossrecord commands (for completeness)
    self:RegisterChatCommand("bossrecord", function(input)
        if KoalityOfLife.BossRecorder then
            KoalityOfLife.BossRecorder:HandleBossRecordCommand(input or "")
        else
            self:PrintTag("|cFF00FF00Boss Recorder:|r Module not loaded")
        end
    end)
    
    self:RegisterChatCommand("br", function(input)
        if KoalityOfLife.BossRecorder then
            KoalityOfLife.BossRecorder:HandleBossRecordCommand(input or "")
        else
            self:PrintTag("|cFF00FF00Boss Recorder:|r Module not loaded")
        end
    end)

    -- Event Monitor Commands
    self:RegisterChatCommand("kwe", function(input)
        input = string.lower(string.trim(input or ""))
        if input == "start" then
            KOL:StartEventMonitor()
        elseif input == "stop" then
            KOL:StopEventMonitor()
        elseif input == "list" then
            KOL:ListMonitoredEvents()
        elseif input == "clear" then
            KOL:ClearMonitoredEvents()
        else
            KOL:Print(COLOR("GREEN", "Event Monitor Commands:"))
            KOL:Print(COLOR("CYAN", "  /kwe start") .. " - Start monitoring events")
            KOL:Print(COLOR("CYAN", "  /kwe stop") .. " - Stop monitoring events")
            KOL:Print(COLOR("CYAN", "  /kwe list") .. " - List captured events")
            KOL:Print(COLOR("CYAN", "  /kwe clear") .. " - Clear event log")
        end
    end)

    self:DebugPrint("!Koality-of-Life v" .. KOL.version .. " loaded", 1)
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
        -- Call the registered function with the remaining arguments, with error handling
        local success, errorMsg = pcall(function()
            commandData.func(unpack(args))
        end)
        if not success then
            print("|cFFFF0000[KoL] Command Error:|r " .. tostring(errorMsg))
        end
        return
    end

    -- Built-in commands (these don't need registration)
    if not cmd or cmd == "" or cmd == "help" then
        self:PrintHelp()
    elseif cmd == "config" or cmd == "options" then
        self:OpenConfig()
    elseif cmd == "ld" or cmd == "limitdamage" then
        self:ToggleLimitDamage()
    elseif cmd == "debug" then
        self:ToggleDebug(args[1], args[2])
    elseif cmd == "themes" then
        -- Simple themes debug command
        self:PrintTag("=== THEMES DEBUG ===")
        
        if KOL.Themes then
            self:PrintTag("Themes module: |cFF00FF00LOADED|r")
            self:PrintTag("Database available: " .. (KOL.db and "|cFF00FF00YES|r" or "|cFFFF0000NO|r"))
            
            local activeTheme = KOL.Themes:GetActiveTheme()
            local count = KOL.Themes:CountThemes()
            
            self:PrintTag("Active theme: |cFFFFFF00" .. (activeTheme or "None") .. "|r")
            self:PrintTag("Theme count: |cFF00FF00" .. count .. "|r")
            
            -- Test theme color retrieval
            local testColor = KOL.Themes:GetThemeColor("GlobalBG", "FFFFFF")
            self:PrintTag("Test color (GlobalBG): |cFF" .. testColor .. "████|r")
            
            -- Test theme RGB conversion
            local rgbColor = KOL.Themes:GetUIThemeColor("ButtonNormal", {r=1, g=1, b=1})
            self:PrintTag("Test RGB (ButtonNormal): " .. string.format("%.2f, %.2f, %.2f", rgbColor.r, rgbColor.g, rgbColor.b))
        else
            self:PrintTag("Themes module: |cFFFF0000NOT LOADED|r")
        end
    elseif cmd == "constants" or cmd == "const" or cmd == "char" then
        local searchTerm = table.concat(args, " ")
        if searchTerm == "" then
            self:PrintTag(YELLOW("Usage: /kol constants <search term>"))
            self:Print("  Examples:")
            self:Print("    /kol constants SHAPES")
            self:Print("    /kol constants ARROW")
            self:Print("    /kol constants FILLED TRIANGLE RIGHT")
        else
            -- Use CHAR_SEARCH to get results without debug spam
            local results = CHAR_SEARCH(searchTerm)
            self:ShowCharViewer(searchTerm, results)
        end
    elseif cmd == "theme" then
        -- Handle theme commands
        local action = args[1] and string.lower(args[1]) or "info"
        
        if not KOL.Themes then
            self:PrintTag("Theme system not available")
            return
        end
        
        if action == "info" then
            local activeTheme = KOL.Themes:GetActiveTheme()
            local theme = KOL.Themes:GetTheme()
            local count = KOL.Themes:CountThemes()
            
            self:PrintTag("=== THEME SYSTEM INFO ===")
            self:PrintTag("Active Theme: |cFFFFFF00" .. (activeTheme or "None") .. "|r")
            self:PrintTag("Available Themes: |cFF00FF00" .. count .. "|r")
            
            if theme then
                self:PrintTag("Author: " .. (theme.author or "Unknown"))
                self:PrintTag("Description: " .. (theme.description or "No description"))
                self:PrintTag("Version: " .. (theme.version or "1.0"))
            end
            
        elseif action == "list" then
            local themes = KOL.Themes:GetThemeList()
            self:PrintTag("=== AVAILABLE THEMES ===")
            for name, _ in pairs(themes) do
                local active = (name == KOL.Themes:GetActiveTheme()) and " [ACTIVE]" or ""
                self:PrintTag("  |cFFFFFF00" .. name .. "|r" .. active)
            end
            
        elseif action == "test" then
            local theme = KOL.Themes:GetTheme()
            if theme and theme.colors then
                self:PrintTag("=== THEME COLOR TEST ===")
                self:PrintTag("GlobalBG: |cFF" .. (theme.colors.GlobalBG or "FFFFFF") .. "████ Global Background|r")
                self:PrintTag("ButtonNormal: |cFF" .. (theme.colors.ButtonNormal or "FFFFFF") .. "████ Button Normal|r")
                self:PrintTag("TextPrimary: |cFF" .. (theme.colors.TextPrimary or "FFFFFF") .. "████ Primary Text|r")
                self:PrintTag("PriorityHigh: |cFF" .. (theme.colors.PriorityHigh or "FFFFFF") .. "████ High Priority|r")
                self:PrintTag("ScrollbarThumb: |cFF" .. (theme.colors.ScrollbarThumbBG or "FFFFFF") .. "████ Scrollbar|r")
            else
                self:PrintTag("No theme data available")
            end
            
        elseif action == "export" then
            local theme = KOL.Themes:GetTheme()
            if theme then
                local exportData = KOL.Themes:ExportTheme(theme.name)
                if exportData then
                    self:PrintTag("=== EXPORT THEME ===")
                    self:PrintTag("Theme data (copy this):")
                    self:Print(exportData)
                else
                    self:PrintTag("Export failed")
                end
            else
                self:PrintTag("No theme to export")
            end
            
        else
            self:PrintTag("Usage: /kol theme [info|list|test|export]")
            self:PrintTag("  info  - Show current theme info")
            self:PrintTag("  list  - List available themes")
            self:PrintTag("  test  - Show color samples")
            self:PrintTag("  export - Export current theme")
        end
    elseif cmd == "devmode" or cmd == "dev" then
        -- Toggle developer mode (shows hidden config tabs)
        local action = args[1] and string.lower(args[1]) or nil

        if action == "on" then
            self.db.profile.devMode = true
        elseif action == "off" then
            self.db.profile.devMode = false
        else
            -- Toggle
            self.db.profile.devMode = not self.db.profile.devMode
        end

        local status = self.db.profile.devMode and GREEN("ON") or RED("OFF")
        self:PrintTag("Developer mode: " .. status)

        if self.db.profile.devMode then
            self:PrintTag("Hidden config tabs are now visible. Reload UI to apply changes.")
        else
            self:PrintTag("Hidden config tabs are now hidden. Reload UI to apply changes.")
        end
    elseif cmd == "testimg" then
        -- Test image display for debugging texture paths
        local testFrame = _G["KOL_TestImageFrame"]
        if testFrame then
            testFrame:Show()
            return
        end

        testFrame = CreateFrame("Frame", "KOL_TestImageFrame", UIParent)
        testFrame:SetSize(200, 200)
        testFrame:SetPoint("CENTER")
        testFrame:SetFrameStrata("DIALOG")
        testFrame:EnableMouse(true)
        testFrame:SetMovable(true)
        testFrame:RegisterForDrag("LeftButton")
        testFrame:SetScript("OnDragStart", testFrame.StartMoving)
        testFrame:SetScript("OnDragStop", testFrame.StopMovingOrSizing)

        -- Background and Border (WotLK style)
        testFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        testFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
        testFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

        -- Title
        local title = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Image Test")

        -- Image 1: Known working image (splash)
        local img1Path = "Interface\\AddOns\\!Koality-of-Life\\media\\images\\kol-splash"
        local img1 = testFrame:CreateTexture(nil, "ARTWORK")
        img1:SetSize(48, 48)
        img1:SetPoint("CENTER", -60, 20)
        img1:SetTexture(img1Path)
        img1:SetTexCoord(0, 0.25, 0, 0.25)

        local label1 = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label1:SetPoint("TOP", img1, "BOTTOM", 0, -2)
        label1:SetText("|cFF00FF00kol-splash|r")

        -- Image 2: stevefurwin_normal
        local img2Path = "Interface\\AddOns\\!Koality-of-Life\\media\\images\\stevefurwin_normal"
        local img2 = testFrame:CreateTexture(nil, "ARTWORK")
        img2:SetSize(48, 48)
        img2:SetPoint("CENTER", 0, 20)
        img2:SetTexture(img2Path)

        local label2 = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label2:SetPoint("TOP", img2, "BOTTOM", 0, -2)
        label2:SetText("|cFFFFFF00normal|r")

        -- Image 3: stevefurwin_buildmanager
        local img3Path = "Interface\\AddOns\\!Koality-of-Life\\media\\images\\stevefurwin_buildmanager"
        local img3 = testFrame:CreateTexture(nil, "ARTWORK")
        img3:SetSize(48, 48)
        img3:SetPoint("CENTER", 60, 20)
        img3:SetTexture(img3Path)

        local label3 = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label3:SetPoint("TOP", img3, "BOTTOM", 0, -2)
        label3:SetText("|cFFFFFF00buildmanager|r")

        -- Close button
        local closeBtn = CreateFrame("Button", nil, testFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -2, -2)
        closeBtn:SetScript("OnClick", function() testFrame:Hide() end)

        self:PrintTag("Test image frame opened - showing 3 images")
    elseif cmd == "cmds" or cmd == "commands" then
        -- Debug: List all registered slash commands
        self:PrintTag("=== REGISTERED COMMANDS ===")
        local count = 0
        for cmdName, cmdData in pairs(self.slashCommands) do
            count = count + 1
            local category = cmdData.category or "module"
            print("  " .. YELLOW(cmdName) .. " [" .. category .. "]")
        end
        self:PrintTag("Total: " .. count .. " commands registered")
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
    self:Print(YELLOW("/kol devmode") .. " - Toggle dev mode (shows hidden tabs)")
    self:Print(YELLOW("/kol constants <term>") .. " - Search character constants (also: /kol char, /kol const)")
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
    self:Print(YELLOW("/r25h") .. ", " .. YELLOW("/r25n") .. ", " .. YELLOW("/r25") .. " - Set 25-man raid difficulty")
    self:Print(YELLOW("/r20n") .. ", " .. YELLOW("/r20") .. " - Legacy 20-man info")
    self:Print(YELLOW("/r10h") .. ", " .. YELLOW("/r10n") .. ", " .. YELLOW("/r10") .. " - Set 10-man raid difficulty")
    self:Print(YELLOW("/d5h") .. ", " .. YELLOW("/d5n") .. ", " .. YELLOW("/d5") .. " - Set dungeon difficulty")
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
        self:PrintTag("Debug mode " .. status .. " (Level " .. YELLOW(level) .. ")", true)
        return
    end

    arg1 = string.lower(arg1)

    if arg1 == "on" then
        self.db.profile.debug = true
        local level = self.db.profile.debugLevel or 1
        self:PrintTag("Debug mode " .. GREEN("enabled") .. " (Level " .. YELLOW(level) .. ")", true)
    elseif arg1 == "off" then
        self.db.profile.debug = false
        self:PrintTag("Debug mode " .. RED("disabled"), true)
    elseif arg1 == "level" or arg1 == "l" then
        if not arg2 then
            local level = self.db.profile.debugLevel or 1
            self:PrintTag("Current debug level: " .. YELLOW(level), true)
            self:Print("Usage: " .. YELLOW("/kol debug level [1-5]") .. " or " .. YELLOW("/kol debug l [1-5]"))
            return
        end

        local newLevel = tonumber(arg2)
        if newLevel and newLevel >= 1 and newLevel <= 5 then
            self.db.profile.debugLevel = newLevel
            self:PrintTag("Debug level set to: " .. YELLOW(newLevel), true)
            if not self.db.profile.debug then
                self:Print(GRAY("  (Debug mode is currently OFF - turn it on with /kol debug on)"))
            end

            -- Refresh debug console if it's open
            if self.RefreshDebugConsole then
                self:RefreshDebugConsole()
            end
        else
            self:PrintTag(RED("Error:") .. " Debug level must be between 1 and 5", true)
        end
    else
        self:PrintTag(RED("Error:") .. " Unknown debug command: " .. arg1, true)
        self:Print("Usage:")
        self:Print("  " .. YELLOW("/kol debug") .. " - Toggle debug mode on/off")
        self:Print("  " .. YELLOW("/kol debug on/off") .. " - Turn debug on or off")
        self:Print("  " .. YELLOW("/kol debug level [1-5]") .. " or " .. YELLOW("/kol debug l [1-5]") .. " - Set debug level")
    end
end

function KOL:ShowPrints(arg1)
    -- /ksp - Toggle print visibility
    -- /ksp 0 - Turn off (default)
    -- /ksp 1 - Turn on

    if not arg1 then
        -- Simple toggle
        self.db.profile.showPrints = not self.db.profile.showPrints
        local status = self.db.profile.showPrints and GREEN("enabled") or RED("disabled")
        self:PrintTag("Print visibility " .. status, true)
        return
    end

    local value = tonumber(arg1)
    if value == 0 then
        self.db.profile.showPrints = false
        self:PrintTag("Print visibility " .. RED("disabled"), true)
    elseif value == 1 then
        self.db.profile.showPrints = true
        self:PrintTag("Print visibility " .. GREEN("enabled"), true)
    else
        self:PrintTag(RED("Error:") .. " Value must be 0 (off) or 1 (on)", true)
        self:Print("Usage:")
        self:Print("  " .. YELLOW("/ksp") .. " - Toggle print visibility on/off")
        self:Print("  " .. YELLOW("/ksp 0") .. " - Turn print visibility off (default)")
        self:Print("  " .. YELLOW("/ksp 1") .. " - Turn print visibility on")
    end
end

function KOL:OpenConfig()
    -- Open the config dialog (handled by ui.lua)
    LibStub("AceConfigDialog-3.0"):Open("KoalityOfLife")

    -- Narrow the tree panel width for Synastria sub-tab (default is 175, we want ~120)
    C_Timer.After(0.1, function()
        local ACD = LibStub("AceConfigDialog-3.0")
        local frame = ACD.OpenFrames["KoalityOfLife"]
        if frame then
            -- Find tree groups in the frame hierarchy and narrow them
            local function NarrowTreeGroups(widget)
                if widget.SetTreeWidth then
                    -- This is a TreeGroup widget - narrow it
                    widget:SetTreeWidth(120, false)  -- 120px, not resizable
                end
                -- Recurse into children
                if widget.children then
                    for _, child in ipairs(widget.children) do
                        NarrowTreeGroups(child)
                    end
                end
            end
            NarrowTreeGroups(frame)
        end
    end)

    -- Start auto-refresh timer for performance stats (updates every 2 seconds)
    if not KOL.statsRefreshTimer then
        KOL.statsRefreshTimer = C_Timer.NewTicker(2, function()
            -- Check if config dialog is still open
            local ACD = LibStub("AceConfigDialog-3.0")
            if ACD.OpenFrames["KoalityOfLife"] then
                -- Notify config registry to refresh (updates dynamic stats)
                LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
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
        self:PrintTag(RED("Error:") .. " " .. tostring(err), true)
    end
    return success
end

-- ============================================================================
-- Event Monitor (for debugging what events fire)
-- ============================================================================

KOL.eventMonitor = {
    enabled = false,
    frame = nil,
    eventLog = {},
    maxEvents = 100,
}

function KOL:StartEventMonitor()
    if self.eventMonitor.enabled then
        self:Print("Event monitor is already running. Use /kwe stop to stop it.")
        return
    end

    self.eventMonitor.enabled = true
    self.eventMonitor.eventLog = {}

    -- Create monitor frame if it doesn't exist
    if not self.eventMonitor.frame then
        self.eventMonitor.frame = CreateFrame("Frame")
        self.eventMonitor.frame:SetScript("OnEvent", function(frame, event, ...)
            if KOL.eventMonitor.enabled then
                local args = {...}
                local argStr = ""
                for i, arg in ipairs(args) do
                    if i > 1 then argStr = argStr .. ", " end
                    argStr = argStr .. tostring(arg)
                end

                local logEntry = string.format("%s(%s)", event, argStr)
                table.insert(KOL.eventMonitor.eventLog, logEntry)

                -- Keep only last N events
                if #KOL.eventMonitor.eventLog > KOL.eventMonitor.maxEvents then
                    table.remove(KOL.eventMonitor.eventLog, 1)
                end

                -- Print to chat
                KOL:Print(COLOR("CYAN", "EVENT: ") .. logEntry)
            end
        end)
    end

    -- Register ALL events we might care about
    local eventsToWatch = {
        "ENCOUNTER_START",
        "ENCOUNTER_END",
        "BOSS_KILL",
        "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
        "UNIT_DIED",
        "PLAYER_DEAD",
        "CHAT_MSG_MONSTER_YELL",
        "CHAT_MSG_RAID_BOSS_EMOTE",
        "PLAY_MOVIE",
        "CINEMATIC_START",
        "UPDATE_INSTANCE_INFO",
    }

    for _, event in ipairs(eventsToWatch) do
        self.eventMonitor.frame:RegisterEvent(event)
    end

    self:Print(COLOR("GREEN", "Event Monitor: ") .. "Started monitoring " .. #eventsToWatch .. " events")
    self:Print("Use " .. COLOR("YELLOW", "/kwe stop") .. " to stop monitoring")
    self:Print("Use " .. COLOR("YELLOW", "/kwe list") .. " to see captured events")
end

function KOL:StopEventMonitor()
    if not self.eventMonitor.enabled then
        self:Print("Event monitor is not running.")
        return
    end

    self.eventMonitor.enabled = false
    if self.eventMonitor.frame then
        self.eventMonitor.frame:UnregisterAllEvents()
    end

    self:Print(COLOR("GREEN", "Event Monitor: ") .. "Stopped. Captured " .. #self.eventMonitor.eventLog .. " events")
    self:Print("Use " .. COLOR("YELLOW", "/kwe list") .. " to see captured events")
end

function KOL:ListMonitoredEvents()
    if #self.eventMonitor.eventLog == 0 then
        self:Print("No events captured. Use /kwe start to begin monitoring.")
        return
    end

    self:Print(COLOR("GREEN", "Event Monitor Log: ") .. #self.eventMonitor.eventLog .. " events")
    self:Print(string.rep("=", 60))
    for i, entry in ipairs(self.eventMonitor.eventLog) do
        self:Print(string.format("%d. %s", i, entry))
    end
    self:Print(string.rep("=", 60))
end

function KOL:ClearMonitoredEvents()
    self.eventMonitor.eventLog = {}
    self:Print(COLOR("GREEN", "Event Monitor: ") .. "Event log cleared")
end

-- ============================================================================
-- Difficulty Setting Functions
-- ============================================================================
-- Note: DebugPrint is now in core.lua so it's available early to all modules

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
-- Tweaks: Limit Damage Toggle
-- ============================================================================

function KOL:ToggleLimitDamage()
    -- Toggle the saved setting
    self.db.profile.limitDamage = not self.db.profile.limitDamage
    local isEnabled = self.db.profile.limitDamage

    -- Block the server's response message (we print our own formatted version)
    self:BlockNextChatMessage("^Changed Misc Options: Limit damage")

    -- Call the Chromie server function
    if ChangePerkOption then
        ChangePerkOption("Misc Options", "Limit damage", isEnabled, true)
    end

    -- Print formatted status message
    -- Output: [Koality-of-Life] Changed [Limit Damage] to [YES/NO]
    print(self.Colors:FormatSettingChange("Limit Damage", isEnabled))

    -- Refresh config dialog if open
    LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
end

-- ============================================================================
-- Tweaks: Racial Swap
-- ============================================================================

-- Valid race/class combinations for WoW 3.3.5a (Chromie server)
KOL.RacialData = {
    validCombos = {
        ["WARRIOR"] = {"Human", "Dwarf", "Night Elf", "Gnome", "Draenei", "Orc", "Undead", "Tauren", "Troll"},
        ["PALADIN"] = {"Human", "Dwarf", "Draenei", "Blood Elf"},
        ["HUNTER"] = {"Night Elf", "Dwarf", "Draenei", "Orc", "Tauren", "Troll", "Blood Elf"},
        ["ROGUE"] = {"Human", "Dwarf", "Night Elf", "Gnome", "Orc", "Undead", "Troll", "Blood Elf"},
        ["PRIEST"] = {"Human", "Dwarf", "Night Elf", "Draenei", "Undead", "Troll", "Blood Elf"},
        ["DEATHKNIGHT"] = {"Human", "Dwarf", "Night Elf", "Gnome", "Draenei", "Orc", "Undead", "Tauren", "Troll", "Blood Elf"},
        ["SHAMAN"] = {"Draenei", "Orc", "Tauren", "Troll"},
        ["MAGE"] = {"Human", "Gnome", "Draenei", "Undead", "Troll", "Blood Elf"},
        ["WARLOCK"] = {"Human", "Gnome", "Orc", "Undead", "Blood Elf"},
        ["DRUID"] = {"Night Elf", "Tauren"},
    },
    -- Short display names for compact UI
    shortNames = {
        ["Human"] = "Human",
        ["Dwarf"] = "Dwarf",
        ["Night Elf"] = "NElf",
        ["Gnome"] = "Gnome",
        ["Draenei"] = "Draenei",
        ["Orc"] = "Orc",
        ["Undead"] = "Undead",
        ["Tauren"] = "Tauren",
        ["Troll"] = "Troll",
        ["Blood Elf"] = "BElf",
    },
}

-- Get valid racials for the player's class
function KOL:GetValidRacials()
    local _, class = UnitClass("player")
    return self.RacialData.validCombos[class] or {}
end

-- Get short name for a racial
function KOL:GetRacialShortName(race)
    return self.RacialData.shortNames[race] or race
end

-- Get the current racial (from saved vars or default)
function KOL:GetCurrentRacial()
    return self.db.profile.currentRacial or self.db.profile.racialPrimary or "Unknown"
end

-- Initialize racial defaults for player's class if not set
function KOL:InitializeRacialDefaults()
    local validRaces = self:GetValidRacials()
    if #validRaces >= 2 then
        if not self.db.profile.racialPrimary then
            self.db.profile.racialPrimary = validRaces[1]
        end
        if not self.db.profile.racialSecondary then
            self.db.profile.racialSecondary = validRaces[2]
        end
        if not self.db.profile.currentRacial then
            self.db.profile.currentRacial = validRaces[1]
        end
    elseif #validRaces == 1 then
        self.db.profile.racialPrimary = validRaces[1]
        self.db.profile.racialSecondary = validRaces[1]
        self.db.profile.currentRacial = validRaces[1]
    end
end

-- Set a specific racial
function KOL:SetRacial(race, silent)
    if not race then return end

    -- Validate the racial is valid for this class
    local validRaces = self:GetValidRacials()
    local isValid = false
    for _, validRace in ipairs(validRaces) do
        if validRace == race then
            isValid = true
            break
        end
    end

    if not isValid then
        self:PrintTag(RED("Invalid racial for your class: ") .. race)
        return
    end

    -- Update saved setting
    self.db.profile.currentRacial = race

    -- Block the server's response message
    self:BlockNextChatMessage("^Changed Extra Racial Skill:")

    -- Call the Chromie server function
    if ChangePerkOption then
        ChangePerkOption("Extra Racial Skill", race, true, silent or false)
    end

    -- Print formatted status message (unless silent)
    if not silent then
        print(self.Colors:FormatSettingChange("Racial", race))
    end

    -- Refresh config dialog if open
    LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
end

-- Toggle between primary and secondary racials
function KOL:ToggleRacial()
    -- Initialize defaults if needed
    self:InitializeRacialDefaults()

    local primary = self.db.profile.racialPrimary
    local secondary = self.db.profile.racialSecondary
    local current = self:GetCurrentRacial()

    -- Toggle to the other racial
    if current == primary then
        self:SetRacial(secondary)
    else
        self:SetRacial(primary)
    end
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
