# 🌟 Splash Screen Feature

## What It Does

When you log in, Koality of Life now displays a beautiful splash screen with your logo for 2 seconds!

## Features

✅ **Professional Appearance**
- Centered on screen
- Black border/background
- Clean, polished look

✅ **Smooth Animation**
- Fades in when you log in
- Holds for 2 seconds
- Smoothly fades out over 0.5 seconds

✅ **Version Display**
- Shows addon version in rainbow colors
- Located at bottom of splash

✅ **Non-Intrusive**
- Only shows on PLAYER_LOGIN
- Automatically disappears
- Doesn't block gameplay

## File Structure

```
Koality-of-Life/
├── splash.lua              # Splash screen code
└── media/
    └── kol-splash.tga      # Your logo (TGA format)
```

## Customization

### Change Duration
Edit `splash.lua`, line 6:
```lua
local SPLASH_DURATION = 2 -- Change to desired seconds
```

### Change Size
Edit `splash.lua`, lines 13-14:
```lua
splash:SetSize(512, 512) -- Frame size
logo:SetSize(480, 480)   # Logo size (slightly smaller for border)
```

### Change Position
Edit `splash.lua`, line 15:
```lua
splash:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
-- Format: ("ANCHOR", parent, "PARENT_ANCHOR", x_offset, y_offset)
```

### Disable Splash
Comment out or remove `splash.lua` from your `.toc` file.

## Technical Details

**Image Format:** TGA (Targa)
- WoW requires TGA format for textures
- No compression needed
- Power-of-2 dimensions recommended (256x256, 512x512, etc.)

**Animation:**
- Uses WoW's animation system
- Fade out starts at 1.5 seconds (0.5s before end)
- Smooth alpha transition

**Loading:**
- Loads early via `.toc` placement
- Shows 0.5s after PLAYER_LOGIN
- Only shows once per session

## Troubleshooting

**Splash doesn't show:**
- Check that `media/kol-splash.tga` exists
- Verify `splash.lua` is loaded in `.toc`
- Enable Lua errors: `/console scriptErrors 1`

**Image looks wrong:**
- TGA must be in correct format (24-bit or 32-bit)
- Check image dimensions
- Verify path: `Interface\\AddOns\\Koality-of-Life\\media\\kol-splash`

**Splash shows too long/short:**
- Adjust `SPLASH_DURATION` variable
- Remember: Fade starts 0.5s before end

## Future Enhancements

Possible additions:
- Configurable on/off in settings
- Different splash for different characters
- Animation effects (zoom, glow, etc.)
- Sound effect on display
- Click to dismiss

---

**Enjoy your professional addon splash screen!** 🎨✨
