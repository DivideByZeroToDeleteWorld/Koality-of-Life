# 🎣 Fishing Module - Phantom Ghostfish Auto-Use

## 📌 Version: 0.0.7.42 (+1)

### ✨ New Module: Fishing

Automatically uses Phantom Ghostfish and cancels the Invisibility buff!

---

## 🎯 How It Works:

### 1. **Detects Phantom Ghostfish**
   - Watches your bags continuously
   - When Phantom Ghostfish (ID: 45902) is looted
   - Automatically uses it!

### 2. **Waits 1 Second**
   - Fish is used → You become invisible
   - Module waits exactly 1.0 second

### 3. **Cancels Invisibility**
   - Finds Invisibility buff (ID: 32612)
   - Cancels it automatically
   - You're visible again!

---

## 🔧 Technical Details:

### Safe & Legal:
✅ **Using items** - `UseItemByName()` is allowed (like eating food)  
✅ **Canceling buffs** - `CancelUnitBuff()` is allowed  
✅ **Only works out of combat** - Respects Blizzard protection  

### How It Detects:
- **BAG_UPDATE** event triggers when you loot fish
- Scans all 5 bags for item ID 45902
- Uses `UseItemByName("Phantom Ghostfish")`

### How It Cancels:
- Records time when fish is used
- OnUpdate loop checks elapsed time
- After 1 second, scans player buffs
- Finds Invisibility by name or ID 32612
- Calls `CancelUnitBuff("player", buffIndex)`

---

## ⚙️ Configuration:

Open `/kol config` → **Fishing** section

**Options:**
1. ✅ **Enable Fishing Module** - Master toggle
2. ✅ **Auto-Use Ghostfish** - Automatically use when found
3. ✅ **Auto-Cancel Invisibility** - Cancel buff after 1 second
4. 🔘 **Test Button** - Manually check for Ghostfish

---

## 🎮 Usage:

### Automatic (Default):
1. Loot Phantom Ghostfish
2. Module uses it automatically
3. Wait 1 second
4. Invisibility canceled!

### Manual Control:
- Disable "Auto-Use" to just get notifications
- Disable "Auto-Cancel" to keep Invisibility
- Use test button to manually trigger

---

## 📦 Contains:

- **modules/fishing.lua** - Complete fishing module
- **Koality-of-Life.toc** - Updated load order

---

## 🧪 Testing:

```
/reload
/kol config  → Check "Fishing" section
Enable all options
Loot a Phantom Ghostfish
Watch it work!
```

**Debug mode:**
```
/kol debug
```
You'll see:
- "Using Phantom Ghostfish..."
- "Canceled Invisibility buff"

---

## 🔍 How The Code Works:

### BAG_UPDATE Flow:
```
Loot Ghostfish
    ↓
BAG_UPDATE event fires
    ↓
CheckForGhostfish() scans bags
    ↓
Found item 45902!
    ↓
UseItemByName("Phantom Ghostfish")
    ↓
Record fishUsedTime = GetTime()
    ↓
Set waitingToCancel = true
```

### OnUpdate Flow:
```
Every frame (continuous)
    ↓
CheckInvisibility()
    ↓
Is waitingToCancel = true?
    ↓
Has 1 second elapsed?
    ↓
FindInvisibilityBuff()
    ↓
Found buff ID 32612?
    ↓
CancelUnitBuff("player", index)
    ↓
Set waitingToCancel = false
```

---

## ⚠️ Important Notes:

1. **Only works OUT of combat** - Item use is protected in combat
2. **1 second delay is precise** - Uses GetTime() for accuracy
3. **Timeout after 3 seconds** - If buff doesn't appear, gives up
4. **Only cancels in this scenario** - Won't cancel Invisibility from other sources

---

## 💡 Future Enhancements:

Possible additions:
- Configurable delay (instead of fixed 1 second)
- Sound notification when used
- Count of fish used per session
- Automatic re-cast fishing when invisible canceled

---

**Your Ghostfish will never make you invisible again!** 🎣✨
