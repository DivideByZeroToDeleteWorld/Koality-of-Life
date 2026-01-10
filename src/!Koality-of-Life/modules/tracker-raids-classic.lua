-- ============================================================================
-- !Koality-of-Life: Progress Tracker Data - Classic Raids
-- ============================================================================
-- Classic raid data (40-player and 20-player legacy content)
-- ============================================================================

local KOL = KoalityOfLife

-- ============================================================================
-- Classic Raids (Legacy Content in WotLK)
-- ============================================================================

-- Molten Core (40-player)
KOL.Tracker:RegisterInstance("mc_40", {
    name = "Molten Core (40-Player)",
    type = "raid",
    expansion = "classic",
    difficulty = 1,
    color = "ORANGE",
    zones = {"Molten Core"},
    challengeMaxLevel = 60,
    groups = {
        {
            name = "The Molten Span",
            bosses = {
                {name = "Lucifron", id = 12118},
                {name = "Magmadar", id = 11982},
                {name = "Gehennas", id = 12259},
            }
        },
        {
            name = "The Molten Bridge",
            bosses = {
                {name = "Garr", id = 12057},
                {name = "Shazzrah", id = 12264},
                {name = "Baron Geddon", id = 12056},
            }
        },
        {
            name = "Ragnaros' Lair",
            bosses = {
                {name = "Sulfuron Harbinger", id = 12098},
                {name = "Golemagg the Incinerator", id = 11988},
                {name = "Majordomo Executus", id = 12018},
                {name = "Ragnaros", id = 11502},
            }
        },
    }
})

-- Blackwing Lair (40-player)
KOL.Tracker:RegisterInstance("bwl_40", {
    name = "Blackwing Lair (40-Player)",
    type = "raid",
    expansion = "classic",
    difficulty = 1,
    color = "RED",
    zones = {"Blackwing Lair"},
    challengeMaxLevel = 60,
    groups = {
        {
            name = "The Dragonmaw",
            bosses = {
                {name = "Razorgore the Untamed", id = 12435},
                {name = "Vaelastrasz the Corrupt", id = 13020},
                {name = "Broodlord Lashlayer", id = 12017},
            }
        },
        {
            name = "Halls of Strife",
            bosses = {
                {name = "Firemaw", id = 11983},
                {name = "Ebonroc", id = 14601},
                {name = "Flamegor", id = 11981},
            }
        },
        {
            name = "Nefarian's Lair",
            bosses = {
                {name = "Chromaggus", id = 14020},
                {name = "Nefarian", id = 11583},
            }
        },
    }
})

-- Zul'Gurub (20-player)
KOL.Tracker:RegisterInstance("zg_20", {
    name = "Zul'Gurub (20-Player)",
    type = "raid",
    expansion = "classic",
    difficulty = 1,
    color = "GREEN",
    zones = {"Zul'Gurub"},
    challengeMaxLevel = 60,
    groups = {
        {
            name = "High Priests",
            bosses = {
                {name = "High Priestess Jeklik", id = 14517},
                {name = "High Priest Venoxis", id = 14507},
                {name = "High Priestess Mar'li", id = 14510},
                {name = "High Priest Thekal", id = 14509},
                {name = "High Priestess Arlokk", id = 14515},
            }
        },
        {
            name = "Zul'Gurub Lords",
            bosses = {
                {name = "Bloodlord Mandokir", id = 11382},
                {name = "Jin'do the Hexxer", id = 11380},
            }
        },
        {
            name = "The Blood God",
            bosses = {
                {name = "Hakkar", id = 14834},
            }
        },
    }
})

-- Ruins of Ahn'Qiraj (20-player)
KOL.Tracker:RegisterInstance("aq20_20", {
    name = "Ruins of Ahn'Qiraj (20-Player)",
    type = "raid",
    expansion = "classic",
    difficulty = 1,
    color = "YELLOW",
    zones = {"Ruins of Ahn'Qiraj"},
    challengeMaxLevel = 60,
    groups = {
        {
            name = "Entrance Guardians",
            bosses = {
                {name = "Kurinnaxx", id = 15348},
                {name = "General Rajaxx", id = 15341},
            }
        },
        {
            name = "The Reservoir",
            bosses = {
                {name = "Moam", id = 15340},
                {name = "Buru the Gorger", id = 15370},
                {name = "Ayamiss the Hunter", id = 15369},
            }
        },
        {
            name = "Ossirian's Sanctum",
            bosses = {
                {name = "Ossirian the Unscarred", id = 15339},
            }
        },
    }
})

-- Temple of Ahn'Qiraj (40-player)
KOL.Tracker:RegisterInstance("aq40_40", {
    name = "Temple of Ahn'Qiraj (40-Player)",
    type = "raid",
    expansion = "classic",
    difficulty = 1,
    color = "PURPLE",
    zones = {"Temple of Ahn'Qiraj"},
    challengeMaxLevel = 60,
    groups = {
        {
            name = "The Hive",
            bosses = {
                {name = "The Prophet Skeram", id = 15263},
                {name = "Bug Trio", id = 15543},
                {name = "Battleguard Sartura", id = 15516},
                {name = "Fankriss the Unyielding", id = 15510},
            }
        },
        {
            name = "The Twin Sanctum",
            bosses = {
                {name = "Viscidus", id = 15299},
                {name = "Princess Huhuran", id = 15509},
                {name = "Twin Emperors", id = 15275},
            }
        },
        {
            name = "C'Thun's Chamber",
            bosses = {
                {name = "Ouro", id = 15517},
                {name = "C'Thun", id = 15727},
            }
        },
    }
})
