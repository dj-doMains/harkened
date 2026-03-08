# Harkened

A World of Warcraft addon that plays a sound alert when your name (or any configured keyword) is mentioned in chat.

## Features

- Monitors Guild, Party, Instance, and Raid chat channels
- Configurable keyword list — alerts on any word or phrase, not just your name
- Searchable sound picker with a curated preset list or the full SOUNDKIT library
- Per-character settings saved between sessions
- Throttle control to prevent alert spam
- Ignores your own messages, including those prepended by addons like Incognito

## Installation

1. Download or clone this repository
2. Copy the `Harkened` folder into your WoW AddOns directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\Harkened
   ```
3. Launch WoW (or type `/reload` if already in-game)
4. Enable the addon from the AddOns list on the character select screen

## Configuration

Open the settings panel from the WoW Settings menu under **Harkened**, or use the slash command `/hark`.

| Setting | Description |
|---|---|
| Enable Harkened | Master on/off toggle |
| Alert Sound | Choose a sound from the curated list or search all available sounds |
| Show all sounds | Expands the sound picker to the full SOUNDKIT library |
| Preview | Plays the currently selected sound |
| Monitor Channels | Choose which chat channels trigger alerts |
| Seconds between alerts | Minimum time between alerts to avoid repeated triggers |
| Keywords | One keyword or phrase per line; case-insensitive |

## Slash Commands

| Command | Description |
|---|---|
| `/hark` | Open the settings panel |
| `/hark on` | Enable the addon |
| `/hark off` | Disable the addon |
| `/hark add <word>` | Add a keyword |
| `/hark remove <word>` | Remove a keyword |
| `/hark test` | Play the current alert sound |
| `/hark status` | Print current settings to chat |

Both `/hark` and `/harkened` are registered as aliases.

## Compatibility

- WoW Retail (patch 12.0.1+)
- Settings stored per character via `SavedVariablesPerCharacter`
- Compatible with Incognito and other addons that modify chat sender display names
