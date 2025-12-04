# Koality of Life - Complete Addon Package

## 📌 Version: 0.0.7.33

### 📦 Installation:

Extract this entire folder to:
```
World of Warcraft/Interface/AddOns/
```

So you end up with:
```
Interface/AddOns/Koality-of-Life/
├── Koality-of-Life.toc
├── core.lua
├── ui.lua
├── splash.lua
├── modules/
│   ├── chat.lua
│   ├── data.lua
│   └── itemtracker.lua
├── media/
│   └── kol-splash-1024.tga
└── docs/
    └── [documentation files]
```

---

## 🚀 Quick Start:

1. Extract to `AddOns/` folder
2. Install required libraries (see `docs/LIBRARY_INSTALLATION.md`)
3. Restart WoW (full exit, not /reload)
4. Type `/kol help` in-game

---

## 📚 Documentation:

All documentation is in the `docs/` folder:

- **INDEX.md** - Start here! Overview of everything
- **QUICKSTART_CHECKLIST.md** - Step-by-step setup guide
- **LIBRARY_INSTALLATION.md** - How to install Ace3 libraries -- ONLY DO THIS IF YOU DONT WANT THE LIBRARIES I INCLUDED WITH THIS ALREADY!! *WARNING*
- **README_CONFIG_SYSTEM.md** - Using the config system
- **SLASH_COMMANDS.md** - All available commands
- **ARCHITECTURE.md** - Technical details

---

## ✨ Features:

✅ Professional Ace3-based configuration system  
✅ Splash screen on login  
✅ Extensible slash command system  
✅ ItemTracker with font customization  
✅ Zone/instance detection utilities  
✅ Profile support (create multiple configs)  
✅ Modular architecture (easy to extend)  

---

## 🎮 In-Game Commands:

```
/kol help      - Show all commands
/kol config    - Open configuration panel
/kol splash    - Show splash screen
/kol testfont  - Test ItemTracker fonts
/kol zone      - Display zone information
/kol debug     - Toggle debug mode
```

---

## 📁 Folder Structure:

```
Koality-of-Life/
├── Koality-of-Life.toc    # Addon metadata and load order
├── core.lua               # Main addon core (AceAddon framework)
├── ui.lua                 # Config system (AceConfig)
├── splash.lua             # Splash screen on login
│
├── modules/               # Feature modules
│   ├── chat.lua           # Chat output and color functions
│   ├── data.lua           # Zone/instance detection
│   └── itemtracker.lua    # Font customization module
│
├── media/                 # Images and assets
│   └── kol-splash-1024.tga
│
└── docs/                  # Documentation (read these!)
    └── [.md files]
```

---

## ⚠️ Important Notes:

1. **Libraries Required**: You MUST install Ace3 libraries separately
   - See `docs/LIBRARY_INSTALLATION.md` for instructions
   
2. **First Launch**: Fully exit and restart WoW (don't just /reload)
   - This clears addon metadata cache
   
3. **Version Display**: If splash shows wrong version, restart WoW completely

---

## 🆘 Troubleshooting:

**Addon won't load?**
- Check libraries are installed in `libs/` folder
- Enable Lua errors: `/console scriptErrors 1`
- Check for red error messages

**Config won't open?**
- Make sure Ace3 libraries are installed
- Try `/reload` then `/kol config`

**Splash doesn't show image?**
- Verify `media/kol-splash-1024.tga` exists
- Check debug output: `/kol debug` then `/kol splash`

---

## 📖 Need Help?

Read the documentation in `docs/` folder:
- Start with `INDEX.md` for overview
- Then `QUICKSTART_CHECKLIST.md` for step-by-step setup

---

**Enjoy your professional WoW addon!** 🎉

Version: 0.0.7.33  
WoW: 3.3.5a (Wrath of the Lich King)
