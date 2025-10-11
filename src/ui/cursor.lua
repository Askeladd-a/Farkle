-- Animated custom cursor module
-- Loads frames from assets/cursor/Stamped and an idle frame as fallback
local Cursor = {}
local frames = {}
local idle
local t = 0
local frameTime = 0.04
local index = 1
local x,y = 0,0
local isAnimating = false
local animationComplete = false
local mirrorX = true

function Cursor.init()
  -- load animation frames
  local i=1
  while true do
    local path = string.format('assets/cursor/Stamped/%d.png', i)
    if love.filesystem.getInfo(path) then
      frames[i] = love.graphics.newImage(path)
      i=i+1
    else
      break
    end
  end
  idle = love.graphics.newImage('assets/cursor/idle/1.png')
  if #frames==0 then frames[1] = idle end
end

function Cursor.update(dt)
  if not isAnimating or #frames <= 1 then return end
  
  t = t + dt
  while t > frameTime do
    t = t - frameTime
    index = index + 1
    if index > #frames then 
      -- Animation complete, stop and return to idle
      index = 1
      isAnimating = false
      animationComplete = true
    end
  end
end

function Cursor.mousemoved(mx,my,dx,dy)
  x,y = mx,my
end

function Cursor.mousepressed(mx, my, button)
  if button == 1 then -- Left mouse button
    isAnimating = true
    animationComplete = false
    index = 1
    t = 0
  end
end

function Cursor.draw()
  local img
  if isAnimating and #frames > 1 then
    img = frames[index]
  else
    img = idle
  end
  
  if not img then return end
  local ox = img:getWidth()/2
  local oy = img:getHeight()/2
  
  -- Calculate scale factors for mirroring
  local scaleX = mirrorX and -1 or 1
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(img, x, y, 0, scaleX, 1, ox, oy)
end

-- Helper functions for external control
function Cursor.setMirrorX(mirror)
  mirrorX = mirror
end

function Cursor.setMirrorY(mirror)
  mirrorY = mirror
end

function Cursor.toggleMirrorX()
  mirrorX = not mirrorX
end

function Cursor.toggleMirrorY()
  mirrorY = not mirrorY
end

function Cursor.getMirrorState()
  return mirrorX, mirrorY
end

return Cursor
