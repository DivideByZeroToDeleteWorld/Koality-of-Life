-- ============================================================================
-- LDB Module - LibDataBroker minimap icon with cascading menu system
-- ============================================================================

local addonName = "!Koality-of-Life"
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

if not LDB or not LDBIcon then
    return
end

-- ============================================================================
-- CRITICAL: Override GetMinimapShape to return "SQUARE" for ALL addons
-- This prevents LibDBIcon from using circular positioning on zone changes
-- ============================================================================
function GetMinimapShape()
    return "SQUARE"
end

-- Local references
local KOL = KoalityOfLife

-- Module namespace
KOL.LDB = KOL.LDB or {}
local LDBModule = KOL.LDB

-- ============================================================================
-- Constants
-- ============================================================================

local MENU_WIDTH = 200
local ITEM_HEIGHT = 20
local HEADER_HEIGHT = 24
local LABEL_HEIGHT = 18
local SEPARATOR_HEIGHT = 10
local PADDING = 6
local SUBMENU_OFFSET = 2

-- Colors
local COLORS = {
    LABEL = {r = 0.4, g = 0.8, b = 1},      -- Sky blue for labels
    FOLDER = {r = 1, g = 0.85, b = 0.4},     -- Gold for folders
    ITEM = {r = 0.85, g = 0.85, b = 0.85},   -- Light gray for items
    HOVER_BG = {r = 0.2, g = 0.2, b = 0.2},  -- Hover background
    SEPARATOR = {r = 0.4, g = 0.4, b = 0.4}, -- Separator line
    ARROW = {r = 0.6, g = 0.6, b = 0.6},     -- Arrow color
    VERSION = {r = 0.5, g = 0.5, b = 0.5},   -- Version text
}

-- ============================================================================
-- Rainbow Color System
-- ============================================================================

local rainbowHue = 0  -- Current hue (0-1)
local rainbowTimer = nil

-- Convert HSV to RGB (h, s, v are 0-1)
local function HSVtoRGB(h, s, v)
    if s == 0 then return v, v, v end
    h = h * 6
    local i = math.floor(h)
    local f = h - i
    local p = v * (1 - s)
    local q = v * (1 - s * f)
    local t = v * (1 - s * (1 - f))
    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v
    else return v, p, q end
end

-- Get current rainbow color as hex string
local function GetRainbowHex()
    local r, g, b = HSVtoRGB(rainbowHue, 1, 1)
    return string.format("%02X%02X%02X", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

-- Start/stop rainbow timer based on settings
function LDBModule:StartRainbowTimer()
    local profile = KOL.db and KOL.db.profile
    local needsTimer = profile and not profile.disableAllRainbow and (profile.ldbXPBarRainbow or profile.ldbREPBarRainbow)

    if needsTimer and not rainbowTimer then
        rainbowTimer = C_Timer.NewTicker(0.05, function()
            rainbowHue = rainbowHue + 0.0125  -- Smooth color cycling (~4 second full cycle at 20 FPS)
            if rainbowHue >= 1 then rainbowHue = 0 end
            if LDBModule.UpdateLDBText then
                LDBModule:UpdateLDBText()
            end
        end)
    elseif not needsTimer and rainbowTimer then
        rainbowTimer:Cancel()
        rainbowTimer = nil
    end
end

-- Icons - use directly available constants or literal characters
local function GetIcon(name)
    local icons = {
        ARROW_RIGHT = CHAR_ARROW_RIGHTFILLED or "▶",
        ARROW_LEFT = CHAR_ARROW_LEFTFILLED or "◄",
        FOLDER = "▸",      -- Small triangle right
        SETTINGS = "◆",    -- Filled diamond
        RELOAD = "↔",      -- Left-right arrow (back and forth/refresh)
        CLOSE = "×",       -- Multiplication sign (clean X)
    }
    return icons[name] or ""
end

-- ============================================================================
-- Tooltip Pool Management (memory leak prevention)
-- ============================================================================

local tooltipPool = {}
local activeTooltips = {}
local mainTooltip = nil
local clickCatcher = nil  -- Fullscreen frame to catch clicks outside menu

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

-- ============================================================================
-- Click Action Tooltip (shows available click actions on hover)
-- ============================================================================

local clickActionTooltip = nil

-- Standing names for reputation display
local STANDING_NAMES = {
    [1] = "Hated",
    [2] = "Hostile",
    [3] = "Unfriendly",
    [4] = "Neutral",
    [5] = "Friendly",
    [6] = "Honored",
    [7] = "Revered",
    [8] = "Exalted",
}

-- Standing colors (matching WoW's reputation colors)
local STANDING_COLORS = {
    [1] = {0.80, 0.13, 0.13},  -- Hated - Dark Red
    [2] = {1.00, 0.25, 0.25},  -- Hostile - Red
    [3] = {0.93, 0.60, 0.20},  -- Unfriendly - Orange
    [4] = {1.00, 1.00, 0.00},  -- Neutral - Yellow
    [5] = {0.00, 1.00, 0.00},  -- Friendly - Green
    [6] = {0.00, 0.80, 0.80},  -- Honored - Teal
    [7] = {0.00, 0.50, 1.00},  -- Revered - Blue
    [8] = {0.58, 0.00, 0.83},  -- Exalted - Purple
}

local function ShowClickActionTooltip(anchor)
    if not clickActionTooltip then
        clickActionTooltip = CreateFrame("Frame", "KOLClickActionTooltip", UIParent)
        clickActionTooltip:SetFrameStrata("TOOLTIP")
        clickActionTooltip:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        clickActionTooltip:SetBackdropColor(0.06, 0.06, 0.09, 0.97)
        clickActionTooltip:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    end

    local fontPath, fontOutline = GetFont()
    local lineHeight = 15
    local padding = 10
    local gapWidth = 16
    local separatorHeight = 12
    local headerHeight = 20
    local sectionSpacing = 4

    -- Clear old elements
    if clickActionTooltip.lines then
        for _, line in ipairs(clickActionTooltip.lines) do
            line:Hide()
            line:SetText("")
        end
    else
        clickActionTooltip.lines = {}
    end

    if clickActionTooltip.separators then
        for _, sep in ipairs(clickActionTooltip.separators) do
            sep:Hide()
        end
    else
        clickActionTooltip.separators = {}
    end

    if clickActionTooltip.headerBgs then
        for _, bg in ipairs(clickActionTooltip.headerBgs) do
            bg:Hide()
        end
    else
        clickActionTooltip.headerBgs = {}
    end

    if clickActionTooltip.headerAccents then
        for _, accent in ipairs(clickActionTooltip.headerAccents) do
            accent:Hide()
        end
    else
        clickActionTooltip.headerAccents = {}
    end

    if clickActionTooltip.headerFades then
        for _, fade in ipairs(clickActionTooltip.headerFades) do
            fade:Hide()
        end
    else
        clickActionTooltip.headerFades = {}
    end

    -- Track font strings, separators, and header elements
    local lineIndex = 0
    local separatorIndex = 0
    local headerBgIndex = 0
    local headerAccentIndex = 0
    local headerFadeIndex = 0

    -- Helper to get or create a font string
    local function GetLine()
        lineIndex = lineIndex + 1
        local line = clickActionTooltip.lines[lineIndex]
        if not line then
            line = clickActionTooltip:CreateFontString(nil, "OVERLAY")
            clickActionTooltip.lines[lineIndex] = line
        end
        line:ClearAllPoints()
        line:Show()
        return line
    end

    -- Helper to get or create a separator texture
    local function GetSeparator()
        separatorIndex = separatorIndex + 1
        local sep = clickActionTooltip.separators[separatorIndex]
        if not sep then
            sep = clickActionTooltip:CreateTexture(nil, "ARTWORK")
            clickActionTooltip.separators[separatorIndex] = sep
        end
        sep:ClearAllPoints()
        sep:Show()
        return sep
    end

    -- Helper to get or create a header background texture
    local function GetHeaderBg()
        headerBgIndex = headerBgIndex + 1
        local bg = clickActionTooltip.headerBgs[headerBgIndex]
        if not bg then
            bg = clickActionTooltip:CreateTexture(nil, "BORDER")
            clickActionTooltip.headerBgs[headerBgIndex] = bg
        end
        bg:ClearAllPoints()
        bg:Show()
        return bg
    end

    -- Helper to get or create a header accent texture
    local function GetHeaderAccent()
        headerAccentIndex = headerAccentIndex + 1
        local accent = clickActionTooltip.headerAccents[headerAccentIndex]
        if not accent then
            accent = clickActionTooltip:CreateTexture(nil, "ARTWORK")
            clickActionTooltip.headerAccents[headerAccentIndex] = accent
        end
        accent:ClearAllPoints()
        accent:Show()
        return accent
    end

    -- Helper to get or create a header fade texture (for right-edge gradient)
    local function GetHeaderFade()
        headerFadeIndex = headerFadeIndex + 1
        local fade = clickActionTooltip.headerFades[headerFadeIndex]
        if not fade then
            fade = clickActionTooltip:CreateTexture(nil, "BORDER")
            clickActionTooltip.headerFades[headerFadeIndex] = fade
        end
        fade:ClearAllPoints()
        fade:Show()
        return fade
    end

    -- Track measurements
    local maxLeftWidth = 0
    local maxRightWidth = 0
    local yOffset = -padding
    local rows = {}
    local hasContent = false  -- Track if we have XP or REP content

    -- Shortcut column widths (tracked separately)
    local shortcutModifierWidth = 0
    local shortcutPlusWidth = 0
    local shortcutMouseWidth = 0
    local shortcutActionWidth = 0

    -- ═══════════════════════════════════════════════════════════════════════
    -- EXPERIENCE SECTION (shown first if enabled, hidden at max level)
    -- ═══════════════════════════════════════════════════════════════════════
    local playerLevel = UnitLevel("player")
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 80
    local isMaxLevel = playerLevel >= maxLevel
    local showXP = KOL.db.profile.ldbShowXP and not isMaxLevel
    if showXP then
        hasContent = true

        -- Add XP header with styled background
        local xpHeader = GetLine()
        xpHeader:SetFont(fontPath, 11, fontOutline)
        xpHeader:SetText("EXPERIENCE")
        xpHeader:SetTextColor(0.4, 0.75, 1.0, 1)
        table.insert(rows, {type = "sectionHeader", line = xpHeader, y = yOffset, color = {0.2, 0.5, 0.8}})
        yOffset = yOffset - headerHeight

        -- Get XP data
        local level = UnitLevel("player")
        local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 80
        local currentXP = UnitXP("player")
        local maxXP = UnitXPMax("player")
        local restedXP = GetXPExhaustion() or 0
        local xpPercent = maxXP > 0 and (currentXP / maxXP * 100) or 0

        -- Level row
        local levelLabel = GetLine()
        levelLabel:SetFont(fontPath, 10, fontOutline)
        levelLabel:SetText("Level")
        levelLabel:SetTextColor(0.6, 0.6, 0.6, 1)

        local levelValue = GetLine()
        levelValue:SetFont(fontPath, 10, fontOutline)
        if level >= maxLevel then
            levelValue:SetText(tostring(level) .. "  ★ MAX")
            levelValue:SetTextColor(1.0, 0.84, 0.0, 1)
        else
            levelValue:SetText(tostring(level) .. " → " .. (level + 1))
            levelValue:SetTextColor(1.0, 1.0, 1.0, 1)
        end

        local lw = levelLabel:GetStringWidth()
        local vw = levelValue:GetStringWidth()
        if lw > maxLeftWidth then maxLeftWidth = lw end
        if vw > maxRightWidth then maxRightWidth = vw end
        table.insert(rows, {type = "pair", left = levelLabel, right = levelValue, y = yOffset})
        yOffset = yOffset - lineHeight

        -- XP Progress row (only if not max level)
        if level < maxLevel then
            local xpLabel = GetLine()
            xpLabel:SetFont(fontPath, 10, fontOutline)
            xpLabel:SetText("Progress")
            xpLabel:SetTextColor(0.6, 0.6, 0.6, 1)

            local xpValue = GetLine()
            xpValue:SetFont(fontPath, 10, fontOutline)
            xpValue:SetText(string.format("%s / %s  (%.1f%%)",
                AbbreviateNumber and AbbreviateNumber(currentXP) or currentXP,
                AbbreviateNumber and AbbreviateNumber(maxXP) or maxXP,
                xpPercent))
            xpValue:SetTextColor(0.5, 0.85, 1.0, 1)

            lw = xpLabel:GetStringWidth()
            vw = xpValue:GetStringWidth()
            if lw > maxLeftWidth then maxLeftWidth = lw end
            if vw > maxRightWidth then maxRightWidth = vw end
            table.insert(rows, {type = "pair", left = xpLabel, right = xpValue, y = yOffset})
            yOffset = yOffset - lineHeight

            -- Remaining XP row
            local remainLabel = GetLine()
            remainLabel:SetFont(fontPath, 10, fontOutline)
            remainLabel:SetText("To Level")
            remainLabel:SetTextColor(0.6, 0.6, 0.6, 1)

            local remainValue = GetLine()
            remainValue:SetFont(fontPath, 10, fontOutline)
            local remaining = maxXP - currentXP
            remainValue:SetText(AbbreviateNumber and AbbreviateNumber(remaining) or tostring(remaining))
            remainValue:SetTextColor(0.85, 0.85, 0.85, 1)

            lw = remainLabel:GetStringWidth()
            vw = remainValue:GetStringWidth()
            if lw > maxLeftWidth then maxLeftWidth = lw end
            if vw > maxRightWidth then maxRightWidth = vw end
            table.insert(rows, {type = "pair", left = remainLabel, right = remainValue, y = yOffset})
            yOffset = yOffset - lineHeight

            -- Rested XP row (if any)
            if restedXP > 0 then
                local restedLabel = GetLine()
                restedLabel:SetFont(fontPath, 10, fontOutline)
                restedLabel:SetText("Rested")
                restedLabel:SetTextColor(0.6, 0.6, 0.6, 1)

                local restedValue = GetLine()
                restedValue:SetFont(fontPath, 10, fontOutline)
                local restedPercent = maxXP > 0 and (restedXP / maxXP * 100) or 0
                restedValue:SetText(string.format("+%s  (%.0f%%)",
                    AbbreviateNumber and AbbreviateNumber(restedXP) or restedXP,
                    restedPercent))
                restedValue:SetTextColor(0.3, 0.5, 1.0, 1)

                lw = restedLabel:GetStringWidth()
                vw = restedValue:GetStringWidth()
                if lw > maxLeftWidth then maxLeftWidth = lw end
                if vw > maxRightWidth then maxRightWidth = vw end
                table.insert(rows, {type = "pair", left = restedLabel, right = restedValue, y = yOffset})
                yOffset = yOffset - lineHeight
            end
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════
    -- REPUTATION SECTION (shown second if enabled)
    -- ═══════════════════════════════════════════════════════════════════════
    local showREP = KOL.db.profile.ldbShowREP
    if showREP then
        local name, standingID, barMin, barMax, barValue = GetWatchedFactionInfo()

        -- Add separator if we had XP content before
        if hasContent then
            table.insert(rows, {type = "separator", y = yOffset - sectionSpacing})
            yOffset = yOffset - separatorHeight
        end
        hasContent = true

        -- Add REP header with styled background
        local repHeader = GetLine()
        repHeader:SetFont(fontPath, 11, fontOutline)
        repHeader:SetText("REPUTATION")
        repHeader:SetTextColor(0.95, 0.75, 0.35, 1)
        table.insert(rows, {type = "sectionHeader", line = repHeader, y = yOffset, color = {0.7, 0.5, 0.2}})
        yOffset = yOffset - headerHeight

        if name and standingID then
            -- Reputation thresholds (absolute values from Hated to Exalted)
            local REP_THRESHOLDS = {
                [1] = {min = -42000, max = -6000},   -- Hated
                [2] = {min = -6000,  max = -3000},   -- Hostile
                [3] = {min = -3000,  max = 0},       -- Unfriendly
                [4] = {min = 0,      max = 3000},    -- Neutral
                [5] = {min = 3000,   max = 9000},    -- Friendly
                [6] = {min = 9000,   max = 21000},   -- Honored
                [7] = {min = 21000,  max = 42000},   -- Revered
                [8] = {min = 42000,  max = 43000},   -- Exalted (max is 42999)
            }

            local standingColor = STANDING_COLORS[standingID] or {1, 1, 1}
            local standingName = STANDING_NAMES[standingID] or "Unknown"

            -- Calculate current rep within standing bracket
            local thresholds = REP_THRESHOLDS[standingID]
            local currentInBracket = 0
            local maxInBracket = 1
            if thresholds then
                currentInBracket = (barValue or 0) - thresholds.min
                maxInBracket = thresholds.max - thresholds.min
            end
            local bracketPercent = maxInBracket > 0 and (currentInBracket / maxInBracket * 100) or 0

            -- Faction name row
            local factionLabel = GetLine()
            factionLabel:SetFont(fontPath, 10, fontOutline)
            factionLabel:SetText("Faction")
            factionLabel:SetTextColor(0.6, 0.6, 0.6, 1)

            local factionValue = GetLine()
            factionValue:SetFont(fontPath, 10, fontOutline)
            factionValue:SetText(name)
            factionValue:SetTextColor(1.0, 1.0, 1.0, 1)

            local lw = factionLabel:GetStringWidth()
            local vw = factionValue:GetStringWidth()
            if lw > maxLeftWidth then maxLeftWidth = lw end
            if vw > maxRightWidth then maxRightWidth = vw end
            table.insert(rows, {type = "pair", left = factionLabel, right = factionValue, y = yOffset})
            yOffset = yOffset - lineHeight

            -- Standing row
            local standingLabel = GetLine()
            standingLabel:SetFont(fontPath, 10, fontOutline)
            standingLabel:SetText("Standing")
            standingLabel:SetTextColor(0.6, 0.6, 0.6, 1)

            local standingValue = GetLine()
            standingValue:SetFont(fontPath, 10, fontOutline)
            standingValue:SetText(standingName)
            standingValue:SetTextColor(standingColor[1], standingColor[2], standingColor[3], 1)

            lw = standingLabel:GetStringWidth()
            vw = standingValue:GetStringWidth()
            if lw > maxLeftWidth then maxLeftWidth = lw end
            if vw > maxRightWidth then maxRightWidth = vw end
            table.insert(rows, {type = "pair", left = standingLabel, right = standingValue, y = yOffset})
            yOffset = yOffset - lineHeight

            -- Progress row (current standing bracket)
            local progressLabel = GetLine()
            progressLabel:SetFont(fontPath, 10, fontOutline)
            progressLabel:SetText("Progress")
            progressLabel:SetTextColor(0.6, 0.6, 0.6, 1)

            local progressValue = GetLine()
            progressValue:SetFont(fontPath, 10, fontOutline)
            progressValue:SetText(string.format("%s / %s  (%.1f%%)",
                AbbreviateNumber and AbbreviateNumber(currentInBracket) or currentInBracket,
                AbbreviateNumber and AbbreviateNumber(maxInBracket) or maxInBracket,
                bracketPercent))
            progressValue:SetTextColor(standingColor[1], standingColor[2], standingColor[3], 1)

            lw = progressLabel:GetStringWidth()
            vw = progressValue:GetStringWidth()
            if lw > maxLeftWidth then maxLeftWidth = lw end
            if vw > maxRightWidth then maxRightWidth = vw end
            table.insert(rows, {type = "pair", left = progressLabel, right = progressValue, y = yOffset})
            yOffset = yOffset - lineHeight

            -- Progress Max row (current bracket progress / total remaining to Exalted)
            if standingID < 8 then
                local exaltedThreshold = REP_THRESHOLDS[8].min  -- 42000 (start of Exalted)
                local remainingInBracket = maxInBracket - currentInBracket
                local totalRemainingToExalted = remainingInBracket

                -- Add rep needed for all standings between current and Exalted
                for i = standingID + 1, 7 do  -- Up to Revered (7), not including Exalted
                    local nextThresholds = REP_THRESHOLDS[i]
                    if nextThresholds then
                        totalRemainingToExalted = totalRemainingToExalted + (nextThresholds.max - nextThresholds.min)
                    end
                end

                local progressMaxLabel = GetLine()
                progressMaxLabel:SetFont(fontPath, 10, fontOutline)
                progressMaxLabel:SetText("Progress Max")
                progressMaxLabel:SetTextColor(0.6, 0.6, 0.6, 1)

                local progressMaxValue = GetLine()
                progressMaxValue:SetFont(fontPath, 10, fontOutline)
                progressMaxValue:SetText(string.format("%s / %s",
                    AbbreviateNumber and AbbreviateNumber(currentInBracket) or currentInBracket,
                    AbbreviateNumber and AbbreviateNumber(currentInBracket + totalRemainingToExalted) or (currentInBracket + totalRemainingToExalted)))
                progressMaxValue:SetTextColor(standingColor[1], standingColor[2], standingColor[3], 1)

                lw = progressMaxLabel:GetStringWidth()
                vw = progressMaxValue:GetStringWidth()
                if lw > maxLeftWidth then maxLeftWidth = lw end
                if vw > maxRightWidth then maxRightWidth = vw end
                table.insert(rows, {type = "pair", left = progressMaxLabel, right = progressMaxValue, y = yOffset})
                yOffset = yOffset - lineHeight
            end

            -- Progress to Exalted row (if not already Exalted)
            if standingID < 8 then
                local exaltedThreshold = REP_THRESHOLDS[8].min  -- 42000
                local repToExalted = exaltedThreshold - (barValue or 0)
                local totalFromNeutral = exaltedThreshold - REP_THRESHOLDS[4].min  -- Total from Neutral to Exalted
                local currentFromNeutral = (barValue or 0) - REP_THRESHOLDS[4].min
                local exaltedPercent = totalFromNeutral > 0 and (currentFromNeutral / totalFromNeutral * 100) or 0
                if exaltedPercent < 0 then exaltedPercent = 0 end
                if exaltedPercent > 100 then exaltedPercent = 100 end

                local toExaltedLabel = GetLine()
                toExaltedLabel:SetFont(fontPath, 10, fontOutline)
                toExaltedLabel:SetText("To Exalted")
                toExaltedLabel:SetTextColor(0.6, 0.6, 0.6, 1)

                local toExaltedValue = GetLine()
                toExaltedValue:SetFont(fontPath, 10, fontOutline)
                toExaltedValue:SetText(string.format("%s  (%.1f%%)",
                    AbbreviateNumber and AbbreviateNumber(repToExalted) or repToExalted,
                    exaltedPercent))
                -- Color based on overall progress (blend from current standing color toward exalted purple)
                local exaltedColor = STANDING_COLORS[8] or {0.58, 0, 0.83}
                local blendR = standingColor[1] * (1 - exaltedPercent/100) + exaltedColor[1] * (exaltedPercent/100)
                local blendG = standingColor[2] * (1 - exaltedPercent/100) + exaltedColor[2] * (exaltedPercent/100)
                local blendB = standingColor[3] * (1 - exaltedPercent/100) + exaltedColor[3] * (exaltedPercent/100)
                toExaltedValue:SetTextColor(blendR, blendG, blendB, 1)

                lw = toExaltedLabel:GetStringWidth()
                vw = toExaltedValue:GetStringWidth()
                if lw > maxLeftWidth then maxLeftWidth = lw end
                if vw > maxRightWidth then maxRightWidth = vw end
                table.insert(rows, {type = "pair", left = toExaltedLabel, right = toExaltedValue, y = yOffset})
                yOffset = yOffset - lineHeight
            end
        else
            -- No faction watched
            local noFactionLine = GetLine()
            noFactionLine:SetFont(fontPath, 10, fontOutline)
            noFactionLine:SetText("No faction tracked")
            noFactionLine:SetTextColor(0.45, 0.45, 0.45, 1)

            local nw = noFactionLine:GetStringWidth()
            if nw > maxLeftWidth + gapWidth + maxRightWidth then
                maxRightWidth = nw - maxLeftWidth - gapWidth
                if maxRightWidth < 0 then
                    maxLeftWidth = nw
                    maxRightWidth = 0
                end
            end
            table.insert(rows, {type = "single", line = noFactionLine, y = yOffset})
            yOffset = yOffset - lineHeight
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════
    -- INFORMATION SECTION (feature explanations)
    -- ═══════════════════════════════════════════════════════════════════════

    -- Add separator if we had content before
    if hasContent then
        table.insert(rows, {type = "separator", y = yOffset - sectionSpacing})
        yOffset = yOffset - separatorHeight
    end
    hasContent = true

    -- Add information header with styled background
    local infoHeader = GetLine()
    infoHeader:SetFont(fontPath, 11, fontOutline)
    infoHeader:SetText("INFORMATION")
    infoHeader:SetTextColor(0.7, 0.7, 0.9, 1)
    table.insert(rows, {type = "sectionHeader", line = infoHeader, y = yOffset, color = {0.4, 0.4, 0.6}})
    yOffset = yOffset - headerHeight

    -- Define information entries
    local infoEntries = {
        {
            label = "SPEED",
            desc = "Current movement speed %",
            labelColor = {0.6, 0.85, 1.0},
            descColor = {0.55, 0.55, 0.55},
        },
        {
            label = "LIMIT",
            desc = "Caps damage for level sync",
            labelColor = {1.0, 0.55, 0.55},
            descColor = {0.55, 0.55, 0.55},
        },
        {
            label = "ADR",
            desc = "Auto-resets dungeon on exit",
            labelColor = {1.0, 0.7, 0.4},
            descColor = {0.55, 0.55, 0.55},
        },
        {
            label = "RACIAL",
            desc = "Swaps primary/secondary racial",
            labelColor = {0.9, 0.55, 1.0},
            descColor = {0.55, 0.55, 0.55},
        },
        {
            label = "XP BAR",
            desc = "Level progress visualization",
            labelColor = {0.4, 0.75, 1.0},
            descColor = {0.55, 0.55, 0.55},
        },
        {
            label = "REP BAR",
            desc = "Faction standing progress",
            labelColor = {0.95, 0.75, 0.35},
            descColor = {0.55, 0.55, 0.55},
        },
    }

    -- Add information rows
    for _, info in ipairs(infoEntries) do
        local labelLine = GetLine()
        labelLine:SetFont(fontPath, 10, fontOutline)
        labelLine:SetText(info.label)
        labelLine:SetTextColor(info.labelColor[1], info.labelColor[2], info.labelColor[3], 1)

        local descLine = GetLine()
        descLine:SetFont(fontPath, 10, fontOutline)
        descLine:SetText(info.desc)
        descLine:SetTextColor(info.descColor[1], info.descColor[2], info.descColor[3], 1)

        local labelWidth = labelLine:GetStringWidth()
        local descWidth = descLine:GetStringWidth()
        if labelWidth > maxLeftWidth then maxLeftWidth = labelWidth end
        if descWidth > maxRightWidth then maxRightWidth = descWidth end

        table.insert(rows, {type = "pair", left = labelLine, right = descLine, y = yOffset})
        yOffset = yOffset - lineHeight
    end

    -- ═══════════════════════════════════════════════════════════════════════
    -- SHORTCUTS SECTION (click actions) - now with 4-column layout
    -- ═══════════════════════════════════════════════════════════════════════

    table.insert(rows, {type = "separator", y = yOffset - sectionSpacing})
    yOffset = yOffset - separatorHeight

    -- Add shortcuts header with styled background
    local shortcutsHeader = GetLine()
    shortcutsHeader:SetFont(fontPath, 11, fontOutline)
    shortcutsHeader:SetText("SHORTCUTS")
    shortcutsHeader:SetTextColor(0.5, 0.8, 0.5, 1)
    table.insert(rows, {type = "sectionHeader", line = shortcutsHeader, y = yOffset, color = {0.3, 0.6, 0.3}})
    yOffset = yOffset - headerHeight

    -- Define click actions with separate modifier/mouse columns
    local actions = {
        {modifier = "",      mouse = "LEFTMOUSE",  action = "Open Menu",         modColor = {0.5, 0.95, 0.5},  mouseColor = {0.5, 0.95, 0.5}},
        {modifier = "",      mouse = "RIGHTMOUSE", action = "Deposit Resources", modColor = {0.6, 0.85, 1.0},  mouseColor = {0.6, 0.85, 1.0}},
        {modifier = "SHIFT", mouse = "LEFTMOUSE",  action = "Reload UI",         modColor = {1.0, 0.85, 0.4},  mouseColor = {1.0, 0.85, 0.4}},
        {modifier = "SHIFT", mouse = "RIGHTMOUSE", action = "Open Config",       modColor = {0.5, 0.75, 1.0},  mouseColor = {0.5, 0.75, 1.0}},
        {modifier = "CTRL",  mouse = "LEFTMOUSE",  action = "Limit Damage",      modColor = {1.0, 0.55, 0.55}, mouseColor = {1.0, 0.55, 0.55}},
        {modifier = "CTRL",  mouse = "RIGHTMOUSE", action = "Auto Dungeon Reset", modColor = {1.0, 0.7, 0.4},   mouseColor = {1.0, 0.7, 0.4}},
        {modifier = "ALT",   mouse = "LEFTMOUSE",  action = "Swap Racial",       modColor = {0.9, 0.55, 1.0},  mouseColor = {0.9, 0.55, 1.0}},
    }

    -- First pass: measure column widths
    local shortcutRows = {}
    for _, actionData in ipairs(actions) do
        local modLine = GetLine()
        modLine:SetFont(fontPath, 10, fontOutline)
        modLine:SetText(actionData.modifier)
        modLine:SetTextColor(actionData.modColor[1], actionData.modColor[2], actionData.modColor[3], 1)

        local plusLine = GetLine()
        plusLine:SetFont(fontPath, 10, fontOutline)
        if actionData.modifier ~= "" then
            plusLine:SetText("+")
            plusLine:SetTextColor(0.5, 0.5, 0.5, 1)
        else
            plusLine:SetText("")
        end

        local mouseLine = GetLine()
        mouseLine:SetFont(fontPath, 10, fontOutline)
        mouseLine:SetText(actionData.mouse)
        mouseLine:SetTextColor(actionData.mouseColor[1], actionData.mouseColor[2], actionData.mouseColor[3], 1)

        local actionLine = GetLine()
        actionLine:SetFont(fontPath, 10, fontOutline)
        actionLine:SetText(actionData.action)
        actionLine:SetTextColor(0.75, 0.75, 0.75, 1)

        -- Track column widths
        local modWidth = modLine:GetStringWidth()
        local plusWidth = plusLine:GetStringWidth()
        local mouseWidth = mouseLine:GetStringWidth()
        local actWidth = actionLine:GetStringWidth()

        if modWidth > shortcutModifierWidth then shortcutModifierWidth = modWidth end
        if plusWidth > shortcutPlusWidth then shortcutPlusWidth = plusWidth end
        if mouseWidth > shortcutMouseWidth then shortcutMouseWidth = mouseWidth end
        if actWidth > shortcutActionWidth then shortcutActionWidth = actWidth end

        table.insert(shortcutRows, {
            mod = modLine, plus = plusLine, mouse = mouseLine, action = actionLine,
            y = yOffset, hasModifier = (actionData.modifier ~= "")
        })
        yOffset = yOffset - lineHeight
    end

    -- Adjust for the extra lineHeight decrement after the last row (keep half line for spacing)
    yOffset = yOffset + (lineHeight / 2)

    -- Store shortcut rows for positioning later
    for _, row in ipairs(shortcutRows) do
        table.insert(rows, {type = "shortcut", data = row})
    end

    -- ═══════════════════════════════════════════════════════════════════════
    -- POSITION ALL ELEMENTS
    -- ═══════════════════════════════════════════════════════════════════════

    -- Calculate total width considering shortcut columns
    local shortcutTotalWidth = shortcutModifierWidth + 4 + shortcutPlusWidth + 4 + shortcutMouseWidth + gapWidth + shortcutActionWidth
    local pairTotalWidth = maxLeftWidth + gapWidth + maxRightWidth

    local contentWidth = math.max(shortcutTotalWidth, pairTotalWidth)
    local totalWidth = padding + contentWidth + padding
    if totalWidth < 220 then totalWidth = 220 end  -- Minimum width

    for _, row in ipairs(rows) do
        if row.type == "pair" then
            row.left:SetPoint("TOPLEFT", clickActionTooltip, "TOPLEFT", padding, row.y)
            row.right:SetPoint("TOPLEFT", clickActionTooltip, "TOPLEFT", padding + maxLeftWidth + gapWidth, row.y)
        elseif row.type == "shortcut" then
            local data = row.data
            local xPos = padding

            -- Position modifier (or skip space if empty)
            if data.hasModifier then
                data.mod:SetPoint("TOPLEFT", clickActionTooltip, "TOPLEFT", xPos, data.y)
            end
            xPos = xPos + shortcutModifierWidth + 4

            -- Position plus sign
            if data.hasModifier then
                data.plus:SetPoint("TOPLEFT", clickActionTooltip, "TOPLEFT", xPos, data.y)
            end
            xPos = xPos + shortcutPlusWidth + 4

            -- Position mouse button
            data.mouse:SetPoint("TOPLEFT", clickActionTooltip, "TOPLEFT", xPos, data.y)
            xPos = xPos + shortcutMouseWidth + gapWidth

            -- Position action
            data.action:SetPoint("TOPLEFT", clickActionTooltip, "TOPLEFT", xPos, data.y)
        elseif row.type == "sectionHeader" then
            -- Create styled section header with solid background and fade at right edge
            -- Background brightness (0.4 = moderately bright, not washed out)
            local bgMult = 0.4
            local bgAlpha = 0.95

            -- Calculate widths: solid part is 70%, fade part is 30%
            local contentWidth = totalWidth - (padding * 2)
            local solidWidth = contentWidth * 0.70
            local fadeWidth = contentWidth * 0.30

            -- Solid background (covers 70% of width)
            local bg = GetHeaderBg()
            bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            bg:SetVertexColor(row.color[1] * bgMult, row.color[2] * bgMult, row.color[3] * bgMult, bgAlpha)
            bg:SetPoint("TOPLEFT", clickActionTooltip, "TOPLEFT", padding, row.y + 2)
            bg:SetSize(solidWidth, headerHeight - 2)

            -- Fade texture (covers last 15%, gradient from solid to transparent)
            local fade = GetHeaderFade()
            fade:SetTexture("Interface\\Buttons\\WHITE8X8")
            fade:SetPoint("TOPLEFT", bg, "TOPRIGHT", 0, 0)
            fade:SetSize(fadeWidth, headerHeight - 2)
            fade:SetGradientAlpha("HORIZONTAL",
                row.color[1] * bgMult, row.color[2] * bgMult, row.color[3] * bgMult, bgAlpha,  -- Left side (solid)
                row.color[1] * bgMult, row.color[2] * bgMult, row.color[3] * bgMult, 0)       -- Right side (transparent)

            -- Solid accent bar on the left (3px wide, full color)
            local accent = GetHeaderAccent()
            accent:SetTexture("Interface\\Buttons\\WHITE8X8")
            accent:SetVertexColor(row.color[1], row.color[2], row.color[3], 1)
            accent:SetPoint("TOPLEFT", clickActionTooltip, "TOPLEFT", padding, row.y + 2)
            accent:SetSize(3, headerHeight - 2)

            -- Vertically center the text in the header
            local textYOffset = row.y - (headerHeight / 2) + 8  -- Adjust for vertical centering
            row.line:SetPoint("TOPLEFT", clickActionTooltip, "TOPLEFT", padding + 8, textYOffset)
        elseif row.type == "header" then
            row.line:SetPoint("TOPLEFT", clickActionTooltip, "TOPLEFT", padding, row.y)
        elseif row.type == "single" then
            row.line:SetPoint("TOPLEFT", clickActionTooltip, "TOPLEFT", padding + 8, row.y)
        elseif row.type == "separator" then
            local sep = GetSeparator()
            sep:SetHeight(1)
            sep:SetTexture("Interface\\Buttons\\WHITE8X8")
            sep:SetVertexColor(0.35, 0.35, 0.4, 0.4)
            sep:SetPoint("TOPLEFT", clickActionTooltip, "TOPLEFT", padding, row.y)
            sep:SetPoint("TOPRIGHT", clickActionTooltip, "TOPRIGHT", -padding, row.y)
        end
    end

    -- Size the tooltip
    local totalHeight = math.abs(yOffset) + padding
    clickActionTooltip:SetSize(totalWidth, totalHeight)

    -- Position based on anchor location
    clickActionTooltip:ClearAllPoints()
    local anchorY = anchor:GetCenter()
    local screenHeight = UIParent:GetHeight()

    if anchorY > screenHeight / 2 then
        -- Anchor is in top half - show tooltip below
        clickActionTooltip:SetPoint("TOP", anchor, "BOTTOM", 0, -4)
    else
        -- Anchor is in bottom half - show tooltip above
        clickActionTooltip:SetPoint("BOTTOM", anchor, "TOP", 0, 4)
    end

    clickActionTooltip:Show()
end

local function HideClickActionTooltip()
    if clickActionTooltip then
        clickActionTooltip:Hide()
    end
end

local function AcquireTooltip()
    local tooltip = table.remove(tooltipPool)
    if not tooltip then
        tooltip = CreateFrame("Frame", nil, UIParent)
        tooltip:SetFrameStrata("TOOLTIP")
        tooltip:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        tooltip.items = {}
        tooltip.regions = {}
    end

    tooltip:SetParent(UIParent)
    tooltip:ClearAllPoints()
    tooltip:Show()
    table.insert(activeTooltips, tooltip)
    return tooltip
end

local function ReleaseTooltip(tooltip)
    if not tooltip then return end

    -- CRITICAL: Disable keyboard capture first to release input focus
    tooltip:EnableKeyboard(false)
    tooltip:SetScript("OnKeyDown", nil)

    -- Hide and clear
    tooltip:Hide()
    tooltip:ClearAllPoints()

    -- Clear item buttons
    for _, item in ipairs(tooltip.items) do
        item:EnableMouse(false)  -- Release mouse on buttons
        item:Hide()
        item:SetParent(nil)
    end
    wipe(tooltip.items)

    -- Clear regions (textures, fontstrings)
    -- Note: Fonts and textures cannot have nil parent, just hide them
    for _, region in ipairs(tooltip.regions) do
        if region.Hide then region:Hide() end
        -- Only reparent frames, not textures/fontstrings (they error on nil parent)
        if region.SetParent and region:IsObjectType("Frame") then
            region:SetParent(nil)
        end
    end
    wipe(tooltip.regions)

    -- Remove from active list
    for i, t in ipairs(activeTooltips) do
        if t == tooltip then
            table.remove(activeTooltips, i)
            break
        end
    end

    -- Return to pool
    table.insert(tooltipPool, tooltip)
end

local function ReleaseAllTooltips()
    -- Release all except main tooltip
    for i = #activeTooltips, 1, -1 do
        local tooltip = activeTooltips[i]
        if tooltip ~= mainTooltip then
            ReleaseTooltip(tooltip)
        end
    end
end

local function ReleaseEverything()
    -- Release all tooltips (disables keyboard/mouse on each)
    for i = #activeTooltips, 1, -1 do
        ReleaseTooltip(activeTooltips[i])
    end
    mainTooltip = nil

    -- CRITICAL: Fully disable click catcher to release all mouse input
    if clickCatcher then
        clickCatcher:EnableMouse(false)
        clickCatcher:Hide()
    end
end

-- Create fullscreen click catcher (only once)
-- Uses LOW strata so other UI elements (BugSack, etc.) receive clicks first
-- Only catches clicks on "empty space" that no other frame handles
local function GetClickCatcher()
    if not clickCatcher then
        clickCatcher = CreateFrame("Button", nil, UIParent)
        -- Use LOW strata - this ensures:
        -- 1. Our menu at TOOLTIP strata is clickable (above this)
        -- 2. Other addons like BugSack at DIALOG strata receive their clicks (above this)
        -- 3. Only "background" clicks that nothing else handles come here
        clickCatcher:SetFrameStrata("LOW")
        clickCatcher:SetFrameLevel(1)
        clickCatcher:SetAllPoints(UIParent)
        clickCatcher:EnableMouse(true)
        clickCatcher:RegisterForClicks("AnyUp")  -- Catch any mouse button
        clickCatcher:SetScript("OnClick", function(self, button)
            -- Hide self FIRST to release mouse, then clean up menu
            self:Hide()
            self:EnableMouse(false)
            -- Now clean up the menu
            pcall(ReleaseEverything)
        end)
        clickCatcher:Hide()
    end
    return clickCatcher
end

-- ============================================================================
-- Screen Edge Detection
-- ============================================================================

local function GetScreenPosition(frame)
    local x, y = frame:GetCenter()
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()

    return {
        x = x,
        y = y,
        nearRight = (x + frame:GetWidth() / 2) > (screenWidth * 0.7),
        nearLeft = (x - frame:GetWidth() / 2) < (screenWidth * 0.3),
        nearTop = (y + frame:GetHeight() / 2) > (screenHeight * 0.8),
        nearBottom = (y - frame:GetHeight() / 2) < (screenHeight * 0.2),
    }
end

local function WouldOverflowRight(parentFrame, childWidth)
    local parentRight = parentFrame and parentFrame:GetRight()
    if not parentRight then return false end  -- Can't determine, default to not overflow
    local screenWidth = GetScreenWidth()
    return (parentRight + childWidth + SUBMENU_OFFSET) > screenWidth
end

-- ============================================================================
-- Tooltip Creation
-- ============================================================================

local function ApplyThemeColors(tooltip)
    -- Default colors
    local bgColor = {r = 0.05, g = 0.05, b = 0.05, a = 0.98}
    local borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1}

    -- Check for user-configured popup colors first
    if KOL.db and KOL.db.profile then
        if KOL.db.profile.popupBgColor then
            bgColor = KOL.db.profile.popupBgColor
        end
        if KOL.db.profile.popupBorderColor then
            borderColor = KOL.db.profile.popupBorderColor
        end
    end

    tooltip:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.98)
    tooltip:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
end

local function CreateLabel(tooltip, text, yOffset, color)
    local fontPath, fontOutline = GetFont()

    local label = tooltip:CreateFontString(nil, "OVERLAY")
    label:SetFont(fontPath, 10, fontOutline)
    label:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING + 4, yOffset)
    label:SetTextColor(color.r, color.g, color.b, 1)
    label:SetText(text)
    table.insert(tooltip.regions, label)

    return LABEL_HEIGHT
end

local function CreateSeparator(tooltip, yOffset, text)
    local fontPath, fontOutline = GetFont()

    if text then
        -- Text separator (--- Options ---)
        local sepText = tooltip:CreateFontString(nil, "OVERLAY")
        sepText:SetFont(fontPath, 9, fontOutline)
        sepText:SetPoint("TOP", tooltip, "TOP", 0, yOffset - 3)
        sepText:SetTextColor(COLORS.SEPARATOR.r, COLORS.SEPARATOR.g, COLORS.SEPARATOR.b, 0.8)
        sepText:SetText(text)
        table.insert(tooltip.regions, sepText)
    else
        -- Line separator
        local line = tooltip:CreateTexture(nil, "ARTWORK")
        line:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING + 4, yOffset - 4)
        line:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -PADDING - 4, yOffset - 4)
        line:SetHeight(1)
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetVertexColor(COLORS.SEPARATOR.r, COLORS.SEPARATOR.g, COLORS.SEPARATOR.b, 0.4)
        table.insert(tooltip.regions, line)
    end

    return SEPARATOR_HEIGHT
end

-- Styled section header (matches UIFactory:CreateSectionHeader and KOL_SectionHeader style)
local SECTION_HEADER_HEIGHT = 22
local function CreateSectionHeader(tooltip, yOffset, text, color)
    local fontPath, fontOutline = GetFont()
    color = color or COLORS.LABEL

    -- Get alpha from popup background setting (so section headers match popup transparency)
    local bgAlpha = 0.8
    if KOL.db and KOL.db.profile and KOL.db.profile.popupBgColor then
        bgAlpha = KOL.db.profile.popupBgColor.a or 0.98
    end

    -- Background - subtle dark using accent color at 20% intensity
    -- Use BORDER layer so it appears above the popup's backdrop but below ARTWORK/OVERLAY
    local bg = tooltip:CreateTexture(nil, "BORDER")
    bg:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING, yOffset)
    bg:SetPoint("BOTTOMRIGHT", tooltip, "TOPRIGHT", -PADDING, yOffset - SECTION_HEADER_HEIGHT)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(color.r * 0.2, color.g * 0.2, color.b * 0.2, bgAlpha)
    table.insert(tooltip.regions, bg)

    -- Left accent bar (3px wide)
    local accent = tooltip:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING, yOffset)
    accent:SetSize(3, SECTION_HEADER_HEIGHT)
    accent:SetTexture("Interface\\Buttons\\WHITE8X8")
    accent:SetVertexColor(color.r, color.g, color.b, 1)
    table.insert(tooltip.regions, accent)

    -- Text in accent color (vertically centered)
    local label = tooltip:CreateFontString(nil, "OVERLAY")
    label:SetFont(fontPath, 11, fontOutline)
    label:SetPoint("LEFT", tooltip, "TOPLEFT", PADDING + 10, yOffset - (SECTION_HEADER_HEIGHT / 2))
    label:SetTextColor(color.r, color.g, color.b, 1)
    label:SetText(text)
    table.insert(tooltip.regions, label)

    return SECTION_HEADER_HEIGHT + 2  -- Small gap after
end

local function CreateSettingRow(tooltip, yOffset, settingName, value, onClick)
    local fontPath, fontOutline = GetFont()
    local ROW_HEIGHT = 14

    -- Create a button frame if clickable, otherwise just use tooltip as parent
    local rowFrame
    if onClick then
        rowFrame = CreateFrame("Button", nil, tooltip)
        rowFrame:SetSize(MENU_WIDTH - (PADDING * 2), ROW_HEIGHT)
        rowFrame:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING, yOffset)
        rowFrame:EnableMouse(true)
        rowFrame:RegisterForClicks("LeftButtonUp")

        -- Background for hover
        rowFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        rowFrame:SetBackdropColor(0, 0, 0, 0)

        -- Hover effects
        rowFrame:SetScript("OnEnter", function(self)
            self:SetBackdropColor(COLORS.HOVER_BG.r, COLORS.HOVER_BG.g, COLORS.HOVER_BG.b, 1)
        end)
        rowFrame:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0, 0, 0, 0)
        end)

        -- Click handler
        rowFrame:SetScript("OnClick", onClick)

        table.insert(tooltip.items, rowFrame)
    end

    local parent = rowFrame or tooltip
    local leftOffset = onClick and 6 or (PADDING + 6)
    local rightOffset = onClick and -6 or (-PADDING - 6)

    -- Setting name on left
    local nameText = parent:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(fontPath, 9, fontOutline)
    if onClick then
        nameText:SetPoint("LEFT", parent, "LEFT", leftOffset, 0)
    else
        nameText:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING + 6, yOffset - 2)
    end
    nameText:SetTextColor(0.7, 0.7, 0.7, 1)  -- Gray for setting name
    nameText:SetText(settingName .. ":")
    table.insert(tooltip.regions, nameText)

    -- Value on right (colored green/red based on boolean)
    local valueText = parent:CreateFontString(nil, "OVERLAY")
    valueText:SetFont(fontPath, 9, fontOutline)
    if onClick then
        valueText:SetPoint("RIGHT", parent, "RIGHT", rightOffset, 0)
    else
        valueText:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -PADDING - 6, yOffset - 2)
    end

    if type(value) == "boolean" then
        if value then
            valueText:SetTextColor(0.3, 1, 0.3, 1)  -- Green for YES/enabled
            valueText:SetText("YES")
        else
            valueText:SetTextColor(1, 0.3, 0.3, 1)  -- Red for NO/disabled
            valueText:SetText("NO")
        end
    else
        valueText:SetTextColor(0.9, 0.9, 0.9, 1)  -- White for other values
        valueText:SetText(tostring(value))
    end
    table.insert(tooltip.regions, valueText)

    -- Store references for updating
    if rowFrame then
        rowFrame.nameText = nameText
        rowFrame.valueText = valueText
    end

    return ROW_HEIGHT
end

local function CreateMenuItem(tooltip, itemData, yOffset, expandLeft)
    local fontPath, fontOutline = GetFont()
    local UIFactory = KOL.UIFactory

    local btn = CreateFrame("Button", nil, tooltip)
    btn:SetSize(MENU_WIDTH - (PADDING * 2), ITEM_HEIGHT)
    btn:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING, yOffset)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Background for hover
    btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    btn:SetBackdropColor(0, 0, 0, 0)

    -- Icon (if folder or has icon) - using UIFactory:CreateGlyph for proper font
    local textOffset = 6

    if itemData.isFolder then
        local folderIcon = itemData.icon or GetIcon("FOLDER")
        if UIFactory and UIFactory.CreateGlyph then
            local icon = UIFactory:CreateGlyph(btn, folderIcon, COLORS.FOLDER, 10)
            icon:SetPoint("LEFT", btn, "LEFT", 6, 0)
        end
        textOffset = 22
    elseif itemData.icon then
        if UIFactory and UIFactory.CreateGlyph then
            local icon = UIFactory:CreateGlyph(btn, itemData.icon, {r = 0.8, g = 0.8, b = 0.8}, 10)
            icon:SetPoint("LEFT", btn, "LEFT", 6, 0)
        end
        textOffset = 22
    end

    -- Text
    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetFont(fontPath, 10, fontOutline)
    text:SetPoint("LEFT", btn, "LEFT", textOffset, 0)
    text:SetJustifyH("LEFT")

    local textColor = itemData.color or COLORS.ITEM
    if itemData.coloredText then
        text:SetText(itemData.text)
    else
        text:SetTextColor(textColor.r, textColor.g, textColor.b, 1)
        text:SetText(itemData.text)
    end
    btn.text = text
    btn.textColor = textColor

    -- Arrow for folders - using UIFactory:CreateGlyph for proper font
    if itemData.isFolder then
        local arrowChar = expandLeft and GetIcon("ARROW_LEFT") or GetIcon("ARROW_RIGHT")
        if UIFactory and UIFactory.CreateGlyph then
            local arrow = UIFactory:CreateGlyph(btn, arrowChar, COLORS.ARROW, 8)
            arrow:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
            btn.arrow = arrow
        end
        btn.arrowChar = arrowChar
        btn.expandLeft = expandLeft
    end

    -- Store data
    btn.itemData = itemData
    btn.parentTooltip = tooltip

    -- Hover effects
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(COLORS.HOVER_BG.r, COLORS.HOVER_BG.g, COLORS.HOVER_BG.b, 1)
        if self.text and not self.itemData.coloredText then
            self.text:SetTextColor(1, 1, 1, 1)
        end
        if self.arrow and self.arrow.SetGlyph then
            self.arrow:SetGlyph(self.arrowChar, {r = 1, g = 1, b = 1})
        end

        -- Show submenu if folder
        if self.itemData.isFolder and self.itemData.children then
            LDBModule:ShowSubmenu(self, self.itemData.children, self.itemData.title, self.expandLeft)
        else
            -- Close any open submenus at this level
            LDBModule:CloseSubmenusFrom(self.parentTooltip)
        end
    end)

    btn:SetScript("OnLeave", function(self)
        -- Check if mouse is over a child submenu
        local isOverChild = false
        for _, t in ipairs(activeTooltips) do
            if t.parentButton == self and MouseIsOver(t) then
                isOverChild = true
                break
            end
        end

        if not isOverChild then
            self:SetBackdropColor(0, 0, 0, 0)
            if self.text and not self.itemData.coloredText then
                self.text:SetTextColor(self.textColor.r, self.textColor.g, self.textColor.b, 1)
            end
            if self.arrow and self.arrow.SetGlyph then
                self.arrow:SetGlyph(self.arrowChar, COLORS.ARROW)
            end
        end
    end)

    -- Click handler - folders show submenu, items with onClick perform action
    if itemData.isFolder and itemData.children then
        btn:SetScript("OnClick", function(self)
            -- Toggle submenu on click as well as hover
            pcall(function()
                LDBModule:ShowSubmenu(self, self.itemData.children, self.itemData.title, self.expandLeft)
            end)
        end)
    elseif itemData.onClick then
        btn:SetScript("OnClick", function(self)
            -- Close menu first, then execute action (in case action errors)
            pcall(ReleaseEverything)
            pcall(self.itemData.onClick)
        end)
    end

    table.insert(tooltip.items, btn)
    return ITEM_HEIGHT
end

-- ============================================================================
-- Submenu Management
-- ============================================================================

function LDBModule:CloseSubmenusFrom(parentTooltip)
    -- Close all tooltips that are children of this parent
    for i = #activeTooltips, 1, -1 do
        local tooltip = activeTooltips[i]
        if tooltip.parentTooltip == parentTooltip then
            -- Recursively close children
            self:CloseSubmenusFrom(tooltip)
            ReleaseTooltip(tooltip)
        end
    end
end

function LDBModule:ShowSubmenu(parentButton, items, title, expandLeft)
    -- Close existing submenus from this parent
    self:CloseSubmenusFrom(parentButton.parentTooltip)

    local fontPath, fontOutline = GetFont()
    local tooltip = AcquireTooltip()
    tooltip.parentButton = parentButton
    tooltip.parentTooltip = parentButton.parentTooltip

    ApplyThemeColors(tooltip)
    tooltip:SetFrameLevel(parentButton.parentTooltip:GetFrameLevel() + 1)

    -- Determine if we should expand left based on screen position
    if expandLeft == nil then
        expandLeft = WouldOverflowRight(parentButton.parentTooltip, MENU_WIDTH)
    end

    -- Calculate height
    local yOffset = -PADDING
    local totalHeight = PADDING * 2

    -- Add centered title header
    if title then
        local header = tooltip:CreateFontString(nil, "OVERLAY")
        header:SetFont(fontPath, 10, fontOutline)
        header:SetPoint("TOP", tooltip, "TOP", 0, yOffset - 2)
        header:SetTextColor(COLORS.LABEL.r, COLORS.LABEL.g, COLORS.LABEL.b, 1)
        header:SetText(title)
        table.insert(tooltip.regions, header)
        yOffset = yOffset - HEADER_HEIGHT
        totalHeight = totalHeight + HEADER_HEIGHT

        -- Add separator after header
        local sepHeight = CreateSeparator(tooltip, yOffset)
        yOffset = yOffset - sepHeight
        totalHeight = totalHeight + sepHeight
    end

    -- Inherit expand direction from parent - only switch to left if would overflow
    -- Never switch back to right once we've gone left (prevents overlap)
    local childExpandLeft = expandLeft or WouldOverflowRight(tooltip, MENU_WIDTH)

    -- Add items
    for _, item in ipairs(items) do
        local itemHeight = CreateMenuItem(tooltip, item, yOffset, childExpandLeft)
        yOffset = yOffset - itemHeight
        totalHeight = totalHeight + itemHeight
    end

    tooltip:SetSize(MENU_WIDTH, totalHeight)

    -- Position relative to parent button
    tooltip:ClearAllPoints()
    if expandLeft then
        tooltip:SetPoint("TOPRIGHT", parentButton, "TOPLEFT", -SUBMENU_OFFSET, SUBMENU_OFFSET)
    else
        tooltip:SetPoint("TOPLEFT", parentButton, "TOPRIGHT", SUBMENU_OFFSET, SUBMENU_OFFSET)
    end

    -- Handle mouse leaving
    tooltip:SetScript("OnLeave", function(self)
        C_Timer.After(0.05, function()
            if not tooltip:IsShown() then return end

            -- Check if mouse is over this tooltip or any child
            local isOverSelf = MouseIsOver(tooltip)
            local isOverChild = false
            for _, t in ipairs(activeTooltips) do
                if t.parentTooltip == tooltip and MouseIsOver(t) then
                    isOverChild = true
                    break
                end
            end

            -- Check if mouse is back on parent
            local isOverParent = parentButton and MouseIsOver(parentButton)

            if not isOverSelf and not isOverChild and not isOverParent then
                LDBModule:CloseSubmenusFrom(parentButton.parentTooltip)
            end
        end)
    end)
end

-- ============================================================================
-- Menu Data Structure
-- ============================================================================

local function GetMenuStructure()
    local structure = {}

    -- Gather test commands dynamically
    local testItems = {}
    if KOL.slashCommands then
        for cmdName, data in pairs(KOL.slashCommands) do
            if data.category == "test" then
                table.insert(testItems, {
                    text = cmdName,
                    onClick = function()
                        KOL:TestSlashCommand(cmdName)
                    end,
                })
            end
        end
        table.sort(testItems, function(a, b) return a.text < b.text end)
    end

    -- Modules folder contents
    local moduleItems = {
        {
            text = "Progress Tracker",
            icon = CHAR_OBJECTIVE_UNCOMPLETE or "○",
            isFolder = true,
            title = "Progress Tracker",
            children = {
                { text = "Toggle Manager", onClick = function() if KOL.ShowTrackerManager then KOL:ShowTrackerManager() end end },
                { text = "Create Custom Tracker", onClick = function() if KOL.ShowTrackerManager then KOL:ShowTrackerManager() end end },
                { text = "Refresh All", onClick = function() if KOL.Tracker then KOL.Tracker:RefreshAllTrackers() end end },
            },
        },
        {
            text = "Macro Updater",
            icon = CHAR_SHAPES_DIAMOND or "◆",
            onClick = function()
                if KOL.MacroUpdater then
                    KOL.MacroUpdater:ShowUI()
                end
            end,
        },
        {
            text = "Boss Recorder",
            icon = "†",  -- Dagger symbol
            isFolder = true,
            title = "Boss Recorder",
            children = {
                { text = "Enable Recording", onClick = function() if KOL.BossRecorder then KOL.BossRecorder:Enable() end end },
                { text = "List Recordings", onClick = function() if KOL.BossRecorder then KOL.BossRecorder:ListRecordings() end end },
                { text = "Stop Recording", onClick = function() if KOL.BossRecorder then KOL.BossRecorder:Stop() end end },
            },
        },
        {
            text = "Key Bindings",
            icon = "☼",  -- Cog/settings symbol
            onClick = function()
                KOL:OpenConfig()
                -- Note: Would need bindings tab navigation
            end,
        },
        {
            text = "Debug Console",
            icon = "★",  -- Star symbol
            onClick = function() KOL:ToggleDebugConsole() end,
        },
        {
            text = "Character Viewer",
            icon = "☺",  -- Smiley face
            onClick = function() KOL:ToggleCharViewer() end,
        },
        {
            text = "Theme Editor",
            icon = "♫",  -- Music notes (creative/artistic)
            onClick = function()
                if KOL.ThemeEditor then
                    KOL.ThemeEditor:Toggle()
                end
            end,
        },
        {
            text = "Racial Swap",
            icon = "☻",  -- Filled smiley (person/character)
            isFolder = true,
            title = "Racial Swap",
            children = (function()
                local items = {
                    {
                        text = "Toggle Racial (/krs)",
                        onClick = function() KOL:ToggleRacial() end
                    },
                }

                -- Build racial selection submenus dynamically
                local validRaces = KOL.GetValidRacials and KOL:GetValidRacials() or {}

                if #validRaces > 0 then
                    -- Set Primary submenu
                    local primaryChildren = {}
                    for _, race in ipairs(validRaces) do
                        table.insert(primaryChildren, {
                            text = race,
                            onClick = function()
                                KOL.db.profile.racialPrimary = race
                                KOL:PrintTag("Primary racial set to: " .. race)
                            end,
                        })
                    end
                    table.insert(items, {
                        text = "Set Primary",
                        isFolder = true,
                        title = "Set Primary Racial",
                        children = primaryChildren,
                    })

                    -- Set Secondary submenu
                    local secondaryChildren = {}
                    for _, race in ipairs(validRaces) do
                        table.insert(secondaryChildren, {
                            text = race,
                            onClick = function()
                                KOL.db.profile.racialSecondary = race
                                KOL:PrintTag("Secondary racial set to: " .. race)
                            end,
                        })
                    end
                    table.insert(items, {
                        text = "Set Secondary",
                        isFolder = true,
                        title = "Set Secondary Racial",
                        children = secondaryChildren,
                    })

                    -- Quick set items for each race
                    table.insert(items, { text = "---", disabled = true })
                    for _, race in ipairs(validRaces) do
                        table.insert(items, {
                            text = "Switch to " .. race,
                            onClick = function() KOL:SetRacial(race) end,
                        })
                    end
                end

                return items
            end)(),
        },
    }

    -- Standalone folder contents
    local standaloneItems = {
        { text = "/kmu - Macro Updater", onClick = function() if KOL.MacroUpdater then KOL.MacroUpdater:ShowUI() end end },
        { text = "/kdc - Debug Console", onClick = function() KOL:ToggleDebugConsole() end },
        { text = "/kc - Config Panel", onClick = function() KOL:OpenConfig() end },
        { text = "/kld - Limit Damage", onClick = function() KOL:ToggleLimitDamage() end },
        { text = "/krs - Racial Swap", onClick = function() KOL:ToggleRacial() end },
        { text = "/rl - Reload UI", onClick = function() ReloadUI() end },
        {
            text = "Difficulty Commands",
            isFolder = true,
            title = "Difficulty",
            children = {
                { text = "/r25h - 25 Heroic", onClick = function() KOL:SetRaidDifficulty(4, "25 Man Heroic") end },
                { text = "/r25n - 25 Normal", onClick = function() KOL:SetRaidDifficulty(2, "25 Man Normal") end },
                { text = "/r10h - 10 Heroic", onClick = function() KOL:SetRaidDifficulty(3, "10 Man Heroic") end },
                { text = "/r10n - 10 Normal", onClick = function() KOL:SetRaidDifficulty(1, "10 Man Normal") end },
                { text = "/d5h - Dungeon Heroic", onClick = function() KOL:SetDungeonDifficulty(2, "5 Player Heroic") end },
                { text = "/d5n - Dungeon Normal", onClick = function() KOL:SetDungeonDifficulty(1, "5 Player Normal") end },
            },
        },
    }

    -- Config options (tabs)
    local configItems = {
        { text = "General", onClick = function() KOL:OpenConfig() LibStub("AceConfigDialog-3.0"):SelectGroup("KoalityOfLife", "general") end },
        { text = "Progress Tracker", onClick = function() KOL:OpenConfig() LibStub("AceConfigDialog-3.0"):SelectGroup("KoalityOfLife", "tracker") end },
        { text = "Tweaks", onClick = function() KOL:OpenConfig() LibStub("AceConfigDialog-3.0"):SelectGroup("KoalityOfLife", "tweaks") end },
        { text = "Command Blocks", onClick = function() KOL:OpenConfig() LibStub("AceConfigDialog-3.0"):SelectGroup("KoalityOfLife", "commandblocks") end },
    }

    -- Data Output items (/kdo commands)
    local dataOutputItems = {
        { text = "/kdo DungeonChallenge", onClick = function() if KOL.Info then KOL.Info:ShowDungeonChallenge() end end },
    }

    return {
        modules = moduleItems,
        tests = testItems,
        standalone = standaloneItems,
        dataOutput = dataOutputItems,
        config = configItems,
    }
end

-- ============================================================================
-- Main Menu
-- ============================================================================

function LDBModule:ShowMainMenu(anchor)
    -- Close any existing menu
    ReleaseEverything()

    local fontPath, fontOutline = GetFont()
    local tooltip = AcquireTooltip()
    mainTooltip = tooltip

    ApplyThemeColors(tooltip)
    tooltip:SetFrameLevel(100)

    local menuData = GetMenuStructure()
    local yOffset = -PADDING
    local totalHeight = PADDING * 2

    -- ========================================================================
    -- Header: Rainbow title + version
    -- ========================================================================

    local rainbowTitle = "|cFFFF6600K|cFFFF8800o|cFFFFAA00a|cFFFFCC00l|cFFFFEE00i|cFFDDFF00t|cFFBBFF00y|cFF99FF00-|cFF77FF00o|cFF55FF00f|cFF33FF00-|cFF00FF33L|cFF00FF66i|cFF00FF99f|cFF00FFCCe|r"

    local title = tooltip:CreateFontString(nil, "OVERLAY")
    title:SetFont(fontPath, 11, fontOutline)
    title:SetPoint("TOPLEFT", tooltip, "TOPLEFT", PADDING + 4, yOffset - 4)
    title:SetText(rainbowTitle)
    table.insert(tooltip.regions, title)

    local version = tooltip:CreateFontString(nil, "OVERLAY")
    version:SetFont(fontPath, 9, fontOutline)
    version:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -PADDING - 4, yOffset - 6)
    version:SetTextColor(COLORS.VERSION.r, COLORS.VERSION.g, COLORS.VERSION.b, 1)
    version:SetText("v" .. (KOL.version or "?"))
    table.insert(tooltip.regions, version)

    yOffset = yOffset - HEADER_HEIGHT
    totalHeight = totalHeight + HEADER_HEIGHT

    -- Separator after header
    local sepHeight = CreateSeparator(tooltip, yOffset)
    yOffset = yOffset - sepHeight
    totalHeight = totalHeight + sepHeight

    -- Check if we should expand submenus left based on anchor position
    -- (moved here so it's available for all submenus including RACIAL)
    local expandLeft = false
    if anchor then
        local anchorX = anchor:GetCenter()
        expandLeft = anchorX and anchorX > (GetScreenWidth() * 0.7)
    end

    -- ========================================================================
    -- Current Settings Section
    -- ========================================================================

    local currentHeaderHeight = CreateSectionHeader(tooltip, yOffset, "CURRENT", COLORS.LABEL)
    yOffset = yOffset - currentHeaderHeight
    totalHeight = totalHeight + currentHeaderHeight

    -- Auto Dungeon Reset setting (clickable to toggle)
    local dungeonResetValue = KOL.db and KOL.db.profile and KOL.db.profile.autoDungeonReset or false
    local dungeonResetRowHeight = CreateSettingRow(tooltip, yOffset, "AUTO DUNGEON RESET", dungeonResetValue, function(self)
        KOL:ToggleAutoDungeonReset()

        local newValue = KOL.db.profile.autoDungeonReset
        if newValue then
            self.valueText:SetTextColor(0.3, 1, 0.3, 1)
            self.valueText:SetText("YES")
        else
            self.valueText:SetTextColor(1, 0.3, 0.3, 1)
            self.valueText:SetText("NO")
        end
    end)
    yOffset = yOffset - dungeonResetRowHeight
    totalHeight = totalHeight + dungeonResetRowHeight

    -- Limit Damage setting (clickable to toggle)
    local limitDamageValue = KOL.db and KOL.db.profile and KOL.db.profile.limitDamage or false
    local limitDamageRowHeight = CreateSettingRow(tooltip, yOffset, "LIMIT DAMAGE", limitDamageValue, function(self)
        -- Toggle the setting (same as /kld)
        KOL:ToggleLimitDamage()

        -- Update the display immediately
        local newValue = KOL.db.profile.limitDamage
        if newValue then
            self.valueText:SetTextColor(0.3, 1, 0.3, 1)  -- Green for YES
            self.valueText:SetText("YES")
        else
            self.valueText:SetTextColor(1, 0.3, 0.3, 1)  -- Red for NO
            self.valueText:SetText("NO")
        end
    end)
    yOffset = yOffset - limitDamageRowHeight
    totalHeight = totalHeight + limitDamageRowHeight

    -- Current Racial setting (clickable folder with submenu)
    local currentRacial = KOL.GetCurrentRacial and KOL:GetCurrentRacial() or "Unknown"
    local validRaces = KOL.GetValidRacials and KOL:GetValidRacials() or {}

    -- Build submenu children for racial selection (cascading submenus)
    local racialChildren = {}

    -- Quick toggle option at the top
    local primary = KOL.db.profile.racialPrimary or "Unknown"
    local secondary = KOL.db.profile.racialSecondary or "Unknown"
    table.insert(racialChildren, {
        text = "|cFFAAAAAAToggle:|r " .. primary .. " <-> " .. secondary,
        coloredText = true,
        onClick = function()
            KOL:ToggleRacial()
        end,
    })

    -- Build Primary submenu children
    local primaryChildren = {}
    for _, race in ipairs(validRaces) do
        local isPrimary = (race == KOL.db.profile.racialPrimary)
        table.insert(primaryChildren, {
            text = race .. (isPrimary and " |cFF00FF00(Current)|r" or ""),
            coloredText = isPrimary,
            onClick = function()
                KOL.db.profile.racialPrimary = race
                KOL:PrintTag("Primary racial set to: |cFF00FF00" .. race .. "|r")
            end,
        })
    end

    -- Build Secondary submenu children
    local secondaryChildren = {}
    for _, race in ipairs(validRaces) do
        local isSecondary = (race == KOL.db.profile.racialSecondary)
        table.insert(secondaryChildren, {
            text = race .. (isSecondary and " |cFF00FFFF(Current)|r" or ""),
            coloredText = isSecondary,
            onClick = function()
                KOL.db.profile.racialSecondary = race
                KOL:PrintTag("Secondary racial set to: |cFF00FFFF" .. race .. "|r")
            end,
        })
    end

    -- Build Quick Set submenu children
    local quickSetChildren = {}
    for _, race in ipairs(validRaces) do
        local isCurrent = (race == currentRacial)
        table.insert(quickSetChildren, {
            text = race .. (isCurrent and " |cFF00FF00(Active)|r" or ""),
            coloredText = isCurrent,
            onClick = function()
                KOL:SetRacial(race)
            end,
        })
    end

    -- Add Primary folder
    table.insert(racialChildren, {
        text = "Primary",
        isFolder = true,
        title = "Set Primary Racial",
        children = primaryChildren,
        color = {r = 0.3, g = 1, b = 0.3},  -- Green for primary
    })

    -- Add Secondary folder
    table.insert(racialChildren, {
        text = "Secondary",
        isFolder = true,
        title = "Set Secondary Racial",
        children = secondaryChildren,
        color = {r = 0.3, g = 1, b = 1},  -- Cyan for secondary
    })

    -- Add Quick Set folder
    table.insert(racialChildren, {
        text = "Quick Set",
        isFolder = true,
        title = "Quick Set Racial",
        children = quickSetChildren,
        color = {r = 1, g = 0.8, b = 0.3},  -- Gold for quick set
    })

    -- Create the racial row as a clickable folder item
    local racialItemHeight = CreateMenuItem(tooltip, {
        text = "RACIAL: " .. currentRacial,
        isFolder = true,
        title = "Racial Selection",
        children = racialChildren,
        color = {r = 0.7, g = 0.7, b = 0.7},
    }, yOffset, expandLeft)
    yOffset = yOffset - racialItemHeight
    totalHeight = totalHeight + racialItemHeight

    -- Separator after current settings
    local currentSepHeight = CreateSeparator(tooltip, yOffset)
    yOffset = yOffset - currentSepHeight
    totalHeight = totalHeight + currentSepHeight

    -- ========================================================================
    -- Shortcuts Label
    -- ========================================================================

    local shortcutsHeaderHeight = CreateSectionHeader(tooltip, yOffset, "SHORTCUTS", COLORS.LABEL)
    yOffset = yOffset - shortcutsHeaderHeight
    totalHeight = totalHeight + shortcutsHeaderHeight

    -- ========================================================================
    -- Folders: Modules, Tests, Standalone
    -- ========================================================================

    -- Modules folder
    local modulesHeight = CreateMenuItem(tooltip, {
        text = "Modules",
        isFolder = true,
        title = "Modules",
        children = menuData.modules,
        color = COLORS.FOLDER,
    }, yOffset, expandLeft)
    yOffset = yOffset - modulesHeight
    totalHeight = totalHeight + modulesHeight

    -- Tests folder (only if tests exist)
    if #menuData.tests > 0 then
        local testsHeight = CreateMenuItem(tooltip, {
            text = "Tests",
            isFolder = true,
            title = "Tests",
            children = menuData.tests,
            color = COLORS.FOLDER,
        }, yOffset, expandLeft)
        yOffset = yOffset - testsHeight
        totalHeight = totalHeight + testsHeight
    end

    -- Standalone folder
    local standaloneHeight = CreateMenuItem(tooltip, {
        text = "Standalone",
        isFolder = true,
        title = "Standalone",
        children = menuData.standalone,
        color = COLORS.FOLDER,
    }, yOffset, expandLeft)
    yOffset = yOffset - standaloneHeight
    totalHeight = totalHeight + standaloneHeight

    -- Data Output folder
    local dataOutputHeight = CreateMenuItem(tooltip, {
        text = "Data Output",
        isFolder = true,
        title = "Data Output",
        children = menuData.dataOutput,
        color = COLORS.FOLDER,
    }, yOffset, expandLeft)
    yOffset = yOffset - dataOutputHeight
    totalHeight = totalHeight + dataOutputHeight

    -- ========================================================================
    -- Options Header (styled section header with accent bar)
    -- ========================================================================

    local optionsHeaderHeight = CreateSectionHeader(tooltip, yOffset, "OPTIONS", COLORS.LABEL)
    yOffset = yOffset - optionsHeaderHeight
    totalHeight = totalHeight + optionsHeaderHeight

    -- ========================================================================
    -- Config Tab Items
    -- ========================================================================

    for _, configItem in ipairs(menuData.config) do
        local itemHeight = CreateMenuItem(tooltip, configItem, yOffset, expandLeft)
        yOffset = yOffset - itemHeight
        totalHeight = totalHeight + itemHeight
    end

    -- ========================================================================
    -- Utility Options (Reload UI, Close)
    -- ========================================================================

    local utilSepHeight = CreateSeparator(tooltip, yOffset)
    yOffset = yOffset - utilSepHeight
    totalHeight = totalHeight + utilSepHeight

    local reloadHeight = CreateMenuItem(tooltip, {
        text = "Reload UI",
        icon = GetIcon("RELOAD"),
        color = {r = 0.7, g = 0.7, b = 0.4},
        onClick = function()
            ReloadUI()
        end,
    }, yOffset, expandLeft)
    yOffset = yOffset - reloadHeight
    totalHeight = totalHeight + reloadHeight

    local closeHeight = CreateMenuItem(tooltip, {
        text = "Close",
        icon = GetIcon("CLOSE"),
        color = {r = 0.6, g = 0.6, b = 0.6},
        onClick = function()
            ReleaseEverything()
        end,
    }, yOffset, expandLeft)
    yOffset = yOffset - closeHeight
    totalHeight = totalHeight + closeHeight

    -- ========================================================================
    -- Set size and position
    -- ========================================================================

    tooltip:SetSize(MENU_WIDTH, totalHeight)

    -- Position near anchor
    tooltip:ClearAllPoints()
    if anchor then
        local anchorX, anchorY = anchor:GetCenter()
        local screenWidth = GetScreenWidth()
        local screenHeight = GetScreenHeight()

        -- Determine best position
        if anchorY > screenHeight / 2 then
            -- Anchor is in top half, show below
            if anchorX > screenWidth / 2 then
                tooltip:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", 0, -2)
            else
                tooltip:SetPoint("TOPLEFT", anchor, "BOTTOMRIGHT", 0, -2)
            end
        else
            -- Anchor is in bottom half, show above
            if anchorX > screenWidth / 2 then
                tooltip:SetPoint("BOTTOMRIGHT", anchor, "TOPLEFT", 0, 2)
            else
                tooltip:SetPoint("BOTTOMLEFT", anchor, "TOPRIGHT", 0, 2)
            end
        end
    else
        -- Position at cursor
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        tooltip:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    end

    -- ========================================================================
    -- Close on click outside (using fullscreen click catcher)
    -- ========================================================================

    local catcher = GetClickCatcher()
    -- Frame level already set in GetClickCatcher() - strata (LOW) handles layering
    catcher:EnableMouse(true)  -- Re-enable after previous ReleaseEverything disabled it
    catcher:Show()

    -- Close on escape (with error protection)
    tooltip:EnableKeyboard(true)
    tooltip:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            pcall(ReleaseEverything)
            if self.SetPropagateKeyboardInput then
                self:SetPropagateKeyboardInput(false)
            end
        else
            if self.SetPropagateKeyboardInput then
                self:SetPropagateKeyboardInput(true)
            end
        end
    end)

    -- Also register for global escape as backup
    if not LDBModule.escapeFrame then
        LDBModule.escapeFrame = CreateFrame("Frame", nil, UIParent)
        LDBModule.escapeFrame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" and mainTooltip and mainTooltip:IsShown() then
                pcall(ReleaseEverything)
            end
        end)
        -- SetPropagateKeyboardInput may not exist in older WoW versions
        if LDBModule.escapeFrame.SetPropagateKeyboardInput then
            LDBModule.escapeFrame:SetPropagateKeyboardInput(true)
        end
    end

end

function LDBModule:HideMenu()
    ReleaseEverything()
end

function LDBModule:ToggleMenu(anchor)
    if mainTooltip and mainTooltip:IsShown() then
        ReleaseEverything()
    else
        self:ShowMainMenu(anchor)
    end
end

-- ============================================================================
-- LDB Data Object (created lazily in Initialize to respect settings)
-- ============================================================================

local dataObject = nil  -- Will be created in Initialize() if LDB plugin is enabled

-- Debug flag - set to true to debug LDB text issues (causes spam, disable after testing)
local ldbSpeedDebug = false

-- ChocolateBar font hook state (declared here so debug commands can access them)
local chocolateBarFontHooked = false
local chocolateBarHookAttempts = 0
local chocolateBarHookMaxAttempts = 20  -- Try for 10 seconds (20 * 0.5s)

local function CreateDataObject()
    if dataObject then return dataObject end

    -- Determine initial text based on saved settings
    -- IMPORTANT: Use PLAIN ASCII text initially - no color codes or Unicode!
    -- ChocolateBar can't render those until our font hook applies.
    -- The fancy formatted text will be set by UpdateLDBText after font hook.
    local initialText = "KoL"
    if KOL.db and KOL.db.profile then
        local profile = KOL.db.profile
        -- Get display settings with proper defaults
        -- Speed defaults to true (like old behavior), others default to false
        local showSpeed = profile.ldbShowSpeed ~= false
        local showLimit = profile.ldbShowLimit or false
        local showRacial = profile.ldbShowRacial or false
        local showADR = profile.ldbShowADR or false
        local showXP = profile.ldbShowXP or false
        local showREP = profile.ldbShowREP or false

        -- Check if any display option is enabled
        if showSpeed or showLimit or showRacial or showADR or showXP or showREP then
            -- Get positions for ordering
            local speedPos = profile.ldbSpeedPosition or 1
            local limitPos = profile.ldbLimitPosition or 2
            local racialPos = profile.ldbRacialPosition or 3
            local adrPos = profile.ldbADRPosition or 4
            local xpPos = profile.ldbXPPosition or 5
            local repPos = profile.ldbREPPosition or 6

            -- Build items with positions for sorting
            local items = {}
            if showSpeed then
                table.insert(items, { pos = speedPos, text = profile.ldbShowSpeedLabel and "SPEED: IDLE" or "IDLE" })
            end
            if showLimit then
                table.insert(items, { pos = limitPos, text = profile.ldbShowLimitLabel and "LIMIT: OFF" or "OFF" })
            end
            if showRacial then
                table.insert(items, { pos = racialPos, text = profile.ldbShowRacialLabel and "RACIAL: ?" or "?" })
            end
            if showADR then
                local disabledText = profile.ldbADRDisabledText or "NO"
                table.insert(items, { pos = adrPos, text = profile.ldbShowADRLabel and ("ADR: " .. disabledText) or disabledText })
            end
            if showXP then
                local xpPreview = profile.ldbShowXPLabel and "XP: [=====-----]" or "[=====-----]"
                if profile.ldbShowXPPercent ~= false then
                    xpPreview = xpPreview .. " 50%"
                end
                table.insert(items, { pos = xpPos, text = xpPreview })
            end
            if showREP then
                local repPreview = profile.ldbShowREPLabel and "REP: [=====-----]" or "[=====-----]"
                if profile.ldbShowREPPercent ~= false then
                    repPreview = repPreview .. " 50%"
                end
                table.insert(items, { pos = repPos, text = repPreview })
            end

            -- Sort by position
            table.sort(items, function(a, b) return a.pos < b.pos end)

            -- Extract text
            local parts = {}
            for _, item in ipairs(items) do
                table.insert(parts, item.text)
            end

            if #parts > 0 then
                initialText = table.concat(parts, " | ")
            end
        end

        -- DEBUG: Print what we're setting
        if ldbSpeedDebug then
            print("|cFF00FFFF[LDB DEBUG]|r CreateDataObject - initialText = '" .. tostring(initialText) .. "' (plain ASCII)")
        end
    end

    dataObject = LDB:NewDataObject("!Koality-of-Life", {
        type = "launcher",
        label = "Koality-of-Life",  -- Friendly name shown in LDB display addons
        text = initialText,         -- Initial text (KoL or BASE depending on mode)
        icon = "Interface\\AddOns\\!Koality-of-Life\\media\\images\\stevefurwin_normal",

        OnClick = function(self, button)
            -- Ignore clicks if LDB plugin is hidden
            if LDBModule:IsLDBHidden() then return end

            -- Hide tooltip on any click
            HideClickActionTooltip()

            -- Check for modifier keys first
            if IsShiftKeyDown() and button == "RightButton" then
                -- Shift+Right Click = Open Config
                KOL:OpenConfig()
                return
            elseif IsShiftKeyDown() then
                -- Shift+Left Click = Reload UI
                ReloadUI()
                return
            elseif IsControlKeyDown() and button == "RightButton" then
                -- Ctrl+Right Click = Toggle ADR
                KOL:ToggleAutoDungeonReset()
                return
            elseif IsControlKeyDown() then
                -- Ctrl+Left Click = Toggle Limit Damage
                KOL:ToggleLimitDamage()
                return
            elseif IsAltKeyDown() then
                KOL:ToggleRacial()
                return
            end

            -- Normal click actions
            if button == "LeftButton" then
                LDBModule:ToggleMenu(self)
            elseif button == "RightButton" then
                -- Right Click = Deposit Resources
                local btn = _G["RBankFrame-DepositAll"]
                if btn then
                    btn:Click()
                end
            end
        end,

        OnEnter = function(self)
            -- Hover effect: brighten/highlight the icon
            if self.icon then
                self.icon:SetVertexColor(1.2, 1.2, 1.2, 1)  -- Slightly brighter
            end
            -- Show click action tooltip
            ShowClickActionTooltip(self)
        end,

        OnLeave = function(self)
            -- Reset icon
            if self.icon then
                self.icon:SetVertexColor(1, 1, 1, 1)
            end
            -- Hide click action tooltip
            HideClickActionTooltip()
        end,

        -- No OnTooltipShow - we use custom menu instead
    })

    return dataObject
end

-- ============================================================================
-- Initialization
-- ============================================================================

function LDBModule:Initialize()
    -- Prevent double initialization (both PLAYER_LOGIN and PLAYER_ENTERING_WORLD fire on login)
    -- But allow re-initialization on reload (when chocolateBarFontHooked is reset to false)
    if self.initialized and chocolateBarFontHooked then
        KOL:DebugPrint("LDB: Already initialized, skipping", 3)
        return
    end
    self.initialized = true

    -- Initialize minimap icon database if needed
    if not KOL.db.profile.minimap then
        KOL.db.profile.minimap = {
            hide = false,
            minimapPos = 220,
            lock = false,
        }
    end

    -- Check if LDB plugin should be created at all
    -- If disabled, we don't create the dataObject - making it invisible to all LDB display addons
    local showLDB = KOL.db.profile.showLDBPlugin
    if showLDB == nil then showLDB = true end  -- Default to enabled

    if showLDB then
        -- Create the data object (this registers with LDB, making it visible to display addons)
        CreateDataObject()

        -- Register with LibDBIcon for minimap button (only if not already registered)
        if dataObject and not LDBIcon:IsRegistered("!Koality-of-Life") then
            LDBIcon:Register("!Koality-of-Life", dataObject, KOL.db.profile.minimap)
        end
    else
        -- LDB plugin disabled - don't create dataObject at all
        -- This means NO LDB display addon will see it
        KOL:DebugPrint("LDB plugin disabled - not registering with LibDataBroker", 2)
    end

    -- Apply minimap visibility (independent of LDB plugin setting)
    self:UpdateMinimapVisibility()

    -- Apply LDB text setting (speed display, etc.)
    self:UpdateLDBText()

    -- Hook minimap button for hover/click effects
    self:HookMinimapButton()

    -- Hook ChocolateBar font for proper glyph rendering
    self:HookChocolateBarFont()

    -- Retry timer: Keep trying to set the text until ChocolateBar accepts it
    -- This is needed because ChocolateBar may not be ready when we first try
    self:StartTextRetryTimer()

    -- Register emergency close command
    if KOL.RegisterSlashCommand then
        KOL:RegisterSlashCommand("closemenu", function()
            LDBModule:ForceCloseMenu()
        end, "Force close LDB menu if stuck", "utility")

        -- Debug command to test speed text
        KOL:RegisterSlashCommand("speedtest", function()
            print("|cFF00FFFF=== SPEED DEBUG ===|r")

            -- Test ReturnSpeedData
            local data = KOL:ReturnSpeedData()
            print("|cFFFFFF00ReturnSpeedData:|r")
            print("  text = '" .. tostring(data.text) .. "'")
            print("  color = '" .. tostring(data.color) .. "'")
            print("  glyph = '" .. tostring(data.glyph) .. "'")
            print("  isMoving = " .. tostring(data.isMoving))

            -- Test ReturnSpeedText
            local textNoPrefix = KOL:ReturnSpeedText(false)
            local textWithPrefix = KOL:ReturnSpeedText(true)
            print("|cFFFFFF00ReturnSpeedText:|r")
            print("  without prefix = '" .. tostring(textNoPrefix) .. "'")
            print("  with prefix = '" .. tostring(textWithPrefix) .. "'")

            -- Show what dataObject currently has
            if dataObject then
                print("|cFFFFFF00dataObject.text:|r '" .. tostring(dataObject.text) .. "'")
            else
                print("|cFFFF0000dataObject is nil!|r")
            end

            -- Show chocolateBarFontHooked status
            print("|cFFFFFF00chocolateBarFontHooked:|r " .. tostring(chocolateBarFontHooked))

            -- Try to directly set the text and show result
            if dataObject then
                local testText = "SPEED: TEST"
                dataObject.text = testText
                print("|cFF00FF00Set dataObject.text to:|r '" .. testText .. "'")
                print("|cFF00FF00dataObject.text after:|r '" .. tostring(dataObject.text) .. "'")
            end

            print("|cFF00FFFF=== END DEBUG ===|r")
        end, "Debug speed text output", "test")

        -- Debug command to check ChocolateBar font hook status
        KOL:RegisterSlashCommand("ldbfont", function()
            print("|cFF00FFFF=== LDB FONT DEBUG ===|r")

            -- Check chocolateBarFontHooked flag
            print("|cFFFFFF00chocolateBarFontHooked:|r " .. tostring(chocolateBarFontHooked))
            print("|cFFFFFF00chocolateBarHookAttempts:|r " .. tostring(chocolateBarHookAttempts))

            -- Check if CHAR_LIGATURESFONT is defined
            print("|cFFFFFF00CHAR_LIGATURESFONT:|r " .. tostring(CHAR_LIGATURESFONT))

            -- Check for our expected frame
            local frameName = "Chocolate!Koality-of-Life"
            local chocolateFrame = _G[frameName]
            print("|cFFFFFF00Frame '" .. frameName .. "':|r " .. tostring(chocolateFrame))

            if chocolateFrame then
                print("  .text exists: " .. tostring(chocolateFrame.text ~= nil))
                if chocolateFrame.text then
                    local fontPath, fontSize, fontFlags = chocolateFrame.text:GetFont()
                    print("  Current font: " .. tostring(fontPath))
                    print("  Font size: " .. tostring(fontSize))
                    print("  Font flags: " .. tostring(fontFlags))
                    print("  Expected font: " .. tostring(CHAR_LIGATURESFONT))
                    print("  Font matches: " .. tostring(fontPath == CHAR_LIGATURESFONT))
                end
            end

            -- Search for any frame starting with "Chocolate"
            print("|cFFFFFF00Searching for Chocolate* frames...|r")
            local found = 0
            for name, frame in pairs(_G) do
                if type(name) == "string" and name:find("^Chocolate") and type(frame) == "table" and frame.GetObjectType then
                    found = found + 1
                    print("  Found: " .. name .. " (" .. tostring(frame:GetObjectType()) .. ")")
                    if found >= 10 then
                        print("  ... (limited to 10)")
                        break
                    end
                end
            end
            if found == 0 then
                print("  No Chocolate* frames found!")
            end

            -- Offer to force re-apply
            print("|cFF00FF00Tip:|r Run /kol ldbfontfix to force re-apply the font hook")

            print("|cFF00FFFF=== END DEBUG ===|r")
        end, "Debug LDB font hook status", "test")

        -- Force fix the font hook
        KOL:RegisterSlashCommand("ldbfontfix", function()
            print("|cFFFFFF00Forcing ChocolateBar font hook re-apply...|r")
            chocolateBarFontHooked = false
            chocolateBarHookAttempts = 0
            LDBModule:HookChocolateBarFont()
            print("|cFF00FF00Done.|r Check /kol ldbfont for status.")
        end, "Force re-apply LDB font hook", "test")
    end

    -- Apply global XP/REP bar visibility settings
    self:ApplyGlobalBarVisibility()

    -- Start rainbow timer if needed
    self:StartRainbowTimer()

    KOL:DebugPrint("LDB module initialized with cascading menu", 2)
end

function LDBModule:Show()
    LDBIcon:Show("!Koality-of-Life")
    KOL.db.profile.minimap.hide = false
end

function LDBModule:Hide()
    LDBIcon:Hide("!Koality-of-Life")
    KOL.db.profile.minimap.hide = true
end

function LDBModule:Toggle()
    if KOL.db.profile.minimap.hide then
        self:Show()
    else
        self:Hide()
    end
end

function LDBModule:IsShown()
    return not KOL.db.profile.minimap.hide
end

function LDBModule:Lock()
    LDBIcon:Lock("!Koality-of-Life")
    KOL.db.profile.minimap.lock = true
end

function LDBModule:Unlock()
    LDBIcon:Unlock("!Koality-of-Life")
    KOL.db.profile.minimap.lock = false
end

-- Visibility control functions (called from settings)
function LDBModule:UpdateMinimapVisibility()
    -- Only works if LDB was registered (showLDBPlugin was enabled at login)
    if not dataObject then return end

    local showMinimap = KOL.db.profile.showMinimapButton
    if showMinimap == nil then showMinimap = true end  -- Default to shown

    if showMinimap then
        LDBIcon:Show("!Koality-of-Life")
        KOL.db.profile.minimap.hide = false
        -- Re-apply styling (HookMinimapButton checks kolHooked to avoid double-hooking)
        -- This is needed when button is shown for first time after being hidden at startup
        self:HookMinimapButton()
    else
        LDBIcon:Hide("!Koality-of-Life")
        KOL.db.profile.minimap.hide = true
    end
end

-- LDB visibility control
-- Now supports dynamic enable/disable for ChocolateBar!
function LDBModule:UpdateLDBVisibility()
    local showLDB = KOL.db.profile.showLDBPlugin
    if showLDB == nil then showLDB = true end

    if showLDB then
        -- ENABLE LDB Plugin
        if not dataObject then
            -- Create it now (late registration)
            CreateDataObject()

            -- Register with LibDBIcon for minimap button
            if dataObject then
                LDBIcon:Register("!Koality-of-Life", dataObject, KOL.db.profile.minimap)
                self:UpdateMinimapVisibility()
                self:HookMinimapButton()
            end
        end

        -- Enable in ChocolateBar if available
        if ChocolateBar and ChocolateBar.EnableDataObject and dataObject then
            ChocolateBar:EnableDataObject("!Koality-of-Life", dataObject)
            KOL:PrintTag("LDB Plugin enabled in ChocolateBar!")
            -- Re-hook the font since ChocolateBar may recreate the frame
            chocolateBarFontHooked = false
            self:HookChocolateBarFont()
        elseif dataObject then
            KOL:PrintTag("LDB Plugin enabled!")
        end
    else
        -- DISABLE LDB Plugin
        -- Use ChocolateBar's API if available (no reload needed!)
        if ChocolateBar and ChocolateBar.DisableDataObject then
            ChocolateBar:DisableDataObject("!Koality-of-Life")
            KOL:PrintTag("LDB Plugin disabled in ChocolateBar!")
        else
            -- Other display addons don't have a disable API - need reload
            KOL:PrintTag("LDB Plugin will be hidden after reload. Type /rl to reload now.")
        end
    end
end

-- LDB Text update (for dynamic text like Speed display)
local ldbTextUpdateFrame = nil

-- ============================================================================
-- LDB Text Cache System (Performance optimization)
-- ============================================================================
-- Cache values to avoid rebuilding text string when nothing changed
local ldbTextCache = {
    lastSpeedValue = nil,      -- Last speed % value
    lastLimitValue = nil,      -- Last limit damage setting
    lastRacialValue = nil,     -- Last racial setting
    lastADRValue = nil,        -- Last auto dungeon reset setting
    lastXPValue = nil,         -- Last XP percentage
    lastRestedValue = nil,     -- Last rested XP percentage
    lastREPValue = nil,        -- Last REP percentage
    lastDisplayText = nil,     -- Last built display text
}

-- Get current raw values for comparison (cheap operations)
local function GetCurrentLDBValues()
    local profile = KOL.db.profile

    -- Speed value (from Scoots module)
    local speedValue = nil
    if profile.ldbShowSpeed ~= false then
        speedValue = KOL.ReturnSpeedText and KOL:ReturnSpeedText(false) or nil
    end

    -- Limit value
    local limitValue = profile.limitDamage or false

    -- Racial value
    local racialValue = KOL.GetCurrentRacial and KOL:GetCurrentRacial() or "Unknown"

    -- ADR value
    local adrValue = profile.autoDungeonReset or false

    -- XP value (percentage) and rested value
    local xpValue = nil
    local restedValue = nil
    if profile.ldbShowXP then
        local currentXP = UnitXP("player") or 0
        local maxXP = UnitXPMax("player") or 1
        xpValue = math.floor((currentXP / maxXP) * 100)

        -- Also track rested XP
        local restedXP = GetXPExhaustion() or 0
        if restedXP > 0 and maxXP > 0 then
            restedValue = math.floor((restedXP / maxXP) * 100)
        end
    end

    -- REP value (percentage of watched faction)
    local repValue = nil
    if profile.ldbShowREP then
        local name, standing, minRep, maxRep, currentRep = GetWatchedFactionInfo()
        if name and maxRep > minRep then
            repValue = math.floor(((currentRep - minRep) / (maxRep - minRep)) * 100)
        end
    end

    return speedValue, limitValue, racialValue, adrValue, xpValue, restedValue, repValue
end

-- Convert {r, g, b} color table to hex color code (e.g. "00FF00")
local function ColorToHex(colorTable, fallback)
    if not colorTable then return fallback end
    return string.format("%02X%02X%02X",
        math.floor((colorTable.r or 0) * 255 + 0.5),
        math.floor((colorTable.g or 0) * 255 + 0.5),
        math.floor((colorTable.b or 0) * 255 + 0.5))
end

-- Build a progress bar string (10 characters)
local function BuildProgressBar(percent, activeColorHex, baseColorHex, bracketColorHex, barChar)
    local BAR_LENGTH = 10
    local filledCount = math.floor((percent / 100) * BAR_LENGTH + 0.5)
    if filledCount > BAR_LENGTH then filledCount = BAR_LENGTH end
    if filledCount < 0 then filledCount = 0 end

    local emptyCount = BAR_LENGTH - filledCount
    local char = barChar or "═"

    local bar = ""
    if filledCount > 0 then
        bar = bar .. "|cFF" .. activeColorHex .. string.rep(char, filledCount) .. "|r"
    end
    if emptyCount > 0 then
        bar = bar .. "|cFF" .. baseColorHex .. string.rep(char, emptyCount) .. "|r"
    end

    return "|cFF" .. bracketColorHex .. "[|r" .. bar .. "|cFF" .. bracketColorHex .. "]|r"
end

-- Build an XP progress bar with rested XP support (10 characters)
-- Shows: [current XP] [rested XP bonus] [empty]
local function BuildXPProgressBar(xpPercent, restedPercent, activeColorHex, restedColorHex, baseColorHex, bracketColorHex, barChar)
    local BAR_LENGTH = 10
    local char = barChar or "═"

    -- Calculate filled count for current XP
    local filledCount = math.floor((xpPercent / 100) * BAR_LENGTH + 0.5)
    if filledCount > BAR_LENGTH then filledCount = BAR_LENGTH end
    if filledCount < 0 then filledCount = 0 end

    -- Calculate rested count (rested XP extends from current XP position)
    -- restedPercent is based on how much of the remaining bar the rested covers
    local restedCount = 0
    if restedPercent > 0 then
        -- Rested XP shows where your XP could go with the bonus
        -- It starts from current XP and extends forward
        local restedEndPercent = xpPercent + restedPercent
        if restedEndPercent > 100 then restedEndPercent = 100 end
        local restedEndCount = math.floor((restedEndPercent / 100) * BAR_LENGTH + 0.5)
        restedCount = restedEndCount - filledCount
        if restedCount < 0 then restedCount = 0 end
    end

    -- Calculate empty count
    local emptyCount = BAR_LENGTH - filledCount - restedCount
    if emptyCount < 0 then emptyCount = 0 end

    local bar = ""
    if filledCount > 0 then
        bar = bar .. "|cFF" .. activeColorHex .. string.rep(char, filledCount) .. "|r"
    end
    if restedCount > 0 then
        bar = bar .. "|cFF" .. restedColorHex .. string.rep(char, restedCount) .. "|r"
    end
    if emptyCount > 0 then
        bar = bar .. "|cFF" .. baseColorHex .. string.rep(char, emptyCount) .. "|r"
    end

    return "|cFF" .. bracketColorHex .. "[|r" .. bar .. "|cFF" .. bracketColorHex .. "]|r"
end

-- Build the LDB display text based on current settings
local function BuildLDBDisplayText()
    local profile = KOL.db.profile

    -- Get display settings (defaults if not set)
    -- Speed defaults to true (like old behavior), others default to false
    local showSpeed = profile.ldbShowSpeed ~= false  -- nil or true = show
    local showSpeedLabel = profile.ldbShowSpeedLabel or false
    local showLimit = profile.ldbShowLimit or false
    local showLimitLabel = profile.ldbShowLimitLabel or false
    local showRacial = profile.ldbShowRacial or false
    local showRacialLabel = profile.ldbShowRacialLabel or false
    local showADR = profile.ldbShowADR or false
    local showADRLabel = profile.ldbShowADRLabel or false
    local showXP = profile.ldbShowXP or false
    local showXPLabel = profile.ldbShowXPLabel or false
    local showXPPercent = profile.ldbShowXPPercent ~= false
    local showREP = profile.ldbShowREP or false
    local showREPLabel = profile.ldbShowREPLabel or false
    local showREPPercent = profile.ldbShowREPPercent ~= false

    -- Get positions (defaults: speed=1, limit=2, racial=3, adr=4, xp=5, rep=6)
    local speedPos = profile.ldbSpeedPosition or 1
    local limitPos = profile.ldbLimitPosition or 2
    local racialPos = profile.ldbRacialPosition or 3
    local adrPos = profile.ldbADRPosition or 4
    local xpPos = profile.ldbXPPosition or 5
    local repPos = profile.ldbREPPosition or 6

    -- If nothing is enabled, show default
    if not showSpeed and not showLimit and not showRacial and not showADR and not showXP and not showREP then
        return "KoL"
    end

    -- Get bar colors (use rainbow if enabled, unless globally disabled)
    local useXPRainbow = profile.ldbXPBarRainbow and not profile.disableAllRainbow
    local useREPRainbow = profile.ldbREPBarRainbow and not profile.disableAllRainbow
    local xpActiveHex = useXPRainbow and GetRainbowHex() or ColorToHex(profile.ldbColorXPActive, "66CCFF")
    local xpBaseHex = ColorToHex(profile.ldbColorXPBase, "404040")
    local xpRestedHex = ColorToHex(profile.ldbColorXPRested, "6666CC")
    local repActiveHex = useREPRainbow and GetRainbowHex() or ColorToHex(profile.ldbColorREPActive, "9966FF")
    local repBaseHex = ColorToHex(profile.ldbColorREPBase, "404040")
    local bracketHex = ColorToHex(profile.ldbColorBracket, "808080")

    -- Build items with their positions
    local items = {}

    if showSpeed then
        local speedText = KOL:ReturnSpeedText(showSpeedLabel)
        if speedText and speedText ~= "" then
            table.insert(items, { pos = speedPos, text = speedText })
        end
    end

    if showLimit then
        local limitValue = profile.limitDamage or false
        local limitOnHex = ColorToHex(profile.ldbColorLimitOn, "00FF00")
        local limitOffHex = ColorToHex(profile.ldbColorLimitOff, "FF4444")
        local limitText = showLimitLabel and "LIMIT: " or ""
        limitText = limitText .. (limitValue and ("|cFF" .. limitOnHex .. "ON|r") or ("|cFF" .. limitOffHex .. "OFF|r"))
        table.insert(items, { pos = limitPos, text = limitText })
    end

    if showRacial then
        local currentRacial = KOL.GetCurrentRacial and KOL:GetCurrentRacial() or "Unknown"
        local racialHex = ColorToHex(profile.ldbColorRacial, "DDAAFF")
        local racialText = showRacialLabel and "RACIAL: " or ""
        racialText = racialText .. "|cFF" .. racialHex .. string.upper(currentRacial) .. "|r"
        table.insert(items, { pos = racialPos, text = racialText })
    end

    if showADR then
        local adrValue = profile.autoDungeonReset or false
        local adrOnHex = ColorToHex(profile.ldbColorADROn, "00FF00")
        local adrOffHex = ColorToHex(profile.ldbColorADROff, "FF4444")
        local enabledText = profile.ldbADREnabledText or "YES"
        local disabledText = profile.ldbADRDisabledText or "NO"
        local stateText = adrValue and ("|cFF" .. adrOnHex .. enabledText .. "|r") or ("|cFF" .. adrOffHex .. disabledText .. "|r")
        local adrText = showADRLabel and ("ADR: " .. stateText) or stateText
        table.insert(items, { pos = adrPos, text = adrText })
    end

    -- Hide XP bar at max level
    local playerLevel = UnitLevel("player")
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 80
    local isMaxLevel = playerLevel >= maxLevel

    if showXP and not isMaxLevel then
        local currentXP = UnitXP("player") or 0
        local maxXP = UnitXPMax("player") or 1
        local xpPercent = math.floor((currentXP / maxXP) * 100)

        -- Get rested XP (bonus XP available)
        local restedXP = GetXPExhaustion() or 0
        local restedPercent = 0
        if restedXP > 0 and maxXP > 0 then
            -- Rested XP shows as a percentage of the level bar
            restedPercent = math.floor((restedXP / maxXP) * 100)
        end

        local xpChar = profile.ldbXPCharacter or "═"
        local xpBar = BuildXPProgressBar(xpPercent, restedPercent, xpActiveHex, xpRestedHex, xpBaseHex, bracketHex, xpChar)
        local xpText = showXPLabel and "XP: " or ""
        xpText = xpText .. xpBar
        if showXPPercent then
            xpText = xpText .. " |cFFFFFF00" .. xpPercent .. "%|r"
        end
        table.insert(items, { pos = xpPos, text = xpText })
    end

    if showREP then
        local name, standing, minRep, maxRep, currentRep = GetWatchedFactionInfo()
        local repPercent = 0
        if name and maxRep > minRep then
            repPercent = math.floor(((currentRep - minRep) / (maxRep - minRep)) * 100)
        end
        local repChar = profile.ldbREPCharacter or "═"
        local repBar = BuildProgressBar(repPercent, repActiveHex, repBaseHex, bracketHex, repChar)
        local repText = showREPLabel and "REP: " or ""
        repText = repText .. repBar
        if showREPPercent then
            repText = repText .. " |cFFFFFF00" .. repPercent .. "%|r"
        end
        table.insert(items, { pos = repPos, text = repText })
    end

    -- Sort by position
    table.sort(items, function(a, b) return a.pos < b.pos end)

    -- Extract just the text
    local segments = {}
    for _, item in ipairs(items) do
        table.insert(segments, item.text)
    end

    -- Join with separator
    if #segments == 0 then
        return "KoL"
    end

    -- Get separator color from profile
    local sepColor = profile.ldbColorSeparator or {r = 0.4, g = 0.4, b = 0.4}
    local sepHex = string.format("|cFF%02X%02X%02X", sepColor.r * 255, sepColor.g * 255, sepColor.b * 255)

    return table.concat(segments, " " .. sepHex .. "|||r ")
end

-- Get LDB text with caching - only rebuilds if values changed
local function GetCachedLDBDisplayText()
    local speedValue, limitValue, racialValue, adrValue, xpValue, restedValue, repValue = GetCurrentLDBValues()

    -- Check if any value changed
    local changed = false
    if speedValue ~= ldbTextCache.lastSpeedValue then
        changed = true
    elseif limitValue ~= ldbTextCache.lastLimitValue then
        changed = true
    elseif racialValue ~= ldbTextCache.lastRacialValue then
        changed = true
    elseif adrValue ~= ldbTextCache.lastADRValue then
        changed = true
    elseif xpValue ~= ldbTextCache.lastXPValue then
        changed = true
    elseif restedValue ~= ldbTextCache.lastRestedValue then
        changed = true
    elseif repValue ~= ldbTextCache.lastREPValue then
        changed = true
    end

    -- If nothing changed and we have cached text, return it
    if not changed and ldbTextCache.lastDisplayText then
        return ldbTextCache.lastDisplayText, false  -- false = not rebuilt
    end

    -- Something changed - rebuild text
    local newText = BuildLDBDisplayText()

    -- Update cache
    ldbTextCache.lastSpeedValue = speedValue
    ldbTextCache.lastLimitValue = limitValue
    ldbTextCache.lastRacialValue = racialValue
    ldbTextCache.lastADRValue = adrValue
    ldbTextCache.lastXPValue = xpValue
    ldbTextCache.lastRestedValue = restedValue
    ldbTextCache.lastREPValue = repValue
    ldbTextCache.lastDisplayText = newText

    return newText, true  -- true = rebuilt
end

-- Check if any dynamic display is enabled (speed/XP/REP need continuous updates)
local function NeedsContinuousUpdate()
    local profile = KOL.db.profile
    -- Speed defaults to true, XP/REP also need updates when enabled
    return profile.ldbShowSpeed ~= false or profile.ldbShowXP or profile.ldbShowREP
end

function LDBModule:UpdateLDBText()
    if not dataObject then return end

    -- Build and set text
    local newText = BuildLDBDisplayText()
    dataObject.text = newText

    -- Sync cache so the ticker doesn't overwrite with stale text
    ldbTextCache.lastDisplayText = newText

    -- DEBUG: Print what we're setting
    if ldbSpeedDebug then
        print("|cFF00FFFF[LDB DEBUG]|r UpdateLDBText - setting text = '" .. tostring(newText) .. "' (fontHooked=" .. tostring(chocolateBarFontHooked) .. ")")
    end

    -- Start/stop update timer based on whether speed display is enabled
    if NeedsContinuousUpdate() then
        if not ldbTextUpdateFrame then
            ldbTextUpdateFrame = CreateFrame("Frame")
            ldbTextUpdateFrame.elapsed = 0
            ldbTextUpdateFrame.debugCount = 0
            ldbTextUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = self.elapsed + elapsed
                if self.elapsed < 0.5 then return end  -- Check every 0.5 seconds
                self.elapsed = 0

                -- Only update if we still need continuous updates
                if NeedsContinuousUpdate() and dataObject then
                    -- Use cached text - only rebuilds if values actually changed
                    local text, wasRebuilt = GetCachedLDBDisplayText()

                    -- Only update dataObject if text was actually rebuilt
                    if wasRebuilt then
                        dataObject.text = text
                    end

                    -- DEBUG: Print first few updates
                    if ldbSpeedDebug then
                        self.debugCount = (self.debugCount or 0) + 1
                        if self.debugCount <= 5 then
                            print("|cFF00FFFF[LDB DEBUG]|r OnUpdate #" .. self.debugCount .. " - rebuilt=" .. tostring(wasRebuilt) .. " text='" .. tostring(text) .. "'")
                        end
                        if text and (text:find("%%") or text:find("BASE")) then
                            print("|cFF00FF00[LDB DEBUG]|r Speed detected! Disabling debug.")
                            ldbSpeedDebug = false
                        end
                    end
                else
                    self:Hide()
                end
            end)
        end
        ldbTextUpdateFrame:Show()
    else
        -- Stop update timer if running
        if ldbTextUpdateFrame then
            ldbTextUpdateFrame:Hide()
        end
    end
end

-- ============================================================================
-- Text Retry Timer
-- Keeps trying to set the LDB text until ChocolateBar actually displays it
-- ============================================================================

local textRetryTimer = nil
local textRetryAttempts = 0
local textRetryMaxAttempts = 20  -- Max 20 attempts (2 seconds total at 0.1s intervals)

function LDBModule:StartTextRetryTimer()
    if not dataObject then return end

    -- Only needed if any display option is enabled
    if not NeedsContinuousUpdate() and not KOL.db.profile.ldbShowLimit and not KOL.db.profile.ldbShowRacial and not KOL.db.profile.ldbShowADR then
        return
    end

    textRetryAttempts = 0

    -- Create timer frame if needed
    if not textRetryTimer then
        textRetryTimer = CreateFrame("Frame")
        textRetryTimer.elapsed = 0
        textRetryTimer:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed < 0.1 then return end
            self.elapsed = 0

            textRetryAttempts = textRetryAttempts + 1

            -- Set the text with full formatting
            local newText = BuildLDBDisplayText()
            dataObject.text = newText

            -- Check if ChocolateBar frame exists and has our text
            local chocolateFrame = _G["Chocolate!Koality-of-Life"]
            local displayedText = chocolateFrame and chocolateFrame.text and chocolateFrame.text:GetText()

            -- Success check: displayed text contains expected content
            local success = displayedText and (
                displayedText:find("IDLE") or
                displayedText:find("BASE") or
                displayedText:find("%%") or
                displayedText:find("ON") or
                displayedText:find("OFF") or
                displayedText:find("KoL")
            )

            if success then
                -- It worked! Stop retrying
                KOL:DebugPrint("LDB: Text retry succeeded after " .. textRetryAttempts .. " attempts", 2)
                ldbSpeedDebug = false
                self:Hide()
                return
            end

            -- Give up after max attempts
            if textRetryAttempts >= textRetryMaxAttempts then
                KOL:DebugPrint("LDB: Text retry gave up after " .. textRetryAttempts .. " attempts", 1)
                self:Hide()
                return
            end
        end)
    end

    textRetryTimer:Show()
end

-- ============================================================================
-- ChocolateBar Font Hack
-- Forces our ligatures font on the ChocolateBar frame for proper glyph rendering
-- ============================================================================

function LDBModule:HookChocolateBarFont()
    if chocolateBarFontHooked then return end

    chocolateBarHookAttempts = chocolateBarHookAttempts + 1

    -- The ChocolateBar frame is named "Chocolate" .. pluginName
    local frameName = "Chocolate!Koality-of-Life"

    -- Try to find the frame
    local chocolateFrame = _G[frameName]

    if chocolateFrame and chocolateFrame.text then
        -- Found it - override the font to our ligatures font
        local fontSize = select(2, chocolateFrame.text:GetFont()) or 12

        -- Verify CHAR_LIGATURESFONT exists
        if not CHAR_LIGATURESFONT then
            KOL:PrintTag("|cFFFF0000ERROR:|r CHAR_LIGATURESFONT is nil! Font hook cannot apply.")
            return
        end

        chocolateFrame.text:SetFont(CHAR_LIGATURESFONT, fontSize, CHAR_LIGATURESOUTLINE or "OUTLINE")
        chocolateBarFontHooked = true
        KOL:DebugPrint("LDB: ChocolateBar font hack applied after " .. chocolateBarHookAttempts .. " attempts", 1)

        -- Also hook the Update function to re-apply our font when ChocolateBar updates
        if chocolateFrame.Update then
            local origUpdate = chocolateFrame.Update
            chocolateFrame.Update = function(self, attr, value, name)
                origUpdate(self, attr, value, name)
                -- Re-apply our font after any update
                if self.text then
                    local size = select(2, self.text:GetFont()) or 12
                    self.text:SetFont(CHAR_LIGATURESFONT, size, CHAR_LIGATURESOUTLINE or "OUTLINE")
                end
            end
        end

        -- NOW that font is ready, trigger text update to use styled glyphs
        self:UpdateLDBText()
    else
        -- Frame not created yet, try again shortly
        if chocolateBarHookAttempts < chocolateBarHookMaxAttempts then
            C_Timer.After(0.5, function()
                self:HookChocolateBarFont()
            end)
        else
            -- Give up after max attempts - frame never appeared
            KOL:DebugPrint("LDB: ChocolateBar font hack gave up after " .. chocolateBarHookAttempts .. " attempts - frame not found", 1)
        end
    end
end

-- Hook minimap button for custom menu and square appearance
function LDBModule:HookMinimapButton()
    C_Timer.After(0.1, function()
        local button = LDBIcon.objects and LDBIcon.objects["!Koality-of-Life"]
        if button and not button.kolHooked then
            button.kolHooked = true
            local iconTexture = button.icon or button.Icon

            -- ============================================================
            -- CUSTOM DRAG BEHAVIOR - Square edge positioning
            -- ============================================================
            local EDGE_OFFSET = 10  -- Distance from minimap edge to button center
            local currentAngle = KOL.db.profile.minimap.minimapPos or 220

            -- Position button along square edge at given angle
            -- Store at module level so it can be called on zone changes etc.
            local function PositionAtAngle(angle)
                local rads = math.rad(angle)
                local cos_a = math.cos(rads)
                local sin_a = math.sin(rads)

                -- Get minimap half-size (square minimap)
                local halfSize = (Minimap:GetWidth() / 2) + EDGE_OFFSET

                -- Calculate intersection with square boundary
                local abs_cos = math.abs(cos_a)
                local abs_sin = math.abs(sin_a)
                local t

                if abs_cos < 0.001 then
                    t = halfSize / abs_sin
                elseif abs_sin < 0.001 then
                    t = halfSize / abs_cos
                elseif abs_cos > abs_sin then
                    t = halfSize / abs_cos
                else
                    t = halfSize / abs_sin
                end

                local x = cos_a * t
                local y = sin_a * t

                button:ClearAllPoints()
                button:SetPoint("CENTER", Minimap, "CENTER", x, y)
            end

            -- Store function at module level for external access
            LDBModule.PositionMinimapButton = function()
                local angle = KOL.db.profile.minimap.minimapPos or 220
                currentAngle = angle
                PositionAtAngle(angle)
            end

            -- Calculate expected position for a given angle (for verification)
            local function GetExpectedPosition(angle)
                local rads = math.rad(angle)
                local cos_a = math.cos(rads)
                local sin_a = math.sin(rads)
                local halfSize = (Minimap:GetWidth() / 2) + EDGE_OFFSET
                local abs_cos = math.abs(cos_a)
                local abs_sin = math.abs(sin_a)
                local t
                if abs_cos < 0.001 then
                    t = halfSize / abs_sin
                elseif abs_sin < 0.001 then
                    t = halfSize / abs_cos
                elseif abs_cos > abs_sin then
                    t = halfSize / abs_cos
                else
                    t = halfSize / abs_sin
                end
                return cos_a * t, sin_a * t
            end

            -- Self-canceling position verifier
            -- Checks position periodically and fixes if wrong, cancels when stable
            local positionTicker = nil
            local correctCount = 0
            local POSITION_TOLERANCE = 2  -- pixels
            local REQUIRED_CORRECT_CHECKS = 3

            LDBModule.StartPositionVerifier = function()
                -- Cancel existing ticker if any
                if positionTicker then
                    positionTicker:Cancel()
                    positionTicker = nil
                end
                correctCount = 0

                -- Immediately fix position (don't wait for first tick)
                local angle = KOL.db.profile.minimap.minimapPos or 220
                currentAngle = angle
                PositionAtAngle(angle)

                positionTicker = C_Timer.NewTicker(0.2, function()
                    if not button or not button:IsShown() then
                        return
                    end

                    local angle = KOL.db.profile.minimap.minimapPos or 220
                    local expectedX, expectedY = GetExpectedPosition(angle)
                    local mx, my = Minimap:GetCenter()
                    local bx, by = button:GetCenter()

                    if mx and my and bx and by then
                        local actualOffsetX = bx - mx
                        local actualOffsetY = by - my
                        local diffX = math.abs(actualOffsetX - expectedX)
                        local diffY = math.abs(actualOffsetY - expectedY)

                        if diffX <= POSITION_TOLERANCE and diffY <= POSITION_TOLERANCE then
                            -- Position is correct
                            correctCount = correctCount + 1
                            if correctCount >= REQUIRED_CORRECT_CHECKS then
                                -- Position has been stable, cancel ticker
                                positionTicker:Cancel()
                                positionTicker = nil
                                KOL:DebugPrint("LDB: Minimap button position verified, ticker stopped", 3)
                            end
                        else
                            -- Position is wrong, fix it
                            correctCount = 0
                            currentAngle = angle
                            PositionAtAngle(angle)
                            KOL:DebugPrint("LDB: Fixed minimap button position (off by " .. string.format("%.1f, %.1f", diffX, diffY) .. ")", 3)
                        end
                    end
                end)

                KOL:DebugPrint("LDB: Started position verifier ticker", 3)
            end

            LDBModule.StopPositionVerifier = function()
                if positionTicker then
                    positionTicker:Cancel()
                    positionTicker = nil
                    KOL:DebugPrint("LDB: Position verifier stopped manually", 3)
                end
            end

            -- Apply initial position
            PositionAtAngle(currentAngle)

            -- Start position verifier on initial setup
            LDBModule.StartPositionVerifier()

            -- Hook OnShow to re-apply position whenever button becomes visible
            button:HookScript("OnShow", function()
                C_Timer.After(0, function()
                    PositionAtAngle(currentAngle)
                end)
                -- Restart verifier when button shows
                LDBModule.StartPositionVerifier()
            end)

            -- Block ALL of LibDBIcon's SetPoint and ClearAllPoints calls
            -- We handle positioning entirely ourselves
            local origSetPoint = button.SetPoint
            local origClearAllPoints = button.ClearAllPoints
            local allowPositioning = false  -- Flag to allow our own positioning calls

            button.ClearAllPoints = function(self)
                if allowPositioning then
                    origClearAllPoints(self)
                end
                -- Block LibDBIcon's ClearAllPoints when allowPositioning is false
            end

            button.SetPoint = function(self, ...)
                if allowPositioning then
                    origSetPoint(self, ...)
                end
                -- Block LibDBIcon's SetPoint when allowPositioning is false
            end

            -- Wrap PositionAtAngle to set the allow flag around the original call
            local origPositionAtAngle = PositionAtAngle
            PositionAtAngle = function(angle)
                allowPositioning = true
                origPositionAtAngle(angle)
                allowPositioning = false
            end

            -- Completely replace drag behavior
            local isDragging = false

            -- Remove LibDBIcon's drag scripts entirely
            button:SetScript("OnDragStart", function(self)
                isDragging = true
                self:SetScript("OnUpdate", function(self)
                    -- Get cursor position and calculate angle to minimap center
                    local cx, cy = GetCursorPosition()
                    local scale = UIParent:GetEffectiveScale()
                    cx, cy = cx / scale, cy / scale

                    local mx, my = Minimap:GetCenter()
                    if mx and my then
                        local dx, dy = cx - mx, cy - my
                        currentAngle = math.deg(math.atan2(dy, dx))
                        PositionAtAngle(currentAngle)
                    end
                end)
            end)

            button:SetScript("OnDragStop", function(self)
                isDragging = false
                self:SetScript("OnUpdate", nil)
                -- Save the angle
                KOL.db.profile.minimap.minimapPos = currentAngle
            end)

            -- ============================================================
            -- Make button SQUARE instead of round
            -- ============================================================
            -- Hide ALL textures except the icon (removes circular border/overlay/mask)
            local regions = {button:GetRegions()}
            for _, region in ipairs(regions) do
                if region:GetObjectType() == "Texture" and region ~= iconTexture then
                    region:Hide()
                end
            end

            -- Also hide named elements if they exist
            if button.overlay then button.overlay:Hide() end
            if button.border then button.border:Hide() end
            if button.background then button.background:Hide() end

            -- Use backdrop for square look with border
            if button.SetBackdrop then
                button:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    tile = false,
                    edgeSize = 1,
                    insets = { left = 0, right = 0, top = 0, bottom = 0 }
                })
                button:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
                button:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            end

            -- Make the icon fill the square
            if iconTexture then
                iconTexture:Show()  -- Make sure icon is visible
                iconTexture:ClearAllPoints()
                iconTexture:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
                iconTexture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
                iconTexture:SetTexCoord(0, 1, 0, 1)  -- Full texture, no circular crop
            end

            -- ============================================================
            -- Hover effects with click action tooltip
            -- ============================================================
            button:SetScript("OnEnter", function(self)
                -- Hover effect
                if iconTexture then
                    iconTexture:SetVertexColor(1.4, 1.2, 0.6, 1)
                end
                if button.SetBackdropBorderColor then
                    button:SetBackdropBorderColor(0.8, 0.7, 0.3, 1)
                end
            end)

            button:SetScript("OnLeave", function(self)
                -- Reset hover effect
                if iconTexture then
                    iconTexture:SetVertexColor(1, 1, 1, 1)
                end
                if button.SetBackdropBorderColor then
                    button:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                end
            end)

            -- Click with modifier support
            button:SetScript("OnClick", function(self, btn)

                -- Check for modifier keys first
                if IsShiftKeyDown() then
                    ReloadUI()
                    return
                elseif IsControlKeyDown() and btn == "RightButton" then
                    KOL:ToggleAutoDungeonReset()
                    return
                elseif IsControlKeyDown() then
                    KOL:ToggleLimitDamage()
                    return
                elseif IsAltKeyDown() then
                    KOL:ToggleRacial()
                    return
                end

                -- Normal click actions
                if btn == "LeftButton" then
                    LDBModule:ToggleMenu(self)
                elseif btn == "RightButton" then
                    -- Toggle config panel
                    local ACD = LibStub("AceConfigDialog-3.0")
                    if ACD.OpenFrames and ACD.OpenFrames["KoalityOfLife"] then
                        ACD:Close("KoalityOfLife")
                    else
                        KOL:OpenConfig()
                    end
                end
            end)

            -- Apply saved size
            local size = KOL.db.profile.minimapButtonSize or 32
            button:SetSize(size, size)

            KOL:DebugPrint("LDB: Minimap button hooked with square style and custom menu", 2)
        end
    end)
end

-- Update minimap button size from config
function LDBModule:UpdateMinimapButtonSize()
    local button = LDBIcon.objects and LDBIcon.objects["!Koality-of-Life"]
    if button then
        local size = KOL.db.profile.minimapButtonSize or 32
        button:SetSize(size, size)
    end
end

-- Check if LDB plugin was created (for click/menu handlers)
function LDBModule:IsLDBHidden()
    return dataObject == nil
end

-- Emergency force-close function (accessible via /kol closemenu)
function LDBModule:ForceCloseMenu()
    -- Force hide everything with maximum prejudice
    if mainTooltip then
        mainTooltip:Hide()
        mainTooltip = nil
    end

    -- Hide all active tooltips
    for i = #activeTooltips, 1, -1 do
        local t = activeTooltips[i]
        if t then
            t:Hide()
            t:SetParent(nil)
        end
    end
    wipe(activeTooltips)

    -- Hide click catcher
    if clickCatcher then
        clickCatcher:Hide()
    end

    -- Clear tooltip pool
    for _, t in ipairs(tooltipPool) do
        if t then
            t:Hide()
            t:SetParent(nil)
        end
    end
    wipe(tooltipPool)

    KOL:PrintTag("LDB menu force-closed")
end

-- ============================================================================
-- Global XP/REP Bar Visibility Control
-- ============================================================================

-- Cache for original visibility states (so we can restore if user toggles off)
local globalBarStates = {
    xpBarWasEnabled = nil,
    repBarWasEnabled = nil,
}

-- Apply global XP bar visibility based on user setting
function LDBModule:ApplyGlobalXPBarVisibility()
    local profile = KOL.db and KOL.db.profile
    if not profile then return end

    local shouldHide = profile.hideGlobalXPBar

    -- Handle default WoW XP bar
    if MainMenuExpBar then
        if shouldHide then
            MainMenuExpBar:Hide()
            MainMenuExpBar:SetScript("OnShow", function(self) self:Hide() end)
        else
            MainMenuExpBar:SetScript("OnShow", nil)
            local level = UnitLevel("player")
            local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 80
            if level < maxLevel then
                MainMenuExpBar:Show()
            end
        end
    end

    -- Handle ExhaustionTick (the rested state indicator)
    if ExhaustionTick then
        if shouldHide then
            ExhaustionTick:Hide()
        else
            local level = UnitLevel("player")
            local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 80
            if level < maxLevel then
                ExhaustionTick:Show()
            end
        end
    end

    -- Handle ElvUI if present - toggle the actual setting
    if ElvUI and ElvUI[1] then
        local E = ElvUI[1]
        if E.db and E.db.databars and E.db.databars.experience then
            -- Save original state on first run
            if globalBarStates.xpBarWasEnabled == nil then
                globalBarStates.xpBarWasEnabled = E.db.databars.experience.enable
            end

            -- Toggle the setting
            E.db.databars.experience.enable = not shouldHide

            -- Refresh ElvUI databars
            local DB = E:GetModule("DataBars", true)
            if DB then
                if DB.UpdateAll then
                    pcall(function() DB:UpdateAll() end)
                elseif DB.EnableDisable_ExperienceBar then
                    pcall(function() DB:EnableDisable_ExperienceBar() end)
                end
            end
        end
    end

    KOL:DebugPrint("Global XP Bar: " .. (shouldHide and "DISABLED" or "ENABLED"), 2)
end

-- Apply global REP bar visibility based on user setting
function LDBModule:ApplyGlobalREPBarVisibility()
    local profile = KOL.db and KOL.db.profile
    if not profile then return end

    local shouldHide = profile.hideGlobalREPBar

    -- Handle default WoW reputation bar
    if ReputationWatchBar then
        if shouldHide then
            ReputationWatchBar:Hide()
            ReputationWatchBar:SetScript("OnShow", function(self) self:Hide() end)
        else
            ReputationWatchBar:SetScript("OnShow", nil)
            local name = GetWatchedFactionInfo()
            if name then
                ReputationWatchBar:Show()
            end
        end
    end

    -- Handle ElvUI if present - toggle the actual setting
    if ElvUI and ElvUI[1] then
        local E = ElvUI[1]
        if E.db and E.db.databars and E.db.databars.reputation then
            -- Save original state on first run
            if globalBarStates.repBarWasEnabled == nil then
                globalBarStates.repBarWasEnabled = E.db.databars.reputation.enable
            end

            -- Toggle the setting
            E.db.databars.reputation.enable = not shouldHide

            -- Refresh ElvUI databars
            local DB = E:GetModule("DataBars", true)
            if DB then
                if DB.UpdateAll then
                    pcall(function() DB:UpdateAll() end)
                elseif DB.EnableDisable_ReputationBar then
                    pcall(function() DB:EnableDisable_ReputationBar() end)
                end
            end
        end
    end

    KOL:DebugPrint("Global REP Bar: " .. (shouldHide and "DISABLED" or "ENABLED"), 2)
end

-- Apply both visibility settings (called on init)
function LDBModule:ApplyGlobalBarVisibility()
    self:ApplyGlobalXPBarVisibility()
    self:ApplyGlobalREPBarVisibility()
end

-- ============================================================================
-- Register initialization with core addon load
-- ============================================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ZONE_CHANGED_INDOORS")
frame:SetScript("OnEvent", function(self, event)
    -- PLAYER_LOGIN fires on initial login only
    -- PLAYER_ENTERING_WORLD fires on login AND /reload
    -- We use both to ensure we initialize in all cases
    if event == "PLAYER_LOGIN" then
        C_Timer.After(0.5, function()
            if KOL and KOL.db then
                LDBModule:Initialize()
            end
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- On reload, PLAYER_LOGIN doesn't fire, so we need this
        -- Use a slightly longer delay to let ChocolateBar initialize first
        C_Timer.After(1.0, function()
            if KOL and KOL.db then
                -- Reset the font hook flag so it can re-apply after reload
                chocolateBarFontHooked = false
                chocolateBarHookAttempts = 0
                LDBModule:Initialize()
            end
        end)
        -- Start position verifier after entering world (self-cancels when stable)
        C_Timer.After(0.1, function()
            if LDBModule.StartPositionVerifier then
                LDBModule.StartPositionVerifier()
            end
        end)
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
        -- Start position verifier after zone changes (self-cancels when stable)
        -- Small delay to ensure we run AFTER LibDBIcon finishes any repositioning
        C_Timer.After(0.1, function()
            if LDBModule.StartPositionVerifier then
                LDBModule.StartPositionVerifier()
            end
        end)
    end
end)
