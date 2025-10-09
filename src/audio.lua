-- Audio module: loads and plays UI and dice SFX, handles delayed quit

local Audio = {
  sounds = {
    dice = {},
    book = nil,   -- page flip
    handle = nil, -- quit handle
    coins = nil,  -- bank jingle
    select = nil, -- select/lock dice
    bust = nil,   -- farkle
    ambience = nil, -- tavern loop
  },
  lastDiceTime = 0,
  pendingQuitAt = nil,
}

local function fsInfo(path)
  local ok, info = pcall(love.filesystem.getInfo, path)
  if ok then return info end
  return nil
end

local function findExistingAudio(base)
  local exts = {".ogg", ".wav", ".mp3", ".OGG", ".WAV", ".MP3"}
  for _, ext in ipairs(exts) do
    local path = base .. ext
    if fsInfo(path) then return path end
  end
  return nil
end

local function tryBases(bases)
  for _, b in ipairs(bases) do
    local p = findExistingAudio(b)
    if p then return p end
  end
  return nil
end

function Audio.init()
  Audio.sounds.dice = {}
  for i = 1, 29 do
    local bases = {
      string.format("sounds/dice/dice-%d", i),
      string.format("sound/dice/dice-%d", i),
    }
    local path = tryBases(bases)
    if path then
      local ok, src = pcall(love.audio.newSource, path, "static")
      if ok and src then table.insert(Audio.sounds.dice, src) end
    end
  end
  print(string.format("[SFX] Dice variants loaded: %d", #Audio.sounds.dice))

  local bookBase = tryBases({
    "sounds/book_page", "sounds/book-page",
    "sound/menu/Book_Page", "sound/menu/book_page"
  })
  if bookBase then
    local ok, src = pcall(love.audio.newSource, bookBase, "static")
    if ok and src then Audio.sounds.book = src; print("[SFX] Loaded book page: " .. bookBase) end
  end

  local handleBase = tryBases({
    "sounds/book_handle", "sounds/book-handle",
    "sound/menu/Book_Handle", "sound/menu/book_handle"
  })
  if handleBase then
    local ok, src = pcall(love.audio.newSource, handleBase, "static")
    if ok and src then Audio.sounds.handle = src; print("[SFX] Loaded book handle: " .. handleBase) end
  end

  -- Coins jingle for banking
  local coinsBase = tryBases({"sounds/ui/coins", "sounds/coins", "sound/ui/coins", "sound/coins"})
  if coinsBase then
    local ok, src = pcall(love.audio.newSource, coinsBase, "static")
    if ok and src then Audio.sounds.coins = src; print("[SFX] Loaded coins: " .. coinsBase) end
  end

  -- Select/lock dice SFX
  local selectBase = tryBases({"sounds/ui/select", "sounds/select", "sound/ui/select", "sound/select"})
  if selectBase then
    local ok, src = pcall(love.audio.newSource, selectBase, "static")
    if ok and src then Audio.sounds.select = src; print("[SFX] Loaded select: " .. selectBase) end
  end

  -- Bust/farkle SFX
  local bustBase = tryBases({"sounds/ui/bust", "sounds/bust", "sound/ui/bust", "sound/bust"})
  if bustBase then
    local ok, src = pcall(love.audio.newSource, bustBase, "static")
    if ok and src then Audio.sounds.bust = src; print("[SFX] Loaded bust: " .. bustBase) end
  end

  -- Ambience loop
  local ambBase = tryBases({"sounds/ambience/tavern", "sound/ambience/tavern", "sounds/ambience", "sound/ambience"})
  if ambBase then
    local ok, src = pcall(love.audio.newSource, ambBase, "stream")
    if ok and src then
      src:setLooping(true)
      src:setVolume(0.32) -- circa -10/-12 LUFS perceived
      Audio.sounds.ambience = src
      print("[SFX] Loaded ambience: " .. ambBase)
    end
  end
end

function Audio.playDiceImpact(strength)
  if not Audio.sounds or not Audio.sounds.dice or #Audio.sounds.dice == 0 then return end
  local now = love.timer.getTime()
  if now - (Audio.lastDiceTime or 0) < 0.035 then return end
  Audio.lastDiceTime = now
  local idx = love.math.random(1, #Audio.sounds.dice)
  local src = Audio.sounds.dice[idx]
  local clone = src:clone()
  local sp = math.max(0.1, (strength or 800) / 1800)
  clone:setVolume(math.min(1, 0.12 + sp * 0.75))
  clone:setPitch(0.9 + love.math.random() * 0.2)
  clone:play()
end

function Audio.playBookPage()
  if not Audio.sounds or not Audio.sounds.book then return end
  local c = Audio.sounds.book:clone()
  c:setVolume(0.8)
  c:setPitch(0.96 + love.math.random() * 0.08)
  c:play()
end

function Audio.playBookHandle()
  if not Audio.sounds or not Audio.sounds.handle then return end
  local c = Audio.sounds.handle:clone()
  c:setVolume(0.9)
  c:setPitch(0.98 + love.math.random() * 0.04)
  c:play()
end

function Audio.playCoins()
  if not (Audio.sounds and Audio.sounds.coins) then return end
  local c = Audio.sounds.coins:clone()
  c:setVolume(0.8)
  c:setPitch(1.0)
  c:play()
end

function Audio.playSelect()
  if not (Audio.sounds and Audio.sounds.select) then return end
  local c = Audio.sounds.select:clone()
  c:setVolume(0.5)
  c:setPitch(1.02)
  c:play()
end

function Audio.playBust()
  if not (Audio.sounds and Audio.sounds.bust) then return end
  local c = Audio.sounds.bust:clone()
  c:setVolume(0.85)
  c:setPitch(0.94)
  c:play()
end

function Audio.requestQuit()
  if Audio.pendingQuitAt then return end
  Audio.playBookHandle()
  Audio.pendingQuitAt = love.timer.getTime() + 0.5
end

function Audio.update()
  if Audio.pendingQuitAt and love.timer.getTime() >= Audio.pendingQuitAt then
    Audio.pendingQuitAt = nil
    love.event.quit()
  end
  if Audio.sounds and Audio.sounds.ambience and not Audio.sounds.ambience:isPlaying() then
    -- lazy start ambience once
    local ok = pcall(function() Audio.sounds.ambience:play() end)
  end
end

return Audio
