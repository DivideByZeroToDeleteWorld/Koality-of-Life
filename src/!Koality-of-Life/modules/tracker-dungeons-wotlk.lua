-- ============================================================================
-- !Koality-of-Life: Progress Tracker Data - WotLK Dungeons
-- ============================================================================
-- Wrath of the Lich King dungeon data (Normal and Heroic)
-- ============================================================================

local KOL = KoalityOfLife

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
        {name = "General Bjarngrim", id = 28586},
        {name = "Volkhan", id = 28587},
        {name = "Ionar", id = 28546},
        {name = "Loken", id = 28923},
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
        {name = "Drakos the Interrogator", id = 27654},
        {name = "Varos Cloudstrider", id = 27447},
        {name = "Mage-Lord Urom", id = 27655},
        {name = "Ley-Guardian Eregos", id = 27656},
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
        {name = "Svala Sorrowgrave", id = 26668},
        {name = "Gortok Palehoof", id = 26687},
        {name = "Skadi the Ruthless", id = 26693},
        {name = "King Ymiron", id = 26861},
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
        {name = "Meathook", id = 26529},
        {name = "Salramm the Fleshcrafter", id = 26530},
        {name = "Chrono-Lord Epoch", id = 26532},
        {name = "Mal'Ganis", id = 26533},
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
        {name = "Grand Champions", id = 35328, type = "yell", yell = "Well fought! Your next challenge comes from the Crusade's own ranks."},
        {name = "Argent Champion", id = {34928, 35119}, type = "yell", yell = {"Excellent work!", "I yield! I submit. Excellent work."}},
        {name = "The Black Knight", type = "multikill", id = 35451, multiKill = 3},
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
        {name = "Bronjahm", id = 36497},
        {name = "Devourer of Souls", id = 36502},
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
        {name = "Forgemaster Garfrost", id = 36494},
        {name = "Ick & Krick", id = 36476},
        {name = "Scourgelord Tyrannus", id = 36658},
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
        {name = "Falric", id = 38112},
        {name = "Marwyn", id = 38113},
        {name = "The Lich King", id = 36954, type = "yell", yell = "FIRE! FIRE!"},
    }
})
