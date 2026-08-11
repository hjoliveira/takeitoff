# TakeItOff

A World of Warcraft addon for version 12.1 (Midnight) that alerts you when specific items are equipped.

## Features

- **Visual Alert**: Displays a customizable warning message (default: "TAKE IT OFF") in large red capital letters centered on your screen when any watched item is equipped
- **Configurable Item List**: Add or remove item IDs to customize which items trigger the alert
- **Settings Panel**: In-game GUI to manage your watch list with drag-and-drop support
- **Custom Warning Text**: Change the warning message to your preference
- **Clickable Item Links**: Item names in chat messages are clickable for easy identification
- **Persistent Storage**: Your configuration is saved between sessions using SavedVariables
- **Automatic Detection**: Checks your equipment on login, UI reload, and whenever you change gear

## Installation

1. Download the latest `TakeItOff.zip` from the [Releases page](https://github.com/hjoliveira/takeitoff/releases)
2. Extract the zip file to your WoW addons directory:
   ```
   World of Warcraft/_retail_/Interface/AddOns/
   ```
3. Restart WoW or reload your UI (`/reload`)

## Commands

| Command | Description |
|---------|-------------|
| `/tio add <itemID>` | Add an item ID to the watch list |
| `/tio remove <itemID>` | Remove an item ID from the watch list |
| `/tio list` | Show all watched items |
| `/tio clear` | Clear all watched items |
| `/tio options` | Open the settings panel |
| `/tio text <message>` | Set a custom warning message |
| `/tio resettext` | Reset warning text to default |
| `/tio debug` | Show debug info and toggle test warning |
| `/tio help` | Show help message |

You can also use `/takeitoff` instead of `/tio`.

## Usage Examples

```
/tio add 19019           -- Add Thunderfury to the watch list
/tio add 32837           -- Add Warglaive of Azzinoth
/tio list                -- View all watched items
/tio remove 19019        -- Remove Thunderfury from the list
/tio clear               -- Remove all items from the list
/tio options             -- Open the settings panel
/tio text "REMOVE GEAR"  -- Set custom warning text
/tio resettext           -- Reset to default "TAKE IT OFF"
/tio debug               -- Show debug info and toggle test warning
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

## Settings Panel

Access the settings panel via `/tio options` or through the WoW AddOns menu (ESC → Options → AddOns → TakeItOff).

The settings panel provides:
- **Custom Warning Text**: Enter a custom message (up to 50 characters) to display instead of the default "TAKE IT OFF"
- **Drag-and-Drop**: Drag items directly from your inventory to add them to the watch list
- **Visual Item List**: See all watched items with icons and clickable item links
- **Remove Buttons**: Easily remove individual items from the list
- **Clear All**: Remove all items at once

## Running Tests

The addon includes unit tests using [busted](https://github.com/lunarmodules/busted), a Lua testing framework.

### Prerequisites

Install Lua 5.1 and busted (Debian/Ubuntu):

```bash
sudo apt-get update && sudo apt-get install -y lua5.1 lua-busted
```

### Running the Tests

From the repository root directory:

```bash
busted tests/TakeItOff_spec.lua
```

Or run all tests:

```bash
busted
```

### Test Coverage

The tests cover:
- Addon initialization and database setup
- Slash commands (add, remove, list, clear, test, text, resettext, debug)
- Equipment detection across all 18 equipment slots
- Warning frame display and styling
- Event handling (ADDON_LOADED, PLAYER_ENTERING_WORLD, PLAYER_EQUIPMENT_CHANGED)
- Settings panel functionality
