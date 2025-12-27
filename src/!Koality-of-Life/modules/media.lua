-- !Koality-of-Life: Media Module
-- Handles SharedMedia sounds, WoW sounds, and media browser UI

local addonName = "!Koality-of-Life"
local KOL = KoalityOfLife

-- Create module
local Media = {}
KOL.media = Media

-- ============================================================================
-- SharedMedia Font Registration
-- ============================================================================

function Media:RegisterFonts()
    local LSM = LibStub("LibSharedMedia-3.0")

    -- Register all monospace fonts from media/fonts/
    -- Cascadia Code (regular only)
    LSM:Register("font", "Cascadia Code", [[Interface\AddOns\!Koality-of-Life\media\fonts\CascadiaCode.ttf]])

    -- Fira Code (Regular, Medium, SemiBold, Bold)
    LSM:Register("font", "Fira Code", [[Interface\AddOns\!Koality-of-Life\media\fonts\FiraCode-Regular.ttf]])
    LSM:Register("font", "Fira Code Medium", [[Interface\AddOns\!Koality-of-Life\media\fonts\FiraCode-Medium.ttf]])
    LSM:Register("font", "Fira Code SemiBold", [[Interface\AddOns\!Koality-of-Life\media\fonts\FiraCode-SemiBold.ttf]])
    LSM:Register("font", "Fira Code Bold", [[Interface\AddOns\!Koality-of-Life\media\fonts\FiraCode-Bold.ttf]])

    -- Inconsolata (Regular, Medium, SemiBold, Bold)
    LSM:Register("font", "Inconsolata", [[Interface\AddOns\!Koality-of-Life\media\fonts\Inconsolata-Regular.ttf]])
    LSM:Register("font", "Inconsolata Medium", [[Interface\AddOns\!Koality-of-Life\media\fonts\Inconsolata-Medium.ttf]])
    LSM:Register("font", "Inconsolata SemiBold", [[Interface\AddOns\!Koality-of-Life\media\fonts\Inconsolata-SemiBold.ttf]])
    LSM:Register("font", "Inconsolata Bold", [[Interface\AddOns\!Koality-of-Life\media\fonts\Inconsolata-Bold.ttf]])

    -- JetBrains Mono (Regular, Medium, SemiBold, Bold)
    LSM:Register("font", "JetBrains Mono", [[Interface\AddOns\!Koality-of-Life\media\fonts\JetBrainsMono-Regular.ttf]])
    LSM:Register("font", "JetBrains Mono Medium", [[Interface\AddOns\!Koality-of-Life\media\fonts\JetBrainsMono-Medium.ttf]])
    LSM:Register("font", "JetBrains Mono SemiBold", [[Interface\AddOns\!Koality-of-Life\media\fonts\JetBrainsMono-SemiBold.ttf]])
    LSM:Register("font", "JetBrains Mono Bold", [[Interface\AddOns\!Koality-of-Life\media\fonts\JetBrainsMono-Bold.ttf]])

    -- Source Code Pro (Regular, Medium, Semibold, Bold)
    LSM:Register("font", "Source Code Pro", [[Interface\AddOns\!Koality-of-Life\media\fonts\SourceCodePro-Regular.ttf]])
    LSM:Register("font", "Source Code Pro Medium", [[Interface\AddOns\!Koality-of-Life\media\fonts\SourceCodePro-Medium.ttf]])
    LSM:Register("font", "Source Code Pro Semibold", [[Interface\AddOns\!Koality-of-Life\media\fonts\SourceCodePro-Semibold.ttf]])
    LSM:Register("font", "Source Code Pro Bold", [[Interface\AddOns\!Koality-of-Life\media\fonts\SourceCodePro-Bold.ttf]])

    KOL:DebugPrint("Media: Registered 17 monospace fonts with SharedMedia", 1)
end

-- ============================================================================
-- SharedMedia Sound Registration
-- ============================================================================

function Media:RegisterSounds()
    local LSM = LibStub("LibSharedMedia-3.0")

    -- Register all custom sounds from media/sounds/
    LSM:Register("sound", "KOL: Splash", [[Interface\AddOns\!Koality-of-Life\media\sounds\splash.ogg]])
    LSM:Register("sound", "KOL: Squeaky Pig", [[Interface\AddOns\!Koality-of-Life\media\sounds\Squeakypig.ogg]])
    LSM:Register("sound", "KOL: Sword Echo", [[Interface\AddOns\!Koality-of-Life\media\sounds\swordecho.ogg]])
    LSM:Register("sound", "KOL: Throw Knife", [[Interface\AddOns\!Koality-of-Life\media\sounds\throwknife.ogg]])
    LSM:Register("sound", "KOL: Incoming Message", [[Interface\AddOns\!Koality-of-Life\media\sounds\SndIncMsg.ogg]])
    LSM:Register("sound", "KOL: Warning", [[Interface\AddOns\!Koality-of-Life\media\sounds\Warning.ogg]])
    LSM:Register("sound", "KOL: Whisper", [[Interface\AddOns\!Koality-of-Life\media\sounds\Whisper.ogg]])
    LSM:Register("sound", "KOL: Jedi", [[Interface\AddOns\!Koality-of-Life\media\sounds\sound_jedi1.ogg]])

    KOL:DebugPrint("Media: Registered 8 custom sounds with SharedMedia", 1)
end

-- ============================================================================
-- SharedMedia Statusbar Registration
-- ============================================================================

function Media:RegisterStatusbars()
    local LSM = LibStub("LibSharedMedia-3.0")

    -- Register statusbar textures from media/statusbar/
    LSM:Register("statusbar", "Flat", [[Interface\AddOns\!Koality-of-Life\media\statusbar\Flat.tga]])

    KOL:DebugPrint("Media: Registered 1 statusbar texture with SharedMedia", 1)
end

-- ============================================================================
-- Sound Playback Functions
-- ============================================================================

-- Play SharedMedia sound by name (supports both friendly names and file names)
function KOL:PlaySMSound(soundName)
    if not soundName or soundName == "" then
        self:PrintTag(RED("Error:") .. " No sound name provided")
        return false
    end

    local LSM = LibStub("LibSharedMedia-3.0")

    -- Try to fetch by friendly name first
    local soundPath = LSM:Fetch("sound", soundName, true)

    -- If not found, try adding "KOL: " prefix
    if not soundPath then
        soundPath = LSM:Fetch("sound", "KOL: " .. soundName, true)
    end

    -- If still not found, check if it's a filename (like "sound_jedi1.ogg")
    if not soundPath then
        -- Try matching by filename in our registered sounds
        local allSounds = LSM:List("sound")
        for _, name in ipairs(allSounds) do
            if string.find(name, "KOL:") then
                local path = LSM:Fetch("sound", name)
                if string.find(path, soundName) then
                    soundPath = path
                    soundName = name  -- Update to friendly name for logging
                    break
                end
            end
        end
    end

    if not soundPath then
        self:PrintTag(RED("Error:") .. " SharedMedia sound '" .. soundName .. "' not found")
        return false
    end

    self:DebugPrint("Playing SharedMedia sound: " .. soundName)
    PlaySoundFile(soundPath)
    return true
end

-- Play WoW built-in sound by name
function KOL:PlayWSSound(soundName)
    if not soundName or soundName == "" then
        self:PrintTag(RED("Error:") .. " No sound name provided")
        return false
    end

    self:DebugPrint("Playing WoW sound: " .. soundName)
    PlaySound(soundName)
    return true
end

-- ============================================================================
-- WoW Built-in Sound List
-- ============================================================================

-- Common WoW sounds that can be played (non-exhaustive list)
Media.WoWSounds = {
    -- UI Sounds
    "igMainMenuOptionCheckBoxOn",
    "igMainMenuOptionCheckBoxOff",
    "igMainMenuOption",
    "igMainMenuOpen",
    "igMainMenuClose",
    "igCharacterInfoTab",
    "igSpellBookOpen",
    "igSpellBookClose",
    "igQuestLogOpen",
    "igQuestLogClose",
    "igBackPackOpen",
    "igBackPackClose",

    -- Quest Sounds
    "QUESTADDED",
    "QUESTCOMPLETED",

    -- Combat Sounds
    "LOOTWINDOWCOINSOUND",
    "RaidWarning",
    "ReadyCheck",
    "TellMessage",
    "WriteQuest",

    -- Alerts
    "AlarmClockWarning1",
    "AlarmClockWarning2",
    "AlarmClockWarning3",
    "RaidBossWhisperWarning",

    -- Level Up
    "LevelUp",

    -- PvP
    "PVPEnterQueue",
    "PVPThroughQueue",
    "PVPVictory",
}

-- ============================================================================
-- Config UI - Media Tab
-- ============================================================================

function Media:InitializeConfig()
    KOL:DebugPrint("Media: InitializeConfig() called")

    -- Create Media config group
    KOL:UIAddConfigGroup("media", "Media", 80)
    KOL:DebugPrint("Media: Config group 'media' registered")

    -- Title
    KOL:UIAddConfigTitle("media", "header", "Media Browser", 1)

    -- Description
    KOL:UIAddConfigDescription("media", "desc", "Preview and test fonts, sounds, and other media registered with SharedMedia.", 2)

    -- Spacer
    KOL:UIAddConfigSpacer("media", "spacer1", 10)

    -- Fonts Section
    KOL:UIAddConfigTitle("media", "fontsHeader", "Fonts", 15)

    -- Font dropdown with preview
    KOL:UIAddConfigSelect("media", "previewFont", {
        name = "Font Preview",
        desc = "Select a font to preview it",
        values = function()
            local LSM = LibStub("LibSharedMedia-3.0")
            local fonts = LSM:List("font")
            local fontTable = {}
            for _, fontName in ipairs(fonts) do
                fontTable[fontName] = fontName
            end
            return fontTable
        end,
        get = function(info)
            return KOL.db.profile.media and KOL.db.profile.media.previewFont or "Friz Quadrata TT"
        end,
        set = function(info, value)
            if not KOL.db.profile.media then
                KOL.db.profile.media = {}
            end
            KOL.db.profile.media.previewFont = value
            KOL:PrintTag("Font preview: " .. YELLOW(value))
        end,
        order = 20,
    })

    -- Spacer
    KOL:UIAddConfigSpacer("media", "spacer2", 30)

    -- SharedMedia Sounds Section
    KOL:UIAddConfigTitle("media", "smSoundsHeader", "SharedMedia Sounds", 35)

    -- SharedMedia sound dropdown
    KOL:UIAddConfigSelect("media", "previewSMSound", {
        name = "SharedMedia Sound",
        desc = "Select a SharedMedia sound",
        values = function()
            local LSM = LibStub("LibSharedMedia-3.0")
            local sounds = LSM:List("sound")
            local soundTable = {}
            for _, soundName in ipairs(sounds) do
                soundTable[soundName] = soundName
            end
            return soundTable
        end,
        get = function(info)
            return KOL.db.profile.media and KOL.db.profile.media.previewSMSound or "KOL: Splash"
        end,
        set = function(info, value)
            if not KOL.db.profile.media then
                KOL.db.profile.media = {}
            end
            KOL.db.profile.media.previewSMSound = value
        end,
        order = 40,
    })

    -- Play SM sound button
    KOL:UIAddConfigExecute("media", "playSMSound", {
        name = "Play Sound",
        desc = "Play the selected SharedMedia sound",
        func = function()
            local soundName = KOL.db.profile.media and KOL.db.profile.media.previewSMSound or "KOL: Splash"
            KOL:PlaySMSound(soundName)
            KOL:PrintTag("Playing: " .. YELLOW(soundName))
        end,
        order = 41,
    })

    -- Spacer
    KOL:UIAddConfigSpacer("media", "spacer3", 55)

    -- WoW Sounds Section
    KOL:UIAddConfigTitle("media", "wowSoundsHeader", "WoW Built-in Sounds", 60)

    -- WoW sound dropdown
    KOL:UIAddConfigSelect("media", "previewWSSound", {
        name = "WoW Sound",
        desc = "Select a WoW built-in sound",
        values = function()
            local soundTable = {}
            for _, soundName in ipairs(Media.WoWSounds) do
                soundTable[soundName] = soundName
            end
            return soundTable
        end,
        get = function(info)
            return KOL.db.profile.media and KOL.db.profile.media.previewWSSound or "RaidWarning"
        end,
        set = function(info, value)
            if not KOL.db.profile.media then
                KOL.db.profile.media = {}
            end
            KOL.db.profile.media.previewWSSound = value
        end,
        order = 60,
    })

    -- Play WoW sound button
    KOL:UIAddConfigExecute("media", "playWSSound", {
        name = "Play Sound",
        desc = "Play the selected WoW sound",
        func = function()
            local soundName = KOL.db.profile.media and KOL.db.profile.media.previewWSSound or "RaidWarning"
            KOL:PlayWSSound(soundName)
            KOL:PrintTag("Playing: " .. YELLOW(soundName))
        end,
        order = 61,
    })
end

-- ============================================================================
-- Module Initialization
-- ============================================================================

function Media:Initialize()
    KOL:DebugPrint("Media: Initialize() called", 4)

    -- Register fonts with SharedMedia
    self:RegisterFonts()

    -- Register sounds with SharedMedia
    self:RegisterSounds()

    -- Register statusbar textures with SharedMedia
    self:RegisterStatusbars()

    -- Initialize config UI
    self:InitializeConfig()

    KOL:DebugPrint("Media: Module initialized - 17 fonts, 8 sounds, 1 statusbar registered", 1)
end

-- ============================================================================
-- Event Registration & Frame
-- ============================================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" and KOL.db then
        Media:Initialize()
    end
end)

-- ============================================================================
-- Module Complete
-- ============================================================================
