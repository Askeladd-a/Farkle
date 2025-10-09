-- Audio module: loads and plays UI and dice SFX, handles delayed quit

local Audio = {
  sounds = {
    dice = {},
    book = nil,   -- page flip
    handle = nil, -- quit handle
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

function Audio.init()
  Audio.sounds.dice = {}
  for i = 1, 29 do
    local base = string.format("sounds/dice/dice-%d", i)
    local path = findExistingAudio(base)
    if path then
      local ok, src = pcall(love.audio.newSource, path, "static")
      if ok and src then table.insert(Audio.sounds.dice, src) end
    end
  end
  print(string.format("[SFX] Dice variants loaded: %d", #Audio.sounds.dice))

  local bookBase = findExistingAudio("sounds/book_page") or findExistingAudio("sounds/book-page")
  if bookBase then
    local ok, src = pcall(love.audio.newSource, bookBase, "static")
    if ok and src then Audio.sounds.book = src; print("[SFX] Loaded book page: " .. bookBase) end
  end

  local handleBase = findExistingAudio("sounds/book_handle") or findExistingAudio("sounds/book-handle")
  if handleBase then
    local ok, src = pcall(love.audio.newSource, handleBase, "static")
    if ok and src then Audio.sounds.handle = src; print("[SFX] Loaded book handle: " .. handleBase) end
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
end

return Audio
