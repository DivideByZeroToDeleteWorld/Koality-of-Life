-- Koality-of-Life: ItemTracker Module
-- Track items with customizable font display

local addonName = "Koality-of-Life"
local KOL = KoalityOfLife
local LSM = LibStub("LibSharedMedia-3.0")

-- Create module
local ItemTracker = {}
KOL.itemtracker = ItemTracker

-- Module defaults (self-contained)
local moduleDefaults = {
    font = "Friz Quadrata TT",
    fontSize = 14,  -- Increased from 12 for better visibility
    fontOutline = "THICKOUTLINE",  -- Changed from OUTLINE for better visibility
}

-- Font outline options with descriptions
local fontOutlineOptions = {
    ["NONE"] = "None",
    ["OUTLINE"] = "Outline",
    ["THICKOUTLINE"] = "Thick Outline",
    ["MONOCHROME"] = "Monochrome",
    ["OUTLINE, MONOCHROME"] = "Outline + Monochrome",
    ["THICKOUTLINE, MONOCHROME"] = "Thick Outline + Monochrome",
}

-- ============================================================================
-- Module Initialization (Self-Contained)
-- ============================================================================

function ItemTracker:Initialize()
    -- Register module defaults with main database
    if not KOL.db.profile.itemtracker then
        KOL.db.profile.itemtracker = {}
    end
    
    -- Apply defaults for any missing values
    for key, value in pairs(moduleDefaults) do
        if KOL.db.profile.itemtracker[key] == nil then
            KOL.db.profile.itemtracker[key] = value
        end
    end
    
    -- Initialize UI config
    self:InitializeConfig()
    
    -- Apply font settings
    self:ApplyFontSettings()
    
    KOL:DebugPrint("ItemTracker module initialized")
end

-- Auto-initialize when core is ready
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" and KOL.db then
        ItemTracker:Initialize()
        
        -- Register slash command for test frame
        if KOL.RegisterSlashCommand then
            KOL:RegisterSlashCommand("testfont", function()
                ItemTracker:CreateTestFrame()
            end, "Show/hide ItemTracker font test frame")
        end
    end
end)

-- ============================================================================
-- Font Management
-- ============================================================================

function ItemTracker:ApplyFontSettings()
    local settings = KOL.db.profile.itemtracker
    
    -- Get the font path from LibSharedMedia
    local fontPath = LSM:Fetch("font", settings.font)
    
    if not fontPath then
        KOL:PrintTag(RED("Error:") .. " Font '" .. settings.font .. "' not found, using default")
        fontPath = "Fonts\\FRIZQT__.TTF"
    end
    
    local fontSize = settings.fontSize
    local fontOutline = settings.fontOutline
    
    KOL:DebugPrint("Applying font: " .. settings.font .. ", size: " .. fontSize .. ", outline: " .. fontOutline)
    
    -- TODO: Apply font settings to your ItemTracker frames
    -- Example for a frame you create:
    -- if self.frame and self.frame.text then
    --     self.frame.text:SetFont(fontPath, fontSize, fontOutline)
    -- end
    
    -- Store for easy access
    self.currentFont = fontPath
    self.currentFontSize = fontSize
    self.currentFontOutline = fontOutline
end

-- Create a sample frame to demonstrate font settings
function ItemTracker:CreateSampleFrame()
    if self.sampleFrame then
        return self.sampleFrame
    end
    
    local frame = CreateFrame("Frame", "KOL_ItemTrackerSample", UIParent)
    frame:SetSize(200, 50)
    frame:SetPoint("CENTER", 0, 0)
    
    -- Create text display
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER")
    text:SetText("Sample Text")
    
    frame.text = text
    self.sampleFrame = frame
    
    return frame
end

-- ============================================================================
-- Configuration UI
-- ============================================================================

function ItemTracker:InitializeConfig()
    -- Create the ItemTracker config group
    KOL:UIAddConfigGroup("itemtracker", "Item Tracker", 10)
    
    -- Add header
    KOL:UIAddConfigTitle("itemtracker", "header", "Font Customization", 1)
    
    -- Add description
    KOL:UIAddConfigDescription(
        "itemtracker",
        "desc",
        "|cFFAAAAAACustomize the font appearance for item tracking displays.|r\n",
        2
    )
    
    -- Font selection dropdown
    KOL:UIAddConfigFontSelect("itemtracker", "font", {
        name = "|cFF88AAFFFont Face|r",
        desc = "Select the font to use for item tracking",
        order = 10,
        get = function()
            return KOL.db.profile.itemtracker.font
        end,
        set = function(_, value)
            KOL.db.profile.itemtracker.font = value
            ItemTracker:ApplyFontSettings()
            KOL:PrintTag("Font changed to: " .. YELLOW(value))
        end,
    })
    
    -- Font size slider
    KOL:UIAddConfigSlider("itemtracker", "fontSize", {
        name = "|cFF88AAFFFont Size|r",
        desc = "Set the size of the font (6-32 points)",
        min = 6,
        max = 32,
        step = 1,
        order = 20,
        get = function()
            return KOL.db.profile.itemtracker.fontSize
        end,
        set = function(_, value)
            KOL.db.profile.itemtracker.fontSize = value
            ItemTracker:ApplyFontSettings()
            KOL:PrintTag("Font size changed to: " .. YELLOW(value))
        end,
    })
    
    -- Font outline dropdown
    KOL:UIAddConfigSelect("itemtracker", "fontOutline", {
        name = "|cFF88AAFFFont Outline|r",
        desc = "Select the outline style for the font",
        values = fontOutlineOptions,
        order = 30,
        width = "double",
        get = function()
            return KOL.db.profile.itemtracker.fontOutline
        end,
        set = function(_, value)
            KOL.db.profile.itemtracker.fontOutline = value
            ItemTracker:ApplyFontSettings()
            KOL:PrintTag("Font outline changed to: " .. YELLOW(fontOutlineOptions[value]))
        end,
    })
    
    -- Spacer
    KOL:UIAddConfigSpacer("itemtracker", "spacer1", 40)
    
    -- Preview section
    KOL:UIAddConfigTitle("itemtracker", "previewHeader", "Preview", 50)
    
    KOL:UIAddConfigDescription(
        "itemtracker",
        "previewDesc",
        "|cFFAAAAAAChanges apply immediately. You can see the current font settings below:|r\n" ..
        "|cFFFFFFFFFont:|r " .. "|cFF88AAFF" .. KOL.db.profile.itemtracker.font .. "|r\n" ..
        "|cFFFFFFFFSize:|r " .. "|cFF88AAFF" .. KOL.db.profile.itemtracker.fontSize .. "|r\n" ..
        "|cFFFFFFFFOutline:|r " .. "|cFF88AAFF" .. fontOutlineOptions[KOL.db.profile.itemtracker.fontOutline] .. "|r",
        51
    )
    
    -- Reset button
    KOL:UIAddConfigExecute("itemtracker", "reset", {
        name = "|cFFFF6600Reset to Defaults|r",
        desc = "Reset all font settings to their default values",
        order = 60,
        func = function()
            KOL.db.profile.itemtracker.font = "Friz Quadrata TT"
            KOL.db.profile.itemtracker.fontSize = 12
            KOL.db.profile.itemtracker.fontOutline = "OUTLINE"
            ItemTracker:ApplyFontSettings()
            KOL:PrintTag("Font settings " .. GREEN("reset to defaults"))
            
            -- Refresh the config dialog to update the preview text
            LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
        end,
    })
end

-- ============================================================================
-- Example: Create a test frame with the configured font
-- ============================================================================

function ItemTracker:CreateTestFrame()
    if self.testFrame then
        if self.testFrame:IsShown() then
            self.testFrame:Hide()
            KOL:PrintTag("Test frame " .. RED("hidden"))
        else
            self.testFrame:Show()
            KOL:PrintTag("Test frame " .. GREEN("shown"))
        end
        return
    end
    
    -- Create a draggable test frame
    local frame = CreateFrame("Frame", "KOL_ItemTrackerTest", UIParent)
    frame:SetSize(300, 100)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", 0, -15)
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    title:SetText(RainbowText("ItemTracker Test Frame"))
    
    -- Sample text
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", 0, 0)
    text:SetText("Sample Item Text")
    
    -- Apply current font settings
    local fontPath = LSM:Fetch("font", KOL.db.profile.itemtracker.font)
    text:SetFont(fontPath, KOL.db.profile.itemtracker.fontSize, KOL.db.profile.itemtracker.fontOutline)
    
    -- Close button
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function()
        ItemTracker:DestroyTestFrame()
    end)
    
    frame.text = text
    self.testFrame = frame
    
    KOL:PrintTag("Test frame created! " .. YELLOW("Drag to move, click X to close"))
end

-- Destroy test frame and free memory
function ItemTracker:DestroyTestFrame()
    if self.testFrame then
        KOL:DebugPrint("Destroying ItemTracker test frame...")
        self.testFrame:Hide()
        self.testFrame = nil
        KOL:PrintTag("Test frame " .. RED("destroyed"))
    end
end

-- Helper function to create rainbow text (same as UI module)
function RainbowText(text)
    local rainbowColors = {
        "FF0000", "FF4400", "FF8800", "FFCC00", "FFFF00", "CCFF00",
        "88FF00", "44FF00", "00FF00", "00FF88", "00FFFF", "55AAFF",
        "7799FF", "8888FF", "AA66FF"
    }
    
    local result = ""
    local colorIndex = 1
    
    for i = 1, #text do
        local char = text:sub(i, i)
        result = result .. "|cFF" .. rainbowColors[colorIndex] .. char
        colorIndex = colorIndex + 1
        if colorIndex > #rainbowColors then
            colorIndex = 1
        end
    end
    
    return result .. "|r"
end
