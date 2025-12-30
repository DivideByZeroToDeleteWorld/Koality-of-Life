-- ============================================================================
-- Batch System UI Configuration
-- ============================================================================
-- Provides a beautiful UI for managing batch channels
-- ============================================================================

local KOL = KoalityOfLife
local Batch = KOL.Batch
local UIFactory = KOL.UIFactory

-- Store reference to queue viewer frame
local queueViewerFrame = nil

-- ============================================================================
-- Batch-Specific UI Helper Functions
-- ============================================================================

-- Priority color mapping (for borders)
local priorityColors = {
    [1] = {r = 1.0, g = 0.2, b = 0.2},   -- CRITICAL - Bright Red
    [2] = {r = 1.0, g = 0.6, b = 0.0},   -- HIGH - Orange
    [3] = {r = 1.0, g = 1.0, b = 0.4},   -- NORMAL - Yellow
    [4] = {r = 0.4, g = 0.8, b = 0.4},   -- LOW - Green
    [5] = {r = 0.5, g = 0.5, b = 0.5},   -- DEFERRED - Gray
}

local function GetPriorityColor(priority)
    return priorityColors[priority] or priorityColors[3]
end

-- ============================================================================
-- Queue Viewer Popup
-- ============================================================================

local function CreateQueueViewer()
    if queueViewerFrame then
        return queueViewerFrame
    end

    -- Create main frame using UIFactory (auto-registered, movable, closable)
    local frame = UIFactory:CreateStyledFrame(UIParent, "KOL_BatchQueueViewer", 450, 550, {
        movable = true,
        closable = true,
        strata = UIFactory.STRATA.NORMAL,  -- Normal KOL window strata
        bgColor = {r = 0.15, g = 0.15, b = 0.15, a = 0.95},
    })
    frame:SetPoint("CENTER")

    -- Create title bar using UIFactory
    local titleBar, title, titleCloseBtn = UIFactory:CreateTitleBar(frame, 24, "Batch Queue Viewer", {
        showCloseButton = true,
    })
    frame.title = title

    -- Channel name label (on title bar, right side)
    local fontPath, fontOutline = UIFactory.GetGeneralFont()
    local channelLabel = frame:CreateFontString(nil, "OVERLAY")
    channelLabel:SetFont(fontPath, 10, fontOutline)
    channelLabel:SetPoint("RIGHT", titleBar, "RIGHT", -26, 0)  -- Leave room for X button
    channelLabel:SetTextColor(0.7, 0.7, 0.7, 1)
    frame.channelLabel = channelLabel

    -- Content area using UIFactory
    local contentBG = UIFactory:CreateContentArea(frame, {top = 28, bottom = 48, left = 8, right = 8})

    -- Scroll frame for queue items
    local scrollFrame = CreateFrame("ScrollFrame", "KOL_BatchQueueScroll", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentBG, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentBG, "BOTTOMRIGHT", -28, 8)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 10)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    frame.scrollChild = scrollChild
    frame.scrollFrame = scrollFrame

    -- Close button at bottom (styled)
    local closeBtn = UIFactory:CreateButton(frame, "Close", {
        type = "styled",
        width = 100,
        height = 30,
        onClick = function() frame:Hide() end
    })
    closeBtn:SetPoint("BOTTOM", 0, 10)

    queueViewerFrame = frame
    return frame
end

local function ShowQueueViewer(channelName)
    KOL:DebugPrint("Batch: ShowQueueViewer called for: " .. tostring(channelName), 4)

    local viewer = CreateQueueViewer()
    KOL:DebugPrint("Batch: Viewer frame: " .. tostring(viewer:GetName()), 4)

    local channel = Batch.channels[channelName]

    if not channel then
        KOL:PrintTag(RED("Error:") .. " Channel not found: " .. channelName)
        return
    end

    KOL:DebugPrint("Batch: Channel found, queue size: " .. #channel.queue, 4)

    -- Get font settings
    local fontPath, fontOutline = UIFactory.GetGeneralFont()

    -- Update title
    viewer.channelLabel:SetText(channelName .. " - " .. #channel.queue .. "/" .. channel.maxQueueSize .. " queued")

    -- Clear previous items
    for _, child in pairs({viewer.scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Create queue item displays
    local yOffset = -5
    local sortedQueue = {}
    for _, action in ipairs(channel.queue) do
        table.insert(sortedQueue, action)
    end
    table.sort(sortedQueue, function(a, b) return a.priority < b.priority end)

    if #sortedQueue == 0 then
        -- Empty state
        local emptyText = viewer.scrollChild:CreateFontString(nil, "OVERLAY")
        emptyText:SetFont(fontPath, 14, fontOutline)
        emptyText:SetPoint("TOP", 0, -50)
        emptyText:SetText("No actions queued")
        emptyText:SetTextColor(0.5, 0.5, 0.5, 1)  -- Gray
    else
        for i, action in ipairs(sortedQueue) do
            local itemFrame = CreateFrame("Frame", nil, viewer.scrollChild)
            itemFrame:SetWidth(viewer.scrollChild:GetWidth() - 10)
            itemFrame:SetHeight(50)
            itemFrame:SetPoint("TOPLEFT", 5, yOffset)

            -- Get priority color
            local color = GetPriorityColor(action.priority)

            -- Background with priority-colored border
            itemFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false,
                tileSize = 1,
                edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            itemFrame:SetBackdropColor(0.12, 0.12, 0.12, 1)  -- Very dark gray background
            itemFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1)  -- Priority color border!

            -- Priority badge
            local priorityText = itemFrame:CreateFontString(nil, "OVERLAY")
            priorityText:SetFont(fontPath, 14, fontOutline)
            priorityText:SetPoint("LEFT", 10, 5)
            priorityText:SetText("P" .. action.priority)
            priorityText:SetTextColor(color.r, color.g, color.b, 1)

            -- Action name
            local nameText = itemFrame:CreateFontString(nil, "OVERLAY")
            nameText:SetFont(fontPath, 13, fontOutline)
            nameText:SetPoint("LEFT", priorityText, "RIGHT", 15, 0)
            nameText:SetPoint("RIGHT", -10, 0)
            nameText:SetJustifyH("LEFT")
            nameText:SetText(action.name)
            nameText:SetTextColor(1, 1, 0.6, 1)  -- Pastel yellow

            -- Age indicator
            local age = GetTime() - action.addedTime
            local ageText = itemFrame:CreateFontString(nil, "OVERLAY")
            ageText:SetFont(fontPath, 11, fontOutline)
            ageText:SetPoint("BOTTOMRIGHT", -10, 5)
            if age < 1 then
                ageText:SetText("Just added")
            elseif age < 60 then
                ageText:SetText(math.floor(age) .. "s ago")
            else
                ageText:SetText(math.floor(age / 60) .. "m ago")
            end
            ageText:SetTextColor(0.5, 0.5, 0.5, 1)  -- Gray

            yOffset = yOffset - 55
        end
    end

    -- Update scroll child height
    local scrollFrameHeight = viewer.scrollFrame and viewer.scrollFrame:GetHeight() or 400
    viewer.scrollChild:SetHeight(math.max(math.abs(yOffset) + 10, scrollFrameHeight))

    KOL:DebugPrint("Batch: About to show viewer frame", 4)
    viewer:Show()
    KOL:DebugPrint("Batch: Viewer should now be visible", 4)
end

-- ============================================================================
-- Batch Config UI
-- ============================================================================

function Batch:InitializeConfigUI()
    -- Make sure UI system is initialized first
    if not KOL.configOptions or not KOL.configGroups then
        KOL:DebugPrint("Batch UI: Waiting for main UI to initialize...", 3)
        return
    end

    -- Create batch config group
    if not KOL.configGroups.batch then
        KOL.configGroups.batch = {
            type = "group",
            name = "|cFFFFAA66Batch System|r",
            order = 50,
            args = {
                header = {
                    type = "description",
                    name = "|cFFFFFFFFBatch System Management|r\n|cFFAAAAAAManage batch processing channels and view queued actions.|r\n",
                    fontSize = "medium",
                    order = 1,
                },
            }
        }
        KOL.configOptions.args.batch = KOL.configGroups.batch
    end

    -- Refresh the batch channels display
    self:RefreshBatchConfigUI()
end

function Batch:RefreshBatchConfigUI()
    if not KOL.configGroups.batch then
        return
    end

    local args = KOL.configGroups.batch.args

    -- Remove old channel groups (keep header)
    for key, _ in pairs(args) do
        if key ~= "header" then
            args[key] = nil
        end
    end

    -- Add each batch channel as a group
    local order = 10
    for channelName, channel in pairs(self.channels) do
        local groupKey = "channel_" .. channelName

        args[groupKey] = {
            type = "group",
            name = channelName,
            inline = true,
            order = order,
            args = {
                status = {
                    type = "description",
                    name = function()
                        local status = channel.isRunning and GREEN("Running") or RED("Stopped")
                        local queue = PASTEL_YELLOW(#channel.queue .. "/" .. channel.maxQueueSize)
                        return "Status: " .. status .. " | Queue: " .. queue .. "\n"
                    end,
                    order = 1,
                },

                interval = {
                    type = "range",
                    name = "Interval",
                    desc = "How often this channel processes (in seconds)",
                    min = 0.1,
                    max = 10.0,
                    step = 0.1,
                    order = 3,
                    width = "normal",
                    hidden = function()
                        local triggerMode = channel.triggerMode or "interval"
                        return triggerMode ~= "interval" and triggerMode ~= "outofcombat"
                    end,
                    get = function() return channel.interval end,
                    set = function(_, value)
                        KOL:BatchConfigure(channelName, { interval = value })
                        KOL:PrintTag("Batch [" .. PASTEL_YELLOW(channelName) .. "] interval set to: " .. PASTEL_YELLOW(value .. "s"))
                    end,
                },

                processMode = {
                    type = "select",
                    name = "Process Mode",
                    desc = "How actions are processed each tick",
                    values = {
                        all = "All - Process all queued actions",
                        priority = "Priority - Process by priority order",
                        limit = "Limit - Process up to maxPerTick",
                    },
                    order = 2,
                    width = "normal",
                    get = function() return channel.processMode end,
                    set = function(_, value)
                        KOL:BatchConfigure(channelName, { processMode = value })
                        KOL:PrintTag("Batch [" .. PASTEL_YELLOW(channelName) .. "] processMode set to: " .. PASTEL_YELLOW(value))
                    end,
                },

                triggerMode = {
                    type = "select",
                    name = "Trigger Mode",
                    desc = "When this batch channel runs:\n• Interval: Runs on timer (every X seconds)\n• Binding: Runs when keybinding is pressed\n• Out of Combat: Timer pauses during combat",
                    values = {
                        interval = "Interval - Timer based",
                        binding = "Binding - Keybind trigger",
                        outofcombat = "Out of Combat",
                    },
                    order = 2,
                    width = "normal",
                    get = function() return channel.triggerMode or "interval" end,
                    set = function(_, value)
                        KOL:BatchConfigure(channelName, { triggerMode = value })
                        KOL:PrintTag("Batch [" .. PASTEL_YELLOW(channelName) .. "] triggerMode set to: " .. PASTEL_YELLOW(value))
                        -- Refresh UI to show/hide interval and keybinding fields
                        Batch:RefreshBatchConfigUI()
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                    end,
                },

                maxQueueSize = {
                    type = "range",
                    name = "Max Queue Size",
                    desc = "Maximum number of actions that can be queued",
                    min = 1,
                    max = 100,
                    step = 1,
                    order = 3,
                    width = "normal",
                    get = function() return channel.maxQueueSize end,
                    set = function(_, value)
                        KOL:BatchConfigure(channelName, { maxQueueSize = value })
                        KOL:PrintTag("Batch [" .. PASTEL_YELLOW(channelName) .. "] maxQueueSize set to: " .. PASTEL_YELLOW(value))
                    end,
                },

                keybinding = {
                    type = "input",
                    name = "Keybinding",
                    desc = "Keybinding to trigger this batch channel (e.g., 'CTRL-SHIFT-M')\nFormat: CTRL-SHIFT-ALT-KEY",
                    order = 4,
                    width = "full",
                    hidden = function() return (channel.triggerMode or "interval") ~= "binding" end,
                    get = function() return channel.keybinding or "" end,
                    set = function(_, value)
                        KOL:BatchConfigure(channelName, { keybinding = value, triggerMode = "binding" })
                        KOL:PrintTag("Batch [" .. PASTEL_YELLOW(channelName) .. "] keybinding set to: " .. PASTEL_YELLOW(value))
                    end,
                },

                spacer = {
                    type = "description",
                    name = " ",
                    order = 5,
                },

                viewQueue = {
                    type = "execute",
                    name = "View Queue",
                    desc = "Open a window showing all queued actions for this channel",
                    order = 6,
                    width = "half",
                    func = function()
                        ShowQueueViewer(channelName)
                    end,
                },

                startStop = {
                    type = "execute",
                    name = function()
                        return channel.isRunning and "Stop" or "Start"
                    end,
                    desc = function()
                        return channel.isRunning and "Stop this batch channel" or "Start this batch channel"
                    end,
                    order = 7,
                    width = "half",
                    func = function()
                        if channel.isRunning then
                            KOL:BatchStop(channelName)
                        else
                            KOL:BatchStart(channelName)
                        end
                        -- Refresh UI
                        Batch:RefreshBatchConfigUI()
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                    end,
                },

                flush = {
                    type = "execute",
                    name = "Flush Queue",
                    desc = "Process all queued actions immediately",
                    order = 8,
                    width = "half",
                    func = function()
                        KOL:BatchFlush(channelName)
                        -- Refresh UI
                        Batch:RefreshBatchConfigUI()
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                    end,
                },

                clear = {
                    type = "execute",
                    name = "Clear Queue",
                    desc = "Remove all queued actions",
                    order = 9,
                    width = "half",
                    func = function()
                        KOL:BatchClear(channelName)
                        -- Refresh UI
                        Batch:RefreshBatchConfigUI()
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
                    end,
                },
            }
        }

        order = order + 10
    end

    -- Notify config system of changes
    if LibStub("AceConfigRegistry-3.0") then
        LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
    end
end

-- Hook into BatchAdd to refresh UI when actions are added
local originalBatchAdd = KOL.BatchAdd
function KOL:BatchAdd(...)
    local result = originalBatchAdd(self, ...)
    if result and Batch.RefreshBatchConfigUI then
        Batch:RefreshBatchConfigUI()
    end
    return result
end

-- Register initialization callback (ui.lua will call this when ready)
KOL.InitializeBatchUI = function()
    Batch:InitializeConfigUI()
end
