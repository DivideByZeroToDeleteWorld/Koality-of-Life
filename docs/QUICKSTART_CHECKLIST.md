# ✅ Quick Start Checklist

## 📦 Pre-Installation

- [ ] I have downloaded the Ace3 library bundle
- [ ] I have downloaded LibSharedMedia-3.0
- [ ] I have downloaded AceGUI-3.0-SharedMediaWidgets
- [ ] All libraries are WoW 3.3.5a compatible

---

## 📁 File Installation

### Step 1: Install Libraries

- [ ] Created `libs/` folder in Koality-of-Life directory (if not exists)
- [ ] Extracted Ace3 bundle to `libs/`
- [ ] Installed LibSharedMedia-3.0 to `libs/LibSharedMedia-3.0/`
- [ ] Installed AceGUI-SharedMediaWidgets to `libs/AceGUI-3.0-SharedMediaWidgets/`

**Verify these folders exist:**
- [ ] `libs/AceAddon-3.0/`
- [ ] `libs/AceConsole-3.0/`
- [ ] `libs/AceDB-3.0/`
- [ ] `libs/AceGUI-3.0/`
- [ ] `libs/AceConfig-3.0/`
- [ ] `libs/AceConfigRegistry-3.0/`
- [ ] `libs/AceConfigDialog-3.0/`
- [ ] `libs/LibSharedMedia-3.0/`
- [ ] `libs/AceGUI-3.0-SharedMediaWidgets/`

### Step 2: Replace Core Files

From `/mnt/user-data/outputs/`, copy to your addon folder:

- [ ] `Koality-of-Life.toc` → Replace existing
- [ ] `core.lua` → Replace existing
- [ ] `ui.lua` → **NEW FILE** (create in root)
- [ ] `modules/chat.lua` → Replace existing
- [ ] `modules/data.lua` → Replace existing
- [ ] `modules/itemtracker.lua` → **NEW FILE** (create in modules/)

---

## 🎮 In-Game Testing

### Step 3: Initial Load

- [ ] Launched WoW 3.3.5a
- [ ] Enabled Lua errors: `/console scriptErrors 1`
- [ ] Typed `/reload`
- [ ] **NO** Lua errors appeared

### Step 4: Config Panel Test

- [ ] Typed `/kol config`
- [ ] Config panel opened
- [ ] Title shows rainbow "Koality of Life"
- [ ] "General" section exists
- [ ] "Item Tracker" section exists
- [ ] "Profiles" section exists

### Step 5: ItemTracker Features

- [ ] Clicked "Item Tracker" in left panel
- [ ] Font dropdown appears
- [ ] Font dropdown shows fonts (not empty)
- [ ] Font Size slider exists (6-32)
- [ ] Font Outline dropdown exists
- [ ] Reset button exists

### Step 6: Settings Persistence

- [ ] Changed font to something different
- [ ] Changed font size to 16
- [ ] Changed outline to "Thick Outline"
- [ ] Typed `/reload`
- [ ] Opened config again
- [ ] **Settings were saved!** ✅

### Step 7: Test Frame

- [ ] Opened Lua console (alt+Z if you have an addon, or create macro)
- [ ] Typed: `/run KoalityOfLife.itemtracker:CreateTestFrame()`
- [ ] Test frame appeared
- [ ] Text shows in configured font/size/outline
- [ ] Frame is draggable
- [ ] Changed font settings
- [ ] Frame updates immediately

### Step 8: Slash Commands

- [ ] `/kol` - Shows help
- [ ] `/kol config` - Opens config
- [ ] `/kol zone` - Shows zone info
- [ ] `/kol debug` - Toggles debug
- [ ] `/koality config` - Alternative command works

---

## 🐛 Troubleshooting (If Issues)

### If Config Won't Open

- [ ] Checked for Lua errors
- [ ] Verified all Ace libs installed
- [ ] Checked .toc file loads ui.lua
- [ ] Tried disabling other addons
- [ ] Re-downloaded libraries

### If Font Picker is Empty

- [ ] Verified LibSharedMedia-3.0 installed
- [ ] Checked AceGUI-SharedMediaWidgets installed
- [ ] Confirmed widget.xml file exists
- [ ] Looked for LSM-related Lua errors

### If Settings Don't Save

- [ ] Checked SavedVariables in .toc
- [ ] Verified AceDB-3.0 loaded
- [ ] Checked for database errors
- [ ] Tested with fresh character

---

## 📚 Documentation Review

- [ ] Read `README_CONFIG_SYSTEM.md`
- [ ] Read `LIBRARY_INSTALLATION.md`
- [ ] Reviewed `SUMMARY.md`
- [ ] Checked `ARCHITECTURE.md`

---

## 🎓 Understanding the Code

- [ ] Opened `core.lua` and read comments
- [ ] Opened `ui.lua` and understood UI functions
- [ ] Opened `modules/itemtracker.lua` as template
- [ ] Understand how to add new config options

---

## 🚀 Ready to Extend

- [ ] I know how to create config groups
- [ ] I know how to add config options
- [ ] I understand the database structure
- [ ] I can add new modules with config

---

## ✨ Success Criteria

**All of these should be ✅:**

- ✅ No Lua errors on load
- ✅ Rainbow config title visible
- ✅ Item Tracker section works
- ✅ Font selection functional
- ✅ Settings persist after /reload
- ✅ Test frame displays correctly
- ✅ All slash commands work
- ✅ Profile system functional

---

## 🎉 Completion

If all checkboxes above are checked, **congratulations!** 

You now have a professional, extensible configuration system for your addon!

**Next Steps:**
1. Start adding your own features
2. Create new modules with config options
3. Customize the UI to your liking
4. Build amazing WoW addon features!

---

## 💡 Quick Reference Commands

```lua
-- Open config
/kol config

-- Create test frame
/run KoalityOfLife.itemtracker:CreateTestFrame()

-- Toggle debug
/kol debug

-- Zone info
/kol zone

-- Check addon is loaded
/run print(KoalityOfLife.version)

-- Check database
/run print(KoalityOfLife.db.profile.itemtracker.font)

-- Enable Lua errors
/console scriptErrors 1
```

---

## 📞 Need Help?

If stuck on any step:
1. Check the detailed documentation in the README files
2. Look for Lua errors with `/console scriptErrors 1`
3. Verify file paths match .toc exactly
4. Compare your setup to ARCHITECTURE.md diagram
5. Re-download libraries if corrupted

**Good luck with your addon development!** 🎮✨
