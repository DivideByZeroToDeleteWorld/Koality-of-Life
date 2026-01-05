local addonName = "!Koality-of-Life"
local KOL = KoalityOfLife

KOL.ChatFilter = {}
local ChatFilter = KOL.ChatFilter

local permanentBlockPatterns = {
}

local temporaryBlockPatterns = {}

local function SystemMessageFilter(self, event, message, ...)
    if not message then return false end

    for _, pattern in ipairs(permanentBlockPatterns) do
        if message:match(pattern) then
            KOL:DebugPrint("ChatFilter: Blocked permanent pattern: " .. message, 3)
            return true
        end
    end

    for i = #temporaryBlockPatterns, 1, -1 do
        local pattern = temporaryBlockPatterns[i]
        if message:match(pattern) then
            table.remove(temporaryBlockPatterns, i)
            KOL:DebugPrint("ChatFilter: Blocked temporary pattern: " .. message, 3)
            return true
        end
    end

    return false
end

function ChatFilter:Initialize()
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemMessageFilter)
    KOL:DebugPrint("ChatFilter: System message filter registered", 2)
end

function ChatFilter:AddPermanentPattern(pattern)
    table.insert(permanentBlockPatterns, pattern)
end

function ChatFilter:AddTemporaryPattern(pattern)
    table.insert(temporaryBlockPatterns, pattern)
end

function KOL:BlockNextChatMessage(pattern)
    ChatFilter:AddTemporaryPattern(pattern)
end

-- Keeping this for backward compatibility
function KOL:Debug(msg)
    if self.db and self.db.profile and self.db.profile.debug then
        self:PrintTag("|cFFFF6600[DEBUG]|r " .. tostring(msg))
    elseif KoalityOfLifeDB and KoalityOfLifeDB.debug then
        -- Fallback for old DB structure
        self:PrintTag(YELLOW("[DEBUG]") .. " " .. tostring(msg))
    end
end

KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
    ChatFilter:Initialize()
end, "ChatFilter_Init")
