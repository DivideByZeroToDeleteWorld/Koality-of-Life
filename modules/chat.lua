-- Koality-of-Life: Chat Module
-- Handles all chat output and color functions

local addonName = "Koality-of-Life"
local KOL = KoalityOfLife

-- ============================================================================
-- Print Functions
-- ============================================================================

function KOL:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(tostring(msg))
end

function KOL:ColorPrint(msg)
    -- Just pass through - colors are pre-formatted in the string
    DEFAULT_CHAT_FRAME:AddMessage(tostring(msg))
end

function KOL:PrintTag(msg)
    local rainbowTag = "|cFFFF0000K|cFFFF4400o|cFFFF8800a|cFFFFCC00l|cFFFFFF00i|cFFCCFF00t|cFF88FF00y|cFF44FF00-|cFF00FF00o|cFF00FF88f|cFF00FFFF-|cFF55AAFFL|cFF7799FFi|cFF8888FFf|cFFAA66FFe|r"
    DEFAULT_CHAT_FRAME:AddMessage("[" .. rainbowTag .. "] " .. tostring(msg))
end

-- Debug is now handled in core.lua as KOL:DebugPrint()
-- Keeping this for backward compatibility
function KOL:Debug(msg)
    if self.db and self.db.profile and self.db.profile.debug then
        self:PrintTag("|cFFFF6600[DEBUG]|r " .. tostring(msg))  -- Orange warning color
    elseif KoalityOfLifeDB and KoalityOfLifeDB.debug then
        -- Fallback for old DB structure
        self:PrintTag(YELLOW("[DEBUG]") .. " " .. tostring(msg))
    end
end

-- ============================================================================
-- Global Color Output Function for Macros
-- Usage: /run CO("Text 1", RED("colored text"), "Text 3")
-- Example: /run CO(RED("Red text"), " ", GREEN("Green"), " ", BLUE("Blue"))
-- ============================================================================

-- Helper function to wrap text in color codes
local function ColorWrap(color, text)
    return "|cFF" .. color .. tostring(text) .. "|r"
end

-- Predefined color functions (no pipes needed in /run commands!)
function RED(text) return ColorWrap("FF0000", text) end
function GREEN(text) return ColorWrap("00FF00", text) end
function BLUE(text) return ColorWrap("0000FF", text) end
function YELLOW(text) return ColorWrap("FFFF00", text) end
function ORANGE(text) return ColorWrap("FF8800", text) end
function PURPLE(text) return ColorWrap("8800FF", text) end
function CYAN(text) return ColorWrap("00FFFF", text) end
function PINK(text) return ColorWrap("FF00FF", text) end
function WHITE(text) return ColorWrap("FFFFFF", text) end
function GRAY(text) return ColorWrap("888888", text) end

-- Custom color function
-- Example: /run CO(COLOR("FF6600", "Custom orange text"))
function COLOR(hexColor, text)
    return ColorWrap(hexColor, text)
end

-- ColorOutput function - handles unlimited arguments and outputs colored text
function ColorOutput(...)
    local output = ""
    
    -- Concatenate all arguments
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        if arg ~= nil then
            output = output .. tostring(arg)
        end
    end
    
    -- Output through KOL:Print to ensure proper color rendering
    if KoalityOfLife and KoalityOfLife.Print then
        KoalityOfLife:Print(output)
    else
        -- Fallback if addon isn't loaded yet
        DEFAULT_CHAT_FRAME:AddMessage(output)
    end
end

-- Create a shorter alias for convenience
CO = ColorOutput
