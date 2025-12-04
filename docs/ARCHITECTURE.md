# 🏗️ Koality of Life - System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         KOALITY OF LIFE                         │
│                    Professional Addon System                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          LOAD ORDER                              │
└─────────────────────────────────────────────────────────────────┘

1. LIBRARIES (libs/)
   ├── LibStub.lua ──────────────┐
   ├── CallbackHandler-1.0 ──────┤
   │                              ├─> Foundation Layer
   ├── AceAddon-3.0 ─────────────┤
   ├── AceConsole-3.0 ───────────┤
   ├── AceDB-3.0 ────────────────┤
   ├── AceDBOptions-3.0 ─────────┤
   ├── AceEvent-3.0 ─────────────┤
   ├── AceGUI-3.0 ───────────────┤
   ├── AceConfig-3.0 ────────────┤
   ├── AceConfigRegistry-3.0 ────┤
   ├── AceConfigDialog-3.0 ──────┤
   ├── AceConfigCmd-3.0 ─────────┤
   ├── LibSharedMedia-3.0 ───────┤
   └── AceGUI-SharedMediaWidgets─┘

2. CORE
   └── core.lua ─────────────────> Main Initialization
       │
       ├─> Creates KoalityOfLife addon object
       ├─> Initializes AceDB database
       ├─> Registers slash commands
       └─> Calls InitializeUI()

3. UI SYSTEM
   └── ui.lua ───────────────────> Configuration Framework
       │
       ├─> Creates main config panel (rainbow title!)
       ├─> Provides UI helper functions
       └─> Registers with Blizzard Interface Options

4. MODULES
   ├── modules/chat.lua ─────────> Chat Output & Colors
   ├── modules/data.lua ─────────> Zone/Instance Info
   └── modules/itemtracker.lua ──> Font Customization
       │
       ├─> Registers config group
       ├─> Adds font options
       └─> Applies settings to frames


┌─────────────────────────────────────────────────────────────────┐
│                       DATA FLOW                                  │
└─────────────────────────────────────────────────────────────────┘

USER ACTION
    │
    ├─> Opens Config (/kol config)
    │   │
    │   └─> AceConfigDialog:Open("KoalityOfLife")
    │       │
    │       └─> Displays ui.lua config table
    │           │
    │           └─> Shows module options from:
    │               ├─> General (core.lua)
    │               ├─> ItemTracker (itemtracker.lua)
    │               └─> Profiles (AceDBOptions)
    │
    ├─> Changes Setting
    │   │
    │   └─> Option's set() function called
    │       │
    │       ├─> Updates KOL.db.profile.module.setting
    │       │   │
    │       │   └─> AceDB automatically saves to SavedVariables
    │       │
    │       └─> Module applies change immediately
    │
    └─> Uses Slash Command (/kol zone)
        │
        └─> core.lua:SlashCommand()
            │
            └─> Calls module function
                │
                └─> Uses data from modules/data.lua


┌─────────────────────────────────────────────────────────────────┐
│                    CONFIGURATION STRUCTURE                       │
└─────────────────────────────────────────────────────────────────┘

AceConfig Options Table
│
├─> General (core.lua)
│   ├─> Enable Addon (toggle)
│   └─> Debug Mode (toggle)
│
├─> Item Tracker (itemtracker.lua)
│   ├─> Font Face (LSM font select)
│   ├─> Font Size (slider 6-32)
│   ├─> Font Outline (dropdown)
│   ├─> Preview (description)
│   └─> Reset to Defaults (execute button)
│
└─> Profiles (AceDBOptions)
    ├─> Choose Profile
    ├─> New Profile
    ├─> Copy From
    └─> Delete Profile


┌─────────────────────────────────────────────────────────────────┐
│                      DATABASE STRUCTURE                          │
└─────────────────────────────────────────────────────────────────┘

SavedVariables: KoalityOfLifeDB
│
├─> profileKeys
│   └─> [realmName - characterName] = "Default"
│
└─> profiles
    │
    ├─> Default
    │   ├─> enabled = true
    │   ├─> debug = false
    │   │
    │   └─> itemtracker
    │       ├─> font = "Friz Quadrata TT"
    │       ├─> fontSize = 12
    │       └─> fontOutline = "OUTLINE"
    │
    └─> [Custom Profile Names...]


┌─────────────────────────────────────────────────────────────────┐
│                     MODULE INTEGRATION                           │
└─────────────────────────────────────────────────────────────────┘

How modules add config options:

1. Module Initialization
   └─> ItemTracker:InitializeConfig()

2. Create Config Group
   └─> KOL:UIAddConfigGroup("itemtracker", "Item Tracker", 10)
       │
       └─> Creates section in config panel

3. Add Options
   ├─> KOL:UIAddConfigFontSelect(...)
   ├─> KOL:UIAddConfigSlider(...)
   ├─> KOL:UIAddConfigSelect(...)
   └─> KOL:UIAddConfigExecute(...)

4. Get/Set Functions
   ├─> get = function() return KOL.db.profile.itemtracker.font end
   └─> set = function(_, value)
           KOL.db.profile.itemtracker.font = value
           ItemTracker:ApplyFontSettings()
       end


┌─────────────────────────────────────────────────────────────────┐
│                      FUNCTION REFERENCE                          │
└─────────────────────────────────────────────────────────────────┘

CORE FUNCTIONS (KOL:)
├─> OnInitialize()        - Called on ADDON_LOADED
├─> OnEnable()            - Called after initialization
├─> SlashCommand()        - Handles /kol commands
├─> PrintTag()            - Rainbow tag output
├─> DebugPrint()          - Debug messages
└─> OpenConfig()          - Opens config panel

UI FUNCTIONS (KOL:)
├─> InitializeUI()         - Sets up config system
├─> UIAddConfigGroup()     - Create module section
├─> UIAddConfigTitle()     - Add header
├─> UIAddConfigDescription() - Add text
├─> UIAddConfigToggle()    - Add checkbox
├─> UIAddConfigSlider()    - Add slider
├─> UIAddConfigSelect()    - Add dropdown
├─> UIAddConfigFontSelect() - Add font picker
├─> UIAddConfigInput()     - Add text input
├─> UIAddConfigColor()     - Add color picker
├─> UIAddConfigExecute()   - Add button
└─> UIAddConfigSpacer()    - Add spacing

CHAT FUNCTIONS (KOL:)
├─> Print()        - Basic output
├─> ColorPrint()   - Colored output
├─> PrintTag()     - Rainbow tag + message
└─> Debug()        - Debug output

DATA FUNCTIONS (KOL:)
├─> GetZoneDetails()  - Detailed zone info
├─> ZoneCommand()     - Display zone info
├─> IsInInstance()    - Instance check
├─> IsInDungeon()     - Dungeon check
├─> IsInRaid()        - Raid check
└─> IsHeroic()        - Heroic difficulty check

ITEMTRACKER FUNCTIONS
├─> Enable()              - Initialize module
├─> ApplyFontSettings()   - Update font on frames
├─> InitializeConfig()    - Register options
└─> CreateTestFrame()     - Show test window

GLOBAL FUNCTIONS (for macros)
├─> CO() / ColorOutput()  - Colored chat output
├─> RED(), GREEN(), etc.  - Color wrappers
├─> COLOR()               - Custom color
└─> GetZoneDetails()      - Zone info


┌─────────────────────────────────────────────────────────────────┐
│                    EXTENDING THE SYSTEM                          │
└─────────────────────────────────────────────────────────────────┘

To add a new module with config:

1. Create modules/mymodule.lua:

   local MyModule = {}
   KOL.mymodule = MyModule
   
   function MyModule:Enable()
       self:InitializeConfig()
   end
   
   function MyModule:InitializeConfig()
       -- Create config group
       KOL:UIAddConfigGroup("mymodule", "My Module", 20)
       
       -- Add options
       KOL:UIAddConfigToggle("mymodule", "enabled", {
           name = "Enable Feature",
           get = function() return KOL.db.profile.mymodule.enabled end,
           set = function(_, val) 
               KOL.db.profile.mymodule.enabled = val 
           end,
       })
   end

2. Add to core.lua defaults:

   local defaults = {
       profile = {
           mymodule = {
               enabled = true,
           },
       }
   }

3. Add to core.lua:OnEnable():

   if self.mymodule then
       self.mymodule:Enable()
   end

4. Add to .toc:

   modules\mymodule.lua

Done! Your module now has a config section.


┌─────────────────────────────────────────────────────────────────┐
│                      COLOR PALETTE                               │
└─────────────────────────────────────────────────────────────────┘

Rainbow Sequence (15 colors):
FF0000 → FF4400 → FF8800 → FFCC00 → FFFF00 → CCFF00 → 88FF00 → 
44FF00 → 00FF00 → 00FF88 → 00FFFF → 55AAFF → 7799FF → 8888FF → AA66FF

Standard Colors:
├─> FFDD00 (Yellow)   - Section headers
├─> 88AAFF (Blue)     - Option names
├─> FF6600 (Orange)   - Warning buttons
├─> 00FF00 (Green)    - Success messages
├─> FF0000 (Red)      - Error messages
└─> AAAAAA (Gray)     - Descriptions


┌─────────────────────────────────────────────────────────────────┐
│                    TROUBLESHOOTING MAP                           │
└─────────────────────────────────────────────────────────────────┘

Problem: Config won't open
├─> Check: All Ace libs installed?
├─> Check: .toc loads libraries in order?
├─> Check: ui.lua exists and loads?
└─> Enable: /console scriptErrors 1

Problem: Settings don't save  
├─> Check: Defaults in core.lua?
├─> Check: Using KOL.db.profile.module.setting?
├─> Check: AceDB-3.0 loaded?
└─> Test: /reload and check persistence

Problem: Font picker empty
├─> Check: LibSharedMedia-3.0 installed?
├─> Check: AceGUI-SharedMediaWidgets installed?
└─> Check: widget.xml file present?

Problem: Module options missing
├─> Check: Module calls InitializeConfig()?
├─> Check: Module enabled in OnEnable()?
├─> Check: UIAddConfigGroup() called?
└─> Check: Module loaded in .toc?


┌─────────────────────────────────────────────────────────────────┐
│                     SUCCESS INDICATORS                           │
└─────────────────────────────────────────────────────────────────┘

✅ Rainbow "Koality of Life" in Interface Options
✅ No Lua errors on /reload
✅ /kol config opens panel
✅ Item Tracker section visible
✅ Font dropdown shows fonts
✅ Settings save after /reload
✅ Profile system works
✅ Test frame shows correct font

If all ✅ then system is working perfectly!
```
