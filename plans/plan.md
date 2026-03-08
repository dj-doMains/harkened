# Harkened - WoW Addon Build Plan

## Overview
"Harkened" is a World of Warcraft addon (targeting patch 12.0.1) that monitors
configured chat channels for keyword mentions and plays a configurable alert
sound. It is fully configurable via a settings panel and a `/hark` slash command.

---

## Reference Documentation
- API: https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
- Events: https://warcraft.wiki.gg/wiki/Events
- Widget API: https://warcraft.wiki.gg/wiki/Widget_API
- HOWTOs: https://warcraft.wiki.gg/wiki/HOWTOs

---

## Tech Stack
- **Language:** Lua (WoW addon environment)
- **UI Framework:** Blizzard's built-in Settings API (10.0.0+, current in 12.0.1)
- **Persistence:** `SavedVariables` declared in .toc, initialized on `ADDON_LOADED`

---

## Key API Surface

### Event Handling
```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("EVENT_NAME")
frame:SetScript("OnEvent", function(self, event, ...)
    -- ...
end)
```

### Chat Events to Monitor
All share the same 17-argument payload; argument 1 is `text` (the message string):
| Event | Channel |
|---|---|
| `CHAT_MSG_GUILD` | Guild |
| `CHAT_MSG_PARTY` | Party (member) |
| `CHAT_MSG_PARTY_LEADER` | Party (leader) |
| `CHAT_MSG_INSTANCE_CHAT` | Instance / LFG group |
| `CHAT_MSG_INSTANCE_CHAT_LEADER` | Instance / LFG group (leader) |

Full payload (in order):
`text, playerName, languageName, channelName, playerName2, specialFlags,
zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid,
bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons`

### Sound Playback
```lua
-- channel options: "Master", "SFX", "Music", "Ambience", "Dialog"
PlaySound(soundKitID [, channel, forceNoDuplicates, runFinishCallback])

-- Examples using the global SOUNDKIT table:
PlaySound(SOUNDKIT.READY_CHECK, "Master")
PlaySound(SOUNDKIT.UI_BATTLEGROUND_COUNTDOWN_FINISHED, "Master")
```

### Settings Panel (10.0.0+ API)
```lua
-- Vertical layout (auto-positioned, native look)
local category, layout = Settings.RegisterVerticalLayoutCategory("Harkened")
Settings.RegisterAddOnCategory(category)

-- Register a setting
local setting = Settings.RegisterAddOnSetting(
    category, variableKey, variableKey, HarkenedDB, type(defaultValue), displayName, defaultValue
)
-- Add a control
Settings.CreateCheckbox(category, setting, tooltip)
Settings.CreateSlider(category, setting, Settings.CreateSliderOptions(min, max, step), tooltip)
Settings.CreateDropdown(category, setting, initFunction, tooltip)
```

### Slash Commands
```lua
SLASH_HARKENED1 = "/hark"
SLASH_HARKENED2 = "/harkened"
SlashCmdList.HARKENED = function(msg, editBox)
    -- parse msg for sub-commands
end
```

### SavedVariables (.toc)
```
## SavedVariablesPerCharacter: HarkenedDB
```
Initialized on `ADDON_LOADED` — check for nil and assign defaults.
Settings are stored per-character, so each character can have independent
keywords, channels, sound, and throttle preferences.

---

## Addon File Structure
```
Harkened/
  Harkened.toc      -- Manifest: metadata, Interface version, SavedVariables, file list
  Core.lua          -- Addon frame, ADDON_LOADED handler, SavedVariables defaults
  Chat.lua          -- Chat event registration and keyword matching
  Sound.lua         -- PlaySound wrapper with throttle logic
  Config.lua        -- Settings panel (Settings API) + slash command
  Locales/
    enUS.lua        -- All user-facing strings
```
Load order in .toc: `Locales/enUS.lua`, `Core.lua`, `Sound.lua`, `Chat.lua`, `Config.lua`

---

## Default Configuration (`HarkenedDB`)
```lua
{
    enabled  = true,
    keywords = { "YourName" },       -- list of strings to match (case-insensitive)
    soundID  = SOUNDKIT.READY_CHECK, -- numeric SoundKitID from SOUNDKIT table
    channels = {
        GUILD         = true,
        PARTY         = true,
        INSTANCE_CHAT = true,
        RAID          = true,
    },
    throttle = 120,  -- minimum seconds between alerts (0 = no throttle)
}
```

---

## Incremental Build Milestones

---

### Milestone 1 — Skeleton & Scaffold
**Goal:** A valid addon that loads in WoW without errors.

Tasks:
- [ ] Create `Harkened.toc` with:
  - `## Interface: 120001` (patch 12.0.1)
  - `## Title: Harkened`
  - `## SavedVariablesPerCharacter: HarkenedDB`
  - File list in load order
- [ ] Create `Locales/enUS.lua` — empty `HarkenedLocale` table stub
- [ ] Create `Core.lua` — create addon frame, listen for `ADDON_LOADED`, print
      `"Harkened loaded."` to confirm

**Acceptance:** Addon appears in the AddOns list; no Lua errors on login; message
visible in chat.

---

### Milestone 2 — SavedVariables & Defaults
**Goal:** Persist configuration across sessions with safe default initialization.

Tasks:
- [ ] Define `HARKENED_DEFAULTS` table in `Core.lua` (see Default Configuration above)
- [ ] In `ADDON_LOADED` handler, check `addOnName == "Harkened"` before acting
- [ ] Deep-merge `HarkenedDB` with `HARKENED_DEFAULTS`: new keys get defaults,
      existing user values are preserved
- [ ] Expose `Harkened.db` as the single access point for settings throughout
      the addon (alias to `HarkenedDB`)

**Acceptance:** Changing `Harkened.db.throttle` to 60, doing `/reload`, and
checking the value still shows 60. Adding a new default key in code populates
it on reload without resetting other values.

---

### Milestone 3 — Chat Monitoring & Keyword Matching
**Goal:** Detect keyword mentions across configured channels.

Tasks:
- [ ] Create `Chat.lua`
- [ ] Build a channel-to-event map:
  ```lua
  local CHANNEL_EVENTS = {
      GUILD         = { "CHAT_MSG_GUILD" },
      PARTY         = { "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER" },
      INSTANCE_CHAT = { "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER" },
      RAID          = { "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER" },
  }
  ```
- [ ] On `ADDON_LOADED`, register only the events for channels that are enabled
- [ ] Provide `Harkened:RefreshChatEvents()` to re-register events when channel
      settings change (unregister all then re-register based on current `db.channels`)
- [ ] In the event handler:
  1. Guard: `if not Harkened.db.enabled then return end`
  2. Extract `text` (first vararg)
  3. Loop keywords, case-insensitive plain search:
     `text:lower():find(kw:lower(), 1, true)`
  4. On match: call `Harkened:TriggerAlert()` (stubbed print for now) and break

**Acceptance:** Sending a message containing a keyword in a watched channel
triggers the stub print. Messages in disabled channels are ignored.

---

### Milestone 4 — Sound Alerts with Throttle
**Goal:** Play a configurable sound on keyword match; prevent spam with throttle.

Tasks:
- [ ] Create `Sound.lua`
- [ ] Track `Harkened.lastAlertTime = 0`
- [ ] Implement `Harkened:TriggerAlert()`:
  ```lua
  function Harkened:TriggerAlert()
      local now = GetTime()
      if now - self.lastAlertTime < self.db.throttle then return end
      self.lastAlertTime = now
      PlaySound(self.db.soundID, "Master")
  end
  ```
- [ ] Define available sounds list (displayed in Config UI):
  ```lua
  Harkened.SOUNDS = {
      { label = "Ready Check",       id = SOUNDKIT.READY_CHECK },
      { label = "Tell / Whisper",    id = SOUNDKIT.TELL_MESSAGE },
      { label = "Battleground Start",id = SOUNDKIT.UI_BATTLEGROUND_COUNTDOWN_FINISHED },
      { label = "Level Up",          id = SOUNDKIT.LEVEL_UP },
      { label = "Quest Complete",    id = SOUNDKIT.QUEST_COMPLETE },
      { label = "Loot Window Open",  id = SOUNDKIT.LOOT_WINDOW_OPEN_KEYRING },
  }
  ```
  Note: Confirm exact SOUNDKIT key names in-game via `/dump SOUNDKIT` or the
  warcraft.wiki.gg SOUNDKIT page before finalizing.

**Acceptance:** Keyword match plays the configured sound. Triggering again within
the throttle window is silently ignored. Triggering after the window plays again.

---

### Milestone 5 — Configuration UI
**Goal:** A native-looking settings panel accessible from the game's Settings >
AddOns tab.

Tasks:
- [ ] Create `Config.lua`
- [ ] Register using the vertical layout API:
  ```lua
  local category, layout = Settings.RegisterVerticalLayoutCategory(L["Harkened"])
  Settings.RegisterAddOnCategory(category)
  ```
- [ ] Add controls in this order:
  1. **Enable toggle** — `Settings.CreateCheckbox` bound to `db.enabled`
  2. **Sound dropdown** — `Settings.CreateDropdown` iterating `Harkened.SOUNDS`;
     stores selected `id` into `db.soundID`; includes a "Test" button beside it
  3. **Channels section** — one `Settings.CreateCheckbox` per channel key
     (`GUILD`, `PARTY`, `INSTANCE_CHAT`, `RAID`); on change call `Harkened:RefreshChatEvents()`
  4. **Throttle slider** — `Settings.CreateSlider` with
     `Settings.CreateSliderOptions(0, 600, 5)`; label shows current value in seconds
  5. **Keywords EditBox** — Canvas layout sub-frame (vertical layout doesn't
     support free-form EditBox natively); one keyword per line; Save button
     parses lines into `db.keywords`, deduplicates, trims whitespace

**Acceptance:** All controls reflect current `HarkenedDB` values on open.
Changing and closing persists values after `/reload`.

---

### Milestone 6 — `/hark` Slash Command
**Goal:** Chat-based access to settings and quick controls.

Tasks:
- [ ] Register in `Config.lua` (after category is created):
  ```lua
  SLASH_HARKENED1 = "/hark"
  SLASH_HARKENED2 = "/harkened"
  SlashCmdList.HARKENED = function(msg, editBox)
      Harkened:HandleSlashCommand(msg)
  end
  ```
- [ ] Implement `Harkened:HandleSlashCommand(msg)` with sub-commands:
  | Input | Action |
  |---|---|
  | *(empty)* | Open Settings panel via `Settings.OpenToCategory(category)` |
  | `on` | Set `db.enabled = true`, confirm in chat |
  | `off` | Set `db.enabled = false`, confirm in chat |
  | `add <word>` | Append keyword, deduplicate, confirm |
  | `remove <word>` | Remove keyword if present, confirm |
  | `test` | Call `Harkened:TriggerAlert()` bypassing throttle |
  | `status` | Print current config summary to chat |
  | anything else | Print usage help |

**Acceptance:** `/hark` opens the panel. All sub-commands update state and print
confirmation. `/hark test` plays the sound immediately regardless of throttle.

---

### Milestone 7 — Polish & Edge Cases
**Goal:** Production-quality hardening.

Tasks:
- [ ] Populate `Locales/enUS.lua` with all user-facing strings; replace
      hardcoded strings throughout with `L["key"]` lookups
- [ ] Validate and clamp settings on load:
  - `throttle`: clamp to `[0, 3600]`
  - `keywords`: strip empty strings, deduplicate, trim whitespace
  - `soundID`: fall back to `SOUNDKIT.READY_CHECK` if value is nil/invalid
- [ ] Add tooltips to all Settings panel controls
- [ ] Handle the case where `ADDON_LOADED` fires before `SOUNDKIT` is populated
      (defer sound list initialization to `PLAYER_LOGIN` if needed)
- [ ] Test keyword matching edge cases: empty keyword list, single-char keywords,
      keywords with special Lua pattern characters (use plain `find`, not pattern)
- [ ] Verify `.toc` Interface number matches current live patch

**Acceptance:** No Lua errors under all normal and edge-case flows. All strings
go through the locale table.

---

## Decisions
1. **Raid chat** — included as a configurable channel (`CHAT_MSG_RAID`, `CHAT_MSG_RAID_LEADER`)
2. **Visible chat message** — sound only, no chat print
3. **SavedVariables scope** — per-character via `SavedVariablesPerCharacter`
