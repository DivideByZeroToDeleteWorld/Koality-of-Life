# 🎉 Update: Extensible Slash Command System

## What's New

Your addon now has a **professional slash command registration system** that any module can use!

---

## 🚀 New Features

### 1. **Centralized Slash Command System**
- All commands go through `/kol` or `/koality`
- Modules register subcommands easily
- Automatic help generation
- No conflicts between modules

### 2. **Easy Registration from Anywhere**
Any module can add commands with one function call:

```lua
KOL:RegisterSlashCommand("mycommand", MyFunction, "Description")
```

### 3. **Built-in Commands**
- `/kol help` - Shows all commands (auto-generated!)
- `/kol config` - Opens config panel
- `/kol debug` - Toggles debug mode

### 4. **Module Commands (Auto-registered)**
- `/kol splash` - Show splash screen (from splash.lua)
- `/kol zone` - Show zone info (from data.lua)

---

## 📁 New/Updated Files

### NEW:
- ✅ **modules/slash.lua** - Centralized command system
- ✅ **SLASH_COMMANDS.md** - Complete documentation

### UPDATED:
- ✅ **core.lua** - Removed duplicate slash code
- ✅ **splash.lua** - Registers `/kol splash` command
- ✅ **data.lua** - Registers `/kol zone` command

---

## 🎯 How to Use

### Test the Splash Command

In-game, type:
```
/kol splash
```

The splash screen will appear on demand!

### See All Commands

```
/kol help
```

Output:
```
Available commands:
/kol config - Open configuration panel
/kol debug - Toggle debug mode
/kol help - Show this help message

Module Commands:
/kol splash - Show the splash screen
/kol zone - Display current zone information
```

---

## 🔧 For Developers

### Add a Command from Your Module

```lua
-- In your module file:
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" and KOL.RegisterSlashCommand then
        KOL:RegisterSlashCommand("yourcommand", function(arg1, arg2)
            -- Your code here
            KOL:PrintTag("Command executed!")
        end, "What your command does")
    end
end)
```

That's it! Your command is now available as `/kol yourcommand`

---

## 💡 Example Use Cases

### Toggle Feature
```lua
KOL:RegisterSlashCommand("toggle", function()
    KOL.db.profile.myfeature = not KOL.db.profile.myfeature
    local status = KOL.db.profile.myfeature and "ON" or "OFF"
    KOL:PrintTag("Feature: " .. status)
end, "Toggle my feature on/off")
```

### Set Value
```lua
KOL:RegisterSlashCommand("scale", function(value)
    local num = tonumber(value)
    if num then
        KOL.db.profile.scale = num
        KOL:PrintTag("Scale set to: " .. num)
    else
        KOL:PrintTag("Usage: /kol scale <number>")
    end
end, "Set UI scale")
```

### Execute Action
```lua
KOL:RegisterSlashCommand("reset", function()
    -- Reset some settings
    KOL.db.profile.mymodule = {}
    KOL:PrintTag("Settings reset!")
end, "Reset module settings")
```

---

## ✨ Benefits

✅ **Module Independence** - Each module manages its own commands  
✅ **No Conflicts** - Centralized registration prevents duplicates  
✅ **Auto Documentation** - Commands appear in `/kol help` automatically  
✅ **Easy to Use** - One function call to register  
✅ **User Friendly** - All commands under `/kol`  
✅ **Extensible** - Add unlimited commands  

---

## 🏗️ Architecture

```
User types: /kol splash
     ↓
core.lua receives via AceConsole
     ↓
Calls: KOL:SlashCommand("splash")
     ↓
slash.lua checks registered commands
     ↓
Finds: slashCommands["splash"].func
     ↓
Executes: ShowSplash()
     ↓
Splash screen appears!
```

---

## 📚 Full Documentation

See **SLASH_COMMANDS.md** for:
- Complete API reference
- Multiple examples
- Best practices
- Troubleshooting
- Advanced usage

---

## 🎮 Try It Now!

1. `/reload` in-game
2. Type `/kol help` to see all commands
3. Type `/kol splash` to test the splash screen
4. Type `/kol zone` to see zone info

---

**Every module can now easily add its own slash commands!** 🚀✨
