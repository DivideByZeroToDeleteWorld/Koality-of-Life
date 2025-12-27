-- ============================================================================
-- !Koality-of-Life: Progress Tracker Custom Panel Editor
-- ============================================================================
-- UI for creating and editing custom tracking panels
-- ============================================================================

local KOL = KoalityOfLife
local UIFactory = KOL.UIFactory

-- Store reference to editor frame
local editorFrame = nil
local currentEditingPanelId = nil

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Create a styled input box
local function CreateStyledInput(parent, width, height, multiline)
    local input = CreateFrame("EditBox", nil, parent)
    input:SetWidth(width)
    input:SetHeight(height)
    input:SetAutoFocus(false)
    input:SetMultiLine(multiline or false)

    if multiline then
        input:SetMaxLetters(0)
    else
        input:SetMaxLetters(50)
    end

    -- Background
    input:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    input:SetBackdropColor(0.05, 0.05, 0.05, 1)
    input:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    -- Font
    local fontPath, fontOutline = UIFactory.GetGeneralFont()
    input:SetFont(fontPath, 11, fontOutline)
    input:SetTextColor(1, 1, 0.6, 1)
    input:SetTextInsets(4, 4, 2, 2)

    -- Scripts
    input:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    input:SetScript("OnEnterPressed", function(self)
        if not multiline then
            self:ClearFocus()
        end
    end)

    return input
end

-- Create a styled button
local function CreateStyledButton(parent, width, height, text)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height)

    -- Background
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    button:SetBackdropColor(0.2, 0.2, 0.2, 1)
    button:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    -- Text
    local fontPath, fontOutline = UIFactory.GetGeneralFont()
    local buttonText = button:CreateFontString(nil, "OVERLAY")
    buttonText:SetFont(fontPath, 11, fontOutline)
    buttonText:SetPoint("CENTER")
    buttonText:SetText(text)
    buttonText:SetTextColor(1, 1, 0.6, 1)
    button.text = buttonText

    -- Hover effect
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

-- ============================================================================
-- Custom Panel Editor
-- ============================================================================

local function CreateCustomPanelEditor()
    if editorFrame then
        return editorFrame
    end

    -- Create main frame
    local frame = CreateFrame("Frame", "KOL_CustomPanelEditor", UIParent)
    frame:SetWidth(600)
    frame:SetHeight(700)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")

    -- Main backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropColor(0.15, 0.15, 0.15, 0.95)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- Make it closable with ESC
    tinsert(UISpecialFrames, "KOL_CustomPanelEditor")

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetHeight(24)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
    })
    titleBar:SetBackdropColor(0.08, 0.08, 0.08, 1)

    -- Title
    local fontPath, fontOutline = UIFactory.GetGeneralFont()
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
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    closeButton:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
    closeButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.9)

    local xText = closeButton:CreateFontString(nil, "OVERLAY")
    xText:SetFont(fontPath, 12, fontOutline)
    xText:SetPoint("CENTER", 0, 0)
    xText:SetText("X")
    xText:SetTextColor(1, 0.4, 0.4, 1)
    closeButton.text = xText

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

    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Content area with scroll
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", -32, 48)
    frame.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 10)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    frame.scrollChild = scrollChild

    -- ========================================================================
    -- Basic Settings Section
    -- ========================================================================

    local yOffset = -10
    local contentWidth = scrollChild:GetWidth() - 20

    -- Panel Name
    local nameLabel = scrollChild:CreateFontString(nil, "OVERLAY")
    nameLabel:SetFont(fontPath, 11, fontOutline)
    nameLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    nameLabel:SetText("Panel Name:")
    nameLabel:SetTextColor(1, 1, 0.6, 1)

    yOffset = yOffset - 18
    local nameInput = CreateStyledInput(scrollChild, contentWidth, 24, false)
    nameInput:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    frame.nameInput = nameInput

    yOffset = yOffset - 32

    -- Panel Type
    local typeLabel = scrollChild:CreateFontString(nil, "OVERLAY")
    typeLabel:SetFont(fontPath, 11, fontOutline)
    typeLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    typeLabel:SetText("Panel Type:")
    typeLabel:SetTextColor(1, 1, 0.6, 1)

    yOffset = yOffset - 22

    local typeButtons = {}
    local buttonWidth = (contentWidth - 10) / 2

    local typeObjective = CreateStyledButton(scrollChild, buttonWidth, 24, "Objective-Based")
    typeObjective:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    typeButtons.objective = typeObjective

    local typeGrouped = CreateStyledButton(scrollChild, buttonWidth, 24, "Boss Groups")
    typeGrouped:SetPoint("TOPLEFT", typeObjective, "TOPRIGHT", 10, 0)
    typeButtons.grouped = typeGrouped

    frame.panelType = "objective"  -- Default

    -- Type selection scripts
    local function UpdateTypeButtons()
        if frame.panelType == "objective" then
            typeObjective:SetBackdropColor(0.4, 0.6, 0.4, 1)
            typeGrouped:SetBackdropColor(0.2, 0.2, 0.2, 1)
            -- Show objectives, hide groups
            frame.objectivesHeader:Show()
            frame.addObjectiveBtn:Show()
            frame.objectivesContainer:Show()
            frame.groupsHeader:Hide()
            frame.addGroupBtn:Hide()
            frame.groupsContainer:Hide()
        else
            typeObjective:SetBackdropColor(0.2, 0.2, 0.2, 1)
            typeGrouped:SetBackdropColor(0.4, 0.6, 0.4, 1)
            -- Show groups, hide objectives
            frame.objectivesHeader:Hide()
            frame.addObjectiveBtn:Hide()
            frame.objectivesContainer:Hide()
            frame.groupsHeader:Show()
            frame.addGroupBtn:Show()
            frame.groupsContainer:Show()
        end
    end

    typeObjective:SetScript("OnClick", function()
        frame.panelType = "objective"
        UpdateTypeButtons()
    end)

    typeGrouped:SetScript("OnClick", function()
        frame.panelType = "grouped"
        UpdateTypeButtons()
    end)

    UpdateTypeButtons()

    yOffset = yOffset - 32

    -- Zones (multi-line)
    local zonesLabel = scrollChild:CreateFontString(nil, "OVERLAY")
    zonesLabel:SetFont(fontPath, 11, fontOutline)
    zonesLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    zonesLabel:SetText("Zones (one per line):")
    zonesLabel:SetTextColor(1, 1, 0.6, 1)

    yOffset = yOffset - 18
    local zonesInput = CreateStyledInput(scrollChild, contentWidth, 60, true)
    zonesInput:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    frame.zonesInput = zonesInput

    yOffset = yOffset - 68

    -- Color
    local colorLabel = scrollChild:CreateFontString(nil, "OVERLAY")
    colorLabel:SetFont(fontPath, 11, fontOutline)
    colorLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    colorLabel:SetText("Panel Color:")
    colorLabel:SetTextColor(1, 1, 0.6, 1)

    yOffset = yOffset - 22

    -- Color picker would go here (simplified for now)
    local colorPreview = CreateFrame("Frame", nil, scrollChild)
    colorPreview:SetWidth(contentWidth)
    colorPreview:SetHeight(30)
    colorPreview:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    colorPreview:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    colorPreview:SetBackdropColor(1, 0.7, 0.9, 1)  -- Default PINK
    colorPreview:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    frame.colorPreview = colorPreview
    frame.selectedColor = {1, 0.7, 0.9}  -- Default PINK RGB

    yOffset = yOffset - 40

    -- ========================================================================
    -- Objectives Section (for objective-based panels)
    -- ========================================================================

    local objectivesHeader = scrollChild:CreateFontString(nil, "OVERLAY")
    objectivesHeader:SetFont(fontPath, 13, fontOutline)
    objectivesHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    objectivesHeader:SetText("Objectives")
    objectivesHeader:SetTextColor(0.6, 0.8, 1, 1)
    frame.objectivesHeader = objectivesHeader

    yOffset = yOffset - 22

    local addObjectiveBtn = CreateStyledButton(scrollChild, 150, 24, "+ Add Objective")
    addObjectiveBtn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    addObjectiveBtn:SetScript("OnClick", function()
        ShowObjectiveEditor(frame, nil)
    end)
    frame.addObjectiveBtn = addObjectiveBtn

    yOffset = yOffset - 30

    -- Objectives list container
    local objectivesContainer = CreateFrame("Frame", nil, scrollChild)
    objectivesContainer:SetWidth(contentWidth)
    objectivesContainer:SetHeight(200)
    objectivesContainer:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    frame.objectivesContainer = objectivesContainer

    yOffset = yOffset - 210

    -- ========================================================================
    -- Groups Section (for grouped panels)
    -- ========================================================================

    local groupsHeader = scrollChild:CreateFontString(nil, "OVERLAY")
    groupsHeader:SetFont(fontPath, 13, fontOutline)
    groupsHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    groupsHeader:SetText("Boss Groups")
    groupsHeader:SetTextColor(0.6, 0.8, 1, 1)
    frame.groupsHeader = groupsHeader

    yOffset = yOffset - 22

    local addGroupBtn = CreateStyledButton(scrollChild, 150, 24, "+ Add Group")
    addGroupBtn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    addGroupBtn:SetScript("OnClick", function()
        ShowGroupEditor(frame, nil)
    end)
    frame.addGroupBtn = addGroupBtn

    yOffset = yOffset - 30

    -- Groups list container
    local groupsContainer = CreateFrame("Frame", nil, scrollChild)
    groupsContainer:SetWidth(contentWidth)
    groupsContainer:SetHeight(200)
    groupsContainer:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    frame.groupsContainer = groupsContainer

    yOffset = yOffset - 210

    -- Update scroll child height
    scrollChild:SetHeight(math.abs(yOffset) + 20)

    -- ========================================================================
    -- Bottom Buttons
    -- ========================================================================

    local saveBtn = CreateStyledButton(frame, 100, 32, "Save")
    saveBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    saveBtn:SetBackdropColor(0.2, 0.6, 0.2, 1)
    frame.saveBtn = saveBtn

    local cancelBtn = CreateStyledButton(frame, 100, 32, "Cancel")
    cancelBtn:SetPoint("BOTTOMRIGHT", saveBtn, "BOTTOMLEFT", -10, 0)
    frame.cancelBtn = cancelBtn

    cancelBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    saveBtn:SetScript("OnClick", function()
        -- Collect data from form
        local panelName = frame.nameInput:GetText()
        if not panelName or panelName == "" then
            KOL:PrintTag(RED("Error:") .. " Panel name is required!")
            return
        end

        -- Parse zones
        local zonesText = frame.zonesInput:GetText() or ""
        local zones = {}
        for zone in string.gmatch(zonesText, "[^\n]+") do
            zone = strtrim(zone)
            if zone ~= "" then
                table.insert(zones, zone)
            end
        end

        -- Get color
        local color = frame.selectedColor or {1, 0.7, 0.9}

        -- Collect objectives or groups based on panel type
        local data = {}
        if frame.panelType == "objective" then
            data.objectives = frame.objectives or {}
        else
            data.groups = frame.groups or {}
        end

        -- Save or update
        if currentEditingPanelId then
            -- Update existing panel
            KOL.Tracker:UpdateCustomPanel(
                currentEditingPanelId,
                panelName,
                zones,
                color,
                frame.panelType,
                data
            )
        else
            -- Create new panel
            KOL.Tracker:CreateCustomPanel(
                panelName,
                zones,
                color,
                frame.panelType,
                data
            )
        end

        frame:Hide()
    end)

    -- Initialize data arrays
    frame.objectives = {}
    frame.groups = {}

    editorFrame = frame
    return frame
end

-- ============================================================================
-- Objective Management
-- ============================================================================

local function RenderObjectivesList(editor)
    -- Clear existing objective frames
    local container = editor.objectivesContainer
    for _, child in pairs({container:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    if not editor.objectives or #editor.objectives == 0 then
        local emptyText = container:CreateFontString(nil, "OVERLAY")
        local fontPath, fontOutline = UIFactory.GetGeneralFont()
        emptyText:SetFont(fontPath, 10, fontOutline)
        emptyText:SetPoint("TOP", container, "TOP", 0, -10)
        emptyText:SetText("|cFFAAAAAAAANo objectives added yet|r")
        return
    end

    local yOffset = -5
    for i, objective in ipairs(editor.objectives) do
        local objFrame = CreateFrame("Frame", nil, container)
        objFrame:SetWidth(container:GetWidth() - 10)
        objFrame:SetHeight(60)
        objFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 5, yOffset)

        -- Background
        objFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        objFrame:SetBackdropColor(0.1, 0.1, 0.1, 1)
        objFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        -- Objective name
        local fontPath, fontOutline = UIFactory.GetGeneralFont()
        local nameText = objFrame:CreateFontString(nil, "OVERLAY")
        nameText:SetFont(fontPath, 11, fontOutline)
        nameText:SetPoint("TOPLEFT", objFrame, "TOPLEFT", 8, -8)
        nameText:SetText(objective.name or "Unnamed Objective")
        nameText:SetTextColor(1, 1, 0.6, 1)

        -- Condition preview
        local condText = objFrame:CreateFontString(nil, "OVERLAY")
        condText:SetFont(fontPath, 9, fontOutline)
        condText:SetPoint("TOPLEFT", objFrame, "TOPLEFT", 8, -28)
        condText:SetPoint("TOPRIGHT", objFrame, "TOPRIGHT", -60, -28)
        condText:SetJustifyH("LEFT")
        local condPreview = objective.conditionString or "return true"
        if #condPreview > 50 then
            condPreview = string.sub(condPreview, 1, 47) .. "..."
        end
        condText:SetText("|cFFAAAAAAAACondition: " .. condPreview .. "|r")

        -- Delete button
        local deleteBtn = CreateStyledButton(objFrame, 50, 20, "Delete")
        deleteBtn:SetPoint("TOPRIGHT", objFrame, "TOPRIGHT", -5, -5)
        deleteBtn:SetBackdropColor(0.6, 0.2, 0.2, 1)
        deleteBtn:SetScript("OnClick", function()
            table.remove(editor.objectives, i)
            RenderObjectivesList(editor)
        end)

        -- Edit button
        local editBtn = CreateStyledButton(objFrame, 50, 20, "Edit")
        editBtn:SetPoint("TOPRIGHT", deleteBtn, "TOPLEFT", -5, 0)
        editBtn:SetScript("OnClick", function()
            ShowObjectiveEditor(editor, i)
        end)

        yOffset = yOffset - 65
    end
end

-- Show objective editor dialog
function ShowObjectiveEditor(editor, objectiveIndex)
    local objective = objectiveIndex and editor.objectives[objectiveIndex] or {}

    -- Create simple dialog using StaticPopup
    StaticPopupDialogs["KOL_OBJECTIVE_EDITOR"] = {
        text = objectiveIndex and "Edit Objective" or "Add Objective",
        button1 = "Save",
        button2 = "Cancel",
        hasEditBox = true,
        hasWideEditBox = true,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self)
            self.editBox:SetText(objective.name or "")
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
            local objName = self.editBox:GetText()
            if not objName or objName == "" then
                KOL:PrintTag(RED("Error:") .. " Objective name is required!")
                return
            end

            -- Show condition editor
            StaticPopupDialogs["KOL_OBJECTIVE_CONDITION"] = {
                text = "Enter Lua condition code:\n(Must return true/false)\n\nExample: return UnitHealth(\"player\") > 1000",
                button1 = "Save",
                button2 = "Cancel",
                hasEditBox = true,
                hasWideEditBox = true,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                OnShow = function(popup)
                    popup.editBox:SetText(objective.conditionString or "return true")
                    popup.editBox:SetFocus()
                end,
                OnAccept = function(popup)
                    local conditionString = popup.editBox:GetText()

                    -- Try to compile the condition
                    local conditionFunc = nil
                    local success, err = pcall(function()
                        conditionFunc = loadstring(conditionString)
                    end)

                    if not success or not conditionFunc then
                        KOL:PrintTag(RED("Error:") .. " Invalid Lua code: " .. tostring(err))
                        return
                    end

                    -- Save objective
                    local newObjective = {
                        name = objName,
                        conditionString = conditionString,
                        condition = conditionFunc,
                    }

                    if objectiveIndex then
                        editor.objectives[objectiveIndex] = newObjective
                    else
                        table.insert(editor.objectives, newObjective)
                    end

                    RenderObjectivesList(editor)
                    KOL:PrintTag(GREEN("Objective saved: ") .. objName)
                end,
                EditBoxOnEscapePressed = function(popup)
                    popup:GetParent():Hide()
                end,
            }
            StaticPopup_Show("KOL_OBJECTIVE_CONDITION")
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
    }

    StaticPopup_Show("KOL_OBJECTIVE_EDITOR")
end

-- ============================================================================
-- Group Management
-- ============================================================================

local function RenderGroupsList(editor)
    -- Clear existing group frames
    local container = editor.groupsContainer
    for _, child in pairs({container:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    if not editor.groups or #editor.groups == 0 then
        local emptyText = container:CreateFontString(nil, "OVERLAY")
        local fontPath, fontOutline = UIFactory.GetGeneralFont()
        emptyText:SetFont(fontPath, 10, fontOutline)
        emptyText:SetPoint("TOP", container, "TOP", 0, -10)
        emptyText:SetText("|cFFAAAAAAAANo groups added yet|r")
        return
    end

    local yOffset = -5
    for i, group in ipairs(editor.groups) do
        local groupFrame = CreateFrame("Frame", nil, container)
        groupFrame:SetWidth(container:GetWidth() - 10)

        -- Calculate height based on number of bosses
        local numBosses = group.bosses and #group.bosses or 0
        local frameHeight = 40 + (numBosses * 18) + 25
        groupFrame:SetHeight(frameHeight)
        groupFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 5, yOffset)

        -- Background
        groupFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        groupFrame:SetBackdropColor(0.1, 0.1, 0.1, 1)
        groupFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        -- Group name
        local fontPath, fontOutline = UIFactory.GetGeneralFont()
        local nameText = groupFrame:CreateFontString(nil, "OVERLAY")
        nameText:SetFont(fontPath, 11, fontOutline)
        nameText:SetPoint("TOPLEFT", groupFrame, "TOPLEFT", 8, -8)
        nameText:SetText((group.name or "Unnamed Group") .. " (" .. numBosses .. " bosses)")
        nameText:SetTextColor(1, 1, 0.6, 1)

        -- Boss list
        local bossYOffset = -28
        if group.bosses then
            for j, boss in ipairs(group.bosses) do
                local bossText = groupFrame:CreateFontString(nil, "OVERLAY")
                bossText:SetFont(fontPath, 9, fontOutline)
                bossText:SetPoint("TOPLEFT", groupFrame, "TOPLEFT", 16, bossYOffset)
                bossText:SetText("• " .. (boss.name or "Unknown") .. " (ID: " .. (boss.id or "0") .. ")")
                bossText:SetTextColor(0.7, 0.7, 0.7, 1)
                bossYOffset = bossYOffset - 18
            end
        end

        -- Delete button
        local deleteBtn = CreateStyledButton(groupFrame, 50, 20, "Delete")
        deleteBtn:SetPoint("TOPRIGHT", groupFrame, "TOPRIGHT", -5, -5)
        deleteBtn:SetBackdropColor(0.6, 0.2, 0.2, 1)
        deleteBtn:SetScript("OnClick", function()
            table.remove(editor.groups, i)
            RenderGroupsList(editor)
        end)

        -- Edit button
        local editBtn = CreateStyledButton(groupFrame, 50, 20, "Edit")
        editBtn:SetPoint("TOPRIGHT", deleteBtn, "TOPLEFT", -5, 0)
        editBtn:SetScript("OnClick", function()
            ShowGroupEditor(editor, i)
        end)

        -- Add Boss button
        local addBossBtn = CreateStyledButton(groupFrame, 80, 20, "+ Add Boss")
        addBossBtn:SetPoint("BOTTOMLEFT", groupFrame, "BOTTOMLEFT", 8, 5)
        addBossBtn:SetBackdropColor(0.2, 0.4, 0.2, 1)
        addBossBtn:SetScript("OnClick", function()
            ShowBossEditor(editor, i, nil)
        end)

        yOffset = yOffset - frameHeight - 5
    end
end

-- Show group editor dialog
function ShowGroupEditor(editor, groupIndex)
    local group = groupIndex and editor.groups[groupIndex] or {}

    StaticPopupDialogs["KOL_GROUP_EDITOR"] = {
        text = groupIndex and "Edit Group Name" or "Add Group",
        button1 = "Save",
        button2 = "Cancel",
        hasEditBox = true,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self)
            self.editBox:SetText(group.name or "")
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
            local groupName = self.editBox:GetText()
            if not groupName or groupName == "" then
                KOL:PrintTag(RED("Error:") .. " Group name is required!")
                return
            end

            local newGroup = {
                name = groupName,
                bosses = group.bosses or {},
            }

            if groupIndex then
                editor.groups[groupIndex] = newGroup
            else
                table.insert(editor.groups, newGroup)
            end

            RenderGroupsList(editor)
            KOL:PrintTag(GREEN("Group saved: ") .. groupName)
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
    }

    StaticPopup_Show("KOL_GROUP_EDITOR")
end

-- Show boss editor dialog
function ShowBossEditor(editor, groupIndex, bossIndex)
    local group = editor.groups[groupIndex]
    if not group then return end

    local boss = bossIndex and group.bosses[bossIndex] or {}

    StaticPopupDialogs["KOL_BOSS_EDITOR"] = {
        text = bossIndex and "Edit Boss" or "Add Boss",
        button1 = "Save",
        button2 = "Cancel",
        hasEditBox = true,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self)
            self.editBox:SetText(boss.name or "")
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
            local bossName = self.editBox:GetText()
            if not bossName or bossName == "" then
                KOL:PrintTag(RED("Error:") .. " Boss name is required!")
                return
            end

            -- Show NPC ID editor
            StaticPopupDialogs["KOL_BOSS_ID"] = {
                text = "Enter NPC ID for " .. bossName .. ":",
                button1 = "Save",
                button2 = "Cancel",
                hasEditBox = true,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                OnShow = function(popup)
                    popup.editBox:SetText(tostring(boss.id or ""))
                    popup.editBox:SetFocus()
                end,
                OnAccept = function(popup)
                    local npcId = tonumber(popup.editBox:GetText())
                    if not npcId then
                        KOL:PrintTag(RED("Error:") .. " Invalid NPC ID!")
                        return
                    end

                    local newBoss = {
                        name = bossName,
                        id = npcId,
                    }

                    if not group.bosses then
                        group.bosses = {}
                    end

                    if bossIndex then
                        group.bosses[bossIndex] = newBoss
                    else
                        table.insert(group.bosses, newBoss)
                    end

                    RenderGroupsList(editor)
                    KOL:PrintTag(GREEN("Boss saved: ") .. bossName)
                end,
                EditBoxOnEscapePressed = function(popup)
                    popup:GetParent():Hide()
                end,
            }
            StaticPopup_Show("KOL_BOSS_ID")
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
    }

    StaticPopup_Show("KOL_BOSS_EDITOR")
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
            editor.title:SetText("Edit Custom Panel: " .. data.name)
            editor.nameInput:SetText(data.name or "")

            -- Load zones
            if data.zones then
                local zonesText = table.concat(data.zones, "\n")
                editor.zonesInput:SetText(zonesText)
            end

            -- Load panel type and data
            if data.groups and #data.groups > 0 then
                editor.panelType = "grouped"
                editor.groups = {}
                -- Deep copy groups
                for _, group in ipairs(data.groups) do
                    local newGroup = {
                        name = group.name,
                        bosses = {}
                    }
                    if group.bosses then
                        for _, boss in ipairs(group.bosses) do
                            table.insert(newGroup.bosses, {
                                name = boss.name,
                                id = boss.id
                            })
                        end
                    end
                    table.insert(editor.groups, newGroup)
                end
            else
                editor.panelType = "objective"
                editor.objectives = {}
                -- Deep copy objectives
                if data.objectives then
                    for _, obj in ipairs(data.objectives) do
                        table.insert(editor.objectives, {
                            name = obj.name,
                            conditionString = obj.conditionString or "return true",
                            condition = obj.condition
                        })
                    end
                end
            end

            -- Load color
            if data.color then
                if type(data.color) == "table" then
                    editor.selectedColor = data.color
                    editor.colorPreview:SetBackdropColor(data.color[1], data.color[2], data.color[3], 1)
                else
                    local rgb = KOL.Colors:GetPastel(data.color)
                    editor.selectedColor = rgb
                    editor.colorPreview:SetBackdropColor(rgb[1], rgb[2], rgb[3], 1)
                end
            end
        end
    else
        -- Creating new panel
        editor.title:SetText("Create New Custom Panel")
        editor.nameInput:SetText("")
        editor.zonesInput:SetText("")
        editor.panelType = "objective"
        editor.objectives = {}
        editor.groups = {}
        editor.selectedColor = {1, 0.7, 0.9}
        editor.colorPreview:SetBackdropColor(1, 0.7, 0.9, 1)
    end

    -- Refresh lists
    RenderObjectivesList(editor)
    RenderGroupsList(editor)

    editor:Show()
    KOL:DebugPrint("Custom Panel Editor: Opened", 2)
end

KOL:DebugPrint("Tracker Editor: Module loaded", 1)
