-- Animated custom cursor module
-- Loads frames from assets/cursor/Stamped and an idle frame as fallback
local Cursor = {}
local frames = {}
local idle
local stampMark
local t = 0
local frameTime = 0.04
local index = 1
local x,y = 0,0
local isAnimating = false
local animationComplete = false
local mirrorX = true

-- Stamp marks system
local stampMarks = {} -- Lista di tutti i stamp marks da disegnare
local stampMarkTriggered = false -- Per evitare trigger multipli durante l'animazione

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
  
  -- Load stamp mark image
  local stampPath = 'assets/cursor/Stamped/stamp_mark.png'
  if love.filesystem.getInfo(stampPath) then
    stampMark = love.graphics.newImage(stampPath)
  else
    print("Warning: stamp_mark.png not found in assets/cursor/Stamped/")
  end
  
  if #frames==0 then frames[1] = idle end
end

function Cursor.update(dt)
  -- Aggiorna animazione cursore
  if isAnimating and #frames > 1 then
    t = t + dt
    while t > frameTime do
      t = t - frameTime
      index = index + 1
      
      -- Trigger stamp mark durante i frame 8, 9, 10 (solo una volta per animazione)
      if not stampMarkTriggered and index >= 8 and index <= 10 and stampMark then
        table.insert(stampMarks, {
          x = x, 
          y = y, 
          alpha = 1.0, 
          lifetime = 0.0,
          maxLifetime = 0.8 -- Dura 0.8 secondi prima di iniziare a scomparire
        })
        stampMarkTriggered = true
      end
      
      if index > #frames then 
        -- Animation complete, stop and return to idle
        index = 1
        isAnimating = false
        animationComplete = true
        stampMarkTriggered = false -- Reset per la prossima animazione
      end
    end
  end
  
  -- Aggiorna stamp marks (fade-out e rimozione)
  for i = #stampMarks, 1, -1 do
    local mark = stampMarks[i]
    mark.lifetime = mark.lifetime + dt
    
    -- Inizia fade-out dopo maxLifetime
    if mark.lifetime > mark.maxLifetime then
      local fadeTime = 1.0 -- 1 secondo per scomparire completamente
      local fadeProgress = (mark.lifetime - mark.maxLifetime) / fadeTime
      mark.alpha = math.max(0, 1.0 - fadeProgress)
      
      -- Rimuovi quando completamente trasparente
      if mark.alpha <= 0 then
        table.remove(stampMarks, i)
      end
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
    stampMarkTriggered = false -- Reset per nuova animazione
    x, y = mx, my -- Aggiorna posizione per il stamp mark
  end
end

function Cursor.draw()
  -- Prima disegna tutti i stamp marks permanenti
  if stampMark then
    for _, mark in ipairs(stampMarks) do
      local ox = stampMark:getWidth()/2
      local oy = stampMark:getHeight()/2
      love.graphics.setColor(1, 1, 1, mark.alpha)
      love.graphics.draw(stampMark, mark.x, mark.y, 0, 1, 1, ox, oy)
    end
  end
  
  -- Poi disegna il cursore animato
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

-- Funzioni per gestire i stamp marks
function Cursor.clearStampMarks()
  stampMarks = {}
end

function Cursor.getStampMarksCount()
  return #stampMarks
end

return Cursor
