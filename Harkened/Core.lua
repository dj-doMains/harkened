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
            Harkened:InitSlash()
            print("|cff00ccffHarkened|r loaded.")
        end
    end
end)
