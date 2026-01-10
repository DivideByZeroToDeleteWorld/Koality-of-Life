-- ============================================================================
-- !Koality-of-Life: Progress Tracker Module
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

-- Multi-NPC boss tracking (which individual NPCs have died)
-- Format: [instanceId][bossId][npcId] = true
Tracker.multiNPCKills = {}

-- Multi-phase boss tracking (how many times the same boss has been killed)
-- Format: [instanceId][bossId] = killCount
Tracker.multiPhaseKills = {}

-- Instance lockout IDs (to detect resets)
-- Format: [instanceId] = lockoutInstanceID
Tracker.instanceLockouts = {}

-- Track last instance exit time (to detect resets on re-entry)
-- Format: [instanceId] = timestamp
Tracker.lastExitTime = {}

-- Track current instance player is in (for exit detection)
Tracker.currentInstanceId = nil

-- Flag to ignore UPDATE_INSTANCE_INFO during initial load/reload
-- This prevents false resets when the event fires on login/reload
Tracker.initialLoadComplete = false

-- Hardmode state tracking (which bosses are in hardmode)
-- Format: [instanceId][bossId] = true/false
Tracker.hardmodeActive = {}

-- Cached frame for text measurement (avoid creating new frames every update)
Tracker.textMeasureFrame = nil
Tracker.textMeasureString = nil

-- ============================================================================
-- Frame Pool System (prevents memory leaks from repeated CreateFrame calls)
-- ============================================================================
Tracker.framePools = {
    buttons = {},
    frames = {},
    buttonsCreated = 0,
    framesCreated = 0,
}

-- Get frame pool statistics for performance monitoring
function Tracker:GetPoolStats()
    return {
        buttonsAvailable = #self.framePools.buttons,
        buttonsCreated = self.framePools.buttonsCreated,
        framesAvailable = #self.framePools.frames,
        framesCreated = self.framePools.framesCreated,
    }
end

-- Acquire a button from the pool or create a new one
-- Reuses existing children (icon, text) instead of creating new ones
function Tracker:AcquireButton(parent)
    local pool = self.framePools.buttons
    local btn = table.remove(pool)
    if btn then
        btn:SetParent(parent)
        btn:ClearAllPoints()
        btn:Show()
        btn:EnableMouse(true)
        -- Show existing children if they exist
        if btn.cachedIcon then btn.cachedIcon:Show() end
        if btn.cachedText then btn.cachedText:Show() end
        return btn
    end
    self.framePools.buttonsCreated = self.framePools.buttonsCreated + 1
    return CreateFrame("Button", nil, parent)
end

-- Acquire a frame from the pool or create a new one
function Tracker:AcquireFrame(parent)
    local pool = self.framePools.frames
    local frame = table.remove(pool)
    if frame then
        frame:SetParent(parent)
        frame:ClearAllPoints()
        frame:Show()
        frame:EnableMouse(true)
        return frame
    end
    self.framePools.framesCreated = self.framePools.framesCreated + 1
    return CreateFrame("Frame", nil, parent)
end

-- Release a button back to the pool
function Tracker:ReleaseButton(btn)
    if not btn then return end
    btn:Hide()
    btn:EnableMouse(false)
    btn:SetScript("OnClick", nil)
    btn:SetScript("OnEnter", nil)
    btn:SetScript("OnLeave", nil)
    btn:ClearAllPoints()
    -- Hide cached children
    if btn.cachedIcon then btn.cachedIcon:Hide() end
    if btn.cachedText then btn.cachedText:Hide() end
    table.insert(self.framePools.buttons, btn)
end

-- Release a frame back to the pool
function Tracker:ReleaseFrame(frame)
    if not frame then return end
    frame:Hide()
    frame:EnableMouse(false)
    frame:SetScript("OnEnter", nil)
    frame:SetScript("OnLeave", nil)
    frame:ClearAllPoints()
    table.insert(self.framePools.frames, frame)
end

-- Release all elements from bossTexts back to pools
function Tracker:ReleaseWatchFrameElements(frame)
    if not frame or not frame.bossTexts then return end

    for _, element in ipairs(frame.bossTexts) do
        if element then
            if element.RegisterForClicks then
                self:ReleaseButton(element)
            elseif element.EnableMouse and not element.GetText then
                self:ReleaseFrame(element)
            else
                if element.Hide then element:Hide() end
            end
        end
    end

    frame.bossTexts = {}
end

-- ============================================================================
-- Universal Boss Detection System
-- ============================================================================
-- Supports multiple detection types so bosses can specify how they're detected:
--   detectType = "death"  (default) - UNIT_DIED event
--   detectType = "cast"   - SPELL_CAST_START/SUCCESS with detectSpellId
--   detectType = "buff"   - SPELL_AURA_APPLIED with detectSpellId
--   detectType = "health" - Boss reaches specific health % (future)
--
-- Usage in boss data:
--   { name = "Valithria Dreamwalker", id = 36789, detectType = "cast", detectSpellId = 71189 }
-- ============================================================================

-- Detection handlers registry
-- Format: handlers[detectType] = { eventTypes = {"EVENT1", "EVENT2"}, handler = function(args, bossLookup) }
Tracker.detectionHandlers = {}

-- Lookup tables for fast detection (built during initialization)
-- Format: spellLookup[spellId] = { {instanceId, bossIndex, boss}, ... }
Tracker.spellLookup = {}

-- NPC ID lookup for fast UNIT_DIED detection
-- Format: npcLookup[npcId] = { {instanceId, bossIndex, boss, groupIndex}, ... }
-- Multiple entries per NPC ID possible (same boss in different difficulties)
Tracker.npcLookup = {}

-- Register a detection handler
-- @param detectType string - The detection type name (e.g., "cast", "buff")
-- @param eventTypes table - List of combat log event types to listen for
-- @param handler function - Function(self, args, lookup) that processes the event
function Tracker:RegisterDetectionHandler(detectType, eventTypes, handler)
    self.detectionHandlers[detectType] = {
        eventTypes = eventTypes,
        handler = handler
    }
    KOL:DebugPrint("Tracker: Registered detection handler for type '" .. detectType .. "'", 3)
end

-- Build lookup tables for all registered detection types
function Tracker:BuildDetectionLookups()
    self.spellLookup = {}
    self.npcLookup = {}

    -- Helper to add NPC ID to lookup
    local function addNpcToLookup(npcId, instanceId, bossIndex, boss, groupIndex)
        if not npcId then return end
        if not self.npcLookup[npcId] then
            self.npcLookup[npcId] = {}
        end
        table.insert(self.npcLookup[npcId], {
            instanceId = instanceId,
            bossIndex = bossIndex,
            boss = boss,
            groupIndex = groupIndex
        })
    end

    for instanceId, data in pairs(self.instances) do
        local function processBoss(boss, bossIndex, groupIndex)
            local detectType = boss.detectType or "death"

            -- Build spell lookup for cast/buff detection
            if detectType == "cast" or detectType == "buff" then
                local spellId = boss.detectSpellId
                if spellId then
                    if not self.spellLookup[spellId] then
                        self.spellLookup[spellId] = {}
                    end
                    table.insert(self.spellLookup[spellId], {
                        instanceId = instanceId,
                        bossIndex = bossIndex,
                        boss = boss,
                        detectType = detectType
                    })
                    KOL:DebugPrint("Tracker: Built lookup for " .. boss.name .. " [" .. detectType .. "] spellId=" .. spellId, 3)
                end
            end

            -- Build NPC lookup for UNIT_DIED detection (all bosses with IDs)
            local bossId = boss.id
            if bossId then
                if type(bossId) == "table" then
                    -- Multiple IDs (e.g., id = {34928, 35119})
                    for _, id in ipairs(bossId) do
                        addNpcToLookup(id, instanceId, bossIndex, boss, groupIndex)
                    end
                else
                    -- Single ID
                    addNpcToLookup(bossId, instanceId, bossIndex, boss, groupIndex)
                end
            end

            -- Also add faction-specific IDs if they exist
            if boss.idHorde then
                if type(boss.idHorde) == "table" then
                    for _, id in ipairs(boss.idHorde) do
                        addNpcToLookup(id, instanceId, bossIndex, boss, groupIndex)
                    end
                else
                    addNpcToLookup(boss.idHorde, instanceId, bossIndex, boss, groupIndex)
                end
            end

            -- Add multikill IDs if present
            if boss.ids then
                for _, id in ipairs(boss.ids) do
                    addNpcToLookup(id, instanceId, bossIndex, boss, groupIndex)
                end
            end
        end

        -- Check flat bosses list
        if data.bosses then
            for bossIndex, boss in ipairs(data.bosses) do
                processBoss(boss, bossIndex, nil)
            end
        end

        -- Check grouped bosses
        if data.groups then
            for groupIndex, group in ipairs(data.groups) do
                if group.bosses then
                    for bossIndex, boss in ipairs(group.bosses) do
                        -- Calculate global boss index for grouped bosses
                        local globalIndex = self:GetGlobalBossIndex(data, groupIndex, bossIndex)
                        processBoss(boss, globalIndex, groupIndex)
                    end
                end
            end
        end

        -- Check entries (new format)
        if data.entries then
            for entryIndex, entry in ipairs(data.entries) do
                if entry.id then
                    if type(entry.id) == "table" then
                        for _, id in ipairs(entry.id) do
                            addNpcToLookup(id, instanceId, entryIndex, entry, nil)
                        end
                    else
                        addNpcToLookup(entry.id, instanceId, entryIndex, entry, nil)
                    end
                end
                if entry.ids then
                    for _, id in ipairs(entry.ids) do
                        addNpcToLookup(id, instanceId, entryIndex, entry, nil)
                    end
                end
            end
        end
    end

    -- Log npcLookup stats
    local npcCount = 0
    for _ in pairs(self.npcLookup) do npcCount = npcCount + 1 end
    KOL:DebugPrint("Tracker: Built npcLookup with " .. npcCount .. " unique NPC IDs", 1)
end

-- Get global boss index for grouped boss structures
function Tracker:GetGlobalBossIndex(instanceData, groupIndex, localBossIndex)
    local globalIndex = 0
    if instanceData.groups then
        for i = 1, groupIndex - 1 do
            if instanceData.groups[i] and instanceData.groups[i].bosses then
                globalIndex = globalIndex + #instanceData.groups[i].bosses
            end
        end
    end
    return globalIndex + localBossIndex
end

-- Initialize the default detection handlers
function Tracker:InitializeDetectionHandlers()
    -- Cast detection handler (SPELL_CAST_START, SPELL_CAST_SUCCESS)
    self:RegisterDetectionHandler("cast", {"SPELL_CAST_START", "SPELL_CAST_SUCCESS"}, function(self, args)
        local eventType = args[2]
        local spellId = args[10]  -- WotLK 3.3.5: arg10 is spellId for spell events
        local spellName = args[11]

        if not spellId then return end

        local lookupEntries = self.spellLookup[spellId]
        if not lookupEntries then return end

        for _, entry in ipairs(lookupEntries) do
            if entry.detectType == "cast" and entry.instanceId == self.currentInstanceId then
                KOL:DebugPrint("CAST DETECT: " .. entry.boss.name .. " via spell " .. spellId .. " (" .. (spellName or "?") .. ")", 2)
                self:HandleBossDetection(entry.instanceId, entry.bossIndex, entry.boss, "cast", spellId)
                return
            end
        end
    end)

    -- Buff detection handler (SPELL_AURA_APPLIED)
    self:RegisterDetectionHandler("buff", {"SPELL_AURA_APPLIED"}, function(self, args)
        local eventType = args[2]
        local spellId = args[10]
        local spellName = args[11]

        if not spellId then return end

        local lookupEntries = self.spellLookup[spellId]
        if not lookupEntries then return end

        for _, entry in ipairs(lookupEntries) do
            if entry.detectType == "buff" and entry.instanceId == self.currentInstanceId then
                KOL:DebugPrint("BUFF DETECT: " .. entry.boss.name .. " via spell " .. spellId .. " (" .. (spellName or "?") .. ")", 2)
                self:HandleBossDetection(entry.instanceId, entry.bossIndex, entry.boss, "buff", spellId)
                return
            end
        end
    end)

    KOL:DebugPrint("Tracker: Default detection handlers initialized", 3)
end

-- Handle boss detection (called by detection handlers)
function Tracker:HandleBossDetection(instanceId, bossIndex, boss, detectType, triggerId)
    local data = self.instances[instanceId]
    if not data then return end

    -- Check if already killed
    if self:IsBossKilled(instanceId, bossIndex) then
        KOL:DebugPrint("Tracker: Boss " .. boss.name .. " already killed, ignoring detection", 3)
        return
    end

    -- Mark boss as killed
    self:MarkBossKilled(instanceId, bossIndex)

    local watchLevel = KOL.db.profile.watchDeathsLevel or 0
    if watchLevel >= 1 then
        local detectInfo = ""
        if detectType == "cast" then
            detectInfo = " (victory spell)"
        elseif detectType == "buff" then
            detectInfo = " (buff applied)"
        end
        KOL:Print("Boss completed: " .. COLOR(data.color, boss.name) .. detectInfo)
    end

    -- Record for BossRecorder if available
    if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
        local bossId = self:GetBossId(boss)
        KOL.BossRecorder:OnBossDetected(boss.name, nil, bossId, "Boss")
    end

    KOL:DebugPrint("Tracker: HandleBossDetection complete for " .. boss.name .. " [" .. detectType .. "]", 2)
end

-- ============================================================================
-- Initialization
-- ============================================================================

function Tracker:Initialize()
    -- Ensure database structure exists
    if not KOL.db.profile.tracker then
        KOL.db.profile.tracker = {
            -- Font settings (defaults to Source Code Pro Bold for proper glyph support)
            baseFont = "Source Code Pro Bold",
            baseFontSize = 12,
            fontScale = 1.0,

            -- Boss kill data (character-specific)
            bossKills = {},

            -- Multi-NPC boss tracking (which individual NPCs have died)
            multiNPCKills = {},

            -- Multi-phase boss tracking (how many times the same boss has been killed)
            multiPhaseKills = {},

            -- Instance lockout IDs (to detect resets)
            instanceLockouts = {},

            -- Hardmode state (which bosses are in hardmode this lockout)
            hardmodeActive = {},

            -- Custom watch panels
            customPanels = {},

            -- Frame positions (saved per character)
            framePositions = {},

            -- Collapsed group states (per instance, per group)
            -- Format: [instanceId][groupIndex] = true/false
            collapsedGroups = {},

            -- General settings
            autoShow = true,
            mouseover = false,
        }

    -- Ensure boss recording database structure exists
    if not KOL.db.profile.bossRecording then
        KOL.db.profile.bossRecording = {
            enabled = true,
            currentSession = nil,
            sessions = {},
            settings = {
                autoRecord = true,
                recordOnlyBosses = true,
                maxSessions = 50,
            }
        }
    end
    end

    -- Load boss kills from DB
    self.bossKills = KOL.db.profile.tracker.bossKills or {}
    self.multiNPCKills = KOL.db.profile.tracker.multiNPCKills or {}
    self.multiPhaseKills = KOL.db.profile.tracker.multiPhaseKills or {}
    self.hardmodeActive = KOL.db.profile.tracker.hardmodeActive or {}

    -- IMPORTANT: instanceLockouts are SESSION-ONLY (not persisted)
    -- GUID-based instance IDs change on /reload, so persisting them causes false resets
    -- We only use them for within-session detection (e.g., manual reset while playing)
    self.instanceLockouts = {}

    -- Initialize autoShow if not exists (for existing users upgrading)
    -- Default to TRUE so watch frames show automatically
    if KOL.db.profile.tracker.autoShow == nil then
        KOL.db.profile.tracker.autoShow = true
        KOL:DebugPrint("Tracker: Initialized autoShow to true (new field for existing user)", 2)
    end

    -- Initialize collapsed groups if not exists (for existing users)
    if not KOL.db.profile.tracker.collapsedGroups then
        KOL.db.profile.tracker.collapsedGroups = {}
    end

    -- Initialize entry progress tracking (for count-based objectives)
    -- Structure: entryProgress[instanceId][entryId] = currentCount
    if not KOL.db.profile.tracker.entryProgress then
        KOL.db.profile.tracker.entryProgress = {}
    end
    self.entryProgress = KOL.db.profile.tracker.entryProgress

    -- Initialize dungeon challenge data
    self:InitializeDungeonChallengeData()

    -- Load custom panels from DB
    self:LoadCustomPanels()

    -- Initialize detection handlers (must be before RegisterEvents)
    self:InitializeDetectionHandlers()

    -- Register event handlers
    self:RegisterEvents()

    -- Start dungeon challenge update ticker (updates every 0.5 seconds)
    self:StartDungeonChallengeUpdates()

    KOL:PrintTag("Tracker module initialized - calling UpdateZoneTracking")

    -- Perform initial zone check (in case we're already in a zone on reload)
    self:UpdateZoneTracking()

    -- After a delay, mark initial load as complete
    -- This prevents UPDATE_INSTANCE_INFO from resetting progress during login/reload
    C_Timer.After(3, function()
        self.initialLoadComplete = true
        KOL:DebugPrint("Tracker: Initial load complete, reset detection now active", 2)
    end)
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

    -- Destroy frame if active
    if self.activeFrames[id] then
        self:DestroyWatchFrame(id)
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

-- Get boss name based on player faction
function Tracker:GetBossName(boss)
    if not boss then return "Unknown" end

    -- Check if player is Horde
    local playerFaction = UnitFactionGroup("player")  -- Returns "Horde" or "Alliance"

    -- If Horde and there's a Horde-specific name, use it
    if playerFaction == "Horde" and boss.nameHorde then
        return boss.nameHorde
    end

    -- Otherwise use the default name
    return boss.name or "Unknown"
end

-- Get formatted boss name with hardmode indicator if active
-- Only shows (HM) if the boss actually has a hardmode definition in the data
function Tracker:GetBossNameWithHardmode(instanceId, bossIndex, boss)
    local bossName = self:GetBossName(boss)

    -- Only show hardmode indicator if the boss actually supports hardmode
    -- (has a hardmode definition in its data) AND is currently in hardmode
    if boss and boss.hardmode and self:IsBossHardmode(instanceId, bossIndex) then
        local nuclearPurple = "CC66FF"  -- Nuclear purple
        if KOL.Colors and KOL.Colors.GetNuclear then
            nuclearPurple = KOL.Colors:GetNuclear("PURPLE") or nuclearPurple
        end
        return bossName .. " |cFF" .. nuclearPurple .. "(HM)|r"
    end

    return bossName
end

-- Get boss ID based on player faction
function Tracker:GetBossId(boss)
    if not boss then return nil end

    -- Check if player is Horde
    local playerFaction = UnitFactionGroup("player")  -- Returns "Horde" or "Alliance"

    -- If Horde and there's a Horde-specific ID, use it
    if playerFaction == "Horde" and boss.idHorde then
        return boss.idHorde
    end

    -- Otherwise use the default ID
    return boss.id
end

-- ============================================================================
-- Entry Compatibility Layer (supports both old and new schema)
-- ============================================================================

-- Get entries from a group (supports both 'entries' and 'bosses' field names)
function Tracker:GetEntries(group)
    if not group then return {} end
    return group.entries or group.bosses or {}
end

-- Get detection type for an entry (infers from old format if type not specified)
function Tracker:GetDetectionType(entry)
    if not entry then return "kill" end

    -- Explicit type field (new format)
    if entry.type and entry.type ~= "custom" then
        return entry.type
    end

    -- Infer from old format fields
    if entry.yells or entry.yell then
        return "yell"
    elseif entry.multiKill or (type(entry.id) == "table" and #entry.id > 1 and not entry.anyNPC) then
        return "multikill"
    elseif entry.itemId or entry.itemIds then
        return "loot"
    else
        return "kill"  -- Default
    end
end

-- Get multikill IDs (supports both 'ids' and 'id' array formats)
function Tracker:GetMultikillIds(entry)
    if not entry then return {} end
    return entry.ids or entry.id or {}
end

-- Get yell patterns (supports both 'yells' array and single 'yell' field)
function Tracker:GetYellPatterns(entry)
    if not entry then return {} end
    if entry.yells then
        return entry.yells
    elseif entry.yell then
        return {entry.yell}
    end
    return {}
end

-- Get item IDs for loot detection (supports both 'itemId' and 'itemIds')
function Tracker:GetLootItemIds(entry)
    if not entry then return {} end
    if entry.itemIds then
        return entry.itemIds
    elseif entry.itemId then
        return {entry.itemId}
    end
    return {}
end

-- Get the primary ID for an entry (for kill detection)
function Tracker:GetEntryId(entry)
    if not entry then return nil end

    -- For single ID entries
    if type(entry.id) == "number" then
        return entry.id
    end

    -- For multi-ID entries, return first ID (for display purposes)
    if type(entry.id) == "table" and #entry.id > 0 then
        return entry.id[1]
    end

    return nil
end

-- Check if an entry has a specific NPC ID (works with single or array)
function Tracker:EntryHasNpcId(entry, npcId)
    if not entry or not npcId then return false end

    if type(entry.id) == "number" then
        return entry.id == npcId
    elseif type(entry.id) == "table" then
        for _, id in ipairs(entry.id) do
            if id == npcId then return true end
        end
    end

    return false
end

-- ============================================================================
-- Hardmode Functions
-- ============================================================================

-- Check if a boss is in hardmode
function Tracker:IsBossHardmode(instanceId, bossIndex)
    if not self.hardmodeActive[instanceId] then
        return false
    end
    return self.hardmodeActive[instanceId][bossIndex] == true
end

-- Mark a boss as hardmode
function Tracker:MarkBossHardmode(instanceId, bossIndex)
    if not self.hardmodeActive[instanceId] then
        self.hardmodeActive[instanceId] = {}
    end
    self.hardmodeActive[instanceId][bossIndex] = true

    -- Save to DB
    KOL.db.profile.tracker.hardmodeActive = self.hardmodeActive

    KOL:DebugPrint("Tracker: Marked boss " .. bossIndex .. " as hardmode in " .. instanceId, 2)
end

-- Clear hardmode status for a boss
function Tracker:ClearBossHardmode(instanceId, bossIndex)
    if not self.hardmodeActive[instanceId] then
        return
    end
    self.hardmodeActive[instanceId][bossIndex] = nil

    -- Save to DB
    KOL.db.profile.tracker.hardmodeActive = self.hardmodeActive

    KOL:DebugPrint("Tracker: Cleared hardmode for boss " .. bossIndex .. " in " .. instanceId, 2)
end

-- Clear all hardmode states for an instance
function Tracker:ClearInstanceHardmodes(instanceId)
    self.hardmodeActive[instanceId] = {}
    KOL.db.profile.tracker.hardmodeActive = self.hardmodeActive
    KOL:DebugPrint("Tracker: Cleared all hardmodes for " .. instanceId, 2)
end

-- Detect hardmode activation based on boss configuration
function Tracker:DetectHardmode(instanceId, bossIndex, triggerType, triggerData)
    local data = self.instances[instanceId]
    if not data then return end

    local boss
    if data.bosses then
        boss = data.bosses[bossIndex]
    elseif data.groups then
        -- Find boss in groups
        for _, group in ipairs(data.groups) do
            if group.bosses then
                boss = group.bosses[bossIndex]
                if boss then break end
            end
        end
    end

    if not boss or not boss.hardmode then
        return
    end

    local hm = boss.hardmode

    -- Check yell triggers
    if triggerType == "yell" and hm.yells then
        for _, yellPattern in ipairs(hm.yells) do
            if triggerData and string.find(triggerData, yellPattern, 1, true) then
                self:MarkBossHardmode(instanceId, bossIndex)
                KOL:PrintTag("Hardmode activated: " .. self:GetBossName(boss) .. " ⚡")
                self:RefreshAllWatchFrames()
                return true
            end
        end
    end

    -- Check interaction triggers (button presses, etc)
    if triggerType == "interaction" and hm.interactions then
        for _, interaction in ipairs(hm.interactions) do
            if triggerData == interaction.objectId or triggerData == interaction.gossipId then
                self:MarkBossHardmode(instanceId, bossIndex)
                KOL:PrintTag("Hardmode activated: " .. self:GetBossName(boss) .. " ⚡")
                self:RefreshAllWatchFrames()
                return true
            end
        end
    end

    -- Check spell triggers (specific spells cast = hardmode)
    if triggerType == "spell" and hm.spells then
        for _, spellId in ipairs(hm.spells) do
            if triggerData == spellId then
                self:MarkBossHardmode(instanceId, bossIndex)
                KOL:PrintTag("Hardmode activated: " .. self:GetBossName(boss) .. " ⚡")
                self:RefreshAllWatchFrames()
                return true
            end
        end
    end

    return false
end

-- Destroy a watch frame and free resources
-- @param instanceId: Instance identifier
function Tracker:DestroyWatchFrame(instanceId)
    local frame = self.activeFrames[instanceId]
    if not frame then
        return
    end

    KOL:DebugPrint("Tracker: Destroying watch frame: " .. instanceId, 2)

    -- Reset dungeon challenge state for this instance
    if self.dungeonChallengeState[instanceId] then
        self.dungeonChallengeState[instanceId].startTime = nil
        self.dungeonChallengeState[instanceId].timeElapsedOffset = 0
        self.dungeonChallengeState[instanceId].buffActive = false
        KOL:DebugPrint("Tracker: Reset dungeon challenge timer for " .. instanceId, 3)

        -- Clear saved time from database (zone reset)
        if KOL.db.profile.tracker.dungeonChallenge and KOL.db.profile.tracker.dungeonChallenge.currentTimes then
            KOL.db.profile.tracker.dungeonChallenge.currentTimes[instanceId] = nil
        end
    end

    -- Hide the frame
    frame:Hide()

    -- Clear all points
    frame:ClearAllPoints()

    -- Unregister all events on the frame
    frame:UnregisterAllEvents()

    -- If the frame has children, clear them
    if frame.scrollFrame then
        frame.scrollFrame:Hide()
        frame.scrollFrame:ClearAllPoints()
        frame.scrollFrame:SetParent(nil)
    end
    if frame.content then
        frame.content:Hide()
        frame.content:ClearAllPoints()
        frame.content:SetParent(nil)
    end
    if frame.scrollBar then
        frame.scrollBar:Hide()
        frame.scrollBar:ClearAllPoints()
        frame.scrollBar:SetParent(nil)
    end
    if frame.titleBar then
        frame.titleBar:Hide()
        frame.titleBar:ClearAllPoints()
        frame.titleBar:SetParent(nil)
    end

    -- Set parent to nil
    frame:SetParent(nil)

    -- Remove from active frames table
    self.activeFrames[instanceId] = nil

    KOL:DebugPrint("Tracker: Watch frame destroyed: " .. instanceId, 3)
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
-- Group Collapse/Expand State
-- ============================================================================

-- Check if a group is collapsed
-- @param instanceId: Instance identifier
-- @param groupIndex: Group index (1-based)
-- @return: true if collapsed, false otherwise
function Tracker:IsGroupCollapsed(instanceId, groupIndex)
    if not KOL.db.profile.tracker.collapsedGroups then
        KOL.db.profile.tracker.collapsedGroups = {}
    end
    if not KOL.db.profile.tracker.collapsedGroups[instanceId] then
        return false
    end
    return KOL.db.profile.tracker.collapsedGroups[instanceId][groupIndex] == true
end

-- Toggle group collapsed state
-- @param instanceId: Instance identifier
-- @param groupIndex: Group index (1-based)
function Tracker:ToggleGroupCollapsed(instanceId, groupIndex)
    if not KOL.db.profile.tracker.collapsedGroups then
        KOL.db.profile.tracker.collapsedGroups = {}
    end
    if not KOL.db.profile.tracker.collapsedGroups[instanceId] then
        KOL.db.profile.tracker.collapsedGroups[instanceId] = {}
    end

    local currentState = KOL.db.profile.tracker.collapsedGroups[instanceId][groupIndex]
    KOL.db.profile.tracker.collapsedGroups[instanceId][groupIndex] = not currentState

    KOL:DebugPrint("Tracker: Toggled group " .. groupIndex .. " in " .. instanceId .. " to " ..
        (KOL.db.profile.tracker.collapsedGroups[instanceId][groupIndex] and "collapsed" or "expanded"), 3)

    -- Update watch frame
    if self.activeFrames[instanceId] then
        self:UpdateWatchFrame(instanceId)
    end
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

    KOL:DebugPrint("SAVED TO DB: Boss killed " .. instanceId .. " / " .. tostring(bossId), 2)

    -- Check if this boss is part of a group, and if so, check for group completion
    local instanceData = self.instances[instanceId]
    if instanceData and instanceData.groups then
        -- Extract group index from bossId (format: "g1-b2" = group 1, boss 2)
        local groupIndex = string.match(tostring(bossId), "^g(%d+)%-")
        if groupIndex then
            groupIndex = tonumber(groupIndex)
            local group = instanceData.groups[groupIndex]

            if group and group.bosses then
                -- Check if ALL bosses in this group are now killed
                local allKilled = true
                for bossIndex, _ in ipairs(group.bosses) do
                    local checkBossId = "g" .. groupIndex .. "-b" .. bossIndex
                    if not self.bossKills[instanceId][checkBossId] then
                        allKilled = false
                        break
                    end
                end

                if allKilled then
                    local colorHex = KOL.Colors:ToHex(KOL.Colors:GetPastel(instanceData.color))
                    local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                    if watchLevel >= 1 then
                        KOL:PrintTag("Quarter complete: |cFF" .. colorHex .. group.name .. "|r")
                    end

                    -- Auto-collapse the completed group
                    if not KOL.db.profile.tracker.collapsedGroups then
                        KOL.db.profile.tracker.collapsedGroups = {}
                    end
                    if not KOL.db.profile.tracker.collapsedGroups[instanceId] then
                        KOL.db.profile.tracker.collapsedGroups[instanceId] = {}
                    end
                    KOL.db.profile.tracker.collapsedGroups[instanceId][groupIndex] = true
                    KOL:DebugPrint("Tracker: Auto-collapsed completed group " .. groupIndex .. " in " .. instanceId, 2)
                end
            end
        end
    end

    -- Update timer log for all zones (if dungeon challenge is enabled)
    if instanceData then
        -- Get the boss name
        local bossName = nil

        -- Check if this is a grouped boss (format: "g1-b2")
        local groupIndex, bossIndex = string.match(tostring(bossId), "^g(%d+)%-b(%d+)$")
        if groupIndex and bossIndex then
            groupIndex = tonumber(groupIndex)
            bossIndex = tonumber(bossIndex)
            if instanceData.groups and instanceData.groups[groupIndex] and instanceData.groups[groupIndex].bosses then
                local boss = instanceData.groups[groupIndex].bosses[bossIndex]
                if boss then
                    bossName = boss.name
                end
            end
        elseif instanceData.bosses and instanceData.bosses[bossId] then
            -- Regular boss (not grouped)
            bossName = instanceData.bosses[bossId].name
        end

        -- Get current time from dungeon challenge state
        if bossName and self.dungeonChallengeState[instanceId] then
            local currentTime = self.dungeonChallengeState[instanceId].currentTime or 0
            self:UpdateTimerLogEntry(instanceId, bossName, currentTime)
        end
    end

    -- Update watch frame if active
    if self.activeFrames[instanceId] then
        self:UpdateWatchFrame(instanceId)
    end
end

-- Check if a boss is killed
function Tracker:IsBossKilled(instanceId, bossId)
    return self.bossKills[instanceId] and self.bossKills[instanceId][bossId] or false
end

-- Unmark a boss as killed (reset to not killed)
-- @param instanceId: Instance identifier
-- @param bossId: Boss identifier (name or index)
function Tracker:UnmarkBossKilled(instanceId, bossId)
    if self.bossKills[instanceId] then
        self.bossKills[instanceId][bossId] = nil
        KOL.db.profile.tracker.bossKills = self.bossKills
        KOL:DebugPrint("SAVED TO DB: Boss unmarked " .. instanceId .. " / " .. tostring(bossId), 2)
    end

    -- Update watch frame if active
    if self.activeFrames[instanceId] then
        self:UpdateWatchFrame(instanceId)
    end
end

-- ============================================================================
-- Entry Progress Tracking (for count-based objectives)
-- ============================================================================

-- Get entry progress (current count)
-- @param instanceId: Instance identifier
-- @param entryId: Entry identifier (e.g., "kill-12345" or "loot-67890")
-- @return current progress count (default 0)
function Tracker:GetEntryProgress(instanceId, entryId)
    if not self.entryProgress[instanceId] then
        return 0
    end
    return self.entryProgress[instanceId][entryId] or 0
end

-- Set entry progress (current count)
-- @param instanceId: Instance identifier
-- @param entryId: Entry identifier
-- @param count: New progress count
function Tracker:SetEntryProgress(instanceId, entryId, count)
    if not self.entryProgress[instanceId] then
        self.entryProgress[instanceId] = {}
    end
    self.entryProgress[instanceId][entryId] = count
    KOL.db.profile.tracker.entryProgress = self.entryProgress
end

-- Increment entry progress by 1
-- @param instanceId: Instance identifier
-- @param entryId: Entry identifier
-- @param requiredCount: The target count (if reached, marks as complete)
-- @return new progress count, and whether it reached the required count
function Tracker:IncrementEntryProgress(instanceId, entryId, requiredCount)
    local current = self:GetEntryProgress(instanceId, entryId)
    local newCount = current + 1
    self:SetEntryProgress(instanceId, entryId, newCount)

    requiredCount = requiredCount or 1
    local complete = newCount >= requiredCount

    -- If complete, also mark the boss as killed (so checkmark shows)
    if complete then
        self:MarkBossKilled(instanceId, entryId)
    end

    -- Update watch frame
    if self.activeFrames[instanceId] then
        self:UpdateWatchFrame(instanceId)
    end

    return newCount, complete
end

-- Reset entry progress
-- @param instanceId: Instance identifier
-- @param entryId: Entry identifier (if nil, resets all for instance)
function Tracker:ResetEntryProgress(instanceId, entryId)
    if not self.entryProgress[instanceId] then
        return
    end

    if entryId then
        self.entryProgress[instanceId][entryId] = nil
    else
        self.entryProgress[instanceId] = {}
    end

    KOL.db.profile.tracker.entryProgress = self.entryProgress
end

-- Check if all objectives in an instance are complete
function Tracker:IsInstanceComplete(instanceId)
    local instanceData = self.instances[instanceId]
    if not instanceData then return false end
    
    -- Check flat bosses
    if instanceData.bosses and #instanceData.bosses > 0 then
        for i = 1, #instanceData.bosses do
            if not self:IsBossKilled(instanceId, i) then
                return false
            end
        end
    end
    
    -- Check grouped bosses
    if instanceData.groups then
        for groupIndex, group in ipairs(instanceData.groups) do
            if group.bosses then
                for bossIndex = 1, #group.bosses do
                    local bossId = "g" .. groupIndex .. "-b" .. bossIndex
                    if not self:IsBossKilled(instanceId, bossId) then
                        return false
                    end
                end
            end
        end
    end

    return true
end

-- Reset boss kills for an instance
function Tracker:ResetInstance(instanceId)
    self.bossKills[instanceId] = {}
    self.multiNPCKills[instanceId] = {}
    self.multiPhaseKills[instanceId] = {}
    self.lastExitTime[instanceId] = nil  -- Clear exit time tracking
    self.instanceLockouts[instanceId] = nil  -- Clear lockout ID

    -- Reset Dungeon Challenge timer - restart fresh
    self.dungeonChallengeState[instanceId] = {
        startTime = GetTime(),
        timeElapsedOffset = 0,
        buffActive = false,
        timerStopped = false,
        completionTime = nil,
        cachedTime = nil,
        currentTime = nil,
    }
    KOL:DebugPrint("Tracker: Restarted dungeon timer for " .. instanceId, 2)

    -- Clear saved dungeon challenge timer from database
    if KOL.db.profile.tracker.dungeonChallenge and KOL.db.profile.tracker.dungeonChallenge.currentTimes then
        KOL.db.profile.tracker.dungeonChallenge.currentTimes[instanceId] = nil
    end

    -- Clear collapsed groups for this instance
    if KOL.db.profile.tracker.collapsedGroups then
        KOL.db.profile.tracker.collapsedGroups[instanceId] = {}
    end

    -- Clear entry progress for this instance
    if self.entryProgress then
        self.entryProgress[instanceId] = {}
        KOL.db.profile.tracker.entryProgress = self.entryProgress
    end

    KOL.db.profile.tracker.bossKills = self.bossKills
    KOL.db.profile.tracker.multiNPCKills = self.multiNPCKills
    KOL.db.profile.tracker.multiPhaseKills = self.multiPhaseKills
    -- Note: instanceLockouts is session-only, not persisted

    KOL:DebugPrint("Reset triggered for: " .. instanceId, 2)

    -- Update watch frame if active
    if self.activeFrames[instanceId] then
        self:UpdateWatchFrame(instanceId)
    end
end

-- Reset all boss kills
function Tracker:ResetAll()
    self.bossKills = {}
    self.multiNPCKills = {}
    self.multiPhaseKills = {}
    self.lastExitTime = {}
    self.instanceLockouts = {}

    -- Clear all collapsed groups
    if KOL.db.profile.tracker.collapsedGroups then
        KOL.db.profile.tracker.collapsedGroups = {}
    end

    -- Clear all entry progress
    self.entryProgress = {}
    KOL.db.profile.tracker.entryProgress = self.entryProgress

    KOL.db.profile.tracker.bossKills = self.bossKills
    KOL.db.profile.tracker.multiNPCKills = self.multiNPCKills
    KOL.db.profile.tracker.multiPhaseKills = self.multiPhaseKills
    KOL.db.profile.tracker.instanceLockouts = self.instanceLockouts

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
function Tracker:OnCombatLogEvent(...)
    local args = {...}

    -- WotLK 3.3.5 combat log structure:
    -- arg1: timestamp
    -- arg2: eventType
    -- arg3: sourceGUID
    -- arg4: sourceName
    -- arg5: sourceFlags
    -- arg6: destGUID
    -- arg7: destName
    -- arg8: destFlags
    -- For spell events: arg10 = spellId, arg11 = spellName
    local timestamp = args[1]
    local eventType = args[2]
    local sourceGUID = args[3]
    local sourceName = args[4]
    local sourceFlags = args[5]
    local destGUID = args[6]
    local destName = args[7]
    local destFlags = args[8]

    -- Check detection handlers for non-death events (cast, buff, etc.)
    if eventType ~= "UNIT_DIED" then
        -- Check all registered detection handlers
        for detectType, handlerInfo in pairs(self.detectionHandlers) do
            for _, eventName in ipairs(handlerInfo.eventTypes) do
                if eventType == eventName then
                    handlerInfo.handler(self, args)
                    return
                end
            end
        end
        return
    end

    KOL:DebugPrint("UNIT_DIED: " .. tostring(destName) .. " | GUID: " .. tostring(destGUID), 3)

    -- Extract NPC ID from GUID
    local npcId = self:ExtractNPCID(destGUID)
    if not npcId then
        KOL:DebugPrint("ERROR: Could not extract NPC ID from GUID: " .. tostring(destGUID), 1)
        return
    end

    KOL:DebugPrint("NPC ID: " .. tostring(npcId) .. " | Name: " .. tostring(destName), 3)

    -- Extract Instance ID from the GUID for reset detection
    local wowInstanceId = self:ExtractInstanceID(destGUID)
    if wowInstanceId then
        KOL:DebugPrint("Tracker: WoW Instance ID: " .. tostring(wowInstanceId), 3)
    end

    -- Watch Deaths Debug Output (/kwd)
    local watchLevel = KOL.db.profile.watchDeathsLevel or 0
    if watchLevel > 0 then
        -- Determine unit classification from flags
        -- COMBATLOG_OBJECT_TYPE_NPC = 0x00000008
        -- COMBATLOG_OBJECT_REACTION_HOSTILE = 0x00000040
        -- COMBATLOG_OBJECT_CONTROL_NPC = 0x00000200
        -- Elite flag = 0x00000010 (COMBATLOG_OBJECT_ELITE)
        -- Boss flag = check if in our database
        local isElite = bit.band(destFlags, 0x00000010) ~= 0
        local isWorldBoss = bit.band(destFlags, 0x00008000) ~= 0  -- COMBATLOG_OBJECT_SPECIAL_1

        -- Check if this NPC is in our tracked bosses database (O(1) lookup)
        local isTrackedBoss = self.npcLookup[npcId] ~= nil

        local isBoss = isWorldBoss or isTrackedBoss
        local shouldOutput = false

        if watchLevel == 3 then
            shouldOutput = true  -- All mobs
        elseif watchLevel == 2 and (isElite or isBoss) then
            shouldOutput = true  -- Elite mobs + bosses
        elseif watchLevel == 1 and isBoss then
            shouldOutput = true  -- Bosses only
        end

        if shouldOutput then
            local classification = "Normal"
            if isBoss then
                classification = "|cFFFF0000Boss|r"
            elseif isElite then
                classification = "|cFFFFAA00Elite|r"
            else
                classification = "|cFFAAAAAA Normal|r"
            end

            local separatorColor = KOL.Colors:ToHex(KOL.Colors.NUCLEAR_SEPARATOR)
            local separator = " |cFF" .. separatorColor .. CHAR_SEPARATOR .. "|r "
            KOL:PrintTag(
                "|cFF00FFFFName:|r " .. tostring(destName) ..
                separator .. "|cFF00FFFFGUID:|r " .. tostring(destGUID) ..
                separator .. "|cFF00FFFF NPC ID:|r " .. tostring(npcId) ..
                separator .. "|cFF00FFFFClass:|r " .. classification
            )
        end
    end

    -- Only process kills for the currently active instance (direct access, no loop)
    -- This avoids cross-difficulty contamination (e.g., naxx_10 vs naxx_25)
    local instanceId = self.currentInstanceId
    local data = self.instances[instanceId]
    if data then
            -- Check custom tracker entries (new format with count support)
            if data.entries and #data.entries > 0 then
                for _, entry in ipairs(data.entries) do
                    if entry.type == "kill" and entry.id then
                        if entry.id == npcId then
                            local entryId = "kill-" .. entry.id
                            local requiredCount = entry.count or 1
                            local currentProgress = self:GetEntryProgress(instanceId, entryId)

                            -- Only increment if not already complete
                            if currentProgress < requiredCount then
                                local newCount, complete = self:IncrementEntryProgress(instanceId, entryId, requiredCount)
                                if complete then
                                    KOL:Print("Kill complete: " .. COLOR(data.color, entry.name) .. " [" .. newCount .. "/" .. requiredCount .. "]")
                                else
                                    KOL:Print("Kill progress: " .. COLOR(data.color, entry.name) .. " [" .. newCount .. "/" .. requiredCount .. "]")
                                end
                            end
                            return
                        end
                    elseif entry.type == "multikill" and entry.ids then
                        -- Check if the killed NPC is part of a multikill entry
                        for _, id in ipairs(entry.ids) do
                            if id == npcId then
                                local entryId = "multi-" .. table.concat(entry.ids, "-")
                                local requiredCount = entry.count or 1
                                local currentProgress = self:GetEntryProgress(instanceId, entryId)

                                -- Only increment if not already complete
                                if currentProgress < requiredCount then
                                    local newCount, complete = self:IncrementEntryProgress(instanceId, entryId, requiredCount)
                                    if complete then
                                        KOL:Print("Multikill complete: " .. COLOR(data.color, entry.name) .. " [" .. newCount .. "/" .. requiredCount .. "]")
                                    else
                                        KOL:Print("Multikill progress: " .. COLOR(data.color, entry.name) .. " [" .. newCount .. "/" .. requiredCount .. "]")
                                    end
                                end
                                return
                            end
                        end
                    end
                end
            end

            -- Check flat bosses list
            if data.bosses and #data.bosses > 0 then
                for bossIndex, boss in ipairs(data.bosses) do
                    -- Support both single ID (number) and multiple IDs (table)
                    -- Also support faction-specific IDs (idHorde)
                    local matchFound = false
                    local bossId = self:GetBossId(boss)
                    local isMultiNPC = type(bossId) == "table"

                    if isMultiNPC then
                    -- Multiple IDs (e.g., Four Horsemen) - check if this NPC is part of the encounter
                    for _, id in ipairs(bossId) do
                        if id == npcId then
                            matchFound = true
                            break
                        end
                    end
                else
                    -- Single ID
                    matchFound = (bossId == npcId)
                end

                if matchFound then
                    KOL:DebugPrint("MATCH FOUND: " .. boss.name .. " (Instance: " .. instanceId .. ", BossIndex: " .. bossIndex .. ", NPC: " .. npcId .. ")", 2)

                    -- Store WoW instance ID for this tracker instance
                    if wowInstanceId then
                        self:StoreInstanceID(instanceId, wowInstanceId)
                    end

                    if isMultiNPC then
                        -- Check if this is an "any NPC" boss (Opera Event, Chess Event)
                        -- vs "all must die" boss (Four Horsemen, Twin Val'kyr)
                        if boss.anyNPC then
                            -- Any NPC dying completes the encounter immediately
                            KOL:DebugPrint("anyNPC boss: " .. boss.name .. " - NPC " .. npcId .. " died, marking complete", 2)
                            self:MarkBossKilled(instanceId, bossIndex)
                            local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                            if watchLevel >= 1 then
                                KOL:Print("Boss defeated: " .. COLOR(data.color, boss.name))
                            end

                            -- Record boss kill for BossRecorder
                            if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                                KOL.BossRecorder:OnBossDetected(destName, destGUID, npcId, "Boss")
                            end
                        else
                            -- Track individual NPC death for multi-NPC bosses (all must die)
                            if not self.multiNPCKills[instanceId] then
                                self.multiNPCKills[instanceId] = {}
                            end
                            if not self.multiNPCKills[instanceId][bossIndex] then
                                self.multiNPCKills[instanceId][bossIndex] = {}
                            end
                            self.multiNPCKills[instanceId][bossIndex][npcId] = true
                            KOL.db.profile.tracker.multiNPCKills = self.multiNPCKills

                            KOL:DebugPrint("Marked NPC " .. npcId .. " as dead for " .. boss.name .. " (bossIndex=" .. bossIndex .. ")", 2)

                            -- Check if ALL NPCs for this boss are now dead
                            local allDead = true
                            local deadCount = 0
                            local totalCount = #bossId
                            for _, id in ipairs(bossId) do
                                if self.multiNPCKills[instanceId][bossIndex][id] then
                                    deadCount = deadCount + 1
                                else
                                    allDead = false
                                end
                            end

                            KOL:DebugPrint(boss.name .. " progress: " .. deadCount .. "/" .. totalCount .. " killed", 2)

                            if allDead then
                                -- All NPCs dead - mark boss as killed!
                                KOL:DebugPrint("ALL NPCs dead! Marking " .. boss.name .. " as complete", 2)
                                self:MarkBossKilled(instanceId, bossIndex)
                                local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                                if watchLevel >= 1 then
                                    KOL:Print("Boss defeated: " .. COLOR(data.color, boss.name))
                                end

                                -- Record boss kill for BossRecorder
                                if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                                    KOL.BossRecorder:OnBossDetected(destName, destGUID, npcId, "Boss")
                                end
                            else
                                -- Partial progress
                                local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                                if watchLevel >= 1 then
                                    KOL:PrintTag(destName .. " defeated (" .. boss.name .. " encounter - " .. deadCount .. "/" .. totalCount .. ")")
                                end
                            end
                        end
                    else
                        -- Single NPC boss - check if it's multi-phase (like Black Knight)
                        if boss.multiKill and type(boss.multiKill) == "number" then
                            -- Multi-phase boss (dies multiple times)
                            if not self.multiPhaseKills[instanceId] then
                                self.multiPhaseKills[instanceId] = {}
                            end
                            if not self.multiPhaseKills[instanceId][bossIndex] then
                                self.multiPhaseKills[instanceId][bossIndex] = 0
                            end

                            -- Increment kill count
                            self.multiPhaseKills[instanceId][bossIndex] = self.multiPhaseKills[instanceId][bossIndex] + 1
                            KOL.db.profile.tracker.multiPhaseKills = self.multiPhaseKills

                            local killCount = self.multiPhaseKills[instanceId][bossIndex]
                            local requiredKills = boss.multiKill

                            local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                            if watchLevel >= 1 then
                                KOL:Print(boss.name .. " defeated (" .. killCount .. "/" .. requiredKills .. ")")
                            end

                            -- Only mark as complete when required kills reached
                            if killCount >= requiredKills then
                                KOL:DebugPrint("MARKING MULTI-PHASE BOSS AS KILLED: " .. boss.name, 2)
                                self:MarkBossKilled(instanceId, bossIndex)
                                if watchLevel >= 1 then
                                    KOL:Print("Boss defeated: " .. COLOR(data.color, boss.name) .. " (Final Phase)")
                                end

                                -- Record boss kill for BossRecorder
                                if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                                    KOL.BossRecorder:OnBossDetected(destName, destGUID, npcId, "Boss")
                                end
                            end
                        else
                            -- Standard single NPC boss - mark as killed immediately
                            KOL:DebugPrint("MARKING BOSS AS KILLED: " .. boss.name .. " (Instance: " .. instanceId .. ", BossIndex: " .. bossIndex .. ")", 2)
                            self:MarkBossKilled(instanceId, bossIndex)
                            local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                            if watchLevel >= 1 then
                                KOL:Print("Boss defeated: " .. COLOR(data.color, boss.name))
                            end

                            -- Record boss kill for BossRecorder
                            if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                                KOL.BossRecorder:OnBossDetected(destName, destGUID, npcId, "Boss")
                            end
                        end
                    end
                    return
                end
            end
        end

        -- Check grouped bosses
        if data.groups and #data.groups > 0 then
            for groupIndex, group in ipairs(data.groups) do
                if group.bosses then
                    for bossIndex, boss in ipairs(group.bosses) do
                        -- Support both single ID (number) and multiple IDs (table)
                        -- Also support faction-specific IDs (idHorde)
                        local matchFound = false
                        local bossId = self:GetBossId(boss)
                        local isMultiNPC = type(bossId) == "table"

                        if isMultiNPC then
                            -- Multiple IDs (e.g., Four Horsemen) - check if this NPC is part of the encounter
                            for _, id in ipairs(bossId) do
                                if id == npcId then
                                    matchFound = true
                                    break
                                end
                            end
                        else
                            -- Single ID
                            matchFound = (bossId == npcId)
                        end

                        if matchFound then
                            local groupedBossId = "g" .. groupIndex .. "-b" .. bossIndex

                            KOL:DebugPrint("MATCH FOUND: " .. boss.name .. " (Instance: " .. instanceId .. ", BossID: " .. groupedBossId .. ", NPC: " .. npcId .. ")", 2)

                            -- Store WoW instance ID for this tracker instance
                            if wowInstanceId then
                                self:StoreInstanceID(instanceId, wowInstanceId)
                            end

                            if isMultiNPC then
                                -- Check if this is an "any NPC" boss (Opera Event, Chess Event)
                                -- vs "all must die" boss (Four Horsemen, Twin Val'kyr)
                                if boss.anyNPC then
                                    -- Any NPC dying completes the encounter immediately
                                    KOL:DebugPrint("anyNPC boss: " .. boss.name .. " - NPC " .. npcId .. " died, marking complete", 2)
                                    self:MarkBossKilled(instanceId, groupedBossId)
                                    local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                                    if watchLevel >= 1 then
                                        KOL:Print("Boss defeated: " .. COLOR(data.color, boss.name))
                                    end

                                    -- Record boss kill for BossRecorder
                                    if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                                        KOL.BossRecorder:OnBossDetected(destName, destGUID, npcId, "Boss")
                                    end
                                else
                                    -- Track individual NPC death for multi-NPC bosses (all must die)
                                    if not self.multiNPCKills[instanceId] then
                                        self.multiNPCKills[instanceId] = {}
                                    end
                                    if not self.multiNPCKills[instanceId][groupedBossId] then
                                        self.multiNPCKills[instanceId][groupedBossId] = {}
                                    end
                                    self.multiNPCKills[instanceId][groupedBossId][npcId] = true
                                    KOL.db.profile.tracker.multiNPCKills = self.multiNPCKills

                                    KOL:DebugPrint("Marked NPC " .. npcId .. " as dead for " .. boss.name .. " (bossId=" .. groupedBossId .. ")", 2)

                                    -- Check if ALL NPCs for this boss are now dead
                                    local allDead = true
                                    local deadCount = 0
                                    local totalCount = #bossId
                                    for _, id in ipairs(bossId) do
                                        if self.multiNPCKills[instanceId][groupedBossId][id] then
                                            deadCount = deadCount + 1
                                        else
                                            allDead = false
                                        end
                                    end

                                    KOL:DebugPrint(boss.name .. " progress: " .. deadCount .. "/" .. totalCount .. " killed", 2)

                                    if allDead then
                                        -- All NPCs dead - mark boss as killed!
                                        KOL:DebugPrint("ALL NPCs dead! Marking " .. boss.name .. " as complete", 2)
                                        self:MarkBossKilled(instanceId, groupedBossId)
                                        local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                                        if watchLevel >= 1 then
                                            KOL:Print("Boss defeated: " .. COLOR(data.color, boss.name))
                                        end
                                    else
                                        -- Partial progress
                                        KOL:PrintTag(destName .. " defeated (" .. boss.name .. " encounter - " .. deadCount .. "/" .. totalCount .. ")")
                                    end
                                end
                            else
                                -- Single NPC boss - check if it's multi-phase (like Black Knight)
                                if boss.multiKill and type(boss.multiKill) == "number" then
                                    -- Multi-phase boss (dies multiple times)
                                    if not self.multiPhaseKills[instanceId] then
                                        self.multiPhaseKills[instanceId] = {}
                                    end
                                    if not self.multiPhaseKills[instanceId][bossId] then
                                        self.multiPhaseKills[instanceId][bossId] = 0
                                    end

                                    -- Increment kill count
                                    self.multiPhaseKills[instanceId][bossId] = self.multiPhaseKills[instanceId][bossId] + 1
                                    KOL.db.profile.tracker.multiPhaseKills = self.multiPhaseKills

                                    local killCount = self.multiPhaseKills[instanceId][bossId]
                                    local requiredKills = boss.multiKill

                                    local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                                    if watchLevel >= 1 then
                                        KOL:Print(boss.name .. " defeated (" .. killCount .. "/" .. requiredKills .. ")")
                                    end

                                    -- Only mark as complete when required kills reached
                                    if killCount >= requiredKills then
                                        KOL:DebugPrint("MARKING MULTI-PHASE BOSS AS KILLED: " .. boss.name, 2)
                                        self:MarkBossKilled(instanceId, bossId)
                                        if watchLevel >= 1 then
                                            KOL:Print("Boss defeated: " .. COLOR(data.color, boss.name) .. " (Final Phase)")
                                        end

                                        -- Record boss kill for BossRecorder
                                        if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                                            KOL.BossRecorder:OnBossDetected(destName, destGUID, npcId, "Boss")
                                        end
                                    end
                                else
                                    -- Standard single NPC boss - mark as killed immediately
                                    KOL:DebugPrint("MARKING BOSS AS KILLED: " .. boss.name .. " (Instance: " .. instanceId .. ", BossID: " .. groupedBossId .. ")", 2)
                                    self:MarkBossKilled(instanceId, groupedBossId)
                                    local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                                    if watchLevel >= 1 then
                                        KOL:Print("Boss defeated: " .. COLOR(data.color, boss.name))
                                    end

                                    -- Record boss kill for BossRecorder
                                    if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                                        KOL.BossRecorder:OnBossDetected(destName, destGUID, npcId, "Boss")
                                    end
                                end
                            end
                            return
                        end
                    end
                end
                end
            end
    end  -- End data check

    -- No match found for this NPC ID
    KOL:DebugPrint("NO MATCH: NPC ID " .. tostring(npcId) .. " (" .. tostring(destName) .. ") is not a tracked boss", 3)
end

-- Handle ENCOUNTER_END events for scripted boss encounters
function Tracker:OnEncounterEnd(encounterID, encounterName, difficultyID, raidSize, success)
    -- Always print what we received (for debugging)
    KOL:Print("ENCOUNTER_END fired: " .. tostring(encounterName) .. " (ID: " .. tostring(encounterID) .. ", Success: " .. tostring(success) .. ")")

    -- Only process successful encounters
    if not success or success == 0 then
        KOL:Print("Encounter failed or not successful, ignoring")
        return
    end

    KOL:DebugPrint("ENCOUNTER_END: " .. tostring(encounterName) .. " (ID: " .. tostring(encounterID) .. ", Difficulty: " .. tostring(difficultyID) .. ")", 2)

    -- Find matching boss by encounter name
    for instanceId, data in pairs(self.instances) do
        -- ONLY process kills for the currently active instance
        if instanceId == self.currentInstanceId then
            -- Check flat bosses list
            if data.bosses and #data.bosses > 0 then
            for bossIndex, boss in ipairs(data.bosses) do
                if boss.name == encounterName or (boss.encounterName and boss.encounterName == encounterName) then
                    KOL:DebugPrint("ENCOUNTER MATCH: " .. boss.name .. " (Instance: " .. instanceId .. ", BossIndex: " .. bossIndex .. ")", 2)
                    self:MarkBossKilled(instanceId, bossIndex)
                    local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                    if watchLevel >= 1 then
                        KOL:Print("Boss defeated: " .. COLOR(data.color, boss.name))
                    end

                    -- Record for BossRecorder (use encounterID as fake NPC ID)
                    if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                        local fakeGUID = "0xF130" .. string.format("%04X", encounterID) .. "00000001"
                        KOL.BossRecorder:OnBossDetected(encounterName, fakeGUID, encounterID, "Boss (Encounter)")
                    end
                    return
                end
            end
        end

        -- Check grouped bosses
        if data.groups and #data.groups > 0 then
            for groupIndex, group in ipairs(data.groups) do
                if group.bosses then
                    for bossIndex, boss in ipairs(group.bosses) do
                        if boss.name == encounterName or (boss.encounterName and boss.encounterName == encounterName) then
                            local bossId = "g" .. groupIndex .. "-b" .. bossIndex
                            KOL:DebugPrint("ENCOUNTER MATCH (grouped): " .. boss.name .. " (Instance: " .. instanceId .. ", BossID: " .. bossId .. ")", 2)
                            self:MarkBossKilled(instanceId, bossId)
                            local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                            if watchLevel >= 1 then
                                KOL:Print("Boss defeated: " .. COLOR(data.color, boss.name))
                            end

                            -- Record for BossRecorder
                            if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                                local fakeGUID = "0xF130" .. string.format("%04X", encounterID) .. "00000001"
                                KOL.BossRecorder:OnBossDetected(encounterName, fakeGUID, encounterID, "Boss (Encounter)")
                            end
                            return
                        end
                    end
                end
                end
            end
        end  -- End instanceId check
    end

    KOL:DebugPrint("NO MATCH: Encounter '" .. tostring(encounterName) .. "' is not a tracked boss", 3)
end

-- Handle CHAT_MSG_MONSTER_YELL for yell-based boss detection
function Tracker:OnMonsterYell(text, npcName, ...)
    if not text then return end

    -- VIOLET HOLD: Special yell-based detection for generic encounters
    -- When any VH boss yells, mark the first uncompleted encounter as done
    local zoneName = GetRealZoneText()
    if zoneName == "The Violet Hold" then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "party" then
            local difficulty = GetInstanceDifficulty()  -- 1 = normal, 2 = heroic
            local instanceId = (difficulty == 2) and "vh_h" or "vh_n"

            -- Check if any VH boss yelled their success message
            for npcId, bossInfo in pairs(KOL.Tracker.VioletHoldBossPool) do
                if bossInfo.difficulty == difficulty and bossInfo.successYell then
                    if text:find(bossInfo.successYell, 1, true) then
                        KOL:DebugPrint("VH YELL MATCH: " .. bossInfo.name .. " - Yell: " .. text, 2)

                        local data = self.instances[instanceId]

                        -- Cyanigosa is always boss #3
                        if bossInfo.name == "Cyanigosa" then
                            KOL:DebugPrint("VH: Marking Cyanigosa (boss #3) complete", 2)
                            self:MarkBossKilled(instanceId, 3)
                            local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                            if watchLevel >= 1 then
                                KOL:Print("Boss defeated: " .. COLOR(data.color, bossInfo.name))
                            end

                            -- Update timer log with actual boss name
                            if self.dungeonChallengeState[instanceId] then
                                local currentTime = self.dungeonChallengeState[instanceId].currentTime or 0
                                self:UpdateTimerLogEntry(instanceId, bossInfo.name, currentTime)
                            end

                            -- Record for BossRecorder
                            if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                                local fakeGUID = "0xF130" .. string.format("%04X", npcId) .. "00000001"
                                KOL.BossRecorder:OnBossDetected(bossInfo.name, fakeGUID, npcId, "Boss (Yell)")
                            end
                            return
                        end

                        -- Random bosses: Find the first uncompleted encounter and mark it done
                        for i = 1, 2 do  -- Check Encounter 1 and Encounter 2
                            if not self:IsBossKilled(instanceId, i) then
                                KOL:DebugPrint("VH: Marking Encounter " .. i .. " complete (" .. bossInfo.name .. ")", 2)
                                self:MarkBossKilled(instanceId, i)
                                local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                                if watchLevel >= 1 then
                                    KOL:Print("Boss defeated: " .. COLOR(data.color, bossInfo.name) .. " (Encounter " .. i .. ")")
                                end

                                -- Update timer log with actual boss name
                                if self.dungeonChallengeState[instanceId] then
                                    local currentTime = self.dungeonChallengeState[instanceId].currentTime or 0
                                    self:UpdateTimerLogEntry(instanceId, bossInfo.name, currentTime)
                                end

                                -- Record for BossRecorder
                                if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                                    local fakeGUID = "0xF130" .. string.format("%04X", npcId) .. "00000001"
                                    KOL.BossRecorder:OnBossDetected(bossInfo.name, fakeGUID, npcId, "Boss (Yell)")
                                end
                                return
                            end
                        end

                        -- If we get here, both encounters are done
                        KOL:DebugPrint("VH: Both encounters already complete, ignoring yell from " .. bossInfo.name, 2)
                        return
                    end
                end
            end
        end
    end

    -- Check all instances for yell-based bosses
    for instanceId, data in pairs(self.instances) do
        -- Only check yells for the currently active instance (same logic as NPC ID tracking)
        if instanceId == self.currentInstanceId then
            -- Check custom tracker entries (new format with count support)
            if data.entries and #data.entries > 0 then
                for _, entry in ipairs(data.entries) do
                    if entry.type == "yell" and entry.yell then
                        local yellMatch = text:find(entry.yell, 1, true)
                        if yellMatch then
                            local entryId = "yell-" .. entry.yell
                            local requiredCount = entry.count or 1
                            local currentProgress = self:GetEntryProgress(instanceId, entryId)

                            -- Only increment if not already complete
                            if currentProgress < requiredCount then
                                local newCount, complete = self:IncrementEntryProgress(instanceId, entryId, requiredCount)
                                if complete then
                                    KOL:Print("Yell complete: " .. COLOR(data.color, entry.name) .. " [" .. newCount .. "/" .. requiredCount .. "]")
                                else
                                    KOL:Print("Yell progress: " .. COLOR(data.color, entry.name) .. " [" .. newCount .. "/" .. requiredCount .. "]")
                                end
                            end
                            return
                        end
                    end
                end
            end

            -- Check flat bosses
            if data.bosses and #data.bosses > 0 then
                for bossIndex, boss in ipairs(data.bosses) do
                    -- Check for yell if boss has a yell field (supports both type="yell" and regular bosses with yell fallback)
                    if boss.yell then
                    local yellMatch = false
                    local matchedYellIndex = nil

                    -- Support both single yell string and table of yells
                    if type(boss.yell) == "table" then
                        for yellIndex, yellText in ipairs(boss.yell) do
                            if text:find(yellText, 1, true) then
                                yellMatch = true
                                matchedYellIndex = yellIndex
                                break
                            end
                        end
                    else
                        yellMatch = text:find(boss.yell, 1, true)
                    end

                    if yellMatch then
                        KOL:DebugPrint("YELL MATCH: " .. boss.name .. " - Yell: " .. text, 2)
                        self:MarkBossKilled(instanceId, bossIndex)
                        local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                        if watchLevel >= 1 then
                            KOL:Print("Boss defeated: " .. COLOR(data.color, boss.name))
                        end

                        -- Record for BossRecorder (use boss NPC ID if available, otherwise 0)
                        if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                            local npcId = 0
                            if boss.id then
                                if type(boss.id) == "table" then
                                    -- Use the NPC ID that matches the yell index
                                    npcId = boss.id[matchedYellIndex] or boss.id[1]
                                else
                                    npcId = boss.id
                                end
                            end
                            local fakeGUID = "0xF130" .. string.format("%04X", npcId) .. "00000001"
                            KOL.BossRecorder:OnBossDetected(boss.name, fakeGUID, npcId, "Boss (Yell)")
                        end
                        return
                    end
                end
            end
        end

            -- Check grouped bosses
            if data.groups and #data.groups > 0 then
                for groupIndex, group in ipairs(data.groups) do
                    if group.bosses then
                        for bossIndex, boss in ipairs(group.bosses) do
                            -- Check for yell if boss has a yell field (supports both type="yell" and regular bosses with yell fallback)
                            if boss.yell then
                            local yellMatch = false
                            local matchedYellIndex = nil

                            -- Support both single yell string and table of yells
                            if type(boss.yell) == "table" then
                                for yellIndex, yellText in ipairs(boss.yell) do
                                    if text:find(yellText, 1, true) then
                                        yellMatch = true
                                        matchedYellIndex = yellIndex
                                        break
                                    end
                                end
                            else
                                yellMatch = text:find(boss.yell, 1, true)
                            end

                            if yellMatch then
                                local bossId = "g" .. groupIndex .. "-b" .. bossIndex
                                KOL:DebugPrint("YELL MATCH (grouped): " .. boss.name .. " - Yell: " .. text, 2)
                                self:MarkBossKilled(instanceId, bossId)
                                local watchLevel = KOL.db.profile.watchDeathsLevel or 0
                                if watchLevel >= 1 then
                                    KOL:Print("Boss defeated: " .. COLOR(data.color, boss.name))
                                end

                                -- Record for BossRecorder
                                if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                                    local npcId = 0
                                    if boss.id then
                                        if type(boss.id) == "table" then
                                            -- Use the NPC ID that matches the yell index
                                            npcId = boss.id[matchedYellIndex] or boss.id[1]
                                        else
                                            npcId = boss.id
                                        end
                                    end
                                    local fakeGUID = "0xF130" .. string.format("%04X", npcId) .. "00000001"
                                    KOL.BossRecorder:OnBossDetected(boss.name, fakeGUID, npcId, "Boss (Yell)")
                                end
                                return
                            end
                        end
                    end
                end
            end
        end
        end  -- End instanceId check
    end  -- End for loop

    -- Check for hardmode activation yells across all active instances
    if self.currentInstanceId then
        local data = self.instances[self.currentInstanceId]
        if data then
            -- Check flat bosses
            if data.bosses and #data.bosses > 0 then
                for i, boss in ipairs(data.bosses) do
                    self:DetectHardmode(self.currentInstanceId, i, "yell", text)
                end
            end

            -- Check grouped bosses
            if data.groups and #data.groups > 0 then
                for groupIndex, group in ipairs(data.groups) do
                    if group.bosses then
                        for bossIndex, boss in ipairs(group.bosses) do
                            local bossId = "g" .. groupIndex .. "-b" .. bossIndex
                            self:DetectHardmode(self.currentInstanceId, bossId, "yell", text)
                        end
                    end
                end
            end
        end
    end
end

-- Handle CHAT_MSG_RAID_BOSS_EMOTE for emote-based boss detection
function Tracker:OnRaidBossEmote(text, npcName, ...)
    if not text then return end

    -- Check all instances for emote-based bosses
    for instanceId, data in pairs(self.instances) do
        -- Check flat bosses
        if data.bosses and #data.bosses > 0 then
            for bossIndex, boss in ipairs(data.bosses) do
                if boss.type == "emote" and boss.emote and text:find(boss.emote, 1, true) then
                    KOL:DebugPrint("EMOTE MATCH: " .. boss.name .. " - Emote: " .. text, 2)
                    self:MarkBossKilled(instanceId, bossIndex)
                    KOL:Print("Boss defeated: " .. COLOR(data.color, boss.name))

                    -- Record for BossRecorder
                    if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                        local npcId = 0
                        if boss.id then
                            if type(boss.id) == "table" then
                                npcId = boss.id[1]  -- Use first ID if it's a table
                            else
                                npcId = boss.id
                            end
                        end
                        local fakeGUID = "0xF130" .. string.format("%04X", npcId) .. "00000001"
                        KOL.BossRecorder:OnBossDetected(boss.name, fakeGUID, npcId, "Boss (Emote)")
                    end
                    return
                end
            end
        end

        -- Check grouped bosses
        if data.groups and #data.groups > 0 then
            for groupIndex, group in ipairs(data.groups) do
                if group.bosses then
                    for bossIndex, boss in ipairs(group.bosses) do
                        if boss.type == "emote" and boss.emote and text:find(boss.emote, 1, true) then
                            local bossId = "g" .. groupIndex .. "-b" .. bossIndex
                            KOL:DebugPrint("EMOTE MATCH (grouped): " .. boss.name .. " - Emote: " .. text, 2)
                            self:MarkBossKilled(instanceId, bossId)
                            KOL:Print("Boss defeated: " .. COLOR(data.color, boss.name))

                            -- Record for BossRecorder
                            if KOL.BossRecorder and KOL.BossRecorder.OnBossDetected then
                                local npcId = 0
                                if boss.id then
                                    if type(boss.id) == "table" then
                                        npcId = boss.id[1]  -- Use first ID if it's a table
                                    else
                                        npcId = boss.id
                                    end
                                end
                                local fakeGUID = "0xF130" .. string.format("%04X", npcId) .. "00000001"
                                KOL.BossRecorder:OnBossDetected(boss.name, fakeGUID, npcId, "Boss (Emote)")
                            end
                            return
                        end
                    end
                end
            end
        end
    end
end

-- Handle CHAT_MSG_LOOT for item drop detection (custom panels)
function Tracker:OnLoot(message, ...)
    if not message then return end

    -- Extract item link from loot message
    -- Format: "You receive loot: [Item Name]" or "PlayerName receives loot: [Item Name]"
    local itemLink = message:match("|c%x+|Hitem:(%d+).-|h%[.-%]|h|r")
    if not itemLink then
        -- Try alternate format - just get the item ID
        itemLink = message:match("|Hitem:(%d+)")
    end

    if not itemLink then return end

    local lootedItemId = tonumber(itemLink)
    if not lootedItemId then return end

    KOL:DebugPrint("Tracker: Loot detected - Item ID: " .. lootedItemId, 3)

    -- Check all instances for loot-based entries
    for instanceId, data in pairs(self.instances) do
        -- Check custom tracker entries (new format with count support)
        if data.entries and #data.entries > 0 then
            for _, entry in ipairs(data.entries) do
                if entry.type == "loot" and entry.itemId then
                    if entry.itemId == lootedItemId then
                        local entryId = "loot-" .. entry.itemId
                        local requiredCount = entry.count or 1
                        local currentProgress = self:GetEntryProgress(instanceId, entryId)

                        -- Only increment if not already complete
                        if currentProgress < requiredCount then
                            local newCount, complete = self:IncrementEntryProgress(instanceId, entryId, requiredCount)
                            if complete then
                                KOL:Print("Loot complete: " .. COLOR(data.color, entry.name) .. " [" .. newCount .. "/" .. requiredCount .. "]")
                            else
                                KOL:Print("Loot progress: " .. COLOR(data.color, entry.name) .. " [" .. newCount .. "/" .. requiredCount .. "]")
                            end
                        end
                        return
                    end
                end
            end
        end

        -- Check flat entries/bosses (legacy format)
        local entries = self:GetEntries(data)
        if entries and #entries > 0 and not data.entries then
            for entryIndex, entry in ipairs(entries) do
                local detectionType = self:GetDetectionType(entry)
                if detectionType == "loot" then
                    local itemIds = self:GetLootItemIds(entry)
                    for _, targetItemId in ipairs(itemIds) do
                        if targetItemId == lootedItemId then
                            KOL:DebugPrint("LOOT MATCH: " .. entry.name .. " - Item ID: " .. lootedItemId, 2)
                            self:MarkBossKilled(instanceId, entryIndex)
                            KOL:Print("Loot obtained: " .. COLOR(data.color, entry.name))
                            return
                        end
                    end
                end
            end
        end

        -- Check grouped entries (old raid/dungeon format)
        if data.groups and #data.groups > 0 and not data.entries then
            for groupIndex, group in ipairs(data.groups) do
                local groupEntries = self:GetEntries(group)
                if groupEntries then
                    for entryIndex, entry in ipairs(groupEntries) do
                        local detectionType = self:GetDetectionType(entry)
                        if detectionType == "loot" then
                            local itemIds = self:GetLootItemIds(entry)
                            for _, targetItemId in ipairs(itemIds) do
                                if targetItemId == lootedItemId then
                                    local bossId = "g" .. groupIndex .. "-b" .. entryIndex
                                    KOL:DebugPrint("LOOT MATCH (grouped): " .. entry.name .. " - Item ID: " .. lootedItemId, 2)
                                    self:MarkBossKilled(instanceId, bossId)
                                    KOL:Print("Loot obtained: " .. COLOR(data.color, entry.name))
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Get progress string for multi-NPC encounters (for debugging)
function Tracker:GetMultiNPCProgress(instanceId, bossId, boss)
    if not self.multiNPCKills[instanceId] or not self.multiNPCKills[instanceId][bossId] then
        return "0/" .. #boss.id
    end

    local killed = 0
    for _, id in ipairs(boss.id) do
        if self.multiNPCKills[instanceId][bossId][id] then
            killed = killed + 1
        end
    end

    return killed .. "/" .. #boss.id
end

-- Generate short title format for compact display
function Tracker:GetShortTitle(data)
    local title = data.name or "Unknown"

    -- Difficulty mapping (patterns need escaped parentheses: %( and %)
    local difficultyShorthand = {
        -- Dungeons (5-player)
        ["%(Normal%)"] = "(5N)",
        ["%(Heroic%)"] = "(5H)",
        -- Raids
        ["%(10%-Player%)"] = "(10N)",
        ["%(25%-Player%)"] = "(25N)",
        ["%(40%-Player%)"] = "(40N)",
        ["%(10%-Player Heroic%)"] = "(10H)",
        ["%(25%-Player Heroic%)"] = "(25H)",
    }

    -- Try to replace known difficulty patterns
    for longForm, shortForm in pairs(difficultyShorthand) do
        local newTitle = string.gsub(title, longForm, shortForm)
        if newTitle ~= title then
            return newTitle
        end
    end

    -- If no pattern matched, return original
    return title
end

-- Extract NPC ID from GUID
function Tracker:ExtractNPCID(guid)
    if not guid then return nil end

    -- WotLK 3.3.5 uses hexadecimal GUIDs like 0xF130003E8B0003CD
    -- Format: 0xTTTTSSSSNNNNIIII where NNNN is the NPC ID
    -- The NPC ID is bytes 5-6 (characters 7-10 after removing "0x")

    local guidStr = tostring(guid)

    -- Remove "0x" prefix if present
    if string.sub(guidStr, 1, 2) == "0x" then
        guidStr = string.sub(guidStr, 3)
    end

    -- Extract NPC ID (bytes 5-6 = characters 7-10 in hex string)
    -- Example: "F130003E8B0003CD" -> "3E8B" -> 16011
    if string.len(guidStr) >= 10 then
        local npcIdHex = string.sub(guidStr, 7, 10)
        local npcId = tonumber(npcIdHex, 16)  -- Convert from hex to decimal
        return npcId
    end

    return nil
end

-- Extract Instance ID from creature GUID
function Tracker:ExtractInstanceID(guid)
    if not guid then return nil end

    -- WotLK 3.3.5 GUID format: 0xTTTTSSSSNNNNIIII
    -- Instance ID is the last 4 hex digits (bytes 7-8)
    -- Example: "F130003E8B0003CD" -> "03CD" -> 973

    local guidStr = tostring(guid)

    -- Remove "0x" prefix if present
    if string.sub(guidStr, 1, 2) == "0x" then
        guidStr = string.sub(guidStr, 3)
    end

    -- Extract Instance ID (last 4 characters in hex string)
    if string.len(guidStr) >= 14 then
        local instanceIdHex = string.sub(guidStr, 11, 14)
        local instanceId = tonumber(instanceIdHex, 16)  -- Convert from hex to decimal
        return instanceId
    end

    return nil
end

-- ============================================================================
-- Zone Detection and Auto-Show/Hide
-- ============================================================================

-- Check current zone and show/hide watch frames
function Tracker:UpdateZoneTracking()
    -- Safety check: KOL.db must exist
    if not KOL or not KOL.db or not KOL.db.profile then
        return
    end

    -- Count registered instances
    local instanceCount = 0
    for _ in pairs(self.instances) do instanceCount = instanceCount + 1 end
    KOL:DebugPrint("UpdateZoneTracking called - " .. instanceCount .. " instances registered", 3)

    -- Check autoShow - default to true if nil (for users upgrading from older versions)
    local autoShow = KOL.db.profile.tracker.autoShow
    if autoShow == nil then
        autoShow = true
        KOL.db.profile.tracker.autoShow = true  -- Save the default
    end
    if autoShow == false then
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

    -- Detect if we're exiting an instance (for reset detection)
    -- ONLY trigger exit if we're going from an instance to OUTSIDE (no instance, or world zone)
    if self.currentInstanceId and self.currentInstanceId ~= instanceId then
        local prevInstanceData = self.instances[self.currentInstanceId]

        -- Only consider it an "exit" if we're leaving an instance/raid/dungeon to go to the world
        -- Don't trigger on subzone changes within the same instance
        if prevInstanceData and (not instanceId or (instanceType == "none")) then
            -- We genuinely left the instance - we're now in the world
            self:OnInstanceExit(self.currentInstanceId)
            KOL:DebugPrint("Tracker: Detected genuine exit from " .. self.currentInstanceId .. " to outside", 2)
        else
            -- Just a zone/difficulty change within instances, ignore
            KOL:DebugPrint("Tracker: Zone change from " .. tostring(self.currentInstanceId) .. " to " .. tostring(instanceId) .. " (not an exit)", 3)
        end
    end

    -- Update current instance
    self.currentInstanceId = instanceId

    -- Destroy all active frames that don't match current zone
    -- SKIP custom trackers - they are manually controlled and should persist
    for activeId, frame in pairs(self.activeFrames) do
        if activeId ~= instanceId then
            -- Only auto-destroy dungeon/raid frames, not custom trackers
            local activeData = self.instances[activeId]
            local isCustom = activeData and (activeData.type ~= "dungeon" and activeData.type ~= "raid")
            if not isCustom then
                self:DestroyWatchFrame(activeId)
            end
        end
    end

    -- Show frame for current zone if found
    if instanceId and instanceData then
        KOL:DebugPrint("UpdateZoneTracking: Showing watch frame for " .. instanceId .. " (instanceType=" .. tostring(instanceType) .. ")", 3)

        -- Check if this is a fresh instance lockout (auto-reset detection)
        if instanceType ~= "none" then
            KOL:DebugPrint("Calling CheckInstanceReset for " .. instanceId, 3)
            self:CheckInstanceReset(instanceId, zoneName, difficultyIndex)
        end

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

    -- Handle custom trackers with autoShow enabled
    for id, data in pairs(self.instances) do
        if data.type == "custom" and data.autoShow then
            local shouldShow = false

            -- If zones list is empty, show everywhere
            if not data.zones or #data.zones == 0 then
                shouldShow = true
                KOL:DebugPrint("Tracker: Custom '" .. id .. "' autoShow=true, zones empty → show everywhere", 3)
            else
                -- Check if current zone matches any in the list
                for _, zone in ipairs(data.zones) do
                    if zone == zoneName or zone == subZoneName then
                        shouldShow = true
                        KOL:DebugPrint("Tracker: Custom '" .. id .. "' zone matched: " .. zone, 3)
                        break
                    end
                end
            end

            if shouldShow then
                -- Show the custom tracker
                if not self.activeFrames[id] then
                    local success, err = pcall(function()
                        self:ShowWatchFrame(id)
                    end)
                    if not success then
                        KOL:DebugPrint("Tracker: Custom autoShow error: " .. tostring(err), 1)
                    else
                        KOL:DebugPrint("Tracker: Custom '" .. id .. "' auto-shown", 2)
                    end
                end
            else
                -- Hide the custom tracker (if currently shown)
                if self.activeFrames[id] then
                    self:DestroyWatchFrame(id)
                    KOL:DebugPrint("Tracker: Custom '" .. id .. "' auto-hidden (zone mismatch)", 2)
                end
            end
        end
    end
end

-- Store the WoW instance ID when we kill a boss
-- Also detects fresh instances by comparing to stored ID
function Tracker:StoreInstanceID(instanceId, wowInstanceId)
    local storedId = self.instanceLockouts[instanceId]
    local storedIdNum = storedId and tonumber(storedId)

    -- Check if we have boss kills recorded
    local hasKills = self.bossKills[instanceId] and next(self.bossKills[instanceId]) ~= nil

    if storedIdNum and storedIdNum ~= wowInstanceId and hasKills then
        -- DIFFERENT INSTANCE DETECTED!
        -- This means we're in a fresh instance (reset happened, different lockout, etc.)
        -- Reset our tracking since this is a new lockout
        local instanceData = self.instances[instanceId]
        local instanceName = instanceData and instanceData.name or instanceId
        KOL:PrintTag("Fresh instance detected (new lockout ID) - resetting " .. instanceName)
        KOL:DebugPrint("Tracker: Instance ID changed from " .. storedIdNum .. " to " .. wowInstanceId ..
            " for " .. instanceId .. " - RESETTING", 2)
        self:ResetInstance(instanceId)
    end

    -- Store the current instance ID (session-only, not persisted to DB)
    self.instanceLockouts[instanceId] = tostring(wowInstanceId)
    KOL:DebugPrint("Tracker: WoW Instance ID for " .. instanceId .. " = " .. wowInstanceId .. " (session-only)", 3)
end

-- Check if instance has reset when player re-enters
-- Uses WoW's internal instance ID to detect fresh instances (not time-based)
function Tracker:CheckInstanceReset(instanceId, zoneName, difficultyIndex)
    local instanceData = self.instances[instanceId]
    if not instanceData then return end

    -- Check if we have kills recorded
    local hasKills = self.bossKills[instanceId] and next(self.bossKills[instanceId]) ~= nil

    -- Check if we have a saved timer
    local hasSavedTimer = false
    if KOL.db.profile.tracker.dungeonChallenge and KOL.db.profile.tracker.dungeonChallenge.currentTimes then
        hasSavedTimer = (KOL.db.profile.tracker.dungeonChallenge.currentTimes[instanceId] or 0) > 0
    end

    if not hasKills and not hasSavedTimer then
        -- No kills recorded and no saved timer, nothing to reset
        KOL:DebugPrint("Tracker: No kills or saved timer for " .. instanceId .. ", skipping reset check", 3)
        return
    end

    KOL:DebugPrint("Tracker: Checking reset for " .. instanceId .. " | hasKills=" .. tostring(hasKills) ..
        " | hasSavedTimer=" .. tostring(hasSavedTimer), 3)

    -- Reset detection is now handled by:
    -- 1. UPDATE_INSTANCE_INFO event when player manually resets while outside (OnInstanceInfoUpdate)
    -- 2. Instance ID comparison when a boss dies (StoreInstanceID detects different lockout)
    --
    -- We do NOT use time-based reset anymore because:
    -- - Dying and running back takes time but shouldn't reset progress
    -- - Hearthing out to repair shouldn't reset progress
    -- - Only actual instance resets should clear progress

    KOL:DebugPrint("CheckInstanceReset: Re-entering " .. instanceId .. " - keeping progress (instance ID based reset only)", 3)
end

-- Track when player exits an instance
function Tracker:OnInstanceExit(instanceId)
    -- Only track if we have kills or a saved timer
    local hasKills = self.bossKills[instanceId] and next(self.bossKills[instanceId]) ~= nil

    local hasSavedTimer = false
    if KOL.db.profile.tracker.dungeonChallenge and KOL.db.profile.tracker.dungeonChallenge.currentTimes then
        hasSavedTimer = (KOL.db.profile.tracker.dungeonChallenge.currentTimes[instanceId] or 0) > 0
    end

    if hasKills or hasSavedTimer then
        local exitTime = time()
        self.lastExitTime[instanceId] = exitTime
        KOL:DebugPrint("Tracker: Exiting " .. instanceId .. " (kills=" .. tostring(hasKills) .. ", timer=" .. tostring(hasSavedTimer) .. ") - recorded exit time", 3)
    end
end

-- ============================================================================
-- Instance Reset Event Handlers (The SMART Way!)
-- ============================================================================

-- Called when instance info updates (including manual resets)
function Tracker:OnInstanceInfoUpdate()
    -- UPDATE_INSTANCE_INFO fires for MANY reasons:
    -- - When you click "Reset All Instances" (OUTSIDE instances - what we want to detect!)
    -- - When you kill a boss and lockout info updates (INSIDE instance - ignore!)
    -- - When you request instance info
    --
    -- KEY INSIGHT: You can ONLY reset instances while OUTSIDE them!
    -- So if this event fires while we're INSIDE an instance, it's just lockout info updating.
    -- If it fires while we're OUTSIDE (in the world), that's a potential manual reset!

    local name, instanceType, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic = GetInstanceInfo()

    KOL:DebugPrint("UPDATE_INSTANCE_INFO fired | instanceType=" .. tostring(instanceType), 3)

    -- If we're currently INSIDE an instance, this is just lockout info updating (boss kill, etc)
    -- Ignore it - NOT a reset!
    if instanceType ~= "none" then
        KOL:DebugPrint("  -> Inside instance, ignoring (just lockout info update)", 3)
        return
    end

    -- We're OUTSIDE instances - this could be a manual reset!
    -- But first, check if we're still in initial load phase (login/reload)
    if not self.initialLoadComplete then
        KOL:DebugPrint("  -> Ignoring (still in initial load phase, not a manual reset)", 2)
        return
    end

    -- Check if we have any tracked instances with kills
    KOL:DebugPrint("  -> Outside instances, checking for manual reset", 2)

    local resetCount = 0

    -- Check all registered instances for kills
    for instanceId, killData in pairs(self.bossKills) do
        local hasKills = killData and next(killData) ~= nil

        if hasKills then
            local instanceData = self.instances[instanceId]
            local instanceName = instanceData and instanceData.name or instanceId

            -- Reset ANY instance with kills (dungeons AND raids)
            if instanceData then
                KOL:PrintTag("Manual reset detected - clearing " .. instanceName)
                self:ResetInstance(instanceId)
                resetCount = resetCount + 1
            end
        end
    end

    if resetCount > 0 then
        KOL:PrintTag("Reset " .. resetCount .. " instance(s)")
    else
        KOL:DebugPrint("UPDATE_INSTANCE_INFO while outside, but no instances with kills to reset", 1)
    end
end

-- Called when you're about to be kicked from instance
function Tracker:OnInstanceBootStart()
    KOL:DebugPrint("Tracker: Instance boot starting", 2)
end

-- Called when instance boot is cancelled
function Tracker:OnInstanceBootStop()
    KOL:DebugPrint("Tracker: Instance boot stopped", 2)
end

-- ============================================================================
-- Event Registration
-- ============================================================================

function Tracker:RegisterEvents()
    -- Combat log for boss kills
    KOL:RegisterEventCallback("COMBAT_LOG_EVENT_UNFILTERED", function(...)
        Tracker:OnCombatLogEvent(...)
    end, "Tracker")
    KOL:DebugPrint("Tracker: COMBAT_LOG_EVENT_UNFILTERED registered", 3)

    -- Encounter end for scripted boss events (Grand Champions, etc.)
    KOL:RegisterEventCallback("ENCOUNTER_END", function(...)
        Tracker:OnEncounterEnd(...)
    end, "Tracker")
    KOL:DebugPrint("Tracker: ENCOUNTER_END registered", 3)

    -- Chat events for yell/emote-based encounter detection
    KOL:RegisterEventCallback("CHAT_MSG_MONSTER_YELL", function(...)
        Tracker:OnMonsterYell(...)
    end, "Tracker")
    KOL:DebugPrint("Tracker: CHAT_MSG_MONSTER_YELL registered", 3)

    KOL:RegisterEventCallback("CHAT_MSG_RAID_BOSS_EMOTE", function(...)
        Tracker:OnRaidBossEmote(...)
    end, "Tracker")
    KOL:DebugPrint("Tracker: CHAT_MSG_RAID_BOSS_EMOTE registered", 3)

    -- Loot events for item drop detection (custom panels)
    KOL:RegisterEventCallback("CHAT_MSG_LOOT", function(...)
        Tracker:OnLoot(...)
    end, "Tracker")
    KOL:DebugPrint("Tracker: CHAT_MSG_LOOT registered", 3)

    -- Dungeon Challenge chat messages (listen to multiple event types)
    KOL:RegisterEventCallback("CHAT_MSG_SYSTEM", function(message)
        Tracker:OnDungeonChallengeChat(message)
    end, "Tracker")
    KOL:DebugPrint("Tracker: CHAT_MSG_SYSTEM registered for Dungeon Challenge", 3)

    -- Also listen to other chat events in case the server sends messages through different channels
    KOL:RegisterEventCallback("CHAT_MSG_TEXT_EMOTE", function(message)
        Tracker:OnDungeonChallengeChat(message)
    end, "Tracker")
    KOL:DebugPrint("Tracker: CHAT_MSG_TEXT_EMOTE registered for Dungeon Challenge", 3)

    KOL:RegisterEventCallback("CHAT_MSG_EMOTE", function(message)
        Tracker:OnDungeonChallengeChat(message)
    end, "Tracker")
    KOL:DebugPrint("Tracker: CHAT_MSG_EMOTE registered for Dungeon Challenge", 3)

    KOL:RegisterEventCallback("CHAT_MSG_SAY", function(message)
        Tracker:OnDungeonChallengeChat(message)
    end, "Tracker")
    KOL:DebugPrint("Tracker: CHAT_MSG_SAY registered for Dungeon Challenge", 3)

    -- Hook chat frame AddMessage as fallback for server addon messages
    if not self.chatFrameHooked and DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        local originalAddMessage = DEFAULT_CHAT_FRAME.AddMessage
        DEFAULT_CHAT_FRAME.AddMessage = function(frame, text, ...)
            -- Check if this is a dungeon challenge message
            if text and type(text) == "string" then
                -- Strip color codes before pattern matching
                local plainText = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                Tracker:OnDungeonChallengeChat(plainText)
            end
            -- Call original function
            return originalAddMessage(frame, text, ...)
        end
        self.chatFrameHooked = true
        KOL:DebugPrint("Tracker: DEFAULT_CHAT_FRAME:AddMessage hooked for Dungeon Challenge", 3)
    end

    -- Zone changes
    KOL:RegisterEventCallback("ZONE_CHANGED_NEW_AREA", function()
        Tracker:UpdateZoneTracking()
    end, "Tracker")

    KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
        Tracker:UpdateZoneTracking()
    end, "Tracker")

    -- Instance reset detection (the SMART way!)
    KOL:RegisterEventCallback("UPDATE_INSTANCE_INFO", function()
        Tracker:OnInstanceInfoUpdate()
    end, "Tracker")

    KOL:RegisterEventCallback("INSTANCE_BOOT_START", function()
        Tracker:OnInstanceBootStart()
    end, "Tracker")

    KOL:RegisterEventCallback("INSTANCE_BOOT_STOP", function()
        Tracker:OnInstanceBootStop()
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
    -- Priority: per-instance config override > instance data default > global config > hardcoded default
    -- These are ONLY used as fallback defaults if auto-sizing can't determine dimensions
    local config = KOL.db.profile.tracker
    local defaultFrameWidth = GetInstanceSetting(instanceId, "frameWidth") or data.frameWidth or config.frameWidth or 230
    local defaultFrameHeight = GetInstanceSetting(instanceId, "frameHeight") or data.frameHeight or config.frameHeight or 200
    local scrollBarWidth = GetInstanceSetting(instanceId, "scrollBarWidth") or config.scrollBarWidth or 16
    local showMinimizeBtn = false  -- Removed minimize button - user can double-click titlebar to minimize
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

    -- Get font settings
    local config = KOL.db.profile.tracker
    local fontScale = GetInstanceSetting(instanceId, "fontScale") or config.fontScale or 1.0

    -- Get global defaults
    local globalFont = config.baseFont or "Source Code Pro Bold"
    local globalFontSize = config.baseFontSize or 12

    -- Get specific font settings with fallback to global defaults
    local titleFont = config.titleFont or globalFont
    local titleFontSize = config.titleFontSize or globalFontSize
    local groupFont = config.groupFont or globalFont
    local groupFontSize = config.groupFontSize or globalFontSize
    local objectiveFont = config.objectiveFont or globalFont
    local objectiveFontSize = config.objectiveFontSize or globalFontSize

    -- Get title font path and outline from LibSharedMedia
    local LSM = LibStub("LibSharedMedia-3.0")
    local titleFontPath = LSM:Fetch("font", titleFont) or "Fonts\\FRIZQT__.TTF"
    local titleFontOutline = config.titleFontOutline or "OUTLINE"

    -- Smart auto-sizing: Calculate minimum width needed for title text
    local titleTextContent = GetInstanceSetting(instanceId, "titleText")
    if not titleTextContent or titleTextContent == "" then
        -- Generate short title format: "Dungeon Name (5H)" instead of "Dungeon Name (Heroic)"
        titleTextContent = self:GetShortTitle(data)
    end

    -- Create temporary font string to measure text width
    local tempFrame = CreateFrame("Frame")
    local tempString = tempFrame:CreateFontString()
    local actualTitleFontSize = math.floor(titleFontSize * fontScale)
    tempString:SetFont(titleFontPath, actualTitleFontSize, titleFontOutline)
    tempString:SetText(titleTextContent)  -- No color codes for measurement

    local titleTextWidth = tempString:GetStringWidth()
    local leftPadding = 8
    local rightPadding = showMinimizeBtn and 30 or 10  -- +2 pixels back from minimize button removal
    local borderPadding = 2  -- Account for frame border
    local minWidthForTitle = math.ceil(titleTextWidth + leftPadding + rightPadding + borderPadding)  -- No extra buffer

    -- Scale default width by fontScale, then use the larger of scaled default or minimum width for title
    local scaledDefaultWidth = math.floor(defaultFrameWidth * fontScale)
    local frameWidth = math.max(scaledDefaultWidth, minWidthForTitle)

    -- Use default height initially; it will be resized based on content later
    local frameHeight = defaultFrameHeight

    KOL:DebugPrint(string.format("Tracker: Auto-sizing frame for '%s' - Title width: %d, Min frame width: %d, Final width: %d",
        titleTextContent, titleTextWidth, minWidthForTitle, frameWidth), 3)

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
    titleBar:SetSize(frameWidth - 2, 20)
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
    local actualTitleFontSize = math.floor(titleFontSize * fontScale)
    local titleText = CreateFrame("Button", nil, titleBar)
    titleText:SetPoint("TOPLEFT", titleBar, "TOPLEFT", 8, 0)
    titleText:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", showMinimizeBtn and -30 or -8, 0)
    titleText:EnableMouse(true)
    titleText:RegisterForClicks("AnyUp")
    titleText:RegisterForDrag("LeftButton")

    local titleString = titleText:CreateFontString(nil, "OVERLAY")
    titleString:SetFont(titleFontPath, actualTitleFontSize, titleFontOutline)
    titleString:SetPoint("CENTER", titleText, "CENTER", 0, 0)

    -- titleTextContent already calculated during auto-sizing
    titleString:SetText("|cFF" .. instanceColorHex .. titleTextContent .. "|r")
    titleString:SetJustifyH("LEFT")
    titleString:SetWordWrap(false)
    titleText.text = titleString

    -- Single click to minimize/restore
    titleText:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            Tracker:ToggleMinimize(frame)
        end
    end)

    -- Dragging from title text
    titleText:SetScript("OnDragStart", function(self)
        frame.isMoving = true  -- Flag to skip expensive updates during drag
        frame:StartMoving()
    end)
    titleText:SetScript("OnDragStop", function(self)
        frame:StopMovingOrSizing()
        frame.isMoving = false
        Tracker:SaveFramePosition(instanceId)
    end)

    frame.titleText = titleText

    -- Minimize button (optional)
    local minimizeBtn
    if showMinimizeBtn then
        minimizeBtn = CreateFrame("Button", nil, titleBar)
        minimizeBtn:SetSize(16, 16)
        minimizeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -2, 0)
        minimizeBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        minimizeBtn:SetBackdropColor(0.2, 0.2, 0.2, 1)
        minimizeBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        local minBtnText = KOL.UIFactory:CreateGlyph(minimizeBtn, CHAR_UI_MINIMIZE, {r = 0.8, g = 0.8, b = 0.8}, 9)
        minBtnText:SetPoint("CENTER")
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
    -- Only add scrollbar padding if scrollbar will be visible
    -- Use custom tracker setting for custom trackers, otherwise use global setting
    local showScrollBarConfig
    local isCustomTracker = data.type ~= "dungeon" and data.type ~= "raid"
    if isCustomTracker and KOL.db.profile.tracker.customShowScrollBar ~= nil then
        showScrollBarConfig = KOL.db.profile.tracker.customShowScrollBar
    else
        showScrollBarConfig = KOL.db.profile.tracker.showScrollBar
    end
    if showScrollBarConfig == nil then
        showScrollBarConfig = false  -- Default to hidden
    end
    local scrollBarPadding = showScrollBarConfig and (scrollBarWidth + 8) or 4
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
        -- Get font for scroll buttons
        -- Ensure minimum font size of 6 to prevent crashes with small scrollbar widths
        local btnFontSize = math.max(6, scrollBarWidth - 2)

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

        local upText = KOL.UIFactory:CreateGlyph(scrollUpBtn, CHAR_ARROW_UPFILLED, {r = 0.6, g = 0.6, b = 0.6}, btnFontSize)
        upText:SetPoint("CENTER", 0, 0)
        scrollUpBtn.text = upText

        scrollUpBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.25, 0.25, 0.25, 1)
            if self.text and self.text.SetGlyph then self.text:SetGlyph(nil, {r = 0.9, g = 0.9, b = 0.9}) end
        end)
        scrollUpBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
            if self.text and self.text.SetGlyph then self.text:SetGlyph(nil, {r = 0.6, g = 0.6, b = 0.6}) end
        end)

        scrollUpBtn:Hide()  -- Start hidden, will show if needed by OnScrollRangeChanged
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

        local downText = KOL.UIFactory:CreateGlyph(scrollDownBtn, CHAR_ARROW_DOWNFILLED, {r = 0.6, g = 0.6, b = 0.6}, btnFontSize)
        downText:SetPoint("CENTER", 0, 0)
        scrollDownBtn.text = downText

        scrollDownBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.25, 0.25, 0.25, 1)
            if self.text and self.text.SetGlyph then self.text:SetGlyph(nil, {r = 0.9, g = 0.9, b = 0.9}) end
        end)
        scrollDownBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
            if self.text and self.text.SetGlyph then self.text:SetGlyph(nil, {r = 0.6, g = 0.6, b = 0.6}) end
        end)

        scrollDownBtn:Hide()  -- Start hidden, will show if needed by OnScrollRangeChanged
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
    scrollBar:SetMinMaxValues(0, 0)  -- Start with 0 range (will be updated by OnScrollRangeChanged)
    scrollBar:SetValue(0)
    scrollBar:EnableMouseWheel(true)
    scrollBar:Hide()  -- Start hidden, will show if needed by OnScrollRangeChanged
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
    local scrollBarBorderColor = GetInstanceSetting(instanceId, "scrollBarBorderColor")
    if scrollBarBorderColor then
        scrollBar:SetBackdropBorderColor(scrollBarBorderColor[1], scrollBarBorderColor[2], scrollBarBorderColor[3], scrollBarBorderColor[4] or 1)
    else
        scrollBar:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    end

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
        local scrollFrameHeight = self:GetHeight()
        local contentHeight = content:GetHeight()

        KOL:DebugPrint(string.format("Tracker: Scroll range changed - yRange=%.1f, scrollFrameHeight=%.1f, contentHeight=%.1f",
            yRange or 0, scrollFrameHeight or 0, contentHeight or 0), 2)

        -- Check if scrollbar visibility is enabled in config
        -- Use custom tracker setting for custom trackers, otherwise use global setting
        local showScrollBarConfig
        local instanceData = Tracker.instances[instanceId]
        local isCustom = instanceData and (instanceData.type ~= "dungeon" and instanceData.type ~= "raid")
        if isCustom and KOL.db.profile.tracker.customShowScrollBar ~= nil then
            showScrollBarConfig = KOL.db.profile.tracker.customShowScrollBar
        else
            showScrollBarConfig = KOL.db.profile.tracker.showScrollBar
        end
        if showScrollBarConfig == nil then
            showScrollBarConfig = false  -- Default to hidden
        end

        if scrollRange > 2 and showScrollBarConfig then
            scrollBar:SetMinMaxValues(0, scrollRange)
            scrollBar:Show()
            if scrollUpBtn then scrollUpBtn:Show() end
            if scrollDownBtn then scrollDownBtn:Show() end
            KOL:DebugPrint("Tracker: Scrollbar shown (content exceeds frame and showScrollBar enabled)", 3)
        else
            scrollBar:SetMinMaxValues(0, 0)
            scrollBar:SetValue(0)
            scrollBar:Hide()
            if scrollUpBtn then scrollUpBtn:Hide() end
            if scrollDownBtn then scrollDownBtn:Hide() end
            if showScrollBarConfig == false then
                KOL:DebugPrint("Tracker: Scrollbar hidden (showScrollBar disabled in config)", 3)
            else
                KOL:DebugPrint("Tracker: Scrollbar hidden (content fits in frame)", 3)
            end
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
                frame:SetBackdropColor(showBg[1], showBg[2], showBg[3], showBg[4])
                frame:SetBackdropBorderColor(showBorder[1], showBorder[2], showBorder[3], showBorder[4])
                frame.titleBar:SetBackdropColor(showTitle[1], showTitle[2], showTitle[3], showTitle[4])
                -- Only set alpha if scroll bar is actually shown (has scrollable content)
                if frame.scrollBar and frame.scrollBar:IsShown() then frame.scrollBar:SetAlpha(1) end
                if frame.scrollUpBtn and frame.scrollUpBtn:IsShown() then frame.scrollUpBtn:SetAlpha(1) end
                if frame.scrollDownBtn and frame.scrollDownBtn:IsShown() then frame.scrollDownBtn:SetAlpha(1) end
                if frame.minimizeBtn then frame.minimizeBtn:SetAlpha(1) end
            else
                -- Hide all UI elements (set alpha to 0)
                frame:SetBackdropColor(showBg[1], showBg[2], showBg[3], 0)
                frame:SetBackdropBorderColor(showBorder[1], showBorder[2], showBorder[3], 0)
                frame.titleBar:SetBackdropColor(showTitle[1], showTitle[2], showTitle[3], 0)
                if frame.scrollBar and frame.scrollBar:IsShown() then frame.scrollBar:SetAlpha(0) end
                if frame.scrollUpBtn and frame.scrollUpBtn:IsShown() then frame.scrollUpBtn:SetAlpha(0) end
                if frame.scrollDownBtn and frame.scrollDownBtn:IsShown() then frame.scrollDownBtn:SetAlpha(0) end
                if frame.minimizeBtn then frame.minimizeBtn:SetAlpha(0) end
            end
        else
            -- Normal visibility (UI always shown) with configured colors
            frame:SetBackdropColor(showBg[1], showBg[2], showBg[3], showBg[4])
            frame:SetBackdropBorderColor(showBorder[1], showBorder[2], showBorder[3], showBorder[4])
            frame.titleBar:SetBackdropColor(showTitle[1], showTitle[2], showTitle[3], showTitle[4])
            -- Only set alpha if scroll bar is actually shown (has scrollable content)
            if frame.scrollBar and frame.scrollBar:IsShown() then frame.scrollBar:SetAlpha(1) end
            if frame.scrollUpBtn and frame.scrollUpBtn:IsShown() then frame.scrollUpBtn:SetAlpha(1) end
            if frame.scrollDownBtn and frame.scrollDownBtn:IsShown() then frame.scrollDownBtn:SetAlpha(1) end
            if frame.minimizeBtn then frame.minimizeBtn:SetAlpha(1) end
        end
    end

    -- Store function on frame so it can be called externally
    frame.UpdateUIVisibility = UpdateUIVisibility

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

    -- Skip expensive updates while dragging the frame
    if frame.isMoving then
        return
    end

    local data = frame.instanceData
    local content = frame.content

    -- No max height - we'll auto-size based on content only
    -- Config values are just fallback defaults if we can't determine size
    local config = KOL.db.profile.tracker

    -- Get font settings
    local fontScale = GetInstanceSetting(instanceId, "fontScale") or config.fontScale or 1.0

    -- Get global defaults
    local globalFont = config.baseFont or "Source Code Pro Bold"
    local globalFontSize = config.baseFontSize or 12

    -- Get specific font settings with fallback to global defaults
    local titleFont = config.titleFont or globalFont
    local titleFontSize = config.titleFontSize or globalFontSize

    -- Update title font with current fontScale
    local LSM = LibStub("LibSharedMedia-3.0")
    local titleFontPath = LSM:Fetch("font", titleFont) or "Fonts\\FRIZQT__.TTF"
    local titleFontOutline = config.titleFontOutline or "OUTLINE"
    local scaledTitleFontSize = math.floor(titleFontSize * fontScale)

    if frame.titleText and frame.titleText.text then
        frame.titleText.text:SetFont(titleFontPath, scaledTitleFontSize, titleFontOutline)
    end

    -- Recalculate frame width based on scaled title
    local titleTextContent = GetInstanceSetting(instanceId, "titleText")
    if not titleTextContent or titleTextContent == "" then
        titleTextContent = self:GetShortTitle(data)
    end

    -- Measure title width with scaled font (use cached frame to avoid garbage)
    if not self.textMeasureFrame then
        self.textMeasureFrame = CreateFrame("Frame")
        self.textMeasureString = self.textMeasureFrame:CreateFontString()
    end
    self.textMeasureString:SetFont(titleFontPath, scaledTitleFontSize, titleFontOutline)
    self.textMeasureString:SetText(titleTextContent)

    local titleTextWidth = self.textMeasureString:GetStringWidth()
    local showMinimizeBtn = false  -- Removed minimize button - user can double-click titlebar to minimize
    local leftPadding = 8
    local rightPadding = showMinimizeBtn and 30 or 10  -- +2 pixels back from minimize button removal
    local borderPadding = 2
    local minWidthForTitle = math.ceil(titleTextWidth + leftPadding + rightPadding + borderPadding)

    -- Get default frame width and scale it by fontScale
    local defaultFrameWidth = GetInstanceSetting(instanceId, "frameWidth") or data.frameWidth or config.frameWidth or 230
    local scaledDefaultWidth = math.floor(defaultFrameWidth * fontScale)
    local newFrameWidth = math.max(scaledDefaultWidth, minWidthForTitle)

    -- Update frame width
    frame:SetWidth(newFrameWidth)

    -- Update content width
    local scrollBarWidth = GetInstanceSetting(instanceId, "scrollBarWidth") or config.scrollBarWidth or 16
    -- Only add scrollbar padding if scrollbar is visible
    -- Use custom tracker setting for custom trackers, otherwise use global setting
    local showScrollBarConfig
    local isCustomTracker = data.type ~= "dungeon" and data.type ~= "raid"
    if isCustomTracker and KOL.db.profile.tracker.customShowScrollBar ~= nil then
        showScrollBarConfig = KOL.db.profile.tracker.customShowScrollBar
    else
        showScrollBarConfig = KOL.db.profile.tracker.showScrollBar
    end
    if showScrollBarConfig == nil then
        showScrollBarConfig = false  -- Default to hidden
    end
    local scrollBarPadding = showScrollBarConfig and (scrollBarWidth + 8) or 4
    local contentWidth = newFrameWidth - scrollBarPadding - 8
    content:SetWidth(contentWidth)

    -- Clear existing boss texts and buttons - release to pools for reuse
    self:ReleaseWatchFrameElements(frame)

    -- Get colors
    local instanceColor = KOL.Colors:GetPastel(data.color or "PINK")
    local killedColor = KOL.Colors:GetPastel("GREEN")
    local unkilledColor = KOL.Colors:GetPastel("RED")

    local instanceColorHex = KOL.Colors:ToHex(instanceColor)
    local killedColorHex = KOL.Colors:ToHex(killedColor)
    local unkilledColorHex = KOL.Colors:ToHex(unkilledColor)

    -- Get group header colors from config (with defaults)
    local groupIncompleteColorConfig = KOL.db.profile.tracker and KOL.db.profile.tracker.groupIncompleteColor
    local groupCompleteColorConfig = KOL.db.profile.tracker and KOL.db.profile.tracker.groupCompleteColor
    local groupIncompleteColor = groupIncompleteColorConfig and {groupIncompleteColorConfig[1], groupIncompleteColorConfig[2], groupIncompleteColorConfig[3]} or {0.7, 0.9, 1}
    local groupCompleteColor = groupCompleteColorConfig and {groupCompleteColorConfig[1], groupCompleteColorConfig[2], groupCompleteColorConfig[3]} or {0.75, 1, 0.75}

    -- Get specific font settings with fallback to global defaults
    local groupFont = config.groupFont or globalFont
    local groupFontSize = config.groupFontSize or globalFontSize
    local objectiveFont = config.objectiveFont or globalFont
    local objectiveFontSize = config.objectiveFontSize or globalFontSize

    -- Get font paths from LibSharedMedia
    local LSM = LibStub("LibSharedMedia-3.0")
    local groupFontPath = LSM:Fetch("font", groupFont) or "Fonts\\FRIZQT__.TTF"
    local objectiveFontPath = LSM:Fetch("font", objectiveFont) or "Fonts\\FRIZQT__.TTF"

    -- Get font outlines
    local groupFontOutline = config.groupFontOutline or "OUTLINE"
    local objectiveFontOutline = config.objectiveFontOutline or "OUTLINE"

    -- Apply font scale to sizes
    local scaledGroupFontSize = math.floor(groupFontSize * fontScale)
    local scaledObjectiveFontSize = math.floor(objectiveFontSize * fontScale)

    -- Create boss texts
    local yOffset = -4
    local contentHeight = 0

    -- Render Dungeon Challenge UI (if applicable)
    local dcConfig = KOL.db.profile.tracker.dungeonChallenge
    if dcConfig and dcConfig.enabled then
        local dcState = self:UpdateDungeonChallengeState(instanceId)
        if dcState and dcState.eligible then
            -- Nuclear green and red colors
            local nuclearGreen = "00FF00"
            local redColor = "FF0000"
            local whiteColor = "FFFFFF"

            -- Gradient from white to nuclear green based on stacks (0-50)
            local function GetStackGradientColor(stacks)
                local ratio = math.min(stacks / 50, 1.0)
                local r = math.floor(255 * (1 - ratio))
                local g = 255
                local b = math.floor(255 * (1 - ratio))
                return string.format("%02X%02X%02X", r, g, b)
            end

            -- SPEED buff status line (if enabled AND (buff is active OR has stacks))
            if dcConfig.showBuffStacks and (dcState.buffActive or dcState.speedStacks > 0) then
                local speedStatusText = content:CreateFontString(nil, "OVERLAY")
                speedStatusText:SetFont(objectiveFontPath, scaledObjectiveFontSize, objectiveFontOutline)
                speedStatusText:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
                speedStatusText:SetJustifyH("LEFT")

                local speedColor = dcState.speedStacks > 0 and nuclearGreen or redColor
                local stackColor = GetStackGradientColor(dcState.speedStacks)
                local speedText = "|cFF" .. speedColor .. "SPEED BUFF:|r |cFF" .. stackColor .. dcState.speedStacks .. "|r"
                speedStatusText:SetText(speedText)

                table.insert(frame.bossTexts, speedStatusText)
                yOffset = yOffset - speedStatusText:GetStringHeight() - 2
                contentHeight = contentHeight + speedStatusText:GetStringHeight() + 2
            end

            -- Current timer and best time line (if enabled AND (buff is active OR has stacks))
            if dcConfig.showTimer and (dcState.buffActive or dcState.speedStacks > 0) then
                local currentTimeStr = self:FormatTime(dcState.currentTime)
                local bestTimeStr = self:FormatTime(dcState.bestTime)
                local timerColor = dcState.buffActive and whiteColor or redColor

                -- TIME: portion (user font)
                local timerText = content:CreateFontString(nil, "OVERLAY")
                timerText:SetFont(objectiveFontPath, scaledObjectiveFontSize, objectiveFontOutline)
                timerText:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
                timerText:SetJustifyH("LEFT")
                timerText:SetText("|cFF" .. timerColor .. "TIME: " .. currentTimeStr .. "|r  ")

                -- Arrow separator (ligatures font for guaranteed glyph rendering)
                local timerSeparator = KOL.UIFactory:CreateGlyph(content, CHAR("LEFTRIGHT"), {r = 0.67, g = 0.67, b = 0.67}, scaledObjectiveFontSize)
                timerSeparator:SetPoint("LEFT", timerText, "RIGHT", 0, 0)

                -- BEST: portion (user font)
                local bestText = content:CreateFontString(nil, "OVERLAY")
                bestText:SetFont(objectiveFontPath, scaledObjectiveFontSize, objectiveFontOutline)
                bestText:SetPoint("LEFT", timerSeparator, "RIGHT", 0, 0)
                bestText:SetText("  BEST: |cFF00FF00" .. bestTimeStr .. "|r")

                -- Create invisible frame for timer log tooltip (spans all three text elements)
                local timerTooltipFrame = Tracker:AcquireFrame(content)
                timerTooltipFrame:SetPoint("TOPLEFT", timerText, "TOPLEFT", 0, 0)
                timerTooltipFrame:SetPoint("BOTTOMRIGHT", bestText, "BOTTOMRIGHT", 0, 0)
                timerTooltipFrame:EnableMouse(true)
                local tracker = self  -- Capture Tracker reference for tooltip callback
                local savedFonts = {}  -- Store original fonts to restore later

                timerTooltipFrame:SetScript("OnEnter", function(tooltipFrame)
                    if dcState.timerLog and #dcState.timerLog > 0 then
                        GameTooltip:SetOwner(tooltipFrame, "ANCHOR_RIGHT")
                        GameTooltip:ClearLines()

                        GameTooltip:AddLine("Encounter Times", 1, 1, 1)
                        GameTooltip:AddLine(" ", 1, 1, 1)  -- Spacer

                        -- Header row
                        GameTooltip:AddLine("Encounter/Objective:        BEST:   LAST:", 1, 1, 0)
                        GameTooltip:AddLine(" ", 1, 1, 1)  -- Spacer

                        -- Timer log entries
                        for _, entry in ipairs(dcState.timerLog) do
                            local bestTimeStr = entry.bestTime > 0 and tracker:FormatTime(entry.bestTime) or "--:--"
                            local lastTimeStr = entry.lastTime > 0 and tracker:FormatTime(entry.lastTime) or "--:--"

                            -- Format with monospaced alignment: "Boss Name                   01:30  06:13"
                            local formattedLine = string.format("%-28s %s  %s", entry.name, bestTimeStr, lastTimeStr)
                            GameTooltip:AddLine(formattedLine, 1, 1, 1)
                        end

                        -- NOW save original fonts (after content is created, before changing to monospaced)
                        savedFonts = {}  -- Clear any old saved fonts
                        for i = 1, 30 do
                            local leftText = _G["GameTooltipTextLeft" .. i]
                            local rightText = _G["GameTooltipTextRight" .. i]
                            if leftText and leftText:IsShown() then
                                local font, size, outline = leftText:GetFont()
                                savedFonts[i] = {left = {font = font, size = size, outline = outline}}
                            end
                            if rightText and rightText:IsShown() then
                                local font, size, outline = rightText:GetFont()
                                if not savedFonts[i] then savedFonts[i] = {} end
                                savedFonts[i].right = {font = font, size = size, outline = outline}
                            end
                        end

                        -- Now set monospaced font on all created lines
                        local LSM = LibStub("LibSharedMedia-3.0")
                        local monoFont = LSM:Fetch("font", "Source Code Pro Bold")
                        local monoFontSize = 11

                        for i = 1, 30 do
                            local leftText = _G["GameTooltipTextLeft" .. i]
                            local rightText = _G["GameTooltipTextRight" .. i]
                            if leftText and leftText:IsShown() then leftText:SetFont(monoFont, monoFontSize, "OUTLINE") end
                            if rightText and rightText:IsShown() then rightText:SetFont(monoFont, monoFontSize, "OUTLINE") end
                        end

                        GameTooltip:Show()
                    end
                end)
                timerTooltipFrame:SetScript("OnLeave", function(tooltipFrame)
                    GameTooltip:Hide()

                    -- Restore original fonts
                    for i, fontData in pairs(savedFonts) do
                        if fontData.left then
                            local leftText = _G["GameTooltipTextLeft" .. i]
                            if leftText then
                                leftText:SetFont(fontData.left.font, fontData.left.size, fontData.left.outline)
                            end
                        end
                        if fontData.right then
                            local rightText = _G["GameTooltipTextRight" .. i]
                            if rightText then
                                rightText:SetFont(fontData.right.font, fontData.right.size, fontData.right.outline)
                            end
                        end
                    end
                    savedFonts = {}  -- Clear saved fonts
                end)

                table.insert(frame.bossTexts, timerText)
                table.insert(frame.bossTexts, timerSeparator)
                table.insert(frame.bossTexts, bestText)
                table.insert(frame.bossTexts, timerTooltipFrame)
                yOffset = yOffset - timerText:GetStringHeight() - 2
                contentHeight = contentHeight + timerText:GetStringHeight() + 2
            end

            -- Current movement speed line (if enabled)
            if dcConfig.showSpeed then
                -- Use centralized speed data function
                local speedData = KOL:ReturnSpeedData()

                -- SPEED: portion (user font)
                local speedDisplayText = content:CreateFontString(nil, "OVERLAY")
                speedDisplayText:SetFont(objectiveFontPath, scaledObjectiveFontSize, objectiveFontOutline)
                speedDisplayText:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
                speedDisplayText:SetJustifyH("LEFT")
                speedDisplayText:SetText("SPEED: |cFF" .. speedData.color .. speedData.text .. "|r ")

                -- Arrow/lightning indicator (ligatures font for guaranteed glyph rendering)
                -- Glyph is NOT colored - use white/default color
                local speedArrowText = KOL.UIFactory:CreateGlyph(content, speedData.glyph, "FFFFFF", scaledObjectiveFontSize)
                speedArrowText:SetPoint("LEFT", speedDisplayText, "RIGHT", 0, 0)

                -- Create invisible frame for tooltip (spans both text elements)
                local speedTooltipFrame = Tracker:AcquireFrame(content)
                speedTooltipFrame:SetPoint("TOPLEFT", speedDisplayText, "TOPLEFT", 0, 0)
                speedTooltipFrame:SetPoint("BOTTOMRIGHT", speedArrowText, "BOTTOMRIGHT", 0, 0)
                speedTooltipFrame:EnableMouse(true)
                speedTooltipFrame:SetScript("OnEnter", function(tooltipFrame)
                    GameTooltip:SetOwner(tooltipFrame, "ANCHOR_RIGHT")
                    GameTooltip:AddLine("Movement Speed", 1, 1, 1)
                    GameTooltip:AddDoubleLine("Total Speed:", speedData.speedTotal .. "%", 1, 1, 1, 0, 1, 0)
                    GameTooltip:AddDoubleLine("Over Base:", speedData.speedIncrease .. "%", 1, 1, 1, 0, 1, 0)
                    GameTooltip:Show()
                end)
                speedTooltipFrame:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)

                table.insert(frame.bossTexts, speedDisplayText)
                table.insert(frame.bossTexts, speedArrowText)
                table.insert(frame.bossTexts, speedTooltipFrame)
                yOffset = yOffset - speedDisplayText:GetStringHeight() - 4
                contentHeight = contentHeight + speedDisplayText:GetStringHeight() + 4
            end

            -- Add separator line
            yOffset = yOffset - 4
            contentHeight = contentHeight + 4
        end
    end

    -- Render flat bosses (no groups)
    if data.bosses and #data.bosses > 0 then
        for i, boss in ipairs(data.bosses) do
            -- Check if boss is killed
            local killed = self:IsBossKilled(instanceId, i)
            local colorHex = killed and killedColorHex or unkilledColorHex
            local checkMark = killed and CHAR_OBJECTIVE_COMPLETE or CHAR_OBJECTIVE_BOX

            -- Create or reuse a clickable button wrapper for the boss
            local bossBtn = self:AcquireButton(content)
            bossBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
            bossBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, yOffset)
            bossBtn:RegisterForClicks("AnyUp")

            -- Icon - reuse cached or create new
            local bossIcon = bossBtn.cachedIcon
            if not bossIcon then
                bossIcon = KOL.UIFactory:CreateGlyph(bossBtn, checkMark, colorHex, scaledObjectiveFontSize)
                bossBtn.cachedIcon = bossIcon
            else
                bossIcon:Show()
                bossIcon:SetGlyph(checkMark, colorHex)
                bossIcon:SetFont(CHAR_LIGATURESFONT, scaledObjectiveFontSize, CHAR_LIGATURESOUTLINE or "OUTLINE")
            end
            bossIcon:ClearAllPoints()
            bossIcon:SetPoint("LEFT", bossBtn, "LEFT", 4, 0)

            -- Text - reuse cached or create new
            local bossText = bossBtn.cachedText
            if not bossText then
                bossText = bossBtn:CreateFontString(nil, "OVERLAY")
                bossBtn.cachedText = bossText
            else
                bossText:Show()
            end
            bossText:SetFont(objectiveFontPath, scaledObjectiveFontSize, objectiveFontOutline)
            bossText:ClearAllPoints()
            bossText:SetPoint("LEFT", bossIcon, "RIGHT", 2, 0)
            bossText:SetPoint("RIGHT", bossBtn, "RIGHT", -4, 0)
            bossText:SetJustifyH("LEFT")
            bossText:SetWordWrap(true)
            bossText:SetText("|cFF" .. colorHex .. self:GetBossNameWithHardmode(instanceId, i, boss) .. "|r")

            -- Calculate height based on text
            local textHeight = bossText:GetStringHeight()
            bossBtn:SetHeight(textHeight + 2)

            -- Store values for closures (avoid stale captured values)
            local storedBossIndex = i
            local storedBossName = boss.name
            local storedInstanceId = instanceId

            -- Shift+Click to mark/unmark boss as complete, Ctrl+Click to reset
            bossBtn:SetScript("OnClick", function(self)
                if IsControlKeyDown() then
                    -- Reset boss progress/status
                    Tracker:UnmarkBossKilled(storedInstanceId, storedBossIndex)
                    KOL:PrintTag("Reset: " .. storedBossName)
                    Tracker:RefreshAllWatchFrames()
                elseif IsShiftKeyDown() then
                    -- Toggle boss killed status (check current state, not captured value)
                    local isCurrentlyKilled = Tracker:IsBossKilled(storedInstanceId, storedBossIndex)
                    if isCurrentlyKilled then
                        Tracker:UnmarkBossKilled(storedInstanceId, storedBossIndex)
                        KOL:PrintTag("Unmarked: " .. storedBossName)
                    else
                        Tracker:MarkBossKilled(storedInstanceId, storedBossIndex)
                        KOL:PrintTag("Marked complete: " .. storedBossName)
                    end
                    Tracker:RefreshAllWatchFrames()
                end
            end)

            table.insert(frame.bossTexts, bossBtn)

            -- Update yOffset for next boss
            local itemSpacing = 2
            yOffset = yOffset - textHeight - itemSpacing
            contentHeight = contentHeight + textHeight + itemSpacing
        end

    -- Render custom tracker entries (new unified format with groups)
    elseif data.entries and #data.entries > 0 then
        -- Speed display for custom trackers at TOP (if showSpeed is enabled)
        if data.showSpeed then
            -- Use centralized speed data function
            local speedData = KOL:ReturnSpeedData()

            -- SPEED: portion (user font)
            local speedDisplayText = content:CreateFontString(nil, "OVERLAY")
            speedDisplayText:SetFont(objectiveFontPath, scaledObjectiveFontSize, objectiveFontOutline)
            speedDisplayText:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
            speedDisplayText:SetJustifyH("LEFT")
            speedDisplayText:SetText("SPEED: |cFF" .. speedData.color .. speedData.text .. "|r ")

            -- Arrow/lightning indicator (ligatures font for guaranteed glyph rendering)
            -- Glyph is NOT colored - use white/default color
            local speedArrowText = KOL.UIFactory:CreateGlyph(content, speedData.glyph, "FFFFFF", scaledObjectiveFontSize)
            speedArrowText:SetPoint("LEFT", speedDisplayText, "RIGHT", 0, 0)

            -- Create invisible frame for tooltip (spans both text elements)
            local speedTooltipFrame = Tracker:AcquireFrame(content)
            speedTooltipFrame:SetPoint("TOPLEFT", speedDisplayText, "TOPLEFT", 0, 0)
            speedTooltipFrame:SetPoint("BOTTOMRIGHT", speedArrowText, "BOTTOMRIGHT", 0, 0)
            speedTooltipFrame:EnableMouse(true)
            speedTooltipFrame:SetScript("OnEnter", function(tooltipFrame)
                GameTooltip:SetOwner(tooltipFrame, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Movement Speed", 1, 1, 1)
                GameTooltip:AddDoubleLine("Total Speed:", speedData.speedTotal .. "%", 1, 1, 1, 0, 1, 0)
                GameTooltip:AddDoubleLine("Over Base:", speedData.speedIncrease .. "%", 1, 1, 1, 0, 1, 0)
                GameTooltip:Show()
            end)
            speedTooltipFrame:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)

            table.insert(frame.bossTexts, speedDisplayText)
            table.insert(frame.bossTexts, speedArrowText)
            table.insert(frame.bossTexts, speedTooltipFrame)
            yOffset = yOffset - speedDisplayText:GetStringHeight() - 6
            contentHeight = contentHeight + speedDisplayText:GetStringHeight() + 6
        end

        -- Organize entries by group (using data.groups order, not entry order)
        local ungrouped = {}
        local grouped = {}  -- {groupName = {entries}}

        -- Build groupOrder from data.groups (this is the canonical order)
        local groupOrder = {}
        if data.groups then
            for _, g in ipairs(data.groups) do
                table.insert(groupOrder, g.name)
                grouped[g.name] = {}  -- Pre-create empty arrays for all groups
            end
        end

        -- Distribute entries into groups
        for i, entry in ipairs(data.entries) do
            local grp = entry.group or ""
            if grp == "" then
                table.insert(ungrouped, entry)
            elseif grouped[grp] then
                -- Group exists in data.groups
                table.insert(grouped[grp], entry)
            else
                -- Entry references a group that doesn't exist - treat as ungrouped
                table.insert(ungrouped, entry)
            end
        end

        -- Helper function to render a single entry
        local function RenderEntry(entry, indented)
            local indent = indented and 8 or 4

            -- Get count requirement and current progress
            local requiredCount = entry.count or 1
            local entryId = nil

            if entry.type == "kill" and entry.id then
                entryId = "kill-" .. entry.id
            elseif entry.type == "loot" and entry.itemId then
                entryId = "loot-" .. entry.itemId
            elseif entry.type == "yell" and entry.yell then
                entryId = "yell-" .. entry.yell
            elseif entry.type == "multikill" and entry.ids then
                entryId = "multi-" .. table.concat(entry.ids, "-")
            end

            -- Fallback: Generate entryId from entry name if not already set
            -- This ensures ALL entries can be clicked to mark complete
            if not entryId and entry.name then
                entryId = "entry-" .. string.gsub(entry.name, "%s+", "-")
            end

            -- Get current progress for count-based entries
            local currentProgress = 0
            local completed = false

            if entryId then
                currentProgress = self:GetEntryProgress(instanceId, entryId)
                -- Complete if progress >= required OR if manually marked complete
                completed = currentProgress >= requiredCount or self:IsBossKilled(instanceId, entryId)
            elseif entry.condition and type(entry.condition) == "function" then
                local success, result = pcall(entry.condition)
                completed = success and result
            end

            local colorHex = completed and killedColorHex or unkilledColorHex
            local checkMark = completed and CHAR_OBJECTIVE_COMPLETE or CHAR_OBJECTIVE_BOX

            -- Create or reuse clickable button for the entry
            local entryBtn = Tracker:AcquireButton(content)
            entryBtn:SetPoint("TOPLEFT", content, "TOPLEFT", indent, yOffset)
            entryBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, yOffset)
            entryBtn:RegisterForClicks("AnyUp")

            -- Icon - reuse cached or create new
            local entryIcon = entryBtn.cachedIcon
            if not entryIcon then
                entryIcon = KOL.UIFactory:CreateGlyph(entryBtn, checkMark, colorHex, scaledObjectiveFontSize)
                entryBtn.cachedIcon = entryIcon
            else
                entryIcon:Show()
                entryIcon:SetGlyph(checkMark, colorHex)
                entryIcon:SetFont(CHAR_LIGATURESFONT, scaledObjectiveFontSize, CHAR_LIGATURESOUTLINE or "OUTLINE")
            end
            entryIcon:ClearAllPoints()
            entryIcon:SetPoint("LEFT", entryBtn, "LEFT", 0, 0)

            -- Text - ONLY show name, no note
            -- Add prefix if showPrefix is enabled
            local prefix = ""
            if data.showPrefix then
                local entryType = entry.type or "kill"
                if entryType == "kill" then
                    prefix = "|cFF00FF00*|r"
                elseif entryType == "loot" then
                    prefix = "|cFFFFD700$|r"
                elseif entryType == "yell" then
                    prefix = "|cFF00BFFF!|r"
                elseif entryType == "multikill" then
                    prefix = "|cFFFF6600#|r"
                end
            end

            -- Add progress [X/Y] for ALL entries (always show count)
            local displayText = (prefix ~= "" and prefix .. " " or "") .. (entry.name or "Unnamed Entry")

            -- Calculate progress percentage for gradient
            local progressPct = currentProgress / requiredCount
            if progressPct > 1 then progressPct = 1 end

            -- Gradient from red (0%) -> yellow (50%) -> green (100%)
            local r, g, b
            if completed then
                -- Completed: bright green
                r, g, b = 0.4, 1.0, 0.4
            elseif progressPct <= 0.5 then
                -- Red to Yellow (0% to 50%)
                local t = progressPct * 2  -- 0 to 1
                r = 1.0
                g = t
                b = 0.2
            else
                -- Yellow to Green (50% to 100%)
                local t = (progressPct - 0.5) * 2  -- 0 to 1
                r = 1.0 - t * 0.6
                g = 1.0
                b = 0.2 + t * 0.2
            end

            -- Convert to hex
            local progressHex = string.format("%02X%02X%02X", r * 255, g * 255, b * 255)

            -- Format: name [current/required] with gradient on numbers only
            -- Brackets and slash in subtle gray, numbers in gradient
            local bracketColor = "888888"
            displayText = displayText .. " |cFF" .. bracketColor .. "[|r|cFF" .. progressHex .. currentProgress .. "|r|cFF" .. bracketColor .. "/|r|cFF" .. progressHex .. requiredCount .. "|r|cFF" .. bracketColor .. "]|r"

            -- Text - reuse cached or create new
            local entryText = entryBtn.cachedText
            if not entryText then
                entryText = entryBtn:CreateFontString(nil, "OVERLAY")
                entryBtn.cachedText = entryText
            else
                entryText:Show()
            end
            entryText:SetFont(objectiveFontPath, scaledObjectiveFontSize, objectiveFontOutline)
            entryText:ClearAllPoints()
            entryText:SetPoint("LEFT", entryIcon, "RIGHT", 2, 0)
            entryText:SetPoint("RIGHT", entryBtn, "RIGHT", -4, 0)
            entryText:SetJustifyH("LEFT")
            entryText:SetWordWrap(true)
            entryText:SetText("|cFF" .. colorHex .. displayText .. "|r")

            -- Calculate button height based on text
            local textHeight = entryText:GetStringHeight()
            entryBtn:SetHeight(textHeight + 2)

            -- Store values for closures
            local storedEntryId = entryId
            local storedCompleted = completed
            local storedRequiredCount = requiredCount
            local storedCurrentProgress = currentProgress
            local storedInstanceId = instanceId

            -- Store entry's group for auto-collapse
            local storedEntryGroup = entry.group

            -- Shift+Click to mark/unmark as complete, Ctrl+Click to reset progress
            entryBtn:SetScript("OnClick", function(self)
                if storedEntryId then
                    if IsControlKeyDown() then
                        -- Reset progress to 0
                        Tracker:ResetEntryProgress(storedInstanceId, storedEntryId)
                        Tracker:UnmarkBossKilled(storedInstanceId, storedEntryId)
                        KOL:PrintTag("Reset progress: " .. (entry.name or "Entry"))
                        Tracker:RefreshAllWatchFrames()
                    elseif IsShiftKeyDown() then
                        if storedCompleted then
                            Tracker:UnmarkBossKilled(storedInstanceId, storedEntryId)
                            -- Also reset progress when unmarking
                            Tracker:ResetEntryProgress(storedInstanceId, storedEntryId)
                            KOL:PrintTag("Unmarked: " .. (entry.name or "Entry"))
                        else
                            -- Mark complete and set progress to required count
                            Tracker:SetEntryProgress(storedInstanceId, storedEntryId, storedRequiredCount)
                            Tracker:MarkBossKilled(storedInstanceId, storedEntryId)
                            KOL:PrintTag("Marked complete: " .. (entry.name or "Entry"))

                            -- Auto-collapse group if all entries complete and auto-collapse is enabled
                            local autoCollapseEnabled = KOL.db.profile.tracker.customAutoCollapse
                            if autoCollapseEnabled == nil then autoCollapseEnabled = true end  -- Default enabled

                            if storedEntryGroup and storedEntryGroup ~= "" and autoCollapseEnabled then
                                -- Check if all entries in this group are now complete
                                local allComplete = true
                                local groupIndex = nil

                                -- Find group index for collapse state
                                if data.groups then
                                    for gi, g in ipairs(data.groups) do
                                        if g.name == storedEntryGroup then
                                            groupIndex = gi
                                            break
                                        end
                                    end
                                end

                                -- Check all entries in this group
                                if data.entries then
                                    for _, e in ipairs(data.entries) do
                                        if e.group == storedEntryGroup then
                                            local eId = nil
                                            if e.type == "kill" and e.id then
                                                eId = "kill-" .. e.id
                                            elseif e.type == "loot" and e.itemId then
                                                eId = "loot-" .. e.itemId
                                            elseif e.type == "yell" and e.yell then
                                                eId = "yell-" .. e.yell
                                            elseif e.type == "multikill" and e.ids then
                                                eId = "multi-" .. table.concat(e.ids, "-")
                                            elseif e.name then
                                                eId = "entry-" .. string.gsub(e.name, "%s+", "-")
                                            end

                                            if eId then
                                                local eCount = e.count or 1
                                                local eProgress = Tracker:GetEntryProgress(storedInstanceId, eId)
                                                local eComplete = eProgress >= eCount or Tracker:IsBossKilled(storedInstanceId, eId)
                                                if not eComplete then
                                                    allComplete = false
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end

                                -- Auto-collapse if all entries in group are complete
                                if allComplete and groupIndex then
                                    if not KOL.db.profile.tracker.collapsedGroups then
                                        KOL.db.profile.tracker.collapsedGroups = {}
                                    end
                                    if not KOL.db.profile.tracker.collapsedGroups[storedInstanceId] then
                                        KOL.db.profile.tracker.collapsedGroups[storedInstanceId] = {}
                                    end
                                    KOL.db.profile.tracker.collapsedGroups[storedInstanceId][groupIndex] = true
                                    KOL:DebugPrint("Tracker: Auto-collapsed completed group '" .. storedEntryGroup .. "' in " .. storedInstanceId, 2)
                                end
                            end
                        end
                        Tracker:RefreshAllWatchFrames()
                    end
                end
            end)

            -- Hover tooltip - show note and progress here
            entryBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(entry.name or "Entry", 1, 1, 1)
                if entry.note and entry.note ~= "" then
                    GameTooltip:AddLine(entry.note, 0.7, 0.85, 0.7)
                end
                -- Show progress info
                if storedRequiredCount > 1 then
                    local progressText = "Progress: " .. storedCurrentProgress .. "/" .. storedRequiredCount
                    if storedCompleted then
                        progressText = progressText .. " (Complete!)"
                    end
                    GameTooltip:AddLine(progressText, 0.5, 0.8, 1)
                end
                if storedEntryId then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Shift+Click to toggle completion", 0.5, 0.5, 0.5)
                    GameTooltip:AddLine("Ctrl+Click to reset progress", 0.5, 0.5, 0.5)
                end
                GameTooltip:Show()
            end)
            entryBtn:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)

            table.insert(frame.bossTexts, entryBtn)

            -- Update yOffset
            local itemSpacing = 1
            yOffset = yOffset - textHeight - itemSpacing
            contentHeight = contentHeight + textHeight + itemSpacing
        end

        -- Render ungrouped entries first (if any)
        if #ungrouped > 0 then
            for _, entry in ipairs(ungrouped) do
                RenderEntry(entry, false)
            end
            -- Small gap after ungrouped
            if #groupOrder > 0 then
                yOffset = yOffset - 4
                contentHeight = contentHeight + 4
            end
        end

        -- Render each group with header
        for groupIdx, groupName in ipairs(groupOrder) do
            local entries = grouped[groupName]

            -- Check if all entries in group are completed
            local allCompleted = true
            for _, entry in ipairs(entries) do
                local entryId = nil
                if entry.type == "kill" and entry.id then
                    entryId = "kill-" .. entry.id
                elseif entry.type == "loot" and entry.itemId then
                    entryId = "loot-" .. entry.itemId
                elseif entry.type == "yell" and entry.yell then
                    entryId = "yell-" .. entry.yell
                elseif entry.type == "multikill" and entry.ids then
                    entryId = "multi-" .. table.concat(entry.ids, "-")
                end
                if entryId and not self:IsBossKilled(instanceId, entryId) then
                    allCompleted = false
                    break
                end
            end

            -- Use configured group colors (complete/incomplete)
            local groupHeaderColor = allCompleted and groupCompleteColor or groupIncompleteColor
            local groupHeaderColorHex = KOL.Colors:ToHex(groupHeaderColor)

            -- Check collapsed state
            local isCollapsed = self:IsGroupCollapsed(instanceId, groupIdx)
            local collapseIcon = isCollapsed and CHAR_ARROW_RIGHTFILLED or CHAR_ARROW_DOWNFILLED

            -- Group header (clickable button for collapse/expand)
            local groupHeaderBtn = Tracker:AcquireButton(content)
            groupHeaderBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 2, yOffset)
            groupHeaderBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", -2, yOffset)
            groupHeaderBtn:SetHeight(scaledGroupFontSize + 4)
            groupHeaderBtn:RegisterForClicks("AnyUp")

            -- Icon - reuse cached or create new (stored as .icon for compatibility)
            local groupIcon = groupHeaderBtn.cachedIcon
            if not groupIcon then
                groupIcon = KOL.UIFactory:CreateGlyph(groupHeaderBtn, collapseIcon, groupHeaderColorHex, scaledGroupFontSize)
                groupHeaderBtn.cachedIcon = groupIcon
            else
                groupIcon:Show()
                groupIcon:SetGlyph(collapseIcon, groupHeaderColorHex)
                groupIcon:SetFont(CHAR_LIGATURESFONT, scaledGroupFontSize, CHAR_LIGATURESOUTLINE or "OUTLINE")
            end
            groupIcon:ClearAllPoints()
            groupIcon:SetPoint("LEFT", groupHeaderBtn, "LEFT", 0, 0)
            groupHeaderBtn.icon = groupIcon

            -- Text - reuse cached or create new (stored as .text for compatibility)
            local groupHeader = groupHeaderBtn.cachedText
            if not groupHeader then
                groupHeader = groupHeaderBtn:CreateFontString(nil, "OVERLAY")
                groupHeaderBtn.cachedText = groupHeader
            else
                groupHeader:Show()
            end
            groupHeader:SetFont(groupFontPath, scaledGroupFontSize, groupFontOutline)
            groupHeader:ClearAllPoints()
            groupHeader:SetPoint("LEFT", groupIcon, "RIGHT", 4, 0)
            groupHeader:SetJustifyH("LEFT")
            groupHeader:SetText("|cFF" .. groupHeaderColorHex .. "[" .. groupName .. "]|r")
            groupHeaderBtn.text = groupHeader
            groupHeaderBtn.groupHeaderColorHex = groupHeaderColorHex
            groupHeaderBtn.groupName = groupName

            -- Single click to toggle collapse
            groupHeaderBtn.groupIndex = groupIdx
            groupHeaderBtn:SetScript("OnClick", function(self, button)
                if button == "LeftButton" then
                    Tracker:ToggleGroupCollapsed(instanceId, self.groupIndex)
                end
            end)

            -- Mouseover highlight - change color on hover, no extra glyph
            groupHeaderBtn:SetScript("OnEnter", function(self)
                local currentIcon = Tracker:IsGroupCollapsed(instanceId, groupIdx) and CHAR_ARROW_RIGHTFILLED or CHAR_ARROW_DOWNFILLED
                self.icon:SetGlyph(currentIcon, "FFFFFF")  -- White on hover
                self.text:SetText("|cFFFFFFFF[" .. self.groupName .. "]|r")
            end)
            groupHeaderBtn:SetScript("OnLeave", function(self)
                local currentIcon = Tracker:IsGroupCollapsed(instanceId, groupIdx) and CHAR_ARROW_RIGHTFILLED or CHAR_ARROW_DOWNFILLED
                self.icon:SetGlyph(currentIcon, self.groupHeaderColorHex)
                self.text:SetText("|cFF" .. self.groupHeaderColorHex .. "[" .. self.groupName .. "]|r")
            end)

            table.insert(frame.bossTexts, groupHeaderBtn)

            local headerHeight = groupHeader:GetStringHeight() + 4
            yOffset = yOffset - headerHeight - 1
            contentHeight = contentHeight + headerHeight + 1

            -- Group entries (only render if not collapsed)
            if not isCollapsed then
                for _, entry in ipairs(entries) do
                    RenderEntry(entry, true)  -- Indented
                end
            end

            -- Add spacing after group (unless it's the last group)
            if groupIdx < #groupOrder then
                yOffset = yOffset - 4
                contentHeight = contentHeight + 4
            end
        end

    -- Render grouped bosses (OLD format with group.bosses - for raids/dungeons)
    elseif data.groups and #data.groups > 0 and data.groups[1].bosses then
        for groupIndex, group in ipairs(data.groups) do
            -- Check if group is collapsed
            local isCollapsed = self:IsGroupCollapsed(instanceId, groupIndex)
            local collapseIcon = isCollapsed and CHAR_ARROW_RIGHTFILLED or CHAR_ARROW_DOWNFILLED

            -- Check if all bosses in this group are killed
            local allGroupBossesKilled = true
            if group.bosses then
                for bossIndex, boss in ipairs(group.bosses) do
                    local bossId = "g" .. groupIndex .. "-b" .. bossIndex
                    if not self:IsBossKilled(instanceId, bossId) then
                        allGroupBossesKilled = false
                        break
                    end
                end
            else
                allGroupBossesKilled = false
            end

            -- Use configured group colors (complete/incomplete)
            local groupHeaderColor = allGroupBossesKilled and groupCompleteColor or groupIncompleteColor
            local groupHeaderColorHex = KOL.Colors:ToHex(groupHeaderColor)

            -- Group header (clickable button for collapse/expand)
            local groupHeaderBtn = Tracker:AcquireButton(content)
            groupHeaderBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 2, yOffset)
            groupHeaderBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", -2, yOffset)
            groupHeaderBtn:SetHeight(scaledGroupFontSize + 4)
            groupHeaderBtn:RegisterForClicks("AnyUp")

            -- Icon - reuse cached or create new
            local groupIcon = groupHeaderBtn.cachedIcon
            if not groupIcon then
                groupIcon = KOL.UIFactory:CreateGlyph(groupHeaderBtn, collapseIcon, groupHeaderColorHex, scaledGroupFontSize)
                groupHeaderBtn.cachedIcon = groupIcon
            else
                groupIcon:Show()
                groupIcon:SetGlyph(collapseIcon, groupHeaderColorHex)
                groupIcon:SetFont(CHAR_LIGATURESFONT, scaledGroupFontSize, CHAR_LIGATURESOUTLINE or "OUTLINE")
            end
            groupIcon:ClearAllPoints()
            groupIcon:SetPoint("LEFT", groupHeaderBtn, "LEFT", 0, 0)
            groupHeaderBtn.icon = groupIcon

            -- Text - reuse cached or create new
            local groupHeader = groupHeaderBtn.cachedText
            if not groupHeader then
                groupHeader = groupHeaderBtn:CreateFontString(nil, "OVERLAY")
                groupHeaderBtn.cachedText = groupHeader
            else
                groupHeader:Show()
            end
            groupHeader:SetFont(groupFontPath, scaledGroupFontSize, groupFontOutline)
            groupHeader:ClearAllPoints()
            groupHeader:SetPoint("LEFT", groupIcon, "RIGHT", 4, 0)
            groupHeader:SetJustifyH("LEFT")
            groupHeader:SetText("|cFF" .. groupHeaderColorHex .. "[" .. group.name .. "]|r")
            groupHeaderBtn.text = groupHeader
            groupHeaderBtn.groupHeaderColorHex = groupHeaderColorHex  -- Store for mouseover

            -- Single click to toggle collapse
            groupHeaderBtn.groupIndex = groupIndex
            groupHeaderBtn:SetScript("OnClick", function(self, button)
                if button == "LeftButton" then
                    Tracker:ToggleGroupCollapsed(instanceId, self.groupIndex)
                end
            end)

            -- Mouseover highlight - change color on hover, no extra glyph
            groupHeaderBtn:SetScript("OnEnter", function(self)
                local currentIcon = Tracker:IsGroupCollapsed(instanceId, groupIndex) and CHAR_ARROW_RIGHTFILLED or CHAR_ARROW_DOWNFILLED
                self.icon:SetGlyph(currentIcon, "FFFFFF")  -- White on hover
                self.text:SetText("|cFFFFFFFF[" .. group.name .. "]|r")
            end)
            groupHeaderBtn:SetScript("OnLeave", function(self)
                local currentIcon = Tracker:IsGroupCollapsed(instanceId, groupIndex) and CHAR_ARROW_RIGHTFILLED or CHAR_ARROW_DOWNFILLED
                self.icon:SetGlyph(currentIcon, self.groupHeaderColorHex)
                self.text:SetText("|cFF" .. self.groupHeaderColorHex .. "[" .. group.name .. "]|r")
            end)

            table.insert(frame.bossTexts, groupHeaderBtn)

            local headerHeight = groupHeader:GetStringHeight() + 4
            yOffset = yOffset - headerHeight - 1
            contentHeight = contentHeight + headerHeight + 1

            -- Group bosses (only render if not collapsed)
            if group.bosses and not isCollapsed then
                for bossIndex, boss in ipairs(group.bosses) do
                    -- Check if boss is killed (using group-boss ID format)
                    local bossId = "g" .. groupIndex .. "-b" .. bossIndex
                    local killed = self:IsBossKilled(instanceId, bossId)
                    local colorHex = killed and killedColorHex or unkilledColorHex
                    local checkMark = killed and CHAR_OBJECTIVE_COMPLETE or CHAR_OBJECTIVE_BOX

                    -- Create or reuse a clickable button wrapper for the boss
                    local bossBtn = Tracker:AcquireButton(content)
                    bossBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 8, yOffset)  -- Indent bosses
                    bossBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, yOffset)
                    bossBtn:RegisterForClicks("AnyUp")

                    -- Icon - reuse cached or create new
                    local bossIcon = bossBtn.cachedIcon
                    if not bossIcon then
                        bossIcon = KOL.UIFactory:CreateGlyph(bossBtn, checkMark, colorHex, scaledObjectiveFontSize)
                        bossBtn.cachedIcon = bossIcon
                    else
                        bossIcon:Show()
                        bossIcon:SetGlyph(checkMark, colorHex)
                        bossIcon:SetFont(CHAR_LIGATURESFONT, scaledObjectiveFontSize, CHAR_LIGATURESOUTLINE or "OUTLINE")
                    end
                    bossIcon:ClearAllPoints()
                    bossIcon:SetPoint("LEFT", bossBtn, "LEFT", 0, 0)

                    -- Text - reuse cached or create new
                    local bossText = bossBtn.cachedText
                    if not bossText then
                        bossText = bossBtn:CreateFontString(nil, "OVERLAY")
                        bossBtn.cachedText = bossText
                    else
                        bossText:Show()
                    end
                    bossText:SetFont(objectiveFontPath, scaledObjectiveFontSize, objectiveFontOutline)
                    bossText:ClearAllPoints()
                    bossText:SetPoint("LEFT", bossIcon, "RIGHT", 2, 0)
                    bossText:SetPoint("RIGHT", bossBtn, "RIGHT", -4, 0)
                    bossText:SetJustifyH("LEFT")
                    bossText:SetWordWrap(true)
                    bossText:SetText("|cFF" .. colorHex .. self:GetBossNameWithHardmode(instanceId, bossId, boss) .. "|r")

                    -- Calculate height based on text
                    local textHeight = bossText:GetStringHeight()
                    bossBtn:SetHeight(textHeight + 2)

                    -- Store values for closures (avoid stale captured values)
                    local storedBossId = bossId
                    local storedBossName = boss.name
                    local storedInstanceId = instanceId

                    -- Shift+Click to mark/unmark boss as complete, Ctrl+Click to reset
                    bossBtn:SetScript("OnClick", function(self)
                        if IsControlKeyDown() then
                            -- Reset boss progress/status
                            Tracker:UnmarkBossKilled(storedInstanceId, storedBossId)
                            KOL:PrintTag("Reset: " .. storedBossName)
                            Tracker:RefreshAllWatchFrames()
                        elseif IsShiftKeyDown() then
                            -- Toggle boss killed status (check current state, not captured value)
                            local isCurrentlyKilled = Tracker:IsBossKilled(storedInstanceId, storedBossId)
                            if isCurrentlyKilled then
                                Tracker:UnmarkBossKilled(storedInstanceId, storedBossId)
                                KOL:PrintTag("Unmarked: " .. storedBossName)
                            else
                                Tracker:MarkBossKilled(storedInstanceId, storedBossId)
                                KOL:PrintTag("Marked complete: " .. storedBossName)
                            end
                            Tracker:RefreshAllWatchFrames()
                        end
                    end)

                    table.insert(frame.bossTexts, bossBtn)

                    -- Update yOffset for next boss
                    local itemSpacing = 1
                    yOffset = yOffset - textHeight - itemSpacing
                    contentHeight = contentHeight + textHeight + itemSpacing
                end
            end

            -- Add spacing after group (unless it's the last group)
            if groupIndex < #data.groups then
                yOffset = yOffset - 4
                contentHeight = contentHeight + 4
            end
        end

    -- Render custom panel objectives
    elseif data.objectives and #data.objectives > 0 then
        -- Custom panel objectives
        for i, objective in ipairs(data.objectives) do
            -- Check objective condition (if function provided)
            local completed = false
            if objective.condition and type(objective.condition) == "function" then
                local success, result = pcall(objective.condition)
                completed = success and result
            end

            local colorHex = completed and killedColorHex or unkilledColorHex
            local checkMark = completed and CHAR_OBJECTIVE_COMPLETE or CHAR_OBJECTIVE_BOX

            -- Icon (using ligatures font for proper Unicode rendering)
            local objIcon = KOL.UIFactory:CreateGlyph(content, checkMark, colorHex, scaledObjectiveFontSize)
            objIcon:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)

            -- Text (using configured objective font)
            local objText = content:CreateFontString(nil, "OVERLAY")
            objText:SetFont(objectiveFontPath, scaledObjectiveFontSize, objectiveFontOutline)
            objText:SetPoint("LEFT", objIcon, "RIGHT", 2, 0)
            objText:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, yOffset)
            objText:SetJustifyH("LEFT")
            objText:SetWordWrap(true)
            objText:SetText("|cFF" .. colorHex .. objective.name .. "|r")

            table.insert(frame.bossTexts, objIcon)
            table.insert(frame.bossTexts, objText)

            -- Update yOffset for next objective
            local textHeight = objText:GetStringHeight()
            local itemSpacing = 2
            yOffset = yOffset - textHeight - itemSpacing
            contentHeight = contentHeight + textHeight + itemSpacing
        end

    else
        -- No bosses or objectives
        local noDataText = content:CreateFontString(nil, "OVERLAY")
        noDataText:SetFont(objectiveFontPath, scaledObjectiveFontSize, objectiveFontOutline)
        noDataText:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
        noDataText:SetText("|cFFAAAAAANo objectives defined|r")
        table.insert(frame.bossTexts, noDataText)
        contentHeight = 20
    end

    -- Auto-expand frame width if content is too wide (for dungeon challenge timers, etc.)
    local maxContentWidth = 0
    for _, element in ipairs(frame.bossTexts) do
        if element and element.GetStringWidth then
            local elementWidth = element:GetStringWidth()
            if elementWidth > maxContentWidth then
                maxContentWidth = elementWidth
            end
        end
    end

    -- If content is wider than available space, expand the frame
    if maxContentWidth > 0 then
        local scrollBarWidth = GetInstanceSetting(instanceId, "scrollBarWidth") or config.scrollBarWidth or 16
        -- Use custom tracker setting for custom trackers, otherwise use global setting
        local showScrollBarConfig
        local isCustomTracker = data.type ~= "dungeon" and data.type ~= "raid"
        if isCustomTracker and KOL.db.profile.tracker.customShowScrollBar ~= nil then
            showScrollBarConfig = KOL.db.profile.tracker.customShowScrollBar
        else
            showScrollBarConfig = KOL.db.profile.tracker.showScrollBar
        end
        if showScrollBarConfig == nil then
            showScrollBarConfig = false
        end
        local scrollBarPadding = showScrollBarConfig and (scrollBarWidth + 8) or 4
        local leftPadding = 8  -- Icon + spacing
        local rightPadding = 8
        local requiredFrameWidth = maxContentWidth + leftPadding + rightPadding + scrollBarPadding
        local currentFrameWidth = frame:GetWidth()

        if requiredFrameWidth > currentFrameWidth then
            frame:SetWidth(requiredFrameWidth)
            content:SetWidth(requiredFrameWidth - scrollBarPadding - 8)
            KOL:DebugPrint(string.format("Tracker: Auto-expanded frame width from %d to %d for content",
                currentFrameWidth, requiredFrameWidth), 3)
        end
    end

    -- Update content size (add 8px bottom buffer to prevent descender cutoff - g, j, y, p, q)
    content:SetHeight(math.max(contentHeight + 8, 1))

    -- Dynamically resize frame to fit content (no max, auto-size only)
    local titleBarHeight = 28  -- Title bar + top border
    local bottomBorderPadding = 8  -- Bottom padding to prevent descender cutoff and scrollbar clipping
    local minFrameHeight = 60  -- Minimum frame height to prevent issues
    local actualFrameHeight = math.max(minFrameHeight, contentHeight + titleBarHeight + bottomBorderPadding)

    -- Only resize if not minimized
    if not frame.minimized then
        frame:SetHeight(actualFrameHeight)
        frame.maxHeight = actualFrameHeight  -- Store current height for minimize/restore
    end

    -- Force scrollbar visibility update (manually trigger the scrollbar logic)
    -- This ensures visibility respects config changes even when scroll range doesn't change
    local scrollFrame = frame.scrollFrame
    local scrollBar = frame.scrollBar
    if scrollFrame and scrollBar then
        local scrollRange = scrollFrame:GetVerticalScrollRange() or 0

        -- Get current visibility config
        -- Use custom tracker setting for custom trackers, otherwise use global setting
        local showScrollBarConfig
        local isCustomTracker = data.type ~= "dungeon" and data.type ~= "raid"
        if isCustomTracker and KOL.db.profile.tracker.customShowScrollBar ~= nil then
            showScrollBarConfig = KOL.db.profile.tracker.customShowScrollBar
        else
            showScrollBarConfig = KOL.db.profile.tracker.showScrollBar
        end
        if showScrollBarConfig == nil then
            showScrollBarConfig = false  -- Default to hidden
        end

        -- Update scrollbar visibility based on config
        local scrollBarActuallyVisible = false
        if scrollRange > 2 and showScrollBarConfig then
            scrollBar:SetMinMaxValues(0, scrollRange)
            scrollBar:Show()
            if frame.scrollUpBtn then frame.scrollUpBtn:Show() end
            if frame.scrollDownBtn then frame.scrollDownBtn:Show() end
            scrollBarActuallyVisible = true
        else
            scrollBar:SetMinMaxValues(0, 0)
            scrollBar:SetValue(0)
            scrollBar:Hide()
            if frame.scrollUpBtn then frame.scrollUpBtn:Hide() end
            if frame.scrollDownBtn then frame.scrollDownBtn:Hide() end
            scrollBarActuallyVisible = false
        end

        -- Adjust scrollFrame width based on actual scrollbar visibility
        local scrollBarWidth = GetInstanceSetting(instanceId, "scrollBarWidth") or config.scrollBarWidth or 16
        local scrollBarPadding = scrollBarActuallyVisible and (scrollBarWidth + 8) or 4
        scrollFrame:ClearAllPoints()
        scrollFrame:SetPoint("TOPLEFT", frame.titleBar, "BOTTOMLEFT", 4, -4)
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -scrollBarPadding, 4)
    end

    KOL:DebugPrint("Tracker: Updated watch frame: " .. instanceId .. " (content: " .. contentHeight .. ", frame: " .. actualFrameHeight .. ")", 3)
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

    -- Initialize dungeon challenge timer when entering zone
    if not self.dungeonChallengeState[instanceId] then
        self.dungeonChallengeState[instanceId] = {}
    end
    if not self.dungeonChallengeState[instanceId].startTime then
        -- Load saved time from database (for /rl persistence)
        local savedTime = 0
        if KOL.db.profile.tracker.dungeonChallenge and KOL.db.profile.tracker.dungeonChallenge.currentTimes then
            savedTime = KOL.db.profile.tracker.dungeonChallenge.currentTimes[instanceId] or 0
        end

        self.dungeonChallengeState[instanceId].startTime = GetTime()
        self.dungeonChallengeState[instanceId].timeElapsedOffset = savedTime
        KOL:DebugPrint("Tracker: Started dungeon timer for " .. instanceId .. " (offset: " .. savedTime .. "s)", 2)
    end

    -- Initialize timer log for all zones (if dungeon challenge is enabled)
    local instanceData = self.instances[instanceId]
    if instanceData then
        self:AddTimerLogEntry(instanceId)
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

-- Hide watch frame for an instance (without destroying it)
function Tracker:HideWatchFrame(instanceId)
    KOL:DebugPrint("Tracker: HideWatchFrame called for: " .. instanceId, 2)

    local frame = self.activeFrames[instanceId]
    if not frame then
        KOL:DebugPrint("Tracker: No active frame to hide for: " .. instanceId, 2)
        return
    end

    -- Just hide the frame (don't destroy it)
    frame:Hide()

    KOL:DebugPrint("Tracker: Watch frame hidden: " .. instanceId, 2)
end

-- Refresh all active watch frames (useful when config changes like fontScale)
function Tracker:RefreshAllWatchFrames()
    KOL:DebugPrint("Tracker: Refreshing all active watch frames", 2)

    for instanceId, frame in pairs(self.activeFrames) do
        if frame and frame:IsShown() then
            KOL:DebugPrint("Tracker: Refreshing frame for: " .. instanceId, 3)
            -- Re-apply position (handles growUpward changes for default-positioned frames)
            self:RestoreFramePosition(instanceId)
            self:UpdateWatchFrame(instanceId)
        end
    end

    KOL:DebugPrint("Tracker: All watch frames refreshed", 2)
end

-- Refresh UI visibility on all active frames (for when Show BG on Mouseover setting changes)
function Tracker:RefreshUIVisibility()
    KOL:DebugPrint("Tracker: Refreshing UI visibility on all active watch frames", 2)

    for instanceId, frame in pairs(self.activeFrames) do
        if frame and frame:IsShown() and frame.UpdateUIVisibility then
            -- Call UpdateUIVisibility with current mouse state
            local isMouseOver = MouseIsOver(frame)
            frame.UpdateUIVisibility(isMouseOver)
            KOL:DebugPrint("Tracker: Refreshed UI visibility for: " .. instanceId .. " (mouseOver=" .. tostring(isMouseOver) .. ")", 3)
        end
    end

    KOL:DebugPrint("Tracker: UI visibility refresh complete", 2)
end

-- Toggle minimize/maximize
function Tracker:ToggleMinimize(frame)
    if not frame then return end

    if frame.minimized then
        -- Maximize
        frame:SetHeight(frame.maxHeight or 300)
        frame.scrollFrame:Show()

        -- Only show scrollbar if config allows AND content requires it
        -- Use custom tracker setting for custom trackers, otherwise use global setting
        local showScrollBarConfig
        local instanceData = frame.instanceId and self.instances[frame.instanceId]
        local isCustomTracker = instanceData and (instanceData.type ~= "dungeon" and instanceData.type ~= "raid")
        if isCustomTracker and KOL.db.profile.tracker.customShowScrollBar ~= nil then
            showScrollBarConfig = KOL.db.profile.tracker.customShowScrollBar
        else
            showScrollBarConfig = KOL.db.profile.tracker.showScrollBar
        end
        if showScrollBarConfig == nil then showScrollBarConfig = false end  -- Default hidden

        if showScrollBarConfig then
            -- Check if scrollbar is actually needed (content exceeds visible area)
            local scrollRange = frame.scrollFrame:GetVerticalScrollRange() or 0
            if scrollRange > 2 and frame.scrollBar then
                frame.scrollBar:Show()
                if frame.scrollUpBtn then frame.scrollUpBtn:Show() end
                if frame.scrollDownBtn then frame.scrollDownBtn:Show() end
            else
                if frame.scrollBar then frame.scrollBar:Hide() end
                if frame.scrollUpBtn then frame.scrollUpBtn:Hide() end
                if frame.scrollDownBtn then frame.scrollDownBtn:Hide() end
            end
        else
            -- Scrollbar disabled in config, keep it hidden
            if frame.scrollBar then frame.scrollBar:Hide() end
            if frame.scrollUpBtn then frame.scrollUpBtn:Hide() end
            if frame.scrollDownBtn then frame.scrollDownBtn:Hide() end
        end

        if frame.minimizeBtn and frame.minimizeBtn.text then
            frame.minimizeBtn.text:SetText(CHAR_UI_MINIMIZE)
        end
        frame.minimized = false
        KOL:DebugPrint("Tracker: Maximized watch frame: " .. frame.instanceId, 3)
    else
        -- Minimize - set height to just titlebar + borders (titlebar is 20px, borders are 2px total)
        frame:SetHeight(22)
        frame.scrollFrame:Hide()
        if frame.scrollBar then frame.scrollBar:Hide() end
        if frame.scrollUpBtn then frame.scrollUpBtn:Hide() end
        if frame.scrollDownBtn then frame.scrollDownBtn:Hide() end
        if frame.minimizeBtn and frame.minimizeBtn.text then
            frame.minimizeBtn.text:SetText(CHAR_UI_MAXIMIZE)
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
        hasCustomPosition = true,  -- Mark that user manually positioned this frame
    }

    KOL:DebugPrint("Tracker: Saved position for: " .. instanceId, 3)
end

-- Restore frame position
function Tracker:RestoreFramePosition(instanceId)
    local frame = self.activeFrames[instanceId]
    if not frame then return end

    local config = KOL.db.profile.tracker
    local pos = config.framePositions and config.framePositions[instanceId]

    if pos and pos.point then
        -- Position exists - restore it (backwards compatible with saves before hasCustomPosition flag)
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
        KOL:DebugPrint("Tracker: Restored saved position for: " .. instanceId, 3)
    elseif config.defaultFrameX and config.defaultFrameY then
        -- Use default frame location if set (for frames that have never been positioned)
        frame:ClearAllPoints()
        local anchorPoint = config.growUpward and "BOTTOMLEFT" or "TOPLEFT"
        frame:SetPoint(anchorPoint, UIParent, "BOTTOMLEFT", config.defaultFrameX, config.defaultFrameY)
        KOL:DebugPrint("Tracker: Using default location for: " .. instanceId, 3)
    else
        -- Fallback: center of screen
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        KOL:DebugPrint("Tracker: Using center position for: " .. instanceId, 3)
    end
end

-- Show draggable frame picker for setting default frame location
function Tracker:ShowDefaultLocationPicker()
    -- Hide existing picker if any
    if self.defaultLocationPickerFrame then
        self.defaultLocationPickerFrame:Hide()
        self.defaultLocationPickerFrame = nil
    end

    local config = KOL.db.profile.tracker

    -- Create picker frame
    local frame = CreateFrame("Frame", "KOLDefaultLocationPicker", UIParent)
    frame:SetSize(200, 150)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)

    -- Position at current default or center
    frame:ClearAllPoints()
    if config.defaultFrameX and config.defaultFrameY then
        local anchorPoint = config.growUpward and "BOTTOMLEFT" or "TOPLEFT"
        frame:SetPoint(anchorPoint, UIParent, "BOTTOMLEFT", config.defaultFrameX, config.defaultFrameY)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetBackdropBorderColor(0.4, 0.8, 0.4, 1)

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetSize(196, 24)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
    })
    titleBar:SetBackdropColor(0.2, 0.5, 0.2, 1)

    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    titleText:SetText("|cFFFFFFFFDrag to Set Default Position|r")

    -- Instructions
    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructions:SetPoint("TOP", titleBar, "BOTTOM", 0, -12)
    instructions:SetWidth(180)
    instructions:SetJustifyH("CENTER")
    instructions:SetText("|cFFCCCCCCNew watch frames will\nappear at this location.\n\nDrag me, then click Save.|r")

    -- Save button (using UIFactory styled button)
    local saveBtn
    if KOL.UIFactory and KOL.UIFactory.CreateButton then
        saveBtn = KOL.UIFactory:CreateButton(frame, "Save", {
            type = "styled",
            width = 80,
            height = 24,
            fontSize = 11,
            textColor = {r = 0.4, g = 1, b = 0.4, a = 1},
            hoverColor = {r = 0.6, g = 1, b = 0.6, a = 1},
            bgColor = {r = 0.15, g = 0.25, b = 0.15, a = 1},
            borderColor = {r = 0.3, g = 0.6, b = 0.3, a = 1},
            hoverBgColor = {r = 0.2, g = 0.35, b = 0.2, a = 1},
            hoverBorderColor = {r = 0.4, g = 0.9, b = 0.4, a = 1},
            onClick = function()
                -- Get position relative to screen bottom-left
                local left = frame:GetLeft()
                local bottom = frame:GetBottom()

                config.defaultFrameX = left
                config.defaultFrameY = bottom

                KOL:PrintTag(GREEN("Default frame location saved!"))
                frame:Hide()
                Tracker.defaultLocationPickerFrame = nil
            end,
        })
    else
        -- Fallback to basic button if UIFactory not available
        saveBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        saveBtn:SetSize(80, 24)
        saveBtn:SetText("Save")
        saveBtn:SetScript("OnClick", function()
            local left = frame:GetLeft()
            local bottom = frame:GetBottom()
            config.defaultFrameX = left
            config.defaultFrameY = bottom
            KOL:PrintTag(GREEN("Default frame location saved!"))
            frame:Hide()
            Tracker.defaultLocationPickerFrame = nil
        end)
    end
    saveBtn:SetPoint("BOTTOM", frame, "BOTTOM", -45, 10)

    -- Cancel button (using UIFactory styled button)
    local cancelBtn
    if KOL.UIFactory and KOL.UIFactory.CreateButton then
        cancelBtn = KOL.UIFactory:CreateButton(frame, "Cancel", {
            type = "styled",
            width = 80,
            height = 24,
            fontSize = 11,
            textColor = {r = 1, g = 0.5, b = 0.5, a = 1},
            hoverColor = {r = 1, g = 0.7, b = 0.7, a = 1},
            bgColor = {r = 0.25, g = 0.12, b = 0.12, a = 1},
            borderColor = {r = 0.5, g = 0.25, b = 0.25, a = 1},
            hoverBgColor = {r = 0.35, g = 0.15, b = 0.15, a = 1},
            hoverBorderColor = {r = 0.8, g = 0.3, b = 0.3, a = 1},
            onClick = function()
                frame:Hide()
                Tracker.defaultLocationPickerFrame = nil
            end,
        })
    else
        -- Fallback to basic button if UIFactory not available
        cancelBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        cancelBtn:SetSize(80, 24)
        cancelBtn:SetText("Cancel")
        cancelBtn:SetScript("OnClick", function()
            frame:Hide()
            Tracker.defaultLocationPickerFrame = nil
        end)
    end
    cancelBtn:SetPoint("BOTTOM", frame, "BOTTOM", 45, 10)

    -- Dragging from title bar
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)

    -- Also allow dragging from main frame
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    frame:Show()
    self.defaultLocationPickerFrame = frame
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
        autoShow = data.autoShow or false,
        showSpeed = data.showSpeed or false,
        showPrefix = data.showPrefix or false,
        objectives = {},
        groups = {},
    }

    -- Add entries/objectives/groups based on data format
    if data.entries then
        -- New unified entries format - save BOTH entries AND groups
        panelData.entries = data.entries
        panelData.groups = data.groups or {}
        panelData.autoShow = data.autoShow or false
        panelData.showSpeed = data.showSpeed or false
        panelData.showPrefix = data.showPrefix or false
    elseif panelType == "objective" and data.objectives then
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

    KOL:PrintTag("Created custom tracker: " .. GREEN(name))

    -- Refresh config UI
    if KOL.PopulateTrackerConfigUI then
        KOL:PopulateTrackerConfigUI()
        LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
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

    -- Update autoShow (explicit nil check since false is valid)
    if data.autoShow ~= nil then
        panelData.autoShow = data.autoShow
    end

    -- Update showSpeed (explicit nil check since false is valid)
    if data.showSpeed ~= nil then
        panelData.showSpeed = data.showSpeed
    end

    -- Update showPrefix (explicit nil check since false is valid)
    if data.showPrefix ~= nil then
        panelData.showPrefix = data.showPrefix
    end

    -- Update entries/objectives/groups based on data format
    if data.entries then
        -- New unified entries format - save BOTH entries AND groups
        panelData.entries = data.entries
        panelData.groups = data.groups or {}
        panelData.objectives = {}
        panelData.autoShow = data.autoShow or false
        panelData.showSpeed = data.showSpeed or false
        panelData.showPrefix = data.showPrefix or false
        -- DEBUG: Log what we're saving
        KOL:DebugPrint("UPDATE: Saving " .. #data.entries .. " entries, " .. (data.groups and #data.groups or 0) .. " groups", 1)
        for i, entry in ipairs(data.entries) do
            KOL:DebugPrint("UPDATE: Entry[" .. i .. "] name='" .. (entry.name or "?") .. "' group='" .. (entry.group or "") .. "' type=" .. (entry.type or "?"), 1)
        end
    elseif panelType == "objective" and data.objectives then
        panelData.objectives = data.objectives
        panelData.groups = {}
        panelData.entries = nil
    elseif panelType == "grouped" and data.groups then
        panelData.groups = data.groups
        panelData.objectives = {}
        panelData.entries = nil
    end

    -- Save to DB
    if not KOL.db.profile.tracker.customPanels then
        KOL.db.profile.tracker.customPanels = {}
    end
    KOL.db.profile.tracker.customPanels[panelId] = panelData

    KOL:DebugPrint("UpdateCustomPanel: Updated " .. panelData.name, 1)

    -- Update active frame if it exists
    if self.activeFrames[panelId] then
        self:UpdateWatchFrame(panelId)
    end

    -- Refresh config UI
    if KOL.PopulateTrackerConfigUI then
        KOL:PopulateTrackerConfigUI()
        LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
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

    KOL:PrintTag("Deleted custom tracker: " .. RED(panelName))

    -- Refresh config UI
    if KOL.PopulateTrackerConfigUI then
        KOL:PopulateTrackerConfigUI()
        LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
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
        KOL:DebugPrint("Tracker: Loaded custom tracker: " .. panelId, 2)
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
        KOL:Print("Current instanceId: " .. tostring(self.currentInstanceId))
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
    elseif cmd == "refresh" then
        self:RefreshAllWatchFrames()
        KOL:PrintTag("All watch frames refreshed")
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
        KOL:Print("  /kol tracker refresh - Refresh all watch frames (use after changing fontScale)")
        KOL:Print("  /kol tracker test - Show test watch frame (flat bosses)")
        KOL:Print("  /kol tracker testgroup - Show test watch frame (grouped bosses)")
        KOL:Print("  /kol tracker kill <id> <boss> - Mark a boss as killed")
        KOL:Print("  /kol tracker show <id> - Show a watch frame")
    end
end

-- ============================================================================
-- Dungeon Challenge Tracking
-- ============================================================================

-- Constants
local DUNGEON_CHALLENGE_BUFF_ID = 60212
local SPEED_BUFF_NAME = "Speed"  -- The speed buff might have a different name, we'll detect by stacks

-- Dungeon Challenge state per instance
Tracker.dungeonChallengeState = {}

-- Initialize dungeon challenge data in database
function Tracker:InitializeDungeonChallengeData()
    if not KOL.db.profile.tracker.dungeonChallenge then
        KOL.db.profile.tracker.dungeonChallenge = {
            enabled = true,  -- Global enable/disable for dungeon challenge tracking
            showBuffStacks = true,  -- Show BUFF: XX line
            showTimer = true,  -- Show TIME: XX:XX line
            showSpeed = true,  -- Show SPEED: XX% line
            bestTimes = {},  -- [instanceId] = seconds
            speedStacks = {}, -- [instanceId] = stack count (0-50)
        }
    end
    -- Add new config keys if they don't exist (for existing users)
    if KOL.db.profile.tracker.dungeonChallenge.enabled == nil then
        KOL.db.profile.tracker.dungeonChallenge.enabled = true
    end
    if KOL.db.profile.tracker.dungeonChallenge.showBuffStacks == nil then
        KOL.db.profile.tracker.dungeonChallenge.showBuffStacks = true
    end
    if KOL.db.profile.tracker.dungeonChallenge.showTimer == nil then
        KOL.db.profile.tracker.dungeonChallenge.showTimer = true
    end
    if KOL.db.profile.tracker.dungeonChallenge.showSpeed == nil then
        KOL.db.profile.tracker.dungeonChallenge.showSpeed = true
    end
end

-- Check if player is eligible for dungeon challenge
function Tracker:IsDungeonChallengeEligible(instanceId)
    -- Check if dungeon challenge tracking is globally enabled
    if not KOL.db.profile.tracker.dungeonChallenge or not KOL.db.profile.tracker.dungeonChallenge.enabled then
        return false
    end

    -- Custom trackers are NOT eligible for dungeon challenge features
    -- (no speed buff, timer, best times - those are dungeon/raid specific)
    local instanceData = self.instances[instanceId]
    if instanceData and instanceData.type == "custom" then
        return false
    end

    -- Now enabled for all zones, not just those with challengeMaxLevel
    return true
end

-- Scan for Dungeon Challenge buff
function Tracker:ScanDungeonChallengeBuff()
    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitBuff("player", i)
        if not name then break end

        -- Check if this is the Dungeon Challenge buff (by name, not ID)
        if name and name:find("Dungeon Challenge") then
            return true, duration, expirationTime
        end
    end
    return false, 0, 0
end

-- Scan for Speed buff (stacks 0-50)
function Tracker:ScanSpeedBuff()
    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitBuff("player", i)
        if not name then break end

        -- Debug: Print all buffs with stacks to help identify the speed buff
        if count and count > 0 and count <= 50 then
            KOL:DebugPrint(string.format("Buff with stacks found: '%s' (ID: %s) - %d stacks",
                name or "unknown", tostring(spellId or "nil"), count), 3)
        end

        -- Speed buff detection - ONLY accept buffs with speed-related names
        -- No fallback logic - if we can't find it by name, we don't show it at all
        if count and count > 0 and count <= 50 then
            if name and (name:find("Speed") or name:find("Dungeon") or name:find("Challenge")) then
                KOL:DebugPrint(string.format("Speed buff detected by name: '%s' - %d stacks", name, count), 2)
                return true, count
            end
        end
    end

    -- No speed buff found - return false so the SPEED BUFF line won't be shown
    return false, 0
end

-- Get player movement speed (percentage above base 100%)
-- DEPRECATED: Use KOL:ReturnUserSpeed() instead
function Tracker:GetPlayerMovementSpeed()
    return KOL:ReturnUserSpeed()
end

-- Get player movement speed (total percentage)
-- DEPRECATED: Use KOL:ReturnUserSpeedTotal() instead
function Tracker:GetPlayerMovementSpeedTotal()
    return KOL:ReturnUserSpeedTotal()
end

-- Update dungeon challenge state
function Tracker:UpdateDungeonChallengeState(instanceId)
    if not instanceId then return end

    local instanceData = self.instances[instanceId]
    if not instanceData then return end

    -- Initialize state if not exists
    if not self.dungeonChallengeState[instanceId] then
        self.dungeonChallengeState[instanceId] = {
            eligible = false,
            buffActive = false,
            buffDuration = 0,
            buffExpiration = 0,
            speedStacks = 0,
            currentTime = 0,
            bestTime = 0,
            currentSpeed = 100,
            remainingEncounters = 0,
            -- Cached values (persist even when buffs disappear)
            cachedTime = 0,
            cachedSpeedStacks = 0,
            cachedCurrentSpeed = 100,
            -- Start time tracking (like WeakAura: time() - aura_env.t)
            startTime = nil,
            timeElapsedOffset = 0,  -- Offset for /rl persistence
            -- Timer log (per-encounter best times)
            timerLog = {},
            timerLogInitialized = false,
            -- Timer completion tracking
            timerStopped = false,
            completionTime = nil,
        }
    end

    local state = self.dungeonChallengeState[instanceId]

    -- Ensure all required fields exist (for backward compatibility with old saved states)
    if state.speedStacks == nil then state.speedStacks = 0 end
    if state.cachedSpeedStacks == nil then state.cachedSpeedStacks = 0 end
    if state.currentSpeed == nil then state.currentSpeed = 100 end
    if state.cachedCurrentSpeed == nil then state.cachedCurrentSpeed = 100 end
    if state.cachedTime == nil then state.cachedTime = 0 end

    -- Check eligibility
    state.eligible = self:IsDungeonChallengeEligible(instanceId)

    -- Scan for buffs (for SPEED stacks and eligibility, not for timer)
    local hasChallengeBuff, duration, expiration = self:ScanDungeonChallengeBuff()
    state.buffActive = hasChallengeBuff
    state.buffDuration = duration
    state.buffExpiration = expiration

    -- Calculate current timer (time elapsed since entering zone)
    -- Timer starts when ShowWatchFrame is called (zone entry), NOT when buff appears
    -- This handles the case where buff goes infinite after completing all challenges
    -- Persists through /rl by using timeElapsedOffset
    -- Timer stops automatically when all objectives are complete
    if state.startTime and not state.timerStopped then
        local now = GetTime()
        local timeElapsed = now - state.startTime
        local calculatedTime = math.max(0, math.floor(timeElapsed) + (state.timeElapsedOffset or 0))
        
        -- Check if all objectives are complete and timer hasn't been stopped yet
        if self:IsInstanceComplete(instanceId) and not state.completionTime then
            state.completionTime = calculatedTime
            state.timerStopped = true
            state.cachedTime = calculatedTime
            KOL:DebugPrint("Timer stopped at " .. self:FormatTime(calculatedTime) .. " - all objectives complete in " .. instanceId, 2)
        end
        
        if not state.timerStopped then
            state.currentTime = calculatedTime
            state.cachedTime = calculatedTime  -- Cache it
        end

        -- Save to database for /rl persistence
        if not KOL.db.profile.tracker.dungeonChallenge.currentTimes then
            KOL.db.profile.tracker.dungeonChallenge.currentTimes = {}
        end
        KOL.db.profile.tracker.dungeonChallenge.currentTimes[instanceId] = state.cachedTime
    else
        -- No start time yet or timer stopped (shouldn't happen, but fallback to cached)
        state.currentTime = state.cachedTime or 0
    end

    -- Scan for speed buff stacks
    local hasSpeedBuff, stacks = self:ScanSpeedBuff()
    if hasSpeedBuff and stacks > 0 then
        state.speedStacks = stacks
        state.cachedSpeedStacks = stacks  -- Cache it
    else
        -- No speed buff detected - don't show cached value to avoid false positives
        state.speedStacks = 0
    end

    -- Get current movement speed (always live, never cached - speed changes with buffs)
    -- Uses centralized speed functions from functions.lua
    state.currentSpeed = KOL:ReturnUserSpeed()
    state.currentSpeedTotal = KOL:ReturnUserSpeedTotal()  -- Keep total for tooltip

    -- Load best time from database
    if KOL.db.profile.tracker.dungeonChallenge and KOL.db.profile.tracker.dungeonChallenge.bestTimes then
        state.bestTime = KOL.db.profile.tracker.dungeonChallenge.bestTimes[instanceId] or 0
    end

    return state
end

-- Initialize timer log entries for an instance
function Tracker:AddTimerLogEntry(instanceId)
    if not instanceId then return end

    local instanceData = self.instances[instanceId]
    if not instanceData then return end

    local state = self.dungeonChallengeState[instanceId]
    if not state then return end

    -- Only initialize once per zone entry
    if state.timerLogInitialized then return end

    -- Clear existing log
    state.timerLog = {}

    -- Special case: Violet Hold - show ALL possible bosses
    if instanceId == "vh_n" or instanceId == "vh_h" then
        -- Get all VH bosses from the pool
        local vhBosses = {}
        for npcId, bossInfo in pairs(self.VioletHoldBossPool) do
            -- Filter by difficulty
            local targetDifficulty = (instanceId == "vh_h") and 2 or 1
            if bossInfo.difficulty == targetDifficulty then
                -- Don't add Cyanigosa to this list, she's always boss #3
                if bossInfo.name ~= "Cyanigosa" then
                    table.insert(vhBosses, bossInfo.name)
                end
            end
        end

        -- Sort alphabetically for consistent order
        table.sort(vhBosses)

        -- Add all possible random bosses
        for i, bossName in ipairs(vhBosses) do
            table.insert(state.timerLog, {
                name = bossName,
                type = "boss",
                index = i,
                bestTime = 0,
                lastTime = 0,
            })
        end

        -- Add Cyanigosa last (always final boss)
        table.insert(state.timerLog, {
            name = "Cyanigosa",
            type = "boss",
            index = #vhBosses + 1,
            bestTime = 0,
            lastTime = 0,
        })
    else
        -- Check if this instance uses groups (like Naxxramas quarters)
        if instanceData.groups then
            -- Flatten all bosses from all groups into timer log
            local entryIndex = 1
            for groupIndex, group in ipairs(instanceData.groups) do
                if group.bosses then
                    for bossIndex, boss in ipairs(group.bosses) do
                        table.insert(state.timerLog, {
                            name = boss.name,
                            type = "boss",
                            index = entryIndex,
                            bestTime = 0,
                            lastTime = 0,
                        })
                        entryIndex = entryIndex + 1
                    end
                end
            end
        elseif instanceData.bosses then
            -- Normal case: add bosses in order
            for i, boss in ipairs(instanceData.bosses) do
                table.insert(state.timerLog, {
                    name = boss.name,
                    type = "boss",
                    index = i,
                    bestTime = 0,
                    lastTime = 0,
                })
            end
        end
    end

    -- Load saved times from database (best times and last times)
    if KOL.db.profile.tracker.dungeonChallenge then
        local savedBest = KOL.db.profile.tracker.dungeonChallenge.timerLogs and KOL.db.profile.tracker.dungeonChallenge.timerLogs[instanceId]
        local savedLast = KOL.db.profile.tracker.dungeonChallenge.timerLogsLast and KOL.db.profile.tracker.dungeonChallenge.timerLogsLast[instanceId]

        for _, entry in ipairs(state.timerLog) do
            if savedBest and savedBest[entry.name] then
                entry.bestTime = savedBest[entry.name]
            end
            if savedLast and savedLast[entry.name] then
                entry.lastTime = savedLast[entry.name]
            end
        end
    end

    state.timerLogInitialized = true
    KOL:DebugPrint(string.format("Timer log initialized for %s with %d entries", instanceId, #state.timerLog), 2)
end

-- Update a timer log entry with kill time (always updates lastTime, updates bestTime if new record)
function Tracker:UpdateTimerLogEntry(instanceId, encounterName, currentTime)
    if not instanceId or not encounterName then return end

    local state = self.dungeonChallengeState[instanceId]
    if not state or not state.timerLog then return end

    -- Find the entry
    for _, entry in ipairs(state.timerLog) do
        if entry.name == encounterName then
            -- Always update lastTime (records every kill)
            entry.lastTime = currentTime

            -- Initialize database structures if needed
            if not KOL.db.profile.tracker.dungeonChallenge.timerLogs then
                KOL.db.profile.tracker.dungeonChallenge.timerLogs = {}
            end
            if not KOL.db.profile.tracker.dungeonChallenge.timerLogs[instanceId] then
                KOL.db.profile.tracker.dungeonChallenge.timerLogs[instanceId] = {}
            end
            if not KOL.db.profile.tracker.dungeonChallenge.timerLogsLast then
                KOL.db.profile.tracker.dungeonChallenge.timerLogsLast = {}
            end
            if not KOL.db.profile.tracker.dungeonChallenge.timerLogsLast[instanceId] then
                KOL.db.profile.tracker.dungeonChallenge.timerLogsLast[instanceId] = {}
            end

            -- Save lastTime to database
            KOL.db.profile.tracker.dungeonChallenge.timerLogsLast[instanceId][encounterName] = currentTime

            -- Update bestTime if this is a new best (or first time)
            if entry.bestTime == 0 or currentTime < entry.bestTime then
                entry.bestTime = currentTime
                KOL.db.profile.tracker.dungeonChallenge.timerLogs[instanceId][encounterName] = currentTime
                KOL:DebugPrint(string.format("Timer log: NEW BEST for %s - %s", encounterName, self:FormatTime(currentTime)), 2)
            else
                KOL:DebugPrint(string.format("Timer log: %s killed at %s (best: %s)", encounterName, self:FormatTime(currentTime), self:FormatTime(entry.bestTime)), 2)
            end
            return
        end
    end
end

-- Handle chat messages for dungeon challenge completion
function Tracker:OnDungeonChallengeChat(message)
    -- Pattern: "You completed this dungeon challenge in MM:SS!"
    -- Pattern: "Your previous best time was MM:SS."
    -- Pattern: "You've made progress with dungeon challenge, current timer is MM:SS! There are X remaining encounters."

    -- Progress update message
    local progressMinutes, progressSeconds, remainingEncounters = message:match("You've made progress with dungeon challenge, current timer is (%d+):(%d+)! There are (%d+) remaining encounters%.")
    if progressMinutes and progressSeconds then
        local totalSeconds = (tonumber(progressMinutes) * 60) + tonumber(progressSeconds)
        local remaining = tonumber(remainingEncounters) or 0

        KOL:DebugPrint(string.format("Dungeon Challenge progress: %s:%s (%d encounters remaining)",
            progressMinutes, progressSeconds, remaining), 2)

        -- Find current instance and update cached time
        for instanceId, frame in pairs(self.activeFrames) do
            if frame:IsShown() then
                if self.dungeonChallengeState[instanceId] then
                    self.dungeonChallengeState[instanceId].cachedTime = totalSeconds
                    self.dungeonChallengeState[instanceId].currentTime = totalSeconds
                    self.dungeonChallengeState[instanceId].remainingEncounters = remaining
                end

                -- Update watch frame
                self:UpdateWatchFrame(instanceId)
                break
            end
        end
        return
    end

    local completionMinutes, completionSeconds = message:match("You completed this dungeon challenge in (%d+):(%d+)!")
    if completionMinutes and completionSeconds then
        local totalSeconds = (tonumber(completionMinutes) * 60) + tonumber(completionSeconds)
        KOL:DebugPrint("Dungeon Challenge completed in " .. totalSeconds .. " seconds", 2)

        -- Find current instance and save completion time
        for instanceId, frame in pairs(self.activeFrames) do
            if frame:IsShown() then
                -- Initialize database structure if needed
                if not KOL.db.profile.tracker.dungeonChallenge.bestTimes then
                    KOL.db.profile.tracker.dungeonChallenge.bestTimes = {}
                end

                -- Get previous best time (0 if none exists)
                local previousBest = KOL.db.profile.tracker.dungeonChallenge.bestTimes[instanceId] or 0

                -- Only save if this is a new best (lower time) or if there was no previous best
                local isNewBest = (previousBest == 0) or (totalSeconds < previousBest)

                if isNewBest then
                    KOL.db.profile.tracker.dungeonChallenge.bestTimes[instanceId] = totalSeconds

                    -- Cache the completion time so it persists after buff disappears
                    if self.dungeonChallengeState[instanceId] then
                        self.dungeonChallengeState[instanceId].cachedTime = totalSeconds
                        self.dungeonChallengeState[instanceId].currentTime = totalSeconds
                        self.dungeonChallengeState[instanceId].bestTime = totalSeconds
                    end

                    if previousBest == 0 then
                        KOL:Print("Dungeon Challenge completed in " .. COLOR("GREEN", completionMinutes .. ":" .. completionSeconds) .. "!")
                    else
                        local previousBestStr = self:FormatTime(previousBest)
                        KOL:Print("NEW BEST TIME: " .. COLOR("GREEN", completionMinutes .. ":" .. completionSeconds) .. " (Previous: " .. previousBestStr .. ")")
                    end

                    -- Update watch frame to show new best time
                    self:UpdateWatchFrame(instanceId)
                else
                    -- Not a new best, just inform the user
                    local bestTimeStr = self:FormatTime(previousBest)
                    KOL:Print("Dungeon Challenge completed in " .. completionMinutes .. ":" .. completionSeconds .. " (Best: " .. COLOR("GREEN", bestTimeStr) .. ")")
                end

                break
            end
        end
        return
    end

    local bestMinutes, bestSeconds = message:match("Your previous best time was (%d+):(%d+)%.")
    if bestMinutes and bestSeconds then
        local totalSeconds = (tonumber(bestMinutes) * 60) + tonumber(bestSeconds)
        KOL:DebugPrint("Server reported previous best time: " .. totalSeconds .. " seconds", 2)

        -- Find current instance and update best time from server
        for instanceId, frame in pairs(self.activeFrames) do
            if frame:IsShown() then
                -- Initialize database structure if needed
                if not KOL.db.profile.tracker.dungeonChallenge.bestTimes then
                    KOL.db.profile.tracker.dungeonChallenge.bestTimes = {}
                end

                -- Only update if we don't have a best time stored, or if server's is better
                local currentBest = KOL.db.profile.tracker.dungeonChallenge.bestTimes[instanceId] or 0
                if currentBest == 0 or totalSeconds < currentBest then
                    KOL.db.profile.tracker.dungeonChallenge.bestTimes[instanceId] = totalSeconds
                    KOL:DebugPrint("Updated best time from server: " .. bestMinutes .. ":" .. bestSeconds, 2)

                    -- Update state
                    if self.dungeonChallengeState[instanceId] then
                        self.dungeonChallengeState[instanceId].bestTime = totalSeconds
                    end

                    -- Update watch frame
                    self:UpdateWatchFrame(instanceId)
                end
                break
            end
        end
    end
end

-- Format seconds as MM:SS
function Tracker:FormatTime(seconds)
    if not seconds or seconds == 0 then
        return "--:--"
    end
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

-- Start periodic dungeon challenge updates
function Tracker:StartDungeonChallengeUpdates()
    -- Create ticker to update dungeon challenge state every 0.5 seconds
    if not self.dungeonChallengeTicker then
        self.dungeonChallengeTicker = C_Timer.NewTicker(0.5, function()
            -- Update state for all active watch frames
            for instanceId, frame in pairs(self.activeFrames) do
                if frame:IsShown() then
                    local instanceData = self.instances[instanceId]
                    if instanceData and instanceData.challengeMaxLevel then
                        -- Update dungeon challenge state (time, speed, etc.)
                        self:UpdateDungeonChallengeState(instanceId)
                    end
                    -- Update the watch frame UI for ALL active frames (not just dungeon challenge)
                    -- This ensures live speed updates even in non-challenge zones
                    self:UpdateWatchFrame(instanceId)
                end
            end
        end)
        KOL:DebugPrint("Watch frame update ticker started (0.5s interval)", 3)
    end
end

-- Stop periodic updates (for cleanup)
function Tracker:StopDungeonChallengeUpdates()
    if self.dungeonChallengeTicker then
        self.dungeonChallengeTicker:Cancel()
        self.dungeonChallengeTicker = nil
        KOL:DebugPrint("Dungeon Challenge update ticker stopped", 3)
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
    
    -- Initialize BossRecorder module
    if KOL.BossRecorder and KOL.BossRecorder.OnInitialize then
        KOL.BossRecorder:OnInitialize()
    end
end, "Tracker")

-- Register slash commands
KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
    KOL:RegisterSlashCommand("tracker", function(...)
        KOL.Tracker:DebugCommand(...)
    end, "Progress Tracker debug commands", "module")

    KOL:RegisterSlashCommand("ktr", function()
        KOL.Tracker:ResetAll()
        KOL:PrintTag("All tracker boss kills reset")
    end, "Reset all tracker boss kills", "module")
end, "Tracker")

-- Register /ktm as a standalone WoW slash command (not via /kol)
SLASH_KOLKTM1 = "/ktm"
SlashCmdList["KOLKTM"] = function(msg)
    -- Quick-edit selected custom tracker: opens editor + watch frame + config panel
    local instanceId = KOL.db and KOL.db.profile and KOL.db.profile.tracker and
                       KOL.db.profile.tracker.selectedCustomInstance or ""

    if instanceId == "" then
        KOL:PrintTag("|cFFFF6600No custom tracker selected!|r Use /kol config > Progress Tracker > Custom Trackers to select one.")
        return
    end

    -- Show the watch frame
    KOL.Tracker:ShowWatchFrame(instanceId)

    -- Open the editor for this tracker
    KOL:ShowTrackerManager(instanceId)

    -- Also open the config panel to Progress Tracker > Custom Trackers
    local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
    if AceConfigDialog then
        AceConfigDialog:Open("KoalityOfLife")
        AceConfigDialog:SelectGroup("KoalityOfLife", "tracker", "custom")
    end

    KOL:PrintTag("|cFF88FF88Quick edit:|r " .. instanceId)
end

KOL:DebugPrint("Tracker module loaded", 1)
