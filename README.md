# Koality-of-Life

Quality-of-life WoW addon for Chromie/Synastria (3.3.5a).

## Features

### Progress Tracker
Track your dungeon and raid progress with detailed statistics:
- **Boss Kill Tracking** - Automatic detection via combat log, yells, and unit IDs
- **Completion Times** - Track clear speeds for dungeons and raids
- **Speed Display** - Real-time speed tracking with customizable display
- **Wing/Area Grouping** - Logical grouping of bosses by raid wings and dungeon areas
- **Expansion Filtering** - Filter by Classic, TBC, or WotLK content
- **Difficulty Support** - Normal, Heroic, 10-man, 25-man tracking

### Custom Trackers (WIP)
Create your own tracking panels to monitor kills, loot, boss yells, and more!
- **Tracker Manager** - Visual editor for creating custom tracking entries
- **Entry Types** - Kill (NPC), Loot (Item), Yell (boss text), Multi-Kill (council fights)
- **Groups** - Organize entries into collapsible groups
- **Zone Filtering** - Auto-show panels in specific zones

**[Read the full Custom Trackers documentation](docs/CustomTrackers.md)**

### Build Manager
Manage talent builds with ease:
- **Build Templates** - Save and load talent configurations
- **Quick Switching** - Fast talent swapping out of combat
- **Class Support** - All classes and specs supported

### Keybinds System
Enhanced keybinding management:
- **Bind Groups** - Organize keybinds into logical groups
- **Profiles** - Multiple keybind profiles for different situations
- **Visual Editor** - Easy-to-use keybind configuration UI
- **Conditional Binds** - Context-aware keybinding options

### Command Blocks
Reusable code snippets for macros:
- **Block Library** - Create and store reusable code blocks
- **Macro Integration** - Use blocks in your macros
- **Syntax Highlighting** - FAIAP-powered Lua highlighting

### Macro Updater
Auto-updating macro system:
- **Dynamic Macros** - Macros that update based on conditions
- **Command Block Integration** - Use command blocks in macros
- **Out-of-Combat Updates** - Automatic updates when safe

### Themes
Custom UI theming system:
- **Theme Editor** - Create and customize themes
- **Color Palettes** - Pastel and standard color sets
- **Live Preview** - See changes in real-time

### UI Factory
Powerful widget creation system (for developers):
- **Custom Widgets** - Dropdowns, sliders, checkboxes, and more
- **Styled Components** - Consistent themed UI elements
- **Drag & Drop** - Moveable UI panels

### Additional Features
- **Fishing Helpers** - Fishing automation and quality-of-life
- **Chat Improvements** - Enhanced chat functionality
- **Font Customization** - Custom fonts for UI elements (ItemHunt support)
- **Debug Console** - Developer debugging tools
- **Notification System** - Toast-style notifications
- **Character Viewer** - Character inspection tools

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

The addon has been renamed to `!Koality-of-Life` (with `!` prefix). This ensures the addon loads first alphabetically in WoW's addon ecosystem.

## Usage

| Command | Description |
|---------|-------------|
| `/kol` | Show available commands |
| `/kol config` | Open the main options panel |
| `/kol tracker` | Open the Progress Tracker |
| `/kol binds` | Open the Keybinds panel |
| `/kol debug` | Toggle debug mode |
| `/kolreload` | Reload UI (alias for `/reload`) |

## Testing Notice

We are currently in **testing phase** for several features:

- **Progress Tracker** - Boss IDs and detection methods are being verified against DBM data
- **Custom Trackers** - Work in progress, may have incomplete functionality
- **Build Manager** - Testing talent application accuracy

Feedback and bug reports are welcome!

## Version History

### v1.0.1.7 (Current)
- Major UI and tracker improvements
- Fixed syntax errors in config panels
- Expanded UI Factory with new widget types
- Enhanced tracker editor functionality
- Improved debug console
- New color definitions and theme improvements

### v1.0.0.7
- Added unified tracker entry schema with multi-type detection

### v1.0.0.6
- Added wing/area grouping to classic dungeons

### v1.0.0.5
- Fixed yell-based boss detection for ICC and ToC

---

Lovingly developed by **Z**ero with the assistance of [Claude Code](https://claude.com/claude-code)
