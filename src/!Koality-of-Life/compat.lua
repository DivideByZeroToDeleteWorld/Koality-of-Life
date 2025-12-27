--[[
    !Koality-of-Life Compatibility Layer

    Provides polyfills for modern WoW API functions that don't exist in 3.3.5a.
    This file MUST load before all other addon files.

    Includes:
    - C_Timer (After, NewTimer, NewTicker)
    - GetInstanceDifficulty (enhanced for 25-man detection)
    - IsInGroup, IsInRaid, GetNumGroupMembers, GetNumSubgroupMembers

    Based on Details! Damage Meter compat.lua implementation.
]]

--------------------------------------------------------------------------------
-- Instance Difficulty Fix
--------------------------------------------------------------------------------
-- Wraps GetInstanceDifficulty to properly detect 25-man raids
-- In 3.3.5a, GetInstanceDifficulty returns 1 for both 10-man and 25-man normal
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

--------------------------------------------------------------------------------
-- C_Timer Implementation
--------------------------------------------------------------------------------
-- Only create if it doesn't exist or is an older version
if not C_Timer or C_Timer._version ~= 2 then
    local setmetatable = setmetatable
    local type = type
    local tinsert = table.insert
    local tremove = table.remove

    C_Timer = C_Timer or {}
    C_Timer._version = 2

    -- Ticker prototype for Cancel() support
    local TickerPrototype = {}
    local TickerMetatable = {
        __index = TickerPrototype,
        __metatable = true
    }

    -- Internal timer management
    local waitTable = {}
    local waitFrame = KOL_TimerFrame or CreateFrame("Frame", "KOL_TimerFrame", UIParent)
    waitFrame:SetScript("OnUpdate", function(self, elapsed)
        local total = #waitTable
        local i = 1

        while i <= total do
            local ticker = waitTable[i]

            if ticker._cancelled then
                -- Remove cancelled tickers
                tremove(waitTable, i)
                total = total - 1
            elseif ticker._delay > elapsed then
                -- Still waiting
                ticker._delay = ticker._delay - elapsed
                i = i + 1
            else
                -- Time to fire!
                ticker._callback(ticker)

                if ticker._remainingIterations == -1 then
                    -- Infinite ticker, reset delay
                    ticker._delay = ticker._duration
                    i = i + 1
                elseif ticker._remainingIterations > 1 then
                    -- More iterations remaining
                    ticker._remainingIterations = ticker._remainingIterations - 1
                    ticker._delay = ticker._duration
                    i = i + 1
                elseif ticker._remainingIterations == 1 then
                    -- Last iteration, remove
                    tremove(waitTable, i)
                    total = total - 1
                end
            end
        end

        -- Hide frame when no timers active (saves CPU)
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

    -- C_Timer.After(duration, callback)
    -- Calls callback once after duration seconds
    function C_Timer.After(duration, callback)
        AddDelayedCall({
            _remainingIterations = 1,
            _delay = duration,
            _callback = callback
        })
    end

    -- C_Timer.NewTimer(duration, callback)
    -- Like After but returns a cancellable timer object
    function C_Timer.NewTimer(duration, callback)
        return CreateTicker(duration, callback, 1)
    end

    -- C_Timer.NewTicker(duration, callback, iterations)
    -- Calls callback every duration seconds, iterations times (or forever if nil)
    function C_Timer.NewTicker(duration, callback, iterations)
        return CreateTicker(duration, callback, iterations)
    end

    -- ticker:Cancel()
    -- Cancels a running timer/ticker
    function TickerPrototype:Cancel()
        self._cancelled = true
    end
end

--------------------------------------------------------------------------------
-- Group/Raid Compatibility Functions
--------------------------------------------------------------------------------
-- These functions exist in later WoW versions but not in 3.3.5a

-- IsInGroup() - Returns true if in party or raid
if not IsInGroup then
    function IsInGroup()
        return GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
    end
end

-- IsInRaid() - Returns true if in raid
if not IsInRaid then
    function IsInRaid()
        return GetNumRaidMembers() > 0
    end
end

-- GetNumSubgroupMembers() - Returns party member count (not including player)
if not GetNumSubgroupMembers then
    function GetNumSubgroupMembers()
        return GetNumPartyMembers()
    end
end

-- GetNumGroupMembers() - Returns total group size
if not GetNumGroupMembers then
    function GetNumGroupMembers()
        if GetNumRaidMembers() > 0 then
            return GetNumRaidMembers()
        else
            return GetNumPartyMembers()
        end
    end
end
