-- ============================================================================
-- Batch Processing System
-- ============================================================================
-- Provides a smart batching system for queueing and processing actions
-- with configurable intervals and priorities.
--
-- Benefits:
--   - Fewer timers running (one per channel instead of many)
--   - Process multiple actions per tick
--   - Priority-based execution
--   - Dynamic interval adjustment
--   - Named actions for easy updates/removal
--
-- Usage:
--   KOL:BatchConfigure("channelName", { interval = 2.0, processMode = "all" })
--   KOL:BatchAdd("channelName", "actionName", function() ... end, priority)
--   KOL:BatchStart("channelName")
-- ============================================================================

-- Wait for KOL to be created, then get reference
local KOL = KoalityOfLife

-- Create a simple table to hold batch system state (not an AceAddon module)
local Batch = {
    channels = {}
}

-- Store reference on KOL for access
KOL.Batch = Batch

-- Generate unique action IDs
local actionIDCounter = 0
local function GenerateActionID()
    actionIDCounter = actionIDCounter + 1
    return "action_" .. actionIDCounter
end

-- ============================================================================
-- Channel Management
-- ============================================================================

-- Create or get a batch channel
function Batch:GetOrCreateChannel(channelName)
    if not self.channels[channelName] then
        self.channels[channelName] = {
            name = channelName,
            queue = {},              -- All pending actions (table of {name, action, priority, id})
            interval = 2.0,          -- How often this channel ticks (seconds)
            elapsed = 0,             -- Time accumulator
            isRunning = false,       -- Is this channel actively processing?
            maxPerTick = nil,        -- nil = process ALL, or set a limit (e.g., 5)
            processMode = "all",     -- "all", "priority", or "limit"
            triggerMode = "interval", -- "interval" (timer), "binding" (keypress), "outofcombat" (on PLAYER_REGEN_ENABLED)
            maxQueueSize = 50,       -- Maximum number of queued actions (prevent runaway growth)
            frame = nil,             -- OnUpdate frame for this channel
            keybinding = nil,        -- Keybinding string (e.g., "CTRL-SHIFT-M") for triggerMode = "binding"
            bindingButton = nil,     -- Hidden button for keybinding trigger
        }

        KOL:DebugPrint("Batch: Channel created: " .. YELLOW(channelName), 1)
    end

    return self.channels[channelName]
end

-- Configure a batch channel
function KOL:BatchConfigure(channelName, config)
    local channel = Batch:GetOrCreateChannel(channelName)

    if config.interval then
        channel.interval = config.interval
        KOL:DebugPrint("Batch: [" .. channelName .. "] interval set to: " .. config.interval .. "s", 1)
    end

    if config.maxPerTick then
        channel.maxPerTick = config.maxPerTick
    end

    if config.maxQueueSize then
        channel.maxQueueSize = config.maxQueueSize
        KOL:DebugPrint("Batch: [" .. channelName .. "] maxQueueSize set to: " .. config.maxQueueSize, 1)
    end

    if config.processMode then
        if config.processMode ~= "all" and config.processMode ~= "priority" and config.processMode ~= "limit" then
            KOL:PrintTag(RED("Error:") .. " Invalid processMode. Must be 'all', 'priority', or 'limit'")
            return false
        end
        channel.processMode = config.processMode
        KOL:DebugPrint("Batch: [" .. channelName .. "] processMode set to: " .. config.processMode, 1)
    end

    if config.triggerMode then
        if config.triggerMode ~= "interval" and config.triggerMode ~= "binding" and config.triggerMode ~= "outofcombat" then
            KOL:PrintTag(RED("Error:") .. " Invalid triggerMode. Must be 'interval', 'binding', or 'outofcombat'")
            return false
        end
        channel.triggerMode = config.triggerMode
        KOL:DebugPrint("Batch: [" .. channelName .. "] triggerMode set to: " .. config.triggerMode, 1)

        -- If switching to binding mode, create/update keybinding
        if config.triggerMode == "binding" and config.keybinding then
            Batch:SetupKeybinding(channelName, config.keybinding)
        end
    end

    if config.keybinding then
        channel.keybinding = config.keybinding
        KOL:DebugPrint("Batch: [" .. channelName .. "] keybinding set to: " .. config.keybinding, 1)
    end

    return true
end

-- Add an action to a batch channel
function KOL:BatchAdd(channelName, actionName, action, priority)
    if not actionName or not action then
        KOL:PrintTag(RED("Error:") .. " BatchAdd requires actionName and action function")
        return false
    end

    local channel = Batch:GetOrCreateChannel(channelName)

    -- Check if action with this name already exists, remove it (prevents duplicates)
    local alreadyExists = false
    for i = #channel.queue, 1, -1 do
        if channel.queue[i].name == actionName then
            table.remove(channel.queue, i)
            alreadyExists = true
            KOL:DebugPrint("Batch: [" .. channelName .. "] replaced action: " .. actionName, 3)
        end
    end

    -- Check queue size limit (only if not replacing existing)
    if not alreadyExists and #channel.queue >= channel.maxQueueSize then
        KOL:PrintTag(RED("Warning:") .. " Batch: [" .. channelName .. "] queue is full (" .. channel.maxQueueSize .. " items). Cannot add: " .. actionName)
        return false
    end

    -- Create the action object
    local actionObj = {
        name = actionName,
        action = action,
        priority = priority or 3,  -- Default to NORMAL (3)
        id = GenerateActionID(),
        addedTime = GetTime(),
    }

    -- Add to queue
    table.insert(channel.queue, actionObj)

    KOL:DebugPrint("Batch: [" .. channelName .. "] added action: " .. YELLOW(actionName) .. " (priority " .. actionObj.priority .. ") - Queue: " .. #channel.queue .. "/" .. channel.maxQueueSize, 3)

    return true
end

-- Remove a specific action from a channel
function KOL:BatchRemove(channelName, actionName)
    local channel = Batch.channels[channelName]
    if not channel then
        KOL:DebugPrint("Batch: Channel not found: " .. channelName, 1)
        return false
    end

    for i = #channel.queue, 1, -1 do
        if channel.queue[i].name == actionName then
            table.remove(channel.queue, i)
            KOL:DebugPrint("Batch: [" .. channelName .. "] removed action: " .. actionName, 1)
            return true
        end
    end

    return false
end

-- Clear all actions from a channel
function KOL:BatchClear(channelName)
    local channel = Batch.channels[channelName]
    if not channel then
        KOL:DebugPrint("Batch: Channel not found: " .. channelName, 1)
        return false
    end

    local count = #channel.queue
    channel.queue = {}

    KOL:DebugPrint("Batch: [" .. channelName .. "] cleared " .. count .. " actions", 3)
    return true
end

-- Setup keybinding for a batch channel
function Batch:SetupKeybinding(channelName, keybindingStr)
    local channel = self.channels[channelName]
    if not channel then
        return false
    end

    -- Create hidden button if it doesn't exist
    if not channel.bindingButton then
        local buttonName = "KOL_BatchBinding_" .. channelName
        channel.bindingButton = CreateFrame("Button", buttonName, UIParent, "SecureActionButtonTemplate")
        channel.bindingButton:Hide()
        channel.bindingButton:SetScript("OnClick", function()
            KOL:DebugPrint("Batch: [" .. channelName .. "] keybinding triggered", 3)
            -- Trigger one batch process cycle
            Batch:ProcessChannel(channel)
        end)
    end

    -- Set the keybinding
    SetBindingClick(keybindingStr, channel.bindingButton:GetName())
    SaveBindings(GetCurrentBindingSet())

    KOL:DebugPrint("Batch: [" .. channelName .. "] keybinding '" .. keybindingStr .. "' registered", 1)
    return true
end

-- Start a batch channel
function KOL:BatchStart(channelName)
    local channel = Batch.channels[channelName]
    if not channel then
        KOL:PrintTag(RED("Error:") .. " Batch channel not found: " .. channelName)
        return false
    end

    if channel.isRunning then
        KOL:DebugPrint("Batch: [" .. channelName .. "] already running", 3)
        return true
    end

    -- Handle different trigger modes
    if channel.triggerMode == "binding" then
        -- For binding mode, we don't auto-start, just wait for keybind press
        KOL:DebugPrint("Batch: [" .. YELLOW(channelName) .. "] waiting for keybinding trigger (" .. #channel.queue .. " actions queued)", 1)
        return true

    elseif channel.triggerMode == "outofcombat" then
        -- For out of combat mode, register combat events
        if not Batch.outOfCombatRegistered then
            -- Start channels when leaving combat
            KOL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
                Batch:ResumeOutOfCombatChannels()
            end, "Batch")
            -- Pause channels when entering combat
            KOL:RegisterEventCallback("PLAYER_REGEN_DISABLED", function()
                Batch:PauseOutOfCombatChannels()
            end, "Batch")
            Batch.outOfCombatRegistered = true
        end

        -- If not in combat, start the timer immediately
        if not InCombatLockdown() then
            if not channel.frame then
                channel.frame = CreateFrame("Frame")
            end

            channel.frame:SetScript("OnUpdate", function(self, elapsed)
                Batch:ProcessChannel(channel, elapsed)
            end)

            channel.isRunning = true
            channel.elapsed = 0
            KOL:DebugPrint("Batch: [" .. channelName .. "] started (out of combat, " .. #channel.queue .. " actions queued)", 3)
        else
            -- In combat, wait for combat to end
            KOL:DebugPrint("Batch: [" .. YELLOW(channelName) .. "] waiting for combat to end (" .. #channel.queue .. " actions queued)", 1)
        end
        return true

    else
        -- Default: interval mode - use OnUpdate frame
        if not channel.frame then
            channel.frame = CreateFrame("Frame")
        end

        channel.frame:SetScript("OnUpdate", function(self, elapsed)
            Batch:ProcessChannel(channel, elapsed)
        end)

        channel.isRunning = true
        channel.elapsed = 0

        KOL:DebugPrint("Batch: [" .. channelName .. "] started (" .. #channel.queue .. " actions queued)", 3)
        return true
    end
end

-- Stop a batch channel
function KOL:BatchStop(channelName)
    local channel = Batch.channels[channelName]
    if not channel then
        KOL:PrintTag(RED("Error:") .. " Batch channel not found: " .. channelName)
        return false
    end

    if not channel.isRunning then
        KOL:DebugPrint("Batch: [" .. channelName .. "] already stopped", 3)
        return true
    end

    if channel.frame then
        channel.frame:SetScript("OnUpdate", nil)
    end

    channel.isRunning = false

    KOL:DebugPrint("Batch: [" .. channelName .. "] stopped", 3)
    return true
end

-- Resume all "outofcombat" mode channels when player exits combat
function Batch:ResumeOutOfCombatChannels()
    for channelName, channel in pairs(self.channels) do
        if channel.triggerMode == "outofcombat" and #channel.queue > 0 and not channel.isRunning then
            KOL:DebugPrint("Batch: [" .. channelName .. "] resumed (left combat)", 3)

            -- Start running this channel with OnUpdate
            if not channel.frame then
                channel.frame = CreateFrame("Frame")
            end

            channel.frame:SetScript("OnUpdate", function(self, elapsed)
                Batch:ProcessChannel(channel, elapsed)
            end)

            channel.isRunning = true
            channel.elapsed = 0
        end
    end
end

-- Pause all "outofcombat" mode channels when player enters combat
function Batch:PauseOutOfCombatChannels()
    for channelName, channel in pairs(self.channels) do
        if channel.triggerMode == "outofcombat" and channel.isRunning then
            KOL:DebugPrint("Batch: [" .. channelName .. "] paused (entered combat)", 3)

            -- Stop the OnUpdate frame
            if channel.frame then
                channel.frame:SetScript("OnUpdate", nil)
            end

            channel.isRunning = false
        end
    end
end

-- Get status of a batch channel
function KOL:BatchStatus(channelName)
    local channel = Batch.channels[channelName]
    if not channel then
        KOL:PrintTag(RED("Error:") .. " Batch channel not found: " .. channelName)
        return
    end

    KOL:PrintTag("Batch Channel: " .. PASTEL_YELLOW(channelName))
    KOL:Print("  Status: " .. (channel.isRunning and GREEN("Running") or RED("Stopped")))
    KOL:Print("  Interval: " .. PASTEL_YELLOW(channel.interval .. "s"))
    KOL:Print("  Process Mode: " .. PASTEL_YELLOW(channel.processMode))
    KOL:Print("  Queue: " .. PASTEL_YELLOW(#channel.queue .. "/" .. channel.maxQueueSize))

    if #channel.queue > 0 then
        KOL:Print("  Queued Actions:")

        -- Sort by priority for display
        local sortedQueue = {}
        for _, action in ipairs(channel.queue) do
            table.insert(sortedQueue, action)
        end
        table.sort(sortedQueue, function(a, b) return a.priority < b.priority end)

        for _, action in ipairs(sortedQueue) do
            KOL:Print("    [P" .. action.priority .. "] " .. PASTEL_YELLOW(action.name))
        end
    else
        KOL:Print(GRAY("  (No actions queued)"))
    end
end

-- Process all queued actions immediately (flush)
function KOL:BatchFlush(channelName)
    local channel = Batch.channels[channelName]
    if not channel then
        KOL:PrintTag(RED("Error:") .. " Batch channel not found: " .. channelName)
        return false
    end

    if #channel.queue == 0 then
        KOL:DebugPrint("Batch: [" .. channelName .. "] has no queued actions to flush", 3)
        return true
    end

    -- Force process immediately
    Batch:ProcessChannelImmediate(channel)

    KOL:DebugPrint("Batch: [" .. channelName .. "] flushed", 3)
    return true
end

-- ============================================================================
-- Processing Logic
-- ============================================================================

-- Process a channel based on its configuration
function Batch:ProcessChannel(channel, elapsed)
    channel.elapsed = channel.elapsed + elapsed

    if channel.elapsed >= channel.interval then
        channel.elapsed = 0

        -- If queue is empty, stop the channel
        if #channel.queue == 0 then
            channel.isRunning = false
            if channel.frame then
                channel.frame:SetScript("OnUpdate", nil)
            end
            KOL:DebugPrint("Batch: [" .. channel.name .. "] auto-stopped (queue empty)", 3)
            return
        end

        -- Process based on mode
        self:ProcessChannelImmediate(channel)
    end
end

-- Process a channel immediately (used by both timer and flush)
function Batch:ProcessChannelImmediate(channel)
    if #channel.queue == 0 then
        return
    end

    local processCount = 0
    local maxToProcess = channel.maxPerTick or #channel.queue

    if channel.processMode == "all" then
        -- Process ALL actions in the queue (queue persists)
        for i = 1, #channel.queue do
            local item = channel.queue[i]
            local success, err = pcall(item.action)
            if not success then
                KOL:PrintTag(RED("Batch Error [") .. channel.name .. "/" .. item.name .. "]: " .. tostring(err))
            end
            processCount = processCount + 1
        end

        KOL:DebugPrint("Batch: [" .. channel.name .. "] processed " .. processCount .. " actions", 5)

    elseif channel.processMode == "priority" then
        -- Sort by priority, then process all (or up to max)
        table.sort(channel.queue, function(a, b)
            if a.priority == b.priority then
                return a.addedTime < b.addedTime  -- Earlier added = higher priority if same level
            end
            return a.priority < b.priority
        end)

        for i = 1, math.min(maxToProcess, #channel.queue) do
            local item = channel.queue[i]
            local success, err = pcall(item.action)
            if not success then
                KOL:PrintTag(RED("Batch Error [") .. channel.name .. "/" .. item.name .. "]: " .. tostring(err))
            end
            processCount = processCount + 1
        end

        KOL:DebugPrint("Batch: [" .. channel.name .. "] processed " .. processCount .. " actions (priority mode)", 5)

    elseif channel.processMode == "limit" then
        -- Process only up to maxPerTick, REMOVE from queue after processing
        for i = 1, math.min(maxToProcess, #channel.queue) do
            local item = table.remove(channel.queue, 1)
            local success, err = pcall(item.action)
            if not success then
                KOL:PrintTag(RED("Batch Error [") .. channel.name .. "/" .. item.name .. "]: " .. tostring(err))
            end
            processCount = processCount + 1
        end

        KOL:DebugPrint("Batch: [" .. channel.name .. "] processed " .. processCount .. " actions (limit mode, " .. #channel.queue .. " remaining)", 5)
    end
end

-- ============================================================================
-- Slash Commands
-- ============================================================================

local function RegisterSlashCommands()
    -- Register batch management commands
    KOL:RegisterSlashCommand("batch", function(...)
        local args = {...}
        local subCmd = args[1] and string.lower(args[1]) or ""
        local channelName = args[2]

        if subCmd == "status" then
            if channelName then
                KOL:BatchStatus(channelName)
            else
                -- Show all channels
                KOL:PrintTag("Batch Channels:")
                local hasChannels = false
                for name, channel in pairs(Batch.channels) do
                    hasChannels = true
                    local status = channel.isRunning and GREEN("Running") or RED("Stopped")
                    local queueInfo = PASTEL_YELLOW(#channel.queue .. "/" .. channel.maxQueueSize)
                    KOL:Print("  " .. PASTEL_YELLOW(name) .. " - " .. status .. " - " .. PASTEL_YELLOW(channel.interval .. "s") .. " interval - " .. queueInfo .. " queued")
                end
                if not hasChannels then
                    KOL:Print(GRAY("  No batch channels created yet"))
                end
            end
        elseif subCmd == "queue" then
            -- Show all queued items across all channels
            KOL:PrintTag("Batch Queue Summary:")
            local totalQueued = 0
            local hasQueued = false

            for name, channel in pairs(Batch.channels) do
                if #channel.queue > 0 then
                    hasQueued = true
                    totalQueued = totalQueued + #channel.queue
                    KOL:Print(" ")
                    KOL:Print(PASTEL_YELLOW(name) .. " (" .. #channel.queue .. "/" .. channel.maxQueueSize .. "):")

                    -- Sort by priority
                    local sortedQueue = {}
                    for _, action in ipairs(channel.queue) do
                        table.insert(sortedQueue, action)
                    end
                    table.sort(sortedQueue, function(a, b) return a.priority < b.priority end)

                    for _, action in ipairs(sortedQueue) do
                        KOL:Print("  [P" .. action.priority .. "] " .. PASTEL_YELLOW(action.name))
                    end
                end
            end

            if not hasQueued then
                KOL:Print(GRAY("  No actions queued in any channel"))
            else
                KOL:Print(" ")
                KOL:Print("Total: " .. PASTEL_YELLOW(totalQueued) .. " actions queued")
            end
        elseif subCmd == "start" then
            if channelName then
                KOL:BatchStart(channelName)
            else
                KOL:PrintTag(RED("Error:") .. " Usage: /kol batch start <channelName>")
            end
        elseif subCmd == "stop" then
            if channelName then
                KOL:BatchStop(channelName)
            else
                KOL:PrintTag(RED("Error:") .. " Usage: /kol batch stop <channelName>")
            end
        elseif subCmd == "clear" then
            if channelName then
                KOL:BatchClear(channelName)
            else
                KOL:PrintTag(RED("Error:") .. " Usage: /kol batch clear <channelName>")
            end
        elseif subCmd == "flush" then
            if channelName then
                KOL:BatchFlush(channelName)
            else
                KOL:PrintTag(RED("Error:") .. " Usage: /kol batch flush <channelName>")
            end
        else
            KOL:PrintTag("Batch System Commands:")
            KOL:Print(YELLOW("  /kol batch status") .. " - Show all batch channels")
            KOL:Print(YELLOW("  /kol batch status <channel>") .. " - Show specific channel details")
            KOL:Print(YELLOW("  /kol batch queue") .. " - Show all queued actions across all channels")
            KOL:Print(YELLOW("  /kol batch start <channel>") .. " - Start a batch channel")
            KOL:Print(YELLOW("  /kol batch stop <channel>") .. " - Stop a batch channel")
            KOL:Print(YELLOW("  /kol batch clear <channel>") .. " - Clear all queued actions")
            KOL:Print(YELLOW("  /kol batch flush <channel>") .. " - Process all actions immediately")
        end
    end, "Batch system management commands")
end

-- ============================================================================
-- Initialization
-- ============================================================================

-- Register slash commands immediately when file loads
RegisterSlashCommands()

KOL:DebugPrint("Batch: System loaded and ready", 1)
