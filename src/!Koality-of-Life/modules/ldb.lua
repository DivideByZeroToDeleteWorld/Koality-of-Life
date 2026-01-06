-- ============================================================================
-- LDB Module - LibDataBroker minimap icon with cascading menu system
-- ============================================================================

local addonName = "!Koality-of-Life"
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

if not LDB or not LDBIcon then
    return
end

-- Local references
local KOL = KoalityOfLife

-- Module namespace
KOL.LDB = KOL.LDB or {}
local LDBModule = KOL.LDB

-- ============================================================================
-- Constants
-- ============================================================================

local MENU_WIDTH = 200
local ITEM_HEIGHT = 20
local HEADER_HEIGHT = 24
local LABEL_HEIGHT = 18
local SEPARATOR_HEIGHT = 10
local PADDING = 6
local SUBMENU_OFFSET = 2

-- Colors
local COLORS = {
    LABEL = {r = 0.4, g = 0.8, b = 1},      -- Sky blue for labels
    FOLDER = {r = 1, g = 0.85, b = 0.4},     -- Gold for folders
    ITEM = {r = 0.85, g = 0.85, b = 0.85},   -- Light gray for items
    HOVER_BG = {r = 0.2, g = 0.2, b = 0.2},  -- Hover background
    SEPARATOR = {r = 0.4, g = 0.4, b = 0.4}, -- Separator line
    ARROW = {r = 0.6, g = 0.6, b = 0.6},     -- Arrow color
    VERSION = {r = 0.5, g = 0.5, b = 0.5},   -- Version text
}

-- Icons - use directly available constants or literal characters
local function GetIcon(name)
    local icons = {
        ARROW_RIGHT = CHAR_ARROW_RIGHTFILLED or "▶",
        ARROW_LEFT = CHAR_ARROW_LEFTFILLED or "◄",
        FOLDER = "▸",      -- Small triangle right
        SETTINGS = "◆",    -- Filled diamond
        RELOAD = "↔",      -- Left-right arrow (back and forth/refresh)
        CLOSE = "×",       -- Multiplication sign (clean X)
    }
    return icons[name] or ""
end

-- ============================================================================
-- Tooltip Pool Management (memory leak prevention)
-- ============================================================================

local tooltipPool = {}
local activeTooltips = {}
local mainTooltip = nil
local clickCatcher = nil  -- Fullscreen frame to catch clicks outside menu

local function GetFont()
    local fontPath = "Fonts\\FRIZQT__.TTF"
    local fontOutline = "OUTLINE"

    if KOL.db and KOL.db.profile then
        local LSM = LibStub("LibSharedMedia-3.0", true)
        if LSM then
            local generalFont = KOL.db.profile.generalFont or "Friz Quadrata TT"
            fontPath = LSM:Fetch("font", generalFont) or fontPath
        end
        fontOutline = KOL.db.profile.generalFontOutline or fontOutline
    end

    return fontPath, fontOutline
end

local function AcquireTooltip()
    local tooltip = table.remove(tooltipPool)
    if not tooltip then
        tooltip = CreateFrame("Frame", nil, UIParent)
        tooltip:SetFrameStrata("TOOLTIP")
        tooltip:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        tooltip.items = {}
        tooltip.regions = {}
    end

    tooltip:SetParent(UIParent)
    tooltip:ClearAllPoints()
    tooltip:Show()
    table.insert(activeTooltips, tooltip)
    return tooltip
end

local function ReleaseTooltip(tooltip)
    if not tooltip then return end

    -- CRITICAL: Disable keyboard capture first to release input focus
    tooltip:EnableKeyboard(false)
    tooltip:SetScript("OnKeyDown", nil)

    -- Hide and clear
    tooltip:Hide()
    tooltip:ClearAllPoints()

    -- Clear item buttons
    for _, item in ipairs(tooltip.items) do
        item:EnableMouse(false)  -- Release mouse on buttons
        item:Hide()
        item:SetParent(nil)
    end
    wipe(tooltip.items)

    -- Clear regions (textures, fontstrings)
    -- Note: Fonts and textures cannot have nil parent, just hide them
    for _, region in ipairs(tooltip.regions) do
        if region.Hide then region:Hide() end
        -- Only reparent frames, not textures/fontstrings (they error on nil parent)
        if region.SetParent and region:IsObjectType("Frame") then
            region:SetParent(nil)
        end
    end
    wipe(tooltip.regions)

    -- Remove from active list
    for i, t in ipairs(activeTooltips) do
        if t == tooltip then
            table.remove(activeTooltips, i)
            break
        end
    end

    -- Return to pool
    table.insert(tooltipPool, tooltip)
end

local function ReleaseAllTooltips()
    -- Release all except main tooltip
    for i = #activeTooltips, 1, -1 do
        local tooltip = activeTooltips[i]
        if tooltip ~= mainTooltip then
            ReleaseTooltip(tooltip)
        end
    end
end

local function ReleaseEverything()
    -- Release all tooltips (disables keyboard/mouse on each)
    for i = #activeTooltips, 1, -1 do
        ReleaseTooltip(activeTooltips[i])
    end
    mainTooltip = nil

    -- CRITICAL: Fully disable click catcher to release all mouse input
    if clickCatcher then
        clickCatcher:EnableMouse(false)
        clickCatcher:Hide()
    end
end

-- Create fullscreen click catcher (only once)
-- Uses LOW strata so other UI elements (BugSack, etc.) receive clicks first
-- Only catches clicks on "empty space" that no other frame handles
local function GetClickCatcher()
    if not clickCatcher then
        clickCatcher = CreateFrame("Button", nil, UIParent)
        -- Use LOW strata - this ensures:
        -- 1. Our menu at TOOLTIP strata is clickable (above this)
        -- 2. Other addons like BugSack at DIALOG strata receive their clicks (above this)
        -- 3. Only "background" clicks that nothing else handles come here
        clickCatcher:SetFrameStrata("LOW")
        clickCatcher:SetFrameLevel(1)
        clickCatcher:SetAllPoints(UIParent)
        clickCatcher:EnableMouse(true)
        clickCatcher:RegisterForClicks("AnyUp")  -- Catch any mouse button
        clickCatcher:SetScript("OnClick", function(self, button)
            -- Hide self FIRST to release mouse, then clean up menu
            self:Hide()
            self:EnableMouse(false)
            -- Now clean up the menu
            pcall(ReleaseEverything)
        end)
        clickCatcher:Hide()
    end
    return clickCatcher
end

-- ============================================================================
-- Screen Edge Detection
-- ============================================================================

local function GetScreenPosition(frame)
    local x, y = frame:GetCenter()
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()

    return {
        x = x,
        y = y,
        nearRight = (x + frame:GetWidth() / 2) > (screenWidth * 0.7),
        nearLeft = (x - frame:GetWidth() / 2) < (screenWidth * 0.3),
        nearTop = (y + frame:GetHeight() / 2) > (screenHeight * 0.8),
        nearBottom = (y - frame:GetHeight() / 2) < (screenHeight * 0.2),
    }
end

local function WouldOverflowRight(parentFrame, childWidth)
    local parentRight = parentFrame and parentFrame:GetRight()
    if not parentRight then return false end  -- Can't determine, default to not overflow
    local screenWidth = GetScreenWidth()
    return (parentRight + childWidth + SUBMENU_OFFSET) > screenWidth
end

-- ============================================================================
-- Tooltip Creation
-- ============================================================================

local function ApplyThemeColors(tooltip)
    -- Default colors
    local bgColor = {r = 0.05, g = 0.05, b = 0.05, a = 0.98}
    local borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1}

    -- Check for user-configured popup colors first
    if KOL.db and KOL.db.profile then
        if KOL.db.profile.popupBgColor then
            bgColor = KOL.db.profile.popupBgColor
        end
        if KOL.db.profile.popupBorderColor then
            borderColor = KOL.db.profile.popupBorderColor
        end
    end

    tooltip:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.98)
    tooltip:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
end

local function CreateLabel(tooltip, text, yOffset, color)
    local fontPath, fontOutline = GetFont()

    local label = tooltip:CreateFontString(nil, "OVERLAY")
    label:SetFont(fontPath, 10, fontOutline)
    label:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING + 4, yOffset)
    label:SetTextColor(color.r, color.g, color.b, 1)
    label:SetText(text)
    table.insert(tooltip.regions, label)

    return LABEL_HEIGHT
end

local function CreateSeparator(tooltip, yOffset, text)
    local fontPath, fontOutline = GetFont()

    if text then
        -- Text separator (--- Options ---)
        local sepText = tooltip:CreateFontString(nil, "OVERLAY")
        sepText:SetFont(fontPath, 9, fontOutline)
        sepText:SetPoint("TOP", tooltip, "TOP", 0, yOffset - 3)
        sepText:SetTextColor(COLORS.SEPARATOR.r, COLORS.SEPARATOR.g, COLORS.SEPARATOR.b, 0.8)
        sepText:SetText(text)
        table.insert(tooltip.regions, sepText)
    else
        -- Line separator
        local line = tooltip:CreateTexture(nil, "ARTWORK")
        line:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING + 4, yOffset - 4)
        line:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -PADDING - 4, yOffset - 4)
        line:SetHeight(1)
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetVertexColor(COLORS.SEPARATOR.r, COLORS.SEPARATOR.g, COLORS.SEPARATOR.b, 0.4)
        table.insert(tooltip.regions, line)
    end

    return SEPARATOR_HEIGHT
end

-- Styled section header (matches UIFactory:CreateSectionHeader and KOL_SectionHeader style)
local SECTION_HEADER_HEIGHT = 22
local function CreateSectionHeader(tooltip, yOffset, text, color)
    local fontPath, fontOutline = GetFont()
    color = color or COLORS.LABEL

    -- Get alpha from popup background setting (so section headers match popup transparency)
    local bgAlpha = 0.8
    if KOL.db and KOL.db.profile and KOL.db.profile.popupBgColor then
        bgAlpha = KOL.db.profile.popupBgColor.a or 0.98
    end

    -- Background - subtle dark using accent color at 20% intensity
    -- Use BORDER layer so it appears above the popup's backdrop but below ARTWORK/OVERLAY
    local bg = tooltip:CreateTexture(nil, "BORDER")
    bg:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING, yOffset)
    bg:SetPoint("BOTTOMRIGHT", tooltip, "TOPRIGHT", -PADDING, yOffset - SECTION_HEADER_HEIGHT)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(color.r * 0.2, color.g * 0.2, color.b * 0.2, bgAlpha)
    table.insert(tooltip.regions, bg)

    -- Left accent bar (3px wide)
    local accent = tooltip:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING, yOffset)
    accent:SetSize(3, SECTION_HEADER_HEIGHT)
    accent:SetTexture("Interface\\Buttons\\WHITE8X8")
    accent:SetVertexColor(color.r, color.g, color.b, 1)
    table.insert(tooltip.regions, accent)

    -- Text in accent color (vertically centered)
    local label = tooltip:CreateFontString(nil, "OVERLAY")
    label:SetFont(fontPath, 11, fontOutline)
    label:SetPoint("LEFT", tooltip, "TOPLEFT", PADDING + 10, yOffset - (SECTION_HEADER_HEIGHT / 2))
    label:SetTextColor(color.r, color.g, color.b, 1)
    label:SetText(text)
    table.insert(tooltip.regions, label)

    return SECTION_HEADER_HEIGHT + 2  -- Small gap after
end

local function CreateSettingRow(tooltip, yOffset, settingName, value, onClick)
    local fontPath, fontOutline = GetFont()
    local ROW_HEIGHT = 14

    -- Create a button frame if clickable, otherwise just use tooltip as parent
    local rowFrame
    if onClick then
        rowFrame = CreateFrame("Button", nil, tooltip)
        rowFrame:SetSize(MENU_WIDTH - (PADDING * 2), ROW_HEIGHT)
        rowFrame:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING, yOffset)
        rowFrame:EnableMouse(true)
        rowFrame:RegisterForClicks("LeftButtonUp")

        -- Background for hover
        rowFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        rowFrame:SetBackdropColor(0, 0, 0, 0)

        -- Hover effects
        rowFrame:SetScript("OnEnter", function(self)
            self:SetBackdropColor(COLORS.HOVER_BG.r, COLORS.HOVER_BG.g, COLORS.HOVER_BG.b, 1)
        end)
        rowFrame:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0, 0, 0, 0)
        end)

        -- Click handler
        rowFrame:SetScript("OnClick", onClick)

        table.insert(tooltip.items, rowFrame)
    end

    local parent = rowFrame or tooltip
    local leftOffset = onClick and 6 or (PADDING + 6)
    local rightOffset = onClick and -6 or (-PADDING - 6)

    -- Setting name on left
    local nameText = parent:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(fontPath, 9, fontOutline)
    if onClick then
        nameText:SetPoint("LEFT", parent, "LEFT", leftOffset, 0)
    else
        nameText:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING + 6, yOffset - 2)
    end
    nameText:SetTextColor(0.7, 0.7, 0.7, 1)  -- Gray for setting name
    nameText:SetText(settingName .. ":")
    table.insert(tooltip.regions, nameText)

    -- Value on right (colored green/red based on boolean)
    local valueText = parent:CreateFontString(nil, "OVERLAY")
    valueText:SetFont(fontPath, 9, fontOutline)
    if onClick then
        valueText:SetPoint("RIGHT", parent, "RIGHT", rightOffset, 0)
    else
        valueText:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -PADDING - 6, yOffset - 2)
    end

    if type(value) == "boolean" then
        if value then
            valueText:SetTextColor(0.3, 1, 0.3, 1)  -- Green for YES/enabled
            valueText:SetText("YES")
        else
            valueText:SetTextColor(1, 0.3, 0.3, 1)  -- Red for NO/disabled
            valueText:SetText("NO")
        end
    else
        valueText:SetTextColor(0.9, 0.9, 0.9, 1)  -- White for other values
        valueText:SetText(tostring(value))
    end
    table.insert(tooltip.regions, valueText)

    -- Store references for updating
    if rowFrame then
        rowFrame.nameText = nameText
        rowFrame.valueText = valueText
    end

    return ROW_HEIGHT
end

local function CreateMenuItem(tooltip, itemData, yOffset, expandLeft)
    local fontPath, fontOutline = GetFont()
    local UIFactory = KOL.UIFactory

    local btn = CreateFrame("Button", nil, tooltip)
    btn:SetSize(MENU_WIDTH - (PADDING * 2), ITEM_HEIGHT)
    btn:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING, yOffset)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Background for hover
    btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    btn:SetBackdropColor(0, 0, 0, 0)

    -- Icon (if folder or has icon) - using UIFactory:CreateGlyph for proper font
    local textOffset = 6

    if itemData.isFolder then
        local folderIcon = itemData.icon or GetIcon("FOLDER")
        if UIFactory and UIFactory.CreateGlyph then
            local icon = UIFactory:CreateGlyph(btn, folderIcon, COLORS.FOLDER, 10)
            icon:SetPoint("LEFT", btn, "LEFT", 6, 0)
        end
        textOffset = 22
    elseif itemData.icon then
        if UIFactory and UIFactory.CreateGlyph then
            local icon = UIFactory:CreateGlyph(btn, itemData.icon, {r = 0.8, g = 0.8, b = 0.8}, 10)
            icon:SetPoint("LEFT", btn, "LEFT", 6, 0)
        end
        textOffset = 22
    end

    -- Text
    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetFont(fontPath, 10, fontOutline)
    text:SetPoint("LEFT", btn, "LEFT", textOffset, 0)
    text:SetJustifyH("LEFT")

    local textColor = itemData.color or COLORS.ITEM
    if itemData.coloredText then
        text:SetText(itemData.text)
    else
        text:SetTextColor(textColor.r, textColor.g, textColor.b, 1)
        text:SetText(itemData.text)
    end
    btn.text = text
    btn.textColor = textColor

    -- Arrow for folders - using UIFactory:CreateGlyph for proper font
    if itemData.isFolder then
        local arrowChar = expandLeft and GetIcon("ARROW_LEFT") or GetIcon("ARROW_RIGHT")
        if UIFactory and UIFactory.CreateGlyph then
            local arrow = UIFactory:CreateGlyph(btn, arrowChar, COLORS.ARROW, 8)
            arrow:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
            btn.arrow = arrow
        end
        btn.arrowChar = arrowChar
        btn.expandLeft = expandLeft
    end

    -- Store data
    btn.itemData = itemData
    btn.parentTooltip = tooltip

    -- Hover effects
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(COLORS.HOVER_BG.r, COLORS.HOVER_BG.g, COLORS.HOVER_BG.b, 1)
        if self.text and not self.itemData.coloredText then
            self.text:SetTextColor(1, 1, 1, 1)
        end
        if self.arrow and self.arrow.SetGlyph then
            self.arrow:SetGlyph(self.arrowChar, {r = 1, g = 1, b = 1})
        end

        -- Show submenu if folder
        if self.itemData.isFolder and self.itemData.children then
            LDBModule:ShowSubmenu(self, self.itemData.children, self.itemData.title, self.expandLeft)
        else
            -- Close any open submenus at this level
            LDBModule:CloseSubmenusFrom(self.parentTooltip)
        end
    end)

    btn:SetScript("OnLeave", function(self)
        -- Check if mouse is over a child submenu
        local isOverChild = false
        for _, t in ipairs(activeTooltips) do
            if t.parentButton == self and MouseIsOver(t) then
                isOverChild = true
                break
            end
        end

        if not isOverChild then
            self:SetBackdropColor(0, 0, 0, 0)
            if self.text and not self.itemData.coloredText then
                self.text:SetTextColor(self.textColor.r, self.textColor.g, self.textColor.b, 1)
            end
            if self.arrow and self.arrow.SetGlyph then
                self.arrow:SetGlyph(self.arrowChar, COLORS.ARROW)
            end
        end
    end)

    -- Click handler - folders show submenu, items with onClick perform action
    if itemData.isFolder and itemData.children then
        btn:SetScript("OnClick", function(self)
            -- Toggle submenu on click as well as hover
            pcall(function()
                LDBModule:ShowSubmenu(self, self.itemData.children, self.itemData.title, self.expandLeft)
            end)
        end)
    elseif itemData.onClick then
        btn:SetScript("OnClick", function(self)
            -- Close menu first, then execute action (in case action errors)
            pcall(ReleaseEverything)
            pcall(self.itemData.onClick)
        end)
    end

    table.insert(tooltip.items, btn)
    return ITEM_HEIGHT
end

-- ============================================================================
-- Submenu Management
-- ============================================================================

function LDBModule:CloseSubmenusFrom(parentTooltip)
    -- Close all tooltips that are children of this parent
    for i = #activeTooltips, 1, -1 do
        local tooltip = activeTooltips[i]
        if tooltip.parentTooltip == parentTooltip then
            -- Recursively close children
            self:CloseSubmenusFrom(tooltip)
            ReleaseTooltip(tooltip)
        end
    end
end

function LDBModule:ShowSubmenu(parentButton, items, title, expandLeft)
    -- Close existing submenus from this parent
    self:CloseSubmenusFrom(parentButton.parentTooltip)

    local fontPath, fontOutline = GetFont()
    local tooltip = AcquireTooltip()
    tooltip.parentButton = parentButton
    tooltip.parentTooltip = parentButton.parentTooltip

    ApplyThemeColors(tooltip)
    tooltip:SetFrameLevel(parentButton.parentTooltip:GetFrameLevel() + 1)

    -- Determine if we should expand left based on screen position
    if expandLeft == nil then
        expandLeft = WouldOverflowRight(parentButton.parentTooltip, MENU_WIDTH)
    end

    -- Calculate height
    local yOffset = -PADDING
    local totalHeight = PADDING * 2

    -- Add centered title header
    if title then
        local header = tooltip:CreateFontString(nil, "OVERLAY")
        header:SetFont(fontPath, 10, fontOutline)
        header:SetPoint("TOP", tooltip, "TOP", 0, yOffset - 2)
        header:SetTextColor(COLORS.LABEL.r, COLORS.LABEL.g, COLORS.LABEL.b, 1)
        header:SetText(title)
        table.insert(tooltip.regions, header)
        yOffset = yOffset - HEADER_HEIGHT
        totalHeight = totalHeight + HEADER_HEIGHT

        -- Add separator after header
        local sepHeight = CreateSeparator(tooltip, yOffset)
        yOffset = yOffset - sepHeight
        totalHeight = totalHeight + sepHeight
    end

    -- Check if submenu items would overflow right
    local childExpandLeft = WouldOverflowRight(tooltip, MENU_WIDTH)

    -- Add items
    for _, item in ipairs(items) do
        local itemHeight = CreateMenuItem(tooltip, item, yOffset, childExpandLeft)
        yOffset = yOffset - itemHeight
        totalHeight = totalHeight + itemHeight
    end

    tooltip:SetSize(MENU_WIDTH, totalHeight)

    -- Position relative to parent button
    tooltip:ClearAllPoints()
    if expandLeft then
        tooltip:SetPoint("TOPRIGHT", parentButton, "TOPLEFT", -SUBMENU_OFFSET, SUBMENU_OFFSET)
    else
        tooltip:SetPoint("TOPLEFT", parentButton, "TOPRIGHT", SUBMENU_OFFSET, SUBMENU_OFFSET)
    end

    -- Handle mouse leaving
    tooltip:SetScript("OnLeave", function(self)
        C_Timer.After(0.05, function()
            if not tooltip:IsShown() then return end

            -- Check if mouse is over this tooltip or any child
            local isOverSelf = MouseIsOver(tooltip)
            local isOverChild = false
            for _, t in ipairs(activeTooltips) do
                if t.parentTooltip == tooltip and MouseIsOver(t) then
                    isOverChild = true
                    break
                end
            end

            -- Check if mouse is back on parent
            local isOverParent = parentButton and MouseIsOver(parentButton)

            if not isOverSelf and not isOverChild and not isOverParent then
                LDBModule:CloseSubmenusFrom(parentButton.parentTooltip)
            end
        end)
    end)
end

-- ============================================================================
-- Menu Data Structure
-- ============================================================================

local function GetMenuStructure()
    local structure = {}

    -- Gather test commands dynamically
    local testItems = {}
    if KOL.slashCommands then
        for cmdName, data in pairs(KOL.slashCommands) do
            if data.category == "test" then
                table.insert(testItems, {
                    text = cmdName,
                    onClick = function()
                        KOL:TestSlashCommand(cmdName)
                    end,
                })
            end
        end
        table.sort(testItems, function(a, b) return a.text < b.text end)
    end

    -- Modules folder contents
    local moduleItems = {
        {
            text = "Progress Tracker",
            icon = CHAR_OBJECTIVE_UNCOMPLETE or "○",
            isFolder = true,
            title = "Progress Tracker",
            children = {
                { text = "Toggle Manager", onClick = function() if KOL.ShowTrackerManager then KOL:ShowTrackerManager() end end },
                { text = "Create Custom Tracker", onClick = function() if KOL.ShowTrackerManager then KOL:ShowTrackerManager() end end },
                { text = "Refresh All", onClick = function() if KOL.Tracker then KOL.Tracker:RefreshAllTrackers() end end },
            },
        },
        {
            text = "Macro Updater",
            icon = CHAR_SHAPES_DIAMOND or "◆",
            onClick = function()
                if KOL.MacroUpdater then
                    KOL.MacroUpdater:ShowUI()
                end
            end,
        },
        {
            text = "Boss Recorder",
            icon = "†",  -- Dagger symbol
            isFolder = true,
            title = "Boss Recorder",
            children = {
                { text = "Enable Recording", onClick = function() if KOL.BossRecorder then KOL.BossRecorder:Enable() end end },
                { text = "List Recordings", onClick = function() if KOL.BossRecorder then KOL.BossRecorder:ListRecordings() end end },
                { text = "Stop Recording", onClick = function() if KOL.BossRecorder then KOL.BossRecorder:Stop() end end },
            },
        },
        {
            text = "Key Bindings",
            icon = "☼",  -- Cog/settings symbol
            onClick = function()
                KOL:OpenConfig()
                -- Note: Would need bindings tab navigation
            end,
        },
        {
            text = "Debug Console",
            icon = "★",  -- Star symbol
            onClick = function() KOL:ToggleDebugConsole() end,
        },
        {
            text = "Character Viewer",
            icon = "☺",  -- Smiley face
            onClick = function() KOL:ToggleCharViewer() end,
        },
        {
            text = "Theme Editor",
            icon = "♫",  -- Music notes (creative/artistic)
            onClick = function()
                if KOL.ThemeEditor then
                    KOL.ThemeEditor:Toggle()
                end
            end,
        },
        {
            text = "Racial Swap",
            icon = "☻",  -- Filled smiley (person/character)
            isFolder = true,
            title = "Racial Swap",
            children = (function()
                local items = {
                    {
                        text = "Toggle Racial (/krs)",
                        onClick = function() KOL:ToggleRacial() end
                    },
                }

                -- Build racial selection submenus dynamically
                local validRaces = KOL.GetValidRacials and KOL:GetValidRacials() or {}

                if #validRaces > 0 then
                    -- Set Primary submenu
                    local primaryChildren = {}
                    for _, race in ipairs(validRaces) do
                        table.insert(primaryChildren, {
                            text = race,
                            onClick = function()
                                KOL.db.profile.racialPrimary = race
                                KOL:PrintTag("Primary racial set to: " .. race)
                            end,
                        })
                    end
                    table.insert(items, {
                        text = "Set Primary",
                        isFolder = true,
                        title = "Set Primary Racial",
                        children = primaryChildren,
                    })

                    -- Set Secondary submenu
                    local secondaryChildren = {}
                    for _, race in ipairs(validRaces) do
                        table.insert(secondaryChildren, {
                            text = race,
                            onClick = function()
                                KOL.db.profile.racialSecondary = race
                                KOL:PrintTag("Secondary racial set to: " .. race)
                            end,
                        })
                    end
                    table.insert(items, {
                        text = "Set Secondary",
                        isFolder = true,
                        title = "Set Secondary Racial",
                        children = secondaryChildren,
                    })

                    -- Quick set items for each race
                    table.insert(items, { text = "---", disabled = true })
                    for _, race in ipairs(validRaces) do
                        table.insert(items, {
                            text = "Switch to " .. race,
                            onClick = function() KOL:SetRacial(race) end,
                        })
                    end
                end

                return items
            end)(),
        },
    }

    -- Standalone folder contents
    local standaloneItems = {
        { text = "/kmu - Macro Updater", onClick = function() if KOL.MacroUpdater then KOL.MacroUpdater:ShowUI() end end },
        { text = "/kdc - Debug Console", onClick = function() KOL:ToggleDebugConsole() end },
        { text = "/kc - Config Panel", onClick = function() KOL:OpenConfig() end },
        { text = "/kld - Limit Damage", onClick = function() KOL:ToggleLimitDamage() end },
        { text = "/krs - Racial Swap", onClick = function() KOL:ToggleRacial() end },
        { text = "/rl - Reload UI", onClick = function() ReloadUI() end },
        {
            text = "Difficulty Commands",
            isFolder = true,
            title = "Difficulty",
            children = {
                { text = "/r25h - 25 Heroic", onClick = function() KOL:SetRaidDifficulty(4, "25 Man Heroic") end },
                { text = "/r25n - 25 Normal", onClick = function() KOL:SetRaidDifficulty(2, "25 Man Normal") end },
                { text = "/r10h - 10 Heroic", onClick = function() KOL:SetRaidDifficulty(3, "10 Man Heroic") end },
                { text = "/r10n - 10 Normal", onClick = function() KOL:SetRaidDifficulty(1, "10 Man Normal") end },
                { text = "/d5h - Dungeon Heroic", onClick = function() KOL:SetDungeonDifficulty(2, "5 Player Heroic") end },
                { text = "/d5n - Dungeon Normal", onClick = function() KOL:SetDungeonDifficulty(1, "5 Player Normal") end },
            },
        },
    }

    -- Config options (tabs)
    local configItems = {
        { text = "General", onClick = function() KOL:OpenConfig() LibStub("AceConfigDialog-3.0"):SelectGroup("KoalityOfLife", "general") end },
        { text = "Progress Tracker", onClick = function() KOL:OpenConfig() LibStub("AceConfigDialog-3.0"):SelectGroup("KoalityOfLife", "tracker") end },
        { text = "Tweaks", onClick = function() KOL:OpenConfig() LibStub("AceConfigDialog-3.0"):SelectGroup("KoalityOfLife", "tweaks") end },
        { text = "Command Blocks", onClick = function() KOL:OpenConfig() LibStub("AceConfigDialog-3.0"):SelectGroup("KoalityOfLife", "commandblocks") end },
    }

    return {
        modules = moduleItems,
        tests = testItems,
        standalone = standaloneItems,
        config = configItems,
    }
end

-- ============================================================================
-- Main Menu
-- ============================================================================

function LDBModule:ShowMainMenu(anchor)
    -- Close any existing menu
    ReleaseEverything()

    local fontPath, fontOutline = GetFont()
    local tooltip = AcquireTooltip()
    mainTooltip = tooltip

    ApplyThemeColors(tooltip)
    tooltip:SetFrameLevel(100)

    local menuData = GetMenuStructure()
    local yOffset = -PADDING
    local totalHeight = PADDING * 2

    -- ========================================================================
    -- Header: Rainbow title + version
    -- ========================================================================

    local rainbowTitle = "|cFFFF6600K|cFFFF8800o|cFFFFAA00a|cFFFFCC00l|cFFFFEE00i|cFFDDFF00t|cFFBBFF00y|cFF99FF00-|cFF77FF00o|cFF55FF00f|cFF33FF00-|cFF00FF33L|cFF00FF66i|cFF00FF99f|cFF00FFCCe|r"

    local title = tooltip:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontPath, 11, fontOutline)
    title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING + 4, yOffset - 4)
    title:SetText(rainbowTitle)
    table.insert(tooltip.regions, title)

    local version = tooltip:CreateFontString(nil, "OVERLAY")
    version:SetFont(fontPath, 9, fontOutline)
    version:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -PADDING - 4, yOffset - 6)
    version:SetTextColor(COLORS.VERSION.r, COLORS.VERSION.g, COLORS.VERSION.b, 1)
    version:SetText("v" .. (KOL.version or "?"))
    table.insert(tooltip.regions, version)

    yOffset = yOffset - HEADER_HEIGHT
    totalHeight = totalHeight + HEADER_HEIGHT

    -- Separator after header
    local sepHeight = CreateSeparator(tooltip, yOffset)
    yOffset = yOffset - sepHeight
    totalHeight = totalHeight + sepHeight

    -- Check if we should expand submenus left based on anchor position
    -- (moved here so it's available for all submenus including RACIAL)
    local expandLeft = false
    if anchor then
        local anchorX = anchor:GetCenter()
        expandLeft = anchorX and anchorX > (GetScreenWidth() * 0.7)
    end

    -- ========================================================================
    -- Current Settings Section
    -- ========================================================================

    local currentHeaderHeight = CreateSectionHeader(tooltip, yOffset, "CURRENT", COLORS.LABEL)
    yOffset = yOffset - currentHeaderHeight
    totalHeight = totalHeight + currentHeaderHeight

    -- Limit Damage setting (clickable to toggle)
    local limitDamageValue = KOL.db and KOL.db.profile and KOL.db.profile.limitDamage or false
    local limitDamageRowHeight = CreateSettingRow(tooltip, yOffset, "LIMIT DAMAGE", limitDamageValue, function(self)
        -- Toggle the setting (same as /kld)
        KOL:ToggleLimitDamage()

        -- Update the display immediately
        local newValue = KOL.db.profile.limitDamage
        if newValue then
            self.valueText:SetTextColor(0.3, 1, 0.3, 1)  -- Green for YES
            self.valueText:SetText("YES")
        else
            self.valueText:SetTextColor(1, 0.3, 0.3, 1)  -- Red for NO
            self.valueText:SetText("NO")
        end
    end)
    yOffset = yOffset - limitDamageRowHeight
    totalHeight = totalHeight + limitDamageRowHeight

    -- Current Racial setting (clickable folder with submenu)
    local currentRacial = KOL.GetCurrentRacial and KOL:GetCurrentRacial() or "Unknown"
    local validRaces = KOL.GetValidRacials and KOL:GetValidRacials() or {}

    -- Build submenu children for racial selection (cascading submenus)
    local racialChildren = {}

    -- Quick toggle option at the top
    local primary = KOL.db.profile.racialPrimary or "Unknown"
    local secondary = KOL.db.profile.racialSecondary or "Unknown"
    table.insert(racialChildren, {
        text = "|cFFAAAAAAToggle:|r " .. primary .. " <-> " .. secondary,
        coloredText = true,
        onClick = function()
            KOL:ToggleRacial()
        end,
    })

    -- Build Primary submenu children
    local primaryChildren = {}
    for _, race in ipairs(validRaces) do
        local isPrimary = (race == KOL.db.profile.racialPrimary)
        table.insert(primaryChildren, {
            text = race .. (isPrimary and " |cFF00FF00(Current)|r" or ""),
            coloredText = isPrimary,
            onClick = function()
                KOL.db.profile.racialPrimary = race
                KOL:PrintTag("Primary racial set to: |cFF00FF00" .. race .. "|r")
            end,
        })
    end

    -- Build Secondary submenu children
    local secondaryChildren = {}
    for _, race in ipairs(validRaces) do
        local isSecondary = (race == KOL.db.profile.racialSecondary)
        table.insert(secondaryChildren, {
            text = race .. (isSecondary and " |cFF00FFFF(Current)|r" or ""),
            coloredText = isSecondary,
            onClick = function()
                KOL.db.profile.racialSecondary = race
                KOL:PrintTag("Secondary racial set to: |cFF00FFFF" .. race .. "|r")
            end,
        })
    end

    -- Build Quick Set submenu children
    local quickSetChildren = {}
    for _, race in ipairs(validRaces) do
        local isCurrent = (race == currentRacial)
        table.insert(quickSetChildren, {
            text = race .. (isCurrent and " |cFF00FF00(Active)|r" or ""),
            coloredText = isCurrent,
            onClick = function()
                KOL:SetRacial(race)
            end,
        })
    end

    -- Add Primary folder
    table.insert(racialChildren, {
        text = "Primary",
        isFolder = true,
        title = "Set Primary Racial",
        children = primaryChildren,
        color = {r = 0.3, g = 1, b = 0.3},  -- Green for primary
    })

    -- Add Secondary folder
    table.insert(racialChildren, {
        text = "Secondary",
        isFolder = true,
        title = "Set Secondary Racial",
        children = secondaryChildren,
        color = {r = 0.3, g = 1, b = 1},  -- Cyan for secondary
    })

    -- Add Quick Set folder
    table.insert(racialChildren, {
        text = "Quick Set",
        isFolder = true,
        title = "Quick Set Racial",
        children = quickSetChildren,
        color = {r = 1, g = 0.8, b = 0.3},  -- Gold for quick set
    })

    -- Create the racial row as a clickable folder item
    local racialItemHeight = CreateMenuItem(tooltip, {
        text = "RACIAL: " .. currentRacial,
        isFolder = true,
        title = "Racial Selection",
        children = racialChildren,
        color = {r = 0.7, g = 0.7, b = 0.7},
    }, yOffset, expandLeft)
    yOffset = yOffset - racialItemHeight
    totalHeight = totalHeight + racialItemHeight

    -- Separator after current settings
    local currentSepHeight = CreateSeparator(tooltip, yOffset)
    yOffset = yOffset - currentSepHeight
    totalHeight = totalHeight + currentSepHeight

    -- ========================================================================
    -- Shortcuts Label
    -- ========================================================================

    local shortcutsHeaderHeight = CreateSectionHeader(tooltip, yOffset, "SHORTCUTS", COLORS.LABEL)
    yOffset = yOffset - shortcutsHeaderHeight
    totalHeight = totalHeight + shortcutsHeaderHeight

    -- ========================================================================
    -- Folders: Modules, Tests, Standalone
    -- ========================================================================

    -- Modules folder
    local modulesHeight = CreateMenuItem(tooltip, {
        text = "Modules",
        isFolder = true,
        title = "Modules",
        children = menuData.modules,
        color = COLORS.FOLDER,
    }, yOffset, expandLeft)
    yOffset = yOffset - modulesHeight
    totalHeight = totalHeight + modulesHeight

    -- Tests folder (only if tests exist)
    if #menuData.tests > 0 then
        local testsHeight = CreateMenuItem(tooltip, {
            text = "Tests",
            isFolder = true,
            title = "Tests",
            children = menuData.tests,
            color = COLORS.FOLDER,
        }, yOffset, expandLeft)
        yOffset = yOffset - testsHeight
        totalHeight = totalHeight + testsHeight
    end

    -- Standalone folder
    local standaloneHeight = CreateMenuItem(tooltip, {
        text = "Standalone",
        isFolder = true,
        title = "Standalone",
        children = menuData.standalone,
        color = COLORS.FOLDER,
    }, yOffset, expandLeft)
    yOffset = yOffset - standaloneHeight
    totalHeight = totalHeight + standaloneHeight

    -- ========================================================================
    -- Options Header (styled section header with accent bar)
    -- ========================================================================

    local optionsHeaderHeight = CreateSectionHeader(tooltip, yOffset, "OPTIONS", COLORS.LABEL)
    yOffset = yOffset - optionsHeaderHeight
    totalHeight = totalHeight + optionsHeaderHeight

    -- ========================================================================
    -- Config Tab Items
    -- ========================================================================

    for _, configItem in ipairs(menuData.config) do
        local itemHeight = CreateMenuItem(tooltip, configItem, yOffset, expandLeft)
        yOffset = yOffset - itemHeight
        totalHeight = totalHeight + itemHeight
    end

    -- ========================================================================
    -- Utility Options (Reload UI, Close)
    -- ========================================================================

    local utilSepHeight = CreateSeparator(tooltip, yOffset)
    yOffset = yOffset - utilSepHeight
    totalHeight = totalHeight + utilSepHeight

    local reloadHeight = CreateMenuItem(tooltip, {
        text = "Reload UI",
        icon = GetIcon("RELOAD"),
        color = {r = 0.7, g = 0.7, b = 0.4},
        onClick = function()
            ReloadUI()
        end,
    }, yOffset, expandLeft)
    yOffset = yOffset - reloadHeight
    totalHeight = totalHeight + reloadHeight

    local closeHeight = CreateMenuItem(tooltip, {
        text = "Close",
        icon = GetIcon("CLOSE"),
        color = {r = 0.6, g = 0.6, b = 0.6},
        onClick = function()
            ReleaseEverything()
        end,
    }, yOffset, expandLeft)
    yOffset = yOffset - closeHeight
    totalHeight = totalHeight + closeHeight

    -- ========================================================================
    -- Set size and position
    -- ========================================================================

    tooltip:SetSize(MENU_WIDTH, totalHeight)

    -- Position near anchor
    tooltip:ClearAllPoints()
    if anchor then
        local anchorX, anchorY = anchor:GetCenter()
        local screenWidth = GetScreenWidth()
        local screenHeight = GetScreenHeight()

        -- Determine best position
        if anchorY > screenHeight / 2 then
            -- Anchor is in top half, show below
            if anchorX > screenWidth / 2 then
                tooltip:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", 0, -2)
            else
                tooltip:SetPoint("TOPLEFT", anchor, "BOTTOMRIGHT", 0, -2)
            end
        else
            -- Anchor is in bottom half, show above
            if anchorX > screenWidth / 2 then
                tooltip:SetPoint("BOTTOMRIGHT", anchor, "TOPLEFT", 0, 2)
            else
                tooltip:SetPoint("BOTTOMLEFT", anchor, "TOPRIGHT", 0, 2)
            end
        end
    else
        -- Position at cursor
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        tooltip:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    end

    -- ========================================================================
    -- Close on click outside (using fullscreen click catcher)
    -- ========================================================================

    local catcher = GetClickCatcher()
    -- Frame level already set in GetClickCatcher() - strata (LOW) handles layering
    catcher:EnableMouse(true)  -- Re-enable after previous ReleaseEverything disabled it
    catcher:Show()

    -- Close on escape (with error protection)
    tooltip:EnableKeyboard(true)
    tooltip:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            pcall(ReleaseEverything)
            if self.SetPropagateKeyboardInput then
                self:SetPropagateKeyboardInput(false)
            end
        else
            if self.SetPropagateKeyboardInput then
                self:SetPropagateKeyboardInput(true)
            end
        end
    end)

    -- Also register for global escape as backup
    if not LDBModule.escapeFrame then
        LDBModule.escapeFrame = CreateFrame("Frame", nil, UIParent)
        LDBModule.escapeFrame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" and mainTooltip and mainTooltip:IsShown() then
                pcall(ReleaseEverything)
            end
        end)
        -- SetPropagateKeyboardInput may not exist in older WoW versions
        if LDBModule.escapeFrame.SetPropagateKeyboardInput then
            LDBModule.escapeFrame:SetPropagateKeyboardInput(true)
        end
    end
end

function LDBModule:HideMenu()
    ReleaseEverything()
end

function LDBModule:ToggleMenu(anchor)
    if mainTooltip and mainTooltip:IsShown() then
        ReleaseEverything()
    else
        self:ShowMainMenu(anchor)
    end
end

-- ============================================================================
-- LDB Data Object (created lazily in Initialize to respect settings)
-- ============================================================================

local dataObject = nil  -- Will be created in Initialize() if LDB plugin is enabled

-- Debug flag - set to true to debug LDB text issues (causes spam, disable after testing)
local ldbSpeedDebug = false

-- ChocolateBar font hook state (declared here so debug commands can access them)
local chocolateBarFontHooked = false
local chocolateBarHookAttempts = 0
local chocolateBarHookMaxAttempts = 20  -- Try for 10 seconds (20 * 0.5s)

local function CreateDataObject()
    if dataObject then return dataObject end

    -- Determine initial text based on saved setting
    -- IMPORTANT: Use PLAIN ASCII text initially - no color codes or Unicode!
    -- ChocolateBar can't render those until our font hook applies.
    -- The fancy formatted text will be set by UpdateLDBText after font hook.
    local initialText = "KoL"
    if KOL.db and KOL.db.profile and KOL.db.profile.ldbTextMode == "speed" then
        local showPrefix = KOL.db.profile.ldbSpeedPrefix or false
        -- Simple ASCII only - ChocolateBar will display this correctly
        initialText = showPrefix and "SPEED: IDLE" or "IDLE"

        -- DEBUG: Print what we're setting
        if ldbSpeedDebug then
            print("|cFF00FFFF[LDB DEBUG]|r CreateDataObject - initialText = '" .. tostring(initialText) .. "' (plain ASCII)")
        end
    end

    dataObject = LDB:NewDataObject("!Koality-of-Life", {
        type = "launcher",
        label = "Koality-of-Life",  -- Friendly name shown in LDB display addons
        text = initialText,         -- Initial text (KoL or BASE depending on mode)
        icon = "Interface\\AddOns\\!Koality-of-Life\\media\\images\\stevefurwin_normal",

        OnClick = function(self, button)
            -- Ignore clicks if LDB plugin is hidden
            if LDBModule:IsLDBHidden() then return end

            if button == "LeftButton" then
                LDBModule:ToggleMenu(self)
            elseif button == "RightButton" then
                KOL:OpenConfig()
            elseif button == "MiddleButton" then
                if KOL.ShowTrackerManager then
                    KOL:ShowTrackerManager()
                end
            end
        end,

        OnEnter = function(self)
            -- Hover effect: brighten/highlight the icon
            -- LibDBIcon buttons have an icon texture we can modify
            if self.icon then
                self.icon:SetVertexColor(1.2, 1.2, 1.2, 1)  -- Slightly brighter
            end
        end,

        OnLeave = function(self)
            -- Reset icon
            if self.icon then
                self.icon:SetVertexColor(1, 1, 1, 1)
            end
        end,

        -- No OnTooltipShow - we use custom menu instead
    })

    return dataObject
end

-- ============================================================================
-- Initialization
-- ============================================================================

function LDBModule:Initialize()
    -- Prevent double initialization (both PLAYER_LOGIN and PLAYER_ENTERING_WORLD fire on login)
    -- But allow re-initialization on reload (when chocolateBarFontHooked is reset to false)
    if self.initialized and chocolateBarFontHooked then
        KOL:DebugPrint("LDB: Already initialized, skipping", 3)
        return
    end
    self.initialized = true

    -- Initialize minimap icon database if needed
    if not KOL.db.profile.minimap then
        KOL.db.profile.minimap = {
            hide = false,
            minimapPos = 220,
            lock = false,
        }
    end

    -- Check if LDB plugin should be created at all
    -- If disabled, we don't create the dataObject - making it invisible to all LDB display addons
    local showLDB = KOL.db.profile.showLDBPlugin
    if showLDB == nil then showLDB = true end  -- Default to enabled

    if showLDB then
        -- Create the data object (this registers with LDB, making it visible to display addons)
        CreateDataObject()

        -- Register with LibDBIcon for minimap button (only if not already registered)
        if dataObject and not LDBIcon:IsRegistered("!Koality-of-Life") then
            LDBIcon:Register("!Koality-of-Life", dataObject, KOL.db.profile.minimap)
        end
    else
        -- LDB plugin disabled - don't create dataObject at all
        -- This means NO LDB display addon will see it
        KOL:DebugPrint("LDB plugin disabled - not registering with LibDataBroker", 2)
    end

    -- Apply minimap visibility (independent of LDB plugin setting)
    self:UpdateMinimapVisibility()

    -- Apply LDB text setting (speed display, etc.)
    self:UpdateLDBText()

    -- Hook minimap button for hover/click effects
    self:HookMinimapButton()

    -- Hook ChocolateBar font for proper glyph rendering
    self:HookChocolateBarFont()

    -- Retry timer: Keep trying to set the text until ChocolateBar accepts it
    -- This is needed because ChocolateBar may not be ready when we first try
    self:StartTextRetryTimer()

    -- Register emergency close command
    if KOL.RegisterSlashCommand then
        KOL:RegisterSlashCommand("closemenu", function()
            LDBModule:ForceCloseMenu()
        end, "Force close LDB menu if stuck", "utility")

        -- Debug command to test speed text
        KOL:RegisterSlashCommand("speedtest", function()
            print("|cFF00FFFF=== SPEED DEBUG ===|r")

            -- Test ReturnSpeedData
            local data = KOL:ReturnSpeedData()
            print("|cFFFFFF00ReturnSpeedData:|r")
            print("  text = '" .. tostring(data.text) .. "'")
            print("  color = '" .. tostring(data.color) .. "'")
            print("  glyph = '" .. tostring(data.glyph) .. "'")
            print("  isMoving = " .. tostring(data.isMoving))

            -- Test ReturnSpeedText
            local textNoPrefix = KOL:ReturnSpeedText(false)
            local textWithPrefix = KOL:ReturnSpeedText(true)
            print("|cFFFFFF00ReturnSpeedText:|r")
            print("  without prefix = '" .. tostring(textNoPrefix) .. "'")
            print("  with prefix = '" .. tostring(textWithPrefix) .. "'")

            -- Show what dataObject currently has
            if dataObject then
                print("|cFFFFFF00dataObject.text:|r '" .. tostring(dataObject.text) .. "'")
            else
                print("|cFFFF0000dataObject is nil!|r")
            end

            -- Show chocolateBarFontHooked status
            print("|cFFFFFF00chocolateBarFontHooked:|r " .. tostring(chocolateBarFontHooked))

            -- Try to directly set the text and show result
            if dataObject then
                local testText = "SPEED: TEST"
                dataObject.text = testText
                print("|cFF00FF00Set dataObject.text to:|r '" .. testText .. "'")
                print("|cFF00FF00dataObject.text after:|r '" .. tostring(dataObject.text) .. "'")
            end

            print("|cFF00FFFF=== END DEBUG ===|r")
        end, "Debug speed text output", "test")

        -- Debug command to check ChocolateBar font hook status
        KOL:RegisterSlashCommand("ldbfont", function()
            print("|cFF00FFFF=== LDB FONT DEBUG ===|r")

            -- Check chocolateBarFontHooked flag
            print("|cFFFFFF00chocolateBarFontHooked:|r " .. tostring(chocolateBarFontHooked))
            print("|cFFFFFF00chocolateBarHookAttempts:|r " .. tostring(chocolateBarHookAttempts))

            -- Check if CHAR_LIGATURESFONT is defined
            print("|cFFFFFF00CHAR_LIGATURESFONT:|r " .. tostring(CHAR_LIGATURESFONT))

            -- Check for our expected frame
            local frameName = "Chocolate!Koality-of-Life"
            local chocolateFrame = _G[frameName]
            print("|cFFFFFF00Frame '" .. frameName .. "':|r " .. tostring(chocolateFrame))

            if chocolateFrame then
                print("  .text exists: " .. tostring(chocolateFrame.text ~= nil))
                if chocolateFrame.text then
                    local fontPath, fontSize, fontFlags = chocolateFrame.text:GetFont()
                    print("  Current font: " .. tostring(fontPath))
                    print("  Font size: " .. tostring(fontSize))
                    print("  Font flags: " .. tostring(fontFlags))
                    print("  Expected font: " .. tostring(CHAR_LIGATURESFONT))
                    print("  Font matches: " .. tostring(fontPath == CHAR_LIGATURESFONT))
                end
            end

            -- Search for any frame starting with "Chocolate"
            print("|cFFFFFF00Searching for Chocolate* frames...|r")
            local found = 0
            for name, frame in pairs(_G) do
                if type(name) == "string" and name:find("^Chocolate") and type(frame) == "table" and frame.GetObjectType then
                    found = found + 1
                    print("  Found: " .. name .. " (" .. tostring(frame:GetObjectType()) .. ")")
                    if found >= 10 then
                        print("  ... (limited to 10)")
                        break
                    end
                end
            end
            if found == 0 then
                print("  No Chocolate* frames found!")
            end

            -- Offer to force re-apply
            print("|cFF00FF00Tip:|r Run /kol ldbfontfix to force re-apply the font hook")

            print("|cFF00FFFF=== END DEBUG ===|r")
        end, "Debug LDB font hook status", "test")

        -- Force fix the font hook
        KOL:RegisterSlashCommand("ldbfontfix", function()
            print("|cFFFFFF00Forcing ChocolateBar font hook re-apply...|r")
            chocolateBarFontHooked = false
            chocolateBarHookAttempts = 0
            LDBModule:HookChocolateBarFont()
            print("|cFF00FF00Done.|r Check /kol ldbfont for status.")
        end, "Force re-apply LDB font hook", "test")
    end

    KOL:DebugPrint("LDB module initialized with cascading menu", 2)
end

function LDBModule:Show()
    LDBIcon:Show("!Koality-of-Life")
    KOL.db.profile.minimap.hide = false
end

function LDBModule:Hide()
    LDBIcon:Hide("!Koality-of-Life")
    KOL.db.profile.minimap.hide = true
end

function LDBModule:Toggle()
    if KOL.db.profile.minimap.hide then
        self:Show()
    else
        self:Hide()
    end
end

function LDBModule:IsShown()
    return not KOL.db.profile.minimap.hide
end

function LDBModule:Lock()
    LDBIcon:Lock("!Koality-of-Life")
    KOL.db.profile.minimap.lock = true
end

function LDBModule:Unlock()
    LDBIcon:Unlock("!Koality-of-Life")
    KOL.db.profile.minimap.lock = false
end

-- Visibility control functions (called from settings)
function LDBModule:UpdateMinimapVisibility()
    -- Only works if LDB was registered (showLDBPlugin was enabled at login)
    if not dataObject then return end

    local showMinimap = KOL.db.profile.showMinimapButton
    if showMinimap == nil then showMinimap = true end  -- Default to shown

    if showMinimap then
        LDBIcon:Show("!Koality-of-Life")
        KOL.db.profile.minimap.hide = false
    else
        LDBIcon:Hide("!Koality-of-Life")
        KOL.db.profile.minimap.hide = true
    end
end

-- LDB visibility control
-- Now supports dynamic enable/disable for ChocolateBar!
function LDBModule:UpdateLDBVisibility()
    local showLDB = KOL.db.profile.showLDBPlugin
    if showLDB == nil then showLDB = true end

    if showLDB then
        -- ENABLE LDB Plugin
        if not dataObject then
            -- Create it now (late registration)
            CreateDataObject()

            -- Register with LibDBIcon for minimap button
            if dataObject then
                LDBIcon:Register("!Koality-of-Life", dataObject, KOL.db.profile.minimap)
                self:UpdateMinimapVisibility()
                self:HookMinimapButton()
            end
        end

        -- Enable in ChocolateBar if available
        if ChocolateBar and ChocolateBar.EnableDataObject and dataObject then
            ChocolateBar:EnableDataObject("!Koality-of-Life", dataObject)
            KOL:PrintTag("LDB Plugin enabled in ChocolateBar!")
            -- Re-hook the font since ChocolateBar may recreate the frame
            chocolateBarFontHooked = false
            self:HookChocolateBarFont()
        elseif dataObject then
            KOL:PrintTag("LDB Plugin enabled!")
        end
    else
        -- DISABLE LDB Plugin
        -- Use ChocolateBar's API if available (no reload needed!)
        if ChocolateBar and ChocolateBar.DisableDataObject then
            ChocolateBar:DisableDataObject("!Koality-of-Life")
            KOL:PrintTag("LDB Plugin disabled in ChocolateBar!")
        else
            -- Other display addons don't have a disable API - need reload
            KOL:PrintTag("LDB Plugin will be hidden after reload. Type /rl to reload now.")
        end
    end
end

-- LDB Text update (for dynamic text like Speed display)
local ldbTextUpdateFrame = nil

function LDBModule:UpdateLDBText()
    if not dataObject then return end

    local textMode = KOL.db.profile.ldbTextMode or "none"

    if textMode == "speed" then
        -- Check if prefix should be shown
        local showPrefix = KOL.db.profile.ldbSpeedPrefix or false

        -- Helper to get speed text
        -- Always use colored text - WoW color codes work in any font
        -- Only the glyph needs the special ligatures font (handled by HookChocolateBarFont)
        local function GetSpeedText(withPrefix)
            return KOL:ReturnSpeedText(withPrefix)
        end

        -- Update text immediately
        local newText = GetSpeedText(showPrefix)
        dataObject.text = newText

        -- DEBUG: Print what we're setting (only until speed works)
        if ldbSpeedDebug then
            print("|cFF00FFFF[LDB DEBUG]|r UpdateLDBText - setting text = '" .. tostring(newText) .. "' (fontHooked=" .. tostring(chocolateBarFontHooked) .. ")")
            print("|cFF00FFFF[LDB DEBUG]|r UpdateLDBText - dataObject.text after = '" .. tostring(dataObject.text) .. "'")
        end

        -- Start update timer if not already running
        if not ldbTextUpdateFrame then
            ldbTextUpdateFrame = CreateFrame("Frame")
            ldbTextUpdateFrame.elapsed = 0
            ldbTextUpdateFrame.debugCount = 0  -- Limit debug spam
            ldbTextUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = self.elapsed + elapsed
                if self.elapsed < 0.1 then return end  -- Update every 0.1 seconds
                self.elapsed = 0

                -- Only update if speed mode is still active
                local mode = KOL.db.profile.ldbTextMode or "none"
                if mode == "speed" and dataObject then
                    local prefix = KOL.db.profile.ldbSpeedPrefix or false
                    local text = GetSpeedText(prefix)
                    dataObject.text = text

                    -- DEBUG: Print first few updates and when it changes from IDLE
                    if ldbSpeedDebug then
                        self.debugCount = (self.debugCount or 0) + 1
                        if self.debugCount <= 5 then
                            print("|cFF00FFFF[LDB DEBUG]|r OnUpdate #" .. self.debugCount .. " - text = '" .. tostring(text) .. "' (fontHooked=" .. tostring(chocolateBarFontHooked) .. ")")
                        end
                        -- Stop debugging once we see actual movement
                        if text and (text:find("%%") or text:find("BASE")) then
                            print("|cFF00FF00[LDB DEBUG]|r Speed detected! Disabling debug. Final text = '" .. tostring(text) .. "'")
                            ldbSpeedDebug = false
                        end
                    end
                else
                    -- Stop updating if mode changed
                    self:Hide()
                end
            end)
        end
        ldbTextUpdateFrame:Show()
    else
        -- Default/none mode - show static text
        dataObject.text = "KoL"

        -- Stop update timer if running
        if ldbTextUpdateFrame then
            ldbTextUpdateFrame:Hide()
        end
    end
end

-- ============================================================================
-- Text Retry Timer
-- Keeps trying to set the LDB text until ChocolateBar actually displays it
-- ============================================================================

local textRetryTimer = nil
local textRetryAttempts = 0
local textRetryMaxAttempts = 20  -- Max 20 attempts (2 seconds total at 0.1s intervals)

function LDBModule:StartTextRetryTimer()
    if not dataObject then return end

    -- Only needed for speed mode
    local textMode = KOL.db.profile.ldbTextMode or "none"
    if textMode ~= "speed" then return end

    textRetryAttempts = 0

    -- Create timer frame if needed
    if not textRetryTimer then
        textRetryTimer = CreateFrame("Frame")
        textRetryTimer.elapsed = 0
        textRetryTimer:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed < 0.1 then return end
            self.elapsed = 0

            textRetryAttempts = textRetryAttempts + 1

            -- Set the text with full formatting (color + glyph)
            local showPrefix = KOL.db.profile.ldbSpeedPrefix or false
            local newText = KOL:ReturnSpeedText(showPrefix)
            dataObject.text = newText

            -- Check if ChocolateBar frame exists and has our text
            local chocolateFrame = _G["Chocolate!Koality-of-Life"]
            local displayedText = chocolateFrame and chocolateFrame.text and chocolateFrame.text:GetText()

            -- Success check: displayed text contains "IDLE" or a speed value (not just "SPEED:...")
            local success = displayedText and (
                displayedText:find("IDLE") or
                displayedText:find("BASE") or
                displayedText:find("%%")
            )

            if success then
                -- It worked! Stop retrying
                KOL:DebugPrint("LDB: Text retry succeeded after " .. textRetryAttempts .. " attempts", 2)
                ldbSpeedDebug = false  -- Disable debug spam
                self:Hide()
                return
            end

            -- Give up after max attempts
            if textRetryAttempts >= textRetryMaxAttempts then
                KOL:DebugPrint("LDB: Text retry gave up after " .. textRetryAttempts .. " attempts", 1)
                self:Hide()
                return
            end
        end)
    end

    textRetryTimer:Show()
end

-- ============================================================================
-- ChocolateBar Font Hack
-- Forces our ligatures font on the ChocolateBar frame for proper glyph rendering
-- ============================================================================

function LDBModule:HookChocolateBarFont()
    if chocolateBarFontHooked then return end

    chocolateBarHookAttempts = chocolateBarHookAttempts + 1

    -- The ChocolateBar frame is named "Chocolate" .. pluginName
    local frameName = "Chocolate!Koality-of-Life"

    -- Try to find the frame
    local chocolateFrame = _G[frameName]

    if chocolateFrame and chocolateFrame.text then
        -- Found it - override the font to our ligatures font
        local fontSize = select(2, chocolateFrame.text:GetFont()) or 12

        -- Verify CHAR_LIGATURESFONT exists
        if not CHAR_LIGATURESFONT then
            KOL:PrintTag("|cFFFF0000ERROR:|r CHAR_LIGATURESFONT is nil! Font hook cannot apply.")
            return
        end

        chocolateFrame.text:SetFont(CHAR_LIGATURESFONT, fontSize, CHAR_LIGATURESOUTLINE or "OUTLINE")
        chocolateBarFontHooked = true
        KOL:DebugPrint("LDB: ChocolateBar font hack applied after " .. chocolateBarHookAttempts .. " attempts", 1)

        -- Also hook the Update function to re-apply our font when ChocolateBar updates
        if chocolateFrame.Update then
            local origUpdate = chocolateFrame.Update
            chocolateFrame.Update = function(self, attr, value, name)
                origUpdate(self, attr, value, name)
                -- Re-apply our font after any update
                if self.text then
                    local size = select(2, self.text:GetFont()) or 12
                    self.text:SetFont(CHAR_LIGATURESFONT, size, CHAR_LIGATURESOUTLINE or "OUTLINE")
                end
            end
        end

        -- NOW that font is ready, trigger text update to use styled glyphs
        self:UpdateLDBText()
    else
        -- Frame not created yet, try again shortly
        if chocolateBarHookAttempts < chocolateBarHookMaxAttempts then
            C_Timer.After(0.5, function()
                self:HookChocolateBarFont()
            end)
        else
            -- Give up after max attempts - frame never appeared
            KOL:DebugPrint("LDB: ChocolateBar font hack gave up after " .. chocolateBarHookAttempts .. " attempts - frame not found", 1)
        end
    end
end

-- Hook minimap button for custom menu and square appearance
function LDBModule:HookMinimapButton()
    C_Timer.After(0.1, function()
        local button = LDBIcon.objects and LDBIcon.objects["!Koality-of-Life"]
        if button and not button.kolHooked then
            button.kolHooked = true
            local iconTexture = button.icon or button.Icon

            -- ============================================================
            -- CUSTOM DRAG BEHAVIOR - Square edge positioning
            -- ============================================================
            local EDGE_OFFSET = 10  -- Distance from minimap edge to button center
            local currentAngle = KOL.db.profile.minimap.minimapPos or 220

            -- Position button along square edge at given angle
            -- Store at module level so it can be called on zone changes etc.
            local function PositionAtAngle(angle)
                local rads = math.rad(angle)
                local cos_a = math.cos(rads)
                local sin_a = math.sin(rads)

                -- Get minimap half-size (square minimap)
                local halfSize = (Minimap:GetWidth() / 2) + EDGE_OFFSET

                -- Calculate intersection with square boundary
                local abs_cos = math.abs(cos_a)
                local abs_sin = math.abs(sin_a)
                local t

                if abs_cos < 0.001 then
                    t = halfSize / abs_sin
                elseif abs_sin < 0.001 then
                    t = halfSize / abs_cos
                elseif abs_cos > abs_sin then
                    t = halfSize / abs_cos
                else
                    t = halfSize / abs_sin
                end

                local x = cos_a * t
                local y = sin_a * t

                button:ClearAllPoints()
                button:SetPoint("CENTER", Minimap, "CENTER", x, y)
            end

            -- Store function at module level for external access
            LDBModule.PositionMinimapButton = function()
                local angle = KOL.db.profile.minimap.minimapPos or 220
                currentAngle = angle
                PositionAtAngle(angle)
            end

            -- Calculate expected position for a given angle (for verification)
            local function GetExpectedPosition(angle)
                local rads = math.rad(angle)
                local cos_a = math.cos(rads)
                local sin_a = math.sin(rads)
                local halfSize = (Minimap:GetWidth() / 2) + EDGE_OFFSET
                local abs_cos = math.abs(cos_a)
                local abs_sin = math.abs(sin_a)
                local t
                if abs_cos < 0.001 then
                    t = halfSize / abs_sin
                elseif abs_sin < 0.001 then
                    t = halfSize / abs_cos
                elseif abs_cos > abs_sin then
                    t = halfSize / abs_cos
                else
                    t = halfSize / abs_sin
                end
                return cos_a * t, sin_a * t
            end

            -- Self-canceling position verifier
            -- Checks position periodically and fixes if wrong, cancels when stable
            local positionTicker = nil
            local correctCount = 0
            local POSITION_TOLERANCE = 2  -- pixels
            local REQUIRED_CORRECT_CHECKS = 3

            LDBModule.StartPositionVerifier = function()
                -- Cancel existing ticker if any
                if positionTicker then
                    positionTicker:Cancel()
                    positionTicker = nil
                end
                correctCount = 0

                positionTicker = C_Timer.NewTicker(0.2, function()
                    if not button or not button:IsShown() then
                        return
                    end

                    local angle = KOL.db.profile.minimap.minimapPos or 220
                    local expectedX, expectedY = GetExpectedPosition(angle)
                    local mx, my = Minimap:GetCenter()
                    local bx, by = button:GetCenter()

                    if mx and my and bx and by then
                        local actualOffsetX = bx - mx
                        local actualOffsetY = by - my
                        local diffX = math.abs(actualOffsetX - expectedX)
                        local diffY = math.abs(actualOffsetY - expectedY)

                        if diffX <= POSITION_TOLERANCE and diffY <= POSITION_TOLERANCE then
                            -- Position is correct
                            correctCount = correctCount + 1
                            if correctCount >= REQUIRED_CORRECT_CHECKS then
                                -- Position has been stable, cancel ticker
                                positionTicker:Cancel()
                                positionTicker = nil
                                KOL:DebugPrint("LDB: Minimap button position verified, ticker stopped", 3)
                            end
                        else
                            -- Position is wrong, fix it
                            correctCount = 0
                            currentAngle = angle
                            PositionAtAngle(angle)
                            KOL:DebugPrint("LDB: Fixed minimap button position (off by " .. string.format("%.1f, %.1f", diffX, diffY) .. ")", 3)
                        end
                    end
                end)

                KOL:DebugPrint("LDB: Started position verifier ticker", 3)
            end

            LDBModule.StopPositionVerifier = function()
                if positionTicker then
                    positionTicker:Cancel()
                    positionTicker = nil
                    KOL:DebugPrint("LDB: Position verifier stopped manually", 3)
                end
            end

            -- Apply initial position
            PositionAtAngle(currentAngle)

            -- Start position verifier on initial setup
            LDBModule.StartPositionVerifier()

            -- Hook OnShow to re-apply position whenever button becomes visible
            button:HookScript("OnShow", function()
                C_Timer.After(0, function()
                    PositionAtAngle(currentAngle)
                end)
                -- Restart verifier when button shows
                LDBModule.StartPositionVerifier()
            end)

            -- Block ALL of LibDBIcon's SetPoint calls - we handle positioning entirely
            local origSetPoint = button.SetPoint
            button.SetPoint = function(self, ...)
                -- Only allow our own calls (identified by first arg being "CENTER" to Minimap)
                local point, relativeTo = ...
                if point == "CENTER" and relativeTo == Minimap then
                    origSetPoint(self, ...)
                end
                -- Block everything else (LibDBIcon's repositioning)
            end

            -- Completely replace drag behavior
            local isDragging = false

            -- Remove LibDBIcon's drag scripts entirely
            button:SetScript("OnDragStart", function(self)
                isDragging = true
                self:SetScript("OnUpdate", function(self)
                    -- Get cursor position and calculate angle to minimap center
                    local cx, cy = GetCursorPosition()
                    local scale = UIParent:GetEffectiveScale()
                    cx, cy = cx / scale, cy / scale

                    local mx, my = Minimap:GetCenter()
                    if mx and my then
                        local dx, dy = cx - mx, cy - my
                        currentAngle = math.deg(math.atan2(dy, dx))
                        PositionAtAngle(currentAngle)
                    end
                end)
            end)

            button:SetScript("OnDragStop", function(self)
                isDragging = false
                self:SetScript("OnUpdate", nil)
                -- Save the angle
                KOL.db.profile.minimap.minimapPos = currentAngle
            end)

            -- ============================================================
            -- Make button SQUARE instead of round
            -- ============================================================
            -- Hide ALL textures except the icon (removes circular border/overlay/mask)
            local regions = {button:GetRegions()}
            for _, region in ipairs(regions) do
                if region:GetObjectType() == "Texture" and region ~= iconTexture then
                    region:Hide()
                end
            end

            -- Also hide named elements if they exist
            if button.overlay then button.overlay:Hide() end
            if button.border then button.border:Hide() end
            if button.background then button.background:Hide() end

            -- Use backdrop for square look with border
            if button.SetBackdrop then
                button:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    tile = false,
                    edgeSize = 1,
                    insets = { left = 0, right = 0, top = 0, bottom = 0 }
                })
                button:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
                button:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            end

            -- Make the icon fill the square
            if iconTexture then
                iconTexture:Show()  -- Make sure icon is visible
                iconTexture:ClearAllPoints()
                iconTexture:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
                iconTexture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
                iconTexture:SetTexCoord(0, 1, 0, 1)  -- Full texture, no circular crop
            end

            -- ============================================================
            -- Hover effects only (menu requires click)
            -- ============================================================
            button:SetScript("OnEnter", function(self)
                -- Hover effect
                if iconTexture then
                    iconTexture:SetVertexColor(1.4, 1.2, 0.6, 1)
                end
                if button.SetBackdropBorderColor then
                    button:SetBackdropBorderColor(0.8, 0.7, 0.3, 1)
                end
            end)

            button:SetScript("OnLeave", function(self)
                -- Reset hover effect
                if iconTexture then
                    iconTexture:SetVertexColor(1, 1, 1, 1)
                end
                if button.SetBackdropBorderColor then
                    button:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                end
            end)

            -- Click toggles menu (left) or toggles config (right)
            button:SetScript("OnClick", function(self, btn)
                if btn == "LeftButton" then
                    LDBModule:ToggleMenu(self)
                elseif btn == "RightButton" then
                    -- Toggle config panel
                    local ACD = LibStub("AceConfigDialog-3.0")
                    if ACD.OpenFrames and ACD.OpenFrames["KoalityOfLife"] then
                        ACD:Close("KoalityOfLife")
                    else
                        KOL:OpenConfig()
                    end
                end
            end)

            -- Apply saved size
            local size = KOL.db.profile.minimapButtonSize or 32
            button:SetSize(size, size)

            KOL:DebugPrint("LDB: Minimap button hooked with square style and custom menu", 2)
        end
    end)
end

-- Update minimap button size from config
function LDBModule:UpdateMinimapButtonSize()
    local button = LDBIcon.objects and LDBIcon.objects["!Koality-of-Life"]
    if button then
        local size = KOL.db.profile.minimapButtonSize or 32
        button:SetSize(size, size)
    end
end

-- Check if LDB plugin was created (for click/menu handlers)
function LDBModule:IsLDBHidden()
    return dataObject == nil
end

-- Emergency force-close function (accessible via /kol closemenu)
function LDBModule:ForceCloseMenu()
    -- Force hide everything with maximum prejudice
    if mainTooltip then
        mainTooltip:Hide()
        mainTooltip = nil
    end

    -- Hide all active tooltips
    for i = #activeTooltips, 1, -1 do
        local t = activeTooltips[i]
        if t then
            t:Hide()
            t:SetParent(nil)
        end
    end
    wipe(activeTooltips)

    -- Hide click catcher
    if clickCatcher then
        clickCatcher:Hide()
    end

    -- Clear tooltip pool
    for _, t in ipairs(tooltipPool) do
        if t then
            t:Hide()
            t:SetParent(nil)
        end
    end
    wipe(tooltipPool)

    KOL:PrintTag("LDB menu force-closed")
end

-- ============================================================================
-- Register initialization with core addon load
-- ============================================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ZONE_CHANGED_INDOORS")
frame:SetScript("OnEvent", function(self, event)
    -- PLAYER_LOGIN fires on initial login only
    -- PLAYER_ENTERING_WORLD fires on login AND /reload
    -- We use both to ensure we initialize in all cases
    if event == "PLAYER_LOGIN" then
        C_Timer.After(0.5, function()
            if KOL and KOL.db then
                LDBModule:Initialize()
            end
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- On reload, PLAYER_LOGIN doesn't fire, so we need this
        -- Use a slightly longer delay to let ChocolateBar initialize first
        C_Timer.After(1.0, function()
            if KOL and KOL.db then
                -- Reset the font hook flag so it can re-apply after reload
                chocolateBarFontHooked = false
                chocolateBarHookAttempts = 0
                LDBModule:Initialize()
            end
        end)
        -- Start position verifier after entering world (self-cancels when stable)
        C_Timer.After(0.1, function()
            if LDBModule.StartPositionVerifier then
                LDBModule.StartPositionVerifier()
            end
        end)
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
        -- Start position verifier after zone changes (self-cancels when stable)
        if LDBModule.StartPositionVerifier then
            LDBModule.StartPositionVerifier()
        end
    end
end)
