-- ============================================================================
-- !Koality-of-Life: Breadcrumb Navigation System
-- ============================================================================
-- Provides clickable breadcrumb navigation at the top of config panels
-- Shows: Main → Binds → Profile Manager (with current location highlighted)
-- ============================================================================

local KOL = KoalityOfLife
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- ============================================================================
-- Module Initialization
-- ============================================================================

KOL.Breadcrumb = {}
local Breadcrumb = KOL.Breadcrumb

-- Current navigation path
Breadcrumb.currentPath = {}
Breadcrumb.initialized = false

-- ============================================================================
-- Configuration
-- ============================================================================

-- Color for inactive breadcrumbs (all non-current segments)
local BREADCRUMB_INACTIVE_COLOR = "PASTEL_BLUE"  -- Nice soft blue

-- Color for current/selected breadcrumb (the one you're on)
local BREADCRUMB_CURRENT_COLOR = "PASTEL_YELLOW"  -- Bright to stand out

-- Section ID to display name mapping
local SECTION_NAMES = {
    [""] = "Main",
    general = "General",
    binds = "Binds",
    tracker = "Tracker",
    batch = "Batch",
    debug = "Debug",
    colors = "Colors",
    tweaks = "Tweaks",
    profiles = "Profile Manager",
    combat = "Combat",
    social = "Social",
    utility = "Utility",
}

-- ============================================================================
-- Path Management
-- ============================================================================

-- Calculate full breadcrumb path based on current location
function Breadcrumb:CurrentCrumb(sectionName)
    -- This will be called when navigating to update the path
    -- For now, we track via SelectGroup hook
    self:UpdateBreadcrumbs()
end

-- Update current path from navigation
function Breadcrumb:SetPath(...)
    self.currentPath = {...}

    -- Debug output
    local pathStr = "Main"
    for i, segment in ipairs(self.currentPath) do
        if segment and segment ~= "" then
            pathStr = pathStr .. " → " .. (SECTION_NAMES[segment] or segment)
        end
    end
    KOL:DebugPrint("Breadcrumb: " .. pathStr)

    self:UpdateBreadcrumbs()
end

-- ============================================================================
-- Breadcrumb Rendering
-- ============================================================================

-- Clear existing breadcrumb elements
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

-- Update breadcrumbs in config panel
function Breadcrumb:UpdateBreadcrumbs()
    if not KOL.configOptions or not KOL.configOptions.args then
        return
    end

    self:ClearBreadcrumbs()

    -- Build breadcrumb segments
    local segments = {}

    -- Always start with Main
    table.insert(segments, {
        id = "",
        name = "Main",
        path = {},
        isCurrent = (#self.currentPath == 0)
    })

    -- Add each path segment
    for i, segmentId in ipairs(self.currentPath) do
        if segmentId and segmentId ~= "" then
            local pathToHere = {}
            for j = 1, i do
                table.insert(pathToHere, self.currentPath[j])
            end

            table.insert(segments, {
                id = segmentId,
                name = SECTION_NAMES[segmentId] or segmentId,
                path = pathToHere,
                isCurrent = (i == #self.currentPath)
            })
        end
    end

    -- Create breadcrumb display as a single line
    local order = -100

    -- Create each segment as a clickable execute button
    for i, segment in ipairs(segments) do
        -- Determine color: current = bright, inactive = soft
        local color = segment.isCurrent and BREADCRUMB_CURRENT_COLOR or BREADCRUMB_INACTIVE_COLOR

        -- Create clickable label (execute button styled as text)
        local buttonKey = "_breadcrumb_seg_" .. i
        KOL.configOptions.args[buttonKey] = {
            type = "execute",
            name = COLOR(color, segment.name),
            desc = segment.isCurrent and "Current location" or ("Navigate to " .. segment.name),
            width = "normal",
            order = order,
            func = function()
                if not segment.isCurrent then
                    if #segment.path == 0 then
                        -- Go to root
                        AceConfigDialog:SelectGroup("KoalityOfLife")
                    else
                        -- Navigate to this segment
                        AceConfigDialog:SelectGroup("KoalityOfLife", unpack(segment.path))
                    end
                end
            end,
        }
        order = order + 1

        -- Add separator arrow (unless this is the last segment)
        if i < #segments then
            local sepKey = "_breadcrumb_sep_" .. i
            KOL.configOptions.args[sepKey] = {
                type = "description",
                name = " " .. CHAR("RIGHT") .. " ",
                width = "normal",
                order = order,
            }
            order = order + 1
        end
    end

    -- Add spacer after breadcrumbs
    KOL.configOptions.args._breadcrumb_spacer = {
        type = "header",
        name = "",
        order = -50,
    }

    -- Refresh UI
    LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
end

-- ============================================================================
-- Navigation Hooks
-- ============================================================================

-- Hook into AceConfigDialog navigation
function Breadcrumb:Initialize()
    if self.initialized then
        return
    end

    -- Only initialize if devMode is enabled (hidden in production)
    if not (KOL.db and KOL.db.profile and KOL.db.profile.devMode) then
        KOL:DebugPrint("Breadcrumb: Skipped (devMode disabled)")
        return
    end

    KOL:DebugPrint("Breadcrumb: Initializing navigation tracking")

    -- Store original SelectGroup function
    local originalSelectGroup = AceConfigDialog.SelectGroup

    -- Hook SelectGroup to track navigation
    AceConfigDialog.SelectGroup = function(self, appName, ...)
        -- Call original function first
        originalSelectGroup(self, appName, ...)

        -- Track navigation for our addon
        if appName == "KoalityOfLife" then
            KOL.Breadcrumb:SetPath(...)
        end
    end

    -- Initialize with root path
    self:SetPath()

    self.initialized = true
    KOL:DebugPrint("Breadcrumb: Initialization complete")
end

-- ============================================================================
-- Public API
-- ============================================================================

-- Global function for manual breadcrumb updates (if needed)
function CurrentCrumb(sectionName)
    if KOL.Breadcrumb then
        KOL.Breadcrumb:CurrentCrumb(sectionName)
    end
end

-- ============================================================================
-- Registration
-- ============================================================================

-- Register initialization callback
KOL.InitializeBreadcrumb = function()
    KOL.Breadcrumb:Initialize()
end
