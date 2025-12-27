-- ============================================================================
-- !Koality-of-Life: Tweaks Module
-- ============================================================================
-- Quality of life tweaks and improvements organized by category
-- ============================================================================

local KOL = KoalityOfLife
local LSM = LibStub("LibSharedMedia-3.0")

-- ============================================================================
-- ItemTracker Module Data
-- ============================================================================

-- ItemTracker defaults
local itemTrackerDefaults = {
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
}

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
-- Pastel Color Selection for Block Titles
-- ============================================================================

-- Smart color selection based on block name keywords
local COLOR_KEYWORDS = {
    -- Commerce/Trade
    ["purchase"] = "GREEN",
    ["vendor"] = "YELLOW",
    ["sell"] = "ORANGE",
    ["buy"] = "MINT",
    ["trade"] = "PEACH",
    ["merchant"] = "YELLOW",

    -- Combat/Action
    ["combat"] = "RED",
    ["attack"] = "ROSE",
    ["defense"] = "BLUE",
    ["buff"] = "LAVENDER",

    -- Control/Interface
    ["control"] = "CYAN",
    ["interface"] = "SKY",
    ["ui"] = "PURPLE",
    ["display"] = "BLUE",

    -- Default
    ["default"] = "PINK",
}

-- Pick a pastel color based on block name
local function PickPastelColor(blockName)
    local lowerName = string.lower(blockName)

    -- Check for keyword matches
    for keyword, colorName in pairs(COLOR_KEYWORDS) do
        if string.find(lowerName, keyword) then
            return KOL.Colors:GetPastel(colorName)
        end
    end

    -- Default to pink if no match
    return KOL.Colors:GetPastel("PINK")
end

-- ============================================================================
-- Font Helper (averages with General settings)
-- ============================================================================

local function GetAveragedFont(requestedSize)
    local generalSize = KOL.db.profile.generalFontSize or 12
    local averageSize = math.floor((requestedSize + generalSize) / 2)

    local fontName = KOL.db.profile.generalFont or "Friz Quadrata TT"
    local fontOutline = KOL.db.profile.generalFontOutline or "THICKOUTLINE"
    local fontPath = LibStub("LibSharedMedia-3.0"):Fetch("font", fontName)

    return fontPath, averageSize, fontOutline
end

-- ============================================================================
-- Tweaks Module
-- ============================================================================

KOL.Tweaks = {}
local Tweaks = KOL.Tweaks

-- Initialize settings
function Tweaks:Initialize()
    -- Ensure database structure exists
    if not KOL.db.profile.tweaks then
        KOL.db.profile.tweaks = {
            vendor = {
                buyStack = false,
            }
        }
    end

    -- Initialize ItemTracker defaults
    if not KOL.db.profile.tweaks.itemTracker then
        KOL.db.profile.tweaks.itemTracker = {}
    end
    for key, value in pairs(itemTrackerDefaults) do
        if KOL.db.profile.tweaks.itemTracker[key] == nil then
            KOL.db.profile.tweaks.itemTracker[key] = value
        end
    end

    -- Setup config UI
    self:SetupConfigUI()

    -- Start ItemTracker batch system
    self:StartItemHuntBatch()

    KOL:DebugPrint("Tweaks: Module initialized", 1)
end

-- ============================================================================
-- ItemTracker Font Functions
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
                if currentFont == fontPath and math.abs((currentSize or 0) - fontSize) < 0.1 then
                    return 0
                end
            end
        end
    end

    local fontStringsUpdated = 0

    -- Check regions for FontStrings
    local regionCount = (frame.GetNumRegions and frame:GetNumRegions()) or 0
    if regionCount > 0 then
        for i = 1, regionCount do
            local region = select(i, frame:GetRegions())
            if region and region:GetObjectType() == "FontString" then
                local currentFont, currentSize = region:GetFont()
                local fontMatches = (currentFont == fontPath)
                local sizeMatches = (math.abs((currentSize or 0) - fontSize) < 0.1)

                if not fontMatches or not sizeMatches then
                    local success = pcall(function()
                        region:SetFont(fontPath, fontSize, fontOutline)
                    end)
                    if success then
                        fontStringsUpdated = fontStringsUpdated + 1
                    end
                end
            end
        end
    end

    -- Also check common properties (text, label, etc.)
    local props = {"text", "label", "title", "Text", "Label", "Title"}
    for _, prop in ipairs(props) do
        if frame[prop] and frame[prop].SetFont and frame[prop].GetFont then
            local currentFont, currentSize = frame[prop]:GetFont()
            local fontMatches = (currentFont == fontPath)
            local sizeMatches = (math.abs((currentSize or 0) - fontSize) < 0.1)

            if not fontMatches or not sizeMatches then
                local success = pcall(function()
                    frame[prop]:SetFont(fontPath, fontSize, fontOutline)
                end)
                if success then
                    fontStringsUpdated = fontStringsUpdated + 1
                end
            end
        end
    end

    -- Mark this frame as having fonts applied
    if fontStringsUpdated > 0 then
        itemHuntFontsApplied[frameName] = true
    end

    return fontStringsUpdated
end

-- Scan and apply fonts to all ItemHunt frames
function Tweaks:ScanAndApplyItemHuntFonts()
    if not KOL.db.profile.tweaks.itemTracker or not KOL.db.profile.tweaks.itemTracker.enabled then
        return 0
    end

    local settings = KOL.db.profile.tweaks.itemTracker

    -- Check if user changed settings - if so, clear tracking and force re-apply
    local settingsChanged = false
    for settingKey, settingValue in pairs(lastAppliedSettings) do
        if settings[settingKey] ~= settingValue then
            settingsChanged = true
            break
        end
    end

    if settingsChanged then
        itemHuntFontsApplied = {}
        for settingKey, _ in pairs(lastAppliedSettings) do
            lastAppliedSettings[settingKey] = settings[settingKey]
        end
    end

    local totalUpdated = 0

    -- Scan ItemHuntFrameItem1 through ItemHuntFrameItem50 (Items/Loot)
    local itemFontPath = LSM:Fetch("font", settings.itemFont)
    if itemFontPath then
        for i = 1, 50 do
            local frameName = "ItemHuntFrameItem" .. i
            local frame = _G[frameName]
            if frame and frame:IsVisible() then
                totalUpdated = totalUpdated + ApplyFontToItemHuntFrame(frame, itemFontPath, settings.itemFontSize, settings.itemFontOutline, frameName)
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
                totalUpdated = totalUpdated + ApplyFontToItemHuntFrame(frame, npcFontPath, settings.npcFontSize, settings.npcFontOutline, frameName)
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
                totalUpdated = totalUpdated + ApplyFontToItemHuntFrame(frame, limitFontPath, settings.limitFontSize, settings.limitFontOutline, frameName)
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
                totalUpdated = totalUpdated + ApplyFontToItemHuntFrame(frame, zoneFontPath, settings.zoneFontSize, settings.zoneFontOutline, frameName)
            end
        end
    end

    if totalUpdated > 0 then
        KOL:DebugPrint("Tweaks: ItemTracker - " .. totalUpdated .. " FontStrings updated", 3)
    end

    return totalUpdated
end

-- Start batch system for ItemHunt font scanning
function Tweaks:StartItemHuntBatch()
    if self.itemHuntScannerActive then
        return
    end

    self.itemHuntScannerActive = true

    -- Initialize lastAppliedSettings with current settings
    if KOL.db.profile.tweaks and KOL.db.profile.tweaks.itemTracker then
        local settings = KOL.db.profile.tweaks.itemTracker
        for settingKey, _ in pairs(lastAppliedSettings) do
            lastAppliedSettings[settingKey] = settings[settingKey]
        end
    end

    -- Configure the itemHunt batch channel
    KOL:BatchConfigure("itemHunt", {
        interval = 0.5,
        processMode = "all",
        triggerMode = "interval",
        maxQueueSize = 5,
    })

    -- Add scanning action
    KOL:BatchAdd("itemHunt", "scanAll", function()
        Tweaks:ScanAndApplyItemHuntFonts()
    end, 3)

    -- Start the batch
    KOL:BatchStart("itemHunt")

    KOL:DebugPrint("Tweaks: Started ItemHunt batch scanner", 3)
end

-- Reset tracking (for zone changes)
function Tweaks:ResetItemHuntTracking()
    itemHuntFontsApplied = {}
    self.itemHuntScannerActive = false
    self:StartItemHuntBatch()
end

-- Apply ItemTracker fonts (called when settings change)
function Tweaks:ApplyItemTrackerFont()
    itemHuntFontsApplied = {}
    self:ScanAndApplyItemHuntFonts()
end

-- ============================================================================
-- Config UI - Block System
-- ============================================================================

-- Create a block in a Tweaks sub-tab
-- Usage: CreateBlock(subtab, blockName, order, [optionalColor])
local function CreateBlock(subtab, blockName, order, colorOverride)
    if not KOL.configOptions or not KOL.configOptions.args.tweaks then
        KOL:DebugPrint("Tweaks: Cannot create block - config not initialized", 1)
        return nil
    end

    local subtabArgs = KOL.configOptions.args.tweaks.args[subtab]
    if not subtabArgs or not subtabArgs.args then
        KOL:DebugPrint("Tweaks: Cannot find subtab: " .. tostring(subtab), 1)
        return nil
    end

    -- Pick color for block title
    local color = colorOverride or PickPastelColor(blockName)
    local colorHex = KOL.Colors:ToHex(color)

    local fontPath, fontSize, fontOutline = GetAveragedFont(14)

    -- Create block group
    local blockKey = string.lower(string.gsub(blockName, " ", "_"))

    subtabArgs.args[blockKey] = {
        type = "group",
        name = " ",  -- Empty name since we'll use a custom header
        order = order,
        inline = true,
        args = {
            blockTitle = {
                type = "description",
                name = "|cFF" .. colorHex .. blockName .. "|r",
                fontSize = "large",
                order = 0,
            },
            separator = {
                type = "description",
                name = " ",
                order = 1,
            },
        }
    }

    KOL:DebugPrint("Tweaks: Created block '" .. blockName .. "' in '" .. subtab .. "'", 3)
    return subtabArgs.args[blockKey]
end

function Tweaks:SetupConfigUI()
    if not KOL.configOptions then
        KOL:DebugPrint("Tweaks: Config not ready yet, deferring setup", 3)
        return
    end

    -- ========================================================================
    -- VENDORS SUB-TAB
    -- ========================================================================

    -- Purchase Control Block (Green color for purchase-related features)
    local purchaseBlock = CreateBlock("vendors", "Purchase Control", 1)

    if purchaseBlock then
        purchaseBlock.args.buyStack = {
            type = "toggle",
            name = "Buy Stack",
            desc = "When enabled, Shift+clicking an item in the vendor window will show a custom 'BUY STACK' dialog that purchases a full stack (20) of the item instead of buying just one.\n\n|cFFFF8888Requires /reload to take effect.|r",
            get = function() return KOL.db.profile.tweaks.vendor.buyStack end,
            set = function(_, value)
                KOL.db.profile.tweaks.vendor.buyStack = value
                if value then
                    KOL:PrintTag("|cFF00FF00Enabled|r Buy Stack feature |cFFFFAAAA(requires /reload)|r")
                else
                    KOL:PrintTag("|cFFFF0000Disabled|r Buy Stack feature |cFFFFAAAA(requires /reload)|r")
                end
            end,
            width = "full",
            order = 2,
        }
    end

    -- ========================================================================
    -- ITEMTRACKER SUB-TAB
    -- ========================================================================

    if not KOL.configOptions.args.tweaks.args.itemtracker_tab then
        KOL.configOptions.args.tweaks.args.itemtracker_tab = {
            type = "group",
            name = "ItemTracker",
            order = 3,
            args = {}
        }
    end
    local itemtrackerTab = KOL.configOptions.args.tweaks.args.itemtracker_tab.args

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
            return KOL.db.profile.tweaks.itemTracker.enabled
        end,
        set = function(_, value)
            KOL.db.profile.tweaks.itemTracker.enabled = value
            Tweaks:ApplyItemTrackerFont()
            KOL:PrintTag("ItemTracker font changes " .. (value and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
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
                desc = "Font for zone headers",
                dialogControl = "LSM30_Font",
                values = LSM:HashTable("font"),
                order = 1,
                get = function() return KOL.db.profile.tweaks.itemTracker.zoneFont end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.zoneFont = value
                    Tweaks:ApplyItemTrackerFont()
                end,
            },
            fontSize = {
                type = "range",
                name = "Size",
                min = 6, max = 32, step = 1,
                order = 2,
                get = function() return KOL.db.profile.tweaks.itemTracker.zoneFontSize end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.zoneFontSize = value
                    Tweaks:ApplyItemTrackerFont()
                end,
            },
            fontOutline = {
                type = "select",
                name = "Outline",
                values = fontOutlineOptions,
                order = 3,
                get = function() return KOL.db.profile.tweaks.itemTracker.zoneFontOutline end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.zoneFontOutline = value
                    Tweaks:ApplyItemTrackerFont()
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
                dialogControl = "LSM30_Font",
                values = LSM:HashTable("font"),
                order = 1,
                get = function() return KOL.db.profile.tweaks.itemTracker.npcFont end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.npcFont = value
                    Tweaks:ApplyItemTrackerFont()
                end,
            },
            fontSize = {
                type = "range",
                name = "Size",
                min = 6, max = 32, step = 1,
                order = 2,
                get = function() return KOL.db.profile.tweaks.itemTracker.npcFontSize end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.npcFontSize = value
                    Tweaks:ApplyItemTrackerFont()
                end,
            },
            fontOutline = {
                type = "select",
                name = "Outline",
                values = fontOutlineOptions,
                order = 3,
                get = function() return KOL.db.profile.tweaks.itemTracker.npcFontOutline end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.npcFontOutline = value
                    Tweaks:ApplyItemTrackerFont()
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
                dialogControl = "LSM30_Font",
                values = LSM:HashTable("font"),
                order = 1,
                get = function() return KOL.db.profile.tweaks.itemTracker.itemFont end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.itemFont = value
                    Tweaks:ApplyItemTrackerFont()
                end,
            },
            fontSize = {
                type = "range",
                name = "Size",
                min = 6, max = 32, step = 1,
                order = 2,
                get = function() return KOL.db.profile.tweaks.itemTracker.itemFontSize end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.itemFontSize = value
                    Tweaks:ApplyItemTrackerFont()
                end,
            },
            fontOutline = {
                type = "select",
                name = "Outline",
                values = fontOutlineOptions,
                order = 3,
                get = function() return KOL.db.profile.tweaks.itemTracker.itemFontOutline end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.itemFontOutline = value
                    Tweaks:ApplyItemTrackerFont()
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
                dialogControl = "LSM30_Font",
                values = LSM:HashTable("font"),
                order = 1,
                get = function() return KOL.db.profile.tweaks.itemTracker.limitFont end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.limitFont = value
                    Tweaks:ApplyItemTrackerFont()
                end,
            },
            fontSize = {
                type = "range",
                name = "Size",
                min = 6, max = 32, step = 1,
                order = 2,
                get = function() return KOL.db.profile.tweaks.itemTracker.limitFontSize end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.limitFontSize = value
                    Tweaks:ApplyItemTrackerFont()
                end,
            },
            fontOutline = {
                type = "select",
                name = "Outline",
                values = fontOutlineOptions,
                order = 3,
                get = function() return KOL.db.profile.tweaks.itemTracker.limitFontOutline end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.limitFontOutline = value
                    Tweaks:ApplyItemTrackerFont()
                end,
            },
        }
    }

    KOL:DebugPrint("Tweaks: Config UI setup complete", 3)
end

-- ============================================================================
-- Vendor Tweaks
-- ============================================================================

local originalMerchantFrame_OnClick

function Tweaks:SetupVendorTweaks()
    if not KOL.db.profile.tweaks.vendor.buyStack then
        return
    end

    -- Hook the merchant item button clicks
    if not originalMerchantFrame_OnClick then
        originalMerchantFrame_OnClick = MerchantItemButton_OnModifiedClick

        MerchantItemButton_OnModifiedClick = function(self, button)
            -- Check if shift is held and Buy Stack is enabled
            if IsShiftKeyDown() and KOL.db.profile.tweaks.vendor.buyStack then
                local itemLink = GetMerchantItemLink(self:GetID())
                if itemLink then
                    -- Show our custom buy stack dialog
                    Tweaks:ShowBuyStackDialog(self:GetID())
                    return
                end
            end

            -- Call original function
            if originalMerchantFrame_OnClick then
                originalMerchantFrame_OnClick(self, button)
            end
        end

        KOL:DebugPrint("Tweaks: Vendor buy stack hook installed", 3)
    end
end

function Tweaks:ShowBuyStackDialog(merchantSlot)
    local name, texture, price, quantity, numAvailable, isUsable = GetMerchantItemInfo(merchantSlot)
    if not name then return end

    local itemLink = GetMerchantItemLink(merchantSlot)

    -- Get max stack size - need to handle case where item isn't cached yet
    local _, _, _, _, _, _, _, maxStack = GetItemInfo(itemLink)

    -- If maxStack is nil, the item isn't cached - use quantity from merchant as fallback
    if not maxStack or maxStack <= 0 then
        maxStack = quantity or 20 -- Use merchant quantity or default to 20
    end

    -- Calculate how many we can buy (limited by availability and stack size)
    local stackSize = maxStack
    if numAvailable and numAvailable >= 0 then
        stackSize = math.min(maxStack, numAvailable)
    end

    local totalPrice = price * stackSize

    -- Create popup frame - compact, no title bar
    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetSize(280, 110)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(200)

    -- Backdrop
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,  -- Changed from 2 to 1
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    popup:SetBackdropColor(0.05, 0.05, 0.05, 0.98)
    popup:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)  -- Darker grey border

    -- Item icon and name
    local icon = popup:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("TOPLEFT", popup, "TOPLEFT", 8, -8)
    icon:SetTexture(texture)

    local fontPath2, fontSize2, fontOutline2 = GetAveragedFont(10)
    local itemName = popup:CreateFontString(nil, "OVERLAY")
    itemName:SetFont(fontPath2, fontSize2, fontOutline2)
    itemName:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    itemName:SetPoint("RIGHT", popup, "RIGHT", -8, 0)
    itemName:SetText(name)
    itemName:SetTextColor(1, 1, 1, 1)
    itemName:SetJustifyH("LEFT")
    itemName:SetWordWrap(false)

    -- Stack info
    local fontPath3, fontSize3, fontOutline3 = GetAveragedFont(9)
    local stackInfo = popup:CreateFontString(nil, "OVERLAY")
    stackInfo:SetFont(fontPath3, fontSize3, fontOutline3)
    stackInfo:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -6)
    stackInfo:SetText(string.format("Stack Size: |cFFFFFFFF%d|r", stackSize))
    stackInfo:SetTextColor(0.7, 1, 0.7, 1)

    -- Price info
    local priceInfo = popup:CreateFontString(nil, "OVERLAY")
    priceInfo:SetFont(fontPath3, fontSize3, fontOutline3)
    priceInfo:SetPoint("TOP", stackInfo, "BOTTOM", 0, -4)
    priceInfo:SetPoint("LEFT", stackInfo, "LEFT", 0, 0)

    local gold = math.floor(totalPrice / 10000)
    local silver = math.floor((totalPrice % 10000) / 100)
    local copper = totalPrice % 100

    local priceStr = ""
    if gold > 0 then priceStr = priceStr .. gold .. "|cFFFFD700g|r " end
    if silver > 0 or gold > 0 then priceStr = priceStr .. silver .. "|cFFC0C0C0s|r " end
    priceStr = priceStr .. copper .. "|cFFCD7F32c|r"

    priceInfo:SetText("Total Cost: " .. priceStr)
    priceInfo:SetTextColor(1, 1, 0.7, 1)

    -- BUY STACK button - darker, muted green with darker green border
    local buyBtn = CreateFrame("Button", nil, popup)
    buyBtn:SetSize(110, 26)
    buyBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 10, 10)
    buyBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    buyBtn:SetBackdropColor(0.2, 0.4, 0.2, 1)  -- Darker, muted green
    buyBtn:SetBackdropBorderColor(0.1, 0.25, 0.1, 1)  -- Even darker green border

    local buyText = buyBtn:CreateFontString(nil, "OVERLAY")
    buyText:SetFont(fontPath2, fontSize2, fontOutline2)
    buyText:SetPoint("CENTER")
    buyText:SetText("BUY STACK")
    buyText:SetTextColor(0.9, 0.9, 0.9, 1)

    buyBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.5, 0.25, 1)
        self:SetBackdropBorderColor(0.15, 0.35, 0.15, 1)  -- Darker green border on hover
    end)
    buyBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.2, 0.4, 0.2, 1)
        self:SetBackdropBorderColor(0.1, 0.25, 0.1, 1)
    end)
    buyBtn:SetScript("OnClick", function()
        -- Buy the stack
        BuyMerchantItem(merchantSlot, stackSize)
        popup:Hide()
        KOL:PrintTag("Purchased |cFFFFFFFF" .. stackSize .. "x|r " .. itemLink)
    end)

    -- Cancel button - darker, muted red with darker red border
    local cancelBtn = CreateFrame("Button", nil, popup)
    cancelBtn:SetSize(110, 26)
    cancelBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 10)
    cancelBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    cancelBtn:SetBackdropColor(0.4, 0.2, 0.2, 1)  -- Darker, muted red
    cancelBtn:SetBackdropBorderColor(0.25, 0.1, 0.1, 1)  -- Even darker red border

    local cancelText = cancelBtn:CreateFontString(nil, "OVERLAY")
    cancelText:SetFont(fontPath2, fontSize2, fontOutline2)
    cancelText:SetPoint("CENTER")
    cancelText:SetText("Cancel")
    cancelText:SetTextColor(0.9, 0.9, 0.9, 1)

    cancelBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.5, 0.25, 0.25, 1)
        self:SetBackdropBorderColor(0.35, 0.15, 0.15, 1)  -- Darker red border on hover
    end)
    cancelBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.4, 0.2, 0.2, 1)
        self:SetBackdropBorderColor(0.25, 0.1, 0.1, 1)
    end)
    cancelBtn:SetScript("OnClick", function()
        popup:Hide()
    end)

    popup:Show()
end

-- Setup vendor hooks when entering world
KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
    Tweaks:SetupVendorTweaks()
end, "Tweaks")

-- Re-setup when config changes
function Tweaks:RefreshHooks()
    Tweaks:SetupVendorTweaks()
end

-- ============================================================================
-- ItemTracker Event Handlers
-- ============================================================================

-- Reset ItemHunt tracking on zone changes (frames may be recreated)
KOL:RegisterEventCallback("ZONE_CHANGED", function()
    Tweaks:ResetItemHuntTracking()
end, "Tweaks_ItemTracker")

KOL:RegisterEventCallback("ZONE_CHANGED_NEW_AREA", function()
    Tweaks:ResetItemHuntTracking()
end, "Tweaks_ItemTracker")

KOL:RegisterEventCallback("ZONE_CHANGED_INDOORS", function()
    Tweaks:ResetItemHuntTracking()
end, "Tweaks_ItemTracker")

KOL:DebugPrint("Tweaks module loaded", 1)
