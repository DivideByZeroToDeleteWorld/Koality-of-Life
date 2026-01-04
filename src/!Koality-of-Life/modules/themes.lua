-- ============================================================================
-- !Koality-of-Life: Themes Module
-- ============================================================================
-- Simple theme management system for UI color theming
-- ============================================================================

local KOL = KoalityOfLife

-- ============================================================================
-- Themes Module
-- ============================================================================

KOL.Themes = {}
local Themes = KOL.Themes

-- ============================================================================
-- Default Theme: Furwin
-- ============================================================================

local defaultTheme = {
    name = "Furwin",
    author = "Zero",
    description = "Default Furwin theme with vibrant colors",
    version = "1.0",
    colors = {
        -- GLOBAL FALLBACK COLORS
        GlobalBG = "051428",
        GlobalBorder = "666666",
        GlobalTitleBG = "141414",
        GlobalBodyBG = "030303",

        -- FRAME-SPECIFIC COLORS
        WatchFrameTitleBG = "141414",
        WatchFrameBodyBG = "030303",
        WatchFrameBorder = "666666",
        DebugTitleBG = "141414",
        DebugBodyBG = "030303",
        DebugBorder = "666666",
        BatchTitleBG = "141414",
        BatchBodyBG = "030303",
        BatchBorder = "666666",
        BindsTitleBG = "141414",
        BindsBodyBG = "030303",
        BindsBorder = "666666",
        TrackerTitleBG = "141414",
        TrackerBodyBG = "030303",
        TrackerBorder = "666666",

        -- BUTTON COLORS
        ButtonNormal = "CC6666",
        ButtonHover = "E68080",
        ButtonPressed = "FF9999",
        ButtonBorder = "333333",

        -- CLOSE BUTTON COLORS
        CloseButtonBG = "262626",
        CloseButtonBorder = "666666",
        CloseButtonText = "FF6666",
        CloseButtonHoverBG = "404040",
        CloseButtonHoverBorder = "FF8080",
        CloseButtonHoverText = "FF9999",

        -- SCROLLBAR COLORS (matching Furwin dark theme)
        ScrollbarTrackBG = "0D0D0D",
        ScrollbarTrackBorder = "333333",
        ScrollbarThumbBG = "4D4D4D",
        ScrollbarThumbBorder = "666666",
        ScrollbarButtonBG = "262626",
        ScrollbarButtonBorder = "404040",
        ScrollbarButtonArrow = "999999",

        -- CONTENT AREA COLORS
        ContentAreaBG = "030303",
        ContentAreaBorder = "404040",

        -- SELECTION/HIGHLIGHT COLORS
        SelectedBG = "E6E6B3",
        SelectedBorder = "B3B390",
        HighlightBG = "CCCC99",
        HighlightBorder = "999966",

        -- PRIORITY COLORS
        PriorityCritical = "FF1A1A",
        PriorityHigh = "FF8000",
        PriorityMedium = "FFCC00",
        PriorityLow = "1AE633",
        PriorityNormal = "66667F",

        -- TEXT COLORS
        TextPrimary = "FFFF99",
        TextSecondary = "CCCCCC",
        TextTitle = "FFFF99",
        TextDisabled = "999999",

        -- DEBUG LEVEL COLORS
        DebugLevel1 = "FF4D4D",
        DebugLevel2 = "FFB34D",
        DebugLevel3 = "FFFF99",
        DebugLevel4 = "99CCFF",
        DebugLevel5 = "808080",

        -- UNLIMITED CUSTOM COLORS
        Color1 = "FF00FF",
        Color2 = "FF00FF",
        Color3 = "FF00FF",
        Color4 = "FF00FF",

        -- LEGACY COLOR SET
        RED = "FF1A1A",
        BLUE = "1A4DFF",
        SKY_BLUE = "3399FF",
        PURPLE = "B31AE6",
        GREEN = "1AE633",
        PINK = "FF4DB3",
        WHITE = "E6E6E6",
        WINTER = "99CCFF",
        GREY = "66667F",
        ORANGE = "FF8000",
        SELECTED = "FF9933",
        UNSELECTED = "E0E0E0"
    }
}

-- ============================================================================
-- Theme Database Structure
-- ============================================================================

-- Initialize theme database if not exists
local function InitializeThemeDatabase()
    if not KOL.db or not KOL.db.profile then
        return false
    end
    
    if not KOL.db.profile.themes then
        KOL.db.profile.themes = {
            active = "Furwin",
            themes = {}
        }
    end
    return true
end

-- ============================================================================
-- Theme Management Functions
-- ============================================================================

-- Register a new theme
function Themes:RegisterTheme(themeData)
    if not themeData or not themeData.name then
        return false
    end
    
    if not InitializeThemeDatabase() then
        return false
    end
    
    KOL.db.profile.themes.themes[themeData.name] = themeData
    return true
end

-- Get theme data
function Themes:GetTheme(themeName)
    if not InitializeThemeDatabase() then
        return nil
    end
    
    themeName = themeName or KOL.db.profile.themes.active
    return KOL.db.profile.themes.themes[themeName]
end

-- Set active theme
function Themes:SetActiveTheme(themeName)
    if not InitializeThemeDatabase() then
        return false
    end
    
    if not themeName or not KOL.db.profile.themes.themes[themeName] then
        return false
    end
    
    KOL.db.profile.themes.active = themeName
    return true
end

-- Get active theme name
function Themes:GetActiveTheme()
    if not InitializeThemeDatabase() then
        return "Furwin"
    end
    return KOL.db.profile.themes.active
end

-- Get list of available themes
function Themes:GetThemeList()
    if not InitializeThemeDatabase() then
        return {["Furwin"] = "Furwin"}
    end
    
    local themeList = {}
    for name, theme in pairs(KOL.db.profile.themes.themes) do
        themeList[name] = name
    end
    return themeList
end

-- Get theme color with fallback
function Themes:GetThemeColor(colorPath, fallback)
    if not InitializeThemeDatabase() then
        return fallback
    end
    
    local theme = self:GetTheme()
    if theme and theme.colors and theme.colors[colorPath] then
        return theme.colors[colorPath]
    end
    return fallback
end

-- Get theme color as RGB object for UI components
function Themes:GetUIThemeColor(colorPath, fallback)
    local color = self:GetThemeColor(colorPath, fallback)
    if not color then
        return {r = 1, g = 1, b = 1, a = 1}
    end
    
    -- Check if it's already an RGB table
    if type(color) == "table" and color.r and color.g and color.b then
        return color
    end
    
    -- Check if it's a hex string and convert
    if type(color) == "string" then
        local r = tonumber(color:sub(1, 2), 16) / 255
        local g = tonumber(color:sub(3, 4), 16) / 255
        local b = tonumber(color:sub(5, 6), 16) / 255
        return {r = r, g = g, b = b, a = 1}
    end
    
    -- Fallback
    return {r = 1, g = 1, b = 1, a = 1}
end

-- Count available themes
function Themes:CountThemes()
    if not InitializeThemeDatabase() then
        return 1
    end
    
    local count = 0
    for _ in pairs(KOL.db.profile.themes.themes) do
        count = count + 1
    end
    return count
end

-- ============================================================================
-- Import/Export System
-- ============================================================================

-- Export theme to compact string format
function Themes:ExportTheme(themeName)
    local theme = self:GetTheme(themeName)
    if not theme then
        return nil, "Theme not found: " .. tostring(themeName)
    end
    
    local parts = {
        "KOL_THEME",
        theme.version or "1.0",
        theme.name or "",
        theme.author or "",
        theme.description or ""
    }
    
    -- Add all color settings
    for key, value in pairs(theme.colors or {}) do
        table.insert(parts, key .. "=" .. value)
    end
    
    table.insert(parts, "END_THEME")
    return table.concat(parts, "|")
end

-- Import theme from compact string format
function Themes:ImportTheme(themeString)
    if not themeString or not themeString:match("^KOL_THEME") then
        return false, "Invalid theme format"
    end
    
    local parts = {}
    for part in themeString:gmatch("[^|]+") do
        table.insert(parts, part)
    end
    
    -- Parse header
    if #parts < 6 then
        return false, "Invalid theme header"
    end
    
    local theme = {
        version = parts[2],
        name = parts[3],
        author = parts[4],
        description = parts[5],
        colors = {}
    }
    
    -- Parse color data
    for i = 6, #parts do
        local part = parts[i]
        if part == "END_THEME" then
            break
        end
        
        local key, value = part:match("^(.-)=(.+)$")
        if key and value then
            theme.colors[key] = value
        end
    end
    
    -- Register theme
    if self:RegisterTheme(theme) then
        return true, theme.name
    else
        return false, "Failed to register imported theme"
    end
end

-- ============================================================================
-- Initialization
-- ============================================================================

-- Initialize module
function Themes:Initialize()
    -- Register default theme if not exists
    if not KOL.db.profile.themes.themes["Furwin"] then
        self:RegisterTheme(defaultTheme)
    end
    
    -- Ensure active theme exists
    if not KOL.db.profile.themes.themes[KOL.db.profile.themes.active] then
        KOL.db.profile.themes.active = "Furwin"
    end
end

-- Auto-initialize if KOL and database are already available
if KOL and KOL.db and KOL.db.profile then
    Themes:Initialize()
end