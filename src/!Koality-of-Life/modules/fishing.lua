-- !Koality-of-Life: Fishing Module
-- Auto-use Phantom Ghostfish and cancel Invisibility buff

local addonName = "!Koality-of-Life"
local KOL = KoalityOfLife

-- Create module
local Fishing = {}
KOL.fishing = Fishing

-- Module settings
local GHOSTFISH_ID = 45902
local GHOSTFISH_NAME = "Phantom Ghostfish"
local INVISIBILITY_BUFF = "Invisibility"
local CANCEL_DELAY = 1.0  -- Wait 1 second after using fish before canceling buff

-- Kalu'ak Fishing Derby - Blacktip Shark
local BLACKTIP_SHARK_ID = 50289
local BLACKTIP_SHARK_NAME = "Blacktip Shark"

-- State tracking
local fishUsedTime = 0
local waitingToCancel = false

-- Module defaults
local moduleDefaults = {
    enabled = true,
    autoUse = true,
    autoCancel = true,
}

-- ============================================================================
-- Startup Cleanup & Safety
-- ============================================================================

function Fishing:CleanupOrphanedKeybinds()
    -- CRITICAL: Check if any keys are still bound to our secure button from a previous session
    -- This can happen if user does /reload or WoW crashes while hijack is active
    local timestamp = date("%H:%M:%S")
    local foundOrphans = false

    -- Check all possible keys that might be bound to our button
    local keysToCheck = {
        "B",           -- Default bag toggle
        "SHIFT-B",     -- Common alternate
        "F8",          -- Another common bag key
        "F9",
        "F10",
        "F11",
        "F12",
    }

    -- Also check whatever is currently bound to bag toggle actions
    local key1, key2 = GetBindingKey("TOGGLEBACKPACK")
    if key1 then table.insert(keysToCheck, key1) end
    if key2 then table.insert(keysToCheck, key2) end

    key1, key2 = GetBindingKey("OPENALLBAGS")
    if key1 then table.insert(keysToCheck, key1) end
    if key2 then table.insert(keysToCheck, key2) end

    -- Scan for orphaned bindings
    for _, key in ipairs(keysToCheck) do
        local action = GetBindingAction(key)
        if action and action == "CLICK KOL_GhostfishButton:LeftButton" then
            -- FOUND ORPHANED BINDING!
            foundOrphans = true
            KOL:DebugPrint("[" .. timestamp .. "] " .. RED("ORPHANED KEYBIND DETECTED: [" .. key .. "] -> KOL_GhostfishButton"))
            KOL:DebugPrint("[" .. timestamp .. "] Clearing orphaned binding...")

            -- Clear the binding
            SetBinding(key)

            -- Try to restore to default bag action
            if key == "B" or key:find("B") then
                SetBinding(key, "TOGGLEBACKPACK")
                KOL:DebugPrint("[" .. timestamp .. "] Restored [" .. key .. "] -> TOGGLEBACKPACK")
            end
        end
    end
end

-- ============================================================================
-- Module Initialization
-- ============================================================================

function Fishing:Initialize()
    KOL:DebugPrint("Fishing: Initialize() called!", 2)
    
    -- CRITICAL STARTUP SAFETY: Check for orphaned keybinds from /reload or crash
    self:CleanupOrphanedKeybinds()

    -- Register module defaults
    if not KOL.db.profile.fishing then
        KOL.db.profile.fishing = {}
    end

    -- Apply defaults
    for key, value in pairs(moduleDefaults) do
        if KOL.db.profile.fishing[key] == nil then
            KOL.db.profile.fishing[key] = value
        end
    end

    -- Initialize config UI
    self:InitializeConfig()

    -- Create Notify batch channel for efficient notification detection
    KOL:BatchConfigure("Notify", {
        interval = 0.5,       -- Run every 0.5 seconds when queue has items
        processMode = "limit", -- Consume queue (remove tasks after processing)
        triggerMode = "interval",
        maxQueueSize = 20,    -- Prevent runaway growth
    })
    KOL:DebugPrint("Fishing: Created 'Notify' batch channel (0.5s interval, limit mode)", 1)

    KOL:DebugPrint("Fishing: Module initialized - enabled: " .. tostring(KOL.db.profile.fishing.enabled))
end

-- ============================================================================
-- Phantom Ghostfish Detection & Usage
-- ============================================================================

function Fishing:CheckForGhostfish()
    -- Don't use in combat (protected)
    if InCombatLockdown() then
        return
    end

    -- Only check in Sholazar Basin (zone ID: 3711, or check by name)
    local zoneName = GetZoneText()
    if zoneName ~= "Sholazar Basin" then
        return
    end

    -- Only check if we have the quest active (quest ID: 13830)
    -- Check if quest is in log
    local hasQuest = false
    for i = 1, GetNumQuestLogEntries() do
        local questID = select(8, GetQuestLogTitle(i))
        if questID == 13830 then
            hasQuest = true
            break
        end
    end

    if not hasQuest then
        return
    end

    KOL:DebugPrint("Fishing: Checking for Ghostfish (in Sholazar + quest active)...")

    -- Find Ghostfish location for using it
    local found, bag, slot = KOL:FindItemLocation(GHOSTFISH_ID)
    if found then
        KOL:DebugPrint("Fishing: GHOSTFISH DETECTED in bag " .. bag .. " slot " .. slot .. " - activating!", 1)
        self:UseGhostfish()
        return
    end

    KOL:DebugPrint("Fishing: No Ghostfish found in inventory")
end

-- ============================================================================
-- Kalu'ak Fishing Derby - Blacktip Shark Detection
-- ============================================================================

-- Track if we've already notified about this shark to avoid spam
local blacktipNotified = false
local lastBlacktipCheck = 0

function Fishing:CheckForBlacktipShark()
    -- Throttle checks to once per second to avoid spam
    local now = GetTime()
    if now - lastBlacktipCheck < 1.0 then
        return
    end
    lastBlacktipCheck = now

    -- Don't check if we already notified (until it's gone)
    if blacktipNotified then
        -- Check if shark is still in bags using utility function
        local stillHave = KOL:ScanInventory(BLACKTIP_SHARK_ID)

        -- If we don't have it anymore, reset notification state
        if not stillHave then
            blacktipNotified = false
            KOL:NotifyRemove("BLACKTIP-ALERT")
            KOL:DebugPrint("Fishing: Blacktip Shark removed from bags, reset notification", 3)
        end
        return
    end

    -- Scan bags for Blacktip Shark using utility function
    local found = KOL:ScanInventory(BLACKTIP_SHARK_ID)
    if found then
        -- Found it! Show notification
        blacktipNotified = true

        -- Show notification with looping sound for 30 seconds with flashing
        KOL:Notify("BLACKTIP-ALERT", "TEXT", "-34,310", "30s", "FLASH",
            "\\CBLACKTIP SHARK CAUGHT!!!\\nKALU'AK FISHING DERBY - Turn in at Dalaran Fountain NOW!!!",
            "Expressway", "THICK", nil, "RaidWarning:LOOP:6S")

        KOL:DebugPrint("Fishing: BLACKTIP SHARK DETECTED - Notification shown!", 1)
        KOL:PrintTag(GREEN("BLACKTIP SHARK CAUGHT!") .. " Turn in at Dalaran Fountain!")
    end
end

-- ============================================================================
-- Unified Notification Check (Batch Queue Task)
-- ============================================================================

-- This function is queued to the Notify batch channel on BAG_UPDATE
-- It runs both Ghostfish and Blacktip checks in a single task
function Fishing:CheckAllNotifications()
    -- Check for Phantom Ghostfish (auto-use)
    if not hijackActive then
        self:CheckForGhostfish()
    end

    -- Check for Blacktip Shark (notification)
    self:CheckForBlacktipShark()

    KOL:DebugPrint("Fishing: Notification checks completed", 5)
end

-- Keybind hijack state
local hijackedKeys = {}
local originalBindings = {}
local hijackActive = false
local secureButton = nil

-- Keys to hijack (most commonly pressed)
local KEYS_TO_HIJACK = {
    "W",           -- Move forward
    "A",           -- Strafe left  
    "S",           -- Move backward
    "D",           -- Strafe right
    "SPACE",       -- Jump
    "BUTTON1",     -- Left mouse
    "BUTTON2",     -- Right mouse
    "Q",           -- Common bind
    "E",           -- Common bind
    "1",           -- Action bar 1
    "2",           -- Action bar 2
    "3",           -- Action bar 3
    "4",           -- Action bar 4
    "5",           -- Action bar 5
}

function Fishing:HijackAllKeys()
    if InCombatLockdown() then
        KOL:DebugPrint("Cannot hijack keybinds during combat!")
        return false
    end
    
    KOL:DebugPrint("Hijacking ALL common keys...")
    
    -- Create secure button if needed
    if not secureButton then
        secureButton = CreateFrame("Button", "KOL_GhostfishButton", UIParent, "SecureActionButtonTemplate")
        secureButton:SetAttribute("type", "item")
        secureButton:SetAttribute("item", GHOSTFISH_NAME)
        secureButton:Hide()
        secureButton:SetSize(1, 1)
        secureButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -100, -100)
        secureButton:SetAlpha(0)
    end
    
    -- Hijack each key
    local successCount = 0
    for _, key in ipairs(KEYS_TO_HIJACK) do
        -- Save original binding
        local originalBinding = GetBindingAction(key)
        originalBindings[key] = originalBinding
        
        -- Bind to our secure button
        local success = SetBindingClick(key, "KOL_GhostfishButton", "LeftButton")
        
        if success then
            table.insert(hijackedKeys, key)
            successCount = successCount + 1
            KOL:DebugPrint("Hijacked: " .. key .. " (was: " .. tostring(originalBinding or "none") .. ")")
        else
            KOL:DebugPrint("Failed to hijack: " .. key)
        end
    end
    
    if successCount > 0 then
        hijackActive = true
        KOL:DebugPrint(GREEN("Hijacked " .. successCount .. " keys successfully!"))
        KOL:PrintTag(YELLOW(">>> Press ANY key/mouse to use Ghostfish! <<<"))
        
        -- Safety timeout - restore after 30 seconds
        C_Timer.After(30.0, function()
            if hijackActive then
                Fishing:RestoreAllKeybinds()
                KOL:DebugPrint("Hijack timed out after 30s - restored all keybinds")
                KOL:PrintTag(RED("Ghostfish auto-use expired (30s timeout)"))
            end
        end)
        
        return true
    else
        KOL:DebugPrint(RED("Failed to hijack any keybinds!"))
        return false
    end
end

function Fishing:RestoreAllKeybinds()
    if not hijackActive then
        return
    end
    
    KOL:DebugPrint("Restoring all original keybinds...")
    
    local restoredCount = 0
    for _, key in ipairs(hijackedKeys) do
        local originalBinding = originalBindings[key]
        
        if originalBinding and originalBinding ~= "" then
            SetBinding(key, originalBinding)
            KOL:DebugPrint("Restored: " .. key .. " -> " .. originalBinding)
        else
            -- Clear the binding (no original)
            SetBinding(key)
            KOL:DebugPrint("Cleared: " .. key)
        end
        
        restoredCount = restoredCount + 1
    end
    
    -- Clean up
    hijackActive = false
    hijackedKeys = {}
    originalBindings = {}
    
    -- Destroy secure button
    if secureButton then
        secureButton:SetAttribute("type", nil)
        secureButton:SetAttribute("item", nil)
        secureButton = nil
    end
    
    KOL:DebugPrint(GREEN("Restored " .. restoredCount .. " keybinds!"))
    KOL:PrintTag(GREEN("Controls restored to normal"))
end

-- Bag toggle hijack state (separate from multi-key hijack above)
local bagsWereOpen = false
local originalBagBinding = nil
local bagToggleKey = nil

function Fishing:AreBagsOpen()
    -- Check if any bag frames are showing
    for i = 0, NUM_BAG_FRAMES do
        local frameName = "ContainerFrame" .. (i + 1)
        local frame = _G[frameName]
        if frame and frame:IsShown() then
            return true
        end
    end
    return false
end

function Fishing:GetBagToggleBinding()
    -- Try TOGGLEBACKPACK first (most common)
    local key1, key2 = GetBindingKey("TOGGLEBACKPACK")
    if key1 then
        KOL:DebugPrint("Found TOGGLEBACKPACK binding: " .. key1)
        return key1, "TOGGLEBACKPACK"
    end
    
    -- Try OPENALLBAGS second
    key1, key2 = GetBindingKey("OPENALLBAGS")
    if key1 then
        KOL:DebugPrint("Found OPENALLBAGS binding: " .. key1)
        return key1, "OPENALLBAGS"
    end
    
    -- Fallback to B key with TOGGLEBACKPACK
    KOL:DebugPrint("No bag binding found, defaulting to B -> TOGGLEBACKPACK")
    return "B", "TOGGLEBACKPACK"
end

function Fishing:HijackBagToggle()
    local timestamp = date("%H:%M:%S")

    if InCombatLockdown() then
        KOL:DebugPrint("[" .. timestamp .. "] Cannot hijack keybinds during combat!")
        return false
    end

    KOL:DebugPrint("[" .. timestamp .. "] === STARTING BAG TOGGLE HIJACK ===")

    -- Get current bag toggle binding
    KOL:DebugPrint("[" .. timestamp .. "] Getting bag toggle binding...")
    local key, action = self:GetBagToggleBinding()
    bagToggleKey = key
    originalBagBinding = action

    KOL:DebugPrint("[" .. timestamp .. "] Current bag toggle key: [" .. key .. "]")
    KOL:DebugPrint("[" .. timestamp .. "] Current bag toggle action: " .. action)
    KOL:DebugPrint("[" .. timestamp .. "] Original binding saved: " .. tostring(originalBagBinding))

    -- Remember if bags are currently open
    bagsWereOpen = self:AreBagsOpen()
    KOL:DebugPrint("[" .. timestamp .. "] Bags currently: " .. (bagsWereOpen and "OPEN" or "CLOSED"))

    -- Find the fish in bags FIRST (we need bag/slot for secure button)
    local found, foundBag, foundSlot = KOL:FindItemLocation(GHOSTFISH_ID)

    if not found then
        KOL:DebugPrint("[" .. timestamp .. "] ERROR: Cannot find Ghostfish in bags!")
        return false
    end

    KOL:DebugPrint("[" .. timestamp .. "] Found Ghostfish at: Bag " .. foundBag .. " Slot " .. foundSlot)
    
    -- Create secure button (VISIBLE FOR DEBUGGING)
    KOL:DebugPrint("[" .. timestamp .. "] Creating secure button...")
    if not secureButton then
        secureButton = CreateFrame("Button", "KOL_GhostfishButton", UIParent, "SecureActionButtonTemplate")

        -- CRITICAL: Use bag/slot method instead of item name (more reliable in 3.3.5a)
        secureButton:SetAttribute("type", "item")
        secureButton:SetAttribute("bag", foundBag)
        secureButton:SetAttribute("slot", foundSlot)

        -- MAKE IT VISIBLE FOR DEBUGGING
        secureButton:SetSize(200, 80)
        secureButton:SetPoint("CENTER", UIParent, "CENTER", 0, 200)

        -- Add background
        local bg = secureButton:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(0, 0, 0, 0.8)  -- Black background
        secureButton.bg = bg

        -- Add border
        local border = secureButton:CreateTexture(nil, "BORDER")
        border:SetAllPoints()
        border:SetTexture(1, 1, 0, 1)  -- Yellow border
        border:SetPoint("TOPLEFT", 2, -2)
        border:SetPoint("BOTTOMRIGHT", -2, 2)

        -- Add text showing the button exists
        local text = secureButton:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", 16, "THICKOUTLINE")
        text:SetPoint("CENTER")
        text:SetTextColor(0, 1, 0, 1)  -- Green
        text:SetText("SECURE BUTTON\n(Click to use fish)")
        secureButton.text = text

        -- Add keybind text
        local bindText = secureButton:CreateFontString(nil, "OVERLAY")
        bindText:SetFont("Fonts\\FRIZQT__.TTF", 12, "THICKOUTLINE")
        bindText:SetPoint("TOP", text, "BOTTOM", 0, -5)
        bindText:SetTextColor(1, 1, 0, 1)  -- Yellow
        bindText:SetText("No keybind")
        secureButton.bindText = bindText

        -- DEBUGGING: Add PreClick handler to log when button is clicked
        secureButton:SetScript("PreClick", function(self, button, down)
            local ts = date("%H:%M:%S")
            KOL:DebugPrint("[" .. ts .. "] " .. GREEN(">>> SECURE BUTTON CLICKED! <<<"))
            KOL:DebugPrint("[" .. ts .. "] Button: " .. tostring(button) .. ", Down: " .. tostring(down))
        end)

        -- Enable the button
        secureButton:Enable()
        secureButton:RegisterForClicks("AnyUp", "AnyDown")

        secureButton:Show()
        KOL:DebugPrint("[" .. timestamp .. "] Secure button created: KOL_GhostfishButton (VISIBLE)")
    else
        -- Update attributes for existing button
        secureButton:SetAttribute("bag", foundBag)
        secureButton:SetAttribute("slot", foundSlot)
        secureButton:Enable()
        secureButton:Show()
        KOL:DebugPrint("[" .. timestamp .. "] Secure button already exists, updated attributes")
    end

    -- Verify button attributes
    local buttonType = secureButton:GetAttribute("type")
    local buttonBag = secureButton:GetAttribute("bag")
    local buttonSlot = secureButton:GetAttribute("slot")
    KOL:DebugPrint("[" .. timestamp .. "] Button type attribute: " .. tostring(buttonType))
    KOL:DebugPrint("[" .. timestamp .. "] Button bag attribute: " .. tostring(buttonBag))
    KOL:DebugPrint("[" .. timestamp .. "] Button slot attribute: " .. tostring(buttonSlot))
    KOL:DebugPrint("[" .. timestamp .. "] Button enabled: " .. tostring(secureButton:IsEnabled()))
    KOL:DebugPrint("[" .. timestamp .. "] Button visible: " .. tostring(secureButton:IsVisible()))
    
    -- Hijack the bag toggle key (FAIL-SAFE: Wrapped in pcall)
    KOL:DebugPrint("[" .. timestamp .. "] " .. YELLOW(">>> ATTEMPTING TO HIJACK KEYBIND NOW <<<"))
    KOL:DebugPrint("[" .. timestamp .. "] Command: SetBindingClick('" .. bagToggleKey .. "', 'KOL_GhostfishButton', 'LeftButton')")
    KOL:DebugPrint("[" .. timestamp .. "] Executing SetBindingClick...")

    local success, result = pcall(function()
        return SetBindingClick(bagToggleKey, "KOL_GhostfishButton", "LeftButton")
    end)

    KOL:DebugPrint("[" .. timestamp .. "] SetBindingClick completed!")
    KOL:DebugPrint("[" .. timestamp .. "] pcall success: " .. tostring(success))
    KOL:DebugPrint("[" .. timestamp .. "] SetBindingClick returned: " .. tostring(result))

    if success and result then
        -- Verify the binding was set
        local newBinding = GetBindingAction(bagToggleKey)
        KOL:DebugPrint("[" .. timestamp .. "] Binding verification: [" .. bagToggleKey .. "] now points to: " .. tostring(newBinding))

        hijackActive = true
        KOL:DebugPrint("[" .. timestamp .. "] " .. GREEN("=== BAG TOGGLE HIJACKED SUCCESSFULLY ==="))
        KOL:DebugPrint("[" .. timestamp .. "] WAS: [" .. bagToggleKey .. "] -> " .. originalBagBinding)
        KOL:DebugPrint("[" .. timestamp .. "] NOW: [" .. bagToggleKey .. "] -> CLICK(KOL_GhostfishButton)")

        -- Update button text to show keybind
        if secureButton and secureButton.bindText then
            secureButton.bindText:SetText("HIJACKED: [" .. bagToggleKey .. "]")
            secureButton.bindText:SetTextColor(0, 1, 0, 1)  -- Green = active
        end

        -- Show notification using new Notify system (with looping sound for infinite duration)
        KOL:Notify("GHOSTFISH-ALERT", "TEXT", "0,-150", "INF", "FLASH",
            "\\CPHANTOM GHOSTFISH CAUGHT!!!\\nURGENT Hit [" .. bagToggleKey .. "] to Open Bags and Automatically Use [Phantom Ghostfish] / Remove Buff!!!",
            "Expressway", "THICK", nil, "RaidWarning:LOOP:6S")

        -- FAIL-SAFE: Multiple safety timeouts
        -- Backup timeout #1: 5 seconds (in case BAG_UPDATE doesn't fire)
        C_Timer.After(5.0, function()
            if hijackActive then
                local ts = date("%H:%M:%S")
                KOL:DebugPrint("[" .. ts .. "] WARNING: Hijack still active after 5s - user may not have pressed key")
            end
        end)

        -- Backup timeout #2: 10 seconds (forcefully restore if still active)
        C_Timer.After(10.0, function()
            if hijackActive then
                local ts = date("%H:%M:%S")
                KOL:DebugPrint("[" .. ts .. "] FORCE RESTORE: 10s timeout reached!")
                Fishing:RestoreBagToggle()
                KOL:PrintTag(ORANGE("Ghostfish auto-use expired (10s timeout - bags will open)"))
            end
        end)

        -- Final safety timeout: 30 seconds (absolute maximum)
        C_Timer.After(30.0, function()
            if hijackActive then
                local ts = date("%H:%M:%S")
                KOL:DebugPrint("[" .. ts .. "] CRITICAL: 30s timeout - force restoring!")
                Fishing:RestoreBagToggle()
                KOL:PrintTag(RED("Ghostfish auto-use expired (30s CRITICAL timeout)"))
            end
        end)

        return true
    else
        KOL:DebugPrint("[" .. timestamp .. "] " .. RED("=== HIJACK FAILED ==="))
        KOL:DebugPrint("[" .. timestamp .. "] SetBindingClick returned: " .. tostring(result))
        if not success then
            KOL:DebugPrint("[" .. timestamp .. "] Error: " .. tostring(result))
        end
        return false
    end
end

function Fishing:RestoreBagToggle()
    local timestamp = date("%H:%M:%S")

    -- CRITICAL: Always try to restore, even if hijackActive is false (safety!)
    if not hijackActive then
        KOL:DebugPrint("[" .. timestamp .. "] RestoreBagToggle called but hijackActive=false (already restored or never hijacked)")
        return
    end

    KOL:DebugPrint("[" .. timestamp .. "] " .. YELLOW("=== RESTORING BAG TOGGLE BINDING ==="))

    -- FAIL-SAFE: Wrap in pcall to ensure cleanup happens even if there's an error
    local success, err = pcall(function()
        -- Restore original binding FIRST
        if bagToggleKey and originalBagBinding then
            local restoreSuccess = SetBinding(bagToggleKey, originalBagBinding)
            KOL:DebugPrint("[" .. timestamp .. "] SetBinding(" .. bagToggleKey .. ", " .. originalBagBinding .. ") returned: " .. tostring(restoreSuccess))

            -- Verify restoration
            local currentBinding = GetBindingAction(bagToggleKey)
            KOL:DebugPrint("[" .. timestamp .. "] Verification: [" .. bagToggleKey .. "] now points to: " .. tostring(currentBinding))
        elseif bagToggleKey then
            -- Clear binding if no original (edge case)
            SetBinding(bagToggleKey)
            KOL:DebugPrint("[" .. timestamp .. "] Cleared binding for: " .. bagToggleKey)
        end

        -- CRITICAL: ALWAYS open bags if they were closed (user expected B to toggle them)
        -- This ensures user sees bags regardless of whether secure button worked or timed out
        if not bagsWereOpen then
            KOL:DebugPrint("[" .. timestamp .. "] Opening bags (they were closed before - user expects to see them)...")
            C_Timer.After(0.15, function()
                if not InCombatLockdown() then
                    KOL:DebugPrint("[" .. timestamp .. "] Executing OpenAllBags()...")
                    OpenAllBags()
                    KOL:DebugPrint("[" .. timestamp .. "] Bags opened!")
                else
                    KOL:DebugPrint("[" .. timestamp .. "] Cannot open bags - in combat!")
                end
            end)
        else
            KOL:DebugPrint("[" .. timestamp .. "] Bags were already open - leaving them open")
        end
    end)

    if not success then
        KOL:DebugPrint("[" .. timestamp .. "] " .. RED("ERROR in RestoreBagToggle: " .. tostring(err)))
        KOL:PrintTag(RED("Error restoring keybind! Check /kol debug output!"))
    end

    -- ALWAYS clean up state (even if error occurred above)
    hijackActive = false
    bagToggleKey = nil
    originalBagBinding = nil
    bagsWereOpen = false

    -- Hide notification (ALWAYS)
    pcall(function()
        KOL:NotifyRemove("GHOSTFISH-ALERT")
    end)

    -- Reset button text and hide (ALWAYS)
    pcall(function()
        if secureButton then
            if secureButton.bindText then
                secureButton.bindText:SetText("No keybind")
                secureButton.bindText:SetTextColor(1, 0, 0, 1)  -- Red = inactive
            end
            secureButton:Hide()
            secureButton:SetAttribute("type", nil)
            secureButton:SetAttribute("item", nil)
            secureButton = nil
        end
    end)

    KOL:DebugPrint("[" .. timestamp .. "] " .. GREEN("=== BAG TOGGLE FULLY RESTORED ==="))
    KOL:PrintTag(GREEN("Controls restored to normal"))
end

function Fishing:UseGhostfish()
    KOL:PrintTag("|cFF00FF00FISHING:|r UseGhostfish() called!")
    KOL:DebugPrint("Found " .. YELLOW(GHOSTFISH_NAME) .. " in bags!")

    -- Find the fish location for using it
    local found, foundBag, foundSlot = KOL:FindItemLocation(GHOSTFISH_ID)

    if not found then
        KOL:DebugPrint("ERROR: Ghostfish not found in bags!")
        return
    end

    KOL:DebugPrint("Found in bag " .. foundBag .. " slot " .. foundSlot)
    
    -- Get bag toggle binding for messages
    local key = self:GetBagToggleBinding()

    -- Debug message only
    KOL:DebugPrint("Phantom Ghostfish Caught! Press [" .. (key or "B") .. "] for toggling your bags.")

    -- Show notification about Phantom Ghostfish
    KOL:Notify("GHOSTFISH-ALERT", "TEXT", "0,0", "10s", "FLASH",
        "\\CPHANTOM GHOSTFISH CAUGHT!!!\\nURGENT Hit [B] to Open Bags and Automatically Use [Phantom Ghostfish] / Remove Buff!!!",
        "Expressway", "THICK", nil, "RaidWarning:LOOP:6S")

    -- Hijack bag toggle
    local success = self:HijackBagToggle()
    
    if not success then
        -- Fallback to notification
        KOL:PrintTag(RED("Auto-use failed - use fish manually!"))
        KOL:PrintTag("Location: Bag " .. foundBag .. ", Slot " .. foundSlot)
        PlaySound("RaidWarning")
    end
end

-- Force use by container item (for testing)
function Fishing:ForceUseContainerItem()
    KOL:DebugPrint("Force testing UseContainerItem method...")

    if InCombatLockdown() then
        KOL:DebugPrint("ERROR: Cannot use items while in combat!")
        return
    end

    -- Find Ghostfish location for using it
    local found, bag, slot = KOL:FindItemLocation(GHOSTFISH_ID)

    if found then
        KOL:DebugPrint("Found Ghostfish in bag " .. bag .. " slot " .. slot)
        KOL:DebugPrint("Command: UseContainerItem(" .. bag .. ", " .. slot .. ")")
        KOL:DebugPrint("Executing NOW...")
        UseContainerItem(bag, slot)
        KOL:DebugPrint("Command executed!")
        fishUsedTime = GetTime()
        waitingToCancel = true
    else
        KOL:DebugPrint("ERROR: No Ghostfish found in bags!")
    end
end

-- ============================================================================
-- Invisibility Buff Canceling
-- ============================================================================

function Fishing:CheckInvisibility()
    if not waitingToCancel then
        return
    end
    
    if not KOL.db.profile.fishing.enabled or not KOL.db.profile.fishing.autoCancel then
        waitingToCancel = false
        return
    end
    
    -- Check if enough time has passed
    local elapsed = GetTime() - fishUsedTime
    if elapsed < CANCEL_DELAY then
        return  -- Not yet
    end
    
    -- Check if we have the Invisibility buff
    local buffIndex = self:FindInvisibilityBuff()
    if buffIndex then
        -- Cancel it!
        KOL:DebugPrint("Canceling " .. YELLOW(INVISIBILITY_BUFF) .. " buff...")
        CancelUnitBuff("player", buffIndex)
        KOL:DebugPrint(GREEN("Invisibility canceled successfully!"))
        waitingToCancel = false
    else
        -- Buff didn't appear yet, keep waiting (but timeout after 3 seconds)
        if elapsed > 3.0 then
            KOL:DebugPrint("Timeout waiting for Invisibility buff")
            waitingToCancel = false
        end
    end
end

function Fishing:FindInvisibilityBuff()
    -- Scan player buffs for Invisibility
    local i = 1
    while true do
        local name, _, _, _, _, _, _, _, _, _, buffID = UnitBuff("player", i)
        if not name then
            break  -- No more buffs
        end
        
        -- Check by name or ID
        if name == INVISIBILITY_BUFF or buffID == 32612 then
            return i  -- Found it!
        end
        
        i = i + 1
    end
    
    return nil  -- Not found
end

-- ============================================================================
-- Event Handlers
-- ============================================================================

function Fishing:OnBagUpdate()
    -- FAIL-SAFE: Wrap in pcall to prevent errors from breaking the addon
    local success, err = pcall(function()
        -- If bag toggle is hijacked, check if fish was used
        if hijackActive then
            -- Check if fish is gone from bags using utility function
            local fishFound = KOL:ScanInventory(GHOSTFISH_ID)

            -- Fish is gone! It was used!
            if not fishFound then
                local ts = date("%H:%M:%S")
                KOL:DebugPrint("[" .. ts .. "] " .. GREEN("Ghostfish was used! Restoring bag toggle..."))
                self:RestoreBagToggle()  -- Will auto-open bags if they were closed
                fishUsedTime = GetTime()
                waitingToCancel = true
            end
        else
            -- Normal mode: Queue notification checks to run via Notify batch channel
            -- This prevents BAG_UPDATE spam from running checks every frame
            KOL:BatchAdd("Notify", "Notifications", function()
                Fishing:CheckAllNotifications()
            end, 3)  -- Priority 3 = NORMAL

            -- Start the batch channel if not already running
            KOL:BatchStart("Notify")
        end
    end)

    if not success then
        local ts = date("%H:%M:%S")
        KOL:DebugPrint("[" .. ts .. "] ERROR in OnBagUpdate: " .. tostring(err))
        -- CRITICAL: If error and hijack is active, restore keybind!
        if hijackActive then
            KOL:DebugPrint("[" .. ts .. "] EMERGENCY RESTORE due to error!")
            self:RestoreBagToggle()
        end
    end
end

function Fishing:OnUpdate()
    -- Continuously check if it's time to cancel Invisibility
    self:CheckInvisibility()
    
    -- Also check for Ghostfish when not in combat and not hijacked
    -- This ensures detection works even if BAG_UPDATE is delayed
    if not InCombatLockdown() and not hijackActive then
        local zoneName = GetZoneText()
        if zoneName == "Sholazar Basin" then
            -- Check if we have the quest active (quest ID: 13830)
            local hasQuest = false
            for i =1, GetNumQuestLogEntries() do
                local questID = select(8, GetQuestLogTitle(i))
                if questID == 13830 then
                    hasQuest = true
                    break
                end
            end
            
            if hasQuest then
                -- Check for Ghostfish (throttled to avoid spam)
                local now = GetTime()
                if not self.lastGhostfishCheck or now - self.lastGhostfishCheck > 2.0 then
                    self.lastGhostfishCheck = now
                    self:CheckForGhostfish()
                end
            end
        end
    end
end

-- ============================================================================
-- Configuration UI
-- ============================================================================

function Fishing:InitializeConfig()
    -- Safety check: ensure configOptions and tweaks tab exist
    if not KOL.configOptions or not KOL.configOptions.args or not KOL.configOptions.args.tweaks then
        KOL:DebugPrint("Fishing: Config not ready yet, deferring InitializeConfig", 2)
        return
    end

    -- Create fishing sub-tab under Tweaks
    if not KOL.configOptions.args.tweaks.args.fishing then
        KOL.configOptions.args.tweaks.args.fishing = {
            type = "group",
            name = "Fishing",
            order = 4,
            args = {}
        }
    end
    -- Store reference for UIAdd functions
    KOL.configGroups.fishing = KOL.configOptions.args.tweaks.args.fishing

    -- Title
    KOL:UIAddConfigTitle("fishing", "header", "Phantom Ghostfish Auto-Use", 1)

    -- Description
    KOL:UIAddConfigDescription("fishing", "desc", "Automatically uses Phantom Ghostfish and cancels Invisibility buff after 1 second.", 2)

    -- Enable module
    KOL:UIAddConfigToggle("fishing", "enabled", {
        name = "Enable Fishing Module",
        desc = "Enable automatic Phantom Ghostfish handling",
        order = 10,
    })

    -- Auto-use toggle
    KOL:UIAddConfigToggle("fishing", "autoUse", {
        name = "Auto-Use Ghostfish",
        desc = "Automatically use Phantom Ghostfish when found in bags",
        order = 11,
    })

    -- Auto-cancel toggle
    KOL:UIAddConfigToggle("fishing", "autoCancel", {
        name = "Auto-Cancel Invisibility",
        desc = "Automatically cancel Invisibility buff 1 second after using Ghostfish",
        order = 12,
    })

    -- Spacer
    KOL:UIAddConfigSpacer("fishing", "spacer1", 15)

    -- Test button
    KOL:UIAddConfigExecute("fishing", "test", {
        name = "Test: Check for Ghostfish",
        desc = "Manually check bags for Phantom Ghostfish",
        func = function()
            Fishing:CheckForGhostfish()
        end,
        order = 20,
    })
end

-- ============================================================================
-- Event Registration & Frame
-- ============================================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Entering combat

-- OnUpdate for continuous checking
frame:SetScript("OnUpdate", function(self, elapsed)
    Fishing:OnUpdate()
end)

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" and KOL.db then
        Fishing:Initialize()
    elseif event == "BAG_UPDATE" then
        Fishing:OnBagUpdate()
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entered combat - FAIL-SAFE: Restore keybind immediately!
        if hijackActive then
            local ts = date("%H:%M:%S")
            KOL:DebugPrint("[" .. ts .. "] COMBAT DETECTED - force restoring keybind!")
            Fishing:RestoreBagToggle()
            KOL:PrintTag(ORANGE("Combat started - keybind restored (can't use items in combat)"))
        end
    end
end)

-- ============================================================================
-- Module Complete
-- ============================================================================

-- Module loaded (don't call DebugPrint here - db not initialized yet)
KOL:DebugPrint("Fishing: Module file loaded successfully!", 2)

