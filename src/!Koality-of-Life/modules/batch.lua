local KOL = KoalityOfLife

local Batch = {
    channels = {}
}

KOL.Batch = Batch

local actionIDCounter = 0
local function GenerateActionID()
    actionIDCounter = actionIDCounter + 1
    return "action_" .. actionIDCounter
end

function Batch:GetOrCreateChannel(channelName)
    if not self.channels[channelName] then
        self.channels[channelName] = {
            name = channelName,
            queue = {},
            interval = 2.0,
            elapsed = 0,
            isRunning = false,
            maxPerTick = nil,
            processMode = "all",
            triggerMode = "interval",
            maxQueueSize = 50,
            frame = nil,
            keybinding = nil,
            bindingButton = nil,
        }

        KOL:DebugPrint("Batch: Channel created: " .. YELLOW(channelName), 1)
    end

    return self.channels[channelName]
end

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

function KOL:BatchAdd(channelName, actionName, action, priority)
    if not actionName or not action then
        KOL:PrintTag(RED("Error:") .. " BatchAdd requires actionName and action function")
        return false
    end

    local channel = Batch:GetOrCreateChannel(channelName)

    local alreadyExists = false
    for i = #channel.queue, 1, -1 do
        if channel.queue[i].name == actionName then
            table.remove(channel.queue, i)
            alreadyExists = true
            KOL:DebugPrint("Batch: [" .. channelName .. "] replaced action: " .. actionName, 3)
        end
    end

    if not alreadyExists and #channel.queue >= channel.maxQueueSize then
        KOL:PrintTag(RED("Warning:") .. " Batch: [" .. channelName .. "] queue is full (" .. channel.maxQueueSize .. " items). Cannot add: " .. actionName)
        return false
    end

    local actionObj = {
        name = actionName,
        action = action,
        priority = priority or 3,
        id = GenerateActionID(),
        addedTime = GetTime(),
    }

    table.insert(channel.queue, actionObj)

    KOL:DebugPrint("Batch: [" .. channelName .. "] added action: " .. YELLOW(actionName) .. " (priority " .. actionObj.priority .. ") - Queue: " .. #channel.queue .. "/" .. channel.maxQueueSize, 3)

    return true
end

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

function Batch:SetupKeybinding(channelName, keybindingStr)
    local channel = self.channels[channelName]
    if not channel then
        return false
    end

    if not channel.bindingButton then
        local buttonName = "KOL_BatchBinding_" .. channelName
        channel.bindingButton = CreateFrame("Button", buttonName, UIParent, "SecureActionButtonTemplate")
        channel.bindingButton:Hide()
        channel.bindingButton:SetScript("OnClick", function()
            KOL:DebugPrint("Batch: [" .. channelName .. "] keybinding triggered", 3)
            Batch:ProcessChannel(channel)
        end)
    end

    SetBindingClick(keybindingStr, channel.bindingButton:GetName())
    SaveBindings(GetCurrentBindingSet())

    KOL:DebugPrint("Batch: [" .. channelName .. "] keybinding '" .. keybindingStr .. "' registered", 1)
    return true
end

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

    if channel.triggerMode == "binding" then
        KOL:DebugPrint("Batch: [" .. YELLOW(channelName) .. "] waiting for keybinding trigger (" .. #channel.queue .. " actions queued)", 1)
        return true

    elseif channel.triggerMode == "outofcombat" then
        if not Batch.outOfCombatRegistered then
            KOL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
                Batch:ResumeOutOfCombatChannels()
            end, "Batch")
            KOL:RegisterEventCallback("PLAYER_REGEN_DISABLED", function()
                Batch:PauseOutOfCombatChannels()
            end, "Batch")
            Batch.outOfCombatRegistered = true
        end

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
            KOL:DebugPrint("Batch: [" .. YELLOW(channelName) .. "] waiting for combat to end (" .. #channel.queue .. " actions queued)", 1)
        end
        return true

    else
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

function Batch:ResumeOutOfCombatChannels()
    for channelName, channel in pairs(self.channels) do
        if channel.triggerMode == "outofcombat" and #channel.queue > 0 and not channel.isRunning then
            KOL:DebugPrint("Batch: [" .. channelName .. "] resumed (left combat)", 3)

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

function Batch:PauseOutOfCombatChannels()
    for channelName, channel in pairs(self.channels) do
        if channel.triggerMode == "outofcombat" and channel.isRunning then
            KOL:DebugPrint("Batch: [" .. channelName .. "] paused (entered combat)", 3)

            if channel.frame then
                channel.frame:SetScript("OnUpdate", nil)
            end

            channel.isRunning = false
        end
    end
end

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

    Batch:ProcessChannelImmediate(channel)

    KOL:DebugPrint("Batch: [" .. channelName .. "] flushed", 3)
    return true
end

function Batch:ProcessChannel(channel, elapsed)
    channel.elapsed = channel.elapsed + elapsed

    if channel.elapsed >= channel.interval then
        channel.elapsed = 0

        if #channel.queue == 0 then
            channel.isRunning = false
            if channel.frame then
                channel.frame:SetScript("OnUpdate", nil)
            end
            KOL:DebugPrint("Batch: [" .. channel.name .. "] auto-stopped (queue empty)", 3)
            return
        end

        self:ProcessChannelImmediate(channel)
    end
end

function Batch:ProcessChannelImmediate(channel)
    if #channel.queue == 0 then
        return
    end

    local processCount = 0
    local maxToProcess = channel.maxPerTick or #channel.queue

    if channel.processMode == "all" then
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
        table.sort(channel.queue, function(a, b)
            if a.priority == b.priority then
                return a.addedTime < b.addedTime
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

local function RegisterSlashCommands()
    KOL:RegisterSlashCommand("batch", function(...)
        local args = {...}
        local subCmd = args[1] and string.lower(args[1]) or ""
        local channelName = args[2]

        if subCmd == "status" then
            if channelName then
                KOL:BatchStatus(channelName)
            else
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
            KOL:PrintTag("Batch Queue Summary:")
            local totalQueued = 0
            local hasQueued = false

            for name, channel in pairs(Batch.channels) do
                if #channel.queue > 0 then
                    hasQueued = true
                    totalQueued = totalQueued + #channel.queue
                    KOL:Print(" ")
                    KOL:Print(PASTEL_YELLOW(name) .. " (" .. #channel.queue .. "/" .. channel.maxQueueSize .. "):")

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

RegisterSlashCommands()

KOL:DebugPrint("Batch: System loaded and ready", 1)
