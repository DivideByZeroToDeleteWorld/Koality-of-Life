# Koality of Life - Professional Configuration System

## 🌈 What's New

Your addon now uses the **Ace3 framework** - the industry standard for professional WoW addons! This gives you:

- **Professional configuration UI** with a beautiful rainbow title
- **Automatic profile management** (create/switch/delete profiles)
- **LibSharedMedia integration** for font selection
- **Extensible module system** - easily add config options from any module
- **Persistent settings** that survive reloads and game restarts

---

## 📋 Required Libraries

You need to download and install these libraries in your `libs/` folder:

### Ace3 Libraries (Download from WoWAce or CurseForge)
- `AceAddon-3.0`
- `AceConsole-3.0`
- `AceConfig-3.0` (meta-package containing):
  - `AceConfigRegistry-3.0`
  - `AceConfigDialog-3.0`
  - `AceConfigCmd-3.0`
- `AceDB-3.0`
- `AceDBOptions-3.0`
- `AceEvent-3.0`
- `AceGUI-3.0`

### SharedMedia Libraries
- `LibSharedMedia-3.0`
- `AceGUI-3.0-SharedMediaWidgets`

**Note:** You already have `LibStub` and `CallbackHandler-1.0` which are required dependencies.

---

## 🎨 Opening the Config Panel

### In-Game Commands:
```
/kol config
/kol options
/koality config
```

### Via Interface Options:
1. Press `ESC` → Interface → AddOns
2. Look for the rainbow "Koality of Life" panel

---

## 🎯 ItemTracker Module

The new **ItemTracker** module demonstrates the configuration system with full font customization:

### Features:
- **Font Selection** - Choose from all available fonts via LibSharedMedia
- **Font Size** - Slider from 6-32 points
- **Font Outline** - Multiple options:
  - None
  - Outline
  - Thick Outline
  - Monochrome
  - Outline + Monochrome
  - Thick Outline + Monochrome
- **Live Preview** - See current settings in the config panel
- **Reset Button** - Restore defaults instantly

### Testing:
```lua
-- In-game, type:
/run KoalityOfLife.itemtracker:CreateTestFrame()

-- This creates a draggable test frame showing your current font settings
-- Drag it around, close with X button
```

---

## 🔧 Adding Config Options to Your Modules

The UI system is **fully extensible**! Here's how to add config options from any module:

### Step 1: Create a Config Group

```lua
-- In your module's initialization
KOL:UIAddConfigGroup("mymodule", "My Module Name", 15)
-- Parameters: internal_name, display_name, order
```

### Step 2: Add Options

```lua
-- Add a title/header
KOL:UIAddConfigTitle("mymodule", "header1", "General Settings", 1)

-- Add a description
KOL:UIAddConfigDescription("mymodule", "desc1", "Configure your module here", 2)

-- Add a toggle (checkbox)
KOL:UIAddConfigToggle("mymodule", "enabled", {
    name = "Enable Feature",
    desc = "Turn this feature on or off",
    order = 10,
    get = function() return KOL.db.profile.mymodule.enabled end,
    set = function(_, value)
        KOL.db.profile.mymodule.enabled = value
        -- Do something when changed
    end,
})

-- Add a slider
KOL:UIAddConfigSlider("mymodule", "amount", {
    name = "Amount",
    desc = "Set the amount",
    min = 1,
    max = 100,
    step = 1,
    order = 20,
    get = function() return KOL.db.profile.mymodule.amount end,
    set = function(_, value)
        KOL.db.profile.mymodule.amount = value
    end,
})

-- Add a dropdown/select
KOL:UIAddConfigSelect("mymodule", "mode", {
    name = "Mode",
    desc = "Select a mode",
    values = {
        ["auto"] = "Automatic",
        ["manual"] = "Manual",
        ["off"] = "Disabled"
    },
    order = 30,
    get = function() return KOL.db.profile.mymodule.mode end,
    set = function(_, value)
        KOL.db.profile.mymodule.mode = value
    end,
})
```

### Available UI Functions:

| Function | Purpose |
|----------|---------|
| `UIAddConfigGroup()` | Create a new config section |
| `UIAddConfigTitle()` | Add a header |
| `UIAddConfigDescription()` | Add descriptive text |
| `UIAddConfigToggle()` | Add a checkbox |
| `UIAddConfigSlider()` | Add a number slider |
| `UIAddConfigSelect()` | Add a dropdown menu |
| `UIAddConfigFontSelect()` | Add a font picker (uses LibSharedMedia) |
| `UIAddConfigInput()` | Add a text input field |
| `UIAddConfigColor()` | Add a color picker |
| `UIAddConfigExecute()` | Add a button that runs a function |
| `UIAddConfigSpacer()` | Add vertical spacing |

---

## 💾 Database Structure

Settings are automatically saved using AceDB with profile support:

```lua
-- Access settings
KOL.db.profile.itemtracker.font
KOL.db.profile.itemtracker.fontSize
KOL.db.profile.itemtracker.fontOutline

-- Settings are automatically saved when changed
-- They persist across /reload and game restarts
```

### Adding Your Module's Settings:

1. **Update `core.lua` defaults table:**
```lua
local defaults = {
    profile = {
        enabled = true,
        debug = false,
        
        -- Add your module settings here
        mymodule = {
            enabled = true,
            amount = 50,
            mode = "auto",
        },
    }
}
```

---

## 🎨 Rainbow Text Effects

The config panel title uses a rainbow effect automatically. The colors cycle through:

```
Red → Orange → Yellow → Green → Cyan → Blue → Purple
```

This makes "Koality of Life" look stunning in the Interface Options!

---

## 🔍 Debug Mode

Enable debug output to see what's happening:

```
/kol debug
```

Or use the toggle in the config panel under **General** settings.

---

## 📁 File Structure

```
Koality-of-Life/
├── libs/
│   ├── LibStub/
│   ├── CallbackHandler-1.0/
│   ├── AceAddon-3.0/
│   ├── AceConsole-3.0/
│   ├── AceConfig-3.0/
│   ├── AceDB-3.0/
│   ├── AceGUI-3.0/
│   ├── LibSharedMedia-3.0/
│   └── AceGUI-3.0-SharedMediaWidgets/
├── modules/
│   ├── chat.lua         # Chat output and color functions
│   ├── data.lua         # Zone/instance detection
│   └── itemtracker.lua  # Font customization (NEW!)
├── core.lua             # Main addon initialization
├── ui.lua              # Config system (NEW!)
└── Koality-of-Life.toc # Updated with all libraries
```

---

## ✅ Testing Checklist

1. **Install all required libraries** in `libs/` folder
2. **Replace your files** with the new versions
3. **/reload** in-game
4. Type **/kol config** - you should see a rainbow title!
5. Click on **"Item Tracker"** in the left panel
6. Change font settings and see them save automatically
7. **/reload** and check settings persist

---

## 🚀 Next Steps

You can now easily add configuration options for:
- Custom features
- Module toggles
- Appearance settings
- Behavior options
- Any user-customizable setting

Just follow the pattern in `modules/itemtracker.lua` - create your module, add a config group, and add your options!

---

## 💡 Tips

- **Colors**: Use `|cFFRRGGBB` format for colored text in option names/descriptions
- **Order**: Lower order numbers appear first in the UI
- **Profiles**: Users can create multiple profiles and switch between them
- **Width**: Options can be "normal", "double", or "full" width
- **Spacing**: Use `UIAddConfigSpacer()` to add visual breathing room

---

## 🐛 Troubleshooting

**Config won't open?**
- Make sure all Ace3 libraries are installed
- Check for Lua errors with `/console scriptErrors 1`
- Verify `.toc` file loads libraries in correct order

**Settings not saving?**
- Make sure you added defaults in `core.lua`
- Check that you're using `KOL.db.profile.yourmodule.setting`
- Verify AceDB-3.0 is loaded

**Font not applying?**
- Make sure LibSharedMedia-3.0 is installed
- Check that the font name exists in SharedMedia
- Look for error messages in debug mode

---

Enjoy your professional configuration system! 🎉
