-- ============================================================================
-- Koality-of-Life: Progress Tracker Module
-- ============================================================================
-- Tracks dungeon/raid progress with boss kills, objectives, and custom panels
-- ============================================================================

local KOL = KoalityOfLife
local LSM = LibStub("LibSharedMedia-3.0")

-- ============================================================================
-- Font Helper (averages with General settings)
-- ============================================================================

local function GetAveragedFont(requestedSize)
    local generalSize = KOL.db.profile.generalFontSize or 12
    local averageSize = math.floor((requestedSize + generalSize) / 2)

    local fontName = KOL.db.profile.generalFont or "Friz Quadrata TT"
    local fontOutline = KOL.db.profile.generalFontOutline or "THICKOUTLINE"

    local fontPath
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local success, result = pcall(function() return LSM:Fetch("font", fontName) end)
        if success and result then
            fontPath = result
        end
    end

    -- Fallback chain: LSM font → hardcoded default
    fontPath = fontPath or "Fonts\\FRIZQT__.TTF"

    return fontPath, averageSize, fontOutline
end

-- ============================================================================
-- Progress Tracker Module
-- ============================================================================

KOL.Tracker = {}
local Tracker = KOL.Tracker

-- Registered content instances (dungeons, raids, custom panels)
Tracker.instances = {}

-- Active watch frames (currently shown)
Tracker.activeFrames = {}

-- Boss kill state (persisted in DB)
Tracker.bossKills = {}

-- ============================================================================
-- Initialization
-- ============================================================================

function Tracker:Initialize()
    -- Ensure database structure exists
    if not KOL.db.profile.tracker then
        KOL.db.profile.tracker = {
            -- Font settings
            baseFont = "Friz Quadrata TT",
            baseFontSize = 12,
            fontScale = 1.0,

            -- Boss kill data (character-specific)
            bossKills = {},

            -- Custom watch panels
            customPanels = {},

            -- Frame positions (saved per character)
            framePositions = {},

            -- General settings
            autoShow = true,
            mouseover = false,
        }
    end

    -- Load boss kills from DB
    self.bossKills = KOL.db.profile.tracker.bossKills or {}

    -- Load custom panels from DB
    self:LoadCustomPanels()

    -- Register event handlers
    self:RegisterEvents()

    KOL:PrintTag("Tracker module initialized - calling UpdateZoneTracking")

    -- Perform initial zone check (in case we're already in a zone on reload)
    self:UpdateZoneTracking()
end

-- ============================================================================
-- Content Instance Registration System
-- ============================================================================

-- Register a content instance (dungeon, raid, or custom panel)
-- @param id: Unique identifier (e.g., "naxx_10n", "icc_25h", "custom_pvp")
-- @param data: Table with instance configuration
--   - name: Display name (e.g., "Naxxramas (10-Player)")
--   - type: "dungeon", "raid", or "custom"
--   - expansion: "classic", "tbc", "wotlk" (optional for custom)
--   - difficulty: 1-4 for dungeons/raids, nil for custom
--   - color: Color name from KOL.Colors.PASTEL (e.g., "SKY")
--   - zones: Array of zone names that trigger this instance (e.g., {"Naxxramas"})
--   - bosses: Array of boss configurations (flat list - no groups)
--     - name: Boss display name
--     - id: Boss NPC ID (for combat log detection)
--     - condition: Optional function for custom condition checking
--   - groups: Array of boss groups (alternative to flat bosses list)
--     - name: Group display name (e.g., "Arachnid Quarter")
--     - bosses: Array of boss configurations in this group
--   - objectives: Array of objective configurations (for custom panels)
--     - name: Objective display name
--     - condition: Function that returns true/false
--   - commandBlock: Name of command block to execute on zone entry (optional)
function Tracker:RegisterInstance(id, data)
    if self.instances[id] then
        KOL:DebugPrint("Tracker: Overwriting existing instance: " .. id, 2)
    end

    -- Validate data
    if not data.name then
        KOL:DebugPrint("Tracker: Cannot register instance without name: " .. id, 1)
        return false
    end

    if not data.type or (data.type ~= "dungeon" and data.type ~= "raid" and data.type ~= "custom") then
        KOL:DebugPrint("Tracker: Invalid type for instance: " .. id, 1)
        return false
    end

    -- Set defaults
    data.color = data.color or "PINK"
    data.zones = data.zones or {}
    data.bosses = data.bosses or {}
    data.groups = data.groups or {}
    data.objectives = data.objectives or {}

    -- Store instance
    self.instances[id] = data

    KOL:DebugPrint("Tracker: Registered instance: " .. id .. " (" .. data.name .. ")", 3)
    return true
end

-- Unregister a content instance
function Tracker:UnregisterInstance(id)
    if not self.instances[id] then
        KOL:DebugPrint("Tracker: Cannot unregister unknown instance: " .. id, 2)
        return false
    end

    -- Hide frame if active
    if self.activeFrames[id] then
        self.activeFrames[id]:Hide()
        self.activeFrames[id] = nil
    end

    self.instances[id] = nil
    KOL:DebugPrint("Tracker: Unregistered instance: " .. id, 3)
    return true
end

-- Get instance data by ID
function Tracker:GetInstance(id)
    return self.instances[id]
end

-- Get all registered instances
function Tracker:GetAllInstances()
    return self.instances
end

-- Find instance by current zone
function Tracker:FindInstanceByZone(zoneName)
    for id, data in pairs(self.instances) do
        for _, zone in ipairs(data.zones) do
            if zone == zoneName then
                return id, data
            end
        end
    end
    return nil, nil
end

-- ============================================================================
-- Boss Kill Tracking
-- ============================================================================

-- Mark a boss as killed
-- @param instanceId: Instance identifier
-- @param bossId: Boss identifier (name or index)
function Tracker:MarkBossKilled(instanceId, bossId)
    if not self.bossKills[instanceId] then
        self.bossKills[instanceId] = {}
    end

    self.bossKills[instanceId][bossId] = true
    KOL.db.profile.tracker.bossKills = self.bossKills

    KOL:DebugPrint("Tracker: Boss killed: " .. instanceId .. " / " .. tostring(bossId), 2)

    -- Update watch frame if active
    if self.activeFrames[instanceId] then
        self:UpdateWatchFrame(instanceId)
    end
end

-- Check if a boss is killed
-- @param instanceId: Instance identifier
-- @param bossId: Boss identifier (name or index)
-- @return: true if killed, false otherwise
function Tracker:IsBossKilled(instanceId, bossId)
    if not self.bossKills[instanceId] then
        return false
    end
    return self.bossKills[instanceId][bossId] == true
end

-- Reset boss kills for an instance
function Tracker:ResetInstance(instanceId)
    self.bossKills[instanceId] = {}
    KOL.db.profile.tracker.bossKills = self.bossKills

    KOL:DebugPrint("Tracker: Reset instance: " .. instanceId, 2)

    -- Update watch frame if active
    if self.activeFrames[instanceId] then
        self:UpdateWatchFrame(instanceId)
    end
end

-- Reset all boss kills
function Tracker:ResetAll()
    self.bossKills = {}
    KOL.db.profile.tracker.bossKills = self.bossKills

    KOL:DebugPrint("Tracker: Reset all instances", 2)

    -- Update all active watch frames
    for instanceId, _ in pairs(self.activeFrames) do
        self:UpdateWatchFrame(instanceId)
    end
end

-- ============================================================================
-- Boss Kill Detection (Combat Log)
-- ============================================================================

-- Combat log event handler for boss kills
function Tracker:OnCombatLogEvent(timestamp, eventType, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
                                   destGUID, destName, destFlags, destRaidFlags, ...)
    -- Only process UNIT_DIED events
    if eventType ~= "UNIT_DIED" then
        return
    end

    -- Extract NPC ID from GUID
    local npcId = self:ExtractNPCID(destGUID)
    if not npcId then
        return
    end

    -- Check all registered instances for matching boss
    for instanceId, data in pairs(self.instances) do
        -- Check flat bosses list
        if data.bosses and #data.bosses > 0 then
            for bossIndex, boss in ipairs(data.bosses) do
                if boss.id == npcId then
                    -- Boss killed!
                    self:MarkBossKilled(instanceId, bossIndex)
                    local colorHex = KOL.Colors:ToHex(KOL.Colors:GetPastel(data.color))
                    KOL:PrintTag("Boss defeated: |cFF" .. colorHex .. boss.name .. "|r")
                    return
                end
            end
        end

        -- Check grouped bosses
        if data.groups and #data.groups > 0 then
            for groupIndex, group in ipairs(data.groups) do
                if group.bosses then
                    for bossIndex, boss in ipairs(group.bosses) do
                        if boss.id == npcId then
                            -- Boss killed! Use group-boss ID format "g1-b2"
                            local bossId = "g" .. groupIndex .. "-b" .. bossIndex
                            self:MarkBossKilled(instanceId, bossId)
                            local colorHex = KOL.Colors:ToHex(KOL.Colors:GetPastel(data.color))
                            KOL:PrintTag("Boss defeated: |cFF" .. colorHex .. boss.name .. "|r")
                            return
                        end
                    end
                end
            end
        end
    end
end

-- Extract NPC ID from GUID
function Tracker:ExtractNPCID(guid)
    if not guid then return nil end

    -- GUID format: "Creature-0-ServerID-MapID-InstanceID-NpcID-SpawnID"
    local npcId = tonumber(string.match(guid, "Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)"))
    return npcId
end

-- ============================================================================
-- Zone Detection and Auto-Show/Hide
-- ============================================================================

-- Check current zone and show/hide watch frames
function Tracker:UpdateZoneTracking()
    -- Count registered instances
    local instanceCount = 0
    for _ in pairs(self.instances) do instanceCount = instanceCount + 1 end
    KOL:PrintTag("UpdateZoneTracking called - " .. instanceCount .. " instances registered")

    if not KOL.db.profile.tracker.autoShow then
        KOL:DebugPrint("Tracker: AutoShow disabled, skipping zone tracking", 3)
        return
    end

    local zoneName = GetRealZoneText() or GetZoneText()
    local subZoneName = GetSubZoneText()

    -- Get instance info for difficulty matching
    local name, instanceType, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic = GetInstanceInfo()

    KOL:DebugPrint("Tracker: Zone=" .. tostring(zoneName) .. ", SubZone=" .. tostring(subZoneName) .. ", InstanceType=" .. tostring(instanceType) .. ", Difficulty=" .. tostring(difficultyIndex), 2)

    -- Find matching instance
    local instanceId, instanceData
    local fallbackId, fallbackData  -- Fallback if difficulty doesn't match

    -- First, try to find by zone name AND difficulty
    for id, data in pairs(self.instances) do
        for _, zone in ipairs(data.zones) do
            if zone == zoneName or zone == subZoneName then
                KOL:DebugPrint("Tracker: Zone matched instance: " .. id .. " (difficulty " .. tostring(data.difficulty) .. ")", 3)

                -- Match difficulty if we're in an instance
                if instanceType ~= "none" and data.difficulty then
                    -- For raids, WotLK uses:
                    -- 1 = 10-player normal, 2 = 25-player normal
                    -- 3 = 10-player heroic, 4 = 25-player heroic
                    -- difficultyIndex from GetInstanceInfo returns these values
                    if data.difficulty == difficultyIndex then
                        instanceId = id
                        instanceData = data
                        KOL:DebugPrint("Tracker: Difficulty matched! Using " .. id, 2)
                        break
                    else
                        -- Store as fallback in case no exact match is found
                        if not fallbackId then
                            fallbackId = id
                            fallbackData = data
                            KOL:DebugPrint("Tracker: Difficulty mismatch, storing as fallback: " .. id, 3)
                        end
                    end
                elseif instanceType == "none" then
                    -- Not in an instance (outside), don't auto-show
                    instanceId = nil
                    instanceData = nil
                    KOL:DebugPrint("Tracker: Not in an instance (instanceType=none), skipping auto-show", 3)
                end
            end
        end
        if instanceId then break end
    end

    -- If no exact difficulty match, use fallback
    if not instanceId and fallbackId and instanceType ~= "none" then
        instanceId = fallbackId
        instanceData = fallbackData
        KOL:DebugPrint("Tracker: Using fallback instance: " .. instanceId, 2)
    end

    -- Hide all active frames that don't match current zone
    for activeId, frame in pairs(self.activeFrames) do
        if activeId ~= instanceId then
            frame:Hide()
            self.activeFrames[activeId] = nil
            KOL:DebugPrint("Tracker: Hidden watch frame: " .. activeId, 3)
        end
    end

    -- Show frame for current zone if found
    if instanceId and instanceData then
        KOL:DebugPrint("Tracker: Showing watch frame for: " .. instanceId, 2)

        -- Wrap in pcall to catch any errors
        local success, err = pcall(function()
            self:ShowWatchFrame(instanceId)
        end)

        if not success then
            KOL:PrintTag("ERROR: Failed to show watch frame: " .. tostring(err))
            KOL:DebugPrint("Tracker: ShowWatchFrame error: " .. tostring(err), 1)
        else
            KOL:DebugPrint("Tracker: ShowWatchFrame completed successfully", 2)
        end

        -- Execute command block if specified
        if instanceData.commandBlock and KOL.CommandBlocks then
            if KOL.CommandBlocks:Exists(instanceData.commandBlock) then
                KOL:DebugPrint("Tracker: Executing command block: " .. instanceData.commandBlock, 2)
                KOL.CommandBlocks:Execute(instanceData.commandBlock)
            end
        end
    else
        KOL:DebugPrint("Tracker: No instance found for zone: " .. tostring(zoneName), 2)
    end
end

-- ============================================================================
-- Event Registration
-- ============================================================================

function Tracker:RegisterEvents()
    -- Combat log for boss kills
    KOL:RegisterEventCallback("COMBAT_LOG_EVENT_UNFILTERED", function(...)
        Tracker:OnCombatLogEvent(...)
    end, "Tracker")

    -- Zone changes
    KOL:RegisterEventCallback("ZONE_CHANGED_NEW_AREA", function()
        Tracker:UpdateZoneTracking()
    end, "Tracker")

    KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
        Tracker:UpdateZoneTracking()
    end, "Tracker")

    KOL:DebugPrint("Tracker: Events registered", 3)
end

-- ============================================================================
-- Watch Frame System
-- ============================================================================

-- Helper to get per-instance setting with fallback to global
local function GetInstanceSetting(instanceId, key, defaultValue)
    if KOL.db.profile.tracker.instances and KOL.db.profile.tracker.instances[instanceId] then
        local value = KOL.db.profile.tracker.instances[instanceId][key]
        if value ~= nil then
            -- For dimensions, 0 means "use global"
            if (key == "frameWidth" or key == "frameHeight") and value == 0 then
                return nil  -- Will fall through to global
            end
            return value
        end
    end
    return defaultValue
end

-- Create a watch frame for an instance
-- @param instanceId: Instance identifier
-- @return: The created watch frame
function Tracker:CreateWatchFrame(instanceId)
    KOL:DebugPrint("Tracker: CreateWatchFrame called for: " .. instanceId, 2)

    local data = self.instances[instanceId]
    if not data then
        KOL:DebugPrint("Tracker: ERROR - Cannot create watch frame for unknown instance: " .. instanceId, 1)
        return nil
    end

    KOL:DebugPrint("Tracker: Instance data found: " .. data.name, 3)

    -- Get config settings (per-instance overrides global)
    local config = KOL.db.profile.tracker
    local frameWidth = GetInstanceSetting(instanceId, "frameWidth") or config.frameWidth or 250
    local frameHeight = GetInstanceSetting(instanceId, "frameHeight") or config.frameHeight or 300
    local scrollBarWidth = config.scrollBarWidth or 16
    local showMinimizeBtn = data.showMinimizeButton ~= false and config.showMinimizeButton ~= false
    local showScrollButtons = config.showScrollButtons ~= false

    -- Get instance color (check for per-instance title font color)
    local titleFontColor = GetInstanceSetting(instanceId, "titleFontColor")
    local instanceColor, instanceColorHex
    if titleFontColor then
        instanceColor = titleFontColor
        instanceColorHex = KOL.Colors:ToHex(titleFontColor)
    else
        instanceColor = KOL.Colors:GetPastel(data.color or "PINK")
        instanceColorHex = KOL.Colors:ToHex(instanceColor)
    end

    -- Get font settings (per-instance overrides)
    local titleFont = GetInstanceSetting(instanceId, "titleFont") or config.baseFont or "Friz Quadrata TT"
    local titleFontSize = GetInstanceSetting(instanceId, "titleFontSize") or 13
    local titleFontScale = GetInstanceSetting(instanceId, "titleFontScale") or 1.0
    local titleFontOutline = GetInstanceSetting(instanceId, "titleFontOutline") or "THICKOUTLINE"
    local fontScale = config.fontScale or 1.0

    -- Create main frame
    local frame = CreateFrame("Frame", "KOLTrackerFrame_" .. instanceId, UIParent)
    frame:SetSize(frameWidth, frameHeight)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)

    -- Store instance data on frame
    frame.instanceId = instanceId
    frame.instanceData = data
    frame.minimized = false
    frame.maxHeight = frameHeight

    -- Backdrop (with per-instance colors)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    local bgColor = GetInstanceSetting(instanceId, "backgroundColor")
    if bgColor then
        frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 0.95)
    else
        frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    end
    local borderColor = GetInstanceSetting(instanceId, "borderColor")
    if borderColor then
        frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
    else
        frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    end

    -- Title bar (with per-instance color)
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetSize(frameWidth - 2, 26)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
    })
    local titleBarColor = GetInstanceSetting(instanceId, "titleBarColor")
    if titleBarColor then
        titleBar:SetBackdropColor(titleBarColor[1], titleBarColor[2], titleBarColor[3], titleBarColor[4] or 1)
    else
        titleBar:SetBackdropColor(0.1, 0.1, 0.1, 1)
    end
    frame.titleBar = titleBar

    -- Title text (interactive - for dragging and double-click)
    -- Use per-instance font settings with fallback chain
    local titleFontPath
    if LSM then
        -- Try requested title font first
        local success, result = pcall(function() return LSM:Fetch("font", titleFont) end)
        if success and result then
            titleFontPath = result
            KOL:DebugPrint("Tracker: Title font loaded: " .. titleFont, 3)
        else
            KOL:DebugPrint("Tracker: Failed to load title font '" .. titleFont .. "', trying general font", 2)
            -- Try general font as fallback
            local generalFont = KOL.db.profile.generalFont or "Friz Quadrata TT"
            success, result = pcall(function() return LSM:Fetch("font", generalFont) end)
            if success and result then
                titleFontPath = result
                KOL:DebugPrint("Tracker: Using general font: " .. generalFont, 3)
            end
        end
    else
        KOL:DebugPrint("Tracker: LSM not available", 2)
    end

    -- Final fallback to hardcoded default
    titleFontPath = titleFontPath or "Fonts\\FRIZQT__.TTF"
    KOL:DebugPrint("Tracker: Final title font path: " .. titleFontPath, 3)

    local actualTitleFontSize = math.floor(titleFontSize * titleFontScale)
    local titleText = CreateFrame("Button", nil, titleBar)
    titleText:SetPoint("TOPLEFT", titleBar, "TOPLEFT", 8, 0)
    titleText:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", showMinimizeBtn and -30 or -8, 0)
    titleText:EnableMouse(true)
    titleText:RegisterForClicks("AnyUp")
    titleText:RegisterForDrag("LeftButton")

    local titleString = titleText:CreateFontString(nil, "OVERLAY")
    titleString:SetFont(titleFontPath, actualTitleFontSize, titleFontOutline)
    titleString:SetPoint("CENTER", titleText, "CENTER", 0, 0)

    -- Use custom title text if set
    local titleTextContent = GetInstanceSetting(instanceId, "titleText")
    if not titleTextContent or titleTextContent == "" then
        titleTextContent = data.name
    end
    titleString:SetText("|cFF" .. instanceColorHex .. titleTextContent .. "|r")
    titleString:SetJustifyH("LEFT")
    titleString:SetWordWrap(false)
    titleText.text = titleString

    -- Double-click to minimize
    titleText.lastClick = 0
    titleText:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            local currentTime = GetTime()
            if currentTime - self.lastClick < 0.3 then
                -- Double-click detected
                Tracker:ToggleMinimize(frame)
                self.lastClick = 0
            else
                self.lastClick = currentTime
            end
        end
    end)

    -- Dragging from title text
    titleText:SetScript("OnDragStart", function(self)
        frame:StartMoving()
    end)
    titleText:SetScript("OnDragStop", function(self)
        frame:StopMovingOrSizing()
        Tracker:SaveFramePosition(instanceId)
    end)

    frame.titleText = titleText

    -- Minimize button (optional)
    local minimizeBtn
    if showMinimizeBtn then
        minimizeBtn = CreateFrame("Button", nil, titleBar)
        minimizeBtn:SetSize(20, 20)
        minimizeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -3, 0)
        minimizeBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        minimizeBtn:SetBackdropColor(0.2, 0.2, 0.2, 1)
        minimizeBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        local minBtnText = minimizeBtn:CreateFontString(nil, "OVERLAY")
        local minFontPath, minFontSize, minFontOutline = GetAveragedFont(11 * fontScale)
        minBtnText:SetFont(minFontPath, minFontSize, minFontOutline)
        minBtnText:SetPoint("CENTER")
        minBtnText:SetText("-")
        minBtnText:SetTextColor(0.8, 0.8, 0.8, 1)
        minimizeBtn.text = minBtnText

        minimizeBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.3, 0.3, 0.3, 1)
            self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end)
        minimizeBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.2, 0.2, 0.2, 1)
            self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end)
        minimizeBtn:SetScript("OnClick", function(self)
            Tracker:ToggleMinimize(frame)
        end)
    end
    frame.minimizeBtn = minimizeBtn

    -- Content scroll frame (custom implementation)
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
    local scrollBarPadding = scrollBarWidth + 8
    scrollFrame:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -scrollBarPadding, 4)
    frame.scrollFrame = scrollFrame

    -- Content frame (inside scroll frame)
    local contentWidth = frameWidth - scrollBarPadding - 8
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(contentWidth, 1)
    scrollFrame:SetScrollChild(content)
    frame.content = content

    -- Scroll buttons (optional)
    local scrollUpBtn, scrollDownBtn
    local scrollBarTopOffset = -30
    local scrollBarBottomOffset = 4

    if showScrollButtons then
        -- Up button
        scrollUpBtn = CreateFrame("Button", nil, frame)
        scrollUpBtn:SetSize(scrollBarWidth, scrollBarWidth)
        scrollUpBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, scrollBarTopOffset)
        scrollUpBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        scrollUpBtn:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
        scrollUpBtn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

        local upText = scrollUpBtn:CreateFontString(nil, "OVERLAY")
        upText:SetFont(fontPath, scrollBarWidth - 2, fontOutline)
        upText:SetPoint("CENTER", 0, 0)
        upText:SetText("▲")
        upText:SetTextColor(0.6, 0.6, 0.6, 1)
        scrollUpBtn.text = upText

        scrollUpBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.25, 0.25, 0.25, 1)
            self.text:SetTextColor(0.9, 0.9, 0.9, 1)
        end)
        scrollUpBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
            self.text:SetTextColor(0.6, 0.6, 0.6, 1)
        end)

        frame.scrollUpBtn = scrollUpBtn

        -- Down button
        scrollDownBtn = CreateFrame("Button", nil, frame)
        scrollDownBtn:SetSize(scrollBarWidth, scrollBarWidth)
        scrollDownBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, scrollBarBottomOffset)
        scrollDownBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        scrollDownBtn:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
        scrollDownBtn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

        local downText = scrollDownBtn:CreateFontString(nil, "OVERLAY")
        downText:SetFont(fontPath, scrollBarWidth - 2, fontOutline)
        downText:SetPoint("CENTER", 0, 0)
        downText:SetText("▼")
        downText:SetTextColor(0.6, 0.6, 0.6, 1)
        scrollDownBtn.text = downText

        scrollDownBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.25, 0.25, 0.25, 1)
            self.text:SetTextColor(0.9, 0.9, 0.9, 1)
        end)
        scrollDownBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
            self.text:SetTextColor(0.6, 0.6, 0.6, 1)
        end)

        frame.scrollDownBtn = scrollDownBtn

        -- Adjust scroll bar position to account for buttons
        scrollBarTopOffset = scrollBarTopOffset - scrollBarWidth - 2
        scrollBarBottomOffset = scrollBarBottomOffset + scrollBarWidth + 2
    end

    -- Custom scroll bar
    local scrollBar = CreateFrame("Slider", nil, frame)
    scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, scrollBarTopOffset)
    scrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, scrollBarBottomOffset)
    scrollBar:SetWidth(scrollBarWidth)
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetValueStep(1)
    scrollBar:SetMinMaxValues(0, 100)
    scrollBar:SetValue(0)
    scrollBar:EnableMouseWheel(true)
    frame.scrollBar = scrollBar

    -- Scroll bar backdrop (with per-instance colors)
    scrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    local scrollBarColor = GetInstanceSetting(instanceId, "scrollBarColor")
    if scrollBarColor then
        scrollBar:SetBackdropColor(scrollBarColor[1], scrollBarColor[2], scrollBarColor[3], scrollBarColor[4] or 0.9)
    else
        scrollBar:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    end
    scrollBar:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -- Scroll bar thumb (with per-instance color)
    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetSize(scrollBarWidth, 20)
    local scrollThumbColor = GetInstanceSetting(instanceId, "scrollThumbColor")
    if scrollThumbColor then
        thumb:SetVertexColor(scrollThumbColor[1], scrollThumbColor[2], scrollThumbColor[3], scrollThumbColor[4] or 1)
    else
        thumb:SetVertexColor(0.3, 0.3, 0.3, 1)
    end
    scrollBar:SetThumbTexture(thumb)

    -- Scroll bar scripts
    scrollBar:SetScript("OnValueChanged", function(self, value)
        local scrollRange = content:GetHeight() - scrollFrame:GetHeight()
        if scrollRange > 0 then
            scrollFrame:SetVerticalScroll(value)
        else
            scrollFrame:SetVerticalScroll(0)
        end
    end)

    scrollBar:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetValue()
        local minVal, maxVal = self:GetMinMaxValues()
        local step = 20
        if delta < 0 then
            self:SetValue(math.min(maxVal, current + step))
        else
            self:SetValue(math.max(minVal, current - step))
        end
    end)

    -- Scroll button clicks
    if scrollUpBtn then
        scrollUpBtn:SetScript("OnClick", function()
            local current = scrollBar:GetValue()
            local minVal, maxVal = scrollBar:GetMinMaxValues()
            scrollBar:SetValue(math.max(minVal, current - 20))
        end)
    end

    if scrollDownBtn then
        scrollDownBtn:SetScript("OnClick", function()
            local current = scrollBar:GetValue()
            local minVal, maxVal = scrollBar:GetMinMaxValues()
            scrollBar:SetValue(math.min(maxVal, current + 20))
        end)
    end

    -- Enable mouse wheel on scroll frame too
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        scrollBar:GetScript("OnMouseWheel")(scrollBar, delta)
    end)

    -- Update scroll bar range when content changes (hide if not needed)
    scrollFrame:SetScript("OnScrollRangeChanged", function(self, xRange, yRange)
        local scrollRange = yRange
        if scrollRange > 0 then
            scrollBar:SetMinMaxValues(0, scrollRange)
            scrollBar:Show()
            if scrollUpBtn then scrollUpBtn:Show() end
            if scrollDownBtn then scrollDownBtn:Show() end
        else
            scrollBar:SetMinMaxValues(0, 0)
            scrollBar:SetValue(0)
            scrollBar:Hide()
            if scrollUpBtn then scrollUpBtn:Hide() end
            if scrollDownBtn then scrollDownBtn:Hide() end
        end
    end)

    -- Boss list (will be populated by UpdateWatchFrame)
    frame.bossTexts = {}

    -- UI visibility (hide UI / show on mouseover)
    local function UpdateUIVisibility(isMouseOver)
        -- Check for per-instance settings first, then fallback to global
        local hideUI = GetInstanceSetting(instanceId, "hideUI")
        if hideUI == nil then
            hideUI = KOL.db.profile.tracker.hideUI
        end

        local showOnMouseover = GetInstanceSetting(instanceId, "showUIOnMouseover")
        if showOnMouseover == nil then
            showOnMouseover = KOL.db.profile.tracker.showUIOnMouseover
        end

        -- Get the configured colors (will be used when showing UI)
        local showBg = bgColor or {0.05, 0.05, 0.05, 0.95}
        local showBorder = borderColor or {0.2, 0.2, 0.2, 1}
        local showTitle = titleBarColor or {0.1, 0.1, 0.1, 1}

        if hideUI then
            if showOnMouseover and isMouseOver then
                -- Show all UI elements on mouseover with configured colors
                self:SetBackdropColor(showBg[1], showBg[2], showBg[3], showBg[4])
                self:SetBackdropBorderColor(showBorder[1], showBorder[2], showBorder[3], showBorder[4])
                self.titleBar:SetBackdropColor(showTitle[1], showTitle[2], showTitle[3], showTitle[4])
                if self.scrollBar then self.scrollBar:SetAlpha(1) end
                if self.scrollUpBtn then self.scrollUpBtn:SetAlpha(1) end
                if self.scrollDownBtn then self.scrollDownBtn:SetAlpha(1) end
                if self.minimizeBtn then self.minimizeBtn:SetAlpha(1) end
            else
                -- Hide all UI elements (set alpha to 0)
                self:SetBackdropColor(showBg[1], showBg[2], showBg[3], 0)
                self:SetBackdropBorderColor(showBorder[1], showBorder[2], showBorder[3], 0)
                self.titleBar:SetBackdropColor(showTitle[1], showTitle[2], showTitle[3], 0)
                if self.scrollBar then self.scrollBar:SetAlpha(0) end
                if self.scrollUpBtn then self.scrollUpBtn:SetAlpha(0) end
                if self.scrollDownBtn then self.scrollDownBtn:SetAlpha(0) end
                if self.minimizeBtn then self.minimizeBtn:SetAlpha(0) end
            end
        else
            -- Normal visibility (UI always shown) with configured colors
            self:SetBackdropColor(showBg[1], showBg[2], showBg[3], showBg[4])
            self:SetBackdropBorderColor(showBorder[1], showBorder[2], showBorder[3], showBorder[4])
            self.titleBar:SetBackdropColor(showTitle[1], showTitle[2], showTitle[3], showTitle[4])
            if self.scrollBar then self.scrollBar:SetAlpha(1) end
            if self.scrollUpBtn then self.scrollUpBtn:SetAlpha(1) end
            if self.scrollDownBtn then self.scrollDownBtn:SetAlpha(1) end
            if self.minimizeBtn then self.minimizeBtn:SetAlpha(1) end
        end
    end

    -- Initialize UI visibility
    UpdateUIVisibility(false)

    -- Mouseover scripts
    frame:SetScript("OnEnter", function(self)
        UpdateUIVisibility(true)
    end)
    frame:SetScript("OnLeave", function(self)
        UpdateUIVisibility(false)
    end)

    -- Store frame
    self.activeFrames[instanceId] = frame

    KOL:DebugPrint("Tracker: Created watch frame for: " .. instanceId, 2)
    return frame
end

-- Update watch frame content (boss list)
function Tracker:UpdateWatchFrame(instanceId)
    local frame = self.activeFrames[instanceId]
    if not frame then
        KOL:DebugPrint("Tracker: Cannot update non-existent watch frame: " .. instanceId, 2)
        return
    end

    local data = frame.instanceData
    local content = frame.content

    -- Clear existing boss texts
    for _, text in ipairs(frame.bossTexts) do
        text:Hide()
    end
    frame.bossTexts = {}

    -- Get colors
    local instanceColor = KOL.Colors:GetPastel(data.color or "PINK")
    local killedColor = KOL.Colors:GetPastel("GREEN")
    local unkilledColor = KOL.Colors:GetPastel("RED")

    local instanceColorHex = KOL.Colors:ToHex(instanceColor)
    local killedColorHex = KOL.Colors:ToHex(killedColor)
    local unkilledColorHex = KOL.Colors:ToHex(unkilledColor)

    -- Get font scale
    local fontScale = KOL.db.profile.tracker.fontScale or 1.0
    local fontPath, fontSize, fontOutline = GetAveragedFont(11 * fontScale)

    -- Create boss texts
    local yOffset = -4
    local contentHeight = 0

    -- Render flat bosses (no groups)
    if data.bosses and #data.bosses > 0 then
        for i, boss in ipairs(data.bosses) do
            local bossText = content:CreateFontString(nil, "OVERLAY")
            bossText:SetFont(fontPath, fontSize, fontOutline)
            bossText:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
            bossText:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, yOffset)
            bossText:SetJustifyH("LEFT")
            bossText:SetWordWrap(true)

            -- Check if boss is killed
            local killed = self:IsBossKilled(instanceId, i)
            local colorHex = killed and killedColorHex or unkilledColorHex
            local checkMark = killed and "✓ " or "• "

            bossText:SetText("|cFF" .. colorHex .. checkMark .. boss.name .. "|r")

            table.insert(frame.bossTexts, bossText)

            -- Update yOffset for next boss
            local textHeight = bossText:GetStringHeight()
            yOffset = yOffset - textHeight - 2
            contentHeight = contentHeight + textHeight + 2
        end

    -- Render grouped bosses (with group headers)
    elseif data.groups and #data.groups > 0 then
        local groupFontPath, groupFontSize, groupFontOutline = GetAveragedFont(10 * fontScale)

        for groupIndex, group in ipairs(data.groups) do
            -- Group header
            local groupHeader = content:CreateFontString(nil, "OVERLAY")
            groupHeader:SetFont(groupFontPath, groupFontSize, groupFontOutline)
            groupHeader:SetPoint("TOPLEFT", content, "TOPLEFT", 2, yOffset)
            groupHeader:SetPoint("TOPRIGHT", content, "TOPRIGHT", -2, yOffset)
            groupHeader:SetJustifyH("LEFT")
            groupHeader:SetText("|cFF" .. instanceColorHex .. "[" .. group.name .. "]|r")
            table.insert(frame.bossTexts, groupHeader)

            local headerHeight = groupHeader:GetStringHeight()
            yOffset = yOffset - headerHeight - 1
            contentHeight = contentHeight + headerHeight + 1

            -- Group bosses
            if group.bosses then
                for bossIndex, boss in ipairs(group.bosses) do
                    local bossText = content:CreateFontString(nil, "OVERLAY")
                    bossText:SetFont(fontPath, fontSize, fontOutline)
                    bossText:SetPoint("TOPLEFT", content, "TOPLEFT", 8, yOffset)  -- Indent bosses
                    bossText:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, yOffset)
                    bossText:SetJustifyH("LEFT")
                    bossText:SetWordWrap(true)

                    -- Check if boss is killed (using group-boss ID format)
                    local bossId = "g" .. groupIndex .. "-b" .. bossIndex
                    local killed = self:IsBossKilled(instanceId, bossId)
                    local colorHex = killed and killedColorHex or unkilledColorHex
                    local checkMark = killed and "✓ " or "• "

                    bossText:SetText("|cFF" .. colorHex .. checkMark .. boss.name .. "|r")

                    table.insert(frame.bossTexts, bossText)

                    -- Update yOffset for next boss
                    local textHeight = bossText:GetStringHeight()
                    yOffset = yOffset - textHeight - 1
                    contentHeight = contentHeight + textHeight + 1
                end
            end

            -- Add spacing after group
            yOffset = yOffset - 4
            contentHeight = contentHeight + 4
        end

    -- Render custom panel objectives
    elseif data.objectives and #data.objectives > 0 then
        -- Custom panel objectives
        for i, objective in ipairs(data.objectives) do
            local objText = content:CreateFontString(nil, "OVERLAY")
            objText:SetFont(fontPath, fontSize, fontOutline)
            objText:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
            objText:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, yOffset)
            objText:SetJustifyH("LEFT")
            objText:SetWordWrap(true)

            -- Check objective condition (if function provided)
            local completed = false
            if objective.condition and type(objective.condition) == "function" then
                local success, result = pcall(objective.condition)
                completed = success and result
            end

            local colorHex = completed and killedColorHex or unkilledColorHex
            local checkMark = completed and "✓ " or "• "

            objText:SetText("|cFF" .. colorHex .. checkMark .. objective.name .. "|r")

            table.insert(frame.bossTexts, objText)

            -- Update yOffset for next objective
            local textHeight = objText:GetStringHeight()
            yOffset = yOffset - textHeight - 2
            contentHeight = contentHeight + textHeight + 2
        end
    else
        -- No bosses or objectives
        local noDataText = content:CreateFontString(nil, "OVERLAY")
        noDataText:SetFont(fontPath, fontSize, fontOutline)
        noDataText:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
        noDataText:SetText("|cFFAAAAAAAANo objectives defined|r")
        table.insert(frame.bossTexts, noDataText)
        contentHeight = 20
    end

    -- Update content size
    content:SetHeight(math.max(contentHeight, 1))

    KOL:DebugPrint("Tracker: Updated watch frame: " .. instanceId, 3)
end

-- Show watch frame for an instance
function Tracker:ShowWatchFrame(instanceId)
    KOL:DebugPrint("Tracker: ShowWatchFrame called for: " .. instanceId, 2)

    local frame = self.activeFrames[instanceId]

    -- Create frame if it doesn't exist
    if not frame then
        KOL:DebugPrint("Tracker: Frame doesn't exist, creating new frame for: " .. instanceId, 2)
        frame = self:CreateWatchFrame(instanceId)
        if not frame then
            KOL:DebugPrint("Tracker: ERROR - CreateWatchFrame returned nil for: " .. instanceId, 1)
            return
        end
        KOL:DebugPrint("Tracker: Frame created successfully for: " .. instanceId, 2)
    else
        KOL:DebugPrint("Tracker: Frame already exists for: " .. instanceId, 3)
    end

    -- Update content
    KOL:DebugPrint("Tracker: Updating watch frame content for: " .. instanceId, 3)
    self:UpdateWatchFrame(instanceId)

    -- Restore position
    KOL:DebugPrint("Tracker: Restoring frame position for: " .. instanceId, 3)
    self:RestoreFramePosition(instanceId)

    -- Show frame
    KOL:DebugPrint("Tracker: Calling Show() on frame for: " .. instanceId, 3)
    frame:Show()

    KOL:DebugPrint("Tracker: Watch frame shown successfully: " .. instanceId .. " (IsShown: " .. tostring(frame:IsShown()) .. ")", 2)
end

-- Toggle minimize/maximize
function Tracker:ToggleMinimize(frame)
    if not frame then return end

    if frame.minimized then
        -- Maximize
        frame:SetHeight(frame.maxHeight or 300)
        frame.scrollFrame:Show()
        if frame.scrollBar then frame.scrollBar:Show() end
        if frame.scrollUpBtn then frame.scrollUpBtn:Show() end
        if frame.scrollDownBtn then frame.scrollDownBtn:Show() end
        if frame.minimizeBtn and frame.minimizeBtn.text then
            frame.minimizeBtn.text:SetText("-")
        end
        frame.minimized = false
        KOL:DebugPrint("Tracker: Maximized watch frame: " .. frame.instanceId, 3)
    else
        -- Minimize
        frame:SetHeight(26)
        frame.scrollFrame:Hide()
        if frame.scrollBar then frame.scrollBar:Hide() end
        if frame.scrollUpBtn then frame.scrollUpBtn:Hide() end
        if frame.scrollDownBtn then frame.scrollDownBtn:Hide() end
        if frame.minimizeBtn and frame.minimizeBtn.text then
            frame.minimizeBtn.text:SetText("+")
        end
        frame.minimized = true
        KOL:DebugPrint("Tracker: Minimized watch frame: " .. frame.instanceId, 3)
    end
end

-- Save frame position
function Tracker:SaveFramePosition(instanceId)
    local frame = self.activeFrames[instanceId]
    if not frame then return end

    local point, _, relativePoint, x, y = frame:GetPoint()

    if not KOL.db.profile.tracker.framePositions then
        KOL.db.profile.tracker.framePositions = {}
    end

    KOL.db.profile.tracker.framePositions[instanceId] = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }

    KOL:DebugPrint("Tracker: Saved position for: " .. instanceId, 3)
end

-- Restore frame position
function Tracker:RestoreFramePosition(instanceId)
    local frame = self.activeFrames[instanceId]
    if not frame then return end

    local pos = KOL.db.profile.tracker.framePositions and KOL.db.profile.tracker.framePositions[instanceId]

    if pos then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
        KOL:DebugPrint("Tracker: Restored position for: " .. instanceId, 3)
    else
        -- Default position (center)
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        KOL:DebugPrint("Tracker: Using default position for: " .. instanceId, 3)
    end
end

-- ============================================================================
-- Custom Panel Management
-- ============================================================================

-- Create a new custom panel
-- @param name: Panel display name
-- @param zones: Array of zone names
-- @param color: Color name or RGB array
-- @param panelType: "objective" or "grouped"
-- @param data: Additional data (objectives or groups)
function Tracker:CreateCustomPanel(name, zones, color, panelType, data)
    if not name or name == "" then
        KOL:PrintTag(RED("Error:") .. " Panel name is required")
        return false
    end

    -- Generate unique ID
    local panelId = "custom_" .. string.gsub(string.lower(name), "%s+", "_") .. "_" .. tostring(math.random(1000, 9999))

    -- Ensure it's unique
    while self.instances[panelId] do
        panelId = "custom_" .. string.gsub(string.lower(name), "%s+", "_") .. "_" .. tostring(math.random(1000, 9999))
    end

    -- Create panel data
    local panelData = {
        name = name,
        type = "custom",
        zones = zones or {},
        color = color or "PINK",
        objectives = {},
        groups = {},
    }

    -- Add objectives or groups based on panel type
    if panelType == "objective" and data.objectives then
        panelData.objectives = data.objectives
    elseif panelType == "grouped" and data.groups then
        panelData.groups = data.groups
    end

    -- Register the panel
    self:RegisterInstance(panelId, panelData)

    -- Save to DB
    if not KOL.db.profile.tracker.customPanels then
        KOL.db.profile.tracker.customPanels = {}
    end
    KOL.db.profile.tracker.customPanels[panelId] = panelData

    KOL:PrintTag("Created custom panel: " .. GREEN(name))

    -- Refresh config UI
    if KOL.PopulateTrackerConfigUI then
        KOL:PopulateTrackerConfigUI()
        LibStub("AceConfigRegistry-3.0"):NotifyChange("Koality-of-Life")
    end

    return panelId
end

-- Update an existing custom panel
function Tracker:UpdateCustomPanel(panelId, name, zones, color, panelType, data)
    if not self.instances[panelId] then
        KOL:PrintTag(RED("Error:") .. " Panel not found: " .. panelId)
        return false
    end

    local panelData = self.instances[panelId]

    -- Update fields
    if name then panelData.name = name end
    if zones then panelData.zones = zones end
    if color then panelData.color = color end

    -- Update objectives or groups
    if panelType == "objective" and data.objectives then
        panelData.objectives = data.objectives
        panelData.groups = {}
    elseif panelType == "grouped" and data.groups then
        panelData.groups = data.groups
        panelData.objectives = {}
    end

    -- Save to DB
    if not KOL.db.profile.tracker.customPanels then
        KOL.db.profile.tracker.customPanels = {}
    end
    KOL.db.profile.tracker.customPanels[panelId] = panelData

    KOL:PrintTag("Updated custom panel: " .. GREEN(panelData.name))

    -- Update active frame if it exists
    if self.activeFrames[panelId] then
        self:UpdateWatchFrame(panelId)
    end

    -- Refresh config UI
    if KOL.PopulateTrackerConfigUI then
        KOL:PopulateTrackerConfigUI()
        LibStub("AceConfigRegistry-3.0"):NotifyChange("Koality-of-Life")
    end

    return true
end

-- Delete a custom panel
function Tracker:DeleteCustomPanel(panelId)
    if not self.instances[panelId] then
        KOL:PrintTag(RED("Error:") .. " Panel not found: " .. panelId)
        return false
    end

    local panelData = self.instances[panelId]
    local panelName = panelData.name

    -- Unregister the instance
    self:UnregisterInstance(panelId)

    -- Remove from DB
    if KOL.db.profile.tracker.customPanels then
        KOL.db.profile.tracker.customPanels[panelId] = nil
    end

    KOL:PrintTag("Deleted custom panel: " .. RED(panelName))

    -- Refresh config UI
    if KOL.PopulateTrackerConfigUI then
        KOL:PopulateTrackerConfigUI()
        LibStub("AceConfigRegistry-3.0"):NotifyChange("Koality-of-Life")
    end

    return true
end

-- Load custom panels from DB
function Tracker:LoadCustomPanels()
    if not KOL.db.profile.tracker.customPanels then
        return
    end

    for panelId, panelData in pairs(KOL.db.profile.tracker.customPanels) do
        self:RegisterInstance(panelId, panelData)
        KOL:DebugPrint("Tracker: Loaded custom panel: " .. panelId, 2)
    end
end

-- ============================================================================
-- Debug / Testing
-- ============================================================================

-- Slash command for testing
function Tracker:DebugCommand(...)
    local args = {...}
    local cmd = args[1] and string.lower(args[1]) or ""

    if cmd == "list" then
        KOL:PrintTag("Registered instances:")
        for id, data in pairs(self.instances) do
            KOL:Print("  " .. id .. ": " .. data.name .. " (" .. data.type .. ")")
        end
    elseif cmd == "zone" then
        local zone = GetRealZoneText() or GetZoneText()
        local subzone = GetSubZoneText()
        local name, instanceType, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic = GetInstanceInfo()

        KOL:PrintTag("Current zone: " .. tostring(zone))
        KOL:Print("Current subzone: " .. tostring(subzone))
        KOL:Print("Instance type: " .. tostring(instanceType))
        KOL:Print("Difficulty index: " .. tostring(difficultyIndex))
        KOL:Print("Difficulty name: " .. tostring(difficultyName))
        KOL:Print("Max players: " .. tostring(maxPlayers))
        KOL:Print("AutoShow enabled: " .. tostring(KOL.db.profile.tracker.autoShow))

        -- Check all matching instances
        KOL:Print("Matching instances:")
        local foundAny = false
        for id, data in pairs(self.instances) do
            for _, zoneCheck in ipairs(data.zones) do
                if zoneCheck == zone or zoneCheck == subzone then
                    local diffMatch = (data.difficulty == difficultyIndex) and "YES" or "NO"
                    KOL:Print("  " .. id .. ": " .. data.name .. " (difficulty " .. tostring(data.difficulty) .. ", match: " .. diffMatch .. ")")
                    foundAny = true
                end
            end
        end
        if not foundAny then
            KOL:Print("  None")
        end

        -- Check active frames
        KOL:Print("Active frames:")
        local activeCount = 0
        for id, frame in pairs(self.activeFrames) do
            KOL:Print("  " .. id .. " (" .. (frame:IsShown() and "visible" or "hidden") .. ")")
            activeCount = activeCount + 1
        end
        if activeCount == 0 then
            KOL:Print("  None")
        end
    elseif cmd == "reset" then
        self:ResetAll()
        KOL:PrintTag("All boss kills reset")
    elseif cmd == "kills" then
        KOL:PrintTag("Boss kills:")
        for instanceId, kills in pairs(self.bossKills) do
            KOL:Print("  " .. instanceId .. ":")
            for bossId, killed in pairs(kills) do
                KOL:Print("    Boss " .. tostring(bossId) .. ": " .. (killed and "KILLED" or "alive"))
            end
        end
    elseif cmd == "test" then
        -- Register a test instance (flat bosses)
        self:RegisterInstance("test_dungeon", {
            name = "Test Dungeon",
            type = "dungeon",
            expansion = "wotlk",
            difficulty = 1,
            color = "SKY",
            zones = {"Test Zone"},
            bosses = {
                {name = "Boss 1", id = 12345},
                {name = "Boss 2", id = 12346},
                {name = "Boss 3", id = 12347},
                {name = "Final Boss", id = 12348},
            }
        })
        -- Show the test watch frame
        self:ShowWatchFrame("test_dungeon")
        KOL:PrintTag("Test watch frame shown (flat). Try: /kol tracker kill test_dungeon 1")
    elseif cmd == "testgroup" then
        -- Register a test instance (grouped bosses)
        self:RegisterInstance("test_raid", {
            name = "Test Raid (Grouped)",
            type = "raid",
            expansion = "wotlk",
            difficulty = 1,
            color = "PURPLE",
            zones = {"Test Zone"},
            groups = {
                {
                    name = "Wing One",
                    bosses = {
                        {name = "First Boss", id = 99901},
                        {name = "Second Boss", id = 99902},
                    }
                },
                {
                    name = "Wing Two",
                    bosses = {
                        {name = "Third Boss", id = 99903},
                        {name = "Fourth Boss", id = 99904},
                        {name = "Final Boss", id = 99905},
                    }
                },
            }
        })
        -- Show the test watch frame
        self:ShowWatchFrame("test_raid")
        KOL:PrintTag("Test watch frame shown (grouped). Try: /kol tracker kill test_raid g1-b1")
    elseif cmd == "kill" then
        local instanceId = args[2]
        local bossId = args[3]
        if instanceId and bossId then
            -- Try to convert to number, otherwise use as string (for grouped bosses)
            local bossIdFinal = tonumber(bossId) or bossId
            self:MarkBossKilled(instanceId, bossIdFinal)
            KOL:PrintTag("Marked boss " .. tostring(bossIdFinal) .. " as killed in " .. instanceId)
        else
            KOL:PrintTag("Usage: /kol tracker kill <instanceId> <bossId>")
            KOL:Print("  For flat bosses: /kol tracker kill test_dungeon 1")
            KOL:Print("  For grouped bosses: /kol tracker kill test_raid g1-b1")
        end
    elseif cmd == "show" then
        local instanceId = args[2]
        if instanceId then
            local success, err = pcall(function()
                self:ShowWatchFrame(instanceId)
            end)
            if success then
                KOL:PrintTag("Showed watch frame: " .. instanceId)
            else
                KOL:PrintTag("ERROR showing frame: " .. tostring(err))
            end
        else
            KOL:PrintTag("Usage: /kol tracker show <instanceId>")
        end
    elseif cmd == "update" or cmd == "refresh" then
        KOL:PrintTag("Manually triggering zone tracking update...")
        self:UpdateZoneTracking()
        KOL:PrintTag("Zone tracking update complete")
    elseif cmd == "autoshow" then
        local setting = args[2]
        if setting == "on" or setting == "true" or setting == "1" then
            KOL.db.profile.tracker.autoShow = true
            KOL:PrintTag("AutoShow enabled")
            self:UpdateZoneTracking()
        elseif setting == "off" or setting == "false" or setting == "0" then
            KOL.db.profile.tracker.autoShow = false
            KOL:PrintTag("AutoShow disabled")
        else
            KOL:PrintTag("AutoShow is currently: " .. tostring(KOL.db.profile.tracker.autoShow))
            KOL:Print("Usage: /kol tracker autoshow <on|off>")
        end
    else
        KOL:PrintTag("Tracker debug commands:")
        KOL:Print("  /kol tracker list - List all registered instances")
        KOL:Print("  /kol tracker zone - Show current zone info and diagnostics")
        KOL:Print("  /kol tracker update - Manually trigger zone tracking update")
        KOL:Print("  /kol tracker autoshow <on|off> - Toggle or check autoshow setting")
        KOL:Print("  /kol tracker kills - Show boss kill status")
        KOL:Print("  /kol tracker reset - Reset all boss kills")
        KOL:Print("  /kol tracker test - Show test watch frame (flat bosses)")
        KOL:Print("  /kol tracker testgroup - Show test watch frame (grouped bosses)")
        KOL:Print("  /kol tracker kill <id> <boss> - Mark a boss as killed")
        KOL:Print("  /kol tracker show <id> - Show a watch frame")
    end
end

-- ============================================================================
-- Module Initialization
-- ============================================================================

-- Initialize on PLAYER_ENTERING_WORLD
KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
    if KOL.Tracker and not KOL.Tracker.initialized then
        KOL.Tracker:Initialize()
        KOL.Tracker.initialized = true
    end
end, "Tracker")

-- Register slash command
KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
    KOL:RegisterSlashCommand("tracker", function(...)
        KOL.Tracker:DebugCommand(...)
    end, "Progress Tracker debug commands", "module")
end, "Tracker")

KOL:DebugPrint("Tracker module loaded", 1)
