# TakeItOff

A World of Warcraft addon for version 12.0 (Midnight) that alerts you when specific items are equipped.

## Features

- **Visual Alert**: Displays "TAKE IT OFF" in large red capital letters centered on your screen when any watched item is equipped
- **Configurable Item List**: Add or remove item IDs to customize which items trigger the alert
- **Persistent Storage**: Your configuration is saved between sessions using SavedVariables
- **Automatic Detection**: Checks your equipment on login, UI reload, and whenever you change gear

## Installation

1. Download or clone this repository
2. Copy the `TakeItOff` folder to your WoW addons directory:
   ```
   World of Warcraft/_retail_/Interface/AddOns/TakeItOff/
   ```
3. Restart WoW or reload your UI (`/reload`)

## Commands

| Command | Description |
|---------|-------------|
| `/tio add <itemID>` | Add an item ID to the watch list |
| `/tio remove <itemID>` | Remove an item ID from the watch list |
| `/tio list` | Show all watched items |
| `/tio clear` | Clear all watched items |
| `/tio test` | Toggle the warning display for testing |
| `/tio help` | Show help message |

You can also use `/takeitoff` instead of `/tio`.

## Usage Examples

```
/tio add 19019       -- Add Thunderfury to the watch list
/tio add 32837       -- Add Warglaive of Azzinoth
/tio list            -- View all watched items
/tio remove 19019    -- Remove Thunderfury from the list
/tio clear           -- Remove all items from the list
/tio test            -- Test the warning display
```

## Finding Item IDs

You can find item IDs on [Wowhead](https://www.wowhead.com). The item ID is the number in the URL:
- `https://www.wowhead.com/item=19019` → Item ID is `19019`

Alternatively, you can use the `/dump` command in-game while hovering over an item.

## Use Cases

- Remind yourself to remove fishing gear before entering combat
- Alert when wearing outdated equipment
- Warn about items that should only be used in specific situations
- Prevent accidentally wearing cosmetic items in raids
