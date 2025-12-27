-- ============================================================================
-- UI Factory
-- ============================================================================
-- Central system for creating styled UI elements with consistent theming
-- ============================================================================

local KOL = KoalityOfLife
local LSM = LibStub("LibSharedMedia-3.0")

-- Create namespace for UI factory
KOL.UIFactory = {}
local UIFactory = KOL.UIFactory
local Colors = KOL.Colors

-- ============================================================================
-- Helper Functions
-- ============================================================================

local function GetGeneralFont()
    if not KOL.db or not KOL.db.profile then
        return LSM:Fetch("font", "Friz Quadrata TT"), "THICKOUTLINE"
    end
    local fontName = KOL.db.profile.generalFont or "Friz Quadrata TT"
    local fontOutline = KOL.db.profile.generalFontOutline or "THICKOUTLINE"
    local fontPath = LSM:Fetch("font", fontName)
    return fontPath, fontOutline
end

-- Export for use by other modules
UIFactory.GetGeneralFont = GetGeneralFont

-- ============================================================================
-- Frame Creation
-- ============================================================================

--[[
    Creates a styled frame with dark theme and 1px border

    Parameters:
        parent - Parent frame (optional, defaults to UIParent)
        name - Frame name (optional)
        width - Frame width (optional, omit to use anchor-based sizing)
        height - Frame height (optional, omit to use anchor-based sizing)
        options - Table with optional settings:
            - bgColor: {r, g, b, a} - Background color (default: very dark)
            - borderColor: {r, g, b, a} - Border color (default: mid gray)
            - movable: boolean - Make frame movable (default: false)
            - closable: boolean - Add to UISpecialFrames for ESC (default: false)
            - strata: string - Frame strata (default: "FULLSCREEN_DIALOG" for always on top)
            - level: number - Frame level (default: 100)

    Returns: frame
]]
function UIFactory:CreateStyledFrame(parent, name, width, height, options)
    options = options or {}
    parent = parent or UIParent

    local frame = CreateFrame("Frame", name, parent)

    -- Only set width/height if provided (allows sizing via anchors)
    if width then frame:SetWidth(width) end
    if height then frame:SetHeight(height) end

    frame:SetFrameStrata(options.strata or "FULLSCREEN_DIALOG")  -- Default to always on top
    frame:SetFrameLevel(options.level or 100)

    -- Apply backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })

    -- Set colors with theme support
    local bgColor, borderColor
    
    -- Check for OverrideTheme option
    if not options.OverrideTheme then
        -- Use theme colors
        if KOL.Themes and KOL.Themes.GetUIThemeColor then
            bgColor = options.bgColor or KOL.Themes:GetUIThemeColor("GlobalBG", {r = 0.02, g = 0.02, b = 0.02, a = 0.98})
            borderColor = options.borderColor or KOL.Themes:GetUIThemeColor("GlobalBorder", {r = 0.4, g = 0.4, b = 0.4, a = 1})
        else
            -- Fallback to original colors
            bgColor = options.bgColor or {r = 0.02, g = 0.02, b = 0.02, a = 0.98}
            borderColor = options.borderColor or {r = 0.4, g = 0.4, b = 0.4, a = 1}
        end
    else
        -- Use provided colors only (OverrideTheme = true)
        bgColor = options.bgColor or {r = 0.02, g = 0.02, b = 0.02, a = 0.98}
        borderColor = options.borderColor or {r = 0.4, g = 0.4, b = 0.4, a = 1}
    end
    
    frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    frame:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

    -- Make movable if requested
    if options.movable then
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    end

    -- Make closable with ESC
    if options.closable and name then
        tinsert(UISpecialFrames, name)
    end

    frame:Hide()
    return frame
end

--[[
    Creates a title bar for a styled frame with optional close button

    Parameters:
        parent - Parent frame
        height - Title bar height (default: 24)
        text - Title text
        options - Table with optional settings:
            - bgColor: {r, g, b, a} - Background color (default: dark)
            - textColor: {r, g, b, a} - Text color (default: pastel yellow)
            - fontSize: number - Font size (default: 12)
            - showCloseButton: boolean - Add X button to close (default: true)

    Returns: titleBar frame, title fontString, closeButton (if created)
]]
function UIFactory:CreateTitleBar(parent, height, text, options)
    options = options or {}
    height = height or 24  -- Much shorter default

    local titleBar = CreateFrame("Frame", nil, parent)
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetHeight(height)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
    })

    local bgColor = options.bgColor or {r = 0.08, g = 0.08, b = 0.08, a = 1}
    titleBar:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)

    -- Title text
    local fontPath, fontOutline = GetGeneralFont()
    local fontSize = options.fontSize or 12  -- Smaller default font
    local title = parent:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontPath, fontSize, fontOutline)
    title:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
    title:SetText(text)
    
    -- Get theme colors with fallback
    local bgColor, borderColor
    
    if not options.OverrideTheme then
        -- Use theme colors
        if KOL.Themes and KOL.Themes.GetUIThemeColor then
            bgColor = options.bgColor or KOL.Themes:GetUIThemeColor("GlobalTitleBG", {r = 0.08, g = 0.08, b = 0.08, a = 1})
            borderColor = options.borderColor or KOL.Themes:GetUIThemeColor("GlobalBorder", {r = 0.4, g = 0.4, b = 0.4, a = 1})
        else
            -- Fallback to original colors
            bgColor = options.bgColor or {r = 0.08, g = 0.08, b = 0.08, a = 1}
            borderColor = options.borderColor or {r = 0.4, g = 0.4, b = 0.4, a = 1}
        end
    else
        -- Use provided colors only (OverrideTheme = true)
        bgColor = options.bgColor or {r = 0.08, g = 0.08, b = 0.08, a = 1}
        borderColor = options.borderColor or {r = 0.4, g = 0.4, b = 0.4, a = 1}
    end
    
    titleBar:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    titleBar:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    
    local textColor = options.textColor or {r = 1, g = 1, b = 0.6, a = 1}
    title:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)

    -- Close button (if requested, default true)
    local closeButton = nil
    if options.showCloseButton ~= false then
        local buttonSize = height - 4  -- Slightly smaller than bar height
        closeButton = CreateFrame("Button", nil, titleBar)
        closeButton:SetWidth(buttonSize)
        closeButton:SetHeight(buttonSize)
        closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -2, 0)

        -- Styled backdrop like D button
        closeButton:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            tileSize = 1,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        closeButton:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
        closeButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.9)

        -- X text
        local xText = closeButton:CreateFontString(nil, "OVERLAY")
        xText:SetFont(fontPath, fontSize, fontOutline)
        xText:SetPoint("CENTER", 0, 0)
        xText:SetText("X")
        xText:SetTextColor(1, 0.4, 0.4, 1)  -- Red-ish like D button
        closeButton.text = xText

        -- Hover effects
        closeButton:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.25, 0.25, 0.25, 0.95)
            self:SetBackdropBorderColor(1, 0.5, 0.5, 1)
            self.text:SetTextColor(1, 0.6, 0.6, 1)
        end)

        closeButton:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
            self:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.9)
            self.text:SetTextColor(1, 0.4, 0.4, 1)
        end)

        -- Click to close parent frame
        closeButton:SetScript("OnClick", function()
            parent:Hide()
        end)
    end

    return titleBar, title, closeButton
end

--[[
    Creates a content area background (darker inset area)

    Parameters:
        parent - Parent frame
        inset - Table with {top, bottom, left, right} insets from parent
        options - Table with optional settings:
            - bgColor: {r, g, b, a} - Background color (default: nearly black)
            - borderColor: {r, g, b, a} - Border color (default: dark gray)

    Returns: content frame
]]
function UIFactory:CreateContentArea(parent, inset, options)
    options = options or {}
    inset = inset or {top = 43, bottom = 40, left = 8, right = 8}

    local content = CreateFrame("Frame", nil, parent)
    content:SetPoint("TOPLEFT", inset.left, -inset.top)
    content:SetPoint("BOTTOMRIGHT", -inset.right, inset.bottom)
    content:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })

    -- Get theme colors with OverrideTheme support
    local bgColor, borderColor
    
    if not options.OverrideTheme then
        -- Use theme colors
        if KOL.Themes and KOL.Themes.GetUIThemeColor then
            bgColor = options.bgColor or KOL.Themes:GetUIThemeColor("ContentAreaBG", {r = 0.01, g = 0.01, b = 0.01, a = 1})
            borderColor = options.borderColor or KOL.Themes:GetUIThemeColor("ContentAreaBorder", {r = 0.25, g = 0.25, b = 0.25, a = 1})
        else
            -- Fallback to original colors
            bgColor = options.bgColor or {r = 0.01, g = 0.01, b = 0.01, a = 1}
            borderColor = options.borderColor or {r = 0.25, g = 0.25, b = 0.25, a = 1}
        end
    else
        -- Use provided colors only (OverrideTheme = true)
        bgColor = options.bgColor or {r = 0.01, g = 0.01, b = 0.01, a = 1}
        borderColor = options.borderColor or {r = 0.25, g = 0.25, b = 0.25, a = 1}
    end

    content:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    content:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

    return content
end

-- ============================================================================
-- Legacy Button Creation (for backward compatibility)
-- ============================================================================

--[[
    Creates a styled button (legacy version - use CreateStyledButtonEnhanced for theme support)

    Parameters:
        parent - Parent frame
        width - Button width
        height - Button height
        text - Button text
        options - Table with optional settings:
            - bgColor: {r, g, b, a} - Background color (default: pastel red)
            - hoverColor: {r, g, b, a} - Hover background color (default: lighter red)
            - borderColor: {r, g, b, a} - Border color (default: dark)
            - textColor: {r, g, b, a} - Text color (default: pastel yellow)
            - fontSize: number - Font size (default: 12)
            - onClick: function - Click handler

    Returns: button
]]
function UIFactory:CreateStyledButton(parent, width, height, text, options)
    options = options or {}

    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height)

    -- Background
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })

    local bgColor = options.bgColor or {r = 0.8, g = 0.4, b = 0.4, a = 1}
    local hoverColor = options.hoverColor or {r = 0.9, g = 0.5, b = 0.5, a = 1}
    local borderColor = options.borderColor or {r = 0.2, g = 0.2, b = 0.2, a = 1}

    button:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    button:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

    -- Text
    local fontPath, fontOutline = GetGeneralFont()
    local fontSize = options.fontSize or 12
    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont(fontPath, fontSize, fontOutline)
    buttonText:SetPoint("CENTER")
    buttonText:SetText(text)

    local textColor = options.textColor or {r = 1, g = 1, b = 0.6, a = 1}
    buttonText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)
    button.text = buttonText

    -- Store colors for hover
    button.normalColor = bgColor
    button.hoverColor = hoverColor

    -- Hover effect
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(self.hoverColor.r, self.hoverColor.g, self.hoverColor.b, self.hoverColor.a)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(self.normalColor.r, self.normalColor.g, self.normalColor.b, self.normalColor.a)
    end)

    -- Click handler
    if options.onClick then
        button:SetScript("OnClick", options.onClick)
    end

    return button
end

-- ============================================================================
-- Scroll Frame Creation
-- ============================================================================

--[[
    Creates a scroll frame for content

    Parameters:
        parent - Parent frame (usually a content area)
        inset - Table with {top, bottom, left, right} insets from parent

    Returns: scrollFrame, scrollChild
]]
function UIFactory:CreateScrollFrame(parent, inset)
    inset = inset or {top = 8, bottom = 8, left = 8, right = 28}

    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", inset.left, -inset.top)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset.right, inset.bottom)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 10)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    return scrollFrame, scrollChild
end

-- ============================================================================
-- ScrollBar Skinning
-- ============================================================================

--[[
    Skin a scrollbar to match KOL's dark theme

    Parameters:
        scrollFrame - The scroll frame containing the scrollbar
        scrollBarName - Name of the scrollbar (or the scrollbar itself)
        colors - Optional table: {track = {bg, border}, thumb = {bg, border}, button = {bg, border, arrow}}
                 Each color is {r, g, b, a}
]]
function KOL:SkinScrollBar(scrollFrame, scrollBarName, colors)
    local scrollBar = scrollFrame[scrollBarName] or _G[scrollBarName]
    if not scrollBar then
        self:DebugPrint("UI: ScrollBar not found: " .. tostring(scrollBarName), 1)
        return
    end

    -- Already skinned
    if scrollBar.kolSkinned then return end

    -- Default colors
    colors = colors or {}
    local trackBg = colors.track and colors.track.bg or {0.05, 0.05, 0.05, 0.9}
    local trackBorder = colors.track and colors.track.border or {0.2, 0.2, 0.2, 1}
    local thumbBg = colors.thumb and colors.thumb.bg or {0.3, 0.3, 0.3, 1}
    local thumbBorder = colors.thumb and colors.thumb.border or {0, 0.6, 0.6, 1}
    local buttonBg = colors.button and colors.button.bg or {0.15, 0.15, 0.15, 0.9}
    local buttonBorder = colors.button and colors.button.border or {0, 0.6, 0.6, 1}
    local buttonArrow = colors.button and colors.button.arrow or {0, 0.8, 0.8, 1}

    -- Set consistent width
    scrollBar:SetWidth(16)

    -- Find scroll buttons and thumb
    local upButton = scrollBar.ScrollUpButton or scrollBar.UpButton
    local downButton = scrollBar.ScrollDownButton or scrollBar.DownButton
    local thumb = scrollBar.ThumbTexture or scrollBar.thumbTexture

    -- Clear default textures
    if scrollBar.Background then scrollBar.Background:SetTexture(nil) end
    if scrollBar.Top then scrollBar.Top:SetTexture(nil) end
    if scrollBar.Middle then scrollBar.Middle:SetTexture(nil) end
    if scrollBar.Bottom then scrollBar.Bottom:SetTexture(nil) end

    -- Create backdrop for scrollbar track
    if not scrollBar.kolBackdrop then
        scrollBar.kolBackdrop = CreateFrame("Frame", nil, scrollBar)
        scrollBar.kolBackdrop:SetAllPoints(scrollBar)
        scrollBar.kolBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        scrollBar.kolBackdrop:SetBackdropColor(unpack(trackBg))
        scrollBar.kolBackdrop:SetBackdropBorderColor(unpack(trackBorder))
        scrollBar.kolBackdrop:SetFrameLevel(scrollBar:GetFrameLevel())
    end

    -- Skin the thumb (draggable part)
    if thumb then
        thumb:SetTexture(nil)
        thumb:SetWidth(16)
        thumb:SetHeight(24)

        if not thumb.kolBackdrop then
            thumb.kolBackdrop = CreateFrame("Frame", nil, scrollBar)
            thumb.kolBackdrop:SetPoint("TOPLEFT", thumb, "TOPLEFT", 0, 0)
            thumb.kolBackdrop:SetPoint("BOTTOMRIGHT", thumb, "BOTTOMRIGHT", 0, 0)
            thumb.kolBackdrop:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false,
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 }
            })
            thumb.kolBackdrop:SetBackdropColor(unpack(thumbBg))
            thumb.kolBackdrop:SetBackdropBorderColor(unpack(thumbBorder))
            thumb.kolBackdrop:SetFrameLevel(scrollBar:GetFrameLevel() + 2)
        end
    end

    -- Skin up button
    if upButton then
        local buttonColors = {bg = buttonBg, border = buttonBorder, arrow = buttonArrow}
        self:SkinScrollButton(upButton, "up", buttonColors)
        upButton:SetPoint("BOTTOM", scrollBar, "TOP", 0, 1)
    end

    -- Skin down button
    if downButton then
        local buttonColors = {bg = buttonBg, border = buttonBorder, arrow = buttonArrow}
        self:SkinScrollButton(downButton, "down", buttonColors)
        downButton:SetPoint("TOP", scrollBar, "BOTTOM", 0, -1)
    end

    scrollBar.kolSkinned = true
    self:DebugPrint("UI: ScrollBar skinned: " .. tostring(scrollBarName), 3)
end

--[[
    Skin scroll buttons (up/down arrows)

    Parameters:
        button - The button to skin
        direction - "up", "down", "left", or "right"
        colors - Optional table: {bg = {r,g,b,a}, border = {r,g,b,a}, arrow = {r,g,b,a}}
]]
function KOL:SkinScrollButton(button, direction, colors)
    if not button or button.kolSkinned then return end

    -- Default colors
    colors = colors or {}
    local bg = colors.bg or {0.15, 0.15, 0.15, 0.9}
    local border = colors.border or {0, 0.6, 0.6, 1}
    local arrow = colors.arrow or {0, 0.8, 0.8, 1}

    button:SetSize(16, 16)

    -- Clear default textures
    if button.GetNormalTexture then
        local normal = button:GetNormalTexture()
        if normal then normal:SetTexture(nil) end
    end
    if button.GetPushedTexture then
        local pushed = button:GetPushedTexture()
        if pushed then pushed:SetTexture(nil) end
    end
    if button.GetDisabledTexture then
        local disabled = button:GetDisabledTexture()
        if disabled then disabled:SetTexture(nil) end
    end
    if button.GetHighlightTexture then
        local highlight = button:GetHighlightTexture()
        if highlight then highlight:SetTexture(nil) end
    end

    -- Create backdrop
    if not button.kolBackdrop then
        button.kolBackdrop = CreateFrame("Frame", nil, button)
        button.kolBackdrop:SetAllPoints(button)
        button.kolBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        button.kolBackdrop:SetBackdropColor(unpack(bg))
        button.kolBackdrop:SetBackdropBorderColor(unpack(border))
    end

    -- Create arrow texture
    if not button.kolArrow then
        button.kolArrow = button:CreateTexture(nil, "OVERLAY")
        button.kolArrow:SetSize(8, 8)
        button.kolArrow:SetPoint("CENTER", 0, 0)
        button.kolArrow:SetTexture("Interface\\Buttons\\WHITE8X8")
        button.kolArrow:SetVertexColor(unpack(arrow))

        -- Create arrow shape using a simple triangle approach
        -- (In WoW 3.3.5a we can't use fancy textures, so we'll use text)
        button.kolArrowText = button:CreateFontString(nil, "OVERLAY")
        button.kolArrowText:SetFont(CHAR_LIGATURESFONT, 10, CHAR_LIGATURESOUTLINE)
        button.kolArrowText:SetPoint("CENTER", 0, 0)
        button.kolArrowText:SetTextColor(unpack(arrow))

        if direction == "up" then
            button.kolArrowText:SetText(CHAR_ARROW_UPFILLED)
        elseif direction == "down" then
            button.kolArrowText:SetText(CHAR_ARROW_DOWNFILLED)
        elseif direction == "left" then
            button.kolArrowText:SetText(CHAR_ARROW_LEFTFILLED)
        elseif direction == "right" then
            button.kolArrowText:SetText(CHAR_ARROW_RIGHTFILLED)
        end

        button.kolArrow:Hide()  -- Use text instead
    end

    -- Store colors for hover effects
    button.kolColors = {bg = bg, border = border, arrow = arrow}

    -- Hover effect
    button:SetScript("OnEnter", function(self)
        local hoverBg = {self.kolColors.bg[1] + 0.05, self.kolColors.bg[2] + 0.05, self.kolColors.bg[3] + 0.05, 1}
        local hoverBorder = {self.kolColors.border[1], self.kolColors.border[2] + 0.2, self.kolColors.border[3] + 0.2, 1}
        local hoverArrow = {self.kolColors.arrow[1], self.kolColors.arrow[2] + 0.2, self.kolColors.arrow[3] + 0.2, 1}

        self.kolBackdrop:SetBackdropColor(unpack(hoverBg))
        self.kolBackdrop:SetBackdropBorderColor(unpack(hoverBorder))
        if self.kolArrowText then
            self.kolArrowText:SetTextColor(unpack(hoverArrow))
        end
    end)

    button:SetScript("OnLeave", function(self)
        self.kolBackdrop:SetBackdropColor(unpack(self.kolColors.bg))
        self.kolBackdrop:SetBackdropBorderColor(unpack(self.kolColors.border))
        if self.kolArrowText then
            self.kolArrowText:SetTextColor(unpack(self.kolColors.arrow))
        end
    end)

    button.kolSkinned = true
end

--[[
    Convenience function to skin standard UIPanelScrollFrameTemplate scrollbars

    Parameters:
        scrollFrame - The UIPanelScrollFrameTemplate frame
        colors - Optional color table (same format as SkinScrollBar)
]]
function KOL:SkinUIPanelScrollFrame(scrollFrame, colors)
    if not scrollFrame then return end

    local scrollBar = scrollFrame.ScrollBar or scrollFrame.scrollBar
    if scrollBar then
        self:SkinScrollBar(scrollFrame, "ScrollBar", colors)
    end
end

-- ============================================================================
-- Button Creation
-- ============================================================================

-- ============================================================================
-- Enhanced Button Creation with Theme Support
-- ============================================================================

--[[
    Creates a styled button with theme support and hover effects

    Parameters:
        parent - Parent frame
        width - Button width
        height - Button height
        text - Button text
        options - Optional table:
            bgColor - Background color {r, g, b, a} (default: theme ButtonNormal)
            textColor - Text color {r, g, b, a} (default: theme TextPrimary)
            borderColor - Border color {r, g, b, a} (default: theme ButtonBorder)
            hoverBgColor - Hover background color (default: theme ButtonHover)
            fontSize - Font size (default: 12)
            onClick - Click handler function
            OverrideTheme - boolean to skip theme colors (default: false)
]]
function UIFactory:CreateStyledButtonEnhanced(parent, width, height, text, options)
    options = options or {}

    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height)

    -- Get theme colors with OverrideTheme support
    local bgColor, borderColor, textColor, hoverBgColor
    
    if not options.OverrideTheme then
        -- Use theme colors
        if KOL.Themes and KOL.Themes.GetUIThemeColor then
            bgColor = options.bgColor or KOL.Themes:GetUIThemeColor("ButtonNormal", {r = 0.8, g = 0.4, b = 0.4, a = 1})
            borderColor = options.borderColor or KOL.Themes:GetUIThemeColor("ButtonBorder", {r = 0.2, g = 0.2, b = 0.2, a = 1})
            textColor = options.textColor or KOL.Themes:GetUIThemeColor("TextPrimary", {r = 1, g = 1, b = 0.6, a = 1})
            hoverBgColor = options.hoverBgColor or KOL.Themes:GetUIThemeColor("ButtonHover", {r = bgColor.r + 0.1, g = bgColor.g + 0.1, b = bgColor.b + 0.1, a = 1})
        else
            -- Fallback to original colors
            bgColor = options.bgColor or {r = 0.8, g = 0.4, b = 0.4, a = 1}
            borderColor = options.borderColor or {r = 0.2, g = 0.2, b = 0.2, a = 1}
            textColor = options.textColor or {r = 1, g = 1, b = 0.6, a = 1}
            hoverBgColor = options.hoverBgColor or {r = bgColor.r + 0.1, g = bgColor.g + 0.1, b = bgColor.b + 0.1, a = 1}
        end
    else
        -- Use provided colors only (OverrideTheme = true)
        bgColor = options.bgColor or {r = 0.8, g = 0.4, b = 0.4, a = 1}
        borderColor = options.borderColor or {r = 0.2, g = 0.2, b = 0.2, a = 1}
        textColor = options.textColor or {r = 1, g = 1, b = 0.6, a = 1}
        hoverBgColor = options.hoverBgColor or {r = bgColor.r + 0.1, g = bgColor.g + 0.1, b = bgColor.b + 0.1, a = 1}
    end
    
    local fontSize = options.fontSize or 12

    -- Background
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    button:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    button:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

    -- Text
    local fontPath, fontOutline = GetGeneralFont()
    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont(fontPath, fontSize, fontOutline)
    buttonText:SetPoint("CENTER")
    buttonText:SetText(text)
    buttonText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)
    button.text = buttonText

    -- Store colors for hover effects
    button.bgColor = bgColor
    button.hoverBgColor = hoverBgColor

    -- Hover effect
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(self.hoverBgColor.r, self.hoverBgColor.g, self.hoverBgColor.b, self.hoverBgColor.a)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(self.bgColor.r, self.bgColor.g, self.bgColor.b, self.bgColor.a)
    end)

    -- Click handler
    if options.onClick then
        button:SetScript("OnClick", options.onClick)
    end

    return button
end

-- ============================================================================
-- Enhanced Color System
-- ============================================================================
-- Note: Color palettes (NUCLEAR, PASTEL, etc.) are now defined in colors.lua

-- ============================================================================
-- Enhanced UI Components for Mockup System
-- ============================================================================

--[[
    Creates a scrollable content area with invisible scrollbar
    
    Parameters:
        parent - Parent frame
        options - Table with optional settings:
            - inset: {top, bottom, left, right} insets from parent
            - showScrollbar: boolean (default: true)
            - scrollbarColor: {bg, border, thumb} colors
    
    Returns: contentFrame, scrollFrame
]]
function UIFactory:CreateScrollableContent(parent, options)
    options = options or {}
    local inset = options.inset or {top = 8, bottom = 8, left = 8, right = 8}
    
    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", inset.left, -inset.top)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset.right, inset.bottom)
    
    -- Create content child
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 10)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Skin scrollbar to be invisible
    if options.showScrollbar ~= false then
        local scrollbarColors = options.scrollbarColor or {
            track = {bg = {0.05, 0.05, 0.05, 0.9}, border = {0.2, 0.2, 0.2, 1}},
            thumb = {bg = {0.3, 0.3, 0.3, 1}, border = {0, 0.6, 0.6, 1}},
            button = {bg = {0.15, 0.15, 0.15, 0.9}, border = {0, 0.6, 0.6, 1}, arrow = {0, 0.8, 0.8, 1}}
        }
        
        KOL:SkinUIPanelScrollFrame(scrollFrame, scrollbarColors)
    end
    
    return scrollChild, scrollFrame
end

--[[
    Creates a breadcrumb navigation system
    
    Parameters:
        parent - Parent frame
        path - Table of breadcrumb items: {name, color, onClick}
        options - Table with optional settings:
            - fontSize: number (default: 10)
            - separator: string (default: " → ")
    
    Returns: breadcrumbFrame
]]
function UIFactory:CreateBreadcrumbs(parent, path, options)
    options = options or {}
    local fontSize = options.fontSize or 10
    local separator = options.separator or " → "
    
    -- Create breadcrumb frame
    local breadcrumbFrame = CreateFrame("Frame", nil, parent)
    breadcrumbFrame:SetHeight(20)
    breadcrumbFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, 5)
    breadcrumbFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, 5)
    
    local fontPath, fontOutline = GetGeneralFont()
    
    -- Build breadcrumb text
    local breadcrumbText = ""
    for i, item in ipairs(path) do
        if i > 1 then
            breadcrumbText = breadcrumbText .. separator
        end
        
        local color = item.color or {r = 0.8, g = 0.8, b = 0.8}
        local colorHex = string.format("%02x%02x%02x", 
            math.floor(color.r * 255), 
            math.floor(color.g * 255), 
            math.floor(color.b * 255))
        
        breadcrumbText = breadcrumbText .. "|cFF" .. colorHex .. item.name .. "|r"
    end
    
    -- Create text display
    local textDisplay = breadcrumbFrame:CreateFontString(nil, "OVERLAY")
    textDisplay:SetFont(fontPath, fontSize, fontOutline)
    textDisplay:SetPoint("LEFT", 5, 0)
    textDisplay:SetText(breadcrumbText)
    textDisplay:SetTextColor(1, 1, 1, 1)
    
    return breadcrumbFrame
end

--[[
    Creates a selectable list with highlighting
    
    Parameters:
        parent - Parent frame
        items - Table of list items: {name, color, selected, onClick}
        options - Table with optional settings:
            - itemHeight: number (default: 24)
            - selectedColor: {r, g, b} (default: PASTEL_SELECTED)
            - normalColor: {r, g, b} (default: based on item.color)
    
    Returns: listFrame
]]
function UIFactory:CreateSelectableList(parent, items, options)
    options = options or {}
    local itemHeight = options.itemHeight or 24
    local selectedColor = options.selectedColor or Colors.PASTEL_SELECTED
    local normalColorBase = options.normalColor
    
    -- Create list container
    local listFrame = CreateFrame("Frame", nil, parent)
    listFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -25)
    listFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 10)
    
    local fontPath, fontOutline = GetGeneralFont()
    local yOffset = 0
    
    -- Create list items
    for i, item in ipairs(items) do
        local listItem = CreateFrame("Button", nil, listFrame)
        listItem:SetSize(listFrame:GetWidth() - 20, itemHeight)
        listItem:SetPoint("TOPLEFT", 10, -yOffset)
        
        -- Set colors based on selection state
        if item.selected then
            listItem:SetBackdropColor(selectedColor.r, selectedColor.g, selectedColor.b, 0.8)
            listItem:SetBackdropBorderColor(selectedColor.r * 0.8, selectedColor.g * 0.8, selectedColor.b * 0.8, 1)
        else
            local baseColor = normalColorBase or item.color or {r = 0.05, g = 0.05, b = 0.05}
            listItem:SetBackdropColor(baseColor.r * 0.3, baseColor.g * 0.3, baseColor.b * 0.3, 0.8)
            listItem:SetBackdropBorderColor(baseColor.r * 0.6, baseColor.g * 0.6, baseColor.b * 0.6, 1)
        end
        
        listItem:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        
        -- Item text
        local itemText = listItem:CreateFontString(nil, "OVERLAY")
        itemText:SetFont(fontPath, 11, fontOutline)
        itemText:SetPoint("LEFT", 8, 0)
        
        local color = item.selected and selectedColor or (item.color or {r = 0.8, g = 0.8, b = 0.8})
        local colorHex = string.format("%02x%02x%02x", 
            math.floor(color.r * 255), 
            math.floor(color.g * 255), 
            math.floor(color.b * 255))
        
        itemText:SetText("|cFF" .. colorHex .. item.name .. "|r")
        
        -- Click handler
        if item.onClick then
            listItem:SetScript("OnClick", item.onClick)
        end
        
        yOffset = yOffset + itemHeight + 2
    end
    
    return listFrame
end

--[[
    Creates a statistics panel for displaying information
    
    Parameters:
        parent - Parent frame
        stats - Table of statistics: {label, value, color}
        options - Table with optional settings:
            - fontSize: number (default: 10)
            - labelColor: {r, g, b} (default: white)
            - valueColor: {r, g, b} (default: yellow)
    
    Returns: statsFrame
]]
function UIFactory:CreateStatsPanel(parent, stats, options)
    options = options or {}
    local fontSize = options.fontSize or 10
    local labelColor = options.labelColor or {r = 1, g = 1, b = 1}
    local valueColor = options.valueColor or {r = 1, g = 1, b = 0.6}
    
    -- Create stats frame
    local statsFrame = CreateFrame("Frame", nil, parent)
    statsFrame:SetHeight(60)
    statsFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -70)
    statsFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -70)
    
    local fontPath, fontOutline = GetGeneralFont()
    local xOffset = 20
    
    -- Create stat items
    for i, stat in ipairs(stats) do
        local label = statsFrame:CreateFontString(nil, "OVERLAY")
        label:SetFont(fontPath, fontSize, fontOutline)
        label:SetPoint("TOPLEFT", xOffset, -10)
        label:SetTextColor(labelColor.r, labelColor.g, labelColor.b, 1)
        label:SetText(stat.label .. ":")
        
        local value = statsFrame:CreateFontString(nil, "OVERLAY")
        value:SetFont(fontPath, fontSize, fontOutline)
        value:SetPoint("TOPLEFT", xOffset + 80, -10)
        value:SetTextColor(valueColor.r, valueColor.g, valueColor.b, 1)
        value:SetText(stat.value)
        
        xOffset = xOffset + 150
        if i % 2 == 0 then
            xOffset = 20
        end
    end
    
    return statsFrame
end

-- ============================================================================
-- Text-Only Button (No Background/Border)
-- ============================================================================

--[[
    Creates a text-only button with no background or border
    Text color changes on hover - used for minimal/clean button style

    Parameters:
        parent - Parent frame
        text - Button text
        options - Table with optional settings:
            - textColor: {r, g, b, a} - Normal text color (default: muted gray)
            - hoverColor: {r, g, b, a} - Hover text color (default: bright cyan)
            - fontSize: number - Font size (default: 12)
            - onClick: function - Click handler
            - fontObject: string - Font object name (optional, uses GetGeneralFont if not set)

    Returns: button
]]
function UIFactory:CreateTextButton(parent, text, options)
    options = options or {}

    local textColor = options.textColor or {r = 0.7, g = 0.7, b = 0.7, a = 1}
    local hoverColor = options.hoverColor or {r = 0, g = 0.9, b = 0.9, a = 1}
    local fontSize = options.fontSize or 12

    local button = CreateFrame("Button", nil, parent)
    button:EnableMouse(true)

    -- Text
    local fontPath, fontOutline = GetGeneralFont()
    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont(fontPath, fontSize, fontOutline)
    buttonText:SetPoint("CENTER")
    buttonText:SetText(text)
    buttonText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a or 1)
    button.text = buttonText

    -- Size button to fit text
    buttonText:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    buttonText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)

    -- Store colors for hover
    button.textColor = textColor
    button.hoverColor = hoverColor

    -- Hover effects
    button:SetScript("OnEnter", function(self)
        self.text:SetTextColor(self.hoverColor.r, self.hoverColor.g, self.hoverColor.b, self.hoverColor.a or 1)
    end)

    button:SetScript("OnLeave", function(self)
        self.text:SetTextColor(self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a or 1)
    end)

    -- Click handler
    if options.onClick then
        button:SetScript("OnClick", options.onClick)
    end

    -- Helper to update size based on text
    function button:UpdateSize()
        local textWidth = self.text:GetStringWidth()
        local textHeight = self.text:GetStringHeight()
        self:SetSize(textWidth + 4, textHeight + 2)
    end

    -- Initial size
    button:UpdateSize()

    return button
end

-- ============================================================================
-- Image Button (Texture-based with states)
-- ============================================================================

--[[
    Creates a button using texture images for different states

    Parameters:
        parent - Parent frame
        width - Button width
        height - Button height
        options - Table with optional settings:
            - normalTexture: string - Path to normal state texture
            - hoverTexture: string - Path to hover state texture
            - pressedTexture: string - Path to pressed state texture
            - onClick: function - Click handler

    Returns: button
]]
function UIFactory:CreateImageButton(parent, width, height, options)
    options = options or {}

    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    button:EnableMouse(true)

    -- Create texture for the button
    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(button)
    button.texture = texture

    -- Store texture paths
    button.normalTexture = options.normalTexture
    button.hoverTexture = options.hoverTexture
    button.pressedTexture = options.pressedTexture

    -- Set initial texture
    if options.normalTexture then
        texture:SetTexture(options.normalTexture)
    end

    -- Hover effect
    button:SetScript("OnEnter", function(self)
        if self.hoverTexture then
            self.texture:SetTexture(self.hoverTexture)
        end
    end)

    button:SetScript("OnLeave", function(self)
        if self.normalTexture then
            self.texture:SetTexture(self.normalTexture)
        end
    end)

    -- Pressed effect
    button:SetScript("OnMouseDown", function(self)
        if self.pressedTexture then
            self.texture:SetTexture(self.pressedTexture)
        end
    end)

    button:SetScript("OnMouseUp", function(self)
        -- Check if mouse is still over button
        if self:IsMouseOver() then
            if self.hoverTexture then
                self.texture:SetTexture(self.hoverTexture)
            end
        else
            if self.normalTexture then
                self.texture:SetTexture(self.normalTexture)
            end
        end
    end)

    -- Click handler
    if options.onClick then
        button:SetScript("OnClick", options.onClick)
    end

    return button
end

-- ============================================================================
-- Styled Edit Box (Single-line input)
-- ============================================================================

--[[
    Creates a styled single-line edit box

    Parameters:
        parent - Parent frame
        width - Edit box width
        height - Edit box height (default: 24)
        options - Table with optional settings:
            - placeholder: string - Placeholder text when empty
            - maxLetters: number - Maximum characters allowed
            - onTextChanged: function(text) - Called when text changes
            - onEnterPressed: function(text) - Called when Enter is pressed
            - bgColor: {r, g, b, a} - Background color
            - borderColor: {r, g, b, a} - Border color
            - textColor: {r, g, b, a} - Text color
            - fontSize: number - Font size (default: 12)

    Returns: editBox
]]
function UIFactory:CreateEditBox(parent, width, height, options)
    options = options or {}
    height = height or 24

    -- Get theme colors
    local bgColor, borderColor
    if not options.OverrideTheme and KOL.Themes and KOL.Themes.GetUIThemeColor then
        bgColor = options.bgColor or KOL.Themes:GetUIThemeColor("ContentAreaBG", {r = 0.05, g = 0.05, b = 0.05, a = 1})
        borderColor = options.borderColor or KOL.Themes:GetUIThemeColor("ContentAreaBorder", {r = 0.3, g = 0.3, b = 0.3, a = 1})
    else
        bgColor = options.bgColor or {r = 0.05, g = 0.05, b = 0.05, a = 1}
        borderColor = options.borderColor or {r = 0.3, g = 0.3, b = 0.3, a = 1}
    end

    local textColor = options.textColor or {r = 1, g = 1, b = 1, a = 1}
    local fontSize = options.fontSize or 12

    -- Create container frame for backdrop
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, height)
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    container:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
    container:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)

    -- Create edit box
    local editBox = CreateFrame("EditBox", nil, container)
    editBox:SetPoint("TOPLEFT", 6, -4)
    editBox:SetPoint("BOTTOMRIGHT", -6, 4)
    editBox:SetAutoFocus(false)

    local fontPath, fontOutline = GetGeneralFont()
    editBox:SetFont(fontPath, fontSize, fontOutline)
    editBox:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a or 1)

    if options.maxLetters then
        editBox:SetMaxLetters(options.maxLetters)
    end

    -- Placeholder text
    if options.placeholder then
        local placeholder = editBox:CreateFontString(nil, "OVERLAY")
        placeholder:SetFont(fontPath, fontSize, fontOutline)
        placeholder:SetPoint("LEFT", 0, 0)
        placeholder:SetText(options.placeholder)
        placeholder:SetTextColor(0.5, 0.5, 0.5, 0.8)
        editBox.placeholder = placeholder

        editBox:SetScript("OnTextChanged", function(self)
            if self:GetText() == "" then
                self.placeholder:Show()
            else
                self.placeholder:Hide()
            end
            if options.onTextChanged then
                options.onTextChanged(self:GetText())
            end
        end)
    elseif options.onTextChanged then
        editBox:SetScript("OnTextChanged", function(self)
            options.onTextChanged(self:GetText())
        end)
    end

    -- Enter pressed handler
    if options.onEnterPressed then
        editBox:SetScript("OnEnterPressed", function(self)
            options.onEnterPressed(self:GetText())
        end)
    end

    -- ESC clears focus
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    -- Store reference to container
    editBox.container = container
    container.editBox = editBox

    -- Helper methods
    function container:GetText()
        return self.editBox:GetText()
    end

    function container:SetText(text)
        self.editBox:SetText(text)
    end

    function container:SetFocus()
        self.editBox:SetFocus()
    end

    function container:ClearFocus()
        self.editBox:ClearFocus()
    end

    return container
end

-- ============================================================================
-- Multi-Line Edit Box (Scrollable text area)
-- ============================================================================

--[[
    Creates a styled multi-line text area with scrolling

    Parameters:
        parent - Parent frame
        width - Text area width
        height - Text area height
        options - Table with optional settings:
            - placeholder: string - Placeholder text when empty
            - onTextChanged: function(text) - Called when text changes
            - bgColor: {r, g, b, a} - Background color
            - borderColor: {r, g, b, a} - Border color
            - textColor: {r, g, b, a} - Text color
            - fontSize: number - Font size (default: 11)

    Returns: container (with :GetText(), :SetText(), :SetFocus(), :HighlightText() methods)
]]
function UIFactory:CreateMultiLineEditBox(parent, width, height, options)
    options = options or {}

    -- Get theme colors
    local bgColor, borderColor
    if not options.OverrideTheme and KOL.Themes and KOL.Themes.GetUIThemeColor then
        bgColor = options.bgColor or KOL.Themes:GetUIThemeColor("ContentAreaBG", {r = 0.03, g = 0.03, b = 0.03, a = 1})
        borderColor = options.borderColor or KOL.Themes:GetUIThemeColor("ContentAreaBorder", {r = 0.3, g = 0.3, b = 0.3, a = 1})
    else
        bgColor = options.bgColor or {r = 0.03, g = 0.03, b = 0.03, a = 1}
        borderColor = options.borderColor or {r = 0.3, g = 0.3, b = 0.3, a = 1}
    end

    local textColor = options.textColor or {r = 1, g = 1, b = 1, a = 1}
    local fontSize = options.fontSize or 11

    -- Create container frame
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, height)
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    container:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
    container:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)

    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, container)
    scrollFrame:SetPoint("TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -4, 4)

    -- Create edit box
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetSize(width - 12, height - 8)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)

    local fontPath, fontOutline = GetGeneralFont()
    editBox:SetFont(fontPath, fontSize, fontOutline)
    editBox:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a or 1)

    scrollFrame:SetScrollChild(editBox)

    -- Handle mouse wheel scrolling
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = current - (delta * 20)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)

    -- Click on container focuses edit box
    container:EnableMouse(true)
    container:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)

    -- Placeholder text
    if options.placeholder then
        local placeholder = container:CreateFontString(nil, "OVERLAY")
        placeholder:SetFont(fontPath, fontSize, fontOutline)
        placeholder:SetPoint("TOPLEFT", 6, -6)
        placeholder:SetText(options.placeholder)
        placeholder:SetTextColor(0.5, 0.5, 0.5, 0.8)
        editBox.placeholder = placeholder

        editBox:SetScript("OnTextChanged", function(self)
            if self:GetText() == "" then
                self.placeholder:Show()
            else
                self.placeholder:Hide()
            end
            -- Update scroll child size
            self:SetWidth(scrollFrame:GetWidth())
            if options.onTextChanged then
                options.onTextChanged(self:GetText())
            end
        end)
    elseif options.onTextChanged then
        editBox:SetScript("OnTextChanged", function(self)
            self:SetWidth(scrollFrame:GetWidth())
            options.onTextChanged(self:GetText())
        end)
    else
        editBox:SetScript("OnTextChanged", function(self)
            self:SetWidth(scrollFrame:GetWidth())
        end)
    end

    -- ESC clears focus
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    -- Store references
    container.scrollFrame = scrollFrame
    container.editBox = editBox

    -- Helper methods
    function container:GetText()
        return self.editBox:GetText()
    end

    function container:SetText(text)
        self.editBox:SetText(text or "")
    end

    function container:SetFocus()
        self.editBox:SetFocus()
    end

    function container:ClearFocus()
        self.editBox:ClearFocus()
    end

    function container:HighlightText()
        self.editBox:HighlightText()
    end

    function container:SetCursorPosition(pos)
        self.editBox:SetCursorPosition(pos)
    end

    return container
end

-- ============================================================================
-- Styled Dropdown Menu
-- ============================================================================

--[[
    Creates a styled dropdown menu

    Parameters:
        parent - Parent frame
        width - Dropdown width
        options - Table with optional settings:
            - items: table - Array of {value, label, color} or just strings
            - selectedValue: any - Initially selected value
            - onSelect: function(value, label) - Called when selection changes
            - placeholder: string - Text shown when nothing selected
            - bgColor: {r, g, b, a} - Background color
            - borderColor: {r, g, b, a} - Border color
            - fontSize: number - Font size (default: 12)

    Returns: dropdown container
]]
function UIFactory:CreateDropdown(parent, width, options)
    options = options or {}
    local height = 24

    -- Get theme colors
    local bgColor, borderColor
    if not options.OverrideTheme and KOL.Themes and KOL.Themes.GetUIThemeColor then
        bgColor = options.bgColor or KOL.Themes:GetUIThemeColor("ContentAreaBG", {r = 0.08, g = 0.08, b = 0.08, a = 1})
        borderColor = options.borderColor or KOL.Themes:GetUIThemeColor("ContentAreaBorder", {r = 0.3, g = 0.3, b = 0.3, a = 1})
    else
        bgColor = options.bgColor or {r = 0.08, g = 0.08, b = 0.08, a = 1}
        borderColor = options.borderColor or {r = 0.3, g = 0.3, b = 0.3, a = 1}
    end

    local fontSize = options.fontSize or 12
    local fontPath, fontOutline = GetGeneralFont()

    -- Create main button
    local dropdown = CreateFrame("Button", nil, parent)
    dropdown:SetSize(width, height)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    dropdown:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
    dropdown:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)

    -- Selected text
    local selectedText = dropdown:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont(fontPath, fontSize, fontOutline)
    selectedText:SetPoint("LEFT", 8, 0)
    selectedText:SetPoint("RIGHT", -20, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetText(options.placeholder or "Select...")
    selectedText:SetTextColor(0.7, 0.7, 0.7, 1)
    dropdown.selectedText = selectedText

    -- Arrow indicator
    local arrow = dropdown:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(CHAR_LIGATURESFONT, fontSize, CHAR_LIGATURESOUTLINE)
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetText(CHAR_ARROW_DOWNFILLED)
    arrow:SetTextColor(0.6, 0.6, 0.6, 1)
    dropdown.arrow = arrow

    -- Store state
    dropdown.items = options.items or {}
    dropdown.selectedValue = options.selectedValue
    dropdown.onSelect = options.onSelect
    dropdown.isOpen = false

    -- Create dropdown list (hidden by default)
    local list = CreateFrame("Frame", nil, dropdown)
    list:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    list:SetWidth(width)
    list:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    list:SetBackdropColor(0.1, 0.1, 0.1, 0.98)
    list:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    -- Always use TOOLTIP strata so dropdown list appears above everything
    list:SetFrameStrata("TOOLTIP")
    list:SetFrameLevel(200)
    list:Hide()
    dropdown.list = list

    -- Function to populate list items
    local function PopulateList()
        -- Clear existing items
        for _, child in ipairs({list:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end

        local itemHeight = 22
        local yOffset = -2

        for i, item in ipairs(dropdown.items) do
            local value, label, color
            if type(item) == "table" then
                value = item.value or item[1]
                label = item.label or item[2] or tostring(value)
                color = item.color
            else
                value = item
                label = tostring(item)
            end

            local itemBtn = CreateFrame("Button", nil, list)
            itemBtn:SetSize(width - 4, itemHeight)
            itemBtn:SetPoint("TOPLEFT", 2, yOffset)

            local itemText = itemBtn:CreateFontString(nil, "OVERLAY")
            itemText:SetFont(fontPath, fontSize - 1, fontOutline)
            itemText:SetPoint("LEFT", 6, 0)
            itemText:SetText(label)

            if color then
                itemText:SetTextColor(color.r, color.g, color.b, 1)
            else
                itemText:SetTextColor(0.9, 0.9, 0.9, 1)
            end

            itemBtn.value = value
            itemBtn.label = label
            itemBtn.color = color
            itemBtn.itemText = itemText

            -- Hover effect
            itemBtn:SetScript("OnEnter", function(self)
                self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
                self:SetBackdropColor(0.2, 0.2, 0.2, 1)
            end)

            itemBtn:SetScript("OnLeave", function(self)
                self:SetBackdrop(nil)
            end)

            -- Click to select
            itemBtn:SetScript("OnClick", function(self)
                dropdown.selectedValue = self.value
                dropdown.selectedText:SetText(self.label)
                if self.color then
                    dropdown.selectedText:SetTextColor(self.color.r, self.color.g, self.color.b, 1)
                else
                    dropdown.selectedText:SetTextColor(1, 1, 1, 1)
                end
                list:Hide()
                dropdown.isOpen = false
                dropdown.arrow:SetText(CHAR_ARROW_DOWNFILLED)

                if dropdown.onSelect then
                    dropdown.onSelect(self.value, self.label)
                end
            end)

            yOffset = yOffset - itemHeight
        end

        list:SetHeight(math.abs(yOffset) + 4)
    end

    -- Toggle dropdown
    dropdown:SetScript("OnClick", function(self)
        if self.isOpen then
            self.list:Hide()
            self.isOpen = false
            self.arrow:SetText(CHAR_ARROW_DOWNFILLED)
        else
            PopulateList()
            self.list:Show()
            self.isOpen = true
            self.arrow:SetText(CHAR_ARROW_UPFILLED)
        end
    end)

    -- Close when clicking elsewhere
    list:SetScript("OnShow", function()
        -- We'll handle this with a global mouse handler if needed
    end)

    -- Hover effect on main button
    dropdown:SetScript("OnEnter", function(self)
        self:SetBackdropColor(bgColor.r + 0.05, bgColor.g + 0.05, bgColor.b + 0.05, bgColor.a or 1)
    end)

    dropdown:SetScript("OnLeave", function(self)
        self:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
    end)

    -- Helper methods
    function dropdown:SetSelectedValue(value)
        self.selectedValue = value
        for _, item in ipairs(self.items) do
            local itemValue, itemLabel, itemColor
            if type(item) == "table" then
                itemValue = item.value or item[1]
                itemLabel = item.label or item[2] or tostring(itemValue)
                itemColor = item.color
            else
                itemValue = item
                itemLabel = tostring(item)
            end

            if itemValue == value then
                self.selectedText:SetText(itemLabel)
                if itemColor then
                    self.selectedText:SetTextColor(itemColor.r, itemColor.g, itemColor.b, 1)
                else
                    self.selectedText:SetTextColor(1, 1, 1, 1)
                end
                return
            end
        end
    end

    function dropdown:GetSelectedValue()
        return self.selectedValue
    end

    function dropdown:SetItems(items)
        self.items = items
    end

    -- Set initial selection if provided
    if options.selectedValue then
        dropdown:SetSelectedValue(options.selectedValue)
    end

    return dropdown
end

-- ============================================================================
-- Styled Checkbox
-- ============================================================================

--[[
    Creates a styled checkbox

    Parameters:
        parent - Parent frame
        label - Checkbox label text
        options - Table with optional settings:
            - checked: boolean - Initial checked state
            - onChange: function(checked) - Called when state changes
            - labelColor: {r, g, b, a} - Label text color
            - checkColor: {r, g, b, a} - Checkmark color
            - fontSize: number - Font size (default: 12)

    Returns: checkbox container
]]
function UIFactory:CreateCheckbox(parent, label, options)
    options = options or {}

    local fontSize = options.fontSize or 12
    local labelColor = options.labelColor or {r = 0.9, g = 0.9, b = 0.9, a = 1}
    local checkColor = options.checkColor or {r = 0, g = 0.8, b = 0.8, a = 1}

    local fontPath, fontOutline = GetGeneralFont()

    -- Create container
    local container = CreateFrame("Button", nil, parent)
    container:EnableMouse(true)

    -- Checkbox box
    local box = CreateFrame("Frame", nil, container)
    box:SetSize(16, 16)
    box:SetPoint("LEFT", 0, 0)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    box:SetBackdropColor(0.05, 0.05, 0.05, 1)
    box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    container.box = box

    -- Checkmark (using ligatures font)
    local checkmark = box:CreateFontString(nil, "OVERLAY")
    checkmark:SetFont(CHAR_LIGATURESFONT, fontSize, CHAR_LIGATURESOUTLINE)
    checkmark:SetPoint("CENTER", 0, 0)
    checkmark:SetText(CHAR_OBJECTIVE_COMPLETE)
    checkmark:SetTextColor(checkColor.r, checkColor.g, checkColor.b, checkColor.a or 1)
    checkmark:Hide()
    container.checkmark = checkmark

    -- Label text
    local labelText = container:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(fontPath, fontSize, fontOutline)
    labelText:SetPoint("LEFT", box, "RIGHT", 6, 0)
    labelText:SetText(label)
    labelText:SetTextColor(labelColor.r, labelColor.g, labelColor.b, labelColor.a or 1)
    container.label = labelText

    -- Size container to fit
    local textWidth = labelText:GetStringWidth()
    container:SetSize(16 + 6 + textWidth + 4, 18)

    -- State
    container.checked = options.checked or false
    container.onChange = options.onChange

    -- Update visual state
    local function UpdateState()
        if container.checked then
            container.checkmark:Show()
            container.box:SetBackdropBorderColor(checkColor.r, checkColor.g, checkColor.b, 1)
        else
            container.checkmark:Hide()
            container.box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end
    end

    -- Initial state
    UpdateState()

    -- Click to toggle
    container:SetScript("OnClick", function(self)
        self.checked = not self.checked
        UpdateState()
        if self.onChange then
            self.onChange(self.checked)
        end
    end)

    -- Hover effect
    container:SetScript("OnEnter", function(self)
        self.box:SetBackdropColor(0.1, 0.1, 0.1, 1)
    end)

    container:SetScript("OnLeave", function(self)
        self.box:SetBackdropColor(0.05, 0.05, 0.05, 1)
    end)

    -- Helper methods
    function container:SetChecked(checked)
        self.checked = checked
        UpdateState()
    end

    function container:IsChecked()
        return self.checked
    end

    return container
end

-- ============================================================================
-- Scrollable Dropdown (for long lists)
-- ============================================================================

--[[
    Creates a scrollable dropdown for long item lists

    Features:
        - Scrollable list (40% screen height max)
        - Mouse wheel support
        - Color support for items
        - Checkmark on selected item

    Parameters:
        parent - Parent frame
        width - Dropdown width (default: 200)
        options - Table with:
            - items: array of {value, label, color} or simple strings
            - selectedValue: initial selected value
            - onSelect: function(value, label) callback
            - placeholder: text when nothing selected
            - fontSize: number - Font size (default: 12)

    Returns: dropdown frame with selectedValue, selectedText, SetValue(value) methods
]]
function UIFactory:CreateScrollableDropdown(parent, width, options)
    options = options or {}
    width = width or 200
    local height = 24
    local itemHeight = 22
    local maxVisibleItems = 12

    local fontPath, fontOutline = GetGeneralFont()
    local fontSize = options.fontSize or 12

    -- Get theme colors
    local bgColor, borderColor
    if KOL.Themes and KOL.Themes.GetUIThemeColor then
        bgColor = KOL.Themes:GetUIThemeColor("ContentAreaBG", {r = 0.08, g = 0.08, b = 0.08, a = 1})
        borderColor = KOL.Themes:GetUIThemeColor("ContentAreaBorder", {r = 0.3, g = 0.3, b = 0.3, a = 1})
    else
        bgColor = {r = 0.08, g = 0.08, b = 0.08, a = 1}
        borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1}
    end

    -- Create main dropdown button
    local dropdown = CreateFrame("Button", nil, parent)
    dropdown:SetSize(width, height)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    dropdown:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
    dropdown:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)

    -- Selected text
    local selectedText = dropdown:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont(fontPath, fontSize, fontOutline)
    selectedText:SetPoint("LEFT", 8, 0)
    selectedText:SetPoint("RIGHT", -20, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetText(options.placeholder or "Select...")
    selectedText:SetTextColor(0.7, 0.7, 0.7, 1)
    dropdown.selectedText = selectedText

    -- Arrow indicator
    local arrow = dropdown:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(CHAR_LIGATURESFONT, fontSize, CHAR_LIGATURESOUTLINE)
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetText(CHAR_ARROW_DOWNFILLED)
    arrow:SetTextColor(0.6, 0.6, 0.6, 1)
    dropdown.arrow = arrow

    -- State
    dropdown.selectedValue = options.selectedValue
    dropdown.isOpen = false
    dropdown.onSelect = options.onSelect
    dropdown.items = options.items or {}
    dropdown.itemButtons = {}

    -- Create dropdown list frame
    local list = CreateFrame("Frame", nil, dropdown)
    list:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    list:SetWidth(width)
    list:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    list:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
    list:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    list:SetFrameStrata("TOOLTIP")
    list:SetFrameLevel(200)
    list:Hide()
    dropdown.list = list

    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, list)
    scrollFrame:SetPoint("TOPLEFT", 2, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
    dropdown.scrollFrame = scrollFrame

    -- Create scroll child
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(width - 4)
    scrollFrame:SetScrollChild(scrollChild)
    dropdown.scrollChild = scrollChild

    -- Scrollbar
    local scrollBar = CreateFrame("Frame", nil, list)
    scrollBar:SetWidth(8)
    scrollBar:SetPoint("TOPRIGHT", -2, -2)
    scrollBar:SetPoint("BOTTOMRIGHT", -2, 2)
    scrollBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    scrollBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    scrollBar:Hide()
    dropdown.scrollBar = scrollBar

    -- Scrollbar thumb
    local scrollThumb = CreateFrame("Frame", nil, scrollBar)
    scrollThumb:SetWidth(6)
    scrollThumb:SetPoint("TOP", 0, 0)
    scrollThumb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    scrollThumb:SetBackdropColor(0.4, 0.4, 0.4, 1)
    scrollThumb:EnableMouse(true)
    dropdown.scrollThumb = scrollThumb
    dropdown.isDragging = false

    -- Scrollbar thumb drag handling
    scrollThumb:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            dropdown.isDragging = true
            dropdown.dragStartY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            dropdown.dragStartScroll = scrollFrame:GetVerticalScroll()
        end
    end)

    scrollThumb:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            dropdown.isDragging = false
        end
    end)

    scrollThumb:SetScript("OnUpdate", function(self)
        if not dropdown.isDragging then return end

        -- Clear drag state if mouse button is no longer down
        if not IsMouseButtonDown("LeftButton") then
            dropdown.isDragging = false
            return
        end

        local currentY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local deltaY = dropdown.dragStartY - currentY

        local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
        if maxScroll <= 0 then return end

        local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
        if thumbRange <= 0 then return end

        local scrollPerPixel = maxScroll / thumbRange
        local newScroll = dropdown.dragStartScroll + (deltaY * scrollPerPixel)
        newScroll = math.max(0, math.min(newScroll, maxScroll))

        scrollFrame:SetVerticalScroll(newScroll)

        local thumbPos = (newScroll / maxScroll) * thumbRange
        scrollThumb:ClearAllPoints()
        scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, -thumbPos)
    end)

    -- Populate list function
    local function PopulateList()
        local items = dropdown.items

        -- Calculate max visible items
        local screenHeight = UIParent:GetHeight()
        local maxListHeight = screenHeight * 0.4
        maxVisibleItems = math.floor(maxListHeight / itemHeight)

        local needsScroll = #items > maxVisibleItems
        local visibleCount = needsScroll and maxVisibleItems or #items
        local listHeight = (visibleCount * itemHeight) + 4

        list:SetHeight(listHeight)
        scrollChild:SetHeight(#items * itemHeight)

        -- Show/hide scrollbar
        if needsScroll then
            scrollBar:Show()
            scrollFrame:SetPoint("BOTTOMRIGHT", -12, 2)
            local thumbHeight = math.max(20, (visibleCount / #items) * (listHeight - 4))
            scrollThumb:SetHeight(thumbHeight)
        else
            scrollBar:Hide()
            scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
        end

        -- Clear existing buttons
        for _, btn in ipairs(dropdown.itemButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
        dropdown.itemButtons = {}

        -- Create item buttons
        for i, item in ipairs(items) do
            local value, label, color
            if type(item) == "table" then
                value = item.value or item[1]
                label = item.label or item[2] or value
                color = item.color
            else
                value = item
                label = item
            end

            local itemBtn = CreateFrame("Button", nil, scrollChild)
            itemBtn:SetSize(width - (needsScroll and 16 or 8), itemHeight)
            itemBtn:SetPoint("TOPLEFT", 2, -((i - 1) * itemHeight))

            -- Checkmark
            local checkmark = itemBtn:CreateFontString(nil, "OVERLAY")
            checkmark:SetFont(CHAR_LIGATURESFONT, fontSize - 2, CHAR_LIGATURESOUTLINE)
            checkmark:SetPoint("LEFT", 4, 0)
            checkmark:SetText(CHAR_OBJECTIVE_COMPLETE)
            checkmark:SetTextColor(0.3, 0.9, 0.3, 1)
            checkmark:Hide()
            itemBtn.checkmark = checkmark

            -- Label text
            local labelText = itemBtn:CreateFontString(nil, "OVERLAY")
            labelText:SetFont(fontPath, fontSize, fontOutline)
            labelText:SetPoint("LEFT", 20, 0)
            labelText:SetPoint("RIGHT", -4, 0)
            labelText:SetJustifyH("LEFT")
            labelText:SetText(label)
            if color then
                labelText:SetTextColor(color.r, color.g, color.b, 1)
            else
                labelText:SetTextColor(0.9, 0.9, 0.9, 1)
            end
            itemBtn.labelText = labelText

            -- Show checkmark if selected
            if value == dropdown.selectedValue then
                checkmark:Show()
            end

            -- Highlight on hover
            itemBtn:SetScript("OnEnter", function(self)
                self.labelText:SetTextColor(1, 1, 1, 1)
            end)
            itemBtn:SetScript("OnLeave", function(self)
                if color then
                    self.labelText:SetTextColor(color.r, color.g, color.b, 1)
                else
                    self.labelText:SetTextColor(0.9, 0.9, 0.9, 1)
                end
            end)

            -- Click to select
            itemBtn:SetScript("OnClick", function(self)
                dropdown.selectedValue = value
                dropdown.selectedText:SetText(label)
                if color then
                    dropdown.selectedText:SetTextColor(color.r, color.g, color.b, 1)
                else
                    dropdown.selectedText:SetTextColor(0.9, 0.9, 0.9, 1)
                end

                -- Update checkmarks
                for _, btn in ipairs(dropdown.itemButtons) do
                    btn.checkmark:Hide()
                end
                self.checkmark:Show()

                -- Close and callback
                list:Hide()
                dropdown.isOpen = false
                if dropdown.onSelect then
                    dropdown.onSelect(value, label)
                end
            end)

            table.insert(dropdown.itemButtons, itemBtn)
        end

        -- Update scroll position
        scrollFrame:SetVerticalScroll(0)
        scrollThumb:SetPoint("TOP", 0, 0)
    end

    -- Mouse wheel scrolling
    local function OnMouseWheel(self, delta)
        local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
        if maxScroll <= 0 then return end

        local current = scrollFrame:GetVerticalScroll()
        local new = current - (delta * itemHeight * 2)
        new = math.max(0, math.min(new, maxScroll))
        scrollFrame:SetVerticalScroll(new)

        -- Update thumb position
        local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
        local thumbPos = (new / maxScroll) * thumbRange
        scrollThumb:SetPoint("TOP", 0, -thumbPos)
    end

    -- Enable mouse wheel (required for 3.3.5)
    list:EnableMouseWheel(true)
    scrollFrame:EnableMouseWheel(true)
    scrollChild:EnableMouseWheel(true)

    list:SetScript("OnMouseWheel", OnMouseWheel)
    scrollFrame:SetScript("OnMouseWheel", OnMouseWheel)
    scrollChild:SetScript("OnMouseWheel", OnMouseWheel)

    -- Toggle dropdown
    dropdown:SetScript("OnClick", function(self)
        if self.isOpen then
            list:Hide()
            self.isOpen = false
        else
            PopulateList()
            list:Show()
            self.isOpen = true
        end
    end)

    -- Close on clicking elsewhere
    list:SetScript("OnShow", function(self)
        self:SetScript("OnUpdate", function()
            if not dropdown:IsMouseOver() and not list:IsMouseOver() then
                if IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton") then
                    list:Hide()
                    dropdown.isOpen = false
                end
            end
        end)
    end)

    list:SetScript("OnHide", function(self)
        self:SetScript("OnUpdate", nil)
        -- Clear drag state when list is hidden
        dropdown.isDragging = false
    end)

    -- SetValue method
    function dropdown:SetValue(value)
        self.selectedValue = value
        for _, item in ipairs(self.items) do
            local itemValue, itemLabel, itemColor
            if type(item) == "table" then
                itemValue = item.value or item[1]
                itemLabel = item.label or item[2] or itemValue
                itemColor = item.color
            else
                itemValue = item
                itemLabel = item
            end
            if itemValue == value then
                self.selectedText:SetText(itemLabel)
                if itemColor then
                    self.selectedText:SetTextColor(itemColor.r, itemColor.g, itemColor.b, 1)
                else
                    self.selectedText:SetTextColor(0.9, 0.9, 0.9, 1)
                end
                break
            end
        end
    end

    -- Set initial value if provided
    if options.selectedValue then
        dropdown:SetValue(options.selectedValue)
    end

    return dropdown
end

-- ============================================================================
-- Font Choice Dropdown (with font preview)
-- ============================================================================

--[[
    Creates a font selection dropdown with font preview
    Each font in the list is rendered in its own typeface

    Features:
        - Font preview (each font renders in its own typeface)
        - Scrollable dropdown (40% screen height threshold)
        - Mouse wheel support
        - Checkmark on selected font
        - Alphabetical sorting (case-insensitive)
        - LibSharedMedia integration

    Parameters:
        parent - Parent frame
        name - Unique name for the dropdown (optional)
        label - Label text shown above dropdown (optional)
        width - Dropdown width (default: 200)
        callback - function(fontName) called when selection changes

    Returns: dropdown container with :GetValue(), :SetValue(fontName) methods
]]
function UIFactory:CreateFontChoiceDropdown(parent, name, label, width, callback)
    width = width or 200
    local height = 24
    local itemHeight = 22
    local maxVisibleItems = 12  -- Will be adjusted based on screen height

    local fontPath, fontOutline = GetGeneralFont()
    local fontSize = 12

    -- Get theme colors
    local bgColor, borderColor
    if KOL.Themes and KOL.Themes.GetUIThemeColor then
        bgColor = KOL.Themes:GetUIThemeColor("ContentAreaBG", {r = 0.08, g = 0.08, b = 0.08, a = 1})
        borderColor = KOL.Themes:GetUIThemeColor("ContentAreaBorder", {r = 0.3, g = 0.3, b = 0.3, a = 1})
    else
        bgColor = {r = 0.08, g = 0.08, b = 0.08, a = 1}
        borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1}
    end

    -- Create container for label + dropdown
    local container = CreateFrame("Frame", name, parent)
    container:SetSize(width, label and (height + 18) or height)

    -- Label (if provided)
    local labelText
    if label then
        labelText = container:CreateFontString(nil, "OVERLAY")
        labelText:SetFont(fontPath, fontSize - 1, fontOutline)
        labelText:SetPoint("TOPLEFT", 0, 0)
        labelText:SetText(label)
        labelText:SetTextColor(0.8, 0.8, 0.8, 1)
        container.label = labelText
    end

    -- Create main dropdown button
    local dropdown = CreateFrame("Button", name and (name .. "Button") or nil, container)
    dropdown:SetSize(width, height)
    if label then
        dropdown:SetPoint("TOPLEFT", 0, -16)
    else
        dropdown:SetPoint("TOPLEFT", 0, 0)
    end
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    dropdown:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
    dropdown:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    container.dropdown = dropdown

    -- Selected font text (will render in the selected font)
    local selectedText = dropdown:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont(fontPath, fontSize, fontOutline)
    selectedText:SetPoint("LEFT", 8, 0)
    selectedText:SetPoint("RIGHT", -20, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetText("Select Font...")
    selectedText:SetTextColor(0.7, 0.7, 0.7, 1)
    dropdown.selectedText = selectedText

    -- Arrow indicator
    local arrow = dropdown:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(CHAR_LIGATURESFONT, fontSize, CHAR_LIGATURESOUTLINE)
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetText(CHAR_ARROW_DOWNFILLED)
    arrow:SetTextColor(0.6, 0.6, 0.6, 1)
    dropdown.arrow = arrow

    -- State
    dropdown.selectedValue = nil
    dropdown.isOpen = false
    dropdown.callback = callback
    dropdown.items = {}
    dropdown.itemButtons = {}

    -- Create dropdown list frame
    local list = CreateFrame("Frame", name and (name .. "List") or nil, dropdown)
    list:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    list:SetWidth(width)
    list:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    list:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
    list:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    -- Always use TOOLTIP strata so dropdown list appears above everything
    list:SetFrameStrata("TOOLTIP")
    list:SetFrameLevel(200)
    list:Hide()
    dropdown.list = list

    -- Create scroll frame for the list
    local scrollFrame = CreateFrame("ScrollFrame", name and (name .. "ScrollFrame") or nil, list)
    scrollFrame:SetPoint("TOPLEFT", 2, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
    dropdown.scrollFrame = scrollFrame

    -- Create scroll child (content holder)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(width - 4)
    scrollFrame:SetScrollChild(scrollChild)
    dropdown.scrollChild = scrollChild

    -- Scrollbar (simple custom one)
    local scrollBar = CreateFrame("Frame", nil, list)
    scrollBar:SetWidth(8)
    scrollBar:SetPoint("TOPRIGHT", -2, -2)
    scrollBar:SetPoint("BOTTOMRIGHT", -2, 2)
    scrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    scrollBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    scrollBar:Hide()
    dropdown.scrollBar = scrollBar

    -- Scrollbar thumb
    local scrollThumb = CreateFrame("Frame", nil, scrollBar)
    scrollThumb:SetWidth(6)
    scrollThumb:SetPoint("TOP", 0, 0)
    scrollThumb:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    scrollThumb:SetBackdropColor(0.4, 0.4, 0.4, 1)
    scrollThumb:EnableMouse(true)
    scrollThumb:SetMovable(true)
    dropdown.scrollThumb = scrollThumb

    -- Get sorted font list from LibSharedMedia
    local function GetSortedFonts()
        local fonts = {}
        local fontList = LSM:List("font")

        for _, fontName in ipairs(fontList) do
            table.insert(fonts, fontName)
        end

        -- Case-insensitive alphabetical sort
        table.sort(fonts, function(a, b)
            return string.lower(a) < string.lower(b)
        end)

        return fonts
    end

    -- Create/update item buttons
    local function PopulateList()
        local fonts = GetSortedFonts()
        dropdown.items = fonts

        -- Calculate max visible items based on 40% screen height
        local screenHeight = UIParent:GetHeight()
        local maxListHeight = screenHeight * 0.4
        maxVisibleItems = math.floor(maxListHeight / itemHeight)

        local needsScroll = #fonts > maxVisibleItems
        local visibleCount = needsScroll and maxVisibleItems or #fonts
        local listHeight = (visibleCount * itemHeight) + 4

        list:SetHeight(listHeight)
        scrollChild:SetHeight(#fonts * itemHeight)

        -- Show/hide scrollbar
        if needsScroll then
            scrollBar:Show()
            scrollFrame:SetPoint("BOTTOMRIGHT", -12, 2)

            -- Update thumb size
            local thumbHeight = math.max(20, (visibleCount / #fonts) * (listHeight - 4))
            scrollThumb:SetHeight(thumbHeight)
        else
            scrollBar:Hide()
            scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
        end

        -- Clear existing buttons
        for _, btn in ipairs(dropdown.itemButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
        dropdown.itemButtons = {}

        -- Create item buttons
        for i, fontName in ipairs(fonts) do
            local itemBtn = CreateFrame("Button", nil, scrollChild)
            itemBtn:SetSize(width - (needsScroll and 16 or 8), itemHeight)
            itemBtn:SetPoint("TOPLEFT", 2, -((i - 1) * itemHeight))

            -- Checkmark for selected item
            local checkmark = itemBtn:CreateFontString(nil, "OVERLAY")
            checkmark:SetFont(CHAR_LIGATURESFONT, fontSize - 2, CHAR_LIGATURESOUTLINE)
            checkmark:SetPoint("LEFT", 4, 0)
            checkmark:SetText(CHAR_OBJECTIVE_COMPLETE)
            checkmark:SetTextColor(0, 0.8, 0.8, 1)
            checkmark:Hide()
            itemBtn.checkmark = checkmark

            -- Font name text (rendered in its own font)
            local itemText = itemBtn:CreateFontString(nil, "OVERLAY")
            local fontFilePath = LSM:Fetch("font", fontName)
            -- Try to set the font, fallback to default if it fails
            if fontFilePath and not itemText:SetFont(fontFilePath, fontSize, "") then
                itemText:SetFont(fontPath, fontSize, fontOutline)
            end
            itemText:SetPoint("LEFT", 20, 0)
            itemText:SetPoint("RIGHT", -4, 0)
            itemText:SetJustifyH("LEFT")
            itemText:SetText(fontName)
            itemText:SetTextColor(0.9, 0.9, 0.9, 1)
            itemBtn.itemText = itemText

            itemBtn.fontName = fontName

            -- Update checkmark visibility
            if dropdown.selectedValue == fontName then
                checkmark:Show()
                itemText:SetTextColor(0, 0.9, 0.9, 1)
            end

            -- Hover effect
            itemBtn:SetScript("OnEnter", function(self)
                self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
                self:SetBackdropColor(0.15, 0.15, 0.15, 1)
            end)

            itemBtn:SetScript("OnLeave", function(self)
                self:SetBackdrop(nil)
            end)

            -- Click to select
            itemBtn:SetScript("OnClick", function(self)
                -- Update all checkmarks
                for _, btn in ipairs(dropdown.itemButtons) do
                    btn.checkmark:Hide()
                    btn.itemText:SetTextColor(0.9, 0.9, 0.9, 1)
                end

                -- Show checkmark on selected
                self.checkmark:Show()
                self.itemText:SetTextColor(0, 0.9, 0.9, 1)

                -- Update dropdown state
                dropdown.selectedValue = self.fontName

                -- Update selected text with the font preview
                local selectedFontPath = LSM:Fetch("font", self.fontName)
                if selectedFontPath then
                    dropdown.selectedText:SetFont(selectedFontPath, fontSize, "")
                end
                dropdown.selectedText:SetText(self.fontName)
                dropdown.selectedText:SetTextColor(1, 1, 1, 1)

                -- Close dropdown
                list:Hide()
                dropdown.isOpen = false
                dropdown.arrow:SetText(CHAR_ARROW_DOWNFILLED)

                -- Call callback
                if dropdown.callback then
                    dropdown.callback(self.fontName)
                end
            end)

            table.insert(dropdown.itemButtons, itemBtn)
        end

        -- Reset scroll position
        scrollFrame:SetVerticalScroll(0)
        scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, 0)
    end

    -- Mouse wheel scrolling
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
        if maxScroll <= 0 then return end

        local current = scrollFrame:GetVerticalScroll()
        local newScroll = current - (delta * itemHeight * 2)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        scrollFrame:SetVerticalScroll(newScroll)

        -- Update thumb position
        local scrollPercent = newScroll / maxScroll
        local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
        scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, -scrollPercent * thumbRange)
    end)

    -- Thumb dragging
    scrollThumb:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.dragging = true
            self.dragStartY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            self.dragStartScroll = scrollFrame:GetVerticalScroll()
        end
    end)

    scrollThumb:SetScript("OnMouseUp", function(self)
        self.dragging = false
    end)

    scrollThumb:SetScript("OnUpdate", function(self)
        if self.dragging then
            local currentY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            local deltaY = self.dragStartY - currentY

            local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
            if maxScroll <= 0 then return end

            local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
            local scrollDelta = (deltaY / thumbRange) * maxScroll
            local newScroll = math.max(0, math.min(self.dragStartScroll + scrollDelta, maxScroll))

            scrollFrame:SetVerticalScroll(newScroll)

            -- Update thumb position
            local scrollPercent = newScroll / maxScroll
            scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, -scrollPercent * thumbRange)
        end
    end)

    -- Toggle dropdown
    dropdown:SetScript("OnClick", function(self)
        if self.isOpen then
            self.list:Hide()
            self.isOpen = false
            self.arrow:SetText(CHAR_ARROW_DOWNFILLED)
        else
            PopulateList()

            -- Smart positioning: check if list would go off-screen
            local scale = UIParent:GetEffectiveScale()
            local dropdownBottom = self:GetBottom() * scale
            local listHeight = list:GetHeight() * scale

            list:ClearAllPoints()
            if dropdownBottom - listHeight - 4 < 0 then
                -- List would go below screen - grow upward instead
                list:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
                self.arrow:SetText(CHAR_ARROW_DOWNFILLED)
            else
                -- Normal: grow downward
                list:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
                self.arrow:SetText(CHAR_ARROW_UPFILLED)
            end

            self.list:Show()
            self.isOpen = true

            -- Scroll to selected item if any
            if self.selectedValue then
                for i, fontName in ipairs(self.items) do
                    if fontName == self.selectedValue then
                        local targetScroll = (i - 1) * itemHeight
                        local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
                        if maxScroll > 0 then
                            targetScroll = math.min(targetScroll, maxScroll)
                            scrollFrame:SetVerticalScroll(targetScroll)

                            -- Update thumb position
                            local scrollPercent = targetScroll / maxScroll
                            local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
                            scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, -scrollPercent * thumbRange)
                        end
                        break
                    end
                end
            end
        end
    end)

    -- Hover effect on main button
    dropdown:SetScript("OnEnter", function(self)
        self:SetBackdropColor(bgColor.r + 0.05, bgColor.g + 0.05, bgColor.b + 0.05, bgColor.a or 1)
    end)

    dropdown:SetScript("OnLeave", function(self)
        self:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
    end)

    -- Close when clicking elsewhere (using OnUpdate check)
    list:SetScript("OnUpdate", function(self)
        if dropdown.isOpen and not self:IsMouseOver() and not dropdown:IsMouseOver() then
            if IsMouseButtonDown("LeftButton") then
                self:Hide()
                dropdown.isOpen = false
                dropdown.arrow:SetText(CHAR_ARROW_DOWNFILLED)
            end
        end
    end)

    -- Public methods
    function container:GetValue()
        return dropdown.selectedValue
    end

    function container:SetValue(fontName)
        if not fontName then return end

        dropdown.selectedValue = fontName

        -- Update display text with font preview
        local selectedFontPath = LSM:Fetch("font", fontName)
        if selectedFontPath then
            dropdown.selectedText:SetFont(selectedFontPath, fontSize, "")
        end
        dropdown.selectedText:SetText(fontName)
        dropdown.selectedText:SetTextColor(1, 1, 1, 1)

        -- Update checkmarks if list is populated
        for _, btn in ipairs(dropdown.itemButtons) do
            if btn.fontName == fontName then
                btn.checkmark:Show()
                btn.itemText:SetTextColor(0, 0.9, 0.9, 1)
            else
                btn.checkmark:Hide()
                btn.itemText:SetTextColor(0.9, 0.9, 0.9, 1)
            end
        end
    end

    function container:SetCallback(cb)
        dropdown.callback = cb
    end

    function container:Close()
        dropdown.list:Hide()
        dropdown.isOpen = false
        dropdown.arrow:SetText(CHAR_ARROW_DOWNFILLED)
    end

    return container
end

KOL:DebugPrint("UI Factory loaded with enhanced components", 1)
