-- ============================================================================
-- !Koality-of-Life: Global Utility Functions
-- ============================================================================
-- Reusable functions that can be used across multiple modules
-- ============================================================================

local KOL = KoalityOfLife

-- ============================================================================
-- Inventory Scanning
-- ============================================================================

--[[
    Scans player inventory for an item by ID or name

    @param itemIDOrName: Item ID (number) or Item Name (string)
    @return found: boolean - true if item found, false otherwise
    @return count: number - total count of item across all bags

    Example usage:
        local found, count = KOL:ScanInventory(45902)
        if found then
            print("Found " .. count .. " items")
        end

    Performance notes:
        - Scans all bags (0-4) and all slots
        - Returns total count across all stacks
        - Type-checks parameter to determine search method (ID vs name)
]]
function KOL:ScanInventory(itemIDOrName)
    -- Validate input
    if not itemIDOrName then
        return false, 0
    end

    local searchType = type(itemIDOrName)
    local totalCount = 0

    -- Scan all bags
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)

            if itemLink then
                local matches = false

                -- Search by Item ID (fastest method)
                if searchType == "number" then
                    local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
                    matches = (itemID == itemIDOrName)

                -- Search by Item Name (slower, requires GetItemInfo call)
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

--[[
    Find the first location of an item in inventory (for using items)

    @param itemIDOrName: Item ID (number) or Item Name (string)
    @return found: boolean - true if item found
    @return bag: number or nil - bag index where item was found (0-4)
    @return slot: number or nil - slot index where item was found

    Example usage:
        local found, bag, slot = KOL:FindItemLocation(45902)
        if found then
            UseContainerItem(bag, slot)
        end
]]
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

--[[
    Scan player's bank for an item by ID or name

    @param itemIDOrName: Item ID (number) or Item Name (string)
    @return found: boolean - true if item found in bank
    @return count: number - total count in bank
    @return bankOpen: boolean - true if bank was accessible

    Note: Bank can only be scanned when the bank window is open.
    If bank is closed, returns found=false, count=0, bankOpen=false.

    Example usage:
        local found, count, bankOpen = KOL:ScanBank(12345)
        if not bankOpen then
            print("Visit a banker to check bank contents")
        end
]]
function KOL:ScanBank(itemIDOrName)
    if not itemIDOrName then
        return false, 0, false
    end

    local searchType = type(itemIDOrName)
    local totalCount = 0

    -- Check if bank is accessible (BANK_CONTAINER = -1)
    -- Bank is only accessible when the bank frame is open
    local bankOpen = false

    -- Try to access main bank slots (28 slots, container -1)
    -- NUM_BANKGENERIC_SLOTS = 28 in WotLK
    local BANK_CONTAINER = -1
    local NUM_BANK_SLOTS = 28

    for slot = 1, NUM_BANK_SLOTS do
        local itemLink = GetContainerItemLink(BANK_CONTAINER, slot)
        if itemLink then
            bankOpen = true  -- Bank is accessible
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

    -- Scan bank bags (bags 5-11)
    for bag = 5, 11 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots and numSlots > 0 then
            bankOpen = true  -- Has bank bags = bank is accessible
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

--[[
    Scan both inventory AND bank for an item

    @param itemIDOrName: Item ID (number) or Item Name (string)
    @return found: boolean - true if item found anywhere
    @return inventoryCount: number - count in bags (0-4)
    @return bankCount: number - count in bank (-1, 5-11)
    @return totalCount: number - combined total
    @return bankOpen: boolean - true if bank was accessible

    Example usage:
        local found, inv, bank, total, bankOpen = KOL:ScanAll(12345)
        print("Inventory: " .. inv)
        print("Bank: " .. bank .. (bankOpen and "" or " (closed)"))
        print("Total: " .. total)

    For tooltip display:
        local found, inv, bank, total = KOL:ScanAll(12345)
        -- Inventory: 5
        -- Bank: 12
        -- Total: 17
]]
function KOL:ScanAll(itemIDOrName)
    local _, inventoryCount = KOL:ScanInventory(itemIDOrName)
    local _, bankCount, bankOpen = KOL:ScanBank(itemIDOrName)

    local totalCount = inventoryCount + bankCount
    local found = totalCount > 0

    return found, inventoryCount, bankCount, totalCount, bankOpen
end

--[[
    Get a formatted breakdown string for item counts (for tooltips/alttext)

    @param itemIDOrName: Item ID (number) or Item Name (string)
    @return breakdownText: Multi-line string for display

    Example output:
        "Inventory: 5
         Bank: 12
         Total: 17"

    Or if bank is closed:
        "Inventory: 5
         Bank: ? (visit banker)
         Total: 5+"
]]
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

--[[
    Counts how many of a specific item exist in player inventory
    (Legacy function - use ScanInventory for combined found+count)

    @param itemIDOrName: Item ID (number) or Item Name (string)
    @return count: number - total count of item in inventory

    Example usage:
        local count = KOL:CountInventoryItem(45902)
        KOL:PrintTag("You have " .. count .. " Phantom Ghostfish")
]]
function KOL:CountInventoryItem(itemIDOrName)
    if not itemIDOrName then
        return 0
    end

    local searchType = type(itemIDOrName)
    local totalCount = 0

    -- Scan all bags
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)

            if itemLink then
                local matches = false

                -- Check by Item ID
                if searchType == "number" then
                    local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
                    matches = (itemID == itemIDOrName)

                -- Check by Item Name
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
-- Generic objective management that works with any tracker type
-- Supports both binary (complete/incomplete) and progress-based objectives
-- ============================================================================

-- Internal storage (syncs with KOL.db.profile.tracker on save)
local objectiveProgress = {}

--[[
    Initialize objective storage from saved data

    Called on addon load to restore objective state from database.
]]
function KOL:InitializeObjectives()
    if KOL.db and KOL.db.profile and KOL.db.profile.tracker then
        objectiveProgress = KOL.db.profile.tracker.objectiveProgress or {}
        KOL.db.profile.tracker.objectiveProgress = objectiveProgress
    end
end

--[[
    Mark an objective as complete

    @param instanceId: Instance/tracker identifier (e.g., "naxx10", "custom_tracker_1")
    @param objectiveId: Objective identifier (e.g., boss index, item name, "objective_1")
    @param options: Optional table { silent = false, skipRefresh = false }
    @return success: boolean - true if marked successfully

    Example usage:
        KOL:MarkObjectiveComplete("naxx10", 1)
        KOL:MarkObjectiveComplete("custom_tracker", "collect_items", { silent = true })
]]
function KOL:MarkObjectiveComplete(instanceId, objectiveId, options)
    if not instanceId or not objectiveId then
        return false
    end

    options = options or {}

    -- Initialize storage for this instance
    if not objectiveProgress[instanceId] then
        objectiveProgress[instanceId] = {}
    end

    -- Mark as complete (progress = max, or just true for binary)
    local existing = objectiveProgress[instanceId][objectiveId]
    if type(existing) == "table" and existing.max then
        -- Progress-based: set current = max
        existing.current = existing.max
        existing.complete = true
    else
        -- Binary objective
        objectiveProgress[instanceId][objectiveId] = {
            complete = true,
            current = 1,
            max = 1,
            timestamp = time()
        }
    end

    -- Save to database
    if KOL.db and KOL.db.profile and KOL.db.profile.tracker then
        KOL.db.profile.tracker.objectiveProgress = objectiveProgress
    end

    if not options.silent then
        KOL:DebugPrint("Objective complete: " .. tostring(instanceId) .. "/" .. tostring(objectiveId), 2)
    end

    -- Trigger UI refresh if needed
    if not options.skipRefresh and KOL.Tracker and KOL.Tracker.RefreshTrackerFrames then
        KOL.Tracker:RefreshTrackerFrames()
    end

    return true
end

--[[
    Update progress for a count-based objective

    @param instanceId: Instance/tracker identifier
    @param objectiveId: Objective identifier
    @param current: Current progress count
    @param max: Maximum/target count (optional, uses existing or defaults to current)
    @param options: Optional table { silent = false, skipRefresh = false, autoComplete = true }
    @return success: boolean
    @return isComplete: boolean - true if current >= max after update

    Example usage:
        KOL:UpdateObjectiveProgress("custom", "ore_collected", 5, 10)  -- [5/10]
        KOL:UpdateObjectiveProgress("custom", "ore_collected", 10)     -- [10/10] -> auto-complete

        -- Check for item and update progress
        local found, count = KOL:ScanInventory(12345)
        if found then
            KOL:UpdateObjectiveProgress("collect_quest", "rare_gem", count, 5)
        end
]]
function KOL:UpdateObjectiveProgress(instanceId, objectiveId, current, max, options)
    if not instanceId or not objectiveId then
        return false, false
    end

    options = options or {}
    local autoComplete = options.autoComplete ~= false  -- Default true

    -- Initialize storage
    if not objectiveProgress[instanceId] then
        objectiveProgress[instanceId] = {}
    end

    -- Get or create objective data
    local obj = objectiveProgress[instanceId][objectiveId]
    if type(obj) ~= "table" then
        obj = { current = 0, max = max or current, complete = false }
        objectiveProgress[instanceId][objectiveId] = obj
    end

    -- Update values
    obj.current = current or obj.current
    if max then
        obj.max = max
    end
    obj.timestamp = time()

    -- Check for completion
    local isComplete = obj.current >= obj.max
    if isComplete and autoComplete then
        obj.complete = true
    end

    -- Save to database
    if KOL.db and KOL.db.profile and KOL.db.profile.tracker then
        KOL.db.profile.tracker.objectiveProgress = objectiveProgress
    end

    if not options.silent then
        KOL:DebugPrint("Objective progress: " .. tostring(instanceId) .. "/" .. tostring(objectiveId) ..
            " [" .. obj.current .. "/" .. obj.max .. "]" .. (isComplete and " COMPLETE" or ""), 3)
    end

    -- Trigger UI refresh
    if not options.skipRefresh and KOL.Tracker and KOL.Tracker.RefreshTrackerFrames then
        KOL.Tracker:RefreshTrackerFrames()
    end

    return true, isComplete
end

--[[
    Check if an objective is complete

    @param instanceId: Instance/tracker identifier
    @param objectiveId: Objective identifier
    @return isComplete: boolean

    Example usage:
        if KOL:IsObjectiveComplete("naxx10", 1) then
            print("Boss already killed!")
        end
]]
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

    -- Legacy boolean format
    return obj == true
end

--[[
    Get objective progress

    @param instanceId: Instance/tracker identifier
    @param objectiveId: Objective identifier
    @return current: number - current progress (0 if not found)
    @return max: number - maximum/target (0 if not found)
    @return isComplete: boolean

    Example usage:
        local current, max, done = KOL:GetObjectiveProgress("custom", "collect_ore")
        print(string.format("Progress: [%d/%d] %s", current, max, done and "DONE" or ""))
]]
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

    -- Legacy boolean format (binary complete)
    if obj == true then
        return 1, 1, true
    end

    return 0, 0, false
end

--[[
    Reset an objective to incomplete state

    @param instanceId: Instance/tracker identifier
    @param objectiveId: Objective identifier (or nil to reset ALL objectives for instance)
    @param options: Optional table { silent = false, skipRefresh = false, keepMax = true }
    @return success: boolean

    Example usage:
        KOL:ResetObjective("naxx10", 1)           -- Reset single objective
        KOL:ResetObjective("naxx10")              -- Reset ALL objectives for naxx10
        KOL:ResetObjective("custom", "ore", { keepMax = false })  -- Reset and clear max
]]
function KOL:ResetObjective(instanceId, objectiveId, options)
    if not instanceId then
        return false
    end

    options = options or {}
    local keepMax = options.keepMax ~= false  -- Default true

    if objectiveId then
        -- Reset single objective
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
        -- Reset ALL objectives for this instance
        objectiveProgress[instanceId] = {}
    end

    -- Save to database
    if KOL.db and KOL.db.profile and KOL.db.profile.tracker then
        KOL.db.profile.tracker.objectiveProgress = objectiveProgress
    end

    if not options.silent then
        KOL:DebugPrint("Objective reset: " .. tostring(instanceId) ..
            (objectiveId and ("/" .. tostring(objectiveId)) or " (all)"), 2)
    end

    -- Trigger UI refresh
    if not options.skipRefresh and KOL.Tracker and KOL.Tracker.RefreshTrackerFrames then
        KOL.Tracker:RefreshTrackerFrames()
    end

    return true
end

--[[
    Scan inventory and auto-update objective progress

    Convenience function that combines ScanInventory with UpdateObjectiveProgress.

    @param instanceId: Instance/tracker identifier
    @param objectiveId: Objective identifier
    @param itemIDOrName: Item to scan for
    @param targetCount: Target amount needed for completion
    @param options: Optional table { silent = false, skipRefresh = false }
    @return found: boolean - item exists in inventory
    @return current: number - current count in inventory
    @return isComplete: boolean - true if count >= target

    Example usage:
        local found, count, done = KOL:ScanAndUpdateObjective("quest", "rare_gem", 12345, 5)
        if done then
            KOL:PrintTag("You have enough gems!")
        end
]]
function KOL:ScanAndUpdateObjective(instanceId, objectiveId, itemIDOrName, targetCount, options)
    local found, count = KOL:ScanInventory(itemIDOrName)

    options = options or {}
    local _, isComplete = KOL:UpdateObjectiveProgress(instanceId, objectiveId, count, targetCount, options)

    return found, count, isComplete
end

--[[
    Get formatted progress string for display

    @param instanceId: Instance/tracker identifier
    @param objectiveId: Objective identifier
    @param format: Optional format string (default "[%d/%d]")
    @return formatted: string - formatted progress like "[5/10]"

    Example usage:
        local progress = KOL:GetObjectiveProgressString("custom", "ore")  -- "[5/10]"
]]
function KOL:GetObjectiveProgressString(instanceId, objectiveId, format)
    local current, max = KOL:GetObjectiveProgress(instanceId, objectiveId)
    format = format or "[%d/%d]"
    return string.format(format, current, max)
end

--[[
    Increment objective progress by a delta

    @param instanceId: Instance/tracker identifier
    @param objectiveId: Objective identifier
    @param delta: Amount to add (default 1)
    @param max: Max value (optional, uses existing)
    @param options: Optional table { silent = false, skipRefresh = false }
    @return success: boolean
    @return newCurrent: number
    @return isComplete: boolean

    Example usage:
        KOL:IncrementObjective("quest", "kills", 1, 10)  -- Adds 1 kill toward 10
        KOL:IncrementObjective("quest", "kills")         -- Adds 1 to existing
]]
function KOL:IncrementObjective(instanceId, objectiveId, delta, max, options)
    delta = delta or 1

    local current = KOL:GetObjectiveProgress(instanceId, objectiveId)
    local newCurrent = current + delta

    local success, isComplete = KOL:UpdateObjectiveProgress(instanceId, objectiveId, newCurrent, max, options)
    return success, newCurrent, isComplete
end

--[[
    Get a gradient color based on objective progress (0% = red, 100% = green)

    @param instanceId: Instance/tracker identifier
    @param objectiveId: Objective identifier
    @return r, g, b: RGB values (0-1)
    @return hexColor: Hex color string like "FF6666"

    Example usage:
        local r, g, b, hex = KOL:GetObjectiveProgressColor("quest", "ore")
        myText:SetTextColor(r, g, b)
        -- or
        local coloredText = "|cFF" .. hex .. progressString .. "|r"
]]
function KOL:GetObjectiveProgressColor(instanceId, objectiveId)
    local current, max, isComplete = KOL:GetObjectiveProgress(instanceId, objectiveId)

    -- Handle edge cases
    if max == 0 then
        return 0.5, 0.5, 0.5, "808080"  -- Gray for undefined
    end

    if isComplete then
        return 0.4, 1.0, 0.4, "66FF66"  -- Bright green for complete
    end

    -- Calculate progress ratio (0 to 1)
    local ratio = current / max
    ratio = math.max(0, math.min(1, ratio))  -- Clamp to 0-1

    -- Gradient: Red (0%) -> Yellow (50%) -> Green (100%)
    local r, g, b
    if ratio < 0.5 then
        -- Red to Yellow
        r = 1.0
        g = ratio * 2
        b = 0
    else
        -- Yellow to Green
        r = 1.0 - ((ratio - 0.5) * 2)
        g = 1.0
        b = 0
    end

    -- Convert to hex
    local hex = string.format("%02X%02X%02X", r * 255, g * 255, b * 255)

    return r, g, b, hex
end

--[[
    Get colored progress string with gradient based on completion

    @param instanceId: Instance/tracker identifier
    @param objectiveId: Objective identifier
    @param format: Optional format string (default "[%d/%d]")
    @return coloredString: WoW-formatted color string like "|cFFFF6666[2/10]|r"

    Example usage:
        local text = KOL:GetColoredProgressString("quest", "ore")  -- "|cFFFFCC00[5/10]|r"
]]
function KOL:GetColoredProgressString(instanceId, objectiveId, format)
    local progressStr = KOL:GetObjectiveProgressString(instanceId, objectiveId, format)
    local _, _, _, hex = KOL:GetObjectiveProgressColor(instanceId, objectiveId)
    return "|cFF" .. hex .. progressStr .. "|r"
end

-- ============================================================================
-- Module Loaded
-- ============================================================================

KOL:DebugPrint("Functions: Global utility module loaded successfully!", 2)
