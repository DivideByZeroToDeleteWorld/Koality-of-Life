local KOL = KoalityOfLife

KOL.Binds = {}
local Binds = KOL.Binds

local secureButtons = {}
local activeProfile = "default"
local captureMode = false
local pendingBind = nil
local inputDialog = nil
local pendingInput = nil
local searchFilter = ""
local keybindingEditor = nil
local batchDialog = nil

function Binds:Initialize()
    KOL:DebugPrint("Binds: Initializing keybinding system")

    if not KOL.db.profile.binds then
        KOL.db.profile.binds = {
            enabled = true,
            showInCombat = false,
            groups = {
                configs = {name = "Configs", color = "STANDARD_GRAY", isSystem = true},
                general = {name = "General", color = "PASTEL_YELLOW", isSystem = true},
            },
            keybindings = {},
            profiles = {
                ["default"] = {
                    name = "Default Profile",
                    groups = {},
                    keybindings = {},
                }
            },
            settings = {
                rememberInputs = true,
                instantProfileSwitch = false,
                showNotifications = true,
            }
        }
    end

    KOL:RegisterSlashCommand("kbc", function(input) self:HandleSlashCommand(input) end, "Keybinding manager commands", "module")

    KOL:DebugPrint("Binds: Initialization complete")
end

KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
    if KOL.Binds and KOL.Binds.Initialize then
        KOL.Binds:Initialize()
    end
end)

function Binds:OpenManager()
    if not KOL.db.profile.binds.enabled then
        KOL:PrintTag(RED("Binds system is disabled. Enable it in the config panel."))
        return
    end

    KOL:PrintTag(PASTEL_YELLOW("Keybinding Manager") .. " - Phase 2 Interface")
    KOL:Print("Available commands:")
    KOL:Print("  /kbc - Open this manager")
    KOL:Print("  /kbc add <name> <type> <target> - Add new keybinding")
    KOL:Print("  /kbc bind <bindId> - Capture key for existing bind")
    KOL:Print("  /kbc list - List all keybindings")
    KOL:Print("  /kbc delete <bindId> - Delete keybinding")
    KOL:Print("  /kol config - Open full config panel")
end

function Binds:StartKeyCapture(bindId)
    if InCombatLockdown() then
        KOL:PrintTag(RED("Cannot capture keybindings in combat"))
        return false
    end

    local bind = KOL.db.profile.binds.keybindings[bindId]
    if not bind then
        KOL:PrintTag(RED("Keybinding not found: ") .. bindId)
        return false
    end

    captureMode = true
    pendingBind = bindId

    KOL:PrintTag(PASTEL_YELLOW("Key Capture Mode") .. " - Press the key you want to bind to " .. GREEN(bind.name))
    KOL:Print("Press ESC to cancel capture")

    local captureFrame = CreateFrame("Frame", "KOL_BindsCaptureFrame", UIParent)
    captureFrame:SetAllPoints()
    captureFrame:SetFrameStrata("DIALOG")
    captureFrame:EnableKeyboard(true)
    captureFrame:EnableMouse(true)
    captureFrame:SetScript("OnKeyDown", function(self, key)
        self:HandleKeyCapture(key)
    end)
    captureFrame:SetScript("OnMouseDown", function(self, button)
        self:HandleMouseCapture(button)
    end)

    captureFrame.HandleKeyCapture = function(self, key)
        if not captureMode then return end

        if key == "ESCAPE" then
            Binds:CancelKeyCapture()
            return
        end

        local fullKey = Binds:BuildKeyString(key)

        local conflict = Binds:CheckKeyConflict(fullKey, bindId)
        if conflict then
            if conflict.id == "WOW" then
                KOL:PrintTag(YELLOW("Warning: ") .. fullKey .. " is already used by " .. conflict.name)
                KOL:Print("This binding will be overwritten. Continue? (Press key again to confirm, ESC to cancel)")
                return
            else
                KOL:PrintTag(RED("Key conflict: ") .. fullKey .. " is already bound to " .. PASTEL_YELLOW(conflict.name))
                KOL:Print("Use /kbc delete " .. conflict.id .. " to remove the conflicting bind")
                Binds:CancelKeyCapture()
                return
            end
        end

        if Binds:ApplyKeybinding(bindId, fullKey) then
            KOL:PrintTag(GREEN("Successfully bound: ") .. PASTEL_YELLOW(bind.name) .. " → " .. GREEN(fullKey))
        end

        Binds:CancelKeyCapture()
    end

    captureFrame.HandleMouseCapture = function(self, button)
        if not captureMode then return end

        if button == "RightButton" then
            Binds:CancelKeyCapture()
            return
        end

        local fullKey = Binds:BuildKeyString("BUTTON" .. button)

        local conflict = Binds:CheckKeyConflict(fullKey, bindId)
        if conflict then
            if conflict.id == "WOW" then
                KOL:PrintTag(YELLOW("Warning: ") .. fullKey .. " is already used by " .. conflict.name)
                KOL:Print("This binding will be overwritten. Continue? (Click again to confirm, Right-click to cancel)")
                return
            else
                KOL:PrintTag(RED("Key conflict: ") .. fullKey .. " is already bound to " .. PASTEL_YELLOW(conflict.name))
                KOL:Print("Use /kbc delete " .. conflict.id .. " to remove the conflicting bind")
                Binds:CancelKeyCapture()
                return
            end
        end

        if Binds:ApplyKeybinding(bindId, fullKey) then
            KOL:PrintTag(GREEN("Successfully bound: ") .. PASTEL_YELLOW(bind.name) .. " → " .. GREEN(fullKey))
        end

        Binds:CancelKeyCapture()
    end

    self.captureFrame = captureFrame
    return true
end

function Binds:CancelKeyCapture()
    captureMode = false
    pendingBind = nil

    if self.captureFrame then
        self.captureFrame:Hide()
        self.captureFrame = nil
    end

    KOL:PrintTag(YELLOW("Key capture cancelled"))
end

function Binds:BuildKeyString(key)
    local modifiers = {}

    if IsShiftKeyDown() then table.insert(modifiers, "SHIFT") end
    if IsControlKeyDown() then table.insert(modifiers, "CTRL") end
    if IsAltKeyDown() then table.insert(modifiers, "ALT") end

    local fullKey = table.concat(modifiers, "-")
    if fullKey ~= "" then
        fullKey = fullKey .. "-" .. key
    else
        fullKey = key
    end

    return fullKey
end

function Binds:CheckKeyConflict(key, excludeBindId)
    for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
        if bindId ~= excludeBindId and bind.enabled and bind.key == key then
            return {id = bindId, name = bind.name}
        end
    end

    local existingAction = GetBindingAction(key)
    if existingAction and existingAction ~= "" then
        return {id = "WOW", name = "WoW Default: " .. existingAction}
    end

    return nil
end

function Binds:ApplyKeybinding(bindId, key)
    if InCombatLockdown() then
        KOL:PrintTag(RED("Cannot modify keybindings in combat"))
        return false
    end

    local bind = KOL.db.profile.binds.keybindings[bindId]
    if not bind then
        return false
    end

    if bind.key and bind.key ~= "" then
        SetBinding(bind.key)
    end

    -- IMPORTANT: Remove this key from any OTHER binds (including our own) to prevent conflicts
    local clearedBinds = {}
    for otherBindId, otherBind in pairs(KOL.db.profile.binds.keybindings) do
        if otherBindId ~= bindId and otherBind.key == key then
            otherBind.key = ""
            table.insert(clearedBinds, otherBind.name)
        end
    end

    if #clearedBinds > 0 then
        KOL:PrintTag(YELLOW("Cleared key from existing binds: ") .. table.concat(clearedBinds, ", "))
    end

    local buttonName = "KOL_Binds_Button_" .. bindId:gsub("[^%w_]", "_")
    local secureButton = secureButtons[buttonName]

    if not secureButton then
        secureButton = CreateFrame("Button", buttonName, UIParent, "SecureActionButtonTemplate")
        secureButton:Hide()
        secureButton:SetSize(1, 1)
        secureButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -100, -100)
        secureButtons[buttonName] = secureButton
    end

    if bind.type == "internal" then
        secureButton:SetAttribute("type", "macro")
        secureButton:SetAttribute("macrotext", "/script KoalityOfLife.Binds:ExecuteKeybinding('" .. bindId .. "')")
    elseif bind.type == "synastria" then
        secureButton:SetAttribute("type", "macro")
        secureButton:SetAttribute("macrotext", "." .. bind.target)
    elseif bind.type == "commandblock" then
        secureButton:SetAttribute("type", "macro")
        secureButton:SetAttribute("macrotext", "/script KoalityOfLife.Binds:ExecuteKeybinding('" .. bindId .. "')")
    end

    local success = SetBindingClick(key, buttonName, "LeftButton")

    if success then
        bind.key = key
        return true
    else
        KOL:PrintTag(RED("Failed to bind key: ") .. key)
        return false
    end
end

function Binds:RemoveKeybinding(bindId)
    if InCombatLockdown() then
        KOL:PrintTag(RED("Cannot modify keybindings in combat"))
        return false
    end

    local bind = KOL.db.profile.binds.keybindings[bindId]
    if not bind then
        return false
    end

    if bind.key and bind.key ~= "" then
        SetBinding(bind.key)
    end

    bind.key = ""

    KOL:PrintTag(GREEN("Removed keybinding for: ") .. PASTEL_YELLOW(bind.name))
    return true
end

function Binds:BindRequiresInput(bind)
    -- Use heuristic: command blocks and synastria commands with placeholders might need input
    return bind.type == "commandblock" or (bind.type == "synastria" and bind.target:find("%{"))
end

function Binds:ShowAdvancedInputDialog(bindId, bind)
    if inputDialog then
        inputDialog:Hide()
    end

    local paramConfig = self:ParseParameterRequirements(bind.target)

    local charName = UnitName("player") .. " - " .. GetRealmName()

    if not KOL.db.profile.binds.characterInputs then
        KOL.db.profile.binds.characterInputs = {}
    end
    if not KOL.db.profile.binds.characterInputs[charName] then
        KOL.db.profile.binds.characterInputs[charName] = {}
    end

    inputDialog = CreateFrame("Frame", "KOL_BindsAdvancedInputDialog", UIParent)
    inputDialog:SetFrameStrata("DIALOG")
    inputDialog:SetWidth(500)
    inputDialog:SetHeight(300 + (#paramConfig * 60))
    inputDialog:SetPoint("CENTER", UIParent, "CENTER")
    inputDialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    inputDialog:SetBackdropBorderColor(0.5, 0.5, 0.5)
    inputDialog:EnableMouse(true)
    inputDialog:SetMovable(true)
    inputDialog:RegisterForDrag("LeftButton")
    inputDialog:SetScript("OnDragStart", function() inputDialog:StartMoving() end)
    inputDialog:SetScript("OnDragStop", function() inputDialog:StopMovingOrSizing() end)

    local title = inputDialog:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", inputDialog, "TOP", 0, -16)
    title:SetText("Parameters Required")

    local desc = inputDialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetWidth(460)
    desc:SetJustifyH("LEFT")
    desc:SetText("Enter parameters for " .. PASTEL_YELLOW(bind.name) .. ":")

    local inputFields = {}

    for i, param in ipairs(paramConfig) do
        local yOffset = -60 - ((i - 1) * 60)

        local label = inputDialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", inputDialog, "TOPLEFT", 20, yOffset)
        label:SetText(param.name .. (param.required and " " .. RED("*") or ""))

        if param.description then
            local paramDesc = inputDialog:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            paramDesc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
            paramDesc:SetWidth(460)
            paramDesc:SetJustifyH("LEFT")
            paramDesc:SetText(param.description)
        end

        local inputBox = CreateFrame("EditBox", nil, inputDialog, "InputBoxTemplate")
        inputBox:SetWidth(300)
        inputBox:SetHeight(32)
        inputBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -20)

        local lastValue = ""
        if KOL.db.profile.binds.settings.rememberInputs then
            lastValue = KOL.db.profile.binds.characterInputs[charName][bindId .. "_" .. param.name] or param.default or ""
        else
            lastValue = param.default or ""
        end
        inputBox:SetText(lastValue)

        local validationText = inputDialog:CreateFontString(nil, "ARTWORK", "GameFontRedSmall")
        validationText:SetPoint("LEFT", inputBox, "RIGHT", 10, 0)
        validationText:SetText("")
        validationText:Hide()

        inputFields[param.name] = {
            box = inputBox,
            config = param,
            validation = validationText
        }

        inputBox:SetScript("OnTextChanged", function()
            local value = inputBox:GetText()
            local isValid, errorMsg = self:ValidateParameter(value, param)

            if not isValid then
                validationText:SetText(errorMsg)
                validationText:Show()
                inputBox:SetTextColor(1, 0.5, 0.5)
            else
                validationText:Hide()
                inputBox:SetTextColor(1, 1, 1)
            end
        end)
    end

    local okButton = CreateFrame("Button", nil, inputDialog, "UIPanelButtonTemplate")
    okButton:SetWidth(120)
    okButton:SetHeight(25)
    okButton:SetPoint("BOTTOMRIGHT", inputDialog, "BOTTOM", -6, 20)
    okButton:SetText("Execute")
    okButton:SetScript("OnClick", function()
        local params = {}
        local isValid = true

        for paramName, field in pairs(inputFields) do
            local value = field.box:GetText()
            local valid, errorMsg = self:ValidateParameter(value, field.config)

            if not valid then
                field.validation:SetText(errorMsg)
                field.validation:Show()
                isValid = false
            else
                params[paramName] = value
            end
        end

        if isValid then
            if KOL.db.profile.binds.settings.rememberInputs then
                for paramName, value in pairs(params) do
                    KOL.db.profile.binds.characterInputs[charName][bindId .. "_" .. paramName] = value
                end
            end

            self:ExecuteKeybindingWithParameters(bindId, bind, params)
            inputDialog:Hide()
            inputDialog = nil
        end
    end)

    local cancelButton = CreateFrame("Button", nil, inputDialog, "UIPanelButtonTemplate")
    cancelButton:SetWidth(120)
    cancelButton:SetHeight(25)
    cancelButton:SetPoint("BOTTOMLEFT", inputDialog, "BOTTOM", 6, 20)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        inputDialog:Hide()
        inputDialog = nil
    end)

    inputDialog:Show()

    if #paramConfig > 0 then
        inputFields[paramConfig[1].name].box:SetFocus()
    end
end

function Binds:ParseParameterRequirements(target)
    local params = {}

    for paramStr in target:gmatch("{([^}]+)}") do
        local parts = {}
        for part in paramStr:gmatch("[^:]+") do
            table.insert(parts, part)
        end

        local param = {
            name = parts[1] or "param",
            type = parts[2] or "string",
            description = parts[3] or "",
            default = parts[4] or "",
            required = true
        }

        if param.name:sub(1, 1) == "?" then
            param.name = param.name:sub(2)
            param.required = false
        end

        if param.type == "number" then
            param.validate = function(value) return tonumber(value) ~= nil, "Must be a number" end
        elseif param.type == "integer" then
            param.validate = function(value)
                local num = tonumber(value)
                return num and math.floor(num) == num, "Must be an integer"
            end
        elseif param.type == "positive" then
            param.validate = function(value)
                local num = tonumber(value)
                return num and num > 0, "Must be a positive number"
            end
        elseif param.type == "player" then
            param.validate = function(value)
                return value and value:match("^[%a%d]+$"), "Invalid player name"
            end
        elseif param.type == "channel" then
            param.validate = function(value)
                local validChannels = {["say"] = true, ["yell"] = true, ["party"] = true,
                                     ["guild"] = true, ["officer"] = true, ["raid"] = true}
                return validChannels[value:lower()], "Invalid channel name"
            end
        else
            param.validate = function(value) return true, "" end
        end

        table.insert(params, param)
    end

    if #params == 0 then
        table.insert(params, {
            name = "input",
            type = "string",
            description = "Enter command input",
            default = "",
            required = true,
            validate = function(value) return value and value ~= "", "Input cannot be empty" end
        })
    end

    return params
end

function Binds:ValidateParameter(value, param)
    if not value or value == "" then
        if param.required then
            return false, "Required field"
        else
            return true, ""
        end
    end

    if param.validate then
        return param.validate(value)
    end

    return true, ""
end

function Binds:ExecuteKeybindingWithParameters(bindId, bind, params)
    local processedTarget = bind.target
    for paramName, value in pairs(params) do
        processedTarget = processedTarget:gsub("{" .. paramName .. "[^}]*}", value)
    end

    local tempBind = {
        name = bind.name,
        type = bind.type,
        target = processedTarget,
        context = bind.context,
        enabled = bind.enabled
    }

    return self:ExecuteKeybinding(bindId, nil, tempBind)
end

function Binds:ShowInputDialog(bindId, bind)
    if bind.target:find("{") then
        return self:ShowAdvancedInputDialog(bindId, bind)
    end

    if inputDialog then
        inputDialog:Hide()
    end

    local charName = UnitName("player") .. " - " .. GetRealmName()

    local lastInput = ""
    if KOL.db.profile.binds.settings.rememberInputs then
        if not KOL.db.profile.binds.characterInputs then
            KOL.db.profile.binds.characterInputs = {}
        end
        if not KOL.db.profile.binds.characterInputs[charName] then
            KOL.db.profile.binds.characterInputs[charName] = {}
        end
        lastInput = KOL.db.profile.binds.characterInputs[charName][bindId] or ""
    end

    inputDialog = CreateFrame("Frame", "KOL_BindsInputDialog", UIParent)
    inputDialog:SetFrameStrata("DIALOG")
    inputDialog:SetWidth(400)
    inputDialog:SetHeight(150)
    inputDialog:SetPoint("CENTER", UIParent, "CENTER")
    inputDialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    inputDialog:SetBackdropBorderColor(0.5, 0.5, 0.5)

    local title = inputDialog:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", inputDialog, "TOP", 0, -16)
    title:SetText("Input Required")

    local question = inputDialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    question:SetPoint("TOP", title, "BOTTOM", 0, -16)
    question:SetWidth(380)
    question:SetText("Enter input for " .. PASTEL_YELLOW(bind.name) .. ":")

    local inputBox = CreateFrame("EditBox", nil, inputDialog, "InputBoxTemplate")
    inputBox:SetWidth(300)
    inputBox:SetHeight(32)
    inputBox:SetPoint("TOP", question, "BOTTOM", 0, -16)
    inputBox:SetAutoFocus(true)
    inputBox:SetText(lastInput)

    local okButton = CreateFrame("Button", nil, inputDialog, "UIPanelButtonTemplate")
    okButton:SetWidth(100)
    okButton:SetHeight(25)
    okButton:SetPoint("BOTTOMRIGHT", inputDialog, "BOTTOM", -6, 16)
    okButton:SetText("OK")
    okButton:SetScript("OnClick", function()
        local inputText = inputBox:GetText()
        self:HandleInputDialog(bindId, bind, inputText)
        inputDialog:Hide()
        inputDialog = nil
    end)

    local cancelButton = CreateFrame("Button", nil, inputDialog, "UIPanelButtonTemplate")
    cancelButton:SetWidth(100)
    cancelButton:SetHeight(25)
    cancelButton:SetPoint("BOTTOMLEFT", inputDialog, "BOTTOM", 6, 16)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        inputDialog:Hide()
        inputDialog = nil
    end)

    inputBox:SetScript("OnEnterPressed", function()
        local inputText = inputBox:GetText()
        self:HandleInputDialog(bindId, bind, inputText)
        inputDialog:Hide()
        inputDialog = nil
    end)

    inputBox:SetScript("OnEscapePressed", function()
        inputDialog:Hide()
        inputDialog = nil
    end)

    inputDialog:Show()
    inputBox:SetFocus()
end

function Binds:HandleInputDialog(bindId, bind, input)
    if KOL.db.profile.binds.settings.rememberInputs and input and input ~= "" then
        local charName = UnitName("player") .. " - " .. GetRealmName()

        if not KOL.db.profile.binds.characterInputs then
            KOL.db.profile.binds.characterInputs = {}
        end
        if not KOL.db.profile.binds.characterInputs[charName] then
            KOL.db.profile.binds.characterInputs[charName] = {}
        end

        KOL.db.profile.binds.characterInputs[charName][bindId] = input
    end

    self:ExecuteKeybinding(bindId, input)
end

function Binds:ListProfiles()
    KOL:PrintTag(PASTEL_YELLOW("Binds Profiles:"))

    for profileId, profile in pairs(KOL.db.profile.binds.profiles) do
        local status = profileId == activeProfile and GREEN("[ACTIVE]") or ""
        local bindCount = 0
        if profile.keybindings then
            for _ in pairs(profile.keybindings) do
                bindCount = bindCount + 1
            end
        end

        KOL:Print(string.format("  %s %s - %d keybindings",
            PASTEL_YELLOW(profile.name),
            status,
            bindCount))
    end

    KOL:Print("Current profile: " .. GREEN(activeProfile))
end

function Binds:SwitchProfile(profileId)
    if not KOL.db.profile.binds.profiles[profileId] then
        KOL:PrintTag(RED("Profile not found: ") .. profileId)
        return false
    end

    if profileId == activeProfile then
        KOL:PrintTag(YELLOW("Already using profile: ") .. profileId)
        return true
    end

    self:RemoveAllKeybindings()

    activeProfile = profileId
    KOL.db.profile.binds.activeProfile = profileId

    self:ReapplyAllKeybindings()

    KOL:PrintTag(GREEN("Switched to profile: ") .. PASTEL_YELLOW(KOL.db.profile.binds.profiles[profileId].name))
    return true
end

function Binds:CreateProfile(name)
    if not name or name == "" then
        KOL:PrintTag(RED("Profile name cannot be empty"))
        return false
    end

    local profileId = name:lower():gsub("%s+", "_"):gsub("[^%w_]", "")

    if KOL.db.profile.binds.profiles[profileId] then
        KOL:PrintTag(RED("Profile already exists: ") .. name)
        return false
    end

    KOL.db.profile.binds.profiles[profileId] = {
        name = name,
        groups = {},
        keybindings = {},
    }

    KOL:PrintTag(GREEN("Created profile: ") .. PASTEL_YELLOW(name))
    return true
end

function Binds:DeleteProfile(profileId)
    if profileId == "default" then
        KOL:PrintTag(RED("Cannot delete the default profile"))
        return false
    end

    if not KOL.db.profile.binds.profiles[profileId] then
        KOL:PrintTag(RED("Profile not found: ") .. profileId)
        return false
    end

    if profileId == activeProfile then
        KOL:PrintTag(RED("Cannot delete the active profile. Switch to another profile first."))
        return false
    end

    local profileName = KOL.db.profile.binds.profiles[profileId].name
    KOL.db.profile.binds.profiles[profileId] = nil

    KOL:PrintTag(GREEN("Deleted profile: ") .. PASTEL_YELLOW(profileName))
    return true
end

function Binds:ExportProfile(profileId)
    profileId = profileId or activeProfile

    if not KOL.db.profile.binds.profiles[profileId] then
        KOL:PrintTag(RED("Profile not found: ") .. profileId)
        return false
    end

    local profile = KOL.db.profile.binds.profiles[profileId]
    local exportData = {
        version = "1.0",
        profileName = profile.name,
        groups = {},
        keybindings = {},
    }

    for groupId, group in pairs(KOL.db.profile.binds.groups) do
        exportData.groups[groupId] = {
            name = group.name,
            color = group.color,
            isSystem = group.isSystem or false,
        }
    end

    for bindId, bind in pairs(profile.keybindings) do
        exportData.keybindings[bindId] = {
            name = bind.name,
            type = bind.type,
            target = bind.target,
            key = bind.key or "",
            modifiers = bind.modifiers or {},
            group = bind.group,
            enabled = bind.enabled,
            order = bind.order,
        }
    end

    local exportString = self:SerializeProfile(exportData)

    KOL:PrintTag(PASTEL_YELLOW("Profile Export: ") .. profile.name)
    KOL:Print("Copy the text below:")
    KOL:Print("--- START EXPORT ---")
    KOL:Print(exportString)
    KOL:Print("--- END EXPORT ---")

    return true
end

function Binds:ImportProfile()
    KOL:PrintTag(PASTEL_YELLOW("Profile Import"))
    KOL:Print("Paste the exported profile data in chat and press Enter:")
    KOL:Print("Type " .. RED("/kbc cancel") .. " to cancel import")

    local importHandler = CreateFrame("Frame")
    importHandler:RegisterEvent("CHAT_MSG_ADDON")

    local function OnAddonMessage(self, event, prefix, message, channel, sender)
        if prefix == "KOL_BINDS_IMPORT" then
            importHandler:UnregisterEvent("CHAT_MSG_ADDON")

            if message == "CANCEL" then
                KOL:PrintTag(YELLOW("Import cancelled"))
                return
            end

            local success, errorMsg = pcall(function()
                local profileData = self:DeserializeProfile(message)
                if profileData then
                    self:ProcessImportedProfile(profileData)
                else
                    error("Invalid profile data format")
                end
            end)

            if not success then
                KOL:PrintTag(RED("Import failed: ") .. tostring(errorMsg))
            end
        end
    end

    importHandler:SetScript("OnEvent", OnAddonMessage)

    KOL:RegisterSlashCommand("kbc", function(input)
        if string.lower(input or "") == "cancel" then
            SendAddonMessage("KOL_BINDS_IMPORT", "CANCEL", "WHISPER", UnitName("player"))
        end
    end, "temp_import_cancel", "module")
end

function Binds:SerializeProfile(data)
    local parts = {}

    table.insert(parts, "KOL_BINDS_PROFILE:" .. data.version)
    table.insert(parts, "NAME:" .. data.profileName)

    for groupId, group in pairs(data.groups) do
        local groupStr = string.format("GROUP:%s|%s|%s|%s",
            groupId, group.name, group.color, tostring(group.isSystem))
        table.insert(parts, groupStr)
    end

    for bindId, bind in pairs(data.keybindings) do
        local bindStr = string.format("BIND:%s|%s|%s|%s|%s|%s|%s|%s|%s",
            bindId, bind.name, bind.type, bind.target,
            bind.key, table.concat(bind.modifiers, ","),
            bind.group, tostring(bind.enabled), tostring(bind.order))
        table.insert(parts, bindStr)
    end

    return table.concat(parts, "\n")
end

function Binds:DeserializeProfile(str)
    if not str or str == "" then
        return nil
    end

    local lines = {}
    for line in str:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    if #lines == 0 then
        return nil
    end

    local header = lines[1]
    if not header:find("^KOL_BINDS_PROFILE:") then
        return nil
    end

    local version = header:sub(19)

    local data = {
        version = version,
        profileName = "",
        groups = {},
        keybindings = {},
    }

    for i = 2, #lines do
        local line = lines[i]

        if line:find("^NAME:") then
            data.profileName = line:sub(6)
        elseif line:find("^GROUP:") then
            local parts = {}
            for part in line:sub(7):gmatch("[^|]+") do
                table.insert(parts, part)
            end

            if #parts >= 4 then
                data.groups[parts[1]] = {
                    name = parts[2],
                    color = parts[3],
                    isSystem = parts[4] == "true",
                }
            end
        elseif line:find("^BIND:") then
            local parts = {}
            for part in line:sub(6):gmatch("[^|]+") do
                table.insert(parts, part)
            end

            if #parts >= 9 then
                local modifiers = {}
                if parts[6] ~= "" then
                    for mod in parts[6]:gmatch("[^,]+") do
                        table.insert(modifiers, mod)
                    end
                end

                data.keybindings[parts[1]] = {
                    name = parts[2],
                    type = parts[3],
                    target = parts[4],
                    key = parts[5],
                    modifiers = modifiers,
                    group = parts[7],
                    enabled = parts[8] == "true",
                    order = tonumber(parts[9]) or 100,
                }
            end
        end
    end

    return data
end

function Binds:ValidateImportData(data)
    if not data then
        return false, "No data provided"
    end

    if not data.profileName or data.profileName == "" then
        return false, "Missing profile name"
    end

    if type(data.profileName) ~= "string" then
        return false, "Invalid profile name type"
    end

    if string.len(data.profileName) > 50 then
        return false, "Profile name too long (max 50 characters)"
    end

    if data.groups then
        if type(data.groups) ~= "table" then
            return false, "Invalid groups data type"
        end

        for groupId, group in pairs(data.groups) do
            if not group.name or group.name == "" then
                return false, "Group missing name: " .. tostring(groupId)
            end

            if not group.color or group.color == "" then
                return false, "Group missing color: " .. group.name
            end

            local validColors = {
                ["RED"] = true, ["GREEN"] = true, ["BLUE"] = true, ["YELLOW"] = true,
                ["ORANGE"] = true, ["PURPLE"] = true, ["CYAN"] = true, ["PINK"] = true,
                ["WHITE"] = true, ["GRAY"] = true, ["STANDARD_GRAY"] = true,
                ["PASTEL_RED"] = true, ["PASTEL_PINK"] = true, ["PASTEL_YELLOW"] = true,
                ["MINT"] = true, ["LAVENDER"] = true, ["PEACH"] = true, ["SKY"] = true,
                ["ROSE"] = true, ["LIME"] = true, ["CORAL"] = true, ["AQUA"] = true,
                ["CREAM"] = true, ["IVORY"] = true, ["PEARL"] = true,
                ["NUCLEAR_RED"] = true, ["NUCLEAR_BLUE"] = true, ["NUCLEAR_SKY_BLUE"] = true,
                ["NUCLEAR_PURPLE"] = true, ["NUCLEAR_GREEN"] = true, ["NUCLEAR_PINK"] = true,
                ["NUCLEAR_WHITE"] = true, ["NUCLEAR_WINTER"] = true, ["NUCLEAR_GREY"] = true,
                ["NUCLEAR_ORANGE"] = true,
            }

            if not validColors[group.color] then
                return false, "Invalid color for group " .. group.name .. ": " .. group.color
            end
        end
    end

    if data.keybindings then
        if type(data.keybindings) ~= "table" then
            return false, "Invalid keybindings data type"
        end

        local bindCount = 0
        for bindId, bind in pairs(data.keybindings) do
            bindCount = bindCount + 1

            if bindCount > 200 then
                return false, "Too many keybindings (max 200)"
            end

            if not bind.name or bind.name == "" then
                return false, "Keybinding missing name: " .. tostring(bindId)
            end

            if not bind.type or bind.type == "" then
                return false, "Keybinding missing type: " .. bind.name
            end

            if not bind.target or bind.target == "" then
                return false, "Keybinding missing target: " .. bind.name
            end

            local validTypes = {["internal"] = true, ["synastria"] = true, ["commandblock"] = true}
            if not validTypes[bind.type] then
                return false, "Invalid type for keybinding " .. bind.name .. ": " .. bind.type
            end

            if string.len(bind.target) > 200 then
                return false, "Target too long for keybinding " .. bind.name .. " (max 200 characters)"
            end

            if bind.context then
                if type(bind.context) == "string" then
                    local validContexts = {
                        ["any"] = true, ["city"] = true, ["dungeon"] = true, ["raid"] = true,
                        ["pvp"] = true, ["outdoor"] = true, ["instance"] = true, ["nomount"] = true,
                        ["noswimming"] = true, ["combat_only"] = true, ["out_of_combat"] = true,
                        ["flying"] = true, ["grounded"] = true
                    }
                    if not validContexts[bind.context] then
                        return false, "Invalid context for keybinding " .. bind.name .. ": " .. bind.context
                    end
                elseif type(bind.context) == "table" then
                    for _, ctx in ipairs(bind.context) do
                        local validContexts = {
                            ["any"] = true, ["city"] = true, ["dungeon"] = true, ["raid"] = true,
                            ["pvp"] = true, ["outdoor"] = true, ["instance"] = true, ["nomount"] = true,
                            ["noswimming"] = true, ["combat_only"] = true, ["out_of_combat"] = true,
                            ["flying"] = true, ["grounded"] = true
                        }
                        if not validContexts[ctx] then
                            return false, "Invalid context for keybinding " .. bind.name .. ": " .. ctx
                        end
                    end
                else
                    return false, "Invalid context type for keybinding " .. bind.name
                end
            end
        end
    end

    return true, "Valid"
end

function Binds:ImportProfileWithValidation(importString)
    KOL:PrintTag(PASTEL_YELLOW("Enhanced Profile Import"))

    local success, data = pcall(function()
        return self:DeserializeProfile(importString)
    end)

    if not success then
        KOL:PrintTag(RED("Failed to parse import data: ") .. tostring(data))
        return false
    end

    local valid, errorMsg = self:ValidateImportData(data)
    if not valid then
        KOL:PrintTag(RED("Import validation failed: ") .. errorMsg)
        return false
    end

    self:ShowImportPreview(data)
    return true
end

function Binds:ShowImportPreview(data)
    local previewDialog = CreateFrame("Frame", "KOL_BindsImportPreview", UIParent)
    previewDialog:SetFrameStrata("DIALOG")
    previewDialog:SetWidth(450)
    previewDialog:SetHeight(400)
    previewDialog:SetPoint("CENTER", UIParent, "CENTER")
    previewDialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    previewDialog:SetBackdropBorderColor(0.5, 0.5, 0.5)
    previewDialog:EnableMouse(true)
    previewDialog:SetMovable(true)
    previewDialog:RegisterForDrag("LeftButton")
    previewDialog:SetScript("OnDragStart", function() previewDialog:StartMoving() end)
    previewDialog:SetScript("OnDragStop", function() previewDialog:StopMovingOrSizing() end)

    local title = previewDialog:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", previewDialog, "TOP", 0, -16)
    title:SetText("Import Preview")

    local profileInfo = previewDialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    profileInfo:SetPoint("TOPLEFT", previewDialog, "TOPLEFT", 20, -50)
    profileInfo:SetWidth(410)
    profileInfo:SetJustifyH("LEFT")
    profileInfo:SetText(WHITE("Profile Name: ") .. PASTEL_YELLOW(data.profileName))

    local groupCount = data.groups and 0 or 0
    if data.groups then
        for _ in pairs(data.groups) do
            groupCount = groupCount + 1
        end
    end

    local bindCount = data.keybindings and 0 or 0
    if data.keybindings then
        for _ in pairs(data.keybindings) do
            bindCount = bindCount + 1
        end
    end

    local stats = previewDialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    stats:SetPoint("TOPLEFT", profileInfo, "BOTTOMLEFT", 0, -10)
    stats:SetWidth(410)
    stats:SetJustifyH("LEFT")
    stats:SetText(WHITE("Contains: ") .. GREEN(groupCount) .. " groups, " .. GREEN(bindCount) .. " keybindings")

    local warning = previewDialog:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    warning:SetPoint("TOPLEFT", stats, "BOTTOMLEFT", 0, -15)
    warning:SetWidth(410)
    warning:SetJustifyH("LEFT")
    warning:SetText(ORANGE("Warning: This will create a new profile and may add new groups. Existing keybindings will not be affected."))

    if data.keybindings and bindCount > 0 then
        local sampleLabel = previewDialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        sampleLabel:SetPoint("TOPLEFT", warning, "BOTTOMLEFT", 0, -15)
        sampleLabel:SetText(WHITE("Sample Keybindings:"))

        local sampleText = previewDialog:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        sampleText:SetPoint("TOPLEFT", sampleLabel, "BOTTOMLEFT", 0, -5)
        sampleText:SetWidth(410)
        sampleText:SetJustifyH("LEFT")

        local samples = {}
        local count = 0
        for bindId, bind in pairs(data.keybindings) do
            if count < 3 then
                table.insert(samples, "• " .. PASTEL_YELLOW(bind.name) .. " (" .. bind.type .. ")")
                count = count + 1
            end
        end

        if bindCount > 3 then
            table.insert(samples, "... and " .. (bindCount - 3) .. " more")
        end

        sampleText:SetText(table.concat(samples, "\n"))
    end

    local importButton = CreateFrame("Button", nil, previewDialog, "UIPanelButtonTemplate")
    importButton:SetWidth(120)
    importButton:SetHeight(25)
    importButton:SetPoint("BOTTOMRIGHT", previewDialog, "BOTTOM", -6, 20)
    importButton:SetText("Import")
    importButton:SetScript("OnClick", function()
        if self:ProcessImportedProfile(data) then
            previewDialog:Hide()
            previewDialog = nil
        end
    end)

    local cancelButton = CreateFrame("Button", nil, previewDialog, "UIPanelButtonTemplate")
    cancelButton:SetWidth(120)
    cancelButton:SetHeight(25)
    cancelButton:SetPoint("BOTTOMLEFT", previewDialog, "BOTTOM", 6, 20)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        previewDialog:Hide()
        previewDialog = nil
    end)

    previewDialog:Show()
end

function Binds:ExportProfileWithValidation(profileId)
    profileId = profileId or activeProfile

    if not KOL.db.profile.binds.profiles[profileId] then
        KOL:PrintTag(RED("Profile not found: ") .. profileId)
        return false
    end

    local profile = KOL.db.profile.binds.profiles[profileId]

    local exportData = {
        version = "2.0",
        exportDate = date("%Y-%m-%d %H:%M:%S"),
        exportVersion = GetAddOnMetadata("!Koality-of-Life", "Version") or "Unknown",
        profileName = profile.name,
        profileId = profileId,
        groups = {},
        keybindings = {},
        metadata = {
            totalGroups = 0,
            totalKeybindings = 0,
            exportType = "profile",
            gameVersion = GetBuildInfo(),
        }
    }

    for groupId, group in pairs(KOL.db.profile.binds.groups) do
        exportData.groups[groupId] = {
            name = group.name,
            color = group.color,
            isSystem = group.isSystem or false,
        }
        exportData.metadata.totalGroups = exportData.metadata.totalGroups + 1
    end

    for bindId, bind in pairs(profile.keybindings or KOL.db.profile.binds.keybindings) do
        exportData.keybindings[bindId] = {
            name = bind.name,
            type = bind.type,
            target = bind.target,
            key = bind.key or "",
            modifiers = bind.modifiers or {},
            group = bind.group,
            enabled = bind.enabled,
            order = bind.order,
            context = bind.context,
            createdDate = bind.createdDate,
            lastUsed = bind.lastUsed,
        }
        exportData.metadata.totalKeybindings = exportData.metadata.totalKeybindings + 1
    end

    local exportString = self:SerializeProfileEnhanced(exportData)

    self:ShowExportDialog(exportData, exportString)

    return true
end

function Binds:SerializeProfileEnhanced(data)
    local parts = {}

    table.insert(parts, "KOL_BINDS_PROFILE_V2:" .. data.version)
    table.insert(parts, "EXPORT_DATE:" .. data.exportDate)
    table.insert(parts, "EXPORT_VERSION:" .. data.exportVersion)
    table.insert(parts, "NAME:" .. data.profileName)
    table.insert(parts,("METADATA:%s|%s|%s|%s"):format(
        data.metadata.totalGroups,
        data.metadata.totalKeybindings,
        data.metadata.exportType,
        data.metadata.gameVersion or "Unknown"
    ))

    for groupId, group in pairs(data.groups) do
        local groupStr = string.format("GROUP:%s|%s|%s|%s",
            groupId, group.name, group.color, tostring(group.isSystem))
        table.insert(parts, groupStr)
    end

    for bindId, bind in pairs(data.keybindings) do
        local contextStr = bind.context and (type(bind.context) == "table" and table.concat(bind.context, ",") or bind.context) or ""
        local bindStr = string.format("BIND:%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s",
            bindId, bind.name, bind.type, bind.target,
            bind.key, table.concat(bind.modifiers, ","),
            bind.group, tostring(bind.enabled), tostring(bind.order),
            contextStr, bind.createdDate or "", bind.lastUsed or "")
        table.insert(parts, bindStr)
    end

    return table.concat(parts, "\n")
end

function Binds:ShowExportDialog(exportData, exportString)
    local exportDialog = CreateFrame("Frame", "KOL_BindsExportDialog", UIParent)
    exportDialog:SetFrameStrata("DIALOG")
    exportDialog:SetWidth(600)
    exportDialog:SetHeight(500)
    exportDialog:SetPoint("CENTER", UIParent, "CENTER")
    exportDialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    exportDialog:SetBackdropBorderColor(0.5, 0.5, 0.5)
    exportDialog:EnableMouse(true)
    exportDialog:SetMovable(true)
    exportDialog:RegisterForDrag("LeftButton")
    exportDialog:SetScript("OnDragStart", function() exportDialog:StartMoving() end)
    exportDialog:SetScript("OnDragStop", function() exportDialog:StopMovingOrSizing() end)

    local title = exportDialog:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", exportDialog, "TOP", 0, -16)
    title:SetText("Profile Export")

    local infoText = exportDialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    infoText:SetPoint("TOPLEFT", exportDialog, "TOPLEFT", 20, -50)
    infoText:SetWidth(560)
    infoText:SetJustifyH("LEFT")
    infoText:SetText(string.format("%s %s %s (%s groups, %s keybindings)\n%s %s %s %s",
        WHITE("Profile:"),
        PASTEL_YELLOW(exportData.profileName),
        WHITE("("),
        GREEN(exportData.metadata.totalGroups),
        GREEN(exportData.metadata.totalKeybindings),
        WHITE(")"),
        WHITE("Exported:"),
        exportData.exportDate,
        WHITE("Version:"),
        exportData.exportVersion))

    local instructions = exportDialog:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    instructions:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -10)
    instructions:SetWidth(560)
    instructions:SetJustifyH("LEFT")
    instructions:SetText(GRAY("Select all text below (Ctrl+A) and copy (Ctrl+C) to share this profile."))

    local scrollFrame = CreateFrame("ScrollFrame", nil, exportDialog, "UIPanelScrollFrameTemplate")
    scrollFrame:SetWidth(560)
    scrollFrame:SetHeight(300)
    scrollFrame:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -10)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetWidth(560)
    editBox:SetHeight(300)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontDisableSmall")
    editBox:SetText(exportString)
    editBox:SetScript("OnEscapePressed", function()
        exportDialog:Hide()
        exportDialog = nil
    end)

    scrollFrame:SetScrollChild(editBox)

    local selectButton = CreateFrame("Button", nil, exportDialog, "UIPanelButtonTemplate")
    selectButton:SetWidth(100)
    selectButton:SetHeight(25)
    selectButton:SetPoint("BOTTOMLEFT", exportDialog, "BOTTOM", 6, 20)
    selectButton:SetText("Select All")
    selectButton:SetScript("OnClick", function()
        editBox:HighlightText()
        editBox:SetFocus()
    end)

    local closeButton = CreateFrame("Button", nil, exportDialog, "UIPanelButtonTemplate")
    closeButton:SetWidth(100)
    closeButton:SetHeight(25)
    closeButton:SetPoint("BOTTOMRIGHT", exportDialog, "BOTTOM", -6, 20)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        exportDialog:Hide()
        exportDialog = nil
    end)

    exportDialog:Show()
    editBox:HighlightText()
end

function Binds:ProcessImportedProfile(data)
    if not data or not data.profileName then
        KOL:PrintTag(RED("Invalid profile data"))
        return false
    end

    local profileId = data.profileName:lower():gsub("%s+", "_"):gsub("[^%w_]", "")
    local counter = 1
    local originalId = profileId

    while KOL.db.profile.binds.profiles[profileId] do
        profileId = originalId .. "_" .. counter
        counter = counter + 1
    end

    KOL.db.profile.binds.profiles[profileId] = {
        name = data.profileName,
        groups = {},
        keybindings = {},
        importDate = date("%Y-%m-%d %H:%M:%S"),
        importVersion = data.exportVersion or "Unknown",
    }

    for groupId, group in pairs(data.groups) do
        if not group.isSystem then
            KOL.db.profile.binds.groups[groupId] = {
                name = group.name,
                color = group.color,
                isSystem = false,
            }
            KOL.db.profile.binds.profiles[profileId].groups[groupId] = true
        end
    end

    for bindId, bind in pairs(data.keybindings) do
        local importedBind = {
            name = bind.name,
            type = bind.type,
            target = bind.target,
            key = bind.key or "",
            modifiers = bind.modifiers or {},
            group = bind.group,
            enabled = bind.enabled,
            order = bind.order,
            context = bind.context,
            createdDate = bind.createdDate,
            lastUsed = bind.lastUsed,
            importedDate = date("%Y-%m-%d %H:%M:%S"),
        }
        KOL.db.profile.binds.profiles[profileId].keybindings[bindId] = importedBind
    end

    KOL:PrintTag(GREEN("Successfully imported profile: ") .. PASTEL_YELLOW(data.profileName))
    KOL:Print("Use " .. YELLOW("/kbc profile switch " .. profileId) .. " to activate it")

    return true
end

function Binds:GetConfigKeybindingList()
    local text = GRAY("Keybindings:") .. "\n"
    local count = 0

    for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
        if searchFilter == "" or
           bind.name:lower():find(searchFilter, 1, true) or
           bind.type:lower():find(searchFilter, 1, true) then

            local status = bind.enabled and GREEN("✓") or RED("✗")
            local key = bind.key and bind.key ~= "" and GREEN(bind.key) or GRAY("[unbound]")
            local group = KOL.db.profile.binds.groups[bind.group]
            local groupColor = group and KOL.Colors and KOL.Colors[group.color] or WHITE
            local groupName = group and group.name or bind.group
            local requiresInput = self:BindRequiresInput(bind) and PASTEL_PINK("[input]") or ""

            text = text .. string.format("  %s %s%s - %s (%s%s) %s\n",
                status,
                PASTEL_YELLOW(bind.name),
                requiresInput,
                key,
                groupColor, groupName,
                GRAY("[Edit: /kbc edit " .. bindId .. "]"))

            count = count + 1
        end
    end

    if count == 0 then
        if searchFilter ~= "" then
            text = text .. GRAY("  No keybindings match filter: " .. searchFilter)
        else
            text = text .. GRAY("  No keybindings configured")
        end
    end

    text = text .. "\n" .. GRAY("Total: ") .. PASTEL_YELLOW(tostring(count)) .. " keybindings"

    return text
end

function Binds:GetConfigProfileList()
    local text = GRAY("Profiles:") .. "\n"

    for profileId, profile in pairs(KOL.db.profile.binds.profiles) do
        local status = profileId == (activeProfile or "default") and GREEN("[ACTIVE]") or ""
        local bindCount = 0
        if profile.keybindings then
            for _ in pairs(profile.keybindings) do
                bindCount = bindCount + 1
            end
        end

        text = text .. string.format("  %s %s - %d keybindings%s\n",
            PASTEL_YELLOW(profile.name),
            status,
            bindCount,
            profileId ~= "default" and " " .. GRAY("[Delete: /kbc profile delete " .. profileId .. "]") or "")
    end

    text = text .. "\n" .. GRAY("Current: ") .. GREEN(activeProfile or "default")

    return text
end

function Binds:ShowKeybindingEditor(bindId)
    if keybindingEditor then
        keybindingEditor:Hide()
    end

    local isEdit = bindId ~= nil
    local bind = bindId and KOL.db.profile.binds.keybindings[bindId]

    keybindingEditor = CreateFrame("Frame", "KOL_BindsEditor", UIParent)
    keybindingEditor:SetFrameStrata("DIALOG")
    keybindingEditor:SetWidth(500)
    keybindingEditor:SetHeight(400)
    keybindingEditor:SetPoint("CENTER", UIParent, "CENTER")
    keybindingEditor:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    keybindingEditor:SetBackdropBorderColor(0.5, 0.5, 0.5)
    keybindingEditor:EnableMouse(true)
    keybindingEditor:SetMovable(true)
    keybindingEditor:RegisterForDrag("LeftButton")
    keybindingEditor:SetScript("OnDragStart", function() keybindingEditor:StartMoving() end)
    keybindingEditor:SetScript("OnDragStop", function() keybindingEditor:StopMovingOrSizing() end)

    local title = keybindingEditor:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", keybindingEditor, "TOP", 0, -16)
    title:SetText(isEdit and "Edit Keybinding" or "Create New Keybinding")

    local nameLabel = keybindingEditor:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", keybindingEditor, "TOPLEFT", 20, -60)
    nameLabel:SetText("Name:")

    local nameInput = CreateFrame("EditBox", nil, keybindingEditor, "InputBoxTemplate")
    nameInput:SetWidth(300)
    nameInput:SetHeight(32)
    nameInput:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -5)
    nameInput:SetText(bind and bind.name or "")

    local typeLabel = keybindingEditor:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    typeLabel:SetPoint("TOPLEFT", nameInput, "BOTTOMLEFT", 0, -15)
    typeLabel:SetText("Type:")

    local typeDropdown = CreateFrame("Frame", nil, keybindingEditor, "UIDropDownMenuTemplate")
    typeDropdown:SetWidth(150)
    typeDropdown:SetPoint("TOPLEFT", typeLabel, "BOTTOMLEFT", 0, -5)

    local typeOptions = {
        {text = "Internal Action", value = "internal"},
        {text = "Synastria Command", value = "synastria"},
        {text = "Command Block", value = "commandblock"},
    }

    local selectedType = bind and bind.type or "internal"

    UIDropDownMenu_SetWidth(typeDropdown, 150)
    UIDropDownMenu_Initialize(typeDropdown, function()
        for _, option in ipairs(typeOptions) do
            local info = {
                text = option.text,
                value = option.value,
                checked = (option.value == selectedType),
                func = function()
                    selectedType = option.value
                    UIDropDownMenu_SetSelectedName(typeDropdown, option.text)
                    UIDropDownMenu_SetSelectedValue(typeDropdown, option.value)
                end
            }
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetSelectedName(typeDropdown,
        (selectedType == "internal" and "Internal Action") or
        (selectedType == "synastria" and "Synastria Command") or
        "Command Block")

    local targetLabel = keybindingEditor:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    targetLabel:SetPoint("TOPLEFT", typeDropdown, "BOTTOMLEFT", 0, -15)
    targetLabel:SetText("Target:")

    local targetInput = CreateFrame("EditBox", nil, keybindingEditor, "InputBoxTemplate")
    targetInput:SetWidth(300)
    targetInput:SetHeight(32)
    targetInput:SetPoint("TOPLEFT", targetLabel, "BOTTOMLEFT", 0, -5)
    targetInput:SetText(bind and bind.target or "")

    local groupLabel = keybindingEditor:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    groupLabel:SetPoint("TOPLEFT", targetInput, "BOTTOMLEFT", 0, -15)
    groupLabel:SetText("Group:")

    local groupDropdown = CreateFrame("Frame", nil, keybindingEditor, "UIDropDownMenuTemplate")
    groupDropdown:SetWidth(150)
    groupDropdown:SetPoint("TOPLEFT", groupLabel, "BOTTOMLEFT", 0, -5)

    local groupOptions = {}
    for groupId, group in pairs(KOL.db.profile.binds.groups) do
        table.insert(groupOptions, {text = group.name, value = groupId})
    end

    local selectedGroup = bind and bind.group or "general"

    UIDropDownMenu_SetWidth(groupDropdown, 150)
    UIDropDownMenu_Initialize(groupDropdown, function()
        for _, option in ipairs(groupOptions) do
            local info = {
                text = option.text,
                value = option.value,
                checked = (option.value == selectedGroup),
                func = function()
                    selectedGroup = option.value
                    UIDropDownMenu_SetSelectedName(groupDropdown, option.text)
                    UIDropDownMenu_SetSelectedValue(groupDropdown, option.value)
                end
            }
            UIDropDownMenu_AddButton(info)
        end
    end)

    local selectedGroupName = "General"
    for _, option in ipairs(groupOptions) do
        if option.value == selectedGroup then
            selectedGroupName = option.text
            break
        end
    end
    UIDropDownMenu_SetSelectedName(groupDropdown, selectedGroupName)

    local enabledCheck = CreateFrame("CheckButton", nil, keybindingEditor, "UICheckButtonTemplate")
    enabledCheck:SetPoint("TOPLEFT", groupDropdown, "BOTTOMLEFT", 0, -15)
    enabledCheck.text:SetText("Enabled")
    enabledCheck:SetChecked(bind and bind.enabled ~= false)

    local saveButton = CreateFrame("Button", nil, keybindingEditor, "UIPanelButtonTemplate")
    saveButton:SetWidth(100)
    saveButton:SetHeight(25)
    saveButton:SetPoint("BOTTOMRIGHT", keybindingEditor, "BOTTOM", -6, 20)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        local name = nameInput:GetText():trim()
        local target = targetInput:GetText():trim()

        if name == "" then
            KOL:PrintTag(RED("Name cannot be empty"))
            return
        end

        if target == "" then
            KOL:PrintTag(RED("Target cannot be empty"))
            return
        end

        if isEdit then
            bind.name = name
            bind.type = selectedType
            bind.target = target
            bind.group = selectedGroup
            bind.enabled = enabledCheck:GetChecked()

            KOL:PrintTag(GREEN("Updated keybinding: ") .. PASTEL_YELLOW(name))
        else
            local newBindId = name:lower():gsub("%s+", "_"):gsub("[^%w_]", "")
            self:CreateKeybinding(newBindId, {
                name = name,
                type = selectedType,
                target = target,
                group = selectedGroup,
                enabled = enabledCheck:GetChecked()
            })

            KOL:PrintTag(GREEN("Created keybinding: ") .. PASTEL_YELLOW(name))
        end

        keybindingEditor:Hide()
        keybindingEditor = nil

        LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
    end)

    local cancelButton = CreateFrame("Button", nil, keybindingEditor, "UIPanelButtonTemplate")
    cancelButton:SetWidth(100)
    cancelButton:SetHeight(25)
    cancelButton:SetPoint("BOTTOMLEFT", keybindingEditor, "BOTTOM", 6, 20)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        keybindingEditor:Hide()
        keybindingEditor = nil
    end)

    if isEdit then
        local deleteButton = CreateFrame("Button", nil, keybindingEditor, "UIPanelButtonTemplate")
        deleteButton:SetWidth(100)
        deleteButton:SetHeight(25)
        deleteButton:SetPoint("BOTTOM", keybindingEditor, "BOTTOM", 0, 55)
        deleteButton:SetText("Delete")
        deleteButton:SetScript("OnClick", function()
            if self:DeleteKeybinding(bindId) then
                keybindingEditor:Hide()
                keybindingEditor = nil
                LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
            end
        end)
    end

    keybindingEditor:Show()
end

function Binds:ShowBatchDialog()
    if batchDialog then
        batchDialog:Hide()
    end

    batchDialog = CreateFrame("Frame", "KOL_BindsBatchDialog", UIParent)
    batchDialog:SetFrameStrata("DIALOG")
    batchDialog:SetWidth(450)
    batchDialog:SetHeight(350)
    batchDialog:SetPoint("CENTER", UIParent, "CENTER")
    batchDialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    batchDialog:SetBackdropBorderColor(0.5, 0.5, 0.5)
    batchDialog:EnableMouse(true)
    batchDialog:SetMovable(true)
    batchDialog:RegisterForDrag("LeftButton")
    batchDialog:SetScript("OnDragStart", function() batchDialog:StartMoving() end)
    batchDialog:SetScript("OnDragStop", function() batchDialog:StopMovingOrSizing() end)

    local title = batchDialog:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", batchDialog, "TOP", 0, -16)
    title:SetText("Batch Operations")

    local operationLabel = batchDialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    operationLabel:SetPoint("TOPLEFT", batchDialog, "TOPLEFT", 20, -60)
    operationLabel:SetText("Operation:")

    local operationDropdown = CreateFrame("Frame", nil, batchDialog, "UIDropDownMenuTemplate")
    operationDropdown:SetWidth(200)
    operationDropdown:SetPoint("TOPLEFT", operationLabel, "BOTTOMLEFT", 0, -5)

    local operationOptions = {
        {text = "Enable All", value = "enable"},
        {text = "Disable All", value = "disable"},
        {text = "Enable by Group", value = "enable_group"},
        {text = "Disable by Group", value = "disable_group"},
        {text = "Enable by Type", value = "enable_type"},
        {text = "Disable by Type", value = "disable_type"},
        {text = "Remove All Keys", value = "unbind_all"},
    }

    local selectedOperation = "enable"

    UIDropDownMenu_SetWidth(operationDropdown, 200)
    UIDropDownMenu_Initialize(operationDropdown, function()
        for _, option in ipairs(operationOptions) do
            local info = {
                text = option.text,
                value = option.value,
                checked = (option.value == selectedOperation),
                func = function()
                    selectedOperation = option.value
                    UIDropDownMenu_SetSelectedName(operationDropdown, option.text)
                    UIDropDownMenu_SetSelectedValue(operationDropdown, option.value)
                end
            }
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetSelectedName(operationDropdown, "Enable All")

    local targetLabel = batchDialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    targetLabel:SetPoint("TOPLEFT", operationDropdown, "BOTTOMLEFT", 0, -15)
    targetLabel:SetText("Target:")

    local targetDropdown = CreateFrame("Frame", nil, batchDialog, "UIDropDownMenuTemplate")
    targetDropdown:SetWidth(200)
    targetDropdown:SetPoint("TOPLEFT", targetLabel, "BOTTOMLEFT", 0, -5)

    local targetOptions = {}
    local selectedTarget = ""

    local function UpdateTargetOptions()
        targetOptions = {}

        if selectedOperation == "enable_group" or selectedOperation == "disable_group" then
            for groupId, group in pairs(KOL.db.profile.binds.groups) do
                table.insert(targetOptions, {text = group.name, value = groupId})
            end
        elseif selectedOperation == "enable_type" or selectedOperation == "disable_type" then
            table.insert(targetOptions, {text = "Internal", value = "internal"})
            table.insert(targetOptions, {text = "Synastria", value = "synastria"})
            table.insert(targetOptions, {text = "Command Block", value = "commandblock"})
        end

        UIDropDownMenu_Initialize(targetDropdown, function()
            for _, option in ipairs(targetOptions) do
                local info = {
                    text = option.text,
                    value = option.value,
                    checked = (option.value == selectedTarget),
                    func = function()
                        selectedTarget = option.value
                        UIDropDownMenu_SetSelectedName(targetDropdown, option.text)
                        UIDropDownMenu_SetSelectedValue(targetDropdown, option.value)
                    end
                }
                UIDropDownMenu_AddButton(info)
            end
        end)

        if #targetOptions > 0 then
            UIDropDownMenu_SetSelectedName(targetDropdown, targetOptions[1].text)
            UIDropDownMenu_SetSelectedValue(targetDropdown, targetOptions[1].value)
            selectedTarget = targetOptions[1].value
        end
    end

    UpdateTargetOptions()

    local executeButton = CreateFrame("Button", nil, batchDialog, "UIPanelButtonTemplate")
    executeButton:SetWidth(120)
    executeButton:SetHeight(25)
    executeButton:SetPoint("BOTTOMRIGHT", batchDialog, "BOTTOM", -6, 20)
    executeButton:SetText("Execute")
    executeButton:SetScript("OnClick", function()
        local affectedCount = 0

        if selectedOperation == "enable" then
            for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
                if not bind.enabled then
                    bind.enabled = true
                    affectedCount = affectedCount + 1
                end
            end
            KOL:PrintTag(GREEN("Enabled ") .. affectedCount .. " keybindings")

        elseif selectedOperation == "disable" then
            for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
                if bind.enabled then
                    bind.enabled = false
                    affectedCount = affectedCount + 1
                end
            end
            KOL:PrintTag(GREEN("Disabled ") .. affectedCount .. " keybindings")

        elseif selectedOperation == "enable_group" then
            for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
                if bind.group == selectedTarget and not bind.enabled then
                    bind.enabled = true
                    affectedCount = affectedCount + 1
                end
            end
            KOL:PrintTag(GREEN("Enabled ") .. affectedCount .. " keybindings in group: " .. selectedTarget)

        elseif selectedOperation == "disable_group" then
            for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
                if bind.group == selectedTarget and bind.enabled then
                    bind.enabled = false
                    affectedCount = affectedCount + 1
                end
            end
            KOL:PrintTag(GREEN("Disabled ") .. affectedCount .. " keybindings in group: " .. selectedTarget)

        elseif selectedOperation == "enable_type" then
            for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
                if bind.type == selectedTarget and not bind.enabled then
                    bind.enabled = true
                    affectedCount = affectedCount + 1
                end
            end
            KOL:PrintTag(GREEN("Enabled ") .. affectedCount .. " keybindings of type: " .. selectedTarget)

        elseif selectedOperation == "disable_type" then
            for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
                if bind.type == selectedTarget and bind.enabled then
                    bind.enabled = false
                    affectedCount = affectedCount + 1
                end
            end
            KOL:PrintTag(GREEN("Disabled ") .. affectedCount .. " keybindings of type: " .. selectedTarget)

        elseif selectedOperation == "unbind_all" then
            for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
                if bind.key and bind.key ~= "" then
                    self:RemoveKeybinding(bindId)
                    affectedCount = affectedCount + 1
                end
            end
            KOL:PrintTag(GREEN("Removed keys from ") .. affectedCount .. " keybindings")
        end

        LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
        batchDialog:Hide()
        batchDialog = nil
    end)

    local cancelButton = CreateFrame("Button", nil, batchDialog, "UIPanelButtonTemplate")
    cancelButton:SetWidth(120)
    cancelButton:SetHeight(25)
    cancelButton:SetPoint("BOTTOMLEFT", batchDialog, "BOTTOM", 6, 20)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        batchDialog:Hide()
        batchDialog = nil
    end)

    operationDropdown:SetScript("OnShow", function()
        UpdateTargetOptions()
    end)

    batchDialog:Show()
end

function Binds:ListKeybindings()
    KOL:PrintTag(PASTEL_YELLOW("Keybindings:"))

    local count = 0
    for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
        local status = bind.enabled and GREEN("✓") or RED("✗")
        local key = bind.key and bind.key ~= "" and GREEN(bind.key) or GRAY("[unbound]")
        local group = KOL.db.profile.binds.groups[bind.group]
        local groupColor = group and KOL.Colors and KOL.Colors[group.color] or WHITE
        local groupName = group and group.name or bind.group
        local requiresInput = self:BindRequiresInput(bind) and PASTEL_PINK("[input]") or ""

        KOL:Print(string.format("  %s %s%s - %s (%s%s|r)",
            status,
            PASTEL_YELLOW(bind.name),
            requiresInput,
            key,
            groupColor, groupName))

        count = count + 1
    end

    if count == 0 then
        KOL:Print(GRAY("  No keybindings configured"))
    end

    KOL:Print("Total: " .. PASTEL_YELLOW(tostring(count)) .. " keybindings")
end

function Binds:CreateKeybinding(bindId, data)
    if not bindId or not data then
        KOL:DebugPrint("Binds: CreateKeybinding - missing parameters", 0)
        return false
    end

    if not data.name or not data.type or not data.target then
        KOL:PrintTag(RED("Error:") .. " Keybinding missing required fields (name, type, target)")
        return false
    end

    local validTypes = {"internal", "synastria", "commandblock"}
    local isValidType = false
    for _, type in ipairs(validTypes) do
        if data.type == type then
            isValidType = true
            break
        end
    end

    if not isValidType then
        KOL:PrintTag(RED("Error:") .. " Invalid action type: " .. tostring(data.type))
        return false
    end

    KOL.db.profile.binds.keybindings[bindId] = {
        name = data.name,
        type = data.type,
        target = data.target,
        key = data.key or "",
        modifiers = data.modifiers or {},
        group = data.group or "general",
        enabled = data.enabled ~= false,
        order = data.order or 100,
        lastInput = data.lastInput or "",
    }

    KOL:PrintTag(GREEN("Created keybinding:") .. " " .. PASTEL_YELLOW(data.name))
    return true
end

function Binds:ExecuteKeybinding(bindId, input)
    if not KOL.db.profile.binds.enabled then
        return false
    end

    local bind = KOL.db.profile.binds.keybindings[bindId]
    if not bind then
        KOL:DebugPrint("ExecuteKeybinding: bind not found - " .. tostring(bindId))
        return false
    end

    if not bind.enabled then
        KOL:DebugPrint("ExecuteKeybinding: bind disabled - " .. bind.name)
        return false
    end

    local contextResult = self:ValidateContext(bind)
    if not contextResult.valid then
        if KOL.db.profile.binds.settings.showNotifications then
            KOL:PrintTag(RED("Context validation failed: ") .. bind.name .. " - " .. contextResult.reason)
        end
        return false
    end

    if not KOL.db.profile.binds.showInCombat and UnitAffectingCombat("player") then
        if KOL.db.profile.binds.settings.showNotifications then
            KOL:PrintTag(RED("Cannot use keybinding in combat: ") .. bind.name)
        end
        return false
    end

    if self:BindRequiresInput(bind) then
        if not input then
            self:ShowInputDialog(bindId, bind)
            return true
        end
    end

    local success = false
    local errorMsg = nil

    if bind.type == "internal" then
        success, errorMsg = self:ExecuteInternalAction(bind.target, input)
    elseif bind.type == "synastria" then
        success, errorMsg = self:ExecuteSynastriaAction(bind.target, input)
    elseif bind.type == "commandblock" then
        success, errorMsg = self:ExecuteCommandBlockAction(bind.target, input)
    else
        errorMsg = "Unknown action type: " .. tostring(bind.type)
    end

    if success then
        if KOL.db.profile.binds.settings.showNotifications then
            KOL:PrintTag(GREEN("Executed:") .. " " .. PASTEL_YELLOW(bind.name))
        end
        KOL:DebugPrint("Successfully executed: " .. bind.name .. " (" .. bind.type .. ":" .. bind.target .. ")")
    else
        if KOL.db.profile.binds.settings.showNotifications then
            local errorText = errorMsg or "Unknown error"
            KOL:PrintTag(RED("Failed to execute:") .. " " .. PASTEL_YELLOW(bind.name) .. " - " .. errorText)
        end
        KOL:DebugPrint("Failed to execute: " .. bind.name .. " (" .. bind.type .. ":" .. bind.target .. ") - " .. tostring(errorMsg))
    end

    return success
end

function Binds:ExecuteInternalAction(target, input)
    local internalActions = {
        ["interface_game"] = function()
            if InterfaceOptionsFrame_OpenToCategory then
                InterfaceOptionsFrame_OpenToCategory("Game")
                return true
            else
                return false, "InterfaceOptionsFrame_OpenToCategory not available"
            end
        end,
        ["interface_sound"] = function()
            if InterfaceOptionsFrame_OpenToCategory then
                InterfaceOptionsFrame_OpenToCategory("Sound")
                return true
            else
                return false, "InterfaceOptionsFrame_OpenToCategory not available"
            end
        end,
        ["interface_video"] = function()
            if InterfaceOptionsFrame_OpenToCategory then
                InterfaceOptionsFrame_OpenToCategory("Video")
                return true
            else
                return false, "InterfaceOptionsFrame_OpenToCategory not available"
            end
        end,
        ["interface_keyboard"] = function()
            if InterfaceOptionsFrame_OpenToCategory then
                InterfaceOptionsFrame_OpenToCategory("Keybindings")
                return true
            else
                return false, "InterfaceOptionsFrame_OpenToCategory not available"
            end
        end,
    }

    local action = internalActions[target]
    if action then
        local success, errorMsg = pcall(action)
        if success then
            return true
        else
            return false, errorMsg or "Internal action failed"
        end
    else
        return false, "Unknown internal action: " .. tostring(target)
    end
end

function Binds:ExecuteSynastriaAction(target, input)
    if not target or target == "" then
        return false, "Empty synastria command"
    end

    local command = "." .. target
    if input and input ~= "" then
        command = command .. " " .. input
    end

    local buttonName = "KOL_Binds_Synastria_" .. target:gsub("[^%w_]", "_")

    if not secureButtons[buttonName] then
        secureButtons[buttonName] = CreateFrame("Button", buttonName, UIParent, "SecureActionButtonTemplate")
        secureButtons[buttonName]:SetAttribute("type", "macro")
        secureButtons[buttonName]:Hide()
        secureButtons[buttonName]:SetSize(1, 1)
        secureButtons[buttonName]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -100, -100)
    end

    secureButtons[buttonName]:SetAttribute("macrotext", command)

    local success, errorMsg = pcall(function()
        secureButtons[buttonName]:Click()
    end)

    if success then
        return true
    else
        return false, "Failed to execute synastria command: " .. tostring(errorMsg)
    end
end

function Binds:ExecuteCommandBlockAction(target, input)
    if not target or target == "" then
        return false, "Empty command block name"
    end

    if KOL.CommandBlocks and KOL.CommandBlocks.Execute then
        local success, result = pcall(function()
            return KOL.CommandBlocks:Execute(target, input)
        end)

        if success then
            return result ~= nil, result
        else
            return false, "Command block execution failed: " .. tostring(result)
        end
    else
        return false, "CommandBlocks system not available"
    end
end

function Binds:GetKeybindingsByGroup(groupName)
    local bindings = {}

    for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
        if bind.group == groupName then
            bindings[bindId] = bind
        end
    end

    return bindings
end

function Binds:GetAllGroups()
    return KOL.db.profile.binds.groups
end

function Binds:DeleteKeybinding(bindId)
    if KOL.db.profile.binds.keybindings[bindId] then
        local name = KOL.db.profile.binds.keybindings[bindId].name
        KOL.db.profile.binds.keybindings[bindId] = nil
        KOL:PrintTag(RED("Deleted keybinding:") .. " " .. PASTEL_YELLOW(name))
        return true
    else
        KOL:PrintTag(RED("Keybinding not found:") .. " " .. tostring(bindId))
        return false
    end
end

function Binds:HandleSlashCommand(input)
    input = strtrim(input or "")
    local args = {}

    for word in string.gmatch(input, "%S+") do
        table.insert(args, word)
    end

    local cmd = args[1] and string.lower(args[1]) or ""

    if cmd == "" or cmd == "help" then
        self:OpenManager()
    elseif cmd == "add" then
        if #args < 4 then
            KOL:PrintTag(RED("Usage:") .. " /kbc add <name> <type> <target> [group]")
            KOL:Print("Types: internal, synastria, commandblock")
            KOL:Print("Example: /kbc add \"Open Game Settings\" internal interface_game general")
            return
        end

        local name = args[2]
        local actionType = args[3]
        local target = args[4]
        local group = args[5] or "general"

        local bindId = name:lower():gsub("%s+", "_"):gsub("[^%w_]", "")

        if self:CreateKeybinding(bindId, {
            name = name,
            type = actionType,
            target = target,
            group = group
        }) then
            KOL:PrintTag(GREEN("Created keybinding: ") .. PASTEL_YELLOW(name))
            KOL:Print("Use " .. YELLOW("/kbc bind " .. bindId) .. " to assign a key")
        end

    elseif cmd == "bind" then
        if #args < 2 then
            KOL:PrintTag(RED("Usage:") .. " /kbc bind <bindId>")
            KOL:Print("Use " .. YELLOW("/kbc list") .. " to see available bind IDs")
            return
        end

        local bindId = args[2]
        self:StartKeyCapture(bindId)

    elseif cmd == "unbind" then
        if #args < 2 then
            KOL:PrintTag(RED("Usage:") .. " /kbc unbind <bindId>")
            return
        end

        local bindId = args[2]
        self:RemoveKeybinding(bindId)

    elseif cmd == "delete" then
        if #args < 2 then
            KOL:PrintTag(RED("Usage:") .. " /kbc delete <bindId>")
            return
        end

        local bindId = args[2]
        if self:DeleteKeybinding(bindId) then
            self:RemoveKeybinding(bindId)
        end

    elseif cmd == "edit" then
        if #args < 2 then
            KOL:PrintTag(RED("Usage:") .. " /kbc edit <bindId>")
            return
        end

        local bindId = args[2]
        self:ShowKeybindingEditor(bindId)

    elseif cmd == "deletegroup" then
        if #args < 2 then
            KOL:PrintTag(RED("Usage:") .. " /kbc deletegroup <groupId>")
            return
        end

        local groupId = args[2]
        if KOL.db.profile.binds.groups[groupId] and not KOL.db.profile.binds.groups[groupId].isSystem then
            local groupName = KOL.db.profile.binds.groups[groupId].name
            KOL.db.profile.binds.groups[groupId] = nil
            KOL:PrintTag(GREEN("Deleted group: ") .. PASTEL_YELLOW(groupName))
            LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
        else
            KOL:PrintTag(RED("Cannot delete group: ") .. groupId)
        end

    elseif cmd == "batch" then
        self:ShowBatchDialog()

    else
        KOL:PrintTag(RED("Unknown command: ") .. cmd)
        KOL:Print("Use " .. YELLOW("/kbc") .. " for help")
    end
end

function Binds:OnEnable()
    KOL:DebugPrint("Binds: OnEnable called")

    self:ReapplyAllKeybindings()
end

function Binds:OnDisable()
    KOL:DebugPrint("Binds: OnDisable called")

    self:RemoveAllKeybindings()
end

function Binds:ReapplyAllKeybindings()
    if InCombatLockdown() then
        KOL:DebugPrint("Cannot reapply keybindings in combat")
        return
    end

    for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
        if bind.enabled and bind.key and bind.key ~= "" then
            self:ApplyKeybinding(bindId, bind.key)
        end
    end

    KOL:DebugPrint("Reapplied all keybindings")
end

function Binds:RemoveAllKeybindings()
    if InCombatLockdown() then
        KOL:DebugPrint("Cannot remove keybindings in combat")
        return
    end

    for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
        if bind.key and bind.key ~= "" then
            SetBinding(bind.key)
        end
    end

    KOL:DebugPrint("Removed all keybindings")
end

function Binds:ValidateContext(bind)
    if not bind or not bind.context then
        return {valid = true, reason = ""}
    end

    local contexts = {}
    if type(bind.context) == "string" then
        contexts[bind.context] = true
    elseif type(bind.context) == "table" then
        for _, ctx in ipairs(bind.context) do
            contexts[ctx] = true
        end
    end

    for context, _ in pairs(contexts) do
        local result = self:ValidateSingleContext(context)
        if not result.valid then
            return result
        end
    end

    return {valid = true, reason = ""}
end

function Binds:ValidateSingleContext(context)
    local zoneType = self:GetCurrentZoneType()
    local inInstance = IsInInstance()
    local instanceType = select(2, IsInInstance())

    if context == "any" then
        return {valid = true, reason = ""}

    elseif context == "city" then
        local isCity = self:IsMajorCity()
        if not isCity then
            return {valid = false, reason = "Must be in a major city"}
        end

    elseif context == "dungeon" then
        if not inInstance or instanceType ~= "scenario" and instanceType ~= "party" then
            return {valid = false, reason = "Must be in a 5-man dungeon"}
        end

    elseif context == "raid" then
        if not inInstance or instanceType ~= "raid" then
            return {valid = false, reason = "Must be in a raid instance"}
        end

    elseif context == "pvp" then
        if instanceType ~= "pvp" and instanceType ~= "arena" and not zoneType.isBattleground then
            return {valid = false, reason = "Must be in a PvP zone"}
        end

    elseif context == "outdoor" then
        if inInstance then
            return {valid = false, reason = "Must be outdoors"}
        end

    elseif context == "instance" then
        if not inInstance then
            return {valid = false, reason = "Must be in an instance"}
        end

    elseif context == "nomount" then
        if IsMounted() then
            return {valid = false, reason = "Cannot be used while mounted"}
        end

    elseif context == "noswimming" then
        if IsSwimming() then
            return {valid = false, reason = "Cannot be used while swimming"}
        end

    elseif context == "combat_only" then
        if not UnitAffectingCombat("player") then
            return {valid = false, reason = "Must be in combat"}
        end

    elseif context == "out_of_combat" then
        if UnitAffectingCombat("player") then
            return {valid = false, reason = "Must be out of combat"}
        end

    elseif context == "flying" then
        if not IsFlying() then
            return {valid = false, reason = "Must be flying"}
        end

    elseif context == "grounded" then
        if IsFlying() then
            return {valid = false, reason = "Cannot be used while flying"}
        end

    else
        return {valid = false, reason = "Unknown context: " .. tostring(context)}
    end

    return {valid = true, reason = ""}
end

function Binds:GetCurrentZoneType()
    local zoneName = GetRealZoneText()
    local subZoneName = GetSubZoneText()
    local inInstance = IsInInstance()
    local instanceType = select(2, IsInInstance())

    local isCity = self:IsMajorCity()

    local isBattleground = false
    for i = 1, GetNumBattlegrounds() do
        local bgName = GetBattlegroundInfo(i)
        if bgName and zoneName:find(bgName) then
            isBattleground = true
            break
        end
    end

    return {
        name = zoneName,
        subZone = subZoneName,
        inInstance = inInstance,
        instanceType = instanceType,
        isCity = isCity,
        isBattleground = isBattleground
    }
end

function Binds:IsMajorCity()
    local zoneName = GetRealZoneText()
    local subZoneName = GetSubZoneText()

    local majorCities = {
        ["Stormwind City"] = true,
        ["Stormwind"] = true,
        ["Ironforge"] = true,
        ["Darnassus"] = true,
        ["The Exodar"] = true,

        ["Orgrimmar"] = true,
        ["Undercity"] = true,
        ["Thunder Bluff"] = true,
        ["Silvermoon City"] = true,

        ["Shattrath City"] = true,
        ["Dalaran"] = true,

        ["Trade District"] = true,
        ["Valley of Strength"] = true,
        ["The Drag"] = true,
        ["Dwarven District"] = true,
        ["Valley of Spirits"] = true,
    }

    return majorCities[zoneName] == true or majorCities[subZoneName] == true
end

function Binds:GetContextOptions()
    return {
        {text = "Anywhere", value = "any"},
        {text = "Major Cities Only", value = "city"},
        {text = "5-Man Dungeons Only", value = "dungeon"},
        {text = "Raids Only", value = "raid"},
        {text = "PvP Zones Only", value = "pvp"},
        {text = "Outdoors Only", value = "outdoor"},
        {text = "Instances Only", value = "instance"},
        {text = "Not While Mounted", value = "nomount"},
        {text = "Not While Swimming", value = "noswimming"},
        {text = "Combat Only", value = "combat_only"},
        {text = "Out of Combat Only", value = "out_of_combat"},
        {text = "While Flying Only", value = "flying"},
        {text = "Grounded Only", value = "grounded"},
    }
end

function Binds:ShowEnhancedBatchDialog()
    if batchDialog then
        batchDialog:Hide()
    end

    batchDialog = CreateFrame("Frame", "KOL_BindsEnhancedBatchDialog", UIParent)
    batchDialog:SetFrameStrata("DIALOG")
    batchDialog:SetWidth(500)
    batchDialog:SetHeight(450)
    batchDialog:SetPoint("CENTER", UIParent, "CENTER")
    batchDialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11}
    })
    batchDialog:SetBackdropBorderColor(0.5, 0.5, 0.5)
    batchDialog:EnableMouse(true)
    batchDialog:SetMovable(true)
    batchDialog:RegisterForDrag("LeftButton")
    batchDialog:SetScript("OnDragStart", function() batchDialog:StartMoving() end)
    batchDialog:SetScript("OnDragStop", function() batchDialog:StopMovingOrSizing() end)

    local title = batchDialog:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", batchDialog, "TOP", 0, -16)
    title:SetText("Enhanced Batch Operations")

    local operationLabel = batchDialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    operationLabel:SetPoint("TOPLEFT", batchDialog, "TOPLEFT", 20, -60)
    operationLabel:SetText("Operation:")

    local operationDropdown = CreateFrame("Frame", nil, batchDialog, "UIDropDownMenuTemplate")
    operationDropdown:SetWidth(200)
    operationDropdown:SetPoint("TOPLEFT", operationLabel, "BOTTOMLEFT", 0, -5)

    local operationOptions = {
        {text = "Enable All", value = "enable"},
        {text = "Disable All", value = "disable"},
        {text = "Enable by Group", value = "enable_group"},
        {text = "Disable by Group", value = "disable_group"},
        {text = "Enable by Type", value = "enable_type"},
        {text = "Disable by Type", value = "disable_type"},
        {text = "Enable by Context", value = "enable_context"},
        {text = "Disable by Context", value = "disable_context"},
        {text = "Remove All Keys", value = "unbind_all"},
        {text = "Set Context for Group", value = "set_context_group"},
    }

    local selectedOperation = "enable"

    UIDropDownMenu_SetWidth(operationDropdown, 200)
    UIDropDownMenu_Initialize(operationDropdown, function()
        for _, option in ipairs(operationOptions) do
            local info = {
                text = option.text,
                value = option.value,
                checked = (option.value == selectedOperation),
                func = function()
                    selectedOperation = option.value
                    UIDropDownMenu_SetSelectedName(operationDropdown, option.text)
                    UIDropDownMenu_SetSelectedValue(operationDropdown, option.value)
                    UpdateTargetOptions()
                end
            }
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetSelectedName(operationDropdown, "Enable All")

    local targetLabel = batchDialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    targetLabel:SetPoint("TOPLEFT", operationDropdown, "BOTTOMLEFT", 0, -15)
    targetLabel:SetText("Target:")

    local targetDropdown = CreateFrame("Frame", nil, batchDialog, "UIDropDownMenuTemplate")
    targetDropdown:SetWidth(200)
    targetDropdown:SetPoint("TOPLEFT", targetLabel, "BOTTOMLEFT", 0, -5)

    local targetOptions = {}
    local selectedTarget = ""

    local function UpdateTargetOptions()
        targetOptions = {}

        if selectedOperation == "enable_group" or selectedOperation == "disable_group" or selectedOperation == "set_context_group" then
            for groupId, group in pairs(KOL.db.profile.binds.groups) do
                table.insert(targetOptions, {text = group.name, value = groupId})
            end
        elseif selectedOperation == "enable_type" or selectedOperation == "disable_type" then
            table.insert(targetOptions, {text = "Internal", value = "internal"})
            table.insert(targetOptions, {text = "Synastria", value = "synastria"})
            table.insert(targetOptions, {text = "Command Block", value = "commandblock"})
        elseif selectedOperation == "enable_context" or selectedOperation == "disable_context" then
            targetOptions = self:GetContextOptions()
        end

        UIDropDownMenu_Initialize(targetDropdown, function()
            for _, option in ipairs(targetOptions) do
                local info = {
                    text = option.text,
                    value = option.value,
                    checked = (option.value == selectedTarget),
                    func = function()
                        selectedTarget = option.value
                        UIDropDownMenu_SetSelectedName(targetDropdown, option.text)
                        UIDropDownMenu_SetSelectedValue(targetDropdown, option.value)
                    end
                }
                UIDropDownMenu_AddButton(info)
            end
        end)

        if #targetOptions > 0 then
            UIDropDownMenu_SetSelectedName(targetDropdown, targetOptions[1].text)
            UIDropDownMenu_SetSelectedValue(targetDropdown, targetOptions[1].value)
            selectedTarget = targetOptions[1].value
        end
    end

    UpdateTargetOptions()

    local previewLabel = batchDialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    previewLabel:SetPoint("TOPLEFT", targetDropdown, "BOTTOMLEFT", 0, -15)
    previewLabel:SetText("Preview:")

    local previewText = batchDialog:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    previewText:SetPoint("TOPLEFT", previewLabel, "BOTTOMLEFT", 0, -5)
    previewText:SetWidth(460)
    previewText:SetJustifyH("LEFT")
    previewText:SetText("Select an operation to preview affected keybindings")

    local function UpdatePreview()
        local affectedCount = 0
        local affectedNames = {}

        for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
            local willAffect = false

            if selectedOperation == "enable" then
                willAffect = not bind.enabled
            elseif selectedOperation == "disable" then
                willAffect = bind.enabled
            elseif selectedOperation == "enable_group" then
                willAffect = bind.group == selectedTarget and not bind.enabled
            elseif selectedOperation == "disable_group" then
                willAffect = bind.group == selectedTarget and bind.enabled
            elseif selectedOperation == "enable_type" then
                willAffect = bind.type == selectedTarget and not bind.enabled
            elseif selectedOperation == "disable_type" then
                willAffect = bind.type == selectedTarget and bind.enabled
            elseif selectedOperation == "enable_context" then
                willAffect = bind.context == selectedTarget and not bind.enabled
            elseif selectedOperation == "disable_context" then
                willAffect = bind.context == selectedTarget and bind.enabled
            end

            if willAffect then
                affectedCount = affectedCount + 1
                table.insert(affectedNames, bind.name)
                if affectedCount <= 5 then
                    if affectedCount == 1 then
                        previewText:SetText("Will affect: " .. PASTEL_YELLOW(bind.name))
                    else
                        previewText:SetText(previewText:GetText() .. ", " .. PASTEL_YELLOW(bind.name))
                    end
                end
            end
        end

        if affectedCount > 5 then
            previewText:SetText(previewText:GetText() .. " ... and " .. (affectedCount - 5) .. " more")
        elseif affectedCount == 0 then
            previewText:SetText("No keybindings will be affected")
        end
    end

    batchDialog:SetScript("OnShow", UpdatePreview)

    local executeButton = CreateFrame("Button", nil, batchDialog, "UIPanelButtonTemplate")
    executeButton:SetWidth(120)
    executeButton:SetHeight(25)
    executeButton:SetPoint("BOTTOMRIGHT", batchDialog, "BOTTOM", -6, 20)
    executeButton:SetText("Execute")
    executeButton:SetScript("OnClick", function()
        local affectedCount = 0

        if selectedOperation == "enable" then
            for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
                if not bind.enabled then
                    bind.enabled = true
                    affectedCount = affectedCount + 1
                end
            end
            KOL:PrintTag(GREEN("Enabled ") .. affectedCount .. " keybindings")

        elseif selectedOperation == "disable" then
            for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
                if bind.enabled then
                    bind.enabled = false
                    affectedCount = affectedCount + 1
                end
            end
            KOL:PrintTag(GREEN("Disabled ") .. affectedCount .. " keybindings")

        elseif selectedOperation == "enable_context" then
            for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
                if bind.context == selectedTarget and not bind.enabled then
                    bind.enabled = true
                    affectedCount = affectedCount + 1
                end
            end
            KOL:PrintTag(GREEN("Enabled ") .. affectedCount .. " keybindings with context: " .. selectedTarget)

        elseif selectedOperation == "disable_context" then
            for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
                if bind.context == selectedTarget and bind.enabled then
                    bind.enabled = false
                    affectedCount = affectedCount + 1
                end
            end
            KOL:PrintTag(GREEN("Disabled ") .. affectedCount .. " keybindings with context: " .. selectedTarget)

        elseif selectedOperation == "set_context_group" then
            for bindId, bind in pairs(KOL.db.profile.binds.keybindings) do
                if bind.group == selectedTarget then
                    bind.context = selectedTarget
                    affectedCount = affectedCount + 1
                end
            end
            KOL:PrintTag(GREEN("Set context for ") .. affectedCount .. " keybindings in group: " .. selectedTarget)

        else
        end

        LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
        batchDialog:Hide()
        batchDialog = nil
    end)

    local cancelButton = CreateFrame("Button", nil, batchDialog, "UIPanelButtonTemplate")
    cancelButton:SetWidth(120)
    cancelButton:SetHeight(25)
    cancelButton:SetPoint("BOTTOMLEFT", batchDialog, "BOTTOM", 6, 20)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        batchDialog:Hide()
        batchDialog = nil
    end)

    batchDialog:Show()
end

KOL.Binds = Binds
