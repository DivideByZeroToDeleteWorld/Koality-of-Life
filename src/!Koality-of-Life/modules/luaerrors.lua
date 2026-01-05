-- ============================================================================
-- !Koality-of-Life: Lua Errors Viewer Module
-- ============================================================================
-- Captures and displays Lua errors in a copyable frame.
-- Usage: /kol luaerrors [addon] - Show errors, optionally filtered by addon name
-- ============================================================================

local KOL = KoalityOfLife

-- Module table
KOL.LuaErrors = {}
local LuaErrors = KOL.LuaErrors

-- Storage for captured errors
LuaErrors.errors = {}
LuaErrors.maxErrors = 100  -- Maximum errors to store

-- UI Frame reference
LuaErrors.frame = nil

-- ============================================================================
-- Error Capture
-- ============================================================================

-- Parse an error message to extract addon name and file:line info
-- We only look at the FIRST line (the actual error source) not the stack trace
function LuaErrors:ParseError(errorMsg)
    if not errorMsg then return nil end

    local errStr = tostring(errorMsg)

    -- Extract the first line only (before any newline)
    local firstLine = errStr:match("^([^\n]+)")
    if not firstLine then
        firstLine = errStr
    end

    -- Try to extract addon name from file path
    -- Common patterns:
    -- Interface\AddOns\AddonName\file.lua:123:
    -- Interface/AddOns/AddonName/file.lua:123:
    -- ...AddonName\file.lua:123:
    local addonName = nil
    local filePath = nil
    local lineNum = nil

    -- Pattern 1: Full path with Interface\AddOns or Interface/AddOns
    addonName = firstLine:match("Interface[/\\]AddOns[/\\]([^/\\:]+)")

    -- Pattern 2: Shortened path like ...AddonName\file.lua
    if not addonName then
        addonName = firstLine:match("%.%.%.([^/\\:]+)[/\\]")
    end

    -- Extract file:line from first line
    filePath, lineNum = firstLine:match("([^:]+):(%d+):")
    if not filePath then
        filePath, lineNum = firstLine:match("([^:]+):(%d+)")
    end

    return {
        addon = addonName or "Unknown",
        file = filePath or firstLine,
        line = lineNum or "?",
        fullError = errStr,
        firstLine = firstLine,
        timestamp = time(),
    }
end

-- Add an error to the storage
function LuaErrors:AddError(errorMsg)
    local parsed = self:ParseError(errorMsg)
    if not parsed then return end

    -- Add to the beginning (newest first)
    table.insert(self.errors, 1, parsed)

    -- Trim to max
    while #self.errors > self.maxErrors do
        table.remove(self.errors)
    end
end

-- Get errors, optionally filtered by addon name
function LuaErrors:GetErrors(filterAddon)
    if not filterAddon or filterAddon == "" then
        return self.errors
    end

    -- Filter by addon name (case-insensitive partial match)
    local filtered = {}
    local filterLower = string.lower(filterAddon)

    for _, err in ipairs(self.errors) do
        local addonLower = string.lower(err.addon or "")
        if string.find(addonLower, filterLower, 1, true) then
            table.insert(filtered, err)
        end
    end

    return filtered
end

-- Clear all stored errors
function LuaErrors:ClearErrors()
    self.errors = {}
    KOL:PrintTag("Lua error log cleared")
end

-- ============================================================================
-- UI Frame
-- ============================================================================

function LuaErrors:CreateFrame()
    if self.frame then return self.frame end

    -- Create main frame
    local frame = CreateFrame("Frame", "KOL_LuaErrorsFrame", UIParent)
    frame:SetSize(700, 500)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- Make it closeable with Escape
    tinsert(UISpecialFrames, "KOL_LuaErrorsFrame")

    -- Background
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    frame:SetBackdropBorderColor(0.6, 0.3, 0.3, 1)

    -- Title bar
    local titleBg = frame:CreateTexture(nil, "ARTWORK")
    titleBg:SetPoint("TOPLEFT", 4, -4)
    titleBg:SetPoint("TOPRIGHT", -4, -4)
    titleBg:SetHeight(24)
    titleBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    titleBg:SetVertexColor(0.4, 0.15, 0.15, 0.8)

    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 12, -8)
    title:SetText("|cFFFF6666Lua Errors Viewer|r")
    frame.title = title

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Filter info text (shows current filter)
    local filterText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterText:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -8, -8)
    filterText:SetJustifyH("RIGHT")
    filterText:SetText("")
    frame.filterText = filterText

    -- Error count text
    local countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countText:SetPoint("TOP", frame, "TOP", 0, -10)
    countText:SetText("")
    frame.countText = countText

    -- Scroll frame container
    local scrollContainer = CreateFrame("Frame", nil, frame)
    scrollContainer:SetPoint("TOPLEFT", 8, -32)
    scrollContainer:SetPoint("BOTTOMRIGHT", -28, 40)
    scrollContainer:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    scrollContainer:SetBackdropColor(0, 0, 0, 0.7)
    scrollContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "KOL_LuaErrorsScrollFrame", scrollContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", -6, 6)

    -- Edit box for copyable text
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetWidth(scrollFrame:GetWidth() - 20)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            -- Don't let user edit, restore the text
            self:SetText(self.originalText or "")
        end
    end)

    -- Use a monospace font if available
    local fontPath = "Interface\\AddOns\\!Koality-of-Life\\media\\fonts\\JetBrainsMono-Regular.ttf"
    editBox:SetFont(fontPath, 11, "")

    scrollFrame:SetScrollChild(editBox)
    frame.editBox = editBox
    frame.scrollFrame = scrollFrame

    -- Button row at bottom
    local buttonRow = CreateFrame("Frame", nil, frame)
    buttonRow:SetPoint("BOTTOMLEFT", 8, 8)
    buttonRow:SetPoint("BOTTOMRIGHT", -8, 8)
    buttonRow:SetHeight(28)

    -- Clear button
    local clearBtn = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
    clearBtn:SetSize(80, 24)
    clearBtn:SetPoint("LEFT", 0, 0)
    clearBtn:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        LuaErrors:ClearErrors()
        LuaErrors:RefreshFrame()
    end)

    -- Copy All button
    local copyBtn = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
    copyBtn:SetSize(100, 24)
    copyBtn:SetPoint("LEFT", clearBtn, "RIGHT", 8, 0)
    copyBtn:SetText("Select All")
    copyBtn:SetScript("OnClick", function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)

    -- Refresh button
    local refreshBtn = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
    refreshBtn:SetSize(80, 24)
    refreshBtn:SetPoint("LEFT", copyBtn, "RIGHT", 8, 0)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function()
        LuaErrors:RefreshFrame()
    end)

    -- Help text
    local helpText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    helpText:SetPoint("BOTTOMRIGHT", -8, 14)
    helpText:SetText("|cFF888888Ctrl+A to select, Ctrl+C to copy|r")

    self.frame = frame
    return frame
end

function LuaErrors:RefreshFrame(filterAddon)
    if not self.frame then return end

    local errors = self:GetErrors(filterAddon)

    -- Update filter text
    if filterAddon and filterAddon ~= "" then
        self.frame.filterText:SetText("|cFFFFFF00Filter:|r " .. filterAddon)
    else
        self.frame.filterText:SetText("|cFF888888No filter|r")
    end

    -- Update count
    local totalCount = #self.errors
    local filteredCount = #errors
    if filterAddon and filterAddon ~= "" then
        self.frame.countText:SetText(string.format("|cFFFFFFFF%d|r of |cFFFFFFFF%d|r errors", filteredCount, totalCount))
    else
        self.frame.countText:SetText(string.format("|cFFFFFFFF%d|r errors", totalCount))
    end

    -- Build the text content
    local lines = {}

    if #errors == 0 then
        table.insert(lines, "No Lua errors captured.")
        table.insert(lines, "")
        table.insert(lines, "Errors will appear here as they occur.")
        if filterAddon and filterAddon ~= "" then
            table.insert(lines, "")
            table.insert(lines, "Try removing the filter to see all errors.")
        end
    else
        for i, err in ipairs(errors) do
            -- Header line: [#] [Addon] File:Line @ Time
            local timeStr = date("%H:%M:%S", err.timestamp)
            local header = string.format("[%d] [%s] %s:%s @ %s",
                i,
                err.addon or "Unknown",
                err.file or "?",
                err.line or "?",
                timeStr
            )
            table.insert(lines, "|cFFFF6666" .. header .. "|r")

            -- Error message (full error without colors for easier copying)
            table.insert(lines, err.fullError)

            -- Separator
            table.insert(lines, "")
            table.insert(lines, string.rep("-", 80))
            table.insert(lines, "")
        end
    end

    local text = table.concat(lines, "\n")
    self.frame.editBox.originalText = text
    self.frame.editBox:SetText(text)

    -- Update edit box height for scrolling
    local numLines = #lines
    local lineHeight = 14
    self.frame.editBox:SetHeight(math.max(numLines * lineHeight, self.frame.scrollFrame:GetHeight()))
end

function LuaErrors:ShowFrame(filterAddon)
    local frame = self:CreateFrame()
    self:RefreshFrame(filterAddon)
    frame:Show()

    -- Store current filter for refresh
    self.currentFilter = filterAddon
end

function LuaErrors:ToggleFrame(filterAddon)
    if self.frame and self.frame:IsShown() then
        self.frame:Hide()
    else
        self:ShowFrame(filterAddon)
    end
end

-- ============================================================================
-- Slash Command Handler
-- ============================================================================

function LuaErrors:HandleSlashCommand(...)
    local args = {...}
    local filterAddon = args[1]

    -- Join multiple words if provided (for addon names with spaces)
    if #args > 1 then
        filterAddon = table.concat(args, " ")
    end

    self:ShowFrame(filterAddon)
end

-- ============================================================================
-- Module Initialization
-- ============================================================================

function LuaErrors:Initialize()
    -- Register slash command
    KOL:RegisterSlashCommand("luaerrors", function(...)
        LuaErrors:HandleSlashCommand(...)
    end, "Show Lua errors viewer with optional addon filter")

    -- Also register "errors" as an alias
    KOL:RegisterSlashCommand("errors", function(...)
        LuaErrors:HandleSlashCommand(...)
    end, "Alias for luaerrors")

    KOL:DebugPrint("LuaErrors: Module initialized", 2)
end

-- Initialize when PLAYER_ENTERING_WORLD fires
KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
    LuaErrors:Initialize()
end, "LuaErrors")
