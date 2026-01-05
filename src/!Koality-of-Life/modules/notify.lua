local KOL = KoalityOfLife

KOL.NotifyModule = {}
local NotifyModule = KOL.NotifyModule

function NotifyModule:Initialize()
    if self.initialized then return end
    self.initialized = true

    if not KOL.db.profile.notify then
        KOL.db.profile.notify = {
            enabled = true,
        }
    end

    self:SetupConfigUI()

    KOL:DebugPrint("Notify: Module initialized", 1)
end

function NotifyModule:SetupConfigUI()
    if not KOL.configOptions or not KOL.configOptions.args then
        KOL:DebugPrint("Notify: Config not ready, deferring setup", 3)
        return
    end

    KOL.configOptions.args.notify = {
        type = "group",
        name = "|cFF88FFAANotify|r",
        order = 5,
        childGroups = "tab",
        args = {
            header = {
                type = "description",
                name = "|cFFFFFFFFNotification System|r\n|cFFAAAAAAConfigure alerts, notifications, and visual feedback.|r\n",
                fontSize = "medium",
                order = 0,
            },

            general = {
                type = "group",
                name = "|cFFFFDD00General|r",
                order = 1,
                childGroups = "tree",
                args = {
                    default = {
                        type = "group",
                        name = "Default",
                        order = 1,
                        args = {
                            header = {
                                type = "description",
                                name = "DEFAULT|0.5,0.8,0.5",
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

KOL:DebugPrint("Notify module loaded", 3)
