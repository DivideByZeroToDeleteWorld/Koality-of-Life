-- ============================================================================
-- !Koality-of-Life: Build Manager Module
-- ============================================================================
-- Manages saved builds for Synastria perks and talents
-- ============================================================================

local KOL = KoalityOfLife

--------------------------------------------------------------------------------
-- Module Setup
--------------------------------------------------------------------------------

KOL.BuildManager = {}
local BuildManager = KOL.BuildManager
local Data = KOL.BuildManagerData

--------------------------------------------------------------------------------
-- Local Variables
--------------------------------------------------------------------------------

local mainFrame = nil           -- Main Build Manager frame
local createFrame = nil         -- Create build popup
local deleteFrame = nil         -- Delete confirmation popup
local recoverFrame = nil        -- Recover deleted builds popup
local selectedBuildId = nil     -- Currently selected build ID
local buildListItems = {}       -- References to build list item frames

-- Action queue system
local actionQueue = {}          -- Queue of actions to process
local queueFrame = nil          -- Frame for OnUpdate processing
local queueDelay = 0            -- Current delay accumulator
local queueProcessing = false   -- Whether queue is being processed

-- Helper for 3.3.5 texture coloring (SetColorTexture doesn't exist)
local function SetTextureColor(texture, r, g, b, a)
    texture:SetTexture("Interface\\Buttons\\WHITE8X8")
    texture:SetVertexColor(r, g, b, a or 1)
end

--------------------------------------------------------------------------------
-- Default Builds Initialization
--------------------------------------------------------------------------------

function BuildManager:InitializeDefaultBuilds()
    local db = self:GetDB()
    if not db then return end

    if db.initialized then return end

    -- Copy default builds to saved builds
    for _, defaultBuild in ipairs(Data.DEFAULT_BUILDS) do
        if not db.builds[defaultBuild.id] then
            db.builds[defaultBuild.id] = {
                name = defaultBuild.name,
                class = defaultBuild.class,
                type = defaultBuild.type,
                deleted = false,
                buildString = defaultBuild.buildString,
                order = defaultBuild.order,
            }
        end
    end

    db.initialized = true
    self:Debug("Default builds initialized")
end

function BuildManager:GetDB()
    if KOL.db and KOL.db.profile then
        -- Ensure buildManager table exists
        if not KOL.db.profile.buildManager then
            KOL.db.profile.buildManager = {
                builds = {},
                lastSelected = nil,
                initialized = false,
            }
        end
        return KOL.db.profile.buildManager
    end
    return nil
end

--------------------------------------------------------------------------------
-- PerkMgrFrame Hook
--------------------------------------------------------------------------------

function BuildManager:HookPerkMgrFrame()
    -- Use OnUpdate to wait for PerkMgrFrame to exist
    local hookFrame = CreateFrame("Frame")
    local checkCount = 0

    hookFrame:SetScript("OnUpdate", function(self, elapsed)
        checkCount = checkCount + 1

        -- Check if PerkMgrFrame exists
        if _G["PerkMgrFrame"] then
            -- Only add button if UIFactory is available
            if KOL.UIFactory then
                BuildManager:AddButtonToPerkFrame()
            end
            self:SetScript("OnUpdate", nil)
            return
        end

        -- Stop checking after 600 attempts (about 10 seconds)
        if checkCount > 600 then
            self:SetScript("OnUpdate", nil)
        end
    end)
end

function BuildManager:AddButtonToPerkFrame()
    local perkFrame = _G["PerkMgrFrame"]
    if not perkFrame or perkFrame.kolBuildManagerButton then return end

    -- Create button with explicit high strata
    local button = CreateFrame("Button", "KOL_BuildManagerButton", perkFrame)
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(perkFrame:GetFrameLevel() + 10)
    button:SetSize(24, 24)
    button:EnableMouse(true)

    -- Create texture with explicit high draw layer
    local texture = button:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints(button)
    texture:SetTexture(Data.BUTTON_IMAGE)
    texture:Show()
    button.texture = texture

    -- Colors for states
    local normalColor = Data.BUTTON_COLOR_NORMAL
    local hoverColor = Data.BUTTON_COLOR_HOVER
    local pressedColor = Data.BUTTON_COLOR_PRESSED

    texture:SetVertexColor(normalColor.r, normalColor.g, normalColor.b)

    -- Hover effect
    button:SetScript("OnEnter", function(self)
        self.texture:SetVertexColor(hoverColor.r, hoverColor.g, hoverColor.b)
    end)

    button:SetScript("OnLeave", function(self)
        self.texture:SetVertexColor(normalColor.r, normalColor.g, normalColor.b)
    end)

    -- Pressed effect
    button:SetScript("OnMouseDown", function(self)
        self.texture:SetVertexColor(pressedColor.r, pressedColor.g, pressedColor.b)
    end)

    button:SetScript("OnMouseUp", function(self)
        if self:IsMouseOver() then
            self.texture:SetVertexColor(hoverColor.r, hoverColor.g, hoverColor.b)
        else
            self.texture:SetVertexColor(normalColor.r, normalColor.g, normalColor.b)
        end
    end)

    -- Click handler
    button:SetScript("OnClick", function()
        BuildManager:ToggleMainFrame()
    end)

    -- Position to the right of the help button
    local helpButton = _G["PerkMgrFrame-HelpButton"]
    if helpButton then
        button:SetPoint("LEFT", helpButton, "RIGHT", 5, -20)
    else
        button:SetPoint("TOPRIGHT", perkFrame, "TOPRIGHT", -70, -20)
    end

    button:Show()

    -- Store reference
    perkFrame.kolBuildManagerButton = button

    self:Debug("Build Manager button added to PerkMgrFrame")
end

--------------------------------------------------------------------------------
-- Action Queue System
--------------------------------------------------------------------------------

function BuildManager:CreateQueueFrame()
    if queueFrame then return end

    queueFrame = CreateFrame("Frame")
    queueFrame:Hide()

    queueFrame:SetScript("OnUpdate", function(self, elapsed)
        BuildManager:ProcessQueue(elapsed)
    end)
end

function BuildManager:QueueAction(actionType, data, delay)
    table.insert(actionQueue, {
        type = actionType,
        data = data,
        delay = delay or 0,
    })
end

function BuildManager:StartQueue(message)
    if #actionQueue == 0 then return end

    queueProcessing = true
    queueDelay = 0
    queueFrame:Show()
    self:Print(message or "Processing build import...")
end

function BuildManager:StopQueue()
    queueProcessing = false
    actionQueue = {}
    queueDelay = 0
    queueFrame:Hide()
end

function BuildManager:ProcessQueue(elapsed)
    if not queueProcessing or #actionQueue == 0 then
        self:StopQueue()
        return
    end

    local action = actionQueue[1]

    -- Handle delay
    if action.delay > 0 then
        queueDelay = queueDelay + elapsed
        if queueDelay < action.delay then
            return
        end
        queueDelay = 0
        action.delay = 0
    end

    -- Process action
    table.remove(actionQueue, 1)

    if action.type == "click_perk" then
        self:ExecuteClickPerk(action.data)
    elseif action.type == "click_toggle" then
        self:ExecuteClickToggle()
    elseif action.type == "change_perk_option" then
        self:ExecuteChangePerkOption(action.data)
    elseif action.type == "complete" then
        self:Print("Build import complete!")
        self:StopQueue()
    elseif action.type == "complete_misc" then
        local count = action.data and action.data.changeCount or 0
        local subOptionsCount = MISC_SUB_OPTIONS and #MISC_SUB_OPTIONS or 0
        self:Print("Misc Perks applied! " .. count .. " perk toggles changed, " .. subOptionsCount .. " sub-options set.")
        self:StopQueue()
    end
end

function BuildManager:ExecuteClickPerk(position)
    local perkLine = _G["PerkMgrFrame-PerkLine-" .. position]
    if perkLine and perkLine:IsVisible() then
        perkLine:Click()
    end
end

function BuildManager:ExecuteClickToggle()
    local toggleBtn = _G["PerkMgrFrame-Toggle"]
    if toggleBtn and toggleBtn:IsVisible() then
        toggleBtn:Click()
    end
end

function BuildManager:ExecuteChangePerkOption(data)
    if ChangePerkOption and data then
        ChangePerkOption(data.category, data.option, data.value, true)  -- silent = true
    end
end

--------------------------------------------------------------------------------
-- Perk System
--------------------------------------------------------------------------------

-- Expand all perk categories so all perks are visible
function BuildManager:ExpandAllCategories()
    -- Reset filter first
    local filterBtn = _G["PerkMgrFrame-FilterButton"]
    if filterBtn then
        filterBtn:Click()
        -- Click "All" option (first button in dropdown)
        local dropdownBtn = _G["DropDownList1Button1"]
        if dropdownBtn then
            dropdownBtn:Click()
        end
    end

    -- Expand each collapsed category
    for _, catName in ipairs(Data.PERK_CATEGORIES) do
        local catFrame = _G["PerkMgrFrame-Cat" .. catName]
        if catFrame and catFrame.isCollapsed then
            catFrame:Click()
        end
    end
end

-- Get all current perks and their states
function BuildManager:GetAllPerks()
    local perks = {}

    -- Get the content container
    local perkList = _G["PerkMgrFrame-Content1"]
    if not perkList then
        self:Print("Error: PerkMgrFrame not found")
        return perks
    end

    -- Expand all categories first
    self:ExpandAllCategories()

    -- Get all children of the perk list
    local children = {perkList:GetChildren()}

    -- Find the starting index by looking for PerkMgrFrame-PerkLine-1
    local startIndex = nil
    for i = 1, #children do
        local child = children[i]
        if child and child:GetName() == "PerkMgrFrame-PerkLine-1" then
            startIndex = i
            break
        end
    end

    if not startIndex then
        self:Debug("Could not find PerkMgrFrame-PerkLine-1")
        return perks
    end

    -- Iterate through all perk frames starting from the found index
    for i = startIndex, #children do
        local perkFrame = children[i]
        if perkFrame and perkFrame.perk and perkFrame.perk.id then
            local perkId = perkFrame.perk.id

            -- Stop if we hit the boundary perk ID
            if perkId == Data.PERK_BOUNDARY_ID then
                break
            end

            local isActive = GetPerkActive and GetPerkActive(perkId) or false
            table.insert(perks, {
                id = perkId,
                active = isActive,
                position = i - startIndex + 1,  -- 1-based position relative to first perk
            })
        else
            -- If we hit a frame without perk data, we've reached the end
            break
        end
    end

    return perks
end

-- Export current perks as comma-separated ID string
function BuildManager:ExportPerks()
    local perks = self:GetAllPerks()
    local activeIds = {}

    for _, perk in ipairs(perks) do
        if perk.active then
            table.insert(activeIds, perk.id)
        end
    end

    return table.concat(activeIds, ",")
end

-- Import perks from comma-separated ID string
function BuildManager:ImportPerks(perkString)
    if not perkString or perkString == "" then return 0 end

    -- Parse target perk IDs into lookup table
    local targetPerks = {}
    for idStr in string.gmatch(perkString, "(%d+)") do
        local id = tonumber(idStr)
        if id then
            targetPerks[id] = true
        end
    end

    -- Get current perk states
    local currentPerks = self:GetAllPerks()
    if #currentPerks == 0 then
        self:Print("Error: No perks found. Make sure PerkMgrFrame is open.")
        return 0
    end

    -- Build lists of changes needed
    local toDeactivate = {}  -- Currently active but shouldn't be
    local toActivate = {}    -- Currently inactive but should be

    for _, perk in ipairs(currentPerks) do
        local shouldBeActive = targetPerks[perk.id] or false

        if perk.active and not shouldBeActive then
            table.insert(toDeactivate, perk)
        elseif not perk.active and shouldBeActive then
            table.insert(toActivate, perk)
        end
    end

    -- Queue deactivations first (order matters)
    for _, perk in ipairs(toDeactivate) do
        self:QueueAction("click_perk", perk.position, Data.QUEUE_DELAY_CLICK)
        self:QueueAction("click_toggle", nil, Data.QUEUE_DELAY_TOGGLE)
    end

    -- Then queue activations
    for _, perk in ipairs(toActivate) do
        self:QueueAction("click_perk", perk.position, Data.QUEUE_DELAY_CLICK)
        self:QueueAction("click_toggle", nil, Data.QUEUE_DELAY_TOGGLE)
    end

    -- Queue completion
    self:QueueAction("complete", nil, 0)

    -- Start processing
    local totalChanges = #toDeactivate + #toActivate
    if totalChanges > 0 then
        self:StartQueue()
    end

    return totalChanges
end

--------------------------------------------------------------------------------
-- Misc Perks System
--------------------------------------------------------------------------------

-- Complete list of all known Misc perks and their sub-options
-- Structure: { name = "Perk Name", id = perkId, defaultOn = bool, subOptions = {...} }
-- defaultOn = the recommended default state (true = enabled by default)
-- User preferences are stored in KOL.db.global.buildManager.miscPerksDisabled
local MISC_PERKS_DATA = {
    {
        name = "Automatic Bank",
        id = 1042,
        defaultOn = true,
        subOptions = {
            { name = "Primary bank tab", defaultOn = true },
            { name = "First bank bag", defaultOn = true },
            { name = "Second bank bag", defaultOn = true },
            { name = "Third bank bag", defaultOn = true },
            { name = "Fourth bank bag", defaultOn = true },
            { name = "Fifth bank bag", defaultOn = true },
            { name = "Sixth bank bag", defaultOn = true },
            { name = "Seventh bank bag", defaultOn = true },
        },
    },
    {
        name = "Automatic Buffs",
        id = 1172,
        defaultOn = true,
        subOptions = {
            { name = "DK: Horn of Winter", defaultOn = true },
            { name = "Druid: Mark of the Wild", defaultOn = true },
            { name = "Druid: Thorns", defaultOn = true },
            { name = "Mage: Arcane Intellect", defaultOn = true },
            { name = "Paladin: Blessing of Kings", defaultOn = true },
            { name = "Paladin: Blessing of Might", defaultOn = false },
            { name = "Paladin: Blessing of Wisdom", defaultOn = false },
            { name = "Priest: Divine Spirit", defaultOn = true },
            { name = "Priest: Fortitude", defaultOn = true },
            { name = "Priest: Shadow Protection", defaultOn = true },
            { name = "Shaman: Water Breathing", defaultOn = true },
            { name = "Shaman: Water Walking", defaultOn = true },
            { name = "Warlock: Detect Invisibility", defaultOn = true },
            { name = "Warrior: Battle Shout", defaultOn = true },
            { name = "Warrior: Commanding Shout", defaultOn = false },
            { name = "Priest: Inner Fire", defaultOn = true },
            { name = "Priest: Vampiric Embrace", defaultOn = true },
        },
    },
    {
        name = "Automatic Fishing",
        id = 855,
        defaultOn = true,
    },
    {
        name = "Automatic Mount",
        id = 1277,
        defaultOn = true,
        subOptions = {
            { name = "Disabled", defaultOn = false },
            { name = "Randomize", defaultOn = true },
            { name = "Ignore Shapeshift", defaultOn = false },
        },
    },
    {
        name = "Automatic Next Melee",
        id = 996,
        defaultOn = true,
    },
    {
        name = "Balance:",  -- Class-specific, matches prefix
        id = nil,  -- ID varies by class
        defaultOn = true,
        isPrefix = true,
    },
    {
        name = "Disable Item Attune",
        id = 947,
        defaultOn = false,
    },
    {
        name = "Disable Item Refund",
        id = 1157,
        defaultOn = false,
    },
    {
        name = "Dungeon Event Speedup",
        id = 909,
        defaultOn = true,
    },
    {
        name = "Extra Racial Skill",
        id = 1141,
        defaultOn = true,
        -- Sub-options not configured - user sets manually
    },
    {
        name = "Instant Windrider",
        id = 806,
        defaultOn = true,
    },
    {
        name = "Less Annoying Buffs",
        id = 778,
        defaultOn = true,
    },
    {
        name = "Minimum Class Perk Level",
        id = 800,
        defaultOn = true,
    },
    {
        name = "Minimum Defensive Perk Level",
        id = 797,
        defaultOn = true,
    },
    {
        name = "Minimum Offensive Perk Level",
        id = 796,
        defaultOn = true,
    },
    {
        name = "Minimum Support Perk Level",
        id = 798,
        defaultOn = true,
    },
    {
        name = "Minimum Utility Perk Level",
        id = 799,
        defaultOn = true,
    },
    {
        name = "Misc Options",
        id = 1112,
        defaultOn = true,
        subOptions = {
            { name = "AH Attunable", defaultOn = true },
            { name = "Notify WG", defaultOn = true },
            { name = "AH Better Affix", defaultOn = true },
            { name = "Always Show Affix", defaultOn = true },
            { name = "Notify Leaderboard Update", defaultOn = true },
            { name = "Stop crafting if Forged", defaultOn = true },
            { name = "Notify on Forged", defaultOn = true },
            { name = "Disable Bulk Craft", defaultOn = false },
            { name = "Don't show attune bars", defaultOn = false },
            { name = "Don't allow destroy favorited", defaultOn = true },
            -- "Limit Damage" skipped - controlled by KoL Tweaks > Misc
            { name = "No pet display", defaultOn = false },
            { name = "Hide AH without buyout", defaultOn = true },
            { name = "AH hide attuned", defaultOn = true },
            { name = "Don't show bounty icon", defaultOn = false },
            { name = "Show account attune bar", defaultOn = true },
        },
    },
    {
        name = "Mythic Penalty",
        id = 1383,
        defaultOn = false,
    },
    {
        name = "No Exalted Lock",
        id = 1276,
        defaultOn = false,
    },
    {
        name = "Scan for Rare Enemy",
        id = 758,
        defaultOn = true,
    },
    {
        name = "Tracking",
        id = 759,
        defaultOn = true,
        subOptions = {
            { name = "Only in Northrend", defaultOn = false },
            { name = "Minerals", defaultOn = true },
            { name = "Herbs", defaultOn = true },
        },
    },
    {
        name = "Weapon Enchant Durations",
        id = 816,
        defaultOn = true,
    },
}

-- Config frame reference
local miscConfigFrame = nil

-- Helper: Check if a perk should be enabled based on user config
function BuildManager:ShouldPerkBeEnabled(perkName)
    -- Check user's disabled list (global)
    if KOL.db and KOL.db.global and KOL.db.global.buildManager then
        if KOL.db.global.buildManager.miscPerksDisabled[perkName] then
            return false  -- User explicitly disabled this
        end
    end
    -- Default to enabled (default-ON approach)
    return true
end

-- Helper: Check if a sub-option should be enabled based on user config
function BuildManager:ShouldSubOptionBeEnabled(perkName, optionName)
    local key = perkName .. ":" .. optionName
    -- Check user's disabled list (global)
    if KOL.db and KOL.db.global and KOL.db.global.buildManager then
        if KOL.db.global.buildManager.miscSubOptionsDisabled[key] then
            return false  -- User explicitly disabled this
        end
    end
    -- Find the default from MISC_PERKS_DATA
    for _, perk in ipairs(MISC_PERKS_DATA) do
        if perk.name == perkName and perk.subOptions then
            for _, opt in ipairs(perk.subOptions) do
                if opt.name == optionName then
                    return opt.defaultOn
                end
            end
        end
    end
    return true  -- Default to enabled
end

-- Toggle perk in user config
function BuildManager:ToggleMiscPerkConfig(perkName, enabled)
    if not KOL.db.global.buildManager then
        KOL.db.global.buildManager = { miscPerksDisabled = {}, miscSubOptionsDisabled = {} }
    end
    if enabled then
        KOL.db.global.buildManager.miscPerksDisabled[perkName] = nil
    else
        KOL.db.global.buildManager.miscPerksDisabled[perkName] = true
    end
end

-- Toggle sub-option in user config
function BuildManager:ToggleMiscSubOptionConfig(perkName, optionName, enabled)
    if not KOL.db.global.buildManager then
        KOL.db.global.buildManager = { miscPerksDisabled = {}, miscSubOptionsDisabled = {} }
    end
    local key = perkName .. ":" .. optionName
    if enabled then
        KOL.db.global.buildManager.miscSubOptionsDisabled[key] = nil
    else
        KOL.db.global.buildManager.miscSubOptionsDisabled[key] = true
    end
end

-- Export MISC PERKS config to a shareable string
function BuildManager:ExportMiscPerksConfig()
    if not KOL.db.global.buildManager then
        KOL.db.global.buildManager = { miscPerksDisabled = {}, miscSubOptionsDisabled = {} }
    end

    local perkParts = {}
    local subParts = {}

    -- Export ALL perks and subs using compact ID.index format
    for perkIdx, perkData in ipairs(MISC_PERKS_DATA) do
        local isEnabled = self:ShouldPerkBeEnabled(perkData.name)
        local state = isEnabled and 1 or 0

        -- Use ID if available, otherwise use index (pN)
        local perkKey = perkData.id and tostring(perkData.id) or ("p" .. perkIdx)
        table.insert(perkParts, perkKey .. "=" .. state)

        -- Export sub-options using perkId.subIndex=state format
        if perkData.subOptions then
            for subIdx, subOpt in ipairs(perkData.subOptions) do
                local subEnabled = self:ShouldSubOptionBeEnabled(perkData.name, subOpt.name)
                local subState = subEnabled and 1 or 0
                table.insert(subParts, perkKey .. "." .. subIdx .. "=" .. subState)
            end
        end
    end

    local perksStr = table.concat(perkParts, ",")
    local subsStr = table.concat(subParts, ",")

    -- Format: KMP:perks:subs
    return "KMP:" .. perksStr .. ":" .. subsStr
end

-- Import MISC PERKS config from a string
function BuildManager:ImportMiscPerksConfig(importStr)
    if not importStr or importStr == "" then
        return false, "Empty import string"
    end

    -- Check for our prefix (KMP: for new format)
    if not importStr:match("^KMP:") then
        return false, "Not a MISC PERKS config string"
    end

    -- Initialize if needed
    if not KOL.db.global.buildManager then
        KOL.db.global.buildManager = { miscPerksDisabled = {}, miscSubOptionsDisabled = {} }
    end

    -- Format: KMP:perkId=state,...:perkId.subIdx=state,...
    local perksStr, subsStr = importStr:match("^KMP:([^:]*):(.*)$")

    if not perksStr then
        return false, "Invalid MISC PERKS config format"
    end

    -- Clear existing config (start from defaults)
    KOL.db.global.buildManager.miscPerksDisabled = {}
    KOL.db.global.buildManager.miscSubOptionsDisabled = {}

    -- Build lookup tables
    local idToPerkData = {}
    local idxToPerkData = {}
    for idx, perkData in ipairs(MISC_PERKS_DATA) do
        if perkData.id then
            idToPerkData[tostring(perkData.id)] = perkData
        end
        idxToPerkData[idx] = perkData
    end

    -- Parse perks (id=state or pN=state where N is index)
    if perksStr and perksStr ~= "" then
        for entry in perksStr:gmatch("[^,]+") do
            local key, stateStr = entry:match("^(.+)=(%d)$")
            if key and stateStr then
                local state = tonumber(stateStr)
                local perkData

                -- Check if it's an index reference (pN) or ID
                local perkIdx = key:match("^p(%d+)$")
                if perkIdx then
                    perkData = idxToPerkData[tonumber(perkIdx)]
                else
                    perkData = idToPerkData[key]
                end

                if perkData then
                    -- State in export is the DESIRED state, not default
                    -- If desired state differs from default, mark in disabled table
                    local wantEnabled = (state == 1)
                    if wantEnabled ~= perkData.defaultOn then
                        KOL.db.global.buildManager.miscPerksDisabled[perkData.name] = true
                    end
                end
            end
        end
    end

    -- Parse sub-options (perkId.subIdx=state or pN.subIdx=state)
    if subsStr and subsStr ~= "" then
        for entry in subsStr:gmatch("[^,]+") do
            local perkKey, subIdxStr, stateStr = entry:match("^(.+)%.(%d+)=(%d)$")
            if perkKey and subIdxStr and stateStr then
                local subIdx = tonumber(subIdxStr)
                local state = tonumber(stateStr)
                local perkData

                -- Check if it's an index reference (pN) or ID
                local perkIdx = perkKey:match("^p(%d+)$")
                if perkIdx then
                    perkData = idxToPerkData[tonumber(perkIdx)]
                else
                    perkData = idToPerkData[perkKey]
                end

                if perkData and perkData.subOptions and perkData.subOptions[subIdx] then
                    local subOpt = perkData.subOptions[subIdx]
                    local key = perkData.name .. ":" .. subOpt.name

                    -- State in export is the DESIRED state
                    local wantEnabled = (state == 1)
                    if wantEnabled ~= subOpt.defaultOn then
                        KOL.db.global.buildManager.miscSubOptionsDisabled[key] = true
                    end
                end
            end
        end
    end

    return true, "MISC PERKS config imported successfully"
end

-- Show Misc Perks Config Frame
function BuildManager:ShowMiscPerksConfig()
    if not miscConfigFrame then
        self:CreateMiscPerksConfigFrame()
    end
    self:RefreshMiscPerksConfig()
    miscConfigFrame:Show()  -- OnShow auto-raises via UIFactory
end

-- Create the Misc Perks Config Frame
function BuildManager:CreateMiscPerksConfigFrame()
    miscConfigFrame = KOL.UIFactory:CreateStyledFrame(nil, "KOL_MiscPerksConfigFrame", 400, 450, {
        closable = true,
        movable = true,
        -- Auto-raise system handles strata/level when clicked
    })
    miscConfigFrame:SetPoint("CENTER", 0, 50)
    miscConfigFrame:Hide()

    -- Header using CreateSectionHeader (colored bar with thumb)
    local header = KOL.UIFactory:CreateSectionHeader(miscConfigFrame, "Configure Misc Perks", {r = 1, g = 0.8, b = 0.3}, 380)
    header:SetPoint("TOPLEFT", miscConfigFrame, "TOPLEFT", 10, -12)

    -- Info text
    local infoText = miscConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
    infoText:SetText("|cFF888888Checked = ENABLED when you click SET MISC PERKS|r")

    -- Scroll frame container
    local scrollContainer = CreateFrame("Frame", nil, miscConfigFrame)
    scrollContainer:SetPoint("TOPLEFT", miscConfigFrame, "TOPLEFT", 10, -55)
    scrollContainer:SetPoint("BOTTOMRIGHT", miscConfigFrame, "BOTTOMRIGHT", -10, 40)

    -- Create scrollable content using UIFactory (auto-skins scrollbar)
    -- Use slim 10px scrollbar without buttons for a clean look
    local scrollChild, scrollFrame = KOL.UIFactory:CreateScrollableContent(scrollContainer, {
        inset = {top = 0, bottom = 0, left = 0, right = 0},
        scrollbarWidth = 10,
        hideButtons = true,
    })
    scrollChild:SetWidth(358)  -- Full width now that scrollbar is inside and slim

    miscConfigFrame.scrollChild = scrollChild
    miscConfigFrame.checkboxes = {}

    -- Close button at bottom
    local closeBtn = KOL.UIFactory:CreateButton(miscConfigFrame, "CLOSE", {
        type = "text",
        onClick = function()
            miscConfigFrame:Hide()
        end,
    })
    closeBtn:SetPoint("BOTTOM", miscConfigFrame, "BOTTOM", 0, 10)
end

-- Refresh/populate the config frame
function BuildManager:RefreshMiscPerksConfig()
    local scrollChild = miscConfigFrame.scrollChild

    -- Clear existing checkboxes
    for _, cb in ipairs(miscConfigFrame.checkboxes) do
        cb:Hide()
        cb:SetParent(nil)
    end
    miscConfigFrame.checkboxes = {}

    local yOffset = -5
    local rowHeight = 20

    for _, perkData in ipairs(MISC_PERKS_DATA) do
        -- Skip prefix-based perks (like Balance:) in config for now
        if not perkData.isPrefix then
            -- Main perk checkbox
            local perkEnabled = self:ShouldPerkBeEnabled(perkData.name)

            local cb = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)
            cb:SetSize(24, 24)
            cb:SetChecked(perkEnabled)

            local label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", cb, "RIGHT", 5, 0)
            label:SetText("|cFFFFCC00" .. perkData.name .. "|r")

            cb:SetScript("OnClick", function(self)
                BuildManager:ToggleMiscPerkConfig(perkData.name, self:GetChecked())
            end)

            table.insert(miscConfigFrame.checkboxes, cb)
            yOffset = yOffset - rowHeight

            -- Sub-options (indented)
            if perkData.subOptions then
                for _, subOpt in ipairs(perkData.subOptions) do
                    local subEnabled = self:ShouldSubOptionBeEnabled(perkData.name, subOpt.name)

                    local subCb = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
                    subCb:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
                    subCb:SetSize(20, 20)
                    subCb:SetChecked(subEnabled)

                    local subLabel = subCb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    subLabel:SetPoint("LEFT", subCb, "RIGHT", 5, 0)
                    subLabel:SetText("|cFFCCCCCC" .. subOpt.name .. "|r")

                    subCb:SetScript("OnClick", function(self)
                        BuildManager:ToggleMiscSubOptionConfig(perkData.name, subOpt.name, self:GetChecked())
                    end)

                    table.insert(miscConfigFrame.checkboxes, subCb)
                    yOffset = yOffset - (rowHeight - 2)
                end
            end

            yOffset = yOffset - 5  -- Extra spacing between main perks
        end
    end

    -- Set scroll child height
    scrollChild:SetHeight(math.abs(yOffset) + 20)
end

-- Apply all Misc Perk settings with one click (default-ON approach)
-- Uses user's config from KOL.db.global.buildManager
function BuildManager:ApplyMiscPerks()
    -- Check if PerkMgrFrame exists
    if not _G["PerkMgrFrame"] then
        self:Print("Please open the Perk Manager first (press P or use /perks)")
        return
    end

    -- Expand all categories and show all perks
    local filterBtn = _G["PerkMgrFrame-FilterButton"]
    if filterBtn then
        filterBtn:Click()
        local dropdownBtn = _G["DropDownList1Button1"]
        if dropdownBtn then
            dropdownBtn:Click()
        end
    end

    local cats = {"Off", "Def", "Sup", "Uti", "Cla", "Clb", "Mis"}
    for _, cat in ipairs(cats) do
        local catFrame = _G["PerkMgrFrame-Cat" .. cat]
        if catFrame and catFrame.isCollapsed then
            catFrame:Click()
        end
    end

    -- Get perk list container
    local perkList = _G["PerkMgrFrame-Content1"]
    if not perkList then
        self:Print("Error: Could not find perk list")
        return
    end

    local children = {perkList:GetChildren()}

    -- Find starting index (PerkMgrFrame-PerkLine-1)
    local startIndex = nil
    for i = 1, #children do
        local child = children[i]
        if child and child:GetName() == "PerkMgrFrame-PerkLine-1" then
            startIndex = i
            break
        end
    end

    if not startIndex then
        self:Print("Error: Could not find perk lines")
        return
    end

    -- Build current state table from UI (scan ALL perks)
    local currentState = {}
    local balancePerkData = nil

    for i = startIndex, #children do
        local perkFrame = children[i]
        if perkFrame and perkFrame.perk and perkFrame.perk.id then
            local perkId = perkFrame.perk.id
            local perkName = perkFrame.perk.name or ""
            local isActive = GetPerkActive and GetPerkActive(perkId) or false
            local position = i - startIndex + 1

            currentState[perkId] = {
                name = perkName,
                active = isActive,
                position = position,
            }

            -- Check for Balance perk (class-specific, starts with "Balance:")
            if perkName:sub(1, 8) == "Balance:" then
                balancePerkData = {
                    id = perkId,
                    name = perkName,
                    active = isActive,
                    position = position,
                }
            end
        end
    end

    -- Build list of perks that need to change using user config
    local toChange = {}

    for _, perkData in ipairs(MISC_PERKS_DATA) do
        -- Skip prefix-based perks (handled separately)
        if not perkData.isPrefix and perkData.id then
            local desiredState = self:ShouldPerkBeEnabled(perkData.name)
            local current = currentState[perkData.id]
            if current and current.active ~= desiredState then
                table.insert(toChange, {
                    id = perkData.id,
                    name = current.name,
                    position = current.position,
                })
            end
        end
    end

    -- Check Balance perk (use user config or default ON)
    local balanceEnabled = self:ShouldPerkBeEnabled("Balance:")
    if balancePerkData and balancePerkData.active ~= balanceEnabled then
        table.insert(toChange, {
            id = balancePerkData.id,
            name = balancePerkData.name,
            position = balancePerkData.position,
        })
    end

    -- Clear any existing queue
    self:StopQueue()

    -- Queue the perk toggles
    for _, perk in ipairs(toChange) do
        self:QueueAction("click_perk", perk.position, 0.05)
        self:QueueAction("click_toggle", nil, 0.05)
    end

    -- Queue sub-option changes via ChangePerkOption (using user config)
    if ChangePerkOption then
        for _, perkData in ipairs(MISC_PERKS_DATA) do
            if perkData.subOptions then
                for _, subOpt in ipairs(perkData.subOptions) do
                    local value = self:ShouldSubOptionBeEnabled(perkData.name, subOpt.name)
                    self:QueueAction("change_perk_option", {
                        category = perkData.name,
                        option = subOpt.name,
                        value = value,
                    }, 0.02)
                end
            end
        end
    end

    -- Queue completion message
    self:QueueAction("complete_misc", {changeCount = #toChange}, 0)

    -- Start processing
    if #actionQueue > 0 then
        self:StartQueue("Setting Default State for MISC Perks...")
    else
        self:Print("Misc Perks already configured correctly!")
    end
end

--------------------------------------------------------------------------------
-- Talent System
--------------------------------------------------------------------------------

-- Check if player has dual-class (Synastria feature)
function BuildManager:IsDualClass()
    if not CustomGetClassMask then return false end

    local classMask = CustomGetClassMask()
    if not classMask or classMask == 0 then return false end

    -- Count set bits (popcount)
    local count = 0
    while classMask > 0 do
        count = count + (classMask % 2)
        classMask = math.floor(classMask / 2)
    end

    return count > 1
end

-- Get class name from talent button tooltip
function BuildManager:GetClassNameFromButton(buttonIndex)
    local button = _G["PlayerClassTalentBtn" .. buttonIndex]
    if not button then return nil end

    -- Trigger tooltip
    if button:GetScript("OnEnter") then
        button:GetScript("OnEnter")(button)
    end

    -- Read tooltip text
    local tooltipText = _G["GameTooltipTextLeft1"]
    if tooltipText then
        local className = tooltipText:GetText()
        GameTooltip:Hide()
        return className
    end

    return nil
end

-- Export talents for current class or both classes if dual-class
function BuildManager:ExportTalents()
    -- Ensure talent UI is loaded
    if TalentFrame_LoadUI then
        TalentFrame_LoadUI()
    end

    local isDual = self:IsDualClass()
    local talentStrings = {}

    if isDual then
        -- Export both classes
        for classIndex = 1, 2 do
            local classBtn = _G["PlayerClassTalentBtn" .. classIndex]
            if classBtn and classBtn:IsVisible() then
                classBtn:Click()
                local className = self:GetClassNameFromButton(classIndex)
                local talentStr = self:ExportCurrentTalents()
                if className and talentStr then
                    table.insert(talentStrings, className:upper() .. ":" .. talentStr)
                end
            end
        end
    else
        -- Single class export
        local _, className = UnitClass("player")
        local talentStr = self:ExportCurrentTalents()
        if talentStr then
            table.insert(talentStrings, className:upper() .. ":" .. talentStr)
        end
    end

    return table.concat(talentStrings, "\n")
end

-- Export talents for currently selected talent tree
function BuildManager:ExportCurrentTalents()
    local numTabs = GetNumTalentTabs()
    if numTabs == 0 then return nil end

    local tabStrings = {}

    for tab = 1, numTabs do
        local numTalents = GetNumTalents(tab)
        local rankString = ""

        for talent = 1, numTalents do
            local _, _, _, _, currentRank = GetTalentInfo(tab, talent)
            rankString = rankString .. (currentRank or 0)
        end

        -- Strip trailing zeros
        rankString = rankString:gsub("0+$", "")

        if rankString ~= "" then
            table.insert(tabStrings, tab .. ":" .. rankString)
        end
    end

    return table.concat(tabStrings, ",")
end

-- Import talents from string
function BuildManager:ImportTalents(talentString)
    if not talentString or talentString == "" then return false end

    -- Ensure talent UI is loaded
    if TalentFrame_LoadUI then
        TalentFrame_LoadUI()
    end

    local isDual = self:IsDualClass()
    local classesImported = 0

    -- Parse talent string (format: CLASSNAME:1:ranks,2:ranks)
    for line in talentString:gmatch("[^\n]+") do
        local className, talentData = line:match("^(%u+):(.+)$")
        if className and talentData then
            if isDual then
                -- Find and click the correct class button
                for classIndex = 1, 2 do
                    local btnClassName = self:GetClassNameFromButton(classIndex)
                    if btnClassName and btnClassName:upper() == className then
                        local classBtn = _G["PlayerClassTalentBtn" .. classIndex]
                        if classBtn then
                            classBtn:Click()
                        end
                        break
                    end
                end
            end

            -- Apply talents
            if self:ApplyTalentData(talentData) then
                classesImported = classesImported + 1
            end
        end
    end

    return classesImported > 0
end

-- Apply talent data to current talent tree
function BuildManager:ApplyTalentData(talentData)
    if not AddPreviewTalentPoints or not LearnPreviewTalents then
        self:Print("Error: Synastria talent APIs not found")
        return false
    end

    -- Clear all preview talents first
    local numTabs = GetNumTalentTabs()
    for tab = 1, numTabs do
        local numTalents = GetNumTalents(tab)
        for talent = 1, numTalents do
            AddPreviewTalentPoints(tab, talent, -5)  -- Clear (max 5 per talent)
        end
    end

    -- Parse and apply new talents
    for tabData in talentData:gmatch("(%d+:[%d]+)") do
        local tab, ranks = tabData:match("(%d+):(%d+)")
        tab = tonumber(tab)

        if tab and ranks then
            for talent = 1, #ranks do
                local points = tonumber(ranks:sub(talent, talent)) or 0
                if points > 0 then
                    AddPreviewTalentPoints(tab, talent, points)
                end
            end
        end
    end

    -- Commit the changes
    LearnPreviewTalents()

    return true
end

--------------------------------------------------------------------------------
-- Full Build Export/Import
--------------------------------------------------------------------------------

-- Export full build (perks + talents)
function BuildManager:ExportFullBuild()
    local perkString = self:ExportPerks()
    local talentString = self:ExportTalents()

    local result = ""
    if perkString and perkString ~= "" then
        result = perkString
    end
    if talentString and talentString ~= "" then
        if result ~= "" then
            result = result .. "\n"
        end
        result = result .. talentString
    end

    return result
end

-- Import full build (perks + talents)
function BuildManager:ImportFullBuild(buildString)
    if not buildString or buildString == "" then
        self:Print("Error: Empty build string")
        return false
    end

    -- Split into lines
    local lines = {}
    for line in buildString:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    -- First line with only numbers and commas is perks
    local perkString = nil
    local talentLines = {}

    for _, line in ipairs(lines) do
        if line:match("^[%d,]+$") then
            perkString = line
        elseif line:match("^%u+:") then
            table.insert(talentLines, line)
        end
    end

    -- Import perks
    local perkChanges = 0
    if perkString then
        perkChanges = self:ImportPerks(perkString)
    end

    -- Import talents
    local talentSuccess = false
    if #talentLines > 0 then
        talentSuccess = self:ImportTalents(table.concat(talentLines, "\n"))
    end

    if perkChanges > 0 or talentSuccess then
        if perkChanges > 0 then
            self:Print(string.format("Queued %d perk changes", perkChanges))
        end
        if talentSuccess then
            self:Print("Talents imported successfully")
        end
        return true
    end

    return false
end

--------------------------------------------------------------------------------
-- Build Storage
--------------------------------------------------------------------------------

function BuildManager:GetBuilds(includeDeleted)
    local db = self:GetDB()
    if not db then return {} end

    local builds = {}
    for id, build in pairs(db.builds) do
        if includeDeleted or not build.deleted then
            build.id = id
            table.insert(builds, build)
        end
    end

    -- Sort by order, then by name
    table.sort(builds, function(a, b)
        if a.order ~= b.order then
            return (a.order or 999) < (b.order or 999)
        end
        return (a.name or "") < (b.name or "")
    end)

    return builds
end

function BuildManager:GetDeletedBuilds()
    local db = self:GetDB()
    if not db then return {} end

    local builds = {}
    for id, build in pairs(db.builds) do
        -- Only return deleted custom builds (not defaults)
        if build.deleted and build.type == "C" then
            build.id = id
            table.insert(builds, build)
        end
    end

    return builds
end

function BuildManager:SaveBuild(name, class, buildString)
    local db = self:GetDB()
    if not db then return nil end

    -- Generate unique ID
    local id = "custom_" .. time()

    -- Find max order for custom builds
    local maxOrder = 100
    for _, build in pairs(db.builds) do
        if build.type == "C" and build.order and build.order >= maxOrder then
            maxOrder = build.order + 1
        end
    end

    db.builds[id] = {
        name = name,
        class = class,
        type = "C",  -- Custom
        deleted = false,
        buildString = buildString,
        order = maxOrder,
    }

    self:Debug("Saved build: " .. name .. " (" .. id .. ")")
    return id
end

function BuildManager:UpdateBuild(buildId, name, class, buildString)
    local db = self:GetDB()
    if not db or not db.builds[buildId] then return false end

    local build = db.builds[buildId]
    build.name = name
    build.class = class
    build.buildString = buildString

    self:Debug("Updated build: " .. name .. " (" .. buildId .. ")")
    return true
end

function BuildManager:DeleteBuild(id)
    local db = self:GetDB()
    if not db or not db.builds[id] then return false end

    -- Soft delete - just set the flag
    db.builds[id].deleted = true

    self:Debug("Deleted build: " .. id)
    return true
end

function BuildManager:RestoreBuild(id)
    local db = self:GetDB()
    if not db or not db.builds[id] then return false end

    db.builds[id].deleted = false

    self:Debug("Restored build: " .. id)
    return true
end

function BuildManager:PermanentDeleteBuild(id)
    local db = self:GetDB()
    if not db or not db.builds[id] then return false end

    local name = db.builds[id].name or id
    db.builds[id] = nil

    self:Debug("Permanently deleted build: " .. name)
    return true
end

function BuildManager:GetBuild(id)
    local db = self:GetDB()
    if not db then return nil end

    return db.builds[id]
end

--------------------------------------------------------------------------------
-- UI: Main Frame
--------------------------------------------------------------------------------

function BuildManager:ToggleMainFrame()
    if mainFrame and mainFrame:IsShown() then
        mainFrame:Hide()
    else
        self:ShowMainFrame()
    end
end

function BuildManager:ShowMainFrame()
    if not mainFrame then
        self:CreateMainFrame()
    end

    self:RefreshBuildList()
    mainFrame:Show()  -- OnShow auto-raises via UIFactory
end

function BuildManager:HideMainFrame()
    if mainFrame then
        mainFrame:Hide()
    end
end

function BuildManager:CreateMainFrame()
    mainFrame = KOL.UIFactory:CreateStyledFrame(nil, "KOL_BuildManagerFrame", 600, 230, {
        closable = true,
        movable = true,
    })
    mainFrame:SetPoint("CENTER")
    mainFrame:Hide()

    -- Content area (no title bar)
    local content = CreateFrame("Frame", nil, mainFrame)
    content:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)
    content:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)
    mainFrame.content = content

    -- Left Panel
    local leftPanel = CreateFrame("Frame", nil, content)
    leftPanel:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    leftPanel:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 10, 15)
    leftPanel:SetWidth(310)

    -- === MISC PERKS Section ===
    local miscPerksHeader = KOL.UIFactory:CreateSectionHeader(leftPanel, "MISC PERKS", {r = 1, g = 0.75, b = 0.3}, 300)
    miscPerksHeader:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 0, 0)

    -- MISC PERKS button row
    local miscButtonRow = CreateFrame("Frame", nil, leftPanel)
    miscButtonRow:SetPoint("TOPLEFT", miscPerksHeader, "BOTTOMLEFT", 0, -6)
    miscButtonRow:SetSize(300, 25)

    local setMiscBtn = KOL.UIFactory:CreateButton(miscButtonRow, "SET", {
        type = "text",
        onClick = function()
            BuildManager:ApplyMiscPerks()
        end,
    })
    setMiscBtn:SetPoint("LEFT", miscButtonRow, "LEFT", 5, 0)

    local configMiscBtn = KOL.UIFactory:CreateButton(miscButtonRow, "CONFIG", {
        type = "text",
        onClick = function()
            BuildManager:ShowMiscPerksConfig()
        end,
    })
    configMiscBtn:SetPoint("LEFT", setMiscBtn, "RIGHT", 10, 0)

    local exportMiscBtn = KOL.UIFactory:CreateButton(miscButtonRow, "EXPORT", {
        type = "text",
        onClick = function()
            local exportStr = BuildManager:ExportMiscPerksConfig()
            mainFrame.editBox:SetText(exportStr)
            mainFrame.editBox:HighlightText()
            mainFrame.editBox:SetFocus()
            BuildManager:Print("MISC PERKS config exported - copied to text box")
        end,
    })
    exportMiscBtn:SetPoint("LEFT", configMiscBtn, "RIGHT", 10, 0)

    -- === IMPORT/EXPORT Section ===
    local importExportHeader = KOL.UIFactory:CreateSectionHeader(leftPanel, "IMPORT / EXPORT", {r = 0.5, g = 0.8, b = 1}, 300)
    importExportHeader:SetPoint("TOPLEFT", miscButtonRow, "BOTTOMLEFT", 0, -10)

    -- Multi-line edit box for build string
    local editBox = KOL.UIFactory:CreateMultiLineEditBox(leftPanel, 300, 80, {
        placeholder = "Paste build string here...",
    })
    editBox:SetPoint("TOPLEFT", importExportHeader, "BOTTOMLEFT", 0, -6)
    mainFrame.editBox = editBox

    -- Import/Export button row
    local importExportRow = CreateFrame("Frame", nil, leftPanel)
    importExportRow:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -6)
    importExportRow:SetSize(300, 25)

    local importBtn = KOL.UIFactory:CreateButton(importExportRow, "IMPORT", {
        type = "text",
        onClick = function()
            local text = editBox:GetText()
            if not text or text == "" then
                BuildManager:Print("Please paste a build string first")
                return
            end

            -- Check for KMP string anywhere in the text (extract the KMP line)
            local kmpString = nil
            local remainingLines = {}

            for line in text:gmatch("[^\r\n]+") do
                if line:match("^KMP:") then
                    kmpString = line
                else
                    table.insert(remainingLines, line)
                end
            end

            local remainingText = table.concat(remainingLines, "\n")

            -- Check if remaining text looks like a Synastria build
            -- (has lines with only numbers/commas OR lines starting with UPPERCASE:)
            local hasSynBuild = false
            for _, line in ipairs(remainingLines) do
                if line:match("^[%d,]+$") or line:match("^%u+:") then
                    hasSynBuild = true
                    break
                end
            end

            -- Import based on what we found
            if hasSynBuild and kmpString then
                -- Both found - import Synastria first, then KMP after delay
                BuildManager:Print("Importing Synastria build + MISC PERKS config...")
                BuildManager:ImportFullBuild(remainingText)
                C_Timer.After(0.5, function()
                    local success, msg = BuildManager:ImportMiscPerksConfig(kmpString)
                    if success then
                        BuildManager:Print(msg)
                        if miscPerksFrame and miscPerksFrame:IsShown() then
                            BuildManager:RefreshMiscPerksConfig()
                        end
                    else
                        BuildManager:Print("|cFFFF0000KMP Import failed:|r " .. msg)
                    end
                end)
            elseif kmpString then
                -- Only KMP found
                local success, msg = BuildManager:ImportMiscPerksConfig(kmpString)
                if success then
                    BuildManager:Print(msg)
                    if miscPerksFrame and miscPerksFrame:IsShown() then
                        BuildManager:RefreshMiscPerksConfig()
                    end
                else
                    BuildManager:Print("|cFFFF0000Import failed:|r " .. msg)
                end
            elseif hasSynBuild then
                -- Only Synastria build found
                BuildManager:ImportFullBuild(text)
            else
                BuildManager:Print("|cFFFF6600Unrecognized import format|r")
            end
        end,
    })
    importBtn:SetPoint("LEFT", importExportRow, "LEFT", 5, 0)

    local exportBtn = KOL.UIFactory:CreateButton(importExportRow, "EXPORT", {
        type = "text",
        onClick = function()
            local buildStr = BuildManager:ExportFullBuild()
            editBox:SetText(buildStr)
            editBox:HighlightText()
            editBox:SetFocus()
            BuildManager:Print("Build exported - copied to text box")
        end,
    })
    exportBtn:SetPoint("LEFT", importBtn, "RIGHT", 10, 0)

    local closeBtn = KOL.UIFactory:CreateButton(importExportRow, "CLOSE", {
        type = "text",
        onClick = function()
            mainFrame:Hide()
        end,
    })
    closeBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)

    -- === Right Panel: Saved Builds ===
    local rightPanel = CreateFrame("Frame", nil, content)
    rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 20, 0)
    rightPanel:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 15)

    local savedHeader = KOL.UIFactory:CreateSectionHeader(rightPanel, "SAVED", {r = 0.6, g = 1, b = 0.6}, 240)
    savedHeader:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, 0)

    -- Scrollable build list (height calculated to align button rows)
    local listContainer = CreateFrame("Frame", nil, rightPanel)
    listContainer:SetPoint("TOPLEFT", savedHeader, "BOTTOMLEFT", 0, -6)
    listContainer:SetPoint("RIGHT", rightPanel, "RIGHT", 0, 0)
    listContainer:SetHeight(143)

    -- Create scroll frame (no template - custom scrollbar)
    local scrollFrame = CreateFrame("ScrollFrame", "KOL_BuildManagerScrollFrame", listContainer)
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -12, 0)

    local scrollChild = CreateFrame("Frame", "KOL_BuildManagerScrollChild", scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1)  -- Will be adjusted dynamically
    scrollFrame:SetScrollChild(scrollChild)

    -- Custom scrollbar
    local scrollBar = CreateFrame("Frame", nil, listContainer)
    scrollBar:SetWidth(8)
    scrollBar:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", 0, 0)
    scrollBar:SetPoint("BOTTOMRIGHT", listContainer, "BOTTOMRIGHT", 0, 0)
    scrollBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    scrollBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    -- Scrollbar thumb
    local scrollThumb = CreateFrame("Frame", nil, scrollBar)
    scrollThumb:SetWidth(6)
    scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, 0)
    scrollThumb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    scrollThumb:SetBackdropColor(0.4, 0.4, 0.4, 1)
    scrollThumb:EnableMouse(true)
    scrollThumb:SetHeight(30)

    -- Drag state
    local isDragging = false
    local dragStartY = 0
    local dragStartScroll = 0

    -- Update thumb position based on scroll
    local function UpdateThumbPosition()
        local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
        if maxScroll <= 0 then
            scrollThumb:Hide()
            return
        end
        scrollThumb:Show()

        local thumbHeight = math.max(20, (scrollFrame:GetHeight() / scrollChild:GetHeight()) * scrollBar:GetHeight())
        scrollThumb:SetHeight(thumbHeight)

        local thumbRange = scrollBar:GetHeight() - thumbHeight
        local currentScroll = scrollFrame:GetVerticalScroll()
        local thumbPos = (currentScroll / maxScroll) * thumbRange

        scrollThumb:ClearAllPoints()
        scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, -thumbPos)
    end

    -- Mouse wheel scrolling
    local function OnMouseWheel(self, delta)
        local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
        if maxScroll <= 0 then return end

        local current = scrollFrame:GetVerticalScroll()
        local new = current - (delta * 22)  -- 22 = item height
        new = math.max(0, math.min(new, maxScroll))
        scrollFrame:SetVerticalScroll(new)
        UpdateThumbPosition()
    end

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", OnMouseWheel)
    listContainer:EnableMouseWheel(true)
    listContainer:SetScript("OnMouseWheel", OnMouseWheel)

    -- Thumb drag handling
    scrollThumb:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDragging = true
            dragStartY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            dragStartScroll = scrollFrame:GetVerticalScroll()
        end
    end)

    scrollThumb:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            isDragging = false
        end
    end)

    scrollThumb:SetScript("OnUpdate", function(self)
        if not isDragging then return end

        if not IsMouseButtonDown("LeftButton") then
            isDragging = false
            return
        end

        local currentY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local deltaY = dragStartY - currentY

        local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
        if maxScroll <= 0 then return end

        local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
        if thumbRange <= 0 then return end

        local scrollPerPixel = maxScroll / thumbRange
        local newScroll = dragStartScroll + (deltaY * scrollPerPixel)
        newScroll = math.max(0, math.min(newScroll, maxScroll))

        scrollFrame:SetVerticalScroll(newScroll)
        UpdateThumbPosition()
    end)

    mainFrame.scrollChild = scrollChild
    mainFrame.scrollFrame = scrollFrame
    mainFrame.updateThumbPosition = UpdateThumbPosition

    -- Build list action buttons (below list container)
    local actionRow = CreateFrame("Frame", nil, rightPanel)
    actionRow:SetPoint("TOPLEFT", listContainer, "BOTTOMLEFT", 0, -6)
    actionRow:SetSize(240, 25)

    local createBtn = KOL.UIFactory:CreateButton(actionRow, "CREATE", {
        type = "text",
        onClick = function()
            BuildManager:ShowCreateFrame()
        end,
    })
    createBtn:SetPoint("LEFT", actionRow, "LEFT", 0, 0)

    local editBtn = KOL.UIFactory:CreateButton(actionRow, "EDIT", {
        type = "text",
        onClick = function()
            if selectedBuildId then
                BuildManager:ShowCreateFrame(selectedBuildId)
            else
                BuildManager:Print("Please select a build first")
            end
        end,
    })
    editBtn:SetPoint("LEFT", createBtn, "RIGHT", 20, 0)

    local deleteBtn = KOL.UIFactory:CreateButton(actionRow, "DELETE", {
        type = "text",
        onClick = function()
            if selectedBuildId then
                BuildManager:ShowDeleteFrame(selectedBuildId)
            else
                BuildManager:Print("Please select a build first")
            end
        end,
    })
    deleteBtn:SetPoint("LEFT", editBtn, "RIGHT", 20, 0)

    local restoreBtn = KOL.UIFactory:CreateButton(actionRow, "RESTORE", {
        type = "text",
        onClick = function()
            BuildManager:ShowRecoverFrame()
        end,
    })
    restoreBtn:SetPoint("LEFT", deleteBtn, "RIGHT", 15, 0)
end

function BuildManager:RefreshBuildList()
    if not mainFrame or not mainFrame.scrollChild then return end

    local scrollChild = mainFrame.scrollChild

    -- Clear existing items
    for _, item in ipairs(buildListItems) do
        item:Hide()
        item:SetParent(nil)
    end
    buildListItems = {}

    -- Get builds
    local builds = self:GetBuilds(false)  -- Don't include deleted

    -- Create list items
    local yOffset = 0
    local itemHeight = 22

    for _, build in ipairs(builds) do
        local item = self:CreateBuildListItem(scrollChild, build)
        item:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        item:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
        item:SetHeight(itemHeight)

        table.insert(buildListItems, item)
        yOffset = yOffset + itemHeight
    end

    -- Update scroll child height
    scrollChild:SetHeight(math.max(yOffset, 1))
end

function BuildManager:CreateBuildListItem(parent, build)
    local item = CreateFrame("Button", nil, parent)

    -- Background (for selection highlight)
    item.bg = item:CreateTexture(nil, "BACKGROUND")
    item.bg:SetAllPoints()
    SetTextureColor(item.bg, 1, 1, 1, 0.05)

    -- Class abbreviation with color
    local classAbbrev = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    classAbbrev:SetPoint("LEFT", item, "LEFT", 5, 0)
    classAbbrev:SetText(Data:GetColoredAbbrev(build.class))

    -- Build name
    local nameText = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", classAbbrev, "RIGHT", 5, 0)
    nameText:SetText(build.name)
    nameText:SetTextColor(0.9, 0.9, 0.9)

    -- Store build reference
    item.buildId = build.id
    item.build = build

    -- Hover effect
    item:SetScript("OnEnter", function(self)
        if selectedBuildId ~= self.buildId then
            SetTextureColor(self.bg, 1, 1, 1, 0.1)
        end
    end)

    item:SetScript("OnLeave", function(self)
        if selectedBuildId ~= self.buildId then
            SetTextureColor(self.bg, 1, 1, 1, 0.05)
        end
    end)

    -- Click to select
    item:SetScript("OnClick", function(self)
        BuildManager:SelectBuild(self.buildId)
    end)

    -- Double-click to load
    item:SetScript("OnDoubleClick", function(self)
        BuildManager:LoadBuildToEditBox(self.buildId)
    end)

    -- Update selection state
    if selectedBuildId == build.id then
        SetTextureColor(item.bg, 0.3, 0.5, 0.8, 0.3)
    end

    return item
end

function BuildManager:SelectBuild(buildId)
    selectedBuildId = buildId

    -- Update visual selection
    for _, item in ipairs(buildListItems) do
        if item.buildId == buildId then
            SetTextureColor(item.bg, 0.3, 0.5, 0.8, 0.3)
        else
            SetTextureColor(item.bg, 1, 1, 1, 0.05)
        end
    end

    -- Store last selected
    local db = self:GetDB()
    if db then
        db.lastSelected = buildId
    end

    -- Load build string to edit box
    self:LoadBuildToEditBox(buildId)
end

function BuildManager:LoadBuildToEditBox(buildId)
    local build = self:GetBuild(buildId)
    if not build or not mainFrame or not mainFrame.editBox then return end

    mainFrame.editBox:SetText(build.buildString or "")
    self:Print("Loaded build: " .. build.name)
end

--------------------------------------------------------------------------------
-- UI: Create Build Popup
--------------------------------------------------------------------------------

function BuildManager:ShowCreateFrame(editBuildId)
    if not createFrame then
        self:CreateCreateFrame()
    end

    -- Store edit mode state
    createFrame.editBuildId = editBuildId

    if editBuildId then
        -- Edit mode - pre-populate with existing build data
        local build = self:GetBuild(editBuildId)
        if build then
            createFrame.title:SetText("Edit Build")
            createFrame.nameEditBox:SetText(build.name or "")
            createFrame.stringEditBox:SetText(build.buildString or "")
            createFrame.selectedClass = build.class or "WARRIOR"
            createFrame.dropdown:SetValue(build.class or "WARRIOR")
        end
    else
        -- Create mode - reset fields
        createFrame.title:SetText("Create New Build")
        createFrame.nameEditBox:SetText("")
        createFrame.stringEditBox:SetText("")
        createFrame.selectedClass = "WARRIOR"
        createFrame.dropdown:SetValue("WARRIOR")
    end

    createFrame:Show()
end

function BuildManager:CreateCreateFrame()
    createFrame = KOL.UIFactory:CreateStyledFrame(UIParent, "KOL_BuildManagerCreateFrame", 320, 320, {
        closable = true,
        movable = true,
        -- Uses default DIALOG strata for proper z-ordering with other KOL frames
    })
    createFrame:SetPoint("CENTER")
    createFrame:Hide()

    -- Add title bar with close button
    local titleBar, title, closeButton = KOL.UIFactory:CreateTitleBar(createFrame, 24, "Create New Build", {
        showCloseButton = true
    })
    createFrame.title = title

    -- Content area below title bar
    local content = CreateFrame("Frame", nil, createFrame)
    content:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    content:SetPoint("BOTTOMRIGHT", createFrame, "BOTTOMRIGHT", 0, 0)
    createFrame.content = content

    -- Name label and edit box
    local nameLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -20)
    nameLabel:SetText("Name:")
    nameLabel:SetTextColor(0.7, 0.7, 0.7)

    local nameEditBox = KOL.UIFactory:CreateEditBox(content, 280, 28, {
        placeholder = "Enter build name...",
        maxLetters = 50,
    })
    nameEditBox:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -5)
    createFrame.nameEditBox = nameEditBox

    -- Class label and dropdown
    local classLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classLabel:SetPoint("TOPLEFT", nameEditBox, "BOTTOMLEFT", 0, -15)
    classLabel:SetText("Class:")
    classLabel:SetTextColor(0.7, 0.7, 0.7)

    -- Build dropdown items from class data (include dual-class combos)
    local dropdownItems = {}
    for _, classInfo in ipairs(Data:GetAllClasses()) do
        -- Build display label - for dual-class combos, show component classes
        local displayLabel = classInfo.name
        if classInfo.class1 and classInfo.class2 then
            -- Get the proper names from the class data
            local class1Info = Data:GetClassById(classInfo.class1)
            local class2Info = Data:GetClassById(classInfo.class2)
            if class1Info and class2Info then
                displayLabel = classInfo.name .. " (" .. class1Info.name .. " + " .. class2Info.name .. ")"
            end
        end
        table.insert(dropdownItems, {
            value = classInfo.id,
            label = displayLabel,
            color = classInfo.color,
        })
    end

    local dropdown = KOL.UIFactory:CreateScrollableDropdown(content, 280, {
        items = dropdownItems,
        selectedValue = "WARRIOR",
        fontSize = 9,  -- Smaller font to fit dual-class names
        onSelect = function(value)
            createFrame.selectedClass = value
        end,
    })
    dropdown:SetPoint("TOPLEFT", classLabel, "BOTTOMLEFT", 0, -5)
    createFrame.dropdown = dropdown
    createFrame.selectedClass = "WARRIOR"

    -- String label and edit box
    local stringLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stringLabel:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -15)
    stringLabel:SetText("Build String:")
    stringLabel:SetTextColor(0.7, 0.7, 0.7)

    local stringEditBox = KOL.UIFactory:CreateMultiLineEditBox(content, 280, 80, {
        placeholder = "Paste build string...",
    })
    stringEditBox:SetPoint("TOPLEFT", stringLabel, "BOTTOMLEFT", 0, -5)
    createFrame.stringEditBox = stringEditBox

    -- Save / Cancel buttons
    local buttonRow = CreateFrame("Frame", nil, content)
    buttonRow:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -20, 20)
    buttonRow:SetSize(200, 25)

    local cancelBtn = KOL.UIFactory:CreateButton(buttonRow, "CANCEL", {
        type = "animated",
        onClick = function()
            createFrame:Hide()
        end,
    })
    cancelBtn:SetPoint("RIGHT", buttonRow, "RIGHT", 0, 0)

    local saveBtn = KOL.UIFactory:CreateButton(buttonRow, "SAVE", {
        type = "animated",
        textColor = {r = 0.5, g = 0.9, b = 0.5, a = 1},
        onClick = function()
            local name = createFrame.nameEditBox:GetText()
            local class = createFrame.selectedClass
            local buildStr = createFrame.stringEditBox:GetText()

            if not name or name == "" then
                BuildManager:Print("Please enter a build name")
                return
            end

            if not buildStr or buildStr == "" then
                BuildManager:Print("Please enter a build string")
                return
            end

            if createFrame.editBuildId then
                -- Edit mode - update existing build
                BuildManager:UpdateBuild(createFrame.editBuildId, name, class, buildStr)
                BuildManager:Print("Build updated: " .. name)
            else
                -- Create mode - save new build
                BuildManager:SaveBuild(name, class, buildStr)
                BuildManager:Print("Build saved: " .. name)
            end

            createFrame:Hide()
            BuildManager:RefreshBuildList()
        end,
    })
    saveBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -30, 0)
end

--------------------------------------------------------------------------------
-- UI: Delete Confirmation Popup
--------------------------------------------------------------------------------

function BuildManager:ShowDeleteFrame(buildId)
    local build = self:GetBuild(buildId)
    if not build then return end

    if not deleteFrame then
        self:CreateDeleteFrame()
    end

    deleteFrame.buildId = buildId
    deleteFrame.buildNameText:SetText('"' .. build.name .. '"')
    deleteFrame.checkbox:SetChecked(false)
    deleteFrame.deleteBtn:Disable()

    deleteFrame:Show()
end

function BuildManager:CreateDeleteFrame()
    deleteFrame = KOL.UIFactory:CreateStyledFrame(UIParent, "KOL_BuildManagerDeleteFrame", 370, 90, {
        closable = true,
        movable = true,
        -- Uses default DIALOG strata for proper z-ordering with other KOL frames
    })
    deleteFrame:SetPoint("CENTER")
    deleteFrame:Hide()

    -- Warning text (no title bar)
    local warningText = deleteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    warningText:SetPoint("TOP", deleteFrame, "TOP", 0, -8)
    warningText:SetText("Are you sure you want to delete this build?")
    warningText:SetTextColor(0.9, 0.9, 0.9)

    -- Build name
    local buildNameText = deleteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buildNameText:SetPoint("TOP", warningText, "BOTTOM", 0, -5)
    buildNameText:SetText("")
    buildNameText:SetTextColor(1, 0.8, 0.3)
    deleteFrame.buildNameText = buildNameText

    -- Confirmation checkbox
    local checkbox = KOL.UIFactory:CreateCheckbox(deleteFrame, "I understand this action will hide the build", {
        checked = false,
        onChange = function(checked)
            if checked then
                deleteFrame.deleteBtn:Enable()
            else
                deleteFrame.deleteBtn:Disable()
            end
        end,
    })
    checkbox:SetPoint("TOP", buildNameText, "BOTTOM", 0, -8)
    deleteFrame.checkbox = checkbox

    -- Delete / Cancel buttons (aligned right)
    local cancelBtn = KOL.UIFactory:CreateButton(deleteFrame, "CANCEL", {
        type = "animated",
        onClick = function()
            deleteFrame:Hide()
        end,
    })
    cancelBtn:SetPoint("BOTTOMRIGHT", deleteFrame, "BOTTOMRIGHT", -15, 8)

    local deleteBtn = KOL.UIFactory:CreateButton(deleteFrame, "DELETE", {
        type = "animated",
        textColor = { r = 0.8, g = 0.3, b = 0.3, a = 1 },
        onClick = function()
            if deleteFrame.buildId then
                BuildManager:DeleteBuild(deleteFrame.buildId)
                BuildManager:Print("Build deleted")
                deleteFrame:Hide()

                -- Clear selection if deleted build was selected
                if selectedBuildId == deleteFrame.buildId then
                    selectedBuildId = nil
                end

                BuildManager:RefreshBuildList()
            end
        end,
    })
    deleteBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -20, 0)
    deleteBtn:Disable()
    deleteFrame.deleteBtn = deleteBtn
end

--------------------------------------------------------------------------------
-- UI: Recover Builds Popup
--------------------------------------------------------------------------------

function BuildManager:ShowRecoverFrame()
    if not recoverFrame then
        self:CreateRecoverFrame()
    end

    self:RefreshRecoverList()
    recoverFrame:Show()
end

function BuildManager:CreateRecoverFrame()
    recoverFrame = KOL.UIFactory:CreateStyledFrame(UIParent, "KOL_BuildManagerRecoverFrame", 320, 200, {
        closable = true,
        movable = true,
        -- Uses default DIALOG strata for proper z-ordering with other KOL frames
    })
    recoverFrame:SetPoint("CENTER")
    recoverFrame:Hide()

    -- Header text (no title bar)
    local header = recoverFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOP", recoverFrame, "TOP", 0, -12)
    header:SetText("RESTORE DELETED BUILDS")
    header:SetTextColor(0.7, 0.7, 0.7)

    -- Content area
    local content = CreateFrame("Frame", nil, recoverFrame)
    content:SetPoint("TOPLEFT", recoverFrame, "TOPLEFT", 0, -30)
    content:SetPoint("BOTTOMRIGHT", recoverFrame, "BOTTOMRIGHT", 0, 0)
    recoverFrame.content = content

    -- Scrollable list container
    local listContainer = CreateFrame("Frame", nil, content)
    listContainer:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -5)
    listContainer:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 45)

    -- Create scroll frame (no template - custom scrollbar)
    local scrollFrame = CreateFrame("ScrollFrame", "KOL_BuildManagerRecoverScrollFrame", listContainer)
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -12, 0)

    local scrollChild = CreateFrame("Frame", "KOL_BuildManagerRecoverScrollChild", scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    -- Custom scrollbar
    local scrollBar = CreateFrame("Frame", nil, listContainer)
    scrollBar:SetWidth(8)
    scrollBar:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", 0, 0)
    scrollBar:SetPoint("BOTTOMRIGHT", listContainer, "BOTTOMRIGHT", 0, 0)
    scrollBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    scrollBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    -- Scrollbar thumb
    local scrollThumb = CreateFrame("Frame", nil, scrollBar)
    scrollThumb:SetWidth(6)
    scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, 0)
    scrollThumb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    scrollThumb:SetBackdropColor(0.4, 0.4, 0.4, 1)
    scrollThumb:EnableMouse(true)
    scrollThumb:SetHeight(30)

    -- Drag state
    local isDragging = false
    local dragStartY = 0
    local dragStartScroll = 0

    -- Update thumb position
    local function UpdateThumbPosition()
        local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
        if maxScroll <= 0 then
            scrollThumb:Hide()
            return
        end
        scrollThumb:Show()

        local thumbHeight = math.max(20, (scrollFrame:GetHeight() / scrollChild:GetHeight()) * scrollBar:GetHeight())
        scrollThumb:SetHeight(thumbHeight)

        local thumbRange = scrollBar:GetHeight() - thumbHeight
        local currentScroll = scrollFrame:GetVerticalScroll()
        local thumbPos = (currentScroll / maxScroll) * thumbRange

        scrollThumb:ClearAllPoints()
        scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, -thumbPos)
    end

    -- Mouse wheel scrolling
    local function OnMouseWheel(self, delta)
        local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
        if maxScroll <= 0 then return end

        local current = scrollFrame:GetVerticalScroll()
        local new = current - (delta * 28)  -- 28 = item height
        new = math.max(0, math.min(new, maxScroll))
        scrollFrame:SetVerticalScroll(new)
        UpdateThumbPosition()
    end

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", OnMouseWheel)
    listContainer:EnableMouseWheel(true)
    listContainer:SetScript("OnMouseWheel", OnMouseWheel)

    -- Thumb drag handling
    scrollThumb:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDragging = true
            dragStartY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            dragStartScroll = scrollFrame:GetVerticalScroll()
        end
    end)

    scrollThumb:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            isDragging = false
        end
    end)

    scrollThumb:SetScript("OnUpdate", function(self)
        if not isDragging then return end

        if not IsMouseButtonDown("LeftButton") then
            isDragging = false
            return
        end

        local currentY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local deltaY = dragStartY - currentY

        local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
        if maxScroll <= 0 then return end

        local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
        if thumbRange <= 0 then return end

        local scrollPerPixel = maxScroll / thumbRange
        local newScroll = dragStartScroll + (deltaY * scrollPerPixel)
        newScroll = math.max(0, math.min(newScroll, maxScroll))

        scrollFrame:SetVerticalScroll(newScroll)
        UpdateThumbPosition()
    end)

    recoverFrame.scrollChild = scrollChild
    recoverFrame.recoverItems = {}

    -- Close button
    local closeBtn = KOL.UIFactory:CreateButton(content, "CLOSE", {
        type = "animated",
        onClick = function()
            recoverFrame:Hide()
        end,
    })
    closeBtn:SetPoint("BOTTOM", content, "BOTTOM", 0, 15)
end

function BuildManager:RefreshRecoverList()
    if not recoverFrame or not recoverFrame.scrollChild then return end

    local scrollChild = recoverFrame.scrollChild

    -- Clear existing items
    for _, item in ipairs(recoverFrame.recoverItems or {}) do
        item:Hide()
        -- Only call SetParent(nil) on frames, not on FontStrings
        if item.SetParent and item:GetObjectType() == "Frame" then
            item:SetParent(nil)
        end
    end
    recoverFrame.recoverItems = {}

    -- Get deleted builds
    local deletedBuilds = self:GetDeletedBuilds()

    if #deletedBuilds == 0 then
        local noBuildsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noBuildsText:SetPoint("CENTER", scrollChild, "CENTER", 0, 0)
        noBuildsText:SetText("No deleted builds to recover")
        noBuildsText:SetTextColor(0.5, 0.5, 0.5)
        table.insert(recoverFrame.recoverItems, noBuildsText)
        scrollChild:SetHeight(50)
        return
    end

    -- Create list items
    local yOffset = 0
    local itemHeight = 28

    for _, build in ipairs(deletedBuilds) do
        local item = CreateFrame("Frame", nil, scrollChild)
        item:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        item:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
        item:SetHeight(itemHeight)

        -- Class abbreviation with color
        local classAbbrev = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        classAbbrev:SetPoint("LEFT", item, "LEFT", 5, 0)
        classAbbrev:SetText(Data:GetColoredAbbrev(build.class))

        -- Build name
        local nameText = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", classAbbrev, "RIGHT", 5, 0)
        nameText:SetText(build.name)
        nameText:SetTextColor(0.7, 0.7, 0.7)

        -- Restore button (rightmost)
        local restoreBtn = KOL.UIFactory:CreateButton(item, "RESTORE", {
            type = "animated",
            onClick = function()
                BuildManager:RestoreBuild(build.id)
                BuildManager:Print("Build restored: " .. build.name)
                BuildManager:RefreshRecoverList()
                BuildManager:RefreshBuildList()
            end,
        })
        restoreBtn:SetPoint("RIGHT", item, "RIGHT", -5, 0)

        -- Delete button (left of restore)
        local deleteBtn = KOL.UIFactory:CreateButton(item, "DELETE", {
            type = "animated",
            textColor = { r = 0.6, g = 0.3, b = 0.3, a = 1 },
            onClick = function()
                BuildManager:PermanentDeleteBuild(build.id)
                BuildManager:Print("Build permanently deleted: " .. build.name)
                BuildManager:RefreshRecoverList()
            end,
        })
        deleteBtn:SetPoint("RIGHT", restoreBtn, "LEFT", -10, 0)

        table.insert(recoverFrame.recoverItems, item)
        yOffset = yOffset + itemHeight
    end

    scrollChild:SetHeight(math.max(yOffset, 1))
end

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------

function BuildManager:RegisterSlashCommands()
    -- Commands are registered through main.lua's /kol handler
end

-- Handle slash command
function BuildManager:HandleSlashCommand(args)
    local cmd = args and args:lower() or ""

    if cmd == "" or cmd == "toggle" then
        self:ToggleMainFrame()
    elseif cmd == "export" then
        local buildStr = self:ExportFullBuild()
        self:Print("Build exported:")
        print(buildStr)
    elseif cmd == "import" then
        self:ShowMainFrame()
        self:Print("Paste your build string in the Import/Export box")
    else
        self:Print("Usage: /kol bm [export|import]")
    end
end

--------------------------------------------------------------------------------
-- Debug Helper
--------------------------------------------------------------------------------

function BuildManager:Debug(msg)
    if KOL.DebugPrint then
        KOL:DebugPrint("BuildManager: " .. msg, 1)
    end
end

function BuildManager:Print(msg)
    print("|cFF00FF00[KOL Build Manager]|r " .. msg)
end

--------------------------------------------------------------------------------
-- Module Initialization
--------------------------------------------------------------------------------

function BuildManager:Initialize()
    -- Initialize default builds on first run
    self:InitializeDefaultBuilds()

    -- Set up PerkMgrFrame hook
    self:HookPerkMgrFrame()

    -- Create queue processing frame
    self:CreateQueueFrame()

    -- Register slash commands
    if KOL.RegisterSlashCommand then
        KOL:RegisterSlashCommand("bm", function(...)
            local args = {...}
            local subCmd = table.concat(args, " ")
            BuildManager:HandleSlashCommand(subCmd)
        end, "Build Manager - save/load perk and talent builds", "module")

        KOL:RegisterSlashCommand("buildmanager", function(...)
            local args = {...}
            local subCmd = table.concat(args, " ")
            BuildManager:HandleSlashCommand(subCmd)
        end, "Build Manager - save/load perk and talent builds", "module")
    end

    self:Debug("Build Manager initialized")
end

-- Initialize on PLAYER_ENTERING_WORLD
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Delay slightly to ensure DB is ready (C_Timer doesn't exist in 3.3.5)
        local delayFrame = CreateFrame("Frame")
        local elapsed = 0
        delayFrame:SetScript("OnUpdate", function(frame, delta)
            elapsed = elapsed + delta
            if elapsed >= 0.5 then
                frame:SetScript("OnUpdate", nil)
                BuildManager:Initialize()
            end
        end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

KOL:DebugPrint("BuildManager: Module loaded", 1)
