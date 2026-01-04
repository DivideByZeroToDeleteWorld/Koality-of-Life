-- ============================================================================
-- !Koality-of-Life: Progress Tracker Data
-- ============================================================================
-- Pre-defined dungeon and raid data for Classic, TBC, and WotLK
-- ============================================================================

local KOL = KoalityOfLife

-- This file registers all dungeons and raids when loaded
-- NPC IDs may need verification - placeholders use 99999

-- ============================================================================
-- Classic Dungeons (Available in WotLK for Leveling)
-- ============================================================================

-- Ragefire Chasm
KOL.Tracker:RegisterInstance("rfc_n", {
    name = "Ragefire Chasm",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "ORANGE",
    zones = {"Ragefire Chasm"},
    challengeMaxLevel = 15,
    bosses = {
        {name = "Oggleflint", id = 11517},
        {name = "Taragaman the Hungerer", id = 11520},
        {name = "Jergosh the Invoker", id = 11518},
        {name = "Bazzalan", id = 11519},
    }
})

-- Wailing Caverns
KOL.Tracker:RegisterInstance("wc_n", {
    name = "Wailing Caverns",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "GREEN",
    zones = {"Wailing Caverns"},
    challengeMaxLevel = 19,
    groups = {
        {
            name = "Lords of the Fang",
            bosses = {
                {name = "Lady Anacondra", id = 3671},
                {name = "Lord Cobrahn", id = 3669},
                {name = "Lord Pythas", id = 3670},
                {name = "Lord Serpentis", id = 3673},
            }
        },
        {
            name = "The Winding Chasm",
            bosses = {
                {name = "Skum", id = 3674},
                {name = "Verdan the Everliving", id = 5775},
            }
        },
        {
            name = "The Dreamer's Rock",
            bosses = {
                {name = "Mutanus the Devourer", id = 3654},
            }
        },
    }
})

-- Deadmines
KOL.Tracker:RegisterInstance("dm_n", {
    name = "The Deadmines",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "YELLOW",
    zones = {"The Deadmines"},
    challengeMaxLevel = 19,
    bosses = {
        {name = "Rhahk'Zor", id = 644},
        {name = "Miner Johnson", id = 3586},
        {name = "Sneed", id = 643},
        {name = "Gilnid", id = 1763},
        {name = "Mr. Smite", id = 646},
        {name = "Captain Greenskin", id = 647},
        {name = "Edwin VanCleef", id = 639},
        {name = "Cookie", id = 645},
    }
})

-- Shadowfang Keep
KOL.Tracker:RegisterInstance("sfk_n", {
    name = "Shadowfang Keep",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "PURPLE",
    zones = {"Shadowfang Keep"},
    challengeMaxLevel = 20,
    bosses = {
        {name = "Rethilgore", id = 3914},
        {name = "Razorclaw the Butcher", id = 3886},
        {name = "Baron Silverlaine", id = 3887},
        {name = "Commander Springvale", id = 4278},
        {name = "Odo the Blindwatcher", id = 4279},
        {name = "Fenrus the Devourer", id = 4274},
        {name = "Wolf Master Nandos", id = 3927},
        {name = "Archmage Arugal", id = 4275},
    }
})

-- Blackfathom Deeps
KOL.Tracker:RegisterInstance("bfd_n", {
    name = "Blackfathom Deeps",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "BLUE",
    zones = {"Blackfathom Deeps"},
    challengeMaxLevel = 23,
    bosses = {
        {name = "Ghamoo-ra", id = 4887},
        {name = "Lady Sarevess", id = 4831},
        {name = "Gelihast", id = 6243},
        {name = "Lorgus Jett", id = 12902},
        {name = "Baron Aquanis", id = 12876},
        {name = "Twilight Lord Kelris", id = 4832},
        {name = "Old Serra'kis", id = 4830},
        {name = "Aku'mai", id = 4829},
    }
})

-- Stockades
KOL.Tracker:RegisterInstance("stocks_n", {
    name = "The Stockade",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "GRAY",
    zones = {"The Stockade"},
    challengeMaxLevel = 24,
    bosses = {
        {name = "Targorr the Dread", id = 1696},
        {name = "Kam Deepfury", id = 1666},
        {name = "Hamhock", id = 1717},
        {name = "Bazil Thredd", id = 1716},
        {name = "Dextren Ward", id = 1663},
        {name = "Bruegal Ironknuckle", id = 1720},
    }
})

-- Gnomeregan
KOL.Tracker:RegisterInstance("gnomer_n", {
    name = "Gnomeregan",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "PINK",
    zones = {"Gnomeregan"},
    challengeMaxLevel = 27,
    bosses = {
        {name = "Grubbis", id = 7361},
        {name = "Viscous Fallout", id = 7079},
        {name = "Electrocutioner 6000", id = 6235},
        {name = "Crowd Pummeler 9-60", id = 6229},
        {name = "Mekgineer Thermaplugg", id = 7800},
    }
})

-- Razorfen Kraul
KOL.Tracker:RegisterInstance("rfk_n", {
    name = "Razorfen Kraul",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "LIME",
    zones = {"Razorfen Kraul"},
    challengeMaxLevel = 26,
    bosses = {
        {name = "Roogug", id = 6168},
        {name = "Aggem Thorncurse", id = 4424},
        {name = "Death Speaker Jargba", id = 4428},
        {name = "Overlord Ramtusk", id = 4420},
        {name = "Agathelos the Raging", id = 4422},
        {name = "Charlga Razorflank", id = 4421},
    }
})

-- Scarlet Monastery (all wings)
KOL.Tracker:RegisterInstance("sm_gy_n", {
    name = "Scarlet Monastery: Graveyard",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "RED",
    zones = {"Scarlet Monastery"},
    challengeMaxLevel = 39,
    bosses = {
        {name = "Interrogator Vishas", id = 3983},
        {name = "Bloodmage Thalnos", id = 4543},
        {name = "Ironspine", id = 14516},
        {name = "Azshir the Sleepless", id = 6490},
        {name = "Fallen Champion", id = 6488},
    }
})

KOL.Tracker:RegisterInstance("sm_lib_n", {
    name = "Scarlet Monastery: Library",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "ROSE",
    zones = {"Scarlet Monastery"},
    challengeMaxLevel = 39,
    bosses = {
        {name = "Houndmaster Loksey", id = 3974},
        {name = "Arcanist Doan", id = 6487},
    }
})

KOL.Tracker:RegisterInstance("sm_arm_n", {
    name = "Scarlet Monastery: Armory",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "ORANGE",
    zones = {"Scarlet Monastery"},
    challengeMaxLevel = 39,
    bosses = {
        {name = "Herod", id = 3975},
    }
})

KOL.Tracker:RegisterInstance("sm_cath_n", {
    name = "Scarlet Monastery: Cathedral",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "CORAL",
    zones = {"Scarlet Monastery"},
    challengeMaxLevel = 39,
    bosses = {
        {name = "High Inquisitor Fairbanks", id = 4542},
        {name = "Scarlet Commander Mograine", id = 3976},
        {name = "High Inquisitor Whitemane", id = 3977},
    }
})

-- Razorfen Downs
KOL.Tracker:RegisterInstance("rfd_n", {
    name = "Razorfen Downs",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "MINT",
    zones = {"Razorfen Downs"},
    challengeMaxLevel = 36,
    bosses = {
        {name = "Tuten'kash", id = 7355},
        {name = "Mordresh Fire Eye", id = 7357},
        {name = "Glutton", id = 8567},
        {name = "Ragglesnout", id = 7356},
        {name = "Amnennar the Coldbringer", id = 7358},
    }
})

-- Uldaman
KOL.Tracker:RegisterInstance("uld_n", {
    name = "Uldaman",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "PEACH",
    zones = {"Uldaman"},
    challengeMaxLevel = 39,
    bosses = {
        {name = "Revelosh", id = 6910},
        {name = "The Lost Dwarves", id = 6906},
        {name = "Ironaya", id = 7228},
        {name = "Obsidian Sentinel", id = 7023},
        {name = "Ancient Stone Keeper", id = 7206},
        {name = "Galgann Firehammer", id = 7291},
        {name = "Grimlok", id = 4854},
        {name = "Archaedas", id = 2748},
    }
})

-- Zul'Farrak
KOL.Tracker:RegisterInstance("zf_n", {
    name = "Zul'Farrak",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "YELLOW",
    zones = {"Zul'Farrak"},
    challengeMaxLevel = 44,
    bosses = {
        {name = "Gahz'rilla", id = 7273},
        {name = "Antu'sul", id = 8127},
        {name = "Theka the Martyr", id = 7272},
        {name = "Witch Doctor Zum'rah", id = 7271},
        {name = "Nekrum Gutchewer", id = 7796},
        {name = "Shadowpriest Sezz'ziz", id = 7275},
        {name = "Chief Ukorz Sandscalp", id = 7267},
    }
})

-- Maraudon
KOL.Tracker:RegisterInstance("mara_n", {
    name = "Maraudon",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "PURPLE",
    zones = {"Maraudon"},
    challengeMaxLevel = 47,
    groups = {
        {
            name = "The Wicked Grotto (Orange)",
            bosses = {
                {name = "Noxxion", id = 13282},
                {name = "Razorlash", id = 12258},
            }
        },
        {
            name = "Foulspore Cavern (Purple)",
            bosses = {
                {name = "Lord Vyletongue", id = 12236},
                {name = "Celebras the Cursed", id = 12225},
            }
        },
        {
            name = "Earth Song Falls",
            bosses = {
                {name = "Landslide", id = 12203},
                {name = "Tinkerer Gizlock", id = 13601},
                {name = "Rotgrip", id = 13596},
                {name = "Princess Theradras", id = 12201},
            }
        },
    }
})

-- Sunken Temple
KOL.Tracker:RegisterInstance("st_n", {
    name = "The Temple of Atal'Hakkar",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "GREEN",
    zones = {"The Temple of Atal'Hakkar"},
    challengeMaxLevel = 49,
    bosses = {
        {name = "Avatar of Hakkar", id = 8443},
        {name = "Jammal'an the Prophet", id = 5710},
        {name = "Wardens of the Dream", id = 5721},
        {name = "Shade of Eranikus", id = 5709},
    }
})

-- Blackrock Depths
KOL.Tracker:RegisterInstance("brd_n", {
    name = "Blackrock Depths",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "ORANGE",
    zones = {"Blackrock Depths"},
    challengeMaxLevel = 55,
    groups = {
        {
            name = "Detention Block",
            bosses = {
                {name = "High Interrogator Gerstahn", id = 9018},
            }
        },
        {
            name = "Shadowforge Prison",
            bosses = {
                {name = "Lord Roccor", id = 9025},
                {name = "Houndmaster Grebmar", id = 9319},
            }
        },
        {
            name = "Ring of Law",
            bosses = {
                {name = "Ring of Law", id = 9027},
            }
        },
        {
            name = "Shadowforge City",
            bosses = {
                {name = "Pyromancer Loregrain", id = 9024},
                {name = "Lord Incendius", id = 9017},
                {name = "Fineous Darkvire", id = 9056},
                {name = "Bael'Gar", id = 9016},
            }
        },
        {
            name = "The Manufactory",
            bosses = {
                {name = "General Angerforge", id = 9033},
                {name = "Golem Lord Argelmach", id = 8983},
            }
        },
        {
            name = "Grim Guzzler",
            bosses = {
                {name = "Hurley Blackbreath", id = 9537},
                {name = "Phalanx", id = 9502},
                {name = "Plugger Spazzring", id = 9499},
            }
        },
        {
            name = "Imperial Seat",
            bosses = {
                {name = "Ambassador Flamelash", id = 9156},
                {name = "The Seven", id = 9041},
                {name = "Magmus", id = 9938},
                {name = "Emperor Dagran Thaurissan", id = 9019},
            }
        },
    }
})

-- Lower Blackrock Spire
KOL.Tracker:RegisterInstance("lbrs_n", {
    name = "Lower Blackrock Spire",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "RED",
    zones = {"Blackrock Spire"},
    challengeMaxLevel = 60,
    groups = {
        {
            name = "Hordemar City",
            bosses = {
                {name = "Highlord Omokk", id = 9196},
            }
        },
        {
            name = "Troll Stronghold",
            bosses = {
                {name = "Shadow Hunter Vosh'gajin", id = 9236},
                {name = "War Master Voone", id = 9237},
            }
        },
        {
            name = "Skitterweb Tunnels",
            bosses = {
                {name = "Mother Smolderweb", id = 10596},
                {name = "Urok Doomhowl", id = 10584},
                {name = "Quartermaster Zigris", id = 9736},
            }
        },
        {
            name = "Halycon's Lair",
            bosses = {
                {name = "Halycon", id = 10220},
                {name = "Gizrul the Slavener", id = 10268},
            }
        },
        {
            name = "Wyrmthalak's Chamber",
            bosses = {
                {name = "Overlord Wyrmthalak", id = 9568},
            }
        },
    }
})

-- Upper Blackrock Spire
KOL.Tracker:RegisterInstance("ubrs_n", {
    name = "Upper Blackrock Spire",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "ROSE",
    zones = {"Blackrock Spire"},
    challengeMaxLevel = 60,
    groups = {
        {
            name = "The Rookery",
            bosses = {
                {name = "Pyroguard Emberseer", id = 9816},
                {name = "Solakar Flamewreath", id = 10264},
            }
        },
        {
            name = "Hall of Blackhand",
            bosses = {
                {name = "Jed Runewatcher", id = 10509},
                {name = "Goraluk Anvilcrack", id = 10899},
            }
        },
        {
            name = "Rend's Arena",
            bosses = {
                {name = "Warchief Rend Blackhand", id = 10429},
                {name = "Gyth", id = 10339},
            }
        },
        {
            name = "The Beast's Lair",
            bosses = {
                {name = "The Beast", id = 10430},
                {name = "General Drakkisath", id = 10363},
            }
        },
    }
})

-- Dire Maul (all wings)
KOL.Tracker:RegisterInstance("dm_east_n", {
    name = "Dire Maul: East",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "LAVENDER",
    zones = {"Dire Maul"},
    challengeMaxLevel = 60,
    bosses = {
        {name = "Pusillin", id = 14354},
        {name = "Zevrim Thornhoof", id = 11490},
        {name = "Hydrospawn", id = 13280},
        {name = "Lethtendris", id = 14327},
        {name = "Alzzin the Wildshaper", id = 11492},
    }
})

KOL.Tracker:RegisterInstance("dm_west_n", {
    name = "Dire Maul: West",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "SKY",
    zones = {"Dire Maul"},
    challengeMaxLevel = 60,
    bosses = {
        {name = "Tendris Warpwood", id = 11489},
        {name = "Illyanna Ravenoak", id = 11488},
        {name = "Magister Kalendris", id = 11487},
        {name = "Immol'thar", id = 11496},
        {name = "Prince Tortheldrin", id = 11486},
    }
})

KOL.Tracker:RegisterInstance("dm_north_n", {
    name = "Dire Maul: North",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "AQUA",
    zones = {"Dire Maul"},
    challengeMaxLevel = 60,
    bosses = {
        {name = "Guard Mol'dar", id = 14326},
        {name = "Stomper Kreeg", id = 14322},
        {name = "Guard Fengus", id = 14321},
        {name = "Guard Slip'kik", id = 14323},
        {name = "Captain Kromcrush", id = 14325},
        {name = "Cho'Rush the Observer", id = 14324},
        {name = "King Gordok", id = 11501},
    }
})

-- Scholomance
KOL.Tracker:RegisterInstance("scholo_n", {
    name = "Scholomance",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "PURPLE",
    zones = {"Scholomance"},
    challengeMaxLevel = 60,
    groups = {
        {
            name = "The Reliquary",
            bosses = {
                {name = "Blood Steward of Kirtonos", id = 14861},
                {name = "Kirtonos the Herald", id = 10506},
            }
        },
        {
            name = "The Viewing Room",
            bosses = {
                {name = "Jandice Barov", id = 10503},
                {name = "Rattlegore", id = 11622},
            }
        },
        {
            name = "The Great Ossuary",
            bosses = {
                {name = "Death Knight Darkreaver", id = 14516},
                {name = "Marduk Blackpool", id = 10433},
                {name = "Vectus", id = 10432},
            }
        },
        {
            name = "Ras Frostwhisper's Study",
            bosses = {
                {name = "Ras Frostwhisper", id = 10508},
            }
        },
        {
            name = "Barov Family Vault",
            bosses = {
                {name = "Instructor Malicia", id = 10505},
                {name = "Doctor Theolen Krastinov", id = 11261},
                {name = "Lorekeeper Polkelt", id = 10901},
                {name = "The Ravenian", id = 10507},
                {name = "Lord Alexei Barov", id = 10504},
                {name = "Lady Illucia Barov", id = 10502},
            }
        },
        {
            name = "Headmaster's Study",
            bosses = {
                {name = "Darkmaster Gandling", id = 1853},
            }
        },
    }
})

-- Stratholme
KOL.Tracker:RegisterInstance("strat_live_n", {
    name = "Stratholme: Live Side",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "YELLOW",
    zones = {"Stratholme"},
    challengeMaxLevel = 60,
    groups = {
        {
            name = "King's Square",
            bosses = {
                {name = "The Unforgiven", id = 10516},
                {name = "Timmy the Cruel", id = 10808},
            }
        },
        {
            name = "Scarlet Bastion",
            bosses = {
                {name = "Cannon Master Willey", id = 10997},
                {name = "Archivist Galford", id = 10811},
                {name = "Balnazzar", id = 10813},
                {name = "Aurius", id = 10917},
            }
        },
    }
})

KOL.Tracker:RegisterInstance("strat_dead_n", {
    name = "Stratholme: Undead Side",
    type = "dungeon",
    expansion = "classic",
    difficulty = 1,
    color = "LIME",
    zones = {"Stratholme"},
    challengeMaxLevel = 60,
    groups = {
        {
            name = "Festival Lane",
            bosses = {
                {name = "Hearthsinger Forresten", id = 10558},
                {name = "Postmaster Malown", id = 11143},
            }
        },
        {
            name = "The Gauntlet",
            bosses = {
                {name = "Baroness Anastari", id = 10436},
                {name = "Nerub'enkan", id = 10437},
                {name = "Maleki the Pallid", id = 10438},
            }
        },
        {
            name = "Slaughter Square",
            bosses = {
                {name = "Magistrate Barthilas", id = 10435},
                {name = "Ramstein the Gorger", id = 10439},
                {name = "Baron Rivendare", id = 10440},
            }
        },
    }
})

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

-- ============================================================================
-- WotLK Raids
-- ============================================================================

-- Naxxramas (10-player)
KOL.Tracker:RegisterInstance("naxx_10", {
    name = "Naxxramas (10-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 1,
    color = "SKY",
    zones = {"Naxxramas"},
    frameWidth = 230,   -- Wider to fit long boss names like "Grand Widow Faerlina"
    frameHeight = 292,  -- Perfect height to fit all 5 groups without scrolling
    groups = {
        {
            name = "Arachnid Quarter",
            bosses = {
                {name = "Anub'Rekhan", id = 15956},
                {name = "Grand Widow Faerlina", id = 15953},
                {name = "Maexxna", id = 15952},
            }
        },
        {
            name = "Plague Quarter",
            bosses = {
                {name = "Noth the Plaguebringer", id = 15954},
                {name = "Heigan the Unclean", id = 15936},
                {name = "Loatheb", id = 16011},
            }
        },
        {
            name = "Military Quarter",
            bosses = {
                {name = "Instructor Razuvious", id = 16061},
                {name = "Gothik the Harvester", id = 16060},
                {
                    name = "The Four Horsemen",
                    type = "multikill",
                    id = {16063, 30549, 16064, 16065},  -- Sir Zeliek, Baron (Synastria), Thane, Lady
                    multiKill = {"Sir Zeliek", "Baron Rivendare", "Thane Korth'azz", "Lady Blaumeux"}
                },
            }
        },
        {
            name = "Construct Quarter",
            bosses = {
                {name = "Patchwerk", id = 16028},
                {name = "Grobbulus", id = 15931},
                {name = "Gluth", id = 15932},
                {name = "Thaddius", id = 15928},
            }
        },
        {
            name = "Frostwyrm Lair",
            bosses = {
                {name = "Sapphiron", id = 15989},
                {name = "Kel'Thuzad", id = 15990},
            }
        },
    }
})

-- Naxxramas (25-player)
KOL.Tracker:RegisterInstance("naxx_25", {
    name = "Naxxramas (25-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 2,
    color = "SKY",
    zones = {"Naxxramas"},
    frameWidth = 230,   -- Wider to fit long boss names like "Grand Widow Faerlina"
    frameHeight = 292,  -- Perfect height to fit all 5 groups without scrolling
    groups = {
        {
            name = "Arachnid Quarter",
            bosses = {
                {name = "Anub'Rekhan", id = 15956},
                {name = "Grand Widow Faerlina", id = 15953},
                {name = "Maexxna", id = 15952},
            }
        },
        {
            name = "Plague Quarter",
            bosses = {
                {name = "Noth the Plaguebringer", id = 15954},
                {name = "Heigan the Unclean", id = 15936},
                {name = "Loatheb", id = 16011},
            }
        },
        {
            name = "Military Quarter",
            bosses = {
                {name = "Instructor Razuvious", id = 16061},
                {name = "Gothik the Harvester", id = 16060},
                {
                    name = "The Four Horsemen",
                    type = "multikill",
                    id = {16063, 30549, 16064, 16065},  -- Sir Zeliek, Baron (Synastria), Thane, Lady
                    multiKill = {"Sir Zeliek", "Baron Rivendare", "Thane Korth'azz", "Lady Blaumeux"}
                },
            }
        },
        {
            name = "Construct Quarter",
            bosses = {
                {name = "Patchwerk", id = 16028},
                {name = "Grobbulus", id = 15931},
                {name = "Gluth", id = 15932},
                {name = "Thaddius", id = 15928},
            }
        },
        {
            name = "Frostwyrm Lair",
            bosses = {
                {name = "Sapphiron", id = 15989},
                {name = "Kel'Thuzad", id = 15990},
            }
        },
    }
})

-- Eye of Eternity (10-player)
KOL.Tracker:RegisterInstance("eoe_10", {
    name = "Eye of Eternity (10-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 1,
    color = "BLUE",
    zones = {"The Eye of Eternity"},
    bosses = {
        {name = "Malygos", id = 28859},
    }
})

-- Eye of Eternity (25-player)
KOL.Tracker:RegisterInstance("eoe_25", {
    name = "Eye of Eternity (25-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 2,
    color = "BLUE",
    zones = {"The Eye of Eternity"},
    bosses = {
        {name = "Malygos", id = 28859},
    }
})

-- Obsidian Sanctum (10-player)
KOL.Tracker:RegisterInstance("os_10", {
    name = "Obsidian Sanctum (10-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 1,
    color = "RED",
    zones = {"The Obsidian Sanctum"},
    groups = {
        {
            name = "Twilight Drakes",
            bosses = {
                {name = "Shadron", id = 30451},
                {name = "Tenebron", id = 30452},
                {name = "Vesperon", id = 30449},
            }
        },
        {
            name = "The Black Dragonflight",
            bosses = {
                {name = "Sartharion", id = 28860},
            }
        },
    }
})

-- Obsidian Sanctum (25-player)
KOL.Tracker:RegisterInstance("os_25", {
    name = "Obsidian Sanctum (25-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 2,
    color = "RED",
    zones = {"The Obsidian Sanctum"},
    groups = {
        {
            name = "Twilight Drakes",
            bosses = {
                {name = "Shadron", id = 30451},
                {name = "Tenebron", id = 30452},
                {name = "Vesperon", id = 30449},
            }
        },
        {
            name = "The Black Dragonflight",
            bosses = {
                {name = "Sartharion", id = 28860},
            }
        },
    }
})

-- Vault of Archavon (10-player)
KOL.Tracker:RegisterInstance("voa_10", {
    name = "Vault of Archavon (10-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 1,
    color = "PURPLE",
    zones = {"Vault of Archavon"},
    bosses = {
        {name = "Archavon the Stone Watcher", id = 31125},
        {name = "Emalon the Storm Watcher", id = 33993},
        {name = "Koralon the Flame Watcher", id = 35013},
        {name = "Toravon the Ice Watcher", id = 38433},
    }
})

-- Vault of Archavon (25-player)
KOL.Tracker:RegisterInstance("voa_25", {
    name = "Vault of Archavon (25-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 2,
    color = "PURPLE",
    zones = {"Vault of Archavon"},
    bosses = {
        {name = "Archavon the Stone Watcher", id = 31125},
        {name = "Emalon the Storm Watcher", id = 33993},
        {name = "Koralon the Flame Watcher", id = 35013},
        {name = "Toravon the Ice Watcher", id = 38433},
    }
})

-- Ulduar (10-player)
KOL.Tracker:RegisterInstance("uld_10", {
    name = "Ulduar (10-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 1,
    color = "CYAN",
    zones = {"Ulduar"},
    frameWidth = 210,
    frameHeight = 320,
    groups = {
        {
            name = "Siege of Ulduar",
            bosses = {
                {
                    name = "Flame Leviathan",
                    id = 33113,
                    hardmode = {
                        yells = {
                            "Systems overload in 5",
                            "Circuit overload",
                        }
                    }
                },
                {name = "Razorscale", id = 33186},
                {name = "Ignis the Furnace Master", id = 33118},
                {
                    name = "XT-002 Deconstructor",
                    id = 33293,
                    hardmode = {
                        yells = {
                            "heart is exposed",
                        }
                    }
                },
            }
        },
        {
            name = "Antechamber of Ulduar",
            bosses = {
                {
                    name = "Assembly of Iron",
                    type = "multikill",
                    id = {32867, 32927, 32857},  -- Steelbreaker, Runemaster Molgeim, Stormcaller Brundir
                    multiKill = {"Steelbreaker", "Runemaster Molgeim", "Stormcaller Brundir"},
                    hardmode = {
                        yells = {
                            "Molgeim, Brundir, your defiance ends here",
                        }
                    }
                },
                {name = "Kologarn", id = 32930},
                {name = "Auriaya", id = 33515},
            }
        },
        {
            name = "Keepers of Ulduar",
            bosses = {
                {
                    name = "Hodir",
                    type = "yell",
                    id = 32845,
                    yell = "I... I am released from his grasp... at last.",
                    hardmode = {
                        yells = {
                            "Hodir has been defeated",
                        }
                    }
                },
                {
                    name = "Thorim",
                    type = "yell",
                    id = 32865,
                    yell = "Stay your arms! I yield!",
                    hardmode = {
                        yells = {
                            "Sif, they",
                        }
                    }
                },
                {
                    name = "Freya",
                    type = "yell",
                    id = 32906,
                    yell = "His hold on me dissipates. I can see clearly once more. Thank you, heroes.",
                    hardmode = {
                        yells = {
                            "Nature's Fury is no match",
                        }
                    }
                },
                {
                    name = "Mimiron",
                    type = "yell",
                    id = 33350,
                    yell = "It would appear that I've made a slight miscalculation. I allowed my mind to be corrupted by the fiend in the prison, overriding my primary directive. All systems seem to be functional now. Clear.",
                    hardmode = {
                        interactions = {
                            {objectId = 194739},
                        }
                    }
                },
            }
        },
        {
            name = "Descent into Madness",
            bosses = {
                {
                    name = "General Vezax",
                    id = 33271,
                    hardmode = {
                        yells = {
                            "Behold the armies",
                        }
                    }
                },
                {
                    name = "Yogg-Saron",
                    id = 33288,
                    hardmode = {
                        yells = {
                            "Impossible!",
                        }
                    }
                },
            }
        },
        {
            name = "Celestial Planetarium",
            bosses = {
                {name = "Algalon the Observer", type = "yell", id = 32871, yell = "I have seen worlds bathed in the Makers' flames, their denizens fading without as much as a whimper. Entire planetary systems born and razed in the time that it takes your mortal hearts to beat once. Yet all throughout, my own heart devoid of emotion... of empathy. I. Have. Felt. Nothing. A million-million lives wasted. Had they all held within them your tenacity? Had they all loved life as you do?"},
            }
        },
    }
})

-- Ulduar (25-player)
KOL.Tracker:RegisterInstance("uld_25", {
    name = "Ulduar (25-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 2,
    color = "CYAN",
    zones = {"Ulduar"},
    frameWidth = 210,
    frameHeight = 320,
    groups = {
        {
            name = "Siege of Ulduar",
            bosses = {
                {
                    name = "Flame Leviathan",
                    id = 33113,
                    hardmode = {
                        yells = {
                            "Systems overload in 5",
                            "Circuit overload",
                        }
                    }
                },
                {name = "Razorscale", id = 33186},
                {name = "Ignis the Furnace Master", id = 33118},
                {
                    name = "XT-002 Deconstructor",
                    id = 33293,
                    hardmode = {
                        yells = {
                            "heart is exposed",
                        }
                    }
                },
            }
        },
        {
            name = "Antechamber of Ulduar",
            bosses = {
                {
                    name = "Assembly of Iron",
                    type = "multikill",
                    id = {32867, 32927, 32857},  -- Steelbreaker, Runemaster Molgeim, Stormcaller Brundir
                    multiKill = {"Steelbreaker", "Runemaster Molgeim", "Stormcaller Brundir"},
                    hardmode = {
                        yells = {
                            "Molgeim, Brundir, your defiance ends here",
                        }
                    }
                },
                {name = "Kologarn", id = 32930},
                {name = "Auriaya", id = 33515},
            }
        },
        {
            name = "Keepers of Ulduar",
            bosses = {
                {
                    name = "Hodir",
                    type = "yell",
                    id = 32845,
                    yell = "I... I am released from his grasp... at last.",
                    hardmode = {
                        yells = {
                            "Hodir has been defeated",
                        }
                    }
                },
                {
                    name = "Thorim",
                    type = "yell",
                    id = 32865,
                    yell = "Stay your arms! I yield!",
                    hardmode = {
                        yells = {
                            "Sif, they",
                        }
                    }
                },
                {
                    name = "Freya",
                    type = "yell",
                    id = 32906,
                    yell = "His hold on me dissipates. I can see clearly once more. Thank you, heroes.",
                    hardmode = {
                        yells = {
                            "Nature's Fury is no match",
                        }
                    }
                },
                {
                    name = "Mimiron",
                    type = "yell",
                    id = 33350,
                    yell = "It would appear that I've made a slight miscalculation. I allowed my mind to be corrupted by the fiend in the prison, overriding my primary directive. All systems seem to be functional now. Clear.",
                    hardmode = {
                        interactions = {
                            {objectId = 194739},
                        }
                    }
                },
            }
        },
        {
            name = "Descent into Madness",
            bosses = {
                {
                    name = "General Vezax",
                    id = 33271,
                    hardmode = {
                        yells = {
                            "Behold the armies",
                        }
                    }
                },
                {
                    name = "Yogg-Saron",
                    id = 33288,
                    hardmode = {
                        yells = {
                            "Impossible!",
                        }
                    }
                },
            }
        },
        {
            name = "Celestial Planetarium",
            bosses = {
                {name = "Algalon the Observer", type = "yell", id = 32871, yell = "I have seen worlds bathed in the Makers' flames, their denizens fading without as much as a whimper. Entire planetary systems born and razed in the time that it takes your mortal hearts to beat once. Yet all throughout, my own heart devoid of emotion... of empathy. I. Have. Felt. Nothing. A million-million lives wasted. Had they all held within them your tenacity? Had they all loved life as you do?"},
            }
        },
    }
})

-- Trial of the Crusader (10-player)
KOL.Tracker:RegisterInstance("toc_10", {
    name = "Trial of the Crusader (10-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 1,
    color = "YELLOW",
    zones = {"Trial of the Crusader"},
    bosses = {
        {
            name = "The Beasts of Northrend",
            id = 34797,
            hardmode = {
                yells = {
                    "The next beast is released!",
                    "The beast is slain!",
                }
            }
        },
        {
            name = "Lord Jaraxxus",
            id = 34780,
            hardmode = {
                yells = {
                    "TRIFLING GNOME!",
                    "Flesh from bone!",
                }
            }
        },
        {
            name = "Faction Champions",
            type = "yell",
            id = 34461,
            yell = "GLORY TO THE ALLIANCE!",  -- Alliance victory
            yells = {
                "GLORY TO THE ALLIANCE!",  -- Alliance victory
                "That was just a taste of what the future brings. FOR THE HORDE!",  -- Horde victory
            },
            hardmode = {
                yells = {
                    "A tragic day",
                }
            }
        },
        {
            name = "Twin Val'kyr",
            id = 34497,
            hardmode = {
                yells = {
                    "LIGHT GRANT ME STRENGTH",
                    "darkness overwhelm",
                }
            }
        },
        {
            name = "Anub'arak",
            id = 34564,
            hardmode = {
                yells = {
                    "This place will serve as your tomb",
                    "AHHH! The surface",
                }
            }
        },
    }
})

-- Trial of the Crusader (25-player)
KOL.Tracker:RegisterInstance("toc_25", {
    name = "Trial of the Crusader (25-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 2,
    color = "YELLOW",
    zones = {"Trial of the Crusader"},
    bosses = {
        {
            name = "The Beasts of Northrend",
            id = 34797,
            hardmode = {
                yells = {
                    "The next beast is released!",
                    "The beast is slain!",
                }
            }
        },
        {
            name = "Lord Jaraxxus",
            id = 34780,
            hardmode = {
                yells = {
                    "TRIFLING GNOME!",
                    "Flesh from bone!",
                }
            }
        },
        {
            name = "Faction Champions",
            type = "yell",
            id = 34461,
            yell = "GLORY TO THE ALLIANCE!",  -- Alliance victory
            yells = {
                "GLORY TO THE ALLIANCE!",  -- Alliance victory
                "That was just a taste of what the future brings. FOR THE HORDE!",  -- Horde victory
            },
            hardmode = {
                yells = {
                    "A tragic day",
                }
            }
        },
        {
            name = "Twin Val'kyr",
            id = 34497,
            hardmode = {
                yells = {
                    "LIGHT GRANT ME STRENGTH",
                    "darkness overwhelm",
                }
            }
        },
        {
            name = "Anub'arak",
            id = 34564,
            hardmode = {
                yells = {
                    "This place will serve as your tomb",
                    "AHHH! The surface",
                }
            }
        },
    }
})

-- Onyxia's Lair (10-player) - WotLK Revamp
KOL.Tracker:RegisterInstance("ony_10", {
    name = "Onyxia's Lair (10-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 1,
    color = "RED",
    zones = {"Onyxia's Lair"},
    bosses = {
        {name = "Onyxia", id = 10184},
    }
})

-- Onyxia's Lair (25-player) - WotLK Revamp
KOL.Tracker:RegisterInstance("ony_25", {
    name = "Onyxia's Lair (25-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 2,
    color = "RED",
    zones = {"Onyxia's Lair"},
    bosses = {
        {name = "Onyxia", id = 10184},
    }
})

-- Icecrown Citadel (10-player)
KOL.Tracker:RegisterInstance("icc_10", {
    name = "Icecrown Citadel (10-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 1,
    color = "SKY",
    zones = {"Icecrown Citadel"},
    groups = {
        {
            name = "The Lower Spire",
            bosses = {
                {
                    name = "Lord Marrowgar",
                    id = 36612,
                    hardmode = {
                        yells = {
                            "BONE STORM!",
                        }
                    }
                },
                {
                    name = "Lady Deathwhisper",
                    id = 36855,
                    hardmode = {
                        yells = {
                            "Fools, you have brought about your own demise!",
                        }
                    }
                },
                {
                    name = "Gunship Battle",
                    type = "yell",
                    id = {37540, 36939},  -- The Skybreaker (Horde target), High Overlord Saurfang (Alliance target)
                    anyNPC = true,
                    yell = "Don't say I didn't warn ya, scoundrels!",  -- Alliance victory (partial match)
                    yells = {
                        "Don't say I didn't warn ya, scoundrels!",  -- Alliance victory
                        "The Alliance falter. Onward to the Lich King!",  -- Horde victory
                    },
                    hardmode = {
                        yells = {
                            "Open fire!",
                            "Marines, defenders of the Alliance",
                        }
                    }
                },
                {
                    name = "Deathbringer Saurfang",
                    id = 37813,
                    hardmode = {
                        yells = {
                            "Feast on their blood!",
                            "Blood beasts, heed my call!",
                        }
                    }
                },
            }
        },
        {
            name = "The Plagueworks",
            bosses = {
                {
                    name = "Festergut",
                    id = 36626,
                    hardmode = {
                        yells = {
                            "Fun time!",
                            "New toys!",
                        }
                    }
                },
                {
                    name = "Rotface",
                    id = 36627,
                    hardmode = {
                        yells = {
                            "Daddy make toys out of you!",
                            "BAD! BAD! BAD!",
                        }
                    }
                },
                {
                    name = "Professor Putricide",
                    id = 36678,
                    hardmode = {
                        yells = {
                            "Good news, everyone!",
                            "Great news, everyone!",
                        }
                    }
                },
            }
        },
        {
            name = "The Crimson Hall",
            bosses = {
                {
                    name = "Blood Prince Council",
                    id = 37970,
                    hardmode = {
                        yells = {
                            "You have made a grave error",
                        }
                    }
                },
                {
                    name = "Blood-Queen Lana'thel",
                    id = 37955,
                    hardmode = {
                        yells = {
                            "You have made a grave mistake",
                            "The blood races in my veins!",
                        }
                    }
                },
            }
        },
        {
            name = "Frostwing Halls",
            bosses = {
                {
                    name = "Valithria Dreamwalker",
                    id = 36789,
                    hardmode = {
                        yells = {
                            "I am lost in a sea of dream",
                        }
                    }
                },
                {
                    name = "Sindragosa",
                    id = 36853,
                    hardmode = {
                        yells = {
                            "Suffer, mortals!",
                            "Icy death awaits!",
                        }
                    }
                },
            }
        },
        {
            name = "The Frozen Throne",
            bosses = {
                {
                    name = "The Lich King",
                    id = 36597,
                    hardmode = {
                        yells = {
                            "Frostmourne hungers!",
                            "I will freeze you from within",
                            "So the Light's vaunted justice has finally arrived",
                        }
                    }
                },
            }
        },
    }
})

-- Icecrown Citadel (25-player)
KOL.Tracker:RegisterInstance("icc_25", {
    name = "Icecrown Citadel (25-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 2,
    color = "SKY",
    zones = {"Icecrown Citadel"},
    groups = {
        {
            name = "The Lower Spire",
            bosses = {
                {
                    name = "Lord Marrowgar",
                    id = 36612,
                    hardmode = {
                        yells = {
                            "BONE STORM!",
                        }
                    }
                },
                {
                    name = "Lady Deathwhisper",
                    id = 36855,
                    hardmode = {
                        yells = {
                            "Fools, you have brought about your own demise!",
                        }
                    }
                },
                {
                    name = "Gunship Battle",
                    type = "yell",
                    id = {37540, 36939},  -- The Skybreaker (Horde target), High Overlord Saurfang (Alliance target)
                    anyNPC = true,
                    yell = "Don't say I didn't warn ya, scoundrels!",  -- Alliance victory (partial match)
                    yells = {
                        "Don't say I didn't warn ya, scoundrels!",  -- Alliance victory
                        "The Alliance falter. Onward to the Lich King!",  -- Horde victory
                    },
                    hardmode = {
                        yells = {
                            "Open fire!",
                            "Marines, defenders of the Alliance",
                        }
                    }
                },
                {
                    name = "Deathbringer Saurfang",
                    id = 37813,
                    hardmode = {
                        yells = {
                            "Feast on their blood!",
                            "Blood beasts, heed my call!",
                        }
                    }
                },
            }
        },
        {
            name = "The Plagueworks",
            bosses = {
                {
                    name = "Festergut",
                    id = 36626,
                    hardmode = {
                        yells = {
                            "Fun time!",
                            "New toys!",
                        }
                    }
                },
                {
                    name = "Rotface",
                    id = 36627,
                    hardmode = {
                        yells = {
                            "Daddy make toys out of you!",
                            "BAD! BAD! BAD!",
                        }
                    }
                },
                {
                    name = "Professor Putricide",
                    id = 36678,
                    hardmode = {
                        yells = {
                            "Good news, everyone!",
                            "Great news, everyone!",
                        }
                    }
                },
            }
        },
        {
            name = "The Crimson Hall",
            bosses = {
                {
                    name = "Blood Prince Council",
                    id = 37970,
                    hardmode = {
                        yells = {
                            "You have made a grave error",
                        }
                    }
                },
                {
                    name = "Blood-Queen Lana'thel",
                    id = 37955,
                    hardmode = {
                        yells = {
                            "You have made a grave mistake",
                            "The blood races in my veins!",
                        }
                    }
                },
            }
        },
        {
            name = "Frostwing Halls",
            bosses = {
                {
                    name = "Valithria Dreamwalker",
                    id = 36789,
                    hardmode = {
                        yells = {
                            "I am lost in a sea of dream",
                        }
                    }
                },
                {
                    name = "Sindragosa",
                    id = 36853,
                    hardmode = {
                        yells = {
                            "Suffer, mortals!",
                            "Icy death awaits!",
                        }
                    }
                },
            }
        },
        {
            name = "The Frozen Throne",
            bosses = {
                {
                    name = "The Lich King",
                    id = 36597,
                    hardmode = {
                        yells = {
                            "Frostmourne hungers!",
                            "I will freeze you from within",
                            "So the Light's vaunted justice has finally arrived",
                        }
                    }
                },
            }
        },
    }
})

-- Ruby Sanctum (10-player)
KOL.Tracker:RegisterInstance("rs_10", {
    name = "Ruby Sanctum (10-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 1,
    color = "RED",
    zones = {"The Ruby Sanctum"},
    bosses = {
        {name = "Halion", id = 39863},
    }
})

-- Ruby Sanctum (25-player)
KOL.Tracker:RegisterInstance("rs_25", {
    name = "Ruby Sanctum (25-Player)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 2,
    color = "RED",
    zones = {"The Ruby Sanctum"},
    bosses = {
        {name = "Halion", id = 39863},
    }
})

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
    zones = {"Sunwell Plateau"},
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
                {name = "The Eredar Twins", id = 25166},
                {name = "M'uru", id = 25840},  -- Entropius (phase 2 form dies)
                {name = "Kil'jaeden", id = 25315},
            }
        },
    }
})

KOL:DebugPrint("Tracker Data: Loaded all dungeons and raids", 1)

-- Populate tracker config UI after all instances are registered
if KOL.PopulateTrackerConfigUI then
    KOL:DebugPrint("Tracker Data: About to populate config UI with " .. tostring(KOL.Tracker and #KOL.Tracker.instances or 0) .. " instances", 1)
    KOL:PopulateTrackerConfigUI()

    -- Notify AceConfig to refresh
    if LibStub and LibStub("AceConfigRegistry-3.0") then
        LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
    end
end

-- ============================================================================
-- WotLK Dungeons
-- ============================================================================

-- Utgarde Keep
KOL.Tracker:RegisterInstance("uk_n", {
    name = "Utgarde Keep (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "BLUE",
    zones = {"Utgarde Keep"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Prince Keleseth", id = 23953},
        {name = "Skarvald & Dalronn", id = 24200},
        {name = "Ingvar the Plunderer", id = 23954},
    }
})

KOL.Tracker:RegisterInstance("uk_h", {
    name = "Utgarde Keep (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "CYAN",
    zones = {"Utgarde Keep"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Prince Keleseth", id = 23953},
        {name = "Skarvald & Dalronn", id = 24200},
        {name = "Ingvar the Plunderer", id = 23954},
    }
})

-- The Nexus
KOL.Tracker:RegisterInstance("nex_n", {
    name = "The Nexus (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "PURPLE",
    zones = {"The Nexus"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Commander Stoutbeard", id = 26796},
        {name = "Grand Magus Telestra", id = 26731},
        {name = "Anomalus", id = 26763},
        {name = "Ormorok the Tree-Shaper", id = 26794},
        {name = "Keristrasza", id = 26723},
    }
})

KOL.Tracker:RegisterInstance("nex_h", {
    name = "The Nexus (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "LAVENDER",
    zones = {"The Nexus"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Commander Stoutbeard", nameHorde = "Commander Kolurg", id = 26796, idHorde = 26798},
        {name = "Grand Magus Telestra", id = 26731},
        {name = "Anomalus", id = 26763},
        {name = "Ormorok the Tree-Shaper", id = 26794},
        {name = "Keristrasza", id = 26723},
    }
})

-- Azjol-Nerub
KOL.Tracker:RegisterInstance("an_n", {
    name = "Azjol-Nerub (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "GREEN",
    zones = {"Azjol-Nerub"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Krik'thir the Gatewatcher", id = 28684},
        {name = "Hadronox", id = 28921},
        {name = "Anub'arak", id = 29120},
    }
})

KOL.Tracker:RegisterInstance("an_h", {
    name = "Azjol-Nerub (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "MINT",
    zones = {"Azjol-Nerub"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Krik'thir the Gatewatcher", id = 28684},
        {name = "Hadronox", id = 28921},
        {name = "Anub'arak", id = 29120},
    }
})

-- Ahn'kahet: The Old Kingdom
KOL.Tracker:RegisterInstance("ok_n", {
    name = "Ahn'kahet: The Old Kingdom (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "PURPLE",
    zones = {"Ahn'kahet: The Old Kingdom"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Elder Nadox", id = 29309},
        {name = "Prince Taldaram", id = 29308},
        {name = "Jedoga Shadowseeker", id = 29310},
        {name = "Herald Volazj", id = 29311},
        {name = "Amanitar", id = 30258},
    }
})

KOL.Tracker:RegisterInstance("ok_h", {
    name = "Ahn'kahet: The Old Kingdom (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "LAVENDER",
    zones = {"Ahn'kahet: The Old Kingdom"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Elder Nadox", id = 29309},
        {name = "Prince Taldaram", id = 29308},
        {name = "Jedoga Shadowseeker", id = 29310},
        {name = "Herald Volazj", id = 29311},
        {name = "Amanitar", id = 30258},
    }
})

-- Drak'Tharon Keep
KOL.Tracker:RegisterInstance("dtk_n", {
    name = "Drak'Tharon Keep (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "RED",
    zones = {"Drak'Tharon Keep"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Trollgore", id = 26630},
        {name = "Novos the Summoner", id = 26631},
        {name = "King Dred", id = 27483},
        {name = "The Prophet Tharon'ja", id = 26632},
    }
})

KOL.Tracker:RegisterInstance("dtk_h", {
    name = "Drak'Tharon Keep (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "ROSE",
    zones = {"Drak'Tharon Keep"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Trollgore", id = 26630},
        {name = "Novos the Summoner", id = 26631},
        {name = "King Dred", id = 27483},
        {name = "The Prophet Tharon'ja", id = 26632},
    }
})

-- The Violet Hold
-- Special: 2 random bosses (unknown which) + Cyanigosa final boss
-- We track generic "Encounter 1" and "Encounter 2" that get marked complete via yells
KOL.Tracker:RegisterInstance("vh_n", {
    name = "The Violet Hold (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "PURPLE",
    zones = {"The Violet Hold"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Encounter 1", id = nil},  -- First random boss (marked via yell)
        {name = "Encounter 2", id = nil},  -- Second random boss (marked via yell)
        {name = "Cyanigosa", id = 31134},  -- Always final boss
    }
})

KOL.Tracker:RegisterInstance("vh_h", {
    name = "The Violet Hold (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "LAVENDER",
    zones = {"The Violet Hold"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Encounter 1", id = nil},  -- First random boss (marked via yell)
        {name = "Encounter 2", id = nil},  -- Second random boss (marked via yell)
        {name = "Cyanigosa", id = 31506},  -- Always final boss (heroic ID)
    }
})

-- Violet Hold Boss Pool (all possible bosses that can spawn)
-- These will be dynamically inserted when detected
-- successYell = the yell that indicates boss was successfully defeated
KOL.Tracker.VioletHoldBossPool = {
    -- Normal mode IDs
    [29315] = {name = "Erekem", difficulty = 1, successYell = "No--kaw, kaw--flee..."},
    [29316] = {name = "Moragg", difficulty = 1},
    [29313] = {name = "Ichoron", difficulty = 1, successYell = "I... recede."},
    [29266] = {name = "Xevozz", difficulty = 1, successYell = "This is an... unrecoverable... loss."},
    [29312] = {name = "Lavanthor", difficulty = 1},
    [29314] = {name = "Zuramat the Obliterator", difficulty = 1, successYell = "Disperse."},
    [31134] = {name = "Cyanigosa", difficulty = 1, successYell = "Perhaps... we have... underestimated... you."},
    -- Heroic mode IDs
    [32226] = {name = "Erekem", difficulty = 2, successYell = "No--kaw, kaw--flee..."},
    [32215] = {name = "Moragg", difficulty = 2},
    [32234] = {name = "Ichoron", difficulty = 2, successYell = "I... recede."},
    [32231] = {name = "Xevozz", difficulty = 2, successYell = "This is an... unrecoverable... loss."},
    [32218] = {name = "Lavanthor", difficulty = 2},
    [32230] = {name = "Zuramat the Obliterator", difficulty = 2, successYell = "Disperse."},
    [31506] = {name = "Cyanigosa", difficulty = 2, successYell = "Perhaps... we have... underestimated... you."},
}

-- Gundrak
KOL.Tracker:RegisterInstance("gd_n", {
    name = "Gundrak (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "GREEN",
    zones = {"Gundrak"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Slad'ran", id = 29304},
        {name = "Moorabi", id = 29305},
        {name = "Drakkari Colossus", id = 29307},
        {name = "Gal'darah", id = 29306},
        {name = "Eck the Ferocious", id = 29932},
    }
})

KOL.Tracker:RegisterInstance("gd_h", {
    name = "Gundrak (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "LIME",
    zones = {"Gundrak"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Slad'ran", id = 29304},
        {name = "Moorabi", id = 29305},
        {name = "Drakkari Colossus", id = 29307},
        {name = "Gal'darah", id = 29306},
        {name = "Eck the Ferocious", id = 29932},
    }
})

-- Halls of Stone
KOL.Tracker:RegisterInstance("hos_n", {
    name = "Halls of Stone (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "CYAN",
    zones = {"Halls of Stone"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Krystallus", id = 27977},
        {name = "Maiden of Grief", id = 27975},
        {name = "Tribunal of Ages", id = 28234},
        {name = "Sjonnir the Ironshaper", id = 27978},
    }
})

KOL.Tracker:RegisterInstance("hos_h", {
    name = "Halls of Stone (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "SKY",
    zones = {"Halls of Stone"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Krystallus", id = 27977},
        {name = "Maiden of Grief", id = 27975},
        {name = "Tribunal of Ages", id = 28234},
        {name = "Sjonnir the Ironshaper", id = 27978},
    }
})

-- Halls of Lightning
KOL.Tracker:RegisterInstance("hol_n", {
    name = "Halls of Lightning (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "YELLOW",
    zones = {"Halls of Lightning"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "General Bjarngrim", id = 28586},
        {name = "Volkhan", id = 28587},
        {name = "Ionar", id = 28546},
        {name = "Loken", id = 28923},
    }
})

KOL.Tracker:RegisterInstance("hol_h", {
    name = "Halls of Lightning (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "ORANGE",
    zones = {"Halls of Lightning"},
    challengeMaxLevel = 80,
    bosses = {
        {
            name = "General Bjarngrim",
            id = 28586,
            hardmode = {
                yells = {
                    "I will crush you!",
                }
            }
        },
        {
            name = "Volkhan",
            id = 28587,
            hardmode = {
                yells = {
                    "Untainted by flame!",
                }
            }
        },
        {
            name = "Ionar",
            id = 28546,
            hardmode = {
                yells = {
                    "You wish to confront the master?",
                }
            }
        },
        {
            name = "Loken",
            id = 28923,
            hardmode = {
                yells = {
                    "What little time you have left in this world will be spent in agony!",
                    "I have witnessed the rise and fall of empires",
                }
            }
        },
    }
})

-- The Oculus
KOL.Tracker:RegisterInstance("oc_n", {
    name = "The Oculus (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "BLUE",
    zones = {"The Oculus"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Drakos the Interrogator", id = 27654},
        {name = "Varos Cloudstrider", id = 27447},
        {name = "Mage-Lord Urom", id = 27655},
        {name = "Ley-Guardian Eregos", id = 27656},
    }
})

KOL.Tracker:RegisterInstance("oc_h", {
    name = "The Oculus (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "CYAN",
    zones = {"The Oculus"},
    challengeMaxLevel = 80,
    bosses = {
        {
            name = "Drakos the Interrogator",
            id = 27654,
            hardmode = {
                yells = {
                    "I will rip the secret of",
                }
            }
        },
        {
            name = "Varos Cloudstrider",
            id = 27447,
            hardmode = {
                yells = {
                    "Nothing takes to the air without my permission!",
                }
            }
        },
        {
            name = "Mage-Lord Urom",
            id = 27655,
            hardmode = {
                yells = {
                    "Astounding! Still alive?",
                }
            }
        },
        {
            name = "Ley-Guardian Eregos",
            id = 27656,
            hardmode = {
                yells = {
                    "You were warned!",
                    "The powers of magic must be unleashed!",
                }
            }
        },
    }
})

-- Utgarde Pinnacle
KOL.Tracker:RegisterInstance("up_n", {
    name = "Utgarde Pinnacle (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "BLUE",
    zones = {"Utgarde Pinnacle"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Svala Sorrowgrave", id = 26668},
        {name = "Gortok Palehoof", id = 26687},
        {name = "Skadi the Ruthless", id = 26693},
        {name = "King Ymiron", id = 26861},
    }
})

KOL.Tracker:RegisterInstance("up_h", {
    name = "Utgarde Pinnacle (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "SKY",
    zones = {"Utgarde Pinnacle"},
    challengeMaxLevel = 80,
    bosses = {
        {
            name = "Svala Sorrowgrave",
            id = 26668,
            hardmode = {
                yells = {
                    "Your death approaches.",
                    "The Lich King has granted me eternal life!",
                }
            }
        },
        {
            name = "Gortok Palehoof",
            id = 26687,
            hardmode = {
                yells = {
                    "What this place?",
                    "Me heard you pink thing!",
                }
            }
        },
        {
            name = "Skadi the Ruthless",
            id = 26693,
            hardmode = {
                yells = {
                    "You motherless knaves!",
                    "Sear them, Grauf!",
                }
            }
        },
        {
            name = "King Ymiron",
            id = 26861,
            hardmode = {
                yells = {
                    "What mongrels dare intrude",
                    "Bjorn! Haldor! Your master calls!",
                }
            }
        },
    }
})

-- The Culling of Stratholme
KOL.Tracker:RegisterInstance("cos_n", {
    name = "The Culling of Stratholme (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "ORANGE",
    zones = {"The Culling of Stratholme"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Meathook", id = 26529},
        {name = "Salramm the Fleshcrafter", id = 26530},
        {name = "Chrono-Lord Epoch", id = 26532},
        {name = "Mal'Ganis", id = 26533},
    }
})

KOL.Tracker:RegisterInstance("cos_h", {
    name = "The Culling of Stratholme (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "RED",
    zones = {"The Culling of Stratholme"},
    challengeMaxLevel = 80,
    bosses = {
        {
            name = "Meathook",
            id = 26529,
            hardmode = {
                yells = {
                    "Ahh... more meat!",
                }
            }
        },
        {
            name = "Salramm the Fleshcrafter",
            id = 26530,
            hardmode = {
                yells = {
                    "Ah, the flesh... the terrible, terrible flesh!",
                }
            }
        },
        {
            name = "Chrono-Lord Epoch",
            id = 26532,
            hardmode = {
                yells = {
                    "We'll see about that, young prince.",
                    "Tick tock, tick tock",
                }
            }
        },
        {
            name = "Mal'Ganis",
            id = 26533,
            hardmode = {
                yells = {
                    "Your journey has just begun, young prince.",
                    "This has been an amusing turn of events.",
                }
            }
        },
    }
})

-- Trial of the Champion
KOL.Tracker:RegisterInstance("toc5_n", {
    name = "Trial of the Champion (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "YELLOW",
    zones = {"Trial of the Champion"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Grand Champions", id = 35328, type = "yell", yell = "Well fought! Your next challenge comes from the Crusade's own ranks."},
        {name = "Argent Champion", id = {34928, 35119}, type = "yell", yell = {"Excellent work!", "I yield! I submit. Excellent work."}},
        {name = "The Black Knight", type = "multikill", id = 35451, multiKill = 3},
    }
})

KOL.Tracker:RegisterInstance("toc5_h", {
    name = "Trial of the Champion (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "ORANGE",
    zones = {"Trial of the Champion"},
    challengeMaxLevel = 80,
    bosses = {
        {
            name = "Grand Champions",
            id = 35328,
            type = "yell",
            yell = "Well fought! Your next challenge comes from the Crusade's own ranks.",
            hardmode = {
                yells = {
                    "Well fought! Your next challenge comes from the Crusade's own ranks.",
                }
            }
        },
        {
            name = "Argent Champion",
            id = {34928, 35119},
            type = "yell",
            yell = {"Excellent work!", "I yield! I submit. Excellent work."},
            hardmode = {
                yells = {
                    "Excellent work!",
                    "I yield! I submit. Excellent work.",
                }
            }
        },
        {
            name = "The Black Knight",
            type = "multikill",
            id = 35451,
            multiKill = 3,
            hardmode = {
                yells = {
                    "This is the hour of the Scourge!",
                    "No more games!",
                }
            }
        },
    }
})

-- Forge of Souls
KOL.Tracker:RegisterInstance("fos_n", {
    name = "Forge of Souls (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "BLUE",
    zones = {"The Forge of Souls"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Bronjahm", id = 36497},
        {name = "Devourer of Souls", id = 36502},
    }
})

KOL.Tracker:RegisterInstance("fos_h", {
    name = "Forge of Souls (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "CYAN",
    zones = {"The Forge of Souls"},
    challengeMaxLevel = 80,
    bosses = {
        {
            name = "Bronjahm",
            id = 36497,
            hardmode = {
                yells = {
                    "Such is the fate of all who oppose the Lich King.",
                }
            }
        },
        {
            name = "Devourer of Souls",
            id = 36502,
            hardmode = {
                yells = {
                    "Despair ends here!",
                    "Face now the lord of the forge!",
                }
            }
        },
    }
})

-- Pit of Saron
KOL.Tracker:RegisterInstance("pos_n", {
    name = "Pit of Saron (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "PURPLE",
    zones = {"Pit of Saron"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Forgemaster Garfrost", id = 36494},
        {name = "Ick & Krick", id = 36476},
        {name = "Scourgelord Tyrannus", id = 36658},
    }
})

KOL.Tracker:RegisterInstance("pos_h", {
    name = "Pit of Saron (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "LAVENDER",
    zones = {"Pit of Saron"},
    challengeMaxLevel = 80,
    bosses = {
        {
            name = "Forgemaster Garfrost",
            id = 36494,
            hardmode = {
                yells = {
                    "Tiny creatures, under foot.",
                    "I will build a monument to your demise!",
                }
            }
        },
        {
            name = "Ick & Krick",
            id = 36476,
            hardmode = {
                yells = {
                    "Ick! You! Come!",
                    "Aw, we gonna die!",
                }
            }
        },
        {
            name = "Scourgelord Tyrannus",
            id = 36658,
            hardmode = {
                yells = {
                    "Frostmourne has many hungers",
                    "Rimefang! Trap them in ice!",
                }
            }
        },
    }
})

-- Halls of Reflection
KOL.Tracker:RegisterInstance("hor_n", {
    name = "Halls of Reflection (Normal)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 1,
    color = "SKY",
    zones = {"Halls of Reflection"},
    challengeMaxLevel = 80,
    bosses = {
        {name = "Falric", id = 38112},
        {name = "Marwyn", id = 38113},
        {name = "The Lich King", id = 36954, type = "yell", yell = "FIRE! FIRE!"},  -- Escape event, completes on Bartlett's yell
    }
})

KOL.Tracker:RegisterInstance("hor_h", {
    name = "Halls of Reflection (Heroic)",
    type = "dungeon",
    expansion = "wotlk",
    difficulty = 2,
    color = "CYAN",
    zones = {"Halls of Reflection"},
    challengeMaxLevel = 80,
    bosses = {
        {
            name = "Falric",
            id = 38112,
            hardmode = {
                yells = {
                    "Men, women, and children...",
                    "Despair... so delicious...",
                }
            }
        },
        {
            name = "Marwyn",
            id = 38113,
            hardmode = {
                yells = {
                    "Death is all that you will find here!",
                    "Your flesh shall decay before your very eyes!",
                }
            }
        },
        {
            name = "The Lich King",
            id = 36954,
            type = "yell",
            yell = "FIRE! FIRE!",
            hardmode = {
                yells = {
                    "FIRE! FIRE!",
                    "There is no escape!",
                }
            }
        },
    }
})
