Harkened.lastAlertTime = 0
Harkened.SOUNDS = {}

-- PlaySound requires a signed 32-bit integer
local INT32_MIN, INT32_MAX = -2147483648, 2147483647

local function isValidSoundID(id)
    return type(id) == "number" and id > 0 and id >= INT32_MIN and id <= INT32_MAX
end

-- Curated preset list (numeric IDs, pre-validated from SOUNDKIT dump)
local CURATED = {
    { label = "Ready Check",             id = 8960  },
    { label = "Raid Warning",            id = 8959  },
    { label = "Tell / Whisper",          id = 3081  },
    { label = "GM Chat Warning",         id = 15273 },
    { label = "Alarm Clock 1",           id = 18871 },
    { label = "Alarm Clock 2",           id = 12867 },
    { label = "Alarm Clock 3",           id = 12889 },
    { label = "Group Invite",            id = 880   },
    { label = "Battle.net Toast",        id = 18019 },
    { label = "Map Ping",                id = 3175  },
    { label = "Tutorial Popup",          id = 7355  },
    { label = "Quest Session Ready",     id = 139828},
    { label = "Notification Warning",    id = 188250},
}

function Harkened:InitSounds()
    -- Curated list: validate each hardcoded ID just in case patches change values
    self.SOUNDS = {}
    for _, sound in ipairs(CURATED) do
        if isValidSoundID(sound.id) then
            self.SOUNDS[#self.SOUNDS + 1] = sound
        end
    end

    -- Full list: iterate entire SOUNDKIT table, validate, sort alphabetically
    self.ALL_SOUNDS = {}
    for k, v in pairs(SOUNDKIT) do
        if isValidSoundID(v) then
            self.ALL_SOUNDS[#self.ALL_SOUNDS + 1] = { label = k, id = v }
        end
    end
    table.sort(self.ALL_SOUNDS, function(a, b) return a.label < b.label end)
end

-- force=true bypasses the throttle (used by /hark test)
function Harkened:TriggerAlert(force)
    local now = GetTime()
    if not force and (now - self.lastAlertTime < self.db.throttle) then return end
    if not isValidSoundID(self.db.soundID) then return end
    self.lastAlertTime = now
    PlaySound(self.db.soundID, "Master")
end
