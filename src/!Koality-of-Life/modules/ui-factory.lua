local KOL = KoalityOfLife
local LSM = LibStub("LibSharedMedia-3.0")

KOL.UIFactory = {}
local UIFactory = KOL.UIFactory
local Colors = KOL.Colors

local function GetGeneralFont()
    if not KOL.db or not KOL.db.profile then
        return LSM:Fetch("font", "Friz Quadrata TT"), "THICKOUTLINE"
    end
    local fontName = KOL.db.profile.generalFont or "Friz Quadrata TT"
    local fontOutline = KOL.db.profile.generalFontOutline or "THICKOUTLINE"
    local fontPath = LSM:Fetch("font", fontName)
    return fontPath, fontOutline
end

UIFactory.GetGeneralFont = GetGeneralFont

local function ColorToHex(color)
    if type(color) == "string" then
        local cleaned = color
        if cleaned:match("^|c[Ff][Ff]") then
            cleaned = cleaned:sub(5)
        end
        if #cleaned < 6 then
            cleaned = cleaned .. string.rep("0", 6 - #cleaned)
        end
        return cleaned:sub(1, 6)
    elseif type(color) == "table" then
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

function UIFactory:FormatGlyph(char, color)
    if not char or char == "" then return "" end
    local hex = color and ColorToHex(color) or "FFFFFF"
    return "|cFF" .. hex .. char .. "|r"
end

function UIFactory:CreateGlyph(parent, char, color, size, drawLayer)
    if not parent then return nil end

    size = size or 10
    drawLayer = drawLayer or "OVERLAY"

    local fs = parent:CreateFontString(nil, drawLayer)
    fs:SetFont(CHAR_LIGATURESFONT, size, CHAR_LIGATURESOUTLINE or "OUTLINE")

    if char and char ~= "" then
        fs:SetText(self:FormatGlyph(char, color))
    end

    fs.glyphChar = char
    fs.glyphColor = color
    fs.glyphSize = size

    fs.SetGlyph = function(self, newChar, newColor)
        self.glyphChar = newChar or self.glyphChar
        self.glyphColor = newColor or self.glyphColor
        self:SetText(UIFactory:FormatGlyph(self.glyphChar, self.glyphColor))
    end

    return fs
end

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

    fs.glyphChar = char
    fs.glyphColor = color
    fs.glyphHoverColor = hoverColor
    fs.glyphSize = size
    fs.isHovering = false
    fs.animationType = animate
    fs.animSpeed = animSpeed
    fs.animFrame = nil

    fs.SetGlyph = function(self, newChar, newColor)
        self.glyphChar = newChar or self.glyphChar
        self.glyphColor = newColor or self.glyphColor
        if not self.isHovering or not self.glyphHoverColor then
            self:SetText(UIFactory:FormatGlyph(self.glyphChar, self.glyphColor))
        end
    end

    fs.SetHoverColor = function(self, newHoverColor)
        self.glyphHoverColor = newHoverColor
    end

    fs.StartAnimation = function(self, animType)
        self.animationType = animType or self.animationType
        if self.animationType == "none" then return end

        if not self.animFrame then
            self.animFrame = CreateFrame("Frame", nil, parent)
        end

        local elapsed = 0
        self.animFrame:SetScript("OnUpdate", function(frame, delta)
            elapsed = elapsed + delta
            local t = (elapsed % self.animSpeed) / self.animSpeed

            if self.animationType == "rainbow" then
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

    fs.StopAnimation = function(self)
        if self.animFrame then
            self.animFrame:SetScript("OnUpdate", nil)
            self.animFrame:Hide()
        end
        self:SetText(UIFactory:FormatGlyph(self.glyphChar, self.glyphColor))
    end

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

    if animate ~= "none" then
        fs:StartAnimation(animate)
    end

    return fs
end

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

-- Simple slot-based system: each frame gets a home level, active frame goes high
-- WoW automatically handles child frame levels - no recursion needed!
UIFactory.HOME_LEVEL = 100
UIFactory.ACTIVE_LEVEL = 500
UIFactory.nextHomeLevel = 100

UIFactory.frameRegistry = {}
UIFactory.activeFrame = nil

UIFactory.KOL_STRATA = "DIALOG"
UIFactory.STRATA = {
    NORMAL = "DIALOG",
    IMPORTANT = "DIALOG",
    MODAL = "FULLSCREEN_DIALOG",
}

function UIFactory:RegisterFrame(frame, strata)
    if not frame then return end

    strata = strata or self.STRATA.NORMAL

    local homeLevel = self.nextHomeLevel
    self.nextHomeLevel = self.nextHomeLevel + 10

    frame:SetFrameStrata(strata)
    frame:SetFrameLevel(homeLevel)
    frame.kolStrata = strata
    frame.kolHomeLevel = homeLevel
    frame.kolRegistered = true

    self.frameRegistry[frame] = true

    return homeLevel
end

function UIFactory:UnregisterFrame(frame)
    if not frame or not frame.kolRegistered then return end

    if self.activeFrame == frame then
        self.activeFrame = nil
    end

    self.frameRegistry[frame] = nil
    frame.kolRegistered = false
    frame.kolHomeLevel = nil
end

function UIFactory:RaiseFrame(frame)
    if not frame or not frame.kolRegistered then return end

    if self.activeFrame == frame then
        return
    end

    if self.activeFrame and self.activeFrame.kolRegistered and self.activeFrame.kolHomeLevel then
        self.activeFrame:SetFrameLevel(self.activeFrame.kolHomeLevel)
    end

    frame:SetFrameLevel(self.ACTIVE_LEVEL)
    self.activeFrame = frame

    if frame.SetToplevel then
        frame:SetToplevel(true)
    end
end

function UIFactory:GetFrameStrataInfo(frame)
    if frame then
        return frame:GetFrameStrata(), frame:GetFrameLevel()
    end
    return self.STRATA.NORMAL, 100
end

function UIFactory:GetDropdownStrataInfo(parentFrame)
    -- Use TOOLTIP strata to guarantee dropdown lists render above all other frames
    return "TOOLTIP", 100
end

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

function UIFactory:CreateStyledFrame(parent, name, width, height, options)
    options = options or {}
    parent = parent or UIParent

    local frame = CreateFrame("Frame", name, parent)

    if width then frame:SetWidth(width) end
    if height then frame:SetHeight(height) end

    local strata = options.strata or self.STRATA.NORMAL

    if not options.noRegister then
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
        frame:SetFrameStrata(strata)
        frame:SetFrameLevel(options.level or 1)
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })

    local bgColor, borderColor

    if not options.OverrideTheme then
        if KOL.Themes and KOL.Themes.GetUIThemeColor then
            bgColor = options.bgColor or KOL.Themes:GetUIThemeColor("GlobalBG", {r = 0.02, g = 0.02, b = 0.02, a = 0.98})
            borderColor = options.borderColor or KOL.Themes:GetUIThemeColor("GlobalBorder", {r = 0.4, g = 0.4, b = 0.4, a = 1})
        else
            bgColor = options.bgColor or {r = 0.02, g = 0.02, b = 0.02, a = 0.98}
            borderColor = options.borderColor or {r = 0.4, g = 0.4, b = 0.4, a = 1}
        end
    else
        bgColor = options.bgColor or {r = 0.02, g = 0.02, b = 0.02, a = 0.98}
        borderColor = options.borderColor or {r = 0.4, g = 0.4, b = 0.4, a = 1}
    end

    frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    frame:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

    frame:SetScript("OnShow", function(self)
        UIFactory:RaiseFrame(self)
    end)

    frame:SetScript("OnHide", function(self)
        if UIFactory.activeFrame == self then
            UIFactory.activeFrame = nil
            if self.kolHomeLevel then
                self:SetFrameLevel(self.kolHomeLevel)
            end
        end
    end)

    if options.movable then
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    end

    frame:HookScript("OnMouseDown", function(self)
        UIFactory:RaiseFrame(self)
    end)

    if options.closable then
        local closeButton = CreateFrame("Button", nil, frame)
        closeButton:SetSize(14, 14)
        closeButton:SetPoint("TOPRIGHT", -4, -4)

        local closeText = closeButton:CreateFontString(nil, "OVERLAY")
        closeText:SetFont(CHAR_LIGATURESFONT, 11, CHAR_LIGATURESOUTLINE)
        closeText:SetPoint("CENTER", 0, 0)
        closeText:SetText(CHAR_CLOSE)
        closeText:SetTextColor(0.5, 0.5, 0.5, 1)
        closeButton.text = closeText

        closeButton:SetScript("OnEnter", function(self)
            self.text:SetTextColor(1, 0.3, 0.3, 1)
        end)
        closeButton:SetScript("OnLeave", function(self)
            self.text:SetTextColor(0.5, 0.5, 0.5, 1)
        end)
        closeButton:SetScript("OnClick", function()
            frame:Hide()
        end)

        frame.closeButton = closeButton

        if name then
            tinsert(UISpecialFrames, name)
        end
    end

    return frame
end

function UIFactory:OldCreateTextButton(parent, text, options)
    options = options or {}

    local fontPath, fontOutline = GetGeneralFont()
    local fontSize = options.fontSize or 11
    local textColor = options.textColor or {r = 0.7, g = 0.7, b = 0.7, a = 1}
    local hoverColor = options.hoverColor or {r = 1, g = 1, b = 1, a = 1}

    local button = CreateFrame("Button", nil, parent)
    button:EnableMouse(true)

    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont(fontPath, fontSize, fontOutline)
    buttonText:SetPoint("CENTER")
    buttonText:SetText(text)
    buttonText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a or 1)
    button.text = buttonText

    local textWidth = buttonText:GetStringWidth()
    button:SetSize(textWidth + 4, fontSize + 6)

    button.textColor = textColor
    button.hoverColor = hoverColor

    button:SetScript("OnEnter", function(self)
        self.text:SetTextColor(self.hoverColor.r, self.hoverColor.g, self.hoverColor.b, self.hoverColor.a or 1)
    end)

    button:SetScript("OnLeave", function(self)
        self.text:SetTextColor(self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a or 1)
    end)

    if options.onClick then
        button:SetScript("OnClick", options.onClick)
    end

    return button
end

function UIFactory:OldCreateAnimatedTextButton(parent, text, options)
    options = options or {}

    local fontPath, fontOutline = GetGeneralFont()
    local fontSize = options.fontSize or 11
    local textColor = options.textColor or {r = 0.7, g = 0.7, b = 0.7, a = 1}
    local rainbowSpeed = options.rainbowSpeed or 0.06

    local button = CreateFrame("Button", nil, parent)
    button:EnableMouse(true)

    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont(fontPath, fontSize, fontOutline)
    buttonText:SetPoint("CENTER")
    buttonText:SetText(text)
    buttonText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a or 1)
    button.text = buttonText

    local textWidth = buttonText:GetStringWidth()
    button:SetSize(textWidth + 4, fontSize + 6)

    button.textColor = textColor
    button.rainbowSpeed = rainbowSpeed
    button.hue = 0
    button.isHovering = false

    button:SetScript("OnEnter", function(self)
        self.isHovering = true
        self.hue = 0
    end)

    button:SetScript("OnLeave", function(self)
        self.isHovering = false
        self.text:SetTextColor(self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a or 1)
    end)

    button:SetScript("OnUpdate", function(self, elapsed)
        if self.isHovering then
            self.hue = (self.hue + elapsed * (1 / self.rainbowSpeed)) % 1
            local r, g, b = self:HSVToRGB(self.hue, 0.8, 1)
            self.text:SetTextColor(r, g, b, 1)
        end
    end)

    function button:HSVToRGB(h, s, v)
        local r, g, b
        local i = math.floor(h * 6)
        local f = h * 6 - i
        local p = v * (1 - s)
        local q = v * (1 - f * s)
        local t = v * (1 - (1 - f) * s)
        i = i % 6
        if i == 0 then r, g, b = v, t, p
        elseif i == 1 then r, g, b = q, v, p
        elseif i == 2 then r, g, b = p, v, t
        elseif i == 3 then r, g, b = p, q, v
        elseif i == 4 then r, g, b = t, p, v
        elseif i == 5 then r, g, b = v, p, q
        end
        return r, g, b
    end

    if options.onClick then
        button:SetScript("OnClick", options.onClick)
    end

    return button
end

function UIFactory:OldCreateAnimatedBorderButton(parent, width, height, text, options)
    options = options or {}

    local borderAnimation = options.borderAnimation or "fade"
    local textAnimation = options.textAnimation
    local fontSize = options.fontSize or 11
    local textColor = options.textColor or {r = 0.9, g = 0.9, b = 0.9, a = 1}
    local hoverTextColor = options.hoverTextColor or {r = 1, g = 1, b = 1, a = 1}
    local pressedTextColor = options.pressedTextColor
    local rainbowSpeed = options.rainbowSpeed or 0.08
    local fadeSpeed = options.fadeSpeed or 3.0
    local usePressEffect = options.textPressEffect ~= false

    local bgColor, borderColor, hoverBorderColor
    if not options.bgColor and KOL.Themes and KOL.Themes.GetUIThemeColor then
        bgColor = KOL.Themes:GetUIThemeColor("ButtonBG", {r = 0.08, g = 0.08, b = 0.08, a = 1})
        borderColor = options.borderColor or KOL.Themes:GetUIThemeColor("ButtonBorder", {r = 0.3, g = 0.3, b = 0.3, a = 1})
    else
        bgColor = options.bgColor or {r = 0.08, g = 0.08, b = 0.08, a = 1}
        borderColor = options.borderColor or {r = 0.3, g = 0.3, b = 0.3, a = 1}
    end
    local hoverBgColor = options.hoverBgColor or {r = bgColor.r + 0.03, g = bgColor.g + 0.03, b = bgColor.b + 0.03, a = 1}
    hoverBorderColor = options.hoverBorderColor or {r = 0, g = 0.8, b = 0.8, a = 1}

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

    local fontPath, fontOutline = GetGeneralFont()
    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont(fontPath, fontSize, fontOutline)
    buttonText:SetPoint("CENTER")
    buttonText:SetText(text)
    buttonText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a or 1)
    button.text = buttonText

    button.bgColor = bgColor
    button.borderColor = borderColor
    button.hoverBgColor = hoverBgColor
    button.hoverBorderColor = hoverBorderColor
    button.textColor = textColor
    button.hoverTextColor = hoverTextColor
    button.pressedTextColor = pressedTextColor
    button.borderAnimation = borderAnimation
    button.textAnimation = textAnimation
    button.rainbowSpeed = rainbowSpeed
    button.fadeSpeed = fadeSpeed
    button.textPressEffect = usePressEffect
    button.textPressed = false
    button.isHovering = false
    button.hue = 0
    button.fadeDirection = 1
    button.fadeProgress = 0

    function button:HSVToRGB(h, s, v)
        local r, g, b
        local i = math.floor(h * 6)
        local f = h * 6 - i
        local p = v * (1 - s)
        local q = v * (1 - f * s)
        local t = v * (1 - (1 - f) * s)
        i = i % 6
        if i == 0 then r, g, b = v, t, p
        elseif i == 1 then r, g, b = q, v, p
        elseif i == 2 then r, g, b = p, v, t
        elseif i == 3 then r, g, b = p, q, v
        elseif i == 4 then r, g, b = t, p, v
        elseif i == 5 then r, g, b = v, p, q
        end
        return r, g, b
    end

    button:SetScript("OnEnter", function(self)
        self.isHovering = true
        self.hue = 0
        self.fadeProgress = 0
        self.fadeDirection = 1
        self:SetBackdropColor(self.hoverBgColor.r, self.hoverBgColor.g, self.hoverBgColor.b, self.hoverBgColor.a or 1)
        if not self.textAnimation then
            self.text:SetTextColor(self.hoverTextColor.r, self.hoverTextColor.g, self.hoverTextColor.b, self.hoverTextColor.a or 1)
        end
    end)

    button:SetScript("OnLeave", function(self)
        self.isHovering = false
        self:SetBackdropColor(self.bgColor.r, self.bgColor.g, self.bgColor.b, self.bgColor.a or 1)
        self:SetBackdropBorderColor(self.borderColor.r, self.borderColor.g, self.borderColor.b, self.borderColor.a or 1)
        self.text:SetTextColor(self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a or 1)
        if self.textPressed then
            self.text:SetPoint("CENTER", 0, 0)
            self.textPressed = false
        end
    end)

    button:SetScript("OnUpdate", function(self, elapsed)
        if self.isHovering then
            if self.borderAnimation == "rainbow" then
                self.hue = (self.hue + elapsed * (1 / self.rainbowSpeed)) % 1
                local r, g, b = self:HSVToRGB(self.hue, 0.8, 1)
                self:SetBackdropBorderColor(r, g, b, 1)
            elseif self.borderAnimation == "fade" then
                self.fadeProgress = self.fadeProgress + (elapsed * self.fadeSpeed * self.fadeDirection)
                if self.fadeProgress >= 1 then
                    self.fadeProgress = 1
                    self.fadeDirection = -1
                elseif self.fadeProgress <= 0 then
                    self.fadeProgress = 0
                    self.fadeDirection = 1
                end
                local r = self.borderColor.r + (self.hoverBorderColor.r - self.borderColor.r) * self.fadeProgress
                local g = self.borderColor.g + (self.hoverBorderColor.g - self.borderColor.g) * self.fadeProgress
                local b = self.borderColor.b + (self.hoverBorderColor.b - self.borderColor.b) * self.fadeProgress
                self:SetBackdropBorderColor(r, g, b, 1)
            end

            if self.textAnimation == "rainbow" and not self.textPressed then
                local textHue = (self.hue + 0.5) % 1
                local r, g, b = self:HSVToRGB(textHue, 0.7, 1)
                self.text:SetTextColor(r, g, b, 1)
            end
        end
    end)

    if usePressEffect then
        button:SetScript("OnMouseDown", function(self)
            self.text:SetPoint("CENTER", 1, -1)
            self.textPressed = true
            if self.pressedTextColor then
                self.text:SetTextColor(self.pressedTextColor.r, self.pressedTextColor.g, self.pressedTextColor.b, self.pressedTextColor.a or 1)
            end
        end)

        button:SetScript("OnMouseUp", function(self)
            self.text:SetPoint("CENTER", 0, 0)
            self.textPressed = false
            if self.pressedTextColor and self.isHovering then
                if self.textAnimation == "rainbow" then
                    -- Let OnUpdate handle color
                else
                    self.text:SetTextColor(self.hoverTextColor.r, self.hoverTextColor.g, self.hoverTextColor.b, self.hoverTextColor.a or 1)
                end
            end
        end)
    end

    if options.onClick then
        button:SetScript("OnClick", function(self)
            options.onClick(self)
        end)
    end

    return button
end

function UIFactory:CreateIconButton(parent, size, options)
    options = options or {}
    size = size or 24

    local bgColor, borderColor
    if not options.bgColor and KOL.Themes and KOL.Themes.GetUIThemeColor then
        bgColor = KOL.Themes:GetUIThemeColor("ButtonBG", {r = 0.08, g = 0.08, b = 0.08, a = 1})
        borderColor = options.borderColor or KOL.Themes:GetUIThemeColor("ButtonBorder", {r = 0.3, g = 0.3, b = 0.3, a = 1})
    else
        bgColor = options.bgColor or {r = 0.08, g = 0.08, b = 0.08, a = 1}
        borderColor = options.borderColor or {r = 0.3, g = 0.3, b = 0.3, a = 1}
    end

    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
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

    local texture = button:CreateTexture(nil, "ARTWORK")
    local inset = options.textureInset or 4
    texture:SetPoint("TOPLEFT", inset, -inset)
    texture:SetPoint("BOTTOMRIGHT", -inset, inset)
    button.texture = texture

    if options.texture then
        texture:SetTexture(options.texture)
        button.normalTexture = options.texture
    end
    if options.hoverTexture then
        button.hoverTexture = options.hoverTexture
    end
    if options.texCoords then
        texture:SetTexCoord(unpack(options.texCoords))
    end

    button:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0, 0.8, 0.8, 1)
        if self.hoverTexture then
            self.texture:SetTexture(self.hoverTexture)
        end
    end)

    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        if self.normalTexture then
            self.texture:SetTexture(self.normalTexture)
        end
    end)

    if options.onClick then
        button:SetScript("OnClick", options.onClick)
    end

    return button
end

function UIFactory:CreateEditBox(parent, width, height, options)
    options = options or {}
    height = height or 24

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

    if options.onEnterPressed then
        editBox:SetScript("OnEnterPressed", function(self)
            options.onEnterPressed(self:GetText())
        end)
    end

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    editBox.container = container
    container.editBox = editBox

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

function UIFactory:CreateMultiLineEditBox(parent, width, height, options)
    options = options or {}

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

    local scrollFrame = CreateFrame("ScrollFrame", nil, container)
    scrollFrame:SetPoint("TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -4, 4)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetSize(width - 12, height - 8)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)

    local fontPath, fontOutline = GetGeneralFont()
    editBox:SetFont(fontPath, fontSize, fontOutline)
    editBox:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a or 1)

    scrollFrame:SetScrollChild(editBox)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = current - (delta * 20)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)

    container:EnableMouse(true)
    container:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)

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

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    container.scrollFrame = scrollFrame
    container.editBox = editBox

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

function UIFactory:CreateDropdown(parent, width, options)
    options = options or {}
    local height = 24

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

    local selectedText = dropdown:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont(fontPath, fontSize, fontOutline)
    selectedText:SetPoint("LEFT", 8, 0)
    selectedText:SetPoint("RIGHT", -20, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetText(options.placeholder or "Select...")
    selectedText:SetTextColor(0.7, 0.7, 0.7, 1)
    dropdown.selectedText = selectedText

    local arrow = dropdown:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(CHAR_LIGATURESFONT, fontSize, CHAR_LIGATURESOUTLINE)
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetText(CHAR_ARROW_DOWNFILLED)
    arrow:SetTextColor(0.6, 0.6, 0.6, 1)
    dropdown.arrow = arrow

    dropdown.items = options.items or {}
    dropdown.selectedValue = options.selectedValue
    dropdown.onSelect = options.onSelect
    dropdown.isOpen = false

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

    local rootFrame = self:FindRootFrame(parent)
    local dropStrata, dropLevel = self:GetDropdownStrataInfo(rootFrame or parent)
    list:SetFrameStrata(dropStrata)
    list:SetFrameLevel(dropLevel)

    list:Hide()
    dropdown.list = list

    local function PopulateList()
        for _, child in ipairs({list:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end

        local itemHeight = 22
        local yOffset = -2

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
            itemBtn:SetFrameLevel(listLevel + 1)
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

            itemBtn:SetScript("OnEnter", function(self)
                self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
                self:SetBackdropColor(0.2, 0.2, 0.2, 1)
            end)

            itemBtn:SetScript("OnLeave", function(self)
                self:SetBackdrop(nil)
            end)

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

    dropdown:SetScript("OnClick", function(self)
        if self.isOpen then
            self.list:Hide()
            self.isOpen = false
            self.arrow:SetText(CHAR_ARROW_DOWNFILLED)
        else
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

    dropdown:SetScript("OnEnter", function(self)
        self:SetBackdropColor(bgColor.r + 0.05, bgColor.g + 0.05, bgColor.b + 0.05, bgColor.a or 1)
    end)

    dropdown:SetScript("OnLeave", function(self)
        self:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
    end)

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

    if options.selectedValue then
        dropdown:SetSelectedValue(options.selectedValue)
    end

    return dropdown
end

function UIFactory:CreateCheckbox(parent, label, options)
    options = options or {}

    local fontSize = options.fontSize or 12
    local labelColor = options.labelColor or {r = 0.9, g = 0.9, b = 0.9, a = 1}
    local checkColor = options.checkColor or {r = 0, g = 0.8, b = 0.8, a = 1}

    local fontPath, fontOutline = GetGeneralFont()

    local container = CreateFrame("Button", nil, parent)
    container:EnableMouse(true)

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

    local checkmark = box:CreateFontString(nil, "OVERLAY")
    checkmark:SetFont(CHAR_LIGATURESFONT, fontSize, CHAR_LIGATURESOUTLINE)
    checkmark:SetPoint("CENTER", 0, 0)
    checkmark:SetText(CHAR_OBJECTIVE_COMPLETE)
    checkmark:SetTextColor(checkColor.r, checkColor.g, checkColor.b, checkColor.a or 1)
    checkmark:Hide()
    container.checkmark = checkmark

    local labelText = container:CreateFontString(nil, "OVERLAY")
    labelText:SetFont(fontPath, fontSize, fontOutline)
    labelText:SetPoint("LEFT", box, "RIGHT", 6, 0)
    labelText:SetText(label)
    labelText:SetTextColor(labelColor.r, labelColor.g, labelColor.b, labelColor.a or 1)
    container.label = labelText

    local textWidth = labelText:GetStringWidth()
    container:SetSize(16 + 6 + textWidth + 4, 18)

    container.checked = options.checked or false
    container.onChange = options.onChange

    local function UpdateState()
        if container.checked then
            container.checkmark:Show()
            container.box:SetBackdropBorderColor(checkColor.r, checkColor.g, checkColor.b, 1)
        else
            container.checkmark:Hide()
            container.box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end
    end

    UpdateState()

    container:SetScript("OnClick", function(self)
        self.checked = not self.checked
        UpdateState()
        if self.onChange then
            self.onChange(self.checked)
        end
    end)

    container:SetScript("OnEnter", function(self)
        self.box:SetBackdropColor(0.1, 0.1, 0.1, 1)
    end)

    container:SetScript("OnLeave", function(self)
        self.box:SetBackdropColor(0.05, 0.05, 0.05, 1)
    end)

    function container:SetChecked(checked)
        self.checked = checked
        UpdateState()
    end

    function container:IsChecked()
        return self.checked
    end

    return container
end

function UIFactory:CreateActionApprovalFrame(parent, frameId, options)
    options = options or {}

    local line1 = options.line1 or "Are you sure you want to"
    local actionName = options.actionName or "perform this action"
    local contextLine = options.contextLine
    local checkboxText = options.checkboxText or "I understand this action cannot be undone"
    local confirmText = options.confirmText or "CONFIRM"
    local cancelText = options.cancelText or "CANCEL"
    local actionColor = options.actionColor or {r = 0, g = 0.8, b = 0.8, a = 1}
    local contextColor = options.contextColor or {r = 0.7, g = 0.5, b = 0.9, a = 1}
    local confirmColor = options.confirmColor or {r = 0.8, g = 0.3, b = 0.3, a = 1}
    local requireCheckbox = options.requireCheckbox ~= false
    local onConfirm = options.onConfirm
    local onCancel = options.onCancel

    local baseHeight = contextLine and 115 or 100

    local frame = self:CreateStyledFrame(parent, frameId, 340, baseHeight, {
        closable = true,
        movable = true,
    })
    frame:SetPoint("CENTER")
    frame:Hide()

    local fontPath, fontOutline = GetGeneralFont()
    local yOffset = -12

    local line1Text = frame:CreateFontString(nil, "OVERLAY")
    line1Text:SetFont(fontPath, 11, fontOutline)
    line1Text:SetPoint("TOP", frame, "TOP", 0, yOffset)
    line1Text:SetText(line1)
    line1Text:SetTextColor(0.9, 0.9, 0.9, 1)
    frame.line1Text = line1Text

    yOffset = yOffset - 18

    local actionText = frame:CreateFontString(nil, "OVERLAY")
    actionText:SetFont(fontPath, 12, fontOutline)
    actionText:SetPoint("TOP", frame, "TOP", 0, yOffset)
    actionText:SetText(actionName)
    actionText:SetTextColor(actionColor.r, actionColor.g, actionColor.b, actionColor.a or 1)
    frame.actionText = actionText

    yOffset = yOffset - 18

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

    if requireCheckbox then
        confirmBtn:Disable()
        confirmBtn:SetAlpha(0.5)
    end

    frame.actionColor = actionColor
    frame.contextColor = contextColor
    frame.requireCheckbox = requireCheckbox

    function frame:SetActionName(text)
        self.actionText:SetText(text)
    end

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

    function frame:SetOnConfirm(func)
        self.onConfirmCallback = func
    end

    function frame:Reset()
        self.checkbox:SetChecked(false)
        if self.requireCheckbox then
            self.confirmBtn:Disable()
            self.confirmBtn:SetAlpha(0.5)
        end
    end

    local originalShow = frame.Show
    frame.Show = function(self)
        self:Reset()
        originalShow(self)
    end

    return frame
end

function UIFactory:CreateScrollableDropdown(parent, width, options)
    options = options or {}
    width = width or 200
    local height = 24
    local itemHeight = 22
    local maxVisibleItems = 12

    local fontPath, fontOutline = GetGeneralFont()
    local fontSize = options.fontSize or 12

    local bgColor, borderColor
    if KOL.Themes and KOL.Themes.GetUIThemeColor then
        bgColor = KOL.Themes:GetUIThemeColor("ContentAreaBG", {r = 0.08, g = 0.08, b = 0.08, a = 1})
        borderColor = KOL.Themes:GetUIThemeColor("ContentAreaBorder", {r = 0.3, g = 0.3, b = 0.3, a = 1})
    else
        bgColor = {r = 0.08, g = 0.08, b = 0.08, a = 1}
        borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1}
    end

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

    local selectedText = dropdown:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont(fontPath, fontSize, fontOutline)
    selectedText:SetPoint("LEFT", 8, 0)
    selectedText:SetPoint("RIGHT", -20, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetText(options.placeholder or "Select...")
    selectedText:SetTextColor(0.7, 0.7, 0.7, 1)
    dropdown.selectedText = selectedText

    local arrow = dropdown:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(CHAR_LIGATURESFONT, fontSize, CHAR_LIGATURESOUTLINE)
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetText(CHAR_ARROW_DOWNFILLED)
    arrow:SetTextColor(0.6, 0.6, 0.6, 1)
    dropdown.arrow = arrow

    dropdown.selectedValue = options.selectedValue
    dropdown.isOpen = false
    dropdown.onSelect = options.onSelect
    dropdown.items = options.items or {}
    dropdown.itemButtons = {}

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

    local rootFrame = self:FindRootFrame(parent)
    local dropStrata, dropLevel = self:GetDropdownStrataInfo(rootFrame or parent)
    list:SetFrameStrata(dropStrata)
    list:SetFrameLevel(dropLevel)

    list:Hide()
    dropdown.list = list

    local scrollFrame = CreateFrame("ScrollFrame", nil, list)
    scrollFrame:SetPoint("TOPLEFT", 2, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
    scrollFrame:SetFrameStrata(dropStrata)
    scrollFrame:SetFrameLevel(dropLevel + 1)
    dropdown.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(width - 4)
    scrollChild:SetFrameStrata(dropStrata)
    scrollChild:SetFrameLevel(dropLevel + 2)
    scrollFrame:SetScrollChild(scrollChild)
    dropdown.scrollChild = scrollChild

    local scrollBar = CreateFrame("Frame", nil, list)
    scrollBar:SetWidth(8)
    scrollBar:SetPoint("TOPRIGHT", -2, -2)
    scrollBar:SetPoint("BOTTOMRIGHT", -2, 2)
    scrollBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    scrollBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    scrollBar:Hide()
    dropdown.scrollBar = scrollBar

    local scrollThumb = CreateFrame("Frame", nil, scrollBar)
    scrollThumb:SetWidth(6)
    scrollThumb:SetPoint("TOP", 0, 0)
    scrollThumb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    scrollThumb:SetBackdropColor(0.4, 0.4, 0.4, 1)
    scrollThumb:EnableMouse(true)
    dropdown.scrollThumb = scrollThumb
    dropdown.isDragging = false

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

    local function PopulateList()
        local items = dropdown.items

        local screenHeight = UIParent:GetHeight()
        local maxListHeight = screenHeight * 0.4
        maxVisibleItems = math.floor(maxListHeight / itemHeight)

        local needsScroll = #items > maxVisibleItems
        local visibleCount = needsScroll and maxVisibleItems or #items
        local listHeight = (visibleCount * itemHeight) + 4

        list:SetHeight(listHeight)
        scrollChild:SetHeight(#items * itemHeight)

        if needsScroll then
            scrollBar:Show()
            scrollFrame:SetPoint("BOTTOMRIGHT", -12, 2)
            local thumbHeight = math.max(20, (visibleCount / #items) * (listHeight - 4))
            scrollThumb:SetHeight(thumbHeight)
        else
            scrollBar:Hide()
            scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
        end

        for _, btn in ipairs(dropdown.itemButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
        dropdown.itemButtons = {}

        local listLevel = list:GetFrameLevel()

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
            itemBtn:SetFrameStrata(list:GetFrameStrata())
            itemBtn:SetFrameLevel(listLevel + 3)
            itemBtn:SetSize(width - (needsScroll and 16 or 8), itemHeight)
            itemBtn:SetPoint("TOPLEFT", 2, -((i - 1) * itemHeight))

            local checkmark = itemBtn:CreateFontString(nil, "OVERLAY")
            checkmark:SetFont(CHAR_LIGATURESFONT, fontSize - 2, CHAR_LIGATURESOUTLINE)
            checkmark:SetPoint("LEFT", 4, 0)
            checkmark:SetText(CHAR_OBJECTIVE_COMPLETE)
            checkmark:SetTextColor(0.3, 0.9, 0.3, 1)
            checkmark:Hide()
            itemBtn.checkmark = checkmark

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

            if value == dropdown.selectedValue then
                checkmark:Show()
            end

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

            itemBtn:SetScript("OnClick", function(self)
                dropdown.selectedValue = value
                dropdown.selectedText:SetText(label)
                if color then
                    dropdown.selectedText:SetTextColor(color.r, color.g, color.b, 1)
                else
                    dropdown.selectedText:SetTextColor(0.9, 0.9, 0.9, 1)
                end

                for _, btn in ipairs(dropdown.itemButtons) do
                    btn.checkmark:Hide()
                end
                self.checkmark:Show()

                list:Hide()
                dropdown.isOpen = false
                if dropdown.onSelect then
                    dropdown.onSelect(value, label)
                end
            end)

            table.insert(dropdown.itemButtons, itemBtn)
        end

        scrollFrame:SetVerticalScroll(0)
        scrollThumb:SetPoint("TOP", 0, 0)
    end

    local function OnMouseWheel(self, delta)
        local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
        if maxScroll <= 0 then return end

        local current = scrollFrame:GetVerticalScroll()
        local new = current - (delta * itemHeight * 2)
        new = math.max(0, math.min(new, maxScroll))
        scrollFrame:SetVerticalScroll(new)

        local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
        local thumbPos = (new / maxScroll) * thumbRange
        scrollThumb:SetPoint("TOP", 0, -thumbPos)
    end

    list:EnableMouseWheel(true)
    scrollFrame:EnableMouseWheel(true)
    scrollChild:EnableMouseWheel(true)

    list:SetScript("OnMouseWheel", OnMouseWheel)
    scrollFrame:SetScript("OnMouseWheel", OnMouseWheel)
    scrollChild:SetScript("OnMouseWheel", OnMouseWheel)

    dropdown:SetScript("OnClick", function(self)
        if self.isOpen then
            list:Hide()
            self.isOpen = false
        else
            local rootFrame = UIFactory:FindRootFrame(self)
            local dropStrata, dropLevel = UIFactory:GetDropdownStrataInfo(rootFrame or self:GetParent())
            list:SetFrameStrata(dropStrata)
            list:SetFrameLevel(dropLevel)

            PopulateList()
            list:Show()
            self.isOpen = true
        end
    end)

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
        dropdown.isDragging = false
    end)

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

    if options.selectedValue then
        dropdown:SetValue(options.selectedValue)
    end

    return dropdown
end

function UIFactory:CreateFontChoiceDropdown(parent, name, label, width, callback)
    width = width or 200
    local height = 24
    local itemHeight = 22
    local maxVisibleItems = 12

    local fontPath, fontOutline = GetGeneralFont()
    local fontSize = 12

    local bgColor, borderColor
    if KOL.Themes and KOL.Themes.GetUIThemeColor then
        bgColor = KOL.Themes:GetUIThemeColor("ContentAreaBG", {r = 0.08, g = 0.08, b = 0.08, a = 1})
        borderColor = KOL.Themes:GetUIThemeColor("ContentAreaBorder", {r = 0.3, g = 0.3, b = 0.3, a = 1})
    else
        bgColor = {r = 0.08, g = 0.08, b = 0.08, a = 1}
        borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1}
    end

    local container = CreateFrame("Frame", name, parent)
    container:SetSize(width, label and (height + 18) or height)

    local labelText
    if label then
        labelText = container:CreateFontString(nil, "OVERLAY")
        labelText:SetFont(fontPath, fontSize - 1, fontOutline)
        labelText:SetPoint("TOPLEFT", 0, 0)
        labelText:SetText(label)
        labelText:SetTextColor(0.8, 0.8, 0.8, 1)
        container.label = labelText
    end

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

    local selectedText = dropdown:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont(fontPath, fontSize, fontOutline)
    selectedText:SetPoint("LEFT", 8, 0)
    selectedText:SetPoint("RIGHT", -20, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetText("Select Font...")
    selectedText:SetTextColor(0.7, 0.7, 0.7, 1)
    dropdown.selectedText = selectedText

    local arrow = dropdown:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(CHAR_LIGATURESFONT, fontSize, CHAR_LIGATURESOUTLINE)
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetText(CHAR_ARROW_DOWNFILLED)
    arrow:SetTextColor(0.6, 0.6, 0.6, 1)
    dropdown.arrow = arrow

    dropdown.selectedValue = nil
    dropdown.isOpen = false
    dropdown.callback = callback
    dropdown.items = {}
    dropdown.itemButtons = {}

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

    local rootFrame = self:FindRootFrame(parent)
    local dropStrata, dropLevel = self:GetDropdownStrataInfo(rootFrame or parent)
    list:SetFrameStrata(dropStrata)
    list:SetFrameLevel(dropLevel)

    list:Hide()
    dropdown.list = list

    local scrollFrame = CreateFrame("ScrollFrame", name and (name .. "ScrollFrame") or nil, list)
    scrollFrame:SetPoint("TOPLEFT", 2, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
    scrollFrame:SetFrameStrata(dropStrata)
    scrollFrame:SetFrameLevel(dropLevel + 1)
    dropdown.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(width - 4)
    scrollChild:SetFrameStrata(dropStrata)
    scrollChild:SetFrameLevel(dropLevel + 2)
    scrollFrame:SetScrollChild(scrollChild)
    dropdown.scrollChild = scrollChild

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

    local function GetSortedFonts()
        local fonts = {}
        local fontList = LSM:List("font")

        for _, fontName in ipairs(fontList) do
            table.insert(fonts, fontName)
        end

        table.sort(fonts, function(a, b)
            return string.lower(a) < string.lower(b)
        end)

        return fonts
    end

    local function PopulateList()
        local fonts = GetSortedFonts()
        dropdown.items = fonts

        local screenHeight = UIParent:GetHeight()
        local maxListHeight = screenHeight * 0.4
        maxVisibleItems = math.floor(maxListHeight / itemHeight)

        local needsScroll = #fonts > maxVisibleItems
        local visibleCount = needsScroll and maxVisibleItems or #fonts
        local listHeight = (visibleCount * itemHeight) + 4

        list:SetHeight(listHeight)
        scrollChild:SetHeight(#fonts * itemHeight)

        if needsScroll then
            scrollBar:Show()
            scrollFrame:SetPoint("BOTTOMRIGHT", -12, 2)

            local thumbHeight = math.max(20, (visibleCount / #fonts) * (listHeight - 4))
            scrollThumb:SetHeight(thumbHeight)
        else
            scrollBar:Hide()
            scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
        end

        for _, btn in ipairs(dropdown.itemButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
        dropdown.itemButtons = {}

        local listLevel = list:GetFrameLevel()

        for i, fontName in ipairs(fonts) do
            local itemBtn = CreateFrame("Button", nil, scrollChild)
            itemBtn:SetFrameStrata(list:GetFrameStrata())
            itemBtn:SetFrameLevel(listLevel + 3)
            itemBtn:SetSize(width - (needsScroll and 16 or 8), itemHeight)
            itemBtn:SetPoint("TOPLEFT", 2, -((i - 1) * itemHeight))

            local checkmark = itemBtn:CreateFontString(nil, "OVERLAY")
            checkmark:SetFont(CHAR_LIGATURESFONT, fontSize - 2, CHAR_LIGATURESOUTLINE)
            checkmark:SetPoint("LEFT", 4, 0)
            checkmark:SetText(CHAR_OBJECTIVE_COMPLETE)
            checkmark:SetTextColor(0, 0.8, 0.8, 1)
            checkmark:Hide()
            itemBtn.checkmark = checkmark

            local itemText = itemBtn:CreateFontString(nil, "OVERLAY")
            local fontFilePath = LSM:Fetch("font", fontName)
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

            if dropdown.selectedValue == fontName then
                checkmark:Show()
                itemText:SetTextColor(0, 0.9, 0.9, 1)
            end

            itemBtn:SetScript("OnEnter", function(self)
                self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
                self:SetBackdropColor(0.15, 0.15, 0.15, 1)
            end)

            itemBtn:SetScript("OnLeave", function(self)
                self:SetBackdrop(nil)
            end)

            itemBtn:SetScript("OnClick", function(self)
                for _, btn in ipairs(dropdown.itemButtons) do
                    btn.checkmark:Hide()
                    btn.itemText:SetTextColor(0.9, 0.9, 0.9, 1)
                end

                self.checkmark:Show()
                self.itemText:SetTextColor(0, 0.9, 0.9, 1)

                dropdown.selectedValue = self.fontName

                local selectedFontPath = LSM:Fetch("font", self.fontName)
                if selectedFontPath then
                    dropdown.selectedText:SetFont(selectedFontPath, fontSize, "")
                end
                dropdown.selectedText:SetText(self.fontName)
                dropdown.selectedText:SetTextColor(1, 1, 1, 1)

                list:Hide()
                dropdown.isOpen = false
                dropdown.arrow:SetText(CHAR_ARROW_DOWNFILLED)

                if dropdown.callback then
                    dropdown.callback(self.fontName)
                end
            end)

            table.insert(dropdown.itemButtons, itemBtn)
        end

        scrollFrame:SetVerticalScroll(0)
        scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, 0)
    end

    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
        if maxScroll <= 0 then return end

        local current = scrollFrame:GetVerticalScroll()
        local newScroll = current - (delta * itemHeight * 2)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        scrollFrame:SetVerticalScroll(newScroll)

        local scrollPercent = newScroll / maxScroll
        local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
        scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, -scrollPercent * thumbRange)
    end)

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

            local scrollPercent = newScroll / maxScroll
            scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, -scrollPercent * thumbRange)
        end
    end)

    dropdown:SetScript("OnClick", function(self)
        if self.isOpen then
            self.list:Hide()
            self.isOpen = false
            self.arrow:SetText(CHAR_ARROW_DOWNFILLED)
        else
            local rootFrame = UIFactory:FindRootFrame(self)
            local dropStrata, dropLevel = UIFactory:GetDropdownStrataInfo(rootFrame or self:GetParent())
            list:SetFrameStrata(dropStrata)
            list:SetFrameLevel(dropLevel)

            PopulateList()

            local scale = UIParent:GetEffectiveScale()
            local dropdownBottom = self:GetBottom() * scale
            local listHeight = list:GetHeight() * scale

            list:ClearAllPoints()
            if dropdownBottom - listHeight - 4 < 0 then
                list:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
                self.arrow:SetText(CHAR_ARROW_DOWNFILLED)
            else
                list:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
                self.arrow:SetText(CHAR_ARROW_UPFILLED)
            end

            self.list:Show()
            self.isOpen = true

            if self.selectedValue then
                for i, fontName in ipairs(self.items) do
                    if fontName == self.selectedValue then
                        local targetScroll = (i - 1) * itemHeight
                        local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
                        if maxScroll > 0 then
                            targetScroll = math.min(targetScroll, maxScroll)
                            scrollFrame:SetVerticalScroll(targetScroll)

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

    dropdown:SetScript("OnEnter", function(self)
        self:SetBackdropColor(bgColor.r + 0.05, bgColor.g + 0.05, bgColor.b + 0.05, bgColor.a or 1)
    end)

    dropdown:SetScript("OnLeave", function(self)
        self:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
    end)

    list:SetScript("OnUpdate", function(self)
        if dropdown.isOpen and not self:IsMouseOver() and not dropdown:IsMouseOver() then
            if IsMouseButtonDown("LeftButton") then
                self:Hide()
                dropdown.isOpen = false
                dropdown.arrow:SetText(CHAR_ARROW_DOWNFILLED)
            end
        end
    end)

    function container:GetValue()
        return dropdown.selectedValue
    end

    function container:SetValue(fontName)
        if not fontName then return end

        dropdown.selectedValue = fontName

        local selectedFontPath = LSM:Fetch("font", fontName)
        if selectedFontPath then
            dropdown.selectedText:SetFont(selectedFontPath, fontSize, "")
        end
        dropdown.selectedText:SetText(fontName)
        dropdown.selectedText:SetTextColor(1, 1, 1, 1)

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

function UIFactory:CreateStyledDropdown(parent, width, options)
    options = options or {}
    width = width or 150
    local height = 22
    local fontSize = options.fontSize or 10
    local maxVisible = options.maxVisible or 8
    local itemHeight = options.itemHeight or 20

    local fontPath, fontOutline = GetGeneralFont()

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

    local selectedText = dropdown:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont(fontPath, fontSize, fontOutline)
    selectedText:SetPoint("LEFT", 6, 0)
    selectedText:SetPoint("RIGHT", -18, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetText(options.placeholder or "Select...")
    selectedText:SetTextColor(0.9, 0.9, 0.9, 1)
    dropdown.text = selectedText
    dropdown.selectedText = selectedText

    local arrow = dropdown:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(CHAR_LIGATURESFONT, fontSize, CHAR_LIGATURESOUTLINE)
    arrow:SetPoint("RIGHT", -5, 0)
    arrow:SetText(CHAR_ARROW_DOWNFILLED)
    arrow:SetTextColor(0.5, 0.5, 0.5, 1)
    dropdown.arrow = arrow

    dropdown.selectedValue = options.selectedValue
    dropdown.items = options.items or {}
    dropdown.onSelect = options.onSelect
    dropdown.bgColor = bgColor
    dropdown.borderColor = borderColor
    dropdown.hoverBorderColor = hoverBorderColor

    dropdown:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(self.hoverBorderColor.r, self.hoverBorderColor.g, self.hoverBorderColor.b, 1)
        self.arrow:SetTextColor(0.8, 0.8, 0.8, 1)
    end)
    dropdown:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(self.borderColor.r, self.borderColor.g, self.borderColor.b, 1)
        self.arrow:SetTextColor(0.5, 0.5, 0.5, 1)
    end)

    local function ShowPopup()
        if styledPopupMenu and styledPopupMenu:IsShown() and styledPopupOwner == dropdown then
            HideStyledPopup()
            return
        end

        HideStyledPopup()

        if not styledPopupMenu then
            styledPopupMenu = CreateFrame("Frame", "KOL_StyledPopupMenu", UIParent)
            styledPopupMenu:SetFrameStrata("HIGH")
            styledPopupMenu:SetFrameLevel(100)
            styledPopupMenu:Hide()
            styledPopupMenu.buttons = {}

            local backdropFrame = CreateFrame("Frame", nil, styledPopupMenu)
            backdropFrame:SetAllPoints()
            backdropFrame:SetFrameLevel(1)
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

        local rootFrame = UIFactory:FindRootFrame(dropdown)
        local dropStrata, dropLevel = UIFactory:GetDropdownStrataInfo(rootFrame or dropdown:GetParent())
        styledPopupMenu:SetFrameStrata(dropStrata)
        styledPopupMenu:SetFrameLevel(dropLevel)

        if styledPopupMenu.backdropFrame then
            styledPopupMenu.backdropFrame:SetFrameLevel(dropLevel)
        end

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

            scrollFrame:EnableMouseWheel(true)
            scrollFrame:SetScript("OnMouseWheel", function(self, delta)
                local current = self:GetVerticalScroll()
                local maxScroll = math.max(0, (numItems * itemHeight) - (visibleItems * itemHeight))
                local newScroll = math.max(0, math.min(maxScroll, current - (delta * itemHeight)))
                self:SetVerticalScroll(newScroll)
            end)
        end

        scrollFrame:SetFrameLevel(dropLevel + 5)
        scrollChild:SetFrameLevel(dropLevel + 10)

        scrollChild:SetSize(menuWidth - 4, numItems * itemHeight)
        scrollFrame:SetVerticalScroll(0)

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
            btn:SetFrameLevel(dropLevel + 15)
            btn:SetSize(menuWidth - 4, itemHeight)
            btn:SetPoint("TOPLEFT", 0, -((i - 1) * itemHeight))

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

            local labelText = btn:CreateFontString(nil, "OVERLAY")
            labelText:SetFont(fontPath, fontSize, fontOutline)
            labelText:SetPoint("LEFT", labelOffset, 0)
            labelText:SetPoint("RIGHT", -6, 0)
            labelText:SetJustifyH("LEFT")
            labelText:SetText(color .. label .. (color ~= "" and "|r" or ""))
            labelText:SetTextColor(0.9, 0.9, 0.9, 1)
            btn.labelText = labelText

            if value == dropdown.selectedValue then
                local check = btn:CreateFontString(nil, "OVERLAY")
                check:SetFont(CHAR_LIGATURESFONT, fontSize - 2, CHAR_LIGATURESOUTLINE)
                check:SetPoint("RIGHT", -4, 0)
                check:SetText(CHAR_OBJECTIVE_COMPLETE)
                check:SetTextColor(0.3, 0.9, 0.3, 1)
            end

            btn:SetScript("OnEnter", function(self)
                self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
                self:SetBackdropColor(0.2, 0.2, 0.2, 1)
            end)
            btn:SetScript("OnLeave", function(self)
                self:SetBackdrop(nil)
            end)

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

    dropdown:SetScript("OnClick", ShowPopup)

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

    if options.selectedValue then
        dropdown:SetValue(options.selectedValue)
    end

    return dropdown
end

function UIFactory:CreateButton(parent, text, options)
    options = options or {}
    local buttonType = options.type or "styled"

    if buttonType == "text" then
        return self:OldCreateTextButton(parent, text, {
            textColor = options.textColor,
            hoverColor = options.hoverColor,
            fontSize = options.fontSize,
            onClick = options.onClick,
        })

    elseif buttonType == "animated" or buttonType == "animatedtext" then
        return self:OldCreateAnimatedTextButton(parent, text, {
            textColor = options.textColor,
            fontSize = options.fontSize,
            onClick = options.onClick,
            rainbowSpeed = options.rainbowSpeed,
        })

    elseif buttonType == "animatedbutton" then
        return self:OldCreateAnimatedBorderButton(parent, options.width or 100, options.height or 28, text, {
            borderAnimation = options.borderAnimation or "fade",
            textAnimation = options.textAnimation,
            textColor = options.textColor,
            hoverTextColor = options.hoverTextColor,
            pressedTextColor = options.pressedTextColor,
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

    else
        local width = options.width or 100
        local height = options.height or 28
        local fontSize = options.fontSize or 11

        local textColor = options.textColor or {r = 1, g = 1, b = 1, a = 1}
        local hoverColor = options.hoverColor or {r = 1, g = 1, b = 1, a = 1}

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

        local fontPath, fontOutline = GetGeneralFont()
        local buttonText = button:CreateFontString(nil, "OVERLAY")
        buttonText:SetFont(fontPath, fontSize, fontOutline)
        buttonText:SetPoint("CENTER")
        buttonText:SetText(text)
        buttonText:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a or 1)
        button.text = buttonText

        button.bgColor = bgColor
        button.borderColor = borderColor
        button.hoverBgColor = hoverBgColor
        button.hoverBorderColor = hoverBorderColor
        button.textColor = textColor
        button.hoverTextColor = hoverColor
        button.pressedTextColor = options.pressedTextColor

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
            if self.textPressed then
                self.text:SetPoint("CENTER", 0, 0)
                self.textPressed = false
            end
        end)

        local usePressEffect = options.textPressEffect ~= false
        button.textPressEffect = usePressEffect
        button.textPressed = false
        if usePressEffect then
            button:SetScript("OnMouseDown", function(self)
                if not self.disabled then
                    self.text:SetPoint("CENTER", 1, -1)
                    self.textPressed = true
                    if self.pressedTextColor then
                        self.text:SetTextColor(self.pressedTextColor.r, self.pressedTextColor.g, self.pressedTextColor.b, self.pressedTextColor.a or 1)
                    end
                end
            end)

            button:SetScript("OnMouseUp", function(self)
                self.text:SetPoint("CENTER", 0, 0)
                self.textPressed = false
                if self.pressedTextColor then
                    self.text:SetTextColor(self.hoverTextColor.r, self.hoverTextColor.g, self.hoverTextColor.b, self.hoverTextColor.a or 1)
                end
            end)
        end

        if options.onClick then
            button:SetScript("OnClick", function(self)
                if not self.disabled then
                    options.onClick(self)
                end
            end)
        end

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

local uiShowcaseFrame = nil

function UIFactory:ShowUIShowcase()
    if uiShowcaseFrame then
        uiShowcaseFrame:Show()
        uiShowcaseFrame:Raise()
        return uiShowcaseFrame
    end

    local frame = self:CreateStyledFrame(UIParent, "KOL_UIShowcase", 520, 500, {
        movable = true,
        closable = true,
        strata = UIFactory.STRATA.IMPORTANT,
    })
    frame:SetPoint("CENTER")

    local fontPath, fontOutline = GetGeneralFont()

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontPath, 14, fontOutline)
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText("UIFactory Showcase")
    title:SetTextColor(0, 0.9, 0.9, 1)

    local subtitle = frame:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(fontPath, 10, fontOutline)
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
    subtitle:SetText("Buttons, Checkboxes, Edit Boxes, Dropdowns, Font Pickers")
    subtitle:SetTextColor(0.6, 0.6, 0.6, 1)

    local closeBtn = self:CreateButton(frame, "Close Showcase", {
        type = "animated",
        textColor = {r = 0.7, g = 0.7, b = 0.7, a = 1},
        fontSize = 11,
        onClick = function() frame:Hide() end
    })
    closeBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 35)
    scrollFrame:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(scrollFrame:GetWidth() - 10)
    content:SetHeight(600)
    scrollFrame:SetScrollChild(content)

    local scrollBar = CreateFrame("Slider", nil, frame)
    scrollBar:SetWidth(12)
    scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -50)
    scrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 35)
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetMinMaxValues(0, 1)
    scrollBar:SetValue(0)
    scrollBar:SetValueStep(20)

    scrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    scrollBar:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    scrollBar:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetVertexColor(0.3, 0.3, 0.3, 1)
    thumb:SetWidth(10)
    thumb:SetHeight(40)
    scrollBar:SetThumbTexture(thumb)

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

    scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)

    local yOffset = -5

    local section1 = content:CreateFontString(nil, "OVERLAY")
    section1:SetFont(fontPath, 11, fontOutline)
    section1:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section1:SetText("type = \"styled\" (with border/background)")
    section1:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

    local btn1 = self:CreateButton(content, "Default Styled", {
        type = "styled",
        width = 110,
        height = 26,
        onClick = function() KOL:PrintTag("Clicked: Default Styled") end
    })
    btn1:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)

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

    local btn4 = self:CreateButton(content, "Disabled", {
        type = "styled",
        width = 80,
        height = 26,
        disabled = true,
    })
    btn4:SetPoint("LEFT", btn3, "RIGHT", 10, 0)

    yOffset = yOffset - 40

    local section2 = content:CreateFontString(nil, "OVERLAY")
    section2:SetFont(fontPath, 11, fontOutline)
    section2:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section2:SetText("type = \"text\" (no border, simple hover)")
    section2:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

    local txtBtn1 = self:CreateButton(content, "Default Text", {
        type = "text",
        onClick = function() KOL:PrintTag("Clicked: Default Text") end
    })
    txtBtn1:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)

    local txtBtn2 = self:CreateButton(content, "Cyan Hover", {
        type = "text",
        textColor = {r = 0.7, g = 0.7, b = 0.7, a = 1},
        hoverColor = {r = 0, g = 0.9, b = 0.9, a = 1},
        onClick = function() KOL:PrintTag("Clicked: Cyan Hover") end
    })
    txtBtn2:SetPoint("LEFT", txtBtn1, "RIGHT", 20, 0)

    local txtBtn3 = self:CreateButton(content, "Green Link", {
        type = "text",
        textColor = {r = 0.4, g = 0.8, b = 0.4, a = 1},
        hoverColor = {r = 0.6, g = 1, b = 0.6, a = 1},
        onClick = function() KOL:PrintTag("Clicked: Green Link") end
    })
    txtBtn3:SetPoint("LEFT", txtBtn2, "RIGHT", 20, 0)

    local txtBtn4 = self:CreateButton(content, "Large Font", {
        type = "text",
        fontSize = 14,
        textColor = {r = 0.9, g = 0.6, b = 0.3, a = 1},
        hoverColor = {r = 1, g = 0.8, b = 0.4, a = 1},
        onClick = function() KOL:PrintTag("Clicked: Large Font") end
    })
    txtBtn4:SetPoint("LEFT", txtBtn3, "RIGHT", 20, 0)

    yOffset = yOffset - 40

    local section3 = content:CreateFontString(nil, "OVERLAY")
    section3:SetFont(fontPath, 11, fontOutline)
    section3:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section3:SetText("type = \"animated\" (rainbow hover)")
    section3:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

    local animBtn1 = self:CreateButton(content, "Rainbow Hover", {
        type = "animated",
        onClick = function() KOL:PrintTag("Clicked: Rainbow Hover") end
    })
    animBtn1:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)

    local animBtn2 = self:CreateButton(content, "Green Start", {
        type = "animated",
        textColor = {r = 0.5, g = 0.9, b = 0.5, a = 1},
        onClick = function() KOL:PrintTag("Clicked: Green Start") end
    })
    animBtn2:SetPoint("LEFT", animBtn1, "RIGHT", 20, 0)

    local animBtn3 = self:CreateButton(content, "Slow Rainbow", {
        type = "animated",
        rainbowSpeed = 0.15,
        onClick = function() KOL:PrintTag("Clicked: Slow Rainbow") end
    })
    animBtn3:SetPoint("LEFT", animBtn2, "RIGHT", 20, 0)

    local animBtn4 = self:CreateButton(content, "Fast Rainbow", {
        type = "animated",
        rainbowSpeed = 0.04,
        onClick = function() KOL:PrintTag("Clicked: Fast Rainbow") end
    })
    animBtn4:SetPoint("LEFT", animBtn3, "RIGHT", 20, 0)

    yOffset = yOffset - 40

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

    local section5 = content:CreateFontString(nil, "OVERLAY")
    section5:SetFont(fontPath, 11, fontOutline)
    section5:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section5:SetText("Practical Examples")
    section5:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

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

    local section6 = content:CreateFontString(nil, "OVERLAY")
    section6:SetFont(fontPath, 11, fontOutline)
    section6:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
    section6:SetText("Animated Border Buttons (type=animatedbutton)")
    section6:SetTextColor(0.9, 0.7, 0.3, 1)

    yOffset = yOffset - 25

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

    local contentHeight = math.abs(yOffset) + 20
    content:SetHeight(contentHeight)

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

function UIFactory:CreateFontOutlineDropdown(parent, width, options)
    options = options or {}
    width = width or 150
    local height = 22
    local fontSize = options.fontSize or 11
    local showPreview = options.showPreview ~= false

    local fontPath, _ = GetGeneralFont()

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

    local outlineOptions = {
        { value = "", label = "NONE" },
        { value = "OUTLINE", label = "OUTLINE" },
        { value = "THICKOUTLINE", label = "THICKOUTLINE" },
        { value = "MONOCHROME", label = "MONOCHROME" },
        { value = "OUTLINE, MONOCHROME", label = "OUTLINE + MONO" },
        { value = "THICKOUTLINE, MONOCHROME", label = "THICKOUTLINE + MONO" },
    }

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

    local selectedText = dropdown:CreateFontString(nil, "OVERLAY")
    selectedText:SetFont(fontPath, fontSize, options.selectedValue or "OUTLINE")
    selectedText:SetPoint("LEFT", 6, 0)
    selectedText:SetPoint("RIGHT", -18, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetText("Select Style...")
    selectedText:SetTextColor(0.9, 0.9, 0.9, 1)
    dropdown.text = selectedText
    dropdown.selectedText = selectedText

    local arrow = dropdown:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(CHAR_LIGATURESFONT, fontSize, CHAR_LIGATURESOUTLINE)
    arrow:SetPoint("RIGHT", -5, 0)
    arrow:SetText(CHAR_ARROW_DOWNFILLED)
    arrow:SetTextColor(0.5, 0.5, 0.5, 1)
    dropdown.arrow = arrow

    dropdown.selectedValue = options.selectedValue
    dropdown.items = outlineOptions
    dropdown.onSelect = options.onSelect
    dropdown.bgColor = bgColor
    dropdown.borderColor = borderColor
    dropdown.hoverBorderColor = hoverBorderColor
    dropdown.fontPath = fontPath
    dropdown.fontSize = fontSize
    dropdown.showPreview = showPreview

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

    dropdown:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(self.hoverBorderColor.r, self.hoverBorderColor.g, self.hoverBorderColor.b, 1)
        self.arrow:SetTextColor(0.8, 0.8, 0.8, 1)
    end)
    dropdown:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(self.borderColor.r, self.borderColor.g, self.borderColor.b, 1)
        self.arrow:SetTextColor(0.5, 0.5, 0.5, 1)
    end)

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

    local function PositionList()
        list:ClearAllPoints()
        list:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    end

    dropdown.itemButtons = {}

    local function PopulateList()
        local itemHeight = 22
        local items = dropdown.items

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

            itemBtn:SetScript("OnEnter", function(self)
                self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
                self:SetBackdropColor(0.2, 0.2, 0.2, 1)
                self.itemText:SetTextColor(0.2, 1, 0.8, 1)
            end)

            itemBtn:SetScript("OnLeave", function(self)
                self:SetBackdrop(nil)
                self.itemText:SetTextColor(0.9, 0.9, 0.9, 1)
            end)

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

    dropdown:SetScript("OnClick", function(self)
        if self.isOpen then
            self.list:Hide()
            self.isOpen = false
            self.arrow:SetText(CHAR_ARROW_DOWNFILLED)
        else
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

    list:SetScript("OnUpdate", function(self)
        if dropdown.isOpen and not self:IsMouseOver() and not dropdown:IsMouseOver() then
            if IsMouseButtonDown("LeftButton") then
                self:Hide()
                dropdown.isOpen = false
                dropdown.arrow:SetText(CHAR_ARROW_DOWNFILLED)
            end
        end
    end)

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

function UIFactory:AddTreeSection(treeArgs, sectionKey, config)
    config = config or {}

    local sectionName = config.name or sectionKey
    local headerColor = config.headerColor or "0.8,0.8,0.8"

    local section = {
        type = "group",
        name = sectionName,
        order = config.order or 1,
        args = {}
    }

    section.args.header = {
        type = "description",
        name = sectionName:upper() .. "|" .. headerColor,
        dialogControl = "KOL_SectionHeader",
        width = "full",
        order = 0,
    }

    if config.desc then
        section.args.desc = {
            type = "description",
            name = "|cFFAAAAAA" .. config.desc .. "|r\n",
            fontSize = "small",
            width = "full",
            order = 0.1,
        }
    end

    if config.args then
        for key, value in pairs(config.args) do
            section.args[key] = value
        end
    end

    treeArgs[sectionKey] = section

    return section
end

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

function UIFactory:AddTreeColor(sectionArgs, key, config)
    config = config or {}

    sectionArgs[key] = {
        type = "color",
        name = config.name or key,
        desc = config.desc,
        hasAlpha = config.hasAlpha ~= false,
        order = config.order or 10,
        width = config.width or 0.6,
        get = config.get,
        set = config.set,
        hidden = config.hidden,
        disabled = config.disabled,
    }
end

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
