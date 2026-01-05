local KOL = KoalityOfLife

KOL.Errors = {}
local Errors = KOL.Errors

Errors.errors = {}
Errors.maxErrors = 100
Errors.frame = nil

function Errors:ParseError(errorMsg)
    if not errorMsg then return nil end

    local errStr = tostring(errorMsg)
    local firstLine = errStr:match("^([^\n]+)") or errStr

    local addonName = firstLine:match("Interface[/\\]AddOns[/\\]([^/\\:]+)")
    if not addonName then
        addonName = firstLine:match("%.%.%.([^/\\:]+)[/\\]")
    end

    local filePath, lineNum = firstLine:match("([^:]+):(%d+):")
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

function Errors:AddError(errorMsg)
    local parsed = self:ParseError(errorMsg)
    if not parsed then return end

    table.insert(self.errors, 1, parsed)

    while #self.errors > self.maxErrors do
        table.remove(self.errors)
    end
end

function Errors:GetErrors(filterAddon)
    if not filterAddon or filterAddon == "" then
        return self.errors
    end

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

function Errors:ClearErrors()
    self.errors = {}
    KOL:PrintTag("Lua error log cleared")
end

function Errors:CreateFrame()
    if self.frame then return self.frame end

    local UIFactory = KOL.UIFactory
    if not UIFactory then
        KOL:PrintTag("|cFFFF0000Error:|r UIFactory not available")
        return nil
    end

    -- Create main styled frame
    local frame = UIFactory:CreateStyledFrame(UIParent, "KOL_ErrorsFrame", 700, 500, {
        movable = true,
        closable = true,
    })

    -- Title bar background
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetHeight(26)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
    })

    -- Get theme colors for title bar
    local titleBgColor = {r = 0.15, g = 0.05, b = 0.05, a = 1}
    if KOL.Themes and KOL.Themes.GetUIThemeColor then
        titleBgColor = KOL.Themes:GetUIThemeColor("GlobalTitleBG", titleBgColor)
    end
    titleBar:SetBackdropColor(titleBgColor.r, titleBgColor.g, titleBgColor.b, titleBgColor.a)

    -- Get font settings
    local fontPath = "Fonts\\FRIZQT__.TTF"
    local fontOutline = "OUTLINE"
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM and KOL.db and KOL.db.profile then
        local generalFont = KOL.db.profile.generalFont or "Friz Quadrata TT"
        fontPath = LSM:Fetch("font", generalFont) or fontPath
        fontOutline = KOL.db.profile.generalFontOutline or fontOutline
    end

    -- Title LEFT: "Lua Errors Viewer" in red-ish color
    local titleLeft = frame:CreateFontString(nil, "OVERLAY")
    titleLeft:SetFont(fontPath, 13, fontOutline)
    titleLeft:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    titleLeft:SetText("|cFFFF6666Lua Errors|r |cFFAAAAAA Viewer|r")

    -- Title CENTER: Error count
    local titleCenter = frame:CreateFontString(nil, "OVERLAY")
    titleCenter:SetFont(fontPath, 11, fontOutline)
    titleCenter:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    titleCenter:SetText("")
    frame.countText = titleCenter

    -- Title RIGHT: Filter info
    local titleRight = frame:CreateFontString(nil, "OVERLAY")
    titleRight:SetFont(fontPath, 10, fontOutline)
    titleRight:SetPoint("RIGHT", titleBar, "RIGHT", -30, 0)
    titleRight:SetJustifyH("RIGHT")
    titleRight:SetText("")
    frame.filterText = titleRight

    -- Close button (styled)
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -3, 0)
    closeBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    closeBtn:SetBackdropColor(0.3, 0.1, 0.1, 0.9)
    closeBtn:SetBackdropBorderColor(0.5, 0.2, 0.2, 1)

    local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
    closeX:SetFont(fontPath, 12, fontOutline)
    closeX:SetPoint("CENTER", 0, 1)
    closeX:SetText("|cFFFF8888X|r")

    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.5, 0.15, 0.15, 1)
        self:SetBackdropBorderColor(0.7, 0.3, 0.3, 1)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.3, 0.1, 0.1, 0.9)
        self:SetBackdropBorderColor(0.5, 0.2, 0.2, 1)
    end)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Scroll container (below title bar, above button row)
    local scrollContainer = CreateFrame("Frame", nil, frame)
    scrollContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -32)
    scrollContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 44)
    scrollContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    scrollContainer:SetBackdropColor(0, 0, 0, 0.6)
    scrollContainer:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    -- Use UIFactory's CreateScrollableContent for proper skinning
    local scrollChild, scrollFrame = UIFactory:CreateScrollableContent(scrollContainer, {
        inset = {top = 4, bottom = 4, left = 4, right = 4},
        scrollbarWidth = 16,
    })

    -- Edit box for copyable text
    local editBox = CreateFrame("EditBox", nil, scrollChild)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, -4)
    editBox:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, -4)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(self.originalText or "")
        end
    end)

    -- Use monospace font for error text
    local monoFont = "Interface\\AddOns\\!Koality-of-Life\\media\\fonts\\JetBrainsMono-Regular.ttf"
    editBox:SetFont(monoFont, 11, "")
    editBox:SetTextColor(0.9, 0.9, 0.9, 1)

    frame.editBox = editBox
    frame.scrollFrame = scrollFrame
    frame.scrollChild = scrollChild

    -- Button row at bottom
    local buttonRow = CreateFrame("Frame", nil, frame)
    buttonRow:SetPoint("BOTTOMLEFT", 8, 8)
    buttonRow:SetPoint("BOTTOMRIGHT", -8, 8)
    buttonRow:SetHeight(30)

    -- Clear button
    local clearBtn = UIFactory:CreateButton(buttonRow, "Clear", {
        width = 80,
        height = 26,
        onClick = function()
            Errors:ClearErrors()
            Errors:RefreshFrame()
        end,
    })
    clearBtn:SetPoint("LEFT", 0, 0)

    -- Select All button
    local selectBtn = UIFactory:CreateButton(buttonRow, "Select All", {
        width = 90,
        height = 26,
        onClick = function()
            editBox:SetFocus()
            editBox:HighlightText()
        end,
    })
    selectBtn:SetPoint("LEFT", clearBtn, "RIGHT", 8, 0)

    -- Refresh button
    local refreshBtn = UIFactory:CreateButton(buttonRow, "Refresh", {
        width = 80,
        height = 26,
        onClick = function()
            Errors:RefreshFrame()
        end,
    })
    refreshBtn:SetPoint("LEFT", selectBtn, "RIGHT", 8, 0)

    -- Help text
    local helpText = frame:CreateFontString(nil, "OVERLAY")
    helpText:SetFont(fontPath, 10, fontOutline)
    helpText:SetPoint("BOTTOMRIGHT", -10, 14)
    helpText:SetText("|cFF666666Ctrl+A to select, Ctrl+C to copy|r")

    self.frame = frame
    return frame
end

function Errors:RefreshFrame(filterAddon)
    if not self.frame then return end

    filterAddon = filterAddon or self.currentFilter
    local errors = self:GetErrors(filterAddon)

    -- Update filter text (title bar right)
    if filterAddon and filterAddon ~= "" then
        self.frame.filterText:SetText("|cFFFFFF00Filter:|r " .. filterAddon)
    else
        self.frame.filterText:SetText("|cFF666666No filter|r")
    end

    -- Update count (title bar center)
    local totalCount = #self.errors
    local filteredCount = #errors
    if filterAddon and filterAddon ~= "" then
        self.frame.countText:SetText(string.format("|cFFFFFFFF%d|r |cFF888888of|r |cFFFFFFFF%d|r |cFF888888errors|r", filteredCount, totalCount))
    else
        self.frame.countText:SetText(string.format("|cFFFFFFFF%d|r |cFF888888errors|r", totalCount))
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
            local timeStr = date("%H:%M:%S", err.timestamp)
            local header = string.format("[%d] [%s] %s:%s @ %s",
                i,
                err.addon or "Unknown",
                err.file or "?",
                err.line or "?",
                timeStr
            )
            table.insert(lines, "|cFFFF6666" .. header .. "|r")
            table.insert(lines, err.fullError)
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
    local contentHeight = math.max(numLines * lineHeight, self.frame.scrollFrame:GetHeight())
    self.frame.editBox:SetHeight(contentHeight)
    self.frame.scrollChild:SetHeight(contentHeight + 8)
end

function Errors:ShowFrame(filterAddon)
    local frame = self:CreateFrame()
    if not frame then return end

    self.currentFilter = filterAddon
    self:RefreshFrame(filterAddon)
    frame:Show()
end

function Errors:ToggleFrame(filterAddon)
    if self.frame and self.frame:IsShown() then
        self.frame:Hide()
    else
        self:ShowFrame(filterAddon)
    end
end

function Errors:HandleSlashCommand(...)
    local args = {...}
    local filterAddon = args[1]

    if #args > 1 then
        filterAddon = table.concat(args, " ")
    end

    self:ShowFrame(filterAddon)
end

function Errors:Initialize()
    KOL:RegisterSlashCommand("luaerrors", function(...)
        Errors:HandleSlashCommand(...)
    end, "Show Lua errors viewer with optional addon filter")

    KOL:RegisterSlashCommand("errors", function(...)
        Errors:HandleSlashCommand(...)
    end, "Alias for luaerrors")

    KOL:DebugPrint("Errors: Module initialized", 2)
end

KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
    Errors:Initialize()
end, "Errors")
