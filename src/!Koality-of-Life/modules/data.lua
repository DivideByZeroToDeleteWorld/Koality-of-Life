-- !Koality-of-Life: Data Module
-- Handles game data queries and lookups

local addonName = "!Koality-of-Life"
local KOL = KoalityOfLife

-- ============================================================================
-- Zone and Instance Information
-- ============================================================================

-- GetZoneDetails - Comprehensive zone and instance information
-- Returns a table with zone details including type and difficulty
function KOL:GetZoneDetails()
    local name, instanceType, difficulty, difficultyName, maxPlayers, dynamicDifficulty, isDynamic = GetInstanceInfo()
    
    -- Get subzone and zone text for better location detail
    local subzone = GetSubZoneText() or ""
    local zone = GetZoneText() or ""
    
    -- Build display name with format: "Subzone [Zone]" or just "Zone"
    local displayName = name
    if instanceType == "none" then
        -- In open world, use subzone and zone
        if subzone ~= "" and subzone ~= zone then
            displayName = subzone .. " [" .. zone .. "]"
        else
            displayName = zone
        end
    else
        -- In instances, optionally add zone context
        if zone ~= "" and zone ~= name then
            displayName = name .. " [" .. zone .. "]"
        end
    end
    
    local details = {
        name = displayName,              -- Pretty formatted name
        rawName = name,                  -- Original GetInstanceInfo name
        subzone = subzone,               -- Subzone text (e.g., "Dalaran")
        zone = zone,                     -- Zone text (e.g., "Northrend")
        instanceType = instanceType,     -- "none", "party", "raid", "arena", "pvp"
        difficulty = difficulty,
        difficultyName = difficultyName,
        maxPlayers = maxPlayers,
        isInstance = false,
        isDungeon = false,
        isRaid = false,
        isHeroic = false,
        raidSize = nil,                  -- 10 or 25 for raids
        prettyDifficulty = "Normal"      -- Human-readable difficulty
    }
    
    -- Determine if we're in an instance
    if instanceType ~= "none" and instanceType ~= "pvp" and instanceType ~= "arena" then
        details.isInstance = true
        
        -- Determine instance type
        if instanceType == "party" then
            details.isDungeon = true
            
            -- Dungeon difficulty
            if difficulty == 1 then
                details.prettyDifficulty = "Normal Dungeon"
            elseif difficulty == 2 then
                details.prettyDifficulty = "Heroic Dungeon"
                details.isHeroic = true
            end
            
        elseif instanceType == "raid" then
            details.isRaid = true
            
            -- Raid difficulty (ICC era)
            if difficulty == 1 then
                details.prettyDifficulty = "10-Player Normal"
                details.raidSize = 10
            elseif difficulty == 2 then
                details.prettyDifficulty = "25-Player Normal"
                details.raidSize = 25
            elseif difficulty == 3 then
                details.prettyDifficulty = "10-Player Heroic"
                details.raidSize = 10
                details.isHeroic = true
            elseif difficulty == 4 then
                details.prettyDifficulty = "25-Player Heroic"
                details.raidSize = 25
                details.isHeroic = true
            end
        end
    else
        -- Not in an instance
        details.prettyDifficulty = "Open World"
    end
    
    return details
end

-- Zone command - displays zone information
function KOL:ZoneCommand()
    local z = self:GetZoneDetails()
    self:PrintTag("Zone Information:")
    self:Print("|cFFFFFF00Name:|r " .. z.name)
    self:Print("|cFFFFFF00Type:|r " .. (z.isDungeon and "Dungeon" or z.isRaid and "Raid" or "Open World"))
    self:Print("|cFFFFFF00Difficulty:|r " .. (z.isHeroic and "|cFFFF0000" or "|cFF00FF00") .. z.prettyDifficulty .. "|r")
    if z.raidSize then
        self:Print("|cFFFFFF00Raid Size:|r " .. z.raidSize .. " players")
    end
end

-- Quick check if player is in an instance
function KOL:IsInInstance()
    local _, instanceType = GetInstanceInfo()
    return instanceType ~= "none" and instanceType ~= "pvp" and instanceType ~= "arena"
end

-- Quick check if player is in a dungeon
function KOL:IsInDungeon()
    local _, instanceType = GetInstanceInfo()
    return instanceType == "party"
end

-- Quick check if player is in a raid
function KOL:IsInRaid()
    local _, instanceType = GetInstanceInfo()
    return instanceType == "raid"
end

-- Quick check if current instance is heroic difficulty
function KOL:IsHeroic()
    local _, instanceType, difficulty = GetInstanceInfo()
    if instanceType == "party" then
        return difficulty == 2  -- Heroic dungeon
    elseif instanceType == "raid" then
        return difficulty == 3 or difficulty == 4  -- 10H or 25H raid
    end
    return false
end

-- ============================================================================
-- Global Helper Function for Easy Access from Macros
-- Example: /run local z = GetZoneDetails(); CO(z.name, " - ", YELLOW(z.prettyDifficulty))
-- ============================================================================
function GetZoneDetails()
    if KoalityOfLife and KoalityOfLife.GetZoneDetails then
        return KoalityOfLife:GetZoneDetails()
    end
    return nil
end

-- ============================================================================
-- Register Slash Command
-- ============================================================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" and KOL.RegisterSlashCommand then
        KOL:RegisterSlashCommand("zone", function()
            KOL:ZoneCommand()
        end, "Display current zone information")
    end
end)
