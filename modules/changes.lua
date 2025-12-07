-- Koality-of-Life: Changes Module
-- Custom UI modifications for third-party addon frames

local addonName = "Koality-of-Life"
local KOL = KoalityOfLife
local LSM = LibStub("LibSharedMedia-3.0")

-- Create module
local Changes = {}
KOL.changes = Changes

-- Module defaults
local moduleDefaults = {
    pfQuest = {
        enabled = true,
        font = "Friz Quadrata TT",
        fontSize = 14,
        fontOutline = "THICKOUTLINE",
    },
    itemTracker = {
        enabled = true,
        -- Zone headers (ItemHuntFrameHeader)
        zoneFont = "Friz Quadrata TT",
        zoneFontSize = 14,
        zoneFontOutline = "THICKOUTLINE",
        -- NPCs/Mobs (ItemHuntFrameObj#)
        npcFont = "Friz Quadrata TT",
        npcFontSize = 14,
        npcFontOutline = "THICKOUTLINE",
        -- Items/Loot (ItemHuntFrameItem#)
        itemFont = "Friz Quadrata TT",
        itemFontSize = 14,
        itemFontOutline = "THICKOUTLINE",
        -- Limits (ItemHuntFrameLimit#)
        limitFont = "Friz Quadrata TT",
        limitFontSize = 14,
        limitFontOutline = "THICKOUTLINE",
    },
}

-- Track if we've successfully applied fonts (batch system will check this)
local pfQuestFontsApplied = false

-- Track which ItemHunt frames we've already applied fonts to
local itemHuntFontsApplied = {}

-- Track what settings we last applied (so we can detect user changes)
local lastAppliedSettings = {
    zoneFont = nil,
    zoneFontSize = nil,
    zoneFontOutline = nil,
    npcFont = nil,
    npcFontSize = nil,
    npcFontOutline = nil,
    itemFont = nil,
    itemFontSize = nil,
    itemFontOutline = nil,
    limitFont = nil,
    limitFontSize = nil,
    limitFontOutline = nil,
}

-- Font outline options
local fontOutlineOptions = {
    ["NONE"] = "None",
    ["OUTLINE"] = "Outline",
    ["THICKOUTLINE"] = "Thick Outline",
    ["MONOCHROME"] = "Monochrome",
    ["OUTLINE, MONOCHROME"] = "Outline + Monochrome",
    ["THICKOUTLINE, MONOCHROME"] = "Thick Outline + Monochrome",
}

-- ============================================================================
-- Module Initialization
-- ============================================================================

-- Start batch system for pfQuest font application
function Changes:StartPfQuestBatch()
    -- Configure the pfQuest batch channel
    KOL:BatchConfigure("pfQuest", {
        interval = 2.0,         -- Start checking every 2 seconds
        processMode = "all",    -- Run all queued actions each tick
        triggerMode = "interval", -- Timer-based
        maxQueueSize = 5,       -- Reasonable limit - we only need 1-2 actions max
    })

    -- Add the font application action
    KOL:BatchAdd("pfQuest", "applyFonts", function()
        if pfQuestFontsApplied then
            return  -- Fonts already applied successfully
        end

        Changes:ApplyPfQuestFont()

        -- Check if successful
        if Changes:CheckPfQuestFontsApplied() then
            pfQuestFontsApplied = true
            KOL:DebugPrint("Changes: Fonts successfully applied via batch!", 1)
        end
    end, 2)  -- HIGH priority

    -- Start the batch
    KOL:BatchStart("pfQuest")

    -- Aggressive phase: speed up temporarily (9-20 seconds)
    C_Timer.After(5, function()
        KOL:BatchConfigure("pfQuest", { interval = 1.0 })  -- Every 1s from 5-20s
    end)

    -- Slow down after 20 seconds
    C_Timer.After(20, function()
        KOL:BatchConfigure("pfQuest", { interval = 5.0 })  -- Every 5s after 20s
    end)

    KOL:DebugPrint("Changes: Started pfQuest batch system", 1)
end

function Changes:Initialize()
    -- Register module defaults
    if not KOL.db.profile.changes then
        KOL.db.profile.changes = {}
    end

    -- Apply defaults for pfQuest
    if not KOL.db.profile.changes.pfQuest then
        KOL.db.profile.changes.pfQuest = {}
    end
    for key, value in pairs(moduleDefaults.pfQuest) do
        if KOL.db.profile.changes.pfQuest[key] == nil then
            KOL.db.profile.changes.pfQuest[key] = value
        end
    end

    -- Apply defaults for itemTracker
    if not KOL.db.profile.changes.itemTracker then
        KOL.db.profile.changes.itemTracker = {}
    end
    for key, value in pairs(moduleDefaults.itemTracker) do
        if KOL.db.profile.changes.itemTracker[key] == nil then
            KOL.db.profile.changes.itemTracker[key] = value
        end
    end

    -- Initialize config UI
    self:InitializeConfig()

    -- Register event callbacks for applying changes
    KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
        pfQuestFontsApplied = false
        Changes:ApplyAllChanges()

        -- Start batch system for pfQuest
        Changes:StartPfQuestBatch()

        -- Start batch system for ItemHunt
        Changes:StartItemHuntBatch()
    end, "Changes")

    -- Reset ItemHunt tracking on zone changes (frames may be recreated)
    KOL:RegisterEventCallback("ZONE_CHANGED", function()
        Changes:ResetItemHuntTracking()
    end, "Changes")

    KOL:RegisterEventCallback("ZONE_CHANGED_NEW_AREA", function()
        Changes:ResetItemHuntTracking()
    end, "Changes")

    KOL:RegisterEventCallback("ZONE_CHANGED_INDOORS", function()
        Changes:ResetItemHuntTracking()
    end, "Changes")

    KOL:RegisterEventCallback("ADDON_LOADED", function(addonName)
        Changes:OnAddonLoaded(addonName)
    end, "Changes")

    -- Apply on EVERY quest-related event
    KOL:RegisterEventCallback("QUEST_LOG_UPDATE", function()
        Changes:ApplyPfQuestFont()
    end, "Changes")

    KOL:RegisterEventCallback("QUEST_WATCH_UPDATE", function()
        Changes:ApplyPfQuestFont()
    end, "Changes")

    KOL:RegisterEventCallback("QUEST_ACCEPTED", function()
        Changes:ApplyPfQuestFont()
    end, "Changes")

    KOL:RegisterEventCallback("QUEST_TURNED_IN", function()
        Changes:ApplyPfQuestFont()
    end, "Changes")

    KOL:RegisterEventCallback("QUEST_COMPLETE", function()
        Changes:ApplyPfQuestFont()
    end, "Changes")

    KOL:RegisterEventCallback("UNIT_QUEST_LOG_CHANGED", function()
        Changes:ApplyPfQuestFont()
    end, "Changes")

    KOL:DebugPrint("Changes: Module initialized")
end

-- ============================================================================
-- pfQuest Font Changes
-- ============================================================================

-- Check if fonts are already correctly applied
function Changes:CheckPfQuestFontsApplied()
    if not pfQuestMapTracker or not pfQuestMapTracker.buttons then
        return false
    end

    local settings = KOL.db.profile.changes.pfQuest
    local targetFontPath = LSM:Fetch("font", settings.font)

    if not targetFontPath then
        return false
    end

    -- Check if at least one button has the correct font
    for id, button in pairs(pfQuestMapTracker.buttons) do
        if button.text then
            local currentFont = button.text:GetFont()
            if currentFont == targetFontPath then
                return true  -- Font is correctly applied
            end
        end
    end

    return false  -- No buttons or fonts don't match
end

function Changes:ApplyPfQuestFont()
    if not KOL.db.profile.changes.pfQuest.enabled then
        return
    end

    -- Check if pfQuest tracker exists (correct frame name: pfQuestMapTracker)
    if not pfQuestMapTracker then
        return
    end

    if not pfQuestMapTracker.buttons then
        return
    end

    -- Count how many buttons exist
    local totalButtons = 0
    for _ in pairs(pfQuestMapTracker.buttons) do
        totalButtons = totalButtons + 1
    end

    if totalButtons == 0 then
        return  -- No buttons to apply fonts to
    end

    local settings = KOL.db.profile.changes.pfQuest
    local fontPath = LSM:Fetch("font", settings.font)

    if not fontPath then
        KOL:DebugPrint("Changes: Font '" .. settings.font .. "' not found for pfQuest")
        return
    end

    -- Apply font to all tracker buttons
    local buttonCount = 0
    local objectiveCount = 0

    for id, button in pairs(pfQuestMapTracker.buttons) do
        -- Update button text
        if button.text then
            local success, err = pcall(function()
                button.text:SetFont(fontPath, settings.fontSize, settings.fontOutline)
            end)
            if success then
                buttonCount = buttonCount + 1
            end
        end

        -- Update objective texts
        if button.objectives then
            for i, objective in pairs(button.objectives) do
                local success, err = pcall(function()
                    objective:SetFont(fontPath, settings.fontSize, settings.fontOutline)
                end)
                if success then
                    objectiveCount = objectiveCount + 1
                end
            end
        end
    end

    -- Mark as successfully applied if we updated buttons
    if buttonCount > 0 then
        pfQuestFontsApplied = true
        KOL:DebugPrint("Changes: Applied font to pfQuest - " .. settings.font .. ", " .. settings.fontSize .. ", " .. settings.fontOutline .. " (" .. buttonCount .. " buttons, " .. objectiveCount .. " objectives)", 3)
    end
end

-- ============================================================================
-- ItemTracker Font Changes
-- ============================================================================

-- Apply font to a single ItemHunt frame (button)
local function ApplyFontToItemHuntFrame(frame, fontPath, fontSize, fontOutline, frameName)
    -- Check if we've already applied fonts to this frame and they're still correct
    if itemHuntFontsApplied[frameName] then
        -- Verify font is still correct (in case ItemHunt reset it)
        local regionCount = (frame.GetNumRegions and frame:GetNumRegions()) or 0
        if regionCount > 0 then
            local region = select(1, frame:GetRegions())
            if region and region:GetObjectType() == "FontString" then
                local currentFont, currentSize, currentFlags = region:GetFont()
                -- Only check font path and size (flags can be finicky)
                if currentFont == fontPath and math.abs((currentSize or 0) - fontSize) < 0.1 then
                    -- Font is still correct, skip this frame entirely
                    return 0
                end
            end
        end
    end

    local fontStringsUpdated = 0

    KOL:DebugPrint("Changes: Checking " .. frameName .. " for FontStrings...", 5)

    -- Check regions for FontStrings
    local regionCount = (frame.GetNumRegions and frame:GetNumRegions()) or 0
    KOL:DebugPrint("Changes:   Region count: " .. regionCount, 5)

    if regionCount > 0 then
        for i = 1, regionCount do
            local region = select(i, frame:GetRegions())
            if region then
                local objType = region:GetObjectType()
                KOL:DebugPrint("Changes:   Region " .. i .. " type: " .. objType, 5)

                if objType == "FontString" then
                    local currentFont, currentSize, currentFlags = region:GetFont()

                    -- Only compare font path and size (ignore flags - they can be finicky)
                    local fontMatches = (currentFont == fontPath)
                    local sizeMatches = (math.abs((currentSize or 0) - fontSize) < 0.1)

                    if not fontMatches or not sizeMatches then
                        KOL:DebugPrint("Changes:   Font needs update: " .. (currentFont or "nil") .. " -> " .. fontPath, 5)

                        local success, err = pcall(function()
                            region:SetFont(fontPath, fontSize, fontOutline)
                        end)
                        if success then
                            fontStringsUpdated = fontStringsUpdated + 1
                            KOL:DebugPrint("Changes:   Successfully set font!", 5)
                        else
                            KOL:DebugPrint("Changes:   ERROR setting font: " .. tostring(err), 1)
                        end
                    else
                        -- Font is already correct, skip
                        KOL:DebugPrint("Changes:   Font already correct, skipping", 5)
                    end
                end
            end
        end
    end

    -- Also check common properties (text, label, etc.)
    local props = {"text", "label", "title", "Text", "Label", "Title"}
    for _, prop in ipairs(props) do
        if frame[prop] and frame[prop].SetFont and frame[prop].GetFont then
            local currentFont, currentSize, currentFlags = frame[prop]:GetFont()

            -- Only compare font path and size (ignore flags - they can be finicky)
            local fontMatches = (currentFont == fontPath)
            local sizeMatches = (math.abs((currentSize or 0) - fontSize) < 0.1)

            if not fontMatches or not sizeMatches then
                KOL:DebugPrint("Changes:   Property " .. prop .. " needs update", 5)
                local success, err = pcall(function()
                    frame[prop]:SetFont(fontPath, fontSize, fontOutline)
                end)
                if success then
                    fontStringsUpdated = fontStringsUpdated + 1
                    KOL:DebugPrint("Changes:   Successfully set font on " .. prop, 5)
                else
                    KOL:DebugPrint("Changes:   ERROR setting font on " .. prop .. ": " .. tostring(err), 1)
                end
            else
                KOL:DebugPrint("Changes:   Property " .. prop .. " already correct, skipping", 5)
            end
        end
    end

    KOL:DebugPrint("Changes:   Total FontStrings updated: " .. fontStringsUpdated, 5)

    -- Mark this frame as having fonts applied (only if we actually updated something)
    if fontStringsUpdated > 0 then
        itemHuntFontsApplied[frameName] = true
        KOL:DebugPrint("Changes:   Marked " .. frameName .. " as font-applied", 5)
    end

    return fontStringsUpdated
end

-- Scan and apply fonts to all ItemHunt frames
function Changes:ScanAndApplyItemHuntFonts()
    if not KOL.db.profile.changes.itemTracker.enabled then
        return 0
    end

    local settings = KOL.db.profile.changes.itemTracker

    -- Check if user changed settings - if so, clear tracking and force re-apply
    local settingsChanged = false
    for settingKey, settingValue in pairs(lastAppliedSettings) do
        if settings[settingKey] ~= settingValue then
            settingsChanged = true
            KOL:DebugPrint("Changes: Setting changed - " .. settingKey .. ": " .. tostring(settingValue) .. " -> " .. tostring(settings[settingKey]), 3)
            break
        end
    end

    if settingsChanged then
        itemHuntFontsApplied = {}
        KOL:DebugPrint("Changes: User changed settings, clearing font tracking", 3)
        -- Update our tracking
        for settingKey, _ in pairs(lastAppliedSettings) do
            lastAppliedSettings[settingKey] = settings[settingKey]
        end
    end

    local totalUpdated = 0
    local framesScanned = 0
    local framesSkipped = 0

    -- Scan ItemHuntFrameItem1 through ItemHuntFrameItem50 (Items/Loot)
    local itemFontPath = LSM:Fetch("font", settings.itemFont)
    if itemFontPath then
        for i = 1, 50 do
            local frameName = "ItemHuntFrameItem" .. i
            local frame = _G[frameName]
            if frame and frame:IsVisible() then
                framesScanned = framesScanned + 1
                local updated = ApplyFontToItemHuntFrame(frame, itemFontPath, settings.itemFontSize, settings.itemFontOutline, frameName)
                if updated == 0 and itemHuntFontsApplied[frameName] then
                    framesSkipped = framesSkipped + 1
                end
                totalUpdated = totalUpdated + updated
            end
        end
    end

    -- Scan ItemHuntFrameObj1 through ItemHuntFrameObj20 (NPCs/Mobs)
    local npcFontPath = LSM:Fetch("font", settings.npcFont)
    if npcFontPath then
        for i = 1, 20 do
            local frameName = "ItemHuntFrameObj" .. i
            local frame = _G[frameName]
            if frame and frame:IsVisible() then
                framesScanned = framesScanned + 1
                local updated = ApplyFontToItemHuntFrame(frame, npcFontPath, settings.npcFontSize, settings.npcFontOutline, frameName)
                if updated == 0 and itemHuntFontsApplied[frameName] then
                    framesSkipped = framesSkipped + 1
                end
                totalUpdated = totalUpdated + updated
            end
        end
    end

    -- Scan ItemHuntFrameLimit1 through ItemHuntFrameLimit50 (Limits)
    local limitFontPath = LSM:Fetch("font", settings.limitFont)
    if limitFontPath then
        for i = 1, 50 do
            local frameName = "ItemHuntFrameLimit" .. i
            local frame = _G[frameName]
            if frame and frame:IsVisible() then
                framesScanned = framesScanned + 1
                local updated = ApplyFontToItemHuntFrame(frame, limitFontPath, settings.limitFontSize, settings.limitFontOutline, frameName)
                if updated == 0 and itemHuntFontsApplied[frameName] then
                    framesSkipped = framesSkipped + 1
                end
                totalUpdated = totalUpdated + updated
            end
        end
    end

    -- Scan headers and other frames (Zone headers)
    local zoneFontPath = LSM:Fetch("font", settings.zoneFont)
    if zoneFontPath then
        local otherFrames = {"ItemHuntFrameHeader", "ItemHuntFrameObjLimit"}
        for _, frameName in ipairs(otherFrames) do
            local frame = _G[frameName]
            if frame and frame:IsVisible() then
                framesScanned = framesScanned + 1
                local updated = ApplyFontToItemHuntFrame(frame, zoneFontPath, settings.zoneFontSize, settings.zoneFontOutline, frameName)
                if updated == 0 and itemHuntFontsApplied[frameName] then
                    framesSkipped = framesSkipped + 1
                end
                totalUpdated = totalUpdated + updated
            end
        end
    end

    -- Only log if we actually did work
    if totalUpdated > 0 then
        KOL:DebugPrint("Changes: Scanner tick - " .. totalUpdated .. " FontStrings updated, " .. framesSkipped .. " frames skipped (already correct)", 3)
    elseif framesSkipped > 0 then
        KOL:DebugPrint("Changes: Scanner tick - All " .. framesSkipped .. " frames already have correct fonts", 5)
    end

    return framesScanned
end

-- Start batch system for ItemHunt font scanning
function Changes:StartItemHuntBatch()
    if self.itemHuntScannerActive then
        return  -- Already running
    end

    self.itemHuntScannerActive = true

    -- Initialize lastAppliedSettings with current settings
    local settings = KOL.db.profile.changes.itemTracker
    for settingKey, _ in pairs(lastAppliedSettings) do
        lastAppliedSettings[settingKey] = settings[settingKey]
    end

    -- Configure the itemHunt batch channel
    KOL:BatchConfigure("itemHunt", {
        interval = 0.5,         -- Scan every 0.5 seconds (fast!)
        processMode = "all",    -- Run all queued actions each tick
        triggerMode = "interval", -- Timer-based
        maxQueueSize = 5,       -- Reasonable limit - we only need 1 scanner action
    })

    -- Add scanning action for all font types
    -- ItemHunt resets fonts when scrolling, so we ALWAYS reapply
    KOL:BatchAdd("itemHunt", "scanAll", function()
        Changes:ScanAndApplyItemHuntFonts()
    end, 3)  -- NORMAL priority

    -- Start the batch
    KOL:BatchStart("itemHunt")

    KOL:DebugPrint("Changes: Started ItemHunt batch scanner (every 0.5s)", 3)
end

-- Stop scanning (for zone changes, reset tracking)
function Changes:ResetItemHuntTracking()
    itemHuntFontsApplied = {}
    self.itemHuntScannerActive = false  -- Allow scanner to restart
    KOL:DebugPrint("Changes: Reset ItemHunt font tracking", 3)
    -- Restart scanner
    self:StartItemHuntBatch()
end

-- Legacy function for compatibility
function Changes:ApplyItemTrackerFont()
    -- Clear tracking cache to force re-application (user changed settings)
    itemHuntFontsApplied = {}
    KOL:DebugPrint("Changes: Cleared ItemHunt font tracking (settings changed)", 3)
    self:ScanAndApplyItemHuntFonts()
end

-- ============================================================================
-- Apply All Changes
-- ============================================================================

function Changes:ApplyAllChanges()
    self:ApplyPfQuestFont()
    self:ApplyItemTrackerFont()
end

-- Handle addon loaded event
function Changes:OnAddonLoaded(loadedAddon)
    if loadedAddon == "pfQuest" then
        KOL:DebugPrint("Changes: pfQuest addon loaded, attempting to apply fonts...")
        pfQuestFontsApplied = false

        -- Try immediately
        Changes:ApplyPfQuestFont()

        -- Start batch system for continuous attempts
        Changes:StartPfQuestBatch()
    end

    if loadedAddon == "Koality-of-Life" then
        KOL:DebugPrint("Changes: Koality-of-Life reloaded, attempting to apply fonts...")
        pfQuestFontsApplied = false
        Changes:ApplyAllChanges()
        Changes:StartPfQuestBatch()
    end
end

-- ============================================================================
-- Configuration UI
-- ============================================================================

function Changes:InitializeConfig()
    -- Create main Changes group with sub-tabs
    if not KOL.configGroups.changes then
        KOL.configGroups.changes = {
            type = "group",
            name = "|cFFFF6B6BChanges|r",
            order = 40,
            childGroups = "tab",  -- This makes children appear as tabs!
            args = {}
        }
        KOL.configOptions.args.changes = KOL.configGroups.changes
    end

    -- ========================================================================
    -- pfQuest Sub-Tab
    -- ========================================================================
    if not KOL.configGroups.changes.args.pfquest_tab then
        KOL.configGroups.changes.args.pfquest_tab = {
            type = "group",
            name = "pfQuest",
            order = 1,
            args = {}
        }
    end
    local pfquestTab = KOL.configGroups.changes.args.pfquest_tab.args

    -- Header
    pfquestTab.header = {
        type = "description",
        name = "|cFFFFFFFFpfQuest Font Customization|r\n|cFFAAAAAACustomize the font appearance for pfQuest tracker.|r\n",
        fontSize = "medium",
        order = 1,
    }

    -- Enable toggle
    pfquestTab.enabled = {
        type = "toggle",
        name = "Enable pfQuest Font Changes",
        desc = "Enable custom font settings for pfQuest tracker",
        order = 2,
        get = function()
            return KOL.db.profile.changes.pfQuest.enabled
        end,
        set = function(_, value)
            KOL.db.profile.changes.pfQuest.enabled = value
            Changes:ApplyPfQuestFont()
            KOL:PrintTag("pfQuest font changes " .. (value and GREEN("enabled") or RED("disabled")))
        end,
    }

    -- Font settings inline group
    pfquestTab.settings = {
        type = "group",
        name = "",
        inline = true,
        order = 3,
        args = {
            spacer1 = {
                type = "description",
                name = " ",
                width = "full",
                order = 0.5,
            },
            font = {
                type = "select",
                name = "Font",
                desc = "Select the font to use for pfQuest tracker",
                dialogControl = "LSM30_Font",
                values = LSM:HashTable("font"),
                order = 1,
                get = function()
                    return KOL.db.profile.changes.pfQuest.font
                end,
                set = function(_, value)
                    KOL.db.profile.changes.pfQuest.font = value
                    Changes:ApplyPfQuestFont()
                    KOL:PrintTag("pfQuest font changed to: " .. YELLOW(value))
                end,
            },
            fontSize = {
                type = "input",
                name = "Size",
                desc = "Font size (6-32)",
                order = 2,
                width = "half",
                get = function()
                    return tostring(KOL.db.profile.changes.pfQuest.fontSize)
                end,
                set = function(_, value)
                    local size = tonumber(value)
                    if size and size >= 6 and size <= 32 then
                        KOL.db.profile.changes.pfQuest.fontSize = size
                        Changes:ApplyPfQuestFont()
                        KOL:PrintTag("pfQuest font size changed to: " .. YELLOW(size))
                    else
                        KOL:PrintTag(RED("Error:") .. " Font size must be between 6 and 32")
                    end
                end,
            },
            fontOutline = {
                type = "select",
                name = "Outline",
                desc = "Select the outline style for the font",
                values = fontOutlineOptions,
                order = 3,
                get = function()
                    return KOL.db.profile.changes.pfQuest.fontOutline
                end,
                set = function(_, value)
                    KOL.db.profile.changes.pfQuest.fontOutline = value
                    Changes:ApplyPfQuestFont()
                    KOL:PrintTag("pfQuest font outline changed to: " .. YELLOW(fontOutlineOptions[value]))
                end,
            },
        }
    }

    -- ========================================================================
    -- ItemTracker Sub-Tab
    -- ========================================================================
    if not KOL.configGroups.changes.args.itemtracker_tab then
        KOL.configGroups.changes.args.itemtracker_tab = {
            type = "group",
            name = "ItemTracker",
            order = 2,
            args = {}
        }
    end
    local itemtrackerTab = KOL.configGroups.changes.args.itemtracker_tab.args

    -- Header
    itemtrackerTab.header = {
        type = "description",
        name = "|cFFFFFFFFItemTracker Font Customization|r\n|cFFAAAAAACustomize fonts for different ItemHunt elements (zones, NPCs, items, limits).|r\n",
        fontSize = "medium",
        order = 1,
    }

    -- Enable toggle
    itemtrackerTab.enabled = {
        type = "toggle",
        name = "Enable ItemTracker Font Changes",
        desc = "Enable custom font settings for ItemTracker",
        order = 2,
        get = function()
            return KOL.db.profile.changes.itemTracker.enabled
        end,
        set = function(_, value)
            KOL.db.profile.changes.itemTracker.enabled = value
            Changes:ApplyItemTrackerFont()
            KOL:PrintTag("ItemTracker font changes " .. (value and GREEN("enabled") or RED("disabled")))
        end,
    }

    -- Zone Headers Group
    itemtrackerTab.zone = {
        type = "group",
        name = "Zone Headers",
        inline = true,
        order = 3,
        args = {
            font = {
                type = "select",
                name = "Font",
                desc = "Font for zone headers (e.g., 'Sholazar Basin')",
                dialogControl = "LSM30_Font",
                values = LSM:HashTable("font"),
                order = 1,
                get = function() return KOL.db.profile.changes.itemTracker.zoneFont end,
                set = function(_, value)
                    KOL.db.profile.changes.itemTracker.zoneFont = value
                    Changes:ApplyItemTrackerFont()
                end,
            },
            fontSize = {
                type = "range",
                name = "Size",
                desc = "Font size for zone headers",
                min = 6,
                max = 32,
                step = 1,
                order = 2,
                get = function() return KOL.db.profile.changes.itemTracker.zoneFontSize end,
                set = function(_, value)
                    KOL.db.profile.changes.itemTracker.zoneFontSize = value
                    Changes:ApplyItemTrackerFont()
                end,
            },
            fontOutline = {
                type = "select",
                name = "Outline",
                desc = "Outline style for zone headers",
                values = fontOutlineOptions,
                order = 3,
                get = function() return KOL.db.profile.changes.itemTracker.zoneFontOutline end,
                set = function(_, value)
                    KOL.db.profile.changes.itemTracker.zoneFontOutline = value
                    Changes:ApplyItemTrackerFont()
                end,
            },
        }
    }

    -- NPCs/Mobs Group
    itemtrackerTab.npc = {
        type = "group",
        name = "NPCs/Mobs",
        inline = true,
        order = 4,
        args = {
            font = {
                type = "select",
                name = "Font",
                desc = "Font for NPC/Mob names",
                dialogControl = "LSM30_Font",
                values = LSM:HashTable("font"),
                order = 1,
                get = function() return KOL.db.profile.changes.itemTracker.npcFont end,
                set = function(_, value)
                    KOL.db.profile.changes.itemTracker.npcFont = value
                    Changes:ApplyItemTrackerFont()
                end,
            },
            fontSize = {
                type = "range",
                name = "Size",
                desc = "Font size for NPC/Mob names",
                min = 6,
                max = 32,
                step = 1,
                order = 2,
                get = function() return KOL.db.profile.changes.itemTracker.npcFontSize end,
                set = function(_, value)
                    KOL.db.profile.changes.itemTracker.npcFontSize = value
                    Changes:ApplyItemTrackerFont()
                end,
            },
            fontOutline = {
                type = "select",
                name = "Outline",
                desc = "Outline style for NPC/Mob names",
                values = fontOutlineOptions,
                order = 3,
                get = function() return KOL.db.profile.changes.itemTracker.npcFontOutline end,
                set = function(_, value)
                    KOL.db.profile.changes.itemTracker.npcFontOutline = value
                    Changes:ApplyItemTrackerFont()
                end,
            },
        }
    }

    -- Items/Loot Group
    itemtrackerTab.item = {
        type = "group",
        name = "Items/Loot",
        inline = true,
        order = 5,
        args = {
            font = {
                type = "select",
                name = "Font",
                desc = "Font for item/loot names",
                dialogControl = "LSM30_Font",
                values = LSM:HashTable("font"),
                order = 1,
                get = function() return KOL.db.profile.changes.itemTracker.itemFont end,
                set = function(_, value)
                    KOL.db.profile.changes.itemTracker.itemFont = value
                    Changes:ApplyItemTrackerFont()
                end,
            },
            fontSize = {
                type = "range",
                name = "Size",
                desc = "Font size for item/loot names",
                min = 6,
                max = 32,
                step = 1,
                order = 2,
                get = function() return KOL.db.profile.changes.itemTracker.itemFontSize end,
                set = function(_, value)
                    KOL.db.profile.changes.itemTracker.itemFontSize = value
                    Changes:ApplyItemTrackerFont()
                end,
            },
            fontOutline = {
                type = "select",
                name = "Outline",
                desc = "Outline style for item/loot names",
                values = fontOutlineOptions,
                order = 3,
                get = function() return KOL.db.profile.changes.itemTracker.itemFontOutline end,
                set = function(_, value)
                    KOL.db.profile.changes.itemTracker.itemFontOutline = value
                    Changes:ApplyItemTrackerFont()
                end,
            },
        }
    }

    -- Limit Indicators Group
    itemtrackerTab.limit = {
        type = "group",
        name = "Limit Indicators",
        inline = true,
        order = 6,
        args = {
            font = {
                type = "select",
                name = "Font",
                desc = "Font for limit indicators",
                dialogControl = "LSM30_Font",
                values = LSM:HashTable("font"),
                order = 1,
                get = function() return KOL.db.profile.changes.itemTracker.limitFont end,
                set = function(_, value)
                    KOL.db.profile.changes.itemTracker.limitFont = value
                    Changes:ApplyItemTrackerFont()
                end,
            },
            fontSize = {
                type = "range",
                name = "Size",
                desc = "Font size for limit indicators",
                min = 6,
                max = 32,
                step = 1,
                order = 2,
                get = function() return KOL.db.profile.changes.itemTracker.limitFontSize end,
                set = function(_, value)
                    KOL.db.profile.changes.itemTracker.limitFontSize = value
                    Changes:ApplyItemTrackerFont()
                end,
            },
            fontOutline = {
                type = "select",
                name = "Outline",
                desc = "Outline style for limit indicators",
                values = fontOutlineOptions,
                order = 3,
                get = function() return KOL.db.profile.changes.itemTracker.limitFontOutline end,
                set = function(_, value)
                    KOL.db.profile.changes.itemTracker.limitFontOutline = value
                    Changes:ApplyItemTrackerFont()
                end,
            },
        }
    }
end

-- ============================================================================
-- Event Registration & Frame
-- ============================================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" and KOL.db then
        Changes:Initialize()
    end
end)

-- ============================================================================
-- Module Complete
-- ============================================================================
