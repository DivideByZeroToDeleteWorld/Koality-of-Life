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
    if not KOL.UIFactory then return end

    -- Create image button using UI-Factory
    local button = KOL.UIFactory:CreateImageButton(perkFrame, 32, 32, {
        normalTexture = Data.BUTTON_IMAGE_NORMAL,
        hoverTexture = Data.BUTTON_IMAGE_HOVER,
        pressedTexture = Data.BUTTON_IMAGE_PRESSED,
        onClick = function()
            BuildManager:ToggleMainFrame()
        end,
    })

    -- Position to the right of the help button
    local helpButton = _G["PerkMgrFrame-HelpButton"]
    if helpButton then
        -- Anchor LEFT to RIGHT with Y offset to position correctly
        button:SetPoint("LEFT", helpButton, "RIGHT", 5, -20)
    else
        -- Fallback position if help button not found
        button:SetPoint("TOPRIGHT", perkFrame, "TOPRIGHT", -70, -20)
    end

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

function BuildManager:StartQueue()
    if #actionQueue == 0 then return end

    queueProcessing = true
    queueDelay = 0
    queueFrame:Show()
    self:Print("Processing build import...")
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
    elseif action.type == "complete" then
        self:Print("Build import complete!")
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
    mainFrame:Show()
end

function BuildManager:CreateMainFrame()
    mainFrame = KOL.UIFactory:CreateStyledFrame(nil, "KOL_BuildManagerFrame", 520, 215, {
        closable = true,
        movable = true,
    })
    mainFrame:SetPoint("CENTER")
    mainFrame:Hide()

    -- Add title bar with close button
    local titleBar, title, closeButton = KOL.UIFactory:CreateTitleBar(mainFrame, 24, "Build Manager", {
        showCloseButton = true
    })

    -- Content area below title bar
    local content = CreateFrame("Frame", nil, mainFrame)
    content:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    content:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)
    mainFrame.content = content

    -- Left Panel: Import/Export
    local leftPanel = CreateFrame("Frame", nil, content)
    leftPanel:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    leftPanel:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 10, 50)
    leftPanel:SetWidth(230)

    local leftHeader = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftHeader:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 0, 0)
    leftHeader:SetText("IMPORT / EXPORT")
    leftHeader:SetTextColor(0.7, 0.7, 0.7)

    -- Multi-line edit box for build string
    local editBox = KOL.UIFactory:CreateMultiLineEditBox(leftPanel, 220, 120, {
        placeholder = "Paste build string here...",
    })
    editBox:SetPoint("TOPLEFT", leftHeader, "BOTTOMLEFT", 0, -10)
    mainFrame.editBox = editBox

    -- Import/Export buttons
    local buttonRow = CreateFrame("Frame", nil, leftPanel)
    buttonRow:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -10)
    buttonRow:SetSize(220, 25)

    local importBtn = KOL.UIFactory:CreateButton(buttonRow, "IMPORT", {
        type = "animated",
        onClick = function()
            local text = editBox:GetText()
            if text and text ~= "" then
                BuildManager:ImportFullBuild(text)
            else
                BuildManager:Print("Please paste a build string first")
            end
        end,
    })
    importBtn:SetPoint("LEFT", buttonRow, "LEFT", 40, 0)

    local exportBtn = KOL.UIFactory:CreateButton(buttonRow, "EXPORT", {
        type = "animated",
        onClick = function()
            local buildStr = BuildManager:ExportFullBuild()
            editBox:SetText(buildStr)
            editBox:HighlightText()
            editBox:SetFocus()
            BuildManager:Print("Build exported - copied to text box")
        end,
    })
    exportBtn:SetPoint("LEFT", importBtn, "RIGHT", 40, 0)

    -- Right Panel: Saved Builds
    local rightPanel = CreateFrame("Frame", nil, content)
    rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 20, 0)
    rightPanel:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 50)

    local rightHeader = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightHeader:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, 0)
    rightHeader:SetText("SAVED BUILDS")
    rightHeader:SetTextColor(0.7, 0.7, 0.7)

    -- Scrollable build list (same height as edit box: 120px)
    local listContainer = CreateFrame("Frame", nil, rightPanel)
    listContainer:SetPoint("TOPLEFT", rightHeader, "BOTTOMLEFT", 0, -10)
    listContainer:SetPoint("RIGHT", rightPanel, "RIGHT", 0, 0)
    listContainer:SetHeight(120)

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
    actionRow:SetPoint("TOPLEFT", listContainer, "BOTTOMLEFT", 0, -10)
    actionRow:SetSize(240, 25)

    local createBtn = KOL.UIFactory:CreateButton(actionRow, "CREATE", {
        type = "animated",
        onClick = function()
            BuildManager:ShowCreateFrame()
        end,
    })
    createBtn:SetPoint("LEFT", actionRow, "LEFT", 0, 0)

    local editBtn = KOL.UIFactory:CreateButton(actionRow, "EDIT", {
        type = "animated",
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
        type = "animated",
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
        type = "animated",
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
        strata = "TOOLTIP",
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
        strata = "TOOLTIP",
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
        strata = "TOOLTIP",
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
