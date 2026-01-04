-- ============================================================================
-- Macro Updater Module
-- ============================================================================
-- Auto-update macros out of combat using Command Blocks
-- ============================================================================

local KOL = KoalityOfLife
local LSM = LibStub("LibSharedMedia-3.0")
local UIFactory = KOL.UIFactory

-- Create module
local MacroUpdater = {}
KOL.MacroUpdater = MacroUpdater

-- Command Block runtime functions (compiled from code strings)
-- ============================================================================
-- Command Block Integration (uses KOL.CommandBlocks module)
-- ============================================================================
-- Note: Command Block management is now handled by the CommandBlocks module

-- ============================================================================
-- Macro Management
-- ============================================================================

-- Get list of all macros (general + character-specific)
function MacroUpdater:GetAllMacros()
    local macros = {}

    -- Get general macros (1-36)
    local numGlobalMacros = GetNumMacros()
    for i = 1, numGlobalMacros do
        local name, iconTexture, body = GetMacroInfo(i)
        if name then
            table.insert(macros, {
                index = i,
                name = name,
                body = body,
                icon = iconTexture,
                type = "general",
            })
        end
    end

    -- Get character-specific macros (37-54)
    local numGlobalMacros, numCharMacros = GetNumMacros()
    for i = 1, numCharMacros do
        local name, iconTexture, body = GetMacroInfo(36 + i)
        if name then
            table.insert(macros, {
                index = 36 + i,
                name = name,
                body = body,
                icon = iconTexture,
                type = "character",
            })
        end
    end

    return macros
end

-- Find macro by name
function MacroUpdater:FindMacro(macroName)
    local macros = self:GetAllMacros()
    for _, macro in ipairs(macros) do
        if macro.name == macroName then
            return macro
        end
    end
    return nil
end

-- Update a macro with new body text
function MacroUpdater:UpdateMacro(macroName, newBody)
    -- Can't update macros in combat
    if InCombatLockdown() then
        KOL:DebugPrint("Macros: Cannot update macro '" .. macroName .. "' while in combat", 1)
        return false
    end

    local macro = self:FindMacro(macroName)
    if not macro then
        KOL:DebugPrint("Macros: Macro not found: " .. macroName, 1)
        return false
    end

    -- Check if update is needed
    if macro.body == newBody then
        KOL:DebugPrint("Macros: Macro '" .. macroName .. "' already up to date", 3)
        return true
    end

    -- Update the macro
    EditMacro(macro.index, nil, nil, newBody)

    KOL:DebugPrint("Macros: Updated macro: " .. YELLOW(macroName), 1)

    -- Update last updated time
    if KOL.db.profile.macroUpdater.macros[macroName] then
        KOL.db.profile.macroUpdater.macros[macroName].lastUpdated = time()
    end

    return true
end

-- ============================================================================
-- Auto-Update System
-- ============================================================================

-- Main update function called by batch system
function KOL:MacroUpdate(macroName, commandBlockName)
    local config = KOL.db.profile.macroUpdater.macros[macroName]
    if not config or not config.enabled then
        KOL:DebugPrint("Macros: Auto-update disabled for: " .. macroName, 3)
        return
    end

    -- Execute command block to get new macro body (using CommandBlocks module)
    local newBody = KOL.CommandBlocks:Execute(commandBlockName)
    if not newBody then
        KOL:DebugPrint("Macros: Command block '" .. commandBlockName .. "' returned nil", 1)
        return
    end

    -- Update the macro
    local success = MacroUpdater:UpdateMacro(macroName, newBody)

    if success then
        -- Stop the batch channel after successful update
        KOL:BatchStop("Macros")
        KOL:DebugPrint("Macros: Successfully updated '" .. macroName .. "', batch stopped", 1)
    end
end

-- Enable auto-update for a macro
function MacroUpdater:EnableMacroAutoUpdate(macroName, commandBlockName)
    if not KOL.db.profile.macroUpdater.macros then
        KOL.db.profile.macroUpdater.macros = {}
    end

    KOL.db.profile.macroUpdater.macros[macroName] = {
        enabled = true,
        commandBlock = commandBlockName,
        lastUpdated = 0,
    }

    KOL:DebugPrint("Macros: Enabled auto-update for: " .. YELLOW(macroName) .. " using block: " .. YELLOW(commandBlockName), 1)
end

-- Disable auto-update for a macro
function MacroUpdater:DisableMacroAutoUpdate(macroName)
    if KOL.db.profile.macroUpdater.macros and KOL.db.profile.macroUpdater.macros[macroName] then
        KOL.db.profile.macroUpdater.macros[macroName].enabled = false
        KOL:DebugPrint("Macros: Disabled auto-update for: " .. YELLOW(macroName), 1)
    end
end

-- Initialize batch system for macro updates
function MacroUpdater:InitializeBatchSystem()
    -- Configure the Macros batch channel
    KOL:BatchConfigure("Macros", {
        interval = 1.0,              -- Run every 1 second
        processMode = "all",         -- Process all actions
        triggerMode = "outofcombat", -- Only run out of combat
        maxQueueSize = 10,
    })

    KOL:DebugPrint("Macros: Batch system initialized", 1)
end

-- ============================================================================
-- Module Initialization
-- ============================================================================

function MacroUpdater:Initialize()
    -- Initialize defaults
    if not KOL.db.profile.macroUpdater then
        KOL.db.profile.macroUpdater = {
            macros = {},
        }
    end

    -- Note: Command blocks are now initialized by the CommandBlocks module

    -- Initialize batch system
    self:InitializeBatchSystem()

    -- Register slash command
    KOL:RegisterSlashCommand("macroupdater", function()
        MacroUpdater:ShowUI()
    end, "Open Macro Updater UI")

    -- Initialize config UI (will be added in next part)
    self:InitializeConfig()

    KOL:DebugPrint("Macros: Module initialized", 1)
end

-- Currently selected macro for UI
local selectedMacroName = nil
local selectedCommandBlock = nil

-- Initialize config UI
function MacroUpdater:InitializeConfig()
    -- Make sure UI system is initialized first
    if not KOL.configOptions or not KOL.configGroups then
        KOL:DebugPrint("Macros: Waiting for main UI to initialize...", 3)
        C_Timer.After(1, function() self:InitializeConfig() end)
        return
    end

    -- Create macro updater config group
    if not KOL.configGroups.macros then
        KOL.configGroups.macros = {
            type = "group",
            name = "|cFF00CCCCMacro Updater|r",
            order = 60,
            args = {
                header = {
                    type = "description",
                    name = "|cFFFFFFFFMacro Auto-Updater|r\n|cFFAAAAAAAuto-update macros out of combat using Command Blocks.|r\n",
                    fontSize = "medium",
                    order = 1,
                },

                macroSelect = {
                    type = "select",
                    name = "Choose Macro",
                    desc = "Select a macro to configure auto-update",
                    order = 2,
                    width = "double",
                    values = function()
                        local macros = MacroUpdater:GetAllMacros()
                        local values = {}
                        for _, macro in ipairs(macros) do
                            local typeLabel = macro.type == "general" and "[G]" or "[C]"
                            values[macro.name] = typeLabel .. " " .. macro.name
                        end
                        return values
                    end,
                    get = function() return selectedMacroName end,
                    set = function(_, value)
                        selectedMacroName = value
                        -- Refresh UI to show macro details
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                    end,
                },

                autoUpdate = {
                    type = "toggle",
                    name = "Auto Update Out of Combat",
                    desc = "Automatically update this macro when leaving combat",
                    order = 3,
                    width = "normal",
                    disabled = function() return not selectedMacroName end,
                    get = function()
                        if not selectedMacroName then return false end
                        local config = KOL.db.profile.macroUpdater.macros[selectedMacroName]
                        return config and config.enabled or false
                    end,
                    set = function(_, value)
                        if not selectedMacroName then return end
                        if value then
                            -- Enable auto-update
                            if selectedCommandBlock and selectedCommandBlock ~= "" then
                                MacroUpdater:EnableMacroAutoUpdate(selectedMacroName, selectedCommandBlock)
                                KOL:PrintTag("Enabled auto-update for: " .. YELLOW(selectedMacroName))
                            else
                                KOL:PrintTag(RED("Error:") .. " Please select a command block first")
                            end
                        else
                            -- Disable auto-update
                            MacroUpdater:DisableMacroAutoUpdate(selectedMacroName)
                            KOL:PrintTag("Disabled auto-update for: " .. YELLOW(selectedMacroName))
                        end
                    end,
                },

                spacer1 = {
                    type = "description",
                    name = "\n",
                    order = 4,
                },

                currentMacroHeader = {
                    type = "header",
                    name = "Current Macro Content",
                    order = 5,
                    hidden = function() return not selectedMacroName end,
                },

                currentMacro = {
                    type = "description",
                    name = function()
                        if not selectedMacroName then return "" end
                        local macro = MacroUpdater:FindMacro(selectedMacroName)
                        if not macro then return RED("Macro not found") end
                        return "|cFFCCCCCC" .. (macro.body or "(empty)") .. "|r"
                    end,
                    order = 6,
                    fontSize = "medium",
                    hidden = function() return not selectedMacroName end,
                },

                spacer2 = {
                    type = "description",
                    name = "\n",
                    order = 7,
                },

                commandBlockHeader = {
                    type = "header",
                    name = "Command Block",
                    order = 8,
                    hidden = function() return not selectedMacroName end,
                },

                commandBlockSelect = {
                    type = "select",
                    name = "Command Block",
                    desc = "Select which command block to use for this macro",
                    order = 9,
                    width = "normal",
                    hidden = function() return not selectedMacroName end,
                    values = function()
                        local blocks = {}
                        blocks[""] = "(None)"
                        for name, _ in pairs(KOL.CommandBlocks:GetAll()) do
                            blocks[name] = name
                        end
                        return blocks
                    end,
                    get = function()
                        if not selectedMacroName then return "" end
                        local config = KOL.db.profile.macroUpdater.macros[selectedMacroName]
                        if config then
                            selectedCommandBlock = config.commandBlock
                            return config.commandBlock or ""
                        end
                        return selectedCommandBlock or ""
                    end,
                    set = function(_, value)
                        selectedCommandBlock = value
                        if selectedMacroName and value ~= "" then
                            if not KOL.db.profile.macroUpdater.macros[selectedMacroName] then
                                KOL.db.profile.macroUpdater.macros[selectedMacroName] = {}
                            end
                            KOL.db.profile.macroUpdater.macros[selectedMacroName].commandBlock = value
                            KOL:PrintTag("Set command block for " .. YELLOW(selectedMacroName) .. ": " .. YELLOW(value))
                        end
                    end,
                },

                manageBlocks = {
                    type = "execute",
                    name = "Manage Command Blocks",
                    desc = "Open the command block editor",
                    order = 10,
                    width = "normal",
                    func = function()
                        MacroUpdater:ShowUI()
                    end,
                },

                spacer3 = {
                    type = "description",
                    name = "\n|cFFFFAA00Note:|r Command blocks are reusable code snippets that return macro text.\nUse the Command Block editor to create and test them.",
                    order = 11,
                },
            }
        }
        -- Only add tab if devMode is enabled (hidden in production)
        if KOL.db and KOL.db.profile and KOL.db.profile.devMode then
            KOL.configOptions.args.macros = KOL.configGroups.macros
            KOL:DebugPrint("Macros: Config UI initialized (devMode)", 1)
        else
            KOL:DebugPrint("Macros: Config UI skipped (devMode disabled)", 1)
        end
    end
end

-- Command Block Editor UI
local editorFrame = nil
local currentBlockName = nil

-- Create the Command Block editor window
-- ============================================================================
-- DEPRECATED: Command Block Editor (now in commandblocks.lua module)
-- ============================================================================
-- This function is deprecated and left here for reference only.
-- Use KOL.CommandBlocks:ShowEditor() instead.
local function CreateCommandBlockEditor()
    if editorFrame then
        return editorFrame
    end

    -- Get font settings
    local fontPath = LSM:Fetch("font", KOL.db.profile.generalFont or "Friz Quadrata TT")
    local fontOutline = KOL.db.profile.generalFontOutline or "NONE"

    -- Create main frame using UIFactory
    local frame = UIFactory:CreateStyledFrame(UIParent, "KOL_CommandBlockEditor", 700, 550, {
        movable = true,
        closable = true,
        strata = UIFactory.STRATA.IMPORTANT,
        bgColor = {r = 0.05, g = 0.05, b = 0.05, a = 0.95},
        borderColor = {r = 0, g = 0.8, b = 0.8, a = 1},
    })
    frame:SetPoint("CENTER")

    -- Title bar using UIFactory
    local titleBar, titleText, closeBtn = UIFactory:CreateTitleBar(frame, 24, "|cFF00CCCCCommand Block Editor|r", {
        showCloseButton = true,
        bgColor = {r = 0, g = 0.5, b = 0.5, a = 1},
    })

    -- Block Name label
    local nameLabel = frame:CreateFontString(nil, "OVERLAY")
    nameLabel:SetFont(fontPath, 11, fontOutline)
    nameLabel:SetPoint("TOPLEFT", 10, -35)
    nameLabel:SetText("|cFFFFFFFFBlock Name:|r")

    -- Block Name Dropdown Display
    local nameDropdown = CreateFrame("Button", nil, frame)
    nameDropdown:SetSize(300, 22)
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

    local nameDropdownArrow = KOL.UIFactory:CreateGlyph(nameDropdown, CHAR_ARROW_DOWNFILLED, {r = 0, g = 0.8, b = 0.8}, 11)
    nameDropdownArrow:SetPoint("RIGHT", -5, 0)

    nameDropdown:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0, 0.8, 0.8, 1)
        nameDropdownArrow:SetGlyph(nil, {r = 0, g = 1, b = 1})
    end)
    nameDropdown:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        nameDropdownArrow:SetGlyph(nil, {r = 0, g = 0.8, b = 0.8})
    end)

    -- Store references
    frame.nameDropdown = nameDropdown
    frame.nameDropdownText = nameDropdownText
    frame.currentBlockName = nil

    -- Description input
    local descLabel = frame:CreateFontString(nil, "OVERLAY")
    descLabel:SetFont(fontPath, 11, fontOutline)
    descLabel:SetPoint("TOPLEFT", 10, -65)
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

    -- Code editor label
    local codeLabel = frame:CreateFontString(nil, "OVERLAY")
    codeLabel:SetFont(fontPath, 11, fontOutline)
    codeLabel:SetPoint("TOPLEFT", 10, -95)
    codeLabel:SetText("|cFFFFFFFFLua Code:|r |cFFAAAA00(must return a string)|r")

    -- Scroll frame for code editor
    local scrollFrame = CreateFrame("ScrollFrame", "KOL_CommandBlockEditor_ScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -115)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)  -- Leave room for scrollbar and buttons
    scrollFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    scrollFrame:SetBackdropColor(0.08, 0.08, 0.08, 1)
    scrollFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    -- Code edit box
    local codeEditBox = CreateFrame("EditBox", nil, scrollFrame)
    codeEditBox:SetMultiLine(true)
    codeEditBox:SetMaxLetters(0)  -- Unlimited text
    codeEditBox:EnableMouse(true)
    codeEditBox:EnableKeyboard(true)
    codeEditBox:SetFont(fontPath, 11, fontOutline)
    codeEditBox:SetWidth(scrollFrame:GetWidth() - 30)
    codeEditBox:SetHeight(1000)  -- Large enough for scrolling
    codeEditBox:SetAutoFocus(false)
    codeEditBox:SetTextInsets(5, 5, 5, 5)  -- Left, Right, Top, Bottom padding
    codeEditBox:SetTextColor(1, 1, 1, 1)
    codeEditBox:SetCursorPosition(0)
    codeEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    codeEditBox:SetScript("OnEnterPressed", function(self)
        -- Allow Enter to create new lines instead of submitting
        local cursorPos = self:GetCursorPosition()
        local text = self:GetText()
        local newText = text:sub(1, cursorPos) .. "\n" .. text:sub(cursorPos + 1)
        self:SetText(newText)
        self:SetCursorPosition(cursorPos + 1)
    end)
    codeEditBox.lastTextLength = 0
    codeEditBox:SetScript("OnTextChanged", function(self, userInput)
        -- Auto-resize height based on content
        local text = self:GetText()
        local lines = 1
        for _ in text:gmatch("\n") do
            lines = lines + 1
        end
        self:SetHeight(math.max(400, lines * 14))

        -- If this is a large text change (like pasting), force re-indentation
        local currentLength = string.len(text)
        local lengthDiff = math.abs(currentLength - self.lastTextLength)

        -- If more than 50 characters changed at once (likely a paste or load), force re-indent
        if lengthDiff > 50 then
            -- Schedule a re-indent after a short delay to let FAIAP settle
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
        self:HighlightText(0, 0)  -- Clear any selection when clicking
    end)
    scrollFrame:SetScrollChild(codeEditBox)
    frame.codeEditBox = codeEditBox

    -- Skin the scrollbar
    KOL:SkinUIPanelScrollFrame(scrollFrame)

    -- Enable FAIAP syntax highlighting
    if KoalityOfLife.indent and KoalityOfLife.indent.enable then
        KoalityOfLife.indent.enable(codeEditBox)
        KOL:DebugPrint("Macros: FAIAP syntax highlighting enabled", 3)
    else
        KOL:DebugPrint("Macros: FAIAP not available", 1)
    end

    -- Helper function to load a command block into the editor
    local function LoadCommandBlock(blockName)
        local blocks = KOL.CommandBlocks:GetAll()
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

    -- Helper function to create dropdown menu for command block names
    local function ShowBlockNameDropdown(anchor)
        local blocks = KOL.CommandBlocks:GetAll()
        local items = {}

        for name, _ in pairs(blocks) do
            table.insert(items, {
                text = name,
                value = name,
            })
        end

        if #items == 0 then
            KOL:PrintTag("No saved command blocks found. Click 'New' to create one.")
            return
        end

        -- Show menu at anchor position
        local dropdownMenu = CreateFrame("Frame", "KOL_BlockNameDropdown_" .. math.random(100000, 999999), UIParent)
        dropdownMenu:SetFrameStrata("FULLSCREEN_DIALOG")
        dropdownMenu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
        dropdownMenu:SetWidth(300)
        dropdownMenu:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        dropdownMenu:SetBackdropColor(0.1, 0.1, 0.1, 0.98)
        dropdownMenu:SetBackdropBorderColor(0, 0.8, 0.8, 1)
        dropdownMenu:EnableMouse(true)

        local yOffset = -2
        for _, item in ipairs(items) do
            local menuItem = CreateFrame("Button", nil, dropdownMenu)
            menuItem:SetSize(296, 20)
            menuItem:SetPoint("TOPLEFT", 2, yOffset)

            local itemText = menuItem:CreateFontString(nil, "OVERLAY")
            itemText:SetFont(fontPath, 11, fontOutline)
            itemText:SetPoint("LEFT", 5, 0)
            itemText:SetText(item.text)
            itemText:SetTextColor(0.9, 0.9, 0.9, 1)

            menuItem:SetScript("OnEnter", function(self)
                self:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                })
                self:SetBackdropColor(0, 0.4, 0.4, 0.5)
                itemText:SetTextColor(1, 1, 1, 1)
            end)
            menuItem:SetScript("OnLeave", function(self)
                self:SetBackdrop(nil)
                itemText:SetTextColor(0.9, 0.9, 0.9, 1)
            end)
            menuItem:SetScript("OnClick", function()
                -- Load this command block
                LoadCommandBlock(item.value)
                dropdownMenu:Hide()
                dropdownMenu:SetParent(nil)
            end)

            yOffset = yOffset - 20
        end

        dropdownMenu:SetHeight(math.abs(yOffset) + 2)
        dropdownMenu:Show()

        -- Close menu when clicking outside
        local closeFrame = CreateFrame("Frame", nil, UIParent)
        closeFrame:SetAllPoints(UIParent)
        closeFrame:SetFrameStrata("FULLSCREEN")
        closeFrame:EnableMouse(true)
        closeFrame:SetScript("OnMouseDown", function()
            dropdownMenu:Hide()
            closeFrame:Hide()
            dropdownMenu:SetParent(nil)
            closeFrame:SetParent(nil)
        end)
        closeFrame:Show()
    end

    -- Hook up the dropdown click handler
    nameDropdown:SetScript("OnClick", function()
        ShowBlockNameDropdown(nameDropdown)
    end)

    -- Helper function to create styled buttons
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
        btn:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
        btn:SetBackdropBorderColor(0, 0.6, 0.6, 1)

        local btnText = btn:CreateFontString(nil, "OVERLAY")
        btnText:SetFont(fontPath, 11, fontOutline)
        btnText:SetPoint("CENTER")
        btnText:SetText(text)
        btnText:SetTextColor(0.9, 0.9, 0.9, 1)
        btn.text = btnText

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.2, 0.2, 0.2, 1)
            self:SetBackdropBorderColor(0, 0.8, 0.8, 1)
            self.text:SetTextColor(1, 1, 1, 1)
        end)

        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
            self:SetBackdropBorderColor(0, 0.6, 0.6, 1)
            self.text:SetTextColor(0.9, 0.9, 0.9, 1)
        end)

        return btn
    end

    -- Buttons
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

        if MacroUpdater:SaveCommandBlock(name, code, desc) then
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

        -- Compile and execute temporarily
        local funcStr = "return function()\n" .. code .. "\nend"
        local loadFunc = loadstring or load
        local compiledChunk, compileError = loadFunc(funcStr)

        -- Check if compilation succeeded
        if not compiledChunk then
            KOL:PrintTag(RED("Compile Error:") .. " " .. tostring(compileError))
            return
        end

        -- Execute the compiled chunk to get the function
        local success, func = pcall(compiledChunk)
        if not success then
            KOL:PrintTag(RED("Function Creation Error:") .. " " .. tostring(func))
            return
        end

        -- Execute the function to get the result
        success, result = pcall(func)
        if not success then
            KOL:PrintTag(RED("Runtime Error:") .. " " .. tostring(result))
            return
        end

        KOL:PrintTag(GREEN("Test Success!") .. " Result: " .. YELLOW(tostring(result)))
    end)

    local deleteBtn = CreateStyledButton(frame, 100, 30, "Delete")
    deleteBtn:SetPoint("LEFT", testBtn, "RIGHT", 10, 0)
    deleteBtn:SetScript("OnClick", function()
        local name = frame.currentBlockName
        if not name or name == "" then
            KOL:PrintTag(RED("Error:") .. " No block selected")
            return
        end

        if MacroUpdater:DeleteCommandBlock(name) then
            KOL:PrintTag("Deleted command block: " .. YELLOW(name))
            nameDropdownText:SetText("|cFF888888(Select Command Block)|r")
            nameDropdownText:SetTextColor(0.7, 0.7, 0.7, 1)
            descInput:SetText("")
            codeEditBox:SetText("")
            frame.currentBlockName = nil
        end
    end)

    -- Helper function to create New Block popup
    local function ShowNewBlockPopup()
        -- Create popup frame
        local popup = CreateFrame("Frame", nil, UIParent)
        popup:SetSize(400, 150)
        popup:SetPoint("CENTER")
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 2,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        popup:SetBackdropColor(0.05, 0.05, 0.05, 0.98)
        popup:SetBackdropBorderColor(0, 0.8, 0.8, 1)
        popup:EnableMouse(true)

        -- Title
        local popupTitle = popup:CreateFontString(nil, "OVERLAY")
        popupTitle:SetFont(fontPath, 12, fontOutline)
        popupTitle:SetPoint("TOP", 0, -15)
        popupTitle:SetText("|cFF00CCCCCreate New Command Block|r")

        -- Label
        local popupLabel = popup:CreateFontString(nil, "OVERLAY")
        popupLabel:SetFont(fontPath, 11, fontOutline)
        popupLabel:SetPoint("TOPLEFT", 20, -50)
        popupLabel:SetText("|cFFFFFFFFBlock Name:|r")

        -- Name input
        local popupInput = CreateFrame("EditBox", nil, popup)
        popupInput:SetSize(250, 24)
        popupInput:SetPoint("LEFT", popupLabel, "RIGHT", 10, 0)
        popupInput:SetFontObject(GameFontNormal)
        popupInput:SetAutoFocus(true)
        popupInput:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        popupInput:SetBackdropColor(0.1, 0.1, 0.1, 1)
        popupInput:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        popupInput:SetTextColor(1, 1, 1, 1)
        popupInput:SetScript("OnEscapePressed", function(self) popup:Hide() end)
        popupInput:SetScript("OnEnterPressed", function(self)
            -- Same as clicking Save
            local blockName = popupInput:GetText()
            if blockName == "" then
                KOL:PrintTag(RED("Error:") .. " Block name cannot be empty")
                return
            end

            -- Create new block with empty code
            if MacroUpdater:SaveCommandBlock(blockName, "", "") then
                -- Load it in the editor
                LoadCommandBlock(blockName)
                KOL:PrintTag("Created new command block: " .. YELLOW(blockName))
                popup:Hide()
            end
        end)

        -- Save button
        local popupSaveBtn = CreateStyledButton(popup, 100, 30, "Save")
        popupSaveBtn:SetPoint("BOTTOM", -55, 20)
        popupSaveBtn:SetScript("OnClick", function()
            local blockName = popupInput:GetText()
            if blockName == "" then
                KOL:PrintTag(RED("Error:") .. " Block name cannot be empty")
                return
            end

            -- Create new block with empty code
            if MacroUpdater:SaveCommandBlock(blockName, "", "") then
                -- Load it in the editor
                LoadCommandBlock(blockName)
                KOL:PrintTag("Created new command block: " .. YELLOW(blockName))
                popup:Hide()
            end
        end)

        -- Cancel button
        local popupCancelBtn = CreateStyledButton(popup, 100, 30, "Cancel")
        popupCancelBtn:SetPoint("BOTTOM", 55, 20)
        popupCancelBtn:SetScript("OnClick", function()
            popup:Hide()
        end)

        popup:Show()
    end

    local newBtn = CreateStyledButton(frame, 100, 30, "New")
    newBtn:SetPoint("LEFT", deleteBtn, "RIGHT", 10, 0)
    newBtn:SetScript("OnClick", function()
        ShowNewBlockPopup()
    end)

    local closeBtn2 = CreateStyledButton(frame, 100, 30, "Close")
    closeBtn2:SetPoint("BOTTOMRIGHT", -10, 10)
    closeBtn2:SetScript("OnClick", function() frame:Hide() end)

    editorFrame = frame
    return frame
end

-- Macro Updater Main UI
local macroUpdaterFrame = nil
local selectedMacroForUpdater = nil
local selectedCommandBlockForUpdater = nil

-- Create the Macro Updater window
local function CreateMacroUpdaterWindow()
    if macroUpdaterFrame then
        return macroUpdaterFrame
    end

    -- Get font settings
    local fontPath = LSM:Fetch("font", KOL.db.profile.generalFont or "Friz Quadrata TT")
    local fontOutline = KOL.db.profile.generalFontOutline or "NONE"

    -- Create main frame using UIFactory
    local frame = UIFactory:CreateStyledFrame(UIParent, "KOL_MacroUpdater", 700, 550, {
        movable = true,
        closable = true,
        strata = UIFactory.STRATA.IMPORTANT,
        bgColor = {r = 0.05, g = 0.05, b = 0.05, a = 0.95},
        borderColor = {r = 0, g = 0.8, b = 0.8, a = 1},
    })
    frame:SetPoint("CENTER")

    -- Title bar using UIFactory
    local titleBar, titleText, closeBtn = UIFactory:CreateTitleBar(frame, 24, "|cFF00CCCCMacro Updater|r", {
        showCloseButton = true,
        bgColor = {r = 0, g = 0.5, b = 0.5, a = 1},
    })

    -- Helper function to create styled buttons
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
        btn:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
        btn:SetBackdropBorderColor(0, 0.6, 0.6, 1)

        local btnText = btn:CreateFontString(nil, "OVERLAY")
        btnText:SetFont(fontPath, 11, fontOutline)
        btnText:SetPoint("CENTER")
        btnText:SetText(text)
        btnText:SetTextColor(0.9, 0.9, 0.9, 1)
        btn.text = btnText

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.2, 0.2, 0.2, 1)
            self:SetBackdropBorderColor(0, 0.8, 0.8, 1)
            self.text:SetTextColor(1, 1, 1, 1)
        end)

        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
            self:SetBackdropBorderColor(0, 0.6, 0.6, 1)
            self.text:SetTextColor(0.9, 0.9, 0.9, 1)
        end)

        return btn
    end

    -- Helper function to create dropdowns with proper menus
    local function CreateDropdown(parent, width, height, label, items, onSelect)
        local container = CreateFrame("Frame", nil, parent)
        container:SetSize(width, height)

        local dropdown = CreateFrame("Button", nil, container)
        dropdown:SetSize(width, height)
        dropdown:SetPoint("LEFT")
        dropdown:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        dropdown:SetBackdropColor(0.1, 0.1, 0.1, 1)
        dropdown:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        local dropdownText = dropdown:CreateFontString(nil, "OVERLAY")
        dropdownText:SetFont(fontPath, 11, fontOutline)
        dropdownText:SetPoint("LEFT", 5, 0)
        dropdownText:SetText(label or "(Select)")
        dropdownText:SetTextColor(0.8, 0.8, 0.8, 1)
        dropdown.text = dropdownText

        local arrow = KOL.UIFactory:CreateGlyph(dropdown, CHAR_ARROW_DOWNFILLED, {r = 0, g = 0.8, b = 0.8}, 11)
        arrow:SetPoint("RIGHT", -5, 0)

        dropdown:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(0, 0.6, 0.6, 1)
        end)
        dropdown:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end)

        -- Store items getter and callback
        container.getItems = items
        container.onSelect = onSelect

        dropdown:SetScript("OnClick", function(self)
            -- Create menu
            local menu = {}
            local itemsList = container.getItems and container.getItems() or {}

            for _, item in ipairs(itemsList) do
                table.insert(menu, {
                    text = item.text,
                    value = item.value,
                    func = function()
                        dropdownText:SetText(item.text)
                        if container.onSelect then
                            container.onSelect(item.value, item.text)
                        end
                    end,
                })
            end

            if #menu == 0 then
                table.insert(menu, {
                    text = "(No items available)",
                    disabled = true,
                })
            end

            -- Show menu at dropdown position
            local dropdownMenu = CreateFrame("Frame", "KOL_DropdownMenu_" .. math.random(100000, 999999), UIParent)
            dropdownMenu:SetFrameStrata("FULLSCREEN_DIALOG")
            dropdownMenu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
            dropdownMenu:SetWidth(width)
            dropdownMenu:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false,
                edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            dropdownMenu:SetBackdropColor(0.1, 0.1, 0.1, 0.98)
            dropdownMenu:SetBackdropBorderColor(0, 0.8, 0.8, 1)
            dropdownMenu:EnableMouse(true)

            local yOffset = -2
            for _, item in ipairs(menu) do
                local menuItem = CreateFrame("Button", nil, dropdownMenu)
                menuItem:SetSize(width - 4, 20)
                menuItem:SetPoint("TOPLEFT", 2, yOffset)

                local itemText = menuItem:CreateFontString(nil, "OVERLAY")
                itemText:SetFont(fontPath, 11, fontOutline)
                itemText:SetPoint("LEFT", 5, 0)
                itemText:SetText(item.text)
                itemText:SetTextColor(item.disabled and 0.5 or 0.9, item.disabled and 0.5 or 0.9, item.disabled and 0.5 or 0.9, 1)

                if not item.disabled then
                    menuItem:SetScript("OnEnter", function(self)
                        self:SetBackdrop({
                            bgFile = "Interface\\Buttons\\WHITE8X8",
                        })
                        self:SetBackdropColor(0, 0.4, 0.4, 0.5)
                        itemText:SetTextColor(1, 1, 1, 1)
                    end)
                    menuItem:SetScript("OnLeave", function(self)
                        self:SetBackdrop(nil)
                        itemText:SetTextColor(0.9, 0.9, 0.9, 1)
                    end)
                    menuItem:SetScript("OnClick", function()
                        item.func()
                        dropdownMenu:Hide()
                        dropdownMenu:SetParent(nil)
                    end)
                end

                yOffset = yOffset - 20
            end

            dropdownMenu:SetHeight(math.abs(yOffset) + 2)
            dropdownMenu:Show()

            -- Close menu when clicking outside
            local closeFrame = CreateFrame("Frame", nil, UIParent)
            closeFrame:SetAllPoints(UIParent)
            closeFrame:SetFrameStrata("FULLSCREEN")
            closeFrame:EnableMouse(true)
            closeFrame:SetScript("OnMouseDown", function()
                dropdownMenu:Hide()
                closeFrame:Hide()
                dropdownMenu:SetParent(nil)
                closeFrame:SetParent(nil)
            end)
            closeFrame:Show()
        end)

        container.dropdown = dropdown
        container.SetText = function(self, text)
            dropdownText:SetText(text)
        end
        container.GetText = function(self)
            return dropdownText:GetText()
        end

        return container
    end

    -- Macro selection dropdown
    local macroLabel = frame:CreateFontString(nil, "OVERLAY")
    macroLabel:SetFont(fontPath, 11, fontOutline)
    macroLabel:SetPoint("TOPLEFT", 10, -35)
    macroLabel:SetText("|cFFFFFFFFSelect Macro:|r")

    local macroDropdown = CreateDropdown(frame, 250, 22, "(Select a Macro)",
        function()
            -- Get items for dropdown
            local macros = MacroUpdater:GetAllMacros()
            local items = {}
            for _, macro in ipairs(macros) do
                local typeLabel = macro.type == "general" and "[G]" or "[C]"
                table.insert(items, {
                    text = typeLabel .. " " .. macro.name,
                    value = macro.name,
                })
            end
            return items
        end,
        function(value, text)
            -- On select callback
            selectedMacroForUpdater = value
            -- Update current macro display
            local macro = MacroUpdater:FindMacro(value)
            if macro then
                frame.currentText:SetText(macro.body or "(empty)")
            end
            -- Try to update preview if we have a command block selected
            if selectedCommandBlockForUpdater then
                local result = MacroUpdater:ExecuteCommandBlock(selectedCommandBlockForUpdater)
                if result then
                    frame.updatedText:SetText(result)
                    frame.updatedText:SetTextColor(0, 1, 0, 1)
                else
                    frame.updatedText:SetText("(Command block returned nil)")
                    frame.updatedText:SetTextColor(1, 0.5, 0, 1)
                end
            end
        end
    )
    macroDropdown:SetPoint("LEFT", macroLabel, "RIGHT", 10, 0)
    frame.macroDropdown = macroDropdown

    -- Arrow separator
    local arrowText = frame:CreateFontString(nil, "OVERLAY")
    arrowText:SetFont(fontPath, 14, fontOutline)
    arrowText:SetPoint("LEFT", macroDropdown, "RIGHT", 10, 0)
    arrowText:SetText("|cFF00CCCC→|r")

    -- Command block selection dropdown (no label, self-explanatory)
    local blockDropdown = CreateDropdown(frame, 260, 22, "(Select Command Block)",
        function()
            -- Get items for dropdown
            local blocks = KOL.CommandBlocks:GetAll()
            local items = {}

            -- Add "Create New" option at the top
            table.insert(items, {
                text = "|cFFFFAA00[Create New]|r",
                value = "__CREATE_NEW__",
            })

            -- Add existing blocks
            for name, _ in pairs(blocks) do
                table.insert(items, {
                    text = name,
                    value = name,
                })
            end

            return items
        end,
        function(value, text)
            -- On select callback
            if value == "__CREATE_NEW__" then
                -- Reset dropdown and open editor
                blockDropdown:SetText("(Select Block)")
                selectedCommandBlockForUpdater = nil
                -- Use new CommandBlocks module editor
                if KOL.CommandBlocks then
                    KOL.CommandBlocks:ShowEditor()
                end
            else
                selectedCommandBlockForUpdater = value
                -- Execute command block to show preview
                local result = MacroUpdater:ExecuteCommandBlock(value)
                if result then
                    frame.updatedText:SetText(result)
                    frame.updatedText:SetTextColor(0, 1, 0, 1)
                else
                    frame.updatedText:SetText("(Command block returned nil)")
                    frame.updatedText:SetTextColor(1, 0.5, 0, 1)
                end
            end
        end
    )
    blockDropdown:SetPoint("LEFT", arrowText, "RIGHT", 10, 0)
    frame.blockDropdown = blockDropdown

    -- Current Macro section
    local currentLabel = frame:CreateFontString(nil, "OVERLAY")
    currentLabel:SetFont(fontPath, 12, fontOutline)
    currentLabel:SetPoint("TOPLEFT", 10, -75)
    currentLabel:SetText("|cFFFFFFFFCurrent Macro:|r")

    local currentBox = CreateFrame("ScrollFrame", "KOL_MacroUpdater_CurrentScroll", frame, "UIPanelScrollFrameTemplate")
    currentBox:SetPoint("TOPLEFT", 10, -95)
    currentBox:SetPoint("TOPRIGHT", -30, -95)
    currentBox:SetHeight(170)
    currentBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    currentBox:SetBackdropColor(0.08, 0.08, 0.08, 1)
    currentBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local currentText = CreateFrame("EditBox", nil, currentBox)
    currentText:SetMultiLine(true)
    currentText:SetMaxLetters(0)
    currentText:SetFont(fontPath, 10, fontOutline)
    currentText:SetWidth(currentBox:GetWidth() - 30)
    currentText:SetHeight(500)  -- Tall enough for scrolling
    currentText:SetAutoFocus(false)
    currentText:SetTextInsets(5, 5, 5, 5)
    currentText:SetTextColor(0.8, 0.8, 0.8, 1)
    currentText:SetText("(No macro selected)")
    currentText:EnableMouse(false)  -- Read-only, no clicking
    currentText:EnableKeyboard(false)  -- Read-only, no typing
    currentBox:SetScrollChild(currentText)
    frame.currentText = currentText

    -- Skin the scrollbar
    KOL:SkinUIPanelScrollFrame(currentBox)

    -- Updated Macro section
    local updatedLabel = frame:CreateFontString(nil, "OVERLAY")
    updatedLabel:SetFont(fontPath, 12, fontOutline)
    updatedLabel:SetPoint("TOPLEFT", 10, -275)
    updatedLabel:SetText("|cFFFFFFFFUpdated Macro:|r |cFFAAAA00(preview)|r")

    local updatedBox = CreateFrame("ScrollFrame", "KOL_MacroUpdater_UpdatedScroll", frame, "UIPanelScrollFrameTemplate")
    updatedBox:SetPoint("TOPLEFT", 10, -295)
    updatedBox:SetPoint("TOPRIGHT", -30, -295)
    updatedBox:SetHeight(170)
    updatedBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    updatedBox:SetBackdropColor(0.08, 0.08, 0.08, 1)
    updatedBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local updatedText = CreateFrame("EditBox", nil, updatedBox)
    updatedText:SetMultiLine(true)
    updatedText:SetMaxLetters(0)
    updatedText:SetFont(fontPath, 10, fontOutline)
    updatedText:SetWidth(updatedBox:GetWidth() - 30)
    updatedText:SetHeight(500)  -- Tall enough for scrolling
    updatedText:SetAutoFocus(false)
    updatedText:SetTextInsets(5, 5, 5, 5)
    updatedText:SetTextColor(0, 1, 0, 1)  -- Green for updated
    updatedText:SetText("(No command block selected)")
    updatedText:EnableMouse(false)  -- Read-only, no clicking
    updatedText:EnableKeyboard(false)  -- Read-only, no typing
    updatedBox:SetScrollChild(updatedText)
    frame.updatedText = updatedText

    -- Skin the scrollbar
    KOL:SkinUIPanelScrollFrame(updatedBox)

    -- Save button
    local saveBtn = CreateStyledButton(frame, 100, 30, "Save")
    saveBtn:SetPoint("BOTTOMLEFT", 10, 10)
    saveBtn:SetScript("OnClick", function()
        if not selectedMacroForUpdater or not selectedCommandBlockForUpdater then
            KOL:PrintTag(RED("Error:") .. " Please select both a macro and command block")
            return
        end

        MacroUpdater:EnableMacroAutoUpdate(selectedMacroForUpdater, selectedCommandBlockForUpdater)
        KOL:PrintTag("Saved! " .. YELLOW(selectedMacroForUpdater) .. " will auto-update using " .. YELLOW(selectedCommandBlockForUpdater))
    end)

    -- Test Command Block button
    local testBtn = CreateStyledButton(frame, 140, 30, "Test Command Block")
    testBtn:SetPoint("LEFT", saveBtn, "RIGHT", 10, 0)
    testBtn:SetScript("OnClick", function()
        if not selectedCommandBlockForUpdater then
            KOL:PrintTag(RED("Error:") .. " Please select a command block first")
            return
        end

        -- Execute command block to show preview
        local result = MacroUpdater:ExecuteCommandBlock(selectedCommandBlockForUpdater)
        if result then
            frame.updatedText:SetText(result)
            frame.updatedText:SetTextColor(0, 1, 0, 1)
            KOL:PrintTag(GREEN("Success!") .. " Command block " .. YELLOW(selectedCommandBlockForUpdater) .. " executed")
        else
            frame.updatedText:SetText("(Command block returned nil or failed)")
            frame.updatedText:SetTextColor(1, 0.5, 0, 1)
            KOL:PrintTag(RED("Error:") .. " Command block " .. YELLOW(selectedCommandBlockForUpdater) .. " returned nil")
        end
    end)

    -- Open Command Block Editor button
    local editorBtn = CreateStyledButton(frame, 180, 30, "Command Block Editor")
    editorBtn:SetPoint("LEFT", testBtn, "RIGHT", 10, 0)
    editorBtn:SetScript("OnClick", function()
        local cbFrame = CreateCommandBlockEditor()
        if cbFrame:IsShown() then
            cbFrame:Hide()
        else
            -- Position to the right of Macro Updater window
            cbFrame:ClearAllPoints()
            cbFrame:SetPoint("LEFT", frame, "RIGHT", 20, 0)
            cbFrame:Show()
        end
    end)

    -- Close button
    local closeBtn2 = CreateStyledButton(frame, 100, 30, "Close")
    closeBtn2:SetPoint("BOTTOMRIGHT", -10, 10)
    closeBtn2:SetScript("OnClick", function() frame:Hide() end)

    macroUpdaterFrame = frame
    return frame
end

-- Show Macro Updater window (for /kol macroupdater command)
function MacroUpdater:ShowUI()
    local frame = CreateMacroUpdaterWindow()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

-- Show Command Block Editor window
function MacroUpdater:ShowCommandBlockEditor()
    -- Use the new CommandBlocks module editor
    if KOL.CommandBlocks then
        KOL.CommandBlocks:ShowEditor()
    end
end

-- ============================================================================
-- Event Registration
-- ============================================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" and KOL.db then
        MacroUpdater:Initialize()
    end
end)
