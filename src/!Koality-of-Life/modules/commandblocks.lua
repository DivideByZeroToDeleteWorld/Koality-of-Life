local KOL = KoalityOfLife
local LSM = LibStub("LibSharedMedia-3.0")

KOL.CommandBlocks = {}
local CommandBlocks = KOL.CommandBlocks

local compiledBlocks = {}

function CommandBlocks:Initialize()
    if not KOL.db.profile.commandBlocks then
        KOL.db.profile.commandBlocks = {}
    end

    for name, block in pairs(KOL.db.profile.commandBlocks) do
        self:Compile(name, block.code)
    end

    KOL:DebugPrint("CommandBlocks: Module initialized", 1)
end

function CommandBlocks:Compile(name, code)
    if not code or code == "" then
        KOL:DebugPrint("CommandBlocks: Cannot compile empty block: " .. name, 1)
        return false
    end

    local funcStr = "return function()\n" .. code .. "\nend"

    local loadFunc = loadstring or load
    local compiledChunk, compileError = loadFunc(funcStr)

    if not compiledChunk then
        KOL:PrintTag(RED("Error:") .. " Failed to compile command block '" .. name .. "': " .. tostring(compileError))
        return false
    end

    local success, func = pcall(compiledChunk)
    if not success then
        KOL:PrintTag(RED("Error:") .. " Failed to create command block function '" .. name .. "': " .. tostring(func))
        return false
    end

    compiledBlocks[name] = func
    KOL:DebugPrint("CommandBlocks: Compiled: " .. YELLOW(name), 3)
    return true
end

function CommandBlocks:Execute(name)
    local func = compiledBlocks[name]
    if not func then
        KOL:DebugPrint("CommandBlocks: Block not compiled: " .. name, 1)
        return nil
    end

    local success, result = pcall(func)
    if not success then
        KOL:PrintTag(RED("Error:") .. " Failed to execute command block '" .. name .. "': " .. tostring(result))
        return nil
    end

    return result
end

function CommandBlocks:Save(name, code, description)
    if not name or name == "" then
        KOL:PrintTag(RED("Error:") .. " Command block name cannot be empty")
        return false
    end

    if not KOL.db.profile.commandBlocks then
        KOL.db.profile.commandBlocks = {}
    end

    KOL.db.profile.commandBlocks[name] = {
        code = code or "",
        description = description or "",
        created = time(),
    }

    self:Compile(name, code)

    KOL:DebugPrint("CommandBlocks: Saved: " .. YELLOW(name), 1)
    return true
end

function CommandBlocks:Delete(name)
    if KOL.db.profile.commandBlocks and KOL.db.profile.commandBlocks[name] then
        KOL.db.profile.commandBlocks[name] = nil
        compiledBlocks[name] = nil
        KOL:DebugPrint("CommandBlocks: Deleted: " .. YELLOW(name), 1)
        return true
    end
    return false
end

function CommandBlocks:GetAll()
    return KOL.db.profile.commandBlocks or {}
end

function CommandBlocks:Get(name)
    if KOL.db.profile.commandBlocks then
        return KOL.db.profile.commandBlocks[name]
    end
    return nil
end

function CommandBlocks:Exists(name)
    return KOL.db.profile.commandBlocks and KOL.db.profile.commandBlocks[name] ~= nil
end

local editorFrame = nil

function CommandBlocks:ShowEditor()
    if not editorFrame then
        editorFrame = self:CreateEditor()
    end
    editorFrame:Show()
end

function CommandBlocks:CreateEditor()
    local fontPath = LSM:Fetch("font", KOL.db.profile.generalFont or "Friz Quadrata TT")
    local fontOutline = KOL.db.profile.generalFontOutline or "NONE"

    local frame = KOL.UIFactory:CreateStyledFrame(UIParent, "KOL_CommandBlockEditor", 700, 550, {
        bgColor = {r = 0.05, g = 0.05, b = 0.05, a = 0.98},
        borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1},
        movable = true,
        closable = true,
        strata = "DIALOG"
    })
    frame:SetPoint("CENTER")

    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    closeBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    closeBtn:SetBackdropColor(0.4, 0.1, 0.1, 0.9)
    closeBtn:SetBackdropBorderColor(0.25, 0.05, 0.05, 1)

    local closeBtnText = KOL.UIFactory:CreateGlyph(closeBtn, CHAR_UI_CLOSE, {r = 0.9, g = 0.9, b = 0.9}, 12)
    closeBtnText:SetPoint("CENTER", 0, 0)

    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.6, 0.15, 0.15, 1)
        self:SetBackdropBorderColor(0.4, 0.1, 0.1, 1)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.4, 0.1, 0.1, 0.9)
        self:SetBackdropBorderColor(0.25, 0.05, 0.05, 1)
    end)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    local nameLabel = frame:CreateFontString(nil, "OVERLAY")
    nameLabel:SetFont(fontPath, 11, fontOutline)
    nameLabel:SetPoint("TOPLEFT", 10, -10)
    nameLabel:SetText("|cFFFFFFFFBlock Name:|r")

    local nameDropdown = CreateFrame("Button", nil, frame)
    nameDropdown:SetSize(260, 22)
    nameDropdown:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    nameDropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 2, right = 20, top = 2, bottom = 2 }
    })
    nameDropdown:SetBackdropColor(0.1, 0.1, 0.1, 1)
    nameDropdown:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local nameDropdownText = nameDropdown:CreateFontString(nil, "OVERLAY")
    nameDropdownText:SetFont(fontPath, 11, fontOutline)
    nameDropdownText:SetPoint("LEFT", 5, 0)
    nameDropdownText:SetPoint("RIGHT", -20, 0)
    nameDropdownText:SetJustifyH("LEFT")
    nameDropdownText:SetText("|cFF888888(Select Command Block)|r")
    nameDropdownText:SetTextColor(0.7, 0.7, 0.7, 1)

    local nameDropdownArrow = KOL.UIFactory:CreateGlyph(nameDropdown, CHAR_ARROW_DOWNFILLED, {r = 0.5, g = 0.5, b = 0.5}, 11)
    nameDropdownArrow:SetPoint("RIGHT", -5, 0)

    nameDropdown:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        nameDropdownArrow:SetGlyph(nil, {r = 0.7, g = 0.7, b = 0.7})
    end)
    nameDropdown:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        nameDropdownArrow:SetGlyph(nil, {r = 0.5, g = 0.5, b = 0.5})
    end)

    frame.nameDropdown = nameDropdown
    frame.nameDropdownText = nameDropdownText
    frame.currentBlockName = nil

    local descLabel = frame:CreateFontString(nil, "OVERLAY")
    descLabel:SetFont(fontPath, 11, fontOutline)
    descLabel:SetPoint("TOPLEFT", 10, -40)
    descLabel:SetText("|cFFFFFFFFDescription:|r")

    local descInput = CreateFrame("EditBox", nil, frame)
    descInput:SetSize(580, 20)
    descInput:SetPoint("LEFT", descLabel, "RIGHT", 10, 0)
    descInput:SetFontObject(GameFontNormal)
    descInput:SetAutoFocus(false)
    descInput:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    descInput:SetBackdropColor(0.1, 0.1, 0.1, 1)
    descInput:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    descInput:SetTextColor(1, 1, 1, 1)
    descInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    frame.descInput = descInput

    local codeLabel = frame:CreateFontString(nil, "OVERLAY")
    codeLabel:SetFont(fontPath, 11, fontOutline)
    codeLabel:SetPoint("TOPLEFT", 10, -70)
    codeLabel:SetText("|cFFFFFFFFLua Code:|r |cFFAAAA00(must return a string)|r")

    local scrollFrame = CreateFrame("ScrollFrame", "KOL_CommandBlocksScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    scrollFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    scrollFrame:SetBackdropColor(0.08, 0.08, 0.08, 1)
    scrollFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local codeEditBox = CreateFrame("EditBox", nil, scrollFrame)
    codeEditBox:SetMultiLine(true)
    codeEditBox:SetMaxLetters(0)
    codeEditBox:EnableMouse(true)
    codeEditBox:EnableKeyboard(true)
    codeEditBox:SetFont(fontPath, 11, fontOutline)
    codeEditBox:SetWidth(scrollFrame:GetWidth() - 30)
    codeEditBox:SetHeight(1000)
    codeEditBox:SetAutoFocus(false)
    codeEditBox:SetTextInsets(5, 5, 5, 5)
    codeEditBox:SetTextColor(1, 1, 1, 1)
    codeEditBox:SetCursorPosition(0)
    codeEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    codeEditBox:SetScript("OnEnterPressed", function(self)
        local cursorPos = self:GetCursorPosition()
        local text = self:GetText()
        local newText = text:sub(1, cursorPos) .. "\n" .. text:sub(cursorPos + 1)
        self:SetText(newText)
        self:SetCursorPosition(cursorPos + 1)
    end)
    codeEditBox.lastTextLength = 0
    codeEditBox:SetScript("OnTextChanged", function(self, userInput)
        local text = self:GetText()
        local lines = 1
        for _ in text:gmatch("\n") do
            lines = lines + 1
        end
        self:SetHeight(math.max(400, lines * 14))

        local currentLength = string.len(text)
        local lengthDiff = math.abs(currentLength - self.lastTextLength)

        if lengthDiff > 50 then
            C_Timer.After(0.05, function()
                if KoalityOfLife.indent and KoalityOfLife.indent.clearCache and KoalityOfLife.indent.indentEditbox then
                    KoalityOfLife.indent.clearCache(self)
                    KoalityOfLife.indent.indentEditbox(self)
                end
            end)
        end

        self.lastTextLength = currentLength
    end)
    codeEditBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText(0, 0)
    end)
    scrollFrame:SetScrollChild(codeEditBox)
    frame.codeEditBox = codeEditBox

    -- Skin the scrollbar
    KOL:SkinUIPanelScrollFrame(scrollFrame)

    if KoalityOfLife.indent and KoalityOfLife.indent.enable then
        KoalityOfLife.indent.enable(codeEditBox)
        KOL:DebugPrint("CommandBlocks: FAIAP syntax highlighting enabled", 3)
    end

    local function LoadCommandBlock(blockName)
        local blocks = CommandBlocks:GetAll()
        local blockData = blocks[blockName]
        if blockData then
            descInput:SetText(blockData.description or "")
            codeEditBox:SetText(blockData.code or "")

            -- Force FAIAP to recalculate indentation immediately (clear cache first)
            if KoalityOfLife.indent and KoalityOfLife.indent.clearCache and KoalityOfLife.indent.indentEditbox then
                KoalityOfLife.indent.clearCache(codeEditBox)
                KoalityOfLife.indent.indentEditbox(codeEditBox)
            end

            frame.currentBlockName = blockName
            nameDropdownText:SetText(blockName)
            nameDropdownText:SetTextColor(1, 1, 1, 1)
            KOL:PrintTag("Loaded command block: " .. YELLOW(blockName))
        end
    end

    local function ShowBlockNameDropdown(anchor)
        local blocks = CommandBlocks:GetAll()
        local items = {}

        for name, _ in pairs(blocks) do
            table.insert(items, {label = name, value = name})
        end

        table.sort(items, function(a, b) return a.label < b.label end)

        KOL:ShowDropdownMenu(anchor, items, function(item)
            LoadCommandBlock(item.value)
        end)
    end

    nameDropdown:SetScript("OnClick", function(self)
        ShowBlockNameDropdown(self)
    end)

    local function CreateStyledButton(parent, width, height, text)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(width, height)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        btn:SetBackdropColor(0.8, 0.4, 0.4, 1)
        btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

        local btnText = btn:CreateFontString(nil, "OVERLAY")
        btnText:SetFont(fontPath, 11, fontOutline)
        btnText:SetPoint("CENTER")
        btnText:SetText(text)
        btnText:SetTextColor(1, 1, 0.6, 1)

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.9, 0.5, 0.5, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.8, 0.4, 0.4, 1)
        end)

        return btn
    end

    local saveBtn = CreateStyledButton(frame, 100, 30, "Save")
    saveBtn:SetPoint("BOTTOMLEFT", 10, 10)
    saveBtn:SetScript("OnClick", function()
        local name = frame.currentBlockName
        local desc = descInput:GetText()
        local code = codeEditBox:GetText()

        if not name or name == "" then
            KOL:PrintTag(RED("Error:") .. " No command block selected. Click 'New' to create one.")
            return
        end

        if CommandBlocks:Save(name, code, desc) then
            KOL:PrintTag("Saved command block: " .. YELLOW(name))
        end
    end)

    local testBtn = CreateStyledButton(frame, 100, 30, "Test")
    testBtn:SetPoint("LEFT", saveBtn, "RIGHT", 10, 0)
    testBtn:SetScript("OnClick", function()
        local code = codeEditBox:GetText()
        if code == "" then
            KOL:PrintTag(RED("Error:") .. " No code to test")
            return
        end

        local tempName = "__TEST_BLOCK__"
        if CommandBlocks:Save(tempName, code, "Test block") then
            local result = CommandBlocks:Execute(tempName)
            CommandBlocks:Delete(tempName)

            if result then
                KOL:PrintTag(GREEN("Success:") .. " Block returned: " .. YELLOW(tostring(result)))
            else
                KOL:PrintTag(RED("Error:") .. " Block returned nil")
            end
        end
    end)

    local deleteBtn = CreateStyledButton(frame, 100, 30, "Delete")
    deleteBtn:SetPoint("LEFT", testBtn, "RIGHT", 10, 0)
    deleteBtn:SetScript("OnClick", function()
        local name = frame.currentBlockName
        if not name or name == "" then
            KOL:PrintTag(RED("Error:") .. " No command block selected")
            return
        end

        if CommandBlocks:Delete(name) then
            KOL:PrintTag("Deleted command block: " .. YELLOW(name))
            nameDropdownText:SetText("|cFF888888(Select Command Block)|r")
            nameDropdownText:SetTextColor(0.7, 0.7, 0.7, 1)
            descInput:SetText("")
            codeEditBox:SetText("")
            frame.currentBlockName = nil
        end
    end)

    local newBtn = CreateStyledButton(frame, 100, 30, "New")
    newBtn:SetPoint("BOTTOMRIGHT", -10, 10)
    newBtn:SetScript("OnClick", function()
        StaticPopupDialogs["KOL_NEW_COMMAND_BLOCK"] = {
            text = "Enter name for new command block:",
            button1 = "Create",
            button2 = "Cancel",
            hasEditBox = true,
            OnAccept = function(self)
                local blockName = self.editBox:GetText()
                if blockName and blockName ~= "" then
                    if CommandBlocks:Save(blockName, "", "") then
                        KOL:PrintTag("Created command block: " .. YELLOW(blockName))
                        LoadCommandBlock(blockName)
                    end
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("KOL_NEW_COMMAND_BLOCK")
    end)

    return frame
end

KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
    CommandBlocks:Initialize()
end, "CommandBlocks")

KOL:DebugPrint("CommandBlocks module loaded", 1)
