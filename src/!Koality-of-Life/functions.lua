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
    @return bag: number or nil - bag index where item was found (0-4)
    @return slot: number or nil - slot index where item was found

    Example usage:
        local found = KOL:ScanInventory(45902)  -- Check by ID
        local found, bag, slot = KOL:ScanInventory("Phantom Ghostfish")  -- Check by name with position

    Performance notes:
        - Scans all bags (0-4) and all slots
        - Returns immediately when first match is found
        - Type-checks parameter to determine search method (ID vs name)
]]
function KOL:ScanInventory(itemIDOrName)
    -- Validate input
    if not itemIDOrName then
        return false, nil, nil
    end

    local searchType = type(itemIDOrName)

    -- Scan all bags
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)

            if itemLink then
                -- Search by Item ID (fastest method)
                if searchType == "number" then
                    local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
                    if itemID == itemIDOrName then
                        return true, bag, slot
                    end

                -- Search by Item Name (slower, requires GetItemInfo call)
                elseif searchType == "string" then
                    local itemName = GetItemInfo(itemLink)
                    if itemName and itemName == itemIDOrName then
                        return true, bag, slot
                    end
                end
            end
        end
    end

    -- Item not found
    return false, nil, nil
end

--[[
    Counts how many of a specific item exist in player inventory

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
-- Module Loaded
-- ============================================================================

KOL:DebugPrint("Functions: Global utility module loaded successfully!", 2)
