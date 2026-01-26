-- !Koality-of-Life: Quest Plates Module
-- Shows quest progress on nameplates for mobs linked to active quests
-- Recreated from ElvUI_Tweaks functionality

local KOL = KoalityOfLife
local LSM = LibStub("LibSharedMedia-3.0")

KOL.QuestPlates = {}
local QuestPlates = KOL.QuestPlates

-- ============================================================================
-- Default Settings
-- ============================================================================

local defaults = {
    enabled = true,
    nameplateSystem = "ElvUI",  -- "None", "ElvUI", "KUI"
    disableInInstance = true,
    disableInCombat = false,

    -- Progress text settings
    showProgress = true,
    progressMouseoverOnly = false,
    progressFont = "Friz Quadrata TT",
    progressFontSize = 10,
    progressFontOutline = "OUTLINE",
    progressAnchor = "RIGHT",
    progressXOffset = 0,
    progressYOffset = 0,
    -- Kill objective colors (gradient from min to max based on progress)
    progressColorKillMin = {r = 1.0, g = 0.2, b = 0.2},   -- Red at 0%
    progressColorKillMax = {r = 0.2, g = 1.0, b = 0.2},   -- Green at 100%
    -- Item objective colors
    progressColorItemMin = {r = 1.0, g = 0.5, b = 0.0},   -- Orange at 0%
    progressColorItemMax = {r = 1.0, g = 0.9, b = 0.2},   -- Yellow at 100%
    -- Default colors
    progressColorDefaultMin = {r = 0.5, g = 0.5, b = 1.0}, -- Blue at 0%
    progressColorDefaultMax = {r = 0.0, g = 1.0, b = 0.0}, -- Green at 100%

    -- Quest icon settings
    showIcon = true,
    iconScale = 1.0,
    iconAlpha = 0.9,
    iconXOffset = 0,
    iconYOffset = 0,
    questColor = {r = 1.0, g = 0.2, b = 0.2},
    multiQuestColor = {r = 1.0, g = 0.6, b = 0.0},
    itemQuestColor = {r = 0.6, g = 0.4, b = 0.9},  -- Purple for loot/item quests
}

-- ============================================================================
-- Local State
-- ============================================================================

local questCache = {}           -- Cache indexed by mob name
local objectiveCache = {}       -- All objectives
local lastCacheTime = 0
local CACHE_DURATION = 2        -- Refresh cache every 2 seconds
local inInstance = false
local inCombat = false
local debugMode = false

-- Frame pools indexed by plateID
local progressFrames = {}
local iconFrames = {}

-- Nameplate system options
local nameplateSystemOptions = {
    ["None"] = "None (Disabled)",
    ["ElvUI"] = "ElvUI",
    ["KUI"] = "KUI Nameplates",
}

-- Anchor point options
local anchorPoints = {
    ["LEFT"] = "LEFT",
    ["RIGHT"] = "RIGHT",
    ["TOP"] = "TOP",
    ["BOTTOM"] = "BOTTOM",
    ["TOPLEFT"] = "TOPLEFT",
    ["TOPRIGHT"] = "TOPRIGHT",
    ["BOTTOMLEFT"] = "BOTTOMLEFT",
    ["BOTTOMRIGHT"] = "BOTTOMRIGHT",
    ["CENTER"] = "CENTER",
}

local fontOutlineOptions = {
    ["NONE"] = "None",
    ["OUTLINE"] = "Outline",
    ["THICKOUTLINE"] = "Thick Outline",
    ["MONOCHROMEOUTLINE"] = "Monochrome Outline",
}

-- ============================================================================
-- Quest Cache Management
-- ============================================================================

local function DebugPrint(msg)
    if debugMode then
        KOL:DebugPrint("QuestPlates: " .. msg, 1)
    end
end

local function ExtractMobName(objectiveText)
    -- Try different patterns to extract mob name from objective text
    local current, total, mobName

    -- Pattern: "Mob Name slain: 3/10"
    mobName, current, total = objectiveText:match("^(.+) slain: (%d+)/(%d+)")
    if mobName then return mobName, tonumber(current), tonumber(total), "kill" end

    -- Pattern: "Kill Mob Name: 3/10" or "Slay Mob Name: 3/10" or "Defeat Mob Name: 3/10"
    mobName, current, total = objectiveText:match("^[Kk]ill (.+): (%d+)/(%d+)")
    if mobName then return mobName, tonumber(current), tonumber(total), "kill" end

    mobName, current, total = objectiveText:match("^[Ss]lay (.+): (%d+)/(%d+)")
    if mobName then return mobName, tonumber(current), tonumber(total), "kill" end

    mobName, current, total = objectiveText:match("^[Dd]efeat (.+): (%d+)/(%d+)")
    if mobName then return mobName, tonumber(current), tonumber(total), "kill" end

    -- Pattern: "Mob Name: 3/10" (generic)
    mobName, current, total = objectiveText:match("^(.+): (%d+)/(%d+)")
    if mobName then return mobName, tonumber(current), tonumber(total), "kill" end

    -- Pattern: "3/10 Mob Name slain" or "3/10 Mob Name killed"
    current, total, mobName = objectiveText:match("^(%d+)/(%d+) (.+) [sS]lain")
    if mobName then return mobName, tonumber(current), tonumber(total), "kill" end

    current, total, mobName = objectiveText:match("^(%d+)/(%d+) (.+) [kK]illed")
    if mobName then return mobName, tonumber(current), tonumber(total), "kill" end

    -- Pattern: "Mob Name's Item: 0/1" (possessive - item drop)
    mobName, current, total = objectiveText:match("^(.+)'s .+: (%d+)/(%d+)")
    if mobName then return mobName, tonumber(current), tonumber(total), "item" end

    -- Pattern: "Item Name: 0/10" (could be item from any mob)
    local itemName
    itemName, current, total = objectiveText:match("^(.+): (%d+)/(%d+)")
    if itemName then
        -- This might be an item, return nil for mob name but keep the objective
        return nil, tonumber(current), tonumber(total), "item"
    end

    return nil, nil, nil, nil
end

function QuestPlates:RefreshQuestCache()
    local currentTime = GetTime()
    if currentTime - lastCacheTime < CACHE_DURATION then
        return
    end
    lastCacheTime = currentTime

    -- Clear caches
    wipe(questCache)
    wipe(objectiveCache)

    local numEntries = GetNumQuestLogEntries()

    for questIndex = 1, numEntries do
        local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questIndex)

        if not isHeader and questTitle then
            local numObjectives = GetNumQuestLeaderBoards(questIndex)

            for objIndex = 1, numObjectives do
                local text, objectiveType, finished = GetQuestLogLeaderBoard(objIndex, questIndex)

                if text and not finished then
                    local mobName, current, total, progressType = ExtractMobName(text)

                    local objectiveData = {
                        questTitle = questTitle,
                        objectiveText = text,
                        mobName = mobName,
                        current = current,
                        total = total,
                        progressType = progressType or "default",
                        finished = finished,
                    }

                    table.insert(objectiveCache, objectiveData)

                    if mobName then
                        local lowerMobName = mobName:lower()
                        if not questCache[lowerMobName] then
                            questCache[lowerMobName] = {}
                        end
                        table.insert(questCache[lowerMobName], objectiveData)
                        DebugPrint("Cached mob: " .. mobName .. " [" .. current .. "/" .. total .. "]")
                    end
                end
            end
        end
    end

    DebugPrint("Quest cache refreshed: " .. #objectiveCache .. " objectives")
end

-- Returns: current, total, hasMore, questCount, objectiveType
function QuestPlates:GetQuestProgressForMob(mobName)
    if not mobName then return nil end

    self:RefreshQuestCache()

    local lowerMobName = mobName:lower()
    DebugPrint("Looking up mob: " .. mobName .. " -> lowercase: " .. lowerMobName)

    -- Level 1: Exact match in questCache
    local objectives = questCache[lowerMobName]
    if objectives and #objectives > 0 then
        local first = objectives[1]
        local hasMore = #objectives > 1
        DebugPrint("Found exact match for: " .. mobName .. " -> " .. (first.current or 0) .. "/" .. (first.total or 0))
        return first.current, first.total, hasMore, #objectives, first.progressType
    end

    DebugPrint("No exact match, trying text search in " .. #objectiveCache .. " objectives")

    -- Level 2: Check if mob name is contained in any cached objective text
    local matchedObjectives = {}
    for i, obj in ipairs(objectiveCache) do
        if obj.objectiveText then
            local lowerText = obj.objectiveText:lower()
            local foundPos = lowerText:find(lowerMobName, 1, true)
            if foundPos then
                DebugPrint("  FOUND in objective " .. i .. " at position " .. foundPos)
                matchedObjectives[#matchedObjectives + 1] = obj
            end
        end
    end

    if #matchedObjectives > 0 then
        local first = matchedObjectives[1]
        local hasMore = #matchedObjectives > 1
        DebugPrint("Found text match for: " .. mobName .. " -> " .. (first.current or 0) .. "/" .. (first.total or 0))
        return first.current, first.total, hasMore, #matchedObjectives, first.progressType
    end

    -- Level 3: Check if any cached mob name is contained in the target mob name
    for cachedName, objs in pairs(questCache) do
        if lowerMobName:find(cachedName, 1, true) then
            local first = objs[1]
            local hasMore = #objs > 1
            DebugPrint("Found reverse match: " .. cachedName .. " in " .. mobName)
            return first.current, first.total, hasMore, #objs, first.progressType
        end
    end

    DebugPrint("No match found for: " .. mobName)
    return nil
end

-- ============================================================================
-- Nameplate Display Functions
-- ============================================================================

local function GetSettings()
    local db = KOL.db.profile.tweaks.questPlates
    if not db then return defaults end

    -- Merge with defaults (db values take priority)
    local settings = {}
    for key, defaultValue in pairs(defaults) do
        if db[key] ~= nil then
            settings[key] = db[key]
        else
            settings[key] = defaultValue
        end
    end
    return settings
end

local function ShouldShowQuestInfo(frame)
    local settings = GetSettings()
    if not settings or not settings.enabled then return false end
    if settings.disableInInstance and inInstance then return false end
    if settings.disableInCombat and inCombat then return false end
    return true
end

-- Get a unique key for a frame (uses plateID if available, otherwise frame reference)
local function GetFrameKey(frame)
    if frame.plateID then
        return frame.plateID
    end
    -- Fallback to using frame as key directly
    return tostring(frame)
end

-- Get or create progress text frame for a nameplate
local function GetProgressFrame(frame)
    if not frame then return nil end

    local key = GetFrameKey(frame)

    if progressFrames[key] then
        return progressFrames[key]
    end

    -- Create a new fontstring for quest progress
    local progressText = frame:CreateFontString(nil, "OVERLAY")
    progressText:SetTextColor(0, 1, 0)  -- Green color default
    progressText:Hide()

    progressFrames[key] = progressText
    DebugPrint("Created progress frame for key: " .. key)
    return progressText
end

-- Get or create icon frame for a nameplate
local function GetIconFrame(frame)
    if not frame then return nil end

    local key = GetFrameKey(frame)

    if iconFrames[key] then
        return iconFrames[key]
    end

    local iconFrame = CreateFrame("Frame", nil, frame)
    iconFrame:SetSize(16, 16)
    iconFrame:SetPoint("RIGHT", frame.Name, "LEFT", -2, 0)
    iconFrame:SetFrameLevel(frame:GetFrameLevel() + 5)

    local texture = iconFrame:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()
    texture:SetTexture([[Interface\QUESTFRAME\UI-Quest-BulletPoint]])
    iconFrame.texture = texture

    iconFrame:Hide()

    iconFrames[key] = iconFrame
    DebugPrint("Created icon frame for key: " .. key)
    return iconFrame
end

-- Check if a texture looks like a quest icon
local function IsQuestTexture(texture)
    if not texture then return false end
    -- Handle both string paths and texture IDs
    if type(texture) == "string" then
        local lowerTexture = texture:lower()
        -- Check for various quest-related texture paths
        if lowerTexture:find("quest") or
           lowerTexture:find("loot") or
           lowerTexture:find("bag") or
           lowerTexture:find("objecticons") or       -- Minimap quest icons
           lowerTexture:find("inv_misc_bag") or      -- Bag inventory icons
           lowerTexture:find("tracking") or          -- Tracking icons
           lowerTexture:find("questie") then         -- Questie addon icons
            return true
        end
    end
    return false
end

-- Table to track textures we've already hidden (to prevent re-showing)
local hiddenQuestTextures = {}

-- Hide quest-related textures on a frame recursively
local function HideQuestTexturesOnFrame(targetFrame, skipFrame, depth)
    if not targetFrame or depth > 5 then return end  -- Limit recursion depth

    -- Check regions (textures, fontstrings, etc)
    local regions = {targetFrame:GetRegions()}
    for _, region in ipairs(regions) do
        if region and region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()

            -- Check if it's a quest texture by path
            local isQuestTex = IsQuestTexture(texture)

            -- Also hide any small textures near the nameplate that look icon-like
            -- (fallback for textures we can't identify by path)
            if not isQuestTex and region:IsShown() then
                local width, height = region:GetSize()
                if width and height and width > 10 and width < 40 and height > 10 and height < 40 then
                    -- Small icon-sized texture - check if it looks like a quest icon position
                    local point, relativeTo, relativePoint = region:GetPoint(1)
                    if point and (point:find("LEFT") or point:find("RIGHT")) then
                        -- Positioned to side - might be quest icon, log for debug
                        DebugPrint("Potential quest icon texture: " .. tostring(texture) .. " size: " .. width .. "x" .. height)
                    end
                end
            end

            if isQuestTex then
                region:SetAlpha(0)
                region:Hide()
                -- Track that we've hidden this texture
                hiddenQuestTextures[region] = true
                DebugPrint("Hidden quest texture: " .. tostring(texture))
            end
        end
    end

    -- Check children frames
    local children = {targetFrame:GetChildren()}
    for _, child in ipairs(children) do
        if child and child ~= skipFrame then
            HideQuestTexturesOnFrame(child, skipFrame, depth + 1)
        end
    end
end

-- Hide Blizzard's default quest icon (bag icon) on a nameplate
local function HideBlizzardQuestIcon(frame)
    if not frame then return end

    -- Get the parent plate frame (the original Blizzard nameplate)
    local plateFrame = frame:GetParent()
    if not plateFrame then return end

    -- Search the plate frame and all its children (except the ElvUI UnitFrame)
    HideQuestTexturesOnFrame(plateFrame, frame, 0)

    -- Also check the grandparent in case of nested structure
    local grandParent = plateFrame:GetParent()
    if grandParent and grandParent ~= WorldFrame and grandParent ~= UIParent then
        HideQuestTexturesOnFrame(grandParent, plateFrame, 0)
    end

    -- Try to find and hide the Blizzard BossIcon/QuestIcon frame directly
    -- In WotLK nameplates, these are commonly named children
    local questIcon = plateFrame.questIcon or plateFrame.QuestIcon
    if questIcon then
        questIcon:Hide()
        if questIcon.SetAlpha then questIcon:SetAlpha(0) end
        hiddenQuestTextures[questIcon] = true
    end
end

-- Update progress text for a frame
local function UpdateProgressText(frame, current, total, hasMore, objectiveType)
    local settings = GetSettings()
    local progressText = GetProgressFrame(frame)
    if not progressText then return end

    -- Check if we should show progress
    if not settings or not settings.showProgress then
        progressText:Hide()
        return
    end

    if not ShouldShowQuestInfo(frame) then
        progressText:Hide()
        return
    end

    -- Check mouseover only setting
    if settings.progressMouseoverOnly and not frame.isMouseover then
        progressText:Hide()
        return
    end

    if not current or not total then
        progressText:Hide()
        return
    end

    -- Update font from settings
    local fontPath = LSM:Fetch("font", settings.progressFont) or "Fonts\\FRIZQT__.TTF"
    progressText:SetFont(fontPath, settings.progressFontSize, settings.progressFontOutline)

    -- Calculate progress percentage (0 to 1)
    local progress = total > 0 and (current / total) or 0
    if progress > 1 then progress = 1 end

    -- Get min/max colors based on objective type
    local colorMin, colorMax
    if objectiveType == "item" then
        colorMin = settings.progressColorItemMin
        colorMax = settings.progressColorItemMax
    elseif objectiveType == "monster" or objectiveType == "kill" then
        colorMin = settings.progressColorKillMin
        colorMax = settings.progressColorKillMax
    else
        colorMin = settings.progressColorDefaultMin
        colorMax = settings.progressColorDefaultMax
    end

    -- Interpolate color based on progress
    local r = colorMin.r + (colorMax.r - colorMin.r) * progress
    local g = colorMin.g + (colorMax.g - colorMin.g) * progress
    local b = colorMin.b + (colorMax.b - colorMin.b) * progress
    progressText:SetTextColor(r, g, b)

    -- Update position based on anchor setting
    local anchor = settings.progressAnchor or "RIGHT"
    local xOffset = settings.progressXOffset or 0
    local yOffset = settings.progressYOffset or 0
    progressText:ClearAllPoints()

    if anchor == "LEFT" then
        progressText:SetPoint("RIGHT", frame.Name, "LEFT", -2 + xOffset, yOffset)
    elseif anchor == "RIGHT" then
        progressText:SetPoint("LEFT", frame.Name, "RIGHT", 2 + xOffset, yOffset)
    elseif anchor == "TOP" then
        progressText:SetPoint("BOTTOM", frame.Name, "TOP", xOffset, 2 + yOffset)
    elseif anchor == "BOTTOM" then
        progressText:SetPoint("TOP", frame.Health, "BOTTOM", xOffset, -2 + yOffset)
    elseif anchor == "TOPLEFT" then
        progressText:SetPoint("BOTTOMRIGHT", frame.Name, "TOPLEFT", xOffset, 2 + yOffset)
    elseif anchor == "TOPRIGHT" then
        progressText:SetPoint("BOTTOMLEFT", frame.Name, "TOPRIGHT", xOffset, 2 + yOffset)
    elseif anchor == "BOTTOMLEFT" then
        progressText:SetPoint("TOPRIGHT", frame.Health, "BOTTOMLEFT", xOffset, -2 + yOffset)
    elseif anchor == "BOTTOMRIGHT" then
        progressText:SetPoint("TOPLEFT", frame.Health, "BOTTOMRIGHT", xOffset, -2 + yOffset)
    elseif anchor == "CENTER" then
        progressText:SetPoint("CENTER", frame.Health, "CENTER", xOffset, yOffset)
    else
        -- Default to right of name
        progressText:SetPoint("LEFT", frame.Name, "RIGHT", 2 + xOffset, yOffset)
    end

    -- Set the text
    local text = string.format("[%d/%d]", current, total)
    if hasMore then
        text = text .. "*"
    end
    progressText:SetText(text)
    progressText:Show()

    DebugPrint("Progress text shown: " .. text)
end

-- Update icon for a frame
local function UpdateIcon(frame, hasQuest, hasMore, objectiveType)
    local settings = GetSettings()
    local key = GetFrameKey(frame)

    if not settings or not settings.showIcon then
        local iconFrame = iconFrames[key]
        if iconFrame then
            iconFrame:Hide()
        end
        return
    end

    if not ShouldShowQuestInfo(frame) then
        local iconFrame = iconFrames[key]
        if iconFrame then
            iconFrame:Hide()
        end
        return
    end

    if not hasQuest then
        local iconFrame = iconFrames[key]
        if iconFrame then
            iconFrame:Hide()
        end
        return
    end

    local iconFrame = GetIconFrame(frame)
    if not iconFrame then return end

    local scale = settings.iconScale or 1
    iconFrame:SetSize(16 * scale, 16 * scale)

    local alpha = settings.iconAlpha or 0.9
    iconFrame:SetAlpha(alpha)

    local xOffset = settings.iconXOffset or 0
    local yOffset = settings.iconYOffset or 0
    iconFrame:ClearAllPoints()
    iconFrame:SetPoint("RIGHT", frame.Name, "LEFT", -2 + xOffset, yOffset)

    local color
    if hasMore then
        -- Multiple quests - use multi color
        color = settings.multiQuestColor or {r = 1, g = 0.6, b = 0}
    elseif objectiveType == "item" then
        -- Item/loot quest - use item color (purple)
        color = settings.itemQuestColor or {r = 0.6, g = 0.4, b = 0.9}
    else
        -- Single kill quest or default - use quest color
        color = settings.questColor or {r = 1, g = 0.2, b = 0.2}
    end
    iconFrame.texture:SetVertexColor(color.r, color.g, color.b, alpha)

    iconFrame:Show()
end

-- Main update function called from ElvUI hook
-- frame is the ElvUI UnitFrame with frame.Name (FontString), frame.UnitName (string), frame.plateID
function QuestPlates:UpdateNameplate(frame)
    if not frame then return end

    -- frame.Name is the FontString element in ElvUI nameplates
    local name = frame.Name
    if not name then
        DebugPrint("frame.Name is nil")
        return
    end

    -- frame.UnitName is the mob's name as a string
    local mobName = frame.UnitName
    if not mobName then
        DebugPrint("frame.UnitName is nil")
        return
    end

    DebugPrint("UpdateNameplate for: " .. mobName)

    -- Get quest progress for this mob
    local current, total, hasMore, questCount, objectiveType = self:GetQuestProgressForMob(mobName)

    -- Update icon (pass objectiveType for color selection)
    UpdateIcon(frame, current ~= nil, hasMore, objectiveType)

    -- Update progress text
    UpdateProgressText(frame, current, total, hasMore, objectiveType)

    -- Hide Blizzard's default quest bag icon
    HideBlizzardQuestIcon(frame)
end

-- ============================================================================
-- ElvUI Integration
-- ============================================================================

local elvUIHooked = false
local NP = nil  -- ElvUI NamePlates module reference

function QuestPlates:HookElvUI()
    if elvUIHooked then return true end

    local E = _G.ElvUI and _G.ElvUI[1]
    if not E then
        DebugPrint("ElvUI not found")
        return false
    end

    NP = E:GetModule("NamePlates", true)
    if not NP then
        DebugPrint("ElvUI NamePlates module not found")
        return false
    end

    -- Wait for NP to be initialized
    if not NP.Initialized then
        DebugPrint("NP not initialized yet, delaying...")
        C_Timer.After(0.5, function()
            self:HookElvUI()
        end)
        return false
    end

    -- Hook into ElvUI's nameplate name update
    -- NP:Update_Name(frame, triggered) - frame is the UnitFrame
    if NP.Update_Name then
        hooksecurefunc(NP, "Update_Name", function(npSelf, frame, triggered)
            DebugPrint(">>> Update_Name HOOK FIRED <<<")
            if frame then
                QuestPlates:UpdateNameplate(frame)
            end
        end)
        elvUIHooked = true
        DebugPrint("Hooked into ElvUI NamePlates Update_Name")

        -- Force update all visible nameplates after a short delay
        -- This ensures quest plates show immediately after /reload
        C_Timer.After(0.2, function()
            DebugPrint("Running initial nameplate update...")
            self:UpdateAllNameplates()
        end)
        -- Run another update slightly later in case some plates weren't ready
        C_Timer.After(1.0, function()
            DebugPrint("Running secondary nameplate update...")
            self:UpdateAllNameplates()
        end)

        return true
    end

    DebugPrint("NP.Update_Name not found")
    return false
end

-- Update all visible nameplates
function QuestPlates:UpdateAllNameplates()
    if not NP or not NP.VisiblePlates then
        DebugPrint("NP.VisiblePlates not available")
        return
    end

    local count = 0
    for frame in pairs(NP.VisiblePlates) do
        self:UpdateNameplate(frame)
        count = count + 1
    end
    DebugPrint("Updated " .. count .. " nameplates")
end

-- Refresh all nameplates when settings change
function QuestPlates:RefreshNameplates()
    if NP and NP.VisiblePlates then
        self:UpdateAllNameplates()
    else
        UpdateAllNameplatesFallback()
    end
end

-- ============================================================================
-- Fallback Nameplate System (for non-ElvUI)
-- ============================================================================

local function UpdateAllNameplatesFallback()
    if not ShouldShowQuestInfo() then return end

    -- Using WorldFrame children for nameplates
    local children = {WorldFrame:GetChildren()}
    for _, frame in ipairs(children) do
        if frame:GetName() and frame:GetName():find("NamePlate") then
            QuestPlates:UpdateNameplate(frame)
        end
    end
end

-- ============================================================================
-- Config UI Setup
-- ============================================================================

function QuestPlates:SetupConfigUI()
    if not KOL.configOptions or not KOL.configOptions.args or not KOL.configOptions.args.tweaks then
        KOL:DebugPrint("QuestPlates: Config not ready, deferring setup", 3)
        return
    end

    local synastriaTab = KOL.configOptions.args.tweaks.args.synastria
    if not synastriaTab then
        KOL:DebugPrint("QuestPlates: Synastria tab not ready yet", 2)
        return
    end

    local settings = GetSettings()

    synastriaTab.args.quests = {
        type = "group",
        name = "Quests",
        order = 6,
        args = {
            header = {
                type = "description",
                name = "QUEST PLATES|0.4,0.8,1",
                dialogControl = "KOL_SectionHeader",
                width = "full",
                order = 0,
            },
            desc = {
                type = "description",
                name = "|cFFAAAAAAShow quest progress on nameplates for mobs linked to active quests.|r\n",
                fontSize = "small",
                order = 0.1,
            },

            -- Nameplate System Selection
            nameplateSystem = {
                type = "select",
                name = "Nameplate System",
                desc = "Select which nameplate addon to integrate with.\n\n|cFFFFFF00Note:|r Requires /reload to take effect when changing.",
                values = nameplateSystemOptions,
                get = function() return GetSettings().nameplateSystem end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.nameplateSystem = value
                    KOL:PrintTag("Quest Plates nameplate system set to |cFF00FFFF" .. value .. "|r |cFFFFAAAA(requires /reload)|r")
                end,
                width = "full",
                order = 0.5,
            },

            -- General Options
            enabled = {
                type = "toggle",
                name = "Enable Quest Plates",
                desc = "Show quest progress indicators on enemy nameplates.",
                get = function() return GetSettings().enabled end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.enabled = value
                    KOL:PrintTag("Quest Plates " .. (value and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
                    QuestPlates:RefreshNameplates()
                end,
                width = "full",
                order = 1,
                hidden = function() return GetSettings().nameplateSystem == "None" end,
            },
            disableInInstance = {
                type = "toggle",
                name = "Disable in Instances",
                desc = "Hide quest indicators in dungeons, raids, battlegrounds, and arenas.",
                get = function() return GetSettings().disableInInstance end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.disableInInstance = value
                    QuestPlates:RefreshNameplates()
                end,
                width = "full",
                order = 2,
                hidden = function() return GetSettings().nameplateSystem == "None" end,
            },
            disableInCombat = {
                type = "toggle",
                name = "Disable in Combat",
                desc = "Hide quest indicators while in combat.",
                get = function() return GetSettings().disableInCombat end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.disableInCombat = value
                    QuestPlates:RefreshNameplates()
                end,
                width = "full",
                order = 3,
                hidden = function() return GetSettings().nameplateSystem == "None" end,
            },

            -- Progress Text Section
            progressHeader = {
                type = "header",
                name = "Progress Text",
                order = 10,
                hidden = function() return GetSettings().nameplateSystem == "None" end,
            },
            showProgress = {
                type = "toggle",
                name = "Show Progress Text",
                desc = "Display [current/total] format on nameplates.",
                get = function() return GetSettings().showProgress end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.showProgress = value
                    QuestPlates:RefreshNameplates()
                end,
                width = "full",
                order = 11,
                hidden = function() return GetSettings().nameplateSystem == "None" end,
            },
            progressMouseoverOnly = {
                type = "toggle",
                name = "Mouseover Only",
                desc = "Only show progress text when hovering over the nameplate.",
                get = function() return GetSettings().progressMouseoverOnly end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.progressMouseoverOnly = value
                    QuestPlates:RefreshNameplates()
                end,
                width = "full",
                order = 12,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },
            progressFont = {
                type = "select",
                name = "Font",
                desc = "Font for progress text.",
                dialogControl = "LSM30_Font",
                values = LSM:HashTable("font"),
                get = function() return GetSettings().progressFont end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.progressFont = value
                    QuestPlates:RefreshNameplates()
                end,
                order = 13,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },
            progressFontSize = {
                type = "range",
                name = "Font Size",
                min = 6, max = 32, step = 1,
                get = function() return GetSettings().progressFontSize end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.progressFontSize = value
                    QuestPlates:RefreshNameplates()
                end,
                order = 14,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },
            progressFontOutline = {
                type = "select",
                name = "Font Outline",
                values = fontOutlineOptions,
                get = function() return GetSettings().progressFontOutline end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.progressFontOutline = value
                    QuestPlates:RefreshNameplates()
                end,
                order = 15,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },
            progressAnchor = {
                type = "select",
                name = "Anchor Point",
                desc = "Where to position the progress text relative to the nameplate name.",
                values = anchorPoints,
                get = function() return GetSettings().progressAnchor end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.progressAnchor = value
                    QuestPlates:RefreshNameplates()
                end,
                order = 16,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },
            progressXOffset = {
                type = "range",
                name = "X Offset",
                min = -100, max = 100, step = 1,
                get = function() return GetSettings().progressXOffset end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.progressXOffset = value
                    QuestPlates:RefreshNameplates()
                end,
                order = 17,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },
            progressYOffset = {
                type = "range",
                name = "Y Offset",
                min = -100, max = 100, step = 1,
                get = function() return GetSettings().progressYOffset end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.progressYOffset = value
                    QuestPlates:RefreshNameplates()
                end,
                order = 18,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },

            -- Progress Colors - Kill Objectives
            killColorsHeader = {
                type = "description",
                name = "|cFFFFFF00Kill Objectives|r - Color gradient from 0% to 100%",
                order = 20,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },
            progressColorKillMin = {
                type = "color",
                name = "Kill (0%)",
                desc = "Color at 0% progress for kill objectives.",
                get = function()
                    local c = GetSettings().progressColorKillMin
                    return c.r, c.g, c.b
                end,
                set = function(_, r, g, b)
                    KOL.db.profile.tweaks.questPlates.progressColorKillMin = {r=r, g=g, b=b}
                    QuestPlates:RefreshNameplates()
                end,
                order = 21,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },
            progressColorKillMax = {
                type = "color",
                name = "Kill (100%)",
                desc = "Color at 100% progress for kill objectives.",
                get = function()
                    local c = GetSettings().progressColorKillMax
                    return c.r, c.g, c.b
                end,
                set = function(_, r, g, b)
                    KOL.db.profile.tweaks.questPlates.progressColorKillMax = {r=r, g=g, b=b}
                    QuestPlates:RefreshNameplates()
                end,
                order = 22,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },

            -- Progress Colors - Item Objectives
            itemColorsHeader = {
                type = "description",
                name = "|cFFFFFF00Item Objectives|r - Color gradient from 0% to 100%",
                order = 23,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },
            progressColorItemMin = {
                type = "color",
                name = "Item (0%)",
                desc = "Color at 0% progress for item objectives.",
                get = function()
                    local c = GetSettings().progressColorItemMin
                    return c.r, c.g, c.b
                end,
                set = function(_, r, g, b)
                    KOL.db.profile.tweaks.questPlates.progressColorItemMin = {r=r, g=g, b=b}
                    QuestPlates:RefreshNameplates()
                end,
                order = 24,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },
            progressColorItemMax = {
                type = "color",
                name = "Item (100%)",
                desc = "Color at 100% progress for item objectives.",
                get = function()
                    local c = GetSettings().progressColorItemMax
                    return c.r, c.g, c.b
                end,
                set = function(_, r, g, b)
                    KOL.db.profile.tweaks.questPlates.progressColorItemMax = {r=r, g=g, b=b}
                    QuestPlates:RefreshNameplates()
                end,
                order = 25,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },

            -- Progress Colors - Default
            defaultColorsHeader = {
                type = "description",
                name = "|cFFFFFF00Other Objectives|r - Color gradient from 0% to 100%",
                order = 26,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },
            progressColorDefaultMin = {
                type = "color",
                name = "Default (0%)",
                desc = "Color at 0% progress for other objectives.",
                get = function()
                    local c = GetSettings().progressColorDefaultMin
                    return c.r, c.g, c.b
                end,
                set = function(_, r, g, b)
                    KOL.db.profile.tweaks.questPlates.progressColorDefaultMin = {r=r, g=g, b=b}
                    QuestPlates:RefreshNameplates()
                end,
                order = 27,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },
            progressColorDefaultMax = {
                type = "color",
                name = "Default (100%)",
                desc = "Color at 100% progress for other objectives.",
                get = function()
                    local c = GetSettings().progressColorDefaultMax
                    return c.r, c.g, c.b
                end,
                set = function(_, r, g, b)
                    KOL.db.profile.tweaks.questPlates.progressColorDefaultMax = {r=r, g=g, b=b}
                    QuestPlates:RefreshNameplates()
                end,
                order = 28,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showProgress end,
            },

            -- Quest Icon Section
            iconHeader = {
                type = "header",
                name = "Quest Icon",
                order = 30,
                hidden = function() return GetSettings().nameplateSystem == "None" end,
            },
            showIcon = {
                type = "toggle",
                name = "Show Quest Icon",
                desc = "Display a quest indicator icon on nameplates.",
                get = function() return GetSettings().showIcon end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.showIcon = value
                    QuestPlates:RefreshNameplates()
                end,
                width = "full",
                order = 31,
                hidden = function() return GetSettings().nameplateSystem == "None" end,
            },
            iconScale = {
                type = "range",
                name = "Icon Scale",
                min = 0.5, max = 3.0, step = 0.1,
                get = function() return GetSettings().iconScale end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.iconScale = value
                    QuestPlates:RefreshNameplates()
                end,
                order = 32,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showIcon end,
            },
            iconAlpha = {
                type = "range",
                name = "Icon Alpha",
                min = 0.1, max = 1.0, step = 0.05,
                get = function() return GetSettings().iconAlpha end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.iconAlpha = value
                    QuestPlates:RefreshNameplates()
                end,
                order = 33,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showIcon end,
            },
            iconXOffset = {
                type = "range",
                name = "X Offset",
                min = -100, max = 100, step = 1,
                get = function() return GetSettings().iconXOffset end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.iconXOffset = value
                    QuestPlates:RefreshNameplates()
                end,
                order = 34,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showIcon end,
            },
            iconYOffset = {
                type = "range",
                name = "Y Offset",
                min = -100, max = 100, step = 1,
                get = function() return GetSettings().iconYOffset end,
                set = function(_, value)
                    KOL.db.profile.tweaks.questPlates.iconYOffset = value
                    QuestPlates:RefreshNameplates()
                end,
                order = 35,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showIcon end,
            },

            -- Icon Colors
            iconColorsGroup = {
                type = "group",
                name = "Icon Colors",
                inline = true,
                order = 40,
                hidden = function() return GetSettings().nameplateSystem == "None" or not GetSettings().showIcon end,
                args = {
                    questColor = {
                        type = "color",
                        name = "Single Quest",
                        desc = "Color when mob is linked to a single quest.",
                        get = function()
                            local c = GetSettings().questColor
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b)
                            KOL.db.profile.tweaks.questPlates.questColor = {r=r, g=g, b=b}
                            QuestPlates:RefreshNameplates()
                        end,
                        order = 1,
                    },
                    multiQuestColor = {
                        type = "color",
                        name = "Multiple Quests",
                        desc = "Color when mob is linked to multiple quests.",
                        get = function()
                            local c = GetSettings().multiQuestColor
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b)
                            KOL.db.profile.tweaks.questPlates.multiQuestColor = {r=r, g=g, b=b}
                            QuestPlates:RefreshNameplates()
                        end,
                        order = 2,
                    },
                    itemQuestColor = {
                        type = "color",
                        name = "Item/Loot Quest",
                        desc = "Color when mob drops items for a quest (loot objectives).",
                        get = function()
                            local c = GetSettings().itemQuestColor
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b)
                            KOL.db.profile.tweaks.questPlates.itemQuestColor = {r=r, g=g, b=b}
                            QuestPlates:RefreshNameplates()
                        end,
                        order = 3,
                    },
                },
            },

            -- Debug Section
            debugHeader = {
                type = "header",
                name = "Debug",
                order = 50,
                hidden = function() return GetSettings().nameplateSystem == "None" end,
            },
            debugDump = {
                type = "execute",
                name = "Dump Quest Cache",
                desc = "Print the current quest cache to chat.",
                func = function()
                    QuestPlates:DumpCache()
                end,
                order = 51,
                hidden = function() return GetSettings().nameplateSystem == "None" end,
            },
            debugTarget = {
                type = "execute",
                name = "Test Target",
                desc = "Test quest matching against your current target.",
                func = function()
                    QuestPlates:TestTarget()
                end,
                order = 52,
                hidden = function() return GetSettings().nameplateSystem == "None" end,
            },
        },
    }

    KOL:DebugPrint("QuestPlates: Config UI setup complete", 3)
end

-- ============================================================================
-- Debug Functions
-- ============================================================================

function QuestPlates:DumpCache()
    self:RefreshQuestCache()

    KOL:PrintTag("|cFF66CCFFQuest Cache Dump:|r")

    local count = 0
    for mobName, objectives in pairs(questCache) do
        count = count + 1
        print(string.format("  |cFFFFFF00%s|r:", mobName))
        for _, obj in ipairs(objectives) do
            print(string.format("    - [%d/%d] %s (%s)",
                obj.current or 0, obj.total or 0, obj.questTitle or "?", obj.progressType or "?"))
        end
    end

    if count == 0 then
        print("  |cFFAAAAAA(no quest mobs cached)|r")
    end

    print(string.format("|cFF66CCFF%d mob(s) in cache, %d total objectives|r", count, #objectiveCache))
end

function QuestPlates:TestTarget()
    if not UnitExists("target") then
        KOL:PrintTag("|cFFFF0000No target selected|r")
        return
    end

    local targetName = UnitName("target")
    KOL:PrintTag(string.format("|cFF66CCFFTesting target:|r %s", targetName))

    local current, total, hasMore, questCount, objectiveType = self:GetQuestProgressForMob(targetName)

    if current then
        print(string.format("  |cFF00FF00Found matching objective:|r"))
        print(string.format("    - Progress: [%d/%d]", current, total))
        print(string.format("    - Type: %s", objectiveType or "unknown"))
        print(string.format("    - Quest count: %d", questCount or 1))
        if hasMore then
            print("    - Has more objectives for this mob")
        end
    else
        print("  |cFFFF8800No matching quest objectives found|r")
    end
end

-- ============================================================================
-- Event Handlers
-- ============================================================================

function QuestPlates:OnQuestLogUpdate()
    lastCacheTime = 0  -- Force cache refresh
    self:RefreshQuestCache()
end

function QuestPlates:OnPlayerEnteringWorld()
    local inInst, instType = IsInInstance()
    inInstance = inInst and (instType == "party" or instType == "raid" or instType == "pvp" or instType == "arena")

    lastCacheTime = 0
    self:RefreshQuestCache()

    -- Force update all nameplates after entering world (handles /reload)
    -- Use a timer to ensure ElvUI has processed its nameplates
    if elvUIHooked and NP then
        C_Timer.After(0.3, function()
            DebugPrint("PLAYER_ENTERING_WORLD: Updating nameplates...")
            self:UpdateAllNameplates()
        end)
    end
end

function QuestPlates:OnCombatState(entering)
    inCombat = entering
end

-- ============================================================================
-- Initialization
-- ============================================================================

function QuestPlates:HookKUI()
    -- TODO: Implement KUI Nameplates integration
    -- KUI Nameplates uses a different structure
    local KUI = _G.KuiNameplates
    if not KUI then
        DebugPrint("KUI Nameplates not found")
        return false
    end

    -- KUI uses message-based callbacks
    -- This is a placeholder for future implementation
    DebugPrint("KUI Nameplates found - integration not yet implemented")
    KOL:PrintTag("|cFFFFFF00QuestPlates:|r KUI Nameplates integration not yet implemented")
    return false
end

function QuestPlates:Initialize()
    -- Initialize settings with defaults
    if not KOL.db.profile.tweaks then
        KOL.db.profile.tweaks = {}
    end

    if not KOL.db.profile.tweaks.questPlates then
        KOL.db.profile.tweaks.questPlates = {}
    end

    -- Apply defaults
    for key, value in pairs(defaults) do
        if KOL.db.profile.tweaks.questPlates[key] == nil then
            KOL.db.profile.tweaks.questPlates[key] = value
        end
    end

    -- Setup config UI
    self:SetupConfigUI()

    local settings = GetSettings()

    -- Check if disabled
    if settings.nameplateSystem == "None" then
        KOL:DebugPrint("QuestPlates: Disabled (nameplate system set to None)", 1)
        return
    end

    -- Hook into the selected nameplate system
    local success = false

    if settings.nameplateSystem == "ElvUI" then
        success = self:HookElvUI()
        if success then
            KOL:DebugPrint("QuestPlates: Hooked into ElvUI", 1)
        else
            KOL:PrintTag("|cFFFFFF00QuestPlates:|r ElvUI not found or NamePlates module unavailable")
        end
    elseif settings.nameplateSystem == "KUI" then
        success = self:HookKUI()
        if success then
            KOL:DebugPrint("QuestPlates: Hooked into KUI Nameplates", 1)
        end
    end

    if not success and settings.nameplateSystem ~= "None" then
        -- Fallback: Use timer to update nameplates (basic support)
        KOL:DebugPrint("QuestPlates: Using fallback nameplate scanning", 2)
        C_Timer.NewTicker(0.5, function()
            if ShouldShowQuestInfo() then
                UpdateAllNameplatesFallback()
            end
        end)
    end

    KOL:DebugPrint("QuestPlates: Module initialized", 1)
end

-- ============================================================================
-- Event Registration
-- ============================================================================

KOL:RegisterEventCallback("QUEST_LOG_UPDATE", function()
    QuestPlates:OnQuestLogUpdate()
end, "QuestPlates")

KOL:RegisterEventCallback("UNIT_QUEST_LOG_CHANGED", function()
    QuestPlates:OnQuestLogUpdate()
end, "QuestPlates")

KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
    QuestPlates:OnPlayerEnteringWorld()
end, "QuestPlates")

KOL:RegisterEventCallback("PLAYER_REGEN_DISABLED", function()
    QuestPlates:OnCombatState(true)
end, "QuestPlates")

KOL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
    QuestPlates:OnCombatState(false)
end, "QuestPlates")

-- ============================================================================
-- Slash Commands
-- ============================================================================

-- Scan all textures on visible nameplates for debugging
local function ScanNameplateTextures()
    if not NP or not NP.VisiblePlates then
        KOL:PrintTag("NP.VisiblePlates not available")
        return
    end

    for frame in pairs(NP.VisiblePlates) do
        local mobName = frame.UnitName or "Unknown"
        KOL:PrintTag("|cFFFFFF00Scanning nameplate for: " .. mobName .. "|r")

        local plateFrame = frame:GetParent()
        if plateFrame then
            print("  Parent frame: " .. tostring(plateFrame:GetName() or "unnamed"))

            -- Scan regions
            local regions = {plateFrame:GetRegions()}
            for i, region in ipairs(regions) do
                if region:GetObjectType() == "Texture" then
                    local tex = region:GetTexture()
                    local w, h = region:GetSize()
                    local shown = region:IsShown() and "shown" or "hidden"
                    print(string.format("    Region %d: tex=%s size=%.0fx%.0f %s", i, tostring(tex), w or 0, h or 0, shown))
                end
            end

            -- Scan children
            local children = {plateFrame:GetChildren()}
            for i, child in ipairs(children) do
                local name = child:GetName() or "unnamed"
                print("  Child " .. i .. ": " .. name)
                local childRegions = {child:GetRegions()}
                for j, region in ipairs(childRegions) do
                    if region:GetObjectType() == "Texture" then
                        local tex = region:GetTexture()
                        local w, h = region:GetSize()
                        local shown = region:IsShown() and "shown" or "hidden"
                        print(string.format("      Tex %d: %s size=%.0fx%.0f %s", j, tostring(tex), w or 0, h or 0, shown))
                    end
                end
            end
        end
        break  -- Only scan first plate
    end
end

SLASH_KOLQPDEBUG1 = "/qpdebug"
SlashCmdList["KOLQPDEBUG"] = function(msg)
    local cmd = msg:lower():trim()

    if cmd == "on" then
        debugMode = true
        KOL:PrintTag("QuestPlates debug mode |cFF00FF00ON|r")
    elseif cmd == "off" then
        debugMode = false
        KOL:PrintTag("QuestPlates debug mode |cFFFF0000OFF|r")
    elseif cmd == "dump" then
        QuestPlates:DumpCache()
    elseif cmd == "target" then
        QuestPlates:TestTarget()
    elseif cmd == "scan" then
        ScanNameplateTextures()
    else
        KOL:PrintTag("|cFF66CCFFQuestPlates Debug Commands:|r")
        print("  /qpdebug on     - Enable debug output")
        print("  /qpdebug off    - Disable debug output")
        print("  /qpdebug dump   - Dump quest cache")
        print("  /qpdebug target - Test current target")
        print("  /qpdebug scan   - Scan nameplate textures")
    end
end

KOL:DebugPrint("QuestPlates module loaded", 1)
