local Audio = {}

-- Default volume settings
Audio.volumes = {
    master = 1.0,
    sfx = 1.0,
    music = 1.0,
    dice = 1.0,
    ui = 1.0,
    ambience = 1.0
}

-- Sound sources
Audio.sources = {}

function Audio.load()
    -- Load dice sounds
    Audio.sources.dice = {}
    for i = 1, 29 do
        local path = "sound/dice/dice-" .. i .. ".wav"
        if love.filesystem.getInfo(path) then
            Audio.sources.dice[i] = love.audio.newSource(path, "static")
        end
    end
    
    -- Load menu sounds
    Audio.sources.menu = {}
    if love.filesystem.getInfo("sound/menu/Book_Handle.wav") then
        Audio.sources.menu.handle = love.audio.newSource("sound/menu/Book_Handle.wav", "static")
    end
    if love.filesystem.getInfo("sound/menu/Book_Page.wav") then
        Audio.sources.menu.page = love.audio.newSource("sound/menu/Book_Page.wav", "static")
    end
end

function Audio.init()
    Audio.load()
end

function Audio.playDiceSound()
    if Audio.sources.dice and #Audio.sources.dice > 0 then
        local index = love.math.random(1, #Audio.sources.dice)
        local source = Audio.sources.dice[index]
        if source then
            source:setVolume(Audio.volumes.dice * Audio.volumes.master)
            love.audio.play(source)
        end
    end
end

function Audio.playMenuSound(type)
    if Audio.sources.menu and Audio.sources.menu[type] then
        local source = Audio.sources.menu[type]
        source:setVolume(Audio.volumes.ui * Audio.volumes.master)
        love.audio.play(source)
    end
end

function Audio.setVolume(category, volume)
    if Audio.volumes[category] then
        Audio.volumes[category] = math.max(0, math.min(1, volume))
    end
end

function Audio.getVolume(category)
    return Audio.volumes[category] or 1.0
end

function Audio.update()
    -- Audio update logic if needed
end

return Audio
