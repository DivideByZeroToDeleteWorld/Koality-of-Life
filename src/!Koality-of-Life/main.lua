-- !Koality-of-Life: Main Systems

local KOL = KoalityOfLife

KOL.slashCommands = {}
KOL.eventCallbacks = {}

-- ============================================================================
-- Slash Command Registration System
-- ============================================================================

function KOL:RegisterSlashCommand(command, func, description, category)
    if not command or not func then
        self:PrintTag(RED("Error:") .. " Invalid slash command registration", true)
        return false
    end

    command = string.lower(command)

    if self.slashCommands[command] then
        self:DebugPrint("Slash command '" .. command .. "' is already registered. Overwriting.", 3)
    end

    self.slashCommands[command] = {
        func = func,
        description = description or "No description available",
        category = category or "module"
    }

    self:DebugPrint("System: Registered slash command: " .. YELLOW(command) .. " (category: " .. (category or "module") .. ")")
    return true
end

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

function KOL:RegisterEventCallback(event, callback, moduleName)
    if not event or not callback then
        self:PrintTag(RED("Error:") .. " Invalid event callback registration", true)
        return false
    end

    if not self.eventCallbacks[event] then
        self.eventCallbacks[event] = {}
    end

    table.insert(self.eventCallbacks[event], {
        callback = callback,
        moduleName = moduleName or "Unknown"
    })

    self:DebugPrint("Registered event callback: " .. YELLOW(event) .. " for " .. (moduleName or "Unknown"))

    if self.eventFrame then
        self.eventFrame:RegisterEvent(event)
    end

    return true
end

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
    if self.InitializeUI then
        self:InitializeUI()
    end

    self:RegisterChatCommand("kol", "SlashCommand")
    self:RegisterChatCommand("koality", "SlashCommand")
    self:RegisterChatCommand("kt", "TestSlashCommand")
    self:RegisterChatCommand("kdc", function() self:ToggleDebugConsole() end)
    self:RegisterChatCommand("kcv", function() self:ToggleCharViewer() end)
    self:RegisterChatCommand("kld", function() self:ToggleLimitDamage() end)
    self:RegisterChatCommand("krs", function() self:ToggleRacial() end)
    self:RegisterChatCommand("kc", function(args)
        args = strtrim(args or ""):lower()
        if args == "showcase" then
            if KOL.UIFactory and KOL.UIFactory.ShowUIShowcase then
                KOL.UIFactory:ShowUIShowcase()
            else
                self:PrintTag("UIFactory not loaded yet!")
            end
        elseif args == "ld" or args == "limitdamage" then
            self:ToggleLimitDamage()
        else
            self:OpenConfig()
        end
    end)
    self:RegisterChatCommand("kcpt", function()
        self:OpenConfig()
        LibStub("AceConfigDialog-3.0"):SelectGroup("KoalityOfLife", "tracker")
    end)
    self:RegisterChatCommand("kmu", function()
        if KoalityOfLife.MacroUpdater then
            KoalityOfLife.MacroUpdater:ShowUI()
        end
    end)
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

        local width = frame:GetWidth()
        local height = frame:GetHeight()
        self:PrintTag("CURRENT DIMENSIONS:")
        self:PrintTag("  Width: " .. math.floor(width))
        self:PrintTag("  Height: " .. math.floor(height))
        self:PrintTag(" ")

        self:PrintTag("DEFAULT DIMENSIONS (from instance data):")
        self:PrintTag("  frameWidth: " .. (instanceData.frameWidth or "not set"))
        self:PrintTag("  frameHeight: " .. (instanceData.frameHeight or "not set"))
        self:PrintTag(" ")

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

        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
        self:PrintTag("POSITION:")
        self:PrintTag("  Point: " .. (point or "unknown"))
        self:PrintTag("  X Offset: " .. (xOfs and math.floor(xOfs) or "unknown"))
        self:PrintTag("  Y Offset: " .. (yOfs and math.floor(yOfs) or "unknown"))
        self:PrintTag("========================================")
    end)

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
    table.remove(args, 1)

    if cmd ~= "" and self.slashCommands[cmd] then
        local commandData = self.slashCommands[cmd]
        local success, errorMsg = pcall(function()
            commandData.func(unpack(args))
        end)
        if not success then
            print("|cFFFF0000[KoL] Command Error:|r " .. tostring(errorMsg))
        end
        return
    end

    if not cmd or cmd == "" or cmd == "help" then
        self:PrintHelp()
    elseif cmd == "config" or cmd == "options" then
        self:OpenConfig()
    elseif cmd == "ld" or cmd == "limitdamage" then
        self:ToggleLimitDamage()
    elseif cmd == "debug" then
        self:ToggleDebug(args[1], args[2])
    elseif cmd == "themes" then
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

        testFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        testFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
        testFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

        local title = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Image Test")

        local img1Path = "Interface\\AddOns\\!Koality-of-Life\\media\\images\\kol-splash"
        local img1 = testFrame:CreateTexture(nil, "ARTWORK")
        img1:SetSize(48, 48)
        img1:SetPoint("CENTER", -60, 20)
        img1:SetTexture(img1Path)
        img1:SetTexCoord(0, 0.25, 0, 0.25)

        local label1 = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label1:SetPoint("TOP", img1, "BOTTOM", 0, -2)
        label1:SetText("|cFF00FF00kol-splash|r")

        local img2Path = "Interface\\AddOns\\!Koality-of-Life\\media\\images\\stevefurwin_normal"
        local img2 = testFrame:CreateTexture(nil, "ARTWORK")
        img2:SetSize(48, 48)
        img2:SetPoint("CENTER", 0, 20)
        img2:SetTexture(img2Path)

        local label2 = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label2:SetPoint("TOP", img2, "BOTTOM", 0, -2)
        label2:SetText("|cFFFFFF00normal|r")

        local img3Path = "Interface\\AddOns\\!Koality-of-Life\\media\\images\\stevefurwin_buildmanager"
        local img3 = testFrame:CreateTexture(nil, "ARTWORK")
        img3:SetSize(48, 48)
        img3:SetPoint("CENTER", 60, 20)
        img3:SetTexture(img3Path)

        local label3 = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label3:SetPoint("TOP", img3, "BOTTOM", 0, -2)
        label3:SetText("|cFFFFFF00buildmanager|r")

        local closeBtn = CreateFrame("Button", nil, testFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -2, -2)
        closeBtn:SetScript("OnClick", function() testFrame:Hide() end)

        self:PrintTag("Test image frame opened - showing 3 images")
    elseif cmd == "cmds" or cmd == "commands" then
        self:PrintTag("=== REGISTERED COMMANDS ===")
        local count = 0
        for cmdName, cmdData in pairs(self.slashCommands) do
            count = count + 1
            local category = cmdData.category or "module"
            print("  " .. YELLOW(cmdName) .. " [" .. category .. "]")
        end
        self:PrintTag("Total: " .. count .. " commands registered")
    elseif cmd == "zone" or cmd == "diag" then
        -- Zone diagnostic command
        local zoneName = GetRealZoneText()
        local subZoneName = GetSubZoneText()
        local name, instanceType, difficultyIndex, difficultyName, maxPlayers = GetInstanceInfo()

        self:PrintTag("=== ZONE DIAGNOSTIC ===")
        print("  Zone: " .. YELLOW(tostring(zoneName)))
        print("  SubZone: " .. YELLOW(tostring(subZoneName)))
        print("  Instance: " .. YELLOW(tostring(name)))
        print("  Type: " .. YELLOW(tostring(instanceType)))
        print("  Difficulty: " .. YELLOW(tostring(difficultyIndex)) .. " (" .. tostring(difficultyName) .. ")")
        print("  Max Players: " .. YELLOW(tostring(maxPlayers)))

        if KOL.Tracker then
            print("  Current Instance ID: " .. YELLOW(tostring(KOL.Tracker.currentInstanceId) or "nil"))

            -- Check if zone matches any registered instance
            local matches = {}
            for id, data in pairs(KOL.Tracker.instances or {}) do
                for _, zone in ipairs(data.zones or {}) do
                    if zone == zoneName or zone == subZoneName then
                        table.insert(matches, id .. " (diff=" .. tostring(data.difficulty) .. ")")
                    end
                end
            end

            if #matches > 0 then
                print("  Matching Instances: " .. GREEN(table.concat(matches, ", ")))
            else
                print("  Matching Instances: " .. RED("NONE - zone not recognized!"))
            end
        end
    elseif cmd == "diffraids" then
        -- Analyze all RAID instances and output available difficulties by expansion
        self:PrintTag("=== RAID DIFFICULTIES ANALYSIS ===")

        if not KOL.Tracker or not KOL.Tracker.instances then
            self:PrintTag(RED("Tracker not loaded or no instances registered"))
            return
        end

        -- Build analysis structure: expansion -> difficulty -> instances
        local analysis = {}
        local instanceCount = 0

        for id, data in pairs(KOL.Tracker.instances) do
            if data.type == "raid" then
                instanceCount = instanceCount + 1
                local exp = data.expansion or "unknown"
                local diff = data.difficulty or 0

                if not analysis[exp] then analysis[exp] = {} end
                if not analysis[exp][diff] then analysis[exp][diff] = {} end

                table.insert(analysis[exp][diff], {
                    id = id,
                    name = data.name or id
                })
            end
        end

        self:PrintTag("Total raids registered: " .. GREEN(instanceCount))
        print("")

        local expansionOrder = {"classic", "tbc", "wotlk"}
        local diffNames = {
            [1] = "10-Player Normal",
            [2] = "25-Player Normal",
            [3] = "10-Player Heroic",
            [4] = "25-Player Heroic"
        }

        for _, exp in ipairs(expansionOrder) do
            if analysis[exp] then
                print(YELLOW("=== " .. string.upper(exp) .. " RAIDS ==="))

                local diffs = {}
                for diff in pairs(analysis[exp]) do
                    table.insert(diffs, diff)
                end
                table.sort(diffs)

                for _, diff in ipairs(diffs) do
                    local instances = analysis[exp][diff]
                    local diffLabel = diffNames[diff] or ("Difficulty " .. diff)
                    print("  " .. CYAN("Difficulty " .. diff) .. " (" .. diffLabel .. "): " .. #instances .. " raids")

                    for _, inst in ipairs(instances) do
                        print("    - " .. inst.name)
                    end
                end
                print("")
            end
        end

    elseif cmd == "diffdungeons" then
        -- Analyze all DUNGEON instances and output available difficulties by expansion
        self:PrintTag("=== DUNGEON DIFFICULTIES ANALYSIS ===")

        if not KOL.Tracker or not KOL.Tracker.instances then
            self:PrintTag(RED("Tracker not loaded or no instances registered"))
            return
        end

        -- Build analysis structure: expansion -> difficulty -> instances
        local analysis = {}
        local instanceCount = 0

        for id, data in pairs(KOL.Tracker.instances) do
            if data.type == "dungeon" then
                instanceCount = instanceCount + 1
                local exp = data.expansion or "unknown"
                local diff = data.difficulty or 0

                if not analysis[exp] then analysis[exp] = {} end
                if not analysis[exp][diff] then analysis[exp][diff] = {} end

                table.insert(analysis[exp][diff], {
                    id = id,
                    name = data.name or id
                })
            end
        end

        self:PrintTag("Total dungeons registered: " .. GREEN(instanceCount))
        print("")

        local expansionOrder = {"classic", "tbc", "wotlk"}
        local diffNames = {
            [1] = "Normal",
            [2] = "Heroic",
            [3] = "Mythic"
        }

        for _, exp in ipairs(expansionOrder) do
            if analysis[exp] then
                print(YELLOW("=== " .. string.upper(exp) .. " DUNGEONS ==="))

                local diffs = {}
                for diff in pairs(analysis[exp]) do
                    table.insert(diffs, diff)
                end
                table.sort(diffs)

                for _, diff in ipairs(diffs) do
                    local instances = analysis[exp][diff]
                    local diffLabel = diffNames[diff] or ("Difficulty " .. diff)
                    print("  " .. CYAN("Difficulty " .. diff) .. " (" .. diffLabel .. "): " .. #instances .. " dungeons")

                    for _, inst in ipairs(instances) do
                        print("    - " .. inst.name)
                    end
                end
                print("")
            end
        end
    else
        self:PrintTag(RED("Unknown command: ") .. cmd)
        self:PrintTag("Type " .. YELLOW("/kol help") .. " for a list of commands")
    end
end

function KOL:TestSlashCommand(input)
    input = string.trim(input or "")
    local args = {}

    for word in string.gmatch(input, "%S+") do
        table.insert(args, word)
    end

    local cmd = args[1] and string.lower(args[1]) or ""
    table.remove(args, 1)

    if cmd ~= "" and self.slashCommands[cmd] and self.slashCommands[cmd].category == "test" then
        local commandData = self.slashCommands[cmd]
        commandData.func(unpack(args))
        return
    end

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
    if not arg1 then
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
    if not arg1 then
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
    LibStub("AceConfigDialog-3.0"):Open("KoalityOfLife")

    C_Timer.After(0.1, function()
        local ACD = LibStub("AceConfigDialog-3.0")
        local frame = ACD.OpenFrames["KoalityOfLife"]
        if frame then
            local function NarrowTreeGroups(widget)
                if widget.SetTreeWidth then
                    widget:SetTreeWidth(120, false)
                end
                if widget.children then
                    for _, child in ipairs(widget.children) do
                        NarrowTreeGroups(child)
                    end
                end
            end
            NarrowTreeGroups(frame)
        end
    end)

    if not KOL.statsRefreshTimer then
        KOL.statsRefreshTimer = C_Timer.NewTicker(2, function()
            local ACD = LibStub("AceConfigDialog-3.0")
            if ACD.OpenFrames["KoalityOfLife"] then
                LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
            else
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

function KOL:SetRaidDifficulty(difficulty, diffName)
    if IsInGroup() or IsInRaid() then
        if not IsRaidLeader() and not IsRaidOfficer() then
            self:PrintTag(RED("Error:") .. " You must be raid leader or assistant to change raid difficulty")
            return
        end
    end

    SetRaidDifficulty(difficulty)
    self:PrintTag("Raid difficulty set to: " .. YELLOW(diffName))
    self:DebugPrint("SetRaidDifficulty(" .. difficulty .. ") called")
end

function KOL:SetDungeonDifficulty(difficulty, diffName)
    if IsInGroup() then
        if not IsPartyLeader() then
            self:PrintTag(RED("Error:") .. " You must be party leader to change dungeon difficulty")
            return
        end
    end

    SetDungeonDifficulty(difficulty)
    self:PrintTag("Dungeon difficulty set to: " .. YELLOW(diffName))
    self:DebugPrint("SetDungeonDifficulty(" .. difficulty .. ") called")
end

-- ============================================================================
-- Tweaks: Limit Damage Toggle
-- ============================================================================

function KOL:ToggleLimitDamage()
    self.db.profile.limitDamage = not self.db.profile.limitDamage
    local isEnabled = self.db.profile.limitDamage

    self:BlockNextChatMessage("^Changed Misc Options: Limit damage")

    if ChangePerkOption then
        ChangePerkOption("Misc Options", "Limit damage", isEnabled, true)
    end

    print(self.Colors:FormatSettingChange("Limit Damage", isEnabled))

    LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
end

-- ============================================================================
-- Tweaks: Racial Swap
-- ============================================================================

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

function KOL:GetValidRacials()
    local _, class = UnitClass("player")
    return self.RacialData.validCombos[class] or {}
end

function KOL:GetRacialShortName(race)
    return self.RacialData.shortNames[race] or race
end

function KOL:GetCurrentRacial()
    return self.db.profile.currentRacial or self.db.profile.racialPrimary or "Unknown"
end

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

function KOL:SetRacial(race, silent)
    if not race then return end

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

    self.db.profile.currentRacial = race

    self:BlockNextChatMessage("^Changed Extra Racial Skill:")

    if ChangePerkOption then
        ChangePerkOption("Extra Racial Skill", race, true, silent or false)
    end

    if not silent then
        print(self.Colors:FormatSettingChange("Racial", race))
    end

    LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
end

function KOL:ToggleRacial()
    self:InitializeRacialDefaults()

    local primary = self.db.profile.racialPrimary
    local secondary = self.db.profile.racialSecondary
    local current = self:GetCurrentRacial()

    if current == primary then
        self:SetRacial(secondary)
    else
        self:SetRacial(primary)
    end
end

-- ============================================================================
-- Event Frame
-- ============================================================================

KOL.eventFrame = CreateFrame("Frame")
KOL.eventFrame:SetScript("OnEvent", function(self, event, ...)
    KOL:FireEventCallbacks(event, ...)
end)
