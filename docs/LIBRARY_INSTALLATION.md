# 📦 Library Installation Guide

## Where to Get the Libraries

All required libraries can be downloaded from **WoWAce** or **CurseForge**. Since you're using WoW 3.3.5a, make sure to get versions compatible with that client.

---

## Option 1: Download Ace3 Bundle (Easiest)

1. Go to: https://www.wowace.com/projects/ace3
2. Download the **Ace3** package (this includes most libraries)
3. Extract the contents to your `Koality-of-Life/libs/` folder

The Ace3 bundle includes:
- AceAddon-3.0
- AceConsole-3.0  
- AceConfig-3.0 (and sub-packages)
- AceDB-3.0
- AceDBOptions-3.0
- AceEvent-3.0
- AceGUI-3.0
- CallbackHandler-1.0 (you already have this)
- LibStub (you already have this)

---

## Option 2: Download Individual Libraries

If you prefer individual libraries or the bundle doesn't work:

### Core Ace3 Libraries
- **AceAddon-3.0**: https://www.wowace.com/projects/ace3/files
- **AceConsole-3.0**: Included in Ace3 bundle
- **AceDB-3.0**: Included in Ace3 bundle
- **AceEvent-3.0**: Included in Ace3 bundle
- **AceGUI-3.0**: Included in Ace3 bundle

### Config Libraries  
- **AceConfig-3.0**: Included in Ace3 bundle
- **AceConfigRegistry-3.0**: Included in Ace3 bundle
- **AceConfigDialog-3.0**: Included in Ace3 bundle
- **AceConfigCmd-3.0**: Included in Ace3 bundle
- **AceDBOptions-3.0**: Included in Ace3 bundle

---

## Required: LibSharedMedia

This is **NOT** included in Ace3, download separately:

1. **LibSharedMedia-3.0**: https://www.wowace.com/projects/libsharedmedia-3-0
2. **AceGUI-3.0-SharedMediaWidgets**: https://www.wowace.com/projects/ace-gui-3-0-shared-media-widgets

---

## Directory Structure After Installation

Your `libs/` folder should look like this:

```
Koality-of-Life/
└── libs/
    ├── LibStub/
    │   └── LibStub.lua
    ├── CallbackHandler-1.0/
    │   └── CallbackHandler-1.0.lua
    ├── AceAddon-3.0/
    │   └── AceAddon-3.0.lua
    ├── AceConsole-3.0/
    │   └── AceConsole-3.0.lua
    ├── AceDB-3.0/
    │   └── AceDB-3.0.lua
    ├── AceDBOptions-3.0/
    │   └── AceDBOptions-3.0.lua
    ├── AceEvent-3.0/
    │   └── AceEvent-3.0.lua
    ├── AceGUI-3.0/
    │   ├── AceGUI-3.0.lua
    │   └── widgets/
    ├── AceConfig-3.0/
    │   └── AceConfig-3.0.lua
    ├── AceConfigRegistry-3.0/
    │   └── AceConfigRegistry-3.0.lua
    ├── AceConfigDialog-3.0/
    │   └── AceConfigDialog-3.0.lua
    ├── AceConfigCmd-3.0/
    │   └── AceConfigCmd-3.0.lua
    ├── LibSharedMedia-3.0/
    │   ├── LibSharedMedia-3.0.lua
    │   └── LibSharedMedia-3.0.toc
    ├── AceGUI-3.0-SharedMediaWidgets/
    │   ├── widget.xml
    │   └── [widget files]
    ├── LibDataBroker-1.1/
    │   └── LibDataBroker-1.1.lua
    └── LibDBIcon-1.0/
        └── LibDBIcon-1.0.lua
```

---

## Verification

After installing, you can verify everything is working:

1. Log into WoW
2. Type `/reload`
3. Check for Lua errors: `/console scriptErrors 1`
4. Type `/kol config`

If the config panel opens with a rainbow "Koality of Life" title, **you're all set!** ✅

---

## Troubleshooting

### Error: "Cannot find AceAddon-3.0"
- Make sure the library folders are in `Koality-of-Life/libs/`
- Check that `.toc` file has correct paths
- Verify library `.lua` files exist

### Error: "attempt to index nil value"  
- One or more libraries failed to load
- Enable Lua errors and check which library is missing
- Re-download and verify file structure

### Config panel is blank
- Make sure `ui.lua` is loaded in `.toc` file
- Check that it comes AFTER all library loads
- Verify `core.lua` loads before `ui.lua`

### Font selector doesn't show fonts
- Install `LibSharedMedia-3.0`
- Install `AceGUI-3.0-SharedMediaWidgets`
- Make sure the `widget.xml` file is present

---

## Alternative: Use Standalone Addon Package

If library management is too complex, you can:

1. Download a working Ace3-based addon (like DBM, Skada, Bartender)
2. Copy their `libs/` folder contents to yours
3. Remove any libraries you don't need

Most major addons include the full Ace3 suite!

---

## Version Compatibility

Since you're on **WoW 3.3.5a (3.3.5.12340)**:

- Make sure libraries are tagged for **WotLK (3.3.5)**
- Retail (9.0+) versions will NOT work
- Look for "Classic WotLK" or "3.3.5" compatible versions

---

## Questions?

If you run into issues:
1. Check `/console scriptErrors 1` for exact error messages
2. Verify file paths match the `.toc` file exactly
3. Make sure library versions are WotLK-compatible
4. Test with just Koality-of-Life enabled (disable other addons)

Happy addon developing! 🎉
