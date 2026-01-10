-- ============================================================================
-- !Koality-of-Life: Progress Tracker Data - WotLK Raids
-- ============================================================================
-- Wrath of the Lich King raid data (10/25-player, Normal/Heroic)
-- ============================================================================

local KOL = KoalityOfLife

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
    frameWidth = 250,  -- Wider for long boss names + BEST time timer
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
    frameWidth = 250,  -- Wider for long boss names + BEST time timer
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
        },
        {
            name = "Lord Jaraxxus",
            id = 34780,
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
        },
        {
            name = "Twin Val'kyr",
            id = 34497,
        },
        {
            name = "Anub'arak",
            id = 34564,
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
        },
        {
            name = "Lord Jaraxxus",
            id = 34780,
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
        },
        {
            name = "Twin Val'kyr",
            id = 34497,
        },
        {
            name = "Anub'arak",
            id = 34564,
        },
    }
})

-- Trial of the Grand Crusader (10-player Heroic)
KOL.Tracker:RegisterInstance("toc_10h", {
    name = "Trial of the Grand Crusader (10H)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 3,
    color = "ORANGE",
    zones = {"Trial of the Crusader"},
    bosses = {
        {
            name = "The Beasts of Northrend",
            id = 34797,
        },
        {
            name = "Lord Jaraxxus",
            id = 34780,
        },
        {
            name = "Faction Champions",
            type = "yell",
            id = 34461,
            yell = "GLORY TO THE ALLIANCE!",
            yells = {
                "GLORY TO THE ALLIANCE!",
                "That was just a taste of what the future brings. FOR THE HORDE!",
            },
        },
        {
            name = "Twin Val'kyr",
            id = 34497,
        },
        {
            name = "Anub'arak",
            id = 34564,
        },
    }
})

-- Trial of the Grand Crusader (25-player Heroic)
KOL.Tracker:RegisterInstance("toc_25h", {
    name = "Trial of the Grand Crusader (25H)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 4,
    color = "ORANGE",
    zones = {"Trial of the Crusader"},
    bosses = {
        {
            name = "The Beasts of Northrend",
            id = 34797,
        },
        {
            name = "Lord Jaraxxus",
            id = 34780,
        },
        {
            name = "Faction Champions",
            type = "yell",
            id = 34461,
            yell = "GLORY TO THE ALLIANCE!",
            yells = {
                "GLORY TO THE ALLIANCE!",
                "That was just a taste of what the future brings. FOR THE HORDE!",
            },
        },
        {
            name = "Twin Val'kyr",
            id = 34497,
        },
        {
            name = "Anub'arak",
            id = 34564,
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
                },
                {
                    name = "Lady Deathwhisper",
                    id = 36855,
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
                },
                {
                    name = "Deathbringer Saurfang",
                    id = 37813,
                },
            }
        },
        {
            name = "The Plagueworks",
            bosses = {
                {
                    name = "Festergut",
                    id = 36626,
                },
                {
                    name = "Rotface",
                    id = 36627,
                },
                {
                    name = "Professor Putricide",
                    id = 36678,
                },
            }
        },
        {
            name = "The Crimson Hall",
            bosses = {
                {
                    name = "Blood Prince Council",
                    id = 37970,
                },
                {
                    name = "Blood-Queen Lana'thel",
                    id = 37955,
                },
            }
        },
        {
            name = "Frostwing Halls",
            bosses = {
                {
                    name = "Valithria Dreamwalker",
                    id = 36789,
                    detectType = "cast",        -- Valithria doesn't die, she's healed
                    detectSpellId = 71189,      -- Victory spell cast when healed to full
                },
                {
                    name = "Sindragosa",
                    id = 36853,
                },
            }
        },
        {
            name = "The Frozen Throne",
            bosses = {
                {
                    name = "The Lich King",
                    id = 36597,
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
                },
                {
                    name = "Lady Deathwhisper",
                    id = 36855,
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
                },
                {
                    name = "Deathbringer Saurfang",
                    id = 37813,
                },
            }
        },
        {
            name = "The Plagueworks",
            bosses = {
                {
                    name = "Festergut",
                    id = 36626,
                },
                {
                    name = "Rotface",
                    id = 36627,
                },
                {
                    name = "Professor Putricide",
                    id = 36678,
                },
            }
        },
        {
            name = "The Crimson Hall",
            bosses = {
                {
                    name = "Blood Prince Council",
                    id = 37970,
                },
                {
                    name = "Blood-Queen Lana'thel",
                    id = 37955,
                },
            }
        },
        {
            name = "Frostwing Halls",
            bosses = {
                {
                    name = "Valithria Dreamwalker",
                    id = 36789,
                    detectType = "cast",        -- Valithria doesn't die, she's healed
                    detectSpellId = 71189,      -- Victory spell cast when healed to full
                },
                {
                    name = "Sindragosa",
                    id = 36853,
                },
            }
        },
        {
            name = "The Frozen Throne",
            bosses = {
                {
                    name = "The Lich King",
                    id = 36597,
                },
            }
        },
    }
})

-- Icecrown Citadel (10-player Heroic)
KOL.Tracker:RegisterInstance("icc_10h", {
    name = "Icecrown Citadel (10H)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 3,
    color = "PURPLE",
    zones = {"Icecrown Citadel"},
    groups = {
        {
            name = "The Lower Spire",
            bosses = {
                { name = "Lord Marrowgar", id = 36612 },
                { name = "Lady Deathwhisper", id = 36855 },
                {
                    name = "Gunship Battle",
                    type = "yell",
                    id = {37540, 36939},
                    anyNPC = true,
                    yell = "Don't say I didn't warn ya, scoundrels!",
                    yells = {
                        "Don't say I didn't warn ya, scoundrels!",
                        "The Alliance falter. Onward to the Lich King!",
                    },
                },
                { name = "Deathbringer Saurfang", id = 37813 },
            }
        },
        {
            name = "The Plagueworks",
            bosses = {
                { name = "Festergut", id = 36626 },
                { name = "Rotface", id = 36627 },
                { name = "Professor Putricide", id = 36678 },
            }
        },
        {
            name = "The Crimson Hall",
            bosses = {
                { name = "Blood Prince Council", id = 37970 },
                { name = "Blood-Queen Lana'thel", id = 37955 },
            }
        },
        {
            name = "Frostwing Halls",
            bosses = {
                {
                    name = "Valithria Dreamwalker",
                    id = 36789,
                    detectType = "cast",
                    detectSpellId = 71189,
                },
                { name = "Sindragosa", id = 36853 },
            }
        },
        {
            name = "The Frozen Throne",
            bosses = {
                { name = "The Lich King", id = 36597 },
            }
        },
    }
})

-- Icecrown Citadel (25-player Heroic)
KOL.Tracker:RegisterInstance("icc_25h", {
    name = "Icecrown Citadel (25H)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 4,
    color = "PURPLE",
    zones = {"Icecrown Citadel"},
    groups = {
        {
            name = "The Lower Spire",
            bosses = {
                { name = "Lord Marrowgar", id = 36612 },
                { name = "Lady Deathwhisper", id = 36855 },
                {
                    name = "Gunship Battle",
                    type = "yell",
                    id = {37540, 36939},
                    anyNPC = true,
                    yell = "Don't say I didn't warn ya, scoundrels!",
                    yells = {
                        "Don't say I didn't warn ya, scoundrels!",
                        "The Alliance falter. Onward to the Lich King!",
                    },
                },
                { name = "Deathbringer Saurfang", id = 37813 },
            }
        },
        {
            name = "The Plagueworks",
            bosses = {
                { name = "Festergut", id = 36626 },
                { name = "Rotface", id = 36627 },
                { name = "Professor Putricide", id = 36678 },
            }
        },
        {
            name = "The Crimson Hall",
            bosses = {
                { name = "Blood Prince Council", id = 37970 },
                { name = "Blood-Queen Lana'thel", id = 37955 },
            }
        },
        {
            name = "Frostwing Halls",
            bosses = {
                {
                    name = "Valithria Dreamwalker",
                    id = 36789,
                    detectType = "cast",
                    detectSpellId = 71189,
                },
                { name = "Sindragosa", id = 36853 },
            }
        },
        {
            name = "The Frozen Throne",
            bosses = {
                { name = "The Lich King", id = 36597 },
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

-- Ruby Sanctum (10-player Heroic)
KOL.Tracker:RegisterInstance("rs_10h", {
    name = "Ruby Sanctum (10H)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 3,
    color = "PINK",
    zones = {"The Ruby Sanctum"},
    bosses = {
        {name = "Halion", id = 39863},
    }
})

-- Ruby Sanctum (25-player Heroic)
KOL.Tracker:RegisterInstance("rs_25h", {
    name = "Ruby Sanctum (25H)",
    type = "raid",
    expansion = "wotlk",
    difficulty = 4,
    color = "PINK",
    zones = {"The Ruby Sanctum"},
    bosses = {
        {name = "Halion", id = 39863},
    }
})
