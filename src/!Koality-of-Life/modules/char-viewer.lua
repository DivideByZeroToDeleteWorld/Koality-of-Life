-- ============================================================================
-- Character Viewer UI
-- ============================================================================
-- A dedicated window for viewing special characters with proper font rendering
-- ============================================================================

local KOL = KoalityOfLife

-- Reference to viewer frame
local viewerFrame = nil

-- ============================================================================
-- Console UI Creation
-- ============================================================================

local function CreateViewerFrame()
    if viewerFrame then
        return viewerFrame
    end

    -- Main frame
    local frame = CreateFrame("Frame", "KOL_CharViewer", UIParent)
    frame:SetWidth(600)
    frame:SetHeight(400)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(100)

    -- Backdrop - dark theme
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 1,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropColor(0.02, 0.02, 0.02, 0.98)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- Make it closable with ESC
    tinsert(UISpecialFrames, "KOL_CharViewer")

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetHeight(20)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = false
    })
    titleBar:SetBackdropColor(0.1, 0.1, 0.1, 1)

    -- Title text with rainbow effect
    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    titleText:SetPoint("LEFT", 8, 0)
    titleText:SetFont(CHAR_LIGATURESFONT, 12, CHAR_LIGATURESOUTLINE)
    titleText:SetText("|cFFFF6699K|cFFFF88AAo|cFFFFAABBa|cFFFFCCCCl|cFFFFEEDDi|cFFFFFFEEt|cFFEEFFFFy|r |cFF88FFFFCharacter Viewer|r")

    -- Close button
    local closeButton = CreateFrame("Button", nil, titleBar)
    closeButton:SetSize(16, 16)
    closeButton:SetPoint("RIGHT", -2, 0)
    closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "KOL_CharViewerScroll", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -25)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)

    -- Scroll child frame to hold the font strings
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 30)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    -- Container for all text
    frame.textLines = {}
    frame.scrollChild = scrollChild

    viewerFrame = frame
    return frame
end

-- ============================================================================
-- Public Functions
-- ============================================================================

function KOL:ShowCharViewer(searchTerm, results)
    local frame = CreateViewerFrame()

    if not frame.scrollChild then
        KOL:PrintTag(RED("Error: Character viewer not initialized properly"))
        return
    end

    -- Clear existing text lines
    for _, line in ipairs(frame.textLines) do
        line:Hide()
        line:SetText("")
    end
    wipe(frame.textLines)

    local fontPath = "Interface\\AddOns\\!Koality-of-Life\\media\\fonts\\SourceCodePro-Bold.ttf"
    local yOffset = -10
    local lineHeight = 20

    -- Helper to create a text line
    local function AddLine(text, size, color)
        local line = frame.scrollChild:CreateFontString(nil, "OVERLAY")
        line:SetFont(fontPath, size or 14, "OUTLINE")
        line:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 10, yOffset)
        line:SetPoint("TOPRIGHT", frame.scrollChild, "TOPRIGHT", -10, yOffset)
        line:SetJustifyH("LEFT")
        line:SetText(text)
        if color then
            line:SetTextColor(color.r, color.g, color.b, color.a or 1)
        else
            line:SetTextColor(1, 1, 1, 1)
        end
        table.insert(frame.textLines, line)
        yOffset = yOffset - lineHeight
        return line
    end

    -- Title
    AddLine("Character Search Results", 16, {r=1, g=0.8, b=0.4})
    AddLine("========================", 14, {r=0.6, g=0.6, b=0.6})
    yOffset = yOffset - 5

    -- TEST: Hardcoded character to verify font rendering
    local testLine = frame.scrollChild:CreateFontString(nil, "OVERLAY")
    testLine:SetFont(fontPath, 32, "OUTLINE")
    testLine:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 10, yOffset)
    testLine:SetText("TEST HARDCODED: ➤ ▸ → ← ▲ ▼")
    testLine:SetTextColor(1, 0, 1, 1)  -- Magenta for visibility
    table.insert(frame.textLines, testLine)
    yOffset = yOffset - 40

    -- Search term
    AddLine("Search term: " .. (searchTerm or "unknown"), 13, {r=0.8, g=1, b=1})
    yOffset = yOffset - 5

    if results and #results > 0 then
        AddLine("Found " .. #results .. " match(es):", 13, {r=0.5, g=1, b=0.5})
        yOffset = yOffset - 5

        for i, result in ipairs(results) do
            -- Debug: Check what we're getting
            KOL:DebugPrint("CharViewer: Result[" .. i .. "] char='" .. tostring(result.char) .. "' key='" .. tostring(result.key) .. "'", 2)

            -- Create two separate lines: one for the character (BIG), one for the key name
            local charLine = frame.scrollChild:CreateFontString(nil, "OVERLAY")
            charLine:SetFont(fontPath, 32, "OUTLINE")  -- Big character
            charLine:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 10, yOffset)
            charLine:SetText(result.char)
            charLine:SetTextColor(1, 1, 0.5, 1)  -- Yellow for the character
            table.insert(frame.textLines, charLine)

            local keyLine = frame.scrollChild:CreateFontString(nil, "OVERLAY")
            keyLine:SetFont(fontPath, 14, "OUTLINE")
            keyLine:SetPoint("LEFT", charLine, "RIGHT", 15, 0)
            keyLine:SetText(result.key)
            keyLine:SetTextColor(0.7, 0.7, 1, 1)  -- Light blue for the key name
            table.insert(frame.textLines, keyLine)

            yOffset = yOffset - 40  -- Extra space for big character
        end

        yOffset = yOffset - 10
        AddLine("Tip: Characters are displayed with Source Code Pro Bold font", 11, {r=0.5, g=0.5, b=0.5})
    else
        AddLine("No matches found.", 13, {r=1, g=0.3, b=0.3})
        yOffset = yOffset - 5
        AddLine("Try searching with simpler terms like:", 12, {r=0.7, g=0.7, b=0.7})
        AddLine("  - ARROW", 12, {r=0.6, g=0.6, b=0.6})
        AddLine("  - TRIANGLE", 12, {r=0.6, g=0.6, b=0.6})
        AddLine("  - FILLED", 12, {r=0.6, g=0.6, b=0.6})
        AddLine("  - CIRCLE", 12, {r=0.6, g=0.6, b=0.6})
    end

    -- Update scroll child height
    frame.scrollChild:SetHeight(math.abs(yOffset) + 20)

    frame:Show()
end

function KOL:ToggleCharViewer()
    local frame = CreateViewerFrame()
    if frame:IsVisible() then
        frame:Hide()
    else
        frame:Show()
    end
end
