local KOL = KoalityOfLife
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

KOL.Breadcrumb = {}
local Breadcrumb = KOL.Breadcrumb

Breadcrumb.currentPath = {}
Breadcrumb.initialized = false

local BREADCRUMB_INACTIVE_COLOR = "PASTEL_BLUE"
local BREADCRUMB_CURRENT_COLOR = "PASTEL_YELLOW"

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

function Breadcrumb:CurrentCrumb(sectionName)
    self:UpdateBreadcrumbs()
end

function Breadcrumb:SetPath(...)
    self.currentPath = {...}

    local pathStr = "Main"
    for i, segment in ipairs(self.currentPath) do
        if segment and segment ~= "" then
            pathStr = pathStr .. " → " .. (SECTION_NAMES[segment] or segment)
        end
    end
    KOL:DebugPrint("Breadcrumb: " .. pathStr)

    self:UpdateBreadcrumbs()
end

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

function Breadcrumb:UpdateBreadcrumbs()
    if not KOL.configOptions or not KOL.configOptions.args then
        return
    end

    self:ClearBreadcrumbs()

    local segments = {}

    table.insert(segments, {
        id = "",
        name = "Main",
        path = {},
        isCurrent = (#self.currentPath == 0)
    })

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

    local order = -100

    for i, segment in ipairs(segments) do
        local color = segment.isCurrent and BREADCRUMB_CURRENT_COLOR or BREADCRUMB_INACTIVE_COLOR

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
                        AceConfigDialog:SelectGroup("KoalityOfLife")
                    else
                        AceConfigDialog:SelectGroup("KoalityOfLife", unpack(segment.path))
                    end
                end
            end,
        }
        order = order + 1

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

    KOL.configOptions.args._breadcrumb_spacer = {
        type = "header",
        name = "",
        order = -50,
    }

    LibStub("AceConfigRegistry-3.0"):NotifyChange("KoalityOfLife")
end

function Breadcrumb:Initialize()
    if self.initialized then
        return
    end

    if not (KOL.db and KOL.db.profile and KOL.db.profile.devMode) then
        KOL:DebugPrint("Breadcrumb: Skipped (devMode disabled)")
        return
    end

    KOL:DebugPrint("Breadcrumb: Initializing navigation tracking")

    local originalSelectGroup = AceConfigDialog.SelectGroup

    AceConfigDialog.SelectGroup = function(self, appName, ...)
        originalSelectGroup(self, appName, ...)

        if appName == "KoalityOfLife" then
            KOL.Breadcrumb:SetPath(...)
        end
    end

    self:SetPath()

    self.initialized = true
    KOL:DebugPrint("Breadcrumb: Initialization complete")
end

function CurrentCrumb(sectionName)
    if KOL.Breadcrumb then
        KOL.Breadcrumb:CurrentCrumb(sectionName)
    end
end

KOL.InitializeBreadcrumb = function()
    KOL.Breadcrumb:Initialize()
end
