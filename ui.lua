-- Koality-of-Life: UI and Configuration System
-- Professional configuration interface using AceConfig-3.0

local addonName = "Koality-of-Life"
local KOL = KoalityOfLife
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

-- Store module config groups
KOL.configGroups = {}

-- Rainbow color sequence for titles
local rainbowColors = {
    "FF0000", "FF4400", "FF8800", "FFCC00", "FFFF00", "CCFF00",
    "88FF00", "44FF00", "00FF00", "00FF88", "00FFFF", "55AAFF",
    "7799FF", "8888FF", "AA66FF"
}

-- ============================================================================
-- Rainbow Text Helper
-- ============================================================================

local function RainbowText(text)
    local result = ""
    local colorIndex = 1
    
    for i = 1, #text do
        local char = text:sub(i, i)
        result = result .. "|cFF" .. rainbowColors[colorIndex] .. char
        colorIndex = colorIndex + 1
        if colorIndex > #rainbowColors then
            colorIndex = 1
        end
    end
    
    return result .. "|r"
end

-- ============================================================================
-- Initialize UI System
-- ============================================================================

function KOL:InitializeUI()
    -- Create main options table
    local options = {
        name = RainbowText("Koality of Life"),
        type = "group",
        args = {
            header = {
                type = "description",
                name = RainbowText("Koality of Life") .. " |cFFFFFFFFv" .. self.version .. "|r\n|cFFAAAAAAQuality of life improvements for Synastria|r\n",
                fontSize = "medium",
                order = 0,
            },
            general = {
                type = "group",
                name = "|cFFFFDD00General|r",
                order = 1,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Enable Addon",
                        desc = "Enable or disable Koality of Life",
                        get = function() return self.db.profile.enabled end,
                        set = function(_, value) self.db.profile.enabled = value end,
                        width = "full",
                        order = 1,
                    },
                    debug = {
                        type = "toggle",
                        name = "Debug Mode",
                        desc = "Enable debug output in chat",
                        get = function() return self.db.profile.debug end,
                        set = function(_, value) 
                            self.db.profile.debug = value
                            local status = value and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
                            self:PrintTag("Debug mode " .. status)
                        end,
                        width = "full",
                        order = 2,
                    },
                }
            },
        }
    }
    
    -- Register options
    AceConfig:RegisterOptionsTable("KoalityOfLife", options)
    
    -- Add to Blizzard Interface Options
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("KoalityOfLife", RainbowText("Koality of Life"))
    
    -- Register profile options
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    options.args.profiles.order = 100
end

-- ============================================================================
-- Module Registration Functions
-- ============================================================================

-- Add a config group for a module
function KOL:UIAddConfigGroup(name, displayName, order)
    if not self.configGroups then
        self.configGroups = {}
    end
    
    -- Create colored display name
    local coloredName = "|cFF" .. (order and rainbowColors[math.min(order, #rainbowColors)] or "88AAFF") .. displayName .. "|r"
    
    local group = {
        type = "group",
        name = coloredName,
        order = order or 50,
        args = {}
    }
    
    self.configGroups[name] = group
    
    -- Get the main options table and add this group
    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
    local appName = "KoalityOfLife"
    
    -- Validate the app exists and get its options
    if AceConfigRegistry:GetOptionsTable(appName) then
        local options = AceConfigRegistry:GetOptionsTable(appName)
        if type(options) == "table" and options.args then
            options.args[name] = group
        end
    end
    
    return group
end

-- Add a header/title to a config group
function KOL:UIAddConfigTitle(groupName, key, text, order)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "header",
        name = text,
        order = order or 0,
    }
end

-- Add a description to a config group
function KOL:UIAddConfigDescription(groupName, key, text, order)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "description",
        name = text,
        fontSize = "medium",
        order = order or 0,
    }
end

-- Add a toggle (checkbox) option
function KOL:UIAddConfigToggle(groupName, key, params)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "toggle",
        name = params.name,
        desc = params.desc,
        get = params.get,
        set = params.set,
        width = params.width or "normal",
        order = params.order or 10,
    }
end

-- Add a slider option
function KOL:UIAddConfigSlider(groupName, key, params)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "range",
        name = params.name,
        desc = params.desc,
        min = params.min or 0,
        max = params.max or 100,
        step = params.step or 1,
        get = params.get,
        set = params.set,
        width = params.width or "normal",
        order = params.order or 10,
    }
end

-- Add a dropdown/select option
function KOL:UIAddConfigSelect(groupName, key, params)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "select",
        name = params.name,
        desc = params.desc,
        values = params.values,
        get = params.get,
        set = params.set,
        width = params.width or "normal",
        order = params.order or 10,
        style = params.style or "dropdown",
    }
end

-- Add a font selector using LibSharedMedia
function KOL:UIAddConfigFontSelect(groupName, key, params)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "select",
        name = params.name,
        desc = params.desc,
        dialogControl = "LSM30_Font",
        values = LSM:HashTable("font"),
        get = params.get,
        set = params.set,
        width = params.width or "double",
        order = params.order or 10,
    }
end

-- Add a text input field
function KOL:UIAddConfigInput(groupName, key, params)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "input",
        name = params.name,
        desc = params.desc,
        get = params.get,
        set = params.set,
        width = params.width or "normal",
        order = params.order or 10,
        multiline = params.multiline or false,
    }
end

-- Add a color picker
function KOL:UIAddConfigColor(groupName, key, params)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "color",
        name = params.name,
        desc = params.desc,
        hasAlpha = params.hasAlpha or false,
        get = params.get,
        set = params.set,
        width = params.width or "normal",
        order = params.order or 10,
    }
end

-- Add an execute button
function KOL:UIAddConfigExecute(groupName, key, params)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "execute",
        name = params.name,
        desc = params.desc,
        func = params.func,
        width = params.width or "normal",
        order = params.order or 10,
    }
end

-- Add a spacer
function KOL:UIAddConfigSpacer(groupName, key, order)
    local group = self.configGroups[groupName]
    if not group then return end
    
    group.args[key] = {
        type = "description",
        name = " ",
        order = order or 50,
    }
end
