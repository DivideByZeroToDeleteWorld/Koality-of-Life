-- ============================================================================
-- Warp Module - Quick teleport interface with world map
-- ============================================================================

local addonName = "!Koality-of-Life"
local KOL = KoalityOfLife

-- Module namespace
KOL.Warp = KOL.Warp or {}
local Warp = KOL.Warp

-- ============================================================================
-- Constants
-- ============================================================================

local FRAME_WIDTH = 900
local FRAME_HEIGHT = 600
local LEFT_PANEL_WIDTH = 250
local TAB_HEIGHT = 28
local WARP_BUTTON_HEIGHT = 24
local PADDING = 8

-- Expansion IDs
local EXPANSION_CLASSIC = 1
local EXPANSION_TBC = 2
local EXPANSION_WOTLK = 3

-- WotLK compatibility helper for SetColorTexture
local function SetColorTexture(texture, r, g, b, a)
    texture:SetTexture("Interface\\Buttons\\WHITE8X8")
    texture:SetVertexColor(r, g, b, a or 1)
end

-- Map textures for each expansion (continent maps)
local MAP_TEXTURES = {
    [EXPANSION_CLASSIC] = {
        -- Eastern Kingdoms and Kalimdor
        file = "Interface\\WorldMap\\WorldMap-small",
        coords = {0, 1, 0, 1},
    },
    [EXPANSION_TBC] = {
        file = "Interface\\WorldMap\\Outland\\Outland",
        coords = {0, 1, 0, 1},
    },
    [EXPANSION_WOTLK] = {
        file = "Interface\\WorldMap\\Northrend\\Northrend",
        coords = {0, 1, 0, 1},
    },
}

-- ============================================================================
-- Warp Data (placeholder - will be populated with actual warp commands)
-- ============================================================================

local WARP_DATA = {
    [EXPANSION_CLASSIC] = {
        { name = "Stormwind", command = ".warp Stormwind", x = 0.45, y = 0.65 },
        { name = "Ironforge", command = ".warp Ironforge", x = 0.52, y = 0.42 },
        { name = "Darnassus", command = ".warp Darnassus", x = 0.15, y = 0.18 },
        { name = "Orgrimmar", command = ".warp Orgrimmar", x = 0.32, y = 0.45 },
        { name = "Thunder Bluff", command = ".warp ThunderBluff", x = 0.22, y = 0.52 },
        { name = "Undercity", command = ".warp Undercity", x = 0.48, y = 0.32 },
        { name = "Blackrock Mountain", command = ".warp BRM", x = 0.55, y = 0.58 },
        { name = "Dire Maul", command = ".warp DireMaul", x = 0.18, y = 0.62 },
        { name = "Stratholme", command = ".warp Stratholme", x = 0.58, y = 0.22 },
        { name = "Scholomance", command = ".warp Scholomance", x = 0.52, y = 0.28 },
    },
    [EXPANSION_TBC] = {
        { name = "Shattrath City", command = ".warp Shattrath", x = 0.45, y = 0.55 },
        { name = "Hellfire Peninsula", command = ".warp HellfirePeninsula", x = 0.75, y = 0.50 },
        { name = "Zangarmarsh", command = ".warp Zangarmarsh", x = 0.55, y = 0.45 },
        { name = "Terokkar Forest", command = ".warp Terokkar", x = 0.50, y = 0.65 },
        { name = "Nagrand", command = ".warp Nagrand", x = 0.35, y = 0.55 },
        { name = "Blade's Edge", command = ".warp BladesEdge", x = 0.45, y = 0.25 },
        { name = "Netherstorm", command = ".warp Netherstorm", x = 0.65, y = 0.20 },
        { name = "Shadowmoon Valley", command = ".warp Shadowmoon", x = 0.65, y = 0.75 },
        { name = "Karazhan", command = ".warp Karazhan", x = 0.25, y = 0.80 },
        { name = "Black Temple", command = ".warp BlackTemple", x = 0.72, y = 0.72 },
    },
    [EXPANSION_WOTLK] = {
        { name = "Dalaran", command = ".warp Dalaran", x = 0.48, y = 0.38 },
        { name = "Borean Tundra", command = ".warp BoreanTundra", x = 0.25, y = 0.55 },
        { name = "Howling Fjord", command = ".warp HowlingFjord", x = 0.75, y = 0.65 },
        { name = "Dragonblight", command = ".warp Dragonblight", x = 0.45, y = 0.55 },
        { name = "Grizzly Hills", command = ".warp GrizzlyHills", x = 0.65, y = 0.55 },
        { name = "Zul'Drak", command = ".warp ZulDrak", x = 0.60, y = 0.35 },
        { name = "Sholazar Basin", command = ".warp Sholazar", x = 0.30, y = 0.35 },
        { name = "Storm Peaks", command = ".warp StormPeaks", x = 0.40, y = 0.22 },
        { name = "Icecrown", command = ".warp Icecrown", x = 0.55, y = 0.18 },
        { name = "Naxxramas", command = ".warp Naxxramas", x = 0.50, y = 0.50 },
        { name = "Ulduar", command = ".warp Ulduar", x = 0.35, y = 0.15 },
        { name = "ICC", command = ".warp ICC", x = 0.55, y = 0.12 },
    },
}

-- ============================================================================
-- Frame Creation
-- ============================================================================

local mainFrame = nil
local currentExpansion = EXPANSION_WOTLK

local function GetFont()
    local fontPath = "Fonts\\FRIZQT__.TTF"
    local fontOutline = "OUTLINE"

    if KOL.db and KOL.db.profile then
        local LSM = LibStub("LibSharedMedia-3.0", true)
        if LSM then
            local generalFont = KOL.db.profile.generalFont or "Friz Quadrata TT"
            fontPath = LSM:Fetch("font", generalFont) or fontPath
        end
        fontOutline = KOL.db.profile.generalFontOutline or fontOutline
    end

    return fontPath, fontOutline
end

local function ExecuteWarp(warpData)
    if warpData and warpData.command then
        -- Send the warp command
        SendChatMessage(warpData.command, "SAY")
        KOL:PrintTag("Warping to: |cFF00FF00" .. warpData.name .. "|r")
    end
end

local function CreateWarpButton(parent, warpData, index)
    local fontPath, fontOutline = GetFont()

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(LEFT_PANEL_WIDTH - 20, WARP_BUTTON_HEIGHT)
    btn:SetPoint("TOPLEFT", 10, -((index - 1) * (WARP_BUTTON_HEIGHT + 2)))

    -- Background
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    SetColorTexture(btn.bg,0.15, 0.15, 0.15, 0.8)

    -- Highlight
    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetAllPoints()
    SetColorTexture(btn.highlight,0.3, 0.5, 0.7, 0.3)

    -- Text
    btn.text = btn:CreateFontString(nil, "OVERLAY")
    btn.text:SetFont(fontPath, 11, fontOutline)
    btn.text:SetPoint("LEFT", 8, 0)
    btn.text:SetText(warpData.name)
    btn.text:SetTextColor(0.9, 0.9, 0.9, 1)

    -- Click handler
    btn:SetScript("OnClick", function()
        ExecuteWarp(warpData)
    end)

    -- Hover effects
    btn:SetScript("OnEnter", function(self)
        SetColorTexture(self.bg,0.2, 0.3, 0.4, 0.9)
        self.text:SetTextColor(1, 1, 1, 1)
    end)

    btn:SetScript("OnLeave", function(self)
        SetColorTexture(self.bg,0.15, 0.15, 0.15, 0.8)
        self.text:SetTextColor(0.9, 0.9, 0.9, 1)
    end)

    return btn
end

local function CreateMapWarpButton(parent, warpData, mapWidth, mapHeight)
    local fontPath, fontOutline = GetFont()

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(12, 12)

    -- Position on map based on x/y coordinates (0-1 range)
    local xPos = warpData.x * mapWidth
    local yPos = -warpData.y * mapHeight
    btn:SetPoint("CENTER", parent, "TOPLEFT", xPos, yPos)

    -- Dot indicator
    btn.dot = btn:CreateTexture(nil, "OVERLAY")
    btn.dot:SetSize(10, 10)
    btn.dot:SetPoint("CENTER")
    SetColorTexture(btn.dot,0, 0.8, 1, 1)

    -- Glow on hover
    btn.glow = btn:CreateTexture(nil, "BACKGROUND")
    btn.glow:SetSize(20, 20)
    btn.glow:SetPoint("CENTER")
    SetColorTexture(btn.glow,0, 0.6, 1, 0.5)
    btn.glow:Hide()

    -- Click handler
    btn:SetScript("OnClick", function()
        ExecuteWarp(warpData)
    end)

    -- Tooltip and hover
    btn:SetScript("OnEnter", function(self)
        self.glow:Show()
        SetColorTexture(self.dot,0, 1, 0.5, 1)

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(warpData.name, 1, 1, 1)
        GameTooltip:AddLine(warpData.command, 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Click to warp", 0, 1, 0)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function(self)
        self.glow:Hide()
        SetColorTexture(self.dot,0, 0.8, 1, 1)
        GameTooltip:Hide()
    end)

    return btn
end

local function PopulateWarpList(scrollChild, expansion)
    -- Clear existing buttons
    if scrollChild.warpButtons then
        for _, btn in ipairs(scrollChild.warpButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
    end
    scrollChild.warpButtons = {}

    -- Create new buttons
    local warps = WARP_DATA[expansion] or {}
    for i, warpData in ipairs(warps) do
        local btn = CreateWarpButton(scrollChild, warpData, i)
        table.insert(scrollChild.warpButtons, btn)
    end

    -- Update scroll child height
    local totalHeight = #warps * (WARP_BUTTON_HEIGHT + 2)
    scrollChild:SetHeight(math.max(totalHeight, 1))
end

local function PopulateMapButtons(mapFrame, expansion)
    -- Clear existing map buttons
    if mapFrame.warpButtons then
        for _, btn in ipairs(mapFrame.warpButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
    end
    mapFrame.warpButtons = {}

    -- Create new buttons on map
    local warps = WARP_DATA[expansion] or {}
    local mapWidth = mapFrame:GetWidth()
    local mapHeight = mapFrame:GetHeight()

    for _, warpData in ipairs(warps) do
        local btn = CreateMapWarpButton(mapFrame, warpData, mapWidth, mapHeight)
        table.insert(mapFrame.warpButtons, btn)
    end
end

local function UpdateMapTexture(mapTexture, expansion)
    local mapData = MAP_TEXTURES[expansion]
    if mapData then
        mapTexture:SetTexture(mapData.file)
        mapTexture:SetTexCoord(unpack(mapData.coords))
    end
end

local function SetExpansion(expansion)
    if not mainFrame then return end

    currentExpansion = expansion

    -- Update tab highlighting
    for i, tab in ipairs(mainFrame.expansionTabs) do
        if i == expansion then
            SetColorTexture(tab.bg,0.2, 0.4, 0.6, 1)
            tab.text:SetTextColor(1, 1, 1, 1)
        else
            SetColorTexture(tab.bg,0.1, 0.1, 0.1, 0.8)
            tab.text:SetTextColor(0.7, 0.7, 0.7, 1)
        end
    end

    -- Update warp list
    PopulateWarpList(mainFrame.scrollChild, expansion)

    -- Update map
    UpdateMapTexture(mainFrame.mapTexture, expansion)
    PopulateMapButtons(mainFrame.mapFrame, expansion)
end

local function CreateExpansionTab(parent, text, expansion, xOffset)
    local fontPath, fontOutline = GetFont()

    local tab = CreateFrame("Button", nil, parent)
    tab:SetSize(75, TAB_HEIGHT - 4)
    tab:SetPoint("TOPLEFT", xOffset, -2)

    -- Background
    tab.bg = tab:CreateTexture(nil, "BACKGROUND")
    tab.bg:SetAllPoints()
    SetColorTexture(tab.bg,0.1, 0.1, 0.1, 0.8)

    -- Text
    tab.text = tab:CreateFontString(nil, "OVERLAY")
    tab.text:SetFont(fontPath, 10, fontOutline)
    tab.text:SetPoint("CENTER")
    tab.text:SetText(text)
    tab.text:SetTextColor(0.7, 0.7, 0.7, 1)

    -- Click handler
    tab:SetScript("OnClick", function()
        SetExpansion(expansion)
    end)

    -- Hover
    tab:SetScript("OnEnter", function(self)
        if currentExpansion ~= expansion then
            SetColorTexture(self.bg,0.15, 0.25, 0.35, 1)
        end
    end)

    tab:SetScript("OnLeave", function(self)
        if currentExpansion ~= expansion then
            SetColorTexture(self.bg,0.1, 0.1, 0.1, 0.8)
        end
    end)

    return tab
end

function Warp:CreateMainFrame()
    if mainFrame then
        mainFrame:Show()
        return mainFrame
    end

    local UIFactory = KOL.UIFactory

    -- Main frame using UIFactory
    local f = UIFactory:CreateStyledFrame(UIParent, "KOL_WarpFrame", FRAME_WIDTH, FRAME_HEIGHT, {
        movable = true,
        closable = true,
        strata = "HIGH",
    })
    f:SetPoint("CENTER")
    f:SetClampedToScreen(true)

    -- Title bar using UIFactory
    local titleBar, titleText, closeBtn = UIFactory:CreateTitleBar(f, 28, "|cFF00FF00KOL|r Warp Portal", {
        bgColor = {r = 0.1, g = 0.3, b = 0.5, a = 0.9},
        fontSize = 14,
        showCloseButton = true,
    })

    -- =========================================================================
    -- LEFT PANEL - Warp List
    -- =========================================================================

    local leftPanel = UIFactory:CreateStyledFrame(f, nil, LEFT_PANEL_WIDTH, FRAME_HEIGHT - 50, {
        noRegister = true,
        bgColor = {r = 0.05, g = 0.05, b = 0.05, a = 0.9},
        borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1},
    })
    leftPanel:SetPoint("TOPLEFT", 10, -40)
    leftPanel:Show()

    -- Expansion Tabs
    local tabContainer = CreateFrame("Frame", nil, leftPanel)
    tabContainer:SetSize(LEFT_PANEL_WIDTH - 10, TAB_HEIGHT)
    tabContainer:SetPoint("TOPLEFT", 5, -5)

    f.expansionTabs = {}
    f.expansionTabs[EXPANSION_CLASSIC] = CreateExpansionTab(tabContainer, "Classic", EXPANSION_CLASSIC, 0)
    f.expansionTabs[EXPANSION_TBC] = CreateExpansionTab(tabContainer, "TBC", EXPANSION_TBC, 78)
    f.expansionTabs[EXPANSION_WOTLK] = CreateExpansionTab(tabContainer, "WotLK", EXPANSION_WOTLK, 156)

    -- Warp List Scroll Frame using UIFactory
    local scrollFrame, scrollChild = UIFactory:CreateScrollFrame(leftPanel, {
        top = TAB_HEIGHT + 10,
        bottom = 5,
        left = 5,
        right = 26,
    })

    f.scrollChild = scrollChild

    -- =========================================================================
    -- RIGHT PANEL - Map Display
    -- =========================================================================

    local rightPanel = UIFactory:CreateStyledFrame(f, nil, FRAME_WIDTH - LEFT_PANEL_WIDTH - 30, FRAME_HEIGHT - 50, {
        noRegister = true,
        bgColor = {r = 0.02, g = 0.02, b = 0.02, a = 0.95},
        borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1},
    })
    rightPanel:SetPoint("TOPRIGHT", -10, -40)
    rightPanel:Show()

    -- Map container (for positioning warp buttons)
    local mapFrame = CreateFrame("Frame", nil, rightPanel)
    mapFrame:SetPoint("TOPLEFT", 10, -10)
    mapFrame:SetPoint("BOTTOMRIGHT", -10, 10)

    -- Map texture
    local mapTexture = mapFrame:CreateTexture(nil, "ARTWORK")
    mapTexture:SetAllPoints()
    mapTexture:SetTexCoord(0, 1, 0, 1)

    f.mapFrame = mapFrame
    f.mapTexture = mapTexture

    -- =========================================================================
    -- Initialize
    -- =========================================================================

    mainFrame = f

    -- Set default expansion (WotLK)
    SetExpansion(EXPANSION_WOTLK)

    return f
end

function Warp:Toggle()
    if mainFrame and mainFrame:IsShown() then
        mainFrame:Hide()
    else
        self:CreateMainFrame()
        mainFrame:Show()
    end
end

function Warp:Show()
    self:CreateMainFrame()
    mainFrame:Show()
end

function Warp:Hide()
    if mainFrame then
        mainFrame:Hide()
    end
end

-- ============================================================================
-- Slash Command Registration
-- ============================================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" and KOL.RegisterSlashCommand then
        KOL:RegisterSlashCommand("warp", function()
            Warp:Toggle()
        end, "Open the Warp Portal interface", "utility")
    end
end)
