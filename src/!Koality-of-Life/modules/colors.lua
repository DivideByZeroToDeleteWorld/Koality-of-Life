-- ============================================================================
-- !Koality-of-Life: Colors Module
-- ============================================================================
-- Unified color library for the entire addon
-- Provides standard colors, pastel colors, and user customization
-- ============================================================================

local KOL = KoalityOfLife

-- ============================================================================
-- Colors Module
-- ============================================================================

KOL.Colors = {}
local Colors = KOL.Colors

-- ============================================================================
-- Standard Color Palette (used by color functions like RED(), GREEN(), etc.)
-- ============================================================================

Colors.STANDARD = {
    RED = "FF0000",
    GREEN = "00FF00",
    BLUE = "0000FF",
    YELLOW = "FFFF00",
    ORANGE = "FF8800",
    PURPLE = "8800FF",
    CYAN = "00FFFF",
    PINK = "FF00FF",
    WHITE = "FFFFFF",
    GRAY = "888888",
    PASTEL_RED = "FF6B6B",
    PASTEL_PINK = "FFB6C1",
    PASTEL_YELLOW = "FFFF99",
}

-- ============================================================================
-- Pastel Color Palette (RGB arrays for UI rendering)
-- ============================================================================

Colors.PASTEL = {
    -- Basic palette
    RED = {1, 0.6, 0.6},
    ORANGE = {1, 0.8, 0.6},
    YELLOW = {1, 1, 0.7},
    GREEN = {0.7, 1, 0.7},
    CYAN = {0.7, 1, 1},
    BLUE = {0.7, 0.8, 1},
    PURPLE = {0.9, 0.7, 1},
    PINK = {1, 0.7, 0.9},

    -- Extended palette
    MINT = {0.7, 1, 0.85},
    LAVENDER = {0.85, 0.8, 1},
    PEACH = {1, 0.85, 0.7},
    SKY = {0.7, 0.9, 1},
    ROSE = {1, 0.75, 0.8},
    LIME = {0.85, 1, 0.7},
    CORAL = {1, 0.8, 0.75},
    AQUA = {0.75, 0.95, 0.9},
    EASTER_GREEN = {0.75, 1, 0.75},  -- Light spring green for completed groups

    -- Neutral tones
    CREAM = {1, 0.98, 0.9},
    IVORY = {1, 1, 0.94},
    PEARL = {0.95, 0.95, 0.95},
}

-- ============================================================================
-- Nuclear Color Palette (RGB objects for vibrant UI colors)
-- ============================================================================

Colors.NUCLEAR = {
    RED = {r = 1.0, g = 0.1, b = 0.1},
    BLUE = {r = 0.1, g = 0.3, b = 1.0},
    SKY_BLUE = {r = 0.2, g = 0.6, b = 1.0},
    PURPLE = {r = 0.7, g = 0.1, b = 0.9},
    GREEN = {r = 0.1, g = 0.9, b = 0.2},
    PINK = {r = 1.0, g = 0.3, b = 0.7},
    WHITE = {r = 0.9, g = 0.9, b = 0.9},
    WINTER = {r = 0.6, g = 0.8, b = 1.0},
    GREY = {r = 0.4, g = 0.4, b = 0.5},
    ORANGE = {r = 1.0, g = 0.5, b = 0.0},
}

-- ============================================================================
-- Selected Color States (for UI components)
-- ============================================================================

Colors.PASTEL_SELECTED = {r = 0.9, g = 0.9, b = 0.7}
Colors.NUCLEAR_SELECTED = {r = 1, g = 0.6, b = 0.2}
Colors.STANDARD_SELECTED = {r = 0.7, g = 0.7, b = 0.7}

-- ============================================================================
-- Separator Colors (for text formatting with CHAR_SEPARATOR)
-- ============================================================================

Colors.PASTEL_SEPARATOR = {r = 0.8, g = 0.8, b = 0.9}     -- Soft lavender
Colors.NUCLEAR_SEPARATOR = {r = 1.0, g = 0.8, b = 0.0}    -- Bright gold
Colors.STANDARD_SEPARATOR = {r = 0.6, g = 0.6, b = 0.6}   -- Medium gray

-- ============================================================================
-- Color Utility Functions
-- ============================================================================

-- Wrap text in color codes
-- @param hexColor: Hex color string (e.g., "FF0000")
-- @param text: Text to wrap
-- @return: Colored text string
function Colors:Wrap(hexColor, text)
    return "|cFF" .. hexColor .. tostring(text) .. "|r"
end

-- Convert RGB to hex color code
-- @param color: RGB as indexed {r, g, b} or named {r=, g=, b=} with values 0-1
-- @return: Hex color string (e.g., "FF6B6B")
function Colors:ToHex(color)
    if type(color) ~= "table" then
        KOL:DebugPrint("Colors: Invalid color for ToHex: " .. tostring(color), 1)
        return "FFFFFF"  -- Default to white
    end

    -- Support both indexed {r, g, b} and named {r=, g=, b=} formats
    local r, g, b
    if color[1] ~= nil then
        -- Indexed array: {0.5, 0.6, 0.7}
        r, g, b = color[1], color[2], color[3]
    elseif color.r ~= nil then
        -- Named table: {r = 0.5, g = 0.6, b = 0.7}
        r, g, b = color.r, color.g, color.b
    else
        KOL:DebugPrint("Colors: Invalid color format for ToHex (no r/g/b or [1]/[2]/[3])", 1)
        return "FFFFFF"
    end

    -- Ensure values are numbers and in 0-1 range
    r = tonumber(r) or 1
    g = tonumber(g) or 1
    b = tonumber(b) or 1

    return string.format("%02X%02X%02X", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

-- Convert hex to RGB array
-- @param hex: Hex color string (e.g., "FF6B6B")
-- @return: RGB array {r, g, b} with values 0-1
function Colors:ToRGB(hex)
    if type(hex) ~= "string" or #hex ~= 6 then
        KOL:DebugPrint("Colors: Invalid hex string for ToRGB: " .. tostring(hex), 1)
        return {1, 1, 1}  -- Default to white
    end

    local r = tonumber(string.sub(hex, 1, 2), 16) / 255
    local g = tonumber(string.sub(hex, 3, 4), 16) / 255
    local b = tonumber(string.sub(hex, 5, 6), 16) / 255

    return {r, g, b}
end

-- Get a pastel color by name (with user customization support)
-- @param colorName: Name of the color (e.g., "RED", "MINT")
-- @return: RGB array {r, g, b}
function Colors:GetPastel(colorName)
    colorName = string.upper(colorName)

    -- Check if user has customized this color
    if KOL.db and KOL.db.profile and KOL.db.profile.colors then
        if KOL.db.profile.colors.pastel and KOL.db.profile.colors.pastel[colorName] then
            return KOL.db.profile.colors.pastel[colorName]
        end
    end

    -- Return default pastel color
    return self.PASTEL[colorName] or self.PASTEL.PINK  -- Default to pink if not found
end

-- Get a nuclear (vibrant) color by name
-- @param colorName: Name of the color (e.g., "RED", "GREEN")
-- @return: Hex color string
function Colors:GetNuclear(colorName)
    colorName = string.upper(colorName)

    -- Check if user has customized this color
    if KOL.db and KOL.db.profile and KOL.db.profile.colors then
        if KOL.db.profile.colors.nuclear and KOL.db.profile.colors.nuclear[colorName] then
            local c = KOL.db.profile.colors.nuclear[colorName]
            return string.format("%02X%02X%02X", c.r * 255, c.g * 255, c.b * 255)
        end
    end

    -- Get from NUCLEAR table
    local c = self.NUCLEAR[colorName]
    if c then
        return string.format("%02X%02X%02X", c.r * 255, c.g * 255, c.b * 255)
    end

    return "FFFFFF"  -- Default to white if not found
end

-- Get a standard color by name (with user customization support)
-- @param colorName: Name of the color (e.g., "RED", "GREEN")
-- @return: Hex color string
function Colors:GetStandard(colorName)
    colorName = string.upper(colorName)

    -- Check if user has customized this color
    if KOL.db and KOL.db.profile and KOL.db.profile.colors then
        if KOL.db.profile.colors.standard and KOL.db.profile.colors.standard[colorName] then
            return KOL.db.profile.colors.standard[colorName]
        end
    end

    -- Return default standard color
    return self.STANDARD[colorName] or "FFFFFF"  -- Default to white if not found
end

-- Reset a color to default
-- @param palette: "standard" or "pastel"
-- @param colorName: Name of the color
function Colors:ResetColor(palette, colorName)
    if not KOL.db or not KOL.db.profile then return false end

    colorName = string.upper(colorName)
    palette = string.lower(palette)

    if not KOL.db.profile.colors then
        KOL.db.profile.colors = {standard = {}, pastel = {}}
    end

    if palette == "standard" then
        KOL.db.profile.colors.standard[colorName] = nil
    elseif palette == "pastel" then
        KOL.db.profile.colors.pastel[colorName] = nil
    else
        return false
    end

    return true
end

-- Reset all colors to defaults
function Colors:ResetAll()
    if not KOL.db or not KOL.db.profile then return false end

    KOL.db.profile.colors = {
        standard = {},
        pastel = {}
    }

    KOL:PrintTag("All colors reset to defaults")
    return true
end

-- ============================================================================
-- Rainbow and Formatted Text Functions
-- ============================================================================

-- Rainbow color gradient for text
-- Each character gets a different color cycling through the rainbow
-- @param text: Text to colorize
-- @return: Rainbow-colored text string
function Colors:RainbowText(text)
    if not text or text == "" then return "" end

    -- Rainbow gradient colors (smooth transition)
    local rainbowColors = {
        "FF6600", -- Red-orange
        "FF8800", -- Orange
        "FFAA00", -- Yellow-orange
        "FFCC00", -- Gold
        "FFEE00", -- Yellow
        "DDFF00", -- Yellow-green
        "BBFF00", -- Lime
        "99FF00", -- Light green
        "77FF00", -- Green
        "55FF00", -- Bright green
        "33FF00", -- Green-cyan
        "00FF33", -- Cyan-green
        "00FF66", -- Teal
        "00FF99", -- Aqua
        "00FFCC", -- Cyan
        "00CCFF", -- Sky blue
        "0099FF", -- Light blue
        "0066FF", -- Blue
    }

    local result = ""
    local colorIndex = 1
    local colorCount = #rainbowColors

    for i = 1, #text do
        local char = string.sub(text, i, i)
        -- Skip spaces for coloring but keep them
        if char == " " then
            result = result .. char
        else
            result = result .. "|cFF" .. rainbowColors[colorIndex] .. char .. "|r"
            colorIndex = colorIndex + 1
            if colorIndex > colorCount then
                colorIndex = 1
            end
        end
    end

    return result
end

-- Color text with a named color or hex code
-- @param text: Text to colorize
-- @param colorNameOrHex: Color name (e.g., "RED", "GREEN", "SKY") or hex code (e.g., "FF0000")
-- @return: Colored text string
function Colors:ColorText(text, colorNameOrHex)
    if not text then return "" end
    if not colorNameOrHex then return tostring(text) end

    local hexColor = colorNameOrHex

    -- If it's not a 6-character hex string, try to look it up as a color name
    if not (type(colorNameOrHex) == "string" and string.match(colorNameOrHex, "^%x%x%x%x%x%x$")) then
        local lookedUpColor = self:GetColor(colorNameOrHex)
        if lookedUpColor then
            hexColor = lookedUpColor
        else
            -- Fallback to white if color not found
            hexColor = "FFFFFF"
        end
    end

    return "|cFF" .. hexColor .. tostring(text) .. "|r"
end

-- Format a settings change message with consistent styling
-- Example: "[Koality-of-Life] Changed [Limit Damage] to [YES]"
-- @param optionName: Name of the option being changed
-- @param newValue: New value (will be colored GREEN for true/YES, RED for false/NO)
-- @param useShortTag: If true, use "KoL" instead of "Koality-of-Life"
-- @return: Formatted message string
function Colors:FormatSettingChange(optionName, newValue, useShortTag)
    local tagText = useShortTag and "KoL" or "Koality-of-Life"
    local rainbowTag = self:RainbowText(tagText)

    -- Determine value text and color
    local valueText, valueColor
    if type(newValue) == "boolean" then
        valueText = newValue and "YES" or "NO"
        valueColor = newValue and "00FF00" or "FF0000"  -- Green for YES, Red for NO
    else
        valueText = tostring(newValue)
        valueColor = "FFCC00"  -- Gold for other values
    end

    -- Build the formatted message
    -- [Rainbow Tag] Changed [Option Name] to [Value]
    return "|cFFFFFFFF[|r" .. rainbowTag .. "|cFFFFFFFF]|r " ..
           "Changed |cFFFFFFFF[|r" .. self:ColorText(optionName, "SKY") .. "|cFFFFFFFF]|r " ..
           "to |cFFFFFFFF[|r" .. "|cFF" .. valueColor .. valueText .. "|r" .. "|cFFFFFFFF]|r"
end

-- ============================================================================
-- Global Color Functions
-- ============================================================================
-- These are GLOBAL so they can be used anywhere (modules, macros, etc.)

-- Helper function for creating global color functions
local function CreateColorFunction(colorName)
    return function(text)
        return KOL.Colors:Wrap(KOL.Colors:GetStandard(colorName), text)
    end
end

-- Create all standard color functions
RED = CreateColorFunction("RED")
GREEN = CreateColorFunction("GREEN")
BLUE = CreateColorFunction("BLUE")
YELLOW = CreateColorFunction("YELLOW")
ORANGE = CreateColorFunction("ORANGE")
PURPLE = CreateColorFunction("PURPLE")
CYAN = CreateColorFunction("CYAN")
PINK = CreateColorFunction("PINK")
WHITE = CreateColorFunction("WHITE")
GRAY = CreateColorFunction("GRAY")
PASTEL_RED = CreateColorFunction("PASTEL_RED")
PASTEL_PINK = CreateColorFunction("PASTEL_PINK")
PASTEL_YELLOW = CreateColorFunction("PASTEL_YELLOW")

-- Global text formatting functions
-- Usage: RainbowText("KoL") returns rainbow-colored "KoL"
-- Usage: ColorText("YES", "GREEN") returns green "YES"
function RainbowText(text)
    return KOL.Colors:RainbowText(text)
end

function ColorText(text, colorNameOrHex)
    return KOL.Colors:ColorText(text, colorNameOrHex)
end

-- Unified color lookup function
-- Searches all palettes (STANDARD, PASTEL, NUCLEAR) for a color by name
-- @param colorName: Name of the color (e.g., "RED", "PASTEL_YELLOW", "NUCLEAR_GREEN")
-- @return: Hex color string or nil if not found
function Colors:GetColor(colorName)
    colorName = string.upper(colorName)

    -- Check STANDARD palette first (hex strings)
    if self.STANDARD[colorName] then
        return self.STANDARD[colorName]
    end

    -- Check PASTEL palette (RGB arrays - need conversion)
    if self.PASTEL[colorName] then
        return self:ToHex(self.PASTEL[colorName])
    end

    -- Check NUCLEAR palette (RGB objects - need conversion)
    if self.NUCLEAR and self.NUCLEAR[string.gsub(colorName, "NUCLEAR_", "")] then
        local nuclearColor = self.NUCLEAR[string.gsub(colorName, "NUCLEAR_", "")]
        return self:ToHex({nuclearColor.r, nuclearColor.g, nuclearColor.b})
    end

    -- Not found
    return nil
end

-- Unified color function - takes color name OR hex code
-- Examples:
--   COLOR("RED", "text") - looks up RED from any palette
--   COLOR("NUCLEAR_GREEN", "text") - looks up NUCLEAR_GREEN
--   COLOR("FF6600", "text") - uses hex code directly
function COLOR(colorNameOrHex, text)
    local hexColor = colorNameOrHex

    -- If it's not a 6-character hex string, try to look it up as a color name
    if not (type(colorNameOrHex) == "string" and string.match(colorNameOrHex, "^%x%x%x%x%x%x$")) then
        local lookedUpColor = KOL.Colors:GetColor(colorNameOrHex)
        if lookedUpColor then
            hexColor = lookedUpColor
        else
            -- Fallback to white if color not found
            hexColor = "FFFFFF"
        end
    end

    return KOL.Colors:Wrap(hexColor, text)
end

-- ============================================================================
-- Theme-Aware Color Functions
-- ============================================================================

-- Get theme color with fallback to existing color system
-- @param colorPath: Theme color path (e.g., "GlobalBG", "ButtonNormal")
-- @param fallback: Fallback color if theme color not found
-- @return: Hex color string
function Colors:GetThemeColor(colorPath, fallback)
    -- Check if themes module is available
    if KOL.Themes and KOL.Themes.GetThemeColor then
        return KOL.Themes:GetThemeColor(colorPath, fallback)
    end
    
    -- Fallback to provided fallback or default
    return fallback or "FFFFFF"
end

-- Get theme color as RGB object for UI components
-- @param colorPath: Theme color path (e.g., "GlobalBG", "ButtonNormal")
-- @param fallback: Fallback RGB table if theme color not found
-- @return: RGB object {r, g, b}
function Colors:GetUIThemeColor(colorPath, fallback)
    -- Check if themes module is available
    if KOL.Themes and KOL.Themes.GetUIThemeColor then
        return KOL.Themes:GetUIThemeColor(colorPath, fallback)
    end
    
    -- Fallback to provided fallback or default white
    return fallback or {r = 1, g = 1, b = 1}
end

-- Enhanced color lookup that checks themes first, then existing palettes
-- @param colorName: Name of color (e.g., "RED", "PASTEL_YELLOW", "NUCLEAR_GREEN", "GlobalBG")
-- @return: Hex color string or nil if not found
function Colors:GetColorWithTheme(colorName)
    -- First check if it's a theme color
    if KOL.Themes and KOL.Themes.GetThemeColor then
        local themeColor = KOL.Themes:GetThemeColor(colorName)
        if themeColor then
            return themeColor
        end
    end
    
    -- Fall back to existing color system
    return self:GetColor(colorName)
end

-- ============================================================================
-- Config UI Population
-- ============================================================================

-- Populate standard colors in config UI
function Colors:PopulateStandardColorsUI()
    if not KOL.configOptions or not KOL.configOptions.args.general or not KOL.configOptions.args.general.args.colors then
        return
    end

    local standardArgs = KOL.configOptions.args.general.args.colors.args.standardColors.args
    local order = 0

    -- Sort color names alphabetically
    local sortedColors = {}
    for colorName, _ in pairs(self.STANDARD) do
        table.insert(sortedColors, colorName)
    end
    table.sort(sortedColors)

    for _, colorName in ipairs(sortedColors) do
        local hexColor = self.STANDARD[colorName]
        order = order + 1

        standardArgs[string.lower(colorName)] = {
            type = "color",
            name = colorName,
            desc = "Hex: " .. hexColor,
            hasAlpha = false,
            get = function()
                local hex = self:GetStandard(colorName)
                local rgb = self:ToRGB(hex)
                return rgb[1], rgb[2], rgb[3]
            end,
            set = function(_, r, g, b)
                if not KOL.db.profile.colors then
                    KOL.db.profile.colors = {standard = {}, pastel = {}, custom = {}}
                end
                if not KOL.db.profile.colors.standard then
                    KOL.db.profile.colors.standard = {}
                end

                local hex = string.format("%02X%02X%02X", r * 255, g * 255, b * 255)
                KOL.db.profile.colors.standard[colorName] = hex
                KOL:PrintTag("Updated " .. colorName .. " to |cFF" .. hex .. "■■■|r")
            end,
            order = order,
        }
    end

    -- Add spacer before special colors
    order = order + 1
    standardArgs["spacer_" .. order] = {
        type = "description",
        name = " ",
        order = order,
    }

    -- Add STANDARD_SELECTED
    order = order + 1
    standardArgs["standard_selected"] = {
        type = "color",
        name = "STANDARD_SELECTED",
        desc = "Selection color for Standard palette",
        hasAlpha = false,
        get = function()
            return self.STANDARD_SELECTED.r, self.STANDARD_SELECTED.g, self.STANDARD_SELECTED.b
        end,
        set = function(_, r, g, b)
            self.STANDARD_SELECTED = {r = r, g = g, b = b}
            local hex = self:ToHex({r, g, b})
            KOL:PrintTag("Updated STANDARD_SELECTED to |cFF" .. hex .. "■■■|r")
        end,
        order = order,
    }

    -- Add STANDARD_SEPARATOR
    order = order + 1
    standardArgs["standard_separator"] = {
        type = "color",
        name = "STANDARD_SEPARATOR",
        desc = "Separator color for Standard palette",
        hasAlpha = false,
        get = function()
            return self.STANDARD_SEPARATOR.r, self.STANDARD_SEPARATOR.g, self.STANDARD_SEPARATOR.b
        end,
        set = function(_, r, g, b)
            self.STANDARD_SEPARATOR = {r = r, g = g, b = b}
            local hex = self:ToHex({r, g, b})
            KOL:PrintTag("Updated STANDARD_SEPARATOR to |cFF" .. hex .. "■■■|r")
        end,
        order = order,
    }

    KOL:DebugPrint("Colors: Populated standard colors UI", 3)
end

-- Populate pastel colors in config UI
function Colors:PopulatePastelColorsUI()
    if not KOL.configOptions or not KOL.configOptions.args.general or not KOL.configOptions.args.general.args.colors then
        return
    end

    local pastelArgs = KOL.configOptions.args.general.args.colors.args.pastelColors.args
    local order = 0

    -- Sort color names alphabetically
    local sortedColors = {}
    for colorName, _ in pairs(self.PASTEL) do
        table.insert(sortedColors, colorName)
    end
    table.sort(sortedColors)

    for _, colorName in ipairs(sortedColors) do
        local rgb = self.PASTEL[colorName]
        order = order + 1

        pastelArgs[string.lower(colorName)] = {
            type = "color",
            name = colorName,
            desc = "RGB: {" .. string.format("%.2f, %.2f, %.2f", rgb[1], rgb[2], rgb[3]) .. "}",
            hasAlpha = false,
            get = function()
                local color = self:GetPastel(colorName)
                return color[1], color[2], color[3]
            end,
            set = function(_, r, g, b)
                if not KOL.db.profile.colors then
                    KOL.db.profile.colors = {standard = {}, pastel = {}, custom = {}}
                end
                if not KOL.db.profile.colors.pastel then
                    KOL.db.profile.colors.pastel = {}
                end

                KOL.db.profile.colors.pastel[colorName] = {r, g, b}
                local hex = self:ToHex({r, g, b})
                KOL:PrintTag("Updated " .. colorName .. " to |cFF" .. hex .. "■■■|r")
            end,
            order = order,
        }
    end

    -- Add spacer before special colors
    order = order + 1
    pastelArgs["spacer_" .. order] = {
        type = "description",
        name = " ",
        order = order,
    }

    -- Add PASTEL_SELECTED
    order = order + 1
    pastelArgs["pastel_selected"] = {
        type = "color",
        name = "PASTEL_SELECTED",
        desc = "Selection color for Pastel palette",
        hasAlpha = false,
        get = function()
            return self.PASTEL_SELECTED.r, self.PASTEL_SELECTED.g, self.PASTEL_SELECTED.b
        end,
        set = function(_, r, g, b)
            self.PASTEL_SELECTED = {r = r, g = g, b = b}
            local hex = self:ToHex({r, g, b})
            KOL:PrintTag("Updated PASTEL_SELECTED to |cFF" .. hex .. "■■■|r")
        end,
        order = order,
    }

    -- Add PASTEL_SEPARATOR
    order = order + 1
    pastelArgs["pastel_separator"] = {
        type = "color",
        name = "PASTEL_SEPARATOR",
        desc = "Separator color for Pastel palette",
        hasAlpha = false,
        get = function()
            return self.PASTEL_SEPARATOR.r, self.PASTEL_SEPARATOR.g, self.PASTEL_SEPARATOR.b
        end,
        set = function(_, r, g, b)
            self.PASTEL_SEPARATOR = {r = r, g = g, b = b}
            local hex = self:ToHex({r, g, b})
            KOL:PrintTag("Updated PASTEL_SEPARATOR to |cFF" .. hex .. "■■■|r")
        end,
        order = order,
    }

    KOL:DebugPrint("Colors: Populated pastel colors UI", 3)
end

-- Populate nuclear colors in config UI
function Colors:PopulateNuclearColorsUI()
    if not KOL.configOptions or not KOL.configOptions.args.general or not KOL.configOptions.args.general.args.colors then
        return
    end

    local nuclearArgs = KOL.configOptions.args.general.args.colors.args.nuclearColors.args
    local order = 0

    -- Sort color names alphabetically
    local sortedColors = {}
    for colorName, _ in pairs(self.NUCLEAR) do
        table.insert(sortedColors, colorName)
    end
    table.sort(sortedColors)

    for _, colorName in ipairs(sortedColors) do
        local rgb = self.NUCLEAR[colorName]
        order = order + 1

        nuclearArgs[string.lower(colorName)] = {
            type = "color",
            name = colorName,
            desc = "RGB: {" .. string.format("%.2f, %.2f, %.2f", rgb.r, rgb.g, rgb.b) .. "}",
            hasAlpha = false,
            get = function()
                return rgb.r, rgb.g, rgb.b
            end,
            set = function(_, r, g, b)
                self.NUCLEAR[colorName] = {r = r, g = g, b = b}
                local hex = self:ToHex({r, g, b})
                KOL:PrintTag("Updated NUCLEAR." .. colorName .. " to |cFF" .. hex .. "■■■|r")
            end,
            order = order,
        }
    end

    -- Add spacer before special colors
    order = order + 1
    nuclearArgs["spacer_" .. order] = {
        type = "description",
        name = " ",
        order = order,
    }

    -- Add NUCLEAR_SELECTED
    order = order + 1
    nuclearArgs["nuclear_selected"] = {
        type = "color",
        name = "NUCLEAR_SELECTED",
        desc = "Selection color for Nuclear palette",
        hasAlpha = false,
        get = function()
            return self.NUCLEAR_SELECTED.r, self.NUCLEAR_SELECTED.g, self.NUCLEAR_SELECTED.b
        end,
        set = function(_, r, g, b)
            self.NUCLEAR_SELECTED = {r = r, g = g, b = b}
            local hex = self:ToHex({r, g, b})
            KOL:PrintTag("Updated NUCLEAR_SELECTED to |cFF" .. hex .. "■■■|r")
        end,
        order = order,
    }

    -- Add NUCLEAR_SEPARATOR
    order = order + 1
    nuclearArgs["nuclear_separator"] = {
        type = "color",
        name = "NUCLEAR_SEPARATOR",
        desc = "Separator color for Nuclear palette",
        hasAlpha = false,
        get = function()
            return self.NUCLEAR_SEPARATOR.r, self.NUCLEAR_SEPARATOR.g, self.NUCLEAR_SEPARATOR.b
        end,
        set = function(_, r, g, b)
            self.NUCLEAR_SEPARATOR = {r = r, g = g, b = b}
            local hex = self:ToHex({r, g, b})
            KOL:PrintTag("Updated NUCLEAR_SEPARATOR to |cFF" .. hex .. "■■■|r")
        end,
        order = order,
    }

    KOL:DebugPrint("Colors: Populated nuclear colors UI", 3)
end

-- Populate custom colors in config UI
function Colors:PopulateCustomColorsUI()
    if not KOL.configOptions or not KOL.configOptions.args.general or not KOL.configOptions.args.general.args.colors then
        return
    end

    local customArgs = KOL.configOptions.args.general.args.colors.args.customColors.args

    -- Clear existing custom colors
    for k, _ in pairs(customArgs) do
        customArgs[k] = nil
    end

    if not KOL.db.profile.colors or not KOL.db.profile.colors.custom then
        return
    end

    local order = 0
    for colorName, colorData in pairs(KOL.db.profile.colors.custom) do
        order = order + 1

        customArgs[string.lower(colorName)] = {
            type = "color",
            name = colorName,
            desc = "Custom color - Click to edit or delete",
            hasAlpha = false,
            get = function()
                local color = colorData
                if type(color) == "string" then
                    return self:ToRGB(color)
                else
                    return color[1], color[2], color[3]
                end
            end,
            set = function(_, r, g, b)
                KOL.db.profile.colors.custom[colorName] = {r, g, b}
                local hex = self:ToHex({r, g, b})
                KOL:PrintTag("Updated custom color " .. colorName .. " to |cFF" .. hex .. "■■■|r")
            end,
            order = order,
        }
    end

    KOL:DebugPrint("Colors: Populated custom colors UI", 3)
end

-- Show dialog to add a custom color
function Colors:ShowCustomColorDialog()
    -- Simple prompt for now - could be enhanced later
    StaticPopupDialogs["KOL_ADD_CUSTOM_COLOR"] = {
        text = "Enter a name for your custom color:",
        button1 = "Add",
        button2 = "Cancel",
        hasEditBox = true,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnAccept = function(self)
            local colorName = self.editBox:GetText()
            if colorName and colorName ~= "" then
                -- Normalize name
                colorName = string.upper(string.gsub(colorName, "%s+", "_"))

                -- Initialize custom colors if needed
                if not KOL.db.profile.colors then
                    KOL.db.profile.colors = {standard = {}, pastel = {}, custom = {}}
                end
                if not KOL.db.profile.colors.custom then
                    KOL.db.profile.colors.custom = {}
                end

                -- Add default white color
                KOL.db.profile.colors.custom[colorName] = {1, 1, 1}

                KOL:PrintTag("Added custom color: " .. colorName .. " (set to white by default)")

                -- Refresh config UI
                if KOL.Colors then
                    KOL.Colors:PopulateCustomColorsUI()
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
                end
            end
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
    }

    StaticPopup_Show("KOL_ADD_CUSTOM_COLOR")
end

-- Get a custom color by name
-- @param colorName: Name of the custom color
-- @return: RGB array {r, g, b} or nil if not found
function Colors:GetCustom(colorName)
    colorName = string.upper(colorName)

    if not KOL.db.profile.colors or not KOL.db.profile.colors.custom then
        return nil
    end

    local color = KOL.db.profile.colors.custom[colorName]
    if not color then
        return nil
    end

    -- Convert hex to RGB if needed
    if type(color) == "string" then
        return self:ToRGB(color)
    else
        return color
    end
end

-- ============================================================================
-- Initialization
-- ============================================================================

function Colors:Initialize()
    -- Ensure database structure exists
    if KOL.db and KOL.db.profile then
        if not KOL.db.profile.colors then
            KOL.db.profile.colors = {
                standard = {},  -- User customizations for standard colors
                pastel = {},    -- User customizations for pastel colors
                custom = {},    -- User-defined custom colors
            }
        end

        -- Populate config UI if it's ready
        if KOL.configOptions and KOL.configOptions.args.colors then
            self:PopulateStandardColorsUI()
            self:PopulatePastelColorsUI()
            self:PopulateCustomColorsUI()
        end
    end

    self.initialized = true
    if KOL.DebugPrint then
        KOL:DebugPrint("Colors: Module initialized", 1)
    end
end

-- Note: Color functions are now available globally
-- Initialization happens later in ui.lua after DB is ready
