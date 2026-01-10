-- ============================================================================
-- !Koality-of-Life: Progress Tracker Data - TBC Raids
-- ============================================================================
-- The Burning Crusade raid data (10-player and 25-player)
-- ============================================================================

local KOL = KoalityOfLife

-- ============================================================================
-- TBC Raids
-- ============================================================================

-- Karazhan (10-player)
KOL.Tracker:RegisterInstance("kara_10n", {
    name = "Karazhan (10-Player)",
    type = "raid",
    expansion = "tbc",
    difficulty = 1,
    color = "PURPLE",
    zones = {"Karazhan"},
    groups = {
        {
            name = "Servant's Quarters",
            bosses = {
                {name = "Attumen the Huntsman", type = "yell", id = 16152, yell = "Always knew... someday I would become... the hunted."},
                {name = "Moroes", id = 15687},
                {name = "Maiden of Virtue", id = 16457},
            }
        },
        {
            name = "Opera Hall",
            bosses = {
                {name = "Opera Event", id = {17521, 18168, 17533, 17534}, anyNPC = true},  -- BBW, Crone, Romulo, Julianne
            }
        },
        {
            name = "The Menagerie",
            bosses = {
                {name = "The Curator", id = 15691},
                {name = "Shade of Aran", id = 16524},
                {name = "Terestian Illhoof", id = 15688},
                {name = "Netherspite", id = 15689},
            }
        },
        {
            name = "Medivh's Tower",
            bosses = {
                {name = "Chess Event", id = {21684, 21752}, anyNPC = true},  -- King Llane, Warchief Blackhand
                {name = "Prince Malchezaar", id = 15690},
                {name = "Nightbane", id = 17225},
            }
        },
    }
})

-- Gruul's Lair (25-player)
KOL.Tracker:RegisterInstance("gruul_25n", {
    name = "Gruul's Lair (25-Player)",
    type = "raid",
    expansion = "tbc",
    difficulty = 2,
    color = "RED",
    zones = {"Gruul's Lair"},
    bosses = {
        {name = "High King Maulgar", id = 18831},
        {name = "Gruul the Dragonkiller", id = 19044},
    }
})

-- Magtheridon's Lair (25-player)
KOL.Tracker:RegisterInstance("mag_25n", {
    name = "Magtheridon's Lair (25-Player)",
    type = "raid",
    expansion = "tbc",
    difficulty = 2,
    color = "RED",
    zones = {"Magtheridon's Lair"},
    bosses = {
        {name = "Magtheridon", id = 17257},
    }
})

-- Serpentshrine Cavern (25-player)
KOL.Tracker:RegisterInstance("ssc_25n", {
    name = "Serpentshrine Cavern (25-Player)",
    type = "raid",
    expansion = "tbc",
    difficulty = 2,
    color = "BLUE",
    zones = {"Serpentshrine Cavern"},
    groups = {
        {
            name = "The Serpent's Lair",
            bosses = {
                {name = "Hydross the Unstable", id = 21216},
                {name = "The Lurker Below", id = 21217},
            }
        },
        {
            name = "Naga Stronghold",
            bosses = {
                {name = "Leotheras the Blind", id = 21215},
                {name = "Fathom-Lord Karathress", id = 21214},
                {name = "Morogrim Tidewalker", id = 21213},
            }
        },
        {
            name = "Lady Vashj's Lair",
            bosses = {
                {name = "Lady Vashj", id = 21212},
            }
        },
    }
})

-- Tempest Keep: The Eye (25-player)
KOL.Tracker:RegisterInstance("tk_25n", {
    name = "Tempest Keep (25-Player)",
    type = "raid",
    expansion = "tbc",
    difficulty = 2,
    color = "PURPLE",
    zones = {"Tempest Keep"},
    groups = {
        {
            name = "The Eye",
            bosses = {
                {name = "Al'ar", id = 19514},
                {name = "Void Reaver", id = 19516},
                {name = "High Astromancer Solarian", id = 18805},
            }
        },
        {
            name = "Kael's Chamber",
            bosses = {
                {name = "Kael'thas Sunstrider", id = 19622},
            }
        },
    }
})

-- Battle for Mount Hyjal (25-player)
KOL.Tracker:RegisterInstance("hyjal_25n", {
    name = "Battle for Mount Hyjal (25-Player)",
    type = "raid",
    expansion = "tbc",
    difficulty = 2,
    color = "GREEN",
    zones = {"Hyjal Summit"},
    groups = {
        {
            name = "Alliance Base",
            bosses = {
                {name = "Rage Winterchill", id = 17767},
                {name = "Anetheron", id = 17808},
            }
        },
        {
            name = "Horde Base",
            bosses = {
                {name = "Kaz'rogal", id = 17888},
                {name = "Azgalor", id = 17842},
            }
        },
        {
            name = "World Tree",
            bosses = {
                {name = "Archimonde", id = 17968},
            }
        },
    }
})

-- Black Temple (25-player)
KOL.Tracker:RegisterInstance("bt_25n", {
    name = "Black Temple (25-Player)",
    type = "raid",
    expansion = "tbc",
    difficulty = 2,
    color = "RED",
    zones = {"Black Temple"},
    groups = {
        {
            name = "Karabor Sewers",
            bosses = {
                {name = "High Warlord Naj'entus", id = 22887},
                {name = "Supremus", id = 22898},
            }
        },
        {
            name = "Sanctuary of Shadows",
            bosses = {
                {name = "Shade of Akama", id = 22841},
                {name = "Teron Gorefiend", id = 22871},
                {name = "Gurtogg Bloodboil", id = 22948},
            }
        },
        {
            name = "Den of Mortal Delights",
            bosses = {
                {name = "Reliquary of Souls", id = 22856},
                {name = "Mother Shahraz", id = 22947},
            }
        },
        {
            name = "Temple Summit",
            bosses = {
                {name = "The Illidari Council", id = 23426},
                {name = "Illidan Stormrage", id = 22917},
            }
        },
    }
})

-- Zul'Aman (10-player)
KOL.Tracker:RegisterInstance("za_10n", {
    name = "Zul'Aman (10-Player)",
    type = "raid",
    expansion = "tbc",
    difficulty = 1,
    color = "YELLOW",
    zones = {"Zul'Aman"},
    groups = {
        {
            name = "Amani Warlords",
            bosses = {
                {name = "Nalorakk", id = 23576},
                {name = "Akil'zon", id = 23574},
                {name = "Jan'alai", id = 23578},
                {name = "Halazzi", id = 23577},
            }
        },
        {
            name = "Zul'jin's Throne",
            bosses = {
                {name = "Hex Lord Malacrass", id = 24239},
                {name = "Zul'jin", id = 23863},
            }
        },
    }
})

-- Sunwell Plateau (25-player)
KOL.Tracker:RegisterInstance("swp_25n", {
    name = "Sunwell Plateau (25-Player)",
    type = "raid",
    expansion = "tbc",
    difficulty = 2,
    color = "ORANGE",
    zones = {"The Sunwell", "Sunwell Plateau"},
    groups = {
        {
            name = "Outer Sanctum",
            bosses = {
                {name = "Kalecgos", id = 24892},  -- Sathrovarr the Corruptor (demon form dies)
                {name = "Brutallus", id = 24882},
                {name = "Felmyst", id = 25038},
            }
        },
        {
            name = "Inner Sanctum",
            bosses = {
                {name = "The Eredar Twins", id = {25165, 25166}},  -- Lady Sacrolash, Grand Warlock Alythess
                {name = "M'uru", id = 25840},  -- Entropius (phase 2 form dies)
                {name = "Kil'jaeden", id = 25315},
            }
        },
    }
})
