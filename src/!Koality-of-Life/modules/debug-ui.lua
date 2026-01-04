-- ============================================================================
-- Debug Console UI
-- ============================================================================
-- A dedicated window for debug output instead of spamming chat
-- ============================================================================

local KOL = KoalityOfLife
local LSM = LibStub("LibSharedMedia-3.0")
local UIFactory = KOL.UIFactory

-- Debug message storage
local debugMessages = {}

-- Reference to console frame
local consoleFrame = nil

-- Reference to floating debug button
local debugButton = nil

-- Rainbow colors (same as tag)
local rainbowColors = {
    {r = 1.00, g = 0.00, b = 0.00}, -- FF0000
    {r = 1.00, g = 0.27, b = 0.00}, -- FF4400
    {r = 1.00, g = 0.53, b = 0.00}, -- FF8800
    {r = 1.00, g = 0.80, b = 0.00}, -- FFCC00
    {r = 1.00, g = 1.00, b = 0.00}, -- FFFF00
    {r = 0.80, g = 1.00, b = 0.00}, -- CCFF00
    {r = 0.53, g = 1.00, b = 0.00}, -- 88FF00
    {r = 0.27, g = 1.00, b = 0.00}, -- 44FF00
    {r = 0.00, g = 1.00, b = 0.00}, -- 00FF00
    {r = 0.00, g = 1.00, b = 0.53}, -- 00FF88
    {r = 0.00, g = 1.00, b = 1.00}, -- 00FFFF
    {r = 0.33, g = 0.67, b = 1.00}, -- 55AAFF
    {r = 0.47, g = 0.60, b = 1.00}, -- 7799FF
    {r = 0.53, g = 0.53, b = 1.00}, -- 8888FF
    {r = 0.67, g = 0.40, b = 1.00}, -- AA66FF
}

local rainbowIndex = 1

-- ============================================================================
-- Helper Functions
-- ============================================================================

local function GetDebugFont()
    local fontName = KOL.db.profile.debugFont or "JetBrains Mono"
    local fontOutline = KOL.db.profile.debugFontOutline or "THICKOUTLINE"
    local fontPath = LSM:Fetch("font", fontName)
    return fontPath, fontOutline
end

-- Level colors
local levelColors = {
    [1] = {r = 1.0, g = 0.3, b = 0.3},   -- Level 1 - Red
    [2] = {r = 1.0, g = 0.7, b = 0.3},   -- Level 2 - Orange
    [3] = {r = 1.0, g = 1.0, b = 0.5},   -- Level 3 - Yellow
    [4] = {r = 0.6, g = 0.8, b = 1.0},   -- Level 4 - Light Blue
    [5] = {r = 0.5, g = 0.5, b = 0.5},   -- Level 5 - Gray
}

local function GetLevelColor(level)
    return levelColors[level] or levelColors[3]
end

-- ============================================================================
-- Message Management
-- ============================================================================

-- Throttle update frequency
local lastUpdateTime = 0
local UPDATE_THROTTLE = 0.1  -- Max 10 updates per second

local function AddDebugMessage(message, level)
    local timestamp = date("%H:%M:%S")
    local entry = {
        time = timestamp,
        message = message,
        level = level or 1,
        fullTimestamp = GetTime()
    }

    table.insert(debugMessages, entry)

    -- Trim old messages based on configured limit (reduced default to prevent memory issues)
    local maxLines = (KOL.db and KOL.db.profile.debugMaxLines) or 500
    while #debugMessages > maxLines do
        table.remove(debugMessages, 1)
    end

    -- Throttled update: Only update console if visible AND enough time has passed
    if consoleFrame and consoleFrame:IsVisible() and not consoleFrame.updatesPaused then
        local currentTime = GetTime()
        if currentTime - lastUpdateTime >= UPDATE_THROTTLE then
            lastUpdateTime = currentTime
            UpdateConsoleDisplay()
        end
    end
end

-- Store reference on KOL so other modules can use it
KOL.AddDebugMessage = AddDebugMessage

-- Expose message count for stats
function KOL.DebugGetMessageCount()
    return #debugMessages
end

-- ============================================================================
-- Console UI Creation
-- ============================================================================

local function CreateConsoleFrame()
    if consoleFrame then
        return consoleFrame
    end

    -- Main frame using UIFactory (auto-registered, movable, closable)
    local frame = UIFactory:CreateStyledFrame(UIParent, "KOL_DebugConsole", 700, 500, {
        movable = true,
        closable = true,
        strata = UIFactory.STRATA.MODAL,  -- High strata to always be on top
        bgColor = {r = 0.02, g = 0.02, b = 0.02, a = 0.98},
    })
    frame:SetPoint("CENTER")

    -- Title bar using UIFactory
    local titleBar, title, titleCloseBtn = UIFactory:CreateTitleBar(frame, 20, "Debug Console", {
        showCloseButton = true,
    })
    frame.title = title

    -- Message count (on title bar, right side)
    local fontPath, fontOutline = GetDebugFont()
    local messageCount = frame:CreateFontString(nil, "OVERLAY")
    messageCount:SetFont(fontPath, 10, fontOutline)
    messageCount:SetPoint("RIGHT", titleBar, "RIGHT", -26, 0)  -- Leave room for X button
    messageCount:SetTextColor(0.7, 0.7, 0.7, 1)
    frame.messageCount = messageCount

    -- Content area using UIFactory
    local contentBG = UIFactory:CreateContentArea(frame, {top = 24, bottom = 40, left = 8, right = 8})

    -- Scroll frame for messages
    local scrollFrame = CreateFrame("ScrollFrame", "KOL_DebugConsoleScroll", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentBG, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentBG, "BOTTOMRIGHT", -28, 8)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 10)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    frame.scrollChild = scrollChild
    frame.scrollFrame = scrollFrame

    -- Text container for messages (use EditBox for selectability like Copy Chat)
    local messageText = CreateFrame("EditBox", nil, scrollChild)
    messageText:SetMultiLine(true)
    messageText:SetMaxLetters(0)
    messageText:SetFont(fontPath, 11, fontOutline)
    messageText:SetPoint("TOPLEFT", 5, -5)
    messageText:SetPoint("TOPRIGHT", -5, -5)
    messageText:SetAutoFocus(false)
    messageText:EnableMouse(true)
    messageText:SetTextInsets(0, 0, 0, 0)

    -- Make it read-only but selectable
    messageText:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    messageText:SetScript("OnEditFocusGained", function(self)
        -- Allow selection
    end)
    messageText:SetScript("OnEditFocusLost", function(self)
        -- Keep selection visible
    end)

    frame.messageText = messageText

    -- Buttons using UIFactory
    local buttonY = 8
    frame.updatesPaused = false

    -- Pause Updates button (styled button with toggle behavior)
    local pauseButton = UIFactory:CreateButton(frame, "Pause Updates", {
        type = "styled",
        width = 110,
        height = 25,
        bgColor = {r = 0.8, g = 0.6, b = 0.2, a = 1},
        onClick = function(self)
            frame.updatesPaused = not frame.updatesPaused
            if frame.updatesPaused then
                self.text:SetText("Resume Updates")
                self:SetBackdropColor(0.2, 0.6, 0.2, 1)  -- Green when paused
                KOL:PrintTag("Debug console updates " .. RED("PAUSED"))
            else
                self.text:SetText("Pause Updates")
                self:SetBackdropColor(0.8, 0.6, 0.2, 1)  -- Orange when active
                UpdateConsoleDisplay()
                KOL:PrintTag("Debug console updates " .. GREEN("RESUMED"))
            end
        end,
    })
    pauseButton:SetPoint("BOTTOMLEFT", 10, buttonY)
    frame.pauseButton = pauseButton

    -- Clear button
    local clearButton = UIFactory:CreateButton(frame, "Clear", {
        type = "styled",
        width = 80,
        height = 25,
        bgColor = {r = 0.8, g = 0.4, b = 0.4, a = 1},
        onClick = function()
            debugMessages = {}
            UpdateConsoleDisplay()
            KOL:PrintTag("Debug console cleared")
        end,
    })
    clearButton:SetPoint("LEFT", pauseButton, "RIGHT", 5, 0)

    -- Close button
    local closeButton = UIFactory:CreateButton(frame, "Close", {
        type = "styled",
        width = 80,
        height = 25,
        bgColor = {r = 0.8, g = 0.4, b = 0.4, a = 1},
        onClick = function() frame:Hide() end,
    })
    closeButton:SetPoint("BOTTOMRIGHT", -10, buttonY)

    -- Auto-scroll checkbox
    local autoScrollCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    autoScrollCheck:SetPoint("BOTTOM", 0, buttonY + 3)
    autoScrollCheck:SetWidth(20)
    autoScrollCheck:SetHeight(20)
    autoScrollCheck:SetChecked(true)
    frame.autoScroll = autoScrollCheck

    local autoScrollLabel = frame:CreateFontString(nil, "OVERLAY")
    autoScrollLabel:SetFont(fontPath, 11, fontOutline)
    autoScrollLabel:SetPoint("LEFT", autoScrollCheck, "RIGHT", 5, 0)
    autoScrollLabel:SetText("Auto-scroll")
    autoScrollLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    consoleFrame = frame
    return frame
end

-- Module name to color mapping (based on config tab colors)
local moduleColors = {
    ["Changes"] = "|cFFFF9999",  -- Pastel red (from changes tab)
    ["Batch"] = "|cFFFFAA66",    -- Orange (from batch tab)
    ["Debug"] = "|cFFFF6666",    -- Red (from debug tab)
    ["General"] = "|cFFFFDD00",  -- Yellow (from general tab)
    ["Fishing"] = "|cFF00FFFF",  -- Cyan
    ["UI"] = "|cFF55AAFF",       -- Blue
    ["Media"] = "|cFFFF88FF",    -- Pink/magenta
    ["Splash"] = "|cFF88FF88",   -- Light green
    ["System"] = "|cFFCCCCCC",   -- Light gray
    ["Tests"] = "|cFFFFAAAA",    -- Pastel orange
    ["Notify"] = "|cFFAAAAFF",   -- Pastel blue
    ["Macros"] = "|cFF00CCCC",   -- Teal
}

-- Maximum section name length for formatting (set to 10 for tighter spacing)
local MAX_SECTION_LENGTH = 10

function UpdateConsoleDisplay()
    if not consoleFrame then return end

    -- Don't update if paused (messages still get stored, just not displayed)
    if consoleFrame.updatesPaused then
        -- Get current debug level for filtering
        local currentDebugLevel = (KOL.db and KOL.db.profile and KOL.db.profile.debugLevel) or 5

        -- Count visible messages (filtered by debug level)
        local visibleCount = 0
        for _, entry in ipairs(debugMessages) do
            if entry.level <= currentDebugLevel then
                visibleCount = visibleCount + 1
            end
        end

        -- Still update message count to show how many messages are waiting
        consoleFrame.messageCount:SetText(visibleCount .. " / " .. #debugMessages .. " messages (PAUSED, L" .. currentDebugLevel .. ")")
        return
    end

    -- Get current debug level for filtering
    local currentDebugLevel = (KOL.db and KOL.db.profile and KOL.db.profile.debugLevel) or 5

    -- Count visible messages (filtered by debug level)
    local visibleCount = 0
    for _, entry in ipairs(debugMessages) do
        if entry.level <= currentDebugLevel then
            visibleCount = visibleCount + 1
        end
    end

    -- Update message count
    consoleFrame.messageCount:SetText(visibleCount .. " / " .. #debugMessages .. " messages (L" .. currentDebugLevel .. ")")

    -- Build message text (limit to last 200 visible lines to prevent memory issues)
    local MAX_RENDER_LINES = 200
    local lines = {}
    local startIndex = 1

    -- Count visible messages and find start index if we need to skip some
    local visibleMessages = {}
    for i, entry in ipairs(debugMessages) do
        if entry.level <= currentDebugLevel then
            table.insert(visibleMessages, entry)
        end
    end

    -- If too many visible messages, skip the oldest ones
    if #visibleMessages > MAX_RENDER_LINES then
        startIndex = #visibleMessages - MAX_RENDER_LINES + 1
    end

    for i = startIndex, #visibleMessages do
        local entry = visibleMessages[i]
        -- Filter by debug level (only show messages at or below current level)
        if entry and entry.level <= currentDebugLevel then
            local color = GetLevelColor(entry.level)
            local colorCode = string.format("|cFF%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)

            local messageText = entry.message
            local sectionName = nil
            local restOfMessage = messageText

            -- Extract section name if present (e.g., "Changes: message" or "Batch [channel] message")
            for moduleName, moduleColor in pairs(moduleColors) do
                -- Match "ModuleName:" at start
                local pattern = "^(" .. moduleName .. "):%s*(.*)"
                local section, rest = messageText:match(pattern)
                if section then
                    sectionName = section
                    restOfMessage = rest

                    -- Calculate padding AFTER the colon (not inside brackets)
                    local paddingNeeded = MAX_SECTION_LENGTH - #sectionName
                    local padding = ""
                    for i = 1, paddingNeeded do
                        padding = padding .. " "
                    end

                    -- Format: [Timestamp] [Level] [Section]: <padding> Message
                    local line = string.format("|cFFCCCCCC[%s]|r |cFFAAAA00[L%d]|r %s[%s]|r:%s%s%s|r",
                        entry.time,           -- White timestamp
                        entry.level,          -- Yellow level
                        moduleColor,          -- Section color
                        sectionName,          -- Section name (compact, no padding inside)
                        padding,              -- Padding AFTER the colon
                        colorCode,            -- Message color
                        restOfMessage         -- Rest of message
                    )
                    table.insert(lines, line)
                    break
                end
            end

            -- If no section found, just print the message normally
            if not sectionName then
                local line = string.format("|cFFCCCCCC[%s]|r |cFFAAAA00[L%d]|r %s%s|r",
                    entry.time,
                    entry.level,
                    colorCode,
                    messageText
                )
                table.insert(lines, line)
            end
        end
    end

    local fullText = table.concat(lines, "\n")
    consoleFrame.messageText:SetText(fullText)

    -- Update scroll child height for EditBox
    local textHeight = consoleFrame.messageText:GetHeight()
    consoleFrame.scrollChild:SetHeight(math.max(textHeight + 20, consoleFrame.scrollFrame:GetHeight() or 400))

    -- Auto-scroll to bottom if enabled
    if consoleFrame.autoScroll:GetChecked() then
        C_Timer.After(0.05, function()
            if consoleFrame.scrollFrame then
                local maxScroll = consoleFrame.scrollFrame:GetVerticalScrollRange()
                if maxScroll > 0 then
                    consoleFrame.scrollFrame:SetVerticalScroll(maxScroll)
                end
            end
        end)
    end
end

-- ============================================================================
-- Floating Debug Button
-- ============================================================================

local function CreateDebugButton()
    if debugButton then
        return debugButton
    end

    -- Create button frame (much smaller!)
    local button = CreateFrame("Button", "KOL_DebugButton", UIParent)
    button:SetWidth(18)  -- Much smaller
    button:SetHeight(18)
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(100)

    -- Load saved position or use default
    if KOL.db and KOL.db.profile.debugButtonPos then
        local pos = KOL.db.profile.debugButtonPos
        button:SetPoint(pos.point, pos.relativeTo or UIParent, pos.relativePoint, pos.x, pos.y)
    else
        -- Default position: upper right of chat frame, -10 pixels left and down
        button:SetPoint("TOPRIGHT", ChatFrame1, "TOPRIGHT", -10, -10)
    end

    -- Make it movable (only when shift is held)
    button:SetMovable(true)
    button:EnableMouse(true)

    -- Styled backdrop matching our UI theme
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    -- Apply theme colors to debug button
    local debugButtonBgColor, debugButtonBorderColor
    if KOL.Themes and KOL.Themes.GetUIThemeColor then
        debugButtonBgColor = KOL.Themes:GetUIThemeColor("DebugButtonBG", {r = 0.15, g = 0.15, b = 0.15, a = 0.8})
        debugButtonBorderColor = KOL.Themes:GetUIThemeColor("DebugButtonBorder", {r = 0.4, g = 0.4, b = 0.4, a = 0.9})
    else
        debugButtonBgColor = {r = 0.15, g = 0.15, b = 0.15, a = 0.8}
        debugButtonBorderColor = {r = 0.4, g = 0.4, b = 0.4, a = 0.9}
    end
    button:SetBackdropColor(debugButtonBgColor.r, debugButtonBgColor.g, debugButtonBgColor.b, debugButtonBgColor.a)
    button:SetBackdropBorderColor(debugButtonBorderColor.r, debugButtonBorderColor.g, debugButtonBorderColor.b, debugButtonBorderColor.a)

    -- "D" letter text (smaller font!)
    local fontPath, fontOutline = GetDebugFont()
    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFont(fontPath, 10, fontOutline)  -- 10 font sizes smaller
    text:SetPoint("CENTER", 0, 0)
    text:SetText("D")
    -- Apply theme color to debug button text
    local debugButtonTextColor
    if KOL.Themes and KOL.Themes.GetUIThemeColor then
        debugButtonTextColor = KOL.Themes:GetUIThemeColor("DebugButtonText", {r = 1, g = 0.4, b = 0.4, a = 1})
    else
        debugButtonTextColor = {r = 1, g = 0.4, b = 0.4, a = 1}
    end
    text:SetTextColor(debugButtonTextColor.r, debugButtonTextColor.g, debugButtonTextColor.b, debugButtonTextColor.a)
    button.text = text

    -- Mouse down handler for shift+drag
    button:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" and IsShiftKeyDown() then
            self:StartMoving()
            self.isMoving = true
        end
    end)

    -- Mouse up handler - save position if moved
    button:SetScript("OnMouseUp", function(self, btn)
        if btn == "LeftButton" then
            if self.isMoving then
                self:StopMovingOrSizing()
                self.isMoving = false

                -- Save position
                local point, relativeTo, relativePoint, x, y = self:GetPoint()
                if KOL.db and KOL.db.profile then
                    KOL.db.profile.debugButtonPos = {
                        point = point,
                        relativeTo = "UIParent",  -- Always save relative to UIParent for consistency
                        relativePoint = relativePoint,
                        x = x,
                        y = y
                    }
                    KOL:PrintTag("Debug button position saved")
                end
            else
                -- Normal click - open console
                KOL:ToggleDebugConsole()
            end
        end
    end)

    -- Hover effects with theme colors
    button:SetScript("OnEnter", function(self)
        local hoverColor
        if KOL.Themes and KOL.Themes.GetUIThemeColor then
            hoverColor = KOL.Themes:GetUIThemeColor("DebugButtonHover", {r = 0.25, g = 0.25, b = 0.25, a = 0.95})
        else
            hoverColor = {r = 0.25, g = 0.25, b = 0.25, a = 0.95}
        end
        self:SetBackdropColor(hoverColor.r, hoverColor.g, hoverColor.b, hoverColor.a)

        -- Tooltip
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Debug Console", 1, 1, 1)
        GameTooltip:AddLine("Left-click: Open Debug Console", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Shift + Left-click: Drag to move", 0.7, 0.7, 0.7)
        GameTooltip:Show()

        -- Start rainbow animation
        self.rainbowTimer = 0
        self.rainbowActive = true
        self:SetScript("OnUpdate", function(self, elapsed)
            if not self.rainbowActive then
                self:SetScript("OnUpdate", nil)
                return
            end

            self.rainbowTimer = self.rainbowTimer + elapsed
            if self.rainbowTimer >= 0.08 then  -- Change color every 0.08 seconds
                self.rainbowTimer = 0
                rainbowIndex = rainbowIndex + 1
                if rainbowIndex > #rainbowColors then
                    rainbowIndex = 1
                end

                local color = rainbowColors[rainbowIndex]
                self.text:SetTextColor(color.r, color.g, color.b, 1)
                self:SetBackdropBorderColor(color.r, color.g, color.b, 1)
            end
        end)
    end)

    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(debugButtonBgColor.r, debugButtonBgColor.g, debugButtonBgColor.b, debugButtonBgColor.a)  -- Back to normal
        self:SetBackdropBorderColor(debugButtonBorderColor.r, debugButtonBorderColor.g, debugButtonBorderColor.b, debugButtonBorderColor.a)
        self.text:SetTextColor(debugButtonTextColor.r, debugButtonTextColor.g, debugButtonTextColor.b, debugButtonTextColor.a)
        GameTooltip:Hide()

        -- Stop rainbow animation
        self.rainbowActive = false
        self:SetScript("OnUpdate", nil)
    end)

    debugButton = button
    return button
end

function KOL:UpdateDebugButton()
    local shouldShow = self.db.profile.showDebugButton ~= false

    if shouldShow then
        local button = CreateDebugButton()
        button:Show()
    else
        if debugButton then
            debugButton:Hide()
        end
    end
end

-- ============================================================================
-- Public Functions
-- ============================================================================

function KOL:ShowDebugConsole()
    local frame = CreateConsoleFrame()
    frame:SetFrameStrata("FULLSCREEN_DIALOG")  -- Ensure always on top
    UpdateConsoleDisplay()
    frame:Show()

    -- Start periodic update timer (updates every 0.5s when visible)
    if not frame.updateTimer then
        frame.updateTimer = C_Timer.NewTicker(0.5, function()
            if frame:IsVisible() and not frame.updatesPaused then
                UpdateConsoleDisplay()
            end
        end)
    end
end

function KOL:ToggleDebugConsole()
    local frame = CreateConsoleFrame()
    if frame:IsVisible() then
        frame:Hide()
    else
        frame:SetFrameStrata("FULLSCREEN_DIALOG")  -- Ensure always on top
        UpdateConsoleDisplay()
        frame:Show()

        -- Start periodic update timer (updates every 0.5s when visible)
        if not frame.updateTimer then
            frame.updateTimer = C_Timer.NewTicker(0.5, function()
                if frame:IsVisible() and not frame.updatesPaused then
                    UpdateConsoleDisplay()
                end
            end)
        end
    end
end

function KOL:RefreshDebugConsole()
    -- Refresh the debug console display (used when debug level changes)
    if consoleFrame and consoleFrame:IsVisible() then
        UpdateConsoleDisplay()
    end
end

-- ============================================================================
-- Hook DebugPrint to send to console
-- ============================================================================

-- Store original DebugPrint
local originalDebugPrint = KOL.DebugPrint

-- Enhanced DebugPrint with theme color support
function KOL:DebugPrint(message, level)
    -- Call original DebugPrint first
    originalDebugPrint(self, message, level)
    
    -- Add theme color to debug messages if themes are available
    if self.Themes and self.Themes.GetThemeColor then
        -- Try to get a theme color for the message
        local themeColor = self.Themes:GetThemeColor("DebugLevel" .. (level or 3), "FFFFFF")
        if themeColor and themeColor ~= "FFFFFF" then
            -- Wrap the message in theme color
            message = "|cFF" .. themeColor .. message .. "|r"
        end
    end
    
    -- Call original DebugPrint with potentially modified message
    originalDebugPrint(self, message, level)
end

-- Override DebugPrint to send to both chat AND console
function KOL:DebugPrint(message, level)
    level = level or 1

    -- Always add to console (even during early load)
    AddDebugMessage(message, level)

    -- Level 0: CRITICAL - Always print to BOTH console AND chat, bypassing all filters
    if level == 0 then
        if originalDebugPrint then
            originalDebugPrint(self, message, 0)
        end
        return
    end

    -- If db not initialized yet, we're in early load - just store message and return
    if not self.db or not self.db.profile then
        return
    end

    -- Check if we should respect debug level filtering
    local currentDebugLevel = self.db.profile.debugLevel or 1
    local debugEnabled = self.db.profile.debug

    -- Only process if debug is enabled and message level is within current setting
    if not debugEnabled or level > currentDebugLevel then
        return
    end

    -- Only print to chat if debugOutputToChat is enabled (default FALSE - console only!)
    if self.db.profile.debugOutputToChat == true then
        -- Call original with safety check
        if originalDebugPrint then
            originalDebugPrint(self, message, level)
        end
    end
end

-- ============================================================================
-- Slash Commands
-- ============================================================================

KOL:RegisterSlashCommand("debugui", function()
    KOL:ToggleDebugConsole()
end, "Toggle debug console window")

KOL:RegisterSlashCommand("debugclear", function()
    debugMessages = {}
    if consoleFrame then
        UpdateConsoleDisplay()
    end
    KOL:PrintTag("Debug console cleared")
end, "Clear debug console messages")

KOL:RegisterSlashCommand("fonts", function()
    KOL:PrintTag("Available Fonts in LibSharedMedia:")

    local availableFonts = LSM:HashTable("font")
    local monoFonts = {"Inconsolata", "Consolas", "Courier New", "Source Code Pro", "DejaVu Sans Mono", "Liberation Mono", "Fira Code", "Fira Mono", "PT Mono", "Roboto Mono", "Hack"}

    local fontList = {}
    for fontName, _ in pairs(availableFonts) do
        table.insert(fontList, fontName)
    end
    table.sort(fontList)

    for _, fontName in ipairs(fontList) do
        local isMono = false
        for _, monoName in ipairs(monoFonts) do
            if fontName:find(monoName) then
                isMono = true
                break
            end
        end

        if isMono then
            KOL:Print("  " .. GREEN(fontName) .. " " .. PASTEL_YELLOW("(monospace)"))
        else
            KOL:Print("  " .. fontName)
        end
    end

    KOL:Print(" ")
    KOL:PrintTag("Green fonts are likely monospace - good for debug console!")
end, "List all available fonts")

-- Initialize debug button when UI system is ready
C_Timer.After(1, function()
    if KOL.UpdateDebugButton then
        KOL:UpdateDebugButton()
    end
end)

KOL:DebugPrint("Debug: Console UI loaded", 1)
