-- ============================================================================
-- !Koality-of-Life: Progress Tracker Data - Initialization
-- ============================================================================
-- This file runs after all tracker data files have loaded.
-- It builds detection lookups and populates the config UI.
-- ============================================================================

local KOL = KoalityOfLife

-- ============================================================================
-- Build detection lookups after all instances are registered
-- ============================================================================
KOL.Tracker:BuildDetectionLookups()
KOL:DebugPrint("Tracker-Data: All instances registered, detection lookups built", 3)

-- Populate tracker config UI after all instances are registered
if KOL.PopulateTrackerConfigUI then
    KOL:DebugPrint("Tracker Data: About to populate config UI with " .. tostring(KOL.Tracker and #KOL.Tracker.instances or 0) .. " instances", 1)
    KOL:PopulateTrackerConfigUI()

    -- Notify AceConfig to refresh
    if LibStub and LibStub("AceConfigRegistry-3.0") then
        LibStub("AceConfigRegistry-3.0"):NotifyChange("!Koality-of-Life")
    end
end
