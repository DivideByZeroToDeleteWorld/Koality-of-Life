-- ============================================================================
-- Koality-of-Life: Tweaks Module
-- ============================================================================
-- Quality of life tweaks and improvements organized by category
-- ============================================================================

local KOL = KoalityOfLife

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

    -- Setup config UI
    self:SetupConfigUI()

    KOL:DebugPrint("Tweaks: Module initialized", 1)
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

KOL:DebugPrint("Tweaks module loaded", 1)
