# 🔧 Slash Command Registration System

## Overview

Koality of Life now has a **centralized, extensible slash command system** that allows any module to register its own commands easily!

---

## How It Works

### Centralized System
All slash commands go through `/kol` or `/koality`, but modules can register their own subcommands:

```
/kol splash      <- Registered by splash.lua
/kol zone        <- Registered by data.lua
/kol config      <- Built-in
/kol debug       <- Built-in
/kol help        <- Built-in (shows all commands)
```

---

## For Module Developers

### Register a Command

From any module, simply call:

```lua
KOL:RegisterSlashCommand(command, function, description)
```

**Parameters:**
- `command` (string) - The subcommand name (e.g., "splash", "zone")
- `function` (function) - The function to call when command is used
- `description` (string) - Help text shown in `/kol help`

### Example: Simple Command

```lua
-- Register a simple command
KOL:RegisterSlashCommand("hello", function()
    KOL:PrintTag("Hello from my module!")
end, "Say hello")

-- Now users can type: /kol hello
```

### Example: Command with Arguments

```lua
-- Register a command that accepts arguments
KOL:RegisterSlashCommand("greet", function(name)
    if not name then
        KOL:PrintTag("Usage: /kol greet <name>")
        return
    end
    KOL:PrintTag("Hello, " .. name .. "!")
end, "Greet someone by name")

-- Usage: /kol greet Will
```

### Example: Multiple Arguments

```lua
KOL:RegisterSlashCommand("math", function(num1, num2)
    local a = tonumber(num1)
    local b = tonumber(num2)
    
    if not a or not b then
        KOL:PrintTag("Usage: /kol math <number> <number>")
        return
    end
    
    KOL:PrintTag("Sum: " .. (a + b))
end, "Add two numbers")

-- Usage: /kol math 5 10
```

---

## Real Examples from KOL

### Splash Module (splash.lua)

```lua
-- Register on PLAYER_LOGIN
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" and KOL.RegisterSlashCommand then
        KOL:RegisterSlashCommand("splash", ShowSplash, "Show the splash screen")
    end
end)

-- Now users can type: /kol splash
```

### Data Module (data.lua)

```lua
-- Register zone command
KOL:RegisterSlashCommand("zone", function()
    KOL:ZoneCommand()
end, "Display current zone information")

-- Now users can type: /kol zone
```

---

## Best Practices

### 1. Register on PLAYER_LOGIN
Always register commands after the addon is fully loaded:

```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" and KOL.RegisterSlashCommand then
        -- Register your commands here
        KOL:RegisterSlashCommand("mycommand", MyFunction, "Description")
    end
end)
```

### 2. Check for KOL
Always verify KOL exists before registering:

```lua
if KOL and KOL.RegisterSlashCommand then
    KOL:RegisterSlashCommand(...)
end
```

### 3. Use Descriptive Names
- ✅ Good: `"reload"`, `"toggle"`, `"show"`
- ❌ Bad: `"r"`, `"t"`, `"s"`

### 4. Provide Clear Descriptions
The description shows in `/kol help`:

```lua
-- ✅ Good
KOL:RegisterSlashCommand("reload", ReloadUI, "Reload the UI")

-- ❌ Bad
KOL:RegisterSlashCommand("reload", ReloadUI, "does stuff")
```

### 5. Handle Missing Arguments
Always validate input:

```lua
KOL:RegisterSlashCommand("scale", function(value)
    local scale = tonumber(value)
    
    if not scale then
        KOL:PrintTag("Usage: /kol scale <number>")
        KOL:PrintTag("Example: /kol scale 1.5")
        return
    end
    
    -- Do something with scale
end, "Set UI scale")
```

---

## Advanced Usage

### Unregister a Command

```lua
KOL:UnregisterSlashCommand("mycommand")
```

### Check if Command Exists

```lua
if KOL.slashCommands["mycommand"] then
    print("Command is registered")
end
```

### List All Registered Commands

```lua
for cmd, data in pairs(KOL.slashCommands) do
    print(cmd .. " - " .. data.description)
end
```

---

## Built-in Commands

These commands are **always available** and don't need registration:

| Command | Description |
|---------|-------------|
| `/kol` or `/kol help` | Show help with all commands |
| `/kol config` | Open configuration panel |
| `/kol debug` | Toggle debug mode |

---

## Command Priority

1. **Registered commands** are checked first
2. **Built-in commands** are checked if no registration found
3. **Unknown command** error if neither exists

This means modules can **override** built-in commands if needed (not recommended).

---

## Help System

When users type `/kol help`, they see:

```
Available commands:
/kol config - Open configuration panel
/kol debug - Toggle debug mode
/kol help - Show this help message

Module Commands:
/kol splash - Show the splash screen
/kol zone - Display current zone information
```

Commands are **automatically sorted alphabetically** in the help display.

---

## Complete Module Example

Here's a complete example of a module with slash commands:

```lua
-- mymodule.lua

local KOL = KoalityOfLife
local MyModule = {}
KOL.mymodule = MyModule

function MyModule:DoSomething()
    KOL:PrintTag("Doing something!")
end

function MyModule:SetValue(value)
    if not value then
        KOL:PrintTag("Usage: /kol setvalue <number>")
        return
    end
    
    local num = tonumber(value)
    if not num then
        KOL:PrintTag(RED("Error:") .. " Value must be a number")
        return
    end
    
    KOL.db.profile.mymodule.value = num
    KOL:PrintTag("Value set to: " .. GREEN(num))
end

-- Register commands on load
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" and KOL.RegisterSlashCommand then
        -- Register multiple commands
        KOL:RegisterSlashCommand("dosomething", function()
            MyModule:DoSomething()
        end, "Do something cool")
        
        KOL:RegisterSlashCommand("setvalue", function(value)
            MyModule:SetValue(value)
        end, "Set a numeric value")
    end
end)
```

---

## Troubleshooting

**Command doesn't work:**
- Check that module is loaded in `.toc`
- Verify registration happens on PLAYER_LOGIN
- Enable debug: `/kol debug`
- Check for Lua errors

**Command not in help:**
- Make sure it's registered before user types `/kol help`
- Check spelling of command name
- Verify description is provided

**Command conflicts:**
- Registration will warn about duplicates
- Last registered command wins
- Check debug output for warnings

---

## API Reference

### KOL:RegisterSlashCommand(command, func, description)
Register a new slash command.

**Parameters:**
- `command` (string) - Command name (lowercase recommended)
- `func` (function) - Function to execute
- `description` (string) - Help text

**Returns:** `boolean` - Success status

**Example:**
```lua
KOL:RegisterSlashCommand("test", function()
    print("Test!")
end, "Run a test")
```

---

### KOL:UnregisterSlashCommand(command)
Remove a registered command.

**Parameters:**
- `command` (string) - Command name

**Returns:** `boolean` - True if command existed

**Example:**
```lua
KOL:UnregisterSlashCommand("test")
```

---

### KOL.slashCommands
Table containing all registered commands.

**Structure:**
```lua
{
    ["commandname"] = {
        func = function,
        description = "string"
    }
}
```

---

## Benefits

✅ **Easy to use** - One function call to register  
✅ **Automatic help** - Commands appear in `/kol help`  
✅ **No conflicts** - Centralized management  
✅ **Module independence** - Each module manages its commands  
✅ **User friendly** - All commands under `/kol`  
✅ **Extensible** - Easy to add new commands  

---

**Now any module can easily add slash commands!** 🎉
