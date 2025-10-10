-- Settings Manager - Handles saving and loading of game settings
local Settings = {}

-- Default settings
local DEFAULT_SETTINGS = {
    video = {
        width = 960,
        height = 640,
        fullscreen = false,
        vsync = true
    },
    audio = {
        masterVolume = 0.8,
        sfxVolume = 0.7,
        musicVolume = 0.6,
        diceVolume = 0.8,
        uiVolume = 0.5,
        ambienceVolume = 0.3
    },
    game = {
        diceRenderMode = "2d",
        showStats = false,
        autoSaveEnabled = true
    }
}

local currentSettings = {}
local SETTINGS_FILE = "settings.json"

-- JSON encode/decode functions (simple implementation)
local function encodeJSON(obj)
    if type(obj) == "table" then
        local result = "{"
        local first = true
        for k, v in pairs(obj) do
            if not first then result = result .. "," end
            first = false
            result = result .. '"' .. tostring(k) .. '":' .. encodeJSON(v)
        end
        return result .. "}"
    elseif type(obj) == "string" then
        return '"' .. obj:gsub('"', '\\"') .. '"'
    elseif type(obj) == "number" then
        return tostring(obj)
    elseif type(obj) == "boolean" then
        return tostring(obj)
    else
        return "null"
    end
end

local function decodeJSON(str)
    -- Simple JSON decoder - for production use a proper library
    local function parse_value(s, i)
        local c = s:sub(i, i)
        if c == '"' then
            -- String
            local j = i + 1
            while j <= #s and s:sub(j, j) ~= '"' do
                if s:sub(j, j) == '\\' then j = j + 1 end
                j = j + 1
            end
            return s:sub(i + 1, j - 1), j + 1
        elseif c == '{' then
            -- Object
            local obj = {}
            i = i + 1
            while i <= #s do
                -- Skip whitespace
                while i <= #s and s:sub(i, i):match("%s") do i = i + 1 end
                if s:sub(i, i) == '}' then break end
                
                -- Parse key
                local key, ni = parse_value(s, i)
                i = ni
                
                -- Skip whitespace and colon
                while i <= #s and (s:sub(i, i):match("%s") or s:sub(i, i) == ':') do i = i + 1 end
                
                -- Parse value
                local value, nj = parse_value(s, i)
                obj[key] = value
                i = nj
                
                -- Skip whitespace and comma
                while i <= #s and (s:sub(i, i):match("%s") or s:sub(i, i) == ',') do i = i + 1 end
            end
            return obj, i + 1
        elseif c:match("[%d%-]") then
            -- Number
            local j = i
            while j <= #s and s:sub(j, j):match("[%d%-%.]") do j = j + 1 end
            return tonumber(s:sub(i, j - 1)), j
        elseif s:sub(i, i + 3) == "true" then
            return true, i + 4
        elseif s:sub(i, i + 4) == "false" then
            return false, i + 5
        end
        return nil, i + 1
    end
    
    local result, _ = parse_value(str, 1)
    return result
end

-- Deep copy function
local function deepCopy(orig)
    local copy = {}
    for key, value in pairs(orig) do
        if type(value) == "table" then
            copy[key] = deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Initialize settings system
function Settings.init()
    print("[Settings] Initializing settings system...")
    currentSettings = deepCopy(DEFAULT_SETTINGS)
    Settings.load()
    print("[Settings] Settings initialized")
end

-- Load settings from file
function Settings.load()
    local success, content = pcall(love.filesystem.read, SETTINGS_FILE)
    if success and content then
        local success2, loaded = pcall(decodeJSON, content)
        if success2 and loaded then
            -- Merge loaded settings with defaults (preserving structure)
            for category, values in pairs(loaded) do
                if currentSettings[category] then
                    for key, value in pairs(values) do
                        if currentSettings[category][key] ~= nil then
                            currentSettings[category][key] = value
                        end
                    end
                end
            end
            print("[Settings] Settings loaded from file")
            return true
        else
            print("[Settings] Failed to parse settings file, using defaults")
        end
    else
        print("[Settings] No settings file found, using defaults")
    end
    return false
end

-- Save settings to file
function Settings.save()
    local success, content = pcall(encodeJSON, currentSettings)
    if success then
        local writeSuccess = pcall(love.filesystem.write, SETTINGS_FILE, content)
        if writeSuccess then
            print("[Settings] Settings saved successfully")
            return true
        else
            print("[Settings] Failed to write settings file")
        end
    else
        print("[Settings] Failed to encode settings")
    end
    return false
end

-- Get setting value
function Settings.get(category, key)
    if currentSettings[category] and currentSettings[category][key] ~= nil then
        return currentSettings[category][key]
    end
    return nil
end

-- Set setting value
function Settings.set(category, key, value)
    if not currentSettings[category] then
        currentSettings[category] = {}
    end
    currentSettings[category][key] = value
    
    -- Auto-save (can be disabled for batch operations)
    if Settings.get("game", "autoSaveEnabled") then
        Settings.save()
    end
end

-- Get entire category
function Settings.getCategory(category)
    return currentSettings[category] or {}
end

-- Set entire category
function Settings.setCategory(category, values)
    currentSettings[category] = deepCopy(values)
    if Settings.get("game", "autoSaveEnabled") then
        Settings.save()
    end
end

-- Apply video settings
function Settings.applyVideoSettings()
    local video = Settings.getCategory("video")
    love.window.setMode(video.width, video.height, {
        fullscreen = video.fullscreen,
        vsync = video.vsync and 1 or 0,
        resizable = not video.fullscreen
    })
    print("[Settings] Applied video settings:", video.width .. "x" .. video.height, "Fullscreen:", video.fullscreen)
end

-- Apply audio settings
function Settings.applyAudioSettings()
    local audio = Settings.getCategory("audio")
    love.audio.setVolume(audio.masterVolume)
    print("[Settings] Applied audio settings - Master volume:", audio.masterVolume)
end

-- Get all settings (for debugging)
function Settings.getAll()
    return deepCopy(currentSettings)
end

-- Reset to defaults
function Settings.resetToDefaults()
    currentSettings = deepCopy(DEFAULT_SETTINGS)
    Settings.save()
    print("[Settings] Settings reset to defaults")
end

return Settings