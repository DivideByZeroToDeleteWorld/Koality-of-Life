-- !Koality-of-Life: Notify Module
-- Advanced notification system with positioning, styling, and attachments

local addonName = "!Koality-of-Life"
local KOL = KoalityOfLife

-- Create module
local Notify = {}
KOL.notify = Notify

-- Storage for active notifications
local activeNotifications = {}
local locationPickerFrame = nil

-- ============================================================================
-- Helper Functions - Parsing
-- ============================================================================

-- Parse position string like "450,-110" into x,y coordinates
function Notify:ParsePosition(positionStr)
    KOL:DebugPrint("Notify:ParsePosition - Input: '" .. tostring(positionStr) .. "'")

    if not positionStr or positionStr == "" then
        KOL:DebugPrint("Notify:ParsePosition - Empty input, defaulting to 0,0")
        return 0, 0
    end

    local x, y = string.match(positionStr, "([^,]+),([^,]+)")

    if not x or not y then
        KOL:DebugPrint("Notify: Invalid position format '" .. positionStr .. "', expected 'x,y'")
        return 0, 0
    end

    local numX, numY = tonumber(x) or 0, tonumber(y) or 0
    KOL:DebugPrint("Notify:ParsePosition - Parsed: x=" .. numX .. ", y=" .. numY)
    return numX, numY
end

-- Parse duration string like "5s" or "INF"
function Notify:ParseDuration(durationStr)
    KOL:DebugPrint("Notify:ParseDuration - Input: '" .. tostring(durationStr) .. "'")

    if not durationStr or durationStr == "" then
        KOL:DebugPrint("Notify:ParseDuration - Empty input, defaulting to 5s")
        return 5  -- Default 5 seconds
    end

    if durationStr == "INF" then
        KOL:DebugPrint("Notify:ParseDuration - Infinite duration")
        return nil  -- nil means infinite
    end

    local seconds = string.match(durationStr, "(%d+)s")
    if seconds then
        local num = tonumber(seconds)
        KOL:DebugPrint("Notify:ParseDuration - Parsed: " .. num .. " seconds")
        return num
    end

    KOL:DebugPrint("Notify: Invalid duration format '" .. durationStr .. "', expected '5s' or 'INF'")
    return 5
end

-- Parse style string like "FLASH-1S", "BORDER-DASHED-2PX", "NOFLASH"
function Notify:ParseStyle(styleStr)
    KOL:DebugPrint("Notify:ParseStyle - Input: '" .. tostring(styleStr) .. "'")

    local style = {
        flash = false,
        flashInterval = 0.25,  -- Default fast flash (0.25 seconds = 4 flashes per second)
        border = false,
        borderType = "FULL",  -- FULL or DASHED
        borderThickness = 2,
    }

    if not styleStr or styleStr == "" or styleStr == "NOFLASH" then
        KOL:DebugPrint("Notify:ParseStyle - No style or NOFLASH, using defaults")
        return style
    end

    -- Split by commas for multiple styles
    for part in string.gmatch(styleStr, "[^,]+") do
        -- Trim whitespace manually (string.trim doesn't exist in Lua 5.1)
        part = string.match(part, "^%s*(.-)%s*$")

        -- Parse FLASH
        if string.find(part, "FLASH") then
            style.flash = true
            local interval = string.match(part, "FLASH%-(%d+)[Ss]")
            if interval then
                style.flashInterval = tonumber(interval)
            end
            KOL:DebugPrint("Notify:ParseStyle - Flash enabled, interval=" .. style.flashInterval)
        end

        -- Parse BORDER
        if string.find(part, "BORDER") then
            style.border = true

            -- Check for DASHED or FULL
            if string.find(part, "DASHED") then
                style.borderType = "DASHED"
            elseif string.find(part, "FULL") then
                style.borderType = "FULL"
            end

            -- Check for thickness
            local thickness = string.match(part, "(%d+)PX")
            if thickness then
                style.borderThickness = tonumber(thickness)
            end
            KOL:DebugPrint("Notify:ParseStyle - Border enabled, type=" .. style.borderType .. ", thickness=" .. style.borderThickness)
        end
    end

    return style
end

-- Parse attachTo string like "KOL-NOTIFY-1 Left Right"
function Notify:ParseAttachTo(attachToStr)
    if not attachToStr or attachToStr == "" then
        return nil
    end

    local targetName, thisAnchor, targetAnchor = string.match(attachToStr, "(%S+)%s+(%S+)%s+(%S+)")

    if not targetName or not thisAnchor or not targetAnchor then
        KOL:DebugPrint("Notify: Invalid attachTo format '" .. attachToStr .. "', expected 'TargetName ThisAnchor TargetAnchor'")
        return nil
    end

    return {
        targetName = targetName,
        thisAnchor = string.upper(thisAnchor),
        targetAnchor = string.upper(targetAnchor),
    }
end

-- Parse sound string like "RaidWarning" or "RaidWarning:LOOP" or "RaidWarning:LOOP:6S"
function Notify:ParseSound(soundStr)
    KOL:DebugPrint("Notify:ParseSound - Input: '" .. tostring(soundStr) .. "'")

    if not soundStr or soundStr == "" then
        KOL:DebugPrint("Notify:ParseSound - No sound specified")
        return nil
    end

    local sound = {
        soundName = soundStr,
        loop = false,
        loopInterval = 3.0,  -- Default 3 seconds
    }

    -- Split by colons
    local parts = {}
    for part in string.gmatch(soundStr, "[^:]+") do
        table.insert(parts, part)
    end

    -- First part is always the sound name
    sound.soundName = parts[1]

    -- Check for LOOP flag (second part)
    if parts[2] and string.upper(parts[2]) == "LOOP" then
        sound.loop = true
        KOL:DebugPrint("Notify:ParseSound - Loop enabled for sound: " .. sound.soundName)

        -- Check for custom interval (third part like "6S")
        if parts[3] then
            local seconds = string.match(parts[3], "^(%d+)[Ss]$")
            if seconds then
                sound.loopInterval = tonumber(seconds)
                KOL:DebugPrint("Notify:ParseSound - Custom loop interval: " .. sound.loopInterval .. "s")
            else
                KOL:DebugPrint("Notify:ParseSound - Invalid interval format '" .. parts[3] .. "', using default 3s")
            end
        end
    end

    KOL:DebugPrint("Notify:ParseSound - Parsed: sound=" .. sound.soundName .. ", loop=" .. tostring(sound.loop) .. ", interval=" .. sound.loopInterval .. "s")
    return sound
end

-- Parse content and split into lines with justification
function Notify:ParseContent(content)
    KOL:DebugPrint("Notify:ParseContent - Input length: " .. (content and string.len(content) or 0))
    KOL:DebugPrint("Notify:ParseContent - Raw content: " .. tostring(content))

    if not content then
        KOL:DebugPrint("Notify:ParseContent - No content provided!")
        return {}
    end

    -- FIRST: Handle double-escaped sequences (\\n should stay as literal \n in output)
    content = string.gsub(content, "\\\\n", "\001ESCAPED_NEWLINE\001")
    content = string.gsub(content, "\\\\L", "\001ESCAPED_L\001")
    content = string.gsub(content, "\\\\C", "\001ESCAPED_C\001")
    content = string.gsub(content, "\\\\R", "\001ESCAPED_R\001")

    -- SECOND: Convert single \n to actual newline characters for splitting
    content = string.gsub(content, "\\n", "\n")
    KOL:DebugPrint("Notify:ParseContent - After newline conversion: " .. tostring(content))

    -- Split by actual newline characters
    local lines = {}
    for line in string.gmatch(content .. "\n", "(.-)\n") do
        local justify = "LEFT"  -- Default justification

        -- Check for justification codes at START of line only
        if string.sub(line, 1, 2) == "\\C" then
            justify = "CENTER"
            line = string.sub(line, 3)
        elseif string.sub(line, 1, 2) == "\\R" then
            justify = "RIGHT"
            line = string.sub(line, 3)
        elseif string.sub(line, 1, 2) == "\\L" then
            justify = "LEFT"
            line = string.sub(line, 3)
        end

        -- Restore escaped sequences
        line = string.gsub(line, "\001ESCAPED_NEWLINE\001", "\\n")
        line = string.gsub(line, "\001ESCAPED_L\001", "\\L")
        line = string.gsub(line, "\001ESCAPED_C\001", "\\C")
        line = string.gsub(line, "\001ESCAPED_R\001", "\\R")

        KOL:DebugPrint("Notify:ParseContent - Line " .. #lines+1 .. ": '" .. line .. "' (justify=" .. justify .. ")")

        table.insert(lines, {
            text = line,
            justify = justify,
        })
    end

    KOL:DebugPrint("Notify:ParseContent - Parsed " .. #lines .. " lines")
    return lines
end

-- ============================================================================
-- Font Management (SharedMedia Integration)
-- ============================================================================

function Notify:GetFont(fontName, outline)
    local fontPath = "Fonts\\FRIZQT__.TTF"  -- Default WoW font
    local outlineFlag = ""

    -- Try to use SharedMedia if available
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM and fontName and fontName ~= "" then
        local mediaFont = LSM:Fetch("font", fontName)
        if mediaFont then
            fontPath = mediaFont
            KOL:DebugPrint("Notify: Using SharedMedia font: " .. fontName)
        else
            KOL:DebugPrint("Notify: Font '" .. fontName .. "' not found in SharedMedia, using default")
        end
    end

    -- Parse outline
    if outline then
        outline = string.upper(outline)
        if outline == "THICK" then
            outlineFlag = "THICKOUTLINE"
        elseif outline == "OUTLINE" then
            outlineFlag = "OUTLINE"
        elseif outline == "NONE" then
            outlineFlag = ""
        else
            outlineFlag = ""
        end
    end

    return fontPath, outlineFlag
end

-- ============================================================================
-- Frame Creation - TEXT Type
-- ============================================================================

function Notify:CreateTextFrame(name, position, duration, style, lines, fontName, outline)
    KOL:DebugPrint("Notify:CreateTextFrame - Starting frame creation for '" .. name .. "'")

    local x, y = self:ParsePosition(position)
    KOL:DebugPrint("Notify:CreateTextFrame - Position: " .. x .. "," .. y)

    -- Create main frame
    KOL:DebugPrint("Notify:CreateTextFrame - Creating frame with name '" .. name .. "'")
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    frame:SetFrameStrata("HIGH")
    KOL:DebugPrint("Notify:CreateTextFrame - Frame created successfully")

    -- Get font settings
    local fontPath, outlineFlag = self:GetFont(fontName, outline)
    KOL:DebugPrint("Notify:CreateTextFrame - Font: " .. fontPath .. ", Outline: " .. outlineFlag)

    -- Create text elements for each line
    local textElements = {}
    local totalHeight = 0
    local maxWidth = 0

    KOL:DebugPrint("Notify:CreateTextFrame - Creating " .. #lines .. " text lines...")

    -- FIRST PASS: Create all text elements and calculate maxWidth
    for i, lineData in ipairs(lines) do
        local text = frame:CreateFontString(nil, "OVERLAY")
        text:SetFont(fontPath, 24, outlineFlag)

        -- Set default yellow color FIRST
        text:SetTextColor(1, 1, 0, 1)  -- Yellow (R=1, G=1, B=0, A=1)

        -- Then set text (WoW color codes like |cFFRRGGBB will override if present)
        text:SetText(lineData.text)

        -- Calculate size
        local width = text:GetStringWidth()
        local height = text:GetStringHeight()

        maxWidth = math.max(maxWidth, width)
        totalHeight = totalHeight + height + 5

        KOL:DebugPrint("Notify:CreateTextFrame - Line " .. i .. ": w=" .. width .. ", h=" .. height .. ", justify=" .. lineData.justify)

        table.insert(textElements, text)
    end

    -- Set frame size
    frame:SetSize(maxWidth + 20, totalHeight + 10)
    KOL:DebugPrint("Notify:CreateTextFrame - Frame size: " .. (maxWidth + 20) .. "x" .. (totalHeight + 10))

    -- SECOND PASS: Position and justify all text elements now that we know maxWidth
    for i, text in ipairs(textElements) do
        local lineData = lines[i]

        -- Set width to maxWidth so justification works
        text:SetWidth(maxWidth)

        -- Justify
        if lineData.justify == "CENTER" then
            text:SetJustifyH("CENTER")
        elseif lineData.justify == "RIGHT" then
            text:SetJustifyH("RIGHT")
        else
            text:SetJustifyH("LEFT")
        end

        -- Position
        if i == 1 then
            text:SetPoint("TOP", frame, "TOP", 0, 0)
        else
            text:SetPoint("TOP", textElements[i-1], "BOTTOM", 0, -5)
        end
    end

    -- NO background by default (user can add border if they want visual separation)

    -- Add border if requested
    if style.border then
        KOL:DebugPrint("Notify:CreateTextFrame - Adding border...")
        self:AddBorder(frame, style)
    end

    -- Add flashing if requested
    if style.flash then
        KOL:DebugPrint("Notify:CreateTextFrame - Adding flashing effect...")
        self:AddFlashing(frame, textElements, style.flashInterval)
    end

    frame:Show()
    KOL:DebugPrint("Notify:CreateTextFrame - Frame shown!")

    return frame, textElements
end

-- ============================================================================
-- Frame Creation - IMAGE Type
-- ============================================================================

function Notify:CreateImageFrame(name, position, duration, style, imagePath)
    local x, y = self:ParsePosition(position)

    -- Create main frame
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    frame:SetFrameStrata("HIGH")

    -- Default size for images
    frame:SetSize(64, 64)

    -- Create texture
    local texture = frame:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexture(imagePath)
    frame.texture = texture

    -- Add border if requested
    if style.border then
        self:AddBorder(frame, style)
    end

    -- Add flashing if requested
    if style.flash then
        self:AddFlashing(frame, {texture}, style.flashInterval)
    end

    frame:Show()

    return frame
end

-- ============================================================================
-- Frame Styling - Border
-- ============================================================================

function Notify:AddBorder(frame, style)
    local thickness = style.borderThickness or 2

    if style.borderType == "DASHED" then
        -- Create dashed border (4 segments per side)
        local segments = {}
        local segmentLength = 0.2  -- 20% of side length
        local gapLength = 0.05     -- 5% gap

        -- Top border (dashed)
        for i = 1, 4 do
            local segment = frame:CreateTexture(nil, "OVERLAY")
            segment:SetTexture(1, 1, 1, 1)
            segment:SetHeight(thickness)
            local offset = (i - 1) * (segmentLength + gapLength)
            segment:SetPoint("TOPLEFT", frame, "TOPLEFT", offset, 0)
            segment:SetPoint("TOPRIGHT", frame, "TOPLEFT", offset + segmentLength, 0)
            table.insert(segments, segment)
        end

        -- Similar for bottom, left, right...
        -- (simplified for now)

        frame.borderSegments = segments
    else
        -- Full border (4 lines)
        local borderTop = frame:CreateTexture(nil, "OVERLAY")
        borderTop:SetTexture(1, 1, 1, 1)
        borderTop:SetHeight(thickness)
        borderTop:SetPoint("TOPLEFT", frame, "TOPLEFT")
        borderTop:SetPoint("TOPRIGHT", frame, "TOPRIGHT")

        local borderBottom = frame:CreateTexture(nil, "OVERLAY")
        borderBottom:SetTexture(1, 1, 1, 1)
        borderBottom:SetHeight(thickness)
        borderBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
        borderBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

        local borderLeft = frame:CreateTexture(nil, "OVERLAY")
        borderLeft:SetTexture(1, 1, 1, 1)
        borderLeft:SetWidth(thickness)
        borderLeft:SetPoint("TOPLEFT", frame, "TOPLEFT")
        borderLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")

        local borderRight = frame:CreateTexture(nil, "OVERLAY")
        borderRight:SetTexture(1, 1, 1, 1)
        borderRight:SetWidth(thickness)
        borderRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
        borderRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

        frame.borderTop = borderTop
        frame.borderBottom = borderBottom
        frame.borderLeft = borderLeft
        frame.borderRight = borderRight
    end
end

-- ============================================================================
-- Frame Styling - Flashing
-- ============================================================================

function Notify:AddFlashing(frame, elements, interval)
    frame.flashElapsed = 0
    frame.flashInterval = interval
    frame.flashVisible = true
    frame.flashElements = elements

    frame:SetScript("OnUpdate", function(self, elapsed)
        self.flashElapsed = self.flashElapsed + elapsed

        if self.flashElapsed >= self.flashInterval then
            self.flashElapsed = 0
            self.flashVisible = not self.flashVisible

            local alpha = self.flashVisible and 1 or 0
            for _, element in ipairs(self.flashElements) do
                element:SetAlpha(alpha)
            end
        end
    end)
end

-- ============================================================================
-- Sound Playback
-- ============================================================================

function Notify:PlaySound(soundData, notificationName)
    if not soundData then
        return
    end

    KOL:DebugPrint("Notify:PlaySound - Playing sound: " .. soundData.soundName)

    -- Play sound once
    PlaySound(soundData.soundName)

    -- If looping, set up repeating timer
    if soundData.loop then
        local loopInterval = soundData.loopInterval or 3.0
        KOL:DebugPrint("Notify:PlaySound - Setting up loop for sound: " .. soundData.soundName .. " (every " .. loopInterval .. "s)")

        local function loopSound()
            -- Check if notification still exists
            if activeNotifications[notificationName] then
                PlaySound(soundData.soundName)
                -- Schedule next loop
                activeNotifications[notificationName].soundLoopTimer = C_Timer.After(loopInterval, loopSound)
            end
        end

        -- Start the loop
        activeNotifications[notificationName].soundLoopTimer = C_Timer.After(loopInterval, loopSound)
    end
end

function Notify:StopSound(notificationName)
    local notification = activeNotifications[notificationName]
    if notification and notification.soundLoopTimer then
        KOL:DebugPrint("Notify:StopSound - Canceling sound loop for: " .. notificationName)
        -- Note: WoW 3.3.5a doesn't have timer:Cancel(), but the function check prevents further loops
        notification.soundLoopTimer = nil
    end
end

-- ============================================================================
-- Main Notify Function
-- ============================================================================

function KOL:Notify(name, notifyType, position, duration, style, content, font, outline, attachTo, sound)
    self:DebugPrint("=== KOL:Notify CALLED ===")
    self:DebugPrint("  name: " .. tostring(name))
    self:DebugPrint("  type: " .. tostring(notifyType))
    self:DebugPrint("  position: " .. tostring(position))
    self:DebugPrint("  duration: " .. tostring(duration))
    self:DebugPrint("  style: " .. tostring(style))
    self:DebugPrint("  content: " .. tostring(content))
    self:DebugPrint("  font: " .. tostring(font))
    self:DebugPrint("  outline: " .. tostring(outline))
    self:DebugPrint("  attachTo: " .. tostring(attachTo))
    self:DebugPrint("  sound: " .. tostring(sound))

    -- Validate required parameters
    if not name or name == "" then
        self:PrintTag(RED("Error:") .. " KOL:Notify requires a notification name")
        self:DebugPrint("ERROR: Missing name parameter")
        return false
    end

    if not notifyType or (notifyType ~= "TEXT" and notifyType ~= "IMAGE") then
        self:PrintTag(RED("Error:") .. " KOL:Notify type must be 'TEXT' or 'IMAGE'")
        self:DebugPrint("ERROR: Invalid notifyType: " .. tostring(notifyType))
        return false
    end

    if not content or content == "" then
        self:PrintTag(RED("Error:") .. " KOL:Notify requires content")
        self:DebugPrint("ERROR: Missing content parameter")
        return false
    end

    -- Remove existing notification with same name
    if activeNotifications[name] then
        self:DebugPrint("Notify: Removing existing notification '" .. name .. "'")
        Notify:RemoveNotification(name)
    end

    -- Parse parameters
    self:DebugPrint("Parsing parameters...")
    local durationSeconds = Notify:ParseDuration(duration)
    local styleData = Notify:ParseStyle(style)
    local attachData = Notify:ParseAttachTo(attachTo)
    local soundData = Notify:ParseSound(sound)

    self:DebugPrint("Notify: Creating '" .. name .. "' type=" .. notifyType .. " duration=" .. tostring(durationSeconds or "INF"))

    local frame = nil

    -- Create frame based on type
    if notifyType == "TEXT" then
        self:DebugPrint("Creating TEXT notification...")
        local lines = Notify:ParseContent(content)
        self:DebugPrint("Content parsed into " .. #lines .. " lines, calling CreateTextFrame...")
        frame = Notify:CreateTextFrame(name, position, durationSeconds, styleData, lines, font, outline)
    elseif notifyType == "IMAGE" then
        self:DebugPrint("Creating IMAGE notification...")
        frame = Notify:CreateImageFrame(name, position, durationSeconds, styleData, content)
    end

    if not frame then
        self:PrintTag(RED("Error:") .. " Failed to create notification frame")
        self:DebugPrint("ERROR: CreateFrame returned nil!")
        return false
    end

    self:DebugPrint("Frame created successfully!")

    -- Handle attachTo
    if attachData then
        local targetFrame = activeNotifications[attachData.targetName]
        if targetFrame and targetFrame.frame then
            frame:ClearAllPoints()
            frame:SetPoint(attachData.thisAnchor, targetFrame.frame, attachData.targetAnchor, 0, 0)
            self:DebugPrint("Notify: Attached '" .. name .. "' to '" .. attachData.targetName .. "'")
        else
            self:DebugPrint("Notify: Target frame '" .. attachData.targetName .. "' not found, using position instead")
        end
    end

    -- Store notification
    activeNotifications[name] = {
        frame = frame,
        createdAt = GetTime(),
        duration = durationSeconds,
        soundLoopTimer = nil,
    }
    self:DebugPrint("Notification stored in activeNotifications['" .. name .. "']")

    -- Play sound (if specified)
    if soundData then
        self:DebugPrint("Playing sound for notification...")
        Notify:PlaySound(soundData, name)
    end

    -- Set up auto-removal (if not infinite)
    if durationSeconds then
        self:DebugPrint("Setting up auto-removal timer for " .. durationSeconds .. " seconds")
        C_Timer.After(durationSeconds, function()
            Notify:RemoveNotification(name)
        end)
    end

    self:DebugPrint("=== KOL:Notify COMPLETED SUCCESSFULLY ===")
    return true
end

-- ============================================================================
-- Remove Notification
-- ============================================================================

function Notify:RemoveNotification(name)
    local notification = activeNotifications[name]
    if not notification then
        return
    end

    KOL:DebugPrint("Notify: Removing notification '" .. name .. "'")

    -- Stop any looping sound
    self:StopSound(name)

    -- Hide and destroy frame
    if notification.frame then
        notification.frame:Hide()
        notification.frame:SetScript("OnUpdate", nil)
        notification.frame = nil
    end

    activeNotifications[name] = nil
end

-- Public API for removing notifications
function KOL:NotifyRemove(name)
    return Notify:RemoveNotification(name)
end

-- ============================================================================
-- Location Picker Tool
-- ============================================================================

function Notify:ShowLocationPicker()
    if locationPickerFrame then
        KOL:PrintTag(YELLOW("Location picker already active! Right-click it to close."))
        return
    end

    KOL:PrintTag("Location picker spawned at screen center. " .. YELLOW("Left-click drag") .. " to move, " .. YELLOW("Right-click") .. " to get coordinates.")

    -- Create picker frame (15x15)
    locationPickerFrame = CreateFrame("Frame", "KOL_LocationPicker", UIParent)
    locationPickerFrame:SetSize(15, 15)
    locationPickerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    locationPickerFrame:SetFrameStrata("DIALOG")
    locationPickerFrame:SetMovable(true)
    locationPickerFrame:EnableMouse(true)
    locationPickerFrame:RegisterForDrag("LeftButton")

    -- Background (Nuclear Purple, semi-transparent)
    local bg = locationPickerFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0.6, 0, 1, 0.5)  -- Purple with 50% alpha

    -- Border (Nuclear Green)
    local border = locationPickerFrame:CreateTexture(nil, "BORDER")
    border:SetTexture(0, 1, 0, 1)  -- Bright green
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)

    -- Drag behavior
    locationPickerFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    locationPickerFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Right-click to get coordinates and close
    locationPickerFrame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            -- Get position relative to screen center
            local x, y = self:GetCenter()
            local screenWidth = UIParent:GetWidth()
            local screenHeight = UIParent:GetHeight()
            local centerX = screenWidth / 2
            local centerY = screenHeight / 2

            local relativeX = math.floor(x - centerX)
            local relativeY = math.floor(y - centerY)

            KOL:PrintTag("Location: " .. YELLOW(relativeX .. "," .. relativeY))
            KOL:PrintTag("Use this in KOL:Notify(..., \"" .. relativeX .. "," .. relativeY .. "\", ...)")

            -- Destroy picker
            self:Hide()
            locationPickerFrame = nil
        end
    end)

    locationPickerFrame:Show()
end

-- ============================================================================
-- Module Initialization
-- ============================================================================

function Notify:Initialize()
    -- Register slash command for location picker
    if KOL.RegisterSlashCommand then
        KOL:RegisterSlashCommand("location", function()
            Notify:ShowLocationPicker()
        end, "Open location picker tool for positioning notifications")
    end

    KOL:DebugPrint("Notify: Module initialized")
end

-- ============================================================================
-- Event Registration & Frame
-- ============================================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" and KOL.db then
        Notify:Initialize()
    end
end)

-- OnUpdate for buff monitoring
frame:SetScript("OnUpdate", function(self, elapsed)
    Notify:CheckDungeonChallengeBuff()
end)

-- ============================================================================
-- Dungeon Challenge Time Tracker
-- ============================================================================

-- State for tracking dungeon challenge buff
local dungeonChallengeState = {
    hadBuff = false,
    scanScheduled = false,
}

-- Parse time string like "04:54" into seconds
local function ParseTimeToSeconds(timeStr)
    local minutes, seconds = string.match(timeStr, "(%d+):(%d+)")
    if minutes and seconds then
        return tonumber(minutes) * 60 + tonumber(seconds)
    end
    return nil
end

-- Check if player has Dungeon Challenge buff
local function HasDungeonChallengeBuff()
    local i = 1
    while true do
        local name = UnitBuff("player", i)
        if not name then
            break
        end

        if name == "Dungeon Challenge" then
            return true
        end

        i = i + 1
    end
    return false
end

-- Scan chat history for dungeon completion messages
function Notify:ScanChatForDungeonCompletion()
    KOL:DebugPrint("Scanning chat history for dungeon completion messages...")

    local currentTime = nil
    local previousTime = nil

    -- Get the default chat frame
    local chatFrame = DEFAULT_CHAT_FRAME
    if not chatFrame then
        KOL:DebugPrint("ERROR: Could not find chat frame!")
        return
    end

    -- Scan the last 100 messages in chat history
    local messageCount = chatFrame:GetNumMessages()
    KOL:DebugPrint("Chat frame has " .. messageCount .. " messages")

    for i = math.max(1, messageCount - 100), messageCount do
        local message = chatFrame:GetMessageInfo(i)
        if message then
            -- Check for completion time
            local completedTime = string.match(message, "You completed this dungeon challenge in (%d+:%d+)!")
            if completedTime then
                currentTime = completedTime
                KOL:DebugPrint("Found completion time in chat history: " .. completedTime)
            end

            -- Check for previous best time
            local bestTime = string.match(message, "Your previous best time was (%d+:%d+)")
            if bestTime then
                previousTime = bestTime
                KOL:DebugPrint("Found previous time in chat history: " .. bestTime)
            end
        end
    end

    -- If we found both messages, process them
    if currentTime and previousTime then
        local currentSeconds = ParseTimeToSeconds(currentTime)
        local previousSeconds = ParseTimeToSeconds(previousTime)

        if currentSeconds and previousSeconds then
            local isFaster = currentSeconds < previousSeconds

            KOL:DebugPrint("Current: " .. currentSeconds .. "s, Previous: " .. previousSeconds .. "s, Faster: " .. tostring(isFaster))

            -- Create notification based on comparison
            if isFaster then
                -- FASTER TIME - Green current, Yellow previous, Flash, LevelUp sound
                local content = "\\C|cFFFFFFFFYou have completed the dungeon challenge faster than previous!|r\\n" ..
                                "\\C|cFF00FF00" .. currentTime .. "|r  |cFFFFFFFF(Previous: |cFFFFFF00" .. previousTime .. "|cFFFFFFFF)|r"

                KOL:Notify("DUNGEON-CHALLENGE-FASTER", "TEXT", "30,320", "5s", "FLASH",
                    content, "Expressway", "THICK", nil, "LevelUp")
            else
                -- SLOWER TIME - Red current, Green previous, No flash, No sound
                local content = "\\C|cFFFFFFFFDungeon challenge completed!|r\\n" ..
                                "\\C|cFFFF0000" .. currentTime .. "|r  |cFFFFFFFF(Previous: |cFF00FF00" .. previousTime .. "|cFFFFFFFF)|r"

                KOL:Notify("DUNGEON-CHALLENGE-SLOWER", "TEXT", "30,320", "5s", "NOFLASH",
                    content, "Expressway", "THICK", nil, nil)
            end
        else
            KOL:DebugPrint("ERROR: Failed to parse time strings")
        end
    else
        KOL:DebugPrint("Could not find both messages in chat history (current: " .. tostring(currentTime) .. ", previous: " .. tostring(previousTime) .. ")")
    end
end

-- Check for Dungeon Challenge buff on each update
function Notify:CheckDungeonChallengeBuff()
    local hasBuff = HasDungeonChallengeBuff()

    -- Detect when buff expires (had it before, don't have it now)
    if dungeonChallengeState.hadBuff and not hasBuff and not dungeonChallengeState.scanScheduled then
        KOL:DebugPrint("Dungeon Challenge buff expired! Scheduling chat scan in 3 seconds...")
        dungeonChallengeState.scanScheduled = true

        -- Wait 3 seconds for the messages to appear, then scan chat
        C_Timer.After(3.0, function()
            Notify:ScanChatForDungeonCompletion()
            dungeonChallengeState.scanScheduled = false
        end)
    end

    -- Update state
    dungeonChallengeState.hadBuff = hasBuff
end

-- ============================================================================
-- Module Complete
-- ============================================================================
