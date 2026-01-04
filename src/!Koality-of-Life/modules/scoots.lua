-- ============================================================================
-- !Koality-of-Life: Scoots Integration Module
-- ============================================================================
-- Provides integration with Scoots addons (ScootsVendorFilter, etc.)
-- This module dynamically detects Scoots addons and adds relevant config
-- options only when those addons are present.
-- ============================================================================

local KOL = KoalityOfLife

-- ============================================================================
-- Scoots Module
-- ============================================================================

KOL.Scoots = {}
local Scoots = KOL.Scoots

-- Track which Scoots addons are detected
Scoots.detectedAddons = {}

-- List of Scoots addons we integrate with
local SCOOTS_ADDONS = {
    {
        name = "ScootsVendorFilter",
        addonName = "ScootsVendorFilter",  -- Exact addon folder name (no space)
        globalCheck = "SVF",  -- Global variable that exists when addon is loaded
        configKey = "vendorFilter",
    },
    -- Add more Scoots addons here as needed
}

-- ============================================================================
-- Initialization
-- ============================================================================

function Scoots:Initialize()
    -- Prevent double initialization
    if self.initialized then return end
    self.initialized = true

    -- Ensure database structure exists
    if not KOL.db.profile.tweaks then
        KOL.db.profile.tweaks = {}
    end
    if not KOL.db.profile.tweaks.scoots then
        KOL.db.profile.tweaks.scoots = {
            vendorFilter = {
                switchButton = true,  -- Show SWITCH button on merchant frame
                autoSwitch = false,   -- Auto-switch when no filtered items
            },
        }
    end

    -- Detect Scoots addons
    self:DetectAddons()

    -- Only setup if at least one Scoots addon is detected
    if next(self.detectedAddons) then
        self:SetupConfigUI()
        self:SetupMerchantHooks()
        KOL:DebugPrint("Scoots: Module initialized with " .. self:GetDetectedCount() .. " addon(s)", 1)
    else
        KOL:DebugPrint("Scoots: No Scoots addons detected, module inactive", 3)
    end
end

-- Detect which Scoots addons are present
function Scoots:DetectAddons()
    self.detectedAddons = {}

    for _, addonInfo in ipairs(SCOOTS_ADDONS) do
        local detected = false

        -- Method 1: Check if the global variable exists
        if _G[addonInfo.globalCheck] then
            detected = true
            KOL:DebugPrint("Scoots: Detected " .. addonInfo.name .. " via global '" .. addonInfo.globalCheck .. "'", 2)
        end

        -- Method 2: Check via IsAddOnLoaded (fallback)
        if not detected and addonInfo.addonName then
            local loaded = IsAddOnLoaded(addonInfo.addonName)
            if loaded then
                detected = true
                KOL:DebugPrint("Scoots: Detected " .. addonInfo.name .. " via IsAddOnLoaded('" .. addonInfo.addonName .. "')", 2)
            end
        end

        -- Method 3: Try checking by addon index (most reliable)
        if not detected then
            local numAddons = GetNumAddOns()
            for i = 1, numAddons do
                local name, _, _, enabled = GetAddOnInfo(i)
                if name == addonInfo.addonName and enabled then
                    detected = true
                    KOL:DebugPrint("Scoots: Detected " .. addonInfo.name .. " via GetAddOnInfo (index " .. i .. ")", 2)
                    break
                end
            end
        end

        if detected then
            self.detectedAddons[addonInfo.name] = addonInfo
        end
    end
end

-- Get count of detected addons
function Scoots:GetDetectedCount()
    local count = 0
    for _ in pairs(self.detectedAddons) do
        count = count + 1
    end
    return count
end

-- ============================================================================
-- Config UI Setup (only if Scoots addons detected)
-- ============================================================================

function Scoots:SetupConfigUI()
    -- Safety check: ensure configOptions and tweaks > synastria tab exist
    if not KOL.configOptions or not KOL.configOptions.args or not KOL.configOptions.args.tweaks then
        KOL:DebugPrint("Scoots: Config not ready, deferring setup", 3)
        return
    end

    -- Get reference to synastria tab args (Scoots options are part of Synastria tree)
    local synastriaTab = KOL.configOptions.args.tweaks.args.synastria
    if not synastriaTab then
        KOL:DebugPrint("Scoots: Synastria tab not ready yet", 2)
        return
    end

    -- SCOOTS tree section (order 5, after Fishing at order 4)
    synastriaTab.args.scoots = {
        type = "group",
        name = "Scoots",
        order = 5,
        args = {
            -- Section Header (teal accent)
            header = {
                type = "description",
                name = "SCOOTS|0,1,0.5",  -- Teal accent
                dialogControl = "KOL_SectionHeader",
                width = "full",
                order = 0,
            },
            desc = {
                type = "description",
                name = "|cFFAAAAAAIntegration options for Scoots addon family.|r\n",
                fontSize = "small",
                order = 0.1,
            },
        }
    }

    -- Add ScootsVendorFilter config if detected
    if self.detectedAddons["ScootsVendorFilter"] then
        self:SetupVendorFilterConfig()
    end

    KOL:DebugPrint("Scoots: Config UI setup complete", 3)
end

-- Setup ScootsVendorFilter specific config
function Scoots:SetupVendorFilterConfig()
    -- Get reference to the Scoots tree item within Synastria
    local scootsArgs = KOL.configOptions.args.tweaks.args.synastria.args.scoots.args

    -- Add Vendor Filter options directly to Scoots tree item (inline, not nested)
    scootsArgs.vendorFilterHeader = {
        type = "header",
        name = "Vendor Filter",
        order = 1,
    }

    scootsArgs.vendorFilterDesc = {
        type = "description",
        name = "|cFFAAAAAAEnhanced controls for ScootsVendorFilter addon.|r\n",
        fontSize = "small",
        order = 1.1,
    }

    scootsArgs.switchButton = {
        type = "toggle",
        name = "Enable SWITCH Button",
        desc = "Add a SWITCH button to the merchant frame that toggles between filtered and unfiltered vendor view.\n\n|cFF00FF00Tip:|r This is an alternative to using the ScootsVendorFilter's built-in toggle button.",
        get = function()
            return KOL.db.profile.tweaks.scoots.vendorFilter.switchButton
        end,
        set = function(_, value)
            KOL.db.profile.tweaks.scoots.vendorFilter.switchButton = value
            -- Show/hide the button if merchant frame is currently open
            if MerchantFrame and MerchantFrame:IsShown() then
                Scoots:UpdateSwitchButton()
            end
            KOL:PrintTag("Scoots SWITCH button " .. (value and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
        end,
        width = "full",
        order = 2,
    }

    scootsArgs.autoSwitch = {
        type = "toggle",
        name = "Auto Switch When No Items Available",
        desc = "Automatically switch to the default vendor view when the filter returns no items.\n\n|cFFFFFF00Note:|r This helps when the vendor has no items matching your current filter.",
        get = function()
            return KOL.db.profile.tweaks.scoots.vendorFilter.autoSwitch
        end,
        set = function(_, value)
            KOL.db.profile.tweaks.scoots.vendorFilter.autoSwitch = value
            KOL:PrintTag("Scoots auto-switch " .. (value and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
        end,
        width = "full",
        order = 3,
    }

    KOL:DebugPrint("Scoots: VendorFilter config added", 3)
end

-- ============================================================================
-- Merchant Frame Integration
-- ============================================================================

local switchButton = nil

function Scoots:SetupMerchantHooks()
    -- Only setup if ScootsVendorFilter is detected
    if not self.detectedAddons["ScootsVendorFilter"] then
        return
    end

    -- Hook MERCHANT_SHOW event
    KOL:RegisterEventCallback("MERCHANT_SHOW", function()
        -- Small delay to let SVF initialize first
        C_Timer.After(0.1, function()
            Scoots:OnMerchantShow()
        end)
    end, "Scoots_MerchantShow")

    -- Hook MERCHANT_CLOSED event
    KOL:RegisterEventCallback("MERCHANT_CLOSED", function()
        Scoots:OnMerchantClosed()
    end, "Scoots_MerchantClosed")

    KOL:DebugPrint("Scoots: Merchant hooks registered", 3)
end

function Scoots:OnMerchantShow()
    local settings = KOL.db.profile.tweaks.scoots.vendorFilter

    -- Create/show SWITCH button if enabled
    if settings.switchButton then
        self:CreateOrShowSwitchButton()
    end

    -- Handle auto-switch if enabled
    if settings.autoSwitch then
        self:CheckAutoSwitch()
    end
end

function Scoots:OnMerchantClosed()
    -- Hide the switch button when merchant closes
    if switchButton then
        switchButton:Hide()
    end
end

-- Create or show the SWITCH button
function Scoots:CreateOrShowSwitchButton()
    if not MerchantFrame then return end

    if not switchButton then
        -- Create the button using UIFactory if available, otherwise create manually
        if KOL.UIFactory and KOL.UIFactory.CreateButton then
            switchButton = KOL.UIFactory:CreateButton(MerchantFrame, "SWITCH", {
                type = "animated",
                width = 60,
                height = 22,
                onClick = function()
                    Scoots:ToggleVendorFilter()
                end,
            })
        else
            -- Fallback: Create a simple button
            switchButton = CreateFrame("Button", "KOL_ScootsSwitchButton", MerchantFrame)
            switchButton:SetSize(60, 22)

            switchButton:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false,
                edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            switchButton:SetBackdropColor(0.15, 0.15, 0.15, 0.95)
            switchButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

            local text = switchButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            text:SetPoint("CENTER")
            text:SetText("SWITCH")
            text:SetTextColor(0.9, 0.9, 0.9, 1)
            switchButton.text = text

            switchButton:SetScript("OnEnter", function(self)
                self:SetBackdropColor(0.25, 0.25, 0.25, 1)
                self:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
            end)

            switchButton:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0.15, 0.15, 0.15, 0.95)
                self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            end)

            switchButton:SetScript("OnClick", function()
                Scoots:ToggleVendorFilter()
            end)
        end

        -- Position to the right of SVFOptionsButton if it exists, otherwise position relative to frame
        local svfOptionsBtn = _G["SVFOptionsButton"]
        if svfOptionsBtn then
            switchButton:SetPoint("LEFT", svfOptionsBtn, "RIGHT", 5, 0)
        else
            -- Fallback position
            switchButton:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 130, -35)
        end

        switchButton:SetFrameStrata("HIGH")
    end

    switchButton:Show()
    self:UpdateSwitchButtonState()
end

-- Update SWITCH button visual state
function Scoots:UpdateSwitchButtonState()
    if not switchButton then return end

    -- Check if SVF is currently filtering (SVF.off = false means filtering is ON)
    local isFiltering = SVF and not SVF.off

    if isFiltering then
        -- Filtering is active - show in green/active state
        if switchButton.SetBackdropBorderColor then
            switchButton:SetBackdropBorderColor(0.2, 0.8, 0.4, 1)  -- Green border
        end
        if switchButton.text then
            switchButton.text:SetTextColor(0.4, 1, 0.6, 1)  -- Green text
        end
    else
        -- Filtering is off - show in default state
        if switchButton.SetBackdropBorderColor then
            switchButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)  -- Gray border
        end
        if switchButton.text then
            switchButton.text:SetTextColor(0.9, 0.9, 0.9, 1)  -- White text
        end
    end
end

-- Update switch button visibility based on settings
function Scoots:UpdateSwitchButton()
    local settings = KOL.db.profile.tweaks.scoots.vendorFilter

    if settings.switchButton then
        if MerchantFrame and MerchantFrame:IsShown() then
            self:CreateOrShowSwitchButton()
        end
    else
        if switchButton then
            switchButton:Hide()
        end
    end
end

-- Toggle the vendor filter (replicates exactly what SVFToggleOffButton does)
function Scoots:ToggleVendorFilter()
    if not SVF then
        KOL:DebugPrint("Scoots: SVF not loaded, cannot toggle", 1)
        return
    end

    -- Replicate the exact logic from SVFToggleOffButton OnClick handler
    -- (from ScootsVendorFilter.lua lines 1338-1347)
    if SVF.off == true then
        -- Currently showing default vendor, switch to filtered
        SVF.off = false
        if SVF.frame then
            SVF.frame:Show()
        end
        if SVF.synopsisFrame then
            SVF.synopsisFrame:Show()
        end
        -- The OnUpdate handler will hide the merchant UI
        KOL:DebugPrint("Scoots: Switched to FILTERED vendor view", 3)
    else
        -- Currently showing filtered, switch to default vendor
        SVF.off = true
        if SVF.frame then
            SVF.frame:Hide()
        end
        if SVF.synopsisFrame then
            SVF.synopsisFrame:Hide()
        end
        -- Show the default merchant UI
        if SVF.showMerchantUi then
            SVF.showMerchantUi()
        end
        KOL:DebugPrint("Scoots: Switched to DEFAULT vendor view", 3)
    end

    -- Update our button state after toggle
    C_Timer.After(0.05, function()
        self:UpdateSwitchButtonState()
    end)
end

-- Check if auto-switch should trigger
function Scoots:CheckAutoSwitch()
    if not SVF then return end

    -- Check if filtering is on and no items are available
    local isFiltering = not SVF.off
    local noItems = (SVF.items == nil or #SVF.items == 0)

    if isFiltering and noItems then
        -- Auto-switch to unfiltered view
        KOL:DebugPrint("Scoots: Auto-switching (no filtered items available)", 2)
        self:ToggleVendorFilter()
        KOL:PrintTag("|cFFFFAA00Auto-switched|r vendor to show all items (no filtered items)")
    end
end

-- Module loaded message (initialization is called from ui.lua)
KOL:DebugPrint("Scoots module loaded", 3)
