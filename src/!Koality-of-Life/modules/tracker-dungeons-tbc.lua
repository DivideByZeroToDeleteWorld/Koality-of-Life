-- ============================================================================
-- !Koality-of-Life: Progress Tracker Data - TBC Dungeons
-- ============================================================================
-- The Burning Crusade dungeon data (Normal and Heroic)
-- ============================================================================

local KOL = KoalityOfLife

-- ============================================================================
-- TBC Dungeons
-- ============================================================================

-- Hellfire Ramparts
KOL.Tracker:RegisterInstance("hr_n", {
    name = "Hellfire Ramparts (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "ORANGE",
    zones = {"Hellfire Ramparts"},
    bosses = {
        {name = "Watchkeeper Gargolmar", id = 17306},
        {name = "Omor the Unscarred", id = 17308},
        {name = "Vazruden & Nazan", id = 17307},
    }
})

KOL.Tracker:RegisterInstance("hr_h", {
    name = "Hellfire Ramparts (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "RED",
    zones = {"Hellfire Ramparts"},
    bosses = {
        {name = "Watchkeeper Gargolmar", id = 17306},
        {name = "Omor the Unscarred", id = 17308},
        {name = "Vazruden & Nazan", id = 17307},
    }
})

-- The Blood Furnace
KOL.Tracker:RegisterInstance("bf_n", {
    name = "The Blood Furnace (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "RED",
    zones = {"The Blood Furnace"},
    bosses = {
        {name = "The Maker", id = 17381},
        {name = "Broggok", id = 17380},
        {name = "Keli'dan the Breaker", id = 17377},
    }
})

KOL.Tracker:RegisterInstance("bf_h", {
    name = "The Blood Furnace (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "ROSE",
    zones = {"The Blood Furnace"},
    bosses = {
        {name = "The Maker", id = 17381},
        {name = "Broggok", id = 17380},
        {name = "Keli'dan the Breaker", id = 17377},
    }
})

-- The Slave Pens
KOL.Tracker:RegisterInstance("sp_n", {
    name = "The Slave Pens (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "BLUE",
    zones = {"The Slave Pens"},
    bosses = {
        {name = "Mennu the Betrayer", id = 17941},
        {name = "Rokmar the Crackler", id = 17991},
        {name = "Quagmirran", id = 17942},
    }
})

KOL.Tracker:RegisterInstance("sp_h", {
    name = "The Slave Pens (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "SKY",
    zones = {"The Slave Pens"},
    bosses = {
        {name = "Mennu the Betrayer", id = 17941},
        {name = "Rokmar the Crackler", id = 17991},
        {name = "Quagmirran", id = 17942},
    }
})

-- The Underbog
KOL.Tracker:RegisterInstance("ub_n", {
    name = "The Underbog (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "GREEN",
    zones = {"The Underbog"},
    bosses = {
        {name = "Hungarfen", id = 17770},
        {name = "Ghaz'an", id = 18105},
        {name = "Swamplord Musel'ek", id = 17826},
        {name = "The Black Stalker", id = 17882},
    }
})

KOL.Tracker:RegisterInstance("ub_h", {
    name = "The Underbog (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "MINT",
    zones = {"The Underbog"},
    bosses = {
        {name = "Hungarfen", id = 17770},
        {name = "Ghaz'an", id = 18105},
        {name = "Swamplord Musel'ek", id = 17826},
        {name = "The Black Stalker", id = 17882},
    }
})

-- Mana-Tombs
KOL.Tracker:RegisterInstance("mt_n", {
    name = "Mana-Tombs (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "PURPLE",
    zones = {"Mana-Tombs"},
    bosses = {
        {name = "Pandemonius", id = 18341},
        {name = "Tavarok", id = 18343},
        {name = "Nexus-Prince Shaffar", id = 18344},
        {name = "Yor", id = 22930},
    }
})

KOL.Tracker:RegisterInstance("mt_h", {
    name = "Mana-Tombs (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "LAVENDER",
    zones = {"Mana-Tombs"},
    bosses = {
        {name = "Pandemonius", id = 18341},
        {name = "Tavarok", id = 18343},
        {name = "Nexus-Prince Shaffar", id = 18344},
        {name = "Yor", id = 22930},
    }
})

-- Auchenai Crypts
KOL.Tracker:RegisterInstance("ac_n", {
    name = "Auchenai Crypts (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "PURPLE",
    zones = {"Auchenai Crypts"},
    bosses = {
        {name = "Shirrak the Dead Watcher", id = 18371},
        {name = "Exarch Maladaar", id = 18373},
    }
})

KOL.Tracker:RegisterInstance("ac_h", {
    name = "Auchenai Crypts (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "LAVENDER",
    zones = {"Auchenai Crypts"},
    bosses = {
        {name = "Shirrak the Dead Watcher", id = 18371},
        {name = "Exarch Maladaar", id = 18373},
    }
})

-- Sethekk Halls
KOL.Tracker:RegisterInstance("sh_n", {
    name = "Sethekk Halls (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "BLUE",
    zones = {"Sethekk Halls"},
    bosses = {
        {name = "Darkweaver Syth", id = 18472},
        {name = "Anzu", id = 23035},
        {name = "Talon King Ikiss", id = 18473},
    }
})

KOL.Tracker:RegisterInstance("sh_h", {
    name = "Sethekk Halls (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "SKY",
    zones = {"Sethekk Halls"},
    bosses = {
        {name = "Darkweaver Syth", id = 18472},
        {name = "Anzu", id = 23035},
        {name = "Talon King Ikiss", id = 18473},
    }
})

-- Shadow Labyrinth
KOL.Tracker:RegisterInstance("sl_n", {
    name = "Shadow Labyrinth (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "PURPLE",
    zones = {"Shadow Labyrinth"},
    bosses = {
        {name = "Ambassador Hellmaw", id = 18731},
        {name = "Blackheart the Inciter", id = 18667},
        {name = "Grandmaster Vorpil", id = 18732},
        {name = "Murmur", id = 18708},
    }
})

KOL.Tracker:RegisterInstance("sl_h", {
    name = "Shadow Labyrinth (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "LAVENDER",
    zones = {"Shadow Labyrinth"},
    bosses = {
        {name = "Ambassador Hellmaw", id = 18731},
        {name = "Blackheart the Inciter", id = 18667},
        {name = "Grandmaster Vorpil", id = 18732},
        {name = "Murmur", id = 18708},
    }
})

-- The Shattered Halls
KOL.Tracker:RegisterInstance("shh_n", {
    name = "The Shattered Halls (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "RED",
    zones = {"The Shattered Halls"},
    bosses = {
        {name = "Grand Warlock Nethekurse", id = 16807},
        {name = "Blood Guard Porung", id = 20923},
        {name = "Warbringer O'mrogg", id = 16809},
        {name = "Warchief Kargath Bladefist", id = 16808},
    }
})

KOL.Tracker:RegisterInstance("shh_h", {
    name = "The Shattered Halls (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "ROSE",
    zones = {"The Shattered Halls"},
    bosses = {
        {name = "Grand Warlock Nethekurse", id = 16807},
        {name = "Blood Guard Porung", id = 20923},
        {name = "Warbringer O'mrogg", id = 16809},
        {name = "Warchief Kargath Bladefist", id = 16808},
    }
})

-- The Steamvault
KOL.Tracker:RegisterInstance("sv_n", {
    name = "The Steamvault (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "BLUE",
    zones = {"The Steamvault"},
    bosses = {
        {name = "Hydromancer Thespia", id = 17797},
        {name = "Mekgineer Steamrigger", id = 17796},
        {name = "Warlord Kalithresh", id = 17798},
    }
})

KOL.Tracker:RegisterInstance("sv_h", {
    name = "The Steamvault (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "AQUA",
    zones = {"The Steamvault"},
    bosses = {
        {name = "Hydromancer Thespia", id = 17797},
        {name = "Mekgineer Steamrigger", id = 17796},
        {name = "Warlord Kalithresh", id = 17798},
    }
})

-- The Botanica
KOL.Tracker:RegisterInstance("bot_n", {
    name = "The Botanica (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "GREEN",
    zones = {"The Botanica"},
    bosses = {
        {name = "Commander Sarannis", id = 17976},
        {name = "High Botanist Freywinn", id = 17975},
        {name = "Thorngrin the Tender", id = 17978},
        {name = "Laj", id = 17980},
        {name = "Warp Splinter", id = 17977},
    }
})

KOL.Tracker:RegisterInstance("bot_h", {
    name = "The Botanica (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "LIME",
    zones = {"The Botanica"},
    bosses = {
        {name = "Commander Sarannis", id = 17976},
        {name = "High Botanist Freywinn", id = 17975},
        {name = "Thorngrin the Tender", id = 17978},
        {name = "Laj", id = 17980},
        {name = "Warp Splinter", id = 17977},
    }
})

-- The Mechanar
KOL.Tracker:RegisterInstance("mech_n", {
    name = "The Mechanar (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "PURPLE",
    zones = {"The Mechanar"},
    bosses = {
        {name = "Gatewatcher Gyro-Kill", id = 19218},
        {name = "Gatewatcher Iron-Hand", id = 19710},
        {name = "Mechano-Lord Capacitus", id = 19219},
        {name = "Nethermancer Sepethrea", id = 19221},
        {name = "Pathaleon the Calculator", id = 19220},
    }
})

KOL.Tracker:RegisterInstance("mech_h", {
    name = "The Mechanar (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "LAVENDER",
    zones = {"The Mechanar"},
    bosses = {
        {name = "Gatewatcher Gyro-Kill", id = 19218},
        {name = "Gatewatcher Iron-Hand", id = 19710},
        {name = "Mechano-Lord Capacitus", id = 19219},
        {name = "Nethermancer Sepethrea", id = 19221},
        {name = "Pathaleon the Calculator", id = 19220},
    }
})

-- The Arcatraz
KOL.Tracker:RegisterInstance("arc_n", {
    name = "The Arcatraz (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "PURPLE",
    zones = {"The Arcatraz"},
    bosses = {
        {name = "Zereketh the Unbound", id = 20870},
        {name = "Dalliah the Doomsayer", id = 20885},
        {name = "Wrath-Scryer Soccothrates", id = 20886},
        {name = "Harbinger Skyriss", id = 20912},
    }
})

KOL.Tracker:RegisterInstance("arc_h", {
    name = "The Arcatraz (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "LAVENDER",
    zones = {"The Arcatraz"},
    bosses = {
        {name = "Zereketh the Unbound", id = 20870},
        {name = "Dalliah the Doomsayer", id = 20885},
        {name = "Wrath-Scryer Soccothrates", id = 20886},
        {name = "Harbinger Skyriss", id = 20912},
    }
})

-- Old Hillsbrad Foothills (Caverns of Time)
KOL.Tracker:RegisterInstance("ohf_n", {
    name = "Old Hillsbrad Foothills (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "YELLOW",
    zones = {"Old Hillsbrad Foothills"},
    bosses = {
        {name = "Lieutenant Drake", id = 17848},
        {name = "Captain Skarloc", id = 17862},
        {name = "Epoch Hunter", id = 18096},
    }
})

KOL.Tracker:RegisterInstance("ohf_h", {
    name = "Old Hillsbrad Foothills (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "PEACH",
    zones = {"Old Hillsbrad Foothills"},
    bosses = {
        {name = "Lieutenant Drake", id = 17848},
        {name = "Captain Skarloc", id = 17862},
        {name = "Epoch Hunter", id = 18096},
    }
})

-- The Black Morass (Caverns of Time)
KOL.Tracker:RegisterInstance("bm_n", {
    name = "The Black Morass (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "PURPLE",
    zones = {"The Black Morass"},
    bosses = {
        {name = "Chrono Lord Deja", id = 17879},
        {name = "Temporus", id = 17880},
        {name = "Aeonus", id = 17881},
    }
})

KOL.Tracker:RegisterInstance("bm_h", {
    name = "The Black Morass (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "LAVENDER",
    zones = {"The Black Morass"},
    bosses = {
        {name = "Chrono Lord Deja", id = 17879},
        {name = "Temporus", id = 17880},
        {name = "Aeonus", id = 17881},
    }
})

-- Magisters' Terrace
KOL.Tracker:RegisterInstance("mgt_n", {
    name = "Magisters' Terrace (Normal)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 1,
    color = "RED",
    zones = {"Magisters' Terrace"},
    bosses = {
        {name = "Selin Fireheart", id = 24723},
        {name = "Vexallus", id = 24744},
        {name = "Priestess Delrissa", id = 24560},
        {name = "Kael'thas Sunstrider", id = 24664},
    }
})

KOL.Tracker:RegisterInstance("mgt_h", {
    name = "Magisters' Terrace (Heroic)",
    type = "dungeon",
    expansion = "tbc",
    difficulty = 2,
    color = "ROSE",
    zones = {"Magisters' Terrace"},
    bosses = {
        {name = "Selin Fireheart", id = 24723},
        {name = "Vexallus", id = 24744},
        {name = "Priestess Delrissa", id = 24560},
        {name = "Kael'thas Sunstrider", id = 24664},
    }
})
