-- !Koality-of-Life: Splash Screen
-- Shows addon logo on load

local addonName = "!Koality-of-Life"
local KOL = KoalityOfLife
local SPLASH_DURATION = 2 -- seconds

-- ============================================================================
-- Create Splash Frame
-- ============================================================================

local function CreateSplashFrame()
    -- Logo dimensions: 1024x512 (power of 2 - WoW requirement!)
    -- Display at 50% scale for reasonable size
    local logoWidth = 512   -- 1024 / 2
    local logoHeight = 256  -- 512 / 2
    local versionHeight = 20
    
    local frameWidth = logoWidth
    local frameHeight = logoHeight + versionHeight
    
    -- Transparent frame - just the logo
    local splash = CreateFrame("Frame", "KOL_SplashFrame", UIParent)
    splash:SetSize(frameWidth, frameHeight)  -- 512x276
    splash:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    splash:SetFrameStrata("FULLSCREEN_DIALOG")
    splash:SetFrameLevel(1000)
    splash:Hide()
    
    -- NO backdrop - transparent!
    
    -- Logo texture - power of 2 dimensions
    local logo = splash:CreateTexture(nil, "ARTWORK")
    logo:SetPoint("TOP", splash, "TOP", 0, 0)
    logo:SetSize(logoWidth, logoHeight)  -- 512x256
    
    -- Load power-of-2 texture (WoW requirement!)
    local texturePath = "Interface\\AddOns\\!Koality-of-Life\\media\\images\\kol-splash.tga"
    logo:SetTexture(texturePath)
    
    -- Debug
    if KOL and KOL.DebugPrint then
        KOL:DebugPrint("Splash: Frame " .. frameWidth .. "x" .. frameHeight)
        KOL:DebugPrint("Splash: Loading: " .. texturePath)
        if logo:GetTexture() then
            KOL:DebugPrint("Splash: Texture loaded (power-of-2)!")
        else
            KOL:DebugPrint("Splash: ERROR - Texture failed to load!")
        end
    end
    
    -- Version text with small black background
    local versionBg = splash:CreateTexture(nil, "BACKGROUND")
    versionBg:SetPoint("BOTTOM", splash, "BOTTOM", 0, 0)
    versionBg:SetSize(logoWidth, versionHeight)  -- Match logo width
    versionBg:SetTexture(0, 0, 0, 0.9)  -- Black with 90% opacity (3.3.5a compatible)
    
    local version = splash:CreateFontString(nil, "OVERLAY")
    version:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    version:SetPoint("BOTTOM", splash, "BOTTOM", 0, 4)
    version:SetTextColor(0.9, 0.9, 0.9, 1)
    
    if KOL then
        -- Simple version text
        if KOL.DebugPrint then
            KOL:DebugPrint("Splash: KOL.version = " .. tostring(KOL.version))
        end
        version:SetText("v" .. KOL.version)
    else
        -- Fallback
        local addonVersion = GetAddOnMetadata("!Koality-of-Life", "Version") or "Unknown"
        version:SetText("v" .. addonVersion)
    end
    
    -- Fade out animation (WoW 3.3.5a compatible)
    local fadeOut = splash:CreateAnimationGroup()
    local alpha = fadeOut:CreateAnimation("Alpha")
    alpha:SetChange(-1) -- Fade from 1 to 0
    alpha:SetDuration(0.5) -- Fade out over 0.5 seconds
    
    -- Set script to hide frame when fade completes
    fadeOut:SetScript("OnFinished", function()
        splash:Hide()
    end)
    
    splash.fadeOut = fadeOut
    
    return splash
end

-- ============================================================================
-- Show Splash Screen
-- ============================================================================

local function ShowSplash()
    -- Debug output
    if KOL and KOL.DebugPrint then
        KOL:DebugPrint("Splash: ShowSplash() called")
    end
    
    local splash = CreateSplashFrame()
    
    -- Debug: Check if frame was created
    if KOL and KOL.DebugPrint then
        if splash then
            KOL:DebugPrint("Splash: Frame created successfully, showing now...")
        else
            KOL:DebugPrint("Splash: ERROR - Frame creation failed!")
            return
        end
    end
    
    -- Show the splash
    splash:Show()
    
    -- Start fade out after delay
    C_Timer.After(SPLASH_DURATION - 0.5, function()
        if splash and splash:IsShown() then
            if KOL and KOL.DebugPrint then
                KOL:DebugPrint("Splash: Starting fade out...")
            end
            splash.fadeOut:Play()
        end
    end)
    
    -- Safety: Hide after duration even if animation fails
    C_Timer.After(SPLASH_DURATION, function()
        if splash and splash:IsShown() then
            if KOL and KOL.DebugPrint then
                KOL:DebugPrint("Splash: Hiding splash")
            end
            splash:Hide()
        end
    end)
end

-- ============================================================================
-- Initialize on PLAYER_LOGIN
-- ============================================================================

local splashShown = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Register slash command (always do this)
        if KOL and KOL.RegisterSlashCommand then
            KOL:RegisterSlashCommand("splash", ShowSplash, "Show the splash screen")
            if KOL.DebugPrint then
                KOL:DebugPrint("Splash: Registered /kol splash command")
            end
        end
        
        -- Show splash on first login only
        if not splashShown then
            splashShown = true
            -- Small delay to ensure UI is ready
            C_Timer.After(0.5, function()
                ShowSplash()
            end)
        end
    end
end)
