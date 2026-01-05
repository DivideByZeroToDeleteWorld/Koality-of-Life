-- !Koality-of-Life Compatibility Layer
-- Polyfills for 3.3.5a: C_Timer, GetInstanceDifficulty fix, IsInGroup/IsInRaid

local KOL_oldGetInstanceDifficulty = GetInstanceDifficulty
function GetInstanceDifficulty()
    local diff = KOL_oldGetInstanceDifficulty()
    if diff == 1 then
        local _, _, difficulty, _, maxPlayers = GetInstanceInfo()
        if difficulty == 1 and maxPlayers == 25 then
            diff = 2  -- 25-man normal
        end
    end
    return diff
end

if not C_Timer or C_Timer._version ~= 2 then
    local setmetatable = setmetatable
    local type = type
    local tinsert = table.insert
    local tremove = table.remove

    C_Timer = C_Timer or {}
    C_Timer._version = 2

    local TickerPrototype = {}
    local TickerMetatable = {
        __index = TickerPrototype,
        __metatable = true
    }

    local waitTable = {}
    local waitFrame = KOL_TimerFrame or CreateFrame("Frame", "KOL_TimerFrame", UIParent)
    waitFrame:SetScript("OnUpdate", function(self, elapsed)
        local total = #waitTable
        local i = 1

        while i <= total do
            local ticker = waitTable[i]

            if ticker._cancelled then
                tremove(waitTable, i)
                total = total - 1
            elseif ticker._delay > elapsed then
                ticker._delay = ticker._delay - elapsed
                i = i + 1
            else
                ticker._callback(ticker)

                if ticker._remainingIterations == -1 then
                    ticker._delay = ticker._duration
                    i = i + 1
                elseif ticker._remainingIterations > 1 then
                    ticker._remainingIterations = ticker._remainingIterations - 1
                    ticker._delay = ticker._duration
                    i = i + 1
                elseif ticker._remainingIterations == 1 then
                    tremove(waitTable, i)
                    total = total - 1
                end
            end
        end

        if #waitTable == 0 then
            self:Hide()
        end
    end)

    local function AddDelayedCall(ticker, oldTicker)
        if oldTicker and type(oldTicker) == "table" then
            ticker = oldTicker
        end

        tinsert(waitTable, ticker)
        waitFrame:Show()
    end

    local function CreateTicker(duration, callback, iterations)
        local ticker = setmetatable({}, TickerMetatable)
        ticker._remainingIterations = iterations or -1
        ticker._duration = duration
        ticker._delay = duration
        ticker._callback = callback

        AddDelayedCall(ticker)

        return ticker
    end

    function C_Timer.After(duration, callback)
        AddDelayedCall({
            _remainingIterations = 1,
            _delay = duration,
            _callback = callback
        })
    end

    function C_Timer.NewTimer(duration, callback)
        return CreateTicker(duration, callback, 1)
    end

    function C_Timer.NewTicker(duration, callback, iterations)
        return CreateTicker(duration, callback, iterations)
    end

    function TickerPrototype:Cancel()
        self._cancelled = true
    end
end

if not IsInGroup then
    function IsInGroup()
        return GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
    end
end

if not IsInRaid then
    function IsInRaid()
        return GetNumRaidMembers() > 0
    end
end

if not GetNumSubgroupMembers then
    function GetNumSubgroupMembers()
        return GetNumPartyMembers()
    end
end

if not GetNumGroupMembers then
    function GetNumGroupMembers()
        if GetNumRaidMembers() > 0 then
            return GetNumRaidMembers()
        else
            return GetNumPartyMembers()
        end
    end
end
