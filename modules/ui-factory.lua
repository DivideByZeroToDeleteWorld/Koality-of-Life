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

-- ============================================================================
-- Frame Creation
-- ============================================================================

--[[
    Creates a styled frame with dark theme and 1px border

    Parameters:
        parent - Parent frame (optional, defaults to UIParent)
        name - Frame name (optional)
        width - Frame width
        height - Frame height
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
    frame:SetWidth(width)
    frame:SetHeight(height)
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

    -- Set colors
    local bgColor = options.bgColor or {r = 0.02, g = 0.02, b = 0.02, a = 0.98}
    local borderColor = options.borderColor or {r = 0.4, g = 0.4, b = 0.4, a = 1}

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
    title:SetPoint("LEFT", titleBar, "LEFT", 8, 0)  -- Left-aligned instead of center
    title:SetText(text)

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

    local bgColor = options.bgColor or {r = 0.01, g = 0.01, b = 0.01, a = 1}
    local borderColor = options.borderColor or {r = 0.25, g = 0.25, b = 0.25, a = 1}

    content:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    content:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

    return content
end

-- ============================================================================
-- Button Creation
-- ============================================================================

--[[
    Creates a styled button

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
        button.kolArrowText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        button.kolArrowText:SetPoint("CENTER", 0, 0)
        button.kolArrowText:SetTextColor(unpack(arrow))

        if direction == "up" then
            button.kolArrowText:SetText("▲")
        elseif direction == "down" then
            button.kolArrowText:SetText("▼")
        elseif direction == "left" then
            button.kolArrowText:SetText("◄")
        elseif direction == "right" then
            button.kolArrowText:SetText("►")
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

KOL:DebugPrint("UI Factory loaded", 1)
