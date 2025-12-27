-- ============================================================================
-- !Koality-of-Life: Build Manager Data
-- ============================================================================
-- Class definitions, colors, abbreviations, and default builds
-- ============================================================================

local KOL = KoalityOfLife

KOL.BuildManagerData = {}

--------------------------------------------------------------------------------
-- Class Definitions
--------------------------------------------------------------------------------

-- Standard WoW classes with Synastria dual-class support
KOL.BuildManagerData.CLASSES = {
    -- Standard Classes (order matches class selection UI)
    { id = "WARRIOR",     name = "Warrior",       abbrev = "WAR", color = { r = 0.78, g = 0.61, b = 0.43 } },
    { id = "PALADIN",     name = "Paladin",       abbrev = "PAL", color = { r = 0.96, g = 0.55, b = 0.73 } },
    { id = "HUNTER",      name = "Hunter",        abbrev = "HUN", color = { r = 0.67, g = 0.83, b = 0.45 } },
    { id = "ROGUE",       name = "Rogue",         abbrev = "ROG", color = { r = 1.00, g = 0.96, b = 0.41 } },
    { id = "PRIEST",      name = "Priest",        abbrev = "PRI", color = { r = 1.00, g = 1.00, b = 1.00 } },
    { id = "DEATHKNIGHT", name = "Death Knight",  abbrev = "DK",  color = { r = 0.77, g = 0.12, b = 0.23 } },
    { id = "SHAMAN",      name = "Shaman",        abbrev = "SHA", color = { r = 0.00, g = 0.44, b = 0.87 } },
    { id = "MAGE",        name = "Mage",          abbrev = "MAG", color = { r = 0.41, g = 0.80, b = 0.94 } },
    { id = "WARLOCK",     name = "Warlock",       abbrev = "WLK", color = { r = 0.58, g = 0.51, b = 0.79 } },
    { id = "DRUID",       name = "Druid",         abbrev = "DRU", color = { r = 1.00, g = 0.49, b = 0.04 } },

    -- ===== SYNASTRIA DUAL-CLASS COMBINATIONS =====
    -- Warrior Combinations (9)
    { id = "CHAMPION",     name = "Champion",     abbrev = "CHA", color = { r = 0.87, g = 0.58, b = 0.58 }, class1 = "WARRIOR", class2 = "PALADIN" },
    { id = "SOLDIER",      name = "Soldier",      abbrev = "SOL", color = { r = 0.73, g = 0.72, b = 0.44 }, class1 = "WARRIOR", class2 = "HUNTER" },
    { id = "BLADEMASTER",  name = "Blademaster",  abbrev = "BLA", color = { r = 0.89, g = 0.79, b = 0.42 }, class1 = "WARRIOR", class2 = "ROGUE" },
    { id = "CRUSADER",     name = "Crusader",     abbrev = "CRU", color = { r = 0.89, g = 0.81, b = 0.72 }, class1 = "WARRIOR", class2 = "PRIEST" },
    { id = "BUTCHER",      name = "Butcher",      abbrev = "BUT", color = { r = 0.78, g = 0.37, b = 0.33 }, class1 = "WARRIOR", class2 = "DEATHKNIGHT" },
    { id = "RAVAGER",      name = "Ravager",      abbrev = "RAV", color = { r = 0.39, g = 0.53, b = 0.65 }, class1 = "WARRIOR", class2 = "SHAMAN" },
    { id = "BATTLEMAGE",   name = "Battlemage",   abbrev = "BAT", color = { r = 0.60, g = 0.71, b = 0.69 }, class1 = "WARRIOR", class2 = "MAGE" },
    { id = "VANQUISHER",   name = "Vanquisher",   abbrev = "VAN", color = { r = 0.68, g = 0.56, b = 0.61 }, class1 = "WARRIOR", class2 = "WARLOCK" },
    { id = "BARBARIAN",    name = "Barbarian",    abbrev = "BAR", color = { r = 0.89, g = 0.55, b = 0.24 }, class1 = "WARRIOR", class2 = "DRUID" },

    -- Paladin Combinations (8)
    { id = "AVENGER",      name = "Avenger",      abbrev = "AVE", color = { r = 0.82, g = 0.69, b = 0.59 }, class1 = "PALADIN", class2 = "HUNTER" },
    { id = "AGENT",        name = "Agent",        abbrev = "AGE", color = { r = 0.98, g = 0.76, b = 0.57 }, class1 = "PALADIN", class2 = "ROGUE" },
    { id = "MARTYR",       name = "Martyr",       abbrev = "MAR", color = { r = 0.98, g = 0.78, b = 0.87 }, class1 = "PALADIN", class2 = "PRIEST" },
    { id = "ENFORCER",     name = "Enforcer",     abbrev = "ENF", color = { r = 0.87, g = 0.34, b = 0.48 }, class1 = "PALADIN", class2 = "DEATHKNIGHT" },
    { id = "SENTINEL",     name = "Sentinel",     abbrev = "SEN", color = { r = 0.48, g = 0.50, b = 0.80 }, class1 = "PALADIN", class2 = "SHAMAN" },
    { id = "INQUISITOR",   name = "Inquisitor",   abbrev = "INQ", color = { r = 0.69, g = 0.68, b = 0.84 }, class1 = "PALADIN", class2 = "MAGE" },
    { id = "WARDEN",       name = "Warden",       abbrev = "WAD", color = { r = 0.77, g = 0.53, b = 0.76 }, class1 = "PALADIN", class2 = "WARLOCK" },
    { id = "GUARDIAN",     name = "Guardian",     abbrev = "GUA", color = { r = 0.98, g = 0.52, b = 0.39 }, class1 = "PALADIN", class2 = "DRUID" },

    -- Hunter Combinations (7)
    { id = "SCOUT",        name = "Scout",        abbrev = "SCO", color = { r = 0.84, g = 0.90, b = 0.43 }, class1 = "HUNTER", class2 = "ROGUE" },
    { id = "SEER",         name = "Seer",         abbrev = "SEE", color = { r = 0.84, g = 0.92, b = 0.73 }, class1 = "HUNTER", class2 = "PRIEST" },
    { id = "SLAYER",       name = "Slayer",       abbrev = "SLA", color = { r = 0.72, g = 0.48, b = 0.34 }, class1 = "HUNTER", class2 = "DEATHKNIGHT" },
    { id = "TEMPEST",      name = "Tempest",      abbrev = "TEM", color = { r = 0.34, g = 0.64, b = 0.66 }, class1 = "HUNTER", class2 = "SHAMAN" },
    { id = "ARCANIST",     name = "Arcanist",     abbrev = "ARC", color = { r = 0.54, g = 0.82, b = 0.70 }, class1 = "HUNTER", class2 = "MAGE" },
    { id = "TRICKSTER",    name = "Trickster",    abbrev = "TRI", color = { r = 0.63, g = 0.67, b = 0.62 }, class1 = "HUNTER", class2 = "WARLOCK" },
    { id = "RANGER",       name = "Ranger",       abbrev = "RAN", color = { r = 0.84, g = 0.66, b = 0.25 }, class1 = "HUNTER", class2 = "DRUID" },

    -- Rogue Combinations (6)
    { id = "HERALD",       name = "Herald",       abbrev = "HER", color = { r = 1.00, g = 0.98, b = 0.71 }, class1 = "ROGUE", class2 = "PRIEST" },
    { id = "ASSASSIN",     name = "Assassin",     abbrev = "ASS", color = { r = 0.89, g = 0.54, b = 0.32 }, class1 = "ROGUE", class2 = "DEATHKNIGHT" },
    { id = "NINJA",        name = "Ninja",        abbrev = "NIN", color = { r = 0.50, g = 0.70, b = 0.64 }, class1 = "ROGUE", class2 = "SHAMAN" },
    { id = "SPELLBLADE",   name = "Spellblade",   abbrev = "SPE", color = { r = 0.71, g = 0.88, b = 0.68 }, class1 = "ROGUE", class2 = "MAGE" },
    { id = "VOIDSTALKER",  name = "Voidstalker",  abbrev = "VOI", color = { r = 0.79, g = 0.74, b = 0.60 }, class1 = "ROGUE", class2 = "WARLOCK" },
    { id = "SPY",          name = "Spy",          abbrev = "SPY", color = { r = 1.00, g = 0.73, b = 0.23 }, class1 = "ROGUE", class2 = "DRUID" },

    -- Priest Combinations (5)
    { id = "WRAITH",       name = "Wraith",       abbrev = "WRA", color = { r = 0.89, g = 0.56, b = 0.62 }, class1 = "PRIEST", class2 = "DEATHKNIGHT" },
    { id = "ORACLE",       name = "Oracle",       abbrev = "ORA", color = { r = 0.50, g = 0.72, b = 0.94 }, class1 = "PRIEST", class2 = "SHAMAN" },
    { id = "MYSTIC",       name = "Mystic",       abbrev = "MYS", color = { r = 0.71, g = 0.90, b = 0.97 }, class1 = "PRIEST", class2 = "MAGE" },
    { id = "SIREN",        name = "Siren",        abbrev = "SIR", color = { r = 0.79, g = 0.76, b = 0.90 }, class1 = "PRIEST", class2 = "WARLOCK" },
    { id = "EMPATH",       name = "Empath",       abbrev = "EMP", color = { r = 1.00, g = 0.75, b = 0.52 }, class1 = "PRIEST", class2 = "DRUID" },

    -- Death Knight Combinations (4)
    { id = "SUMMONER",     name = "Summoner",     abbrev = "SUM", color = { r = 0.39, g = 0.28, b = 0.55 }, class1 = "DEATHKNIGHT", class2 = "SHAMAN" },
    { id = "LICH",         name = "Lich",         abbrev = "LIC", color = { r = 0.59, g = 0.46, b = 0.59 }, class1 = "DEATHKNIGHT", class2 = "MAGE" },
    { id = "NECROMANCER",  name = "Necromancer",  abbrev = "NEC", color = { r = 0.68, g = 0.32, b = 0.51 }, class1 = "DEATHKNIGHT", class2 = "WARLOCK" },
    { id = "DREADWEAVER",  name = "Dreadweaver",  abbrev = "DRE", color = { r = 0.89, g = 0.31, b = 0.14 }, class1 = "DEATHKNIGHT", class2 = "DRUID" },

    -- Shaman Combinations (3)
    { id = "ELEMENTALIST", name = "Elementalist", abbrev = "ELE", color = { r = 0.21, g = 0.62, b = 0.91 }, class1 = "SHAMAN", class2 = "MAGE" },
    { id = "HARBINGER",    name = "Harbinger",    abbrev = "HAR", color = { r = 0.29, g = 0.48, b = 0.83 }, class1 = "SHAMAN", class2 = "WARLOCK" },
    { id = "SAGE",         name = "Sage",         abbrev = "SAG", color = { r = 0.50, g = 0.47, b = 0.46 }, class1 = "SHAMAN", class2 = "DRUID" },

    -- Mage Combinations (2)
    { id = "SORCERER",     name = "Sorcerer",     abbrev = "SOR", color = { r = 0.50, g = 0.66, b = 0.87 }, class1 = "MAGE", class2 = "WARLOCK" },
    { id = "CONJURER",     name = "Conjurer",     abbrev = "CON", color = { r = 0.71, g = 0.65, b = 0.49 }, class1 = "MAGE", class2 = "DRUID" },

    -- Warlock Combinations (1)
    { id = "WITCH",        name = "Witch",        abbrev = "WIT", color = { r = 0.79, g = 0.50, b = 0.42 }, class1 = "WARLOCK", class2 = "DRUID" },
}

-- Build lookup tables for quick access
KOL.BuildManagerData.CLASS_BY_ID = {}
KOL.BuildManagerData.CLASS_BY_ABBREV = {}

for _, classInfo in ipairs(KOL.BuildManagerData.CLASSES) do
    KOL.BuildManagerData.CLASS_BY_ID[classInfo.id] = classInfo
    KOL.BuildManagerData.CLASS_BY_ABBREV[classInfo.abbrev] = classInfo
end

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

-- Get class info by ID
function KOL.BuildManagerData:GetClassById(classId)
    return self.CLASS_BY_ID[classId]
end

-- Get class info by abbreviation
function KOL.BuildManagerData:GetClassByAbbrev(abbrev)
    return self.CLASS_BY_ABBREV[abbrev]
end

-- Get color string for class (returns hex color code)
function KOL.BuildManagerData:GetClassColorHex(classId)
    local classInfo = self.CLASS_BY_ID[classId]
    if classInfo then
        local r = math.floor(classInfo.color.r * 255)
        local g = math.floor(classInfo.color.g * 255)
        local b = math.floor(classInfo.color.b * 255)
        return string.format("%02X%02X%02X", r, g, b)
    end
    return "FFFFFF" -- Default white
end

-- Get colored class abbreviation for display
function KOL.BuildManagerData:GetColoredAbbrev(classId)
    local classInfo = self.CLASS_BY_ID[classId]
    if classInfo then
        local colorHex = self:GetClassColorHex(classId)
        return string.format("|cFF%s[%s]|r", colorHex, classInfo.abbrev)
    end
    return "[???]"
end

-- Get standard classes only (no dual-class)
function KOL.BuildManagerData:GetStandardClasses()
    local standard = {}
    for i = 1, 10 do -- First 10 are standard classes
        table.insert(standard, self.CLASSES[i])
    end
    return standard
end

-- Get all classes including dual-class
function KOL.BuildManagerData:GetAllClasses()
    return self.CLASSES
end

--------------------------------------------------------------------------------
-- Default Builds
-- Users create their own builds - starting with empty list
-- Type "D" = Default (built-in), Type "C" = Custom (user-created)
--------------------------------------------------------------------------------

KOL.BuildManagerData.DEFAULT_BUILDS = {
    -- No default builds - users create their own
}

--------------------------------------------------------------------------------
-- Perk Categories
-- Used for expanding all categories during perk reading
--------------------------------------------------------------------------------

KOL.BuildManagerData.PERK_CATEGORIES = {
    "Off",  -- Offensive
    "Def",  -- Defensive
    "Sup",  -- Support
    "Uti",  -- Utility
    "Cla",  -- Class A
    "Clb",  -- Class B
    "Mis",  -- Miscellaneous
}

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

-- Perk ID boundary marker (stop reading perks after this ID)
KOL.BuildManagerData.PERK_BOUNDARY_ID = 1042

-- Queue delays (in seconds)
KOL.BuildManagerData.QUEUE_DELAY_CLICK = 0.1
KOL.BuildManagerData.QUEUE_DELAY_TOGGLE = 0.15

-- Image paths for Build Manager button
KOL.BuildManagerData.BUTTON_IMAGE_NORMAL = "Interface\\AddOns\\!Koality-of-Life\\media\\images\\BM_1"
KOL.BuildManagerData.BUTTON_IMAGE_HOVER = "Interface\\AddOns\\!Koality-of-Life\\media\\images\\BM_2"
KOL.BuildManagerData.BUTTON_IMAGE_PRESSED = "Interface\\AddOns\\!Koality-of-Life\\media\\images\\BM_3"
