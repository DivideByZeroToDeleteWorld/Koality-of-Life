-- !Koality-of-Life: Chat Module
-- Handles chat output and message filtering

local addonName = "!Koality-of-Life"
local KOL = KoalityOfLife

-- ============================================================================
-- Chat Message Filtering
-- Block unwanted messages from appearing in chat (e.g., server spam we replace)
-- ============================================================================

KOL.ChatFilter = {}
local ChatFilter = KOL.ChatFilter

-- Patterns to always block (permanent filters)
local permanentBlockPatterns = {
    -- Add permanent patterns here if needed
}

-- Temporary patterns to block (one-time use, cleared after match)
local temporaryBlockPatterns = {}

-- Filter function for CHAT_MSG_SYSTEM
local function SystemMessageFilter(self, event, message, ...)
    if not message then return false end

    -- Check permanent patterns
    for _, pattern in ipairs(permanentBlockPatterns) do
        if message:match(pattern) then
            KOL:DebugPrint("ChatFilter: Blocked permanent pattern: " .. message, 3)
            return true  -- Block this message
        end
    end

    -- Check temporary patterns (one-time blocks)
    for i = #temporaryBlockPatterns, 1, -1 do
        local pattern = temporaryBlockPatterns[i]
        if message:match(pattern) then
            table.remove(temporaryBlockPatterns, i)
            KOL:DebugPrint("ChatFilter: Blocked temporary pattern: " .. message, 3)
            return true  -- Block this message
        end
    end

    return false  -- Don't block
end

-- Initialize chat filtering
function ChatFilter:Initialize()
    -- Register filter for system messages
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemMessageFilter)
    KOL:DebugPrint("ChatFilter: System message filter registered", 2)
end

-- Add a permanent block pattern
function ChatFilter:AddPermanentPattern(pattern)
    table.insert(permanentBlockPatterns, pattern)
end

-- Add a temporary block pattern (removed after first match)
function ChatFilter:AddTemporaryPattern(pattern)
    table.insert(temporaryBlockPatterns, pattern)
end

-- Block the next message matching a pattern (convenience function)
function KOL:BlockNextChatMessage(pattern)
    ChatFilter:AddTemporaryPattern(pattern)
end

-- ============================================================================
-- Legacy Debug Function
-- ============================================================================

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

-- ============================================================================
-- Initialize on load
-- ============================================================================

-- Register for initialization after KOL is ready
KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
    ChatFilter:Initialize()
end, "ChatFilter_Init")
