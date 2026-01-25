local addonName = "!Koality-of-Life"
local KOL = KoalityOfLife

function KOL:GetZoneDetails()
    local name, instanceType, difficulty, difficultyName, maxPlayers, dynamicDifficulty, isDynamic = GetInstanceInfo()

    local subzone = GetSubZoneText() or ""
    local zone = GetZoneText() or ""

    local displayName = name
    if instanceType == "none" then
        if subzone ~= "" and subzone ~= zone then
            displayName = subzone .. " [" .. zone .. "]"
        else
            displayName = zone
        end
    else
        if zone ~= "" and zone ~= name then
            displayName = name .. " [" .. zone .. "]"
        end
    end

    local details = {
        name = displayName,
        rawName = name,
        subzone = subzone,
        zone = zone,
        instanceType = instanceType,
        difficulty = difficulty,
        difficultyName = difficultyName,
        maxPlayers = maxPlayers,
        isInstance = false,
        isDungeon = false,
        isRaid = false,
        isHeroic = false,
        raidSize = nil,
        prettyDifficulty = "Normal"
    }

    if instanceType ~= "none" and instanceType ~= "pvp" and instanceType ~= "arena" then
        details.isInstance = true

        if instanceType == "party" then
            details.isDungeon = true

            if difficulty == 1 then
                details.prettyDifficulty = "Normal Dungeon"
            elseif difficulty == 2 then
                details.prettyDifficulty = "Heroic Dungeon"
                details.isHeroic = true
            end

        elseif instanceType == "raid" then
            details.isRaid = true

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
        details.prettyDifficulty = "Open World"
    end

    return details
end

function KOL:ZoneCommand()
    local z = self:GetZoneDetails()
    self:PrintTag("Zone Information:")
    self:Print("|cFFFFFF00Name:|r " .. z.name)
    self:Print("|cFFFFFF00SubZone:|r " .. (z.subzone ~= "" and z.subzone or "(none)"))
    self:Print("|cFFFFFF00Type:|r " .. (z.isDungeon and "Dungeon" or z.isRaid and "Raid" or "Open World"))
    self:Print("|cFFFFFF00Difficulty:|r " .. (z.isHeroic and "|cFFFF0000" or "|cFF00FF00") .. z.prettyDifficulty .. "|r")
    if z.raidSize then
        self:Print("|cFFFFFF00Raid Size:|r " .. z.raidSize .. " players")
    end

    -- Tracker information
    if KOL.Tracker then
        local instanceId = KOL.Tracker.currentInstanceId
        self:Print("|cFFFFFF00Tracker Instance ID:|r " .. (instanceId and "|cFF00FF00" .. instanceId .. "|r" or "|cFFFF0000nil|r"))

        -- Show matching instances for this zone
        local zoneName = GetRealZoneText()
        local matches = {}
        for id, data in pairs(KOL.Tracker.instances or {}) do
            for _, zone in ipairs(data.zones or {}) do
                if zone == zoneName then
                    table.insert(matches, id)
                end
            end
        end
        if #matches > 0 then
            self:Print("|cFFFFFF00Matching Instances:|r |cFF00FF00" .. table.concat(matches, ", ") .. "|r")
        else
            self:Print("|cFFFFFF00Matching Instances:|r |cFFFF0000NONE|r")
        end
    end
end

function KOL:IsInInstance()
    local _, instanceType = GetInstanceInfo()
    return instanceType ~= "none" and instanceType ~= "pvp" and instanceType ~= "arena"
end

function KOL:IsInDungeon()
    local _, instanceType = GetInstanceInfo()
    return instanceType == "party"
end

function KOL:IsInRaid()
    local _, instanceType = GetInstanceInfo()
    return instanceType == "raid"
end

function KOL:IsHeroic()
    local _, instanceType, difficulty = GetInstanceInfo()
    if instanceType == "party" then
        return difficulty == 2
    elseif instanceType == "raid" then
        return difficulty == 3 or difficulty == 4
    end
    return false
end

-- Global helper for macro access: /run local z = GetZoneDetails(); CO(z.name, " - ", YELLOW(z.prettyDifficulty))
function GetZoneDetails()
    if KoalityOfLife and KoalityOfLife.GetZoneDetails then
        return KoalityOfLife:GetZoneDetails()
    end
    return nil
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" and KOL.RegisterSlashCommand then
        KOL:RegisterSlashCommand("zone", function()
            KOL:ZoneCommand()
        end, "Display current zone information")
    end
end)
