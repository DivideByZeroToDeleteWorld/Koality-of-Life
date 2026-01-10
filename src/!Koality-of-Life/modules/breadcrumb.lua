local KOL = KoalityOfLife
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

KOL.Breadcrumb = {}
local Breadcrumb = KOL.Breadcrumb

Breadcrumb.currentPath = {}
Breadcrumb.initialized = false

-- Section names and their signature colors
local SECTION_DATA = {
    [""] = { name = "Main", color = "FFFFFF" },
    -- Top-level tabs
    general = { name = "General", color = "FFDD00" },
    tracker = { name = "Progress Tracker", color = "66FFCC" },
    tweaks = { name = "Tweaks", color = "88DDFF" },
    commandblocks = { name = "Command Blocks", color = "FFAA66" },
    -- General sub-tabs
    main = { name = "Main", color = "FFDD00" },
    debug = { name = "Debug", color = "FF6666" },
    colors = { name = "Colors", color = "FF88CC" },
    -- Progress Tracker sub-tabs
    generalTracker = { name = "General", color = "FFDD00" },
    dungeons = { name = "Dungeons", color = "88DDFF" },
    raids = { name = "Raids", color = "FF6666" },
    custom = { name = "Custom", color = "AA66FF" },
    -- Tweaks sub-tabs
    synastria = { name = "Synastria", color = "00CCFF" },
    vendors = { name = "Vendors", color = "FFDD00" },
    -- Command Blocks sub-tabs
    combat = { name = "Combat", color = "FF6666" },
    social = { name = "Social", color = "88DDFF" },
    utility = { name = "Utility", color = "FFDD00" },
    binds = { name = "Binds", color = "88FF88" },
    batch = { name = "Batch", color = "FFAA66" },
    -- Other
    profiles = { name = "Profiles", color = "AAAAAA" },
    notify = { name = "Notify", color = "FF88CC" },
    batchSystem = { name = "Batch System", color = "FFAA66" },
    media = { name = "Media", color = "88DDFF" },
}

-- Tabs that have sub-tabs (need 2+ path segments for full path)
local TABS_WITH_SUBTABS = {
    general = true,
    tracker = true,
    tweaks = true,
    commandblocks = true,
}

-- Clear breadcrumb from root args only
function Breadcrumb:ClearBreadcrumbs()
    if not KOL.configOptions or not KOL.configOptions.args then
        return
    end

    for key in pairs(KOL.configOptions.args) do
        if key:match("^_breadcrumb") then
            KOL.configOptions.args[key] = nil
        end
    end
end

function Breadcrumb:SetPath(...)
    self.currentPath = {...}

    local pathStr = "Root"
    for i, segment in ipairs(self.currentPath) do
        if segment and segment ~= "" then
            local data = SECTION_DATA[segment]
            pathStr = pathStr .. " > " .. (data and data.name or segment)
        end
    end
    KOL:DebugPrint("Breadcrumb: " .. pathStr)

    self:UpdateBreadcrumbs()
end

function Breadcrumb:UpdateBreadcrumbs()
    if not KOL.configOptions or not KOL.configOptions.args then
        return
    end

    -- Clear existing breadcrumb
    self:ClearBreadcrumbs()

    -- Build the breadcrumb text
    local breadcrumbText = "|cFF888888Root|r"

    for i, segmentId in ipairs(self.currentPath) do
        if segmentId and segmentId ~= "" then
            local data = SECTION_DATA[segmentId] or { name = segmentId, color = "FFFFFF" }
            breadcrumbText = breadcrumbText .. " |cFF555555>|r |cFF" .. data.color .. data.name .. "|r"
        end
    end

    -- Always add breadcrumb to ROOT args (stays at top, above tabs)
    KOL.configOptions.args._breadcrumb_text = {
        type = "description",
        name = breadcrumbText .. "\n",
        fontSize = "medium",
        width = "full",
        order = 0.5,  -- After header (0), before tabs (1+)
    }

    LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
end

function Breadcrumb:Initialize()
    if self.initialized then
        return
    end

    -- Hook FeedGroup - this is called when rendering groups/tabs
    if AceConfigDialog.FeedGroup then
        local originalFeedGroup = AceConfigDialog.FeedGroup
        AceConfigDialog.FeedGroup = function(dialog, appName, options, container, rootframe, path, ...)
            originalFeedGroup(dialog, appName, options, container, rootframe, path, ...)
            if appName == "KoalityOfLife" and path and type(path) == "table" and #path > 0 then
                -- Skip partial paths for tabs that have sub-tabs
                -- (wait for the full path with sub-tab included)
                local firstSegment = path[1]
                if #path == 1 and TABS_WITH_SUBTABS[firstSegment] then
                    return  -- Wait for full path
                end
                KOL.Breadcrumb:SetPath(unpack(path))
            end
        end
    end

    -- Set initial empty path (shows just "Root")
    self:SetPath()

    self.initialized = true
end

KOL.InitializeBreadcrumb = function()
    KOL.Breadcrumb:Initialize()
end
