local KOL = KoalityOfLife

KOL.Scoots = {}
local Scoots = KOL.Scoots

Scoots.detectedAddons = {}

local SCOOTS_ADDONS = {
    {
        name = "ScootsVendorFilter",
        addonName = "ScootsVendorFilter",
        globalCheck = "SVF",
        configKey = "vendorFilter",
    },
}

function Scoots:Initialize()
    if self.initialized then return end
    self.initialized = true

    if not KOL.db.profile.tweaks then
        KOL.db.profile.tweaks = {}
    end
    if not KOL.db.profile.tweaks.scoots then
        KOL.db.profile.tweaks.scoots = {
            vendorFilter = {
                switchButton = true,
                autoSwitch = false,
            },
        }
    end

    self:DetectAddons()

    if next(self.detectedAddons) then
        self:SetupConfigUI()
        self:SetupMerchantHooks()
        KOL:DebugPrint("Scoots: Module initialized with " .. self:GetDetectedCount() .. " addon(s)", 1)
    else
        KOL:DebugPrint("Scoots: No Scoots addons detected, module inactive", 3)
    end
end

function Scoots:DetectAddons()
    self.detectedAddons = {}

    for _, addonInfo in ipairs(SCOOTS_ADDONS) do
        local detected = false

        if _G[addonInfo.globalCheck] then
            detected = true
            KOL:DebugPrint("Scoots: Detected " .. addonInfo.name .. " via global '" .. addonInfo.globalCheck .. "'", 2)
        end

        if not detected and addonInfo.addonName then
            local loaded = IsAddOnLoaded(addonInfo.addonName)
            if loaded then
                detected = true
                KOL:DebugPrint("Scoots: Detected " .. addonInfo.name .. " via IsAddOnLoaded('" .. addonInfo.addonName .. "')", 2)
            end
        end

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

function Scoots:GetDetectedCount()
    local count = 0
    for _ in pairs(self.detectedAddons) do
        count = count + 1
    end
    return count
end

function Scoots:SetupConfigUI()
    if not KOL.configOptions or not KOL.configOptions.args or not KOL.configOptions.args.tweaks then
        KOL:DebugPrint("Scoots: Config not ready, deferring setup", 3)
        return
    end

    local synastriaTab = KOL.configOptions.args.tweaks.args.synastria
    if not synastriaTab then
        KOL:DebugPrint("Scoots: Synastria tab not ready yet", 2)
        return
    end

    synastriaTab.args.scoots = {
        type = "group",
        name = "Scoots",
        order = 5,
        args = {
            header = {
                type = "description",
                name = "SCOOTS|0,1,0.5",
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

    if self.detectedAddons["ScootsVendorFilter"] then
        self:SetupVendorFilterConfig()
    end

    KOL:DebugPrint("Scoots: Config UI setup complete", 3)
end

function Scoots:SetupVendorFilterConfig()
    local scootsArgs = KOL.configOptions.args.tweaks.args.synastria.args.scoots.args

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

local switchButton = nil

function Scoots:SetupMerchantHooks()
    if not self.detectedAddons["ScootsVendorFilter"] then
        return
    end

    KOL:RegisterEventCallback("MERCHANT_SHOW", function()
        C_Timer.After(0.1, function()
            Scoots:OnMerchantShow()
        end)
    end, "Scoots_MerchantShow")

    KOL:RegisterEventCallback("MERCHANT_CLOSED", function()
        Scoots:OnMerchantClosed()
    end, "Scoots_MerchantClosed")

    KOL:DebugPrint("Scoots: Merchant hooks registered", 3)
end

function Scoots:OnMerchantShow()
    local settings = KOL.db.profile.tweaks.scoots.vendorFilter

    if settings.switchButton then
        self:CreateOrShowSwitchButton()
    end

    if settings.autoSwitch then
        self:CheckAutoSwitch()
    end
end

function Scoots:OnMerchantClosed()
    if switchButton then
        switchButton:Hide()
    end
end

function Scoots:CreateOrShowSwitchButton()
    if not MerchantFrame then return end

    if not switchButton then
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

        local svfOptionsBtn = _G["SVFOptionsButton"]
        if svfOptionsBtn then
            switchButton:SetPoint("LEFT", svfOptionsBtn, "RIGHT", 5, 0)
        else
            switchButton:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 130, -35)
        end

        switchButton:SetFrameStrata("HIGH")
    end

    switchButton:Show()
    self:UpdateSwitchButtonState()
end

function Scoots:UpdateSwitchButtonState()
    if not switchButton then return end

    -- SVF.off = false means filtering is ON
    local isFiltering = SVF and not SVF.off

    if isFiltering then
        if switchButton.SetBackdropBorderColor then
            switchButton:SetBackdropBorderColor(0.2, 0.8, 0.4, 1)
        end
        if switchButton.text then
            switchButton.text:SetTextColor(0.4, 1, 0.6, 1)
        end
    else
        if switchButton.SetBackdropBorderColor then
            switchButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end
        if switchButton.text then
            switchButton.text:SetTextColor(0.9, 0.9, 0.9, 1)
        end
    end
end

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

function Scoots:ToggleVendorFilter()
    if not SVF then
        KOL:DebugPrint("Scoots: SVF not loaded, cannot toggle", 1)
        return
    end

    -- Replicate the exact logic from SVFToggleOffButton OnClick handler
    -- (from ScootsVendorFilter.lua lines 1338-1347)
    if SVF.off == true then
        SVF.off = false
        if SVF.frame then
            SVF.frame:Show()
        end
        if SVF.synopsisFrame then
            SVF.synopsisFrame:Show()
        end
        KOL:DebugPrint("Scoots: Switched to FILTERED vendor view", 3)
    else
        SVF.off = true
        if SVF.frame then
            SVF.frame:Hide()
        end
        if SVF.synopsisFrame then
            SVF.synopsisFrame:Hide()
        end
        if SVF.showMerchantUi then
            SVF.showMerchantUi()
        end
        KOL:DebugPrint("Scoots: Switched to DEFAULT vendor view", 3)
    end

    C_Timer.After(0.05, function()
        self:UpdateSwitchButtonState()
    end)
end

function Scoots:CheckAutoSwitch()
    if not SVF then return end

    local isFiltering = not SVF.off
    local noItems = (SVF.items == nil or #SVF.items == 0)

    if isFiltering and noItems then
        KOL:DebugPrint("Scoots: Auto-switching (no filtered items available)", 2)
        self:ToggleVendorFilter()
        KOL:PrintTag("|cFFFFAA00Auto-switched|r vendor to show all items (no filtered items)")
    end
end

KOL:DebugPrint("Scoots module loaded", 3)
