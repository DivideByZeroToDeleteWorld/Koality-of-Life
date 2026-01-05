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
-- Glyph / Icon Character Helpers
-- ============================================================================
-- These functions ensure CHAR_LIGATURESFONT is always used for special chars
-- ============================================================================

-- Convert color to hex string
local function ColorToHex(color)
    if type(color) == "string" then
        local cleaned = color
        -- Only strip |cFF prefix if present (don't strip FF from valid hex like "FFFFFF")
        if cleaned:match("^|c[Ff][Ff]") then
            cleaned = cleaned:sub(5)  -- Remove "|cFF" (4 chars)
        end
        -- Ensure exactly 6 hex chars (pad or truncate)
        if #cleaned < 6 then
            cleaned = cleaned .. string.rep("0", 6 - #cleaned)
        end
        return cleaned:sub(1, 6)
    elseif type(color) == "table" then
        -- Support both indexed {r, g, b} and named {r=, g=, b=} formats
        local r, g, b
        if color[1] ~= nil then
            r, g, b = color[1], color[2], color[3]
        elseif color.r ~= nil then
            r, g, b = color.r, color.g, color.b
        else
            return "FFFFFF"
        end
        r = math.floor((tonumber(r) or 1) * 255)
        g = math.floor((tonumber(g) or 1) * 255)
        b = math.floor((tonumber(b) or 1) * 255)
        return string.format("%02X%02X%02X", r, g, b)
    end
    return "FFFFFF"
end

--- Format a glyph character with color codes
-- @param char string - The glyph character (e.g., CHAR_FOLDER)
-- @param color table|string - Color as {r,g,b}, {1,1,1}, or "RRGGBB" hex (optional, default white)
-- @return string - Formatted "|cFFrrggbbX|r" string
function UIFactory:FormatGlyph(char, color)
    if not char or char == "" then return "" end
    local hex = color and ColorToHex(color) or "FFFFFF"
    return "|cFF" .. hex .. char .. "|r"
end

--- Create a FontString configured for glyph/icon characters
-- @param parent frame - Parent frame for the fontstring
-- @param char string - The glyph character (e.g., CHAR_FOLDER)
-- @param color table|string - Color as {r,g,b} or "RRGGBB" hex (optional, default white)
-- @param size number - Font size (optional, default 10)
-- @param drawLayer string - Draw layer within frame: BACKGROUND, BORDER, ARTWORK, OVERLAY, HIGHLIGHT (optional, default "OVERLAY")
-- @return fontstring - The created and configured FontString
function UIFactory:CreateGlyph(parent, char, color, size, drawLayer)
    if not parent then return nil end

    size = size or 10
    drawLayer = drawLayer or "OVERLAY"

    local fs = parent:CreateFontString(nil, drawLayer)
    fs:SetFont(CHAR_LIGATURESFONT, size, CHAR_LIGATURESOUTLINE or "OUTLINE")

    if char and char ~= "" then
        fs:SetText(self:FormatGlyph(char, color))
    end

    -- Store references for later updates
    fs.glyphChar = char
    fs.glyphColor = color
    fs.glyphSize = size

    -- Helper method to update the glyph
    fs.SetGlyph = function(self, newChar, newColor)
        self.glyphChar = newChar or self.glyphChar
        self.glyphColor = newColor or self.glyphColor
        self:SetText(UIFactory:FormatGlyph(self.glyphChar, self.glyphColor))
    end

    return fs
end

--- Create an interactive FontString with hover effects and animations
-- @param parent frame - Parent frame for the fontstring (MUST be a mouse-enabled frame for hover to work)
-- @param char string - The glyph character (e.g., CHAR_FOLDER)
-- @param options table - Configuration options:
--   .color        table|string - Primary color (default white)
--   .hoverColor   table|string - Color on hover (optional)
--   .size         number - Font size (default 10)
--   .drawLayer    string - Draw layer (default "OVERLAY")
--   .animate      string - Animation type: "rainbow", "pulse", "none" (default "none")
--   .animSpeed    number - Animation speed in seconds per cycle (default 2)
-- @return fontstring - The created FontString with extended methods
function UIFactory:CreateInteractiveGlyph(parent, char, options)
    if not parent then return nil end

    options = options or {}
    local color = options.color or "FFFFFF"
    local hoverColor = options.hoverColor
    local size = options.size or 10
    local drawLayer = options.drawLayer or "OVERLAY"
    local animate = options.animate or "none"
    local animSpeed = options.animSpeed or 2

    local fs = parent:CreateFontString(nil, drawLayer)
    fs:SetFont(CHAR_LIGATURESFONT, size, CHAR_LIGATURESOUTLINE or "OUTLINE")
    fs:SetText(self:FormatGlyph(char, color))

    -- Store state
    fs.glyphChar = char
    fs.glyphColor = color
    fs.glyphHoverColor = hoverColor
    fs.glyphSize = size
    fs.isHovering = false
    fs.animationType = animate
    fs.animSpeed = animSpeed
    fs.animFrame = nil

    -- SetGlyph method
    fs.SetGlyph = function(self, newChar, newColor)
        self.glyphChar = newChar or self.glyphChar
        self.glyphColor = newColor or self.glyphColor
        if not self.isHovering or not self.glyphHoverColor then
            self:SetText(UIFactory:FormatGlyph(self.glyphChar, self.glyphColor))
        end
    end

    -- Set hover color
    fs.SetHoverColor = function(self, newHoverColor)
        self.glyphHoverColor = newHoverColor
    end

    -- Start animation
    fs.StartAnimation = function(self, animType)
        self.animationType = animType or self.animationType
        if self.animationType == "none" then return end

        if not self.animFrame then
            self.animFrame = CreateFrame("Frame", nil, parent)
        end

        local elapsed = 0
        self.animFrame:SetScript("OnUpdate", function(frame, delta)
            elapsed = elapsed + delta
            local t = (elapsed % self.animSpeed) / self.animSpeed  -- 0 to 1

            if self.animationType == "rainbow" then
                -- Cycle through rainbow colors
                local r, g, b
                local h = t * 6
                local i = math.floor(h)
                local f = h - i
                local q = 1 - f
                if i == 0 then r, g, b = 1, f, 0
                elseif i == 1 then r, g, b = q, 1, 0
                elseif i == 2 then r, g, b = 0, 1, f
                elseif i == 3 then r, g, b = 0, q, 1
                elseif i == 4 then r, g, b = f, 0, 1
                else r, g, b = 1, 0, q end
                self:SetText(UIFactory:FormatGlyph(self.glyphChar, {r, g, b}))

            elseif self.animationType == "pulse" then
                -- Pulse between color and white
                local brightness = 0.5 + 0.5 * math.sin(t * 2 * math.pi)
                local baseColor = self.glyphColor or "FFFFFF"
                local hex = ColorToHex(baseColor)
                local r = tonumber(hex:sub(1,2), 16) / 255
                local g = tonumber(hex:sub(3,4), 16) / 255
                local b = tonumber(hex:sub(5,6), 16) / 255
                r = r + (1 - r) * brightness
                g = g + (1 - g) * brightness
                b = b + (1 - b) * brightness
                self:SetText(UIFactory:FormatGlyph(self.glyphChar, {r, g, b}))
            end
        end)
        self.animFrame:Show()
    end

    -- Stop animation
    fs.StopAnimation = function(self)
        if self.animFrame then
            self.animFrame:SetScript("OnUpdate", nil)
            self.animFrame:Hide()
        end
        -- Restore base color
        self:SetText(UIFactory:FormatGlyph(self.glyphChar, self.glyphColor))
    end

    -- Set up hover if parent supports it and hoverColor is specified
    if hoverColor then
        local origEnter = parent:GetScript("OnEnter")
        local origLeave = parent:GetScript("OnLeave")

        parent:HookScript("OnEnter", function()
            fs.isHovering = true
            fs:SetText(UIFactory:FormatGlyph(fs.glyphChar, fs.glyphHoverColor))
        end)

        parent:HookScript("OnLeave", function()
            fs.isHovering = false
            fs:SetText(UIFactory:FormatGlyph(fs.glyphChar, fs.glyphColor))
        end)
    end

    -- Start animation if specified
    if animate ~= "none" then
        fs:StartAnimation(animate)
    end

    return fs
end

-- ============================================================================
-- Frame Registry & Strata Management
-- ============================================================================
-- Intelligent system to manage frame stacking order
-- - Frames auto-raise when clicked/dragged
-- - Dropdowns inherit parent strata + offset
-- - All KOL frames stay above normal game UI
-- ============================================================================

-- Strata hierarchy (lowest to highest):
-- MEDIUM = 1, HIGH = 2, DIALOG = 3, FULLSCREEN = 4, FULLSCREEN_DIALOG = 5, TOOLTIP = 6
local STRATA_ORDER = {
    ["BACKGROUND"] = 0,
    ["LOW"] = 1,
    ["MEDIUM"] = 2,
    ["HIGH"] = 3,
    ["DIALOG"] = 4,
    ["FULLSCREEN"] = 5,
    ["FULLSCREEN_DIALOG"] = 6,
    ["TOOLTIP"] = 7,
}

-- ============================================================================
-- SMART SLOT MANAGEMENT SYSTEM
-- ============================================================================
-- Each frame gets a permanent "home" slot when created
-- There's one special "active" slot that's always highest
-- Focused frame moves to active slot; previous active returns to its home
-- Closed frames release their home slot for reuse
-- ============================================================================

-- Simple slot-based system: each frame gets a home level, active frame goes high
-- WoW automatically handles child frame levels - no recursion needed!
UIFactory.HOME_LEVEL = 100        -- Base level for home slots
UIFactory.ACTIVE_LEVEL = 500      -- Level for the active (focused) frame
UIFactory.nextHomeLevel = 100     -- Counter for assigning home levels

UIFactory.frameRegistry = {}      -- Registered frames
UIFactory.activeFrame = nil       -- Currently focused frame

-- All KOL frames use DIALOG strata for consistent z-ordering
UIFactory.KOL_STRATA = "DIALOG"
UIFactory.STRATA = {
    NORMAL = "DIALOG",
    IMPORTANT = "DIALOG",
    MODAL = "FULLSCREEN_DIALOG",
}

-- Register a frame (called when frame is created)
function UIFactory:RegisterFrame(frame, strata)
    if not frame then return end

    strata = strata or self.STRATA.NORMAL

    -- Assign a unique home level (increments by 10 for each frame)
    local homeLevel = self.nextHomeLevel
    self.nextHomeLevel = self.nextHomeLevel + 10

    frame:SetFrameStrata(strata)
    frame:SetFrameLevel(homeLevel)
    frame.kolStrata = strata
    frame.kolHomeLevel = homeLevel
    frame.kolRegistered = true

    -- Store in registry
    self.frameRegistry[frame] = true

    return homeLevel
end

-- Unregister a frame (called when frame is closed/destroyed)
function UIFactory:UnregisterFrame(frame)
    if not frame or not frame.kolRegistered then return end

    -- If this was the active frame, clear it
    if self.activeFrame == frame then
        self.activeFrame = nil
    end

    self.frameRegistry[frame] = nil
    frame.kolRegistered = false
    frame.kolHomeLevel = nil
end

-- Raise a frame to the active level (called on show/focus)
-- This is INSTANT - just two SetFrameLevel calls, no recursion!
function UIFactory:RaiseFrame(frame)
    if not frame or not frame.kolRegistered then return end

    -- If already the active frame, do nothing
    if self.activeFrame == frame then
        return
    end

    -- Return the previous active frame to its home level
    if self.activeFrame and self.activeFrame.kolRegistered and self.activeFrame.kolHomeLevel then
        self.activeFrame:SetFrameLevel(self.activeFrame.kolHomeLevel)
    end

    -- Raise this frame to the active level
    frame:SetFrameLevel(self.ACTIVE_LEVEL)
    self.activeFrame = frame

    -- Ensure it's toplevel
    if frame.SetToplevel then
        frame:SetToplevel(true)
    end
end

-- Get frame's strata info (simplified - no more slot/level complexity)
function UIFactory:GetFrameStrataInfo(frame)
    if frame then
        return frame:GetFrameStrata(), frame:GetFrameLevel()
    end
    return self.STRATA.NORMAL, 100
end

-- Get dropdown strata/level (use TOOLTIP strata for guaranteed visibility)
function UIFactory:GetDropdownStrataInfo(parentFrame)
    -- Use TOOLTIP strata to guarantee dropdown lists render above all other frames
    -- This fixes issues where dropdown text appears behind parent frames
    return "TOOLTIP", 100
end

-- Find the root KOL frame for a given child frame
function UIFactory:FindRootFrame(frame)
    local current = frame
    while current do
        if current.kolRegistered then
            return current
        end
        current = current:GetParent()
    end
    return nil
end

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
            - strata: string - Frame strata (default: UIFactory.STRATA.NORMAL = "HIGH")
                      Can use: "HIGH", "DIALOG", "FULLSCREEN_DIALOG", or UIFactory.STRATA constants
            - level: number - Frame level (optional, auto-assigned if not provided)
            - noRegister: boolean - Don't register in frame registry (for child frames)

    Returns: frame
]]
function UIFactory:CreateStyledFrame(parent, name, width, height, options)
    options = options or {}
    parent = parent or UIParent

    local frame = CreateFrame("Frame", name, parent)

    -- Only set width/height if provided (allows sizing via anchors)
    if width then frame:SetWidth(width) end
    if height then frame:SetHeight(height) end

    -- Determine strata - use provided or default to NORMAL
    local strata = options.strata or self.STRATA.NORMAL

    -- Register frame unless it's a child/internal frame
    if not options.noRegister then
        -- If explicit level provided, use it; otherwise auto-assign
        if options.level then
            frame:SetFrameStrata(strata)
            frame:SetFrameLevel(options.level)
            frame.kolStrata = strata
            frame.kolLevel = options.level
            frame.kolRegistered = true
            table.insert(self.frameRegistry, frame)
        else
            self:RegisterFrame(frame, strata)
        end
    else
        -- Child frame - just set strata/level directly
        frame:SetFrameStrata(strata)
        frame:SetFrameLevel(options.level or 1)
    end

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

    -- Auto-raise whenever frame is shown (moves to active slot)
    frame:SetScript("OnShow", function(self)
        UIFactory:RaiseFrame(self)
    end)

    -- Return to home level when hidden (releases active level for other frames)
    frame:SetScript("OnHide", function(self)
        -- If this was the active frame, return it to home level and clear active
        if UIFactory.activeFrame == self then
            UIFactory.activeFrame = nil
            if self.kolHomeLevel then
                self:SetFrameLevel(self.kolHomeLevel)
            end
        end
    end)

    -- Make movable if requested
    if options.movable then
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    end

    -- Instant click-to-front: raise frame immediately on any mouse click
    frame:HookScript("OnMouseDown", function(self)
        UIFactory:RaiseFrame(self)
    end)

    -- Make closable with ESC
    if options.closable and name then
        tinsert(UISpecialFrames, name)
    end

    -- Set as toplevel so clicking raises it
    frame:SetToplevel(true)

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
    Creates a styled section header with a colored left accent bar.
    Useful for visually separating sections in config panels or lists.

    Parameters:
        parent - Parent frame
        text - Section title text
        color - Table with {r, g, b} values (0-1 range) for the accent color
        width - Width of the header (optional, defaults to parent width)

    Returns: header frame with .text (fontstring) and .accent (texture) references

    Example:
        local header = UIFactory:CreateSectionHeader(scrollChild, "Combat Settings", {r=0.8, g=0.2, b=0.2}, 300)
        header:SetPoint("TOPLEFT", 0, -yOffset)
]]
function UIFactory:CreateSectionHeader(parent, text, color, width)
    color = color or {r = 0.6, g = 0.6, b = 0.6}  -- Default gray

    local header = CreateFrame("Frame", nil, parent)
    header:SetHeight(22)

    -- Width handling: use provided width or stretch to parent
    if width then
        header:SetWidth(width)
    else
        -- Will need to be anchored with SetPoint to define width
        header:SetWidth(200)  -- Fallback default
    end

    -- Background - subtle dark using accent color at 20% intensity
    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetAllPoints()
    bg:SetVertexColor(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.8)
    header.bg = bg

    -- Left accent bar (3px wide)
    local accent = header:CreateTexture(nil, "ARTWORK")
    accent:SetTexture("Interface\\Buttons\\WHITE8X8")
    accent:SetWidth(3)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", 0, 0)
    accent:SetVertexColor(color.r, color.g, color.b, 1)
    header.accent = accent

    -- Text in accent color
    local fontPath, fontOutline = GetGeneralFont()
    local label = header:CreateFontString(nil, "OVERLAY")
    label:SetFont(fontPath, 11, fontOutline)  -- Slightly larger than normal (10+1)
    label:SetPoint("LEFT", 10, 0)
    label:SetTextColor(color.r, color.g, color.b, 1)
    label:SetText(text)
    header.text = label

    -- Store color for potential updates
    header.color = color

    -- Method to update the color dynamically
    function header:SetAccentColor(newColor)
        self.color = newColor
        self.bg:SetVertexColor(newColor.r * 0.2, newColor.g * 0.2, newColor.b * 0.2, 0.8)
        self.accent:SetVertexColor(newColor.r, newColor.g, newColor.b, 1)
        self.text:SetTextColor(newColor.r, newColor.g, newColor.b, 1)
    end

    -- Method to update the text
    function header:SetText(newText)
        self.text:SetText(newText)
    end

    return header
end

-- ============================================================================
-- AceGUI Custom Widget: KOL_SectionHeader
-- ============================================================================
-- This allows using CreateSectionHeader in AceConfig via dialogControl
-- Usage in AceConfig options:
--   fontHeader = {
--       type = "description",
--       name = "Fonts|1,0.67,0",  -- Text|R,G,B (color encoded in name)
--       dialogControl = "KOL_SectionHeader",
--       width = "full",
--       order = 3,
--   },
-- ============================================================================

local function RegisterAceGUISectionHeader()
    local AceGUI = LibStub("AceGUI-3.0", true)
    if not AceGUI then return end

    local Type = "KOL_SectionHeader"
    local Version = 2  -- Incremented version

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetHeight(22)
        frame:Hide()

        -- Background - will be colored based on accent
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetAllPoints()
        bg:SetVertexColor(0.12, 0.12, 0.12, 0.8)  -- Default dark
        frame.bg = bg

        -- Left accent bar (3px wide)
        local accent = frame:CreateTexture(nil, "ARTWORK")
        accent:SetTexture("Interface\\Buttons\\WHITE8X8")
        accent:SetWidth(3)
        accent:SetPoint("TOPLEFT", 0, 0)
        accent:SetPoint("BOTTOMLEFT", 0, 0)
        accent:SetVertexColor(0.6, 0.6, 0.6, 1)  -- Default gray
        frame.accent = accent

        -- Text - vertically centered
        local fontPath, fontOutline = GetGeneralFont()
        local label = frame:CreateFontString(nil, "OVERLAY")
        label:SetFont(fontPath, 11, fontOutline)
        label:SetPoint("LEFT", 10, 0)
        label:SetPoint("TOP", 0, 0)
        label:SetPoint("BOTTOM", 0, 0)
        label:SetJustifyV("MIDDLE")
        label:SetTextColor(0.6, 0.6, 0.6, 1)  -- Default gray
        frame.label = label

        -- Widget object
        local widget = {
            frame = frame,
            type = Type,
            bg = bg,
            accent = accent,
            label = label,
            color = {r = 0.6, g = 0.6, b = 0.6},
        }

        -- Set the accent color (affects bar, background, and text)
        function widget:SetColor(color)
            if not color then return end
            self.color = color
            self.bg:SetVertexColor(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.8)
            self.accent:SetVertexColor(color.r, color.g, color.b, 1)
            self.label:SetTextColor(color.r, color.g, color.b, 1)
        end

        -- AceGUI required methods
        function widget:OnAcquire()
            -- Refresh font in case it changed
            local fontPath, fontOutline = GetGeneralFont()
            self.label:SetFont(fontPath, 11, fontOutline)
            self.frame:Show()
        end

        function widget:OnRelease()
            self.frame:ClearAllPoints()
            self.frame:Hide()
            self.label:SetText("")
            -- Reset to default color
            self:SetColor({r = 0.6, g = 0.6, b = 0.6})
        end

        -- Parse text for color: "Header Text|R,G,B" format
        function widget:SetText(text)
            if not text then
                self.label:SetText("")
                return
            end

            -- Check for color encoding: "Text|R,G,B"
            local displayText, colorStr = text:match("^(.+)|([%d%.]+,[%d%.]+,[%d%.]+)$")
            if displayText and colorStr then
                self.label:SetText(displayText)
                -- Parse color
                local r, g, b = colorStr:match("([%d%.]+),([%d%.]+),([%d%.]+)")
                if r and g and b then
                    self:SetColor({r = tonumber(r), g = tonumber(g), b = tonumber(b)})
                end
            else
                -- No color encoded, just set text
                self.label:SetText(text)
            end
        end

        function widget:SetLabel(text)
            self:SetText(text)
        end

        function widget:SetWidth(width)
            self.frame:SetWidth(width)
        end

        function widget:SetHeight(height)
            self.frame:SetHeight(height or 22)
        end

        -- Disable/Enable (not really applicable for a header)
        function widget:SetDisabled(disabled) end

        -- AceConfigDialog calls these on description widgets
        function widget:SetFontObject(font) end
        function widget:SetJustifyH(justify) end
        function widget:SetJustifyV(justify) end
        function widget:SetImageSize(width, height) end
        function widget:SetImage(path, ...) end
        function widget:SetFullWidth(isFull) end
        function widget:SetFullHeight(isFull) end

        function widget:SetCallback(name, func)
            self.callbacks = self.callbacks or {}
            self.callbacks[name] = func
        end

        return AceGUI:RegisterAsWidget(widget)
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
    KOL:DebugPrint("Registered AceGUI widget: KOL_SectionHeader", 2)
end

-- Register the widget when this file loads (after a short delay to ensure AceGUI is ready)
C_Timer.After(0, RegisterAceGUISectionHeader)

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
function UIFactory:OldCreateStyledButton(parent, width, height, text, options)
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

    -- Default colors and dimensions - pull from theme system
    colors = colors or {}

    -- Get theme colors for scrollbar (convert hex to RGBA)
    local function GetThemeScrollbarColor(colorName, fallback)
        if KOL.Themes and KOL.Themes.GetUIThemeColor then
            local themeColor = KOL.Themes:GetUIThemeColor(colorName, nil)
            if themeColor then
                return {themeColor.r, themeColor.g, themeColor.b, themeColor.a or 1}
            end
        end
        return fallback
    end

    local trackBg = colors.track and colors.track.bg or GetThemeScrollbarColor("ScrollbarTrackBG", {0.05, 0.05, 0.05, 0.9})
    local trackBorder = colors.track and colors.track.border or GetThemeScrollbarColor("ScrollbarTrackBorder", {0.2, 0.2, 0.2, 1})
    local thumbBg = colors.thumb and colors.thumb.bg or GetThemeScrollbarColor("ScrollbarThumbBG", {0.3, 0.3, 0.3, 1})
    local thumbBorder = colors.thumb and colors.thumb.border or GetThemeScrollbarColor("ScrollbarThumbBorder", {0.2, 0.2, 0.2, 1})
    local buttonBg = colors.button and colors.button.bg or GetThemeScrollbarColor("ScrollbarButtonBG", {0.15, 0.15, 0.15, 0.9})
    local buttonBorder = colors.button and colors.button.border or GetThemeScrollbarColor("ScrollbarButtonBorder", {0.2, 0.2, 0.2, 1})
    local buttonArrow = colors.button and colors.button.arrow or GetThemeScrollbarColor("ScrollbarButtonArrow", {0.5, 0.5, 0.5, 1})
    local scrollbarWidth = colors.width or 16

    -- Always update width (allows live resizing)
    scrollBar:SetWidth(scrollbarWidth)

    -- Note: We no longer return early even if skinned, to allow color updates

    -- Find scroll buttons and thumb (try multiple naming patterns for WoW 3.3.5a)
    -- IMPORTANT: Use the scrollbar's actual name, not the property name passed in
    local scrollBarRealName = scrollBar:GetName() or ""
    local upButton = scrollBar.ScrollUpButton or scrollBar.UpButton or _G[scrollBarRealName .. "ScrollUpButton"]
    local downButton = scrollBar.ScrollDownButton or scrollBar.DownButton or _G[scrollBarRealName .. "ScrollDownButton"]
    local thumb = scrollBar.ThumbTexture or scrollBar.thumbTexture or _G[scrollBarRealName .. "ThumbTexture"]

    KOL:DebugPrint("UI: SkinScrollBar - scrollBarRealName: " .. scrollBarRealName .. ", upButton: " .. tostring(upButton) .. ", downButton: " .. tostring(downButton) .. ", thumb: " .. tostring(thumb), 3)

    -- Clear default textures (named children) - use solid texture set to fully transparent
    local function HideScrollbarRegion(region)
        if region then
            pcall(function()
                if region.SetTexture then region:SetTexture("Interface\\Buttons\\WHITE8X8") end
                if region.SetVertexColor then region:SetVertexColor(0, 0, 0, 0) end
                if region.SetAlpha then region:SetAlpha(0) end
                region:Hide()
            end)
        end
    end

    HideScrollbarRegion(scrollBar.Background)
    HideScrollbarRegion(scrollBar.Top)
    HideScrollbarRegion(scrollBar.Middle)
    HideScrollbarRegion(scrollBar.Bottom)

    -- In WoW 3.3.5a, also iterate through ALL scrollbar regions to hide any we missed
    if not scrollBar.kolRegionsHidden then
        local regions = { scrollBar:GetRegions() }
        for _, region in ipairs(regions) do
            if region and region ~= thumb then  -- Don't hide the thumb, we handle it separately
                HideScrollbarRegion(region)
            end
        end
        scrollBar.kolRegionsHidden = true
    end

    -- Create backdrop for scrollbar track (or update colors if it exists)
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
        scrollBar.kolBackdrop:SetFrameLevel(scrollBar:GetFrameLevel())
    end
    -- Always update colors (allows theme changes to apply)
    scrollBar.kolBackdrop:SetBackdropColor(unpack(trackBg))
    scrollBar.kolBackdrop:SetBackdropBorderColor(unpack(trackBorder))

    -- Skin the thumb (draggable part)
    if thumb then
        -- Aggressively hide original thumb texture - use solid texture set to fully transparent
        pcall(function()
            thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
            thumb:SetVertexColor(0, 0, 0, 0)
            thumb:SetAlpha(0)
        end)

        if not thumb.kolBackdrop then
            thumb.kolBackdrop = CreateFrame("Frame", nil, scrollBar)
            thumb.kolBackdrop:SetWidth(scrollbarWidth)  -- Full width to cover edges
            thumb.kolBackdrop:SetHeight(26)  -- Slightly taller to cover any edge artifacts
            thumb.kolBackdrop:SetPoint("CENTER", thumb, "CENTER", 0, 0)
            thumb.kolBackdrop:SetFrameLevel(scrollBar:GetFrameLevel() + 10)  -- Higher frame level
            thumb.kolBackdrop:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false,
                edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
        end
        -- ALWAYS ensure mouse passes through to actual thumb (fixes drag)
        thumb.kolBackdrop:EnableMouse(false)
        -- Always update colors and width (allows theme changes to apply)
        thumb.kolBackdrop:SetWidth(scrollbarWidth)
        thumb.kolBackdrop:SetBackdropColor(unpack(thumbBg))
        thumb.kolBackdrop:SetBackdropBorderColor(unpack(thumbBorder))
    end

    -- Skin or hide up/down buttons
    if colors.hideButtons then
        -- Hide buttons completely for minimal scrollbar look
        local function HideButtonCompletely(button)
            if not button then return end

            -- Hide the button itself
            button:Hide()
            button:SetAlpha(0)
            button:SetHeight(1)
            button:SetWidth(1)

            -- Hide any custom backdrop we created
            if button.kolBackdrop then
                button.kolBackdrop:Hide()
                button.kolBackdrop:SetAlpha(0)
            end
            if button.kolArrow then
                button.kolArrow:Hide()
                button.kolArrow:SetAlpha(0)
            end

            -- Clear all button textures
            pcall(function()
                if button.GetNormalTexture and button:GetNormalTexture() then
                    button:GetNormalTexture():SetTexture(nil)
                    button:GetNormalTexture():Hide()
                end
                if button.GetPushedTexture and button:GetPushedTexture() then
                    button:GetPushedTexture():SetTexture(nil)
                    button:GetPushedTexture():Hide()
                end
                if button.GetDisabledTexture and button:GetDisabledTexture() then
                    button:GetDisabledTexture():SetTexture(nil)
                    button:GetDisabledTexture():Hide()
                end
                if button.GetHighlightTexture and button:GetHighlightTexture() then
                    button:GetHighlightTexture():SetTexture(nil)
                    button:GetHighlightTexture():Hide()
                end
            end)

            -- Hide all child regions
            local regions = {button:GetRegions()}
            for _, region in ipairs(regions) do
                if region then
                    pcall(function()
                        if region.SetTexture then region:SetTexture(nil) end
                        if region.SetAlpha then region:SetAlpha(0) end
                        region:Hide()
                    end)
                end
            end

            -- Disable the button so it doesn't respond to clicks
            button:Disable()
        end

        HideButtonCompletely(upButton)
        HideButtonCompletely(downButton)
    else
        -- Skin up button
        if upButton then
            local buttonColors = {bg = buttonBg, border = buttonBorder, arrow = buttonArrow, width = scrollbarWidth}
            self:SkinScrollButton(upButton, "up", buttonColors)
            upButton:SetPoint("BOTTOM", scrollBar, "TOP", 0, 1)
        end

        -- Skin down button
        if downButton then
            local buttonColors = {bg = buttonBg, border = buttonBorder, arrow = buttonArrow, width = scrollbarWidth}
            self:SkinScrollButton(downButton, "down", buttonColors)
            downButton:SetPoint("TOP", scrollBar, "BOTTOM", 0, -1)
        end
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
    if not button then return end

    -- Default colors and dimensions
    colors = colors or {}
    local bg = colors.bg or {0.15, 0.15, 0.15, 0.9}
    local border = colors.border or {0.25, 0.25, 0.25, 1}
    local arrow = colors.arrow or {0.6, 0.6, 0.6, 1}
    local buttonSize = colors.width or 16

    -- Always update size (allows live resizing)
    button:SetSize(buttonSize, buttonSize)

    -- Note: We no longer return early even if skinned, to allow color updates

    -- Aggressively hide ALL original textures
    -- First try the standard texture getters - use solid texture set to fully transparent
    local function HideTexture(tex)
        if tex then
            tex:SetTexture("Interface\\Buttons\\WHITE8X8")
            tex:SetVertexColor(0, 0, 0, 0)
            tex:SetAlpha(0)
            tex:Hide()
        end
    end

    pcall(function()
        if button.GetNormalTexture then HideTexture(button:GetNormalTexture()) end
        if button.GetPushedTexture then HideTexture(button:GetPushedTexture()) end
        if button.GetDisabledTexture then HideTexture(button:GetDisabledTexture()) end
        if button.GetHighlightTexture then HideTexture(button:GetHighlightTexture()) end
    end)

    -- In WoW 3.3.5a, also iterate through ALL regions to catch any we missed
    if not button.kolRegionsHidden then
        local regions = { button:GetRegions() }
        for _, region in ipairs(regions) do
            if region then
                pcall(function()
                    if region.SetTexture then
                        region:SetTexture("Interface\\Buttons\\WHITE8X8")
                    end
                    if region.SetVertexColor then
                        region:SetVertexColor(0, 0, 0, 0)
                    end
                    if region.SetAlpha then
                        region:SetAlpha(0)
                    end
                    region:Hide()
                end)
            end
        end
        button.kolRegionsHidden = true
    end

    -- Also clear the button's own backdrop if it has one (some templates add backdrops)
    pcall(function()
        if button.SetBackdrop then
            button:SetBackdrop(nil)
        end
    end)

    -- Hide any child frames (not just regions) that might have their own visuals
    if not button.kolChildrenHidden then
        local children = { button:GetChildren() }
        for _, child in ipairs(children) do
            if child and not child.kolBackdrop then  -- Don't hide our own backdrop
                pcall(function()
                    if child.SetBackdrop then child:SetBackdrop(nil) end
                    -- Don't hide children completely as they might be needed for functionality
                    -- Just remove their backdrops
                end)
            end
        end
        button.kolChildrenHidden = true
    end

    -- Create backdrop (set very high frame level to cover original textures)
    -- Make it slightly larger than the button to fully cover any edge artifacts
    if not button.kolBackdrop then
        button.kolBackdrop = CreateFrame("Frame", nil, button)
        button.kolBackdrop:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
        button.kolBackdrop:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
        button.kolBackdrop:SetFrameLevel(button:GetFrameLevel() + 10)
        button.kolBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
    end
    -- Always update colors (allows theme changes to apply)
    button.kolBackdrop:SetBackdropColor(unpack(bg))
    button.kolBackdrop:SetBackdropBorderColor(unpack(border))

    -- Create arrow text on the backdrop (ensures it's above everything)
    if not button.kolArrowText then
        button.kolArrowText = button.kolBackdrop:CreateFontString(nil, "OVERLAY")
        button.kolArrowText:SetFont(CHAR_LIGATURESFONT, 10, CHAR_LIGATURESOUTLINE)
        button.kolArrowText:SetPoint("CENTER", button.kolBackdrop, "CENTER", 0, 0)

        if direction == "up" then
            button.kolArrowText:SetText(CHAR_ARROW_UPFILLED)
        elseif direction == "down" then
            button.kolArrowText:SetText(CHAR_ARROW_DOWNFILLED)
        elseif direction == "left" then
            button.kolArrowText:SetText(CHAR_ARROW_LEFTFILLED)
        elseif direction == "right" then
            button.kolArrowText:SetText(CHAR_ARROW_RIGHTFILLED)
        end
    end
    -- Always update arrow color (allows theme changes to apply)
    button.kolArrowText:SetTextColor(unpack(arrow))

    -- Store colors for hover effects
    button.kolColors = {bg = bg, border = border, arrow = arrow}

    -- Hover effect (keep gray by adding equally to all channels)
    button:SetScript("OnEnter", function(self)
        if not self.kolColors then return end
        local hoverBg = {self.kolColors.bg[1] + 0.1, self.kolColors.bg[2] + 0.1, self.kolColors.bg[3] + 0.1, 1}
        local hoverBorder = {self.kolColors.border[1] + 0.15, self.kolColors.border[2] + 0.15, self.kolColors.border[3] + 0.15, 1}
        local hoverArrow = {self.kolColors.arrow[1] + 0.2, self.kolColors.arrow[2] + 0.2, self.kolColors.arrow[3] + 0.2, 1}

        if self.kolBackdrop then
            self.kolBackdrop:SetBackdropColor(unpack(hoverBg))
            self.kolBackdrop:SetBackdropBorderColor(unpack(hoverBorder))
        end
        if self.kolArrowText then
            self.kolArrowText:SetTextColor(unpack(hoverArrow))
        end
    end)

    button:SetScript("OnLeave", function(self)
        if not self.kolColors then return end
        if self.kolBackdrop then
            self.kolBackdrop:SetBackdropColor(unpack(self.kolColors.bg))
            self.kolBackdrop:SetBackdropBorderColor(unpack(self.kolColors.border))
        end
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

    -- Try multiple ways to find the scrollbar (WoW 3.3.5a compatibility)
    local scrollBar = scrollFrame.ScrollBar or scrollFrame.scrollBar
    local frameName = scrollFrame:GetName()

    -- In 3.3.5a, UIPanelScrollFrameTemplate creates scrollbar in global namespace
    if not scrollBar and frameName then
        scrollBar = _G[frameName .. "ScrollBar"]
    end

    if scrollBar then
        -- Pass the actual scrollbar name for proper lookup in SkinScrollBar
        local scrollBarName = scrollBar:GetName() or "ScrollBar"
        self:SkinScrollBar(scrollFrame, scrollBarName, colors)
        self:DebugPrint("UI: Skinned scrollbar for " .. (frameName or "unknown"), 2)
    else
        self:DebugPrint("UI: Could not find scrollbar for " .. (frameName or "unknown"), 1)
    end
end

-- ============================================================================
-- Scrollbar Registration System (for Synastria UI skinning)
-- ============================================================================
-- Ultra-performant registration system for skinning scrollbars across the UI.
-- Frames register their scrollbar patterns, and SkinRegisteredScrollBars is
-- called from the batch system to apply skins efficiently.

-- Registry of frames to skin: { frameBaseName = { patterns = {...}, lastSkinned = time } }
UIFactory.scrollbarRegistry = UIFactory.scrollbarRegistry or {}

--[[
    Register a frame's scrollbars for skinning

    Parameters:
        frameBaseName - Base name of the frame (e.g., "PerkMgrFrame")
        patterns - Table of scrollbar patterns to skin:
            {
                { slider = "PerkMgrFrame-Slider%d", upButton = "PerkMgrFrame-Slider%dScrollUpButton",
                  downButton = "PerkMgrFrame-Slider%d-ScrollDownButton", maxIndex = 5 },
            }
]]
function UIFactory:RegisterScrollBars(frameBaseName, patterns)
    self.scrollbarRegistry[frameBaseName] = {
        patterns = patterns,
        lastSkinned = 0,
    }
    KOL:DebugPrint("UIFactory: Registered scrollbars for " .. frameBaseName, 2)
end

--[[
    Skin all registered scrollbars (called from batch system)
    Extremely performant - only checks if frames exist and skins if needed

    Parameters:
        forceReskin - If true, re-skin even already-skinned scrollbars (for live settings updates)
]]
function UIFactory:SkinRegisteredScrollBars(forceReskin)
    -- Check if scrollbar skinning is enabled
    if not KOL.db or not KOL.db.profile.tweaks or not KOL.db.profile.tweaks.synastria then
        return
    end
    if not KOL.db.profile.tweaks.synastria.scrollbarSkinning then
        return
    end

    -- Get global scrollbar settings
    local scrollbarSettings = KOL.db.profile.tweaks.synastria.scrollbar or {}
    local isHidden = scrollbarSettings.hidden
    local hideUpButton = scrollbarSettings.hideUpButton
    local hideDownButton = scrollbarSettings.hideDownButton
    local width = scrollbarSettings.width or 16

    -- Build colors table from settings
    local colors = {
        width = width,
        track = {
            bg = scrollbarSettings.trackBg and {scrollbarSettings.trackBg.r, scrollbarSettings.trackBg.g, scrollbarSettings.trackBg.b, scrollbarSettings.trackBg.a},
            border = scrollbarSettings.trackBorder and {scrollbarSettings.trackBorder.r, scrollbarSettings.trackBorder.g, scrollbarSettings.trackBorder.b, scrollbarSettings.trackBorder.a},
        },
        thumb = {
            bg = scrollbarSettings.thumbBg and {scrollbarSettings.thumbBg.r, scrollbarSettings.thumbBg.g, scrollbarSettings.thumbBg.b, scrollbarSettings.thumbBg.a},
            border = scrollbarSettings.thumbBorder and {scrollbarSettings.thumbBorder.r, scrollbarSettings.thumbBorder.g, scrollbarSettings.thumbBorder.b, scrollbarSettings.thumbBorder.a},
        },
        button = {
            bg = scrollbarSettings.buttonBg and {scrollbarSettings.buttonBg.r, scrollbarSettings.buttonBg.g, scrollbarSettings.buttonBg.b, scrollbarSettings.buttonBg.a},
            border = scrollbarSettings.buttonBorder and {scrollbarSettings.buttonBorder.r, scrollbarSettings.buttonBorder.g, scrollbarSettings.buttonBorder.b, scrollbarSettings.buttonBorder.a},
            arrow = scrollbarSettings.buttonArrow and {scrollbarSettings.buttonArrow.r, scrollbarSettings.buttonArrow.g, scrollbarSettings.buttonArrow.b, scrollbarSettings.buttonArrow.a},
        },
    }

    local skinCount = 0

    for frameBaseName, regData in pairs(self.scrollbarRegistry) do
        -- Check if the base frame exists
        local baseFrame = _G[frameBaseName]
        if baseFrame then
            -- Hook OnShow to trigger skinning when the frame is shown (once per frame)
            if not regData.hooked then
                baseFrame:HookScript("OnShow", function()
                    -- Delay slightly to ensure children are created
                    C_Timer.After(0.1, function()
                        if KOL.UIFactory and KOL.UIFactory.SkinRegisteredScrollBars then
                            KOL.UIFactory:SkinRegisteredScrollBars()
                        end
                    end)
                end)
                regData.hooked = true
                KOL:DebugPrint("UIFactory: Hooked OnShow for " .. frameBaseName, 2)
            end
        end

        if baseFrame and baseFrame:IsVisible() then
            -- Process each pattern set
            for _, patternSet in ipairs(regData.patterns) do
                local maxIdx = patternSet.maxIndex or 10

                for i = 1, maxIdx do
                    -- Build the actual frame names from patterns
                    local sliderName = patternSet.slider and string.format(patternSet.slider, i)
                    local slider = sliderName and _G[sliderName]

                    if slider and (forceReskin or not slider.kolSkinned) then
                        -- Clear skinned flag if forcing reskin
                        if forceReskin then
                            slider.kolSkinned = nil
                        end

                        -- Found a slider to skin
                        local upBtnName = patternSet.upButton and string.format(patternSet.upButton, i)
                        local downBtnName = patternSet.downButton and string.format(patternSet.downButton, i)

                        -- Handle visibility
                        if isHidden then
                            slider:SetAlpha(0)
                            slider:EnableMouse(false)  -- Allow click-through
                        else
                            slider:SetAlpha(1)
                            slider:EnableMouse(true)

                            -- Create a mock parent with the scrollbar for SkinScrollBar
                            local mockParent = {}
                            mockParent[sliderName] = slider

                            -- Skin it using global colors
                            KOL:SkinScrollBar(mockParent, sliderName, colors)
                        end

                        -- Handle buttons
                        local upBtn = upBtnName and _G[upBtnName]
                        local downBtn = downBtnName and _G[downBtnName]

                        if upBtn then
                            if isHidden or hideUpButton then
                                upBtn:SetAlpha(0)
                                upBtn:EnableMouse(false)
                            else
                                upBtn:SetAlpha(1)
                                upBtn:EnableMouse(true)
                                KOL:SkinScrollButton(upBtn, "up", colors.button)
                            end
                        end
                        if downBtn then
                            if isHidden or hideDownButton then
                                downBtn:SetAlpha(0)
                                downBtn:EnableMouse(false)
                            else
                                downBtn:SetAlpha(1)
                                downBtn:EnableMouse(true)
                                KOL:SkinScrollButton(downBtn, "down", colors.button)
                            end
                        end

                        -- Apply position offset if specified (fixes scrollbars that get pushed too far)
                        if patternSet.xOffset and not slider.kolOffsetApplied then
                            local point, relativeTo, relativePoint, xOfs, yOfs = slider:GetPoint(1)
                            if point then
                                slider:ClearAllPoints()
                                slider:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + patternSet.xOffset, yOfs or 0)
                                slider.kolOffsetApplied = true
                            end
                        end

                        skinCount = skinCount + 1
                        KOL:DebugPrint("UIFactory: Skinned " .. sliderName, 3)
                    end
                end
            end

            regData.lastSkinned = GetTime()
        end
    end

    if skinCount > 0 then
        KOL:DebugPrint("UIFactory: Skinned " .. skinCount .. " scrollbars", 2)
    end
end

-- NOTE: External frame scrollbar skinning (like PerkMgrFrame) was removed
-- because it's too fragile - those frames have their own parent/anchor logic
-- that conflicts with our skinning. We only skin our own KOL scrollbars now.

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
    Creates a scrollable content area with skinned scrollbar

    Parameters:
        parent - Parent frame
        options - Table with optional settings:
            - inset: {top, bottom, left, right} insets from parent
            - showScrollbar: boolean (default: true)
            - scrollbarColor: {bg, border, thumb} colors
            - scrollbarWidth: number (default: 16) - width of scrollbar in pixels
            - hideButtons: boolean (default: false) - hide up/down buttons for minimal look
            - scrollbarInside: boolean (default: true) - position scrollbar inside content area

    Returns: contentFrame, scrollFrame
]]
function UIFactory:CreateScrollableContent(parent, options)
    options = options or {}
    local inset = options.inset or {top = 8, bottom = 8, left = 8, right = 8}
    local scrollbarWidth = options.scrollbarWidth or 16
    local scrollbarInside = options.scrollbarInside ~= false  -- Default true

    -- Create scroll frame (needs unique name for UIPanelScrollFrameTemplate in 3.3.5a)
    local scrollFrameName = "KOL_ScrollFrame_" .. tostring(math.random(100000, 999999))
    local scrollFrame = CreateFrame("ScrollFrame", scrollFrameName, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", inset.left, -inset.top)
    -- Reserve space for scrollbar on the right if inside
    local rightInset = scrollbarInside and (inset.right + scrollbarWidth + 2) or inset.right
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -rightInset, inset.bottom)

    -- Create content child
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    -- Skin scrollbar using theme colors
    if options.showScrollbar ~= false then
        local scrollbarColors

        if options.scrollbarColor then
            -- Use provided colors
            scrollbarColors = options.scrollbarColor
        elseif KOL.Themes and KOL.Themes.GetUIThemeColor then
            -- Pull from Theme system (gray fallbacks matching Furwin theme)
            local trackBG = KOL.Themes:GetUIThemeColor("ScrollbarTrackBG", {r = 0.05, g = 0.05, b = 0.05, a = 0.9})
            local trackBorder = KOL.Themes:GetUIThemeColor("ScrollbarTrackBorder", {r = 0.2, g = 0.2, b = 0.2, a = 1})
            local thumbBG = KOL.Themes:GetUIThemeColor("ScrollbarThumbBG", {r = 0.3, g = 0.3, b = 0.3, a = 1})
            local thumbBorder = KOL.Themes:GetUIThemeColor("ScrollbarThumbBorder", {r = 0.4, g = 0.4, b = 0.4, a = 1})
            local buttonBG = KOL.Themes:GetUIThemeColor("ScrollbarButtonBG", {r = 0.15, g = 0.15, b = 0.15, a = 0.9})
            local buttonBorder = KOL.Themes:GetUIThemeColor("ScrollbarButtonBorder", {r = 0.25, g = 0.25, b = 0.25, a = 1})
            local buttonArrow = KOL.Themes:GetUIThemeColor("ScrollbarButtonArrow", {r = 0.6, g = 0.6, b = 0.6, a = 1})

            scrollbarColors = {
                track = {bg = {trackBG.r, trackBG.g, trackBG.b, trackBG.a or 0.9}, border = {trackBorder.r, trackBorder.g, trackBorder.b, trackBorder.a or 1}},
                thumb = {bg = {thumbBG.r, thumbBG.g, thumbBG.b, thumbBG.a or 1}, border = {thumbBorder.r, thumbBorder.g, thumbBorder.b, thumbBorder.a or 1}},
                button = {bg = {buttonBG.r, buttonBG.g, buttonBG.b, buttonBG.a or 0.9}, border = {buttonBorder.r, buttonBorder.g, buttonBorder.b, buttonBorder.a or 1}, arrow = {buttonArrow.r, buttonArrow.g, buttonArrow.b, buttonArrow.a or 1}}
            }
        else
            -- Fallback to hardcoded defaults (gray, matching Furwin theme)
            scrollbarColors = {
                track = {bg = {0.05, 0.05, 0.05, 0.9}, border = {0.2, 0.2, 0.2, 1}},
                thumb = {bg = {0.3, 0.3, 0.3, 1}, border = {0.4, 0.4, 0.4, 1}},
                button = {bg = {0.15, 0.15, 0.15, 0.9}, border = {0.25, 0.25, 0.25, 1}, arrow = {0.6, 0.6, 0.6, 1}}
            }
        end

        -- Add width and hideButtons options to colors
        scrollbarColors.width = scrollbarWidth
        scrollbarColors.hideButtons = options.hideButtons

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
function UIFactory:OldCreateTextButton(parent, text, options)
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
-- Rainbow Animation System
-- ============================================================================

-- Rainbow colors (matches the tag rainbow)
local rainbowColors = {
    {r = 1.00, g = 0.00, b = 0.00}, -- FF0000 Red
    {r = 1.00, g = 0.27, b = 0.00}, -- FF4400
    {r = 1.00, g = 0.53, b = 0.00}, -- FF8800 Orange
    {r = 1.00, g = 0.80, b = 0.00}, -- FFCC00
    {r = 1.00, g = 1.00, b = 0.00}, -- FFFF00 Yellow
    {r = 0.80, g = 1.00, b = 0.00}, -- CCFF00
    {r = 0.53, g = 1.00, b = 0.00}, -- 88FF00 Green
    {r = 0.27, g = 1.00, b = 0.00}, -- 44FF00
    {r = 0.00, g = 1.00, b = 0.00}, -- 00FF00
    {r = 0.00, g = 1.00, b = 0.53}, -- 00FF88
    {r = 0.00, g = 1.00, b = 1.00}, -- 00FFFF Cyan
    {r = 0.33, g = 0.67, b = 1.00}, -- 55AAFF
    {r = 0.47, g = 0.60, b = 1.00}, -- 7799FF Blue
    {r = 0.53, g = 0.53, b = 1.00}, -- 8888FF
    {r = 0.67, g = 0.40, b = 1.00}, -- AA66FF Purple
}

-- Global rainbow index (shared across all rainbow animations for sync)
local globalRainbowIndex = 1

--[[
    Get the rainbow colors table
    Returns: table of {r, g, b} colors
]]
function UIFactory:GetRainbowColors()
    return rainbowColors
end

--[[
    Get the current rainbow color (for synced animations)
    Returns: {r, g, b} color table
]]
function UIFactory:GetCurrentRainbowColor()
    return rainbowColors[globalRainbowIndex]
end

--[[
    Start rainbow animation on a frame's text
    The animation cycles through rainbow colors on the provided fontstring

    Parameters:
        frame - The frame to attach the OnUpdate script to
        fontstring - The fontstring to animate
        options - Table with optional settings:
            - speed: number - Color change interval in seconds (default: 0.08)
            - borderFrame: frame - Optional frame whose border to also animate

    Returns: nothing (modifies frame in place)
]]
function UIFactory:StartRainbowAnimation(frame, fontstring, options)
    options = options or {}
    local speed = options.speed or 0.08

    frame.rainbowTimer = 0
    frame.rainbowActive = true
    frame.rainbowFontstring = fontstring
    frame.rainbowBorderFrame = options.borderFrame

    frame:SetScript("OnUpdate", function(self, elapsed)
        if not self.rainbowActive then
            self:SetScript("OnUpdate", nil)
            return
        end

        self.rainbowTimer = self.rainbowTimer + elapsed
        if self.rainbowTimer >= speed then
            self.rainbowTimer = 0
            globalRainbowIndex = globalRainbowIndex + 1
            if globalRainbowIndex > #rainbowColors then
                globalRainbowIndex = 1
            end

            local color = rainbowColors[globalRainbowIndex]
            if self.rainbowFontstring then
                self.rainbowFontstring:SetTextColor(color.r, color.g, color.b, 1)
            end
            if self.rainbowBorderFrame then
                self.rainbowBorderFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1)
            end
        end
    end)
end

--[[
    Stop rainbow animation on a frame

    Parameters:
        frame - The frame with the rainbow animation
        restoreColor - Optional {r, g, b, a} color to restore text to
        restoreBorderColor - Optional {r, g, b, a} color to restore border to
]]
function UIFactory:StopRainbowAnimation(frame, restoreColor, restoreBorderColor)
    frame.rainbowActive = false
    frame:SetScript("OnUpdate", nil)

    if restoreColor and frame.rainbowFontstring then
        frame.rainbowFontstring:SetTextColor(restoreColor.r, restoreColor.g, restoreColor.b, restoreColor.a or 1)
    end
    if restoreBorderColor and frame.rainbowBorderFrame then
        frame.rainbowBorderFrame:SetBackdropBorderColor(restoreBorderColor.r, restoreBorderColor.g, restoreBorderColor.b, restoreBorderColor.a or 1)
    end
end

-- ============================================================================
-- Animated Text Button (Text-only with rainbow hover)
-- ============================================================================

--[[
    Creates a text-only button with rainbow color animation on hover

    Parameters:
        parent - Parent frame
        text - Button text
        options - Table with optional settings:
            - textColor: {r, g, b, a} - Normal text color (default: muted gray)
            - fontSize: number - Font size (default: 12)
            - onClick: function - Click handler
            - fontObject: string - Font object name (optional)
            - rainbowSpeed: number - Rainbow animation speed (default: 0.08)

    Returns: button
]]
function UIFactory:OldCreateAnimatedTextButton(parent, text, options)
    options = options or {}

    local textColor = options.textColor or {r = 0.7, g = 0.7, b = 0.7, a = 1}
    local fontSize = options.fontSize or 12
    local rainbowSpeed = options.rainbowSpeed or 0.08

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

    -- Store colors for restore
    button.textColor = textColor

    -- Hover effects with rainbow animation
    button:SetScript("OnEnter", function(self)
        UIFactory:StartRainbowAnimation(self, self.text, {speed = rainbowSpeed})
    end)

    button:SetScript("OnLeave", function(self)
        UIFactory:StopRainbowAnimation(self, self.textColor)
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
-- Animated Border Button (Border animations on hover)
-- ============================================================================

--[[
    Creates a styled button with animated border effects on hover

    Parameters:
        parent - Parent frame
        width - Button width
        height - Button height
        text - Button text
        options - Table with optional settings:
            - borderAnimation: "fade" | "rainbow" - Animation type for border
            - textAnimation: "rainbow" - Optional, animates text in rainbow colors on hover
            - textColor: {r, g, b, a} - Text color (default state)
            - hoverTextColor: {r, g, b, a} - Text color on hover (ignored if textAnimation="rainbow")
            - pressedTextColor: {r, g, b, a} - Text color when mouse pressed
            - bgColor: {r, g, b, a} - Background color
            - hoverBgColor: {r, g, b, a} - Background color on hover
            - borderColor: {r, g, b, a} - Border color (start color for fade)
            - hoverBorderColor: {r, g, b, a} - Target border color for fade
            - fontSize: number - Font size
            - textPressEffect: boolean - Text shifts on click (defaults to true)
            - rainbowSpeed: number - Speed of rainbow animation (default 0.06)
            - fadeSpeed: number - Speed of fade animation (default 3.0)
            - onClick: function - Click handler

    Returns: button
]]
function UIFactory:OldCreateAnimatedBorderButton(parent, width, height, text, options)
    options = options or {}

    local borderAnimation = options.borderAnimation or "fade"
    local textAnimation = options.textAnimation  -- Optional: "rainbow" for rainbow text on hover
    local textColor = options.textColor or {r = 0.8, g = 0.8, b = 0.8, a = 1}
    local hoverTextColor = options.hoverTextColor or {r = 1, g = 1, b = 1, a = 1}
    local bgColor = options.bgColor or {r = 0.08, g = 0.08, b = 0.08, a = 1}
    local hoverBgColor = options.hoverBgColor or {r = 0.12, g = 0.12, b = 0.12, a = 1}
    local borderColor = options.borderColor or {r = 0.3, g = 0.3, b = 0.3, a = 1}
    local hoverBorderColor = options.hoverBorderColor or {r = 0, g = 0.8, b = 0.8, a = 1}
    local fontSize = options.fontSize or 11
    local rainbowSpeed = options.rainbowSpeed or 0.06
    local fadeSpeed = options.fadeSpeed or 3.0
    local textPressEffect = options.textPressEffect

    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    button:EnableMouse(true)

    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    button:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
    button:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)

    -- Text
    local fontPath, fontOutline = GetGeneralFont()
    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont(fontPath, fontSize, fontOutline)
    buttonText:SetPoint("CENTER", 0, 0)
    buttonText:SetText(text)
    buttonText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a or 1)
    button.text = buttonText

    -- Store state
    button.bgColor = bgColor
    button.hoverBgColor = hoverBgColor
    button.borderColor = borderColor
    button.hoverBorderColor = hoverBorderColor
    button.textColor = textColor
    button.hoverTextColor = hoverTextColor
    button.pressedTextColor = options.pressedTextColor  -- Optional: text color when mouse is pressed
    button.borderAnimation = borderAnimation
    button.textAnimation = textAnimation  -- Optional: "rainbow" for rainbow text animation
    button.isHovered = false
    button.animProgress = 0  -- 0 = normal, 1 = fully hovered
    button.textPressEffect = textPressEffect
    button.textPressed = false
    button.textRainbowIndex = 1  -- Separate index for text rainbow (can be offset from border)

    -- Rainbow colors for border (same as text rainbow)
    local rainbowColors = {
        {r = 1.00, g = 0.00, b = 0.00},
        {r = 1.00, g = 0.53, b = 0.00},
        {r = 1.00, g = 1.00, b = 0.00},
        {r = 0.00, g = 1.00, b = 0.00},
        {r = 0.00, g = 1.00, b = 1.00},
        {r = 0.47, g = 0.60, b = 1.00},
        {r = 0.67, g = 0.40, b = 1.00},
    }
    button.rainbowColors = rainbowColors
    button.rainbowIndex = 1
    button.rainbowTimer = 0
    button.rainbowSpeed = rainbowSpeed
    button.fadeSpeed = fadeSpeed

    -- OnUpdate for animations
    button:SetScript("OnUpdate", function(self, elapsed)
        if not self.isHovered then
            -- Animate back to normal state
            if self.animProgress > 0 then
                self.animProgress = math.max(0, self.animProgress - elapsed * self.fadeSpeed)
                -- Interpolate border color back to normal
                local p = self.animProgress
                local r = self.borderColor.r + (self.hoverBorderColor.r - self.borderColor.r) * p
                local g = self.borderColor.g + (self.hoverBorderColor.g - self.borderColor.g) * p
                local b = self.borderColor.b + (self.hoverBorderColor.b - self.borderColor.b) * p
                self:SetBackdropBorderColor(r, g, b, 1)
                -- Interpolate background
                local bgR = self.bgColor.r + (self.hoverBgColor.r - self.bgColor.r) * p
                local bgG = self.bgColor.g + (self.hoverBgColor.g - self.bgColor.g) * p
                local bgB = self.bgColor.b + (self.hoverBgColor.b - self.bgColor.b) * p
                self:SetBackdropColor(bgR, bgG, bgB, self.bgColor.a or 1)
            end
            return
        end

        if self.borderAnimation == "rainbow" then
            -- Rainbow border animation
            self.rainbowTimer = self.rainbowTimer + elapsed
            if self.rainbowTimer >= self.rainbowSpeed then
                self.rainbowTimer = 0
                self.rainbowIndex = self.rainbowIndex + 1
                if self.rainbowIndex > #self.rainbowColors then
                    self.rainbowIndex = 1
                end
                local color = self.rainbowColors[self.rainbowIndex]
                self:SetBackdropBorderColor(color.r, color.g, color.b, 1)

                -- Also animate text if textAnimation is rainbow (offset by 3 for contrast)
                if self.textAnimation == "rainbow" then
                    local textIdx = ((self.rainbowIndex + 2) % #self.rainbowColors) + 1
                    local textColor = self.rainbowColors[textIdx]
                    self.text:SetTextColor(textColor.r, textColor.g, textColor.b, 1)
                end
            end
        elseif self.borderAnimation == "fade" then
            -- Smooth fade to hover color
            if self.animProgress < 1 then
                self.animProgress = math.min(1, self.animProgress + elapsed * self.fadeSpeed)
                local p = self.animProgress
                local r = self.borderColor.r + (self.hoverBorderColor.r - self.borderColor.r) * p
                local g = self.borderColor.g + (self.hoverBorderColor.g - self.borderColor.g) * p
                local b = self.borderColor.b + (self.hoverBorderColor.b - self.borderColor.b) * p
                self:SetBackdropBorderColor(r, g, b, 1)
                -- Interpolate background too
                local bgR = self.bgColor.r + (self.hoverBgColor.r - self.bgColor.r) * p
                local bgG = self.bgColor.g + (self.hoverBgColor.g - self.bgColor.g) * p
                local bgB = self.bgColor.b + (self.hoverBgColor.b - self.bgColor.b) * p
                self:SetBackdropColor(bgR, bgG, bgB, self.bgColor.a or 1)
            end

            -- Text rainbow animation (works with fade border too)
            if self.textAnimation == "rainbow" then
                self.rainbowTimer = self.rainbowTimer + elapsed
                if self.rainbowTimer >= self.rainbowSpeed then
                    self.rainbowTimer = 0
                    self.textRainbowIndex = self.textRainbowIndex + 1
                    if self.textRainbowIndex > #self.rainbowColors then
                        self.textRainbowIndex = 1
                    end
                    local textColor = self.rainbowColors[self.textRainbowIndex]
                    self.text:SetTextColor(textColor.r, textColor.g, textColor.b, 1)
                end
            end
        end
    end)

    -- Hover effects
    button:SetScript("OnEnter", function(self)
        self.isHovered = true
        -- Only set hover text color if not using rainbow text animation
        if self.textAnimation ~= "rainbow" then
            self.text:SetTextColor(self.hoverTextColor.r, self.hoverTextColor.g, self.hoverTextColor.b, self.hoverTextColor.a or 1)
        end
        -- For rainbow, set background immediately
        if self.borderAnimation == "rainbow" then
            self:SetBackdropColor(self.hoverBgColor.r, self.hoverBgColor.g, self.hoverBgColor.b, self.hoverBgColor.a or 1)
        end
    end)

    button:SetScript("OnLeave", function(self)
        self.isHovered = false
        self.text:SetTextColor(self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a or 1)
        -- Reset text position if it was pressed
        if self.textPressed then
            self.text:SetPoint("CENTER", 0, 0)
            self.textPressed = false
        end
    end)

    -- Text press effect (MouseDown/MouseUp) - defaults to TRUE for animatedbutton
    local usePressEffect = textPressEffect ~= false
    if usePressEffect then
        button:SetScript("OnMouseDown", function(self)
            self.text:SetPoint("CENTER", 1, -1)
            self.textPressed = true
            -- Apply pressed text color if specified
            if self.pressedTextColor then
                self.text:SetTextColor(self.pressedTextColor.r, self.pressedTextColor.g, self.pressedTextColor.b, self.pressedTextColor.a or 1)
            end
        end)

        button:SetScript("OnMouseUp", function(self)
            self.text:SetPoint("CENTER", 0, 0)
            self.textPressed = false
            -- Restore to hover color (we're still hovering after mouse up)
            if self.pressedTextColor then
                self.text:SetTextColor(self.hoverTextColor.r, self.hoverTextColor.g, self.hoverTextColor.b, self.hoverTextColor.a or 1)
            end
        end)
    end

    -- Click handler
    if options.onClick then
        button:SetScript("OnClick", options.onClick)
    end

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

    -- Inherit strata from parent frame + offset for proper layering
    local rootFrame = self:FindRootFrame(parent)
    local dropStrata, dropLevel = self:GetDropdownStrataInfo(rootFrame or parent)
    list:SetFrameStrata(dropStrata)
    list:SetFrameLevel(dropLevel)

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

        -- Get list's frame level so we can put buttons above it
        local listLevel = list:GetFrameLevel()

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
            itemBtn:SetFrameLevel(listLevel + 1)  -- Ensure buttons are above list backdrop
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
            -- Dynamically update strata before showing (parent may have been raised)
            local rootFrame = UIFactory:FindRootFrame(self)
            local dropStrata, dropLevel = UIFactory:GetDropdownStrataInfo(rootFrame or self:GetParent())
            self.list:SetFrameStrata(dropStrata)
            self.list:SetFrameLevel(dropLevel)

            PopulateList()
            self.list:Show()
            self.isOpen = true
            self.arrow:SetText(CHAR_ARROW_UPFILLED)
        end
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
-- Action Approval Frame (Confirmation Dialog)
-- ============================================================================

--[[
    Creates a reusable confirmation dialog for dangerous/destructive actions

    Visual Layout:
        ┌────────────────────────────────────┐
        │                              [X]   │
        │     Are you sure you want to       │
        │     Reset All Settings             │  <- actionColor (cyan)
        │     for Tracker: Test Panel        │  <- contextColor (purple)
        │                                    │
        │  [✓] I understand this cannot...   │
        │                                    │
        │         [CONFIRM]  [CANCEL]        │
        └────────────────────────────────────┘

    Parameters:
        parent - Parent frame (usually UIParent)
        frameId - Unique frame name (e.g., "KOL_ResetApproval")
        options - Table with settings:
            -- Text content
            - line1: string - Question text (default: "Are you sure you want to")
            - actionName: string - The action being confirmed (required)
            - contextLine: string - Optional context (e.g., "for Tracker: Test Panel")
            - checkboxText: string - Checkbox label (default: "I understand this action cannot be undone")

            -- Button text
            - confirmText: string - Confirm button text (default: "CONFIRM")
            - cancelText: string - Cancel button text (default: "CANCEL")

            -- Colors
            - actionColor: {r,g,b,a} - Color for action name (default: cyan)
            - contextColor: {r,g,b,a} - Color for context line (default: purple)
            - confirmColor: {r,g,b,a} - Confirm button color (default: red for danger)

            -- Behavior
            - requireCheckbox: boolean - Must check to enable confirm (default: true)

            -- Callbacks
            - onConfirm: function() - Called when confirmed
            - onCancel: function() - Called when cancelled (optional)

    Returns: frame with methods:
        - frame:Show() - Show the dialog
        - frame:Hide() - Hide the dialog
        - frame:SetActionName(text) - Update action name
        - frame:SetContextLine(text) - Update context line
        - frame:SetOnConfirm(func) - Update confirm callback
        - frame:Reset() - Reset checkbox and disable confirm button

    Usage:
        local approval = UIFactory:CreateActionApprovalFrame(UIParent, "KOL_ResetApproval", {
            actionName = "Reset All Settings",
            contextLine = "for Tracker: Test Panel",
            onConfirm = function()
                -- Do the reset
                KOL:PrintTag("Settings reset!")
            end,
        })
        approval:Show()
]]
function UIFactory:CreateActionApprovalFrame(parent, frameId, options)
    options = options or {}

    -- Defaults
    local line1 = options.line1 or "Are you sure you want to"
    local actionName = options.actionName or "perform this action"
    local contextLine = options.contextLine  -- nil is ok
    local checkboxText = options.checkboxText or "I understand this action cannot be undone"
    local confirmText = options.confirmText or "CONFIRM"
    local cancelText = options.cancelText or "CANCEL"
    local actionColor = options.actionColor or {r = 0, g = 0.8, b = 0.8, a = 1}
    local contextColor = options.contextColor or {r = 0.7, g = 0.5, b = 0.9, a = 1}
    local confirmColor = options.confirmColor or {r = 0.8, g = 0.3, b = 0.3, a = 1}
    local requireCheckbox = options.requireCheckbox ~= false  -- default true
    local onConfirm = options.onConfirm
    local onCancel = options.onCancel

    -- Calculate height based on whether we have a context line
    local baseHeight = contextLine and 115 or 100

    -- Create the frame
    local frame = self:CreateStyledFrame(parent, frameId, 340, baseHeight, {
        closable = true,
        movable = true,
        -- Uses default DIALOG strata - focus system brings it to front when shown
    })
    frame:SetPoint("CENTER")
    frame:Hide()

    local fontPath, fontOutline = GetGeneralFont()
    local yOffset = -12

    -- Line 1: Question text
    local line1Text = frame:CreateFontString(nil, "OVERLAY")
    line1Text:SetFont(fontPath, 11, fontOutline)
    line1Text:SetPoint("TOP", frame, "TOP", 0, yOffset)
    line1Text:SetText(line1)
    line1Text:SetTextColor(0.9, 0.9, 0.9, 1)
    frame.line1Text = line1Text

    yOffset = yOffset - 18

    -- Line 2: Action name (colored)
    local actionText = frame:CreateFontString(nil, "OVERLAY")
    actionText:SetFont(fontPath, 12, fontOutline)
    actionText:SetPoint("TOP", frame, "TOP", 0, yOffset)
    actionText:SetText(actionName)
    actionText:SetTextColor(actionColor.r, actionColor.g, actionColor.b, actionColor.a or 1)
    frame.actionText = actionText

    yOffset = yOffset - 18

    -- Line 3: Context line (optional, colored differently)
    local contextText = nil
    if contextLine then
        contextText = frame:CreateFontString(nil, "OVERLAY")
        contextText:SetFont(fontPath, 10, fontOutline)
        contextText:SetPoint("TOP", frame, "TOP", 0, yOffset)
        contextText:SetText(contextLine)
        contextText:SetTextColor(contextColor.r, contextColor.g, contextColor.b, contextColor.a or 1)
        frame.contextText = contextText
        yOffset = yOffset - 16
    end

    yOffset = yOffset - 8

    -- Checkbox
    local checkbox = self:CreateCheckbox(frame, checkboxText, {
        checked = false,
        fontSize = 10,
        onChange = function(checked)
            if requireCheckbox then
                if checked then
                    frame.confirmBtn:Enable()
                    frame.confirmBtn:SetAlpha(1)
                else
                    frame.confirmBtn:Disable()
                    frame.confirmBtn:SetAlpha(0.5)
                end
            end
        end,
    })
    checkbox:SetPoint("TOP", frame, "TOP", 0, yOffset)
    frame.checkbox = checkbox

    -- Buttons at bottom
    local cancelBtn = self:OldCreateTextButton(frame, cancelText, {
        textColor = {r = 0.7, g = 0.7, b = 0.7, a = 1},
        hoverColor = {r = 0.9, g = 0.9, b = 0.9, a = 1},
        fontSize = 11,
        onClick = function()
            frame:Hide()
            if onCancel then
                onCancel()
            end
        end,
    })
    cancelBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 10)
    frame.cancelBtn = cancelBtn

    local confirmBtn = self:OldCreateTextButton(frame, confirmText, {
        textColor = confirmColor,
        hoverColor = {r = math.min(1, confirmColor.r + 0.2), g = math.min(1, confirmColor.g + 0.2), b = math.min(1, confirmColor.b + 0.2), a = 1},
        fontSize = 11,
        onClick = function()
            frame:Hide()
            if frame.onConfirmCallback then
                frame.onConfirmCallback()
            end
        end,
    })
    confirmBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -25, 0)
    frame.confirmBtn = confirmBtn
    frame.onConfirmCallback = onConfirm

    -- Start with confirm disabled if checkbox required
    if requireCheckbox then
        confirmBtn:Disable()
        confirmBtn:SetAlpha(0.5)
    end

    -- Store settings
    frame.actionColor = actionColor
    frame.contextColor = contextColor
    frame.requireCheckbox = requireCheckbox

    -- Helper methods

    -- Update action name text
    function frame:SetActionName(text)
        self.actionText:SetText(text)
    end

    -- Update context line (can set to nil to hide concept)
    function frame:SetContextLine(text)
        if self.contextText then
            if text then
                self.contextText:SetText(text)
                self.contextText:Show()
            else
                self.contextText:Hide()
            end
        end
    end

    -- Update confirm callback
    function frame:SetOnConfirm(func)
        self.onConfirmCallback = func
    end

    -- Reset state (uncheck checkbox, disable confirm)
    function frame:Reset()
        self.checkbox:SetChecked(false)
        if self.requireCheckbox then
            self.confirmBtn:Disable()
            self.confirmBtn:SetAlpha(0.5)
        end
    end

    -- Override Show to always reset first
    local originalShow = frame.Show
    frame.Show = function(self)
        self:Reset()
        originalShow(self)
    end

    return frame
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

    -- Inherit strata from parent frame + offset for proper layering
    local rootFrame = self:FindRootFrame(parent)
    local dropStrata, dropLevel = self:GetDropdownStrataInfo(rootFrame or parent)
    list:SetFrameStrata(dropStrata)
    list:SetFrameLevel(dropLevel)

    list:Hide()
    dropdown.list = list

    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, list)
    scrollFrame:SetPoint("TOPLEFT", 2, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
    scrollFrame:SetFrameStrata(dropStrata)
    scrollFrame:SetFrameLevel(dropLevel + 1)
    dropdown.scrollFrame = scrollFrame

    -- Create scroll child
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(width - 4)
    scrollChild:SetFrameStrata(dropStrata)
    scrollChild:SetFrameLevel(dropLevel + 2)
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

        -- Get list's frame level so we can put buttons above it
        local listLevel = list:GetFrameLevel()

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
            itemBtn:SetFrameStrata(list:GetFrameStrata())  -- Explicit strata for TOOLTIP visibility
            itemBtn:SetFrameLevel(listLevel + 3)  -- Ensure buttons are above all list elements
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
            -- Dynamically update strata before showing (parent may have been raised)
            local rootFrame = UIFactory:FindRootFrame(self)
            local dropStrata, dropLevel = UIFactory:GetDropdownStrataInfo(rootFrame or self:GetParent())
            list:SetFrameStrata(dropStrata)
            list:SetFrameLevel(dropLevel)

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

    -- Inherit strata from parent frame + offset for proper layering
    local rootFrame = self:FindRootFrame(parent)
    local dropStrata, dropLevel = self:GetDropdownStrataInfo(rootFrame or parent)
    list:SetFrameStrata(dropStrata)
    list:SetFrameLevel(dropLevel)

    list:Hide()
    dropdown.list = list

    -- Create scroll frame for the list
    local scrollFrame = CreateFrame("ScrollFrame", name and (name .. "ScrollFrame") or nil, list)
    scrollFrame:SetPoint("TOPLEFT", 2, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
    scrollFrame:SetFrameStrata(dropStrata)
    scrollFrame:SetFrameLevel(dropLevel + 1)
    dropdown.scrollFrame = scrollFrame

    -- Create scroll child (content holder)
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(width - 4)
    scrollChild:SetFrameStrata(dropStrata)
    scrollChild:SetFrameLevel(dropLevel + 2)
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

        -- Get list's frame level so we can put buttons above it
        local listLevel = list:GetFrameLevel()

        -- Create item buttons
        for i, fontName in ipairs(fonts) do
            local itemBtn = CreateFrame("Button", nil, scrollChild)
            itemBtn:SetFrameStrata(list:GetFrameStrata())  -- Explicit strata for TOOLTIP visibility
            itemBtn:SetFrameLevel(listLevel + 3)  -- Ensure buttons are above all list elements
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
            -- Dynamically update strata before showing (parent may have been raised)
            local rootFrame = UIFactory:FindRootFrame(self)
            local dropStrata, dropLevel = UIFactory:GetDropdownStrataInfo(rootFrame or self:GetParent())
            list:SetFrameStrata(dropStrata)
            list:SetFrameLevel(dropLevel)

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

-- ============================================================================
-- Styled Popup Dropdown (Clean, Reusable, Scrollable)
-- ============================================================================

-- Shared popup menu frame (only one can be open at a time)
local styledPopupMenu = nil
local styledPopupOwner = nil

local function HideStyledPopup()
    if styledPopupMenu then
        styledPopupMenu:SetScript("OnUpdate", nil)
        styledPopupMenu:Hide()
        if styledPopupOwner and styledPopupOwner.arrow then
            styledPopupOwner.arrow:SetText(CHAR_ARROW_DOWNFILLED)
        end
        styledPopupOwner = nil
    end
end

--[[
    Creates a styled dropdown with popup menu

    Features:
        - Clean, themed styling
        - Auto-scrollable when items exceed maxVisible
        - Proper toggle behavior (no race conditions)
        - Supports icons and colors per item
        - Mouse wheel scrolling
        - Closes when clicking elsewhere
        - Only one popup open at a time

    Parameters:
        parent - Parent frame
        width - Dropdown width (default: 150)
        options - Table with:
            - items: array of items, each can be:
                - string: "Label"
                - table: {value = "val", label = "Label", icon = "*", color = "|cFFFFFF00"}
            - selectedValue: initial selected value
            - onSelect: function(value, label) callback
            - placeholder: text when nothing selected (default: "Select...")
            - fontSize: number (default: 10)
            - maxVisible: max items before scrolling (default: 8)
            - itemHeight: height per item (default: 20)

    Returns: dropdown button with methods:
        - :GetValue() - returns selected value
        - :SetValue(value) - sets selected value
        - :SetItems(items) - updates item list
        - :Close() - closes popup if open
]]
function UIFactory:CreateStyledDropdown(parent, width, options)
    options = options or {}
    width = width or 150
    local height = 22
    local fontSize = options.fontSize or 10
    local maxVisible = options.maxVisible or 8
    local itemHeight = options.itemHeight or 20

    local fontPath, fontOutline = GetGeneralFont()

    -- Get theme colors
    local bgColor, borderColor, hoverBorderColor
    if KOL.Themes and KOL.Themes.GetUIThemeColor then
        bgColor = KOL.Themes:GetUIThemeColor("ContentAreaBG", {r = 0.08, g = 0.08, b = 0.08, a = 1})
        borderColor = KOL.Themes:GetUIThemeColor("ContentAreaBorder", {r = 0.3, g = 0.3, b = 0.3, a = 1})
        hoverBorderColor = KOL.Themes:GetUIThemeColor("ButtonHoverBorder", {r = 0, g = 0.6, b = 0.6, a = 1})
    else
        bgColor = {r = 0.08, g = 0.08, b = 0.08, a = 1}
        borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1}
        hoverBorderColor = {r = 0, g = 0.6, b = 0.6, a = 1}
    end

    -- Create main dropdown button
    local dropdown = CreateFrame("Button", nil, parent)
    dropdown:SetSize(width, height)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 1, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    dropdown:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
    dropdown:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)

    -- Selected text display
    local selectedText = dropdown:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont(fontPath, fontSize, fontOutline)
    selectedText:SetPoint("LEFT", 6, 0)
    selectedText:SetPoint("RIGHT", -18, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetText(options.placeholder or "Select...")
    selectedText:SetTextColor(0.9, 0.9, 0.9, 1)
    dropdown.text = selectedText
    dropdown.selectedText = selectedText  -- Alias for compatibility

    -- Arrow indicator
    local arrow = dropdown:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(CHAR_LIGATURESFONT, fontSize, CHAR_LIGATURESOUTLINE)
    arrow:SetPoint("RIGHT", -5, 0)
    arrow:SetText(CHAR_ARROW_DOWNFILLED)
    arrow:SetTextColor(0.5, 0.5, 0.5, 1)
    dropdown.arrow = arrow

    -- State
    dropdown.selectedValue = options.selectedValue
    dropdown.items = options.items or {}
    dropdown.onSelect = options.onSelect
    dropdown.bgColor = bgColor
    dropdown.borderColor = borderColor
    dropdown.hoverBorderColor = hoverBorderColor

    -- Hover effect on dropdown button
    dropdown:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(self.hoverBorderColor.r, self.hoverBorderColor.g, self.hoverBorderColor.b, 1)
        self.arrow:SetTextColor(0.8, 0.8, 0.8, 1)
    end)
    dropdown:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(self.borderColor.r, self.borderColor.g, self.borderColor.b, 1)
        self.arrow:SetTextColor(0.5, 0.5, 0.5, 1)
    end)

    -- Show popup menu function
    local function ShowPopup()
        -- Toggle: if already open for this dropdown, close it
        if styledPopupMenu and styledPopupMenu:IsShown() and styledPopupOwner == dropdown then
            HideStyledPopup()
            return
        end

        -- Close any other open popup
        HideStyledPopup()

        -- Create popup frame if needed
        if not styledPopupMenu then
            styledPopupMenu = CreateFrame("Frame", "KOL_StyledPopupMenu", UIParent)
            -- Strata will be set dynamically when popup is shown based on owner frame
            styledPopupMenu:SetFrameStrata("HIGH")
            styledPopupMenu:SetFrameLevel(100)
            styledPopupMenu:Hide()
            styledPopupMenu.buttons = {}

            -- Create a SEPARATE backdrop frame at a lower level
            -- This ensures button children render ABOVE the backdrop
            local backdropFrame = CreateFrame("Frame", nil, styledPopupMenu)
            backdropFrame:SetAllPoints()
            backdropFrame:SetFrameLevel(1)  -- Low level, buttons will be higher
            backdropFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false, tileSize = 1, edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            backdropFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.98)
            backdropFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            styledPopupMenu.backdropFrame = backdropFrame
        end

        styledPopupOwner = dropdown
        arrow:SetText(CHAR_ARROW_UPFILLED)

        -- Dynamically set strata based on the dropdown's parent frame
        local rootFrame = UIFactory:FindRootFrame(dropdown)
        local dropStrata, dropLevel = UIFactory:GetDropdownStrataInfo(rootFrame or dropdown:GetParent())
        styledPopupMenu:SetFrameStrata(dropStrata)
        styledPopupMenu:SetFrameLevel(dropLevel)

        -- Update backdrop frame level relative to popup (must be done AFTER popup level is set)
        if styledPopupMenu.backdropFrame then
            styledPopupMenu.backdropFrame:SetFrameLevel(dropLevel)  -- Same as popup base
        end

        -- Clear existing buttons
        for _, btn in ipairs(styledPopupMenu.buttons) do
            btn:Hide()
            btn:SetParent(nil)
        end
        styledPopupMenu.buttons = {}

        local items = dropdown.items
        local numItems = #items
        local visibleItems = math.min(numItems, maxVisible)
        local needsScroll = numItems > maxVisible
        local menuWidth = width
        local menuHeight = visibleItems * itemHeight + 4

        styledPopupMenu:SetSize(menuWidth, menuHeight)
        styledPopupMenu:ClearAllPoints()
        styledPopupMenu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)

        -- Create scroll frame if needed
        local scrollFrame = styledPopupMenu.scrollFrame
        local scrollChild = styledPopupMenu.scrollChild

        if not scrollFrame then
            scrollFrame = CreateFrame("ScrollFrame", nil, styledPopupMenu)
            scrollFrame:SetPoint("TOPLEFT", 2, -2)
            scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
            styledPopupMenu.scrollFrame = scrollFrame

            scrollChild = CreateFrame("Frame", nil, scrollFrame)
            scrollFrame:SetScrollChild(scrollChild)
            styledPopupMenu.scrollChild = scrollChild

            -- Mouse wheel scrolling
            scrollFrame:EnableMouseWheel(true)
            scrollFrame:SetScript("OnMouseWheel", function(self, delta)
                local current = self:GetVerticalScroll()
                local maxScroll = math.max(0, (numItems * itemHeight) - (visibleItems * itemHeight))
                local newScroll = math.max(0, math.min(maxScroll, current - (delta * itemHeight)))
                self:SetVerticalScroll(newScroll)
            end)
        end

        -- Update scroll hierarchy levels relative to popup level (MUST be done each time popup opens)
        scrollFrame:SetFrameLevel(dropLevel + 5)
        scrollChild:SetFrameLevel(dropLevel + 10)

        scrollChild:SetSize(menuWidth - 4, numItems * itemHeight)
        scrollFrame:SetVerticalScroll(0)

        -- Create item buttons
        for i, item in ipairs(items) do
            local value, label, icon, color
            if type(item) == "table" then
                value = item.value or item[1] or i
                label = item.label or item[2] or tostring(value)
                icon = item.icon
                color = item.color or ""
            else
                value = item
                label = tostring(item)
                icon = nil
                color = ""
            end

            local btn = CreateFrame("Button", nil, scrollChild)
            btn:SetFrameLevel(dropLevel + 15)  -- Above scrollChild, which is above backdrop
            btn:SetSize(menuWidth - 4, itemHeight)
            btn:SetPoint("TOPLEFT", 0, -((i - 1) * itemHeight))

            -- Icon (if provided)
            local labelOffset = 6
            if icon then
                local iconText = btn:CreateFontString(nil, "OVERLAY")
                iconText:SetFont(fontPath, fontSize, fontOutline)
                iconText:SetPoint("LEFT", 6, 0)
                iconText:SetWidth(14)
                iconText:SetJustifyH("CENTER")
                iconText:SetText(icon)
                labelOffset = 22
            end

            -- Label
            local labelText = btn:CreateFontString(nil, "OVERLAY")
            labelText:SetFont(fontPath, fontSize, fontOutline)
            labelText:SetPoint("LEFT", labelOffset, 0)
            labelText:SetPoint("RIGHT", -6, 0)
            labelText:SetJustifyH("LEFT")
            labelText:SetText(color .. label .. (color ~= "" and "|r" or ""))
            labelText:SetTextColor(0.9, 0.9, 0.9, 1)
            btn.labelText = labelText

            -- Checkmark for selected item
            if value == dropdown.selectedValue then
                local check = btn:CreateFontString(nil, "OVERLAY")
                check:SetFont(CHAR_LIGATURESFONT, fontSize - 2, CHAR_LIGATURESOUTLINE)
                check:SetPoint("RIGHT", -4, 0)
                check:SetText(CHAR_OBJECTIVE_COMPLETE)
                check:SetTextColor(0.3, 0.9, 0.3, 1)
            end

            -- Hover effect
            btn:SetScript("OnEnter", function(self)
                self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
                self:SetBackdropColor(0.2, 0.2, 0.2, 1)
            end)
            btn:SetScript("OnLeave", function(self)
                self:SetBackdrop(nil)
            end)

            -- Click to select
            btn:SetScript("OnClick", function()
                dropdown.selectedValue = value
                dropdown.text:SetText(color .. (icon and (icon .. " ") or "") .. label .. (color ~= "" and "|r" or ""))
                HideStyledPopup()
                if dropdown.onSelect then
                    dropdown.onSelect(value, label)
                end
            end)

            table.insert(styledPopupMenu.buttons, btn)
        end

        styledPopupMenu:Show()

        -- Close on click elsewhere (with delay to prevent immediate close)
        local clickDelay = 0.15
        styledPopupMenu:SetScript("OnUpdate", function(self, elapsed)
            clickDelay = clickDelay - elapsed
            if clickDelay > 0 then return end

            if not MouseIsOver(self) and not MouseIsOver(dropdown) then
                if IsMouseButtonDown("LeftButton") then
                    HideStyledPopup()
                end
            end
        end)
    end

    -- Click to toggle popup
    dropdown:SetScript("OnClick", ShowPopup)

    -- Public methods
    function dropdown:GetValue()
        return self.selectedValue
    end

    function dropdown:SetValue(value)
        self.selectedValue = value
        for _, item in ipairs(self.items) do
            local itemValue, itemLabel, itemIcon, itemColor
            if type(item) == "table" then
                itemValue = item.value or item[1]
                itemLabel = item.label or item[2] or tostring(itemValue)
                itemIcon = item.icon
                itemColor = item.color or ""
            else
                itemValue = item
                itemLabel = tostring(item)
                itemIcon = nil
                itemColor = ""
            end
            if itemValue == value then
                self.text:SetText(itemColor .. (itemIcon and (itemIcon .. " ") or "") .. itemLabel .. (itemColor ~= "" and "|r" or ""))
                return
            end
        end
    end

    function dropdown:SetItems(items)
        self.items = items or {}
    end

    function dropdown:Close()
        if styledPopupOwner == self then
            HideStyledPopup()
        end
    end

    -- Set initial value if provided
    if options.selectedValue then
        dropdown:SetValue(options.selectedValue)
    end

    return dropdown
end

-- ============================================================================
-- Consolidated Button Creator
-- ============================================================================

--[[
    UIFactory:CreateButton(parent, text, options)

    The unified button creation function - use this for all button types.

    Parameters:
        parent - Parent frame (the WoW frame this button attaches to)
        text - Button text label
        options - Table with settings:
            - type: "styled" | "text" | "animated" | "animatedtext" | "animatedbutton" (default: "styled")
                - "styled": Standard button with background and border
                - "text": Text-only button (link style)
                - "animated" / "animatedtext": Text button with rainbow text on hover
                - "animatedbutton": Styled button with animated border effects
            - width: number - Button width (required for styled/animatedbutton, auto for text types)
            - height: number - Button height (required for styled/animatedbutton, auto for text types)
            - textColor: {r, g, b, a} - Default text color
            - hoverColor: {r, g, b, a} - Hover text color (for text/styled types)
            - hoverTextColor: {r, g, b, a} - Hover text color (for animatedbutton)
            - pressedTextColor: {r, g, b, a} - Text color when mouse pressed (styled/animatedbutton)
            - bgColor: {r, g, b, a} - Background color (styled/animatedbutton)
            - hoverBgColor: {r, g, b, a} - Hover background color (styled/animatedbutton)
            - borderColor: {r, g, b, a} - Border color (styled/animatedbutton)
            - hoverBorderColor: {r, g, b, a} - Hover border color (styled/animatedbutton)
            - borderAnimation: "fade" | "rainbow" - Border animation type (animatedbutton only)
            - textAnimation: "rainbow" - Text animation on hover (animatedbutton only)
            - fontSize: number - Font size (default: 11-12)
            - rainbowSpeed: number - Rainbow animation speed (default: 0.06-0.08)
            - fadeSpeed: number - Fade animation speed (animatedbutton only, default: 3.0)
            - textPressEffect: boolean - Text shifts on click (styled/animatedbutton, defaults TRUE)
            - onClick: function - Click handler
            - disabled: boolean - Start disabled

    Returns: button frame
]]
function UIFactory:CreateButton(parent, text, options)
    options = options or {}
    local buttonType = options.type or "styled"

    -- Route to appropriate creator based on type
    if buttonType == "text" then
        return self:OldCreateTextButton(parent, text, {
            textColor = options.textColor,
            hoverColor = options.hoverColor,
            fontSize = options.fontSize,
            onClick = options.onClick,
        })

    elseif buttonType == "animated" or buttonType == "animatedtext" then
        -- "animated" is kept for backwards compatibility, "animatedtext" is the new name
        return self:OldCreateAnimatedTextButton(parent, text, {
            textColor = options.textColor,
            fontSize = options.fontSize,
            onClick = options.onClick,
            rainbowSpeed = options.rainbowSpeed,
        })

    elseif buttonType == "animatedbutton" then
        -- Animated border button with fade or rainbow border effects
        return self:OldCreateAnimatedBorderButton(parent, options.width or 100, options.height or 28, text, {
            borderAnimation = options.borderAnimation or "fade",
            textAnimation = options.textAnimation,  -- Optional: "rainbow" for rainbow text on hover
            textColor = options.textColor,
            hoverTextColor = options.hoverTextColor,
            pressedTextColor = options.pressedTextColor,  -- Text color when pressed
            bgColor = options.bgColor,
            hoverBgColor = options.hoverBgColor,
            borderColor = options.borderColor,
            hoverBorderColor = options.hoverBorderColor,
            fontSize = options.fontSize,
            textPressEffect = options.textPressEffect,
            rainbowSpeed = options.rainbowSpeed,
            fadeSpeed = options.fadeSpeed,
            onClick = options.onClick,
        })

    else -- "styled" (default)
        -- Create styled button with full theming
        local width = options.width or 100
        local height = options.height or 28
        local fontSize = options.fontSize or 11

        local textColor = options.textColor or {r = 1, g = 1, b = 1, a = 1}
        local hoverColor = options.hoverColor or {r = 1, g = 1, b = 1, a = 1}

        -- Theme-aware colors
        local bgColor, borderColor
        if not options.bgColor and KOL.Themes and KOL.Themes.GetUIThemeColor then
            bgColor = KOL.Themes:GetUIThemeColor("ButtonBG", {r = 0.08, g = 0.08, b = 0.08, a = 1})
            borderColor = KOL.Themes:GetUIThemeColor("ButtonBorder", {r = 0.3, g = 0.3, b = 0.3, a = 1})
        else
            bgColor = options.bgColor or {r = 0.08, g = 0.08, b = 0.08, a = 1}
            borderColor = options.borderColor or {r = 0.3, g = 0.3, b = 0.3, a = 1}
        end

        local hoverBgColor = options.hoverBgColor or {r = bgColor.r + 0.05, g = bgColor.g + 0.05, b = bgColor.b + 0.05, a = 1}
        local hoverBorderColor = options.hoverBorderColor or {r = 0, g = 0.8, b = 0.8, a = 1}

        local button = CreateFrame("Button", nil, parent)
        button:SetSize(width, height)
        button:EnableMouse(true)

        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            tileSize = 1,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        button:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
        button:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)

        -- Text
        local fontPath, fontOutline = GetGeneralFont()
        local buttonText = button:CreateFontString(nil, "OVERLAY")
        buttonText:SetFont(fontPath, fontSize, fontOutline)
        buttonText:SetPoint("CENTER")
        buttonText:SetText(text)
        buttonText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a or 1)
        button.text = buttonText

        -- Store colors
        button.bgColor = bgColor
        button.borderColor = borderColor
        button.hoverBgColor = hoverBgColor
        button.hoverBorderColor = hoverBorderColor
        button.textColor = textColor
        button.hoverTextColor = hoverColor
        button.pressedTextColor = options.pressedTextColor  -- Optional: text color when mouse is pressed

        -- Hover effects
        button:SetScript("OnEnter", function(self)
            if not self.disabled then
                self:SetBackdropColor(self.hoverBgColor.r, self.hoverBgColor.g, self.hoverBgColor.b, self.hoverBgColor.a or 1)
                self:SetBackdropBorderColor(self.hoverBorderColor.r, self.hoverBorderColor.g, self.hoverBorderColor.b, self.hoverBorderColor.a or 1)
                self.text:SetTextColor(self.hoverTextColor.r, self.hoverTextColor.g, self.hoverTextColor.b, self.hoverTextColor.a or 1)
            end
        end)

        button:SetScript("OnLeave", function(self)
            self:SetBackdropColor(self.bgColor.r, self.bgColor.g, self.bgColor.b, self.bgColor.a or 1)
            self:SetBackdropBorderColor(self.borderColor.r, self.borderColor.g, self.borderColor.b, self.borderColor.a or 1)
            self.text:SetTextColor(self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a or 1)
            -- Reset text position if it was pressed
            if self.textPressed then
                self.text:SetPoint("CENTER", 0, 0)
                self.textPressed = false
            end
        end)

        -- Text press effect (MouseDown/MouseUp) - defaults to TRUE
        local usePressEffect = options.textPressEffect ~= false  -- Only false if explicitly set to false
        button.textPressEffect = usePressEffect
        button.textPressed = false
        if usePressEffect then
            button:SetScript("OnMouseDown", function(self)
                if not self.disabled then
                    self.text:SetPoint("CENTER", 1, -1)
                    self.textPressed = true
                    -- Apply pressed text color if specified
                    if self.pressedTextColor then
                        self.text:SetTextColor(self.pressedTextColor.r, self.pressedTextColor.g, self.pressedTextColor.b, self.pressedTextColor.a or 1)
                    end
                end
            end)

            button:SetScript("OnMouseUp", function(self)
                self.text:SetPoint("CENTER", 0, 0)
                self.textPressed = false
                -- Restore to hover color (we're still hovering after mouse up)
                if self.pressedTextColor then
                    self.text:SetTextColor(self.hoverTextColor.r, self.hoverTextColor.g, self.hoverTextColor.b, self.hoverTextColor.a or 1)
                end
            end)
        end

        -- Click handler
        if options.onClick then
            button:SetScript("OnClick", function(self)
                if not self.disabled then
                    options.onClick(self)
                end
            end)
        end

        -- Disabled state helper
        button.disabled = options.disabled or false
        function button:SetDisabled(disabled)
            self.disabled = disabled
            if disabled then
                self:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
                self:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
                self.text:SetTextColor(0.4, 0.4, 0.4, 1)
            else
                self:SetBackdropColor(self.bgColor.r, self.bgColor.g, self.bgColor.b, self.bgColor.a or 1)
                self:SetBackdropBorderColor(self.borderColor.r, self.borderColor.g, self.borderColor.b, self.borderColor.a or 1)
                self.text:SetTextColor(self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a or 1)
            end
        end

        return button
    end
end

-- ============================================================================
-- UI Showcase Frame (/kc showcase)
-- ============================================================================

local uiShowcaseFrame = nil

function UIFactory:ShowUIShowcase()
    if uiShowcaseFrame then
        uiShowcaseFrame:Show()
        uiShowcaseFrame:Raise()
        return uiShowcaseFrame
    end

    -- Create showcase frame (fixed size)
    local frame = self:CreateStyledFrame(UIParent, "KOL_UIShowcase", 520, 500, {
        movable = true,
        closable = true,
        strata = UIFactory.STRATA.IMPORTANT,  -- DIALOG strata for important windows
    })
    frame:SetPoint("CENTER")

    local fontPath, fontOutline = GetGeneralFont()

    -- Title (outside scroll area)
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontPath, 14, fontOutline)
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText("UIFactory Showcase")
    title:SetTextColor(0, 0.9, 0.9, 1)

    -- Subtitle
    local subtitle = frame:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(fontPath, 10, fontOutline)
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
    subtitle:SetText("Buttons, Checkboxes, Edit Boxes, Dropdowns, Font Pickers")
    subtitle:SetTextColor(0.6, 0.6, 0.6, 1)

    -- Close button at bottom (outside scroll area)
    local closeBtn = self:CreateButton(frame, "Close Showcase", {
        type = "animated",
        textColor = {r = 0.7, g = 0.7, b = 0.7, a = 1},
        fontSize = 11,
        onClick = function() frame:Hide() end
    })
    closeBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)

    -- Create scroll frame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 35)
    scrollFrame:EnableMouseWheel(true)

    -- Content frame (this holds all the buttons)
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(scrollFrame:GetWidth() - 10)
    content:SetHeight(600)  -- Will be resized after adding content
    scrollFrame:SetScrollChild(content)

    -- Scrollbar
    local scrollBar = CreateFrame("Slider", nil, frame)
    scrollBar:SetWidth(12)
    scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -50)
    scrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 35)
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetMinMaxValues(0, 1)
    scrollBar:SetValue(0)
    scrollBar:SetValueStep(20)

    -- Scrollbar track background
    scrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    scrollBar:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    scrollBar:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -- Scrollbar thumb
    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetVertexColor(0.3, 0.3, 0.3, 1)
    thumb:SetWidth(10)
    thumb:SetHeight(40)
    scrollBar:SetThumbTexture(thumb)

    -- Mouse wheel scrolling
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        local min, max = scrollBar:GetMinMaxValues()
        local step = 30
        if delta > 0 then
            scrollBar:SetValue(math.max(min, current - step))
        else
            scrollBar:SetValue(math.min(max, current + step))
        end
    end)

    -- Scrollbar value changed
    scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)

    -- Now create content on the content frame
    local yOffset = -5

    -- ========================================
    -- Section 1: Styled Buttons
    -- ========================================
    local section1 = content:CreateFontString(nil, "OVERLAY")
    section1:SetFont(fontPath, 11, fontOutline)
    section1:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section1:SetText("type = \"styled\" (with border/background)")
    section1:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

    -- Default styled button
    local btn1 = self:CreateButton(content, "Default Styled", {
        type = "styled",
        width = 110,
        height = 26,
        onClick = function() KOL:PrintTag("Clicked: Default Styled") end
    })
    btn1:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)

    -- Custom colors styled button
    local btn2 = self:CreateButton(content, "Green Theme", {
        type = "styled",
        width = 100,
        height = 26,
        bgColor = {r = 0.1, g = 0.2, b = 0.1, a = 1},
        borderColor = {r = 0.2, g = 0.5, b = 0.2, a = 1},
        hoverBorderColor = {r = 0.3, g = 0.9, b = 0.3, a = 1},
        textColor = {r = 0.6, g = 0.9, b = 0.6, a = 1},
        onClick = function() KOL:PrintTag("Clicked: Green Theme") end
    })
    btn2:SetPoint("LEFT", btn1, "RIGHT", 10, 0)

    -- Red warning button
    local btn3 = self:CreateButton(content, "Red Warning", {
        type = "styled",
        width = 100,
        height = 26,
        bgColor = {r = 0.25, g = 0.08, b = 0.08, a = 1},
        borderColor = {r = 0.5, g = 0.15, b = 0.15, a = 1},
        hoverBorderColor = {r = 0.9, g = 0.2, b = 0.2, a = 1},
        textColor = {r = 1, g = 0.5, b = 0.5, a = 1},
        onClick = function() KOL:PrintTag("Clicked: Red Warning") end
    })
    btn3:SetPoint("LEFT", btn2, "RIGHT", 10, 0)

    -- Disabled button
    local btn4 = self:CreateButton(content, "Disabled", {
        type = "styled",
        width = 80,
        height = 26,
        disabled = true,
    })
    btn4:SetPoint("LEFT", btn3, "RIGHT", 10, 0)

    yOffset = yOffset - 40

    -- ========================================
    -- Section 2: Text Buttons
    -- ========================================
    local section2 = content:CreateFontString(nil, "OVERLAY")
    section2:SetFont(fontPath, 11, fontOutline)
    section2:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section2:SetText("type = \"text\" (no border, simple hover)")
    section2:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

    -- Default text button
    local txtBtn1 = self:CreateButton(content, "Default Text", {
        type = "text",
        onClick = function() KOL:PrintTag("Clicked: Default Text") end
    })
    txtBtn1:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)

    -- Cyan hover text button
    local txtBtn2 = self:CreateButton(content, "Cyan Hover", {
        type = "text",
        textColor = {r = 0.7, g = 0.7, b = 0.7, a = 1},
        hoverColor = {r = 0, g = 0.9, b = 0.9, a = 1},
        onClick = function() KOL:PrintTag("Clicked: Cyan Hover") end
    })
    txtBtn2:SetPoint("LEFT", txtBtn1, "RIGHT", 20, 0)

    -- Green text button
    local txtBtn3 = self:CreateButton(content, "Green Link", {
        type = "text",
        textColor = {r = 0.4, g = 0.8, b = 0.4, a = 1},
        hoverColor = {r = 0.6, g = 1, b = 0.6, a = 1},
        onClick = function() KOL:PrintTag("Clicked: Green Link") end
    })
    txtBtn3:SetPoint("LEFT", txtBtn2, "RIGHT", 20, 0)

    -- Large text button
    local txtBtn4 = self:CreateButton(content, "Large Font", {
        type = "text",
        fontSize = 14,
        textColor = {r = 0.9, g = 0.6, b = 0.3, a = 1},
        hoverColor = {r = 1, g = 0.8, b = 0.4, a = 1},
        onClick = function() KOL:PrintTag("Clicked: Large Font") end
    })
    txtBtn4:SetPoint("LEFT", txtBtn3, "RIGHT", 20, 0)

    yOffset = yOffset - 40

    -- ========================================
    -- Section 3: Animated Text Buttons
    -- ========================================
    local section3 = content:CreateFontString(nil, "OVERLAY")
    section3:SetFont(fontPath, 11, fontOutline)
    section3:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section3:SetText("type = \"animated\" (rainbow hover)")
    section3:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

    -- Default animated button
    local animBtn1 = self:CreateButton(content, "Rainbow Hover", {
        type = "animated",
        onClick = function() KOL:PrintTag("Clicked: Rainbow Hover") end
    })
    animBtn1:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)

    -- Green start animated button
    local animBtn2 = self:CreateButton(content, "Green Start", {
        type = "animated",
        textColor = {r = 0.5, g = 0.9, b = 0.5, a = 1},
        onClick = function() KOL:PrintTag("Clicked: Green Start") end
    })
    animBtn2:SetPoint("LEFT", animBtn1, "RIGHT", 20, 0)

    -- Slow rainbow
    local animBtn3 = self:CreateButton(content, "Slow Rainbow", {
        type = "animated",
        rainbowSpeed = 0.15,
        onClick = function() KOL:PrintTag("Clicked: Slow Rainbow") end
    })
    animBtn3:SetPoint("LEFT", animBtn2, "RIGHT", 20, 0)

    -- Fast rainbow
    local animBtn4 = self:CreateButton(content, "Fast Rainbow", {
        type = "animated",
        rainbowSpeed = 0.04,
        onClick = function() KOL:PrintTag("Clicked: Fast Rainbow") end
    })
    animBtn4:SetPoint("LEFT", animBtn3, "RIGHT", 20, 0)

    yOffset = yOffset - 40

    -- ========================================
    -- Section 4: Font Sizes Comparison
    -- ========================================
    local section4 = content:CreateFontString(nil, "OVERLAY")
    section4:SetFont(fontPath, 11, fontOutline)
    section4:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section4:SetText("Font Size Comparison (animated type)")
    section4:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

    local sizes = {9, 10, 11, 12, 14}
    local lastBtn = nil
    for _, size in ipairs(sizes) do
        local sizeBtn = self:CreateButton(content, "Size " .. size, {
            type = "animated",
            fontSize = size,
            onClick = function() KOL:PrintTag("Clicked: Size " .. size) end
        })
        if lastBtn then
            sizeBtn:SetPoint("LEFT", lastBtn, "RIGHT", 15, 0)
        else
            sizeBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
        end
        lastBtn = sizeBtn
    end

    yOffset = yOffset - 45

    -- ========================================
    -- Section 5: Practical Examples
    -- ========================================
    local section5 = content:CreateFontString(nil, "OVERLAY")
    section5:SetFont(fontPath, 11, fontOutline)
    section5:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section5:SetText("Practical Examples")
    section5:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

    -- Save/Cancel row (like tracker-editor)
    local exampleLabel1 = content:CreateFontString(nil, "OVERLAY")
    exampleLabel1:SetFont(fontPath, 10, fontOutline)
    exampleLabel1:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    exampleLabel1:SetText("Form Actions:")
    exampleLabel1:SetTextColor(0.6, 0.6, 0.6, 1)

    local saveEx = self:CreateButton(content, "Save", {
        type = "animated",
        textColor = {r = 0.5, g = 0.9, b = 0.5, a = 1},
        fontSize = 11,
        onClick = function() KOL:PrintTag("Save clicked!") end
    })
    saveEx:SetPoint("LEFT", exampleLabel1, "RIGHT", 15, 0)

    local cancelEx = self:CreateButton(content, "Cancel", {
        type = "animated",
        textColor = {r = 0.7, g = 0.7, b = 0.7, a = 1},
        fontSize = 11,
        onClick = function() KOL:PrintTag("Cancel clicked!") end
    })
    cancelEx:SetPoint("LEFT", saveEx, "RIGHT", 15, 0)

    yOffset = yOffset - 30

    -- Action buttons row
    local exampleLabel2 = content:CreateFontString(nil, "OVERLAY")
    exampleLabel2:SetFont(fontPath, 10, fontOutline)
    exampleLabel2:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    exampleLabel2:SetText("Action Bar:")
    exampleLabel2:SetTextColor(0.6, 0.6, 0.6, 1)

    local showEx = self:CreateButton(content, "Show", {
        type = "styled",
        width = 60,
        height = 24,
        onClick = function() KOL:PrintTag("Show clicked!") end
    })
    showEx:SetPoint("LEFT", exampleLabel2, "RIGHT", 15, 0)

    local hideEx = self:CreateButton(content, "Hide", {
        type = "styled",
        width = 60,
        height = 24,
        onClick = function() KOL:PrintTag("Hide clicked!") end
    })
    hideEx:SetPoint("LEFT", showEx, "RIGHT", 8, 0)

    local resetEx = self:CreateButton(content, "Reset", {
        type = "styled",
        width = 60,
        height = 24,
        bgColor = {r = 0.2, g = 0.1, b = 0.1, a = 1},
        borderColor = {r = 0.4, g = 0.2, b = 0.2, a = 1},
        hoverBorderColor = {r = 0.8, g = 0.3, b = 0.3, a = 1},
        onClick = function() KOL:PrintTag("Reset clicked!") end
    })
    resetEx:SetPoint("LEFT", hideEx, "RIGHT", 8, 0)

    yOffset = yOffset - 35

    -- Link-style navigation
    local exampleLabel3 = content:CreateFontString(nil, "OVERLAY")
    exampleLabel3:SetFont(fontPath, 10, fontOutline)
    exampleLabel3:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    exampleLabel3:SetText("Navigation:")
    exampleLabel3:SetTextColor(0.6, 0.6, 0.6, 1)

    local navItems = {"Home", "Settings", "Profile", "Help"}
    local lastNavBtn = exampleLabel3
    for _, navText in ipairs(navItems) do
        local navBtn = self:CreateButton(content, navText, {
            type = "text",
            fontSize = 10,
            textColor = {r = 0.5, g = 0.7, b = 0.9, a = 1},
            hoverColor = {r = 0.7, g = 0.9, b = 1, a = 1},
            onClick = function() KOL:PrintTag(navText .. " clicked!") end
        })
        navBtn:SetPoint("LEFT", lastNavBtn, "RIGHT", 12, 0)
        lastNavBtn = navBtn
    end

    yOffset = yOffset - 40

    -- ========================================
    -- Section 6: Animated Border Buttons (NEW)
    -- ========================================
    local section6 = content:CreateFontString(nil, "OVERLAY")
    section6:SetFont(fontPath, 11, fontOutline)
    section6:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section6:SetText("Animated Border Buttons (type=animatedbutton)")
    section6:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

    -- Row 1: Fade animation variants
    local fadeLabel = content:CreateFontString(nil, "OVERLAY")
    fadeLabel:SetFont(fontPath, 10, fontOutline)
    fadeLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    fadeLabel:SetText("Fade Border:")
    fadeLabel:SetTextColor(0.6, 0.6, 0.6, 1)

    local fadeCyan = self:CreateButton(content, "Cyan Fade", {
        type = "animatedbutton",
        borderAnimation = "fade",
        width = 85,
        height = 26,
        borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1},
        hoverBorderColor = {r = 0, g = 0.9, b = 0.9, a = 1},
        onClick = function() KOL:PrintTag("Cyan Fade clicked!") end
    })
    fadeCyan:SetPoint("LEFT", fadeLabel, "RIGHT", 15, 0)

    local fadeGreen = self:CreateButton(content, "Green Fade", {
        type = "animatedbutton",
        borderAnimation = "fade",
        width = 85,
        height = 26,
        borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1},
        hoverBorderColor = {r = 0.3, g = 0.9, b = 0.3, a = 1},
        onClick = function() KOL:PrintTag("Green Fade clicked!") end
    })
    fadeGreen:SetPoint("LEFT", fadeCyan, "RIGHT", 8, 0)

    local fadeRed = self:CreateButton(content, "Red Fade", {
        type = "animatedbutton",
        borderAnimation = "fade",
        width = 85,
        height = 26,
        borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1},
        hoverBorderColor = {r = 0.9, g = 0.3, b = 0.3, a = 1},
        bgColor = {r = 0.15, g = 0.08, b = 0.08, a = 1},
        hoverBgColor = {r = 0.2, g = 0.1, b = 0.1, a = 1},
        onClick = function() KOL:PrintTag("Red Fade clicked!") end
    })
    fadeRed:SetPoint("LEFT", fadeGreen, "RIGHT", 8, 0)

    yOffset = yOffset - 32

    -- Row 2: Rainbow border
    local rainbowLabel = content:CreateFontString(nil, "OVERLAY")
    rainbowLabel:SetFont(fontPath, 10, fontOutline)
    rainbowLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    rainbowLabel:SetText("Rainbow Border:")
    rainbowLabel:SetTextColor(0.6, 0.6, 0.6, 1)

    local rainbowBtn = self:CreateButton(content, "Rainbow!", {
        type = "animatedbutton",
        borderAnimation = "rainbow",
        width = 90,
        height = 26,
        onClick = function() KOL:PrintTag("Rainbow border clicked!") end
    })
    rainbowBtn:SetPoint("LEFT", rainbowLabel, "RIGHT", 15, 0)

    local rainbowFast = self:CreateButton(content, "Fast Rainbow", {
        type = "animatedbutton",
        borderAnimation = "rainbow",
        width = 100,
        height = 26,
        rainbowSpeed = 0.03,
        onClick = function() KOL:PrintTag("Fast Rainbow clicked!") end
    })
    rainbowFast:SetPoint("LEFT", rainbowBtn, "RIGHT", 8, 0)

    local rainbowFull = self:CreateButton(content, "Full Rainbow", {
        type = "animatedbutton",
        borderAnimation = "rainbow",
        textAnimation = "rainbow",
        width = 105,
        height = 26,
        rainbowSpeed = 0.04,
        onClick = function() KOL:PrintTag("Full Rainbow clicked!") end
    })
    rainbowFull:SetPoint("LEFT", rainbowFast, "RIGHT", 8, 0)

    yOffset = yOffset - 32

    -- Row 3: Text Press Effect on styled buttons
    local pressLabel = content:CreateFontString(nil, "OVERLAY")
    pressLabel:SetFont(fontPath, 10, fontOutline)
    pressLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    pressLabel:SetText("Press Effect:")
    pressLabel:SetTextColor(0.6, 0.6, 0.6, 1)

    local pressBtn = self:CreateButton(content, "Default (On)", {
        type = "styled",
        width = 95,
        height = 26,
        onClick = function() KOL:PrintTag("Press effect button clicked!") end
    })
    pressBtn:SetPoint("LEFT", pressLabel, "RIGHT", 15, 0)

    local noPressBtn = self:CreateButton(content, "Disabled", {
        type = "styled",
        width = 85,
        height = 26,
        textPressEffect = false,
        onClick = function() KOL:PrintTag("No press effect clicked!") end
    })
    noPressBtn:SetPoint("LEFT", pressBtn, "RIGHT", 8, 0)

    yOffset = yOffset - 45

    -- ========================================
    -- Section 7: Checkboxes
    -- ========================================
    local section7 = content:CreateFontString(nil, "OVERLAY")
    section7:SetFont(fontPath, 11, fontOutline)
    section7:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section7:SetText("Checkboxes (CreateCheckbox)")
    section7:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

    local check1 = self:CreateCheckbox(content, "Default Checkbox", {
        checked = false,
        onChange = function(checked) KOL:PrintTag("Default: " .. tostring(checked)) end
    })
    check1:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)

    local check2 = self:CreateCheckbox(content, "Checked", {
        checked = true,
        onChange = function(checked) KOL:PrintTag("Checked: " .. tostring(checked)) end
    })
    check2:SetPoint("LEFT", check1, "RIGHT", 20, 0)

    local check3 = self:CreateCheckbox(content, "Green Check", {
        checked = true,
        checkColor = {r = 0.3, g = 0.9, b = 0.3, a = 1},
        onChange = function(checked) KOL:PrintTag("Green: " .. tostring(checked)) end
    })
    check3:SetPoint("LEFT", check2, "RIGHT", 20, 0)

    local check4 = self:CreateCheckbox(content, "Gold Check", {
        checked = true,
        checkColor = {r = 0.9, g = 0.7, b = 0.2, a = 1},
        onChange = function(checked) KOL:PrintTag("Gold: " .. tostring(checked)) end
    })
    check4:SetPoint("LEFT", check3, "RIGHT", 20, 0)

    yOffset = yOffset - 35

    -- ========================================
    -- Section 8: Edit Boxes
    -- ========================================
    local section8 = content:CreateFontString(nil, "OVERLAY")
    section8:SetFont(fontPath, 11, fontOutline)
    section8:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section8:SetText("Edit Boxes (CreateEditBox)")
    section8:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

    local editLabel1 = content:CreateFontString(nil, "OVERLAY")
    editLabel1:SetFont(fontPath, 10, fontOutline)
    editLabel1:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    editLabel1:SetText("Default:")
    editLabel1:SetTextColor(0.6, 0.6, 0.6, 1)

    local edit1 = self:CreateEditBox(content, 120, 24, {
        placeholder = "Type here..."
    })
    edit1:SetPoint("LEFT", editLabel1, "RIGHT", 10, 0)

    local editLabel2 = content:CreateFontString(nil, "OVERLAY")
    editLabel2:SetFont(fontPath, 10, fontOutline)
    editLabel2:SetPoint("LEFT", edit1, "RIGHT", 15, 0)
    editLabel2:SetText("Wide:")
    editLabel2:SetTextColor(0.6, 0.6, 0.6, 1)

    local edit2 = self:CreateEditBox(content, 180, 24, {
        placeholder = "Wider input field..."
    })
    edit2:SetPoint("LEFT", editLabel2, "RIGHT", 10, 0)

    yOffset = yOffset - 35

    -- ========================================
    -- Section 9: Dropdowns
    -- ========================================
    local section9 = content:CreateFontString(nil, "OVERLAY")
    section9:SetFont(fontPath, 11, fontOutline)
    section9:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section9:SetText("Dropdowns (CreateDropdown)")
    section9:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

    local dropLabel1 = content:CreateFontString(nil, "OVERLAY")
    dropLabel1:SetFont(fontPath, 10, fontOutline)
    dropLabel1:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    dropLabel1:SetText("Basic:")
    dropLabel1:SetTextColor(0.6, 0.6, 0.6, 1)

    local dropdown1 = self:CreateDropdown(content, 130, {
        placeholder = "Select option...",
        items = {
            {value = "opt1", label = "Option 1"},
            {value = "opt2", label = "Option 2"},
            {value = "opt3", label = "Option 3"},
        },
        onSelect = function(value, label) KOL:PrintTag("Selected: " .. label) end
    })
    dropdown1:SetPoint("LEFT", dropLabel1, "RIGHT", 10, 0)

    local dropLabel2 = content:CreateFontString(nil, "OVERLAY")
    dropLabel2:SetFont(fontPath, 10, fontOutline)
    dropLabel2:SetPoint("LEFT", dropdown1, "RIGHT", 15, 0)
    dropLabel2:SetText("Colors:")
    dropLabel2:SetTextColor(0.6, 0.6, 0.6, 1)

    local dropdown2 = self:CreateDropdown(content, 130, {
        placeholder = "Pick a color...",
        items = {
            {value = "red", label = "Red", color = {r = 1, g = 0.4, b = 0.4}},
            {value = "green", label = "Green", color = {r = 0.4, g = 1, b = 0.4}},
            {value = "blue", label = "Blue", color = {r = 0.4, g = 0.6, b = 1}},
            {value = "gold", label = "Gold", color = {r = 1, g = 0.8, b = 0.2}},
        },
        onSelect = function(value, label) KOL:PrintTag("Color: " .. label) end
    })
    dropdown2:SetPoint("LEFT", dropLabel2, "RIGHT", 10, 0)

    yOffset = yOffset - 35

    -- ========================================
    -- Section 10: Scrollable Dropdown
    -- ========================================
    local section10 = content:CreateFontString(nil, "OVERLAY")
    section10:SetFont(fontPath, 11, fontOutline)
    section10:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section10:SetText("Scrollable Dropdown (CreateScrollableDropdown)")
    section10:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

    local scrollDropLabel = content:CreateFontString(nil, "OVERLAY")
    scrollDropLabel:SetFont(fontPath, 10, fontOutline)
    scrollDropLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    scrollDropLabel:SetText("Many Items:")
    scrollDropLabel:SetTextColor(0.6, 0.6, 0.6, 1)

    -- Generate many items for scrollable dropdown
    local manyItems = {}
    for i = 1, 20 do
        table.insert(manyItems, {value = "item" .. i, label = "Item " .. i})
    end

    local scrollDrop = self:CreateScrollableDropdown(content, 150, {
        placeholder = "Scroll to see more...",
        items = manyItems,
        onSelect = function(value, label) KOL:PrintTag("Scrollable: " .. label) end
    })
    scrollDrop:SetPoint("LEFT", scrollDropLabel, "RIGHT", 10, 0)

    yOffset = yOffset - 35

    -- ========================================
    -- Section 11: Font Picker
    -- ========================================
    local section11 = content:CreateFontString(nil, "OVERLAY")
    section11:SetFont(fontPath, 11, fontOutline)
    section11:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section11:SetText("Font Picker (CreateFontChoiceDropdown)")
    section11:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

    local fontPickerLabel = content:CreateFontString(nil, "OVERLAY")
    fontPickerLabel:SetFont(fontPath, 10, fontOutline)
    fontPickerLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    fontPickerLabel:SetText("Font Preview:")
    fontPickerLabel:SetTextColor(0.6, 0.6, 0.6, 1)

    local fontPicker = self:CreateFontChoiceDropdown(content, nil, nil, 200, function(fontPath, fontName)
        KOL:PrintTag("Font selected: " .. fontName)
    end)
    fontPicker:SetPoint("LEFT", fontPickerLabel, "RIGHT", 10, 0)

    yOffset = yOffset - 50

    -- Set final content height based on yOffset
    local contentHeight = math.abs(yOffset) + 20
    content:SetHeight(contentHeight)

    -- Update scrollbar max value
    local scrollMax = math.max(0, contentHeight - scrollFrame:GetHeight())
    scrollBar:SetMinMaxValues(0, scrollMax)

    uiShowcaseFrame = frame
    frame:Show()

    KOL:PrintTag("UI Showcase opened - /kc showcase")
    return frame
end

function UIFactory:HideUIShowcase()
    if uiShowcaseFrame then
        uiShowcaseFrame:Hide()
    end
end

-- ============================================================================
-- Font Outline Dropdown
-- ============================================================================
--[[
    Creates a styled dropdown specifically for font outline/style selection.
    Shows all valid WoW font flags with preview text in each style.

    Parameters:
        parent - Parent frame
        width - Dropdown width (default 150)
        options - Table with:
            - selectedValue: Currently selected outline value
            - onSelect: Callback function(value, label)
            - fontSize: Font size for dropdown text (default 11)
            - showPreview: Show outline preview in dropdown items (default true)

    Returns: dropdown with :GetValue(), :SetValue(value), :SetItems() methods

    Available outline values:
        "" - None (no outline)
        "OUTLINE" - Thin outline
        "THICKOUTLINE" - Thick outline
        "MONOCHROME" - Sharp (no antialiasing)
        "OUTLINE, MONOCHROME" - Thin outline + sharp
        "THICKOUTLINE, MONOCHROME" - Thick outline + sharp
]]
function UIFactory:CreateFontOutlineDropdown(parent, width, options)
    options = options or {}
    width = width or 150
    local height = 22
    local fontSize = options.fontSize or 11
    local showPreview = options.showPreview ~= false  -- Default true

    local fontPath, _ = GetGeneralFont()  -- Get font path but we'll use our own outline

    -- Get theme colors
    local bgColor, borderColor, hoverBorderColor
    if KOL.Themes and KOL.Themes.GetUIThemeColor then
        bgColor = KOL.Themes:GetUIThemeColor("ContentAreaBG", {r = 0.08, g = 0.08, b = 0.08, a = 1})
        borderColor = KOL.Themes:GetUIThemeColor("ContentAreaBorder", {r = 0.3, g = 0.3, b = 0.3, a = 1})
        hoverBorderColor = KOL.Themes:GetUIThemeColor("ButtonHoverBorder", {r = 0, g = 0.6, b = 0.6, a = 1})
    else
        bgColor = {r = 0.08, g = 0.08, b = 0.08, a = 1}
        borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1}
        hoverBorderColor = {r = 0, g = 0.6, b = 0.6, a = 1}
    end

    -- Define all valid font outline options
    local outlineOptions = {
        { value = "", label = "NONE" },
        { value = "OUTLINE", label = "OUTLINE" },
        { value = "THICKOUTLINE", label = "THICKOUTLINE" },
        { value = "MONOCHROME", label = "MONOCHROME" },
        { value = "OUTLINE, MONOCHROME", label = "OUTLINE + MONO" },
        { value = "THICKOUTLINE, MONOCHROME", label = "THICKOUTLINE + MONO" },
    }

    -- Create main dropdown button
    local dropdown = CreateFrame("Button", nil, parent)
    dropdown:SetSize(width, height)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 1, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    dropdown:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
    dropdown:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)

    -- Selected text display
    local selectedText = dropdown:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont(fontPath, fontSize, options.selectedValue or "OUTLINE")
    selectedText:SetPoint("LEFT", 6, 0)
    selectedText:SetPoint("RIGHT", -18, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetText("Select Style...")
    selectedText:SetTextColor(0.9, 0.9, 0.9, 1)
    dropdown.text = selectedText
    dropdown.selectedText = selectedText

    -- Arrow indicator
    local arrow = dropdown:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(CHAR_LIGATURESFONT, fontSize, CHAR_LIGATURESOUTLINE)
    arrow:SetPoint("RIGHT", -5, 0)
    arrow:SetText(CHAR_ARROW_DOWNFILLED)
    arrow:SetTextColor(0.5, 0.5, 0.5, 1)
    dropdown.arrow = arrow

    -- State
    dropdown.selectedValue = options.selectedValue
    dropdown.items = outlineOptions
    dropdown.onSelect = options.onSelect
    dropdown.bgColor = bgColor
    dropdown.borderColor = borderColor
    dropdown.hoverBorderColor = hoverBorderColor
    dropdown.fontPath = fontPath
    dropdown.fontSize = fontSize
    dropdown.showPreview = showPreview

    -- Set initial display text
    if dropdown.selectedValue then
        for _, item in ipairs(outlineOptions) do
            if item.value == dropdown.selectedValue then
                selectedText:SetText(item.label)
                if showPreview then
                    selectedText:SetFont(fontPath, fontSize, item.value)
                end
                break
            end
        end
    end

    -- Hover effect
    dropdown:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(self.hoverBorderColor.r, self.hoverBorderColor.g, self.hoverBorderColor.b, 1)
        self.arrow:SetTextColor(0.8, 0.8, 0.8, 1)
    end)
    dropdown:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(self.borderColor.r, self.borderColor.g, self.borderColor.b, 1)
        self.arrow:SetTextColor(0.5, 0.5, 0.5, 1)
    end)

    -- Create dropdown list (parented to UIParent for proper layering)
    local list = CreateFrame("Frame", nil, UIParent)
    list:SetWidth(width)
    list:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, tileSize = 1, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    list:SetBackdropColor(0.05, 0.05, 0.05, 0.98)
    list:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, 1)
    list:SetFrameStrata("TOOLTIP")
    list:SetFrameLevel(100)
    list:Hide()
    dropdown.list = list

    -- Position list below dropdown
    local function PositionList()
        list:ClearAllPoints()
        list:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    end

    dropdown.itemButtons = {}

    -- Function to populate list items
    local function PopulateList()
        local itemHeight = 22
        local items = dropdown.items

        -- Clear existing buttons
        for _, btn in ipairs(dropdown.itemButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
        dropdown.itemButtons = {}

        local listHeight = (#items * itemHeight) + 4
        list:SetHeight(listHeight)

        for i, item in ipairs(items) do
            local itemBtn = CreateFrame("Button", nil, list)
            itemBtn:SetSize(width - 4, itemHeight)
            itemBtn:SetPoint("TOPLEFT", 2, -((i - 1) * itemHeight) - 2)

            local itemText = itemBtn:CreateFontString(nil, "OVERLAY")
            -- Show preview of the outline style if enabled
            if dropdown.showPreview then
                itemText:SetFont(dropdown.fontPath, dropdown.fontSize, item.value)
            else
                itemText:SetFont(dropdown.fontPath, dropdown.fontSize, "OUTLINE")
            end
            itemText:SetPoint("LEFT", 6, 0)
            itemText:SetText(item.label)
            itemText:SetTextColor(0.9, 0.9, 0.9, 1)

            itemBtn.value = item.value
            itemBtn.label = item.label
            itemBtn.itemText = itemText

            -- Hover effect
            itemBtn:SetScript("OnEnter", function(self)
                self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
                self:SetBackdropColor(0.2, 0.2, 0.2, 1)
                self.itemText:SetTextColor(0.2, 1, 0.8, 1)
            end)

            itemBtn:SetScript("OnLeave", function(self)
                self:SetBackdrop(nil)
                self.itemText:SetTextColor(0.9, 0.9, 0.9, 1)
            end)

            -- Click to select
            itemBtn:SetScript("OnClick", function(self)
                dropdown.selectedValue = self.value
                dropdown.selectedText:SetText(self.label)
                if dropdown.showPreview then
                    dropdown.selectedText:SetFont(dropdown.fontPath, dropdown.fontSize, self.value)
                end
                list:Hide()
                dropdown.isOpen = false
                dropdown.arrow:SetText(CHAR_ARROW_DOWNFILLED)

                if dropdown.onSelect then
                    dropdown.onSelect(self.value, self.label)
                end
            end)

            table.insert(dropdown.itemButtons, itemBtn)
        end
    end

    -- Toggle dropdown
    dropdown:SetScript("OnClick", function(self)
        if self.isOpen then
            self.list:Hide()
            self.isOpen = false
            self.arrow:SetText(CHAR_ARROW_DOWNFILLED)
        else
            -- Dynamically update strata before showing (parent may have been raised)
            local rootFrame = UIFactory:FindRootFrame(self)
            local dropStrata, dropLevel = UIFactory:GetDropdownStrataInfo(rootFrame or self:GetParent())
            self.list:SetFrameStrata(dropStrata)
            self.list:SetFrameLevel(dropLevel)

            PositionList()
            PopulateList()
            self.list:Show()
            self.isOpen = true
            self.arrow:SetText(CHAR_ARROW_UPFILLED)
        end
    end)

    -- Close when clicking elsewhere
    list:SetScript("OnUpdate", function(self)
        if dropdown.isOpen and not self:IsMouseOver() and not dropdown:IsMouseOver() then
            if IsMouseButtonDown("LeftButton") then
                self:Hide()
                dropdown.isOpen = false
                dropdown.arrow:SetText(CHAR_ARROW_DOWNFILLED)
            end
        end
    end)

    -- Helper methods
    function dropdown:GetValue()
        return self.selectedValue
    end

    function dropdown:SetValue(value)
        self.selectedValue = value
        for _, item in ipairs(self.items) do
            if item.value == value then
                self.selectedText:SetText(item.label)
                if self.showPreview then
                    self.selectedText:SetFont(self.fontPath, self.fontSize, value)
                end
                return
            end
        end
        -- If value not found, show as-is
        self.selectedText:SetText(value == "" and "NONE" or value)
    end

    function dropdown:Close()
        if self.isOpen then
            self.list:Hide()
            self.isOpen = false
            self.arrow:SetText(CHAR_ARROW_DOWNFILLED)
        end
    end

    return dropdown
end

-- ============================================================================
-- AceConfig Tree Panel Helpers
-- ============================================================================
-- These functions make it easy to create tree-style config panels
-- (like ElvUI's nested selector panels) using AceConfig's childGroups = "tree"
--
-- Usage:
--   -- Create a tree panel
--   local treePanel = UIFactory:CreateTreePanel({
--       name = "|cFF00CCFFSynastria|r",
--       order = 0.5,
--   })
--
--   -- Add sections to it
--   UIFactory:AddTreeSection(treePanel.args, "changes", {
--       name = "CHANGES",
--       headerColor = "1,0.3,0.3",  -- RGB for styled header
--       desc = "Server-specific changes and tweaks",
--       order = 1,
--   })
--
--   -- Then add options to the section
--   treePanel.args.changes.args.myOption = { type = "toggle", ... }
-- ============================================================================

--[[
    Creates a tree-style config panel structure for AceConfig

    Parameters:
        config.name - Display name (can include color codes)
        config.order - Order in parent (default: 1)
        config.desc - Optional description

    Returns:
        AceConfig group table with childGroups = "tree"
]]
function UIFactory:CreateTreePanel(config)
    config = config or {}

    return {
        type = "group",
        name = config.name or "Tree Panel",
        order = config.order or 1,
        desc = config.desc,
        childGroups = "tree",
        args = {}
    }
end

--[[
    Adds a section to a tree panel with a styled header

    Parameters:
        treeArgs - The .args table of the tree panel
        sectionKey - Unique key for this section (e.g., "changes", "uiFactory")
        config.name - Section name (will be used for tree item AND styled header)
        config.headerColor - RGB string for styled header (e.g., "1,0.3,0.3")
        config.desc - Optional description shown below header
        config.order - Order in tree (default: 1)
        config.args - Optional pre-defined args to include

    Returns:
        The created section group (for chaining or further modification)
]]
function UIFactory:AddTreeSection(treeArgs, sectionKey, config)
    config = config or {}

    local sectionName = config.name or sectionKey
    local headerColor = config.headerColor or "0.8,0.8,0.8"

    -- Create the section group
    local section = {
        type = "group",
        name = sectionName,
        order = config.order or 1,
        args = {}
    }

    -- Add styled header at the top
    section.args.header = {
        type = "description",
        name = sectionName:upper() .. "|" .. headerColor,
        dialogControl = "KOL_SectionHeader",
        width = "full",
        order = 0,
    }

    -- Add description if provided
    if config.desc then
        section.args.desc = {
            type = "description",
            name = "|cFFAAAAAA" .. config.desc .. "|r\n",
            fontSize = "small",
            width = "full",
            order = 0.1,
        }
    end

    -- Copy any pre-defined args
    if config.args then
        for key, value in pairs(config.args) do
            section.args[key] = value
        end
    end

    -- Add to tree
    treeArgs[sectionKey] = section

    return section
end

--[[
    Helper to add a toggle option to a section

    Parameters:
        sectionArgs - The .args table of the section
        key - Option key
        config.name - Display name
        config.desc - Tooltip description
        config.order - Order (default: 10)
        config.width - Width (default: "full")
        config.get - Getter function
        config.set - Setter function
]]
function UIFactory:AddTreeToggle(sectionArgs, key, config)
    config = config or {}

    sectionArgs[key] = {
        type = "toggle",
        name = config.name or key,
        desc = config.desc,
        order = config.order or 10,
        width = config.width or "full",
        get = config.get,
        set = config.set,
        hidden = config.hidden,
        disabled = config.disabled,
    }
end

--[[
    Helper to add a range/slider option to a section

    Parameters:
        sectionArgs - The .args table of the section
        key - Option key
        config.name - Display name
        config.desc - Tooltip description
        config.min, config.max, config.step - Range settings
        config.order - Order (default: 10)
        config.width - Width (default: 1.2)
        config.get - Getter function
        config.set - Setter function
]]
function UIFactory:AddTreeRange(sectionArgs, key, config)
    config = config or {}

    sectionArgs[key] = {
        type = "range",
        name = config.name or key,
        desc = config.desc,
        min = config.min or 0,
        max = config.max or 100,
        step = config.step or 1,
        order = config.order or 10,
        width = config.width or 1.2,
        get = config.get,
        set = config.set,
        hidden = config.hidden,
        disabled = config.disabled,
    }
end

--[[
    Helper to add a color picker option to a section

    Parameters:
        sectionArgs - The .args table of the section
        key - Option key
        config.name - Display name
        config.desc - Tooltip description
        config.hasAlpha - Include alpha channel (default: true)
        config.order - Order (default: 10)
        config.width - Width (default: 0.6)
        config.get - Getter function (should return r,g,b,a)
        config.set - Setter function (receives _, r,g,b,a)
]]
function UIFactory:AddTreeColor(sectionArgs, key, config)
    config = config or {}

    sectionArgs[key] = {
        type = "color",
        name = config.name or key,
        desc = config.desc,
        hasAlpha = config.hasAlpha ~= false,  -- default true
        order = config.order or 10,
        width = config.width or 0.6,
        get = config.get,
        set = config.set,
        hidden = config.hidden,
        disabled = config.disabled,
    }
end

--[[
    Helper to add an inline group (for grouping related options)

    Parameters:
        sectionArgs - The .args table of the section
        key - Group key
        config.name - Group title
        config.order - Order (default: 10)
        config.hidden - Hidden function

    Returns:
        The args table of the new group (add options to this)
]]
function UIFactory:AddTreeGroup(sectionArgs, key, config)
    config = config or {}

    sectionArgs[key] = {
        type = "group",
        name = config.name or key,
        inline = true,
        order = config.order or 10,
        hidden = config.hidden,
        args = {},
    }

    return sectionArgs[key].args
end

KOL:DebugPrint("UI Factory loaded with enhanced components", 1)
