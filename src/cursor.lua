-- Cursor module: manages custom cursor drawing and click animations
local Cursor = {}

local cursorImage
local clickFrames = {}
local frameIndex = 1
local animTime = 0
local isClickPlaying = false
local frameDuration = 0.035 -- 35ms ~28fps
local mouseVisible = true

function Cursor.load()
  -- Load idle cursor image
  local success, img = pcall(love.graphics.newImage, "assets/cursor/idle/1.png")
  if success and img then
    cursorImage = img
    -- Hide system cursor and set grab to window
    love.mouse.setVisible(false)
    if love.mouse.setGrab then
      love.mouse.setGrab(true)
    end
    mouseVisible = false
    print("[Cursor] Custom cursor loaded successfully from assets/cursor/idle/1.png")
  else
    print("[Cursor] Failed to load cursor image, using system cursor")
    love.mouse.setVisible(true)
    mouseVisible = true
  end
  
  -- Load stamped click animation frames
  clickFrames = {}
  for i=1,20 do
    local path = string.format("assets/cursor/Stamped/%d.png", i)
    local okImg, frameImg = pcall(love.graphics.newImage, path)
    if okImg and frameImg then
      clickFrames[#clickFrames+1] = frameImg
    end
  end
  print(string.format("[Cursor] Loaded %d click animation frames", #clickFrames))
end

function Cursor.startClick()
  if #clickFrames == 0 then return end
  isClickPlaying = true
  frameIndex = 1
  animTime = 0
  print("[Cursor] Starting click animation")
end

function Cursor.update(dt, onFinished)
  if not isClickPlaying then return end
  animTime = animTime + dt
  while animTime >= frameDuration and isClickPlaying do
    animTime = animTime - frameDuration
    frameIndex = frameIndex + 1
    if frameIndex > #clickFrames then
      isClickPlaying = false
      if onFinished then pcall(onFinished) end
      print("[Cursor] Click animation finished")
    end
  end
end

function Cursor.draw()
  if not cursorImage or mouseVisible then return end
  
  local mx, my = love.mouse.getPosition()
  
  -- Draw cursor image centered on mouse position
  if isClickPlaying and frameIndex <= #clickFrames then
    -- Draw click animation frame
    local frame = clickFrames[frameIndex]
    if frame then
      love.graphics.draw(frame, mx - frame:getWidth() / 2, my - frame:getHeight() / 2)
    end
  else
    -- Draw idle cursor
    love.graphics.draw(cursorImage, mx - cursorImage:getWidth() / 2, my - cursorImage:getHeight() / 2)
  end
end

function Cursor.isPlaying() 
  return isClickPlaying 
end

function Cursor.setVisible(visible)
  mouseVisible = visible
  love.mouse.setVisible(visible)
  if visible then
    love.mouse.setGrab(false)
  else
    love.mouse.setGrab(true)
  end
end

return Cursor
