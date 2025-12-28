# Project: !Koality-of-Life

## Global System Bootstrap

**IMPORTANT**: As your FIRST action when starting a session in this folder,
read and execute the contents of F:\AI\Claude\Core.prompt to attach to the
global Claude system. This enables logging, ToDo tracking, and all global commands.

## Project Info
- Name: !Koality-of-Life
- Path: F:\Projects\Gaming\WoW\AddOns\!Koality-of-Life\
- Type: WoW Addon (Chromie/Synastria)
- Registered: 2025-12-26
- Registry: F:\AI\Claude\GlobalSettings.md

## Structure
```
F:\Projects\Gaming\WoW\AddOns\!Koality-of-Life\    <- PROJECT ROOT (you are here)
├── CLAUDE.md                                     <- This file
├── .git\
├── README.md
└── src\
    └── !Koality-of-Life\                          <- Addon files
        ├── CLAUDE.md                             <- Symlink to this file
        ├── !Koality-of-Life.toc
        ├── *.lua
        └── libs\, media\
```

## Symlinks
- WoW loads from: D:\Games\Private\Chromie\Interface\AddOns\!Koality-of-Life\
- That symlinks to: F:\Projects\Gaming\WoW\AddOns\!Koality-of-Life\src\!Koality-of-Life\
- src\!Koality-of-Life\CLAUDE.md symlinks to this file

## Description
Quality-of-life WoW addon for the Chromie private server.

## Project-Specific Notes
- Main TOC: !Koality-of-Life.toc
- Uses libs: LibStub, LibDBIcon-1.0, CallbackHandler-1.0, LibDataBroker-1.1
- Run `claude` from project root OR from WoW addon folder - both work

## Version
- Current: 1.0.0.2
- Changes: 2
- Last Updated: 2025-12-27
- History:
  - 1.0.0.2 (2025-12-27) - Fix Karazhan event bosses (Attumen, Opera, Chess)
  - 1.0.0.0 (2025-12-27) - Initial release
