-- ============================================================================
-- !Koality-of-Life: Notify Module
-- ============================================================================
-- Notification system configuration and management
-- ============================================================================

local KOL = KoalityOfLife

-- ============================================================================
-- Notify Module
-- ============================================================================

KOL.NotifyModule = {}
local NotifyModule = KOL.NotifyModule

-- ============================================================================
-- Initialization
-- ============================================================================

function NotifyModule:Initialize()
    -- Prevent double initialization
    if self.initialized then return end
    self.initialized = true

    -- Ensure database structure exists
    if not KOL.db.profile.notify then
        KOL.db.profile.notify = {
            enabled = true,
        }
    end

    -- Setup config UI
    self:SetupConfigUI()

    KOL:DebugPrint("Notify: Module initialized", 1)
end

-- ============================================================================
-- Config UI Setup
-- ============================================================================

function NotifyModule:SetupConfigUI()
    if not KOL.configOptions or not KOL.configOptions.args then
        KOL:DebugPrint("Notify: Config not ready, deferring setup", 3)
        return
    end

    -- Create the Notify main tab
    KOL.configOptions.args.notify = {
        type = "group",
        name = "|cFF88FFAANotify|r",
        order = 5,  -- After commandblocks (order 4)
        childGroups = "tab",
        args = {
            header = {
                type = "description",
                name = "|cFFFFFFFFNotification System|r\n|cFFAAAAAAConfigure alerts, notifications, and visual feedback.|r\n",
                fontSize = "medium",
                order = 0,
            },

            -- General sub-tab with tree view
            general = {
                type = "group",
                name = "|cFFFFDD00General|r",
                order = 1,
                childGroups = "tree",  -- Tree-style nested panel (like Synastria)
                args = {
                    -- ============================================================
                    -- DEFAULT Section (placeholder)
                    -- ============================================================
                    default = {
                        type = "group",
                        name = "Default",
                        order = 1,
                        args = {
                            header = {
                                type = "description",
                                name = "DEFAULT|0.5,0.8,0.5",  -- Soft green accent
                                dialogControl = "KOL_SectionHeader",
                                width = "full",
                                order = 0,
                            },
                            desc = {
                                type = "description",
                                name = "|cFFAAAAAADefault notification settings (placeholder).|r\n",
                                fontSize = "small",
                                order = 0.1,
                            },
                        },
                    },
                },
            },
        },
    }

    KOL:DebugPrint("Notify: Config UI setup complete", 3)
end

-- Module loaded message (initialization is called from ui.lua)
KOL:DebugPrint("Notify module loaded", 3)
