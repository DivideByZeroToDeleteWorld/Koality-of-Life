-- !Koality-of-Life: Splash Screen

local addonName = "!Koality-of-Life"
local KOL = KoalityOfLife
local SPLASH_DURATION = 2

local function CreateSplashFrame()
    local logoWidth = 512
    local logoHeight = 256
    local versionHeight = 20

    local frameWidth = logoWidth
    local frameHeight = logoHeight + versionHeight

    local splash = CreateFrame("Frame", "KOL_SplashFrame", UIParent)
    splash:SetSize(frameWidth, frameHeight)
    splash:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    splash:SetFrameStrata("FULLSCREEN_DIALOG")
    splash:SetFrameLevel(1000)
    splash:Hide()

    local logo = splash:CreateTexture(nil, "ARTWORK")
    logo:SetPoint("TOP", splash, "TOP", 0, 0)
    logo:SetSize(logoWidth, logoHeight)

    local texturePath = "Interface\\AddOns\\!Koality-of-Life\\media\\images\\kol-splash.tga"
    logo:SetTexture(texturePath)

    if KOL and KOL.DebugPrint then
        KOL:DebugPrint("Splash: Frame " .. frameWidth .. "x" .. frameHeight)
        KOL:DebugPrint("Splash: Loading: " .. texturePath)
        if logo:GetTexture() then
            KOL:DebugPrint("Splash: Texture loaded (power-of-2)!")
        else
            KOL:DebugPrint("Splash: ERROR - Texture failed to load!")
        end
    end

    local versionBg = splash:CreateTexture(nil, "BACKGROUND")
    versionBg:SetPoint("BOTTOM", splash, "BOTTOM", 0, 0)
    versionBg:SetSize(logoWidth, versionHeight)
    versionBg:SetTexture(0, 0, 0, 0.9)

    local version = splash:CreateFontString(nil, "OVERLAY")
    version:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    version:SetPoint("BOTTOM", splash, "BOTTOM", 0, 4)
    version:SetTextColor(0.9, 0.9, 0.9, 1)

    if KOL then
        if KOL.DebugPrint then
            KOL:DebugPrint("Splash: KOL.version = " .. tostring(KOL.version))
        end
        version:SetText("v" .. KOL.version)
    else
        local addonVersion = GetAddOnMetadata("!Koality-of-Life", "Version") or "Unknown"
        version:SetText("v" .. addonVersion)
    end

    local fadeOut = splash:CreateAnimationGroup()
    local alpha = fadeOut:CreateAnimation("Alpha")
    alpha:SetChange(-1)
    alpha:SetDuration(0.5)

    fadeOut:SetScript("OnFinished", function()
        splash:Hide()
    end)

    splash.fadeOut = fadeOut

    return splash
end

local function ShowSplash()
    if KOL and KOL.DebugPrint then
        KOL:DebugPrint("Splash: ShowSplash() called")
    end

    local splash = CreateSplashFrame()

    if KOL and KOL.DebugPrint then
        if splash then
            KOL:DebugPrint("Splash: Frame created successfully, showing now...")
        else
            KOL:DebugPrint("Splash: ERROR - Frame creation failed!")
            return
        end
    end

    splash:Show()

    C_Timer.After(SPLASH_DURATION - 0.5, function()
        if splash and splash:IsShown() then
            if KOL and KOL.DebugPrint then
                KOL:DebugPrint("Splash: Starting fade out...")
            end
            splash.fadeOut:Play()
        end
    end)

    C_Timer.After(SPLASH_DURATION, function()
        if splash and splash:IsShown() then
            if KOL and KOL.DebugPrint then
                KOL:DebugPrint("Splash: Hiding splash")
            end
            splash:Hide()
        end
    end)
end

local splashShown = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if KOL and KOL.RegisterSlashCommand then
            KOL:RegisterSlashCommand("splash", ShowSplash, "Show the splash screen")
            if KOL.DebugPrint then
                KOL:DebugPrint("Splash: Registered /kol splash command")
            end
        end

        if not splashShown then
            splashShown = true
            C_Timer.After(0.5, function()
                local showSplash = true
                if KOL and KOL.db and KOL.db.profile then
                    showSplash = KOL.db.profile.showSplash
                    if showSplash == nil then showSplash = true end
                end

                if showSplash then
                    ShowSplash()
                end
            end)
        end
    end
end)
