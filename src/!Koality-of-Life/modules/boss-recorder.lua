-- ============================================================================
-- Koality of Life - Boss Recorder Module
-- ============================================================================
-- Records boss kills with NPC IDs and GUIDs for easy data collection
-- ============================================================================

local KOL = KoalityOfLife

-- ============================================================================
-- Module Structure
-- ============================================================================

KOL.BossRecorder = {}
local BossRecorder = KOL.BossRecorder

-- ============================================================================
-- Module Initialization
-- ============================================================================

-- OnInitialize function called from main addon
function KOL.BossRecorder:OnInitialize()
    BossRecorder:Initialize()
end

function BossRecorder:Initialize()
    KOL:DebugPrint("BossRecorder module initializing...", 3)
    
    -- Initialize database if not exists
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
    
    -- Register events
    self:RegisterEvents()
    
    -- Register slash commands
    self:RegisterSlashCommands()
    
    -- Check if we should start recording on enable
    self:CheckAutoRecord()
    
    KOL:DebugPrint("BossRecorder module initialized", 3)
end

function BossRecorder:RegisterEvents()
    KOL:RegisterEventCallback("ZONE_CHANGED_NEW_AREA", function()
        self:OnZoneChange()
    end)
    
    KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
        self:OnZoneChange()
    end)
end

-- ============================================================================
-- Session Management
-- ============================================================================

function BossRecorder:StartRecording(reason, forceNew)
    -- Check if we're already recording
    if BossRecorder:IsRecording() then
        if not forceNew then
            -- Already recording, just confirm it's active
            local session = BossRecorder:GetCurrentSession()
            local bossCount = #session.bosses
            KOL:Print(COLOR("GREEN", "Boss Recorder:") .. " Already recording (" .. bossCount .. " bosses recorded so far)")
            KOL:Print("Use " .. COLOR("YELLOW", "/kbr start new") .. " to start a fresh session")
            return true
        else
            -- Force new session - stop current one first
            KOL:Print(COLOR("GREEN", "Boss Recorder:") .. " Stopping current session to start new one...")
            BossRecorder:StopRecording("Manual stop - starting new session")
        end
    end

    local zoneName = GetRealZoneText() or GetZoneText()
    local _, instanceType, difficultyIndex = GetInstanceInfo()

    -- Determine if this is a manual or auto start
    local isAutoStart = reason and reason:find("Auto") or false

    -- Only allow auto-recording in dungeons and raids
    if isAutoStart and instanceType ~= "raid" and instanceType ~= "party" then
        KOL:DebugPrint("BossRecorder: Auto-record ignored - not in dungeon or raid instance", 3)
        return false
    end

    local session = {
        id = "session_" .. time(),
        startTime = GetTime(),
        endTime = nil,
        zone = zoneName,
        instanceType = instanceType,
        difficulty = difficultyIndex,
        bosses = {},
        reason = reason or "Manual start",
        isManual = not isAutoStart,  -- Track if manually started
        multiZone = not isAutoStart,  -- Manual sessions persist across zones
    }

    KOL.db.profile.bossRecording.currentSession = session

    KOL:Print(COLOR("GREEN", "Boss Recorder:") .. " Started recording in " .. zoneName ..
              (reason and " (" .. reason .. ")" or ""))

    KOL:DebugPrint("BossRecorder: Started session " .. session.id, 2)
    return true
end

function BossRecorder:StopRecording(reason)
    if not BossRecorder:IsRecording() then
        KOL:DebugPrint("BossRecorder: Not recording, ignoring stop request", 2)
        return false
    end

    local session = KOL.db.profile.bossRecording.currentSession
    session.endTime = GetTime()
    session.endReason = reason or "Manual stop"

    -- Add to sessions list
    table.insert(KOL.db.profile.bossRecording.sessions, session)

    -- Maintain max sessions limit
    local maxSessions = KOL.db.profile.bossRecording.settings.maxSessions
    while #KOL.db.profile.bossRecording.sessions > maxSessions do
        table.remove(KOL.db.profile.bossRecording.sessions, 1)
    end

    KOL:Print(COLOR("GREEN", "Boss Recorder:") .. " Stopped recording - " ..
              #session.bosses .. " bosses recorded" ..
              (reason and " (" .. reason .. ")" or ""))

    KOL:DebugPrint("BossRecorder: Stopped session " .. session.id .. " with " ..
                   #session.bosses .. " bosses", 2)

    KOL.db.profile.bossRecording.currentSession = nil
    return true
end

function BossRecorder:IsRecording()
    return KOL.db.profile.bossRecording.currentSession ~= nil
end

function BossRecorder:GetCurrentSession()
    return KOL.db.profile.bossRecording.currentSession
end

function BossRecorder:RecordBossKill(destName, destGUID, npcId, classification)
    if not BossRecorder:IsRecording() then
        return false
    end

    local session = BossRecorder:GetCurrentSession()
    if not session then
        return false
    end

    -- Only record bosses if setting is enabled
    if KOL.db.profile.bossRecording.settings.recordOnlyBosses and
       not classification:find("Boss") then
        return false
    end

    -- Duplicate detection: Check if we already recorded this exact GUID in the last 5 seconds
    local currentTime = GetTime()
    for i = #session.bosses, 1, -1 do
        local prevKill = session.bosses[i]
        if currentTime - prevKill.timestamp > 5 then
            break  -- No more recent kills to check
        end
        if prevKill.guid == destGUID then
            KOL:DebugPrint("BossRecorder: Duplicate kill ignored - " .. destName .. " (GUID already recorded)", 2)
            return false  -- Already recorded this exact boss kill
        end
    end

    local name, instanceType, difficultyIndex = GetInstanceInfo()
    local bossKill = {
        timestamp = GetTime(),
        name = destName,
        guid = destGUID,
        npcId = npcId,
        classification = classification,
        zone = GetRealZoneText(),
        difficulty = difficultyIndex,
        instanceType = instanceType  -- Store instance type (party/raid) for proper difficulty labeling
    }

    table.insert(session.bosses, bossKill)

    KOL:DebugPrint("BossRecorder: Recorded boss kill - " .. destName .. " (ID: " .. npcId .. ")", 2)
    return true
end

-- ============================================================================
-- Auto-Recording Logic
-- ============================================================================

function BossRecorder:CheckAutoRecord()
    if not KOL.db.profile.bossRecording.settings.autoRecord then
        return
    end

    local _, instanceType, difficultyIndex = GetInstanceInfo()

    -- Auto-record for both dungeons (party) and raids
    if instanceType == "raid" or instanceType == "party" then
        if not BossRecorder:IsRecording() then
            local instanceTypeName = instanceType == "raid" and "raid" or "dungeon"
            BossRecorder:StartRecording("Auto-record: Entered " .. instanceTypeName .. " instance")
        end
    else
        -- Only auto-stop if the session was auto-started (not manual)
        if BossRecorder:IsRecording() then
            local session = BossRecorder:GetCurrentSession()
            if session and not session.multiZone then
                -- Auto-started session, stop it when leaving instance
                BossRecorder:StopRecording("Auto-record: Left instance")
            else
                -- Manual/multi-zone session, keep it running
                KOL:DebugPrint("BossRecorder: Manual session persisting across zone change", 2)
            end
        end
    end
end

function BossRecorder:OnZoneChange()
    self:CheckAutoRecord()
end

-- ============================================================================
-- Export System
-- ============================================================================

function BossRecorder:ExportAllSessions()
    local sessions = {}

    -- Include all saved sessions
    for _, session in ipairs(KOL.db.profile.bossRecording.sessions) do
        table.insert(sessions, session)
    end

    -- Also include current active session if recording
    if BossRecorder:IsRecording() then
        local currentSession = KOL.db.profile.bossRecording.currentSession
        if currentSession and #currentSession.bosses > 0 then
            -- Mark it as current/active
            currentSession.isActive = true
            table.insert(sessions, currentSession)
        end
    end

    if #sessions == 0 then
        KOL:Print(COLOR("GREEN", "Boss Recorder:") .. " No recorded sessions found")
        KOL:Print("Use " .. COLOR("YELLOW", "/kbr start") .. " to begin recording")
        return
    end

    local totalBosses = 0
    for _, session in ipairs(sessions) do
        totalBosses = totalBosses + #session.bosses
    end

    -- Clean paste-friendly format
    KOL:Print(COLOR("GREEN", "Boss Recorder:") .. " Exporting " .. #sessions ..
              " sessions with " .. totalBosses .. " total bosses:")
    KOL:Print(string.rep("=", 80))

    for sessionIndex, session in ipairs(sessions) do
        if #session.bosses > 0 then
            -- Session header (indicate if multi-zone or active)
            local sessionType = ""
            if session.isActive then
                sessionType = " " .. COLOR("YELLOW", "(ACTIVE - Currently Recording)")
            elseif session.multiZone then
                sessionType = " (Multi-Zone)"
            end
            KOL:Print("=== Session " .. sessionIndex .. sessionType .. " ===")

            -- Group bosses by zone
            local bossesByZone = {}
            for bossIndex, boss in ipairs(session.bosses) do
                local zone = boss.zone or session.zone or "Unknown"
                if not bossesByZone[zone] then
                    bossesByZone[zone] = {}
                end
                table.insert(bossesByZone[zone], boss)
            end

            -- Output each zone's bosses
            for zone, bosses in pairs(bossesByZone) do
                -- Get difficulty from first boss (or use session difficulty)
                local diffIndex = bosses[1].difficulty or session.difficulty
                local instType = bosses[1].instanceType or "unknown"

                -- Difficulty names depend on instance type
                local diffName
                if instType == "raid" then
                    -- Raid difficulties
                    local raidDiffNames = {
                        [1] = "10N",   -- 10 Player Normal
                        [2] = "25N",   -- 25 Player Normal
                        [3] = "10H",   -- 10 Player Heroic
                        [4] = "25H",   -- 25 Player Heroic
                        [5] = "40N",   -- 40 Player Normal (classic)
                    }
                    diffName = raidDiffNames[diffIndex] or ("Raid-" .. (diffIndex or "?"))
                elseif instType == "party" then
                    -- Dungeon difficulties
                    local dungeonDiffNames = {
                        [1] = "5N",    -- 5 Player Normal
                        [2] = "5H",    -- 5 Player Heroic
                    }
                    diffName = dungeonDiffNames[diffIndex] or ("Dungeon-" .. (diffIndex or "?"))
                else
                    diffName = "Difficulty " .. (diffIndex or "?")
                end

                KOL:Print(COLOR("CYAN", zone) .. " - " .. diffName)

                for _, boss in ipairs(bosses) do
                    KOL:Print("  Boss: " .. boss.name .. " (NPC ID: " .. boss.npcId .. ", GUID: " .. boss.guid .. ")")
                end
            end

            -- Blank line between sessions
            if sessionIndex < #sessions then
                KOL:Print("")
            end
        end
    end

    KOL:Print(string.rep("=", 80))
    KOL:Print(COLOR("GREEN", "Boss Recorder:") .. " Export complete - Use '/kbr clear' to delete all sessions")
end

function BossRecorder:ClearAllSessions()
    local savedCount = #KOL.db.profile.bossRecording.sessions
    local currentBosses = 0

    -- Clear saved sessions
    KOL.db.profile.bossRecording.sessions = {}

    -- Also clear current session if recording
    if BossRecorder:IsRecording() then
        currentBosses = #KOL.db.profile.bossRecording.currentSession.bosses
        KOL.db.profile.bossRecording.currentSession = nil
    end

    local totalCleared = savedCount + (currentBosses > 0 and 1 or 0)
    KOL:Print(COLOR("GREEN", "Boss Recorder:") .. " Cleared " .. totalCleared .. " sessions (" ..
              savedCount .. " saved, " .. currentBosses .. " bosses in active session)")
    KOL:DebugPrint("BossRecorder: Cleared all sessions and current recording", 2)
end

function BossRecorder:ShowStatus()
    local currentSession = BossRecorder:IsRecording()
    local sessionCount = #KOL.db.profile.bossRecording.sessions
    local currentBosses = 0

    if currentSession then
        currentBosses = #KOL.db.profile.bossRecording.currentSession.bosses
    end

    KOL:Print(COLOR("GREEN", "Boss Recorder Status:"))
    KOL:Print(COLOR("GREEN", "  Recording:") .. " " .. (currentSession and COLOR("GREEN", "Yes") or COLOR("GRAY", "No")))
    if currentSession then
        local session = KOL.db.profile.bossRecording.currentSession
        KOL:Print(COLOR("GREEN", "  Started In:") .. " " .. (session.zone or "Unknown"))
        KOL:Print(COLOR("GREEN", "  Bosses Recorded:") .. " " .. currentBosses)
        if session.multiZone then
            KOL:Print(COLOR("YELLOW", "  Multi-Zone:") .. " Active (persists across zones and reloads)")
        end
    else
        KOL:Print(COLOR("GRAY", "  Use '/kbr start' to begin recording"))
    end
    KOL:Print(COLOR("GREEN", "  Saved Sessions:") .. " " .. sessionCount)
    KOL:Print(COLOR("GREEN", "  Auto-Record:") .. " " .. (KOL.db.profile.bossRecording.settings.autoRecord and COLOR("GREEN", "Enabled (dungeons & raids)") or COLOR("GRAY", "Disabled")))
end

function BossRecorder:ListSessions()
    local sessions = KOL.db.profile.bossRecording.sessions
    
    if #sessions == 0 then
        KOL:PrintTag("|cFF00FF00Boss Recorder:|r No recorded sessions found")
        return
    end
    
    KOL:PrintTag("|cFF00FF00Boss Recorder Sessions:|r")
    
    for i, session in ipairs(sessions) do
        local duration = session.endTime and 
                        string.format("%.1f", session.endTime - session.startTime) .. "s" or 
                        "Incomplete"
        
        KOL:PrintTag("|cFF00FFFF  " .. i .. ".|r " .. session.zone .. 
                      " (Difficulty: " .. (session.difficulty or "Unknown") .. 
                      ", " .. #session.bosses .. " bosses, " .. duration .. ")")
    end
end

-- ============================================================================
-- Slash Commands
-- ============================================================================

function BossRecorder:RegisterSlashCommands()
    -- Commands are now registered in main.lua using RegisterChatCommand
    -- This function is kept for compatibility but does nothing
end

function BossRecorder:HandleBossRecordCommand(input)
    if not input or input == "" then
        self:ShowStatus()
        return
    end

    local command, arg = string.match(input, "^(%S+)%s*(.*)$")
    if not command then
        self:ShowStatus()
        return
    end

    command = command:lower()

    if command == "start" then
        -- Check if they want to force a new session
        local forceNew = arg and arg:lower() == "new"
        BossRecorder:StartRecording("Manual start", forceNew)
    elseif command == "stop" then
        BossRecorder:StopRecording(arg or "Manual stop")
    elseif command == "status" then
        self:ShowStatus()
    elseif command == "export" then
        self:ExportAllSessions()
    elseif command == "clear" then
        self:ClearAllSessions()
    elseif command == "wipe" then
        -- Nuclear option: completely reset everything
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
        KOL:Print(COLOR("RED", "Boss Recorder:") .. " Complete wipe - all data deleted!")
    elseif command == "list" then
        self:ListSessions()
    else
        KOL:Print(COLOR("GREEN", "Boss Recorder Commands:"))
        KOL:Print(COLOR("CYAN", "  start") .. " - Resume/continue current recording session")
        KOL:Print(COLOR("CYAN", "  start new") .. " - Start fresh session (saves current first)")
        KOL:Print(COLOR("CYAN", "  stop") .. " - Stop recording and save session")
        KOL:Print(COLOR("CYAN", "  status") .. " - Show current recording status")
        KOL:Print(COLOR("CYAN", "  export") .. " - Export all recorded sessions (includes active)")
        KOL:Print(COLOR("CYAN", "  clear") .. " - Clear all sessions (saved + active)")
        KOL:Print(COLOR("CYAN", "  wipe") .. " - " .. COLOR("RED", "NUCLEAR:") .. " Delete everything, full reset")
        KOL:Print(COLOR("CYAN", "  list") .. " - List all saved sessions")
        KOL:Print(COLOR("YELLOW", "Aliases:") .. " /kbre (export), /kbrl (list), /kbrs (status)")
        KOL:Print(COLOR("YELLOW", "Tip:") .. " Recording persists across reloads - just /kbr start to resume!")
    end
end

-- ============================================================================
-- Integration with Tracker Module
-- ============================================================================

-- This function will be called from tracker.lua when a boss is detected
function BossRecorder:OnBossDetected(destName, destGUID, npcId, classification)
    if BossRecorder:IsRecording() then
        BossRecorder:RecordBossKill(destName, destGUID, npcId, classification)
    end
end