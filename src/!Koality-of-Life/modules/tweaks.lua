local KOL = KoalityOfLife
local LSM = LibStub("LibSharedMedia-3.0")

local itemTrackerDefaults = {
    enabled = true,
    zoneFont = "Friz Quadrata TT",
    zoneFontSize = 14,
    zoneFontOutline = "THICKOUTLINE",
    npcFont = "Friz Quadrata TT",
    npcFontSize = 14,
    npcFontOutline = "THICKOUTLINE",
    itemFont = "Friz Quadrata TT",
    itemFontSize = 14,
    itemFontOutline = "THICKOUTLINE",
    limitFont = "Friz Quadrata TT",
    limitFontSize = 14,
    limitFontOutline = "THICKOUTLINE",
    scrollbarEnabled = true,
    scrollbarHidden = false,
    scrollbarWidth = 16,
    scrollbarTrackBg = {r = 0.05, g = 0.05, b = 0.05, a = 0.9},
    scrollbarTrackBorder = {r = 0.51, g = 0.25, b = 0.8, a = 0},
    scrollbarThumbBg = {r = 0.51, g = 0.25, b = 0.8, a = 1},
    scrollbarThumbBorder = {r = 0.51, g = 0.25, b = 0.8, a = 1},
    scrollbarButtonBg = {r = 0.15, g = 0.15, b = 0.15, a = 0.9},
    scrollbarButtonBorder = {r = 0.51, g = 0.25, b = 0.8, a = 1},
    scrollbarButtonArrow = {r = 0.51, g = 0.25, b = 0.8, a = 1},
}

local itemHuntFontsApplied = {}

local lastAppliedSettings = {
    zoneFont = nil,
    zoneFontSize = nil,
    zoneFontOutline = nil,
    npcFont = nil,
    npcFontSize = nil,
    npcFontOutline = nil,
    itemFont = nil,
    itemFontSize = nil,
    itemFontOutline = nil,
    limitFont = nil,
    limitFontSize = nil,
    limitFontOutline = nil,
}

local fontOutlineOptions = {
    ["NONE"] = "None",
    ["OUTLINE"] = "Outline",
    ["THICKOUTLINE"] = "Thick Outline",
    ["MONOCHROME"] = "Monochrome",
    ["OUTLINE, MONOCHROME"] = "Outline + Monochrome",
    ["THICKOUTLINE, MONOCHROME"] = "Thick Outline + Monochrome",
}

local COLOR_KEYWORDS = {
    ["purchase"] = "GREEN",
    ["vendor"] = "YELLOW",
    ["sell"] = "ORANGE",
    ["buy"] = "MINT",
    ["trade"] = "PEACH",
    ["merchant"] = "YELLOW",
    ["combat"] = "RED",
    ["attack"] = "ROSE",
    ["defense"] = "BLUE",
    ["buff"] = "LAVENDER",
    ["control"] = "CYAN",
    ["interface"] = "SKY",
    ["ui"] = "PURPLE",
    ["display"] = "BLUE",
    ["default"] = "PINK",
}

local function PickPastelColor(blockName)
    local lowerName = string.lower(blockName)

    for keyword, colorName in pairs(COLOR_KEYWORDS) do
        if string.find(lowerName, keyword) then
            return KOL.Colors:GetPastel(colorName)
        end
    end

    return KOL.Colors:GetPastel("PINK")
end

local function GetAveragedFont(requestedSize)
    local generalSize = KOL.db.profile.generalFontSize or 12
    local averageSize = math.floor((requestedSize + generalSize) / 2)

    local fontName = KOL.db.profile.generalFont or "Friz Quadrata TT"
    local fontOutline = KOL.db.profile.generalFontOutline or "THICKOUTLINE"
    local fontPath = LibStub("LibSharedMedia-3.0"):Fetch("font", fontName)

    return fontPath, averageSize, fontOutline
end

KOL.Tweaks = {}
local Tweaks = KOL.Tweaks

function Tweaks:Initialize()
    if not KOL.db.profile.tweaks then
        KOL.db.profile.tweaks = {
            vendor = {
                buyStack = false,
            }
        }
    end

    if not KOL.db.profile.tweaks.itemTracker then
        KOL.db.profile.tweaks.itemTracker = {}
    end
    for key, value in pairs(itemTrackerDefaults) do
        if KOL.db.profile.tweaks.itemTracker[key] == nil then
            KOL.db.profile.tweaks.itemTracker[key] = value
        end
    end

    if not KOL.db.profile.tweaks.synastria then
        KOL.db.profile.tweaks.synastria = {
            scrollbarSkinning = true,
        }
    end

    local scrollbarDefaults = {
        width = 16,
        hidden = false,
        hideUpButton = false,
        hideDownButton = false,
        trackBg = {r = 0.1, g = 0.1, b = 0.1, a = 0.8},
        trackBorder = {r = 0.3, g = 0.3, b = 0.3, a = 1},
        thumbBg = {r = 0.3, g = 0.3, b = 0.3, a = 1},
        thumbBorder = {r = 0.5, g = 0.5, b = 0.5, a = 1},
        buttonBg = {r = 0.2, g = 0.2, b = 0.2, a = 1},
        buttonBorder = {r = 0.4, g = 0.4, b = 0.4, a = 1},
        buttonArrow = {r = 0.8, g = 0.8, b = 0.8, a = 1},
    }
    if not KOL.db.profile.tweaks.synastria.scrollbar then
        KOL.db.profile.tweaks.synastria.scrollbar = scrollbarDefaults
    else
        for k, v in pairs(scrollbarDefaults) do
            if KOL.db.profile.tweaks.synastria.scrollbar[k] == nil then
                KOL.db.profile.tweaks.synastria.scrollbar[k] = v
            end
        end
    end

    self:SetupConfigUI()

    self:StartItemHuntBatch()

    self:SetupQuestHelperSuppressor()

    KOL:DebugPrint("Tweaks: Module initialized", 1)
end

-- Automatically closes the annoying "QuestHelper has broke" popup
function Tweaks:SetupQuestHelperSuppressor()
    if not self.questHelperHooked then
        local function CheckAndHideQHPopup(popup)
            if not popup or not popup:IsVisible() then return end

            local textWidget = popup.text or _G[popup:GetName() .. "Text"]
            if textWidget then
                local text = textWidget:GetText()
                if text and string.find(text, "QuestHelper has broken") then
                    popup:Hide()
                    KOL:DebugPrint("Tweaks: Suppressed QuestHelper error popup", 1)
                    return true
                end
            end
            return false
        end

        local suppressorFrame = CreateFrame("Frame")
        suppressorFrame.elapsed = 0
        suppressorFrame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed < 0.1 then return end
            self.elapsed = 0

            for i = 1, 4 do
                local popup = _G["StaticPopup" .. i]
                if popup and popup:IsVisible() then
                    CheckAndHideQHPopup(popup)
                end
            end
        end)

        self.questHelperHooked = true
        KOL:DebugPrint("Tweaks: QuestHelper popup suppressor active", 2)
    end
end

local function ApplyFontToItemHuntFrame(frame, fontPath, fontSize, fontOutline, frameName)
    if itemHuntFontsApplied[frameName] then
        -- Verify font is still correct (in case ItemHunt reset it)
        local regionCount = (frame.GetNumRegions and frame:GetNumRegions()) or 0
        if regionCount > 0 then
            local region = select(1, frame:GetRegions())
            if region and region:GetObjectType() == "FontString" then
                local currentFont, currentSize, currentFlags = region:GetFont()
                if currentFont == fontPath and math.abs((currentSize or 0) - fontSize) < 0.1 then
                    return 0
                end
            end
        end
    end

    local fontStringsUpdated = 0

    local regionCount = (frame.GetNumRegions and frame:GetNumRegions()) or 0
    if regionCount > 0 then
        for i = 1, regionCount do
            local region = select(i, frame:GetRegions())
            if region and region:GetObjectType() == "FontString" then
                local currentFont, currentSize = region:GetFont()
                local fontMatches = (currentFont == fontPath)
                local sizeMatches = (math.abs((currentSize or 0) - fontSize) < 0.1)

                if not fontMatches or not sizeMatches then
                    local success = pcall(function()
                        region:SetFont(fontPath, fontSize, fontOutline)
                    end)
                    if success then
                        fontStringsUpdated = fontStringsUpdated + 1
                    end
                end
            end
        end
    end

    local props = {"text", "label", "title", "Text", "Label", "Title"}
    for _, prop in ipairs(props) do
        if frame[prop] and frame[prop].SetFont and frame[prop].GetFont then
            local currentFont, currentSize = frame[prop]:GetFont()
            local fontMatches = (currentFont == fontPath)
            local sizeMatches = (math.abs((currentSize or 0) - fontSize) < 0.1)

            if not fontMatches or not sizeMatches then
                local success = pcall(function()
                    frame[prop]:SetFont(fontPath, fontSize, fontOutline)
                end)
                if success then
                    fontStringsUpdated = fontStringsUpdated + 1
                end
            end
        end
    end

    if fontStringsUpdated > 0 then
        itemHuntFontsApplied[frameName] = true
    end

    return fontStringsUpdated
end

function Tweaks:ScanAndApplyItemHuntFonts()
    if not KOL.db.profile.tweaks.itemTracker or not KOL.db.profile.tweaks.itemTracker.enabled then
        return 0
    end

    local settings = KOL.db.profile.tweaks.itemTracker

    local settingsChanged = false
    for settingKey, settingValue in pairs(lastAppliedSettings) do
        if settings[settingKey] ~= settingValue then
            settingsChanged = true
            break
        end
    end

    if settingsChanged then
        itemHuntFontsApplied = {}
        for settingKey, _ in pairs(lastAppliedSettings) do
            lastAppliedSettings[settingKey] = settings[settingKey]
        end
    end

    local totalUpdated = 0

    local itemFontPath = LSM:Fetch("font", settings.itemFont)
    if itemFontPath then
        for i = 1, 50 do
            local frameName = "ItemHuntFrameItem" .. i
            local frame = _G[frameName]
            if frame and frame:IsVisible() then
                totalUpdated = totalUpdated + ApplyFontToItemHuntFrame(frame, itemFontPath, settings.itemFontSize, settings.itemFontOutline, frameName)
            end
        end
    end

    local npcFontPath = LSM:Fetch("font", settings.npcFont)
    if npcFontPath then
        for i = 1, 20 do
            local frameName = "ItemHuntFrameObj" .. i
            local frame = _G[frameName]
            if frame and frame:IsVisible() then
                totalUpdated = totalUpdated + ApplyFontToItemHuntFrame(frame, npcFontPath, settings.npcFontSize, settings.npcFontOutline, frameName)
            end
        end
    end

    local limitFontPath = LSM:Fetch("font", settings.limitFont)
    if limitFontPath then
        for i = 1, 50 do
            local frameName = "ItemHuntFrameLimit" .. i
            local frame = _G[frameName]
            if frame and frame:IsVisible() then
                totalUpdated = totalUpdated + ApplyFontToItemHuntFrame(frame, limitFontPath, settings.limitFontSize, settings.limitFontOutline, frameName)
            end
        end
    end

    local zoneFontPath = LSM:Fetch("font", settings.zoneFont)
    if zoneFontPath then
        local otherFrames = {"ItemHuntFrameHeader", "ItemHuntFrameObjLimit"}
        for _, frameName in ipairs(otherFrames) do
            local frame = _G[frameName]
            if frame and frame:IsVisible() then
                totalUpdated = totalUpdated + ApplyFontToItemHuntFrame(frame, zoneFontPath, settings.zoneFontSize, settings.zoneFontOutline, frameName)
            end
        end
    end

    if totalUpdated > 0 then
        KOL:DebugPrint("Tweaks: ItemTracker - " .. totalUpdated .. " FontStrings updated", 3)
    end

    return totalUpdated
end

function Tweaks:StartItemHuntBatch()
    if self.itemHuntScannerActive then
        return
    end

    self.itemHuntScannerActive = true

    if KOL.db.profile.tweaks and KOL.db.profile.tweaks.itemTracker then
        local settings = KOL.db.profile.tweaks.itemTracker
        for settingKey, _ in pairs(lastAppliedSettings) do
            lastAppliedSettings[settingKey] = settings[settingKey]
        end
    end

    KOL:BatchConfigure("itemHunt", {
        interval = 0.5,
        processMode = "all",
        triggerMode = "interval",
        maxQueueSize = 5,
    })

    KOL:BatchAdd("itemHunt", "scanAll", function()
        Tweaks:ScanAndApplyItemHuntFonts()
        Tweaks:ApplyItemTrackerScrollbar()
        if KOL.UIFactory and KOL.UIFactory.SkinRegisteredScrollBars then
            KOL.UIFactory:SkinRegisteredScrollBars()
        end
    end, 3)

    KOL:BatchStart("itemHunt")

    KOL:DebugPrint("Tweaks: Started ItemHunt batch scanner", 3)
end

function Tweaks:ResetItemHuntTracking()
    itemHuntFontsApplied = {}
    self.itemHuntScannerActive = false
    self:StartItemHuntBatch()
    self:ApplyItemTrackerScrollbar()
end

function Tweaks:ApplyItemTrackerFont()
    itemHuntFontsApplied = {}
    self:ScanAndApplyItemHuntFonts()
end

local itemHuntScrollbarSkinned = false

function Tweaks:ApplyItemTrackerScrollbar()
    local settings = KOL.db.profile.tweaks.itemTracker

    local scrollBar = _G["ItemHuntFrame-ScrollFrameScrollBar"]
    if not scrollBar then
        KOL:DebugPrint("Tweaks: ItemHuntFrame scrollbar not found", 3)
        return
    end

    if settings.scrollbarHidden then
        scrollBar:Hide()
        if scrollBar.kolBackdrop then scrollBar.kolBackdrop:Hide() end
        local scrollBarName = scrollBar:GetName() or ""
        local upButton = scrollBar.ScrollUpButton or scrollBar.UpButton or _G[scrollBarName .. "ScrollUpButton"]
        local downButton = scrollBar.ScrollDownButton or scrollBar.DownButton or _G[scrollBarName .. "ScrollDownButton"]
        local thumb = scrollBar.ThumbTexture or scrollBar.thumbTexture or _G[scrollBarName .. "ThumbTexture"]
        if upButton then upButton:Hide(); if upButton.kolBackdrop then upButton.kolBackdrop:Hide() end end
        if downButton then downButton:Hide(); if downButton.kolBackdrop then downButton.kolBackdrop:Hide() end end
        if thumb and thumb.kolBackdrop then thumb.kolBackdrop:Hide() end
        KOL:DebugPrint("Tweaks: ItemHuntFrame scrollbar hidden", 3)
        return
    else
        scrollBar:Show()
        if scrollBar.kolBackdrop then scrollBar.kolBackdrop:Show() end
        local scrollBarName = scrollBar:GetName() or ""
        local upButton = scrollBar.ScrollUpButton or scrollBar.UpButton or _G[scrollBarName .. "ScrollUpButton"]
        local downButton = scrollBar.ScrollDownButton or scrollBar.DownButton or _G[scrollBarName .. "ScrollDownButton"]
        local thumb = scrollBar.ThumbTexture or scrollBar.thumbTexture or _G[scrollBarName .. "ThumbTexture"]
        if upButton then upButton:Show(); if upButton.kolBackdrop then upButton.kolBackdrop:Show() end end
        if downButton then downButton:Show(); if downButton.kolBackdrop then downButton.kolBackdrop:Show() end end
        if thumb and thumb.kolBackdrop then thumb.kolBackdrop:Show() end
    end

    if not settings.scrollbarEnabled then
        KOL:DebugPrint("Tweaks: ItemTracker scrollbar skinning disabled", 3)
        return
    end

    if itemHuntScrollbarSkinned and scrollBar.kolSkinned then
        return
    end

    local colors = {
        width = settings.scrollbarWidth or 16,
        track = {
            bg = {settings.scrollbarTrackBg.r, settings.scrollbarTrackBg.g, settings.scrollbarTrackBg.b, settings.scrollbarTrackBg.a},
            border = {settings.scrollbarTrackBorder.r, settings.scrollbarTrackBorder.g, settings.scrollbarTrackBorder.b, settings.scrollbarTrackBorder.a},
        },
        thumb = {
            bg = {settings.scrollbarThumbBg.r, settings.scrollbarThumbBg.g, settings.scrollbarThumbBg.b, settings.scrollbarThumbBg.a},
            border = {settings.scrollbarThumbBorder.r, settings.scrollbarThumbBorder.g, settings.scrollbarThumbBorder.b, settings.scrollbarThumbBorder.a},
        },
        button = {
            bg = {settings.scrollbarButtonBg.r, settings.scrollbarButtonBg.g, settings.scrollbarButtonBg.b, settings.scrollbarButtonBg.a},
            border = {settings.scrollbarButtonBorder.r, settings.scrollbarButtonBorder.g, settings.scrollbarButtonBorder.b, settings.scrollbarButtonBorder.a},
            arrow = {settings.scrollbarButtonArrow.r, settings.scrollbarButtonArrow.g, settings.scrollbarButtonArrow.b, settings.scrollbarButtonArrow.a},
        },
    }

    local scrollFrame = _G["ItemHuntFrame-ScrollFrame"]
    if scrollFrame then
        scrollBar.kolSkinned = nil
        KOL:SkinScrollBar(scrollFrame, "ItemHuntFrame-ScrollFrameScrollBar", colors)
        itemHuntScrollbarSkinned = true
        KOL:DebugPrint("Tweaks: ItemHuntFrame scrollbar skinned", 2)
    else
        scrollBar.kolSkinned = nil
        if KOL.SkinScrollBar then
            local mockParent = {["ItemHuntFrame-ScrollFrameScrollBar"] = scrollBar}
            KOL:SkinScrollBar(mockParent, "ItemHuntFrame-ScrollFrameScrollBar", colors)
            itemHuntScrollbarSkinned = true
            KOL:DebugPrint("Tweaks: ItemHuntFrame scrollbar skinned (direct)", 2)
        end
    end
end

function Tweaks:ResetItemTrackerScrollbar()
    local scrollBar = _G["ItemHuntFrame-ScrollFrameScrollBar"]
    if scrollBar then
        scrollBar.kolSkinned = nil
        if scrollBar.kolBackdrop then
            scrollBar.kolBackdrop:Hide()
            scrollBar.kolBackdrop = nil
        end

        local scrollBarName = scrollBar:GetName() or ""
        local upButton = scrollBar.ScrollUpButton or scrollBar.UpButton or _G[scrollBarName .. "ScrollUpButton"]
        local downButton = scrollBar.ScrollDownButton or scrollBar.DownButton or _G[scrollBarName .. "ScrollDownButton"]
        local thumb = scrollBar.ThumbTexture or scrollBar.thumbTexture or _G[scrollBarName .. "ThumbTexture"]

        if upButton then
            upButton.kolSkinned = nil
            if upButton.kolBackdrop then upButton.kolBackdrop:Hide(); upButton.kolBackdrop = nil end
            if upButton.kolArrowText then upButton.kolArrowText:Hide(); upButton.kolArrowText = nil end
        end
        if downButton then
            downButton.kolSkinned = nil
            if downButton.kolBackdrop then downButton.kolBackdrop:Hide(); downButton.kolBackdrop = nil end
            if downButton.kolArrowText then downButton.kolArrowText:Hide(); downButton.kolArrowText = nil end
        end
        if thumb and thumb.kolBackdrop then
            thumb.kolBackdrop:Hide()
            thumb.kolBackdrop = nil
        end
    end
    itemHuntScrollbarSkinned = false
    self:ApplyItemTrackerScrollbar()
end

local function CreateBlock(subtab, blockName, order, colorOverride)
    if not KOL.configOptions or not KOL.configOptions.args.tweaks then
        KOL:DebugPrint("Tweaks: Cannot create block - config not initialized", 1)
        return nil
    end

    local subtabArgs = KOL.configOptions.args.tweaks.args[subtab]
    if not subtabArgs or not subtabArgs.args then
        KOL:DebugPrint("Tweaks: Cannot find subtab: " .. tostring(subtab), 1)
        return nil
    end

    local color = colorOverride or PickPastelColor(blockName)
    local colorHex = KOL.Colors:ToHex(color)

    local fontPath, fontSize, fontOutline = GetAveragedFont(14)

    local blockKey = string.lower(string.gsub(blockName, " ", "_"))

    subtabArgs.args[blockKey] = {
        type = "group",
        name = " ",
        order = order,
        inline = true,
        args = {
            blockTitle = {
                type = "description",
                name = "|cFF" .. colorHex .. blockName .. "|r",
                fontSize = "large",
                order = 0,
            },
            separator = {
                type = "description",
                name = " ",
                order = 1,
            },
        }
    }

    KOL:DebugPrint("Tweaks: Created block '" .. blockName .. "' in '" .. subtab .. "'", 3)
    return subtabArgs.args[blockKey]
end

function Tweaks:SetupConfigUI()
    if not KOL.configOptions then
        KOL:DebugPrint("Tweaks: Config not ready yet, deferring setup", 3)
        return
    end

    local purchaseBlock = CreateBlock("vendors", "Purchase Control", 1)

    if purchaseBlock then
        purchaseBlock.args.buyStack = {
            type = "toggle",
            name = "Buy Stack",
            desc = "When enabled, Shift+clicking an item in the vendor window will show a custom 'BUY STACK' dialog that purchases a full stack (20) of the item instead of buying just one.\n\n|cFFFF8888Requires /reload to take effect.|r",
            get = function() return KOL.db.profile.tweaks.vendor.buyStack end,
            set = function(_, value)
                KOL.db.profile.tweaks.vendor.buyStack = value
                if value then
                    KOL:PrintTag("|cFF00FF00Enabled|r Buy Stack feature |cFFFFAAAA(requires /reload)|r")
                else
                    KOL:PrintTag("|cFFFF0000Disabled|r Buy Stack feature |cFFFFAAAA(requires /reload)|r")
                end
            end,
            width = "full",
            order = 2,
        }
    end

    local synastriaTab = KOL.configOptions.args.tweaks.args.synastria.args

    synastriaTab.itemTracker = {
        type = "group",
        name = "Item Tracker",
        order = 3,
        args = {
            header = {
                type = "description",
                name = "ITEM TRACKER|1,0.6,0.2",
                dialogControl = "KOL_SectionHeader",
                width = "full",
                order = 0,
            },
            desc = {
                type = "description",
                name = "|cFFAAAAAACustomize fonts for different ItemHunt elements (zones, NPCs, items, limits).|r\n",
                fontSize = "small",
                order = 0.1,
            },

            enabled = {
                type = "toggle",
                name = "Enable ItemTracker Font Changes",
                desc = "Enable custom font settings for ItemTracker",
                order = 1,
                get = function()
                    return KOL.db.profile.tweaks.itemTracker.enabled
                end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.enabled = value
                    Tweaks:ApplyItemTrackerFont()
                    KOL:PrintTag("ItemTracker font changes " .. (value and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
                end,
            },

            zone = {
                type = "group",
                name = "Zone Headers",
                inline = true,
                order = 2,
                args = {
                    font = {
                        type = "select",
                        name = "Font",
                        desc = "Font for zone headers",
                        dialogControl = "LSM30_Font",
                        values = LSM:HashTable("font"),
                        order = 1,
                        get = function() return KOL.db.profile.tweaks.itemTracker.zoneFont end,
                        set = function(_, value)
                            KOL.db.profile.tweaks.itemTracker.zoneFont = value
                            Tweaks:ApplyItemTrackerFont()
                        end,
                    },
                    fontSize = {
                        type = "range",
                        name = "Size",
                        min = 6, max = 32, step = 1,
                        order = 2,
                        get = function() return KOL.db.profile.tweaks.itemTracker.zoneFontSize end,
                        set = function(_, value)
                            KOL.db.profile.tweaks.itemTracker.zoneFontSize = value
                            Tweaks:ApplyItemTrackerFont()
                        end,
                    },
                    fontOutline = {
                        type = "select",
                        name = "Outline",
                        values = fontOutlineOptions,
                        order = 3,
                        get = function() return KOL.db.profile.tweaks.itemTracker.zoneFontOutline end,
                        set = function(_, value)
                            KOL.db.profile.tweaks.itemTracker.zoneFontOutline = value
                            Tweaks:ApplyItemTrackerFont()
                        end,
                    },
                }
            },

            npc = {
                type = "group",
                name = "NPCs/Mobs",
                inline = true,
                order = 3,
                args = {
                    font = {
                        type = "select",
                        name = "Font",
                        dialogControl = "LSM30_Font",
                        values = LSM:HashTable("font"),
                        order = 1,
                        get = function() return KOL.db.profile.tweaks.itemTracker.npcFont end,
                        set = function(_, value)
                            KOL.db.profile.tweaks.itemTracker.npcFont = value
                            Tweaks:ApplyItemTrackerFont()
                        end,
                    },
                    fontSize = {
                        type = "range",
                        name = "Size",
                        min = 6, max = 32, step = 1,
                        order = 2,
                        get = function() return KOL.db.profile.tweaks.itemTracker.npcFontSize end,
                        set = function(_, value)
                            KOL.db.profile.tweaks.itemTracker.npcFontSize = value
                            Tweaks:ApplyItemTrackerFont()
                        end,
                    },
                    fontOutline = {
                        type = "select",
                        name = "Outline",
                        values = fontOutlineOptions,
                        order = 3,
                        get = function() return KOL.db.profile.tweaks.itemTracker.npcFontOutline end,
                        set = function(_, value)
                            KOL.db.profile.tweaks.itemTracker.npcFontOutline = value
                            Tweaks:ApplyItemTrackerFont()
                        end,
                    },
                }
            },

            item = {
                type = "group",
                name = "Items/Loot",
                inline = true,
                order = 4,
                args = {
                    font = {
                        type = "select",
                        name = "Font",
                        dialogControl = "LSM30_Font",
                        values = LSM:HashTable("font"),
                        order = 1,
                        get = function() return KOL.db.profile.tweaks.itemTracker.itemFont end,
                        set = function(_, value)
                            KOL.db.profile.tweaks.itemTracker.itemFont = value
                            Tweaks:ApplyItemTrackerFont()
                        end,
                    },
                    fontSize = {
                        type = "range",
                        name = "Size",
                        min = 6, max = 32, step = 1,
                        order = 2,
                        get = function() return KOL.db.profile.tweaks.itemTracker.itemFontSize end,
                        set = function(_, value)
                            KOL.db.profile.tweaks.itemTracker.itemFontSize = value
                            Tweaks:ApplyItemTrackerFont()
                        end,
                    },
                    fontOutline = {
                        type = "select",
                        name = "Outline",
                        values = fontOutlineOptions,
                        order = 3,
                        get = function() return KOL.db.profile.tweaks.itemTracker.itemFontOutline end,
                        set = function(_, value)
                            KOL.db.profile.tweaks.itemTracker.itemFontOutline = value
                            Tweaks:ApplyItemTrackerFont()
                        end,
                    },
                }
            },

            limit = {
                type = "group",
                name = "Limit Indicators",
                inline = true,
                order = 5,
                args = {
                    font = {
                        type = "select",
                        name = "Font",
                        dialogControl = "LSM30_Font",
                        values = LSM:HashTable("font"),
                        order = 1,
                        get = function() return KOL.db.profile.tweaks.itemTracker.limitFont end,
                        set = function(_, value)
                            KOL.db.profile.tweaks.itemTracker.limitFont = value
                            Tweaks:ApplyItemTrackerFont()
                        end,
                    },
                    fontSize = {
                        type = "range",
                        name = "Size",
                        min = 6, max = 32, step = 1,
                        order = 2,
                        get = function() return KOL.db.profile.tweaks.itemTracker.limitFontSize end,
                        set = function(_, value)
                            KOL.db.profile.tweaks.itemTracker.limitFontSize = value
                            Tweaks:ApplyItemTrackerFont()
                        end,
                    },
                    fontOutline = {
                        type = "select",
                        name = "Outline",
                        values = fontOutlineOptions,
                        order = 3,
                        get = function() return KOL.db.profile.tweaks.itemTracker.limitFontOutline end,
                        set = function(_, value)
                            KOL.db.profile.tweaks.itemTracker.limitFontOutline = value
                            Tweaks:ApplyItemTrackerFont()
                        end,
                    },
                }
            },

            scrollbarHeader = {
                type = "header",
                name = "ItemTracker Scrollbar Skinning",
                order = 6,
            },

            scrollbarEnabled = {
                type = "toggle",
                name = "Enable Scrollbar Skinning",
                desc = "Skin the ItemHuntFrame scrollbar to match KoL's dark theme",
                get = function() return KOL.db.profile.tweaks.itemTracker.scrollbarEnabled end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.scrollbarEnabled = value
                    if value then
                        Tweaks:ApplyItemTrackerScrollbar()
                        KOL:PrintTag("ItemTracker scrollbar skinning |cFF00FF00enabled|r")
                    else
                        KOL:PrintTag("ItemTracker scrollbar skinning |cFFFF0000disabled|r |cFFFFAAAA(requires /reload)|r")
                    end
                end,
                width = "full",
                order = 7,
            },

            scrollbarHidden = {
                type = "toggle",
                name = "Hide Scrollbar",
                desc = "Completely hide the ItemHuntFrame scrollbar (you can still scroll with mouse wheel)",
                get = function() return KOL.db.profile.tweaks.itemTracker.scrollbarHidden end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.scrollbarHidden = value
                    Tweaks:ApplyItemTrackerScrollbar()
                    if value then
                        KOL:PrintTag("ItemTracker scrollbar |cFFFF8800hidden|r")
                    else
                        KOL:PrintTag("ItemTracker scrollbar |cFF00FF00visible|r")
                    end
                end,
                width = "full",
                order = 8,
            },

            scrollbarWidth = {
                type = "range",
                name = "Scrollbar Width",
                desc = "Width of the scrollbar track and buttons (8-32 pixels)",
                min = 8,
                max = 32,
                step = 1,
                get = function() return KOL.db.profile.tweaks.itemTracker.scrollbarWidth or 16 end,
                set = function(_, value)
                    KOL.db.profile.tweaks.itemTracker.scrollbarWidth = value
                    Tweaks:ResetItemTrackerScrollbar()
                end,
                hidden = function()
                    return not KOL.db.profile.tweaks.itemTracker.scrollbarEnabled or
                           KOL.db.profile.tweaks.itemTracker.scrollbarHidden
                end,
                width = "full",
                order = 9,
            },

            scrollbarColors = {
                type = "group",
                name = "Scrollbar Colors",
                inline = true,
                order = 10,
                hidden = function() return not KOL.db.profile.tweaks.itemTracker.scrollbarEnabled end,
                args = {
                    trackBg = {
                        type = "color",
                        name = "Track Background",
                        hasAlpha = true,
                        order = 1,
                        width = 0.8,
                        get = function()
                            local c = KOL.db.profile.tweaks.itemTracker.scrollbarTrackBg
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            KOL.db.profile.tweaks.itemTracker.scrollbarTrackBg = {r=r, g=g, b=b, a=a}
                            Tweaks:ResetItemTrackerScrollbar()
                        end,
                    },
                    trackBorder = {
                        type = "color",
                        name = "Track Border",
                        hasAlpha = true,
                        order = 2,
                        width = 0.8,
                        get = function()
                            local c = KOL.db.profile.tweaks.itemTracker.scrollbarTrackBorder
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            KOL.db.profile.tweaks.itemTracker.scrollbarTrackBorder = {r=r, g=g, b=b, a=a}
                            Tweaks:ResetItemTrackerScrollbar()
                        end,
                    },
                    thumbBg = {
                        type = "color",
                        name = "Thumb Background",
                        hasAlpha = true,
                        order = 3,
                        width = 0.8,
                        get = function()
                            local c = KOL.db.profile.tweaks.itemTracker.scrollbarThumbBg
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            KOL.db.profile.tweaks.itemTracker.scrollbarThumbBg = {r=r, g=g, b=b, a=a}
                            Tweaks:ResetItemTrackerScrollbar()
                        end,
                    },
                    thumbBorder = {
                        type = "color",
                        name = "Thumb Border",
                        hasAlpha = true,
                        order = 4,
                        width = 0.8,
                        get = function()
                            local c = KOL.db.profile.tweaks.itemTracker.scrollbarThumbBorder
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            KOL.db.profile.tweaks.itemTracker.scrollbarThumbBorder = {r=r, g=g, b=b, a=a}
                            Tweaks:ResetItemTrackerScrollbar()
                        end,
                    },
                    buttonBg = {
                        type = "color",
                        name = "Button Background",
                        hasAlpha = true,
                        order = 5,
                        width = 0.8,
                        get = function()
                            local c = KOL.db.profile.tweaks.itemTracker.scrollbarButtonBg
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            KOL.db.profile.tweaks.itemTracker.scrollbarButtonBg = {r=r, g=g, b=b, a=a}
                            Tweaks:ResetItemTrackerScrollbar()
                        end,
                    },
                    buttonBorder = {
                        type = "color",
                        name = "Button Border",
                        hasAlpha = true,
                        order = 6,
                        width = 0.8,
                        get = function()
                            local c = KOL.db.profile.tweaks.itemTracker.scrollbarButtonBorder
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            KOL.db.profile.tweaks.itemTracker.scrollbarButtonBorder = {r=r, g=g, b=b, a=a}
                            Tweaks:ResetItemTrackerScrollbar()
                        end,
                    },
                    buttonArrow = {
                        type = "color",
                        name = "Button Arrow",
                        hasAlpha = true,
                        order = 7,
                        width = 0.8,
                        get = function()
                            local c = KOL.db.profile.tweaks.itemTracker.scrollbarButtonArrow
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            KOL.db.profile.tweaks.itemTracker.scrollbarButtonArrow = {r=r, g=g, b=b, a=a}
                            Tweaks:ResetItemTrackerScrollbar()
                        end,
                    },
                },
            },
        },
    }

    KOL:DebugPrint("Tweaks: Config UI setup complete", 3)
end

local originalMerchantFrame_OnClick

function Tweaks:SetupVendorTweaks()
    if not KOL.db.profile.tweaks.vendor.buyStack then
        return
    end

    if not originalMerchantFrame_OnClick then
        originalMerchantFrame_OnClick = MerchantItemButton_OnModifiedClick

        MerchantItemButton_OnModifiedClick = function(self, button)
            if IsShiftKeyDown() and KOL.db.profile.tweaks.vendor.buyStack then
                local itemLink = GetMerchantItemLink(self:GetID())
                if itemLink then
                    Tweaks:ShowBuyStackDialog(self:GetID())
                    return
                end
            end

            if originalMerchantFrame_OnClick then
                originalMerchantFrame_OnClick(self, button)
            end
        end

        KOL:DebugPrint("Tweaks: Vendor buy stack hook installed", 3)
    end
end

function Tweaks:ShowBuyStackDialog(merchantSlot)
    local name, texture, price, quantity, numAvailable, isUsable = GetMerchantItemInfo(merchantSlot)
    if not name then return end

    local itemLink = GetMerchantItemLink(merchantSlot)

    local _, _, _, _, _, _, _, maxStack = GetItemInfo(itemLink)

    -- If maxStack is nil, the item isn't cached - use quantity from merchant as fallback
    if not maxStack or maxStack <= 0 then
        maxStack = quantity or 20
    end

    local stackSize = maxStack
    if numAvailable and numAvailable >= 0 then
        stackSize = math.min(maxStack, numAvailable)
    end

    local totalPrice = price * stackSize

    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetSize(280, 110)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetFrameLevel(200)

    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    popup:SetBackdropColor(0.05, 0.05, 0.05, 0.98)
    popup:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local icon = popup:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("TOPLEFT", popup, "TOPLEFT", 8, -8)
    icon:SetTexture(texture)

    local fontPath2, fontSize2, fontOutline2 = GetAveragedFont(10)
    local itemName = popup:CreateFontString(nil, "OVERLAY")
    itemName:SetFont(fontPath2, fontSize2, fontOutline2)
    itemName:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    itemName:SetPoint("RIGHT", popup, "RIGHT", -8, 0)
    itemName:SetText(name)
    itemName:SetTextColor(1, 1, 1, 1)
    itemName:SetJustifyH("LEFT")
    itemName:SetWordWrap(false)

    local fontPath3, fontSize3, fontOutline3 = GetAveragedFont(9)
    local stackInfo = popup:CreateFontString(nil, "OVERLAY")
    stackInfo:SetFont(fontPath3, fontSize3, fontOutline3)
    stackInfo:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -6)
    stackInfo:SetText(string.format("Stack Size: |cFFFFFFFF%d|r", stackSize))
    stackInfo:SetTextColor(0.7, 1, 0.7, 1)

    local priceInfo = popup:CreateFontString(nil, "OVERLAY")
    priceInfo:SetFont(fontPath3, fontSize3, fontOutline3)
    priceInfo:SetPoint("TOP", stackInfo, "BOTTOM", 0, -4)
    priceInfo:SetPoint("LEFT", stackInfo, "LEFT", 0, 0)

    local gold = math.floor(totalPrice / 10000)
    local silver = math.floor((totalPrice % 10000) / 100)
    local copper = totalPrice % 100

    local priceStr = ""
    if gold > 0 then priceStr = priceStr .. gold .. "|cFFFFD700g|r " end
    if silver > 0 or gold > 0 then priceStr = priceStr .. silver .. "|cFFC0C0C0s|r " end
    priceStr = priceStr .. copper .. "|cFFCD7F32c|r"

    priceInfo:SetText("Total Cost: " .. priceStr)
    priceInfo:SetTextColor(1, 1, 0.7, 1)

    local buyBtn = CreateFrame("Button", nil, popup)
    buyBtn:SetSize(110, 26)
    buyBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 10, 10)
    buyBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    buyBtn:SetBackdropColor(0.2, 0.4, 0.2, 1)
    buyBtn:SetBackdropBorderColor(0.1, 0.25, 0.1, 1)

    local buyText = buyBtn:CreateFontString(nil, "OVERLAY")
    buyText:SetFont(fontPath2, fontSize2, fontOutline2)
    buyText:SetPoint("CENTER")
    buyText:SetText("BUY STACK")
    buyText:SetTextColor(0.9, 0.9, 0.9, 1)

    buyBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.5, 0.25, 1)
        self:SetBackdropBorderColor(0.15, 0.35, 0.15, 1)
    end)
    buyBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.2, 0.4, 0.2, 1)
        self:SetBackdropBorderColor(0.1, 0.25, 0.1, 1)
    end)
    buyBtn:SetScript("OnClick", function()
        BuyMerchantItem(merchantSlot, stackSize)
        popup:Hide()
        KOL:PrintTag("Purchased |cFFFFFFFF" .. stackSize .. "x|r " .. itemLink)
    end)

    local cancelBtn = CreateFrame("Button", nil, popup)
    cancelBtn:SetSize(110, 26)
    cancelBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 10)
    cancelBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    cancelBtn:SetBackdropColor(0.4, 0.2, 0.2, 1)
    cancelBtn:SetBackdropBorderColor(0.25, 0.1, 0.1, 1)

    local cancelText = cancelBtn:CreateFontString(nil, "OVERLAY")
    cancelText:SetFont(fontPath2, fontSize2, fontOutline2)
    cancelText:SetPoint("CENTER")
    cancelText:SetText("Cancel")
    cancelText:SetTextColor(0.9, 0.9, 0.9, 1)

    cancelBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.5, 0.25, 0.25, 1)
        self:SetBackdropBorderColor(0.35, 0.15, 0.15, 1)
    end)
    cancelBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.4, 0.2, 0.2, 1)
        self:SetBackdropBorderColor(0.25, 0.1, 0.1, 1)
    end)
    cancelBtn:SetScript("OnClick", function()
        popup:Hide()
    end)

    popup:Show()
end

KOL:RegisterEventCallback("PLAYER_ENTERING_WORLD", function()
    Tweaks:SetupVendorTweaks()
end, "Tweaks")

function Tweaks:RefreshHooks()
    Tweaks:SetupVendorTweaks()
end

KOL:RegisterEventCallback("ZONE_CHANGED", function()
    Tweaks:ResetItemHuntTracking()
end, "Tweaks_ItemTracker")

KOL:RegisterEventCallback("ZONE_CHANGED_NEW_AREA", function()
    Tweaks:ResetItemHuntTracking()
end, "Tweaks_ItemTracker")

KOL:RegisterEventCallback("ZONE_CHANGED_INDOORS", function()
    Tweaks:ResetItemHuntTracking()
end, "Tweaks_ItemTracker")

KOL:DebugPrint("Tweaks module loaded", 1)
