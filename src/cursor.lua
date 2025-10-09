-- Cursor module: manages custom idle cursor and stamped click animation
local Cursor = {}

local idle
local frames = {}
local frameIndex = 1
local animTime = 0
local playing = false
local frameDuration = 0.035 -- 35ms ~28fps

local function setCursor(cur)
  if cur then
    pcall(love.mouse.setCursor, cur)
  end
end

function Cursor.load()
  -- Load idle
  do
    local okIdle, imgIdle = pcall(love.graphics.newImage, "images/cursor/idle/1.png")
    if okIdle and imgIdle then
      local okC, cur = pcall(love.mouse.newCursor, imgIdle:getData(), 0, 0)
      if okC and cur then
        idle = cur
        setCursor(idle)
      end
    end
  end
  -- Load stamped frames
  frames = {}
  for i=1,20 do
    local path = string.format("images/cursor/Stamped/%d.png", i)
    local okImg, img = pcall(love.graphics.newImage, path)
    if okImg and img then
      local okC, cur = pcall(love.mouse.newCursor, img:getData(), 0, 0)
      if okC and cur then frames[#frames+1] = cur end
    end
  end
  print(string.format("[Cursor] idle=%s frames=%d", idle and "OK" or "NO", #frames))
end

function Cursor.startClick()
  if #frames == 0 then return end
  playing = true
  frameIndex = 1
  animTime = 0
  setCursor(frames[1])
end

function Cursor.update(dt, onFinished)
  if not playing then return end
  animTime = animTime + dt
  while animTime >= frameDuration and playing do
    animTime = animTime - frameDuration
    frameIndex = frameIndex + 1
    if frameIndex > #frames then
      playing = false
      if onFinished then pcall(onFinished) end
      setCursor(idle)
    else
      setCursor(frames[frameIndex])
    end
  end
end

function Cursor.isPlaying() return playing end

return Cursor
