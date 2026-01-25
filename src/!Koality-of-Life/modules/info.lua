-- ============================================================================
-- Info Module - Data Output System
-- ============================================================================
-- Provides /kdo command for displaying various data outputs in styled frames
-- ============================================================================

local KOL = KoalityOfLife

KOL.Info = {}
local Info = KOL.Info

-- ============================================================================
-- Data Output Registry
-- ============================================================================

Info.outputs = {}
Info.frames = {}

-- Register a data output
function Info:RegisterOutput(name, config)
    self.outputs[name:lower()] = {
        name = name,
        description = config.description or "No description",
        handler = config.handler,
    }
end

-- Get all registered outputs
function Info:GetOutputs()
    return self.outputs
end

-- ============================================================================
-- Classic Dungeon Challenge Data
-- ============================================================================
-- Format: {maxLevel, zoneName, instanceId (for speedStacks lookup)}

Info.dungeonChallengeData = {
    -- ========================================================================
    -- Classic Dungeons (MaxLevel 15-60) - Normal only
    -- ========================================================================
    {15, "Ragefire Chasm", "rfc_n"},
    {19, "Deadmines", "dm_n"},
    {19, "Wailing Caverns", "wc_n"},
    {20, "Shadowfang Keep", "sfk_n"},
    {23, "Blackfathom Deeps", "bfd_n"},
    {24, "Stockade", "stocks_n"},
    {26, "Razorfen Kraul", "rfk_n"},
    {27, "Gnomeregan", "gnomer_n"},
    {36, "Razorfen Downs", "rfd_n"},
    {39, "Uldaman", "uld_n"},
    {39, "Scarlet Monastery", "sm_n"},
    {44, "Zul'Farrak", "zf_n"},
    {47, "Maraudon", "mara_n"},
    {49, "Sunken Temple", "st_n"},
    {55, "Blackrock Depths", "brd_n"},
    {60, "Blackrock Spire", "brs_n"},
    {60, "Scholomance", "scholo_n"},
    {60, "Stratholme", "strat_n"},
    {60, "Dire Maul", "diremaul_n"},

    -- ========================================================================
    -- Classic Raids (MaxLevel 60) - Normal only
    -- ========================================================================
    {60, "Zul'Gurub", "zg_20"},
    {60, "Ruins of Ahn'Qiraj", "aq20_20"},
    {60, "Molten Core", "mc_40"},
    {60, "Blackwing Lair", "bwl_40"},
    {60, "Temple of Ahn'Qiraj", "aq40_40"},

    -- ========================================================================
    -- TBC Dungeons - Normal (MaxLevel 70)
    -- ========================================================================
    {70, "Hellfire Ramparts", "hr_n"},
    {70, "The Blood Furnace", "bf_n"},
    {70, "The Slave Pens", "sp_n"},
    {70, "The Underbog", "ub_n"},
    {70, "Mana-Tombs", "mt_n"},
    {70, "Auchenai Crypts", "ac_n"},
    {70, "Sethekk Halls", "sh_n"},
    {70, "Shadow Labyrinth", "sl_n"},
    {70, "Shattered Halls", "shh_n"},
    {70, "The Steamvault", "sv_n"},
    {70, "The Botanica", "bot_n"},
    {70, "The Mechanar", "mech_n"},
    {70, "The Arcatraz", "arc_n"},
    {70, "Old Hillsbrad Foothills", "ohf_n"},
    {70, "The Black Morass", "bm_n"},
    {70, "Magisters' Terrace", "mgt_n"},

    -- ========================================================================
    -- TBC Dungeons - Heroic (MaxLevel 70)
    -- ========================================================================
    {70, "Hellfire Ramparts", "hr_h"},
    {70, "The Blood Furnace", "bf_h"},
    {70, "The Slave Pens", "sp_h"},
    {70, "The Underbog", "ub_h"},
    {70, "Mana-Tombs", "mt_h"},
    {70, "Auchenai Crypts", "ac_h"},
    {70, "Sethekk Halls", "sh_h"},
    {70, "Shadow Labyrinth", "sl_h"},
    {70, "Shattered Halls", "shh_h"},
    {70, "The Steamvault", "sv_h"},
    {70, "The Botanica", "bot_h"},
    {70, "The Mechanar", "mech_h"},
    {70, "The Arcatraz", "arc_h"},
    {70, "Old Hillsbrad Foothills", "ohf_h"},
    {70, "The Black Morass", "bm_h"},
    {70, "Magisters' Terrace", "mgt_h"},

    -- ========================================================================
    -- TBC Raids - Normal (MaxLevel 70)
    -- ========================================================================
    {70, "Karazhan", "kara_10n"},
    {70, "Gruul's Lair", "gruul_25n"},
    {70, "Magtheridon's Lair", "mag_25n"},
    {70, "Zul'Aman", "za_10n"},
    {70, "Serpentshrine Cavern", "ssc_25n"},
    {70, "Tempest Keep: The Eye", "tk_25n"},
    {70, "Hyjal Summit", "hyjal_25n"},
    {70, "Black Temple", "bt_25n"},
    {70, "Sunwell Plateau", "swp_25n"},

    -- ========================================================================
    -- WotLK Dungeons - Normal (MaxLevel 80)
    -- ========================================================================
    {80, "Utgarde Keep", "uk_n"},
    {80, "The Nexus", "nex_n"},
    {80, "Azjol-Nerub", "an_n"},
    {80, "Ahn'kahet: The Old Kingdom", "ok_n"},
    {80, "Drak'Tharon Keep", "dtk_n"},
    {80, "Violet Hold", "vh_n"},
    {80, "Gundrak", "gd_n"},
    {80, "Halls of Stone", "hos_n"},
    {80, "Halls of Lightning", "hol_n"},
    {80, "The Oculus", "oc_n"},
    {80, "Utgarde Pinnacle", "up_n"},
    {80, "Culling of Stratholme", "cos_n"},
    {80, "Trial of the Champion", "toc5_n"},
    {80, "Forge of Souls", "fos_n"},
    {80, "Pit of Saron", "pos_n"},
    {80, "Halls of Reflection", "hor_n"},

    -- ========================================================================
    -- WotLK Dungeons - Heroic (MaxLevel 80)
    -- ========================================================================
    {80, "Utgarde Keep", "uk_h"},
    {80, "The Nexus", "nex_h"},
    {80, "Azjol-Nerub", "an_h"},
    {80, "Ahn'kahet: The Old Kingdom", "ok_h"},
    {80, "Drak'Tharon Keep", "dtk_h"},
    {80, "Violet Hold", "vh_h"},
    {80, "Gundrak", "gd_h"},
    {80, "Halls of Stone", "hos_h"},
    {80, "Halls of Lightning", "hol_h"},
    {80, "The Oculus", "oc_h"},
    {80, "Utgarde Pinnacle", "up_h"},
    {80, "Culling of Stratholme", "cos_h"},
    {80, "Trial of the Champion", "toc5_h"},
    {80, "Forge of Souls", "fos_h"},
    {80, "Pit of Saron", "pos_h"},
    {80, "Halls of Reflection", "hor_h"},

    -- ========================================================================
    -- WotLK Dungeons - Mythic (MaxLevel 80)
    -- ========================================================================
    {80, "Utgarde Keep", "uk_m"},
    {80, "The Nexus", "nex_m"},
    {80, "Azjol-Nerub", "an_m"},
    {80, "Ahn'kahet: The Old Kingdom", "ok_m"},
    {80, "Drak'Tharon Keep", "dtk_m"},
    {80, "Violet Hold", "vh_m"},
    {80, "Gundrak", "gd_m"},
    {80, "Halls of Stone", "hos_m"},
    {80, "Halls of Lightning", "hol_m"},
    {80, "The Oculus", "oc_m"},
    {80, "Utgarde Pinnacle", "up_m"},
    {80, "Culling of Stratholme", "cos_m"},
    {80, "Trial of the Champion", "toc5_m"},
    {80, "Forge of Souls", "fos_m"},
    {80, "Pit of Saron", "pos_m"},
    {80, "Halls of Reflection", "hor_m"},

    -- ========================================================================
    -- WotLK Raids - Normal (MaxLevel 80)
    -- ========================================================================
    {80, "Naxxramas (10)", "naxx_10"},
    {80, "Naxxramas (25)", "naxx_25"},
    {80, "Obsidian Sanctum (10)", "os_10"},
    {80, "Obsidian Sanctum (25)", "os_25"},
    {80, "Eye of Eternity (10)", "eoe_10"},
    {80, "Eye of Eternity (25)", "eoe_25"},
    {80, "Vault of Archavon (10)", "voa_10"},
    {80, "Vault of Archavon (25)", "voa_25"},
    {80, "Ulduar (10)", "uld_10"},
    {80, "Ulduar (25)", "uld_25"},
    {80, "Trial of the Crusader (10)", "toc_10"},
    {80, "Trial of the Crusader (25)", "toc_25"},
    {80, "Onyxia's Lair (10)", "ony_10"},
    {80, "Onyxia's Lair (25)", "ony_25"},
    {80, "Icecrown Citadel (10)", "icc_10"},
    {80, "Icecrown Citadel (25)", "icc_25"},
    {80, "Ruby Sanctum (10)", "rs_10"},
    {80, "Ruby Sanctum (25)", "rs_25"},

    -- ========================================================================
    -- WotLK Raids - Heroic (MaxLevel 80)
    -- ========================================================================
    {80, "Trial of the Crusader (10H)", "toc_10h"},
    {80, "Trial of the Crusader (25H)", "toc_25h"},
    {80, "Icecrown Citadel (10H)", "icc_10h"},
    {80, "Icecrown Citadel (25H)", "icc_25h"},
    {80, "Ruby Sanctum (10H)", "rs_10h"},
    {80, "Ruby Sanctum (25H)", "rs_25h"},
}

-- ============================================================================
-- Instance Type Detection
-- ============================================================================
-- Returns: type, sortOrder, color
-- Types: "dungeon_normal", "dungeon_heroic", "dungeon_mythic", "raid_normal", "raid_heroic"
-- Dungeon Colors: Paisley (tan), Periwinkle (light purple), Pastel Magenta (soft pink)
-- Raid Colors: Gold family (normal) with size variations, Violet family (heroic) with size variations

function Info:GetInstanceTypeInfo(instanceId)
    if not instanceId then
        return "unknown", 99, "AAAAAA"
    end

    -- Dungeon Colors
    local colorPaisley = "DDBB88"        -- Tan/beige for Normal Dungeons
    local colorPeriwinkle = "9999FF"     -- Light purple for Heroic Dungeons
    local colorPastelMagenta = "FF88CC"  -- Soft pink for Mythic Dungeons

    -- Normal Raid Colors (very distinct hues by size)
    local colorRaid10N = "88EEFF"        -- Cyan/aqua for 10-man normal
    local colorRaid20N = "FF9933"        -- Bright orange for 20-man
    local colorRaid25N = "EEFF44"        -- Lime/yellow-green for 25-man normal
    local colorRaid40N = "FF7777"        -- Coral/salmon for 40-man

    -- Heroic Raid Colors (very distinct by size)
    local colorRaid10H = "FF99DD"        -- Bright pink for 10-man heroic
    local colorRaid25H = "AA44FF"        -- Deep violet/purple for 25-man heroic

    -- Check raid heroic patterns first (most specific)
    if instanceId:match("_10h$") then
        return "raid_heroic", 5, colorRaid10H
    end
    if instanceId:match("_25h$") then
        return "raid_heroic", 5, colorRaid25H
    end

    -- Check raid normal patterns (with size variations)
    if instanceId:match("_10n?$") then
        return "raid_normal", 4, colorRaid10N
    end
    if instanceId:match("_20$") then
        return "raid_normal", 4, colorRaid20N
    end
    if instanceId:match("_25n?$") then
        return "raid_normal", 4, colorRaid25N
    end
    if instanceId:match("_40$") then
        return "raid_normal", 4, colorRaid40N
    end

    -- Dungeon patterns
    if instanceId:match("_m$") then
        return "dungeon_mythic", 3, colorPastelMagenta
    end
    if instanceId:match("_h$") then
        return "dungeon_heroic", 2, colorPeriwinkle
    end
    if instanceId:match("_n$") then
        return "dungeon_normal", 1, colorPaisley
    end

    return "unknown", 99, "AAAAAA"
end

-- ============================================================================
-- Difficulty Display Helper
-- ============================================================================
-- Returns difficulty string based on instance ID suffix
-- 5N = 5-man Normal, 5H = 5-man Heroic, 10N/25N = raid normal, 10H/25H = raid heroic

function Info:GetDifficultyDisplay(instanceId)
    if not instanceId then return "-" end

    -- Raid heroic (check first - more specific)
    if instanceId:match("_10h$") then return "10H" end
    if instanceId:match("_25h$") then return "25H" end

    -- Raid normal (with or without 'n' suffix)
    if instanceId:match("_10n?$") then return "10N" end
    if instanceId:match("_25n?$") then return "25N" end

    -- Classic raid sizes
    if instanceId:match("_40$") then return "40" end
    if instanceId:match("_20$") then return "20" end

    -- Dungeon difficulties
    if instanceId:match("_m$") then return "5M" end
    if instanceId:match("_h$") then return "5H" end
    if instanceId:match("_n$") then return "5N" end

    return "-"
end

-- ============================================================================
-- Speed Stack Color Gradient
-- ============================================================================
-- Returns a hex color based on proximity to max (50)
-- 0 = Red, 25 = Yellow, 50 = Green

function Info:GetSpeedStackColor(stacks)
    if not stacks or stacks <= 0 then
        return "FF4444"  -- Red for no stacks
    end

    local maxStacks = 50
    local ratio = math.min(stacks / maxStacks, 1)

    -- Gradient: Red (0) -> Yellow (0.5) -> Green (1)
    local r, g, b
    if ratio < 0.5 then
        -- Red to Yellow
        local t = ratio * 2  -- 0 to 1
        r = 1
        g = t
        b = 0
    else
        -- Yellow to Green
        local t = (ratio - 0.5) * 2  -- 0 to 1
        r = 1 - t
        g = 1
        b = 0
    end

    return string.format("%02X%02X%02X",
        math.floor(r * 255),
        math.floor(g * 255),
        math.floor(b * 255)
    )
end

-- ============================================================================
-- Get Speed Stacks for Instance
-- ============================================================================

function Info:GetSpeedStacks(instanceId)
    if not KOL.db or not KOL.db.profile then return 0 end
    if not KOL.db.profile.tracker then return 0 end
    if not KOL.db.profile.tracker.dungeonChallenge then return 0 end
    if not KOL.db.profile.tracker.dungeonChallenge.speedStacks then return 0 end

    return KOL.db.profile.tracker.dungeonChallenge.speedStacks[instanceId] or 0
end

-- ============================================================================
-- DungeonChallenge Data Output
-- ============================================================================

function Info:ShowDungeonChallenge()
    local UIFactory = KOL.UIFactory
    if not UIFactory then
        KOL:PrintTag("|cFFFF0000Error:|r UIFactory not available")
        return
    end

    -- Reuse existing frame or create new one
    local frameName = "KOL_DataOutput_DungeonChallenge"
    local frame = self.frames.dungeonChallenge

    if not frame then
        -- Create main styled frame
        frame = UIFactory:CreateStyledFrame(UIParent, frameName, 420, 450, {
            movable = true,
            closable = true,
        })

        -- Title bar using UIFactory
        local titleBar, titleText, closeBtn = UIFactory:CreateTitleBar(frame, 26, "DungeonChallenge - Data Output", {
            textColor = {r = 0.53, g = 0.8, b = 1, a = 1},  -- Light blue
        })

        -- Create table container (below title bar)
        local tableContainer = CreateFrame("Frame", nil, frame)
        tableContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -32)
        tableContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)

        -- Create the data table using UIFactory
        local dataTable = UIFactory:CreateTable(tableContainer, {
            columns = {
                {name = "Dungeon/Raid", width = 180},
                {name = "Diff", width = 35, align = "CENTER"},
                {name = "MaxLvl", width = 50, align = "CENTER"},
                {name = "SpeedStacks", width = 80, align = "CENTER"},
            },
            rowHeight = 18,
            headerHeight = 20,
            fontSize = 10,
            scrollbarWidth = 8,
            hideScrollButtons = true,
            inset = {top = 0, bottom = 0, left = 0, right = 0},
        })
        dataTable:SetAllPoints(tableContainer)

        frame.dataTable = dataTable
        frame.tableContainer = tableContainer
        self.frames.dungeonChallenge = frame
    end

    -- Center the frame first so it has proper dimensions
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:Show()

    -- Populate the data after frame is shown (so widths are calculated)
    C_Timer.After(0, function()
        self:RefreshDungeonChallengeData(frame)
    end)
end

function Info:RefreshDungeonChallengeData(frame)
    local dataTable = frame.dataTable
    if not dataTable then return end

    -- Expansion colors (Nuclear variants)
    local expansionColors = {
        [60] = "FF4444",   -- Nuclear Red for Classic
        [70] = "44FF44",   -- Nuclear Green for The Burning Crusade
        [80] = "8888FF",   -- Nuclear Periwinkle for Wrath of the Lich King
    }

    local expansionNames = {
        [60] = "Classic",
        [70] = "The Burning Crusade",
        [80] = "Wrath of the Lich King",
    }

    local raidSectionNames = {
        [60] = "CLASSIC RAIDS",
        [70] = "TBC RAIDS",
        [80] = "WOTLK RAIDS",
    }

    -- Build table data with sorting info
    local rawData = {}

    for _, data in ipairs(self.dungeonChallengeData) do
        local maxLevel = data[1]
        local dungeonName = data[2]
        local instanceId = data[3]

        -- Determine expansion
        local expansion = maxLevel <= 60 and 60 or (maxLevel <= 70 and 70 or 80)

        -- Get instance type info for color and sorting
        local instanceType, sortOrder, nameColor = self:GetInstanceTypeInfo(instanceId)

        -- Get difficulty display from instance ID
        local difficulty = self:GetDifficultyDisplay(instanceId)

        -- Determine raid size for sorting (10 < 20 < 25 < 40)
        local raidSize = 0
        if instanceId:match("_10h?$") then raidSize = 10
        elseif instanceId:match("_20$") then raidSize = 20
        elseif instanceId:match("_25h?n?$") then raidSize = 25
        elseif instanceId:match("_40$") then raidSize = 40
        end

        -- Strip raid size from display name (since it's shown in Diff column)
        local displayName = dungeonName
        if raidSize > 0 then
            displayName = dungeonName:gsub(" %(%d+H?%)$", "")
        end

        -- Get speed stacks for this instance
        local speedStacks = self:GetSpeedStacks(instanceId)

        -- Build speed stacks display
        local speedDisplay
        if speedStacks >= 50 then
            speedDisplay = {text = "MAX", color = "00FF00"}
        elseif speedStacks > 0 then
            speedDisplay = {text = tostring(speedStacks), color = self:GetSpeedStackColor(speedStacks)}
        else
            speedDisplay = {text = "-", color = "666666"}
        end

        -- Store with sort keys
        table.insert(rawData, {
            expansion = expansion,
            maxLevel = maxLevel,
            dungeonName = dungeonName,
            displayName = displayName,
            instanceId = instanceId,
            difficulty = difficulty,
            sortOrder = sortOrder,
            raidSize = raidSize,
            nameColor = nameColor,
            speedDisplay = speedDisplay,
        })
    end

    -- Sort: by expansion, then by type, then by raid size, then by maxLevel, then alphabetically
    table.sort(rawData, function(a, b)
        -- Primary sort: by expansion
        if a.expansion ~= b.expansion then
            return a.expansion < b.expansion
        end

        -- Secondary sort: by type (Normal Dungeon -> Heroic Dungeon -> Mythic Dungeon -> Normal Raid -> Heroic Raid)
        if a.sortOrder ~= b.sortOrder then
            return a.sortOrder < b.sortOrder
        end

        -- Tertiary sort: by raid size (10 < 20 < 25 < 40) - only applies to raids
        if a.raidSize ~= b.raidSize then
            return a.raidSize < b.raidSize
        end

        -- Quaternary sort: by maxLevel
        if a.maxLevel ~= b.maxLevel then
            return a.maxLevel < b.maxLevel
        end

        -- Quinary sort: alphabetically by display name
        return a.displayName < b.displayName
    end)

    -- Build final table data with section headers
    local tableData = {}
    local currentExpansion = nil
    local inRaidSection = false  -- Track if we've entered raids for this expansion

    for _, entry in ipairs(rawData) do
        -- Insert section header when expansion changes
        if entry.expansion ~= currentExpansion then
            currentExpansion = entry.expansion
            inRaidSection = false  -- Reset raid section flag for new expansion
            local expColor = expansionColors[currentExpansion] or "FFFFFF"
            local expName = expansionNames[currentExpansion] or "Unknown"

            -- Section header row (expansion name with decorative separators)
            table.insert(tableData, {
                {text = "═══ " .. expName .. " ═══", color = expColor},
                {text = "", color = "000000"},
                {text = "", color = "000000"},
                {text = "", color = "000000"},
            })
        end

        -- Insert raid section header when transitioning from dungeons to raids
        -- sortOrder 4 = raid_normal, 5 = raid_heroic
        if not inRaidSection and entry.sortOrder >= 4 then
            inRaidSection = true
            local expColor = expansionColors[currentExpansion] or "FFFFFF"
            local raidSectionName = raidSectionNames[currentExpansion] or "RAIDS"

            -- Raid section header row
            table.insert(tableData, {
                {text = "─── " .. raidSectionName .. " ───", color = expColor},
                {text = "", color = "000000"},
                {text = "", color = "000000"},
                {text = "", color = "000000"},
            })
        end

        -- Regular data row
        table.insert(tableData, {
            {text = entry.displayName, color = entry.nameColor},
            {text = entry.difficulty, color = entry.nameColor},
            {text = tostring(entry.maxLevel), color = "FFFFFF"},
            entry.speedDisplay,
        })
    end

    -- Set the data
    dataTable:SetData(tableData)
end

-- ============================================================================
-- Slash Command Handler
-- ============================================================================

function Info:HandleCommand(...)
    local args = {...}
    local cmd = args[1] and string.lower(args[1]) or nil

    -- No argument - list available outputs
    if not cmd or cmd == "" then
        self:ListOutputs()
        return
    end

    -- Check if it's a registered output
    local output = self.outputs[cmd]
    if output then
        if output.handler then
            output.handler(self, unpack(args, 2))
        end
        return
    end

    -- Unknown command
    KOL:PrintTag("Unknown data output: |cFFFF8888" .. cmd .. "|r")
    KOL:Print("Use |cFF88CCFF/kdo|r to see available outputs")
end

function Info:ListOutputs()
    KOL:PrintTag("|cFF88CCFFData Output System|r")
    KOL:Print("Usage: |cFF88CCFF/kdo <output>|r")
    KOL:Print("")
    KOL:Print("Available outputs:")

    -- Sort outputs by name
    local sortedNames = {}
    for name, _ in pairs(self.outputs) do
        table.insert(sortedNames, name)
    end
    table.sort(sortedNames)

    for _, name in ipairs(sortedNames) do
        local output = self.outputs[name]
        KOL:Print("  |cFFFFFF00" .. output.name .. "|r - " .. output.description)
    end
end

-- ============================================================================
-- Initialization
-- ============================================================================

function Info:Initialize()
    if self.initialized then return end
    self.initialized = true

    -- Register the standalone /kdo command
    self:RegisterChatCommand("kdo", function(input)
        local args = {}
        for word in string.gmatch(input or "", "[^%s]+") do
            table.insert(args, word)
        end
        Info:HandleCommand(unpack(args))
    end)

    -- Register DungeonChallenge output
    self:RegisterOutput("DungeonChallenge", {
        description = "Classic dungeon challenge progress with speed stacks",
        handler = function(self)
            self:ShowDungeonChallenge()
        end,
    })

    KOL:DebugPrint("Info: Module initialized", 2)
end

-- Helper to register chat commands using Ace3
function Info:RegisterChatCommand(cmd, func)
    if KOL.RegisterChatCommand then
        KOL:RegisterChatCommand(cmd, func)
    else
        -- Fallback to global slash command
        local cmdUpper = string.upper(cmd)
        _G["SLASH_KOL" .. cmdUpper .. "1"] = "/" .. cmd
        SlashCmdList["KOL" .. cmdUpper] = func
    end
end

-- ============================================================================
-- Initialization Hook
-- ============================================================================

KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
    Info:Initialize()
end, "Info")
