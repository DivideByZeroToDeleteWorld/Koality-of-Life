-- ============================================================================
-- Koality-of-Life: Colors Module
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
-- Color Utility Functions
-- ============================================================================

-- Wrap text in color codes
-- @param hexColor: Hex color string (e.g., "FF0000")
-- @param text: Text to wrap
-- @return: Colored text string
function Colors:Wrap(hexColor, text)
    return "|cFF" .. hexColor .. tostring(text) .. "|r"
end

-- Convert RGB array to hex color code
-- @param color: RGB array {r, g, b} with values 0-1
-- @return: Hex color string (e.g., "FF6B6B")
function Colors:ToHex(color)
    if type(color) ~= "table" or #color < 3 then
        KOL:DebugPrint("Colors: Invalid color array for ToHex: " .. tostring(color), 1)
        return "FFFFFF"  -- Default to white
    end
    return string.format("%02X%02X%02X", color[1] * 255, color[2] * 255, color[3] * 255)
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

-- Custom color function (not tied to palette)
-- Example: COLOR("FF6600", "Custom orange text")
function COLOR(hexColor, text)
    return KOL.Colors:Wrap(hexColor, text)
end

-- ============================================================================
-- Config UI Population
-- ============================================================================

-- Populate standard colors in config UI
function Colors:PopulateStandardColorsUI()
    if not KOL.configOptions or not KOL.configOptions.args.colors then
        return
    end

    local standardArgs = KOL.configOptions.args.colors.args.standardColors.args
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

    KOL:DebugPrint("Colors: Populated standard colors UI", 3)
end

-- Populate pastel colors in config UI
function Colors:PopulatePastelColorsUI()
    if not KOL.configOptions or not KOL.configOptions.args.colors then
        return
    end

    local pastelArgs = KOL.configOptions.args.colors.args.pastelColors.args
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

    KOL:DebugPrint("Colors: Populated pastel colors UI", 3)
end

-- Populate custom colors in config UI
function Colors:PopulateCustomColorsUI()
    if not KOL.configOptions or not KOL.configOptions.args.colors then
        return
    end

    local customArgs = KOL.configOptions.args.colors.args.customColors.args

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
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("Koality-of-Life")
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
