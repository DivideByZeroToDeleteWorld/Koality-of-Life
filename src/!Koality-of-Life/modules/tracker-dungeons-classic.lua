-- ============================================================================
-- !Koality-of-Life: Progress Tracker - Classic Dungeons
-- ============================================================================
-- Classic dungeon data (Available in WotLK for Leveling)
-- ============================================================================

local KOL = KoalityOfLife

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
