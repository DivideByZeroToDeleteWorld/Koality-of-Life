-- !Koality-of-Life: Tests Module
-- Consolidated testing functionality for all modules

local addonName = "!Koality-of-Life"
local KOL = KoalityOfLife
local LSM = LibStub("LibSharedMedia-3.0")

-- Create module
local Tests = {}
KOL.tests = Tests

-- Debug helper (safe to call before KOL is fully initialized)
local function TestsDebug(msg, level)
    level = level or 3
    if KOL and KOL.DebugPrint then
        KOL:DebugPrint("[Tests] " .. msg, level)
    end
end

TestsDebug("tests.lua loading...", 5)
TestsDebug("KOL exists: " .. tostring(KOL ~= nil), 5)
TestsDebug("LSM loaded: " .. tostring(LSM ~= nil), 5)

-- ============================================================================
-- Notify Module Tests
-- ============================================================================

function Tests:TestNotify()
    KOL:PrintTag("Testing KOL:Notify system...")
    local success, err = pcall(function()
        KOL:Notify("TEST-NOTIFICATION", "TEXT", "0,0", "5s", "FLASH", "\\CTest Notification\\n\\LThis is a test!", "Expressway", "THICK", nil, "RaidWarning")
    end)
    if success then
        KOL:PrintTag(GREEN("Test notification created! Should appear at screen center."))
    else
        KOL:PrintTag(RED("ERROR: ") .. tostring(err))
    end
end

function Tests:TestGhostfish()
    KOL:PrintTag("Testing Ghostfish notification with looping sound...")
    local success, err = pcall(function()
        KOL:Notify("GHOSTFISH-ALERT", "TEXT", "-34,310", "10s", "FLASH",
            "\\CPHANTOM GHOSTFISH CAUGHT!!!\\nURGENT Hit [B] to Open Bags and Automatically Use [Phantom Ghostfish] / Remove Buff!!!",
            "Expressway", "THICK", nil, "RaidWarning:LOOP:6S")
    end)
    if success then
        KOL:PrintTag(GREEN("Ghostfish notification created! Sound will loop every 6s for 10s."))
    else
        KOL:PrintTag(RED("ERROR: ") .. tostring(err))
    end
end

function Tests:TestBlacktip()
    KOL:PrintTag("Testing Blacktip Shark notification with looping sound...")
    local success, err = pcall(function()
        KOL:Notify("BLACKTIP-ALERT", "TEXT", "-34,310", "30s", "FLASH",
            "\\CBLACKTIP SHARK CAUGHT!!!\\nKALU'AK FISHING DERBY - Turn in at Dalaran Fountain NOW!!!",
            "Expressway", "THICK", nil, "RaidWarning:LOOP:6S")
    end)
    if success then
        KOL:PrintTag(GREEN("Blacktip Shark notification created! Sound will loop every 6s for 30s."))
    else
        KOL:PrintTag(RED("ERROR: ") .. tostring(err))
    end
end

function Tests:TestSound()
    KOL:PrintTag("Testing sound notification with looping...")
    local success, err = pcall(function()
        KOL:Notify("TEST-SOUND-LOOP", "TEXT", "0,100", "10s", "FLASH",
            "\\CLooping Sound Test\\n\\LSound will loop every 3 seconds for 10 seconds",
            "Expressway", "THICK", nil, "RaidWarning:LOOP")
    end)
    if success then
        KOL:PrintTag(GREEN("Looping sound test created! Listen for RaidWarning every 3s."))
    else
        KOL:PrintTag(RED("ERROR: ") .. tostring(err))
    end
end

function Tests:TestJustify()
    KOL:PrintTag("Testing justification and newlines...")
    local success, err = pcall(function()
        -- Get Notify module
        local Notify = KOL.notify

        -- Create notification with forced 800px width
        local name = "TEST-JUSTIFY"
        local lines = Notify:ParseContent("\\LLEFT\\n\\CCENTER\\n\\RRIGHT")
        local styleData = Notify:ParseStyle("BORDER-FULL-2PX")

        -- Create frame manually with fixed 800px width
        local frame = CreateFrame("Frame", name, UIParent)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame:SetFrameStrata("HIGH")
        frame:SetSize(800, 100)  -- FORCE 800px width

        local fontPath, outlineFlag = Notify:GetFont("Expressway", "THICK")

        -- Create text elements
        local textElements = {}
        for i, lineData in ipairs(lines) do
            local text = frame:CreateFontString(nil, "OVERLAY")
            text:SetFont(fontPath, 24, outlineFlag)
            text:SetTextColor(1, 1, 0, 1)
            text:SetText(lineData.text)
            text:SetWidth(800)  -- Match frame width

            if lineData.justify == "CENTER" then
                text:SetJustifyH("CENTER")
            elseif lineData.justify == "RIGHT" then
                text:SetJustifyH("RIGHT")
            else
                text:SetJustifyH("LEFT")
            end

            if i == 1 then
                text:SetPoint("TOP", frame, "TOP", 0, 0)
            else
                text:SetPoint("TOP", textElements[i-1], "BOTTOM", 0, -5)
            end

            table.insert(textElements, text)
        end

        -- Add border
        Notify:AddBorder(frame, styleData)

        frame:Show()

        -- Store notification (access activeNotifications via a temporary local reference)
        local activeNotifications = {}
        activeNotifications[name] = {
            frame = frame,
            createdAt = GetTime(),
            duration = 10,
        }

        C_Timer.After(10, function()
            Notify:RemoveNotification(name)
        end)
    end)
    if success then
        KOL:PrintTag(GREEN("Justification test created! 800px wide frame."))
    else
        KOL:PrintTag(RED("ERROR: ") .. tostring(err))
    end
end

function Tests:TestDungeon(testType)
    testType = testType or "faster"
    KOL:PrintTag("Testing dungeon challenge notification (" .. testType .. ")...")

    if testType == "faster" then
        -- Simulate faster time by printing to chat and scanning
        DEFAULT_CHAT_FRAME:AddMessage("You completed this dungeon challenge in 04:54!")
        DEFAULT_CHAT_FRAME:AddMessage("Your previous best time was 08:55")
        C_Timer.After(0.1, function()
            if KOL.notify and KOL.notify.ScanChatForDungeonCompletion then
                KOL.notify:ScanChatForDungeonCompletion()
            end
        end)
    elseif testType == "slower" then
        -- Simulate slower time by printing to chat and scanning
        DEFAULT_CHAT_FRAME:AddMessage("You completed this dungeon challenge in 09:30!")
        DEFAULT_CHAT_FRAME:AddMessage("Your previous best time was 08:55")
        C_Timer.After(0.1, function()
            if KOL.notify and KOL.notify.ScanChatForDungeonCompletion then
                KOL.notify:ScanChatForDungeonCompletion()
            end
        end)
    else
        KOL:PrintTag(RED("Usage: /kol testdungeon [faster|slower]"))
    end
end

-- ============================================================================
-- Fishing Module Tests
-- ============================================================================

function Tests:CheckFish()
    if KOL.fishing and KOL.fishing.CheckForGhostfish then
        KOL.fishing:CheckForGhostfish()
    else
        KOL:PrintTag(RED("Error:") .. " Fishing module not loaded")
    end
end

function Tests:UseFish()
    if KOL.fishing and KOL.fishing.ForceUseContainerItem then
        KOL.fishing:ForceUseContainerItem()
    else
        KOL:PrintTag(RED("Error:") .. " Fishing module not loaded")
    end
end

function Tests:TestHijack()
    KOL:DebugPrint("=== MANUAL HIJACK TEST ===")
    if KOL.fishing and KOL.fishing.HijackBagToggle then
        local success = KOL.fishing:HijackBagToggle()
        if success then
            KOL:PrintTag(GREEN("Hijack test: SUCCESS! Press your bag key now!"))
        else
            KOL:PrintTag(RED("Hijack test: FAILED! Check debug output."))
        end
    else
        KOL:PrintTag(RED("Error:") .. " Fishing module not loaded")
    end
end

function Tests:ClickButton()
    if KOL.fishing then
        local secureButton = _G["KOL_GhostfishButton"]
        if secureButton then
            KOL:DebugPrint("=== MANUAL BUTTON CLICK TEST ===")
            KOL:DebugPrint("Attempting to click secure button directly...")
            secureButton:Click("LeftButton")
            KOL:DebugPrint("Click command sent!")
        else
            KOL:PrintTag(RED("No secure button exists! Run /kol testhijack first."))
        end
    else
        KOL:PrintTag(RED("Error:") .. " Fishing module not loaded")
    end
end

-- ============================================================================
-- Changes Module Tests (ItemTracker/pfQuest)
-- ============================================================================

function Tests:InspectFrame(frameName)
    if not frameName or frameName == "" then
        KOL:PrintTag(RED("ERROR:") .. " Please provide a frame name!")
        KOL:PrintTag("Usage: " .. YELLOW("/kt inspectframe FrameName"))
        return
    end

    local frame = _G[frameName]
    if not frame then
        KOL:PrintTag(RED("ERROR:") .. " Frame '" .. frameName .. "' not found!")
        return
    end

    KOL:PrintTag(GREEN("Inspecting " .. frameName .. ":"))

    -- Get frame type
    local frameType = frame:GetObjectType()
    KOL:Print("  Frame Type: " .. YELLOW(frameType))

    -- Get all regions (including FontStrings)
    local regionCount = (frame.GetNumRegions and frame:GetNumRegions()) or 0
    KOL:Print("  Total Regions: " .. YELLOW(regionCount))

    if regionCount > 0 then
        KOL:Print(" ")
        KOL:Print(CYAN("FontStrings found:"))

        local fontStringCount = 0
        for i = 1, regionCount do
            local region = select(i, frame:GetRegions())
            if region and region:GetObjectType() == "FontString" then
                fontStringCount = fontStringCount + 1
                local name = region:GetName() or "unnamed"
                local font, size, flags = region:GetFont()
                KOL:Print("  [" .. fontStringCount .. "] " .. YELLOW(name) .. " - Font: " .. (font or "nil") .. ", Size: " .. (size or "nil") .. ", Flags: " .. (flags or "nil"))
            end
        end

        if fontStringCount == 0 then
            KOL:Print(RED("  No FontStrings found in regions!"))
        end
    end

    -- Check for common child properties
    KOL:Print(" ")
    KOL:Print(CYAN("Checking common properties:"))

    local commonProps = {"text", "label", "title", "Text", "Label", "Title"}
    for _, prop in ipairs(commonProps) do
        if frame[prop] then
            KOL:Print("  Found " .. YELLOW(frameName .. "." .. prop))
            if frame[prop].GetObjectType then
                KOL:Print("    Type: " .. frame[prop]:GetObjectType())
            end
        end
    end

    -- Check for children frames
    local children = {frame:GetChildren()}
    if #children > 0 then
        KOL:Print(" ")
        KOL:Print(CYAN("Children frames:"))
        for i, child in ipairs(children) do
            local childName = child:GetName() or "unnamed"
            local childType = child:GetObjectType()
            KOL:Print("  [" .. i .. "] " .. YELLOW(childName) .. " (" .. childType .. ")")

            -- Check if child has regions with FontStrings
            local childRegionCount = (child.GetNumRegions and child:GetNumRegions()) or 0
            if childRegionCount > 0 then
                local childFontStrings = 0
                for j = 1, childRegionCount do
                    local region = select(j, child:GetRegions())
                    if region and region:GetObjectType() == "FontString" then
                        childFontStrings = childFontStrings + 1
                    end
                end
                if childFontStrings > 0 then
                    KOL:Print("      → " .. GREEN(childFontStrings .. " FontString(s) found"))
                end
            end

            -- Check common properties on child
            local childProps = {"text", "label", "title", "Text", "Label", "Title"}
            for _, prop in ipairs(childProps) do
                if child[prop] and child[prop].GetObjectType then
                    if child[prop]:GetObjectType() == "FontString" then
                        local font, size, flags = child[prop]:GetFont()
                        KOL:Print("      → " .. YELLOW(prop) .. ": FontString - " .. (font or "nil") .. ", " .. (size or "nil"))
                    end
                end
            end

            -- For ScrollFrames, check ScrollChild
            if childType == "ScrollFrame" and child.GetScrollChild then
                local scrollChild = child:GetScrollChild()
                if scrollChild then
                    local scrollChildName = scrollChild:GetName() or "unnamed"
                    KOL:Print("      → ScrollChild: " .. YELLOW(scrollChildName))

                    -- Check FontStrings in ScrollChild
                    local scrollRegions = (scrollChild.GetNumRegions and scrollChild:GetNumRegions()) or 0
                    if scrollRegions > 0 then
                        local scrollFontStrings = 0
                        for j = 1, scrollRegions do
                            local region = select(j, scrollChild:GetRegions())
                            if region and region:GetObjectType() == "FontString" then
                                scrollFontStrings = scrollFontStrings + 1
                            end
                        end
                        if scrollFontStrings > 0 then
                            KOL:Print("         → " .. GREEN(scrollFontStrings .. " FontString(s) in ScrollChild"))
                        end
                    end
                end
            end
        end
    end
end

function Tests:InspectPfQuest()
    Tests:InspectFrame("pfQuestMapTracker")
end

function Tests:TestFont()
    if self.testFrame then
        if self.testFrame:IsShown() then
            self.testFrame:Hide()
            KOL:PrintTag("Test frame " .. RED("hidden"))
        else
            self.testFrame:Show()
            KOL:PrintTag("Test frame " .. GREEN("shown"))
        end
        return
    end

    -- Create a draggable test frame
    local frame = CreateFrame("Frame", "KOL_FontTest", UIParent)
    frame:SetSize(300, 100)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", 0, -15)
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    title:SetText(self:RainbowText("Font Test Frame"))

    -- Sample text
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", 0, 0)
    text:SetText("Sample Item Text")

    -- Apply current font settings from Changes module
    if KOL.db and KOL.db.profile and KOL.db.profile.changes and KOL.db.profile.changes.itemTracker then
        local settings = KOL.db.profile.changes.itemTracker
        local fontPath = LSM:Fetch("font", settings.font)
        if fontPath then
            text:SetFont(fontPath, settings.fontSize, settings.fontOutline)
        end
    end

    -- Close button
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function()
        Tests:DestroyTestFrame()
    end)

    frame.text = text
    self.testFrame = frame

    KOL:PrintTag("Test frame created! " .. YELLOW("Drag to move, click X to close"))
end

function Tests:DestroyTestFrame()
    if self.testFrame then
        KOL:DebugPrint("Destroying font test frame...")
        self.testFrame:Hide()
        self.testFrame = nil
        KOL:PrintTag("Test frame " .. RED("destroyed"))
    end
end

-- Helper function to create rainbow text
function Tests:RainbowText(text)
    local rainbowColors = {
        "FF0000", "FF4400", "FF8800", "FFCC00", "FFFF00", "CCFF00",
        "88FF00", "44FF00", "00FF00", "00FF88", "00FFFF", "55AAFF",
        "7799FF", "8888FF", "AA66FF"
    }

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
-- Module Initialization
-- ============================================================================

function Tests:RegisterCommands()
    TestsDebug("RegisterCommands() called", 3)

    -- Register all test slash commands with "test" category
    if not KOL or not KOL.RegisterSlashCommand then
        -- Core not ready yet, try again in 0.5 seconds
        TestsDebug("Core not ready, retrying in 0.5s...", 3)
        C_Timer.After(0.5, function() Tests:RegisterCommands() end)
        return
    end

    TestsDebug("Starting command registration...", 5)

    -- Notify tests
    KOL:RegisterSlashCommand("testnotify", function()
        Tests:TestNotify()
    end, "Test the notification system with a simple notification", "test")

    KOL:RegisterSlashCommand("testghost", function()
        Tests:TestGhostfish()
    end, "Test the Ghostfish notification with looping sound", "test")

    KOL:RegisterSlashCommand("testblacktip", function()
        Tests:TestBlacktip()
    end, "Test the Blacktip Shark notification with looping sound", "test")

    KOL:RegisterSlashCommand("testsound", function()
        Tests:TestSound()
    end, "Test notification with looping sound", "test")

    KOL:RegisterSlashCommand("testjustify", function()
        Tests:TestJustify()
    end, "Test text justification (left/center/right) and newlines", "test")

    KOL:RegisterSlashCommand("testdungeon", function(args)
        Tests:TestDungeon(args)
    end, "Test dungeon challenge notification (use 'faster' or 'slower')", "test")

    -- Fishing tests
    KOL:RegisterSlashCommand("checkfish", function()
        Tests:CheckFish()
    end, "Manually check for Phantom Ghostfish", "test")

    KOL:RegisterSlashCommand("usefish", function()
        Tests:UseFish()
    end, "Force use Ghostfish by container (for testing)", "test")

    KOL:RegisterSlashCommand("testhijack", function()
        Tests:TestHijack()
    end, "Test bag toggle hijacking manually", "test")

    KOL:RegisterSlashCommand("clickbutton", function()
        Tests:ClickButton()
    end, "Test clicking the secure button directly", "test")

    -- Font/Changes tests
    KOL:RegisterSlashCommand("testfont", function()
        Tests:TestFont()
    end, "Show/hide font test frame", "test")

    KOL:RegisterSlashCommand("inspectpfquest", function()
        Tests:InspectPfQuest()
    end, "Inspect pfQuestMapTracker frame structure", "test")

    KOL:RegisterSlashCommand("inspectframe", function(frameName)
        Tests:InspectFrame(frameName)
    end, "Inspect any frame structure (usage: /kt inspectframe FrameName)", "test")

    KOL:RegisterSlashCommand("testbossrecorder", function()
        Tests:TestBossRecorder()
    end, "Test Boss Recorder functionality", "test")

    KOL:RegisterSlashCommand("testghostfish", function()
        Tests:TestGhostfish()
    end, "Test Ghostfish functionality", "test")

    KOL:DebugPrint("Tests: Module initialized - all test commands registered")
end

-- ============================================================================
-- Boss Recorder Tests
-- ============================================================================

function Tests:TestBossRecorder()
    KOL:PrintTag("Testing Boss Recorder system...")
    
    -- Test if BossRecorder module exists
    if not KOL.BossRecorder then
        KOL:PrintTag(RED("ERROR: BossRecorder module not found"))
        return
    end
    
    -- Simulate a boss kill
    local testBoss = {
        name = "Test Boss",
        guid = "0xF130003E8B0003CD",
        npcId = 15956,
        classification = "|cFFFF0000Boss|r"
    }
    
    KOL:PrintTag("Simulating boss kill: " .. testBoss.name .. " (ID: " .. testBoss.npcId .. ")")
    
    -- Start recording if not already recording
    if not KOL.BossRecorder:IsRecording() then
        KOL.BossRecorder:StartRecording("Test simulation")
    end
    
    -- Record boss kill
    KOL.BossRecorder:OnBossDetected(testBoss.name, testBoss.guid, testBoss.npcId, testBoss.classification)
    
    KOL:PrintTag(GREEN("Boss kill recorded! Use '/kbre' to export recorded sessions."))
end

function Tests:TestGhostfish()
    KOL:PrintTag("Testing Ghostfish detection...")
    
    if not KOL.fishing then
        KOL:PrintTag(RED("ERROR: Fishing module not found"))
        return
    end
    
    -- Force call CheckForGhostfish
    KOL.fishing:CheckForGhostfish()
    
    KOL:PrintTag("Ghostfish test complete - check debug output for results")
end

function Tests:TestBossRecorder()
    KOL:PrintTag("Testing Boss Recorder system...")
    
    -- Test if BossRecorder module exists
    if not KOL.BossRecorder then
        KOL:PrintTag(RED("ERROR: BossRecorder module not found"))
        return
    end
    
    -- Simulate a boss kill
    local testBoss = {
        name = "Test Boss",
        guid = "0xF130003E8B0003CD",
        npcId = 15956,
        classification = "|cFFFF0000Boss|r"
    }
    
    KOL:PrintTag("Simulating boss kill: " .. testBoss.name .. " (ID: " .. testBoss.npcId .. ")")
    
    -- Start recording if not already recording
    if not KOL.BossRecorder:IsRecording() then
        KOL.BossRecorder:StartRecording("Test simulation")
    end
    
    -- Record the boss kill
    KOL.BossRecorder:OnBossDetected(testBoss.name, testBoss.guid, testBoss.npcId, testBoss.classification)
    
    KOL:PrintTag(GREEN("Boss kill recorded! Use '/kbre' to export recorded sessions."))
end

-- ============================================================================
-- Auto-Register Commands
-- ============================================================================

-- Register commands immediately when file loads
TestsDebug("Calling RegisterCommands()...", 3)
Tests:RegisterCommands()
TestsDebug("RegisterCommands() call completed", 3)

-- ============================================================================
-- Module Complete
-- ============================================================================
