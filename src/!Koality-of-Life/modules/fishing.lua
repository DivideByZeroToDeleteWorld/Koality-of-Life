local addonName = "!Koality-of-Life"
local KOL = KoalityOfLife

local Fishing = {}
KOL.fishing = Fishing

local GHOSTFISH_ID = 45902
local GHOSTFISH_NAME = "Phantom Ghostfish"
local INVISIBILITY_BUFF = "Invisibility"
local CANCEL_DELAY = 1.0

local BLACKTIP_SHARK_ID = 50289
local BLACKTIP_SHARK_NAME = "Blacktip Shark"

local fishUsedTime = 0
local waitingToCancel = false

local moduleDefaults = {
    enabled = true,
    autoUse = true,
    autoCancel = true,
}

function Fishing:CleanupOrphanedKeybinds()
    -- CRITICAL: Check if any keys are still bound to our secure button from a previous session
    -- This can happen if user does /reload or WoW crashes while hijack is active
    local timestamp = date("%H:%M:%S")
    local foundOrphans = false

    local keysToCheck = {
        "B",
        "SHIFT-B",
        "F8",
        "F9",
        "F10",
        "F11",
        "F12",
    }

    local key1, key2 = GetBindingKey("TOGGLEBACKPACK")
    if key1 then table.insert(keysToCheck, key1) end
    if key2 then table.insert(keysToCheck, key2) end

    key1, key2 = GetBindingKey("OPENALLBAGS")
    if key1 then table.insert(keysToCheck, key1) end
    if key2 then table.insert(keysToCheck, key2) end

    for _, key in ipairs(keysToCheck) do
        local action = GetBindingAction(key)
        if action and action == "CLICK KOL_GhostfishButton:LeftButton" then
            foundOrphans = true
            KOL:DebugPrint("[" .. timestamp .. "] " .. RED("ORPHANED KEYBIND DETECTED: [" .. key .. "] -> KOL_GhostfishButton"))
            KOL:DebugPrint("[" .. timestamp .. "] Clearing orphaned binding...")

            SetBinding(key)

            if key == "B" or key:find("B") then
                SetBinding(key, "TOGGLEBACKPACK")
                KOL:DebugPrint("[" .. timestamp .. "] Restored [" .. key .. "] -> TOGGLEBACKPACK")
            end
        end
    end
end

function Fishing:Initialize()
    KOL:DebugPrint("Fishing: Initialize() called!", 2)

    self:CleanupOrphanedKeybinds()

    if not KOL.db.profile.fishing then
        KOL.db.profile.fishing = {}
    end

    for key, value in pairs(moduleDefaults) do
        if KOL.db.profile.fishing[key] == nil then
            KOL.db.profile.fishing[key] = value
        end
    end

    self:InitializeConfig()

    KOL:BatchConfigure("Notify", {
        interval = 0.5,
        processMode = "limit",
        triggerMode = "interval",
        maxQueueSize = 20,
    })
    KOL:DebugPrint("Fishing: Created 'Notify' batch channel (0.5s interval, limit mode)", 1)

    KOL:DebugPrint("Fishing: Module initialized - enabled: " .. tostring(KOL.db.profile.fishing.enabled))
end

function Fishing:CheckForGhostfish()
    if InCombatLockdown() then
        return
    end

    local zoneName = GetZoneText()
    if zoneName ~= "Sholazar Basin" then
        return
    end

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

    local found, bag, slot = KOL:FindItemLocation(GHOSTFISH_ID)
    if found then
        KOL:DebugPrint("Fishing: GHOSTFISH DETECTED in bag " .. bag .. " slot " .. slot .. " - activating!", 1)
        self:UseGhostfish()
        return
    end

    KOL:DebugPrint("Fishing: No Ghostfish found in inventory")
end

local blacktipNotified = false
local lastBlacktipCheck = 0

function Fishing:CheckForBlacktipShark()
    local now = GetTime()
    if now - lastBlacktipCheck < 1.0 then
        return
    end
    lastBlacktipCheck = now

    if blacktipNotified then
        local stillHave = KOL:ScanInventory(BLACKTIP_SHARK_ID)

        if not stillHave then
            blacktipNotified = false
            KOL:NotifyRemove("BLACKTIP-ALERT")
            KOL:DebugPrint("Fishing: Blacktip Shark removed from bags, reset notification", 3)
        end
        return
    end

    local found = KOL:ScanInventory(BLACKTIP_SHARK_ID)
    if found then
        blacktipNotified = true

        KOL:Notify("BLACKTIP-ALERT", "TEXT", "-34,310", "30s", "FLASH",
            "\\CBLACKTIP SHARK CAUGHT!!!\\nKALU'AK FISHING DERBY - Turn in at Dalaran Fountain NOW!!!",
            "Expressway", "THICK", nil, "RaidWarning:LOOP:6S")

        KOL:DebugPrint("Fishing: BLACKTIP SHARK DETECTED - Notification shown!", 1)
        KOL:PrintTag(GREEN("BLACKTIP SHARK CAUGHT!") .. " Turn in at Dalaran Fountain!")
    end
end

function Fishing:CheckAllNotifications()
    if not hijackActive then
        self:CheckForGhostfish()
    end

    self:CheckForBlacktipShark()

    KOL:DebugPrint("Fishing: Notification checks completed", 5)
end

local hijackedKeys = {}
local originalBindings = {}
local hijackActive = false
local secureButton = nil

local KEYS_TO_HIJACK = {
    "W",
    "A",
    "S",
    "D",
    "SPACE",
    "BUTTON1",
    "BUTTON2",
    "Q",
    "E",
    "1",
    "2",
    "3",
    "4",
    "5",
}

function Fishing:HijackAllKeys()
    if InCombatLockdown() then
        KOL:DebugPrint("Cannot hijack keybinds during combat!")
        return false
    end

    KOL:DebugPrint("Hijacking ALL common keys...")

    if not secureButton then
        secureButton = CreateFrame("Button", "KOL_GhostfishButton", UIParent, "SecureActionButtonTemplate")
        secureButton:SetAttribute("type", "item")
        secureButton:SetAttribute("item", GHOSTFISH_NAME)
        secureButton:Hide()
        secureButton:SetSize(1, 1)
        secureButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -100, -100)
        secureButton:SetAlpha(0)
    end

    local successCount = 0
    for _, key in ipairs(KEYS_TO_HIJACK) do
        local originalBinding = GetBindingAction(key)
        originalBindings[key] = originalBinding

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
            SetBinding(key)
            KOL:DebugPrint("Cleared: " .. key)
        end

        restoredCount = restoredCount + 1
    end

    hijackActive = false
    hijackedKeys = {}
    originalBindings = {}

    if secureButton then
        secureButton:SetAttribute("type", nil)
        secureButton:SetAttribute("item", nil)
        secureButton = nil
    end

    KOL:DebugPrint(GREEN("Restored " .. restoredCount .. " keybinds!"))
    KOL:PrintTag(GREEN("Controls restored to normal"))
end

local bagsWereOpen = false
local originalBagBinding = nil
local bagToggleKey = nil

function Fishing:AreBagsOpen()
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
    local key1, key2 = GetBindingKey("TOGGLEBACKPACK")
    if key1 then
        KOL:DebugPrint("Found TOGGLEBACKPACK binding: " .. key1)
        return key1, "TOGGLEBACKPACK"
    end

    key1, key2 = GetBindingKey("OPENALLBAGS")
    if key1 then
        KOL:DebugPrint("Found OPENALLBAGS binding: " .. key1)
        return key1, "OPENALLBAGS"
    end

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

    KOL:DebugPrint("[" .. timestamp .. "] Getting bag toggle binding...")
    local key, action = self:GetBagToggleBinding()
    bagToggleKey = key
    originalBagBinding = action

    KOL:DebugPrint("[" .. timestamp .. "] Current bag toggle key: [" .. key .. "]")
    KOL:DebugPrint("[" .. timestamp .. "] Current bag toggle action: " .. action)
    KOL:DebugPrint("[" .. timestamp .. "] Original binding saved: " .. tostring(originalBagBinding))

    bagsWereOpen = self:AreBagsOpen()
    KOL:DebugPrint("[" .. timestamp .. "] Bags currently: " .. (bagsWereOpen and "OPEN" or "CLOSED"))

    -- Need bag/slot for secure button - more reliable than item name in 3.3.5a
    local found, foundBag, foundSlot = KOL:FindItemLocation(GHOSTFISH_ID)

    if not found then
        KOL:DebugPrint("[" .. timestamp .. "] ERROR: Cannot find Ghostfish in bags!")
        return false
    end

    KOL:DebugPrint("[" .. timestamp .. "] Found Ghostfish at: Bag " .. foundBag .. " Slot " .. foundSlot)

    KOL:DebugPrint("[" .. timestamp .. "] Creating secure button...")
    if not secureButton then
        secureButton = CreateFrame("Button", "KOL_GhostfishButton", UIParent, "SecureActionButtonTemplate")

        -- Use bag/slot method instead of item name (more reliable in 3.3.5a)
        secureButton:SetAttribute("type", "item")
        secureButton:SetAttribute("bag", foundBag)
        secureButton:SetAttribute("slot", foundSlot)

        secureButton:SetSize(200, 80)
        secureButton:SetPoint("CENTER", UIParent, "CENTER", 0, 200)

        local bg = secureButton:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(0, 0, 0, 0.8)
        secureButton.bg = bg

        local border = secureButton:CreateTexture(nil, "BORDER")
        border:SetAllPoints()
        border:SetTexture(1, 1, 0, 1)
        border:SetPoint("TOPLEFT", 2, -2)
        border:SetPoint("BOTTOMRIGHT", -2, 2)

        local text = secureButton:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", 16, "THICKOUTLINE")
        text:SetPoint("CENTER")
        text:SetTextColor(0, 1, 0, 1)
        text:SetText("SECURE BUTTON\n(Click to use fish)")
        secureButton.text = text

        local bindText = secureButton:CreateFontString(nil, "OVERLAY")
        bindText:SetFont("Fonts\\FRIZQT__.TTF", 12, "THICKOUTLINE")
        bindText:SetPoint("TOP", text, "BOTTOM", 0, -5)
        bindText:SetTextColor(1, 1, 0, 1)
        bindText:SetText("No keybind")
        secureButton.bindText = bindText

        secureButton:SetScript("PreClick", function(self, button, down)
            local ts = date("%H:%M:%S")
            KOL:DebugPrint("[" .. ts .. "] " .. GREEN(">>> SECURE BUTTON CLICKED! <<<"))
            KOL:DebugPrint("[" .. ts .. "] Button: " .. tostring(button) .. ", Down: " .. tostring(down))
        end)

        secureButton:Enable()
        secureButton:RegisterForClicks("AnyUp", "AnyDown")

        secureButton:Show()
        KOL:DebugPrint("[" .. timestamp .. "] Secure button created: KOL_GhostfishButton (VISIBLE)")
    else
        secureButton:SetAttribute("bag", foundBag)
        secureButton:SetAttribute("slot", foundSlot)
        secureButton:Enable()
        secureButton:Show()
        KOL:DebugPrint("[" .. timestamp .. "] Secure button already exists, updated attributes")
    end

    local buttonType = secureButton:GetAttribute("type")
    local buttonBag = secureButton:GetAttribute("bag")
    local buttonSlot = secureButton:GetAttribute("slot")
    KOL:DebugPrint("[" .. timestamp .. "] Button type attribute: " .. tostring(buttonType))
    KOL:DebugPrint("[" .. timestamp .. "] Button bag attribute: " .. tostring(buttonBag))
    KOL:DebugPrint("[" .. timestamp .. "] Button slot attribute: " .. tostring(buttonSlot))
    KOL:DebugPrint("[" .. timestamp .. "] Button enabled: " .. tostring(secureButton:IsEnabled()))
    KOL:DebugPrint("[" .. timestamp .. "] Button visible: " .. tostring(secureButton:IsVisible()))

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
        local newBinding = GetBindingAction(bagToggleKey)
        KOL:DebugPrint("[" .. timestamp .. "] Binding verification: [" .. bagToggleKey .. "] now points to: " .. tostring(newBinding))

        hijackActive = true
        KOL:DebugPrint("[" .. timestamp .. "] " .. GREEN("=== BAG TOGGLE HIJACKED SUCCESSFULLY ==="))
        KOL:DebugPrint("[" .. timestamp .. "] WAS: [" .. bagToggleKey .. "] -> " .. originalBagBinding)
        KOL:DebugPrint("[" .. timestamp .. "] NOW: [" .. bagToggleKey .. "] -> CLICK(KOL_GhostfishButton)")

        if secureButton and secureButton.bindText then
            secureButton.bindText:SetText("HIJACKED: [" .. bagToggleKey .. "]")
            secureButton.bindText:SetTextColor(0, 1, 0, 1)
        end

        KOL:Notify("GHOSTFISH-ALERT", "TEXT", "0,-150", "INF", "FLASH",
            "\\CPHANTOM GHOSTFISH CAUGHT!!!\\nURGENT Hit [" .. bagToggleKey .. "] to Open Bags and Automatically Use [Phantom Ghostfish] / Remove Buff!!!",
            "Expressway", "THICK", nil, "RaidWarning:LOOP:6S")

        C_Timer.After(5.0, function()
            if hijackActive then
                local ts = date("%H:%M:%S")
                KOL:DebugPrint("[" .. ts .. "] WARNING: Hijack still active after 5s - user may not have pressed key")
            end
        end)

        C_Timer.After(10.0, function()
            if hijackActive then
                local ts = date("%H:%M:%S")
                KOL:DebugPrint("[" .. ts .. "] FORCE RESTORE: 10s timeout reached!")
                Fishing:RestoreBagToggle()
                KOL:PrintTag(ORANGE("Ghostfish auto-use expired (10s timeout - bags will open)"))
            end
        end)

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

    if not hijackActive then
        KOL:DebugPrint("[" .. timestamp .. "] RestoreBagToggle called but hijackActive=false (already restored or never hijacked)")
        return
    end

    KOL:DebugPrint("[" .. timestamp .. "] " .. YELLOW("=== RESTORING BAG TOGGLE BINDING ==="))

    local success, err = pcall(function()
        if bagToggleKey and originalBagBinding then
            local restoreSuccess = SetBinding(bagToggleKey, originalBagBinding)
            KOL:DebugPrint("[" .. timestamp .. "] SetBinding(" .. bagToggleKey .. ", " .. originalBagBinding .. ") returned: " .. tostring(restoreSuccess))

            local currentBinding = GetBindingAction(bagToggleKey)
            KOL:DebugPrint("[" .. timestamp .. "] Verification: [" .. bagToggleKey .. "] now points to: " .. tostring(currentBinding))
        elseif bagToggleKey then
            SetBinding(bagToggleKey)
            KOL:DebugPrint("[" .. timestamp .. "] Cleared binding for: " .. bagToggleKey)
        end

        -- Always open bags if they were closed - user expected B to toggle them
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

    -- Always clean up state even if error occurred
    hijackActive = false
    bagToggleKey = nil
    originalBagBinding = nil
    bagsWereOpen = false

    pcall(function()
        KOL:NotifyRemove("GHOSTFISH-ALERT")
    end)

    pcall(function()
        if secureButton then
            if secureButton.bindText then
                secureButton.bindText:SetText("No keybind")
                secureButton.bindText:SetTextColor(1, 0, 0, 1)
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

    local found, foundBag, foundSlot = KOL:FindItemLocation(GHOSTFISH_ID)

    if not found then
        KOL:DebugPrint("ERROR: Ghostfish not found in bags!")
        return
    end

    KOL:DebugPrint("Found in bag " .. foundBag .. " slot " .. foundSlot)

    local key = self:GetBagToggleBinding()

    KOL:DebugPrint("Phantom Ghostfish Caught! Press [" .. (key or "B") .. "] for toggling your bags.")

    KOL:Notify("GHOSTFISH-ALERT", "TEXT", "0,0", "10s", "FLASH",
        "\\CPHANTOM GHOSTFISH CAUGHT!!!\\nURGENT Hit [B] to Open Bags and Automatically Use [Phantom Ghostfish] / Remove Buff!!!",
        "Expressway", "THICK", nil, "RaidWarning:LOOP:6S")

    local success = self:HijackBagToggle()

    if not success then
        KOL:PrintTag(RED("Auto-use failed - use fish manually!"))
        KOL:PrintTag("Location: Bag " .. foundBag .. ", Slot " .. foundSlot)
        PlaySound("RaidWarning")
    end
end

function Fishing:ForceUseContainerItem()
    KOL:DebugPrint("Force testing UseContainerItem method...")

    if InCombatLockdown() then
        KOL:DebugPrint("ERROR: Cannot use items while in combat!")
        return
    end

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

function Fishing:CheckInvisibility()
    if not waitingToCancel then
        return
    end

    if not KOL.db.profile.fishing.enabled or not KOL.db.profile.fishing.autoCancel then
        waitingToCancel = false
        return
    end

    local elapsed = GetTime() - fishUsedTime
    if elapsed < CANCEL_DELAY then
        return
    end

    local buffIndex = self:FindInvisibilityBuff()
    if buffIndex then
        KOL:DebugPrint("Canceling " .. YELLOW(INVISIBILITY_BUFF) .. " buff...")
        CancelUnitBuff("player", buffIndex)
        KOL:DebugPrint(GREEN("Invisibility canceled successfully!"))
        waitingToCancel = false
    else
        -- Buff didn't appear yet, keep waiting but timeout after 3 seconds
        if elapsed > 3.0 then
            KOL:DebugPrint("Timeout waiting for Invisibility buff")
            waitingToCancel = false
        end
    end
end

function Fishing:FindInvisibilityBuff()
    local i = 1
    while true do
        local name, _, _, _, _, _, _, _, _, _, buffID = UnitBuff("player", i)
        if not name then
            break
        end

        if name == INVISIBILITY_BUFF or buffID == 32612 then
            return i
        end

        i = i + 1
    end

    return nil
end

function Fishing:OnBagUpdate()
    local success, err = pcall(function()
        if hijackActive then
            local fishFound = KOL:ScanInventory(GHOSTFISH_ID)

            if not fishFound then
                local ts = date("%H:%M:%S")
                KOL:DebugPrint("[" .. ts .. "] " .. GREEN("Ghostfish was used! Restoring bag toggle..."))
                self:RestoreBagToggle()
                fishUsedTime = GetTime()
                waitingToCancel = true
            end
        else
            KOL:BatchAdd("Notify", "Notifications", function()
                Fishing:CheckAllNotifications()
            end, 3)

            KOL:BatchStart("Notify")
        end
    end)

    if not success then
        local ts = date("%H:%M:%S")
        KOL:DebugPrint("[" .. ts .. "] ERROR in OnBagUpdate: " .. tostring(err))
        -- If error and hijack is active, restore keybind as emergency measure
        if hijackActive then
            KOL:DebugPrint("[" .. ts .. "] EMERGENCY RESTORE due to error!")
            self:RestoreBagToggle()
        end
    end
end

function Fishing:OnUpdate()
    self:CheckInvisibility()

    -- Check for Ghostfish when not in combat and not hijacked
    -- Ensures detection works even if BAG_UPDATE is delayed
    if not InCombatLockdown() and not hijackActive then
        local zoneName = GetZoneText()
        if zoneName == "Sholazar Basin" then
            local hasQuest = false
            for i =1, GetNumQuestLogEntries() do
                local questID = select(8, GetQuestLogTitle(i))
                if questID == 13830 then
                    hasQuest = true
                    break
                end
            end

            if hasQuest then
                local now = GetTime()
                if not self.lastGhostfishCheck or now - self.lastGhostfishCheck > 2.0 then
                    self.lastGhostfishCheck = now
                    self:CheckForGhostfish()
                end
            end
        end
    end
end

function Fishing:InitializeConfig()
    if not KOL.configOptions or not KOL.configOptions.args or not KOL.configOptions.args.tweaks then
        KOL:DebugPrint("Fishing: Config not ready yet, deferring InitializeConfig", 2)
        return
    end

    local synastriaTab = KOL.configOptions.args.tweaks.args.synastria
    if not synastriaTab then
        KOL:DebugPrint("Fishing: Synastria tab not ready yet", 2)
        return
    end

    synastriaTab.args.fishing = {
        type = "group",
        name = "Fishing",
        order = 4,
        args = {
            header = {
                type = "description",
                name = "FISHING|0.4,0.6,1",
                dialogControl = "KOL_SectionHeader",
                width = "full",
                order = 0,
            },
            desc = {
                type = "description",
                name = "|cFFAAAAAAAutomatically uses Phantom Ghostfish and cancels Invisibility buff after 1 second.|r\n",
                fontSize = "small",
                order = 0.1,
            },

            enabled = {
                type = "toggle",
                name = "Enable Fishing Module",
                desc = "Enable automatic Phantom Ghostfish handling",
                get = function() return KOL.db.profile.tweaks.fishing.enabled end,
                set = function(_, value)
                    KOL.db.profile.tweaks.fishing.enabled = value
                    KOL:PrintTag("Fishing module " .. (value and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))
                end,
                order = 1,
            },

            autoUse = {
                type = "toggle",
                name = "Auto-Use Ghostfish",
                desc = "Automatically use Phantom Ghostfish when found in bags",
                get = function() return KOL.db.profile.tweaks.fishing.autoUse end,
                set = function(_, value)
                    KOL.db.profile.tweaks.fishing.autoUse = value
                end,
                order = 2,
            },

            autoCancel = {
                type = "toggle",
                name = "Auto-Cancel Invisibility",
                desc = "Automatically cancel Invisibility buff 1 second after using Ghostfish",
                get = function() return KOL.db.profile.tweaks.fishing.autoCancel end,
                set = function(_, value)
                    KOL.db.profile.tweaks.fishing.autoCancel = value
                end,
                order = 3,
            },

            test = {
                type = "execute",
                name = "Test: Check for Ghostfish",
                desc = "Manually check bags for Phantom Ghostfish",
                func = function()
                    Fishing:CheckForGhostfish()
                end,
                order = 4,
            },
        },
    }
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")

frame:SetScript("OnUpdate", function(self, elapsed)
    Fishing:OnUpdate()
end)

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" and KOL.db then
        Fishing:Initialize()
    elseif event == "BAG_UPDATE" then
        Fishing:OnBagUpdate()
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entered combat - restore keybind immediately as fail-safe
        if hijackActive then
            local ts = date("%H:%M:%S")
            KOL:DebugPrint("[" .. ts .. "] COMBAT DETECTED - force restoring keybind!")
            Fishing:RestoreBagToggle()
            KOL:PrintTag(ORANGE("Combat started - keybind restored (can't use items in combat)"))
        end
    end
end)

KOL:DebugPrint("Fishing: Module file loaded successfully!", 2)
