-- !Koality-of-Life: Global Utility Functions

local KOL = KoalityOfLife

-- ============================================================================
-- Inventory Scanning
-- ============================================================================

function KOL:ScanInventory(itemIDOrName)
    if not itemIDOrName then
        return false, 0
    end

    local searchType = type(itemIDOrName)
    local totalCount = 0

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)

            if itemLink then
                local matches = false

                if searchType == "number" then
                    local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
                    matches = (itemID == itemIDOrName)
                elseif searchType == "string" then
                    local itemName = GetItemInfo(itemLink)
                    matches = (itemName and itemName == itemIDOrName)
                end

                if matches then
                    local _, count = GetContainerItemInfo(bag, slot)
                    totalCount = totalCount + (count or 1)
                end
            end
        end
    end

    return (totalCount > 0), totalCount
end

function KOL:FindItemLocation(itemIDOrName)
    if not itemIDOrName then
        return false, nil, nil
    end

    local searchType = type(itemIDOrName)

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)

            if itemLink then
                local matches = false

                if searchType == "number" then
                    local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
                    matches = (itemID == itemIDOrName)
                elseif searchType == "string" then
                    local itemName = GetItemInfo(itemLink)
                    matches = (itemName and itemName == itemIDOrName)
                end

                if matches then
                    return true, bag, slot
                end
            end
        end
    end

    return false, nil, nil
end

function KOL:ScanBank(itemIDOrName)
    if not itemIDOrName then
        return false, 0, false
    end

    local searchType = type(itemIDOrName)
    local totalCount = 0
    local bankOpen = false
    local BANK_CONTAINER = -1
    local NUM_BANK_SLOTS = 28

    for slot = 1, NUM_BANK_SLOTS do
        local itemLink = GetContainerItemLink(BANK_CONTAINER, slot)
        if itemLink then
            bankOpen = true
            local matches = false

            if searchType == "number" then
                local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
                matches = (itemID == itemIDOrName)
            elseif searchType == "string" then
                local itemName = GetItemInfo(itemLink)
                matches = (itemName and itemName == itemIDOrName)
            end

            if matches then
                local _, count = GetContainerItemInfo(BANK_CONTAINER, slot)
                totalCount = totalCount + (count or 1)
            end
        end
    end

    for bag = 5, 11 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots and numSlots > 0 then
            bankOpen = true
            for slot = 1, numSlots do
                local itemLink = GetContainerItemLink(bag, slot)
                if itemLink then
                    local matches = false

                    if searchType == "number" then
                        local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
                        matches = (itemID == itemIDOrName)
                    elseif searchType == "string" then
                        local itemName = GetItemInfo(itemLink)
                        matches = (itemName and itemName == itemIDOrName)
                    end

                    if matches then
                        local _, count = GetContainerItemInfo(bag, slot)
                        totalCount = totalCount + (count or 1)
                    end
                end
            end
        end
    end

    return (totalCount > 0), totalCount, bankOpen
end

function KOL:ScanAll(itemIDOrName)
    local _, inventoryCount = KOL:ScanInventory(itemIDOrName)
    local _, bankCount, bankOpen = KOL:ScanBank(itemIDOrName)

    local totalCount = inventoryCount + bankCount
    local found = totalCount > 0

    return found, inventoryCount, bankCount, totalCount, bankOpen
end

function KOL:GetItemCountBreakdown(itemIDOrName)
    local found, inv, bank, total, bankOpen = KOL:ScanAll(itemIDOrName)

    local lines = {}
    table.insert(lines, "Inventory: " .. inv)

    if bankOpen then
        table.insert(lines, "Bank: " .. bank)
        table.insert(lines, "Total: " .. total)
    else
        table.insert(lines, "Bank: ? (visit banker)")
        table.insert(lines, "Total: " .. inv .. "+")
    end

    return table.concat(lines, "\n")
end

function KOL:CountInventoryItem(itemIDOrName)
    if not itemIDOrName then
        return 0
    end

    local searchType = type(itemIDOrName)
    local totalCount = 0

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)

            if itemLink then
                local matches = false

                if searchType == "number" then
                    local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
                    matches = (itemID == itemIDOrName)
                elseif searchType == "string" then
                    local itemName = GetItemInfo(itemLink)
                    matches = (itemName and itemName == itemIDOrName)
                end

                if matches then
                    local _, count = GetContainerItemInfo(bag, slot)
                    totalCount = totalCount + (count or 1)
                end
            end
        end
    end

    return totalCount
end

-- ============================================================================
-- Unified Objective Tracking System
-- ============================================================================

local objectiveProgress = {}

function KOL:InitializeObjectives()
    if KOL.db and KOL.db.profile and KOL.db.profile.tracker then
        objectiveProgress = KOL.db.profile.tracker.objectiveProgress or {}
        KOL.db.profile.tracker.objectiveProgress = objectiveProgress
    end
end

function KOL:MarkObjectiveComplete(instanceId, objectiveId, options)
    if not instanceId or not objectiveId then
        return false
    end

    options = options or {}

    if not objectiveProgress[instanceId] then
        objectiveProgress[instanceId] = {}
    end

    local existing = objectiveProgress[instanceId][objectiveId]
    if type(existing) == "table" and existing.max then
        existing.current = existing.max
        existing.complete = true
    else
        objectiveProgress[instanceId][objectiveId] = {
            complete = true,
            current = 1,
            max = 1,
            timestamp = time()
        }
    end

    if KOL.db and KOL.db.profile and KOL.db.profile.tracker then
        KOL.db.profile.tracker.objectiveProgress = objectiveProgress
    end

    if not options.silent then
        KOL:DebugPrint("Objective complete: " .. tostring(instanceId) .. "/" .. tostring(objectiveId), 2)
    end

    if not options.skipRefresh and KOL.Tracker and KOL.Tracker.RefreshTrackerFrames then
        KOL.Tracker:RefreshTrackerFrames()
    end

    return true
end

function KOL:UpdateObjectiveProgress(instanceId, objectiveId, current, max, options)
    if not instanceId or not objectiveId then
        return false, false
    end

    options = options or {}
    local autoComplete = options.autoComplete ~= false

    if not objectiveProgress[instanceId] then
        objectiveProgress[instanceId] = {}
    end

    local obj = objectiveProgress[instanceId][objectiveId]
    if type(obj) ~= "table" then
        obj = { current = 0, max = max or current, complete = false }
        objectiveProgress[instanceId][objectiveId] = obj
    end

    obj.current = current or obj.current
    if max then
        obj.max = max
    end
    obj.timestamp = time()

    local isComplete = obj.current >= obj.max
    if isComplete and autoComplete then
        obj.complete = true
    end

    if KOL.db and KOL.db.profile and KOL.db.profile.tracker then
        KOL.db.profile.tracker.objectiveProgress = objectiveProgress
    end

    if not options.silent then
        KOL:DebugPrint("Objective progress: " .. tostring(instanceId) .. "/" .. tostring(objectiveId) ..
            " [" .. obj.current .. "/" .. obj.max .. "]" .. (isComplete and " COMPLETE" or ""), 3)
    end

    if not options.skipRefresh and KOL.Tracker and KOL.Tracker.RefreshTrackerFrames then
        KOL.Tracker:RefreshTrackerFrames()
    end

    return true, isComplete
end

function KOL:IsObjectiveComplete(instanceId, objectiveId)
    if not instanceId or not objectiveId then
        return false
    end

    local obj = objectiveProgress[instanceId] and objectiveProgress[instanceId][objectiveId]
    if not obj then
        return false
    end

    if type(obj) == "table" then
        return obj.complete == true
    end

    return obj == true
end

function KOL:GetObjectiveProgress(instanceId, objectiveId)
    if not instanceId or not objectiveId then
        return 0, 0, false
    end

    local obj = objectiveProgress[instanceId] and objectiveProgress[instanceId][objectiveId]
    if not obj then
        return 0, 0, false
    end

    if type(obj) == "table" then
        return obj.current or 0, obj.max or 0, obj.complete == true
    end

    if obj == true then
        return 1, 1, true
    end

    return 0, 0, false
end

function KOL:ResetObjective(instanceId, objectiveId, options)
    if not instanceId then
        return false
    end

    options = options or {}
    local keepMax = options.keepMax ~= false

    if objectiveId then
        local obj = objectiveProgress[instanceId] and objectiveProgress[instanceId][objectiveId]
        if obj and type(obj) == "table" then
            obj.current = 0
            obj.complete = false
            if not keepMax then
                obj.max = 0
            end
        else
            objectiveProgress[instanceId] = objectiveProgress[instanceId] or {}
            objectiveProgress[instanceId][objectiveId] = nil
        end
    else
        objectiveProgress[instanceId] = {}
    end

    if KOL.db and KOL.db.profile and KOL.db.profile.tracker then
        KOL.db.profile.tracker.objectiveProgress = objectiveProgress
    end

    if not options.silent then
        KOL:DebugPrint("Objective reset: " .. tostring(instanceId) ..
            (objectiveId and ("/" .. tostring(objectiveId)) or " (all)"), 2)
    end

    if not options.skipRefresh and KOL.Tracker and KOL.Tracker.RefreshTrackerFrames then
        KOL.Tracker:RefreshTrackerFrames()
    end

    return true
end

function KOL:ScanAndUpdateObjective(instanceId, objectiveId, itemIDOrName, targetCount, options)
    local found, count = KOL:ScanInventory(itemIDOrName)

    options = options or {}
    local _, isComplete = KOL:UpdateObjectiveProgress(instanceId, objectiveId, count, targetCount, options)

    return found, count, isComplete
end

function KOL:GetObjectiveProgressString(instanceId, objectiveId, format)
    local current, max = KOL:GetObjectiveProgress(instanceId, objectiveId)
    format = format or "[%d/%d]"
    return string.format(format, current, max)
end

function KOL:IncrementObjective(instanceId, objectiveId, delta, max, options)
    delta = delta or 1

    local current = KOL:GetObjectiveProgress(instanceId, objectiveId)
    local newCurrent = current + delta

    local success, isComplete = KOL:UpdateObjectiveProgress(instanceId, objectiveId, newCurrent, max, options)
    return success, newCurrent, isComplete
end

function KOL:GetObjectiveProgressColor(instanceId, objectiveId)
    local current, max, isComplete = KOL:GetObjectiveProgress(instanceId, objectiveId)

    if max == 0 then
        return 0.5, 0.5, 0.5, "808080"
    end

    if isComplete then
        return 0.4, 1.0, 0.4, "66FF66"
    end

    local ratio = current / max
    ratio = math.max(0, math.min(1, ratio))

    local r, g, b
    if ratio < 0.5 then
        r = 1.0
        g = ratio * 2
        b = 0
    else
        r = 1.0 - ((ratio - 0.5) * 2)
        g = 1.0
        b = 0
    end

    local hex = string.format("%02X%02X%02X", r * 255, g * 255, b * 255)

    return r, g, b, hex
end

function KOL:GetColoredProgressString(instanceId, objectiveId, format)
    local progressStr = KOL:GetObjectiveProgressString(instanceId, objectiveId, format)
    local _, _, _, hex = KOL:GetObjectiveProgressColor(instanceId, objectiveId)
    return "|cFF" .. hex .. progressStr .. "|r"
end

-- ============================================================================
-- Speed Functions
-- ============================================================================

local BASE_RUN_SPEED = 7

function KOL:ReturnUserSpeed()
    local unit = UnitInVehicle("player") and "vehicle" or "player"
    local currentSpeed = GetUnitSpeed(unit)

    if not currentSpeed or currentSpeed == 0 then
        return 0
    end

    local speedPercent = (currentSpeed / BASE_RUN_SPEED) * 100
    local speedIncrease = math.floor(speedPercent - 100)

    return speedIncrease
end

function KOL:ReturnUserSpeedTotal()
    local unit = UnitInVehicle("player") and "vehicle" or "player"
    local currentSpeed = GetUnitSpeed(unit)

    if not currentSpeed or currentSpeed == 0 then
        return 100
    end

    return math.floor((currentSpeed / BASE_RUN_SPEED) * 100)
end

local speedDataDebugCount = 0
local speedDataDebugEnabled = false

function KOL:ReturnSpeedData()
    local dimAmber = "BB9955"
    local defaultData = {
        speedIncrease = 0,
        speedTotal = 100,
        color = dimAmber,
        glyph = CHAR_IDLE or "■",
        glyphName = nil,
        text = "IDLE",
        isMoving = false,
    }

    speedDataDebugCount = speedDataDebugCount + 1
    local shouldDebug = speedDataDebugEnabled and speedDataDebugCount <= 3

    if shouldDebug then
        print("|cFFFFFF00[SPEED DEBUG]|r ReturnSpeedData call #" .. speedDataDebugCount)
        print("|cFFFFFF00[SPEED DEBUG]|r CHAR_IDLE = '" .. tostring(CHAR_IDLE) .. "'")
        print("|cFFFFFF00[SPEED DEBUG]|r defaultData.glyph = '" .. tostring(defaultData.glyph) .. "'")
    end

    local speedIncrease = self:ReturnUserSpeed() or 0
    local speedTotal = self:ReturnUserSpeedTotal() or 100

    local unit = UnitInVehicle("player") and "vehicle" or "player"
    local currentSpeed = GetUnitSpeed(unit)
    local isMoving = currentSpeed and currentSpeed > 0

    local dimGreen = "77BB77"
    local dimRed = "BB6666"
    local dimLavender = "AA88CC"

    local color, glyph, glyphName, text

    if speedIncrease > 0 then
        color = dimGreen
        glyph = CHAR("UP") or "^"
        glyphName = "UP"
        text = "+" .. speedIncrease .. "%"
    elseif speedIncrease < 0 then
        color = dimRed
        glyph = CHAR("DOWN") or "v"
        glyphName = "DOWN"
        text = speedIncrease .. "%"
    elseif isMoving then
        color = dimLavender
        glyph = CHAR_BASE or "o"
        glyphName = nil
        text = "BASE"
    else
        if shouldDebug then
            print("|cFFFFFF00[SPEED DEBUG]|r Returning IDLE defaultData")
            print("|cFFFFFF00[SPEED DEBUG]|r defaultData.text = '" .. tostring(defaultData.text) .. "'")
        end
        return defaultData
    end

    local result = {
        speedIncrease = speedIncrease,
        speedTotal = speedTotal,
        color = color,
        glyph = glyph,
        glyphName = glyphName,
        text = text,
        isMoving = isMoving,
    }

    if shouldDebug then
        print("|cFFFFFF00[SPEED DEBUG]|r Returning moving data: text='" .. tostring(text) .. "', glyph='" .. tostring(glyph) .. "'")
    end

    return result
end

function KOL:ReturnSpeedText(includePrefix)
    local prefix = includePrefix and "SPEED: " or ""
    local data = self:ReturnSpeedData()

    local result = prefix .. "|cFF" .. data.color .. data.text .. "|r " .. data.glyph

    return result
end

KOL:DebugPrint("Functions: Global utility module loaded successfully!", 2)
