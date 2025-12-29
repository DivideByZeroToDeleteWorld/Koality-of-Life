-- ============================================================================
-- !Koality-of-Life: Progress Tracker Custom Panel Editor
-- ============================================================================
-- Unified entry editor with type dropdown (Kill/Loot/Yell/Multi-Kill)
-- ============================================================================

local KOL = KoalityOfLife
local UIFactory = KOL.UIFactory

-- Store reference to editor frame
local editorFrame = nil
local currentEditingPanelId = nil

-- Entry type icons and labels
local ENTRY_TYPES = {
    {value = "kill", label = "Kill (NPC)", icon = "|cFF00FF00*|r"},
    {value = "loot", label = "Loot (Item)", icon = "|cFFFFD700$|r"},
    {value = "yell", label = "Yell", icon = "|cFF00BFFF!|r"},
    {value = "multikill", label = "Multi-Kill", icon = "|cFFFF6600#|r"},
}

-- ============================================================================
-- Helper Functions
-- ============================================================================

local function CreateStyledInput(parent, width, height, multiline)
    local input = CreateFrame("EditBox", nil, parent)
    input:SetWidth(width)
    input:SetHeight(height)
    input:SetAutoFocus(false)
    input:SetMultiLine(multiline or false)
    input:SetMaxLetters(multiline and 0 or 200)

    input:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    input:SetBackdropColor(0.05, 0.05, 0.05, 1)
    input:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local fontPath, fontOutline = UIFactory.GetGeneralFont()
    input:SetFont(fontPath, 11, fontOutline)
    input:SetTextColor(1, 1, 0.6, 1)
    input:SetTextInsets(4, 4, 2, 2)

    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    input:SetScript("OnEnterPressed", function(self) if not multiline then self:ClearFocus() end end)

    return input
end

local function CreateStyledButton(parent, width, height, text)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height)

    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    button:SetBackdropColor(0.2, 0.2, 0.2, 1)
    button:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local fontPath, fontOutline = UIFactory.GetGeneralFont()
    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont(fontPath, 11, fontOutline)
    buttonText:SetPoint("CENTER")
    buttonText:SetText(text)
    buttonText:SetTextColor(1, 1, 0.6, 1)
    button.text = buttonText

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.3, 0.3, 1)
        self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.2, 1)
        self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    end)

    return button
end

local function CreateDropdown(parent, width)
    local dropdown = CreateFrame("Frame", nil, parent)
    dropdown:SetWidth(width)
    dropdown:SetHeight(24)

    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.1, 1)
    dropdown:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local fontPath, fontOutline = UIFactory.GetGeneralFont()
    local text = dropdown:CreateFontString(nil, "OVERLAY")
    text:SetFont(fontPath, 11, fontOutline)
    text:SetPoint("LEFT", 6, 0)
    text:SetTextColor(1, 1, 0.6, 1)
    dropdown.text = text

    local arrow = dropdown:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(fontPath, 10, fontOutline)
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetText("v")
    arrow:SetTextColor(0.6, 0.6, 0.6, 1)

    dropdown.selectedValue = nil
    dropdown.options = {}

    return dropdown
end

-- ============================================================================
-- Entry Type Dropdown with Menu
-- ============================================================================

local function ShowTypeMenu(dropdown, callback)
    local menu = CreateFrame("Frame", nil, dropdown)
    menu:SetWidth(dropdown:GetWidth())
    menu:SetHeight(#ENTRY_TYPES * 22 + 4)
    menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menu:SetFrameStrata("TOOLTIP")

    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    menu:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    menu:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local fontPath, fontOutline = UIFactory.GetGeneralFont()
    local yOffset = -2

    for _, typeInfo in ipairs(ENTRY_TYPES) do
        local option = CreateFrame("Button", nil, menu)
        option:SetWidth(menu:GetWidth() - 4)
        option:SetHeight(20)
        option:SetPoint("TOPLEFT", menu, "TOPLEFT", 2, yOffset)

        local optText = option:CreateFontString(nil, "OVERLAY")
        optText:SetFont(fontPath, 10, fontOutline)
        optText:SetPoint("LEFT", 6, 0)
        optText:SetText(typeInfo.icon .. " " .. typeInfo.label)
        optText:SetTextColor(0.9, 0.9, 0.9, 1)

        option:SetScript("OnEnter", function(self)
            self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
            self:SetBackdropColor(0.3, 0.3, 0.3, 1)
        end)
        option:SetScript("OnLeave", function(self)
            self:SetBackdrop(nil)
        end)
        option:SetScript("OnClick", function()
            dropdown.selectedValue = typeInfo.value
            dropdown.text:SetText(typeInfo.icon .. " " .. typeInfo.label)
            menu:Hide()
            if callback then callback(typeInfo.value) end
        end)

        yOffset = yOffset - 22
    end

    menu:Show()

    -- Close on click outside
    menu:SetScript("OnUpdate", function(self)
        if not MouseIsOver(self) and not MouseIsOver(dropdown) then
            if IsMouseButtonDown("LeftButton") then
                self:Hide()
            end
        end
    end)
end

-- ============================================================================
-- Entry Rendering
-- ============================================================================

local function GetEntryIcon(entryType)
    for _, t in ipairs(ENTRY_TYPES) do
        if t.value == entryType then
            return t.icon
        end
    end
    return "|cFF888888?|r"
end

local function GetEntryDescription(entry)
    local entryType = entry.type or "kill"

    if entryType == "kill" then
        return "Kill: " .. (entry.id or "?")
    elseif entryType == "loot" then
        local itemId = entry.itemId or (entry.itemIds and entry.itemIds[1]) or "?"
        return "Loot: " .. itemId
    elseif entryType == "yell" then
        local yell = entry.yell
        if type(yell) == "table" then yell = yell[1] end
        if yell and #yell > 25 then yell = string.sub(yell, 1, 22) .. "..." end
        return "Yell: \"" .. (yell or "?") .. "\""
    elseif entryType == "multikill" then
        local ids = entry.ids or entry.id
        if type(ids) == "table" then
            return "Multi: " .. #ids .. " NPCs"
        end
        return "Multi: ?"
    end

    return "Unknown"
end

local function RenderEntriesList(editor)
    local container = editor.entriesContainer

    -- Clear existing
    for _, child in pairs({container:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local fontPath, fontOutline = UIFactory.GetGeneralFont()

    if not editor.entries or #editor.entries == 0 then
        local emptyText = container:CreateFontString(nil, "OVERLAY")
        emptyText:SetFont(fontPath, 10, fontOutline)
        emptyText:SetPoint("TOP", container, "TOP", 0, -10)
        emptyText:SetText("|cFFAAAAAAAANo entries added yet|r")
        container:SetHeight(40)
        return
    end

    local yOffset = -5
    local rowHeight = 28

    for i, entry in ipairs(editor.entries) do
        local row = CreateFrame("Frame", nil, container)
        row:SetWidth(container:GetWidth() - 10)
        row:SetHeight(rowHeight)
        row:SetPoint("TOPLEFT", container, "TOPLEFT", 5, yOffset)

        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        row:SetBackdropColor(0.08, 0.08, 0.08, 1)
        row:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

        -- Icon + Name
        local icon = GetEntryIcon(entry.type)
        local nameText = row:CreateFontString(nil, "OVERLAY")
        nameText:SetFont(fontPath, 11, fontOutline)
        nameText:SetPoint("LEFT", row, "LEFT", 8, 0)
        nameText:SetText(icon .. " " .. (entry.name or "Unnamed"))
        nameText:SetTextColor(1, 1, 0.8, 1)

        -- Description
        local descText = row:CreateFontString(nil, "OVERLAY")
        descText:SetFont(fontPath, 9, fontOutline)
        descText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
        descText:SetText("|cFF888888(" .. GetEntryDescription(entry) .. ")|r")

        -- Note (if exists)
        if entry.note and entry.note ~= "" then
            local noteText = row:CreateFontString(nil, "OVERLAY")
            noteText:SetFont(fontPath, 9, fontOutline)
            noteText:SetPoint("LEFT", descText, "RIGHT", 6, 0)
            noteText:SetText("|cFF666666- " .. entry.note .. "|r")
        end

        -- Delete button
        local delBtn = CreateStyledButton(row, 40, 20, "Del")
        delBtn:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        delBtn:SetBackdropColor(0.5, 0.15, 0.15, 1)
        delBtn:SetScript("OnClick", function()
            table.remove(editor.entries, i)
            RenderEntriesList(editor)
        end)

        yOffset = yOffset - rowHeight - 2
    end

    container:SetHeight(math.abs(yOffset) + 10)
end

-- ============================================================================
-- Dynamic Input Fields
-- ============================================================================

local function UpdateInputFields(editor, entryType)
    -- Hide all type-specific fields
    editor.npcIdLabel:Hide()
    editor.npcIdInput:Hide()
    editor.itemIdLabel:Hide()
    editor.itemIdInput:Hide()
    editor.yellLabel:Hide()
    editor.yellInput:Hide()
    editor.multiIdsLabel:Hide()
    editor.multiIdsInput:Hide()

    -- Show fields for selected type
    if entryType == "kill" then
        editor.npcIdLabel:Show()
        editor.npcIdInput:Show()
    elseif entryType == "loot" then
        editor.itemIdLabel:Show()
        editor.itemIdInput:Show()
    elseif entryType == "yell" then
        editor.yellLabel:Show()
        editor.yellInput:Show()
    elseif entryType == "multikill" then
        editor.multiIdsLabel:Show()
        editor.multiIdsInput:Show()
    end
end

-- ============================================================================
-- Custom Panel Editor
-- ============================================================================

local function CreateCustomPanelEditor()
    if editorFrame then
        return editorFrame
    end

    local frame = CreateFrame("Frame", "KOL_CustomPanelEditor", UIParent)
    frame:SetWidth(550)
    frame:SetHeight(600)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropColor(0.12, 0.12, 0.12, 0.97)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    tinsert(UISpecialFrames, "KOL_CustomPanelEditor")

    local fontPath, fontOutline = UIFactory.GetGeneralFont()

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetHeight(24)
    titleBar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
    titleBar:SetBackdropColor(0.06, 0.06, 0.06, 1)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontPath, 12, fontOutline)
    title:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
    title:SetText("Custom Panel Editor")
    title:SetTextColor(1, 1, 0.6, 1)
    frame.title = title

    -- Close button
    local closeButton = CreateFrame("Button", nil, titleBar)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -2, 0)
    closeButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1
    })
    closeButton:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
    closeButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.9)

    local xText = closeButton:CreateFontString(nil, "OVERLAY")
    xText:SetFont(fontPath, 12, fontOutline)
    xText:SetPoint("CENTER")
    xText:SetText("X")
    xText:SetTextColor(1, 0.4, 0.4, 1)
    closeButton.text = xText

    closeButton:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.25, 0.25, 0.95)
        self.text:SetTextColor(1, 0.6, 0.6, 1)
    end)
    closeButton:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
        self.text:SetTextColor(1, 0.4, 0.4, 1)
    end)
    closeButton:SetScript("OnClick", function() frame:Hide() end)

    -- Content area
    local contentWidth = frame:GetWidth() - 30
    local yOffset = -35

    -- ========================================================================
    -- Basic Settings
    -- ========================================================================

    -- Panel Name
    local nameLabel = frame:CreateFontString(nil, "OVERLAY")
    nameLabel:SetFont(fontPath, 11, fontOutline)
    nameLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    nameLabel:SetText("Panel Name:")
    nameLabel:SetTextColor(1, 1, 0.6, 1)

    local nameInput = CreateStyledInput(frame, contentWidth, 24, false)
    nameInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset - 16)
    frame.nameInput = nameInput

    yOffset = yOffset - 48

    -- Zones
    local zonesLabel = frame:CreateFontString(nil, "OVERLAY")
    zonesLabel:SetFont(fontPath, 11, fontOutline)
    zonesLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    zonesLabel:SetText("Zones (comma separated, leave empty for all):")
    zonesLabel:SetTextColor(1, 1, 0.6, 1)

    local zonesInput = CreateStyledInput(frame, contentWidth, 24, false)
    zonesInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset - 16)
    frame.zonesInput = zonesInput

    yOffset = yOffset - 48

    -- Color dropdown (simplified to text input for now)
    local colorLabel = frame:CreateFontString(nil, "OVERLAY")
    colorLabel:SetFont(fontPath, 11, fontOutline)
    colorLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    colorLabel:SetText("Color (name like GREEN, PINK, SKY, etc):")
    colorLabel:SetTextColor(1, 1, 0.6, 1)

    local colorInput = CreateStyledInput(frame, 120, 24, false)
    colorInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset - 16)
    colorInput:SetText("PINK")
    frame.colorInput = colorInput

    yOffset = yOffset - 55

    -- ========================================================================
    -- Add New Entry Section
    -- ========================================================================

    local addHeader = frame:CreateFontString(nil, "OVERLAY")
    addHeader:SetFont(fontPath, 12, fontOutline)
    addHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    addHeader:SetText("|cFF88CCFFAdd New Entry|r")

    yOffset = yOffset - 22

    -- Row 1: Type dropdown and Name
    local typeLabel = frame:CreateFontString(nil, "OVERLAY")
    typeLabel:SetFont(fontPath, 10, fontOutline)
    typeLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    typeLabel:SetText("Type:")
    typeLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local typeDropdown = CreateDropdown(frame, 130)
    typeDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset - 14)
    typeDropdown.text:SetText(ENTRY_TYPES[1].icon .. " " .. ENTRY_TYPES[1].label)
    typeDropdown.selectedValue = "kill"
    frame.typeDropdown = typeDropdown

    typeDropdown:EnableMouse(true)
    typeDropdown:SetScript("OnMouseDown", function()
        ShowTypeMenu(typeDropdown, function(value)
            UpdateInputFields(frame, value)
        end)
    end)

    local entryNameLabel = frame:CreateFontString(nil, "OVERLAY")
    entryNameLabel:SetFont(fontPath, 10, fontOutline)
    entryNameLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 155, yOffset)
    entryNameLabel:SetText("Name:")
    entryNameLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local entryNameInput = CreateStyledInput(frame, 200, 24, false)
    entryNameInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 155, yOffset - 14)
    frame.entryNameInput = entryNameInput

    local noteLabel = frame:CreateFontString(nil, "OVERLAY")
    noteLabel:SetFont(fontPath, 10, fontOutline)
    noteLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 365, yOffset)
    noteLabel:SetText("Note (optional):")
    noteLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local noteInput = CreateStyledInput(frame, 150, 24, false)
    noteInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 365, yOffset - 14)
    frame.noteInput = noteInput

    yOffset = yOffset - 48

    -- Row 2: Type-specific input fields (only one visible at a time)

    -- Kill: NPC ID
    local npcIdLabel = frame:CreateFontString(nil, "OVERLAY")
    npcIdLabel:SetFont(fontPath, 10, fontOutline)
    npcIdLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    npcIdLabel:SetText("NPC ID:")
    npcIdLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    frame.npcIdLabel = npcIdLabel

    local npcIdInput = CreateStyledInput(frame, 120, 24, false)
    npcIdInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset - 14)
    frame.npcIdInput = npcIdInput

    -- Loot: Item ID
    local itemIdLabel = frame:CreateFontString(nil, "OVERLAY")
    itemIdLabel:SetFont(fontPath, 10, fontOutline)
    itemIdLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    itemIdLabel:SetText("Item ID:")
    itemIdLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    frame.itemIdLabel = itemIdLabel

    local itemIdInput = CreateStyledInput(frame, 120, 24, false)
    itemIdInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset - 14)
    frame.itemIdInput = itemIdInput

    -- Yell: Yell text
    local yellLabel = frame:CreateFontString(nil, "OVERLAY")
    yellLabel:SetFont(fontPath, 10, fontOutline)
    yellLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    yellLabel:SetText("Yell Text (partial match):")
    yellLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    frame.yellLabel = yellLabel

    local yellInput = CreateStyledInput(frame, 350, 24, false)
    yellInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset - 14)
    frame.yellInput = yellInput

    -- Multi-Kill: NPC IDs
    local multiIdsLabel = frame:CreateFontString(nil, "OVERLAY")
    multiIdsLabel:SetFont(fontPath, 10, fontOutline)
    multiIdsLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    multiIdsLabel:SetText("NPC IDs (comma separated):")
    multiIdsLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    frame.multiIdsLabel = multiIdsLabel

    local multiIdsInput = CreateStyledInput(frame, 250, 24, false)
    multiIdsInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset - 14)
    frame.multiIdsInput = multiIdsInput

    -- Add button
    local addBtn = CreateStyledButton(frame, 70, 28, "+ Add")
    addBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 440, yOffset - 10)
    addBtn:SetBackdropColor(0.15, 0.45, 0.15, 1)
    frame.addBtn = addBtn

    addBtn:SetScript("OnClick", function()
        local entryType = frame.typeDropdown.selectedValue or "kill"
        local entryName = frame.entryNameInput:GetText()
        local note = frame.noteInput:GetText()

        if not entryName or entryName == "" then
            KOL:PrintTag(RED("Error:") .. " Entry name is required!")
            return
        end

        local newEntry = {
            name = entryName,
            type = entryType,
        }

        if note and note ~= "" then
            newEntry.note = note
        end

        -- Get type-specific data
        if entryType == "kill" then
            local npcId = tonumber(frame.npcIdInput:GetText())
            if not npcId then
                KOL:PrintTag(RED("Error:") .. " Valid NPC ID required!")
                return
            end
            newEntry.id = npcId
        elseif entryType == "loot" then
            local itemId = tonumber(frame.itemIdInput:GetText())
            if not itemId then
                KOL:PrintTag(RED("Error:") .. " Valid Item ID required!")
                return
            end
            newEntry.itemId = itemId
        elseif entryType == "yell" then
            local yellText = frame.yellInput:GetText()
            if not yellText or yellText == "" then
                KOL:PrintTag(RED("Error:") .. " Yell text required!")
                return
            end
            newEntry.yell = yellText
        elseif entryType == "multikill" then
            local idsText = frame.multiIdsInput:GetText()
            if not idsText or idsText == "" then
                KOL:PrintTag(RED("Error:") .. " NPC IDs required!")
                return
            end
            local ids = {}
            for id in string.gmatch(idsText, "(%d+)") do
                table.insert(ids, tonumber(id))
            end
            if #ids < 2 then
                KOL:PrintTag(RED("Error:") .. " Multi-kill needs at least 2 NPC IDs!")
                return
            end
            newEntry.ids = ids
        end

        -- Add to entries
        if not frame.entries then frame.entries = {} end
        table.insert(frame.entries, newEntry)

        -- Clear inputs
        frame.entryNameInput:SetText("")
        frame.noteInput:SetText("")
        frame.npcIdInput:SetText("")
        frame.itemIdInput:SetText("")
        frame.yellInput:SetText("")
        frame.multiIdsInput:SetText("")

        -- Refresh list
        RenderEntriesList(frame)
        KOL:PrintTag(GREEN("Added: ") .. entryName)
    end)

    -- Initialize with kill type visible
    UpdateInputFields(frame, "kill")

    yOffset = yOffset - 50

    -- ========================================================================
    -- Entries List
    -- ========================================================================

    local entriesHeader = frame:CreateFontString(nil, "OVERLAY")
    entriesHeader:SetFont(fontPath, 12, fontOutline)
    entriesHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    entriesHeader:SetText("|cFF88CCFFEntries|r")

    yOffset = yOffset - 18

    -- Entries container (scrollable area would be better for many entries)
    local entriesContainer = CreateFrame("Frame", nil, frame)
    entriesContainer:SetWidth(contentWidth)
    entriesContainer:SetHeight(150)
    entriesContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    frame.entriesContainer = entriesContainer

    -- ========================================================================
    -- Bottom Buttons
    -- ========================================================================

    local saveBtn = CreateStyledButton(frame, 100, 32, "Save Panel")
    saveBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 12)
    saveBtn:SetBackdropColor(0.15, 0.5, 0.15, 1)
    frame.saveBtn = saveBtn

    local cancelBtn = CreateStyledButton(frame, 80, 32, "Cancel")
    cancelBtn:SetPoint("BOTTOMRIGHT", saveBtn, "BOTTOMLEFT", -10, 0)
    frame.cancelBtn = cancelBtn

    cancelBtn:SetScript("OnClick", function() frame:Hide() end)

    saveBtn:SetScript("OnClick", function()
        local panelName = frame.nameInput:GetText()
        if not panelName or panelName == "" then
            KOL:PrintTag(RED("Error:") .. " Panel name is required!")
            return
        end

        -- Parse zones
        local zonesText = frame.zonesInput:GetText() or ""
        local zones = {}
        for zone in string.gmatch(zonesText, "[^,]+") do
            zone = strtrim(zone)
            if zone ~= "" then
                table.insert(zones, zone)
            end
        end

        -- Get color name
        local colorName = frame.colorInput:GetText() or "PINK"

        -- Build data
        local data = {
            entries = frame.entries or {}
        }

        -- Save or update
        if currentEditingPanelId then
            KOL.Tracker:UpdateCustomPanel(
                currentEditingPanelId,
                panelName,
                zones,
                colorName,
                "custom",
                data
            )
            KOL:PrintTag(GREEN("Panel updated: ") .. panelName)
        else
            KOL.Tracker:CreateCustomPanel(
                panelName,
                zones,
                colorName,
                "custom",
                data
            )
            KOL:PrintTag(GREEN("Panel created: ") .. panelName)
        end

        frame:Hide()
    end)

    frame.entries = {}
    editorFrame = frame
    return frame
end

-- ============================================================================
-- Public API
-- ============================================================================

function KOL:ShowCustomPanelEditor(panelId)
    local editor = CreateCustomPanelEditor()

    currentEditingPanelId = panelId

    if panelId then
        -- Editing existing panel
        local data = KOL.Tracker.instances[panelId]
        if data then
            editor.title:SetText("Edit: " .. data.name)
            editor.nameInput:SetText(data.name or "")

            -- Load zones
            if data.zones and #data.zones > 0 then
                editor.zonesInput:SetText(table.concat(data.zones, ", "))
            else
                editor.zonesInput:SetText("")
            end

            -- Load color
            if data.color then
                if type(data.color) == "string" then
                    editor.colorInput:SetText(data.color)
                else
                    editor.colorInput:SetText("PINK")
                end
            end

            -- Load entries (support both old and new formats)
            editor.entries = {}

            -- New format: entries array
            if data.entries and #data.entries > 0 then
                for _, entry in ipairs(data.entries) do
                    table.insert(editor.entries, {
                        name = entry.name,
                        type = entry.type or "kill",
                        id = entry.id,
                        itemId = entry.itemId,
                        itemIds = entry.itemIds,
                        yell = entry.yell,
                        ids = entry.ids,
                        note = entry.note,
                    })
                end
            -- Old format: groups with bosses
            elseif data.groups and #data.groups > 0 then
                for _, group in ipairs(data.groups) do
                    if group.bosses then
                        for _, boss in ipairs(group.bosses) do
                            table.insert(editor.entries, {
                                name = boss.name,
                                type = KOL.Tracker:GetDetectionType(boss),
                                id = type(boss.id) == "number" and boss.id or nil,
                                ids = type(boss.id) == "table" and boss.id or nil,
                                yell = boss.yell,
                                note = group.name,  -- Use group name as note
                            })
                        end
                    end
                end
            -- Old format: objectives
            elseif data.objectives and #data.objectives > 0 then
                for _, obj in ipairs(data.objectives) do
                    table.insert(editor.entries, {
                        name = obj.name,
                        type = "kill",
                        note = "Converted from objective",
                    })
                end
            end
        end
    else
        -- Creating new panel
        editor.title:SetText("Create Custom Panel")
        editor.nameInput:SetText("")
        editor.zonesInput:SetText("")
        editor.colorInput:SetText("PINK")
        editor.entries = {}
    end

    -- Reset input fields
    editor.entryNameInput:SetText("")
    editor.noteInput:SetText("")
    editor.npcIdInput:SetText("")
    editor.itemIdInput:SetText("")
    editor.yellInput:SetText("")
    editor.multiIdsInput:SetText("")
    editor.typeDropdown.selectedValue = "kill"
    editor.typeDropdown.text:SetText(ENTRY_TYPES[1].icon .. " " .. ENTRY_TYPES[1].label)
    UpdateInputFields(editor, "kill")

    -- Render entries
    RenderEntriesList(editor)

    editor:Show()
    KOL:DebugPrint("Custom Panel Editor: Opened", 2)
end

KOL:DebugPrint("Tracker Editor: Module loaded (unified schema)", 1)
