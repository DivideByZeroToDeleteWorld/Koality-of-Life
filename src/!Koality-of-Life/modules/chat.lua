-- !Koality-of-Life: Chat Module
-- Handles chat output (color functions now in core.lua)

local addonName = "!Koality-of-Life"
local KOL = KoalityOfLife

-- Note: All print functions and color functions are now in core.lua
-- This file is kept for backward compatibility and potential future chat features

-- Debug is now handled in main.lua as KOL:DebugPrint()
-- Keeping this for backward compatibility
function KOL:Debug(msg)
    if self.db and self.db.profile and self.db.profile.debug then
        self:PrintTag("|cFFFF6600[DEBUG]|r " .. tostring(msg))  -- Orange warning color
    elseif KoalityOfLifeDB and KoalityOfLifeDB.debug then
        -- Fallback for old DB structure
        self:PrintTag(YELLOW("[DEBUG]") .. " " .. tostring(msg))
    end
end
