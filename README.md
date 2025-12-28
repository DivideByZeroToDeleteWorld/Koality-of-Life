# Koality-of-Life

Quality-of-life WoW addon for Chromie/Synastria (3.3.5a).

## Features

- **Progress Tracker** - Track dungeon/raid completion times and boss kills
- **Tweaks** - Font customization for ItemHunt and other UI elements
- **Themes** - Custom UI theming system
- **Fishing** - Fishing automation helpers
- **Keybinds** - Enhanced keybind management
- **Chat** - Chat improvements
- **Macros** - Auto-updating macro system

## Installation

1. Download the latest release ZIP from GitHub
2. Extract the ZIP file
3. Copy the `!Koality-of-Life` folder from inside `src/` to your WoW addons folder:
   ```
   WoW/Interface/AddOns/!Koality-of-Life
   ```
4. Restart WoW or type `/reload`

### Upgrading from a Previous Version

> **Important:** If you previously installed this addon as `Koality-of-Life` (without the `!` prefix), you must **delete** the old `Interface/AddOns/Koality-of-Life` folder before installing.

The addon has been renamed to `!Koality-of-Life` (with `!` prefix). This is intentional - the `!` prefix ensures the addon loads first alphabetically in WoW's addon ecosystem, allowing us to initialize before other addons for proper functionality.

## Testing Notice

We are currently in **testing phase** while finalizing the dungeon and raid data for the **Progress Tracker** feature. Boss IDs, detection methods, and raid wing groupings are being verified against DBM data for accuracy.

Feedback and bug reports are welcome!

## Usage

Type `/kol` in-game to open the options panel.

---

Lovingly developed by **Z**ero with the assistance of [Claude Code](https://claude.com/claude-code)
