# AI Coding Agent Instructions for Koality-of-Life AddOn

## Overview
Koality-of-Life is a modular World of Warcraft AddOn designed for version 3.3.5a. It provides quality-of-life improvements and is structured to allow easy expansion through additional modules. The codebase uses Lua and relies on several external libraries.

### Key Components
- **Core.lua**: Handles addon initialization, event management, saved variables, and slash commands.
- **modules/**: Contains modular features, such as `Chat.lua` for chat-related functionality.
- **libs/**: External dependencies, including `LibStub`, `CallbackHandler-1.0`, `LibDataBroker-1.1`, and `LibDBIcon-1.0`.

### External Libraries
Ensure the following libraries are present in the `libs/` folder:
- `LibStub`
- `CallbackHandler-1.0`
- `LibDataBroker-1.1`
- `LibDBIcon-1.0`

## Development Guidelines

### Adding New Modules
1. Create a new Lua file in the `modules/` directory (e.g., `YourModule.lua`).
2. Register the module in `Koality-of-Life.toc` under the `# Modules` section.
3. Use the `KoalityOfLife` global table to access shared functionality.

### Coding Conventions
- Use the `ColorOutput` function for chat messages to ensure proper rendering of color codes.
  ```lua
  ColorOutput("This is ", "|cFFFF0000red text|r", " and this is normal")
  ```
- Short alias for `ColorOutput`:
  ```lua
  CO("Quick ", "|cFF00FF00green|r", " text")
  ```
- Follow the modular architecture to keep features isolated and maintainable.

### Slash Commands
- `/kol help`: Display available commands.
- `/kol toggle`: Enable/disable the addon.
- `/kol debug`: Toggle debug mode.

## Debugging and Testing
- Use `/kol debug` to enable debug mode for additional logging.
- Test new modules by adding them to the TOC file and verifying their functionality in-game.

## Examples
### Colored Output
```lua
/run ColorOutput("|cFFFF0000Red|r, |cFF00FF00Green|r, |cFF0000FFBlue|r")
```

### Dynamic Variables
```lua
/run ColorOutput("Your health: ", "|cFF00FF00" .. UnitHealth("player") .. "|r")
```

### Multiple Arguments
```lua
/run CO("Part 1", " Part 2", " Part 3")
```

## Future Enhancements
- Expand the modular architecture with additional features.
- Document new modules and their usage in this file.