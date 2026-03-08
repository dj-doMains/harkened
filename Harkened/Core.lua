Harkened = {}

local function initDB()
    HarkenedDB = HarkenedDB or {}
    local db = HarkenedDB

    -- Top-level defaults
    if db.enabled  == nil then db.enabled  = true end
    if db.keywords == nil then db.keywords = { UnitName("player") or "YourName" } end
    if db.soundID  == nil then db.soundID  = SOUNDKIT.READY_CHECK end
    if db.throttle == nil then db.throttle = 120 end

    -- Nested channel defaults
    if db.channels == nil then db.channels = {} end
    if db.channels.GUILD         == nil then db.channels.GUILD         = true end
    if db.channels.PARTY         == nil then db.channels.PARTY         = true end
    if db.channels.INSTANCE_CHAT == nil then db.channels.INSTANCE_CHAT = true end
    if db.channels.RAID          == nil then db.channels.RAID          = true end

    Harkened.db = db
end

-- Dev tool: /hark dumpsounds
-- Iterates SOUNDKIT, saves all valid int32 IDs to HarkenedDB.soundDump, then
-- instructs the user to log out so WoW flushes SavedVariables to disk.
function Harkened:DumpSounds()
    local INT32_MAX = 2147483647
    local results = {}
    for k, v in pairs(SOUNDKIT) do
        if type(v) == "number" and v > 0 and v <= INT32_MAX then
            results[#results + 1] = { name = k, id = v }
        end
    end
    table.sort(results, function(a, b) return a.name < b.name end)
    self.db.soundDump = results
    print("|cff00ccffHarkened|r Sound dump saved: " .. #results .. " valid sounds.")
    print("|cff00ccffHarkened|r Log out (don't reload) to write to disk.")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addOnName = ...
        if addOnName == "Harkened" then
            self:UnregisterEvent("ADDON_LOADED")
            initDB()
            Harkened:InitSounds()
            Harkened:InitChat()
            -- Temporary slash command until Config.lua slash handler is built (Milestone 6)
            SLASH_HARKENED1 = "/hark"
            SlashCmdList.HARKENED = function(msg)
                if msg == "dumpsounds" then
                    Harkened:DumpSounds()
                end
            end
            print("|cff00ccffHarkened|r loaded.")
        end
    end
end)
