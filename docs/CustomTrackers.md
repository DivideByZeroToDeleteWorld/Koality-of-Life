# Custom Trackers

> **Status:** Work in Progress (WIP)

Custom Trackers allow you to create your own tracking panels to monitor kills, loot, boss yells, and more. This is useful for tracking progress on custom objectives that aren't covered by the built-in dungeon/raid tracker.

## Opening the Tracker Manager

1. Type `/kol config` to open the main options panel
2. Navigate to **Progress Tracker** > **Custom Panels**
3. Click **Manage Custom Tracker** to open the Tracker Manager

Or use the slash command: `/kol tracker manage`

## Tracker Manager Overview

The Tracker Manager is where you create and edit custom tracking panels. It has several sections:

### Panel Settings (Top Row)

| Field | Description |
|-------|-------------|
| **Name** | The display name for your tracker panel |
| **Zones** | Comma-separated list of zone names where this tracker should auto-show. Leave blank to show in ALL zones |
| **Title Color** | The color of the panel title (Pink, Red, Orange, Yellow, Green, Cyan, Blue, Purple, White, or Pastel variants) |

### Groups Section

Groups let you organize entries within your tracker panel. For example, you might have groups like "Bosses", "Trash", "Collectibles", etc.

- **Group Name** - Enter a name and click **ADD GROUP**
- Groups can be reordered using the up/down arrows
- Click **EDIT** to rename a group
- Click **DEL** to delete a group (entries in that group become ungrouped)

### Entries Section

Entries are the individual objectives you want to track.

## Entry Types

### Kill (NPC)
Track when a specific NPC is killed.

| Field | Description |
|-------|-------------|
| **Name** | Display name (e.g., "Lich King") |
| **NPC ID** | The numeric NPC ID from the game |
| **Group** | Optional group assignment |
| **Count** | Number of kills required (default: 1) |

**How to find NPC IDs:**
- Use `/kol debug` to enable debug mode, then target the NPC
- Check WoWHead or similar databases
- Use the Boss Recorder feature to capture IDs during encounters

### Loot (Item)
Track when a specific item is looted.

| Field | Description |
|-------|-------------|
| **Name** | Display name (e.g., "Shadowmourne") |
| **Item ID** | The numeric item ID |
| **Group** | Optional group assignment |
| **Count** | Number of items required (default: 1) |

**How to find Item IDs:**
- Shift-click an item link and look at the URL
- Check WoWHead or similar databases
- Item IDs are in the format: `item:12345:0:0:0:0:0:0:0`

### Yell
Track when a boss yells specific text (useful for phase transitions or boss spawns).

| Field | Description |
|-------|-------------|
| **Name** | Display name (e.g., "Phase 2 Start") |
| **Yell text** | Text to match in monster yells (partial match) |
| **Group** | Optional group assignment |

**Example yell texts:**
- "Suffer, mortals" (Lich King transition)
- "I will freeze the blood in your veins" (Sindragosa)

### Multi-Kill
Track multiple NPCs that must all be killed (like council fights).

| Field | Description |
|-------|-------------|
| **Name** | Display name (e.g., "Blood Council") |
| **IDs (csv)** | Comma-separated list of NPC IDs |
| **Group** | Optional group assignment |

**Example:** For the Blood Princes, you'd enter: `37970,37972,37973`

## Managing Entries

- **ADD** - Creates a new entry with the current field values
- **UP/DOWN arrows** - Reorder entries within the list
- **EDIT** - Load an entry's values back into the input fields for editing
- **DEL** - Delete an entry

## Auto-Save

Changes are automatically saved as you make them. You don't need to click a save button.

## Panel Display

Once you've created a custom tracker:

1. The panel will appear as a draggable frame on your screen
2. It shows in zones matching your Zones filter (or all zones if blank)
3. Completed objectives show with a checkmark
4. Progress is tracked per-character in your saved variables

## Tips

1. **Test in the right zone** - If you set specific zones, make sure you're in one of them to see the panel
2. **Use groups** - Organizing entries into groups makes large trackers easier to read
3. **Partial yell matching** - Yell detection uses partial text matching, so you don't need the exact full text
4. **Count objectives** - Set count > 1 for objectives that require multiple completions (e.g., "Kill 10 Ghouls")

## Resetting Progress

To reset progress on a custom tracker:
1. Open the tracker manager
2. The reset happens automatically when you re-enter an instance (for dungeon/raid trackers)
3. For custom panels, you may need to manually reset via `/kol tracker reset <panelname>`

## Troubleshooting

**Panel not showing:**
- Check that you're in a zone matching the Zones filter
- Make sure the panel has at least one entry
- Try `/reload` to refresh the UI

**Kills not tracking:**
- Verify the NPC ID is correct using debug mode
- Make sure you're in combat log range when the kill happens
- Check that the entry type is "Kill" not "Yell"

**Yells not detecting:**
- Enable debug mode to see what yell text is being received
- Use shorter, unique phrases for better matching
- Remember yells are case-sensitive

---

*This feature is under active development. Please report bugs and suggestions!*
