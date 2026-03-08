local CHANNEL_EVENTS = {
    GUILD         = { "CHAT_MSG_GUILD" },
    PARTY         = { "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER" },
    INSTANCE_CHAT = { "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER" },
    RAID          = { "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER" },
}

-- Flat list of every event we may ever register, for clean unregistration
local ALL_EVENTS = {}
for _, events in pairs(CHANNEL_EVENTS) do
    for _, event in ipairs(events) do
        ALL_EVENTS[#ALL_EVENTS + 1] = event
    end
end

local chatFrame = CreateFrame("Frame")

local function onChatMessage(_, _, ...)
    if not Harkened.db.enabled then return end

    local text = ...  -- first payload argument is the message text

    for _, keyword in ipairs(Harkened.db.keywords) do
        if text:lower():find(keyword:lower(), 1, true) then
            Harkened:TriggerAlert()
            return
        end
    end
end

function Harkened:RefreshChatEvents()
    -- Unregister every possible chat event first
    for _, event in ipairs(ALL_EVENTS) do
        chatFrame:UnregisterEvent(event)
    end

    -- Re-register only events for enabled channels
    for channel, events in pairs(CHANNEL_EVENTS) do
        if self.db.channels[channel] then
            for _, event in ipairs(events) do
                chatFrame:RegisterEvent(event)
            end
        end
    end
end

chatFrame:SetScript("OnEvent", onChatMessage)

-- Called from Core.lua after initDB()
function Harkened:InitChat()
    self:RefreshChatEvents()
end
