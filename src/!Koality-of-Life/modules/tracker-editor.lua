-- ============================================================================
-- !Koality-of-Life: Progress Tracker - Manage Tracker Panel
-- ============================================================================
-- Unified entry editor with type dropdown (Kill/Loot/Yell/Multi-Kill)
-- Compact layout with all inputs on minimal lines
-- ============================================================================

local KOL = KoalityOfLife
local UIFactory = KOL.UIFactory

-- Store reference to editor frame
local editorFrame = nil
local currentEditingPanelId = nil
local currentEditingEntryIndex = nil  -- Track which entry is being edited
local currentEditingGroupIndex = nil  -- Track which group is being edited

-- Entry type icons and labels
local ENTRY_TYPES = {
    {value = "kill", label = "Kill (NPC)", icon = "|cFF00FF00*|r"},
    {value = "loot", label = "Loot (Item)", icon = "|cFFFFD700$|r"},
    {value = "yell", label = "Yell", icon = "|cFF00BFFF!|r"},
    {value = "multikill", label = "Multi-Kill", icon = "|cFFFF6600#|r"},
}

-- Available title colors for dropdown
local TITLE_COLORS = {
    {value = "PINK", label = "Pink", color = "|cFFFF69B4"},
    {value = "RED", label = "Red", color = "|cFFFF4444"},
    {value = "ORANGE", label = "Orange", color = "|cFFFF8800"},
    {value = "YELLOW", label = "Yellow", color = "|cFFFFFF00"},
    {value = "GREEN", label = "Green", color = "|cFF00FF00"},
    {value = "CYAN", label = "Cyan", color = "|cFF00FFFF"},
    {value = "BLUE", label = "Blue", color = "|cFF4488FF"},
    {value = "PURPLE", label = "Purple", color = "|cFFAA66FF"},
    {value = "WHITE", label = "White", color = "|cFFFFFFFF"},
    {value = "PASTEL_PINK", label = "Pastel Pink", color = "|cFFFFB6C1"},
    {value = "PASTEL_BLUE", label = "Pastel Blue", color = "|cFF87CEEB"},
    {value = "PASTEL_GREEN", label = "Pastel Green", color = "|cFF98FB98"},
    {value = "PASTEL_YELLOW", label = "Pastel Yellow", color = "|cFFFFFFAA"},
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

-- Convert ENTRY_TYPES to dropdown items format
local function GetTypeDropdownItems()
    local items = {}
    for _, t in ipairs(ENTRY_TYPES) do
        table.insert(items, {
            value = t.value,
            label = t.label,
            icon = t.icon,
        })
    end
    return items
end

-- Convert TITLE_COLORS to dropdown items format
local function GetColorDropdownItems()
    local items = {}
    for _, c in ipairs(TITLE_COLORS) do
        table.insert(items, {
            value = c.value,
            label = c.label,
            color = c.color,
        })
    end
    return items
end

-- ============================================================================
-- Dynamic Input Fields (must be before RenderEntriesList)
-- ============================================================================

local function UpdateInputFields(editor, entryType)
    -- Update the ID label and show/hide appropriate field
    -- ID field has 110px width to fit the new layout with Group dropdown
    if entryType == "kill" then
        editor.idLabel:SetText("NPC ID:")
        editor.idInput:Show()
        editor.idInput:SetWidth(110)
    elseif entryType == "loot" then
        editor.idLabel:SetText("Item ID:")
        editor.idInput:Show()
        editor.idInput:SetWidth(110)
    elseif entryType == "yell" then
        editor.idLabel:SetText("Yell text:")
        editor.idInput:Show()
        editor.idInput:SetWidth(110)
    elseif entryType == "multikill" then
        editor.idLabel:SetText("IDs (csv):")
        editor.idInput:Show()
        editor.idInput:SetWidth(110)
    end
end

-- ============================================================================
-- Entries List Rendering
-- ============================================================================

-- Forward declaration (needed because helper functions call this)
local RenderEntriesList

-- Helper to render a single entry row
local function RenderEntryRow(container, editor, entry, i, yOffset, containerWidth, fontPath, fontOutline, indented)
    local rowHeight = 26

    -- Get icon
    local icon = "|cFF00FF00*|r"
    for _, t in ipairs(ENTRY_TYPES) do
        if t.value == entry.type then
            icon = t.icon
            break
        end
    end

    -- Entry row
    local row = CreateFrame("Frame", nil, container)
    row:SetWidth(containerWidth)
    row:SetHeight(rowHeight)
    row:SetPoint("TOPLEFT", container, "TOPLEFT", 0, yOffset)

    -- Icon + Name (indented if in a group)
    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(fontPath, 10, fontOutline)
    nameText:SetPoint("LEFT", row, "LEFT", indented and 20 or 4, 0)

    -- Format ID display based on type
    local info = ""
    if entry.type == "kill" and entry.id then
        info = " |cFF888888[NPC: " .. entry.id .. "]|r"
    elseif entry.type == "loot" and (entry.itemId or entry.itemIds) then
        local id = entry.itemId or (entry.itemIds and entry.itemIds[1])
        info = " |cFF888888[Item: " .. (id or "?") .. "]|r"
    elseif entry.type == "yell" and entry.yell then
        local shortYell = string.sub(entry.yell, 1, 15)
        if #entry.yell > 15 then shortYell = shortYell .. "..." end
        info = ' |cFF888888["' .. shortYell .. '"]|r'
    elseif entry.type == "multikill" and entry.ids then
        info = " |cFF888888[IDs: " .. table.concat(entry.ids, ",") .. "]|r"
    end

    nameText:SetText(icon .. " " .. (entry.name or "Unknown") .. info)
    nameText:SetTextColor(0.9, 0.9, 0.9, 1)

    -- DEL button
    local delBtn = UIFactory:CreateButton(row, "DEL", {
        type = "animated",
        textColor = {r = 1, g = 0.4, b = 0.4, a = 1},
        fontSize = 9,
        onClick = function()
            if currentEditingEntryIndex == i then
                currentEditingEntryIndex = nil
                if editor.addBtn and editor.addBtn.text then
                    editor.addBtn.text:SetText("SAVE")
                    if editor.AdjustNoteWidth then editor.AdjustNoteWidth("SAVE") end
                end
            end
            table.remove(editor.entries, i)
            RenderEntriesList(editor)
            KOL:PrintTag("|cFFFF6666Removed:|r " .. (entry.name or "Entry"))
            -- Trigger auto-save if enabled
            if editor.DoAutoSave then editor.DoAutoSave() end
        end,
    })
    delBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)

    -- DOWN button
    local downBtn = CreateFrame("Button", nil, row)
    downBtn:SetSize(16, 16)
    local downText = downBtn:CreateFontString(nil, "OVERLAY")
    downText:SetFont(CHAR_LIGATURESFONT, 10, CHAR_LIGATURESOUTLINE)
    downText:SetPoint("CENTER")
    downText:SetText(CHAR_ARROW_DOWNFILLED)
    downText:SetTextColor(0.7, 0.7, 0.7, 1)
    downBtn:SetScript("OnEnter", function() downText:SetTextColor(1, 1, 1, 1) end)
    downBtn:SetScript("OnLeave", function() downText:SetTextColor(0.7, 0.7, 0.7, 1) end)
    downBtn:SetScript("OnClick", function()
        if i < #editor.entries then
            local targetEntry = editor.entries[i + 1]
            local movingEntry = editor.entries[i]
            if targetEntry.group ~= movingEntry.group then
                movingEntry.group = targetEntry.group or ""
            end
            editor.entries[i], editor.entries[i + 1] = editor.entries[i + 1], editor.entries[i]
            if currentEditingEntryIndex == i then
                currentEditingEntryIndex = i + 1
            elseif currentEditingEntryIndex == i + 1 then
                currentEditingEntryIndex = i
            end
            RenderEntriesList(editor)
            if editor.DoAutoSave then editor.DoAutoSave() end
        end
    end)
    -- downBtn point set after editBtn is created below
    if i >= #editor.entries then downBtn:SetAlpha(0.3) end

    -- UP button
    local upBtn = CreateFrame("Button", nil, row)
    upBtn:SetSize(16, 16)
    local upText = upBtn:CreateFontString(nil, "OVERLAY")
    upText:SetFont(CHAR_LIGATURESFONT, 10, CHAR_LIGATURESOUTLINE)
    upText:SetPoint("CENTER")
    upText:SetText(CHAR_ARROW_UPFILLED)
    upText:SetTextColor(0.7, 0.7, 0.7, 1)
    upBtn:SetScript("OnEnter", function() upText:SetTextColor(1, 1, 1, 1) end)
    upBtn:SetScript("OnLeave", function() upText:SetTextColor(0.7, 0.7, 0.7, 1) end)
    upBtn:SetScript("OnClick", function()
        if i > 1 then
            local targetEntry = editor.entries[i - 1]
            local movingEntry = editor.entries[i]
            if targetEntry.group ~= movingEntry.group then
                movingEntry.group = targetEntry.group or ""
            end
            editor.entries[i], editor.entries[i - 1] = editor.entries[i - 1], editor.entries[i]
            if currentEditingEntryIndex == i then
                currentEditingEntryIndex = i - 1
            elseif currentEditingEntryIndex == i - 1 then
                currentEditingEntryIndex = i
            end
            RenderEntriesList(editor)
            if editor.DoAutoSave then editor.DoAutoSave() end
        end
    end)
    upBtn:SetPoint("RIGHT", downBtn, "LEFT", -4, 0)
    if i <= 1 then upBtn:SetAlpha(0.3) end

    -- EDIT button
    local editBtn = UIFactory:CreateButton(row, "EDIT", {
        type = "animated",
        textColor = {r = 0.4, g = 0.7, b = 1, a = 1},
        fontSize = 9,
        onClick = function()
            currentEditingEntryIndex = i
            editor.groupDropdown:SetValue(entry.group or "")
            editor.typeDropdown:SetValue(entry.type or "kill")
            UpdateInputFields(editor, entry.type or "kill")
            editor.entryNameInput:SetText(entry.name or "")
            editor.noteInput:SetText(entry.note or "")
            editor.countInput:SetText(tostring(entry.count or 1))
            if entry.type == "kill" and entry.id then
                editor.idInput:SetText(tostring(entry.id))
            elseif entry.type == "loot" and entry.itemId then
                editor.idInput:SetText(tostring(entry.itemId))
            elseif entry.type == "yell" and entry.yell then
                editor.idInput:SetText(entry.yell)
            elseif entry.type == "multikill" and entry.ids then
                editor.idInput:SetText(table.concat(entry.ids, ", "))
            else
                editor.idInput:SetText("")
            end
            if editor.addBtn and editor.addBtn.text then
                editor.addBtn.text:SetText("UPDATE")
                if editor.AdjustNoteWidth then editor.AdjustNoteWidth("UPDATE") end
            end
            KOL:PrintTag("|cFF55AAFFEditing:|r " .. (entry.name or "Entry"))
        end,
    })
    editBtn:SetPoint("RIGHT", delBtn, "LEFT", -8, 0)

    -- Now set downBtn point (after editBtn exists) - Order: UP, DOWN, EDIT, DEL
    downBtn:SetPoint("RIGHT", editBtn, "LEFT", -6, 0)

    return rowHeight
end

RenderEntriesList = function(editor)
    local container = editor.entriesContainer
    local fontPath, fontOutline = UIFactory.GetGeneralFont()

    -- Clear existing
    for _, child in ipairs({container:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, fs in ipairs({container:GetRegions()}) do
        if fs.SetText then fs:Hide() end
    end

    local rowHeight = 26
    local headerHeight = 20

    if not editor.entries or #editor.entries == 0 then
        local emptyText = container:CreateFontString(nil, "OVERLAY")
        emptyText:SetFont(fontPath, 10, fontOutline)
        emptyText:SetPoint("TOP", container, "TOP", 0, -10)
        emptyText:SetText("|cFFAAAAAANo entries added yet|r")
        container:SetHeight(40)
        return
    end

    local yOffset = -5
    local containerWidth = 455

    -- Organize entries by group (using editor.groups order, not entry order)
    local ungrouped = {}
    local grouped = {}  -- {groupName = {entries with indices}}

    -- Build groupOrder from editor.groups (this is the canonical order)
    local groupOrder = {}
    if editor.groups then
        for _, g in ipairs(editor.groups) do
            table.insert(groupOrder, g.name)
            grouped[g.name] = {}  -- Pre-create empty arrays for all groups
        end
    end

    -- Distribute entries into groups
    for i, entry in ipairs(editor.entries) do
        local grp = entry.group or ""
        if grp == "" then
            table.insert(ungrouped, {entry = entry, index = i})
        elseif grouped[grp] then
            -- Group exists in editor.groups
            table.insert(grouped[grp], {entry = entry, index = i})
        else
            -- Entry references a group that doesn't exist - treat as ungrouped
            table.insert(ungrouped, {entry = entry, index = i})
        end
    end

    -- Render ungrouped entries first (if any)
    if #ungrouped > 0 then
        local header = container:CreateFontString(nil, "OVERLAY")
        header:SetFont(fontPath, 9, fontOutline)
        header:SetPoint("TOPLEFT", container, "TOPLEFT", 4, yOffset)
        header:SetText("|cFF888888— Ungrouped —|r")
        yOffset = yOffset - headerHeight

        for _, data in ipairs(ungrouped) do
            RenderEntryRow(container, editor, data.entry, data.index, yOffset, containerWidth, fontPath, fontOutline, false)
            yOffset = yOffset - rowHeight
        end
        yOffset = yOffset - 5  -- Gap after section
    end

    -- Render each group with management buttons
    for groupIdx, groupName in ipairs(groupOrder) do
        local entries = grouped[groupName]

        -- Find the actual group index in editor.groups
        local actualGroupIdx = nil
        for gi, g in ipairs(editor.groups) do
            if g.name == groupName then
                actualGroupIdx = gi
                break
            end
        end

        -- Group header row
        local headerRow = CreateFrame("Frame", nil, container)
        headerRow:SetWidth(containerWidth)
        headerRow:SetHeight(headerHeight)
        headerRow:SetPoint("TOPLEFT", container, "TOPLEFT", 0, yOffset)

        -- Group header - arrow icon (needs ligatures font)
        local arrowIcon = headerRow:CreateFontString(nil, "OVERLAY")
        arrowIcon:SetFont(CHAR_LIGATURESFONT, 10, CHAR_LIGATURESOUTLINE)
        arrowIcon:SetPoint("LEFT", headerRow, "LEFT", 4, 0)
        arrowIcon:SetText("|cFFAAFFAA" .. CHAR_ARROW_RIGHTFILLED .. "|r")

        -- Group header - text (uses general font)
        local header = headerRow:CreateFontString(nil, "OVERLAY")
        header:SetFont(fontPath, 10, fontOutline)
        header:SetPoint("LEFT", arrowIcon, "RIGHT", 4, 0)
        header:SetText("|cFFAAFFAA" .. groupName .. "|r |cFF666666(" .. #entries .. ")|r")

        -- DEL button for group
        local delBtn = UIFactory:CreateButton(headerRow, "DEL", {
            type = "animated",
            textColor = {r = 1, g = 0.4, b = 0.4, a = 1},
            fontSize = 9,
            onClick = function()
                if currentEditingGroupIndex == actualGroupIdx then
                    currentEditingGroupIndex = nil
                    if editor.addGroupBtn and editor.addGroupBtn.text then
                        editor.addGroupBtn.text:SetText("ADD GROUP")
                    end
                end
                -- Remove group assignment from entries
                for _, entry in ipairs(editor.entries) do
                    if entry.group == groupName then
                        entry.group = nil
                    end
                end
                -- Remove group
                for gi, g in ipairs(editor.groups) do
                    if g.name == groupName then
                        table.remove(editor.groups, gi)
                        break
                    end
                end
                RenderEntriesList(editor)
                if editor.RefreshGroupDropdown then editor:RefreshGroupDropdown() end
                if editor.RefreshGroupsDisplay then editor:RefreshGroupsDisplay() end
                KOL:PrintTag("|cFFFF6666Removed group:|r " .. groupName)
                if editor.DoAutoSave then editor.DoAutoSave() end
            end,
        })
        delBtn:SetPoint("RIGHT", headerRow, "RIGHT", -4, 0)

        -- DOWN button for group
        local downBtn = CreateFrame("Button", nil, headerRow)
        downBtn:SetSize(16, 16)
        local downText = downBtn:CreateFontString(nil, "OVERLAY")
        downText:SetFont(CHAR_LIGATURESFONT, 10, CHAR_LIGATURESOUTLINE)
        downText:SetPoint("CENTER")
        downText:SetText(CHAR_ARROW_DOWNFILLED)
        downText:SetTextColor(0.7, 0.7, 0.7, 1)
        downBtn:SetScript("OnEnter", function() downText:SetTextColor(1, 1, 1, 1) end)
        downBtn:SetScript("OnLeave", function() downText:SetTextColor(0.7, 0.7, 0.7, 1) end)
        downBtn:SetScript("OnClick", function()
            if actualGroupIdx and actualGroupIdx < #editor.groups then
                editor.groups[actualGroupIdx], editor.groups[actualGroupIdx + 1] = editor.groups[actualGroupIdx + 1], editor.groups[actualGroupIdx]
                RenderEntriesList(editor)
                if editor.DoAutoSave then editor.DoAutoSave() end
            end
        end)
        -- downBtn point set after editBtn is created below
        if groupIdx >= #groupOrder then downBtn:SetAlpha(0.3) end

        -- UP button for group
        local upBtn = CreateFrame("Button", nil, headerRow)
        upBtn:SetSize(16, 16)
        local upText = upBtn:CreateFontString(nil, "OVERLAY")
        upText:SetFont(CHAR_LIGATURESFONT, 10, CHAR_LIGATURESOUTLINE)
        upText:SetPoint("CENTER")
        upText:SetText(CHAR_ARROW_UPFILLED)
        upText:SetTextColor(0.7, 0.7, 0.7, 1)
        upBtn:SetScript("OnEnter", function() upText:SetTextColor(1, 1, 1, 1) end)
        upBtn:SetScript("OnLeave", function() upText:SetTextColor(0.7, 0.7, 0.7, 1) end)
        upBtn:SetScript("OnClick", function()
            if actualGroupIdx and actualGroupIdx > 1 then
                editor.groups[actualGroupIdx], editor.groups[actualGroupIdx - 1] = editor.groups[actualGroupIdx - 1], editor.groups[actualGroupIdx]
                RenderEntriesList(editor)
                if editor.DoAutoSave then editor.DoAutoSave() end
            end
        end)
        upBtn:SetPoint("RIGHT", downBtn, "LEFT", -4, 0)
        if groupIdx <= 1 then upBtn:SetAlpha(0.3) end

        -- EDIT button for group
        local editBtn = UIFactory:CreateButton(headerRow, "EDIT", {
            type = "animated",
            textColor = {r = 0.4, g = 0.7, b = 1, a = 1},
            fontSize = 9,
            onClick = function()
                currentEditingGroupIndex = actualGroupIdx
                editor.groupNameInput:SetText(groupName)
                if editor.addGroupBtn and editor.addGroupBtn.text then
                    editor.addGroupBtn.text:SetText("UPDATE")
                end
                KOL:PrintTag("|cFF55AAFFEditing group:|r " .. groupName)
            end,
        })
        editBtn:SetPoint("RIGHT", delBtn, "LEFT", -8, 0)

        -- Now set downBtn point (after editBtn exists) - Order: UP, DOWN, EDIT, DEL
        downBtn:SetPoint("RIGHT", editBtn, "LEFT", -6, 0)

        yOffset = yOffset - headerHeight

        -- Group entries (indented)
        for _, data in ipairs(entries) do
            RenderEntryRow(container, editor, data.entry, data.index, yOffset, containerWidth, fontPath, fontOutline, true)
            yOffset = yOffset - rowHeight
        end
        yOffset = yOffset - 5  -- Gap after group
    end

    -- Set content height for proper scrolling
    local totalRows = #editor.entries + #groupOrder + (#ungrouped > 0 and 1 or 0)
    local contentHeight = math.max(40, math.abs(yOffset) + 10)
    container:SetHeight(contentHeight)

    -- Update scroll frame if it exists
    if editor.scrollFrame then
        editor.scrollFrame:UpdateScrollChildRect()
    end
end

-- ============================================================================
-- Custom Panel Editor
-- ============================================================================

local function CreateTrackerManager()
    if editorFrame then
        return editorFrame
    end

    -- Use UIFactory for consistent frame styling (no title bar)
    local frame = UIFactory:CreateStyledFrame(UIParent, "KOL_CustomPanelEditor", 520, 450, {
        movable = true,
        closable = true,
        strata = "TOOLTIP",  -- Highest strata to ensure it's above config dialog
        level = 100,  -- High frame level
    })
    frame:SetToplevel(true)  -- Ensure it stays on top when clicked
    frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)  -- Offset to the right

    local fontPath, fontOutline = UIFactory.GetGeneralFont()

    -- Content area (no title bar, start near top)
    local yOffset = -10

    -- ========================================================================
    -- Row 1: Panel Name | Zones | Title Color (all on one line)
    -- Layout: Name(160) + gap(10) + Zones(185) + gap(10) + TitleColor(130) = 495 (fits 496)
    -- ========================================================================

    -- Panel Name
    local nameLabel = frame:CreateFontString(nil, "OVERLAY")
    nameLabel:SetFont(fontPath, 10, fontOutline)
    nameLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
    nameLabel:SetText("Name:")
    nameLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local nameInput = CreateStyledInput(frame, 160, 22, false)
    nameInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset - 14)
    frame.nameInput = nameInput

    -- Zones
    local zonesLabel = frame:CreateFontString(nil, "OVERLAY")
    zonesLabel:SetFont(fontPath, 10, fontOutline)
    zonesLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 182, yOffset)
    zonesLabel:SetText("Zones:")
    zonesLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    -- Tooltip text for zones
    local zonesTooltipText = "Comma Separated List\nLeave blank to show in ALL zones"

    -- Create invisible button over label for tooltip
    local zonesLabelHitbox = CreateFrame("Button", nil, frame)
    zonesLabelHitbox:SetPoint("TOPLEFT", zonesLabel, "TOPLEFT", 0, 0)
    zonesLabelHitbox:SetPoint("BOTTOMRIGHT", zonesLabel, "BOTTOMRIGHT", 0, 0)
    zonesLabelHitbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(zonesTooltipText, 1, 1, 0.8, 1, true)
        GameTooltip:Show()
    end)
    zonesLabelHitbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local zonesInput = CreateStyledInput(frame, 185, 22, false)
    zonesInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 182, yOffset - 14)
    frame.zonesInput = zonesInput

    -- Add tooltip to zones input
    zonesInput:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(zonesTooltipText, 1, 1, 0.8, 1, true)
        GameTooltip:Show()
    end)
    zonesInput:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Title Color (dropdown) - using UIFactory:CreateStyledDropdown
    local colorLabel = frame:CreateFontString(nil, "OVERLAY")
    colorLabel:SetFont(fontPath, 10, fontOutline)
    colorLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 377, yOffset)
    colorLabel:SetText("Title Color:")
    colorLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local colorDropdown = UIFactory:CreateStyledDropdown(frame, 125, {
        items = GetColorDropdownItems(),
        selectedValue = "PINK",
        maxVisible = 8,
    })
    colorDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 377, yOffset - 14)
    frame.colorDropdown = colorDropdown

    yOffset = yOffset - 48

    -- ========================================================================
    -- Groups Section
    -- ========================================================================

    local groupsHeader = frame:CreateFontString(nil, "OVERLAY")
    groupsHeader:SetFont(fontPath, 11, fontOutline)
    groupsHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
    groupsHeader:SetText("|cFF88CCFFGroups|r")

    yOffset = yOffset - 20

    -- Group name input
    local groupNameLabel = frame:CreateFontString(nil, "OVERLAY")
    groupNameLabel:SetFont(fontPath, 10, fontOutline)
    groupNameLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
    groupNameLabel:SetText("Group Name:")
    groupNameLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local groupNameInput = CreateStyledInput(frame, 200, 22, false)
    groupNameInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset - 14)
    frame.groupNameInput = groupNameInput

    -- ADD GROUP button
    local addGroupBtn = UIFactory:CreateButton(frame, "ADD GROUP", {
        type = "animated",
        textColor = {r = 0.6, g = 0.9, b = 0.6, a = 1},
        fontSize = 10,
        onClick = function()
            local groupName = frame.groupNameInput:GetText()
            if not groupName or groupName == "" then
                KOL:PrintTag(RED("Error:") .. " Group name is required!")
                return
            end

            if not frame.groups then frame.groups = {} end

            -- Check if we're editing an existing group
            if currentEditingGroupIndex then
                local oldName = frame.groups[currentEditingGroupIndex].name

                -- Check for duplicate (but allow same name for the group being edited)
                for idx, g in ipairs(frame.groups) do
                    if g.name == groupName and idx ~= currentEditingGroupIndex then
                        KOL:PrintTag(RED("Error:") .. " Group '" .. groupName .. "' already exists!")
                        return
                    end
                end

                -- Update entries that had the old group name
                if frame.entries and oldName ~= groupName then
                    for _, entry in ipairs(frame.entries) do
                        if entry.group == oldName then
                            entry.group = groupName
                        end
                    end
                end

                frame.groups[currentEditingGroupIndex].name = groupName
                KOL:PrintTag(GREEN("Updated group: ") .. groupName)

                -- Clear edit state
                currentEditingGroupIndex = nil
                frame.addGroupBtn.text:SetText("ADD GROUP")
            else
                -- Adding new group - check for duplicate
                for _, g in ipairs(frame.groups) do
                    if g.name == groupName then
                        KOL:PrintTag(RED("Error:") .. " Group '" .. groupName .. "' already exists!")
                        return
                    end
                end

                table.insert(frame.groups, {name = groupName})
                KOL:PrintTag(GREEN("Added group: ") .. groupName)
            end

            frame.groupNameInput:SetText("")

            -- Refresh displays
            RenderEntriesList(frame)
            if frame.RefreshGroupDropdown then
                frame:RefreshGroupDropdown()
            end
            if frame.RefreshGroupsDisplay then
                frame:RefreshGroupsDisplay()
            end

            -- Trigger auto-save if enabled
            if frame.DoAutoSave then frame.DoAutoSave() end
        end,
    })
    addGroupBtn:SetPoint("LEFT", groupNameInput, "RIGHT", 12, 0)
    frame.addGroupBtn = addGroupBtn

    -- Inline display of existing groups
    local groupsListText = frame:CreateFontString(nil, "OVERLAY")
    groupsListText:SetFont(fontPath, 10, fontOutline)
    groupsListText:SetPoint("LEFT", addGroupBtn, "RIGHT", 12, 0)
    groupsListText:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
    groupsListText:SetJustifyH("LEFT")
    groupsListText:SetTextColor(0.6, 0.8, 0.6, 1)
    frame.groupsListText = groupsListText

    -- Function to refresh the inline groups display
    frame.RefreshGroupsDisplay = function(self)
        if not self.groups or #self.groups == 0 then
            self.groupsListText:SetText("|cFF666666(no groups)|r")
        else
            local names = {}
            for _, g in ipairs(self.groups) do
                table.insert(names, "|cFF88FF88" .. g.name .. "|r")
            end
            self.groupsListText:SetText(table.concat(names, ", "))
        end
    end

    yOffset = yOffset - 48

    -- ========================================================================
    -- Entry Data Section
    -- ========================================================================

    local addHeader = frame:CreateFontString(nil, "OVERLAY")
    addHeader:SetFont(fontPath, 11, fontOutline)
    addHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
    addHeader:SetText("|cFF88CCFFEntry Data|r")

    yOffset = yOffset - 20

    -- Row 2: Group | Type | Name (on one line)
    -- Layout: Group(110) + gap(10) + Type(110) + gap(10) + Name(150) = 390
    local groupLabel = frame:CreateFontString(nil, "OVERLAY")
    groupLabel:SetFont(fontPath, 10, fontOutline)
    groupLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
    groupLabel:SetText("Group:")
    groupLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    -- Group dropdown for entries
    local groupDropdown = UIFactory:CreateStyledDropdown(frame, 110, {
        items = {{value = "", label = "(No Group)"}},
        selectedValue = "",
    })
    groupDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset - 14)
    frame.groupDropdown = groupDropdown

    -- Function to refresh group dropdown items
    frame.RefreshGroupDropdown = function(self)
        local items = {{value = "", label = "(No Group)"}}
        if self.groups then
            for _, g in ipairs(self.groups) do
                table.insert(items, {value = g.name, label = g.name})
            end
        end
        self.groupDropdown:SetItems(items)
    end

    local typeLabel = frame:CreateFontString(nil, "OVERLAY")
    typeLabel:SetFont(fontPath, 10, fontOutline)
    typeLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 132, yOffset)
    typeLabel:SetText("Type:")
    typeLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    -- Type dropdown - using UIFactory:CreateStyledDropdown
    local typeDropdown = UIFactory:CreateStyledDropdown(frame, 110, {
        items = GetTypeDropdownItems(),
        selectedValue = "kill",
        onSelect = function(value)
            UpdateInputFields(frame, value)
        end,
    })
    typeDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 132, yOffset - 14)
    frame.typeDropdown = typeDropdown

    local entryNameLabel = frame:CreateFontString(nil, "OVERLAY")
    entryNameLabel:SetFont(fontPath, 10, fontOutline)
    entryNameLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 252, yOffset)
    entryNameLabel:SetText("Name:")
    entryNameLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local entryNameInput = CreateStyledInput(frame, 130, 22, false)
    entryNameInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 252, yOffset - 14)
    frame.entryNameInput = entryNameInput

    local idLabel = frame:CreateFontString(nil, "OVERLAY")
    idLabel:SetFont(fontPath, 10, fontOutline)
    idLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 392, yOffset)
    idLabel:SetText("NPC ID:")
    idLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    frame.idLabel = idLabel

    local idInput = CreateStyledInput(frame, 110, 22, false)
    idInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 392, yOffset - 14)
    frame.idInput = idInput

    yOffset = yOffset - 48

    -- Row 3: Note | Count | [+ Add] button
    -- Layout: Note(dynamic) + gap(8) + Count label + Count(50) + gap(8) + AddBtn
    local noteLabel = frame:CreateFontString(nil, "OVERLAY")
    noteLabel:SetFont(fontPath, 10, fontOutline)
    noteLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
    noteLabel:SetText("Note (optional):")
    noteLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local noteInput = CreateStyledInput(frame, 200, 22, false)
    noteInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset - 14)
    frame.noteInput = noteInput

    -- Count field (how many needed to complete) - anchored to right of note
    local countLabel = frame:CreateFontString(nil, "OVERLAY")
    countLabel:SetFont(fontPath, 10, fontOutline)
    countLabel:SetPoint("LEFT", noteInput, "RIGHT", 8, 0)
    countLabel:SetPoint("TOP", noteLabel, "TOP", 0, 0)
    countLabel:SetText("Count:")
    countLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local countInput = CreateStyledInput(frame, 50, 22, false)
    countInput:SetPoint("LEFT", noteInput, "RIGHT", 8, 0)
    countInput:SetPoint("TOP", noteInput, "TOP", 0, 0)
    countInput:SetText("1")  -- Default to 1
    countInput:SetNumeric(true)  -- Only allow numbers
    frame.countInput = countInput
    frame.countLabel = countLabel

    -- Tooltip for count field
    countInput:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("How many times this must be completed\n(kills, loots, yells, etc.)", 1, 1, 0.8, 1, true)
        GameTooltip:Show()
    end)
    countInput:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- SAVE button (animated text-only, blue/purple color)
    local addBtn = UIFactory:CreateButton(frame, "SAVE", {
        type = "animated",
        textColor = {r = 0.5, g = 0.6, b = 1, a = 1},  -- Soft blue-purple
        fontSize = 11,
        onClick = function(self)
            local entryType = frame.typeDropdown:GetValue() or "kill"
            local entryName = frame.entryNameInput:GetText()
            local note = frame.noteInput:GetText()
            local idText = frame.idInput:GetText()
            local groupName = frame.groupDropdown:GetValue() or ""
            local countText = frame.countInput:GetText()
            local count = tonumber(countText) or 1
            if count < 1 then count = 1 end

            if not entryName or entryName == "" then
                KOL:PrintTag(RED("Error:") .. " Entry name is required!")
                return
            end

            local newEntry = {
                name = entryName,
                type = entryType,
                count = count,
            }

            -- Add group if selected
            if groupName and groupName ~= "" then
                newEntry.group = groupName
            end

            if note and note ~= "" then
                newEntry.note = note
            end

            -- Get type-specific data
            if entryType == "kill" then
                local npcId = tonumber(idText)
                if not npcId then
                    KOL:PrintTag(RED("Error:") .. " Valid NPC ID required!")
                    return
                end
                newEntry.id = npcId
            elseif entryType == "loot" then
                local itemId = tonumber(idText)
                if not itemId then
                    KOL:PrintTag(RED("Error:") .. " Valid Item ID required!")
                    return
                end
                newEntry.itemId = itemId
            elseif entryType == "yell" then
                if not idText or idText == "" then
                    KOL:PrintTag(RED("Error:") .. " Yell text required!")
                    return
                end
                newEntry.yell = idText
            elseif entryType == "multikill" then
                if not idText or idText == "" then
                    KOL:PrintTag(RED("Error:") .. " NPC IDs required!")
                    return
                end
                local ids = {}
                for id in string.gmatch(idText, "(%d+)") do
                    table.insert(ids, tonumber(id))
                end
                if #ids < 2 then
                    KOL:PrintTag(RED("Error:") .. " Multi-kill needs at least 2 NPC IDs!")
                    return
                end
                newEntry.ids = ids
            end

            -- Check if we're editing an existing entry
            if currentEditingEntryIndex then
                local existingEntry = frame.entries[currentEditingEntryIndex]

                -- If name changed, add as new entry; otherwise update existing
                if existingEntry and existingEntry.name == entryName then
                    -- Same name - update existing entry
                    frame.entries[currentEditingEntryIndex] = newEntry
                    KOL:PrintTag(GREEN("Updated: ") .. entryName)
                else
                    -- Name changed - add as new entry (don't overwrite)
                    if not frame.entries then frame.entries = {} end
                    table.insert(frame.entries, newEntry)
                    KOL:PrintTag(GREEN("Added: ") .. entryName .. " (name changed, created new entry)")
                end

                -- Clear edit state
                currentEditingEntryIndex = nil
                self.text:SetText("SAVE")
                if frame.AdjustNoteWidth then frame.AdjustNoteWidth("SAVE") end
            else
                -- Not editing - add new entry
                if not frame.entries then frame.entries = {} end
                table.insert(frame.entries, newEntry)
                KOL:PrintTag(GREEN("Added: ") .. entryName)
            end

            -- Clear inputs
            frame.entryNameInput:SetText("")
            frame.noteInput:SetText("")
            frame.idInput:SetText("")
            frame.countInput:SetText("1")
            frame.groupDropdown:SetValue("")

            -- Refresh list
            RenderEntriesList(frame)

            -- Trigger auto-save if enabled
            if frame.DoAutoSave then frame.DoAutoSave() end
        end,
    })
    addBtn:SetPoint("LEFT", countInput, "RIGHT", 8, 0)
    frame.addBtn = addBtn

    -- Helper to adjust button width AND note input width based on button text
    local function AdjustNoteWidth(buttonText)
        -- Measure the text width
        local tempFS = frame:CreateFontString(nil, "OVERLAY")
        local fontPath2, fontOutline2 = UIFactory.GetGeneralFont()
        tempFS:SetFont(fontPath2, 11, fontOutline2)
        tempFS:SetText(buttonText)
        local textWidth = tempFS:GetStringWidth()
        tempFS:Hide()

        -- Set button width to fit text with padding
        local buttonWidth = textWidth + 16
        addBtn:SetWidth(buttonWidth)

        -- Adjust note input width:
        -- frame(520) - leftMargin(12) - gap(8) - countInput(50) - gap(8) - buttonWidth - rightMargin(12)
        local availableWidth = 520 - 12 - 8 - 50 - 8 - buttonWidth - 12
        noteInput:SetWidth(availableWidth)
    end
    frame.AdjustNoteWidth = AdjustNoteWidth

    -- Set initial widths based on "SAVE" text
    AdjustNoteWidth("SAVE")

    -- Initialize with kill type visible
    UpdateInputFields(frame, "kill")

    yOffset = yOffset - 50

    -- ========================================================================
    -- Entries List (Scrollable using UIFactory)
    -- ========================================================================

    local entriesHeader = frame:CreateFontString(nil, "OVERLAY")
    entriesHeader:SetFont(fontPath, 11, fontOutline)
    entriesHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
    entriesHeader:SetText("|cFF88CCFFEntries|r")

    yOffset = yOffset - 18

    -- Scroll frame container - extends from current yOffset down to just above bottom buttons
    local scrollContainer = CreateFrame("Frame", nil, frame)
    scrollContainer:SetWidth(490)
    scrollContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
    scrollContainer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 38)  -- 38px from bottom for buttons
    scrollContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1
    })
    scrollContainer:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
    scrollContainer:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

    -- Create scrollable content using UIFactory (uses Theme colors automatically)
    -- Use larger right inset to keep scrollbar inside the container
    local entriesContainer, scrollFrame = UIFactory:CreateScrollableContent(scrollContainer, {
        inset = {top = 4, bottom = 4, left = 4, right = 24},  -- Right inset for scrollbar
        showScrollbar = true,
        -- scrollbarColor not specified = use Theme system colors
    })
    entriesContainer:SetWidth(455)  -- Scroll content width (adjusted for scrollbar)
    frame.entriesContainer = entriesContainer
    frame.scrollFrame = scrollFrame
    -- Note: Scrollbar is skinned automatically by UIFactory:CreateScrollableContent

    -- ========================================================================
    -- Bottom Buttons (Text-only with rainbow hover)
    -- ========================================================================

    local saveBtn = UIFactory:CreateButton(frame, "Save Tracker", {
        type = "animated",
        textColor = {r = 0.5, g = 0.9, b = 0.5, a = 1},  -- Light green
        fontSize = 11,
        onClick = function()
            local panelName = frame.nameInput:GetText()
            if not panelName or panelName == "" then
                KOL:PrintTag(RED("Error:") .. " Tracker name is required!")
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

            -- Get color name from dropdown
            local colorName = frame.colorDropdown:GetValue() or "PINK"

            -- Get autoShow, showSpeed, showPrefix settings (UIFactory checkboxes use IsChecked())
            local autoShow = frame.autoShowCheck and frame.autoShowCheck:IsChecked() or false
            local showSpeed = frame.showSpeedCheck and frame.showSpeedCheck:IsChecked() or false
            local showPrefix = frame.showPrefixCheck and frame.showPrefixCheck:IsChecked() or false

            -- Build data
            local data = {
                entries = frame.entries or {},
                groups = frame.groups or {},
                autoShow = autoShow,
                showSpeed = showSpeed,
                showPrefix = showPrefix,
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
                KOL:PrintTag(GREEN("Tracker updated: ") .. panelName)
            else
                KOL.Tracker:CreateCustomPanel(
                    panelName,
                    zones,
                    colorName,
                    "custom",
                    data
                )
                KOL:PrintTag(GREEN("Tracker created: ") .. panelName)
            end

            -- Refresh the config UI so the new tracker appears in the dropdown
            if KOL.PopulateTrackerConfigUI then
                KOL:PopulateTrackerConfigUI()
            end
            LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")

            frame:Hide()
        end,
    })
    saveBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
    frame.saveBtn = saveBtn

    local cancelBtn = UIFactory:CreateButton(frame, "Cancel", {
        type = "animated",
        textColor = {r = 0.7, g = 0.7, b = 0.7, a = 1},  -- Gray
        fontSize = 11,
        onClick = function() frame:Hide() end,
    })
    cancelBtn:SetPoint("RIGHT", saveBtn, "LEFT", -15, 0)
    frame.cancelBtn = cancelBtn

    -- Bottom row checkboxes (left to right): Show Speed, Show Prefix, Auto Show, Live Update
    -- All use fontSize 9 to fit properly

    -- Helper function to show tooltip above the editor frame
    local function ShowEditorTooltip(widget, text)
        GameTooltip:SetOwner(frame, "ANCHOR_NONE")
        GameTooltip:SetPoint("BOTTOM", frame, "TOP", 0, 5)
        GameTooltip:SetText(text, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end

    -- Tooltips for Save and Cancel buttons
    local saveBtnTooltipText = "|cFFFFFFFFSave Tracker|r\n\nSaves all changes to this tracker\nincluding entries, groups, and settings.\n\n|cFF88FF88Tip:|r Use |cFFFFCC00Live Update|r checkbox\nto see changes in real-time."
    saveBtn:SetScript("OnEnter", function(self)
        ShowEditorTooltip(self, saveBtnTooltipText)
    end)
    saveBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local cancelBtnTooltipText = "|cFFFFFFFFCancel|r\n\nCloses the editor without saving.\n\n|cFFFF8888Warning:|r Any unsaved changes\nwill be lost!"
    cancelBtn:SetScript("OnEnter", function(self)
        ShowEditorTooltip(self, cancelBtnTooltipText)
    end)
    cancelBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Show Speed checkbox (show movement speed on custom tracker frame)
    local showSpeedCheck = UIFactory:CreateCheckbox(frame, "Show Speed", {
        fontSize = 9,
        labelColor = {r = 0.53, g = 0.67, b = 1, a = 1},  -- Light blue
        checkColor = {r = 0.4, g = 0.8, b = 1, a = 1},  -- Cyan check
        checked = false,
    })
    showSpeedCheck:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 14)
    frame.showSpeedCheck = showSpeedCheck

    -- Tooltip for Show Speed checkbox
    local showSpeedTooltipText = "|cFFFFFFFFShow Speed|r\n\nDisplays your current movement speed\non this tracker frame.\n\n|cFF88FF88Green|r = faster than base\n|cFFFF8888Red|r = slower than base"
    showSpeedCheck:SetScript("OnEnter", function(self)
        ShowEditorTooltip(self, showSpeedTooltipText)
    end)
    showSpeedCheck:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Show Prefix checkbox (show colored type prefix before objectives)
    local showPrefixCheck = UIFactory:CreateCheckbox(frame, "Show Prefix", {
        fontSize = 9,
        labelColor = {r = 0.53, g = 0.67, b = 1, a = 1},  -- Light blue
        checkColor = {r = 0.4, g = 0.8, b = 1, a = 1},  -- Cyan check
        checked = false,
    })
    showPrefixCheck:SetPoint("LEFT", showSpeedCheck, "RIGHT", 6, 0)
    frame.showPrefixCheck = showPrefixCheck

    -- Tooltip for Show Prefix checkbox
    local showPrefixTooltipText = "|cFFFFFFFFShow Prefix|r\n\nShows the colored type prefix before\neach objective on the watch frame.\n\n|cFF00FF00*|r Kill  |cFFFFD700$|r Loot  |cFF00BFFF!|r Yell  |cFFFF6600#|r Multi"
    showPrefixCheck:SetScript("OnEnter", function(self)
        ShowEditorTooltip(self, showPrefixTooltipText)
    end)
    showPrefixCheck:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Auto Show checkbox (auto-show tracker based on zone matching)
    local autoShowCheck = UIFactory:CreateCheckbox(frame, "Auto Show", {
        fontSize = 9,
        labelColor = {r = 0.53, g = 0.67, b = 1, a = 1},  -- Light blue
        checkColor = {r = 0.4, g = 0.8, b = 1, a = 1},  -- Cyan check
        checked = false,
    })
    autoShowCheck:SetPoint("LEFT", showPrefixCheck, "RIGHT", 6, 0)
    frame.autoShowCheck = autoShowCheck

    -- Tooltip for Auto Show checkbox
    local autoShowTooltipText = "|cFFFFFFFFAuto Show|r\n\nAutomatically shows this tracker frame\nwhen entering zones listed in the |cFF88DDFFZones|r field.\n\n|cFFFFAA00If Zones is blank:|r Shows everywhere."
    autoShowCheck:SetScript("OnEnter", function(self)
        ShowEditorTooltip(self, autoShowTooltipText)
    end)
    autoShowCheck:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Live Update checkbox (only visible when editing existing tracker)
    local autoUpdateCheck = UIFactory:CreateCheckbox(frame, "Live Update", {
        fontSize = 9,
        labelColor = {r = 0.53, g = 0.67, b = 1, a = 1},  -- Light blue
        checkColor = {r = 0.4, g = 0.8, b = 1, a = 1},  -- Cyan check
        checked = false,
    })
    autoUpdateCheck:SetPoint("LEFT", autoShowCheck, "RIGHT", 6, 0)
    autoUpdateCheck:Hide()  -- Hidden by default, shown when editing existing
    frame.autoUpdateCheck = autoUpdateCheck

    -- Tooltip for Live Update checkbox
    local autoUpdateTooltipText = "|cFFFFFFFFLive Update|r\n\nAutomatically updates the watch frame\nas you make changes in the editor.\n\n|cFFFFAA00Only available when editing existing trackers.|r"
    autoUpdateCheck:SetScript("OnEnter", function(self)
        ShowEditorTooltip(self, autoUpdateTooltipText)
    end)
    autoUpdateCheck:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Auto-save function (triggered when auto update is enabled)
    local function DoAutoSave()
        -- Debug: Log all checks
        local isShown = autoUpdateCheck:IsShown()
        local isChecked = autoUpdateCheck:IsChecked()
        KOL:DebugPrint("AutoSave: IsShown=" .. tostring(isShown) .. ", IsChecked=" .. tostring(isChecked) .. ", panelId=" .. tostring(currentEditingPanelId), 3)

        if not isShown then
            return
        end
        if not isChecked then
            return
        end
        if not currentEditingPanelId then
            KOL:DebugPrint("AutoSave: Skipped - no panel ID", 1)
            return
        end

        local panelName = frame.nameInput:GetText()
        if not panelName or panelName == "" then
            KOL:DebugPrint("AutoSave: Skipped - no panel name", 1)
            return
        end

        KOL:DebugPrint("AutoSave: Saving " .. panelName .. " (panelId=" .. currentEditingPanelId .. ")", 1)

        -- Parse zones
        local zonesText = frame.zonesInput:GetText() or ""
        local zones = {}
        for zone in string.gmatch(zonesText, "[^,]+") do
            zone = strtrim(zone)
            if zone ~= "" then
                table.insert(zones, zone)
            end
        end

        local colorName = frame.colorDropdown:GetValue() or "PINK"
        local autoShow = frame.autoShowCheck and frame.autoShowCheck:IsChecked() or false
        local showSpeed = frame.showSpeedCheck and frame.showSpeedCheck:IsChecked() or false
        local showPrefix = frame.showPrefixCheck and frame.showPrefixCheck:IsChecked() or false

        local data = {
            entries = frame.entries or {},
            groups = frame.groups or {},
            autoShow = autoShow,
            showSpeed = showSpeed,
            showPrefix = showPrefix,
        }

        KOL.Tracker:UpdateCustomPanel(
            currentEditingPanelId,
            panelName,
            zones,
            colorName,
            "custom",
            data
        )

        -- Ensure watch frame is visible and updated (for Live Update)
        -- This forces the watch frame to show and refresh even if not already active
        if KOL.Tracker.activeFrames[currentEditingPanelId] then
            KOL.Tracker:UpdateWatchFrame(currentEditingPanelId)
            KOL:DebugPrint("AutoSave: Updated existing watch frame", 3)
        else
            -- Show the watch frame so user can see live changes
            KOL.Tracker:ShowWatchFrame(currentEditingPanelId)
            KOL:DebugPrint("AutoSave: Created and showed new watch frame", 3)
        end

        -- Refresh config UI
        if KOL.PopulateTrackerConfigUI then
            KOL:PopulateTrackerConfigUI()
        end
        LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
    end
    frame.DoAutoSave = DoAutoSave

    -- Hook input changes for auto-save
    local origNameOnTextChanged = nameInput:GetScript("OnTextChanged")
    nameInput:SetScript("OnTextChanged", function(self, ...)
        if origNameOnTextChanged then origNameOnTextChanged(self, ...) end
        DoAutoSave()
    end)

    local origZonesOnTextChanged = zonesInput:GetScript("OnTextChanged")
    zonesInput:SetScript("OnTextChanged", function(self, ...)
        if origZonesOnTextChanged then origZonesOnTextChanged(self, ...) end
        DoAutoSave()
    end)

    -- Hook color dropdown for auto-save
    local origColorOnSelect = colorDropdown.onSelect
    colorDropdown.onSelect = function(value)
        if origColorOnSelect then origColorOnSelect(value) end
        DoAutoSave()
    end

    frame.entries = {}
    frame.groups = {}
    editorFrame = frame
    return frame
end

-- ============================================================================
-- Public API
-- ============================================================================

function KOL:ShowTrackerManager(panelId)
    local editor = CreateTrackerManager()

    currentEditingPanelId = panelId

    if panelId then
        -- Editing existing panel
        local data = KOL.Tracker.instances[panelId]
        if data then
            -- No title bar, just load data
            editor.nameInput:SetText(data.name or "")

            -- Load zones
            if data.zones and #data.zones > 0 then
                editor.zonesInput:SetText(table.concat(data.zones, ", "))
            else
                editor.zonesInput:SetText("")
            end

            -- Load color into dropdown (SetValue handles display text)
            local colorValue = (data.color and type(data.color) == "string") and data.color or "PINK"
            editor.colorDropdown:SetValue(colorValue)

            -- Load autoShow setting
            if editor.autoShowCheck then
                editor.autoShowCheck:SetChecked(data.autoShow or false)
            end

            -- Load showSpeed setting
            if editor.showSpeedCheck then
                editor.showSpeedCheck:SetChecked(data.showSpeed or false)
            end

            -- Load showPrefix setting
            if editor.showPrefixCheck then
                editor.showPrefixCheck:SetChecked(data.showPrefix or false)
            end

            -- Load groups
            editor.groups = {}
            if data.groups and #data.groups > 0 then
                for _, g in ipairs(data.groups) do
                    table.insert(editor.groups, {name = g.name})
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
                        group = entry.group,
                        count = entry.count,
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
                                note = group.name,
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
        -- Creating new tracker (no title bar)
        editor.nameInput:SetText("")
        editor.zonesInput:SetText("")
        editor.colorDropdown:SetValue("PINK")
        if editor.autoShowCheck then
            editor.autoShowCheck:SetChecked(false)
        end
        if editor.showSpeedCheck then
            editor.showSpeedCheck:SetChecked(false)
        end
        if editor.showPrefixCheck then
            editor.showPrefixCheck:SetChecked(false)
        end
        editor.entries = {}
        editor.groups = {}
    end

    -- Reset input fields and edit state
    currentEditingEntryIndex = nil
    editor.groupDropdown:SetValue("")
    editor.entryNameInput:SetText("")
    editor.noteInput:SetText("")
    editor.idInput:SetText("")
    editor.countInput:SetText("1")
    editor.typeDropdown:SetValue("kill")
    editor.groupNameInput:SetText("")
    UpdateInputFields(editor, "kill")

    -- Reset button text to SAVE and adjust note width
    if editor.addBtn and editor.addBtn.text then
        editor.addBtn.text:SetText("SAVE")
        if editor.AdjustNoteWidth then editor.AdjustNoteWidth("SAVE") end
    end

    -- Show/hide Auto Update checkbox based on editing existing vs new
    if panelId then
        -- Editing existing - show auto update checkbox
        editor.autoUpdateCheck:SetChecked(false)
        editor.autoUpdateCheck:Show()
    else
        -- Creating new - hide auto update checkbox
        editor.autoUpdateCheck:SetChecked(false)
        editor.autoUpdateCheck:Hide()
    end

    -- Reset group edit state
    currentEditingGroupIndex = nil
    if editor.addGroupBtn and editor.addGroupBtn.text then
        editor.addGroupBtn.text:SetText("ADD GROUP")
    end

    -- Refresh group dropdown and inline display
    if editor.RefreshGroupDropdown then
        editor:RefreshGroupDropdown()
    end
    if editor.RefreshGroupsDisplay then
        editor:RefreshGroupsDisplay()
    end

    -- Render entries
    RenderEntriesList(editor)

    editor:Show()
    editor:Raise()  -- Bring to front above config panel
    KOL:DebugPrint("Manage Tracker: Panel opened", 2)
end

KOL:DebugPrint("Tracker Editor: Module loaded (unified schema v2)", 1)
