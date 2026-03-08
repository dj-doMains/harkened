-- luacheck configuration for WoW addon development
std = "lua51"  -- WoW uses a Lua 5.1-compatible environment

globals = {
    -- Addon namespace
    "Harkened",
    "HarkenedDB",
    "HarkenedLocale",

    -- WoW API globals
    "CreateFrame",
    "GetTime",
    "PlaySound",
    "SOUNDKIT",
    "SlashCmdList",
    "Settings",
    "UnitName",
    "C_AddOns",

    -- WoW globals
    "UIParent",

    -- Slash command registration pattern
    "SLASH_HARKENED1",
    "SLASH_HARKENED2",
}

read_globals = {
    -- WoW print replacement
    "print",

    -- WoW string/table globals
    "string",
    "table",
    "math",
    "pairs",
    "ipairs",
    "type",
    "tostring",
    "tonumber",
    "unpack",
    "select",
    "error",
    "pcall",
    "xpcall",
    "setmetatable",
    "getmetatable",
    "rawget",
    "rawset",
    "next",
}

-- Ignore line length warnings (WoW addon code often has long lines)
max_line_length = false
