-- ── Panel registration ────────────────────────────────────────────────────

local panel = CreateFrame("Frame")
local category = Settings.RegisterCanvasLayoutCategory(panel, "Harkened")
Settings.RegisterAddOnCategory(category)
Harkened.settingsCategory = category  -- used by slash command (Milestone 6)

-- ── Layout helpers ────────────────────────────────────────────────────────

local function sectionHeader(text, yOffset)
    local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    fs:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, yOffset)
    fs:SetText(text)
    return fs
end

local function inlineLabel(text, yOffset)
    local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, yOffset)
    fs:SetText(text)
    return fs
end

local function createCheckbox(parent, labelText, x, yOffset)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, yOffset)
    local lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    lbl:SetText(labelText)
    return cb
end

-- ── Enable ────────────────────────────────────────────────────────────────

local enableCB = createCheckbox(panel, "Enable Harkened", 8, -8)
enableCB:SetScript("OnClick", function(self)
    Harkened.db.enabled = self:GetChecked()
end)

-- ── Sound ─────────────────────────────────────────────────────────────────

sectionHeader("Alert Sound", -46)

local showAllSounds = false
local refreshSoundDropdown  -- forward declared; assigned below

-- Sound selector button — opens the picker popup
local soundSelectorBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
soundSelectorBtn:SetSize(196, 22)
soundSelectorBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -66)
soundSelectorBtn:GetFontString():SetWidth(176)

-- Scrollable sound picker popup
local soundPicker = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
soundPicker:SetSize(300, 340)
soundPicker:SetFrameStrata("DIALOG")
soundPicker:SetBackdrop({
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
})
soundPicker:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
soundPicker:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
soundPicker:Hide()

local pickerSearch = CreateFrame("EditBox", nil, soundPicker, "InputBoxTemplate")
pickerSearch:SetSize(266, 20)
pickerSearch:SetPoint("TOPLEFT", soundPicker, "TOPLEFT", 12, -12)
pickerSearch:SetAutoFocus(false)
pickerSearch:SetMaxLetters(64)

local pickerScroll = CreateFrame("ScrollFrame", nil, soundPicker, "UIPanelScrollFrameTemplate")
pickerScroll:SetPoint("TOPLEFT",     pickerSearch, "BOTTOMLEFT",      0,  -8)
pickerScroll:SetPoint("BOTTOMRIGHT", soundPicker,  "BOTTOMRIGHT",   -28,   8)

local pickerContent = CreateFrame("Frame", nil, pickerScroll)
pickerContent:SetWidth(256)
pickerScroll:SetScrollChild(pickerContent)

local pickerButtons = {}

local function populatePicker(filter)
    filter = (filter or ""):lower()
    local list = showAllSounds and Harkened.ALL_SOUNDS or Harkened.SOUNDS
    local y, count = 0, 0
    for _, sound in ipairs(list) do
        if filter == "" or sound.label:lower():find(filter, 1, true) then
            count = count + 1
            local btn = pickerButtons[count]
            if not btn then
                btn = CreateFrame("Button", nil, pickerContent)
                btn:SetHeight(20)
                btn:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight", "ADD")
                local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                fs:SetPoint("LEFT",  btn, "LEFT",  4, 0)
                fs:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
                fs:SetJustifyH("LEFT")
                btn.fs = fs
                pickerButtons[count] = btn
            end
            btn:SetPoint("TOPLEFT", pickerContent, "TOPLEFT", 0, -y)
            btn:SetWidth(256)
            btn.fs:SetText(sound.label)
            btn.fs:SetTextColor(sound.id == Harkened.db.soundID and 1   or 0.9,
                                sound.id == Harkened.db.soundID and 0.82 or 0.9,
                                sound.id == Harkened.db.soundID and 0   or 0.9)
            local sid, slabel = sound.id, sound.label
            btn:SetScript("OnClick", function()
                Harkened.db.soundID = sid
                soundSelectorBtn:SetText(slabel)
                soundPicker:Hide()
            end)
            btn:Show()
            y = y + 20
        end
    end
    for i = count + 1, #pickerButtons do pickerButtons[i]:Hide() end
    pickerContent:SetHeight(math.max(y, 1))
end

pickerSearch:SetScript("OnTextChanged", function(self)
    populatePicker(self:GetText())
end)
pickerSearch:SetScript("OnEscapePressed", function()
    soundPicker:Hide()
end)

soundSelectorBtn:SetScript("OnClick", function()
    if soundPicker:IsShown() then
        soundPicker:Hide()
    else
        soundPicker:ClearAllPoints()
        soundPicker:SetPoint("TOPLEFT", soundSelectorBtn, "BOTTOMLEFT", 0, -4)
        pickerSearch:SetText("")
        pickerSearch:SetFocus()
        populatePicker("")
        soundPicker:Show()
    end
end)

-- Preview button
local previewBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
previewBtn:SetSize(60, 22)
previewBtn:SetPoint("LEFT", soundSelectorBtn, "RIGHT", 4, 0)
previewBtn:SetText("Preview")
previewBtn:SetScript("OnClick", function()
    Harkened:TriggerAlert(true)
end)

-- Show all sounds toggle
local showAllCB = createCheckbox(panel, "Show all sounds", 8, -92)
showAllCB:SetScript("OnClick", function(self)
    showAllSounds = self:GetChecked()
    soundPicker:Hide()
    refreshSoundDropdown()
end)

refreshSoundDropdown = function()
    local lists = { Harkened.SOUNDS, Harkened.ALL_SOUNDS }
    for _, list in ipairs(lists) do
        for _, s in ipairs(list) do
            if s.id == Harkened.db.soundID then
                soundSelectorBtn:SetText(s.label)
                return
            end
        end
    end
    soundSelectorBtn:SetText("ID: " .. tostring(Harkened.db.soundID))
end

-- ── Channels ──────────────────────────────────────────────────────────────

sectionHeader("Monitor Channels", -128)

local CHANNELS = {
    { key = "GUILD",         label = "Guild Chat"    },
    { key = "PARTY",         label = "Party Chat"    },
    { key = "INSTANCE_CHAT", label = "Instance Chat" },
    { key = "RAID",          label = "Raid Chat"     },
}

local channelCBs = {}
for i, ch in ipairs(CHANNELS) do
    local col = ((i - 1) % 2) * 180
    local row = math.floor((i - 1) / 2)
    local cb = createCheckbox(panel, ch.label, 8 + col, -148 - (row * 28))
    cb:SetScript("OnClick", function(self)
        Harkened.db.channels[ch.key] = self:GetChecked()
        Harkened:RefreshChatEvents()
    end)
    channelCBs[ch.key] = cb
end

-- ── Throttle ──────────────────────────────────────────────────────────────

sectionHeader("Alert Cooldown", -214)

local throttleLabel = inlineLabel("Seconds between alerts:", -236)

local throttleBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
throttleBox:SetSize(60, 20)
throttleBox:SetPoint("LEFT", throttleLabel, "RIGHT", 8, 0)
throttleBox:SetNumeric(true)
throttleBox:SetMaxLetters(4)
throttleBox:SetAutoFocus(false)
throttleBox:SetScript("OnEnterPressed", function(self)
    local val = math.max(0, math.min(3600, tonumber(self:GetText()) or Harkened.db.throttle))
    Harkened.db.throttle = val
    self:SetText(tostring(val))
    self:ClearFocus()
end)
throttleBox:SetScript("OnEscapePressed", function(self)
    self:SetText(tostring(Harkened.db.throttle))
    self:ClearFocus()
end)

-- ── Keywords ──────────────────────────────────────────────────────────────

sectionHeader("Keywords", -262)

local keywordHint = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
keywordHint:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -282)
keywordHint:SetText("One per line. Case-insensitive.")

local keywordBorder = CreateFrame("Frame", nil, panel, "InsetFrameTemplate")
keywordBorder:SetSize(280, 110)
keywordBorder:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -300)

local keywordScroll = CreateFrame("ScrollFrame", nil, keywordBorder, "UIPanelScrollFrameTemplate")
keywordScroll:SetPoint("TOPLEFT",     keywordBorder, "TOPLEFT",     4,   -4)
keywordScroll:SetPoint("BOTTOMRIGHT", keywordBorder, "BOTTOMRIGHT", -26,  4)

local keywordBox = CreateFrame("EditBox", nil, keywordScroll)
keywordBox:SetWidth(230)
keywordBox:SetMultiLine(true)
keywordBox:SetAutoFocus(false)
keywordBox:SetFontObject("ChatFontNormal")
keywordScroll:SetScrollChild(keywordBox)

local function saveKeywords()
    local keywords, seen = {}, {}
    for line in (keywordBox:GetText() .. "\n"):gmatch("([^\n]*)\n") do
        local kw = line:match("^%s*(.-)%s*$")  -- trim whitespace
        if kw ~= "" and not seen[kw:lower()] then
            seen[kw:lower()] = true
            keywords[#keywords + 1] = kw
        end
    end
    Harkened.db.keywords = keywords
    keywordBox:SetText(table.concat(keywords, "\n"))
end

keywordBox:SetScript("OnEditFocusLost", saveKeywords)
keywordBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

-- ── Sync controls from db on panel open ───────────────────────────────────

local function refresh()
    enableCB:SetChecked(Harkened.db.enabled)
    refreshSoundDropdown()
    for key, cb in pairs(channelCBs) do
        cb:SetChecked(Harkened.db.channels[key])
    end
    throttleBox:SetText(tostring(Harkened.db.throttle))
    keywordBox:SetText(table.concat(Harkened.db.keywords, "\n"))
end

panel:SetScript("OnShow", refresh)

-- ── Slash command ──────────────────────────────────────────────────────────

local function printHelp()
    local c = "|cff00ccff"
    local r = "|r"
    print(c .. "Harkened" .. r .. " commands:")
    print("  /hark              – open settings panel")
    print("  /hark on|off       – enable / disable")
    print("  /hark add <word>   – add a keyword")
    print("  /hark remove <word>– remove a keyword")
    print("  /hark test         – play alert sound")
    print("  /hark status       – show current settings")

end

function Harkened:InitSlash()
    SLASH_HARKENED1 = "/hark"
    SLASH_HARKENED2 = "/harkened"
    SlashCmdList.HARKENED = function(msg)
        local cmd, arg = msg:match("^(%S+)%s*(.*)")
        cmd = (cmd or ""):lower()
        arg = arg or ""

        if cmd == "" then
            Settings.OpenToCategory(Harkened.settingsCategory)

        elseif cmd == "on" then
            Harkened.db.enabled = true
            print("|cff00ccffHarkened|r enabled.")

        elseif cmd == "off" then
            Harkened.db.enabled = false
            print("|cff00ccffHarkened|r disabled.")

        elseif cmd == "add" then
            if arg == "" then
                print("|cff00ccffHarkened|r Usage: /hark add <keyword>")
            else
                local kw = arg:match("^%s*(.-)%s*$")
                local lower = kw:lower()
                for _, existing in ipairs(Harkened.db.keywords) do
                    if existing:lower() == lower then
                        print("|cff00ccffHarkened|r \"" .. kw .. "\" is already in the keyword list.")
                        return
                    end
                end
                Harkened.db.keywords[#Harkened.db.keywords + 1] = kw
                print("|cff00ccffHarkened|r Added keyword: \"" .. kw .. "\"")
            end

        elseif cmd == "remove" then
            if arg == "" then
                print("|cff00ccffHarkened|r Usage: /hark remove <keyword>")
            else
                local kw = arg:match("^%s*(.-)%s*$")
                local lower = kw:lower()
                local found = false
                local newList = {}
                for _, existing in ipairs(Harkened.db.keywords) do
                    if existing:lower() == lower then
                        found = true
                    else
                        newList[#newList + 1] = existing
                    end
                end
                if found then
                    Harkened.db.keywords = newList
                    print("|cff00ccffHarkened|r Removed keyword: \"" .. kw .. "\"")
                else
                    print("|cff00ccffHarkened|r Keyword not found: \"" .. kw .. "\"")
                end
            end

        elseif cmd == "test" then
            Harkened:TriggerAlert(true)
            print("|cff00ccffHarkened|r Playing alert sound.")

        elseif cmd == "status" then
            local db = Harkened.db
            print("|cff00ccffHarkened|r Status:")
            print("  Enabled : " .. (db.enabled and "yes" or "no"))
            print("  Keywords: " .. (#db.keywords > 0 and table.concat(db.keywords, ", ") or "(none)"))
            print("  Throttle: " .. db.throttle .. "s")
            local chList = {}
            for ch, on in pairs(db.channels) do
                if on then chList[#chList + 1] = ch end
            end
            print("  Channels: " .. (#chList > 0 and table.concat(chList, ", ") or "(none)"))

        else
            printHelp()
        end
    end
end
